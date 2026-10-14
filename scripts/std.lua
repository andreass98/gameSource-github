local registeredConsoleCommands = _G.getSelection ~= nil
GS_IS_EDITOR = registeredConsoleCommands
GS_INPUT_HELP_MODE_AUTO = 1
GS_INPUT_HELP_MODE_KEYBOARD = 2
GS_INPUT_HELP_MODE_GAMEPAD = 3
GS_INPUT_HELP_MODE_TOUCH = 4
GS_PRIO_VERY_HIGH = 1
GS_PRIO_HIGH = 2
GS_PRIO_NORMAL = 3
GS_PRIO_LOW = 4
GS_PRIO_VERY_LOW = 5
GS_MONEY_EURO = 1
GS_MONEY_DOLLAR = 2
GS_MONEY_POUND = 3
function loadfile() end
function load()
    return nil, "invalid function"
end
if setFileLogPrefixTimestamp == nil then
    function setFileLogPrefixTimestamp(addTimestamp) end
end
local registeredConsoleCommands = {}
if addConsoleCommand ~= nil then
    local oldAddConsoleCommand = addConsoleCommand
    function addConsoleCommand(name, description, funcName, funcTarget, argumentNames, ...)
        -- upvalues: (copy) registeredConsoleCommands, (copy) oldAddConsoleCommand
        if registeredConsoleCommands[name] == nil then
            oldAddConsoleCommand(name, description, funcName, funcTarget, argumentNames, ...)
            local arguments = nil
            if argumentNames ~= nil then
                arguments = string.split(argumentNames, ";")
                for argIndex, argument in ipairs(arguments) do
                    arguments[argIndex] = string.trim(argument)
                end
            end
            registeredConsoleCommands[name] = {
                ["description"] = description,
                ["arguments"] = arguments
            }
        else
            printError(string.format("Error: Failed to register console command \'%s. Command was already registered!", name))
        end
    end
end
if removeConsoleCommand ~= nil then
    local oldAddConsoleCommand = removeConsoleCommand
    function removeConsoleCommand(name, ...)
        -- upvalues: (copy) oldAddConsoleCommand, (copy) registeredConsoleCommands
        oldAddConsoleCommand(name, ...)
        registeredConsoleCommands[name] = nil
    end
