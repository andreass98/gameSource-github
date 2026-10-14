GameTestCaseAIDeliver = {}
local GameTestCaseAIDeliver_mt = Class(GameTestCaseAIDeliver, GameTestCaseAI)
function GameTestCaseAIDeliver.new(customMt)
    -- upvalues: (copy) GameTestCaseAIDeliver_mt
    local self = GameTestCaseAI.new(customMt or GameTestCaseAIDeliver_mt)
    self.vehicleSetup = nil
    self.spawnPosition = nil
    self.fillType = nil
    self.unloadingStation = nil
    return self
end
function GameTestCaseAIDeliver:setVehicleSetup(vehicleSetup)
    self.vehicleSetup = vehicleSetup
end
function GameTestCaseAIDeliver:setSpawnPosition(spawnPosition)
    self.spawnPosition = spawnPosition
end
function GameTestCaseAIDeliver:setFillType(fillType)
    self.fillType = fillType
end
function GameTestCaseAIDeliver:setStations(unloadingStation)
    self.unloadingStation = unloadingStation
end
function GameTestCaseAIDeliver:finalize()
    if self.vehicleSetup == nil then
        return false
    end
    if self.spawnPosition == nil then
        return false
    end
    if self.fillType == nil then
        return false
    end
    if self.unloadingStation == nil then
        return false
    end
    self.description = string.format("Deliver \'%s\' from \'%s\' to \'%s\' with \'%s\'", g_fillTypeManager:getFillTypeTitleByIndex(self.fillType), self.spawnPosition.name, self.unloadingStation:getName(), self.vehicleSetup.name)
    self.descriptionShort = string.format("Deliver to %s", self.unloadingStation:getName())
    return true
end
function GameTestCaseAIDeliver:saveToXMLFile(xmlFile, key)
    GameTestCaseAIDeliver:superClass().saveToXMLFile(self, xmlFile, key)
    GameTestCaseAI.saveVehicleSetup(self.vehicleSetup, xmlFile, key .. ".vehicleSetup")
    GameTestCaseAI.savePosition(self.spawnPosition, xmlFile, key .. ".spawnPosition")
    xmlFile:setString(key .. "#filType", g_fillTypeManager:getFillTypeNameByIndex(self.fillType))
    GameTestCaseAI.savePlaceable(self.unloadingStation.owningPlaceable, xmlFile, key .. ".unloadingStation")
end
function GameTestCaseAIDeliver.generateTestCaseFromConfig(xmlFile, key)
    local vehicleSetup = GameTestCaseAI.loadVehicleSetup(xmlFile, key .. ".vehicleSetup")
    if vehicleSetup == nil then
        Logging.xmlError(xmlFile, "Unknown vehicle setup")
        return nil
    end
    local spawnPosition = GameTestCaseAI.loadPosition(xmlFile, key .. ".spawnPosition")
    if spawnPosition == nil then
        Logging.xmlError(xmlFile, "Unknown spawn position")
        return nil
    end
    local fillType = nil
    local filTypeStr = xmlFile:getString(key .. "#filType")
    if filTypeStr ~= nil then
        fillType = g_fillTypeManager:getFillTypeIndexByName(filTypeStr)
    end
    if fillType == nil then
        Logging.xmlError(xmlFile, "Unknown fill type")
        return nil
    end
    local unloadingStationPlaceable = GameTestCaseAI.loadPlaceable(xmlFile, key .. ".unloadingStation")
    if unloadingStationPlaceable ~= nil then
        local unloadingStations = GameTestCaseAIDeliver.loadUnloadingStations()
        local i = 1
        for i = i, #unloadingStations do
            local unloadingStationData = unloadingStations[i]
            if unloadingStationData.fillType == fillType and unloadingStationData.unloadingStation.owningPlaceable == unloadingStationPlaceable then
                local case = GameTestCaseAIDeliver.new()
                case:setVehicleSetup(vehicleSetup)
                case:setSpawnPosition(spawnPosition)
                case:setFillType(unloadingStationData.fillType)
                case:setStations(unloadingStationData.unloadingStation)
                if case:finalize() then
                    case:print("Loaded test case from XML. (%s)", case:getDescription())
                    return case
                end
            end
        end
    end
    Logging.xmlError(xmlFile, "Unable to find unloading station")
    return nil
end
function GameTestCaseAIDeliver:start(finishedCallback)
    GameTestCaseAIDeliver:superClass().start(self, finishedCallback)
    self.testTask = GameTestTaskAIDeliver.new(self)
    self.testTask:setData(self.vehicleSetup, self.spawnPosition, self.fillType, self.unloadingStation)
    self.testTask:start(function(result, reason)
        -- upvalues: (copy) self, (copy) finishedCallback
        self:onFinished(result, reason, finishedCallback)
    end)
end
function GameTestCaseAIDeliver.loadUnloadingStations()
    local unloadingStations = {}
    for _, unloadingStation in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
        if unloadingStation:isa(UnloadingStation) then
            local x, _, _, _, _ = unloadingStation:getAITargetPositionAndDirection(FillType.UNKNOWN)
            if x ~= nil then
                local unloadFillTypes = unloadingStation:getAISupportedFillTypes()
                for unloadFillTypeIndex, _state in pairs(unloadFillTypes) do
                    if _state then
                        local x, _, _, _, _ = unloadingStation:getAITargetPositionAndDirection(unloadFillTypeIndex)
                        if x ~= nil then
                            table.insert(unloadingStations, {
                                ["unloadingStation"] = unloadingStation,
                                ["fillType"] = unloadFillTypeIndex
                            })
                            break
                        end
                    end
                end
            end
        end
    end
    return unloadingStations
end
function GameTestCaseAIDeliver.generateTestCases(targetTable, xmlFile, key)
    local spawnPositions = GameTestCaseAI.loadSpawnPositions(xmlFile, key)
    local vehicleSetups = GameTestCaseAI.loadVehicleSetups(xmlFile, key)
    local unloadingStations = GameTestCaseAIDeliver.loadUnloadingStations()
    local i = 1
    for i = i, #unloadingStations do
        local s = 1
        for s = s, #spawnPositions do
            local v = 1
            for v = v, #vehicleSetups do
                local vehicleSetup = vehicleSetups[v]
                local canLoadFillType = false
                local vi = 1
                local case = #vehicleSetup.vehicles
                for vi = vi, case do
                    local vehicle = vehicleSetup.vehicles[vi]
                    if vehicle.fillTypes ~= nil then
                        local fi = 1
                        for fi = fi, #vehicle.fillTypes do
                            if vehicle.fillTypes[fi] == unloadingStations[i].fillType then
                                canLoadFillType = true
                                break
                            end
                        end
                    end
                end
                if canLoadFillType then
                    local case = GameTestCaseAIDeliver.new()
                    case:setVehicleSetup(vehicleSetups[v])
                    case:setSpawnPosition(spawnPositions[s])
                    case:setFillType(unloadingStationData.fillType)
                    case:setStations(unloadingStationData.unloadingStation)
                    if case:finalize() then
                        case:print("Found test case. (%s)", case:getDescription())
                        table.insert(targetTable, case)
                    end
                end
            end
        end
    end
end
function GameTestCaseAIDeliver.registerXMLPaths(schema, baseKey) end
GameTestManager.registerTestCase(GameTestCaseAIDeliver)