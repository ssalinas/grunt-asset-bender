_ = require 'underscore'
Q = require 'q'
path = require 'path'
fs = require 'fs'

module.exports = (grunt) ->
    utils = require('../lib/utils').init(grunt)
    LegacyAssetBenderRunner = require('../lib/legacy_asset_bender_runner').init(grunt)

    grunt.registerTask 'bender_run_jasmine_tests', 'Runs the jasmine tests if any exist for this project. Stops any further tasks if the tests fail', ->
        done = @async()

        grunt.config.requires 'bender.build.projectName',
                              'bender.build.copiedProjectDir',
                              'bender.build.archiveDir',
                              'bender.build.versionWithStaticPrefix',
                              'bender.build.test.outputDir'

        projectDir = grunt.config.get 'bender.build.copiedProjectDir'
        outputDir  = grunt.config.get 'bender.build.test.outputDir'
        stopwatch  = utils.graphiteStopwatch(grunt)

        hasSpecs = utils.hasJasmineSpecs()
        jasmineTestsEnabled = utils.jasmineTestsEnabled()

        runTestOn = utils.preferredModeBuilt()

        if hasSpecs and not jasmineTestsEnabled
            grunt.log.writeln "Skipping jasmine tests since RUN_JASMINE_TESTS=#{jasmineTestsEnabled}\n"
            done()

        else if hasSpecs and jasmineTestsEnabled
            grunt.log.writeln "Running jasmine tests\n"

            buildVersions = {}
            buildVersions[grunt.config.get 'bender.build.projectName'] = grunt.config.get 'bender.build.version'

            runner = new LegacyAssetBenderRunner _.extend {},
                assetBenderPath: grunt.config.get 'bender.assetBenderDir'
                project: projectDir
                destDir:  outputDir
                archiveDir: grunt.config.get 'bender.build.archiveDir'
                mode: 'precompiled'
                command: 'jasmine'
                headless: true
                buildVersions: buildVersions

            stopwatch.start 'jasmine_test_duration'

            runner.run().then ->
                grunt.log.writeln 'Jasmine tests succeeded.'
            .fail ->
                stopwatch.stop 'jasmine_test_duration'
                done new Error 'Jasmine tests failed, failing build.'
            .done ->
                done()

        else
            grunt.log.writeln "No jasmine tests to run"
            done()

