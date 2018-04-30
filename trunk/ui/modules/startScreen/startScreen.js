angular.module('beamng.stuff')

.controller('startScreenController', ['$scope', '$state', '$timeout', 'bngApi', function($scope, $state, $timeout, bngApi) {
  setTimeout(() => { $state.go('menu.mainmenu'); }, 1000);
}]);