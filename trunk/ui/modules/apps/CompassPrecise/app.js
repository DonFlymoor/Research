angular.module('beamng.apps')

/**
 * @ngdoc directive
 * @name beamng.apps:compassPrecise
 *
 * @description "Precision Copmass" canvas-based app. It consists of two
 * canvases (one hidden, one visible). The hidden one gets rendered once and
 * on update the visible shows the relevant part of it. 
 *
 * @note Ported as best as possible from previous implementation, but both of 
 * them are likely to have some DOM-related bugs - should be tested properly.
 **/
.directive('compassPrecise', ['StreamsManager', function (StreamsManager) {
  return {
    template: '<div style="background-color:rgba(0, 0, 0, 0.43);"><canvas width="280" height="56"></canvas></div>',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {      
      var streamsList = ['sensors'];
      StreamsManager.add(streamsList);
      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      var c = element[0].getElementsByTagName('canvas')[0]
        , ctx = c.getContext('2d')
        , compass_width = 2000 //Defines how close are markings to each other
        , width_less = (compass_width - c.width)/2
      ;

      var generate = function () {
        var osCanvas = angular.element('<canvas></canvas>');
        element.parent().append(osCanvas);

        osCanvas[0].width = compass_width;
        osCanvas[0].height = element.parent()[0].offsetHeight;
        osCanvas.css({"display": "none"});

        var osCtx = osCanvas[0].getContext('2d');
        osCtx.font='bold 17px "Lucida Console", Monaco, monospace';
        osCtx.textAlign="center";
        osCtx.fillStyle = "white";
        osCtx.strokeStyle = "white";

        for (var i = 0; i < 37; i++) {
          
          var r=i*Math.PI/180*10
            , pos_x_1 = r * compass_width/(2*Math.PI)
            , pos_x_2 = pos_x_1 + compass_width/72
          ;
          
          //big lines
          osCtx.beginPath();
          osCtx.lineWidth=2;
          osCtx.moveTo(pos_x_1, 30);
          osCtx.lineTo(pos_x_1, 50);
          osCtx.stroke();
          
          //small lines
          if (i!=36){
            osCtx.beginPath();
            osCtx.lineWidth=2;
            osCtx.moveTo(pos_x_2, 30);
            osCtx.lineTo(pos_x_2, 45);
            osCtx.stroke();
          }
          
          //text
          text = i*10;
          if (text==0||text==360){
            text="N";
          }else if (text==90){
            text="E";
          }else if (text==180){
            text="S";
          }else if (text==270){
            text="W";
          }

          osCtx.fillText(text,  pos_x_1, 22);
        }

        return osCanvas[0];
      };

      var osCanvas = generate();

      scope.$on('streamsUpdate', function (event, streams) {
        var size = Math.min(c.width, c.height)
          , heading = streams.sensors.yaw;

        ctx.clearRect(0, 0, c.width, c.height);
        ctx.fillStyle = "rgba(255,255,255,0.8)";
        ctx.strokeStyle = "rgba(255,255,255,0.6)";

        posX = heading * compass_width / (2*Math.PI) - width_less;
        ctx.drawImage(osCanvas, posX, 0);
        if(heading * compass_width / (2*Math.PI) - width_less > 0){
          ctx.drawImage(osCanvas, posX - compass_width, 0);
        } else if(posX + compass_width < c.width){
          ctx.drawImage(osCanvas, posX + compass_width, 0);
        }
        
        //needle
        ctx.beginPath();
        ctx.lineWidth=2;
        ctx.strokeStyle = "white";
        ctx.moveTo(c.width/2, 40);
        ctx.lineTo(c.width/2-5, 55);
        ctx.moveTo(c.width/2, 40);
        ctx.lineTo(c.width/2+5, 55);
        ctx.stroke();  
      });

      scope.$on('app:resized', function (event, data) {
        c.width = data.width;
        c.height = data.height;
      });
    }
  };
}]);