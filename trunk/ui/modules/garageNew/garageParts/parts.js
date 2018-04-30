angular.module('beamng.garage')

.directive('gpBreadCrumb', [function () {
  return {
    template: `
      <div layout="column">
        <div class="color2">{{location.name}}</div>
        <div layout="row">
          <div ng-repeat="behind in before track by $index" layout="row" layout-align="center center">
            <div class="breadCrumbPoint clickable" ng-click="click(before.length - $index)" ng-class="{filled: backHover === $index, color3: backHover === $index}" style="position: relative;">
              <div ng-mouseover="setHover($index)" ng-mouseenter="setHover($index)" ng-mouseleave="setHover()" style="z-index: 10; position: absolute; top: -20px; right: -20px; bottom: -20px; left: -20px;"></div>
            </div>
            <div class="breadCrumpConnector"></div>
          </div>
          
          <div class="breadCrumbPoint" ng-class="{filled: backHover === undefined}"></div>

          <!--<div ng-repeat="behind in after track by $index" layout="row" layout-align="center center">
            <div class="breadCrumpConnector"></div>
            <div class="breadCrumbPoint"></div>
          </div> -->
        </div>
      </div>
    `,
    scope: {
      location: '=',
      back: '&'
    },
    link: function (scope) {
      scope.backHover;
      scope.setHover = function (id) {
        scope.backHover = id;
      };

      scope.click = function (id) {
        scope.backHover = undefined;
        scope.back()(id);
      };

      scope.$watch('location', (location) => {
        if (location) {
          scope.before = [].constructor(location.behind);
          scope.after = [].constructor(location.ahead);
          // console.log(location, scope.before.length, scope.before);
        }
      });
    }
  };
}])

