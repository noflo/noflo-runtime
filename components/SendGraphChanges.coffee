noflo = require 'noflo'

# @runtime all

class SendGraphChanges extends noflo.Component
  constructor: ->
    @runtime = null
    @graph = null
    @changes = []
    @changesStates = {}
    @subscribed = false
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
      error:
        datatype: 'object'

    @inPorts.on 'runtime', 'data', (@runtime) =>
      @changes = []
      unless @runtime.canDo 'protocol:graph'
        return @error new Error "Runtime #{@runtime.definition.id} cannot update graphs"
      do @subscribe
    @inPorts.on 'graph', 'data', (graph) =>
      do @unsubscribe if @graph
      @changes = []
      @graph = graph
      do @subscribe

  subscribe: ->
    return if @subscribed
    return if !@runtime or !@graph
    @graph.on 'endTransaction', @send
    @graph.on 'addNode', @addNode
    @graph.on 'removeNode', @removeNode
    @graph.on 'renameNode', @renameNode
    @graph.on 'changeNode', @changeNode
    @graph.on 'addEdge', @addEdge
    @graph.on 'removeEdge', @removeEdge
    @graph.on 'changeEdge', @changeEdge
    @graph.on 'addInitial', @addInitial
    @graph.on 'removeInitial', @removeInitial
    @graph.on 'addInport', @addInport
    @graph.on 'removeInport', @removeInport
    @graph.on 'renameInport', @renameInport
    @graph.on 'addOutport', @addOutport
    @graph.on 'removeOutport', @removeOutport
    @graph.on 'renameOutport', @renameOutport
    @graph.on 'addGroup', @addGroup
    @graph.on 'removeGroup', @removeGroup
    @graph.on 'renameGroup', @renameGroup
    @graph.on 'changeGroup', @changeGroup
    @subscribed = true

  unsubscribe: ->
    return unless @graph
    @graph.removeListener 'endTransaction', @send
    @graph.removeListener 'addNode', @addNode
    @graph.removeListener 'removeNode', @removeNode
    @graph.removeListener 'renameNode', @renameNode
    @graph.removeListener 'changeNode', @changeNode
    @graph.removeListener 'addEdge', @addEdge
    @graph.removeListener 'removeEdge', @removeEdge
    @graph.removeListener 'changeEdge', @changeEdge
    @graph.removeListener 'addInitial', @addInitial
    @graph.removeListener 'removeInitial', @removeInitial
    @graph.removeListener 'addInport', @addInport
    @graph.removeListener 'removeInport', @removeInport
    @graph.removeListener 'renameInport', @renameInport
    @graph.removeListener 'addOutport', @addOutport
    @graph.removeListener 'removeOutport', @removeOutport
    @graph.removeListener 'renameOutport', @renameOutport
    @graph.removeListener 'addGroup', @addGroup
    @graph.removeListener 'removeGroup', @removeGroup
    @graph.removeListener 'renameGroup', @renameGroup
    @graph.removeListener 'changeGroup', @changeGroup
    @subscribed = false

    @outPorts.sent.disconnect()
    @outPorts.queued.disconnect()

  graphIdentifier: -> @graph.name or @graph.properties.id

  registerChange: (topic, payload) =>
    @changes.push
      topic: topic
      payload: payload
    @outPorts.queued.send @changes.length
    return @changes.length - 1

  replaceChange: (offset, topic, payload) =>
    @changes[offset] =
      topic: topic
      payload: payload

  addNode: (node) =>
    @registerChange 'addnode',
      id: node.id
      component: node.component
      metadata: node.metadata
      graph: @graphIdentifier()

  removeNode: (node) =>
    @registerChange 'removenode',
      id: node.id
      graph: @graphIdentifier()

  renameNode: (from, to) =>
    @registerChange 'renamenode',
      from: from
      to: to
      graph: @graphIdentifier()

  changeNode: (node) =>
    key = 'changenode- ' + node.id
    metadata =
      id: node.id
      metadata: node.metadata
      graph: @graphIdentifier()
    if @changesStates[key] is undefined
      @changesStates[key] = @registerChange 'changenode', metadata
    else
      @replaceChange @changesStates[key], 'changenode', metadata

  addEdge: (edge) =>
    @registerChange 'addedge',
      src:
        node: edge.from.node
        port: edge.from.port
      tgt:
        node: edge.to.node
        port: edge.to.port
      metadata: edge.metadata
      graph: @graphIdentifier()

  removeEdge: (edge) =>
    @registerChange 'removeedge',
      src:
        node: edge.from.node
        port: edge.from.port
      tgt:
        node: edge.to.node
        port: edge.to.port
      metadata: edge.metadata
      graph: @graphIdentifier()

  changeEdge: (edge) =>
    @registerChange 'changeedge',
      src:
        node: edge.from.node
        port: edge.from.port
      tgt:
        node: edge.to.node
        port: edge.to.port
      metadata: edge.metadata
      graph: @graphIdentifier()

  addInitial: (iip) =>
    @registerChange 'addinitial',
      src:
        data: iip.from.data
      tgt:
        node: iip.to.node
        port: iip.to.port
      metadata: iip.metadata
      graph: @graphIdentifier()

  removeInitial: (iip) =>
    @registerChange 'removeinitial',
      tgt:
        node: iip.to.node
        port: iip.to.port
      graph: @graphIdentifier()

  addInport: (pub, priv) =>
    @registerChange 'addinport',
      public: pub
      node: priv.process
      port: priv.port
      metadata: priv.metadata
      graph: @graphIdentifier()

  removeInport: (pub) =>
    @registerChange 'removeinport',
      public: pub
      graph: @graphIdentifier()

  renameInport: (oldPub, newPub) =>
    @registerChange 'renameinport',
      from: oldPub
      to: newPub
      graph: @graphIdentifier()

  addOutport: (pub, priv) =>
    @registerChange 'addoutport',
      public: pub
      node: priv.process
      port: priv.port
      metadata: priv.metadata
      graph: @graphIdentifier()

  removeOutport: (pub) =>
    @registerChange 'removeoutport',
      public: pub
      graph: @graphIdentifier()

  renameOutport: (oldPub, newPub) =>
    @registerChange 'renameoutport',
      from: oldPub
      to: newPub
      graph: @graphIdentifier()

  addGroup: (group) =>
    @registerChange 'addgroup',
      name: group.name
      nodes: group.nodes
      metadata: group.metadata
      graph: @graphIdentifier()

  removeGroup: (group) =>
    @registerChange 'removegroup',
      name: group.name
      graph: @graphIdentifier()

  renameGroup: (oldName, newName) =>
    @registerChange 'renamegroup',
      from: oldName
      to: newName
      graph: @graphIdentifier()

  changeGroup: (group, before) =>
    key = 'changegroup-' + group.name
    metadata =
      name: group.name
      metadata: group.metadata
      graph: @graphIdentifier()
    if @changesStates[key] is undefined
      @changesStates[key] = @registerChange 'changegroup', metadata
    else
      @replaceChange @changesStates[key], 'changegroup', metadata

  send: =>
    return unless @runtime
    while @changes.length
      change = @changes.shift()
      @runtime.sendGraph change.topic, change.payload
    @outPorts.sent.beginGroup @graphIdentifier() if @graph
    @outPorts.sent.send true
    @outPorts.sent.endGroup() if @graph
    @outPorts.queued.send @changes.length
    @changesStates = {}

  shutdown: ->
    do @unsubscribe

exports.getComponent = -> new SendGraphChanges
