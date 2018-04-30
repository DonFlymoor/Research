angular.module('beamng.stuff')

/**
 * @ngdoc controller
 * @name beamng.stuff:LevelSelectController
 * @description Controller used in level selecting view
**/
.controller('LevelSelectController',  ['$filter', '$scope', '$state', '$rootScope', 'InstalledContent',
  function($filter, $scope, $state, $rootScope, InstalledContent) {

  InstalledContent.levels.forEach(x => {
    x.__displayName__ = $filter('translate')(x.title);
  });

  var vm = this;

  vm.filtered = beamng.shipping ? InstalledContent.levels.filter((e) => e.levelName != 'showroom_v2_dark') : InstalledContent.levels;
  vm.selected = InstalledContent.levels[0];

  vm.updateList = function (query) {
    vm.filtered = $filter('filter')(InstalledContent.levels, { __displayName__: query});
    vm.selected = vm.filtered[0];
  };

  vm.openRepo = function () {
    window.location.href = 'http-external://www.beamng.com/resources/categories/terrains-levels-maps.9/?ingame=2';
  };

  vm.select = function (level) {
    vm.selected = level;
  };

  vm.details = function (level, index, gameState) {
    $state.go(`menu.levelDetails`, {level: level.__index__});
  };

  $scope.showDisable = function (reason) {

    var messageMap = {
      "x86": "ui.levelselect.x86Disabled"
    }

    var message = (messageMap[reason] ? messageMap[reason] : reason);

    $rootScope.$broadcast("toastrMsg", { type: "error", title: "Map Disabled",  msg: $filter('translate')(message) })
  }

}])

.controller('LevelSelectDetailsController',  ['$stateParams', 'bngApi', 'InstalledContent', '$scope',
  function($stateParams, bngApi, InstalledContent, $scope) {
  var vm = this;

  vm.level = InstalledContent.levels[Number($stateParams.level)];

  vm.selected = vm.level.spawnPoints[0];

  vm.select = function (level) {
    vm.selected = level;
  };

  vm.launch = function(point) {
    point = point || vm.selected;

    var luaCmd = `core_levels.startFreeroam(` + bngApi.serializeToLua(vm.level) + `, "${point.objectname}")`;
    $scope.$emit('CloseMenu');
    bngApi.engineLua(luaCmd);
  };
}])
