noflo = require 'noflo'

sendGraph = (graph, runtime, callback) ->
  if graph.properties.environment?.type
    unless graph.properties.environment.type in ['all', runtime.definition.type]
      return callback new Error "Graph type #{graph.properties.environment.type} doesn't match runtime type #{runtime.definition.type}"

  unless runtime.canDo 'protocol:graph'
    return callback new Error 'Runtime doesn\'t support graph protocol'

  graphId = graph.name or graph.properties.id
  runtime.sendGraph 'clear',
    id: graphId
    name: graph.name
    library: graph.properties.project
    icon: graph.properties.icon or ''
    description: graph.properties.description or ''
  for node in graph.nodes
    runtime.sendGraph 'addnode',
      id: node.id
      component: node.component
      metadata: node.metadata
      graph: graphId
  for edge in graph.edges
    runtime.sendGraph 'addedge',
      src:
        node: edge.from.node
        port: edge.from.port
      tgt:
        node: edge.to.node
        port: edge.to.port
      metadata: edge.metadata
      graph: graphId
  for iip in graph.initializers
    runtime.sendGraph 'addinitial',
      src:
        data: iip.from.data
      tgt:
        node: iip.to.node
        port: iip.to.port
      metadata: iip.metadata
      graph: graphId
  if graph.inports
    for pub, priv of graph.inports
      runtime.sendGraph 'addinport',
        public: pub
        node: priv.process
        port: priv.port
        graph: graphId
  if graph.outports
    for pub, priv of graph.outports
      runtime.sendGraph 'addoutport',
        public: pub
        node: priv.process
        port: priv.port
        graph: graphId

  do callback

exports.getComponent = ->
  c = new noflo.Component
  c.inPorts.add 'graph',
    datatype: 'object'
    required: yes
  c.inPorts.add 'runtime',
    datatype: 'object'
    required: yes
  c.outPorts.add 'out',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: 'graph'
    params: 'runtime'
    out: 'out'
    async: true
  , (data, groups, out, callback) ->
    unless c.params.runtime.canDo
      return callback new Error 'Incorrect runtime instance'

    if c.params.runtime.isConnected()
      sendGraph data, c.params.runtime, (err) ->
        return callback err if err
        out.send data
        do callback
      return

    c.params.runtime.once 'capabilities', ->
      sendGraph data, c.params.runtime, (err) ->
        return callback err if err
        out.send data
        do callback

  c
