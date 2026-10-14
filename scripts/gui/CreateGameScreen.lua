CreateGameScreen = {}
local CreateGameScreen_mt = Class(CreateGameScreen, ScreenElement)
function CreateGameScreen.register()
    local createGameScreen = CreateGameScreen.new()
    g_gui:loadGui("dataS/gui/CreateGameScreen.xml", "CreateGameScreen", createGameScreen)
    return createGameScreen
end
function CreateGameScreen.new(target, custom_mt)
    -- upvalues: (copy) CreateGameScreen_mt
    local self = ScreenElement.new(target, custom_mt or CreateGameScreen_mt)
    self.capacityTable = { "2" }
    self.capacityNumberTable = { 2 }
    self.lastCheckedPort = nil
    self.isPortTesting = false
    self.mappedPortUDP = 0
    self.mappedPortTCP = 0
    self.connectionsTable = {}
    self.connectionsInfos = {}
    if Platform.hasNetworkSettings then
        table.insert(self.connectionsTable, "DSL 6000 (6/0.5 Mbit/s)")
        table.insert(self.connectionsInfos, {
            ["maxCapacity"] = 4,
            ["uploadRate"] = 50
        })
        table.insert(self.connectionsTable, "DSL 16000 (16/1 Mbit/s)")
        table.insert(self.connectionsInfos, {
            ["maxCapacity"] = 8,
            ["uploadRate"] = 80
        })
        table.insert(self.connectionsTable, "DSL 25 (25/5 Mbit/s)")
        table.insert(self.connectionsInfos, {
            ["maxCapacity"] = 10,
            ["uploadRate"] = 150
        })
        table.insert(self.connectionsTable, "DSL 50 (50/10 Mbit/s)")
        table.insert(self.connectionsInfos, {
            ["maxCapacity"] = 12,
            ["uploadRate"] = 250
        })
        table.insert(self.connectionsTable, "DSL 100 (100/20 Mbit/s)")
        table.insert(self.connectionsInfos, {
            ["maxCapacity"] = 16,
            ["uploadRate"] = 500
        })
        table.insert(self.connectionsTable, "LAN (100/100 Mbit/s)")
        table.insert(self.connectionsInfos, {
            ["maxCapacity"] = 16,
            ["uploadRate"] = 1000
        })
        self.dedicatedServerConnectionIndex = #self.connectionsTable - 1
    else
        table.insert(self.connectionsTable, "16Mbps/1Mbps")
        table.insert(self.connectionsInfos, {
            ["maxCapacity"] = g_serverMaxCapacity,
            ["uploadRate"] = 80
        })
        self.dedicatedServerConnectionIndex = 1
    end
    self.defaultServerName = ""
    self.lastUserName = ""
    self.allowOnlyFriends = false
    self.allowCrossPlay = false
    self.autoAccept = false
    self.usePendingInvites = false
    self.mpLanguage = g_gameSettings:getValue(GameSettings.SETTING.MP_LANGUAGE)
    self.blockTime = 0
    return self
end
function CreateGameScreen.createFromExistingGui(gui, guiName)
    local newGui = CreateGameScreen.new(nil, nil, gui.startMissionInfo)
    g_gui.guis[guiName]:delete()
    g_gui.guis[guiName].target:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    return newGui
end
function CreateGameScreen:onCreate()
    self.portElementBox:setVisible(Platform.hasNetworkSettings)
    self.bandwidthElementBox:setVisible(Platform.hasNetworkSettings)
    self.allowOnlyFriendsElementBox:setVisible(Platform.hasFriendFilter)
    self.changeButton:setVisible(GS_IS_CONSOLE_VERSION)
    self.buttonBox:invalidateLayout()
    self.settingsBox:invalidateLayout()
end
function CreateGameScreen:getDefaultServerName()
    local nickname = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)
    if g_languageShort == "pl" then
        return nickname .. " - " .. g_i18n:getText("ui_serverNameGame")
    elseif nickname:endsWith("s") then
        return nickname .. "\' " .. g_i18n:getText("ui_serverNameGame")
    elseif nickname:endsWith("\'") then
        return nickname .. "s " .. g_i18n:getText("ui_serverNameGame")
    else
        return nickname .. "\'s " .. g_i18n:getText("ui_serverNameGame")
    end
