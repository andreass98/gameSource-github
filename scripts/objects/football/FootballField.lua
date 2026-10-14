FootballField = {}
source("dataS/scripts/objects/football/Football.lua")
source("dataS/scripts/objects/football/FootballFieldActivatable.lua")
source("dataS/scripts/objects/football/FootballFieldGoalEvent.lua")
source("dataS/scripts/objects/football/FootballFieldResetBallEvent.lua")
source("dataS/scripts/objects/football/FootballFieldResetEvent.lua")
source("dataS/scripts/objects/football/FootballShootEvent.lua")
local FootballField_mt = Class(FootballField, Object)
InitStaticObjectClass(FootballField, "FootballField")
g_xmlManager:addCreateSchemaFunction(function()
    FootballField.xmlSchema = XMLSchema.new("footballField")
end)
g_xmlManager:addInitSchemaFunction(function()
    local schema = FootballField.xmlSchema
    I3DUtil.registerI3dMappingXMLPaths(schema, "footballField")
    schema:register(XMLValueType.NODE_INDEX, "footballField.field#spawnPointNode", "Football spawn point node")
    schema:register(XMLValueType.NODE_INDEX, "footballField.field#gameAreaNode", "Football field game area")
    schema:register(XMLValueType.NODE_INDEX, "footballField.field#resetTriggerNode", "Field reset trigger")
    schema:register(XMLValueType.NODE_INDEX, "footballField.field.teamBlue.goal#triggerNode", "Goal trigger for team blue")
    schema:register(XMLValueType.NODE_INDEX, "footballField.field.teamBlue.scoreboard#node", "Scoreboard node for team blue")
    schema:register(XMLValueType.NODE_INDEX, "footballField.field.teamRed.goal#triggerNode", "Goal trigger for team red")
    schema:register(XMLValueType.NODE_INDEX, "footballField.field.teamRed.scoreboard#node", "Scoreboard node for team red")
    SoundManager.registerSampleXMLPaths(schema, "footballField.field.sounds", "goalBlue")
    SoundManager.registerSampleXMLPaths(schema, "footballField.field.sounds", "goalRed")
    SoundManager.registerSampleXMLPaths(schema, "footballField.field.sounds", "goal")
    SoundManager.registerSampleXMLPaths(schema, "footballField.field.sounds", "whistle")
    Football.registerXMLPaths(schema, "footballField.football")
end)
function FootballField.onCreate(_, id)
    local footballField = FootballField.new
    local footballField = footballField(g_server ~= nil, g_client ~= nil)
    if footballField:load(id) then
        g_currentMission.onCreateObjectSystem:add(footballField)
        footballField:register(true)
    else
        footballField:delete()
    end
end
function FootballField.new(isServer, isClient, customMt)
    -- upvalues: (copy) FootballField_mt
    local self = Object.new(isServer, isClient, customMt or FootballField_mt)
    registerObjectClassName(self, "FootballField")
    self.i3dMappings = {}
    self.components = {}
    return self
