module.exports = ->
  # Project configuration
  @initConfig
    pkg: @file.readJSON 'package.json'

    # CoffeeScript compilation
    coffee:
      spec:
        options:
          bare: true
          transpile:
            presets: ['es2015']
        expand: true
        cwd: 'spec'
        src: ['**.coffee']
        dest: 'spec'
        ext: '.js'

    # Browser build of NoFlo
    noflo_browser:
      options:
        baseDir: './'
        webpack:
          externals:
            'repl': 'commonjs repl' # somewhere inside coffee-script
            'module': 'commonjs module' # somewhere inside coffee-script
            'child_process': 'commonjs child_process' # somewhere inside coffee-script
            'jison': 'commonjs jison'
            'should': 'commonjs should' # used by tests in octo
            'express': 'commonjs express' # used by tests in octo
            'highlight': 'commonjs highlight' # used by octo?
            'microflo-emscripten': 'commonjs microflo-emscripten' # optional?
            'acorn': 'commonjs acorn' # optional?
          module:
            rules: [
              test: /\.coffee$/
              use: ["coffee-loader"]
            ,
              test: /\.fbp$/
              use: ["fbp-loader"]
            ]
          resolve:
            extensions: [".coffee", ".js"]
          node:
            fs: "empty"
        ignores: [
          /bin\/coffee/
        ]
      main:
        files:
          'browser/noflo-runtime.js': ['entry.webpack.js']

    # Automated recompilation and testing when developing
    watch:
      files: ['spec/*.coffee', 'components/*.coffee']
      tasks: ['test']

    # BDD tests on Node.js
    mochaTest:
      nodejs:
        src: ['spec/*.coffee']
        options:
          reporter: 'spec'

    # BDD tests on browser
    connect:
      server:
        options:
          port: 3000
          #keepalive: true
    mocha_phantomjs:
      options:
        reporter: 'spec'
      all:
        options:
          urls: ['http://127.0.0.1:3000/spec/runner.html']

    # Coding standards
    coffeelint:
      components:
        files:
          src: ['components/*.coffee', 'src/*.coffee', 'src/runtimes/*.coffee']
        options:
          max_line_length:
            value: 80
            level: 'ignore'

  # Grunt plugins used for building
  @loadNpmTasks 'grunt-noflo-browser'
  @loadNpmTasks 'grunt-contrib-coffee'

  # Grunt plugins used for testing
  @loadNpmTasks 'grunt-contrib-watch'
  @loadNpmTasks 'grunt-contrib-connect'
  @loadNpmTasks 'grunt-mocha-test'
  @loadNpmTasks 'grunt-mocha-phantomjs'
  @loadNpmTasks 'grunt-coffeelint'

  # Our local tasks
  @registerTask 'build', 'Build NoFlo for the chosen target platform', (target = 'all') =>
    @task.run 'coffee'
    if target is 'all' or target is 'browser'
      @task.run 'noflo_browser'

  @registerTask 'start_servers', 'Start local WebSocket servers', ->
    done = @async()
    require('coffee-script/register');
    utils = require './spec/utils/utils'
    utils.createServer 3889, (err) =>
      return @fail.fatal err if err
      console.log "Echo server running at port 3889"
      utils.createNoFloServer 3892, (err) =>
        return @fail.fatal err if err
        console.log "NoFlo server running at port 3892"
        done()

  @registerTask 'test', 'Build NoFlo and run automated tests', (target = 'all') =>
    @task.run 'coffeelint'
    @task.run 'build'
    if target is 'all' or target is 'nodejs'
      @task.run 'mochaTest'
    if target is 'all' or target is 'browser'
      @task.run 'connect'
      @task.run 'start_servers'
      @task.run 'mocha_phantomjs'

  @registerTask 'default', ['test']
