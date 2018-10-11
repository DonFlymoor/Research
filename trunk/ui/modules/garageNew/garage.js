angular.module('beamng.garage')


.directive('gpPanel', ['logger', 'SpatialNavigation', 'Utils', function (logger, SpatialNavigation, Utils) {
  return {
    template: `
      <div style="position: relative;" ng-focus="setActive(true)" ng-blur="setActive(false)" class="filler" bng-nav-item item-nav-actions="{up: {cmd: 'up()', navigation: true}, down: {cmd: 'down()', navigation: true}, confirm: {cmd: 'enter()', name: 'ui.actions.enter', navigation: false}}" nav-item-disabled="{{navigatable}}">
        <div class="filler" ng-style="{'background-color': noBackground ? 'transparent' : 'rgba(0, 0, 0, 0.4)'}">
          <div bng-blur="!noBackground" radius="8px" class="filler" style="position: relative;">
            <div ng-transclude style="padding: {{noPadding ? '' : '15px'}}; height: {{noPadding ? '100%' : 'calc(100% - 30px)'}}; overflow-y: auto; overflow-x: hidden; text-align: left; direction: {{:: rotated === 'true' ? 'rtl' : 'ltr'}};"></div>

            <gp-gradient-corner active="true" style="position: absolute; bottom: 100%; left: 100%; height: 15px; width: 15px;" ng-if="!rotated && active && !disableSelectcorner" horizontal="'top'" vertical="'right'"></gp-gradient-corner>
            <gp-gradient-corner active="true" style="position: absolute; top: 100%; right: 100%; height: 15px; width: 15px;" ng-if="!rotated && active && !disableSelectcorner" horizontal="'bottom'" vertical="'left'"></gp-gradient-corner>
            <gp-gradient-corner active="true" style="position: absolute; bottom: 100%; right: 100%; height: 15px; width: 15px;" ng-if="rotated && active && !disableSelectcorner" horizontal="'top'" vertical="'left'"></gp-gradient-corner>
            <gp-gradient-corner active="true" style="position: absolute; top: 100%; left: 100%; height: 15px; width: 15px;" ng-if="rotated && active && !disableSelectcorner" horizontal="'bottom'" vertical="'right'"></gp-gradient-corner>
          </div>
        </div>

        <gp-gradient ng-if="!stripped" style="position: absolute; {{:: left}}: 20px; top: 0; width: 40%; max-width: 250px;" reverse="{{:: rotated}}"></gp-gradient>
        <gp-gradient ng-if="!stripped" style="position: absolute; {{:: left}}: 0; top: 20px; bottom: {{:: part ? '20%' : '50%'}}; max-height: {{:: part ? '' : '250px'}};" orientation="vertical"></gp-gradient>
        <gp-circle ng-if="!middle && !stripped" style="position: absolute; top: -7.5px; {{:: left}}: {{:: part ? '-15px' : '-7.5px'}}; z-index: 12;"></gp-circle>

        <gp-gradient ng-if="middle && !stripped" style="position: absolute; {{:: right}}: 20px; top: 0; width: 50%; max-width: 250px;" reverse="{{:: !rotated}}"></gp-gradient>
        <gp-gradient ng-if="middle && !stripped" style="position: absolute; {{:: right}}: 0; top: 20px; bottom: 50%; max-height: 250px;" orientation="vertical"></gp-gradient>

        <div style="{{:: left}}: -55px;" layout="column" class="tabContainer" ng-if="tabs.length > 1">
          <gp-menu-btn class="tabItem" ng-mouseover="activateTab($index)" ng-repeat="tab in tabs track by $index" icon="tab.scope.icon" active="openTab === $index && active"></gp-menu-btn>
        </div>
      </div>`,
    transclude: true,
    scope: {
      rotated: '@',
      title: '=',
      openTab: '=?',
      middle: '@',
      part: '@',
      noPadding: '@',
      navigatable: '@?',
      defaultActive: '@?',
      stripped: '@?',
      noBackground: '=?',
      focused: '&?',
      iconFallback: '@',
      disableSelectcorner: '@'
    },
    restrict: 'E',
    controller: function ($scope, $element) {
      var elem = angular.element($element[0]);
      var vm = this;

      if ($scope.rotated === 'true') {
        $scope.left = 'right';
        $scope.right = 'left';
      } else {
        $scope.left = 'left';
        $scope.right = 'right';
      }

      $scope.setActive = function (val) {
        $scope.active = val;
        vm.active = val;
      };

      $scope.$watch('active', (v) => {
        if ($scope.focused) {
          $scope.focused()(v);
        }
      });

      $scope.openTab = $scope.openTab || 0;

      $scope.tabs = [];

      $scope.down = function () {
        $scope.$evalAsync(() => {
          if ($scope.openTab < $scope.tabs.length - 1) {
            $scope.activateTab($scope.openTab + 1);
          }
        });
      };

      $scope.up = function () {
        $scope.$evalAsync(() => {
          if ($scope.openTab > 0) {
            $scope.activateTab($scope.openTab - 1);
          }
        });
      };

      $scope.enter = function () {
        // console.log($scope.tabs[$scope.openTab].rtCtrl);
        SpatialNavigation.enterRoot($scope.tabs[$scope.openTab].rtCtrl);
      };

      Utils.waitForCefAndAngular(() => {
        if($scope.$eval($scope.defaultActive)) {
          $scope.enter();
        }
      });

      $scope.activateTab = function (tabId) {
        $scope.tabs[$scope.openTab].scope.open = false;
        $scope.openTab = tabId;
        $scope.tabs[$scope.openTab].scope.open = true;
      };

      vm.addTab = function (tabScope, rootCtrl) {
        $scope.tabs.push({scope: tabScope, rtCtrl: rootCtrl});
        if ($scope.tabs.length === $scope.openTab + 1) {
          tabScope.open = true;
        }

        return {
          cmd: () => {$element[0].children[0].focus()},
          name: 'ui.actions.exit'
        };
      };
    }
  };
}])

