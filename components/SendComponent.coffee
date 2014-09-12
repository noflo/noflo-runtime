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
    required: yes
  c.inPorts.add 'runtime',
    datatype: 'object'
    required: yes
  c.outPorts.add 'out',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: 'component'
    params: 'runtime'
    out: 'out'
    async: true
  , (data, groups, out, callback) ->
    unless c.params.runtime.canDo
      return callback new Error 'Incorrect runtime instance'

    if c.params.runtime.isConnected()
      sendComponent data, c.params.runtime, (err) ->
        return callback err if err
        out.send component
        do callback
      return

    c.params.runtime.once 'capabilities', ->
      sendComponent data, c.params.runtime, (err) ->
        return callback err if err
        out.send component
        do callback

  c
