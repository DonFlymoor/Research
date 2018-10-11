angular.module('beamng.stuff')

.controller('ModManagerController', function ($scope, $state, bngApi) {
  'use strict';
  var vm = this
    , map = ['local', 'repository', 'downloaded', 'scheduled'].map(e => `menu.mods.${e}`)
    // , currenStateIndex = map.indexOf($state.current.name)
    , changeState = false
    ;

  bngApi.engineLua('core_gamestate.requestGameState();');

  // $scope.$watch(() => vm.selectedTab, () => {
  //   if (vm.selectedTab !== undefined && !changeState) {
  //     $state.go(map[vm.selectedTab]);
  //   }
  //   changeState = false;
  // });

  if ($state.current.name === 'menu.mods.repository') {
    vm.selectedTab = 1;
  }
  else if ($state.current.name === 'menu.mods.local') {
    vm.selectedTab = 0;
  }

  $scope.switchState = function (newState) {
    $state.go(newState);
  }

  $scope.openModSite = () => { window.location.href = 'http-external://www.beamng.com/resources/?ingame=2'; };

  $scope.$on('$stateChangeStart', function (event, toState, toParams, fromState) {
    var index = map.indexOf(toState.name);
    if (index !== -1 && map.indexOf(fromState.name) !== -1) {
      changeState = true;
      // vm.selectedTab = map.indexOf(toState.name);
    }
  });
})

.value('ModFilterValues', {orderby: 'dateAdded', customFilter: {modType: ''}})

