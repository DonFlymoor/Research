angular.module('beamng.stuff')

.controller('TutorialIntroController', ['$log', '$scope', '$state', 'bngApi', function ($log, $scope, $state, bngApi) {
  var vm = this;

}])


angular.module('beamng.stuff')
.directive('typewriter', function () {
  "use strict";
  return {
    restrict : 'EAC',
    scope : {
      speed: '=speed',
      cursor: '=cursor',
    },
     link: function (scope, element, attributes) {
      if(!scope.speed) scope.speed = 100;

      var text = element[0].innerHTML;
      element[0].innerHTML = '';
      var cur = ''
      var prevSpeed = 0;
      var replaceChars = 0;
      function parseCommands() {
        if(text.indexOf('<br/>') == 0) {
          cur += '<br/>';
          text = text.slice(5);
          return;
        }
        if(text[0] == "\n") {
          cur += '<br/>';
          text = text.slice(1);
          return parseCommands();
        }
        if(text.indexOf('\\b') == 0) {
          cur = cur.substring(0, cur.length-1)
          text = text.slice(2);
          return parseCommands();
        }        
        if(text.indexOf('</tw>') == 0) {
          text = text.slice(5);
          scope.speed = prevSpeed;
          return parseCommands();
        }
        if(text[0] == "<") {
          var res = text.match(/^<\s*tw\s*([a-z0-9_-]+)\s*={0,1}\s*['"]{0,1}(\d*)['"]{0,1}\s*>/);
          if(res && res[1] == 'speed') {
            prevSpeed = scope.speed;
            scope.speed = parseInt(res[2]);
            text = text.slice(res[0].length);
            return parseCommands();
          } else if(res && res[1] == 'clear') {
            cur = '';
            text = text.slice(res[0].length);
            return parseCommands();
          }
        }
      }

      function typeChar() {
        parseCommands();
        if(text.length == 0) return;

        cur += text[0];
        text = text.slice(1);
        element[0].innerHTML = '<span>'+cur+'</span>';
        if(scope.cursor) element[0].innerHTML += '<span class="cursor">|</span>'
        setTimeout(typeChar, scope.speed);
      }
      setTimeout(typeChar, 2000);
    }
  }
});
