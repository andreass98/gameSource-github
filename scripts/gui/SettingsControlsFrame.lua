SettingsControlsFrame = {}
local SettingsControlsFrame_mt = Class(SettingsControlsFrame, TabbedMenuFrameElement)
local function NO_CALLBACK() end
function SettingsControlsFrame.register()
    local settingsControlsFrame = SettingsControlsFrame.new()
    g_gui:loadGui("dataS/gui/SettingsControlsFrame.xml", "SettingsControlsFrame", settingsControlsFrame, true)
end
function SettingsControlsFrame.new(target, custom_mt)
    -- upvalues: (copy) SettingsControlsFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or SettingsControlsFrame_mt)
    self.controlsController = nil
    self.controlsData = {}
    self.controlsMessageText = ""
    self.userChangedInput = false
    self.currentFocusCell = nil
    self.dataRowOffset = 0
    self.hasCustomMenuButtons = true
    self.backButtonInfo = {}
    self.saveButtonInfo = {}
    self.resetButtonInfo = {}
    return self
end
function SettingsControlsFrame.createFromExistingGui(gui, guiName)
    local newGui = SettingsControlsFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function SettingsControlsFrame:initialize(controlsController)
    self.controlsController = controlsController
    self.controlsController:setMessageCallback(function(messageId, additionalText, addLine)
        -- upvalues: (copy) self
        self:setControlsMessage(messageId, additionalText, addLine)
    end)
    self.controlsController:setInputDoneCallback(function(madeChange)
        -- upvalues: (copy) self
        self:notifyInputGatheringFinished(madeChange)
    end)
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
    self.saveButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACTIVATE,
        ["text"] = g_i18n:getText(SettingsControlsFrame.L10N_SYMBOL.BUTTON_SAVE),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:saveChanges()
        end,
        ["showWhenPaused"] = true
    }
    self.resetButtonInfo = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = g_i18n:getText(SettingsControlsFrame.L10N_SYMBOL.BUTTON_DEFAULTS),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onClickDefaults()
        end,
        ["showWhenPaused"] = true
    }
    function self.controlsList.queueReusableCell(instance, cell, _)
        local isFocused = cell:getAttribute("actionButton1") ~= nil and cell:getAttribute("actionButton1"):getIsFocused() or cell:getAttribute("actionButton2") ~= nil and cell:getAttribute("actionButton2"):getIsFocused()
        if not isFocused then
            isFocused = false
            if cell:getAttribute("actionButton3") ~= nil then
                isFocused = cell:getAttribute("actionButton3"):getIsFocused()
            end
        end
        if not isFocused and instance.sections[cell.sectionIndex] ~= nil then
            instance.sections[cell.sectionIndex].cells[cell.indexInSection] = nil
        end
        if not isFocused then
            cell.sectionIndex = nil
            cell.indexInSection = nil
            local cache = instance.cellCache[cell.reusableName]
            cache[#cache + 1] = cell
            FocusManager:removeElement(cell)
            cell:unlinkElement()
        end
    end
end
function SettingsControlsFrame:onFrameOpen()
    SettingsControlsFrame:superClass().onFrameOpen(self)
    self.numTotalDevices = 3 + g_inputBinding.numActiveGamepads
    self.dataRowOffset = 0
    self:assignDeviceTableData()
    self.controlsList:makeCellVisible(1, 1)
    self.nextFocusSection = 1
    self.nextFocusCell = 1
    self.nextFocusedButtonName = "actionButton1"
    self.controlsMessageText = ""
    self:updateMenuButtons()
    g_messageCenter:subscribe(MessageType.INPUT_DEVICES_CHANGED, self.onControllerChanged, self)
    _, self.menuAcceptUpEventId = g_inputBinding:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onMenuAcceptUp, true, false, false, true)
    g_inputBinding:resetBindingInputStates()
end
function SettingsControlsFrame:requestClose(callback)
    if self.userChangedInput then
        SettingsControlsFrame:superClass().requestClose(self, callback)
        YesNoDialog.show(self.onYesNoSaveControls, self, g_i18n:getText(SettingsControlsFrame.L10N_SYMBOL.SAVE_CHANGES_PROMPT))
    end
    return not self.userChangedInput
