angular.module('beamng.apps')
.directive('simplePerfTimers', ['$log', 'bngApi', 'StreamsManager', 'UiUnits', function ($log, bngApi, StreamsManager, UiUnits) {
  return {
    template: `
      <div style="width:100%; height:100%; background-color: rgba(0, 0, 0, 0.7); color: white" layout="column">
        <div flex style="overflow-y:auto">
          <table style="width:100%">
            <thead>
              <tr>
                <th><b>Type</b></th> 
                <th><b>Start</b></th> 
                <th><b>End</b></th> 
                <th><b>Time</b></th> 
                <th><b>Distance</b></th> 
              </tr>
            </thead>
            <tbody style="text-align:center">
              <tr ng-repeat="row in timers">
                <td>{{ row.type }}</td> 
                <td>{{ row.start }}</td> 
                <td>{{ row.stop }}</td> 
                <td>{{ row.time }}</td> 
                <td>{{ row.distance }}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div style="min-height:1em;">{{ msg.test }}<br>{{ msg.abort }}</div>
      </div>`,
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      var streamsList = ['electrics', 'sensors', 'stats'];
      StreamsManager.add(streamsList);
      scope.$on('$destroy', function () {
        $log.debug('<simple-perf-timers> destroyed');
        StreamsManager.remove(streamsList);
      });

      scope.timers = [];

      var timerSpeedLimit = 100 / 3.6; // More or less..

      var speedMargin     = 0.5
        , wheelTimerState = 0
        , wheelTimer      = 0
        , prevTime = 0
        , curTime  = 0
      ;

      var startPos, startVelo, stopVelo, aborted,  testing;
      scope.msg = {
        test: '',
        abort: ''
      };

      var _distanceUnit_;

      var _getDistanceString_ = function (m) {
        //console.log('unit is:', _distanceUnit_);
        switch (_distanceUnit_) {
          case 'metric':
            return `${m.toFixed(2)} m`
          case 'imperial':
            return `${(3.2808399 * m).toFixed(2)} ft`;
          default:
            return '---';
        }
      };

      var appendTimerRow = function (type, start, stop, time, distance) {
        scope.$evalAsync(function () {
          scope.timers.unshift({
            type: type,
            start: UiUnits.buildString('speed', start, 0),
            startRaw: start,
            stop: UiUnits.buildString('speed', stop, 0),
            stopRaw: stop,
            time: time.toFixed(2) + ' s',
            distance:  _getDistanceString_(distance),
            distanceRaw: distance
          });
        });
      };

      var changeRowsSystem = function () {
        scope.$evalAsync(function () {
          scope.timers.forEach(row => {
            row.start = UiUnits.buildString('speed', row.startRaw, 0),
            row.stop = UiUnits.buildString('speed',  row.stopRaw, 0),
            row.distance = _getDistanceString_(row.distanceRaw)
          });
        });                     
      };

      scope.$on('SettingsChanged', function (event, data) {
        _distanceUnit_ = data.values.uiUnitLength;
        changeRowsSystem();
      });


      scope.$on('streamsUpdate', function (event, streams) {
        var throttle = streams.electrics.throttle_input
          , brake = streams.electrics.brake
          , position = streams.sensors.position
          , airspeed = UiUnits.speed(streams.electrics.airspeed).val
        ;

        prevTime = curTime;
        curTime = performance.now();
        var dt = (curTime - prevTime) / 1000;

        testing = ' ';
        aborted = ' ';

        // Speed testing.
        if (throttle > 0.5 && airspeed > speedMargin && airspeed < 3*speedMargin && wheelTimerState === 0 ) {
          wheelTimerState = 1;
          wheelTimer = 0;
          startPos = position;
          startVelo = streams.electrics.airspeed;
          aborted = ' ';
          testing = ' ';
        } else if (wheelTimerState == 1) {
          wheelTimer += dt;

          if (streams.electrics.airspeed >= timerSpeedLimit) {
            var stopPos = position;
            stopVelo = streams.electrics.airspeed;
            var distance = Math.sqrt(Math.pow((stopPos.x - startPos.x), 2) + Math.pow((stopPos.y - startPos.y), 2) + Math.pow((stopPos.z - startPos.z), 2));
            wheelTimerState = 0;
            testing = ' ';
            appendTimerRow('Speed', startVelo, stopVelo, wheelTimer, distance);
          }

          if (throttle < 0.3) {
            aborted = 'Aborted: Throttle < 0.3';
            wheelTimerState = 0;
          }
        }
        if (wheelTimerState == 1) {
          testing = `Speed testing... ${UiUnits.buildString('speed', streams.electrics.airspeed, 2)}, ${wheelTimer.toFixed(2)} s`;
        }

        // Brake testing
        if (brake > 0.5 && airspeed > 10 - speedMargin && wheelTimerState === 0) {
          wheelTimerState = 3;
          wheelTimer = 0;
          startPos = position;
          startVelo = streams.electrics.airspeed;
          aborted = ' ';
          testing = ' ';
        } else if (wheelTimerState == 3) {
          wheelTimer += dt;

          if (airspeed < speedMargin) {
            var stopPos2 = position;
            stopVelo = streams.electrics.airspeed;
            var distance2 = Math.sqrt(Math.pow((stopPos2.x - startPos.x), 2) + Math.pow((stopPos2.y - startPos.y), 2)  + Math.pow((stopPos2.z - startPos.z), 2));
            wheelTimerState = 0;
            testing = ' ';
            appendTimerRow('Brake', startVelo, stopVelo, wheelTimer, distance2);
          }

          if (brake < 0.5) {
            aborted = 'Aborted: Brake < 0.5';
            wheelTimerState = 0;
          }
        }

        if (wheelTimerState == 3) {
          testing = `Brake testing... ${UiUnits.buildString('speed', streams.electrics.airspeed, 2)}, ${wheelTimer.toFixed(2)} s`;
        }

        scope.$evalAsync(function () {
          scope.msg = {test: testing, abort: aborted};
          if (aborted !== ' ') {
            console.log('[PerfTimerApp] ', aborted);
          }
        });
      });

      // make sure we know the unit system for distance (it is handled manually, outside UiUnits service).
      bngApi.engineLua('settings.requestState()');

      scope.$on('$destroy', function () {
        $log.debug('<simple-perf-timers> destroyed');
        StreamsManager.remove(streamsList);
      });
    }
  }
}])
