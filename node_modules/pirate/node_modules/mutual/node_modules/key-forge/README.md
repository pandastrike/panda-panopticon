Key Forge
=========

A simple key generation library for use with Node. More or less a convenience wrapper around Node's Crypto and Buffer libraries.

## Install

    npm install key-forge

## Usage

Although Key Forge has a number of functions that you can use to fine-tune your key generation, mostly what you want is this:

    {randomKey} = require "key-forge"
    keySize = 16 # bytes
    key = randomKey keySize # defaults to hex encoding
    key = randomKey keySize, "hex"
    key = randomKey keySize, "base64"
    key = randomKey keySize, "base64url"


## Notes on Encodings

* "hex": direct output from Node.js Buffer.toString("hex")

* "base64": output from Buffer.toString("base64") with the "=" padding stripped.

* "base64url": Based on http://tools.ietf.org/html/rfc4648#section-5, with padding stripped.

