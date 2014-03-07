_ = require 'underscore'
Q = require 'q'
path = require 'path'
fs = require 'fs'

module.exports = (grunt) ->
    utils = require('../lib/utils').init(grunt)
    LegacyAssetBenderRunner = require('../lib/legacy_asset_bender_runner').init(grunt)

    getBuildHash = (projectName, version, outputDir) ->
        hashPath = path.join outputDir, projectName, "static", "premunged-static-contents-hash.md5"

        try
            hashPath = path.join outputDir, projectName, "static-#{version}", "premunged-static-contents-hash.md5"
            grunt.file.read hashPath
        catch err
            try
                hashPath = path.join outputDir, projectName, "static", "premunged-static-contents-hash.md5"
                grunt.file.read hashPath
            catch err
                grunt.log.writeln "Couldn't read #{hashPath}, this might be an empty static project."

    grunt.registerTask 'bender_build_parallel', 'Precompile debug and compressed assets in parallel using HubSpot static v3', ->
        done = @async()

        options = @options
            project: grunt.config.get('bender.build.copiedProjectDir') or process.cwd()
            destDir: grunt.config.get('bender.build.baseOutputDir') or path.join(process.cwd(), "build")
            assetBenderPath: grunt.config.get 'bender.assetBenderDir'

        projectName      = grunt.config.get 'bender.build.projectName' or path.basename(options.project)
        fixedProjectDeps = grunt.config.get 'bender.build.fixedProjectDeps'
        stopwatch        = utils.graphiteStopwatch(grunt)
        version          = grunt.config.get 'bender.build.version'
        buildVersions    = undefined

        needsToBuildTests = utils.hasJasmineSpecs() and utils.jasmineTestsEnabled()

        if fixedProjectDeps and version
            buildVersions = _.extend {}, grunt.config.get('bender.build.fixedProjectDeps')
            buildVersions[projectName] = version

            grunt.verbose.writeln "Dependency versions interpolated during compilation:"
            grunt.verbose.writeln JSON.stringify(buildVersions, null, 4)
        else
            grunt.verbose.writeln "Not interpolating any dependency versions during compilation"


        modesBuilt = []
        promises = []

        # Prepare debug (and base) compilation options
        debugOptions = _.extend {}, options,
            bufferOutput: true
            project: options.project
            mode: 'development'
            restrict: projectName
            destDir: "#{options.destDir}-debug"
            command: 'precompile_assets_only'
            buildVersions: buildVersions
            archiveDir: grunt.config.get 'bender.build.archiveDir'
            tempDir: "#{grunt.config.get 'bender.build.sprocketsCacheDir'}-debug"
            globalAssetsDir: path.join(grunt.config.get('bender.build.tempDir'), 'hs-static-global')
            domain: grunt.config.get 'bender.build.forcedDomain'

            # Don't include runtimeDeps
            production: false
            ignore: [
                "#{projectName}/static/test/*"
            ]


        # The debug compilation process
        debugRunner = new LegacyAssetBenderRunner debugOptions
        stopwatch.start 'precompile_debug_assets'

        debugPromise = debugRunner.run().then (result) ->
            stopwatch.stop 'precompile_debug_assets'

            grunt.log.writeln "\nDebug output\n============\n"
            grunt.log.writeln result.stdoutAndStderr
            grunt.log.writeln "== End debug output"

            modesBuilt.push debugOptions.mode
            grunt.config.set "bender.build.#{debugOptions.mode}.outputDir", debugOptions.destDir
            grunt.config.set "bender.build.#{debugOptions.mode}.buildMD5Hash", getBuildHash(projectName, version, debugOptions.destDir)

        , (result) ->
            grunt.log.writeln "\nFailed debug output (code: #{result.code})\n==================\n"
            grunt.log.writeln result.stdoutAndStderr
            grunt.fail.warn 'Debug compile process failed'

        promises.push debugPromise


        # Prepare compressed options (based off of the debug options)
        compressedOptions = _.extend {}, debugOptions,
            mode: "compressed"
            command: 'precompile'
            buildVersions: buildVersions
            tempDir: grunt.config.get('bender.build.sprocketsCacheDir')
            destDir: options.destDir

        # The compressed compilation process
        compressedRunner = new LegacyAssetBenderRunner compressedOptions
        stopwatch.start 'precompile_compressed_assets'

        compressedPromise = compressedRunner.run().then (result) ->
            stopwatch.stop 'precompile_compressed_assets'

            grunt.log.writeln "\nCompressed output\n=================\n"
            grunt.log.writeln result.stdoutAndStderr
            grunt.log.writeln "== End compressed output"

            modesBuilt.push compressedOptions.mode
            grunt.config.set "bender.build.#{compressedOptions.mode}.outputDir", compressedOptions.destDir
            grunt.config.set "bender.build.#{compressedOptions.mode}.buildMD5Hash", getBuildHash(projectName, version, compressedOptions.destDir)

        , (result) ->
            grunt.log.writeln "\nFailed compressed output (code: #{result.code})\n=======================\n"
            grunt.log.writeln result.stdoutAndStderr
            grunt.fail.warn 'Compressed compile process failed'

        promises.push compressedPromise


        # Build the tests serially after the main debug build finishes
        # (but still in parallel with the debug build), so we can share the
        # compressed build's cache.
        if needsToBuildTests

            testPromise = debugPromise.then ->
                testOptions = _.extend {}, compressedOptions,
                    command: 'precompile_without_bundle_html'
                    destDir: "#{options.destDir}-test"

                    # *Only* bulid things in the test folder
                    ignore: []
                    limitTo: [
                        "#{projectName}/static/test/*"
                    ]

                    # Treat any runtime deps that are needed to build/run
                    # the tests to regular deps.
                    production: false

                testRunner = new LegacyAssetBenderRunner testOptions
                stopwatch.start 'precompile_test_assets'

                testRunner.run().then (result) ->
                    stopwatch.stop 'precompile_test_assets'

                    grunt.log.writeln "\nTest output\n===========\n"
                    grunt.log.writeln result.stdoutAndStderr
                    grunt.log.writeln "== End test output"

                    grunt.config.set "bender.build.test.outputDir", testOptions.destDir

                , (result) ->
                    grunt.log.writeln "\nFailed test build output (code: #{result.code})\n=======================\n"
                    grunt.log.writeln result.stdoutAndStderr
                    grunt.fail.warn 'Test compile process failed'

            promises.push testPromise

        console.log "promises", promises

        Q.all(promises).done ->
            grunt.config.set 'bender.build.modesBuilt', modesBuilt
            grunt.log.writeln "Done with build."
            done()
        , (message) ->
            done new Error(message || "unknown error")
