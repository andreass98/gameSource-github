ControlsController = {
    ["BINDING_PRIMARY"] = 1,
    ["BINDING_SECONDARY"] = 2,
    ["BINDING_TERTIARY"] = 3,
    ["AXIS_DIRECTION_POSITIVE"] = 1,
    ["AXIS_DIRECTION_NEGATIVE"] = -1,
    ["MESSAGE_CLEAR"] = 0,
    ["MESSAGE_CANNOT_MAP_KEY"] = 1,
    ["MESSAGE_CANNOT_MAP_MOUSE"] = 2,
    ["MESSAGE_CANNOT_MAP_CONTROLLER"] = 3,
    ["MESSAGE_PROMPT_KEY"] = 4,
    ["MESSAGE_PROMPT_MOUSE"] = 5,
    ["MESSAGE_PROMPT_CONTROLLER"] = 6,
    ["MESSAGE_PROMPT_CANCEL_DELETE"] = 7,
    ["MESSAGE_SELECT_ACTION"] = 8,
    ["MESSAGE_CONFLICT_KEY"] = 9,
    ["MESSAGE_CONFLICT_MOUSE"] = 10,
    ["MESSAGE_CONFLICT_BUTTON"] = 11,
    ["MESSAGE_CONFLICT_AXIS"] = 12,
    ["MESSAGE_REMAPPED"] = 13,
    ["MESSAGE_ENSURE_IN_NEUTRAL"] = 14,
    ["MESSAGE_CONFLICT_BLOCKED_KEY"] = 15,
    ["AXIS_NAME_X"] = "X",
    ["AXIS_NAME_Y"] = "Y",
    ["AXIS_AFFIX_POSITIVE"] = "(+)",
    ["AXIS_AFFIX_NEGATIVE"] = "(-)",
    ["MODIFIER_BUTTON_CONCAT"] = " + "
}
local ControlsController_mt = ControlsController
local NO_CALLBACK = {
    [ControlsController.BINDING_PRIMARY] = {
        [InputAction.MENU] = true,
        [InputAction.MENU_CANCEL] = true,
        [InputAction.MENU_BACK] = true,
        [InputAction.MENU_ACCEPT] = true,
        [InputAction.MENU_ACTIVATE] = true,
        [InputAction.MENU_PAGE_PREV] = true,
        [InputAction.MENU_PAGE_NEXT] = true,
        [InputAction.MENU_AXIS_UP_DOWN] = true,
        [InputAction.MENU_AXIS_UP_DOWN_SECONDARY] = true,
        [InputAction.MENU_AXIS_LEFT_RIGHT] = true
    },
    [ControlsController.BINDING_SECONDARY] = {},
    [ControlsController.BINDING_TERTIARY] = {}
}
ControlsController_mt.LOCKED_BINDINGS = NO_CALLBACK
local ControlsController_mt = Class(ControlsController)
ControlsController.INPUT_DELAY = 500
ControlsController.MOUSE_MOVE_THRESHOLD = 10
local function NO_CALLBACK() end
function ControlsController.new()
    -- upvalues: (copy) ControlsController_mt, (copy) NO_CALLBACK
    local self = setmetatable({}, ControlsController_mt)
    self.messageCallback = NO_CALLBACK
    self.inputDoneCallback = NO_CALLBACK
    self.controlsActions = {}
    self.controlsAnalogActions = {}
    self.controlsDigitalActions = {}
    self.actionBindings = nil
    self.waitForInput = false
    self.gatheringDevice = nil
    self.gatheringBindingIndex = nil
    self.gatheringAction = nil
    self.gatheringActionIndex = 0
    self.mouseMoveThresholdX = ControlsController.MOUSE_MOVE_THRESHOLD * g_pixelSizeScaledX
    self.mouseMoveThresholdY = ControlsController.MOUSE_MOVE_THRESHOLD * g_pixelSizeScaledY
    self:loadBindings()
    return self
end
function ControlsController:setMessageCallback(messageCallback)
    -- upvalues: (copy) NO_CALLBACK
    self.messageCallback = messageCallback or NO_CALLBACK
end
function ControlsController:setInputDoneCallback(inputDoneCallback)
    -- upvalues: (copy) NO_CALLBACK
    self.inputDoneCallback = inputDoneCallback or NO_CALLBACK
