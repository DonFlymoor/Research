angular.module('beamng.stuff')

.value('ScenarioSelect', {order: '', query: ''})

/**
 * @ngdoc controller
 * @name beamng.stuff:ScenarioSelectController
 * @description Controller for the scenario selection view
**/
.controller('ScenarioSelectController', ['$filter', 'logger', '$scope', '$state', '$interval', 'bngApi', 'Aux', 'ScenarioSelect',
  function ScenarioSelectController ($filter, logger, $scope, $state, $interval, bngApi, Aux, ScenarioSelect) {

  var availableScenarios = [];
  $scope.filtered = [];
  $scope.selected = null;

  $scope.tilesOrder = [
    {label: 'ui.common.order.date',       key: '-date'},
    {label: 'ui.common.order.difficulty', key: 'difficulty'},
    {label: 'ui.common.order.author',     key: 'authors'},
    {label: 'ui.common.order.players',    key: '-maxPlayers'},
  ];

  function goalIcon (goal) {
    switch (goal) {
      case 'damage':
        return {tooltip: 'ui.goals.damage', icon:''};
      case 'distance':
        return {tooltip: 'ui.goals.distance', icon:''};
      case 'drift':
        return {tooltip: '', icon:''};
      case 'finishRace':
        return {tooltip: 'ui.goals.finishRace', icon:''};
      case 'nomove':
        return {tooltip: 'ui.goals.nomove', icon:''};
      case 'position':
        return {tooltip: 'ui.goals.position', icon:''};
      case 'speed':
        return {tooltip: 'ui.goals.speed', icon:''};
      default:
        return {tooltip: goal, icon:''};
    };
  }

  if (ScenarioSelect.order !== '') {
    $scope.selectedOrder = ScenarioSelect.order;
  } else {
    $scope.selectedOrder = $scope.tilesOrder[0].key;
  }
  $scope.query = ScenarioSelect.query;

  bngApi.engineLua('scenario_scenariosLoader.getList()', function(res) {
    $scope.filtered = [];
    // logger.debug('[ScenarioSelectController] got scenarios %o', res);
    for (var i = 0; i < res.length; i++) {
      if (res[i].previews && res[i].previews.length > 0) {
        res[i].preview = res[i].previews[0];
        res[i].preImgIndex = 0;
        res[i].maxPlayers = 0;

        for (var j in res[i].vehicles) {
          var v = res[i].vehicles[j];
          if (v.playerUsable == true) res[i].maxPlayers++;
          if (v.driver && v.driver.player == true) res[i].maxPlayers++;

          if (v.goal) {
            if (res[i].goals === undefined) {
              res[i].goals = {};
            }

            for (var goal in v.goal) {
              // todo: wayPointAction should never have been listed as goal. restructure
              if (res[i].goals[goal] === undefined && goal !== 'wayPointAction') {
                res[i].goals[goal] = goalIcon(goal);
              }
            }
          }
        }

        if (res[i].playersCountRange) res[i].maxPlayers = res[i].playersCountRange.max;
        res[i].minPlayers = res[i].maxPlayers;
        if (res[i].playersCountRange) res[i].minPlayers = res[i].playersCountRange.min;
        res[i].displayName = $filter('translate')(res[i].name);

      }
    }

    availableScenarios = res;

    $scope.$watchGroup(['query', 'selectedOrder'], function (value) {
      var temp = $filter('filter')(availableScenarios, {displayName: value[0]});
      temp = $filter('orderBy')(temp, [value[1], 'name']);
      $scope.filtered = temp;
      $scope.selected = $scope.filtered[0];
    });

    $scope.$digest(); // trigger the $watchGroup
  });


  // TODO: select the first entry of the filtered list always
  var selectedTimer = 0;//Timer to make previews one by one in a certain duration


  function changePreview() {
    $scope.selected.preImgIndex++;
    if ($scope.selected.preImgIndex > $scope.selected.previews.length - 1) {
      $scope.selected.preImgIndex = 0;
    }
    $scope.selected.preview = $scope.selected.previews[$scope.selected.preImgIndex];
  }

  $scope.difText = function (num) {
    var val = ['Easy', 'Medium', 'Hard', 'Very Hard'];
    return val[Math.floor(parseFloat(num)/25)];
  }

  $scope.openRepo = function () {
    window.location.href = 'http-external://www.beamng.com/resources/categories/scenario_scenarios.8/?ingame=2';
  };

  $scope.selectScenario = function(scenario) {
    $interval.cancel(selectedTimer);
    $scope.selected = scenario;
    $scope.selected.multiseat = {context: {minPlayers: scenario.minPlayers, maxPlayers: scenario.maxPlayers}};

    if (!$scope.selected.previews) {
      $scope.selected.preview = null;
      return;
    }
    $scope.selected.preview = $scope.selected.previews[$scope.selected.preImgIndex];
    if ($scope.selected.previews.length > 1) {
      selectedTimer = $interval(changePreview, 3000);
    }
  };

  $scope.startScenario = function(scenario) {
    var luaCmd = 'scenario_scenariosLoader.start(' + bngApi.serializeToLua(scenario) + ')';
    $scope.$emit('CloseMenu');
    bngApi.engineLua(luaCmd);
  };

  $scope.$on('$destroy', function () {
    ScenarioSelect.order = $scope.selectedOrder;
    ScenarioSelect.query = $scope.query;
  });

}]);
