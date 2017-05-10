noflo = require 'noflo'
connection = require './connection'
fbpClient = require 'fbp-protocol-client'
debug = require('debug') 'noflo-runtime:remotesubgraph'

class RemoteSubGraph extends noflo.Component

  constructor: (metadata) ->
    metadata = {} unless metadata

    @runtime = null
    @ready = false
    @graph = null
    @graphName = null

    super()

  isReady: ->
    @ready
  setReady: (ready) ->
    debug("#{@nodeId} setting ready to #{ready}")
    @ready = ready
    @emit 'ready' if ready

  setUp: (callback) ->
    @runtime.start()
    do callback

  tearDown: (callback) ->
    @runtime.stop()
    @runtime.disconnect()
    do callback

  setDefinition: (definition) ->
    @definition = definition
    try
      Runtime = fbpClient.getTransport @definition.protocol
    catch e
      throw new Error "'#{@definition.protocol}' protocol not supported: " + e.message
    @runtime = new Runtime @definition

    @description = definition.description || ''
    @setIcon definition.icon if definition.icon

    @runtime.on 'runtime', (msg) =>
      if msg.command is 'runtime'
        @handleRuntime definition, msg.payload
      if msg.command == 'ports'
        @setupPorts msg.payload
      else if msg.command == 'packet'
        @onPacketReceived msg.payload

    @runtime.on 'error', (err) ->
      console.error err

    # Attempt to connect
    @runtime.connect()

  handleRuntime: (definition, payload) ->
    if 'protocol:runtime' not in payload.capabilities
      throw new Error "runtime #{definition.id} does not allow protocol:runtime"
    if payload.graph and payload.graph is definition.graph
      debug "#{@nodeId} runtime is already running desired graph #{payload.graph}"
      @graphName = payload.graph
      # Already running the desired graph
      @runtime.setMain
        name: payload.graph
      return
    unless definition.graph
      # No graph to upload, accept what runtime has
      return
    # Prepare to upload graph
    if 'protocol:graph' not in payload.capabilities
      throw new Error "runtime #{definition.id} does not allow protocol:graph"

    debug "#{@nodeId} sending graph #{definition.graph} to runtime (had #{payload.graph})"
    noflo.graph.loadFile definition.graph, (err, graph) =>
      throw err if err
      graph.properties.id = definition.graph unless graph.properties.id
      @setGraph graph, (err) ->
        throw err if err

  setGraph: (graph, callback) ->
    @graph = graph
    @graphName = graph.name or graph.properties.id
    @runtime.setMain graph
    connection.sendGraph graph, @runtime, callback, true

  setupPorts: (ports) ->
    if @graph
      # We should only emit ready once the remote runtime sent us at least all the ports that
      # the graph exports
      for exported, metadata of @graph.inports
        matching = ports.inPorts.filter (port) -> port.id is exported
        return unless matching.length
      for exported, metadata of @graph.outports
        matching = ports.outPorts.filter (port) -> port.id is exported
        return unless matching.length
    
    @setReady false
    # Expose remote graph's exported ports as node ports
    @prepareInport port for port in ports.inPorts
    @prepareOutport port for port in ports.outPorts
    @setReady true

  normalizePort: (definition) ->
    type = definition.type or 'all'
    type = 'all' if type is 'any'
    return def =
      datatype: type
      required: definition.required or false
      addressable: definition.addressable or false

  prepareInport: (definition) ->
    name = definition.id
    # Send data across to remote graph
    @inPorts.add name, @normalizePort(definition), (event, packet) =>
      packet = null if event in ['connect', 'disconnect']
      @runtime.sendRuntime 'packet',
        port: name
        event: event
        payload: packet
        graph: @graphName

  prepareOutport: (definition) ->
    name = definition.id
    port = @outPorts.add name, @normalizePort definition

  onPacketReceived: (packet) ->
    name = packet.port
    port = @outPorts[name]
    switch packet.event
      when 'connect' then port.connect()
      when 'begingroup' then port.beginGroup packet.payload
      when 'data' then port.send packet.payload
      when 'endgroup' then port.endGroup packet.payload
      when 'disconnect' then port.disconnect()

exports.RemoteSubGraph = RemoteSubGraph
exports.getComponent = (metadata) -> new RemoteSubGraph metadata
exports.getComponentForRuntime = (runtime, baseDir) ->
  return (metadata) ->
    instance = exports.getComponent metadata
    instance.baseDir = baseDir
    instance.setDefinition runtime
    return instance
