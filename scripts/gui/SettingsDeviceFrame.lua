SettingsDeviceFrame = {}
local SettingsDeviceFrame_mt = Class(SettingsDeviceFrame, TabbedMenuFrameElement)
function SettingsDeviceFrame.register()
    local settingsDeviceFrame = SettingsDeviceFrame.new()
    g_gui:loadGui("dataS/gui/SettingsDeviceFrame.xml", "SettingsDeviceFrame", settingsDeviceFrame, true)
end
function SettingsDeviceFrame.new(target, custom_mt)
    -- upvalues: (copy) SettingsDeviceFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or SettingsDeviceFrame_mt)
    self.hasCustomMenuButtons = true
    self.stateBars = {}
    return self
end
function SettingsDeviceFrame.createFromExistingGui(gui, guiName)
    local newGui = SettingsDeviceFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    newGui.hasCustomMenuButtons = gui.hasCustomMenuButtons
    return newGui
end
function SettingsDeviceFrame:copyAttributes(src)
    SettingsDeviceFrame:superClass().copyAttributes(self, src)
    self.hasCustomMenuButtons = src.hasCustomMenuButtons
end
function SettingsDeviceFrame:initialize()
    self.sectionTemplate:unlinkElement()
    FocusManager:removeElement(self.sectionTemplate)
    self.deadzoneTemplate:unlinkElement()
    FocusManager:removeElement(self.deadzoneTemplate)
    self.sensitivityTemplate:unlinkElement()
    FocusManager:removeElement(self.sensitivityTemplate)
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
    self.switchButtonInfo = {
        ["inputAction"] = InputAction.MENU_EXTRA_1,
        ["text"] = g_i18n:getText(SettingsDeviceFrame.L10N_SYMBOL.SWITCH_DEVICE),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onSwitchDevice()
        end
    }
    self.applyButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACCEPT,
        ["text"] = g_i18n:getText(SettingsDeviceFrame.L10N_SYMBOL.BUTTON_APPLY),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onApplySettings()
        end
    }
    self:updateController()
end
function SettingsDeviceFrame:delete()
    if self.sectionTemplate ~= nil then
        self.sectionTemplate:delete()
    end
    if self.deadzoneTemplate ~= nil then
        self.deadzoneTemplate:delete()
    end
    if self.sensitivityTemplate ~= nil then
        self.sensitivityTemplate:delete()
    end
    SettingsDeviceFrame:superClass().delete(self)
end
function SettingsDeviceFrame:onFrameOpen()
    SettingsDeviceFrame:superClass().onFrameOpen(self)
    g_settingsModel:initDeviceSettings()
    g_settingsModel:refresh()
    self:updateView()
    g_inputBinding:setContextEventsActive("MENU", InputAction.MENU_AXIS_LEFT_RIGHT, false)
    g_inputBinding:setContextEventsActive("MENU", InputAction.MENU_AXIS_UP_DOWN, false)
    g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onAxisUpDown, false, true, false, true)
    g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onAxisLeftRight, true, true, true, true)
end
function SettingsDeviceFrame:onFrameClose()
    SettingsDeviceFrame:superClass().onFrameClose(self)
    g_inputBinding:setContextEventsActive("MENU", InputAction.MENU_AXIS_LEFT_RIGHT, true)
    g_inputBinding:setContextEventsActive("MENU", InputAction.MENU_AXIS_UP_DOWN, true)
    g_inputBinding:removeActionEventsByTarget(self)
end
function SettingsDeviceFrame.onAxisUpDown(_, _, value)
    g_gui:notifyControls(InputAction.MENU_AXIS_UP_DOWN, value)
end
function SettingsDeviceFrame.onAxisLeftRight(_, _, value)
    g_gui:notifyControls(InputAction.MENU_AXIS_LEFT_RIGHT, value)
