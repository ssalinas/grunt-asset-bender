_ = require 'underscore'
Q = require 'q'
path = require 'path'
fs = require 'fs'

module.exports = (grunt) ->
    utils = require('../lib/utils').init(grunt)

    grunt.registerTask 'bender_insert_version_into_source_folder', '', ->
        grunt.config.requires 'bender.build.projectName',
                              'bender.build.versionWithStaticPrefix'

        projectName        = grunt.config.get 'bender.build.projectName'
        versionWithPrefix  = grunt.config.get 'bender.build.versionWithStaticPrefix'
        projectDir         = grunt.config.get 'bender.build.copiedProjectDir'

        # Make the source directory have the version in it
        staticDir = path.join(projectDir, 'static')
        staticDirWithVersion = path.join(projectDir, versionWithPrefix)

        utils.moveSync staticDir, staticDirWithVersion
