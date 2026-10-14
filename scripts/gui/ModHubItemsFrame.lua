ModHubItemsFrame = {}
local ShopItemsFrame_mt = Class(ModHubItemsFrame, TabbedMenuFrameElement)
local function NO_CALLBACK() end
function ModHubItemsFrame.register()
    local modHubItemsFrame = ModHubItemsFrame.new()
    g_gui:loadGui("dataS/gui/ModHubItemsFrame.xml", "ModHubItemsFrame", modHubItemsFrame, true)
end
function ModHubItemsFrame.new(target, custom_mt)
    -- upvalues: (copy) ShopItemsFrame_mt, (copy) NO_CALLBACK
    local self = TabbedMenuFrameElement.new(target, custom_mt or ShopItemsFrame_mt)
    self.categoryName = ""
    self.updateModInterval = 1000
    self.updateModTimer = self.updateModInterval
    self.notifyActivatedModItemCallback = NO_CALLBACK
    self.notifySelectedModItemCallback = NO_CALLBACK
    self.notifySearchCallback = NO_CALLBACK
    self.notifyToggleBetaCallback = NO_CALLBACK
    self.setModItems = nil
    self.mods = {}
    return self
end
function ModHubItemsFrame.createFromExistingGui(gui, guiName)
    local newGui = ModHubItemsFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function ModHubItemsFrame:initialize(headerIconSliceId)
    self.backButtonInfo = {
        ["inputAction"] = InputAction.MENU_BACK
    }
    self.nextPageButtonInfo = {
        ["inputAction"] = InputAction.MENU_PAGE_NEXT,
        ["text"] = g_i18n:getText("ui_ingameMenuNext"),
        ["callback"] = self.onPageNext
    }
    self.prevPageButtonInfo = {
        ["inputAction"] = InputAction.MENU_PAGE_PREV,
        ["text"] = g_i18n:getText("ui_ingameMenuPrev"),
        ["callback"] = self.onPagePrevious
    }
    self.detailsButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACCEPT,
        ["text"] = g_i18n:getText(ModHubItemsFrame.L10N_SYMBOL.BUTTON_DETAILS),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonDetails()
        end
    }
    self.searchButtonInfo = {
        ["inputAction"] = InputAction.MENU_EXTRA_2,
        ["text"] = g_i18n:getText("button_search"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonSearch()
        end
    }
    self.updateAllButtonInfo = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = g_i18n:getText(ModHubItemsFrame.L10N_SYMBOL.BUTTON_UPDATE_ALL),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonUpdateAll()
        end
    }
    self.toggleTopButtonInfo = {
        ["inputAction"] = InputAction.MENU_EXTRA_1,
        ["text"] = "",
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonShowToggle()
        end
    }
    self.deleteAllButtonInfo = {
        ["inputAction"] = InputAction.MENU_EXTRA_1,
        ["text"] = "Delete All Mods",
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonDeleteAllMods()
        end
    }
    if headerIconSliceId ~= nil then
        self.headerIcon:setImageSlice(nil, headerIconSliceId)
    end
    if g_i18n:hasText("modHub_authorDisclaimer") then
        self.disclaimerLabel:setText(g_i18n:getText("modHub_abuse") .. " " .. g_i18n:getText("modHub_authorDisclaimer"))
    end
end
function ModHubItemsFrame:onFrameOpen()
    ModHubItemsFrame:superClass().onFrameOpen(self)
    if self.categoryId ~= nil then
        g_modHubController:loadCategory(self.categoryId)
    end
    self:updateList()
    self:setSoundSuppressed(true)
    FocusManager:setFocus(self.itemsList)
    self:setSoundSuppressed(false)
    g_modHubController:setAddedToDownloadCallback(self.setMenuButtonInfoDirty, self)
end
function ModHubItemsFrame:getMenuButtonInfo()
    -- upvalues: (copy) NO_CALLBACK
    local buttons = {}
    if #self.mods > 0 then
        table.insert(buttons, self.detailsButtonInfo)
    end
    table.insert(buttons, self.backButtonInfo)
    table.insert(buttons, self.nextPageButtonInfo)
    table.insert(buttons, self.prevPageButtonInfo)
    if self.categoryName == "update" then
        for _, modInfo in pairs(self.mods) do
            if not modInfo:getIsExternal() and (Platform.isPC or not modInfo:getIsDLC()) then
                table.insert(buttons, self.updateAllButtonInfo)
                break
            end
        end
    end
    if self.notifySearchCallback ~= NO_CALLBACK then
        table.insert(buttons, self.searchButtonInfo)
    end
    if Platform.allowsScriptMods and (self.notifyToggleBetaCallback ~= NO_CALLBACK and (self.forcedModItems == nil and self.categoryName ~= "testing")) then
        self.toggleTopButtonInfo.text = self.getBetaToggleText()
        table.insert(buttons, self.toggleTopButtonInfo)
    end
    if self.categoryName == "testing" then
        table.insert(buttons, self.deleteAllButtonInfo)
    end
    return buttons