.directive('gpPanelTab', ['SpatialNavigation', function (SpatialNavigation) {
  return {
    template: `
      <div ng-if="open">
        <gp-heading stripped="{{stripped}}" ng-if="slotFilled('header')" style="direction: ltr; position: absolute; {{rotated ? 'right' : 'left'}}: 0; bottom: calc(100% + 22px); font-size: 1.7em;" rotated="{{rotated}}">
          <div ng-transclude="header"></div>
        </gp-heading>

        <div ng-transclude class="filler">
        </div>

        <div ng-if="slotFilled('footer')" style="direction: ltr; position: absolute; top: 100%; left: -5px; right: -5px;" ng-transclude="footer">
        </div>
      </div>
    `,
    transclude: {
       'footer': '?gpPanelTabFooter',
       'header': '?gpPanelTabHeader'
    },
    restrict: 'E',
    require: ['^gpPanel', '?bngNavRoot'],
    scope: {
      title: '@',
      icon: '@',
      rotated: '@',
      stripped: '@'
    },
    link: function(scope, elem, attr, ctrls) {
      scope.open = false;
      scope.gpPanelCtrl = ctrls[0];
      var callback = scope.gpPanelCtrl.addTab(scope, ctrls[1]);

      scope.rootActive = true;
      if (ctrls[1] && callback) {
        ctrls[1].addAction('back', callback);
      }
    },
    controller: ['$scope', '$transclude', function ($scope, $transclude) {
      $scope.slotFilled = $transclude.isSlotFilled;
    }]
  };
}])

.directive('gpGradientCorner', function () {
  return {
    template: `
      <div style="position: absolute; {{horizontal}}: 0px; {{vertical}}: 0px;" class="filler">
        <gp-gradient active="active" style="position: absolute; {{horizontal}}: 0; {{vertical}}: 0; width: 200%;" reverse="{{vertical === 'right'}}"></gp-gradient>
        <gp-gradient active="active" style="position: absolute; {{vertical}}: 0; {{horizontal}}: 0; height: 200%;" reverse="{{horizontal === 'bottom'}}" orientation="vertical"></gp-gradient>
      </div>
    `,
    scope: {
      horizontal: '=',
      vertical: '=',
      active: '='
    },
    link: function (scope) {

    }
  };
})

.directive('gpMenuBtn', function () {
  return {
    template: `
      <div class="btn filler" style="position: relative;" ng-class="{'active': active}" bng-blur radius="30px" layout layout-align="center center">
        <div style="width: 85%; height: 85%; position: relative;">
          <bng-icon type="sprite" src="icon"></bng-icon>
        </div>
        <div ng-if="active && title" style="position: absolute; bottom: -24pt; left: -100%; right: -100%; font-size: 13pt; text-align: center" class="color1 font2">{{title | translate}}</div>
      </div>
    `,
    scope: {
      icon: '=',
      active: '=',
      title: '@?'
    }
  };
})

