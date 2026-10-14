HandToolHolder = {}
local HandToolHolder_mt = Class(HandToolHolder, Object)
function HandToolHolder.registerXMLPaths(schema, basePath)
    schema:setXMLSharedRegistration("HandToolHolder", basePath)
    schema:register(XMLValueType.STRING, basePath .. ".handToolHolder(?).holder#type", "The type of hand tool that this holder accepts")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".handToolHolder(?).holder#node", "The name of the node specifying the orientation of the held tool")
    schema:register(XMLValueType.STRING, basePath .. ".handToolHolder(?).holder#dummyFilename", "The filename of a dummy object that will be visible while player is in range")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".handToolHolder(?).clickBoxes.clickBox(?)#node", "The name of the clickbox node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".handToolHolder(?).trigger#node", "Player activation trigger")
    schema:register(XMLValueType.STRING, basePath .. ".handToolHolder(?).spawnedHandToolFilename", "The filepath of the hand tool that is spawned. If this is not nil, then only the spawned tool can be put into and taken out of this holder")
    schema:register(XMLValueType.L10N_STRING, basePath .. ".handToolHolder(?).actions#takeText", "The name of the localization string displayed when the player can take the tool")
    schema:register(XMLValueType.L10N_STRING, basePath .. ".handToolHolder(?).actions#storeText", "The name of the localization string displayed when the player can store a tool")
    schema:resetXMLSharedRegistration("HandToolHolder", basePath)
end
function HandToolHolder.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#uniqueId", nil, false)
end
function HandToolHolder.new(parent, isServer, isClient, customMt)
    -- upvalues: (copy) HandToolHolder_mt
    local self = Object.new(isServer, isClient, customMt or HandToolHolder_mt)
    self.parent = parent
    self.name = ""
    self.handTool = nil
    self.isPlayerInRange = false
    return self
end
function HandToolHolder:load(xmlFile, key, callback, callbackTarget, callbackArgs, components, i3dMappings, baseDirectory, customEnv)
    self.holderType = xmlFile:getValue(key .. ".holder#type", nil)
    self.holderNode = xmlFile:getValue(key .. ".holder#node", nil, components, i3dMappings)
    local dummyFilename = xmlFile:getValue(key .. ".holder#dummyFilename")
    if dummyFilename ~= nil then
        local spawnedHandToolFilename = Utils.getFilename(dummyFilename, baseDirectory)
        self.dummySharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(spawnedHandToolFilename, true, true, self.onDummyHandToolI3DLoaded, self, nil)
    end
    self.clickBoxes = {}
    for nodeIndex, clickBoxNodeKey in xmlFile:iterator(key .. ".clickBoxes.clickBox") do
        local clickBox = xmlFile:getValue(clickBoxNodeKey .. "#node", nil, components, i3dMappings)
        if clickBox ~= nil then
            table.insert(self.clickBoxes, clickBox)
        end
    end
    self.activationTrigger = xmlFile:getValue(key .. ".trigger#node", nil, components, i3dMappings)
    if self.activationTrigger then
        addTrigger(self.activationTrigger, "onPlayerCallback", self)
    end
    self.callback = callback
    self.callbackTarget = callbackTarget
    self.callbackArgs = callbackArgs
    local spawnedHandToolFilename = xmlFile:getValue(key .. ".spawnedHandToolFilename")
    if spawnedHandToolFilename ~= nil then
        local data = Utils.getFilename(spawnedHandToolFilename, baseDirectory)
        self.spawnedHandToolFilename = data
        local data = HandToolLoadingData.new()
        data:setFilename(data)
        data:setOwnerFarmId(self:getOwnerFarmId())
        data:setIsRegistered(false)
        data:load(self.onSpawnedHandToolLoaded, self)
        self.pendingHandToolData = data
        self.isHandToolPending = true
    end
    local data = xmlFile:getValue(key .. ".actions#takeText", "action_takeHandTool", customEnv, true)
    local storeText = xmlFile:getValue(key .. ".actions#storeText", "action_returnHandTool", customEnv, true)
    self.activatable = HandToolHolderActivatable.new(self, data, storeText, self.activationTrigger ~= nil)
    if not self.isHandToolPending then
        self:onFinishedLoading()
    end
