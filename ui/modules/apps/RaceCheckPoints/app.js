angular.module('beamng.apps')

/**
 * @ngdoc directive
 * @name beamng.apps:raceCheckpoints
 * @description 
**/
.directive('raceCheckpoints', function () {
  return {
    template: 
      '<div ng-class="{\'bngApp\': txt}" style="width: 100%; height: 100%; font-size: 1.4em;" ' +
                  'layout="column" layout-align="center center">' +
        '{{ txt }}' +
      '</div>',
    replace: true,
    link: function (scope, element, attrs) {      
      scope.txt = null;
      scope.$on('WayPoint', function (event, data) {
        scope.$applyAsync(function () { 
          scope.txt = data;
        });
      });

      scope.$on('ScenarioNotRunning', function () {
        scope.txt = null;
      });
    }
  };
});