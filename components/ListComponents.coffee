noflo = require 'noflo'

onRuntimeConnected = null
onRuntimeComponent = null

subscribe = (runtime, port) ->
  requestListing = ->
    return unless runtime.canDo 'protocol:component'
    runtime.sendComponent 'list'
    port.connect()
    port.beginGroup 'list'

  onRuntimeConnected = -> do requestListing
  onRuntimeComponent = (message) ->
    if message.command is 'componentsready'
      port.endGroup 'list'

    return unless message.command is 'component'
    return if message.payload.name in ['Graph', 'ReadDocument']
    definition =
      name: message.payload.name
      description: message.payload.description
      icon: message.payload.icon
      subgraph: message.payload.subgraph or false
      runtime: message.payload.runtime or runtime.definition?.id
      inports: []
      outports: []
    for portDef in message.payload.inPorts
      definition.inports.push
        name: portDef.id
        type: portDef.type
        required: portDef.required
        description: portDef.description
        addressable: portDef.addressable
        values: portDef.values
        default: portDef.default
    for portDef in message.payload.outPorts
      definition.outports.push
        name: portDef.id
        type: portDef.type
        required: portDef.required
        description: portDef.description
        addressable: portDef.addressable
    port.send
      componentDefinition: definition

  runtime.on 'capabilities', onRuntimeConnected
  runtime.on 'component', onRuntimeComponent
  do requestListing if runtime.isConnected()

unsubscribe = (runtime, port) ->
  port.disconnect()
  runtime.removeListener 'capabilities', onRuntimeConnected if onRuntimeConnected
  runtime.removeListener 'component', onRuntimeComponent if onRuntimeComponent
  onRuntimeConnected = null
  onRuntimeComponent = null

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'List components available on a runtime'
  c.runtime = null
  c.inPorts.add 'runtime',
    datatype: 'object'
    process: (event, payload) ->
      return unless event is 'data'
      unsubscribe c.runtime, c.outPorts.out if c.runtime
      if payload.isConnected() and not payload.canDo 'protocol:component'
        return c.error new Error "Runtime #{payload.definition.id} is not able to list components"
      c.runtime = payload
      subscribe c.runtime, c.outPorts.out
  c.outPorts.add 'out',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'

  c.shutdown = ->
    unsubscribe c.runtime, c.outPorts.out if c.runtime

  c
