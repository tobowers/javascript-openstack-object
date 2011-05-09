vows = require 'vows'
assert = require 'assert'
Client = require './../lib/main'

authInfo = {authUrl: 'https://secure.motionbox.com/auth/v1.0', username: "blah:blah", apiKey: "blah"}

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
                console.log("setting auth")
            "should log": (err, response, body) ->
                console.log("called test")
            
).export module
