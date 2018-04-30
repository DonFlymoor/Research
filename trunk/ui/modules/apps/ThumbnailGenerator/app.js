angular.module('beamng.apps')
  .directive('thumbnailGenerator', ['logger', 'StreamsManager', 'UiUnits', 'bngApi', function (logger, StreamsManager, UiUnits, bngApi) {
    return {
      templateUrl: 'modules/apps/ThumbnailGenerator/app.html',
      replace: true,
      restrict: 'EA',
      link: function (scope, element, attrs) {
        'use strict';
        StreamsManager.add(['electrics']);

        bngApi.engineLua('extensions.load("util_thumbnailApp")');

        scope.rotation = 0;
        scope.fov = 20;
        scope.distance = 1;
        scope.thumbnailType = {};
        scope.view = ['default', 'frontGarage', 'sideGarage']
        scope.view.selectedView = 'default'
        scope.offsets = {};
        scope.offsets.x = 0;
        scope.offsets.y = 0;
        scope.offsets.z = 0;
        scope.width = 1000;
        scope.plate = ""
        scope.default = true;
        scope.currentMap = false;

        var thumbnailTable = []
        var views = [];
        scope.parameters = [];
        var thumbnailParams = [];
        scope.$on('$destroy', function () {
          StreamsManager.remove(['electrics']);
        });

        scope.setParameters = function () {
          scope.parameters = [];
          for (var v in scope.offsets) {
            scope.parameters.push(scope.offsets[v])
          }
          scope.parameters.push(scope.rotation);
          scope.parameters.push(scope.fov);
          scope.parameters.push(scope.distance);
          scope.parameters.push(scope.width);
          thumbnailParams[scope.view.selectedView] = scope.parameters
        }

        scope.$watch('view.selectedView', function () {
          for (var v in thumbnailParams) {
            if (v === scope.view.selectedView) {
              scope.rotation = thumbnailParams[v][3]
              scope.fov = thumbnailParams[v][4]
              scope.distance = thumbnailParams[v][5]
              scope.offsets.x = thumbnailParams[v][0];
              scope.offsets.y = thumbnailParams[v][1];
              scope.offsets.z = thumbnailParams[v][2];
              scope.width = thumbnailParams[v][6]
              selectView(scope.view.selectedView)
            }
          }
        })

        scope.focus = function () {
          bngApi.engineLua('setCEFFocus(true)');
        }

        scope.argsToLua = function (arr) {
          return arr.map(function (i) {
            return bngApi.serializeToLua(i);
          }).join(',');
        };

        function selectView(v) {
          thumbnailTable = [];

          for (var x in thumbnailParams) {
            thumbnailTable.push(x + '={' + scope.argsToLua(thumbnailParams[x]) + '}')
          }
          bngApi.engineLua('util_thumbnailApp.setViews(' + bngApi.serializeToLua(scope.default) + ', ' + bngApi.serializeToLua(v) + ', {' + scope.argsToLua(thumbnailTable).replace(/['"]+/g, '') + '})');
        }

        scope.$watch('parameters', function () {
          selectView(scope.view.selectedView)
        });

        scope.generateThumbs = function () {
          bngApi.engineLua('util_thumbnailApp.createThumbnails(' + (scope.default) + ', '
            + bngApi.serializeToLua(scope.currentMap) + ', ' + bngApi.serializeToLua(scope.plate) + ', {' 
            + scope.argsToLua(scope.parameters)+ '}, ' + scope.width  + ')');
        };

      }
    };
  }]);