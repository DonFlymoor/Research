angular.module('beamng.stuff')

/**
  Future how to use:
  Call quickRaceLoader.getQuickraceList(), which contanis a list of levels.
  Each level has a levelInfo-property, which is the info from the info.json in the level.
  Also, each level has a routes-property list, which contains all the routes.
  After getting these, display them and let the user select them. Use the BusRouteService
  if you want to, it works for now. Let the user select a vehicle. I copied and modified
  some code of the vehicleselect-screen.
  Once you have a level, route and vehicle, call quickRaceLoader.startQuickrace(level, route, vehicle).
  This will merge the data and create one scenario file, which is then loaded by
  the scenario_scenarios.lua code.
**/

.factory('BusRouteService', function() {
  var selections= {};

  function reset () {
    selections.level = {
      name: '',
      file:null,
      preview: '/ui/images/appDefault.png',
      targetState:'busRoutesLevelSelect'
    };
    selections.route = {
      name: '',
      file:null,
      preview: '/ui/images/appDefault.png',
      targetState:'busRoutesRouteSelect',
      disabled: true
    };
    selections.vehicle = {
      name: '',
      file:null,
      preview: '/ui/images/appDefault.png',
      targetState: {state: 'vehicles', args: {mode: 'busRoutes'}}
    };
  }

  reset();

  return {
    getSelections:  function()        { return selections;            },
    setLevel:       function(level)   { selections.level    = level;  },
    setRoute:       function(route)   { selections.route    = route;  },
    setVehicle:    function(vehicle)  { selections.vehicle   = vehicle; },
    reset : reset,
    accessibility: function () {
      for (var key in selections) {
        selections[key].disabled = key === 'route';
      }
    }
  };
})