end
function SettingsControlsFrame:onFrameClose()
    g_messageCenter:unsubscribe(MessageType.INPUT_DEVICES_CHANGED, self)
    g_inputBinding:removeActionEvent(self.menuAcceptUpEventId)
    SettingsControlsFrame:superClass().onFrameClose(self)
end
function SettingsControlsFrame:update(dt)
    SettingsControlsFrame:superClass().update(self, dt)
    if self.nextFocusSection ~= nil then
        local newCell = self.controlsList:getElementAtSectionIndex(self.nextFocusSection, self.nextFocusCell)
        if newCell ~= nil then
            local newButton = newCell:getAttribute(self.nextFocusedButtonName)
            FocusManager:setFocus(newButton)
            self.nextFocusSection = nil
            self.nextFocusCell = nil
        end
    end
end
function SettingsControlsFrame:onYesNoSaveControls(yes)
    -- upvalues: (copy) NO_CALLBACK
    if yes then
        self:saveChanges()
    else
        self:revertChanges()
        self.requestCloseCallback()
        self.requestCloseCallback = NO_CALLBACK
    end
end
function SettingsControlsFrame:revertChanges()
    self.controlsController:discardChanges()
    self.userChangedInput = false
    self:updateMenuButtons()
end
function SettingsControlsFrame:saveChanges()
    -- upvalues: (copy) NO_CALLBACK
    if self.userChangedInput then
        self.controlsController:saveChanges()
        self.userChangedInput = false
        self:updateMenuButtons()
        InfoDialog.show(g_i18n:getText(SettingsControlsFrame.L10N_SYMBOL.SAVED_CHANGES_INFO), self.requestCloseCallback)
        self.requestCloseCallback = NO_CALLBACK
    end
end
function SettingsControlsFrame:updateMenuButtons()
    if self.userChangedInput then
        self.menuButtonInfo = {
            self.backButtonInfo,
            self.nextPageButtonInfo,
            self.prevPageButtonInfo,
            self.saveButtonInfo,
            self.resetButtonInfo
        }
    else
        self.menuButtonInfo = {
            self.backButtonInfo,
            self.nextPageButtonInfo,
            self.prevPageButtonInfo,
            self.resetButtonInfo
        }
    end
    self.menuButtonInfo = self.menuButtonInfo
    self:setMenuButtonInfoDirty()
end
function SettingsControlsFrame:assignDeviceTableData()
    self.controlsController:loadBindings()
    self.controlsData = self.controlsController:getDeviceCategoryActionBindings()
    self.controlsList:reloadData()
    self:updateListHeaderNames()
end
function SettingsControlsFrame:updateListHeaderNames()
    local gamepads = g_inputBinding:getGamepadDevices()
    local index = 1 + self.dataRowOffset
    local headerName
    if index <= 3 then
        headerName = g_i18n:getText(SettingsControlsFrame.DEVICES[index].name)
    else
        headerName = gamepads[index - 3].name
        if g_i18n:hasText(headerName) then
            headerName = g_i18n:getText(headerName)
        elseif InputDevice.NAMES[headerName] ~= nil then
        end
    end
    self.headerText1:setText(headerName)
    local index = index + 1
    local headerName
    if index <= 3 then
        headerName = g_i18n:getText(SettingsControlsFrame.DEVICES[index].name)
    else
        headerName = gamepads[index - 3].name
        if g_i18n:hasText(headerName) then
            headerName = g_i18n:getText(headerName)
        elseif InputDevice.NAMES[headerName] ~= nil then
        end
    end
    self.headerText2:setText(headerName)
    local index = index + 1
    local headerName
    if index <= 3 then
        headerName = g_i18n:getText(SettingsControlsFrame.DEVICES[index].name)
    else
        headerName = gamepads[index - 3].name
        if g_i18n:hasText(headerName) then
            headerName = g_i18n:getText(headerName)
        elseif InputDevice.NAMES[headerName] ~= nil then
        end
    end
    self.headerText3:setText(headerName)
    self.buttonPrevRow:setVisible(self.dataRowOffset > 0)
    self.buttonNextRow:setVisible(self.dataRowOffset < self.numTotalDevices - 3)
    self.gamepads = gamepads
