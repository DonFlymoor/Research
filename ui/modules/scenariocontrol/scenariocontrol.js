angular.module('beamng.stuff')

/**
 * @ngdoc controller
 * @name beamng.stuff:ScenarioStartController
 * @description Controller for the view that appears on scenario start
**/
.factory('ScenarioControlService', function() {
  var selections= {};

  function reset () {
    selections.vehicle = {
      name: '',
      file:null,
      preview: '/ui/images/appDefault.png',
      targetState: {state: 'vehicles', args: {mode: 'selectableVehicle'}}
    };
  }

  reset();

  return {
    getSelections:  function()        { return selections;            },
    setVehicle:    function(vehicle)  { selections.vehicle   = vehicle; },
    reset : reset,
    accessibility: function () {
      for (var key in selections) {
        selections[key].disabled = key === 'route';
      }
    }
  };
})
.controller('ScenarioStartController', ['logger', '$scope', '$state', '$timeout', '$rootScope', 'bngApi', 'ControlsUtils', 'Utils', '$ocLazyLoad', 'gamepadNav', '$sce', '$translate', 'VehicleSelectConfig', '$stateParams', 'ScenarioControlService',
function (logger, $scope, $state, $timeout, $rootScope, bngApi, ControlsUtils, Utils, $ocLazyLoad, gamepadNav, $sce, $translate, VehicleSelectConfig, $stateParams, ScenarioControlService) {
  var vm = this;
  vm.data = null;
  vm.config = { playerValid: true };

  var crossfireEnabled = gamepadNav.crossfireEnabled();
  var gamepadNavEnabled = gamepadNav.gamepadNavEnabled();
  var spatialNavEnabled = gamepadNav.spatialNavEnabled();
  gamepadNav.enableCrossfire(false);
  gamepadNav.enableGamepadNav(false);
  gamepadNav.enableSpatialNav(true);
  Utils.waitForCefAndAngular(() => {
    $scope.$emit('ShowApps', false);
    bngApi.engineLua("bindings.menuActive(true);");
    // Start listening to the controls. Needed for starting the scenario without clicking
    // on the button (e.g. by throttle action)
    bngApi.engineLua('WinInput.setForwardRawEvents(true);');
    bngApi.engineLua('WinInput.setForwardFilteredEvents(true);');
  });

  if (ScenarioControlService.getSelections().vehicle.name === "") {
    bngApi.engineLua('core_vehicles.getCurrentVehicleDetails()', function(data) {
      var currentVehicle = data;
      ScenarioControlService.setVehicle({
        official: currentVehicle.configs.aggregates.Source['BeamNG - Official'],
        model: currentVehicle.current.key,
        config: currentVehicle.current.config_key,
        color: currentVehicle.current.color,
        name: currentVehicle.configs.Name,
        preview: currentVehicle.configs.preview,
        targetState: {state: 'vehicles', args: {mode: 'selectableVehicle'}},
        file: currentVehicle.model
      });
      $scope.vehicle = ScenarioControlService.getSelections().vehicle;
    });
  }
  else {
    $scope.vehicle = ScenarioControlService.getSelections().vehicle;
  }

  vm.selectVehicle = function() {
    $state.go('menu.vehicles', {mode: 'selectableVehicle'})
    $scope.$emit('MenuHide', false);

    VehicleSelectConfig.addConfig('selectableVehicle', {
      hide: {
        'removeBtns': true,
        'spawnNew': true
      },
      backButtonRef : 'scenario-start',
      selected: (carObj, model, config, color, spawnNew) => {
        if(config == null ) config = carObj.default_pc;
        if(color == null ) color = carObj.default_color;
        ScenarioControlService.setVehicle({
          official: carObj.aggregates.Source['BeamNG - Official'],
          model: model,
          config: config,
          color: color,
          name: carObj.Name,
          preview: carObj.preview,
          targetState: {state: 'vehicles', args: {mode: 'selectableVehicle'}},
          file: carObj
        });
        VehicleSelectConfig.configs['selectableVehicle'].backButtonRef = 'scenario-start';
        $state.go(`scenario-start`);
        var vehicle = {
          'model': model,
          'config': config,
          'color': color
        }
        var fallback = $timeout(() => {
           // if the car isn't spawned by now it will probably not spawn at all, so remove the waiting sign
          $rootScope.$broadcast('app:waiting', false);
        }, 3000);

        $rootScope.$broadcast('app:waiting', true, function() {
          bngApi.engineLua(`extensions.hook("onVehicleSelected", ${bngApi.serializeToLua(vehicle)})`, function() {
            $timeout($rootScope.$broadcast('app:waiting', false));
            $timeout.cancel(fallback);
          });
        });
      },
      selectButton: 'ui.quickrace.selectVehicle',
      parentState: 'scenario-start',
      name: 'scenario-start',
      filter: {
        'Type': ['Prop', 'Trailer']
      },
      getVehicles: function() {
        if ($stateParams.vehicles) {
          return $stateParams.vehicles;
        }
        return undefined;
      }
    });
  }


  // bngApi.engineLua('requestGameState()'); // <- why? (todo)
  Utils.waitForCefAndAngular(() => $scope.$emit('StickyState', $state.$current.name));
  /**
   * @ngdoc method
   * @name beamng.stuff:ScenarioStartController#play
   * @methodOf beamng.stuff:ScenarioStartController
   *
   * @description Informs Lua that we are ready to launch the loaded scenario
   */
  vm.play = function () {
    if( vm.config && !vm.config.playerValid )
      return;
    $scope.$emit('StickyState', null);

    // Inform Lua that we UI is ready to launch the scenario
    logger.scenarioControl.debug('[ScenarioStartController] sending to engineLua: %s', 'scenario_scenarios.onScenarioUIReady("play")');
    bngApi.engineLua('extensions.hook("onScenarioUIReady", "play")');
    $scope.$emit('MenuHide'); // Close menus (just in case)
    $state.go('menu');              // and return to the default state
  };
  vm.getIconName = function (devName) { return ControlsUtils.deviceIcon(devName); };

  vm.showStartButton = true;
  $scope.$on('scenarioStart:showStartButton', (_, data) => {
    vm.showStartButton = !!data;
    $scope.$evalAsync();
  });

  // Listeners ------------------------------------------------------------------

  $scope.$on('FilteredInputChanged', function (event, data) {
    if (data.bindingAction == 'accelerate' && data.value > 0 && data.controlType == 'key') vm.play(); //only allow throttle key (not buttons or axes) to start scenario. as well as the usual menu bindings for each device (button-A in gamepads, etc)
    bngApi.engineLua( "scenario_scenarios.onFilteredInputChanged('"+ data.devName +"', '" + data.bindingAction + "', " + data.value + ")" );
  });

  $scope.$on('RawInputChanged', function (event, data) {
    // When UI is focused, CEF swallows all filtered input events from keyboard
    // This means, when UI is focused, user cannot change keyboard multiseat vehicle with left/right steering bindings
    // To work around this, we check the raw inputs, and convert left/right arrow keys, to steering events for the multiseat scenario UI selection
    if (data.devName[0] != "k")                            return; // only forward keyboard events
    if (data.control != "left" && data.control != "right") return; // only forward left/right events
    var action = "steer_" + data.control;
    bngApi.engineLua( "scenario_scenarios.onFilteredInputChanged('"+ data.devName +"', '"+action+"', " + data.value + ")" );
  });

  $scope.$on('PlayersChanged', function (event, data) {
    // console.log("onPlayersChange", data);
    $scope.$evalAsync(function () {
      vm.config = data;
    });
  });

  $scope.BBToHtml = function (code) {
    return $sce.trustAsHtml(Utils.parseBBCode(code));
  };

  function displayStartHtml (data) {
    $scope.$evalAsync(function () {
      vm.data = data;
      vm.data.description = $scope.BBToHtml($translate.instant(vm.data.description));
      vm.data.descriptionHref = data.startHTML ? ( data.directory + '/' + data.startHTML) : null;

    });
  }

  $scope.$on('SettingsChanged', function (_, data) {
    $scope.$evalAsync(() => {
      vm.userSettings = data;
    });
  });
  bngApi.engineLua('settings.requestState()')

  vm.applySettings = function (key) {
    bngApi.engineLua(`settings.setValue("${key}", "${vm.userSettings.values[key]}")`)
  }

  // This event carries data relevant to the loaded scenario. By listening to
  // that, we get the information to be displayed.
  $scope.$on('ScenarioChange', function (event, data) {
    logger.scenarioControl.debug('[ScenarioStartController] received ScenarioChange:', data);
    if (data && !data.isEmpty()) {
      if (data.jsSource !== undefined) {
        $ocLazyLoad.load(data.jsSource).then(() => {
          displayStartHtml(data);
        });
      } else {
        displayStartHtml(data);
      }
    }
  });

  // We no longer need to listen to the controls once the state is gone.
  $scope.$on('$destroy', function() {
    bngApi.engineLua('WinInput.setForwardRawEvents(false);');
    bngApi.engineLua('WinInput.setForwardFilteredEvents(false);');
    gamepadNav.enableCrossfire(crossfireEnabled); // use old value from before opening the menu here
    gamepadNav.enableGamepadNav(gamepadNavEnabled); // use old value here
    gamepadNav.enableSpatialNav(spatialNavEnabled); // use old value here
    bngApi.engineLua("bindings.menuActive(false);");
    $scope.$emit('ShowApps', true);
    ScenarioControlService.reset();
    //vm.play();
  });


  // Run on launch ----------------------------------------------------------------

  // This is actually a request to the Lua engine to send a "ScenarioChange"
  // event through the HookManager, with information about the about-to-start scenario.
  // A listener is already registered.
  Utils.waitForCefAndAngular(() =>
    bngApi.engineLua('extensions.hook("onScenarioUIReady", "start")')
  );


  // Send focus to the start button, to make it easy starting the scenario by throttle action, Enter, etc.
  setTimeout(function () {
    // document.getElementById('scenario-start-btn').focus();
  }, 100);
}])