.controller('BusRoutesController', ['$filter', '$scope', '$state', '$interval', 'bngApi', '$stateParams', 'Aux','BusRouteService', 'VehicleSelectConfig', 'gamepadNav',
  function($filter,  $scope, $state, $interval, bngApi, $stateParams, Aux, BusRouteService, VehicleSelectConfig, gamepadNav) {
    // console.warn('LOADED');
  var prevCross = gamepadNav.crossfireEnabled()
    , prevGame = gamepadNav.gamepadNavEnabled()
    , prevSpatial = gamepadNav.gamepadNavEnabled()
  ;


  $scope.setDesc = function(desc) {
    $scope.$evalAsync(function() {
      $scope.selectedDesc = desc
    })
  }

  gamepadNav.enableCrossfire(false);
  gamepadNav.enableGamepadNav(false);
  gamepadNav.enableSpatialNav(true);

  $scope.$emit('ShowApps', false);  // hide apps when time trials is open

  var highscores = [];
  var tmpVehicle = null;
  var todNames = ['night','sunrise','morning','earlyNoon','noon','lateNoon','afternoon', 'evening', 'sunset'];
  $scope.showLapRecords = false;
  //local tod = {   0.5,    0.755,    0.8,        0.9,        0,      0.1,      0.175,       0.23,      0.245}

  $scope.todChanged = function() {
    $scope.selections.route.file.todText = "{{ :: 'ui.quickrace.tod." + todNames[$scope.selections.route.file.tod%9]+"' | translate }}";
  }

  $scope.isDisabled = function () {
    return !$scope.selections.level.file || !$scope.selections.route.file || !$scope.selections.vehicle.file;
  };


  // register quickrace configuration for vehicleselector
  if (VehicleSelectConfig.configs['busRoutes'] === undefined) {
    VehicleSelectConfig.addConfig('busRoutes', {
      hide: {
        'removeBtns': true,
        'spawnNew': true
      },
      backButtonRef : '^.busRoutes',
      selected: (carObj, model, config, color, spawnNew) => {
        if(config == null ) config = carObj.default_pc;
        if(color == null ) color = carObj.default_color;
        //console.log(carObj);
        BusRouteService.setVehicle({
          official: carObj.aggregates.Source['BeamNG - Official'],
          model: model,
          config: config,
          color: color,
          name: carObj.Name,
          preview: carObj.preview,
          targetState: {state: 'vehicles', args: {mode: 'busRoutes'}},
          file: carObj

        });

        VehicleSelectConfig.configs['busRoutes'].backButtonRef = '^.busRoutes';
        $state.go(`^.busRoutes`);
      },
      selectButton: 'ui.quickrace.selectVehicle',
      parentState: 'menu',
      name: 'busRoutes',
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


  $scope.difText = function (num) {
    var val = ['Easy', 'Medium', 'Hard', 'Very Hard'];
    return val[Math.floor(parseFloat(num)/25)];
  }


  $scope.selections = BusRouteService.getSelections();



  if($stateParams.level && $stateParams.level.name ) {
    var preview = null;
    if($stateParams.level.previews.length > 0) {
      preview = $stateParams.level.previews[Math.floor(Math.random() * $stateParams.level.previews.length)];
    }
    BusRouteService.setLevel({
      name: $stateParams.level.name,
      preview: preview,
      file:$stateParams.level,
      targetState:'busRoutesLevelSelect',
      disabled: true
    });
  }

  if($stateParams.route && $stateParams.route.name)
  {
    BusRouteService.setRoute({
      name: $stateParams.route.name,
      file: $stateParams.route,
      preview: $stateParams.route.previews,
      reversePreview: $stateParams.route.reversePreview,
      targetState:'busRoutesRouteSelect',
      disabled: true
    });
  }

  bngApi.engineLua('core_vehicles.getCurrentVehicleDetails()', (res) => {
    // console.log(res);
    if (BusRouteService.getSelections().vehicle.name === "") {
      BusRouteService.setVehicle({
        official: res.configs.aggregates.Source['BeamNG - Official'],
        model: res.model.key,
        config: res.current.config_key,
        color: res.current.color,
        name: res.configs.Name,
        preview: res.configs.preview,
        file: res.model,
        targetState: {state: 'vehicles', args: {mode: 'busRoutes'}}
      });
    }
  })


  // if($stateParams.vehicles ) {

     // TODO: Get the current vehile the player is driving and set it
     // TODO: Pass this ownedVehicles list as a filter to Vehicle select screen.

    //  BusRouteService.setVehicle({
    //       official: $stateParams.vehicle.carObj.aggregates.Source['BeamNG - Official'],
    //       model: $stateParams.vehicle.model,
    //       config: $stateParams.vehicle.config,
    //       color: $stateParams.vehicle.color,
    //       name: $stateParams.vehicle.carObj.Name,
    //       preview: $stateParams.vehicle.carObj.preview,
    //       targetState: {state: 'vehicles', args: {mode: 'quickrace'}},
    //       file: $stateParams.vehicle.carObj
    //     });
  // }

  $scope.getTargetState = function (card) {
    if (card.disabled) {
      return '.';
    } else if (typeof card.targetState === 'string') {
      return `^.${card.targetState}`;
    }
    return `^.${card.targetState.state}(${JSON.stringify(card.targetState.args)})`;
  }


  $scope.changeLaps = function() {
      if($scope.selections.route.file.lapCount == 0 && $scope.selections.route.file.allowRollingStart)
        $scope.selections.route.file.rollingStart = true;

  }

  // bngApi.engineLua('extensions.load("scenario_busdriverLoader")');

  $scope.startRoute = function() {
    // if($scope.selections.level.file == null) {
    //   console.log("no level specified!");
    //   return;
    // }
    // if($scope.selections.route.file == null) {
    //   console.log("no route specified!");
    //   return;
    // }
    // if($scope.selections.vehicle.file == null) {
    //   console.log("no vehicle specified!");
    //   return;
    // }
    // var lCode = bngApi.serializeToLua($scope.selections.level.file)
    // var tCode = bngApi.serializeToLua($scope.selections.route.file)
    // var vCode = bngApi.serializeToLua($scope.selections.vehicle)
    // var luaCode = 'scenario_quickRaceLoader.startQuickrace(' + lCode + ' , ' + tCode + ' , ' + vCode + ')';

    $scope.selections.route.file.userSelectedVehicle = $scope.selections.vehicle;

    // $scope.selections.route.file.isBusScenario = true;

    var luaCode = 'extensions.scenario_scenariosLoader.start(' + bngApi.serializeToLua($scope.selections.route.file) + ')';

    var busRoute = {};
    if ($scope.selections.level.file && $scope.selections.route.file && $scope.selections.vehicle) {
      bngApi.engineLua(luaCode);
      BusRouteService.reset();
      $scope.$emit('CloseMenu');
    }
  };

  $scope.toggleShowLapRecords = function() {
    $scope.showLapRecords = !$scope.showLapRecords;
  }

  $scope.settingsChanged = function() {
    if(!$scope.selections.level.file || !$scope.selections.route.file ) {
      $scope.$evalAsync(function () {
        $scope.highscores = [];
      });
      return;
    }

    var luaCmd = 'core_highscores.getScenarioHighscores("';
    luaCmd = luaCmd + $scope.selections.route.file.levelName + '","';
    luaCmd = luaCmd + $scope.selections.route.name + '","';



    var configKey = "standing";
    if($scope.selections.route.file.rollingStart && $scope.selections.route.file.lapCount > 0 && !$scope.showLapRecords)
      configKey = "rolling";
    if($scope.selections.route.file.reverse)
      configKey += "Reverse";
    if(!$scope.showLapRecords)
      configKey +=  $scope.selections.route.file.lapCount;
    else
      configKey += 0;

    luaCmd = luaCmd + 'busRoute")';;
    tmpVehicle = BusRouteService.getSelections().vehicle;

    bngApi.engineLua(luaCmd, function(res) {
      $scope.$evalAsync(function () {
        $scope.highscores = res;
      });
    });



  }
  $scope.settingsChanged();
  $scope.$on('$destroy', () => {
    gamepadNav.enableCrossfire(prevCross);
    gamepadNav.enableGamepadNav(prevGame);
    gamepadNav.enableSpatialNav(prevSpatial);
    $scope.$emit('ShowApps', true); // show apps again once time trial is closed
  });

  var popoverCounter = 0;
  $scope.showRecord = function(index) {
    if($scope.highscores[index].vehicleModel == null)
      return;
    var luaCmd = "core_vehicles.getModel('" + $scope.highscores[index].vehicleModel + "')";
    popoverCounter++;
    var current = popoverCounter;
     bngApi.engineLua(luaCmd, function(res) {
      if(popoverCounter != current)
        return;
      $scope.$evalAsync(function () {
        $scope.selections.vehicle = {}
        $scope.selections.vehicle.file = {}
        $scope.selections.vehicle.file.Brand = res.model.Brand;
        $scope.selections.vehicle.file.Country = res.model.Country;
        $scope.selections.vehicle.file['Derby Class'] = res.model['Derby Class'];
        $scope.selections.vehicle.name = res.configs[$scope.highscores[index].vehicleConfig].Name;
        $scope.selections.vehicle.preview = [];
        $scope.selections.vehicle.preview[0] = res.configs[$scope.highscores[index].vehicleConfig].preview;

      });
    });

  };

  $scope.selectRecord = function(index) {
    if($scope.highscores[index].vehicleModel == null)
      return;
    var luaCmd = "core_vehicles.getModel('" + $scope.highscores[index].vehicleModel + "')";
    popoverCounter++;
    var current = popoverCounter;
     bngApi.engineLua(luaCmd, function(res) {
      if(popoverCounter != current)
        return;
      $scope.$evalAsync(function () {
        $scope.selections.vehicle.brand = res.model.Brand;
        $scope.selections.vehicle.file = res.model;
        $scope.selections.vehicle.file['Derby Class'] = res.model['Derby Class'];
        $scope.selections.vehicle.color = res.configs[$scope.highscores[index].vehicleConfig].default_color;
        $scope.selections.vehicle.name = res.configs[$scope.highscores[index].vehicleConfig].Name;
        $scope.selections.vehicle.preview = [];
        $scope.selections.vehicle.preview[0] = res.configs[$scope.highscores[index].vehicleConfig].preview;
        $scope.selections.vehicle.config = $scope.highscores[index].vehicleConfig
        $scope.selections.vehicle.model = $scope.highscores[index].vehicleModel
        tmpVehicle = $scope.selections.vehicle;
      });
    });
  };

$scope.hideRecord = function () {
      popoverCounter++;
    var current = popoverCounter;
  $scope.$evalAsync(function () {
    if(popoverCounter != current)
        return;
    $scope.selections.vehicle = tmpVehicle;
  });

};


}])
.controller('BusRoutesLevelController', ['$filter', 'BusRouteService', '$scope', '$state', '$interval', 'bngApi', 'Aux',
  function($filter, BusRouteService, $scope, $state, $interval, bngApi, Aux) {

  $scope.filtered = [];
  $scope.selected = null;

  bngApi.engineLua('scenario_scenariosLoader.getLevels("bus")', function(res) {
    showList(res);
  });


  function showList(res) {
    $scope.$evalAsync(() => {
      $scope.filtered = res;
      $scope.selected = $scope.filtered[0];
    });
  }

  // TODO: select the first entry of the filtered list always
  var selectedTimer = 0;//Timer to make previews one by one in a certain duration

  function changePreview() {
    $scope.selected.preImgIndex++;
    if ($scope.selected.preImgIndex > $scope.selected.previews.length - 1) {
      $scope.selected.preImgIndex = 0;
    }
    $scope.selected.preview = $scope.selected.previews[$scope.selected.preImgIndex];
  }

  $scope.selectLevel = function(level) {
    $interval.cancel(selectedTimer);
    $scope.selected = level;
    if (!$scope.selected.previews) {
      $scope.selected.preview = null;
      return;
    }
    $scope.selected.preview = $scope.selected.previews[$scope.selected.preImgIndex];
    if ($scope.selected.previews.length > 1) {
      selectedTimer = $interval(changePreview, 3000);
    }
  };

  $scope.startLevel = function(scenario, gameState, goToRoute) {
    //scenario.raceFile = "quickrace/skycurve1"
    //var luaCmd = 'scenario_scenarios.start(' + bngApi.serializeToLua(scenario) + ')';
    //bngApi.engineLua(luaCmd);
    var preview = null;
    if(scenario.previews.length > 0) {
      preview = scenario.previews[Math.floor(Math.random() * scenario.previews.length)];
    }
    BusRouteService.setLevel({
      name: scenario.levelInfo.title,
      preview: preview,
      file:scenario,
      targetState:'busRoutesLevelSelect',
    });
    BusRouteService.setRoute({
      name: 'Select Route',
      file: null,
      targetState:'busRoutesRouteSelect',
      preview: '/ui/images/appDefault.png'
    });

    if(goToRoute) {
      $state.go(`^.busRoutesRouteSelect`);
    } else {
      $state.go(`^.busRoutes`);
    }
  };
}])
.controller('BusRoutesRouteController', ['$filter', 'BusRouteService', '$scope', '$state', '$interval', 'bngApi', 'Aux', 'VehicleSelectConfig',
  function($filter, BusRouteService, $scope, $state, $interval, bngApi, Aux, VehicleSelectConfig) {

  var levelName = BusRouteService.getSelections().level.name;
  var available = [];
  $scope.filtered = [];
  $scope.selected = null;
  $scope.query = '';

  $scope.tilesOrder = [
    {label: 'Difficulty', key: 'difficulty'},
    {label: 'Date',       key: '-date'},
    {label: 'Author',     key: 'authors'},
    {label: 'Players',    key: '-maxPlayers'},
  ];

  $scope.selectedOrder = $scope.tilesOrder[0].key;

  bngApi.engineLua("", function(res) {
    available = [];
    showList(BusRouteService.getSelections().level.file.scenarios)
    // showList(res);
  });



  function showList(res) {
    $scope.filtered = [];

    for (var i = 0; i < res.length; i++) {
      if (res[i].previews && res[i].previews.length > 0) {
        res[i].preview = res[i].previews[0];

        if (res[i].reversePreviews && res[i].reversePreviews.length > 0)
          res[i].reversePreview = res[i].reversePreviews[0];
        else
          res[i].reversePreview = null;
        res[i].preImgIndex = 0;
        res[i].maxPlayers = 0;

        for (var j in res[i].vehicles) {
            var v = res[i].vehicles[j];
            if (v.playerUsable == true) res[i].maxPlayers++;
            if (v.driver && v.driver.player == true) res[i].maxPlayers++;
        }
        if (res[i].playersCountRange) res[i].maxPlayers = res[i].playersCountRange.max;
        res[i].minPlayers = res[i].maxPlayers;
        if (res[i].playersCountRange) res[i].minPlayers = res[i].playersCountRange.min;
      }
    }

    available = res;

    $scope.$watchGroup(['query', 'selectedOrder'], function (value) {
      var temp = $filter('filter')(available, value[0]);
      temp = $filter('orderBy')(temp, [value[1], 'name']);
      $scope.filtered = temp;
      $scope.selected = $scope.filtered[0];
    });

    $scope.$digest(); // trigger the $watchGroup
  }



  // TODO: select the first entry of the filtered list always
  var selectedTimer = 0;//Timer to make previews one by one in a certain duration


  function changePreview() {
    $scope.selected.preImgIndex++;
    if ($scope.selected.preImgIndex > $scope.selected.previews.length - 1) {
      $scope.selected.preImgIndex = 0;
    }
    $scope.selected.preview = $scope.selected.previews[$scope.selected.preImgIndex];
  }

  $scope.difText = function (num) {
    var val = ['Easy', 'Medium', 'Hard', 'Very Hard'];
    return val[Math.floor(parseFloat(num)/25)];
  }

$scope.openRepo = function () {
    //window.location.href = 'http-external://www.beamng.com/resources/categories/scenario_scenarios.8/?ingame=2';
  };

  $scope.selectRoute = function(route) {
    $interval.cancel(selectedTimer);
    $scope.selected = route;
    if (!$scope.selected.previews) {
      $scope.selected.preview = null;
      return;
    }
    $scope.selected.preview = $scope.selected.previews[$scope.selected.preImgIndex];
    if ($scope.selected.previews.length > 1) {
      selectedTimer = $interval(changePreview, 3000);
    }

    if ($scope.selected.userSelectedVehicle) {
      bngApi.engineLua(`core_vehicles.getModel(${bngApi.serializeToLua($scope.selected.userSelectedVehicle.model)})`, function(data) {
        var carObj = data

        BusRouteService.setVehicle({
          official: carObj.model.aggregates.Source['BeamNG - Official'],
          model: carObj.model.key,
          config: carObj.configs[$scope.selected.userSelectedVehicle.config].key,
          color: "0.9 0.9 0.9 1.18",
          name: carObj.model.Name,
          preview: carObj.configs[$scope.selected.userSelectedVehicle.config].preview,
          targetState: {state: 'vehicles', args: {mode: 'busRoutes'}},
          file: carObj.model
        });
      });
    }
    // bngApi.engineLua('core_vehicles.getModel()', function(data) {
    //   var carObj = data

    //   BusRouteService.setVehicle({
    //     official: carObj.aggregates.Source['BeamNG - Official'],
    //     model: model,
    //     config: config,
    //     color: color,
    //     name: carObj.Name,
    //     preview: carObj.preview,
    //     targetState: {state: 'vehicles', args: {mode: 'busRoutes'}},
    //     file: carObj
    //   });
    // });
  };

  $scope.startRoute = function(route, gameState, goToVehicles) {
    //scenario.raceFile = "quickrace/skycurve1"
    //var luaCmd = 'scenario_scenarios.start(' + bngApi.serializeToLua(scenario) + ')';
    //bngApi.engineLua(luaCmd);
   // bngApi.engineLua("dump(" + bngApi.serializeToLua(route) + ")");

    if (route.reversible) {
      route.reverse = false; // init this
    }

    if (route.allowRollingStart) {
      route.rollingStart = false; // and this
    }

    BusRouteService.setRoute({
      name: route.name,
      file: route,
      preview: route.preview,
      reversePreview: route.reversePreview,
      targetState:'busRoutesRouteSelect'
    });
    if(goToVehicles && BusRouteService.getSelections().vehicle.model == null) {
      VehicleSelectConfig.configs['busRoutes'].backButtonRef = '^.busRoutesRouteSelect';
      $state.go(`menu.vehicles`, {mode: 'busRoutes'});
    } else {
      VehicleSelectConfig.configs['busRoutes'].backButtonRef = '^.busRoutes';
      $state.go(`^.busRoutes`);
    }
     //$state.go(`^.quickraceOverview`);
  };
}])

;