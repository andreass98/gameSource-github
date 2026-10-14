ModHubScreen = {}
local ModHubScreen_mt = Class(ModHubScreen, TabbedMenuWithDetails)
ModHubScreen.SPECIAL_LIST_LIMIT = 42
function ModHubScreen.register()
    ModHubCategoriesFrame.register()
    ModHubDetailsFrame.register()
    ModHubExtraContentFrame.register()
    ModHubItemsFrame.register()
    ModHubLoadingFrame.register()
    local modHubScreen = ModHubScreen.new()
    g_gui:loadGui("dataS/gui/ModHubScreen.xml", "ModHubScreen", modHubScreen)
    return modHubScreen
end
function ModHubScreen.new(target, custom_mt)
    -- upvalues: (copy) ModHubScreen_mt
    local self = TabbedMenuWithDetails.new(target, custom_mt or ModHubScreen_mt)
    self.checkForLoaded = true
    self.isLoading = true
    self.showingAllMods = false
    self.updateModInterval = 1000
    self.updateModTimer = self.updateModInterval
    return self
end
function ModHubScreen.createFromExistingGui(gui, guiName)
    ModHubCategoriesFrame.createFromExistingGui(g_gui.frames.modHubCategories.target, "ModHubCategoriesFrame")
    ModHubDetailsFrame.createFromExistingGui(g_gui.frames.modHubDetails.target, "ModHubDetailsFrame")
    ModHubExtraContentFrame.createFromExistingGui(g_gui.frames.modHubExtraContent.target, "ModHubExtraContentFrame")
    ModHubItemsFrame.createFromExistingGui(g_gui.frames.modHubItems.target, "ModHubItemsFrame")
    local newGui = ModHubScreen.new()
    g_gui.guis[gui.name].target:delete()
    g_gui.guis[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, false)
    return newGui
end
function ModHubScreen:onGuiSetupFinished()
    ModHubScreen:superClass().onGuiSetupFinished(self)
    self.showingAllMods = g_gameSettings:getValue(GameSettings.SETTING.SHOW_ALL_MODS)
    g_modHubController:setShowAllMods(self.showingAllMods)
    self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)
    self.clickNextCallback = self:makeSelfCallback(self.onPageNext)
    self.clickPrevCallback = self:makeSelfCallback(self.onPagePrevious)
    self:setupPages()
    self:setupMenuButtonInfo()
end
function ModHubScreen:setupPages()
    local pagePredicate = self:makeIsModHubEnabledPredicate()
    local contestPredicate = self:makeIsContestEnabledPredicate()
    local detailsPredicate = self:makeIsModHubItemsEnabledPredicate()
    local testingPredicate = self:makeIsTestingEnabledPredicate()
    local orderedPages = {
        { self.pageLoading, self:makeIsLoadingEnabledPredicate(), ModHubScreen.SLICE_ID.CATEGORIES },
        { self.pageCategories, pagePredicate, ModHubScreen.SLICE_ID.CATEGORIES },
        { self.pageInstalled, pagePredicate, ModHubScreen.SLICE_ID.INSTALLED },
        { self.pageUpdates, pagePredicate, ModHubScreen.SLICE_ID.UPDATES },
        { self.pageDLCs, pagePredicate, ModHubScreen.SLICE_ID.DLCS },
        { self.pageExtraContent, pagePredicate, ModHubScreen.SLICE_ID.EXTRA_CONTENT },
        { self.pageContest, contestPredicate, ModHubScreen.SLICE_ID.CONTEST },
        { self.pageTesting, testingPredicate, ModHubScreen.SLICE_ID.TESTING },
        { self.pageItems, detailsPredicate, ModHubScreen.SLICE_ID.BEST },
        { self.pageDetails, detailsPredicate, ModHubScreen.SLICE_ID.BEST },
        { self.pageSearch, detailsPredicate, ModHubScreen.SLICE_ID.BEST }
    }
    for i, pageDef in ipairs(orderedPages) do
        local page, predicate, iconSliceId = unpack(pageDef)
        self:registerPage(page, i, predicate)
        self:addPageTab(page, nil, nil, iconSliceId)
    end
    self:rebuildTabList()
