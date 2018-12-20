angular.module('beamng.apps')
.directive('engineHeatDebugGraph', ['StreamsManager', function (StreamsManager) {
  return {
    template:
      '<div style="font-family:Consolas,Monaco,Lucida Console,Liberation Mono;">' +
        '<div layout="column" style="position: absolute; top: 0; left: 5px;">' +
          '<small style="color:#333676; padding:2px">Water</small>' +
          '<small style="color:#AA8C39; padding:2px">Oil</small>' +
          '<small style="color:#378B2E; padding:2px">Block</small>' +
          '<small style="color:#A7383E; padding:2px">Exhaust</small>' +
        '</div>' +
        '<canvas></canvas>' +
      '</div>',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      var streamsList = ['engineThermalData'];
      StreamsManager.add(streamsList);
      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      var canvas = element[0].getElementsByTagName('canvas')[0];

      var chart = new SmoothieChart({
          minValue: 50,
          maxValue: 150,
          millisPerPixel: 40,
          interpolation: 'bezier',
          grid: { fillStyle: 'rgba(250,250,250,0.8)', strokeStyle: 'black', verticalSections: 0, millisPerLine: 0 },
          labels: {fillStyle: 'black'}
        })
        , coolantGraph = new TimeSeries()
        , oilGraph = new TimeSeries()
        , blockGraph = new TimeSeries()
        , exhaustGraph = new TimeSeries()
      ;

      chart.addTimeSeries(coolantGraph, {strokeStyle: '#333676', lineWidth: 1});
      chart.addTimeSeries(oilGraph, {strokeStyle: '#AA8C39', lineWidth: 1});
      chart.addTimeSeries(blockGraph, {strokeStyle: '#378B2E', lineWidth: 1});
      chart.addTimeSeries(exhaustGraph, {strokeStyle: '#A7383E', lineWidth: 1});
      chart.streamTo(canvas, 40);

      scope.$on('streamsUpdate', function (event, streams) {
        if (streams.engineThermalData) {
          var xPoint = new Date();
          coolantGraph.append(xPoint, streams.engineThermalData.coolantTemperature);
          oilGraph.append(xPoint, streams.engineThermalData.oilTemperature);
          blockGraph.append(xPoint, streams.engineThermalData.engineBlockTemperature);
          exhaustGraph.append(xPoint, streams.engineThermalData.exhaustTemperature);
        }
      });

      scope.$on('app:resized', function (event, data) {
        canvas.width = data.width;
        canvas.height = data.height;
      });
    }
  }
}])