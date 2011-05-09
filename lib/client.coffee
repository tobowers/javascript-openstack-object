require.paths.unshift(require('path').join(__dirname, '.'))

Request = require "request"
url = require "url"
EventEmitter = require("events").EventEmitter

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
                HOST: url.parse(@auth.authUrl).host
                'X-Storage-User': @auth.username
                'X-Auth-Key': @auth.apiKey
                
        @emit("authorizationRequest")        
        Request authOptions, (err, res, body) =>
            statusCode = res.statusCode
            return callback(new Client.BadAuthError(body)) if @failCodes[statusCode]
            
            @_setStorageUrlsFromRequest(res) if @successCodes[statusCode]
            @emit("authorized", this)
            callback(null, res)
        
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
        
    makeRequest: (method, uri, body, headers, callback) =>
        
class Client.ObjectStoreError
    constructor: (@message) ->

class Client.BadAuthError extends Client.ObjectStoreError        

Client.create = (auth) ->
    new Client(auth)

module.exports = Client
