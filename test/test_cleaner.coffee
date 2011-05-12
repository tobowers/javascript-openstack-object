vows = require 'vows'
assert = require 'assert'

Storage = require './../lib/main'

goodCredentials = require('./credentials').good
badCredentials = require("./credentials").bad

client = Storage.Client.create(goodCredentials)

class TestCleaner
    constructor: (opts) ->
        @objects = opts.objects || []
        @containers = opts.containers || []
    
    cleanObjects: (callback) =>
        numberDeleted = 0
        numberToDelete = @objects.length
        return callback(null, 0) if numberToDelete == 0
        
        for obj in @objects
            do (obj) ->
                objArray = obj.split("/")
                containerName = objArray[0]
                objectName = objArray[1]
                container = new Storage.Container(containerName, client)
                container.destroyObject objectName, (err, resp) ->                    
                    return callback(err) if err and not err.statusCode == "404"
                    numberDeleted++
                    callback(null, numberDeleted) if numberDeleted >= numberToDelete
    
    cleanContainers: (callback) =>
        numberDeleted = 0
        numberToDelete = @containers.length
        return callback(null, 0) if numberToDelete == 0
        for containerName in @containers
            do (containerName) ->
                container = new Storage.Container(containerName, client)
                container.destroy (err, resp) ->
                    return callback(err) if err and not err.statusCode == "404"
                    numberDeleted++
                    callback(null, client) if numberDeleted >= numberToDelete
    
    clean: (callback) =>
        doClean = (err, res) =>
            return callback(err) if err
            @cleanObjects (err, number) =>
                return callback(err) if err
                @cleanContainers (containerError, containerCount) ->
                    return callback(containerError) if containerError
                    callback(null, true)
                    
        if client.isAuthorized
            doClean()
        else
            client.setAuth(doClean)
       
    @initialize: (opts) ->
        new TestCleaner(opts)
        
# TestCleaner =
#     initialize: (opts) ->
#         opts ?= {}
#         objects = opts.objects if opts.objects?
#         containers = opts.containers if opts.containers?
#     destroyObject: (container, objectName, callback) ->
#         container = new Storage.Container(containerName, client) if Storage.Utils.isString(container)
#         container.destroyObject objectName, (err, resp) ->
#             return callback(err) if err and not err.statusCode == "404"
#             callback(null, client)
#     vows:
#         "clean for tests": 
#             topic: ->
#                 callback = @callback
#                 client.setAuth (err, auth) ->
#                     callback(err, client)
#                 return
#             "delete the testobjects":
#                 topic: (client) ->
#                     numberDeleted = 0
#                     callback = @callback
#                     callback(null,client) if objects.length == 0
#                     for obj in objects
#                         do (obj) ->
#                             objArray = obj.split("/")
#                             containerName = objArray[0]
#                             objectName = objArray[1]
#                             container = new Storage.Container(containerName, client)
#                             container.destroyObject objectName, (err, resp) ->
#                                 return callback(err) if err and not err.statusCode == "404"
#                                 numberDeleted++
#                                 callback(null, client) if numberDeleted >= objects.length
#                     return            
#                 "should have worked": (err, client) ->
#                     assert.instanceOf(client, Storage.Client)
#                     
#                 "deleteing test containers":
#                     topic: (client) ->
#                         numberDeleted = 0
#                         callback = @callback
#                         callback(null, client) if containers.length == 0
#                         for container in containers
#                             do (container) ->
#                                 containerName = container
#                                 container = new Storage.Container(containerName, client)
#                                 container.destroy (err, resp) ->
#                                     return callback(err) if err and not err.statusCode == "404"
#                                     numberDeleted++
#                                     callback(null, client) if numberDeleted >= containers.length 
#                         return
#                     "should have worked": (err, client) ->
#                         assert.instanceOf(client, Storage.Client)     
        
module.exports = TestCleaner