ExtendedSowingMachine = {}
ExtendedSowingMachine.MIN_SEED_RATE = 1
ExtendedSowingMachine.MAX_SEED_RATE = 3
ExtendedSowingMachine.DEFAULT_SEED_RATE = 2
ExtendedSowingMachine.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".extendedSowingMachine"
source(g_currentModDirectory .. "scripts/hud/ExtendedSowingMachineHUDExtension.lua")
function ExtendedSowingMachine.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(SowingMachine, specializations) and SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
end
function ExtendedSowingMachine.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setSeedRateAutoMode", ExtendedSowingMachine.setSeedRateAutoMode)
    SpecializationUtil.registerFunction(vehicleType, "setManualSeedRate", ExtendedSowingMachine.setManualSeedRate)
    SpecializationUtil.registerFunction(vehicleType, "onTramlinesChanged", ExtendedSowingMachine.onTramlinesChanged)
end
function ExtendedSowingMachine.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "processSowingMachineArea", ExtendedSowingMachine.processSowingMachineArea)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "processOverSeedingArea", ExtendedSowingMachine.processOverSeedingArea)
end
function ExtendedSowingMachine.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", ExtendedSowingMachine)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", ExtendedSowingMachine)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ExtendedSowingMachine)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", ExtendedSowingMachine)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", ExtendedSowingMachine)
end
function ExtendedSowingMachine:onLoad(_)
    local spec = self[ExtendedSowingMachine.SPEC_TABLE_NAME]
    spec.seedRateAutoMode = true
    spec.manualSeedRate = ExtendedSowingMachine.DEFAULT_SEED_RATE
    spec.lastSeedRate = 0
    spec.lastSeedRateIndex = 0
    spec.lastRealChangedArea = 0
    spec.lastGroundUpdateDistance = math.huge
    spec.groundUpdateDistance = 4
    spec.tramlineWidth = nil
    spec.seedRateRecommendation = nil
    spec.inputActionToggleAuto = InputAction.PRECISIONFARMING_SEED_RATE_MODE
    spec.inputActionToggleRate = InputAction.PRECISIONFARMING_SEED_RATE
    spec.texts = {}
    spec.texts.inputToggleAutoModePos = g_i18n:getText("action_toggleSeedRateAutoModePos", self.customEnvironment)
    spec.texts.inputToggleAutoModeNeg = g_i18n:getText("action_toggleSeedRateAutoModeNeg", self.customEnvironment)
    spec.texts.inputChangeSeedRate = g_i18n:getText("action_changeManualSeedRate", self.customEnvironment)
    spec.soilMap = g_precisionFarming.soilMap
    spec.seedRateMap = g_precisionFarming.seedRateMap
    spec.tramlineMap = g_precisionFarming.tramlineMap
    spec.hudExtension = ExtendedSowingMachineHUDExtension.new(self)
    g_messageCenter:subscribe(MessageType.PRECISION_FARMING_TRAMLINES_CHANGED, self.onTramlinesChanged, self)
end
function ExtendedSowingMachine:onDelete()
    local spec = self[ExtendedSowingMachine.SPEC_TABLE_NAME]
    if spec.hudExtension ~= nil then
        spec.hudExtension:delete()
    end
