angular.module('beamng.controls')

.directive('bngSelect', ['$translate', 'bngApi', function ($translate, bngApi) {
  return {
    scope: {
      options: '=',
    },
    require: ['ngModel', '?^bngNavItem'],
    replace: true,
    template: `
      <div class="bng-select">
        <span ng-click="changeValue(-1)" class="button left"></span>
        <span class="text"></span>
        <span ng-click="changeValue(1)" class="button right"></span>
      </div>
    `,

    link: function (scope, element, attrs, controllers) {
      var ngModel = controllers[0]
        , navItemCtrl = controllers[1]
      ;

      var txt = element[0].querySelector('.text');
      var loop = 'loop' in attrs && (attrs.loop == "" ? true : scope.$eval(attrs.loop));

      var lButton = element[0].querySelector('.button.left')
        , rButton = element[0].querySelector('.button.right');

      var config = angular.merge({ value: x => x, label: x => x },  eval(`(${attrs.config})`) )
        , index = -1
      ;

      var findIndex = () => {
        index = scope.options.findIndex(
          x => angular.equals(config.value(x), ngModel.$modelValue)
        );
      };

      var updateText = () => {
        $translate(config.label(scope.options[index])).then((val) => {
          txt.innerHTML = val;
        });
      };

      ngModel.$render = () => {
        findIndex();
        updateText();
      };

      scope.changeValue = (offset) => {
        if (index < 0) return;
        if (loop) {
          index = (scope.options.length + index + offset) % (scope.options.length);
        } else {
          index += offset;
          index = Math.max(0, index);
          index = Math.min(index, scope.options.length-1);

          if (index == 0) {
            lButton.classList.add('bng-disabled');
          } else {
            lButton.classList.remove('bng-disabled');
          }

          if (index == scope.options.length - 1) {
            rButton.classList.add('bng-disabled');
          } else {
            rButton.classList.remove('bng-disabled')
          }
        }
        bngApi.engineLua(`Engine.Audio.playOnce('AudioGui', 'event:>UI>Garage>Select Part', {unique = true})`);
        ngModel.$modelValue = config.value(scope.options[index]);
        ngModel.$viewValue  = ngModel.$modelValue;
        ngModel.$$writeModelToScope();
        updateText();
      };

      if (navItemCtrl) {
        navItemCtrl.actions.right = {cmd: () => { scope.changeValue(1); }, name: 'Increase'};
        navItemCtrl.actions.left = {cmd: () => { scope.changeValue(-1); }, name: 'Decrease'};
      }
      var _init_ = () => {
        findIndex();
        // scope.changeValue(0); // <-- why? this just triggers an ng-change on initialisation and works fine without as far as i see it
      }

      element.ready(_init_);
      scope.$watch('options', _init_);

    }
  };
}])

.directive('bngSlider', ['$document', 'Utils', 'bngApi', function ($document, Utils, bngApi) {
  return {
    restrict: 'E',
    require: ['ngModel', '?^bngNavItem'],
    template: `
      <div class="bng-slider" tabindex="a" ondragstart="return false;">
        <div class="bng-slider-filler">
          <div class="bng-slider-handle"></div>
        </div>
      </div>
    `,
    replace: true,
    link: function (scope, element, attrs, controllers) {
      var ngModel = controllers[0]
        , navItemCtrl = controllers[1]
      ;

      // TODO: The <div> element should not be focusable at all!
      // Not sure why it has a tabindex value 0, possibly from ng-material.
      // For the moment, an invalid value like "a" does the job.
      var xOffset = () => element[0].getBoundingClientRect().left
        , xFactor = () => (max - min) / element[0].offsetWidth
        , min = parseFloat(attrs.min) || 0
        , max = parseFloat(attrs.max) || 100
        , step = parseFloat(attrs.step) || 1;

      var track = angular.element(element[0])
        , filler = element[0].querySelector('.bng-slider-filler');

      var drawFiller = () => {
        filler.style.width = (ngModel.$modelValue - min) / xFactor() + 'px';
      };

      scope.moveSlider = function (ticks) {
        var short =  Utils.round(ngModel.$modelValue + ticks*step, step);
        if (short <= max && short >= min) {
          setVal(short);
        }
      };

      if (navItemCtrl) {
        navItemCtrl.actions.right = {cmd: () => { scope.moveSlider(1); }, name: 'Increase'};
        navItemCtrl.actions.left = {cmd: () => { scope.moveSlider(-1); }, name: 'Decrease'};
      }

      var setValue = ($event) => {
        scope.$evalAsync(() => {
          var v = min + ($event.clientX - xOffset()) * xFactor();
          v = Math.round(v / step) * step;
          if (v > max) v = max;
          else if (v < min) v = min;
          setVal(v);
        });
      };

      function setVal (v) {
        bngApi.engineLua(`Engine.Audio.playOnce('AudioGui', 'event:>UI>Garage>Slider', {unique = true})`);
        ngModel.$modelValue = v;
        ngModel.$viewValue  = ngModel.$modelValue;
        ngModel.$$writeModelToScope();
        drawFiller();
      }

      ngModel.$render = drawFiller;
      var addListeners    = () => { $document.on('mousemove', setValue); };
      var removeListeners = () => { $document.off('mousemove', setValue); };

      track.on('mousedown', (event) => {
        drawFiller();
        scope.$evalAsync(() => {
          setValue(event);
        });

        addListeners();
      });

      track.on('dragend', () => { removeListeners(); });
      $document.on('mouseup', () => { removeListeners(); });

      element.ready(() => {
        ngModel.$render();
      });
    }
  };
}])

