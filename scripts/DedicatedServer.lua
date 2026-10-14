DedicatedServer = {}
DedicatedServer.PAUSE_MODE_NO = 1
DedicatedServer.PAUSE_MODE_INSTANT = 2
DedicatedServer.MIN_FRAME_LIMIT = 5
DedicatedServer.MAX_FRAME_LIMIT = 60
local DedicatedServer_mt = Class(DedicatedServer)
function DedicatedServer.new(customMt)
    -- upvalues: (copy) DedicatedServer_mt
    local self = setmetatable({}, customMt or DedicatedServer_mt)
    self.filename = ""
    self.name = "Farming Simulator Dedicated Game"
    self.password = ""
    self.savegame = 1
    self.maxPlayer = g_serverMaxCapacity
    self.ip = ""
    self.port = 10823
    self.crossplayAllowed = true
    self.mapName = ""
    self.mapFileName = ""
    self.adminPassword = ""
    self.pauseGameIfEmpty = true
    self.mpLanguageCode = "en"
    self.autoSaveInterval = 0
    self.gameStatsInterval = 60000
    self.mods = {}
    self.economicDifficulty = 1
    self.initialMoney = 100000
    self.initialLoan = 0
    self.hasStartFarm = false
    return self
end
function DedicatedServer:load(filename, gameStatsFilename)
    local xmlFile = XMLFile.load("DedicatedServerConfig", filename)
    if xmlFile ~= nil then
        self.filename = filename
        self.name = xmlFile:getString("gameserver.settings.game_name", self.name)
        self.password = xmlFile:getString("gameserver.settings.game_password", self.password)
        self.savegame = math.clamp(xmlFile:getInt("gameserver.settings.savegame_index", self.savegame), 1, SavegameController.NUM_SAVEGAMES)
        self.maxPlayer = math.clamp(xmlFile:getInt("gameserver.settings.max_player", self.maxPlayer), g_serverMinCapacity, g_serverMaxCapacity)
        self.ip = xmlFile:getString("gameserver.settings.ip", self.ip)
        self.port = xmlFile:getInt("gameserver.settings.port", self.port)
        self.crossplayAllowed = xmlFile:getBool("gameserver.settings.crossplay_allowed", self.crossplayAllowed)
        self.economicDifficulty = math.clamp(xmlFile:getInt("gameserver.settings.economicDifficulty", self.economicDifficulty), 1, 3)
        self.initialMoney = xmlFile:getInt("gameserver.settings.initialMoney", self.initialMoney)
        self.initialLoan = xmlFile:getInt("gameserver.settings.initialLoan", self.initialLoan)
        self.mapName = xmlFile:getString("gameserver.settings.mapID", self.mapName)
        self.mapFileName = xmlFile:getString("gameserver.settings.mapFilename", self.mapFileName)
        self.adminPassword = xmlFile:getString("gameserver.settings.admin_password", self.adminPassword)
        if self.adminPassword == "" then
            Logging.info("Starting dedicated server without an admin password!")
        end
        self.mpLanguageCode = xmlFile:getString("gameserver.settings.language", self.mpLanguageCode)
        self.pauseGameIfEmpty = xmlFile:getInt("gameserver.settings.pause_game_if_empty", DedicatedServer.PAUSE_MODE_INSTANT) == DedicatedServer.PAUSE_MODE_INSTANT
        self.autoSaveInterval = math.clamp(xmlFile:getInt("gameserver.settings.auto_save_interval", self.autoSaveInterval), 0, 360)
        self.gameStatsInterval = math.max(xmlFile:getInt("gameserver.settings.stats_interval", self.gameStatsInterval), 10) * 1000
        for _, modKey in xmlFile:iterator("gameserver.mods.mod") do
            local modFilename = xmlFile:getString(modKey .. "#filename")
            if xmlFile:getBool(modKey .. "#isDlc") and g_dlcModNameHasPrefix[modFilename] then
            end
            table.insert(self.mods, modFilename)
        end
        xmlFile:delete()
    end
    CaptionUtil.addText(string.format(" - ServerName: \'%s\'", self.name))
    if string.endsWith(self.mapFileName, ".dlc") and not string.startsWith(self.mapFileName, "pdlc_") then
        self.mapFileName = "pdlc_" .. self.mapFileName
    end
    local languageIndex = 0
    for languageIndex = languageIndex, getNumOfLanguages() - 1 do
        if getLanguageCode(languageIndex) == self.mpLanguageCode then
            g_gameSettings:setValue(GameSettings.SETTING.MP_LANGUAGE, languageIndex)
            break
        end
    end
    self.gameStats = GameStats.new(gameStatsFilename, self.gameStatsInterval)
end
function DedicatedServer:delete()
    if self.gameStats ~= nil then
        self.gameStats:delete()
        self.gameStats = nil
    end
end
function DedicatedServer:update(dt)
    if self.gameStats ~= nil then
        self.gameStats:update(dt)
    end
end
function DedicatedServer:onStartMission(mission)
    if self.gameStats ~= nil then
        self.gameStats:init(mission)
    end
end
function DedicatedServer:lowerFramerate()
    local frameRateLimit = DedicatedServer.MIN_FRAME_LIMIT
    Logging.devInfo("DedicatedServer:raiseFramerate: set framerate to %d", frameRateLimit)
    setFramerateLimiter(true, frameRateLimit)
end
function DedicatedServer:raiseFramerate()
    local param
    if g_isDevelopmentVersion then
        param = tonumber(StartParams.getValue("serverFrameRateLimit"))
        if param == nil then
            param = DedicatedServer.MAX_FRAME_LIMIT
        end
    else
        param = frameRateLimit
    end
    Logging.devInfo("DedicatedServer:raiseFramerate: set framerate to %d", param)
    setFramerateLimiter(true, param)
end
function DedicatedServer:updateServerInfo(serverName, password, capacity)
    if self.filename ~= nil then
        local xmlFile = XMLFile.load("DedicatedServerConfig", self.filename)
        xmlFile:setString("gameserver.settings.game_name", serverName)
        xmlFile:setString("gameserver.settings.game_password", password)
        xmlFile:setInt("gameserver.settings.max_player", capacity)
        xmlFile:save()
        xmlFile:delete()
    end
end
function DedicatedServer:start()
    g_gui:setIsMultiplayer(true)
    g_gui:showGui("CareerScreen")
    g_gameSettings:setValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME, "Server")
end