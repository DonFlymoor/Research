angular.module('beamng.stuff')

.directive('useLangFont', ['$translate', function ($translate) {
  return {
    restrict: 'A',
    link: function (scope, elem, attrs) {
      function setFont () {
        var key = `ui.fonts.${attrs.useLangFont}`;
        $translate(key).then((font) => {
          if (font === key) {
            // in case a font doesn't specify the key requested fallback to the default font
            $translate('ui.fonts.1').then((font) => {
              elem.css('font-family', font);
            });
          } else {
            elem.css('font-family', font);
          }
        });
      }

      setFont();
      scope.$on('languageChange', setFont);
    }
  };
}])

// (function () {
//   'use strict';

//   angular.module('beamng.ui2Ports')

// this is how we will handle icons that should be the same, but appear in different ui contexts witout breaking naming or copying them over and over again
.constant('spriteDuplicates', {})

// .run(function (FS, spriteDuplicates) {
//   FS.loadJSON('Components/Icons/duplicates.json').then((dupes) => {
//     for (var key in dupes) {
//       spriteDuplicates[key] = dupes[key];
//     }
//   })
// })

// use this directive for icons
// icons should always be squares otherwise they are images and should not be handled here.
// .directive('bngIcon', function () {
//   return {
//     template: `
//       <bng-box1x1 class="filler" ng-switch="type" ng-style="{transform: getTransform()}">
//         <bng-flag ng-switch-when="flag" src="val" deg="getDeg()"></bng-flag>
//         <bng-icon-img ng-switch-when="img" src="val" deg="getDeg()"></bng-icon-img>
//         <bng-icon-material ng-switch-when="material" src="val" deg="getDeg()" color="color"></bng-icon-material>
//         <bng-icon-svg ng-switch-when="svg" src="val" deg="getDeg()" color="color"></bng-icon-svg>
//         <bng-icon-svg-sprite ng-switch-when="sprite" src="val" deg="getDeg()" color="color"></bng-icon-svg-sprite>
//         <bng-icon-svg-sprite ng-switch-default src="'general_beamng_logo_bw'" color="color"></bng-icon-svg-sprite>
//       </bng-box1x1>
//     `,
//     scope: {
//       type: '@',
//       val: '=src',
//       color: '=',
//       direction: '=?',
//       degree: '=?'
//     },
//     link: function (scope) {
//       scope.degree = scope.degree || 0;

//       scope.getDeg = function () {
//         switch (scope.direction) {
//         case 'top': scope.degree = 0; break;
//         case 'right': scope.degree = 90; break;
//         case 'bottom': scope.degree = 180; break;
//         case 'left': scope.degree = 270; break;
//         }
//         return scope.degree;
//       }
//     }
//   };
// })



// // === important: do not use any of these directly! use the above (bngIcon) instead =================================
// .directive('bngIconSvg', function () {
//   return {
//     restrict: 'E',
//     template: `<div ng-include="src" style="{{!color ? 'fill: currentColor;' : ''}} pointer-events: none; transform: rotate({{deg}}deg);" class="{{color ? 'fill-' + color : ''}}"></div>`,
//     scope: {
//       src: '=',
//       color: '=',
//       deg: '='
//     }
//   };
// })

// // === important: do not use any of these directly! use the above (bngIcon) instead =================================
// .directive('bngIconSvgSprite', function (spriteDuplicates) {
//   return {
//     restrict: 'E',
//     template: `<svg class="{{color ? 'fill-' + color : ''}} filler" style="{{!color ? 'fill: currentColor;' : ''}} pointer-events: none; transform: rotate({{deg}}deg);"><use xlink:href="{{getPath(src)}}"/></svg>`,
//     scope: {
//       src: '=',
//       color: '=',
//       deg: '='
//     },
//     link: function (scope) {
//       scope.getPath = (src) => `#${spriteDuplicates[src] || src}`;
//     }
//   };
// })

// // === important: do not use any of these directly! use the above (bngIcon) instead =================================
// .directive('bngIconMaterial', function () {
//   return {
//     restrict: 'E',
//     template: `<bng-icon-svg-sprite src="getPath(src)" color="color" deg="deg"></bng-icon-svg-sprite>`,
//     scope: {
//       src: '=',
//       color: '=',
//       deg: '='
//     },
//     link: function (scope) {
//       scope.getPath = (src) => `material_${src}`;
//     }
//   };
// })

// // === important: do not use any of these directly! use the above (bngIcon) instead =================================
// .directive('bngIconImg', function () {
//   return {
//     restrict: 'E',
//     template: `<img class="filler" ng-src="{{src}}" style="transform: rotate({{deg}}deg);"/>`,
//     scope: {
//       src: '=',
//       deg: '='
//     },
//   };
// })

// // === important: do not use any of these directly! use the above (bngIcon) instead =================================
// .directive('bngFlag', function () {
//   return {
//     restrict: 'E',
//     template: `<img class="filler" ng-src="{{imgSrc}}"  style="transform: rotate({{deg}}deg);"/>`,
//     scope: {
//       src: '=',
//       deg: '='
//     },
//     link: function (scope) {
//       var shortHand =
//         { 'United States': 'USA'
//         , 'Japan': 'JP'
//         , 'Germany': 'GER'
//         , 'Italy': 'IT'
//         }
//       ;
//       function setSrc () {
//         scope.imgSrc = `Assets/Icons/CountryFlags/${shortHand[scope.src] || scope.src || 'missing'}.png`;
//       }

//       scope.$watch('src', setSrc);

//       setSrc();
//     }
//   };s
// })


.directive('bngGrid', function () {
  return {
    restrict: 'E',
    template: `
      <div class="container" ng-transclude></div>`,
    scope: {
      rows: '@',
      cols: '@'
    },
    transclude: true,
    controller: function ($scope, $element) {
      var vm = this
        , childs = [] // TODO: implement this, so we can have some more control over how items are placed it the values do not result in a pixel perfect grid
          // otherwise we'll have some pixel fragments between and around the right and bottom border
        ;

      vm.register = function (x, y, rowspan, colspan, cb) {
        var res = {}
          , width = 100/Number($scope.cols)
          , height = 100/Number($scope.rows)
          ;
        res.width = `${width * colspan}%`;
        res.height = `${height * rowspan}%`;
        res.left = `${(x - 1) * width}%`;
        res.top = `${(y - 1) * height}%`;
        cb(res);
      }
    }
  }
})

