angular.module('beamng.apps')

.value('streamLogData', {})

.directive('logStreams', ['StreamsManager', 'bngApi', 'streamLogData', function (StreamsManager, bngApi, streamLogData) {
  return {
    template:
      '<div style="width:100%; max-height:100%;" layout="row" layout="row" layout-align="center center" layout-wrap>' +
        '<md-button flex md-no-ink style="margin: 2px; min-width: 170px" ng-click="printTable()" class="md-raised">Print as table</md-button>' +
        '<md-button flex md-no-ink style="margin: 2px; min-width: 170px" ng-click="printJson()" class="md-raised">Print Json</md-button>' +
        '<md-button flex md-no-ink style="margin: 2px; min-width: 170px" ng-click="printWikitable()" class="md-raised">Print as wikitable</md-button>' +
        '<md-button flex md-no-ink style="margin: 2px; min-width: 170px" ng-click="printRst()" class="md-raised">Print as rst</md-button>' +

        '<md-button flex md-no-ink style="margin: 2px; min-width: 170px" ng-click="importJson()" class="md-raised">Import JSON</md-button>' +
        '<md-button flex md-no-ink style="margin: 2px; min-width: 170px" ng-click="exportJson()" class="md-raised">Export JSON</md-button>' +
        '<md-button flex md-no-ink style="margin: 2px; min-width: 170px" ng-click="importWikitable()" class="md-raised">Import wikitable</md-button>' +
        '<md-button flex md-no-ink style="margin: 2px; min-width: 170px" ng-click="exportWikitable()" class="md-raised">Export as wikitable</md-button>' +
        '<md-button flex md-no-ink style="margin: 2px; min-width: 170px" ng-click="importRst()" class="md-raised">Import Rst</md-button>' +
        '<md-button flex md-no-ink style="margin: 2px; min-width: 170px" ng-click="exportRst()" class="md-raised">Export as Rst</md-button>' +

        '<md-button flex md-no-ink style="margin: 2px; min-width: 170px" ng-click="rmData()" class="md-raised">Reset logged Data</md-button>' +
      '</div>',
    replace: true,
    link: function (scope, element, attrs) {
      'use strict';

      bngApi.engineLua('extensions.load("util_logStreams")');

      // Add all Streams I know of as of now
      var requiredStreams =
        [ 'wheelInfo'
        , 'engineInfo'
        , 'electrics'
        , 'absData'
        , 'stats'
        , 'sensors'
        , 'engineThermalData'
        , 'escData'
        , 'tcsData'
        , 'forcedInductionInfo'
        , 'torqueCurve'
        , 'profilingData'
        , 'advancedWheelDebugData'
        , 'wheelThermalData'
        , 'gearboxData'
        , 'powertrainDeviceData'
        , 'shiftDecisionData'
        , 'shiftPointDebugData'
        , 'n2oInfo'
        ];

      StreamsManager.add(requiredStreams);

      scope.$on('$destroy', function () {
        StreamsManager.remove(requiredStreams);
        streamLogData = streamLog;
        bngApi.engineLua('extensions.unload("util_logStreams")');
      });


      var streamLog = {};

      if (Object.keys(streamLogData).length > 0) {
        streamLog = streamLogData;
      }

      var interval;
      function autoStoreData () {
        var interval = setInterval(function () {
          streamLogData = streamLog;
        }, 10000);
      }
      autoStoreData();


      scope.printJson = function () {
        console.log(JSON.stringify(streamLog, null, 4));
      };

      scope.printTable = function () {
        console.table(toTable(true));
      };

      scope.printWikitable = function () {
        console.log(toWikitable());
      };

      scope.printRst = function () {
        console.log(toRst());
      };

      scope.rmData = function () {
        streamLog = {};
        streamLogData = {};
        autoStoreData();
      };

      scope.importWikitable = function () {
        bngApi.engineLua('util_logStreams.readWikitable()', function (data) {
          // huge hack and not happy about it, but it works! finally! \o/
          parseWikitable(data.replace(/\\n/g, '\n'));
        });
      };

      scope.importRst = function () {
        bngApi.engineLua('util_logStreams.readRst()', function (data) {
          // huge hack and not happy about it, but it works! finally! \o/
          parseRst(data.replace(/\\n/g, '\n'));
        });
      };

      scope.importJson = function () {
        bngApi.engineLua('util_logStreams.readJson()', function (data) {
          parseJson(data);
        });
      };

      scope.exportWikitable = function () {
        bngApi.engineLua('util_logStreams.saveWikitable(\'' + toWikitable().replace(/\n/g, '\\n') + '\')');
      };

      scope.exportRst = function () {
        bngApi.engineLua('util_logStreams.saveRst(\'' + toRst().replace(/\n/g, '\\n') + '\')');
      };

      scope.exportJson = function () {
        bngApi.engineLua('util_logStreams.saveJson(' + bngApi.serializeToLua(streamLog) + ')');
      };


      scope.$on('streamsUpdate', function (event, streams) {
        // parse every single stream you recieve even those not explicitly listening too :-)
        parseStreams(streams);
      });


      function trimEntrys (arr) {
        for (var i = 0; i < arr.length; i++) {
          arr[i] = arr[i].trim();
        }
      }

      function resolveType (type1, type2) {
        if (type1 === type2) {
          return type1;
        }

        if (type1 === '???') {
          return type2;
        }

        if (type2 === '???') {
          return type1;
        }

        if (type1 === 'int' && (type2 === 'float' || type2 === 'int')) {
          return type2;
        }

        if (type2 === 'int' && (type1 === 'float' || type1 === 'int')) {
          return type1;
        }


        // Case where one needed more than two states
        if (type1 === 'int' && type2 === 'bool') {
          return type1;
        }

        console.warn('Type error');
        console.log(type1, type2);
        return '???';
      }

      function parseWikitable (str) {
        var lines = str.split('\n') //split string into lines
          .map(function (elem) {return elem.trim();}) // remove all whitespaces form start and end
          .filter(function (elem) {return elem.indexOf('|-') !== 0;}) // remove all lines that are just horizontal spacers
          .map(function (elem) {return elem.replace(/\s*\|\|\s*/g, '||');}); // remove all whitespaces from start and end of data strings
        var currentStream = '';

        var streamRegex = new RegExp('=\\s*?(\\S*?)\\s*?=');
        var objRegex = new RegExp('^\\|\\s*?([^\\|]*?)\\|\\|([^|]*?)\\|\\|([^\\|]*?)$');
        var objLuanameRegex = new RegExp('^\\|\\s*?([^\\|]*?)\\|\\|([^|]*?)\\|\\|([^\\|]*?)\\|\\|([^\\|]*?)$');

        for (var i = 0; i < lines.length; i += 1) {
          var match;
          if ((match = lines[i].match(streamRegex)) !== null) {
            trimEntrys(match);
            currentStream = match[1];
            if (streamLog[currentStream] === undefined) {
              streamLog[currentStream] = {};
            }
          } else {
            if (currentStream === undefined) {
              console.warn('A stream has to be specified first');
            }
            if ((match = lines[i].match(objLuanameRegex)) !== null) {
              trimEntrys(match);
              if (streamLog[currentStream][match[1]] === undefined) {
                streamLog[currentStream][match[1]] = {
                  type: match[3],
                  name: match[1],
                  min: undefined,
                  max: undefined,
                  exampleVals: [],
                  desc: match[4],
                  luaName: match[2],
                  stream: currentStream
                };
              } else {
                streamLog[currentStream][match[1]].type = resolveType(streamLog[currentStream][match[1]].type, match[3]);
                streamLog[currentStream][match[1]].luaName = match[2];
                if (match[4] !== '???') {
                  streamLog[currentStream][match[1]].desc = match[4];
                }
              }
            } else if ((match = lines[i].match(objRegex)) !== null) {
              trimEntrys(match);
              if (streamLog[currentStream][match[1]] === undefined) {
                streamLog[currentStream][match[1]] = {
                  type: match[2],
                  name: match[1],
                  min: undefined,
                  max: undefined,
                  exampleVals: [],
                  desc: match[3],
                  luaName: '???',
                  stream: currentStream
                };
              } else {
                streamLog[currentStream][match[1]].type = resolveType(streamLog[currentStream][match[1]].type, match[2]);
                if (match[3] !== '???') {
                  streamLog[currentStream][match[1]].desc = match[3];
                }
              }
            }
          }
        }
      }

      function parseJson (obj) {
        for (var streamName in obj) {
          var objStream = obj[streamName];
          if (streamLog[streamName] === undefined) {
            streamLog[streamName] = objStream;
          } else {
            for (var objName in objStream) {
              if (streamLog[streamName][objName] === undefined) {
                streamLog[streamName][objName] = objStream[objName];
              } else {
                var type = resolveType(streamLog[streamName][objName].type,  objStream[objName].type);
                if (type !== '???') {
                  streamLog[streamName][objName].type = type;
                  for (var propName in streamLog[streamName][objName]) {
                    switch(propName) {
                      case 'exampleVals':
                        for (var i = 0; i < objStream[objName][propName].length; i += 1) {
                          insertExampleVal(streamLog[streamName][objName], objStream[objName][propName][i], 0.5);
                        }
                        break;
                      case 'min':
                        if (streamLog[streamName][objName][propName] > objStream[objName][propName]) {
                          streamLog[streamName][objName][propName] = objStream[objName][propName];
                        }
                        break;
                      case 'max':
                        if (streamLog[streamName][objName][propName] < objStream[objName][propName]) {
                          streamLog[streamName][objName][propName] = objStream[objName][propName];
                        }
                        break;
                      default:
                        if (streamLog[streamName][objName][propName] === '???' && propName.indexOf('ex_') === -1) {
                          streamLog[streamName][objName][propName] = objStream[objName][propName];
                        }
                    }
                  }
                }
              }
            }
          }
        }
      }

      function parseRst (str) {
        var lines = str.split('\n') //split string into lines
          .map(function (elem) {return elem.trim();}) // remove all whitespaces form start and end
          .filter(function (elem) {return elem.indexOf('+-') !== 0;}) // remove all lines that are just horizontal spacers
          .map(function (elem) {return elem.replace(/\s*\|\s*/g, '|');}); // remove all whitespaces from start and end of data strings
        var currentStream = '';

        var streamRegex = new RegExp('\\*\\*\\s*?(\\S*?)\\s*?\\*\\*');
        var objRegex = new RegExp('^\\|\\s*?([^\\|]*?)\\|([^|]*?)\\|([^\\|]*?)\\|$');
        var objLuanameRegex = new RegExp('^\\|\\s*?([^\\|]*?)\\|([^|]*?)\\|([^\\|]*?)\\|([^\\|]*?)\\|$');

        for (var i = 0; i < lines.length; i += 1) {
          var match;
          if ((match = lines[i].match(streamRegex)) !== null) {
            trimEntrys(match);
            currentStream = match[1];
            if (streamLog[currentStream] === undefined) {
              streamLog[currentStream] = {};
            }
          } else {
            if (currentStream === undefined) {
              console.warn('A stream has to be specified first');
            }
            if ((match = lines[i].match(objLuanameRegex)) !== null && match.last() !== 'Description') {
              trimEntrys(match);
              if (streamLog[currentStream][match[1]] === undefined) {
                streamLog[currentStream][match[1]] = {
                  type: match[3],
                  name: match[1],
                  min: undefined,
                  max: undefined,
                  exampleVals: [],
                  desc: match[4],
                  luaName: match[2],
                  stream: currentStream
                };
              } else {
                streamLog[currentStream][match[1]].type = resolveType(streamLog[currentStream][match[1]].type, match[3]);
                streamLog[currentStream][match[1]].luaName = match[2];
                if (match[4] !== '???') {
                  streamLog[currentStream][match[1]].desc = match[4];
                }
              }
            } else if ((match = lines[i].match(objRegex)) !== null && match.last() !== 'Description') {
              trimEntrys(match);
              if (streamLog[currentStream][match[1]] === undefined) {
                streamLog[currentStream][match[1]] = {
                  type: match[2],
                  name: match[1],
                  min: undefined,
                  max: undefined,
                  exampleVals: [],
                  desc: match[3],
                  luaName: '???',
                  stream: currentStream
                };
              } else {
                streamLog[currentStream][match[1]].type = resolveType(streamLog[currentStream][match[1]].type, match[2]);
                if (match[3] !== '???') {
                  streamLog[currentStream][match[1]].desc = match[3];
                }
              }
            }
          }
        }
      }

      function parseStreams (streams) {
        for (var streamName in streams) {

          if (streamLog[streamName] === undefined) {
            streamLog[streamName] = {};
          }

          parse(streamName, streams[streamName], '');
        }
      }

      function insertExampleVal (obj, val, percent) {
        if (obj.exampleVals === undefined) {
          obj.exampleVals = [];
        }

        if (obj.exampleVals.length < 10) {
          obj.exampleVals.push(val);
        } else if (Math.random() > (percent || 0.95)) {
          obj.exampleVals[(Math.floor(Math.random() * 10))] = val;
        }
      }

      function parse (streamName, param, prefix) {
        var type = typeof param;
        var help = streamLog[streamName][prefix];

        switch (type) {
          case 'object':
            if (Array.isArray(param)) {
              for (var i = 0; i < param.length; i += 1) {
                parse(streamName, param[i],  prefix + '[' + i + ']');
              }
            } else {
              for (var prop in param) {
                if (Object.prototype.hasOwnProperty.call(param, prop) ) {
                  parse(streamName, param[prop], prefix + (prefix !== '' ? '.' : '') + prop);
                }
              }
            }
            break;
          case 'number':
            if (help === undefined) {
              streamLog[streamName][prefix] = {
                type: (param % 1 === 0 ? 'int' : 'float'),
                name: prefix,
                min: param,
                max: param,
                exampleVals: [param],
                desc: '???',
                luaName: '???',
                stream: streamName
              };
            } else {
              if (help.min > param || help.min === undefined) {
                help.min = param;
              }

              if (help.max < param || help.max === undefined) {
                help.max = param;
              }

              if (help.type === 'int' && param % 1 !== 0) {
                help.type = 'float';
              }

              insertExampleVal(help, param);
            }
            break;
          case 'string':
            if (help === undefined) {
              streamLog[streamName][prefix] = {
                type: 'string',
                name: prefix,
                exampleVals: [param],
                desc: '???',
                luaName: '???',
                stream: streamName
              };
            } else {
              insertExampleVal(help, param);
            }
            break;
          case 'boolean':
            if (help === undefined) {
              streamLog[streamName][prefix] = {
                type: 'boolean',
                name: prefix,
                exampleVals: [param],
                desc: '???',
                luaName: '???',
                stream: streamName
              };
            } else {
              insertExampleVal(help, param);
            }
            break;
          default:
            console.warn('Unrecognized type');
        }
      }

      function toTable (bool) {
        var res = {};

        for (var streamName in streamLog) {
          for (var propName in streamLog[streamName]) {
            var help = streamLog[streamName][propName];
            res[streamName + ' ' + propName] = help;
            if (bool) {
              for (var i = 0; i < help.exampleVals.length; i += 1) {
                res[streamName + ' ' + propName]['ex_' + i] = help.exampleVals[i];
              }
            }
          }
        }
        return res;
      }

      function toWikitable () {
        var res = '';

        for (var streamName in streamLog) {
          res += '\n\n=' + streamName + '=\n' +
            ':{| class="wikitable"\n' +
            '|-\n' +
            '! Name !! Corresponding LUA names !! Type !! Description\n';

          for (var propName in streamLog[streamName]) {
            if (propName.indexOf('exampleVal') === -1 && propName.indexOf('min') === -1 && propName.indexOf('max') === -1) {
              var help = streamLog[streamName][propName];
              res += '|-\n' +
                '| ' + help.name + ' || ' + help.luaName + ' || ' + help.type + ' || ' + help.desc + '\n';
            }
          }

          res += '|}\n';
        }

        return res;
      }



      function getLongestStrsHelpers (list) {
        var res = {};
        for (var i = 0; i < list.length; i += 1) {
          for (var key in list[i]) {
            for (var key2 in list[i][key]) {
              var short = list[i][key][key2]
              if (key2.indexOf('exampleVal') === -1 && key2.indexOf('min') === -1 && key2.indexOf('max') === -1) {
                if (res[key2] === undefined || res[key2] < short.length) {
                  res[key2] = short.length;
                }
              }
            }
          }
        }
        return res;
      }

      function pad (str, toLen) {
        return (str + ' '.repeat(toLen)).slice(0, toLen)
      }

      function lineHelper (obj, lengths) {
        return '| ' + pad(obj.name, lengths.name) + ' | ' + pad(obj.luaName, lengths.luaName) + ' | ' + pad(obj.type, lengths.type) + ' | ' + pad(obj.desc, lengths.desc) + ' |\n';
      }

      function toRst () {
        var res = ''
          , headers = {name: 'Name', luaName: 'Corresponding LUA names', type: 'Type', desc: 'Description'}
          ;

        for (var streamName in streamLog) {
          res += '\n\n**' + streamName + '**\n\n';
          var lengths = getLongestStrsHelpers([streamLog[streamName], {_: headers}])
          var seperator = '+' + ('-'.repeat(lengths.name + 2)) + '+' + ('-'.repeat(lengths.luaName + 2)) + '+' + ('-'.repeat(lengths.type + 2)) + '+' + ('-'.repeat(lengths.desc + 2)) + '+\n';

          res += seperator;
          res += lineHelper(headers, lengths);
          res += seperator.replace(/-/g, '=')

          for (var propName in streamLog[streamName]) {
            res += lineHelper(streamLog[streamName][propName], lengths);
            res += seperator
          }

          res += '\n';
        }

        return res;
      }
    }
  };
}]);
