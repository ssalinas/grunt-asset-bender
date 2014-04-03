_ = require 'underscore'
Q = require 'q'
path = require 'path'
fs = require 'fs'

module.exports = (grunt) ->
    utils = require('../lib/utils').init(grunt)

    grunt.registerTask 'bender_create_archive_from_build_output', 'Tars up the compiled output', ->
        done = @async()

        grunt.config.requires 'bender.build.projectName',
                              'bender.build.versionWithStaticPrefix',
                              'bender.build.fixedProjectDeps'

        outputDir          = utils.preferredOutputDir(grunt)
        projectName        = grunt.config.get 'bender.build.projectName'
        versionWithPrefix  = grunt.config.get 'bender.build.versionWithStaticPrefix'


        builtArchiveName = "#{projectName}-#{versionWithPrefix}.tar.gz"
        grunt.log.writeln "Creating #{builtArchiveName}, an archive of the compiled output."

        utils.executeCommand("tar cvzf #{builtArchiveName} --exclude=.svn  --exclude=.git #{projectName}/", outputDir).fail (err) ->
            grunt.fail.warn "Error building #{builtArchiveName} archive"
        .done ->
            done()
