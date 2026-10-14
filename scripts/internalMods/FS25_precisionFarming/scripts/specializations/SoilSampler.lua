SoilSampler = {}
SoilSampler.SPEC_NAME = g_currentModName .. ".soilSampler"
SoilSampler.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".soilSampler"
SoilSampler.SEND_NUM_BITS = 9
function SoilSampler.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
end
function SoilSampler.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("SoilSampler")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.soilSampler#node", "Sampling Node")
    schema:register(XMLValueType.FLOAT, "vehicle.soilSampler#radius", "Sampling radius", 10)
    schema:register(XMLValueType.STRING, "vehicle.soilSampler#actionNameTake", "Take sample input action name", "IMPLEMENT_EXTRA")
    schema:register(XMLValueType.STRING, "vehicle.soilSampler#actionNameSend", "Send sample input action name", "IMPLEMENT_EXTRA3")
    schema:register(XMLValueType.STRING, "vehicle.soilSampler#animationName", "Sampling animation name")
    schema:register(XMLValueType.FLOAT, "vehicle.soilSampler#animationSpeed", "Sampling animation speed", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.soilSampler#foldMinLimit", "Fold min. limit", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.soilSampler#foldMaxLimit", "Fold max. limit", 1)
    schema:register(XMLValueType.STRING, "vehicle.soilSampler.samplesAnimation#name", "Samples animation name")
    schema:register(XMLValueType.FLOAT, "vehicle.soilSampler.samplesAnimation#speed", "Samples animation speed", 1)
    schema:register(XMLValueType.INT, "vehicle.soilSampler.samplesAnimation#minSamples", "Min. samples", 0)
    schema:register(XMLValueType.INT, "vehicle.soilSampler.samplesAnimation#maxSamples", "Max. samples", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.soilSampler.visualSamples#updateTime", "Update time", 0.5)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.soilSampler.visualSamples.visualSample(?)#node", "Visual sample node")
    schema:setXMLSpecializationType()
    Vehicle.xmlSchemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?)." .. SoilSampler.SPEC_NAME .. "#numCollectedSamples", "Num collected samples")
end
function SoilSampler.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "startSoilSampling", SoilSampler.startSoilSampling)
    SpecializationUtil.registerFunction(vehicleType, "setNumCollectedSoilSamples", SoilSampler.setNumCollectedSoilSamples)
    SpecializationUtil.registerFunction(vehicleType, "getNormalizedSampleIndex", SoilSampler.getNormalizedSampleIndex)
    SpecializationUtil.registerFunction(vehicleType, "getCanStartSoilSampling", SoilSampler.getCanStartSoilSampling)
    SpecializationUtil.registerFunction(vehicleType, "processSoilSampling", SoilSampler.processSoilSampling)
    SpecializationUtil.registerFunction(vehicleType, "sendTakenSoilSamples", SoilSampler.sendTakenSoilSamples)
end
function SoilSampler.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", SoilSampler.doCheckSpeedLimit)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", SoilSampler.getIsFoldAllowed)
end
function SoilSampler.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", SoilSampler)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", SoilSampler)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", SoilSampler)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", SoilSampler)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SoilSampler)
    SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", SoilSampler)
    SpecializationUtil.registerEventListener(vehicleType, "onLeaveRootVehicle", SoilSampler)
    SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", SoilSampler)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", SoilSampler)
