angular.module('beamng.stuff')

/**
 * @ngdoc service
 * @name beamng.stuff:VehicleConfig
 *
 * @description
 * Helper functions for editing a vehicle's configuration
 */
.factory('VehicleConfig', ['logger', '$q', 'bngApi', 'Utils', function (logger, $q, bngApi, Utils) {
  var prefix = '';

  var _generateTreeBranch = function (d, des, simple, depth) {
    var res = [];
    depth = depth || 0;

    for (var child in d) {
      var slot = d[child];
      var element = {
        name: des[child].replace(prefix, ''),
        slot: slot[0].partType,
        val: 'none',
        options: [],
        highlight: true
      };
      if(slot[0].coreSlot === undefined) {
        element.options.push({name: 'Empty', val: 'none'});
      } else {
        element.open = true;
      }

      var help = element.options;
      for (var item=0; item<slot.length; item++) {
        help[help.length] = {
          name: slot[item].name.replace('prefix', ''),
          val: slot[item].partName
        };
        if (slot[item].active) {
          element.val = slot[item].partName;
          if (slot[item].parts)
            element.parts = _generateTreeBranch(slot[item].parts, des, simple, depth + 1);
          if (simple && element.parts !== undefined && element.parts.length === 0)
            delete element.parts;
        }
      }
      if (!simple || element.options.length > 2 || (element.options.length > 1 && element.options[0].val !== 'none') || depth < 1) {
        res.push(element);
      }
    }
    return res;
  };

  var _getPrefix = function (des) {
    var strings = [];

    Object.keys(des).map(function (x) { strings.push(des[x]); });

    var max = Math.max.apply(null, strings.map(function (x) { return x.length; }));

    for (var i=0; i<max; i++) {
      for (var key in des) {
        if (des[key].indexOf(prefix) !== 0) {
          return strings[0].substring(0, (i-2));
        }
      }
      prefix = strings[0].substring(0, i);
    }
    return '';
  };

  return {
    get prefix () {
      return prefix;
    },

    generateTree: function (data, simple) {
      prefix = _getPrefix(data.slotDescriptions);
      return _generateTreeBranch(data.slotMap, data.slotDescriptions, simple);
    },

    generateConfig: function (d, res) {
      res = res || {};
      if (!d) return res;

      d.map((x) => {
        res[x.slot] = x.val;
        if (x.parts) this.generateConfig(x.parts, res);
      });

      return res;
    },

    varValToDisVal: function (v) {
      var vData = (v.val - v.min) / (v.max - v.min);
      return Utils.round(vData * (v.maxDis - v.minDis) + v.minDis, v.stepDis);
    },

    getVariablesConfig: function (variables) {
      var configObj = {};
      for (var i in variables) {
        var v = variables[i];
        var vDis = (v.valDis - v.minDis) / (v.maxDis - v.minDis);
        v.val = vDis * (v.max - v.min) + v.min;
        configObj[v.name] = v.val;
      }
      return configObj;
    },

    loadConfigList: function () {
      var d = $q.defer();

      bngApi.activeObjectLua('partmgmt.getConfigList()', (configs) => {
        var list = configs.map((elem) => elem.slice(0, -3));
        d.resolve(list);
      });

      return d.promise;
    },

    treeSort: function _treeSort_ (a, b) {
      if (a.parts) {
        a.parts.sort(_treeSort_);
        if (!b.parts) return 1;
      }

      if (b.parts) {
        b.parts.sort(_treeSort_);
        if (!a.parts) return -1;
      }

      return a.slot.localeCompare(b.slot);
    }
  };

  // return service;
}])
/**
 * @ngdoc controller
 * @name beamng.stuff:VehicleconfigController
 * @description The controller for the Vehicle Config entry. It handles all tabs in the view.
 * @require logger
 * @require $scope
 * @require beamng.stuff:bngApi
 * @require beamng.stuff:VehicleConfig
**/
.controller('VehicleconfigController', ['$filter', 'logger', '$scope', '$window', 'bngApi', 'RateLimiter', 'VehicleConfig', 'StreamsManager',
function ($filter, logger, $scope, $window, bngApi, RateLimiter, VehicleConfig, StreamsManager) {
  var vm = this;

  // Multi Part Highlighting

  // function used to flatten objects
  function processPart (obj, func) {
    func(obj);
    if (obj.parts) {
      obj.parts.forEach(function (parts) {
        processPart(parts, func);
      });
    }
  }

  vm.highlightParts = function(selectedPart) {
    processPart(selectedPart, function (obj) {
      obj.highlight = selectedPart.highlight;
    });

    var flattenedParts = [];
    for (var key in vm.d.data) {
      processPart(vm.d.data[key], function(obj) {
        flattenedParts.push(obj);
      })
    }
    bngApi.activeObjectLua(`partmgmt.highlightParts(${bngApi.serializeToLua(flattenedParts)})`);
  };

  $scope.$on('VehicleFocusChanged', function(event, data) {
    bngApi.activeObjectLua('partmgmt.vehicleResetted()');
  })

  // LICENSE PLATE STUFF
  vm.licensePlate = '';
  
  bngApi.engineLua('getVehicleLicenseName()', function (str) {
    $scope.$evalAsync(() => { vm.licensePlate = str; });
  });

  vm.updateLicensePlate = function () {
    bngApi.engineLua(`setPlateText("${vm.licensePlate}")`);
  };
  // --------------

  vm.stopPropagation = function(event) {
    event.stopPropagation();
  };

  vm.open = {};
  vm.openRuntime = {};
  vm.d = {};
  vm.configList = [];
  vm.stickyPartSelection = false;
  vm.selectSubParts = true;
  vm.simple = false;
  vm.liveVariablesUpdate = false;

  var initConfig = null
    , loadedConfig = null
    , init = true
  ;

  // var loadOpenSlots = function () {
  //   var open = JSON.parse(window.sessionStorage.getItem(`vehicleconfigOpenSlots${VehicleConfig.prefix}`));
  //   if (open) {
  //     vm.openRuntime = (vm.open = open);
  //   }
  // };

  // var saveOpenSlots = function () {
  //   window.sessionStorage.setItem(`vehicleconfigOpenSlots${VehicleConfig.prefix}`, JSON.stringify(vm.openRuntime));
  // };

  var autoUpdateVariables = RateLimiter.debounce(() => {
    logger.vehicleconfig.debug(`Writing vehicle configuration (live update)`);
    vm.write();
  }, 1500);

  vm.openRepo = function () {
    window.location.href = 'http-external://www.beamng.com/resources/categories/mods-and-skins.7/?ingame=2';
  };

  vm.emptyFront = function (option) {
    if (option.name === 'Empty') {
      return 0;
    }
  };

  /**
   * @ngdoc method
   * @name toggleOpenSlot
   * @methodOf beamng.stuff:VehicleconfigController
   * @param {string} section <TODO>
   *
   * @description <TODO>
   */
  vm.toggleOpenSlot = function (section) {
    if (vm.openRuntime[section])
      vm.openRuntime[section] = !vm.openRuntime[section];
    else
      vm.openRuntime[section] = true;

    // saveOpenSlots();
  };

  /**
   * @ngdoc method
   * @name selectPart
   * @methodOf beamng.stuff:VehicleconfigController
   * @param {string} element <TODO>
   *
   * @description <TODO>
   */
  vm.selectPart = function (event, element) {
    event.stopPropagation();
    logger.vehicleconfig.debug(`Selecting part ${element} (subparts: ${vm.selectSubParts})`);
    bngApi.activeObjectLua(`partmgmt.selectPart("${element}", ${vm.selectSubParts})`);
  };

  /**
   * @ngdoc method
   * @name deselectPart
   * @methodOf beamng.stuff:VehicleconfigController
   * @param {boolean} sticky the stickypartselection state
   *
   * @description
   * De-selects currently selected vehicle part. It is triggered when
   * user hovers out of the part's div in the Parts tree, if stickyPartSelection is false
   */
  vm.deselectPart = function (sticky) {

    var flattenedParts = [];
    if (vm.d.data.length > 0) {
      for (var key in vm.d.data) {
        processPart(vm.d.data[key], function(obj) {
          flattenedParts.push(obj);
        })
      }
      logger.vehicleconfig.debug(`Reset part selection`);
      // bngApi.activeObjectLua('partmgmt.selectReset()');
      bngApi.activeObjectLua(`partmgmt.highlightParts(${bngApi.serializeToLua(flattenedParts)})`);
    }
  };

  vm.addSpacer = (function () {
    var lastCategory;
    return (cat) => {
      var res = cat !== lastCategory;
      lastCategory = cat;
      return res;
    }
  })();

  /**
   * @ngdoc method
   * @name write
   * @methodOf beamng.stuff:VehicleconfigController
   *
   * @description
   * Applies the modified configuration to active vehicle.
   */
  vm.write = function () {
    var newConfig = VehicleConfig.generateConfig(vm.d.data);
    var data = {
      parts: newConfig,
      vars: VehicleConfig.getVariablesConfig(vm.d.variables)
    };

    logger.vehicleconfig.debug(`Setting configuration`, data);
    bngApi.activeObjectLua(`partmgmt.setConfig(${bngApi.serializeToLua(data)})`);
  };

  /**
   * @ngdoc method
   * @name reset
   * @methodOf beamng.stuff:VehicleconfigController
   *
   * @description
   * Resets configuration to the initial values.
   */
  vm.reset = function () {
    if (loadedConfig && typeof(loadedConfig) == 'string') {
      logger.vehicleconfig.debug(`Resetting to loaded configuration`, data);
      vm.load(loadedConfig);
    } else {
      var data = {
        parts: initConfig,
        vars: VehicleConfig.getVariablesConfig(vm.d.variables)
      };
      bngApi.activeObjectLua(`partmgmt.setConfig(${bngApi.serializeToLua(data)})`);
    }
  };

  /**
   * @ngdoc method
   * @name tuningVariablesChanged
   * @methodOf beamng.stuff:VehicleconfigController
   *
   * @description
   * This is called when some tuning parameter is changed. If liveVariablesUpdate is true
   * it applies the configuration.
   */
  vm.tuningVariablesChanged = function () {
    if (vm.liveVariablesUpdate)
      autoUpdateVariables();
  };

  /**
   * @ngdoc method
   * @name resetVars
   * @methodOf beamng.stuff:VehicleconfigController
   *
   * @description
   * Resets configuration variables to the default ones.
   */
  vm.resetVars = function () {
    vm.d.variables.forEach((x) => {
      x.val = x.default;
      x.valDis = VehicleConfig.varValToDisVal(x);
    });
    vm.tuningVariablesChanged(); // got to call this, since the change didn't come from the inputs.
  };

  /**
   * @ngdoc method
   * @name updateColor
   * @methodOf beamng.stuff:VehicleconfigController
   *
   * @description ????
   */
  vm.updateColor = function (index, value) {
    // console.log( `setVehicleColorPalette(${index-1}, "${value}");` );
    // console.log('setVehicleColorPalette(' + (index-1) + ',"' + value + '");')
    // console.log( `changeVehicleColor("${value}");` );
    // console.log('changeVehicleColor("' + value  + '");');

    if (index === 0) {
      bngApi.engineScript(`changeVehicleColor("${value}");`);
    } else {
      bngApi.engineScript(`setVehicleColorPalette(${index-1}, "${value}");`);
    }
  };

  /**
   * @ngdoc method
   * @name save
   * @methodOf beamng.stuff:VehicleconfigController
   *
   * @description
   * Saves current configuration to a file.
   */
  vm.save = function (configName) {
    bngApi.activeObjectLua(`partmgmt.saveLocal("${configName}.pc")`);
  };

  /**
   * @ngdoc method
   * @name load
   * @methodOf beamng.stuff:VehicleconfigController
   *
   * @description
   * Loads an available configuration from a file.
   */
  vm.load = function ($event, config) {
    loadedConfig = config;
    bngApi.activeObjectLua(`partmgmt.loadLocal("${config}.pc")`);
    $event.stopPropagation();
  };

  /**
   * @ngdoc method
   * @name toggleAdvancedWheelDebug
   * @methodOf beamng.stuff:VehicleconfigController
   * @param {boolean} state The state to set advancedwheeldebug module
   *
   * @description
   * Loads/Unloads the advancedwheeldebug module for the current vehicle.
   * When loaded, this module emits messages through "AdvancedWheelDebugData" event
   * in a very high rate, so enable it only when needed!
   */
  vm.toggleAdvancedWheelDebug = function (state) {
    bngApi.activeObjectLua('extensions.advancedwheeldebug.registerDebugUser("tuningmenu",' + state + ')');
  };

  function calcTree (config) {
    $scope.$evalAsync(function () {
      if (init) {
        init = false;
        initConfig = config;
      }

      var tree = VehicleConfig.generateTree(config, vm.simple);
      tree.sort(VehicleConfig.treeSort);
      var configArray = [];
      var variable_categories = {};

      for (var o in config.variables) {
        var v = config.variables[o];
        if (!variable_categories[v.category])
          variable_categories[v.category] = true;
        v.valDis = VehicleConfig.varValToDisVal(v);
        configArray.push(v);
      }

      vm.d.data = tree;
      vm.d.variables = $filter('orderBy')(configArray, 'name');
      vm.d.variable_categories = Object.keys(variable_categories);
      // loadOpenSlots();
    });
  }

  vm.recalcTree = function () {
    calcTree(initConfig);
  };

  $scope.$on('VehicleconfigChange', (event, config) => calcTree(config));

  $scope.$on('streamsUpdate', (ev, streams) => {
    if (streams.advancedWheelDebugData !== undefined) {
      $scope.$evalAsync(() => {
        vm.d.advancedWheelDebugData = streams.advancedWheelDebugData;
      });
    }
  });

  var streams = ['advancedWheelDebugData'];
  StreamsManager.add(streams);

  $scope.$on('VehicleChange', (event, data) => {
    VehicleConfig.loadConfigList().then((list) => {
      $scope.$evalAsync(() => { vm.configList = list; });
    });
    $scope.$emit('VehicleChangeColor'); // The event will be captured from this controller.
  });

  $scope.$on('VehicleconfigSaved', (event, data) => {
    VehicleConfig.loadConfigList().then((list) => {
      $scope.$evalAsync(() => { vm.configList = list; });
    });
  });

  $scope.$on('VehicleChangeColor', (event, data) => {
    vm.color = ['White', 'White', 'White'];

    bngApi.engineLua('beamng_cef.getVehicleColor()', (res) => {
      vm.color[0] = res || vm.color[0];
    });

    for (var i=1; i<vm.color.length; i++) {
      // yes this is needed, since otherwise we crate a function inside the for loop and thanks to clojure i would always be 4
      bngApi.engineScript(`getVehicleColorPalette(${i-1});`, ((id) =>
        (res) => {
          vm.color[id] = res || vm.color[id];
        }
      )(i));
    }
  });

  vm.carColorPresets = {};

  function getVehicleColors () {
    bngApi.engineLua('core_vehicles.getCurrentVehicleDetails()', (data) => {
      if (data.model !== undefined && data.model.colors !== undefined) {
        $scope.$apply(() => {
          vm.carColorPresets = data.model.colors;
        });
      }
    }); 
  }

  getVehicleColors();

  $scope.$on('VehicleChange', getVehicleColors);


  $scope.$on('$destroy', () => {
    vm.toggleAdvancedWheelDebug(false);
    vm.deselectPart(false);
    StreamsManager.remove(streams);
  });

  // Initial data load
  bngApi.activeObjectLua('partmgmt.vehicleResetted()');
  $scope.$emit('VehicleChange'); // The event will be captured from this controller.


  // The tabs' arrows don't show at first. Probably due to an angular-material bug
  // (e.g. issues #1464 and #3577). However, a window resize triggers them back,
  // so we just mock one.
  // setTimeout(() => {
  //   var evt = document.createEvent('Event');
  //   evt.initEvent('resize', true, true);
  //   $window.dispatchEvent(evt);
  // }, 0);

}]);
