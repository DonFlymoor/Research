angular.module('beamng.apps')
.directive('simplePedals', ['StreamsManager', function (StreamsManager) {
  return {
    template: 
        '<object class="bngApp" style="width:100%; height:100%; pointer-events: none" type="image/svg+xml" data="modules/apps/SimplePedals/simple-pedals.svg?t=' + Date.now() + '"/>',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      StreamsManager.add(['electrics']);

      scope.$on('$destroy', function () {
        StreamsManager.remove(['electrics']);
      });
      
      element.on('load', function () {
        var svg    = element[0].contentDocument
          , clutch   = { bar: svg.getElementById('filler0'), txt: svg.getElementById('txt0'), val: svg.getElementById('val0'), factor: svg.getElementById('container0').getAttribute('height') / 100.0 }
          , brake    = { bar: svg.getElementById('filler1'), txt: svg.getElementById('txt1'), val: svg.getElementById('val1'), factor: svg.getElementById('container1').getAttribute('height') / 100.0 }
          , throttle = { bar: svg.getElementById('filler2'), txt: svg.getElementById('txt2'), val: svg.getElementById('val2'), factor: svg.getElementById('container2').getAttribute('height') / 100.0 }
          , parking  = { bar: svg.getElementById('filler3'), txt: svg.getElementById('txt3'), val: svg.getElementById('val3'), factor: svg.getElementById('container3').getAttribute('height') / 100.0 }
        ;
        
        scope.$on('streamsUpdate', function (event, streams) {
          if (streams != null && streams.electrics != null) {              
              var clutchVal   = Math.round(streams.electrics.clutch * 100 + 0.49)
                , brakeVal    = Math.round(streams.electrics.brake * 100)
                , throttleVal = Math.round(streams.electrics.throttle * 100)
                , parkingVal  = Math.round(streams.electrics.parkingbrake * 100)
              ;

              clutch.val.innerHTML = clutchVal;
              brake.val.innerHTML = brakeVal;
              throttle.val.innerHTML = throttleVal;
              parking.val.innerHTML = parkingVal;

              clutch.txt.innerHTML = "clutch";
              brake.txt.innerHTML = "brake";
              throttle.txt.innerHTML = "throt";
              parking.txt.innerHTML = "p-brk";

              clutch.bar.setAttribute('height',   isNaN(clutchVal)   ? 0 : clutchVal * clutch.factor);
              brake.bar.setAttribute('height',    isNaN(brakeVal)    ? 0 : brakeVal * brake.factor);
              throttle.bar.setAttribute('height', isNaN(throttleVal) ? 0 : throttleVal * throttle.factor);
              parking.bar.setAttribute('height',  isNaN(parkingVal)  ? 0 : parkingVal * parking.factor);
          }
        });
      });
    }
  };
}]);
