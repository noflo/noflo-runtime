noflo = require 'noflo'
connection = require '../src/connection'

exports.getComponent = ->
  c = new noflo.Component
  c.inPorts.add 'graph',
    datatype: 'object'
  c.inPorts.add 'runtime',
    datatype: 'object'
    control: true
  c.outPorts.add 'out',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'

  c.process (input, output) ->
    return unless input.hasData 'graph', 'runtime'
    [graph, runtime] = input.getData 'graph', 'runtime'
    unless runtime.canDo
      output.done new Error 'Incorrect runtime instance'
      return

    if runtime.isConnected()
      connection.sendGraph graph, runtime, (err) ->
        if err
          output.done err
          return
        output.sendDone
          out: graph
      return

    runtime.once 'capabilities', ->
      connection.sendGraph graph, runtime, (err) ->
        if err
          output.done err
          return
        output.sendDone
          out: graph
