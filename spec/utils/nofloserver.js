require('coffee-script/register');
var utils = require('./utils');
var port = parseInt(process.argv[2]);
utils.createNoFloServer(port, function(err, server) {
  console.log("NoFlo server running on " + port);
});
