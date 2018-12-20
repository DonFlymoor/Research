angular.module('beamng.garage')

.directive('colorPreset', function () {
  return {
    template: `
      <div class="filler" style="position: relative;">
        <gp-square>
          <div style="margin: 8px; box-sizing: border-box; border-radius: 200%; position: absolute; top: 8px; bottom: 8px; left: 8px; right: 8px; overflow: hidden; border: 3px solid {{highlight || active ? 'currentColor' : 'transparent'}};" ng-class="{color2: highlight, 'color3': active }">
            <div style="position: absolute; top: 1px; right: 1px; bottom: 1px; left: 1px; border-radius: 100%;" class="transparentIndicatorSquared"></div>
            <!--<div style="background: -webkit-linear-gradient(rgba(255, 255, 255, 0.3), rgba(0, 0, 0, 0.5)); position: absolute; top: 1px; right: 1px; bottom: 1px; left: 1px; border-radius: 100%;"></div>-->
            <div style="background-color: hsla({{color[0] * 360}}, {{color[1] * 100}}%, {{color[2] * 100}}%, {{color[3]}}); position: absolute; top: 1px; right: 1px; bottom: 1px; left: 1px; border-radius: 100%;"></div>
            <div style="position: absolute;" class="filler colorWidgetShadow"></div>
          </div>
        </gp-square>
        <div ng-if="active" class="font1 color1" style="font-size: 12pt; position: absolute; width: 150px; text-align: center; left: calc(-75px + 50%); bottom: -8px;">{{key}}</div>
      </div>
    `,
    scope: {
      color: '=',
      key: '=',
      highlight: '=',
      active: '='
    }
  };
})


