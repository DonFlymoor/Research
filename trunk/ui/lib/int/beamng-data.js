angular.module('beamng.data', ['beamng.core'])

.factory('InstalledContent', ['$rootScope', 'AppSelectFilters', 'bngApi', function ($rootScope, AppSelectFilters, bngApi) {
  var _levels = []
    , _allLevels = []
    , _scenarios = []
    , _vehicles = { list: [], models: [], configs: [], filters: {}}
    , _campaigns = []
    , _apps = []
  ;

  // Listeners
  $rootScope.$on('InstalledContentUpdate', (_, data) => {
    switch (data.context) {
      case 'apps':
        _apps = data.list;

        // Populate apps' filters
        data.list.forEach(app => {
          app.types.forEach(type => {
            if (!(type in AppSelectFilters.types))
              AppSelectFilters.types[type] = true;
          });
        });

        break;

      case 'levels':
        _levels = data.list.map((x, i) => angular.extend(x, { __index__: i }));
        break;
      
      case 'allLevels':
        _allLevels = data.list.map((x, i) => angular.extend(x, { __index__: i }));
        break;

      default:
        break;
    }
  });

  // -- on init --
  bngApi.engineLua('core_levels.requestData()');
  bngApi.engineLua('ui_apps.requestData()');

  return {
    // levels: _levels,
    get levels() { return _levels; },
    get allLevels() { return _allLevels; },
    scenarios: _scenarios,
    campaigns: _campaigns,
    get apps() { return _apps; }
  };
}])



.constant('EnvironmentPresets', {
  gravity: [
    { title: 'ui.environment.zeroGravity',   value: 0.0    },
    { title: 'ui.environment.earth',         value: -9.81  },
    { title: 'ui.environment.moon',          value: -1.62  },
    { title: 'ui.environment.mars',          value: -3.71  },
    { title: 'ui.environment.sun',           value: -274   },
    { title: 'ui.environment.jupiter',       value: -24.92 },
    { title: 'ui.environment.neptune',       value: -11.15 },
    { title: 'ui.environment.saturn',        value: -10.44 },
    { title: 'ui.environment.uranus',        value: -8.87  },
    { title: 'ui.environment.venus',         value: -8.87  },
    { title: 'ui.environment.mercury',       value: -3.7   },
    { title: 'ui.environment.pluto',         value: -0.58  },
    { title: 'ui.environment.negativeEarth', value: 9.81   }
  ],

  simSpeed: [
    { title: 'ui.environment.realtime', value: 1 },
    { title: '2x',   value: 2 },
    { title: '4x',   value: 4 },
    { title: '10x',  value: 10 },
    { title: '100x', value: 100 }
  ]
})


