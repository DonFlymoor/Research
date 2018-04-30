angular.module('beamng.apps', ['oc.lazyLoad'])

.value('AppLayout', {
  current: {}
})



/**
 * @ngdoc service
 * @name beamng.apps.service:StreamsManager
 * @description Tracks the streams currently in use.
 */
.factory('StreamsManager', ['logger', 'bngApi', function (logger, bngApi) {
  var counts = {electrics: 1, sensors: 1};

  return {
    add: function (streams) {
      for (var i=0; i<streams.length; ++i) {
        logger.StreamsManager.log(`adding stream ${streams[i]} in`, counts);
        if (counts[streams[i]]) counts[streams[i]] += 1;
        else counts[streams[i]] = 1;
      }

      bngApi.activeObjectLua(`streams.setRequiredStreams(${bngApi.serializeToLua(counts)})`);
    },

    remove: function (streams) {
      for (var i=0; i<streams.length; ++i) {
        logger.StreamsManager.log(`removing stream ${streams[i]} from`, counts);
        if (!counts[streams[i]]) {
          logger.StreamsManager.warn(`Asked to remove stream ${streams[i]}, but it doesn\'t exist.`);
        } else {
          if (counts[streams[i]] === 0)
            logger.StreamsManager.warn(`Asked to remove stream ${streams[i]} but there are already 0 references.`);
          else
            counts[streams[i]] -= 1;
        }
      }

      bngApi.activeObjectLua(`streams.setRequiredStreams(${bngApi.serializeToLua(counts)})`);
    },

    reset: function () {
      logger.StreamsManager.info(`Resetting streams references.`);
      counts = {};
    },

    resubmit: function () {
      bngApi.activeObjectLua(`streams.setRequiredStreams(${bngApi.serializeToLua(counts)})`);
    }
  };
}])


/**
 * @ngdoc service
 * @name beamng.apps.service:UiAppsService
 * @description Apps-related functions. This is intented to be used from {@link beamng.apps.directive:appContainer}
 * since some of its methods require a parent scope parameter.
 */
