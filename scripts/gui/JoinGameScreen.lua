JoinGameScreen = {}
JoinGameScreen.REFRESH_TIME = 25000
JoinGameScreen.FILTER_CHANGE_REFRESH_TIME = 500
local JoinGameScreen_mt = Class(JoinGameScreen, ScreenElement)
function JoinGameScreen.register()
    local joinGameScreen = JoinGameScreen.new()
    g_gui:loadGui("dataS/gui/JoinGameScreen.xml", "JoinGameScreen", joinGameScreen)
    return joinGameScreen
end
function JoinGameScreen.new(target, custom_mt)
    -- upvalues: (copy) JoinGameScreen_mt
    local self = ScreenElement.new(target, custom_mt or JoinGameScreen_mt)
    self.servers = {}
    self.serversBuffer = {}
    self.displayServers = {}
    self.requestedDetailsServerId = -1
    self.serverDetailsPending = false
    self.sortKey = "name"
    self.sortOrder = TableHeaderElement.SORTING_ASC
    self.totalNumServers = 0
    self.numServers = 0
    self.maxNumPlayersStates = {}
    self.maxNumPlayersNumbers = {}
    local i = g_serverMinCapacity
    for i = i, g_joinServerMaxCapacity do
        table.insert(self.maxNumPlayersStates, (tostring(i)))
        table.insert(self.maxNumPlayersNumbers, i)
    end
    self.maxNumPlayersState = #self.maxNumPlayersNumbers
    self.selectedMaxNumPlayers = self.maxNumPlayersNumbers[self.maxNumPlayersState]
    self.includePasswordProtected = true
    self.includeFullGames = true
    self.onlyWithAllModsAvailable = false
    self.allowCrossPlay = false
    self.selectedMap = ""
    self.selectedLanguageId = 0
    self.serverName = ""
    self.lastUserName = ""
    self.returnScreenClass = MultiplayerScreen
    self.lastSelectedServerName = nil
    self.lastSelectedServerMapName = nil
    if g_isDevelopmentVersion then
        JoinGameScreen.REFRESH_TIME = 10000
    end
    return self
end
function JoinGameScreen.createFromExistingGui(gui, guiName)
    local newGui = JoinGameScreen.new()
    g_gui.guis[guiName]:delete()
    g_gui.guis[guiName].target:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    return newGui
end
function JoinGameScreen:onOpen()
    JoinGameScreen:superClass().onOpen(self)
    local mpAvailibility, _ = getCrossPlayAvailability(false)
    local text = self.allowCrossPlayElement.parent
    local i = mpAvailibility == MultiplayerAvailability.AVAILABLE
    text:setVisible(i)
    self.settingsBox:invalidateLayout()
    self.mapTable = {}
    self.mapIds = {}
    local i = g_i18n
    table.insert(self.mapTable, i:getText("ui_anyMap"))
    table.insert(self.mapIds, "")
    local i = 1
    local map = g_mapManager:getNumOfMaps()
    for i = i, map do
        local map = g_mapManager:getMapDataByIndex(i)
        table.insert(self.mapTable, (Utils.limitTextToWidth(map.title, 0.025, 0.245, false, "..")))
        table.insert(self.mapIds, map.id)
    end
    self.mapSelectionElement:setTexts(self.mapTable)
    if self.showingDeepLinkingPassword then
        self.showingPasswordDialog = nil
        self.showingDeepLinkingPassword = nil
        g_deepLinkingInfo = nil
    end
    if g_deepLinkingInfo == nil then
        MessageDialog.hide()
    else
        local text = g_i18n:getText("ui_connectingPleaseWait")
        MessageDialog.show(text, nil, nil, DialogElement.TYPE_LOADING)
    end
    local text = self.mainBox
    local i = g_deepLinkingInfo ~= nil
    text:setVisible(i)
    local text = not self.settingsLoaded
    if GS_IS_CONSOLE_VERSION and self.lastUserName ~= g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME) then
        self.lastUserName = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)
        text = true
    end
    if text then
        self:loadFilterSettings()
    end
    self.isRequestPending = false
    self.serverDetailsPending = false
    g_masterServerConnection:setCallbackTarget(self)
    self.startButtonElement:setDisabled(true)
    self.detailButtonElement:setDisabled(true)
    self.numServersText:setText("")
    self.refreshTimer = JoinGameScreen.REFRESH_TIME
    self.servers = {}
    self.isInitialLoad = true
    self.serverList:reloadData()
    if not g_masterServerConnection.isInit then
        g_connectionManager:startupWithWorkingPort(g_gameSettings:getValue(GameSettings.SETTING.DEFAULT_SERVER_PORT))
        g_masterServerConnection:connectToMasterServer(g_masterServerConnection.lastBackServerIndex)
    end
    local map = self.serverList:getItemCount() == 0
    self.loadingText:setVisible(map)
    self.noMatchingGamesText:setVisible(false)
    if g_deepLinkingInfo == nil then
        self:getServers()
    else
        masterServerRequestServerDetailsWithPlatformServerId(g_deepLinkingInfo.platformServerId, mpAvailibility == MultiplayerAvailability.AVAILABLE)
    end
    g_messageCenter:subscribe(MessageType.INPUT_MODE_CHANGED, self.onInputModeChanged, self)
    self:showSortButton(false)
    g_messageCenter:subscribe(MessageType.BLOCK_LIST_CHANGED, self.getServers, self)
    Logging.info("numBlockedUsers: %d", getNumOfBlockedUsers())
