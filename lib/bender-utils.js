var spawn = require('child_process').spawn;
var path = require('path');
var tilde = require('tilde-expansion');
var temp = require('temp');

function script(options, grunt) {
  var dir = grunt.option('benderPath') || options.benderPath || '';
  var bin = grunt.option('benderScript') || options.benderScript || 'bender';

  return path.join(dir, bin);
}

function mode(options, grunt) {
  return options.compressed  ? "compressed" : "development";
}

function runBenderCommand(cmdArray, grunt) {
  tilde(cmdArray.shift(), function(cmd) {

    var args = cmdArray;
    var done = grunt.task.current.async(); // Tells Grunt that an async task is complete

    grunt.log.writeln('Running: ' + cmd, args.join(' '));
    var child = spawn(cmd, args);

    child.stdout.on('data', function (data) {
      process.stdout.write(data);
    });

    child.stderr.on('data', function (data) {
      process.stderr.write(data);
    });

    child.on('close', function (code) {
      // console.log('child process exited with code ' + code);
      done();
    });
  });

}

function prepareExtraBenderRuntimeConfig(cmdArray, options) {
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

}

exports.script = script;
exports.mode = mode;
exports.runBenderCommand = runBenderCommand;
exports.prepareExtraBenderRuntimeConfig = prepareExtraBenderRuntimeConfig;