end
function CreateGameScreen:onCreateNumPlayer(element)
    self.capacityElement = element
    element:setTexts(self.capacityTable)
    element:setState(#self.capacityTable)
end
function CreateGameScreen:onCreateBandwidth(element)
    self.bandwidthElement = element
    element:setTexts(self.connectionsTable)
end
function CreateGameScreen:onCreateMultiplayerLanguage(element)
    self.multiplayerLanguageElement = element
    local languageTable = {}
    local i = 0
    for i = i, getNumOfLanguages() - 1 do
        table.insert(languageTable, getLanguageName(i))
    end
    element:setTexts(languageTable)
end
function CreateGameScreen:onOpen()
    CreateGameScreen:superClass().onOpen(self)
    local mpAvailibility, _ = getCrossPlayAvailability(false)
    local reloadSettings = self.allowCrossPlayElementBox
    local numPlayers = mpAvailibility == MultiplayerAvailability.AVAILABLE
    reloadSettings:setVisible(numPlayers)
    local reloadSettings = not self.settingsLoaded
    if GS_IS_CONSOLE_VERSION then
        if self.lastUserName ~= g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME) then
            self.lastUserName = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)
            reloadSettings = true
        end
        FocusManager:setFocus(self.serverNameElement)
    end
    if reloadSettings then
        local bandwidth = g_gameSettings:getTableValue(GameSettings.SETTING.CREATE_GAME, "bandwidth")
        local i = Utils.getNoNil(bandwidth, 2)
        self.bandwidthElement:setState((math.clamp(i, 1, #self.connectionsTable)))
    end
    self:fillCapacity()
    local bandwidth = #self.capacityNumberTable
    if reloadSettings then
        self.settingsLoaded = true
        self.defaultServerName = self:getDefaultServerName()
        self.serverNameElement:setText(Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.CREATE_GAME, "serverName"), self.defaultServerName))
        self.passwordElement:setText(Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.CREATE_GAME, "password"), ""))
        local numPlayers = self.portElement
        local i = Utils.getNoNil
        numPlayers:setText((tostring(i(g_gameSettings:getTableValue(GameSettings.SETTING.CREATE_GAME, "port"), g_gameSettings:getValue(GameSettings.SETTING.DEFAULT_SERVER_PORT)))))
        self.autoAccept = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.CREATE_GAME, "autoAccept"), false)
        self.autoAcceptElement:setIsChecked(self.autoAccept, true)
        self.allowOnlyFriends = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.CREATE_GAME, "allowOnlyFriends"), false)
        self.allowOnlyFriendsElement:setIsChecked(self.allowOnlyFriends, true)
        local numPlayers = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.CREATE_GAME, "allowCrossPlay"), false)
        if numPlayers then
            numPlayers = mpAvailibility == MultiplayerAvailability.AVAILABLE
        end
        self.allowCrossPlay = numPlayers
        self.allowCrossPlayElement:setIsChecked(self.allowCrossPlay, true)
        self.mpLanguage = Utils.getNoNil(g_gameSettings:getValue(GameSettings.SETTING.MP_LANGUAGE), g_language)
        self.multiplayerLanguageElement:setState(self.mpLanguage + 1)
        local numPlayers = g_gameSettings:getTableValue(GameSettings.SETTING.CREATE_GAME, "capacity")
        if numPlayers ~= nil then
            local i = 1
            for i = i, #self.capacityNumberTable do
                if numPlayers == self.capacityNumberTable[i] then
                    bandwidth = i
                    break
                end
            end
        end
    end
    self.capacityElement:setState(bandwidth)
    local numPlayers = g_mapManager:getMapById(self.missionInfo.mapId)
    if numPlayers ~= nil then
        self.mapBackground:setImageFilename(numPlayers.iconFilename)
    end
    local i = numPlayers ~= nil
    self.mapBackground:setVisible(i)
    self.isTyping = false
    self.isPortTesting = false
    self.settingsBox:invalidateLayout()
end
function CreateGameScreen:onClickAutoAccept(_)
    self.autoAccept = self.autoAcceptElement:getIsChecked()
end
function CreateGameScreen:onClickAllowOnlyFriends(_)
    self.allowOnlyFriends = self.allowOnlyFriendsElement:getIsChecked()
