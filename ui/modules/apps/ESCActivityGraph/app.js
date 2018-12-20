angular.module('beamng.apps')
.directive('escActivityGraph', ['StreamsManager', function (StreamsManager) {
  return {
    template:
        '<div style="font-family:Consolas,Monaco,Lucida Console,Liberation Mono;">' +
          '<div layout="column" style="position: absolute; top: 0; left: 5px;">' +
            '<small style="color:#0F51BA; padding:2px">Yaw</small>' +
            '<small style="color:#15DA00; padding:2px">Desired Yaw</small>'+
            '<small style="color:#FB000D; padding:2px" >Difference</small>'+
          '</div>' +
          '<canvas></canvas>' +
        '</div>',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      var streamsList = ['escData'];
      StreamsManager.add(streamsList);
      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      var chart = new SmoothieChart({
          minValue: -1.3,
          maxValue: 1.3,
          millisPerPixel: 20,
          interpolation: 'bezier',
          grid: { fillStyle: 'rgba(250,250,250,0.8)', strokeStyle: 'transparent', verticalSections: 0, millisPerLine: 1000, sharpLines: true },
          labels: {fillStyle: 'black'}
        })
        , yawGraph = new TimeSeries()
        , desiredYawGraph = new TimeSeries()
        , desiredYawAccelerationGraph = new TimeSeries()
        , desiredYawSteeringGraph = new TimeSeries()
        , diffGraph = new TimeSeries()
        , steeringGraph = new TimeSeries()
      ;

      var canvas = element[0].getElementsByTagName('canvas')[0];

      chart.addTimeSeries(yawGraph,                     {strokeStyle: '#0F51BA', lineWidth: 1.5});
      chart.addTimeSeries(desiredYawGraph,              {strokeStyle: '#15DA00', lineWidth: 1.5});
      chart.addTimeSeries(desiredYawAccelerationGraph,  {strokeStyle: '#0D8D00', lineWidth: 1.5});
      chart.addTimeSeries(desiredYawSteeringGraph,      {strokeStyle: '#64E357', lineWidth: 1.5});
      chart.addTimeSeries(diffGraph,                    {strokeStyle: '#FB000D', lineWidth: 1.5});
      chart.streamTo(canvas, 40);

      scope.$on('streamsUpdate', function (event, streams) {
        if (streams.escData) {
          var xPoint = new Date();
          yawGraph.append(xPoint, streams.escData.yawRate);
          desiredYawGraph.append(xPoint, streams.escData.desiredYawRate);
          desiredYawAccelerationGraph.append(xPoint, streams.escData.desiredYawRateAcceleration);
          desiredYawSteeringGraph.append(xPoint, streams.escData.desiredYawRateSteering);
          diffGraph.append(xPoint, streams.escData.difference);
        }
      });

      scope.$on('app:resized', function (event, data) {
        canvas.width = data.width;
        canvas.height = data.height;
      });
    }
  }
}])