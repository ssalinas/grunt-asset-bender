"use strict"

grunt = require 'grunt'
LegacyAssetBenderRunner = require('../lib/legacy_asset_bender_runner').init(grunt)

#  ======== A Handy Little Nodeunit Reference ========
#  https://github.com/caolan/nodeunit
#
#  Test methods:
#    test.expect(numAssertions)
#    test.done()
#
#  Test assertions:
#    test.ok(value, [message])
#    test.equal(actual, expected, [message])
#    test.notEqual(actual, expected, [message])
#    test.deepEqual(actual, expected, [message])
#    test.notDeepEqual(actual, expected, [message])
#    test.strictEqual(actual, expected, [message])
#    test.notStrictEqual(actual, expected, [message])
#    test.throws(block, [error], [message])
#    test.doesNotThrow(block, [error], [message])
#    test.ifError(value)


exports.legacy_asset_bender_defaults =
    setUp: (done) ->
        @runner = new LegacyAssetBenderRunner
            command: 'precompile'

        done()

    defaultPath: (test) ->
        test.expect 1
        test.equals @runner.path, "#{process.env['HOME']}/dev/src/hubspot_static_daemon"
        test.done()

    defaultExecutable: (test) ->
        test.expect 1
        test.equals @runner.executable, "#{process.env['HOME']}/dev/src/hubspot_static_daemon/hs-static"
        test.done()

    defaultModeOption: (test) ->
        test.expect 1
        test.deepEqual @runner.modeOption(), ["--mode", "development"]
        test.done()

    defaultProjectOptions: (test) ->
        test.expect 1
        test.ok not @runner.projectOptions()
        test.done()

    defaultBuildVersionOptions: (test) ->
        test.expect 1
        test.ok not @runner.buildVersionOptions()
        test.done()

    defaultDestDirOption: (test) ->
        test.expect 1
        test.ok not @runner.destDirOption()
        test.done()

    defaultRestrictOption: (test) ->
        test.expect 1
        test.ok not @runner.restrictOption()
        test.done()

    defaultTempDirOption: (test) ->
        test.expect 1
        test.ok not @runner.tempDirOption()
        test.done()

    defaultDomainOption: (test) ->
        test.expect 1
        test.ok not @runner.domainOption()
        test.done()


