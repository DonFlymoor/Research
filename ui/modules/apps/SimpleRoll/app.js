angular.module('beamng.apps')
.directive('simpleRoll', ['StreamsManager', function (StreamsManager) {
  return {
    template: 
        '<object  style="width:100%; height:100%; pointer-events: none" type="image/svg+xml" data="modules/apps/SimpleRoll/simple-roll.svg?t=' + Date.now() + '"/>',
    replace: true,
    link: function (scope, element, attrs) {
      var streamsList = ['sensors'];
      StreamsManager.add(streamsList);
      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      element.on('load', function () {
        var svg    = element[0].contentDocument
          , circle = svg.getElementById('circle')
          , bbox   = circle.getBBox()
          , rotateOriginStr = ' ' + (bbox.x + bbox.width/2) + ' ' + (bbox.y + bbox.height/2)
          , rollDegrees     = 0
          , rollText        = svg.getElementById('roll-text');

        scope.$on('streamsUpdate', function (event, streams) {
          rollDegrees = Math.asin(streams.sensors.roll) * (180 / Math.PI);
          circle.setAttribute('transform', 'rotate(' + rollDegrees + rotateOriginStr + ')');
          rollText.innerHTML = rollDegrees.toFixed(1) + ' &#176;';
        });

      });
    }
  };
}]);