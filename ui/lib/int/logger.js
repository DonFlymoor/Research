/**
 * @ngdoc service
 * @name beamng.stuff.service:logger
 * @description 
 *  service to get some control over what is shown in the log

 *  IMPORTANT: LINE NUMBERS
 *  to get to see the right line numbers displayed in the cef console do the following:
 *  Open the cef console options (upper right cog)
 *  go to 'Manage framework blackboxing...'
 *  make sure the 'Blackbox content scripts' option is checked
 *  add this filename (namely 'logger.js')
 *  reload
 *  the line numbers should be correct now \o/

 *  note:
 *    1. When restarting the game you might have to add this anew
 *    2. to exclude all other librarys aswell use '\.min\.js$'
 * @example logger.log('Something Important');
 *  logger.modmanager.error('This is a class specific error')
**/
angular.module('beamng.stuff')
.provider('logger', function () {
    var enabled = true;
    var blacklist;
    var whitelist;
    var classes = [];
    var align1 = true;
    var align2 = false;
    var length = 0;
    var defaultName = 'Console';
    var unsupportedMethods = ['table', 'dir', 'time', 'timeEnd', 'group', 'groupEnd', 'groupCollapsed', 'profile', 'profileEnd'];
    var indentedMethods = ['error', 'trace'];
    var rootScope;


    // check if the method should be provided
    function provide (funcName) {
      return (enabled && 
        !(blacklist !== undefined && blacklist.indexOf(funcName) !== -1) && 
        !(whitelist !== undefined && whitelist.indexOf(funcName) === -1)
      );
    }

    function calcLength () {
      return Math.max.apply(undefined, ([defaultName].concat(classes)).map((val) => val.length));
    }

    function emptyStrWithLen (len) {
      var res = '';

      for (var i = 0; i < len; i += 1) {
        res += ' ';
      }

      return res;
    }

    function logFunc (func, pref) {
      if (provide(func) && provide(pref)) {
        var args = Array.prototype.slice.call(arguments).slice(2);
        pref = ((align1 && indentedMethods.indexOf(func) === -1)? '  ' : '') + '[' + pref + ']' + (align2 ? emptyStrWithLen(length - pref.length) : '');

        if (func === 'error' || func === 'warn') {
          rootScope.$broadcast('DevLog', {msg: '', level: (func === 'error' ? 'E' : 'W'), origin: 'ui.logger'});
        }

        if (unsupportedMethods.indexOf(func) === -1) {
          if (typeof args[0] === 'string') {
            window.console[func].apply(window.console, [pref + ' ' + args[0]].concat(args.slice(1)));
          } else {
            window.console[func].apply(window.console, [pref].concat(args));
          }
        } else {
          window.console[func].apply(window.console, args);
        }
      }
    }

    function createLogFunctions (obj, type) {
      for (var m in window.console) {
        if (typeof window.console[m] === 'function') {
          obj[m] = logFunc.bind(undefined, m, type);
        }
      }
    }

    function wrapperConstructor () {
      var debug = {};

      for (var i = 0; i < classes.length; i += 1) {
        var className = classes[i];
        debug[className] = {};
        createLogFunctions(debug[className], className);
      }

      createLogFunctions(debug, defaultName);

      return debug;
    }




    // Wrapper class
    var Debugger = wrapperConstructor();



    
    /**
     * @ngdoc method
     * @name enabled
     * @methodOf beamng.stuff.service:logger
     * @param {boolean} enabled if the logger should be enabled or not
     *
     * @example loggerProvider.enabled(false);
    */
    this.enabled = function (val) {
      if (val !== undefined && typeof val === 'boolean') {
        enabled = val;
      }
    };

    /**
     * @ngdoc method
     * @name align
     * @methodOf beamng.stuff.service:logger
     * @param {boolean} enabled if the logger should try to get all classnames aligned (errors have this small arrow upfront) 
     *
     * @example loggerProvider.align(false);
    */
    this.align = function (val) {
      if (val !== undefined && typeof val === 'boolean') {
        align1 = val;
      }
    };

    /**
     * @ngdoc method
     * @name crazyAlign
     * @methodOf beamng.stuff.service:logger
     * @param {boolean} enabled if the logger should try to get all messages aligned (different length of classnames) 
     *
     * @example loggerProvider.crazyAlign(true);
    */
    this.crazyAlign = function (val) {
      if (val !== undefined && typeof val === 'boolean') {
        align2 = val;
      }
    };

    /**
     * @ngdoc method
     * @name hideMessages
     * @methodOf beamng.stuff.service:logger
     * @param {array} list the list of classes 
     * @param {boolean} true = blacklist, false = whitelist, defaults to blacklist 
     *
     * @description function to use a white or blacklist
     *  Blacklist: everything except what's on the list
     *  Whitelist: nothing except what's on the list
     *  IMPORTANT: If you use a whitelist make sure to enable the class AND as well the functions you want to use on it
     * @example loggerProvider.hideMessages(['HookManager'], false);
    */
    this.hideMessages = function (list, black) {
      if (list && Array.isArray(list)) {
        if (black === undefined || black) {
          blacklist = list;
        } else {
          whitelist = list;
        }
      } else {
        throw new Error ('Invalid list');
      }
    };
    /**
     * @ngdoc method
     * @name addClasses
     * @methodOf beamng.stuff.service:logger
     * @param {array} list the list of classes you want to use through the application
     *
     * @description function to add classes, that make it easier to filter and directly see which modules logged which messages
     * @example loggerProvider.addClasses(['HookManager']);
    */
    this.addClasses = function (list) {
      var ok = false;
      
      if (list && Array.isArray(list)) {
        ok = list.every((val) => typeof val === 'string');
      }

      if (ok) {
        classes = classes.concat(list).unique();
        length = calcLength(classes);
        Debugger = wrapperConstructor();
      } else {
        throw new Error ('Invalid list');
      }
    };

    this.$get = ['$rootScope', function ($rootScope) {
      if (rootScope === undefined) {
        rootScope = $rootScope; // hack :-(
      }
      return Debugger;
    }];
  });