end
function SoilSampler:onLoad(_)
    local spec = self[SoilSampler.SPEC_TABLE_NAME]
    spec.samplingNode = self.xmlFile:getValue("vehicle.soilSampler#node", nil, self.components, self.i3dMappings)
    spec.samplingRadius = self.xmlFile:getValue("vehicle.soilSampler#radius", 10)
    spec.densityMapCircle = DensityMapCircle.new()
    local actionNameTake = self.xmlFile:getValue("vehicle.soilSampler#actionNameTake", "IMPLEMENT_EXTRA")
    spec.inputActionTake = InputAction[actionNameTake] or InputAction.IMPLEMENT_EXTRA
    local actionNameSend = self.xmlFile:getValue("vehicle.soilSampler#actionNameSend", "IMPLEMENT_EXTRA3")
    spec.inputActionSend = InputAction[actionNameSend] or InputAction.IMPLEMENT_EXTRA
    spec.isSampling = false
    spec.animationName = self.xmlFile:getValue("vehicle.soilSampler#animationName")
    spec.animationSpeed = self.xmlFile:getValue("vehicle.soilSampler#animationSpeed", 1)
    spec.numCollectedSamples = 0
    spec.foldMinLimit = self.xmlFile:getValue("vehicle.soilSampler#foldMinLimit", 0)
    spec.foldMaxLimit = self.xmlFile:getValue("vehicle.soilSampler#foldMaxLimit", 1)
    spec.samplesAnimation = {}
    spec.samplesAnimation.name = self.xmlFile:getValue("vehicle.soilSampler.samplesAnimation#name")
    spec.samplesAnimation.speed = self.xmlFile:getValue("vehicle.soilSampler.samplesAnimation#speed", 1)
    spec.samplesAnimation.minSamples = self.xmlFile:getValue("vehicle.soilSampler.samplesAnimation#minSamples", 0)
    spec.samplesAnimation.maxSamples = self.xmlFile:getValue("vehicle.soilSampler.samplesAnimation#maxSamples", 0)
    spec.visualSampleUpdateTime = self.xmlFile:getValue("vehicle.soilSampler.visualSamples#updateTime", 0.5)
    spec.visualSampleUpdated = true
    spec.visualSamples = {}
    local i = 0
    while true do
        local visualSampleKey = string.format("%s.visualSamples.visualSample(%d)", "vehicle.soilSampler", i)
        if not self.xmlFile:hasProperty(visualSampleKey) then
            break
        end
        local node = self.xmlFile:getValue(visualSampleKey .. "#node", nil, self.components, self.i3dMappings)
        if node ~= nil then
            setVisibility(node, false)
            table.insert(spec.visualSamples, node)
        end
        i = i + 1
    end
    spec.texts = {}
    spec.texts.takeSample = g_i18n:getText("action_takeSoilSample", self.customEnvironment)
    spec.texts.sendSoilSamples = g_i18n:getText("action_sendSoilSamples", self.customEnvironment)
    spec.texts.numSamplesTaken = g_i18n:getText("info_numSamplesTaken", self.customEnvironment)
    spec.texts.infoSamplesSend = g_i18n:getText("info_samplesSend", self.customEnvironment)
    if g_precisionFarming ~= nil then
        spec.soilMap = g_precisionFarming.soilMap
        spec.coverMap = g_precisionFarming.coverMap
        spec.farmlandStatistics = g_precisionFarming.farmlandStatistics
    end
end
function SoilSampler:onPostLoad(savegame)
    if savegame ~= nil and not savegame.resetVehicles then
        self:setNumCollectedSoilSamples(savegame.xmlFile:getValue(savegame.key .. "." .. SoilSampler.SPEC_NAME .. "#numCollectedSamples", self[SoilSampler.SPEC_TABLE_NAME].numCollectedSamples), true)
    end
end
function SoilSampler:saveToXMLFile(xmlFile, key, _)
    xmlFile:setValue(key .. "#numCollectedSamples", self[SoilSampler.SPEC_TABLE_NAME].numCollectedSamples)
end
function SoilSampler:onReadStream(streamId, _)
    self:setNumCollectedSoilSamples(streamReadUIntN(streamId, SoilSampler.SEND_NUM_BITS) or self[SoilSampler.SPEC_TABLE_NAME].numCollectedSamples, true)
end
function SoilSampler:onWriteStream(streamId, _)
    streamWriteUIntN(streamId, self[SoilSampler.SPEC_TABLE_NAME].numCollectedSamples, SoilSampler.SEND_NUM_BITS)
end
function SoilSampler:onUpdate(_, _, isActiveForInputIgnoreSelection, _)
    local spec = self[SoilSampler.SPEC_TABLE_NAME]
    if spec.isSampling then
        if self.isClient and (not spec.visualSampleUpdated and self:getAnimationTime(spec.animationName) >= spec.visualSampleUpdateTime) then
            local sampleIndex = self:getNormalizedSampleIndex()
            local i = 1
            for i = i, #spec.visualSamples do
                setVisibility(spec.visualSamples[i], i <= sampleIndex)
            end
            spec.visualSampleUpdated = false
        end
        if not self:getIsAnimationPlaying(spec.animationName) then
            spec.isSampling = false
            self:setAnimationTime(spec.animationName, 0, false)
            if spec.soilMap:getMinimapAdditionalElementLinkNode() == spec.samplingNode then
                spec.soilMap:setMinimapSamplingState(false)
            end
            self:processSoilSampling()
            self.speedLimit = math.huge
        end
    end
    if isActiveForInputIgnoreSelection and spec.numCollectedSamples > 0 then
        g_currentMission:addExtraPrintText(string.format(spec.texts.numSamplesTaken, spec.numCollectedSamples))
    end
end
function SoilSampler:onFoldStateChanged(direction, _)
    if self:getIsActiveForInput(true) then
        self[SoilSampler.SPEC_TABLE_NAME].soilMap:setRequireMinimapDisplay(direction == 1, self, self:getIsSelected())
    end
