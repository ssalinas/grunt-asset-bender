
module.exports = (grunt) ->
    require('./bender_insert_version_into_source_folder')
    require('./bender_build_pointers')
    require('./bender_create_fixed_dependencies_file')
    require('./bender_create_archive_from_build_output')
    require('./bender_interpolate_versions_in_source')
    require('./bender_create_archive_from_source')
    require('./bender_finalize_debug_assets')

    grunt.registerTask 'bender_finalize_build_for_upload',
                       'Takes static3 build output and does all the processing necessary to get it ready to upload to S3 (create pointer files, interpolate versions, make a copy of the fixed dependencies, prepare debug HTML, etc).',
                       [
                           'bender_insert_version_into_source_folder',
                           'bender_build_pointers',
                           'bender_create_fixed_dependencies_file',
                           'bender_copy_necessary_config_into_python_module',
                           'bender_create_archive_from_build_output',
                           'bender_interpolate_versions_in_source',
                           'bender_create_archive_from_source',
                           'bender_finalize_debug_assets'
                       ]