end
function SettingsControlsFrame:setControlsMessage(messageId, additionalText, addLine)
    if messageId and messageId ~= ControlsController.MESSAGE_CLEAR then
        local text = ""
        if addLine then
            text = self.controlsMessageText .. "\n"
        end
        local uiSymbol = SettingsControlsFrame.CONTROLS_UI_STRINGS[messageId]
        local text
        if uiSymbol then
            text = text .. g_i18n:getText(uiSymbol)
            if additionalText and #additionalText > 0 then
            end
        else
            local formatString = g_i18n:getText(SettingsControlsFrame.L10N_TEMPLATE_SYMBOL[messageId])
            if additionalText and #additionalText > 0 then
                text = text .. string.format(formatString, unpack(additionalText))
            end
        end
        self.controlsMessageText = text
        InfoDialog.show(text, nil, nil, SettingsControlsFrame.CONFLICT_MESSAGES[messageId] == true and DialogElement.TYPE_WARNING or DialogElement.TYPE_INFO)
    else
        self.controlsMessageText = ""
    end
end
function SettingsControlsFrame:notifyInputGatheringFinished(madeChange)
    self:setSoundSuppressed(true)
    g_gui:closeAllDialogs()
    FocusManager:setGui(self.name)
    self:setSoundSuppressed(false)
    if madeChange then
        self:assignDeviceTableData()
        self.userChangedInput = true
        self:updateMenuButtons()
    end
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
end
function SettingsControlsFrame.showInputPrompt(_, deviceCategory, bindingId, actionData)
    local promptStringSymbol
    if deviceCategory == InputDevice.CATEGORY.KEYBOARD_MOUSE then
        if bindingId == ControlsController.BINDING_PRIMARY or bindingId == ControlsController.BINDING_SECONDARY then
            promptStringSymbol = SettingsControlsFrame.L10N_SYMBOL.KEY_PROMPT
        else
            promptStringSymbol = SettingsControlsFrame.L10N_SYMBOL.MOUSE_PROMPT
        end
    else
        promptStringSymbol = SettingsControlsFrame.L10N_SYMBOL.BUTTON_PROMPT
    end
    local promptTemplate = g_i18n:getText(promptStringSymbol)
    local text = string.format(promptTemplate, actionData.displayName) .. "\n" .. g_i18n:getText(SettingsControlsFrame.CONTROLS_UI_STRINGS[ControlsController.MESSAGE_PROMPT_CANCEL_DELETE])
    local ensureInNeutral = g_i18n:getText(SettingsControlsFrame.CONTROLS_UI_STRINGS[ControlsController.MESSAGE_ENSURE_IN_NEUTRAL])
    if utf8Strlen(ensureInNeutral) > 1 then
    end
    MessageDialog.show(text, nil, nil, DialogElement.TYPE_KEY)
end
SettingsControlsFrame.KB_MOUSE_BOUND_CONTROLS = {
    ["ACTION"] = "action",
    ["KEY_1"] = "key1",
    ["KEY_2"] = "key2",
    ["MOUSE_BUTTON"] = "mouseButton"
}
SettingsControlsFrame.GAMEPAD_BOUND_CONTROLS = {
    ["ACTION"] = "gamepadAction",
    ["BUTTON_1"] = "gamepadButton1",
    ["BUTTON_2"] = "gamepadButton2"
}
function SettingsControlsFrame:getNumberOfSections(_)
    return #self.controlsData
end
function SettingsControlsFrame:getTitleForSectionHeader(_, section)
    return g_i18n:convertText(self.controlsData[section].name)
end
function SettingsControlsFrame:getNumberOfItemsInSection(_, section)
    return #self.controlsData[section]
