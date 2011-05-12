Client = require("./client")
Container = require("./container")
Utils = require('./utils')


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
