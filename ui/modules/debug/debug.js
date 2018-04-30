angular.module('beamng.stuff')

.factory('DebugViewControls', ['Debug', function (Debug) {
  return {
    vehicle: {
      buttonGroup_1: [
        { label: 'ui.debug.vehicle.loadDefault', action: Debug.vehicles.loadDefault },
        { label: 'ui.debug.vehicle.spawnNew',        action: Debug.vehicles.spawnNew },
        { label: 'ui.debug.vehicle.removeCurrent',   action: Debug.vehicles.removeCurrent },
        { label: 'ui.debug.vehicle.cloneCurrent',   action: Debug.vehicles.cloneCurrent },
        { label: 'ui.debug.vehicle.removeAll',       action: Debug.vehicles.removeAll },
        { label: 'ui.debug.vehicle.removeOthers', action: Debug.vehicles.removeOthers },
        { label: 'ui.debug.vehicle.resetAll',        action: Debug.vehicles.resetAll },
        { label: 'ui.debug.vehicle.reloadAll',       action: Debug.vehicles.reloadAll }
      ],

      toggleGroup_1: [
        { label: 'ui.debug.activatePhysics', key: 'physicsEnabled', onChange: () => { Debug.togglePhysics(Debug.state.physicsEnabled); } }
      ],
    },

    terrain: {
      toggleGroup_1: [
        { label: 'ui.debug.terrain.staticCollision', key: 'staticCollision', onChange: () => { Debug.toggleStaticCollision(Debug.state.terrain.staticCollision); } },
        { label: 'ui.debug.terrain.groundmodel',     key: 'groundmodel',     onChange: () => { Debug.toggleTerrainCollision(Debug.state.terrain.groundmodel);    } }
      ]
    },

    renderer: {
      toggleGroup_1: [
        { label: 'ui.debug.renderer.boundingBoxes',  key: 'boundingboxes',  onChange: () => { Debug.toggleBoundingBoxes(Debug.state.renderer.boundingboxes);    } },
        { label: 'ui.debug.renderer.disableShadows', key: 'disableShadows', onChange: () => { Debug.toggleShadowsDisabled(Debug.state.renderer.disableShadows); } },
        { label: 'ui.debug.renderer.wireframeMode',  key: 'wireframe',      onChange: () => { Debug.toggleWireframe(Debug.state.renderer.wireframe);            } }
      ],

      buttonGroup_1: [
        { label: 'ui.debug.renderer.toggleFps', action: Debug.toggleFps }
      ]
    },

    effects: {
      buttonGroup_1: [
        { label: 'ui.debug.effects.toggleFreeCamera', action: Debug.toggleFreeCamera }
      ]
    }
  }
}])


.controller('DebugController', ['$scope', 'bngApi', 'Debug', 'DebugViewControls',
function ($scope, bngApi, Debug, DebugViewControls) {
  Debug.registerScope($scope, () => { $scope.$evalAsync(); });
  Debug.update();

  var vm = this;
  vm.service = Debug;
  vm.controls = DebugViewControls;
  vm.disableVehicleButtons = false;

  $scope.$on('GameStateUpdate', (_, gamestate) => {
    vm.disableVehicleButtons = gamestate.state.toLowerCase().indexOf('scenario') !== -1;
  });

  bngApi.engineLua('core_gamestate.requestGameState();');
}]);