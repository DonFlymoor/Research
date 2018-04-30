angular.module('beamng.stuff')

.controller('PlayModesController', ['AppDefaults', function (AppDefaults) {
  var vm = this;
  vm.list = AppDefaults.playModes;

  vm.openRepo = function () {
    window.location.href = 'http-external://www.beamng.com/resources/?ingame=2';
  };

}]);