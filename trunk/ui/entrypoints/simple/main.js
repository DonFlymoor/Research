angular.module('beamng.stuff', [])

angular.module('BeamNG.ui.2', ['beamng.stuff', 'beamng.apps'])

.run(['$rootScope', '$window', 'apiCallbacks', function ($rootScope, $window, apiCallbacks) {
  $window.HookManager = {
    trigger: function (hook, data) {
      $rootScope.$broadcast(hook, data);
    }
  };

  $window.bngApiCallback = function(idx, result) {
    apiCallbacks[idx](result);
    delete apiCallbacks[idx];
  };

  angular.element(document).ready(function(e) {
    // Add an app immediately: Just spawn it in module.run function
    // -> app attributes: pretty much the same as in info.json (not everything is needed - e.g. description)
    var sampleApp = {
      directive: "navigation",
      domElement: "<navigation></navigation>",
      css: { width: '100%', height: '100%', top: '0px', left: '0px'},
      jsSource: 'modules/apps/Navigation/app.js' // IMPORTANT: This is *NOT* in the info.json but is absolutely necessary for app lazy loading
    };

    HookManager.trigger('appContainer:spawn', sampleApp);  
  });
  
}])

.controller('TestController', function () {
  var vm = this;

  // Add an app while playing
  vm.addOtherApp = function () {
    var otherApp = {
      directive: 'aiControl', 
      domElement: '<ai-control></ai-control>', 
      css: {width: '300px', height: '200px', top: '20px', left: '20px'}, 
      jsSource: 'modules/apps/AIControl/app.js' // IMPORTANT: This is *NOT* in the info.json but is absolutely necessary for app lazy loading
    };

    HookManager.trigger('appContainer:spawn', otherApp);
  };

});