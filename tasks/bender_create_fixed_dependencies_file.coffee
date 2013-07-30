_ = require 'underscore'
Q = require 'q'
path = require 'path'
fs = require 'fs'

module.exports = (grunt) ->
    { writeFile } = require('../lib/utils').init(grunt)

    writeConfFileWithBuild = (outputPath) ->

        # Clone of config
        output = _.extend {}, grunt.config.get('bender.build.projectConfig')
        output['build'] = grunt.config.get 'bender.build.version'
        output = JSON.stringify(output, null, 4)

        grunt.verbose.writeln "Writing #{outputPath}:\n#{output}\n"
        fs.writeFileSync outputPath, output

    writeFixedDepsFile = (outputPath) ->
        output =
            name:  grunt.config.get 'bender.build.projectName'
            build: grunt.config.get 'bender.build.version'
            deps:  grunt.config.get 'bender.build.fixedProjectDeps'

        output = JSON.stringify(output, null, 4)

        grunt.verbose.writeln "Writing #{outputPath}:\n#{output}\n"
        fs.writeFileSync outputPath, output


    grunt.registerTask 'bender_create_fixed_dependencies_file', '', ->
        grunt.config.requires 'bender.build.projectName',
                              'bender.build.copiedProjectDir',
                              'bender.build.versionWithStaticPrefix',
                              'bender.build.modesBuilt',
                              'bender.build.projectConfig',
                              'bender.build.version',
                              'bender.build.fixedProjectDeps'

        projectName       = grunt.config.get 'bender.build.projectName'
        projectDir        = grunt.config.get 'bender.build.copiedProjectDir'
        versionWithPrefix = grunt.config.get 'bender.build.versionWithStaticPrefix'
        modesBuilt        = grunt.config.get 'bender.build.modesBuilt'

        outputDirs = (grunt.config.get "bender.build.#{mode}.outputDir" for mode in modesBuilt)

        grunt.log.writeln 'Writing static_conf.json and prebuilt_recursive_static_conf.json to output directories'

        # Build a fixed-in-time static_conf.json (and prebuilt_recursive_static_conf.json) for the source folder, debug output, and compressed output
        writeConfFileWithBuild path.join(projectDir, versionWithPrefix, 'static_conf.json')
        writeFixedDepsFile path.join(projectDir, versionWithPrefix, 'prebuilt_recursive_static_conf.json')

        for outputDir in outputDirs
            writeConfFileWithBuild path.join(outputDir, projectName, versionWithPrefix, 'static_conf.json')
            writeFixedDepsFile path.join(outputDir, projectName, versionWithPrefix, 'prebuilt_recursive_static_conf.json')
