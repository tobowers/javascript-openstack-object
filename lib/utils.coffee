Utils = {
    isString: (obj) ->
        !!(obj == '' || (obj && obj.charCodeAt && obj.substr)) #taken from underscore.js
}

module.exports = Utils