Client = require("./client") #incase we need the error definitions

class Container
    constructor: (@name, @client, response) ->
        @metadata = {}
        @bytes = 0
        @count = 0
        @parseHeadResponse(response) if response

    reload: (callback) =>
        @client.storageRequest "HEAD", @escapedName(), null, null, (err, response) =>
            return callback(err) if err
            @parseHeadResponse(response)
            callback(null, this)
            
    destroy: (callback) =>
        @client.storageRequest "DELETE", @escapedName(), null, null, (err, response) =>
            return callback(err) if err
            callback(null, this)
            
    setMetadata: (hsh, callback) =>
        hsh ?= {}
        @metadata = hsh
        headers = {}
        for own key, value of hsh
            do (key, value) ->
                headers["x-container-meta-#{escape(key)}"] = escape(value)
        @client.storageRequest "POST", @escapedName(), null, headers, (err, response) =>
            return callback(err) if err
            callback(null, this)

    escapedName: =>
        escape(@name)

    parseHeadResponse: (response) =>
        headers = response.headers
        @bytes = new Number(headers["x-container-bytes-used"]) if headers["x-container-bytes-used"]?
        @count = new Number(headers["x-container-object-count"]) if headers["x-container-object-count"]?
        @containerRead = headers["x-container-read"]
        @containerWrite = headers["x-container-write"]
        for own header, value of headers
            do (header, value) =>
                if match = header.match(/^x-container-meta-(.+)/)
                    @metadata[unescape(match[1])] = unescape(value)
        
        
Container.create = (name, client, callback) ->
    client.storageRequest "PUT", escape(name), null, null, (err, response) =>
        return callback(err) if err
        callback(null, new Container(name, client, response))
            
module.exports = Container
        
    