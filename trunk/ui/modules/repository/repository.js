angular.module('beamng.stuff')

.value('RepoFilter', {filter_query: '', filter_order_by:'update', filter_order:'desc', currentPage:1, category:[3, 4, 5, 6, 7, 8, 9, 10, 12, 13, 15], subscribed_only: false })
.value('RepoCategories',[{ category: 'vehicles', name: 'ui.repository.cat_veh_land',     value:3  , originalTxt:"Land"},
  { category: 'vehicles', name: 'ui.repository.cat_veh_air',      value:4  , originalTxt:"Air"},
  { category: 'vehicles', name: 'ui.repository.cat_veh_props',    value:5  , originalTxt:"Props"},
  { category: 'vehicles', name: 'ui.repository.cat_veh_boats',    value:6  , originalTxt:"Boats"},
  { category: 'vehicles', name: 'ui.repository.cat_veh_config',   value:14 , originalTxt:"Configurations"},

  { category: 'none',     name: 'ui.repository.cat_scenarios',    value:8  , originalTxt:"Scenarios"},
  { category: 'none',     name: 'ui.repository.cat_terrain',      value:9  , originalTxt:"Terrains, Levels, Maps"},
  { category: 'none',     name: 'ui.repository.cat_ui',           value:10 , originalTxt:"User Interface Apps"},
  { category: 'none',     name: 'ui.repository.cat_sound',        value:13 , originalTxt:"Sounds"},
  { category: 'none',     name: 'ui.repository.cat_idplate',      value:15 , originalTxt:"License Plates"},
  { category: 'none',     name: 'ui.repository.cat_yo-dawg-mod',  value:7  , originalTxt:"Mods of Mods"},
  { category: 'none',     name: 'ui.repository.cat_skin',         value:12 , originalTxt:"Skins"},
])
/**
 * @ngdoc controller
 * @name beamng.stuff:RepositoryController
 * @description Controller used in level selecting view
**/
.controller('RepositoryController',  ['$scope', '$location', 'bngApi', '$state', '$timeout', 'RepoFilter', '$sce', '$sanitize', 'Utils', 'RepoCategories',
  function($scope, $location, bngApi, $state, $timeout, RepoFilter, $sce, $sanitize, Utils, RepoCategories) {
  var vm = this;

  // bngApi.engineLua('UI.unlockFPS();');

  $scope.hasFilter = {hasFilter: true, name: 'ui.repository.filters'};
  vm.data = [];
  vm.onlineState = false;
  vm.loadingPage = false;
  vm.loadTimeout = false;
  bngApi.engineLua('settings.getValue("onlineFeatures")', (data) => {
    $scope.online = data;
  });
  bngApi.engineLua('Engine.Online.isAuthenticated()', (data) => {
    vm.onlineState = data;
    if(vm.onlineState){
      vm.gotoPage();
    }
  });
  $scope.$on("OnlineStateChanged", function(evt, data) {
    vm.onlineState = data;
    if(vm.onlineState){
      vm.gotoPage();
    }
  });

  vm.categories = RepoCategories;
  vm.category = RepoFilter.category;
  vm.filter_order = RepoFilter.filter_order;
  vm.filter_order_by = RepoFilter.filter_order_by;
  vm.filter_query  = RepoFilter.filter_query;
  vm.currentPage = RepoFilter.currentPage;
  vm.subscribed_only = RepoFilter.subscribed_only;

  $scope.$on("$destroy", function() {
    RepoFilter.category = vm.category;
    RepoFilter.filter_order = vm.filter_order;
    RepoFilter.filter_order_by = vm.filter_order_by;
    RepoFilter.filter_query = vm.filter_query;
    RepoFilter.currentPage = vm.currentPage;
    RepoFilter.subscribed_only = vm.subscribed_only;

    $timeout.cancel(timeOut);
    // bngApi.engineLua('UI.limitFPSDefault();');
  });

  $scope.argsToLua = function(arr){
    return arr.map(function(i){
       return bngApi.serializeToLua(i);
    }).join(',');
  };

  $scope.showMods = function (event, pnewdata) {
    vm.loadingPage = false;
    vm.loadTimeout = false;
    if (pnewdata.repoMsg) {
      vm.repoMsg = pnewdata.repoMsg;
      vm.repoMsg.msg = $sce.trustAsHtml(Utils.parseBBCode($sanitize(pnewdata.repoMsg.msg)));
    }
    if( pnewdata.metered !== undefined && pnewdata.metered){
      vm.metered = pnewdata.metered;
    }
    if(pnewdata.count === 0) {
      $scope.$apply(function () {
        $scope.nOfPages = 0;
        vm.modData = [];
      });
      return;
    }
    $scope.$apply(function () {
      vm.loadingPage = false;
      $scope.nOfPages = Math.ceil(pnewdata.count/12);
      //create thumbnail links
      vm.modData = pnewdata.data.map(function(m){
        m.icon = "https://api.beamng.com/s1/v4/download/mods/" + m.path + "icon.jpg"
        m.downTxt = m.download_count>1000? (m.download_count/1000).toFixed(0)+"K": m.download_count;
        m.rating_avg = parseFloat(m.rating_avg).toFixed(0);
        return m;
      });
      //console.warn(vm.modData);
    });
  };

  // fetch data from Lua
  $scope.$on('ModListReceived', $scope.showMods);
  $scope.$on('MyModsReceived', $scope.showMods);


  var timeOut = $timeout(function() {
    if (vm.loadingPage === true) {
      vm.loadTimeout = true;
    }
    else {
      vm.loadTimeout = false;
    }
  }, 10000);

  vm.gotoPage = function(){
      if(!vm.onlineState){return;}
      vm.loadingPage = true;
      if(vm.subscribed_only){
          $scope.mode = 'requestMyMods';
      }
      else{
          $scope.mode = 'requestMods';
      }
      var args = [ vm.filter_query || '', vm.filter_order_by, vm.filter_order, vm.currentPage, vm.category || []];
      bngApi.engineLua("extensions.core_repository."+$scope.mode+"(" + $scope.argsToLua(args) +")");
  };

  vm.filterApply = function(){
    if(!vm.onlineState){return;}
    vm.loadingPage = true;
      if(vm.subscribed_only){
        $scope.mode = 'requestMyMods';
      }
      else{
        $scope.mode = 'requestMods';
      }
      var args = [ vm.filter_query || '', vm.filter_order_by, vm.filter_order, 1, vm.category || [] ];
      bngApi.engineLua("extensions.core_repository."+$scope.mode+"(" + $scope.argsToLua(args) +")");
      vm.currentPage = 1;
  };

  vm.setFilters = function(order_by,order){
    vm.filter_query = '';
    vm.subscribed_only = false;
    vm.filter_order_by = order_by;
    vm.filter_order = order;
    vm.filterApply();
  };

  vm.selected = vm.data[0];

  $scope.goToMenu = function() {
    $state.go('menu.mainmenu');
  }

  $scope.$on('downloadStatesChanged', (evt, data) => {
    $scope.$evalAsync(() => {
      if( data.length === 0){vm.downState=[];return;}
      vm.downState= data;
      for (var key in vm.downState) {
        vm.downState[key].progress = Math.floor(vm.downState[key].dlnow / vm.downState[key].dltotal * 100) > 0 ? Math.floor(vm.downState[key].dlnow / vm.downState[key].dltotal * 100) : 0;

        //for mod list
        for (var mkey in vm.modData) {
          if (vm.modData[mkey].filename === vm.downState[key].filename && vm.downState[key].state === 'working') {
            vm.modData[mkey].progress = vm.downState[key].progress;
          }
        }
      }
    });
  })

  // We need to check which mods have finished downloading and set their pending state to false
  $scope.$on('ModDownloaded', function(event, data) {
    for (var key in vm.modData) {
      if (vm.modData[key].tagid === data.modID) {
        vm.modData[key].pending = false;
        vm.modData[key].downState = data.state;
      }
    }
  })

  $scope.$on('RepoModChangeStatus', (evt, data) => {
    $scope.$evalAsync(() => {
      for (var key in vm.modData) {
        if (vm.modData[key].tagid === data.id) {
          vm.modData[key].sub = data.sub;
          vm.modData[key].downState = data.state;
        }
      }
    });
  })

  $scope.$on('repoError', function (ev, data) {
    $scope.$emit("toastrMsg", { type: "error", title: "Repository Error", msg: data })
  });

  $scope.subscribe = function (evt, mod, id) {
    evt.stopPropagation();    // we need to prevent propagation so click doesn't register on the tile

    if (vm.modData[id].sub === false) {
      bngApi.engineLua("extensions.core_repository.modSubscribe(" + bngApi.serializeToLua(vm.modData[id].tagid) + ")");
      bngApi.engineLua("extensions.core_repository.changeStateUpdateQueue(" + bngApi.serializeToLua(mod.filename, "updating") + ")");
      vm.modData[id].sub = true;
      vm.modData[id].pending = true;
      vm.modData[id].downState = 'updating';
    }
    else if (vm.modData[id].sub === true) {
      bngApi.engineLua("extensions.core_repository.modUnsubscribe(" + bngApi.serializeToLua(vm.modData[id].tagid) + ")");
      vm.modData[id].sub = false;
    }
  }

  $scope.updateOneMod = function (evt, mod, id) {
    evt.stopPropagation();    // we need to prevent propagation so click doesn't register on the tile

    bngApi.engineLua("extensions.core_repository.updateOneMod(" + bngApi.serializeToLua(vm.modData[id].tagid) + ")");
    vm.modData[id].downState = 'updating'; // we set this in the UI initially or else there is a big delay for the loading icon to display
  }

  vm.select = function (mod, id, subscribe) {
    $location.path('/menu/mods/detail/'+mod.tagid).search()
    vm.selected = mod;
    vm.selectedId = id;
    vm.currentPage = vm.currentPage;
  };

}])

