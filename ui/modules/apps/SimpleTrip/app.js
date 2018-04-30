(function () {
  'use strict';

  angular.module('beamng.apps')

    .directive('simpleTrip', ['logger', 'bngApi', 'StreamsManager', 'UiUnits', function (logger, bngApi, StreamsManager, UiUnits) {
      return {
        template: '<div class="bngApp" style="width:100%; height:100%; cursor: pointer;" layout="column" ng-click="changeMode()">' +
        '<div flex layout="column" layout-align="center center">' +
        '<span style="font-weight:bold; font-size:1.2em">{{ text }}</span>' +
        '</div>' +
        '<small style="text-align:center">{{ display }}</small>' +
        '<span style="position:absolute; top:2px; right: 2px" class="material-icons" ng-click="reset($event)">autorenew</span>' +
        '</div>',
        link: function (scope, element, attrs) {
          var streamsList = ['electrics', 'engineInfo'];
          StreamsManager.add(streamsList);
          scope.$on('$destroy', function () {
            StreamsManager.remove(streamsList);
          });

          var timer = 0
            , prevTime = performance.now()
            , curTime = prevTime
            , count = 0
            , totalDistance = 0
            , range = 0
            , avgSpeed = 0
            , fuelConsumptionRate = 0
            , avgFuelConsumptionRate = 0
            , previousFuel = 0
            ;

          var resetFlag = false;
          scope.reset = function ($event) {
            logger.debug('<simple-trip> resetting trip computer');
            timer = 0;
            prevTime = performance.now();
            curTime = prevTime;
            count = 0;
            totalDistance = 0;
            range = 0;
            avgSpeed = 0;
            fuelConsumptionRate = 0;
            avgFuelConsumptionRate = 0;
            previousFuel = 0;

            $event.stopPropagation();
          };

          var mode = parseInt(localStorage.getItem('apps:simpleTrip.mode')) || 0;
          logger.debug('mode is:', mode);

          scope.changeMode = function (targetMode) {
            if (targetMode !== undefined)
              mode = targetMode;
            else
              mode = (mode + 1) % 5;

            switch (mode) {
              case 0: scope.display = 'Total Distance'; break;
              case 1: scope.display = 'AVG Speed'; break;
              case 2: scope.display = 'AVG Fuel Consu.'; break;
              case 3: scope.display = 'Fuel Consumption'; break;
              case 4: scope.display = 'Range'; break;
            }

            localStorage.setItem('apps:simpleTrip.mode', mode);
          };


          scope.$emit('requestPhysicsState');

          // if physics is resumed, throw away timestamp from before, since the vehicle didn't move in the mean time
          // => no streamsupdate
          // => no new timestamp in the meantime
          // => curTime === timestamp from when physics was paused
          scope.$on('updatePhysicsState', function (event, data) {
            if (data) {
              curTime = performance.now();
            }
          });

          scope.$on('streamsUpdate', function (event, streams) {
            if (streams.electrics && streams.engineInfo) {
              var wheelSpeed = streams.electrics.wheelspeed;


              prevTime = curTime;

              curTime = performance.now();
              timer -= 0.001 * (curTime - prevTime);

              if (timer < 0) {
                totalDistance += ((1.0 - timer) * wheelSpeed);
                count++;
                avgSpeed += (wheelSpeed - avgSpeed) / count;

                if (previousFuel > streams.engineInfo[11] && (previousFuel - streams.engineInfo[11]) > 0.0002) {
                  fuelConsumptionRate = (previousFuel - streams.engineInfo[11]) / ((1 - timer) * streams.electrics.wheelspeed); // l/(s*(m/s)) = l/m
                } else {
                  fuelConsumptionRate = 0;
                }

                previousFuel = streams.engineInfo[11];
                range = fuelConsumptionRate > 0 ? UiUnits.buildString('distance', streams.engineInfo[11] / fuelConsumptionRate, 2) : (streams.electrics.wheelspeed > 0.1 ? 'Infinity' : UiUnits.buildString('distance', 0));
                avgFuelConsumptionRate += (fuelConsumptionRate - avgFuelConsumptionRate) / count;
                timer = 1;
              }

              scope.$evalAsync(() => {
                switch (mode) {
                  case 0:
                    scope.text = UiUnits.buildString('distance', totalDistance, 1);
                    break;

                  case 1:
                    scope.text = UiUnits.buildString('speed', avgSpeed, 1);
                    break;

                  case 2:
                    scope.text = UiUnits.buildString('consumptionRate', avgFuelConsumptionRate, 1);
                    break;

                  case 3:
                    scope.text = UiUnits.buildString('consumptionRate', fuelConsumptionRate, 1);
                    break;

                  case 4:
                    scope.text = range
                    break;
                }
              });
            }
          });

          // run on launch
          scope.changeMode(mode);
          setTimeout(function () {
            bngApi.engineLua('settings.requestState()');
          }, 500);

        }

      };
    }]);
})();