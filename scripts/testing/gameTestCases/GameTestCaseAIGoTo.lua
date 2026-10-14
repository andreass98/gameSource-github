GameTestCaseAIGoTo = {}
local GameTestCaseAIGoTo_mt = Class(GameTestCaseAIGoTo, GameTestCaseAI)
function GameTestCaseAIGoTo.new(customMt)
    -- upvalues: (copy) GameTestCaseAIGoTo_mt
    local self = GameTestCaseAI.new(customMt or GameTestCaseAIGoTo_mt)
    self.vehicleSetup = nil
    self.spawnPosition = nil
    self.targetPosition = nil
    return self
end
function GameTestCaseAIGoTo:setVehicleSetup(vehicleSetup)
    self.vehicleSetup = vehicleSetup
end
function GameTestCaseAIGoTo:setSpawnPosition(spawnPosition)
    self.spawnPosition = spawnPosition
end
function GameTestCaseAIGoTo:setTargetPosition(targetPosition)
    self.targetPosition = targetPosition
end
function GameTestCaseAIGoTo:finalize()
    if self.vehicleSetup == nil then
        return false
    end
    if self.spawnPosition == nil then
        return false
    end
    if self.targetPosition == nil then
        return false
    end
    self.description = string.format("Go from \'%s\' to \'%s\' with \'%s\'", self.spawnPosition.name, self.targetPosition.name, self.vehicleSetup.name)
    self.descriptionShort = string.format("GoTo %s-%s", self.spawnPosition.name, self.targetPosition.name)
    return true
end
function GameTestCaseAIGoTo:saveToXMLFile(xmlFile, key)
    GameTestCaseAIGoTo:superClass().saveToXMLFile(self, xmlFile, key)
    GameTestCaseAI.saveVehicleSetup(self.vehicleSetup, xmlFile, key .. ".vehicleSetup")
    GameTestCaseAI.savePosition(self.spawnPosition, xmlFile, key .. ".spawnPosition")
    GameTestCaseAI.savePosition(self.targetPosition, xmlFile, key .. ".targetPosition")
end
function GameTestCaseAIGoTo.generateTestCaseFromConfig(xmlFile, key)
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
    local targetPosition = GameTestCaseAI.loadPosition(xmlFile, key .. ".targetPosition")
    if targetPosition == nil then
        Logging.xmlError(xmlFile, "Unknown target position")
        return nil
    end
    local case = GameTestCaseAIGoTo.new()
    case:setVehicleSetup(vehicleSetup)
    case:setSpawnPosition(spawnPosition)
    case:setTargetPosition(targetPosition)
    if not case:finalize() then
        return nil
    end
    case:print("Found test case. (%s)", case:getDescription())
    return case
end
function GameTestCaseAIGoTo:start(finishedCallback)
    GameTestCaseAIGoTo:superClass().start(self, finishedCallback)
    self.testTask = GameTestTaskAIGoTo.new(self)
    self.testTask:setData(self.vehicleSetup, self.spawnPosition, self.targetPosition)
    self.testTask:start(function(result, reason)
        -- upvalues: (copy) self, (copy) finishedCallback
        self:onFinished(result, reason, finishedCallback)
    end)
end
function GameTestCaseAIGoTo.generateTestCases(targetTable, xmlFile, key)
    local spawnPositions = GameTestCaseAI.loadSpawnPositions(xmlFile, key)
    local vehicleSetups = GameTestCaseAI.loadVehicleSetups(xmlFile, key)
    local s = 1
    for s = s, #spawnPositions do
        local t = 1
        for t = t, #spawnPositions do
            if s ~= t then
                local v = 1
                for v = v, #vehicleSetups do
                    local case = GameTestCaseAIGoTo.new()
                    case:setVehicleSetup(vehicleSetups[v])
                    case:setSpawnPosition(spawnPositions[s])
                    case:setTargetPosition(spawnPositions[t])
                    if case:finalize() then
                        case:print("Found test case. (%s)", case:getDescription())
                        table.insert(targetTable, case)
                    end
                end
            end
        end
    end
end
function GameTestCaseAIGoTo.registerXMLPaths(schema, baseKey) end
GameTestManager.registerTestCase(GameTestCaseAIGoTo)