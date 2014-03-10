fs = require 'fs'
path = require 'path'
Q = require 'q'
graphite = require 'graphite'
_ = require 'underscore'
{ inspect } = require 'util'
{ spawn } = require 'child_process'

{ DualGraphiteStopwatch, FauxGraphiteStopwatch } = require '../lib/graphiteStopwatch.coffee'


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
        contents = grunt.file.read configPath
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
        server =    grunt.config.get 'bender.graphite.server'
        port =      grunt.config.get 'bender.graphite.port'
        namespace = grunt.config.get('bender.graphite.namespace') ? 'jenkins'
        jobName =   grunt.config.get 'bender.build.jobName'

        if server and port
            graphiteClient = graphite.createClient("plaintext://#{server}:#{port}")
            _global_stopwatch = new DualGraphiteStopwatch("#{namespace}.bender.", "#{jobName}.", graphiteClient)
        else
            grunt.log.writeln "Not logging to graphite, GRAPHITE_SERVER and GRAPHITE_PORT must be set."
            _global_stopwatch = new FauxGraphiteStopwatch()

    envVarEnabled = (envVarName, defaultValue = true) ->
        value = process.env[envVarName] ? new String(defaultValue)
        value = value.toLowerCase()
        value in ['1', 'true', 'on', 'yes']

    copyFileSync = (srcFile, destFile) ->
        content = grunt.file.read srcFile
        grunt.file.write destFile, content

    moveSync = (source, dest) ->
        grunt.fail.warn "Can't move, #{source} doesn't exist" unless fs.existsSync source
        fs.renameSync source, dest
        grunt.fail.warn "Move failed #{dest} doesn't exist" unless fs.existsSync dest
        grunt.verbose.writeln "Moved: ", source, "to", dest

    benderInfoForProject = (projectName) ->
        return grunt.config.get('bender.build.projectInfo') if grunt.config.get 'bender.build.projectInfo'

        grunt.config.requires 'bender.build.fixedProjectDeps',
                              'bender.build.copiedProjectDir',
                              'bender.build.archiveDir',
                              'bender.build.version'

        LegacyAssetBenderRunner = require('./legacy_asset_bender_runner').init(grunt)

        buildVersions = _.extend {}, grunt.config.get('bender.build.fixedProjectDeps')
        buildVersions[projectName] = grunt.config.get 'bender.build.version'

        runner = new LegacyAssetBenderRunner
            command: 'project_info'
            args: [projectName]
            bufferOutput: true
            buildVersions: buildVersions
            project: grunt.config.get('bender.build.copiedProjectDir')
            archiveDir: grunt.config.get('bender.build.archiveDir')

        runner.run().then (result) ->
            projectInfo = JSON.parse result.stdout
            grunt.verbose.writeln result.stdoutAndStderr
            projectInfo
        .fail (result) ->
            grunt.log.writeln result.stdoutAndStderr
            grunt.fail.warn "Error getting project_info for #{projectName}"

    numCPUs = ->
        Math.max(require('os').cpus().length / 2, 1)

    # A helper method to compose a find and replace command made of up find, xargs, and sed
    findAndReplace = (options={}) ->
        grunt.config.requires 'bender.build.isGNU'

        commands = options.command || options.commands
        commands = [commands] if not Array.isArray(commands)

        parts = []

        # Start the find part (find ... -type f -print0)
        parts.push 'find', options.sourceDirectory, '-type', 'f'

        if options.filesToReplace
            parts.push '-name', "'#{options.filesToReplace}'"

        # Ignore hidden, binary, and image types (not-exhaustive)
        typesToIgnore = [
            '.*'
            '*.gif'
            '*.jpg'
            '*.png'
            '*.eps'
            '*.ico'
            '*.ai'
            '*.swf'
            '*.cur'
            '*.pdn'
        ]

        for extension in typesToIgnore
            parts.push '-not', '-iname', "'#{extension}'"

        parts.push '-print0'

        # Start xargs part (xargs -0 sed -i '' -e ...)
        parts.push '|', 'xargs'

        if options.parallel
            parts.push '-P', numCPUs()

        parts.push '-0', 'sed'


        # Macs are slightly different with inplace editing
        if not grunt.config.get('bender.build.isGNU')
            parts.push '-i', "''"
        else
            parts.push "-i''"

        # Macs use a different flag for extended regexes
        if options.useExtendedRegex and not grunt.config.get('bender.build.isGNU')
            parts.push '-E'
        else if options.useExtendedRegex
            parts.push '-r'

        for command in commands
            # Macs also do word-breaks differently
            if not grunt.config.get('bender.build.isGNU')
                command = command.replace '\\<', '[[:<:]]'

            parts.push '-e', command

        # Yeah, joining and execing a whole string is gross... (too lazy right now
        # to re-do the escaping on all the uses of this command)
        sedCmd = parts.join ' '

        grunt.verbose.writeln "Running: #{sedCmd}"
        executeCommand(sedCmd)


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
        copyFileSync
        benderInfoForProject
        numCPUs
        findAndReplace
    }