.factory('UiAppsService', ['$compile', '$filter', '$http', '$injector', '$q', '$rootScope', '$ocLazyLoad', 'AppLayout', 'bngApi', 'RateLimiter',
function ($compile, $filter, $http, $injector, $q, $rootScope, $ocLazyLoad, AppLayout, bngApi, RateLimiter) {
  var appCount = 0;

  // Fake window resize events are a handy way to forcilly recheck apps' status. However,
  // style changing causes reflows and is in general expensive, so we just wrap it inside a debounce
  // function to avoid checking as many times as the amount of used apps.
  var _emitFakeWindowResize = RateLimiter.debounce(function () {
    $rootScope.$broadcast('windowResize', {width: window.innerWidth, height: window.innerHeight});
  }, 50);

  function spawnHelper (appData, container, parentScope, id) {
    if (!appData.domElement) {
      console.warn('please specify a DOM element in the app.json');
      return;
    }

    if (service.isAppActive(appData)) {
      console.warn(`App [${ $filter('translate')(appData.name) }] is already active. Will not add.`);
      return;
    }

    service._prepareApp(appData).then(function () {
      var appScope = parentScope.$new(true);
      appScope.name = appData.name;

      var appId = id.toString()
        , tmpl = `<bng-app appid="${appId}">${appData.domElement}</bng-app>`
        , el   = $compile(tmpl)(appScope)
      ;

      AppLayout.current[appId] = {
        element: el,
        domElement: appData.domElement,
        css: appData.css,
        noCockpit: appData.noCockpit || false,
        name: appData.name,
        directive: appData.directive,
        jsSource: appData.jsSource,
        preserveAspectRatio: (!! appData.preserveAspectRatio)
      };

      container.append(el);

      el.ready(function () {
        el.css(appData.css);
        _emitFakeWindowResize();
      });

    }, function () {
      console.error(`Failed to load ${appData.directive} directive`);
    });
  }

  var layoutSaveName;
  var service = {
    /**
     * @ngdoc method
     * @name _prepareApp
     * @methodOf beamng.apps.service:UiAppsService
     * @param {object} appData app's attributes
     * @description Loads app resources if necessary
     */
    _prepareApp: function (appData) {
      if (!$injector.has(appData.directive + 'Directive')) {
        if (appData.jsSource)
          return $ocLazyLoad.load(appData.jsSource);
        else
          return $q.reject(`ERROR: No jsSource field for ${appData.directive}`);
      } else {
        return $q.when();
      }
    },

    isAppActive: (appData) => {
      for (var _appId in AppLayout.current) {
        if (AppLayout.current[_appId].domElement === appData.domElement)
          return true;
      }

      return false;
    },


    /**
     * @ngdoc method
     * @name spawnApp
     * @methodOf beamng.apps.service:UiAppsService
     * @param {object} appData app's attributes
     * @param {object} container container element for the app
     * @param {object} parentScope app's parent scope
     * @description Adds an app to current layout
     */
    spawnApp: function (appData, container, parentScope) {
      appCount++;
      spawnHelper(appData, container, parentScope, appCount);
    },

    /**
     * @ngdoc method
     * @name getLayouts
     * @methodOf beamng.apps.service:UiAppsService
     * @description Loads available app layouts
     */
    getLayouts: function () {
      return new Promise((resolve, reject) => {
        bngApi.engineLua('core_apps.getLayouts()', (data) => {
          Object.keys(data).forEach(layout => { AppLayout[layout] = data[layout]; });
          resolve();
        })
      });
    },


    /**
     * @ngdoc method
     * @name clearCurrentLayout
     * @methodOf beamng.apps.service:UiAppsService
     * @description Removes all apps from the current layout
     */
    clearCurrentLayout: function () {
      Object.keys(AppLayout.current).map(function (appId) {
        AppLayout.current[appId].element.remove();
        delete AppLayout.current[appId];
        // $q.when(AppLayout.current[appId], () => {
        //   AppLayout.current[appId].element.remove();
        //   delete AppLayout.current[appId];
        // });
        // rejection is not important, since it won't be added to the Applayout, nor be spawned
      });
    },

    /**
     * @ngdoc method
     * @name _prepareApp
     * @methodOf beamng.apps.service:UiAppsService
     * @param {string} playmode Playmode currently in use
     * @description Saves current layout
     */
    saveCurrentLayout: function (playmode) {
      var propertiesToSave = ['domElement', 'css', 'noCockpit', 'name', 'directive', 'jsSource', 'preserveAspectRatio'];
      if (layoutSaveName !== undefined) {
          playmode = layoutSaveName;
      }
      AppLayout[playmode] = Object.keys(AppLayout.current).map(appId => 
        propertiesToSave.reduce((obj, prop) => { obj[prop] = AppLayout.current[appId][prop]; return obj; }, {}));
      
      var outLayouts = Object.keys(AppLayout).filter(x => x !== 'current').reduce((out, layout) => { out[layout] = AppLayout[layout]; return out; }, {});
      bngApi.engineLua(`core_apps.saveLayouts(${bngApi.serializeToLua(outLayouts)})`);
    },

    /**
     * @ngdoc method
     * @name loadLayout
     * @methodOf beamng.apps.service:UiAppsService
     * @param {string | Array | object} layout The layout to load
     * @param {object} container Container element that will hold the layout's apps
     * @param {object} parentScope Parent scope for the layout's apps
     * @description Loads an app layout
     */
    loadLayout: function (layout, container, parentScope) {
      service.clearCurrentLayout();

      layoutSaveName = undefined;
     
      if (typeof layout === 'string') {
        layoutSaveName = layout;
        layout = AppLayout[layout] || [];
      } else if (typeof layout === 'object' && Object.keys(layout).length > 0) {
        layout = Object.keys(layout).map((x) => layout[x]);
      } else if (!Array.isArray(layout)) {
        console.log('Bad formatted layout', layout);
        layout = [];
      }

      if (layout.length > 0) {
        layout.forEach(function(appData) {
          service.spawnApp(appData, container, parentScope);
        });
      }
    },

    /**
     * @ngdoc method
     * @name resetLayouts
     * @methodOf beamng.apps.service:UiAppsService
     * @return {Promise} A promise resolved when layouts are reset.
     * @description Reset all user layouts to the game's default ones
     */
    resetLayouts: function () {
      return new Promise((resolve, reject) => { 
        bngApi.engineLua('core_apps.resetLayouts()', (data) => {
          for (var gameState in data) AppLayout[gameState] = data[gameState];
          resolve();
        });
      });
    },

    resetLayout: function () {
      var d = $q.defer();
      var listener = $rootScope.$on('GameStateUpdate', (ev, data) => {
        bngApi.engineLua(`core_apps.resetLayout('${data.appLayout}')`, function (val) {
          AppLayout[data.appLayout] = val;

          d.resolve();
          listener();
        });
      });
      bngApi.engineLua('core_gamestate.requestGameState()');

      return d.promise;
    },

    resetPositionAttributes: function (element) {
      var top  = element.offsetTop, 
          left = element.offsetLeft;
      
      element.style.bottom = element.style.right = element.style.margin = '';
      element.style.top  = `${top}px`;
      element.style.left = `${left}px`;
    },

    alignInContainer: function (element, top, left) {
      var alignment = '';

      // Check if we are really close to the center
      var centerRadius = 40
        , rect = element.getBoundingClientRect()
        , cx = 0.5*(left + rect.right)
        , cy = 0.5*(top + rect.bottom)
        , pageCenterX = window.innerWidth / 2
        , pageCenterY = window.innerHeight / 2
      ;

      if (Math.abs(cy - pageCenterY) < centerRadius) {
        element.style.top = `${pageCenterY - rect.height/2}px`;
        alignment += 'C';
      } else {
        // element.style.top = top + 'px';
        // alignment += cy < pageCenterY ? 'T' : 'B';
        if (cy < pageCenterY) {
          element.style.top = `${top}px`;
          alignment += 'T'
        } else {
          var pxFromBottom = window.innerHeight - top - rect.height;
          pxFromBottom = Math.ceil(pxFromBottom / 5) * 5; // WARNING: HARDCODED GRID (matches the one in the bngApp controller?)
          element.style.top = `${window.innerHeight - pxFromBottom - rect.height}px`;
          alignment += 'B';
        }
      }

      if (Math.abs(cx - pageCenterX) < centerRadius) {
        element.style.left = `${pageCenterX - rect.width/2}px`;
        alignment += 'C';
      } else {
        // element.style.left = left + 'px';
        // alignment += cx < pageCenterX ? 'L' : 'R';
        if (cx < pageCenterX) {
          element.style.left = `${left}px`;
          alignment += 'L'
        } else {
          var pxFromRight = window.innerWidth - left - rect.width;
          pxFromRight = Math.ceil(pxFromRight / 5) * 5; // WARNING: HARDCODED GRID (matches the one in the bngApp controller?)
          element.style.left = `${window.innerWidth - pxFromRight - rect.width}px`;
          alignment += 'R';
        }
      }

      return alignment;
    },

    drawAlignmentHelpers: function (ctx, element, alignment) {
      var rect = element.getBoundingClientRect();

      ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
      ctx.font = '15px Roboto';

      ctx.lineWidth = 3;
      ctx.strokeStyle = 'black';
      ctx.shadowBlur = 10;
      ctx.shadowColor = 'white';
      ctx.setLineDash([3, 8]);

      if (alignment === 'CC') {
        ctx.save();
        ctx.fillStyle = 'rgba(0, 0, 0, 0.2)';
        ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height);
        ctx.clearRect(rect.left-15, rect.top-15, rect.width+30, rect.height+30);
        ctx.restore();
        return;
      }

      switch (alignment.charAt(0)) {
        case 'C':
          ctx.save();
          ctx.fillStyle = 'rgba(0, 0, 0, 0.1)';
          ctx.fillRect(0, 0, ctx.canvas.width, rect.top);
          ctx.fillRect(0, rect.bottom, ctx.canvas.width, ctx.canvas.height);
          ctx.restore();
          break;
        case 'T':
          ctx.beginPath();
          ctx.moveTo(rect.left + rect.width/2, rect.top);
          ctx.lineTo(rect.left + rect.width/2, 0);
          ctx.stroke();

          ctx.textBaseline = 'bottom';
          ctx.textAlign    = 'left';
          ctx.fillText(rect.top, rect.left + rect.width/2 + 8, rect.top - 2);
          ctx.closePath();
          break;
        case 'B':
          ctx.beginPath();
          ctx.moveTo(rect.left + rect.width/2, rect.bottom);
          ctx.lineTo(rect.left + rect.width/2, ctx.canvas.height);
          ctx.stroke();

          ctx.textBaseline = 'top';
          ctx.textAlign    = 'left';
          ctx.fillText((window.innerHeight - rect.bottom), rect.left + rect.width/2 + 8, rect.bottom + 2);
          ctx.closePath();
      }


      switch (alignment.charAt(1)) {
        case 'C':
          ctx.save();
          ctx.fillStyle = 'rgba(0, 0, 0, 0.1)';
          ctx.fillRect(0, 0, rect.left, ctx.canvas.height);
          ctx.fillRect(rect.right, 0, ctx.canvas.width, ctx.canvas.height);
          ctx.restore();
          break;
        case 'L':
          ctx.beginPath();
          ctx.moveTo(rect.left, rect.top + rect.height/2);
          ctx.lineTo(0, rect.top + rect.height/2);
          ctx.stroke();

          ctx.textBaseline = 'bottom';
          ctx.textAlign = 'right';
          ctx.fillText(rect.left, rect.left - 8, rect.top + rect.height/2 - 2);
          ctx.closePath();
          break;
        case 'R':
          ctx.beginPath();
          ctx.moveTo(rect.right, rect.top + rect.height/2);
          ctx.lineTo(ctx.canvas.width, rect.top + rect.height/2);
          ctx.stroke();

          ctx.textBaseline = 'bottom';
          ctx.textAlign = 'left';
          ctx.fillText((window.innerWidth - rect.right), rect.right + 8, rect.top + rect.height/2 - 2);
          ctx.closePath();
      }
    },

    getCssObj: function (element, alignment) {
      var rect = element.getBoundingClientRect();
      var obj = {position: 'absolute', width: `${rect.width}px`, height: `${rect.height}px`};

      if (!alignment) return obj;

      switch (alignment.charAt(0)) {
        case 'C':
          obj['top'] = 0;
          obj['bottom'] = 0;
          obj['margin'] = 'auto';
          break;

        case 'T':
          obj['top'] = `${rect.top}px`;
          obj['bottom'] = '';
          break;

        case 'B':
          obj['top'] = '';
          obj['bottom'] = `${window.innerHeight - rect.bottom}px`;
      }

      switch (alignment.charAt(1)) {
        case 'C':
          obj['left'] = 0;
          obj['right'] = 0;
          obj['margin'] = 'auto';
          break;
        case 'L':
          obj['left'] = `${rect.left}px`;
          obj['right'] = '';
          break;
        case 'R':
          obj['left'] = '';
          obj['right'] = `${window.innerWidth - rect.right}px`;
      }

      return obj;
    },

    restrictInWindow: function (element) {
      // var rect = element.getBoundingClientRect();
      // console.log('rect', rect);
      // console.log(element.offsetTop, element.offsetLeft, element.offsetLeft + element.offsetWidth, element.offsetTop + element.offsetHeight);
      if (element.offsetTop < 0) {
        // var a = rect.top;
        // console.log('it is over the top:', a, element.offsetTop);
        element.style.top = 0;
        element.style.bottom = undefined;
        // element.style.margin = undefined;
      }

      if (element.offsetLeft < 0) {
        // var a = rect.left;
        // console.log('it is out from the left side', a);
        element.style.left = 0;
        element.style.right = undefined;
        // element.style.margin = undefined;
      }

      if ((element.offsetTop + element.offsetHeight) > window.innerHeight) {
        // var a = rect.bottom;
        // console.log('it is out from the bottom:', a);
        element.style.top = undefined;
        element.style.bottom = 0;
        // element.style.margin = undefined;
      }

      if ((element.offsetLeft + element.offsetWidth) > window.innerWidth) {
        // var a = rect.right;
        // console.log('it is out from the right', a);
        element.style.left = undefined;
        element.style.right = 0;
        // element.style.margin = undefined;
      }

      // Resize as last resort!
      // rect = element.getBoundingClientRect();

      if (element.offsetTop < 0 || element.offsetTop + element.offsetHeight > window.innerHeight) {
        // console.log('still out V');
        element.style.margin = undefined;
        element.style.height = `${window.innerHeight}px`;
      }
      if (element.offsetLeft < 0 || element.offsetLeft + element.offsetWidth > window.innerWidth) {
        // console.log('still out H');
        element.style.margin = undefined;
        element.style.width = `${window.innerWidth}px`;
      }
    },

    /**
     * @ngdoc method
     * @name handleCameraChange
     * @methodOf beamng.apps.service:UiAppsService
     * @param {string} cameraMode The current camera mode
     * @description Hides/shows apps according to the camera mode in use
     */
    handleCameraChange: function (cameraMode, editMode) {
      var visibleOpacity = 1; // always fully visible
      var hiddenOpacity = 1; // fully visible in non-driver cameras
      if (cameraMode === 'onboard.driver') {
        if (editMode) hiddenOpacity = 0.7; // partially transparent while editing apps
        else hiddenOpacity = 0; // fully transparent while playing
      }
      
      Object.keys(AppLayout.current)
        .forEach(appId => {
            AppLayout.current[appId].element[0].style.opacity = AppLayout.current[appId].noCockpit? hiddenOpacity : visibleOpacity;
        });
    }
  };

  return service;
}])


