noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Listen to a network on a runtime'
  c.inPorts.add 'runtime',
    datatype: 'object'
    description: 'Runtime to listen from'
  c.inPorts.add 'graph',
    datatype: 'object'
    description: 'Graph to listen to'
  c.outPorts.add 'started',
    datatype: 'object'
  c.outPorts.add 'stopped',
    datatype: 'object'
  c.outPorts.add 'status',
    datatype: 'object'
  c.outPorts.add 'output',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'
  c.outPorts.add 'processerror',
    datatype: 'object'
  c.outPorts.add 'icon',
    datatype: 'object'
  c.outPorts.add 'packet',
    datatype: 'object'

  unsubscribe = (runtime) ->
    return unless runtime
    runtime.rt.removeListener 'network', runtime.listener
    runtime.ctx.deactivate()

  c.tearDown = (callback) ->
    unsubscribe c.runtime if c.runtime
    c.runtime = null
    c.graph = null
    do callback

  c.process (input, output, context) ->
    if input.hasData 'graph'
      # Updating the graph context to follow
      c.graph = input.getData 'graph'
      output.done()
      return
    if input.hasData 'runtime'
      unsubscribe c.runtime if c.runtime
      c.runtime =
        rt: input.getData 'runtime'
        ctx: context
        listener: ({command, payload}) ->
          if command is 'error'
            output.send
              error: payload
            return

          if payload.graph isnt c.graph?.name and payload.graph isnt c.graph?.properties?.id
            # For non-errors we're not interested in events
            # affecting other networks than the current one
            return

          if command in ['connect', 'begingroup', 'data', 'endgroup', 'disconnect']
            # Special handling for packets
            output.send
              packet: new noflo.IP 'data',
                edge: payload.id
                src: payload.src
                tgt: payload.tgt
                type: command
                group: if payload.group? then payload.group else ''
                data: if payload.data? then payload.data else ''
                subgraph: if payload.subgraph? then payload.subgraph else ''
                runtime: c.runtime.rt.definition.id
            return

          return unless command in ['started', 'stopped', 'status', 'output', 'processerror', 'icon']
          # Other supported runtime events, send to appropriate port
          result = {}
          result[command] = payload
          output.send result
          return

      c.runtime.rt.on 'network', c.runtime.listener
      return
