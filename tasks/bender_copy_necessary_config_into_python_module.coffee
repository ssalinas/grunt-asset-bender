_ = require 'underscore'
Q = require 'q'
path = require 'path'
fs = require 'fs'
mkdirp = require 'mkdirp'
glob = require 'glob'

module.exports = (grunt) ->
    utils = require('../lib/utils').init(grunt)

    grunt.registerTask 'bender_copy_necessary_config_into_python_module', 'Tars up the compiled output', ->

        grunt.config.requires 'bender.build.projectName',
                              'bender.build.copiedProjectDir',
                              'bender.build.archiveDir',
                              'bender.build.version',
                              'bender.build.versionWithStaticPrefix',
                              'bender.build.majorVersion'
                              'bender.build.isCurrentVersion'

        projectName        = grunt.config.get 'bender.build.projectName'
        projectDir         = grunt.config.get 'bender.build.copiedProjectDir'
        versionWithPrefix  = grunt.config.get 'bender.build.versionWithStaticPrefix'

        fromDir            = path.join projectDir, 'static'
        pythonModuleDir    = path.join projectDir, projectName

        if not fs.existsSync path.join(pythonModuleDir, '__init__.py')
            grunt.log.writeln "Warning, no such #{pythonModuleDir} module folder, looking for the first subdirectory with an __init__.py"

            # Search for all directories that contain an __init__.py
            allPythonDirs = glob.sync(path.join(projectDir, '*')).filter (potentialModuleDir) ->
                fs.existsSync path.join(potentialModuleDir, '__init__.py')

            grunt.verbose.writeln "All python module dirs: #{allPythonDirs.join(', ')}" if allPythonDirs
            grunt.verbose.writeln "No python module dirs exist" if not allPythonDirs

            pythonModuleDir = allPythonDirs[0]

        if pythonModuleDir
            grunt.log.writeln "Copying static_conf.json and prebuilt_recursive_static_conf.json from #{from_dir} to #{pythonModuleDir}/static/ (so it will work via egg/venv install)"

            mkdirp.sync path.join pythonModuleDir, 'static'
            utils.copyFileSync path.join(from_dir, 'static_conf.json'),  path.join(pythonModuleDir, 'static', 'static_conf.json')
            utils.copyFileSync path.join(from_dir, 'prebuilt_recursive_static_conf.json'),  path.join(pythonModuleDir, 'static', 'prebuilt_recursive_static_conf.json')
            utils.copyFileSync path.join(from_dir, 'info.txt'),  path.join(pythonModuleDir, 'static', 'info.txt')
        else
            grunt.log.writeln "Assuming this is not a python/django project, no module folder could be found."
