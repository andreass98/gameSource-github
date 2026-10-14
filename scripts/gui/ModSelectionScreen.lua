ModSelectionScreen = {}
ModSelectionScreen.BG_PROFILE = "fs25_modSelectionListItemBackground"
ModSelectionScreen.BG_PROFILE_SELECTED = "fs25_modSelectionListItemBackgroundSelected"
ModSelectionScreen.COLOR_MAIN_DARK = {
    0.00439,
    0.00478,
    0.00368,
    1
}
ModSelectionScreen.COLOR_MAIN_LIGHT = {
    0.89627,
    0.92158,
    0.81485,
    1
}
ModSelectionScreen.AUTHOR_NAME_GIANTS = "GIANTS Software"
local ModSelectionScreen_mt = Class(ModSelectionScreen, ScreenElement)
function ModSelectionScreen.register()
    local modSelectionScreen = ModSelectionScreen.new()
    g_gui:loadGui("dataS/gui/ModSelectionScreen.xml", "ModSelectionScreen", modSelectionScreen)
    return modSelectionScreen
end
function ModSelectionScreen.new(target, custom_mt)
    -- upvalues: (copy) ModSelectionScreen_mt
    local self = ScreenElement.new(target, custom_mt or ModSelectionScreen_mt)
    self.availableMods = {}
    self.sectionToData = {}
    self.blockedMods = {}
    self.updatableMods = {}
    self.selectedMods = {}
    self.uniqueTypesInUse = {}
    self.numAddedMods = 0
    self.numAddedModsBesidesMap = 0
    self.showBlockedError = true
    self.crossplayOnly = Platform.isConsole
    self.indexedSearch = IndexedSearch.new({
        ["title"] = 5,
        ["modName"] = 3,
        ["author"] = 2
    })
    self.overlayCache = OverlayCache.new()
    return self
end
function ModSelectionScreen.createFromExistingGui(gui, guiName)
    local newGui = ModSelectionScreen.new()
    g_gui.guis[guiName]:delete()
    g_gui.guis[guiName].target:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    newGui.missionInfo = gui.missionInfo
    newGui.missionDynamicInfo = gui.missionDynamicInfo
    return newGui
end
function ModSelectionScreen:onGuiSetupFinished()
    ModSelectionScreen:superClass().onGuiSetupFinished(self)
    self.defaultTitle = self.title:getText()
end
function ModSelectionScreen:setMissionInfo(missionInfo, missionDynamicInfo)
    self.missionInfo = missionInfo
    self.missionDynamicInfo = missionDynamicInfo
end
function ModSelectionScreen:onOpen()
    ModSelectionScreen:superClass().onOpen(self)
    self.mapModName = g_mapManager:getModNameFromMapId(self.missionInfo.mapId)
    self.checkOutdatedMods = true
    self:loadAvailableMods()
    self.buttonToggleCrossplay:setText(self.crossplayOnly and g_i18n:getText("button_modHubShowAll") or g_i18n:getText("button_modHubShowCrossplay"))
    local defaultModSetting = self.buttonToggleCrossplay
    defaultModSetting:setVisible(not Platform.isConsole and self.missionDynamicInfo.isMultiplayer)
    self.buttonToggleCrossplay.parent:invalidateLayout()
    if self.mapModName ~= nil then
        self:setItemState(g_modManager:getModByName(self.mapModName), true)
    end
    local defaultModSetting = true
    if GS_PLATFORM_PLAYSTATION and getModUseAvailability(false) ~= MultiplayerAvailability.AVAILABLE then
        defaultModSetting = false
    end
    if self.missionInfo.isValid then
        for _, modInfo in pairs(self.missionInfo.mods) do
            if modInfo.modName ~= self.mapModName then
                local modItem = g_modManager:getModByName(modInfo.modName)
                if modItem ~= nil and self:shouldShowModInList(modItem) then
                    self:setItemState(modItem, modItem.isDLC or defaultModSetting)
                end
            end
        end
    else
        for _, modInfo in ipairs(self.availableMods) do
            self:setItemState(modInfo, modInfo.isDLC or defaultModSetting)
        end
    end
    if Platform.isMobile or #self.availableMods == 0 then
        self:onClickOk()
    end
    if Platform.autoSelectDLCs then
        local hasMods = false
        for modInfo, modItem in ipairs(self.availableMods) do
            if not modItem.isDLC then
                hasMods = true
                break
            end
        end
        if not hasMods then
            self:onClickOk()
        end
    end