.directive('bngGridItem', function () {
  return {
    require: '^bngGrid',
    // todo: perf only adjust height and width once (they are percentage based anyway and should then be handled by css)
    template: `
        <div style="position: absolute;" ng-transclude>
      </div>`,
    restrict: 'E',
    transclude: true,
    scope: {
      row: '@',
      col: '@',
      rowspan: '@',
      colspan: '@'
    },
    replace: true,
    link: function (scope, elem, attrs, gridCtrl) {
      var x = Number(scope.col)
        , y = Number(scope.row)
        , colspan = scope.colspan ? Number(scope.colspan) : 1
        , rowspan = scope.rowspan ? Number(scope.rowspan) : 1
        ;
      gridCtrl.register(x, y, rowspan, colspan, function (dim) {
        // console.log(x, y, rowspan, colspan, dim)
        for (var key in dim) {
          elem.css(key, dim[key])
        }
      });
    }
  }
})



.directive('bngBox', function () {
  return {
    restrict: 'E',
    template: `
      <div class='box box'>
        <div class='container' ng-transclude></div>
      </div>
    `,
    transclude: true
  };
})

.directive('bngVList', function ($compile, logger) {
  return {
    scope: true, // Use a scope that inherits from parent to access data
    restrict: 'A',
    compile: function (tElement, tAttrs, transclude) {
      var vRepeatAttr = tAttrs.bngVRepeat.split('in');
      var itemAlias = vRepeatAttr[0].replace(' ', '');

      var template = angular.element(`
        <div class="container bng-v-list">
          <div style="position: relative">
            <div style="position: absolute; width: 100%; box-sizing: border-box;">
            </div>
          </div>
        </div>`);

      var scroller = template[0].children[0];
      var vscreen  = scroller.children[0];

      var clone = angular.element(tElement.children()[0]);
      clone.attr('ng-repeat', `${itemAlias} in visibleItems`);
      clone.addClass('bng-v-list__item');

      angular.element(vscreen).append(clone);

      tElement.html('');
      tElement.append(template);

      var element = angular.element(tElement.children()[0]);

      function getVisible (firstItem, lastItem, data) {
        firstItem = firstItem < 0 ? 0 : firstItem;
        lastItem = lastItem > data.length - 1 ? data.length - 1 : lastItem;
        return data.slice(firstItem, lastItem + 1);
      }

      return {
        post: function (scope, rootElem, attrs) {
          var rowHeight
            , itemsPerRow
            , currentRows = [0, 0]
            ;

          scope.allData = scope.$eval(vRepeatAttr[1].replace(' ', '')) || [];
          scope.visibleItems = getVisible(0, 1, scope.allData);

          function handleScroll (forceRefresh) {
            // if possible show a row below visible and above visible as well, so gamepad nav can "scroll"
            var elemRect = element[0].getBoundingClientRect()
              , nrRowsNotShown = 1
              , scrollPos = element[0].scrollTop
              , firstRow = Math.floor(scrollPos / rowHeight) - nrRowsNotShown
              , lastRow = firstRow + Math.ceil(elemRect.height / rowHeight) + nrRowsNotShown
              , firstItem = firstRow * itemsPerRow
              , lastItem = (lastRow + 1) * itemsPerRow - 1
              ;

            if (forceRefresh || currentRows[0] !== firstRow || currentRows[1] !== lastRow) {
              currentRows = [firstRow, lastRow];
              // console.log(itemsPerRow)
              scope.$evalAsync(() => {
                // subtract the amount of not shown rows
                // subtract the part of a row we are not showing, since we are moving a container and the elems inside it are always at the top
                newScrollPos = scrollPos - (nrRowsNotShown * rowHeight) - (scrollPos % rowHeight)
                vscreen.style.transform = `translateY(${newScrollPos < 0 ? 0 : newScrollPos}px)`;
                // console.log('debug', `Rows: ${firstRow} - ${lastRow}, Items: ${firstItem} - ${lastItem}`);
                scope.visibleItems = getVisible(firstItem, lastItem, scope.allData);
                // console.log('debug', vscreen.style.transform, scrollPos, rowHeight);
              });
            }
          };

          function initHelper () {
            // TODO: check if both offsetWidth and getBoundingClientRect() caue a reflow or if one would be cheaper
            // for now we'll use clientRect, since it is more precise
            var item = vscreen.querySelector('.bng-v-list__item')
              , iRect = item.getBoundingClientRect()
              , vRect = vscreen.getBoundingClientRect()
              ;
            rowHeight = iRect.height;
            itemsPerRow = Math.floor(vRect.width / iRect.width)
            // console.debug(itemsPerRow, vRect.width, iRect.width)
            // console.log('rowHeight:', rowHeight, '#items/row:', itemsPerRow);
            var maxHeight = Math.ceil(scope.allData.length / itemsPerRow) * rowHeight + 'px';
            if (maxHeight !== scroller.style.height) {
              // console.debug(maxHeight, scroller.style.maxHeight)
              scroller.style.height = maxHeight;
            }
            handleScroll(true);
          };

          // if for some reason the data is loaded later etc.
          // or for some other reason the visibleitem list is empty
          // and thus resulting in no bng-v-list__item existing
          // mock one, so we can call init
          // otherwise we would never be able to apply new data that was available only after compilation
          function init () {
            if (scope.visibleItems.length === 0) {
              scope.visibleItems = [{}];
              setTimeout(initHelper);
            } else {
              initHelper();
            }
          }

          // it is important () => handleScroll() is used here instead of handlescroll,
          // since in the on scroll case handleScroll should be called without forceRefresh,
          // but if passed as before handlescroll will be passed the scroll event object
          // which will evaluate to truthy thus acting like forceRefresh = true
          // TODO: consider not binding this directly as it could get spammy
          element.on('scroll', () => handleScroll());

          scope.$watch(() => scope.$eval(vRepeatAttr[1].replace(' ', '')), (val) => {
            scope.allData = val || [];
            init();
          });

          window.onresize = function () {
            init();
          };
        }
      };
    }
  };
})



