-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local keywordWhiteList = {"not", "true", "false", "nil"}
local keyworkdWhiteListLookup = nil

--function used as a case selector, input can be both int and bool as the first argument, any number of arguments after that
--in case it's a bool, it works like a ternary if, returning the second param if true, the third if false
--if the selector is an int n, it simply returns the nth+1 param it was given, if n > #params it returns the last given param
local function case(selector, ...)
  local index = 0
  local selectorType = type(selector)

  if selectorType == "boolean" then
    index = selector and 1 or 0
  elseif selectorType == "number" then
    index = math.floor(selector) --make sure we have an int for table access
  else
    log_jbeam('E', "jbeam.expressionParser.parse", "Only booleans and numbers are supported as case selectors! Defaulting to last argument... Type: "..selectorType)
  end

  local arg = {...}
  return arg[index] or arg[select("#", ...)] --fetch value from given index or from the last index
end

local function buildBaseEnv()
  --we build our custom environment for the parsed lua from jbeam variables
  --we also include a list of variables from the pc file so that we can keep backwards compatibility with (now) removed variables
  local env = {}
  --include all math functions and constants
  for k,v in pairs(math) do
    env[k] = v
  end

  --also include a few of our own math functions
  env.round = round
  env.square = square
  env.clamp = clamp
  env.smoothstep = smoothstep
  env.smootherstep = smootherstep
  env.smoothmin = smoothmin
  env.sign = sign
  env.case = case

  --dump(env)

  return env
end

local function buildEnvJbeamVariables(variables, userVariables)
    --build our kweyword lookup table
  keyworkdWhiteListLookup = {}
  for _,v in pairs(keywordWhiteList) do
    keyworkdWhiteListLookup[v] = true
  end

  local env = buildBaseEnv(true)

  --include all our jbeam variables with the user_ prefix
  for k,v in pairs(variables) do
    --strip the leading "$" from the name and replace by the user prefix
    local name = "user_"..k:sub(2)
    env[name] = v.val
  end

  --we also need to include ALL variables that are defined in the pc file for backwards compat reasons
  --this means that some variables in our final env might not actually be defined in jbeam anymore
  for k,v in pairs(userVariables) do
    --strip the leading "$" from the name and replace by the user prefix
    local name = "user_"..k:sub(2)
    if not env[name] then
      env[name] = v
    end
  end

  env = tableReadOnly(env)

  return env
end

local function parse(expr, env)
  --strip leading "$=" from expression and replace all occurences of "$" with "user_" (as these are used for lua variable names)
  local sanitizedExpr = expr:sub(3):gsub("%$","user_")
  --print(sanitizedExpr)
  --check if we find a *single standalone* "=" sign and abort parsing if found. >=, <=, == and ~= are allowed to support boolean operations
  if sanitizedExpr:find("[^<>~=]=[^=]") then
    log_jbeam('E', "jbeam.expressionParser.parse", "Assignments are not supported inside expressions!")
    return nil
  end
  --print(sanitizedExpr)

  --find all literals (single letter, then >= 0 letters, numbers or _, so supported variable names in jbeam for this consist of [a-zA-Z0-9_])
  for v in sanitizedExpr:gmatch("%a[%a%d_]*") do
    --print("Literal: "..v)
    --if the literal does *not* start with "user_" we need to check if it exists in the env (functions mostly) or if it's in the whitelist (for stuff like true/false/etc)
    --if it's not in either table, it's forbidden and we abort parsing
    if v:sub(1,5) ~= "user_" and not (env[v] or keyworkdWhiteListLookup[v]) then
      log_jbeam('E', "jbeam.expressionParser.parse", "Found illegal literal in expression: "..v)
      return nil
    end
  end
  --load the now sanitized and sandbox checked code with our custom environment
  local exprFunc, message = load("return "..sanitizedExpr, nil, 't', env)
  if exprFunc then
    --execute the loaded code in protected mode to catch any non syntax errors
    local success, result = pcall(exprFunc)
    if not success then
      log_jbeam('E', "jbeam.expressionParser.parse", "Executing expression failed, message: "..result)
      return nil
    end
    --print("Expression value: "..result)
    return result
  else
    --syntax error most likely
    log_jbeam('E', "jbeam.expressionParser.parse", "Parsing expression failed, message: "..message)
    return nil
  end
end

M.parse = parse
M.buildBaseEnv = buildBaseEnv
M.buildEnvJbeamVariables = buildEnvJbeamVariables

return M