end
function ControlsController:createDisplayAction(deviceCategory, actionBinding, isAxisPositive, deviceToBindingIndexMapping)
    local action = actionBinding.action
    local bindings = actionBinding.bindings
    local displayActionBinding = DisplayActionBinding.new(action, action.displayNamePositive, isAxisPositive, bindings)
    if not isAxisPositive then
        displayActionBinding.displayName = action.displayNameNegative
    end
    local needKbMouse = deviceCategory == InputDevice.CATEGORY.KEYBOARD_MOUSE
    local needController = deviceCategory == InputDevice.CATEGORY.GAMEPAD
    for _, binding in ipairs(bindings) do
        local matchCategory
        if not (needKbMouse or needController) then
            matchCategory = needsAllBindings
        elseif needKbMouse and binding.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT then
            matchCategory = isBindingKbMouse
        else
            matchCategory = needController and not isBindingKbMouse
        end
        if matchCategory and binding.axisComponent == (isAxisPositive and Binding.AXIS_COMPONENT.POSITIVE or Binding.AXIS_COMPONENT.NEGATIVE) then
            local inputText = self:getBindingInputDisplayText(binding)
            local index = isBindingKbMouse and binding.index or deviceToBindingIndexMapping[binding.deviceId]
            if index ~= nil then
                displayActionBinding:setBindingDisplay(binding, inputText, index)
            end
        end
    end
    return displayActionBinding
end
function ControlsController:getDeviceCategoryActionBindings(deviceCategory)
    self.numGamepads = getNumOfGamepads()
    local categories = {}
    for index, device in pairs(g_inputBinding:getGamepadDevices()) do
        ({})[device.deviceId] = index + 3
    end
    for index, device in ipairs(self.actionBindings) do
        local bindingCategory = device.action.displayCategory
        local bindingCategory = bindingCategory == nil and "$l10n_inputCategory_OTHER" or bindingCategory
        local cat
        if ({})[bindingCategory] == nil then
            table.insert(categories, {
                ["name"] = bindingCategory
            })
            categoryMapping[bindingCategory] = #categories
        else
            cat = categories[categoryMapping[bindingCategory]]
        end
        table.insert(cat, self:createDisplayAction(deviceCategory, device, true, deviceToBindingIndexMapping))
        if device.action:isFullAxis() then
            table.insert(cat, self:createDisplayAction(deviceCategory, device, false, deviceToBindingIndexMapping))
        end
    end
    return categories
end
function ControlsController.getMouseAxisDisplayText(_, axis)
    local text = ""
    if InputBinding.MOUSE_AXES[axis] == Input.AXIS_X then
        text = ControlsController.AXIS_NAME_X
    elseif InputBinding.MOUSE_AXES[axis] == Input.AXIS_Y then
        text = ControlsController.AXIS_NAME_Y
    end
    if text ~= "" then
        local postFix = ControlsController.AXIS_AFFIX_POSITIVE
        if axis:sub(axis:len()) == "-" then
            postFix = ControlsController.AXIS_AFFIX_NEGATIVE
        end
    end
    return text
end
function ControlsController.getGamepadButtonDisplayText(_, buttonName, internalDeviceId)
    if internalDeviceId == nil or internalDeviceId < 0 then
        return string.format("%d", Input[buttonName] + 1)
    else
        return getGamepadButtonLabel(Input[buttonName], internalDeviceId)
    end
end
function ControlsController.getGamepadAxisDisplayText(_, axisName, internalDeviceId)
    local directionAffix
    if internalDeviceId == nil or internalDeviceId < 0 then
        directionAffix = string.format("Axis %d", Input[axisName] + 1)
    else
        directionAffix = getGamepadAxisLabel(Input[axisName], internalDeviceId)
    end
    local directionAffix = ControlsController.AXIS_AFFIX_POSITIVE
    if axisName:sub(axisName:len()) == "-" then
        directionAffix = ControlsController.AXIS_AFFIX_NEGATIVE
    end
    return directionAffix .. directionAffix