/**
 * @ngdoc directive
 * @name beamng.stuff:qrCode
 * @description A general-purpose, canvas-based QR code visualization directive
 */
.directive('qrCode', function () {
  return {
    template: '<div style="display: flex; justify-content: center; align-items: center"><canvas></canvas></div>',
    replace: true,
    scope: {
      data: '=',
      color: '@?'
    },
    link: function (scope, element, attrs) {
      var canvas = element[0].children[0]
        , ctx = canvas.getContext('2d')
        , size = Math.min(element[0].clientWidth, element[0].clientHeight) - 10
      ;

      canvas.width = size;
      canvas.height = size;

      scope.$watch('data', function (data) {
        ctx.clearRect(0, 0, size, size);
        if (!data) return;

        var gridSize = data.length
          , tileSize = Math.floor(size / gridSize) // round to avoid gaps between tiles
          , offset = Math.floor((size - tileSize * gridSize) / 2)// offset to center in canvas
        ;

        ctx.fillStyle = scope.color || 'black';

        for (var i=0; i<gridSize; i++) {
          for (var j=0; j<gridSize; j++) {
            if (scope.data[i][j] < 0) continue;
            ctx.fillRect(i*tileSize + offset, j*tileSize + offset, tileSize, tileSize);
          }
        }
      });
    }
  }
})


/**
 * @ngdoc filter
 * @name beamng.stuff:orderObjectBy
 * @description Helper-Filter to order objects in a list in ng-repeat, from here: {@link https://github.com/fmquaglia/ngOrderObjectBy}
**/
.filter('orderObjectBy', function() {
    /*
    The MIT License (MIT)

    Copyright (c) 2015 Fabricio Quagliariello

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
    */
    return function (items, field, reverse) {
      var filtered = [];
      angular.forEach(items, function(item) {
        filtered.push(item);
      });
      function index(obj, i) {
        return obj[i];
      }
      filtered.sort(function (a, b) {
        var comparator;
        var reducedA = field.split('.').reduce(index, a);
        var reducedB = field.split('.').reduce(index, b);
        if (reducedA === reducedB) {
          comparator = 0;
        } else {
          comparator = (reducedA > reducedB ? 1 : -1);
        }
        return comparator;
      });
      if (reverse) {
        filtered.reverse();
      }
      return filtered;
    };
  })

.filter('maxFractions', ['Utils', function (Utils) {
  return function (num, frac) {
    // first part is copied form angulars number filter
    return (num == null)
      ? num
      : Utils.roundDec(num, frac);
  };
}])

.filter('bbcode', ['$sce', 'Utils', function($sce, Utils) {
  return function (text) {
    return $sce.trustAsHtml(Utils.parseBBCode(args.msg));
  };
}])

.filter('numStr', ['Utils', function (Utils) {
  function putSpacesIn (str, sep, every) {
    if (str.length > every) {
      return putSpacesIn(str.slice(0, -every)) + sep + str.slice(-every);
    }
    return str
  }
  return function (num, sep, every) {
    every = every || 3;
    sep = sep || ' ';
    return (num == null)
      ? num
      : putSpacesIn(num.toString(), sep, every);
  };
}])

/**
 * @ngdoc filter
 * @name beamng.stuff:bytes
 * @description [ DESCRIPTION NEEDED ]
**/
.filter('bytes', function() {
  return function(bytes, precision) {
    if(!bytes) return '';
    if (isNaN(parseFloat(bytes)) || !isFinite(bytes)) {return '-';}
    if (typeof precision === 'undefined') {precision = 1;}
    var units = ['bytes', 'kB', 'MB', 'GB', 'TB', 'PB'], number = Math.floor(Math.log(bytes) / Math.log(1024));
    return (bytes / Math.pow(1024, Math.floor(number))).toFixed(precision) + ' ' + units[number];
  };
})

/**
 * @ngdoc filter
 * @name beamng.stuff:objectSize
 * @description Small filter used to get the number of keys from an object (found it in SO:25299436)
**/
.filter('objectSize', function(){
  return function(input){
    if(!angular.isObject(input)){
      return 0;
    }
    return Object.keys(input).length;
  };
})

/**
 * @ngdoc directive
 * @name beamng.stuff:bngAllClicks
 * @description Small directive to allow catching both single and double clicks.
 * No scope is created in order to avoid multidir error when used on top of other
 * directives.
 * IMPORTANT:
 * This is only designed for cases, where the single click doesn't prevent the dblclick for other cases use bngAllClicks (so no page navigation for example)
 *
 * @example
     <div bng-all-clicks single="ctrl.onSingle()" double="ctrl.onDouble()"></div>
 *
**/
.directive('bngAllClicksNoNav', function ($parse, logger) {
  return {
    restrict: 'A',
    scope: false,
    link: function (scope, element, attrs) {
      var maxDoubleClickDelayMS = 300 // allow 300 ms for double clicking
        , lastTileClick = null
        , single = $parse(attrs.single)
        , double = $parse(attrs.double)
      ;

      element.on('click', function () {
        // logger.log('clicked');
        var timestamp = new Date().getTime();

        if (lastTileClick !== null && timestamp - lastTileClick < maxDoubleClickDelayMS) {
          // double click
          scope.$evalAsync(function () {
            double(scope);
          });

        }
        lastTileClick = timestamp;
        // boring single click only
        scope.$evalAsync(function () {
          single(scope);
        });
      });
    }
  };
})

.directive('bngAllClicks', ['$parse', '$timeout', 'logger', function ($parse, $timeout, logger) {
  return {
    restrict: 'A',
    scope: false,
    link: function (scope, element, attrs) {
      var maxDoubleClickDelayMS = 300 // allow 300 ms for double clicking
        , lastTileClick = null
        , single = $parse(attrs.single)
        , double = $parse(attrs.double)
        , timeoutPromise
      ;

      element.on('click', function () {
        // logger.log('clicked');
        var timestamp = new Date().getTime();

        if (timeoutPromise !== undefined) {
          $timeout.cancel(timeoutPromise);
          timeoutPromise = undefined;
        }
        if (lastTileClick !== null && timestamp - lastTileClick < maxDoubleClickDelayMS) {
          scope.$evalAsync(function () {
            double(scope);
          });
        } else {
          timeoutPromise = $timeout(function () {
            scope.$evalAsync(function () {
              single(scope);
            });
          }, maxDoubleClickDelayMS);
        }
        lastTileClick = timestamp;
      });
    }
  };
}])

