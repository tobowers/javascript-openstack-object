
class Container
    constructor: (@name, @client, response) ->
        @metadata = {}
        @parseHeadResponse(response) if response

    reload: (callback) =>
        @client.storageRequest "HEAD", @name, null, null, (err, response) =>
            return callback(err) if err
            @parseHeadResponse(response)
            callback(null, this)
            
    destroy: (callback) =>
        @client.storageRequest "DELETE", @name, null, null, (err, response) =>
            return callback(err) if err
            callback(null, this)
    #     
    # getContainer: (name, callback) =>
    #     @queueOrMakeRequest "GET", @storageUrlFor(name), null, null, (err, response) =>
    #         return callback(err) if err
    #         callback(null, new Container(name, this, response))
    # 
    # deleteContainer: (name, callback) =>
    #     @queueOrMakeRequest "DELETE", @storageUrlFor(name), null, null, (err, response) =>
    #          return callback(err) if err
    #          callback(null, true)
    # 
    # createContainer: (name, callback) =>
    #     @queueOrMakeRequest "PUT", @storageUrlFor(name), null, null, (err, response) =>
    #         return callback(err) if err
    #         callback(null, new Container(name, this, response))

    parseHeadResponse: (response) =>
        headers = response.headers
        @bytes = headers["x-container-bytes-used"]
        @count = headers["x-container-object-count"]
        @containerRead = headers["x-container-read"]
        @containerWrite = headers["x-container-write"]
        for own header, value in headers
            do (header, value) =>
                if match = header.match(/^x-container-meta-(.+)/)
                    @metadata[match[1]] = value
        
        
Container.create = (name, client, callback) ->
    client.storageRequest "PUT", name, null, null, (err, response) =>
        return callback(err) if err
        callback(null, new Container(name, this, response))
            
module.exports = Container
        
    