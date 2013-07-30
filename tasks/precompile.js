
module.exports = function(grunt) {
  'use strict';

  var benderUtils = require('../lib/bender-utils');
  var _ = grunt.util._;

  grunt.registerTask('bender-precompile', 'Uses asset bender to pre-compile & concatenate static files (SASS, Coffeescript, JS templates, etc)', function() {

    var options = this.options({
      sourceProject: null,
      archiveDir: null,
      targetDir: null,
      compressed: null,
      processes: null
    });

    // Run time grunt overrides
    options.compressed = this.flags.compressed || options.compressed;
    options.archiveDir = grunt.option('archiveDir') || options.archiveDir;
    options.targetDir = grunt.option('targetDir') || options.targetDir;
    options.processes = grunt.option('processes') || options.processes;

    var cmd = [
      benderUtils.script(options, grunt),
      "--mode", benderUtils.mode(options, grunt),

      "precompile",

      options.sourceProject || process.cwd(),
      "--output", options.targetDir
    ];

    if (options.processes !== null) {
      cmd.push("--processes", options.processes);
    }

    benderUtils.prepareExtraBenderRuntimeConfig(cmd, options);
    benderUtils.runBenderCommand(cmd, grunt);

  });

};
