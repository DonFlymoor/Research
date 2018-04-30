angular.module('beamng.stuff')

/**
 * @ngdoc controller
 * @name beamng.stuff.controller:TrackBuilderController
 * @description Track Builder controller
 */
.controller('TrackBuilderController', ['$scope', 'bngApi',
  function($scope, bngApi) {
        bngApi.engineLua("simpleSplineTrack =  require('util/simpleSplineTrack')");

    //size and direction of the current end tile
    // var currentSize = 3;
    var currentDir = 0;

    //marker values for the current tile
    var currentHeight = 0;
    var currentBank = 0;
    var currentWidth = 10;

    //lua index of current tile 
    var currentLuaIndex = 0;
    // number of track elements
    var trackElementCount = 1

    var currentPieceLua = "addCurve"

    $scope.selectedTrackElementData = null

    $scope.selectedBuildPieceIndex = 2

    $scope.clearedTrack = false

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
      }
    ]

    // for some reason you need to bind this to an object or else value doesnt update on checkbox...
    $scope.displayMarkers = {
      value: true
    }

    $scope.modifierValues = {
      bank: 0,
      elevate: 0,
      width: 10
    }

    $scope.quality = {
      value: false
    }

    $scope.trackPosition = {
      x: 0,
      y: 0,
      z: 0,
      hdg: 0

    }

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
      console.warn(index, $scope.pieceParameters[index]);
    }

    $scope.parameterReset = function(pIndex) {
      $scope.pieceParameters[$scope.selectedBuildPieceIndex].parameters[pIndex].value  =  $scope.pieceParameters[$scope.selectedBuildPieceIndex].parameters[pIndex].reset;
      $scope.parameterChanged(pIndex);

    }

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




    // Gets modifier value (bank, elevate, height etc) and then calls the required function
    $scope.modify = function(mode, value) {
      if(mode == "width" && value < 0) 
        value = 0;

      if(value != null)
        $scope.modifierValues[mode] = value;

      bngApi.engineLua(`simpleSplineTrack.${mode}(${value},${currentLuaIndex})`);
      refreshTrack();
      
    }




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

      bngApi.engineLua("simpleSplineTrack.focusMarkerOn("+currentLuaIndex+")"); 
      if(s != 0)       
        refreshInfo();
    };



    $scope.insert = function(before) {
      if(currentLuaIndex == 1 && before) 
        return;
      if(!before)
        addPieceAfter(currentLuaIndex+1)
      else
        addPieceAfter(currentLuaIndex)
      //$scope.select(1);
      refreshTrack(true);
    }

    $scope.build = function() {
      addPieceAfter(trackElementCount+1)
      refreshTrack();
    }

    $scope.removeTip = function() {
      bngApi.engineLua("simpleSplineTrack.revert()");
      refreshTrack();
    }

    $scope.removeSelected = function() {
      if(currentLuaIndex == trackElementCount) {
        $scope.removeTip();
        return;
      }
      if(currentLuaIndex == 1) 
        return;

      bngApi.engineLua("simpleSplineTrack.removeAt(" + currentLuaIndex + ")");
      refreshTrack(true);
    }

    refreshTrack = function(keepSelection) {
    
       //   bngApi.engineLua("simpleSplineTrack.elevate(" + currentHeight + ")");
       //   bngApi.engineLua("simpleSplineTrack.bank(" + currentBank + ")");
      
      bngApi.engineLua("simpleSplineTrack.makeTrack()");
      refreshInfo(keepSelection);
      
    }

    refreshInfo = function(keepSelection) {
       bngApi.engineLua("simpleSplineTrack.getPieceInfo(nil)", (allData) => {
        var data = allData.pieces;
        var selectLastElem = !keepSelection && (trackElementCount != data.length); //if the number of track elements changed, we want to select the last element.

        $scope.currentLuaIndex = allData.currentSelected
        $scope.displayMarkers.value = allData.showMarkers;      
        $scope.quality.value = allData.highQuality
        $scope.trackPosition = allData.trackPosition
        $scope.trackPosition.hdg = Math.round(-(allData.trackPosition.hdg/ Math.PI) * 18000) / 100;

        trackElementCount = data.length;

        $scope.modifierValues.bank = null;
        $scope.modifierValues.elevate = null;
        $scope.modifierValues.width = null;

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

 

    getSelectedTrackElementData = function() {
      bngApi.engineLua("simpleSplineTrack.getSelectedTrackInfo()", (data) => {
        $scope.selectedTrackElementData = data;
        if(data) {
          var nameToLookFor = ""
          var params = [];
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
        console.warn($scope.selectedTrackElementData);


    }




    replaceSelectedPiece = function() {
      if(currentLuaIndex == 1)
        return;
      var luaCode = "simpleSplineTrack.";
      var piece = $scope.pieceParameters[$scope.selectedBuildPieceIndex]
      luaCode += piece.function + "(";

      for(var i = 0; i<piece.parameters.length; i++) {
        luaCode += piece.parameters[i].value;
        if(i != piece.parameters.length-1)
          luaCode += ","
      }

      luaCode += "," + (currentLuaIndex)
      luaCode +=",true"
        
      luaCode += ")";
      console.warn("Replacing: " + luaCode);
      bngApi.engineLua(luaCode);
    }

    addPieceAfter = function(afterIndex) {

      var luaCode = "simpleSplineTrack.";
      var piece = $scope.pieceParameters[$scope.selectedBuildPieceIndex]
      luaCode += piece.function + "(";

      for(var i = 0; i<piece.parameters.length; i++) {
        luaCode += piece.parameters[i].value;
        if(i != piece.parameters.length-1)
          luaCode += ","
      }

      luaCode += "," + afterIndex   
      luaCode +=",false"
      luaCode += ")";
      console.warn(luaCode)
      bngApi.engineLua(luaCode);
    }

    $scope.showMarkers = function() {
      bngApi.engineLua("simpleSplineTrack.showMarkers(" + !$scope.displayMarkers.value + ")");
    }

    $scope.toggleQuality = function() {
      bngApi.engineLua("simpleSplineTrack.setHighQuality(" + !$scope.quality.value + ")");
      bngApi.engineLua("simpleSplineTrack.makeTrack(true)");
      refreshInfo(true);
    }
    /** saving and loading 
    *
    * call simpleSplineTrack.save("nameOfTrack") to save a file.
    * call simpleSplineTrack.load("nameOfTrack") to load a file.
    * call simpleSplineTrack.rename("old", "new") to rename a file.
    * call simpleSplineTrack.getCustomTracks() to get a list of all tracks (as an array)
    *
    *
    **/

    $scope.save = function(saveName) {
      bngApi.engineLua(`simpleSplineTrack.save(${bngApi.serializeToLua(saveName)})`);
      bngApi.engineLua("simpleSplineTrack.getCustomTracks()", (data) => {
        $scope.tracks = data;
      });
    }

    $scope.load = function(trackName) {
      bngApi.engineLua(`simpleSplineTrack.load(${bngApi.serializeToLua(trackName)})`);
      refreshInfo();
    }

    bngApi.engineLua("simpleSplineTrack.getCustomTracks()", (data) => {
      $scope.tracks = data;
    });
   
    //Stacking
    $scope.stackCount = 0;

    $scope.stack = function(count) {
      if(count == 1)
        bngApi.engineLua("simpleSplineTrack.stack(1)");
      else
        bngApi.engineLua("simpleSplineTrack.applyStack(1)");
      refreshTrack();
      getStackCount();
    }

    $scope.stackToCursor = function() {
      bngApi.engineLua("simpleSplineTrack.stackToCursor()");
      refreshTrack();
      getStackCount();
    }

    $scope.stackApplyAll = function(keep) {
      bngApi.engineLua("simpleSplineTrack.applyStack(99999,"+keep+")");
      refreshTrack();
      getStackCount();
    }

    $scope.clearStack = function() {
      bngApi.engineLua("simpleSplineTrack.clearStack()");
      getStackCount(); 
    }
    getStackCount = function() {
      bngApi.engineLua("simpleSplineTrack.getStackCount()", (data) => {
        $scope.stackCount = data;
      });
    }


    $scope.setTrackPosition = function() {
      bngApi.engineLua("simpleSplineTrack.setTrackPosition(" + $scope.trackPosition.x + "," + $scope.trackPosition.y + "," +$scope.trackPosition.z + "," +$scope.trackPosition.hdg + ")" );
      bngApi.engineLua("simpleSplineTrack.makeTrack(true)");
      refreshInfo(true);

    }

    $scope.drive = function() {

      if(!$scope.quality.value) {
        $scope.quality.value = true;
        bngApi.engineLua("simpleSplineTrack.setHighQuality(true)");
        bngApi.engineLua("simpleSplineTrack.makeTrack(true)");
      }
      bngApi.engineLua("simpleSplineTrack.showMarkers(false)");

      bngApi.engineLua("simpleSplineTrack.positionVehicle()");
      $scope.displayMarkers.value = false;

    }

    $scope.clearTrack = function() {
      bngApi.engineLua("simpleSplineTrack.removeTrack()");
      bngApi.engineLua("simpleSplineTrack.unloadAll()");
      $scope.clearedTrack = true;
    }
    $scope.clearedTrack = false
    refreshTrack();
    refreshInfo();
    getStackCount();
    // bngApi.engineLua("simpleSplineTrack.forward(1)");    
  
  }
]);
