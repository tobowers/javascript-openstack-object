vows = require 'vows'
assert = require 'assert'
Client = require './../lib/main'

goodCredentials = require('./credentials').good
badCredentials = require("./credentials").bad

vows.describe('Client').addBatch(
    "client initialization":
        topic: (topic) ->
            Client.create(goodCredentials)
        "should save the auth": (client) ->
            assert.equal(goodCredentials, client.auth)
        "should not be isAuthorized": (client) ->
            assert.isFalse(client.isAuthorized)
        "setting auth": 
            topic: (client) ->
                callback = @callback
                client.setAuth (err, response, body) ->
                    callback(err, response, body, client)
                return  
                  
            "should not error": (err, response, body) ->
                assert.isNull(err)
            "should set the storageUrl": (err, response, body, client) ->
                assert.isString(client.storageUrl)
            "should set the storageToken": (err,response,body,client) ->
                assert.isString(client.storageToken)
            "should set isAuthorized to true": (err,response,body,client) ->
                assert.isTrue(client.isAuthorized) 
            
).addBatch(
    "with bad credentials":
        topic: ->
            Client.create(badCredentials)
        "setting auth":
            topic: (client) ->
                callback = @callback
                client.setAuth (err, response, body) ->
                    callback(err, response, body, client)
                return
            "should raise the BadAuthError": (err, response, body, client) ->
                assert.instanceOf(err, Client.BadAuthError)
    
).export(module)
