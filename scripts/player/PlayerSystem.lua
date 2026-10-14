PlayerSystem = {}
local PlayerSystem_mt = Class(PlayerSystem)
PlayerSystem.MAX_NUM_SAVED_PLAYERS = 250
PlayerSystem.MAX_NUM_DAYS_OFFLINE = 30
PlayerSystem.PLAYER_STYLES_BY_FILENAME = {}
PlayerSystem.PLAYER_STYLES = {}
PlayerSystem.DEBUG_ANIMATIONS = false
PlayerSystem.DEBUG_SOUNDS = false
g_xmlManager:addEarlyCreateSchemaFunction(function()
    PlayerSystem.charactersXMLSchema = XMLSchema.new("playerModels")
    PlayerSystem.registerCharactersXMLPaths(PlayerSystem.charactersXMLSchema)
    PlayerSystem.xmlSchema = XMLSchema.new("player")
    PlayerSystem.registerXMLPaths(PlayerSystem.xmlSchema)
    PlayerSystem.savegameXMLSchema = XMLSchema.new("savegame_players")
    PlayerSystem.registerSavegameXMLPaths(PlayerSystem.savegameXMLSchema)
end)
function PlayerSystem.registerCharactersXMLPaths(charactersXMLSchema)
    charactersXMLSchema:register(XMLValueType.STRING, "playerModels.playerModel(?)#filename", "The filename of the player file", nil, true)
    charactersXMLSchema:register(XMLValueType.STRING, "playerModels.playerModel(?)#name", "The name of the player file", nil, true)
    charactersXMLSchema:register(XMLValueType.STRING, "playerModels.playerModel(?)#gender", "The gender of the player file", nil, true)
end
function PlayerSystem.registerXMLPaths(xmlSchema)
    Player.registerXMLPaths(xmlSchema)
end
function PlayerSystem.registerSavegameXMLPaths(savegameXMLSchema)
    Player.registerSavegameXMLPaths(savegameXMLSchema, "players")
end
function PlayerSystem.new()
    -- upvalues: (copy) PlayerSystem_mt
    local self = setmetatable({}, PlayerSystem_mt)
    self.players = {}
    self.playersByUniqueId = {}
    self.playersByUserId = {}
    self.playersByRootNode = {}
    self.playersByConnection = {}
    if g_server ~= nil then
        self.unloadedPlayerDataCount = 0
        self.unloadedPlayerDataByUniqueId = {}
    end
    g_messageCenter:subscribe(MessageType.USER_ADDED, PlayerSystem.onUserAdded, self)
    g_playerSystem = self
    addConsoleCommand("gsPlayerAnimationReload", "Reloads the animations", "consoleCommandAnimationReload", self)
    addConsoleCommand("gsPlayerAnimationDebug", "Toggles animation debug view", "consoleCommandAnimationDebug", self)
    addConsoleCommand("gsPlayerSoundsReload", "Reloads the sounds", "consoleCommandSoundReload", self)
    addConsoleCommand("gsPlayerSoundsDebug", "Toggles sounds debug view", "consoleCommandSoundDebug", self)
    return self
end
function PlayerSystem:delete()
    removeConsoleCommand("gsPlayerAnimationReload")
    removeConsoleCommand("gsPlayerAnimationDebug")
    removeConsoleCommand("consoleCommandSoundReload")
    removeConsoleCommand("consoleCommandSoundDebug")
    g_messageCenter:unsubscribeAll(self)
    g_playerSystem = nil
end
function PlayerSystem:saveToXMLFile(xmlFilename)
    local xmlFile = XMLFile.create("Players", xmlFilename, "players", PlayerSystem.savegameXMLSchema)
    if xmlFile == nil then
        return false
    end
    local savedPlayerCount = 0
    for i, player in ipairs(self.players) do
        player:saveToXMLFile(xmlFile, string.format("%s.player(%d)", "players", savedPlayerCount))
        savedPlayerCount = savedPlayerCount + 1
    end
    if savedPlayerCount + self.unloadedPlayerDataCount >= PlayerSystem.MAX_NUM_SAVED_PLAYERS then
        self:saveHugeUnloadedPlayers(xmlFile, "players")
    else
        self:saveUnloadedPlayers(xmlFile, "players")
    end
    xmlFile:save()
    xmlFile:delete()
    return true
