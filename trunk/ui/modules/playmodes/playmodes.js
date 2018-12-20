angular.module('beamng.stuff')

.controller('PlayModesController', ['AppDefaults', 'bngApi', 'InstalledContent', '$state', function (AppDefaults, bngApi, InstalledContent, $state) {
  var vm = this;
  vm.list = AppDefaults.playModes;

  vm.openRepo = function () {
    window.location.href = 'http-external://www.beamng.com/resources/?ingame=2';
  };

  vm.handleClick = function(card) {
    // console.log(card)
    var levelName = card.levelName;
    var levelData = InstalledContent.allLevels.filter(e => e.levelName === levelName)[0];
    if (levelData !== undefined) {
      bngApi.engineLua(`freeroam_freeroam.startTrackBuilder(${bngApi.serializeToLua(levelData)})`)
    } else {
      $state.go((card.disabled || !card.targetState) ? '.' : 'menu.' + card.targetState);
    }
  }

}]);