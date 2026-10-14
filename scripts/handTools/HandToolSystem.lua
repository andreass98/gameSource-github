source("dataS/scripts/handTools/HandToolUtil.lua")
source("dataS/scripts/handTools/HandTool.lua")
source("dataS/scripts/handTools/HandToolLoadingData.lua")
source("dataS/scripts/handTools/HandToolLoadingState.lua")
source("dataS/scripts/handTools/HandToolHolder.lua")
source("dataS/scripts/handTools/HandToolHolderActivatable.lua")
source("dataS/scripts/handTools/events/HandToolSetHolderEvent.lua")
HandToolSystem = {}
local HandToolSystem_mt = Class(HandToolSystem, AbstractManager)
HandToolSystem.UNIQUE_ID_PREFIX = "HandTool"
g_xmlManager:addCreateSchemaFunction(function()
    HandToolSystem.registerXMLPaths()
    HandToolSystem.savegameXMLSchema = XMLSchema.new("savegame_handTools")
    HandToolSystem.registerSavegameXMLPaths(HandToolSystem.savegameXMLSchema)
end)
function HandToolSystem.registerXMLPaths()
    Mission00.xmlSchema:register(XMLValueType.STRING, "map.newPlayerHandTools.handTool(?)#xmlFilename", "Filename of the hand tool\'s xml file", nil, false)
    HandTool.registerXMLPaths()
end
function HandToolSystem.registerSavegameXMLPaths(savegameXMLSchema)
    savegameXMLSchema:register(XMLValueType.INT, "handTools#version", "The version of the save file", nil, true)
    HandTool.registerSavegameXMLPaths(savegameXMLSchema)
end
function HandToolSystem.new()
    -- upvalues: (copy) HandToolSystem_mt
    local self = setmetatable({}, HandToolSystem_mt)
    self.version = 1
    self.handTools = {}
    self.handToolsByUniqueId = {}
    self.pendingHandTools = {}
    self.startingPlayerHandTools = {}
    self.handToolsToDelete = {}
    self.handToolHolders = {}
    self.handToolHoldersByUniqueId = {}
    self.handToolHoldersByClickBox = {}
    self.isHandToolReloadRunning = false
    if g_addTestCommands then
        addConsoleCommand("gsHandToolsPendingLoadings", "Prints the pending handtool loadings", "consoleCommandPrintPendingLoadings", self)
    end
    addConsoleCommand("gsHandToolReload", "Reloads the currently held hand tool", "consoleCommandReloadHandTool", self)
    return self
end
function HandToolSystem:delete()
    for k, handTool in pairs(self.handToolsToDelete) do
        handTool:delete()
    end
    table.clear(self.handToolsToDelete)
    for k, handTool in ipairs(self.handTools) do
        handTool:delete()
    end
    table.clear(self.handTools)
    for k, handTool in ipairs(self.handToolHolders) do
        handTool:delete()
    end
    table.clear(self.handToolHolders)
    if self.savegameXMLFile ~= nil then
        self.savegameXMLFile:delete()
        self.savegameXMLFile = nil
    end
    removeConsoleCommand("gsHandToolsPendingLoadings")
    removeConsoleCommand("gsHandToolReload")
end
function HandToolSystem:loadMapData(xmlFile, _, baseDirectory)
    if xmlFile ~= nil then
        xmlFile = XMLFile.wrap(xmlFile, Mission00.xmlSchema)
        for _, handToolNodeKey in xmlFile:iterator("map.newPlayerHandTools.handTool") do
            local handToolXMLFilename = xmlFile:getValue(handToolNodeKey .. "#xmlFilename")
            if string.isNilOrWhitespace(handToolXMLFilename) then
                Logging.xmlError(xmlFile, "Player starting hand tool at %q has a missing filename!", handToolNodeKey)
            else
                local handToolXMLFilename = Utils.getFilename(handToolXMLFilename, baseDirectory)
                table.addElement(self.startingPlayerHandTools, handToolXMLFilename)
            end
        end
    end
end
function HandToolSystem:getStartingHandTools()
    return self.startingPlayerHandTools
