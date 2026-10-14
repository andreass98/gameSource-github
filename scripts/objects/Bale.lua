Bale = {}
Bale.INTERACTION_RADIUS = 3
Bale.NUM_BITS_VARIATION = 4
Bale.MAX_NUM_VARIATIONS = 2 ^ Bale.NUM_BITS_VARIATION
source("dataS/scripts/events/BaleOpenEvent.lua")
local Bale_mt = Class(Bale, MountableObject)
InitStaticObjectClass(Bale, "Bale")
g_xmlManager:addInitSchemaFunction(function()
    Bale.registerSavegameXMLPaths(ItemSystem.xmlSchemaSavegame, "items.item(?)")
end)
function Bale.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#uniqueId", "Unique id")
    schema:register(XMLValueType.STRING, basePath .. "#filename", "Path to bale xml file")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#position", "Bale position")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotation", "Bale rotation")
    schema:register(XMLValueType.FLOAT, basePath .. "#fillLevel", "Current bale fill level")
    schema:register(XMLValueType.STRING, basePath .. "#fillType", "Current bale fill type")
    schema:register(XMLValueType.INT, basePath .. "#variationIndex", "Current variation index")
    schema:register(XMLValueType.INT, basePath .. "#farmId", "Id of owner farm")
    schema:register(XMLValueType.STRING, basePath .. ".textures#wrapDiffuse", "Current wrap diffuse file")
    schema:register(XMLValueType.STRING, basePath .. ".textures#wrapNormal", "Current wrap normal file")
    schema:register(XMLValueType.BOOL, basePath .. ".fermentation#isFermenting", "Bale is fermenting")
    schema:register(XMLValueType.FLOAT, basePath .. ".fermentation#time", "Current fermentation time")
    schema:register(XMLValueType.FLOAT, basePath .. "#wrappingState", "Current wrapping state")
    schema:register(XMLValueType.VECTOR_3, basePath .. "#wrappingColor", "Wrapping color")
    schema:register(XMLValueType.FLOAT, basePath .. "#valueScale", "Bale value scale")
    schema:register(XMLValueType.BOOL, basePath .. "#isMissionBale", "Bale was produced in mission context", false)
end
function Bale.new(isServer, isClient, customMt)
    -- upvalues: (copy) Bale_mt
    local self = MountableObject.new(isServer, isClient, customMt or Bale_mt)
    self.forcedClipDistance = 300
    registerObjectClassName(self, "Bale")
    self.fillType = FillType.STRAW
    self.fillLevel = 0
    self.needsSaving = true
    self.variationIndex = 1
    self.supportsWrapping = false
    self.wrappingState = 0
    self.wrappingColor = { 1, 1, 1 }
    self.defaultMass = 0.25
    self.isFermenting = false
    self.fermentingPercentage = 0
    self.canBeSold = true
    self.allowPickup = true
    self.isMissionBale = false
    self.activatable = BaleActivatable.new(self)
    self.fillTypeDirtyFlag = self:getNextDirtyFlag()
    self.fillLevelDirtyFlag = self:getNextDirtyFlag()
    self.variationDirtyFlag = self:getNextDirtyFlag()
    self.texturesDirtyFlag = self:getNextDirtyFlag()
    self.wrapStateDirtyFlag = self:getNextDirtyFlag()
    self.wrapColorDirtyFlag = self:getNextDirtyFlag()
    self.fermentingDirtyFlag = self:getNextDirtyFlag()
    self.obstacleNodeId = nil
    self.sharedLoadRequestId = nil
    self.uniqueId = nil
    g_currentMission.slotSystem:addLimitedObject(SlotSystem.LIMITED_OBJECT_BALE, self)
    return self
end
function Bale:delete()
    if self.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
        self.sharedLoadRequestId = nil
    end
    self.meshes = {}
    self.tensionBeltMeshes = {}
    g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
    if self.isFermenting then
        g_baleManager:removeFermentation(self)
    end
    self:setBaleAIObstacle(false)
    g_currentMission.slotSystem:removeLimitedObject(SlotSystem.LIMITED_OBJECT_BALE, self)
    unregisterObjectClassName(self)
    g_currentMission.itemSystem:removeItem(self)
    Bale:superClass().delete(self)
end
function Bale:readUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            self:setFillType((streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)))
        end
        if streamReadBool(streamId) then
            self:setFillLevel(streamReadFloat32(streamId))
        end
        if streamReadBool(streamId) then
            self:setVariationIndex(streamReadUIntN(streamId, Bale.NUM_BITS_VARIATION) + 1)
        end
        if streamReadBool(streamId) then
            if streamReadBool(streamId) then
                self:setWrapTextures(NetworkUtil.convertFromNetworkFilename(streamReadString(streamId)), nil)
            end
            if streamReadBool(streamId) then
                self:setWrapTextures(nil, (NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))))
            end
        end
        if streamReadBool(streamId) then
            self:setWrappingState(streamReadUInt8(streamId) / 255, false)
        end
        if streamReadBool(streamId) then
            local fillType, g, b = Color.readStreamRGB(streamId)
            self:setColor(fillType, g, b)
        end
        if streamReadBool(streamId) then
            self.isFermenting = streamReadBool(streamId)
            self.fermentingPercentage = streamReadUInt8(streamId) / 255
        end
    end
    Bale:superClass().readUpdateStream(self, streamId, timestamp, connection)
end
function Bale:writeUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.fillTypeDirtyFlag) ~= 0) then
            streamWriteUIntN(streamId, self.fillType, FillTypeManager.SEND_NUM_BITS)
        end
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.fillLevelDirtyFlag) ~= 0) then
            streamWriteFloat32(streamId, self.fillLevel)
        end
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.variationDirtyFlag) ~= 0) then
            streamWriteUIntN(streamId, self.variationIndex - 1, Bale.NUM_BITS_VARIATION)
        end
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.texturesDirtyFlag) ~= 0) then
            if streamWriteBool(streamId, self.wrapDiffuse ~= nil) then
                streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.wrapDiffuse))
            end
            if streamWriteBool(streamId, self.wrapNormal ~= nil) then
                streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.wrapNormal))
            end
        end
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.wrapStateDirtyFlag) ~= 0) then
            streamWriteUInt8(streamId, (math.clamp(self.wrappingState * 255, 0, 255)))
        end
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.wrapColorDirtyFlag) ~= 0) then
            Color.writeStreamRGB(streamId, self.wrappingColor[1], self.wrappingColor[2], self.wrappingColor[3])
        end
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.fermentingDirtyFlag) ~= 0) then
            streamWriteBool(streamId, self.isFermenting)
            streamWriteUInt8(streamId, (math.clamp(self.fermentingPercentage * 255, 0, 255)))
        end
    end
    Bale:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
