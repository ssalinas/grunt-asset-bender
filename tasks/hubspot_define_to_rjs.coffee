module.exports = (grunt) ->
    grunt.registerMultiTask 'hubspot_define_to_rjs', 'Convert hubspot.define calls to requirejs compatible define calls', ->
        fs = require('fs')
        falafel = require('falafel')
        path = require('path')

        REMOVE_STRING = "removeme"

        options = @options
            verifyPath: true
            basePath: process.cwd()

        for fileInfo in @files
            srcFilePath = fileInfo.src[0]
            srcFile = fs.readFileSync(srcFilePath, 'utf8')

            getModulePathParts = (name) ->
                name = name.replace /\/\//g, '/'
                name = name.replace /\./g, '/'

                parts = name.split('/')

                for part, i in parts
                    if part is ''
                        parts[i] = '..'

                if parts[0] in ['hubspot', 'hs']
                    parts.splice(0, 1) # splice out hubspot and the project name

                parts = (p.toLowerCase() for p in parts)

            processModulePath = (name) ->
                parts = getModulePathParts name
                return "'" + parts.join("/") + "'"
            
            grunt.log.writeln "\nProcessing #{srcFilePath}..."
            isHubSpotDefine = (node) ->
                node.type is "CallExpression" and node.callee?.object?.name is "hubspot" and node.callee.property.name is "define"                

            output = falafel srcFile, (node) ->
                # rewrite dependencies

                if node.type is "Literal" and isHubSpotDefine(node.parent) and node.parent.arguments[0].value is node.value    
                    grunt.verbose.writeln "Found module #{node.value} at #{srcFilePath}"

                    if options.verifyPath and node.value isnt null and /^(hubspot|hs)/.test(node.value) # if we're verifying this path
                        modulePath = getModulePathParts(node.value)[1..].join("/")
                        expectedSrcFile = path.join(options.basePath, modulePath+"") + ".js"
                        grunt.verbose.writeln "Expecting file to be at #{expectedSrcFile}"
                        if expectedSrcFile != srcFilePath
                            grunt.log.error "Expected file to be #{expectedSrcFile} but file is in #{srcFilePath}"

                    node.update REMOVE_STRING

                if node.type is "ArrayExpression" and node.parent.type is "CallExpression" and node.parent.callee?.object?.name is "hubspot" and node.parent.callee.property.name is "define"
                    deps = for item in node.elements
                        if item.type is "Literal"
                            processModulePath item.value

                    newDeps = "[#{deps.join(",")}]"
                    grunt.verbose.writeln "Transforming deps to #{newDeps}"
                    node.update newDeps

                if isHubSpotDefine(node)
                    replacer = new RegExp("^hubspot.define\\(#{REMOVE_STRING},\\s*")
                    node.update node.source()?.replace(replacer, "define(")

            destFilename = path.normalize(path.join(process.cwd(), fileInfo.dest))
            grunt.file.write fileInfo.dest, output