angular.module('beamng.apps')
.directive('proctrack',  ['$http', '$log', 'bngApi', function ($http, $log, bngApi) {
  return {
    templateUrl: 'modules/apps/ProcTrack/app.html',
    replace: true,
    restrict: 'EA',
    scope: true,
    link: function (scope, element, $mdDialog)  {


      scope.find = function() { 
        //scope.position = "horn lehe";
        console.log('loadMap', scope.seed);
        bngApi.engineLua("require('util/procTrack').reGenerate(" + scope.seed + ")");
         //bngApi.engineLua("be:resetVehicle(be:getPlayerVehicle(0):getID())");
        // bngApi.engineLua("scenario_scenarios.restartScenario()");
         bngApi.engineLua("scenario_scenarios.uiEventRetry()");
      };

      scope.enterMouse = function() {
        scope.$evalAsync(function () {
            bngApi.engineLua('setCEFFocus(true)');
        });
      };

      scope.randomize = function() {
        scope.$evalAsync(function () {
            scope.seed = Math.ceil(Math.random() * 500*500*500*500);
        });
      };

       scope.$on('procTrackSeed',function(event,data) {
        scope.$evalAsync(() => {
          scope.seed = data;
        });
      });

     bngApi.engineLua("require('util/procTrack').getSeed()",function(ret) { scope.seed = ret });
    
    
    }
  }
}]);