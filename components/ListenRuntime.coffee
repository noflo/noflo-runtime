noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.inPorts.add 'runtime',
    datatype: 'object'
    description: 'FBP Runtime instance'
  c.outPorts.add 'connected',
    datatype: 'object'
    description: 'FBP Runtime instance'
  c.outPorts.add 'disconnected',
    datatype: 'object'
    description: 'Runtime connection error'
  c.outPorts.add 'graph',
    datatype: 'object'
    description: 'Changes to runtime graph'

  c.runtime = null
  unsubscribe = ->
    return unless c.runtime
    c.runtime.rt.removeListener 'connected', c.runtime.onConnected
    c.runtime.rt.removeListener 'disconnected', c.runtime.onDisconnected
    c.runtime.rt.removeListener 'graph', c.runtime.onGraph
    c.runtime.ctx.deactivate()
    c.runtime = null
  c.tearDown = (callback) ->
    do unsubscribe
    do callback

  c.forwardBrackets = {}
  c.process (input, output, context) ->
    return unless input.hasData 'runtime'
    c.runtime =
      rt: input.getData 'runtime'
      onConnected: ->
        output.send
          connected: c.runtime.rt
      onDisconnected: ->
        output.send
          disconnected: c.runtime.rt
      onGraph: (data) ->
        output.send
          graph: data
      ctx: context
    c.runtime.rt.on 'connected', c.runtime.onConnected
    c.runtime.rt.on 'disconnected', c.runtime.onDisconnected
    c.runtime.rt.on 'graph', c.runtime.onGraph
