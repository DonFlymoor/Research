angular.module('beamng.stuff')


.controller('MapViewCtrl', ['$rootScope', '$scope', '$stateParams', 'bngApi', 'gamepadNav', function ($rootScope, $scope, $stateParams, bngApi, gamepadNav) {
  // $stateParams.data.points = [

    //   {
    //     "x": 0.55604117202759,
    //     "y": 0.17097964477539,
    //     "desc": "campaigns.utah.chapter_1.cliffjump.title",
    //     "title": "campaigns.utah.chapter_1.cliffjump.title",
    //     "state": "ready",
    //     "onClick": "campaign_exploration.onFocusPOI(\"cliffjump\")",
    //     "objectives": {
    //       "bla1": true,
    //       "bla2": false,
    //       "bla3": false
    //     },
    //     "type": "delivery"
    //   },
    // {
    //   "x": -0.020046508789063,
    //   "y": 0.99413854980469,
    //   "desc": "campaigns.training.training.training_acceleration_braking.description",
    //   "title": "campaigns.training.training.training_acceleration_braking.title",
    //   "state": "ready",
    //   "onClick": "campaign_exploration.onFocusPOI(\"driver_training_1\")",
    //   "objectives": {
    //     "bla1": true,
    //     "bla2": false,
    //     "bla3": false
    //   },
    //   "type": "training"
    // },
    // {
    //   "x": 0.26620196533203,
    //   "y": 0.95482748413086,
    //   "desc": "campaigns.utah.chapter_1.highway.title",
    //   "title": "campaigns.utah.chapter_1.highway.title",
    //   "state": "failed",
    //   "onClick": "campaign_exploration.onFocusPOI(\"highway\")",
    //   "objectives": {
    //     "bla1": true,
    //     "bla2": false,
    //     "bla3": false
    //   },
    //   "type": "race"
    // },
    // {
    //   "x": 0.420046508789063,
    //   "y": 0.83413854980469,
    //   "desc": "campaigns.training.training.training_acceleration_braking.description",
    //   "title": "campaigns.training.training.training_acceleration_braking.title",
    //   "state": "bronze",
    //   "onClick": "campaign_exploration.onFocusPOI(\"training\")",
    //   "objectives": {
    //     "bla1": true,
    //     "bla2": false,
    //     "bla3": false
    //   },
    //   "type": "training"
    // },
    // {
    //   "x": 0.20046508789063,
    //   "y": 0.513854980469,
    //   "desc": "campaigns.training.training.training_acceleration_braking.description",
    //   "onClick": "campaign_exploration.onFocusPOI(\"training\")",
    //   "type": "site",
    //   "subtype": "vendor"
    // }
  // ]


  $rootScope.$broadcast('ToggleMissionPopups', false);  // TODO: not that classy... must be handled at top-level along with other global state stuff

  bngApi.engineLua('UI.unlockFPS();');
  bngApi.engineLua("bindings.menuActive(true)");

  var prevCross = gamepadNav.crossfireEnabled()
    , prevGame = gamepadNav.gamepadNavEnabled()
    , prevSpatial = gamepadNav.gamepadNavEnabled()
  ;

  gamepadNav.enableCrossfire(false);
  gamepadNav.enableGamepadNav(false);
  gamepadNav.enableSpatialNav(true);

  $scope.$on('$destroy', () => {
    gamepadNav.enableCrossfire(prevCross);
    gamepadNav.enableGamepadNav(prevGame);
    gamepadNav.enableSpatialNav(prevSpatial);

    bngApi.engineLua("bindings.menuActive(false)");
    bngApi.engineLua('UI.limitFPSDefault();');

    $rootScope.$broadcast('ToggleMissionPopups', true);
  });

  var vm = this;
  $scope.colors = {
    failed: 'red',
    skipped: 'red',
    ready: 'green',
    bronze: '#cd7f32',
    silver: '#c0c0c0',
    gold: '#d4af37',
    found: 'grey',
    notFound: 'white'
  }


  $scope.filter = {
    state: {
      ready: {color: $scope.colors.ready, enabled: true},
      failed: {color: $scope.colors.failed, enabled: true},
      skipped: {color: $scope.colors.skipped, enabled: true},
      bronze: {color: $scope.colors.bronze, enabled: true},
      silver: {color: $scope.colors.silver, enabled: true},
      gold: {color: $scope.colors.gold, enabled: true}
    },
    type: {},
    subtype: {}
  };


  $scope.applyFilter = function () {
    $scope.$evalAsync(() => {
      vm.data.points = originalData.points.filter(e => e.type === 'site' ? ($scope.filter.subtype[e.subtype] || {}).enabled : ($scope.filter.type[e.type] || {}).enabled && ($scope.filter.state[e.state] || {}).enabled);
      // console.log(vm.data.points);
      vm.data.logPoints = vm.data.points.concat(originalData.logPoints);
    });
  };

  var iconmap = {
    'tiemTrial': 'time_trial',
    'vendor': 'car_dealer',
    'transitionPoint': 'transition_point',
    'playerHQ': 'headquarter',
  }

  var prefixmap = {
    'poi': ['playerHQ', 'transitionPoint', 'vendor'],
    'mission': ["chase", "crash", "delivery", "fun", "race", "stunt", "time_trial"]
  }

  function getIconForPoi (name) {
    var prefix = '';
    for (var key in prefixmap) {
      if (prefixmap[key].indexOf(name) !== -1) {
        prefix = key;
      }
    }
    return `#map_${prefix}_${iconmap[name] || name}`;
  }


  for (var point in $stateParams.data.points) {
    var short = $stateParams.data.points[point];

    var where = short.type !== 'site' ? 'type' : 'subtype';
    if ($scope.filter[where][short[where]] === undefined) {
      $scope.filter[where][short[where]] = {color: 'white', icon: getIconForPoi(short[where]), enabled: true};
    }
    short.size = 20;

    switch(short.type) {
      case 'site':
        short.icon = getIconForPoi(short.subtype);
        break;
      default:
        short.icon = getIconForPoi(short.type);
    }

    short.iconColor = $scope.colors[short.state] || 'white';
  }

  // console.log('my params:', $stateParams);
  // console.log($scope.filter);
  vm.data = $stateParams.data;
  var originalData = angular.copy($stateParams.data);
  vm.data.logPoints = vm.data.points.concat(Array.isArray(vm.data.logPoints) ? vm.data.logPoints : []);

  vm.selectedMission = {
    title: '',
    type: '',
    description: ''
  };

  $scope.select = function (mission) {
    // IMPORTANT this only works due to the mission being an object reference
    // be carefull
    if (vm.data.points.indexOf(mission) !== -1) {
      $scope.$broadcast('poi:focus', mission);
    }
  };

  $scope.$on('mapview:missionFocus', (_, mission) => {
    vm.selectedMission = mission;
    $scope.$evalAsync();
  });


  $scope.hasEntries = (obj) => Object.keys(obj).length > 0;


}])

