(function() {
  'use strict';

  angular
    .module('fc.paging', [])
    .directive('wanMaterialPaging', WanMaterialPagingDirective);

  /**
   * @ngInject
   */
  function WanMaterialPagingDirective() {
    return {
      restrict: 'EA',
      scope: {
        wmpTotal: '=',
        position: '@',
        gotoPage: '&',
        step: '=',
        currentPage: '='
      },
      controller: Controller,
      controllerAs: 'vm_paging',
      template: [
        '<div layout="row" class="wan-material-paging" layout-align="{{ position }}" ng-show="wmpTotal>1">',
          '<md-button class="md-raised md-primary wmp-button" aria-label="First" ng-click="vm_paging.gotoFirst()" ng-disabled="wmpTotal<2 || currentPage < 2">{{ vm_paging.first }}</md-button>',
          '<md-button class="md-raised wmp-button" aria-label="Previous Page" ng-click="vm_paging.gotoPreP()" ng-disabled="currentPage < 2">{{ vm_paging.prevp }}</md-button>',
          '<md-button class="md-raised wmp-button" aria-label="Previous" ng-click="vm_paging.getoPre()" ng-disabled="vm_paging.index - 1 <= 0">...</md-button>',
          '<md-button class="md-raised wmp-button" aria-label="Go to page {{i+1}}" ng-repeat="i in vm_paging.stepInfo"',
          ' ng-click="vm_paging.goto(vm_paging.index + i)" ng-show="vm_paging.page[vm_paging.index + i]" ',
          ' ng-class="{true: \'md-primary\', false: \'\'}[vm_paging.page[vm_paging.index + i] === currentPage]">',
          ' {{ vm_paging.page[vm_paging.index + i] }}',
          '</md-button>',
          '<md-button class="md-raised wmp-button" aria-label="Next" ng-click="vm_paging.getoNext()" ng-disabled="vm_paging.index + vm_paging.step >= wmpTotal">...</md-button>',
          '<md-button class="md-raised wmp-button" aria-label="Next Page" ng-click="vm_paging.gotoNextP()" ng-disabled="currentPage >= wmpTotal">{{ vm_paging.nextp }}</md-button>',
          '<md-button class="md-raised md-primary wmp-button" aria-label="Last" ng-click="vm_paging.gotoLast()" ng-disabled="currentPage == wmpTotal">{{ vm_paging.last }}</md-button>',
        '</div>'
      ].join('')
    };
  }

  /**
   * @ngInject
   */
  var	Controller = ['$scope', function ($scope) {
    var vm_paging = this;

    vm_paging.first = '<<';
    vm_paging.last = '>>';
    vm_paging.prevp = '<';
    vm_paging.nextp = '>';
    vm_paging.index = 0;
    vm_paging.step = $scope.step;

    vm_paging.goto = function(index) {
      $scope.currentPage = vm_paging.page[index];
    };

    vm_paging.getoPre = function(){
      $scope.currentPage = vm_paging.index;
      vm_paging.index -= vm_paging.step;
    };

    vm_paging.getoNext = function(){
      vm_paging.index += vm_paging.step;
      $scope.currentPage = vm_paging.index + 1;
    };

    vm_paging.gotoPreP = function(){
      $scope.currentPage -= 1;
      if($scope.currentPage == vm_paging.index){vm_paging.index -=vm_paging.step;}
    };

    vm_paging.gotoNextP = function(){
      $scope.currentPage += 1;
    };

    vm_paging.gotoFirst = function(){
      if($scope.wmpTotal<2 || $scope.currentPag < 2)return;
      vm_paging.index = 0;
      $scope.currentPage = 1;
    };

    vm_paging.gotoLast = function(){
      vm_paging.index = parseInt($scope.wmpTotal / vm_paging.step) * vm_paging.step;
      vm_paging.index === $scope.wmpTotal ? vm_paging.index = vm_paging.index - vm_paging.step : '';
      $scope.currentPage = $scope.wmpTotal;
    };

    $scope.$watch('currentPage', function() {
      if( (vm_paging.index +vm_paging.step ) < $scope.currentPage || vm_paging.index > $scope.currentPage){vm_paging.index = ($scope.currentPage-$scope.currentPage%vm_paging.step);}
      $scope.gotoPage();
    });

    $scope.$watch('wmpTotal', function() {
      vm_paging.init();
    });

    vm_paging.init = function() {
      vm_paging.stepInfo = (function() {
        var i, result = [];
        for (i = 0; i < vm_paging.step; i++) {
          result.push(i)
        }
        return result;
      })();

     vm_paging.page = (function() {
        var i, result = [];
        for (i = 1; i <= $scope.wmpTotal; i++) {
          result.push(i);
        }
        return result;
      })();

    };
  }];

})();
