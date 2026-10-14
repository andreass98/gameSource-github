PrecisionFarmingStatistic = {}
PrecisionFarmingStatistic.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".precisionFarmingStatistic"
function PrecisionFarmingStatistic.prerequisitesPresent(specializations)
    return true
end
function PrecisionFarmingStatistic.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getPFStatisticInfo", PrecisionFarmingStatistic.getPFStatisticInfo)
    SpecializationUtil.registerFunction(vehicleType, "updatePFStatistic", PrecisionFarmingStatistic.updatePFStatistic)
    SpecializationUtil.registerFunction(vehicleType, "getPFYieldMap", PrecisionFarmingStatistic.getPFYieldMap)
end
function PrecisionFarmingStatistic.registerOverwrittenFunctions(vehicleType) end
function PrecisionFarmingStatistic.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", PrecisionFarmingStatistic)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", PrecisionFarmingStatistic)
end
function PrecisionFarmingStatistic:onLoad(_)
    local spec = self[PrecisionFarmingStatistic.SPEC_TABLE_NAME]
    if g_precisionFarming ~= nil then
        spec.soilMap = g_precisionFarming.soilMap
        spec.phMap = g_precisionFarming.phMap
        spec.yieldMap = g_precisionFarming.yieldMap
        spec.farmlandStatistics = g_precisionFarming.farmlandStatistics
    end
    spec.isOnField = false
    spec.isOnFieldSmoothed = false
    spec.isOnFieldLastPos = { 0, 0 }
    spec.farmlandId = 0
    spec.farmlandAccess = false
    spec.mission = nil
    spec.lastUpdateDistance = 0
    spec.updateDistance = 0.5
end
function PrecisionFarmingStatistic:onUpdateTick(_, _, _, _)
    local spec = self[PrecisionFarmingStatistic.SPEC_TABLE_NAME]
    spec.lastUpdateDistance = spec.lastUpdateDistance + self.lastMovedDistance
    if spec.lastUpdateDistance > spec.updateDistance or spec.farmlandId == 0 then
        spec.lastUpdateDistance = 0
        local x, _, z = getWorldTranslation(self.rootNode)
        spec.farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
        if spec.farmlandId == 0 then
            spec.farmlandAccess = false
        else
            local landOwner = g_farmlandManager:getFarmlandOwner(spec.farmlandId)
            local distance = false
            if landOwner ~= 0 then
                distance = g_currentMission.accessHandler:canFarmAccessOtherId(self:getActiveFarm(), landOwner)
            end
            spec.farmlandAccess = distance
        end
        spec.mission = g_missionManager:getMissionAtWorldPosition(x, z)
        local landOwner = self.isOnField
        if landOwner ~= spec.isOnField then
            if landOwner then
                spec.isOnFieldSmoothed = true
            else
                spec.isOnFieldLastPos[1] = x
                spec.isOnFieldLastPos[2] = z
            end
        end
        if spec.isOnFieldSmoothed ~= landOwner and MathUtil.vector2Length(x - spec.isOnFieldLastPos[1], z - spec.isOnFieldLastPos[2]) > 20 then
            spec.isOnFieldSmoothed = landOwner
        end
        spec.isOnField = landOwner
    end
end
function PrecisionFarmingStatistic:getPFStatisticInfo()
    local spec = self[PrecisionFarmingStatistic.SPEC_TABLE_NAME]
    return spec.farmlandStatistics, spec.isOnField, spec.farmlandId, spec.isOnFieldSmoothed, spec.mission
end
function PrecisionFarmingStatistic:updatePFStatistic(name, value)
    local spec = self[PrecisionFarmingStatistic.SPEC_TABLE_NAME]
    if spec.farmlandStatistics ~= nil and (spec.farmlandId ~= nil and (spec.farmlandAccess and spec.mission == nil)) then
        spec.farmlandStatistics:updateStatistic(spec.farmlandId, name, value)
    end
end
function PrecisionFarmingStatistic:getPFYieldMap()
    return self[PrecisionFarmingStatistic.SPEC_TABLE_NAME].yieldMap
end