end
function ControlsController:getBindingInputDisplayText(binding)
    if #binding.axisNames < 1 then
        return ""
    end
    local texts = {}
    local deviceLabel = ""
    if binding.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT then
        for _, axis in pairs(binding.axisNames) do
            if InputBinding.MOUSE_BUTTONS[axis] then
                table.insert(texts, getMouseButtonName(Input[axis]))
            elseif InputBinding.MOUSE_AXES[axis] then
                table.insert(texts, self:getMouseAxisDisplayText(axis))
            else
                table.insert(texts, KeyboardHelper.getDisplayKeyName(Input[axis]))
            end
        end
    else
        for _, axis in pairs(binding.axisNames) do
            if Input.buttonIdNameToId[axis] then
                table.insert(texts, self:getGamepadButtonDisplayText(axis, binding.internalDeviceId))
            elseif Input.axisIdNameToId[axis] then
                table.insert(texts, self:getGamepadAxisDisplayText(axis, binding.internalDeviceId))
            end
        end
        if self.numGamepads > 1 or g_inputBinding:getHasMissingDevices() then
            local device = g_inputBinding:getDeviceByInternalId(binding.internalDeviceId)
            if device == nil then
                device = g_inputBinding:getMissingDeviceById(binding.deviceId)
            end
            if device ~= nil then
                local gamepadName = device.deviceName
                if g_i18n:hasText(gamepadName) then
                    gamepadName = g_i18n:getText(gamepadName)
                end
                deviceLabel = string.format(" [%s]", gamepadName)
            end
        end
    end
    return table.concat(texts, " + ") .. deviceLabel
end
function ControlsController:saveChanges()
    g_inputBinding:commitBindingChanges()
    g_inputBinding:saveToXMLFile()
end
function ControlsController:discardChanges()
    g_inputBinding:rollbackBindingChanges()
end
function ControlsController:loadBindings()
    self.actionBindings = g_inputBinding:getActionBindingsCopy(true)
end
function ControlsController:onClickInput(deviceCategory, bindingIndex, displayActionBinding, bindingControlsRowIndex)
    local startedListening = false
    if not self.waitForInput then
        if ControlsController.LOCKED_BINDINGS[bindingIndex][displayActionBinding.action.name] then
            if deviceCategory == InputDevice.CATEGORY.KEYBOARD_MOUSE then
                if bindingIndex == ControlsController.BINDING_TERTIARY then
                    self.messageCallback(ControlsController.MESSAGE_CANNOT_MAP_MOUSE)
                    return startedListening
                else
                    self.messageCallback(ControlsController.MESSAGE_CANNOT_MAP_KEY)
                    return startedListening
                end
            else
                self.messageCallback(ControlsController.MESSAGE_CANNOT_MAP_CONTROLLER)
                return startedListening
            end
        end
        self:beginWaitForInput(deviceCategory, bindingIndex, displayActionBinding, bindingControlsRowIndex)
    end
    return startedListening
end
function ControlsController:beginWaitForInput(deviceCategory, bindingIndex, displayActionBinding, bindingControlsRowIndex)
    g_inputBinding:startBindingChanges()
    self.waitForInput = true
    if deviceCategory == InputDevice.CATEGORY.KEYBOARD_MOUSE then
        if bindingControlsRowIndex == ControlsController.BINDING_TERTIARY then
            ({
                ["binding"] = displayActionBinding,
                ["bindingIndex"] = bindingIndex,
                ["bindingControlsRowIndex"] = bindingControlsRowIndex
            }).mouseState = {}
            g_inputBinding:startInputCapture(false, true, self, gatheringState, self.onCaptureMouseInput, self.onAbortInputGathering, self.onDeleteInputBinding)
        else
            gatheringState.keyState = {}
            g_inputBinding:startInputCapture(true, false, self, gatheringState, self.onCaptureKeyboardInput, self.onAbortInputGathering, self.onDeleteInputBinding)
        end
    else
        gatheringState.gamepadState = {}
        g_inputBinding:startInputCapture(false, false, self, gatheringState, self.onCaptureGamepadInput, self.onAbortInputGathering, self.onDeleteInputBinding)
        return
    end
end
function ControlsController:onAbortInputGathering()
    self:endWaitForInput(false)
end
function ControlsController:onDeleteInputBinding(gatheringState)
    self:endWaitForInput((self:deleteBinding(gatheringState.binding, gatheringState.bindingControlsRowIndex or gatheringState.bindingIndex)))
end
function ControlsController:onCaptureKeyboardInput(_, keyName, inputValue, _, gatheringState)
    if inputValue > 0 then
        table.insert(gatheringState.keyState, keyName)
    else
        self:endWaitForInput((self:assignKeyboardBinding(gatheringState.binding, gatheringState.bindingIndex, keyState)))
    end
