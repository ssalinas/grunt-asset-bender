_ = require 'underscore'
Q = require 'q'
path = require 'path'
fs = require 'fs'

module.exports = (grunt) ->
    utils = require('../lib/utils').init(grunt)

    grunt.registerTask 'bender_upload_to_s3', 'Upload the final built output to S3 in parallel', ->
        done = @async()

        ignoreBuildNumber = grunt.config.get 'bender.build.customLocalConfig.ignoreBuildNumber'
        skipUpload        = grunt.config.get 'bender.build.skipUpload'

        if skipUpload
            grunt.log.writeln "SKIP_STATIC_UPLOAD or bender.build.skipUpload set, not uploading anything to S3"
            done()
        else if ignoreBuildNumber
            grunt.fail.warn "This is a locally run build, are you sure that you want to upload build results to s3?\nIf you really want to (let's say, a jenkins emergency), you must manually set ignoreBuildNumber to false and specify a buildNumber inside the 'bender_fake_jenkins_env_for_testing' options in your gruntfile.\n"
            done()
        else
            grunt.config.requires 'bender.build.projectName'

            projectName      = grunt.config.get 'bender.build.projectName'
            stopwatch        = utils.graphiteStopwatch(grunt)
            outputDir        = utils.preferredOutputDir(grunt)

            # upload the assets to S3 (too lazy to port at this point)
            grunt.log.writeln "Uploading assets to s3...\n"

            pythonBin = process.env.PYTHON_BIN
            pythonBin = 'python2.6' unless pythonBin

            uploadScript = path.join __dirname, '..', 'lib', 'upload_project_assets_to_s3_parallel.py'
            cmd = "#{pythonBin} #{uploadScript} -p \"#{projectName}\" "

            stopwatch.start 'uploading_to_s3'

            utils.executeCommand(cmd, outputDir).fail ->
                grunt.fail.warn "Error uploading static files to S3!"
            .finally ->
                stopwatch.stop 'uploading_to_s3'
                stopwatch.stop 'total_build_duration'

                done()