end
function JoinGameScreen:onClose()
    JoinGameScreen:superClass().onClose(self)
    self.settingsLoaded = false
    self.servers = {}
    self.serversBuffer = {}
    self.displayServers = {}
    self.mapTable = {}
    self.mapIds = {}
    self.showingPasswordDialog = nil
    self.showingDeepLinkingPassword = nil
    g_messageCenter:unsubscribeAll(self)
end
function JoinGameScreen:triggerRebuildOnFilterChange()
    self:updateDisplayedServers()
end
function JoinGameScreen:onServerInfoDetails(id, name, language, capacity, numPlayers, mapName, mapId, hasPassword, isLanServer, modTitles, modHashes, allowCrossPlay, platformId, password)
    if g_isDevelopmentVersion then
        log(string.format("JoinGameScreen Id: %d\nname: %s\nlanguage: %d\ncapacity: %d\nnumPlayers: %d\nmapName: %s\nmapId: %s\nhasPassword: %s\nisLanServer: %s\nmodTitles: %s\nmodHashes: %s\nallowCrossPlay: %s\nplatformId: %s\n", id, name, language, capacity, numPlayers, mapName, mapId, tostring(hasPassword), tostring(isLanServer), modTitles, modHashes, allowCrossPlay, getDeviceTypeFromPlatformId(platformId)))
        for k, t in ipairs(modTitles) do
            log("    ", t, "> Hash:", modHashes[k])
        end
    end
    if g_deepLinkingInfo == nil then
        if id == self.requestedDetailsServerId then
            g_serverDetailScreen:setServerInfo(id, name, language, capacity, numPlayers, mapName, mapId, hasPassword, isLanServer, modTitles, modHashes, g_modManager:getAreAllModsAvailable(modHashes), allowCrossPlay, platformId)
            g_gui:showGui("ServerDetailScreen")
        end
    elseif g_deepLinkingInfo.platformServerId ~= "" then
        if hasPassword then
            self.showingPasswordDialog = true
            self.showingDeepLinkingPassword = true
            PasswordDialog.show(self.onPasswordEntered, self, {
                ["serverId"] = id,
                ["language"] = language
            }, "")
        else
            self:startGame(password, id, language)
        end
    end
    self.serverDetailsPending = false
end
function JoinGameScreen:onServerInfoDetailsFailed(reason)
    if g_deepLinkingInfo == nil then
        self.requestedDetailsServerId = -1
    else
        g_deepLinkingInfo = nil
        if reason == MasterServerServerDetailsFailedReason.NO_CROSS_PLAY then
            local _, didDialogShow = getCrossPlayAvailability(true)
            if didDialogShow then
                self.serverDetailsPending = false
                self.crossPlayDialogPendingInfo = g_deepLinkingInfo
                return
            end
            ConnectionFailedDialog.show(g_i18n:getText("ui_failedToConnectToGameCrossPlay"), g_connectionFailedDialog.onOkCallback, g_connectionFailedDialog, { "JoinGameScreen" })
        else
            ConnectionFailedDialog.show(g_i18n:getText("ui_failedToConnectToGame"), g_connectionFailedDialog.onOkCallback, g_connectionFailedDialog, { "JoinGameScreen" })
        end
    end
    self.serverDetailsPending = false
    self:getServers()
