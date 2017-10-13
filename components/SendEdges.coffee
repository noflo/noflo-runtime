noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Send edges selected by user to runtime'
  c.inPorts.add 'edges',
    datatype: 'array'
  c.inPorts.add 'runtime',
    datatype: 'object'
  c.inPorts.add 'graph',
    datatype: 'object'
  c.outPorts.add 'out',
    datatype: 'array'
  c.outPorts.add 'error',
    datatype: 'object'

  c.process (input, output) ->
    return unless input.hasData 'edges', 'runtime', 'graph'
    [edges, runtime, graph] = input.getData 'edges', 'runtime', 'graph'
    unless runtime?.canDo
      # Pass-through
      output.sendDone
        out: edges
      return
    unless runtime.isConnected()
      # Pass-through since there is no connection
      output.sendDone
        out: edges
      return
    runtime.sendNetwork 'edges',
      edges: edges.map (edge) ->
        e =
          src: edge.src or edge.from
          tgt: edge.tgt or edge.to
        return e
      graph: graph.name or graph.properties?.id
    output.sendDone
      out: edges
