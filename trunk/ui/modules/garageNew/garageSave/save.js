angular.module('beamng.garage')

.controller('garageSave', ['$scope', 'logger', 'bngApi', '$state', 'Utils', 'SimpleStateNav', function ($scope, logger, bngApi, $state, Utils, SimpleStateNav) {
  var vm = this;

  vm.configList = [];

  bngApi.activeObjectLua('partmgmt.getConfigList()', (configs) => {
    $scope.$evalAsync(() => {
      vm.configList = configs;
    });
  });

  vm.setAsDefault = () => bngApi.activeObjectLua('partmgmt.savedefault();');

  vm.save = () => bngApi.activeObjectLua(`partmgmt.saveLocal("${vm.filename}.pc")`);

  vm.disableBtn = true;

  vm.shouldBtnDisable = () => {
    vm.fileExists = vm.configList.indexOf(`${vm.filename}.pc`) !== -1;
    vm.disableBtn = vm.filename.length < 1;
  };

  vm.back = SimpleStateNav.back;

  vm.unloadGarage = () => {
    bngApi.engineLua('extensions.unload("ui_garage");');
  };
}]);