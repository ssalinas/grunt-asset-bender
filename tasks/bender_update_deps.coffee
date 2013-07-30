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
                              'bender.build.projectName'

        tempDir     = grunt.config.get 'bender.build.tempDir'
        projectName = grunt.config.get 'bender.build.projectName'
        projectDir  = grunt.config.get 'bender.build.copiedProjectDir'
        stopwatch   = utils.graphiteStopwatch(grunt)

        options = @options
            project: projectDir or process.cwd()
            archiveDir: path.join tempDir, 'static-archive'

        useLocalMirrorSetting = utils.envVarEnabled('SE_LOCAL_ARCHIVE_MIRROR', true)

        if not options.mirrorArchiveDir and useLocalMirrorSetting
            mirrorParentDir = grunt.config.get('bender.build.sharedBuildRoot') or '/tmp'
            options.mirrorArchiveDir = path.join mirrorParentDir, 'mirrored_static_downloads'

        if options.mirrorArchiveDir
            grunt.config.set 'bender.build.mirrorArchiveDir', options.mirrorArchiveDir

        dependencyTreeOutputPath = path.join tempDir, 'dependency-tree.json'

        runner = new LegacyAssetBenderRunner _.extend options,
            command: 'update-deps'
            archiveDir: options.archiveDir
            mirrorArchiveDir: options.mirrorArchiveDir
            fixedDepsPath: dependencyTreeOutputPath

        stopwatch.start 'download_static_deps'

        runner.run().done ->
            stopwatch.stop 'download_static_deps'

            grunt.config.set 'bender.build.archiveDir', options.archiveDir

            dependencyTree = JSON.parse fs.readFileSync(dependencyTreeOutputPath, 'utf-8')
            grunt.config.set 'bender.build.fixedProjectDeps', dependencyTree[projectName]

            grunt.log.writeln "Done with downloading deps."
            done()
        , (message) ->
            done new Error(message || "unkown error")