end
function SettingsControlsFrame:populateCellForItemInSection(list, section, index, cell)
    local actionBinding = self.controlsData[section][index]
    cell:getAttribute("actionName"):setText(actionBinding.displayName)
    local i = 1
    for i = i, 3 do
        local dataIndex = i + self.dataRowOffset
        local binding = nil
        if dataIndex - 3 > 0 then
            for id, columnBinding in pairs(actionBinding.columnBindings) do
                if columnBinding.deviceId == self.gamepads[dataIndex - 3].deviceId then
                    binding = columnBinding
                    dataIndex = id
                    break
                end
            end
        else
            binding = actionBinding.columnBindings[dataIndex]
        end
        local deviceId = cell:getAttribute("actionGlyph" .. i)
        local button = cell:getAttribute("actionButton" .. i)
        deviceId:setActions({ actionBinding.action.name }, nil, nil, nil, binding)
        local hasIcon = false
        if deviceId.glyphElement ~= nil then
            for _, keyName in pairs(deviceId.glyphElement.actionNames) do
                if deviceId.glyphElement.keyNames[keyName] ~= nil and deviceId.glyphElement.keyNames[keyName][1] ~= "" then
                    hasIcon = true
                end
            end
        end
        local columnBinding
        if binding == nil then
            columnBinding = false
        else
            columnBinding = hasIcon
        end
        deviceId:setVisible(columnBinding)
        if hasIcon then
            button:setText("")
        else
            button:setText(actionBinding.columnTexts[dataIndex])
        end
        local oldFocusEnterFunc = deviceId.onFocusEnter
        function deviceId.onFocusEnter()
            -- upvalues: (copy) oldFocusEnterFunc, (copy) deviceId
            oldFocusEnterFunc(deviceId)
            deviceId.glyphElement:setButtonGlyphColor(SettingsControlsFrame.COLOR.BLACK)
        end
        local id = deviceId.onFocusLeave
        function deviceId.onFocusLeave(element)
            -- upvalues: (copy) id, (copy) deviceId
            id(deviceId)
            if deviceId.glyphElement ~= nil then
                deviceId.glyphElement:setButtonGlyphColor(SettingsControlsFrame.COLOR.GREEN)
            end
        end
        local columnBinding = button.onFocusEnter
        function button.onFocusEnter()
            -- upvalues: (copy) columnBinding, (copy) button, (copy) list, (copy) cell, (copy) self, (copy) i
            columnBinding(button)
            list:makeCellVisible(cell.sectionIndex, cell.indexInSection)
            self.currentFocusCell = cell
            self.currentFocusSection = cell.sectionIndex
            self.currentFocusIndex = cell.indexInSection
            self["headerText" .. 1]:setSelected(i == 1)
            self["headerText" .. 2]:setSelected(i == 2)
            self["headerText" .. 3]:setSelected(i == 3)
        end
        local dataIndex
        function button.shouldFocusChange(_, direction)
            -- upvalues: (copy) cell, (copy) self, (copy) dataIndex, (copy) list, (copy) i
            if g_gui:getIsDialogVisible() then
                return false
            end
            local section = cell.sectionIndex
            local index = cell.indexInSection
            if section == nil then
                section = self.currentFocusSection
                index = self.currentFocusIndex
            end
            if direction == FocusManager.LEFT then
                if dataIndex == 1 then
                    return false
                end
                if dataIndex == 1 + self.dataRowOffset then
                    self.dataRowOffset = self.dataRowOffset - 1
                    self.controlsList:reloadData()
                    self:updateListHeaderNames()
                    return false
                end
            elseif direction == FocusManager.RIGHT then
                if dataIndex == self.numTotalDevices then
                    return false
                end
                if dataIndex == 3 + self.dataRowOffset then
                    self.dataRowOffset = self.dataRowOffset + 1
                    self.controlsList:reloadData()
                    self:updateListHeaderNames()
                    return false
                end
            else
                if direction == FocusManager.TOP then
                    local newIndex = index - 1
                    if newIndex == 0 then
                        section = section - 1
                        if section == 0 then
                            return false
                        end
                        newIndex = list.sections[section].numItems
                    end
                    list:makeCellVisible(section, newIndex)
                    self.nextFocusSection = section
                    self.nextFocusCell = newIndex
                    self.nextFocusedButtonName = "actionButton" .. i
                    return false
                end
                if direction == FocusManager.BOTTOM then
                    local newIndex = index + 1
                    if list.sections[section].numItems < newIndex then
                        section = section + 1
                        if #list.sections < section then
                            return false
                        end
                        newIndex = 1
                    end
                    list:makeCellVisible(section, newIndex)
                    self.nextFocusSection = section
                    self.nextFocusCell = newIndex
                    self.nextFocusedButtonName = "actionButton" .. i
                    return false
                end
            end
            return true
        end
    end
    cell.actionBinding = actionBinding