// important: this is a directive, but it really is only meant to be used in the part selector of the new garage!
// the only purpose here is to encapsulate, not to abstract!
.directive('gpTextList', ['SpatialNavigation', function (SpatialNavigation) {
  return {
    restrict: 'E',
    template: `
      <div class="filler">
        <gp-arrow ng-if="leftPossible()" ng-click="left()" style="cursor: pointer; background-color: rgba(0, 0, 0, 0.001); position: absolute; top: 0; bottom: 0; right: calc(100% + 15px); width: 50px;" direction="left" ng-click="left()"></gp-arrow>
        <gp-arrow ng-if="rightPossible()" ng-click="right()" style="cursor: pointer; background-color: rgba(0, 0, 0, 0.001); position: absolute; top: 0; bottom: 0; left: calc(100% + 15px); width: 50px;" direction="right" ng-click="right()"></gp-arrow>
        <div style="position: absolute; top: 0; bottom: 0; left: calc(100% + 60px); font-size: 1.3em;" class="font1 color3" layout="row" layout-align="start center">
          <{{view.active + 1}}/{{view.data.length}}>
        </div>

        <div class="filler" layout="row" ng-style="{opacity: active ? 1 : 1}">
          <div ng-repeat="slot in list track by $index" ng-mouseover="activate($index)" ng-click="helper(getRealIndex($index))" item-nav-actions="{confirm: {name:'Enter', navigation: false}}" ng-style="{'background-color': view.active === getRealIndex($index) ? 'rgba(255, 103, 0, 0.7)' : 'rgba(0, 0, 0, 0.4)', cursor: slot.parts ? 'pointer' : 'default'}" style="margin: 10px;" bng-blur>
            <div style="height: 50px; width: 180px; position: relative;" layout="row" layout-align="center center">
              <div ng-if="slot.parts" class="color3 indicator" style="display: flex;"></div>
              <div class="truncate font1" style="max-width: 90%;">{{slot.description}}</div>
              <div class="color1" layout="row" layout-align="center center" style="padding: 0 15px; font-size: 12pt; position: absolute; top: 100%; left: 0; right: 0;" ng-if="view.active === getRealIndex($index) && slot.parts">
                <span style="margin-right: 5px;">{{slot.parts.length}}</span> 
                <span ng-if="slot.parts.length !== 1">{{'ui.garage.parts.subparts' | translate}}</span>
                <span ng-if="slot.parts.length === 1">{{'ui.garage.parts.subpart' | translate}}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
      `,
    scope: {
      view: '=',
      enter: '&?',
      selectPart: '&?',
      active: '='
    },
    require: '?^bngNavItem',
    link: function (scope, elem, attrs, navCtrl) {
      scope.helper = function (key) {
        scope.enter()(key);
      };
      
      var fits = 10;
      var start = 0;

      scope.$watch(
        'view.data',
        () => {
          if (scope.view) {
            calcFits();

            if (scope.view.active === undefined) {
              scope.view.active = 0;
            }

            updateShownList();
          } else {
            scope.list = [];
          }
        }
      )

      function calcFits () {
        fits = Math.floor(elem[0].parentNode.parentNode.offsetWidth / 200);
        // console.log(elem[0].parentNode.parentNode.offsetWidth, fits);
      }

      function updateShownList (forwards) {
        start = scope.view.active;
        var end = start + fits;
        if (forwards) {
          start -= fits - 1;
          end -= fits - 1;
        }

        if (end > scope.view.data.length) {
          start = scope.view.data.length - fits;
          end = scope.view.data.length;
        } 
        if (start < 0) {
          start = 0;
          end = fits;
        }

        scope.list = scope.view.data.slice(start, end);
      }

      scope.getRealIndex = (id) => id + start;

      scope.leftPossible = () => start > 0;
      scope.rightPossible = () => scope.view && start + fits < scope.view.data.length;

      function selectActive () {
        if (scope.selectPart) {
          scope.selectPart()(scope.view.data[scope.view.active].slotName, true);
        }
      }

      scope.activate = (id) => {
        scope.$evalAsync(() => {
          scope.view.active = start + id;
          selectActive();
        });
      };

      scope.left = () => {
        if (scope.view && scope.view.active > 0) {
          scope.$evalAsync(() => {
            scope.view.active -= 1;
            selectActive();
            if (scope.view.active < start) {
              updateShownList();
            }
          });
        }
      };


      scope.right = () => {
        if (scope.view && scope.view.active < scope.view.data.length - 1) {
          scope.$evalAsync(() => {
            scope.view.active += 1;
            selectActive();
            if (scope.view.active >= start + fits) {
              updateShownList(true);
            }
          });
        }
      };

      if (navCtrl) {
        navCtrl.actions.left = {cmd: scope.left, hide: true};;
        navCtrl.actions.right = {cmd: scope.right, hide: true};;
        navCtrl.actions.up = {cmd: () => {}, hide: true};
        navCtrl.actions.down = {cmd: () => {console.log('surpress down')}, hide: true};
        navCtrl.actions.confirm = () => {
          // mock different roots for entering and exiting
          var short = scope.view.data[scope.view.active];
          if (short.parts) {
            scope.helper(scope.view.active);
          } else {
            delete navCtrl.actions.down;
            SpatialNavigation.triggerAction('down');
            navCtrl.actions.down = {cmd: () => {console.log('surpress down')}, hide: true};
          }
        };
      }
    }
  };
}])

.directive('gpPartsSpecialty', ['SpatialNavigation', function (SpatialNavigation) {
  return {
    require: 'bngNavItem',
    link: function (scope, elem, attrs, navCtrl) {
      var allowUp = scope.$eval(attrs.allowUp);
      navCtrl.actions.left = {cmd: () => console.log('surpress left'), hide: true};
      navCtrl.actions.right = {cmd: () => console.log('surpress right'), hide: true};

      navCtrl.actions.back = {cmd: () => {
        delete navCtrl.actions.right;
        SpatialNavigation.triggerAction('right');
        navCtrl.actions.right = {cmd: () => console.log('surpress right'), hide: true};
      }};

      if (!allowUp) {
        navCtrl.actions.up = {cmd: () => console.log('surpress up'), hide: true};
      }
    }
  }
}])