.controller('LocalModController', function( $scope, $state, $sce, $sanitize, bngApi, logger, UiUnits, $window, Utils, ConfirmationDialog, ModFilterValues) {
  'use strict';
  var vm = this;
  $scope.mod = '';
  vm.filter = ModFilterValues;

  // make sure the filter.html is loaded
  $scope.hasFilter = {hasFilter: true, name: 'ui.repository.filters'};

  $scope.devMode = false;


  $scope.$on('SettingsChanged', function (event, data) {
    $scope.devMode = data.values.devMode;
  });

  $scope.formatDate = function (date) {
    return UiUnits.date(new Date(date));
  };

  vm.numActiveObj = () => {return {active: $scope.activeMods, all: $scope.numberOfMods};};

  vm.deactivateAllMods = function() {
    $scope.$emit('app:waiting', true, function () {
      Utils.waitForCefAndAngular(() => {
        bngApi.engineLua('core_modmanager.deactivateAllMods()');
      });
    });
  };


  vm.activateAllMods = function() {
    $scope.$emit('app:waiting', true, function () {
      Utils.waitForCefAndAngular(() => {
        bngApi.engineLua('core_modmanager.activateAllMods()');
      });
    });
  };

  vm.openModFolderInExplorer = function() {
    bngApi.engineLua('core_modmanager.openModFolderInExplorer()');
  };

  vm.toogleActivation = function(mod, ev) {
    if (mod.active) {
      bngApi.engineLua('core_modmanager.deactivateMod("' + mod.modname + '")');
    } else {
      bngApi.engineLua('core_modmanager.activateMod("' + mod.modname + '")');
    }
    ev.stopPropagation();
  };

  vm.types = [];
  bngApi.engineLua('extensions.core_repository.uiUpdateQueue()');

  // need this method since using ui-sref breaks text alignment...
  $scope.goToMenu = function() {
    $state.go('menu.mainmenu');
  }

  $scope.$on('ModManagerModsChanged', function (event, data) {
    logger.Modmanager.log('received ModManagerModsChanged:', data);
    $scope.$emit('app:waiting', false);

    // logger.log(data);
    var list = [];
    // convert to a list, since filter does not work with objects
    var active = 0;
    for(var k in data) {

      if (vm.types.indexOf(data[k].modType) === -1) {
        vm.types.push(data[k].modType);
      }

      data[k].displaypath = data[k].fullpath;
      if(data[k].displaypath.startsWith('mods/')) {
        data[k].displaypath = data[k].displaypath.substring(5);
      }
      data[k].packed = (data[k].unpackedPath === undefined);
      data[k].dateAdded = Math.floor(data[k].dateAdded / (60 * 60 * 24))  * -1000 * 60 * 60 * 24 ;
      // the minus is a hack to sort the last added first but added on same dates alphabetically
      // Also we are only interested in the day, not the specific seconds

      list.push(data[k]);
      if(data[k].active !== false && k !== 'translations') {
        active++;
      }
    }
    list = list.filter((e) => e.modname !== 'translations')

    list = list.map(function(m){
      if (m.modInfoPath) {
        m.icon = m.modInfoPath + "icon.jpg"
      }
      // js isnt reading the unicode correctly therefore we have to convert them
      if (m.modData && m.modData.title) {
        m.modData.title = unicodeToChar(m.modData.title);
        m.modname = m.modData.title;
      }

      if (m.modData && m.modData.tag_line) {
        m.modData.tag_line = unicodeToChar(m.modData.tag_line)
      }

      // m.icon = m.modData.imgs[0];
      // m.downTxt = m.download_count>1000? (m.download_count/1000).toFixed(0)+"K": m.download_count;
      // m.rating_avg = parseFloat(m.rating_avg).toFixed(0);
      return m;
    });

    // TODO: is there a reason this is in the ModChanged hook?
    $scope.subscribe = function(evt, mod, id) {
      evt.stopPropagation();    // we need to prevent propagation so click doesn't register on the tile
      bngApi.engineLua("extensions.core_repository.modUnsubscribe(" + bngApi.serializeToLua(mod.modID || mod.modname) + ")");
    }

    $scope.$evalAsync(() => {
      vm.list = list;
      console.log(vm.list);
      // logger.Modmanager.log(list);
      $scope.numberOfMods = list.length;
      $scope.activeMods = active;
    });

  });

  $scope.toggleActivation = function(evt, mod, id) {
    evt.stopPropagation();    // we need to prevent propagation so click doesn't register on the tile
    $scope.$emit('app:waiting', true, function () {
      setTimeout(function() {
        if (mod.active) {
          bngApi.engineLua('core_modmanager.deactivateModId(' + bngApi.serializeToLua(mod.modID || mod.modname) + ')');
        } else {
          bngApi.engineLua('core_modmanager.activateModId(' + bngApi.serializeToLua(mod.modID || mod.modname) + ')');
        }
      }, 10);
    });
  };

    // unicode conversion obtained from: https://stackoverflow.com/questions/17267329/converting-unicode-character-to-string-format
    function unicodeToChar(text) {
      return text.replace(/\\u[\dA-Fa-f]{4}/g, function (match) {
        return String.fromCharCode(parseInt(match.replace(/\\u/g, ''), 16));
      });
    }

  $scope.getTypeIcon = function (str) {
    switch (str) {
      case 'vehicle':
        return 'directions_car';
      case 'terrain':
        return 'landscape';
      case 'scenario':
        return 'movie';
      case 'app':
        return 'web';
      case 'sound':
        return 'volume_up';
      default:
        return 'help';
    }
  };

  bngApi.engineLua('settings.getValue("onlineFeatures")', (data) => {
    $scope.online = data;
  });

  vm.goToDetails = function (item) {
    var itemID = (item.modID || item.id)
    if (itemID /*&& $scope.online === 'enable'*/) {
      $state.go('menu.mods.details', {modId: itemID.toUpperCase()});
    }
    else {
      // $location.path('/menu/mods/detail/'+item.tagid)
      $state.go('menu.modsDetails', {modFilePath: encodeURIComponent(item.modname)})
    }
  }

  // vm.gotoPage = function(){
  //   if(vm.subscribed_only){
  //       $scope.mode = 'requestMyMods';
  //   }
  //   else{
  //       $scope.mode = 'requestMods';
  //   }
  //   var args = [ vm.filter_query || '', vm.filter_order_by, vm.filter_order, vm.currentPage, vm.category || []];
  //   bngApi.engineLua("extensions.core_repository."+$scope.mode+"(" + $scope.argsToLua(args) +")");
  // };

  $scope.$on('$destroy', function () {
    $scope.$emit('app:waiting', false);
  });

  bngApi.engineLua('settings.requestState()');
  bngApi.engineLua('core_modmanager.requestState()');

  vm.updateAll = function (){
    bngApi.engineLua('core_modmanager.checkUpdate()');
  }

  vm.deleteAll = function() {
    ConfirmationDialog.open('ui.modmanager.deleteAll', 'ui.modmanager.deleteAllDesc', [{label: "No", key: false}, {label: "Yes", key: true}]).then((res) => {
      if (res === true) {
        $scope.$emit('app:waiting', true, function () {
          Utils.waitForCefAndAngular(() => {
            bngApi.engineLua("extensions.core_modmanager.deleteAllMods()");
          });
        });
      }
    });
  }

  $scope.$on('UpdateQueueState', function (ev, data) {
    //console.log('UpdateQueueState',data);
    if( data.metered !== undefined){
      vm.metered = data.metered;
    }

    $scope.$evalAsync(() => {
      vm.updating = data.updating
      vm.updateList = data.updatingList;
      vm.doneList = data.doneList;
    });

    $scope.$on('downloadStatesChanged', (evt, data) => {
      $scope.$evalAsync(() => {
        if( data.length === 0){vm.downState=[];return;}
        vm.downState= data;

        for (var key in vm.downState) {
          vm.updateList[key].progress = Math.floor(vm.downState[key].dlnow / vm.downState[key].dltotal * 100) > 0 ? Math.floor(vm.downState[key].dlnow / vm.downState[key].dltotal * 100) : 0;
        }
      });
    })

    /*$scope.$evalAsync(() => {
      timeout = setTimeout(function() {
        bngApi.engineLua('core_repository.uiUpdateQueue()');
      }, 1000);
    });*/

    $scope.$emit('app:waiting', false);
  });
})

