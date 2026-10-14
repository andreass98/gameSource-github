GameStats = {}
GameStats.STEP_IDLE = 1
GameStats.STEP_UPDATE_FARMLANDS = 2
GameStats.STEP_UPDATE_FIELDS = 3
GameStats.STEP_UPDATE_PLAYERS = 4
GameStats.STEP_UPDATE_VEHICLES_INIT = 5
GameStats.STEP_UPDATE_VEHICLES = 6
GameStats.STEP_UPDATE_FINISHED = 7
local GameStats_mt = Class(GameStats)
function GameStats.new(filename, updateIntervalMs, customMt)
    -- upvalues: (copy) GameStats_mt
    local self = setmetatable({}, customMt or GameStats_mt)
    self.statsXMLFile = nil
    self.filename = filename
    self.updateIntervalMs = updateIntervalMs
    self.updateTime = 0
    self.maxVehiclesPerFrame = 3
    self.pendingVehicles = {}
    self.currentStep = GameStats.STEP_IDLE
    return self
end
function GameStats:init(mission)
    local xmlFile = createXMLFile("serverStatsFile", self.filename, "Server")
    if xmlFile == 0 then
        Logging.error("Failed to create serverStats xml file")
    else
        self.mission = mission
        self.statsXMLFile = xmlFile
        local mapName = "Unknown"
        local map = g_mapManager:getMapById(mission.missionInfo.mapId)
        if map ~= nil then
            mapName = map.title
        end
        setXMLString(xmlFile, "Server#game", g_gameTitle)
        setXMLString(xmlFile, "Server#version", g_gameVersionDisplay .. g_gameVersionDisplayExtra)
        setXMLString(xmlFile, "Server#mapOverviewFilename", NetworkUtil.convertToNetworkFilename(mission.mapImageFilename))
        setXMLInt(xmlFile, "Server#mapSize", mission.terrainSize or 2048)
        setXMLString(xmlFile, "Server#mapName", HTMLUtil.encodeToHTML(mapName))
        setXMLInt(xmlFile, "Server.Slots#capacity", 1)
        setXMLInt(xmlFile, "Server.Slots#numUsed", 0)
        local i = 0
        for _, mod in pairs(mission.missionDynamicInfo.mods) do
            local modKey = string.format("Server.Mods.Mod(%d)", i)
            setXMLString(xmlFile, modKey .. "#name", HTMLUtil.encodeToHTML(mod.modName))
            setXMLString(xmlFile, modKey .. "#author", HTMLUtil.encodeToHTML(mod.author))
            setXMLString(xmlFile, modKey .. "#version", HTMLUtil.encodeToHTML(mod.version))
            setXMLString(xmlFile, modKey, HTMLUtil.encodeToHTML(mod.title, true))
            if mod.fileHash ~= nil then
                setXMLString(xmlFile, modKey .. "#hash", HTMLUtil.encodeToHTML(mod.fileHash))
            end
            i = i + 1
        end
        for _, mod in ipairs(g_farmlandManager.sortedFarmlands) do
            local modKey = string.format("Server.Farmlands.Farmland(%d)", _ - 1)
            setXMLString(xmlFile, modKey .. "#name", (tostring(mod.name)))
            setXMLInt(xmlFile, modKey .. "#id", mod.id)
            setXMLInt(xmlFile, modKey .. "#owner", g_farmlandManager:getFarmlandOwner(mod.id))
            setXMLFloat(xmlFile, modKey .. "#area", mod.areaInHa)
            setXMLInt(xmlFile, modKey .. "#price", (math.round(mod.price)))
            setXMLFloat(xmlFile, modKey .. "#x", mod.xWorldPos)
            setXMLFloat(xmlFile, modKey .. "#z", mod.zWorldPos)
        end
        for _, mod in ipairs(g_fieldManager:getFields()) do
            local modKey = string.format("Server.Fields.Field(%d)", _ - 1)
            setXMLString(xmlFile, modKey .. "#id", (tostring(mod:getId())))
            setXMLFloat(xmlFile, modKey .. "#x", mod.posX)
            setXMLFloat(xmlFile, modKey .. "#z", mod.posZ)
            setXMLBool(xmlFile, modKey .. "#isOwned", mod:getHasOwner())
        end
        saveXMLFile(xmlFile)
        g_messageCenter:subscribe(MessageType.USER_ADDED, self.onUserAdded, self)
        g_messageCenter:subscribe(MessageType.USER_REMOVED, self.onUserRemoved, self)
        if mission:getIsServer() and g_addTestCommands then
            addConsoleCommand("gsGameStatsUpdate", "Updates the game stats xml file", "consoleCommandUpdateGameStats", self)
        end
    end