end
function Bale:readStream(streamId, connection)
    local baleTypeIndex = streamReadUIntN(streamId, BaleManager.SEND_NUM_BITS)
    local xmlFilename = g_baleManager:getBaleXMLFilenameByIndex(baleTypeIndex)
    if self.nodeId == 0 then
        self:loadFromConfigXML(xmlFilename)
    end
    self:setFillLevel((streamReadFloat32(streamId)))
    self:setFillType((streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)))
    self:setVariationIndex(streamReadUIntN(streamId, Bale.NUM_BITS_VARIATION) + 1)
    if streamReadBool(streamId) then
        self:setWrapTextures(NetworkUtil.convertFromNetworkFilename(streamReadString(streamId)), nil)
    end
    if streamReadBool(streamId) then
        self:setWrapTextures(nil, (NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))))
    end
    Bale:superClass().readStream(self, streamId, connection)
    g_currentMission.itemSystem:addItem(self)
    self:setWrappingState(streamReadUInt8(streamId) / 255, false)
    local wrapDiffuse, g, b = Color.readStreamRGB(streamId)
    self:setColor(wrapDiffuse, g, b)
    self.isFermenting = streamReadBool(streamId)
    if self.isFermenting then
        self.fermentingPercentage = streamReadUInt8(streamId) / 255
    else
        self.fermentingPercentage = 0
    end
end
function Bale:writeStream(streamId, connection)
    local baleTypeIndex = g_baleManager:getBaleTypeIndexByXMLFilename(self.xmlFilename) or 1
    streamWriteUIntN(streamId, baleTypeIndex, BaleManager.SEND_NUM_BITS)
    streamWriteFloat32(streamId, self.fillLevel)
    streamWriteUIntN(streamId, self.fillType, FillTypeManager.SEND_NUM_BITS)
    streamWriteUIntN(streamId, self.variationIndex - 1, Bale.NUM_BITS_VARIATION)
    if streamWriteBool(streamId, self.wrapDiffuse ~= nil) then
        streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.wrapDiffuse))
    end
    if streamWriteBool(streamId, self.wrapNormal ~= nil) then
        streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.wrapNormal))
    end
    Bale:superClass().writeStream(self, streamId, connection)
    streamWriteUInt8(streamId, (math.clamp(self.wrappingState * 255, 0, 255)))
    Color.writeStreamRGB(streamId, self.wrappingColor[1], self.wrappingColor[2], self.wrappingColor[3])
    if streamWriteBool(streamId, self.isFermenting) then
        streamWriteUInt8(streamId, (math.clamp(self.fermentingPercentage * 255, 0, 255)))
    end
end
function Bale:mount(object, node, x, y, z, rx, ry, rz)
    Bale:superClass().mount(self, object, node, x, y, z, rx, ry, rz)
    self:setBaleAIObstacle(false)
end
function Bale:unmount()
    if not Bale:superClass().unmount(self) then
        return false
    end
    self:setReducedComponentMass(false)
    self:setBaleAIObstacle(true)
    return true
end
function Bale:mountKinematic(object, node, x, y, z, rx, ry, rz)
    Bale:superClass().mountKinematic(self, object, node, x, y, z, rx, ry, rz)
    self:setBaleAIObstacle(false)
end
function Bale:unmountKinematic()
    if not Bale:superClass().unmountKinematic(self) then
        return false
    end
    self:setReducedComponentMass(false)
    self:setBaleAIObstacle(true)
    return true
end
function Bale:mountDynamic(object, objectActorId, jointNode, mountType, forceAcceleration)
    if not Bale:superClass().mountDynamic(self, object, objectActorId, jointNode, mountType, forceAcceleration) then
        return false
    end
    self:setBaleAIObstacle(false)
    return true
end
function Bale:unmountDynamic(isDelete)
    Bale:superClass().unmountDynamic(self, isDelete)
    self:setReducedComponentMass(false)
    self:setBaleAIObstacle(true)
end
function Bale:setBaleAIObstacle(isActive)
    if isActive and self.obstacleNodeId == nil then
        g_currentMission.aiSystem:addObstacle(self.nodeId, nil, nil, nil, nil, nil, nil, nil)
        self.obstacleNodeId = self.nodeId
    elseif not isActive and self.obstacleNodeId ~= nil then
        g_currentMission.aiSystem:removeObstacle(self.obstacleNodeId)
        self.obstacleNodeId = nil
    end
end
function Bale:createNode(i3dFilename)
    self.i3dFilename = i3dFilename
    local baleRoot, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
    self.sharedLoadRequestId = sharedLoadRequestId
    local baleId = getChildAt(baleRoot, 0)
    link(getRootNode(), baleId)
    delete(baleRoot)
    self:setNodeId(baleId)
end
function Bale:loadFromConfigXML(xmlFilename, x, y, z, rx, ry, rz, uniqueId)
    if xmlFilename == nil or not fileExists(xmlFilename) then
        Logging.error("Failed to load bale. XML file could not be found! (%s)", xmlFilename)
        return false
    end
    if g_baleManager:getBaleTypeIndexByXMLFilename(xmlFilename) == nil and g_iconGenerator == nil then
        Logging.error("Failed to load bale. Bale not correctly registered! (%s)", xmlFilename)
        return false
    end
    local xmlFile = XMLFile.load("TempBale", xmlFilename, BaleManager.baleXMLSchema)
    self.xmlFilename = xmlFilename
    self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(self.xmlFilename)
    self.i3dFilename = xmlFile:getValue("bale.filename")
    if self.i3dFilename ~= nil then
        self.i3dFilename = Utils.getFilename(self.i3dFilename, self.baseDirectory)
        self:createNode(self.i3dFilename)
        if x ~= nil and (y ~= nil and (z ~= nil and (rx ~= nil and (ry ~= nil and rz ~= nil)))) then
            setTranslation(self.nodeId, x, y, z)
            setRotation(self.nodeId, rx, ry, rz)
        end
        if not self:loadBaleAttributesFromXML(xmlFile) then
            Logging.error("Failed to load bale. Attributes could not be loaded. (%s)", xmlFilename)
            return false
        end
    end
    xmlFile:delete()
    if uniqueId ~= nil then
        self:setUniqueId(uniqueId)
    end
    g_currentMission.itemSystem:addItem(self)
    self:setBaleAIObstacle(true)
    return true
