var navigableElements = "[ng-click],[href],[bng-all-clicks],[bng-all-clicks-no-nav],[ui-sref],input,textarea,button,md-option,md-slider,md-select";
function uncollectRects(scope) {
  var ns = document.querySelectorAll(navigableElements);
  for (var i = 0,l = ns.length; i < l; i++) {
    if (!isFocusable(ns[i])) continue;
    ns[i].classList.remove("menu-navigation");
  }
}
function collectRects(scope) {
  scope.links = { "up":[], "down":[], "left":[], "right":[] };
  var ns = document.querySelectorAll(navigableElements);
  for (var i = 0,l = ns.length; i < l; i++) {
    if (!isFocusable(ns[i])) continue;
    ns[i].classList.add("menu-navigation");
    ns[i].tabIndex = 0; // make element focusable
    var rect = ns[i].getBoundingClientRect();
    scope.links[   "up"].push({dom: ns[i], rect: rect});
    scope.links[ "down"].push({dom: ns[i], rect: rect});
    scope.links[ "left"].push({dom: ns[i], rect: rect});
    scope.links["right"].push({dom: ns[i], rect: rect});
  }
  scope.links[   "up"].sort(function(a,b) { return a.rect.top    - b.rect.top   });
  scope.links[ "down"].sort(function(a,b) { return a.rect.botton - b.rect.bottom});
  scope.links[ "left"].sort(function(a,b) { return a.rect.left   - b.rect.left  });
  scope.links["right"].sort(function(a,b) { return a.rect.right  - b.rect.right });
}
function getCenter(rect) {
  return {x: rect.left + (rect.width) / 2, y: rect.top + (rect.height) / 2};
}
function isFocusable(node) {
    if (!isVisible(node)) return false;
    return true;
}
function isVisible(node) {
  var tmp = node;
  while (tmp.tagName != "HTML") {
    var style = document.defaultView.getComputedStyle(tmp, "");
    if (style.display == "none" || style.visibility == "hidden" || style.opacity == 0) {
      return false;
    }
    tmp = tmp.parentNode;
  }
  var rects = node.getClientRects();
  for (var i = 0, l = rects.length; i < l; i++) {
    if (!isOcluded(node, rects[i])) return true;
  }
  return false;
}
function isOcluded (element, r) {
  // returns true only when element is on viewport AND other HTML element is ocluding it on screen (preventing user from seeing/clicking it)
  var x = (r.left + r.right)/2, y = (r.top + r.bottom)/2;
  var topElement = document.elementFromPoint(x, y);
  if (topElement == null) return false; // outside viewport, we assume it's not ocluded
  var tmp = topElement;
  while (tmp.tagName != "HTML") { // check if we clicked on our desired element, or any of its ancestors
    if (tmp == element) return false;
    tmp = tmp.parentNode;
  }
  return true;
}

function isTarget(curr, goal, direction) {
  var dx = (Math.abs(goal.left-curr.left) + Math.abs(goal.right-curr.right))/2;
  var dy = (Math.abs(goal.top-curr.top) + Math.abs(goal.bottom-curr.bottom))/2;

  var dist;
  if (direction == "down" ) {
      if (goal.top    < curr.top   ) return -1;         // too far down
      dist = goal.bottom - curr.bottom;
  }
  if (direction == "up"   ) {
      if (goal.bottom > curr.bottom) return -1;         // too far up
      dist = curr.top    - goal.top;
  }
  if (direction == "right") {
      if (goal.left   < curr.left  ) return -1;         // too far left
      dist = goal.right  - curr.right;
  }
  if (direction == "left" ) {
      if (goal.right  > curr.right ) return -1;         // too far right
      dist = curr.left   - goal.left;
  }
  var mult = 1;
  if (direction ==   "up" || direction ==  "down") {
      if (                      -1 >= dist) return -1; // too far vertically
      if ((curr.left - goal.right) >= dist) return -1; // too far left
      if ((goal.left - curr.right) >= dist) return -1; // too far right
      return dx*mult + dy     ;
  }
  if (direction == "left" || direction == "right") {
      if (                       0 >= dist) return -1; // too far horizontally
      if ((curr.top - goal.bottom) >= dist) return -1; // too far up
      if ((goal.top - curr.bottom) >= dist) return -1; // too far down
      return dx      + dy*mult;
  }
  return -1;
}

function navigate(scope, direction) {
    if(scope.links[direction]) {
      navigateNext(scope.links[direction], direction);
    }
}

function navigateNext(links, direction) {
  var active = document.activeElement;
  if (active.nodeName == "BODY") {
    setTimeout(function(){
      //locate first button (closest to topleft corner), and set its focus
      var firstElement = null;
      var firstElementDistance = Number.MAX_SAFE_INTEGER;
      for (var i = 0; i<links.length; i++) {
          var distance = links[i].rect.top * links[i].rect.top + links[i].rect.left * links[i].rect.left;
          if (distance > firstElementDistance) continue;
          firstElementDistance = distance;
          firstElement = links[i].dom;
      }
      if (!firstElement) {
          console.log("Couldn't locate any button anywhere. Menu navigation won't work");
          return;
      }
      firstElement.focus();
      console.log("First button focused: ", firstElement);
    }, 0);
    return;
  }
  if (active.nodeName == "MD-SLIDER" && (direction == "left" || direction == "right")) return fireKey(active, direction);
  if (active.nodeName == "MD-OPTION" && (direction ==   "up" || direction ==  "down")) return fireKey(active, direction);
  var dir = 1;
  if (direction == "left" || direction == "up") dir = -1;
  var ignore = false;
  var activeRect = active.getBoundingClientRect();
  var start = (dir == 1) ? 0 : links.length - 1;
  var minDistance = -1;
  var nearestNode = null;
  for (var i = start,l = links.length; 0 <= i  && i < l; i += dir) {
    if (links[i].dom == active ) continue; // don't navigate to current element again
    var distance = isTarget(activeRect, links[i].rect, direction);
    if (distance < 0) continue; // not an eligible element to navigate to
    if (minDistance < 0 || distance < minDistance) {
      minDistance = distance;
      nearestNode = links[i].dom;
    }
  }
  if (nearestNode) {
    nearestNode.focus();
  }
}
function fireKey(element, direction) {
    var key = null;
    if (direction == "left")  key = 37;
    if (direction == "up")    key = 38;
    if (direction == "right") key = 39;
    if (direction == "down")  key = 40;
    return element.dispatchKey(key);
}
