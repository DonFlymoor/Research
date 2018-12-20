angular.module('beamng.apps')
.directive('simpleSteering', ['StreamsManager', function (StreamsManager) {
  return {
    template:
      '<object style="width:100%; height:100%; pointer-events: none" type="image/svg+xml" data="modules/apps/SimpleSteering/simple-steering.svg?t=' + Date.now() + '"></object>',
    replace: true,
    link: function (scope, element, attrs) {
      var streamsList = ['sensors'];
      StreamsManager.add(streamsList);
      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      element.on('load', function () {
        var svg    = element[0].contentDocument
          , wheel  = svg.getElementById('wheel')
          , helper = svg.getElementById('bounding-rect')
          , bbox   = wheel.getBBox()
          , rotateOriginStr = ' ' + (bbox.x + bbox.width/2) + ' ' + (bbox.y + bbox.height/2)
          , barRight = svg.getElementById('bar-right')
          , barLeft  = svg.getElementById('bar-left')
          , hFactor = svg.getElementById('bar-outer').getAttribute('width') / 2
        ;

        scope.$on('streamsUpdate', function (event, streams) {
          if (!streams.electrics) return;
          wheel.setAttribute('transform', 'rotate(' + (-streams.electrics.steering) + rotateOriginStr + ')');
          var steeringRaw = streams.electrics.steering_input;

          if (steeringRaw > 0) {
            barRight.setAttribute('width', steeringRaw * hFactor);
            barLeft.setAttribute('width', 0)
          } else {
            barRight.setAttribute('width', 0)
            barLeft.setAttribute('width', -steeringRaw * hFactor);
          }
        });
      });
    }
  };
}]);