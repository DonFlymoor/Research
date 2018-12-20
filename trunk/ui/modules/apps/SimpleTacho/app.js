
angular.module('beamng.apps')
.directive('simpleTacho', ['StreamsManager', function (StreamsManager) {
  return {
    template:
        '<object style="width:100%; height:100%; box-sizing:border-box; pointer-events: none" type="image/svg+xml" data="modules/apps/SimpleTacho/simple-tacho.svg?t=' + Date.now() + '"></object>',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
        StreamsManager.add(['engineInfo']);

        scope.$on('$destroy', function () {
            StreamsManager.remove(['electrics']);
        });

        element.on('load', function () {
            var svg = element[0].contentDocument;
            var values = [];

            scope.$on('streamsUpdate', function (event, streams) {
                if (streams.engineInfo[1] !== values[1] || streams.engineInfo[0] !== values[0]) {
                    values[0] = streams.engineInfo[0]; //rpm idle
                    values[1] = streams.engineInfo[1]; //rpm max
                    svg.getElementById('text0').innerHTML = values[0];
                    svg.getElementById('text1').innerHTML = values[1];
                }
                var rpm = Math.round(Number(streams.engineInfo[4]));
                var rgb = '';

                if(rpm < values[0] * 1.25) { //we are at idle, blue
                    rgb = '(0,0,255)';
                } else if(rpm > values[1] * 0.9) { //we are near redline, red
                    rgb = '(255,0,0)';
                } else { //normal rpm, green
                    rgb = '(0,255,0)';
                }

                svg.getElementById('rpm').innerHTML = rpm;
                svg.getElementById('filler').setAttribute("width", Math.abs(Math.round((rpm-values[0])/values[1] * 637)));
                svg.getElementById('filler').style.fill = 'rgb' + rgb;
            });
        });


    }
  };
}]);
