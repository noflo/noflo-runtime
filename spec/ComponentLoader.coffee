noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai' unless chai
  rt = require '../index'
else
  rt = require 'noflo-runtime'

ComponentLoader = rt.ComponentLoader
RemoteSubGraph = rt.RemoteSubGraph

describe 'ComponentLoader', ->

  it 'should export a function', ->
    chai.expect(ComponentLoader).to.be.a 'function'

  describe 'runtimes specified in project file', ->
    baseDir = if noflo.isBrowser() then '/spec/data' else require('path').resolve __dirname, './data/'
    names = null
    loader = new noflo.ComponentLoader baseDir
    compName = 'runtime/2ef763ff-1f28-49b8-b58f-5c6a5c54af2d'
    it 'should be listed', (done) ->
        @timeout 5000
        loader.listComponents (err) ->
            return done err if err
            # initialized
            ComponentLoader loader, (err) ->
                return done err if err
                loader.listComponents (err, components) ->
                    return done err if err
                    names = Object.keys(components).filter (c) -> return c.indexOf('runtime/') == 0
                    chai.expect(names.length).to.be.at.least 1
                    namesMatching = names.filter (n) -> n is compName
                    chai.expect(namesMatching.length).to.equal 1
                    done()
        return
    it 'should be a RemoteSubGraph', (done) ->
        component = loader.load compName, (err, instance) ->
            return done err if err
            chai.expect(instance).to.not.equal null
            chai.expect(instance).to.be.instanceOf RemoteSubGraph.RemoteSubGraph
            done()
