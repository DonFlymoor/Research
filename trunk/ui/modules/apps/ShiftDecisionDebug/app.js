angular.module('beamng.apps')
.directive('shiftDecisionDebug', ['UiUnits', function (UiUnits) {
  return {
    template: 
    '<div style="height:100%; width:100%;" class="bngApp">' + 
      'Shift up RPM: {{ data.shiftUpRPM.toFixed(0) }}<br>' + 
      'Shift Down RPM: {{ data.shiftDownRPM.toFixed(0) }}<br>' +
      'Aggression: {{ data.aggression.toFixed(2) }} <br>' + 
      'Wheelslip Down: {{ data.wheelSlipDown }} <br>' + 
      'Wheelslip Up: {{ data.wheelSlipUp }} <br>' +
    '</div>',
    replace: true,
    restrict: 'EA',
    scope: true,
    controller: ['$log', '$scope', 'bngApi', 'StreamsManager', function ($log, $scope, bngApi, StreamsManager) {
      var streamsList = ['shiftDecisionData'];
      StreamsManager.add(streamsList);
      $scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      $scope.$on('streamsUpdate', function (event, data) {
        $scope.$evalAsync(function () {
          $scope.data = data.shiftDecisionData;
        });        
      });
    }]
  };
}]);