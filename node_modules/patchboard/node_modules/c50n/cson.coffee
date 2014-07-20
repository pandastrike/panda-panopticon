CoffeeScript = window?.CoffeeScript 
CoffeeScript ?= require "coffee-script"

{type} = require "fairmont"
 
parse = (source, options={}) ->
  options.sandbox ?= true
  CoffeeScript.eval source, options
  
quote = (string) ->
  "'" + (string.replace /'/g, "\\'") + "'"
  
property = (key,value) ->
  key = if key.match /^[\w_]+$/
    key
  else
    quote key
  
  "#{key}: #{value}"

_stringify = (object, options={}) ->

  {indent} = options
  outer = indent or ""
  inner = outer + "  "
  
  switch type object
    when "object"
      properties = (property key, (_stringify value, indent: inner) for key,value of object).join("\n#{outer}")
      "\n#{outer}#{properties}\n#{outer}"
    when "array"
      elements = ((_stringify element, indent: inner) for element in object).join("\n#{inner}")
      "[\n#{inner}#{elements}\n#{outer}]"
    when "string"
      quote object.toString()
    when "function"
      ;
    else
      object.toString()
    
    
stringify = (object) -> (_stringify object)[1..-1]

module.exports = 
  parse: parse
  stringify: stringify
  