vows = require 'vows'
assert = require 'assert'
Storage = require './../index'
TestCleaner = require './test_cleaner'

goodCredentials = require('./credentials').good
badCredentials = require("./credentials").bad

testContainerName = "containerTestContainer"
testObjectName = "containerTestObject.txt"

testCleaner = TestCleaner.initialize {objects: ["#{testContainerName}/#{testObjectName}"], containers: [testContainerName]}

client = Storage.Client.create(goodCredentials)

vows.describe('Container').addBatch(
    "test cleaner":
        topic: ->
            testCleaner.clean(@callback)
            return
        "should work": (err, result) ->
            assert.isNull(err)
).addBatch(
    "after authing":
        topic: ->
            client.setAuth @callback
            return
        "should be able to create a container":
            topic: () ->
               Storage.Container.create(testContainerName, client, @callback)
               return
            "should not error": (err, container) ->
                assert.isNull(err)
            "should return a container": (err, container) ->
                assert.instanceOf(container, Storage.Container)
            "container should have object count": (err, container) ->
                assert.equal(container.count, 0)
                
            "when setting metadata":
                topic: (container) ->
                    callback = @callback
                    container.setMetadata {"oh hi long metadata": "testValue"}, (err, container) ->
                        return callback(err) if err
                        container.reload(callback)
                    container.metadata = {} #let's be sneaky here to make sure the reload worked
                    return
                "should have the new metadata": (err, container) ->
                    assert.equal(container.metadata["oh hi long metadata"], "testValue")
            "when setting readAcl":
                topic: (container) ->
                    callback = @callback
                    container.setReadAcl "r:*", (err, container) ->
                        return callback(err) if err
                        container.reload(callback)
                    return
                "should update the acl": (err, container) ->
                    assert.equal(container.readAcl, "r:*")
            "and when setting writeAcl":
                topic: (container) ->
                    callback = @callback
                    container.setWriteAcl "r:*", (err, container) ->
                        return callback(err) if err
                        container.reload(callback)
                    return
                "should update the acl": (err, container) ->
                    assert.equal(container.writeAcl, "r:*")
                    
                 
).addBatch(
    "after authing and creating a container":
        topic: ->   
            callback = @callback
            client.setAuth (err, auth) ->
                Storage.Container.create(testContainerName, client, callback)
            return
            
        "deleting the container":
            topic: (container) -> 
                container.destroy(@callback)
                return
            "should not error": (err, container) ->
                assert.isNull(err)
            "should return the container": (err, container) ->
                assert.instanceOf(container, Storage.Container)
            "and then doing a get container":
                topic: (container) ->
                    client = Storage.Client.create(goodCredentials)
                    callback = @callback
                    client.setAuth (err, auth) ->
                        return callback(err) if err
                        client.getContainer(testContainerName, callback)
                    return
                "should return a 404": (err, container) ->
                    assert.equal(err.statusCode, "404")
            
).addBatch(
    "testing StorageObject methods":
        topic: ->
            callback = @callback
            client.setAuth (err, auth) ->
                return callback(err) if err
                Storage.Container.create(testContainerName, client, callback)
            return
        "object creation":
            topic: (container) ->
                callback = @callback
                # container.createObject(testObjectName, (err, obj) ->
                #     console.log("err %o obj %o", err, obj)
                #     callback(err, obj)
                # )
                container.createObject(testObjectName, @callback)
                return
            "should not error": (err, storageObject) ->
                assert.isNull(err)
            "should return a storage object": (err, storageObject) ->
                assert.instanceOf(storageObject, Storage.StorageObject)
            "listing the objects":
                topic: (storageObject) ->
                    storageObject.container.objects(@callback)
                    return
                "should return an array": (err, objects) ->
                    assert.isArray(objects)
                "should include the testObject": (err, objects) ->
                    assert.include(objects, testObjectName)
                
).export(module)
