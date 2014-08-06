_ = require 'underscore'
Q = require 'q'
path = require 'path'
fs = require 'fs'
mkdirp = require 'mkdirp'

module.exports = (grunt) ->
    utils = require('../lib/utils').init(grunt)
    LegacyAssetBenderRunner = require('../lib/legacy_asset_bender_runner').init(grunt)

    grunt.registerTask 'bender_download_built_deps', 'Download the built output of dependencies via HubSpot static v3', ->
        done = @async()

        grunt.config.requires 'bender.build.tempDir',
                              'bender.build.projectName',
                              'bender.assetBenderDir'

        tempDir     = grunt.config.get 'bender.build.tempDir'
        projectName = grunt.config.get 'bender.build.projectName'
        projectDir  = grunt.config.get 'bender.build.copiedProjectDir'
        stopwatch   = utils.graphiteStopwatch(grunt)

        options = @options
            project: projectDir or process.cwd()
            archiveDir: path.join tempDir, 'static-archive'
            builtArchiveDir: path.join tempDir, 'built-archive'
            assetBenderPath: grunt.config.get 'bender.assetBenderDir'

            # Ensure the same dep versions from update-deps are downloaded
            usePrebuilt: true

        mkdirp.sync options.builtArchiveDir

        runner = new LegacyAssetBenderRunner _.extend options,
            command: 'download-built-deps'
            destDir: options.builtArchiveDir
            mirrorArchiveDir: options.mirrorArchiveDir or grunt.config.get('bender.build.mirrorArchiveDir')
            nocolor: grunt.config.get 'bender.build.hideColor'

        stopwatch.start 'download_prebuilt_static_deps'

        runner.run().done ->
            stopwatch.stop 'download_prebuilt_static_deps'

            grunt.config.set 'bender.build.builtArchiveDir', options.builtArchiveDir

            done()
        , (message) ->
            done new Error(message || "unkown error")
