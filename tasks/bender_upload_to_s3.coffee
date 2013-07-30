_ = require 'underscore'
Q = require 'q'
path = require 'path'
fs = require 'fs'

module.exports = (grunt) ->
    utils = require('../lib/utils').init(grunt)

    grunt.registerTask 'bender_upload_to_s3', 'Upload the final built output to S3 in parallel', ->
        done = @async()

        grunt.config.requires 'bender.assetBenderDir',
                              'bender.build.projectName'

        assetBenderPath  = grunt.config.get 'bender.assetBenderDir'
        projectName      = grunt.config.get 'bender.build.projectName'
        stopwatch        = utils.graphiteStopwatch(grunt)
        outputDir        = utils.preferredOutputDir(grunt)

        # upload the assets to S3 (too lazy to port at this point)
        grunt.log.writeln "Uploading assets to s3...\n"

        pythonBin = process.env.PYTHON_BIN
        pythonBin = 'python26' unless pythonBin

        uploadScript = path.join assetBenderPath, 'script', 'upload_project_assets_to_s3_parallel.py'
        cmd = "#{pythonBin} #{uploadScript} -p \"#{projectName}\" "

        stopwatch.start 'uploading_to_s3'

        utils.executeCommand(cmd, outputDir).fail ->
            grunt.fail.warn "Error uploading static files to S3!"
        .finally ->
            stopwatch.stop 'total_build_duration'
            done()