end
function PlayerSystem:saveUnloadedPlayers(xmlFile, baseKey)
    local savedPlayerCount = self:getPlayerCount()
    for _, playerData in pairs(self.unloadedPlayerDataByUniqueId) do
        Player.saveDataToXMLFile(xmlFile, playerData, string.format("%s.player(%d)", baseKey, savedPlayerCount))
        savedPlayerCount = savedPlayerCount + 1
    end
end
function PlayerSystem:saveHugeUnloadedPlayers(xmlFile, baseKey)
    local savedPlayerCount = self:getPlayerCount()
    local sortedPlayerDataByLastPlayTime = table.create(self.unloadedPlayerDataCount)
    for _, playerData in pairs(self.unloadedPlayerDataByUniqueId) do
        table.insert(sortedPlayerDataByLastPlayTime, playerData)
    end
    table.sort(sortedPlayerDataByLastPlayTime, function(a, b)
        return a.lastConnectedDateTime > b.lastConnectedDateTime
    end)
    local currentYear, currentMonth, currentDay, _, playerData = string.match(getDate("%Y/%m/%d %H:%M"), "(%d+)/(%d+)/(%d+) (%d+):(%d+)")
    local maxSecondsSinceLastConnection = tonumber(currentYear)
    local maxSecondsSinceLastConnection = tonumber(currentMonth)
    local maxSecondsSinceLastConnection = tonumber(currentDay)
    local maxSecondsSinceLastConnection = tonumber(_)
    local maxSecondsSinceLastConnection = tonumber(playerData)
    for i, playerData in ipairs(sortedPlayerDataByLastPlayTime) do
        if i + savedPlayerCount > PlayerSystem.MAX_NUM_SAVED_PLAYERS then
            local year, month, day, hour, minute = string.match(playerData.lastConnectedDateTime, "(%d+)/(%d+)/(%d+) (%d+):(%d+)")
            local year = tonumber(year)
            local month = tonumber(month)
            local day = tonumber(day)
            local hour = tonumber(hour)
            local minute = tonumber(minute)
            if year ~= nil then
                if maxSecondsSinceLastConnection < math.abs((getDateDiffSeconds(year, month, day, hour, minute, 0, PlayerSystem.MAX_NUM_DAYS_OFFLINE * 24 * 60 * 60, maxSecondsSinceLastConnection, maxSecondsSinceLastConnection, maxSecondsSinceLastConnection, maxSecondsSinceLastConnection, 0))) then
                    Logging.xmlInfo(xmlFile, "Excluded %d players from player save: Limit reached and affected players did not join the server for more than %d days", savedPlayerCount + self.unloadedPlayerDataCount - (i - 1), PlayerSystem.MAX_NUM_DAYS_OFFLINE)
                    return
                end
            end
        end
        Player.saveDataToXMLFile(xmlFile, playerData, string.format("%s.player(%d)", baseKey, i + savedPlayerCount - 1))
    end
