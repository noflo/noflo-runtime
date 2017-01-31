noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Send edges selected by user to runtime'
  c.inPorts.add 'edges',
    datatype: 'array'
    required: yes
  c.inPorts.add 'runtime',
    datatype: 'object'
    required: yes
  c.inPorts.add 'graph',
    datatype: 'object'
    required: yes
  c.outPorts.add 'out',
    datatype: 'array'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: ['edges', 'graph', 'runtime']
    out: 'out'
    async: true
    forwardGroups: true
  , (data, groups, out, callback) ->
    unless data.runtime?.canDo
      # Pass-through
      out.send data.edges
      do callback
      return
    unless data.runtime.isConnected()
      # Pass-through since there is no connection
      out.send data.edges
      do callback
      return
    data.runtime.sendNetwork 'edges',
      edges: data.edges
      graph: data.graph?.name or data.graph?.properties.id
    out.send data.edges
    do callback