end
function SettingsDeviceFrame:getMenuButtonInfo()
    local buttons = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
    if g_settingsModel:getNumDevices() > 1 then
        table.insert(buttons, self.switchButtonInfo)
    end
    if g_settingsModel:hasChanges() then
        table.insert(buttons, self.applyButtonInfo)
    end
    return buttons
end
function SettingsDeviceFrame:onApplySettings()
    g_settingsModel:saveChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)
    InfoDialog.show(g_i18n:getText(SettingsDeviceFrame.L10N_SYMBOL.SAVING_FINISHED), function()
        -- upvalues: (copy) self
        self:setMenuButtonInfoDirty()
    end, nil, DialogElement.TYPE_INFO)
end
function SettingsDeviceFrame:onSwitchDevice()
    g_settingsModel:nextDevice()
    self:updateView()
end
function SettingsDeviceFrame:update(dt)
    SettingsDeviceFrame:superClass().update(self, dt)
    if getNumOfGamepads() ~= self.numOfGamepads then
        self:updateController()
    end
    self:updateGamepadInputStates()
end
function SettingsDeviceFrame:updateGamepadInputStates()
    for _, barInfo in pairs(self.stateBars) do
        local deadzone = g_settingsModel:getCurrentDeviceDeadzoneValue(barInfo.axisIndex)
        local sensitivity = g_settingsModel:getCurrentDeviceSensitivityValue(barInfo.axisIndex)
        local value = g_inputBinding:getGamepadAxisValue(g_settingsModel.deviceSettings[g_settingsModel.currentDevice].device.internalId, barInfo.axisIndex, "", 0, deadzone) * sensitivity
        local bar = math.clamp(value, -1, 1)
        local bar = barInfo.element.elements[1]
        local boxSize = barInfo.element.absSize[1]
        bar:setSize((math.max(math.abs(bar) * boxSize * 0.5, 2 * g_pixelSizeX)))
        if bar < 0 then
            bar:setPosition((1 - math.abs(bar)) * boxSize * 0.5)
        else
            bar:setPosition(boxSize * 0.5)
        end
        barInfo.element:updateAbsolutePosition()
    end
end
function SettingsDeviceFrame:updateController()
    self.numOfGamepads = getNumOfGamepads()
    g_settingsModel:initDeviceSettings()
    self:updateView()
    self:setMenuButtonInfoDirty()