end
function ExtendedSowingMachine:onUpdate(_, _, isActiveForInputIgnoreSelection, _)
    local spec = self[ExtendedSowingMachine.SPEC_TABLE_NAME]
    spec.lastGroundUpdateDistance = spec.lastGroundUpdateDistance + self.lastMovedDistance
    if spec.lastGroundUpdateDistance > spec.groundUpdateDistance then
        spec.lastGroundUpdateDistance = 0
        local workArea = self:getWorkAreaByIndex(1)
        if workArea ~= nil then
            local lx, _, _ = localToLocal(workArea.start, self.rootNode, 0, 0, 0)
            local x1, z1
            if math.abs(lx) < 0.5 then
                x1, _, z1 = getWorldTranslation(workArea.start)
            else
                local x1, _, z1 = getWorldTranslation(workArea.start)
                local x2, _, z2 = getWorldTranslation(workArea.width)
            end
            local x1, _ = FSDensityMapUtil.getFieldDataAtWorldPosition(x1, 0, z1)
            if x1 then
                local z1 = spec.soilMap:getTypeIndexAtWorldPos(x1, z1)
                if z1 > 0 then
                    spec.seedRateRecommendation = spec.seedRateMap:getOptimalSeedRateByFruitTypeAndSoiltype(self.spec_sowingMachine.seeds[self.spec_sowingMachine.currentSeed], z1)
                else
                    spec.seedRateRecommendation = nil
                end
                spec.tramlineWidth = spec.tramlineMap:getTramlineWidthAtWorldPos(x1, z1)
            else
                spec.seedRateRecommendation = nil
                spec.tramlineWidth = nil
            end
        end
    end
    if isActiveForInputIgnoreSelection and spec.hudExtension ~= nil then
        g_currentMission.hud:addHelpExtension(spec.hudExtension)
    end
end
function ExtendedSowingMachine:onEndWorkAreaProcessing(_, _)
    local specSowingMachine = self.spec_sowingMachine
    if self.isServer and specSowingMachine.workAreaParameters.lastChangedArea > 0 then
        local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(specSowingMachine.workAreaParameters.seedsFruitType)
        local realHa = MathUtil.areaToHa(self[ExtendedSowingMachine.SPEC_TABLE_NAME].lastRealChangedArea, g_currentMission:getFruitPixelsToSqm())
        local lastHa = MathUtil.areaToHa(specSowingMachine.workAreaParameters.lastChangedArea, g_currentMission:getFruitPixelsToSqm())
        local usage = fruitDesc.seedUsagePerSqm * lastHa * 10000 * specSowingMachine.seedUsageScale
        local usageRegular = fruitDesc.seedUsagePerSqm * realHa * 10000 * specSowingMachine.seedUsageScale
        local damage = self:getVehicleDamage()
        if damage > 0 then
        end
        if self.updatePFStatistic ~= nil then
            self:updatePFStatistic("usedSeeds", usage)
            self:updatePFStatistic("usedSeedsRegular", usageRegular)
        end
    end
