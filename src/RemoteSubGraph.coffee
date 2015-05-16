noflo = require 'noflo'
connection = require './connection'
fbpClient = require 'fbp-protocol-client'

class RemoteSubGraph extends noflo.Component

  constructor: (metadata) ->
    metadata = {} unless metadata

    @runtime = null
    @ready = false
    @graph = null
    @graphName = null

    @inPorts = new noflo.InPorts
    @outPorts = new noflo.OutPorts
    # TODO: add connected/disconnected output port by default

  isReady: ->
    @ready
  setReady: (ready) ->
    @ready = ready
    @emit 'ready' if ready

  start: ->
    @runtime.start()
    super()

  shutdown: ->
    @runtime.stop()
    @runtime.disconnect()
    super()

  setDefinition: (definition) ->
    @definition = definition
    try
      Runtime = fbpClient.getTransport @definition.protocol
    catch e
      throw new Error "'#{@definition.protocol}' protocol not supported: " + e.message
    @runtime = new Runtime @definition

    @description = definition.description || ''
    @setIcon definition.icon if definition.icon

    @runtime.on 'capabilities', (capabilities) =>
      if 'protocol:runtime' not in capabilities
        throw new Error "runtime #{@definition.id} does not declare protocol:runtime"

      if definition.graph
        if 'protocol:graph' not in capabilities
          throw new Error "runtime #{@definition.id} does not declare protocol:graph"

        noflo.graph.loadFile definition.graph, (graph) =>
          @graph = graph
          @graphName = graph.name or graph.properties.id
          @runtime.setMain graph
          connection.sendGraph graph, @runtime, =>
            return
          , true

    @runtime.on 'runtime', (msg) =>
      if msg.command is 'runtime' and msg.payload.graph
        @graphName = msg.payload.graph
      if msg.command == 'ports'
        @setupPorts msg.payload
      else if msg.command == 'packet'
        @onPacketReceived msg.payload

    @runtime.on 'connected', () =>
      #
    @runtime.on 'error', () =>
      console.log 'error'

    # Attempt to connect
    @runtime.connect()

  setupPorts: (ports) ->
    if @definition.graph and not @graph
      # We are going to load and send a new graph to runtime, disregard whatever the runtime
      # tells initially
      return

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

  prepareInport: (definition) ->
    name = definition.id
    # Send data across to remote graph
    # TODO: set metadata like datatype
    @inPorts.add name, {}, (event, packet) =>
      @runtime.sendRuntime 'packet',
        port: name
        event: event
        payload: packet
        graph: @graphName

  prepareOutport: (definition) ->
    name = definition.id
    # TODO: set metadata like datatype
    port = @outPorts.add name, {}

  onPacketReceived: (packet) ->
    # TODO: set metadata like datatype
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