end
function SettingsControlsFrame.inputEvent(_, action, _, eventUsed)
    return action == InputAction.MENU_ACCEPT and true or eventUsed
end
function SettingsControlsFrame:onMenuAcceptUp(_, _, _)
    local rowIndex = 1
    if self.currentFocusCell ~= nil then
        local focusedButton = FocusManager:getFocusedElement()
    end
    local focusedButton = rowIndex + self.dataRowOffset
    local deviceInfoIndex = math.min(focusedButton, 4)
    self:onInputClicked(SettingsControlsFrame.DEVICES[deviceInfoIndex].category, SettingsControlsFrame.DEVICES[deviceInfoIndex].binding, self.currentFocusCell.actionBinding, focusedButton)
    return true
end
function SettingsControlsFrame:onInputClicked(deviceCategory, bindingId, actionData, bindingControlsRowIndex)
    if self.controlsController:onClickInput(deviceCategory, bindingId, actionData, bindingControlsRowIndex) then
        self:showInputPrompt(deviceCategory, bindingId, actionData)
    end
end
function SettingsControlsFrame:onClickDefaults()
    YesNoDialog.show(function(dialogAccepted)
        -- upvalues: (copy) self
        if dialogAccepted then
            self.controlsController:loadDefaultSettings()
            self.userChangedInput = false
            self:assignDeviceTableData()
            self:updateMenuButtons()
            InfoDialog.show(g_i18n:getText(SettingsControlsFrame.L10N_SYMBOL.DEFAULTS_LOADED), function(target)
                target.controlsList:makeCellVisible(1, 1)
                target.nextFocusSection = 1
                target.nextFocusCell = 1
                target.nextFocusedButtonName = "actionButton1"
            end, self, DialogElement.TYPE_INFO)
        end
    end, nil, g_i18n:getText(SettingsControlsFrame.L10N_SYMBOL.LOAD_DEFAULTS), g_i18n:getText(SettingsControlsFrame.L10N_SYMBOL.BUTTON_RESET))
end
function SettingsControlsFrame:onControllerChanged()
    self.dataRowOffset = 0
    self.numTotalDevices = 3 + g_inputBinding.numActiveGamepads
    self.controlsList:makeCellVisible(1, 1, true)
    self.nextFocusSection = 1
    self.nextFocusCell = 1
    self.nextFocusedButtonName = "actionButton1"
    self:assignDeviceTableData()
    self.controlsMessageText = ""
    self:updateMenuButtons()
end
function SettingsControlsFrame:onClickNextRow()
    self.dataRowOffset = self.dataRowOffset + 1
    self.controlsList:reloadData()
    self:updateListHeaderNames()
end
function SettingsControlsFrame:onClickPrevRow()
    self.dataRowOffset = self.dataRowOffset - 1
    self.controlsList:reloadData()
    self:updateListHeaderNames()
