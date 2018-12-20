angular.module('beamng.apps')
.directive('simpleDash', ['bngApi', 'StreamsManager', function (bngApi, StreamsManager) {
  return {
    template:
      '<object class="bngApp" style="width:100%; height:100%;" type="image/svg+xml" data="modules/apps/SimpleDash/simple-dash.svg?t=' + Date.now() + '"></object>',
    replace: true,
    link: function (scope, element, attrs) {
      var streamsList = ['electrics'];

      StreamsManager.add(streamsList);
      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      element.on('load', function () {
        var svg    = element[0].contentDocument
          , fuelbar = svg.getElementById('fuelbar')
          , fuelFactor = svg.getElementById('fuelbar_border').getAttribute('height')
          , hbrake = { outer: svg.getElementById('hbrake_outer'),
                       inner: svg.getElementById('hbrake_inner')
                     }
          , lblink = svg.getElementById('blink_left')
          , rblink = svg.getElementById('blink_right')
          , abs = { outer: svg.getElementById('abs_outer'),
                    inner: svg.getElementById('abs_inner')
                  }
          , lights = svg.getElementById('lights')
        ;

        lblink.addEventListener('click', function () {
          bngApi.activeObjectLua('electrics.toggle_left_signal()');
        });

        rblink.addEventListener('click', function () {
          bngApi.activeObjectLua('electrics.toggle_right_signal()');
        });

        lights.addEventListener('click', function () {
          bngApi.activeObjectLua('electrics.toggle_lights()');
        });

        hbrake.outer.addEventListener('click', function () {
          bngApi.activeObjectLua('input.toggleEvent("parkingbrake")');
        });

        scope.$on('streamsUpdate', function (event, streams) {

          // Fuel
          if (streams.electrics.lowfuel)
            fuelbar.style.fill="#FF8000";
          else
            fuelbar.style.fill="rgba(0,0,128,0.7)";

          fuelbar.setAttribute('height', streams.electrics.fuel  * fuelFactor);

          // Handbrake
          if (streams.electrics.parkingbrake > 0.5) {
            hbrake.outer.style.stroke="#FF8000";
            hbrake.inner.style.fill="#FF8000";
          } else {
            hbrake.outer.style.stroke="rgba(255, 255, 255, 0.9)";
            hbrake.inner.style.fill="rgba(255, 255, 255, 0.9)";
          }

          // Left Blinker
          if (streams.electrics.signal_L > 0.5)
            lblink.style.fill="rgba(0, 255, 0, 0.6)";
          else
            lblink.style.fill="rgba(255, 255, 255, 0.9)";

          // Right Blinker
          if (streams.electrics.signal_R > 0.5)
            rblink.style.fill="rgba(0, 255, 0, 0.6)";
          else
            rblink.style.fill="rgba(255, 255, 255, 0.9)";

          // ABS
          if (streams.electrics.abs > 0.5) {
            abs.inner.style.fill="#FF8000";
            abs.outer.style.stroke="#FF8000";
          } else {
            abs.inner.style.fill="rgba(255, 255, 255, 0.9)";
            abs.outer.style.stroke="rgba(255, 255, 255, 0.9)";
          }

          // Headlights
          if (streams.electrics.lights < 0.1)
            lights.style.fill="rgba(255, 255, 255, 0.9)";
          else if (streams.electrics.lights < 1.1)
            lights.style.fill="rgba(0, 255, 0, 0.6)";
          else
            lights.style.fill="#00f";
        });
      });
    }
  };
}]);