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
    c.runtime.removeListener 'network', c.onNetworkPacket if c.runtime
    c.runtime = runtime
    c.graph = graph
    c.runtime.on 'network', c.onNetworkPacket if c.runtime

  c.onNetworkPacket = ({command, payload}) ->
    return if not payload.graph or not c.graph or payload.graph isnt c.graph.name
    c.outPorts.packet.send
      edge: payload.id
      type: command
      group: if payload.group? then payload.group else ''
      data: if payload.data? then payload.data else ''
      subgraph: if payload.subgraph? then payload.subgraph else ''
      runtime: c.runtime.definition.id

  c.shutdown = ->
    c.updateListeners null, null

  c