.directive('colorCircle', ['$document', 'bngApi', function ($document, bngApi) {
  return {
    restrict: 'E',
    require: ['ngModel', '?bngNavItem'],
    template: `
      <div layout="column" layout-align="center center" style="cursor: pointer; width: 100%; height: 100%; position: relative;" tabindex="a" ondragstart="return false;">
        <div style="width: 100%; height: 100%; position: relative;">
          <div style="position: absolute; width: 100%; height: 100%; transform: rotate({{fixIndPos(rotation)}}deg);" layout="row" layout-align="center center">
            <gp-arrow style="position: relative; top: -65%; width: 27%; max-width: 50px; -webkit-transform: scale(0.8);"></gp-arrow>
          </div>
          <!--<div style="position: absolute; top: 50%; left: 50%; bottom: 50%; right: 50%; border: 1px solid white;"></div>-->
          <!--<div style="position: fixed; z-index: 100; top: {{ref.y}}px; left: {{ref.x}}px; border: 1px solid white;"></div>-->
          <div ng-if="type === 'brightness'" style="background-color: white; position: absolute; width: 100%; height: 100%; -webkit-mask: url({{:: imgSrc}}) no-repeat center center; -webkit-mask-size: 100%; -webkit-transform: scaleX(-1);"></div>
          <div ng-if="!noBg" ng-class="{'transparentIndicatorSquared': bgSquared}" style="background-color: white; position: absolute; width: 100%; height: 100%; -webkit-mask: url(modules/garageNew/elements/color_circle.png) no-repeat center center; -webkit-mask-size: 100%;"></div>
          <div ng-if="bgColor" style="background-color: {{bgColor}}; position: absolute; width: 100%; height: 100%; -webkit-mask: url(modules/garageNew/elements/circle_white_gradient.png) no-repeat center center; -webkit-mask-size: 100%;"></div>
          <img ng-if="(!bgColor || type === 'brightness') && imgSrc" ng-src="{{imgSrc}}" style="width: 100%; height: 100%; position: absolute;"/>
        </div>
      </div>`,
    scope: {
      type: '@',
      bgColor: '=',
      max: "@"
    },
    link: function (scope, elem, attrs, ctrls) {
      var mDown = false
        , prefix = 1
        , input = angular.element(elem[0])
        , ngModel = ctrls[0]
        , navItem = ctrls[1]
        , dim = getDim()
      ;

      function getDim () {
        var help = elem[0].getBoundingClientRect();
        help.radius = help.width / 2;
        help.centerX = help.left + help.radius;
        help.centerY = help.top + help.radius;
        if (help.width !== help.height) console.error('weel the color circle isn\'t round. Damn. Fix me!');
        return help;
      }

      switch (scope.type) {
        case 'hue': 
          scope.title = 'Hue';
          scope.imgSrc = 'modules/garageNew/elements/color_circle.png';
          scope.noBg = true;
          break;
        case 'saturation':
          scope.title = 'Saturation';
          break;
        case 'brightness': 
          scope.title = 'Brightness';
          scope.imgSrc = 'modules/garageNew/elements/circle_black_gradient.png';
          prefix = 0;
          break;
        case 'alpha': 
          scope.title = 'Chrominess';
          scope.imgSrc = 'modules/garageNew/elements/circle_black_gradient.png';
          scope.bgSquared = true;
          break;
      }
      scope.rotation = 0;


      var addListeners = () => { $document.on('mousemove', setVal); };
      var removeListeners = () => { $document.off('mousemove', setVal); };

      function mousedown (ev) {
        setVal(ev);
        addListeners();
      }

      input.on('mousedown', mousedown);
      input.on('dragend', removeListeners);
      $document.on('mouseup', removeListeners);

      scope.ref = {x: 0, y: 0};

      scope.fixRange = (val) => Math.abs(val - prefix); // invert degree for all except those with prefix 0
      scope.fixIndPos = (val) => val * ((prefix - 0.5) * -2); // change direction of deg for all except those with prefix 0

      function setVal (ev) {
        dim = getDim();
        // console.log(dim, ev.clientX, ev.clientY, radialFun, Math.abs(dim.centerY - ev.clientY), Math.abs(dim.centerX - ev.clientX), Math.abs(dim.centerX - ev.clientX) > 10 || Math.abs(dim.centerY - ev.clientY) > 10, ngModel.$modelValue);
        scope.ref = {x: ev.clientX, y: ev.clientY};
        var dx = Math.pow(Math.abs(ev.clientX - dim.centerX), 2) + Math.pow(Math.abs(ev.clientY - dim.centerY), 2);

        scope.$evalAsync(() => {
          // todo use proper threshold -yh 
          if (Math.abs(dx) >= (dim.radius * dim.radius) / 2.2) {
            // bngApi.engineLua(`Engine.Audio.playOnce('AudioGui', 'core/art/sound/ui_slider.ogg',  {unique = true})`);
            ngModel.$modelValue = scope.fixRange(convertRectToDeg(ev.clientX, ev.clientY)); 
            ngModel.$viewValue = ngModel.$modelValue;
            ngModel.$$writeModelToScope();
            draw();
          }
        });
      };

      // calc alpha in a triangle with one 90 deg corner
       function angle (x, y) {
        var hyp = Math.sqrt(Math.pow(y, 2) + Math.pow(x, 2)) * (x > 0 ? -1 : 1);
        return (Math.asin(y / hyp) + Math.PI / 2) * (180 / Math.PI) + (x > 0 ? 0 : 180);
      }
    
      function convertRectToDeg (x, y) {

        var  xc = dim.centerX
          , yc = dim.centerY
        ;
        // console.log(x, y, xc, yc, radialFun.x, radialFun.y);

        // separate the coords in 4 quadrants and put the 0-90 deg from angle in perspective of the circle
        // don't even try to calc if cursor is exactly above center, since this doesn't make any sense 
        if (xc !== x || yc !== y) {
          // x coor in cef maps fine to x-axis on controller,
          // but y coor is reverse to y-axis 
          var res = angle(x-xc, yc-y);
          // back to val btw 0 and 1
          return res / 360;
        }
      };

      function draw () {
        scope.rotation = Math.round(ngModel.$modelValue * 360);
      };

      ngModel.$render = draw;


      var radialFun = {x: 0, y: 0};
      var mockedEv = {
        get clientX () {return dim.centerX + radialFun.x * 50},
        get clientY () {return dim.centerY - radialFun.y * 50},
      };


      if (navItem) {
        navItem.actions['radial-x'] = function (val) {
          radialFun.x = val; 
          setVal(mockedEv); 
        };
        navItem.actions['radial-y'] = function (val) {
          radialFun.y = val; 
          setVal(mockedEv); 
        };
      }
    }
  };
}])