end
function ModSelectionScreen:onClose()
    self.availableMods = {}
    self.selectedMods = {}
    self.sectionToData = {}
    self.indexedSearch:clear()
    self.uniqueTypesInUse = {}
    self.lastFilterValue = ""
    self.overlayCache:clearCache()
    ModSelectionScreen:superClass().onClose(self)
end
function ModSelectionScreen:toggleAllAction()
    local canSelectAll, hasMods = self:getCanSelectAll()
    if hasMods then
        if canSelectAll then
            local numDlc = 0
            local numMod = 0
            for _, modItem in pairs(self.availableMods) do
                if modItem.isDLC then
                end
            end
            if numMod <= 0 or (numDlc ~= 0 or PlatformPrivilegeUtil.checkModUse(self.performSelectAll, self)) then
                self:performSelectAll()
            end
        end
        for section, data in ipairs(self.sectionToData) do
            for k, mod in ipairs(data.mods) do
                if self.selectedMods[mod] then
                    self:setItemState(mod, false)
                end
            end
        end
    end
end
function ModSelectionScreen:performSelectAll()
    local modSetting = getModUseAvailability(false) == MultiplayerAvailability.AVAILABLE
    for section, data in ipairs(self.sectionToData) do
        for k, mod in ipairs(data.mods) do
            self:setItemState(mod, mod.isDLC or modSetting)
        end
    end
end
function ModSelectionScreen:selectCurrentMod()
    local mod = self:getSelectedMod()
    if mod == nil then
        return
    elseif mod.isDLC or PlatformPrivilegeUtil.checkModUse(self.selectCurrentMod, self) then
        local newIsSelected = not self:getIsModSelected(mod)
        if newIsSelected and self.blockedMods[mod] then
            local updateableModId = self.updatableMods[mod]
            if updateableModId == nil then
                InfoDialog.show(g_i18n:getText("ui_modsCannotActivateBlockedMod"), nil, nil, DialogElement.TYPE_WARNING)
            else
                local yesText = g_i18n:getText("button_ok")
                local noText = g_i18n:getText("button_modHubUpdate")
                YesNoDialog.show(function(yes)
                    -- upvalues: (copy) self, (copy) updateableModId
                    if not yes then
                        self:installOrUpdateMods({ updateableModId })
                    end
                end, nil, g_i18n:getText("ui_modsCannotActivateBlockedModUpdate"), nil, yesText, noText, DialogElement.TYPE_WARNING)
            end
        else
            if not self:setItemState(mod, newIsSelected) then
                local callback = self.uniqueTypesInUse[mod.uniqueType]
                YesNoDialog.show(function(yes)
                    -- upvalues: (copy) self, (copy) callback, (copy) mod
                    if yes then
                        self:setItemState(callback, false)
                        self:setItemState(mod, true)
                    end
                end, nil, string.format(g_i18n:getText("ui_modConflictQuestion"), mod.title, callback.title))
            end
            return
        end
    else
        return
    end
end
function ModSelectionScreen:toggleModAction()
    self:selectCurrentMod()
end
function ModSelectionScreen:onClickBack()
    if self.lastFilterValue == nil or self.lastFilterValue == "" then
        return ModSelectionScreen:superClass().onClickBack(self)
    end
    self:filter("")
    return true