.factory('Environment', ['$rootScope', 'bngApi', 'RateLimiter', function ($rootScope, bngApi, RateLimiter) {

  var _registeredScopes = {};

  var _updateRegisteredScopes = () => {
    Object.keys(_registeredScopes).forEach((x) => {
      _registeredScopes[x].call(null);
    });
  };

  /**
   * @prop time {float} Current time of day in range [0, 1].
   * @prop dayScale {float}  How fast time passes in day
   * @prop nightScale {float} Same as dayScale for night
   * @prop play {boolean} Whether time changes
   * @prop fogDensity {float}
   * @prop cloudCover {float}
   * @prop gravity {float}
   * @prop windSpeed {float}
   *
   * @note Check file game:/lua/ge/extensions/core/environment.lua
   */
  var _state = {};

  // Current simulation speed
  var _bulletTime;

  // This triggers an "EnvironmentStateUpdate" event. The calls are
  // debounced since they might occur in a very high rate.
  var _requestEnvironmentState = RateLimiter.debounce(function () {
    bngApi.engineLua('core_environment.requestState()');
  }, 300, false);

  // This triggers a "BullettimeValueChanged" event. The calls are
  // debounced since they might occur in a very high rate.
  var _requestSimulationSpeed = RateLimiter.debounce(function () {
    bngApi.engineLua('bullettime.requestValue()');
  }, 30, false);

  // Update the stored state and the registered scopes.
  var _updateState = (data) => {
    _state = data;
    if (typeof data.time !== 'number') _state.time = -1;

    if (data.play && _timeWatcher === null) {
      _timeWatcher = _watchTime();
    } else if (!data.play && _timeWatcher !== null) {
      clearInterval(_timeWatcher);
      _timeWatcher = null;
    }

    _updateRegisteredScopes();
  };

  // Poll to get time changes
  var _watchTime = function () {
    return setInterval(function () {
      bngApi.engineLua('core_environment.getTimeOfDay()', (timeObj) => {
        _state.time = timeObj.time;
        _updateRegisteredScopes();
      });
    }, 200);
  };

  // Interval id for time changes poll
  var _timeWatcher = null;

  $rootScope.$on('EnvironmentStateUpdate', (_, data) => { _updateState(data); });

  $rootScope.$on('BullettimeValueChanged', (_, value) => {
    _bulletTime = 1/value;
    _updateRegisteredScopes();
  });

  var _update = () => {
    bngApi.engineLua('core_environment.requestState()');
    bngApi.engineLua('bullettime.requestValue()');
  }

  // Get initial state
  _update();


  return {
    update: _update,
    get state() { return _state; },
    get simSpeed() { return _bulletTime; },

    submitState: (stateObj) => {
      bngApi.engineLua(`core_environment.setState(${bngApi.serializeToLua(stateObj || _state)})`);
      _requestEnvironmentState();
    },

    setSimSpeed: (x) => {
      bngApi.engineLua(`bullettime.set(${x || 1/_bulletTime})`);
      _requestSimulationSpeed();
    },

    registerScope: (scope, updateFn) => {
      _registeredScopes[scope.$id] = updateFn;
      scope.$on('$destroy', () => { delete _registeredScopes[scope.$id]; });
    }
  };
}])



