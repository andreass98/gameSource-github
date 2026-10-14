TabbedMenu = {}
local TabbedMenu_mt = Class(TabbedMenu, ScreenElement)
TabbedMenu.PAGE_TAB_TEMPLATE_BUTTON_NAME = "tabButton"
TabbedMenu.NO_BUTTON_INFO = {}
TabbedMenu.DEFAULT_BUTTON_ACTIONS = {
    [InputAction.MENU_ACCEPT] = true,
    [InputAction.MENU_ACTIVATE] = true,
    [InputAction.MENU_CANCEL] = true,
    [InputAction.MENU_BACK] = true,
    [InputAction.MENU_EXTRA_1] = true,
    [InputAction.MENU_EXTRA_2] = true
}
TabbedMenu.PAUSE_ACTIONS = {
    [InputAction.MENU_BACK] = true,
    [InputAction.MENU_PAGE_NEXT] = true,
    [InputAction.MENU_PAGE_PREV] = true
}
TabbedMenu.MONEY_UPDATE_INTERVAL = 300
local function NO_CALLBACK() end
function TabbedMenu.new(target, custom_mt)
    -- upvalues: (copy) TabbedMenu_mt, (copy) NO_CALLBACK
    local self = ScreenElement.new(target, custom_mt or TabbedMenu_mt)
    self.pageFrames = {}
    self.pageTabs = {}
    self.pageTypeControllers = {}
    self.pageRoots = {}
    self.pageEnablingPredicates = {}
    self.disabledPages = {}
    self.enabledPages = {}
    self.currentPageId = 1
    self.currentPageListIndex = 1
    self.currentPage = nil
    self.restorePageIndex = 1
    self.restorePageScrollOffset = 0
    self.buttonActionCallbacks = {}
    self.defaultButtonActionCallbacks = {}
    self.defaultMenuButtonInfoByActions = {}
    self.customButtonEvents = {}
    self.clickBackCallback = NO_CALLBACK
    self.frameClosePageNextCallback = self:makeSelfCallback(self.onPageNext)
    self.frameClosePagePreviousCallback = self:makeSelfCallback(self.onPagePrevious)
    self.performBackgroundBlur = false
    return self
end
function TabbedMenu:delete()
    g_messageCenter:unsubscribeAll(self)
    TabbedMenu:superClass().delete(self)
end
function TabbedMenu:onGuiSetupFinished()
    TabbedMenu:superClass().onGuiSetupFinished(self)
    self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)
    self:setupMenuButtonInfo()
    if self.pagingElement.profile == "uiInGameMenuPaging" then
        self.pagingElement:setSize(1 - self.header.absSize[1])
    end
end
function TabbedMenu:exitMenu()
    self:changeScreen(nil)
end
function TabbedMenu:reset()
    TabbedMenu:superClass().reset(self)
    self.currentPageId = 1
    self.currentPage = nil
    self.restorePageIndex = 1
    self.restorePageScrollOffset = 0
end
function TabbedMenu:onOpen(_)
    TabbedMenu:superClass().onOpen(self)
    if self.performBackgroundBlur then
        g_depthOfFieldManager:pushArea(0, 0, 1, 1)
    end
    if not self.muteSound then
        self:playSample(GuiSoundPlayer.SOUND_SAMPLES.PAGING)
    end
    if self.gameState ~= nil then
        g_gameStateManager:setGameState(self.gameState)
    end
    self:setSoundSuppressed(true)
    self:updatePages()
    if self.restorePageIndex ~= nil then
        self.currentPage = self.restorePage
        self.pageSelector:setState(self.restorePageIndex, true)
        if self.pagingTabList ~= nil then
            self.pagingTabList:scrollTo(self.restorePageScrollOffset)
        end
    end
    self:setSoundSuppressed(false)
    self:onMenuOpened()
end
function TabbedMenu:onClose(_)
    if self.currentPage ~= nil then
        self.currentPage:onFrameClose()
    end
    TabbedMenu:superClass().onClose(self)
    if self.performBackgroundBlur then
        g_depthOfFieldManager:popArea()
    end
    g_inputBinding:storeEventBindings()
    self:clearMenuButtonActions()
    self.restorePage = self.currentPage
    self.restorePageIndex = self.pageSelector:getState()
    if self.pagingTabList ~= nil then
        self.restorePageScrollOffset = self.pagingTabList.viewOffset
    end
    self.currentPage = nil
    self.currentPageId = nil
    if self.gameState ~= nil then
        g_currentMission:resetGameState()
    end