end
function Bale:loadBaleAttributesFromXML(xmlFile)
    self:setMountableObjectAttributes(xmlFile:getValue("bale.mountableObject#triggerNode", nil, self.nodeId), xmlFile:getValue("bale.mountableObject#forceAcceleration", 4), xmlFile:getValue("bale.mountableObject#forceLimitScale", 1), xmlFile:getValue("bale.mountableObject#axisFreeY", false), (xmlFile:getValue("bale.mountableObject#axisFreeX", false)))
    self.fillTypes = {}
    Bale.loadFillTypesFromXML(self.fillTypes, xmlFile, self.baseDirectory)
    self.variations = {}
    Bale.loadVariationsFromXML(self.variations, xmlFile, self.baseDirectory)
    self.isRoundbale = xmlFile:getValue("bale.size#isRoundbale", true)
    self.width = MathUtil.round(xmlFile:getValue("bale.size#width", 0), 2)
    self.height = MathUtil.round(xmlFile:getValue("bale.size#height", 0), 2)
    self.length = MathUtil.round(xmlFile:getValue("bale.size#length", 0), 2)
    self.diameter = MathUtil.round(xmlFile:getValue("bale.size#diameter", 0), 2)
    self.centerOffsetX = 0
    self.centerOffsetY = 0
    self.centerOffsetZ = 0
    self.uvId = xmlFile:getValue("bale.uvId", "DEFAULT")
    self.meshes, self.tensionBeltMeshes = Bale.loadVisualMeshesFromXML(self.nodeId, xmlFile, self.baseDirectory)
    return true
end
function Bale:getBaleMatchesSize(diameter, width, height, length)
    if self.isRoundbale then
        return diameter == self.diameter and width == self.width
    else
        return width == self.width and height == self.height and length == self.length
    end
end
function Bale:getSupportsWrapping()
    return self.supportsWrapping
end
function Bale:loadFromXMLFile(xmlFile, key, resetVehicles)
    local x, y, z = xmlFile:getValue(key .. "#position")
    local rx, ry, rz = xmlFile:getValue(key .. "#rotation")
    if x == nil or (y == nil or (z == nil or (rx == nil or (ry == nil or rz == nil)))) then
        return false
    end
    local xmlFilename = xmlFile:getValue(key .. "#filename")
    if xmlFilename == nil then
        return false
    end
    local attributes = NetworkUtil.convertFromNetworkFilename(xmlFilename)
    if not fileExists(attributes) then
        return false
    end
    local attributes = {}
    Bale.loadBaleAttributesFromXMLFile(attributes, xmlFile, key, resetVehicles)
    if not self:loadFromConfigXML(attributes, x, y, z, rx, ry, rz, attributes.uniqueId) then
        return false
    end
    self:applyBaleAttributes(attributes)
    return true
end
function Bale.loadBaleAttributesFromXMLFile(attributes, xmlFile, key, _)
    attributes.xmlFilename = NetworkUtil.convertFromNetworkFilename(xmlFile:getValue(key .. "#filename"))
    attributes.farmId = xmlFile:getValue(key .. "#farmId", AccessHandler.EVERYONE)
    attributes.fillLevel = xmlFile:getValue(key .. "#fillLevel")
    attributes.fillTypeName = xmlFile:getValue(key .. "#fillType")
    attributes.variationIndex = xmlFile:getValue(key .. "#variationIndex")
    attributes.fillType = g_fillTypeManager:getFillTypeIndexByName(attributes.fillTypeName)
    local wrapDiffuse = xmlFile:getValue(key .. ".textures#wrapDiffuse")
    if wrapDiffuse ~= nil then
        attributes.wrapDiffuse = NetworkUtil.convertFromNetworkFilename(wrapDiffuse)
    end
    local wrapNormal = xmlFile:getValue(key .. ".textures#wrapNormal")
    if wrapNormal ~= nil then
        attributes.wrapNormal = NetworkUtil.convertFromNetworkFilename(wrapNormal)
    end
    attributes.isFermenting = xmlFile:getValue(key .. ".fermentation#isFermenting", false)
    attributes.fermentationTime = xmlFile:getValue(key .. ".fermentation#time", 0)
    attributes.wrappingState = xmlFile:getValue(key .. "#wrappingState", 0)
    attributes.wrappingColor = xmlFile:getValue(key .. "#wrappingColor", nil, true) or { 1, 1, 1 }
    attributes.isMissionBale = xmlFile:getValue(key .. "#isMissionBale", false)
    attributes.uniqueId = xmlFile:getValue(key .. "#uniqueId", nil)
    return true
end
function Bale:getBaleAttributes()
    local attributes = {
        ["xmlFilename"] = self.xmlFilename,
        ["farmId"] = self:getOwnerFarmId(),
        ["fillLevel"] = self.fillLevel,
        ["fillType"] = self.fillType,
        ["variationIndex"] = self.variationIndex,
        ["wrapDiffuse"] = self.wrapDiffuse,
        ["wrapNormal"] = self.wrapNormal,
        ["supportsWrapping"] = self.supportsWrapping,
        ["wrappingState"] = self.wrappingState,
        ["wrappingColor"] = self.wrappingColor,
        ["isMissionBale"] = self.isMissionBale,
        ["isFermenting"] = self.isFermenting
    }
    if self.isFermenting then
        attributes.fermentationTime = g_baleManager:getFermentationTime(self) or 0
    end
    return attributes