.value('CampaignResults', {
  stats: {}
})

.directive('showInOrder', ['$timeout', function ($timeout) {
  return {
    restrict: 'A',
    scope: {
      showInOrder: '@'
    },
    controller: ['$scope', function ($scope) {
      var vm = this
        , list = []
        , index = 0;
        ;

      $scope.$on('showInOrderStart', (ev, data) => {
        if (data === $scope.showInOrder) {
          index = 0;
          showElements();
        }
        //console.log('test');
      });

      // todo
      // $scope.$on('showInOrderPause', (ev, data) => {

      // });

      // $scope.$on('showInOrderContinue', (ev, data) => {

      // });

      function showElements () {
        var counter = 0;
        if (list.length > index) {
          for (var i = 0; i < list[index].length; i += 1) {
            var short = list[index][i];

            short.timeout = $timeout(() => {
              short.elem.show();
              counter += 1;
              if (counter === list[index].length) {
                showElements();
              }
            }, short.delay);
          }
        }
      }

      vm.registerItem = function (position, item, delay) {
        if (list[position] === undefined) {
          list[position] = [];
        }
        list[position].push({elem: item, delay: (delay === undefined ? 5000 : delay)});
      };

      vm.deregisterItem = function (position, item) {
        // todo
      };
    }]
  };
}])