.directive('gpBtn', function () {
  return {
    template: `
      <div ng-click="btnClick()" class="color3 normalBtn filler" ng-focus="showTitle = true" ng-blur="showTitle = false" layout layout-align="center center" style="position: relative;" bng-nav-item item-nav-actions="{confirm: {navigation: false}}" bng-nav-default-focus="{{defaultFocus}}">
        <md-icon class="material-icons color1" ng-if="!isSvg(icon)" style="font-size: 36px;">{{icon}}</md-icon>
        <svg class="material-icons fill-color1" ng-if="isSvg(icon)" style="margin: auto; height: 36px; width: 36px;"><use xlink:href="{{icon}}"/></svg>
        <div ng-if="showTitle && title" style="position: absolute; bottom: -20pt; left: 0; right: 0; font-size: 13pt;" layout="row" layout-align="center center" class="color1 font2">{{title | translate}}</div>
      </div>
    `,
    scope: {
      icon: '=',
      title: '@',
      defaultFocus: '=',
      btnClick: '&?'
    },
    link: function (scope) {
      scope.isSvg = (icon) => icon && icon.charAt(0) === '#';
    }
  };
})

.directive('gpRoundBtn', function () {
  return {
    template: `
      <div class="filler btnRound" ng-focus="active = true" ng-blur="active = false" ng-class="{'active': active}" layout layout-align="center center" style="position: relative;" bng-nav-item item-nav-actions="{confirm: {navigation: false}}">
        <md-icon class="material-icons menu-icon">{{icon}}</md-icon>
        <div ng-if="active && title" style="position: absolute; bottom: -25pt; left: 50%; font-size: 13pt; width: 100%; min-width: 200px; -webkit-transform: translate(-50%, 0);" layout="row" layout-align="center center" class="color1 font2">{{title | translate}}</div>
      </div>
    `,
    scope: {
      icon: '=',
      title: '@'
    }
  };
})

.directive('gpBigBtn', [function () {
  return {
    template: `
      <gp-square style="width: {{:: btnSize === undefined || btnSize === '' ? '70px' : btnSize}};" ng-style="{cursor: btnDisabled ? 'not-allowed' : 'pointer'}">
        <!--Todo: fix the hardcoded color-->
        <div class="filler" ng-click="btnClick()" bng-sound="{click: 'event:>UI>Garage>Select Vehicle'}" ng-class="{'color3': !btnDisabled}" ng-style="{'background-color': btnDisabled ? '#808080' : '#FF7600'}"">
          <div class="filler color1 font2" layout="row" layout-align="center center">
            {{btnName}}
          </div>
        </div>
      </gp-square>`,
    scope: {
      btnClick: '&',
      btnName: '@',
      btnSize: '@',
      btnDisabled: '=',
    }
  };
}])

.directive('gpArrow', function () {
  return {
    template: `
       <div class="filler gpArrow" ng-include="'modules/garageNew/elements/arrow.svg'" style="transform: rotate({{degree}}deg); pointer-events: none; fill: currentColor"></div>
    `,
    scope: {
      direction: '@?',
      degree: '=?',
    },
    link: function (scope) {
      switch (scope.direction) {
        case 'top': scope.degree = 180; break;
        case 'bottom': scope.degree = 0; break;
        case 'right': scope.degree = 270; break;
        case 'left': scope.degree = 90; break;
      }
    }
  };
})

.directive('gpCircle', function () {
  return {
    template: `
      <div ng-class="{'bg-color3': active, 'bg-color2': !active}" style="width: 20px; height: 20px; border-radius: 20px;"></div>
    `,
    scope: {
      active: '=?'
    }
  };
})

.directive('gpGradient', function () {
  return {
    template: `
      <div style="{{:: dirWidth}}: calc(100% + ({{:: both ? 2 : 1}} * 30px)); position: relative; {{:: reverse === 'true' || both ? direction + ': -30px' : ''}}" layout="{{::layout}}">
        <div ng-if="reverse === 'true' || both" style="background: -webkit-linear-gradient({{:: toggleDir(direction)}}, {{active ? '#FF6700' : 'currentColor'}}, transparent); {{:: dirWidth}}: 30px;"></div>
        <div style="{{:: dirHeight}}: {{::actualWidth}}px;" ng-class="{'bg-color3': active, 'bg-color2': !active}"" flex></div>
        <div ng-if="reverse !== 'true'" style="background: -webkit-linear-gradient({{:: direction}}, {{active ? '#FF6700' : 'currentColor'}}, transparent); {{:: dirWidth}}: 30px;"></div>
      </div>
    `,
    scope: {
      orientation: '@',
      reverse: '@',
      both: '@',
      active: '=?',
      width: '@'
    },
    link: function (scope) {
      scope.actualWidth = scope.width || '3';

      if (scope.orientation === 'vertical') {
        scope.dirHeight = 'width';
        scope.dirWidth = 'height';
        scope.direction = 'top';
        scope.layout = 'column'
        scope.toggleDir = () => scope.direction === 'top' ? 'bottom' : 'top';
      } else {
        scope.dirHeight = 'height';
        scope.dirWidth = 'width';
        scope.direction = 'left';
        scope.layout = 'row'
        scope.toggleDir = () => scope.direction === 'right' ? 'left' : 'right';
      }

    }
  };
})

