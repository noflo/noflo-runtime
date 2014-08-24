noflo = require 'noflo'

class ListGraphs extends noflo.Component
  constructor: ->
    @sources = {}
    @pending = []
    @runtime = null

    @inPorts = new noflo.InPorts
      auto:
        datatype: 'boolean'
        description: 'Request a graph list automatically on connection'
        required: false
      list:
        datatype: 'bang'
        description: 'Signal to start listing the graphs'
      runtime:
        datatype: 'object'
        description: 'Runtime to communicate with'
    @outPorts = new noflo.OutPorts
      graphs:
        datatype: 'array'
        description: 'An array of graph description'
      error:
        datatype: 'object'
        required: false

    @inPorts.on 'runtime', 'data', (@runtime) =>
      unless @runtime.canDo 'protocol:graph'
        return @error new Error "Runtime #{@runtime.definition.id} cannot list graphs"
      @subscribe @runtime
    @inPorts.on 'list', 'data', =>
      do @list
    @inPorts.on 'auto', 'data', (data) =>
      @auto = String(data) is 'true'

  subscribe: (runtime) ->
    runtime.on 'graph', (message) =>
      return unless runtime is @runtime
      if message.command == 'graph'
        @graphs.push message.payload.description
      else if message.command == 'graphsdone'
        return unless runtime is @runtime
        @outPorts.graphs.beginGroup runtime.id
        @outPorts.graphs.send @graphs
        @outPorts.graphs.endGroup()
        @outPorts.graphs.disconnect()
        @runtimes = []
    runtime.on 'disconnected',  =>
      return unless runtime is @runtime
      @graphs = []

    do @list if @auto

  list: ->
    unless @runtime
      @outPorts.error.send new Error 'No Runtime available'
      @outPorts.error.disconnect()
      return
    @graphs = []
    @runtime.sendGraph 'list', ''

exports.getComponent = -> new ListGraphs
