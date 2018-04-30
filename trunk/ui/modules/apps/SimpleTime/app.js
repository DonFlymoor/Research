angular.module('beamng.apps')
	.directive('simpleTime', ['bngApi', 'StreamsManager', 'UiUnits', function (bngApi, StreamsManager, UiUnits) {
		return {
			template:
        '<div style="width:100%; height:100%;" layout="column" layout-align="center center" class="bngApp">' +
          '<span style="font-size:1.3em">{{ currentTime }}</span>' +
        '</div>',
			replace: true,
			link:
			function (scope, element, attrs) {
				var streamsList = ['electrics'];
				StreamsManager.add(streamsList);

				scope.$on('streamsUpdate', function (event, data) {
					scope.$evalAsync(function () {
						var currentDate = new Date(); 
						var currentHour = currentDate.getHours();
						var currentMinute = currentDate.getMinutes();

						if (currentMinute < 10) {
							currentMinute = "0" + currentMinute;
						}
						
						scope.currentTime = currentHour + ":" + currentMinute;
					})
				});

				scope.$on('$destroy', function () {
					StreamsManager.remove(streamsList);
				});
			}
		};
	}])
