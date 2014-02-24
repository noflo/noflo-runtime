noflo = require 'noflo'

class SendGraphChanges extends noflo.Component
  constructor: ->
    @runtime = null
    @graph = null
    @changes = []
    @inPorts = new noflo.InPorts
      runtime:
        datatype: 'object'
        description: 'FBP Runtime instance'
        required: true
      graph:
        datatype: 'object'
        description: 'Graph to listen to'
        required: true
    @outPorts = new noflo.OutPorts
      queued:
        datatype: 'int'
        description: 'Number of changes in queue'
        required: false
      sent:
        datatype: 'bang'
        description: 'Notification that changes have been transmitted'
        required: false

    @inPorts.on 'runtime', 'data', (@runtime) =>
      @changes = []
      do @subscribe
    @inPorts.on 'graph', 'data', (graph) =>
      do @unsubscribe if @graph
      @changes = []
      @graph = graph
      do @subscribe

  subscribe: ->
    return if !@runtime or !@graph
    @graph.on 'endTransaction', @send
    @graph.on 'addNode', @addNode
    @graph.on 'removeNode', @removeNode
    @graph.on 'renameNode', @renameNode
    @graph.on 'addEdge', @addEdge
    @graph.on 'removeEdge', @removeEdge
    @graph.on 'addInitial', @addInitial
    @graph.on 'removeInitial', @removeInitial

  unsubscribe: ->
    return unless @graph
    @graph.removeListener 'endTransaction', @send
    @graph.removeListener 'addNode', @addNode
    @graph.removeListener 'removeNode', @removeNode
    @graph.removeListener 'renameNode', @renameNode
    @graph.removeListener 'addEdge', @addEdge
    @graph.removeListener 'removeEdge', @removeEdge
    @graph.removeListener 'addInitial', @addInitial
    @graph.removeListener 'removeInitial', @removeInitial

    @outPorts.sent.disconnect()
    @outPorts.queued.disconnect()

  registerChange: (topic, payload) =>
    @changes.push
      topic: topic
      payload: payload
    @outPorts.queued.send @changes.length

  addNode: (node) =>
    @registerChange 'addnode',
      id: node.id
      component: node.component
      metadata: node.metadata
      graph: @graph.properties.id

  removeNode: (node) =>
    @registerChange 'removenode',
      id: node.id
      graph: @graph.properties.id

  renameNode: (from, to) =>
    @registerChange 'renamenode',
      from: from
      to: to
      graph: @graph.properties.id

  addEdge: (edge) =>
    @registerChange 'addedge',
      src:
        node: edge.from.node
        port: edge.from.port
      tgt:
        node: edge.to.node
        port: edge.to.port
      metadata: edge.metadata
      graph: @graph.properties.id

  removeEdge: (edge) =>
    @registerChange 'removeedge',
      src:
        node: edge.from.node
        port: edge.from.port
      tgt:
        node: edge.to.node
        port: edge.to.port
      metadata: edge.metadata
      graph: @graph.properties.id

  addInitial: (iip) =>
    @registerChange 'addinitial',
      src:
        data: iip.from.data
      tgt:
        node: iip.to.node
        port: iip.to.port
      metadata: edge.metadata
      graph: @graph.properties.id

  removeInitial: (iip) =>
    @registerChange 'removeinitial',
      tgt:
        node: iip.to.node
        port: iip.to.port
      graph: @graph.properties.id

  send: =>
    return unless @runtime
    while @changes.length
      change = @changes.shift()
      @runtime.sendGraph change.topic, change.payload
    @outPorts.sent.beginGroup @graph.properties.id if @graph
    @outPorts.sent.send true
    @outPorts.sent.endGroup() if @graph
    @outPorts.queued.send @changes.length

  shutdown: ->
    do @unsubscribe

exports.getComponent = -> new SendGraphChanges
