angular.module('beamng.apps')
  .directive('simpleBrakeThermals', ['bngApi', 'StreamsManager', 'UiUnits', function (bngApi, StreamsManager, UiUnits) {
    return {
      template:
      `<svg viewBox="0 0 120 500" style="height: auto; margin:0; padding:0; pointer-event:none;">
        <defs>
          <image id="drum" width="60" height="60" xlink:href="modules/apps/SimpleBrakeThermals/drum.svg" />
          <image id="disc" width="60" height="60" xlink:href="modules/apps/SimpleBrakeThermals/disc.svg" />
          <image id="vented-disc" width="60" height="60" xlink:href="modules/apps/SimpleBrakeThermals/vented-disc.svg" />
          <image id="semi-race" width="60" height="60" xlink:href="modules/apps/SimpleBrakeThermals/semi-race.svg" />
          <image id="fullrace" width="60" height="60" xlink:href="modules/apps/SimpleBrakeThermals/full-race.svg" />
          <image id="sport" width="60" height="60" xlink:href="modules/apps/SimpleBrakeThermals/sport.svg" />
          <image id="basic" width="60" height="60" xlink:href="modules/apps/SimpleBrakeThermals/basic.svg" />
          <image id="premium" width="60" height="60" xlink:href="modules/apps/SimpleBrakeThermals/premium.svg" />
        </defs>
      </svg>`,
      replace: true,
      link:
      function (scope, element, attrs) {
        var streamsList = ['wheelThermalData', 'wheelInfo'];  // loading required streams
        StreamsManager.add(streamsList);  // adding streams    
        var svg = element[0];
        var svgBrakes = []; // contains all svg items for brake discs
        var svgText = []; // contains text svgs
        var svgBrakeType = [];  //contains svgs for different brake types
        var svgPadType = [];  //contains svgs for different pad types
        var brakes = [];
        var svgCreated = 0;
        var brakesGenerated = 0;

        var discMap = {
          drum: "#drum",
          disc: "#disc",
          'vented-disc': "#vented-disc"
        };

        var padMap = {
          'semi-race': '#semi-race',
          'full-race': '#fullrace',
          sport: '#sport',
          basic: "#basic",
          premium: "#premium"
        };

        function resetSVG() {
          for (var key in svgBrakes) {
            svgBrakes[key].remove();  // removing all brake svgs from array
          }

          for (var key in svgText) {
            svgText[key].remove();  // removing all text svgs from array
          }

          for (var key in svgBrakeType) {
            svgBrakeType[key].remove();  // removing all text svgs from array
          }

          for (var key in svgPadType) {
            svgPadType[key].remove();  // removing all text svgs from array
          }

          svgBrakeType = [];
          svgBrakes = []; // resetting arrays
          svgPadType = [];
          svgText = [];
          brakes = [];
          brakesGenerated = 0;
          svgCreated = 0;
        }

        function createSVG(i) { // function to initialise SVGs

          var brakeGroup = hu('<svg>', svg).attr({ 'z-index': "999" }); // group used to hold brake disk and calipers

          disc = hu('<circle>', brakeGroup).attr({
            cx: 30,
            cy: 30,
            r: 18,
            fill: "transparent",
            opacity: "1;",
            strokeWidth: 13,
          });

          svgPadType.push(hu('<use>', svg));

          type = hu('<use>', svg).attr({
            x: 2,
            y: 0,
          });

          var text = hu('<text>', svg).attr({  //text svg used for brake temps
            "text-align": "middle"
          }).css({
            fill: 'white',
            "text-align": "left",
            "font-weight": "bold",
            "font-size": 15,
            "text-shadow": "1px 2px black", // allows text to be easy to read
          });

          svgBrakes.push(brakeGroup);
          svgText.push(text);
          svgBrakeType.push(type);
          svgCreated = 1;
        }

        function generateBrakes(data) {
          brakes = [];
          for (i in data.wheelThermalData.wheels) {
            brakes.push(i);
          }

          brakes.sort();  // sorting array so that wheels go FL, FR, RL, RR etc.

          for (i = 0; i < svgBrakes.length; i++) {  // arrays used to generate a grid (2x(number of axles))

            svgPadType[i].attr({ x: 60 * ((i % 2) + 0.037), y: 70 * Math.floor((i / 2)), });
            svgBrakes[i].attr({ x: 60 * (i % 2), y: 70 * Math.floor((i / 2)), }); //i%2 ensures columns are only 2 wide
            svgText[i].attr({ x: 60 * ((i % 2) + 0.3), y: 70 * (Math.floor(((i) / 2)) + 1) });
            svgBrakeType[i].attr({ x: 60 * ((i % 2) + 0.037), y: 70 * Math.floor((i / 2)), });

            if (data.wheelThermalData.wheels[brakes[i]] != null) {
              svgBrakeType[i].attr({ 'xlink:href': discMap[data.wheelThermalData.wheels[brakes[i]].brakeType] });
              if (data.wheelThermalData.wheels[brakes[i]].brakeType != "drum") {
                svgPadType[i].attr({ 'xlink:href': padMap[data.wheelThermalData.wheels[brakes[i]].padMaterial] });
              }
            }
            else {
              return;
            }
          }
          brakesGenerated = 1;
        }

        scope.$on('streamsUpdate', function (event, data) {
          if (data.wheelThermalData != null) {

            if (svgCreated === 0) { // checks if svgs have been made in order to prevent more elements than necessary being stored in the arrays
              for (i in data.wheelInfo) {
                createSVG(i);
              }
              brakesGenerated = 0;
            }
          }
          else {
            return;
          }

          if (brakesGenerated === 0) {  //only generates brakes once in order to save resources
            generateBrakes(data);
          }

          for (i = 0; i < brakes.length; i++) { //changes the colour of the disks and text according to their values
            if (data.wheelThermalData.wheels[brakes[i]] != null) {
              var wheel = data.wheelThermalData.wheels[brakes[i]]
                , colorSwitch = wheel.slopeSwitchBit
                , eff = Math.min(Math.max((wheel.finalBrakeEfficiency - 0.5) * 2, 0), 1)
                , efficiency = eff * eff
                , red = Math.round((1 - efficiency) * (1 - colorSwitch) * 255)
                , green = Math.round(efficiency * 255)
                , blue = Math.round((1 - efficiency) * colorSwitch * 255)
              svgBrakes[i].attr({ stroke: "rgba(" + red + ", " + green + ", " + blue + ", 0.7)" })
              svgText[i].text(Math.floor(UiUnits.temperature(data.wheelThermalData.wheels[brakes[i]].brakeSurfaceTemperature).val)
                + UiUnits.temperature(data.wheelThermalData.wheels[brakes[i]].brakeSurfaceTemperature).unit);
            }
            else {
              return;
            }
          }
        });

        scope.$on('VehicleChange', function () {
          resetSVG(); //resets everything so that elements can be redrawn
        });

        scope.$on('VehicleReset', function () {
          resetSVG(); //resets everything so that elements can be redrawn
        });

        scope.$on('VehicleFocusChanged', function () {
          resetSVG(); //resets everything so that elements can be redrawn
        });

        scope.$on('$destroy', function () {     //removing streams
          StreamsManager.remove(streamsList);
        });
      }
    };
  }])