end
function Bale.saveBaleAttributesToXMLFile(attributes, xmlFile, key)
    xmlFile:setValue(key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(attributes.xmlFilename)))
    xmlFile:setValue(key .. "#fillLevel", attributes.fillLevel)
    xmlFile:setValue(key .. "#fillType", g_fillTypeManager:getFillTypeNameByIndex(attributes.fillType))
    xmlFile:setValue(key .. "#variationIndex", attributes.variationIndex)
    xmlFile:setValue(key .. "#farmId", attributes.farmId)
    xmlFile:setValue(key .. "#isMissionBale", attributes.isMissionBale)
    xmlFile:setValue(key .. "#wrappingState", attributes.wrappingState)
    xmlFile:setValue(key .. "#wrappingColor", attributes.wrappingColor[1], attributes.wrappingColor[2], attributes.wrappingColor[3])
    if attributes.wrapDiffuse ~= nil then
        xmlFile:setValue(key .. ".textures#wrapDiffuse", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(attributes.wrapDiffuse)))
    end
    if attributes.wrapNormal ~= nil then
        xmlFile:setValue(key .. ".textures#wrapNormal", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(attributes.wrapNormal)))
    end
    if attributes.isFermenting then
        xmlFile:setValue(key .. ".fermentation#isFermenting", true)
        xmlFile:setValue(key .. ".fermentation#time", attributes.fermentationTime)
    end
end
function Bale:applyBaleAttributes(attributes)
    self:setOwnerFarmId(attributes.farmId or AccessHandler.EVERYONE)
    self:setFillLevel(attributes.fillLevel or self.fillLevel)
    if attributes.fillTypeName == nil then
        if attributes.fillType ~= nil then
            self:setFillType(attributes.fillType)
        end
    else
        self:setFillType(g_fillTypeManager:getFillTypeIndexByName(attributes.fillTypeName) or self.fillType)
    end
    self:setVariationIndex(attributes.variationIndex or self.variationIndex)
    self:setWrapTextures(attributes.wrapDiffuse, attributes.wrapNormal)
    self:setWrappingState(attributes.wrappingState, false)
    self:setColor(unpack(attributes.wrappingColor))
    self.isMissionBale = Utils.getNoNil(attributes.isMissionBale, self.isMissionBale)
    if self.isServer and attributes.isFermenting then
        local fillTypeIndex = self:getFillTypeInfo(self.fillType)
        if fillTypeIndex ~= nil and fillTypeIndex.fermenting ~= nil then
            g_baleManager:registerFermentation(self, attributes.fermentationTime, self.isMissionBale and 0 or fillTypeIndex.fermenting.time * 86400000)
            self.isFermenting = true
            self:raiseDirtyFlags(self.fermentingDirtyFlag)
        end
    end
    return true
end
function Bale:saveToXMLFile(xmlFile, key)
    local x, y, z = getTranslation(self.nodeId)
    local xRot, yRot, zRot = getRotation(self.nodeId)
    xmlFile:setValue(key .. "#uniqueId", self.uniqueId)
    xmlFile:setValue(key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.xmlFilename)))
    xmlFile:setValue(key .. "#position", x, y, z)
    xmlFile:setValue(key .. "#rotation", xRot, yRot, zRot)
    xmlFile:setValue(key .. "#fillLevel", self.fillLevel)
    xmlFile:setValue(key .. "#fillType", g_fillTypeManager:getFillTypeNameByIndex(self.fillType))
    xmlFile:setValue(key .. "#variationIndex", self.variationIndex)
    xmlFile:setValue(key .. "#farmId", self:getOwnerFarmId())
    xmlFile:setValue(key .. "#isMissionBale", self.isMissionBale)
    xmlFile:setValue(key .. "#wrappingState", self.wrappingState)
    xmlFile:setValue(key .. "#wrappingColor", self.wrappingColor[1], self.wrappingColor[2], self.wrappingColor[3])
    if self.wrapDiffuse ~= nil then
        xmlFile:setValue(key .. ".textures#wrapDiffuse", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.wrapDiffuse)))
    end
    if self.wrapNormal ~= nil then
        xmlFile:setValue(key .. ".textures#wrapNormal", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.wrapNormal)))
    end
    if self.isFermenting then
        xmlFile:setValue(key .. ".fermentation#isFermenting", true)
        xmlFile:setValue(key .. ".fermentation#time", g_baleManager:getFermentationTime(self))
    end
end
function Bale:setNeedsSaving(needsSaving)
    self.needsSaving = needsSaving
end
function Bale:getNeedsSaving()
    if not self.needsSaving then
        return false
    end
    local _, y, _ = getTranslation(self.nodeId)
    return y > -90
end
function Bale:getAutoLoadIsSupported()
    return true
end
function Bale:getAutoLoadIsAllowed()
    return self:getAllowPickup()
end
function Bale:getAutoLoadSize()
    return self.width, self.isRoundbale and self.diameter or self.height, self.isRoundbale and self.diameter or self.length
end
function Bale:autoLoad(autoLoader, node, posX, posZ, sizeX, sizeZ)
    if self.dynamicMountType == MountableObject.MOUNT_TYPE_KINEMATIC then
        self:unmountKinematic()
    end
    self:mountKinematic(autoLoader, node, posX + sizeX * 0.5, self.isRoundbale and self.diameter * 0.5 or self.height * 0.5, posZ + sizeZ * 0.5, 0, self.isRoundbale and 1.5707963267948966 or 0, 0)
    return true
end
function Bale:getAutoLoadBoundingBox()
    local x, y, z = getWorldTranslation(self.nodeId)
    local dirX, dirY, dirZ = localDirectionToWorld(self.nodeId, 0, 0, 1)
    local upX, upY, upZ = localDirectionToWorld(self.nodeId, 0, 1, 0)
    return x, y, z, dirX, dirY, dirZ, upX, upY, upZ, self.width * 0.5, self.isRoundbale and self.diameter * 0.5 or self.height * 0.5, self.isRoundbale and self.diameter * 0.5 or self.length * 0.5
end
function Bale:getValue()
    local pricePerLiter = g_currentMission.economyManager:getPricePerLiter(self.fillType)
    return self.fillLevel * pricePerLiter
end
function Bale:getMass()
    return entityExists(self.nodeId or 0) and getMass(self.nodeId) or 0