/**
 * @ngdoc directive
 * @name beamng.apps.directive:appContainer
 * @require beamng.stuff.service:bngApi
 *
 * @description A custom element to include and manipulate all the apps
 * in the game.
**/
.directive('appContainer', ['$document', 'bngApi', 'RateLimiter', 'StreamsManager', 'UiAppsService', 'Utils', 'logger',
function ($document, bngApi, RateLimiter, StreamsManager, UiAppsService, Utils, logger) {
  return {
    restrict: 'E',
    template: '<div style="position: absolute; left: 0; top: 0; width: 100%; height: 100%">' +
                '<div id="container" ng-transclude style="position:relative; width: 100%; height: 100%"></div>' +
              '</div>',
    transclude: true,
    replace: true,
    controller: ['$element', '$scope', '$window', 'AppLayout',
      function ($element, $scope, $window, AppLayout) {


      var appCount  = 0
        , container = angular.element($element[0].querySelector('#container'))
        , playmode = 'freeroam'
        , canvas
      ;

      $element.ready(function () {
        canvas = $element[0].querySelector('canvas');
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
      });


      $scope.editMode = false;
      // $scope.align = 'TL';

      $scope.$on('windowResize', (_, windowSize) => {
        canvas.width = windowSize.width;
        canvas.height = windowSize.height;
      });


      // capture all the streams and pass it down to the apps
      bngApi.registerGlobalCallback('streams', function (streams) {
        Utils.deepFreeze(streams);
        $scope.$broadcast('streamsUpdate', streams);
      });


      // This must absolutely go!!!
      var __temp_load_layout__ = RateLimiter.debounce(function (data) {
        UiAppsService.loadLayout(data, container, $scope);
      }, 100);

      $scope.$on('VehicleReset', function () { StreamsManager.resubmit(); });
      $scope.$on('appContainer:clear', function () { UiAppsService.clearCurrentLayout(); });
      $scope.$on('appContainer:loadLayout', function (_, data) { UiAppsService.loadLayout(data, container, $scope); });
      $scope.$on('appContainer:spawn', function (_, data) { UiAppsService.spawnApp(data, container, $scope); });
      $scope.$on('appContainer:resetLayouts', function () {
        UiAppsService.clearCurrentLayout();
        UiAppsService.resetLayouts().then(function () {
          bngApi.engineLua('core_gamestate.requestGameState()');
        });
      });
      $scope.$on('appContainer:resetLayout', function () {
        UiAppsService.clearCurrentLayout();
        UiAppsService.resetLayout().then(function () {
          bngApi.engineLua('core_gamestate.requestGameState()');
        });
      });

      var cameraMode = null;
      $scope.$on('CameraMode', function (_, data) {
        cameraMode = data.mode;
        $scope.updateCockpitApps();
      });

      // Change editable state of the apps
      $scope.$on('editApps', function (event, state) {
        $document.triggerHandler('mouseup');
        $scope.editMode = state;
        $scope.updateCockpitApps();
        $scope.$broadcast('updateCockpitApps');
        if (!state) {
          UiAppsService.saveCurrentLayout(playmode);
          bngApi.activeObjectLua('requestCameraConfig()');
        }
      });

      $scope.updateCockpitApps = function() {
        UiAppsService.handleCameraChange(cameraMode, $scope.editMode);
      };

      $scope.$on('GameStateUpdate', function (event, data) {
        playmode = data.state;
        if (data.appLayout !== undefined) {
          // UiAppsService.loadLayout(data.appLayout, container, $scope); // uilayout can be either a layout name, or the actual layout json
          __temp_load_layout__(data.appLayout, container, $scope);
        } else if (playmode !== undefined) {
          __temp_load_layout__(playmode, container, $scope);

        } else {
          logger.debug(`Expected AppLayout but didn't get one :-( `, data);
        }
      });
    }]
  };
}])



