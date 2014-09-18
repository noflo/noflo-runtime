Base = require './base'
microflo = require 'microflo'


# TODO: make this runtime be for every device that supports the same FBCS protocol as MicroFlo
class MicroFloRuntime extends Base
  constructor: (definition) ->
    @connecting = false
    @buffer = []
    @container = null
    super definition

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

  connect: ->
    unless @container
      throw new Error 'Unable to connect without a parent element'

    # Make sure serial transport is closed before reopening
    if @getSerial and @getSerial()
      @getSerial().close () ->
        #

    # Let the UI know we're connecting
    @connecting = true
    @emit 'status',
      online: false
      label: 'connecting'

    # Set an ID for targeting purposes
    @container.id = 'preview-container'

    # Update container contents as needed
    @on 'connected', @updatecontainer

    # Setup runtime
    # TODO: remove hardcoding of baudrate and debugLevel
    baudRate = 9600
    debugLevel = 'Error'
    address = @getAddress()
    serialPort = address.replace 'serial://', ''
    @setupRuntime baudRate, serialPort, debugLevel

    # HACK: sends initial message, which hooks up receiving as well
    @onLoaded()

  disconnect: ->
    onClosed = (success) ->
      @emit 'status',
        online: false
        label: 'disconnected'
      @emit 'disconnected'

      if @getSerial and @getSerial()
        @getSerial().close onClosed
      else
        onClosed false

  updatecontainer: =>
    return if !@container or !@graph
    # TEMP

  setupRuntime: (baudRate, serialPort, debugLevel) ->
    @microfloGraph = {}
    # FIXME: nasty and racy, should pass callback and only then continue
    @debugLevel = debugLevel
    @getSerial = null
    try
      @getSerial = microflo.serial.openTransport serialPort, baudRate, (err, transport) ->
        console.log err, transport
    catch e
      console.log 'MicroFlo setup:', e

  # Called every time the container has loaded successfully
  onLoaded: =>
    @connecting = false
    @emit 'status',
      online: true
      label: 'connected'
    @emit 'connected'

    # Perform capability discovery
    @send 'runtime', 'getruntime', null

    @flush()

  send: (protocol, command, payload) ->
    msg =
        protocol: protocol
        command: command
        payload: payload
    if @connecting
      @buffer.push msg
      return

    sendFunc = (response) =>
      console.log 'sendFunc', response
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
