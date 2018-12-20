angular.module('beamng.apps')
.directive('tcsDebugGraph', ['StreamsManager', function (StreamsManager) {
  return {
    template:
        '<div style="font-family:Consolas,Monaco,Lucida Console,Liberation Mono;">' +
          '<div layout="column" style="position: absolute; top: 0; left: 5px;">' +
            '<small style="color:#FF6F00; padding:2px">Slip FL</small>'+
            '<small style="color:#00B1A4; padding:2px">Slip FR</small>'+
            '<small style="color:#5BE600; padding:2px">Slip RL</small>'+
            '<small style="color:#ED003B; padding:2px">Slip RR</small>'+
            '<small style="color:#353A39; padding:2px">Slip Threshold</small>'+
          '</div>' +
          '<canvas></canvas>' +
        '</div>',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      var streamsList = ['tcsData'];
      StreamsManager.add(streamsList);
      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      var canvas = element[0].getElementsByTagName('canvas')[0];

      var chart = new SmoothieChart({
          minValue: 0.0,
          maxValue: 1.0,
          millisPerPixel: 20,
          interpolation: 'bezier',
          grid: { fillStyle: 'rgba(250,250,250,0.8)', strokeStyle: 'transparent', verticalSections: 0, millisPerLine: 1000, sharpLines: true },
          labels: {fillStyle: 'black'}
        })
        , thresholdGraph = new TimeSeries()
        , wheelsGraphs = { 'RL': new TimeSeries(),
                           'RR': new TimeSeries(),
                           'FL': new TimeSeries(),
                           'FR': new TimeSeries() }
      ;

      chart.addTimeSeries(thresholdGraph, {strokeStyle: '#353A39', lineWidth: 1.0});
      chart.addTimeSeries(wheelsGraphs['RL'], {strokeStyle: '#5BE600', lineWidth: 1.5});
      chart.addTimeSeries(wheelsGraphs['RR'], {strokeStyle: '#ED003B', lineWidth: 1.5});
      chart.addTimeSeries(wheelsGraphs['FL'], {strokeStyle: '#FF6F00', lineWidth: 1.5});
      chart.addTimeSeries(wheelsGraphs['FR'], {strokeStyle: '#00B1A4', lineWidth: 1.5});
      chart.streamTo(canvas, 40);


      scope.$on('streamsUpdate', function (event, streams) {
        if (streams.tcsData) {
          var xPoint = new Date();

          thresholdGraph.append(xPoint, streams.tcsData.slipThreshold);
          for (var wheel in streams.tcsData.wheelSlips)
            wheelsGraphs[wheel].append(xPoint, streams.tcsData.wheelSlips[wheel]);
        }
      });

      scope.$on('app:resized', function (event, data) {
        canvas.width = data.width;
        canvas.height = data.height;
      });
    }
  }
}])