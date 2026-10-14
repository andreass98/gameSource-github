MasterServerConnection = {}
MasterServerConnection.FAILED_NONE = 0
MasterServerConnection.FAILED_UNKNOWN = 1
MasterServerConnection.FAILED_WRONG_VERSION = 2
MasterServerConnection.FAILED_MAINTENANCE = 3
MasterServerConnection.FAILED_TEMPORARY_BAN = 4
MasterServerConnection.FAILED_PERMANENT_BAN = 5
MasterServerConnection.FAILED_CONNECTION_LOST = 6
MasterServerConnection.FAILED_TEMPORARY_BAN_INVALID_MODS = 7
MasterServerConnection.FAILED_CONSOLE_USER_FAILED_AUTHENTICATION = 8
MasterServerConnection.FAILED_WRONG_PASSWORD = 11
local MasterServerConnection_mt = Class(MasterServerConnection)
function MasterServerConnection.new()
    -- upvalues: (copy) MasterServerConnection_mt
    local self = setmetatable({}, MasterServerConnection_mt)
    self.lastBackServerIndex = -1
    self.isInit = false
    return self
end
function MasterServerConnection:setCallbackTarget(target)
    self.masterServerCallbackTarget = target
end
function MasterServerConnection:onMasterServerList(name, id)
    self.masterServerCallbackTarget:onMasterServerList(name, id)
end
function MasterServerConnection:onMasterServerListStart(numMasterServers)
    self.masterServerCallbackTarget:onMasterServerListStart(numMasterServers)
end
function MasterServerConnection:onMasterServerListEnd()
    self.masterServerCallbackTarget:onMasterServerListEnd()
end
function MasterServerConnection:onConnectionReady()
    self.masterServerCallbackTarget:onMasterServerConnectionReady()
end
function MasterServerConnection:onConnectionFailed(reason)
    self.masterServerCallbackTarget:onMasterServerConnectionFailed(reason)
end
function MasterServerConnection:onServerInfo(id, name, language, capacity, numPlayers, mapName, mapId, hasPassword, allModsAvailable, isLanServer, isFriendServer, allowCrossPlay, platformId)
    if self.masterServerCallbackTarget.onServerInfo == nil then
        Logging.devWarning("Callback target is missing onServerInfo")
    else
        self.masterServerCallbackTarget:onServerInfo(id, name, language, capacity, numPlayers, mapName, mapId, hasPassword, allModsAvailable, isLanServer, isFriendServer, allowCrossPlay, platformId)
    end
end
function MasterServerConnection:onServerInfoStart(numServers, totalNumServers)
    if self.masterServerCallbackTarget.onServerInfoStart == nil then
        Logging.devWarning("Callback target is missing onServerInfoStart")
    else
        self.masterServerCallbackTarget:onServerInfoStart(numServers, totalNumServers)
    end
end
function MasterServerConnection:onServerInfoEnd()
    if self.masterServerCallbackTarget.onServerInfoEnd == nil then
        Logging.devWarning("Callback target is missing onServerInfoEnd")
    else
        self.masterServerCallbackTarget:onServerInfoEnd()
    end
end
function MasterServerConnection:onServerInfoDetails(id, name, language, capacity, numPlayers, mapName, mapId, hasPassword, isLanServer, modTitles, modHashes, allowCrossPlay, platformId, password)
    if self.masterServerCallbackTarget.onServerInfoDetails == nil then
        Logging.devWarning("Callback target is missing onServerInfoDetails")
    else
        self.masterServerCallbackTarget:onServerInfoDetails(id, name, language, capacity, numPlayers, mapName, mapId, hasPassword, isLanServer, modTitles, modHashes, allowCrossPlay, platformId, password)
    end
end
function MasterServerConnection:onServerInfoDetailsFailed(reason)
    if self.masterServerCallbackTarget.onServerInfoDetailsFailed == nil then
        Logging.devWarning("Callback target is missing onServerInfoDetailsFailed")
    else
        self.masterServerCallbackTarget:onServerInfoDetailsFailed(reason)
    end
end
function MasterServerConnection:init()
    if not self.isInit and Platform.supportsMultiplayer then
        masterServerInit(g_gameVersion, g_gameSettings:getValue(GameSettings.SETTING.MP_LANGUAGE))
        masterServerAddDlcStart()
        for _, mod in ipairs(g_modManager:getMultiplayerMods()) do
            if string.endsWith(mod.modFile, "dlcDesc.xml") then
                masterServerAddDlc(mod.modFile)
            end
        end
        masterServerAddDlcEnd()
        masterServerSetCallbacks("onMasterServerList", "onMasterServerListStart", "onMasterServerListEnd", "onConnectionReady", "onConnectionFailed", "onServerInfo", "onServerInfoStart", "onServerInfoEnd", "onServerInfoDetails", "onServerInfoDetailsFailed", self)
        self.isInit = true
    end
end
function MasterServerConnection:connectToMasterServerFront()
    self:init()
    self.lastBackServerIndex = -1
    if Platform.supportsMultiplayer then
        masterServerConnectFront()
    end
end
function MasterServerConnection:connectToMasterServer(index)
    self:init()
    self.lastBackServerIndex = index
    if Platform.supportsMultiplayer then
        masterServerConnectBack(index)
    end
end
function MasterServerConnection:disconnectFromMasterServer()
    if Platform.supportsMultiplayer then
        masterServerDisconnect()
        self.lastBackServerIndex = -1
    end
    self.isInit = false
end
function MasterServerConnection:reconnectToMasterServer()
    if Platform.supportsMultiplayer then
        masterServerReconnect()
    end
end