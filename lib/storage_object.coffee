Client = require("./client")
Container = require("./container")
Utils = require('./utils')
Error = require('./errors')

mime = require('mime')

fs = require("fs")

class StorageObject
            
    constructor: (@name, @container, @client, response) ->
        @container = new Container(@container, @client) if Utils.isString(@container)
        @metadata = {}
        @bytes = 0
        @lastModified = new Date()
    
    reload: (callback) =>
        @client.storageRequest "HEAD", @storagePath(), null, null, (err, response) =>
            return callback(err) if err
            @parseHeadResponse(response)
            callback(null, this)
            
    destroy: (callback) =>
        @client.storageRequest "DELETE", @storagePath(), null, null, (err, response) =>
            return callback(err) if err
            callback(null, this)
    
    write: (data, headersOrCallback, callback) =>
        return callback(new Error.NoDataInWriteRequest("No data or headers in write request")) unless data? or (typeof headersOrCallback == 'object')
        if typeof headersOrCallback == 'function'
            callback = headersOrCallback
            headers = {}
        else
            headers = headersOrCallback
            
        headers['Content-Type'] = mime.lookup(@name) unless headers["Content-Type"]?
        headers['Content-Type'] ?= "application/octet-stream"
        @client.storageRequest "PUT", @storagePath(), data, headers, (err, resp) =>
            return callback(err) if err
            callback(null, this)
    
    data: (opts, callback) =>
        if typeof opts == 'function'
            callback = opts
            opts = {}
        opts.size ?= -1
        headers = {}
        opts.offset ?= 0
        if new Number(opts.size) > 0
            headers["Range"] = "bytes=#{opts.offset}-#{opts.offset + opts.size - 1}"
        @client.storageRequest "GET", @storagePath(), null, headers, (err, response, body) ->
            return callback(err) if err
            callback(null, body)
    
    saveToFile: (path, callback) =>
        request = @client.storageRequest "GET", @storagePath(), null, null, (err, response) =>
            return callback(err) if err
            callback(null, this)
        request.pipe(fs.createWriteStream(path))
            
    writeFromFile: (path, headersOrCallback, callback) =>
        if typeof headersOrCallback == 'function'
            callback = headersOrCallback
            headers = {}
        else
            headers = headersOrCallback
        request = @client.storageRequest "PUT", @storagePath(), null, headers, (err, response, body) =>
            return callback(err) if err
            callback(null, this)
        fs.createReadStream(path).pipe(request)        
            
    escapedName: =>
        escape(@name)
        
    storagePath: =>
        escape("#{@container.name}/#{@name}")
    
    parseHeadResponse: (response) =>
        headers = response.headers
        @bytes = new Number(headers["content-length"]) if headers["content-length"]?
        @lastModified = new Date(headers["last-modified"]) if headers["last-modified"]?
        @etag = headers["etag"]
        @contentType = headers["content-type"]
        for own header, value of headers
            do (header, value) =>
                if match = header.match(/^x-object-meta-(.+)/)
                    @metadata[unescape(match[1])] = unescape(value)    
     
    @create: (name, container, callback) ->
        client = container.client
        client.storageRequest "PUT", [container.escapedName(), escape(name)].join("/"), null, null, (err, response) ->
            return callback(err) if err
            callback(null, new StorageObject(name, container, client))
        return
        
module.exports = StorageObject
