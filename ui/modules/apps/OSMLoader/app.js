angular.module('beamng.apps')
.directive('osmloader', ['$http', '$log', 'bngApi', function ($http, $log, bngApi) {
  return {
    templateUrl: 'modules/apps/OSMLoader/app.html',
    replace: true,
    restrict: 'EA',
    scope: true,
    link: function (scope, element, $mdDialog)  {
        
       scope.places = {};
       scope.disabled = false;

      scope.find = function() { 
        //scope.position = "horn lehe";
        console.log('loadMap', scope.position);
       scope.disabled = false;
        if(!scope.position || scope.position.length == 0)
          return;
        var url = 'http://nominatim.openstreetmap.org/search/'+scope.position+'?format=json';
        scope.places = {};
        $http.get(url).success((data) => {
          scope.places = data;
        });

      }

      scope.enter = function () {
        scope.$evalAsync(function () {
            bngApi.engineLua('setCEFFocus(true)');
        });
      };

      scope.loadMap = function(pos) { 
          bngApi.engineLua('util_osm.getGeoData('+pos.lon + "," + pos.lat + ",nil,nil)");

          scope.disabled = true;
      }

      scope.$on('osmFinished',function(event,data) {
        cope.$evalAsync(() => {
          scope.disabled = false;
        });
          console.log('loadMap', "enabled");
      });


       bngApi.engineLua('extensions.load("util_osm")');
    }
  }
}]);