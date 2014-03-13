EventEmitter = require 'emitter'

class BaseRuntime extends EventEmitter
  constructor: (@definition) ->
    @graph = null

  setMain: (@graph) ->

  getType: -> @definition.protocol
  getAddress: -> @definition.address

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
      graph: @graph.properties.id

  # Stop a NoFlo network
  stop: ->
    unless @graph
      throw new Error 'No graph defined for execution'
    @sendNetwork 'stop',
      graph: @graph.properties.id

  # Set the parent element that some runtime types need
  setParentElement: (parent) ->

  # Get a DOM element rendered by the runtime for preview purposes
  getElement: ->

  recvRuntime: (command, payload) ->
    @emit 'graph',
      command: command
      payload: payload

  recvComponent: (command, payload) ->
    switch command
      when 'component'
        @emit 'component',
          command: command
          payload: payload
      when 'error'
        @emit 'network',
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
          running: true
          label: 'running'
      when 'stopped'
        @emit 'execution',
          running: false
          label: 'stopped'
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
