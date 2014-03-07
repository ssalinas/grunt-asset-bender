_ = require 'underscore'
Q = require 'q'
path = require 'path'
fs = require 'fs'

module.exports = (grunt) ->
    utils = require('../lib/utils').init(grunt)

    grunt.registerTask 'bender_interpolate_versions_in_source', '', ->
        done = @async()

        grunt.config.requires 'bender.build.projectName',
                              'bender.build.copiedProjectDir',
                              'bender.build.versionWithStaticPrefix',
                              'bender.build.fixedProjectDeps'

        projectName        = grunt.config.get 'bender.build.projectName'
        projectDir         = grunt.config.get 'bender.build.copiedProjectDir'
        versionWithPrefix  = grunt.config.get 'bender.build.versionWithStaticPrefix'
        fixedProjectDeps   = grunt.config.get 'bender.build.fixedProjectDeps'

        projectVersionsToInterpolate = _.extend {}, fixedProjectDeps
        projectVersionsToInterpolate[projectName] = versionWithPrefix

        grunt.log.writeln 'Interpolating versions in the source folder'
        grunt.verbose.writeln "Dep versions to interpolate: \n", projectVersionsToInterpolate

        sedTasks = []
        sedPromises = []

        console.log "source to sed: #{projectDir}/#{versionWithPrefix}"
        console.assert fs.existsSync "#{projectDir}/#{versionWithPrefix}"

        # Munge build names throughout the entire source project (for all recursive deps)
        for own depName, depVersion of projectVersionsToInterpolate
            do (depName, depVersion) ->
                sedTasks.push ->

                    string1 = "#{depName}\\/static\\/"
                    string2 = "#{depName}\\/#{depVersion}\\/"

                    # sedCmd = "find #{projectDir}/#{versionWithPrefix} -type f -print0 | xargs -0 sed -i '' 's/#{string1}/#{string2}/g'"

                    utils.findAndReplace
                        sourceDirectory: path.join projectDir, versionWithPrefix
                        commands: "'s/\\<#{string1}/#{string2}/g'"
                    .fail (err) ->
                        grunt.fail.warn "Error munging build names for #{depName} to #{depVersion}: #{err}"

        # Run the sed tasks sequentially
        if sedTasks
            firstTask = sedTasks.shift()
            result = Q(firstTask)

            sedTasks.forEach (task) ->
                result = result.then(task);
                sedPromises.push result

        Q.all(sedPromises).finally ->
            done()
