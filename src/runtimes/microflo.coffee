Base = require './base'
microflo = require 'microflo'

parseQueryString = (queryString) ->
  queries = queryString.split "&"
  params = {}
  queries.forEach (query, i) ->
    kv = query.split '='
    params[kv[0]] = kv[1]
  return params

parseAddress = (address) ->
  info =
    type: null
    device: null
    baudrate: "9600"

  if address.indexOf('serial://') == 0
    info.type = 'serial'
  if address.indexOf('simulator://') == 0
    info.type = 'simulator'

  if info.type
    start = address.indexOf('://')+'://'.length
    end = address.indexOf('?')
    end = address.length if end < 0
    d = address.substring start, end
    info.device = d if d

  queryStart = address.indexOf('?')
  if queryStart != -1
    query = address.substring queryStart+1
    params = parseQueryString query
    for k, v of params
      info[k] = v

  return info


# TODO: make this runtime be for every device that supports the same FBCS protocol as MicroFlo
class MicroFloRuntime extends Base
  constructor: (definition) ->
    @connecting = false
    @buffer = []
    @container = null

    # MicroFlo things
    @runtime = null

    @on 'connected', @updatecontainer

    super definition

  isConnected: -> @runtime isnt null

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

  openComm: () ->
    getRuntime = null
    info = parseAddress @getAddress()

    if info.type == 'serial'
      getRuntime = (callback) =>
        microflo.serial.openTransport info.device, parseInt info.baudrate, (err, transport) ->
          return callback err if err
          dev = new microflo.runtime.Runtime transport
          return callback null, dev
    else if info.type == 'simulator'
      getRuntime = (callback) =>
        sim = new microflo.simulator.RuntimeSimulator
        sim.start()
        #sim.device.graph = sim.graph
        return callback null, sim

    getRuntime (err, runtime) =>
      return @emit 'error', err if err

      runtime.on 'message', (response) =>
        @onMessage { data: response }

      runtime.device.open () =>
        @connecting = false
        if err
          console.log 'MicroFlo error:', err
          @emit 'error', err
          return
        @runtime = runtime

        # Perform capability discovery
        @send 'runtime', 'getruntime',
          secret: @definition.secret

        @emit 'status',
          online: true
          label: 'connected'
        @emit 'connected'

        @flush()

  connect: ->
    return if @connecting
    @connecting = true

    transport = runtime?.transport
    @runtime?.stop()
    @runtime = null
    # Make sure serial transport is closed before reopening
    if transport
      transport.close () =>
        @openComm()
    else
      f = () =>
        @openComm()
      setTimeout f, 0

  disconnect: ->

    onClosed = (success) =>
      @runtime = null
      @emit 'status',
        online: false
        label: 'disconnected'
      @emit 'disconnected'

    if @runtime
      @runtime.transport.close onClosed
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

    try
      @runtime.handleMessage msg
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
MicroFloRuntime.parseAddress = parseAddress
