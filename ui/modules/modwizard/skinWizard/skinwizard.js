angular.module('beamng.stuff')
  .controller('SkinWizardController', ['$log', '$scope', '$state', '$rootScope', 'bngApi', 'Vehicles', 'InstalledContent', 'Utils',
    function ($log, $scope, $state, $rootScope, bngApi, Vehicles, InstalledContent, Utils) {
      var vm = this;

      bngApi.engineLua('extensions.load("util_modwizard")');
      // make sure we unload the lua module as well when this page is unloaded
      $scope.$on('$destroy', function () {
        // bngApi.engineLua('extensions.unload("util_modwizard")');
      });

      var arrVehicles = [
        'barstow',
        'burnside',
        'coupe',
        'etk800',
        //'etkc',
        'etki',
        'fullsize',
        'hatch',
        'hopper',
        //'legran',
        //'midsize',
        'miramar',
        'moonhawk',
        'pessima',
        'pigeon',
        'pickup',
        'roamer',
        //'semi',
        'sbr',
        'sunburst',
        'super',
        'van'
      ];

      var init = function () {
        vm.data = InstalledContent.vehicles.models.filter((e) => arrVehicles.indexOf(e.key) !== -1);
      }

      Vehicles.populate().then(init);

      vm.vehicleSelect = function (vehicle) {
        vm.selectedVehicle = vehicle;
        vm.key = vehicle.key
        vm.next();
      }

      $scope.$evalAsync(() => {
        vm.next = function () {
          switch (vm.index) {
            case 0: //  step 1
              vm.index++;
              break;
            case 1: //  step 2
              if (vm.selectedVehicle != null) {
                vm.index++;
              }
              else {
                $rootScope.$broadcast('toastrMsg', { type: "error", title: "Vehicle not Selected", msg: "Please select a vehicle from the list." })
              }
              break;
            case 2: //  step 3
              if (vm.modName === undefined || vm.modName.match(/\W/g, '')) {  // checking if modName is valid
                vm.errorMsg = 'Please enter a valid name'
                $rootScope.$broadcast("toastrMsg", { type: "error", title: "Invalid Name", msg: "Please enter a valid mod name." })
              }
              else {
                bngApi.engineLua('util_modwizard.validateName(' + bngApi.serializeToLua(vm.key) + ", " + bngApi.serializeToLua(vm.modName) + ')', (res) => {
                  if (res) {
                    vm.errorMsg = 'Mod already exists'
                    $rootScope.$broadcast("toastrMsg", { type: "error", title: "Mod Exists", msg: "Mod already exists please use another name" })
                  }
                  else {
                    vm.modName = vm.modName.replace(/\s/g, '');
                    vm.createMod()
                    vm.index++;
                  }
                });
              }
              break;
            case 3: //  step 4
              bngApi.engineLua('util_modwizard.loadSkin(' + bngApi.serializeToLua(vm.key) + ')')
              break;
          }
        }
      });

      vm.createMod = function () {
        // once files are created and mounted the UI does not refresh, this is inteded to solve that.
        $rootScope.$apply(
          $scope.$emit('app:waiting', true, function () {
            Utils.waitForCefAndAngular(() => {
              bngApi.engineLua('util_modwizard.createSkin(' + "'" + vm.modName + "'" + "," + '"' + vm.key + '"' + ')');
              $scope.$emit('app:waiting', false);
            });
          })
        )
      }

      vm.openMod = function () {
        bngApi.engineLua('util_modwizard.openExplorer(' + "'" + vm.modName + "'" + ')');
      }

      vm.done = function () {
        $state.go('menu.modwizard')
      }

      vm.back = function () {
        if (vm.index === 0) {
          $state.go('menu.modwizard')
        }
        vm.index--;
      }

      bngApi.engineLua('core_vehicles.requestList()');
    }

  ])