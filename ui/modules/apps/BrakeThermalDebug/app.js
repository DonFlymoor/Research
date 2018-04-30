angular.module('beamng.apps')
.directive('brakeThermalDebug', ['UiUnits', function (UiUnits) {
  return {
    templateUrl: 'modules/apps/BrakeThermalDebug/app.html',
    replace: true,
    restrict: 'EA',
    scope: true,
    controller: ['$log', '$scope', 'bngApi', 'StreamsManager', function ($log, $scope, bngApi, StreamsManager) {
      var streamsList = ['wheelThermalData'];
      StreamsManager.add(streamsList);
      $scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      $scope.gearText = '';
      $scope.wheels = [];
      $scope.displayWheel1 = null;
      $scope.displayWheel2 = null;

      var _reset = function () {
        $scope.$evalAsync(function () {
          $scope.wheels = [];
          $scope.displayWheel1 = null;
          $scope.displayWheel2 = null;
        });
      };

      $scope.$on('streamsUpdate', function (event, data) {
        if (!data.wheelThermalData) {
          $scope.data = [];
          return;
        }

        if ($scope.wheels.length < 1) {
          var wheelKeys = Object.keys(data.wheelThermalData.wheels);
          $scope.wheels = wheelKeys;
          $scope.displayWheel1 = wheelKeys[wheelKeys.length-1];
          $scope.displayWheel2 = wheelKeys[0];
          $scope.$digest();
          return;
        }

        if ( !($scope.displayWheel1 in data.wheelThermalData.wheels) ||
             !($scope.displayWheel2 in data.wheelThermalData.wheels)) {
          _reset();
          return;
        }

        $scope.$evalAsync(function () {
          var currentWheels = Object.keys(data.wheelThermalData.wheels);
          if (currentWheels.length != $scope.wheels.length)
            $scope.wheels = currentWheels;

          $scope.data = makeDataDisplayable(data.wheelThermalData, $scope.displayWheel1, $scope.displayWheel2);
        });
      });

      $scope.$on('VehicleFocusChanged', _reset);
      $scope.$on('VehicleReset', _reset);

      var makeDataDisplayable = function (data, displayWheel1, displayWheel2) {
        return [{
              name: 'Brake Type',
              str1: data.wheels[displayWheel1].brakeType,
              str2: data.wheels[displayWheel2].brakeType,
          }, {
              name: 'Pad Type',
              str1: data.wheels[displayWheel1].padMaterial,
              str2: data.wheels[displayWheel2].padMaterial,
          }, {
              name: 'Surface Temp',
              str1: UiUnits.buildString('temperature', data.wheels[displayWheel1].brakeSurfaceTemperature, 0),
              str2: UiUnits.buildString('temperature', data.wheels[displayWheel2].brakeSurfaceTemperature, 0),
          }, {
			  name: 'Core Temp',
              str1: UiUnits.buildString('temperature', data.wheels[displayWheel1].brakeCoreTemperature, 0),
              str2: UiUnits.buildString('temperature', data.wheels[displayWheel2].brakeCoreTemperature, 0),
          }, {
              name: 'Energy To Brake Surface',
              str1: UiUnits.buildString('energy', data.wheels[displayWheel1].energyToBrakeSurface, 0),
              str2: UiUnits.buildString('energy', data.wheels[displayWheel2].energyToBrakeSurface, 0),
		  }, {
              name: 'Energy Surface To Core',
              str1: UiUnits.buildString('energy', data.wheels[displayWheel1].energyBrakeSurfaceToCore, 0),
              str2: UiUnits.buildString('energy', data.wheels[displayWheel2].energyBrakeSurfaceToCore, 0),
          }, {
              name: 'Energy Surface To Air',
              str1: UiUnits.buildString('energy', data.wheels[displayWheel1].energyBrakeSurfaceToAir, 0),
              str2: UiUnits.buildString('energy', data.wheels[displayWheel2].energyBrakeSurfaceToAir, 0),
		  }, {
              name: 'Energy Core To Air',
              str1: UiUnits.buildString('energy', data.wheels[displayWheel1].energyBrakeCoreToAir, 0),
              str2: UiUnits.buildString('energy', data.wheels[displayWheel2].energyBrakeCoreToAir, 0),
          }, {
              name: 'Energy Radiation To Air',
              str1: UiUnits.buildString('energy', data.wheels[displayWheel1].energyRadiationToAir, 0),
              str2: UiUnits.buildString('energy', data.wheels[displayWheel2].energyRadiationToAir, 0),
          }, {
              name: 'Surface Cooling',
              str1: data.wheels[displayWheel1].surfaceCooling.toFixed(2),
              str2: data.wheels[displayWheel2].surfaceCooling.toFixed(2),
          }, {
              name: 'Core Cooling',
              str1: data.wheels[displayWheel1].coreCooling.toFixed(2),
              str2: data.wheels[displayWheel2].coreCooling.toFixed(2),
		  }, {
              name: 'Thermal Efficiency',
              str1: data.wheels[displayWheel1].brakeThermalEfficiency.toFixed(2),
              str2: data.wheels[displayWheel2].brakeThermalEfficiency.toFixed(2),
		  //}, {
          //    name: 'Pad Glazing',
          //    str1: data.wheels[displayWheel1].padGlazingFactor.toFixed(2),
          //    str2: data.wheels[displayWheel2].padGlazingFactor.toFixed(2),
          }, {
              name: 'Final Efficiency',
              str1: data.wheels[displayWheel1].finalBrakeEfficiency.toFixed(2),
              str2: data.wheels[displayWheel2].finalBrakeEfficiency.toFixed(2),
              warn1: (data.wheels[displayWheel1].finalBrakeEfficiency <= 0.90),
              warn2: (data.wheels[displayWheel2].finalBrakeEfficiency <= 0.90),
              error1: (data.wheels[displayWheel1].finalBrakeEfficiency < 0.85),
              error2: (data.wheels[displayWheel2].finalBrakeEfficiency < 0.85)
		  
		  }, {
              name: 'Slope',
              str1: data.wheels[displayWheel1].slopeSwitchBit,
              str2: data.wheels[displayWheel2].slopeSwitchBit,
          }
        ];
      }
    }]
  };
}]);
