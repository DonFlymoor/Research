angular.module('beamng.apps')
.directive('taxiStats', ['bngApi', function (bngApi) {
  return {
    templateUrl: 'modules/apps/TaxiStats/app.html',
    replace: true,
    link: function (scope, element, attrs) {
      var vm = this;
      scope.total = 0;
      scope.fare_ = 0;
      scope.tip_ = 0;

      scope.objectiveColor;
      scope.customerColor = 'rgb(255, 255, 255)';

      scope.stats = null;

      var countDown = 2;

      bngApi.engineLua('extensions.load("core_taxidriver")');

      scope.formatNumber = function(i, sig) {
        return Math.round(i * sig)/sig;
      }

      var counter = setInterval(function() {
        if (countDown > 0)
          return;
        if (scope.fare_ > 1) {
          scope.total += 1;
          scope.fare_ -= 1;
        } else if (scope.tip_ > 1) {
          scope.fare_ = 0;
          scope.total += 1;
          scope.tip_ -= 1;
        } else {
          scope.fare_ = 0;
          scope.tip_ = 0;
          scope.total = scope.stats.earnings;
        }
      }, 100);

      var coolTime = setInterval(function() {
        if (countDown > 0)
          countDown--;
      }, 1000);

      scope.$on('TaxiStatsUpdate', function(evt, data) {
        scope.$evalAsync(function() {
          scope.stats = data;
          scope.customerColor = 'rgb('+scope.formatNumber(scope.stats.passengerColor[0]*255, 1)+','+scope.formatNumber(scope.stats.passengerColor[1]*255, 1)+','+scope.formatNumber(scope.stats.passengerColor[2]*255, 1)+')';

          if (countDown == 0) {
            scope.g = scope.stats.g
            if ((scope.stats.timeLeft <= 20 && scope.stats.mood === 1) || (scope.stats.g > 0.8 && scope.stats.mood === 2)) {
              scope.objectiveColor = '#FFB300';
            }
            else {
              scope.objectiveColor = '#FFFFFF';
            }
          }
          if ((scope.stats.timeLeft <= 10 && scope.stats.mood === 1) || (scope.stats.g > 5 && scope.stats.mood === 2)) {
            scope.objectiveColor = '#F44336';
            //countDown = 2;
          }
        })
      });

      scope.$on('TaxiStatsSum', function(evt) {
        scope.$evalAsync(function() {
          countDown = 2;
          if (scope.stats.fare != null)
            scope.fare_ = scope.stats.fare
          if (scope.stats.tip != null) {
            scope.tip_ = scope.stats.tip
          }
        })
      });

      scope.$on('$destroy', function () {
        bngApi.engineLua('extensions.unload("core_taxidriver")');
      });
    }
  };
}]);