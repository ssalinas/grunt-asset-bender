
module.exports = (grunt) ->
    grunt.registerTask 'run_default_jenkins_build_locally',
                       'All of the default tasks to mimic a static jenkins build locally',
                       [
                         'bender_fake_jenkins_env_for_testing'

                         'bender_collect_jenkins_env'
                         'bender_abort_if_version_already_exists'

                         'bender_update_deps'
                         'bender_create_fixed_dependencies_file'
                         'bender_build_parallel'

                         'bender_run_jasmine_tests'

                         'bender_finalize_build_for_upload'
                       ]
