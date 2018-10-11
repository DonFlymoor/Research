angular.module('beamng.apps')
.directive('clutchThermalDebug', ['UiUnits', function (UiUnits) {
  return {
    templateUrl: 'modules/apps/ClutchThermalDebug/app.html',
    replace: true,
    restrict: 'EA',
    scope: true,
    controller: ['$log', '$scope', 'bngApi', 'StreamsManager', function ($log, $scope, bngApi, StreamsManager) {
      var streamsList = ['clutchThermalData'];
      StreamsManager.add(streamsList);
      $scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      $scope.gearText = '';
      $scope.$on('streamsUpdate', function (event, data) {
        $scope.$evalAsync(function () {
          if (data.clutchThermalData) {
            $scope.data = makeDataDisplayable(data.clutchThermalData);
          } else {
            $scope.data = undefined;
          }
        });
      });

      function makeDataDisplayable (data) {
        return [{ 
              str: UiUnits.buildString('temperature', data.clutchTemperature, 0), 
              name: 'Clutch temperature', 
              warn: (data.clutchTemperature > data.maxSafeTemp && data.clutchTemperature <= data.efficiencyScaleEnd),
              error: (data.clutchTemperature > data.efficiencyScaleEnd)
          }, { 
              str: UiUnits.buildString('temperature', data.maxSafeTemp, 0), 
              name: 'Max safe temperature', 
          }, {       
              str: UiUnits.buildString('temperature', data.efficiencyScaleEnd, 0), 
              name: 'Efficiency scale end', 
          }, { 
              str: data.thermalEfficiency.toFixed(3), 
              name: 'Clutch efficiency', 
              warn: (data.thermalEfficiency < 1 && data.thermalEfficiency >= 0.5),
              error: data.thermalEfficiency < 0.5
          }, { 
              str: UiUnits.buildString('energy', data.energyToClutch, 0), 
              name: 'Q to clutch', 
          }, { 
              str: UiUnits.buildString('energy', data.energyClutchToBellHousing, 0), 
              name: 'Q clutch to bell housing', 
          }
        ];
      }
    }]
  };
}]);
