source("dataS/scripts/placeables/specializations/events/PlaceableDoghouseFoodBowlStateEvent.lua")
source("dataS/scripts/placeables/specializations/activatables/DoghouseActivatable.lua")
PlaceableDoghouse = {}
function PlaceableDoghouse.prerequisitesPresent(specializations)
    return true
end
function PlaceableDoghouse.initSpecialization()
    g_placeableConfigurationManager:addConfigurationType("dogHouse", g_i18n:getText("configuration_doghouse"), "dogHouse", PlaceableConfigurationItem)
end
function PlaceableDoghouse.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "dogInteractionTriggerCallback", PlaceableDoghouse.dogInteractionTriggerCallback)
    SpecializationUtil.registerFunction(placeableType, "isDoghouseRegistered", PlaceableDoghouse.isDoghouseRegistered)
    SpecializationUtil.registerFunction(placeableType, "registerDoghouseToMission", PlaceableDoghouse.registerDoghouseToMission)
    SpecializationUtil.registerFunction(placeableType, "unregisterDoghouseToMission", PlaceableDoghouse.unregisterDoghouseToMission)
    SpecializationUtil.registerFunction(placeableType, "setFoodBowlState", PlaceableDoghouse.setFoodBowlState)
    SpecializationUtil.registerFunction(placeableType, "getDog", PlaceableDoghouse.getDog)
    SpecializationUtil.registerFunction(placeableType, "getSpawnNode", PlaceableDoghouse.getSpawnNode)
    SpecializationUtil.registerFunction(placeableType, "onPreviewDogLoaded", PlaceableDoghouse.onPreviewDogLoaded)
end
function PlaceableDoghouse.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableDoghouse.setOwnerFarmId)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "canBuy", PlaceableDoghouse.canBuy)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getCanBePlacedAt", PlaceableDoghouse.getCanBePlacedAt)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getNeedHourChanged", PlaceableDoghouse.getNeedHourChanged)
end
function PlaceableDoghouse.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableDoghouse)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableDoghouse)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableDoghouse)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableDoghouse)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableDoghouse)
    SpecializationUtil.registerEventListener(placeableType, "onHourChanged", PlaceableDoghouse)
end
function PlaceableDoghouse.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Doghouse")
    local function addDogSchema(key)
        -- upvalues: (copy) schema
        schema:register(XMLValueType.NODE_INDEX, key .. ".dog#node", "Dog link node")
        schema:register(XMLValueType.NODE_INDEX, key .. ".dog#previewNode", "Dog preview link node")
        schema:register(XMLValueType.INT, key .. ".dog#tileUIndex", "Dog tile index U")
        schema:register(XMLValueType.INT, key .. ".dog#tileVIndex", "Dog tile index V")
        schema:register(XMLValueType.STRING, key .. ".dog#xmlFilename", "Dog xml filename")
        schema:register(XMLValueType.NODE_INDEX, key .. ".nameplate#node", "Name plate node")
        schema:register(XMLValueType.NODE_INDEX, key .. ".ball#node", "Ball node")
        schema:register(XMLValueType.STRING, key .. ".ball#filename", "Ball 3d file")
        schema:register(XMLValueType.NODE_INDEX, key .. ".playerInteractionTrigger#node", "Interaction trigger node")
        schema:register(XMLValueType.NODE_INDEX, key .. ".bowl#foodNode", "Food node in bowl")
        SoundManager.registerSampleXMLPaths(schema, key .. ".bowl", "fillSound")
    end
    addDogSchema(basePath .. ".dogHouse")
    addDogSchema(basePath .. ".dogHouse.dogHouseConfigurations.dogHouseConfiguration(?)")
    schema:setXMLSpecializationType()
end
function PlaceableDoghouse.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Doghouse")
    Dog.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType()
