Q             = require 'Q'
fs            = require 'fs'
path          = require 'path'
glob          = require 'glob'
mkdirp        = require 'mkdirp'
rimraf        = require 'rimraf'
{ Dir_Diff }  = require 'node-dir-diff'
{ exec }      = require 'execSync'
{ inspect }   = require 'util'

module.exports = (grunt) ->
    utils = require('../lib/utils').init(grunt)

    grunt.registerTask 'compare_archives_test', '', ->
        done = @async()

        buildToCompareTo = @options().buildToCompareTo
        outputDir = utils.preferredOutputDir(grunt)
        tempDir = '/tmp/comparing-archives'

        # Find the two just-built archives
        [newSourceArchivePath, newBuildArchivePath] = glob.sync path.join(outputDir, '*.tar.gz')
        [sourceArchiveName, buildArchiveName] = [newSourceArchivePath, newBuildArchivePath].map path.basename

        # Extract them to 2 separate temp folders
        newSourceDir = path.join tempDir, 'new-source'
        newBuildDir = path.join tempDir, 'new-build'

        rimraf.sync newSourceDir
        rimraf.sync newBuildDir

        mkdirp.sync newSourceDir
        mkdirp.sync newBuildDir

        utils.executeCommand "tar -xzf #{newSourceArchivePath}", newSourceDir
        utils.executeCommand "tar -xzf #{newBuildArchivePath}", newBuildDir


        # Download the two existing archives
        # Move them to 2 separate temp folders (with similar names to above) and extract
        existingSourceArchivePath = path.join(tempDir, sourceArchiveName)
        existingBuildArchivePath = path.join(tempDir, buildArchiveName)

        if not fs.existsSync existingSourceArchivePath
            url = "http://hubspot-static2cdn.s3.amazonaws.com/#{sourceArchiveName}"
            utils.executeCommand "curl #{url} > #{existingSourceArchivePath}"

        if not fs.existsSync existingBuildArchivePath
            url = "http://hubspot-static2cdn.s3.amazonaws.com/#{buildArchiveName}"
            utils.executeCommand "curl #{url} > #{existingBuildArchivePath}"

        existingSourceOutputDir = path.join tempDir, 'existing-source'
        existingBuildOutputDir = path.join tempDir, 'existing-build'

        rimraf.sync existingSourceOutputDir
        rimraf.sync existingBuildOutputDir

        mkdirp.sync existingSourceOutputDir
        mkdirp.sync existingBuildOutputDir


        Q.all([
            utils.executeCommand "tar -xzf #{existingSourceArchivePath}", existingSourceOutputDir
            utils.executeCommand "tar -xzf #{existingBuildArchivePath}", existingBuildOutputDir
        ]).finally ->

            Q.all([
                utils.executeCommand("diff -r -w #{existingSourceOutputDir} #{newSourceDir} &> cmpSource.diff")
                utils.executeCommand("diff -r -w #{existingBuildOutputDir} #{newBuildDir} &> cmpBuild.diff")
            ]).finally ->
                grunt.log.writeln "\n\n\n\n\nComparing", existingSourceOutputDir, "and", newSourceDir
                grunt.log.writeln grunt.file.read("cmpSource.diff")


                grunt.log.writeln "\n\n\n\n\nComparing", existingBuildOutputDir, "and", newBuildDir
                grunt.log.writeln grunt.file.read("cmpBuild.diff")
