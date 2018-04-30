angular.module('beamng.apps')
.directive('escStiffness', [function () {
  return {
    template: 
    '<div style="max-height:100%; width:100%; background:transparent;" layout="row" layout-align="center center" layout-wrap>' + 
      '<md-button flex style="margin: 2px; min-width: 198px" md-no-ink class="md-raised" ng-click="startTest()">Start Test</md-button>' + 
      '<md-button flex style="margin: 2px; min-width: 122px" md-no-ink class="md-raised" ng-click="stopTest()">Stop Test</md-button>' +     
	  '<div style="height:100%; width:100%; background-color: rgba(255,255,255,0.9)">' + 
        'State: {{ data.state }}<br>' + 
        'Progress: {{ data.progress.toFixed(2) }}%<br>' + 
        'Target Angle: {{ data.currentAngle }}<br>' + 
        'Target Speed: {{ data.currentSpeed.toFixed() }}<br>' +
        'Max. Stiffness Front: {{ data.stiffnessFront.toFixed() }}<br>' +
        'Max. Stiffness Rear: {{ data.stiffnessRear.toFixed() }}<br>' +
      '</div>'+
    '</div>',
    replace: true,
    restrict: 'EA',
    scope: true,
    controller: ['$log', '$scope', 'bngApi', function ($log, $scope, bngApi) {

        $scope.startTest = function () {
            bngApi.activeObjectLua('extensions.escCalibration.startSkewStiffnessTest()');
        };

        $scope.stopTest = function () {
            bngApi.activeObjectLua('extensions.escCalibration.stopSkewStiffnessTest()');
        };
		
		$scope.$on('ESCSkewStiffnessChange', function (event, data) {
			$scope.$evalAsync(function () {
				$scope.data = data;
			});
        });
		
		//$scope.$on('VehicleChange', function () {
        //    bngApi.activeObjectLua('extensions.load("escCalibration");');
        //  });
		
		$scope.data = {state : "", progress : 0, currentAngle : 0, currentSpeed : 0, stiffnessFront : 0, stiffnessRear : 0}
		//bngApi.activeObjectLua('extensions.load("escCalibration");');
    }]
  };
}]);