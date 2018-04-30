angular.module('beamng.apps')
.directive('vehicleTelemetryDebug', [function () {
  return {
    template:
    '<div style="max-height:100%; width:100%; background:transparent;" layout="row" layout-align="center center" layout-wrap>' +
      '<md-button flex style="margin: 2px; min-width: 198px" md-no-ink class="md-raised" ng-click="startRecording()">Start Recording</md-button>' +
      '<md-button flex style="margin: 2px; min-width: 122px" md-no-ink class="md-raised" ng-click="stopRecording()">Pause Recording</md-button>' +
      '<md-button flex style="margin: 2px; min-width: 148px" md-no-ink class="md-raised" ng-click="resetData()">Reset</md-button>' +
      '<md-button flex style="margin: 2px; min-width: 124px" md-no-ink class="md-raised" ng-click="saveToDisk()">Stop + Save Data</md-button>' +
    '</div>',
    replace: true,
    restrict: 'EA',
    scope: true,
    controller: ['$log', '$scope', 'bngApi', function ($log, $scope, bngApi) {
		bngApi.activeObjectLua('extensions.load("telemetryLogger");');

		$scope.$on('VehicleFocusChanged', function () {
            bngApi.activeObjectLua('extensions.load("telemetryLogger");');
        });

        $scope.startRecording = function () {
            bngApi.activeObjectLua('telemetryLogger.startRecording()');
        };

        $scope.stopRecording = function () {
            bngApi.activeObjectLua('telemetryLogger.stopRecording()');
        };

        $scope.resetData = function () {
            bngApi.activeObjectLua('telemetryLogger.onReset()');
        };

        $scope.saveToDisk = function () {
            bngApi.activeObjectLua('telemetryLogger.saveDataToDisk()');
        };
    }]
  };
}]);