end
function ModHubItemsFrame:setItemClickCallback(itemClickedCallback)
    -- upvalues: (copy) NO_CALLBACK
    self.notifyActivatedModItemCallback = itemClickedCallback or NO_CALLBACK
end
function ModHubItemsFrame:setItemSelectCallback(itemSelectedCallback)
    -- upvalues: (copy) NO_CALLBACK
    self.notifySelectedModItemCallback = itemSelectedCallback or NO_CALLBACK
end
function ModHubItemsFrame:setSearchCallback(searchCallback)
    self.notifySearchCallback = searchCallback
end
function ModHubItemsFrame:setToggleBetaCallback(callback)
    self.notifyToggleBetaCallback = callback
end
function ModHubItemsFrame:setBetaToggleTextCallback(callback)
    self.getBetaToggleText = callback
end
function ModHubItemsFrame:setCategory(categoryName)
    self.categoryName = categoryName
    self.headerText:setText(g_modHubController:getCategory(categoryName).label)
end
function ModHubItemsFrame:setCategoryId(categoryId)
    self.categoryId = categoryId
end
function ModHubItemsFrame:setModItems(modItems)
    self.forcedModItems = modItems
end
function ModHubItemsFrame:setListSizeLimit(limit)
    self.listSizeLimit = limit
end
function ModHubItemsFrame:reload()
    self:updateList()
