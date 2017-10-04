noflo = require 'noflo'
chai = require 'chai' unless chai
ListenRuntime = require '../components/ListenRuntime.coffee'
BaseRuntime = require '../node_modules/fbp-protocol-client/lib/base'

describe 'ListenRuntime component', ->
  component = null
  runtime = null
  runtimeSocket = null
  connectedSocket = null
  disconnectedSocket = null
  graphSocket = null

  beforeEach ->
    component = ListenRuntime.getComponent()
    runtime = new BaseRuntime
      capabilities: [
        'protocol:runtime'
        'protocol:graph'
        'protocol:component'
        'protocol:network'
      ]

    runtimeSocket = noflo.internalSocket.createSocket()
    component.inPorts.runtime.attach runtimeSocket

    connectedSocket = noflo.internalSocket.createSocket()
    component.outPorts.connected.attach connectedSocket

    disconnectedSocket = noflo.internalSocket.createSocket()
    component.outPorts.disconnected.attach disconnectedSocket

    graphSocket = noflo.internalSocket.createSocket()
    component.outPorts.graph.attach graphSocket

  describe 'instantiation', ->
    it 'should have a "runtime" inport', ->
      chai.expect(component.inPorts.runtime).to.be.an 'object'

    it 'should have a "connected" outport', ->
      chai.expect(component.outPorts.connected).to.be.an 'object'

    it 'should have a "disconnected" outport', ->
      chai.expect(component.outPorts.disconnected).to.be.an 'object'

    it 'should have a "graph" outport', ->
      chai.expect(component.outPorts.graph).to.be.an 'object'

  describe 'connection', ->
    beforeEach ->
      runtimeSocket.send runtime

    it 'should notify connected port when runtime connects', (done) ->
      connectedSocket.once 'data', (data) ->
        chai.expect(data).to.equal runtime
        done()

      runtime.emit 'connected'

    it 'should notify disconnected port when runtime disconnects', (done) ->
      disconnectedSocket.once 'data', (data) ->
        chai.expect(data).to.equal runtime
        done()

      runtime.emit 'disconnected'

    it 'should notify graph port when receiving graph event', (done) ->
      graphEvent =
        command: 'addnode'
        payload:
          component: 'core/Merge'
          graph: '123abc'
          id: 'component1'
          metadata:
            x: 0
            y: 0

      graphSocket.once 'data', (data) ->
        chai.expect(data).to.equal graphEvent
        done()

      runtime.emit 'graph', graphEvent