end
function Bale:getDefaultMass()
    return self.defaultMass
end
function Bale:getFillType()
    return self.fillType
end
function Bale:setReducedComponentMass(state)
    if state then
        setMass(self.nodeId, 0.1)
    else
        setMass(self.nodeId, self.defaultMass)
    end
end
function Bale:getAllowComponentMassReduction()
    return self.defaultMass > 0.1
end
function Bale:setFillType(fillTypeIndex, fillBale)
    Bale.setFillTypeTextures(self.meshes, self.fillTypes, fillTypeIndex)
    self.fillType = fillTypeIndex
    self.supportsWrapping = false
    local fillTypeInfo = self:getFillTypeInfo(self.fillType)
    if fillTypeInfo ~= nil then
        self.supportsWrapping = fillTypeInfo.supportsWrapping
        setMass(self.nodeId, fillTypeInfo.mass)
        self.defaultMass = fillTypeInfo.mass
        if self.isServer then
            if fillTypeInfo.forceAcceleration ~= nil then
                self:setMountableObjectAttributes(nil, fillTypeInfo.forceAcceleration, self.dynamicMountForceLimitScale, self.dynamicMountSingleAxisFreeY, self.dynamicMountSingleAxisFreeX)
            end
            if fillTypeInfo.fermenting ~= nil and not fillTypeInfo.fermenting.requiresWrapping then
                if self.isFermenting then
                    g_baleManager:removeFermentation(self)
                end
                g_baleManager:registerFermentation(self, 0, fillTypeInfo.fermenting.time * 86400000)
                self.isFermenting = true
                self:raiseDirtyFlags(self.fermentingDirtyFlag)
            end
        end
        if fillBale == true then
            self:setFillLevel(fillTypeInfo.capacity)
        end
    end
    local maxTime = Bale.updateVisualMeshVisibility
    maxTime(self.meshes, self.fillType, self.wrappingState ~= 0)
    Bale.updateVisualMeshWrappingState(self.meshes, self.wrappingState, self.wrappingColor)
    if self.isServer then
        self:raiseDirtyFlags(self.fillTypeDirtyFlag)
    end
end
function Bale:setVariationIndex(variationIndex)
    local variation = self.variations[variationIndex or 1]
    if variation ~= nil then
        self.variationIndex = variationIndex
        Bale.setVariationTextures(self.meshes, self.variations, variation.id)
        if self.isServer then
            self:raiseDirtyFlags(self.variationDirtyFlag)
        end
    end
end
function Bale:setVariationId(variationId)
    if variationId == nil then
        self:setVariationIndex(1)
        return true
    end
    for variationIndex, variation in ipairs(self.variations) do
        if string.lower(variation.id) == string.lower(variationId) then
            self:setVariationIndex(variationIndex)
            return true
        end
    end
    return false
end
function Bale:getVariationId()
    if #self.variations == 0 then
        return "NONE"
    end
    local variation = self.variations[self.variationIndex]
    return variation == nil and "NONE" or variation.id
end
function Bale:getCapacity()
    local fillTypeInfo = self:getFillTypeInfo(self.fillType)
    return fillTypeInfo == nil and 0 or fillTypeInfo.capacity
end
function Bale:getFillLevel()
    return self.fillLevel
end
function Bale:setFillLevel(fillLevel)
    self.fillLevel = fillLevel
    if self.isServer then
        self:raiseDirtyFlags(self.fillLevelDirtyFlag)
    end
end
function Bale:getFillTypeInfo(_)
    local i = 1
    for i = i, #self.fillTypes do
        if self.fillTypes[i].fillTypeIndex == self.fillType then
            return self.fillTypes[i]
        end
    end
    return nil
end
function Bale:setCanBeSold(canBeSold)
    self.canBeSold = canBeSold
end
function Bale:getCanBeSold()
    return self.canBeSold
end
function Bale:setWrappingState(wrappingState, updateFermentation)
    if self.isServer and self.wrappingState ~= wrappingState then
        self:raiseDirtyFlags(self.wrapStateDirtyFlag)
    end
    self.wrappingState = wrappingState
    local i = 1
    local fillTypeInfo = #self.meshes
    local maxTime = 1
    for i = i, fillTypeInfo, maxTime do
        local meshData = self.meshes[i]
        if not meshData.supportsWrapping then
            visibility = false
            if wrappingState ~= 0 then
                goto l8
            end
        end
        local visibility = meshData.fillTypeVisibility
        ::l8::
        setVisibility(meshData.node, visibility)
        if visibility then
            setShaderParameter(meshData.node, "wrappingState", self.wrappingState, 0, 0, 0, false)
        end
    end
    if self.isServer and (updateFermentation ~= false and self.wrappingState >= 1) then
        local fillTypeInfo = self:getFillTypeInfo(self.fillType)
        if fillTypeInfo ~= nil and (fillTypeInfo.fermenting ~= nil and (fillTypeInfo.fermenting.requiresWrapping and not self.isFermenting)) then
            g_baleManager:registerFermentation(self, 0, self.isMissionBale and 0 or fillTypeInfo.fermenting.time * 86400000)
            self.isFermenting = true
            self:raiseDirtyFlags(self.fermentingDirtyFlag)
        end
    end
    if wrappingState > 0 then
        g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
    else
        g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
    end
end
function Bale:setWrapTextures(diffuse, normal)
    self.wrapDiffuse = diffuse or self.wrapDiffuse
    self.wrapNormal = normal or self.wrapNormal
    local i = 1
    for i = i, #self.meshes do
        local meshData = self.meshes[i]
        local materialId = getMaterial(meshData.node, 0)
        if self.wrapDiffuse ~= nil then
            if textureFileExists(self.wrapDiffuse) then
                materialId = setMaterialCustomMapFromFile(materialId, "wrapDiffuseMap", self.wrapDiffuse, false, true, false)
            else
                Logging.warning("Unknown bale wrapping texture \'%s\'. Using default texture.", self.wrapDiffuse)
            end
        end
        if self.wrapNormal ~= nil then
            if textureFileExists(self.wrapNormal) then
                materialId = setMaterialCustomMapFromFile(materialId, "wrapNormalMap", self.wrapNormal, false, false, false)
            else
                Logging.warning("Unknown bale wrapping texture \'%s\'. Using default texture.", self.wrapNormal)
            end
        end
        setMaterial(meshData.node, materialId, 0)
        setShaderParameter(meshData.node, "wrappingState", self.wrappingState, 0, 0, 0, false)
        setShaderParameter(meshData.node, "colorScale", self.wrappingColor[1], self.wrappingColor[2], self.wrappingColor[3], 1, false)
    end
    if self.isServer and (diffuse ~= nil or normal ~= nil) then
        self:raiseDirtyFlags(self.texturesDirtyFlag)
    end
