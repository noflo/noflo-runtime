Base = require './base'

class IframeRuntime extends Base
  constructor: (definition) ->
    @origin = window.location.origin
    @iframe = null
    super definition

  getElement: -> @iframe

  setMain: (graph) ->
    if @graph
      # Unsubscribe from previous main graph
      @graph.removeListener 'changeProperties', @updateIframe

    # Update contents on property changes
    graph.on 'changeProperties', @updateIframe
    super graph

  setParentElement: (parent) ->
    @iframe = document.createElement 'iframe'
    @iframe.setAttribute 'sandbox', 'allow-scripts'
    parent.appendChild @iframe

  connect: ->
    unless @iframe
      throw new Exception 'Unable to connect without a parent element'

    @iframe.addEventListener 'load', @onLoaded, false

    # Let the UI know we're connecting
    @emit 'status',
      online: false
      label: 'connecting'

    # Set the source to the iframe so that it can load
    @iframe.setAttribute 'src', @getAddress()

    # Set an ID for targeting purposes
    @iframe.id = 'preview-iframe'

    # Update iframe contents as needed
    @on 'connected', @updateIframe

    # Start listening for messages from the iframe
    window.addEventListener 'message', @onMessage, false

  updateIframe: =>
    return if !@iframe or !@graph
    env = @graph.properties.environment
    return if !env or !env.content
    @send 'iframe', 'setcontent', env.content

  disconnect: ->
    @iframe.removeEventListener 'load', @onLoaded, false

    # Stop listening to messages
    window.removeEventListener 'message', @onMessage, false

    @emit 'status',
      online: false
      label: 'disconnected'

  # Called every time the iframe has loaded successfully
  onLoaded: =>
    @emit 'status',
      online: true
      label: 'connected'
    @emit 'connected'

  send: (protocol, command, payload) ->
    w = @iframe.contentWindow
    return unless w
    try
      return if w.location.href is 'about:blank'
      if w.location.href.indexOf('chrome-extension://') isnt -1
        throw new Error 'Use * for IFRAME communications in a Chrome app'
    catch e
      # Chrome Apps
      w.postMessage
        protocol: protocol
        command: command
        payload: payload
      , '*'
      return
    w.postMessage
      protocol: protocol
      command: command
      payload: payload
    , w.location.href

  onMessage: (message) =>
    switch message.data.protocol
      when 'graph' then @recvGraph message.data.command, message.data.payload
      when 'network' then @recvNetwork message.data.command, message.data.payload
      when 'component' then @recvComponent message.data.command, message.data.payload

module.exports = IframeRuntime