end
function GameStats:delete()
    if self.statsXMLFile ~= nil then
        delete(self.statsXMLFile)
        self.statsXMLFile = nil
    end
    self.mission = nil
    g_messageCenter:unsubscribeAll(self)
    removeConsoleCommand("gsGameStatsUpdate")
end
function GameStats:update(dt)
    if self.updateTime > 0 then
        self.updateTime = self.updateTime - dt
    else
        self:processStep()
    end
end
function GameStats:processStep()
    if self.statsXMLFile == nil then
        return
    elseif self.currentStep == GameStats.STEP_IDLE then
        self.currentStep = GameStats.STEP_UPDATE_FARMLANDS
        self:updateStatsInfo()
        return
    elseif self.currentStep == GameStats.STEP_UPDATE_FARMLANDS then
        self.currentStep = GameStats.STEP_UPDATE_FIELDS
        self:updateStatsFarmlands()
        return
    elseif self.currentStep == GameStats.STEP_UPDATE_FIELDS then
        self.currentStep = GameStats.STEP_UPDATE_PLAYERS
        self:updateStatsFields()
        return
    elseif self.currentStep == GameStats.STEP_UPDATE_PLAYERS then
        self.currentStep = GameStats.STEP_UPDATE_VEHICLES_INIT
        self:updateStatsPlayers()
        return
    elseif self.currentStep == GameStats.STEP_UPDATE_VEHICLES_INIT then
        self.currentStep = GameStats.STEP_UPDATE_VEHICLES
        self:updateStatsVehiclesInit()
        return
    elseif self.currentStep == GameStats.STEP_UPDATE_VEHICLES then
        if #self.pendingVehicles == 0 then
            self.currentStep = GameStats.STEP_UPDATE_FINISHED
        else
            self:updateStatsVehicleStep()
        end
    else
        if self.currentStep == GameStats.STEP_UPDATE_FINISHED then
            self.currentStep = GameStats.STEP_IDLE
            self:updateStatsFinished()
        end
        return
    end
end
function GameStats:updateStatsInfo()
    local xmlFile = self.statsXMLFile
    if xmlFile == nil then
        return
    elseif self.mission ~= nil then
        local dayTime = 0
        if self.mission.environment ~= nil then
            dayTime = self.mission.environment.dayTime
        end
        setXMLString(xmlFile, "Server#name", HTMLUtil.encodeToHTML(self.mission.missionDynamicInfo.serverName or ""))
        setXMLInt(xmlFile, "Server#dayTime", dayTime)
    end
end
function GameStats:updateStatsFarmlands()
    local xmlFile = self.statsXMLFile
    if xmlFile ~= nil then
        for k, farmland in ipairs(g_farmlandManager.sortedFarmlands) do
            local farmlandKey = string.format("Server.Farmlands.Farmland(%d)", k - 1)
            setXMLInt(xmlFile, farmlandKey .. "#owner", g_farmlandManager:getFarmlandOwner(farmland.id))
        end
    end
end
function GameStats:updateStatsFields()
    local xmlFile = self.statsXMLFile
    if xmlFile ~= nil then
        for k, field in ipairs(g_fieldManager:getFields()) do
            local fieldKey = string.format("Server.Fields.Field(%d)", k - 1)
            setXMLBool(xmlFile, fieldKey .. "#isOwned", field:getHasOwner())
        end
    end
