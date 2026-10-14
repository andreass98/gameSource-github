MultiplayerScreen = {}
MultiplayerScreen.NUM_HINTS = 7
MultiplayerScreen.HINTS_KEY = "ui_joinMultiplayerHint"
local MultiplayerScreen_mt = Class(MultiplayerScreen, ScreenElement)
function MultiplayerScreen.register()
    local multiplayerScreen = MultiplayerScreen.new()
    g_gui:loadGui("dataS/gui/MultiplayerScreen.xml", "MultiplayerScreen", multiplayerScreen)
    return multiplayerScreen
end
function MultiplayerScreen.new(target, custom_mt)
    -- upvalues: (copy) MultiplayerScreen_mt
    local self = ScreenElement.new(target, custom_mt or MultiplayerScreen_mt)
    self.returnScreenClass = MainScreen
    self.gameplayHintsInitialized = false
    self.gameplayHintDuration = 6500
    self.gameplayHintTime = self.gameplayHintDuration
    return self
end
function MultiplayerScreen.createFromExistingGui(gui, guiName)
    local newGui = MultiplayerScreen.new()
    g_gui.guis[guiName]:delete()
    g_gui.guis[guiName].target:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    return newGui
end
function MultiplayerScreen:onOpen()
    MultiplayerScreen:superClass().onOpen(self)
    self:initJoinGameScreen()
    g_startMissionInfo.createGame = false
    g_startMissionInfo.isMultiplayer = true
    if g_startMissionInfo.canStart then
        g_startMissionInfo.canStart = false
        self:changeScreen(ConnectToMasterServerScreen)
        g_connectToMasterServerScreen:connectToFront()
    end
    self:updateOnlinePresenceName()
    self.listCoop:reloadData()
    FocusManager:linkElements(self.listCoop, FocusManager.RIGHT, nil)
    FocusManager:linkElements(self.listCoop, FocusManager.TOP, nil)
    FocusManager:setFocus(self.listCoop)
    local hints = {}
    local i = 1
    for i = i, MultiplayerScreen.NUM_HINTS do
        table.insert(hints, g_i18n:getText(MultiplayerScreen.HINTS_KEY .. tostring(i)))
    end
    self.gameplayHintsInitialized = true
    self.gameplayHintSelector:setTexts(hints)
    self.hintStateBox:setPageCount(MultiplayerScreen.NUM_HINTS)
    self.gameplayHintTime = self.gameplayHintDuration
end
function MultiplayerScreen:updateOnlinePresenceName()
    self.onlineNameText:setText(g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME))
    if self.onlineNameBox ~= nil then
        self.onlineNameBox:invalidateLayout()
        self.onlineNameBoxBg:setSize(self.onlineNameBox.flowSizes[1] + 65 * g_pixelSizeScaledX)
    end
    if Platform.canChangeGamerTag then
        self.changeNameButton:setVisible(true)
    else
        self.changeNameButton:setVisible(false)
    end
    self.changeNameButton.parent:invalidateLayout()
end
function MultiplayerScreen:initJoinGameScreen()
    g_connectionManager:startupWithWorkingPort(g_gameSettings:getValue(GameSettings.SETTING.DEFAULT_SERVER_PORT))
    g_connectToMasterServerScreen:setNextScreenClass(JoinGameScreen)
    g_connectToMasterServerScreen:setPrevScreenClass(MultiplayerScreen)
end
function MultiplayerScreen:onContinue()
    if FocusManager:getFocusedElement() == self.listCoop then
        local index = self.listCoop.selectedIndex
        if index == 1 then
            g_startMissionInfo.canStart = false
            self:changeScreen(ConnectToMasterServerScreen)
            g_connectToMasterServerScreen:connectToFront()
            return
        end
        if index == 2 then
            g_startMissionInfo.canStart = false
            g_createGameScreen.usePendingInvites = false
            self:changeScreen(CareerScreen)
            return
        end
        if index == 3 then
            openWebFile(Platform.urlDedicatedServer, "")
        end
    end
end
function MultiplayerScreen:onClickCreateGame()
    self.listCoop:setSelectedIndex(2)
    self:onContinue()
end
function MultiplayerScreen:onClickJoinGame()
    self.listCoop:setSelectedIndex(1)
    self:onContinue()
end
function MultiplayerScreen:update(dt)
    MultiplayerScreen:superClass().update(self, dt)
    Platform.verifyMultiplayerAvailabilityInMenu()
    self.natWarning:setVisible(getNATType() == NATType.NAT_STRICT)
    self.gameplayHintTime = self.gameplayHintTime - dt
    if self.gameplayHintTime <= 0 then
        self.gameplayHintTime = self.gameplayHintDuration
        self.gameplayHintSelector.soundDisabled = true
        self.gameplayHintSelector:onRightButtonClicked(nil, true)
        self.gameplayHintSelector.soundDisabled = false
    end
end
function MultiplayerScreen:onClickChangeName()
    local text = g_i18n:getText("ui_enterName")
    local defaultText = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)
    local confirmText = g_i18n:getText("button_change")
    TextInputDialog.show(function(newName)
        -- upvalues: (copy) self
        if newName ~= g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME) then
            g_gameSettings:setValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME, newName, true)
            self:updateOnlinePresenceName()
        end
    end, nil, defaultText, nil, nil, nil, confirmText, nil, text)
end
function MultiplayerScreen:onClickOpenBlocklist()
    UnBanDialog.show(nil, nil, true)
end
function MultiplayerScreen:getNumberOfItemsInSection(list, _)
    return Platform.showRentServerWebButton and list == self.listCoop and 3 or 2
end
function MultiplayerScreen:populateCellForItemInSection(list, _, index, cell)
    if list == self.listCoop then
        if index == 1 then
            cell:getAttribute("title"):setLocaKey("button_joinGame")
            cell:getAttribute("text"):setLocaKey("ui_coop_join_short")
            cell:getAttribute("icon"):setImageSlice(nil, "gui.icon_multiplayer_joinServer")
            return
        end
        if index == 2 then
            cell:getAttribute("title"):setLocaKey("button_createGame")
            cell:getAttribute("text"):setLocaKey("ui_coop_create_short")
            cell:getAttribute("icon"):setImageSlice(nil, "gui.icon_multiplayer_createServer")
            return
        end
        if index == 3 then
            cell:getAttribute("title"):setLocaKey("button_rentAServer")
            cell:getAttribute("text"):setLocaKey("ui_coop_dedicated_short")
            cell:getAttribute("icon"):setImageSlice(nil, "gui.icon_multiplayer_rentDedi")
        end
    end
end