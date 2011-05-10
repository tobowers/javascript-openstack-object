vows = require 'vows'
assert = require 'assert'
Client = require './../lib/main'
Container = require './../lib/container'

goodCredentials = require('./credentials').good
badCredentials = require("./credentials").bad

testContainerName = "containerTestContainer"

vows.describe('Container').addBatch(
    "after authing":
        topic: ->
            client = Client.create(goodCredentials)
            callback = @callback
            client.setAuth (err, auth) ->
                callback(err, client)
            return
        "should be able to create a container":
            topic: (client) ->
               callback = @callback
               Container.create(testContainerName, client, callback)
               return
            "should not error": (err, container) ->
                assert.isNull(err)
            "should return a container": (err, container) ->
                assert.instanceOf(container, Container)
            "container should have object count": (err, container) ->
                assert.equal(container.count, 0)
                
            "and when setting metadata":
                topic: (container) ->
                    callback = @callback
                    container.setMetadata {"oh hi long metadata": "testValue"}, (err, container) ->
                        return callback(err) if err
                        container.reload(callback)
                    container.metadata = {} #let's be sneaky here to make sure the reload worked
                    return
                "should have the new metadata": (err, container) ->
                    assert.equal(container.metadata["oh hi long metadata"], "testValue")
                    
                    
                 
).addBatch(
    "after authing and creating a container":
        topic: ->
            client = Client.create(goodCredentials)
            callback = @callback
            client.setAuth (err, auth) ->
                return callback(err) if err
                Container.create(testContainerName, client, callback)
            return
            
        "deleting the container":
            topic: (container) -> 
                container.destroy(@callback)
                return
            "should not error": (err, container) ->
                assert.isNull(err)
            "should return the container": (err, container) ->
                assert.instanceOf(container, Container)
            "and then doing a get container":
                topic: (container) ->
                    client = Client.create(goodCredentials)
                    callback = @callback
                    client.setAuth (err, auth) ->
                        return callback(err) if err
                        client.getContainer(testContainerName, callback)
                    return
                "should return a 404": (err, container) ->
                    assert.equal(err.statusCode, "404")
            
).export(module)
