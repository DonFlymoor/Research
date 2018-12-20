angular.module('beamng.apps')
  .directive('navigation', ['bngApi', 'StreamsManager', 'Utils', function (bngApi, StreamsManager, Utils) {
    return {
      template: `
      <div style="height: 100%; width: 100%; position: relative;">
        <!-- map container -->

        <div id="overflow-wrap" style=" width: 100%; height: 100%; overflow: hidden">
          <div id="mapContainer" style="overflow: visible;">
            <svg style="overflow: visible">
              <defs>
                <image style="" id="vehicleMarker" width="40" height="40"  x="-20" y="-20" xlink:href="modules/apps/Navigation/vehicleMarker.svg" />
              </defs>
            </svg>
          </div>
          <div style="position: absolute">
            <svg width="40" height="40" style="position: fixed; top:0; left: 50%; margin-top: -20px; margin-left: -20px; transform: scale(1, 1);">
              <!--<path d="M20.272 3.228l-5.733 10.52-3.878 6.51c-1.22 1.87-1.873 4.056-1.877 6.29 0 6.38 5.17 11.55 11.55 11.55 6.38 0 11.55-5.17 11.55-11.55-.002-2.257-.666-4.466-1.91-6.35l-3.92-6.505z" fill="#282828" fill-rule="evenodd" stroke="#fff" stroke-width="2.88"/>-->
              <circle cx="20" cy="20" r="10" stroke="#FFF" stroke-width="1.5" fill="#282828" />
              <text style="line-height:125%" x="14.265" y="1043.581" font-size="14" font-family="sans-serif" letter-spacing="0" word-spacing="0" fill="#fff" transform="translate(1 -1012.362)"><tspan x="14" y="1037">N</tspan></text>
            </svg>
          </div>
        </div>

        <!-- Collectible Display -->
        <div ng-if="collectableTotal > 0" style="font-size: 1.2em; padding: 1%; color: white; background-color: rgba(0, 0, 0, 0.3); position: absolute; top:15px; left: 15px">
          <md-icon style="margin-bottom: 3px;" md-svg-src="{{ 'modules/apps/Navigation/snowman.svg' }}" />
          {{ collectableCurrent + '/' + collectableTotal }}
        </div>

        <style>
          .bounce {
            animation: bounce 1s cubic-bezier(0.4,0.1,0.2,1) both;
          }
          @keyframes bounce {
            0%, 20%, 50%, 80%, 100% { transform: translateY(0); }
            40% { transform: translateY(-4px); }
            60% { transform: translateY(-2px); }
          }
        </style>

      </div>
      `,
      replace: true,
      restrict: 'EA',
      link: function (scope, element, attrs) {

        var root = element[0];
        var mapcontainer = root.children[0].children[0];
        var svg = mapcontainer.children[0];
        var pointer = mapcontainer.children[1];
        var northPointer = root.children[0].children[1].children[0];

        var mapReady = false;
        var rotateMap = true;
        var viewParams = [];

        var mapZoom = 0;
        var mapScale = 1
        var zoomStates = [0, -1000, -2000]
        var zoomSlot = 0;
        var t = 0;
        // receive live data from the GE map
        var vehicleShapes = {};
        var lastcontrolID = -1;

        var collectableShapes = {};
        // group to store all collectable svgs
        var collGroup;

        var visibilitySlots = [0.2, 0.6, 0.8, 1]
        var activeVisibilitySlot = 1;

        // ability to interact
        element[0].addEventListener('click', function (e) {
          activeVisibilitySlot++;
          if (activeVisibilitySlot >= visibilitySlots.length) activeVisibilitySlot = 0;
          element.css({
            'background-color': 'rgba(50, 50, 50, ' + visibilitySlots[activeVisibilitySlot] + ')',
          })
        });

        element[0].addEventListener('contextmenu', function(e) {
          zoomSlot++;
          mapZoom = zoomSlot < zoomStates.length   ? zoomStates[zoomSlot] : zoomSlot = 0;
        });

        scope.$on('NavigationMapUpdate', function (event, data) {
          if (!mapReady || !data) return;
          updateNavMap(data);

          // center map on thing that is controlled
          centerMap(data.objects[data.controlID]);
        });

        scope.$on('app:resized', function (event, streams) {
          element.css({
            'width': streams.width-25 + "px",
            'height': streams.height-25 + "px",
          })
          setupMap();
        });

        scope.$on('$destroy', function () {
          bngApi.engineLua('extensions.unload("ui_uiNavi")');
          //StreamsManager.remove(requiredStreams);
        });

        // receive the one-time map setup
        scope.$on('NavigationMap', function (event, data) {
          if (data) setupMap(data);
          //console.log(data);
        });

        scope.$on('CollectablesInit', (event, data) => {
          if (data) setupCollectables(data);
        });

        scope.$on('CollectablesUpdate', (event, data) => {
          if (data) {
            // remove collectable from svg
            collectableShapes[data.collectableName].remove();
            // play animation
            var collectIcon = root.children[1].children[0];
            collectIcon.classList.add('bounce')
            collectIcon.addEventListener("animationend", function () {  // resetting the animation
              collectIcon.classList.remove('bounce');
            });
            // update collected amount
            scope.collectableCurrent = data.collectableAmount;
          };
        });

        function _createCircle(x, y, r, c, s, sw) {
          hu('<circle>', svg).attr({
            cx: x, cy: y, r: 0.5 * r, fill: c, stroke: s, 'stroke-width': sw
          });
        }

        function _createLine(p1, p2, color) {
           hu('<line>', svg).attr({
            x1: p1.x, y1: p1.y, x2: p2.x, y2: p2.y,
            stroke: color,
            strokeWidth: Math.max(p1.radius, p2.radius),
            strokeLinecap: "round",
          });
        }

        function centerMap(obj) {
          var zoom = Math.min(50 + (obj.speed * 3.6) * 1.5, 150);

          // center on what?
          var focusX = -obj.pos[0] / mapScale;
          var focusY = obj.pos[1] / mapScale;

          var borderWidth = root.children[0].clientWidth;
          var borderHeight = root.children[0].clientHeight;
          var degreeNorth = rotateMap ? (obj.rot - 90) : 90;
          var npx = - Math.cos(degreeNorth * Math.PI / 180) * borderWidth * 0.75;
          var npy = borderHeight * 0.5 - Math.sin(degreeNorth * Math.PI / 180) * borderHeight * 0.75;
          var translateX = (((viewParams[0]) + borderWidth/2 - 10) + focusX+10);
          var translateY = (((viewParams[1]) + borderHeight/1.5) + focusY);

          mapcontainer.style.transformOrigin = (((viewParams[0] * -1)) - focusX) + "px " + ((viewParams[1] * -1) - focusY) + "px"
          mapcontainer.style.transform = "translate3d(" + translateX + "px, " + translateY + "px," + mapZoom + "px)" + "rotateX(" + 40 + (zoom / 10) + "deg)" + "rotateZ(" + (180 + Utils.roundDec(obj.rot, 2)) + "deg)"

          northPointer.style.transform = 'translate(' + Math.min(Math.max(npx, -borderWidth / 2 - 2), borderWidth / 2) + 'px,' + Math.min(Math.max(npy, 0), borderHeight) + 'px)';
        }

        // no cheating :D
        function hideCollectables(camera) {
          if (camera) {
            collGroup.attr({opacity: 0});
          }
          else {
            collGroup.attr({opacity: 1});
          }
        }

        function updatePlayerShape(key, data) {
          //console.log('updatePlayerShape', key)
          if (vehicleShapes[key]) vehicleShapes[key].remove();
          var isControlled = (key == data.controlID)

          //console.log(data)
          var obj = data.objects[key];
          if (isControlled) {
            if (obj.type == 'Camera') {
              hideCollectables(true)
              vehicleShapes[key] = hu('<circle>', svg)
              vehicleShapes[key].attr('cx', 0)
              vehicleShapes[key].attr('cy', 0)
              vehicleShapes[key].attr('r', 8)
              vehicleShapes[key].css('fill', '#FD6A00');
            }
            else {
              hideCollectables(false)
              vehicleShapes[key] = hu('<use>', svg);
              vehicleShapes[key].attr({ 'xlink:href': '#vehicleMarker' });
            }
          }
          else {
            vehicleShapes[key] = hu('<circle>', svg)
            vehicleShapes[key].attr('cx', 0)
            vehicleShapes[key].attr('cy', 0)
            vehicleShapes[key].attr('r', 10)
            vehicleShapes[key].css('stroke', '#FFFFFF');
            vehicleShapes[key].css('stroke-width', '3px');
            vehicleShapes[key].css('fill', '#A3D39C');
          }
        }

        function updateNavMap(data) {
          // player changed? update shapes?
          if (lastcontrolID != data.controlID) {
            if (lastcontrolID != -1) updatePlayerShape(lastcontrolID, data); // update shape of old vehicle
            updatePlayerShape(data.controlID, data); // update shape of new vehicle
            lastcontrolID = data.controlID;
          }

          // update shape positions
          for (var key in data.objects) {
            var o = data.objects[key];

            if (vehicleShapes[key]) {
              var px = -o.pos[0] / mapScale;
              var py = o.pos[1] / mapScale;
              var rot = Math.floor(-o.rot);
              var iconScale = 1; //Math.min(3, 1 + lastSpeed * 0.5);
              vehicleShapes[key].attr("transform", "translate(" + px + "," + py + ") scale(" + iconScale + "," + iconScale + ") rotate(" + rot + ")");
            }
            else {
              updatePlayerShape(key, data);
            }
          }
          // delete missing vehicles
          for (var key in vehicleShapes) {
            if (!data.objects[key]) {
              vehicleShapes[key].remove();
              delete vehicleShapes[key];
            }
          }
        }

        function setupMap(data) {
          if (data != null) {
            element.css({
              'position': 'relative',
              'margin': '10px',
              'perspective': '1000px',
              'background-color': 'rgba(50, 50, 50, 0.6)',
              'border': '2px solid rgba(180, 180, 180, 0.8)',
            });
            svg.style.transform = "scale(-1, -1)"


            if (data.terrainSize) {
              var terrainSizeX = Math.min(data.terrainSize[0] / Math.min(data.squareSize, 1) / mapScale, 2048);
              var terrainSizeY = Math.min(data.terrainSize[1] / Math.min(data.squareSize, 1) / mapScale, 2048);
              viewParams = [
                (-terrainSizeX / 2),
                (-terrainSizeY / 2),
                terrainSizeX,
                terrainSizeY
              ];
            }
            else {
              viewParams = [
                (-512),
                (-512),
                1024,
                1024
              ];
            }

            mapcontainer.style.width = viewParams[2] + "px"
            mapcontainer.style.height = viewParams[3] + "px";
            svg.setAttribute('viewBox', viewParams.join(' '));

            // Draw the map elements
            var minX = 999, maxX = -999;
            var minY = 999, maxY = -999;

            var nodes = data.nodes;

            // figure out dimensions of the road network
            for (var key in nodes) {
              var el = nodes[key];
              if (-el.pos[0] < minX) minX = -el.pos[0];
              if (-el.pos[0] > maxX) maxX = -el.pos[0];
              if (el.pos[1] < minY) minY = el.pos[1];
              if (el.pos[1] > maxY) maxY = el.pos[1];
            }

            // use background image if existing, otherwise draw a simple grid
            if (data.minimapImage && data.terrainOffset && data.terrainSize) {
              // mapcontainer.style.backgroundSize = "100%"
              // mapcontainer.style.backgroundImage = "url('/" + data.minimapImage + "')"
              var bgImage = hu('<image>', svg).attr({
                'x': data.terrainOffset[0] / mapScale,
                'y': data.terrainOffset[1] / mapScale,
                'width': data.terrainSize[0] / mapScale,
                'height': data.terrainSize[1] / mapScale,
                'transform': "scale(-1,-1)",
                'xlink:href': "/" + data.minimapImage,
              });
            } else {
              // draw grid
              var distX = maxX - minX
              var dx = 50
              for (var x = minX; x <= maxX + 1; x += dx) {
                _createLine({ x: x, y: minY, radius: 1 }, { x: x, y: maxY, radius: 1 }, 'rgba(255,255,255,0.3)');
              }
              var distY = maxY - minY
              var dy = 50
              for (var y = minY; y <= maxY + 1; y += dy) {
                _createLine({ x: minX, y: y, radius: 1 }, { x: maxX, y: y, radius: 1 }, 'rgba(255,255,255,0.3)');
              }
            }

            function getDrivabilityColor(d) {
              if (d < 0.9) return 'rgba(110, 110, 110, 1)'; //'#853800';
              return 'rgba(160, 160, 160, 1)'; //#fa9e28';
            }

            function drawRoads(drivabilityMin, drivabilityMax) {
              for (var key in nodes) {
                var el = nodes[key];
                // walk the links of the node
                if (el.links !== undefined) { // links
                  var d = '';
                  var first = true;
                  for (var key2 in el.links) {
                    var el2 = nodes[key2];
                    var drivability = el.links[key2].drivability;
                    if (drivability >= drivabilityMin && drivability <= drivabilityMax) {
                      _createLine({
                        x: -el.pos[0] / mapScale,
                        y: el.pos[1] / mapScale,
                        radius: Math.min(Math.max(el.radius, 0), 5) * 3
                      }, {
                          x: -el2.pos[0] / mapScale,
                          y: el2.pos[1] / mapScale,
                          radius: Math.min(Math.max(el2.radius, 0), 5) * 3    // prevents massive blobs due to waypoints having larger radius'
                        }, getDrivabilityColor(drivability)
                      );
                    }
                  }

                  /*
                    if(first) {
                      d += 'M' + -el2.pos[0] + ' ' + -el2.pos[1]
                      first = false;
                    } else {
                      d += ' L' + -el2.pos[0] + ' ' + -el2.pos[1]
                    }
                    d +=' Z'
                  var p = hu('<path>', svg).attr({
                    stroke: getDrivabilityColor(drivability),
                    strokeWidth: 10,
                    strokeLinecap: "round",
                    fill: 'none',
                    d: d,
                  });
                    */

                }
              }
            }

            // draw dirt roads and then normal on top
            drawRoads(0, 0.9)
            drawRoads(0.9, 1)

            // draw nodes on top
            /*
            var nodeColor = '#fa9e28'
            for (var key in nodes) {
              var el = nodes[key];
              if (el.links !== undefined) {
                nodeColor = getDrivabilityColor(el.links[Object.keys(el.links)[0]]);
              }
              _createCircle(-el.pos[0], el.pos[1], el.radius * 2, nodeColor); // nodes
            }
            */

            mapReady = true;
          }

        }

        // need to draw collectables after roads have been drawn
        function setupCollectables(data) {
          var mapSize = viewParams[2];
          var perimeterScale = 0;

          scope.collectableTotal = data.collectableAmount;
          scope.collectableCurrent = data.collectableCurrent;

          // Calculating the different radius' for the collectible containers
          // based on map size.
          switch (true) {
            case (mapSize <= 1024): {
              perimeterScale = 130;
              break;
            }
            case (mapSize > 1024): {
              perimeterScale = 125
              break;
            }
            case (mapSize >= 2048): {
              perimeterScale = 100;
              break;
            }
          };

          // remove any existing collectable svgs
          for (var key in collectableShapes) {
            collectableShapes[key].remove();
          }
          collGroup = hu('<g>', svg);
          // draw collectable svgs
          for (var item in data.collectableItems) {
            var offset = (Math.random() * 50);
            var coll = hu('<circle>', collGroup).attr({
              cx: (-data.collectableItems[item][1] - (Math.max(Math.random() * 50), 50)), // collectable will be located somewhere within this circle but never in the exact center.
              cy: (data.collectableItems[item][2] - (Math.max(Math.random() * 50), 50)),
              r: perimeterScale,
              fill: 'rgba(255, 160, 0, 0.2)',
              stroke: 'rgba(255, 160, 0, 0.6)',
              'stroke-width': 3,
            });
            // store all collectable svgs
            collectableShapes[item] = coll;
          }
        };

        bngApi.engineLua('extensions.ui_uiNavi.requestUIDashboardMap()');

        bngApi.engineLua(`extensions.core_collectables.sendUIState()`);

      }
    };
  }]);