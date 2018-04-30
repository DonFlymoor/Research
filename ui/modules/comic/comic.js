angular.module('beamng.stuff')

/**
 * @ngdoc controller
 * @name beamng.stuff:ScenarioStartController
 * @description Controller for the view that appears on scenario start
**/
.controller('ComicController', ['Utils', '$scope', '$rootScope', '$stateParams', 'gamepadNav', 'SpatialNavigation', 'bngApi', function (Utils, $scope, $rootScope, $stateParams, gamepadNav, SpatialNavigation, bngApi) {
  var prevCross = gamepadNav.crossfireEnabled()
    , prevGame = gamepadNav.gamepadNavEnabled()
    , prevSpatial = gamepadNav.gamepadNavEnabled()
  ;

  gamepadNav.enableCrossfire(false);
  gamepadNav.enableGamepadNav(false);
  gamepadNav.enableSpatialNav(true);

  bngApi.engineLua("bindings.menuActive(true)");

  $scope.$on('$destroy', () => {
    bngApi.engineLua("bindings.menuActive(false)");
    
    gamepadNav.enableCrossfire(prevCross);
    gamepadNav.enableGamepadNav(prevGame);
    gamepadNav.enableSpatialNav(prevSpatial);

  });

  $scope.confirmTriggered = function () {
    $rootScope.$broadcast('forceSpineAnimationEnd');
  };

  if (!$stateParams.comiclist.isEmpty()) {
    Utils.waitForCefAndAngular(() => {
      $rootScope.$broadcast('startSpineAnimation', $stateParams.comiclist);
    });
  }
}])