end
function ModHubScreen:setupMenuButtonInfo()
    local onButtonBackFunction = self.clickBackCallback
    local onButtonNextFunction = self.clickNextCallback
    local onButtonPrevFunction = self.clickPrevCallback
    self.defaultMenuButtonInfo = {
        {
            ["inputAction"] = InputAction.MENU_BACK,
            ["text"] = g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_BACK),
            ["callback"] = onButtonBackFunction
        },
        {
            ["inputAction"] = InputAction.MENU_PAGE_NEXT,
            ["text"] = g_i18n:getText("ui_ingameMenuNext"),
            ["callback"] = onButtonNextFunction
        },
        {
            ["inputAction"] = InputAction.MENU_PAGE_PREV,
            ["text"] = g_i18n:getText("ui_ingameMenuPrev"),
            ["callback"] = onButtonPrevFunction
        }
    }
    self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
    self.defaultMenuButtonInfoByActions[InputAction.MENU_PAGE_NEXT] = self.defaultMenuButtonInfo[2]
    self.defaultMenuButtonInfoByActions[InputAction.MENU_PAGE_PREV] = self.defaultMenuButtonInfo[3]
    self.defaultButtonActionCallbacks = {
        [InputAction.MENU_BACK] = onButtonBackFunction,
        [InputAction.MENU_PAGE_NEXT] = onButtonNextFunction,
        [InputAction.MENU_PAGE_PREV] = onButtonPrevFunction
    }
    self:assignMenuButtonInfo(self.defaultMenuButtonInfo)
end
function ModHubScreen:initializePages()
    g_modHubController:setShowAllMods(self.showingAllMods)
    g_modHubController:load()
    g_modHubController:setDiscSpaceChangedCallback(self.updateDiscSpace, self)
    local onSearchButtonCallback = self:makeSelfCallback(self.onSearchButton)
    local onToggleCallback = self:makeSelfCallback(self.onToggleBeta)
    local getBetaToggleTextCallback = self:makeSelfCallback(self.getBetaToggleText)
    local clickItemCallback = self:makeClickItemCallback()
    local onSelectItemCallback = self:makeSelfCallback(self.onSelectItem)
    self.pageCategories:initialize(g_modHubController:getVisibleCategories(), self:makeSelfCallback(self.onClickCategory), g_i18n:getText(ModHubScreen.L10N_SYMBOL.HEADER_MOD_HUB), ModHubScreen.CATEGORY_IMAGE_HEIGHT_WIDTH_RATIO)
    self.pageCategories:setSearchCallback(onSearchButtonCallback)
    self.pageCategories:setToggleBetaCallback(onToggleCallback)
    self.pageCategories:setBetaToggleTextCallback(getBetaToggleTextCallback)
    self.pageCategories:setItemSelectCallback(onSelectItemCallback)
    self.pageCategories:setItemClickCallback(clickItemCallback)
    self.pageExtraContent:initialize(g_i18n:getText(ModHubScreen.L10N_SYMBOL.HEADER_EXTRA_CONTENT))
    local function initCategoryPage(page, categoryName, _, headerIconSliceId)
        -- upvalues: (copy) clickItemCallback, (copy) onSelectItemCallback, (copy) onSearchButtonCallback, (copy) onToggleCallback, (copy) getBetaToggleTextCallback
        local category = g_modHubController:getCategory(categoryName)
        if category ~= nil then
            page:initialize(headerIconSliceId)
            page:setCategoryId(category.id)
            page:setCategory(categoryName)
            page:setItemClickCallback(clickItemCallback)
            page:setItemSelectCallback(onSelectItemCallback)
            page:setSearchCallback(onSearchButtonCallback)
            page:setToggleBetaCallback(onToggleCallback)
            page:setBetaToggleTextCallback(getBetaToggleTextCallback)
        end
    end
    initCategoryPage(self.pageInstalled, "installed", nil, ModHubScreen.SLICE_ID.INSTALLED)
    initCategoryPage(self.pageUpdates, "update", nil, ModHubScreen.SLICE_ID.UPDATES)
    initCategoryPage(self.pageDLCs, "dlc", true, ModHubScreen.SLICE_ID.DLCS)
    initCategoryPage(self.pageContest, "contest", nil, ModHubScreen.SLICE_ID.CONTEST)
    initCategoryPage(self.pageTesting, "testing", nil, ModHubScreen.SLICE_ID.TESTING)
    self.pageSearch:initialize()
    self.pageSearch:setItemClickCallback(clickItemCallback)
    self.pageSearch:setItemSelectCallback(onSelectItemCallback)
    self.pageSearch.headerText:setText(g_i18n:getText("modHub_search"))
    self.pageItems:initialize()
    self.pageItems:setItemClickCallback(clickItemCallback)
    self.pageItems:setItemSelectCallback(onSelectItemCallback)
    self.pageItems:setSearchCallback(onSearchButtonCallback)
    self.pageItems:setToggleBetaCallback(onToggleCallback)
    self.pageItems:setBetaToggleTextCallback(getBetaToggleTextCallback)
    self.pageDetails:initialize()
