Base = require './base'

class WebRTCRuntime extends Base
  constructor: (definition) ->
    @peer = null
    @connecting = false
    @connection = null
    @protocol = 'webrtc'
    @buffer = []
    super definition

  getElement: ->
    # DOM visualization for remote runtime output
    console = document.createElement 'pre'

    @on 'network', (message) ->
      return unless message.command is 'output'
      message.payload.message = '' unless message.payload.message
      encoded = message.payload.message.replace /[\u00A0-\u99999<>\&]/gim, (i) -> "&##{i.charCodeAt(0)};"
      console.innerHTML += "#{encoded}\n"
      console.scrollTop = console.scrollHeight
    @on 'disconnected', ->
      console.innerHTML = ''

  isConnected: ->
    return @connection != null

  connect: ->
    return if @connection or @connecting

    address = @getAddress()
    if (address.indexOf('#') != -1)
      signaller = address.split('#')[0]
      id = address.split('#')[1]
    else
      signaller = 'https://api.flowhub.io'
      id = address

    options =
      room: id
      debug: true
      channels:
        chat: true
      signaller: signaller
      capture: false
      constraints: false
      expectedLocalStreams: 0

    console.log 'creating peer'
    @peer = RTC options
    @peer.on 'channel:opened:chat', (id, dc) =>
      console.log 'opened'
      @connection = dc
      @connection.onmessage = (data) =>
        console.log 'message', data.data
        @handleMessage data.data
      console.log 'onmessage registered'
      @connecting = false
      @send 'runtime', 'getruntime',
        secret: @definition.secret
      @emit 'status',
        online: true
        label: 'connected'
      @emit 'connected'
      console.log 'connected emitted'
      @flush()

    @peer.on 'channel:closed:chat', (id, dc) =>
      dc.onmessage = null
      @connection = null
      @emit 'status',
        online: false
        label: 'disconnected'
      @emit 'disconnected'

    @connecting = true

  disconnect: ->
    console.log 'disconnect WEBRTC'
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
    @connection = null
    @connecting = false

  handleMessage: (message) =>
    msg = JSON.parse message
    switch msg.protocol
      when 'runtime' then @recvRuntime msg.command, msg.payload
      when 'graph' then @recvGraph msg.command, msg.payload
      when 'network' then @recvNetwork msg.command, msg.payload
      when 'component' then @recvComponent msg.command, msg.payload

  flush: ->
    for item in @buffer
      @send item.protocol, item.command, item.payload
    @buffer = []

module.exports = WebRTCRuntime
