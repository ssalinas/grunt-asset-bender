_ = require 'underscore'
Q = require 'q'
path = require 'path'
fs = require 'fs'

module.exports = (grunt) ->

    grunt.registerTask 'bender_fake_deps_for_external_project', '', ->
        grunt.config.set 'bender.build.fixedProjectDeps', {}

    grunt.registerTask 'bender_create_fixed_dependencies_file_for_external_project', '', [
        'bender_fake_deps_for_external_project',
        'bender_create_fixed_dependencies_file'
    ]