.directive('ngRightClick', ['$parse', function($parse) {
  return function(scope, element, attrs) {
    var fn = $parse(attrs.ngRightClick);
    element.bind('contextmenu', function(event) {
      scope.$apply(function() {
        event.preventDefault();
        fn(scope, {$event: event});
      });
    });
  };
}])


//Thanks to: http://stackoverflow.com/questions/30207272/capitalize-the-first-letter-of-string-in-angularjs
.filter('capitalize', function() {
    return function(input) {
      return (!!input) ? input.charAt(0).toUpperCase() + input.substr(1).toLowerCase() : '';
    };
})


.service('SimpleStateNav', ['$rootScope', '$state', function ($rootScope, $state) {
  var list = []
    , index = -1
    , navCalled = false
    , maxItems = 5
  ;

  $rootScope.$on('$stateChangeSuccess', function (ev, toState, toStateParams) {
    if (!navCalled) {
      if (index < list.length - 1) {
        list = list.slice(0, index + 1);
      }

      list.push({name: toState.name, params: toStateParams});

      if (list.length > maxItems) {
        list.shift();
      } else {
        index += 1;
      }
    } else {
      navCalled = false;
    }
  });

  return {
    back: () => {
      if (index > 0) {
        navCalled = true;
        index -= 1;
        $state.go(list[index].name, list[index].params);
      } else {
        console.error('Unable to go back: I don\'t remember the state before this one. Sorry!');
      }
    },
    forward: () => {
      if (index < list.length - 1) {
        navCalled = true;
        index += 1;
        $state.go(list[index].name, list[index].params);
      } else {
        console.error('Unable to go forward: No future state known. The choice is yours!');
      }
    },
    // getListSimple: () => list.map((elem) => elem.name),
    // getList: () => list,
  };
}])

/**
 * @ngdoc service
 * @name beamng.stuff.service:UiUnits
 * @description Small utility to convert values from raw input coming from streams to game's metric/imperial units
 */

/**
 * Please use SI units and terms where possible (i.e. Length instead of Distance)
 * - Do not add scaling in there (kilo, Mega, Giga, etc). The engine should perform these on the fly where fit and required.
 * - The settings should describe the system it uses: metric/imperial
 */
