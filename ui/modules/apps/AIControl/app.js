angular.module('beamng.apps')

.constant('AI_Options', {
    // drawingDistance: [
    //   { txt: '50m',  val: 50    },
    //   { txt: '200m', val: 200   },
    //   { txt: '400m', val: 400   },
    //   { txt: '10km', val: 10000 }
    // ],

    engineDebugMode: [
      { txt: 'Disabled',   val: 'off'    },
      { txt: 'NaviGraph',  val: 'graph'  },
      { txt: 'Visual Log', val: 'vislog' }
    ],

    aiMode: [
      { txt: 'Disabled', val: 'disabled' },
      { txt: 'Random',   val: 'random'   },
      { txt: 'Span',     val: 'span'     },
      { txt: 'Manual',   val: 'manual'   },
      { txt: 'Chase',    val: 'chase'    },
      { txt: 'Flee',     val: 'flee'     },
      { txt: 'Stopping', val: 'stop'     }
    ],

    vehicleDebugMode: [
      { txt: 'Disabled',    val: 'off'        },
      { txt: 'Target',      val: 'target'     },
      { txt: 'Speeds',      val: 'speeds'     },
      { txt: 'Trajectory',  val: 'trajectory' },
      { txt: 'Route',       val: 'route'      }
    ],

    speedMode: [
      { txt: 'off',   val: 'off'    },
      { txt: 'Set',   val: 'set'    },
      { txt: 'Limit', val: 'limit'  }
    ],

    driveInLaneFlag: [
      { txt: 'off',   val: 'off'    },
      { txt: 'on',    val: 'on'     }
    ]
})


