angular.module('beamng.stuff')

.directive('gameIndicatorsLayer', ['$compile', '$http', function ($compile, $http) {
  
  var arrows = {
    left:  {id: 'icon-left',  class: 'arrow-left' },
    right: {id: 'icon-right', class: 'arrow-right'},
    up:    {id: 'icon-up',    class: 'arrow-up'   },
    down:  {id: 'icon-down',  class: 'arrow-down' }
  };
  
  var icons = {
    warning:   { id: 'icon-warning' },
    bell:      { id: 'icon-bell' },
    happy:     { id: 'icon-emoji-happy' },
    sad:       { id: 'icon-emoji-sad' },
    help:      { id: 'icon-help' },
    home:      { id: 'icon-home' },
    lightbulb: { id: 'icon-light-bulb' }
  };
  
  var activeIndicators = {
    // [indicatorId]: { element: [DOM element], type: [Indicator type] }
  };
  
    
  
  
  
  return {
    restrict: 'E',
    scope: {},
    
    controller: function ($scope, $element, $attrs) {
      // console.log('hi!');
      var arrowsSprite = null;
      var iconsSprite = null;
      
      $http.get('modules/tests/indicators/arrows_default.svg')
        .success(function (svg) {
          arrowsSprite = angular.element(svg);
          $element.append(arrowsSprite);
        });
        
      $http.get('modules/tests/indicators/icons_default.svg')
        .success(function (svg) {
          iconsSprite = angular.element(svg);
          $element.append(iconsSprite);
        });
        
      var context = '[GameIndicators]';
      
      var addArrow = function (data) { 
        if (activeIndicators[data.id]) {
          console.warn(`${context}: Indicator ${data.id} already active.`);
          return;
        }
        
        var el = angular.element(`<svg> <use xlink:href="#${arrows[data.direction].id}"/> </svg>`);
        el.addClass(arrows[data.direction].class);
        $element.append(el);
        activeIndicators[data.id] = { element: el, type: 'arrow' };     
      };
      
      var addMessage = function (data) {
        var el = angular.element(`
          <svg height="300" width="300">
            <g transform="translate(10, 10)">
              <polyline style="fill:none;stroke:black;stroke-width:3" />
            </g>
          </svg>`
        );
        var path = el[0].querySelector('polyline');
        path.setAttribute('points', '0,0 0,100 100,100 100,200');
        //console.log('svg', el[0]);
        //console.log('path', path);
        $element.append(el);
      };
      
      var addIcon = function (data) {
        if (activeIndicators[data.id]) {
          //console.log(activeIndicators[data.id]);
          console.warn(`${context}: Indicator ${data.id} already active.`);
          var el = activeIndicators[data.id].element[0];
          
          
          //console.log('ELEMENT:', el);
          
         
          if (data.size) {
            el.style.width = `${data.size}px`;
            el.style.height = `${data.size}px`
          }
          
          if (data.position) {
            el.style.top = `${data.position.y - el.clientHeight/2}px`;
            el.style.left = `${data.position.x - el.clientWidth/2}px`;
          }
          
          return;
        }
        
        var el = angular.element(`<svg> <use xlink:href="#${icons[data.icon].id}"/> </svg>`);
        var size = data.size || 20;
        el.css({ position: 'absolute', height: `${size}px`, width: `${size}px`, top: `${data.position.y - size/2}px`, left: `${data.position.x - size/2}px`});
        $element.append(el);
        activeIndicators[data.id] = { element: el, type: 'icon' };
      };
      
      $scope.$on('GameIndicator', function (_, data) {
        
        //console.log('GameIndicator event!', data);
        // console.log(gameIndicators);
        if (!data.id) {
          console.error(`${context}: no id provided`);
          return;
        }
        
        if (data.remove) {
          if (!activeIndicators[data.id]) {
            console.error(`${context}: No indicator w/ id ${data.id}.`);
            return;
          }
          
          activeIndicators[data.id].element.remove();
          activeIndicators[data.id] = null;
          delete activeIndicators[data.id];
          return;
        }

        switch (data.type) {
          case 'arrow':
            addArrow(data);
            break;
          case 'message':
            // addMessage(data);
            //console.log(`${context}: Message indicator not implemented yet`);
            break;
          case 'icon':
            addIcon(data);
            break;
          default:
            console.warn(`${context}: Unknown indicator type ${data.type}`);
        }
      });
    }
  };
}])





.directive('messageIndicator', function () {
  return {
    require: 'gameIndicatorsLayer',
    scope: {
      msgPosition: '=',
      arrowPosition: '='
    },
    controller: ['$scope', '$element', '$attrs', function ($scope, $element, $attrs) {
      
    }]
  };
});
