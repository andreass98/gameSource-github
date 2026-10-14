ConversationDialog = {}
local ConversationDialog_mt = Class(ConversationDialog, MessageDialog)
function ConversationDialog.register()
    local conversationDialog = ConversationDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/ConversationDialog.xml", "ConversationDialog", conversationDialog)
    ConversationDialog.INSTANCE = conversationDialog
end
function ConversationDialog.show(npcName, text, options, duration, callback, target, callbackArgs)
    if ConversationDialog.INSTANCE ~= nil then
        local dialog = ConversationDialog.INSTANCE
        dialog:setVisible(true)
        dialog:setNpcName(npcName)
        dialog:setText(text)
        dialog:setOptions(options)
        if duration ~= nil and #options > 0 then
            duration = 0
            Logging.devWarning("Not allowed to have a duration of options are available")
        end
        dialog:setDuration(duration)
        dialog:setCallback(callback, target, callbackArgs)
        if not dialog.isOpen then
            g_gui:showDialog("ConversationDialog")
        end
    end
end
function ConversationDialog.hide()
    if ConversationDialog.INSTANCE ~= nil then
        ConversationDialog.INSTANCE:close()
    end
end
function ConversationDialog.new(target, custom_mt)
    -- upvalues: (copy) ConversationDialog_mt
    local self = MessageDialog.new(target, custom_mt or ConversationDialog_mt)
    self.buttonAction = InputAction.MENU_ACCEPT
    self.isBackAllowed = false
    self.inputDelay = 250
    self.duration = math.huge
    self.disableOpenSound = true
    self.isOpen = false
    self.buttonOptionMapping = {}
    return self
end
function ConversationDialog:delete()
    self.optionButtonTemplate:delete()
    ConversationDialog:superClass().delete(self)
end
function ConversationDialog.createFromExistingGui(gui, _)
    ConversationDialog.register()
    ConversationDialog.show(gui.npcName, gui.text, gui.options, gui.callbackFunc, gui.target, gui.args)
end
function ConversationDialog:onGuiSetupFinished()
    ConversationDialog:superClass().onGuiSetupFinished(self)
    self.backgroundHeightOffset = self.optionBoxBackground.size[2] - self.optionsBox.size[2]
    self.boxOffset = self.box.size[2] - self.optionBoxBackground.size[2] - self.textBox.size[2]
    local button = self.optionButtonTemplate:getDescendantByName("text")
    self.borderHeight = self.optionButtonTemplate.size[2] - button.size[2]
    self.optionButtonTemplate:unlinkElement()
    FocusManager:removeElement(self.optionButtonTemplate)
end
function ConversationDialog:update(dt)
    ConversationDialog:superClass().update(self, dt)
    if self.duration ~= nil then
        self.duration = self.duration - dt
        if self.duration < 0 then
            self:onClickOption(false, 0)
            self.duration = nil
        end
    end
end
function ConversationDialog:onOpen()
    ConversationDialog:superClass().onOpen(self)
    if self.options == nil or #self.options == 0 then
        local _, eventId = g_inputBinding:registerActionEvent(InputAction.CONVERSATION_SKIP, self, self.onSkip, false, true, false, true)
        self.skipEventId = eventId
    end
    self.inputDelay = self.time + 250
    self.isOpen = true
end
function ConversationDialog:onClose()
    ConversationDialog:superClass().onClose(self)
    self.duration = nil
    self.isOpen = false
    if self.skipEventId ~= nil then
        g_inputBinding:removeActionEvent(self.skipEventId)
        self.skipEventId = nil
    end
end
function ConversationDialog:setText(text)
    local height = self.textBox
    height:setVisible(text ~= nil)
    if text ~= nil then
        self.textElement:setText(text)
        self.text = text
        local height = self.textElement:getTextHeight()
        self.textBox:setSize(nil, height + self.textBox.margin[2] + self.textBox.margin[2])
    end
    self:invalidateOptionsBox()
end
function ConversationDialog:setNpcName(npcName)
    self.npcNameElement:setText(npcName .. ": ")
    self.npcName = npcName
    local identation = self.npcNameElement:getTextWidth()
    self.textElement:setFirstLineIndentation(identation + self.textElement.margin[3])
end
function ConversationDialog:setOptions(options)
    self.options = options
    local i = #self.optionsBox.elements
    local firstButton = 1
    for i = i, firstButton, -1 do
        self.optionsBox.elements[i]:delete()
    end
    if self.options ~= nil then
        local firstButton = nil
        for k, option in ipairs(self.options) do
            local background = self.optionButtonTemplate:clone(self.optionsBox)
            local button = background:getDescendantByName("text")
            button:setText(option)
            background:setSize(nil, button:getTextHeight() + self.borderHeight)
            local k
            function button.onClickCallback()
                -- upvalues: (copy) self, (copy) k
                self:onClickOption(false, k)
            end
            function button.onFocusCallback()
                -- upvalues: (copy) background
                background.focused = true
            end
            function button.onLeaveCallback()
                -- upvalues: (copy) background
                background.focused = false
            end
            function button.onHighlightCallback()
                -- upvalues: (copy) background
                background.highlighted = true
            end
            function button.onHighlightRemoveCallback()
                -- upvalues: (copy) background
                background.highlighted = false
            end
            if firstButton == nil then
                firstButton = button
            end
        end
        self:invalidateOptionsBox()
        if firstButton ~= nil then
            FocusManager:setFocus(firstButton)
            FocusManager:setHighlight(firstButton)
        end
    end
end
function ConversationDialog:invalidateOptionsBox()
    local sizeY = self.optionsBox:invalidateLayout()
    local boxSizeY = self.textBox.size[2]
    if self.options ~= nil and #self.options > 0 then
        self.optionsBox:setSize(nil, sizeY)
        self.optionBoxBackground:setSize(nil, sizeY + self.optionsBox.margin[2] + self.optionsBox.margin[4] + self.backgroundHeightOffset)
    end
    self.optionBoxBackground:setVisible(self.options ~= nil and #self.options > 0)
    self.box:setSize(nil, boxSizeY)
end
function ConversationDialog:onClickOption(canceled, optionIndex)
    if self.inputDelay >= self.time then
        return true
    end
    self:setVisible(false)
    if self.callbackFunc ~= nil then
        if self.callbackTarget == nil then
            self.callbackFunc(canceled, optionIndex, self.callbackArgs)
        else
            self.callbackFunc(self.callbackTarget, canceled, optionIndex, self.callbackArgs)
        end
        self.callbackFunc = nil
        self.callbackTarget = nil
        self.callbackArgs = nil
    end
    return false
end
function ConversationDialog:inputEvent(action, value, eventUsed)
    eventUsed = ConversationDialog:superClass().inputEvent(self, action, value, eventUsed)
    if self:getIsVisible() and not eventUsed then
        if action == InputAction.MENU_BACK then
            self:onClickBack()
            return eventUsed
        end
        if action == InputAction.MENU_ACCEPT and (self.options == nil or #self.options == 0) then
            self:onClickOk()
        end
    end
    return eventUsed
end
function ConversationDialog:setDuration(duration)
    self.duration = duration
end
function ConversationDialog:setCallback(callbackFunc, callbackTarget, callbackArgs)
    self.callbackFunc = callbackFunc
    self.callbackTarget = callbackTarget
    self.callbackArgs = callbackArgs
end
function ConversationDialog:onClickOk()
    self:onClickOption(false, 0)
end
function ConversationDialog:onSkip()
    if self.options == nil or #self.options == 0 then
        self:onClickOption(false, 0)
    end
end
function ConversationDialog:onClickBack()
    self:onClickOption(true, nil)
end