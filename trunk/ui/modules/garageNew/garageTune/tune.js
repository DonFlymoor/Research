angular.module('beamng.garage')

.controller('garageTune', ['$scope', 'logger', 'bngApi', 'VehicleConfig', 'Utils', '$filter', 'RateLimiter', 'StreamsManager', function ($scope, logger, bngApi, VehicleConfig, Utils, $filter, RateLimiter, StreamsManager) {
  var vm = this;

  var streams = ['advancedWheelDebugData'];
  StreamsManager.add(streams);

  vm.liveVariablesUpdate = false;

  bngApi.activeObjectLua('extensions.advancedwheeldebug.registerDebugUser("garageTune", true)');


  $scope.$on('streamsUpdate', (ev, streams) => {
    if (streams.advancedWheelDebugData !== undefined) {
      $scope.$evalAsync(() => {
        vm.advancedWheelDebugData = streams.advancedWheelDebugData;
      });
    }
  });

  $scope.$on('VehicleconfigChange', (event, config) => {
    var tuning = {};
    var categories = [];

    for (var o in config.variables) {
      var v = config.variables[o];
      if (tuning[v.category] === undefined) {
        tuning[v.category] = [];
        categories.push(v.category);
      }
      v.valDis = VehicleConfig.varValToDisVal(v);
      tuning[v.category].push(v);
    }

    for (var o in tuning) {
      tuning[o].sort((a, b) => a.name < b.name);
    }
    categories.sort();

    vm.data = tuning;
    vm.categories = categories;

    logger.log(vm.data);
    logger.log(vm.categories);
  });


  /**
   * @description
   * This is called when some tuning parameter is changed. If liveVariablesUpdate is true
   * it applies the configuration.
   */
  vm.tuningVariablesChanged = function () {
    if (vm.liveVariablesUpdate)
      autoUpdateVariables();
  };

  /**
   * @description
   * Resets configuration variables to the default ones.
   */
  vm.resetVars = function () {
    eachVar((x) => {
      x.val = x.default;
      x.valDis = VehicleConfig.varValToDisVal(x);
    });

    vm.writeVars();
  };

  var autoUpdateVariables = RateLimiter.debounce(() => {
    logger.vehicleconfig.debug(`Writing vehicle configuration (live update)`);
    vm.writeVars();
  }, 1500);

  function eachVar (func) {
    for (var cat in vm.data) {
      for(var tunable in vm.data[cat]) {
        func(vm.data[cat][tunable]);
      }
    }
  }

  vm.writeVars = function () {
    var helper = [];
    eachVar((t) => helper.push(t));

    var vars = VehicleConfig.getVariablesConfig(helper);

    logger.vehicleconfig.debug('Setting configuration vars to', vars);
    bngApi.activeObjectLua(`partmgmt.setConfigVars(${bngApi.serializeToLua(vars)})`);
  };

  vm.addSpacer = (function () {
    var lastCategory;
    return (cat) => {
      var res = cat !== lastCategory;
      lastCategory = cat;
      return res;
    }
  })();

  $scope.$on('$destroy', function () {
  bngApi.activeObjectLua('extensions.advancedwheeldebug.registerDebugUser("garageTune", false)');
    StreamsManager.remove(streams);
  });

  // Initial data load
  bngApi.activeObjectLua('partmgmt.vehicleResetted()');
}]);