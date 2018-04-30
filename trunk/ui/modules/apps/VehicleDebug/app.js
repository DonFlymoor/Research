angular.module('beamng.apps')
.directive('vehicleDebug', [function () {
  return {
    template:
    '<div style="max-height:100%; width:100%; background:transparent;" layout="row" layout-align="center center" layout-wrap>' +
      '<md-button flex style="margin: 2px; min-width: 198px" md-no-ink class="md-raised" ng-click="breakAllBreakgroups()">{{\'ui.apps.vehicleDebug.breakAll\' | translate}}</md-button>' +
      '<md-button flex style="margin: 2px; min-width: 122px" md-no-ink class="md-raised" ng-click="deflateTires()">{{ \'ui.apps.vehicleDebug.deflateTires\' | translate }}</md-button>' +
      '<md-button flex style="margin: 2px; min-width: 148px" md-no-ink class="md-raised" ng-click="breakAllHinges()">{{ \'ui.apps.vehicleDebug.breakHinges\' | translate }}</md-button>' +
      '<md-button flex style="margin: 2px; min-width: 124px" md-no-ink class="md-raised" ng-click="igniteVehicle()">{{ \'ui.apps.vehicleDebug.igniteVehicle\' | translate }}</md-button>' +
      '<md-button flex style="margin: 2px; min-width: 124px" md-no-ink class="md-raised" ng-click="explodeVehicle()">{{ \'ui.apps.vehicleDebug.explodeVehicle\' | translate }}</md-button>' +
      '<md-button flex style="margin: 2px; min-width: 105px" md-no-ink class="md-raised" ng-click="igniteNode()">{{ \'ui.apps.vehicleDebug.igniteNode\' | translate }}</md-button>' +
      '<md-button flex style="margin: 2px; min-width: 105px" md-no-ink class="md-raised" ng-click="igniteNodeMinimal()">{{ \'ui.apps.vehicleDebug.igniteNodeMin\' | translate }}</md-button>' +
      '<md-button flex style="margin: 2px; min-width: 162px" md-no-ink class="md-raised" ng-click="extinguishVehicle()">{{ \'ui.apps.vehicleDebug.extinguishVehicle\' | translate }}</md-button>' +
    '</div>',
    replace: true,
    restrict: 'EA',
    scope: true,
    controller: ['$log', '$scope', 'bngApi', function ($log, $scope, bngApi) {

        $scope.breakAllHinges = function () {
            bngApi.activeObjectLua('beamstate.breakHinges()');
        };

        $scope.breakAllBreakgroups = function () {
            bngApi.activeObjectLua('beamstate.breakAllBreakgroups()');
        };

        $scope.deflateTires = function () {
            bngApi.activeObjectLua('beamstate.deflateTires()');
        };

        $scope.igniteVehicle = function () {
            bngApi.activeObjectLua('fire.igniteVehicle()');
        };

		$scope.explodeVehicle = function () {
            bngApi.activeObjectLua('fire.explodeVehicle()');
        };

        $scope.igniteNode = function () {
            bngApi.activeObjectLua('fire.igniteRandomNode()');
        };

		$scope.igniteNodeMinimal = function () {
            bngApi.activeObjectLua('fire.igniteRandomNodeMinimal()');
        };

        $scope.extinguishVehicle = function () {
            bngApi.activeObjectLua('fire.extinguishVehicle()');
        };
    }]
  };
}]);