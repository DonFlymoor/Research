angular.module('beamng.apps')
  .directive('engineDamageApp', ['bngApi', 'StreamsManager', function (bngApi, StreamsManager) {
    return {
      template:
      `
        <div class="bngApp" style="width:100%; height:100%; padding: 10px; background-color: transparent;">
          <object style="width:100%; pointer-events: none;" type="image/svg+xml" data="modules/apps/DamageAppEngine/damage_engine.svg"/>
        </div>
      `,
      replace: true,
      link: function ($scope, element, attrs) {
        // actuall logic:
        // colors:
        var opacity = 0.6
          , greenColor = `rgba(0, 255, 0, ${opacity})`
          , orangeColor = `rgba(255, 132, 0, ${opacity})`
          , redColor = `rgba(255, 0, 0, ${opacity})`
          , noDataColor = 'transparent'
          // elements / systems to color:
          , elements
          ;

        var damageMap = {
          coolantHot:           {svgId: '#coolantTemp',  priority: 1},
          oilStarvation:        {svgId: '#oilStarv',     priority: 1},
          oilHot:               {svgId: '#oilStarv',     priority: 1},
          pistonRingsDamaged:   {svgId: '#pistonRings',  priority: 1},
          rodBearingsDamaged:   {svgId: '#rodBearings',  priority: 1},
          headGasketDamaged:    {svgId: '#headGasket',   priority: 1},
          turbochargerHot:      {svgId: '#turbocharger', priority: 0},

          engineIsHydrolocking: {svgId: '#engine',       priority: 0},
          engineReducedTorque:  {svgId: '#engine',       priority: 0},
          mildOverrevDamage:    {svgId: '#engine',       priority: 0},
          mildOverTorqueDamage: {svgId: '#engine',       priority: 0},

          engineHydrolocked:    {svgId: '#engine',       priority: 1},
          engineDisabled:       {svgId: '#engine',       priority: 1},
          blockMelted:          {svgId: '#engine',       priority: 1},
          engineLockedUp:       {svgId: '#engine',       priority: 1}
        }

        element[0].children[0].onload = function () {
          var svg = element[0].children[0].contentDocument;

          $scope.$on('DamageData', (ev, data) => {

            // checking if component is not damaged, this is done here and not as an else
            // for the loop below as that will overwrite existing damage colour since
            // we are using the same svg paths for multiple damage types.
            for (var key in damageMap) {
              if (data['engine'] && data['engine'][key] === false) {
                hu(damageMap[key].svgId, svg).css({ fill: greenColor});
              }
            }

            // checking for component damage
            for (var key in damageMap) {
              if (data['engine'] && data['engine'][key] === true) {
                if (damageMap[key].priority === 1) {
                  hu(damageMap[key].svgId, svg).css({ fill: redColor});
                }
                else if (damageMap[key].priority === 0) {
                  hu(damageMap[key].svgId, svg).css({ fill: orangeColor});
                }
              }
            }
          });

          $scope.$on('VehicleChange', reset);

          // request skeleton on TAB
          $scope.$on('VehicleFocusChanged', function() {
            reset();
          });

          //on vehicle reset
          $scope.$on('VehicleReset', reset);

          // reset svgs:
          function reset() {
            for (var key in damageMap) {
              hu(damageMap[key].svgId, svg).css({ fill: noDataColor });
            }
          }

        }

      }
    };
  }]);