.directive('gpHeading', function () {
  return {
    template: `
      <div style="position: relative; {{:: left}}: 20px; text-align: {{:: left}}">
        <gp-gradient active="active" ng-if="!stripped" both="true" style="position: absolute; bottom: -3px; left: 0; right: 0;"></gp-gradient>
        <div ng-transclude class="font2 color1"></div>
      </div>
    `,
    transclude: true,
    restrict: 'E',
    scope: {
      rotated: '@',
      stripped: '@',
      active: '=?'
    },
    link: function(scope) {
      if (scope.rotated === 'true') {
        scope.left = 'right';
      } else {
        scope.left = 'left';
      }
    }
  };
})

.directive('gpImgList', function (RateLimiter) {
  return {
    template: `
    <div class="container" bng-nav-item nav-item-disabled="{{navigatable}}" class="animateAwesomeThings">
      <div class="container" style="-webkit-mask-image: -webkit-linear-gradient({{getDir()}}, transparent, black 10%, black 90%, transparent)">
        <div class="filler movingPixels" style="position: relative;" layout="{{dir}}" layout-align="space-between center">
          <div ng-repeat="item in newList | orderBy:$index:reverse track by $index" style="height: calc({{boxHeight}}px * {{scaleUp($index) ? '1.25' : '1'}}); width: calc({{boxWidth}}px * {{scaleUp($index) ? '1.25' : '1'}}); padding: {{paddingDim}};">
            <div class="filler imgListItem" layout="row" layout-align="center center">
              <div class="filler" ng-class="{activeBox: $index === getActive(), followActiveBox: $index === successor, 'selected': $index === getActive(), 'active': active}" style="transform: scale({{$index === allTheFun ? '0.8' : $index === getActive() ? '1' : ''}}); overflow: hidden; background: rgba(255, 255, 255, 0.2);">
                <img ng-src="{{item.previewGarage || item.preview}}" style="height: {{item.previewGarage || item.preview ? '100%' : '0'}}; width: 100%; object-fit: cover; position: relative;" class="animationImage"/>
                <div ng-if="item.previewGarage === '/ui/images/emptyBackground.png'" class="color1 font1" style="position: absolute; top: 50%; left: 50%; -webkit-transform: translate(-50%, -50%); max-width: 90%;">{{item.key}}</div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="container" layout="{{dir}}" layout-align="space-between center">
        <div ng-repeat="item in newList | orderBy:$index:reverse track by $index" style="height: calc({{boxHeight}}px * {{scaleUp($index, true) ? '1.25' : '1'}}); width: calc({{boxWidth}}px * {{scaleUp($index, true) ? '1.25' : '1'}}); padding: {{paddingDim}}; cursor: pointer;" ng-click="shortcut($index)">
          <div class="filler imgListItem" layout="row" layout-align="center center">

            <div class="container" ng-class="{gradientBox: $index === getActive()}">
              <gp-gradient ng-if="$index === getActive()" width="{{borderDim}}" style="position: absolute; right: 5px; top: -{{active ? borderDim + 3 : borderDim}}px; left: 50%;" reverse="true"></gp-gradient>
              <gp-gradient ng-if="$index === getActive()" width="{{borderDim}}" style="position: absolute; left: 5px; bottom: -{{active ? borderDim + 3 : borderDim}}px; right: 50%;"></gp-gradient>
              <gp-gradient ng-if="$index === getActive()" width="{{borderDim}}" style="position: absolute; top: 5px; right: -{{active ? borderDim + 3 : borderDim}}px; bottom: 50%;" orientation="vertical"></gp-gradient>
              <gp-gradient ng-if="$index === getActive()" width="{{borderDim}}" style="position: absolute; bottom: 5px; left: -{{active ? borderDim + 3 : borderDim}}px; top: 50%;" orientation="vertical" reverse="true"></gp-gradient>
            </div>

            <div layout="row" layout-align="start start" class="container" ng-if="!hideItemNum && (reverse ? $first : $last)">
              <div style="position: relative; {{reverse ? 'bottom' : 'top'}}: {{boxHeight}}px; font-size: 1.3em;" class="font1 color3"><{{selected + 1}}/{{list.length}}></div>
            </div>
            <div layout="row" layout-align="center center" ng-mouseover="oLeft = true" ng-mouseleave="oLeft = false" ng-class="{'color3': left || oLeft, 'color2': !left || !oLeft}" class="container" ng-if="$first"><gp-arrow ng-click="swallowCLick($event, -1)" bng-sound="{click: 'event:>UI>Garage>Select Vehicle'}" direction="{{directions[1]}}" style="cursor: pointer; position: relative; {{directions[1]}}: -{{(horizontal ? boxWidth : boxHeight) * 0.5 + 30}}px;"></gp-arrow></div>
            <div layout="row" layout-align="center center" ng-mouseover="oRight = true" ng-mouseleave="oRight = false" ng-class="{'color3': right || oRight, 'color2': !right || !oRight}" class="container" ng-if="$last"><gp-arrow ng-click="swallowCLick($event, 1)" bng-sound="{click: 'event:>UI>Garage>Select Vehicle'}" direction="{{directions[0]}}" style="cursor: pointer; position: relative; {{directions[0]}}: -{{(horizontal ? boxWidth : boxHeight) * 0.5 + 30}}px;"></gp-arrow></div>
          </div>
        </div>
      </div>
    </div>
    `,
    scope: {
      selected: '=',
      list: '=',
      horizontal: '=',
      active: '=',
      ratio: '=',
      reverse: '=',
      hideItemNum: '=',
      increaseFunc: '&?',
      decreaseFunc: '&?',
      navigatable: '@?',
      sortBy: '&?',
      left: '=?',
      right: '=?',
      // clickSelected: '=?' // TODO: - yh
    },
    controller: function($scope, $element) {
      "use strict";
      var fits;

      function checkSelected () {
        $scope.selected = ($scope.selected !== undefined ? $scope.selected : 0);
      }

      function animationFun () {
        $element.addClass('animateAwesomeThings');
        // very very important: the timout should not be much longar than the actuall animation, since otherwise the animations won't be triggered correctly
        setTimeout(function() {$element.removeClass('animateAwesomeThings');}, 1000);
      }

      // TODO: do not have this as function, or at least cache the result, this is called far to frequently for this to be performant
      $scope.getActive = function () {
        var res = 1
        if ($scope.reverse && $scope.newList && $scope.newList.length -2 >= 0) {
          res = $scope.newList.length - 2;
        }
        if (res >= $scope.newList.length) {
          res = $scope.newList.length -1;
        }
        return res;
      };

      $scope.scaleUp = function (i, exlSucc) {
        if (!$scope.active) return false;
        if ($scope.allTheFun !== undefined && !exlSucc) return i === $scope.allTheFun;
        return i === $scope.getActive();
      }

      $scope.swallowCLick = (ev, num) => {
        $scope.updateSelected(num);
        ev.stopPropagation();
      };

      // hack, but the other possibilites are worse
      if ($scope.increaseFunc) {
        $scope.increaseFunc()(() => $scope.updateSelected(1));
      }

      if ($scope.decreaseFunc) {
        $scope.decreaseFunc()(() => $scope.updateSelected(-1));
      }

      checkSelected();

      var origListLength;
      var updateListDimDebounced = RateLimiter.debounce(updateListDim, 50)
      // window.addEventListener('resize', updateListDim);
      $scope.$watch(
        function () {
          help = $element[0].getBoundingClientRect();
          return [help.width, help.height, help.left, help.top].join('x');
        },
        updateListDimDebounced
      );
      $scope.$watch(() => $scope.selected, updateListDimDebounced);
      $scope.$watch(() => $scope.list, () => {
        if ($scope.list && $scope.sortBy !== undefined) {
          $scope.list.sort($scope.sortBy());
        }
        origListLength = ($scope.list || []).length;
        updateListDimDebounced();
        checkSelected();
      });

      $scope.shortcut = (val) => $scope.updateSelected($scope.reverse ? (val - $scope.newList.length + 2) : val - 1);

      var domElem = angular.element($element[0])[0];
      var movingPixels = domElem.getElementsByClassName('movingPixels')[0];

      var animationInProg = false;
      $scope.updateSelected = (val) => {
        if (val === 0) return;
        $scope.successor = $scope.getActive() + val;

        var newVal = (($scope.selected + ($scope.reverse ? -val : val) + $scope.list.length) % $scope.list.length) % origListLength;

        var doc = domElem.getElementsByClassName('activeBox');
        var doc2;

        var eventHandler = {
          handleEvent: (ev) => {
            // console.log(ev);
            switch (ev.animationName) {
              case 'wrongSizeOne':
                doc2 = domElem.getElementsByClassName('followActiveBox')[0];
                if (doc2 !== undefined) {
                  var direction = $scope.directions[val > 0 ? 0 : 1];
                  var move = doc2.getBoundingClientRect()[direction] - doc[0].parentNode.getBoundingClientRect()[direction];
                  $scope.$evalAsync(() => {
                    $scope.allTheFun = $scope.successor;
                    $element.addClass('animateAwesomeThings');
                    movingPixels.style[$scope.directions[0]] = move + 'px';
                    doc2.addEventListener('webkitAnimationEnd', eventHandler);
                    $element.removeClass('animateAwesomeThings2');
                  });
                } else {
                  doc[0].removeEventListener('webkitAnimationEnd', eventHandler);
                  $element.removeClass('animateAwesomeThings2');
                  $scope.$evalAsync(() => {
                    movingPixels.style[$scope.directions[0]] = '0px';
                    $scope.selected = newVal;
                    $scope.successor = undefined;
                    $scope.allTheFun = undefined;
                    animationInProg = false;
                  });
                }
                break;
              case 'rightSizeOne':
                doc[0].removeEventListener('webkitAnimationEnd', eventHandler);
                doc2.removeEventListener('webkitAnimationEnd', eventHandler);
                $scope.$evalAsync(() => {
                  $element.removeClass('animateAwesomeThings');
                  movingPixels.style[$scope.directions[0]] = '0px';
                  $scope.selected = newVal;
                  $scope.successor = undefined;
                  $scope.allTheFun = undefined;
                  animationInProg = false;
                });
                break;
            }
          }
        };

        if (doc.length > 0) {
          if (!animationInProg) {
            animationInProg = true;
            doc[0].addEventListener('webkitAnimationEnd', eventHandler);
            $element.addClass('animateAwesomeThings2');
          }
        } else {
          $scope.$evalAsync(() => {
            $scope.selected = newVal;
          });
        }
      };

      $scope.directions = ['bottom', 'top']

      function updateListDim () {
        if ($scope.list !== undefined) {
          var width = $element[0].offsetWidth
            , height = $element[0].offsetHeight
            , boxHeight
            , boxWidth
            , borderDim
            , paddingDim
            , dir
            , startId
            , newList
            , helperList = []
            , yetAnotherList = [{emptyFiller: true}].concat($scope.list);
          ;

          if ((!$scope.horizontal !== undefined && $scope.horizontal === false) || height > width) {
            // vertical
            var invertedRatio = Math.pow($scope.ratio || 1, -1);
            dir = 'column';
            boxHeight = invertedRatio * width * 0.6;
            boxWidth = ($scope.ratio || 1) * boxHeight;
            borderDim = ($scope.active ? 4 : 3);
            paddingDim = `0 ${0.16 * width}px 0 ${0.16 * width}px`;
            $scope.directions = ['bottom', 'top']
            fits = Math.floor(height / (boxHeight + 0.05 * width)); // added some buffer, so the elements don't stich together if they would fit perfectly otherwise
          } else {
            // horizontal
            dir = 'row'
            boxHeight = 0.6 * height;
            boxWidth = ($scope.ratio || 1) * boxHeight;
            borderDim = ($scope.active ? 4 : 3);
            paddingDim = `${0.16 * height}px 0 ${0.16 * height}px 0`;
            $scope.directions = ['right', 'left'];
            fits = Math.floor(width / (boxWidth + 0.05 * height)); // added some buffer, so the elements don't stich together if they would fit perfectly otherwise
          }

          // in case the list is smaller then the number of elements that can be displayed -> repeat list
          for (var i = 0; i < fits && fits > helperList.length; i += 1) {
            helperList = helperList.concat([{emptyFiller: true}]);
          }

          startId = ($scope.selected + $scope.list.length) % $scope.list.length;
          var startSlice = fits > 1 ? startId : startId + 1;
          newList = yetAnotherList.slice(startSlice, startSlice + fits);

          if (newList.length !== fits) {
            newList = newList.concat(helperList.slice(0, fits - newList.length));
          }
          $scope.$evalAsync(() => {
            $scope.newList = newList;
            $scope.dir = dir;
            $scope.boxHeight = boxHeight;
            $scope.boxWidth = boxWidth;
            $scope.borderDim = borderDim;
            $scope.paddingDim = paddingDim;
          });
        }
      }
    }
  };
})

