_ = require 'underscore'
Q = require 'q'
path = require 'path'
fs = require 'fs'

module.exports = (grunt) ->
    utils = require('../lib/utils').init(grunt)

    grunt.registerTask 'bender_finalize_debug_assets', 'Prepares the debug assets to get uploaded alongside the compressed assets and ensures that ?hsDebug=true will use the debug assets', ->
        done = @async()

        grunt.config.requires 'bender.build.projectName',
                              'bender.build.versionWithStaticPrefix'

        projectName        = grunt.config.get 'bender.build.projectName'
        versionWithPrefix  = grunt.config.get 'bender.build.versionWithStaticPrefix'

        outputDir          = grunt.config.get 'bender.build.compressed.outputDir'
        debugOutputDir     = grunt.config.get 'bender.build.development.outputDir'
        builtDebugAssets   = debugOutputDir?


        # Copy over the debug assets (wait till right before the upload to not goof up the hash checking)
        if builtDebugAssets and fs.existsSync path.join(debugOutputDir, projectName, versionWithPrefix)

            grunt.log.writeln "Copying debug assets over to #{outputDir}/#{versionWithPrefix}-debug\n"
            utils.moveSync path.join(debugOutputDir, projectName, versionWithPrefix), path.join(outputDir, projectName, "#{versionWithPrefix}-debug")

            string1 = """(\\/|\\"|\\')static-([0-9]+\\.[0-9]+)(\\/|\\"|\\')"""
            string2 = "\\1static-\\2-debug\\3"

            # Change debug links from /static-x.y/ -> /static-x.y-debug/
            # sedCmd = "find #{outputDir}/#{projectName}/#{versionWithPrefix} -type f -iname '*.bundle-expanded.html' -print0 | xargs -0 sed -i '' -r \"s/#{string1}/#{string2}/g\""

            grunt.log.writeln "Pointing links in *.bundle-expanded.html to the debug folder"
            sedPromise1 = utils.findAndReplace
                sourceDirectory: path.join(outputDir, projectName, versionWithPrefix)
                filesToReplace: "*.bundle-expanded.html"
                useExtendedRegex: true
                commands: "\"s/#{string1}/#{string2}/g\""
            .fail ->
                grunt.log.writeln "Error munging build names from \"/static/\" to \'#{versionWithPrefix}\". Continuing..."

            # Change the debug html assets to point to /static-x.y-debug/ resources
            # sedCmd2 = "find #{outputDir}/#{projectName}/#{versionWithPrefix}-debug -type f -iname '*.html' -print0 | xargs -0 sed -i '' -r \"s/#{string1}/#{string2}/g\""

            grunt.log.writeln "Pointing links in compiled html templates in the debug folder to other debug assets"
            sedPromise2 = utils.findAndReplace
                sourceDirectory: path.join(outputDir, projectName, "#{versionWithPrefix}-debug")
                filesToReplace: "*.html"
                useExtendedRegex: true
                commands: "\"s/#{string1}/#{string2}/g\""
            .fail ->
                grunt.log.writeln "Error munging build names from \"/static/\" to \'#{versionWithPrefix}\" in compiled debug templates. Continuing..."

            Q.all([sedPromise1, sedPromise2]).finally ->
                done()

        # If we didn't build any debug assets (since DONT_COMPRESS_STATIC was set), copy the precompiled output to '/static-x.y-debug/' verbatim
        else if not builtDebugAssets

            grunt.log.writeln "Copying over the precompiled output (that was already non-compressed from compressProductionOutput being false) verbatim to /static-<x.y>-debug/"
            utils.executeCommand("cp -r #{outputDir}/#{projectName}/#{versionWithPrefix} #{outputDir}/#{projectName}/#{versionWithPrefix}-debug").then ->
                grunt.fail.warn "Error copying compiled (non-compressed) output to static-<x.y>-debug/"
            .finally ->
                done()

        else
            grunt.fail.warn "Hit unknown case in bender_finalize_debug_assets (debug output folder invalid?)"
