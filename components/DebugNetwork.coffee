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

  c.process (input, output) ->
    return unless input.hasData 'runtime', 'graph', 'enable'
    [runtime, graph, enable] = input.getData 'runtime', 'graph', 'enable'
    runtime.sendNetwork 'debug',
      graph: graph.name or graph.properties.id
      enable: enable
    output.sendDone
      sent: true