.service('BlurGame', ['bngApi', function (bngApi) {
  // todo: find a solution if i should actually overflow at some point
  var i = 0
    , list = {}
    , disabled = false
  ;

  function updateLua () {
    // console.log('update blur to lua', list);
    bngApi.engineLua(`ui_gameBlur.replaceGroup("uiBlur", ${bngApi.serializeToLua(disabled ? {} : list)})`);
  }

  return {
    register: function (coord) {
      if (coord !== undefined) {
        i += 1;

        if (list.isEmpty()) {
          bngApi.engineLua('extensions.load("ui_gameBlur");');
        }

        list[i] = coord;
      } else {
        throw new Error('You need to specify the coordinates to register');
      }
      updateLua();

      return i;
    },
    unregister: function (i) {
      delete list[i];
      updateLua();

      if (list.isEmpty()) {
        i = 0;
        bngApi.engineLua('extensions.unload("ui_gameBlur");');
      }
    },
    update: function (i, coord) {
      list[i] = coord;
      updateLua();
    },
    disable: function (bool) {
      disable = !!bool;
      updateLua();
    }
  }
}])

.directive('bngBlur', ['BlurGame', 'RateLimiter', function (BlurGame, RateLimiter) {
  return {
    restrict: 'A',
    link: function (scope, elem, attrs) {
      var id;
      var active = true;
      var blurUpdateWrapper = RateLimiter.debounce(updateBlur, 50);

      // dim change?
      scope.$watch(
        function () {
          help = elem[0].getBoundingClientRect();
          return [help.width, help.height, help.left, help.top].join('x');
        },
        blurUpdateWrapper
      )

      scope.$watch(attrs.bngBlur, (val) => {
        if (val !== undefined) {
          active = val;
          blurUpdateWrapper();
        }
      });

      function calcBlur () {
        var help = elem[0].getBoundingClientRect();
        return [ help.left / screen.width
          , help.top / screen.height
          , help.width / screen.width
          , help.height / screen.height
          ];
      }

      function updateBlur () {
        if (active) {
          if (id === undefined) {
            id = BlurGame.register(calcBlur());
          } else {
            BlurGame.update(id, calcBlur());
          }
        } else {
          BlurGame.unregister(id);
          id = undefined;
        }
      }

      scope.$on('$destroy', () => {
        BlurGame.unregister(id);
      });
    }
  };
}])


