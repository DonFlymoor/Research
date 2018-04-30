angular.module('beamng.stuff')
  .controller('TerrainWizardController', ['$log', '$scope', '$state', 'bngApi',
    function ($log, $scope, $state, bngApi, ModWizardService) {
      var vm = this;

      vm.next = function () {
        if (vm.index === 0 || vm.index === 1) {
          vm.index++;
        }
        if (vm.index === 2) {
          if (vm.modName === undefined) {
            console.log('undefined')
          }
          else {
            vm.modName = vm.modName.replace(/\s/g, '');
            vm.createMod()
            vm.index++;
          }
        }
        else if (vm.index === 3) {
          $state.go("menu.modwizard");
        }
      }

      vm.back = function () {
        if (vm.index === 0) {
          $state.go('menu.modwizard')
        }
        vm.index--;
      }

      vm.createMod = function () {
        bngApi.engineLua('util_modwizard.createTerrain(' + "'" + vm.modName + "'" + ')');
      }

      vm.openMod = function () {
        bngApi.engineLua('util_modwizard.openExplorer(' + "'" + vm.modName + "'" + ')');
      }
    }
  ])