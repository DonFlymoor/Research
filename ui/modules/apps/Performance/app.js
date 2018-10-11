(function () {
  'use strict';

  angular.module('beamng.apps')

.directive('physicsperf', ['bngApi', function (bngApi) {
  return {
    template:
      `<div class="bngApp filler" style="font-size: 0.9em;">
        <table border="0" ng-if="data.length > 0">
          <tr ng-repeat="v in data track by $index">
            <td>{{ v.name }}</td>
            <td>{{ v.val }}</td>
          </tr>
          <tr>
            <td>Sum</td>
            <td>{{ sum }}</td>
          </tr>
        </table>
      </div>`,
    link: function (scope) {
      scope.data = [];

      scope.$on('physicsperf', function (event, data) {
        //console.log(data);

        var sum = data.sum.toFixed(2);
        delete data.sum; //  otherwise the for loop also loops over the data.sum property

        var dataDedupe = {}
        for(var objid in data) {
          var objName = data[objid][0];
          if(dataDedupe[objName] !== undefined)  {
            dataDedupe[objName][1] += data[objid][1]
            dataDedupe[objName][5]++;
          } else {
            dataDedupe[objName] = data[objid];
            dataDedupe[objName][5] = 1;
          }
        }
        var dataArr = [];
        for(var objid in dataDedupe) {
          dataArr.push(dataDedupe[objid]);
        }
        dataArr = dataArr
          .sort((a, b) => b[1] - a[1])
          .map(e => ({
            name: e[0] + (e[5] > 1 ? ` (${e[5]})`: ''),
            val: e[1].toFixed(2)
          }))

        scope.$evalAsync(() => {
          scope.data = dataArr;
          scope.sum = sum;
        })
      });

      scope.$on('$destroy', function () {
        bngApi.engineLua('extensions.unload("ui_physicsPerf")');
      });

      bngApi.engineLua('extensions.load("ui_physicsPerf")');
    }
  };
}]);

})();
