noflo = require 'noflo'
path = require 'path'
fs = require 'fs'
RemoteSubGraph = require '../src/RemoteSubGraph'

registerComponent = (loader, prefix, runtime) ->
  bound = RemoteSubGraph.getComponentForRuntime runtime
  name = runtime.id
  loader.registerComponent prefix, name, bound

module.exports = (loader, done) ->
  # Read runtime definitions from package.json
  packageFile = path.resolve loader.baseDir, 'package.json'

  fs.readFile packageFile, 'utf-8', (err, def) ->
    return done err if err
    try
      packageDef = JSON.parse def
    catch e
      return done e
    runtimes = packageDef.noflo?.runtimes
    return done() unless runtimes

    prefix = loader.getModulePrefix 'runtime'
    for runtime in runtimes
      registerComponent loader, prefix, runtime
    done null
