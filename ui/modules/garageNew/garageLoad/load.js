angular.module('beamng.garage')

.controller('garageLoad', ['$scope', 'logger', 'bngApi', '$state', 'Vehicles', function ($scope, logger, bngApi, $state, Vehicles) {
  var vm = this;

  vm.list = [];

  bngApi.engineLua('core_vehicles.requestPcList()');

  $scope.$on('customVehicleList', (ev, data) => {
    $scope.$evalAsync(() => {
      vm.list = data;
    });
  });

  vm.current = 0;

  vm.select = (i) => vm.current = i;

  vm.load = (i) => {
    var short = vm.list[i === undefined ? vm.current : i];
    Vehicles.addToGame(short.model_key, short.key);
  };
}]);