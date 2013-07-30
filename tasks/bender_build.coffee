_ = require 'underscore'
Q = require 'q'
path = require 'path'

module.exports = (grunt) ->
    LegacyAssetBenderRunner = require('../lib/legacy_asset_bender_runner').init(grunt)

    grunt.registerTask 'bender_build', 'Precompile using HubSpot static v3', ->
        done = @async()

        options = @options
            project: process.cwd()
            destDir: path.join(process.cwd(), "build")

        sourceDir = options.project
        sourceDir = [sourceDir] unless Array.isArray sourceDir

        # Run the build for each directory separately
        promises = for dir in sourceDir
            clonedOptions = _.extend {}, options,
                project: dir
                command: 'precompile_assets_only'

            runner = new LegacyAssetBenderRunner clonedOptions
            runner.run()

        Q.all(promises).then ->
            grunt.log.writeln "Done with build."
            done()
        , (message) ->
            done new Error(message || "unkown error")

    # TODO (after testing)
    # grunt.registerTask 'static3_build', ['bender_build']
