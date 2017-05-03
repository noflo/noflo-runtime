noflo = require 'noflo'
fbpClient = require 'fbp-protocol-client'

class ConnectRuntime extends noflo.Component
  constructor: ->
    @element = null
    @timeout = 1000
    @inPorts = new noflo.InPorts
      definition:
        datatype: 'object'
        description: 'Runtime definition object'
        required: true
      element:
        datatype: 'object'
        description: 'DOM element to be set as Runtime parent element'
        required: false
      timeout:
        datatype: 'number'
        description: 'How long to try connecting, in milliseconds'
        default: 1000
        required: false
    @outPorts = new noflo.OutPorts
      runtime:
        datatype: 'object'
        description: 'FBP Runtime instance'
        required: false
      connected:
        datatype: 'object'
        description: 'Connected FBP Runtime instance'
        required: false
      unavailable:
        datatype: 'object'
        description: 'Unavailable FBP Runtime instance'
        required: false
      error:
        datatype: 'object'
        description: 'Runtime connection error'
        required: false

    @inPorts.on 'definition', 'data', (data) =>
      @connect data
    @inPorts.on 'element', 'data', (@element) =>
    @inPorts.on 'timeout', 'data', (@timeout) =>

  validate: (definition) ->
    unless definition.protocol
      @outPorts.error.send new Error 'Protocol definition required'
      @outPorts.error.disconnect()
      return false
    unless definition.address
      @outPorts.error.send new Error 'Address definition required'
      @outPorts.error.disconnect()
      return false
    true

  connect: (definition) ->
    return unless @validate definition

    try
      Runtime = fbpClient.getTransport definition.protocol
    catch e
      @outPorts.error.send new Error "Protocol #{definition.protocol} is not supported"
      @outPorts.error.disconnect()
      return

    onError = (e) =>
      clearTimeout timeout if timeout
      rt.removeListener 'capabilities', onCapabilities
      if rt and @outPorts.unavailable.isAttached()
        @outPorts.unavailable.beginGroup definition.id
        @outPorts.unavailable.send rt
        @outPorts.unavailable.endGroup()
        @outPorts.unavailable.disconnect()
        return
      @outPorts.error.send e
      @outPorts.error.disconnect()
      return

    onTimeout = =>
      @outPorts.unavailable.beginGroup definition.id
      @outPorts.unavailable.send rt
      @outPorts.unavailable.endGroup()
      @outPorts.unavailable.disconnect()
      rt.removeListener 'error', onError
      rt.removeListener 'capabilities', onCapabilities
      rt.disconnect()

    onCapabilities = =>
      clearTimeout timeout if timeout
      rt.removeListener 'error', onError
      @outPorts.connected.beginGroup definition.id
      @outPorts.connected.send rt
      @outPorts.connected.endGroup()
      @outPorts.connected.disconnect()

    rt = new Runtime definition
    rt.setParentElement @element if @element
    timeout = setTimeout onTimeout, @timeout
    rt.once 'capabilities', onCapabilities
    rt.once 'error', onError
    @outPorts.runtime.beginGroup definition.id
    @outPorts.runtime.send rt
    @outPorts.runtime.endGroup()
    @outPorts.runtime.disconnect()
    rt.connect()

exports.getComponent = -> new ConnectRuntime
