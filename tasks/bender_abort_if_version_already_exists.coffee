{ versionAlreadyExistsOnServer } = require 'hsstatic/tools'

module.exports = (grunt) ->
    grunt.registerTask 'bender_abort_if_version_already_exists', 'Stops any further tasks if the version to be built already exists', ->
        done = @async()

        ignoreBuildNumber = grunt.config.get 'bender.build.customLocalConfig.ignoreBuildNumber'

        if ignoreBuildNumber
            grunt.log.writeln "Looks like a local build (since ignoreBuildNumber is set), skipping this task."
            done()
        else
            grunt.config.requires 'bender.build.projectName',
                                  'bender.build.version'

            projectName = grunt.config.get 'bender.build.projectName'
            version = grunt.config.get 'bender.build.version'

            versionAlreadyExistsOnServer(projectName, version).then ->
                grunt.warn "Can't build version #{version} of #{projectName}. It already has been built and uploaded to s3!"
            .fail ->
                grunt.verbose.writeln "Version #{version} (or anything greater) doesn't exist. Continuing to build #{projectName}"
                done()

