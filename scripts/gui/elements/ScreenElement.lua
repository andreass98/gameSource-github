ScreenElement = {}
local ScreenElement_mt = Class(ScreenElement, FrameElement)
function ScreenElement.new(target, custom_mt)
    -- upvalues: (copy) ScreenElement_mt
    local self = FrameElement.new(target, custom_mt or ScreenElement_mt)
    self.isBackAllowed = true
    self.handleCursorVisibility = true
    self.returnScreenClass = nil
    self.isOpen = false
    self.lastMouseCursorState = false
    self.isInitialized = false
    self.nextClickSoundMuted = false
    return self
end
function ScreenElement:onOpen()
    if not self.isInitialized then
        self:initializeScreen()
    end
    self.lastMouseCursorState = g_inputBinding:getShowMouseCursor()
    g_inputBinding:setShowMouseCursor(true)
    self.isOpen = true
end
function ScreenElement:initializeScreen()
    self.isInitialized = true
    if self.pageSelector ~= nil and self.pageSelector.disableButtonSounds ~= nil then
        self.pageSelector:disableButtonSounds()
    end
end
function ScreenElement:onClose()
    if self.handleCursorVisibility then
        g_inputBinding:setShowMouseCursor(self.lastMouseCursorState)
    end
    self.isOpen = false
end
function ScreenElement:onClickOk()
    return true
end
function ScreenElement:onClickActivate()
    return true
end
function ScreenElement:onClickCancel()
    return true
end
function ScreenElement:onClickMenuExtra1()
    return true
end
function ScreenElement:onClickMenuExtra2()
    return true
end
function ScreenElement:onClickMenu()
    return true
end
function ScreenElement:onClickShop()
    return true
end
function ScreenElement:onPagePrevious()
    self.pageSelector:inputLeft(true, nil, true)
end
function ScreenElement:onPageNext()
    self.pageSelector:inputRight(true, nil, true)
end
function ScreenElement:onClickBack(forceBack, _)
    local eventUnused = true
    if (self.isBackAllowed or forceBack) and self.returnScreenClass ~= nil then
        self:changeScreen(self.returnScreenClass)
        eventUnused = false
    end
    return eventUnused
end
function ScreenElement:onBackAction()
    return self:onClickBack()
end
function ScreenElement:invalidateScreen() end
function ScreenElement.callButtonsWithAction(list, action)
    local i = 1
    for i = i, #list do
        local element = list[i]
        if element:isa(ButtonElement) and (element.isTriggerableByGlobalAction and (element:getIsActive() and element.inputActionName == action)) then
            element:sendAction()
            return true
        end
        if ScreenElement.callButtonsWithAction(element.elements, action) then
            return true
        end
    end
    return false
end
function ScreenElement:inputEvent(action, value, eventUsed)
    local focusElement = ScreenElement:superClass().inputEvent(self, action, value, eventUsed)
    if self.inputDisableTime <= 0 then
        if self.pageSelector ~= nil and (action == InputAction.MENU_PAGE_PREV or action == InputAction.MENU_PAGE_NEXT) then
            if action == InputAction.MENU_PAGE_PREV then
                self:onPagePrevious()
            elseif action == InputAction.MENU_PAGE_NEXT then
                self:onPageNext()
            end
            focusElement = true
        end
        if not focusElement then
            local focusElement = FocusManager:getFocusedElement()
            if focusElement ~= nil and g_inputBinding.nameActions[action]:getNumActiveBindings() > 0 then
                if action == InputAction.MENU_LIST_PAGE_START then
                    if focusElement.scrollToStart ~= nil then
                        focusElement:scrollToStart()
                    end
                elseif action == InputAction.MENU_LIST_PAGE_END and focusElement.scrollToEnd ~= nil then
                    focusElement:scrollToEnd()
                end
                if action == InputAction.MENU_LIST_PAGE_PREV then
                    if focusElement.scrollToPrevPage ~= nil then
                        focusElement:scrollToPrevPage()
                    end
                elseif action == InputAction.MENU_LIST_PAGE_NEXT and focusElement.scrollToNextPage ~= nil then
                    focusElement:scrollToNextPage()
                end
                if action == InputAction.MENU_LIST_PAGE_START_GAMEPAD then
                    if focusElement.scrollToStartGamepad ~= nil then
                        focusElement:scrollToStartGamepad()
                    end
                elseif action == InputAction.MENU_LIST_PAGE_END_GAMEPAD and focusElement.scrollToEndGamepad ~= nil then
                    focusElement:scrollToEndGamepad()
                end
            end
        end
        focusElement = focusElement or ScreenElement.callButtonsWithAction(self.elements, action)
    end
    return focusElement
end
function ScreenElement:inputReleaseEvent(action, value, eventUsed)
    eventUsed = ScreenElement:superClass().inputReleaseEvent(self, action, value, eventUsed)
    if self.pageSelector == nil or action ~= InputAction.MENU_PAGE_PREV and action ~= InputAction.MENU_PAGE_NEXT then
        return eventUsed
    end
    self.pageSelector.leftDelayTime = 0
    self.pageSelector.rightDelayTime = 0
    return true
end
function ScreenElement:setReturnScreenClass(returnScreenClass)
    self.returnScreenClass = returnScreenClass
end
function ScreenElement:getIsOpen()
    return self.isOpen
end
function ScreenElement:canReceiveFocus()
    if not self.visible then
        return false
    end
    local i = 1
    for i = i, #self.elements do
        if not self.elements[i]:canReceiveFocus() then
            return false
        end
    end
    return true
end
function ScreenElement:setNextScreenClickSoundMuted(value)
    self.nextClickSoundMuted = value == nil and true or value
end