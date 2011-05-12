Client = require("./client")
Container = require("./container")
Utils = require('./utils')
Error = require('./errors')

mime = require('mime')

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
    ###
        def write(data = nil, headers = {})
          raise CloudFiles::Exception::Syntax, "No data or header updates supplied" if ((data.nil? && $stdin.tty?) and headers.empty?)
          if headers['Content-Type'].nil?
            type = MIME::Types.type_for(self.name).first.to_s
            if type.empty?
              headers['Content-Type'] = "application/octet-stream"
            else
              headers['Content-Type'] = type
            end
          end
          # If we're taking data from standard input, send that IO object to cfreq
          data = $stdin if (data.nil? && $stdin.tty? == false)
          response = self.container.connection.storage_request("PUT", @storagepath, headers, data)
          code = response.code
          raise CloudFiles::Exception::InvalidResponse, "Invalid content-length header sent" if (code == "412")
          raise CloudFiles::Exception::MisMatchedChecksum, "Mismatched etag" if (code == "422")
          raise CloudFiles::Exception::InvalidResponse, "Invalid response code #{code}" unless (code =~ /^20./)
          make_path(File.dirname(self.name)) if @make_path == true
          self.refresh
          true
        end
    ###
    
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
    
    ###
            def data(size = -1, offset = 0, headers = {})
          if size.to_i > 0
            range = sprintf("bytes=%d-%d", offset.to_i, (offset.to_i + size.to_i) - 1)
            headers['Range'] = range
          end
          response = self.container.connection.storage_request("GET", @storagepath, headers)
          raise CloudFiles::Exception::NoSuchObject, "Object #{@name} does not exist" unless (response.code =~ /^20/)
          response.body
        end
    ###
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
