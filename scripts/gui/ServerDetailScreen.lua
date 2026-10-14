ServerDetailScreen = {}
ServerDetailScreen.COLOR_RED = {
    0.8069,
    0.0097,
    0.0097,
    1
}
ServerDetailScreen.COLOR_WHITE = {
    0.89627,
    0.92158,
    0.81485,
    1
}
local ServerDetailScreen_mt = Class(ServerDetailScreen, ScreenElement)
function ServerDetailScreen.register()
    local serverDetailScreen = ServerDetailScreen.new()
    g_gui:loadGui("dataS/gui/ServerDetailScreen.xml", "ServerDetailScreen", serverDetailScreen)
    return serverDetailScreen
end
function ServerDetailScreen.new(target, custom_mt)
    -- upvalues: (copy) ServerDetailScreen_mt
    local self = ScreenElement.new(target, custom_mt or ServerDetailScreen_mt)
    self:setReturnScreenClass(JoinGameScreen)
    self.sortedMods = {}
    return self
end
function ServerDetailScreen.createFromExistingGui(gui, guiName)
    local newGui = ServerDetailScreen.new()
    g_gui.guis[guiName]:delete()
    g_gui.guis[guiName].target:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    return newGui
end
function ServerDetailScreen:onCreate(_)
    self.modList:removeElement(self.listItemTemplate)
end
function ServerDetailScreen:onCreateList(element)
    self.modList = element
end
function ServerDetailScreen:setServerInfo(id, name, language, capacity, numPlayers, mapName, mapId, hasPassword, _, modTitles, modHashes, areAllModsAvailable, allowCrossPlay, platformId)
    self.serverId = id
    self.numPlayers = numPlayers
    self.capacity = capacity
    self.areAllModsAvailable = areAllModsAvailable
    self.hasPassword = hasPassword
    self.platformId = platformId
    self.serverName = name
    self.serverNameElement:setText(name)
    self.mapElement:setText(mapName)
    self.languageElement:setText(getLanguageName(language))
    self.platformElement:setPlatformId(platformId)
    local map = g_mapManager:getMapById(mapId)
    if map == nil then
        self.mapIconElement:setImageFilename("dataS/menu/modHubPreview_default.png")
    else
        self.mapIconElement:setImageFilename(map.iconFilename)
    end
    self.passwordElement:setLocaKey(hasPassword and "ui_yes" or "ui_no")
    self.crossPlayElement:setLocaKey(allowCrossPlay and "ui_yes" or "ui_no")
    self.numPlayersElement:setText((string.format("%02d/%02d", numPlayers, capacity)))
    if numPlayers == capacity then
        self.numPlayersElement:setTextColor(unpack(ServerDetailScreen.COLOR_RED))
    else
        self.numPlayersElement:setTextColor(unpack(ServerDetailScreen.COLOR_WHITE))
    end
    self:updateStartButton()
    for index, mod in pairs(modTitles) do
        local modTitle, modVersion, modAuthor, modName = ServerDetailScreen.unpackModInfo(modTitles[index])
        local modHash = modHashes[index]
        local hash = nil
        local icon = nil
        local iconIsWeb = nil
        local author = nil
        local modHubId = nil
        local zipFilename, availability
        if g_modManager:getIsModAvailable(modHash) then
            local modItem = g_modManager:getModByFileHash(modHash)
            modTitle = modItem.title
            modVersion = modItem.version
            icon = modItem.iconFilename
            zipFilename = ""
            availability = "ui_modAvailable"
        else
            local modItem = getModIdByFilename(modName)
            if modItem == 0 or getModMetaAttributeString(modItem, "hash") ~= modHash then
                zipFilename = modName ~= nil and (modName ~= "" and modName .. ".zip") or ""
                availability = "ui_modUnavailable"
                hash = modHash
                author = modAuthor
            else
                local modHubInfo = g_modHubController:getModInfo(modItem)
                if getModMetaAttributeBool(modItem, "isDLC") then
                    modItem = modHubId
                end
                modTitle = modHubInfo:getName()
                modVersion = modHubInfo:getVersionString()
                icon = modHubInfo:getIconFilename()
                iconIsWeb = true
                zipFilename = ""
                availability = "ui_modAvailableModHub"
            end
        end
        table.insert(self.sortedMods, {
            ["title"] = modTitle,
            ["modHubId"] = modHubId,
            ["version"] = modVersion,
            ["hash"] = hash,
            ["icon"] = icon,
            ["iconIsWeb"] = iconIsWeb,
            ["availability"] = availability,
            ["zipFilename"] = zipFilename,
            ["author"] = author
        })
    end
    local availabilities = {
        ["ui_modUnavailable"] = 1,
        ["ui_modAvailableModHub"] = 2,
        ["ui_modAvailable"] = 3
    }
    table.sort(self.sortedMods, function(a, b)
        -- upvalues: (copy) availabilities
        if a.availability == b.availability then
            return a.title < b.title
        else
            return availabilities[a.availability] < availabilities[b.availability]
        end
    end)
    local hasMods = #self.sortedMods > 0
    self.noModsDLCsElement:setVisible(not hasMods)
    local index = self.notAllModsOnSystemLabel
    if hasMods then
        hasMods = not areAllModsAvailable
    end
    index:setVisible(hasMods)
    self.modList:setDataSource(self)
    self.modList:reloadData()
    local index, mod, modTitle = self:getDownloadableModsInfo()
    local modVersion = self.getModsButton
    local modName = modTitle == 0
    modVersion:setDisabled(modName)
    if Platform.hasNativeProfiles and getPlatformIdsAreCompatible(platformId, getPlatformId()) then
        self.blockOrShowButton:setText(g_i18n:getText("button_showProfile"))
        self.doShowUserProfile = true
    else
        self.blockOrShowButton:setText(g_i18n:getText("button_block"))
        self.doShowUserProfile = false
    end
