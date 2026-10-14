EnvironmentalScoreTillage = {}
EnvironmentalScoreTillage.TYPE_NONE = 0
EnvironmentalScoreTillage.TYPE_DEEP_CULTIVATION = 1
EnvironmentalScoreTillage.TYPE_FLAT_CULTIVATION = 2
EnvironmentalScoreTillage.TYPE_DIRECT_PLANTING = 3
local EnvironmentalScoreTillage_mt = Class(EnvironmentalScoreTillage, EnvironmentalScoreValue)
function EnvironmentalScoreTillage.new(pfModule, customMt)
    -- upvalues: (copy) EnvironmentalScoreTillage_mt
    local self = EnvironmentalScoreValue.new(pfModule, customMt or EnvironmentalScoreTillage_mt)
    self.xmlKey = "tillage"
    self.typeWeights = {
        [EnvironmentalScoreTillage.TYPE_NONE] = 0.5,
        [EnvironmentalScoreTillage.TYPE_DEEP_CULTIVATION] = 0,
        [EnvironmentalScoreTillage.TYPE_FLAT_CULTIVATION] = 0.5,
        [EnvironmentalScoreTillage.TYPE_DIRECT_PLANTING] = 1
    }
    return self
end
function EnvironmentalScoreTillage:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
    return EnvironmentalScoreTillage:superClass().loadFromXML(self, xmlFile, key, baseDirectory, configFileName, mapFilename) and true or false
end
function EnvironmentalScoreTillage:update(dt) end
function EnvironmentalScoreTillage:getScore(farmlandId)
    local farmlandData = self:getFarmlandData(farmlandId)
    if farmlandData.clientScore ~= nil then
        return farmlandData.clientScore
    end
    local scorePct = 0
    if farmlandData.totalFieldArea > 0 then
        local i = 0
        for i = i, #farmlandData.workedAreaByType do
            scorePct = scorePct + math.min(farmlandData.workedAreaByType[i] / farmlandData.totalFieldArea, 1) * self.typeWeights[i]
        end
    else
        scorePct = self.typeWeights[EnvironmentalScoreTillage.TYPE_NONE]
    end
    return math.min(scorePct, 1)
end
function EnvironmentalScoreTillage:initFarmlandData()
    return {
        ["totalFieldArea"] = 0,
        ["workedAreaByType"] = {
            [EnvironmentalScoreTillage.TYPE_NONE] = math.huge,
            [EnvironmentalScoreTillage.TYPE_DEEP_CULTIVATION] = 0,
            [EnvironmentalScoreTillage.TYPE_FLAT_CULTIVATION] = 0,
            [EnvironmentalScoreTillage.TYPE_DIRECT_PLANTING] = 0
        }
    }
end
function EnvironmentalScoreTillage.loadFarmlandData(_, data, xmlFile, key)
    data.totalFieldArea = xmlFile:getFloat(key .. "#totalFieldArea", data.totalFieldArea)
    data.workedAreaByType[EnvironmentalScoreTillage.TYPE_NONE] = xmlFile:getFloat(key .. "#workedAreaNone", data.workedAreaByType[EnvironmentalScoreTillage.TYPE_NONE])
    data.workedAreaByType[EnvironmentalScoreTillage.TYPE_DEEP_CULTIVATION] = xmlFile:getFloat(key .. "#workedAreaDeep", data.workedAreaByType[EnvironmentalScoreTillage.TYPE_DEEP_CULTIVATION])
    data.workedAreaByType[EnvironmentalScoreTillage.TYPE_FLAT_CULTIVATION] = xmlFile:getFloat(key .. "#workedAreaFlat", data.workedAreaByType[EnvironmentalScoreTillage.TYPE_FLAT_CULTIVATION])
    data.workedAreaByType[EnvironmentalScoreTillage.TYPE_DIRECT_PLANTING] = xmlFile:getFloat(key .. "#workedAreaDirect", data.workedAreaByType[EnvironmentalScoreTillage.TYPE_DIRECT_PLANTING])
end
function EnvironmentalScoreTillage.saveFarmlandData(_, data, xmlFile, key)
    if data.workedAreaByType[EnvironmentalScoreTillage.TYPE_NONE] ~= math.huge then
        xmlFile:setFloat(key .. "#totalFieldArea", data.totalFieldArea)
        xmlFile:setFloat(key .. "#workedAreaNone", data.workedAreaByType[EnvironmentalScoreTillage.TYPE_NONE])
        xmlFile:setFloat(key .. "#workedAreaDeep", data.workedAreaByType[EnvironmentalScoreTillage.TYPE_DEEP_CULTIVATION])
        xmlFile:setFloat(key .. "#workedAreaFlat", data.workedAreaByType[EnvironmentalScoreTillage.TYPE_FLAT_CULTIVATION])
        xmlFile:setFloat(key .. "#workedAreaDirect", data.workedAreaByType[EnvironmentalScoreTillage.TYPE_DIRECT_PLANTING])
    end
