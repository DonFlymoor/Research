angular.module('beamng.garage')

.controller('garageSelect', ['$scope', 'logger', 'bngApi', 'InstalledContent', 'Utils', 'Vehicles', '$state', function ($scope, logger, bngApi, InstalledContent, Utils, Vehicles, $state) {
  var vm = this;

  Vehicles.populate().then(() => {
    vm.perfKeyList = InstalledContent.vehicles.displayInfo.perfData;
    vm.overviewKeylist = InstalledContent.vehicles.displayInfo.filterData;
  });

  bngApi.engineLua('core_vehicles.requestSimpleVehicleList()');

  $scope.$on('simpleVehicleList', (ev, data) => {
    // just in case
    $scope.$evalAsync(() => {
      vm.models = data;

      vm.selectedConfigs = [];
    });
  });

  vm.getCurrentConfig = function () {
    if (vm.models && vm.models[vm.selectedModel] && vm.selectedConfigs[vm.selectedModel] !== undefined) {
      return vm.models[vm.selectedModel].configs[vm.selectedConfigs[vm.selectedModel]];
    }
  };

  vm.getCountry = function () {
    var shortHand = 
      { 'United States': 'USA'
      , 'Japan': 'JP'
      , 'Germany': 'GER'
      , 'Italy': 'IT'
      }
      , short = vm.getCurrentConfig()
    ;
    if (short && short.aggregates && short.aggregates.Country) {
      var help = Object.keys(short.aggregates.Country)[0];
      return shortHand[help] || help;
    }
    return '';
  }

  vm.keyExists = function (key, val) {
    if (val === undefined) {
      var short = vm.getCurrentConfig();
      if (short) {
        var aggType = short.aggregates[key];
        for (var propName in aggType) {
          if (short[key] === undefined) {
            if (InstalledContent.vehicles.displayInfo.ranges.all.indexOf(key) !== -1) {
              return aggType;
            } else {
              return propName;
            }
          }
        }
      }
    }
    return val;
  };

  vm.considerUnit = (e, v) => v !== undefined ? Vehicles.considerUnit(e, v, true) : 'Unknown';

  vm.isRealRange = (title) => InstalledContent.vehicles.displayInfo.ranges.real.indexOf(title) !== -1;

  var alreadyShown = ['Years', 'Value', 'Country', 'Source', 'Brand']; // 'Body Style'
  vm.showData = (title, performance) => alreadyShown.indexOf(title) === -1 && Vehicles.showData(title, true, performance);
  
  vm.sortByValue = (a, b) => a.aggregates && a.aggregates.Value && a.aggregates.Value.min && b.aggregates && b.aggregates.Value && b.aggregates.Value.min ? a.aggregates.Value.min - b.aggregates.Value.min : 1;

  $scope.down = () => console.warn('callback doesn\'t seem to be registered');
  $scope.up = () => console.warn('callback doesn\'t seem to be registered');
  $scope.left = () => console.warn('callback doesn\'t seem to be registered');
  $scope.right = () => console.warn('callback doesn\'t seem to be registered');

  $scope.increaseModel = (c) => $scope.down = () => {vm.last = 'down'; $scope.$evalAsync(c);};
  $scope.decreaseModel = (c) => $scope.up = () => {vm.last = 'up'; $scope.$evalAsync(c);};
  $scope.increaseConfig = (c) => $scope.right = () => {vm.last = 'right'; $scope.$evalAsync(c);};
  $scope.decreaseConfig = (c) => $scope.left = () => {vm.last = 'left'; $scope.$evalAsync(c);};

  $scope.confirm = () => {
    var config = vm.models[vm.selectedModel].configs[vm.selectedConfigs[vm.selectedModel]];
    Vehicles.addToGame(config.model_key, config.key);
    $state.go('garage.menu.parts');
  };

}]);