end
function JoinGameScreen:onMasterServerConnectionReady()
    self:getServers()
end
function JoinGameScreen.onMasterServerConnectionFailed(_, reason)
    g_masterServerConnection:disconnectFromMasterServer()
    g_connectionManager:shutdownAll()
    ConnectionFailedDialog.showMasterServerConnectionFailedReason(reason, "MultiplayerScreen")
end
function JoinGameScreen:onServerInfoStart(numServers, totalNumServers)
    self.totalNumServers = totalNumServers
    self.numServers = numServers
    self.serversBufferNextIndex = 1
end
function JoinGameScreen:onServerInfo(id, name, language, capacity, numPlayers, mapName, mapId, hasPassword, allModsAvailable, isLanServer, isFriendServer, allowCrossPlay, platformId)
    local server = self.serversBuffer[self.serversBufferNextIndex] or {}
    server.id = id
    server.name = name
    server.hasPassword = hasPassword
    server.language = language
    server.capacity = capacity
    server.numPlayers = numPlayers
    server.mapName = mapName
    server.mapId = mapId
    server.allModsAvailable = allModsAvailable
    server.isLanServer = isLanServer
    server.isFriendServer = isFriendServer
    server.allowCrossPlay = allowCrossPlay
    server.platformId = platformId
    server.fullness = numPlayers / capacity
    self.serversBuffer[self.serversBufferNextIndex] = server
    self.serversBufferNextIndex = self.serversBufferNextIndex + 1
end
function JoinGameScreen:onServerInfoEnd()
    local i = #self.serversBuffer
    for i = i, self.serversBufferNextIndex, -1 do
        self.serversBuffer[i] = nil
    end
    self.servers = self.serversBuffer
    self.isRequestPending = false
    self:updateDisplayedServers()
end
function JoinGameScreen:getServers()
    if self.isRequestPending or (self.serverDetailsPending or self.showingPasswordDialog) then
        Logging.devInfo("getServers cancel; isRequestPending=%s serverDetailsPending=%s showingPasswordDialog=%s", self.isRequestPending, self.serverDetailsPending, self.showingPasswordDialog)
    else
        masterServerAddAvailableModStart()
        for _, mod in ipairs(g_modManager:getMultiplayerMods()) do
            masterServerAddAvailableMod(mod.fileHash)
        end
        masterServerAddAvailableModEnd()
        self.isRequestPending = true
        masterServerRequestFilteredServers(self.selectedLanguageId, self.allowCrossPlay)
    end
end
function JoinGameScreen:buildSortFunc()
    return function(a, b)
        -- upvalues: (copy) self
        if a.isLanServer == b.isLanServer then
            if a.isFriendServer == b.isFriendServer then
                if self.sortOrder == TableHeaderElement.SORTING_ASC then
                    return a[self.sortKey] < b[self.sortKey]
                else
                    return a[self.sortKey] > b[self.sortKey]
                end
            else
                return not b.isFriendServer and a.isFriendServer
            end
        else
            return not b.isLanServer and a.isLanServer
        end
    end
