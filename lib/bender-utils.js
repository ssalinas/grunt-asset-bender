var exec = require('child_process').exec;

function runBenderCommand(cmdArray, grunt) {
  var cmd = cmdArray.join(' ');
  var done = grunt.task.current.async(); // Tells Grunt that an async task is complete
  var child;

  grunt.log.writeln('Running: ' + cmd);

  child = exec(cmd, {
    // cwd: '/Users/timmfin/Dropbox/Development/asset-bender'
  }, function(error, stdout, stderr) {
    grunt.log.writeln('stdout: ' + stdout);
    grunt.log.writeln('stderr: ' + stderr);
    done(error); // Technique recommended on #grunt IRC channel. Tell Grunt asych function is finished. Pass error for logging; if operation completes successfully error will be null
  });
}

exports.runBenderCommand = runBenderCommand;