.service('UiUnits', ['$rootScope', 'bngApi', 'Utils', 'logger', function ($rootScope, bngApi, Utils, logger) {
  uiUnits = {
  'uiUnitLength': 'metric',
  'uiUnitTemperature': 'f',
  'uiUnitWeight': 'lb',
  'uiUnitConsumptionRate': 'imperial',
  'uiUnitTorque': 'imperial',
  'uiUnitEnergy': 'imperial',
  'uiUnitDate': 'us',
  'uiUnitPower': 'bhp',
  'uiUnitVolume': 'gal',
  'uiUnitPressure': 'psi'
};

  var mapping = {
    'length': 'uiUnitLength',
    'speed': 'uiUnitLength',
    'temperature': 'uiUnitTemperature',
    'weight': 'uiUnitWeight',
    'consumptionRate': 'uiUnitConsumptionRate',
    'torque': 'uiUnitTorque',
    'energy': 'uiUnitEnergy',
    'date': 'uiUnitDate',
    'power': 'uiUnitPower',
    'volume': 'uiUnitVolume',
    'pressure': 'uiUnitPressure'
  };
  $rootScope.$on('SettingsChanged', function (event, data) {
    for (var i in uiUnits) {
      if (data.values[i] !== undefined) {
        uiUnits[i] = data.values[i];
      }
    }
  });


  bngApi.engineLua('settings.requestState()');

  var service = {

    /**
     * @ngdoc method
     * @methodOf beamng.stuff.service:UiUnits
     * @name buildString
     * @param {String} Name of Ui.Units function to use for conversion
     * @param {Number} value to convert
     * @param {Number} numDec number of Decimals to use
     * @param {('metric' | 'imperial')} system System to convert to. If omitted uses the current ui unit system.
     * @description returns a string with value and unit to be directly included in html
     */
    buildString: function (func, val, numDecs, system) {
      if (func === 'division' || func === 'buildString' || func === 'date' || typeof service[func] !== 'function') {
        logger.UiUnits.log(arguments);
        throw new Error('Cannot use this function to build a string');
      }

      if (mapping[func] !== undefined && system === undefined) {
        system = uiUnits[mapping[func]];
      }

      var helper = service[func](val, system);
      if (helper !== null) {
        if(typeof helper.val == 'string') {
          return helper.val;
        } else if(typeof helper.val == 'number')  {
          return helper.val.toFixed(numDecs) + ' ' + helper.unit;
        } else {
          logger.UiUnits.log(arguments);
          logger.UiUnits.error('got invalid reply');
          return '';
        }
      } else {
        logger.UiUnits.log(arguments);
        logger.UiUnits.error('got null');
        return '';
      }
    },

    division: function (func1, func2, val1, val2, numDecs, system1, system2) {
      if ((func1 === 'division' || func1 === 'weightPower' || func1 === 'buildString' || func1 === 'date' || typeof service[func1] !== 'function'
        && func2 === 'division' || func2 === 'weightPower' || func2 === 'buildString' || func2 === 'date' || typeof service[func2] !== 'function')) {
        logger.UiUnits.log(arguments);
        throw new Error('Cannot use these functions');
      }

      var helper1 = service[func1](val1, system1);
      var helper2 = service[func2](val2, system2);

      if (helper1 !== null && helper2 !== null) {
        var newVal = helper1.val / helper2.val;
        return {
          val: (numDecs !== undefined ? Utils.roundDec(newVal) : newVal),
          unit: `${helper1.unit}/${helper2.unit}`
        };
      } else {
        logger.UiUnits.log(arguments);
        logger.UiUnits.error('got null');
        return null;
      }
    },

    weightPower: function(x) {
      var helper = service.division('weight', 'power', 1, 1);

      if (helper !== null) {
        return {
          val: helper.val * x,
          unit: helper.unit
        };
      } else {
        return null;
      }
    },


    /**
     * @ngdoc method
     * @methodOf beamng.stuff.service:UiUnits
     * @name length
     * @param {Number} x length in meters.
     * @param {('metric' | 'imperial')} system System to convert to. If omitted uses the current ui unit system.
     * @description Converts length to metric or imperial
     */
    length: function (meters, system) {
      if (system === undefined) {
        system = uiUnits.uiUnitLength;
      }

      if(system == 'metric') {
        if(meters < 0.01) return { val: meters * 1000, unit: 'mm'};
        else if(meters < 1) return { val: meters * 100, unit: 'cm'};
        else if(meters < 1000) return { val: meters, unit: 'm'};
        else return { val: meters * 0.001, unit: 'km'};

      } else if (system == 'imperial') {
        var yd = meters * 1.0936;
        if(yd < 1) return { val: yd * 36, unit: 'in'};
        else if(yd < 3) return { val: yd * 3, unit: 'ft'};
        else if(yd < 1760) return { val: yd, unit: 'yd'};
        else return { val: yd * 0.000568182, unit: 'mi'};
      }
      return null;
    },

    area: function (squareMeters, system) {
      if (system === undefined) {
        system = uiUnits.uiUnitLength;
      }

      if(system == 'metric') {
        if(squareMeters < 1000) return { val: squareMeters, unit: 'sq m'};
        else return { val: squareMeters * 0.001 * 0.001, unit: ' sq km'};
      } else if (system == 'imperial') {
        var sqrYards = squareMeters * 1.0936 * 1.0936;
        if(sqrYards < 1760) return { val: sqrYards, unit: 'sq yd'};
        else return { val: sqrYards * 0.000568182 * 0.000568182, unit: 'sq mi'};
      }
      return null;
    },


    /**
     * @ngdoc method
     * @methodOf beamng.stuff.service:UiUnits
     * @name temperature
     * @param {Number} x temperature in Kelvin.
     * @param {('metric' | 'imperial')} system System to convert to. If omitted uses the current ui unit system.
     * @description Converts temperature Celsius to metric (Celsius) or imperial (Fahrenheit) system.
     */
    temperature: function (x, system) {
      if (system === undefined) {
        system = uiUnits.uiUnitTemperature;
      }
      switch (system) {
        case 'c': return { val: x,            unit: '°C' };
        case 'f': return { val: x * 1.8 + 32, unit: '°F' };
        case 'k': return { val: x + 273.15, unit: 'K' };
        default: return null;
      }
    },

    volume: function (x, system) {
      if (system === undefined) {
        system = uiUnits.uiUnitVolume;
      }
      switch (system) {
        case 'l': return { val: x,            unit: 'L' };
        case 'gal': return { val: x * 0.2642, unit: 'gal' };
        default: return null;
      }
    },

    pressure: function (x, system) {
      if (system === undefined) {
        system = uiUnits.uiUnitPressure;
      }
      switch (system) {
        case 'inHg': return { val: x * 0.2953, unit: 'in.Hg' };
        case 'bar': return { val: x * 0.01, unit: 'Bar' };
        case 'psi': return { val: x * 0.145038, unit: 'PSI' };
        case 'kPa': return { val: x, unit: 'kPa' };
        default: return null;
      }
    },


    /**
     * @ngdoc method
     * @methodOf beamng.stuff.service:UiUnits
     * @name weight
     * @param {Number} x weight in kilograms.
     * @param {('metric' | 'imperial')} system System to convert to. If omitted uses the current ui unit system.
     * @description Converts weight from kilograms to metric (kilograms) or imperial (pounds) system.
     */
    weight: function (x, system) {
      if (system === undefined) {
        system = uiUnits.uiUnitWeight;
      }
      switch (system) {
        case 'kg':    return {val: x,              unit: 'kg'  };
        case 'lb':  return {val: 2.20462262 * x, unit: 'lbs' };
        default: return null;
      }
    },

    /**
     * @ngdoc method
     * @methodOf beamng.stuff.service:UiUnits
     * @name consumptionRate
     * @param {Number} x fuel consumption rate in L/m.
     * @param {('metric' | 'imperial')} system System to convert to. If omitted uses the current ui unit system.
     * @description Converts fuel consumption rate from L/m to metric (liters per 100km) or imperial (miles per gallon) system.
     */
    consumptionRate: function (x, system) {
      if (system === undefined) {
        system = uiUnits.uiUnitConsumptionRate;
      }
      switch (system) {
        case 'metric':   return {val: ( 1e+5 * x > 50000 ) ? 'n/a' : 1e+5 * x,       unit: 'L/100km' };
        case 'imperial': return {val: (x === 0 ? 0 : 235 * 1e-5 / x), unit: 'MPG'     };
        default: return null;
      }
    },

    /**
     * @ngdoc method
     * @methodOf beamng.stuff.service:UiUnits
     * @name speed
     * @param {Number} x speed in meters per second.
     * @param {('metric' | 'imperial')} system System to convert to. If omitted uses the current ui unit system.
     * @description Converts speed from meters per second to metric (kilometers per hour) or imperial (miles per hour) system.
     */
    speed: function (x, system) {
      if (system === undefined) {
        system = uiUnits.uiUnitLength;
      }
      switch (system) {
        case 'metric':   return { val: 3.6 * x,        unit: 'km/h' };
        case 'imperial': return { val: 2.23693629 * x, unit: 'mph'  };
        default: return null;
      }
    },

    /**
     * @ngdoc method
     * @methodOf beamng.stuff.service:UiUnits
     * @name power
     * @param {Number} x power in metric hp.
     * @param {('metric' | 'imperial')} system System to convert to. If omitted uses the current ui unit system.
     * @description Converts power from metric hp to metric (metric hp) or imperial (imperial hp) system.
     */
    power: function (x, system) {
     if (system === undefined) {
        system = uiUnits.uiUnitPower;
      }
      switch (system) {
        case 'kw':   return { val: 0.735499 * x, unit: 'kW' };
        case 'hp':   return { val: x, unit: 'PS' };
        case 'bhp': return { val: 0.98632 * x, unit: 'bhp' };
        default: return null;
      }
    },

    /**
     * @ngdoc method
     * @methodOf beamng.stuff.service:UiUnits
     * @name torque
     * @param {Number} x torque in Nm
     * @param {('metric' | 'imperial')} system System to convert to. If omitted uses the current ui unit system.
     * @description Converts torque from Nm to metric (Nm) or imperial (lb * ft) system.
     */
    torque: function (x, system) {
      if (system === undefined) {
        system = uiUnits.uiUnitTorque;
      }

      switch (system) {
        case 'metric':
          system = 'kg';
          break;
        case 'imperial':
          system = 'lb';
          break;
      }

      switch (system) {
        case 'kg':   return {val: x,              unit: 'Nm'   };
        case 'lb': return {val: 0.7375621495*x, unit: 'lb-ft'};
        default: return null;
      }
    },

    /**
     * @ngdoc method
     * @methodOf beamng.stuff.service:UiUnits
    */
    energy: function (x, system) {
      if (system === undefined) {
        system = uiUnits.uiUnitEnergy;
      } else {
        switch (system) {
          case 'metric':
            system = 'j';
            break;
          case 'imperial':
            system = 'ft lb';
            break;
          default:
        }
      }
      switch (system) {
        case 'j':   return {val: x,              unit: 'J'   };
        case 'ft lb': return {val: 0.7375621495*x, unit: 'ft lb'};
        default: return null;
      }
    },
    /**
     * @ngdoc method
     * @methodOf beamng.stuff.service:UiUnits
      */
    date: function (x, system) {
      if (system === undefined) {
        system = uiUnits.uiUnitDate;
      }
      switch (system) {
        case 'ger':   return x.toLocaleDateString('de-DE');
        case 'uk': return x.toLocaleDateString('en-GB');
        case 'us': return x.toLocaleDateString('en-US');
        default: return null;
      }
    }
  };

  // backward compatibility:
  service.distance = service.length;

  return service;
}])

