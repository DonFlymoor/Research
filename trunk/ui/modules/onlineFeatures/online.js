(function () {
'use strict';
  
angular.module('beamng.stuff')

.controller('OnlineFeaturesController', ['$scope', 'bngApi', '$state', '$timeout', function($scope, bngApi, $state, $timeout) {
  'use strict';

  // The lua setting need to be functional before we redirect, otherwise we'll land here again.
  // for that reason, we listen for the settings changed event that will ensure that the main menu will not get back here again
  
  var selectedAnswer = false;
  $scope.storeAnswer = function (val) {
    bngApi.engineLua(`settings.setValue('onlineFeatures', '${val}')`);
    selectedAnswer = true;
  };

  $scope.$on('SettingsChanged', (ev, data) => {
    if(selectedAnswer) {
      $state.go('menu.mainmenu');
    }
  });

}]);

})();