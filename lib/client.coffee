require.paths.unshift(require('path').join(__dirname, '.'))
version = require "version"

Request = require "request"
url = require "url"
EventEmitter = require("events").EventEmitter
Container = require "container"
StorageError = require "errors"
Utils = require 'utils'

defaultAuthUrl = "https://secure.motionbox.com/auth/v1.0"

class Client extends EventEmitter
    constructor: (@auth) ->
        @isAuthorized = false
        @requestQueue = []
        
    failCodes:
        400: "Bad Request",
        401: "Unauthorized",
        403: "Resize not allowed",
        404: "Item not found",
        409: "Build in progress",
        413: "Over Limit",
        415: "Bad Media Type",
        500: "Fault",
        503: "Service Unavailable"
        
    successCodes:
        200: "OK",
        202: "Accepted",
        203: "Non-authoritative information",
        204: "No content",
        
    _setStorageUrlsFromRequest: (response) =>
        headers = response.headers
        @storageUrl = headers['x-storage-url']
        @storageToken = headers['x-storage-token'] || headers['x-auth-token']
        @isAuthorized = true
        
    setAuth: (callback) ->
        authOptions =
            uri: @auth.authUrl
            headers:
                #HOST: url.parse(@auth.authUrl).host
                'X-Storage-User': @auth.username
                'X-Auth-Key': @auth.apiKey
                
        @emit("authorizationRequest")        
        Request authOptions, (err, res, body) =>
            statusCode = res.statusCode
            return callback(new StorageError.BadAuthError(body)) if @failCodes[statusCode]
            
            @_setStorageUrlsFromRequest(res) if @successCodes[statusCode]
            @emit("authorized", this)
            callback(null, res)
            if @requestQueue.length > 0
                for req in @requestQueue
                    do (req) =>
                        @makeRequest(req.method, req.uri, req.body, req.headers, req.callback)
                    
            
    getInfo: (callback) ->
        @storageRequest("HEAD", "", null, null, (err, response, body) =>
            return callback(err) if err
            @bytes = new Number(response.headers["x-account-bytes-used"])
            @count = new Number(response.headers["x-account-container-count"])
            callback(null, {bytes: @bytes, count: @count})
        ) 
        
    queueOrMakeRequest: (method, uri, body, headers, callback) =>
        if @isAuthorized
            @makeRequest(method, uri, body, headers, callback)
        else
            @requestQueue.push({
                method: method,
                uri: uri,
                body: body,
                headers: headers,
                callback: callback
            })
    
    storageRequest: (method, path, body, headers, callback) =>
        uri = path
        uri = @storageUrlFor(path) unless path[0] == "/"
        @queueOrMakeRequest(method, uri, body, headers, callback)
        
    getContainer: (name, callback, loadFromServer) =>
        loadFromServer ?= true
        container = new Container(name, this)
        container.reload(callback) if loadFromServer
            
    destroyContainer: (name, callback) =>
        container = new Container(name, this)
        container.destroy(callback)
        
    createContainer: (name, callback) =>
        Container.create(name, this, callback)
        
    makeRequest: (method, uri, body, headers, callback) =>
        headers ?= {}
        headers["X-Auth-Token"] = @storageToken
        headers["X-Storage-Token"] = @storageToken
        headers["User-Agent"] = "Javascript Open Stack API Client #{version}"
        #console.log("requesting: #{method}", uri)
        options =
            method: method
            uri: uri
            headers: headers
            callback: (err, response, body) =>
                return callback(new StorageError.BadRequest(err)) if err
                statusCode = response.statusCode
                return @_handleUnauthorizedRequest(method, uri, body, headers, callback) if statusCode.toString() == "401"
                
                if @failCodes[statusCode]
                    callback(new StorageError.BadRequest(body, statusCode))
                else
                    callback(null, response, body)
                    
        options.body = body if Utils.isString(body)            
        
        request = Request(options)
        if body? and not Utils.isString(body)
            try
                request.pipe(body) 
            catch error
                callback(new Error.BadBodySpecified("a body was specified that was not a string or failed to pipe"))
        return request
            
    _handleUnauthorizedRequest: (method, uri, body, headers, callback) =>
        console.log("handling unauthroized request to: ", path)
        retryCount = 0
        getAuthAndUpRetry ->
            return callback(new StorageError.BadAuthError(err)) if retryCount > 3
            @setAuth (err, auth) ->
                return getAuthAndUpRetry() if err
                @makeRequest(method, uri, body, headers, callback)
            retryCount++
        getAuthAndUpRetry()
        
            
    storageUrlFor: (path) ->
        "#{@storageUrl}/#{path}"
          

Client.create = (auth) ->
    new Client(auth)

module.exports = Client