.directive('missionStatus', [function () {
  return {
    scope: {
      title: '=',
      cash: '='
    },
    template: `
      <div class="mission-status">
        <div class="title">{{ title }}</div>
        <div class="status">
          <svg style="fill: #EAEAEA; height: 50px; width: 50px"><use xlink:href="#avatar"></svg>
          <div style="text-align: right; flex-grow: 1">{{ cash }}</div>
        </div>
      </div>
    `
  };
}])

.directive('missionDetails', [function () {
  return {
    scope: {
      mission: '='
    },
    template: `
      <div class="mission-details">
        <div class="header">
          <div class="title">{{ mission.title | translate }}</div>
          <span class="subtitle">{{ mission.type | translate }}</span>
        </div>

        <div class="body">{{ mission.description | translate }}</div>
        <div class="requirements"></div>
        <div class="awards"></div>
      </div>
    `,
    link: function (scope, element, attrs) {}
  };
}])

.directive('missionLog', [function () {
  return {
    template: `
      <md-tabs class="mission-log" md-dynamic-height>
        <md-tab label="{{item.name}} ({{item.list.length}})" ng-repeat="item in cat track by $index">
          <div class="body">
            <details ng-repeat="mission in item.list track by $index" ng-mouseover="selectPoint({point: mission})">
              <summary>
                <svg ng-if="mission.iconColor" style="background-color: {{ mission.iconColor}}; height: 20px; width: 20px; border-radius: 50%; vertical-align: middle;"><use xlink:href="{{ mission.icon}}" style="fill: black;"/></svg>
                {{ mission.title | translate }}
              </summary>
              <p ng-if="mission.objectives.length > 0">
                <div ng-repeat="(key, val) in mission.objectives track by $index">
                  <input type="checkbox" read-only ng-checked="val" disabled>
                  <label>{{key}}</label>
                </div>
              </p>
              <p ng-if="mission.desc !== undefined" bng-translate="{{mission.desc}}"></p>
            </details>
          </div>
        </md-tab>
      </md-tabs>
    `,
    scope: {
      points: '=',
      selectPoint: '&'
    },
    link: function (scope, elem, attr) {
      function categorize () {
        if (scope.points !== undefined) {
          scope.cat = [
            {list: scope.points.filter(e => ['ready', 'bronze', 'silver'].indexOf(e.state) !== -1 && e.type !== 'site'), name: "Open"},
            {list: scope.points.filter(e => ['failed', 'skipped'].indexOf(e.state) !== -1), name: "Failed"},
            {list: scope.points.filter(e => ['gold'].indexOf(e.state) !== -1), name: "Closed"},
            {list: scope.points.filter(e => e.type === 'photoSafari' && e.state === 'notFound'), name: "Photo Safari"}
          ]
        }
      }
      scope.$watch('points', categorize);
    }
  };
}])