end
function PlaceableDoghouse:onLoad(_)
    local spec = self.spec_doghouse
    local xmlFile = self.xmlFile
    local isValid = true
    local dogHouseConfigurationId = Utils.getNoNil(self.configurations.dogHouse, 1)
    local configKey = string.format("placeable.dogHouse.dogHouseConfigurations.dogHouseConfiguration(%d)", dogHouseConfigurationId - 1)
    local configKey = not xmlFile:hasProperty(configKey) and "placeable.dogHouse" or configKey
    spec.spawnNode = xmlFile:getValue(configKey .. ".dog#node", nil, self.components, self.i3dMappings)
    if spec.spawnNode == nil then
        Logging.xmlError(xmlFile, "Could not load dog spawn node!")
        isValid = false
    end
    local isConstructionPreview = self.propertyState == PlaceablePropertyState.CONSTRUCTION_PREVIEW
    local tileUIndex = xmlFile:getInt(configKey .. ".dog#tileUIndex", 0)
    local tileVIndex = xmlFile:getInt(configKey .. ".dog#tileVIndex", 0)
    if self.isServer and (isValid and not isConstructionPreview) then
        local posX, posY, posZ = getWorldTranslation(spec.spawnNode)
        local xmlFilename = Utils.getFilename(xmlFile:getValue(configKey .. ".dog#xmlFilename"), self.baseDirectory)
        local dog = Dog.new(self.isServer, self.isClient)
        dog:setOwnerFarmId(self:getOwnerFarmId(), true)
        if dog:load(self, xmlFilename, posX, posY, posZ) then
            dog:setTextureTileIndices(tileUIndex, tileVIndex)
            dog:register()
            spec.dog = dog
        else
            isValid = false
            Logging.xmlWarning(xmlFile, "Could not load dog!")
        end
    end
    if isValid then
        spec.namePlateNode = xmlFile:getValue(configKey .. ".nameplate#node", nil, self.components, self.i3dMappings)
        spec.ballSpawnNode = xmlFile:getValue(configKey .. ".ball#node", nil, self.components, self.i3dMappings)
        if self.isServer and not isConstructionPreview then
            local posX = Utils.getFilename(xmlFile:getValue(configKey .. ".ball#filename"), self.baseDirectory)
            local posY, posZ, xmlFilename = getWorldTranslation(spec.ballSpawnNode)
            local dog, ry, rz = getWorldRotation(spec.ballSpawnNode)
            spec.dogBall = DogBall.new(self.isServer, self.isClient)
            spec.dogBall:setOwnerFarmId(self:getOwnerFarmId(), true)
            spec.dogBall:load(posX, posY, posZ, xmlFilename, dog, ry, rz, self)
            spec.dogBall:register()
        end
        if isConstructionPreview then
            spec.dogPreviewLinkNode = xmlFile:getValue(configKey .. ".dog#previewNode", nil, self.components, self.i3dMappings)
            local posX = Utils.getFilename(xmlFile:getValue(configKey .. ".dog#xmlFilename"), self.baseDirectory)
            local posY = XMLFile.load("dog", posX)
            local posZ = Utils.getFilename(posY:getString("dog.asset#filename"), self.baseDirectory)
            local xmlFilename = posY:getInt("dog.asset.texture#numTilesU", 1)
            local dog = posY:getInt("dog.asset.texture#numTilesV", 1)
            posY:delete()
            local rz = {
                ["loadingTask"] = self:createLoadingTask(spec),
                ["tileUIndex"] = tileUIndex,
                ["tileVIndex"] = tileVIndex,
                ["numTilesU"] = xmlFilename,
                ["numTilesV"] = dog
            }
            spec.dogPreviewSharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(posZ, true, false, self.onPreviewDogLoaded, self, rz)
        end
        spec.triggerNode = xmlFile:getValue(configKey .. ".playerInteractionTrigger#node", nil, self.components, self.i3dMappings)
        if spec.triggerNode ~= nil then
            addTrigger(spec.triggerNode, "dogInteractionTriggerCallback", self)
        end
        spec.foodNode = xmlFile:getValue(configKey .. ".bowl#foodNode", nil, self.components, self.i3dMappings)
        if spec.foodNode == nil then
            Logging.xmlWarning(xmlFile, "Missing bowl food node in \'placeable.dogHouse.bowl#foodNode\'!")
        else
            setVisibility(spec.foodNode, false)
            if g_client ~= nil then
                spec.foodFillSample = g_soundManager:loadSampleFromXML(xmlFile, configKey .. ".bowl", "fillSound", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings)
            end
        end
        spec.activatable = DoghouseActivatable.new(self)
    else
        SpecializationUtil.removeEventListener(self, "onDelete", PlaceableDoghouse)
        SpecializationUtil.removeEventListener(self, "onFinalizePlacement", PlaceableDoghouse)
        SpecializationUtil.removeEventListener(self, "onWriteStream", PlaceableDoghouse)
        SpecializationUtil.removeEventListener(self, "onReadStream", PlaceableDoghouse)
        SpecializationUtil.removeEventListener(self, "onHourChanged", PlaceableDoghouse)
    end
end
function PlaceableDoghouse:onDelete()
    local spec = self.spec_doghouse
    g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    self:unregisterDoghouseToMission()
    if self.isServer then
        if spec.dogBall ~= nil and not spec.dogBall.isDeleted then
            spec.dogBall:delete()
            spec.dogBall = nil
        end
        if spec.dog ~= nil and not spec.dog.isDeleted then
            spec.dog:delete()
            spec.dog = nil
        end
    end
    if spec.triggerNode ~= nil then
        removeTrigger(spec.triggerNode)
    end
    if spec.foodFillSample ~= nil then
        g_soundManager:deleteSample(spec.foodFillSample)
        spec.foodFillSample = nil
    end
    if spec.dogPreviewSharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(spec.dogPreviewSharedLoadRequestId)
    end
