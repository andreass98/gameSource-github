GameTestCaseAIFieldWork = {}
GameTestCaseAIFieldWork.WORK_TYPE = {}
GameTestCaseAIFieldWork.WORK_TYPE.CULTIVATION = 1
GameTestCaseAIFieldWork.WORK_TYPE.SOWING = 2
GameTestCaseAIFieldWork.WORK_TYPE.COMBINE_HARVESTER = 3
GameTestCaseAIFieldWork.WORK_TYPE.SPRAYING = 4
GameTestCaseAIFieldWork.WORK_TYPE.MOWING = 5
GameTestCaseAIFieldWork.WORK_TYPE.PLOWING = 6
Enum(GameTestCaseAIFieldWork.WORK_TYPE)
GameTestCaseAIFieldWork.WORK_TYPE_TO_NAME = {}
GameTestCaseAIFieldWork.WORK_TYPE_TO_NAME[GameTestCaseAIFieldWork.WORK_TYPE.CULTIVATION] = "Cultivation"
GameTestCaseAIFieldWork.WORK_TYPE_TO_NAME[GameTestCaseAIFieldWork.WORK_TYPE.SOWING] = "Sowing"
GameTestCaseAIFieldWork.WORK_TYPE_TO_NAME[GameTestCaseAIFieldWork.WORK_TYPE.COMBINE_HARVESTER] = "Combine Harvester"
GameTestCaseAIFieldWork.WORK_TYPE_TO_NAME[GameTestCaseAIFieldWork.WORK_TYPE.SPRAYING] = "Spraying"
GameTestCaseAIFieldWork.WORK_TYPE_TO_NAME[GameTestCaseAIFieldWork.WORK_TYPE.MOWING] = "Mowing"
GameTestCaseAIFieldWork.WORK_TYPE_TO_NAME[GameTestCaseAIFieldWork.WORK_TYPE.PLOWING] = "Plowing"
local GameTestCaseAIFieldWork_mt = Class(GameTestCaseAIFieldWork, GameTestCaseAI)
function GameTestCaseAIFieldWork.new(customMt)
    -- upvalues: (copy) GameTestCaseAIFieldWork_mt
    local self = GameTestCaseAI.new(customMt or GameTestCaseAIFieldWork_mt)
    self.vehicleSetup = nil
    self.spawnPosition = nil
    self.workType = nil
    self.fruitTypeIndex = nil
    self.minFieldPercentage = 0.95
    self.maxLeftOverArea = 100
    return self
end
function GameTestCaseAIFieldWork:setVehicleSetup(vehicleSetup)
    self.vehicleSetup = vehicleSetup
end
function GameTestCaseAIFieldWork:setSpawnPosition(spawnPosition)
    self.spawnPosition = spawnPosition
end
function GameTestCaseAIFieldWork:setWorkType(workType)
    self.workType = workType
end
function GameTestCaseAIFieldWork:setFruitTypeIndex(fruitTypeIndex)
    self.fruitTypeIndex = fruitTypeIndex
end
function GameTestCaseAIFieldWork:setSegments(segments)
    self.segments = segments
end
function GameTestCaseAIFieldWork:setSegmentStartIndex(segmentStartIndex)
    self.segmentStartIndex = segmentStartIndex
end
function GameTestCaseAIFieldWork:setGoals(minFieldPercentage, maxLeftOverArea)
    self.minFieldPercentage = minFieldPercentage or self.minFieldPercentage
    self.maxLeftOverArea = maxLeftOverArea or self.maxLeftOverArea
end
function GameTestCaseAIFieldWork:finalize()
    if self.vehicleSetup == nil then
        return false
    end
    if self.spawnPosition == nil then
        return false
    end
    if self.workType == nil then
        return false
    end
    local workName = GameTestCaseAIFieldWork.WORK_TYPE_TO_NAME[self.workType]
    self.description = string.format("%s on \'%s\' with \'%s\'", workName, self.spawnPosition.name, self.vehicleSetup.name)
    self.descriptionShort = string.format("%s on %s", workName, self.spawnPosition.name)
    return true
end
function GameTestCaseAIFieldWork:saveToXMLFile(xmlFile, key)
    GameTestCaseAIFieldWork:superClass().saveToXMLFile(self, xmlFile, key)
    GameTestCaseAI.saveVehicleSetup(self.vehicleSetup, xmlFile, key .. ".vehicleSetup")
    GameTestCaseAI.savePosition(self.spawnPosition, xmlFile, key .. ".spawnPosition")
    GameTestCaseAIFieldWork.saveSegments(self.segments, xmlFile, key)
    xmlFile:setString(key .. "#workType", GameTestCaseAIFieldWork.WORK_TYPE.getName(self.workType))
    if self.fruitTypeIndex ~= nil then
        xmlFile:setString(key .. "#fruitType", g_fruitTypeManager:getFruitTypeNameByIndex(self.fruitTypeIndex))
    end
    xmlFile:setFloat(key .. ".goals#minFieldPercentage", self.minFieldPercentage)
    xmlFile:setFloat(key .. ".goals#maxLeftOverArea", self.maxLeftOverArea)
