(function() {
  'use strict';

  angular.module('beamng.stuff')




  /**
   * @ngdoc controller
   * @name beamng.stuff:ScenarioSelectController
   * @description Controller for the scenario selection view
  **/
  .controller('CampaignSelectController', ['$filter', 'logger', '$scope', '$state', '$interval', 'bngApi', 'Aux',
    function($filter, logger, $scope, $state, $interval, bngApi, Aux) {

    var availableCampaigns = [];
    $scope.filtered = [];
    $scope.selected = null;
    $scope.query = '';

    $scope.tilesOrder = [
      {label: 'ui.common.order.difficulty', key: 'difficulty'},
      {label: 'ui.common.order.date',       key: '-date'},
      {label: 'ui.common.order.author',     key: 'authors'},
      {label: 'ui.common.order.players',    key: '-maxPlayers'},
    ];

    $scope.selectedOrder = $scope.tilesOrder[0].key;

    bngApi.engineLua('campaign_campaignsLoader.getList()', function(res) {
      $scope.filtered = [];
      // logger.debug('[CampaignSelectController] got scenarios', JSON.stringify(res, null, '  '));
      // logger.debug('[CampaignSelectController] got scenarios %o', res);
      for (var i = 0; i < res.length; i++) {
        res[i].__displayName__ = $filter('translate')(res[i].title);

        if (res[i].previews && res[i].previews.length > 0) {
          res[i].preview = res[i].previews[0];
          res[i].preImgIndex = 0;
          res[i].maxPlayers = 0;
          for (var j in res[i].vehicles) {
              var v = res[i].vehicles[j];
              if (v.playerUsable == true) res[i].maxPlayers++;
              if (v.driver && v.driver.player == true) res[i].maxPlayers++;
          }
          if (res[i].playersCountRange) res[i].maxPlayers = res[i].playersCountRange.max;
          res[i].minPlayers = res[i].maxPlayers;
          if (res[i].playersCountRange) res[i].minPlayers = res[i].playersCountRange.min;
        }
      }

      availableCampaigns = res;

      $scope.$watchGroup(['query', 'selectedOrder'], function (value) {
        var temp = $filter('filter')(availableCampaigns, {__displayName__: value[0]});
        temp = $filter('orderBy')(temp, [value[1], 'name']);
        $scope.filtered = temp;
        $scope.selected = $scope.filtered[0];
      });

      $scope.$digest(); // trigger the $watchGroup
    });


    // TODO: select the first entry of the filtered list always

    $scope.difText = function (num) {
      var val = ['Easy', 'Medium', 'Hard', 'Very Hard'];
      return val[Math.floor(parseFloat(num)/25)];
    }

    $scope.openRepo = function () {
      window.location.href = 'http-external://www.beamng.com/resources/categories/scenario_scenarios.8/?ingame=2';
    };

    $scope.selectCampaign = function(campaign) {
      $scope.selected = campaign;
    };

    $scope.startCampaign = function(campaign) {
      var luaCmd = 'campaign_campaignsLoader.start(' + bngApi.serializeToLua(campaign) + ')';
      $scope.$emit('CloseMenu');
      bngApi.engineLua(luaCmd);
    };

  }]);

}());
