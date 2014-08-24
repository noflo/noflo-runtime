Base = require './base'

class WebSocketRuntime extends Base
  constructor: (definition) ->
    @connecting = false
    @connection = null
    @protocol = 'noflo'
    @buffer = []
    @container = null
    super definition

  getElement: ->
    return @container if @container

    # DOM visualization for remote runtime output
    @container = document.createElement 'div'
    @container.classList.add 'preview-container'
    messageConsole = document.createElement 'pre'
    previewImage = document.createElement 'img'
    @container.appendChild previewImage
    @container.appendChild messageConsole

    @on 'network', (message) ->
      return unless message.command is 'output'

      p = message.payload
      if p.type? and p.type == 'previewurl'
        hasQuery = p.url.indexOf '?' != -1
        separator = if hasQuery then '&' else '?'
        previewImage.src = p.url + separator + 'timestamp=' + new Date().getTime()
      if p.message?
        encoded = p.message.replace /[\u00A0-\u99999<>\&]/gim, (i) -> "&##{i.charCodeAt(0)};"
        messageConsole.innerHTML += "#{encoded}\n"
        messageConsole.scrollTop = messageConsole.scrollHeight
    @on 'disconnected', ->
      messageConsole.innerHTML = ''

    @container

  connect: ->
    return if @connection or @connecting

    if @protocol
      @connection = new WebSocket @getAddress(), @protocol
    else
      @connection = new WebSocket @getAddress()
    @connection.addEventListener 'open', =>
      @connecting = false

      # Perform capability discovery
      @send 'runtime', 'getruntime', null

      @emit 'status',
        online: true
        label: 'connected'
      @emit 'connected'

      @flush()
    , false
    @connection.addEventListener 'message', @handleMessage, false
    @connection.addEventListener 'error', @handleError, false
    @connection.addEventListener 'close', (event) =>
      @connection = null
      @emit 'status',
        online: false
        label: 'disconnected'
      @emit 'disconnected'
    , false
    @connecting = true

  disconnect: ->
    return unless @connection
    @connecting = false
    @connection.close()

  send: (protocol, command, payload) ->
    if @connecting
      @buffer.push
        protocol: protocol
        command: command
        payload: payload
      return

    return unless @connection
    @connection.send JSON.stringify
      protocol: protocol
      command: command
      payload: payload

  handleError: (error) =>
    if @protocol is 'noflo'
      delete @protocol
      @connecting = false
      @connection = null
      setTimeout =>
        @connect()
      , 1
      return
    @emit 'error', error
    @connection = null
    @connecting = false

  handleMessage: (message) =>
    msg = JSON.parse message.data
    switch msg.protocol
      when 'runtime' then @recvRuntime msg.command, msg.payload
      when 'graph' then @recvGraph msg.command, msg.payload
      when 'network' then @recvNetwork msg.command, msg.payload
      when 'component' then @recvComponent msg.command, msg.payload

  flush: ->
    for item in @buffer
      @send item.protocol, item.command, item.payload
    @buffer = []

module.exports = WebSocketRuntime