exports.legacy_asset_bender_options =
    command: (test) ->
        runner = new LegacyAssetBenderRunner
            command: 'precompile_asset_only'

        test.expect 1
        test.equals runner.command, "precompile_asset_only"
        test.done()

    singleProject: (test) ->
        runner = new LegacyAssetBenderRunner
            command: 'test'
            project: "/tmp/something/out/there"

        test.expect 1
        test.deepEqual runner.projectOptions(), ["-p", "/tmp/something/out/there"]
        test.done()

    multipleProjects: (test) ->
        runner = new LegacyAssetBenderRunner
            command: 'test'
            project: [ "/tmp/something/out/there", "/Users/rand-al-thor/the/DRAGON"]

        test.expect 1
        test.deepEqual runner.projectOptions(), ["-p", "/tmp/something/out/there", "-p", "/Users/rand-al-thor/the/DRAGON"]
        test.done()

    buildVersions: (test) ->
        runner = new LegacyAssetBenderRunner
            command: 'test'
            buildVersions:
                proj1: 'static-1.1'
                proj2: 'static-3.256'
                another_proj: 'static-11.17'

        test.expect 1
        test.deepEqual runner.buildVersionOptions(), ["-b", "proj1:static-1.1", "-b", "proj2:static-3.256", "-b", "another_proj:static-11.17"]
        test.done()

    destDir: (test) ->
        runner = new LegacyAssetBenderRunner
            command: 'test'
            destDir: 'somevalue'

        test.expect 1
        test.deepEqual runner.destDirOption(), ["--target", "somevalue"]
        test.done()

    restrict: (test) ->
        runner = new LegacyAssetBenderRunner
            command: 'test'
            restrict: 'somevalue'

        test.expect 1
        test.deepEqual runner.restrictOption(), ["--restrict", "somevalue"]
        test.done()

    tempDir: (test) ->
        runner = new LegacyAssetBenderRunner
            command: 'test'
            tempDir: 'somevalue'

        test.expect 1
        test.deepEqual runner.tempDirOption(), ["--temp", "somevalue"]
        test.done()

    domain: (test) ->
        runner = new LegacyAssetBenderRunner
            command: 'test'
            domain: 'somevalue'

        test.expect 1
        test.deepEqual runner.domainOption(), ["--domain", "'somevalue'"]
        test.done()

    fixedDepsPath: (test) ->
        runner = new LegacyAssetBenderRunner
            command: 'test'
            fixedDepsPath: 'somevalue'

        test.expect 1
        test.deepEqual runner.fixedDepsPathOption(), ["--fixed-deps-path", "somevalue"]
        test.done()

    archiveDir: (test) ->
        runner = new LegacyAssetBenderRunner
            command: 'test'
            archiveDir: 'somevalue'

        test.expect 1
        test.deepEqual runner.archiveDirOption(), ["--archive-dir", "somevalue"]
        test.done()


    mirrorArchiveDir: (test) ->
        runner = new LegacyAssetBenderRunner
            command: 'test'
            mirrorArchiveDir: 'somevalue'

        test.expect 1
        test.deepEqual runner.mirrorArchiveDirOption(), ["--mirror-archive-dir", "somevalue"]
        test.done()

    combinedOptions: (test) ->
        runner = new LegacyAssetBenderRunner
            command: 'precompile'
            mode: 'compressed'
            project: [ "/tmp/something/out/there", "/Users/rand-al-thor/the/DRAGON"]
            buildVersions:
                proj1: 'static-1.1'
                proj2: 'static-3.256'
                another_proj: 'static-11.17'
            destDir: "/opt/cool/stuff/here"
            restrict: "there"
            tempDir: "/tmp/TEMP/no_really"
            domain: "//static.hsappstatic.net"

        test.expect 1
        test.deepEqual runner.buildOptionsArray(), [
            "-p", "/tmp/something/out/there", "-p", "/Users/rand-al-thor/the/DRAGON"
            "-b", "proj1:static-1.1", "-b", "proj2:static-3.256", "-b", "another_proj:static-11.17"
            "--domain", "'//static.hsappstatic.net'"
            "--mode", "compressed"
            "--target", "/opt/cool/stuff/here"
            "--restrict", "there"
            "--temp", "/tmp/TEMP/no_really"
        ]
        test.done()

    spareOptions: (test) ->
        runner = new LegacyAssetBenderRunner
            command: 'precompile'
            project: "/Users/rand-al-thor/the/DRAGON"
            destDir: "/opt/cool/stuff/here"
            restrict: "there"
            domain: "//static.hsappstatic.net"

        test.expect 1
        test.deepEqual runner.buildOptionsArray(), [
            "-p", "/Users/rand-al-thor/the/DRAGON"
            "--domain", "'//static.hsappstatic.net'"
            "--mode", "development"
            "--target", "/opt/cool/stuff/here"
            "--restrict", "there"
        ]
        test.done()

    withAnArg: (test) ->
        runner = new LegacyAssetBenderRunner
            command: 'paths'
            args: ['someproj']

        test.expect 1
        test.deepEqual runner.buildOptionsArray(), [
            "someproj"
            "--mode", "development"
        ]
        test.done()

    withAnArg2: (test) ->
        runner = new LegacyAssetBenderRunner
            command: 'paths'
            args: ['someproj']
            project: "/Users/rand-al-thor/the/DRAGON"

        test.expect 1
        test.deepEqual runner.buildOptionsArray(), [
            "someproj"
            "-p", "/Users/rand-al-thor/the/DRAGON"
            "--mode", "development"
        ]
        test.done()