end
function Bale:setColor(r, g, b)
    r = r or 1
    g = g or 1
    b = b or 1
    if r ~= self.wrappingColor[1] or (g ~= self.wrappingColor[2] or b ~= self.wrappingColor[3]) then
        if self.isServer then
            self:raiseDirtyFlags(self.wrapColorDirtyFlag)
        end
        self.wrappingColor[1] = r
        self.wrappingColor[2] = g
        self.wrappingColor[3] = b
        local i = 1
        for i = i, #self.meshes do
            local meshData = self.meshes[i]
            if getHasShaderParameter(meshData.node, "colorScale") then
                setShaderParameter(meshData.node, "colorScale", r, g, b, 1, false)
            end
        end
    end
end
function Bale:setIsMissionBale(state)
    self.isMissionBale = state
end
function Bale:getMeshNodes()
    return self.tensionBeltMeshes
end
function Bale:getSupportsTensionBelts()
    return true
end
function Bale:getTensionBeltNodeId()
    return self.nodeId
end
function Bale:getBaleSupportsBaleLoader()
    return true
end
function Bale:getAllowPickup()
    return self.allowPickup
end
function Bale:getAdditionalMountingDistance()
    return self.isRoundbale and 0 or self.height * 0.5
end
function Bale:getIsFermenting()
    return self.isFermenting
end
function Bale:getFermentingPercentage()
    return not self.isFermenting and 0 or self.fermentingPercentage
end
function Bale:onFermentationUpdate(percentage)
    self.fermentingPercentage = percentage
    self:raiseDirtyFlags(self.fermentingDirtyFlag)
end
function Bale:onFermentationEnd()
    if self.isServer and self.isFermenting then
        local fillTypeInfo = self:getFillTypeInfo(self.fillType)
        if fillTypeInfo ~= nil and fillTypeInfo.fermenting ~= nil then
            self:setFillType(fillTypeInfo.fermenting.outputFillTypeIndex)
        end
        self.isFermenting = false
        self:raiseDirtyFlags(self.fermentingDirtyFlag)
    end
end
function Bale:getCanBeOpened()
    if self.wrappingState <= 0 then
        return false
    elseif self.isFermenting then
        return false
    else
        return self.dynamicMountType == MountableObject.MOUNT_TYPE_NONE
    end
end
function Bale:getInteractionPosition()
    if not g_localPlayer:getIsInVehicle() then
        return getWorldTranslation(g_localPlayer.rootNode)
    end
end
function Bale:getCanInteract()
    if not g_currentMission.accessHandler:canPlayerAccess(self) then
        return false
    end
    local px, py, pz = self:getInteractionPosition()
    if px == nil then
        return false
    end
    local x, y, z = getWorldTranslation(self.nodeId)
    return MathUtil.vector3Length(x - px, y - py, z - pz) <= Bale.INTERACTION_RADIUS
end
function Bale:open()
    self:setWrappingState(0)
end
function Bale:resetDetailVisibilityCut()
    local i = 1
    for i = i, #self.meshes do
        local meshData = self.meshes[i]
        if getHasShaderParameter(meshData.node, "visibilityXZ") then
            setShaderParameter(meshData.node, "visibilityXZ", 5, -5, 5, -5, false)
        end
    end
end
function Bale:setDetailVisibilityCutNode(node, axis, direction)
    local i = 1
    for i = i, #self.meshes do
        Bale.setBaleMeshVisibilityCut(self.meshes[i].node, node, axis, direction, false)
    end
end
function Bale.setBaleMeshVisibilityCut(baleMesh, node, axis, direction, recursively)
    if getHasShaderParameter(baleMesh, "visibilityXZ") then
        local sx = nil
        local sy = nil
        local sz = nil
        local x, _, z = localToLocal(node, baleMesh, 0, 0, 0)
        if axis == 1 then
            if direction > 0 then
                z = nil
                sx = x
            else
                z = sw
                sy = x
            end
        elseif direction > 0 then
            sz = z
        end
        setShaderParameter(baleMesh, "visibilityXZ", sx, sy, sz, z, false)
    end
    if recursively then
        local sz = 1
        local sw = getNumOfChildren(baleMesh)
        for sz = sz, sw do
            Bale.setBaleMeshVisibilityCut(getChildAt(baleMesh, sz - 1), node, axis, direction, recursively)
        end
    end
end
function Bale:doDensityMapItemAreaUpdate(func, target, ...)
    if self.isRoundbale then
        local x, _, z = getWorldTranslation(self.nodeId)
        func(target, x + self.width * 0.4 + 0.25, z + self.width * 0.4 + 0.25, x - self.width * 0.4 + 0.25, z + self.width * 0.4 + 0.25, x + self.width * 0.4 + 0.25, z - self.width * 0.4 + 0.25, ...)
    else
        local _, z, sizeFactor = localToWorld(self.nodeId, self.width * 0.4, self.height * 0.4, self.length * 0.4)
        local x0, z0, x1 = localToWorld(self.nodeId, -self.width * 0.4, -self.height * 0.4, self.length * 0.4)
        local z1, x2, z2 = localToWorld(self.nodeId, self.width * 0.4, self.height * 0.4, -self.length * 0.4)
        func(target, _ + 0.25, sizeFactor + 0.25, x0 + 0.25, x1 + 0.25, z1 + 0.25, z2 + 0.25, ...)
    end
end
function Bale:showInfo(box)
    local fillType = self:getFillType()
    local fillLevel = self:getFillLevel()
    box:addLine(g_fillTypeManager:getFillTypeByIndex(fillType).title, g_i18n:formatVolume(fillLevel, 0))
    if self:getIsFermenting() then
        box:addLine(g_i18n:getText("info_fermenting"), string.format("%d%%", self:getFermentingPercentage() * 100))
    end
    box:addLine(g_i18n:getText("infohud_mass"), g_i18n:formatMass(self:getMass()))
