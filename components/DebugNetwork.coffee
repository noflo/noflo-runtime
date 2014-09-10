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
    c.params.runtime.sendNetwork 'debug',
      graph: c.params.graph.name or c.params.graph.properties.id
      enable: data
    out.send true

  c
