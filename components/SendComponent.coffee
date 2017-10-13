noflo = require 'noflo'

sendComponent = (component, runtime, callback) ->
  unless component.code
    return callback new Error "No code available for component #{component.name}"

  # Check for platform-specific components
  runtimeType = component.code.match /@runtime ([a-z\-]+)/
  if runtimeType
    unless runtimeType[1] in ['all', runtime.definition.type]
      return callback new Error "Component type #{runtimeType} doesn't match runtime type #{runtime.definition.type}"

  unless runtime.canDo 'component:setsource'
    return callback new Error 'Runtime doesn\'t support setsource'

  runtime.sendComponent 'source',
    name: component.name
    language: component.language
    library: component.project or component.library
    code: component.code
    tests: component.tests

  do callback

exports.getComponent = ->
  c = new noflo.Component
  c.inPorts.add 'component',
    datatype: 'object'
  c.inPorts.add 'runtime',
    datatype: 'object'
    control: true
  c.outPorts.add 'out',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'

  c.process (input, output) ->
    return unless input.hasData 'component', 'runtime'
    [component, runtime] = input.getData 'component', 'runtime'
    unless runtime.canDo
      output.done new Error 'Incorrect runtime instance'
      return

    if runtime.isConnected()
      sendComponent component, runtime, (err) ->
        if err
          output.done err
          return
        output.sendDone
          out: component
      return

    runtime.once 'capabilities', ->
      sendComponent component, runtime, (err) ->
        if err
          output.done err
          return
        output.sendDone
          out: component
