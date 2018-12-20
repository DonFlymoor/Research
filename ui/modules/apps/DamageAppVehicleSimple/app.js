(function () {
  'use strict';
  angular.module('beamng.apps')
  .directive('damageApp', ['bngApi', 'StreamsManager', '$sce', '$timeout', function (bngApi, StreamsManager, $sce, $timeout) {
    return {
      template:
      `
        <div>
          <div style="width: 100%; height: 100%" ng-include="'modules/apps/DamageAppVehicleSimple/damage_car.svg'" onload="svgLoaded()"></div>
        </div>
      `,
      replace: true,
      link: function ($scope, element, attrs) {
        // Streams:
        var streamsList = ['wheelThermalData', 'engineInfo'];
        StreamsManager.add(streamsList);

        var greenColor  = `rgba(0,   255, 0, 0.6)`,
            orangeColor = `rgba(255, 132, 0, 0.6)`,
            redColor    = `rgba(255, 0,   0, 0.6)`,
            noDataColor = 'rgba(0,   0,   0, 0  )',
            damageQueue = [],     // Array used to store each instance of damage so that damage text can be cycled through
            hasDamage = 0, // Value to check if damage has occured
            textDisplayTime = 2000,// Amount of time damage text is shon in milliseconds
            beams = {},
            appDisplayed = 0,
            animTimeout,
            damageTimeout,
            textFunction,
            permanentDamage = 0;

        // Method only called once the SVG has completed loaded
        $scope.svgLoaded = function () {
          var svg = element[0].children[0].children[0],
              svgCarGroup = hu('#carGroup', svg),
              svgDamageTextContainer = hu('#dmgContainer', svg),
              svgDamageText = hu('#dmgText', svg);

          // Map for powertrain components
          // Since we re-use the same SVG for multiple damage types, the priority value is used so
          // that more important damage can be shown as red else the damage will be shown as orange
          var componentDamageMap =  {
            body : {
              FL:                   { svgId: '#bodyFL',       priority: 2, damageDisplayed: 0      },
              FR:                   { svgId: '#bodyFR',       priority: 2, damageDisplayed: 0      },
              ML:                   { svgId: '#bodyML',       priority: 2, damageDisplayed: 0      },
              MR:                   { svgId: '#bodyMR',       priority: 2, damageDisplayed: 0      },
              RL:                   { svgId: '#bodyRL',       priority: 2, damageDisplayed: 0      },
              RR:                   { svgId: '#bodyRR',       priority: 2, damageDisplayed: 0      }
            },

            engine: {
              coolantHot:           { svgId: '#engine',       priority: 0, damageDisplayed: 0, damageText: 'Coolant Overheating'                      },
              oilStarvation:        { svgId: '#engine',       priority: 0, damageDisplayed: 0, damageText: 'Oil Starvation'                           },
              oilHot:               { svgId: '#engine',       priority: 0, damageDisplayed: 0, damageText: 'Oil Overheating'                          },
              pistonRingsDamaged:   { svgId: '#engine',       priority: 0, damageDisplayed: 0, damageText: 'Piston Rings Damaged'                     },
              rodBearingsDamaged:   { svgId: '#engine',       priority: 0, damageDisplayed: 0, damageText: 'Rod Bearings Damaged'                     },
              headGasketDamaged:    { svgId: '#engine',       priority: 0, damageDisplayed: 0, damageText: 'Head Gasket Damaged'                      },
              turbochargerHot:      { svgId: '#engine',       priority: 0, damageDisplayed: 0, damageText: 'Turbocharger Overheating'                 },
              engineIsHydrolocking: { svgId: '#engine',       priority: 0, damageDisplayed: 0, damageText: 'Engine is Hydrolocking'                   },
              engineReducedTorque:  { svgId: '#engine',       priority: 0, damageDisplayed: 0, damageText: 'Engine Torque Reduced'                    },
              mildOverrevDamage:    { svgId: '#engine',       priority: 0, damageDisplayed: 0, damageText: 'Mild Over Rev Damage'                     },
              overRevDanger:        { svgId: '#engine',       priority: 0, damageDisplayed: 0, damageText: 'Over Rev Risk',                           },
              overTorqueDanger:     { svgId: '#engine',       priority: 0, damageDisplayed: 0, damageText: 'Over Torque Risk'                         },
              engineHydrolocked:    { svgId: '#engine',       priority: 1, damageDisplayed: 0, damageText: 'Engine is Hydrolocked'                    },
              engineDisabled:       { svgId: '#engine',       priority: 1, damageDisplayed: 0, damageText: 'Engine Disabled'                          },
              blockMelted:          { svgId: '#engine',       priority: 1, damageDisplayed: 0, damageText: 'Block Melted'                             },
              engineLockedUp:       { svgId: '#engine',       priority: 1, damageDisplayed: 0, damageText: 'Engine Locked Up'                         },
              radiatorLeak:         { svgId: '#radiator',     priority: 1, damageDisplayed: 0, damageText: 'Radiator Leaking'                         }
            },
            powertrain: {
              wheelaxleFL:          { svgId: '#wheelaxleFL',  priority: 1, damageDisplayed: 0, damageText: 'Front Left Axle Broken'                   },
              wheelaxleFR:          { svgId: '#wheelaxleFR',  priority: 1, damageDisplayed: 0, damageText: 'Front Right Axle Broken'                  },
              wheelaxleRL:          { svgId: '#wheelaxleRL',  priority: 1, damageDisplayed: 0, damageText: 'Rear Left Axle Broken'                    },
              wheelaxleRR:          { svgId: '#wheelaxleRR',  priority: 1, damageDisplayed: 0, damageText: 'Rear Right Axle Broken'                   },
              driveshaft:           { svgId: '#driveshaft' ,  priority: 1, damageDisplayed: 0, damageText: 'Driveshaft Broken'                        },
              driveshaft_F:         { svgId: '#driveshaft' ,  priority: 1, damageDisplayed: 0, damageText: 'Front Driveshaft Broken'                  },
              mainEngine:           { svgId: '#engine'     ,  priority: 1, damageDisplayed: 0, damageText: 'Engine Broken'                            }
            },
            energyStorage: {
              mainTank:             { svgId: '#fueltank',     priority: 1, damageDisplayed: 0, damageText: 'Fuel Tank Damaged'                        }
            },
            wheels: {
              tireFR:               { svgId: '#tireFR',       priority: 0, damageDisplayed: 0, damageText: 'Front Right Tire Burst'                   },
              tireFL:               { svgId: '#tireFL',       priority: 0, damageDisplayed: 0, damageText: 'Front Left Tire Burst'                    },
              tireRL:               { svgId: '#tireRL',       priority: 0, damageDisplayed: 0, damageText: 'Rear Left Tire Burst'                     },
              tireRR:               { svgId: '#tireRR',       priority: 0, damageDisplayed: 0, damageText: 'Rear Right Tire Burst'                    },

              brakeFL:              { svgId: '#brakeFL',      priority: 1, damageDisplayed: 0, damageText: 'FL Brake Damaged'                         },
              brakeFR:              { svgId: '#brakeFR',      priority: 1, damageDisplayed: 0, damageText: 'FR Brake Damaged'                         },
              brakeRL:              { svgId: '#brakeRL',      priority: 1, damageDisplayed: 0, damageText: 'RL Brake Damaged'                         },
              brakeRR:              { svgId: '#brakeRR',      priority: 1, damageDisplayed: 0, damageText: 'RR Brake Damaged'                         },

              brakeOverHeatFL:      { svgId: '#brakeFL',      priority: 0, damageDisplayed: 0, damageText: 'FL Brake Fading',  tempDamage: 1     },
              brakeOverHeatFR:      { svgId: '#brakeFR',      priority: 0, damageDisplayed: 0, damageText: 'FR Brake Fading',  tempDamage: 1     },
              brakeOverHeatRL:      { svgId: '#brakeRL',      priority: 0, damageDisplayed: 0, damageText: 'RL Brake Fading',  tempDamage: 1     },
              brakeOverHeatRR:      { svgId: '#brakeRR',      priority: 0, damageDisplayed: 0, damageText: 'RR Brake Fading',  tempDamage: 1     },

              FL:                   { svgId: '#tireFL',       priority: 1, damageDisplayed: 0, damageText: 'Front Left Tire Broken'                   },
              FR:                   { svgId: '#tireFR',       priority: 1, damageDisplayed: 0, damageText: 'Front Right Tire Broken'                  },
              RL:                   { svgId: '#tireRL',       priority: 1, damageDisplayed: 0, damageText: 'Rear Left Tire Broken'                    },
              RR:                   { svgId: '#tireRR',       priority: 1, damageDisplayed: 0, damageText: 'Rear Right Tire Broken'                   }
            }
          }

          function showText() {
            if (damageQueue && damageQueue.length > 0) {
              svgDamageText.css({opacity:1}).text(damageQueue[0].damageText);
              svgDamageTextContainer.css({opacity:1});
              damageQueue.splice(0, 1);  // removing current item from array
              animTimeout = $timeout(showText, textDisplayTime);
            }
            else {
              svgDamageText.css({opacity:0}).text('');
              svgDamageTextContainer.css({opacity:0});

              if (permanentDamage === 0) {
                damageTimeout = $timeout(function() {
                  svgCarGroup.animate({opacity: 0}, 200);
                }, 1000);
              }

              appDisplayed = 0;
              damageQueue = [];
              $timeout.cancel(animTimeout);
            }
          };

          function showApp(arr) {
            svgCarGroup.animate({opacity: 1,},200);
            showText();
          };

          function reset() {
            for (var key in componentDamageMap) {
              for (var val in componentDamageMap[key]) {
                hu(componentDamageMap[key][val].svgId, svg).css({
                  fill: noDataColor
                });
                componentDamageMap[key][val].damageDisplayed = 0;
                hu(componentDamageMap[key][val].svgId, svg).n.classList.remove("flashAnim");
              }
            }
            // svgCarGroup.attr({opacity: 1});
            hasDamage = 0;
            permanentDamage = 0;
            appDisplayed = 0;
            damageQueue = [];
            showApp();
          };

          function setDamage(component, color, anim) {
            hu(component.svgId, svg).css({
              fill: color
            }).attr({
              class: anim
            }).on('webkitAnimationEnd', function (){
              hu(component.svgId, svg).n.classList.remove("flashAnim");
            });
          };

          function checkDamage(type, component, data) {
            if (componentDamageMap[type] && componentDamageMap[type][component] !== undefined) {
              var damagedComponent = componentDamageMap[type][component];
              if (damagedComponent.damageDisplayed === 0) {
                if (data[type][component] === true || data[type][component] > 0) {
                  if (damagedComponent.priority === 1) {
                    permanentDamage = 1;
                    setDamage(damagedComponent, redColor, 'flashAnim')
                  } else if (damagedComponent.priority === 0) {
                    permanentDamage = 1;
                    setDamage(damagedComponent, orangeColor, 'flashAnim');
                  } else if (damagedComponent.priority === 2 ) {
                    var damageAmount = Math.round(data[type][component] * 1000);
                    var bodyColor = `rgba(${150+damageAmount}, ${150-damageAmount}, 0, 0.6)`
                    setDamage(damagedComponent, bodyColor, '');
                  }
                  hasDamage = 1;
                  if (damagedComponent.damageText !== undefined && damagedComponent.damageDisplayed === 0) {
                    damageQueue.push(damagedComponent); // Adding damaged components to a queue so their damage text can be displayed over a certain period of time
                    damagedComponent.damageDisplayed = 1;
                  }
                }
              } else if (damagedComponent.tempDamage) {
                if (data[type][component] === true || data[type][component] > 0) {
                  setDamage(damagedComponent, orangeColor, 'flashAnim');
                }
                else if (data[type][component] === false || data[type][component] === 0) {
                  setDamage(damagedComponent, noDataColor, 'flashAnim');
                }
              }
            }
          };

          $scope.$on('DamageData', (ev, data) => {
            for (var key in data) {
              for (var val in data[key]) {
                checkDamage(key, val, data);
              }
            }
            if (appDisplayed === 0 && hasDamage) {
              appDisplayed = 1;
              showApp(damageQueue);
            }
          });

          $scope.$on('DamageMessage', (ev, data) => {
            damageQueue.push(data);
            showApp();
          });

          $scope.$on('VehicleReset', function() {
            reset();
          });

          $scope.$on('VehicleChange', function() {
            reset();
          });

          // request skeleton on TAB
          $scope.$on('VehicleFocusChanged', function(evt, data) {
            if (data.mode === true) {
              reset();
            }
          });

          $scope.$on('$destroy', function () {
            StreamsManager.remove(streamsList);
          });
        }
      }
    };
  }]);
})();
