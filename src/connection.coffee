
# Code for connecting between a noflo.Graph instance and a noflo-runtime

exports.sendGraph = (graph, runtime, callback) ->
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
