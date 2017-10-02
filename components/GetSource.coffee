noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.icon = 'code'
  c.inPorts.add 'name',
    datatype: 'string'
    description: 'Name of the component to get'
  c.inPorts.add 'runtime',
    datatype: 'object'
    description: 'Runtime to communicate with'
  c.outPorts.add 'source',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'error'
  c.runtime = null

  c.tearDown = (callback) ->
    do unsubscribe
    do callback

  unsubscribe: ->
    return unless c.runtime
    c.runtime.rt.removeListener 'component', handleMessage
    c.runtime = null

  handleMessage = (message) ->
    return unless c.runtime
    return unless message.command is 'source'
    componentName = [message.payload.library, message.payload.name].join '/'
    # Cache the component
    c.runtime.sources[componentName] = message.payload

  c.process (input, output) ->
    if input.hasData 'runtime'
      # New runtime connection
      runtime = input.getData 'runtime'
      if c.runtime
        if c.runtime.rt is runtime
          # No-op if this runtime is same as what we had before
          return output.done()
        # Unsubscribe previous
        do unsubscribe
      if runtime.isConnected() and not runtime.canDo 'component:getsource'
        output.done new Error "Runtime #{runtime.definition.id} cannot get sources"
        return
      # Keep the context open
      c.runtime =
        rt: runtime
        sources: {}
      runtime.on 'component', handleMessage
      output.done()
      return
    return unless input.hasData 'name'
    # Requesting component sources
    return unless c.runtime
    name = input.getData 'name'
    if c.runtime.sources[name]
      # We already have this component cached
      output.sendDone
        source: c.runtime.sources[name]
      return
    # Request the sources from the runtime
    c.runtime.rt.sendComponent 'getsource',
      name: name
    # Wait for response
    rounds = 10
    poll = ->
      rounds--
      if c.runtime.sources[name]
        output.sendDone
          source: c.runtime.sources[name]
        return
      unless rounds
        output.done new Error "Runtime didn't provide source for #{name} in time"
      setTimeout poll, 100
    setTimeout poll, 100
