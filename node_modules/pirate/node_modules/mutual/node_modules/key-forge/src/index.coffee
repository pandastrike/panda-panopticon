Crypto = require "crypto"
Buffer = (require "buffer").Buffer

Keys =
  
  randomKey: (size, format="hex") ->
    Keys.bufferToKey( Keys.randomBytes( size ), format)
    
  randomBytes: (size) ->
    Crypto.randomBytes size
  
  numberToKey: (number) ->
    Keys.bufferToKey Keys.numberToBytes number

  # We don't use, say, writeDoubleBE because I'm leery about hard-coding the
  # size of a double, given that buffers deal in raw memory. 
  #
  # I was also getting trailing 0s but that might have been because I was
  # using BE instead of LE ... ? 
  #
  # Also, we don't use bitwise operators here because JavaScript
  # auto-converts values to 32-bits when you do that.
  numberToBytes: (number,size=8) ->
    bytes = []
    x = number
    while x >= 256
      bytes.push (x % 256)
      x = Math.floor(x/256)
    bytes.push x
    # Add some padding to ensure uniform keys, which helps guarantee
    # uniqueness.
    while bytes.length < size
      bytes.push 0
    new Buffer bytes.reverse()
    
  # This function is primarily here to make it easy to test the numberToBytes
  # function. The Buffer object works just like an array so you can pass in
  # either a Buffer instance or an array here.
  bytesToNumber: (bytes) ->
    x = 0
    for byte in bytes
      x *= 256
      x += byte
    x
        
  bufferToKey: (buffer, format="hex") ->
    switch format
      when "hex"
        buffer.toString("hex")
      when "base64"
        # Omitting padding characters, per:
        # http://tools.ietf.org/html/rfc4648#section-3.2
        buffer.toString("base64").replace(/\=+$/, '')
      when "base64url"
        Keys.sanitize(buffer.toString("base64"))
      else
        throw new Error "Unknown format: '#{format}'"

  
  sanitize: (string) ->
    # Based on RFC 4648's "base64url" mapping:
    # http://tools.ietf.org/html/rfc4648#section-5
    string.replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/\=+$/, '')


  buffersToKey: (buffers...) -> Keys.bufferToKey Buffer.concat buffers


module.exports = Keys
