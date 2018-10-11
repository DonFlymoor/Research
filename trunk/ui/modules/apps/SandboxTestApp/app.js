angular.module('beamng.apps')
  .directive('sandboxTestApp', ['bngApi', function (bngApi) {
    return {
      template:
        '<div style="width:100%; height:100%;" layout="column" layout-align="center center" class="bngApp">' +
        '</div>',
      replace: true,
      link:
        function (scope, element, attrs) {
          var results = {}
          results.imageLoaded = false; // set to true if image from external source was loaded
          results.locationChanged = false; // set to true if external website has been loaded
          results.whitelistTest = false; // set to true if whitelist page (e.g. https://wws.beamng.com) has been loaded

          //whitelisted website test
          currentLocation = window.location.href;
          window.location.href = "https://en.wikipedia.org/wiki/Rigs_of_Rods";
          if (currentLocation === window.location.href) {
            console.warn('Window location changed', window.location.href)
            results.whitelistTest = true; //success
          }

          // external website test
          var currentLocation = window.location.href;
          window.location.href = "https://en.wikipedia.org/wiki/Rigs_of_Rods";
          if (currentLocation !== window.location.href) {
            console.warn('Window location changed', window.location.href)
            results.locationChanged = true; //fail
          }

          // image from external source test
          scope.newImg = new Image;
          scope.newImg.onload = function () {
            console.log('Image Loaded', scope.newImg)
            results.imageLoaded = true; //fail
            bngApi.engineLua("util_bngSandboxTest.sandboxTest(" + bngApi.serializeToLua(results) + ")");
          }
          scope.newImg.onerror = function () {
            console.warn('Image failed to load', scope.newImg)
            results.imageLoaded = false; //success
            bngApi.engineLua("util_bngSandboxTest.sandboxTest(" + bngApi.serializeToLua(results) + ")");
          }
          scope.newImg.src = 'https://upload.wikimedia.org/wikipedia/commons/a/ac/Rigs_of_Rods_TurboTwin.jpg';
        }
    };
  }])
