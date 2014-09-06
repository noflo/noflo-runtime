noflo = require 'noflo'

exports.getComponent = () ->
  c = new noflo.Component
  c.description = "Switch a network's debug mode on or off"

  c.inPorts.add 'runtime',
    datatype: 'object'
    description: 'FBP runtime instance'
  c.inPorts.add 'graph',
    datatype: 'object'
    description: 'Graph to debug'
  c.inPorts.add 'enable',
    datatype: 'boolean'
    description: 'Whether to debug the graph'

  c.outPorts.add 'sent',
    datatype: 'bang'
    description: 'Command sent to the runtime'

  c.inPorts.enable.on 'data', (data) ->
    console.log "data:"
    console.log data

  noflo.helpers.WirePattern c,
    in: 'enable'
    params: ['runtime', 'graph']
    forwardGroups: true
    out: 'sent'
  , (data, groups, out) ->
    return unless c.params.runtime? and c.params.graph?
    graph = c.params.graph
    graphId = if graph.properties.library? then "#{graph.properties.library}/#{graph.properties.id}" else graph.properties.id
    c.params.runtime.sendNetwork 'debug',
      graph: graphId
      enable: data
    out.send true

  c