.directive('showAtPosition', [function () {
  return {
    restrict: 'A',
    require: '^^showInOrder',
    scope: {
      showAfterMs: '@',
      showAtPosition: '@'
    },
    link: function (scope, elem, attr, inOrder) {
      // elem.hide();

      inOrder.registerItem(scope.showAtPosition, elem, scope.showAfterSeconds);

      scope.$on('$destroy', () => {
        inOrder.deregisterItem(scope.showAtPosition, elem);
      });
    }
  }
}])

.directive('points', [function () {
  return {
    template:
      `<div layout="row" layout-align="center center">
        <span ng-if="points === undefined && maxPoints === undefined">
        -
        </span>

        <span ng-if="points < 0">
          {{points.toFixed(0)}}
        </span>

        <span ng-if="(points !== undefined || maxPoints !== undefined) && points >= 0">
          <span ng-if="points !== undefined">{{points.toFixed(0)}}</span>
          <span ng-if="points === undefined" style="color: rgb(200, 200, 200);">NA</span>
          &nbsp;/&nbsp;
          <span ng-if="maxPoints !== undefined">{{maxPoints.toFixed(0)}}</span>
          <span ng-if="maxPoints === undefined" style="color: rgb(200, 200, 200);">NA</span>
        </span>

      </div>`,
    scope: {
      points: '=',
      maxPoints: '='
    },
    restrict: 'E'
  };
}])

// thanks to: http://stackoverflow.com/questions/26881197/set-conditional-focus-on-some-field-in-angularjs
.directive('focusIf', function() {
  return {
    scope: {
      focusIf: '='
    },
    link: function($scope, $element) {

      $scope.$watch('focusIf', function(shouldFocus) {
        if (shouldFocus) {
          $element[0].focus();
        }
      });

    }
  };
})

