noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Send edges selected by user to runtime'
  c.inPorts.add 'edges',
    datatype: 'array'
    required: yes
  c.inPorts.add 'runtime',
    datatype: 'object'
    required: yes
  c.outPorts.add 'out',
    datatype: 'array'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: 'edges'
    params: 'runtime'
    out: 'out'
    async: true
  , (data, groups, out, callback) ->
    unless c.params.runtime.canDo
      return callback new Error 'Incorrect runtime instance'
    unless c.params.runtime.isConnected()
      # Pass-through since there is no connection
      out.send data
      do callback
      return
    c.params.runtime.sendNetwork 'edges', data
    out.send edges
    do callback
