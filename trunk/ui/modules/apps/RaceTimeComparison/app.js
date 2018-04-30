angular.module('beamng.apps')

/**
 * @ngdoc directive
 * @name beamng.apps:raceTimeComparison
 * @description Simple app that compare the time with last lap in race mode.
**/
.directive('raceTimeComparison', ['$log', function ($log) {
  return {
    template: 
      '<div class="bngApp" style="width: 100%; height: 100%; font-size: 1.4em; background-color: {{ bgColor}};" ' +
                  'layout="row" layout-align="center center">' +
        '<span ng-if="time > 0">+</span>{{ time.toFixed(3) }}' +
      '</div>',
    replace: true,
    link: function (scope, element, attrs) {
      scope.time = null;
      scope.bgColor = 'transparent';

      scope.$on('RaceTimeComparison', function (event, data) {
        scope.$applyAsync(function () {
          scope.time = data.time;
          scope.bgColor = (data.time > 0 ? 'rgba(212,0,0,0.71)' : 'rgba(60,204,0,0.71)');
        });
      });

      scope.$on('ScenarioNotRunning', function () {
        scope.time = null;
        scope.bgColor = 'transparent';
      });
    }
  };
}]);