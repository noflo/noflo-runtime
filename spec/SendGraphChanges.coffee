noflo = require 'noflo'
chai = require 'chai' unless chai
BaseRuntime = require '../node_modules/fbp-protocol-client/lib/base'
path = require 'path'
baseDir = path.resolve __dirname, '../'

describe 'SendGraphChanges component', ->
  component = null
  graph = null
  runtime = null
  runtimeSocket = null
  graphSocket = null
  queuedSocket = null
  sentSocket = null
  errorSocket = null
  loader = null

  before ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
  beforeEach (done) ->
    loader.load 'runtime/SendGraphChanges', (err, instance) ->
      return done err if err
      component = instance
      runtime = new BaseRuntime
        capabilities: [
          'protocol:graph'
        ]

      runtimeSocket = noflo.internalSocket.createSocket()
      component.inPorts.runtime.attach runtimeSocket

      graphSocket = noflo.internalSocket.createSocket()
      component.inPorts.graph.attach graphSocket

      queuedSocket = noflo.internalSocket.createSocket()
      component.outPorts.queued.attach queuedSocket

      sentSocket = noflo.internalSocket.createSocket()
      component.outPorts.sent.attach sentSocket

      errorSocket = noflo.internalSocket.createSocket()
      component.outPorts.error.attach errorSocket

      graph = new noflo.Graph 'hello'

      done()

  describe 'with a runtime and a graph', ->
    beforeEach ->
      runtimeSocket.send runtime
      graphSocket.send graph

    it 'should queue an addNode event', (done) ->
      errorSocket.on 'data', (data) ->
        done data
      queuedSocket.on 'data', (data) ->
        chai.expect(data).to.equal 1
        done()
      graph.addNode 'test', 'core/Split'
    it 'should send queued events on endTransaction', (done) ->
      queued = [
        1
        2
        3
        0
      ]
      errorSocket.on 'data', (data) ->
        done data
      queuedSocket.on 'data', (data) ->
        chai.expect(data).to.equal queued.shift()
      sentSocket.on 'data', ->
        chai.expect(queued.length).to.equal 0
        done()
      graph.startTransaction 'foo'
      graph.addNode 'sender', 'core/Split'
      graph.addNode 'receiver', 'core/Split'
      graph.addEdge 'sender', 'out', 'receiver', 'in'
      graph.endTransaction 'foo'
