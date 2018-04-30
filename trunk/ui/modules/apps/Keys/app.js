angular.module('beamng.apps')
  .directive('keyList', ['StreamsManager', 'bngApi', '$state', function (StreamsManager, bngApi, $state) {
    return {
      templateUrl: 'modules/apps/Keys/template.html',
      replace: true,
      restrict: 'EA',
      link: function (scope, element, attrs) {
        scope.bindings = [];

        function existsAt(arr, ac) {
          return arr.map(function (elem, i) {
            return (elem.actionName === ac ? i : -1);
          }).filter(function (elem) {
            return elem !== -1;
          });
        }

        scope.small = true;
        var timeout;
        scope.toggleSmall = () => {
          scope.small = !scope.small
          clearTimeout(timeout);
        }

        scope.$on('VehicleChange', showBriefly)
        scope.$on('VehicleFocusChanged', showBriefly)

        function showBriefly () {
          if (scope.small) {
            timeout = setTimeout(function () {
              scope.$evalAsync(() => {
                scope.small = true;
              });
            }, 10000);
          }
          scope.$evalAsync(() => {
            scope.small = false;
          });
        };

        scope.goToBindings = (action, control) => {
          scope.$emit('MenuHide', false);
          $state.go('menu.options.controls.bindings.edit', {action: action.actionName, oldBinding: {control: control.c, device: control.n}});
        };

        scope.show = 0;
        scope.players = []; // so we know if the header is to be displayed, no other function, because it makes no sense to cycel through empty binding lists (thinking of pcs with lots of controllers equiped, but only one person playing or smth like that)

        scope.forward = function () {
          scope.show = (scope.show + 1) % scope.bindings.length;
        };

        scope.backward = function () {
          scope.show = (scope.show === 0 ? scope.bindings.length - 1 : scope.show - 1 );
        };

        scope.$on('InputBindingsChanged', function (event, data) {
          // console.log(data);
          var specialKeys = [];
          scope.players = [];

          for (var i = 0; i < data.bindings.length; i++) {
            for (var j = 0; j < data.bindings[i].contents.bindings.length; j++) {
              var bind = data.bindings[i].contents.bindings[j];

              if (specialKeys[bind.player] === undefined) {
                specialKeys[bind.player] = [];
              }
              // Count the number of players (no other functionality)
              if (!scope.players[bind.player]) {
                scope.players[bind.player] = true;
              }

              if (data.actions[bind.action].cat === 'vehicle_specific') {
                var exAt = existsAt(specialKeys[bind.player], bind.action);
                if (exAt.length === 0) {
                  specialKeys[bind.player].push({
                    control: [{
                      c: bind.control,
                      d: data.bindings[i].contents.devicetype,
                      n: data.bindings[i].devname
                    }],
                    actionName: bind.action,
                    action: data.actions[bind.action].title,
                    order: data.actions[bind.action].order,
                    i: j
                  });
                } else {
                  specialKeys[bind.player][exAt[0]].control.push({
                    c: bind.control,
                    d: data.bindings[i].contents.devicetype,
                    n: data.bindings[i].devname
                  });
                }
              }
            }
          }
          for (var k in specialKeys) {
            specialKeys[k].sort(function (a, b) {
              return a.order - b.order;
            });
          }
          // console.log(specialKeys);
          // console.log(scope.players);
          scope.$evalAsync(function () {
            scope.bindings = specialKeys.map(function (elem) { return elem.sort(function (a, b) {
                return a.order - b.order;
              });
            });
            if (scope.show >= scope.bindings.length) {
              scope.show = 0;
            }
          });
        });
        bngApi.engineLua('bindings.notifyUI("keys app: link init")');

          // copied, no clue why there needs to be this timeout
        setTimeout(function () {
          bngApi.engineLua('settings.requestState()');
        }, 200);
      }
    };
  }]);