end
function PlayerSystem.loadStyleConfigurationsXML(xmlFilename)
    local xmlFile = XMLFile.loadIfExists("PlayerModels", xmlFilename, PlayerSystem.charactersXMLSchema)
    if xmlFile == nil then
        Logging.fatal("Missing models file at %s, cannot load without player data!", xmlFilename)
    end
    for i, playerConfigKey in xmlFile:iterator("playerModels.playerModel") do
        local filename = xmlFile:getValue(playerConfigKey .. "#filename", nil)
        local name = xmlFile:getValue(playerConfigKey .. "#name", nil)
        local gender = xmlFile:getValue(playerConfigKey .. "#gender", "male")
        if string.isNilOrWhitespace(filename) then
            Logging.xmlError(xmlFile, "Player model at %s has invalid filename!", playerConfigKey)
        else
            local playerStyle = PlayerStyle.new()
            playerStyle:loadConfigurationXML(filename)
            local playerStyleConfig = {
                ["filename"] = playerStyle.xmlFilename,
                ["name"] = name,
                ["gender"] = gender,
                ["style"] = playerStyle
            }
            PlayerSystem.PLAYER_STYLES_BY_FILENAME[playerStyle.xmlFilename] = playerStyleConfig
            PlayerSystem.PLAYER_STYLES[#PlayerSystem.PLAYER_STYLES + 1] = playerStyleConfig
        end
    end
    xmlFile:delete()
end
function PlayerSystem:loadFromSavegameXML(xmlFilename)
    local xmlFile = XMLFile.loadIfExists("Players", xmlFilename, PlayerSystem.savegameXMLSchema)
    if xmlFile == nil then
        if self.logDebug then
            Logging.devInfo("No players saved under %s, skipping", xmlFilename)
        end
    else
        self.unloadedPlayerDataCount = 0
        for playerIndex, playerKey in xmlFile:iterator("players.player") do
            local playerData = Player.loadDataFromXMLFile(xmlFile, playerKey)
            self.unloadedPlayerDataByUniqueId[playerData.uniqueId] = playerData
            self.unloadedPlayerDataCount = self.unloadedPlayerDataCount + 1
        end
        xmlFile:delete()
    end
end
function PlayerSystem:draw()
    for _, player in pairs(self.players) do
        if not player.isDeleted then
            player:drawUIInfo()
        end
    end
    if PlayerSystem.DEBUG_ANIMATIONS then
        local posX = 0.07
        local _ = 0.9
        local player = getCorrectTextSize(0.012)
        local numPlayer = 1
        for _, player in pairs(self.players) do
            local name = player:getNickname()
            setTextBold(true)
            renderText(posX, _ + 0.02, player, name)
            setTextBold(false)
            player:drawDebug(posX, _, player)
            posX = posX + 0.1
            numPlayer = numPlayer + 1
            if numPlayer > 9 then
                posX = 0.07
                numPlayer = 1
            end
        end
    end
    if PlayerSystem.DEBUG_SOUNDS then
        local posX = 0.07
        local _ = 0.9
        local player = getCorrectTextSize(0.012)
        local numPlayer = 1
        for _, player in pairs(self.players) do
            local name = player:getNickname()
            setTextBold(true)
            renderText(posX, _ + 0.02, player, name)
            setTextBold(false)
            player.graphicsComponent.sounds:drawDebug(posX, _, player)
            posX = posX + 0.1
            numPlayer = numPlayer + 1
            if numPlayer > 9 then
                posX = 0.07
                numPlayer = 1
            end
        end
    end
end
function PlayerSystem:getLocalPlayer()
    return g_localPlayer
end
function PlayerSystem.setLocalPlayer(_, localPlayer)
    g_localPlayer = localPlayer
end
function PlayerSystem:getHasPlayerWithUniqueId(uniqueId)
    if g_server == nil then
        return uniqueId ~= nil and self.playersByUniqueId[uniqueId] ~= nil
    else
        return uniqueId ~= nil and (self.playersByUniqueId[uniqueId] ~= nil or self.unloadedPlayerDataByUniqueId[uniqueId] ~= nil)
    end
end
function PlayerSystem:getIsPlayerAdded(player)
    return player ~= nil and player.uniqueUserId ~= nil and self:getPlayerByUniqueId(player.uniqueUserId) ~= nil
end
function PlayerSystem:getPlayerCount()
    return #self.players
end
function PlayerSystem:getPlayerByIndex(index)
    return self.players[index]
end
function PlayerSystem:getPlayerByUniqueId(uniqueId)
    return self.playersByUniqueId[uniqueId]
end
function PlayerSystem:getPlayerByUserId(userId)
    return self.playersByUserId[userId]
end
function PlayerSystem:getPlayerByRootNode(rootNode)
    return self.playersByRootNode[rootNode]
end
function PlayerSystem:getPlayerByConnection(connection)
    return self.playersByConnection[connection]
end
function PlayerSystem:getPlayerDataByUniqueId(uniqueId)
    if g_server == nil then
        return nil
    else
        return self.unloadedPlayerDataByUniqueId[uniqueId]
    end
end
function PlayerSystem:onUserAdded(user)
    local player = self:getPlayerByUserId(user:getId())
    if player == nil then
        return
    else
        local uniqueUserId = user:getUniqueUserId()
        if self:getPlayerByUniqueId(uniqueUserId) == nil then
            player:setUniqueUserId(uniqueUserId)
            self.playersByUniqueId[uniqueUserId] = player
            if g_server ~= nil and self.unloadedPlayerDataByUniqueId[uniqueUserId] ~= nil then
                self.unloadedPlayerDataByUniqueId[uniqueUserId] = nil
                self.unloadedPlayerDataCount = self.unloadedPlayerDataCount - 1
            end
        end
    end
end
function PlayerSystem:addPlayer(player)
    local existingPlayer = self:getPlayerByUserId(player.userId)
    if existingPlayer ~= nil then
        if existingPlayer ~= player then
            Logging.error("Player with user id %d exists in the system with table address of %s, but a player with the same user id tried to be added with a table address of %s!", player.userId, tostring(existingPlayer), (tostring(player)))
        end
        return false
    end
    table.insert(self.players, player)
    self.playersByUserId[player.userId] = player
    self.playersByRootNode[player.rootNode] = player
    self.playersByConnection[player.connection] = player
    if not string.isNilOrWhitespace(player.uniqueUserId) then
        self.playersByUniqueId[player.uniqueUserId] = player
        if g_server ~= nil and self.unloadedPlayerDataByUniqueId[player.uniqueUserId] ~= nil then
            self.unloadedPlayerDataByUniqueId[player.uniqueUserId] = nil
            self.unloadedPlayerDataCount = self.unloadedPlayerDataCount - 1
        end
    end
    if player.isOwner then
        self:setLocalPlayer(player)
    end
    return true
end
function PlayerSystem:removePlayer(player)
    if g_server ~= nil then
        local playerData = player:createData()
        self.unloadedPlayerDataByUniqueId[playerData.uniqueId] = playerData
        self.unloadedPlayerDataCount = self.unloadedPlayerDataCount + 1
    end
    table.removeElement(self.players, player)
    self.playersByUserId[player.userId] = nil
    self.playersByRootNode[player.rootNode] = nil
    self.playersByConnection[player.connection] = nil
    if not string.isNilOrWhitespace(player.uniqueUserId) then
        self.playersByUniqueId[player.uniqueUserId] = nil
    end
end
function PlayerSystem:consoleCommandAnimationReload()
    for _, player in ipairs(self.players) do
        if player.graphicsComponent ~= nil then
            player.graphicsComponent:loadAnimation()
        end
    end
    return "Reloaded animation"
end
function PlayerSystem:consoleCommandAnimationDebug()
    PlayerSystem.DEBUG_ANIMATIONS = not PlayerSystem.DEBUG_ANIMATIONS
    return string.format("Animation debug: %s", PlayerSystem.DEBUG_ANIMATIONS)
end
function PlayerSystem:consoleCommandSoundDebug()
    PlayerSystem.DEBUG_SOUNDS = not PlayerSystem.DEBUG_SOUNDS
    return string.format("Sound debug: %s", PlayerSystem.DEBUG_SOUNDS)
end
function PlayerSystem:consoleCommandSoundReload()
    for _, player in ipairs(self.players) do
        if player.graphicsComponent ~= nil then
            player.graphicsComponent:loadSounds()
        end
    end
    return "Reloaded animation"
end
function PlayerSystem:debugDrawAllPlayers(x, y, textSize)
    for i, player in ipairs(self.players) do
        player:debugDraw(x, y, textSize)
        x = x + 0.2
    end
end