end
function Bale:setUniqueId(uniqueId)
    self.uniqueId = uniqueId
end
function Bale:getUniqueId()
    return self.uniqueId
end
function Bale.createDummyBale(xmlFilename, fillTypeIndex, variationId, wrappingState, wrappingColor)
    local xmlFile = XMLFile.load("TempBale", xmlFilename, BaleManager.baleXMLSchema)
    local baleId = nil
    local sharedLoadRequestId = nil
    local i3dFilename = xmlFile:getValue("bale.filename")
    if i3dFilename ~= nil then
        local _, baseDirectory = Utils.getModNameAndBaseDirectory(xmlFilename)
        local meshes = Utils.getFilename(i3dFilename, baseDirectory)
        local meshes
        meshes, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(meshes, false, false)
        if meshes ~= 0 then
            baleId = getChildAt(meshes, 0)
            setRigidBodyType(baleId, RigidBodyType.NONE)
            unlink(baleId)
            wrappingState = wrappingState or 0
            local meshes = Bale.loadVisualMeshesFromXML(baleId, xmlFile, baseDirectory)
            local fillTypes = {}
            Bale.loadFillTypesFromXML(fillTypes, xmlFile, baseDirectory)
            Bale.setFillTypeTextures(meshes, fillTypes, fillTypeIndex)
            local variations = {}
            Bale.loadVariationsFromXML(variations, xmlFile, baseDirectory)
            Bale.setVariationTextures(meshes, variations, variationId)
            Bale.updateVisualMeshVisibility(meshes, fillTypeIndex, wrappingState > 0)
            Bale.updateVisualMeshWrappingState(meshes, wrappingState, wrappingColor)
            delete(meshes)
        end
    end
    xmlFile:delete()
    return baleId, sharedLoadRequestId
end
function Bale.loadTexturesFromXML(target, xmlFile, key, baseDirectory)
    target.diffuseFilename = xmlFile:getValue(key .. ".diffuse#filename", nil, baseDirectory)
    target.diffuseUseFillTypeArray = xmlFile:getValue(key .. ".diffuse#useFillTypeArray", false)
    target.normalFilename = xmlFile:getValue(key .. ".normal#filename", nil, baseDirectory)
    target.normalUseFillTypeArray = xmlFile:getValue(key .. ".normal#useFillTypeArray", false)
    target.alphaFilename = xmlFile:getValue(key .. ".alpha#filename", nil, baseDirectory)
    target.baleNormalFilename = xmlFile:getValue(key .. ".baleNormal#filename", nil, baseDirectory)
    target.netWrapDiffuseFilename = xmlFile:getValue(key .. ".netWrapDiffuse#filename", nil, baseDirectory)
    target.netWrapNormalFilename = xmlFile:getValue(key .. ".netWrapNormal#filename", nil, baseDirectory)
end
function Bale.loadFillTypesFromXML(fillTypes, xmlFile, baseDirectory)
    xmlFile:iterate("bale.fillTypes.fillType", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) baseDirectory, (copy) fillTypes
        local fillTypeName = xmlFile:getValue(key .. "#name")
        local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
        if fillTypeIndex ~= nil then
            local fillTypeInfo = {
                ["fillTypeIndex"] = fillTypeIndex,
                ["capacity"] = xmlFile:getValue(key .. "#capacity", 1000),
                ["mass"] = xmlFile:getValue(key .. "#mass", 500) / 1000,
                ["forceAcceleration"] = xmlFile:getValue(key .. "#forceAcceleration"),
                ["supportsWrapping"] = xmlFile:getValue(key .. "#supportsWrapping", false),
                ["materialName"] = xmlFile:getValue(key .. "#materialName"),
                ["alphaMaterialName"] = xmlFile:getValue(key .. "#alphaMaterialName")
            }
            Bale.loadTexturesFromXML(fillTypeInfo, xmlFile, key, baseDirectory)
            local outputFillTypeName = xmlFile:getValue(key .. ".fermenting#outputFillType")
            local outputFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(outputFillTypeName)
            if outputFillTypeIndex ~= nil then
                fillTypeInfo.fermenting = {}
                fillTypeInfo.fermenting.outputFillTypeIndex = outputFillTypeIndex
                fillTypeInfo.fermenting.requiresWrapping = xmlFile:getValue(key .. ".fermenting#requiresWrapping", true)
                fillTypeInfo.fermenting.time = xmlFile:getValue(key .. ".fermenting#time", 0)
            end
            table.insert(fillTypes, fillTypeInfo)
        end
    end)
end
function Bale.loadVariationsFromXML(variations, xmlFile, baseDirectory)
    for _, key in xmlFile:iterator("bale.variations.variation") do
        local id = xmlFile:getValue(key .. "#id")
        if id ~= nil then
            local variation = {
                ["id"] = id
            }
            Bale.loadTexturesFromXML(variation, xmlFile, key, baseDirectory)
            table.insert(variations, variation)
        end
    end
    if #variations == 0 then
        table.insert(variations, {
            ["id"] = "DEFAULT"
        })
    end
end
function Bale.setFillTypeTextures(meshes, fillTypes, fillTypeIndex)
    local i = 1
    for i = i, #fillTypes do
        local fillTypeInfo = fillTypes[i]
        if fillTypeInfo.fillTypeIndex == fillTypeIndex then
            for _, meshData in ipairs(meshes) do
                local materialName = fillTypeInfo.materialName
                if meshData.isAlphaMesh then
                    materialName = fillTypeInfo.alphaMaterialName
                end
                if fillTypeInfo.materialName ~= nil then
                    local materialId = g_materialManager:getBaseMaterialByName(materialName)
                    if materialId == nil then
                        Logging.warning("Unable to find bale material \'%s\'", materialName)
                    else
                        setMaterial(meshData.node, materialId, 0)
                    end
                end
                Bale.setTexturesForNode(meshData.node, fillTypeInfo)
                if getHasShaderParameter(meshData.node, "fillTypeId") then
                    local materialId = g_fillTypeManager:getTextureArrayIndexByFillTypeIndex(fillTypeInfo.fillTypeIndex)
                    if materialId ~= nil then
                        setShaderParameter(meshData.node, "fillTypeId", materialId - 1, 0, 0, 0, true)
                    end
                end
            end
            return
        end
    end
