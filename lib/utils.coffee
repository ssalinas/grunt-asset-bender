fs = require 'fs'
path = require 'path'
Q = require 'q'
graphite = require 'graphite'
{ spawn } = require 'child_process'

{ DualGraphiteStopWatch, FauxGraphiteStopWatch } = require '../lib/graphiteStopwatch.coffee'

innerExports = undefined

exports.init = (grunt) ->
    return innerExports if innerExports?

    innerExports = {}

    expandHomeDirectory = (filepath) ->
        if filepath?.substr(0,1) == '~' and process.env.HOME
            process.env.HOME + filepath.substr(1)
        else
            filepath

    # Looks to see if the debug, compressed, or both builds were performed.
    # If only one happened, return it. But if both happened, return compressed.
    #
    # This is necessary to do things like get the correct build output dir
    # depending on different build configurations.
    preferredModeBuilt = ->
        grunt.config.requires 'bender.build.modesBuilt'
        modesBuilt = grunt.config.get 'bender.build.modesBuilt'

        if modesBuilt.length == 0
            grunt.fail.warn "Error, nothing has been built but this task requires it"
        else if modesBuilt.length > 1 and modesBuilt.indexOf 'compressed' >= 0
            'compressed'
        else if modesBuilt.length > 1
            'development'
        else
            modesBuilt[0]

    preferredOutputDir = ->
        preferredMode = preferredModeBuilt()
        grunt.config.requires "bender.build.#{preferredMode}.outputDir"
        grunt.config.get "bender.build.#{preferredMode}.outputDir"

    secondaryOutputDir = ->
        preferredMode = preferredModeBuilt(grunt)

        grunt.config.requires 'bender.build.modesBuilt'
        modesBuilt = grunt.config.get 'bender.build.modesBuilt'

        if modesBuilt.length > 1 and preferredMode == 'compressed'
            grunt.config.requires 'bender.build.development.outputDir'
            grunt.config.get 'bender.build.development.outputDir'


    writeFile = (contents, filepath) ->
        grunt.verbose.writeln "Writing #{contents} to #{filepath}"
        fs.writeFile filepath, contents

    covertUnderscoresToCamelCase = (str) ->
        str.replace /_([a-z])/g, (g) ->
            g[1].toUpperCase()

    covertUnderscoreKeysInObjectToCamelCase = (object) ->
        newObject = {}

        for own key, value of object
            newObject[covertUnderscoresToCamelCase(key)] = value

        newObject

    loadBenderProjectConfig = (projectDir) ->
        configPath = path.join projectDir, 'static', 'static_conf.json'
        contents = fs.readFileSync configPath, "utf8"
        config = JSON.parse contents

        # Support legacy key names that used underscores instead of camel case
        covertUnderscoreKeysInObjectToCamelCase config

    # Runs a shell command interpolating the command (allowing for pipes, etc) and
    # outputing stdout and stderr normally. Returns a promise.
    executeCommand = (command, cwd = null) ->
        deferred = Q.defer()
        grunt.verbose.writeln "Running: ", command

        compileProc = spawn 'sh', ['-c', command],
            cwd: cwd,
            stdio: 'inherit'

        compileProc.on 'exit', (code) ->
            if code is 0
                deferred.resolve()
            else
                deferred.reject(new Error "Exit with #{code}")

        deferred.promise

    # Detect whether this system is using GNU tools or not to deal with
    # differences between GNU and BSD options. (Ghetto detection from
    # http://stackoverflow.com/questions/8747845/how-can-i-detect-bsd-vs-gnu-version-of-date-in-shell-script)
    isGNU = ->
        executeCommand("date --version >/dev/null 2>&1").then ->
            true
        , ->
            grunt.log.writeln "This system is using non-GNU commands"
            false


    _global_stopwatch = null

    graphiteStopwatch = ->
        stopwatch = _global_stopwatch ? createGraphiteStopwatch(grunt)

    createGraphiteStopwatch = ->
        server = grunt.config.get 'bender.graphite.server'
        port = grunt.config.get 'bender.graphite.port'
        namespace = grunt.config.get('bender.graphite.namespace') ? 'jenkins'

        if server and port
            graphiteClient = graphite.createClient("plaintext://#{server}:#{port}")
            _global_stopwatch = new DualGraphiteStopWatch("#{namespace}.bender.", "#{graphite.config.get 'bender.build.jobName'}.", graphiteClient)
        else
            grunt.log.writeln "Not logging to graphite, GRAPHITE_SERVER and GRAPHITE_PORT must be set."
            _global_stopwatch = new FauxGraphiteStopWatch()

    envVarEnabled = (envVarName, defaultValue = true) ->
        value = process.env[envVarName] ? new String(defaultValue)
        value = value.toLowerCase()
        value in ['1', 'true', 'on', 'yes']

    copyFileSync = (srcFile, destFile, encoding) ->
        content = fs.readFileSync(srcFile, encoding)
        fs.writeFileSync(destFile, content, encoding)

    moveSync = (source, dest) ->
        grunt.fail.warn "Can't move, #{source} doesn't exist" unless fs.existsSync source
        fs.renameSync source, dest
        grunt.fail.warn "Move failed #{dest} doesn't exist" unless fs.existsSync dest
        grunt.verbose.writeln "Moved: ", source, "to", dest


    innerExports = {
        expandHomeDirectory
        preferredModeBuilt
        preferredOutputDir
        secondaryOutputDir
        writeFile
        loadBenderProjectConfig
        executeCommand
        isGNU
        graphiteStopwatch
        envVarEnabled
        moveSync
    }
