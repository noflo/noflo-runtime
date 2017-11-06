isBrowser = () ->
  return !(typeof(process) != 'undefined' && process.execPath && process.execPath.indexOf('node') != -1)
EventEmitter = require('events').EventEmitter

WebSocketServer = require('websocket').server
http = require 'http'
path = require 'path'

normalizePorts = (ports) ->
  defaults =
    type: 'any'
    description: ''
    addressable: false
    required: false
  if not ports.length?
    ports = [ ports ]
  normalizePort = (port) ->
    normal = {}
    for k,v of normal
      normal[k] = v
    for k,v of port
      normal[k] = v
    return normal
  return (normalizePort p for p in ports)

# TODO: implement array ports such that each connection gets its own index,
# and that data send on a specific index is only sent to that connection
class PseudoComponent extends EventEmitter
  constructor: () ->
    super()
    @_receiveFunc = null
    @ports =
      inPorts: {}
      outPorts: {}

  inports: (p) ->
    @ports.inPorts = normalizePorts p
    return this
  outports: (p) ->
    @ports.outPorts = normalizePorts p
    return this
  receive: (f) ->
    @receiveFunc = f
    return this

  send: (port, event, index, payload) ->
    @emit 'output', port, event, index, payload
  _receive: (port, event, index, payload) ->
    send = @send.bind @
    @receiveFunc port, event, index, payload, send

class PseudoRuntime extends EventEmitter
  constructor: (httpServer) ->
    super()
    @connections = []
    @wsServer = new WebSocketServer { httpServer: httpServer }
    @wsServer.on 'request', (request) =>
      connection = request.accept 'noflo', request.origin
      @connections.push(connection);
      connection.on 'message', (message) =>
        @handleMessage message, connection
      connection.on 'close', () =>
        if @connections.indexOf(connection) == -1
          return
        @connections.splice @connections.indexOf(connection), 1

  handleMessage: (message, connection) ->
    return if not message.type == 'utf8'
    try
      msg = JSON.parse(message.utf8Data);
    catch e
      return

    if msg.protocol == 'runtime' && msg.command == 'getruntime'
      rt =
        type: 'remote-subgraph-test'
        version: '0.5'
        capabilities: ['protocol:runtime', 'protocol:graph']
      msg = { protocol: 'runtime', command: 'runtime', payload: rt }
      connection.sendUTF JSON.stringify msg
      @sendPorts()
    else if msg.protocol == 'runtime' && msg.command == 'packet'
      @receivePacket msg.payload, connection

  setComponent: (component) ->
    @component = component
    @component.on 'output', (port, event, index, payload) =>
      packet =
        port: port
        event: event
        payload: payload
        index: index
      @sendPacket packet

  receivePacket: (p) ->
    @component._receive p.port, p.event, p.index, p.payload

  sendPacket: (p) -> 
    msg =
      protocol: 'runtime'
      command: 'packet'
      payload: p
    @sendAll msg

  sendPorts: () ->
    msg =
      protocol: 'runtime'
      command: 'ports'
      payload: @component.ports
    @sendAll msg

  sendAll: (msg) ->
    msg = JSON.stringify msg
    for connection in @connections
      connection.sendUTF msg


component = (name) ->
  c = new PseudoComponent name
  return c

Echo = () ->
  c = component('Echo')
    .inports({ id: 'in', description: 'Data to echo' })
    .outports({ id: 'out', description: 'Echoed data' })
    .receive (port, index, event, payload, send) ->
      send 'out', index, event, payload

createServer = (port, callback) ->
  server = new http.Server
  runtime = new PseudoRuntime server
  runtime.setComponent Echo()
  server.listen port, (err) ->
    return callback err, server

createNoFloServer = (port, callback) ->
  runtime = require('noflo-runtime-websocket')
  baseDir = path.join __dirname, '../../'

  server = http.createServer () ->
  options =
    baseDir: baseDir
    captureOutput: false
    catchExceptions: false
    permissions:
      'my-super-secret2s': ['protocol:runtime', 'protocol:graph', 'protocol:network']
      'my-super-secret': ['protocol:runtime', 'protocol:graph']
  rt = runtime server, options
  server.listen port, () ->
    return callback null, server

module.exports =
  Echo: Echo
  Component: PseudoComponent
  Server: PseudoRuntime
  createServer: createServer
  createNoFloServer: createNoFloServer
