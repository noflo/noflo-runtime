
isBrowser = () ->
  return !(typeof(process) != 'undefined' && process.execPath && process.execPath.indexOf('node') != -1)
EventEmitter = require('events').EventEmitter

if not isBrowser()
  # Simple compatibility layer between node.js WebSocket client and native browser APIs
  # Respects events: open, close, message, error
  # Note: no data is passed with open and close events
  class NodeWebSocketClient extends EventEmitter
    constructor: (address, protocol) ->
      WebSocketClient = require('websocket').client
      @client = new WebSocketClient # the real client
      @connection = null
  
      @client.on 'connectionFailed', (error) =>
        @emit 'error', error
      @client.on 'connect', (connection) =>
        console.log 'WARNING: multiple connections for one NodeWebSocketClient' if @connection
        @connection = connection
        connection.on 'error', (error) =>
          @connection = null
          @emit 'error', error
        connection.on 'close', () =>
          @connection = null
          @emit 'close'
        connection.on 'message', (message) =>
          message.data = message.utf8Data
          @emit 'message', message

        @emit 'open'

      @client.connect address, protocol

    addEventListener: (event, listener, capture, wantsUntrusted) ->
      @on event, listener
    close: () ->
      @connection.close()
    send: (msg) ->
      @connection.sendUTF msg
    
module.exports =
  isBrowser: isBrowser
  EventEmitter: EventEmitter
  WebSocket: if isBrowser() then window.WebSocket else NodeWebSocketClient
