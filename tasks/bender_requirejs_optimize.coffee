
module.exports = (grunt) ->
    # require('./bender_download_built_deps')
    grunt.loadNpmTasks('grunt-contrib-requirejs')

    grunt.registerTask 'bender_requirejs_optimize',
                       'Prepares a project, runs the requirejs optimizer, and then moves the optimized files back over to be uploaded',
                       [
                           # Since requirejs can't deal with coffeescript (without
                           # some shennanigans, it needs the built output of every
                           # dependency when optimizating.
                           'bender_download_built_deps',

                           # Prepares some default requirejs config for ya (dependency
                           # directories and such)
                           'bender_prepare_requirejs_optimize',

                           # Actually run the optimizer
                           'requirejs'

                           # Move the optimized files back into the output dir to upload
                           'bender_post_requirejs_optimize',
                       ]
