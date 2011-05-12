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
            "should return a storage object": (err, obj) ->
                assert.instanceOf(obj, Storage.StorageObject)
                
).export(module)
