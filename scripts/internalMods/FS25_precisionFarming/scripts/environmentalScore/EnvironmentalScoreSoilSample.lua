EnvironmentalScoreSoilSample = {}
EnvironmentalScoreSoilSample.TYPE_NONE = 1
EnvironmentalScoreSoilSample.TYPE_SAMPLED = 2
local EnvironmentalScoreSoilSample_mt = Class(EnvironmentalScoreSoilSample, EnvironmentalScoreValue)
function EnvironmentalScoreSoilSample.new(pfModule, customMt)
    -- upvalues: (copy) EnvironmentalScoreSoilSample_mt
    local self = EnvironmentalScoreValue.new(pfModule, customMt or EnvironmentalScoreSoilSample_mt)
    self.xmlKey = "soilSample"
    self.typeWeights = {
        [EnvironmentalScoreSoilSample.TYPE_NONE] = 0,
        [EnvironmentalScoreSoilSample.TYPE_SAMPLED] = 1
    }
    return self
end
function EnvironmentalScoreSoilSample:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
    return EnvironmentalScoreTillage:superClass().loadFromXML(self, xmlFile, key, baseDirectory, configFileName, mapFilename) and true or false
end
function EnvironmentalScoreSoilSample:update(dt) end
function EnvironmentalScoreSoilSample:getScore(farmlandId)
    local farmlandData = self:getFarmlandData(farmlandId)
    if farmlandData.clientScore == nil then
        return farmlandData.samplePercentage < 0 and 0.5 or farmlandData.samplePercentage
    else
        return farmlandData.clientScore
    end
end
function EnvironmentalScoreSoilSample:initFarmlandData()
    return {
        ["samplePercentage"] = -1
    }
end
function EnvironmentalScoreSoilSample.loadFarmlandData(_, data, xmlFile, key)
    data.samplePercentage = xmlFile:getFloat(key .. "#samplePercentage", data.samplePercentage)
end
function EnvironmentalScoreSoilSample.saveFarmlandData(_, data, xmlFile, key)
    xmlFile:setFloat(key .. "#samplePercentage", data.samplePercentage)
end
function EnvironmentalScoreSoilSample.readFarmlandDataFromStream(_, data, streamId, _)
    data.clientScore = MathUtil.round(streamReadUIntN(streamId, 8) / 255, 2)
end
function EnvironmentalScoreSoilSample:writeFarmlandDataToStream(data, streamId, _)
    local score = self:getScore(data.farmlandId)
    streamWriteUIntN(streamId, score * 255, 8)
end
function EnvironmentalScoreSoilSample:onHarvestScoreReset(farmlandId)
    self:updateFarmlandSampleState(farmlandId)
end
function EnvironmentalScoreSoilSample:updateFarmlandSampleState(farmlandId)
    local farmlandData = self:getFarmlandData(farmlandId)
    local percentage = self.pfModule.coverMap:getFarmlandSampleState(farmlandId)
    farmlandData.samplePercentage = math.clamp(percentage, 0, 1)
end
function EnvironmentalScoreSoilSample:onFarmlandSampleStatesFinished(sampledPercentageByFarmlandId)
    for farmlandId, percentage in pairs(sampledPercentageByFarmlandId) do
        self:getFarmlandData(farmlandId).samplePercentage = math.clamp(percentage, 0, 1)
    end
end
function EnvironmentalScoreSoilSample:overwriteGameFunctions(pfModule)
    if g_server ~= nil then
        pfModule:overwriteGameFunction(SoilSampler, "processSoilSampling", function(superFunc, vehicle, ...)
            -- upvalues: (copy) self
            superFunc(vehicle, ...)
            local spec = vehicle[SoilSampler.SPEC_TABLE_NAME]
            if spec.coverMap ~= nil then
                local x, _, z = getWorldTranslation(spec.samplingNode)
                self:updateFarmlandSampleState((g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)))
            end
        end)
        pfModule:overwriteGameFunction(CoverMap, "onCoverUpdateFinished", function(superFunc, coverMap, farmId, farmlandId, sampledPercentageByFarmlandId)
            -- upvalues: (copy) self
            superFunc(coverMap, farmId, farmlandId, sampledPercentageByFarmlandId)
            self:onFarmlandSampleStatesFinished(sampledPercentageByFarmlandId)
        end)
        pfModule:overwriteGameFunction(CoverMap, "analyseArea", function(superFunc, coverMap, densityMapShape, state, farmId, farmlandId)
            -- upvalues: (copy) self
            superFunc(coverMap, densityMapShape, state, farmId, farmlandId)
            if farmlandId ~= nil then
                self:updateFarmlandSampleState(farmlandId)
            end
        end)
    end
end