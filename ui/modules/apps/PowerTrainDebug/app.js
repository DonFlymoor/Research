angular.module('beamng.apps')
.directive('powertrainApp', ['bngApi', 'StreamsManager', '$interval', '$filter', function (bngApi, StreamsManager, $interval, $filter) {
  return {
    template:
      `<svg style="width:100%; height:100%;margin:0;padding:0;pointer-event: none;background:none">
        <rect x="-0.14" y="-0.12" width="1.3" height="1.2" style="fill:black;fill-opacity:0.43;" />
        <defs>
          <g id='engineIcon'>
            <circle r="0.05" cx="0" cy="0" fill="#343434"/>
            <use fill="white" x="-0.05" y="-0.05" width="0.1" height="0.1" xlink:href="#powertrain_engine" />
          </g>
          <g id='automaticGearboxIcon'>
            <circle r="0.05" cx="0" cy="0" fill="#343434"/>
            <use fill="white" x="-0.04" y="-0.04" width="0.08" height="0.08" xlink:href="#powertrain_gearbox_automatic" />
          </g>
          <g id='manualGearboxIcon'>
            <circle r="0.05" cx="0" cy="0" fill="#343434"/>
            <use fill="white" x="-0.04" y="-0.04" width="0.08" height="0.08" xlink:href="#powertrain_gearbox_manual" />
          </g>
          <g id='sequentialGearboxIcon'>
            <circle r="0.05" cx="0" cy="0" fill="#343434"/>
            <use fill="white" x="-0.04" y="-0.04" width="0.08" height="0.08" xlink:href="#powertrain_gearbox_sequential" />
          </g>
          <g id='clutchIcon'>
            <circle r="0.05" cx="0" cy="0" fill="#343434"/>
            <use fill="white" x="-0.05" y="-0.05" width="0.1" height="0.1" xlink:href="#powertrain_clutch" />
          </g>
          <g id='torqueConverterIcon'>
            <circle r="0.05" cx="0" cy="0" fill="#343434"/>
            <use fill="white" x="-0.05" y="-0.05" width="0.1" height="0.1" xlink:href="#powertrain_torque_converter" />
          </g>
          <g id='rangeboxIcon'>
            <circle r="0.04" cx="0" cy="0" fill="#FFFFFF"/>
            <use fill="#343434" x="-0.05" y="-0.05" width="0.1" height="0.1" xlink:href="#powertrain_rangebox_high" />
          </g>
          <g id='lowRangeboxIcon'>
            <circle r="0.04" cx="0" cy="0" fill="#FFFFFF"/>
            <use fill="#343434" x="-0.05" y="-0.05" width="0.1" height="0.1" xlink:href="#powertrain_rangebox_low" />
          </g>
          <g id='shaftIcon'>
            <circle r="0.05" cx="0" cy="0" fill="#343434"/>
            <use fill="white" x="-0.05" y="-0.05" width="0.1" height="0.1" xlink:href="#powertrain_shaft_connected" />
          </g>
          <g id='disconnectedShaftIcon'>
            <circle r="0.05" cx="0" cy="0" fill="#343434"/>
            <use fill="white" x="-0.05" y="-0.05" width="0.1" height="0.1" xlink:href="#powertrain_shaft_disconnected" />
          </g>
          <g id='differentialOpenIcon'>
            <circle r="0.05" cx="0" cy="0" fill="#343434"/>
            <use fill="white" x="-0.05" y="-0.05" width="0.1" height="0.1" xlink:href="#powertrain_differential_open" />
          </g>
          <g id='differentialLSDIcon'>
            <circle r="0.05" cx="0" cy="0" fill="#343434"/>
            <use fill="white" x="-0.05" y="-0.05" width="0.1" height="0.1" xlink:href="#powertrain_differential_lsd" />
          </g>
          <g id='differentialViscousIcon'>
            <circle r="0.05" cx="0" cy="0" fill="#343434"/>
            <use fill="white" x="-0.05" y="-0.05" width="0.1" height="0.1" xlink:href="#powertrain_differential_lsd" />
          </g>
          <g id='differentialLockedIcon'>
            <circle r="0.05" cx="0" cy="0" fill="#343434"/>
            <use fill="white" x="-0.05" y="-0.05" width="0.1" height="0.1" xlink:href="#powertrain_differential_closed" />
          </g>
          <g id='wheelIcon'>
            <circle r="0.05" cx="0" cy="0" fill="#343434"/>
            <use fill="white" x="-0.05" y="-0.05" width="0.1" height="0.1" xlink:href="#powertrain_wheel_connected" />
          </g>
          <g id='disconnectedWheelIcon'>
            <circle r="0.05" cx="0" cy="0" fill="#343434"/>
            <use fill="white" x="-0.05" y="-0.05" width="0.1" height="0.1" xlink:href="#powertrain_wheel_disconnected" />
          </g>
          <g id='torsionReactorIcon'>
            <circle r="0.05" cx="0" cy="0" fill="#343434"/>
            <use fill="white" x="-0.05" y="-0.05" width="0.1" height="0.1" xlink:href="#powertrain_torsion_reactor" />
          </g>
          <!-- placeholder images below -->
          <g id='unknownIcon'>
            <circle r="0.05" cx="0" cy="0" fill="rgba(255, 0, 255, 0.8)" strokeWidth="0.01"></circle>
            <text x="-0.035" y="0.035" font-family="Roboto" font-size="0.1">?</text>
          </g>
        </defs>
        <!-- <use x=0 y=0 xlink:href="#gearboxIcon" /> -->
      </svg>`,


              r: 0.05,
              cx: 0,
              cy: 0,
              stroke: 'white',
              fill: 'rgba(255, 255, 255, 0.8)',
              //cursor: 'pointer',
              strokeWidth: 0.01,
              strokeLinecap: "round",
    replace: true,
    link: function ($scope, element, attrs) {
      var svg = element[0];
      var svgItems = []; // contains all svg items - need to be destroyed on recreation
      var prevSvgItems = []; // items to be cleaned up
      var powerCoef = 1;
      var torqueCoef = 1;
      var redrawRequested = true;
      var interactionMode = false; // mouse over mode: show things that you can interact with?
      var lastselectedNode = null;
      var nodeFocusColor = '#aaaaff'
      var displayTypeText = [$filter('translate')('ui.options.units.power'), $filter('translate')('ui.options.units.torque')]
      var displayType = 1; //power:0 torque:1

      // icons setup
      var typeIcons = {
        automaticGearbox : '#automaticGearboxIcon',
        dctGearbox : '#automaticGearboxIcon',
        cvtGearbox : '#automaticGearboxIcon',
        manualGearbox : '#manualGearboxIcon',
        sequentialGearbox : '#sequentialGearboxIcon',
        rangeBox : '#rangeboxIcon',
        combustionEngine : '#engineIcon',
        shaft : '#shaftIcon',
        multiShaft : '#shaftIcon',
        frictionClutch : '#clutchIcon',
        torqueConverter : '#torqueConverterIcon',
        wheel : '#wheelIcon',
        differential_open : '#differentialOpenIcon',
        differential_lsd : '#differentialLSDIcon',
        differential_viscous : '#differentialViscousIcon',
        differential_locked : '#differentialLockedIcon',
        splitShaft : '#differentialViscousIcon',
        viscousClutch : '#torqueConverterIcon',
        torsionReactor : '#torsionReactorIcon'
      };

      // icons setup end
      var modeMap = {
        disconnected : '#disconnectedShaftIcon',
        low : '#lowRangeboxIcon',
        open : '#differentialOpenIcon',
        locked : '#differentialLockedIcon',
        lsd : '#differentialLSDIcon',
      };

      var ExponentialSmoothing = function(window, startingValue) {
        if(typeof window === "undefined") window = 10;
        this.a = 2 / window;
        this.samplePrev = null;
        this.stPrev = null;
        if(typeof startingValue !== "undefined") {
          this.samplePrev = startingValue;
          this.stPrev = startingValue;
        }
      }
      ExponentialSmoothing.prototype.update = function(sample) {
        if(this.samplePrev === null) {
          this.samplePrev = sample;
          this.stPrev = sample;
          return sample;
        }
        this.stPrev = this.stPrev + this.a * (this.samplePrev - this.stPrev);
        this.samplePrev = sample;
        return this.stPrev;
      }

      function camelCaseSpaceInserter(t) {
        // camelcase space inserter: ThisIsAnExample > This Is An Example
        var lastCaseSenType = 0;
        var res = '';
        for (var i = 0; i < t.length; i++) {
          var c = t.charAt(i);
          var caseSenType = 0; // lower
          if(c == c.toUpperCase()) caseSenType = 1; // upper
          if(lastCaseSenType < caseSenType) {
            res += ' ' + c;
          } else {
            res += c;
          }
          lastCaseSenType = caseSenType;
        }
        return res;
      }

      var streamsList = ['powertrainDeviceData'];
      StreamsManager.add(streamsList);
      $scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      function posMinMax(graph) {
        var minx = Infinity, miny = Infinity, maxx = -Infinity, maxy = -Infinity;
        for(var i = 0; i < graph.nodes.length; i++) {
          var node = graph.nodes[i];
          if (node.pos != null) {
            minx = Math.min(minx, node.pos.x);
            miny = Math.min(miny, node.pos.y);
            maxx = Math.max(maxx, node.pos.x);
            maxy = Math.max(maxy, node.pos.y);
          }
        }
        if (minx == maxx) {
          minx = 0;
          maxx *= 2;
        }
        if (miny == maxy) {
          miny = 0;
          maxy *= 2;
        }
        if (!isFinite(minx)) {
          minx = 0;
          maxx = 1;
          miny = 0;
          maxy = 1;
        }
        return [minx, miny, maxx, maxy];
      }

      function normalizeGraphPos(graph) {
        var tmp = posMinMax(graph);
        var minx = tmp[0], miny = tmp[1], maxx = tmp[2], maxy = tmp[3];
        var invdifx = 1.0 / (maxx - minx + 1e-25);
        var invdify = 1.0 / (maxy - miny + 1e-25);

        var undefy = 0;
        if (graph.fixedNodes.length > 0) {
          for(var i = 0; i < graph.fixedNodes.length; i++) {
            undefy += (graph.fixedNodes[i][0].pos.y - miny) * invdify;
          }
          undefy /= graph.fixedNodes.length;
        }
        var undefx = -0.1;
        //undefy = 1
        for(var i = 0; i < graph.nodes.length; i++) {
          var node = graph.nodes[i];
          if (node.pos != null) {
            node.pos.x = (maxx - node.pos.x) * invdifx;
            node.pos.y = (node.pos.y - miny) * invdify;
          } else {
            node.pos = {x : 0.5 + undefx, y : undefy};
            undefx = -undefx;
            undefy -= 0.01;
          }
        }
        var newFixed = [];
        for(var i = 0; i < graph.fixedNodes.length; i++) {
          var n1 = graph.fixedNodes[i][0];
          var overlap = false;
          for(var i1 = 0; i1 < i; i1++) {
            var n2 = graph.fixedNodes[i1][0];
            var dx = n1.pos.x - n2.pos.x;
            var dy = n1.pos.y - n2.pos.y;
            if (dx * dx + dy * dy < 0.005) {
              overlap = true;
              n1.pos.y = n1.pos.y + i * 1e-10
              break;
            }
          }
          if (!overlap) {
            newFixed.push([n1, n1.pos.x, n1.pos.y]);
          }
        }
        graph.fixedNodes = newFixed;
      }

      function fdgStep(graph, t) {
        // reset forces
        for(var i = 0; i < graph.nodes.length; i++) {
          graph.nodes[i].force.x = 0;
          graph.nodes[i].force.y = 0;
        }

        // calculate repulsive forces
        for(var i1 = 0; i1 < graph.nodes.length - 1; i1++) {
          var n1 = graph.nodes[i1];

          for(var i2 = i1 + 1; i2 < graph.nodes.length; i2++) {
            var n2 = graph.nodes[i2];

            var dx = n1.pos.x - n2.pos.x;
            var dy = n1.pos.y - n2.pos.y;
            var l = dx * dx + dy * dy;
            var coef = 0.000005 / (l * l + 1e-30);
            var fx = dx * coef;
            var fy = dy * coef;
            n1.force.x += fx;
            n1.force.y += fy;
            n2.force.x -= fx;
            n2.force.y -= fy;
          }
        }

        // calculate attractive forces
        for(var i = 0; i < graph.edges.length; i++) {
          var e = graph.edges[i];
          var n1 = e.n1;
          var n2 = e.n2;
          var dx = n1.pos.x - n2.pos.x;
          var dy = n1.pos.y - n2.pos.y;
          var coef = Math.sqrt(dx * dx + dy * dy) * 0.1;
          var fx = dx * coef;
          var fy = dy * coef;
          n1.force.x -= fx;
          n1.force.y -= fy;
          n2.force.x += fx;
          n2.force.y += fy;
        }

        // integrator
        for(var i = 0; i < graph.nodes.length; i++) {
          var n = graph.nodes[i];

          n.pos.x += Math.sign(n.force.x) * Math.min(Math.abs(n.force.x), t)
          n.pos.y += Math.sign(n.force.y) * Math.min(Math.abs(n.force.y), t)
        }

        // reset fixed nodes
        for(var i = 0; i < graph.fixedNodes.length; i++) {
          graph.fixedNodes[i][0].pos.x = graph.fixedNodes[i][1];
          graph.fixedNodes[i][0].pos.y = graph.fixedNodes[i][2];
        }
      }

      var graph = null
      function createGraph(graph, devices) {
        for (var k in devices) {
          var node = devices[k];
          if(node.pos != null) {
            graph.fixedNodes.push([node, node.pos.x, node.pos.y]);
          }
          node.name = k;
          node.force = {x: 0, y: 0};
          graph.nodes.push(node);
          graph.namedNodes[k] = node;
          node.edges = [];
          for(var k1 in node.children) {
            var e = { n1: node, n2: devices[node.children[k1]], dashOffset: 0, av: 0, torque: 0}
            graph.edges.push(e)
            node.edges.push(e);
          }
        }
      }

      // tries to interpret the values that we are presented with. Hardcoded meaning below.
      function generateFancyName(n) {
        if(n.fancyName === undefined) {
          var t = n.name;
          t = t.charAt(0).toUpperCase() + t.slice(1);
          t = t.replace(/[_]?FL/, "Front Left");
          t = t.replace(/[_]?FR/, "Front Right");
          t = t.replace(/[_]?RL/, "Rear Left");
          t = t.replace(/[_]?RR/, "Rear Right");
          t = t.replace('_R', "Rear");
          t = t.replace('_F', "Front");
          t = camelCaseSpaceInserter(t);
          t = t.replace(/_/g, ' ');
          t = t.replace(/\s+/g, ' ');
          t = t.replace(/^\s+/, '');
          t = t.replace(/\s+$/, '');
          n.fancyName = t + ' / ' + n.name;
        }
      }

      function showNodeInfo(n, enforceUpdate) {
        //console.log('showNodeInfo', enforceUpdate)
        if (enforceUpdate === undefined && n === lastselectedNode) {return;}
        lastselectedNode = n;
        var items = []

        items.push(n.fancyName);
        // items.push(n.type); // not really needed as its the same most of the time
        if(n.modes && n.currentMode) {
          items.push('state: ' + n.currentMode);
        }
        if(n.valueText) {
          items.push(n.valueText);
        }
        //n.nodeText.css({opacity:1})
        n.focusRing.css({opacity:1, stroke: nodeFocusColor})
        graph.infoText.text(items.join(', '));
        graph.infoText.css({opacity:1, fill:'white'})
      }

      function createSvgGraph(graph) {
        graph.infoText = hu('<text>', svg).attr({
          fill: 'rgba(255,255,255,1)',
            x: -0.12,
            y: -0.06,
        });
        graph.infoText.css({fontSize:'0.033pt', fill:'white', opacity:1, 'font-weight': 'bold',
            'text-shadow': '-1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, 1px 1px 0 #000'
          })
        graph.infoText.text(displayTypeText[displayType]);

        function switchType() {
          displayType = 1 - displayType;
          graph.infoText.text(displayTypeText[displayType]);
        }

        graph.infoText.on('mousedown', switchType)

        svgItems.push(graph.infoText);

        function clearInfo() {
          if(lastselectedNode !== null) {
            //lastselectedNode.nodeText.css({opacity:0});
            //lastselectedNode.nodeIcon.css({'box-shadow': ''});
            lastselectedNode.focusRing.css({opacity:0})
            lastselectedNode = null;
          }
           graph.infoText.text(displayTypeText[displayType]);
           graph.infoText.css({fill:'yellow'})
        }

        function showEdgeInfo(e) {
          var txt = 'edge: ' + e.i;
          graph.infoText.css({opacity:0})
          graph.infoText.text(txt);
        }

        // create edges bottom to top
        for(var i = graph.edges.length - 1; i >= 0; i--) {
          var e = graph.edges[i];
          var n1 = e.n1;
          var n2 = e.n2;
          e.n1.hasEdge = true;
          e.n2.hasEdge = true;
          // background line
          var linebg = hu('<line>', svg);
          linebg.attr({
            strokeWidth: 0.001,
            strokeLinecap: "round",
          });
          svgItems.push(linebg);
          e.linebg = linebg;

          // foreground line
          var linefg = hu('<line>', svg);
          linefg.attr({
            strokeWidth: 0.001,
            strokeDasharray: '0.035, 0.1',
            strokeLinecap: "round",
          });
          svgItems.push(linefg);
          e.linefg = linefg;

          //linefg.on('mouseenter', showEdgeInfo.bind(this, e))
          //linefg.on('mouseleave', clearInfo)
        }
        // and the nodes on top

        function switchNode(node) {
          if(!node.modes || !node.currentMode) return;
          showNodeInfo(node, true)
          var curNum = 0;
          for(var i = 0; i < node.modes.length; i++) {
            if(node.modes[i] === node.currentMode) {
              curNum = i;
              break;
            }
          }
          var newMode = node.modes[(curNum + 1) % (node.modes.length)]
          var cmd = 'powertrain.setDeviceMode("' + node.name + '","' + newMode + '")';
          //console.log('switching node: ' + node.name + ' to mode ' + newMode);
          bngApi.activeObjectLua(cmd);
        }

        for(var i = 0; i < graph.nodes.length; i++) {
          var n = graph.nodes[i];
          var nodeIcon;

          n.focusRing = hu('<circle>', svg).attr({
            cx: n.pos.x,
            cy: n.pos.y,
            r: 0.049,
            stroke: 'yellow',
            strokeWidth: 0.01,
            fill: 'rgba(0, 0, 0, 0)',
          });
          n.focusRing.css({opacity:0})
          svgItems.push(n.focusRing);

          if(typeIcons[n.type] !== undefined) {
            var iconName = typeIcons[n.type];
            if (n.currentMode in modeMap) {

              if (iconName == '#wheelIcon') {
                iconName = '#disconnectedWheelIcon'
              } else {
                iconName = modeMap[n.currentMode];
              }
            }
            nodeIcon = hu('<use>', svg).attr({
              'xlink:href' : iconName,
              x: n.pos.x,
              y: n.pos.y,
            });

          } else {
            // generic circle
            nodeIcon = hu('<circle>', svg).attr({
              cx: n.pos.x,
              cy: n.pos.y,
              r: 0.043,
              stroke: 'white',
              strokeWidth: 0.008,
              fill: 'rgba(120, 120, 120, 1)',
              //cursor: 'pointer',
            });
          }

          nodeIcon.on('mouseover', showNodeInfo.bind(this, n))
          nodeIcon.on('mouseleave', clearInfo)
          if(n.modes) {
            nodeIcon.on('mousedown', switchNode.bind(this, n))
            nodeIcon.css({cursor: 'pointer'})
            nodeIcon.attr({
              fill: 'rgba(0, 180, 0, 1)'
            })
          }

          n.nodeIcon = nodeIcon;
          svgItems.push(nodeIcon);

          // gray out nodes without edges
          if(n.hasEdge === undefined) {
            n.nodeIcon.css({opacity:'0.6'})
          }

          // try to reselect the node that was active before the graph was recreated?
          if(lastselectedNode) showNodeInfo(lastselectedNode)

          generateFancyName(n);
        }
        // the labels on top
        for(var i = 0; i < graph.nodes.length; i++) {
          var n = graph.nodes[i];
          /*
          var nodeText = hu('<text>', svg).attr({
            x: n.pos.x,
            y: n.pos.y - 0.08,
            textAnchor:"middle",
            fill: 'rgba(255,255,255,1)',
            //cursor: 'pointer',
          });
          nodeText.css({fontSize:'0.033pt', fill:'white', opacity:0, 'font-weight': 'bold', 'pointer-events': 'none',
            'text-shadow': '-1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, 1px 1px 0 #000'
          })
          var name;
          if(n.currentMode !== undefined) {
            name = n.name + ' : ' + n.currentMode;
          } else {
            name = n.name;
          }
          nodeText.text(name);
          n.nodeText = nodeText
          svgItems.push(nodeText);
          */
        }

        svg.setAttribute('viewBox', [-0.14, -0.12, 1.3, 1.2].join(' '));
        svg.setAttribute('preserveAspectRatio', 'xMinYMin meet');
      }

      function setIconData(n, e) {
        if(e && (n.type === 'wheel' || n.type === 'torqueConverter' || n.type === 'frictionClutch')) {
          if(n.rot === undefined) n.rot = 0
          n.rot = n.rot + Math.sign(e.av) * Math.min(3, Math.abs(1 * e.av));
          n.nodeIcon.attr({"transform": "rotate(" + Math.round(n.rot) + "," + n.pos.x + "," + n.pos.y + ")"}) // Math.round(n.rot) because CSS dodes not like 12e-12 numbers
        }
        var textItems = []
        if(e && e.av) {
          textItems.push('RPM: ' + Math.round(e.av * 9.549296596425384)); // AV to RPM: 9.549296596425384
        }
        if(n.hasEdge === undefined) {
          textItems.push('(not driven)')
        }
        n.valueText = textItems.join(', ');
      }
      function updateInteractionViz() {
        for(var i = 0; i < graph.nodes.length; i++) {
          var n = graph.nodes[i];
          if(n.modes && n.focusRing !== undefined) {
            n.focusRing.css({opacity:(interactionMode?1:0), stroke: (lastselectedNode == n)?nodeFocusColor:'yellow'})
          }
        }
        if(lastselectedNode) {
          showNodeInfo(lastselectedNode, true);
          graph.infoText.css({fill: 'white'})
        } else {
          graph.infoText.css({fill: interactionMode?'yellow':'white'})
        }
      }

      element.on('mouseover', function(e) { interactionMode = true; updateInteractionViz() })
      element.on('mouseleave', function(e) { interactionMode = false; updateInteractionViz() })

      function updateSvgGraph() {
        if(lastselectedNode) setIconData(lastselectedNode); // even update the data of selected nodes that are not in the edge list
        for(var i = 0; i < graph.edges.length; i++) {
          var e = graph.edges[i];
          var n1 = e.n1, n2 = e.n2;
          // var power = e.torque * e.av;
          var diplayVar = displayType == 0 ? e.torque * e.av : e.torque;
          var displayCoef = displayType == 0 ? powerCoef : torqueCoef;
          setIconData(n1, e);
          setIconData(n2, e);
          var intensity = Math.max(Math.min(Math.sqrt(Math.abs(diplayVar * displayCoef)) * 700, 100),0);
          var color = e.torque > 0 ? 201 : 30;
          var satdif = 100 - intensity;
          // the background line
          var lineAttr = {
            x1: n1.pos.x,
            y1: n1.pos.y,
            x2: n2.pos.x,
            y2: n2.pos.y,
            strokeWidth: Math.max(Math.min(Math.abs(diplayVar * displayCoef), 0.1), 0.015),
            stroke: 'hsla(' + color + ',' + Math.round(intensity) +'%,' + Math.round(50 - satdif * 0.3) + '%, 0.8)',
          };
          e.linebg.attr(lineAttr);
          // now the foreground line
          // use the sum of dash lengths for the % value
          if(Math.abs(e.av) > 0.01) {
            e.dashOffset = e.dashOffset - Math.sign(e.torque * e.av) * Math.min(0.01, Math.abs(e.torque * 0.00003));
          }
          lineAttr.strokeDashoffset = (e.dashOffset * 100) + '%';
          //lineAttr.strokeWidth += 0.005 * Math.min(intensity * 0.01, 1);
          lineAttr.stroke = 'hsla(' + color + ',' + Math.round(intensity) +'%,' + Math.round(50 + satdif * 0.2) + '%, 0.8)';
          e.linefg.attr(lineAttr);
        }
        updateInteractionViz();
      }

      // cleaning step one: create a new array and put the garbage to be cleaned up into another
      function cleanSVG() {
        if(graph.infoText) graph.infoText.css({opacity:0})
        if(prevSvgItems.length) cleanSVGPrev(); // if the garbage was not cleaned up yet, do it now to prevent leaking things
        prevSvgItems = svgItems;
        svgItems = []
        delete graph.infoText;
      }

      // cleaning step two: clear the garbage out. the new elements will have rendered already, so no flashing should appear
      function cleanSVGPrev() {
        // clear any old SVG items
        for(var key in prevSvgItems) {
          prevSvgItems[key].remove();
        }
        prevSvgItems = [];
      }1

      $scope.$on('PowertrainDeviceTreeChanged', function (event, data) {
        // console.log('PowertrainDeviceTreeChanged', data);
        powerCoef = 0.0001 / Math.max(data.maxPower, 1);
        torqueCoef = 0.7 / Math.max(data.maxTorque, 1);
        graph = {
          nodes: [],
          fixedNodes: [],
          namedNodes: {},
          edges: [],
        }
        createGraph(graph, data.devices);
        normalizeGraphPos(graph);
        // console.log('graph: ', graph);

        // we pre-run the FDG
        var t = 0.5;
        for(var n = 0; n < 2000; n++) {
          //t = t * 0.99
          fdgStep(graph, t);
        }
        var tmp = posMinMax(graph);
        var minx = tmp[0], miny = tmp[1], maxx = tmp[2], maxy = tmp[3];
        var invdifx = 1.0 / (maxx - minx + 1e-25);
        var invdify = 1.0 / (maxy - miny + 1e-25);
        for(var i = 0; i < graph.nodes.length; i++) {
          var n = graph.nodes[i];
          n.pos.x = (n.pos.x - minx) * invdifx;
          n.pos.y = (n.pos.y - miny) * invdify;
        }
        cleanSVG();
        createSvgGraph(graph);
        //console.log('tree after step: ', graph);
        updateSvgGraph(graph);
      });
      bngApi.activeObjectLua('powertrain.sendDeviceTree()');

      // request data on vehicle exchange (same GE object)
      $scope.$on('VehicleChange', function (event, data) {
        bngApi.activeObjectLua('powertrain.sendDeviceTree()');
      });

      // request data on TAB
      $scope.$on('VehicleFocusChanged', function (event, data) {
        bngApi.activeObjectLua('powertrain.sendDeviceTree()');
      });

      // dynamic updates disabled
      $interval(function(){
        if(prevSvgItems.length) cleanSVGPrev();
        if(graph === null || !redrawRequested) return;
        redrawRequested = false;
        //fdgStep(graph, 0.5);
        updateSvgGraph(graph);
      }, 60)

      var logged = false;
      $scope.$on('streamsUpdate', function (event, data) {
        if(!data.powertrainDeviceData || graph === null) return;

        var devices = data.powertrainDeviceData.devices;
        var recreateSVG = false;
        for(var k in data.powertrainDeviceData.devices) {
          if(!graph.namedNodes[k]) continue;
          if (('currentMode' in devices[k]) && graph.namedNodes[k].currentMode != devices[k].currentMode) {
            recreateSVG = true;
          }
          graph.namedNodes[k].currentMode = devices[k].currentMode;
          for(var i=0; i < graph.namedNodes[k].edges.length; i++) {
            var edge = graph.namedNodes[k].edges[i];
            if(edge.avSmoother === undefined) {
              edge.avSmoother = new ExponentialSmoothing(5);
            }
            if(edge.torqueSmoother === undefined) {
              edge.torqueSmoother = new ExponentialSmoothing(5);
            }

            edge.torque = edge.torqueSmoother.update(devices[k].outputTorque[i]);
            edge.av = edge.avSmoother.update(devices[k].outputAV[i]);
          }
        }
        if(!logged) {
          //console.log('streamsUpdate', data.powertrainDeviceData, graph.namedNodes);
          console.log(data);

          logged = true;
        }
        redrawRequested = true;
        if (recreateSVG) {
          cleanSVG();
          createSvgGraph(graph);
        }
      });
      $scope.$on('app:resized', function (event, data) {
        //svg.setAttribute('viewBox', [0, 0, data.width, data.height].join(' '));
      });
    }
  };
}]);