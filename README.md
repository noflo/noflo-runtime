# noflo-runtime [![Build Status](https://secure.travis-ci.org/noflo/noflo-runtime.png?branch=master)](http://travis-ci.org/noflo/noflo-runtime)

FBP Runtime handling components for NoFlo

A thin wrapper around [flowbased/fbp-protocol-client](https://github.com/flowbased/fbp-protocol-client)

## Changes

* 0.6.1 (November 17 2017)
  - We now longer attempt to fetch `component.json` via AJAX to determine runtimes. Make it available via `require()` if you need RemoteSubgraphs in browser builds
  - Made RemoteSubgraph connection errors throw
  - Dropped direct MicroFlo connection (serial port) support. Start a microflo runtime separately a connect to it via WebSockets
