angular.module('beamng.stuff')
.controller('LuaDebugController', ['$scope', 'bngApi', function($scope, bngApi) {
  $scope.enabled = false;
  $scope.windowSize = 1;
  $scope.luaData = {};
  $scope.luaView = 'T3D';

  $scope.$on('onLuaPerf', function (event, data){
    $scope.$apply(function() {
      $scope.luaData[data.source] = data;
    });
  });
  
  $scope.$on('$destroy', function() {
    HookManager.unregisterAll(hookObj);
  });

  function enable() {
    bngApi.engineLua('perf.enable(' + $scope.windowSize + ', "onLuaPerf", {source = "T3D"})');
    bngApi.activeObjectLua('perf.enable(' + $scope.windowSize + ', "onLuaPerf", {source = "v0"})');
  }

  function disable() {
    bngApi.engineLua('perf.disable()');
    bngApi.activeObjectLua('perf.disable()');
    $scope.luaData = {};
  }

  $scope.$watch('enabled', function(newVal, oldVal) {
    if (newVal == oldVal) {
      return;
    }
    if (newVal) {
      enable();
    } else {
      disable();
    }
  });

  $scope.$watch('windowSize', function(newVal, oldVal) {
    if (newVal == oldVal) {
      return;
    }
    if ($scope.enabled) {
      disable();
    }
    enable();
  });

}]);
