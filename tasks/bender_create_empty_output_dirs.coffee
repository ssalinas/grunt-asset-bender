_ = require 'underscore'
Q = require 'q'
path = require 'path'
fs = require 'fs'

module.exports = (grunt) ->

    grunt.registerTask 'bender_create_empty_output_dirs', '', ->

        # Necessary settings (that normally come from running bender_build_parallel)
        compressedDestDir = grunt.config.get('bender.build.baseOutputDir')
        devDestDir = "#{devDestDir}-debug"

        grunt.config.set "bender.build.development.outputDir", devDestDir
        grunt.config.set "bender.build.compressed.outputDir", compressedDestDir

        grunt.config.set 'bender.build.modesBuilt', ['development', 'compressed']
