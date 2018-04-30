angular.module('beamng.apps')
.directive('engineDebug', ['UiUnits', function (UiUnits) {
  return {
    template: 
    '<div style="height:100%; width:100%;" class="bngApp">' + 
      'RPM: {{ data.engineInfo[4].toFixed() }}<br>' + 
      'Gear: {{ gearText }}<br>' +
      'Flywheel torque: {{ engineT }} <br>' + 
      'Wheel torque: {{ wheelT }}' +
    '</div>',
    replace: true,
    restrict: 'EA',
    scope: true,
    controller: ['$log', '$scope', 'bngApi', 'StreamsManager', function ($log, $scope, bngApi, StreamsManager) {
      var streamsList = ['engineInfo'];
      StreamsManager.add(streamsList);
      $scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      $scope.gearText = '';

      $scope.$on('streamsUpdate', function (event, data) {
        $scope.$evalAsync(function () {
          if (data.engineInfo != null) {
            $scope.data = data;

            $scope.engineT = UiUnits.buildString('torque', data.engineInfo[8], 0);
            $scope.wheelT = UiUnits.buildString('torque', data.engineInfo[19], 0);
            
            var gear = data.engineInfo[16];
            
            if (gear > 0)
              $scope.gearText = 'F ' + gear + ' / ' + data.engineInfo[6];
            else if (gear < 0)
              $scope.gearText = 'R ' + Math.abs(gear) + ' / ' + data.engineInfo[7];
            else
              $scope.gearText = 'N';
          }
          else {
            return;
          }
        });
      });
    }]
  };
}]);