angular.module('beamng.apps')

/**
 * @ngdoc directive
 * @name beamng.apps:raceLaps
 * @description 
**/
.directive('raceLaps', function () {
  return {
    template: 
      '<div ng-class="{\'bngApp\' : data}" style="width: 100%; height: 100%; font-size: 1.4em;" ' +
                  'layout="column" layout-align="center center">' +
        '<span ng-if="data">Lap {{ data.current }} / {{ data.count }}</span>' +
      '</div>',
    replace: true,
    link: function (scope, element, attrs) {
      scope.data = null;
      scope.$on('RaceLapChange', function (event, data) {
        if(data === null) return; 
        scope.$applyAsync(function () { 
          scope.data = data;
        });
      });

      scope.$on('ScenarioNotRunning', function () {
        scope.data = null;
      });
    }
  };
});