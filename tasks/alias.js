
module.exports = function(grunt) {
  'use strict';

  grunt.registerTask('bender-build-munge-and-upload', 'Performs all the needed deps downloading, precompilation, version interpolcation, and s3 uploading to completely build an asset bender project.', function() {

    if (!grunt.option('bender.version')) {
        throw new Error("This build's version number hasn't been passed in, exiting");
    }

    grunt.task.run('bender-download-deps');

    // Do something different in non-compressed only
    grunt.task.run('bender-precompile:debug');
    grunt.task.run('bender-precompile:compressed');

    // All of the following tasks should require that bender-precompile was run

    // grunt.task.run('bender-check-for-identical-build');

    // // Check if has jasmine tests
    // grunt.task.run('bender-jasmine-tests');

    // grunt.task.run('bender-create-built-archive');

    // grunt.task.run('bender-new-pointers');
    // grunt.task.run('bender-create-fixed-deps-file');
    // grunt.task.run('bender-move-static-config-into-python');

    // grunt.task.run('bender-intepolate-versions');
    // grunt.task.run('bender-create-intepolated-source-archive');

    // grunt.task.run('bender-reconfigure-debug-asset-paths');
    // grunt.task.run('bender-upload-to-s3-in-parallel');

    // grunt.task.run('bender-invalidate-staging-scaffolds');
  });

};
