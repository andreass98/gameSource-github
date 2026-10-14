WoodContainer = {}
source("dataS/scripts/vehicles/specializations/events/WoodContainerWrongLengthEvent.lua")
function WoodContainer.prerequisitesPresent(specializations)
    return true
end
function WoodContainer.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("woodContainer", g_i18n:getText("shop_configuration"), "woodContainer", VehicleConfigurationItem)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("WoodContainer")
    WoodContainer.registerXMLPaths(schema, "vehicle.woodContainer")
    WoodContainer.registerXMLPaths(schema, "vehicle.woodContainer.woodContainerConfigurations.woodContainerConfiguration(?)")
    schema:register(XMLValueType.INT, "vehicle.woodContainer.sounds#numLogs", "Number of logs filled in the container", 1)
    SoundManager.registerSampleXMLPaths(schema, "vehicle.woodContainer.sounds", "load")
    schema:setXMLSpecializationType()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).woodContainer#woodQualityVolume", "Volume including the quality factors")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).woodContainer#woodQualityTotalVolume", "Volume excluding the quality factors")
end
function WoodContainer.registerXMLPaths(schema, baseKey)
    schema:register(XMLValueType.FLOAT, baseKey .. "#foldMinLimit", "Min. fold anim time to fill the container", 0)
    schema:register(XMLValueType.FLOAT, baseKey .. "#foldMaxLimit", "Max. fold anim time to fill the container", 1)
    schema:register(XMLValueType.INT, baseKey .. "#fillUnitIndex", "Index of fill unit", 1)
    schema:register(XMLValueType.FLOAT, baseKey .. "#targetLength", "Optimal length of trees (has the highest value)", 12)
    schema:register(XMLValueType.NODE_INDEX, baseKey .. "#triggerNode", "Tree trigger node")
    schema:register(XMLValueType.STRING, baseKey .. ".pushAnimation#name", "Animation that is played as soon as something is loaded into the container")
    schema:register(XMLValueType.FLOAT, baseKey .. ".pushAnimation#speedScale", "Animation speed", 1)
end
function WoodContainer.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getPalletUnloadTriggerExtraSellPrice", WoodContainer.getPalletUnloadTriggerExtraSellPrice)
    SpecializationUtil.registerFunction(vehicleType, "getIsWoodContainerFillingAllowed", WoodContainer.getIsWoodContainerFillingAllowed)
    SpecializationUtil.registerFunction(vehicleType, "onWoodContainerTriggerCallback", WoodContainer.onWoodContainerTriggerCallback)
end
function WoodContainer.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getInfoBoxTitle", WoodContainer.getInfoBoxTitle)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addFillUnitFillLevel", WoodContainer.addFillUnitFillLevel)
end
function WoodContainer.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", WoodContainer)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", WoodContainer)
    SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", WoodContainer)
end
function WoodContainer:onLoad(savegame)
    local spec = self.spec_woodContainer
    local configurationId = Utils.getNoNil(self.configurations.woodContainer, 1)
    local configKey = string.format("vehicle.woodContainer.woodContainerConfigurations.woodContainerConfiguration(%d)", configurationId - 1)
    local configKey = not self.xmlFile:hasProperty(configKey) and "vehicle.woodContainer" or configKey
    spec.foldMinLimit = self.xmlFile:getValue(configKey .. "#foldMinLimit", 0)
    spec.foldMaxLimit = self.xmlFile:getValue(configKey .. "#foldMaxLimit", 1)
    spec.fillUnitIndex = self.xmlFile:getValue(configKey .. "#fillUnitIndex", 1)
    spec.targetLength = self.xmlFile:getValue(configKey .. "#targetLength", 12)
    spec.triggerNode = self.xmlFile:getValue(configKey .. "#triggerNode", nil, self.components, self.i3dMappings)
    if self.isServer and spec.triggerNode ~= nil then
        addTrigger(spec.triggerNode, "onWoodContainerTriggerCallback", self)
    end
    spec.woodQualityVolume = 0
    spec.woodQualityTotalVolume = 0
    spec.pushAnimation = {}
    spec.pushAnimation.name = self.xmlFile:getValue(configKey .. ".pushAnimation#name")
    spec.pushAnimation.speedScale = self.xmlFile:getValue(configKey .. ".pushAnimation#speedScale", 1)
    spec.samples = {}
    if self.isClient then
        spec.soundNumLogs = self.xmlFile:getValue("vehicle.woodContainer.sounds#numLogs", 1)
        spec.soundLastNumLogs = 0
        spec.samples.load = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.woodContainer.sounds", "load", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    spec.texts = {}
    spec.texts.warningTransportTreesCannotBeLoaded = g_i18n:getText("warning_transportTreesCannotBeLoaded")
    spec.texts.warningWoodContainerWrongLength = g_i18n:getText("warning_woodContainerWrongLength")
    if savegame ~= nil then
        spec.woodQualityVolume = savegame.xmlFile:getValue(savegame.key .. ".woodContainer#woodQualityVolume", spec.woodQualityVolume)
        spec.woodQualityTotalVolume = savegame.xmlFile:getValue(savegame.key .. ".woodContainer#woodQualityTotalVolume", spec.woodQualityTotalVolume)
    end
end
function WoodContainer:onDelete()
    local spec = self.spec_woodContainer
    if spec.triggerNode ~= nil then
        removeTrigger(spec.triggerNode)
    end
    if spec.samples ~= nil then
        g_soundManager:deleteSamples(spec.samples)
    end
