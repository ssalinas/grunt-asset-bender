# Uploaded to http://hubspot.com.s3.amazonaws.com/tools/front-end/run_default_jenkins_build.sh manually.
# (hubspot.com s3 bucket)


# If there is a package.json, do npm install, otherwise just install the latest version
# of grunt-asset-bender (unless we are locally developing the module)
if [ -f package.json ]; then
  npm install
else
  if [ -L 'node_modules/grunt-asset-bender' ]; then
    echo "Not installing grunt-asset-bender, you have a local dev link in place"
  else
    npm install grunt-asset-bender@~0.3.3
  fi
fi

# If there is a Gruntfile, use it. Otherwise make a temporary one
gruntfile=`ls | grep -i "gruntfile\." | head -n 1`

if [ "$gruntfile" ]; then
  echo "Using your local $gruntfile to build..."
  grunt run_jenkins_build_locally --verbose
else
  tempGruntfile="Gruntfile-temp-local.js"
  echo "module.exports = function (grunt) { grunt.loadNpmTasks('grunt-asset-bender'); }" > $tempGruntfile

  echo "Created a temporary gruntfile $tempGruntfile to build..."
  grunt run_default_jenkins_build_locally --verbose --gruntfile $tempGruntfile

  rm $tempGruntfile
fi

