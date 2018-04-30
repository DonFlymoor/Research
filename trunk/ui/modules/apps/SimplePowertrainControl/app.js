angular.module('beamng.apps')
.directive('simplePowertrainControl', ['bngApi', 'StreamsManager', 'UiUnits', '$interval', function (bngApi, StreamsManager, UiUnits, $interval) {
  return {
    template:
    `<svg viewBox = "0 0 250 250" style="margin:0; padding:0; pointer-event:none;">
      <defs>
        <image id="ignition" width="100" height="100" xlink:href="modules/apps/SimplePowertrainControl/ignition_btn.svg" />

        <g id="connected">
          <circle r="17.5" cx="17.5" cy="17.5" fill="#343434"/>
          <use fill="white" width="35" height="35" xlink:href="#powertrain_shaft_connected" />
        </g>
        <g id="disconnected">
          <circle r="17.5" cx="17.5" cy="17.5" fill="#343434"/>
          <use fill="white" width="35" height="35" xlink:href="#powertrain_shaft_disconnected" />
        </g>
        <g id="highRangeBoxIcon">
          <circle r="16.5" cx="17.5" cy="17.5" fill="#FFFFFF"/>
          <use fill="#343434" width="35" height="35" xlink:href="#powertrain_rangebox_high" />
        </g>
        <g id="low">
          <circle r="16.5" cx="17.5" cy="17.5" fill="#FFFFFF"/>
          <use fill="#343434" width="35" height="35" xlink:href="#powertrain_rangebox_low" />
        </g>
        <g id="lockedIcon">
          <circle r="17.5" cx="17.5" cy="17.5" fill="#343434"/>
          <use fill="white" width="35" height="35" xlink:href="#powertrain_differential_closed" />
        </g>
        <g id="openIcon">
          <circle r="17.5" cx="17.5" cy="17.5" fill="#343434"/>
          <use fill="white" width="35" height="35" xlink:href="#powertrain_differential_open" />
        </g>
        <g id="wheelconnected">
          <circle r="17.5" cx="17.5" cy="17.5" fill="#343434"/>
          <use fill="white" width="35" height="35" xlink:href="#powertrain_wheel_connected" />
        </g>
        <g id="wheeldisconnected">
          <circle r="17.5" cx="17.5" cy="17.5" fill="#343434"/>
          <use fill="white" width="35" height="35" xlink:href="#powertrain_wheel_disconnected" />
        </g>
        <g id='lsdIcon'>
          <circle r="17.5" cx="17.5" cy="17.5" fill="#343434"/>
          <use fill="white" width="35" height="35" xlink:href="#powertrain_differential_lsd" />
        </g>

        <g id="escGrp">
          <circle r="16.5" cx="17.5" cy="17.5" fill="#FFFFFF"/>
          <path d="M2,18.5 a1,1 0 0,0 30,0" id="escLight" />
          <use fill="#343434" id="escIcon" width="35" height="35" xlink:href="#powertrain_esc" />
        </g>

        <g id="n2oGrp">
          <circle r="17.5" cx="17.5" cy="17.5" fill="#343434"/>
          <use id="n2oIcon" width="35" height="35" fill="#FFF" xlink:href="#powertrain_n2o" />
          <circle id="n2oLight" style="transform-origin: 50% 50%; transform: rotate(-90deg)" cx="17.5" cy="17.5" r="13.5" fill="transparent" stroke-width="3px" stroke-dasharray="84.78"/>
        </g>

        <g id="jatoGrp">
          <circle r="17.5" cx="17.5" cy="17.5" fill="#343434"/>
          <use id="jatoIcon" width="35" height="35" style="transform-origin: 17.5px 17.5px; transform: scale(0.85) rotate(-20deg)" fill="#FFF" xlink:href="#powertrain_jato" />
          <circle id="jatoLightBackground" style="transform-origin: 50% 50%; transform: rotate(-90deg)" cx="17.5" cy="17.5" r="17.5" fill="transparent" stroke="#7da7d9" stroke-width="4px" stroke-dasharray="109.95"/>
          <circle id="jatoLight" style="transform-origin: 50% 50%; transform: rotate(-90deg)" cx="17.5" cy="17.5" r="17.5" fill="transparent" stroke="#0072bc" stroke-width="4px" stroke-dasharray="109.95"/>
        </g>
      </defs>
    </svg>`,

    replace: true,
    link:
    function (scope, element, attrs) {
      var streamsList = ['engineInfo', 'electrics', 'escInfo', 'powertrainDeviceData', 'n2oInfo'];
      StreamsManager.add(streamsList);

      var svg = element[0];
      var svgIcons = [];
      var svgIgnition = [];
      var svgText = [];
      var svgCreated = 0;
      var components = [];
      var text = null;
      var current;
      var started = false;
      var engineStateHelper; // could actually hav the same meaning as started, but hadn't had time to check;

      var modeMap = {
        disconnected: '#disconnected',
        connected: '#connected',
        low: '#low',
        high: '#highRangeBoxIcon',
        locked: '#lockedIcon',
        open: '#openIcon',
        lsd: '#lsdIcon'
      };

      var colour = {
        0: "#000000",
        1: "#FF6600"
      }

      function reset() {
        for (var key in svgIcons) {
          svgIcons[key].remove();  // removing all icon svgs from array
        }

        for (var key in svgIgnition) {
          svgIgnition[key].remove();  // removing all icon svgs from array
        }

        for (var key in svgText) {
          svgText[key].remove();  // removing all icon svgs from array
        }

        if (text !== null) {
          text.attr({   // fixes text from staying when vehicles are changed.
            opacity: 0,
          })
        }

        svgText = [];
        svgIgnition = [];
        svgIcons = [];
        components = [];
        svgCreated = 0;
      }

      function positionIcons(s) {
        var width = 200,
          height = 200,
          angle = 340,
          step = (2 * Math.PI) / 10;
        radius = 65;
        for (i = 0; i < s.length; i++) {
          s[i].attr({
            x: 107 + Math.round(width / 2 + radius * Math.cos(angle) - 200 / 2),
            y: 80 + Math.round(width / 2 + radius * Math.sin(angle) - 200 / 2),
          });
          angle += step
        }
      }

      function createSVG(data) {
        if (data.powertrainDeviceData != null) {
          if (data.powertrainDeviceData.devices["mainEngine"] != null) {
            var ignitionLight = hu('<circle>', svg).attr({
              cx: 120,
              cy: 90,
              r: 30,
              fill: "#FF6600",
            })

            var ignition = hu('<use>', svg).attr({
              x: 73,
              y: 49,
              'xlink:href': "#ignition",
              cursor: 'pointer',
            })

            svgIgnition.push(ignitionLight);
            svgIgnition.push(ignition);

            svgIgnition[1].on('mousedown', function () {
              if (engineStateHelper === 1) {
                bngApi.activeObjectLua('controller.mainController.setEngineIgnition(false)');
              }
              else if (engineStateHelper === 0) {
                bngApi.activeObjectLua('controller.mainController.setStarter(true)');
              }
            });
          }

          for (var key in data.powertrainDeviceData.devices) {
            if (data.powertrainDeviceData.devices[key].currentMode != null) {
              components.push(key);
            }
          }

          components.sort();

          for (var key in components) {
            if (data.powertrainDeviceData.devices[components[key]].currentMode != null) {
              svgIcons.push(hu('<use>', svg).attr({
                id: components[key],
                'xlink:href': modeMap[data.powertrainDeviceData.devices[components[key]].currentMode],
                cursor: 'pointer',
                "background-color": "#FFFFFF"
              }))
            }
          }

          // ESC Icon
          if (data.escInfo) {
            svgIcons.push(hu('<use>', svg).attr({

              'xlink:href': '#escGrp',
              cursor: 'pointer',
            }).on('mousedown', function () {
              bngApi.activeObjectLua("local esc = controller.getController('esc') if esc then esc.toggleESCMode() end");
            }))
          }

          // N2O Icon
          if (data.n2oInfo) {
            svgIcons.push(hu('<use>', svg).attr({
              id: 'N2O',
              'xlink:href': '#n2oGrp',
              cursor: 'pointer',
            }).on('mousedown', function () {
              bngApi.activeObjectLua("controller.getController('nitrousOxideInjection').toggleActive()");
            }))
          }

          // jato Icon
          if (data.electrics.jato !== undefined) {
            svgIcons.push(hu('<use>', svg).attr({
              id: 'Jato',
              'xlink:href': '#jatoGrp'
            }))
          }

          text = hu('<text>', svg).attr({
            opacity: 0,
          }).css({
            fill: "#FFFFFF",
            "text-align": "left",
            "font-weight": "bold",
            "font-size": 15,
            "text-shadow": "1px 2px black", // allows text to be easy to read
          }).on('mouseover', function () {
            text.attr({
              opacity: 0,
            }).text(
              ""
              )
          })

          svgIcons.forEach(function (el, i) {
            el.on('mousedown', function () {
              bngApi.activeObjectLua('powertrain.toggleDeviceMode("' + components[i] + '")');
            }).on('mouseover', function () {
              text.attr({
                x: svgIcons[i].attr('x'),
                y: svgIcons[i].attr('y'),
                opacity: 1,
              }).text(
                svgIcons[i].n.id
                )
            }).on('mouseleave', function () {
              text.attr({
                opacity: 0,
              }).text(
                ""
                )
            })
          })

          positionIcons(svgIcons);    // function used to position icons around starter
          svgCreated = 1;
        }
      }



      scope.$on('streamsUpdate', function (event, data) {
        if (svgCreated === 0) {
          createSVG(data);
        }

        // updating esc light
        if (data.escInfo) {
          hu('#escLight', svg).attr({ fill: "#" + data.escInfo.ledColor });
        }

        // updating n2o light
        if (data.n2oInfo) {
          hu('#n2oLight', svg).attr({ stroke: "#" + (data.n2oInfo.isArmed ? '98FB00' : 'FFFFFF') });
          if (data.n2oInfo.isActive) {
            hu('#n2oLight', svg).attr({ stroke: '#3096F1' });
          }
          hu('#n2oLight', svg).attr({ 'stroke-dashoffset': ((1 - data.n2oInfo.tankRatio) * - 84.78) });
        }

        // updating jato light
        if (data.electrics.jato !== undefined) {
          hu('#jatoLight', svg).attr({ stroke: "#" + (data.electrics.jato === 1 ? '0072bc' : '0072bc') });
          hu('#jatoLight', svg).attr({ 'stroke-dashoffset': ((1 - data.electrics.jatofuel) * - 84.78) });
        }

        if (data.powertrainDeviceData) {
          for (i = 0; i < svgIcons.length; i++) {   // updating icons to represent their current state
            if (components[i] === "wheelaxleFL" || components[i] === "wheelaxleFR") {  // used to assign correct wheel axle icons instead of regular drive shafts
              svgIcons[i].attr({ 'xlink:href': '#wheel' + data.powertrainDeviceData.devices[components[i]].currentMode });
            }
            else if (data.powertrainDeviceData.devices[components[i]]) {
              svgIcons[i].attr({ 'xlink:href': modeMap[data.powertrainDeviceData.devices[components[i]].currentMode] });
            }
          }
        }

        // updating ignition light
        if (data.engineInfo) {
          engineStateHelper = data.engineInfo[17];
          if (svgIgnition[1]) {
            svgIgnition[0].attr({ fill: colour[data.engineInfo[17]] })
          }
        }

      });

      scope.$on('VehicleChange', function () {
        reset();
      });

      scope.$on('VehicleFocusChanged', function () {
        reset();
      });

      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });
    }
  };
}])
