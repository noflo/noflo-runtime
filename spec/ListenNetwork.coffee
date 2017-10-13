noflo = require 'noflo'
chai = require 'chai' unless chai
BaseRuntime = require '../node_modules/fbp-protocol-client/lib/base'
path = require 'path'
baseDir = path.resolve __dirname, '../'

describe 'ListenNetwork component', ->
  component = null
  runtime = null
  runtimeSocket = null
  graphSocket = null
  startedSocket = null
  stoppedSocket = null
  packetSocket = null
  errorSocket = null
  loader = null

  before ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
  beforeEach (done) ->
    loader.load 'runtime/ListenNetwork', (err, instance) ->
      return done err if err
      component = instance
      runtime = new BaseRuntime
        capabilities: [
          'protocol:network'
        ]
      runtime.definition =
        id: 123

      runtimeSocket = noflo.internalSocket.createSocket()
      component.inPorts.runtime.attach runtimeSocket

      graphSocket = noflo.internalSocket.createSocket()
      component.inPorts.graph.attach graphSocket

      startedSocket = noflo.internalSocket.createSocket()
      component.outPorts.started.attach startedSocket

      stoppedSocket = noflo.internalSocket.createSocket()
      component.outPorts.stopped.attach stoppedSocket

      packetSocket = noflo.internalSocket.createSocket()
      component.outPorts.packet.attach packetSocket

      errorSocket = noflo.internalSocket.createSocket()
      component.outPorts.error.attach errorSocket

      done()

  describe 'connection', ->
    beforeEach ->
      runtimeSocket.send runtime
      graphSocket.send
        name: 'foo'

    it 'should notify error port on network errors', (done) ->
      payload =
        message: 'Something went wrong'
      errorSocket.on 'data', (data) ->
        chai.expect(data).to.eql payload
        done()

      runtime.emit 'network',
        command: 'error'
        payload: payload

    it 'should notify started port when network starts', (done) ->
      payload =
        time: Date.now()
        started: true
        running: true
        graph: 'foo'
      startedSocket.on 'data', (data) ->
        chai.expect(data).to.eql payload
        done()

      runtime.emit 'network',
        command: 'started'
        payload: payload

    it 'shouldn\'t notify started port when wrong network starts', (done) ->
      payload =
        time: Date.now()
        started: true
        running: true
        graph: 'bar'
      received = false
      startedSocket.on 'data', (data) ->
        received = true
        done new Error 'Received non-expected started message'

      setTimeout ->
        chai.expect(received).to.equal false
        done()
      , 100

      runtime.emit 'network',
        command: 'started'
        payload: payload

    it 'should notify stopped port when network stops', (done) ->
      payload =
        time: Date.now()
        started: true
        running: false 
        graph: 'foo'
      stoppedSocket.on 'data', (data) ->
        chai.expect(data).to.eql payload
        done()

      runtime.emit 'network',
        command: 'stopped'
        payload: payload

    it 'should notify packet port on network begingroups', (done) ->
      payload =
        id: 'Foo OUT -> IN Bar'
        src:
          node: 'Foo'
          port: 'out'
        tgt:
          node: 'Bar'
          port: 'in'
        group: 'Hello'
        graph: 'foo'
      packetSocket.on 'data', (data) ->
        chai.expect(data).to.eql
          edge: payload.id
          src: payload.src
          tgt: payload.tgt
          type: 'begingroup'
          group: payload.group
          data: ''
          subgraph: ''
          runtime: 123
        done()

      runtime.emit 'network',
        command: 'begingroup'
        payload: payload