.factory('Debug', ['$log', '$rootScope', 'bngApi', 'RateLimiter', function ($log, $rootScope, bngApi, RateLimiter) {
  var _registeredScopes = {};
  var _lastVisualizationMode = null;

  var _updateRegisteredScopes = () => {
    for (scopeId in _registeredScopes)
      _registeredScopes[scopeId]();
  };

  var _state = {};

  var _update = () => {
    bngApi.engineScript('$Camera::movementSpeed', (speed) => {
      service.cameraSpeed = Number(speed);
      bngApi.activeObjectLua('bdebug.requestState()');
    });
  };

  var _applyState = () => {
    bngApi.activeObjectLua(`bdebug.setState( ${bngApi.serializeToLua(_state)} )`);
  };

  $rootScope.$on('BdebugUpdate', (_, debugState) => {
    _state = debugState;
    _lastVisualizationMode = debugState.renderer.visualization;
    _updateRegisteredScopes();
  });

  $rootScope.$on('updatePhysicsState',  (_, state) => {
    _state.physicsEnabled = !!state;
    _updateRegisteredScopes();
  });


  var _visualizationModes = {
    'None':        () => { },
    'Depth':       () => { bngApi.engineScript('toggleDepthViz("");');         },
    'Normal':      () => { bngApi.engineScript('toggleNormalsViz("");');       },
    'Light Color': () => { bngApi.engineScript('toggleLightColorViz("");');    },
    'Specular':    () => { bngApi.engineScript('toggleLightSpecularViz("");'); }
  };

  return service = {
    registerScope: (scope, callback) => {
      _registeredScopes[scope.$id] = callback;
      scope.$on('$destroy', () => {
        delete _registeredScopes[scope.$id];
      });
    },

    get state() { return _state; },
    get jsLogging() { return window.jsLogging; },

    toggleJSLogging: (state) => {
      state = (state === undefined) ? window.jsLogging.enabled : state;
      window.jsLogging.enabled = state;
      window.jsLogging.provider.debugEnabled(state);
    },

    update: _update,
    applyState: _applyState,

    cameraSpeed: 0,
    visualizationModes: Object.keys(_visualizationModes),

    vehicles: {
      spawnNew:        () => { bngApi.engineLua('core_vehicles.spawnDefault()'); },
      removeCurrent:   () => { bngApi.engineLua('core_vehicles.removeCurrent()'); },
      cloneCurrent:    () => { bngApi.engineLua('core_vehicles.cloneCurrent()'); },
      removeAll:       () => { bngApi.engineLua('core_vehicles.removeAll()'); },
      removeOthers: () => { bngApi.engineLua('core_vehicles.removeAllExceptCurrent()'); },
      loadDefault: () => {bngApi.engineLua('core_vehicles.loadDefault()');},
      resetAll:        () => { bngApi.engineScript('beamNGResetFlexMeshAllVehicles();beamNGResetAllVehicles();'); },
      reloadAll:       () => { bngApi.engineScript('beamNGReloadAllVehicles();'); },
    },

    setCameraSpeed: (cameraSpeed) => {
      cameraSpeed = (cameraSpeed === undefined) ? service.cameraSpeed : cameraSpeed;
      service.cameraSpeed = cameraSpeed;
      bngApi.engineScript(`$Camera::movementSpeed = ${cameraSpeed};`);
      _updateRegisteredScopes();
    },

    setFOV: (fov) => {
      fov = (fov === undefined) ? _state.fov : fov;
      bngApi.engineScript(`setFov(${fov});`);
      _state.fov = fov;
      _applyState();
    },

    togglePhysics: (status) => {
      bngApi.engineLua(`bullettime.togglePause()`);
    },

    toggleBoundingBoxes: (status) => {
      status = (status === undefined) ? !_state.renderer.boundingboxes : !!status;
      bngApi.engineScript(`$Scene::renderBoundingBoxes=${status};`);
    },

    toggleShadowsDisabled: (status) => {
      status = (status === undefined) ? !_state.renderer.disableShadows : !!status;
      bngApi.engineScript(`$Shadows::disable=${status};`);
    },

    toggleWireframe: (status) => {
      status = (status === undefined) ? !_state.renderer.wireframe : !!status;
      _state.renderer.wireframe = status;
      bngApi.engineScript(`$gfx::wireframe=${status};`);
      _applyState();
    },

    showGroundModelDebug: () => {bngApi.engineLua('extensions.load("test_groundModelDebug") test_groundModelDebug.openWindow()');},

    setVisualizationMode: (mode) => {
      mode = (mode === undefined) ? _state.renderer.visualization : mode;
      if (mode === 'None')
        _visualizationModes[_lastVisualizationMode]();
      else
        _visualizationModes[mode]();

      _applyState();
      _update();
    },

    toggleFps:        () => { bngApi.engineScript('cycleMetrics();');  },
    toggleFreeCamera: () => { bngApi.engineLua('commands.toggleCamera()');}
  };
}])

// Populated in run phase of beamng.data module
.constant('Hints', [])


.factory('AppSelectFilters', [function () {
  var _types = {}; // The types are filled in each time the app list gets updated

  var service = {
    query: '',

    get types() { return _types; },

    selectAll: () => { for (var key in _types) _types[key] = true; },

    deselectAll: () => {
      for (var key in _types)
        _types[key] = false;
      service.query = '';
    },

    typesFilter: (model) => {
      return Object.keys(_types).some(key => _types[key] && model.types.indexOf(key) !== -1);
    }
  };

  return service;
}])


.run(['$http', '$log', 'Hints', 'InstalledContent', function ($http, $log, Hints, InstalledContent) {

  var hintsPath = 'modules/loading/hints.json';

  $http.get(hintsPath)
    .success((data) => { Array.prototype.push.apply(Hints, data); })
    .error((error) => { $log.error(`Could not load hints from ${hintsPath}.`); });

}]);
