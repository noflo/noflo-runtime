platform = require '../platform'

class BaseRuntime extends platform.EventEmitter
  constructor: (@definition) ->
    @definition.capabilities = [] unless definition.capabilities
    @graph = null

  setMain: (@graph) ->

  getType: -> @definition.protocol
  getAddress: -> @definition.address

  canDo: (capability) ->
    @definition.capabilities.indexOf(capability) isnt -1

  isConnected: -> false

  # Connect to the target runtime environment (iframe URL, WebSocket address)
  connect: ->

  disconnect: ->

  reconnect: ->
    do @disconnect
    do @connect

  # Start a NoFlo Network
  start: ->
    unless @graph
      throw new Error 'No graph defined for execution'
    @sendNetwork 'start',
      graph: @graph.name or @graph.properties.id

  # Stop a NoFlo network
  stop: ->
    unless @graph
      throw new Error 'No graph defined for execution'
    @sendNetwork 'stop',
      graph: @graph.name or @graph.properties.id

  # Set the parent element that some runtime types need
  setParentElement: (parent) ->

  # Get a DOM element rendered by the runtime for preview purposes
  getElement: ->

  recvRuntime: (command, payload) ->
    if command is 'runtime'
      for key, val of payload
        @definition[key] = val
      @emit 'capabilities', payload.capabilities or []
    @emit 'runtime',
      command: command
      payload: payload

  recvComponent: (command, payload) ->
    switch command
      when 'error'
        @emit 'network',
          command: command
          payload: payload
      else
        @emit 'component',
          command: command
          payload: payload

  recvGraph: (command, payload) ->
    @emit 'graph',
      command: command
      payload: payload

  recvNetwork: (command, payload) ->
    switch command
      when 'started'
        @emit 'execution',
          running: if payload? and payload.running? then payload.running else true
          started: if payload? and payload.started then payload.started else true
      when 'stopped'
        @emit 'execution',
          running: if payload? and payload.running? then payload.running else false
          started: if payload? and payload.started then payload.started else false
      when 'status'
        @emit 'execution',
          running: payload.running
          started: payload.started
      when 'icon'
        @emit 'icon', payload
      else
        @emit 'network',
          command: command
          payload: payload

  sendRuntime: (command, payload) ->
    @send 'runtime', command, payload
  sendGraph: (command, payload) ->
    @send 'graph', command, payload
  sendNetwork: (command, payload) ->
    @send 'network', command, payload
  sendComponent: (command, payload) ->
    @send 'component', command, payload

  send: (protocol, command, payload) ->

module.exports = BaseRuntime