end
function EnvironmentalScoreTillage.readFarmlandDataFromStream(_, data, streamId, _)
    data.clientScore = MathUtil.round(streamReadUIntN(streamId, 8) / 255, 2)
end
function EnvironmentalScoreTillage:writeFarmlandDataToStream(data, streamId, _)
    local score = self:getScore(data.farmlandId)
    streamWriteUIntN(streamId, score * 255, 8)
end
function EnvironmentalScoreTillage:addWorkedArea(farmlandId, area, type)
    local farmlandData = self:getFarmlandData(farmlandId)
    if farmlandData.workedAreaByType[EnvironmentalScoreTillage.TYPE_NONE] == math.huge then
        local farmland = g_farmlandManager:getFarmlandById(farmlandId)
        if farmland ~= nil and farmland.totalFieldArea ~= nil then
            farmlandData.totalFieldArea = farmland.totalFieldArea * 10000
            farmlandData.workedAreaByType[EnvironmentalScoreTillage.TYPE_NONE] = farmlandData.totalFieldArea
        end
    end
    local farmland = MathUtil.areaToHa(area, g_currentMission:getFruitPixelsToSqm()) * 10000
    while farmland > 0 do
        local changed = false
        local i = 0
        for i = i, #farmlandData.workedAreaByType - 1 do
            if i ~= type and (farmlandData.workedAreaByType[i] > 0 and farmland > 0) then
                local change = farmland / (#farmlandData.workedAreaByType - 1)
                farmlandData.workedAreaByType[i] = math.max(farmlandData.workedAreaByType[i] - change, 0)
                farmland = farmland - change
                changed = true
            end
        end
        if not changed then
            break
        end
    end
    if farmland > 0 then
        farmlandData.workedAreaByType[type] = farmlandData.workedAreaByType[type] - farmland
    end
    farmlandData.workedAreaByType[type] = farmlandData.workedAreaByType[type] + farmland
end
function EnvironmentalScoreTillage:overwriteGameFunctions(pfModule)
    if g_server ~= nil then
        pfModule:overwriteGameFunction(Cultivator, "processCultivatorArea", function(superFunc, vehicle, ...)
            -- upvalues: (copy) self
            local realArea, area = superFunc(vehicle, ...)
            if realArea > 0 and vehicle.getPFStatisticInfo ~= nil then
                local _, _, farmlandId = vehicle:getPFStatisticInfo()
                if farmlandId ~= nil then
                    self:addWorkedArea(farmlandId, realArea, vehicle.spec_cultivator.useDeepMode and EnvironmentalScoreTillage.TYPE_DEEP_CULTIVATION or EnvironmentalScoreTillage.TYPE_FLAT_CULTIVATION)
                end
            end
            return realArea, area
        end)
        pfModule:overwriteGameFunction(SowingMachine, "processSowingMachineArea", function(superFunc, vehicle, ...)
            -- upvalues: (copy) self
            local realArea, area = superFunc(vehicle, ...)
            if realArea > 0 and vehicle.getPFStatisticInfo ~= nil then
                local _, _, farmlandId = vehicle:getPFStatisticInfo()
                if farmlandId ~= nil and vehicle.spec_sowingMachine.useDirectPlanting then
                    self:addWorkedArea(farmlandId, realArea, EnvironmentalScoreTillage.TYPE_DIRECT_PLANTING)
                end
            end
            return realArea, area
        end)
        pfModule:overwriteGameFunction(FertilizingSowingMachine, "processSowingMachineArea", function(superFunc, vehicle, ...)
            -- upvalues: (copy) self
            local realArea, area = superFunc(vehicle, ...)
            if realArea > 0 and vehicle.getPFStatisticInfo ~= nil then
                local _, _, farmlandId = vehicle:getPFStatisticInfo()
                if farmlandId ~= nil and vehicle.spec_sowingMachine.useDirectPlanting then
                    self:addWorkedArea(farmlandId, realArea, EnvironmentalScoreTillage.TYPE_DIRECT_PLANTING)
                end
            end
            return realArea, area
        end)
        pfModule:overwriteGameFunction(HarvestExtension, "setLastScoringValues", function(superFunc, harvestExtension, area, farmlandId, nActual, nTarget, pHActual, pHTarget, ignoreOverfertilization, fillTypeIndex)
            -- upvalues: (copy) self
            superFunc(harvestExtension, area, farmlandId, nActual, nTarget, pHActual, pHTarget, ignoreOverfertilization, fillTypeIndex)
            if fillTypeIndex ~= nil and (fillTypeIndex == FillType.GRASS or fillTypeIndex == FillType.GRASS_WINDROW) and (area > 0 and farmlandId ~= nil) then
                self:addWorkedArea(farmlandId, area, EnvironmentalScoreTillage.TYPE_DIRECT_PLANTING)
            end
        end)
    end
end