// little filter to convert units to the user's units
.filter('unit', ['UiUnits', function(UiUnits) {
  return function(num, type, numDec) {
    return UiUnits.buildString(type, num, numDec);
  };
}])

.directive('bngTranslate', ['$compile', '$filter', 'Utils', function ($compile, $filter, Utils) {
  return {
    restrict: 'A',
    link: function (scope, element, attrs) {
      // Get the translation

      attrs.$observe('bngTranslate', translate);

      var lastAppended;

      function translate (val) {
        if (lastAppended !== undefined) {
          lastAppended.html('');
        }

        var str;

        try {
          var translationObj = JSON.parse(val);
          if (translationObj.fallback) {
            var val =  $filter('translate')(translationObj.txt, translationObj.context)
            if (val === translationObj.txt) {
              str = translationObj.fallback;
            } else {
              str = val;
            }
          } else {
            str = $filter('translate')(translationObj.txt, translationObj.context);
          }
        } catch (err) {
          str = $filter('translate')(val);
        }
        var html = Utils.parseBBCode(str);

        lastAppended = element.append( $compile(`<div>${html}</div>`)(scope).contents());
      }
    }
  };
}])

/**
 * @ngdoc service
 * @name beamng.stuff:Utils
 * @description A set of general-purpose functions that wouldn't fit in a more specific-usage service, meant to be shared
 * throughout the game.
 */
