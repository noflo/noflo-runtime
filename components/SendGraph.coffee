noflo = require 'noflo'

if noflo.isBrowser()
  connection = require '../src/connection'
else
  connection = require '../src/connection'

exports.getComponent = ->
  c = new noflo.Component
  c.inPorts.add 'graph',
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
    in: 'graph'
    params: 'runtime'
    out: 'out'
    async: true
  , (data, groups, out, callback) ->
    unless c.params.runtime.canDo
      return callback new Error 'Incorrect runtime instance'

    if c.params.runtime.isConnected()
      connection.sendGraph data, c.params.runtime, (err) ->
        return callback err if err
        out.send data
        do callback
      return

    c.params.runtime.once 'capabilities', ->
      connection.sendGraph data, c.params.runtime, (err) ->
        return callback err if err
        out.send data
        do callback

  c
