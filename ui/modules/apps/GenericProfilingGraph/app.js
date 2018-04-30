angular.module('beamng.apps')
.directive('genericProfilingGraph', ['StreamsManager', function (StreamsManager) {
  return {
    template: 
      `<div style="font-family:Consolas,Monaco,Lucida Console,Liberation Mono;">
        <div layout="column" style="position: absolute; top: 0; left: 5px;"> 
          <small ng-repeat="graph in graphList" style="color:{{ ::graph.color }}; padding:2px">{{ ::graph.title }} (AVG: {{ rollingAvg[graph.key] }} {{ ::graph.unit }})</small>
        </div>
        <canvas></canvas>
      <div>`,
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
      scope.rollingAvg = {}; // The data to be displayed in the legend


      var canvas = element[0].getElementsByTagName('canvas')[0];

      var chart = new SmoothieChart({
          minValue: 0,
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
              scope.graphList.push({title: streams.profilingData[data].title, color: streams.profilingData[data].color, key: data, unit: streams.profilingData[data].unit });
              graphs[data] = new TimeSeries()
              
              rollingAvg[data] = {buffer: [], sum: 0.0, idx: 0, ticks: -1};
              scope.rollingAvg[data] = '---';

              chart.addTimeSeries(graphs[data], {strokeStyle: streams.profilingData[data].color, lineWidth: 2});
              scope.$digest();
              return;
            }
            graphs[data].append(xPoint, streams.profilingData[data].value);

            if (rollingAvg[data].buffer.length < WINDOW_SIZE) {
              rollingAvg[data].buffer.push(streams.profilingData[data].value)
              rollingAvg[data].sum += streams.profilingData[data].value
            } else {
              rollingAvg[data].sum -= rollingAvg[data].buffer[rollingAvg[data].idx];
              rollingAvg[data].sum += streams.profilingData[data].value;
              rollingAvg[data].buffer[rollingAvg[data].idx] = streams.profilingData[data].value;
              rollingAvg[data].idx  = (rollingAvg[data].idx + 1) % WINDOW_SIZE;
              rollingAvg[data].ticks = (rollingAvg[data].idx + 1) % STEP_SIZE;

              if (rollingAvg[data].ticks === 0) {
                scope.rollingAvg[data] = (rollingAvg[data].sum / WINDOW_SIZE).toFixed(6);
              }
            }
          }

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