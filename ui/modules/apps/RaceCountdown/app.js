angular.module('beamng.apps')

.value('raceCountdownData', {
  messages: [],
  stepTimeout: undefined,
  appExists: false
})

.directive('raceCountdown', [function () {
  return {
    template: 
    '<div style="height:100%; width:100%; background:transparent; text-shadow: 3px 3px 5px rgba(0, 0, 0, 0.43); font-weight: bold; color: white;" layout="row" layout-align="center center" class="RaceCountdown">' + 
      '<link type="text/css" rel="stylesheet" href="modules/apps/RaceCountdown/app.css">' +
      '<div>{{ txt | translate }}</div>' + 
    '</div>',
    replace: true,
    restrict: 'EA',
    scope: true,
    controller: ['$element', '$filter', 'logger', '$scope', '$timeout', 'raceCountdownData', 'bngApi', function ($element, $filter, logger, $scope, $timeout, raceCountdownData, bngApi) {
      var msgIndex = 0
        , paused = false
        , raceStarted = false
        , msgElement = angular.element($element[0].childNodes[1])
      ;

      if (!raceCountdownData.appExists) {
        raceCountdownData.appExists = true;

        $scope.$on('RaceStart', function (event) {
          raceStarted = true;
        });

        $scope.$emit('requestPhysicsState');

        // The message to be displayed
        $scope.txt = '';

        $scope.$on('ScenarioFlashMessageReset', function (event, data) {
          $element.css({'font-size': '2em'});
        });

        $scope.$on('ScenarioNotRunning', function () {
          msgIndex = 0;
          raceCountdownData.messages = [];
          $scope.txt = '';
          try {
            $timeout.cancel(raceCountdownData.stepTimeout);
            raceCountdownData.stepTimeout = undefined;
          } catch (e) {
            console.warn(e);
          }
        });

        // This event a group of messages to be displayed, in the form of an array of arrays.
        // Each array element has 2 or 3 elements of its own:
        // 0: The actual message to be displayed
        // 1: Time (in seconds) to show that message
        // 2 (optional): 
        //  call to the Lua engine 
        //  or a js callback 
        //  or if none of the above two is provided but 3 is -> 3
        // 3 (optional): If the font should be big or not (mostly used for countdown)
        $scope.$on('ScenarioFlashMessage', function (event, data) {
          // logger.debug('[race-count-down] received ScenarioFlashMessage w/ %o', data);
          // console.log('ScenarioFlashMessage', data);
          // never use for in loop on an array that's invented for objects while for with a counter is designed for arrays
          // otherwise protoyiping and other stuff can break loops unexpectedly from everywhere in js, so for instance 3rd party apps otherwise
          for(var i=0; i < data.length; i += 1) {
            raceCountdownData.messages.push(data[i]);
          }
          
          if ((!paused || raceStarted) && raceCountdownData.stepTimeout === undefined) {
            playMessages();
          }
        });

        var playMessages = function () {
          msgElement.removeClass('fadeOut');
          msgElement.addClass('fadeIn');
          $element.css({'font-size': '2em'});

          if (raceCountdownData.messages.length === 0) return;

          var msg = raceCountdownData.messages[0];
          $scope.txt = typeof(msg[0]) == 'object' ? $filter('translate')(msg[0].txt, msg[0].context) : msg[0];
          $scope.$digest();
          
          if (msg.length > 2) {
            // if the last parameter is the boolean true use large font otherwise use small one
            if ((msg.length > 3 && msg[3]) || (typeof msg[2] === 'boolean' && msg[2])) {
              $element.css({'font-size': '8em'});
            } else {
              $element.css({'font-size': '2em'});
            }
            // if a string is passed execute it
            if (typeof msg[2] === 'string') {
              bngApi.engineLua(msg[2]);
            }

            // if a function is passed execute it as well
            if (typeof msg[2] === 'function') {
              msg[2]();
            }
          }
          raceCountdownData.messages.shift();
          
          setTimeout(() => {
            msgElement.removeClass('fadeIn');
          }, 200);

          setTimeout(() => {
            msgElement.addClass('fadeOut');
          }, (parseFloat(msg[1]) * 1000 - 200));

          raceCountdownData.stepTimeout = $timeout(timeoutHelper, parseFloat(msg[1]) * 1000);
        };

        var timeoutHelper = function () {
          $scope.txt = '';
          raceCountdownData.stepTimeout = undefined;
          if (raceCountdownData.messages.length > 0) {
            playMessages();
          }
        };

        $scope.$on('updatePhysicsState', function (event, state) {
          paused = !state;
          if (!state) {
            $timeout.cancel(raceCountdownData.stepTimeout);
            raceCountdownData.stepTimeout = undefined;
          } else if (state) {
            timeoutHelper();
          }
        });

        // just in case...
        $scope.$on('$destroy', function () {
          $timeout.cancel(raceCountdownData.stepTimeout);
          raceCountdownData.stepTimeout = undefined;
          raceCountdownData.messages = [];
          raceCountdownData.appExists = false;
        });
      }
    }]
  };
}]);