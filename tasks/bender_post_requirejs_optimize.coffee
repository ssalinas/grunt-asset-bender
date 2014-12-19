path = require 'path'
fs = require 'fs'
{ exec } = require 'execSync'

module.exports = (grunt) ->
    utils = require('../lib/utils').init(grunt)

    grunt.registerTask 'bender_post_requirejs_optimize', 'Take the files optimized by requirejs and copy them back into the output folder', ->

        grunt.config.requires 'requirejs.compile.options'

        requirejsConfig     = grunt.config.get 'requirejs.compile.options'
        outputDir           = utils.preferredOutputDir(grunt)
        stopwatch           = utils.MetricStopwatch(grunt)

        stopwatch.stop('requirejs_optimizer')

        for module in requirejsConfig.modules
          modulePath = path.join requirejsConfig.dir, "#{module.name}.js"
          destPath   = path.join outputDir, "#{module.name}.js"

          utils.copyFileSync modulePath, destPath

