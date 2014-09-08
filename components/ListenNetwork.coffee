noflo = require 'noflo'

exports.getComponent = () ->
  c = new noflo.Component
  c.description = 'Listen to a network on a runtime'

  c.inPorts.add 'runtime',
    datatype: 'object'
    description: 'Runtime to listen from'
    process: (event, payload) ->
      return unless event is 'data'
      c.updateListeners payload, c.graph
  c.inPorts.add 'graph',
    datatype: 'object'
    description: 'Graph to listen to'
    process: (event, payload) ->
      return unless event is 'data'
      c.updateListeners c.runtime, payload

  c.outPorts.add 'packet',
    datatype: 'object'

  c.updateListeners = (runtime, graph) ->
    @runtime.removeListener 'network', @onNetworkPacket if @runtime?
    @runtime = runtime
    @graph = graph
    return unless @graph? and @runtime?
    @graphId = if @graph.properties.library? then "#{@graph.properties.library}/#{@graph.properties.id}" else @graph.properties.id
    @runtime.on 'network', @onNetworkPacket if @runtime

  c.onNetworkPacket = ({command, payload}) =>
    return unless payload.graph
    return unless payload.graph == c.graphId
    c.outPorts.packet.send
      edge: payload.id
      type: command
      group: if payload.group? then payload.group else ''
      data: if payload.data? then payload.data else ''
      subgraph: if payload.subgraph? then payload.subgraph else ''
      runtime: c.runtime.definition.id

  c.shutdown = () ->
    @updateListeners null, null

  c
