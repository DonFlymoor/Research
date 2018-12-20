angular.module('beamng.apps')
.directive('tacho2', ['logger', 'bngApi', 'StreamsManager', 'UiUnits', function (logger, bngApi, StreamsManager, UiUnits) {
  return {
    template:
        '<object style="width:100%; height:100%; box-sizing:border-box; pointer-events: none" type="image/svg+xml" data="modules/apps/Tacho2/tacho.svg?t=' + Date.now() + '"></object>',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {

      element.on('load', function () {
        var svg = element[0].contentDocument;

        scope.$on('VehicleChange', svg.vehicleChanged);

        scope.$on('VehicleFocusChanged', function (event, data) {
          if(data.mode == 1 && svg && svg.vehicleChanged) {
             svg.vehicleChanged();
          }
        });

        scope.$on('streamsUpdate', (ev, streams) => svg.update(streams));

        svg.wireThroughUnitSystem((val, func) => UiUnits[func](val));


        StreamsManager.add(svg.getStreams());
        scope.$on('$destroy', function () {
          StreamsManager.remove(svg.getStreams());
        });
      });
    }
  };
}]);