end
function WoodContainer:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_woodContainer
    xmlFile:setValue(key .. "#woodQualityVolume", spec.woodQualityVolume)
    xmlFile:setValue(key .. "#woodQualityTotalVolume", spec.woodQualityTotalVolume)
end
function WoodContainer:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, _, _, _, _)
    local spec = self.spec_woodContainer
    if fillUnitIndex == spec.fillUnitIndex then
        if self.isClient and fillLevelDelta > 0 then
            local numLogs = math.ceil(self:getFillUnitFillLevelPercentage(fillUnitIndex) * (spec.soundNumLogs - 1))
            if numLogs ~= spec.soundLastNumLogs then
                if not g_soundManager:getIsSamplePlaying(spec.samples.load) then
                    g_soundManager:playSample(spec.samples.load)
                end
                spec.soundLastNumLogs = numLogs
            end
        end
        if spec.pushAnimation.name ~= nil then
            local fillLevel = self:getFillUnitFillLevelPercentage(fillUnitIndex)
            local numLogs = self:getAnimationTime(spec.pushAnimation.name)
            if fillLevel > 0 and numLogs == 0 then
                self:playAnimation(spec.pushAnimation.name, spec.pushAnimation.speedScale, self:getAnimationTime(spec.pushAnimation.name), true)
                return
            end
            if fillLevel == 0 and numLogs ~= 0 then
                self:playAnimation(spec.pushAnimation.name, -spec.pushAnimation.speedScale, self:getAnimationTime(spec.pushAnimation.name), true)
            end
        end
    end
end
function WoodContainer:getPalletUnloadTriggerExtraSellPrice()
    return self:getPrice()
end
function WoodContainer:getIsWoodContainerFillingAllowed()
    if self.spec_foldable ~= nil then
        local spec = self.spec_woodContainer
        local foldAnimTime = self:getFoldAnimTime()
        if foldAnimTime < spec.foldMinLimit or spec.foldMaxLimit < foldAnimTime then
            return false
        end
    end
    return true
end
function WoodContainer:getInfoBoxTitle(_)
    return g_i18n:getText("storeItem_shippingContainer", self.customEnvironment)
end
function WoodContainer:addFillUnitFillLevel(superFunc, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
    local delta = superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
    if fillLevelDelta < 0 then
        local spec = self.spec_woodContainer
        if spec.woodQualityTotalVolume > 0 then
        end
    end
    return delta
end
function WoodContainer:onWoodContainerTriggerCallback(_, otherId, _, _, _)
    if self:getIsWoodContainerFillingAllowed() and otherId ~= 0 then
        local splitType = g_splitShapeManager:getSplitTypeByIndex(getSplitType(otherId))
        if splitType ~= nil and splitType.pricePerLiter > 0 then
            if string.contains(splitType.name, "TRANSPORT") then
                g_currentMission:showBlinkingWarning(self.spec_woodContainer.texts.warningTransportTreesCannotBeLoaded, 2000)
            else
                local spec = self.spec_woodContainer
                local liter, qualityScale, length = WoodContainer.getSplitShapeInfo(otherId, spec.targetLength)
                if liter > 0 and (qualityScale > 0 and self:getFillUnitFreeCapacity(spec.fillUnitIndex) > 0) then
                    spec.woodQualityVolume = spec.woodQualityVolume + liter * qualityScale * splitType.pricePerLiter
                    spec.woodQualityTotalVolume = spec.woodQualityTotalVolume + liter
                    self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, liter, FillType.WOOD, ToolType.UNDEFINED, nil)
                    delete(otherId)
                    if math.abs(spec.targetLength - length) > 1 then
                        g_server:broadcastEvent(WoodContainerWrongLengthEvent.new(self), true, nil, self)
                        return
                    end
                end
            end
        end
    end
end
function WoodContainer.getSplitShapeInfo(objectId, _)
    local volume = getVolume(objectId)
    local splitType = g_splitShapeManager:getSplitTypeByIndex(getSplitType(objectId))
    local sizeX, sizeY, sizeZ, numConvexes, numAttachments = getSplitShapeStats(objectId)
    local qualityScale = 1
    local lengthScale = 1
    local defoliageScale = 1
    local maxSize = 0
    if sizeX ~= nil and volume > 0 then
        local maxQuality = math.clamp((sizeX * sizeY * sizeZ / volume - 3) / 7, 0, 1)
        local volumeQuality = 1 - math.sqrt(maxQuality) * 0.95
        local convexityQuality = 1 - math.clamp((numConvexes - 2) / 4, 0, 1) * 0.95
        maxSize = math.max(sizeX, sizeY, sizeZ)
        if maxSize < 11 then
            lengthScale = 0.6 + math.min(math.max((maxSize - 1) / 5, 0), 1) * 0.6
        else
            lengthScale = 1.2 - math.min(math.max((maxSize - 11) / 8, 0), 1) * 0.6
        end
        local minQuality = math.min(convexityQuality, volumeQuality)
        qualityScale = minQuality + (math.max(convexityQuality, volumeQuality) - minQuality) * 0.3
        defoliageScale = 1 - math.min(numAttachments / 15, 1) * 0.8
    end
    local bvVolume = #EconomicDifficulty.getAllOrdered()
    local volumeQuality = g_currentMission.missionInfo
    local convexityQuality = MathUtil.lerp(1, qualityScale, volumeQuality.economicDifficulty / bvVolume)
    local convexityQuality = MathUtil.lerp(1, defoliageScale, volumeQuality.economicDifficulty / bvVolume)
    return volume * splitType.volumeToLiter, convexityQuality * convexityQuality * lengthScale, maxSize
end