.factory('Utils', ['$rootScope', 'bngApi', function ($rootScope, bngApi) {
  return {
    roundDec: function (val, num) {
      num = num || 0;
      if (val !== undefined) {
        var help = Math.pow(10, num);
        return Math.round(val * help) / help;
      } else {
        throw new Error ('The function at least needs a value ');
      }
    },

    roundDecStr: function (val, num) {
      var r = this.roundDec(val, num).toString();
      var h = r.split('.')
      h[1] = h[1] || ''
      if (h[1].length !== num) {
        var t = '';
        for (var i = 0; i < num; i += 1) {
          t += '0';
        }
        r = h[0] + '.' + (h[1] + t).slice(0, num);
      }
      return r;
    },

    round: function (val, step) {
      step = step || 1;
      if (val !== undefined) {
        return Math.round(val / step) * step;
      } else {
        throw new Error ('The function at least needs a value ');
      }
    },

    waitForCefAndAngular: function (func) {
      // wait for angulars digest loop
      setTimeout(() =>
        // wait for digest to be applied to dom
        window.requestAnimationFrame(() =>
          setTimeout(() =>
            // be really sure browser has rendered
            window.requestAnimationFrame(() =>
              // just in case (maybe an images takes longer or smth similar)
              setTimeout(func, 100)
            )
          ), 100
        ), 100
      );
    },

    rainbow: function (numOfSteps, step) {
      // This function generates vibrant, "evenly spaced" colors (i.e. no clustering). This is ideal for creating easily distinguishable vibrant markers in Google Maps and other apps.
      // Adam Cole, 2011-Sept-14
      // HSV to RBG adapted from: http://mjijackson.com/2008/02/rgb-to-hsl-and-rgb-to-hsv-color-model-conversion-algorithms-in-javascript
      var r, g, b;
      var h = step / numOfSteps;
      var i = ~~(h * 6);
      var f = h * 6 - i;
      var q = 1 - f;
      switch(i % 6){
        case 0: r = 1; g = f; b = 0; break;
        case 1: r = q; g = 1; b = 0; break;
        case 2: r = 0; g = 1; b = f; break;
        case 3: r = 0; g = q; b = 1; break;
        case 4: r = f; g = 0; b = 1; break;
        case 5: r = 1; g = 0; b = q; break;
      }
      //var c = "#" + ("00" + (~ ~(r * 255)).toString(16)).slice(-2) + ("00" + (~ ~(g * 255)).toString(16)).slice(-2) + ("00" + (~ ~(b * 255)).toString(16)).slice(-2);
      return [r, g, b];
    },

    /**
     * @ngdoc method
     * @name parseBBCode
     * @methodOf beamng.stuff:Utils
     * @param {string} text The text to be parsed.
     * @description Surprise, this parses BBCode! Like for example the one returned from Steams API.
     */
    parseBBCode: function (text) {

      if (typeof text !== "string") {
        text = '';
      }

      function parseNested( txt, re, template)
      {
          while(txt.search(re) !== -1) {
              txt = txt.replace(re, template);
          }
          return txt;
      }

      // no more <i class="material-icons">link</i> - we do not support that stuff

      text = text.replace(/\[url=https?:\/\/([^\s\]]+)\](.*?(?=\[\/url\]))\[\/url\]/gi, '<a href="http-external://$1">$2</a>');
      text = text.replace(/\[url='https?:\/\/([^\s\]]+)'\](.*?(?=\[\/url\]))\[\/url\]/gi, '<a href="http-external://$1">$2</a>');
      text = text.replace(/\[forumurl=https?:\/\/([^\s\]]+)\](\S*?(?=\[\/forumurl\]))\[\/forumurl\]/gi, '<a href="http-external://$1">$2</a>');
      text = text.replace(/\[url\]https?:\/\/(.*?(?=\[\/url\]))\[\/url\]/gi, '<a href="http-external://$1">$1</a>');
      text = text.replace(/\[url=([^\s\]]+)\](.*?(?=\[\/url\]))\[\/url\]/gi, '<a href="$1">$2</a>');

      text = text.replace(/\[ico=([^\s\]]+)\s*\](.*?(?=\[\/ico\]))\[\/ico\]/gi, '<img style="max-width: 98%;" src="images/icons/$1.png">$2</img>');
      text = text.replace(/\[h(\d)\](.*?(?=\[\/h\d\]))\[\/h\d\]/gi, '<h$1>$2</h$1>');
      text = text.replace(/\[img\]\s*?(\S*?(?=\[\/img\]))\[\/img\]/gi, '<img style="max-width: 98%;" src="$1"></img>');
      // this only works if before the plain text link is at least one whitespace character
      text = text.replace(/\shttp(s|):\/\/(\S*)/gi, '<a href="http-external://$2">http$1://$2</a>');
      // this is the [] [/] version
      text = text.replace(/\[action=(.*?)\](.*?)/gi, '<binding action="$1" style="margin: 0 4px"></binding>');
      // version with no closing bracket:
      text = text.replace(/\[action=(.*?)\]/gi, '<binding action="$1"></binding>');
      text = text.replace(/\[list=\d+\](.*?(?=\[\/list\]))\[\/list\]/gi, '<ol>$1</ol>');
      text = text.replace(/\[list\]/gi, '<ul>');
      text = text.replace(/\[\/list\]/gi, '</ul>');
      text = text.replace(/\[olist\]/gi, '<ol>');
      text = text.replace(/\[\/olist\]/gi, '</ol>');
      text = text.replace(/\[\*\]\s*?((.|\s)*?(?=\[\*\]|\<\/ul\>|\<\/ol\>))/gim, '<li>$1</li>');
      text = parseNested(text, /\[b\](.*?(?=\[\/b\]))\[\/b\]/gi, '<b>$1</b>');
      text = parseNested(text, /\[u\](.*?(?=\[\/u\]))\[\/u\]/gi, '<u>$1</u>');
      text = parseNested(text, /\[s\](.*?(?=\[\/s\]))\[\/s\]/gi, '<s>$1</s>');
      text = parseNested(text, /\[i\](.*?(?=\[\/i\]))\[\/i\]/gi, '<i>$1</i>');
      text = text.replace(/\[strike\](.*?(?=\[\/strike\]))\[\/strike\]/gi, '<s>$1</s>');
      text = text.replace(/\[ico=([^\s\]]+)\s*\]/gi, '<img style="max-width: 98%;" class="ico" src="images/icons/$1.png"/>');
      text = text.replace(/\[code\](.*?(?=\[\/code\]))\[\/code\]/gi, '<span class="bbcode-pre">$1</span>');
      text = text.replace(/\[br\]/gi, '<br />');
      text = text.replace(/\n\n/gi, '<br/><br/>');
      text = text.replace(/\n/gi, '<br/>');
      text = text.replace(/\[attach=?f?u?l?l?\](.*?(?=\[\/attach\]))\[\/attach\]/gi, '<img style="max-width: 98%;" src="https://www.beamng.com/attachments/.$1/">');
      text = text.replace(/\[USER=([\d]+)\](.*?(?=\[\/USER\]))\[\/USER\]/gi, '<a href="http-external://www.beamng.com/members/.$1/">$2</a>');
      text = text.replace(/\[MEDIA=youtube\](.*?(?=\[\/MEDIA\]))\[\/MEDIA\]/gi, '<div style="position: relative; width: 100%; height: 0; padding-bottom: 56.25%;"><iframe style="position: absolute;top: 0;left: 0;width: 100%;height: 100%;" src="https://www.youtube-nocookie.com/embed/$1?autoplay=0&controls=1&disablekb=1&fs=0&modestbranding=1&rel=0&showinfo=0" frameborder="0" allowfullscreen></iframe></div>'); //do not work
      text = text.replace(/\[MEDIA=beamng\](.*?(?=\[\/MEDIA\]))\[\/MEDIA\]/gi, '<img style="max-width: 98%;" src="https://media.beamng.com/$1/">'); //do not work
      //text = text.replace(/\[COLOR=([a-z0-9#\(\)]+)\]([^[]*(?:\[(?!COLOR=[a-z0-9#\(\)]+\]|\/COLOR\])[^[]*)*)\[\/COLOR\]/gi, '<span style=\'color:$1;\'>$2</span>');
      //text = text.replace(/\[size=(\d+)\]([^[]*(?:\[(?!size=\d+\]|\/size\])[^[]*)*)\[\/size\]/gi, '<span style="font-size: calc($1*3px+6);">$2</span>');
      text = parseNested(text, /\[size=(\d+)\]([^[]*(?:\[(?!size=\d+\]|\/size\])[^[]*)*)\[\/size\]/ig , '<span style="font-size: calc($1*3px+6);">$2</span>');
      text = parseNested(text, /\[COLOR=([a-z0-9\#\, \'\"\(\)]+)\]([^[]*(?:\[(?!COLOR=[a-z0-9#\(\)]+\]|\/COLOR\])[^[]*)*)\[\/COLOR\]/gi, '<span style=\'color:$1;\'>$2</span>');
      text = text.replace(/\[hr\]\[\/hr\]/gi, '<hr>');
      text = text.replace(/\[spoiler=([^\]]+)\](.*?(?=\[\/spoiler\]))\[\/spoiler\]/gi, '<div style="margin-bottom: 2px;"> <b>Spoiler: $1 </b><input value="Show" style="margin: 0px; padding: 0px; width: 60px; font-size: 10px;" onclick="if(this.parentNode.getElementsByTagName(\'div\')[0].getElementsByTagName(\'div\')[0].style.display != \'inline\') { this.parentNode.getElementsByTagName(\'div\')[0].getElementsByTagName(\'div\')[0].style.display = \'inline\'; this.value = \'Hide\'; } else { this.parentNode.getElementsByTagName(\'div\')[0].getElementsByTagName(\'div\')[0].style.display = \'none\'; this.value=\'Show\'; }" type="button"> <br> <div style="border: 1px inset; padding: 6px;"> <div style="display: none;">$2</div> </div> </div> ');
      text = text.replace(/\[spoiler\](.*?(?=\[\/spoiler\]))\[\/spoiler\]/gi, '<div style="margin-bottom: 2px;"> <b>Spoiler </b><input value="Show" style="margin: 0px; padding: 0px; width: 60px; font-size: 10px;" onclick="if(this.parentNode.getElementsByTagName(\'div\')[0].getElementsByTagName(\'div\')[0].style.display != \'inline\') { this.parentNode.getElementsByTagName(\'div\')[0].getElementsByTagName(\'div\')[0].style.display = \'inline\'; this.value = \'Hide\'; } else { this.parentNode.getElementsByTagName(\'div\')[0].getElementsByTagName(\'div\')[0].style.display = \'none\'; this.value=\'Show\'; }" type="button"> <br> <div style="border: 1px inset; padding: 6px;"> <div style="display: none;">$1</div> </div> </div> ');
      text = parseNested(text, /\[font=([^\]]+)\](.*?(?=\[\/font\]))\[\/font\]/gi, '<span style="family: $1;">$2</span>');
      text = parseNested(text, /\[left\](.*?(?=\[\/left\]))\[\/left\]/gi, '<p style="text-align: left;">$1</p>');
      text = parseNested(text, /\[center\](.*?(?=\[\/center\]))\[\/center\]/gi, '<p style="text-align: center;">$1</p>');
      text = parseNested(text, /\[right\](.*?(?=\[\/right\]))\[\/right\]/gi, '<p style="text-align: right;">$1</p>');
      return text;
    },


    /**
     * @ngdoc method
     * @name deepFreeze
     * @methodOf beamng.stuff:Utils
     * @description
     * From mdn: https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Object/freeze
     * To make obj fully immutable, freeze each object in obj.
     *  To do so, we use this function.
     */
    deepFreeze: function _deepfreeeze_ (obj) {

      // Retrieve the property names defined on obj
      var propNames = Object.getOwnPropertyNames(obj);

      // Freeze properties before freezing self
      propNames.forEach(function(name) {
        var prop = obj[name];

        // Freeze prop if it is an object
        if (typeof prop == 'object' && prop !== null)
          _deepfreeeze_(prop);
      });

      // Freeze self (no-op if already frozen)
      return Object.freeze(obj);
    },

    /**
     * @ngdoc method
     * @name dateFromUnixTs
     * @methodOf beamng.stuff:Utils
     * @param {number} seconds A Unix timestamp (seconds since Jan 01 1970)
     *
     * @description Converts unix timestamp to Date format
     */
    dateFromUnixTs: function (seconds) {
      return new Date(seconds * 1000);
    },

    random: function (lower, upper, int) {
      lower = lower || 0;
      upper = (upper === undefined ? 1 : upper);
      if (int !== undefined && int) {
        return Math.floor(Math.random() * (upper - lower + 1)) + lower
      } else {
        return Math.random() * (upper - lower) + lower;
      }
    }
  };
}]);