end
function FootballField:load(id)
    self.rootNode = id
    local xmlFilename = getUserAttribute(id, "xmlFilename")
    if xmlFilename == nil then
        Logging.warning("Missing config \'xmlFilename\' for FootballField")
        return false
    end
    local baseDirectory = g_currentMission.baseDirectory
    local xmlFile = Utils.getFilename(xmlFilename, baseDirectory)
    local xmlFile = XMLFile.load("footballField", xmlFile, FootballField.xmlSchema)
    if xmlFile == nil then
        Logging.warning("Could not load football field xml file %q", xmlFile)
        return false
    end
    table.insert(self.components, {
        ["node"] = id
    })
    I3DUtil.loadI3DMapping(xmlFile, "footballField", self.components, self.i3dMappings)
    self.football = Football.new(self.isServer, self.isClient)
    if not self.football:load(xmlFile, "footballField.football", self.components, self.i3dMappings) then
        self.football:delete()
        Logging.xmlWarning(xmlFile, "Could not load football for FootballField")
        xmlFile:delete()
        return false
    end
    self.football:register(true)
    self.footballSpawnPointNode = xmlFile:getValue("footballField.field#spawnPointNode", nil, self.components, self.i3dMappings)
    if self.footballSpawnPointNode == nil then
        Logging.xmlWarning(xmlFile, "Invalid spawnPointNode for FootballField")
        xmlFile:delete()
        return false
    end
    self.gameAreaNode = xmlFile:getValue("footballField.field#gameAreaNode", nil, self.components, self.i3dMappings)
    if self.gameAreaNode == nil then
        Logging.xmlWarning(xmlFile, "Invalid gameAreaNode for FootballField")
        xmlFile:delete()
        return false
    end
    self.resetTriggerNode = xmlFile:getValue("footballField.field#resetTriggerNode", nil, self.components, self.i3dMappings)
    if self.resetTriggerNode == nil then
        Logging.xmlWarning(xmlFile, "Invalid resetTriggerNode for FootballField")
        xmlFile:delete()
        return false
    end
    self.goalTriggerBlueNode = xmlFile:getValue("footballField.field.teamBlue.goal#triggerNode", nil, self.components, self.i3dMappings)
    if self.goalTriggerBlueNode == nil then
        Logging.xmlWarning(xmlFile, "Invalid team blue goalTriggerNode for FootballField")
        xmlFile:delete()
        return false
    end
    self.goalTriggerRedNode = xmlFile:getValue("footballField.field.teamRed.goal#triggerNode", nil, self.components, self.i3dMappings)
    if self.goalTriggerRedNode == nil then
        Logging.xmlWarning(xmlFile, "Invalid team red goalTriggerNode for FootballField")
        xmlFile:delete()
        return false
    end
    local scoreboardBlueNode = xmlFile:getValue("footballField.field.teamBlue.scoreboard#node", nil, self.components, self.i3dMappings)
    if scoreboardBlueNode == nil then
        Logging.xmlWarning(xmlFile, "Invalid team blue scoreboard node for FootballField")
        xmlFile:delete()
        return false
    end
    if xmlFile:getValue("footballField.field.teamRed.scoreboard#node", nil, self.components, self.i3dMappings) == nil then
        Logging.xmlWarning(xmlFile, "Invalid team red scoreboard node for FootballField")
        xmlFile:delete()
        return false
    end
    self.scoreboardBlue = self:createScoreboard(scoreboardBlueNode)
    self.scoreboardRed = self:createScoreboard(scoreboardRedNode)
    self.scoreBlue = 0
    self.scoreRed = 0
    self.samples = {}
    self.samples.goal = g_soundManager:loadSampleFromXML(xmlFile, "footballField.field.sounds", "goal", baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
    self.samples.goalBlue = g_soundManager:loadSampleFromXML(xmlFile, "footballField.field.sounds", "goalBlue", baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
    self.samples.goalRed = g_soundManager:loadSampleFromXML(xmlFile, "footballField.field.sounds", "goalRed", baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
    self.samples.whistle = g_soundManager:loadSampleFromXML(xmlFile, "footballField.field.sounds", "whistle", baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
    self:updateScoreboards()
    if self.isServer then
        addTrigger(self.goalTriggerBlueNode, "goalBlueCallback", self)
        addTrigger(self.goalTriggerRedNode, "goalRedCallback", self)
        addTrigger(self.gameAreaNode, "gameAreaCallback", self)
        self.ballResetTimer = Timer.new(3000)
        self.ballResetTimer:setFinishCallback(function()
            -- upvalues: (copy) self
            self:resetBall()
        end)
    end
    addTrigger(self.resetTriggerNode, "resetTriggerCallback", self)
    self.resetActivatable = FootballFieldResetActivatable.new(self)
    xmlFile:delete()
    return true
end
function FootballField:delete()
    if self.football ~= nil then
        self.football:delete()
    end
    if self.goalTriggerBlueNode ~= nil then
        removeTrigger(self.goalTriggerBlueNode)
    end
    if self.goalTriggerRedNode ~= nil then
        removeTrigger(self.goalTriggerRedNode)
    end
    if self.gameAreaNode ~= nil then
        removeTrigger(self.gameAreaNode)
    end
    if self.resetTriggerNode ~= nil then
        removeTrigger(self.resetTriggerNode)
    end
    if self.ballResetTimer ~= nil then
        self.ballResetTimer:reset()
    end
    g_soundManager:deleteSamples(self.samples)
    g_currentMission.activatableObjectsSystem:removeActivatable(self.resetActivatable)
    removeConsoleCommand("gsFootballFieldReload")
    unregisterObjectClassName(self)
    FootballField:superClass().delete(self)
end
function FootballField:readStream(streamId, connection)
    FootballField:superClass().readStream(self, streamId, connection)
    if connection:getIsServer() then
        local footballId = NetworkUtil.readNodeObjectId(streamId)
        self.football:readStream(streamId, connection)
        g_client:finishRegisterObject(self.football, footballId)
        self:setScore(streamReadUInt8(streamId), (streamReadUInt8(streamId)))
    end
end
function FootballField:writeStream(streamId, connection)
    FootballField:superClass().writeStream(self, streamId, connection)
    if not connection:getIsServer() then
        NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.football))
        self.football:writeStream(streamId, connection)
        g_server:registerObjectInStream(connection, self.football)
        streamWriteUInt8(streamId, self.scoreBlue)
        streamWriteUInt8(streamId, self.scoreRed)
    end
end
function FootballField:resetBall()
    if self.football ~= nil then
        local x, y, z = getWorldTranslation(self.footballSpawnPointNode)
        self.football:resetToWorldPosition(x, y, z, 0, 0, 0)
    end
end
function FootballField:onResetBall()
    g_soundManager:playSample(self.samples.whistle)
end
function FootballField:reset()
    g_soundManager:playSample(self.samples.whistle)
    self:setScore(0, 0)
    if self.isServer then
        self:resetBall()
    else
        g_client:getServerConnection():sendEvent(FootballFieldResetEvent.new(self))
    end
end
function FootballField:onGoal(isBlueGoal, scoreBlue, scoreRed)
    self:setScore(scoreBlue, scoreRed)
    g_soundManager:playSample(self.samples.whistle)
    g_soundManager:playSample(self.samples.goal)
    if isBlueGoal then
        g_soundManager:playSample(self.samples.goalBlue)
    else
        g_soundManager:playSample(self.samples.goalRed)
    end
end
function FootballField:onGoalBlue()
    g_server:broadcastEvent(FootballFieldGoalEvent.new(self, true, self.scoreBlue + 1, self.scoreRed), true)
end
function FootballField:onGoalRed()
    g_server:broadcastEvent(FootballFieldGoalEvent.new(self, false, self.scoreBlue, self.scoreRed + 1), true)
end
function FootballField:goalBlueCallback(_, otherId, onEnter, _, _, _)
    if onEnter and otherId ~= 0 then
        local object = g_currentMission:getNodeObject(otherId)
        if object ~= nil and (object == self.football and not self.ballResetTimer:getIsRunning()) then
            self.ballResetTimer:start()
            self:onGoalRed()
        end
    end
end
function FootballField:goalRedCallback(_, otherId, onEnter, _, _, _)
    if onEnter and otherId ~= 0 then
        local object = g_currentMission:getNodeObject(otherId)
        if object ~= nil and (object == self.football and not self.ballResetTimer:getIsRunning()) then
            self.ballResetTimer:start()
            self:onGoalBlue()
        end
    end
end
function FootballField:gameAreaCallback(_, otherId, _, onLeave, _, _)
    if onLeave and otherId ~= 0 then
        local object = g_currentMission:getNodeObject(otherId)
        if object ~= nil and object == self.football then
            self.ballResetTimer:startIfNotRunning()
            if self.isServer then
                g_server:broadcastEvent(FootballFieldResetBallEvent.new(self), true)
            end
        end
    end
end
function FootballField:resetTriggerCallback(_, otherId, onEnter, onLeave, _, _)
    if (onEnter or onLeave) and (g_localPlayer and g_localPlayer.rootNode == otherId) then
        if onEnter then
            g_currentMission.activatableObjectsSystem:addActivatable(self.resetActivatable)
            if g_isDevelopmentVersion then
                addConsoleCommand("gsFootballFieldReload", "Reload football field", "debugReloadField", self)
            end
        end
        if onLeave then
            g_currentMission.activatableObjectsSystem:removeActivatable(self.resetActivatable)
            removeConsoleCommand("gsFootballFieldReload")
        end
    end
end
function FootballField.createScoreboard(_, node)
    local fontMaterial = g_materialManager:getFontMaterial("GENERIC_BOLD", nil)
    if fontMaterial == nil then
        return nil
    end
    local scoreboard = {
        ["displayNode"] = node
    }
    local characterLine, characters = Utils.maskToFormat("00")
    scoreboard.formatStr = characterLine
    scoreboard.formatPrecision = characters
    scoreboard.fontMaterial = fontMaterial
    local characterLine = CharacterLine.new(scoreboard.displayNode, fontMaterial, ("00"):len())
    characterLine:setTextAlignment(RenderText.ALIGN_CENTER)
    characterLine:setSizeAndScale(0.7, 1, 1)
    characterLine:setColor({
        1,
        1,
        1,
        1
    }, {
        0.5,
        0.5,
        0.5,
        1
    }, 0, nil)
    scoreboard.characterLine = characterLine
    for _, char in ipairs(scoreboard.characterLine.characters) do
        setClipDistance(char, 150)
    end
    return scoreboard
end
function FootballField:updateScoreboards()
    self.scoreboardBlue.characterLine:setText(string.format("%02d", self.scoreBlue))
    self.scoreboardRed.characterLine:setText(string.format("%02d", self.scoreRed))
end
function FootballField:setScore(blue, red)
    self.scoreBlue = blue
    self.scoreRed = red
    self:updateScoreboards()
end
function FootballField:debugReloadField()
    self:delete()
    local footballField = FootballField.new
    local footballField = footballField(g_server ~= nil, g_client ~= nil)
    if footballField:load(self.rootNode) then
        footballField:register(true)
        return "Reloaded football field"
    else
        footballField:delete()
        return "Could not reload football field. Please restart the game"
    end
end