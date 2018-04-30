angular.module('beamng.apps')
.directive('simpleDigSpeedoAir', ['$log', 'StreamsManager', 'UiUnits', function ($log, StreamsManager, UiUnits) {
  return {
    template:
      '<div style="width:100%; height:100%;" class="bngApp" layout="column">' +
        '<div style="display:flex; justify-content: center; align-items: baseline;">' +
        //this ^ has to be display flex instead of the layout attribute from angular since the latter has no baseline option
          '<span style="font-size:1.3em; font-weight:bold;">' +
            '<span style="color: rgba(255, 255, 255, 0.8)"> {{leadingZeros}}</span>' +
            '<span>{{speed.val}}</span>' +
          '</span>' +
          '<span style="font-size:0.9em; font-weight:bold; margin-left:2px">{{speed.unit}}</span>' +
        '</div>' +
        '<small style="text-align:center; color: rgba(255, 255, 255, 0.8); font-size: 0.75em">Airspeed</small>' +
      '</div>',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      'use strict';
      StreamsManager.add(['electrics']);

      scope.$on('$destroy', function () {
        $log.debug('<simple-dig-speedo> destroyed');
        StreamsManager.remove(['electrics']);
      });

      scope.speed = {
        val: 0,
        unit: ''
      };

      scope.$on('streamsUpdate', function (event, streams) {  
        scope.$evalAsync(function () {
          var speedMs = streams.electrics.airspeed;

          // logger.App.log('speed', speedMs);
          scope.speed = UiUnits.speed(speedMs);
          scope.speed.val = scope.speed.val.toFixed().slice(-4);
          if (!isNaN(scope.speed.val)) {
            scope.leadingZeros = ('0000').slice(scope.speed.val.length);
          }
        });
      });
    }
  };
}]);