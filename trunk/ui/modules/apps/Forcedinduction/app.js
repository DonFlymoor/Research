angular.module('beamng.apps')
.directive('forcedInduction', ['$log', 'bngApi', 'StreamsManager', 'UiUnits', 'Utils', function ($log, bngApi, StreamsManager, UiUnits, Utils) {
  return {
    template:
        '<object style="width:100%; height:100%; visibility: hidden; box-sizing:border-box; pointer-events: none" type="image/svg+xml" data="modules/apps/forcedinduction/forcedinduction.svg?t=' + Date.now() + '"></object>',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {

      element.on('load', function () {
        var svg = element[0].contentDocument;
        svg.roundDec = Utils.roundDec;


        scope.$on('VechicleChange', svg.reset);

        scope.$on('VehicleFocusChanged', function (event, data) {
          if(data.mode == 1 && svg && svg.reset) {
             svg.reset();
          }
        });

        var enabled = false;

        scope.$on('streamsUpdate', (ev, streams) => {
          // todo: this function is bullshit visibility should be dependent on the lua module beeing loaded or not, not on data being present
          var newEnabled = svg.isStreamValid(streams)
          if (newEnabled) {
            if(newEnabled && !enabled) {
              element[0].style.visibility = '';
            }
            svg.update(streams);
          } else {
            if(!newEnabled && enabled) {
              element[0].style.visibility = 'hidden';
            }
          }
          enabled = newEnabled;
        });

        svg.wireThroughUnitSystem((val, func) => UiUnits[func](val));

        StreamsManager.add(svg.getStreams());
        scope.$on('$destroy', function () {
          StreamsManager.remove(svg.getStreams());
        });
      });
    }
  }
}])