end
function JoinGameScreen:updateDisplayedServers()
    local lastServerName = self.lastSelectedServerName
    self.displayServers = {}
    for _, server in ipairs(self.servers) do
        if self:filterServer(server) then
            table.insert(self.displayServers, server)
        end
    end
    table.sort(self.displayServers, self:buildSortFunc())
    self.numServersText:setText(string.format("%d / %d", #self.displayServers, self.totalNumServers))
    self.numServersBox:invalidateLayout()
    self.numServersBoxBg:setSize(self.numServersBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
    self.serverList:reloadData()
    self.loadingText:setVisible(false)
    local index = self.noMatchingGamesText
    index:setVisible(self.serverList:getItemCount() == 0)
    if self.isInitialLoad then
        if #self.displayServers > 0 then
            FocusManager:setFocus(self.serverList)
        else
            FocusManager:setFocus(self.mapSelectionElement)
        end
    end
    self.isInitialLoad = false
    self:updateButtons()
    if lastServerName ~= nil then
        local index = 1
        for server, server in ipairs(self.displayServers) do
            if server.name == lastServerName and server.mapName == self.lastSelectedServerMapName then
                index = server
                break
            end
        end
        self.serverList:setSelectedIndex(index)
    end
    if g_autoDevMP ~= nil then
        for _, server in ipairs(self.displayServers) do
            if server.name == g_autoDevMP.serverName then
                self.serverList:setSelectedIndex(_)
                self:onClickOk(true)
                return
            end
        end
        self.refreshTimer = 2500
    end
end
function JoinGameScreen:filterServer(server)
    local pwOk = self.includePasswordProtected or not server.hasPassword
    local capacityOk = self.includeFullGames
    if not capacityOk then
        capacityOk = server.numPlayers < server.capacity
    end
    local mapOk = true
    if self.selectedMap ~= "" then
        mapOk = server.mapId == self.selectedMap
    end
    local serverNameOk = self.serverName and server.name
    if serverNameOk then
        serverNameOk = true
        if self.serverName ~= "" then
            serverNameOk = string.find(utf8ToLower(server.name), utf8ToLower(self.serverName), 1, true) ~= nil
        end
    end
    if pwOk then
        if capacityOk then
            if mapOk then
                if not self.onlyWithAllModsAvailable or server.allModsAvailable then
                    if server.language == self.selectedLanguageId then
                        if not (server.capacity <= self.selectedMaxNumPlayers) then
                            serverNameOk = capOk
                        end
                    else
                        serverNameOk = languageOk
                    end
                else
                    serverNameOk = modsOk
                end
            else
                serverNameOk = mapOk
            end
        else
            serverNameOk = capacityOk
        end
    else
        serverNameOk = pwOk
    end
    return serverNameOk
end
function JoinGameScreen:onClickHeader(element)
    local sortingOrder = element:toggleSorting()
    if sortingOrder == TableHeaderElement.SORTING_OFF then
        self.sortKey = "name"
        self.sortOrder = TableHeaderElement.SORTING_ASC
    else
        self.sortKey = element.columnName
        self.sortOrder = sortingOrder
    end
    self:updateDisplayedServers()
end
function JoinGameScreen:onFocusHeader(headerElement)
    self.focusedHeaderElement = headerElement
    self:showSortButton(true)
end
function JoinGameScreen:onLeaveHeader(_)
    self.focusedHeaderElement = nil
    self:showSortButton(false)
end
function JoinGameScreen.onCreateLanguage(_, element)
    local languageTable = {}
    local numL = getNumOfLanguages()
    local i = 1
    for i = i, numL do
        table.insert(languageTable, getLanguageName(i - 1))
    end
    element:setTexts(languageTable)
end
function JoinGameScreen:onCreateMaxNumPlayers(element)
    element:setTexts(self.maxNumPlayersStates)
end
function JoinGameScreen:onFocusGameName(element)
    self.selectedInputElement = element
    self.startButtonElement:setText(g_i18n:getText("button_change"))
    self.startButtonElement:setDisabled(false)
end
function JoinGameScreen:onLeaveGameName(_)
    self.selectedInputElement = nil
    self.startButtonElement:setText(g_i18n:getText("button_start"))
    self:updateButtons()
end
function JoinGameScreen:onClickLanguage(state)
    self.selectedLanguageId = state - 1
    self.refreshTimer = JoinGameScreen.FILTER_CHANGE_REFRESH_TIME
end
function JoinGameScreen:onClickMaxNumPlayers(state)
    self.selectedMaxNumPlayers = self.maxNumPlayersNumbers[state]
    self:triggerRebuildOnFilterChange()
end
function JoinGameScreen:onClickMap(_)
    self.selectedMap = self.mapIds[self.mapSelectionElement.state]
    self:triggerRebuildOnFilterChange()
end
function JoinGameScreen:onClickPassword(_)
    self.includePasswordProtected = self.passwordElement:getIsChecked()
    self:triggerRebuildOnFilterChange()
end
function JoinGameScreen:onClickCapacity(_)
    self.includeFullGames = self.capacityElement:getIsChecked()
    self:triggerRebuildOnFilterChange()
end
function JoinGameScreen:onClickModsDlcs(_)
    self.onlyWithAllModsAvailable = self.modDlcElement:getIsChecked()
    self:triggerRebuildOnFilterChange()
end
function JoinGameScreen:onClickAllowCrossPlay(_)
    self.allowCrossPlay = self.allowCrossPlayElement:getIsChecked()
    self.refreshTimer = JoinGameScreen.FILTER_CHANGE_REFRESH_TIME
end
function JoinGameScreen:onServerNameChanged(_, text)
    self.serverName = text
    self:triggerRebuildOnFilterChange()
end
function JoinGameScreen:onClickOk(isMouseClick)
    if self.selectedInputElement == nil then
        self:saveFilterSettings()
        JoinGameScreen:superClass().onClickOk(self)
        if self.serverList.selectedIndex > 0 then
            if self:isSelectedServerValid() then
                local server = self:getSelectedServer()
                if server ~= nil and server.allModsAvailable then
                    if server.hasPassword then
                        local password = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "password"), "")
                        self.showingPasswordDialog = true
                        PasswordDialog.show(self.onPasswordEntered, self, {
                            ["serverId"] = server.id
                        }, password)
                    else
                        self:startGame("", server.id, server.language)
                    end
                end
            end
            if isMouseClick then
                self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
            end
        end
    else
        self.serverNameElement:onFocusActivate()
    end
end
function JoinGameScreen:onClickActivate()
    JoinGameScreen:superClass().onClickActivate(self)
    self:saveFilterSettings()
    local server = self:getSelectedServer()
    if server ~= nil and not self.serverDetailsPending then
        self.requestedDetailsServerId = server.id
        self.serverDetailsPending = true
        masterServerRequestServerDetails(server.id)
    end
end
function JoinGameScreen:onClickBack()
    g_startMissionInfo.canStart = false
    g_masterServerConnection:disconnectFromMasterServer()
    g_connectionManager:shutdownAll()
    self:saveFilterSettings()
    return JoinGameScreen:superClass().onClickBack(self)
end
function JoinGameScreen:onDoubleClick()
    self:onClickOk(true)
end
function JoinGameScreen:onClickSort()
    local eventUnused = JoinGameScreen:superClass().onClickMenuExtra1(self)
    if eventUnused then
        if self.focusedHeaderElement ~= nil then
            self:onClickHeader(self.focusedHeaderElement)
        end
        eventUnused = false
    end
    return eventUnused
end
function JoinGameScreen:onClickOpenBlocklist()
    UnBanDialog.show(nil, nil, true)
end
function JoinGameScreen:onInputModeChanged(_)
    self:showSortButton(self.focusedHeaderElement ~= nil)
end
function JoinGameScreen:getNumberOfItemsInSection(_, _)
    return #self.displayServers
end
function JoinGameScreen:populateCellForItemInSection(_, _, index, cell)
    local server = self.displayServers[index]
    cell:getAttribute("iconModsMissing"):setVisible(not server.allModsAvailable)
    cell:getAttribute("iconServerPassword"):setVisible(server.hasPassword)
    local numPlayers = cell:getAttribute("iconServerInternet")
    local languageCode = not server.isFriendServer
    if languageCode then
        languageCode = not server.isLanServer
    end
    numPlayers:setVisible(languageCode)
    local numPlayers = cell:getAttribute("iconServerLan")
    local languageCode = not server.isFriendServer
    if languageCode then
        languageCode = server.isLanServer
    end
    numPlayers:setVisible(languageCode)
    cell:getAttribute("iconFriends"):setVisible(server.isFriendServer)
    cell:getAttribute("iconPlatform"):setPlatformId(server.platformId)
    cell:getAttribute("gameName"):setText(server.name)
    cell:getAttribute("mapName"):setText(server.mapName)
    local numPlayers = string.format("%02d/%02d", server.numPlayers, server.capacity)
    cell:getAttribute("players"):setText(numPlayers)
    local isFull = server.numPlayers == server.capacity
    cell:getAttribute("iconSlotsFull"):setVisible(isFull)
    cell:getAttribute("iconSlotsAvailable"):setVisible(not isFull)
    local languageCode = string.upper(getLanguageCode(server.language) or "")
    cell:getAttribute("language"):setText(languageCode)
end
function JoinGameScreen:onListSelectionChanged(_, _, index)
    local server = self.displayServers[index]
    if server ~= nil then
        self.lastSelectedServerName = server.name
        self.lastSelectedServerMapName = server.mapName
    end
    self:updateButtons()
end
function JoinGameScreen:loadFilterSettings()
    self.settingsLoaded = true
    local mpAvailibility, _ = getCrossPlayAvailability(false)
    local selectedMapState = 1
    self.includePasswordProtected = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "includePasswordProtected"), true)
    self.includeFullGames = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "includeFullGames"), true)
    self.onlyWithAllModsAvailable = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "onlyWithAllModsAvailable"), false)
    local mapId = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "allowCrossPlay"), true)
    if mapId then
        mapId = mpAvailibility == MultiplayerAvailability.AVAILABLE
    end
    self.allowCrossPlay = mapId
    self.serverName = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "serverName"), "")
    if g_autoDevMP ~= nil then
        self.serverName = g_autoDevMP.serverName
    end
    self.maxNumPlayersState = #self.maxNumPlayersNumbers
    self.selectedLanguageId = g_gameSettings:getValue(GameSettings.SETTING.MP_LANGUAGE)
    local selectedLanguageId = self.selectedLanguageId
    local capacity = math.max(selectedLanguageId, 0)
    local selectedLanguageId = getNumOfLanguages() - 1
    self.selectedLanguageId = math.min(capacity, selectedLanguageId)
    local mapId = g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "mapId")
    if mapId ~= nil then
        for i, m in ipairs(self.mapIds) do
            if m == mapId then
                selectedMapState = i
                break
            end
        end
    end
    local capacity = g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "capacity")
    if capacity ~= nil then
        for m, c in ipairs(self.maxNumPlayersNumbers) do
            if c == capacity then
                self.maxNumPlayersState = m
                break
            end
        end
    end
    local selectedLanguageId = g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "language")
    if selectedLanguageId ~= nil and (selectedLanguageId >= 0 and selectedLanguageId < getNumOfLanguages()) then
        self.selectedLanguageId = selectedLanguageId
    end
    self.mapSelectionElement:setState(selectedMapState)
    self.selectedMap = self.mapIds[self.mapSelectionElement.state]
    self.passwordElement:setIsChecked(self.includePasswordProtected, true)
    self.capacityElement:setIsChecked(self.includeFullGames, true)
    self.modDlcElement:setIsChecked(self.onlyWithAllModsAvailable, true)
    self.allowCrossPlayElement:setIsChecked(self.allowCrossPlay, true)
    self.serverNameElement:setText(self.serverName)
    self.maxNumPlayersElement:setState(self.maxNumPlayersState)
    self.selectedMaxNumPlayers = self.maxNumPlayersNumbers[self.maxNumPlayersElement.state]
    local languageIndex = self.selectedLanguageId + 1
    self.languageElement:setState(languageIndex)
