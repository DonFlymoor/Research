angular.module('beamng.stuff')

.controller('TemplateController', ['$log', '$scope', '$state', 'bngApi', function ($log, $scope, $state, bngApi) {
  var vm = this;

  bngApi.engineLua('extensions.load("template")');
  // make sure we unload the lua module as well when this page is unloaded
  $scope.$on('$destroy', function () {
    bngApi.engineLua('extensions.unload("template")');
  });

  // example data holder
  $scope.data = {};
  $scope.testtext = 'hello,world,this,is,a,test';

  // example for a function call
  $scope.doSomething = function(arg1) {
    console.log("calling function with arg: ", arg1);
    // simple calls with no return value:
    bngApi.engineLua('template.doSomething(' + bngApi.serializeToLua(arg1) + ')');
    
    // calls with return values:
    bngApi.engineLua('template.doSomething(' + bngApi.serializeToLua(arg1) + ')', function (response) {
      console.log("got response from lua: ", response);
      $scope.$apply(function () { 
        $scope.data = response;
      });
    });
  
  }
}])


