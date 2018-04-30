angular.module('beamng.apps')
.directive('weightDistribution', ['bngApi', 'CanvasShortcuts', 'StreamsManager', 'UiUnits', function (bngApi, CanvasShortcuts, StreamsManager, UiUnits) {
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

        if (!sortedWheelIndices || value.length != sortedWheelIndices.length)
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
        7  drivetrain.wheelInfo[wd.wheelID].downForce
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
        var totalDownForce = 0;
        var nwheels = sortedWheelIndices.length;

        for(var j in value)
          totalDownForce += value[j][7];

        for(var i in sortedWheelIndices) {
          wheelCount++;
          var w = value[sortedWheelIndices[i]];
          var downForce = w[7];
          // then draw
          CanvasShortcuts.circle(ctx, x, y, r, 1, 'rgb(0, 0, 0)', 'rgba(0, 0, 0, 0.43)'); // max circle size marker (currently double the regular weight distribution)

          if ((downForce/totalDownForce)*nwheels < 1)
              CanvasShortcuts.filledArc(ctx, x, y, r/2, 1, 1, "rgba(0, 0, 0, 0.43)"); // regular weight distribution marker

          var gradient = ctx.createRadialGradient(x, y, 0, x, y, r);
          gradient.addColorStop(0, 'RGBA(0,255,0,0.5)');
          gradient.addColorStop(0.4, 'RGBA(0,255,0,0.5)');
          gradient.addColorStop(0.6, 'RGBA(255,0,0,0.5)');
          gradient.addColorStop(1, 'RGBA(255,0,0,0.5)');
          ctx.fillStyle = gradient;

          ctx.beginPath();
          ctx.arc(x, y, (downForce/totalDownForce)*nwheels*(r/2), 0, 2 * Math.PI);
          ctx.fill();

          ctx.fillStyle = '#ffffff';

          ctx.fillText(w[0], x, y - ((fontSize + 0)/2));
          ctx.fillText(Math.round((downForce/totalDownForce)*100 ) + ' %', x, y + ((fontSize + 0)/1));

          ctx.fillText(UiUnits.buildString('weight', (downForce / 9.81), 0), x, y - r + (fontSize*2));
          ctx.fillText(Math.round(downForce) + ' N', x, y + r - (fontSize*1));

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

      setTimeout(function () {
        bngApi.engineLua('settings.requestState()');
      }, 200);
    }
  };
}]);