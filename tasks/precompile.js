
module.exports = function(grunt) {
  'use strict';

  var path = require('path');
  var temp = require('temp');
  var benderUtils = require('../lib/bender-utils');

  var _ = grunt.util._;

  grunt.registerMultiTask('bender-precompile', 'Uses asset bender to pre-compile & concatenate static files (SASS, Coffeescript, JS templates, etc)', function() {

    var options = this.options({
      sourceProject: null,
      archiveDir: null,
      targetDir: null,
      compressed: true,
      processes: null
    });

    var cmd = [
      benderUtils.script(options),
      "--mode", benderUtils.mode(options),

      "precompile",

      options.sourceProject || process.cwd(),
      "--output", options.targetDir
    ];

    if (options.processes !== null) {
      cmd.push("--processes", options.processes);
    }

    var extraRuntimeConfig = {};

    if (options.archiveDir !== null) {
      extraRuntimeConfig['archive_dir'] = path.resolve(options.archive_dir);
    }

    if (extraRuntimeConfig.length > 0) {
      var tempFile = temp.openSync({ suffix: '.json' });
      tempFile.fd.writeSync(JSON.stringify(extraRuntimeConfig));
      tempFile.fd.closeSync();

      cmd.push("--runtime-config-file", tempFile.path);
    }

    benderUtils.runBenderCommand(cmd, grunt);

  });

};