end
function HandToolSystem:addHandTool(handTool)
    if handTool == nil or handTool:isa(HandTool) == nil then
        Logging.error("Given object is not a handtool")
        return false
    elseif handTool:getUniqueId() == nil or self.handToolsByUniqueId[handTool:getUniqueId()] == nil then
        if handTool:getUniqueId() == nil then
            handTool:setUniqueId(Utils.getUniqueId(handTool, self.handToolsByUniqueId, HandToolSystem.UNIQUE_ID_PREFIX))
        end
        table.addElement(self.handTools, handTool)
        self.handToolsByUniqueId[handTool:getUniqueId()] = handTool
        g_messageCenter:publish(MessageType.HANDTOOL_ADDED)
        return true
    else
        Logging.warning("Tried to add existing handTool with unique id of %s! Existing: %s, new: %s", handTool:getUniqueId(), tostring(self.handToolsByUniqueId[handTool:getUniqueId()]), (tostring(handTool)))
        return false
    end
end
function HandToolSystem:removeHandTool(handTool)
    if handTool ~= nil then
        table.removeElement(self.handTools, handTool)
        local uniqueId = handTool:getUniqueId()
        if uniqueId ~= nil and self.handToolsByUniqueId[uniqueId] == handTool then
            self.handToolsByUniqueId[uniqueId] = nil
        end
        g_messageCenter:publish(MessageType.HANDTOOL_REMOVED)
    end
end
function HandToolSystem:getHandToolByUniqueId(uniqueId)
    return self.handToolsByUniqueId[uniqueId]
end
function HandToolSystem:deleteMarkedHandTools()
    for k, handTool in pairs(self.handToolsToDelete) do
        handTool:delete()
        self.handToolsToDelete[k] = nil
    end
end
function HandToolSystem:markHandToolForDeletion(handTool)
    self.handToolsToDelete[handTool] = handTool
end
function HandToolSystem:addHandToolHolder(handToolHolder)
    if handToolHolder == nil or handToolHolder:isa(HandToolHolder) == nil then
        Logging.error("Given object is not a HandToolHolder")
        return false
    end
    table.addElement(self.handToolHolders, handToolHolder)
    local uniqueId = handToolHolder:getUniqueId()
    if uniqueId ~= nil and self.handToolHoldersByUniqueId[uniqueId] ~= nil then
        Logging.warning("Tried to add existing handToolHolder (%s) but uniqueId is already in use! Existing: %s, new: %s", uniqueId, tostring(self.handToolHoldersByUniqueId[uniqueId]), (tostring(handToolHolder)))
        return false
    end
    if uniqueId == nil then
        uniqueId = Utils.getUniqueId(handToolHolder, self.handToolHoldersByUniqueId, HandToolSystem.UNIQUE_ID_HOLDER_PREFIX)
        handToolHolder:setUniqueId(uniqueId)
    end
    self.handToolHoldersByUniqueId[uniqueId] = handToolHolder
    Logging.devInfo("Added handtool holder %q (%s)", handToolHolder, uniqueId)
    for _, clickBoxNode in ipairs(handToolHolder.clickBoxes) do
        self.handToolHoldersByClickBox[clickBoxNode] = handToolHolder
    end
    return true
end
function HandToolSystem:removeHandToolHolder(handToolHolder)
    if handToolHolder ~= nil then
        table.removeElement(self.handToolHolders, handToolHolder)
        local uniqueId = handToolHolder:getUniqueId()
        if uniqueId ~= nil and self.handToolHoldersByUniqueId[uniqueId] == handToolHolder then
            self.handToolHoldersByUniqueId[uniqueId] = nil
        end
        if handToolHolder.clickBoxes ~= nil then
            for _, clickBoxNode in ipairs(handToolHolder.clickBoxes) do
                self.handToolHoldersByClickBox[clickBoxNode] = nil
            end
        end
    end
end
function HandToolSystem:getHandToolHolderByUniqueId(uniqueId)
    return self.handToolHoldersByUniqueId[uniqueId]
end
function HandToolSystem:getHandToolHolderByClickBox(clickBoxNode)
    return clickBoxNode ~= nil and self.handToolHoldersByClickBox[clickBoxNode] or nil