end
function JoinGameScreen:saveFilterSettings()
    g_gameSettings:setTableValue(GameSettings.SETTING.JOIN_GAME, "includePasswordProtected", self.passwordElement:getIsChecked())
    g_gameSettings:setTableValue(GameSettings.SETTING.JOIN_GAME, "includeFullGames", self.capacityElement:getIsChecked())
    g_gameSettings:setTableValue(GameSettings.SETTING.JOIN_GAME, "onlyWithAllModsAvailable", self.modDlcElement:getIsChecked())
    g_gameSettings:setTableValue(GameSettings.SETTING.JOIN_GAME, "allowCrossPlay", self.allowCrossPlayElement:getIsChecked())
    g_gameSettings:setTableValue(GameSettings.SETTING.JOIN_GAME, "serverName", self.serverName)
    g_gameSettings:setTableValue(GameSettings.SETTING.JOIN_GAME, "language", self.selectedLanguageId)
    g_gameSettings:setTableValue(GameSettings.SETTING.JOIN_GAME, "capacity", self.maxNumPlayersNumbers[self.maxNumPlayersElement.state])
    g_gameSettings:setTableValue(GameSettings.SETTING.JOIN_GAME, "mapId", self.mapIds[self.mapSelectionElement.state])
    g_gameSettings:save()