end
function TabbedMenu:update(dt)
    TabbedMenu:superClass().update(self, dt)
    if self.currentPage ~= nil and (FocusManager.currentGui ~= self.currentPage.name and not g_gui:getIsDialogVisible()) then
        FocusManager:setGui(self.currentPage.name)
    end
    if self.currentPage ~= nil then
        if self.currentPage:isMenuButtonInfoDirty() and (g_gui.currentListener ~= nil and g_gui.currentListener.name or nil) == self.name then
            self:assignMenuButtonInfo(self.currentPage:getMenuButtonInfo())
            self.currentPage:clearMenuButtonInfoDirty()
        end
        if self.currentPage:isTabbingMenuVisibleDirty() then
            self:updatePagingVisibility(self.currentPage:getTabbingMenuVisible())
        end
    end
end
function TabbedMenu:setupMenuButtonInfo() end
function TabbedMenu:addPageTab(frameController, iconFilename, iconUVs, iconSliceId, soundId)
    local tab = {}
    self.pageTabs[frameController] = tab
    tab.iconFilename = iconFilename
    tab.iconUVs = iconUVs
    tab.iconSliceId = iconSliceId
    tab.soundId = soundId
    function tab.onClickCallback()
        -- upvalues: (copy) self, (copy) frameController, (copy) tab
        self:onPageClicked(self.activeDetailPage)
        local pageId = self.pagingElement:getPageIdByElement(frameController)
        local pageMappingIndex = self.pagingElement:getPageMappingIndex(pageId)
        if self.currentPage:requestClose(tab.onClickCallback) then
            self.pageSelector:setState(pageMappingIndex, true)
        end
    end
end
function TabbedMenu:onPageClicked(oldPage) end
function TabbedMenu:setPageTabEnabled(pageController, isEnabled, blockListReload)
    self.pageTabs[pageController].isDisabled = not isEnabled
    if not blockListReload then
        self.pagingTabList:reloadData()
    end
end
function TabbedMenu:rebuildTabList()
    self.enabledPages = {}
    for i, page in ipairs(self.pageFrames) do
        local pageId = self.pagingElement:getPageIdByElement(page)
        if not self.pagingElement:getIsPageDisabled(pageId) then
            table.insert(self.enabledPages, page)
        end
    end
    self.pagingTabList:reloadData()
    self.pagingTabList:setSelectedIndex(self.currentPageListIndex)
end
function TabbedMenu:getNumberOfItemsInSection(_, _)
    return #self.enabledPages
end
function TabbedMenu:populateCellForItemInSection(_, _, index, cell)
    local button = cell:getAttribute("tabButton")
    local tab = self.pageTabs[self.enabledPages[index]]
    button:setImageFilename(nil, tab.iconFilename)
    button:setImageUVs(nil, tab.iconUVs)
    button:setImageSlice(nil, tab.iconSliceId)
    if tab.soundId == nil then
        button:setClickSound(GuiSoundPlayer.SOUND_SAMPLES.PAGING)
    else
        button:setClickSound(tab.soundId)
    end
    button.onClickCallback = tab.onClickCallback
end
function TabbedMenu:updatePages()
    for pageElement, predicate in pairs(self.pageEnablingPredicates) do
        local pageId = self.pagingElement:getPageIdByElement(pageElement)
        local enable = false
        if self.disabledPages[pageElement] == nil then
            enable = predicate()
        end
        self.pagingElement.neuterPageUpdates = true
        self.pagingElement:setPageIdDisabled(pageId, not enable)
        self.pagingElement.neuterPageUpdates = false
        self:setPageTabEnabled(pageElement, enable, true)
    end
    self:rebuildTabList()
    self:setPageSelectorTitles()
end
function TabbedMenu:clearMenuButtonActions()
    for k in pairs(self.buttonActionCallbacks) do
        self.buttonActionCallbacks[k] = nil
    end
    for k in ipairs(self.customButtonEvents) do
        g_inputBinding:removeActionEvent(self.customButtonEvents[k])
        self.customButtonEvents[k] = nil
    end
