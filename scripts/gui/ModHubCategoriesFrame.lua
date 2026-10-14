ModHubCategoriesFrame = {}
local ModHubCategoriesFrame_mt = Class(ModHubCategoriesFrame, TabbedMenuFrameElement)
local function NO_CALLBACK() end
ModHubCategoriesFrame.SUB_CATEGORY = {
    ["CATEGORIES"] = 1,
    ["BEST"] = 2,
    ["MOST_DOWNLOADED"] = 3,
    ["LATEST"] = 4,
    ["RECOMMENDED"] = 5
}
function ModHubCategoriesFrame.register()
    local modHubCategoriesFrame = ModHubCategoriesFrame.new()
    g_gui:loadGui("dataS/gui/ModHubCategoriesFrame.xml", "ModHubCategoriesFrame", modHubCategoriesFrame, true)
end
function ModHubCategoriesFrame.new(target, custom_mt)
    -- upvalues: (copy) ModHubCategoriesFrame_mt, (copy) NO_CALLBACK
    local self = TabbedMenuFrameElement.new(target, custom_mt or ModHubCategoriesFrame_mt)
    self.notifyActivatedCategoryCallback = NO_CALLBACK
    self.notifySearchCallback = NO_CALLBACK
    self.notifyToggleBetaCallback = NO_CALLBACK
    self.categories = {}
    self.categoryTypes = {}
    self.categoryName = ""
    self.notifyActivatedModItemCallback = NO_CALLBACK
    self.notifySelectedModItemCallback = NO_CALLBACK
    self.notifySearchCallback = NO_CALLBACK
    self.notifyToggleBetaCallback = NO_CALLBACK
    self.setModItems = nil
    self.mods = {}
    return self