.directive('missionsMap', ['$compile', 'bngApi', function ($compile, bngApi) {
  return {
    template: `
      <div class="missions-map container" bng-nav-root>
        <svg id="target-halo" width="70" height="70" style="position: absolute; display:none">
          <circle cx="35" cy="35" r="30">
        </svg>

        <svg id="target-cross"><use xlink:href="#target"/></svg>
        <img src="{{ baseImg }}" />
      </div>
    `,
    scope: {
      baseImg: '<',
      poi: '<',
      player: '<',
      mission: '<'
    },
    replace: true,

    link: function (scope, element, attrs) {

      var imageBase = element[0].querySelector('img')
        // , targetCross = angular.element(element[0].querySelector('#target-cross'))
        , targetHalo = element[0].querySelector('#target-halo')
        , poiElements = []
        , poiSize = 30
        , offset = {x: 0, y: 0}
        , scale = {x: 1, y: 1}
        , selectedPOICoords = null
      ;

      var calculateBounds = () => {
        offset = {x: imageBase.offsetLeft, y: imageBase.offsetTop};
        scale  = {x: imageBase.offsetWidth, y: imageBase.clientHeight};
      };

      var poiCss = (poiConfig) => ({
        position: 'absolute',
        width:  `${poiSize}px`,
        height: `${poiSize}px`,
        left:  `${offset.x + poiConfig.x*scale.x - poiSize/2}px`,
        top: `${offset.y + poiConfig.y*scale.y - poiSize/2}px`,
        transform: `rotate(${poiConfig.heading || 0}deg)`
      });

      var addPOI = (poiData,  hasFocus, isSelected) => {
        var poiScope   = scope.$new(true);
        poiScope.title = poiData.title;
        poiScope.type  = poiData.type;
        poiScope.description = poiData.desc;
        poiScope.action = poiData.onClick ? () => { bngApi.engineLua(`${poiData.onClick}`); } : () => {};
        poiScope.state = poiData.state;
        poiScope.site = poiData.site;
        poiScope.icon = poiData.icon;
        poiScope.iconColor = poiData.iconColor;
        poiScope.x = poiData.x;
        poiScope.y = poiData.y;

        var poiEl = angular.element('<map-poi class="{{ ::state }}" ng-click="action()"></map-poi>');

        if (hasFocus)
          poiEl.attr('bng-nav-default-focus', true);


        // console.log(poiData, hasFocus, isSelected);

        if (isSelected) {
          selectedPOICoords = { x: poiData.x, y: poiData.y };
          targetHalo.style.display = 'inherit';
          targetHalo.style.top = `${offset.y + poiData.y*scale.y - 35}px`;
          targetHalo.style.left = `${offset.x + poiData.x*scale.x - 35}px`;
        }

        poiEl.css( poiCss(poiData) );
        element.append(poiEl);
        poiElements.push({el: poiEl, config: {x: poiData.x, y: poiData.y}, scope: poiScope});


        $compile(poiEl)(poiScope);
      };

      var addPlayer = (playerData) => {
        // var ss = scope.$new(true);
        var playerEl = angular.element('<svg class="arrow"><use xlink:href="#map_vehicle_marker"/></svg>');
        playerEl.css(poiCss(playerData));

        element.append(playerEl);
        poiElements.push({el: playerEl, config: {x: playerData.x, y: playerData.y, heading: playerData.heading}});
        $compile(playerEl)(scope);
      };

      var updatePositions = () => {
        calculateBounds();

        poiElements.forEach(poi => {
          poi.el.css( poiCss(poi.config) );
        });

        if (selectedPOICoords !== null) {
          targetHalo.style.top = `${offset.y + selectedPOICoords.y*scale.y - 35}px`;
          targetHalo.style.left = `${offset.x + selectedPOICoords.x*scale.x - 35}px`;
        }
      };

      function initHelper () {
        var missionIndex = scope.mission;

        if (!Number.isFinite(missionIndex) || missionIndex < 0) {
          var minDistance = Infinity;
          missionIndex = scope.poi.reduce((minIndex, p, i) => {
            var d = Math.sqrt(Math.pow(p.x - scope.player.x, 2) + Math.pow(p.y - scope.player.y, 2));
            if (d < minDistance) {
              minDistance = d;
              return i;
            }
            return minIndex;
          }, -1);
        }


        calculateBounds();

        scope.poi.forEach((point, i) => {
          addPOI(point, i==missionIndex, i==scope.mission);
        });

        addPlayer(scope.player);
      }

      var initialize = function () {
        bngApi.engineLua("Engine.Audio.playOnce('AudioGui', 'event:>UI>Minimap On')");

        targetHalo.style.display = 'none';
        selectedPOICoords = null
        initHelper();
      };

      angular.element(imageBase).on('load', initialize);
      scope.$on('windowResize', updatePositions);

      scope.$watch(() => scope.poi, () => {
        if (poiElements.length > 0) {
          poiElements.forEach(e => {
            if (e.scope) {
              e.scope.$destroy();
            }
            e.el.remove();
          });
          initialize();
        }
      });

      scope.$on('poi:focused', (_, el) => {
        var targetSize = 1.5*poiSize;

        // targetCross.css({
        //   // display: 'initial',
        //   width:  `${targetSize}px`,
        //   height: `${targetSize}px`,
        //   left: `${el.offsetLeft + el.offsetWidth/2 - targetSize/2}px`,
        //   top:  `${el.offsetTop + el.offsetHeight/2 - targetSize/2}px`
        // });
      });

      // scope.$on('poi:blur', () => {
      //   targetCross[0].style.display = 'none';
      // });
    }
  }
}])


.directive('mapPoi', ['bngApi', function (bngApi) {
  return {
    scope: false,
    template: '<svg class="map-poi" bng-nav-item><use xlink:href="" style="fill: black;"/></svg>',
    replace: true,
    link: function (scope, element, attrs) {
      var missionData = {
        title: scope.title,
        type: scope.type,
        description: scope.description
      };

      element.on('focus', () => {
        scope.$emit('poi:focused', element[0]);
        scope.$emit('mapview:missionFocus', missionData);
        bngApi.engineLua("Engine.Audio.playOnce('AudioGui', 'event:>UI>Minimap Mouse Over')");
      });

      scope.$on('poi:focus', (_, d) => {
        if (d.x === scope.x && d.y ===  scope.y) {
          // console.debug('asdfljas;dfljk');
          element[0].focus();
        }
      });

      element.on('blur', () => {
        scope.$emit('poi:blur');
      });

      var useNode = element[0].querySelector('use');
      var svgNode = element[0];
      useNode.setAttribute('xlink:href', scope.icon);
      svgNode.style['background-color'] = scope.iconColor;
    }
  };
}])

