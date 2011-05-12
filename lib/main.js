require("coffee-script");

var client = require("./client");
var container = require("./container");
var errors = require("./errors");
var storageObject = require("./storage_object");
var utils = require("./utils");

var OpenstackClient = {
    Client: client,
    Container: container,
    Error: errors,
    StorageObject: storageObject,
    Utils: utils
};

module.exports = OpenstackClient;