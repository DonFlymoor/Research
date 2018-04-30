angular.module('beamng.stuff')

.value('showPhotomodeGrid', {
  show:false
})

.controller('PhotoModeController', ['$scope', 'bngApi', 'logger', 'Utils', 'showPhotomodeGrid', function($scope, bngApi, logger, Utils, showPhotomodeGrid)  {


  //bngApi.engineScript('EditorGuiStatusBar.setCamera("Smooth Rot Camera");');
  bngApi.engineLua("commands.setEditorCameraNewtonDamped()");
  bngApi.engineLua("commands.setFreeCamera()");
  bngApi.engineScript('$_pm_fov=$cameraFov;$mvRoll = 0;');
  bngApi.engineLua('bullettime.pause(true)');

  var vm = this;

  vm.shipping = beamng.shipping;

  $scope.$on('SettingsChanged', function (event, data) {
    vm.devMode = data.values.devMode;
  });

  bngApi.engineLua('settings.requestState()');
  bngApi.engineLua('Steam.isWorking', function (steamStatus) {
    console.log('steam available:', steamStatus);
    $scope.$evalAsync(function () {
      vm.steamAvailable = steamStatus;
    });
  });

  $scope.$emit('ShowApps', false);

  vm.settings = {
    fov: 80,
    roll: 0,
    visible: false,
    showGrid: showPhotomodeGrid.show
  };


  // quick fix for reseting the values on enter, but actually that should be doable just by setting the default values after the watchers, so setting them would trigger the watchers...
  bngApi.engineScript( 'setFov(80);' );
  bngApi.engineScript( 'rollAbs(0);' );
  bngApi.engineScript( '$Camera::movementSpeed = 10;' );

  bngApi.engineScript('$Camera::movementSpeed', function (speed) {
    $scope.$evalAsync(function () {
      vm.settings.cameraSpeed = Number(speed);
    });
  });

  vm.showSettings   = true;

  vm.showControls = true;

  vm.takePic = function() {
    // vm.settings.visible = false;
    vm.showControls = false;
    setTimeout(function() {
      $scope.$emit('hide_ui', true);
      bngApi.engineScript('hideCursor();');
      bngApi.engineScript('doScreenShot();');
      setTimeout(function() {
        $scope.$emit('hide_ui', false);
        bngApi.engineScript('showCursor();');
        vm.showControls = true;
        $scope.$apply();
      }, 500);
    }, 500);
  };

  vm.doBigScreenShot = function() {
    // vm.settings.visible = false;
    vm.showControls = false;
    setTimeout(function() {
      $scope.$emit('hide_ui', true);
      bngApi.engineScript('hideCursor();');
      bngApi.engineScript('doBigScreenShot();');
      setTimeout(function() {
        $scope.$emit('hide_ui', false);
        bngApi.engineScript('showCursor();');
        vm.showControls = true;
        $scope.$apply();
      }, 500);
    }, 500);
  };

  vm.sharePic = function() {
    // vm.settings.visible = false;

    vm.showControls = false;
    setTimeout(function() {
      $scope.$emit('hide_ui', true);
      bngApi.engineScript('hideCursor();');
      bngApi.engineLua('screenshot.publish()');
      setTimeout(function() {
        $scope.$emit('hide_ui', false);
        bngApi.engineScript('showCursor();');
        vm.showControls = true;
        $scope.$apply();
      }, 500);
    }, 500);
  };

  vm.steamPic = function() {
    vm.showControls = false;
    //$scope.$emit callback system not working, so moved the UI hide before cursor hide in TS
     $scope.$emit('hide_ui', true); 
     //Waiting to make sure hide has executed
     Utils.waitForCefAndAngular(() => {
        bngApi.engineScript('hideCursor();', () => {
          bngApi.engineLua('screenshot.doSteamScreenshot()', () => {
          $scope.$emit('hide_ui', false);
          vm.showControls = true;
          bngApi.engineScript('showCursor();');
          $scope.$apply();
          });
        });
     });
  };

  vm.toggleSettings = function () {
    vm.settings.visible = !vm.settings.visible;
    //if (vm.settings.visible) {
    //  vm.postfx.visible = false;
    //}
    // logger.log('settings is now', vm.settings.visible);
  };


  $scope.$watch('photo.settings.fov', function(value) {
      bngApi.engineScript( 'setFov(' + value + ');' );
  });

  $scope.$watch('photo.settings.cameraSpeed', function(value) {
    // logger.log('changed speed', value);
    bngApi.engineScript( '$Camera::movementSpeed = ' + value + ';' );
  });

  $scope.$watch('photo.settings.roll', function (value) {
    bngApi.engineScript( 'rollAbs(' + (value * 100) + ');' ); // in rads
  });

  vm.openPostFXManager = function() {
    bngApi.engineScript('Canvas.pushDialog(PostFXManager);');
  };


  $scope.$on('$destroy', function() {
    $scope.$emit('ShowApps', true);
    logger.debug('exiting photomode.');
    bngApi.engineLua("commands.setEditorCameraStandard()"); // camera change if the editor was not loaded before
    bngApi.engineLua("commands.setGameCamera()"); // camera change if the editor was not loaded before
    bngApi.engineScript('$mvRoll = 0;setFov($_pm_fov);');
    showPhotomodeGrid.show = vm.settings.showGrid;
  });

}]);

