Error = {}

class Error.ObjectStoreError extends Error
    constructor: (@message, @statusCode) ->

class Error.BadAuthError extends Error.ObjectStoreError 
    
class Error.BadRequest extends Error.ObjectStoreError

class Error.InvalidResponse extends Error.ObjectStoreError
    
class Error.BadBodySpecified extends Error.ObjectStoreError

module.exports = Error