end
function SoilSampler:onLeaveRootVehicle()
    local spec = self[SoilSampler.SPEC_TABLE_NAME]
    if spec.soilMap:getMinimapAdditionalElementLinkNode() == spec.samplingNode then
        spec.soilMap:setRequireMinimapDisplay(false, self)
        spec.soilMap:setMinimapAdditionalElementLinkNode(nil)
        spec.soilMap:setMinimapSamplingState(false)
    end
end
function SoilSampler:onPreDetach()
    local spec = self[SoilSampler.SPEC_TABLE_NAME]
    if spec.soilMap:getMinimapAdditionalElementLinkNode() == spec.samplingNode then
        spec.soilMap:setRequireMinimapDisplay(false, self)
        spec.soilMap:setMinimapAdditionalElementLinkNode(nil)
        spec.soilMap:setMinimapSamplingState(false)
    end
end
function SoilSampler:startSoilSampling(noEventSend)
    local spec = self[SoilSampler.SPEC_TABLE_NAME]
    spec.isSampling = true
    if self.isServer then
        if not self:getIsLowered(false) then
            local attacherVehicle = self:getAttacherVehicle()
            if attacherVehicle ~= nil and attacherVehicle:getAttacherJointDescFromObject(self).allowsLowering then
                attacherVehicle:setJointMoveDown(attacherVehicle:getAttacherJointIndexFromObject(self), true, false)
            end
        end
        local attacherVehicle, jointDesc, jointDescIndex = self:getPFStatisticInfo()
        if jointDesc then
            self:updatePFStatistic("numSoilSamples", 1)
            self:updatePFStatistic("soilSampleCosts", spec.soilMap:getPricePerSoilSample())
        end
        self.speedLimit = 0
    end
    self:playAnimation(spec.animationName, spec.animationSpeed, self:getAnimationTime(spec.animationName), true)
    self:setNumCollectedSoilSamples(spec.numCollectedSamples + 1, false)
    if self:getIsActiveForInput(true) then
        spec.soilMap:setMinimapSamplingState(true)
    end
    if self.isClient then
        if (spec.numCollectedSamples - 1) % #spec.visualSamples == 0 then
            local jointDescIndex = 1
            for jointDescIndex = jointDescIndex, #spec.visualSamples do
                setVisibility(spec.visualSamples[jointDescIndex], false)
            end
            self:playAnimation(spec.samplesAnimation.name, -spec.samplesAnimation.speed, self:getAnimationTime(spec.samplesAnimation.name), true)
        else
            local jointDesc = (self:getNormalizedSampleIndex() - spec.samplesAnimation.minSamples) / (spec.samplesAnimation.maxSamples - spec.samplesAnimation.minSamples)
            if self:getAnimationTime(spec.samplesAnimation.name) < jointDesc then
                self:setAnimationStopTime(spec.samplesAnimation.name, jointDesc)
                self:playAnimation(spec.samplesAnimation.name, spec.samplesAnimation.speed, self:getAnimationTime(spec.samplesAnimation.name), true)
            end
        end
        spec.visualSampleUpdated = false
    end
    SoilSampler.updateActionEventState(self)
    SoilSamplerStartEvent.sendEvent(self, noEventSend)
end
function SoilSampler:setNumCollectedSoilSamples(num, updateVisuals)
    local spec = self[SoilSampler.SPEC_TABLE_NAME]
    spec.numCollectedSamples = num or spec.numCollectedSamples + 1
    if updateVisuals then
        local sampleIndex = self:getNormalizedSampleIndex()
        local j = 1
        for j = j, #spec.visualSamples do
            setVisibility(spec.visualSamples[j], j <= sampleIndex)
        end
        self:setAnimationTime(spec.samplesAnimation.name, (sampleIndex - spec.samplesAnimation.minSamples) / (spec.samplesAnimation.maxSamples - spec.samplesAnimation.minSamples), true)
    end