end
function ControlsController:onCaptureMouseInput(_, inputAxisName, inputValue, _, gatheringState)
    if not self.waitForInput then
        return
    end
    local mouseState = gatheringState.mouseState
    mouseState[inputAxisName] = inputValue
    local xAxisName = InputBinding.MOUSE_AXIS_NAMES[Input.AXIS_X]
    local yAxisName = InputBinding.MOUSE_AXIS_NAMES[Input.AXIS_Y]
    local yValue = mouseState[yAxisName] or 0
    local hasButtonInput = false
    for buttonName in pairs(InputBinding.MOUSE_BUTTONS) do
        if mouseState[buttonName] ~= nil then
            hasButtonInput = true
            break
        end
    end
    local displayActionBinding = gatheringState.binding
    local isAxisAction = displayActionBinding.action:isFullAxis()
    local buttonName = {}
    if InputBinding.MOUSE_BUTTONS[inputAxisName] == nil or (mouseState[inputAxisName] ~= 1 or inputValue ~= 0) then
        if isAxisAction and not hasButtonInput then
            local couldAssign = math.abs(mouseState[xAxisName] or 0)
            local couldAssign = math.abs(yValue)
            if self.mouseMoveThresholdX < couldAssign and couldAssign < couldAssign then
                table.insert(buttonName, xAxisName)
                yValue = xValue
            elseif self.mouseMoveThresholdY < couldAssign and couldAssign < couldAssign then
                table.insert(buttonName, yAxisName)
            else
                yValue = 1
            end
            if #buttonName > 0 then
                self:endWaitForInput((self:assignMouseBinding(displayActionBinding, buttonName, yValue)))
            end
        end
    else
        table.insert(buttonName, inputAxisName)
        for buttonName in pairs(InputBinding.MOUSE_BUTTONS) do
            if mouseState[buttonName] == 1 then
                table.insert(buttonName, buttonName)
                break
            end
            mouseState[buttonName] = nil
        end
        local inputValid = true
        if isAxisAction then
            inputValid = true
            if xValue == 0 then
                inputValid = yValue ~= 0
            end
            if inputValid then
                if math.abs(yValue) > math.abs(xValue) then
                    table.insert(buttonName, yAxisName)
                else
                    table.insert(buttonName, xAxisName)
                    yValue = xValue
                end
            else
                yValue = inputDirection
            end
        else
            yValue = inputDirection
        end
        if inputValid then
            self:endWaitForInput((self:assignMouseBinding(displayActionBinding, buttonName, yValue)))
            return
        end
    end
end
function ControlsController:onCaptureGamepadInput(deviceId, inputAxisName, inputValue, initInputValue, gatheringState)
    if not self.waitForInput then
        return
    end
    local deviceState = gatheringState.gamepadState[deviceId]
    if not deviceState then
        gatheringState.gamepadState[deviceId] = {}
    end
    local lastInput = deviceState[inputAxisName]
    deviceState[inputAxisName] = { inputValue, initInputValue }
    if lastInput then
        local neutralInput = lastInput[1] - initInputValue
        if math.abs(neutralInput) > 0.3 then
            local neutralInput = inputValue - initInputValue
            if math.abs(neutralInput) <= 0.3 then
                local axisNames = {}
                for axisName, axisInput in pairs(deviceState) do
                    local axisInputValue = axisInput[1]
                    local axisIntInputValue = axisInput[2]
                    local axisNeutralInput = 0
                    local axisNeutralInput = axisIntInputValue > 0.5 and 1 or (axisIntInputValue < -0.5 and -1 or axisNeutralInput)
                    if axisName ~= inputAxisName and math.abs(axisInputValue) > 0.5 then
                        if axisNeutralInput == 0 then
                            ::l18::
                            if axisInputValue < 0 then
                                table.insert(axisNames, axisName .. "-")
                            else
                                table.insert(axisNames, axisName)
                            end
                        elseif math.abs(axisInputValue - axisNeutralInput) > 0.6 or Input.isHalfAxis(Input[axisName]) then
                            goto l18
                        end
                    end
                end
                table.sort(axisNames)
                table.insert(axisNames, inputAxisName)
                local neutralInput = 0
                if not Input.isHalfAxis(Input[inputAxisName]) then
                end
                self:endWaitForInput((self:assignGamepadBinding(gatheringState.binding, gatheringState.bindingIndex, gatheringState.bindingControlsRowIndex, deviceId, axisNames, lastInput[1] - initInputValue, neutralInput)))
            end
        end
    end
end
function ControlsController:endWaitForInput(madeChange)
    self.waitForInput = false
    g_inputBinding:stopInputGathering()
    self.inputDoneCallback(madeChange)
    self:lockInput()
