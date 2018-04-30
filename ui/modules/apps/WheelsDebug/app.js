angular.module('beamng.apps')
.directive('wheelsDebug', ['CanvasShortcuts', 'StreamsManager', 'UiUnits', function (CanvasShortcuts, StreamsManager, UiUnits) {
  return {
    template: '<canvas width="220"></canvas>',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      var streamsList = ['wheelInfo'];
      StreamsManager.add(streamsList);
      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      var c = element[0]
        , ctx = c.getContext('2d')
      ;

      var sortedWheelIndices = null;

      var _sortedWheelIndicesFunc = function (wheelInfo){ // TODO: duplicated in WeightDistribution app
        function getWheelNames(wheelInfo){
          var names=[];
          for(var i in wheelInfo)
            names.push(wheelInfo[i][0]);
          return names;
        }

        function wheelNamesToIndices(wheelInfo, wheelNames){
          var indices=[];
          for(var i in wheelNames)
            for(var j in wheelInfo)
              if (wheelNames[i] == wheelInfo[j][0])
                indices.push(j);
          return indices;
        }
        return wheelNamesToIndices(wheelInfo, getWheelNames(wheelInfo).sort()); // alphabetical sort suits our needs: FL < FR < RL < RR
      };

      scope.$on('streamsUpdate', function (event, streams) {
        var value = streams.wheelInfo;

        if (!sortedWheelIndices || (value && value.length != sortedWheelIndices.length))
          sortedWheelIndices = _sortedWheelIndicesFunc(value);

        var wheelCount = 0;
        /* value format:
        0  wd.name
        1  wd.radius
        2  wd.wheelDir
        3  w.angularVelocity
        4  w.lastTorque
        5  drivetrain.wheelInfo[wd.wheelID].lastSlip
        6  wd.lastTorqueMode
        */

        // clear
        ctx.setTransform(1, 0, 0, 1, 0, 0);
        ctx.clearRect(0, 0, c.width, c.height);
        ctx.textAlign = 'center';
        var fontSize = 11;
        ctx.font = fontSize + 'pt "Lucida Console", Monaco, monospace';
        var r = 50;
        var rs = 5;
        var b = 5;
        var x = r + b;
        var y = r + b;
        for(var i in sortedWheelIndices) {
          wheelCount++;
          var w = value[sortedWheelIndices[i]];

          // then draw
          CanvasShortcuts.circle(ctx, x, y, r, 1, 'rgb(0, 0, 0)', 'rgba(0, 0, 0, 0.43)');
          ctx.fillStyle = '#ffffff';
          ctx.fillText(w[0], x, y);

          var wheelSpeed = w[3] * w[1] * w[2];
          ctx.fillText(UiUnits.buildString('speed', wheelSpeed, 2) , x, y + fontSize + 3);
          CanvasShortcuts.filledArc(ctx, x, y, r - 1, rs, wheelSpeed/33, 'rgba(0, 0, 255, 0.7)'); // outer rubber speed

          CanvasShortcuts.filledArc(ctx, x, y, r - 1 - rs, rs, w[5]/10 , 'rgba(255, 255, 255, 0.7)'); // absolute slip

          var torque = (w[4] * w[2]) / 10000;
          var col = 'rgba(255,0,0,0.5)'; // no brake input, net brake (probably engine braking)
          if (torque > 0)
            col = 'rgba(0,255,0,0.5)'; // no brake input, net acceleration (probably throttle)
          if(w[6] == 1) {
            col = 'rgba(255,0,0,0.5)'; // foot brake
          } else if(w[6] == 2) {
            col = 'rgba(255,255,0,0.5)'; // hand brake
          }

          CanvasShortcuts.filledArc(ctx, x, y, r - 1 - rs * 2, rs, torque, col); // net force

          x += 2 * r +  5;

          if(x + r >= c.width) {
              x = r + b;
              y += 2 * r + 5;
            }
        }

        //Calculating height:
        var wheelRows = Math.ceil(wheelCount/2);
        var height =  wheelRows * ( 2 * r  + 5);
        if(c.height != height)
            c.height = height;
      });

      scope.$on('VehicleChange', function (event, data) {
        sortedWheelIndices = null;
      });

      scope.$on('app:resized', function (event, data) {
        c.width = data.width;
        c.height = data.height;
      });
    }
  };
}]);