end
function JoinGameScreen:showSortButton(show)
    self.sortButton:setVisible(show)
    self.buttonBox:invalidateLayout()
end
function JoinGameScreen:getSelectedServer()
    return self.displayServers[self.serverList.selectedIndex]
end
function JoinGameScreen:updateButtons()
    if self.startButtonElement ~= nil then
        local isValid = self:isSelectedServerValid()
        self.startButtonElement:setDisabled(not isValid)
    end
    local isValid = self.detailButtonElement
    isValid:setDisabled(self:getSelectedServer() ~= nil)
end
function JoinGameScreen:isSelectedServerValid()
    local selectedServer = self:getSelectedServer()
    return selectedServer and selectedServer.allModsAvailable and selectedServer.numPlayers < selectedServer.capacity
end
function JoinGameScreen:onPasswordEntered(password, clickOk, args)
    self.showingPasswordDialog = nil
    self.showingDeepLinkingPassword = nil
    if clickOk then
        if g_deepLinkingInfo == nil then
            g_gameSettings:setTableValue(GameSettings.SETTING.JOIN_GAME, "password", password)
            g_gameSettings:save()
        end
        local serverId = nil
        for _, server in ipairs(self.displayServers) do
            if server.id == args.serverId then
                serverId = serverIdRequested
                break
            end
        end
        if serverId == nil then
            local text = string.format("%s\n%s", g_i18n:getText("ui_connectionFailed"), g_i18n:getText("ui_serverWasShutdown"))
            InfoDialog.show(text, nil, nil, DialogElement.TYPE_WARNING)
            return
        end
        self:startGame(password, serverId, args.language)
    end
