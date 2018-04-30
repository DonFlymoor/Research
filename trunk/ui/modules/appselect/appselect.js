angular.module('beamng.stuff')

/**
 * @ngdoc controller
 * @name beamng.stuff:AppSelectController
 * @requires $filter
 * @requires $rootScope
 * @requires $scope
 * @requires $state
 * @requires beamng.stuff:InstalledContent
 */
.controller('AppSelectController', ['$filter', '$rootScope', '$state', 'InstalledContent', 'AppSelectFilters', 'UiAppsService',
function ($filter, $rootScope, $state, InstalledContent, AppSelectFilters, UiAppsService) {
	var vm = this;

  // Extend here or in the resolved phase - no need to keep the stored information updated at all times w/ unnecessary listeners
  vm.list = InstalledContent.apps.map(x => angular.extend(x, { __displayName__: $filter('translate')(x.name), isActive: UiAppsService.isAppActive(x) }));
  vm.filters = AppSelectFilters;

  vm.openRepo = () => { window.location.href = 'http-external://www.beamng.com/resources/categories/user-interface-apps.10/?ingame=2'; };

  vm.spawn = (appData) => {
    if (appData.isActive) {
      return;
    }
    
    $rootScope.$broadcast('appContainer:spawn', appData); // The 'spawnApp' event is caught by the app-container directive too!
    $state.go('appedit');
  };

}])

.controller('AppEditController', ['$rootScope', '$scope', function ($rootScope, $scope) {
  // The 'editApps' event is caught by the app-container directive
  $rootScope.$broadcast('editApps', true);

  $scope.$on('$destroy', function () {
    $rootScope.$broadcast('editApps', false);
  });

  $scope.reset = () => $rootScope.$broadcast('appContainer:resetLayout');
}]);