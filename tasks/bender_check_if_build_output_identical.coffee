_ = require 'underscore'

module.exports = (grunt) ->



    grunt.registerTask 'bender_check_if_build_output_identical', 'Stops any further tasks this build\'s compiled assets are identical to the previous build', ->
        done = @async()

        anIgnorableError = (msg = '') ->
            grunt.log.write 'Error doing build identity check, assuing the build is different and continuing'
            grunt.log.write ': #{msg}' if msg
            grunt.log.writeln ''
            done()

        aFatalError = (msg = '') ->
            done new Error('Fatal error doing build identity check: #{msg}')


        grunt.config.requires 'bender.build.projectName',
                              'bender.build.majorVersion',

        projectName  = grunt.config.get 'bender.build.projectName'
        majorVersion = grunt.config.get 'bender.build.majorVersion'

        hasIsFrom = utils.preferredModeBuilt()
        currentMD5Hash = grunt.config.get 'bender.build.#{hashIsFrom}.buildMD5Hash'

        grunt.config.requires 'bender.build.#{hashIsFrom}.outputDir'
        outputDir = grunt.config.get 'bender.build.#{hashIsFrom}.outputDir'

        if not currentMD5Hash
            grunt.vebose.log "Skipping identity check, no build hash"
        else
            tools.fetchLatestVersionOfProject(projectName, majorVersion).fail(anIgnorableError).then (latestVersion) ->
                tools.getAsString("#{projectName}/#{latestVersion}/premunged-static-contents-hash.md5", { cdn: false }).fail(anIgnorableError).then (resp) ->
                    formerMD5Hash = resp.data.trim()

                    grunt.verbose.log "currentMD5Hash: #{currentMD5Hash}"
                    grunt.verbose.log "formerMD5Hash:  #{formerMD5Hash}\n"

                    hashIsTheSame = currentMD5Hash? and formerMD5Hash? and currentMD5Hash == formerMD5Hash

                    currentStaticDeps = TODO_FETCH_CURRENT_STATIC_DEPS

                    tools.getAsString("#{projectName}/#{latestVersion}/prebuilt_recursive_static_conf.json", { cdn: false }).fail(anIgnorableError).then (resp) ->
                        formerStaticDeps = JSON.parse(resp.data)

                        grunt.verbose.log "currentStaticDeps:  #{currentStaticDeps.inspect}"
                        grunt.verbose.log "formerStaticDeps:  #{formerStaticDeps.inspect}", "\n"

                        depsAreTheSame = currentStaticDeps? and formerStaticDeps? and _.isEqual(currentStaticDeps, formerStaticDeps)

                        if hashIsTheSame and depsAreTheSame and process.env.FORCE_S3_UPLOAD
                            grunt.log.writeln "Compiled files and depencencies are identical to previous build. However FORCE_S3_UPLOAD is set, so continue on and build anyway."

                        else if hashIsTheSame and depsAreTheSame
                            grunt.log.writeln "Compiled files and depencencies are identical to previous build. Copying down the previous build config and skipping further tasks."

                            # TODO IMPLEMENT !!!
                            download_previous_build_conf projectName, majorVersion, "#{source_dir}/static/"
                            copyOverConfToPython_module projectName, static_workspace_dir, "#{source_dir}/static/"

                            grunt.util.exit(0)

                        done()
