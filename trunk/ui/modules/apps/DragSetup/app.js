angular.module('beamng.apps')
.directive('dragSetup', [function () {
  return {
    template:
    '<div style="max-height:100%; width:100%; background:transparent;" layout="row" layout-align="center center" layout-wrap>' +
      '<md-button flex style="margin: 2px; min-width: 198px" md-no-ink class="md-raised" ng-click="prepare()">Prepare</md-button>' +
      '<md-button flex style="margin: 2px; min-width: 148px" md-no-ink class="md-raised" ng-click="go()">Go!</md-button>' +
    '</div>',
    replace: true,
    restrict: 'EA',
    scope: true,
    controller: ['$log', '$scope', 'bngApi', function ($log, $scope, bngApi) {
        
        $scope.prepare = function () {
            bngApi.engineScript('beamNGResetAllVehicles();');
            bngApi.engineLua("be:queueAllObjectLua('controller.mainController.setFreeze(1)')");
            bngApi.engineLua("be:queueAllObjectLua('input.event(\"throttle\",1,2)')");
        };

        $scope.go = function () {
            bngApi.engineLua("be:queueAllObjectLua('controller.mainController.setFreeze(0)')");
        };
    }]
  };
}]);