#!/usr/bin/env node
require('coffee-script/register');
var reporter = require('nodeunit').reporters.default;
reporter.run(['test']);
