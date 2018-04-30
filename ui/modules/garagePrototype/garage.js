angular.module('beamng.garage')


.controller('garageProtoCtrl', ['$scope', 'bngApi', 'Utils', 'gamepadNav', 'SpatialNavigation', '$state', function ($scope, bngApi, Utils, gamepadNav, SpatialNavigation, $state) {

  console.warn('Garage Prototype Loaded');

  var prevCross = gamepadNav.crossfireEnabled()
    , prevGame = gamepadNav.gamepadNavEnabled()
    , prevSpatial = gamepadNav.gamepadNavEnabled()
  ;


  gamepadNav.enableCrossfire(false);
  gamepadNav.enableGamepadNav(false);
  gamepadNav.enableSpatialNav(true);

  bngApi.engineLua("bindings.menuActive(true)");

  $scope.$on('$destroy', () => {
    gamepadNav.enableCrossfire(prevCross);
    gamepadNav.enableGamepadNav(prevGame);
    gamepadNav.enableSpatialNav(prevSpatial);

    SpatialNavigation.currentViewActions.toggleMenues = oldAction;
  });

  var oldAction = SpatialNavigation.currentViewActions.toggleMenues;
  SpatialNavigation.currentViewActions.back = {
    cmd: () => {;
                bngApi.engineLua('campaign_exploration.uiEventGarageExit()')}, name: 'Exit'}
}])

.controller('garageProtoMenuCtrl', ['$scope', 'logger', 'bngApi', '$state', 'Utils', 'SpatialNavigation', function ($scope, logger, bngApi, $state, Utils, SpatialNavigation) {
  'use strict';
  var vm = this;

  vm.menus =
  [
    { icon: '#gp-icons-my_cars'
    , name: 'ui.garage.tabs.load'
    , href: 'garage.menu.load'
    }
  , { icon: 'directions_car'
    , name: 'ui.garage.tabs.vehicles'
    , href: 'garage.menu.select'
    }
  , { icon: 'settings'
    , name: 'ui.garage.tabs.parts'
    , href: 'garage.menu.parts'
    }
  , { icon: 'tune'
    , name: 'ui.garage.tabs.tune'
    , href: 'garage.menu.tune'
    }
  , { icon: 'brush'
    , name: 'ui.garage.tabs.paint'
    , href: 'garage.menu.paint'
    }
  , { icon: 'photo_camera'
    , name: 'ui.garage.tabs.photo'
    , href: 'garage.menu.photo'
    }
  , { icon: 'save'
    , href: 'garage.save'
    }
  ]

  vm.spaceBefore = ['ui.garage.tabs.photo'];

  vm.isActive = (menu) => menu.href === $state.current.name;

  $scope.$on('$destroy', () => {
    delete SpatialNavigation.currentViewActions['trigger-right'];
    delete SpatialNavigation.currentViewActions['trigger-left'];
  });

  vm.executeAction = function (func) {
    if (typeof func === 'function') {
      func();
    }
  };

  function stateIdByName (name) {
    for (var i = 0; i < vm.menus.length && vm.menus[i].href !== name; i += 1) {}
    return i;
  }

  function handleMenuChange (direction, newId) {
    var id = stateIdByName($state.current.name);
    var nId = (newId !== undefined ? newId : id + direction);

    if (vm.menus[id] !== undefined && vm.menus[nId] !== undefined) {
      bngApi.engineLua(`Engine.Audio.playOnce('AudioGui', 'core/art/sound/ui_select_main.ogg')`);
      $state.go(vm.menus[nId].href);
    }

    SpatialNavigation.currentViewActions['trigger-left'].hide = (nId === 0);
    SpatialNavigation.currentViewActions['trigger-right'].hide = (nId + 1 === vm.menus.length);
  }

  $scope.$on('UpdateGarageTitle', function(event, data) {
    if (data === 'dealer') {
      $scope.garageTitle = 'Car Dealer';
    } else if (data === 'garage') {
      $scope.garageTitle = 'Garage';
    }
  })

  vm.handleMenuChange = handleMenuChange;

  // SpatialNavigation.currentViewActions['trigger-left'] = {cmd: () => handleMenuChange(-1), name: 'ui.actions.menuLeft', hide: false};
  // SpatialNavigation.currentViewActions['trigger-right'] = {cmd: () => handleMenuChange(+1), name: 'ui.actions.menuRight', hide: false};
}]);


