angular.module('beamng.gamepadNav')

.factory('SpatialNavigation', ['logger', '$rootScope', function (logger, $rootScope) {
  var _config = {
    min_overlap: 0.7
  };

  var rulerDistance = (r1, r2) => Math.sqrt(Math.pow((r1.left + r1.width/2 - r2.left - r2.width/2), 2) + Math.pow((r1.top + r1.height/2 - r2.top - r2.height/2), 2));

  var activeRoot = null;

  var _currentViewActions = {};

  var _RULES_ = {
    visible: (x) => x.offsetWidth > 0 && x.offsetHeight > 0,

    inTargetArea: {
      up:    (_rect_, orect) => _rect_.top < orect.top,
      down:  (_rect_, orect) => _rect_.bottom > orect.bottom,
      right: (_rect_, orect) => _rect_.right > orect.right,
      left:  (_rect_, orect) => _rect_.left < orect.left
    },

    overlap: {
      up:    (_rect_, orect) => (Math.min(_rect_.right, orect.right) - Math.max(_rect_.left, orect.left)) / Math.min(_rect_.width, orect.width),
      down:  (_rect_, orect) => (Math.min(_rect_.right, orect.right) - Math.max(_rect_.left, orect.left)) / Math.min(_rect_.width, orect.width),
      right: (_rect_, orect) => (Math.min(_rect_.bottom, orect.bottom) - Math.max(_rect_.top, orect.top)) / Math.min(_rect_.height, orect.height),
      left:  (_rect_, orect) => (Math.min(_rect_.bottom, orect.bottom) - Math.max(_rect_.top, orect.top)) / Math.min(_rect_.height, orect.height)
    },

    directDistance: {
      up:    (_rect_, orect) =>  orect.top - _rect_.top,
      down:  (_rect_, orect) => _rect_.bottom - orect.bottom,
      right: (_rect_, orect) => _rect_.right - orect.right,
      left:  (_rect_, orect) => orect.left - _rect_.left
    },

    customDistance: {
      up:    rulerDistance, //(_rect_, orect) => 10,
      down:  rulerDistance, //(_rect_, orect) => 10, //_rect_.bottom > orect.bottom,
      right: rulerDistance, //(_rect_, orect) => 10, //_rect_.right > orect.right,
      left:  rulerDistance  //(_rect_, orect) => 10  //_rect_.left < orect.left
    }
  };


  var _classifyTargets = function (items, orect, direction) {
    var targets = {direct: [], secondary: []};

    for (var i=0, numItems = items.length; i<numItems; i++) {
      if (!(direction in _RULES_.inTargetArea) || !(_RULES_.inTargetArea[direction](items[i].rect, orect))) continue;
      if (_RULES_.overlap[direction](items[i].rect, orect) > _config.min_overlap)
        targets.direct.push(items[i])
      else
        targets.secondary.push(items[i]);
    }

    return targets;
  };

  var _closestTarget = function (items, origin, direction) {
    logger.spatialNav.debug('closest target: among', items, 'from', origin);
    var originRect = origin.getBoundingClientRect()
      , index = -1
      , minDistance = Infinity
      , currentDistance
    ;

    var visibleRects = items.map((item, ind) => {
      var x = item.elem;
      if (x !== origin && _RULES_.visible(x) && item.active)
        return {rect: x.getBoundingClientRect(), index: ind};
    }).filter(x => x);

    var targets = _classifyTargets(visibleRects, originRect, direction);

    if (targets.direct.length > 0) {
      for (var i=0, numItems = targets.direct.length; i<numItems; i++) {
        currentDistance = _RULES_.directDistance[direction](targets.direct[i].rect, originRect);
        if (currentDistance < minDistance) {
          minDistance = currentDistance;
          index = targets.direct[i].index;
        }
      }
    } else {
      for (var i=0, numItems = targets.secondary.length; i<numItems; i++) {
        // logger.spatialNav.debug('secondary:', targets.secondary);
        currentDistance = _RULES_.customDistance[direction](targets.secondary[i].rect, originRect);
        if (currentDistance < minDistance) {
          minDistance = currentDistance;
          index = targets.secondary[i].index;
        }
      }
    }

    return index;
  }

  var _handleAction = function (action, val) {
    logger.spatialNav.debug(`Handling action (${action}). active root:`, activeRoot);
    // if there is no active root still have a look into the viewActions
    var specialAction = (activeRoot ? activeRoot.handleAction(action, val) : false) || actionHelper(_currentViewActions[action], $rootScope, val);
    if (!specialAction) {
      logger.spatialNav.log('no special action');
      if (!activeRoot.navigate(action)) {
        logger.spatialNav.log('no active root navigation');
      }
    }
    logger.spatialNav.debug('-------- DONE.');
  };

  function actionHelper (action, scope, val, str, func) {
    var cmd = action;

    if (typeof action === 'object' && action.cmd) {
      cmd = action.cmd;
    }

    switch(typeof cmd) {
      case 'string':
        if (str) {
          str(cmd, val);
        } else {
          scope.$eval(cmd);
        }
        return true;
      case 'function':
        (func || cmd)(val);
        return true;
    }
    return false;
  }

  // $rootScope.$on('MenuItemNavigation', _handleAction);

  return {
    setActiveRoot: (rootCtrl) => { logger.spatialNav.debug('Setting active root:', rootCtrl); activeRoot = rootCtrl;},
    enterRoot: (rootCtrl) => rootCtrl.recievedFocus(),
    config: _config,
    get currentViewActions () {return _currentViewActions;},
    get activeRoot () {return activeRoot;},
    closestTarget: _closestTarget,
    triggerAction: _handleAction,
    isVisible: _RULES_.visible,
    actionHelper: actionHelper
  };
}])


