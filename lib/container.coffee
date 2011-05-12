StorageObject = require("./storage_object")
Error = require("./errors")

# def objects(params = {})
# params[:marker] ||= params[:offset] unless params[:offset].nil?
# query = []
# params.each do |param, value|
# if [:limit, :marker, :prefix, :path, :delimiter].include? param
#   query << "#{param}=#{CloudFiles.escape(value.to_s)}"
# end
# end
# response = self.connection.storage_request("GET", "#{escaped_name}?#{query.join '&'}")
# return [] if (response.code == "204")
# raise CloudFiles::Exception::InvalidResponse, "Invalid response code #{response.code}" unless (response.code == "200")
# return CloudFiles.lines(response.body)
# end

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
    
    createObject: (name, callback) =>
        StorageObject.create(name, this, callback)
    
    destroyObject: (name, callback) =>
        (new StorageObject(name, this, this.client)).destroy(callback)
        
    objects: (opts, callback) =>
        if typeof opts == 'function'
            callback = opts
            opts = {}
        opts ?= {}
        query = []
        allowedValues = ["limit", "marker", "prefix", "path", "delimiter"]
        for own key, value of opts
            do (key, value) ->
                query.push "#{key}=#{escape(value)}" if allowedValues.indexOf(key) != -1
    
        @client.storageRequest "GET", "#{@escapedName()}?#{query.join("&")}", null, null, (err, response, body) ->
            return callback(err) if err
            return callback(null, []) if response.statusCode == "204"
            callback(null, body.split("\n"))
        
    
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
        
        
    @create = (name, client, callback) ->
        client.storageRequest "PUT", escape(name), null, null, (err, response) ->
            return callback(err) if err
            callback(null, new Container(name, client, response))
            
module.exports = Container
        
    