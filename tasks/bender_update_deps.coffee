_ = require 'underscore'
Q = require 'q'
path = require 'path'
fs = require 'fs'

module.exports = (grunt) ->
    utils = require('../lib/utils').init(grunt)
    LegacyAssetBenderRunner = require('../lib/legacy_asset_bender_runner').init(grunt)

    grunt.registerTask 'bender_update_deps', 'Download and create list of dependencies via HubSpot static v3', ->
        done = @async()

        grunt.config.requires 'bender.build.tempDir',
                              'bender.build.projectName',
                              'bender.assetBenderDir'

        tempDir     = grunt.config.get 'bender.build.tempDir'
        projectName = grunt.config.get 'bender.build.projectName'
        projectDir  = grunt.config.get 'bender.build.copiedProjectDir'
        stopwatch   = utils.graphiteStopwatch(grunt)

        options = @options
            project: projectDir ? process.cwd()
            extraProjects: @options()?.extraProjects
            archiveDir: path.join tempDir, 'static-archive'
            assetBenderPath: grunt.config.get 'bender.assetBenderDir'

        dependencyTreeOutputPath = path.join tempDir, 'dependency-tree.json'

        runner = new LegacyAssetBenderRunner _.extend options,
            command: 'update-deps'
            archiveDir: options.archiveDir
            mirrorArchiveDir: options.mirrorArchiveDir or grunt.config.get('bender.build.mirrorArchiveDir')
            fixedDepsPath: dependencyTreeOutputPath
            nocolor: grunt.config.get 'bender.build.hideColor'

            # Treat any runtime deps as regular deps, so that they are downloaded
            # and ready when test code is built and run (it is very likely that
            # runtime deps are needed for the tests)
            production: false

        stopwatch.start 'download_static_deps'

        runner.run().done ->
            stopwatch.stop 'download_static_deps'

            grunt.config.set 'bender.build.archiveDir', options.archiveDir

            dependencyTree = JSON.parse grunt.file.read(dependencyTreeOutputPath)
            grunt.config.set 'bender.build.fixedProjectDeps', dependencyTree[projectName]

            grunt.log.writeln "Done with downloading deps."
            done()
        , (message) ->
            done new Error(message || "Unknown error")
