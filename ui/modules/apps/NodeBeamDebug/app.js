angular.module('beamng.apps')
.directive('nodeBeamDebug', ['UiUnits', function (UiUnits) {
  return {
    template:
    '<div style="height:100%; width:100%;" class="bngApp">' +
      '{{ beams.total }} beams<br>' +
      ' - {{ beams.deformed.number }}  ({{ beams.deformed.percentage.toFixed(2) }} %) deformed<br>' +
      ' - {{ beams.broken.number }} ({{ beams.broken.percentage.toFixed(2) }} %) broken<br><br>' +
      '{{ numNodes }} nodes<br>' +
      ' - {{ weight.total}} total weight <br>' +
      ' - {{ weight.wheels.average}} per wheel<br>' +
      ' - ({{ weight.wheels.total}} all {{ weight.wheels.count }} wheels)<br>' +
      ' - {{ (weight.chassis)}} chassis weight<br><br>' +
      '{{ triCount }} triangles<br>' +
      ' - {{ (collTriCount)}} collidable<br>' +
    '</div>',
    replace: true,
    restrict: 'EA',
    scope: true,
    controller: ['$log', '$scope', 'bngApi', 'StreamsManager', function ($log, $scope, bngApi, StreamsManager) {
      var streamsList = ['stats'];
      StreamsManager.add(streamsList);
      $scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      $scope.numNodes = 0;
      $scope.weight = {
        total: '',
        wheels: { average: '', total: '', count: ''}
      };

      $scope.beams = {
        total: '-',
        deformed: { number: '', percentage: ''},
        broken: { number: '', percentage: ''}
      };

      $scope.$on('streamsUpdate', function (event, data) {
        $scope.$evalAsync(function () {
          if (data.stats != null) {
            $scope.beams.total    = data.stats.beam_count;
            $scope.beams.deformed = { number: data.stats.beams_deformed, percentage: data.stats.beams_deformed/data.stats.beam_count * 100 };
            $scope.beams.broken   = { number: data.stats.beams_broken, percentage: data.stats.beams_broken/data.stats.beam_count * 100 };

            $scope.numNodes      = data.stats.node_count;
            $scope.weight.total  = UiUnits.buildString('weight', data.stats.total_weight, 2) ;
            $scope.weight.wheels = {
              total: UiUnits.buildString('weight', data.stats.wheel_weight, 2),
              count: data.stats.wheel_count,
              average: UiUnits.buildString('weight', (data.stats.wheel_weight / data.stats.wheel_count), 2)
            };
            $scope.weight.chassis = UiUnits.buildString('weight', data.stats.total_weight - data.stats.wheel_weight, 2);
            
            $scope.triCount = data.stats.tri_count;
            $scope.collTriCount = data.stats.collidable_tri_count;
          }
          else {
            return;
          }
        });
      });
    }]
  };
}]);