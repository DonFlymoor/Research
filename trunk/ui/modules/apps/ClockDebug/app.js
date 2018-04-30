angular.module('beamng.apps')
.directive('clockDebug', ['bngApi', function (bngApi) {
  return {
    template: 
      `<div style="font-family:Consolas,Monaco,Lucida Console,Liberation Mono;">
        <div layout="column" style="position: absolute; top: 0; left: 5px;"> 
          <small style="color:white; padding:2px"><span style="background-color: rgba(0,0,0,0.8);">Clock Type: {{clockType}}, {{fps | number: 1}} fps, {{1000/fps | number: 1}} ms</span></small>
          <small ng-repeat="graph in graphList" style="color:{{ ::graph.color }}; padding:2px"><span style="background-color: rgba(0,0,0,0.8);">{{ ::graph.title }}: {{ rollingAvg[graph.key] }}{{ ::graph.unit }}</span></small>
        </div>
        <canvas></canvas>
      <div>`,
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      var WINDOW_SIZE = 10
        , STEP_SIZE = 10
        , rollingAvg = {}
      ;
      scope.rollingAvg = {}; // The data to be displayed in the legend


      var canvas = element[0].getElementsByTagName('canvas')[0];
      var chart = null;
      var graphs = {};
      var startTime = 0;

      scope.$on('clockDebugInit', function (event, data) {
        chart = new SmoothieChart({
          millisPerPixel: 10,
          interpolation: 'bezier',
          grid: { fillStyle: 'rgba(0,0,0,0.43)', strokeStyle: 'transparent', verticalSections: 10, millisPerLine: 1000, sharpLines: true },
          labels: {fillStyle: 'lightgrey', precision: 3, fontSize:12}
        });
        scope.graphList = [];
        scope.clockType = null;
        scope.fps = null;

        chart.streamTo(canvas, 150);
        graphs = {};
        startTime = new Date().getTime();
        scope.$evalAsync(function () {});
      });


      scope.$on('clockDebug', function (event, data) {
        if (!scope.graphList) return; // probably reloading the page, ignore data until we get the clockDebugInit event again
        var time = startTime + (data.now*1000);
        scope.clockType = data.clockType;
        scope.fps = data.fps;
        for (var counter in data.counters) {
          if (graphs[counter] == null) {
            scope.graphList.push({title: counter, color: data.counters[counter].color, key: counter, unit: data.counters[counter].unit });
            graphs[counter] = new TimeSeries()
            
            rollingAvg[counter] = {buffer: [], sum: 0.0, idx: 0, ticks: -1};
            scope.rollingAvg[counter] = '---';
            if (!data.counters[counter].lineWidth) data.counters[counter].lineWidth = 1;
            chart.addTimeSeries(graphs[counter], {strokeStyle:  data.counters[counter].color, lineWidth: data.counters[counter].lineWidth});
            scope.$digest();
            return;
          }
          
          graphs[counter].append(time, data.counters[counter].value);

          if (rollingAvg[counter].buffer.length < WINDOW_SIZE) {
            rollingAvg[counter].buffer.push(Math.abs(data.counters[counter].value));
            rollingAvg[counter].sum += Math.abs(data.counters[counter].value);
          } else {
            rollingAvg[counter].sum -= rollingAvg[counter].buffer[rollingAvg[counter].idx];
            rollingAvg[counter].sum += Math.abs(data.counters[counter].value);
            rollingAvg[counter].buffer[rollingAvg[counter].idx] = Math.abs(data.counters[counter].value);
            rollingAvg[counter].idx  = (rollingAvg[counter].idx + 1) % WINDOW_SIZE;
            rollingAvg[counter].ticks = (rollingAvg[counter].idx + 1) % STEP_SIZE;

            if (rollingAvg[counter].ticks === 0) {
              scope.rollingAvg[counter] = (rollingAvg[counter].sum / WINDOW_SIZE).toFixed(2);
            }
          }
        }
        scope.$evalAsync(function () {});
      });
      scope.$on('app:resized', function (event, data) {
        WINDOW_SIZE = 10;
        STEP_SIZE = 10;
        canvas.width = data.width;
        canvas.height = data.height;
      });      

      bngApi.engineLua('extensions.reload("core_clockDebug")');
      scope.$on('$destroy', function () {
          bngApi.engineLua('extensions.unload("core_clockDebug");');
      });
    }
  }
}])
