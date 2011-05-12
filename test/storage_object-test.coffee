vows = require 'vows'
assert = require 'assert'
Storage = require './../lib/main'
TestCleaner = require './test_cleaner'

goodCredentials = require('./credentials').good
badCredentials = require("./credentials").bad

testContainerName = "storageObjectTestContainer"
testObjectName = "storageObjectTestObject.txt"

testCleaner = TestCleaner.initialize {objects: ["#{testContainerName}/#{testObjectName}"], containers: [testContainerName]}

client = Storage.Client.create(goodCredentials)

vows.describe('StorageObject').addBatch(
    "test cleaner":
        topic: ->
            testCleaner.clean(@callback)
            return
        "should work": (err, result) ->
            assert.isNull(err)
).addBatch(
    "after authing and creating container":
        topic: ->
            callback = @callback
            client.setAuth (err, auth) ->
                return callback(err) if err
                Storage.Container.create(testContainerName, client, callback)
                return
            return
        "testing creating an object":
            topic: (container) ->
                container.createObject(testObjectName, @callback)
                return
            "should return a storage object": (err, obj) ->
                assert.instanceOf(obj, Storage.StorageObject)
                
            "should be able to write a string":
                topic: (storageObject) ->
                    storageObject.write("oh hai", @callback)
                    return
                "should not error": (err, storageObject) ->
                    assert.isNull(err)
                "reading it back":
                    topic: (storageObject) ->
                        storageObject.data(@callback)
                        return
                    "should have the same data": (err, body) ->
                        assert.equal(body, "oh hai")
                
).export(module)
