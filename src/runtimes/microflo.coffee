Base = require './base'
microflo = require 'microflo'


# TODO: make this runtime be for every device that supports the same FBCS protocol as MicroFlo
class MicroFloRuntime extends Base
  constructor: (definition) ->
    @connecting = false
    @buffer = []
    @container = null

    # MicroFlo things
    @transport = null
    @microfloGraph = null
    @debugLevel = 'Error'

    @on 'connected', @updatecontainer

    super definition

  isConnected: -> @transport isnt null

  getElement: -> @container

  setParentElement: (parent) ->
    @container = document.createElement 'container'
    parent.appendChild @container

  setMain: (graph) ->
    if @graph
      # Unsubscribe from previous main graph
      @graph.removeListener 'changeProperties', @updatecontainer

    # Update contents on property changes
    graph.on 'changeProperties', @updatecontainer
    super graph

  openComm: (serialPort, baudRate) ->
      microflo.serial.openTransport serialPort, baudRate, (err, transport) =>
        @connecting = false
        if err
          console.log 'MicroFlo error:', err
          @emit 'error', err
          return
        @transport = transport

        # Perform capability discovery
        @send 'runtime', 'getruntime', null

        @emit 'status',
          online: true
          label: 'connected'
        @emit 'connected'

        @flush()

  connect: ->
    return if @connecting
    @connecting = true
    @microfloGraph = {}

    # TODO: remove hardcoding of baudrate and debugLevel
    baudRate = 9600
    serialPort = @getAddress().replace 'serial://', ''

    # Make sure serial transport is closed before reopening
    if @transport
      @transport.close () =>
        @transport = null
        @openComm serialPort, baudRate
    else
        f = () =>
          @openComm serialPort, baudRate
        setTimeout f, 0

  disconnect: ->
    onClosed = (success) ->
      @emit 'status',
        online: false
        label: 'disconnected'
      @emit 'disconnected'

      if @transport
        @transport.close onClosed
      else
        onClosed false

  updatecontainer: =>
    return unless @container
    # Set an ID for targeting purposes
    @container.id = 'preview-container'

  send: (protocol, command, payload) ->
    msg =
        protocol: protocol
        command: command
        payload: payload
    if @connecting
      @buffer.push msg
      return

    console.log 'MicroFlo send:', msg
    sendFunc = (response) =>
      console.log 'MicroFlo receive:', response
      @onMessage { data: response }
    conn = { send: sendFunc }
    try
      microflo.runtime.handleMessage msg, conn, @microfloGraph, @getSerial, @debugLevel
    catch e
      console.log e.stack
      console.log e

  onMessage: (message) =>
    switch message.data.protocol
      when 'runtime' then @recvRuntime message.data.command, message.data.payload
      when 'graph' then @recvGraph message.data.command, message.data.payload
      when 'network' then @recvNetwork message.data.command, message.data.payload
      when 'component' then @recvComponent message.data.command, message.data.payload

  flush: ->
    for item in @buffer
      @send item.protocol, item.command, item.payload
    @buffer = []

module.exports = MicroFloRuntime
