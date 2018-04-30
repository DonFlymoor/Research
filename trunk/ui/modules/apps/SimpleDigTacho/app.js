angular.module('beamng.apps')
.directive('simpleDigTacho', ['$log', 'StreamsManager', function ($log, StreamsManager) {
  return {
    template: 
      '<div style="width:100%; height:100%;" class="bngApp" layout="column">' +
        '<div style="display:flex; justify-content: center; align-items: baseline;">' +
        //this ^ has to be display flex instead of the layout attribute from angular since the latter has no baseline option
          '<span style="font-size:1.3em; font-weight:bold;">' +
            '<span style="color: rgba(255, 255, 255, 0.8)"> {{leadingZeros}}</span>' +
            '<span>{{rpm}}</span>' +
          '</span>' +
          '<span style="font-size:0.9em; font-weight:bold; margin-left:2px">RPM</span>' +
        '</div>' +
        '<small style="text-align:center; color: rgba(255, 255, 255, 0.8); font-size: 0.75em">Engine <span>(x{{numToBig}})</span></small>' +
      '</div>',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      StreamsManager.add(['engineInfo']);

      scope.$on('$destroy', function () {
        $log.debug('<simple-dig-tacho> destroyed');
        StreamsManager.remove(['engineInfo']);
      });

      scope.numToBig = '1';
      scope.speed = NaN;

      scope.$on('streamsUpdate', function (event, streams) {  
        scope.$evalAsync(function () {
          var rpm = Math.round(streams.engineInfo[4]);
          if (rpm.toString().length > 4) {
            var help = Math.pow(10, rpm.toString().length -4);
            scope.numToBig = help.toString();
            rpm = Math.round(rpm / help);
          } else {
            scope.numToBig = '1';
          }
          scope.rpm = rpm.toString().slice(-4);
          if (!isNaN(scope.rpm)) {
            scope.leadingZeros = ('0000').slice(scope.rpm.length);
          }
        });
      });
    }
  };
}]);