end
function ServerDetailScreen:onOpen()
    ServerDetailScreen:superClass().onOpen(self)
    self.getModsButton:setVisible(Platform.hasModHub)
    self.modList:setSelectedIndex(1, nil, true)
end
function ServerDetailScreen:onClose()
    self.sortedMods = {}
    ServerDetailScreen:superClass().onClose(self)
end
function ServerDetailScreen:onClickOk()
    if self:getCanStartGame() then
        if not self.hasPassword then
            g_joinGameScreen:startGame("", self.serverId)
            return
        end
        local password = Utils.getNoNil(g_gameSettings:getTableValue(GameSettings.SETTING.JOIN_GAME, "password"), "")
        PasswordDialog.show(self.onPasswordEntered, self, nil, password)
    end
end
function ServerDetailScreen:update(dt)
    ServerDetailScreen:superClass().update(self, dt)
    self:updateStartButton()
end
function ServerDetailScreen:updateStartButton()
    local isDisabled = not self:getCanStartGame()
    if self.startElement:getIsDisabled() ~= isDisabled then
        self.startElement:setDisabled(isDisabled)
    end
end
function ServerDetailScreen:getCanStartGame()
    local canStart = self.areAllModsAvailable
    if canStart then
        canStart = self.numPlayers < self.capacity
    end
    if self.serverId ~= nil then
        local uniqueUserId, platformUserId, platformId = masterServerGetServerUserInfo(self.serverId)
        if getIsUserBlocked(uniqueUserId, platformUserId, platformId) then
            canStart = false
        end
    end
    return canStart