end
function PlaceableDoghouse:onFinalizePlacement()
    local spec = self.spec_doghouse
    if self.isServer and spec.dog ~= nil then
        spec.dog:finalizePlacement()
    end
    self:registerDoghouseToMission()
end
function PlaceableDoghouse:onReadStream(streamId, connection)
    if connection:getIsServer() then
        local spec = self.spec_doghouse
        spec.dog = NetworkUtil.readNodeObject(streamId)
        if spec.dog ~= nil then
            spec.dog.spawner = self
        end
        if spec.foodNode ~= nil then
            setVisibility(spec.foodNode, streamReadBool(streamId))
        end
    end
end
function PlaceableDoghouse:onWriteStream(streamId, connection)
    if not connection:getIsServer() then
        local spec = self.spec_doghouse
        NetworkUtil.writeNodeObject(streamId, spec.dog)
        if spec.foodNode ~= nil then
            streamWriteBool(streamId, getVisibility(spec.foodNode))
        end
    end
end
function PlaceableDoghouse:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_doghouse
    if spec.dog ~= nil then
        spec.dog:loadFromXMLFile(xmlFile, key)
    end
end
function PlaceableDoghouse:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_doghouse
    if spec.dog ~= nil then
        spec.dog:saveToXMLFile(xmlFile, key, usedModNames)
    end
end
function PlaceableDoghouse:onPreviewDogLoaded(node, _, args)
    if node == 0 or node == nil then
        self:finishLoadingTask(args.loadingTask)
    else
        link(self.spec_doghouse.dogPreviewLinkNode or self.rootNode, node)
        setShaderParameterRecursive(node, "atlasInvSizeAndOffsetUV", 1 / args.numTilesU, 1 / args.numTilesV, args.tileUIndex / args.numTilesU, args.tileVIndex / args.numTilesV, false)
        self:finishLoadingTask(loadingTask)
    end
end
function PlaceableDoghouse:dogInteractionTriggerCallback(_, otherId, onEnter, onLeave, _)
    local spec = self.spec_doghouse
    if spec.dog ~= nil and (g_localPlayer ~= nil and (otherId == g_localPlayer.rootNode and g_localPlayer.farmId == self:getOwnerFarmId())) then
        if onEnter then
            g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
            return
        end
        if onLeave then
            g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
        end
    end
end
function PlaceableDoghouse:isDoghouseRegistered()
    return g_currentMission:getDoghouse(self:getOwnerFarmId()) ~= nil
end
function PlaceableDoghouse:registerDoghouseToMission()
    if self:isDoghouseRegistered() then
        return false
    end
    g_currentMission.doghouses[self] = self
    return true
end
function PlaceableDoghouse:unregisterDoghouseToMission()
    g_currentMission.doghouses[self] = nil
    return true
end
function PlaceableDoghouse:setOwnerFarmId(superFunc, farmId, noEventSend)
    superFunc(self, farmId, noEventSend)
    if self.isServer then
        local spec = self.spec_doghouse
        if spec.dog ~= nil then
            spec.dog:setOwnerFarmId(farmId, noEventSend)
        end
        if spec.dogBall ~= nil then
            spec.dogBall:setOwnerFarmId(farmId, noEventSend)
        end
    end
end
function PlaceableDoghouse:setFoodBowlState(isFilled, noEventSend)
    local spec = self.spec_doghouse
    if spec.foodNode ~= nil then
        PlaceableDoghouseFoodBowlStateEvent.sendEvent(self, isFilled, noEventSend)
        setVisibility(spec.foodNode, isFilled)
        if isFilled and spec.dog ~= nil then
            spec.dog:onFoodBowlFilled(spec.foodNode)
            if spec.foodFillSample ~= nil then
                g_soundManager:playSample(spec.foodFillSample)
            end
        end
    end
end
function PlaceableDoghouse:getDog()
    return self.spec_doghouse.dog
end
function PlaceableDoghouse:getSpawnNode()
    return self.spec_doghouse.spawnNode
end
function PlaceableDoghouse:getCanBePlacedAt(superFunc, x, y, z, farmId)
    if self:isDoghouseRegistered() then
        return false, g_i18n:getText("warning_onlyOneOfThisItemAllowedPerFarm")
    else
        return superFunc(self, x, y, z, farmId)
    end
end
function PlaceableDoghouse:canBuy(superFunc)
    local canBuy, warning = superFunc(self)
    if canBuy then
        if self:isDoghouseRegistered() then
            return false, g_i18n:getText("warning_onlyOneOfThisItemAllowedPerFarm")
        else
            return true, nil
        end
    else
        return false, warning
    end
end
function PlaceableDoghouse:getNeedHourChanged(superFunc)
    return true
end
function PlaceableDoghouse:onHourChanged()
    self:setFoodBowlState(false, true)
end