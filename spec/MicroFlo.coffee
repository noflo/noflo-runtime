noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai' unless chai
  Runtime = require '../src/runtimes/microflo'
  Base = require '../src/runtimes/base'
  utils = require './utils'
else
    Runtime = require 'noflo-runtime/src/runtimes/microflo'
    Base = require 'noflo-runtime/src/runtimes/base'

describe 'MicroFlo', ->

  before (done) ->
    done()
  after (done) ->
    done()

  describe 'Runtime', ->
    runtime = null
    def =
      label: "MicroFlo Simulator"
      description: "The first remote component in the world"
      type: "microflo"
      protocol: "microflo"
      address: "simulator://"
      secret: "my-super-secret"
      id: "2ef763ff-1f28-49b8-b58f-5c6a5c23af2d"
      user: "3f3a8187-0931-4611-8963-239c0dff1931"
      seenHoursAgo: 11

    it 'should be instantiable', () ->
      runtime = new Runtime def
      chai.expect(runtime).to.be.an.instanceof Base
    it 'should not be connected initially', () ->
      chai.expect(runtime.isConnected()).to.equal false
    it.skip 'should emit "connected" on connect()', (done) ->
      runtime.on 'connected', () ->
        chai.expect(runtime.isConnected()).to.equal true
        done()
      runtime.connect()
    it.skip 'should emit "disconnected" on disconnect()', (done) ->
      runtime.on 'disconnected', () ->
        chai.expect(runtime.isConnected()).to.equal false
        done()
      runtime.disconnect()

    # TODO: test building up simple program, incl start/stop behavior
    # TODO: in browser, test simulator UI able to blink an LED
    # TODO: test exported ports and sending data through