end
function JoinGameScreen:startGame(password, serverId, languageId)
    g_maxUploadRate = 30.72
    local missionInfo = FSCareerMissionInfo.new("", nil, 0)
    missionInfo:loadDefaults()
    g_mpLoadingScreen:setMissionInfo(missionInfo, {
        ["serverId"] = serverId,
        ["isMultiplayer"] = true,
        ["isClient"] = true,
        ["password"] = password,
        ["languageId"] = languageId,
        ["allowOnlyFriends"] = false
    })
    g_gui:changeScreen(nil, MPLoadingScreen, self.returnScreenClass or MultiplayerScreen)
    g_mpLoadingScreen:startClient()
end
function JoinGameScreen:update(dt)
    JoinGameScreen:superClass().update(self, dt)
    Platform.verifyMultiplayerAvailabilityInMenu()
    if self.crossPlayDialogPendingInfo ~= nil then
        local mpAvailibility, _ = getCrossPlayAvailability(true)
        if mpAvailibility == MultiplayerAvailability.AVAILABILITY_UNKNOWN then
            return
        end
        if mpAvailibility == MultiplayerAvailability.AVAILABLE then
            g_deepLinkingInfo = self.crossPlayDialogPendingInfo
            masterServerRequestServerDetailsWithPlatformServerId(g_deepLinkingInfo.platformServerId, true)
        else
            MessageDialog.hide()
            self.mainBox:setVisible(g_deepLinkingInfo ~= nil)
            FocusManager:setFocus(self.mapSelectionElement)
            self:getServers()
        end
        self.crossPlayDialogPendingInfo = nil
    end
    if not (self.requestPending or (self.serverDetailsPending or self.showingPasswordDialog)) then
        self.refreshTimer = self.refreshTimer - dt
        if self.refreshTimer <= 0 then
            self.refreshTimer = JoinGameScreen.REFRESH_TIME
            self:getServers()
        end
    end
end