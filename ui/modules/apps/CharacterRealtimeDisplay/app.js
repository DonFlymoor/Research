angular.module('beamng.apps')
  .directive('characterRealtimeDisplay', [function () {
    return {
      template: `
    <div ng-class="{'characterRealtimeDisplay-show': messagePresent}" layout="row">
      <img ng-if="img" ng-src="{{img}}" style="margin-right: 20px; height: 100%;"/>
      <div flex bng-translate="{{translate | json}}"></div>
    </div>
    `,
      replace: true,
      restrict: 'EA',
      scope: true,
      controller: ['$element', 'logger', '$scope', '$timeout', 'bngApi', function ($element, logger, $scope, $timeout, bngApi) {
        function clear() {
          $scope.messagePresent = false;
          $scope.translate = { fallback: '', txt: '' };
          $scope.img = undefined;
        }
        clear();

        $scope.$on('ScenarioNotRunning', clear);

        $scope.$on('CharacterRealtimeDisplay', function (event, data) {
          $scope.messagePresent = data !== undefined;

          if ($scope.messagePresent) {
            $scope.$evalAsync(function () {
              // because lua sometimes is not able to send strings...
              $scope.translate = { fallback: `${data.msg}`, txt: `${data.msg}`, context: data.context };
              $scope.img = data.img; // let's just hope lua does not send us invalid paths
            });
          } else {
            clear();
          }
        });
      }]
    };
  }]);