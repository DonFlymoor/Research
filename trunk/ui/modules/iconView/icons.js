(function () {
  'use strict';

  angular.module('beamng.stuff')

.controller('iconViewerCtrl', function ($scope, $filter) {
  var vm = this
    , color = 'white'
    // , list = [{type: 'svg', color: color, src: 'Components/Shapes/arrow.svg'}]
    , list = []
    ;
  vm.config = {};

  $scope.$evalAsync(() => {
    if (vm.config.query === undefined) {
      vm.config.query = '';
    }
  });

  vm.list = [];

  // === important: this code will not be needed in production, this is jsut to detect the available icons. ===================================================
  // === all icons are already loaded via the constants.js
  // function getFlags (cb) {
  //   FS.getFiles('Assets/Icons/CountryFlags/').then((data) => {
  //     var formated = data.map((e) => ({src: e.replace('.png', '').replace('Assets/Icons/CountryFlags/', ''), color: color, type: 'flag'}));
  //     // console.log(formated);
  //     list = list.concat(formated);
  //     (cb || nop)();
  //   });
  // }


  function getMaterial (cb) {
    list = list.concat(Array.apply(undefined, document.querySelectorAll('.symbols-def symbol')).map(e => {
      if (e.id.startsWith('material_')) {
        return {src: e.id.slice('material_'.length), color:color, type: 'material'}
      }
      return {src: e.id, color:color, type: 'sprite'};
    }));
    (cb || nop)();
  }


  vm.sort = function (val) {
    $scope.$evalAsync(() => {
      // console.log(list);
      vm.config.sortBy = val || vm.config.sortBy;
      vm.list = $filter('filter')(list, vm.config.query);
    });
  };
  setTimeout(() => {
    getMaterial(() => $scope.$evalAsync(() => vm.sort(list)));
  }, 500)
})
}());











(function () {
  'use strict';

  angular.module('beamng.ui2Ports')

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
.directive('bngIcon', function () {
  return {
    template: `
      <bng-box1x1 class="filler" ng-switch="type" ng-style="{transform: getTransform()}">
        <bng-flag ng-switch-when="flag" src="val" deg="getDeg()"></bng-flag>
        <bng-icon-img ng-switch-when="img" src="val" deg="getDeg()"></bng-icon-img>
        <bng-icon-material ng-switch-when="material" src="val" deg="getDeg()" color="color"></bng-icon-material>
        <bng-icon-svg ng-switch-when="svg" src="val" deg="getDeg()" color="color"></bng-icon-svg>
        <bng-icon-svg-sprite ng-switch-when="sprite" src="val" deg="getDeg()" color="color"></bng-icon-svg-sprite>
        <bng-icon-svg-sprite ng-switch-default src="'general_beamng_logo_bw'" color="color"></bng-icon-svg-sprite>
      </bng-box1x1>
    `,
    scope: {
      type: '@',
      val: '=src',
      color: '=',
      direction: '=?',
      degree: '=?'
    },
    link: function (scope) {
      scope.degree = scope.degree || 0;

      scope.getDeg = function () {
        switch (scope.direction) {
        case 'top': scope.degree = 0; break;
        case 'right': scope.degree = 90; break;
        case 'bottom': scope.degree = 180; break;
        case 'left': scope.degree = 270; break;
        }
        return scope.degree;
      }
    }
  };
})



// === important: do not use any of these directly! use the above (bngIcon) instead =================================
.directive('bngIconSvg', function () {
  return {
    restrict: 'E',
    template: `<div ng-include="src" style="{{!color ? 'fill: currentColor;' : ''}} pointer-events: none; transform: rotate({{deg}}deg);" class="{{color ? 'fill-' + color : ''}}"></div>`,
    scope: {
      src: '=',
      color: '=',
      deg: '='
    }
  };
})

// === important: do not use any of these directly! use the above (bngIcon) instead =================================
.directive('bngIconSvgSprite', function (spriteDuplicates) {
  return {
    restrict: 'E',
    template: `<svg class="{{color ? 'fill-' + color : ''}} filler" style="{{!color ? 'fill: currentColor;' : ''}} pointer-events: none; transform: rotate({{deg}}deg);"><use xlink:href="{{getPath(src)}}"/></svg>`,
    scope: {
      src: '=',
      color: '=',
      deg: '='
    },
    link: function (scope) {
      scope.getPath = (src) => `#${spriteDuplicates[src] || src}`;
    }
  };
})

// === important: do not use any of these directly! use the above (bngIcon) instead =================================
.directive('bngIconMaterial', function () {
  return {
    restrict: 'E',
    template: `<bng-icon-svg-sprite src="getPath(src)" color="color" deg="deg"></bng-icon-svg-sprite>`,
    scope: {
      src: '=',
      color: '=',
      deg: '='
    },
    link: function (scope) {
      scope.getPath = (src) => `material_${src}`;
    }
  };
})

// === important: do not use any of these directly! use the above (bngIcon) instead =================================
.directive('bngIconImg', function () {
  return {
    restrict: 'E',
    template: `<img class="filler" ng-src="{{src}}" style="transform: rotate({{deg}}deg);"/>`,
    scope: {
      src: '=',
      deg: '='
    },
  };
})

// === important: do not use any of these directly! use the above (bngIcon) instead =================================
.directive('bngFlag', function () {
  return {
    restrict: 'E',
    template: `<img class="filler" ng-src="{{imgSrc}}"  style="transform: rotate({{deg}}deg);"/>`,
    scope: {
      src: '=',
      deg: '='
    },
    link: function (scope) {
      var shortHand =
        { 'United States': 'USA'
        , 'Japan': 'JP'
        , 'Germany': 'GER'
        , 'Italy': 'IT'
        }
      ;
      function setSrc () {
        scope.imgSrc = `Assets/Icons/CountryFlags/${shortHand[scope.src] || scope.src || 'missing'}.png`;
      }

      scope.$watch('src', setSrc);

      setSrc();
    }
  };
})




.directive('bngBox1x1', function () {
  return {
    restrict: 'E',
    template: `
      <div class='box1_1'>
        <div class='container' ng-transclude></div>
      </div>
    `,
    transclude: true
  };
})
}());



