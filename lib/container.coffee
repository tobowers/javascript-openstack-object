
class Container
    constructor: (@name, @client, response) ->
        @metadata = {}
        @parseHeadResponse(response) if response

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
        
            
module.exports = Container
        
    