// found on: http://www.mademyday.de/css-height-equals-width-with-pure-css.html
.directive('gpSquare', [function () {
  return {
    restrict: 'E',
    template: `
      <div class='box box1_1'>
        <div class='container' ng-transclude></div>
      </div>
    `,
    transclude: true
  };
}])

.directive('gpDisplay', [function () {
  return {
    restrict: 'E',
    template: `
      <div class='box box16_19'>
        <div class='container' ng-transclude></div>
      </div>
    `,
    transclude: true
  };
}])

.directive('gpListInput', [function () {
  return {
    template: `
      <div flex layout="column" ng-style="{'background-color': active ? 'rgba(255, 103, 0, 0.3)' : 'transparent'}" style="padding: 15px 30px 0 30px;">
        <div layout="row" layout-align="start end" ng-style="{'opacity': active ? '1' : '1'}" class="color1">
          <ng-transclude flex></ng-transclude>
          <gp-big-btn style="background-color: red; margin: 5px;" btn-click="btnClick()" btn-name="{{btnName}}" btn-size="{{btnSize}}" btn-disabled="btnDisabled"></gp-big-btn>
        </div>
        <gp-gradient class="color2" both="true" style="width: calc(100% - 30px); position: relative; left: 15px;"></gp-gradient>
      </div>
    `,
    scope: {
      btnClick: '&',
      btnName: '@',
      btnSize: '@',
      btnDisabled: '=',
      active: '='
    },
    transclude: true
  };
}])