end
function ModHubItemsFrame:updateList()
    if self.forcedModItems == nil then
        self.mods = g_modHubController:getModsByCategory(self.categoryId, true)
    else
        self.mods = self.forcedModItems
    end
    self.itemsList:reloadData()
    self.modAttributeBox:setVisible(#self.mods > 0)
    self.noModsElement:setVisible(#self.mods == 0)
    self:setMenuButtonInfoDirty()
end
function ModHubItemsFrame:getMainElementSize()
    return self.modAttributeBox.size
end
function ModHubItemsFrame:getMainElementPosition()
    return self.modAttributeBox.absPosition
end
function ModHubItemsFrame:onActivateItem(_, _)
    self.notifyActivatedModItemCallback(self, self.mods[self.itemsList.selectedIndex].modId, self.categoryName)
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
end
function ModHubItemsFrame:onButtonDetails()
    self:onActivateItem()
end
function ModHubItemsFrame:onClickLeft()
    self.itemsList:scrollTo(self.itemsList.firstVisibleItem - self.itemsList.itemsPerCol)
end
function ModHubItemsFrame:onClickRight()
    self.itemsList:scrollTo(self.itemsList.firstVisibleItem + self.itemsList.itemsPerCol)
end
function ModHubItemsFrame:onListSelectionChanged(_, _, index)
    local modItem = self.mods[index]
    if modItem ~= nil then
        self.notifySelectedModItemCallback(self, modItem.modId)
    end
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
end
function ModHubItemsFrame:setModInfo(modInfo)
    if self.modAttributeName ~= nil then
        self.modAttributeName:setText(modInfo:getName(), true)
        self.modAttributeInfoAuthor:setText(modInfo:getAuthor(), true)
        local isInstalled = modInfo:getIsInstalled()
        local versionString = modInfo:getVersionString()
        if isInstalled then
            local mod = g_modManager:getModByTitle(modInfo:getName())
            if mod ~= nil and versionString ~= mod.version then
                versionString = versionString .. " (" .. g_i18n:getText("ui_modsInstalled") .. ": " .. mod.version .. ")"
            end
        end
        self.modAttributeInfoVersion:setText(versionString, true)
        local mod = modInfo:getIsDLC()
        local isTop = modInfo:getIsTop()
        if mod then
            local size = modInfo:getPriceString()
            self.modAttributePrice:setText(size, true)
            isTop = size:len() > 1
        else
            local size = modInfo:getFilesize() / 1024 / 1024
            self.modAttributeInfoSize:setText(string.format("%.02f MB", size), true)
            local ratingScore = modInfo:getRatingScore() / 100
            local i = 1
            for i = i, 5 do
                self.modAttributeRatingStar[i].elements[1]:setVisible(i - 0.75 <= ratingScore and ratingScore < i - 0.25)
                if i - 0.25 <= ratingScore then
                    self.modAttributeRatingStar[i]:applyProfile(ModHubItemsFrame.PROFILE.RATING_STAR_ACTIVE)
                else
                    self.modAttributeRatingStar[i]:applyProfile(ModHubItemsFrame.PROFILE.RATING_STAR)
                end
            end
            self.modAttributePrice:setText(g_i18n:getText("modHub_flag_crossplay"), true)
        end
        self.modAttributeInfoSize:setVisible(not mod)
        self.modAttributeInfoSizeSpace:setVisible(not mod)
        self.modAttributeRatingBox:setVisible(not mod)
        self.modAttributeInfoRatingSpace:setVisible(not mod)
        self.modAttributePrice:setVisible(isTop)
        self.modAttributeInfoPriceSpace:setVisible(isTop)
        self.modAttributeBox:invalidateLayout()
    end
end
function ModHubItemsFrame:onButtonSearch()
    self.notifySearchCallback(self.categoryId)
end
function ModHubItemsFrame:onButtonUpdateAll()
    YesNoDialog.show(self.onYesNoUpdateAll, self, g_i18n:getText("modHub_updateAllDialog"), g_i18n:getText("modHub_updateAll"))
end
function ModHubItemsFrame:onYesNoUpdateAll(yes)
    if yes then
        for _, modInfo in pairs(self.mods) do
            if not modInfo:getIsExternal() and (Platform.isPC or not modInfo:getIsDLC()) then
                g_modHubController:update(modInfo:getId())
            end
        end
    end
end
function ModHubItemsFrame:onButtonShowToggle()
    self.notifyToggleBetaCallback(self)
end
function ModHubItemsFrame:onButtonDeleteAllMods()
    YesNoDialog.show(self.onYesNoDeleteAllMods, self, "Are you sure you want to delete all mods? this will delete any mod installed on this device", "Delete all mods", nil, nil, DialogElement.TYPE_WARNING)
end
function ModHubItemsFrame:onYesNoDeleteAllMods(yes)
    if yes then
        local mods = g_modHubController:getModsByCategory(g_modHubController:getCategory("installed").id)
        local function dummy() end
        g_modHubController:setUninstallFailedCallback(dummy, nil)
        g_modHubController:setUninstalledCallback(dummy, nil)
        for _, mod in pairs(mods) do
            g_modHubController:uninstall(mod.modId)
        end
        self:reload()
    end
end
function ModHubItemsFrame:getNumberOfItemsInSection(_, _)
    local total = #self.mods
    if self.listSizeLimit == nil then
        return total
    end
    return math.min(total, self.listSizeLimit)
end
function ModHubItemsFrame:populateCellForItemInSection(_, _, index, cell)
    local modInfo = self.mods[index]
    local numUpdates = modInfo:getNumUpdates()
    local numNew = modInfo:getNumNew()
    local numConflicts = modInfo:getNumConflicts()
    local markerElement = cell:getAttribute("markerNew")
    markerElement:setVisible(numUpdates > 0 or (numNew > 0 or numConflicts > 0))
    if numConflicts > 0 then
        markerElement:applyProfile("fs25_modHubMarkerConflict")
    elseif numUpdates > 0 then
        markerElement:applyProfile("fs25_modHubMarkerUpdate")
    elseif numNew > 0 then
        markerElement:applyProfile("fs25_modHubMarkerNew")
    end
    cell:getAttribute("markerBox"):invalidateLayout()
    local iconElement = cell:getAttribute("icon")
    iconElement:setIsWebOverlay(not modInfo:getIsIconLocal())
    iconElement:setImageFilename(modInfo:getIconFilename())
    cell:getAttribute("nameLabel"):setText(modInfo:getName())
    cell:getAttribute("dlcTag"):setVisible(modInfo:getIsDLC())
    cell:getAttribute("installedIcon"):setVisible(modInfo:getIsInstalled())
end
ModHubItemsFrame.PROFILE = {
    ["LIST_ITEM_NEUTRAL"] = "modHubItemsListItem",
    ["LIST_ITEM_SELECTED"] = "modHubItemsListItemSelected",
    ["RATING_STAR_ACTIVE"] = "fs25_modHubAttributeRatingStarActive",
    ["RATING_STAR"] = "fs25_modHubAttributeRatingStar"
}
ModHubItemsFrame.L10N_SYMBOL = {
    ["STATUS_PENDING"] = "modHub_pending",
    ["STATUS_UPDATE"] = "modHub_update",
    ["STATUS_INSTALLED"] = "modHub_installed",
    ["STATUS_FAILED"] = "modHub_failed",
    ["BUTTON_DETAILS"] = "button_detail",
    ["BUTTON_UPDATE_ALL"] = "modHub_updateAll",
    ["BUTTON_SHOW_ALL"] = "button_modHubShowAll",
    ["BUTTON_SHOW_TOP"] = "button_modHubShowTop"
}