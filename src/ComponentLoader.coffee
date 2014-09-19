noflo = require 'noflo'
path = require 'path'
fs = require 'fs'
RemoteSubGraph = require '../src/RemoteSubGraph'

registerComponent = (loader, prefix, runtime) ->
  bound = RemoteSubGraph.getComponentForRuntime runtime
  name = runtime.id
  loader.registerComponent prefix, name, bound

module.exports = (loader, done) ->
  # Read MicroFlo graph definitions from fbp.json
  packageFile = path.resolve loader.baseDir, 'fbp.json'
  fs.readFile packageFile, 'utf-8', (err, def) ->
    return done() if err
    try
      packageDef = JSON.parse def
    catch e
      return
    return done() unless packageDef.runtimes

    prefix = loader.getModulePrefix 'runtime'
    for runtime in packageDef.runtimes
      registerComponent loader, prefix, runtime
    done()
