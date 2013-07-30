
module.exports = function(grunt) {
  'use strict';

  var benderUtils = require('../lib/bender-utils');
  var _ = grunt.util._;

  grunt.registerTask('bender-download-deps', 'Downloads all the asset bender deps for the current project', function() {

    var options = this.options({
      sourceProject: null,
      archiveDir: null
    });

    // Run time grunt overrides
    options.archiveDir = grunt.option('archiveDir') || options.archiveDir;

    var cmd = [
      benderUtils.script(options, grunt),

      "update-deps",

      options.sourceProject || process.cwd()
    ];

    benderUtils.prepareExtraBenderRuntimeConfig(cmd, options);
    benderUtils.runBenderCommand(cmd, grunt);
  });

};
