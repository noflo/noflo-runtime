noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai' unless chai
  RemoteSubGraph = require '../src/RemoteSubGraph'
  utils = require './utils'
else
  RemoteSubGraph = require 'noflo-runtime/src/RemoteSubGraph'

# TODO: test the custom ComponentLoader
# TODO: test whole connect/begin/endBracket/disconnect

describe 'Remote runtimes', ->
  c = null
  server = null
  port = 3888

  before (done) ->
    if noflo.isBrowser()
      console.log "WebSocket runtime should have been set up on #{port}"
      done()
    else
      utils.createServer port, (err, s) ->
        server = s
        done()
  after (done) ->
    server.close() if server
    done()

  describe 'RemoteSubGraph component', ->
    def =
      label: "MicroFlo 222"
      description: "The first remote component in the world"
      type: "noflo"
      protocol: "websocket"
      address: "ws://localhost:#{port}"
      secret: "my-super-secret"
      id: "2ef763ff-1f28-49b8-b58f-5c6a5c23af2d"
      user: "3f3a8187-0931-4611-8963-239c0dff1931"
      seenHoursAgo: 11
    meta = {}
    readyEmitted = false

    it 'should be instantiable', ->
      c = (RemoteSubGraph.getComponentForRuntime def)(meta)
      chai.expect(c).to.be.an.instanceof noflo.Component
      c.on 'ready', () ->
        readyEmitted = true
    it 'should set description', ->
      chai.expect(c.description).to.equal def.description
    it 'should populate ports and go ready after connecting to remote', (done) ->
      checkPorts = () ->
        chai.expect(c.inPorts.ports).to.be.an 'object'
        chai.expect(c.inPorts.ports["in"]).to.be.an 'object'
        done()
      if readyEmitted
        checkPorts()
      else
        c.on 'ready', () ->
          checkPorts()
    it 'sending data into local port should be echoed back', (done) ->
      input = noflo.internalSocket.createSocket()
      output = noflo.internalSocket.createSocket()
      c.inPorts['in'].attach input
      c.outPorts.out.attach output  

      output.on 'data', (data) ->
        chai.expect(data).to.deep.equal { test: true }
        done()
      input.send {test: true}
