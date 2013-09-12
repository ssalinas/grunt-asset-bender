path = require 'path'
fs = require 'fs'
_ = require 'underscore'
{ exec } = require 'execSync'

module.exports = (grunt) ->
    utils = require('../lib/utils').init(grunt)

    loadRequirejsConfigUsedDuringBuild = (projectName, debugOutputDir, versionWithPrefix) ->
        rjsConfigFromBuildPath = path.join debugOutputDir, projectName, versionWithPrefix,'/html/built-requirejs-config.json'
        json = grunt.file.read rjsConfigFromBuildPath

        JSON.parse json

    grunt.registerTask 'bender_prepare_requirejs_optimize', '', ->
        done = @async()

        grunt.config.requires 'bender.build.builtArchiveDir',
                              'bender.build.projectConfig',
                              'bender.build.projectName',
                              'bender.build.versionWithStaticPrefix'

        # options = @options
        projectConfig       = grunt.config.get 'bender.build.projectConfig'
        projectName         = grunt.config.get 'bender.build.projectName'
        requirejsConfig     = grunt.config.get 'requirejs.compile.options'
        versionWithPrefix   = grunt.config.get 'bender.build.versionWithStaticPrefix'
        builtArchiveDir     = grunt.config.get('bender.build.builtArchiveDir')
        debugOutputDir      = grunt.config.get 'bender.build.development.outputDir'
        outputDir           = utils.preferredOutputDir(grunt)
        stopwatch           = utils.graphiteStopwatch(grunt)

        configThatShouldntBeAlreadySet = [
            'baseUrl',
            'dir',
            'optimize',
            'optimizeCss',
        ]

        for key in configThatShouldntBeAlreadySet
            if requirejsConfig[key]?
                grunt.fail.warn "You have already setup the #{key} requirejs option. The bender_prepare_requirejs_optimize task will overwrite this, so you should remove it from your config."

        requirejsConfig.optimizeCss = requirejsConfig.optimize = 'none'
        requirejsConfig.optimizeCss = requirejsConfig.optimize = 'none'

        requirejsConfig.baseUrl = builtArchiveDir
        requirejsConfig.dir = path.join outputDir, '..', 'compiled-output-requirejs'

        requirejsConfig.paths ||= {}
        requirejsConfig.map   ||= {}
        requirejsConfig.shim  ||= {}

        requirejsConfig.paths[projectName] = path.join outputDir, projectName

        # Load config from project's built-requirejs-config.js file (created during the build step)
        buildConfig = loadRequirejsConfigUsedDuringBuild(projectName, debugOutputDir, versionWithPrefix)

        _.extend requirejsConfig.paths, buildConfig.paths
        _.extend requirejsConfig.map, buildConfig.map
        _.extend requirejsConfig.shim, buildConfig.shim

        # The optimizer can't work with network paths, so only use the last fallback path
        # (we are assuming that the last fallback is always local)
        for module, path of requirejsConfig.paths
            if _.isArray path
                requirejsConfig.paths[module] = path = path[path.length - 1].replace('//static2cdn.hubspot.(com|net)/', '')

        # Change hubspot.define -> define() and hubspot.require -> require() (also the first string arg in hubspot.define)

        grunt.log.writeln "Rewrite hubspot.define() and hubspot.require() to define()/require() so the optimizer traverses dependencies correctly (on #{utils.numCPUs()} cores)"

        # sedCmd = "find #{builtArchiveDir} -type f -iname '*.js' -print0 | xargs -P #{numCPUs} -0 sed -i '' -e 's/hubspot.require/require/g' -e 's/hubspot.define([^,[]*,/hubspot.define(/g' -e 's/hubspot.define/define/g'"
        utils.findAndReplace
            sourceDirectory: builtArchiveDir
            filesToReplace: '*.js'
            parallel: true
            commands: [
                "'s/hubspot.require/require/g'"
                "'s/hubspot.define([^,[]*,/hubspot.define(/g'"
                "'s/hubspot.define/define/g'"
            ]
        .done ->
            grunt.config.set 'requirejs.compile.options', requirejsConfig

            grunt.log.writeln "Requirejs optimizer config: "
            grunt.log.writeln JSON.stringify(requirejsConfig, null, 4)

            stopwatch.start('requirejs_optimizer')

            done()
