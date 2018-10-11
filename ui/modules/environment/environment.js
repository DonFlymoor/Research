angular.module('beamng.stuff')

/**
 * @ngdoc controller
 * @name beamng.stuff.controller:EnvironmentController
 * @description Environment controller
 */
.controller('EnvironmentController', ['$scope', 'bngApi', 'Environment', 'EnvironmentPresets',
 function($scope, bngApi, Environment, EnvironmentPresets) {
  var vm = this;
  vm.currentWeatherPreset;
  vm.weatherPresets;
  Environment.update();
  Environment.registerScope($scope, () => { $scope.$evalAsync(); });

  bngApi.engineLua('core_weather.getPresets()',
    (data) => {
      $scope.$evalAsync(() => {
        vm.weatherPresets = data
      })
    }
  )

  bngApi.engineLua('core_weather.getCurrentWeatherPreset()',
    (data) => {
      $scope.$evalAsync(() => {
        vm.currentWeatherPreset = data
      })
    }
  )

  vm.switchWeather = function(preset){
    bngApi.engineLua('core_weather.switchWeather("'+ preset +'")')
    vm.currentWeatherPreset = preset;
  }

  vm.service = Environment;
  vm.presets = EnvironmentPresets;
}]);
