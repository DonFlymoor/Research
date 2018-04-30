angular.module('beamng.stuff')
  .controller('ModWizardController', ['$log', '$scope', '$state', 'bngApi', function ($log, $scope, $state, bngApi, ModWizardService) {
    var vm = this;

    // make sure we unload the lua module as well when this page is unloaded
    $scope.$on('$destroy', function () {
      bngApi.engineLua('extensions.unload("util_modwizard")');
    });
  }])