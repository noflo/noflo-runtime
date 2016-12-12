var exported = {
  'noflo': require('noflo'),
  'noflo-runtime': require('./index')
};

if (window) {
  window.require = function (moduleName) {
    if (exported[moduleName]) {
      return exported[moduleName];
    }
    throw new Error('Module ' + moduleName + ' not available');
  };
}

