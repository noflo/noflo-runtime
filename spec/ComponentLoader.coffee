noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai' unless chai
  ComponentLoader = require '../src/ComponentLoader'
  RemoteSubGraph = require '../src/RemoteSubGraph'
else
  ComponentLoader = require 'noflo-runtime/src/ComponentLoader'
  RemoteSubGraph = require 'noflo-runtime/src/RemoteSubGraph'

describe 'ComponentLoader', ->

  it 'should export a function', ->
    chai.expect(ComponentLoader).to.be.a 'function'

  describe 'runtimes specified in project file', ->
    baseDir = if noflo.isBrowser() then '/noflo-runtime/spec/data' else require('path').resolve __dirname, './data/'
    names = null
    loader = new noflo.ComponentLoader baseDir
    compName = 'runtime/2ef763ff-1f28-49b8-b58f-5c6a5c54af2d'
    it 'should be listed', (done) ->
        @timeout 5000
        loader.listComponents () ->
            # initialized
            ComponentLoader loader, (err) ->
                chai.expect(err).to.equal null
                loader.listComponents (err, components) ->
                    if not components
                        # NoFlo <0.6 compat
                        components = err
                        err = null
                    names = Object.keys(components).filter (c) -> return c.indexOf('runtime/') == 0
                    chai.expect(names).to.have.length 1
                    chai.expect(names[0]).to.equal compName
                    done()
    it 'should be a RemoteSubGraph', ->
        component = loader.load compName, (err, instance) ->
            chai.expect(err).to.equal null
            chai.expect(instance).to.not.equal null
            chai.expect(instance).to.be.instanceOf RemoteSubGraph.RemoteSubGraph
