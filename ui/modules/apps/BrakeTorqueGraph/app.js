angular.module('beamng.apps')
.directive('brakeTorqueGraph', ['$log', 'StreamsManager', 'Utils', function ($log, StreamsManager, Utils) {
  return {
    restrict: 'E',
    template:
    `<div style="height:100%; font-family:Consolas,Monaco,Lucida Console,Liberation Mono;">
      <div layout="column" style="position: absolute; top: 10px; left: 5px; font-weight:bold;">
        <small ng-repeat="graph in graphList" style="color:{{ graph.color }}; padding:2px">{{ graph.title }}</small>
      </div>
      <canvas></canvas>
    <div>`,

    replace: true,
    link: function (scope, element, attrs) {
      var TAG = '[beamng.apps:brakeTorqueGraph]';

      var streamsList = ['wheelInfo', 'electrics'];
      StreamsManager.add(streamsList);
      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      colors = [];
      for (var i=15; i>0; i--) {
        var c = Utils.rainbow(15, i);
        colors.push(`rgb(${Math.round(255 * c[0])}, ${Math.round(255 * c[1])}, ${Math.round(255 * c[2])})`);
      }

      var graphs = {};
      scope.graphList = [{title: 'Speed', color: colors[0]}];

      var canvas = element[0].getElementsByTagName('canvas')[0];

      var chart = new SmoothieChart({
          minValue: 0.0,
          // maxValue: 1500,
          millisPerPixel: 20,
          interpolation: 'linear',
          grid: { fillStyle: 'rgba(250, 250, 250, 0.8)', strokeStyle: 'transparent', verticalSections: 6, millisPerLine: 1000, sharpLines: true },
          labels: {fillStyle: 'black'}
        })
        , speedGraph = new TimeSeries()

      var globalMax = 2000;

      chart.addTimeSeries(speedGraph,   {strokeStyle: colors[0], lineWidth: 2});
      chart.streamTo(canvas, 40);

      scope.$on('streamsUpdate', function (event, streams) {
        var xPoint = new Date();
        speedGraph.append(xPoint, streams.electrics.airspeed * 15);
        globalMax = Math.max(globalMax, streams.electrics.airspeed * 15);

        // The wheel sensors can break, don't take the format of incoming data for granted!

        for (var w in streams.wheelInfo) {
          var wheelName = streams.wheelInfo[w][0];
          if (!graphs.hasOwnProperty(wheelName)) {
            // Use $digest here instead of $evalAsync or similar, otherwise there is no guarantee that
            // the colors will change as intended. This will be called very few times (as many as the number of the wheels)
            // so there should be no noticeable performance penalty.
            graphs[wheelName] = new TimeSeries();
            $log.debug(`${TAG} adding graph for ${wheelName}`);
            var wheelColor = colors[scope.graphList.length % colors.length];
            scope.graphList.push({title: wheelName, color: wheelColor});  
            chart.addTimeSeries(graphs[wheelName], {strokeStyle: wheelColor, lineWidth: 2});  
            scope.$digest();
            return;
          }

          graphs[wheelName].append(xPoint, streams.wheelInfo[w][8]);
          globalMax = Math.max(globalMax, streams.wheelInfo[w][8]);
        }

        chart.options.maxValue = globalMax;
      });

      scope.$on('VehicleReset', function (event, data) {
        graphs = {};
        scope.graphList = [{title: 'Speed', color: colors[0]}];
        scope.$digest();
      });

      scope.$on('VehicleChange', function (event, data) {
        graphs = {};
        scope.graphList = [{title: 'Speed', color: colors[0]}];
        scope.$digest();
      });
      
      scope.$on('app:resized', function (event, data) {
        canvas.width = data.width;
        canvas.height = data.height;
      });
    }
  };
}]);