end
function HandToolSystem:save(xmlFilename, usedModNames)
    local xmlFile = XMLFile.create("handToolsXML", xmlFilename, "handTools", HandToolSystem.savegameXMLSchema)
    if xmlFile ~= nil then
        self:saveToXML(self.handTools, xmlFile, usedModNames)
        xmlFile:delete()
    end
end
function HandToolSystem:saveToXML(handTools, xmlFile, usedModNames)
    if xmlFile ~= nil then
        local xmlIndex = 0
        for i, handTool in ipairs(handTools) do
            if handTool:getNeedsSaving() then
                self:saveHandToolToXML(handTool, xmlFile, xmlIndex, i, usedModNames)
                xmlIndex = xmlIndex + 1
            end
        end
        xmlFile:save(false, true)
    end
end
function HandToolSystem.saveHandToolToXML(_, handTool, xmlFile, index, _, usedModNames)
    local handToolKey = string.format("handTools.handTool(%d)", index)
    local modName = handTool.customEnvironment
    if modName ~= nil then
        if usedModNames ~= nil then
            usedModNames[modName] = modName
        end
        xmlFile:setValue(handToolKey .. "#modName", modName)
    end
    xmlFile:setValue(handToolKey .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(handTool.configFileName)))
    handTool:saveToXMLFile(xmlFile, handToolKey, usedModNames)
