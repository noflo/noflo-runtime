noflo = require 'noflo'

class ListNetworks extends noflo.Component
  constructor: ->
    @sources = {}
    @pending = []
    @runtime = null

    @inPorts = new noflo.InPorts
      auto:
        datatype: 'boolean'
        description: 'Request a network list automatically on connection'
        required: false
      list:
        datatype: 'bang'
        description: 'Signal to start listing the graphs'
      runtime:
        datatype: 'object'
        description: 'Runtime to communicate with'
    @outPorts = new noflo.OutPorts
      networks:
        datatype: 'array'
        description: 'An array of networks description'
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
    runtime.on 'network', (message) =>
      return unless runtime is @runtime
      console.log "Network message!"
      console.log message
      if message.command == 'network'
        @networks.push message.payload
      else if message.command == 'networksdone'
        return unless runtime is @runtime
        @outPorts.graphs.beginGroup runtime.id
        @outPorts.graphs.send @networks
        @outPorts.graphs.endGroup()
        @outPorts.graphs.disconnect()
        @networks = []
    runtime.on 'disconnected',  =>
      return unless runtime is @runtime
      @networks = []

    do @list if @auto

  list: ->
    unless @runtime
      @outPorts.error.send new Error 'No Runtime available'
      @outPorts.error.disconnect()
      return
    @networks = []
    @runtime.sendNetwork 'list', ''

exports.getComponent = -> new ListNetworks
