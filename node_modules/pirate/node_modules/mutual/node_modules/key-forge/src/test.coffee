Keys = require "./index"
Testify = require("testify")
assert = require "assert"

Testify.test "Key generation", (context) ->

  context.test "randomKey returns a string", ->
    assert.ok (Keys.randomKey 16).charAt

  context.test "bytesToNumber is the inverse of numberToBytes", ->
    x = Date.now()
    assert.ok (Keys.bytesToNumber Keys.numberToBytes x), x
    x = 17
    assert.equal (Keys.bytesToNumber Keys.numberToBytes x), x

  context.test "numberToKey returns a string", ->
    assert.ok (Keys.numberToKey Date.now()).charAt
  
  z = Keys.buffersToKey Keys.randomBytes(16), Keys.numberToBytes Date.now()

  context.test "we can combine byte arrays to create composite keys", ->
    assert.ok z.charAt

  context.test "Encoding for hex works as expected", ->
    assert.equal z, (new Buffer z, 'hex').toString('hex')