EnvironmentalScoreValue = {}
local EnvironmentalScoreValue_mt = Class(EnvironmentalScoreValue)
function EnvironmentalScoreValue.new(pfModule, customMt)
    -- upvalues: (copy) EnvironmentalScoreValue_mt
    local self = setmetatable({}, customMt or EnvironmentalScoreValue_mt)
    self.pfModule = pfModule
    self.xmlKey = "default"
    return self
end
function EnvironmentalScoreValue:initFarmlandData()
    return {}
end
function EnvironmentalScoreValue:getFarmlandData(farmlandId)
    if farmlandId ~= nil and self.farmlandDatas[farmlandId] == nil then
        self.farmlandDatas[farmlandId] = self:initFarmlandData()
        self.farmlandDatas[farmlandId].farmlandId = farmlandId
    end
    return self.farmlandDatas[farmlandId]
end
function EnvironmentalScoreValue:loadFromXML(_, _, _, _, _)
    self.farmlandDatas = {}
    return true
end
function EnvironmentalScoreValue:loadFromItemsXML(xmlFile, key)
    xmlFile:iterate(string.format("%s.%s.farmland", key, self.xmlKey), function(_, dataKey)
        -- upvalues: (copy) xmlFile, (copy) self
        local farmlandId = xmlFile:getInt(dataKey .. "#farmlandId")
        if farmlandId ~= nil then
            self:loadFarmlandData(self:getFarmlandData(farmlandId), xmlFile, dataKey)
        end
    end)
end
function EnvironmentalScoreValue:saveToXMLFile(xmlFile, key, _)
    local index = 0
    for farmlandId, data in pairs(self.farmlandDatas) do
        local dataKey = string.format("%s.%s.farmland(%d)", key, self.xmlKey, index)
        xmlFile:setInt(dataKey .. "#farmlandId", farmlandId)
        self:saveFarmlandData(data, xmlFile, dataKey)
        index = index + 1
    end
end
function EnvironmentalScoreValue:loadFarmlandData(data, xmlFile, key) end
function EnvironmentalScoreValue:saveFarmlandData(data, xmlFile, key) end
function EnvironmentalScoreValue:readStream(streamId, connection, _)
    local numFarmlandDatas = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
    for i = 1, numFarmlandDatas do
        self:readFarmlandDataFromStream(self:getFarmlandData((streamReadUIntN(streamId, g_farmlandManager.numberOfBits))), streamId, connection)
    end
end
function EnvironmentalScoreValue:writeStream(streamId, connection, farmId)
    local numFarmlandDatas = 0
    for farmlandId, _ in pairs(self.farmlandDatas) do
        if g_farmlandManager.farmlandMapping[farmlandId] == farmId then
        end
    end
    streamWriteUIntN(streamId, numFarmlandDatas, g_farmlandManager.numberOfBits)
    for farmlandId, _ in pairs(self.farmlandDatas) do
        if g_farmlandManager.farmlandMapping[farmlandId] == farmId then
            streamWriteUIntN(streamId, farmlandId, g_farmlandManager.numberOfBits)
            self:writeFarmlandDataToStream(_, streamId, connection)
        end
    end
end
function EnvironmentalScoreValue:readFarmlandDataFromStream(data, streamId, connection) end
function EnvironmentalScoreValue:writeFarmlandDataToStream(data, streamId, connection) end
function EnvironmentalScoreValue:update(dt) end
function EnvironmentalScoreValue:getScore()
    return 0.5
end
function EnvironmentalScoreValue:overwriteGameFunctions(pfModule)
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
end