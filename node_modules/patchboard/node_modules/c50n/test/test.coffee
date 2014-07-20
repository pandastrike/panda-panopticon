cson = require "../cson"
{read} = require "fairmont"
{resolve} = require "path"

console.log (cson.stringify (cson.parse (read resolve __dirname, "./test.cson")))