end
function consoleCommandListCommands()
    -- upvalues: (copy) registeredConsoleCommands
    local sortedNames = {}
    local maxNameLength = 0
    for name, data in pairs(registeredConsoleCommands) do
        sortedNames[#sortedNames + 1] = name
        local commandData = registeredConsoleCommands[name]
        if commandData.arguments ~= nil then
            local name = string.format("%s %s", name, table.concat(commandData.arguments, ", "))
        end
        local nameLen = string.len(name)
        maxNameLength = math.max(maxNameLength, nameLen)
    end
    table.sort(sortedNames)
    setFileLogPrefixTimestamp(false)
    for name, data in ipairs(sortedNames) do
        local commandData = registeredConsoleCommands[data]
        if commandData.arguments ~= nil then
            local data = string.format("%s %s", data, table.concat(commandData.arguments, ", "))
        end
        local commandName = data .. string.rep(" ", maxNameLength - string.len(data))
        print(string.format("%s   %s", commandName, registeredConsoleCommands[data].description))
    end
    print(string.format("# Listed %d script-based console commands. Use \'help\' to get all commands", #sortedNames))
    setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
end
function consoleCommandSearchCommands(searchStr)
    -- upvalues: (copy) registeredConsoleCommands
    local results = {}
    if searchStr == nil or searchStr == "" then
        return "Error: no search string given"
    end
    local addCommandToResults = string.upper(searchStr)
    for commandName, commandData in pairs(registeredConsoleCommands) do
        if string.contains(string.upper(commandName), addCommandToResults) then
            if ({})[commandName] == nil then
                local commandData = registeredConsoleCommands[commandName]
                if commandData == nil then
                    printError("No command with name %q", commandName)
                else
                    table.insert(results, { commandName, commandData })
                    resultsLookup[commandName] = true
                end
            end
        end
    end
    for commandName, commandData in pairs(registeredConsoleCommands) do
        if string.contains(string.upper(commandData.description), addCommandToResults) then
            if resultsLookup[commandName] == nil then
                local commandData = registeredConsoleCommands[commandName]
                if commandData == nil then
                    printError("No command with name %q", commandName)
                else
                    table.insert(results, { commandName, commandData })
                    resultsLookup[commandName] = true
                end
            end
        end
    end
    for commandName, commandData in pairs(registeredConsoleCommands) do
        if commandData.arguments ~= nil then
            for _, argument in ipairs(commandData.arguments) do
                if string.contains(string.upper(argument), addCommandToResults) then
                    if resultsLookup[commandName] == nil then
                        local commandData = registeredConsoleCommands[commandName]
                        if commandData == nil then
                            printError("No command with name %q", commandName)
                        else
                            table.insert(results, { commandName, commandData })
                            resultsLookup[commandName] = true
                        end
                    end
                end
            end
        end
    end
    if #results == 0 then
        return "Error: no results\nTry a different search term or use \'help\' to list all commands"
    end
    setFileLogPrefixTimestamp(false)
    for commandName, commandData in ipairs(results) do
        local arguments = commandData[1][2].arguments ~= nil and " " .. table.concat(commandData[1][2].arguments, ", ") or ""
        print(commandData .. arguments .. "\n        " .. commandData[2].description)
    end
    print(string.format("Listed %d script-defined console commands for search \'%s\'. Use \'help\' to get all available commands", #results, addCommandToResults))
    setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
end
if addConsoleCommand ~= nil then
    addConsoleCommand("gsScriptCommandsList", "Lists script-based console commands. Use \'help\' to get all commands", "consoleCommandListCommands", nil)
    addConsoleCommand("gsSearch", "Searches for script-based console commands containing the given string (name and description). Use \'help\' to get all commands", "consoleCommandSearchCommands", nil)
end
function log(...)
    local str = ""
    local i = 1
    for i = i, select("#", ...) do
        str = str .. " " .. tostring(select(i, ...))
    end
    print(str)
end
local function oldAddConsoleCommand(inputTable, inputIndent, depth, maxDepth)
    -- upvalues: (copy) oldAddConsoleCommand
    inputIndent = inputIndent or "  "
    depth = depth or 0
    maxDepth = maxDepth or 3
    if maxDepth >= depth then
        for i, j in pairs(inputTable) do
            print(inputIndent .. tostring(i) .. " :: " .. tostring(j))
            if type(j) == "table" then
                oldAddConsoleCommand(j, inputIndent .. "    ", depth + 1, maxDepth)
            end
        end
        return ""
    end
end
function print_r(tbl, depth)
    -- upvalues: (copy) oldAddConsoleCommand
    if tbl == nil then
        print("table: nil")
        return
    elseif type(tbl) == "table" then
        if next(tbl) == nil then
            print("table: empty")
        else
            setFileLogPrefixTimestamp(false)
            oldAddConsoleCommand(tbl, "  ", 0, depth or 5)
            setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
        end
    else
        print("table: no such table")
        return
    end
end
function printf(formatText, ...)
    print(string.format(formatText, ...))
end
function ipairs_reverse(list)
    if type(list) ~= "table" then
        error(string.format("invalid argument #1 (%s) to \'ipairs_reverse\' (table expected)", (type(list))), 2)
    end
    local currentIndex = #list
    return function()
        -- upvalues: (ref) currentIndex, (copy) list
        if currentIndex < 1 then
            return nil
        end
        local value = list[currentIndex]
        if value == nil then
            return nil
        end
        currentIndex = currentIndex - 1
        return currentIndex + 1, value
    end
end
function ipairs_randomStart(list)
    if type(list) ~= "table" then
        error(string.format("invalid argument #1 (%s) to \'ipairs_randomStart\' (table expected)", (type(list))), 2)
    end
    local length = #list
    local currentIndex = 0
    local numIterations = 0
    if length > 1 then
        currentIndex = math.random(0, length - 1)
    end
    return function()
        -- upvalues: (ref) numIterations, (copy) length, (ref) currentIndex, (copy) list
        if numIterations == length then
            return nil
        else
            currentIndex = currentIndex + 1
            if length < currentIndex then
                currentIndex = 1
            end
            local value = list[currentIndex]
            if value == nil then
                return nil
            else
                return currentIndex, value
            end
        end
    end
end
function iteratePointList2D(pointList2D)
    local length = pointList2D:getNumPoints()
    local index = 1
    return function()
        -- upvalues: (ref) index, (copy) length, (copy) pointList2D
        if index > length then
            return nil
        end
        local x, z = pointList2D:get(index - 1)
        index = index + 1
        return index - 1, x, z
    end
end
function iteratePointList2DLines(pointList2D)
    local length = pointList2D:getNumPoints()
    local index = 1
    return function()
        -- upvalues: (ref) index, (copy) length, (copy) pointList2D
        if index >= length then
            return nil
        end
        local x1, z1 = pointList2D:get(index - 1)
        local x2, z2 = pointList2D:get(index)
        index = index + 1
        return x1, z1, x2, z2
    end
end
function assertWithCallstack(expression, message)
    if not expression then
        if message == nil or type(message) ~= "string" then
            printError("Error: assertion failed!")
        else
            printError("Error: assertion failed: " .. message)
        end
        printCallstack()
        error("Assertion failed")
    end
end
function registerObjectClassName(object, className)
    if g_currentMission ~= nil then
        g_currentMission.objectsToClassName[object] = className
    end
end
function unregisterObjectClassName(object)
    if g_currentMission ~= nil then
        g_currentMission.objectsToClassName[object] = nil
    end
end
function getNormalizedScreenValues(x, y)
    if x == nil or y == nil then
        printCallstack()
    end
    return x / g_referenceScreenWidth * g_aspectScaleX, y / g_referenceScreenHeight * g_aspectScaleY
end
function getCorrectTextSize(size)
    if g_aspectScaleY == nil then
        return size
    else
        return size * g_aspectScaleY
    end
end
function calculateFovY(defaultFovy)
    if GS_IS_EDITOR then
        return defaultFovy
    end
    return math.clamp(defaultFovy + (g_gameSettings:getValue(GameSettings.SETTING.FOV_Y) - g_fovYDefault), g_fovYMin, g_fovYMax)
end
if GS_IS_EDITOR then
    RainSimWeatherType = RainSimWeatherType or {
        ["DEFAULT"] = 1,
        ["RAIN"] = 2,
        ["SNOW"] = 3,
        ["HAIL"] = 4
    }
    getUserName = getUserName or function(...)
        return ""
    end
    getUserId = getUserId or function(...)
        return ""
    end
    reportUser = reportUser or function(uniqueUserId, platformUserId, platformId, reason, ...) end
    addConsoleCommand = addConsoleCommand or function(commandName, description, functionName, target, targetArgumentNames, excludeFromHistory, ...)
        return true
    end
    removeConsoleCommand = removeConsoleCommand or function(commandName, ...) end
    executeConsoleCommand = executeConsoleCommand or function(consoleCommandName, excludeFromHistory, ...) end
    getAppBasePath = getAppBasePath or function()
        return getGameBasePath() or ""
    end
    getUserProfileAppPath = getUserProfileAppPath or function()
        return g_userProfilePath or ""
    end
    getEngineRevision = getEngineRevision or function()
        return ""
    end
    getTotalSystemMemory = getTotalSystemMemory or function()
        return 16384
    end
    setFileLogPrefixTimestamp = setFileLogPrefixTimestamp or function(prefixTimestamp, ...) end
    enableDevelopmentControls = enableDevelopmentControls or function() end
    startFrameRepeatMode = startFrameRepeatMode or function()
        return false
    end
    endFrameRepeatMode = endFrameRepeatMode or function()
        return false
    end
    forceEndFrameRepeatMode = forceEndFrameRepeatMode or function() end
    enterCpuBoostMode = enterCpuBoostMode or function() end
    leaveCpuBoostMode = leaveCpuBoostMode or function() end
    get3dResolutionScaling = get3dResolutionScaling or function()
        return 1
    end
    centerHeadTracking = centerHeadTracking or function() end
    getScreenAspectRatio = getScreenAspectRatio or function()
        return g_screenAspectRatio
    end
end
if getHasGamepadAxisForceFeedback == nil then
    function getHasGamepadAxisForceFeedback(axisNumber, gamepadIndex)
        return false
    end
end
if setGamepadAxisForceFeedback == nil then
    function setGamepadAxisForceFeedback(axisNumber, gamepadIndex, force, position) end
end