end
function GameStats:updateStatsPlayers()
    local xmlFile = self.statsXMLFile
    if xmlFile == nil then
        return
    elseif self.mission ~= nil then
        local userManager = self.mission.userManager
        local numUsers = userManager:getNumberOfUsers()
        if g_dedicatedServer ~= nil then
        end
        local capacity = self.mission.missionDynamicInfo.capacity or 0
        setXMLInt(xmlFile, "Server.Slots#capacity", capacity)
        setXMLInt(xmlFile, "Server.Slots#numUsed", numUsers)
        local i = 1
        for i = i, g_serverMaxCapacity do
            local playerKey = string.format("Server.Slots.Player(%d)", i - 1)
            removeXMLProperty(xmlFile, playerKey)
            if i <= capacity then
                local user = userManager:getUsers()[i + 1]
                if user == nil then
                    setXMLBool(xmlFile, playerKey .. "#isUsed", false)
                else
                    local player = nil
                    local connection = user:getConnection()
                    if connection ~= nil then
                        player = self.mission.connectionsToPlayer[connection]
                    end
                    local x = (self.mission.time - user:getConnectedTime()) / 60000
                    local uptimeMinutes = math.round(x)
                    setXMLBool(xmlFile, playerKey .. "#isUsed", true)
                    setXMLBool(xmlFile, playerKey .. "#isAdmin", user:getIsMasterUser())
                    setXMLInt(xmlFile, playerKey .. "#uptime", uptimeMinutes)
                    if player ~= nil and (player.isControlled and (player.rootNode ~= nil and player.rootNode ~= 0)) then
                        local x, y, z = getWorldTranslation(player.rootNode)
                        setXMLFloat(xmlFile, playerKey .. "#x", x)
                        setXMLFloat(xmlFile, playerKey .. "#y", y)
                        setXMLFloat(xmlFile, playerKey .. "#z", z)
                    end
                    setXMLString(xmlFile, playerKey, HTMLUtil.encodeToHTML(user:getNickname(), true))
                end
            end
        end
    end
end
function GameStats:updateStatsVehiclesInit()
    table.clear(self.pendingVehicles)
    local xmlFile = self.statsXMLFile
    if xmlFile ~= nil then
        removeXMLProperty(xmlFile, "Server.Vehicles")
        for _, vehicle in ipairs(g_currentMission.vehicleSystem.vehicles) do
            local vehicleId = NetworkUtil.getObjectId(vehicle)
            table.insert(self.pendingVehicles, vehicleId)
        end
    end
end
function GameStats:updateStatsVehicleStep()
    local xmlFile = self.statsXMLFile
    if xmlFile == nil then
        return
    end
    local i = 0
    while self.maxVehiclesPerFrame >= i do
        local vehicleId = table.remove(self.pendingVehicles, 1)
        if vehicleId == nil then
            break
        end
        local vehicle = NetworkUtil.getObject(vehicleId)
        if vehicle ~= nil then
            local numElements = getXMLNumOfElements(xmlFile, "Server.Vehicles.Vehicle")
            vehicle:saveStatsToXMLFile(xmlFile, (string.format("Server.Vehicles.Vehicle(%d)", numElements)))
        end
        i = i + 1
    end
end
function GameStats:updateStatsFinished()
    self.updateTime = self.updateIntervalMs
    local xmlFile = self.statsXMLFile
    if xmlFile ~= nil then
        saveXMLFile(xmlFile)
    end
end
function GameStats:setDirty()
    if self.currentStep ~= GameStats.STEP_IDLE then
        return false
    end
    self.updateTime = 0
    return true
end
function GameStats:onUserAdded(_)
    self:setDirty()
end
function GameStats:onUserRemoved(_)
    self:setDirty()
end
function GameStats:consoleCommandUpdateGameStats()
    return self:setDirty() and "Triggered game stats update" or "Could not start game stats update. Update is currently in progress..."
end