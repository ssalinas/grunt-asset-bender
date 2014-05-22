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

        if fixedProjectDeps and version
            buildVersions = _.extend {}, grunt.config.get('bender.build.fixedProjectDeps')
            buildVersions[projectName] = version

            grunt.verbose.writeln "Dependency versions interpolated during compilation:"
            grunt.verbose.writeln JSON.stringify(buildVersions, null, 4)
        else
            grunt.verbose.writeln "Not interpolating any dependency versions during compilation"


        modesBuilt = []
        promises = []
        debugBuildPromise = null
        compressedBuildPromise = null

        # The debug compilation process
        debugOptions = _.extend {}, options,
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

            # By default, stream out the debug build and buffer the compressed build
            # output for later
            bufferOutput: false

        # If this is a project using devDeps/runtimeDeps, don't include them in the debug build
        if utils.hasDevOrRuntimeDeps()
            _.extend debugOptions,
                production: true
                ignore: [
                    "#{projectName}/static/test/*"
                ]

        grunt.log.writeln ""

        if options.skipDebugBuild is true
            grunt.log.writeln "Skipping compressed build due to skipDebugBuild"
            debugBuildPromise = Q()
        else
            do (debugOptions) ->
                debugRunner = new LegacyAssetBenderRunner debugOptions
                stopwatch.start 'precompile_debug_assets'

                promises.push debugBuildPromise = debugRunner.run().then (result) ->
                    stopwatch.stop 'precompile_debug_assets'

                    if debugOptions.bufferOutput is true
                        grunt.log.writeln "\nDebug output\n============"
                        grunt.log.writeln result.stdoutAndStderr
                        grunt.log.writeln "== End debug output"

                    modesBuilt.push debugOptions.mode
                    grunt.config.set "bender.build.#{debugOptions.mode}.outputDir", debugOptions.destDir
                    grunt.config.set "bender.build.#{debugOptions.mode}.buildMD5Hash", getBuildHash(projectName, version, debugOptions.destDir)

                , (result) ->
                    if debugOptions.bufferOutput is true
                        grunt.log.writeln "\nFailed debug output (code: #{result.code})\n=================="
                        grunt.log.writeln result.stdoutAndStderr

                    grunt.fail.warn 'Debug compile process failed'


        # The compressed compilation process
        compressedOptions = _.extend {}, debugOptions,
            project: grunt.config.get('bender.build.copiedProjectDirForCompressedBuild') or process.cwd()
            mode: "compressed"
            command: 'precompile'
            buildVersions: buildVersions
            tempDir: grunt.config.get('bender.build.sprocketsCacheDir')
            destDir: options.destDir

            # Only stream out the compressed output if there isn't a debug build
            bufferOutput: not options.skipDebugBuild

        grunt.log.writeln ""

        if options.skipCompressedBuild is true
            grunt.log.writeln "\nSkipping compressed build due to skipCompressedBuild"
            compressedBuildPromise = Q()
        else
            do (compressedOptions) ->
                compressedRunner = new LegacyAssetBenderRunner compressedOptions
                stopwatch.start 'precompile_compressed_assets'

                promises.push compressedBuildPromise = compressedRunner.run().then (result) ->
                    stopwatchOut = stopwatch.stopButDontPrint 'precompile_compressed_assets'

                    # Wait to print anything until debug is done
                    debugBuildPromise.finally ->
                        if compressedOptions.bufferOutput is true
                            grunt.log.writeln "\nCompressed output\n================="
                            grunt.log.writeln result.stdoutAndStderr
                            grunt.log.writeln "== End compressed output"

                        grunt.log.writeln stopwatchOut

                        modesBuilt.push compressedOptions.mode
                        grunt.config.set "bender.build.#{compressedOptions.mode}.outputDir", compressedOptions.destDir
                        grunt.config.set "bender.build.#{compressedOptions.mode}.buildMD5Hash", getBuildHash(projectName, version, compressedOptions.destDir)

                , (result) ->
                    # Wait to print anything until debug is done
                    debugBuildPromise.finally ->
                        if compressedOptions.bufferOutput is true
                            grunt.log.writeln "\nFailed compressed output (code: #{result.code})\n======================="
                            grunt.log.writeln result.stdoutAndStderr

                        grunt.fail.warn 'Compressed compile process failed'


        # Since tests need the runtime & dev deps included, we will do a separate
        # test compile pass when a project has any runtime or dev dependencies
        #
        # This test compile pass is run serially after the main compressed build
        # finishes (but still in parallel with the debug build), so we can share
        # the compressed build's cache.
        if utils.needsToBuildTestsSeparately()

            testPromise = compressedBuildPromise.then ->
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


        if debugOptions.bufferOutput is false and not options.skipDebugBuild
            grunt.log.writeln "\nStreaming debug output\n======================"
        else if compressedOptions.bufferOutput is false and not options.skipCompressedBuild
            grunt.log.writeln "\nStreaming compressed output\n==========================="

        Q.all(promises).done ->
            grunt.config.set 'bender.build.modesBuilt', modesBuilt

            # Make sure that test dir is set even if there wasn't a separate test
            # compile pass
            if not grunt.config.get("bender.build.test.outputDir")?
                grunt.config.set "bender.build.test.outputDir", utils.preferredOutputDir(grunt)

            grunt.log.writeln "Done with build."
            done()
        , (message) ->
            done new Error(message || "unknown error")
