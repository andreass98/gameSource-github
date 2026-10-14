InGameMenuSaveFrame = {}
InGameMenuSaveFrame.NUM_GAMEPLAY_HINTS = 4
local InGameMenuSaveFrame_mt = Class(InGameMenuSaveFrame, TabbedMenuFrameElement)
function InGameMenuSaveFrame.register()
    local inGameMenuSaveFrame = InGameMenuSaveFrame.new()
    g_gui:loadGui("dataS/gui/InGameMenuSaveFrame.xml", "SaveFrame", inGameMenuSaveFrame, true)
end
function InGameMenuSaveFrame.new(target, custom_mt)
    -- upvalues: (copy) InGameMenuSaveFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuSaveFrame_mt)
    self.hasMasterRights = false
    self.hasCustomMenuButtons = true
    self.gameplayHintsInitialized = false
    self.gameplayHintDuration = 6500
    self.gameplayHintTime = self.gameplayHintDuration
    return self
end
function InGameMenuSaveFrame.createFromExistingGui(gui, guiName)
    local newGui = InGameMenuSaveFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function InGameMenuSaveFrame:initialize()
    InGameMenuSaveFrame:superClass().initialize(self)
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
    self.selectButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACCEPT,
        ["text"] = g_i18n:getText("button_select"),
        ["callback"] = self.onMenuAccept,
        ["showWhenPaused"] = true
    }
    self.saveButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACTIVATE,
        ["text"] = g_i18n:getText("button_saveGame"),
        ["callback"] = self.onButtonSaveGame,
        ["showWhenPaused"] = true
    }
    self.quitButtonInfo = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = g_i18n:getText("button_quit"),
        ["callback"] = self.onButtonQuit,
        ["showWhenPaused"] = true
    }
    self.menuButtonInfo = {
        self.backButtonInfo,
        self.nextPageButtonInfo,
        self.prevPageButtonInfo,
        self.selectButtonInfo,
        self.saveButtonInfo,
        self.quitButtonInfo
    }
    self.buttonOpenControls:setVisible(Platform.canChangeControls)
    self.buttonsLayout:invalidateLayout()
end
function InGameMenuSaveFrame:onFrameOpen()
    InGameMenuSaveFrame:superClass().onFrameOpen(self)
    if self.saveButton:getIsDisabled() ~= not self.hasMasterRights then
        self.saveButton:setDisabled(not self.hasMasterRights)
    end
    if self.saveButton:getIsDisabled() then
        FocusManager:setFocus(self.gameSettingsButton)
    end
    self:updateMenuButtons()
end
function InGameMenuSaveFrame:onFrameClose()
    InGameMenuSaveFrame:superClass().onFrameClose(self)
    self.gameplayHintsInitialized = false
end
function InGameMenuSaveFrame:setHasMasterRights(hasMasterRights)
    self.hasMasterRights = hasMasterRights
    if self.saveButton:getIsDisabled() ~= not self.hasMasterRights then
        self.saveButton:setDisabled(not self.hasMasterRights)
    end
    self:updateMenuButtons()
end
function InGameMenuSaveFrame:update(dt)
    InGameMenuSaveFrame:superClass().update(self, dt)
    if self.gameplayHintsInitialized then
        self.gameplayHintTime = self.gameplayHintTime - dt
        if self.gameplayHintTime <= 0 then
            self.gameplayHintTime = self.gameplayHintDuration
            self.gameplayHintSelector.soundDisabled = true
            self.gameplayHintSelector:onRightButtonClicked(nil, true)
            self.gameplayHintSelector.soundDisabled = false
            return
        end
    elseif g_gameplayHintManager:getIsLoaded() then
        local hints = g_gameplayHintManager:getRandomGameplayHint(InGameMenuSaveFrame.NUM_GAMEPLAY_HINTS)
        if hints ~= nil then
            local texts = {}
            for _, hint in ipairs(hints) do
                local text = string.gsub(hint, "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true))
                table.insert(texts, text)
            end
            self.gameplayHintsInitialized = true
            self.gameplayHintSelector:setTexts(texts)
            self.hintStateBox:setPageCount(InGameMenuSaveFrame.NUM_GAMEPLAY_HINTS)
        end
        self.gameplayHintTime = self.gameplayHintDuration
    end
end
function InGameMenuSaveFrame:updateMenuButtons()
    self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
    if not self.gameplayHintSelector:getIsFocused() then
        table.insert(self.menuButtonInfo, self.selectButtonInfo)
    end
    if self.hasMasterRights then
        table.insert(self.menuButtonInfo, self.saveButtonInfo)
    end
    table.insert(self.menuButtonInfo, self.quitButtonInfo)
    self:setMenuButtonInfoDirty()
end
function InGameMenuSaveFrame:onButtonFocused(button)
    if not g_gui.currentlyReloading then
        FocusManager:linkElements(self.gameplayHintSelector, FocusManager.TOP, button)
        FocusManager:linkElements(self.gameplayHintSelector, FocusManager.BOTTOM, button)
    end
end
function InGameMenuSaveFrame:onMenuAccept()
    local focusedButton = FocusManager:getFocusedElement()
    if focusedButton.onClickCallback ~= nil then
        focusedButton:onClickCallback()
    end
end
function InGameMenuSaveFrame:onButtonSaveGame()
    g_inGameMenu:onButtonSaveGame()
end
function InGameMenuSaveFrame:onButtonGameSettings()
    g_inGameMenu:openGameSettingsScreen()
end
function InGameMenuSaveFrame:onButtonControls()
    g_inGameMenu:openControlsScreen()
    g_inGameMenu.pageSettings.controlsList:makeCellVisible(1, 1)
    g_inGameMenu.pageSettings.nextFocusSection = 1
    g_inGameMenu.pageSettings.nextFocusCell = 1
end
function InGameMenuSaveFrame:onButtonHelp()
    g_inGameMenu:openHelpLine()
end
function InGameMenuSaveFrame:onButtonQuit()
    g_inGameMenu:onButtonQuit()
end