angular.module('beamng.apps')
.directive('cruiseControl', ['$log', 'bngApi', function ($log, bngApi) {
  return {
    template:
      '<object style="width:100%; height:100%;" type="image/svg+xml" data="modules/apps/CruiseControl/cruise_control_t01.svg"/>',
    replace: true,
    restrict: 'EA',
    scope: true,
    link: function (scope, element, attrs) {
        var TAG = '[beamng.apps:CruiseControl]';

        var unitMultiplier = {
          'metric': 3.6,
          'imperial': 2.23694
        };

        element.on('load', function () {
          var svg = element[0].contentDocument
            , setBtn = angular.element(svg.getElementById('set_btn'))
            , resBtn = angular.element(svg.getElementById('res_btn'))
            , ccBtn = angular.element(svg.getElementById('cc_btn'))
            , ccIcon = svg.getElementById('cc_icon')
            , upBtn = angular.element(svg.getElementById('up_btn'))
            , downBtn = angular.element(svg.getElementById('down_btn'))
            , speedTxt = svg.getElementById('target_speed_txt')
            , state = null
            , speedStep = 1.0 / 3.6
            , speedMult = 1.0
            , offColor = '#949494'
            , onColor = '#FF6600'
          ;


          scope.$on('SettingsChanged', function (event, data) {
            speedStep = 1.0 / unitMultiplier[data.values.uiUnitLength];
            bngApi.activeObjectLua('extensions.cruiseControl.requestState()');
          });

          setBtn.on('click', function () {
            bngApi.activeObjectLua('extensions.cruiseControl.holdCurrentSpeed()');
          });

          resBtn.on('click', function () {
            if (!state.isEnabled && state.targetSpeed > 0.1)
          bngApi.activeObjectLua('extensions.cruiseControl.setEnabled(true)');
          });

          ccBtn.on('click', function () {
            bngApi.activeObjectLua(`extensions.cruiseControl.setEnabled(${!state.isEnabled})`);
            bngApi.activeObjectLua('extensions.cruiseControl.requestState()');
          });

          upBtn.on('click', function () {
            bngApi.activeObjectLua(`extensions.cruiseControl.setSpeed(${state.targetSpeed + (speedStep * speedMult)})`);
            bngApi.activeObjectLua('extensions.cruiseControl.requestState()');
          });

          downBtn.on('click', function () {
            bngApi.activeObjectLua(`extensions.cruiseControl.setSpeed(${state.targetSpeed - (speedStep * speedMult)})`);
            bngApi.activeObjectLua('extensions.cruiseControl.requestState()');
          });

          scope.$on('CruiseControlState', function (event, data) {
            $log.debug(TAG, 'state:', data);
            state = data;
            speedTxt.innerHTML = Math.round(state.targetSpeed / speedStep);
            if (state.isEnabled) {
              speedTxt.style.fill = onColor;
              ccIcon.style.fill = onColor;
            } else {
              speedTxt.style.fill = offColor;
              ccIcon.style.fill = offColor
            }
          });
          
          scope.$on('VehicleFocusChanged', function () {
            bngApi.activeObjectLua('extensions.cruiseControl.requestState()');
          });
          
          scope.$on('AIStateChange', function (event, data) {
            bngApi.activeObjectLua('extensions.cruiseControl.setEnabled(false)');
            bngApi.activeObjectLua('extensions.cruiseControl.requestState()');
          });

          bngApi.engineLua('settings.requestState()');
        });
    }
  };
}]);
