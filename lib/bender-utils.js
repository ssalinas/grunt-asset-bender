var spawn = require('child_process').spawn;
var tilde = require('tilde-expansion');

function script(options) {
  return (options.benderPath || '') + (options.benderScript || 'bender');
}

function mode(options) {
  return options.compressed  ? "compressed" : "development";
}

function runBenderCommand(cmdArray, grunt) {

  tilde(cmdArray.shift(), function(cmd) {

      var args = cmdArray;
      var done = grunt.task.current.async(); // Tells Grunt that an async task is complete

      grunt.log.writeln('Running: ' + cmd);
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

exports.script = script;
exports.mode = mode;
exports.runBenderCommand = runBenderCommand;