end
function HandToolSystem:load(xmlFilename, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
    self.savegameXMLFile = XMLFile.loadIfExists("handToolsXML", xmlFilename, HandToolSystem.savegameXMLSchema)
    if self.savegameXMLFile == nil then
        if asyncCallbackFunction ~= nil then
            asyncCallbackFunction(asyncCallbackObject, {}, HandToolLoadingState.OK, asyncCallbackArguments)
        end
    else
        self:loadFromXMLFile(self.savegameXMLFile, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
    end
end
function HandToolSystem:loadFromXMLFile(xmlFile, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
    self.loadedHandTools = {}
    self.handToolsToLoad = 0
    self.handToolLoadingState = nil
    self.asyncCallbackFunction = asyncCallbackFunction
    self.asyncCallbackObject = asyncCallbackObject
    self.asyncCallbackArguments = asyncCallbackArguments
    for _, key in xmlFile:iterator("handTools.handTool") do
        local key
        g_asyncTaskManager:addSubtask(function()
            -- upvalues: (copy) self, (copy) xmlFile, (copy) key
            self:loadHandToolFromXML(xmlFile, key)
        end)
    end
    if self.asyncCallbackFunction ~= nil then
        g_asyncTaskManager:addSubtask(function()
            -- upvalues: (copy) self
            if self.handToolsToLoad <= 0 then
                self.asyncCallbackFunction(self.asyncCallbackObject, self.loadedHandTools, HandToolLoadingState.OK, self.asyncCallbackArguments)
                self.asyncCallbackFunction = nil
                self.asyncCallbackObject = nil
                self.asyncCallbackArguments = nil
            end
        end)
    end
end
function HandToolSystem:loadHandToolFromXML(xmlFile, key)
    local filename = xmlFile:getValue(key .. "#filename")
    local storeItem = g_storeManager:getItemByXMLFilename((NetworkUtil.convertFromNetworkFilename(filename)))
    if storeItem == nil then
        return false
    end
    self.handToolsToLoad = self.handToolsToLoad + 1
    local data = HandToolLoadingData.new()
    data:setStoreItem(storeItem)
    data:setSavegameData({
        ["xmlFile"] = xmlFile,
        ["key"] = key
    })
    data:load(self.loadHandToolFinished, self)
    return true
end
function HandToolSystem:loadHandToolFinished(handTool, loadingState)
    if loadingState == HandToolLoadingState.OK then
        table.insert(self.loadedHandTools, handTool)
    else
        self.handToolLoadingState = self.handToolLoadingState or loadingState
    end
    self.handToolsToLoad = self.handToolsToLoad - 1
    if self.handToolsToLoad <= 0 and self.asyncCallbackFunction ~= nil then
        self.asyncCallbackFunction(self.asyncCallbackObject, self.loadedHandTools, self.handToolLoadingState or HandToolLoadingState.OK, self.asyncCallbackArguments)
        self.asyncCallbackFunction = nil
        self.asyncCallbackObject = nil
        self.asyncCallbackArguments = nil
        self.loadedHandTools = nil
        self.handToolLoadingState = nil
    end
end
function HandToolSystem:addPendingHandToolLoad(handTool)
    table.addElement(self.pendingHandTools, handTool)
end
function HandToolSystem:removePendingHandToolLoad(handTool)
    table.removeElement(self.pendingHandTools, handTool)
end
function HandToolSystem:getNumPendingHandTools()
    return #self.pendingHandTools
end
function HandToolSystem:canStartMission()
    for _, handTool in ipairs(self.handTools) do
        if not handTool:getIsSynchronized() then
            return false
        end
    end
    return #self.pendingHandTools <= 0
end
function HandToolSystem:consoleCommandPrintPendingLoadings()
    Logging.info("Pending HandTool Loadings:")
    for _, handTool in ipairs(self.pendingHandTools) do
        Logging.info("    - %s", handTool.configFileName or "Unknown")
        Logging.info("        LoadingState: %s", HandToolLoadingState.getName(handTool.loadingState))
        Logging.info("        LoadingStep: %s", SpecializationUtil.getLoadingStepName(handTool.loadingStep))
        Logging.info("        Num-Tasks: %d", #handTool.loadingTasks)
    end
    Logging.info("Pending HandTool:")
    for _, handTool in ipairs(self.handTools) do
        if not handTool:getIsSynchronized() then
            Logging.info("    - LoadingState: %s | LoadingStep: %s | %s", HandToolLoadingState.getName(handTool.loadingState), SpecializationUtil.getLoadingStepName(handTool.loadingStep), handTool.configFileName or "Unknown")
        end
    end
end
function HandToolSystem:consoleCommandReloadHandTool()
    if not g_currentMission:getIsServer() or g_currentMission.missionDynamicInfo.isMultiplayer then
        return "Error: Reloading only available in singleplayer!"
    end
    if self.isHandToolReloadRunning then
        return "Error: Reloading of hand tool already in progress!"
    end
    local player = g_localPlayer
    if player == nil then
        return "Error: No local player found!"
    end
    local handTool = player:getHeldHandTool()
    if handTool == nil then
        return "Error: No hand tool currently held! Hold a hand tool first."
    end
    local configFileName = handTool.configFileName
    local ownerFarmId = handTool:getOwnerFarmId()
    local storeItem = g_storeManager:getItemByXMLFilename(configFileName)
    local xmlFile = XMLFile.create("reloadHandToolXMLFile", "", "handTools", HandToolSystem.savegameXMLSchema)
    if xmlFile == nil then
        return "Error: Unable to create XML for saving hand tool state"
    end
    self:saveHandToolToXML(handTool, xmlFile, 0, 1, nil)
    xmlFile:save(false, true)
    self.handToolsByUniqueId[handTool:getUniqueId()] = nil
    handTool:delete()
    g_i3DManager:clearEntireSharedI3DFileCache(false)
    self.isHandToolReloadRunning = true
    local data = HandToolLoadingData.new()
    if storeItem == nil then
        data:setFilename(configFileName)
    else
        data:setStoreItem(storeItem)
    end
    data:setOwnerFarmId(ownerFarmId)
    data:setHolder(player)
    data:setSavegameData({
        ["xmlFile"] = xmlFile,
        ["key"] = "handTools.handTool(0)"
    })
    data:load(self.onReloadHandToolFinished, self, {
        ["xmlFile"] = xmlFile,
        ["player"] = player,
        ["configFileName"] = configFileName
    })
end
function HandToolSystem:onReloadHandToolFinished(handTool, loadingState, arguments)
    self.isHandToolReloadRunning = false
    arguments.xmlFile:delete()
    if loadingState == HandToolLoadingState.OK and handTool ~= nil then
        local player = arguments.player
        handTool.pendingHolder = nil
        handTool:setHolder(player)
        player:setCurrentHandTool(handTool)
        Logging.info("Hand tool \'%s\' reloaded successfully", arguments.configFileName)
    else
        Logging.error("Failed to reload hand tool \'%s\'!", arguments.configFileName)
    end
end