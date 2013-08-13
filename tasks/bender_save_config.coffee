fs = require 'fs'
path = require 'path'

module.exports = (grunt) ->
    grunt.registerTask 'bender_save_config', 'Saves all of the build\'s config to a file so it can be easily picked up from later', ->
        grunt.config.requires 'bender.build',
                              'bender.build.tempDir'

        benderBuildConfig = grunt.config.get 'bender.build'

        options = @options
            savedConfigDir: benderBuildConfig.tempDir

        configPath = path.join options.savedConfigDir, 'saved_bender_build.config'
        grunt.file.write configPath, JSON.stringify(benderBuildConfig, null, 4)