end
function HandToolHolder:onDummyHandToolI3DLoaded(i3dNode, _, _)
    if i3dNode ~= 0 then
        self.dummyHandTool = getChildAt(i3dNode, 0)
        link(self.holderNode, self.dummyHandTool)
        delete(i3dNode)
        self:updateDummyHandTool()
    end
end
function HandToolHolder:onSpawnedHandToolLoaded(handTool, _)
    self.pendingHandToolData = nil
    if handTool == nil then
        Logging.error("Could not load spawned hand tool for HandToolHolder!")
        self.callback(self.callbackTarget, nil, self.callbackArgs)
    else
        self.spawnedHandTool = handTool
        handTool:setAttachedHolder(self)
        handTool:setHolder(self, true)
        if self.isRegistered then
            handTool:register(true)
        end
        if string.isNilOrWhitespace(self.spawnedHandToolFilename) then
            self.spawnedHandToolFilename = handTool.xmlFilename
        end
        self:onFinishedLoading()
    end
end
function HandToolHolder:onFinishedLoading()
    self.callback(self.callbackTarget, self, self.callbackArgs)
    g_currentMission.handToolSystem:addHandToolHolder(self)
    if self.activationTrigger == nil then
        g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
    end
end
function HandToolHolder:delete()
    local handTool = self.handTool
    self.storeCallback = nil
    self.pickupCallback = nil
    if self.pendingHandToolData ~= nil then
        self.pendingHandToolData:cancelLoading()
        self.pendingHandToolData = nil
    end
    if handTool ~= nil and handTool ~= self.spawnedHandTool then
        handTool:setHolder(nil)
    end
    if self.spawnedHandTool ~= nil then
        self.spawnedHandTool:setHolder(nil, true)
        self.spawnedHandTool:delete()
    end
    if self.activationTrigger ~= nil then
        removeTrigger(self.activationTrigger)
        self.activationTrigger = nil
    end
    if self.dummySharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.dummySharedLoadRequestId)
        self.dummySharedLoadRequestId = nil
    end
    self.parent = nil
    g_currentMission.handToolSystem:removeHandToolHolder(self)
    g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
    HandToolHolder:superClass().delete(self)
end
function HandToolHolder:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. "#uniqueId", self.uniqueId)
end
function HandToolHolder:loadFromXMLFile(xmlFile, key)
    local uniqueId = xmlFile:getValue(key .. "#uniqueId", nil)
    if uniqueId ~= nil then
        self:setUniqueId(uniqueId)
    end
end
function HandToolHolder:writeStream(streamId, connection)
    if not connection:getIsServer() then
        local spawnedHandTool = self.spawnedHandTool
        if streamWriteBool(streamId, spawnedHandTool ~= nil) then
            NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spawnedHandTool))
            spawnedHandTool:postWriteStream(streamId, connection)
            g_server:registerObjectInStream(connection, spawnedHandTool)
        end
    end
end
function HandToolHolder:readStream(streamId, connection, _)
    if connection:getIsServer() and streamReadBool(streamId) then
        local spawnedHandTool = self.spawnedHandTool
        local spawnedHandToolId = NetworkUtil.readNodeObjectId(streamId)
        spawnedHandTool:postReadStream(streamId, connection)
        g_client:finishRegisterObject(spawnedHandTool, spawnedHandToolId)
    end
end
function HandToolHolder:register(alreadySent)
    HandToolHolder:superClass().register(self, alreadySent)
    if self.spawnedHandTool ~= nil and not self.spawnedHandTool.isRegistered then
        self.spawnedHandTool:register(true)
    end
end
function HandToolHolder:getUniqueId()
    return self.uniqueId
end
function HandToolHolder:setUniqueId(uniqueId)
    self.uniqueId = uniqueId
end
function HandToolHolder:getHolderName()
    return self.name
end
function HandToolHolder:setHolderName(name)
    self.name = name