end
function TabbedMenu:assignMenuButtonInfo(menuButtonInfo)
    -- upvalues: (copy) NO_CALLBACK
    self:clearMenuButtonActions()
    for i, button in ipairs(self.menuButton) do
        local info = menuButtonInfo[i]
        local hasInfo = info ~= nil
        button:setVisible(hasInfo)
        if hasInfo and (info.inputAction ~= nil and InputAction[info.inputAction] ~= nil) then
            button:setInputAction(info.inputAction)
            if Platform.isMobile then
                if info.profile == nil then
                    button:applyProfile("buttonBack")
                else
                    button:applyProfile(info.profile)
                end
            end
            local buttonText = info.text
            if buttonText == nil and self.defaultMenuButtonInfoByActions[info.inputAction] ~= nil then
                buttonText = self.defaultMenuButtonInfoByActions[info.inputAction].text
            end
            button:setText(buttonText)
            local buttonClickCallback = info.callback or (self.defaultButtonActionCallbacks[info.inputAction] or NO_CALLBACK)
            local sound = GuiSoundPlayer.SOUND_SAMPLES.CLICK
            if info.inputAction == InputAction.MENU_BACK then
                sound = GuiSoundPlayer.SOUND_SAMPLES.BACK
            end
            if info.clickSound == nil or info.clickSound == sound then
                button:setClickSound(sound)
            else
                local sound = info.clickSound
                buttonClickCallback = function(...)
                    -- upvalues: (copy) self, (ref) sound, (copy) buttonClickCallback
                    self:playSample(sound)
                    self:setNextScreenClickSoundMuted()
                    return buttonClickCallback(...)
                end
                button:setClickSound(GuiSoundPlayer.SOUND_SAMPLES.NONE)
            end
            local oldButtonClickCallback = Platform.isMobile or (not self.paused or info.showWhenPaused)
            if not oldButtonClickCallback then
                oldButtonClickCallback = TabbedMenu.PAUSE_ACTIONS[info.inputAction] ~= nil
            end
            local disabled = info.disabled or not oldButtonClickCallback
            if not disabled then
                if TabbedMenu.DEFAULT_BUTTON_ACTIONS[info.inputAction] then
                    self.buttonActionCallbacks[info.inputAction] = buttonClickCallback
                else
                    local _, eventId = g_inputBinding:registerActionEvent(info.inputAction, nil, buttonClickCallback, false, true, false, true)
                    g_inputBinding:setActionEventTextVisibility(eventId, false)
                    table.insert(self.customButtonEvents, eventId)
                end
            end
            button.onClickCallback = buttonClickCallback
            button:setDisabled(disabled)
            local _ = button:getDescendantByName("separator")
            if _ ~= nil then
                _:setVisible(i ~= 1)
            end
        end
    end
    if self.buttonActionCallbacks[InputAction.MENU_BACK] == nil then
        self.buttonActionCallbacks[InputAction.MENU_BACK] = self.clickBackCallback
    end
    self.buttonsPanel:invalidateLayout()
