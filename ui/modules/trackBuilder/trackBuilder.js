angular.module('beamng.stuff')

/**
 * @ngdoc controller
 * @name beamng.stuff.controller:TrackBuilderController
 * @description Track Builder controller
 */
.controller('TrackBuilderController', ['$scope', 'bngApi',
  function($scope, bngApi) {
    bngApi.engineLua("extensions.load('util/trackBuilder/splineTrack')");

    //lua index of current tile 
    var currentLuaIndex = 0;
    // number of track elements
    var trackElementCount = 1
    //holds the name of the function of the current piece
    var currentPieceLua = "addCurve"
    $scope.pieceSet= {value:"hex"}
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
    $scope.pieceParameters = 
    {
      hex: [
        {
          parameters: [
            {
              value: 3,
              name: "Radius",
              show: true,
              min: 1,
              type: "number",
              reset: 3,
              luaName: "length"
            },{
              value: 0,
              name: "Easing",
              show: true,
              min: -1,
              max: 1,
              stepSize: 0.1,
              type: "number",
              reset: 0,
              luaName: "hardness"
            },
            {
              value:-1,
              luaName: "direction"
            }
          ],
          function: "hexCurve",
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
              reset: 3,
              luaName: "size"
            },{
              name: 'Ease In',
              value: true,
              show: true,
              type: "checkbox",
              luaName: "inside"
            },{
              value:-1,
              luaName: "direction"
            }
          ],
          function: "hexSpiral",
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
              reset: 3,
              luaName: "length"
            }
          ],
          function: "hexForward",
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
              reset: 3,
              luaName: "size"
            },{
              name: 'Ease In',
              value: true,
              show: true,
              type: "checkbox",
              luaName: "inside"
            },{
              value:1,
              luaName: "direction"
            }
          ],
          function: "hexSpiral",
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
              reset: 3,
              luaName: "length"
            },{
              value: 0,
              name: "Easing",
              show: true,
              min: -1,
              max: 1,
              stepSize: 0.1,
              type: "number",
              reset: 0,
              luaName: "hardness"
            },
            {
              value:1,
              luaName: "direction"
            }
          ],
          function: "hexCurve",
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
              reset: 6,
              luaName: "length"
            },
            {
              value: 2,
              name: "Offset",
              show: true,
              type: "number",
              reset: 2,
              luaName: "xOffset"
            },
            {
              value: 0,
              name: "Hardness",
              show: true,
              min: -4,
              max: 10,
              type: "number",
              reset: 0,
              luaName: "hardness"
            },
          ],
          function: "hexOffsetCurve",
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
              reset: 6,
              luaName: "radius"
            },
            {
              value: 2,
              name: "Offset",
              show: true,
              type: "number",
              reset: 2,
              luaName: "xOffset"
            }
          ],
          function: "hexLoop",
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
              reset: 0,
              luaName: "xOff"
            },{
              value: 2,
              name: "Y Offset",
              show: true,
              type: "number",
              reset: 2,
              luaName: "yOff"
            },{
              value: 0,
              name: "Height Offset",
              show: true,
              type: "number",
              reset: 0,
              luaName: "zOff"
            },{
              value: 0,
              name: "Direction Offset",
              show: true,
              min: -3,
              max: 3,
              type: "number",
              reset: 0,
              luaName: "dirOff"
            },{
              name: 'Absolute',
              value: false,
              show: true,
              type: "checkbox",
              luaName: "absolute"
            }
          ],
          function: "hexEmptyOffset",
          icon:"material_linear_scale",
          tooltip: "ui.trackBuilder.emptyPiece",
          name: 'emptyOffset'
        }
      ],

      /////////////////////////////////////////////////////////
      square: [
        {
          parameters: [
            {
              value: 3,
              name: "Radius",
              show: true,
              min: 1,
              type: "number",
              reset: 3,
              luaName: "length"
            },{
              value: 0,
              name: "Easing",
              show: true,
              min: -1,
              max: 1,
              stepSize: 0.1,
              type: "number",
              reset: 0,
              luaName: "hardness"
            },
            {
              value:-1,
              luaName: "direction"
            }
          ],
          function: "squareCurve",
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
              reset: 3,
              luaName: "size"
            },{
              name: 'Ease In',
              value: true,
              show: true,
              type: "checkbox",
              luaName: "inside"
            },{
              value:-1,
              luaName: "direction"
            }
          ],
          function: "squareSpiral",
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
              reset: 3,
              luaName: "length"
            }
          ],
          function: "squareForward",
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
              reset: 3,
              luaName: "size"
            },{
              name: 'Ease In',
              value: true,
              show: true,
              type: "checkbox",
              luaName: "inside"
            },{
              value:1,
              luaName: "direction"
            }
          ],
          function: "squareSpiral",
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
              reset: 3,
              luaName: "length"
            },{
              value: 0,
              name: "Easing",
              show: true,
              min: -1,
              max: 1,
              stepSize: 0.1,
              type: "number",
              reset: 0,
              luaName: "hardness"
            },
            {
              value:1,
              luaName: "direction"
            }
          ],
          function: "squareCurve",
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
              reset: 6,
              luaName: "length"
            },
            {
              value: 2,
              name: "Offset",
              show: true,
              type: "number",
              reset: 2,
              luaName: "xOffset"
            },
            {
              value: 0,
              name: "Hardness",
              show: true,
              min: -4,
              max: 10,
              type: "number",
              reset: 0,
              luaName: "hardness"
            },
          ],
          function: "squareOffsetCurve",
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
              reset: 6,
              luaName: "radius"
            },
            {
              value: 2,
              name: "Offset",
              show: true,
              type: "number",
              reset: 2,
              luaName: "xOffset"
            }
          ],
          function: "squareLoop",
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
              reset: 0,
              luaName: "xOff"
            },{
              value: 2,
              name: "Y Offset",
              show: true,
              type: "number",
              reset: 2,
              luaName: "yOff"
            },{
              value: 0,
              name: "Height Offset",
              show: true,
              type: "number",
              reset: 0,
              luaName: "zOff"
            },{
              value: 0,
              name: "Direction Offset",
              show: true,
              min: -3,
              max: 3,
              type: "number",
              reset: 0,
              luaName: "dirOff"
            },{
              name: 'Absolute',
              value: false,
              show: true,
              type: "checkbox",
              luaName: "absolute"
            }
          ],
          function: "squareEmptyOffset",
          icon:"material_linear_scale",
          tooltip: "ui.trackBuilder.emptyPiece",
          name: 'emptyOffset'
        }
      ],

      /////////////////////////////////////////////////////////
      free:[
        {
          parameters: [
            {
              value: 3,
              name: "Radius",
              show: true,
              min: 1,
              type: "number",
              reset: 3,
              luaName: "radius"
            },{
              value: 30,
              name: "Angle",
              show: true,
              min: 1,
              max: 180,
              type: "number",
              reset: 30,
              luaName: "length"
            },
            {
              name: 'Fit to Hex',
              value: false,
              show: true,
              type: "checkbox",
              luaName: "fitHex"
            },
            {
              value:-1,
              luaName: "direction"
            }
          ],
          function: "freeCurve",
          icon: "trackgenerator_left_curve",
          tooltip: "ui.trackBuilder.leftTurn",
          name: 'leftCurve'
        },
        {
          parameters: [
            {
              value: 4,
              name: "Length",
              show: true,
              min: 1,
              type: "number",
              reset: 4,
              luaName: "length"
            }
          ],
          function: "freeForward",
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
              min: 1,
              type: "number",
              reset: 3,
              luaName: "radius"
            },{
              value: 30,
              name: "Angle",
              show: true,
              min: 1,
              max: 180,
              type: "number",
              reset: 30,
              luaName: "length"
            },{
              name: 'Fit to Hex',
              value: false,
              show: true,
              type: "checkbox",
              luaName: "fitHex"
            },{
              value:1,
              luaName: "direction"
            }
          ],
          function: "freeCurve",
          icon: "trackgenerator_right_curve",
          tooltip: "ui.trackBuilder.rightTurn",
          name: 'rightCurve'
        },
        {
          parameters: [
            {
              value: 0,
              name: "X Offset",
              show: true,
              type: "number",
              reset: 0,
              luaName: "xOff"
            },{
              value: 6,
              name: "Y Offset",
              show: true,
              type: "number",
              reset: 6,
              luaName: "yOff"
            },{
              value: 0,
              name: "Direction Offset",
              show: true,
              min: -3,
              max: 3,
              type: "number",
              reset: 0,
              luaName: "dirOff"
            }, {
              value: 4,
              name: "Forward Bezier Length",
              show: true,
              type: "number",
              reset: 4,
              min:1,
              luaName: "forwardLen"
            },{
              value: 4,
              name: "Backward Bezier Length",
              show: true,
              type: "number",
              reset: 4,
              min: 1,
              luaName: "backwardLen"
            },{
              name: 'Absolute',
              value: false,
              show: true,
              type: "checkbox",
              luaName: "absolute"
            }
          ],
          function: "freeBezier",
          icon: "trackgenerator_s_curve",
          tooltip: "ui.trackBuilder.rightTurn",
          name: 'freeBezier'
        }
      ]
    }

    //wether markers are shown or not
    $scope.displayMarkers = {
      value: true
    }

    //values for the different modifiers
    $scope.modifierValues = {
      bank: 0,
      height: 0,
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

    $scope.meshTypes = {
      border: ['regular','bevel','tube5m','tube5mHigh','tube5mFull','tube10m','tube10mHigh','tube10mFull','sideWall01','sideWall03','sideWall05','sideWall10','sideWall50','sideWall100','rotWall30','rotWall45','rotWall90'],
      center: ['regular', 'centerWall','leftWall','rightWall','centerGap','flat']
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
      $scope.pieceParameters[$scope.pieceSet.value][$scope.selectedBuildPieceIndex].parameters[pIndex].value  =  $scope.pieceParameters[$scope.pieceSet.value][$scope.selectedBuildPieceIndex].parameters[pIndex].reset;
      $scope.parameterChanged(pIndex);
    }

    //after a parameter is changed (by index), checks bounds and updates track
    $scope.parameterChanged = function(pIndex) {
      var piece = $scope.pieceParameters[$scope.pieceSet.value][$scope.selectedBuildPieceIndex]
      if(piece.parameters[pIndex].min)
        if(piece.parameters[pIndex].value < piece.parameters[pIndex].min)
          piece.parameters[pIndex].value = piece.parameters[pIndex].min;

      if(piece.parameters[pIndex].max)
        if(piece.parameters[pIndex].value > piece.parameters[pIndex].max)
          piece.parameters[pIndex].value = piece.parameters[pIndex].max;

      //some hacking to make the curves and straight pieces have the same parameter
      if($scope.pieceSet.value == 'hex' || $scope.pieceSet.value == 'square') {
        if($scope.selectedBuildPieceIndex <= 4) {
          if(pIndex == 0)
            for(var i = 0; i< 5; i++) 
                $scope.pieceParameters[$scope.pieceSet.value][i].parameters[pIndex].value = piece.parameters[pIndex].value;  
        }

        if(pIndex == 1 && ($scope.selectedBuildPieceIndex == 1 || $scope.selectedBuildPieceIndex == 3)) {
          $scope.pieceParameters[$scope.pieceSet.value][1].parameters[1].value = piece.parameters[1].value;  
          $scope.pieceParameters[$scope.pieceSet.value][3].parameters[1].value = piece.parameters[1].value;  
        }
      }
      replaceSelectedPiece();
      refreshTrack(true);
    }

    // sets modifier value (bank, height, height etc) and then calls the required function
    $scope.modify = function(mode, v) {
      if(mode == "width" && v < 0) 
        v = 0;
      if(mode == "width" && v > 50) 
        v = 50;

      if(v != null)
        $scope.modifierValues[mode] = v;
      var val = {
        value: v,
        interpolation: 'smoothSlope'
      }

      bngApi.engineLua(`extensions["util/trackBuilder/splineTrack"].markerChange("${mode}",${currentLuaIndex},${bngApi.serializeToLua(val)})`);
      refreshTrack();
      
    }

        // sets modifier value (bank, height, height etc) and then calls the required function
    $scope.modifyMesh = function(mode, value) {
      if(value == " - ") 
        value = null;

      if(value != null)
        $scope.modifierValues[mode] = value;
      var luaVal = '"' + value + '"';

      if(value == null)
        luaVal = "nil";
      $scope.quality.value = true;
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].setHighQuality(true)");
      bngApi.engineLua(`extensions["util/trackBuilder/splineTrack"].markerChange("${mode}",${currentLuaIndex},${luaVal})`);
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

      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].focusMarkerOn("+currentLuaIndex+")"); 
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
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].revert()");
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
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].removeAt(" + currentLuaIndex + ")");
      refreshTrack(true);
    }

    //calls the re-building function of the track builder, then gets the updated info.
    refreshTrack = function(keepSelection) {
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].makeTrack()");
      refreshInfo(keepSelection);
    }

    //gets the info of the track, like element count, marker info etc.
    refreshInfo = function(keepSelection) {
       bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].getPieceInfo(nil)", (allData) => {
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
        $scope.modifierValues.height = null;
        $scope.modifierValues.width = null;
        $scope.modifierValues.leftMesh = null;
        $scope.modifierValues.centerMesh = null;
        $scope.modifierValues.rightMesh = null;

        //sets the marker values to the first marker before the selection
        for(var i = data.length-1; i>=0; i--) {
          if(i <= currentLuaIndex-1) {
            if($scope.modifierValues.height == null && data[i].height)
              $scope.modifierValues.height = data[i].height.value;

            if($scope.modifierValues.bank == null && data[i].bank)
              $scope.modifierValues.bank = data[i].bank.value;

            if($scope.modifierValues.width == null && data[i].width) 
              $scope.modifierValues.width = data[i].width.value
            
            if($scope.modifierValues.leftMesh == null && data[i].leftMesh) 
              $scope.modifierValues.leftMesh = data[i].leftMesh.value
            
            if($scope.modifierValues.centerMesh == null && data[i].centerMesh) 
              $scope.modifierValues.centerMesh = data[i].centerMesh.value
            
            if($scope.modifierValues.rightMesh == null && data[i].rightMesh) 
              $scope.modifierValues.rightMesh = data[i].rightMesh.value
            
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
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].getSelectedTrackInfo()", (data) => {
        $scope.selectedTrackElementData = data;
        if(data) {

          $scope.selectedTrackElementData = null;

          if(data.parameters && data.parameters.piece) {
            var found = false;
            //loop over all pieces of all piece sets
            for(var set in $scope.pieceParameters) {
              for(var pi = 0; pi< $scope.pieceParameters[set].length; pi++){
                var piece = $scope.pieceParameters[set][pi];
                //if the functions match, check if it is actually the right piece (left/right have same function)
                if(piece.function == data.parameters.piece) {
                  var isRightPiece = true;
                  //check invisible parameters
                  for(var param in piece.parameters) {
                    if(!piece.parameters[param].show)
                      isRightPiece &= piece.parameters[param].value == data.parameters[piece.parameters[param].luaName];
                  }
                  if(!isRightPiece)
                    continue;
                  //put in parameters
                  for(var param in piece.parameters) 
                    piece.parameters[param].value = data.parameters[piece.parameters[param].luaName];
                  $scope.selectedBuildPieceIndex = pi;
                  $scope.pieceSet.value = set;
                  found = true;
                  break;
                }
              }
              if(found) break;
            }
          }
        }
      });
    }
    //replaces the current piece of the track with a new piece 
    replaceSelectedPiece = function() {
      if(currentLuaIndex == 1)
        return;
      var luaCode = "extensions[\"util/trackBuilder/splineTrack\"].addPiece(";
      var piece = $scope.pieceParameters[$scope.pieceSet.value][$scope.selectedBuildPieceIndex];
      //luaCode += piece.function + "(";
      var parameters = {}
      for(var i = 0; i<piece.parameters.length; i++) {
        parameters[piece.parameters[i].luaName] = piece.parameters[i].value;
      }
      parameters['piece'] = piece.function;

      luaCode += bngApi.serializeToLua(parameters)

      luaCode += "," + (currentLuaIndex);
      luaCode +=",true";
      luaCode += ")";
      bngApi.engineLua(luaCode);
    }

    //adds a new piece after a given index.
    addPieceAfter = function(afterIndex) {
      var luaCode = "extensions[\"util/trackBuilder/splineTrack\"].addPiece(";
      var piece = $scope.pieceParameters[$scope.pieceSet.value][$scope.selectedBuildPieceIndex];
      //luaCode += piece.function + "(";
      var parameters = {}
      for(var i = 0; i<piece.parameters.length; i++) {
        parameters[piece.parameters[i].luaName] = piece.parameters[i].value;
      }
      parameters['piece'] = piece.function;
      luaCode += bngApi.serializeToLua(parameters)


      luaCode += "," + afterIndex;
      luaCode +=",false";
      luaCode += ")";
      bngApi.engineLua(luaCode);
    }
    //shows or hides the markers
    $scope.showMarkers = function() {
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].showMarkers(" + !$scope.displayMarkers.value + ")");
      if($scope.displayMarkers.value)
        bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].setAllPiecesToAsphalt()");
    }

    //sets high or low quality.
    $scope.toggleQuality = function() {
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].setHighQuality(" + !$scope.quality.value + ")");
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].makeTrack()");
      refreshInfo(true);
    }

    //saves or overwrites the track under a given name
    $scope.save = function(saveName) {
      bngApi.engineLua(`extensions[\"util/trackBuilder/splineTrack\"].save(${bngApi.serializeToLua(saveName)})`);
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].getCustomTracks()", (data) => {
        $scope.tracks = data;
      });
    }

    $scope.setDefaultLaps = function() {
      if($scope.defaultLaps.value < 1)
        $scope.defaultLaps.value = 1;
      bngApi.engineLua(`extensions[\"util/trackBuilder/splineTrack\"].setDefaultLaps(${$scope.defaultLaps.value})`);
      refreshInfo(true);
    }

    $scope.setReversible = function() {
      bngApi.engineLua(`extensions[\"util/trackBuilder/splineTrack\"].setReversible(${$scope.reversible.value})`);
      refreshInfo(true);
    }

    //loads a track by name
    $scope.load = function(trackName) {
      bngApi.engineLua(`extensions[\"util/trackBuilder/splineTrack\"].load(${bngApi.serializeToLua(trackName)})`);
      refreshInfo();
    }

    //puts a number of pieces on the stack
    $scope.stack = function(count) {
      if(count == 1)
        bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].stack(1)");
      else
        bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].applyStack(1)");
      refreshTrack();
      getStackCount();
    }

    //stacks all the pieces up to the cursor.
    $scope.stackToCursor = function() {
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].stackToCursor()");
      refreshTrack();
      getStackCount();
    }

    //applies all pieces on the stack
    $scope.stackApplyAll = function(keep) {
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].applyStack(99999,"+keep+")");
      refreshTrack();
      getStackCount();
    }

    //clears the stack.
    $scope.clearStack = function() {
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].clearStack()");
      getStackCount(); 
    }

    //gets how many pieces currently are on the stack from lua.
    getStackCount = function() {
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].getStackCount()", (data) => {
        $scope.stackCount = data;
      });
    }

    //sets the track position and rotation, then re-makes the track.
    $scope.setTrackPosition = function() {
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].setTrackPosition(" + $scope.trackPosition.x + "," + $scope.trackPosition.y + "," +$scope.trackPosition.z + "," +$scope.trackPosition.hdg + ")" );
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].makeTrack()");
      refreshInfo(true);
    }

    // Calls a function, then makes track and refreshes info.
    $scope.callMakeRefresh = function(functionToCall) {
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"]."+functionToCall+"()" );
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].makeTrack()");
      refreshInfo(true);
    }

    //sets high quality, hides markers and places the currentl vehicle on the track start.
    $scope.drive = function() {
      //if(!$scope.quality.value) {
        $scope.quality.value = true;
        bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].setHighQuality(true)");
        bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].makeTrack(true)");
    //  }
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].showMarkers(false)");
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].setAllPiecesToAsphalt()");
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].positionVehicle()");
      $scope.displayMarkers.value = false;

    }

    //removes the whole track, disables the track builder UI.
    $scope.clearTrack = function() {
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].removeTrack()");
      bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].unloadAll()");
      $scope.clearedTrack = true;
    }

    //whenever the app is started:
    //un-clear the track (enable UI)
    $scope.clearedTrack = false
    refreshTrack();
    refreshInfo();
    getStackCount();
     //getting the tracks when the app is loaded.
    bngApi.engineLua("extensions[\"util/trackBuilder/splineTrack\"].getCustomTracks()", (data) => {
      $scope.tracks = data;
    });
  }
]);