/**
 * @ngdoc directive
 * @name beamng.apps.directive:bngApp
 * @require $document
 * @require $q
 * @require beamng.apps.service:AppLayout
 * @require beamng.stuff.service:bngApi
 *
 * @description This directive is used in order to define the app's overall behavior
 * such as moving and resizing. It is used as a wrapper element for each implemented
 * app in the game.
**/
.directive('bngApp', ['$document', '$q', 'logger', 'AppLayout', 'bngApi', 'UiAppsService', function ($document, $q, logger, AppLayout, bngApi, UiAppsService) {
  return {
    restrict: 'EA',
    templateUrl: '/ui/modules/apps/bng-app.html',
    transclude: true,
    replace: true,
    require: '^appContainer',
    scope: false,
    controller: function ($scope, $element, $attrs) {
      var ctrl = this;

      ctrl.getSettings = function () {
        var pathParts = $scope.entry.jsSource.split('/')
          , directory = pathParts[pathParts.length - 2]
          , d = $q.defer()
        ;

        bngApi.engineLua(`core_apps.getSettings("${directory}")`, function (data) {
          d.resolve(data);
        });

        return d.promise;
      };


      var initListener = $scope.$watch('entry', (entry) => {
        if (entry !== undefined) {
          $element.css(entry.css);
          initListener();
        }
      });

      ctrl.saveSettings = function (settings) {
        var pathParts = $scope.entry.jsSource.split('/')
          , directory = pathParts[pathParts.length - 2]
        ;

        bngApi.engineLua(`core_apps.saveSettings("${directory}", ${bngApi.serializeToLua(settings)})`);
      };


      var startX, startY, x, y, maxTop, maxLeft, maxWidth, maxHeight, alignment, ctx, initAspectRatio;

      $element.ready(function () {
        x = $element[0].offsetLeft;
        y = $element[0].offsetTop;
        ctx = document.getElementById('alignment-canvas').getContext('2d');
        UiAppsService.restrictInWindow($element[0]);
        $scope.entry = AppLayout.current[$attrs.appid];
        $scope.$broadcast('app:resized', {width: $element[0].offsetWidth, height: $element[0].offsetHeight});
        initAspectRatio = $element[0].offsetWidth / $element[0].offsetHeight;
      });

      $scope.$on('editApps', (_, mode) => {
        if (mode) $element[0].classList.add('editable');
        else      $element[0].classList.remove('editable');
      });

      $scope.$on('windowResize', function () {
        if ($scope.entry) {
          $element.css($scope.entry.css);
          UiAppsService.restrictInWindow($element[0]);
        }
      });

      $scope.translateStart = function (event) {
        event.stopPropagation();
        UiAppsService.resetPositionAttributes($element[0]);

        maxTop  = window.innerHeight - $element[0].offsetHeight;
        maxLeft = window.innerWidth - $element[0].offsetWidth;

        startX = event.pageX - $element[0].offsetLeft;//x;
        startY = event.pageY - $element[0].offsetTop;//y;

        $element[0].classList.add('active');
        $document.on('mousemove', translate);
        $document.on('mouseup', translateEnd);

        translate(event); // It is like moving without moving! just a cheap trick to show lines and such..
      };

      $scope.resizeStart = function (event) {
        event.stopPropagation();
        UiAppsService.resetPositionAttributes($element[0]);

        maxWidth = window.innerWidth - $element[0].offsetLeft;
        maxHeight = window.innerHeight - $element[0].offsetTop;

        startX = $element[0].offsetLeft;
        startY = $element[0].offsetTop;

        $element.addClass('active');
        $document.on('mousemove', resize);
        $document.on('mouseup', resizeEnd);
      };

      $scope.kill = function () {
        delete AppLayout.current[$attrs.appid];
        $scope.$destroy();
        $element.remove();
      };

      $element.on('$destroy', function () {
        $scope.$destroy();
      });


      function translate (event) {
        x = event.pageX - startX;
        y = event.pageY - startY;

        var top  = Math.ceil(y/5) * 5
          , left = Math.ceil(x/5) * 5
        ;

        top = Math.max(0, Math.min(top, maxTop));
        left = Math.max(0, Math.min(left, maxLeft));

        alignment = UiAppsService.alignInContainer($element[0], top, left);
        UiAppsService.drawAlignmentHelpers(ctx, $element[0], alignment);
      }

      function resize (event) {

        $scope.showDimensions = true;
        var width = Math.max(Math.ceil((event.pageX - startX) / 10) * 10, 50)
          , height = Math.max(Math.ceil((event.pageY - startY) / 10) * 10, 40)
        ;

        
        if ($scope.entry.preserveAspectRatio) {
          if (width > height) {
            height = width / initAspectRatio;
          } else {
            width = height * initAspectRatio;
          }
        }

        var sizeChanged = (width !== $element[0].offsetWidth || height !== $element[0].offsetHeight);

        $element[0].style.width  = Math.max(0, Math.min(width, maxWidth)) + 'px';
        $element[0].style.height = Math.max(0, Math.min(height, maxHeight)) + 'px';

        if (sizeChanged) {
          $scope.$evalAsync(function () {
            $scope.dimensions = { width: $element[0].offsetWidth, height: $element[0].offsetHeight };
            $scope.$broadcast('app:resized', $scope.dimensions);
          });
        }
      }


      function translateEnd (event) {
        ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);

        var cssObj = UiAppsService.getCssObj($element[0], alignment);
        $scope.entry.css = cssObj;
        $element.css(cssObj);

        $element[0].classList.remove('active');

        $document.off('mousemove', translate);
        $document.off('mouseup', translateEnd);
      }

      function resizeEnd (event) {
        var cssObj = UiAppsService.getCssObj($element[0], null);
        $scope.entry.css.width = cssObj.width;
        $scope.entry.css.height = cssObj.height;

        $element.removeClass('active');

        $scope.$evalAsync(() => { $scope.showDimensions = false; });
        $document.off('mousemove', resize);
        $document.off('mouseup', resizeEnd);
      }
    }
  };
}])























