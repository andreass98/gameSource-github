ConnectToMasterServerScreen = {}
local ConnectToMasterServerScreen_mt = Class(ConnectToMasterServerScreen, ScreenElement)
function ConnectToMasterServerScreen.register()
    local connectToMasterServerScreen = ConnectToMasterServerScreen.new()
    g_gui:loadGui("dataS/gui/ConnectToMasterServerScreen.xml", "ConnectToMasterServerScreen", connectToMasterServerScreen)
    return connectToMasterServerScreen
end
function ConnectToMasterServerScreen.new(target, custom_mt)
    -- upvalues: (copy) ConnectToMasterServerScreen_mt
    local self = ScreenElement.new(target, custom_mt or ConnectToMasterServerScreen_mt)
    self.isBackAllowed = false
    return self
end
function ConnectToMasterServerScreen.createFromExistingGui(gui, guiName)
    local controller = gui:getController()
    local newGui = ConnectToMasterServerScreen.new()
    g_gui.guis[guiName]:delete()
    g_gui.guis[guiName].target:delete()
    newGui:setController(controller)
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    return newGui
end
function ConnectToMasterServerScreen:onOpen()
    ConnectToMasterServerScreen:superClass().onOpen(self)
    local text = self.mainBox
    text:setVisible(g_deepLinkingInfo ~= nil)
    if g_deepLinkingInfo == nil then
        MessageDialog.hide()
    else
        local text = g_i18n:getText("ui_connectingPleaseWait")
        MessageDialog.show(text, nil, nil, DialogElement.TYPE_LOADING)
    end
    g_masterServerConnection:setCallbackTarget(self)
end
function ConnectToMasterServerScreen:onClickCancel()
    ConnectToMasterServerScreen:superClass().onClickCancel(self)
    ConnectToMasterServerScreen.goBackCleanup()
    g_startMissionInfo.canStart = false
    if g_startMissionInfo.createGame then
        self:changeScreen(self.prevScreenClass or CreateGameScreen)
    else
        self:changeScreen(self.prevScreenClass or MultiplayerScreen)
    end
end
function ConnectToMasterServerScreen:setNextScreenClass(nextScreenClass)
    self.nextScreenClass = nextScreenClass
end
function ConnectToMasterServerScreen:setPrevScreenClass(prevScreenClass)
    self.prevScreenClass = prevScreenClass
end
function ConnectToMasterServerScreen:connectToFront()
    g_masterServerConnection:connectToMasterServerFront()
end
function ConnectToMasterServerScreen.connectToBack(_, index)
    g_masterServerConnection:disconnectFromMasterServer()
    g_masterServerConnection:connectToMasterServer(index)
end
function ConnectToMasterServerScreen:onMasterServerListStart(numMasterServers)
    self.numMasterServers = numMasterServers
end
function ConnectToMasterServerScreen:onMasterServerList(name, id) end
function ConnectToMasterServerScreen:onMasterServerListEnd()
    if self.numMasterServers == 1 then
        self:connectToBack(0)
    end
end
function ConnectToMasterServerScreen:onMasterServerConnectionFailed(reason)
    self.mainBox:setVisible(false)
    g_startMissionInfo.canStart = false
    ConnectToMasterServerScreen.goBackCleanup()
    ConnectionFailedDialog.showMasterServerConnectionFailedReason(reason, ClassUtil.getClassName(self.prevScreenClass))
end
function ConnectToMasterServerScreen:onMasterServerConnectionReady()
    g_gui:changeScreen(nil, self.nextScreenClass, self.prevScreenClass).target:onMasterServerConnectionReady()
end
function ConnectToMasterServerScreen.goBackCleanup()
    g_asyncTaskManager:flushAllTasks()
    saveReadSavegameFinish("", ConnectToMasterServerScreen)
    g_deepLinkingInfo = nil
    g_masterServerConnection:disconnectFromMasterServer()
    g_mpLoadingScreen:unloadGameRelatedData()
    if g_client ~= nil then
        g_client:delete()
        g_client = nil
    end
    if g_server == nil then
        g_connectionManager:shutdownAll()
    else
        g_server:delete()
        g_server = nil
    end
end