end
function CreateGameScreen:onClickAllowCrossPlay(_)
    self.allowCrossPlay = self.allowCrossPlayElement:getIsChecked()
end
function CreateGameScreen:onClickNumPlayer(state)
    self.capacity = state
end
function CreateGameScreen:onClickMultiplayerLanguage(state)
    self.mpLanguage = state - 1
    self.mpLanguage = math.clamp(self.mpLanguage, 0, getNumOfLanguages() - 1)
end
function CreateGameScreen:onClickBandwidth(_)
    self:fillCapacity()
end
function CreateGameScreen:onFocus(element)
    self.currentInputElement = element
    self:showChangeButton(true)
end
function CreateGameScreen:onLeave(_)
    self.currentInputElement = nil
    self:showChangeButton(false)
end
function CreateGameScreen:onEscPressed(element)
    FocusManager:setFocus(element)
    self.isTyping = false
    self.blockTime = self.time + 250
    FocusManager:unsetFocus(element)
    FocusManager:setFocus(element)
end
function CreateGameScreen:onEnterPressed(element)
    self.blockTime = self.time + 250
    self.isTyping = false
    FocusManager:unsetFocus(element)
    FocusManager:setFocus(element)
end
function CreateGameScreen:onEnter(_)
    self.isTyping = true
end
function CreateGameScreen:onClickActivate()
    if self.currentInputElement ~= nil then
        self.currentInputElement:onFocusActivate()
    end
end
function CreateGameScreen:onClickBack()
    if not self.isTyping and self.blockTime <= self.time then
        g_startMissionInfo.canStart = false
        CreateGameScreen:superClass().onClickBack(self)
    end
end
function CreateGameScreen:onClickOk()
    if self.isTyping or self.blockTime > self.time then
        if self.currentInputElement ~= nil then
            self.currentInputElement:setForcePressed(false)
        end
        return true
    end
    CreateGameScreen:superClass().onClickOk(self)
    if not self:verifyServerName() then
        return true
    end
    g_gameSettings:setValue(GameSettings.SETTING.MP_LANGUAGE, self.mpLanguage)
    local port = self:getPort()
    local capacity = self.capacityNumberTable[self.capacityElement.state]
    g_gameSettings:setTableValue(GameSettings.SETTING.CREATE_GAME, "password", self.passwordElement.text)
    g_gameSettings:setTableValue(GameSettings.SETTING.CREATE_GAME, "serverName", self.serverNameElement.text)
    g_gameSettings:setTableValue(GameSettings.SETTING.CREATE_GAME, "port", port)
    g_gameSettings:setTableValue(GameSettings.SETTING.CREATE_GAME, "bandwidth", self.bandwidthElement.state)
    g_gameSettings:setTableValue(GameSettings.SETTING.CREATE_GAME, "capacity", capacity)
    g_gameSettings:setTableValue(GameSettings.SETTING.CREATE_GAME, "allowOnlyFriends", self.allowOnlyFriends)
    g_gameSettings:setTableValue(GameSettings.SETTING.CREATE_GAME, "allowCrossPlay", self.allowCrossPlay)
    g_gameSettings:setTableValue(GameSettings.SETTING.CREATE_GAME, "autoAccept", self.autoAccept)
    g_gameSettings:save()
    self.settingsLoaded = false
    if GS_IS_CONSOLE_VERSION then
        self.missionDynamicInfo.serverPort = g_gameSettings:getValue(GameSettings.SETTING.DEFAULT_SERVER_PORT)
    else
        self.missionDynamicInfo.serverPort = port
    end
    self.missionDynamicInfo.isMultiplayer = true
    self.missionDynamicInfo.isClient = false
    self.missionDynamicInfo.password = self.passwordElement.text
    self.missionDynamicInfo.languageId = self.mpLanguage
    self.missionDynamicInfo.allowOnlyFriends = self.allowOnlyFriends
    self.missionDynamicInfo.allowCrossPlay = self.allowCrossPlay
    self.missionDynamicInfo.serverName = self.serverNameElement.text
    self.missionDynamicInfo.capacity = capacity
    local ok = self.autoAccept
    if not ok then
        ok = g_dedicatedServer ~= nil
    end
    self.missionDynamicInfo.autoAccept = ok
    g_maxUploadRate = self.connectionsInfos[self.bandwidthElement.state].uploadRate * 1024 / 1000
    if GS_IS_CONSOLE_VERSION and capacity < 5 then
        g_maxUploadRate = g_maxUploadRate * 0.9
    end
    if GS_PLATFORM_PLAYSTATION then
        local ok, _, up, measured = netGetBandwidthEstimate()
        if ok and measured then
            g_maxUploadRate = up / 8 * 0.8 / 1000
            g_maxUploadRate = math.clamp(g_maxUploadRate, 20, 200)
        end
    end
    g_mpLoadingScreen:setMissionInfo(self.missionInfo, self.missionDynamicInfo)
    g_mpLoadingScreen:showPortTesting()
    g_mpLoadingScreen:loadSavegameAndStart()
    return false
