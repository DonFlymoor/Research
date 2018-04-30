angular.module('beamng.apps')
.directive('advancedWheelsDebug', ['UiUnits', function (UiUnits) {
  return {
    template: 
    `<div style="height:100%; width:100%;" class="bngApp">
      <label layout="row" layout-align="start center">
          <div ng-if="data.advancedWheelDebugData">
            <div class="md-padding">
              <table style="width:100%">
                <thead>
                  <tr style ="text-align: justify;">
                    <th style="width: 25%">Name</th><th style="width: 25%">Camber</th><th style="width: 25%">Toe</th><th style="width: 25%">Caster</th><th style="width: 25%">SAI</th>
                  </tr>
                </thead>
                <tr ng-repeat="w in data.advancedWheelDebugData | orderBy: 'name' track by $index">
                  <td class="md-body-2">{{ w.name }}</td>
                  <td class="md-body-1">{{ w.camber | number: 3 }}</td>
                  <td class="md-body-1">{{ w.toe | number: 3 }}</td>
                  <td class="md-body-1">{{ w.caster | number: 3 }}</td>
                  <td class="md-body-1">{{ w.sai | number: 3 }}</td>
                </tr>
              </table>
            </div>
          </div>
      </label> 
    </div>`,
    replace: true,
    restrict: 'EA',
    scope: true,
    controller: ['$log', '$scope', 'bngApi', 'StreamsManager', function ($log, $scope, bngApi, StreamsManager) {
      var streamsList = ['advancedWheelDebugData'];
      StreamsManager.add(streamsList);

      function register() {
        bngApi.activeObjectLua('extensions.advancedwheeldebug.registerDebugUser("advancedWheelDebugApp", true)');
      }

      register();
          
      $scope.$on('streamsUpdate', function (event, data) {
        $scope.$evalAsync(function () {
          $scope.data = data;
        });
      });

      $scope.$on('VehicleReset', register);
      $scope.$on('VehicleChange', register);

      $scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
        bngApi.activeObjectLua('extensions.advancedwheeldebug.registerDebugUser("advancedWheelDebugApp", false)');
      });

    }]
  };
}]);