angular.module('beamng.stuff')

//thanks to: https://gist.github.com/Todd-Werelius/bbc735daec6951938c4b
.directive('mdxPaintFg',function(mdx) {
  "use strict";
  return {
    restrict : 'A',
    link     : function(scope, element, attributes) {
      setTimeout(function() {
        setRGB(element,'color',mdx.mdxThemeColors,attributes.mdxPaintFg,'mdx-paint-fg');
      });
    }
  };
})
.directive('mdxPaintBg',function(mdx) {
  "use strict";
  return {
    restrict : 'A',
    link     : function(scope, element, attributes) {
      setTimeout(function() {
        setRGB(element,'background-color',mdx.mdxThemeColors,attributes.mdxPaintBg,'mdx-paint-bg');
      });
    }
  };
})
.directive('mdxPaintSvg',function(mdx) {
    "use strict";
    return {
      restrict : 'A',
      link     : function(scope, element, attributes) {
        setTimeout(function() {
          setRGB(element,'fill',mdx.mdxThemeColors,attributes.mdxPaintSvg,'mdx-paint-svg');
        });
      }
    };
  })
// Couldn't get access to _PALETTES any other way?
.provider('mdx', ['$mdThemingProvider', 'AppDefaults', function($mdThemingProvider, AppDefaults){
  return {
    $get : function() {
      "use strict";
      return {
        mdxThemeColors : $mdThemingProvider,
        indices: {
          'primary': {
            light: '500',
            dark:  '500'
          },
          'accent': {
            light: 'A200',
            dark: '300'
          },
          'warn': {
            light: '700',
            dark: '700'
          },
          'background': {
            light: 'A100',
            dark: '800'
          }
        },
        getCurrentTheme: function () {
          if (localStorage.getItem('angularThemeConfig')) {
            return JSON.parse(localStorage.getItem('angularThemeConfig')) || AppDefaults.uiTheme;
          }
          return AppDefaults.uiTheme;
        }
      };
    }
  };
}]);


function setRGB(element,styled,themeProvider,input,directiveName) {
  "use strict";
  var themeName     = 'default';
  var hueName       = 'default';
  var intentionName = 'primary';
  var hueKey,theme,hue,intention;

  // Do our best to parse out the attributes
  angular.forEach(input.split(" "), function(value, key) {
    if (0 === key && 'default' === value) {
      themeName = value;
    } else
    if ({primary:'primary',accent:'accent',warn:'warn',background:'background'}[value]) {
      intentionName = value;
    } else if ({default:'default','hue-1':'hue-1','hue-2':'hue-2','hue-3':'hue-3'}[value]) {
      hueName = value;
    } else if ({'50' :'50' ,'100':'100','200':'200','300':'300','400':'400',
                '500':'500','600':'600','700':'700','800':'800','A100':'A100',
                'A200':'A200','A400':'A400','A700':'A700'}[value]) {
      hueKey = value;
    }
  });

  // Lookup and assign the right values
  if ((theme = themeProvider._THEMES[themeName])) {
    if ((intention = theme.colors[intentionName]) ) {
      if (!hueKey) {
        hueKey = intention.hues[hueName];
      }
      if ((hue = themeProvider._PALETTES[intention.name][hueKey]) ) {
        element.css(styled,'rgb('+hue.value[0]+','+hue.value[1]+','+hue.value[2]+')');
        return;
      }
    }
  }

  console.error("%s='%s' bad or missing attributes", directiveName, input);
  console.log(`  usage ${directiveName}="[theme] intention [hue]"
                   acceptable intentions : primary, accent, warn, background
                   acceptable hues       : default, hue-1, hue-2, hue-3`);
}