.controller('RepositoryDetailsController',  ['$location', '$scope', '$stateParams', 'bngApi','Utils','$sce','$sanitize', '$timeout', '$http','$state','RepoFilter','RepoCategories','$filter',
  function($location, $scope, $stateParams, bngApi,Utils,$sce,$sanitize,$timeout,$http,$state,RepoFilter,RepoCategories,$filter) {
  var vm = this;

  $scope.hasFilter = {hasFilter: true, name: 'ui.repository.info', hasOwnHeader: true, back: () => history.back()};

  vm.categories = RepoCategories;

  vm.getPage = function(){
    vm.loadingPage = true;
    bngApi.engineLua("extensions.core_repository.requestMod(" + bngApi.serializeToLua($stateParams.modId) + ")");
  }
  vm.onlineState = false;
  vm.loadingPage = false;
  bngApi.engineLua('settings.getValue("onlineFeatures")', (data) => {
    $scope.online = data;
  });
  bngApi.engineLua('Engine.Online.isAuthenticated()', (data) => {
    vm.onlineState = data;
    if(vm.onlineState){
      vm.getPage();
    }else{
      vm.loadingPage = true;
      vm.onlineState = true;
      bngApi.engineLua("extensions.core_repository.requestModOffline(" + bngApi.serializeToLua($stateParams.modId) + ")");
    }
  });
  $scope.$on("OnlineStateChanged", function(evt, data) {
    vm.onlineState = data;
    if(vm.onlineState){
      vm.getPage();
    }
  });

  var timeOut = $timeout(function() {
    if (vm.loadingPage === true) {
      vm.loadTimeout = true;
    }
  }, 10000);

  $scope.$on("$destroy", function() {
    $timeout.cancel(timeOut);
  })

  $scope.$on('ModReceived', function (event, newdata) {
    $scope.$apply(function () {
      console.log("modRCV",newdata.data);
      vm.loadingPage = false;
      vm.modData = newdata.data;
      vm.modData.message = $sce.trustAsHtml(Utils.parseBBCode($sanitize(vm.modData.message)));
      vm.modData.last_update = new Date(vm.modData.last_update*1000);
      if( typeof(vm.modData.attachments) === "string"){
        vm.modData.attachments = JSON.parse(vm.modData.attachments);
      }
      vm.modData.rating_avg = Math.round(vm.modData.rating_avg);

      vm.modData.icon = "https://api.beamng.com/s1/v4/download/mods/" + vm.modData.path + "icon.jpg";
      //$sce.trustAsUrl("http-external://www.beamng.com/threads/.**");
      vm.modData.discussionThreadHref = $sce.trustAsUrl($sanitize("http-external://www.beamng.com/threads/."+vm.modData.discussion_thread_id));

      vm.modData.category = -1;
      for( c in vm.categories){
        if(vm.modData.category_title === vm.categories[c].originalTxt){
          vm.modData.category = vm.categories[c].value;
          vm.modData.category_title = $filter('translate')(vm.categories[c].name);
          break;
        }
      }

      bngApi.engineLua('core_modmanager.requestState()');
    });
  });


  $scope.$on('RepoModChangeStatus', (evt, data) => {
    if (vm.modData && vm.modData.tagid === data.id) {
      vm.modData.downState = data.state;
    }
  })

  $scope.$on('downloadStatesChanged', (evt, data) => {
    $scope.$evalAsync(() => {
      for (var key in data) {
        if (vm.modData && vm.modData.filename === data[key].filename) {
          vm.modData.downState = data[key].state;
          vm.modData.dl = data[key];
          vm.modData.dl.progress = Math.floor(data[key].dlnow / data[key].dltotal * 100);
        }
      }
    });
  })

  // We need to check which mods have finished downloading and set their pending state to false
  $scope.$on('ModDownloaded', function(event, data) {
    for (var key in vm.modData) {
      if (vm.modData.tagid === data.modID) {
        vm.modData.pending = false;
        vm.modData.downState = data.state;
      }
    }
  })

  $scope.$on('ModSubscribed', function (event, data) {
    $scope.$apply(function () {
      // if the server returns data, we presume the mod has been subscribed to
      if(data && data.modData  && data.hasOwnProperty('ok')){
        vm.modData.subscribed = true;
      }
    });
  });

  $scope.$on('ModUnsubscribed', function (event, data) {
    $scope.$apply(function () {
      if(data && data.hasOwnProperty('ok')){
        vm.modData.subscribed = false;
      }
    });
  });

  $scope.modSubscribe = function(modData){
    bngApi.engineLua("extensions.core_repository.modSubscribe(" + bngApi.serializeToLua(modData.tagid) + ")");
    // vm.modData.sub = true;
    vm.modData.pending = true;
    // vm.modData.downState = 'updating'; // we set this in the UI initially or else there is a big delay for the loading icon to display
  };

  $scope.modUnsubscribe = function(modData){
    bngApi.engineLua("extensions.core_repository.modUnsubscribe(" + bngApi.serializeToLua(modData.tagid) + ")");
    bngApi.engineLua('core_modmanager.deleteMod( extensions.core_modmanager.getModNameFromID(' + bngApi.serializeToLua(modData.tagid) + ') )');
    vm.localData = undefined;
  };

  $scope.installMod = function(m){
    //console.log(m);
    var uri = m.path + m.filename;
    var filename = m.filename;
    bngApi.engineLua("extensions.core_repository.installMod('" + uri + "','" + filename + "')");
  };


  $scope.$on('ModManagerModsChanged', function (event, data) {
    $scope.$emit('app:waiting', false);
    for (var k in data) {
      if (data[k].modID && vm.modData && data[k].modID.toUpperCase() === vm.modData.tagid) {
        // assume that if it's in this list it is installed locally
        var d = angular.copy(data[k]);
        $scope.$evalAsync(() => {
          vm.localData = d;
          vm.localData.packed = d.unpackedPath === undefined;
          bngApi.engineLua('settings.getValue("GraphicFullscreen")', (val) => {
            vm.fullScreenOn = val;
          })
        });
      }
    }
  });

  vm.togglePacked = () => {
    $scope.$emit('app:waiting', true, function () {
      // the button would not be available if there was no localData, so we do not need to check again here
      if (vm.localData.packed) {
        bngApi.engineLua('core_modmanager.unpackMod("' + vm.localData.modname + '")');
      } else {
        bngApi.engineLua('core_modmanager.packMod("' + vm.localData.fullpath + '")');
      }
    });
  };

  $scope.toggleActivation = function() {
    $scope.$emit('app:waiting', true, function () {
      setTimeout(function() {
        if (vm.localData.active) {
          bngApi.engineLua('core_modmanager.deactivateMod("' + vm.localData.modname + '")');
        } else {
          bngApi.engineLua('core_modmanager.activateMod("' + vm.localData.modname + '")');
        }
      }, 10);
    });
  };

  $scope.openDiscussion = function() {
    window.location.href = vm.modData.discussionThreadHref;
  }

  vm.openInExplorer = function() {
    bngApi.engineLua('core_modmanager.openEntryInExplorer("' + vm.localData.modname + '")');
  };

  vm.deleteMod = function() {
    bngApi.engineLua('core_modmanager.deleteMod("' + vm.localData.modname + '")');
  };

  $scope.openAuthor = function(name){
    RepoFilter.filter_query = name;
    RepoFilter.currentPage = 1;
    RepoFilter.filter_order_by='downloads';
    RepoFilter.filter_order='desc';
    RepoFilter.category=[];
    $state.go('menu.mods.repository')
  };

  $scope.openCat = function(){
    RepoFilter.filter_query = "";
    RepoFilter.currentPage = 1;
    RepoFilter.filter_order_by='downloads';
    RepoFilter.filter_order='desc';
    if(vm.modData.category === -1)
      RepoFilter.category=[];
    else
      RepoFilter.category=[vm.modData.category];
    $state.go('menu.mods.repository')
  };

}]);
