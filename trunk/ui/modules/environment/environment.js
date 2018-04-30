angular.module('beamng.stuff')

/**
 * @ngdoc controller
 * @name beamng.stuff.controller:EnvironmentController
 * @description Environment controller
 */
.controller('EnvironmentController', ['$scope', 'bngApi', 'Environment', 'EnvironmentPresets',
 function($scope, bngApi, Environment, EnvironmentPresets) {
  Environment.update();
  Environment.registerScope($scope, () => { $scope.$evalAsync(); });
  
  var vm = this;
  vm.service = Environment;
  vm.presets = EnvironmentPresets;
}]);
