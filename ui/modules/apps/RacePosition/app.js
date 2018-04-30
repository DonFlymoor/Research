angular.module('beamng.apps')
.directive('racePosition', ['$log', function ($log) {
  return {
    template: 
        '<div style="height:100%; width: 100%; background: rgba(0,0,0,0.2)">{{ position }}</div>',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      scope.position = '';
      scope.$on('Position', function (event, data) {
        $log.debug('<race-position> got Position message: %o', data);
        scope.$evalAsync(function () {
          scope.position = data;
        });
      });
    }
  }
}])