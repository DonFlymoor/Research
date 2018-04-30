angular.module('beamng.apps')
  .directive('messages', ['logger', function (logger) {
    return {
      template:
      '<div style="background:transparent;" class="fillParent Messages">' +
      '<link type="text/css" rel="stylesheet" href="modules/apps/messages/app.css">' +
      '<div ng-repeat="n in cat" class="message bngApp" layout="row" layout-align="start center">' +
      '<div ng-if="n.icon" class="icon">' +
      '<md-icon class="material-icons">{{n.icon}}</md-icon>' +
      '</div>' +
      '<div bng-translate="{{n.txt}}" flex style="flex-wrap: wrap" layout="row" layout-align="start center" class="fillParent"></div>' +
      '</div>' +
      '</div>',
      replace: true,
      restrict: 'EA',
      scope: true,
      controller: ['$log', '$scope', 'bngApi', 'StreamsManager', '$timeout', '$sce', 'Utils', function ($log, $scope, bngApi, StreamsManager, $timeout, $sce, Utils) {
        $scope.cat = {};
        var xinputStatus = {
          0: { connected: false, battery: 1 },
          1: { connected: false, battery: null },
          2: { connected: false, battery: null },
          3: { connected: false, battery: null }
        };

        function getIcon(category) {
          if (category.indexOf('damage.') !== -1) {
            return 'priority_high';
          }

          if (category.indexOf('controller') !== -1) {
            return undefined;
          }

          switch (category) {
            case 'cameramode':
              return 'videocam';
            default:
              return 'menu';
          }
        }

        $scope.$on('Message', function (event, args) {
          // logger.App.log(args);
          var ttl = args.ttl || 5;
          var category = args.category || 'default';
          // logger.error(args);
          var matchedCategories = [];

          // try to match the category as a regexp. for example, match all "^damage\." categories, and set an empty message to them all
          var re = new RegExp(category);
          for (var i in $scope.cat) if (re.test(i)) matchedCategories.push(i);

          // if no category was found, assume this is not a regexp but an actual category name
          if (matchedCategories.length == 0) matchedCategories.push(category);

          // go through all categories, removing previous messages and adding new messages
          for (i in matchedCategories) {
            var cat = matchedCategories[i];

            // clean previous message in this category
            $timeout(function () {  // timeout fixes $rootScope:inprog error
              $scope.$apply(() => {
                if ($scope.cat[cat] == undefined) return;
                if ($scope.cat[cat].promise == undefined) return;
                $timeout.cancel($scope.cat[cat].promise);
                delete ($scope.cat[cat])
              });
            })

            // apply new message to this category
            $timeout(function () {  
              $scope.$apply(() => {
                if (args.msg == "") return; // empty message indicates we want to clear this category, so don't add anything, just return
                $scope.cat[cat] = { icon: args.icon || getIcon(cat), txt: args.msg };
                $scope.cat[cat].promise = $timeout(
                  function () { delete ($scope.cat[cat]); },
                  ttl * 1000
                );
              });
            })
          }
        });

        // xinput module almost completyl as before, since it didn't end up well in it's own module :-(
        // BTW: there si as small problem if two controllers are connected at the same time, only one will be shown
        $scope.$on('XInputControllerUpdated', function (event, args) {
          // logger.App.log(args);
          var ttl = 10; // in seconds
          var levels = { 0: "empty", 1: "low", 2: "medium", 3: "full" };
          var n = args.controller;
          var connected = args.connected;
          var battery = args.battery; // 0 to 3 included
          var m;
          var i;

          if (battery !== undefined) {
            if (xinputStatus[n].battery !== null) {
              var level = levels[battery];

              m = "<div class='imgdiv'>";

              for (i in xinputStatus) {
                m += "  <div class='" + (n == i ? "blink" : "imgover nonsubject") + " color controller_mask_" + i + "'></div>";
              }

              m += "  <div class='color imgover bat_" + level + " battery_" + battery + "_mask'></div>";
              m += "</div>";
              m += "<div>Controller " + (n + 1) + " Battery " + level + "</div>";

              $scope.$emit('Message', { msg: m, ttl: ttl, category: 'battery_xi_controller_' + n });
            }
            xinputStatus[n].battery = battery;
          }

          if (connected !== undefined) {
            if (connected === 0) {
              xinputStatus[n].battery = null;
            }
            xinputStatus[n].connected = connected;

            m = "<div class='imgdiv'>";

            for (i in xinputStatus) {
              m += "  <div class='" + (n == i ? "blink" : "imgover nonsubject") + " color controller_mask_" + i + "'></div>";
            }

            m += "  <div style=\"position: absolute; top: 0; right: 0; bottom: 0; left:0;\" layout layout-align=\"center center\">";
            m += "    <md-icon class=\"material-icons\" style=\"color: white; font-size:20px;\">games</md-icon>";
            m += "  </div>";
            m += "</div>";
            m += "<div>Controller " + (n + 1) + " " + (connected ? "connected" : "unplugged") + "</div>";

            $scope.$emit('Message', { msg: m, ttl: ttl, category: 'xi_controller_' + n });
          }
        });
      }]
    };
  }]);
