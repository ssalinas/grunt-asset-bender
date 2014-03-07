path = require 'path'
{spawn} = require 'child_process'
_ = require 'underscore'
Q = require 'q'


HS_STATIC_EXECUTABLE_NAME = 'hs-static'
HS_STATIC_DEFAULT_PATH = "~/dev/src/hubspot_static_daemon"
HS_STATIC_PATH_ENV_NAME = 'HS_STATIC_PATH'


exports.init = (grunt) ->
    utils = require('./utils').init(grunt)

    class LegacyAssetBenderRunner

        constructor: (options = {}) ->
            @command = options.command
            throw new Error("No command specified") unless @command?

            @bufferOutput = options.bufferOutput ? false

            # hs-static options
            @args = options.args || []
            @mode = options.mode or "development"

            @projects = options.project
            @projects = [ @projects ] if @projects? and not Array.isArray @projects

            @buildVersionMap = options.buildVersions

            @destDir = options.destDir
            @restrict = options.restrict
            @archiveDir = options.archiveDir
            @mirrorArchiveDir = options.mirrorArchiveDir
            @globalAssetsDir = options.globalAssetsDir
            @tempDir = options.tempDir
            @domain = options.domain
            @fixedDepsPath = options.fixedDepsPath
            @headless = options.headless
            @usePrebuilt = options.usePrebuilt
            @debug = options.debug
            @limitTo = options.limitTo
            @ignore = options.ignore
            @production = options.production

            # other (non-hs-static) options
            @envVars = options.envVars or {}
            @path = utils.expandHomeDirectory(process.env[HS_STATIC_PATH_ENV_NAME] or options.assetBenderPath or HS_STATIC_DEFAULT_PATH)
            @executable = path.join @path, HS_STATIC_EXECUTABLE_NAME

            unless grunt.file.exists @executable
                grunt.log.error """
                No #{HS_STATIC_EXECUTABLE_NAME} command found at #{@executable}.
                If it's in a nonstandard location, set its location in your
                #{HS_STATIC_PATH_ENV_NAME} environment variable.
                """

        # A simple way to make sure the '//' or 'http://' in the domain string
        # is escaped for the command line
        domainOption: ->
            ['--domain', "'#{@domain}'"] if @domain?

        limitToPathsOption: ->
            if _.isArray @limitTo
                ['--limit-to', @limitTo.join(',')]
            else if _.isString @limitTo
                ['--limit-to', @limitTo]

        ignoredPathsOption: ->
            if _.isArray @ignore
                ['--ignored-paths', @ignore.join(',')]
            else if _.isString @ignore
                ['--ignored-paths', @ignore]

        projectOptions: ->
            if @projects? and @projects.length >= 0
                _.flatten(["-p", dir] for dir in @projects)

        buildVersionOptions: ->
            if @buildVersionMap?
                _.flatten(["-b", "#{dep}:#{version}"] for own dep, version of @buildVersionMap)

        # Some metaprogramming for all the simple passthough options and flags
        basicOptionFunctions =
            modeOption:              "--mode"
            destDirOption:           "--target"
            restrictOption:          "--restrict"
            tempDirOption:           "--temp"
            archiveDirOption:        "--archive-dir"
            mirrorArchiveDirOption:  "--mirror-archive-dir"
            fixedDepsPathOption:     "--fixed-deps-path"
            globalAssetsDirOption:   "--global-assets-dir"

        basicFlagFunctions =
            headlessFlag:            "--headless"
            debugFlag:               "--debug"
            usePrebuiltFlag:         "--use-prebuilt-static-conf"
            productionFlag:          "--production"

        for own funcName, flag of basicOptionFunctions
            do (funcName, flag) ->
                varName = funcName.replace 'Option', ''
                LegacyAssetBenderRunner::[funcName] = -> [flag, @[varName]] if @[varName]

        for own funcName, flag of basicFlagFunctions
            do (funcName, flag) ->
                varName = funcName.replace 'Flag', ''
                LegacyAssetBenderRunner::[funcName] = -> flag if @[varName]

        buildOptionsArray: ->
            bits = []

            # Every potential option
            bits.push @projectOptions()
            bits.push @buildVersionOptions()
            bits.push @domainOption()
            bits.push @limitToPathsOption()
            bits.push @ignoredPathsOption()

            for optionFunc, flag of basicOptionFunctions
                bits.push @[optionFunc]()

            for optionFunc, flag of basicFlagFunctions
                bits.push @[optionFunc]()

            # Flatten everything and omit empties
            @args.concat(_.flatten(_.filter(bits, (x) -> x?)))


        buildFullCommandString: ->
            [@executable, @command].concat(@buildOptionsArray()).join ' '

        run: ->
            deferred = Q.defer()
            grunt.log.writeln "Running: ", @buildFullCommandString()

            compileProc = spawn @executable, [@command].concat(@buildOptionsArray()),
                env: _.extend process.env, @envVars
                cwd: @path

            if @bufferOutput
                stdoutChunks = []
                stderrChunks = []
                stdoutAndStderrChunks = []

                compileProc.stdout.on 'data', (data) =>
                    stdoutChunks.push data
                    stdoutAndStderrChunks.push data

                compileProc.stderr.on 'data', (data) =>
                    stderrChunks.push data
                    stdoutAndStderrChunks.push data

                compileProc.on 'exit', (code) ->
                    result =
                        stdout: stdoutChunks.join('')
                        stderr: stderrChunks.join('')
                        stdoutAndStderr: stdoutAndStderrChunks.join('')
                        code: code

                    if code is 0
                        deferred.resolve result
                    else
                        deferred.reject result

            else
                compileProc.stdout.on 'data', (data) => grunt.verbose.write data
                compileProc.stderr.on 'data', (data) => grunt.log.error data

                compileProc.on 'exit', (code) ->
                    if code is 0
                        deferred.resolve()
                    else
                        deferred.reject(new Error "Exit with #{code}")

            return deferred.promise


    # Export the constructor
    LegacyAssetBenderRunner


