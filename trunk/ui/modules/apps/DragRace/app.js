angular.module('beamng.apps')
.directive('dragRace', ['StreamsManager', 'InstalledContent', 'Vehicles', '$q', 'bngApi', '$timeout', '$rootScope', function (StreamsManager, InstalledContent, Vehicles, $q, bngApi, $timeout, $rootScope) {
  return {
    templateUrl: 'modules/apps/Dragrace/app.html',
    replace: true,
    link: function (scope, element, attrs) {
      var vm = this;
      var streamsList = ['sensors'];
      StreamsManager.add(streamsList);
      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      scope.model = '';
      scope.config = '';

      scope.$on('simpleVehicleList', (ev, data) => {
        scope.data = {};
        for (var key in data) {
          scope.data[data[key].key] = data[key];
        }
      });

      scope.addVehicle = function(mode, model, config) {
        var fallback = $timeout(() => {
          // if the car isn't spawned by now it will probably not spawn at all, so remove the waiting sign
          $rootScope.$broadcast('app:waiting', false);
        }, 3000);

        $rootScope.$broadcast('app:waiting', true, function () {
          bngApi.engineLua(`freeroam_dragRace.selectOpponent(${bngApi.serializeToLua({config})})`, function() {
            $timeout($rootScope.$broadcast('app:waiting', false));
            $timeout.cancel(fallback);
          });
        });
      }

      scope.$on('DragRaceMsg', function(evt, data) {
        scope.$evalAsync(function() {
          scope.msg = data;
        })
      });

      scope.$on('DragRaceResult', function(evt, data) {
        console.log(data);
        scope.$evalAsync(function() {
          scope.results = data;
        })
      });

      bngApi.engineLua('core_vehicles.requestSimpleVehicleList()');

    }
  };
}]);