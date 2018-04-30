angular.module('beamng.apps')
  .directive('shiftPointDebug', ['StreamsManager', function (StreamsManager) {
    return {
      template:
      '<div>' +
        '<link type="text/css" rel="stylesheet" href="modules/apps/ShiftPointDebug/app.css">' +
        '<div class="ct-chart"></div>' +
      '</div>',
      replace: true,
      restrict: 'EA',
      link: function (scope, element, attrs) {
        var streamsList = ['shiftPointDebugData', 'engineInfo', 'electrics'];
        StreamsManager.add(streamsList);
        scope.$on('$destroy', function () {
          StreamsManager.remove(streamsList);
        });
        var windowHeight = 0;
        var rpm = 0;
        var currentSpeed = 0;
        var maxSpeed = 0;
        var currentGear = 0;

        var gearSpeeds = [];
        var gears = [];
        var shiftUp = [];
        var shiftDown = [];
        var labelTicks = [0];

        var data = {
          labels: [],
          series: []
        };

        var options = null;
        var chart = null;
        var clear = 1;

        function clearGraph() {
          gearSpeeds = [];
          gears = [];
          shiftUp = [];
          shiftDown = [];
          labelTicks = [0];
          data = {
            labels: [],
            series: []
          };
        }

        function updateGraph() {
          if (data.series[gears.length] != null) {
            data.series[gears.length][0][0].y = rpm;
            if (gearSpeeds[currentGear] != null) {
              data.series[gears.length][0][1].x = (rpm * gearSpeeds[currentGear].wheelSpeedCoef * 3.6);
            }
            data.series[gears.length][0][1].y = rpm;
            chart.update(data);
          }
        }

        function drawGraph(streams) {
          if (clear) {
            clearGraph();
            clear = 1;
          }
          if (streams != null) {
            for (i = 0; i < streams.forward.length; i++) {
              gearSpeeds[i] = streams.forward[i];
            }

            maxSpeed = gearSpeeds[streams.forward.length - 1].maxRPM * gearSpeeds[streams.forward.length - 1].wheelSpeedCoef * 3.6;

            shiftDown.push(   // line used for current rpm, also allows for shiftdown colours to correspond correctly
              new Array(
                { x: 0, y: 0 },
                { x: 0, y: 0 }
              )
            )

            for (i = 0; i < streams.forward.length; i++) {
              gears.push(
                new Array(
                  { x: (gearSpeeds[i].minRPM * gearSpeeds[i].wheelSpeedCoef) * 3.6, y: gearSpeeds[i].minRPM },
                  { x: (gearSpeeds[i].maxRPM * gearSpeeds[i].wheelSpeedCoef) * 3.6, y: gearSpeeds[i].maxRPM }
                )
              )
              if (i < streams.forward.length - 1) {
                shiftUp.push(
                  new Array(
                    { x: (gearSpeeds[i].shiftUpHigh * gearSpeeds[i].wheelSpeedCoef) * 3.6, y: gearSpeeds[i].shiftUpHigh },
                    { x: (gearSpeeds[i].shiftUpHigh * gearSpeeds[i].wheelSpeedCoef) * 3.6, y: ((gearSpeeds[i].shiftUpHigh * gearSpeeds[i].wheelSpeedCoef) / gearSpeeds[i + 1].wheelSpeedCoef) }
                  )
                )
              }
              if (i > 0) {
                shiftDown.push(
                  new Array(
                    { x: (gearSpeeds[i].shiftDownHigh * gearSpeeds[i].wheelSpeedCoef) * 3.6, y: gearSpeeds[i].shiftDownHigh },
                    { x: (gearSpeeds[i].shiftDownHigh * gearSpeeds[i].wheelSpeedCoef) * 3.6, y: ((gearSpeeds[i].shiftDownHigh * gearSpeeds[i].wheelSpeedCoef) / gearSpeeds[i - 1].wheelSpeedCoef) }
                  )
                )
              }
            }

            var count = 0;

            for (i = 0; i < maxSpeed; i++) {
              if (count <= maxSpeed) {
                count += 25;
                labelTicks.push(count);
              }
            }

            var gearLabels = labelTicks;

            for (i = 0; i < (gears.length + 1); i++) {
              data.series.push([]);
            }

            for (i = 0; i < gears.length; i++) {
              for (j = 0; j < gears[i].length; j++) {
                data.series[i].push(gears[i][j]);
              }
            }

            for (i = 0; i < shiftUp.length; i++) {
              for (j = 0; j < shiftUp[i].length; j++) {
                data.series[i].push(shiftUp[i][j]);
              }
            }

            for (i = 0; i < gears.length; i++) {    // hack to prevent bug with shiftUp lines attaching to shiftDown (fix)
              data.series[i].push([null][null]);
            }

            for (i = 0; i < shiftDown.length; i++) {
              for (j = 0; j < shiftDown[i].length; j++) {
                data.series[i].push(shiftDown[i][j]);
              }
            }
            data.series[gears.length].push(shiftDown[0]);
          }

          var options = {
            width: '100%',
            height: windowHeight + "px",
            axisX: {
              type: Chartist.FixedScaleAxis,
              low: 0,
              high: (Math.ceil(maxSpeed) + 20),
              ticks: labelTicks,
            },
            axisY: {
              low: 0,
              labelOffset: {
                y: 20
              }
            },
            fullWidth: true,
            showPoint: false,
            lineSmooth: Chartist.Interpolation.none({
              fillHoles: false,
            })
          };
          chart = new Chartist.Line('.ct-chart', data, options);
        }

        scope.$on('streamsUpdate', function (event, streams) {
          if (streams.engineInfo != null) {
            rpm = Math.max(streams.engineInfo[4], 0);
            currentSpeed = streams.electrics.wheelspeed;
            currentGear = streams.electrics.gear_M - 1;
            updateGraph();
          }
          else {
            return;
          }
        });

        scope.$on('ShiftPointDebugDataChanged', function (event, streams) {
          clearGraph();
          drawGraph(streams);
        })

        scope.$on('app:resized', function (event, streams) {
          windowHeight = streams.height;
          clear = 0;  // used to prevent the loss of data on resizing
          drawGraph();
        });
      }
    };
  }]);