end
SettingsControlsFrame.CONTROLS_UI_STRINGS = {
    [ControlsController.MESSAGE_CANNOT_MAP_KEY] = "ui_cannotMapKeyHere",
    [ControlsController.MESSAGE_CANNOT_MAP_MOUSE] = "ui_cannotMapMouseHere",
    [ControlsController.MESSAGE_CANNOT_MAP_CONTROLLER] = "ui_cannotMapGamepadHere",
    [ControlsController.MESSAGE_PROMPT_KEY] = "ui_pressKeyToMap",
    [ControlsController.MESSAGE_PROMPT_MOUSE] = "ui_pressMouseButtonToMap",
    [ControlsController.MESSAGE_PROMPT_CONTROLLER] = "ui_pressGamepadButtonToMap",
    [ControlsController.MESSAGE_PROMPT_CANCEL_DELETE] = "ui_pressESCToCancel",
    [ControlsController.MESSAGE_ENSURE_IN_NEUTRAL] = "ui_ensureAxisToMapInNeutral",
    [ControlsController.MESSAGE_SELECT_ACTION] = "ui_selectActionToRemap",
    [ControlsController.MESSAGE_CONFLICT_KEY] = "ui_keyAlreadyMapped",
    [ControlsController.MESSAGE_CONFLICT_MOUSE] = "ui_buttonAlreadyMapped",
    [ControlsController.MESSAGE_CONFLICT_BUTTON] = "ui_buttonAlreadyMapped",
    [ControlsController.MESSAGE_CONFLICT_AXIS] = "ui_axisAlreadyMapped",
    [ControlsController.MESSAGE_CONFLICT_BLOCKED_KEY] = "ui_blockedKeyCombination"
}
SettingsControlsFrame.CONFLICT_MESSAGES = {
    [ControlsController.MESSAGE_CANNOT_MAP_KEY] = true,
    [ControlsController.MESSAGE_CANNOT_MAP_MOUSE] = true,
    [ControlsController.MESSAGE_CANNOT_MAP_CONTROLLER] = true,
    [ControlsController.MESSAGE_CONFLICT_KEY] = true,
    [ControlsController.MESSAGE_CONFLICT_MOUSE] = true,
    [ControlsController.MESSAGE_CONFLICT_BUTTON] = true,
    [ControlsController.MESSAGE_CONFLICT_AXIS] = true,
    [ControlsController.MESSAGE_CONFLICT_BLOCKED_KEY] = true
}
SettingsControlsFrame.L10N_TEMPLATE_SYMBOL = {
    [ControlsController.MESSAGE_REMAPPED] = "ui_actionRemapped"
}
SettingsControlsFrame.L10N_SYMBOL = {
    ["BUTTON_SAVE"] = "button_saveControls",
    ["BUTTON_DEFAULTS"] = "button_defaults",
    ["BUTTON_KEYBOARD"] = "ui_keyboard",
    ["BUTTON_GAMEPAD"] = "ui_gamepad",
    ["SAVE_CHANGES_PROMPT"] = "ui_saveChanges",
    ["SAVED_CHANGES_INFO"] = "ui_savingFinished",
    ["LOAD_DEFAULTS"] = "ui_loadDefaultSettings",
    ["DEFAULTS_LOADED"] = "ui_loadedDefaultSettings",
    ["KEY_PROMPT"] = "ui_pressKeyToMap",
    ["MOUSE_PROMPT"] = "ui_pressMouseButtonToMap",
    ["BUTTON_PROMPT"] = "ui_pressGamepadButtonToMap",
    ["BUTTON_RESET"] = "button_reset"
}
SettingsControlsFrame.COLOR = {
    ["BLACK"] = {
        0.00439,
        0.00478,
        0.00368,
        1
    },
    ["GREEN"] = {
        0.22323,
        0.40724,
        0.00368,
        1
    }
}
SettingsControlsFrame.DEVICES = {
    {
        ["name"] = "ui_key1",
        ["category"] = InputDevice.CATEGORY.KEYBOARD_MOUSE,
        ["binding"] = ControlsController.BINDING_PRIMARY
    },
    {
        ["name"] = "ui_key2",
        ["category"] = InputDevice.CATEGORY.KEYBOARD_MOUSE,
        ["binding"] = ControlsController.BINDING_SECONDARY
    },
    {
        ["name"] = "ui_mouse",
        ["category"] = InputDevice.CATEGORY.KEYBOARD_MOUSE,
        ["binding"] = ControlsController.BINDING_TERTIARY
    },
    {
        ["category"] = InputDevice.CATEGORY.GAMEPAD,
        ["binding"] = ControlsController.BINDING_PRIMARY
    }
}