.controller('DownloadModController', function ($scope, $state, bngApi, Utils) {
  'use strict';
  var vm = this
    , timeout
    ;

  // angulars orderBy seems to use id internally creating an error, so we'll rename that attribut to order and it should be fine
  function processData (e) {
    e.order = e.id;
    delete e.id;
    e.time = Utils.roundDec(e.time, 1);
    return e;
  }


  $scope.$on('OnlineRequestsState', function (ev, data) {
    var list = [];
    for (var elem in data) {
      // only keep files that are downloaded
      if (data[elem].outfile) {
        list.push(processData(data[elem]));
      }
    }
    $scope.$evalAsync(() => {
      vm.list = list;
      timeout = setTimeout(function() {
        bngApi.engineLua('core_online.getRequestsUI()');
      }, 1000);
    });
  });

  bngApi.engineLua('core_online.getRequestsUI()');

  $scope.$on('$destroy', function () {
    if (timeout) {
      clearTimeout(timeout);
    }
  });
})

.controller('ScheduledModController', function ($scope, $state, bngApi, UiUnits) {
  'use strict';
  var vm = this
    , timeout
    ;

  vm.list = [];
  vm.updateList = [];
  vm.updating = false;
  vm.metered = false;
  vm.checkingUpdates = false;
  vm.checkingMod = undefined;

  $scope.$on('checkingUpdatesEnd', function (ev, data) {
    vm.checkingUpdates = false;
    vm.checkingMod = undefined;
  });

  $scope.$on('checkUpdateCheckedMod', function (ev, data) {
    $scope.$evalAsync(() => {
      vm.checkingMod = data;
    });
  })

  $scope.selectMod = function(mod){
    mod.update = !mod.update;
    vm.selectedId = mod.id;
    if (mod.update === true) {
      vm.updateList.push(mod);
    }
  }

  $scope.showConflict = function(mod){
    vm.modConfilct = mod.filename;
    vm.selectedConflict = mod.conflict;
    $scope.hasFilter = {name: 'ui.repository.scheduled_conflicts'};
  }

  $scope.checkUpdates = function(){
    vm.checkingUpdates = true;
    vm.checkingMod = '';
    $scope.$emit('app:waiting', true, function () {
      setTimeout(function() {
        bngApi.engineLua('extensions.core_modmanager.checkUpdate()');
        $scope.checkingUpdates = false;
      }, 10);
    });
  }

  $scope.checkUpdates();

  $scope.argsToLua = function(arr){
    return arr.map(function(i){
       return bngApi.serializeToLua(i);
    }).join(',');
  };

  $scope.update = function(){
    vm.updating = true;
    var checked = [];
    for(var elem in vm.list){
      checked.push(vm.list[elem].update);
    }
    bngApi.engineLua('core_repository.updateMods( {'+$scope.argsToLua(checked)+'}  )');
  }

  $scope.$on('UpdateFinished', function (ev, data) {
    vm.updating = false;
  });


  $scope.$on('$destroy', function () {

  });
})