end
function ModHubScreen:reset()
    ModHubScreen:superClass().reset(self)
    g_modHubController:reset()
    self.showingAllMods = false
end
function ModHubScreen:onOpen(_)
    g_modHubController:startModification()
    if modDownloadManagerLoaded() then
        self:setIsLoading(false)
        self.checkForLoaded = false
        self:updateDownloadStates()
    else
        self:setIsLoading(true)
        self.checkForLoaded = true
    end
    ModHubScreen:superClass().onOpen(self)
    self.pageSelector:setState(1, true)
    if g_isDevelopmentVersion then
        addConsoleCommand("gsModHubUninstallAll", "Uninstalls all mods", "consoleCommandUninstallAll", self)
    end
end
function ModHubScreen:onClose(_)
    removeConsoleCommand("gsModHubUninstallAll")
    g_modHubController:endModification()
    self.pageCategories:reset()
    ModHubScreen:superClass().onClose(self)
end
function ModHubScreen:update(dt)
    ModHubScreen:superClass().update(self, dt)
    if getModDownloadAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
        ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
        return
    elseif getNetworkError() then
        ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
    else
        if self.checkForLoaded and modDownloadManagerLoaded() then
            self.checkForLoaded = false
            self:setIsLoading(false)
            self:updateDownloadStates()
            self:updatePages()
            self.pageSelector:setState(1, true)
        end
        self.updateModTimer = self.updateModTimer - dt
        if self.updateModTimer <= 0 then
            self:updateDownloadStates()
            self:updateDiscSpace(g_modHubController:getFreeModSpaceKb(), g_modHubController:getUsedModSpaceKb())
        end
    end
end
function ModHubScreen:setIsLoading(loading)
    self.isLoading = loading
    if not (loading or self.initialized) then
        self:initializePages()
        self.initialized = true
    end
end
function ModHubScreen:exitMenu()
    self:changeScreen(MainScreen)