.controller('garageParts', ['$scope', 'logger', 'bngApi', '$state', 'Utils', 'SpatialNavigation', function ($scope, logger, bngApi, $state, Utils, SpatialNavigation) {
  var vm = this;
  var pcData;

  vm.selectPart = function (element, subparts) {
    logger.debug(`Selecting part ${pcData[element]} (subparts: ${!!subparts})`);
    if (pcData[element]) {
      // try element name if is not avialable rather than do nothing, so lua can at least reset the highlightiung
      bngApi.activeObjectLua(`partmgmt.selectPart("${pcData[element] !== 'none' ? pcData[element] : element}", ${!!subparts})`);
    }
  };

  vm.deselectPart = function () {
    // logger.vehicleconfig.debug(`Reset part selection`);
    bngApi.activeObjectLua('partmgmt.selectReset()');
  };

  function sortingFunction (field, a, b) {
    if (a.sortingPrio !== undefined) {
      return -1;
    }

    if (b.sortingPrio !== undefined) {
      return 1;
    }

    return a[field].localeCompare(b[field]);
  } 

  function processData (parts) {
    var res = {parts: [], onOff: []};

    for (var partName in parts) {
      // console.log(partName, parts[partName].options.length);

      if (parts[partName].options.length === 1 && parts[partName].options[0].parts === undefined) { // not sure if checking for parts is a good criteria here, but makes life easier for the moment
        if (!parts[partName].coreSlot) {
          var help = parts[partName].options[0];
          help.description = parts[partName].description;
          help.slotName = partName;
          res.onOff.push(help);
        // delete parts[partName];
        }
      } else if (parts[partName].options.length > 0) {
        var help = {
          slotName: partName,
          coreSlot: parts[partName].coreSlot,
          description: parts[partName].description,
          options: parts[partName].options.sort(sortingFunction.bind(undefined, 'name')),
          sortingPrio: parts[partName].sortingPrio
        };

        delete parts[partName].sortingPrio;

        for (var i = 0; i < parts[partName].options.length; i += 1) {
          var short = parts[partName].options[i];

          if (short.parts && short.active) { // active is important here, so that parts from non active slots aren't passed to their parent
            // put the parent in the parts as well, so that the options are a level deeper
            var partsPointer = short.parts;
            delete short.parts;
            parts[partName].sortingPrio = true;
            partsPointer[partName] = parts[partName];

            var recRes = processData(partsPointer);
            // todo: what should happen if the slot only has one part after all on off are removed?
            res.onOff = res.onOff.concat(recRes.onOff);
            help.parts = recRes.parts;

            delete help.options;
          }
          delete short.parts;
        }

        if (help.options || help.parts.length > 0) {
          res.parts.push(help);
        }
      }
    }

    res.parts.sort(sortingFunction.bind(undefined, 'description'));
    return res;
  } 

  function fixUpLuaData (config, parts) {
    var res = {}
      , parts = parts || config.slotMap;

    for (var partName in parts) {
      var part = {
        description: config.slotDescriptions[partName],
        options: []
      };
      for (var i = 0; i < parts[partName].length; i += 1) {
        var short = parts[partName][i];
        
        // if the coreSlot property is set by one of the options keep it
        part.coreSlot = part.coreSlot || !!short.coreSlot;

        delete short.coreSlot; // wrong location, sould be on slot and not on part itself
        delete short.level; // not accurate + not needed
        delete short.partType; // child does not need to know it's parent

        if (short.parts) short.parts = fixUpLuaData(config, short.parts);

        part.options.push(short);
      }
      res[partName] = part;
    }

    return res;
  }

  // first call expects data to be parts and res to be onOff
  // recursive call data will be the parts of parts etc and res the partially build result;
  function constructPC (data, res) {
    if (Array.isArray(res)) {
      var help = {};
      for (var i = 0; i < res.length; i += 1) {
        help[res[i].slotName] = res[i].active ? res[i].partName : 'none';
      }
      res = help;
    }

    if (res === undefined) {
      res = {};
    }

    for (var j = 0; j < data.length; j += 1) {
      if (data[j].parts) {
        constructPC(data[j].parts, res);
      } else if (data[j].options) {
        var selected = 'none';
        for (var i = 0; i < data[j].options.length; i += 1) {
          if (data[j].options[i].active) {
            selected = data[j].options[i].partName;
          }
        }
        res[data[j].slotName] = selected;
      }
    }
    return res;
  }

  $scope.$on('VehiclePartsTree', (event, config) => {
    // console.log(angular.copy(config));
    var data = fixUpLuaData(config, config.slotMap);
    var processed = processData(data);
    pcData = constructPC(processed.parts, processed.onOff);
    // console.log(processed);
    $scope.$evalAsync(() => {
      $scope.onOff = processed.onOff.sort(sortingFunction.bind(undefined, 'description'));
      $scope.parts = processed.parts;
      $scope.view = $scope.getView();
    });
  });

  $scope.changeParts = function () {
    pcData = constructPC($scope.parts, $scope.onOff);
    // console.log(pcData);
    bngApi.activeObjectLua(`partmgmt.setPartsConfig(${bngApi.serializeToLua(pcData)})`);
  };

  vm.changePart = function (id, removing) {
    // prevent user from accidentally removing a core slot
    if ($scope.view.data[$scope.view.active].coreSlot && removing) return;
    
    var options = $scope.view.data[$scope.view.active].options;

    for (var i = 0; i < options.length; i += 1) {
      options[i].active = i === id && !options[id].active;
    }
    $scope.changeParts();
  };

  // TODO: don't forget that potentially the vehicle can be changed underneath the menu -yh

  bngApi.activeObjectLua('partmgmt.requestPartsTree()');


  $scope.$on('VehicleChange', () => {
    bngApi.activeObjectLua('partmgmt.requestPartsTree()');
  });

  function maxDepth (parts, res) {
    // disabled for the moment
    return 0;

    res = res || 0;
    var steps = [0];

    for (var i = parts.length - 1; i >= 0; i--) {
      if(parts[i].parts) {
        steps.push(maxDepth(parts[i].parts, res + 1));
      }
    }
    return Math.max.apply(undefined, steps) || res;
  }


  function followPath (tree, path) {
    var res = tree;

    for (var i = 0; i < path.length; i += 1) {
      res = res[path[i]];
    }

    return res;
  }

  vm.path = [];

  $scope.getView = function () {
    var view = {
      data: followPath($scope.parts, vm.path)
    };

    view.location = {
      behind: vm.path.filter((elem) => elem !== 'parts').length,
      ahead: maxDepth(view.data),
      name: (followPath($scope.parts, vm.path.slice(0, (vm.path[vm.path.length - 1] === 'parts' ? -1 : vm.path.length))).description || 'Car')
    };

    return view;
  };

  vm.enter = function (key) {
    if ($scope.view.data[key].parts) {
      vm.path.push(key, 'parts');
      $scope.$evalAsync(() => {
        $scope.view = $scope.getView();
      });
    }
    addBack();
  };

  vm.back = function (numElems) {
    var numElems = numElems || 1;
    var remaining = vm.path;

    if (vm.path.length >= numElems) {
      
      for (var i = 0; i < numElems; i += 1) {
        var slice = 1;
        if (remaining[remaining.length -1] === 'parts') {
          slice = 2;
        }
        remaining = remaining.slice(0, slice * -1);
      }

      vm.path = remaining;
      $scope.$evalAsync(() => {
        $scope.view = $scope.getView();
      });
    }
    if (vm.path.length === 0) {
      if (origBack !== undefined) {
        actions.back = origBack;
      } else {
        delete actions.back;
      }
    }
  };

  // $scope.$watch(vm.partsPanelActive, () => console.log(val))

  var actions = {};
  var thisBack = {cmd: vm.back, name: 'Back', navigation: false}
  var origBack;

  function addBack () {
    if (actions.back !== thisBack) {
      origBack = actions.back;
      actions.back = thisBack;
    }
  }

  var clicked = false;
  vm.preventBlurAction = () => {
    clicked = true;
  };
  vm.blur = () => {
    vm.slotsActive = clicked || false;
    clicked = false;
  };

  vm.getFun = function () {return actions;};

  vm.panelFocused = false;

  vm.panelFocus = function (val) {
    vm.panelFocused = val;
  };


  $scope.$on('$destroy', () => {
    vm.deselectPart();
  });
}]);