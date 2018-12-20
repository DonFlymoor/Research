angular.module('beamng.garage')

.directive('gpEdge', [function () {
  return {
    template: `
      <div style="position: relative;" class="filler">
        <div style="position: absolute; background-color: currentColor; height: 4%; top: 0; right: 10%; left: 10%;" ng-if="top"></div>
        <div style="position: absolute; background-color: currentColor; height: 4%; bottom: 0; right: 10%; left: 10%;" ng-if="bottom"></div>
        <div style="position: absolute; background-color: currentColor; width: 4%; left: 0; top: 10%; bottom: 10%;" ng-if="left"></div>
        <div style="position: absolute; background-color: currentColor; width: 4%; right: 0; top: 10%; bottom: 10%;" ng-if="right"></div>
      </div>
    `,
    scope: {
      top: '@',
      right: '@',
      bottom: '@',
      left: '@'
    }
  }
}])

.value('showPhotomodeGrid', {
  show:false
})

.controller('garagePhoto', ['showPhotomodeGrid', 'RateLimiter', '$scope', 'logger', 'bngApi', '$state', 'Utils', 'Environment', function (showPhotomodeGrid, RateLimiter, $scope, logger, bngApi, $state, Utils, Environment) {
  'use strict';

  Environment.update();
  Environment.registerScope($scope, () => { $scope.$evalAsync(); });

  //bngApi.engineScript('EditorGuiStatusBar.setCamera("Smooth Rot Camera");');
  bngApi.engineLua("commands.setEditorCameraNewtonDamped()"); // camera change if the editor was not loaded before
  bngApi.engineLua("commands.setFreeCamera()"); // camera change if the editor was not loaded before
  bngApi.engineLua("MoveManager.rollRelative = 0; core_camera.savedFreeCameraFov = getFreeCameraFov()");

  $scope.$emit('ShowApps', false);

  var vm = this;

  vm.environment = Environment;

  vm.settings = {
    fov: 80,
    roll: 0,
    cameraSpeed: 10,
    visible: false,
    showGrid: showPhotomodeGrid.show
  };

  vm.shipping = beamng.shipping;


  bngApi.engineLua('settings.requestState()');
  
  bngApi.engineLua('Steam.isWorking', function (steamStatus) {
    //console.log('steam available:', steamStatus);
    $scope.$evalAsync(function () {
      vm.steamAvailable = steamStatus;
    });
  });

  $scope.$on('SettingsChanged', function (event, data) {
    vm.devMode = data.values.devMode;
  });


  // quick fix for reseting the values on enter, but actually that should be doable just by setting the default values after the watchers, so setting them would trigger the watchers...
  bngApi.engineLua( 'setFreeCameraFov(80);' );
  bngApi.engineLua( 'core_camera.rollAbs(0)' );
  bngApi.engineScript( '$Camera::movementSpeed = 10;' );

  bngApi.engineScript('$Camera::movementSpeed', function (speed) {
    $scope.$evalAsync(function () {
      vm.settings.cameraSpeed = Number(speed);
    });
  });

  function picHelper (func1) {
    vm.showControls = false;
    bngApi.engineLua("guihooks.trigger('hide_ui', true)")
    bngApi.engineScript('hideCursor();');
    setTimeout(function() {
      func1();

      setTimeout(function() {
        bngApi.engineLua("guihooks.trigger('hide_ui', false)")
        bngApi.engineScript('showCursor();');
        vm.showControls = true;
        $scope.$digest();
      }, 500);
    }, 500);
  }

  vm.takePic = () => picHelper(() => bngApi.engineScript('doScreenShot();'));

  vm.doBigScreenShot = () => picHelper(() => bngApi.engineScript('doBigScreenShot();'));
    
  vm.sharePic = () => picHelper(() => bngApi.engineLua('screenshot.publish()'));
    
  vm.steamPic = () => picHelper(() => bngApi.engineLua('screenshot.doSteamScreenshot()'));
    
  vm.openPostFXManager = () => bngApi.engineScript('Canvas.pushDialog(PostFXManager);');

  $scope.$watch('gpPhoto.settings.fov', function(value) {
    bngApi.engineLua('setFreeCameraFov(' + value + ')');
  });

  $scope.$watch('gpPhoto.settings.cameraSpeed', function(value) {
    bngApi.engineScript( '$Camera::movementSpeed = ' + value + ';' );
  });

  $scope.$watch('gpPhoto.settings.roll', function (value) {
    bngApi.engineLua('core_camera.rollAbs(' + (value * 100) + ')' ); // in rads
  });

  $scope.$on('$destroy', function() {
    $scope.$emit('ShowApps', true);
    logger.debug('exiting photomode.');
    bngApi.engineLua("commands.setEditorCameraStandard()"); // camera change if the editor was not loaded before
    bngApi.engineLua("commands.setGameCamera()"); // camera change if the editor was not loaded before
    bngApi.engineLua("MoveManager.rollRelative = 0; setFreeCameraFov(core_camera.savedFreeCameraFov)");
    
    showPhotomodeGrid.show = vm.settings.showGrid;
  });

}]);