.directive('gpInputListItem', [function () {
  return {
    template: `
      <div class="filler color1 font1 inputListItem" layout="column" style="font-size: 1.1em; padding: 24px 24px 5px 24px; box-sizing: border-box;" bng-nav-item bng-nav-default-focus="{{defaultActive}}" root-active-focus="{{rootActive}}">
        <div layout="row">
          <div flex style="text-align: center;">{{title | translate}}</div>
          <div ng-if="val !== undefined" style="width: 25%; min-width: 50px;"></div>
        </div>
        <div layout="row" layout-align="center center" style="min-height: 32px;">
          <ng-transclude flex></ng-transclude>
          <div ng-if="val !== undefined" style="width: 25%; min-width: 50px;" layout="row" layout-align="end center" layout-wrap>
            <span ng-if"fixed !== undefined">{{val | maxFractions:fixed }}</span>
            <span ng-if="fixed === undefined">{{val}}</span>
            <span ng-if="unit" style="margin-left: 5px;">{{unit}}</span>
          </div>
        </div>
      </div>
    `,
    scope: {
      title: '@',
      val: '=',
      unit: '@',
      fixed: '@',
      defaultActive: '@',
      rootActive: '@'
    },
    transclude: true
  }
}])

.controller('garageCtrl', ['$scope', 'bngApi', 'Utils', 'gamepadNav', 'SpatialNavigation', '$state', function ($scope, bngApi, Utils, gamepadNav, SpatialNavigation, $state) {
  var prevCross = gamepadNav.crossfireEnabled()
    , prevGame = gamepadNav.gamepadNavEnabled()
    , prevSpatial = gamepadNav.gamepadNavEnabled()
  ;

  gamepadNav.enableCrossfire(false);
  gamepadNav.enableGamepadNav(false);
  gamepadNav.enableSpatialNav(true);

  bngApi.engineLua("bindings.menuActive(true)");

  $scope.$on('$destroy', () => {
    // just to be save it really is unloaded

    // For some reason using Utils.waitForCefAndAngular() is causing the module to sometimes not be unloaded...
    // Utils.waitForCefAndAngular(() => bngApi.engineLua('extensions.unload("ui_garage");'));

    bngApi.engineLua('extensions.unload("ui_garage");');


    // bngApi.engineLua("bindings.menuActive(false)");

    gamepadNav.enableCrossfire(prevCross);
    gamepadNav.enableGamepadNav(prevGame);
    gamepadNav.enableSpatialNav(prevSpatial);

    SpatialNavigation.currentViewActions.toggleMenues = oldAction;
  });

  var oldAction = SpatialNavigation.currentViewActions.toggleMenues;
  SpatialNavigation.currentViewActions.toggleMenues = {cmd: () => $state.go('garage.save'), name: 'ui.garage.exit'}
}])

