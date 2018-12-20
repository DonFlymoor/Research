angular.module('beamng.apps')
  .directive('simpleAGears', ['StreamsManager', function (StreamsManager) {
    return {
      template: '<object style="width:100%; height:100%; pointer-events: none" type="image/svg+xml" data="modules/apps/SimpleAGears/simple-a-gears.svg?t=' + Date.now() + '"></object>',
      replace: true,
      link: function (scope, element, attrs) {
        StreamsManager.add(['electrics', 'engineInfo']);

        scope.$on('$destroy', function () {
          StreamsManager.remove(['electrics', 'engineInfo']);
        });

        element.on('load', function () {
          var svg = element[0].contentDocument;

          var presets = {
            P: { letter: svg.getElementById('letter-P'), box: svg.getElementById('box-P') },
            R: { letter: svg.getElementById('letter-R'), box: svg.getElementById('box-R') },
            N: { letter: svg.getElementById('letter-N'), box: svg.getElementById('box-N') },
            D: { letter: svg.getElementById('letter-D'), box: svg.getElementById('box-D') },
            2: { letter: svg.getElementById('letter-2'), box: svg.getElementById('box-2') },
            1: { letter: svg.getElementById('letter-1'), box: svg.getElementById('box-1') }
          };

          var activeGear = null;

          var backToDefault = function (index) {
            presets[index].letter.style.fill = 'black';
            presets[index].box.style.fill = 'none';
          };

          var highlight = function (index) {
            presets[index].letter.style.fill = 'white';
            presets[index].box.style.fill = '#e15b00';
          };

          scope.$on('streamsUpdate', function (event, streams) {
            if (streams.electrics != null) {
              currGear = streams.electrics.gear;
              if (activeGear != currGear) {
                if (presets[currGear] != null) {
                  if (activeGear != null) {
                    backToDefault(activeGear)
                  }
                  highlight(streams.electrics.gear)
                  activeGear = currGear;
                }
              }
            }
            else {
              return;
            }
          });
        });
      }
    };
  }]);