.controller('garagePaint', ['$scope', 'logger', 'bngApi', '$state', 'Utils', function ($scope, logger, bngApi, $state, Utils) {
  var vm = this;

  vm.presets = {
    user: [],
    car: {'White': '1 1 1 2'},
  };

  vm.active = [];

  $scope.$on('SettingsChanged', function (event, data) {
    var help = data.values.userColorPresets;
    if (help !== undefined) {
      $scope.$evalAsync(() => {
        vm.presets.user = JSON.parse(help.replace(/'/g, '\"')).map(fixRgba);
      });
    }
  });

  bngApi.engineLua('WinInput.setForwardRawEvents(true);');


  var oldValue;
  vm.set = function () {
    if (vm.color[vm.currentPalette]) {
    oldValue = angular.copy(vm.color[vm.currentPalette]);
    }
  };

  vm.reset = function () {
    if (oldValue) {
      $scope.$evalAsync(() => {
        vm.color[vm.currentPalette] = angular.copy(oldValue);
        oldValue = undefined;
      });
    }
  };

  bngApi.engineLua('settings.requestState()');

  $scope.$on('$destroy', () => {
    bngApi.engineLua('WinInput.setForwardRawEvents(false);');
  });

  $scope.$on('RawInputChanged', (ev, data) => {
    if (data.devName === 'xinput0') {
      if (data.control === 'thumblx' || data.control === 'thumbly') {
        // console.log(data);
      }
    }
  });


  $scope.$on('VehicleChange', () => getVehiclePresetColors);
  getVehiclePresetColors();

  var init = true;
  function getVehiclePresetColors () {
    bngApi.engineLua('core_vehicles.getCurrentVehicleDetails()', (data) => {
      var short = data.model.colors || {};
      if (short['White'] === undefined) {
        short['White'] = '1 1 1 2';
      }
      for (var name in short) {
        short[name] = fixRgba(short[name]);
      }
      $scope.$evalAsync(() => {
        vm.presets.car = short;
        if (init) {
          init = false;
          getVehicleCurrentColors();
        }
      });
    });
  }
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

    return [h, s, l, rgb[3]];
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
    return [r, g, b, hsl[3]];
  }
  
  
  vm.color = [[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]];

  // not needed, since called by getVehiclePresetColors on VehicleChange anyway
  // $scope.$on('VehicleChange', () => getVehicleCurrentColors);

  function findColorKey (colorArray) {
    for (var i in vm.presets.car) {
      if (vm.presets.car[i][0] === colorArray[0]
        && vm.presets.car[i][1] === colorArray[1]
        && vm.presets.car[i][2] === colorArray[2]
        && vm.presets.car[i][3] === colorArray[3]) {
        return {list: 'factory', index: i};
      }
    }

    for (var i = 0; i < vm.presets.user.length; i += 1) {
      if (vm.presets.user[i][0] === colorArray[0]
        && vm.presets.user[i][1] === colorArray[1]
        && vm.presets.user[i][2] === colorArray[2]
        && vm.presets.user[i][3] === colorArray[3]) {
        return {list: 'user', index: i};
      }
    }

    return {list: '', index: undefined};
  }

  function getVehicleCurrentColors () {
    bngApi.engineLua('getVehicleColor()', (res) => {

      logger.log(res);
      $scope.$evalAsync(() => {
        if (res) {
          if (vm.presets.car[res] !== undefined) {
            vm.color[0] = vm.presets.car[res];
            vm.active[0] = {list: 'factory', index: res};
          } else {
            vm.color[0] = fixRgba(res);
            vm.active[0] = findColorKey(vm.color[0]);
          }
        }
      });
    });

    for (var i = 1; i < vm.color.length; i += 1) {
      // yes this is needed, since otherwise we create a function inside the for loop and thanks to clojure i would always be 4
      bngApi.engineScript(`getVehicleColorPalette(${i-1});`, ((id) =>
        (res) => {
          if (res) {
            if (vm.presets.car[res] !== undefined) {
              vm.color[id] = vm.presets.car[res];
              vm.active[id] = {list: 'factory', index: res};
            } else {
              vm.color[id] = fixRgba(res);
              vm.active[id] = findColorKey(vm.color[id]);
            }
          }
        }
      )(i));
    }
    logger.log(vm.color);
  }

  vm.isActive = (palette, index) => vm.currentPalette !== undefined && vm.active[vm.currentPalette] !== undefined && vm.active[vm.currentPalette].list === palette && index === vm.active[vm.currentPalette].index;

  vm.currentPalette = 0;
  vm.updateColor = function () {
    var color = unfixRgba(vm.color[vm.currentPalette]);
    if (vm.currentPalette === 0) {
      bngApi.engineScript(`changeVehicleColor("${color}");`);
    } else {
      bngApi.engineScript(`setVehicleColorPalette(${vm.currentPalette-1}, "${color}");`);
    }
  };

  
  var mult = [1, 1, 1, 0.5];

  function fixRgba (c) {
    var help = c.split(' ').map((e, i) => e * mult[i]);
    return toHsl(help);
  }

  function unfixRgba (c) {
    return fromHsl(c).map((e, i) => e / mult[i]).join(' ');
  }

  vm.setColor = function (c, list, index) {
    vm.active[vm.currentPalette] = {list: list, index: index};
    vm.color[vm.currentPalette] = angular.copy(c);
    logger.log(vm.color);
    logger.log(vm.active);
    vm.updateColor();
  };


  vm.getSatBg = function () {
    var short = vm.color[vm.currentPalette];
    // console.log(short);
    return `hsla(${short[0] * 360}, 50%, 50%, 1)`;
  };

  vm.getLumBg = function () {
    var short = vm.color[vm.currentPalette];
    // console.log(short);
    return `hsla(${short[0] * 360}, ${short[1] * 100}%, 50%, 1)`;
  };

  vm.getAlphaBg = function () {
    var short = vm.color[vm.currentPalette];
    // console.log(short);
    return `hsla(${short[0] * 360}, ${short[1] * 100}%, ${short[2] * 100}%, 1)`;
  };


  function saveUserPresets () {
    bngApi.engineLua('settings.setValue("userColorPresets", ' + bngApi.serializeToLua(JSON.stringify(vm.presets.user.map(unfixRgba))) + ')');
  }

  vm.addColor = function () {
    vm.presets.user.push(vm.color[vm.currentPalette]);
    saveUserPresets();
  };

  vm.removeColor = function () {
    var index = vm.active[vm.currentPalette].index;
    if (vm.isActive('user', index)) {
      vm.presets.user.splice(index, 1);
      vm.active[vm.currentPalette] = undefined;
      saveUserPresets();
    }
  };
  // LICENSE PLATE STUFF
  vm.licensePlate = '';
  
  bngApi.engineLua('getVehicleLicenseName()', function (str) {
    $scope.$evalAsync(() => { vm.licensePlate = str; });
  });


  vm.updateLicensePlate = () => bngApi.engineLua(`setPlateText("${vm.licensePlate}")`);

  logger.log(vm.presets);
  logger.log(vm.active);
}]);
