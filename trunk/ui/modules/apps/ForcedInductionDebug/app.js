angular.module('beamng.apps')
.directive('forcedInductionDebug', ['UiUnits', function (UiUnits) {
  return {
    template:`
      <div style="height: 100%; overflow: auto; background-color: rgba(255, 255, 255, 0.9)">
        <table cellpadding="3">
          <tr ng-repeat="m in measures | filter: valueDefined">
            <td valign="baseline" align="right">{{ ::m.name }} &nbsp; </td>
            <td valign="baseline" style="font-family: monospace; font-size: 1.2em">{{ m.val }}</td>
          </tr>
        </table>
      </div>`,
    replace: true,
    restrict: 'EA',
    scope: true,
    controller: ['$log', '$scope', 'bngApi', 'StreamsManager', function ($log, $scope, bngApi, StreamsManager) {
      var streamsList = ['forcedInductionInfo'];
      StreamsManager.add(streamsList);
      $scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      var init = function () {
        $scope.$evalAsync(function () {
          $scope.measures = [
            { name: 'RPM', key: 'rpm'},
            { name: 'Boost', key: 'boost', type: 'pressure'},
            { name: 'Power Coef', key: 'coef'},
            { name: 'Pressure Pulses',   key: 'pulses' },
            { name: 'SC Loss',           key: 'loss'},
            { name: 'Exhaust Power',     key: 'exhaustPower'},
            { name: 'Friction',          key: 'friction'},
            { name: 'Backpressure',      key: 'backpressure'},
            { name: 'Wastegate Factor',  key: 'wastegateFactor'},
            { name: 'Turbo Temp',        key: 'turboTemp', type: 'temperature'},
          ];  
        });
      };
      

      $scope.valueDefined = function (x) {
        return x.val !== undefined;
      };

      init();

      $scope.$on('VehicleReset', init);
      $scope.$on('VehicleFocusChanged', init);

      $scope.$on('streamsUpdate', function (event, streams) {
        if (streams.forcedInductionInfo) {
          $scope.$evalAsync(function () {
            $scope.measures.forEach((x) => {
              var val = streams.forcedInductionInfo[x.key];
              if (val !== undefined) {
                if (x.type !== undefined) {
                  val = UiUnits.buildString(x.type, val, 2);
                } else {
                  val = val.toFixed(2);
                }
                x.val = val;
              }
            });
          });
        }
      });

    }]
  };
}]);
