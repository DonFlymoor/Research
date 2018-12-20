angular.module('beamng.apps')
.directive('forceFeedbackGraph', function () {
  return {
    restrict: 'E',
    template: `
      <div>
        <canvas width="400" height="160"></canvas>
        <div class="md-caption" style="padding: 2px; color: silver; position: absolute; top: 0; left: 0; width: auto; height: auto; background-color: rgba(50, 50, 50, 0.9)" layout="column">
          <md-checkbox style="margin:0px" ng-model="showForces">Force</md-checkbox>
          <span ng-show="showForces" layout="column">
              <span style="color: #FD9393; margin:0px">At driver: {{ sensors.ffbAtDriver }}</span>
              <span style="color: #FF4343; margin:0px">At wheel: {{ sensors.ffbAtWheel }}</span>
              <span style="color: #992343; margin:0px">Limit: &plusmn;{{ sensors.maxffb }}</span>
              <!--<span style="margin:0px">,</span>-->
          </span>
          <md-checkbox style="margin:0px" ng-model="showRates">Rate</md-checkbox>
          <span ng-show="showRates" layout="column">
              <span style="color: #c1d9f0; margin:0px">Limit: {{ sensors.maxffbRate }}Hz</span>
          </span>
          <md-checkbox style="margin:0px" ng-model="showInput">Input</md-checkbox>
          <span ng-show="showInput" layout="column">
              <span style="color: #A8DD73; margin:0px">Steering: {{ input }}%</span>
          </span>
        </div>
      </div>`,
    replace: true,
    link: function (scope, element, attrs) {
      scope.showRates = true;
      scope.showForces = true;
      scope.showInput = true;
      var canvas = element[0].children[0];
      var chart = new SmoothieChart({
          minValue: -1.0,
          maxValue: 1.0,
          millisPerPixel: 20,
          interpolation: 'linear',
          grid: { fillStyle: 'rgba(0,0,0,0.43)', strokeStyle: 'black', verticalSections: 4, millisPerLine: 1000, sharpLines: true }
        })
        , ffbAtDriverGraph=new TimeSeries()
        , ffbAtWheelGraph= new TimeSeries()
        , maxRateGraph   = new TimeSeries()
        , steerGraph     = new TimeSeries()
        , maxffbGraphPos = new TimeSeries()
        , maxffbGraphNeg = new TimeSeries()
        , maxRateLine   = { strokeStyle: '#c1d9f0', lineWidth: 2 }
        //, maxRateLine   = { strokeStyle: '#c1d9f0', lineWidth: 2, fillStyle:'rgba(115, 168, 221, 0.2)' }
        , steerLine     = { strokeStyle: '#A8DD73', lineWidth: 3 }
        , maxffbLinePos = { strokeStyle: '#992343', lineWidth: 1 }
        , maxffbLineNeg = { strokeStyle: '#992343', lineWidth: 1 }
        , ffbAtDriverLine={ strokeStyle: '#FD9393', lineWidth: 2 }
        , ffbAtWheelLine= { strokeStyle: '#FF4343', lineWidth: 2 }
        , ffbScale      = 10.0
        , ffbRateScale  = 2000.0
      ;

      chart.addTimeSeries(maxRateGraph,   maxRateLine);
      chart.addTimeSeries(steerGraph,     steerLine);
      chart.addTimeSeries(maxffbGraphPos, maxffbLinePos);
      chart.addTimeSeries(maxffbGraphNeg, maxffbLineNeg);
      chart.addTimeSeries(ffbAtDriverGraph,            ffbAtDriverLine);
      chart.addTimeSeries(ffbAtWheelGraph,      ffbAtWheelLine);
      chart.streamTo(canvas, 40);

      scope.sensors = {
        maxffbRate: 0,
        maxffb: 0,
        ffbAtDriver: 0,
        ffbAtWheel: 0,
      };
      scope.input = 0;

      var dirtycount = 0;
      var lasttime = new Date();
      scope.$on('streamsUpdate', function (event, streams) {
        if (scope.showRates) {
          maxRateGraph.append(new Date(), (2.0*streams.sensors.maxffbRate / ffbRateScale) - 1); // desired ffb rate (according to binding setting and measured hardware ffb call speeds)
        }
        if (scope.showInput) {
          steerGraph.append(new Date(), streams.electrics.steering_input);   // current steering
        }
        if (scope.showForces) {
          maxffbGraphPos.append(new Date(),  streams.sensors.maxffb / ffbScale); // ffb limit (from binding settings)
          maxffbGraphNeg.append(new Date(), -streams.sensors.maxffb / ffbScale); // ffb limit (from binding settings)
          ffbAtDriverGraph.append(new Date(),  streams.sensors.ffbAtDriver / ffbScale); // current ffb, corrected against FFB response curve
          ffbAtWheelGraph.append(new Date(),  streams.sensors.ffbAtWheel    / ffbScale); // current ffb
        }

        var dirty = false;
        for (var key in scope.sensors) {
            if (streams.sensors[key] !== undefined && scope.sensors[key] != streams.sensors[key].toFixed(1)) {
                dirty = true;
                break;
            }
        }
        if (streams.electrics.steering_input !== undefined && scope.input != (streams.electrics.steering_input*100).toFixed(0)) dirty = true;

        if (dirty) {
          scope.$apply(() => {
            for (var key in scope.sensors) {
              if (streams.sensors[key] !== undefined) {
                scope.sensors[key] = streams.sensors[key].toFixed(1);
              }
            }
            if (streams.electrics.steering_input !== undefined) {
              scope.input = (streams.electrics.steering_input*100).toFixed(0);
            }
          });
        }
      });

      scope.$on('app:resized', function (event, data) {
        canvas.width = data.width;
        canvas.height = data.height;
      });
    }
  };
})
