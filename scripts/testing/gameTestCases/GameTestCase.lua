GameTestCase = {}
GameTestCase.RESULT = {}
GameTestCase.RESULT.SUCCESS = 0
GameTestCase.RESULT.FAILED = 1
GameTestCase.LOG_COPY_INTERVAL = 100
local GameTestCase_mt = Class(GameTestCase)
function GameTestCase.new(customMt)
    -- upvalues: (copy) GameTestCase_mt
    local self = setmetatable({}, customMt or GameTestCase_mt)
    self.index = -1
    self.description = "none"
    self.descriptionShort = "none"
    self.resultReason = "Unknown"
    self.screenshots = {}
    self.logCopyTimer = 0
    return self
end
function GameTestCase:delete() end
function GameTestCase:getName()
    return ClassUtil.getClassNameByObject(self)
end
function GameTestCase:getFullName()
    if self.index > 0 then
        return string.format("%s #%d", ClassUtil.getClassNameByObject(self), self.index)
    else
        return self:getName()
    end
end
function GameTestCase:getDescription()
    return self.description
end
function GameTestCase:getShortDescription()
    return self.descriptionShort
end
function GameTestCase:getBaseFilename()
    return string.format("%stestCase%04d/", g_gameTestManager.currentTestFolder, self.index)
end
function GameTestCase:getFilename()
    return self:getBaseFilename() .. "report.xml"
end
function GameTestCase:loadFromConfigXML(xmlFile, key)
    return true
end
function GameTestCase:start(_)
    createFolder(self:getBaseFilename())
end
function GameTestCase:update(dt)
    if self.testTask ~= nil then
        self.testTask:update(dt)
    end
end
function GameTestCase:onFinished(result, reason, finishedCallback)
    self:print(string.format("Finished test case. Result: %s (%s)", GameTestCase.getResultName(result), reason))
    self.result = result
    self.resultReason = reason
    self:createReport(self.testTask, result)
    self.testTask:delete()
    self.testTask = nil
    finishedCallback(result)
end
function GameTestCase:takeScreenshot(name)
    local gameTestFolder = self:getBaseFilename()
    local fullPath = gameTestFolder .. string.format("screenshot_%03d_%s.png", #self.screenshots + 1, name)
    saveScreenshot(fullPath)
    local screenshot = {
        ["filename"] = fullPath:sub(string.len(gameTestFolder) + 1),
        ["position"] = { getWorldTranslation(getCamera()) }
    }
    table.insert(self.screenshots, screenshot)
end
function GameTestCase:createReport(testTask, result)
    local filename = self:getFilename()
    local xmlFile = XMLFile.create("gameTestTaskCaseReport", filename, "testCaseReport", nil)
    xmlFile:setString("testCaseReport#result", GameTestCase.getResultName(result))
    xmlFile:setString("testCaseReport#reason", self.resultReason)
    xmlFile:setString("testCaseReport#taskName", self:getName())
    xmlFile:setString("testCaseReport#description", self:getDescription())
    xmlFile:setString("testCaseReport#descriptionShort", self:getShortDescription())
    self:saveToXMLFile(xmlFile, "testCaseReport.config")
    local i = 1
    for i = i, #self.screenshots do
        local screenshot = self.screenshots[i]
        local key = string.format("testCaseReport.screenshots.screenshot(%d)", i - 1)
        xmlFile:setString(key .. "#filename", screenshot.filename)
        xmlFile:setVector(key .. "#position", screenshot.position)
    end
    if testTask ~= nil then
        testTask:fillReportXMLFile(xmlFile, "testCaseReport")
    end
    xmlFile:save()
    xmlFile:delete()
    self:print("Saved case report to \'%s\'", filename)
end
function GameTestCase:fillReportXMLFile(xmlFile) end
function GameTestCase:saveToXMLFile(xmlFile, key)
    xmlFile:setString(key .. "#className", ClassUtil.getClassNameByObject(self))
    if g_currentMission ~= nil then
        xmlFile:setString(key .. "#mapId", g_currentMission.missionInfo.mapId)
        xmlFile:setString(key .. "#mapTitle", g_currentMission.missionInfo.mapTitle)
    end
end
function GameTestCase:print(text, ...)
    g_gameTestManager:print("(" .. self:getFullName() .. "): " .. string.format(text, ...))
end
function GameTestCase.fillMetaData(xmlFile, key)
    xmlFile:setString(key .. ".map#id", g_currentMission.missionInfo.mapId)
    xmlFile:setString(key .. ".map#title", g_currentMission.missionInfo.mapTitle)
    xmlFile:setString(key .. ".map#imageFilename", NetworkUtil.convertToNetworkFilename(g_currentMission.mapImageFilename))
    local mapXMLFilename = Utils.getFilename(g_currentMission.missionInfo.mapXMLFilename, g_currentMission.baseDirectory)
    local mapXMLFile = XMLFile.load("MapXML", mapXMLFilename, Mission00.xmlSchema)
    local mapFilename = mapXMLFile:getString("map.filename")
    local mapFilename = Utils.getFilename(mapFilename, g_currentMission.baseDirectory)
    xmlFile:setString(key .. ".map#filename", NetworkUtil.convertToNetworkFilename(mapFilename))
    mapXMLFile:delete()
    for i, field in ipairs(g_fieldManager.fields) do
        local fieldKey = string.format("%s.map.fields.field(%d)", key, i - 1)
        xmlFile:setString(fieldKey .. "#fieldId", field:getName())
        xmlFile:setFloat(fieldKey .. "#posX", field.posX)
        xmlFile:setFloat(fieldKey .. "#posZ", field.posZ)
        xmlFile:setString(fieldKey .. "#name", field.name or string.format("Field %d", i))
    end
    for i, field in ipairs(g_currentMission.placeableSystem.placeables) do
        local fieldKey = string.format("%s.placeables.placeable(%d)", key, i - 1)
        xmlFile:setString(fieldKey .. "#filename", NetworkUtil.convertToNetworkFilename(field.configFileName))
        xmlFile:setString(fieldKey .. "#i3dFilename", NetworkUtil.convertToNetworkFilename(field.i3dFilename))
        xmlFile:setVector(fieldKey .. "#translation", { getWorldTranslation(field.rootNode) })
        xmlFile:setVector(fieldKey .. "#rotation", { getWorldRotation(field.rootNode) })
    end
end
function GameTestCase.registerXMLPaths(schema, baseKey) end
function GameTestCase.getResultName(resultIndex)
    for name, index in pairs(GameTestCase.RESULT) do
        if index == resultIndex then
            return name
        end
    end
    return "INVALID"
end
function GameTestCase.generateTestCases(xmlFile, key)
    Logging.error("Base GameTestCase cannot be generated!")
end
function GameTestCase.generateTestCaseFromConfig(xmlFile, key)
    Logging.error("Base GameTestCase cannot be generated from XML!")
end
GameTestManager.registerTestCase(GameTestCase)