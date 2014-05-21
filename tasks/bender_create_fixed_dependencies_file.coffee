_ = require 'underscore'
Q = require 'q'
path = require 'path'
fs = require 'fs'

module.exports = (grunt) ->
    { writeFile } = require('../lib/utils').init(grunt)

    writeConfFileWithBuild = (projectDir, otherProjectDir) ->

        # Clone of config
        output = _.extend {}, grunt.config.get('bender.build.projectConfig')
        output['build'] = grunt.config.get 'bender.build.version'
        output = JSON.stringify(output, null, 4)

        # Need to write to both source folders
        outputPath1 = path.join(projectDir, 'static', 'static_conf.json')
        outputPath2 = path.join(otherProjectDir, 'static', 'static_conf.json')

        grunt.verbose.writeln "Writing #{outputPath1} and #{outputPath2}:\n#{output}\n"
        grunt.file.write outputPath1, output
        grunt.file.write outputPath2, output

    writeFixedDepsFile = (projectDir, otherProjectDir) ->
        output = _.extend {}, grunt.config.get('bender.build.projectConfig'),
            name:  grunt.config.get 'bender.build.projectName'
            build: grunt.config.get 'bender.build.version'
            deps:  grunt.config.get 'bender.build.fixedProjectDeps'

        output = JSON.stringify(output, null, 4)

        # Need to write to both source folders
        outputPath1 = path.join(projectDir, 'static', 'prebuilt_recursive_static_conf.json')
        outputPath2 = path.join(otherProjectDir, 'static', 'prebuilt_recursive_static_conf.json')

        grunt.verbose.writeln "Writing #{outputPath1} and #{outputPath2}:\n#{output}\n"
        grunt.file.write outputPath1, output
        grunt.file.write outputPath2, output


    grunt.registerTask 'bender_create_fixed_dependencies_file', '', ->
        grunt.config.requires 'bender.build.projectName',
                              'bender.build.copiedProjectDir',
                              'bender.build.versionWithStaticPrefix',
                              'bender.build.projectConfig',
                              'bender.build.version',
                              'bender.build.fixedProjectDeps'

        projectName       = grunt.config.get 'bender.build.projectName'
        projectDir        = grunt.config.get 'bender.build.copiedProjectDir'
        otherProjectDir   = grunt.config.get 'bender.build.copiedProjectDirForCompressedBuild'
        versionWithPrefix = grunt.config.get 'bender.build.versionWithStaticPrefix'

        grunt.log.writeln 'Writing static_conf.json and prebuilt_recursive_static_conf.json to the source directory'

        # Build a fixed-in-time static_conf.json (and prebuilt_recursive_static_conf.json)
        # for the source folder, # debug output, and compressed output. The precompile
        # tasks will copy to the output folders for us.
        writeConfFileWithBuild(projectDir, otherProjectDir)
        writeFixedDepsFile(projectDir, otherProjectDir)
