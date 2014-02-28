path = require 'path'
fs = require 'fs'
{ exec } = require 'execSync'

module.exports = (grunt) ->
    utils = require('../lib/utils').init(grunt)

    envVarsExpectedByBuild =
        jobName:         'JOB_NAME'
        jenkinsRoot:     'JENKINS_ROOT'
        workspace:       'WORKSPACE'
        projectPath:     'PROJECT_PATH'
        hsStaticRepoDir: 'HS_STATIC_REPO_DIR'
        cacheDir:        'CACHE_DIR'
        jenkinsTools:    'JENKINS_TOOLS'
        buildNumber:     'BUILD_NUMBER'
        gitCommit:       'GIT_COMMIT'

        pythonBin:               'PYTHON_BIN'
        staticDeployPython:      'STATIC_DEPLOY_PYTHON'
        staticDeployWorkonHome:  'STATIC_DEPLOY_WORKON_HOME'

        benderS3AccessKeyId:     'BENDER_S3_ACCESS_KEY_ID'
        benderS3SecretAccessKey: 'BENDER_S3_SECRET_ACCESS_KEY'

        persistStaticCache:      'PERSIST_HS_STATIC_CACHE'


        # forcedMajorVersion: 'FORCED_MAJOR_VERSION',
        # currentStaticVersion: 'CURRENT_STATIC_VERSION',

        # graphiteNamespace: 'GRAPHITE_NAMESPACE',
        # graphiteServer: 'GRAPHITE_SERVER',
        # graphitePort: 'GRAPHITE_PORT'

    loadUpEnv = (options) ->
        for own key, envVarName of envVarsExpectedByBuild
            process.env[envVarName] = options[key] if options[key]?

    tryToLoadS3Keys = (options) ->
        s3CredsPath = utils.expandHomeDirectory('~/.hubspot/bender_s3_creds')

        if fs.existsSync s3CredsPath
            varsFromFile = {}
            contents = grunt.file.read s3CredsPath

            envVariableRegex = /\s*export\s+(\w+)=(['"])(.*)\2\s*/g

            while match = envVariableRegex.exec(contents)
                varsFromFile[match[1]] = match[3]

            grunt.log.writeln "Loading ", Object.keys(varsFromFile), "into grunt options"

            if varsFromFile.BENDER_S3_ACCESS_KEY_ID
                options.benderS3AccessKeyId = varsFromFile.BENDER_S3_ACCESS_KEY_ID

            if varsFromFile.BENDER_S3_SECRET_ACCESS_KEY
                options.benderS3SecretAccessKey = varsFromFile.BENDER_S3_SECRET_ACCESS_KEY
        else
            grunt.log.error "~/.hubspot/bender_s3_creds doesn't exist. You'll need it do be able to upload to s3 locally\n"

    grunt.registerTask 'bender_fake_jenkins_env_for_testing', '', ->
        job = path.basename(process.cwd())

        options = @options
            jobName:            job
            jenkinsRoot:        '/tmp/jenkins-root'
            workspace:          process.cwd()
            projectPath:        process.cwd()
            hsStaticRepoDir:    utils.expandHomeDirectory('~/dev/src/hubspot_static_daemon')
            cacheDir:           "/tmp/cache-dir/#{job}"
            jenkinsTools:       utils.expandHomeDirectory('~/dev/src/JenkinsTools')
            buildNumber:        '1'
            ignoreBuildNumber:  true

            persistStaticCache: false

            pythonBin:               '/usr/bin/python'
            staticDeployPython:      '/usr/bin/python'
            staticDeployWorkonHome:  '/tmp/fake-deploy-workon-home'

            # forcedMajorVersion
            # currentStaticVersion

            # graphiteServer
            # graphitePort
            # graphiteNamespace

        tryToLoadS3Keys(options)

        options.gitCommit = exec('git rev-list master --max-count 1').stdout?.replace(/\n$/, '') unless options.gitCommit

        grunt.log.writeln "Faked jenkins environment:"
        grunt.log.writeln JSON.stringify(options, null, 2)

        grunt.config.set 'bender.build.customLocalConfig', options

        loadUpEnv(options)

        # Ensure that hsstatic requests don't go to the local server
        process.env['HSSTATIC_ENV'] = 'qa'







