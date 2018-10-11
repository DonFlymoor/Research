angular.module('beamng.garage')

.controller('garageProtoSelect', ['$scope', '$rootScope', '$timeout', 'logger', 'bngApi', 'InstalledContent', 'Utils', 'Vehicles', '$state', '$stateParams',
function ($scope, $rootScope, $timeout, logger, bngApi, InstalledContent, Utils, Vehicles, $state, $stateParams) {

  var vm = this;


    Vehicles.populate().then(() => {
      vm.perfKeyList = InstalledContent.vehicles.displayInfo.perfData;
      vm.overviewKeylist = InstalledContent.vehicles.displayInfo.filterData;
    });

    vm.params = $stateParams
    vm.hasStock = true;
    vm.data;

    // Broadcasting the current mode of garage (dealer or HQ) so we can set the title in garage.html
    $rootScope.$broadcast('UpdateGarageTitle', vm.params.mode);

    bngApi.engineLua('core_vehicles.requestSimpleVehicleList()');

    $scope.$on('simpleVehicleList', (ev, data) => {
      vm.data = data;
      filterVehicles(vm.data);
    });

    function filterVehicles(data) {
      // just in case
      $scope.$evalAsync(() => {
        // filtering all ingame vehicles to show only the ones the player 'owns'
        if (vm.params.vehicles.length > 0) {
          vm.hasStock = true;

          vm.models = data.filter((e) => {
            for (var key in vm.params.vehicles) {
              if (vm.params.vehicles[key].model === e.key) return true;
            }
            return false;
          })

          // filtering out configs
          for (var veh in vm.models) {
            vm.models[veh].configs = vm.models[veh].configs.filter((e) => {
              for (var val in params.vehicles) {
                if (vm.params.vehicles[val].config === e.key && vm.params.vehicles[val].model === e.model_key) return true;
              }
            })
          }

          // Selected vehicle in garage is assigned to currently used vehicle
          for (var i = 0; i < vm.models.length; i++) {
            if (vm.models[i].key === vm.current.key) {
              vm.selectedModel = i;
            }
          }

          vm.selectedConfigs = [];

          // vm.models[0].configs[0].owned = true;   // owned car test
        }
        else {
          vm.hasStock = false;
        }

      });
    }

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

    function loadVehicle() {
      var fallback = $timeout(() => {
        // if the car isn't spawned by now it will probably not spawn at all, so remove the waiting sign
        $rootScope.$broadcast('app:waiting', false);
      }, 3000);

      $rootScope.$broadcast('app:waiting', true, function () {
        var config = vm.models[vm.selectedModel].configs[vm.selectedConfigs[vm.selectedModel]];
        var luaArgs = {};

        if (config) {
          if (typeof config === 'string') {
            luaArgs.config = config;
          } else if (typeof config === 'object') {
            luaArgs.config = config.key;
          }
        }

        if (typeof config.model_key === 'object') {
          luaArgs.model = config.model_key.key;
        } else if (typeof config.model_key === 'string') {
          luaArgs.model = config.model_key;
        }

        bngApi.engineLua('campaign_exploration.uiEventSelectVehicle(' + bngApi.serializeToLua(luaArgs) + ')', function () {
          $timeout($rootScope.$broadcast('app:waiting', false));
          vm.selectedConfigs = undefined;
          vm.selectedModel = undefined;
          filterVehicles(vm.data);
          // car was spawned clear fallback
          $timeout.cancel(fallback);
        });
      })
    }

    $scope.confirm = () => {
      $scope.$evalAsync(function () {
        var selectedVehicle = vm.models[vm.selectedModel].configs[vm.selectedConfigs[vm.selectedModel]];
        if (vm.params.mode === "dealer" && selectedVehicle) {
          if (vm.params.money >= selectedVehicle.Value) {
            for (var key in vm.params.vehicles) {
              if (selectedVehicle.key === vm.params.vehicles[key].config) {
                loadVehicle();
                vm.params.money -= selectedVehicle.Value;
                vm.params.vehicles.splice(key, 1);
              }
            }
          }
          else {
            var money = document.getElementById("money");
            money.classList.add('insufficient-funds')
            money.addEventListener("animationend", function () {  // resetting the animation
              money.classList.remove('insufficient-funds');
            });
          }
        }
        else {
          loadVehicle();
        }
      })
    };

    bngApi.engineLua('core_vehicles.getCurrentVehicleDetails()', (res) => { // Getting currently used vehicle details.
      vm.current = res.current;
    })
        loadVehicle();
      }
    })
  };

  bngApi.engineLua('core_vehicles.getCurrentVehicleDetails()', (res) => { // Getting currently used vehicle details.
    vm.current = res.current;
  })

}])