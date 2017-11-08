noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai' unless chai
  rt = require '../index'
  utils = require './utils/utils'
else
  rt = require 'noflo-runtime'

RemoteSubGraph = rt.RemoteSubGraph
connection = rt.connection

# TODO: test whole connect/begin/endBracket/disconnect

describe 'Remote runtimes', ->
  describe 'PseudoRuntime over WebSocket in NoFlo', ->
    c = null
    server = null
    port = 3888
    def =
      label: "NoFlo 222"
      description: "The first remote component in the world"
      type: "noflo"
      protocol: "websocket"
      address: "ws://localhost:#{port}"
      secret: "my-super-secret"
      id: "2ef763ff-1f28-49b8-b58f-5c6a5c23af2d"
      user: "3f3a8187-0931-4611-8963-239c0dff1931"
      seenHoursAgo: 11

    before (done) ->
      if noflo.isBrowser()
        port = 3889
        def.address = "ws://#{window.location.hostname}:#{port}"
        console.log "WebSocket runtime should have been set up on #{def.address}"
        done()
      else
        utils.createServer port, (err, s) ->
          return done err if err
          console.log "WebSocket runtime running in port #{port}"
          server = s
          done()
    after (done) ->
      server.close() if server
      done()

    meta = {}
    readyEmitted = false

    it 'should be instantiable', (done) ->
      @timeout 5000
      c = (RemoteSubGraph.getComponentForRuntime def)(meta)
      chai.expect(c).to.be.an.instanceof noflo.Component
      c.on 'ready', () ->
        readyEmitted = true
        done()
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
      chai.expect(c.inPorts.in).to.be.an 'object'
      c.inPorts['in'].attach input
      chai.expect(c.outPorts.out).to.be.an 'object'
      c.outPorts.out.attach output

      output.on 'data', (data) ->
        chai.expect(data).to.deep.equal { test: true }
        done()
      input.send {test: true}


  describe.skip 'MicroFlo simulator direct in NoFlo', ->
    c = null
    c = null
    def =
      label: "MircroFlo sim"
      description: ""
      type: "microflo"
      protocol: "microflo"
      address: "simulator://"
      secret: "my-super-secret2s"
      id: "2ef763ff-1f28-49b8-b58f-5c6a5c23af23"
      user: "3f3a8187-0931-4611-8963-239c0dff1934"
      seenHoursAgo: 11
    # FIXME: output should be from last node, not edge in middle
    forward = """
    INPORT=fOne.IN:INPUT
    OUTPORT=fTwo.OUT:OUTPUT
    fOne(Forward) OUT -> IN fTwo(Forward) OUT -> IN fThree(Forward)
    """
    meta = {}
    readyEmitted = false

    before (done) ->
      try
        require 'microflo'
      catch e
        @skip()
      done()
    after (done) ->
      done()

    it 'should be instantiable', (done) ->
      c = (RemoteSubGraph.getComponentForRuntime def)(meta)
      chai.expect(c).to.be.an.instanceof noflo.Component
      c.once 'ready', () ->
        done()
    it 'should be possible to upload new graph', (done) ->
        checkRunning = (status) ->
          if status.running
            c.runtime.removeListener 'execution', checkRunning
            return done()
        c.runtime.on 'execution', checkRunning
        noflo.graph.loadFBP forward, (err, graph) ->
          graph = err if not graph # NoFlo <0.6 compat
          c.runtime.setMain graph # XXX: neccesary/correct?
          connection.sendGraph graph, c.runtime, () ->
            c.runtime.start() # does actual upload, MicroFlo specific
    it 'should have exported inport and outport', (done) ->
      checkPorts = () ->
        chai.expect(c.inPorts.ports).to.be.an 'object'
        chai.expect(c.outPorts.ports).to.be.an 'object'
        chai.expect(c.inPorts.ports['input']).to.be.an 'object'
        chai.expect(c.outPorts.ports['output']).to.be.an 'object'
        done()
      if c.isReady()
        checkPorts()
      else
        c.on 'ready', () ->
          checkPorts()
    it 'sending data into local port should be echoed back', (done) ->
      input = noflo.internalSocket.createSocket()
      output = noflo.internalSocket.createSocket()
      c.inPorts.input.attach input
      c.outPorts.output.attach output
      # FIXME: is called multiple times, should not happen
      output.once 'data', (data) ->
        chai.expect(data).to.deep.equal 113
        done()
      input.send 113


  describe 'NoFlo over Websocket in NoFlo', ->
    server = null
    c = null
    port = 3891

    echoNoflo = """
    INPORT=One.IN:INPUT
    OUTPORT=Three.OUT:OUTPUT
    One(core/Repeat) OUT -> IN Two(core/Repeat) OUT -> IN Three(core/Repeat)
    '1000'-> INTERVAL keepalive(core/RunInterval) OUT -> IN dummy(core/Repeat), 'foo' -> START keepalive
    """
    meta = {}
    readyEmitted = false
    def =
      label: "NoFlo node.js websocket"
      description: ""
      type: "noflo"
      protocol: "websocket"
      address: "ws://localhost:"+port
      secret: "my-super-secret2s"
      id: "2ef763ff-1f28-49b8-b58f-5c6a5c23af23"
      user: "3f3a8187-0931-4611-8963-239c0dff1934"
      seenHoursAgo: 11

    before (done) ->
      if noflo.isBrowser()
        port = 3892
        def.address = "ws://#{window.location.hostname}:#{port}"
        console.log "WebSocket NoFlo runtime should have been set up on #{def.address}"
        done()
      else
        utils.createNoFloServer port, (err, s) ->
          return done err if err
          console.log "NoFlo server running in port #{port}"
          server = s
          done()
    after (done) ->
      server.close() if server
      done()

    it 'should be instantiable', (done) ->
      @timeout 4*1000
      c = (RemoteSubGraph.getComponentForRuntime def)(meta)
      chai.expect(c).to.be.an.instanceof noflo.Component
      return setTimeout done, 2*1000 # FIXME: figure out why 'ready' is never emitted
      c.once 'ready', () ->
        done()
    it 'should be possible to upload new graph', (done) ->
        @timeout 10000 # component loading takes forever
        checkRunning = (status) ->
          if status.running
            c.runtime.removeListener 'execution', checkRunning
            return done()
        c.runtime.on 'execution', checkRunning
        noflo.graph.loadFBP echoNoflo, (err, graph) ->
          graph = err if not graph # NoFlo <0.6 compat
          graph.setProperties { id: 'echoNoflo', main: true }
          c.setGraph graph, (err) ->
            return done err if err
            c.runtime.start()
    it 'should have exported inport and outport', (done) ->
      checkPorts = () ->
        chai.expect(c.inPorts.ports).to.be.an 'object'
        chai.expect(c.outPorts.ports).to.be.an 'object'
        chai.expect(c.inPorts.ports['input']).to.be.an 'object'
        chai.expect(c.outPorts.ports['output']).to.be.an 'object'
        done()
      if c.isReady()
        checkPorts()
      else
        c.on 'ready', () ->
          checkPorts()
    it 'sending data into local port should be echoed back', (done) ->
      input = noflo.internalSocket.createSocket()
      output = noflo.internalSocket.createSocket()
      c.inPorts.input.attach input
      c.outPorts.output.attach output
      # FIXME: is called multiple times, should not happen
      output.once 'data', (data) ->
        chai.expect(data).to.deep.equal 113
        done()
      input.send 113
