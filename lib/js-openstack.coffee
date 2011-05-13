require.paths.unshift(require('path').join(__dirname, '.'))

storageObject = require("storage_object")
container = require("container")
errors = require("errors")
utils = require("utils")
client = require("client")
version = require("version")


OpenstackClient =
    Client: client
    Container: container
    Error: errors
    StorageObject: storageObject
    Utils: utils
    version: version

module.exports = OpenstackClient;