end
function TabbedMenu:setPageSelectorTitles()
    local texts = self.pagingElement:getPageTitles()
    self.pageSelector:setTexts(texts)
    self.pageSelector:setDisabled(#texts == 1)
    self.pageSelector.state = self.pagingElement:getPageMappingIndex((self.pagingElement:getCurrentPageId()))
end
function TabbedMenu:goToPage(page, muteSound)
    self.muteSound = muteSound
    local index = self.pagingElement:getPageMappingIndexByElement(page)
    if index ~= nil then
        self.pageSelector:setState(index, true)
    end
    self.muteSound = self.muteSound
end
function TabbedMenu:updatePagingVisibility(visible)
    self.header:setVisible(visible)
end
function TabbedMenu:onMenuActionClick(menuActionName)
    -- upvalues: (copy) NO_CALLBACK
    local buttonCallback = self.buttonActionCallbacks[menuActionName]
    return (buttonCallback == nil or buttonCallback == NO_CALLBACK) and true or (buttonCallback() or false)
end
function TabbedMenu:onClickOk()
    return self:onMenuActionClick(InputAction.MENU_ACCEPT)
end
function TabbedMenu:onClickBack()
    local eventUnused = (self.currentPage == nil or self.currentPage:requestClose(self.clickBackCallback)) and TabbedMenu:superClass().onClickBack(self)
    if eventUnused then
        eventUnused = self:onMenuActionClick(InputAction.MENU_BACK)
    end
    return eventUnused
end
function TabbedMenu:onClickCancel()
    local eventUnused = TabbedMenu:superClass().onClickCancel(self)
    if eventUnused then
        eventUnused = self:onMenuActionClick(InputAction.MENU_CANCEL)
    end
    return eventUnused
end
function TabbedMenu:onClickActivate()
    local eventUnused = TabbedMenu:superClass().onClickActivate(self)
    if eventUnused then
        eventUnused = self:onMenuActionClick(InputAction.MENU_ACTIVATE)
    end
    return eventUnused
end
function TabbedMenu:onClickMenuExtra1()
    local eventUnused = TabbedMenu:superClass().onClickMenuExtra1(self)
    if eventUnused then
        eventUnused = self:onMenuActionClick(InputAction.MENU_EXTRA_1)
    end
    return eventUnused
end
function TabbedMenu:onClickMenuExtra2()
    local eventUnused = TabbedMenu:superClass().onClickMenuExtra2(self)
    if eventUnused then
        eventUnused = self:onMenuActionClick(InputAction.MENU_EXTRA_2)
    end
    return eventUnused
end
function TabbedMenu:onClickPageSelection(state)
    if self.pagingElement:setPage(state) and not self.muteSound then
        local soundId = GuiSoundPlayer.SOUND_SAMPLES.CLICK
        if self.pageTabs[self.currentPage] ~= nil and self.pageTabs[self.currentPage].soundId ~= nil then
            soundId = self.pageTabs[self.currentPage].soundId
        end
        self:playSample(soundId)
    end
end
function TabbedMenu:onPagePrevious()
    if Platform.isMobile then
        if self.currentPage:getHasPreviousPage() then
            self.currentPage:onPreviousPage()
            return
        end
    elseif self.currentPage:requestClose(self.frameClosePagePreviousCallback) then
        TabbedMenu:superClass().onPagePrevious(self)
    end
end
function TabbedMenu:onPageNext()
    if Platform.isMobile then
        if self.currentPage:getHasNextPage() then
            self.currentPage:onNextPage()
            return
        end
    elseif self.currentPage:requestClose(self.frameClosePageNextCallback) then
        TabbedMenu:superClass().onPageNext(self)
    end
end
function TabbedMenu:onPageChange(pageIndex, pageMappingIndex, _, skipTabVisualUpdate)
    if self.currentPage ~= nil then
        self.currentPage:onFrameClose()
        self.currentPage:setVisible(false)
    end
    g_inputBinding:storeEventBindings()
    local page = self.pagingElement:getPageElementByIndex(pageIndex)
    self.currentPage = page
    self.currentPageListIndex = pageMappingIndex
    if not skipTabVisualUpdate then
        self.currentPageId = pageIndex
        if self.pagingTabList ~= nil then
            self.pagingTabList:setSelectedIndex(pageMappingIndex)
        end
    end
    page:setVisible(true)
    page:setSoundSuppressed(true)
    FocusManager:setGui(page.name)
    page:setSoundSuppressed(false)
    self:updateButtonsPanel(page)
    self:updateTabDisplay()
    page:onFrameOpen()
end
function TabbedMenu:onTabMenuSelectionChanged() end
function TabbedMenu:onTabMenuScroll()
    self:updateTabDisplay()
end
function TabbedMenu:updateButtonsPanel(page)
    self:assignMenuButtonInfo((self:getPageButtonInfo(page)))
    if page.buttonBox ~= nil then
        page.buttonBox.parent:addElement(page.buttonBox)
    end
end
function TabbedMenu:updateTabDisplay()
    if not Platform.isMobile then
        if self.pagingTabPrevious ~= nil then
            local isFirstItemVisible = false
            if self.pagingTabList.totalItemCount > 0 then
                isFirstItemVisible = list.sections[1].cells[1] ~= nil
            end
            self.pagingTabPrevious:setVisible(not isFirstItemVisible)
            if not isFirstItemVisible then
                local prevElement = list.listItems[list.firstVisibleItem - 1].elements[1]
                self.pagingTabPrevious.elements[1]:setImageUVs(GuiOverlay.STATE_NORMAL, unpack(prevElement.icon.uvs))
                self.pagingTabPrevious.elements[1]:setImageFilename(prevElement.icon.filename)
            end
        end
        if self.pagingTabNext ~= nil then
            local itemToShow = false
            if list.totalItemCount > 0 then
                itemToShow = list.sections[#list.sections].cells[list.sections[#list.sections].numItems] ~= nil
            end
            self.pagingTabNext:setVisible(not itemToShow)
            if not itemToShow then
                local nextElement = list.listItems[list.firstVisibleItem + list.visibleItems].elements[1]
                self.pagingTabNext.elements[1]:setImageUVs(GuiOverlay.STATE_NORMAL, unpack(nextElement.icon.uvs))
                self.pagingTabNext.elements[1]:setImageFilename(nextElement.icon.filename)
            end
        end
    end
end
function TabbedMenu:getPageButtonInfo(page)
    if page:getHasCustomMenuButtons() then
        return page:getMenuButtonInfo()
    else
        return self.defaultMenuButtonInfo
    end
end
function TabbedMenu:onPageUpdate() end
function TabbedMenu:onButtonBack()
    self:exitMenu()
end
function TabbedMenu:onMenuOpened() end
function TabbedMenu:registerPage(pageFrameElement, position, enablingPredicateFunction)
    if position == nil then
        position = #self.pageFrames + 1
    else
        position = math.max(1, (math.min(#self.pageFrames + 1, position)))
    end
    table.insert(self.pageFrames, position, pageFrameElement)
    self.pageTypeControllers[pageFrameElement:class()] = pageFrameElement
    local pageRoot = pageFrameElement.elements[1]
    self.pageRoots[pageFrameElement] = pageRoot
    self.pageEnablingPredicates[pageFrameElement] = enablingPredicateFunction
    pageFrameElement:setVisible(false)
    return pageRoot, position
end
function TabbedMenu:unregisterPage(pageFrameClass)
    local pageController = self.pageTypeControllers[pageFrameClass]
    local pageRoot = nil
    if pageController ~= nil then
        local pageRemoveIndex = -1
        for i, page in ipairs(self.pageFrames) do
            if page == pageController then
                pageRemoveIndex = i
                break
            end
        end
        table.remove(self.pageFrames, pageRemoveIndex)
        pageRoot = self.pageRoots[pageController]
        self.pageRoots[pageController] = nil
        self.pageTypeControllers[pageFrameClass] = nil
        self.pageEnablingPredicates[pageController] = nil
        self.pageTabs[pageController] = nil
    end
    local pageRemoveIndex = pageController ~= nil
    return pageRemoveIndex, pageController, pageRoot, nil
end
function TabbedMenu:addPage(pageFrameElement, position, tabIconFilename, tabIconUVs, enablingPredicateFunction)
    local pageRoot, actualPosition = self:registerPage(pageFrameElement, position, enablingPredicateFunction)
    self:addPageTab(pageFrameElement, tabIconFilename, GuiUtils.getUVs(tabIconUVs))
    local name = pageRoot.title
    if name == nil then
        name = g_i18n:getText("ui_" .. pageRoot.name)
    end
    self.pagingElement:addPage(string.upper(pageRoot.name), pageRoot, name, actualPosition)
end
function TabbedMenu:removePage(pageFrameClass)
    if self.defaultPageElementIDs[self.pageTypeControllers[pageFrameClass]] == nil then
        local needDelete, pageController, pageRoot, pageTab = self:unregisterPage(pageFrameClass)
        if needDelete then
            self.pagingElement:removeElement(pageRoot)
            pageRoot:delete()
            pageController:delete()
            if self.pagingTabList ~= nil then
                self.pagingTabList:removeElement(pageTab)
            end
            pageTab:delete()
        end
    else
        self:setPageEnabled(pageFrameClass, false)
    end
end
function TabbedMenu:setPageEnabled(pageFrameClass, isEnabled)
    local pageController = self.pageTypeControllers[pageFrameClass]
    if pageController ~= nil then
        local pageId = self.pagingElement:getPageIdByElement(pageController)
        self.pagingElement:setPageIdDisabled(pageId, not isEnabled)
        pageController:setDisabled(not isEnabled)
        if isEnabled then
            self.disabledPages[pageController] = nil
        else
            self.disabledPages[pageController] = pageController
        end
        self:setPageTabEnabled(pageController, isEnabled)
        if self.pagingTabList ~= nil then
            self.pagingTabList:updateView()
        end
    end
end
function TabbedMenu:makeSelfCallback(func)
    return function(...)
        -- upvalues: (copy) func, (copy) self
        return func(self, ...)
    end
end
TabbedMenu.PROFILE = {
    ["PAGE_TAB"] = "uiTabbedMenuPageTab",
    ["PAGE_TAB_ACTIVE"] = "uiTabbedMenuPageTabActive"
}