// TODO: Move these out of here!
.directive('graphLegendTip', function () {
  return {
    template: '<canvas height="10"></canvas>',
    replace: true,
    scope: {
      color: '@',
      type: '@',
      dashArray: '@?'
    },
    link: function (scope, element, attrs) {
      var context = '<graph-legend-tip>',
          ctx = element[0].getContext('2d');

      if (scope.dashArray) {
        scope.dashArray = JSON.parse(scope.dashArray);
        if (!Array.isArray(scope.dashArray)) {
          console.log(`${context}: dash-array must be an array!`);
          scope.dashArray = null;
        }
      }

      switch(scope.type) {
        case 'fill':
          ctx.canvas.width = ctx.canvas.height;
          ctx.fillStyle = scope.color;
          ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height);
          break;
        case 'line':
          ctx.canvas.width = ctx.canvas.height * 2.5;
          ctx.strokeStyle = scope.color;
          ctx.lineWidth = 2;
          ctx.setLineDash(scope.dashArray || []);
          ctx.beginPath();
          ctx.moveTo(0, ctx.canvas.height/2);
          ctx.lineTo(ctx.canvas.width, ctx.canvas.height/2);
          ctx.stroke();
          break;
        default:
          console.log(`{context}: Unknown tip type ${scope.type}`);
      }
    }
  }
})



