FruitPreparer = {}
FruitPreparer.CLIENT_DM_UPDATE_RADIUS = 50
function FruitPreparer.initSpecialization()
    g_workAreaTypeManager:addWorkAreaType("fruitPreparer", false, true, true)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("FruitPreparer")
    schema:register(XMLValueType.STRING, "vehicle.fruitPreparer#fruitType", "Fruit type")
    schema:register(XMLValueType.STRING_LIST, "vehicle.fruitPreparer#fruitTypes", "List of preparing fruit types separated by whitespace")
    schema:register(XMLValueType.BOOL, "vehicle.fruitPreparer#aiUsePreparedState", "AI uses prepared state instead of unprepared state", "true if vehicle has also the Cutter specialization")
    schema:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_KEY .. ".fruitPreparer#dropWorkAreaIndex", "Drop area index")
    schema:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".fruitPreparer#dropWorkAreaIndex", "Drop area index")
    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.fruitPreparer.animationNodes")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.fruitPreparer.sounds", "work")
    schema:register(XMLValueType.BOOL, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#moveOnlyIfPreparerCut", "Move only if fruit preparer cuts something", false)
    schema:setXMLSpecializationType()
end
function FruitPreparer.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
end
function FruitPreparer.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "processFruitPreparerArea", FruitPreparer.processFruitPreparerArea)
end
function FruitPreparer.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", FruitPreparer.loadWorkAreaFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoGroundManipulation", FruitPreparer.getDoGroundManipulation)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", FruitPreparer.doCheckSpeedLimit)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowCutterAIFruitRequirements", FruitPreparer.getAllowCutterAIFruitRequirements)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", FruitPreparer.getDirtMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", FruitPreparer.getWearMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadRandomlyMovingPartFromXML", FruitPreparer.loadRandomlyMovingPartFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsRandomlyMovingPartActive", FruitPreparer.getIsRandomlyMovingPartActive)
end
function FruitPreparer.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", FruitPreparer)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", FruitPreparer)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", FruitPreparer)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", FruitPreparer)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", FruitPreparer)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", FruitPreparer)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", FruitPreparer)
    SpecializationUtil.registerEventListener(vehicleType, "onAIFieldCourseSettingsInitialized", FruitPreparer)
end
function FruitPreparer:onLoad(_)
    local spec = self.spec_fruitPreparer
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnAnimation#name", "vehicle.turnOnVehicle.turnedAnimation#name")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnAnimation#speed", "vehicle.turnOnVehicle.turnedAnimation#turnOnSpeedScale")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.fruitPreparer#useReelStateToTurnOn")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.fruitPreparer#onlyActiveWhenLowered")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.vehicle.fruitPreparerSound", "vehicle.fruitPreparer.sounds.work")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode", "vehicle.fruitPreparer.animationNodes.animationNode", "fruitPreparer")
    if self.isClient then
        spec.samples = {}
        spec.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.fruitPreparer.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.fruitPreparer.animationNodes", self.components, self, self.i3dMappings)
    end
    spec.fruitTypes = {}
    local fruitTypes = self.xmlFile:getValue("vehicle.fruitPreparer#fruitTypes", {}, true)
    local fruitType = self.xmlFile:getValue("vehicle.fruitPreparer#fruitType")
    if fruitType ~= nil then
        table.insert(fruitTypes, fruitType)
    end
    if #fruitTypes > 0 then
        for _, fruitType in ipairs(fruitTypes) do
            local desc = g_fruitTypeManager:getFruitTypeByName(fruitType)
            if desc == nil then
                Logging.xmlWarning(self.xmlFile, "Unable to find fruitType \'%s\' in fruitPreparer", fruitType)
            else
                table.insert(spec.fruitTypes, desc.index)
                if self.setAIFruitRequirements ~= nil then
                    if desc.minPreparingGrowthState == -1 then
                        self:addAIFruitRequirement(desc.index, spec.allowsForageGrowthState and desc.minForageGrowthState or desc.minHarvestingGrowthState, desc.maxHarvestingGrowthState)
                    else
                        self:setAIFruitRequirements(desc.index, desc.minPreparingGrowthState, desc.maxPreparingGrowthState)
                        if self.xmlFile:getValue("vehicle.fruitPreparer#aiUsePreparedState", self.spec_cutter ~= nil) then
                            self:addAIFruitRequirement(desc.index, desc.preparedGrowthState, desc.preparedGrowthState)
                        end
                    end
                end
            end
        end
    else
        Logging.xmlWarning(self.xmlFile, "Missing fruitType in fruitPreparer")
    end
    spec.isWorking = false
    spec.lastWorkTime = -math.huge
    spec.dirtyFlag = self:getNextDirtyFlag()
end
function FruitPreparer:onDelete()
    local spec = self.spec_fruitPreparer
    g_soundManager:deleteSamples(spec.samples)
    g_animationManager:deleteAnimations(spec.animationNodes)
end
function FruitPreparer:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        self.spec_fruitPreparer.isWorking = streamReadBool(streamId)
    end