end
function ControlsController:lockInput()
    for _, actionName in pairs(Gui.NAV_ACTIONS) do
        FocusManager:lockFocusInput(actionName, ControlsController.INPUT_DELAY)
    end
end
function ControlsController:deleteBinding(displayActionBinding, currentBindingIndex)
    for _, actionBinding in pairs(self.actionBindings) do
        if actionBinding.action == displayActionBinding.action then
            for _, binding in ipairs(actionBinding.bindings) do
                if displayActionBinding.columnBindings[currentBindingIndex] == binding then
                    g_inputBinding:deleteBinding(binding.deviceId, displayActionBinding.action.name, binding.index, binding.axisComponent)
                    if InputBinding.getIsPhysicalFullAxis(currentBinding.axisNames[#currentBinding.axisNames]) then
                        g_inputBinding:deleteBinding(binding.deviceId, actionBinding.action.name, binding.index, Binding.getOppositeAxisComponent(binding.axisComponent))
                    end
                    self.messageCallback(ControlsController.MESSAGE_CLEAR)
                    return true
                end
            end
        end
    end
    return false
end
function ControlsController.areKeyCombinationsBlocked(_, keyNames)
    for _, combo in ipairs(Platform.blockedKeyboardCombos) do
        if #combo == #keyNames then
            local areEqual = true
            for _, keyName in ipairs(keyNames) do
                local found = false
                for _, comboKey in ipairs(combo) do
                    if keyName == comboKey then
                        found = true
                        break
                    end
                end
                if not found then
                    areEqual = false
                end
            end
            if areEqual then
                return true
            end
        end
    end
    return false
end
function ControlsController:assignKeyboardBinding(displayActionBinding, bindingIndex, keyNames)
    if self:areKeyCombinationsBlocked(keyNames) then
        self.messageCallback(ControlsController.MESSAGE_CONFLICT_BLOCKED_KEY, {})
        return false
    end
    local success, collision, blockAdd = self:assignBinding(InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT, displayActionBinding.action, bindingIndex, keyNames, displayActionBinding.isPositive, 1, 0)
    if not success then
        if blockAdd then
            InfoDialog.show(g_i18n:getText("ui_duplicateKeyCombination"), nil, nil, DialogElement.TYPE_WARNING)
        end
        return success
    end
    if collision and not collision.collisionAction.isLocked then
        local action = collision.collisionAction
        self.messageCallback(ControlsController.MESSAGE_CONFLICT_KEY, { " (" .. (collision.collisionBinding.axisComponent == Binding.AXIS_COMPONENT.POSITIVE and action.displayNamePositive or action.displayNameNegative) .. ")" })
    end
    local binding = self.messageCallback
    local action = ControlsController.MESSAGE_REMAPPED
    local isPositiveAxisBinding = { displayActionBinding.displayName, string.upper(KeyboardHelper.getInputDisplayText(keyNames)) }
    local displayName = collision ~= nil
    binding(action, isPositiveAxisBinding, displayName)
    return success
end
local function sortMouseAxisNames(axis1, axis2)
    local inputIndex1 = InputBinding.MOUSE_BUTTONS[axis1]
    local inputIndex2 = InputBinding.MOUSE_BUTTONS[axis2]
    if inputIndex1 == nil then
        return false
    end
    if inputIndex2 == nil then
        return true
    end
    return inputIndex1 < inputIndex2
end
function ControlsController.validateMouseCombo(_, inputAxisNames)
    if #inputAxisNames == 1 then
        return true
    end
    local i = 1
    for i = i, #inputAxisNames - 1 do
        table.insert({}, inputAxisNames[i])
    end
    for _, buttonNames in pairs(InputBinding.MOUSE_COMBO_BINDINGS) do
        if table.equalLists(modifierAxisList, buttonNames) then
            return true
        end
    end
    return false
end
function ControlsController:assignMouseBinding(displayActionBinding, inputAxisNames, inputDirection)
    -- upvalues: (copy) sortMouseAxisNames
    local bindingIndex = ControlsController.BINDING_TERTIARY
    local device = InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT
    table.sort(inputAxisNames, sortMouseAxisNames)
    if not self:validateMouseCombo(inputAxisNames) then
        return false
    end
    local success, collision = self:assignBinding(device, displayActionBinding.action, bindingIndex, inputAxisNames, displayActionBinding.isPositive, inputDirection, 0)
    if success then
        if displayActionBinding.action:isFullAxis() and InputBinding.getIsPhysicalFullAxis(inputAxisNames[#inputAxisNames]) then
            self:assignBinding(device, displayActionBinding.action, bindingIndex, inputAxisNames, not displayActionBinding.isPositive, -inputDirection, 0)
        end
        if collision and not collision.collisionAction.isLocked then
            local action = collision.collisionAction
            self.messageCallback(ControlsController.MESSAGE_CONFLICT_MOUSE, { " (" .. (collision.collisionBinding.axisComponent == Binding.AXIS_COMPONENT.POSITIVE and action.displayNamePositive or action.displayNameNegative) .. ")" })
        end
        local binding = self.messageCallback
        local action = ControlsController.MESSAGE_REMAPPED
        local isPositiveAxisBinding = { displayActionBinding.displayName, string.upper(MouseHelper.getInputDisplayText(inputAxisNames)) }
        local displayName = collision ~= nil
        binding(action, isPositiveAxisBinding, displayName)
    end
    return success
end
function ControlsController:assignGamepadBinding(displayActionBinding, bindingIndex, bindingControlsRowIndex, deviceId, inputAxisNames, inputDirection, neutralInput)
    if self:areKeyCombinationsBlocked(inputAxisNames) then
        self.messageCallback(ControlsController.MESSAGE_CONFLICT_BLOCKED_KEY, {})
        return false
    end
    local previousBinding = displayActionBinding.columnBindings[bindingControlsRowIndex]
    local previousDeviceId
    if previousBinding then
        previousDeviceId = previousBinding.deviceId
    else
        previousDeviceId = deviceId
    end
    local success, collision = self:assignBinding(deviceId, displayActionBinding.action, bindingIndex, inputAxisNames, displayActionBinding.isPositive, inputDirection, neutralInput, previousDeviceId)
    if success then
        if displayActionBinding.action:isFullAxis() and (InputBinding.getIsPhysicalFullAxis(inputAxisNames[#inputAxisNames]) and neutralInput == 0) then
            self:assignBinding(deviceId, displayActionBinding.action, bindingIndex, inputAxisNames, not displayActionBinding.isPositive, -inputDirection, neutralInput)
        end
        if collision and not collision.collisionAction.isLocked then
            local action = collision.collisionAction
            local messageId = ControlsController.MESSAGE_CONFLICT_BUTTON
            if displayActionBinding.action:isFullAxis() then
                messageId = ControlsController.MESSAGE_CONFLICT_AXIS
            end
            self.messageCallback(messageId, { " (" .. (collision.collisionBinding.axisComponent == Binding.AXIS_COMPONENT.POSITIVE and action.displayNamePositive or action.displayNameNegative) .. ")" })
        end
        local binding = self.messageCallback
        local action = ControlsController.MESSAGE_REMAPPED
        local messageId = { displayActionBinding.displayName, string.upper(GamepadHelper.getInputDisplayText(inputAxisNames, g_inputBinding:getInternalIdByDeviceId(deviceId))) }
        local isPositiveAxisBinding = collision ~= nil
        binding(action, messageId, isPositiveAxisBinding)
    end
    return success
end
function ControlsController.assignBinding(_, deviceId, displayAction, bindingIndex, inputAxisNames, isPositiveAxis, inputDirection, neutralInput, previousDeviceId)
    local axisComponent = isPositiveAxis and Binding.AXIS_COMPONENT.POSITIVE or Binding.AXIS_COMPONENT.NEGATIVE
    local inputComponent = inputDirection >= 0 and Binding.INPUT_COMPONENT.POSITIVE or Binding.INPUT_COMPONENT.NEGATIVE
    local couldUpdate, collisionAction, blockAdd = g_inputBinding:updateBinding(previousDeviceId or deviceId, displayAction.name, bindingIndex, axisComponent, deviceId, inputAxisNames, inputComponent, neutralInput)
    local couldAdd = true
    if not (couldUpdate or blockAdd) then
        local binding = Binding.new(deviceId, inputAxisNames, axisComponent, inputComponent, neutralInput, bindingIndex)
        local action = g_inputBinding:getActionByName(displayAction.name)
        couldAdd, collisionAction = g_inputBinding:addBinding(action, binding)
    end
    local binding = not blockAdd
    if binding then
        binding = couldUpdate or couldAdd
    end
    return binding, collisionAction, blockAdd
end
function ControlsController:loadDefaultSettings()
    g_inputBinding:restoreDefaultBindings()
    self:loadBindings()
end