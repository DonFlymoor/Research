angular.module('beamng.apps')
/**
 * @ngdoc directive
 * @name beamng.apps:simpleRpmDebug
 * @description A simple canvas-based app, which shows current RPM 
 * in relation to specified values for idle, shiftdown, shiftup and maximum engine RPM
**/
.directive('simpleRpmDebug', ['StreamsManager', function (StreamsManager) {
  return {
    template: '<canvas width="150" height="150"></canvas>',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      var streamsList = ['engineInfo'];
      StreamsManager.add(streamsList);
      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      var c = element[0]
        , ctx = c.getContext('2d')
      ;

      scope.$on('streamsUpdate', function (event, streams) {
        //Get the values to work with, do rounding and stuff as needed
        var idleRPM    = streams.engineInfo[0]
          , maxRPM     = streams.engineInfo[1]
          , shiftUpRPM = streams.engineInfo[2]
          , shiftDnRPM = streams.engineInfo[3]
          , curRPM     = streams.engineInfo[4]
        ;

        //clear before drawing stuff on canvas
        ctx.clearRect(0, 0, c.width*2, c.height*2);

        //background circle
        ctx.arc(c.width/2, c.height/2, c.height*0.5, 0, 2*Math.PI);
        ctx.fillStyle = "RGBA(255,255,255,0.9)";
        ctx.fill();

        //currentRPM
        ctx.beginPath();
        ctx.arc(c.width/2, c.height/2, c.height*0.4, 0.5*Math.PI, 0.5*Math.PI+curRPM/maxRPM*2*Math.PI);
        ctx.lineWidth = Math.min(c.height, c.width)/10;
        ctx.strokeStyle = "RGBA(128,128,128,0.75)";
        ctx.stroke();

        //idle RPM
        ctx.beginPath();
        ctx.moveTo(c.width/2, c.height/2);
        ctx.arc(c.width/2, c.height/2, c.height*0.4, 0.5*Math.PI, 0.5*Math.PI+idleRPM/maxRPM*2*Math.PI);
        ctx.lineTo(c.width/2, c.height/2);
        ctx.fillStyle = "RGBA(0,0,0,0.5)";
        ctx.fill();

        //shift dn RPM
        ctx.beginPath();
        ctx.moveTo(c.width/2, c.height/2);
        ctx.arc(c.width/2, c.height/2,c.height*0.4, 0.5*Math.PI+idleRPM/maxRPM*2*Math.PI, 0.5*Math.PI+shiftDnRPM/maxRPM*2*Math.PI);
        ctx.lineTo(c.width/2, c.height/2);
        ctx.fillStyle = "RGBA(0,0,255,0.5)";
        ctx.fill();

        //shift up RPM
        ctx.beginPath();
        ctx.moveTo(c.width/2, c.height/2);
        ctx.arc(c.width/2, c.height/2, c.height*0.4, 0.5*Math.PI+shiftDnRPM/maxRPM*2*Math.PI, 0.5*Math.PI+shiftUpRPM/maxRPM*2*Math.PI);
        ctx.lineTo(c.width/2, c.height/2);
        ctx.fillStyle = "RGBA(255,0,255,0.5)";
        ctx.fill();

        //max RPM
        ctx.beginPath();
        ctx.moveTo(c.width/2, c.height/2);
        ctx.arc(c.width/2, c.height/2, c.height*0.4, 0.5*Math.PI+shiftUpRPM/maxRPM*2*Math.PI, 0.5*Math.PI+maxRPM/maxRPM*2*Math.PI);
        ctx.lineTo(c.width/2, c.height/2);
        ctx.fillStyle = "RGBA(255,0,0,0.5)";
        ctx.fill(); 
      });

      scope.$on('app:resized', function (event, data) {
        c.width = data.width;
        c.height = data.height;
      });
    }
  };
}]);