end
function ServerDetailScreen:getDownloadableModsInfo()
    local downloadable = {}
    local totalSize = 0
    local totalCount = 0
    for _, modInfo in ipairs(self.sortedMods) do
        if not g_modManager:getIsModAvailable(modInfo.hash) then
            local modId = modInfo.modHubId
            if modId ~= nil then
                downloadable[#downloadable + 1] = modId
                totalSize = totalSize + getModMetaAttributeInt(modId, "filesize")
            end
        end
    end
    return downloadable, totalSize, totalCount
end
function ServerDetailScreen:onClickDownload()
    if PlatformPrivilegeUtil.checkModDownload(self.onClickDownload, self) then
        local downloadable, totalSize, totalCount = self:getDownloadableModsInfo()
        local freeSpaceKb = g_modHubController:getFreeModSpaceKb()
        local text = (totalSize + 1023) / 1024
        local callback = math.floor(text)
        if freeSpaceKb < callback then
            InfoDialog.show(string.format(g_i18n:getText("modHub_installNoFreeSpace"), callback, freeSpaceKb))
        else
            local text = string.namedFormat(g_i18n:getText("ui_downloadingServerMods"), "numMods", totalCount, "filesize", string.format("%.02f", callback / 1024))
            YesNoDialog.show(function(yes)
                -- upvalues: (copy) downloadable
                if yes then
                    g_modHubController:installOrUpdateMods(downloadable, function(numFailed)
                        g_masterServerConnection:disconnectFromMasterServer()
                        g_connectionManager:shutdownAll()
                        g_modHubScreen:openDownloads()
                        if numFailed > 0 then
                            InfoDialog.show(g_i18n:getText("modHub_installFailed"))
                        end
                    end)
                end
            end, nil, text, g_i18n:getText("ui_downloadingServerModsTitle"))
        end
    else
        return
    end
end
function ServerDetailScreen:onClickBlockOrShowInfo()
    if self.doShowUserProfile then
        local _, platformUserId, _ = masterServerGetServerUserInfo(self.serverId)
        showUserProfile(platformUserId)
    else
        YesNoDialog.show(function(yes)
            -- upvalues: (copy) self
            if yes then
                local uniqueUserId, platformUserId, platformId = masterServerGetServerUserInfo(self.serverId)
                setIsUserBlocked(uniqueUserId, platformUserId, platformId, true, self.serverName)
                g_messageCenter:publish(MessageType.BLOCK_LIST_CHANGED)
                self:onClickBack()
            end
        end, nil, g_i18n:getText("ui_doYouWantToBlockThisServer"), g_i18n:getText("ui_doYouWantToBlockThisServer_title"))
    end
end
function ServerDetailScreen:onPasswordEntered(password, clickOk)
    if clickOk then
        g_gameSettings:setTableValue(GameSettings.SETTING.JOIN_GAME, "password", password)
        g_gameSettings:save()
        g_joinGameScreen:startGame(password, self.serverId)
    end
end
function ServerDetailScreen.packModInfo(modTitle, version, author, modName)
    return string.gsub(modTitle, ";", " ") .. ";" .. string.gsub(version, ";", " ") .. ";" .. string.gsub(author, ";", " ") .. ";" .. string.gsub(modName, ";", " ")
end
function ServerDetailScreen.unpackModInfo(str)
    local parts = str:split(";")
    local modTitle = parts[1]
    local version = parts[2]
    local author = parts[3]
    local modName = parts[4]
    return (modTitle == nil or modTitle == "") and "Unknown Title" or modTitle, (version == nil or version == "") and "0.0.0.1" or version, author == nil and "" or author, modName == nil and "" or modName
end
function ServerDetailScreen:getNumberOfItemsInSection(_, _)
    return #self.sortedMods
end
function ServerDetailScreen:populateCellForItemInSection(_, _, index, cell)
    local modInfo = self.sortedMods[index]
    local iconElement = cell:getAttribute("icon")
    iconElement:setVisible(modInfo.icon ~= nil)
    if modInfo.icon ~= nil then
        iconElement:setIsWebOverlay(modInfo.iconIsWeb == true)
        iconElement:setImageFilename(modInfo.icon)
    end
    cell:getAttribute("title"):setText(modInfo.title)
    cell:getAttribute("version"):setText(g_i18n:getText("ui_modVersion") .. " " .. modInfo.version)
    cell:getAttribute("zipFilename"):setText(modInfo.zipFilename)
    local hash1 = cell:getAttribute("missingIcon")
    hash1:setVisible(modInfo.availability ~= "ui_modAvailable")
    local hash1 = cell:getAttribute("missingIconBg")
    hash1:setVisible(modInfo.availability == "ui_modUnavailable")
    if modInfo.hash == nil then
        cell:getAttribute("hash"):setVisible(false)
        cell:getAttribute("author"):setVisible(false)
    else
        local hash1 = modInfo.hash:sub(1, modInfo.hash:len() / 2)
        local hash2 = hash:sub(hash:len() / 2 + 1)
        cell:getAttribute("hash"):setText(hash1 .. "\n" .. hash2)
        cell:getAttribute("hash"):setVisible(true)
        cell:getAttribute("author"):setText(modInfo.author)
        cell:getAttribute("author"):setVisible(true)
    end
end