.controller('NavRootCtrl', ['$attrs', '$element', 'logger', '$scope', 'SpatialNavigation',
  function ($attrs, $element, logger, $scope, SpatialNavigation) {
    var ctrl = this
      , itemToActivate // same as default active, but only triggers when the root is the new active root
    ;

    ctrl.rootNavActions = $scope.$eval($attrs.rootNavActions) || {}

    ctrl.addAction = function (action, func) {
      if (ctrl.rootNavActions[action] === undefined) {
        ctrl.rootNavActions[action] = func;
        logger.spatialNav.debug(ctrl.rootNavActions);
      }
    };

    ctrl.registerItemToActivate = function (elem) {
      itemToActivate = elem;
    }

    ctrl.recievedFocus = function () {
      if (itemToActivate && SpatialNavigation.isVisible(itemToActivate)) {
        itemToActivate.focus();
      }
    };

    logger.spatialNav.log('ROOT ACTIONS:', ctrl.rootNavActions);
    ctrl.element = $element[0];

    ctrl.children = []; // [{element: <Element>, ctrl: ngController}]
    ctrl.focusedItem = null;

    ctrl.handleAction = (action, val) => {
      logger.spatialNav.log(action, ctrl.rootNavActions);

      return ctrl.focusedItem.ctrl.handleNavAction(action, val) || (action in ctrl.rootNavActions ?  () => {
        SpatialNavigation.actionHelper(ctrl.rootNavActions[action], $scope, val);
        return true; } : (() => false)
      )();
    };

    ctrl.navigate = (direction) => {
      var index = SpatialNavigation.closestTarget(ctrl.children.map(x => {return {elem: x.element, active: x.active};}), ctrl.focusedItem.element, direction);
      if (index < 0) {
        // logger.spatialNav.debug(`No target nav-item found for direction ${direction}.`);
        return false;
      }

      ctrl.children[index].element.focus();

      return true;
    };
  }
])


.directive('bngNavRoot', ['SpatialNavigation', function (SpatialNavigation) {
  return {
    scope: false,
    controller: 'NavRootCtrl'
  };
}])





.controller('NavItemCtrl', ['logger', '$scope', '$element', '$attrs', 'SpatialNavigation', function (logger, $scope, $element, $attrs, SpatialNavigation) {
  var $ctrl = this;

  var _defaultActions = {
    confirm: { cmd: () => { $element.triggerHandler('click'); }, navigation: true, name: 'ui.actions.confirm'}
  };

  $ctrl.actions = angular.merge(_defaultActions, ($scope.$eval($attrs.itemNavActions) || {}));

  $ctrl.focus = function () {$element[0].focus();};

  logger.spatialNav.debug($ctrl.actions);

  $ctrl.handleNavAction = (action, val) => {
    logger.spatialNav.debug(`Handling action (${action})`);

    if (!(action in $ctrl.actions) || $ctrl.actions[action] === undefined) {
      logger.spatialNav.debug('Nothing here...');
      return false;
    }

    logger.spatialNav.debug(`Found registered action: ${$ctrl.actions[action]}`, $ctrl.actions);
    SpatialNavigation.actionHelper($ctrl.actions[action], $scope, val, function (cmd) {
        if (cmd.charAt(0) === '#') {
          // logger.spatialNav.debug(`Navigating to ${$ctrl.actions[action]}`);
          navRoot.element.querySelector(`[nav-id="${$ctrl.actions[action].slice(1)}"]`).focus();
        } else {
          // logger.spatialNav.debug(`Evaluating ${$ctrl.actions[action]}`);
          $scope.$eval(cmd);
        }
    });

    return true;
  };
}])


