(function (window) {
'use strict';

  function callJS(name) {
    return function () {
      var short = registered[name];
      for (var i = 0; i < short.length; i += 1) {
        short[i].apply(undefined, arguments);
      }
    }
  }

  var jsApi = {
    triggerHook: callJS('hooks'),
    streamUpdate: callJS('streams')
  };

  window.registered = {};

  // var streamData = [{}];
  // var streamUpdated = false;
  // legacy ==================================================================
  window.oUpdate = function () {
    // streamData = arguments;
    // streamUpdated = true;
    jsApi.streamUpdate.apply(undefined, arguments);
  }

  window.HookManager = {
    trigger: function () {
      jsApi.triggerHook.apply(undefined, arguments);
    }
  };

  // end legacy ==================================================================

})(window);


angular.module('beamng.core', [])

/**
 * @ngdoc service
 * @name  beamng.core.service:bngApi
 * @requires beamng.core.value:apiCallbacks
 *
 * @description
 * This is used for communication with the other modules of the game,
 * in order to avoid direct usage of the <emph>beamng</emph> object.
 * Almost all functions can be paired with a callback that is stored
 * in the {@link beamng.core.value:apiCallbacks apiCallbacks} object.
**/
.factory('bngApi', ['$window', function ($window) {
  var callbackId = 0;
  var apiCallbacks = {};

  function registerGlobalCallback (name, callback) {
    if (name && callback) {
      if (registered[name] === undefined) {
        registered[name] = [callback];
      } else {
        registered[name].push(callback);
      }
      return registered.length;
    }
    return false;
  }

  $window.bngApiCallback = function(idx, result) {
    apiCallbacks[idx](result);
    delete apiCallbacks[idx];
  };

  var returnObj = {
    registerGlobalCallback: registerGlobalCallback,
    /**
     * @ngdoc method
     * @name  beamng.core.service:bngApi#engineScript
     * @methodOf beamng.core.service:bngApi
     * @param {string} cmd Command to the game engine
     * @param {function=} callback Function to be called after command has finished execution.
     *
     * @description
     * Sends a command to the game engine.
    **/
    engineScript: function (cmd, callback) {
      if (!callback) {
        beamng.sendGameEngine(cmd);
        return;
      }

      apiCallbacks[++callbackId] = callback;
      if( cmd.charAt(cmd.length-1) == ";" ) {
        cmd = cmd.substr(0, cmd.length-1);
      }
      cmdStr = 'beamNGExecuteJS(\"bngApiCallback(' + callbackId + ', \\\"\"@ strreplace(' + cmd + ',"\\\"","\\\\\\\"") @ "\\\");\");';
      beamng.sendGameEngine(cmdStr);
    },

    /**
     * @ngdoc method
     * @name activeObjectLua
     * @methodOf beamng.core.service:bngApi
     * @param {string} cmd Command to the active Lua object
     * @param {function=} callback Function to be called after command has finished execution.
     *
     * @description
     * Sends a command to the active Lua object.
    **/
    activeObjectLua: function (cmd, callback) {
      if (!callback) {
        beamng.sendActiveObjectLua(cmd);
        return;
      }

      apiCallbacks[++callbackId] = callback;
      var cmdStr = 'obj:executeJS("bngApiCallback(' + callbackId + ',".. encodeJson(' + cmd + ') ..")");';
      beamng.sendActiveObjectLua(cmdStr);
    },

    /**
     * @ngdoc method
     * @name  engineLua
     * @methodOf beamng.core.service:bngApi
     * @param {string} cmd Command to the Lua engine
     * @param {function=} callback Function to be called after command has finished execution.
     *
     * @description
     * Sends a command to the Lua engine.
    **/
    engineLua: function (cmd, callback) {
      if (beamng.externalUi) {
        beamng.sendEngineLua('return ' + cmd, callback || function () {});
        return;
      }

      if (!callback) {
        beamng.sendEngineLua(cmd);
        return;
      }


      apiCallbacks[++callbackId] = callback;
      var cmdStr = 'be:executeJS("bngApiCallback(' + callbackId + ',".. encodeJson(' + cmd + ') ..")");';
      beamng.sendEngineLua(cmdStr);
    },

    /**
     * @ngdoc method
     * @name  queueAllObjectLua
     * @methodOf beamng.core.service:bngApi
     * @param {string} cmd Command to Lua system
     *
     * @description
     * Sends a command to the Lua of .all objects
    **/
    queueAllObjectLua: function (cmd) {
      beamng.queueAllObjectLua(cmd);
    },

    /**
     * @ngdoc method
     * @name  serializeToLua
     * @methodOf beamng.core.service:bngApi
     * @param {object} obj Object to be serialized
     *
     * @description
     * Converts an object to a format compatible with Lua functions.
     *
     * @return {srting}
     * A string representation of the object that can be directly used
     * from Lua functions.
    **/
    serializeToLua: function (obj) {
      var tmp;
      if (obj === undefined || obj === null) { return 'nil'; } //nil';
      switch (obj.constructor) {
        case String:
          return '"' + obj.replace(/\"/g, '\'') + '"';
        case Number:
          return isFinite(obj) ? obj.toString() : null;
        case Boolean:
          return obj ? 'true' : 'false';
        case Array:
          tmp = [];
          for (var i = 0; i < obj.length; i++) {
            if (obj[i] != null) {
                tmp.push(this.serializeToLua(obj[i]));
            }
          }
          return '{' + tmp.join(',') + '}';
        case Function:
          return 'nil'
        default:
          if (typeof obj == 'object') {
            tmp = [];
            for (var attr in obj) {
              if (typeof obj[attr] != 'function') {
                tmp.push('["' + attr + '"]=' + this.serializeToLua(obj[attr]));
              }
            }
            return '{' + tmp.join(',') + '}';
          } else {
            return obj.toString();
          }
      }
    }
  };

  // if (!beamng.externalUi && beamng.externalUi !== undefined) {
  //   returnObj.engineLua(`extensions.util_extUI.setUiInfo(${returnObj.serializeToLua(beamng)})`);
  //   registerGlobalCallback('hooks', function () {
  //     returnObj.engineLua(`extensions.util_extUI.hookTriggered(${returnObj.serializeToLua(Array.prototype.slice.call(arguments))})`);
  //   });
  //   registerGlobalCallback('streams', function (streams) {
  //     returnObj.engineLua(`extensions.util_extUI.streamUpdate(${returnObj.serializeToLua(streams)})`);
  //   });
  // }

  return returnObj;
}])




/**
 * @ngdoc service
 * @name  beamng.core:RateLimiter
 *
 * @description
 * Limits the rate of function calls by means of throttling or
 * debouncing. Essentially the two functions of the service are
 * (simplified) copies of {@link http://underscorejs.org/ underscore}
 * library implementations.
 *
 * @note
 * These are _not_ Angular ports of underscore's functions. This
 * means that scope digests should be called manually (if at all).
 */
.service('RateLimiter', function () {
  return {

    /**
     * @ngdoc method
     * @name debounce
     * @methodOf beamng.core:RateLimiter
     * @param {function} func The function to be debounced
     * @param {int} wait Time in milliseconds to allow between successive calls.
     * @param {boolean} immediate Whether to allow first function call
     *
     * @description
     * underscore.js debounce utility, partially rewritten as
     * seen in {@link http://davidwalsh.name/function-debounce}
    **/
    debounce: function (func, wait, immediate) {
      var timeout;
      return function () {
        var context = this, args = arguments;
        var later = function () {
          timeout = null;
          if (!immediate) func.apply(context, args);
        };
        var callNow = immediate && !timeout;
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
        if (callNow) func.apply(context, args);
      };
    },

    /**
     * @ngdoc method
     * @name throttle
     * @methodOf beamng.core:RateLimiter
     * @param {func} The function to throttle
     * @param {int} wait Number of milliseconds between successive calls.
     *
     * @description
     * underscore.js throttle utility, partially rewritten as seen
     * in {@link http://briantford.com/blog/huuuuuge-angular-apps}
    **/
    throttle: function (func, wait) {
      var context, args, timeout, result;
      var previous = 0;
      var later = function () {
        previous = new Date();
        timeout = null;
        result = func.apply(context, args);
      };
      return function () {
        var now = new Date();
        var remaining = wait - (now - previous);
        context = this;
        args = arguments;
        if (remaining <= 0) {
          clearTimeout(timeout);
          timeout = null;
          previous = now;
          result = func.apply(context, args);
        } else if (!timeout) {
          timeout = setTimeout(later, remaining);
        }
        return result;
      };
    }
  };
})

.directive('bngSound', ['bngApi', function (bngApi) {
  var path = 'core/art/sound';

  return function (scope, element, attrs) {
    var config = scope.$eval(attrs.bngSound);

    Object.keys(config).forEach((ev) => {
      element.on(ev, () => {
        // console.log(config[ev], config[ev].disabled ? config[ev].disabled() : 'non obj');

        if (typeof config[ev] === 'string') {
          var soundLoc = config[ev].startsWith('event:') ? config[ev] : `${path}/${config[ev]}`;
          bngApi.engineLua(`Engine.Audio.playOnce('AudioGui', '${soundLoc}')`);
        } else if (!config[ev].disabled()) {
          var soundLoc = config[ev].sound.startsWith('event:') ? config[ev].sound : `${path}/${config[ev].sound}`;
          bngApi.engineLua(`Engine.Audio.playOnce('AudioGui', '${soundLoc}')`);
        }
      });
    });
  };
}])

// todo use camelcase here and udpated every other entry -yh
.directive('imageslider', ['$interval', '$timeout', function ($interval, $timeout) {
  return {
    restrict: 'E',
	  replace: true,
    template: `
      <div class="imageslider">
        <div class="imageslideItem filler" ng-repeat="image in images track by $index" ng-show="image.visible" ng-mouseenter="isActive(true)" ng-mouseleave="isActive(false)">
          <div style="background-image: url('{{image.url}}'); background-size: cover; background-position: center center;" class="filler"></div>
        </div>
      </div>
      `,
    scope:{
      imageurls: '=',
      delay: '@'
    },
    link: function (scope, elem, attrs) {
      var timer
        , offsetTimer
        , c = 0
        , delayMin = 3000
        , delayVar = 1000
        , delay = Number(scope.delay) || (delayMin + delayVar * Math.random())
        , initialDelay = delay * 0.3
      ;
      //console.log("imageslider delay: ", delay, ' inital: ' , initialDelay);

      scope.images = [];

      scope.isActive = function(active) {
        if(scope.images.length < 1) return;
        if(offsetTimer) $timeout.cancel(offsetTimer);
        if(timer) $interval.cancel(timer);
        timer = $interval(switchImages, active ? 1300 : delay);
      };

      // go through the images list and disable everything except the one to currently be shown
      function switchImages () {
        c = (c + 1) % scope.images.length;
        scope.images.forEach((elem, i) => elem.visible = i === c);
      }

      function setup () {
        // if it's not an array or a string return
        if(!Array.isArray(scope.imageurls) && typeof scope.imageurls !== 'string') {
          console.debug("invalid image data: imageurls = ", scope.imageurls)
          return;
        }
        //console.debug(scope.imageurls)

        // if it's a string, it'll have only one picture
        if(typeof scope.imageurls === 'string') {
          scope.imageurls = [scope.imageurls];
        }

        c = 0;
        scope.images = scope.imageurls.map((elem) => {return {url: elem, visible: true}});

        // only do the animations if we have more than one image
        if(scope.images.length > 1) {
          // don't start right away
          offsetTimer = $timeout(function() {
            timer = $interval(switchImages, delay);
          }, initialDelay);
        }
      }

      scope.$watch('imageurls', setup);

      scope.$on('$destroy', function() {
        if(offsetTimer) $timeout.cancel(offsetTimer);
        if(timer) $interval.cancel(timer);
      });
    }
  }
}])

.directive('countryFlag', function () {
  return {
    restrict: 'E',
    template: `<img class="filler" ng-src="{{imgSrc}}"/>`,
    scope: {
      src: '='
    },
    link: function (scope) {
      var shortHand =
        { 'United States': 'USA'
        , 'Japan': 'JP'
        , 'Germany': 'GER'
        , 'Italy': 'IT'
        }
      ;
      function setSrc () {
        scope.imgSrc = `/ui/lib/int/country_flags/${shortHand[scope.src] || scope.src || 'missing'}.png`;
      }

      scope.$watch('src', setSrc);

      setSrc();
    }
  };
})


;