angular.module('beamng.apps')
.directive('indicatedAirspeed', ['bngApi', 'StreamsManager', function (bngApi, StreamsManager) {
  return {
    template: '<canvas width="512" height="512" ng-click="toggleUnit()"></canvas>',
    replace: true,
    link: function (scope, element, attrs) {
      var streamsList = ['electrics'];
      StreamsManager.add(streamsList)
      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      var Unit = localStorage.getItem('apps:indicatedAirspeed.unit') || 'KNOTS';
      scope.toggleUnit = function () {
        Unit = Unit === 'KNOTS' ? 'km/h' : (Unit === 'MPH' ? 'KNOTS' : 'MPH');        
        localStorage.setItem('apps:indicatedAirspeed.unit', Unit);
      };

      var airspeed = 0;

      function callback(res){
          airspeed = res;
      }

      var framesAboveOrBelowMax = 0;

      var showMach = false;
      var fadingOut = false;
      var fadeFrame = 0;

      var FADE_FRAMES = 3;
      var WAIT_FRAMES = 10;


      var canvas = element[0]
        , ctx = canvas.getContext('2d')
      ;

      var minAngle = 0
        , maxAngle = 320
        , minSpeed = 0
        , maxSpeed = 320
      ;

      scope.$on('streamsUpdate', function (event, streams) {
        ctx.clearRect(0, 0, 512, 512);

        // Ring
        ctx.strokeStyle = "RGB(70,70,70)";
        ctx.fillStyle = "RGBA(255,255,255,0.92)";
        ctx.lineWidth = 8;
        ctx.beginPath();
        var radius = 230;
        ctx.arc(256, 256, radius, 0, 2 * Math.PI);
        ctx.closePath();
        ctx.fill();
        ctx.stroke();

        ctx.lineWidth = 5;
        ctx.lineCap = "round";
        ctx.font = "30px Arial";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.strokeStyle = "RGBA(0,0,0,0.6)"; // graduations
        ctx.fillStyle = "RGB(40,40,40)";     // text and needle

        for (var i = minSpeed; i <= maxSpeed; i = i + 10) {
          ctx.save();
          ctx.translate(256, 256);
          var rads = (-90 + minAngle + (i - minSpeed) / (maxSpeed - minSpeed) * (maxAngle - minAngle)) * (Math.PI / 180);
          ctx.rotate(rads);
          ctx.translate(-256, -256);
          ctx.moveTo(256 + radius, 256);
          if (i % 20 == 0) {
            ctx.lineTo(256 + radius - 35, 256);
            if (i != 0) {
              var adjustx = Math.cos(rads) * (ctx.measureText(i).width / 2);
              var adjusty = Math.sin(rads) * (15);
              var adjust = Math.sqrt(adjustx * adjustx + adjusty * adjusty);
              ctx.translate(256 + radius - 42 - adjust, 256);
              ctx.rotate(-rads);
              ctx.fillText(i, 0, 0);
            }
          } else {
            ctx.lineTo(256 + radius - 22, 256); // minors
          }
          ctx.restore();
        }
        ctx.stroke();

        var speedScale;
        if(Unit == 'KNOTS') {
          speedScale = 1.94384;
        } else if (Unit == 'km/h') {
          speedScale = 3.6;
        } else { // MPH
          speedScale = 2.23694;
        }

        bngApi.activeObjectLua('(obj:getDirectionVector():dot(obj:getVelocity() - obj:getFlow())) * math.sqrt(obj:getDensityAtNode(0) / 1.225)', callback);
        var displaySpeed = Math.max(airspeed * speedScale, 0);

        // Animate the fade between for mach number display at high speeds
        if (fadeFrame > 0) {
            if (--fadeFrame == 0 && fadingOut) {
                // If we've totally faded out, start fading back in
                fadingOut = false;
                fadeFrame = FADE_FRAMES;
                showMach = framesAboveOrBelowMax > 0;
            }
        } else {
            if (!showMach && displaySpeed > maxSpeed) {
                framesAboveOrBelowMax++;
                if (framesAboveOrBelowMax > WAIT_FRAMES) {
                    fadeFrame = FADE_FRAMES;
                    fadingOut = true;
                }
            } else if (showMach && displaySpeed < maxSpeed - 10) {
                framesAboveOrBelowMax--;
                if (-framesAboveOrBelowMax > WAIT_FRAMES) {
                    fadeFrame = FADE_FRAMES;
                    fadingOut = true;
                }
            } else {
                framesAboveOrBelowMax = 0;
            }
        }

        ctx.fillStyle = "black";
        ctx.font = "26px Arial";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";

        ctx.save();
        if (fadingOut)
            ctx.globalAlpha = fadeFrame / FADE_FRAMES;
        else
            ctx.globalAlpha = 1 - fadeFrame / FADE_FRAMES;

        if (showMach) {
            var speedOfSound = 340.29 - streams.electrics.altitude * .00408;
            ctx.fillText("MACH", 256, 170);
            ctx.fillText((airspeed / speedOfSound).toFixed(2), 256, 200);
        }
        else {
            ctx.fillText("AIRSPEED", 256, 206);
        }
        ctx.restore();

        // unit label
        // ctx.fillText(this.persistance.Unit, 256, 306);
        ctx.fillText(Unit, 256, 306);

        // Draw the needle
        ctx.save();
        ctx.translate(256, 256);
        var rads = (-90 + minAngle + (displaySpeed - minSpeed) / (maxSpeed - minSpeed) * (maxAngle - minAngle)) * (Math.PI / 180);
        ctx.rotate(rads);
        ctx.beginPath();
        ctx.moveTo(0, -5);
        ctx.lineTo(radius - 100, -5);
        ctx.lineTo(radius - 95, -2);
        ctx.lineTo(radius - 20, -2);
        ctx.lineTo(radius - 20, 2);
        ctx.lineTo(radius - 95, 2);
        ctx.lineTo(radius - 100, 5);
        ctx.lineTo(0, 5);
        ctx.closePath();
        ctx.fill();

        // Draw base of needle
        ctx.fillStyle = "RGB(255,255,255)";
        ctx.beginPath();
        ctx.arc(0, 0, 11, 0, 2*Math.PI);
        ctx.closePath();
        ctx.fill();
        ctx.stroke();
        ctx.restore();
      });

      scope.$on('app:resized', function (event, data) {
        var size = Math.min(data.width, data.height);
        canvas.height = size;
        canvas.width = size;
        ctx.scale(size/512, size/512);
      });
    }
  };
}]);