angular.module('beamng.apps')
.directive('campaignDebug', ['StreamsManager', 'InstalledContent', 'Vehicles', '$q', 'bngApi', function (StreamsManager, InstalledContent, Vehicles, $q, bngApi) {
  return {
    templateUrl: 'modules/apps/CampaignDebug/app.html',
    replace: true,
    link: function (scope, element, attrs) {
      var vm = this;
      var streamsList = ['sensors'];
      StreamsManager.add(streamsList);
      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList);
      });

      scope.model = '';
      scope.config = '';
      scope.money = 0;

      scope.$on('simpleVehicleList', (ev, data) => {
        scope.data = {};
        for (var key in data) {
          scope.data[data[key].key] = data[key];
        }
      });

      scope.toggleTeleportation = function(value) {
        bngApi.engineLua(`require('input_action_filter').clear(${value})`);
      }

      scope.addFunds = function(value) {
        bngApi.engineLua(`core_inventory.addItem("$$$_MONEY", ${value})`);
        scope.money = 0;
      }

      scope.removeFunds = function(value) {
        bngApi.engineLua(`core_inventory.removeItem("$$$_MONEY", ${value})`);
        scope.money = 0;
      }

      scope.completeScenario = function(state, medal) {
        if (state === 'success') {
          bngApi.engineLua(`statistics_statistics.stopStatsGathering_orginal = statistics_statistics.stopStatsGathering

                            statistics_statistics.stopStatsGathering = function(scenario)
                              statistics_statistics.stopStatsGathering_orginal(scenario)
                              statistics_statistics.DEBUG_generateScoreForMedal('${medal}')
                            end
                            scenario_scenarios.finish({msg = 'success'})
                            statistics_statistics.stopStatsGathering = statistics_statistics.stopStatsGathering_orginal
                            statistics_statistics.stopStatsGathering_orginal = nil
                          `);
        }
        else {
          bngApi.engineLua(`scenario_scenarios.finish({failed = 'fail'})`);
        }
      }

      scope.addVehicle = function(mode, model, config) {
        if (mode === 'spawn') {
          var luaArgs = {};
          luaArgs.config = config.key;
          bngApi.engineLua('core_vehicles.replaceVehicle("' + model.key + '", ' + bngApi.serializeToLua(luaArgs) + ')');
        }
        else if (mode === 'garage') {
          bngApi.engineLua(`core_inventory.addItem("$$$_VEHICLES", {model=`+ bngApi.serializeToLua(model.key) +`, config=`+ bngApi.serializeToLua(config.key) +`, color='1 1 1 1'})`);
        }
        else {
          bngApi.engineLua(`campaign_dealer.addToStock("$$$_VEHICLES", {model=`+ bngApi.serializeToLua(model.key) +`, config=`+ bngApi.serializeToLua(config.key) +`})`);
        }
      }

      bngApi.engineLua('core_vehicles.requestSimpleVehicleList()');

    }
  };
}]);