.directive('bngNavItem', ['logger', 'SpatialNavigation', '$rootScope', function (logger, SpatialNavigation, $rootScope) {
  return {
    require: '^^bngNavRoot',
    scope: false,
    controller: 'NavItemCtrl as itmCtrl',
    link: function (scope, element, attrs, navRoot) {
      element[0].tabIndex = -1; // make element focusable
      var _rootEntry = {element: element[0], ctrl: scope.itmCtrl, active: attrs.navItemDisabled !== 'false'}; // The object to be used from navRoot parent

      element.on('focus', () => {
        if (_rootEntry.active) {
          logger.spatialNav.debug('Got focus:', element[0]);
          $rootScope.$broadcast('FocusedElementChanged');
          SpatialNavigation.setActiveRoot(navRoot);
          navRoot.focusedItem = _rootEntry;
        } else {
          element[0].blur();
        }
      });

      element.on('mouseover', (event) => {
        if (_rootEntry.active) {
          event.stopPropagation();
          event.preventDefault();
          element[0].focus();
        }
      });

      element.ready(() => {
        navRoot.children.push(_rootEntry);
        if (scope.$eval(attrs.bngNavDefaultFocus)) {
          element[0].focus();
        }

        if (scope.$eval(attrs.rootActiveFocus)) {
          navRoot.registerItemToActivate(element[0]);
        }
      });

      attrs.$observe('navItemDisabled', function () {
        _rootEntry.active = attrs.navItemDisabled !== 'false';
      });
    }
  };
}])

.directive('bngEnterableRoot', ['SpatialNavigation', function (SpatialNavigation) {
  return {
    require: ['bngNavItem', 'bngNavRoot'],
    restrict: 'A',
    link: function (scope, elem, attrs, ctrls) {
      var itm = ctrls[0]
        , rt = ctrls[1]
      ;
      console.log(itm, rt);
      itm.actions.confirm = () => SpatialNavigation.enterRoot(rt);
      rt.rootNavActions.back = () => itm.focus();
    }
  };
}])

.directive('bngNavPossibleActions', ['SpatialNavigation', 'gamepadNav', 'logger', function (SpatialNavigation, gamepadNav, logger) {
  return {
    restrict: 'E',
    template: `<div layout="row">
      <div ng-repeat="(key, val) in actions" class="possibleActionKey color1" style="font-size: 14pt;" layout="row" layout-align="start center" ng-click="execute(key)">
        <binding style="margin-right: 12px;" action="{{:: prefix(key)}}"></binding>
        <span>{{(val.name || key) | translate}}</span>
      </div>
    </div>`,
    scope: {
      exclude: '=?',
      include: '=?'
    },
    link: function (scope) {
      scope.actions = {};
      scope.prefix = gamepadNav.prefix;

      scope.execute = SpatialNavigation.triggerAction;

      function getActions () {
        var dst = {}
          , src1 = SpatialNavigation.currentViewActions
          , src2 = {}
          , src3 = {}
        ;

        if (SpatialNavigation.activeRoot) {
          src2 = SpatialNavigation.activeRoot.rootNavActions;
          src3 = SpatialNavigation.activeRoot.focusedItem.ctrl.actions;
        }
        angular.merge(dst, src1, src2, src3);

        logger.spatialNav.log(dst);
        for (var key in dst) {
          if (dst[key].navigation || dst[key].hide) {
            delete dst[key];
          }
        }
        return dst;
      }

      var lastActionWithoutElemChange;

      scope.$on('FocusedElementChanged', () => {
        scope.$evalAsync(() => {scope.actions = getActions()});
        lastActionWithoutElemChange = false;
      });
      scope.$on('MenuItemNavigation', () => {
        if (lastActionWithoutElemChange) {
          scope.$evalAsync(() => {scope.actions = getActions()});
        }
        lastActionWithoutElemChange = true;
      })
    }
  }
}])


;