end
function Bale.setVariationTextures(meshes, variations, id)
    if type(id) == "number" then
        local variation = variations[id]
    end
    local i = 1
    local variation = #variations
    for i = i, variation do
        if variations[i].id == id then
            for _, meshData in ipairs(meshes) do
                Bale.setTexturesForNode(meshData.node, variations[i])
            end
            return
        end
    end
    if #variations > 0 then
        for _, meshData in ipairs(meshes) do
            Bale.setTexturesForNode(meshData.node, variations[1])
        end
    end
end
function Bale.setTexturesForNode(nodeId, textureData)
    if getHasClassId(nodeId, ClassIds.SHAPE) then
        local materialId = getMaterial(nodeId, 0)
        if materialId ~= 0 and getMaterialCustomShaderFilename(materialId):contains("wrapBaleShader") then
            if textureData.diffuseFilename == nil then
                if textureData.diffuseUseFillTypeArray then
                    g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(nodeId, g_terrainNode, true, false, false)
                    materialId = getMaterial(nodeId, 0)
                end
            else
                materialId = setMaterialDiffuseMapFromFile(materialId, textureData.diffuseFilename, true, true, false)
            end
            if textureData.normalFilename == nil then
                if textureData.normalUseFillTypeArray then
                    g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(nodeId, g_terrainNode, false, true, false)
                    materialId = getMaterial(nodeId, 0)
                end
            else
                materialId = setMaterialNormalMapFromFile(materialId, textureData.normalFilename, true, false, false)
            end
            if textureData.alphaFilename ~= nil then
                materialId = setMaterialCustomMapFromFile(materialId, "alphaMap", textureData.alphaFilename, true, false, false)
            end
            if textureData.baleNormalFilename ~= nil then
                materialId = setMaterialCustomMapFromFile(materialId, "baleNormalMap", textureData.baleNormalFilename, true, false, false)
            end
            if textureData.netWrapDiffuseFilename ~= nil then
                materialId = setMaterialCustomMapFromFile(materialId, "netWrapDiffuseMap", textureData.netWrapDiffuseFilename, true, true, false)
            end
            if textureData.netWrapNormalFilename ~= nil then
                materialId = setMaterialCustomMapFromFile(materialId, "netWrapNormalMap", textureData.netWrapNormalFilename, true, false, false)
            end
            setMaterial(nodeId, materialId, 0)
        end
    end
end
function Bale.loadVisualMeshesFromXML(rootNode, xmlFile, _)
    local meshes = {}
    local tensionBeltMeshes = {}
    xmlFile:iterate("bale.baleMeshes.baleMesh", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) rootNode, (copy) tensionBeltMeshes, (copy) meshes
        local meshData = {
            ["node"] = xmlFile:getValue(key .. "#node", nil, rootNode),
            ["supportsWrapping"] = xmlFile:getValue(key .. "#supportsWrapping", true)
        }
        local fillTypeNames = xmlFile:getValue(key .. "#fillTypes")
        meshData.fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames)
        meshData.fillTypeVisibility = true
        meshData.isTensionBeltMesh = xmlFile:getValue(key .. "#isTensionBeltMesh", false)
        if meshData.isTensionBeltMesh then
            table.insert(tensionBeltMeshes, meshData.node)
        end
        meshData.isAlphaMesh = xmlFile:getValue(key .. "#isAlphaMesh", false)
        table.insert(meshes, meshData)
    end)
    return meshes, tensionBeltMeshes
end
function Bale.updateVisualMeshVisibility(meshes, fillTypeIndex, isWrapped)
    local i = 1
    for i = i, #meshes do
        local meshData = meshes[i]
        if meshData.fillTypes ~= nil and #meshData.fillTypes > 0 then
            setVisibility(meshData.node, false)
            meshData.fillTypeVisibility = false
            local j = 1
            for j = j, #meshData.fillTypes do
                if meshData.fillTypes[j] == fillTypeIndex then
                    if meshData.supportsWrapping or not isWrapped then
                        setVisibility(meshData.node, true)
                    end
                    meshData.fillTypeVisibility = true
                    break
                end
            end
        end
    end
end
function Bale.updateVisualMeshWrappingState(meshes, wrappingState, wrappingColor)
    local i = 1
    for i = i, #meshes do
        local node = meshes[i].node
        setShaderParameter(node, "wrappingState", wrappingState, 0, 0, 0, false)
        if wrappingState > 0 and getHasShaderParameter(node, "colorScale") then
            if wrappingColor == nil or #wrappingColor ~= 3 then
                setShaderParameter(node, "colorScale", 0.85, 0.85, 0.85, 1, false)
            else
                setShaderParameter(node, "colorScale", wrappingColor[1], wrappingColor[2], wrappingColor[3], 1, false)
            end
        end
    end
end
BaleActivatable = {}
local BaleActivatable_mt = Class(BaleActivatable)
function BaleActivatable.new(bale)
    -- upvalues: (copy) BaleActivatable_mt
    local self = setmetatable({}, BaleActivatable_mt)
    self.bale = bale
    self.activateText = g_i18n:getText("action_cutBale")
    return self
end
function BaleActivatable:getIsActivatable()
    return self.bale:getCanInteract() and self.bale:getCanBeOpened() and true or false
end
function BaleActivatable:getHasAccess(farmId)
    return g_currentMission.accessHandler:canFarmAccessOtherId(farmId, self.bale:getOwnerFarmId())
end
function BaleActivatable:getDistance(posX, _, posZ)
    if self.bale.nodeId == 0 then
        return math.huge
    end
    local x, _, z = getWorldTranslation(self.bale.nodeId)
    return MathUtil.vector2Length(posX - x, posZ - z)
end
function BaleActivatable:run()
    if g_server == nil then
        g_client:getServerConnection():sendEvent(BaleOpenEvent.new(self.bale))
    else
        self.bale:open()
    end
end