(function () {
  'use strict';

  angular.module('beamng.stuff')

.controller('iconViewerCtrl', function ($scope, $filter) {
  var vm = this
    , color = 'white'
    // , list = [{type: 'svg', color: color, src: 'Components/Shapes/arrow.svg'}]
    , list = [
      // [ {type: 'svg', color: 'blue', src: 'Assets/logo.svg'}
      // , {type: 'img', color: 'blue', src: 'Assets/logo.svg'}
      // , {type: 'sprite', color: 'blue', src: 'automation_logo'}
      // , {type: 'sprite', color: 'blue', src: 'automation_logo_origcolor'}
      // , {type: 'svg', color: 'blue', src: 'Assets/beamng_logo.svg'}
      // , {type: 'img', color: 'blue', src: 'Assets/beamng_logo.svg'}
      ]
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


  function getSymbols (cb) {
    list = list.concat(Array.apply(undefined, document.querySelectorAll('.symbols-def symbol')).map(e => ({src: e.id, color:color, type: 'sprite'})));
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
    getSymbols(() => $scope.$evalAsync(() => vm.sort(list)));
  }, 500)
})
}());

