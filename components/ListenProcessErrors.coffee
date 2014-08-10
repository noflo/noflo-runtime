noflo = require 'noflo'

exports.getComponent = () ->
  c = new noflo.Component
  c.description = 'Listen to process errors on a runtime'

  c.inPorts.add 'runtime',
    datatype: 'object'
    description: 'FBP Runtime instance'
    required: yes
    process: (event, payload) ->
      return unless event is 'data'
      c.updateListener payload

  c.outPorts.add 'process',
    datatype: 'string'
    description: 'Process id that generated the error'
  c.outPorts.add 'message',
    datatype: 'string'
    description: 'Error message'

  c.updateListener = (runtime) ->
    @removeListener()
    @runtime = runtime
    @listener = (message) =>
      return unless message.command is 'processerror'
      console.log "got error message : "
      console.log JSON.stringify message
      @outPorts.process.send message.payload.id
      @outPorts.message.send message.payload.error
      @outPorts.process.disconnect()
      @outPorts.message.disconnect()
    @runtime.on 'network', @listener if @runtime

  c.removeListener = () ->
    return unless @runtime
    @runtime.removeListener 'network', @listener

  c.shutdown = () ->
    @removeListener()

  c
