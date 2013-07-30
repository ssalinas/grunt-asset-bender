module.exports = (grunt) ->
    path = require 'path'
    {spawn} = require 'child_process'
    _ = require 'underscore'
    Q = require 'q'

    grunt.registerTask 'static3_build', 'Precompile using HubSpot static v3', ->
        HS_STATIC_PATH_ENV_NAME = 'HS_STATIC_PATH'
        HS_STATIC_EXECUTABLE_NAME = 'hs-static'
        done = @async()

        runStatic3 = (sourceDir) ->
            grunt.log.writeln "Building project in #{sourceDir}"
            deferred = Q.defer()

            staticBuildProcess = spawn staticExecutable, ["precompile", "-p", sourceDir, "-t", options.destDir],
                env: _.extend process.env, options.envVars
                cwd: options.assetBenderPath

            staticBuildProcess.stdout.on 'data', (data) ->
                grunt.verbose.write data

            staticBuildProcess.stderr.on 'data', (data) ->
                grunt.log.error data

            staticBuildProcess.on 'exit', (code) ->
                if code is 0
                    deferred.resolve()
                else
                    deferred.reject(new Error "Exit with #{code}")

            return deferred.promise

        options = @options
            assetBenderPath: process.env[HS_STATIC_PATH_ENV_NAME] or "~/dev/src/hubspot_static_daemon" # default location is that from setup script
            sourceDir: process.cwd()
            destDir: path.join(process.cwd(), "build")
            envVars: {}

        staticExecutable = path.join options.assetBenderPath, HS_STATIC_EXECUTABLE_NAME

        if not grunt.file.exists staticExecutable
            grunt.log.error """
            Static3 not found at #{staticExecutable}.
            If it's in a nonstandard location, set its location in your #{HS_STATIC_PATH_ENV_NAME} environment variable.
            """

        grunt.log.writeln "Starting static build with #{staticExecutable}"

        if not _.isArray(options.sourceDir) then options.sourceDir = [options.sourceDir]

        r = null
        for b in options.sourceDir
            if not r?
                r = runStatic3(b)
            else
                r = r.then -> runStatic3(b)

        r.done ->
            grunt.log.writeln "Done with build."
            done()
        , (fail) ->
            done new Error "Exit with #{code}"