end
function ModHubCategoriesFrame.createFromExistingGui(gui, guiName)
    local newGui = ModHubCategoriesFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function ModHubCategoriesFrame:initialize(categories, categoryClickedCallback, _, iconHeightWidthRatio)
    -- upvalues: (copy) NO_CALLBACK
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
        ["text"] = g_i18n:getText(ModHubCategoriesFrame.L10N_SYMBOL.BUTTON_DETAILS),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonDetails()
        end
    }
    self.detailsButtonDisabledInfo = {
        ["inputAction"] = InputAction.MENU_ACCEPT,
        ["text"] = g_i18n:getText(ModHubCategoriesFrame.L10N_SYMBOL.BUTTON_DETAILS),
        ["callback"] = nil,
        ["disabled"] = true
    }
    self.searchButtonInfo = {
        ["inputAction"] = InputAction.MENU_EXTRA_2,
        ["text"] = g_i18n:getText("button_search"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonSearch()
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
    self.iconHeightWidthRatio = iconHeightWidthRatio
    self.notifyActivatedCategoryCallback = categoryClickedCallback or NO_CALLBACK
    self:setCategories(categories)
    for index, button in pairs(self.subCategoryTabs) do
        local index
        button:getDescendantByName("background").getIsSelected = function()
            -- upvalues: (copy) index, (copy) self
            return index == self.subCategoryPaging:getState()
        end
        function button.getIsSelected()
            -- upvalues: (copy) index, (copy) self
            return index == self.subCategoryPaging:getState()
        end
    end
    if g_i18n:hasText("modHub_authorDisclaimer") then
        self.disclaimerLabel:setText(g_i18n:getText("modHub_abuse") .. " " .. g_i18n:getText("modHub_authorDisclaimer"))
    end
    self:updateSubCategoryPages(1)
end
function ModHubCategoriesFrame:setCategories(categories)
    self.categories = categories
    self.categoryTypes = g_modHubController:getCategoryTypes()
    self.categoryList:reloadData()
    self:setMenuButtonInfoDirty()
end
function ModHubCategoriesFrame:onFrameOpen()
    ModHubCategoriesFrame:superClass().onFrameOpen(self)
    self.isOpening = true
    self:updateSubCategoryPages(self.subCategoryPaging:getState())
    self.isOpening = false
    self:setMenuButtonInfoDirty()
    self.subCategoryBox:invalidateLayout()
    self.subCategoryPaging:setTexts(ModHubCategoriesFrame.HEADER_TITLES)
    self.subCategoryPaging:setSize(self.subCategoryBox.maxFlowSize + 140 * g_pixelSizeScaledX)
end
function ModHubCategoriesFrame:updateList()
    if self.forcedModItems == nil then
        self.mods = g_modHubController:getModsByCategory(self.categoryId, true)
    else
        self.mods = self.forcedModItems
    end
    self.itemList:reloadData(true)
    self.modAttributeBox:setVisible(self.subCategoryPaging:getState() ~= ModHubCategoriesFrame.SUB_CATEGORY.CATEGORIES and self.itemList:getItemCount() > 0)
    self:setMenuButtonInfoDirty()
end
function ModHubCategoriesFrame:reload()
    if self.subCategoryPaging:getState() ~= ModHubCategoriesFrame.SUB_CATEGORY.CATEGORIES then
        self:updateList()
    end
end
function ModHubCategoriesFrame:reset()
    self:onClickCategories()
    self.categoryList:setSelectedItem(1, 1, nil, true)
    self.categoryList:makeCellVisible(1, 1)
end
function ModHubCategoriesFrame:getMainElementSize()
    return self.categoryList.size
end
function ModHubCategoriesFrame:getMainElementPosition()
    return self.categoryList.absPosition
end
function ModHubCategoriesFrame:getMenuButtonInfo()
    -- upvalues: (copy) NO_CALLBACK
    local buttons = {}
    if #self.categories > 0 then
        if self.subCategoryPaging:getState() == ModHubCategoriesFrame.SUB_CATEGORY.CATEGORIES or self.itemList:getItemCount() ~= 0 then
            table.insert(buttons, self.detailsButtonInfo)
        else
            table.insert(buttons, self.detailsButtonDisabledInfo)
        end
    end
    table.insert(buttons, self.backButtonInfo)
    table.insert(buttons, self.nextPageButtonInfo)
    table.insert(buttons, self.prevPageButtonInfo)
    if self.subCategoryPaging:getState() == ModHubCategoriesFrame.SUB_CATEGORY.CATEGORIES or self.notifySearchCallback ~= NO_CALLBACK then
        table.insert(buttons, self.searchButtonInfo)
    end
    if Platform.allowsScriptMods then
        self.toggleTopButtonInfo.text = self.getBetaToggleText()
        table.insert(buttons, self.toggleTopButtonInfo)
    end
    return buttons
end
function ModHubCategoriesFrame:setItemClickCallback(itemClickedCallback)
    -- upvalues: (copy) NO_CALLBACK
    self.notifyActivatedModItemCallback = itemClickedCallback or NO_CALLBACK
end
function ModHubCategoriesFrame:setItemSelectCallback(itemSelectedCallback)
    -- upvalues: (copy) NO_CALLBACK
    self.notifySelectedModItemCallback = itemSelectedCallback or NO_CALLBACK
end
function ModHubCategoriesFrame:setSearchCallback(searchCallback)
    self.notifySearchCallback = searchCallback
end
function ModHubCategoriesFrame:setToggleBetaCallback(callback)
    self.notifyToggleBetaCallback = callback
end
function ModHubCategoriesFrame:setBetaToggleTextCallback(callback)
    self.getBetaToggleText = callback
end
function ModHubCategoriesFrame:setCategory(categoryName)
    self.categoryName = categoryName
end
function ModHubCategoriesFrame:setCategoryId(categoryId)
    self.categoryId = categoryId
end
function ModHubCategoriesFrame:setModItems(modItems)
    self.forcedModItems = modItems
end
function ModHubCategoriesFrame:updateListSizeLimit(_)
    local state = self.subCategoryPaging:getState()
    if state == ModHubCategoriesFrame.SUB_CATEGORY.BEST or (state == ModHubCategoriesFrame.SUB_CATEGORY.LATEST or state == ModHubCategoriesFrame.SUB_CATEGORY.MOST_DOWNLOADED) then
        self.listSizeLimit = ModHubScreen.SPECIAL_LIST_LIMIT
    else
        self.listSizeLimit = nil
    end
end
function ModHubCategoriesFrame:onActivateItem()
    local modInfo = self.mods[self.itemList.selectedIndex]
    if modInfo ~= nil then
        self.notifyActivatedModItemCallback(self, modInfo.modId, self.categoryName)
        self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
    end
end
function ModHubCategoriesFrame:onActivateCategory()
    local category = self.categories[self.categoryList.selectedSectionIndex][self.categoryList.selectedIndex]
    self.notifyActivatedCategoryCallback(category.id, category.name)
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
end
function ModHubCategoriesFrame:onListSelectionChanged(list, _, index)
    if list == self.itemList then
        local modItem = self.mods[index]
        if modItem ~= nil then
            self.notifySelectedModItemCallback(self, modItem.modId)
        end
    end
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
end
function ModHubCategoriesFrame:setModInfo(modInfo)
    if self.modAttributeName ~= nil then
        self.modAttributeName:setText(modInfo:getName(), true)
        self.modAttributeInfoAuthor:setText(modInfo:getAuthor(), true)
        self.modAttributeInfoVersion:setText(modInfo:getVersionString(), true)
        local isDLC = modInfo:getIsDLC()
        local isTop = modInfo:getIsTop()
        if isDLC then
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
                    self.modAttributeRatingStar[i]:applyProfile(ModHubCategoriesFrame.PROFILE.RATING_STAR_ACTIVE)
                else
                    self.modAttributeRatingStar[i]:applyProfile(ModHubCategoriesFrame.PROFILE.RATING_STAR)
                end
            end
            self.modAttributePrice:setText(g_i18n:getText("modHub_flag_crossplay"), true)
        end
        self.modAttributeInfoSize:setVisible(not isDLC)
        self.modAttributeInfoSizeSpace:setVisible(not isDLC)
        self.modAttributeRatingBox:setVisible(not isDLC)
        self.modAttributeInfoRatingSpace:setVisible(not isDLC)
        self.modAttributePrice:setVisible(isTop)
        self.modAttributeInfoPriceSpace:setVisible(isTop)
        self.modAttributeBox:invalidateLayout()
    end
end
function ModHubCategoriesFrame:onButtonDetails()
    if self.subCategoryPaging:getState() == ModHubCategoriesFrame.SUB_CATEGORY.CATEGORIES then
        self:onActivateCategory()
    else
        self:onActivateItem()
    end
end
function ModHubCategoriesFrame:onButtonSearch()
    self.notifySearchCallback()
end
function ModHubCategoriesFrame:onButtonShowToggle()
    self.notifyToggleBetaCallback(self)
end
function ModHubCategoriesFrame:updateSubCategoryPages(subCategoryIndex)
    self.categoryHeaderIcon:setImageSlice(nil, ModHubCategoriesFrame.HEADER_SLICES[subCategoryIndex])
    self.categoryHeaderTitle:setText(g_i18n:getText(ModHubCategoriesFrame.HEADER_TITLES[subCategoryIndex]))
    local category = self.subCategoryPaging:getState() ~= ModHubCategoriesFrame.SUB_CATEGORY.CATEGORIES
    self.modAttributeBox:setVisible(category)
    self:updateListSizeLimit()
    self.categoryListContainer:setVisible(self.subCategoryPaging:getState() == ModHubCategoriesFrame.SUB_CATEGORY.CATEGORIES)
    self.itemListContainer:setVisible(not isCategoriesPage)
    if isCategoriesPage then
        g_modHubController:reload()
        self.categoryList:reloadData(true)
        self.slider:setDataElement(self.categoryList)
        if not self.isOpening then
            self.categoryList:setSelectedItem(1, 1, nil, true)
            self.categoryList:makeCellVisible(1, 1)
        end
    else
        local categoryName = ModHubCategoriesFrame.CATEGORY_IDS[subCategoryIndex]
        local category = g_modHubController:getCategory(categoryName)
        self:setCategory(categoryName)
        self:setCategoryId(category.id)
        g_modHubController:loadCategory(category.id)
        self:updateList()
        self.slider:setDataElement(self.itemList)
        if not self.isOpening then
            self.itemList:setSelectedIndex(1, nil, true)
            self.itemList:makeCellVisible(1, 1)
        end
    end
    local categoryName = self.noModsElement
    categoryName:setVisible(not isCategoriesPage and #self.mods == 0)
end
function ModHubCategoriesFrame:onClickCategories()
    self.subCategoryPaging:setState(ModHubCategoriesFrame.SUB_CATEGORY.CATEGORIES, true)
end
function ModHubCategoriesFrame:onClickBest()
    self.subCategoryPaging:setState(ModHubCategoriesFrame.SUB_CATEGORY.BEST, true)
end
function ModHubCategoriesFrame:onClickMostDownloaded()
    self.subCategoryPaging:setState(ModHubCategoriesFrame.SUB_CATEGORY.MOST_DOWNLOADED, true)
end
function ModHubCategoriesFrame:onClickLatest()
    self.subCategoryPaging:setState(ModHubCategoriesFrame.SUB_CATEGORY.LATEST, true)
end
function ModHubCategoriesFrame:onClickRecommended()
    self.subCategoryPaging:setState(ModHubCategoriesFrame.SUB_CATEGORY.RECOMMENDED, true)
end
function ModHubCategoriesFrame:getNumberOfSections(list)
    return list == self.categoryList and #self.categoryTypes or 1
end
function ModHubCategoriesFrame:getTitleForSectionHeader(_, section)
    return g_modHubController.categoryTypeNameMapping[self.categoryTypes[section]] or ""
end
function ModHubCategoriesFrame:getNumberOfItemsInSection(list, section)
    if list == self.categoryList then
        return #self.categories[section]
    end
    local total = #self.mods
    if self.listSizeLimit == nil then
        return total
    end
    return math.min(total, self.listSizeLimit)
end
function ModHubCategoriesFrame:populateCellForItemInSection(list, section, index, cell)
    if list == self.categoryList then
        local category = self.categories[section][index]
        local iconElement = cell:getAttribute("markerNew")
        iconElement:setVisible(category.numNewItems > 0)
        local iconElement = cell:getAttribute("markerUpdate")
        iconElement:setVisible(category.numAvailableUpdates > 0)
        local iconElement = cell:getAttribute("markerConflict")
        iconElement:setVisible(category.numConflictedItems > 0)
        cell:getAttribute("markerBox"):invalidateLayout()
        local iconElement = cell:getAttribute("image")
        iconElement:setImageFilename(category.iconFilename)
        iconElement:setSize(nil, iconElement.size[2] * (self.iconHeightWidthRatio or 1))
        cell:getAttribute("text"):setText(category.label)
    else
        local category = self.mods[index]
        local iconElement = category:getNumUpdates()
        local numNew = category:getNumNew()
        local numConflicts = category:getNumConflicts()
        local markerElement = cell:getAttribute("markerNew")
        markerElement:setVisible(iconElement > 0 or (numNew > 0 or numConflicts > 0))
        if numConflicts > 0 then
            markerElement:applyProfile("fs25_modHubMarkerConflict")
        elseif iconElement > 0 then
            markerElement:applyProfile("fs25_modHubMarkerUpdate")
        elseif numNew > 0 then
            markerElement:applyProfile("fs25_modHubMarkerNew")
        end
        cell:getAttribute("markerBox"):invalidateLayout()
        local iconElement = cell:getAttribute("icon")
        iconElement:setIsWebOverlay(not category:getIsIconLocal())
        iconElement:setImageFilename(category:getIconFilename())
        cell:getAttribute("nameLabel"):setText(category:getName())
        cell:getAttribute("dlcTag"):setVisible(category:getIsDLC())
        cell:getAttribute("installedIcon"):setVisible(category:getIsInstalled())
    end
end
ModHubCategoriesFrame.HEADER_SLICES = {
    [ModHubCategoriesFrame.SUB_CATEGORY.CATEGORIES] = "gui.modhub_categories",
    [ModHubCategoriesFrame.SUB_CATEGORY.BEST] = "gui.modHub_best",
    [ModHubCategoriesFrame.SUB_CATEGORY.MOST_DOWNLOADED] = "gui.modHub_mostDownloaded",
    [ModHubCategoriesFrame.SUB_CATEGORY.LATEST] = "gui.modHub_latest",
    [ModHubCategoriesFrame.SUB_CATEGORY.RECOMMENDED] = "gui.modHub_recommended"
}
ModHubCategoriesFrame.HEADER_TITLES = {
    [ModHubCategoriesFrame.SUB_CATEGORY.CATEGORIES] = "ui_modHubCategories",
    [ModHubCategoriesFrame.SUB_CATEGORY.BEST] = "modHub_best",
    [ModHubCategoriesFrame.SUB_CATEGORY.MOST_DOWNLOADED] = "modHub_most_downloaded",
    [ModHubCategoriesFrame.SUB_CATEGORY.LATEST] = "modHub_latest",
    [ModHubCategoriesFrame.SUB_CATEGORY.RECOMMENDED] = "category_recommended"
}
ModHubCategoriesFrame.CATEGORY_IDS = {
    [ModHubCategoriesFrame.SUB_CATEGORY.BEST] = "best",
    [ModHubCategoriesFrame.SUB_CATEGORY.MOST_DOWNLOADED] = "most_downloaded",
    [ModHubCategoriesFrame.SUB_CATEGORY.LATEST] = "latest",
    [ModHubCategoriesFrame.SUB_CATEGORY.RECOMMENDED] = "recommended"
}
ModHubCategoriesFrame.PROFILE = {
    ["RATING_STAR_ACTIVE"] = "fs25_modHubAttributeRatingStarActive",
    ["RATING_STAR"] = "fs25_modHubAttributeRatingStar"
}
ModHubCategoriesFrame.L10N_SYMBOL = {
    ["STATUS_PENDING"] = "modHub_pending",
    ["STATUS_UPDATE"] = "modHub_update",
    ["STATUS_INSTALLED"] = "modHub_installed",
    ["STATUS_FAILED"] = "modHub_failed",
    ["BUTTON_DETAILS"] = "button_detail",
    ["BUTTON_SHOW_ALL"] = "button_modHubShowAll",
    ["BUTTON_SHOW_TOP"] = "button_modHubShowTop"
}