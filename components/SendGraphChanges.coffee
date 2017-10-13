noflo = require 'noflo'

# @runtime all

convertEvent = (graph, event, data) ->
  msg =
    command: event.toLowerCase()
    payload: {}
  switch event
    when 'renameNode', 'renameInport', 'renameOutport', 'renameGroup'
      msg.payload =
        from: data[0]
        to: data[1]
    when 'addEdge', 'removeEdge', 'changeEdge', 'addInitial'
      msg.payload =
        src: data[0].from
        tgt: data[0].to
        metadata: data[0].metadata
    when 'removeInitial'
      msg.payload =
        tgt: data[0].to
    when 'addInport', 'addOutport'
      msg.payload =
        public: data[0]
        node: data[1].process
        port: data[1].port
        metadata: data[1].metadata
    when 'removeInport', 'removeOutport'
      msg.payload =
        public: data[0]
    else
      msg.payload = data[0]
  msg.payload.graph = graph.name or graph.properties?.id
  return msg

exports.getComponent = ->
  c = new noflo.Component
  c.inPorts.add 'runtime',
    datatype: 'object'
    description: 'FBP Runtime instance'
  c.inPorts.add 'graph',
    datatype: 'object'
    description: 'Graph to listen to'
  c.outPorts.add 'queued',
    datatype: 'int'
    description: 'Number of changes in queue'
  c.outPorts.add 'sent',
    datatype: 'bang'
    description: 'Notification that changes have been transmitted'
  c.outPorts.add 'error',
    datatype: 'object'

  events = [
    'addNode'
    'removeNode'
    'renameNode'
    'changeNode'
    'addEdge'
    'removeEdge'
    'changeEdge'
    'addInitial'
    'removeInitial'
    'addInport'
    'removeInport'
    'renameInport'
    'addOutport'
    'removeOutport'
    'renameOutport'
    'addGroup'
    'removeGroup'
    'renameGroup'
    'changeGroup'
  ]

  c.current = null
  unsubscribe = ->
    return unless c.current
    for event in events
      c.current.graph.removeListener event, c.current[event]
    c.current.graph.removeListener 'endTransaction', c.current.endTransaction
    c.current.ctx.deactivate()
    c.current = null
  c.tearDown = (callback) ->
    do unsubscribe
    do callback

  c.process (input, output, context) ->
    return unless input.hasData 'runtime', 'graph'
    [runtime, graph] = input.getData 'runtime', 'graph'
    do unsubscribe

    unless runtime.canDo 'protocol:graph'
      output.done new Error "Runtime #{@runtime.definition.id} cannot update graphs"
      return

    c.current =
      graph: graph
      rt: runtime
      ctx: context
      changes: []

    events.forEach (event) ->
      # Convert fbp-graph event name to fbp-protocol command
      c.current[event] = (args...) ->
        return unless c.current.graph is graph
        c.current.changes.push convertEvent graph, event, args
        output.send
          queued: c.current.changes.length
      graph.on event, c.current[event]

    c.current.endTransaction = ->
      return unless c.current.graph is graph
      while c.current.changes.length
        change = c.current.changes.shift()
        c.current.rt.sendGraph change.command, change.payload
      output.send
        queued: c.current.changes.length
      output.send
        sent: true
    graph.on 'endTransaction', c.current.endTransaction
    return