end
function SoilSampler:getNormalizedSampleIndex()
    local spec = self[SoilSampler.SPEC_TABLE_NAME]
    local sampleIndex = spec.numCollectedSamples % #spec.visualSamples
    return spec.numCollectedSamples == 0 and 0 or (sampleIndex == 0 and #spec.visualSamples or sampleIndex)
end
function SoilSampler:getCanStartSoilSampling()
    local spec = self[SoilSampler.SPEC_TABLE_NAME]
    local x, _, z = getWorldTranslation(spec.samplingNode)
    local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
    if farmlandId == nil then
        return false, g_i18n:getText("warning_youDontHaveAccessToThisLand")
    end
    local landOwner = g_farmlandManager:getFarmlandOwner(farmlandId)
    local accessible = false
    if landOwner ~= 0 then
        accessible = g_currentMission.accessHandler:canFarmAccessOtherId(self:getActiveFarm(), landOwner)
    end
    if not accessible then
        return false, g_i18n:getText("warning_youDontHaveAccessToThisLand")
    end
    if self.getIsMotorStarted == nil then
        local rootAttacherVehicle = self:getRootVehicle()
        if rootAttacherVehicle ~= self and (rootAttacherVehicle.getIsMotorStarted ~= nil and not rootAttacherVehicle:getIsMotorStarted()) then
            return false, g_i18n:getText("warning_motorNotStarted")
        end
    elseif not self:getIsMotorStarted() then
        return false, g_i18n:getText("warning_motorNotStarted")
    end
    if self.getFoldAnimTime ~= nil then
        local rootAttacherVehicle = self:getFoldAnimTime()
        if spec.foldMaxLimit < rootAttacherVehicle or rootAttacherVehicle < spec.foldMinLimit then
            return false, self.spec_foldable.unfoldWarning
        end
    end
    return not self[SoilSampler.SPEC_TABLE_NAME].isSampling
end
function SoilSampler:processSoilSampling()
    if self.isServer then
        local spec = self[SoilSampler.SPEC_TABLE_NAME]
        if spec.soilMap ~= nil then
            local worldX, _, worldZ = getWorldTranslation(spec.samplingNode)
            spec.densityMapCircle:updateFromWorldPosition(worldX, worldZ, spec.samplingRadius, 20)
            spec.coverMap:analyseArea(spec.densityMapCircle, nil, self:getOwnerFarmId())
        end
    end
end
function SoilSampler:sendTakenSoilSamples(noEventSend)
    local spec = self[SoilSampler.SPEC_TABLE_NAME]
    if self.isServer and spec.soilMap ~= nil then
        spec.soilMap:analyseSoilSamples(self:getOwnerFarmId(), spec.numCollectedSamples)
    end
    if self.isClient then
        local i = 1
        for i = i, #spec.visualSamples do
            setVisibility(spec.visualSamples[i], false)
        end
        self:playAnimation(spec.samplesAnimation.name, -spec.samplesAnimation.speed, self:getAnimationTime(spec.samplesAnimation.name), true)
    end
    spec.numCollectedSamples = 0
    SoilSampler.updateActionEventState(self)
    SoilSamplerSendEvent.sendEvent(self, noEventSend)
end
function SoilSampler:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self[SoilSampler.SPEC_TABLE_NAME]
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addActionEvent(spec.actionEvents, spec.inputActionTake, self, SoilSampler.actionEventStartSample, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
            g_inputBinding:setActionEventText(actionEventId, spec.texts.takeSample)
            local _, actionEventId = self:addActionEvent(spec.actionEvents, spec.inputActionSend, self, SoilSampler.actionEventSendSamples, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
            g_inputBinding:setActionEventText(actionEventId, spec.texts.sendSoilSamples)
            SoilSampler.updateActionEventState(self)
            spec.soilMap:setRequireMinimapDisplay(self:getFoldAnimTime() > 0, self, self:getIsSelected())
            spec.soilMap:setMinimapAdditionalElementLinkNode(spec.samplingNode)
            spec.soilMap:setMinimapAdditionalElementRealSize(spec.samplingRadius * 2, spec.samplingRadius * 2)
        end
    end
end
function SoilSampler:updateActionEventState()
    local spec = self[SoilSampler.SPEC_TABLE_NAME]
    local actionEventSend = spec.actionEvents[spec.inputActionSend]
    if actionEventSend ~= nil then
        g_inputBinding:setActionEventActive(actionEventSend.actionEventId, spec.numCollectedSamples > 0)
    end
end
function SoilSampler:actionEventStartSample(_, _, _, _)
    local canStart, warning = self:getCanStartSoilSampling()
    if canStart then
        self:startSoilSampling()
    elseif warning ~= nil then
        g_currentMission:showBlinkingWarning(warning, 2000)
    end
end
function SoilSampler:actionEventSendSamples(_, _, _, _)
    local spec = self[SoilSampler.SPEC_TABLE_NAME]
    if spec.numCollectedSamples > 0 and not spec.isSampling then
        InfoDialog.show(spec.texts.infoSamplesSend, SoilSampler.onSendSoilSamplesDialog, self)
    end
end
function SoilSampler:onSendSoilSamplesDialog()
    local spec = self[SoilSampler.SPEC_TABLE_NAME]
    if spec.soilMap ~= nil then
        spec.soilMap:sendSoilSamplesByFarm(self:getOwnerFarmId())
    end
end
function SoilSampler:doCheckSpeedLimit(superFunc)
    return superFunc(self) or self[SoilSampler.SPEC_TABLE_NAME].isSampling
end
function SoilSampler:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
    return not self[SoilSampler.SPEC_TABLE_NAME].isSampling and superFunc(self, direction, onAiTurnOn)
end