end
function SettingsDeviceFrame:updateView()
    local name = g_settingsModel:getCurrentDeviceName()
    if name == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT then
        name = g_i18n:getText("ui_mouse")
    elseif g_i18n:hasText(name) then
        name = g_i18n:getText(name)
    end
    self.titleElement:setText(string.format("%s: %s", g_i18n:getText("ui_deviceConfiguration"), name))
    local i = #self.layout.elements
    local isMouse = 1
    local sensitivityTemplate = -1
    for i = i, isMouse, sensitivityTemplate do
        self.layout.elements[i]:delete()
        self.layout.elements[i] = nil
    end
    self.stateBars = {}
    local isMouse = g_settingsModel:getIsDeviceMouse()
    local i
    if isMouse then
        (function(title, axis)
            -- upvalues: (copy) self
            local cell = self.sectionTemplate:clone(self.layout)
            cell:getDescendantByName("title"):setText(title)
            local box = cell:getDescendantByName("box")
            box:setVisible(axis ~= nil)
            if axis ~= nil then
                table.insert(self.stateBars, {
                    ["element"] = box,
                    ["axisIndex"] = axis
                })
            end
        end)(g_i18n:getText("ui_mouse"))
        i = self.sensitivityTemplate:clone(self.layout).elements[1]
        i:setTexts(g_settingsModel:getSensitivityTexts())
        i:setState(g_settingsModel:getMouseSensitivityValue())
        function i.onClickCallback(_, state)
            -- upvalues: (copy) self
            g_settingsModel:setMouseSensitivity(state)
            self:setMenuButtonInfoDirty()
        end
        if nil ~= nil then
            i = firstOptionElement
        end
    else
        i = firstOptionElement
    end
    local sensitivityTemplate = g_gameSettings:getValue(GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED)
    if sensitivityTemplate then
        sensitivityTemplate = isHeadTrackingAvailable()
    end
    local i = getIsKeyboardAvailable()
    if sensitivityTemplate then
        sensitivityTemplate = isMouse or not i
    end
    local optionElement
    if sensitivityTemplate then
        addSectionHeader(g_i18n:getText("setting_headTracking"))
        optionElement = self.sensitivityTemplate:clone(self.layout).elements[1]
        optionElement:setTexts(g_settingsModel:getHeadTrackingSensitivityTexts())
        optionElement:setState(g_settingsModel:getHeadTrackingSensitivityValue())
        function optionElement.onClickCallback(_, state)
            -- upvalues: (copy) self
            g_settingsModel:setHeadTrackingSensitivity(state)
            self:setMenuButtonInfoDirty()
        end
        if i ~= nil then
            optionElement = i
        end
    else
        optionElement = i
    end
    if not isMouse then
        local optionElement = g_settingsModel.deviceSettings[g_settingsModel.currentDevice].device.internalId
        local axis = 0
        for axis = axis, Input.MAX_NUM_AXES - 1 do
            local hasDeadzone = g_settingsModel:getDeviceHasAxisDeadzone(axis)
            local hasSensitiviy = g_settingsModel:getDeviceHasAxisSensitivity(axis)
            if hasDeadzone or hasSensitiviy then
                local label = getGamepadAxisLabel(axis, optionElement)
                local title = string.format(g_i18n:getText("setting_gamepadAxis"), axis + 1)
                if label ~= "" then
                end
                addSectionHeader(title, axis)
                local optionElement
                if hasDeadzone then
                    optionElement = self.deadzoneTemplate:clone(self.layout).elements[1]
                    optionElement:setTexts(g_settingsModel:getDeadzoneTexts())
                    optionElement:setState(g_settingsModel:getDeviceAxisDeadzoneValue(axis))
                    function optionElement.onClickCallback(_, state)
                        -- upvalues: (copy) axis, (copy) self
                        g_settingsModel:setDeviceDeadzoneValue(axis, state)
                        self:setMenuButtonInfoDirty()
                    end
                    if optionElement ~= nil then
                    end
                end
                if hasSensitiviy then
                    optionElement = self.sensitivityTemplate:clone(self.layout).elements[1]
                    optionElement:setTexts(g_settingsModel:getSensitivityTexts())
                    optionElement:setState(g_settingsModel:getDeviceAxisSensitivityValue(axis))
                    function optionElement.onClickCallback(_, state)
                        -- upvalues: (copy) axis, (copy) self
                        g_settingsModel:setDeviceSensitivityValue(axis, state)
                        self:setMenuButtonInfoDirty()
                    end
                    if optionElement ~= nil then
                    end
                end
            end
        end
    end
    self.layout:scrollTo(0, true)
    local sensitivityTemplate = true
    for axis, hasDeadzone in pairs(self.layout.elements) do
        if hasDeadzone.name == "sectionHeader" then
            sensitivityTemplate = true
        elseif hasDeadzone:getIsVisible() then
            hasDeadzone:setImageColor(nil, unpack(SettingsScreen.COLOR_ALTERNATING[sensitivityTemplate]))
            sensitivityTemplate = not sensitivityTemplate
        end
    end
    self.layout:invalidateLayout()
    if optionElement ~= nil then
        self.layout:scrollToMakeElementVisible(optionElement)
        FocusManager:setFocus(optionElement)
        optionElement.forceFocusScrollToTop = true
    end
end
SettingsDeviceFrame.L10N_SYMBOL = {
    ["BUTTON_APPLY"] = "button_apply",
    ["SWITCH_DEVICE"] = "ui_switchDevice",
    ["SAVING_FINISHED"] = "ui_savingFinished"
}