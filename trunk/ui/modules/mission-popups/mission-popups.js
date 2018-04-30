angular.module('beamng.stuff')

.directive('missionPopups', ['$rootScope', function ($rootScope) {
  return {
    template: '<div class="mission-popups" ng-show="missionPopupsVisible" ng-transclude></div>',
    replace: true,
    transclude: true,
    scope: false,
    link: function (scope, element, attrs) {
      scope.missionPopupsVisible = true;

      scope.$on('ToggleMissionPopups', (_, state) => {
        if (typeof (state) === 'boolean')
          scope.missionPopupsVisible = state;
        else
          scope.missionPopupsVisible = !scope.missionPopupsVisible;

        scope.$evalAsync();
      });

      $rootScope.$on('$stateChangeStart', (_, state) => {
        scope.missionPopupsVisible = state.name === 'menu';
      });
    }
  };
}])

.directive('missionInfo', ['bngApi', 'Settings', 'UiUnits', function (bngApi, Settings, UiUnits) {
  return {
    template: `
      <div class="mission-info" ng-show="data">
        <div class="header">
          
          <div style="position: relative">
            <svg class="header-icon"><use xlink:href="" ng-href="{{ '#' + data.type }}"></svg>
            <div class="header-title">{{ data.title | translate }}</div>
            <div class="header-subtitle">{{ data.type }}</div>
          </div>
        </div>

        <div class="body" ng-if="data.data">
          <div class="data-table">
            <div class="row" ng-repeat="entry in data.data">
              <span class="cell entry-label">{{ entry.label | translate }}</span>
              <span class="cell entry-val">{{ entry.value | translate }}</span>
            </div>
          </div>
        </div>

        <div class="buttons">
          <div class="button" ng-repeat="btn in data.buttons" ng-click="run(btn.cmd)">
            <binding action="{{ ::btn.action }}"></binding> <span style="padding: 0 8px">{{ btn.text | translate }}</span>
          </div>
        </div>
      </div>`,
    replace: true,
    link: function (scope, element, attrs) {
      scope.data = null;

      scope.$on('MissionInfoUpdate', (_, data) => {
        //console.log('got mission:', data);
        scope.data = data;

        if (data && data.data) {
          var distObj = data.data.find(x => x.label == 'distance');
          if (distObj) {
            var converted = UiUnits.length(distObj.value, Settings.values.uiUnitLength);
            if (converted !== null) {
              distObj.value = `${converted.val.toFixed(2)} ${converted.unit}`;
            }
          }
        }
        
        scope.$evalAsync();
      });

      scope.run = bngApi.engineLua;
    }
  };
}]);