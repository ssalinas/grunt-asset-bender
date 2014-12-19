_ = require 'underscore'
Q = require 'q'
path = require 'path'
fs = require 'fs'

module.exports = (grunt) ->
    utils = require('../lib/utils').init(grunt)

    grunt.registerTask 'bender_create_archive_from_source', 'Tars up the build-name-ified source', ->
        done = @async()

        grunt.config.requires 'bender.build.projectName',
                              'bender.build.copiedProjectDir',
                              'bender.build.versionWithStaticPrefix'

        baseOutputDir      = grunt.config.get 'bender.build.baseOutputDir'
        projectName        = grunt.config.get 'bender.build.projectName'
        projectDir         = grunt.config.get 'bender.build.copiedProjectDir'
        versionWithPrefix  = grunt.config.get 'bender.build.versionWithStaticPrefix'

        srcDirParent       = path.join(projectDir, '..')


        sourceArchiveName = "#{projectName}-#{versionWithPrefix}-src.tar.gz"
        grunt.log.writeln "Creating #{sourceArchiveName}, an archive of the version interpolated source (from #{srcDirParent})"

        utils.executeCommand("tar cvzf #{sourceArchiveName} --exclude=.svn  --exclude=.git #{projectName}/", srcDirParent).fail (err) ->
            grunt.fail.warn "Error building #{sourceArchiveName} archive"
        .done ->
            utils.moveSync path.join(projectDir, '..', sourceArchiveName), path.join(baseOutputDir, sourceArchiveName)
            done()