.controller('ModManagerControllerDetails', ['logger', '$scope', 'bngApi', '$stateParams', '$sce', '$state', 'Utils', 'UiUnits',
 function(logger, $scope, bngApi, $stateParams, $sce, $state, Utils, UiUnits) {
  'use strict';

  $scope.formatDate = function (date) {
    date = new Date(date);
    return UiUnits.date(date);
  };

  // TODO: fix the timeout
  $scope.toggleActivation = function() {
    $scope.$emit('app:waiting', true, function () {
      setTimeout(function() {
        if ($scope.mod.active) {
          bngApi.engineLua('core_modmanager.deactivateMod("' + $scope.mod.modname + '")');
        } else {
          bngApi.engineLua('core_modmanager.activateMod("' + $scope.mod.modname + '")');
        }
      }, 10);
    });
  };

  $scope.togglePackaged = function() {
    $scope.$emit('app:waiting', true, function () {
      setTimeout(function() {
        if ($scope.mod.packed) {
          bngApi.engineLua('core_modmanager.unpackMod("' + $scope.mod.modname + '")');
        } else {
          bngApi.engineLua('core_modmanager.packMod("' + $scope.mod.fullpath + '")');
        }
      }, 10);
    });
  };

  $scope.openInExplorer = function() {
    bngApi.engineLua('core_modmanager.openEntryInExplorer("' + $scope.mod.modname + '")');
  };

  $scope.deleteMod = function(gamestate) {
    bngApi.engineLua('core_modmanager.deleteMod("' + $scope.mod.modname + '")');
    $state.go((gamestate === 'menu' ? 'menu' : 'menu') + '.mods.local');
  };

  // TODO ask thomas about the lower case thing
  var passedPath = decodeURIComponent($stateParams.modFilePath).toLowerCase().trim();

  $scope.$on('ModManagerModsChanged', function (event, data) {
    logger.Modmanager.log('received ModManagerModsChanged:', data);
    $scope.$emit('app:waiting', false);

    if (data[passedPath]) {
      $scope.$evalAsync(function () {
        $scope.mod = data[passedPath];
        $scope.mod.packed = ($scope.mod.unpackedPath === undefined);
        if ($scope.mod.modData) {
          //$scope.mod.modData.imgs = ($scope.mod.modData.images || []).slice(0, 2);
          $scope.mod.modData.html = $sce.trustAsHtml(Utils.parseBBCode($scope.mod.modData.text));
        }
      });
    } else {
      logger.error('[modmanager.js] could not load mod data for vehicle: ', passedPath);
    }
    setTimeout(function () {
      // logger.group();
      // logger.log('modmanager')('passedPath: ', passedPath);
      // logger.table(data);
      // logger.log('modmanager')('data[path]: ', data[passedPath]);
      // logger.log('modmanager')('$scope.mod: ', $scope.mod);
      // logger.groupEnd();
    });
  });

  $scope.$on('$destroy', function () {
    $scope.$emit('app:waiting', false);
  });

  $scope.$on('ModManagerVehiclesChanged', function (event, data) {
    logger.Modmanager.log('received ModManagerVehiclesChanged:', data);
    $scope.$emit('app:waiting', false);
    $scope.$apply(function() {
      $scope.vehicles = data;
    });
  });

  bngApi.engineLua('settings.requestState()');
  bngApi.engineLua('core_modmanager.requestState()');
}]);