end
function ExtendedSowingMachine:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self[ExtendedSowingMachine.SPEC_TABLE_NAME]
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addActionEvent(spec.actionEvents, spec.inputActionToggleAuto, self, ExtendedSowingMachine.actionEventToggleAuto, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
            local _, actionEventId = self:addActionEvent(spec.actionEvents, spec.inputActionToggleRate, self, ExtendedSowingMachine.actionEventChangeSeedRate, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
            g_inputBinding:setActionEventText(actionEventId, spec.texts.inputChangeSeedRate)
            ExtendedSowingMachine.updateActionEventState(self)
        end
        spec.attachStateChanged = true
    end
end
function ExtendedSowingMachine:setSeedRateAutoMode(state, noEventSend)
    local spec = self[ExtendedSowingMachine.SPEC_TABLE_NAME]
    if state == nil then
        state = not spec.seedRateAutoMode
    end
    if state ~= spec.seedRateAutoMode then
        spec.seedRateAutoMode = state
        if self.isClient then
            ExtendedSowingMachine.updateActionEventState(self)
        end
        ExtendedSowingMachineRateEvent.sendEvent(self, spec.seedRateAutoMode, spec.manualSeedRate, noEventSend)
    end
end
function ExtendedSowingMachine:setManualSeedRate(seedRate, noEventSend)
    local spec = self[ExtendedSowingMachine.SPEC_TABLE_NAME]
    seedRate = math.clamp(seedRate, ExtendedSowingMachine.MIN_SEED_RATE, ExtendedSowingMachine.MAX_SEED_RATE)
    if seedRate ~= spec.manualSeedRate then
        spec.manualSeedRate = seedRate
        ExtendedSowingMachineRateEvent.sendEvent(self, spec.seedRateAutoMode, spec.manualSeedRate, noEventSend)
    end
end
function ExtendedSowingMachine:onTramlinesChanged()
    self[ExtendedSowingMachine.SPEC_TABLE_NAME].lastGroundUpdateDistance = math.huge
end
function ExtendedSowingMachine:processSowingMachineArea(superFunc, workArea, dt)
    local changedArea, totalArea = superFunc(self, workArea, dt)
    if changedArea > 0 then
        local spec = self[ExtendedSowingMachine.SPEC_TABLE_NAME]
        local workAreaParameters = self.spec_sowingMachine.workAreaParameters
        spec.lastRealChangedArea = workAreaParameters.lastChangedArea
        local sx, _, sz = getWorldTranslation(workArea.start)
        local wx, _, wz = getWorldTranslation(workArea.width)
        local hx, _, hz = getWorldTranslation(workArea.height)
        local fruitType = workAreaParameters.seedsFruitType
        local realUsage, realSeedRate, realSeedRateIndex = spec.seedRateMap:updateSeedArea(sx, sz, wx, wz, hx, hz, fruitType, spec.seedRateAutoMode, spec.manualSeedRate)
        if realSeedRateIndex ~= nil then
            local usageOffset = realUsage / g_fruitTypeManager:getFruitTypeByIndex(fruitType).seedUsagePerSqm
            workAreaParameters.lastChangedArea = spec.lastRealChangedArea * usageOffset
            spec.lastSeedRate = realSeedRate
            spec.lastSeedRateIndex = realSeedRateIndex
        end
    end
    return changedArea, totalArea
end
function ExtendedSowingMachine:processOverSeedingArea(superFunc, workArea, dt)
    local changedArea, totalArea = superFunc(self, workArea, dt)
    if changedArea > 0 then
        local spec = self[ExtendedSowingMachine.SPEC_TABLE_NAME]
        local workAreaParameters = self.spec_sowingMachine.workAreaParameters
        spec.lastRealChangedArea = workAreaParameters.lastChangedArea
        local sx, _, sz = getWorldTranslation(workArea.start)
        local wx, _, wz = getWorldTranslation(workArea.width)
        local hx, _, hz = getWorldTranslation(workArea.height)
        local fruitType = workAreaParameters.seedsFruitType
        local realUsage, realSeedRate, realSeedRateIndex = spec.seedRateMap:updateSeedArea(sx, sz, wx, wz, hx, hz, fruitType, spec.seedRateAutoMode, spec.manualSeedRate)
        if realSeedRateIndex ~= nil then
            local usageOffset = realUsage / g_fruitTypeManager:getFruitTypeByIndex(fruitType).seedUsagePerSqm
            workAreaParameters.lastChangedArea = spec.lastRealChangedArea * usageOffset
            spec.lastSeedRate = realSeedRate
            spec.lastSeedRateIndex = realSeedRateIndex
        end
    end
    return changedArea, totalArea
end
function ExtendedSowingMachine:actionEventToggleAuto(_, _, _, _)
    self:setSeedRateAutoMode()
end
function ExtendedSowingMachine:actionEventChangeSeedRate(_, inputValue, _, _, ...)
    self:setManualSeedRate(self[ExtendedSowingMachine.SPEC_TABLE_NAME].manualSeedRate + math.sign(inputValue))
end
function ExtendedSowingMachine:updateActionEventState()
    local spec = self[ExtendedSowingMachine.SPEC_TABLE_NAME]
    local actionEventToggleAuto = spec.actionEvents[spec.inputActionToggleAuto]
    if actionEventToggleAuto ~= nil then
        g_inputBinding:setActionEventText(actionEventToggleAuto.actionEventId, spec.seedRateAutoMode and spec.texts.inputToggleAutoModeNeg or spec.texts.inputToggleAutoModePos)
    end
    local actionEventToggleRate = spec.actionEvents[spec.inputActionToggleRate]
    if actionEventToggleRate ~= nil then
        g_inputBinding:setActionEventActive(actionEventToggleRate.actionEventId, not spec.seedRateAutoMode)
    end
end