end
function ModHubScreen:updateDownloadStates()
    local category = g_modHubController:getCategory("download")
    local activeDownloads = nil
    if category ~= nil then
        activeDownloads = g_modHubController:getModsByCategory(category.id, true)
        self.downloadFailedFound = false
        self.downloadActiveFound = false
        if #activeDownloads > 0 then
            for _, modInfo in ipairs(activeDownloads) do
                self:updateModDownloadState(modInfo)
            end
        end
    end
    local categoryId = self.buttonDownload
    categoryId:setVisible(activeDownloads ~= nil and #activeDownloads > 0)
    self.updateModTimer = self.updateModInterval
end
function ModHubScreen:updateModDownloadState(modInfo)
    if self.downloadFailedFound then
        return
    else
        local isFailed = modInfo:getIsFailed()
        if not (isFailed or self.downloadActiveFound) then
            local isDownloading = modInfo:getIsDownloading()
            local isInstalled = modInfo:getIsInstalled()
            local percent = 0
            if isDownloading or modInfo:getIsDownload() then
                local downloaded = modInfo:getDownloadedBytes()
                local fileSize = modInfo:getFilesize()
                if fileSize ~= 0 then
                    percent = math.clamp(downloaded / fileSize, 0, 1) or percent
                end
            end
            local downloaded = self.downloadStatusBar.startSize[1] + self.downloadStatusBar.endSize[1]
            local fileSize = self.downloadStatusBar
            fileSize:setSize(math.max(self.downloadStatusBarBg.size[1] * percent + g_pixelSizeX, downloaded), nil)
            self.downloadTextFailed:setVisible(isFailed)
            self.downloadStatusBarBg:setVisible(not isFailed)
        end
    end
end
function ModHubScreen:onClickCategory(categoryId, categoryName)
    self.pageItems:setCategoryId(categoryId)
    self.pageItems:setCategory(categoryName)
    self:pushDetail(self.pageItems)
end
function ModHubScreen.onSelectItem(_, page, modId)
    if not g_gui.currentlyReloading then
        page:setModInfo((g_modHubController:getModInfo(modId)))
    end
end
function ModHubScreen:updateDiscSpace(freeSpaceKb, usedSpaceKb)
    local topFrame = self:getTopFrame()
    if topFrame ~= self.pageLoading and (topFrame ~= self.pageExtraContent and topFrame.spaceUsageLabel ~= nil) then
        if Platform.hasLimitedModSpace then
            local total = (freeSpaceKb + usedSpaceKb) / 1024
            local used = usedSpaceKb / 1024
            topFrame.spaceUsageLabel:setText(string.format("%s / %s Mb (%0.f%%)", g_i18n:formatNumber(used, 2, true), g_i18n:formatNumber(total, 2, true), used / total * 100))
            topFrame.diskSpaceBox:setVisible(true)
            topFrame.diskSpaceBoxBg:setVisible(true)
            topFrame.diskSpaceBox:invalidateLayout()
            topFrame.diskSpaceBoxBg:setSize(topFrame.diskSpaceBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
            return
        end
        if topFrame.diskSpaceBox ~= nil then
            topFrame.diskSpaceBox:setVisible(false)
            topFrame.diskSpaceBoxBg:setVisible(false)
        end
    end
end
function ModHubScreen:onSearchButton(categoryId)
    local dialogPrompt = g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH)
    local imePrompt = g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH)
    local confirmText = g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH)
    TextInputDialog.show(self.onSearchFinished, self, nil, dialogPrompt, imePrompt, 40, confirmText, categoryId, nil, false)
end
function ModHubScreen:onSearchFinished(text, ok, categoryId)
    if ok and utf8Strlen(text) > 0 then
        local result = g_modHubController:searchMods(categoryId, text)
        self.pageSearch:setModItems(result)
        self:pushDetail(self.pageSearch)
    end
end
function ModHubScreen:onDownloadButton()
    ModHubDownloadDialog.show()
end
function ModHubScreen:onToggleBeta(page)
    self.showingAllMods = not self.showingAllMods
    g_modHubController:setShowAllMods(self.showingAllMods)
    g_modHubController:reload()
    g_gameSettings:setValue(GameSettings.SETTING.SHOW_ALL_MODS, self.showingAllMods, true)
    self.pageCategories:setCategories(g_modHubController:getVisibleCategories())
    page:reload()
end
function ModHubScreen:getBetaToggleText()
    if self.showingAllMods then
        return g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SHOW_CROSSPLAY)
    else
        return g_i18n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SHOW_ALL)
    end
end
function ModHubScreen:onDetailOpened(...)
    ModHubScreen:superClass().onDetailOpened(self, ...)
    self:updateDiscSpace(g_modHubController:getFreeModSpaceKb(), g_modHubController:getUsedModSpaceKb())
