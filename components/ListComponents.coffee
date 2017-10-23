noflo = require 'noflo'

onRuntimeConnected = null
onRuntimeComponent = null

subscribe = (runtime, output) ->
  requestListing = ->
    return unless runtime.canDo 'protocol:component'
    runtime.sendComponent 'list'
  onRuntimeConnected = -> do requestListing
  onRuntimeComponent = (message) ->
    return unless message.command is 'component'
    return if message.payload.name in ['Graph', 'ReadDocument']
    definition =
      name: message.payload.name
      description: message.payload.description
      icon: message.payload.icon
      subgraph: message.payload.subgraph or false
      runtime: message.payload.runtime or runtime.definition?.id
      inports: message.payload.inPorts.slice(0).map (port) ->
        port.name = port.id
        delete port.id
        return port
      outports: message.payload.outPorts.slice(0).map (port) ->
        port.name = port.id
        delete port.id
        return port
    output.send
      out:
        componentDefinition: definition
  runtime.on 'capabilities', onRuntimeConnected
  runtime.on 'component', onRuntimeComponent
  do requestListing if runtime.isConnected()

unsubscribe = (runtime, context) ->
  runtime.removeListener 'capabilities', onRuntimeConnected if onRuntimeConnected
  runtime.removeListener 'component', onRuntimeComponent if onRuntimeComponent
  onRuntimeConnected = null
  onRuntimeComponent = null
  context.deactivate()

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'List components available on a runtime'
  c.inPorts.add 'runtime',
    datatype: 'object'
  c.outPorts.add 'out',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'

  c.runtime = null
  c.tearDown = (callback) ->
    unsubcribe c.runtime.rt, c.runtime.ctx if c.runtime
    c.runtime = null
    do callback
  c.forwardBrackets = {}
  c.process (input, output, context) ->
    return unless input.hasData 'runtime'
    runtime = input.getData 'runtime'
    unsubscribe c.runtime.rt, c.runtime.ctx if c.runtime
    c.runtime =
      rt: runtime
      ctx: context
    subscribe c.runtime.rt, output
