noflo = require 'noflo'

# @runtime all

class GetSource extends noflo.AsyncComponent
  icon: 'code'
  constructor: ->
    @sources = {}
    @pending = []
    @runtime = null

    @inPorts = new noflo.InPorts
      name:
        datatype: 'string'
        description: 'Name of the component to get'
      runtime:
        datatype: 'object'
        description: 'Runtime to communicate with'
        process: (event, payload) =>
          return unless event is 'data'
          @subscribe payload
    @outPorts = new noflo.OutPorts
      source:
        datatype: 'object'
      error:
        datatype: 'object'
        required: false

    super 'name', 'source'

  subscribe: (runtime) ->
    return if @runtime is runtime
    @unsubscribe @runtime if @runtime
    runtime.on 'component', @handleMessage
    @runtime = runtime
    if @runtime.connecting
      @runtime.once 'status', =>
        do @flush
    else
      do @flush

  unsubscribe: (runtime) ->
    @sources = {}
    @pending = []
    runtime.off 'component', @handleMessage
    @runtime = null

  handleMessage: (message) =>
    return unless message.command is 'source'
    @sources["#{message.payload.library}/#{message.payload.name}"] = message.payload

  doAsync: (name, callback) ->
    if not @runtime or @runtime.connecting
      @pending.push
        name: name
        callback: callback
      return

    @runtime.sendComponent 'getsource',
      name: name

    rounds = 10

    poll = =>
      rounds--

      if @sources[name]
        @outPorts.source.beginGroup name
        @outPorts.source.send @sources[name]
        @outPorts.source.endGroup()
        return callback()

      if rounds <= 0
        return callback new Error 'Runtime didn\'t provide source in time'

      setTimeout poll, 100
    setTimeout poll, 200

  shutdown: ->
    return unless @runtime
    unsubscribe @runtime

  flush: ->
    while @pending.length
      task = @pending.shift()
      @doAsync task.name, task.callback

exports.getComponent = -> new GetSource
