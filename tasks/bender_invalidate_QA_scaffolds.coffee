_ = require 'underscore'
Q = require 'q'
path = require 'path'
fs = require 'fs'

module.exports = (grunt) ->
    utils = require('../lib/utils').init(grunt)

    grunt.registerTask 'bender_invalidate_QA_scaffolds', 'Invalidates all the static scaffolds on QA so this new build version shows up immediately', ->
        done = @async()

        grunt.config.requires 'bender.build.projectName',
                              'bender.build.jenkinsToolsDir'

        jenkinsToolsDir  = grunt.config.get 'bender.build.jenkinsToolsDir'
        projectName      = grunt.config.get 'bender.build.projectName'
        stopwatch        = utils.graphiteStopwatch(grunt)

        if utils.envVarEnabled('SKIP_STATIC_QA_DEPLOY', false)
            grunt.log.writeln "Skipping QA static deploy"
        else
            grunt.log.writeln "Invalidating QA scaffolds (so that QA gets the latest code immediately)..."

            pythonDeployStaticPath = process.env.PYTHON_DEPLOY_STATIC_PATH
            pythonDeployStaticPath = "#{jenkinsToolsDir}/python/scripts/python_deploy_static.py" unless pythonDeployStaticPath

            grunt.fail.warn "PYTHON_DEPLOY_STATIC_PATH isn't set, can't invalidate QA scaffolds" unless pythonDeployStaticPath?

            cmd = "bash #{pythonDeployStaticPath} #{projectName}"
            stopwatch.start 'invalidate_static_scaffolds'

            utils.executeCommand(cmd).fail ->
                grunt.log.writeln "Couldn't invalidate static scaffolds on QA, updates won't show up immediately."
            .finally ->
                stopwatch.stop 'invalidate_static_scaffolds'
                done()