/**
 * @ngdoc service
 * @name beamng.apps.service:CanvasShortcuts
 * @description Various helper functions for canvas operations used in some apps
**/
.factory('CanvasShortcuts', function () {
  return {
    filledArc: function (ctx, x, y, r, w, v, c) {
      if(v > 1) v = 1;
      else if(v < -1) v = -1;
      ctx.beginPath();
      var rads = v * 2 * Math.PI;
      var reverse = (v < 0);
      ctx.arc(x,y,r-(w/2)  , 1.5 * Math.PI, 1.5 * Math.PI + rads, reverse);
      ctx.lineWidth = w;
      ctx.strokeStyle = c;
      ctx.stroke();
      ctx.closePath();
    },
    circle: function (ctx, x, y, r, lineWidth, strokeStyle, fillStyle) {
      ctx.beginPath();
      ctx.arc(x,y,r-(lineWidth/2), 0, 2 * Math.PI, false);
      var prevFillStyle = ctx.fillStyle;
      if (fillStyle !== undefined) {
        ctx.fillStyle = fillStyle;
        ctx.fill();
      }
      ctx.lineWidth = lineWidth;
      ctx.strokeStyle = strokeStyle;
      ctx.stroke();
      ctx.closePath();
      if (fillStyle !== undefined) {
        ctx.fillStyle = prevFillStyle;
      }
    },

    subsample: function (outLength, inputArray) {

      var winLength = Math.floor(inputArray.length / outLength);
      var outArray = new Array(outLength);

      for (var i=0; i<outLength; i+=1) {
        var val = 0.0;
        for (var j=0; j<winLength; j+=1)
          val += inputArray[i*winLength + j];

        outArray[i] = val / winLength;
      }

      return outArray;
    },

    plotAxis: function (ctx, side, range, ticks, _margin, grid, txtColor) {
      var margin = angular.extend({top: 0, bottom: 0, left: 0, right: 0}, _margin)
        , width  = ctx.canvas.clientWidth
        , height = ctx.canvas.clientHeight
      ;

      ctx.save();
      ctx.beginPath();
      ctx.strokeStyle = 'black';
      ctx.lineWidth = 1;

      switch (side) {
        case 'left':
          ctx.moveTo(margin.left, margin.top);
          ctx.lineTo(margin.left, height - margin.bottom);
          ctx.stroke();

          if (range.length > 0)
            var yFactor = (range[1] - range[0]) / (height - margin.top - margin.bottom);
          // Draw ticks
          if (ticks.length > 0) {
            ctx.textAlign = 'end';
            ctx.textBaseline = 'middle';
            ctx.fillStyle = txtColor || 'black';

            ticks.map(function (t) {
              var y = height - margin.bottom - ((t - range[0]) / yFactor);
              ctx.fillText(t, margin.left - 3, y);
            });
          }

          if (grid) {
            var gridParams = angular.extend({color: 'black', width: 1}, grid);
            ctx.setLineDash(gridParams.dashArray || []);

            if (gridParams.values) { // Gridlines at specified values
              if (!range)
                logger.error('left axis: Grid values without range');

              gridParams.values.map(function (v) {
                var y = height - margin.bottom - (v / yFactor);
                ctx.beginPath();
                ctx.strokeStyle = gridParams.color;
                ctx.lineWidth = gridParams.width;
                ctx.moveTo(width - margin.right, y);
                ctx.lineTo(margin.left, y);
                ctx.stroke();
              });

            } else if (gridParams.numLines) {
              var gmin = (!range || !gridParams.min) ? (height - margin.bottom) : (height - margin.bottom - (gridParams.min || range[0]) / yFactor)
                , gmax = (!range || !gridParams.max) ? margin.top : (height - margin.bottom - (gridParams.max || range[1]) / yFactor)
                , tickSpacing = (gmax - gmin) / (grid.numLines - 1)
              ;

              for (var i=0; i<gridParams.numLines; i++) {
                var y = gmin + i*tickSpacing;
                ctx.beginPath();
                ctx.strokeStyle = gridParams.color;
                ctx.lineWidth = gridParams.width;
                ctx.moveTo(margin.left, y);
                ctx.lineTo(width - margin.right, y);
                ctx.stroke();
              }
            } else {
              logger.warn('left axis: Must provide values or number of lines for grid');
            }
          }

          break;

        case 'right':
          ctx.moveTo(width - margin.right, margin.top);
          ctx.lineTo(width - margin.right , height - margin.bottom);
          ctx.stroke();

          if (range.length > 0)
            var yFactor = (range[1] - range[0]) / (height - margin.top - margin.bottom);

          // Draw ticks
          if (ticks.length > 0) {
            ctx.textAlign = 'start';
            ctx.textBaseline = 'middle';
            ctx.fillStyle = txtColor || 'black';

            ticks.map(function (t) {
              var y = height - margin.bottom - ((t-range[0]) / yFactor);
              ctx.fillText(t, width - margin.right + 3, y);
            });
          }

          // Draw gridlines
          if (grid) {
            var gridParams = angular.extend({color: 'black', width: 1}, grid);
            ctx.setLineDash(gridParams.dashArray || []);

            if (gridParams.values) { // Gridlines at specified values
              if (!range)
                logger.error('right axis: Grid values without range');

              gridParams.values.map(function (v) {
                var y = height - margin.bottom - (v / yFactor);
                ctx.beginPath();
                ctx.strokeStyle = gridParams.color;
                ctx.lineWidth = gridParams.width;
                ctx.moveTo(width - margin.right, y);
                ctx.lineTo(margin.left, y);
                ctx.stroke();
              });

            } else if (gridParams.numLines) {
              var gmin = (!range || !gridParams.min) ? (height - margin.bottom) : (height - margin.bottom - (gridParams.min || range[0]) / yFactor)
                , gmax = (!range || !gridParams.max) ? margin.top : (height - margin.bottom - (gridParams.max || range[1]) / yFactor)
                , tickSpacing = (gmax - gmin) / (grid.numLines - 1)
              ;

              for (var i=0; i<gridParams.numLines; i++) {
                var y = gmin + i*tickSpacing;
                ctx.beginPath();
                ctx.strokeStyle = gridParams.color;
                ctx.lineWidth = gridParams.width;
                ctx.moveTo(width - margin.right, y);
                ctx.lineTo(margin.left, y);
                ctx.stroke();
              }
            } else {
              logger.warn('right axis: Must provide values or number of lines for grid');
            }
          }
          break;

        case 'top':
          ctx.moveTo(margin.left, margin.top);
          ctx.lineTo(width - margin.right, margin.top);
          ctx.stroke();

          if (range.length > 0)
            var xFactor = (range[1] - range[0]) / (width - margin.left - margin.right);

          // Draw ticks
          if (ticks.length > 0) {
            ctx.textAlign = 'center';
            ctx.textBaseline = 'bottom';
            ctx.fillStyle = txtColor || 'black';

            ticks.map(function (t) {
              var x = margin.left + (t / xFactor);
              ctx.fillText(t, x, margin.top - 3);
            });
          }

          // Draw gridlines
          if (grid) {
            var gridParams = angular.extend({color: 'black', width: 1}, grid);
            ctx.setLineDash(gridParams.dashArray || []);

            if (gridParams.values) { // Gridlines at specified values
              if (!range)
                logger.error('top axis: Grid values without range');

              gridParams.values.map(function (v) {
                var x = margin.left + (v / xFactor);
                ctx.beginPath();
                ctx.strokeStyle = gridParams.color;
                ctx.lineWidth = gridParams.width;
                ctx.moveTo(x, margin.top);
                ctx.lineTo(x, height - margin.bottom);
                ctx.stroke();
              });

            } else if (gridParams.numLines) {
              var gmin = (!range || !gridParams.min) ? margin.left            : (margin.left + (gridParams.min || range[0]) / xFactor)
                , gmax = (!range || !gridParams.max) ? (width - margin.right) : (margin.left + (gridParams.max || range[1]) / xFactor)
                , tickSpacing = (gmax - gmin) / (grid.numLines - 1)
              ;

              for (var i=0; i<gridParams.numLines; i++) {
                var x = gmin + i*tickSpacing;
                ctx.beginPath();
                ctx.strokeStyle = gridParams.color;
                ctx.lineWidth = gridParams.width;
                ctx.moveTo(x, margin.top);
                ctx.lineTo(x, height - margin.bottom);
                ctx.stroke();
              }
            } else {
              logger.warn('top axis: Must provide values or number of lines for grid');
            }
          }

          break;

        case 'bottom':
          // Draw axis
          ctx.moveTo(margin.left, height - margin.bottom);
          ctx.lineTo(width - margin.right, height - margin.bottom);
          ctx.stroke();

          if (range.length > 0)
            var xFactor = (range[1] - range[0]) / (width - margin.left - margin.right);

          // Draw ticks
          if (ticks.length > 0) {
            ctx.textAlign = 'center';
            ctx.textBaseline = 'top';
            ctx.fillStyle = txtColor || 'black';

            ticks.map(function (t) {
              var x = margin.left + (t / xFactor);
              ctx.fillText(t, x, height - margin.bottom + 3);
            });
          }

          // Draw gridlines
          if (grid) {
            var gridParams = angular.extend({color: 'black', width: 1}, grid);
            ctx.setLineDash(gridParams.dashArray || []);

            if (gridParams.values) { // Gridlines at specified values
              if (!range)
                logger.error('bottom axis: Grid values without range');

              gridParams.values.map(function (v) {
                var x = margin.left + (v / xFactor);
                ctx.beginPath();
                ctx.strokeStyle = gridParams.color;
                ctx.lineWidth = gridParams.width;
                ctx.moveTo(x, height - margin.bottom);
                ctx.lineTo(x, margin.top);
                ctx.stroke();
              });

            } else if (gridParams.numLines) {
              var gmin = (!range || !gridParams.min) ? margin.left            : (margin.left + (gridParams.min || range[0]) / xFactor)
                , gmax = (!range || !gridParams.max) ? (width - margin.right) : (margin.left + (gridParams.max || range[1]) / xFactor)
                , tickSpacing = (gmax - gmin) / (grid.numLines - 1)
              ;

              for (var i=0; i<gridParams.numLines; i++) {
                var x = gmin + i*tickSpacing;
                ctx.beginPath();
                ctx.strokeStyle = gridParams.color;
                ctx.lineWidth = gridParams.width;
                ctx.moveTo(x, height - margin.bottom);
                ctx.lineTo(x, margin.top);
                ctx.stroke();
              }
            } else {
              logger.warn('bottom axis: Must provide values or number of lines for grid');
            }
          }

          break;

        default:
          log.warn(`Unknown side ${side}`);
      }

      ctx.restore();
    },

    plotData: function (ctx, data, miny, maxy, inputParams) {
      var defaultParams = {
        margin: {
          top: 15, bottom: 15, left: 25, right: 25
        },
        lineWidth: 2,
        lineColor: 'black',
        minIndex: 0,
        maxIndex: data.length - 1,
        lineType: null
      };

      var params = angular.extend({}, defaultParams, inputParams);
      var
         width = ctx.canvas.clientWidth - params.margin.left - params.margin.right
        , height = ctx.canvas.clientHeight
        , yFactor = (height - params.margin.bottom - params.margin.top) / (maxy - miny)
        , dx = width / (data.length - 1)
        // , nDraw = width / dx
      ;

      ctx.save();
      ctx.beginPath();
      ctx.lineWidth = params.lineWidth;
      ctx.strokeStyle = params.lineColor;

      if (params.dashArray) {
        // user-defined dash array
        ctx.setLineDash(params.dashArray);
      } else {
        // or one of the presets (solid line as default)
        switch (params.lineType) {
          case 'dashed':
            ctx.setLineDash([4*params.lineWidth, 3*params.lineWidth]);
            break;
          case 'dotted':
            ctx.setLineDash([params.lineWidth, 2*params.lineWidth]);
            break;
          default:
            // console.log('back to default:', params.lineType);
            ctx.setLineDash([]);
        }
      }


      ctx.moveTo(params.margin.left + params.minIndex * dx, height - params.margin.bottom - data[params.minIndex]*yFactor);

      for (var i=params.minIndex + 1; i<=params.maxIndex; i++)
        ctx.lineTo(params.margin.left + i*dx, height - data[i]*yFactor - params.margin.bottom);

      ctx.stroke();
      ctx.restore();

    }


  };
})

;
