

angular.module('gaugesScreen', [])
.controller('GaugesScreenController', function($scope, $window) {
  var unit = null;
  $scope.data = {}
  // overwriting plain javascript function so we can access from within the controller
  $window.setUnits = (data) => {
    unit = data.unitType;
  }
  
  $window.updateData = (data) => {
    $scope.$evalAsync(function() {
      // We need access to the efficiency bar svg element so that we can animate it
      var eff = document.getElementById("efficiency");
      value = data.fuelDisplay;
      // dash array needs to be the same as the circumference of the circle (radius * 2 * PI)
      eff.style.strokeDasharray = 342

      if (value > 0) {
        // We need to add the value to the negative circumference of the circle so that we can fill up the bar
        eff.style.strokeDashoffset = -342 + value.toFixed(2) * 23
        eff.style.stroke = "#BD362F";
      }
      else {
        eff.style.strokeDashoffset = -342 + value.toFixed(2) * 23
        eff.style.stroke = "#295AAC";
      }

      if (data.gear === -1) {
        $scope.data.gear = "R";
      }
      else if (data.gear === 0) {
        $scope.data.gear = "N";
      }
      else {
        $scope.data.gear = data.gear;
      }

      $scope.data.time = data.time;

      // checking if metric gauge cluster is being used
      if (unit === "metric") {
        $scope.data.speedVal = (data.speed * 3.6).toFixed(0);
        $scope.data.speedUnit = "km/h";
        if (data.temp.toFixed(1) > 99.9 || data.temp.toFixed(1) < -99.9) {
					$scope.data.temp = "---°C";
				}
				else {
					$scope.data.temp = data.temp.toFixed(1) + "°C";
        }
        if (data.averageFuelConsumption === 0) {;
          $scope.data.consumptionVal = "---"
				}
				else {
          $scope.data.consumptionVal = data.averageFuelConsumption.toFixed(1)
				}
        $scope.data.consumptionUnit = "l/100km";
      }
      else {
        $scope.data.speedVal = (data.speed * 2.23694).toFixed(0);
				$scope.data.speedUnit = "mph";
        $scope.data.temp = (data.temp * 1.8 + 32).toFixed(0) + "°F";
				if (data.averageFuelConsumption === 0) {
					$scope.data.consumptionVal = "---";
				}
				else {
					$scope.data.consumptionVal = (235 / data.averageFuelConsumption).toFixed(1);
				}
        $scope.data.consumptionUnit = "mpg";
        // A bit ugly but need to set the markers on the SVG for imperial or metric units
        document.getElementById('markOne').textContent = "30";
        document.getElementById('markTwo').textContent = "20";
        document.getElementById('markThree').textContent = "10";
        document.getElementById('markFour').textContent = "0";
      }
    })
  }
});    