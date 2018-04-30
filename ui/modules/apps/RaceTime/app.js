angular.module('beamng.apps')
.directive('raceTime', [function () {
  return {
    template: 
      '<div class="bngApp" style="width: 100%; height: 100%; font-size: 1.4em;" ' +
                  'layout="column" layout-align="center center">' +
        '<span style="font-size: 130%">Time</span>' + 
        '<span>{{ (raceTime | date: "mm:ss:sss") || "--:--:---" }}</span>' +
      '</div>',
    replace: true,
    link: function (scope, element, attrs) {
      'use strict';

      scope.raceTime = null;
      var offset = 0;
      var newLap = false;

      function resetValues () {
        offset = 0;
        newLap = false;
        scope.$evalAsync(function () {
          scope.raceTime = null;
        });
      }

      scope.$on('raceTime', function (event, data) {
        if (newLap) {
          offset = data.reverseTime ? 0 : data.time;
          newLap = false;
        }
        scope.$evalAsync(function () {
            scope.raceTime = (data.time - offset) * 1000;
        });
      });

      scope.$on('ScenarioResetTimer', resetValues);

      scope.$on('RaceLapChange', function (event, data) {
        if (data && data.current > 1) {
          newLap = true;
        }
      });
    }
  };
}]);