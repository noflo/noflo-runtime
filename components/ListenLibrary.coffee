noflo = require 'noflo'

class ListenLibrary extends noflo.Component
  constructor: ->
    @runtime = null
    @auto = true
    @inPorts = new noflo.InPorts
      runtime:
        datatype: 'object'
        description: 'FBP Runtime instance'
        required: true
      list:
        datatype: 'bang'
        description: 'Request a list of components from Runtime'
        required: false
      auto:
        datatype: 'boolean'
        description: 'Request a component list automatically on connection'
        required: false
    @outPorts = new noflo.OutPorts
      component:
        datatype: 'object'
        description: 'Component definition received from runtime'
      error:
        datatype: 'object'
        required: false

    @inPorts.on 'runtime', 'data', (@runtime) =>
      @subscribe @runtime
    @inPorts.on 'list', 'data', =>
      do @list
    @inPorts.on 'auto', 'data', (data) =>
      @auto = String(data) is 'true'

  subscribe: (runtime) ->
    runtime.on 'component', (message) =>
      return unless runtime is @runtime
      if message.payload.name is 'Graph' or message.payload.name is 'ReadDocument'
        return
      definition =
        name: message.payload.name
        description: message.payload.description
        icon: message.payload.icon
        inports: []
        outports: []
      for port in message.payload.inPorts
        definition.inports.push
          name: port.id
          type: port.type
          array: port.array
      for port in message.payload.outPorts
        definition.outports.push
          name: port.id
          type: port.type
          array: port.array

      @outPorts.component.beginGroup runtime.id
      @outPorts.component.send definition
      @outPorts.component.endGroup()
    runtime.on 'disconnected',  =>
      return unless runtime is @runtime
      @outPorts.component.disconnect()

    do @list if @auto

  list: ->
    unless @runtime
      @outPorts.error.send new Error 'No Runtime available'
      @outPorts.error.disconnect()
      return
    @runtime.sendComponent 'list', ''

exports.getComponent = -> new ListenLibrary
