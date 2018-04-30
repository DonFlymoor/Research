angular.module('beamng.apps')
.directive('odometer', ['UiUnits', function (UiUnits) {
  return {
    template: 
      '<div class="bngApp" style="width: 100%; height: 100%; font-size: 1.4em;" ' +
                  'layout="column" layout-align="center center">' +        
        '<span style="font-size: 90%">Target Distance: {{ (odometerTargetDistance) || "-------" }}</span>' +
        '<span style="font-size: 90%">Current Distance: {{ (odometerDistance) || "-------" }}</span>' +
      '</div>',
    replace: true,
    link: function (scope, element, attrs) {
      'use strict';

      scope.odometerDistance = null;

      function resetValues () {
        scope.$evalAsync(function () {
          scope.odometerDistance = null;
          scope.odometerTargetDistance = null;
        });
      }

      scope.$on('odometerDistance', function (event, data) {
        
        scope.$evalAsync(function () {
          scope.odometerDistance = UiUnits.buildString('length', data.distance, data.decimalPlaces);
          scope.odometerTargetDistance = UiUnits.buildString('length', data.targetDistance, data.decimalPlaces);
        });
      });

      scope.$on('ScenarioResetTimer', resetValues);

      scope.$on('RaceLapChange', function (event, data) {
      
      });
    }
  };
}]);