.directive('aiControl', ['AI_Options', 'bngApi', function (AI_Options, bngApi) {
  return {
    templateUrl: 'modules/apps/AIControl/app.html',
    replace: false,
    restrict: 'E',
    scope: false,
    link: function (scope, element, attrs) {
      var ctrl = scope.ai;
      ctrl.populate();

      scope.$on('AIStateChange', function (_, data) {
        // console.log('AISTATECHANGE EVENT:', data);
        // Same thing as in ai.getState() callback in ctrl._updateAiState() function
        scope.$evalAsync(function () {
          ctrl.mode.value = data.mode;
          if (data.mode.value != 'manual') ctrl.mapNodes.value = null;

          ctrl.aggression.value = data.extAggression;
          ctrl.driveInLaneFlag.value = data.driveInLaneFlag;
          ctrl.vehicleDebugMode.value = data.debugMode;
          ctrl.targetObjects.value = data.targetObjectID;
          ctrl.mapNodes.value = data.manualTargetName;
          ctrl.routeSpeed.value = Math.round(data.routeSpeed * ctrl.distanceUnits.mult);
          ctrl.speedMode.value = data.speedMode;
          ctrl.drivability.value = data.cutOffDrivability;
        });
      });

      bngApi.engineLua('settings.requestState()');

      scope.$on('VehicleReset', function (_, data) {
        // console.log('VEHICLERESET EVENT:', data);
        ctrl._updateMapState();
      });

      scope.$on('VehicleFocusChanged', function (_, data) {
        // console.log('VEHICLEFOCUSCHANGED EVENT:', data);
        ctrl._updateMapState();
      });
    },

    controller: function ($scope, $element, $attrs) {
      var vm = this;

      var units = {
        'metric': {label: 'km/h', mult: 3.6},
        'imperial': {label: 'mph', mult: 2.23694}
      };

      vm.distanceUnits = {};

      $scope.$on('SettingsChanged', function (event, data) {
        $scope.$evalAsync(function () {
          vm.distanceUnits = units[data.values.uiUnitLength];
        });
      });

      vm.mode = {value: null, options: AI_Options.aiMode};
      vm.aggression = {value: 1};
      vm.driveInLaneFlag = {value: null, options: AI_Options.driveInLaneFlag};
      vm.routeSpeed = {value: null};
      vm.speedMode = {value: null, options: AI_Options.speedMode};
      vm.engineDebugMode  = {value: null, options: AI_Options.engineDebugMode};
      vm.vehicleDebugMode = {value: null, options: AI_Options.vehicleDebugMode};
      vm.mapNodes = {value: null, options: []};
      vm.targetObjects = {value: null, options: []};
      vm.drivability = {value: 0};
      // vm.drawingDistance = {value: null, options: AI_Options.drawingDistance};

      vm.changeMode = function () {
        var cmd = `ai.setState( ${bngApi.serializeToLua({mode: vm.mode.value})} )`;
        bngApi.activeObjectLua(cmd);
        // console.log('changing AI mode:', cmd);
      };

      vm.changeAggression = function () {
        var cmd = `ai.setAggression(${vm.aggression.value})`;
        bngApi.activeObjectLua(cmd);
      };

      vm.changeCutOffDrivability = function () {
        var cmd = `ai.setCutOffDrivability(${vm.drivability.value})`;
        bngApi.activeObjectLua(cmd);
        console.log('Changed cut off drivability')
      }

      vm.changeLaneDriving = function () {
        var cmd = `ai.driveInLane("${vm.driveInLaneFlag.value}")`;
        bngApi.activeObjectLua(cmd);
      };

      vm.changeSpeed = function () {
        var siSpeed = vm.routeSpeed.value / vm.distanceUnits.mult;
        var cmd = `ai.setSpeed(${siSpeed})`;
        bngApi.activeObjectLua(cmd);
      };

      vm.changeSpeedMode = function () {
        var cmd = `ai.setSpeedMode("${vm.speedMode.value}")`;
        bngApi.activeObjectLua(cmd);
      };

      vm.changeEngineDebugMode = function () {
        var cmd = `map.setDebugMode("${vm.engineDebugMode.value}")`;
        bngApi.engineLua(cmd);
      };

      vm.changeVehicleDebugMode = function () {
        var cmd = `ai.setVehicleDebugMode( ${bngApi.serializeToLua({debugMode: vm.vehicleDebugMode.value})} )`;
        bngApi.activeObjectLua(cmd);
        // console.log('change vehicle debug mode:', cmd);
      };

      vm.changeMapNode = function () {
        // Although this is can only be called when in "manual" mode, we still have to re-apply
        // the state to the Lua side (is this a bug?)
        //vm.mode.value = 'manual';
        //var aiModeCmd = `ai.setState( ${bngApi.serializeToLua({mode: 'manual'})} )`;
        //bngApi.activeObjectLua(aiModeCmd);

        var cmd = `ai.setTarget("${vm.mapNodes.value}")`
        bngApi.activeObjectLua(cmd);
        // console.log('change map node:', cmd);
      };

      vm.changeTargetObject = function () {
        var cmd = `ai.setTargetObjectID(${vm.targetObjects.value})`;
        bngApi.activeObjectLua(cmd);
        // console.log('change Target:', cmd);
      };

      // vm.changeDrawingDistance = function () {
      //   var changesStr = bngApi.serializeToLua({ debugDrawingDistance: vm.drawingDistance.value });
      //   bngApi.activeObjectLua(`ai.setState(${changesStr})`);
      //   bngApi.engineLua(`map.setState(${changesStr})`);
      //   console.log('draw changes str:', changesStr);
      // };

      vm._updateAiState = function () {
        bngApi.activeObjectLua('ai.getState()', (response) => {
          // console.log('ai.getState(): ', response);
          $scope.$evalAsync(function () {
            vm.mode.value = response.mode;

            if (vm.mode.value != 'manual') vm.mapNodes.value = null;

            vm.aggression.value = response.extAggression;
            vm.driveInLaneFlag.value = response.driveInLaneFlag;
            vm.vehicleDebugMode.value = response.debugMode;
            vm.targetObjects.value = response.targetObjectID;
            vm.mapNodes.value = response.manualTargetName;
            vm.routeSpeed.value = response.routeSpeed * vm.distanceUnits.mult;
            vm.speedMode.value = response.speedMode;
            vm.drivability.value = response.drivability;
          });
        });
      };

      vm._updateMapState = function () {
        bngApi.engineLua('map.getState()', (response) => {
          // console.log('map.getState(): ', response);

          $scope.$evalAsync(function () {
            // vm.drawingDistance.value = response.debugDrawingDistance;
            vm.targetObjects.options =  Object.keys(response.objects)
              .filter(x => !response.objects[x].active)
              .map(x => ({
                id: response.objects[x].id,
                txt: `${response.objects[x].name}  (${response.objects[x].licensePlate}, ${x})`
              }));
            vm.engineDebugMode.value = response.debugMode;
          });
        });
      };

      vm._updateNodes = function () {
        bngApi.engineLua('map.getMap()', (response) => {
          // console.log('map.getMap(): ', response);
          $scope.$evalAsync(function () {
            vm.mapNodes.options = Object.keys(response.nodes).sort();
          });
        });
      };

      vm.populate = function () {
        // console.log('POPULATE');
        vm._updateAiState();
        vm._updateMapState();
        vm._updateNodes();
      };

    },
    controllerAs: 'ai'
  };
}]);