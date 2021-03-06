vows = require 'vows'
assert = require 'assert'
Storage = require './../index'
TestCleaner = require './test_cleaner'

goodCredentials = require('./credentials').good
badCredentials = require("./credentials").bad

testContainerName = "clientTestContainer"

testCleaner = TestCleaner.initialize {containers: [testContainerName]}

client = Storage.Client.create(goodCredentials)

vows.describe('Client').addBatch(
    "test cleaner":
        topic: ->
            testCleaner.clean(@callback)
            return
        "should work": (err, result) ->
            assert.isNull(err)
).addBatch(
    "storage object from client":
        topic: ->
            client.storageObject("test", "test");
        "should be a storage client": (object) ->
            assert.instanceOf(object, Storage.StorageObject)
    "container from client":
        topic: ->
            client.container("test")
        "should be a container": (container) ->
            assert.instanceOf(container, Storage.Container)
        

).addBatch(
    "client initialization":
        topic: (topic) ->
            Storage.Client.create(goodCredentials)
        "should save the auth": (client) ->
            assert.equal(goodCredentials, client.auth)
        "should not be isAuthorized": (client) ->
            assert.isFalse(client.isAuthorized)
        "setting auth": 
            topic: (client) ->
                callback = @callback
                client.setAuth (err, response, body) ->
                    callback(err, response, body, client)
                return # coffee script will return the last bit which vows doesn't like
            "should not error": (err, response, body) ->
                assert.isNull(err)
            "should set the storageUrl": (err, response, body, client) ->
                assert.isString(client.storageUrl)
            "should set the storageToken": (err,response,body,client) ->
                assert.isString(client.storageToken)
            "should set isAuthorized to true": (err,response,body,client) ->
                assert.isTrue(client.isAuthorized) 
                
            "should be able to get info on the account":
                topic: (err, response, body, client) ->
                    callback = @callback
                    client.getInfo (err, res) ->
                        callback(err, res, client)
                    return
                "should not error": (err, result) ->
                    assert.isNull(err)
                "should return the bytes and count to the callback": (err, result) ->
                    assert.isNumber(result.bytes)
                    assert.isNumber(result.count)
                "should set the bytes and count used": (err, result, client) ->
                    assert.isNumber(client.bytes)
                    assert.isNumber(client.count)
                    
            "should be able to create container":
                 topic: (err, response, body, client) ->
                     callback = @callback
                     client.createContainer "testContainerName", (err, container) ->
                         callback(err,container,client)
                     return
                 "should return a container": (err, container, client) ->
                     assert.instanceOf(container, Storage.Container)
                 "should be able to get the container after":
                     topic: (container, client) ->
                         callback = @callback
                         client.getContainer "testContainerName", (err, getContainer) ->
                             callback(err, getContainer, client)
                         return
                     "should not error": (err, container) ->
                         assert.isNull(err)
                     "should give back a container": (err, container) ->
                         assert.instanceOf(container, Storage.Container)
                     "should be able to delete it":
                         topic: (container, client) ->
                             callback = @callback
                             client.destroyContainer "testContainerName", (err, result) ->
                                 return callback(err) if err
                                 client.getContainer "testContainerName", callback
                             return
                         "should have an error": (err, result) ->
                             assert.isNotNull(err)
                         "error should be a 404": (err, result) ->
                             assert.equal("404", err.statusCode)
                                 
            
).addBatch(
    "with bad credentials":
        topic: ->
            Storage.Client.create(badCredentials)
        "setting auth":
            topic: (client) ->
                callback = @callback
                client.setAuth (err, response, body) ->
                    callback(err, response, body, client)
                return
            "should raise the BadAuthError": (err, response, body, client) ->
                assert.instanceOf(err, Storage.Error.BadAuthError)
    
).export(module)
