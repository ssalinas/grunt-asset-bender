fs = require 'fs'
path = require 'path'

module.exports = (grunt) ->
    grunt.registerTask 'bender_load_from_saved_config', 'Picks up a build from where it was saved', ->

        options = @options
            savedConfigDir: path.join(process.cwd(), 'temp-for-static')

        configPath = path.join options.savedConfigDir, 'saved_bender_build.config'

        benderBuildConfig = grunt.file.read configPath, benderBuildConfig
        grunt.config.set 'bender.build', JSON.parse(benderBuildConfig)
