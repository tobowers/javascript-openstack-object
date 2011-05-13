client = require("./client")
container = require("./container")
errors = require("./errors")
storageObject = require("./storage_object")
utils = require("./utils")

OpenstackClient =
    Client: client
    Container: container
    Error: errors
    StorageObject: storageObject
    Utils: utils

module.exports = OpenstackClient;