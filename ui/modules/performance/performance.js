(function () {
  'use strict';


  angular.module('beamng.stuff')
  .controller('PerformanceController', ['$log', '$scope', 'Settings', 'bngApi', function($log, $scope, Settings, bngApi) {
    var vm = this
      , timeout
    ;

    bngApi.engineLua('extensions.load("ui_performance")');
    $scope.updatesLimited = false;
    $scope.updatesText = 'Updates limited';

    $scope.vsync = false;
    $scope.fps_limiter = 0;
    if(Settings.values.GraphicSyncFullscreen !== undefined) {
      $scope.vsync = Settings.values.GraphicSyncFullscreen;
    }

    //fps-limiter
    if(Settings.values.FPSLimiter !== undefined) {
      $scope.fps_limiter = Settings.values.FPSLimiter;
    }

    // TODO: change this to check if the settings changed before applying it directly
    $scope.$on('SettingsChanged', function (event, data) {
      //console.log('onHardwareInfo', data)
      $scope.$apply(function() {
        $scope.vsync = data.values.GraphicSyncFullscreen;
        $scope.fps_limiter = data.values.FPSLimiter;
      });
    });

    $scope.$on('$destroy', function () {
      bngApi.engineLua('extensions.unload("ui_performance")');
      $scope.$emit('ShowApps', true);
      $scope.$emit('hide_ui', false);
      clearTimeout(timeout);
    });

    $scope.$emit('ShowApps', false);

    $scope.tempHideUI = function () {
      $scope.$emit('hide_ui', true);
      timeout = setTimeout(function() {
        $scope.$emit('hide_ui', false);
      }, 10000);
    };
  }])

  .directive('performanceGraph', function () {
   return {
     restrict : 'E',
     scope : true,
     template: '<canvas></canvas>',
     link: function (scope, element) {
      var canvas = element.find('canvas')[0]
        , ctx = canvas.getContext('2d')
        , neededHeight = 1200
        , shouldDraw = false
        ;

      beamng.sendEngineLua('ui_performance.requestConfig()');

      // cover resizes
      function resize() {
        canvas.width = canvas.parentElement.offsetWidth;
        canvas.height = neededHeight;
        // console.log('needed height', neededHeight)
      }
      window.addEventListener('resize', resize, false);
      resize();

      ctx.lineWidth = 1;
      ctx.font = 'monospace';
      ctx.textAlign = "left";

      // Anti aliasing fix. This makes the lines look crisp and sharp and means that rounding to the nearest half pixel is not needed.
      ctx.translate(0.5, 0.5);

      // config/metadata sent by lua
      var config = null;

      // runtime vars
      var simpleGraphs = [];
      var stackedGraphs = [];
      var updateData = [];

      scope.$on('$destroy', () => {
        shouldDraw = false;
        // clearInterval(fnCallHelper.intervalHandel)
      });

      scope.$on('PerformanceInit', function (_, _config) {
        neededHeight = 20;
        // called on start to setup the metadata
        config = _config;
        //console.log('got performance config: ', config);
        // setup stacked graphs
        stackedGraphs.length = 0;
        for(var pk in config.stacked) {
          var sg = new StackedGraph(config.stacked[pk], config.metadata);
          stackedGraphs.push(sg);
          neededHeight += 200;
        }
        //setup simple graphs
        simpleGraphs.length = 0;
        for(var pk in config.simple) {
          var sg = new SimpleGraph(config.simple[pk], config.metadata);
          simpleGraphs.push(sg);
          neededHeight += 80;
        }

        resize();
        shouldDraw = true;
        drawHelper();
      });

      scope.$on('PerformanceData', function (_, rawData) {
        // delivers the data
        //console.log(rawData)
        updateData.push(rawData)
      });

      function drawHelper () {
        if (shouldDraw) {
          window.requestAnimationFrame(draw);
        }
      }

      // var fnCallHelper = fnCallCounter(drawHelper);
      // drawHelper = fnCallHelper.newFn;

      function draw () {
        // delivers the data
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        var y = 10;
        var x = 10;
        var graphWidth = canvas.width - 20;

        // update stackedGraphs
        for(var i = 0; i < stackedGraphs.length; i++) {
          var res = stackedGraphs[i].draw(updateData, ctx, x, y, graphWidth, 180);
          x = res[0];
          y = res[1] + 10;
        }

        // update simpleGraphs
        for(var i = 0; i < simpleGraphs.length; i++) {
          var res = simpleGraphs[i].draw(updateData, ctx, x, y, graphWidth, 60);
          x = res[0];
          y = res[1] + 10;
        }

        updateData.length = 0;
        setTimeout(drawHelper, 250);
      }
    }
  }
});


// Graphing library from here on
// TODO: when porting to ui2 make sure to put this in an es6 module


function F32windowShift(array, newElemLen, windowLen) {
  if (newElemLen == 0) return array;
  if (array.length >= windowLen) {
    if (newElemLen <= windowLen) array.set(array.subarray(newElemLen));
    return array;
  }
  var totalLen = array.length + newElemLen;
  if (totalLen <= windowLen) {
    var tmp = new Float32Array(totalLen);
    tmp.set(array);
    return tmp;
  }
  var tmp = new Float32Array(windowLen);
  if (newElemLen <= windowLen) tmp.set(array.subarray(Math.max(totalLen - windowLen, 0)));
  return tmp;
}

/*****************************************************************************/
function rainbow(numOfSteps, step) {
  // This function generates vibrant, "evenly spaced" colours (i.e. no clustering). This is ideal for creating easily distinguishable vibrant markers in Google Maps and other apps.
  // Adam Cole, 2011-Sept-14
  // HSV to RBG adapted from: http://mjijackson.com/2008/02/rgb-to-hsl-and-rgb-to-hsv-color-model-conversion-algorithms-in-javascript
  var r, g, b;
  var h = step / numOfSteps;
  var i = ~~(h * 6);
  var f = h * 6 - i;
  var q = 1 - f;
  switch(i % 6){
    case 0: r = 1; g = f; b = 0; break;
    case 1: r = q; g = 1; b = 0; break;
    case 2: r = 0; g = 1; b = f; break;
    case 3: r = 0; g = q; b = 1; break;
    case 4: r = f; g = 0; b = 1; break;
    case 5: r = 1; g = 0; b = q; break;
  }
  //var c = "#" + ("00" + (~ ~(r * 255)).toString(16)).slice(-2) + ("00" + (~ ~(g * 255)).toString(16)).slice(-2) + ("00" + (~ ~(b * 255)).toString(16)).slice(-2);
  return [r, g, b]
}

function getRandomColor() {
  return [Math.random()*255, Math.random()*255, Math.random()*255, 1]
}
//converts rgba array to string, allowing to darken/lighten it in the process
function getColor(rgba, lum, alphaChange) {
  var lum = lum || 1;
  var alphaChange = alphaChange || 1;
  if(lum != 1 || alphaChange != 1) {
    var rgbaNew = [
      Math.min(Math.max(rgba[0] * lum, 0), 255),
      Math.min(Math.max(rgba[1] * lum, 0), 255),
      Math.min(Math.max(rgba[2] * lum, 0), 255),
      Math.min(Math.max((rgba[3] || 1) * alphaChange, 0), 1)
    ];
    rgba = rgbaNew;
  }
  return `rgba(${Math.round(rgba[0])},${Math.round(rgba[1])},${Math.round(rgba[2])},${rgba[3]})`;
}
function bytesToSize(bytes, precision) {
   var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
   if (bytes == 0) return '0 Byte';
   var i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
   return (bytes / Math.pow(1024, i)).toFixed(precision) + ' ' + sizes[i];
}
/*****************************************************************************/
var ExponentialSmoothing = function(window, startingValue) {
  if(typeof window === "undefined") window = 10;
  this.a = 2 / window;
  this.samplePrev = null;
  this.stPrev = null;
  if(typeof startingValue !== "undefined") {
    this.samplePrev = startingValue;
    this.stPrev = startingValue;
  }
}
ExponentialSmoothing.prototype.update = function(sample) {
  if(this.samplePrev === null) {
    this.samplePrev = sample;
    this.stPrev = sample;
    return sample;
  }
  this.stPrev = this.stPrev + this.a * (this.samplePrev - this.stPrev);
  this.samplePrev = sample;
  return this.stPrev;
}
/*****************************************************************************/
var SimpleGraph = function(_config, _metaData) {
  this.config = _config;
  this.metaData = _metaData;

  this.data = new Float32Array(0);
  this.dataAvg = new Float32Array(0);
  this.min = null;
  this.max = null;
  this.range = 0;
  this.title = 'unknown';

  this.leftBorder = 120;
  this.width = 1; // set on draw
  this.unit = '';

  // 'apply' the config
  for (var attrname in this.config) { this[attrname] = this.config[attrname]; };
  this.meta = this.metaData[this.config.graph] || this.metaData['default']
  if(this.meta.color == 'random') {
    this.meta.color = getRandomColor();
  }
  this.meta._fillStyle = getColor(this.meta.color, 0.8, 0.2);
  this.meta._strokeStyle = getColor(this.meta.color, 0.3, 0.3);
  this.meta._graphStrokeStyle = getColor(this.meta.color, 1.1);
  this.meta._titleFillStyle = getColor(this.meta.color, 0.3);
  this.smoother = new ExponentialSmoothing(this.meta.window);
};
SimpleGraph.prototype.drawNumberScaled = function(ctx, x, y, v, _prefix) {
  if(!v) return;
  var prefix = _prefix || '';
  var txt;
  if(this.meta.unit == 'bytes') {
    txt = prefix + bytesToSize(v, this.meta.precision);
  } else {
    txt = prefix + v.toFixed(this.meta.precision) + this.meta.unit;
  }
  ctx.fillText(txt, x, y);
}

SimpleGraph.prototype.draw = function(updateData, ctx, x, y, width, height) {
  // update the data
  var windowLen = (width - this.leftBorder);
  var updateLen = updateData.length;

  var totalLen = updateLen + this.data.length;
  this.data = F32windowShift(this.data, updateLen, windowLen);
  this.dataAvg = F32windowShift(this.dataAvg, updateLen, windowLen);
  var ui = Math.max(updateLen - windowLen, 0);
  var di = Math.max(this.data.length - (updateLen - ui), 0);
  var graphData = this.data;
  var graphAvg = this.dataAvg;
  var smootherUpdate = this.smoother.update;
  var graphName = this.config.graph;
  var smoother = this.smoother;
  for (i = ui; i < updateLen; i++) {
    var v = updateData[i][graphName];
    graphData[di] = v
    graphAvg[di] = smoother.update(v);
    di++;
  }

  // draw the val
  this.width = width;
  ctx.lineWidth = 1;
  ctx.setLineDash([0]);

  ctx.strokeStyle = '#444';
  ctx.font = '11px monospace';
  var fontHeight = ctx.measureText('M').width;

  ctx.strokeStyle = '#777';
  ctx.beginPath();
  ctx.rect(x,y,width,height);
  ctx.stroke();

  ctx.beginPath();
  ctx.fillStyle = this.meta._fillStyle
  ctx.fillRect(x,y,this.leftBorder,height);
  ctx.stroke();

  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.strokeStyle = this.meta._strokeStyle;
  var upLimit = y + height - 2;
  var graphSize = this.data.length;

  var localMin = this.data[0];
  var localMax = localMin;

  var i = graphSize;
  while (i--) {
    localMin = Math.min(localMin, Math.min(graphData[i], graphAvg[i]));
    localMax = Math.max(localMax, Math.max(graphData[i], graphAvg[i]));
  }

  this.range = (localMax - localMin);
  if(this.range == 0) this.range = 0.00001
  var scale = (height - 4) / this.range;

  i = graphSize;
  var x2 = Math.round(x + width);
  while (i--) {
    ctx.lineTo(x2, Math.round(upLimit - (graphData[i] - localMin) * scale));
    x2--;
  }
  ctx.stroke();
  // draw graph
  ctx.beginPath();
  ctx.lineWidth = 2;
  ctx.strokeStyle = this.meta._graphStrokeStyle;

  i = graphSize;
  var x2 = Math.round(x + width);
  while (i--) {
    ctx.lineTo(x2, Math.round(upLimit - (graphAvg[i] - localMin) * scale));
    x2--;
  }
  ctx.stroke();

  // draw border
  //ctx.textAlign = "left";
  ctx.lineWidth = 1;
  ctx.strokeStyle = '#777';
  ctx.beginPath();
  ctx.moveTo(Math.round(x + this.leftBorder), Math.round(y));
  ctx.lineTo(Math.round(x + this.leftBorder), Math.round(y + height));
  ctx.stroke();

  // title
  ctx.textAlign = 'left';
  ctx.font = '16px Arial bold';
  var fontHeight2 = ctx.measureText('M').width;
  ctx.fillStyle = this.meta._titleFillStyle;
  ctx.fillText(this.title, Math.round(x + 5), Math.round(y + (height * 0.5) + fontHeight2 * 0.45));

  ctx.textAlign = 'right';
  ctx.fillStyle = '#444';
  ctx.font = '11px monospace';

  //ctx.font = '11px monospace';

  this.drawNumberScaled(ctx, x + this.leftBorder - 5, y + fontHeight + 5, this.max, 'max: ')
  this.drawNumberScaled(ctx, x + this.leftBorder - 5, y + height - 5, this.min, 'min: ')

  // value text
  ctx.textAlign = "left";
  ctx.fillStyle = "#444";
  this.drawNumberScaled(ctx, x + this.leftBorder + 5, y + fontHeight + 5, this.data[this.data.length-1], 'last: ')
  this.drawNumberScaled(ctx, x + this.leftBorder + 5, y + fontHeight * 2 + 10, this.dataAvg[this.dataAvg.length-1], 'avg: ')

  this.min = localMin;
  this.max = localMax;

  y += height;
  return [x, y]; // return new x and y
};
/*****************************************************************************/
var StackedGraph = function(_config, _metaData) {
  this.config = _config;
  this.metaData = _metaData;

  this.max = 1;
  this.width = 1; // set on draw
  this.data = {};
  this.colors = {};
  this.leftBorder = 50;
  this.topBorder = 30;
  this.prevVals = {};

  // 'apply' the config
  for (var attrname in this.config) { this[attrname] = this.config[attrname]; };

  for(var i = 0; i < this.config.graphs.length; i++) {
    this.data[this.config.graphs[i]] = new Float32Array(0);
    var g = this.metaData[this.config.graphs[i]] || this.metaData['default'];
    var col = g.color;
    if(col == 'random') {
      this.colors[this.config.graphs[i]] = getColor(getRandomColor());
    } else {
      this.colors[this.config.graphs[i]] = getColor(col);
    }
  }
};

StackedGraph.prototype.draw = function(updateData, ctx, x, y, width, height) {
  // update the data
  var updateLen = updateData.length;
  var windowLen = width - this.leftBorder - 2;
  var uiStart = Math.max(updateLen - windowLen, 0);
  var uwlen = (updateLen - uiStart);

  if (this.prevVals.length != windowLen) this.prevVals = new Float32Array(windowLen);
  for (var gk in this.data) {
    this.data[gk] = F32windowShift(this.data[gk], updateLen, windowLen);
    var data = this.data[gk];
    var di = Math.max(data.length - uwlen, 0);
    for (i = uiStart; i < updateLen; i++) {
      data[di] = updateData[i][gk];
      di++;
    }
  }

  // draw the graph
  this.width = width;
  ctx.lineWidth = 1;
  ctx.setLineDash([0]);
  ctx.font = '11px monospace';
  var fontHeight = ctx.measureText('M').width;

  ctx.strokeStyle = '#777';
  ctx.beginPath();
  ctx.rect(Math.round(x),Math.round(y),Math.round(width),Math.round(height));
  ctx.stroke();


  var bottomLine = Math.round(y + height - 1);

  var firstGraph = this.data[this.config.graphs[0]];
  var dataLength = firstGraph.length;
  var prevVals = this.prevVals;
  var i = dataLength;
  while (i--) {
    prevVals[i] = 0;
  }

  var scale = (height - this.topBorder - 2) / this.max;
  var xStart = Math.round(x + width);

  for (var gk in this.data) {
      ctx.beginPath();
      ctx.strokeStyle = this.colors[gk];
      var graphData = this.data[gk];
      var x2 = xStart;
	    var k = graphData.length;
      while (k--) {
		    var v = prevVals[k];
        ctx.moveTo(x2, Math.round(bottomLine - v * scale));
		    v += graphData[k];
        prevVals[k] = v;
        ctx.lineTo(x2, Math.round(bottomLine - v * scale));
        x2--;
      }
      ctx.stroke();
  }

  k = dataLength;
  var tmpMax = prevVals[0];
  while (k--) {
    tmpMax = Math.max(prevVals[k], tmpMax);
  }
  this.max = tmpMax;

  // draw title
  var x2 = x + 5;
  var y2 = y + 5;
  ctx.textAlign = "left";
  ctx.fillStyle = "black";
  ctx.font = '16px Arial bold';
  var th = ctx.measureText('M').width;
  ctx.fillText(this.title, x2, y2 + th);
  x2 += ctx.measureText(this.title).width + 20;
  var titleLeft = x2;

  // legend
  ctx.textAlign = 'left';
  ctx.font = '11px monospace';
  for (var gk in this.data) {
    ctx.fillStyle = this.colors[gk];
    var txt = this.metaData[gk].title
    var tw = ctx.measureText(txt).width;
    // next line?
    if(x2 + tw >= x + width) {
      x2 = titleLeft;
      y2 += fontHeight * 1.5
    }
    ctx.fillText(txt, Math.round(x2), Math.round(y2) + fontHeight);
    x2+= tw + 10;
  }


  // grid
  ctx.textAlign = "left";
  ctx.fillStyle = "black";
  ctx.strokeStyle = 'rgba(20,20,20,0.3)';
  ctx.lineWidth = 1;
  var gs = (this.max / 5);
  ctx.beginPath();
  ctx.setLineDash([5]);
  for(var k = 0; k <= 5; k++) {
    var v2 = gs * k;
    var y2 = Math.round(bottomLine - v2 * scale);
    if(k != 0) {
      // skip bottom 0 line
      ctx.moveTo(Math.round(x), y2);
      ctx.lineTo(Math.round(x + width), y2);
    }
    ctx.fillText(v2.toFixed(this.precision) + this.unit, Math.round(x + 3), Math.round(y2-3));
  }
  ctx.stroke();

  y += height;
  return [x, y]; // return new x and y
};

/*****************************************************************************/

})();