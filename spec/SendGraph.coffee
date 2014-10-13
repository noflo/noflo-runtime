noflo = require 'noflo'
chai = require 'chai' unless chai
SendGraph = require '../components/SendGraph.coffee'

describe 'SendGraph component', ->
  c = null
  url = null
  beforeEach ->
    c = SendGraph.getComponent()
    out = noflo.internalSocket.createSocket()
    c.outPorts.out.attach out

  describe 'when instantiated', ->
    it 'should have a "graph" inport', ->
      chai.expect(c.inPorts.graph).to.be.an 'object'
    it 'should have a "runtime" inport', ->
      chai.expect(c.inPorts.runtime).to.be.an 'object'
    it 'should have a "out" outport', ->
      chai.expect(c.outPorts.out).to.be.an 'object'
    it 'should have a "error" outport', ->
      chai.expect(c.outPorts.error).to.be.an 'object'