end
function HandToolHolder:getHandTool()
    return self.handTool
end
function HandToolHolder:getSpawnedHandTool()
    return self.spawnedHandTool
end
function HandToolHolder:getSpawnsHandTool()
    return self.spawnedHandToolFilename ~= nil
end
function HandToolHolder:getHolderNodePair(handTool)
    if handTool.getHolsterNodeByType == nil then
        return nil, nil
    else
        local handToolHolderNode = handTool:getHolsterNodeByType(self.holderType)
        if handToolHolderNode == nil then
            return nil, nil
        else
            return self.holderNode, handToolHolderNode
        end
    end
end
function HandToolHolder:getCanPickupHandToolFromMenu(handTool)
    return true
end
function HandToolHolder:getCanPickupHandTool(handTool)
    if self.handTool ~= nil then
        return false
    end
    if handTool == nil or handTool.spec_storable == nil then
        return false
    end
    if self:getSpawnsHandTool() then
        local handToolHolderNode = self:getSpawnedHandTool() == handTool
        return handToolHolderNode
    end
    local handToolHolderNode = handTool:getHolsterNodeByType(self.holderType)
    local sameFarm = handTool:getOwnerFarmId() == self:getOwnerFarmId()
    if handToolHolderNode == nil then
        sameFarm = false
    end
    return sameFarm
end
function HandToolHolder:onPickupHandTool(handTool)
    if handTool == nil then
        return false
    end
    if not self:getCanPickupHandTool(handTool) then
        return false
    end
    local holderNode, handToolHolderNode = self:getHolderNodePair(handTool)
    if holderNode == nil or handToolHolderNode == nil then
        return false
    end
    self.handTool = handTool
    if self.storeCallback ~= nil then
        self.storeCallback(handTool)
    end
    HandToolUtil.linkAndTransformRelativeToParent(handTool.rootNode, handToolHolderNode, holderNode)
    if handTool.graphicalNode ~= handTool.rootNode then
        setTranslation(handTool.graphicalNode, 0, 0, 0)
        setRotation(handTool.graphicalNode, 0, 0, 0)
    end
    self:updateDummyHandTool()
    return true
end
function HandToolHolder:setPlayerInRange(isInRange)
    self.isPlayerInRange = isInRange
    self:updateDummyHandTool()
end
function HandToolHolder:updateDummyHandTool()
    if self.dummyHandTool ~= nil then
        local isVisible = self.isPlayerInRange
        if isVisible then
            isVisible = self.handTool ~= nil
        end
        setVisibility(self.dummyHandTool, isVisible)
    end
end
function HandToolHolder:onDropHandTool(handTool)
    if handTool ~= nil and handTool == self.handTool then
        unlink(handTool.rootNode)
        self.handTool = nil
        if self.pickupCallback ~= nil then
            self.pickupCallback(handTool)
        end
        self:updateDummyHandTool()
        return handTool
    end
end
function HandToolHolder:drawDebug()
    if self.handTool == nil then
        DebugGizmo.renderAtNode(self.holderNode)
    else
        local holderNode, toolNode = self:getHolderNodePair(self:getHandTool())
        DebugGizmo.renderAtNode(holderNode)
        DebugGizmo.renderAtNode(toolNode)
    end
end
function HandToolHolder:setOwnerFarmId(farmId, noEventSend)
    HandToolHolder:superClass().setOwnerFarmId(self, farmId, noEventSend)
    if self.spawnedHandTool ~= nil then
        self.spawnedHandTool:setOwnerFarmId(farmId, true)
    end
end
function HandToolHolder:setStoreCallback(storeCallback)
    self.storeCallback = storeCallback
end
function HandToolHolder:setPickupCallback(pickupCallback)
    self.pickupCallback = pickupCallback
end
function HandToolHolder:onPlayerCallback(_, otherId, onEnter, onLeave, _)
    if (onEnter or onLeave) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
        if onEnter then
            g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
            self:setPlayerInRange(true)
            return
        end
        g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
        self:setPlayerInRange(false)
    end
end