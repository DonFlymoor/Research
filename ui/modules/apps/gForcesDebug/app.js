angular.module('beamng.apps')
.directive('gforcesDebug', ['StreamsManager', function (StreamsManager) {
  return {
    template: '<canvas width="300" height="300"></canvas>',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      var streamsList = ['sensors'];
      StreamsManager.add(streamsList);
    
      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      var c = element[0]
        , ctx = c.getContext('2d')
        , history = []
        , historySize = 100
        , maxG = 2
        , circleSize = 100 / maxG
        , circleRadius = 2
      ;

      ctx.setTransform(c.width/200, 0, 0, c.height/200, c.width/2,c.height/2);

      scope.$on('streamsUpdate', function (event, streams) {
        var gForces = {};

        for (var key in streams.sensors) {
            gForces[key] = streams.sensors[key] / 9.81;
        }

        // var c = this.canvas[0];
        // var ctx = c.getContext('2d');
        ctx.font = '12px "Lucida Console", Monaco, monospace';
        ctx.textAlign = "right";
        ctx.textBaseline = "middle";

        ctx.clearRect(-100,-100,200,200);
        // ctx.clearRect(0, 0, 300, 300);

        // Circles
        ctx.strokeStyle = "RGBA(0,0,0,0.2)";
        ctx.lineWidth =1;
        ctx.fillStyle = "RGBA(0,0,0,0.2)";

        ctx.fillStyle = "RGBA(0,0,0,0.2)";
        for (var i = 1; i <= maxG; i++) {
            ctx.beginPath();
            ctx.arc(0,0,circleSize*i,0,2*Math.PI,false);
            ctx.fill();
            ctx.stroke();
        }

        // Min/Max-g's
        ctx.strokeStyle = "RGBA(0,0,255,0.7)";
        ctx.lineWidth = 2;
        ctx.lineCap = "";

        ctx.beginPath();
        ctx.moveTo(gForces.gxMin * circleSize, 0);
        ctx.lineTo(gForces.gxMax * circleSize, 0);
        ctx.stroke();

        ctx.beginPath();
        ctx.moveTo(0,gForces.gyMin * -circleSize);
        ctx.lineTo(0,gForces.gyMax * -circleSize);
        ctx.stroke();


        // Labels
        ctx.fillStyle = "RGBA(0,0,0,0.7)";
        for (var i = 1; i <= maxG; i++) {
            ctx.fillText(i+"g",circleSize*i-5,0);
        }
        
        ctx.fillStyle = "RGBA(255,0,0,0.5)";
        ctx.beginPath();
        ctx.arc(gForces.gx*circleSize, gForces.gy*-circleSize, circleRadius, 0, 2*Math.PI, false);
        ctx.fill();

        ctx.fillStyle = "RGBA(0,255,0,1)";

        var px = gForces.gx2 *  circleSize;
        var py = gForces.gy2 * -circleSize;
        
        ctx.beginPath();
        ctx.arc(px, py, circleRadius, 0, 2*Math.PI, false);
        ctx.fill();
        
        ctx.fillStyle = "RGBA(255,255,255,1)";
        ctx.fillText(gForces.gx2.toFixed(2) + 'gx', -50, 0);
        ctx.fillText(gForces.gy2.toFixed(2) + 'gy',  20, 90);
        ctx.fillText(Math.sqrt(gForces.gx2 * gForces.gx2 + gForces.gy2 * gForces.gy2).toFixed(2) + 'g', 80, 50);

        // draw history track
        if(history.length > 0) {
            for(var i = 1; i < history.length; i++) {
                ctx.beginPath();
                ctx.lineWidth = 1 + (2*i/history.length);
                ctx.strokeStyle = "RGBA(255,255,0," + ((i/history.length) + 0.3) + ")";
                ctx.moveTo(history[i-1][0], history[i-1][1]);
                ctx.lineTo(history[i][0], history[i][1]);
                ctx.stroke();
            }
            if(history.length > historySize) {
                history.splice(0, 1);
            }
            var sx = Math.abs(history[history.length - 1][0] - px);
            var sy = Math.abs(history[history.length - 1][1] - py);
            if(sx > 2 || sy > 2) {
                history.push([px, py]);
            }
        } else {
            history.push([px, py]);
        }
      });

      scope.$on('app:resized', function (event, data) {
        c.width = data.width;
        c.height = data.height;
        ctx.setTransform(c.width/200, 0, 0, c.height/200, c.width/2,c.height/2);
      });
    }
  };
}]);