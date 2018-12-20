angular.module('beamng.apps')
.directive('genericProfilingGraph', ['StreamsManager', function (StreamsManager) {
  return {
    template:
      `<div style="font-family:Consolas,Monaco,Lucida Console,Liberation Mono;">
        <div layout="column" style="position: absolute; top: 0; left: 5px;">
          <small ng-repeat="graph in graphList" style="color:{{ ::graph.color }}; padding:2px">{{ ::graph.title }} (AVG: {{ rollingAvg[graph.key] }} {{ ::graph.unit }})</small>
        </div>
        <canvas></canvas>
      </div>`,
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      var streamsList = ['profilingData'];
      StreamsManager.add(streamsList);
      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });


      var WINDOW_SIZE = 100
        , STEP_SIZE = 10
        , rollingAvg = {}
      ;

      var colori = 0;
      var contrast_color_list = [
          [255, 0, 0, 255],
          [0, 255, 0, 255],
          [0, 0, 255, 255],
          [255, 255, 0, 255],
          [255, 0, 255, 255],
          [0, 255, 255, 255],
          [96, 128, 200, 255],
          [196, 8, 0, 255],
          [120, 0, 196, 255],
          [90, 255, 255, 255],
          [63, 102, 190, 255],
          [235, 135, 63, 255]
        ]

      scope.rollingAvg = {}; // The data to be displayed in the legend

      var canvas = element[0].getElementsByTagName('canvas')[0];

      var chart = new SmoothieChart({
          millisPerPixel: 20,
          interpolation: 'bezier',
          grid: { fillStyle: 'rgba(250,250,250,0.8)', strokeStyle: 'transparent', verticalSections: 10, millisPerLine: 1000, sharpLines: true },
          labels: {fillStyle: 'black', precision: 6, fontSize:12}
        });
      var graphs = {};
      scope.graphList = [];

      chart.streamTo(canvas, 150);

      scope.$on('streamsUpdate', function (event, streams) {
        if (streams.profilingData) {
          var xPoint = new Date();

          for (var data in streams.profilingData) {
            if (graphs[data] == null) {
              var color;
              if (typeof streams.profilingData[data] === 'number') {
                var c = contrast_color_list[colori % contrast_color_list.length];
                color = "#" + "0".repeat(c[0]<10) + c[0].toString(16) + "0".repeat(c[1]<10) + c[1].toString(16) + "0".repeat(c[2]<10) + c[2].toString(16);
                  scope.graphList.push({
                    "title": data,
                    "color": color,
                    "key": data});
              } else {
                if ("max" in streams.profilingData[data]) {
                  chart.options.maxValue = Math.max(chart.options.maxValue, streams.profilingData[data].max);
                }

                if ("color" in streams.profilingData[data]) {
                  color = streams.profilingData[data].color;
                } else {
                  var c = contrast_color_list[colori % contrast_color_list.length];
                  color = "#" + "0".repeat(c[0]<10) + c[0].toString(16) + "0".repeat(c[1]<10) + c[1].toString(16) + "0".repeat(c[2]<10) + c[2].toString(16);
                }

                scope.graphList.push({
                  "title": ("title" in streams.profilingData[data] ? streams.profilingData[data].title : data),
                  "color": color,
                  "key": data,
                  unit: streams.profilingData[data].unit });
              }
              colori++;

              graphs[data] = new TimeSeries()

              rollingAvg[data] = {buffer: [], sum: 0.0, idx: 0, ticks: -1};
              scope.rollingAvg[data] = '---';

              chart.addTimeSeries(graphs[data], {strokeStyle: color, lineWidth: 2});
              scope.$digest();
              return;
            }
            var value = typeof streams.profilingData[data] === 'number' ? streams.profilingData[data]: streams.profilingData[data].value;
            graphs[data].append(xPoint, value);

            if (rollingAvg[data].buffer.length < WINDOW_SIZE) {
              rollingAvg[data].buffer.push(value)
              rollingAvg[data].sum += value
            } else {
              rollingAvg[data].sum -= rollingAvg[data].buffer[rollingAvg[data].idx];
              rollingAvg[data].sum += value;
              rollingAvg[data].buffer[rollingAvg[data].idx] = value;
              rollingAvg[data].idx  = (rollingAvg[data].idx + 1) % WINDOW_SIZE;
              rollingAvg[data].ticks = (rollingAvg[data].idx + 1) % STEP_SIZE;

              if (rollingAvg[data].ticks === 0) {
                scope.rollingAvg[data] = (rollingAvg[data].sum / WINDOW_SIZE).toFixed(6);
              }
            }
          }
          colori = 0;

          scope.$evalAsync(function () {});
        }
      });

      scope.$on('VehicleChange', function () {
        graphs = {};
        scope.graphList = [];
        scope.$digest();
      });

      scope.$on('VehicleReset', function () {
        graphs = {};
        scope.graphList = [];
        scope.$digest();
      });

      scope.$on('app:resized', function (event, data) {
        canvas.width = data.width;
        canvas.height = data.height;
      });
    }
  }
}])