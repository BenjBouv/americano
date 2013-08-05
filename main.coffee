express = require 'express'
fs = require 'fs'

# TODO:
# make americano plugin as npm package
# add comments to this file
# add tests
# find a way to manage juggling model properly
# americano wraps express
module.exports = americano = express

# root folder, required to find the configuration files
# TODO make it parameterable.
root = process.cwd()

config = []

_configure = (app) ->

    try
        config = require "#{root}/config"
    catch err
        console.log err
        console.log "Can't load config file, use default one instead"

    process.env.NODE_ENV = 'development' unless process.env.NODE_ENV?
    _configureEnv app, env, middlewares for env, middlewares of config

_configureEnv = (app, env, middlewares) ->
    if env is 'common'
        app.use middleware for middleware in middlewares
    else
        app.configure env, =>
            app.use middleware for middleware in middlewares

_loadRoutes = (app) ->

    try
        routes = require "#{root}/controllers/routes"
    catch err
        console.log err
        console.log "Route confiiguration file is missing, make sure " + \
                    "routes.(coffee|js) is located at the root of the " + \
                    "controlllers folder."
        process.exit 1

    for path, controllers of routes
        for verb, controller of controllers
            for name, action of controller
                try
                    app[verb] path, \
                              require("#{root}/controllers/#{name}")[action]
                catch e
                    console.log "Can't load controller for " + \
                                "route #{verb} #{path} #{action}"
                    process.exit 1

_loadPlugin = (app, plugin, callback) ->
    console.log "add plugin: #{plugin}"
    require("#{root}/plugins/#{plugin}") app, callback

_loadPlugins = (app, callback) ->
    pluginList = []

    for plugin in fs.readdirSync "#{root}/plugins"
        fileExtension = plugin.substring(plugin.length - 7, plugin.length)
        if  fileExtension is '.coffee'
            name = plugin.substring 0, plugin.length - 7
            pluginList.push name

    _loadPluginList = (list) ->
        if list.length > 0
            plugin = list.pop()
            _loadPlugin app, plugin, (err) ->
                if err
                    console.log "#{plugin} failed to load."
                else
                    console.log "#{plugin} loaded."
                _loadPluginList list
        else
            callback()

    _loadPluginList pluginList

_new = (callback) ->
    app = americano()
    _configure app
    _loadRoutes app
    _loadPlugins app, ->
        callback app

americano.start = (options, callback) ->
    port = options.port || 3000
    console.log process.cwd()
    _new (app) ->
        app.listen port
        options.name ?= "Americano"
        console.log "#{options.name} server is listening on port #{port}..."
        console.info "Configuration for #{process.env.NODE_ENV} loaded."

        callback app if callback?