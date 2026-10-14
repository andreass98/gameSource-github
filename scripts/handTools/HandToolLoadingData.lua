HandToolLoadingData = {}
local HandToolLoadingData_mt = Class(HandToolLoadingData)
function HandToolLoadingData.new(customMt)
    -- upvalues: (copy) HandToolLoadingData_mt
    local self = setmetatable({}, customMt or HandToolLoadingData_mt)
    self.isValid = false
    self.storeItem = nil
    self.handToolData = nil
    self.ownerFarmId = AccessHandler.EVERYONE
    self.savegameData = nil
    self.isSaved = true
    self.canBeDropped = true
    self.isRegistered = true
    self.forceServer = false
    self.loadingHandTool = nil
    self.loadingState = nil
    return self
end
function HandToolLoadingData:setFilename(filename)
    if fileExists(filename) then
        self.handToolData = {
            ["xmlFilename"] = filename
        }
    else
        Logging.error("Unable to find handtool config for \'%s\'", filename)
        printCallstack()
    end
end
function HandToolLoadingData:setStoreItem(storeItem)
    if storeItem == nil then
        Logging.error("No store item defined")
        printCallstack()
    else
        self.storeItem = storeItem
        self.handToolData = {
            ["xmlFilename"] = storeItem.xmlFilename
        }
    end
    self.isValid = storeItem ~= nil
end
function HandToolLoadingData:setOwnerFarmId(ownerFarmId)
    self.ownerFarmId = ownerFarmId
end
function HandToolLoadingData:setIsRegistered(isRegistered)
    self.isRegistered = isRegistered
end
function HandToolLoadingData:setHolder(holder)
    self.holder = holder
end
function HandToolLoadingData:setIsSaved(isSaved)
    self.isSaved = isSaved
end
function HandToolLoadingData:setCanBeDropped(canBeDropped)
    self.canBeDropped = canBeDropped
end
function HandToolLoadingData:setSavegameData(savegameData)
    self.savegameData = savegameData
end
function HandToolLoadingData:load(callback, callbackTarget, callbackArguments)
    self.callback = callback
    self.callbackTarget = callbackTarget
    self.callbackArguments = callbackArguments
    local handToolData = self.handToolData
    handToolData.handToolType, handToolData.handToolClass = g_handToolTypeManager:getObjectTypeFromXML(handToolData.xmlFilename)
    self.loadingState = HandToolLoadingState.OK
    if handToolData.handToolType == nil or handToolData.handToolClass == nil then
        self.loadingState = HandToolLoadingState.ERROR
        if self.callback ~= nil then
            self.callback(self.callbackTarget, nil, self.loadingState, self.callbackArguments)
            self.callback = nil
            self.callbackTarget = nil
            self.callbackArguments = nil
        end
    else
        self:loadHandTool(handToolData)
    end
end
function HandToolLoadingData:loadHandTool(handToolData)
    local isServer = self.forceServer or g_currentMission:getIsServer()
    local isClient = self.forceServer or g_currentMission:getIsClient()
    local handTool = handToolData.handToolClass.new(isServer, isClient)
    handTool:setFilename(handToolData.xmlFilename)
    handTool:setType(handToolData.handToolType)
    handTool:setLoadCallback(self.onHandToolLoaded, self, nil)
    handTool:load(self)
    self.loadingHandTool = handTool
end
function HandToolLoadingData:loadHandToolOnClient(handTool, callback, _)
    local handToolData = self.handToolData
    local handToolType, _ = g_handToolTypeManager:getObjectTypeFromXML(handToolData.xmlFilename)
    if handToolType ~= nil then
        handTool:setFilename(handToolData.xmlFilename)
        handTool:setType(handToolType)
        handTool:setLoadCallback(callback, self, nil)
        handTool:load(self)
    end
end
function HandToolLoadingData:cancelLoading()
    self.canceledLoading = true
    if self.loadingHandTool ~= nil then
        self.loadingHandTool:delete()
    end
    if self.callback ~= nil then
        self.callback(self.callbackTarget, nil, HandToolLoadingState.CANCELED, self.callbackArguments)
        self.callback = nil
        self.callbackTarget = nil
        self.callbackArguments = nil
    end
end
function HandToolLoadingData:onHandToolLoaded(handTool, loadingState)
    if not self.canceledLoading then
        if loadingState == HandToolLoadingState.OK then
            g_messageCenter:publish(MessageType.HANDTOOL_LOADED, handTool)
        else
            self.loadingState = loadingState
            handTool:delete()
        end
        if self.callback ~= nil then
            self.callback(self.callbackTarget, handTool, self.loadingState, self.callbackArguments)
            self.callback = nil
            self.callbackTarget = nil
            self.callbackArguments = nil
        end
    end
end