end
function FruitPreparer:onWriteUpdateStream(streamId, connection, _)
    if not connection:getIsServer() then
        streamWriteBool(streamId, self.spec_fruitPreparer.isWorking)
    end
end
function FruitPreparer:onTurnedOn()
    if self.isClient then
        local spec = self.spec_fruitPreparer
        g_soundManager:playSample(spec.samples.work)
        g_animationManager:startAnimations(spec.animationNodes)
    end
end
function FruitPreparer:onTurnedOff()
    if self.isClient then
        local spec = self.spec_fruitPreparer
        g_soundManager:stopSamples(spec.samples)
        g_animationManager:stopAnimations(spec.animationNodes)
    end
end
function FruitPreparer:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
    local retValue = superFunc(self, workArea, xmlFile, key)
    if workArea.type == WorkAreaType.FRUITPREPARER then
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#dropStartIndex", key .. ".fruitPreparer#dropWorkAreaIndex")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#dropWidthIndex", key .. ".fruitPreparer#dropWorkAreaIndex")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#dropHeightIndex", key .. ".fruitPreparer#dropWorkAreaIndex")
        workArea.dropWorkAreaIndex = xmlFile:getValue(key .. ".fruitPreparer#dropWorkAreaIndex")
    end
    return retValue
end
function FruitPreparer:getDoGroundManipulation(superFunc)
    return superFunc(self) and self.spec_fruitPreparer.isWorking
end
function FruitPreparer:doCheckSpeedLimit(superFunc)
    return not superFunc(self) and self:getIsTurnedOn() and (self.getIsImplementChainLowered == nil or self:getIsImplementChainLowered())
end
function FruitPreparer:getAllowCutterAIFruitRequirements(superFunc)
    return false
end
function FruitPreparer:getDirtMultiplier(superFunc)
    if self.spec_fruitPreparer.isWorking then
        return superFunc(self) + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
    else
        return superFunc(self)
    end
end
function FruitPreparer:getWearMultiplier(superFunc)
    if self.spec_fruitPreparer.isWorking then
        return superFunc(self) + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
    else
        return superFunc(self)
    end
end
function FruitPreparer:loadRandomlyMovingPartFromXML(superFunc, part, xmlFile, key)
    local retValue = superFunc(self, part, xmlFile, key)
    part.moveOnlyIfPreparerCut = xmlFile:getValue(key .. "#moveOnlyIfPreparerCut", false)
    return retValue
end
function FruitPreparer:getIsRandomlyMovingPartActive(superFunc, part)
    local retValue = superFunc(self, part)
    if part.moveOnlyIfPreparerCut then
        if retValue then
            retValue = self.spec_fruitPreparer.isWorking
        end
    end
    return retValue
end
function FruitPreparer.getDefaultSpeedLimit()
    return 15
end
function FruitPreparer:onEndWorkAreaProcessing(_)
    if self.isServer then
        local spec = self.spec_fruitPreparer
        local isWorking = g_time - spec.lastWorkTime < 500
        if isWorking ~= spec.isWorking then
            self:raiseDirtyFlags(spec.dirtyFlag)
            spec.isWorking = isWorking
        end
    end
end
function FruitPreparer.onAIFieldCourseSettingsInitialized(_, fieldCourseSettings)
    fieldCourseSettings.headlandsFirst = true
    fieldCourseSettings.workInitialSegment = true
end
function FruitPreparer:processFruitPreparerArea(workArea)
    local spec = self.spec_fruitPreparer
    if not self.isServer and self.currentUpdateDistance > FruitPreparer.CLIENT_DM_UPDATE_RADIUS then
        return 0, 0
    end
    local xs, _, zs = getWorldTranslation(workArea.start)
    local xw, _, zw = getWorldTranslation(workArea.width)
    local xh, _, zh = getWorldTranslation(workArea.height)
    local limitToFruit = true
    local dxs, dzh, dzw, dxh, dxw, dzs
    if workArea.dropWorkAreaIndex == nil then
        dxs = xs
        dzh = zh
        dzw = zw
        dxh = xh
        dxw = xw
        dzs = zs
    else
        local dropArea = self.spec_workArea.workAreas[workArea.dropWorkAreaIndex]
        if dropArea == nil then
            dxs = xs
            dzh = zh
            dzw = zw
            dxh = xh
            dxw = xw
            dzs = zs
        else
            dxs, _, dzs = getWorldTranslation(dropArea.start)
            dxw, _, dzw = getWorldTranslation(dropArea.width)
            dxh, _, dzh = getWorldTranslation(dropArea.height)
            limitToFruit = false
        end
    end
    local dropArea = 0
    for _, fruitType in ipairs(spec.fruitTypes) do
        local area = FSDensityMapUtil.updateFruitPreparerArea(fruitType, xs, zs, xw, zw, xh, zh, dxs, dzs, dxw, dzw, dxh, dzh, limitToFruit)
        if area > 0 then
            spec.lastWorkTime = g_time
            dropArea = area
        end
    end
    return 0, dropArea
end