end
function ModSelectionScreen:onClickOk()
    local unresolved = self:verifyDependencies()
    if #unresolved == 0 then
        local mods = {}
        local availableUpdateModIds = {}
        local scriptModsSelected = false
        for _, modItem in pairs(self.selectedMods) do
            table.insert(mods, modItem)
            local modId = self.updatableMods[modItem]
            if modId ~= nil then
                table.addElement(availableUpdateModIds, modId)
            end
            scriptModsSelected = modItem.hasScripts
        end
        for _, modItem in pairs(self.blockedMods) do
            local modId = self.updatableMods[_]
            if modId ~= nil then
                table.insert(availableUpdateModIds, modId)
            end
        end
        local function startGame()
            -- upvalues: (copy) self, (copy) mods
            local mapMod = g_modManager:getModByName(self.mapModName)
            if mapMod == nil or not self.blockedMods[mapMod] then
                self.missionDynamicInfo.mods = mods
                local returnScreen = ModSelectionScreen
                if #self.availableMods == 0 then
                    returnScreen = nil
                end
                g_careerScreen:startGame(self.missionInfo, self.missionDynamicInfo, returnScreen)
            else
                InfoDialog.show(g_i18n:getText("ui_modMapBlocked"), nil, nil, DialogElement.TYPE_WARNING)
            end
        end
        local skipDialog = StartParams.getIsSet("autoStart") or StartParams.getIsSet("skipModUpdateDialog")
        local function showIgnoreModUpdatesDialog()
            -- upvalues: (copy) availableUpdateModIds, (copy) skipDialog, (copy) startGame, (copy) self
            if g_dedicatedServer == nil and (#availableUpdateModIds > 0 and not skipDialog) then
                local acceptText = g_i18n:getText("button_start")
                local backText = g_i18n:getText("button_back")
                local cancelText = g_i18n:getText("button_modHubUpdate")
                MultiOptionDialog.show(function(action)
                    -- upvalues: (ref) startGame, (ref) self, (ref) availableUpdateModIds
                    if action == MultiOptionDialog.ACTION.ACCEPT then
                        startGame()
                        return
                    elseif action == MultiOptionDialog.ACTION.CANCEL then
                        self:installOrUpdateMods(availableUpdateModIds)
                    end
                end, nil, g_i18n:getText("ui_mod_ignoreAvailableUpdates"), nil, acceptText, backText, nil, cancelText, DialogElement.TYPE_WARNING)
            else
                startGame()
            end
        end
        if GS_IS_MSSTORE_VERSION and (self.missionInfo.initialPlatformId == PlatformId.XBOX_SERIES and scriptModsSelected) then
            YesNoDialog.show(function(yes)
                -- upvalues: (copy) self, (copy) showIgnoreModUpdatesDialog
                if yes then
                    self.missionInfo.initialPlatformId = getPlatformId()
                    showIgnoreModUpdatesDialog()
                end
            end, nil, g_i18n:getText("ui_savegameCrossPlatformWarning"), nil, nil, nil, DialogElement.TYPE_WARNING)
        else
            showIgnoreModUpdatesDialog()
        end
    else
        if g_dedicatedServer == nil then
            local mods = {}
            local availableUpdateModIds = {}
            local scriptModsSelected = false
            local startGame = {}
            for modItem, modId in ipairs(unresolved) do
                if startGame[modId.mod.title] == nil then
                    startGame[modId.mod.title] = modId.dependencyTitle
                else
                    startGame[modId.mod.title] = startGame[modId.mod.title] .. ", " .. modId.dependencyTitle
                end
                if modId.dependencyModId == nil then
                    if modId.canActivate then
                        table.insert(mods, modId.dependencyMod)
                    else
                        scriptModsSelected = true
                    end
                else
                    table.insert(availableUpdateModIds, modId.dependencyModId)
                end
            end
            local skipDialog = nil
            for modId, deps in pairs(startGame) do
                if skipDialog == nil then
                    skipDialog = string.format(g_i18n:getText("ui_mod_required"), modId, deps)
                else
                    skipDialog = skipDialog .. " " .. string.format(g_i18n:getText("ui_mod_required"), modId, deps)
                end
            end
            if #mods > 0 then
                YesNoDialog.show(function(yes)
                    -- upvalues: (copy) mods, (copy) self
                    if yes then
                        for _, modItem in ipairs(mods) do
                            self:setItemState(modItem, true)
                        end
                    end
                end, nil, skipDialog .. "\n\n" .. g_i18n:getText("ui_mod_selectAllRequired"), nil, nil, nil, DialogElement.TYPE_QUESTION)
                return
            end
            if #availableUpdateModIds > 0 then
                YesNoDialog.show(function(yes)
                    -- upvalues: (copy) self, (copy) availableUpdateModIds
                    if yes then
                        self:installOrUpdateMods(availableUpdateModIds)
                    end
                end, nil, skipDialog .. "\n\n" .. g_i18n:getText("ui_mod_downloadAllRequired"), nil, nil, nil, DialogElement.TYPE_WARNING)
                return
            end
            if scriptModsSelected then
                InfoDialog.show(skipDialog, nil, nil, DialogElement.TYPE_WARNING)
                return
            end
        else
            local mods = {}
            for skipDialog, showIgnoreModUpdatesDialog in ipairs(unresolved) do
                if mods[showIgnoreModUpdatesDialog.mod.title] == nil then
                    mods[showIgnoreModUpdatesDialog.mod.title] = showIgnoreModUpdatesDialog.dependencyTitle
                else
                    mods[showIgnoreModUpdatesDialog.mod.title] = mods[showIgnoreModUpdatesDialog.mod.title] .. ", " .. showIgnoreModUpdatesDialog.dependencyTitle
                end
            end
            local availableUpdateModIds = nil
            for showIgnoreModUpdatesDialog, _ in pairs(mods) do
                if availableUpdateModIds == nil then
                    availableUpdateModIds = "\'" .. showIgnoreModUpdatesDialog .. "\' wants " .. _
                end
            end
            Logging.error("Could not start dedicated server with current mod setup because some dependencies are missing: " .. availableUpdateModIds)
            if g_dedicatedServer ~= nil then
                doExit()
            end
        end
        return
    end
end
function ModSelectionScreen:onDoubleClick(_)
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
    self:selectCurrentMod()
end
function ModSelectionScreen:toggleCrossplay()
    self.crossplayOnly = not self.crossplayOnly
    self:loadAvailableMods()
    for _, mod in ipairs(self.availableMods) do
        if self.selectedMods[mod] then
            self:setItemState(mod, true)
        end
    end
    self.buttonToggleCrossplay:setText(self.crossplayOnly and g_i18n:getText("button_modHubShowAll") or g_i18n:getText("button_modHubShowCrossplay"))
end
function ModSelectionScreen:update(dt)
    ModSelectionScreen:superClass().update(self, dt)
    if g_dedicatedServer == nil then
        if Profiler.IS_INITIALIZED then
            self:onClickOk()
        end
        if g_startMissionInfo.isMultiplayer then
            Platform.verifyMultiplayerAvailabilityInMenu()
        end
    else
        for _, modItem in pairs(self.selectedMods) do
            self:setItemState(modItem, false)
        end
        for _, modItem in pairs(g_dedicatedServer.mods) do
            local modItem = g_modManager:getModByName(modItem)
            if modItem ~= nil then
                if self:shouldShowModInList(modItem) then
                    self:setItemState(modItem, true)
                else
                    Logging.error("Mod \'%s\' is not available for current dedicated server setup", modItem.title)
                end
            end
        end
        self:onClickOk()
    end
end
function ModSelectionScreen:shouldShowModInList(mod)
    local showMod = (self.missionDynamicInfo.isMultiplayer and true or false) and mod.isMultiplayerSupported
    if showMod then
        showMod = mod.fileHash ~= nil
    end
    if showMod and (not self.missionDynamicInfo.isMultiplayer and mod.multiplayerOnly) then
        showMod = false
    end
    if not mod.isSelectable then
        showMod = false
    end
    if showMod and (not mod.isDLC and mod.modName ~= self.mapModName) then
        for mapId, _ in pairs(g_mapManager.idToMap) do
            local modName = g_mapManager:getModNameFromMapId(mapId)
            if modName ~= nil and modName == mod.modName then
                showMod = false
                break
            end
        end
    end
    if not mod.isDLC and (self.crossplayOnly and (self.missionDynamicInfo.isMultiplayer and showMod)) then
        if mod.hasScripts and not mod.isInternalScriptMod then
            return false
        end
        local modId = getModIdByFilename(mod.modName)
        if modId == 0 or getModMetaAttributeString(modId, "hash") ~= mod.fileHash then
            showMod = false
        end
    end
    return showMod
end
function ModSelectionScreen:isModActivated(name)
    for _, activeMod in pairs(self.selectedMods) do
        if activeMod.modName == name then
            return true
        end
    end
    return false
end
function ModSelectionScreen:verifyDependencies()
    local unresolved = {}
    for _, modItem in pairs(self.selectedMods) do
        if modItem.dependencies ~= nil and #modItem.dependencies > 0 then
            for _, depName in ipairs(modItem.dependencies) do
                if not self:isModActivated(depName) then
                    local depMod = g_modManager:getModByName(depName)
                    if depMod == nil then
                        local modId = getModIdByFilename(depName)
                        if modId == 0 then
                            table.insert(unresolved, {
                                ["mod"] = modItem,
                                ["dependencyTitle"] = "\'" .. depName .. ".zip\'"
                            })
                        else
                            table.insert(unresolved, {
                                ["mod"] = modItem,
                                ["dependencyTitle"] = "\'" .. g_modHubController:getModInfo(modId):getName() .. "\'",
                                ["dependencyModId"] = modId
                            })
                        end
                    else
                        table.insert(unresolved, {
                            ["mod"] = modItem,
                            ["dependencyTitle"] = "\'" .. depMod.title .. "\'",
                            ["dependencyMod"] = depMod,
                            ["canActivate"] = true
                        })
                    end
                end
            end
        end
    end
    return unresolved
end
function ModSelectionScreen:loadAvailableMods()
    self.indexedSearch:clear()
    self.availableMods = {}
    self.blockedMods = {}
    self.updatableMods = {}
    self.numUpdatableMods = 0
    self.selectedMods = {}
    local isModDownloadManagerLoaded = modDownloadManagerLoaded()
    local outdatedMods
    if isModDownloadManagerLoaded then
        local i = 0
        local mods = getNumOfBlockedMods() - 1
        for i = i, mods do
            local filename, versionStr, minModDesc, maxModDesc = getBlockedMod(i)
            if not MathUtil.getIsOutOfBounds(g_maxModDescVersion, minModDesc, maxModDesc) then
                local versionParts = string.split(versionStr, ".")
                for i, part in ipairs(versionParts) do
                    versionParts[i] = tonumber(string.match(part, "%d+")) or 0
                end
                ({})[filename] = versionParts
            end
        end
        self.showBlockedError = false
    else
        outdatedMods = g_outdatedMods
    end
    local mods = g_modManager:getMods()
    for versionStr, minModDesc in ipairs(mods) do
        if self:shouldShowModInList(minModDesc) then
            local maxModDesc = outdatedMods[minModDesc.modName]
            if maxModDesc ~= nil then
                local versionParts = string.split(minModDesc.version, ".")
                for i, part in ipairs(versionParts) do
                    versionParts[i] = tonumber(string.match(part, "%d+")) or 0
                end
                if Utils.compareVersions(versionParts, maxModDesc) < 1 then
                    self.blockedMods[minModDesc] = true
                    if self.showBlockedError then
                        printError("Error: Mod \'" .. minModDesc.modName .. "\' in version \'" .. minModDesc.version .. "\' and lower is outdated and not working properly. Please update the mod to resolve this!")
                    end
                end
            end
            if isModDownloadManagerLoaded then
                local versionParts = getModIdByFilename(minModDesc.modName)
                if versionParts ~= 0 then
                    local modInfo = g_modHubController:getModInfo(versionParts)
                    local isUpdate = modInfo:getIsUpdate()
                    local isExternal = modInfo:getIsExternal()
                    if modInfo ~= nil and (isUpdate and (not isExternal and (not minModDesc.isDirectory and (Platform.isPC or not modInfo:getIsDLC())))) then
                        self.updatableMods[minModDesc] = versionParts
                        self.numUpdatableMods = self.numUpdatableMods + 1
                    end
                end
            end
            local modInfo = self.availableMods
            table.insert(modInfo, minModDesc)
            self.indexedSearch:addDocument({
                ["title"] = minModDesc.title,
                ["modName"] = string.gsub(minModDesc.modName, "FS25_", ""),
                ["author"] = minModDesc.author
            }, minModDesc)
        end
    end
    self.indexedSearch:build()
    self.numAddedModsBesidesMap = 0
    self.numAddedMods = 0
    self:showMods(nil)
    for versionStr, minModDesc in ipairs(self.availableMods) do
        self:setItemState(minModDesc, false)
    end
end
function ModSelectionScreen:filter(name)
    name = string.isNilOrWhitespace(name) and "" or name
    if self.lastFilterValue ~= name then
        local isSearching = true
        if self.indexedSearch:search(name, function(results)
            -- upvalues: (ref) isSearching, (copy) self
            MessageDialog.hide()
            isSearching = false
            local mods = nil
            if results ~= nil then
                for _, data in ipairs(results) do
                    ({})[data.ref] = data.score
                end
            end
            self:showMods(mods)
        end) then
            if isSearching then
                MessageDialog.show(g_i18n:getText("ui_storeSearching"))
            end
        else
            self:showMods(nil)
        end
        self.lastFilterValue = name
        local title = self.defaultTitle
        if self.lastFilterValue ~= "" then
            title = string.format("%s (\'%s\')", title, self.lastFilterValue)
        end
        self.title:setText(title)
    end
end
function ModSelectionScreen:showMods(mods)
    local updateables = {}
    local blocked = {}
    local others = {}
    local numMods = 0
    table.clear(self.sectionToData)
    for _, mod in ipairs(self.availableMods) do
        if mods == nil or mods[mod] then
            if self.updatableMods[mod] then
                table.insert(updateables, mod)
            elseif self.blockedMods[mod] then
                table.insert(blocked, mod)
            else
                table.insert(others, mod)
            end
        end
    end
    local function sortMods(a, b)
        -- upvalues: (copy) mods, (copy) self
        local isDlcA = a.isDLC or a.isFreeDLC
        local isDlcB = b.isDLC or b.isFreeDLC
        if mods ~= nil then
            local scoreA = mods[a]
            local scoreB = mods[b]
            if scoreA and scoreB then
                if scoreB < scoreA then
                    return true
                end
                if scoreA < scoreB then
                    return false
                end
            end
        end
        if isDlcA and not isDlcB then
            return true
        end
        if not isDlcA and isDlcB then
            return false
        end
        local scoreA = self.blockedMods[a]
        local scoreB = self.blockedMods[b]
        if not scoreA and scoreB then
            return true
        end
        if scoreA and not scoreB then
            return false
        end
        if a.author == ModSelectionScreen.AUTHOR_NAME_GIANTS and b.author ~= ModSelectionScreen.AUTHOR_NAME_GIANTS then
            return true
        end
        if b.author == ModSelectionScreen.AUTHOR_NAME_GIANTS and a.author ~= ModSelectionScreen.AUTHOR_NAME_GIANTS then
            return false
        end
        return a.title < b.title
    end
    table.sort(updateables, sortMods)
    table.sort(blocked, sortMods)
    table.sort(others, sortMods)
    if #updateables > 0 then
        local mod = {
            ["title"] = g_i18n:getText("ui_modsUpdatesAvailable"),
            ["mods"] = updateables
        }
        table.insert(self.sectionToData, mod)
    end
    if #blocked > 0 then
        local mod = {
            ["title"] = g_i18n:getText("ui_modsBlocked"),
            ["mods"] = blocked
        }
        table.insert(self.sectionToData, mod)
    end
    local _ = self.sectionToData
    local mod = {
        ["title"] = g_i18n:getText("ui_modsInstalled"),
        ["mods"] = others
    }
    table.insert(_, mod)
    self.modList:reloadData()
    local mod = numMods == 0
    self.buttonSelect:setDisabled(mod)
    local mod = numMods == 0
    self.buttonSelectAll:setDisabled(mod)
    local mod = numMods == 0
    self.noModsDLCsElement:setVisible(mod)
end
function ModSelectionScreen:setItemState(item, isSelected)
    if item ~= nil then
        if isSelected and self.blockedMods[item] then
            return false
        end
        if item.uniqueType ~= nil then
            if self.uniqueTypesInUse[item.uniqueType] == nil then
                if isSelected then
                    self.uniqueTypesInUse[item.uniqueType] = item
                end
            else
                if isSelected then
                    return false
                end
                self.uniqueTypesInUse[item.uniqueType] = nil
            end
        end
        local isNotUsedMap = true
        if self.mapModName ~= nil then
            isNotUsedMap = item.modName ~= self.mapModName
        end
        if isSelected then
            if self.selectedMods[item] == nil then
                if isNotUsedMap then
                    self.numAddedModsBesidesMap = self.numAddedModsBesidesMap + 1
                end
                self.numAddedMods = self.numAddedMods + 1
            end
            self.selectedMods[item] = item
        elseif isNotUsedMap then
            if self.selectedMods[item] ~= nil then
                self.numAddedModsBesidesMap = self.numAddedModsBesidesMap - 1
                self.numAddedMods = self.numAddedMods - 1
            end
            self.selectedMods[item] = nil
        end
        if not isNotUsedMap then
            if self.blockedMods[item] then
                return false
            end
            isSelected = true
        end
        if item.isDLC and Platform.autoSelectDLCs then
            if self.blockedMods[item] then
                return false
            end
            isSelected = true
        end
        local section, index = self:getSectionAndIndexForItem(item)
        if index ~= nil then
            local cell = self.modList:getElementAtSectionIndex(section, index)
            if cell ~= nil and not cell.isEmptyCell then
                if isSelected then
                    cell:getAttribute("bg"):applyProfile(ModSelectionScreen.BG_PROFILE_SELECTED)
                    cell:getAttribute("title"):setTextColor(unpack(ModSelectionScreen.COLOR_MAIN_DARK))
                    cell:getAttribute("version"):setTextColor(unpack(ModSelectionScreen.COLOR_MAIN_DARK))
                else
                    cell:getAttribute("bg"):applyProfile(ModSelectionScreen.BG_PROFILE)
                    cell:getAttribute("title"):setTextColor(unpack(ModSelectionScreen.COLOR_MAIN_LIGHT))
                    cell:getAttribute("version"):setTextColor(unpack(ModSelectionScreen.COLOR_MAIN_LIGHT))
                end
            end
        end
        self.numSelectedModsText:setText(self.numAddedMods .. " / " .. #self.availableMods)
        if self.numSelectedModsBox ~= nil then
            self.numSelectedModsBox:invalidateLayout()
            self.numSelectedModsBoxBg:setSize(self.numSelectedModsBox.flowSizes[1] + 65 * g_pixelSizeScaledX)
        end
    end
    self:updateSelectButton()
    return true
end
function ModSelectionScreen:getSectionAndIndexForItem(item)
    for section, data in ipairs(self.sectionToData) do
        for k, mod in ipairs(data.mods) do
            if mod == item then
                return section, k
            end
        end
    end
    return nil, nil
end
function ModSelectionScreen:getIsModSelected(item)
    return self.selectedMods[item] ~= nil
end
function ModSelectionScreen:getSelectedMod()
    local sections = self.sectionToData[self.modList.selectedSectionIndex]
    if sections == nil then
        return nil
    end
    return sections.mods[self.modList.selectedIndex]
end
function ModSelectionScreen:updateSelectButton()
    if self.selectedMods[self:getSelectedMod()] == nil then
        self.buttonSelect:setText(g_i18n:getText("button_select"))
    else
        self.buttonSelect:setText(g_i18n:getText("button_deselect"))
    end
    local canSelectAll, hasMods = self:getCanSelectAll()
    if hasMods then
        if canSelectAll then
            self.buttonSelectAll:setText(g_i18n:getText("button_selectAll"))
            return
        end
        self.buttonSelectAll:setText(g_i18n:getText("button_deselectAll"))
    end
end
function ModSelectionScreen:getCanSelectAll()
    local canSelectAll = false
    local hasMods = false
    for section, data in ipairs(self.sectionToData) do
        for k, mod in ipairs(data.mods) do
            if self.blockedMods[mod] == nil then
                hasMods = true
                if self.selectedMods[mod] == nil then
                    canSelectAll = true
                    break
                end
            end
        end
    end
    return canSelectAll, hasMods
end
function ModSelectionScreen:getNumberOfSections(_)
    return #self.sectionToData
end
function ModSelectionScreen:getTitleForSectionHeader(_, section)
    return self.sectionToData[section].title
end
function ModSelectionScreen:getNumberOfItemsInSection(_, section)
    return #self.sectionToData[section].mods
end
function ModSelectionScreen:populateCellForItemInSection(_, section, index, cell)
    local mod = self.sectionToData[section].mods[index]
    local isBlocked = self.blockedMods[mod]
    if self.selectedMods[mod] then
        cell:getAttribute("bg"):applyProfile(ModSelectionScreen.BG_PROFILE_SELECTED)
        local markerElement = cell:getAttribute("title")
        markerElement:setTextColor(unpack(ModSelectionScreen.COLOR_MAIN_DARK))
        local markerElement = cell:getAttribute("version")
        markerElement:setTextColor(unpack(ModSelectionScreen.COLOR_MAIN_DARK))
    else
        cell:getAttribute("bg"):applyProfile(ModSelectionScreen.BG_PROFILE)
        local markerElement = cell:getAttribute("title")
        markerElement:setTextColor(unpack(ModSelectionScreen.COLOR_MAIN_LIGHT))
        local markerElement = cell:getAttribute("version")
        markerElement:setTextColor(unpack(ModSelectionScreen.COLOR_MAIN_LIGHT))
    end
    local markerElement = cell:getAttribute("markerBox")
    if markerElement ~= nil then
        local markerUpdate = markerElement:getDescendantByName("markerUpdate")
        if markerUpdate ~= nil then
            markerUpdate:setVisible(self.updatableMods[mod])
        end
        local markerBlocked = markerElement:getDescendantByName("markerBlocked")
        if markerBlocked ~= nil then
            markerBlocked:setVisible(isBlocked)
        end
        cell:getAttribute("markerBox"):invalidateLayout()
    end
    if isBlocked then
        cell:getAttribute("title"):setTextColor(0.1, 0.1, 0.1, 1)
        cell:getAttribute("version"):setTextColor(0.1, 0.1, 0.1, 1)
        cell:getAttribute("icon"):setImageColor(nil, 0.2, 0.2, 0.2, 1)
    else
        cell:getAttribute("icon"):setImageColor(1, 1, 1, 1)
    end
    cell:getAttribute("title"):setText(mod.title)
    cell:getAttribute("version"):setText(g_i18n:getText("ui_modVersion") .. " " .. mod.version)
    cell:getAttribute("dlcTag"):setVisible(mod.isDLC or mod.isFreeDLC)
    cell:getAttribute("icon"):setImageFilename(mod.iconFilename)
    self.overlayCache:addOverlay(mod.iconFilename)
end
function ModSelectionScreen:onListSelectionChanged(_, _, _)
    self:updateSelectButton()
end
function ModSelectionScreen:onSearch()
    local dialogPrompt = g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH)
    local imePrompt = g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH)
    local confirmText = g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH)
    TextInputDialog.show(self.onSearchFinished, self, self.lastFilterValue, dialogPrompt, imePrompt, 40, confirmText, nil, nil, false)
end
function ModSelectionScreen:onSearchFinished(text, ok)
    if ok then
        self:filter(text)
    else
        self:filter("")
    end
end
function ModSelectionScreen.installOrUpdateMods(_, modIds)
    g_modHubController:installOrUpdateMods(modIds, function(numFailed)
        g_masterServerConnection:disconnectFromMasterServer()
        g_connectionManager:shutdownAll()
        g_modHubScreen:openDownloads()
        if numFailed > 0 then
            InfoDialog.show(g_i18n:getText("modHub_installFailed"))
        end
    end)
end