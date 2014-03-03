_ = require 'underscore'
Q = require 'q'
path = require 'path'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'
wrench = require 'wrench'
fs = require 'fs'

module.exports = (grunt) ->
    utils = require('../lib/utils').init(grunt)

    setRequiredBuildConfig = (key, value) ->
        grunt.warn "Can't continue build, #{key} isn't set" unless value?
        grunt.config.set(key, value) unless grunt.config.get(key)

    grunt.registerTask 'bender_collect_jenkins_env', 'Extracts current jenkins build enviornment and makes it available to other grunt tasks', ->
        done = @async()

        # Basic build info/directories
        setRequiredBuildConfig 'bender.build.jobName', process.env.JOB_NAME
        setRequiredBuildConfig 'bender.build.jobNumber', process.env.BUILD_NUMBER
        setRequiredBuildConfig 'bender.build.workspace', process.env.WORKSPACE
        setRequiredBuildConfig 'bender.build.originalProjectDir', process.env.PROJECT_PATH or process.env.WORKSPACE
        setRequiredBuildConfig 'bender.build.root', process.env.JENKINS_ROOT
        setRequiredBuildConfig 'bender.build.cacheDir', process.env.CACHE_DIR
        setRequiredBuildConfig 'bender.build.scmRev', process.env.GIT_COMMIT or process.env.SVN_REVISION
        setRequiredBuildConfig 'bender.build.forcedDomain', process.env.FORCED_STATIC_DOMAIN or "static.hsappstatic.net"
        setRequiredBuildConfig 'bender.assetCDNRegex', /\/\/static2cdn.hubspot.(com|net)\//
        setRequiredBuildConfig 'bender.assetBenderDir', process.env.HS_STATIC_REPO_DIR

        origProjectDir = grunt.config.get 'bender.build.originalProjectDir'


        # Backward compatibility stuff to remove..
        process.env.COMPILE_JADE = '1' unless process.env.COMPILE_JADE?  # (Can be removed after build.hubteam.com is decommisioned)


        # Tempory directories
        setRequiredBuildConfig 'bender.build.tempDir', path.join(process.env.CACHE_DIR or process.env.WORKSPACE, 'temp-for-static')

        tempDir = grunt.config.get 'bender.build.tempDir'
        rimraf.sync tempDir
        mkdirp.sync tempDir
        grunt.config.set 'bender.build.baseOutputDir', path.join(tempDir, 'compiled-output')


        # Custom tmp directory for hs-static
        persistedCacheDir = "#{grunt.config.get 'bender.build.cacheDir'}/hs-static-tmp-persisted"
        shouldPersistCache = utils.envVarEnabled('PERSIST_HS_STATIC_CACHE', true)

        if shouldPersistCache
            # If configured, keep the static cache between builds
            sprocketsCacheDir = persistedCacheDir
            grunt.log.writeln "Using the saved static cache for this build"
        else
            # Otherwise, start with a fresh cache and blow away the persisted one
            sprocketsCacheDir = path.join grunt.config.get('bender.build.tempDir'), 'hs-static-tmp'
            grunt.log.writeln "Using a fresh hs-static cache for this build."

            if fs.existsSync persistedCacheDir
                grunt.log.writeln "Blowing away the persisted cache since this build isn't using it (rm -rf #{persistedCacheDir})"
                rimraf persistedCacheDir, ->

        setRequiredBuildConfig 'bender.build.sprocketsCacheDir', sprocketsCacheDir


        # Helper tools/repos
        setRequiredBuildConfig 'bender.build.jenkinsToolsDir', process.env.JENKINS_TOOLS


        # Static project info
        projectConfig = utils.loadBenderProjectConfig origProjectDir
        setRequiredBuildConfig 'bender.build.projectConfig', projectConfig
        setRequiredBuildConfig 'bender.build.projectName', projectConfig.name


        # Move the source that will be messed with to a temp location (so we don't goof up the repo when modifying it)
        sourceDir = path.join tempDir, 'src'
        grunt.config.set 'bender.build.sourceDir', sourceDir

        copiedProjectDir = path.join sourceDir, projectConfig.name
        grunt.config.set 'bender.build.copiedProjectDir', copiedProjectDir

        mkdirp.sync copiedProjectDir
        wrench.copyDirSyncRecursive path.join(origProjectDir, 'static'), path.join(copiedProjectDir, 'static'),
            excludeHiddenUnix: true     # .DS_Store files gunk up the sed replacements that happen later


        # Mirror archive directory
        if utils.envVarEnabled('USE_LOCAL_ARCHIVE_MIRROR', true)
            # Just use temp for now since the cacheDir isn't yet saved between builds
            mirrorParentDir = '/tmp'
            # mirrorParentDir = grunt.config.get('bender.build.cacheDir') or '/tmp'

            grunt.config.set 'bender.build.mirrorArchiveDir', path.join(mirrorParentDir, 'mirrored_static_downloads')
            mkdirp.sync grunt.config.get 'bender.build.mirrorArchiveDir'


        # Version
        forcedMajorVersion = parseInt(process.env.FORCED_MAJOR_VERSION, 10) if process.env.FORCED_MAJOR_VERSION?
        majorVersion = forcedMajorVersion or projectConfig.majorVersion or 1
        minorVersion = grunt.config.get('bender.build.jobNumber')
        isCurrentVersion = projectConfig.isCurrentVersion

        # Legacy "is current" check
        if process.env.CURRENT_STATIC_VERSION?
            isCurrentVersion = majorVersion == parseInt(process.env.CURRENT_STATIC_VERSION, 10)

        # By default, assume isCurrentVersion anything majorVersion == 1
        else if majorVersion == 1 and not isCurrentVersion?
            isCurrentVersion = true

        # Otherwise, set isCurrentVersion for any other major version (unless it is explicitly set)
        else if not isCurrentVersion?
            isCurrentVersion = false

        setRequiredBuildConfig 'bender.build.isCurrentVersion', isCurrentVersion
        setRequiredBuildConfig 'bender.build.majorVersion', majorVersion
        setRequiredBuildConfig 'bender.build.minorVersion', minorVersion
        setRequiredBuildConfig 'bender.build.version', "#{majorVersion}.#{minorVersion}"
        setRequiredBuildConfig 'bender.build.versionWithStaticPrefix', "static-#{majorVersion}.#{minorVersion}"

        # Graphite client for other tasks to use
        grunt.config.set 'bender.graphite.server', process.env.GRAPHITE_SERVER
        grunt.config.set 'bender.graphite.port', process.env.GRAPHITE_PORT
        grunt.config.set 'bender.graphite.namespace', process.env.GRAPHITE_NAMESPACE

        grunt.log.writeln "process.env.GRAPHITE_SERVER", process.env.GRAPHITE_SERVER
        grunt.log.writeln "process.env.GRAPHITE_PORT", process.env.GRAPHITE_PORT
        grunt.log.writeln "process.env.GRAPHITE_NAMESPACE", process.env.GRAPHITE_NAMESPACE


        # Output all build config when --verbose
        grunt.verbose.writeln "Current build config:"
        formattedConfig = JSON.stringify grunt.config.get('bender'), null, 2
        formattedConfig = formattedConfig.replace '\n', '\n  '
        grunt.verbose.writeln formattedConfig


        utils.graphiteStopwatch(grunt).start('total_build_duration')

        # Store whether the command line tools are GNU-style for future tasks
        utils.isGNU().done (isGNU) ->
            grunt.config.set 'bender.build.isGNU', isGNU

            # Always log the name and version to build
            grunt.log.writeln "Attempting to build #{projectConfig.name} #{grunt.config.get('version') || ''}...\n"
            done()
