angular.module('beamng.apps')
.directive('forceFeedback', ['StreamsManager', function (StreamsManager) {
  return {
    template: 
        '<object class="bngApp" style="max-width:100%; max-height:100%; pointer-events: none" type="image/svg+xml" data="modules/apps/ForceFeedback/force-feedback.svg?t=' + Date.now() + '"/>',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {      
      var streamsList = ['sensors'];
      StreamsManager.add(streamsList);
      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });
      
      element.on('load', function () {
        var svg = element[0].contentDocument
          , txt    = svg.getElementById('valText')
          , barPos = svg.getElementById('bar-positive')
          , barNeg = svg.getElementById('bar-negative')
          , scale = 1
          , hFactor = svg.getElementById('outer').getAttribute('width') / 2
        ;

        scope.$on('streamsUpdate', function (event, streams) {
          var val = streams.sensors.ffb || 0
          scale = Math.max(Math.abs(val), scale);

          if (val > 0) {
            barPos.setAttribute('width', val * hFactor / scale);
            barNeg.setAttribute('width', 0);  
          } else {
            barPos.setAttribute('width', 0);
            barNeg.setAttribute('width', -val * hFactor / scale);
          }
        
          txt.innerHTML = val.toFixed(2);
        });
      }); 
    }
  };
}]);