noflo = require 'noflo'
fbpClient = require 'fbp-protocol-client'

exports.getComponent = ->
  c = new noflo.Component
  c.inPorts.add 'definition',
    datatype: 'object'
    description: 'Runtime definition object'
    required: true
  c.inPorts.add 'element',
    datatype: 'object'
    description: 'DOM element to be set as Runtime parent element'
    required: false
  c.inPorts.add 'timeout',
    datatype: 'number'
    description: 'How long to try connecting, in milliseconds'
    default: 1000
    required: false
    control: true
  c.outPorts.add 'runtime',
    datatype: 'object'
    description: 'FBP Runtime instance'
    required: false
  c.outPorts.add 'connected',
    datatype: 'object'
    description: 'Connected FBP Runtime instance'
    required: false
  c.outPorts.add 'unavailable',
    datatype: 'object'
    description: 'Unavailable FBP Runtime instance'
    required: false
  c.outPorts.add 'error',
    datatype: 'object'
    description: 'Runtime connection error'
    required: false
  c.process = (input, output) ->
    return unless input.hasData 'definition'
    definition = input.getData 'definition'
    unless definition.protocol
      output.done new Error 'Protocol definition required'
      return
    unless definition.address
      output.done new Error 'Address definition required'
      return

    timeout = if input.hasData('timeout') then input.getData('timeout') else 1000
    element = if input.hasData('element') then input.getData('element') else null

    try
      Runtime = fbpClient.getTransport definition.protocol
    catch e
      output.done new Error "Protocol #{definition.protocol} is not supported"
      return

    onError = (e) ->
      clearTimeout timeout if timeout
      rt.removeListener 'capabilities', onCapabilities
      if rt and c.outPorts.unavailable.isAttached()
        output.send
          unavailable: rt
        return
      output.done e
      return

    onTimeout = ->
      output.sendDone
        unavailable: rt
      rt.removeListener 'error', onError
      rt.removeListener 'capabilities', onCapabilities
      rt.disconnect()

    onCapabilities = ->
      clearTimeout timeout if timeout
      rt.removeListener 'error', onError
      output.sendDone
        connected: rt

    rt = new Runtime definition
    rt.setParentElement element if element
    timeout = setTimeout onTimeout, timeout
    rt.once 'capabilities', onCapabilities
    rt.once 'error', onError
    output.send
      runtime: rt
    rt.connect()
