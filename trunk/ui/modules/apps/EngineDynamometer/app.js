angular.module('beamng.apps')
.directive('engineDynamometer', ['StreamsManager', 'UiUnits', function (StreamsManager, UiUnits) {
  return {
    template:
        `<div style="height:100%; font-family:Consolas,Monaco,Lucida Console,Liberation Mono; background-color:rgba(255,255,255,0.9)">
          <div layout="column" style="position: absolute; top: 20px; left: 70px; font-weight:bold;">
            <small style="color:#000000; padding:2px">Torque (Flywheel)</small>
            <small style="color:#FF0000; padding:2px">Power (Flywheel)</small>
            <small style="color:#FF4400; padding:2px">Power (Wheels)</small>
            <small style="color:#0000FF; padding:2px">RPM</small>
          </div>

          <div layout="row" layout-align="start end">
            <div >
              <div style="padding: 0; left: -35px; bottom: 50%; transform: rotate(-90deg); position: absolute">
                Power ({{powerUnit}})
              </div>
              <div layout="column" ng-repeat="l in tickLabels" style="text-align: center; left:30px; position: absolute; top: {{ $index*tickSpacing }}px">
                {{ (globalMax - $index*tickInterval).toFixed(0) }}
              </div>
            </div>
            <canvas style="position: relative; top:10px; left: 60px"></canvas>
            <div >
              <div style="right: -35px; bottom: 50%; transform: rotate(90deg); position: absolute;">
                Torque ({{torqueUnit}})
              </div>
              <div layout="column" ng-repeat="l in tickLabels" style="text-align: justify; right:40px; position: absolute; top: {{ $index*tickSpacing }}px">
                {{ (globalMax - $index*tickInterval).toFixed(0) }}
              </div>
            </div>
          </div>
        </div>`,
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      var streamsList = ['engineInfo'];
      StreamsManager.add(streamsList);
      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      scope.tickLabels = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
      scope.globalMax = 0;

      // scope.globalMin = 0;

      var chart = new SmoothieChart({
          minValue: 0,
          maxValue: 1000,
          millisPerPixel: 20,
          interpolation: 'bezier',
          grid: { fillStyle: 'rgba(250,250,250,0.2)', strokeStyle: 'grey', verticalSections: 20, millisPerLine: 1000, sharpLines: true },
          labels: {disabled: true}
        })
        , torqueGraph = new TimeSeries()
        , powerGraph = new TimeSeries()
        , powerWheelGraph = new TimeSeries()
        , rpmGraph = new TimeSeries()
      ;

      var canvas = element[0].getElementsByTagName('canvas')[0];

      scope.tickSpacing = canvas.height / 10;
      //var powerFactor = Math.PI * 1.341 / 30000;
      chart.addTimeSeries(torqueGraph,        {strokeStyle: '#000000', lineWidth: 1.5});
      chart.addTimeSeries(powerGraph, {strokeStyle: '#FF0000', lineWidth: 1.5});
      chart.addTimeSeries(powerWheelGraph, {strokeStyle: '#FF4400', lineWidth: 1.5});
      chart.addTimeSeries(rpmGraph,       {strokeStyle: '#0000FF', lineWidth: 1.5});
      chart.streamTo(canvas, 40);

      scope.$on('streamsUpdate', function (event, streams) {
        if (streams) {
          var xPoint = new Date();
          var torque = UiUnits.torque(streams.engineInfo[8]).val
            , power  = UiUnits.power(streams.engineInfo[4] * 0.104719755 * streams.engineInfo[8] / 1000 * 1.34102).val
            //, power  = streams.engineInfo[4] * torque * powerFactor
            , wheelPower  = UiUnits.power(streams.engineInfo[20] / 1000 * 1.34102).val
            //, wheelPower  = streams.engineInfo[20] / 1000 * 1.34102
            , rpm    = streams.engineInfo[4] / 10;

            scope.torqueUnit = UiUnits.torque().unit;
            scope.powerUnit = UiUnits.power().unit;
          // scope.torqueUnit = ;


          scope.$applyAsync(function () {
            scope.globalMax = Math.ceil(Math.max.apply(null, [scope.globalMax, torque, power]) / 100) * 100;
            //scope.globalMin = Math.floor(Math.min.apply(null, [scope.globalMin, torque, power, rpm]) / 100) * 100;
            // scope.globalMin = 0;
            scope.tickInterval = (scope.globalMax - /*scope.globalMin*/ 0) / 10;
          });
          chart.options.maxValue = scope.globalMax;
          // chart.options.minValue = scope.globalMin;

          torqueGraph.append(xPoint, torque);
          powerGraph.append(xPoint, power);
          powerWheelGraph.append(xPoint, wheelPower);
          rpmGraph.append(xPoint, rpm);
        }
      });

      scope.$on('app:resized', function (event, data) {
        canvas.width = data.width - 130;
        canvas.height = data.height - 20;
        scope.tickSpacing = canvas.height / 10;
      });

    }
  }
}])