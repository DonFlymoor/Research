angular.module('beamng.apps')
.directive('engineThermalDebug', ['UiUnits', function (UiUnits) {
  return {
    templateUrl: 'modules/apps/EngineThermalDebug/app.html',
    replace: true,
    restrict: 'EA',
    scope: true,
    controller: ['$log', '$scope', 'bngApi', 'StreamsManager', function ($log, $scope, bngApi, StreamsManager) {
      var streamsList = ['engineThermalData'];
      StreamsManager.add(streamsList);
      $scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      $scope.gearText = '';
      $scope.$on('streamsUpdate', function (event, data) {
        $scope.$evalAsync(function () {
          if (data.engineThermalData) {
            $scope.data = makeDataDisplayable(data.engineThermalData);
          } else {
            $scope.data = undefined;
          }
        });
      });

      function makeDataDisplayable (data) {
        return [{ 
              str: UiUnits.buildString('temperature', data.coolantTemperature, 0), 
              name: 'Coolant', 
              warn: (data.coolantTemperature > data.thermostatTemperature && data.coolantTemperature < 120 && data.thermostatStatus == 1),
              error: (data.coolantTemperature > 120)
          }, { 
              str: UiUnits.buildString('temperature', data.oilTemperature, 0), 
              name: 'Oil', 
              warn: data.oilTemperature > 140,
              error: data.oilTemperature > 150
          }, { 
              str: UiUnits.buildString('temperature', data.engineBlockTemperature, 0), 
              name: 'Block', 
          }, { 
              str: UiUnits.buildString('temperature', data.cylinderWallTemperature, 0), 
              name: 'Cylinder Wall', 
          }, { 
              str: UiUnits.buildString('temperature', data.exhaustTemperature, 0), 
              name: 'Exhaust Manifold', 
          }, { 
              str: data.thermostatStatus.toFixed(3), 
              name: 'Coolant Thermostat', 
              warn: data.thermostatStatus > 0.9
          }, { 
              str: data.oilThermostatStatus.toFixed(3), 
              name: 'Oil Thermostat',
              warn: data.oilThermostatStatus > 0.9
          }, { 
              str: UiUnits.buildString('speed', data.radiatorAirSpeed, 0), 
              name: 'Radiator Air Speed',
          }, { 
              str: data.radiatorAirSpeedEfficiency.toFixed(4), 
              name: 'Radiator Air Speed Efficiency', 
          }, { 
              str: data.fanActive, 
              name: 'Radiator Fan Active'
          }, { 
              str: data.coolantLeakRate.toFixed(3), 
              name: 'Coolant Leak Rate',
              warn: data.coolantLeakRate > 0,
          }, { 
              str: data.coolantEfficiency.toFixed(3), 
              name: 'Coolant Efficiency',
              warn: data.coolantEfficiency < 1,
              error: data.coolantEfficiency === 0
          }, { 
              str: data.engineEfficiency.toFixed(2), 
              name: 'Engine Efficiency', 
          }, { 
              str: UiUnits.buildString('energy', data.energyToCylinderWall, 0), 
              name: 'Q to cylinder wall', 
          }, { 
              str: UiUnits.buildString('energy', data.energyCylinderWallToCoolant, 0), 
              name: 'Q cylinder wall to coolant', 
          }, { 
              str: UiUnits.buildString('energy', data.energyCoolantToAir, 0), 
              name: 'Q coolant to air', 
          }, { 
              str: UiUnits.buildString('energy', data.energyCoolantToBlock, 0), 
              name: 'Q coolant to block', 
          }, { 
              str: UiUnits.buildString('energy', data.energyCylinderWallToBlock, 0), 
              name: 'Q cylinder wall to block', 
          }, { 
              str: UiUnits.buildString('energy', data.energyBlockToAir, 0), 
              name: 'Q block to air', 
          }, { 
              str: UiUnits.buildString('energy', data.energyToOil, 0), 
              name: 'Q to oil', 
          }, { 
              str: UiUnits.buildString('energy', data.energyCylinderWallToOil, 0), 
              name: 'Q cylinder wall to oil', 
          }, { 
              str: UiUnits.buildString('energy', data.energyOilToAir, 0), 
              name: 'Q oil radiator to air', 
          }, { 
              str: UiUnits.buildString('energy', data.energyOilSumpToAir, 0), 
              name: 'Q oil sump to air', 
          }, { 
              str: UiUnits.buildString('energy', data.energyToExhaust, 0), 
              name: 'Q to exhaust', 
          }, { 
              str: UiUnits.buildString('energy', data.energyExhaustToAir, 0), 
              name: 'Q exhaust to air', 
          }, { 
              str: data.engineBlockOverheatDamage.toFixed(), 
              name: 'Block Damage',
              warn: data.engineBlockOverheatDamage > 0
          }, { 
              str: data.oilOverheatDamage.toFixed(), 
              name: 'Oil Damage',
              warn: data.oilOverheatDamage > 0
          }, { 
              str: data.cylinderWallOverheatDamage.toFixed(), 
              name: 'Cylinder Wall Damage',
              warn: data.cylinderWallOverheatDamage > 0
          }, { 
              str: data.headGasketBlown, 
              name: 'Head gasket blown',
              error: data.headGasketBlown
          }, { 
              str: data.pistonRingsDamaged, 
              name: 'Piston rings damaged',
              error: data.pistonRingsDamaged
          }, { 
              str: data.connectingRodBearingsDamaged, 
              name: 'Connecting rod bearings damaged',
              error: data.connectingRodBearingsDamaged
          }
        ];
      }
    }]
  };
}]);