.controller('ScenarioEndController', ['logger', '$scope', '$sce', 'Utils', 'UiUnits', '$state', 'bngApi', '$stateParams', 'CampaignResults', '$timeout', 'gamepadNav',
function (logger, $scope, $sce, Utils, UiUnits, $state, bngApi, $stateParams, CampaignResults, $timeout, gamepadNav) {
  bngApi.engineLua('UI.unlockFPS();');
  var crossfireEnabled = gamepadNav.crossfireEnabled();
  var gamepadNavEnabled = gamepadNav.gamepadNavEnabled();
  var spatialNavEnabled = gamepadNav.spatialNavEnabled();
  gamepadNav.enableCrossfire(false);
  gamepadNav.enableGamepadNav(false);
  gamepadNav.enableSpatialNav(true);
  Utils.waitForCefAndAngular(() => {
    bngApi.engineLua("bindings.menuActive(true);");
  });


  var reopened = $stateParams.stats.overall === undefined;
  var _data = reopened ? CampaignResults.stats : $stateParams.stats;
  var _rewards = reopened ? CampaignResults.rewards : $stateParams.rewards;

  // if (Object.keys(_data).length === 0) {
  //   _data = {
  //    "buttons": [
  //       {
  //          "label": "ui.common.retry",
  //          "cmd": "scenario_scenarios.uiEventRetry()"
  //       },
  //       {
  //          "label": "ui.scenarios.end.freeroam",
  //          "cmd": "scenario_scenarios.uiEventFreeRoam()",
  //          "enableOnChooseReward": true
  //       },
  //       {
  //          "label": "ui.common.menu",
  //          "cmd": "openMenu",
  //          "enableOnChooseReward": true
  //       },
  //       {
  //          "label": "ui.dashboard.scenarios",
  //          "cmd": "openScenarios",
  //          "enableOnChooseReward": true
  //       }
  //    ],
  //    "overall": {
  //       "player": 94,
  //       "medal": "gold",
  //       "label": "scenarios.driver_training.driver_training.training_acceleration_braking1.5.title",
  //       "maxPoints": 1000,
  //       "community": 16.373636363635,
  //       "failed": false,
  //       "points": 940,
  //       "decimals": 1
  //    },
  //    "title": "scenarios.driver_training.driver_training.training_acceleration_braking1.5.title",
  //    "time": "00:13.12",
  //    "text": "scenarios.driver_training.driver_training.training_acceleration_braking1.5.defaultWin",
  //    "stats": [
  //       {
  //          "points": 940,
  //          "predefinedUnit": "s",
  //          "community": 75.531876747553,
  //          "relativePoints": 94,
  //          "player": 72.821851649951,
  //          "label": "Time",
  //          "value": 13.119000250474,
  //          "maxValue": 18.015197297558,
  //          "maxPoints": 1000,
  //          "decimals": 2
  //       }
  //    ]
  //   }
  // }

  // if (_rewards === undefined) {
  //   _rewards = { vehicles:
  //     [ {model: 'pigeon', config: '600'}
  //     , {model: 'pigeon', config: 'base'}
  //     ]
  //   , choices:
  //     { vehicles:
  //       [ {model: 'pigeon', config: '600'}
  //       , {model: 'pigeon', config: 'base'}
  //       ]
  //     }
  //   , other: ['Maroon', 'Cream', 'Charcoal', 'Shale Green']
  //   , money: 500
  //   }
  // }

  $scope.detailed = false;
  $scope.detailedRecord = {};
  bngApi.engineLua('scenario_scenarios.getScenario()', (scenario) => {
    $scope.$evalAsync(() => {
      $scope.scenario = scenario;
      if(scenario.lapCount == 1) {
        $scope.detailed = true;
      }
      if(scenario.detailedTimes != null) {
       _data.time = scenario.detailedTimes.normal[scenario.detailedTimes.normal.length-1].duration
        if(scenario.detailedRecord != null) {
           $scope.detailedRecord = scenario.detailedRecord;
           $scope.detailedRecord.formattedTime = _data.time;
        }
      }


    });
  });

  $scope.showRecord = function(index, total) {
    if(total)
      $scope.detailedRecord = $scope.scenario.highscores.scores[index];
    else
      $scope.detailedRecord = $scope.scenario.highscores.singleScores[index];
  };

  if (_rewards) {
    $scope.rewardChoosen = !_rewards.choices;
    $scope.sendChoosenVehicle = function (vehicle) {
      var index = -1;
      if (vehicle !== undefined) {
        index = vehicle.id;
        $scope.rewardChoosen = true;
        bngApi.engineLua(`${$scope.rewards.callback}(${index})`);
      }
    }
  }

  function setVehicleInfo (vehicleIDs, configs) {
    var res = [];
    for (var i = 0; i < vehicleIDs.length; i += 1) {
      res[i] = configs[vehicleIDs[i].model + '_' + vehicleIDs[i].config];
      res[i].id = i + 1;
    }
    return res;
  }

  if (_rewards && (_rewards.vehicles || (_rewards.choices && _rewards.choices.vehicles))) {
    bngApi.engineLua('core_vehicles.getConfigList()', (res) => {
      $scope.$evalAsync(() => {
        if (_rewards.vehicles) {
          _rewards.vehicles = setVehicleInfo(_rewards.vehicles, res.configs);
        }
        if (_rewards.choices.vehicles) {
          _rewards.choices.vehicles = setVehicleInfo(_rewards.choices.vehicles, res.configs);

          if (_rewards.choices.vehicles.length < 2) {
            $scope.sendChoosenVehicle(_rewards.choices.vehicles[0]);
          }
        }
        $scope.rewards = _rewards;
      });
    });
  }

  CampaignResults.stats = _data;
  CampaignResults.rewards = _rewards;
  $scope.data = _data;

  logger.debug($scope.data);

  // console.log(JSON.stringify($stateParams.stats, null, '   '));
  // // $stateParams.stats = testData();
  // if (Object.keys($stateParams.stats).length > 1) {
  //   var help = $stateParams.stats;
  //   help.stats = help.stats.map((elem) => {
  //     if (elem.player !== undefined) {
  //       elem.player = Math.min(Utils.roundDec(elem.player, 0), 100);
  //     } else if (elem.numPassed !== undefined) {
  //       elem.numPassed = Math.min(Utils.roundDec(elem.numPassed, 0), 100);
  //     }
  //     return elem;
  //   });
  //   help.overall.player = Math.min(Utils.roundDec(help.overall.player, 0), 100);
  //   help.required = help.stats.filter((elem) => elem.required);
  //   help.stats = help.stats.filter((elem) => !elem.required);
  //   $scope.data = help;
  // } else {
  //   $scope.data = CampaignResults.stats;
  // }

  $scope.BBToHtml = function (code) {
    console.log(code);
    return $sce.trustAsHtml(Utils.parseBBCode(code));
  };

  $scope.activeButton = $scope.data.buttons.length - 1;

  for (var i = $scope.data.buttons.length - 1; i >= 0; i--) {
    if ($scope.data.buttons[i].active) {
      $scope.activeButton = i;
    }
  }

  var cmds = {
    openMenu: function () {
      $scope.$emit('MenuToggle', true);
    },
    openScenarios:function(){
      $scope.$emit('MenuToggle', true);
      setTimeout(function() {$state.go('menu.scenarios');});
    },

    openQuickrace:function(){
      $scope.$emit('MenuToggle', true);
      setTimeout(function() {$state.go('menu.quickraceOverview');});
    },
    openCampaigns:function(){
      $scope.$emit('MenuToggle', true);
      setTimeout(function() {$state.go('menu.campaigns');});
    }
  };

  function execHelper (cmd) {
    var luaCmd = cmds[cmd] === undefined;
    return {
      func: luaCmd ? () => bngApi.engineLua(cmd) : cmds[cmd],
      exits: luaCmd
    };
  }

  $scope.executeCmd = function (cmdStr, showLoadingScreen) {
    console.log(cmdStr)
    var cmd = execHelper(cmdStr);

    if (cmd.exits) {
      $scope.$emit('StickyState', null);
    }
    cmd.func();
  };

  $scope.getMedalInfo = function (medal) {
    if (medal === 'wood' ) {
      return {
        img: 'modules/scenariocontrol/medal_wooden.png',
        sound: {animationstart: 'event:>UI>Scenario End Failed'}
      };
    } else if (medal === 'bronze') {
        return {
          img: 'modules/scenariocontrol/medal_bronze.png',
          sound: {animationstart: 'event:>UI>Scenario End Bronze'}
        };
    } else if (medal === 'silver') {
        return {
          img: 'modules/scenariocontrol/medal_silver.png',
          sound: {animationstart: 'event:>UI>Scenario End Silver'}
        };
    } else if (medal === 'gold') {
        return {
          img: 'modules/scenariocontrol/medal_gold.png',
          sound: {animationstart: 'event:>UI>Scenario End Gold'}
        };
    }
  };

  $scope.getBarSound = function (i) {
    if (i === 0) {
      return {animationstart: 'event:>UI>Scenario End Counting'};
    }
    return {};
  };


  // $scope.testForUnit = function (obj, val) {
  //   if (obj.unit !== undefined) {
  //     return UiUnits.buildString(obj.unit, val, (obj.decimals || 0));
  //   } else if (obj.predefinedUnit !== undefined) {
  //     return Utils.roundDec(val, obj.decimals || 0) + ' ' + obj.predefinedUnit;
  //   } else {
  //     return Utils.roundDec(val, obj.decimals || 0);
  //   }
  // };

  $scope.$on('$destroy', () => {
    // CampaignResults.stats = $scope.data;
    $scope.$emit('ShowApps', true);
    bngApi.engineLua('UI.limitFPSDefault();');
    gamepadNav.enableCrossfire(crossfireEnabled); // use old value from before opening the menu here
    gamepadNav.enableGamepadNav(gamepadNavEnabled); // use old value here
    gamepadNav.enableSpatialNav(spatialNavEnabled); // use old value here
    bngApi.engineLua("bindings.menuActive(false);");
  });

  setTimeout(function() {
    $scope.$emit('StickyState', $state.$current.name);
    $scope.$emit('ShowApps', false);
  });

  $scope.toggleDetail = function () {
    $scope.$evalAsync(() => {
       $scope.detailed = !$scope.detailed;
    });
  };
}])




