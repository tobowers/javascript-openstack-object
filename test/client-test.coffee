vows = require 'vows'
assert = require 'assert'
Client = require './../lib/main'

authInfo = require './credentials'

vows.describe('Client').addBatch(
    "client initialization":
        topic: (topic) ->
            return Client.create(authInfo)
        "should save the auth": (client) ->
            assert.equal(authInfo, client.auth)
        "should not be isAuthorized": (client) ->
            assert.isFalse(client.isAuthorized)
        "setting auth": 
            topic: (client) ->
                client.setAuth(@callback)
            "should not error": (err, response, body) ->
                assert.isNull(err)
            
).export module
