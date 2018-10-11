angular.module('beamng.stuff')

/**
 * @ngdoc controller
 * @name beamng.stuff.controller:TrackBuilderController
 * @description Track Builder controller
 */
.controller('TrackBuilderController', ['$scope', 'bngApi',
  function($scope, bngApi) {
    bngApi.engineLua("extensions.load('util_simpleSplineTrack')");

    //lua index of current tile 
    var currentLuaIndex = 0;
    // number of track elements
    var trackElementCount = 1
    //holds the name of the function of the current piece
    var currentPieceLua = "addCurve"

    //Stacking
    $scope.stackCount = 0;

    //holds the infos of the currently selected piece as it comes from the lua side
    $scope.selectedTrackElementData = null

    //index of currently selected piece
    $scope.selectedBuildPieceIndex = 2

    //wether or not the track is currently closed
    $scope.trackClosed = false;

    //whether the track has been cleared (and thus the interface should not be interactable)
    $scope.clearedTrack = false

    //info for the pieces you can build
    $scope.pieceParameters = [
      {
        parameters: [
          {
            value: 3,
            name: "Radius",
            show: true,
            min: 1,
            type: "number",
            reset: 3
          },{
            value: 0,
            name: "Easing",
            show: true,
            min: -3,
            max: 3,
            type: "number",
            reset: 0
          },

          {
            value:-1
          }
        ],
        function: "addCurve",
        icon: "trackgenerator_left_curve",
        tooltip: "ui.trackBuilder.leftTurn",
        name: 'leftCurve'
      },
      {
        parameters: [
          {
            value: 3,
            name: "Radius",
            show: true,
            type: "number",
            min: 1,
            reset: 3
          },{
            name: 'Ease In',
            value: true,
            show: true,
            type: "checkbox"
          },{
            value:-1
          }
        ],
        function: "addSpiral",
        icon: "trackgenerator_left_ease_curve",
        tooltip: "ui.trackBuilder.easeLeft",
        name: 'leftEase'
      },
      {
        parameters: [
          {
            value: 3,
            name: "Length",
            show: true,
            min: 1,
            type: "number",
            reset: 3
          }
        ],
        function: "addForward",
        icon: "trackgenerator_forward",
        tooltip: "ui.trackBuilder.forward",
        name: 'forward'
      },
      {
        parameters: [
          {
            value: 3,
            name: "Radius",
            show: true,
            type: "number",
            min: 1,
            reset: 3
          },{
            name: 'Ease In',
            value: true,
            show: true,
            type: "checkbox"
          },{
            value:1
          }
        ],
        function: "addSpiral",
        icon: "trackgenerator_right_ease_curve",
        tooltip: "ui.trackBuilder.easeRight",
        name: 'rightEase'
      },
      {
        parameters: [
          {
            value: 3,
            name: "Radius",
            show: true,
            min: 1,
            type: "number",
            reset: 3
          },{
            value: 0,
            name: "Easing",
            show: true,
            min: -3,
            max: 3,
            type: "number",
            reset: 0
          },
          {
            value:1
          }
        ],
        function: "addCurve",
        icon: "trackgenerator_right_curve",
        tooltip: "ui.trackBuilder.rightTurn",
        name: 'rightCurve'
      },
      {
        parameters: [
          {
            value: 6,
            name: "Length",
            show: true,
            min: 1,
            type: "number",
            reset: 6

          },
          {
            value: 2,
            name: "Offset",
            show: true,
            type: "number",
            reset: 2
          },
          {
            value: 0,
            name: "Hardness",
            show: true,
            min: -4,
            max: 10,
            type: "number",
            reset: 0
          },
        ],
        function: "addOffsetCurve",
        icon: "trackgenerator_s_curve",
        tooltip: "ui.trackBuilder.offsetCurve",
        name: 'offsetCurve'
      },
      {
        parameters: [
          {
            value: 10,
            name: "Radius",
            show: true,
            min: 6,
            type: "number",
            reset: 6
          },
          {
            value: 2,
            name: "Offset",
            show: true,
            type: "number",
            reset: 2
          }
        ],
        function: "addLoop",
        icon:"trackgenerator_loop",
        tooltip: "ui.trackBuilder.loop",
        name: 'loop'
      },
      {
        parameters: [
          {
            value: 0,
            name: "X Offset",
            show: true,
            type: "number",
            reset: 0
          },{
            value: 2,
            name: "Y Offset",
            show: true,
            type: "number",
            reset: 2
          },{
            value: 0,
            name: "Height Offset",
            show: true,
            type: "number",
            reset: 0
          },{
            value: 0,
            name: "Direction Offset",
            show: true,
            min: -3,
            max: 3,
            type: "number",
            reset: 0
          },{
            name: 'Absolute',
            value: false,
            show: true,
            type: "checkbox"
          }
        ],
        function: "addEmptyOffset",
        icon:"material_linear_scale",
        tooltip: "ui.trackBuilder.emptyPiece",
        name: 'emptyOffset'
      }
    ]

    //wether markers are shown or not
    $scope.displayMarkers = {
      value: true
    }

    //values for the different modifiers
    $scope.modifierValues = {
      bank: 0,
      elevate: 0,
      width: 10
    }

    //wether or not the track is high quality
    $scope.quality = {
      value: false
    }

    //position of the track (hdg is in deg, in lua it is in radians)
    $scope.trackPosition = {
      x: 0,
      y: 0,
      z: 0,
      hdg: 0
    }

    //default laps when saving a track
    $scope.defaultLaps = {
      value: 2
    }

    // wether or not the track can be reversed
    $scope.reversible = {
      value: false
    }

    

    //selects a buildable piece by its index, builds/replaces it depending on previously selected piece
    $scope.selectPiece = function(index) {
      if($scope.selectedBuildPieceIndex == index) {
        if(currentLuaIndex == trackElementCount)
          $scope.build();
      } else {
        $scope.selectedBuildPieceIndex = index;
        replaceSelectedPiece();
        refreshTrack(true);
      }
      $scope.selectedBuildPieceIndex = index;
    }

    //resets the parameter given by index of the currently selected piece to its default value
    $scope.parameterReset = function(pIndex) {
      $scope.pieceParameters[$scope.selectedBuildPieceIndex].parameters[pIndex].value  =  $scope.pieceParameters[$scope.selectedBuildPieceIndex].parameters[pIndex].reset;
      $scope.parameterChanged(pIndex);
    }

    //after a parameter is changed (by index), checks bounds and updates track
    $scope.parameterChanged = function(pIndex) {
      var piece = $scope.pieceParameters[$scope.selectedBuildPieceIndex]
      if(piece.parameters[pIndex].min)
        if(piece.parameters[pIndex].value < piece.parameters[pIndex].min)
          piece.parameters[pIndex].value = piece.parameters[pIndex].min;

      if(piece.parameters[pIndex].max)
        if(piece.parameters[pIndex].value > piece.parameters[pIndex].max)
          piece.parameters[pIndex].value = piece.parameters[pIndex].max;

      //some hacking to make the curves and straight pieces have the same parameter
      if($scope.selectedBuildPieceIndex <= 4) {
        if(pIndex == 0)
          for(var i = 0; i< 5; i++) 
              $scope.pieceParameters[i].parameters[pIndex].value = piece.parameters[pIndex].value;  
      }

      if(pIndex == 1 && ($scope.selectedBuildPieceIndex == 1 || $scope.selectedBuildPieceIndex == 3)) {
        $scope.pieceParameters[1].parameters[1].value = piece.parameters[1].value;  
        $scope.pieceParameters[3].parameters[1].value = piece.parameters[1].value;  
      }

      replaceSelectedPiece();
      refreshTrack(true);
    }

    // sets modifier value (bank, elevate, height etc) and then calls the required function
    $scope.modify = function(mode, value) {
      if(mode == "width" && value < 0) 
        value = 0;
      if(mode == "width" && value > 50) 
        value = 50;

      if(value != null)
        $scope.modifierValues[mode] = value;

      bngApi.engineLua(`extensions.util_simpleSplineTrack.${mode}(${value},${currentLuaIndex})`);
      refreshTrack();
      
    }

    //selects an already build piece by its index
    $scope.select = function(s) { 
      currentLuaIndex += s;
      if (currentLuaIndex < 1) {
        if (currentLuaIndex == 0)
          currentLuaIndex = trackElementCount;  
        else
          currentLuaIndex = 1;
      }
      if(currentLuaIndex > trackElementCount){
        if (currentLuaIndex == trackElementCount+1)
          currentLuaIndex = 1;
        else
          currentLuaIndex = trackElementCount;
      }

      bngApi.engineLua("extensions.util_simpleSplineTrack.focusMarkerOn("+currentLuaIndex+")"); 
      if(s != 0)       
        refreshInfo();
    };

    //builds a piece at the currently selected index.
    $scope.insert = function() {
      addPieceAfter(currentLuaIndex+1)
      refreshTrack(true);
    }
    //builds a piece at the end of the track.
    $scope.build = function() {
      addPieceAfter(trackElementCount+1)
      refreshTrack();
    }
    //removes the last piece of the track.
    $scope.removeTip = function() {
      bngApi.engineLua("extensions.util_simpleSplineTrack.revert()");
      refreshTrack();
    }
    //removes the selected element of the track.
    $scope.removeSelected = function() {
      if(currentLuaIndex == trackElementCount) {
        $scope.removeTip();
        return;
      }
      if(currentLuaIndex == 1) 
        return;
      bngApi.engineLua("extensions.util_simpleSplineTrack.removeAt(" + currentLuaIndex + ")");
      refreshTrack(true);
    }

    //calls the re-building function of the track builder, then gets the updated info.
    refreshTrack = function(keepSelection) {
      bngApi.engineLua("extensions.util_simpleSplineTrack.makeTrack()");
      refreshInfo(keepSelection);
    }

    //gets the info of the track, like element count, marker info etc.
    refreshInfo = function(keepSelection) {
       bngApi.engineLua("extensions.util_simpleSplineTrack.getPieceInfo(nil)", (allData) => {
        var data = allData.pieces;
        var selectLastElem = !keepSelection && (trackElementCount != data.length); //if the number of track elements changed, we want to select the last element.

        $scope.currentLuaIndex = allData.currentSelected
        $scope.displayMarkers.value = allData.showMarkers;      
        $scope.quality.value = allData.highQuality
        $scope.trackPosition = allData.trackPosition
        $scope.trackPosition.hdg = Math.round(-(allData.trackPosition.hdg/ Math.PI) * 18000) / 100;

        trackElementCount = data.length;
        $scope.trackClosed = allData.trackClosed;
        $scope.defaultLaps.value = allData.defaultLaps;
        $scope.reversible.value = allData.reversible;

        $scope.modifierValues.bank = null;
        $scope.modifierValues.elevate = null;
        $scope.modifierValues.width = null;

        //sets the marker values to the first marker before the selection
        for(var i = data.length-1; i>=0; i--) {
          if(i <= currentLuaIndex-1) {
            if($scope.modifierValues.elevate == null)
              $scope.modifierValues.elevate = data[i].height;
            if($scope.modifierValues.bank == null)
              $scope.modifierValues.bank = data[i].bank;
            if($scope.modifierValues.width == null) {
              $scope.modifierValues.width = data[i].width
            }
          }
        }

        if(selectLastElem) 
          $scope.select(10000);
        else
          $scope.select(0);  
      });
      getSelectedTrackElementData();
    }

    //gets the info for the currently selected track piece.
    getSelectedTrackElementData = function() {
      bngApi.engineLua("extensions.util_simpleSplineTrack.getSelectedTrackInfo()", (data) => {
        $scope.selectedTrackElementData = data;
        if(data) {
          var nameToLookFor = ""
          var params = [];
          if(data.parameters && data.parameters.piece) {
            if(data.parameters.piece == "curve") {
              nameToLookFor = (data.parameters.direction == -1? "left" : "right") + "Curve";
              params = [data.parameters.length, data.parameters.hardness, data.parameters.direction]
            } else if(data.parameters.piece == "spiral") {
              nameToLookFor = (data.parameters.direction == -1? "left" : "right") + "Ease";
              params = [data.parameters.size, data.parameters.inside, data.parameters.direction]
            } else if(data.parameters.piece == "forward") {
              nameToLookFor = "forward"
              params = [data.parameters.length]
            } else if(data.parameters.piece == "loop") {
              nameToLookFor = "loop";
              params = [data.parameters.radius, data.parameters.xOffset]
            } else if(data.parameters.piece == "offsetCurve") {
              nameToLookFor = "offsetCurve"
              params = [data.parameters.length, data.parameters.xOffset, data.parameters.hardness]
            } else if(data.parameters.piece == "emptyOffset") {
              nameToLookFor = "emptyOffset"
              params = [data.parameters.xOff, data.parameters.yOff, data.parameters.zOff, data.parameters.dirOff]
            }
          }

          var parameterIndex = -1
          for(var i = 0; i< $scope.pieceParameters.length; i++)
            if($scope.pieceParameters[i].name == nameToLookFor) {
              parameterIndex = i;
              break;
            }
          if(parameterIndex == -1) {
             $scope.selectedTrackElementData = null;
             return;
          }
          $scope.selectedTrackElementData.parameterIndex = parameterIndex;
          if($scope.selectedBuildPieceIndex != parameterIndex) {
             $scope.selectedBuildPieceIndex = parameterIndex;
          }
          for(var j = 0; j< params.length; j++)
          $scope.pieceParameters[i].parameters[j].value = params[j]
        }
      });
    }
    //replaces the current piece of the track with a new piece 
    replaceSelectedPiece = function() {
      if(currentLuaIndex == 1)
        return;
      var luaCode = "extensions.util_simpleSplineTrack.";
      var piece = $scope.pieceParameters[$scope.selectedBuildPieceIndex];
      luaCode += piece.function + "(";

      for(var i = 0; i<piece.parameters.length; i++) {
        luaCode += piece.parameters[i].value;
        if(i != piece.parameters.length-1)
          luaCode += ",";
      }

      luaCode += "," + (currentLuaIndex);
      luaCode +=",true";
      luaCode += ")";
      bngApi.engineLua(luaCode);
    }

    //adds a new piece after a given index.
    addPieceAfter = function(afterIndex) {
      var luaCode = "extensions.util_simpleSplineTrack.";
      var piece = $scope.pieceParameters[$scope.selectedBuildPieceIndex]
      luaCode += piece.function + "(";

      for(var i = 0; i<piece.parameters.length; i++) {
        luaCode += piece.parameters[i].value;
        if(i != piece.parameters.length-1)
          luaCode += ",";
      }

      luaCode += "," + afterIndex;
      luaCode +=",false";
      luaCode += ")";
      bngApi.engineLua(luaCode);
    }
    //shows or hides the markers
    $scope.showMarkers = function() {
      bngApi.engineLua("extensions.util_simpleSplineTrack.showMarkers(" + !$scope.displayMarkers.value + ")");
      if($scope.displayMarkers.value)
        bngApi.engineLua("extensions.util_simpleSplineTrack.setAllPiecesToAsphalt()");
    }

    //sets high or low quality.
    $scope.toggleQuality = function() {
      bngApi.engineLua("extensions.util_simpleSplineTrack.setHighQuality(" + !$scope.quality.value + ")");
      bngApi.engineLua("extensions.util_simpleSplineTrack.makeTrack()");
      refreshInfo(true);
    }

    //saves or overwrites the track under a given name
    $scope.save = function(saveName) {
      bngApi.engineLua(`extensions.util_simpleSplineTrack.save(${bngApi.serializeToLua(saveName)})`);
      bngApi.engineLua("extensions.util_simpleSplineTrack.getCustomTracks()", (data) => {
        $scope.tracks = data;
      });
    }

    $scope.setDefaultLaps = function() {
      if($scope.defaultLaps.value < 1)
        $scope.defaultLaps.value = 1;
      bngApi.engineLua(`extensions.util_simpleSplineTrack.setDefaultLaps(${$scope.defaultLaps.value})`);
      refreshInfo(true);
    }

    $scope.setReversible = function() {
      bngApi.engineLua(`extensions.util_simpleSplineTrack.setReversible(${$scope.reversible.value})`);
      refreshInfo(true);
    }

    //loads a track by name
    $scope.load = function(trackName) {
      bngApi.engineLua(`extensions.util_simpleSplineTrack.load(${bngApi.serializeToLua(trackName)})`);
      refreshInfo();
    }

    //puts a number of pieces on the stack
    $scope.stack = function(count) {
      if(count == 1)
        bngApi.engineLua("extensions.util_simpleSplineTrack.stack(1)");
      else
        bngApi.engineLua("extensions.util_simpleSplineTrackeSplineTrack.applyStack(1)");
      refreshTrack();
      getStackCount();
    }

    //stacks all the pieces up to the cursor.
    $scope.stackToCursor = function() {
      bngApi.engineLua("extensions.util_simpleSplineTrack.stackToCursor()");
      refreshTrack();
      getStackCount();
    }

    //applies all pieces on the stack
    $scope.stackApplyAll = function(keep) {
      bngApi.engineLua("extensions.util_simpleSplineTrack.applyStack(99999,"+keep+")");
      refreshTrack();
      getStackCount();
    }

    //clears the stack.
    $scope.clearStack = function() {
      bngApi.engineLua("extensions.util_simpleSplineTrack.clearStack()");
      getStackCount(); 
    }

    //gets how many pieces currently are on the stack from lua.
    getStackCount = function() {
      bngApi.engineLua("extensions.util_simpleSplineTrack.getStackCount()", (data) => {
        $scope.stackCount = data;
      });
    }

    //sets the track position and rotation, then re-makes the track.
    $scope.setTrackPosition = function() {
      bngApi.engineLua("extensions.util_simpleSplineTrack.setTrackPosition(" + $scope.trackPosition.x + "," + $scope.trackPosition.y + "," +$scope.trackPosition.z + "," +$scope.trackPosition.hdg + ")" );
      bngApi.engineLua("extensions.util_simpleSplineTrack.makeTrack()");
      refreshInfo(true);
    }

    // Calls a function, then makes track and refreshes info.
    $scope.callMakeRefresh = function(functionToCall) {
      bngApi.engineLua("extensions.util_simpleSplineTrack."+functionToCall+"()" );
      bngApi.engineLua("extensions.util_simpleSplineTrack.makeTrack()");
      refreshInfo(true);
    }

    //sets high quality, hides markers and places the currentl vehicle on the track start.
    $scope.drive = function() {
      //if(!$scope.quality.value) {
        $scope.quality.value = true;
        bngApi.engineLua("extensions.util_simpleSplineTrack.setHighQuality(true)");
        bngApi.engineLua("extensions.util_simpleSplineTrack.makeTrack(true)");
    //  }
      bngApi.engineLua("extensions.util_simpleSplineTrack.showMarkers(false)");
      bngApi.engineLua("extensions.util_simpleSplineTrack.setAllPiecesToAsphalt()");
      bngApi.engineLua("extensions.util_simpleSplineTrack.positionVehicle()");
      $scope.displayMarkers.value = false;

    }

    //removes the whole track, disables the track builder UI.
    $scope.clearTrack = function() {
      bngApi.engineLua("extensions.util_simpleSplineTrack.removeTrack()");
      bngApi.engineLua("extensions.util_simpleSplineTrack.unloadAll()");
      $scope.clearedTrack = true;
    }

    //whenever the app is started:
    //un-clear the track (enable UI)
    $scope.clearedTrack = false
    refreshTrack();
    refreshInfo();
    getStackCount();
     //getting the tracks when the app is loaded.
    bngApi.engineLua("extensions.util_simpleSplineTrack.getCustomTracks()", (data) => {
      $scope.tracks = data;
    });
  }
]);
