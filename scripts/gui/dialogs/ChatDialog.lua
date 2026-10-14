ChatDialog = {}
ChatDialog.SCROLL_DELAY = 500
local ChatDialog_mt = Class(ChatDialog, ScreenElement)
function ChatDialog.register()
    local chatDialog = ChatDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/ChatDialog.xml", "ChatDialog", chatDialog)
end
function ChatDialog.new(target, custom_mt)
    -- upvalues: (copy) ChatDialog_mt
    local self = ScreenElement.new(target, custom_mt or ChatDialog_mt)
    self.lastScrollTime = 0
    return self
end
function ChatDialog:onGuiSetupFinished()
    ChatDialog:superClass().onGuiSetupFinished(self)
    self.defaultPosY = self.textElement.position[2]
end
function ChatDialog:onOpen(_)
    ChatDialog:superClass().onOpen(self)
    g_currentMission.isPlayerFrozen = true
    self.textElement:openIme()
    self.textElement:setForcePressed(true)
    self.textElement:setText("")
    local newPosY = self.defaultPosY * g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
    self.textElement:setPosition(nil, (math.max(self.defaultPosY, newPosY)))
    g_inputBinding:registerActionEvent(InputAction.MENU_AXIS_UP_DOWN, self, self.onMenuAxisUpDown, false, true, true, true)
end
function ChatDialog:onClose(_)
    ChatDialog:superClass().onClose(self)
    if g_currentMission ~= nil then
        g_currentMission:scrollChatMessages(-9999999)
        g_currentMission.isPlayerFrozen = false
    end
    self.textElement:abortIme()
    self.textElement:setForcePressed(false)
end
function ChatDialog:onCreateTextInput(element)
    self.textElement = element
end
function ChatDialog:onSendClick()
    if self.textElement.text ~= "" then
        local farmId = g_currentMission:getFarmId()
        if getAllowTextCommunication() then
            if g_server == nil then
                g_client:getServerConnection():sendEvent(ChatEvent.new(self.textElement.text, g_currentMission.playerNickname, farmId, g_currentMission.playerUserId))
            else
                g_server:broadcastEvent(ChatEvent.new(self.textElement.text, nickname, farmId, g_currentMission.playerUserId))
            end
            g_currentMission:addChatMessage(nickname, self.textElement.text, farmId, g_currentMission.playerUserId)
        end
        self.textElement:setText("")
    end
    g_gui:showGui("")
end
function ChatDialog:onMenuAxisUpDown(_, inputValue)
    local delta = 0
    local delta = inputValue > 0 and 1 or (inputValue < 0 and -1 or delta)
    if delta ~= 0 and self.lastScrollTime + ChatDialog.SCROLL_DELAY <= g_time then
        g_currentMission:scrollChatMessages(delta)
        self.lastScrollTime = g_time
    end
end
function ChatDialog:update(dt)
    ChatDialog:superClass().update(self, dt)
    g_currentMission.hud:setChatDisplayVisible(true)
end
function ChatDialog:onEnterPressed()
    self:onSendClick()
end
function ChatDialog:onEscPressed()
    self.textElement:setText("")
    g_gui:showGui("")
end