end
function GameTestCaseAIFieldWork.generateTestCaseFromConfig(xmlFile, key)
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
    local workType = nil
    local workTypeStr = xmlFile:getString(key .. "#workType")
    if workTypeStr ~= nil then
        workType = GameTestCaseAIFieldWork.WORK_TYPE[string.upper(workTypeStr)]
    end
    if workType == nil then
        Logging.xmlError(xmlFile, "Unknown work type")
        return nil
    end
    local fruitTypeIndex = nil
    local fruitTypeStr = xmlFile:getString(key .. "#fruitType")
    if fruitTypeStr ~= nil then
        fruitTypeIndex = g_fruitTypeManager:getFruitTypeIndexByName(fruitTypeStr)
    end
    local minFieldPercentage = xmlFile:getFloat(key .. ".goals#minFieldPercentage")
    local maxLeftOverArea = xmlFile:getFloat(key .. ".goals#maxLeftOverArea")
    local case = GameTestCaseAIFieldWork.new()
    case:setVehicleSetup(vehicleSetup)
    case:setSpawnPosition(spawnPosition)
    case:setWorkType(workType)
    case:setFruitTypeIndex(fruitTypeIndex)
    case:setGoals(minFieldPercentage, maxLeftOverArea)
    if StartParams.getIsSet("gameTestCaseSegmentIndex") then
        case:setSegments(GameTestCaseAIFieldWork.loadSegments(xmlFile, key))
        case:setSegmentStartIndex(StartParams.getValue("gameTestCaseSegmentIndex"))
    end
    if not case:finalize() then
        return nil
    end
    case:print("Loaded test case from XML. (%s)", case:getDescription())
    return case
end
function GameTestCaseAIFieldWork:start(finishedCallback)
    GameTestCaseAIFieldWork:superClass().start(self, finishedCallback)
    self.testTask = GameTestTaskAIFieldWork.new(self)
    self.testTask:setData(self.vehicleSetup, self.spawnPosition, self.workType, self.fruitTypeIndex, self.segments, self.segmentStartIndex, self.minFieldPercentage, self.maxLeftOverArea)
    self.testTask:start(function(result, reason)
        -- upvalues: (copy) self, (copy) finishedCallback
        self.descriptionShort = self.descriptionShort .. string.format(" (%.2f%%)", self.testTask.fieldAreaSuccessPct * 100)
        self:onFinished(result, reason, finishedCallback)
    end)
end
function GameTestCaseAIFieldWork.generateTestCases(targetTable, xmlFile, key)
    local spawnPositions = GameTestCaseAI.loadSpawnPositions(xmlFile, key)
    local vehicleSetups = GameTestCaseAI.loadVehicleSetups(xmlFile, key)
    local workTypeStr = xmlFile:getString(key .. "#workType")
    if workTypeStr ~= nil then
        local workType = GameTestCaseAIFieldWork.WORK_TYPE[string.upper(workTypeStr)]
        if workType ~= nil then
            local minFieldPercentage = xmlFile:getFloat(key .. ".goals#minFieldPercentage")
            local maxLeftOverArea = xmlFile:getFloat(key .. ".goals#maxLeftOverArea")
            local fruitTypeIndex = nil
            local fruitTypeStr = xmlFile:getString(key .. "#fruitType")
            if fruitTypeStr ~= nil then
                fruitTypeIndex = g_fruitTypeManager:getFruitTypeIndexByName(fruitTypeStr)
            end
            local s = 1
            for s = s, #spawnPositions do
                local v = 1
                for v = v, #vehicleSetups do
                    local case = GameTestCaseAIFieldWork.new()
                    case:setVehicleSetup(vehicleSetups[v])
                    case:setSpawnPosition(spawnPositions[s])
                    case:setWorkType(workType)
                    case:setFruitTypeIndex(fruitTypeIndex)
                    case:setGoals(minFieldPercentage, maxLeftOverArea)
                    if case:finalize() then
                        case:print("Found test case. (%s)", case:getDescription())
                        table.insert(targetTable, case)
                    end
                end
            end
        end
    end
end
function GameTestCaseAIFieldWork.loadSegments(xmlFile, key)
    key = not xmlFile:hasProperty(key .. ".segments") and "testCaseReport.aiFieldWorker" or key
    local segments = {}
    for index, segmentKey in xmlFile:iterator(key .. ".segments.segment") do
        local segment = {
            ["index"] = index,
            ["isTurn"] = xmlFile:getBool(key .. "#isTurn", false),
            ["isHeadlandSegment"] = xmlFile:getBool(key .. "#isHeadlandSegment", false),
            ["isIslandSegment"] = xmlFile:getBool(key .. "#isIslandSegment", false),
            ["length"] = xmlFile:getBool(key .. "#length", 0),
            ["positions"] = {}
        }
        for _, positionKey in xmlFile:iterator(segmentKey .. ".position") do
            local value = xmlFile:getVector(positionKey .. "#value")
            table.insert(segment.positions, value)
        end
        table.insert(segments, segment)
    end
    return segments
end
function GameTestCaseAIFieldWork.saveSegments(segments, xmlFile, key)
    if segments ~= nil then
        for index, segment in ipairs(segments) do
            local segmentsKey = string.format("%s.segments.segment(%d)", key, index - 1)
            xmlFile:setBool(segmentsKey .. "#isTurn", Utils.getNoNil(segment.isTurn, false))
            xmlFile:setBool(segmentsKey .. "#isHeadlandSegment", Utils.getNoNil(segment.isHeadlandSegment, false))
            xmlFile:setBool(segmentsKey .. "#isIslandSegment", Utils.getNoNil(segment.isIslandSegment, false))
            xmlFile:setFloat(segmentsKey .. "#length", segment.length or 0)
            for positionIndex, position in ipairs(segment.positions) do
                xmlFile:setVector(string.format("%s.position(%d)", segmentsKey, positionIndex - 1) .. "#value", position)
            end
        end
    end
end
function GameTestCaseAIFieldWork.registerXMLPaths(schema, baseKey) end
GameTestManager.registerTestCase(GameTestCaseAIFieldWork)