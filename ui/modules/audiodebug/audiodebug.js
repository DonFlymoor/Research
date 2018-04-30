(function() {
'use strict';

angular.module('beamng.stuff')

.controller('AudioDebugController', ['$scope', 'bngApi', function ($scope, bngApi) {

  $scope.query = '';

  $scope.enabled = false;
  $scope.windowSize = 1;
  $scope.data = null;

  $scope.$on('AudioDebug', function (event, data) {
    $scope.$evalAsync(function () {
      $scope.data = data;
    });
  });


  function enable() {
    bngApi.activeObjectLua('sounds.setUIDebug(true, {source = "v0"})');
  }

  function disable() {
    bngApi.activeObjectLua('sounds.setUIDebug(false)');
  }

  $scope.$on('$destroy', function() {
    disable();
  });
  enable();
}])


.directive('audioVisualDebug', ['Utils', function (Utils) {
   "use strict";
   return {
     restrict : 'EAC',
     replace : true,
     scope : true,
     template: '<canvas width=800 height=800 style="background-color:rgba(255,255,255,0.8);"></canvas>',
     link: function (scope, element, attribute) {
      var canvas = element[0];
      var c = canvas.getContext('2d');
      var width = canvas.width;
      var height = canvas.height;
      var pointsCount = width;

      c.lineWidth = 1;
      c.strokeStyle = '#333';
      c.font = 'monospace';
      c.textAlign = "left";



      var graphs = {};
      var sources = {};
      var graphCount = 0;
      var dd = 0;

      scope.$watch('data', function(d) {
        if(!d) return;
        c.clearRect(0, 0, width, height);

        // setup graphs
        if(graphCount == 0) { // TODO: detect changes?: || d.sounds.length != graphCount) {
          var dataGraphCount = Object.keys(d.sounds).length;
          graphs = {};
          for(var sk in d.sounds) {
            var snd = d.sounds[sk];
            
            var g = {};
            g.data = {};
            g.min = {};
            g.max = {};
            g.range = {};
            g.color = Utils.rainbow(dataGraphCount, graphCount);
            g.title = snd.filename.split('/').reverse()[0];
            graphs[snd.sfxProfile] = g
            graphCount++;
            //console.log(snd);
            if(!sources[snd.source]) {
              sources[snd.source] = {profiles:[], data:[], min: {}, max: {}, range: {}};
            }
            sources[snd.source].profiles.push(snd.sfxProfile);
          }
        }

        function addPoint(d, v, sg) {
          if(!d.data[sg]) d.data[sg] = [];
          d.data[sg].push(v);
          if(d.data[sg].length > pointsCount) {
            d.data [sg]= d.data[sg].slice(1); // rotate data
          }
          if(!d.min[sg] || v < d.min[sg]) {
            d.min[sg] = v;
            d.range[sg] = (d.max[sg] - d.min[sg])
          } 
          if(!d.max[sg] || v > d.max[sg]) {
            d.max[sg] = v;
            d.range[sg] = (d.max[sg] - d.min[sg])
          }
          if(d.range[sg] == 0) d.range[sg] = 0.00001
        }

        // update graph data
        var updatedSources = {};
        for(var sk in d.sounds) {
          var snd = d.sounds[sk];
          addPoint(graphs[snd.sfxProfile], snd.lastPitch, 0);
          addPoint(graphs[snd.sfxProfile], snd.lastVolume, 1);
          addPoint(graphs[snd.sfxProfile], snd.lastVal, 2);
          if(!updatedSources[snd.source]) {
            addPoint(sources[snd.source], snd.lastVal, 0);

          }
        }

        // draw graphs
        var rowHeight = 30;
        var y = 30;

        c.textAlign = "left";
        c.strokeStyle = 'black';
        c.font = '16px Arial bold';
        c.fillText('Graphs', 10, y-5);
        c.beginPath();
        c.strokeStyle = 'red';
        c.moveTo(5, y);
        c.lineTo(width - 10, y);
        c.stroke();

        y += 16

        for(var sk in graphs) {
          var g = graphs[sk];

          // draw border
          c.textAlign = "left";
          c.fillStyle = "black";
          c.strokeStyle = '#888';
          c.beginPath();
          c.moveTo(0, y+rowHeight);
          c.lineTo(width, y+rowHeight);
          c.stroke();
          // then the actual graph
          c.font = '12px monospace';
          c.fillText(g.title, 55, y + 10);
          c.fillStyle = "#444";
          c.font = '11px monospace';
          c.fillText(Math.round(g.min[0]*100)/100, 0, y + 9);
          c.fillText(Math.round(g.max[0]*100)/100, 0, y + rowHeight);

          // draw the pitch + vol
          for(var i = 0; i < g.data[0].length; i++) {
            var pitch = 1-(g.data[0][i] - g.min[0])/ g.range[0];
            var volume = (g.data[1][i] - g.min[1]) / g.range[1];
            //var d2 = g.data[2][i]) / g.range[2]);

            c.beginPath();
            c.strokeStyle = 'rgba('+Math.round(g.color[0]*255)+','+Math.round(g.color[1]*255)+','+Math.round(g.color[2]*255)+','+(pitch+0.05)+')';;
            c.moveTo(i, y + rowHeight-1);
            if(volume<0) volume = 0;
            c.lineTo(i, y + rowHeight - volume * (rowHeight-2));
            c.stroke();
          }

          // draw the val
          c.beginPath();
          c.strokeStyle = '#444';
          for(var i = 1; i < g.data[0].length; i++) {
            var d2 = (g.data[2][i] - g.min[2]) / g.range[2];
            c.lineTo(i, y + rowHeight - d2 * (rowHeight-2) - 1);
          }
          c.stroke();

          // value test
          c.textAlign = "left";
          c.fillStyle = "#444";
          var txt = 'pitch: ' + Math.round(g.data[0][g.data[0].length-1]*100)/100 + ', volume: ' + Math.round(g.data[1][g.data[1].length-1]*100)/100 + ', val: ' + Math.round(g.data[2][g.data[2].length-1]*100)/100;
          c.fillText(txt, width - 350, y + 9);
          
          y+= rowHeight;
        }

        // sources section
        y += 30
        c.textAlign = "left";
        c.strokeStyle = 'black';
        c.font = '16px Arial bold';
        c.fillText('Sources', 10, y-5);
        c.beginPath();
        c.strokeStyle = 'red';
        c.moveTo(5, y);
        c.lineTo(width - 10, y);
        c.stroke();
        y += 16
      });



     }
   }
 }]);
})();
