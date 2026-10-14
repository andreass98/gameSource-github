AutoSaveManager = {}
AutoSaveManager.DEFAULT_INTERVAL = 15
AutoSaveManager.INTERVAL_OPTIONS = {}
AutoSaveManager.INTERVAL_OPTIONS[1] = 0
AutoSaveManager.INTERVAL_OPTIONS[2] = 5
AutoSaveManager.INTERVAL_OPTIONS[3] = 10
AutoSaveManager.INTERVAL_OPTIONS[4] = 15
local AutoSaveManager_mt = Class(AutoSaveManager, AbstractManager)
function AutoSaveManager.new(customMt)
    -- upvalues: (copy) AutoSaveManager_mt
    local self = AbstractManager.new(customMt or AutoSaveManager_mt)
    self.interval = 60000 * AutoSaveManager.DEFAULT_INTERVAL
    self.time = self.interval
    self.isPending = false
    self.isActive = true
    self.saveNextFrame = false
    return self
end
function AutoSaveManager:loadFinished()
    g_messageCenter:subscribe(MessageType.GUI_INGAME_OPEN, self.onOpenIngameMenu, self)
    g_messageCenter:subscribe(MessageType.SAVEGAME_LOADED, self.onSavegameLoaded, self)
    if g_currentMission:getIsServer() then
        addConsoleCommand("gsAutoSave", "Enables/disables auto save", "consoleCommandAutoSave", self, "[true|false]")
        addConsoleCommand("gsAutoSaveInterval", "Sets the auto save interval", "consoleCommandAutoSaveInterval", self, "[minutes]")
    end
end
function AutoSaveManager:unloadMapData()
    g_messageCenter:unsubscribeAll(self)
    if g_currentMission:getIsServer() then
        removeConsoleCommand("gsAutoSaveInterval")
        removeConsoleCommand("gsAutoSave")
    end
end
function AutoSaveManager:update(_)
    if self:getIsAutoSaveAllowed() and (g_currentMission:getIsServer() and (g_currentMission.gameStarted and self.time < g_time)) then
        self.isPending = true
        if g_dedicatedServer ~= nil then
            self:runAutoSaveIfPending(true)
        end
    end
    if self.saveNextFrame then
        self:runAutoSaveIfPending()
        self.saveNextFrame = false
    end
end
function AutoSaveManager:runAutoSaveIfPending(hideVisuals)
    if self.isPending then
        self.isPending = false
        g_currentMission:startSaveCurrentGame(hideVisuals)
        self.time = g_time + self.interval
    end
end
function AutoSaveManager:onMissionStarted(_)
    self.time = g_time + self.interval
    self.isPending = false
end
function AutoSaveManager:onOpenIngameMenu()
    self.saveNextFrame = true
end
function AutoSaveManager:onSavegameLoaded()
    if g_dedicatedServer == nil then
        local interval = 0
        if g_currentMission ~= nil then
            if g_currentMission.missionInfo ~= nil and g_currentMission.missionInfo.autoSaveInterval ~= nil then
                interval = g_currentMission.missionInfo.autoSaveInterval
            end
            g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, AutoSaveManager.onMissionStarted, self)
        end
        if not GS_IS_MOBILE_VERSION then
            self:setInterval(interval)
        end
    end
end
function AutoSaveManager:setInterval(intervalMinutes)
    if intervalMinutes > 0 then
        self.interval = intervalMinutes * 60 * 1000
        self.time = g_time + self.interval
        self:setIsActive(true)
    else
        self:setIsActive(false)
    end
end
function AutoSaveManager:getInterval()
    return not self.isActive and 0 or self.interval / 60 / 1000
end
function AutoSaveManager.getIntervalFromIndex(_, index)
    local interval = AutoSaveManager.INTERVAL_OPTIONS[index]
    return interval == nil and 0 or interval
end
function AutoSaveManager.getIndexFromInterval(_, interval)
    for i, v in ipairs(AutoSaveManager.INTERVAL_OPTIONS) do
        if v == interval then
            return i
        end
    end
    return 1
end
function AutoSaveManager:getIntervalOptions()
    return AutoSaveManager.INTERVAL_OPTIONS
end
function AutoSaveManager:setIsActive(state)
    self.isActive = state
    if state then
        self.time = g_time + self.interval
    end
end
function AutoSaveManager:getIsActive()
    return self.isActive
end
function AutoSaveManager:resetTime()
    self.time = g_time + self.interval
end
function AutoSaveManager:getIsAutoSaveAllowed()
    if g_currentMission == nil or not g_currentMission:getIsAutoSaveSupported() then
        return false
    elseif g_appIsSuspended then
        return false
    elseif Profiler.IS_INITIALIZED then
        return false
    else
        return self.isActive
    end
end
function AutoSaveManager.consoleCommandAutoSaveInterval(_, intervalMinutes)
    if g_currentMission:getIsServer() then
        local currentInterval = tonumber(intervalMinutes)
        if currentInterval ~= nil then
            local currentInterval = math.max(currentInterval, 0)
            g_autoSaveManager:setInterval(currentInterval)
        end
        local currentInterval = g_autoSaveManager:getInterval()
        return string.format("AutoSaveInterval = %s\nArguments: intervalInMinutes", currentInterval > 0 and string.format("%d minutes", currentInterval) or "off")
    end
    printError("This is a server-only command")
end
function AutoSaveManager.consoleCommandAutoSave(_, enabledStr)
    if g_currentMission:getIsServer() then
        if enabledStr == nil or enabledStr == "" then
            return "AutoSave = " .. tostring(g_autoSaveManager:getIsActive()) .. ". Arguments: enabled[true|false]"
        end
        local enabled = Utils.stringToBoolean(enabledStr)
        g_autoSaveManager:setIsActive(enabled)
        return "AutoSave = " .. tostring(g_autoSaveManager:getIsActive())
    end
    printError("This is a server-only command")
end