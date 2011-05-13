vows = require 'vows'
assert = require 'assert'
Storage = require './../index'
TestCleaner = require './test_cleaner'
Path = require 'path'
fs = require 'fs'

goodCredentials = require('./credentials').good
badCredentials = require("./credentials").bad

testContainerName = "storageObjectTestContainer"
testObjectName = "storageObjectTestObject.txt"

testCleaner = TestCleaner.initialize {objects: ["#{testContainerName}/#{testObjectName}"], containers: [testContainerName]}

pathToFileUpload = Path.resolve("#{__dirname}/helper_files/small_text.txt")
uploadFileData = fs.readFileSync(pathToFileUpload, 'utf8')


pathToTmp = Path.resolve("#{__dirname}/tmp")
fs.mkdirSync(pathToTmp, "0600") unless Path.existsSync(pathToTmp)

pathToTmpDownloadFile = Path.join(pathToTmp, "tempDownload.txt")
fs.unlinkSync(pathToTmpDownloadFile) if Path.existsSync(pathToTmpDownloadFile)

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
                
).addBatch(
    "after authing and creating a container and object":
        topic: ->
            callback = @callback
            client.setAuth (err, auth) ->
                return callback(err) if err
                Storage.Container.create testContainerName, client, (err, container) ->
                    container.createObject(testObjectName, callback)
                return
            return
        "writing from a file": 
            topic: (storageObject) ->
                storageObject.writeFromFile(pathToFileUpload, @callback)
                return
            "should not error": (err, storageObject) ->
                assert.isNull(err)
            "and then reading it back":
                topic: (storageObject) ->
                    storageObject.data(@callback)
                    return
                "should have the same data": (err, data) ->
                    assert.equal(data, uploadFileData)
            "and then saving it to a file":
                topic: (storageObject) ->
                    callback = @callback
                    path = pathToTmpDownloadFile
                    storageObject.saveToFile path, (err, obj) ->
                        return callback(err) if err
                        fs.readFile(path, "utf8", callback)
                    return
                "should have the same data as the uploaded file": (err, data) ->
                    assert.equal(data, uploadFileData)
            
            
).export(module)
