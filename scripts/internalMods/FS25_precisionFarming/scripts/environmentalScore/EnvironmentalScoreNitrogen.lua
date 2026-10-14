EnvironmentalScoreNitrogen = {}
EnvironmentalScoreNitrogen.COMPRESSION = 1000
local EnvironmentalScoreNitrogen_mt = Class(EnvironmentalScoreNitrogen, EnvironmentalScoreValue)
function EnvironmentalScoreNitrogen.new(pfModule, customMt)
    -- upvalues: (copy) EnvironmentalScoreNitrogen_mt
    local self = EnvironmentalScoreValue.new(pfModule, customMt or EnvironmentalScoreNitrogen_mt)
    self.xmlKey = "nitrogen"
    return self
end
function EnvironmentalScoreNitrogen:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
    if not EnvironmentalScoreTillage:superClass().loadFromXML(self, xmlFile, key, baseDirectory, configFileName, mapFilename) then
        return false
    end
    self.scoreCurve = AnimCurve.new(linearInterpolator1)
    local i = 0
    while true do
        local baseKey = string.format("%s.scoreMapping.scoreValue(%d)", key, i)
        if not hasXMLProperty(xmlFile, baseKey) then
            break
        end
        local nOffset = getXMLFloat(xmlFile, baseKey .. "#nOffset") or 0
        local score = getXMLFloat(xmlFile, baseKey .. "#score") or 0
        local nitrogenMap = g_precisionFarming.nitrogenMap
        if nitrogenMap ~= nil then
            nOffset = nOffset / nitrogenMap:getNitrogenFromChangedStates(1)
        end
        self.scoreCurve:addKeyframe({
            score,
            ["time"] = nOffset
        })
        i = i + 1
    end
    return true
end
function EnvironmentalScoreNitrogen:update(dt) end
function EnvironmentalScoreNitrogen:getScore(farmlandId)
    local farmlandData = self:getFarmlandData(farmlandId)
    if farmlandData.clientScore ~= nil then
        return farmlandData.clientScore
    end
    if farmlandData.harvestedArea <= 0 then
        return 0.5
    end
    return self.scoreCurve:get(farmlandData.nOffsetSum / farmlandData.harvestedArea * EnvironmentalScoreNitrogen.COMPRESSION)
end
function EnvironmentalScoreNitrogen:initFarmlandData()
    return {
        ["harvestedArea"] = 0,
        ["nOffsetSum"] = 0,
        ["pendingReset"] = false
    }
end
function EnvironmentalScoreNitrogen.loadFarmlandData(_, data, xmlFile, key)
    data.harvestedArea = xmlFile:getFloat(key .. "#harvestedArea", data.harvestedArea)
    data.nOffsetSum = xmlFile:getFloat(key .. "#nOffsetSum", data.nOffsetSum)
    data.pendingReset = xmlFile:getBool(key .. "#pendingReset", data.pendingReset)
end
function EnvironmentalScoreNitrogen.saveFarmlandData(_, data, xmlFile, key)
    xmlFile:setFloat(key .. "#harvestedArea", data.harvestedArea)
    xmlFile:setFloat(key .. "#nOffsetSum", data.nOffsetSum)
    xmlFile:setBool(key .. "#pendingReset", data.pendingReset)
end
function EnvironmentalScoreNitrogen.readFarmlandDataFromStream(_, data, streamId, _)
    data.clientScore = MathUtil.round(streamReadUIntN(streamId, 8) / 255, 2)
end
function EnvironmentalScoreNitrogen:writeFarmlandDataToStream(data, streamId, _)
    local score = self:getScore(data.farmlandId)
    streamWriteUIntN(streamId, score * 255, 8)
end
function EnvironmentalScoreNitrogen:onHarvestScoreReset(farmlandId)
    self:getFarmlandData(farmlandId).pendingReset = true
end
function EnvironmentalScoreNitrogen:addWorkedArea(farmlandId, area, nOffset)
    area = area / EnvironmentalScoreNitrogen.COMPRESSION
    local farmlandData = self:getFarmlandData(farmlandId)
    if farmlandData.pendingReset then
        farmlandData.harvestedArea = 0
        farmlandData.nOffsetSum = 0
        farmlandData.pendingReset = false
    end
    farmlandData.harvestedArea = farmlandData.harvestedArea + area
    farmlandData.nOffsetSum = farmlandData.nOffsetSum + area * (nOffset / EnvironmentalScoreNitrogen.COMPRESSION)
end
function EnvironmentalScoreNitrogen:overwriteGameFunctions(pfModule)
    if g_server ~= nil then
        pfModule:overwriteGameFunction(HarvestExtension, "setLastScoringValues", function(superFunc, harvestExtension, area, farmlandId, nActual, nTarget, pHActual, pHTarget, ignoreOverfertilization, fillTypeIndex)
            -- upvalues: (copy) self
            superFunc(harvestExtension, area, farmlandId, nActual, nTarget, pHActual, pHTarget, ignoreOverfertilization, fillTypeIndex)
            if nActual ~= nil and (nTarget ~= nil and (area > 0 and farmlandId ~= nil)) then
                local difference = nActual - nTarget
                if ignoreOverfertilization then
                    difference = math.min(difference, 0)
                end
                self:addWorkedArea(farmlandId, area, difference)
            end
        end)
    end
end