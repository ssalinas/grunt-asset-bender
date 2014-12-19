_ = require 'underscore'
Q = require 'q'
path = require 'path'

{ fetchLatestVersionOfProject, compareVersions } = require 'hsstatic/tools'

module.exports = (grunt) ->
    utils = require('../lib/utils').init(grunt)
    writeFile = utils.writeFile

    grunt.registerTask 'bender_build_pointers', 'Creates the necessary pointers for a build. (A sub-task of bender_finalize_build_for_upload)', ->
        done = @async()

        aFatalError = (msg = '') ->
            done new Error('Fatal error doing build finalization: #{msg}')

        grunt.config.requires 'bender.build.projectName',
                              'bender.build.copiedProjectDir',
                              'bender.build.version',
                              'bender.build.versionWithStaticPrefix',
                              'bender.build.majorVersion'
                              'bender.build.isCurrentVersion'

        outputDir          = utils.preferredOutputDir(grunt)
        secondaryOutputDir = utils.secondaryOutputDir(grunt)

        projectName        = grunt.config.get 'bender.build.projectName'
        projectDir         = grunt.config.get 'bender.build.copiedProjectDir'
        version            = grunt.config.get 'bender.build.version'
        versionWithPrefix  = grunt.config.get 'bender.build.versionWithStaticPrefix'
        majorVersion       = grunt.config.get 'bender.build.majorVersion'
        isCurrentVersion   = grunt.config.get 'bender.build.isCurrentVersion'
        scmRev             = grunt.config.get 'bender.build.scmRev'

        writePointerToAll = (content, pointerName) ->
            writeFile content, path.join(projectDir, pointerName)
            writeFile content, path.join(outputDir, projectName, pointerName)
            writeFile content, path.join(secondaryOutputDir, projectName, pointerName) if secondaryOutputDir?

        nowStr = new String(new Date())
        infoStr = "#{projectName}-#{version} rev: #{scmRev} #{nowStr}"

        # Log the build info for this specific build
        utils.writeFile infoStr, "#{outputDir}/#{projectName}/#{versionWithPrefix}/info.txt"
        utils.writeFile infoStr, "#{secondaryOutputDir}/#{projectName}/#{versionWithPrefix}/info.txt" if secondaryOutputDir?

        # Grab the most edge version build (of any majorVersion)
        currentEdgeVersion = null

        fetchLatestVersionOfProject(projectName, 'edge').fail ->
            ; # Leave currentEdgeVersion null to indicate the version doesn't exist
        .then (result) ->
            currentEdgeVersion = result
        .always ->

            # If this is the first time this project has been built or if this is the most edge version, create the edge pointers
            needToCreateEdgePointer = not currentEdgeVersion? or compareVersions(version, currentEdgeVersion) == 1

            grunt.log.writeln "This #{version} > #{currentEdgeVersion} => #{needToCreateEdgePointer}"

            if needToCreateEdgePointer
                # Note, there should be no difference between "-qa" and non "-qa" edge pointers
                writePointerToAll versionWithPrefix, "latest-qa"     # Deprecated
                writePointerToAll versionWithPrefix, "latest"        # Deprecated
                writePointerToAll versionWithPrefix, "edge-qa"
                writePointerToAll versionWithPrefix, "edge"

            writePointerToAll versionWithPrefix, "latest-version-#{majorVersion}-qa"

            if isCurrentVersion
                grunt.log.writeln "Writing the 'current-qa' pointer since this _is_ the \"current\" build."
                writePointerToAll versionWithPrefix, "current-qa"
            else
                grunt.log.writeln "Skipping the 'current-qa' pointer since this is not a \"current\" build."

            promises = []

            # If this is the first time this major version has been built, create the prod pointer(s) as well
            promises.push fetchLatestVersionOfProject(projectName, majorVersion, { forceProduction: true, cdn: false, env: 'prod' }).fail ->
                grunt.log.writeln "This is the first time building major version #{majorVersion}, creating the prod latest-version-#{majorVersion} pointer"
                writePointerToAll versionWithPrefix, "latest-version-#{majorVersion}"

            # If this is major version one and there is no existing "prod" current pointer, create it
            if majorVersion == 1
                promises.push fetchLatestVersionOfProject(projectName, 'current', { forceProduction: true, cdn: false, env: 'prod' }).fail ->
                    grunt.log.writeln "Also building the product current pointer for the first time"
                    writePointerToAll versionWithPrefix, "current"

            # Wait until two previous fetches are finished to end task
            Q.allSettled(promises).done ->
                done()

        .done()