//non enumerable sum function for arrays
Object.defineProperty(Array.prototype, 'sum', {
  value: function () {
    return this.reduce(function(pv, cv) { return pv + cv; }, 0);
  }
});

Object.defineProperty(Array.prototype, 'add', {
  value: function (arr) {
    return this.concat.apply(this, arr);
  }
});

// Simulates the press of a key for a specific target
Object.defineProperty(Element.prototype, 'dispatchKey', {
  value: function dispatchKey (key) {
    // key should be ther number of the keycode one wants to dispatch
    if (typeof key !== 'number') {
      throw new Error('Invalid key');
    }

    // Default to document
    target = this || document;

    // actual event to be dipatched
    var ev = document.createEvent('KeyboardEvent');

    // Hack Idea from: http://stackoverflow.com/questions/10455626/keydown-simulation-in-chrome-fires-normally-but-not-the-correct-key/10520017#10520017
    // Basically what this does is it overwrites the inhereted in cef buggy and not working property keyCode
    Object.defineProperty(ev, 'keyCode', {
      get : function() {
        return this.keyCodeVal;
      }
    });

    // Also tested with keypress, but apparently that does not work in cef for arrow keys but only most other ones
    ev.initKeyboardEvent('keydown', true, true);

    // Used for the getter of the keyCode property
    // Stored as ownproperty so the function execution does not leave an open closure
    ev.keyCodeVal = key;

    // Dispatch keypress and return if it worked
    return target.dispatchEvent(ev);
  }

});






// idea from: http://stackoverflow.com/questions/1584370/how-to-merge-two-arrays-in-javascript-and-de-duplicate-items
Object.defineProperty(Array.prototype, 'unique', {
  value: function () {
    return this.filter((item, pos) => this.indexOf(item) === pos);
  }
});

Object.defineProperty(Array.prototype, 'last', {
  value: function () {
    return this[this.length - 1];
  }
});

// convert array like objects to arrays.
// Normaly you would not have to use this. Rather make get array right in the first place
Object.defineProperty(Object.prototype, 'convertToArray', {
  value: function () {
    return Object.keys(this).map((key) => this[key]);
  }
});

Object.defineProperty(Object.prototype, 'isEmpty', {
  value: function () {
    return Object.keys(this).length === 0;
  }
});

function nop () {}

window.print = nop;



function fnCallCounter (fn) {
  ctr = 0
  interval = 1000
  i = setInterval(() => {
    console.log(ctr, interval)
    ctr = 0
  }, interval)
  return {intervalHandel: i, newFn: function () {
      ctr += 1
      fn.apply(undefined, arguments);
    }};

}