.controller('garageMenuCtrl', ['$scope', 'logger', 'bngApi', '$state', 'Utils', 'SpatialNavigation', function ($scope, logger, bngApi, $state, Utils, SpatialNavigation) {
  'use strict';
  var vm = this;

  vm.menus =
  [
    { icon: 'garage_wheels'
    , name: 'ui.garage.tabs.load'
    , href: 'garage.menu.load'
    }
  , { icon: 'material_directions_car'
    , name: 'ui.garage.tabs.vehicles'
    , href: 'garage.menu.select'
    }
  , { icon: 'material_settings'
    , name: 'ui.garage.tabs.parts'
    , href: 'garage.menu.parts'
    }
  , { icon: 'material_tune'
    , name: 'ui.garage.tabs.tune'
    , href: 'garage.menu.tune'
    }
  , { icon: 'material_brush'
    , name: 'ui.garage.tabs.paint'
    , href: 'garage.menu.paint'
    }
  , { icon: 'material_photo_camera'
    , name: 'ui.garage.tabs.photo'
    , href: 'garage.menu.photo'
    }
  , { icon: 'material_save'
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
      bngApi.engineLua(`Engine.Audio.playOnce('AudioGui', 'event:>UI>Main Select')`);
      $state.go(vm.menus[nId].href);
    }

    SpatialNavigation.currentViewActions['trigger-left'].hide = (nId === 0);
    SpatialNavigation.currentViewActions['trigger-right'].hide = (nId + 1 === vm.menus.length);
  }

  vm.handleMenuChange = handleMenuChange;

  SpatialNavigation.currentViewActions['trigger-left'] = {cmd: () => handleMenuChange(-1), name: 'ui.actions.menuLeft', hide: false};
  SpatialNavigation.currentViewActions['trigger-right'] = {cmd: () => handleMenuChange(+1), name: 'ui.actions.menuRight', hide: false};
}]);
