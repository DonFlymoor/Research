angular.module('beamng.stuff')


.controller('LoadingController', ['bngApi', 'logger', '$scope', 'ControlsUtils', 'Hints', 'Utils',
  function (bngApi, logger, $scope, ControlsUtils, Hints, Utils) {

  var vm = this;

  vm.hintTranslationKey = Hints[Math.floor(Math.random() * Hints.length)];

  vm.simple = (beamng.buildtype !== 'RELEASE' && beamng.buildtype !== 'INTERNAL'); // hides the tips, hotkeys, etc

  vm.progress = { val: '-1', txt: 'loading ...' };

  $scope.$on('UpdateProgress', function (event, data) {
    window.requestAnimationFrame(function () {
      $scope.$apply(function () {
        if (data.txt !== '') {
          vm.progress = data;
        } else {
          vm.progress.val = data.val;
        }
      });
    });
    $scope.$digest();
  });


  bngApi.engineLua(`dirContent("game:/ui/modules/loading/${beamng.product}/")`, (data) => {
    var files = data.map((elem) => elem.slice('/ui/'.length + (elem.indexOf("game:")==0?'game:'.length:0)));
    var file = files[Utils.random(0, files.length -1, true)];
    $scope.$evalAsync(() => {
      vm.img = file;
      // give angualar a head start to finish running it's digest
      setTimeout(function () {
        // since background images don't fire a load event, we'll simulate one
        var a = new Image();
        a.onload = function () {
          // give the render a head start (ie. wait 2-3 frames)
          Utils.waitForCefAndAngular(() => {
            bngApi.engineLua('core_gamestate.loadingScreenActive()');
          });
        }
        a.src = file;
      });
    });
  });

  vm.helpActions = {};

  var actions = [
    'toggleMenues',
    'toggle_help',
    'reset_physics',
    'accelerate',
    'brake',
    'steer_left',
    'steer_right',
    'switch_camera_next',
    'center_camera'
  ].forEach((elem) => {
    vm.helpActions[elem] = ControlsUtils.findBindingForAction(elem);
  });


  // no infinite loading screen
  var timeout = setTimeout(() => bngApi.engineLua('core_gamestate.loadingScreenActive()'), 10000);
  
  $scope.$on('$destroy', function () {
    clearTimeout(timeout)
  });
}]);