// canvas for rendering comics
.directive('spineAnimation', ['bngApi', '$q', 'logger', '$rootScope', function (bngApi, $q, logger, $rootScope) {
  return {
    template: `
      <canvas class="filler"></canvas>
    `,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      'use strict';
      var animation = [] //'campaigns/chapter2/cutscenes/crawl/crawlp1/', 'campaigns/chapter2/cutscenes/crawl/crawlp2/', 'campaigns/chapter2/cutscenes/crawl/crawlp3/', 'campaigns/chapter2/cutscenes/crawl/crawlp4/'
        , currentBasePath
        , index = 0
        , canvas = element.find('canvas')[0]
        , context = canvas.getContext("2d", {alpha: false})
        , render = () => {}
        , load = () => {}
        , nextStart
        , continueLoop = true
        , finish = () => {}
        , soundPath
      ;
        var skeletonRenderer = new spine.canvas.SkeletonRenderer(context);
        // enable debug rendering
        // skeletonRenderer.debugRendering = true;
        // enable the triangle renderer, supports meshes, but may produce artifacts in some browsers
        skeletonRenderer.triangleRendering = true;

      // allow to load asstes eventhough the comic currently playing isn't finished yet
      // returned funciton will start the loaded comic
      function init (assets, path, sounds) {
        var assetManager = new spine.canvas.AssetManager();
        var skeletons = loadAssets(assets, assetManager, path);

        // context = canvas.getContext("2d", {alpha: false});
        logger.spine.log(path)

        currentBasePath = '/../' + path;


        var deferred = $q.defer();

        load = createLoad(assetManager, skeletonRenderer, skeletons, sounds, (renderFunc) => {deferred.resolve(renderFunc)});
        requestAnimationFrame(load);

        return deferred.promise;
      }

      // get all assets in folder
      function loadAssets (list, assetManager, path) {
        var skeletons = [];
        for (var i = 0; i < list.length; i += 1) {
          if (list[i].slice(-4) === '.png') {
            assetManager.loadTexture(list[i]);
          } else {
            assetManager.loadText(list[i]);
          }

          if (list[i].slice(-5) === '.json') {
            skeletons.push(list[i].slice(('/../' + path).length, -5));
          }
        }
        return skeletons;
      }

      // if several skeletons exist wait for the last one to finishe before going to next
      function createFinished (skeletons) {
        var count = 0;
        return (force) => {
          count += 1;
          if (count === skeletons.length || force) {
            logger.spine.warn('start timer');
            logger.spine.time('timeBtwComics');
            continueLoop = false;

            if (nextStart !== undefined && !force) {
              nextStart.then((renderFunc) => {
                logger.spine.warn('startNextComic');
                renderFunc();
                nextStart = undefined;
              });
            } else {
              logger.spine.error('end timer')
              logger.spine.timeEnd('timeBtwComics');
              bngApi.engineLua('UI.limitFPSDefault();');
              bngApi.engineLua('extensions.hook("onSpineAnimationFinished")');
              $rootScope.$broadcast('SpineAnimationFinished');
            }
          }
        };
      }

      // use closure rather than globals, so each comic has it's own data and there is as few shared variables as possible
      function createLoad (assetManager, skeletonRenderer, skeletons, sounds, callback) {
        return () => {
          if (assetManager.isLoadingComplete()) {
            var data = [];
            for (var i = 0; i < skeletons.length; i += 1) {
              logger.spine.log('loading skeleton', skeletons[i]);
              data[i] = loadSkeleton(skeletons[i], 'animation', 'default', assetManager);
            }
            callback(() => {
              finish = createFinished(skeletons);
              render = createRender(data, (Date.now() / 1000), skeletonRenderer, skeletons, sounds)
              // not nice, but works for this time, since we just came from an animation frame + saves about 10-15ms
              render();
            });
          } else {
            // todo: rewrite as hook. not that much gain, but this kinda hurts
            requestAnimationFrame(load);
          }
        }
      }


      function loadSkeleton (name, initialAnimation, skin, assetManager) {
        if (skin === undefined) skin = "default";

        // Load the texture atlas using name.atlas and name.png from the AssetManager.
        // The function passed to TextureAtlas is used to resolve relative core_paths.
        var atlas = new spine.TextureAtlas(assetManager.get(currentBasePath + name + ".atlas"), function(path) {
          return assetManager.get(currentBasePath + path);
        });

        // Create a AtlasAttachmentLoader, which is specific to the WebGL backend.
        var atlasLoader = new spine.AtlasAttachmentLoader(atlas);

        // Create a SkeletonJson instance for parsing the .json file.
        var skeletonJson = new spine.SkeletonJson(atlasLoader);

        // Set the scale to apply during parsing, parse the file, and create a new skeleton.
        var skeletonData = skeletonJson.readSkeletonData(assetManager.get(currentBasePath + name + ".json"));
        var skeleton = new spine.Skeleton(skeletonData);
        skeleton.flipY = true;
        var bounds = calculateBounds(skeleton);
        skeleton.setSkinByName(skin);

        // Create an AnimationState, and set the initial animation in looping mode.
        var animationState = new spine.AnimationState(new spine.AnimationStateData(skeleton.data));
        animationState.setAnimation(0, initialAnimation);
        animationState.addListener({
          event: function(trackIndex, event) {
            // logger.spine.log("Event on track " + trackIndex + ": " + JSON.stringify(event));
          },
          complete: function(trackIndex, loopCount) {
            // logger.spine.log("Animation on track " + trackIndex + " completed, loop count: " + loopCount);
          },
          start: function(trackIndex) {
            // logger.spine.log("Animation on track " + trackIndex + " started");
          },
          end: function(trackIndex) {
            logger.spine.log("Animation on track " + trackIndex + " ended");
            finish();
          }
        });

        // Pack everything up and return to caller.
        return { skeleton: skeleton, state: animationState, bounds: bounds };
      }

      function boundsHelper (offset, size, slot) {
        var minX = Number.POSITIVE_INFINITY
          , minY = Number.POSITIVE_INFINITY
          , maxX = Number.NEGATIVE_INFINITY
          , maxY = Number.NEGATIVE_INFINITY
          , vertices
        ;

        var attachment = slot.getAttachment();
        if (attachment instanceof spine.RegionAttachment)
          vertices = attachment.updateWorldVertices(slot, false);
        else if (attachment instanceof spine.MeshAttachment)
          vertices = attachment.updateWorldVertices(slot, true);

        if (vertices != null) {
          for (var ii = 0, nn = vertices.length; ii < nn; ii += 8) {
            var x = vertices[ii], y = vertices[ii + 1];
            minX = Math.min(minX, x);
            minY = Math.min(minY, y);
            maxX = Math.max(maxX, x);
            maxY = Math.max(maxY, y);
          }
        }
        // camera border width is 9 px on each side
        offset.set(minX + 9, minY + 9);
        size.set(maxX - minX - 18, maxY - minY - 18);
      }

      // at least one skeleton should have a camera attachment
      function calculateBounds(skeleton) {
        var data = skeleton.data;
        var camera = skeleton.slots.filter((elem) => (elem.attachment || {name: ''}).name === 'camera');

        // todo: fallback to spines getBounds if no camera attachment is found
        skeleton.setToSetupPose();
        skeleton.updateWorldTransform();
        var offset = new spine.Vector2();
        var size = new spine.Vector2();

        if (camera.length > 0) {
          boundsHelper(offset, size, camera[0]);
        } else {
          skeleton.getBounds(offset, size);
        }

        return { offset: offset, size: size, basedOnCam: camera.length > 0};
      }

      // use closure rather than globals, so each comic has it's own data and there is as few shared variables as possible
      function createRender (data, lFT, skeletonRenderer, skeletons, sounds) {
        var lastFrameTime = lFT
          , bounds
          , helper = data.filter((elem) => elem.bounds.basedOnCam) // there should be at least one skeleton that defines a camera
        ;
        if (helper.length > 0) {
          bounds = helper[0].bounds;
        } else {
          logger.spine.warn('no camera found', currentBasePath);
          bounds = data[0].bounds;
        }
        continueLoop = true;

        var frame = 0;

        logger.spine.log('createRender');

        logger.spinePerf.time('resize');
        resize(bounds, context, canvas);
        logger.spinePerf.timeEnd('resize');

        return () => {
          logger.spinePerf.timeEnd('timeBtwAnimationFrames')
          var now = Date.now() / 1000;
          var delta = now - lastFrameTime;
          if (frame === 0) delta = 0;
          lastFrameTime = now;
          logger.spinePerf.log('Delta', delta * 1000);

          logger.spinePerf.group();
          logger.spinePerf.time('emptying');
          emptyCanvas(context, canvas);
          logger.spinePerf.timeEnd('emptying');

          for (var i = 0; i < data.length; i += 1) {
            logger.spinePerf.time(`calc ${skeletons[i]}`);
            data[i].state.update(delta);
            data[i].state.apply(data[i].skeleton);
            data[i].skeleton.updateWorldTransform();
            logger.spinePerf.timeEnd(`calc ${skeletons[i]}`);
          }
          if (frame === 0) {
            logger.spine.error('end timer')
            logger.spine.timeEnd('timeBtwComics');
            // start loading the other assets already
            setTimeout(() => {
              index += 1;
              if (animation[index] !== undefined) {
                nextStart = findFiles(animation[index].comic || animation[index], animation[index].sound);
              } else {
                nextStart = undefined;
              }
            });
          }


          for (var i = 0; i < data.length; i += 1) {
            logger.spinePerf.time(`draw ${skeletons[i]}`)
            skeletonRenderer.draw(data[i].skeleton);
            logger.spinePerf.timeEnd(`draw ${skeletons[i]}`)
          }

          if (sounds && frame === 1) {
            for (var i = 0; i < sounds.length; i += 1) {
              logger.spine.log('playSound', sounds[i]);
              bngApi.engineLua(`Engine.Audio.playOnce('AudioGuiComic', '${sounds[i]}')`);
            }
          }


          if (frame < 5) frame += 1;

          // logger.spine.log('timestamp: ', now - lFT);
          logger.spinePerf.groupEnd();

          if (continueLoop) {
            logger.spinePerf.time('timeBtwAnimationFrames');
            requestAnimationFrame(render);
          }
        }
      }

      function resize (bounds) {
        var w = canvas.clientWidth;
        var h = canvas.clientHeight;
        if (canvas.width != w || canvas.height != h) {
          canvas.width = w;
          canvas.height = h;
        }

        var centerX = bounds.offset.x + bounds.size.x / 2;
        var centerY = bounds.offset.y + bounds.size.y / 2;
        var scaleX = bounds.size.x / canvas.width;
        var scaleY = bounds.size.y / canvas.height;
        var scale = Math.min(scaleX, scaleY);
        if (scale <= 0) scale = 0.0001;
        var width = canvas.width * scale;
        var height = canvas.height * scale;

        context.resetTransform();
        context.scale(1 / scale, 1 / scale);
        context.translate(-centerX, -centerY);
        context.translate(width / 2, height / 2);
      }


      function findFiles (animationPath) {
        var deferred = $q.defer();
        logger.spine.log('called findFiles');

        bngApi.engineLua(`dirContent("${animationPath}")`, (data) => {
          var animationFiles = data.map((elem) => '/../' + elem).filter((elem) => ['.atlas', '.json', '.png'].filter((e) => elem.endsWith(e)).length > 0);
          var soundFiles = data.filter((elem) => ['.ogg'].filter((e) => elem.endsWith(e)).length > 0);
          init(animationFiles, animationPath, soundFiles).then((renderFunc) => {
            logger.spine.warn('init resolved');
            deferred.resolve(renderFunc);
          });
        });

        return deferred.promise;
      }

      function emptyCanvas () {
        if (context !== undefined) {
          context.save();
          context.setTransform(1, 0, 0, 1, 0, 0);
          context.clearRect(0, 0, canvas.width, canvas.height);
          context.restore();
        }
      }

      scope.$on('startSpineAnimation', (ev, data) => {
        nextStart = undefined;
        index = 0;
        render = () => {}
        load = () => {}
        logger.spine.debug('got new list', data);

        animation = data.list;
        bngApi.engineLua('UI.unlockFPS();');
        if (animation[index] !== undefined) {
          findFiles(animation[index]).then((renderFunc) => {
            logger.spine.warn('startNextComic');
            renderFunc();
            if (data.backgroundSound) {
              logger.spine.log('playSound', data.backgroundSound);
              bngApi.engineLua(`Engine.Audio.playOnce('AudioGuiComic', '${data.backgroundSound}')`);
            }
          });
        }
      });

      scope.$on('$destroy', function () {
        bngApi.engineLua('UI.limitFPSDefault();');
        bngApi.engineLua('extensions.hook("onSpineAnimationFinished")');
      });


      scope.$on('forceSpineAnimationEnd', function () {
        finish(true);
      });
    }
  };
}]);



;
