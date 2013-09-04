_ = require 'underscore'
Q = require 'q'
path = require 'path'
fs = require 'fs'

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

        useLocalMirrorSetting = utils.envVarEnabled('USE_LOCAL_ARCHIVE_MIRROR', true)

        if not options.mirrorArchiveDir and useLocalMirrorSetting
            mirrorParentDir = grunt.config.get('bender.build.sharedBuildRoot') or '/tmp'
            options.mirrorArchiveDir = path.join mirrorParentDir, 'mirrored_static_downloads'

        if options.mirrorArchiveDir
            grunt.config.set 'bender.build.mirrorArchiveDir', options.mirrorArchiveDir

        runner = new LegacyAssetBenderRunner _.extend options,
            command: 'download-built-deps'
            destDir: options.builtArchiveDir
            mirrorArchiveDir: options.mirrorArchiveDir

        stopwatch.start 'download_prebuilt_static_deps'

        runner.run().done ->
            stopwatch.stop 'download_prebuilt_static_deps'

            grunt.config.set 'bender.build.builtArchiveDir', options.builtArchiveDir

            done()
        , (message) ->
            done new Error(message || "unkown error")