end
function CreateGameScreen:verifyServerName()
    local serverName = self.serverNameElement.text:trim()
    local filteredServerName = filterText(serverName, false, true)
    if serverName ~= "" and serverName == filteredServerName then
        return true
    end
    if serverName == "" then
        self.serverNameElement:setText(self.defaultServerName)
    else
        self.serverNameElement:setText(filteredServerName)
        printWarning("Warning: Gamename not allowed. Profanity text filter. Gamename adjusted")
    end
    return false
end
function CreateGameScreen:getPort()
    if GS_IS_CONSOLE_VERSION then
        return g_gameSettings:getValue(GameSettings.SETTING.DEFAULT_SERVER_PORT)
    end
    local port = tonumber(self.portElement.text)
    if port == nil then
        port = g_gameSettings:getValue(GameSettings.SETTING.DEFAULT_SERVER_PORT)
    end
    self.portElement:setText((tostring(port)))
    return port
end
function CreateGameScreen:onMasterServerConnectionFailed(reason)
    if self.isPortTesting then
        self.isPortTesting = false
        netShutdown(500, 0)
        ConnectionFailedDialog.showMasterServerConnectionFailedReason(reason, "CreateGameScreen")
    end
end
function CreateGameScreen:fillCapacity()
    local bandwidth = self.bandwidthElement.state
    if g_dedicatedServer ~= nil then
        bandwidth = self.dedicatedServerConnectionIndex
    end
    self.capacityTable = {}
    self.capacityNumberTable = {}
    local i = 2
    for i = i, self.connectionsInfos[bandwidth].maxCapacity do
        table.insert(self.capacityTable, (tostring(i)))
        table.insert(self.capacityNumberTable, i)
    end
    self.capacityElement:setTexts(self.capacityTable)
    self.capacityElement:setState((math.min(self.capacityElement.state, #self.capacityTable)))
end
function CreateGameScreen:setMissionInfo(missionInfo, missionDynamicInfo)
    self.missionInfo = missionInfo
    self.missionDynamicInfo = missionDynamicInfo
end
function CreateGameScreen.onIsUnicodeAllowed(_, unicode)
    return unicode >= 48 and unicode <= 57
end
function CreateGameScreen:showChangeButton(show)
    if show ~= self.changeButton:getIsVisible() then
        self.changeButton:setVisible(show)
        self.buttonBox:invalidateLayout()
    end
end
function CreateGameScreen:update(dt)
    CreateGameScreen:superClass().update(self, dt)
    if g_dedicatedServer == nil then
        self:showChangeButton(self.currentInputElement ~= nil)
        if GS_PLATFORM_PLAYSTATION then
            if getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
                g_masterServerConnection:disconnectFromMasterServer()
                g_gui:showGui("MainScreen")
            end
            if getNetworkError() then
                g_masterServerConnection:disconnectFromMasterServer()
                ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
            end
        end
    else
        local dediData = g_dedicatedServer
        self.serverNameElement:setText((tostring(dediData.name)))
        self.passwordElement:setText((tostring(dediData.password)))
        self.portElement:setText((tostring(dediData.port)))
        self.allowCrossPlayElement:setIsChecked(dediData.crossplayAllowed)
        self.missionDynamicInfo.serverAddress = dediData.ip
        self.bandwidthElement:setState(self.dedicatedServerConnectionIndex)
        self.capacityElement:setState(dediData.maxPlayer - g_serverMinCapacity + 1)
        self.allowCrossPlay = dediData.crossplayAllowed
        if self:onClickOk() then
            self:onClickOk()
        end
    end
end