end
function ModHubScreen:onPageChange(...)
    ModHubScreen:superClass().onPageChange(self, ...)
    local index = 1
    for index = index, #self.enabledPages do
        self:updateModhubUpdateIcon(1, index, (self.pagingTabList:getElementAtSectionIndex(1, index)))
    end
    self:updateDiscSpace(g_modHubController:getFreeModSpaceKb(), g_modHubController:getUsedModSpaceKb())
end
function ModHubScreen:populateCellForItemInSection(list, section, index, cell)
    ModHubScreen:superClass().populateCellForItemInSection(self, list, section, index, cell)
    self:updateModhubUpdateIcon(section, index, cell)
end
function ModHubScreen:updateModhubUpdateIcon(_, index, cell)
    if modDownloadManagerLoaded() then
        local _, numUpdates, _ = g_modHubController:getCategoryData(ModHubController.CATEGORY_ID_UPDATE)
        cell:getAttribute("iconHasUpdates"):setVisible(self.enabledPages[index] == self.pageUpdates and numUpdates > 0)
    end
end
function ModHubScreen:makeClickItemCallback()
    return function(_, modId, _)
        -- upvalues: (copy) self
        local modInfo = g_modHubController:getModInfo(modId)
        self.pageDetails:setModInfo(modInfo)
        self:pushDetail(self.pageDetails)
    end
end
function ModHubScreen:makeIsLoadingEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        return self.isLoading
    end
end
function ModHubScreen:makeIsModHubEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        return not self.isLoading and not self:getIsDetailMode()
    end
end
function ModHubScreen:makeIsModHubItemsEnabledPredicate()
    return function()
        return false
    end
end
function ModHubScreen:makeIsContestEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        return not (self.isLoading or self:getIsDetailMode()) and g_modHubController:isContestEnabled()
    end
end
function ModHubScreen:makeIsTestingEnabledPredicate()
    return function()
        return g_isDevelopmentVersion
    end
end
function ModHubScreen:openWithModId(modId)
    local modInfo = g_modHubController:getModInfo(modId)
    if modInfo ~= nil then
        g_gui:showGui("ModHubScreen")
        self.pageDetails:setModInfo(modInfo)
        self:pushDetail(self.pageDetails)
    end
end
function ModHubScreen:openDownloads()
    g_gui:showGui("ModHubScreen")
    ModHubDownloadDialog.show()
end
function ModHubScreen:consoleCommandUninstallAll()
    local function dummy() end
    g_modHubController:setUninstallFailedCallback(dummy, nil)
    g_modHubController:setUninstalledCallback(dummy, nil)
    local category = g_modHubController:getCategory("installed")
    local mods = g_modHubController:getModsByCategory(category.id, true)
    for _, modInfo in ipairs(mods) do
        g_modHubController:uninstall(modInfo:getId())
    end
end
ModHubScreen.L10N_SYMBOL = {
    ["HEADER_MOD_HUB"] = "modHub_title",
    ["HEADER_EXTRA_CONTENT"] = "modHub_extraContent",
    ["BUTTON_BACK"] = "button_back",
    ["BUTTON_SEARCH"] = "modHub_search",
    ["BUTTON_SHOW_ALL"] = "button_modHubShowAll",
    ["BUTTON_SHOW_CROSSPLAY"] = "button_modHubShowCrossplay"
}
ModHubScreen.SLICE_ID = {
    ["CATEGORIES"] = "gui.modhub_categories",
    ["DLCS"] = "gui.modhub_dlcs",
    ["BEST"] = "gui.modHub_best",
    ["MOST_DOWNLOADED"] = "gui.modHub_mostDownloaded",
    ["LATEST"] = "gui.modHub_latest",
    ["CONTEST"] = "gui.modHub_winners",
    ["RECOMMENDED"] = "gui.modHub_recommended",
    ["DOWNLOADS"] = "gui.modHub_downloads",
    ["UPDATES"] = "gui.modhub_updates",
    ["INSTALLED"] = "gui.modhub_installed",
    ["EXTRA_CONTENT"] = "gui.modhub_extraContent",
    ["TESTING"] = "gui.modhub_testing"
}
ModHubScreen.CATEGORY_IMAGE_HEIGHT_WIDTH_RATIO = 1