.directive('bngButton', function () {
  return {
    restrict: 'E',
    scope: {
      click: '&'
    },
    require: ['?^navItem'],
    template: `
      <div bng-font="secondary" class="bng-button color-white bd-padding bd-margin" layout="row" layout-align="center center" ng-focus="focus=true"
        ng-blur="focus=false" ng-class="{'bg-primary-dark': focus, 'bg-primary-light': !focus}" ng-click="click()">
        <ng-transclude></ng-transclude>
      </div>
    `,
    transclude: true,
    replace: true,
    link: function (scope, element, attrs, controllers) {
      var navItemCtrl = controllers[0];

      if (navItemCtrl) {
        navItemCtrl.actions.click = {cmd: () => scope.click(), navigation: true};
      }
    }
  }
})


.service('ConfirmationDialog', function ($q) {
  var dialogs = []
  , dialogFn
  , dialogDisplayed = false
  ;

  function open (title, text, options) {
    var deferred = $q.defer();

    if (typeof options[0] === 'string') {
      options = options.map(e => ({label: e, key: e}));
    }
    dialogs.push({dialog: {title: title, text: text, options: options}, deferred: deferred});

    if (!dialogDisplayed) {
      showDialog();
    }

    return deferred.promise;
  }

  function showDialog () {
    var d = dialogs.shift();
    dialogDisplayed = true;

    if (dialogFn === undefined) {
      deferred.reject('Missing dialog dir in current DOM.')
    } else {
      if (d === undefined) {
        console.error('Tried to show dialog when there was non queued');
      } else {
        dialogFn(d.dialog, (res) => {
          d.deferred.resolve(res);
          dialogDisplayed = false;
          if (dialogs.length > 0) {
            showDialog();
          }
        });
      }
    }
  }

  function register (setFn) {
    dialogFn = setFn;
  }

  //  IMPORTANT: It is on purpose, that there is no hook here. Do NOT add one.
  return {
    open: open,
    _registerDir: register
  }
})

.directive('bngDialog', function (ConfirmationDialog) {
  return {
    restrict: 'E',
    replace: true,
    template: `
    <div ng-if="show" class="container dialog">
      <div nav-root class="bg-grey-dark" position="center center" layout="column">
        <div class="header bg-primary" layout="row" layout-align="center center">
          <div class="color-white bd-padding heading2">
            {{ dialog.title | translate }}
          </div>
        </div>
        <div flex class="content bd-padding" layout="column">
          <div flex class="color-white msg bd-margin text">
            {{ dialog.text | translate }}
          </div>
          <div class="options" layout="row" layout-align="end center" layout-wrap>
            <bng-button nav-item click="clicked(option.key)" ng-repeat="option in dialog.options track by $index">
              <span class="heading3">{{ option.label | translate }}</span>
            </bng-button>
          </div>
        </div>
      </div>
    </div>`,
    link: function (scope, element, attrs) {
      //  IMPORTANT: It is on purpose, that there is no hook here. Do NOT add one.
      ConfirmationDialog._registerDir(setFn);

      function setFn (dialog, callback) {
        scope.$evalAsync(() => {
          scope.show = true;
          scope.dialog = dialog;
          scope.clicked = (val) => {
            scope.show = false;
            callback(val);
          };
        });
      }
    }
  }
})

;