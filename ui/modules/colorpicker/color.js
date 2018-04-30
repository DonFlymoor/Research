(function() {
'use strict';

angular.module('beamng.color')

.service('convertColor', ['capitalizeFilter', function (capitalizeFilter) {

  /**
   * Converts an RGB color value to HSL. Conversion formula
   * adapted from http://en.wikipedia.org/wiki/HSL_color_space.
   * Assumes r, g, and b are contained in the set [0, 255] and
   * returns h, s, and l in the set [0, 1].
   *
   * @param   Number  r       The red color value
   * @param   Number  g       The green color value
   * @param   Number  b       The blue color value
   * @return  Array           The HSL representation
   **/
  function toHsl(rgb) {
    rgb = rgb.map((elem) => elem / 255);
    var r = rgb[0], g = rgb[1], b = rgb[2];
    var max = Math.max(r, g, b), min = Math.min(r, g, b);
    var h, s, l = (max + min) / 2;

    if (max == min) {
      h = s = 0; // achromatic
    } else {
      var d = max - min;
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
      switch (max){
        case r: h = (g - b) / d + (g < b ? 6 : 0); break;
        case g: h = (b - r) / d + 2; break;
        case b: h = (r - g) / d + 4; break;
      }
      h /= 6;
    }

    return [h, s, l];
  }

  /**
   * Converts an HSL color value to RGB. Conversion formula
   * adapted from http://en.wikipedia.org/wiki/HSL_color_space.
   * Assumes h, s, and l are contained in the set [0, 1] and
   * returns r, g, and b in the set [0, 255].
   *
   * @param   Number  h       The hue
   * @param   Number  s       The saturation
   * @param   Number  l       The lightness
   * @return  Array           The RGB representation
   **/
  function fromHsl(hsl) {
    var r, g, b;

    if (hsl[1] === 0) {
      r = g = b = hsl[2]; // achromatic
    } else {
      var hue2rgb = function hue2rgb(p, q, t) {
        if (t < 0) {t += 1;}
        if (t > 1) {t -= 1;}
        if (t < 1 / 6) {return p + (q - p) * 6 * t;}
        if (t < 1 / 2) {return q;}
        if (t < 2 / 3) {return p + (q - p) * (2 / 3 - t) * 6;}
        return p;
      };

      var q = hsl[2] < 0.5 ? hsl[2] * (1 + hsl[1]) : hsl[2] + hsl[1] - hsl[2] * hsl[1];
      var p = 2 * hsl[2] - q;
      r = hue2rgb(p, q, hsl[0] + 1 / 3);
      g = hue2rgb(p, q, hsl[0]);
      b = hue2rgb(p, q, hsl[0] - 1 / 3);
    }
    return [r, g, b].map((elem) => Math.round(elem * 255));
  }

  function push(arr, elem) {
    arr.push(elem);
    return arr;
  }

  function pop(arr) {
    arr.pop();
    return arr;
  }


  var functions = {
    readRgb: (rgb) => push(rgb, 0.5),
    readRgba: (rgba) => rgba,
    readHsl: (hsl) => functions.readRgb(fromHsl(hsl)),
    readHsla: (hsla) => push(fromHsl(hsla), hsla[3]),

    writeRgb: (rgba) => pop(rgba),
    writeRgba: (rgba) => rgba,
    writeHsl: (rgba) => toHsl(pop(rgba)),
    writeHsla: (rgba) => push(toHsl(rgba), rgba[3]),

    convert: (a, b, val) => functions['write' + capitalizeFilter(b)](functions['read' + capitalizeFilter(a)](val))
  };

  return functions;
}])

.directive('colorPicker', [function () {
  var color = [];

  return {
    restrict: 'E',
    template: `

    `,
    scope: {
    },
    controller: function ($scope, $element, $attrs) {
      var vm = this
        , color = [];


      vm.selectPreset = function (rgba) {
        color = rgba;
      };
    }
  };
}])

.directive('presets', [function () {
   return {
    restrict: 'E',
    require: '^^colorPicker',
    template: `

    `,
    scope: {
      colors: '=',
      car: '='
    },
    link: function(scope, iElement, iAttrs, colorPicker) {
      scope.userPrestes = [];
      scope.carPresets = [];

      scope.presets = () => scope.userPrestes.concat(scope.carPresets);

      scope.selectPreset = colorPicker.selectPreset;

      scope.addPreset = function () {

      };

      scope.$watch('colors', () => scope.carPresets = scope.colors);

      $scope.$on('SettingsChanged', function (event, data) {
        var help = data.values.userColorPresets;
        if (help !== undefined) {
          $scope.userPrestes = JSON.parse(help.replace(/'/g, '\"'));
        } else {
          $scope.userPrestes = [];
        }
      });

      bngApi.engineLua('settings.requestState()');


      function getVehicleColors () {
        if (scope.colors !== undefined) {
          bngApi.engineLua('core_vehicles.getCurrentVehicleDetails()', (data) => {
            if (model !== undefined && model.colors !== undefined) {
              $scope.$apply(() => {
                scope.carPresets = model.colors;
              });
            }
          });
        } 
      }

      getVehicleColors();

      $scope.$on('VehicleChange', getVehicleColors);
    }
  };
}])



})();

angular.module('beamng.stuff')

.directive('ngColor', ['$log', 'bngApi', function($log, bngApi) {
  return {
    restrict: 'E',
    require: 'ngModel',
    scope: {
      initValue: '=ngModel',
      showText: '@?', // to disable add show-text="false" to the directive
      showPresets: '@?',
      presetsEditable: '@?',
      showAlpha: '@?',
      showMain: '@?',
      preCol: '@?', // to Use add pre-col="{{object with key value and value as rgb string}}"
      width: '@?',
      showPreview: '@?'
      // height: '@'
    },
    templateUrl: 'modules/colorpicker/color.html',
    link: function($scope, iElement, iAttrs, ngModelController) {
      $scope.$watch(
        function(scope) {return scope.initValue;},
        init
      );

      $scope.updateWidth = function() {
        $scope.w = ($scope.width ? Number($scope.width) : iElement[0].children[1].clientWidth-10);
        $scope.height = ($scope.w ? $scope.w / 1.75 : 200);
      };

      $scope.$watch(
        function () {return iElement[0].children[1].clientWidth;},
        function () {
          // console.log(iElement[0].children[1].clientWidth);
          $scope.updateWidth();
        }
      );

      iAttrs.$observe('width', $scope.updateWidth);

      iAttrs.$observe('preCol', function() {
        var temp;
        if ($scope.preCol !== undefined && typeof $scope.preCol === 'string' && $scope.preCol.length > 0) {
          temp = JSON.parse($scope.preCol);
        } else{
          temp = $scope.preCol;
        }
        if (!Array.isArray(temp)) {
          var temp2 = [];
          for (var i in temp) {
            var t = {};
            t[i] = temp[i];
            temp2.push(t);
          }
          temp = sortColors(temp2);
        }
        //console.log(temp);
        $scope.$evalAsync(() => {
          $scope.presets.car = temp;
        });
      });

      function showText () {
        $scope.showText = ($scope.showText !== undefined && $scope.showText.length > 0 ? JSON.parse($scope.showText) : true);
      };
      function showPresets () {
        $scope.showPresets = ($scope.showPresets !== undefined && $scope.showPresets.length > 0 ? JSON.parse($scope.showPresets) : true);
      };
      function presetsEditable () {
        $scope.presetsEditable = ($scope.presetsEditable !== undefined && $scope.presetsEditable.length > 0 ? JSON.parse($scope.presetsEditable) : false);
      };
      function showAlpha () {
        $scope.showAlpha = ($scope.showAlpha !== undefined && $scope.showAlpha.length > 0 ? JSON.parse($scope.showAlpha) : true);
      };
      function showMain () {
        $scope.showMain = ($scope.showMain !== undefined && $scope.showMain.length > 0 ? JSON.parse($scope.showMain) : true);
      };
      function showPreview () {
        $scope.showPreview = ($scope.showPreview !== undefined && $scope.showPreview.length > 0 ? JSON.parse($scope.showPreview) : true);
      };

      iAttrs.$observe('showText', showText);
      iAttrs.$observe('showPresets', showPresets);
      iAttrs.$observe('presetsEditable', presetsEditable);
      iAttrs.$observe('showAlpha', showAlpha);
      iAttrs.$observe('showMain', showMain);
      iAttrs.$observe('showPreview', showPreview);

      showText();
      showPresets();
      presetsEditable();
      showAlpha();
      showMain();
      showPreview();

      $scope.colorDot = {};
      $scope.hslMousedownFlag = false;

      $scope.color = (function() {
        var values = [0, 0, 0];
        var alpha = 0;

        //  $scope.$watch(
        //   function() {return values;},
        //   function() {console.log(values); }
        // );

        /**
         * Converts an RGB color value to HSL. Conversion formula
         * adapted from http://en.wikipedia.org/wiki/HSL_color_space.
         * Assumes r, g, and b are contained in the set [0, 1] and
         * returns h, s, and l in the set [0, 1].
         *
         * @param   Number  r       The red color value
         * @param   Number  g       The green color value
         * @param   Number  b       The blue color value
         * @return  Array           The HSL representation
         **/
        function toHsl(rgb) {
          var r = rgb[0], g = rgb[1], b = rgb[2];
          var max = Math.max(r, g, b), min = Math.min(r, g, b);
          var h, s, l = (max + min) / 2;

          if (max == min) {
            h = s = 0; // achromatic
          } else {
            var d = max - min;
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
            switch (max){
              case r: h = (g - b) / d + (g < b ? 6 : 0); break;
              case g: h = (b - r) / d + 2; break;
              case b: h = (r - g) / d + 4; break;
            }
            h /= 6;
          }

          return [h, s, l];
        }

        /**
         * Converts an HSL color value to RGB. Conversion formula
         * adapted from http://en.wikipedia.org/wiki/HSL_color_space.
         * Assumes h, s, and l are contained in the set [0, 1] and
         * returns r, g, and b in the set [0, 255].
         *
         * @param   Number  h       The hue
         * @param   Number  s       The saturation
         * @param   Number  l       The lightness
         * @return  Array           The RGB representation
         **/
        function fromHsl(hsl) {
          var r, g, b;

          if (hsl[1] === 0) {
            r = g = b = hsl[2]; // achromatic
          } else {
            var hue2rgb = function hue2rgb(p, q, t) {
              if (t < 0) {t += 1;}
              if (t > 1) {t -= 1;}
              if (t < 1 / 6) {return p + (q - p) * 6 * t;}
              if (t < 1 / 2) {return q;}
              if (t < 2 / 3) {return p + (q - p) * (2 / 3 - t) * 6;}
              return p;
            };

            var q = hsl[2] < 0.5 ? hsl[2] * (1 + hsl[1]) : hsl[2] + hsl[1] - hsl[2] * hsl[1];
            var p = 2 * hsl[2] - q;
            r = hue2rgb(p, q, hsl[0] + 1 / 3);
            g = hue2rgb(p, q, hsl[0]);
            b = hue2rgb(p, q, hsl[0] - 1 / 3);
          }
          return [r, g, b];
        }

        var arr = {
          get rgb() {
            return fromHsl(values).map(function(elem) {return Math.round(elem * 255);});
          },
          get rgba() {
            return this.rgb.concat([alpha]);
          },
          set rgb(arr) {
            values = toHsl(arr);
            alpha = arr[3] || alpha;
          },
          get hsl() {
            return values;
          },
          get hsla() {
            return values.concat([alpha]);
          },
          set hsl(arr) {
            values = arr;
            alpha = arr[3] || alpha;
          }
        };

        var str = {
          get rgb01() {
            return fromHsl(values).slice(0, 3).join(' ');
          },
          get rgba01() {
            return this.rgb01 + ' ' + alpha;
          },
          set rgb01(str) {
            var arr = str.split(' ');
            values = toHsl(arr.slice(0, 3).map(function(elem) {return Math.round(Number(elem) * 255);}));
            alpha = arr[3] || alpha;
          },
          get rgb() {
            return fromHsl(values).slice(0, 3).map(function(elem) {return Math.round(elem * 255);}).join(' ');
          },
          get rgba() {
            return this.rgb + ' ' + alpha;
          },
          set rgb(str) {
            var arr = str.split(' ').map(Number);
            values = toHsl(arr);
            alpha = arr[3] || alpha;
          },
          get hsl() {
            return values.slice(0, 3).join(' ');
          },
          get hsla() {
            return this.hsl + ' ' + alpha;
          },
          set hsl(str) {
            var arr = str.split(' ').map(Number);
            values = arr;
            alpha = arr[3] || alpha;
          }
        };

        function hslCssStr (arr) {
          return Math.round(arr[0] * 360) + ',' + Math.round(arr[1] * 100) + '%,' + Math.round(arr[2] * 100) + '%';
        }

        return {
          arr: arr,
          str: str,
          // todo: why is this getter and setter and not jsut a property?
          get alpha() {
            return alpha;
          },
          set alpha(val) {
            alpha = val;
          },
          rgbToHsl: toHsl,
          hslToRgb: fromHsl,
          hslCssStr: hslCssStr
        };
      }());

        $scope.presets = {
          user: [],
          car: []
        };

        $scope.carListEmpty = true;

      $scope.$watch(
        function(scope) {return scope.presets.car;},
        function() {$scope.carListEmpty = $scope.presets.car.length <= 0;}
      );

      $scope.userListEmpty = true;

      $scope.$watch(
        function(scope) {return scope.presets.user;},
        function() {$scope.userListEmpty = $scope.presets.user.length <= 0;}
      );

      function inCarPresets (name) {
        for (var i = 0; i < $scope.presets.car.length; i++) {
          if (name in $scope.presets.car[i]) {
            return i;
          }
        }
        return -1;
      }

      function init() {
        if ($scope.initValue !== $scope.color.str.rgba01) {
          var index = inCarPresets($scope.initValue);
          if ($scope.presets.car !== undefined && index !== -1) {
            $scope.color.str.rgb = $scope.presets.car[index][$scope.initValue];
          } else if ($scope.initValue !== undefined && $scope.initValue.split(' ').length < 3) { // In case the the new value is astring that cannot be parsed
            $scope.color.arr.rgb = [0, 0, 0, 0];
          } else {
            $scope.color.str.rgb = $scope.initValue || '0 0 0 0';
          }
          $scope.setColorDot();
        }
        // console.log($scope.showMain);
        // console.log($scope);
      }

      function average (arr) {
        return arr.reduce(function (a, c) {return a + c;}) / arr.length;
      }

      function valComparable(list, thres) {
        thres = thres || 0.05;
        var bool = true;
        var av = average(list);

        for (var i = 0; i < list.length; i+=1) {
          bool = bool && (av - thres <= list[i]) && (av + thres >= list[i]);
        }
        bool = bool && (av > 0.8 || av < 0.2);
        return bool;
      }

      function colorHigherHelper(list) {
        var av = average(list.valOrig.slice(0,3));
        // console.log(av);
        var al = list.valOrig[3]/2;
        var res = Math.abs(av - 1) * al;

        if (res === 0) {
          return (av + al)/2;
        } else {
          return res + 1 ;
        }
      }

      function colorHigher (a, b) {
        var aColor = valComparable(a.valOrig.slice(0,3));
        var bColor = valComparable(b.valOrig.slice(0,3));
        // console.log(aColor, bColor);

        if (aColor && bColor) {
          // console.log(colorHigherHelper(a), colorHigherHelper(b), colorHigherHelper(b) - colorHigherHelper(a));
          return colorHigherHelper(b) - colorHigherHelper(a);
        } else if (aColor && !bColor) {
          return 1;
        } else if (!aColor && bColor){
          return -1;
        } else {
          for (var i = 0; i < 3; i++) {
            if (a.val[i] !== b.val[i]) {
              return a.val[i] - b.val[i];
            }
          }
          return 0;
        }
      }

      // Thanks to: http://www.alanzucconi.com/2015/09/30/colour-sorting/
      function colorValue(obj) {
        var repitions = 8;
        var rgb = [];

        for (var i = 0; i < 3; i++) {
          rgb[i] = ((1 - obj[3]/2) * obj[i]) + (obj[3]/2 * obj[i]);
        }

        lum = Math.sqrt(0.241 * rgb[0] + 0.691 * rgb[1] + 0.068 * rgb[2]);
        var hsv = $scope.color.rgbToHsl(rgb);
        var out = [hsv[0], lum, hsv[1]].map(function (elem) {return elem * repitions;});

        if (out[0] % 2 === 1) {
          out[1] = repitions - out[1];
          out[2] = repitions - out[2];
        }

        out.push(obj[3]);
        return out;
      }

      function sortColors(arr) {
        var temp = arr.map(function (elem) {
          var valOrig = elem[Object.keys(elem)[0]].split(' ').map(function (elem) {return Number(elem);});
          return {val: colorValue(valOrig), valOrig: valOrig, orig: elem};
        });
        var help = temp.sort(colorHigher);
        // console.log(help);
        return help.map(function (elem) {return elem.orig;});
      }

      $scope.$on('SettingsChanged', function (event, data) {
        $log.debug('[color.js] received Settings:', data);
        $scope.$apply(function() {
          $scope.values = data.values;
          var help = $scope.values.userColorPresets;
          if (help !== undefined) {
            $scope.presets.user = JSON.parse(help.replace(/'/g, '\"'));
          } else {
            $scope.presets.user = [];
          }
          // console.log(typeof $scope.presets.user, $scope.presets.user);
        });
      });

      bngApi.engineLua('settings.requestState()');

      $scope.toIntVal = function(val, div) {
        div = div || true;
        var help = val.split(' ');
        return help.slice(0, 3).map(function(elem) {return Math.round(255 * Number(elem));}).join(',') + ', ' + (help[3] / (div ? 2 : 1));
      };

      $scope.applyPreset = function(pre) {
        var help = pre.split(' ').map(Number);
        $scope.color.arr.rgb = help;
        $scope.alpha = help[3];
        $scope.returnColor();
      };

      function updatePreStor() {
        $scope.values.userColorPresets = JSON.stringify($scope.presets.user);
        console.log(typeof $scope.values.userColorPresets, $scope.values.userColorPresets);
        var short = bngApi.serializeToLua($scope.values);
        console.log(typeof short, short);
        bngApi.engineLua('settings.setState(' + bngApi.serializeToLua($scope.values) + ')');
      }

      $scope.addPreset = function() {
        console.log($scope.color.str.rgba01);
        $scope.presets.user.push($scope.color.str.rgba01);
        updatePreStor();
      };

      $scope.removePreset = function(pre) {
        if ($scope.presetsEditable) {
          $scope.presets.user.splice($scope.presets.user.indexOf(pre), 1);
          updatePreStor();
        }
      };

      $scope.updateBright = function(val) {
        var help = $scope.color.arr.hsl.slice(0, 2);
        help[2] = Number(val);
        $scope.color.arr.hsl = help;
        // console.log($scope.color.arr.hsl);
      };

      $scope.brightGradientColor = function() {
        var help = $scope.color.arr.hsl.slice(0, 2).concat([0.5]);
        return $scope.color.hslCssStr(help);
      };

      $scope.alphaGradientColor = function() {
        return $scope.color.hslCssStr($scope.color.arr.hsl);
      };

      $scope.returnColor = function() {
        // console.log($scope.color.str.rgba01);
        ngModelController.$setViewValue($scope.color.str.rgba01);
      };

      $scope.setColorDot = function() {
        var help = $scope.color.arr.hsl;
        $scope.colorDot = {x: Math.round(help[0] * $scope.w), y: Math.round($scope.height * (1 - help[1]))};
        $scope.brightness = help[2];
      };

      function getMouseInHslimg(ev, ref) {
        var elem = ev.target.getBoundingClientRect();
        var x = ev.x - elem.left;
        var y = ev.y - elem.top;
        return elem.width < 20 ? ref : {x: x, y: y};
      }

      $scope.hslMouseupLeave = function(ev) {
        if ($scope.hslMousedownFlag) {
          var info = getMouseInHslimg(ev, $scope.colorDot);
          $scope.updateColor(info.x, info.y);

          $scope.hslMousedownFlag = false;
        }
      };

      $scope.hslMousemove = function(ev) {
        if ($scope.hslMousedownFlag) {
          var info = getMouseInHslimg(ev, $scope.colorDot);
          $scope.updateColor(info.x, info.y);
        }
      };

      $scope.updateColor = function(x, y) {
        var l = $scope.color.arr.hsl[2];

        if ($scope.hslMousedownFlag) {
          $scope.color.arr.hsl = [
            (x < 0 ? 0 : (x > $scope.w ? 0.99 : x / $scope.w)),
            (y < 0 ? 1 : (y > $scope.height ? 0.01 : (1 - y / $scope.height))), l];
          $scope.setColorDot();
          $scope.returnColor();
        }
      };

      $scope.hslMousedown = function() {
        $scope.hslMousedownFlag = true;
      };


      init();
    }
  };
}]);

// })();
