angular.module('beamng.stuff')

.controller('TerrainGenController', ['$log', '$scope', '$state', 'bngApi', function ($log, $scope, $state, bngApi) {
  var vm = this;

  bngApi.engineLua('extensions.load("ui_terraingen")');
  // make sure we unload the lua module as well when this page is unloaded
  $scope.$on('$destroy', function () {
    bngApi.engineLua('extensions.unload("ui_terraingen")');
  });

  // example for a function call
  $scope.generateTerrain = function() {
    console.log("GIB TERRAIN PLS");
    // simple calls with no return value:
    // only works in private build
    //bngApi.engineLua('core_environment.generateTerrain()');
  
  }
}])
