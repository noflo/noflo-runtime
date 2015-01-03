noflo = require 'noflo'
RemoteSubGraph = require '../src/RemoteSubGraph'

if noflo.isBrowser()
else
  path = require 'path'
  fs = require 'fs'

registerComponent = (loader, prefix, runtime) ->
  bound = RemoteSubGraph.getComponentForRuntime runtime, loader.baseDir
  name = runtime.id
  loader.registerComponent prefix, name, bound

getRuntimesNode = (baseDir, callback) ->
  # Read runtime definitions from package.json
  packageFile = path.resolve baseDir, 'package.json'

  fs.readFile packageFile, 'utf-8', (err, def) ->
    return callback err if err
    try
      packageDef = JSON.parse def
    catch e
      return callback e
    runtimes = []
    runtimes = packageDef.noflo.runtimes if packageDef.noflo?.runtimes?
    return callback null, runtimes

getRuntimesBrowser = (baseDir, callback) ->
  # Read runtime definitions from component.json
  p = baseDir+'/component.json'
  try
    packageDef = require(p)
  catch e
    return callback e, null
  runtimes = []
  runtimes = packageDef.noflo.runtimes if packageDef.noflo?.runtimes?
  return callback null, runtimes

module.exports = (loader, done) ->
  getRuntimes = if noflo.isBrowser() then getRuntimesBrowser else getRuntimesNode
  getRuntimes loader.baseDir, (err, runtimes) ->
    return done err if err
    prefix = loader.getModulePrefix 'runtime'
    for runtime in runtimes
      registerComponent loader, prefix, runtime
    return done null
