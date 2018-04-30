angular.module('beamng.apps')
.directive('annotationInfo', ['UiUnits', function (UiUnits) {
  return {
    template: 
    '<div style="height:100%; width:100%;" class="bngApp"><table border=0 width="100%">' +
    '<tr><td>time</td><td>{{data.runTime | date: "mm:ss"}}</td></tr>' +
    '<tr><td># data</td><td>{{data.generatedSets | number: 0}}</td></tr>' +
    '<tr ng-if="data.left"><td># left:</td><td>{{data.left | number: 0}}</td></tr>' +
    '<tr ng-if="data.progress"><td>Progress</td><td>{{data.progress | number: 2}} %</td></tr>' +
    '<tr ng-if="data.eta"><td>ETA</td><td>{{data.eta | date: "mm:ss"}}</td></tr>' +
    '</table>' + 
    //'<md-button md-no-ink ng-click="toggleViz()">Toggle Mode</md-button>' +
    '<md-button md-no-ink ng-click="cancelAnnotation()">Cancel</md-button></div>',
    replace: true,
    restrict: 'EA',
    scope: true,
    controller: ['$log', '$scope', 'bngApi', 'StreamsManager', function ($log, $scope, bngApi, StreamsManager) {
      $scope.$on('AnnotationStateChanged', function (event, data) {
        //console.log(data);
        $scope.$evalAsync(function () {
          $scope.data = data;
        });
      });
      $scope.cancelAnnotation = function() {
        bngApi.engineLua('extensions.util_annotation.cancel()');
      }

      $scope.toggleViz = function() {
        bngApi.engineScript('toggleAnnotationVisualize();');
      }
      
    }]
  };
}]);