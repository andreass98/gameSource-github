ExtendedCombine = {}
ExtendedCombine.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".extendedCombine"
ExtendedCombine.YIELD_NUM_BITS = 11
ExtendedCombine.YIELD_MAX_VALUE = 2 ^ ExtendedCombine.YIELD_NUM_BITS - 1
ExtendedCombine.YIELD_PCT_NUM_BITS = 7
ExtendedCombine.YIELD_PCT_MAX_VALUE = 2 ^ ExtendedCombine.YIELD_PCT_NUM_BITS - 1
source(g_currentModDirectory .. "scripts/hud/ExtendedCombineHUDExtension.lua")
function ExtendedCombine.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Combine, specializations) and SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
end
function ExtendedCombine.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setLastYieldValues", ExtendedCombine.setLastYieldValues)
end
function ExtendedCombine.registerOverwrittenFunctions(vehicleType) end
function ExtendedCombine.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", ExtendedCombine)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", ExtendedCombine)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", ExtendedCombine)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", ExtendedCombine)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ExtendedCombine)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ExtendedCombine)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", ExtendedCombine)
end
function ExtendedCombine:onLoad(_)
    local spec = self[ExtendedCombine.SPEC_TABLE_NAME]
    spec.lastYieldWeight = 0
    spec.lastYieldPercentage = 0
    spec.lastYieldPotential = 0
    spec.usageValuesDirtyFlag = self:getNextDirtyFlag()
    spec.hudExtension = ExtendedCombineHUDExtension.new(self)
end
function ExtendedCombine:onDelete()
    local spec = self[ExtendedCombine.SPEC_TABLE_NAME]
    if spec.hudExtension ~= nil then
        spec.hudExtension:delete()
    end
end
function ExtendedCombine:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            self[ExtendedCombine.SPEC_TABLE_NAME].lastYieldWeight = streamReadUIntN(streamId, ExtendedCombine.YIELD_NUM_BITS) / 10
            spec.lastYieldPercentage = streamReadUIntN(streamId, ExtendedCombine.YIELD_PCT_NUM_BITS)
            spec.lastYieldPotential = streamReadUIntN(streamId, ExtendedCombine.YIELD_PCT_NUM_BITS)
        end
    end
end
function ExtendedCombine:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self[ExtendedCombine.SPEC_TABLE_NAME]
        if streamWriteBool(streamId, bit32.band(dirtyMask, spec.usageValuesDirtyFlag) ~= 0) then
            streamWriteUIntN(streamId, math.min(math.floor(spec.lastYieldWeight * 10), ExtendedCombine.YIELD_MAX_VALUE), ExtendedCombine.YIELD_NUM_BITS)
            streamWriteUIntN(streamId, math.min(math.floor(spec.lastYieldPercentage), ExtendedCombine.YIELD_PCT_MAX_VALUE), ExtendedCombine.YIELD_PCT_NUM_BITS)
            streamWriteUIntN(streamId, math.min(math.floor(spec.lastYieldPotential), ExtendedCombine.YIELD_PCT_MAX_VALUE), ExtendedCombine.YIELD_PCT_NUM_BITS)
        end
    end
end
function ExtendedCombine:onUpdate(_, _, _, _)
    local spec = self[ExtendedCombine.SPEC_TABLE_NAME]
    if self.isActiveForInputIgnoreSelectionIgnoreAI and spec.hudExtension ~= nil then
        g_currentMission.hud:addHelpExtension(spec.hudExtension)
    end
end
function ExtendedCombine:onUpdateTick(_, _, _, _)
    if self.isClient and self.isActiveForInputIgnoreSelectionIgnoreAI then
        ExtendedCombine.updateMinimapActiveState(self)
    end
end
function ExtendedCombine:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        if isActiveForInputIgnoreSelection then
            ExtendedCombine.updateMinimapActiveState(self)
            return
        end
        ExtendedCombine.updateMinimapActiveState(self, false)
    end
end
function ExtendedCombine:updateMinimapActiveState(forcedState)
    local yieldMap = self:getPFYieldMap()
    if yieldMap ~= nil then
        if forcedState == nil then
            local _, _, _, mission
            _, _, _, forcedState, mission = self:getPFStatisticInfo()
            if forcedState then
                forcedState = false
                if self.spec_combine.numAttachedCutters > 0 then
                    forcedState = mission ~= nil
                end
            end
        end
        yieldMap:setRequireMinimapDisplay(forcedState, self, self:getIsSelected())
    end
end
function ExtendedCombine:setLastYieldValues(lastYieldWeight, lastYieldPercentage, lastYieldPotential)
    local spec = self[ExtendedCombine.SPEC_TABLE_NAME]
    if lastYieldWeight ~= spec.lastYieldWeight or (lastYieldPercentage ~= spec.lastYieldPercentage or lastYieldPotential ~= spec.lastYieldPotential) then
        spec.lastYieldWeight = lastYieldWeight
        spec.lastYieldPercentage = lastYieldPercentage
        spec.lastYieldPotential = lastYieldPotential
        self:raiseDirtyFlags(spec.usageValuesDirtyFlag)
    end
end