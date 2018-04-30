angular.module('beamng.apps')
.directive('escDesiredYawGraph', ['CanvasShortcuts', 'StreamsManager', function (CanvasShortcuts, StreamsManager) {
  return {
    template: `
        <div style="width:100%; height:100%; position:relative; background-color: rgba(255,255,255,0.9)">
          <canvas style="position:absolute; top: 0; left: 0" width="150" height="150"></canvas>
          <div class="md-caption" style="position: absolute; width: 180px; height:auto; top: 12px; right: 2px; padding: 2px; background-color: rgba(255, 255, 255, 0.9)">
            <span style="font-family: monospace; color: #E08E1B">Acceleration:</span> {{ accVal.toFixed(2) || '---'}} rad/s<br>
            <span style="font-family: monospace; color: #38659D">Steering:</span> {{ steerVal.toFixed(2) }} rad/s
          </div>
          <canvas style="position:absolute; top: 0; left: 0" width="150" height="150"></canvas>
        <div>`,
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      var streamsList = ['escData'];
      StreamsManager.add(streamsList);
      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      var gotData = true
        , isReady = false
        , maxX = 50, maxY = 4
      ;

      scope.accVal = 0.0;
      scope.steerVal = 0.0; 

      var canvas = element[0].getElementsByTagName('canvas')[0]
        , ctx = canvas.getContext('2d')
        , plotMargins = {top: 10, bottom: 15, left: 15, right: 10}
        , gridParams = {color: 'rgba(0,0,0,0.4)', width: 1}
      ;

      var dCanvas = element[0].getElementsByTagName('canvas')[1]
        , dctx = dCanvas.getContext('2d');

      var plotGrid = function () {
        CanvasShortcuts.plotAxis(ctx, 'left',  [0, 4], [0, 1, 2, 3, 4], plotMargins, {values: [1, 2, 3], color: 'grey'}, 'black');
        CanvasShortcuts.plotAxis(ctx, 'right', [], [], plotMargins, null)
        CanvasShortcuts.plotAxis(ctx, 'top', [], [], plotMargins, null);
        CanvasShortcuts.plotAxis(ctx, 'bottom', [0, 50], [0, 10, 20, 30, 40, 50], plotMargins, {values: [10, 20, 30, 40], color: 'grey'}, 'black');  
      };
      
      scope.$on('streamsUpdate', function (event, streams) {
        dctx.clearRect(0, 0, dCanvas.width, dCanvas.height);
        
        if (!streams.escData || !streams.escData.accelerationCurve || !streams.escData.steeringCurve)
          return;

        var accelerationCurve = streams.escData.accelerationCurve
          , steeringCurve     = streams.escData.steeringCurve
          , i = 0;
        // console.log(steeringCurve);

        
        // 4 is the max y value: don't plot values above it (clipping looks awful)
        while (accelerationCurve[i] > 4) i++;

        var speed = Math.min(streams.escData.speed, 50);
        scope.$evalAsync(function () {
          
          var smallIndex = Math.floor(speed)
            , bigIndex   = Math.ceil(speed);

          scope.accVal = (speed - smallIndex) * accelerationCurve[smallIndex] + (bigIndex - speed) * accelerationCurve[bigIndex];
          scope.steerVal = (speed - smallIndex) * steeringCurve[smallIndex] + (bigIndex - speed) * steeringCurve[bigIndex];

          if (scope.accVal > 10000) scope.accVal = '---';
        });
        
        var x = plotMargins.left + speed * (dCanvas.width - plotMargins.left - plotMargins.right) / 50;
        dctx.strokeStyle = 'red';
        dctx.lineWidth = 1;
        dctx.beginPath();
        dctx.moveTo(x, plotMargins.top);
        dctx.lineTo(x, dCanvas.height - plotMargins.bottom);
        dctx.stroke();


        CanvasShortcuts.plotData(dctx, accelerationCurve, 0, 4, {margin: plotMargins, lineWidth: 2, lineColor: '#E08E1B', minIndex: i});
        CanvasShortcuts.plotData(dctx, steeringCurve, 0, 4, {margin: plotMargins, lineWidth: 3, lineColor: '#38659D'});
      });

      scope.$on('app:resized', function (event, data) {
        canvas.width = data.width;
        canvas.height = data.height;
        dCanvas.width = data.width;
        dCanvas.height = data.height;
        plotGrid();
      });


      
    }
  }
}]);



// ESCDesiredYawGraph.prototype.update = function(streams){
//     this.steeringCurve = streams.escData.steeringCurve;
//     this.accelerationCurve = streams.escData.accelerationCurve;
//     this.maxSpeed = streams.escData.maxSpeed;

//     //build data for plot
//     var steeringData = [];
//     for (var i = 0; i < this.maxSpeed; i++) {
//         steeringData.push([i,this.steeringCurve[i]]);
//     }
//     steeringData.push([this.maxSpeed,this.steeringCurve[this.maxSpeed]]);

//     var accelerationData = [];
//     for (var i = 0; i < this.maxSpeed; i++) {
//         accelerationData.push([i,this.accelerationCurve[i]]);
//     }
//     accelerationData.push([this.maxSpeed,this.accelerationCurve[this.maxSpeed]]);

//     this.plot.setData([
//         {label:"Steering",data:steeringData,color:"#38659D"},
//         {label:"Acceleration",data:accelerationData,color:"#E08E1B"}]);
//     this.plot.setupGrid();
//     this.plot.draw();
    
//     $(".flot-y1-axis").css('text-shadow', '0 0 0.5px #38659D');

//     // change legend
//     this.rootElement.find(".legend").children('table').css('width', 200);
//     this.rootElement.find(".legend").children('div').css('width', 200);
//     this.rootElement.find('.legendLabel').each(function(index, el) {
//         $(el).css({
//             'text-align': 'right',
//             width: 200
//         });
//     });        
    
//     if(this.steeringCurve !== undefined){
//         this.plot.setCrosshair({x:streams.escData.speed});
//         var legends = this.rootElement.find('.legendLabel');
//         var speed = toInt(streams.escData.speed);
//         var currentSpeed = this.steeringCurve[speed];
//         var currentAcc = this.accelerationCurve[speed];
//         if(currentAcc >=10) // the first point of our acc curve is x/0, something we can't really display here, so instead of using a huge value (and therefore displaying somewhat crappy stuff), we are simply displaying 0
//             currentAcc = 0;
//         if(currentSpeed !== undefined)
//             legends.eq(0).text("Steering: " + currentSpeed.toFixed(3) + " rad/s");  
//         if(currentAcc !== undefined)    
//             legends.eq(1).text("Acceleration: " + currentAcc.toFixed(3) + " rad/s");
//     }
// };
