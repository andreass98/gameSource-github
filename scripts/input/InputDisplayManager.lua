InputDisplayManager = {}
local InputDisplayManager_mt = Class(InputDisplayManager)
source("dataS/scripts/input/DisplayActionBinding.lua")
source("dataS/scripts/input/InputHelpElement.lua")
InputDisplayManager.CONTROLLER_SYMBOLS_PATH = "dataS/controllerSymbols.xml"
InputDisplayManager.AXIS_ICON_DEFINITIONS_PATH = "dataS/axisIcons.xml"
InputDisplayManager.SYMBOLS_TEXTURE_CONFIG_PATH = "dataS/menu/controllerSymbols.xml"
InputDisplayManager.AXIS_ICON_BASE_SIZE = 40
InputDisplayManager.SYMBOL_PREFIX_XBOX = "xbox_"
InputDisplayManager.SYMBOL_PREFIX_PS4 = "ps4_"
InputDisplayManager.SYMBOL_PREFIX_PS5 = "ps5_"
InputDisplayManager.SYMBOL_PREFIX_MOUSE = "mouse_"
InputDisplayManager.SYMBOL_PREFIX_SWITCH = "switch_"
InputDisplayManager.SYMBOL_PREFIX_MOBILE = "mobile_"
InputDisplayManager.SYMBOL_PREFIX_STADIA = "stadia_"
InputDisplayManager.AXIS_NAME_X = "X"
InputDisplayManager.AXIS_NAME_Y = "Y"
InputDisplayManager.AXIS_NAME_MOUSE_X = InputBinding.MOUSE_AXIS_NAMES[Input.AXIS_X]
InputDisplayManager.AXIS_NAME_MOUSE_Y = InputBinding.MOUSE_AXIS_NAMES[Input.AXIS_Y]
InputDisplayManager.AXIS_AFFIX_POSITIVE = "(+)"
InputDisplayManager.AXIS_AFFIX_NEGATIVE = "(-)"
InputDisplayManager.MODIFIER_BUTTON_CONCAT = " + "
InputDisplayManager.PLUS_OVERLAY_NAME = "PLUS"
InputDisplayManager.OR_OVERLAY_NAME = "OR"
InputDisplayManager.NO_HELP_ELEMENT = InputHelpElement.new()
function InputDisplayManager.new(messageCenter, inputManager, modManager, isConsoleVersion)
    -- upvalues: (copy) InputDisplayManager_mt
    local self = setmetatable({}, InputDisplayManager_mt)
    self.messageCenter = messageCenter
    self.inputManager = inputManager
    self.modManager = modManager
    self.isConsoleVersion = isConsoleVersion
    self.isMobileVersion = GS_IS_MOBILE_VERSION
    messageCenter:subscribe(MessageType.INPUT_BINDINGS_CHANGED, self.onActionBindingsChanged, self)
    inputManager:setEventChangeCallback(function(displayActionEvents)
        -- upvalues: (copy) self
        self:onActionEventsChanged(displayActionEvents)
    end)
    self.actionList = inputManager:getActionList()
    self.actionBindings = inputManager:getActionBindings()
    self.eventHelpElements = {
        [GS_INPUT_HELP_MODE_GAMEPAD] = {},
        [GS_INPUT_HELP_MODE_KEYBOARD] = {},
        [GS_INPUT_HELP_MODE_TOUCH] = {}
    }
    self.eventComboButtons = {
        [GS_INPUT_HELP_MODE_GAMEPAD] = {},
        [GS_INPUT_HELP_MODE_KEYBOARD] = {},
        [GS_INPUT_HELP_MODE_TOUCH] = {}
    }
    self.controllerSymbols = {}
    self.plusOverlay = nil
    self.orOverlay = nil
    self.keyboardKeyOverlay = nil
    self.axisIconOverlays = {}
    self.buttonIconSize = 45
    self.uiScale = 1
    g_overlayManager:addTextureConfigFile(InputDisplayManager.SYMBOLS_TEXTURE_CONFIG_PATH, "controllerSymbols")
    self.debugControllerSymbols = false
    return self
end
function InputDisplayManager:load()
    self.uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
    self:setDevGamepadLabelMapping()
    self:loadControllerSymbolsAndOverlays()
    local axisIconsXmlFile = loadXMLFile("AxisIcons", InputDisplayManager.AXIS_ICON_DEFINITIONS_PATH)
    if axisIconsXmlFile == 0 then
        Logging.warning("Unable to load axisIcon definition file %q", InputDisplayManager.AXIS_ICON_DEFINITIONS_PATH)
    else
        self:loadAxisIcons(axisIconsXmlFile)
        delete(axisIconsXmlFile)
    end
    self:loadModAxisIcons()
    addConsoleCommand("gsInputDebugControllerSymbols", "", "consoleCommandShowInputControllerSymbols", self)
end
function InputDisplayManager:delete()
    g_messageCenter:unsubscribeAll(self)
    for _, symbol in pairs(self.controllerSymbols) do
        symbol.overlay:delete()
    end
    for _, symbol in pairs(self.axisIconOverlays) do
        symbol:delete()
    end
    self.keyboardKeyOverlay:delete()
end
function InputDisplayManager:setDevGamepadLabelMapping()
    if GS_PLATFORM_PLAYSTATION and g_isDevelopmentVersion then
        local PS_BUTTON_MAPPING = {
            ["A"] = "Cross",
            ["B"] = "Circle",
            ["X"] = "Square",
            ["Y"] = "Triangle",
            ["LB"] = "L1",
            ["RB"] = "R1",
            ["Back"] = "Options",
            ["Start"] = "Touch",
            ["LS"] = "L3",
            ["RS"] = "R3"
        }
        local PS_AXIS_MAPPING = {
            ["LT"] = "L2",
            ["RT"] = "R2"
        }
        local oldGetGamepadButtonLabel = getGamepadButtonLabel
        function getGamepadButtonLabel(buttonId, internalId)
            -- upvalues: (copy) oldGetGamepadButtonLabel, (copy) PS_BUTTON_MAPPING
            local label = oldGetGamepadButtonLabel(buttonId, internalId)
            return Utils.getNoNil(PS_BUTTON_MAPPING[label], label)
        end
        local oldGetGamepadAxisLabel = getGamepadAxisLabel
        function getGamepadAxisLabel(axisId, internalId)
            -- upvalues: (copy) oldGetGamepadAxisLabel, (copy) PS_AXIS_MAPPING
            local label = oldGetGamepadAxisLabel(axisId, internalId)
            return Utils.getNoNil(PS_AXIS_MAPPING[label], label)
        end
    end
end
function InputDisplayManager:loadControllerSymbolsAndOverlays()
    local metadata = g_overlayManager:getConfigMetaData("controllerSymbols")
    if metadata == nil then
        Logging.warning("No texture config for controller symbols found")
    else
        local xmlFile = loadXMLFile("ControllerSymbolsBinding", InputDisplayManager.CONTROLLER_SYMBOLS_PATH)
        local i = 0
        while true do
            local baseName = string.format("controllerSymbols.controllerSymbol(%d)", i)
            if not hasXMLProperty(xmlFile, baseName) then
                break
            end
            local prefix = getXMLString(xmlFile, baseName .. "#prefix") or ""
            local axisName = getXMLString(xmlFile, baseName .. "#name")
            local sliceId = "controllerSymbols." .. getXMLString(xmlFile, baseName .. "#sliceId")
            if axisName ~= nil then
                local parts = axisName:trim():split(" ")
                local axisSymbolName = ""
                for _, part in pairs(parts) do
                    if part ~= "" then
                    end
                end
                if self.controllerSymbols[axisSymbolName] then
                    printWarning("Warning: controller symbol name \'" .. axisSymbolName .. "\' already exists!")
                else
                    self:createButtonOverlay(axisSymbolName, metadata.filename, sliceId)
                end
            end
            i = i + 1
        end
        self.keyboardKeyOverlay = ButtonOverlay.new()
        delete(xmlFile)
    end
end
function InputDisplayManager:createButtonOverlay(axisName, filename, sliceId)
    local iconSizeX, iconSizeY = getNormalizedScreenValues(self.buttonIconSize * self.uiScale, self.buttonIconSize * self.uiScale)
    local overlay = g_overlayManager:createOverlay(sliceId, 0, 0, iconSizeX, iconSizeY)
    overlay:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_LEFT)
    self.controllerSymbols[axisName] = {
        ["name"] = axisName,
        ["filename"] = filename,
        ["overlay"] = overlay
    }
    if axisName == InputDisplayManager.PLUS_OVERLAY_NAME then
        self.plusOverlay = overlay
        overlay.width = iconSizeX * 0.5
        overlay.defaultWidth = iconSizeX * 0.5
        overlay.height = iconSizeY * 0.5
        overlay.defaultHeight = iconSizeY * 0.5
    elseif axisName == InputDisplayManager.OR_OVERLAY_NAME then
        self.orOverlay = overlay
        overlay.width = iconSizeX * 0.5
        overlay.defaultWidth = iconSizeX * 0.5
        overlay.height = iconSizeY * 0.5
        overlay.defaultHeight = iconSizeY * 0.5
    end
end
function InputDisplayManager:loadAxisIcons(xmlFile, modPath)
    if xmlFile == nil or xmlFile == 0 then
        Logging.error("InputDisplayManager:loadAxisIcons(): xmlFile nil or 0")
        printCallstack()
    else
        local rootPath = "axisIcons"
        local baseDirectory = ""
        local prefix = ""
        if modPath then
            rootPath = "modDesc.axisIcons"
            prefix, baseDirectory = Utils.getModNameAndBaseDirectory(modPath)
        end
        local modName = 0
        while true do
            local dir = string.format("%s.icon(%d)", rootPath, modName)
            if not hasXMLProperty(xmlFile, dir) then
                break
            end
            local iconName = prefix .. getXMLString(xmlFile, dir .. "#name") or ""
            local iconPath = getXMLString(xmlFile, dir .. "#filename")
            if iconName and iconPath then
                local iconFilename = Utils.getFilename(iconPath, baseDirectory)
                local size = InputDisplayManager.AXIS_ICON_BASE_SIZE * self.uiScale
                local iconWidth, iconHeight = getNormalizedScreenValues(size, size)
                local iconOverlay = Overlay.new(iconFilename, 0, 0, iconWidth, iconHeight)
                iconOverlay:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_LEFT)
                self.axisIconOverlays[iconName] = iconOverlay
            end
            modName = modName + 1
        end
    end
end
function InputDisplayManager:loadModAxisIcons()
    for _, modDesc in ipairs(self.modManager:getMods()) do
        local xmlFile = loadXMLFile("ModFile", modDesc.modFile)
        if xmlFile == 0 then
            Logging.error("InputDisplayManager:loadModAxisIcons(): unable to load %q", modDesc.modFile)
        else
            self:loadAxisIcons(xmlFile, modDesc.modFile)
            delete(xmlFile)
        end
    end
end
function InputDisplayManager:addContextBindings(contextBindings, action, isContextGamepad, isComboAction)
    local addedGamepadBinding = nil
    local addedGamepadBindingIndex = -1
    for _, binding in pairs(self.actionBindings[action]) do
        if binding.isActive then
            local axisRepresented = false
            if not isComboAction then
                for _, contextBinding in pairs(contextBindings) do
                    if binding.internalDeviceId == contextBinding.internalDeviceId and binding.unmodifiedAxis == contextBinding.unmodifiedAxis then
                        axisRepresented = true
                        break
                    end
                end
            end
            if not axisRepresented then
                local isMouse = not isContextGamepad
                if isMouse then
                    isMouse = binding.isMouse
                end
                local isGamepad = isContextGamepad and binding.isGamepad
                local shouldSwapGamepadBinding
                if isGamepad then
                    shouldSwapGamepadBinding = false
                    if addedGamepadBinding ~= nil then
                        shouldSwapGamepadBinding = binding.index < addedGamepadBinding.index
                    end
                else
                    shouldSwapGamepadBinding = isGamepad
                end
                if shouldSwapGamepadBinding or self.inputManager:getDeviceByInternalId(binding.internalDeviceId).category == InputDevice.CATEGORY.GAMEPAD and isComboAction then
                    table.remove(contextBindings, addedGamepadBindingIndex)
                    addedGamepadBinding = nil
                end
                if isMouse or isGamepad and addedGamepadBinding == nil then
                    table.insert(contextBindings, binding)
                    if isGamepad then
                        addedGamepadBindingIndex = #contextBindings
                        addedGamepadBinding = binding
                    end
                end
            end
        end
    end
end
function InputDisplayManager:getActionBindingsForContext(action1, action2, isContextGamepad, isComboAction)
    local contextBindings = {}
    self:addContextBindings(contextBindings, action1, isContextGamepad, isComboAction)
    if action2 then
        self:addContextBindings(contextBindings, action2, isContextGamepad)
    end
    return contextBindings
end
local actionBindingsBuffer = {}
function InputDisplayManager:getKeyboardBindings(action1, action2)
    -- upvalues: (copy) actionBindingsBuffer
    for k in pairs(actionBindingsBuffer) do
        actionBindingsBuffer[k] = nil
    end
    if action2 then
    end
    local k = actionBindingsBuffer
    table.insert(k, self.actionBindings[action1])
    if action2 ~= nil then
        table.insert(actionBindingsBuffer, action2)
    end
    local kbBindings = {}
    for _, bindings in ipairs(actionBindingsBuffer) do
        for _, binding in ipairs(bindings) do
            if binding.isKeyboard then
                table.insert(kbBindings, binding)
            end
        end
    end
    return kbBindings
end
function InputDisplayManager:resolveModifierSymbols(overlays, separators, isComboButtonMapping, firstContextBinding)
    local i = 1
    for i = i, #firstContextBinding.axisNames - 1 do
        local symbolName = self:getGamepadInputSymbolName(firstContextBinding.internalDeviceId, firstContextBinding.axisNames[i], false)
        local symbol = self.controllerSymbols[symbolName]
        if symbol ~= nil then
            table.insert(overlays, symbol.overlay)
            table.insert(isComboButtonMapping, true)
            table.insert(separators, InputHelpElement.SEPARATOR.COMBO_INPUT)
        end
    end
end
function InputDisplayManager:resolveAccumulatedSymbolPermutations(overlays, isComboButtonMapping, symbolNames, permLength)
    if permLength == 0 then
        local accumSymbolName = ""
        for _, name in ipairs(symbolNames) do

        end
        local symbol = self.controllerSymbols[accumSymbolName]
        if symbol ~= nil then
            table.insert(overlays, symbol.overlay)
            table.insert(isComboButtonMapping, false)
            return
        end
    else
        local i = 1
        for i = i, permLength do
            symbolNames[permLength] = symbolNames[i]
            symbolNames[i] = symbolNames[permLength]
            self:resolveAccumulatedSymbolPermutations(overlays, isComboButtonMapping, symbolNames, permLength - 1)
            symbolNames[permLength] = symbolNames[i]
            symbolNames[i] = symbolNames[permLength]
        end
    end
end
function InputDisplayManager:resolveUnmodifiedSymbols(overlays, isComboButtonMapping, contextBindings, isContextGamepad, accumulateSymbols)
    local accumSymbols = nil
    for _, binding in pairs(contextBindings) do
        local symbolName
        if isContextGamepad then
            symbolName = self:getGamepadInputSymbolName(binding.internalDeviceId, binding.unmodifiedAxis, binding.isAnalog)
        else
            symbolName = self:getMouseInputSymbolName(binding.axisNames)
        end
        if accumulateSymbols and symbolName ~= nil then
            if accumSymbols == nil then
                accumSymbols = { symbolName }
            else
                local isAxisInput = false
                for _, knownName in ipairs(accumSymbols) do
                    if knownName == symbolName then
                        isAxisInput = true
                        break
                    end
                end
                if not isAxisInput then
                    table.insert(accumSymbols, symbolName)
                end
            end
        else
            local isAxisInput = self.controllerSymbols[symbolName]
            if isAxisInput ~= nil then
                table.insert(overlays, isAxisInput.overlay)
                table.insert(isComboButtonMapping, false)
            end
        end
    end
    if accumulateSymbols and accumSymbols ~= nil then
        self:resolveAccumulatedSymbolPermutations(overlays, isComboButtonMapping, accumSymbols, #accumSymbols)
    end
end
function InputDisplayManager:addRegularSymbols(overlays, separators, isComboButtonMapping, accumulateSymbols, contextBindings, isContextGamepad, ignoreComboButtons)
    if #contextBindings > 0 then
        if not ignoreComboButtons and isContextGamepad then
            self:resolveModifierSymbols(overlays, separators, isComboButtonMapping, contextBindings[1])
        end
        local prevCount = #overlays
        self:resolveUnmodifiedSymbols(overlays, isComboButtonMapping, contextBindings, isContextGamepad, accumulateSymbols)
        local afterCount = #overlays
        if prevCount ~= afterCount then
            for _ = 1, afterCount - prevCount - 1 do
                table.insert(separators, InputHelpElement.SEPARATOR.ANY_INPUT)
            end
        end
    end
end
function InputDisplayManager:addComboSymbols(overlays, separators, isComboButtonMapping, contextBindings, isContextGamepad)
    local symbolName = #contextBindings == 1
    assert(symbolName, "Number of bindings for a combo action must always be 1, check code and configuration!")
    if isContextGamepad then
        for _, inputAxisName in ipairs(contextBindings[1].axisNames) do
            local symbolName = self:getGamepadInputSymbolName(binding.internalDeviceId, inputAxisName, false)
            local symbol = self.controllerSymbols[symbolName]
            if symbol ~= nil then
                table.insert(overlays, symbol.overlay)
                table.insert(isComboButtonMapping, true)
            end
        end
    else
        local symbolName = self:getMouseInputSymbolName(binding.axisNames, false)
        table.insert(overlays, self.controllerSymbols[symbolName].overlay)
        table.insert(isComboButtonMapping, true)
    end
    local symbolName = #overlays - 1
    for _ = 1, symbolName do
        table.insert(separators, InputHelpElement.SEPARATOR.COMBO_INPUT)
    end
end
function InputDisplayManager:getControllerSymbolOverlays(actionName1, actionName2, text, ignoreComboButtons, customBinding)
    local action1 = self.inputManager:getActionByName(actionName1)
    local action2 = self.inputManager:getActionByName(actionName2)
    local isGamepadComboAction = InputBinding.GAMEPAD_COMBOS[actionName1] ~= nil
    local isMouseComboAction = InputBinding.MOUSE_COMBOS[actionName1] ~= nil
    local isContextGamepad = self.isConsoleVersion or self.isMobileVersion
    if isContextGamepad then
        isGamepadComboAction = isContextGamepad
    elseif self.inputManager:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD then
        isGamepadComboAction = true
    end
    if customBinding ~= nil then
        return self:makeHelpElementForBinding(action1, customBinding)
    end
    if isGamepadComboAction then
        isGamepadComboAction = not isMouseComboAction
    end
    return self:makeHelpElement(action1, action2, text, isGamepadComboAction or isMouseComboAction, isGamepadComboAction, ignoreComboButtons)
end
function InputDisplayManager.requireSymbolAccumulation(action1, action2, contextBindings)
    local accumulateSymbols = action1:isFullAxis() and not action2
    if accumulateSymbols then
        action2 = accumulateSymbols
    elseif action2 then
        action2 = action2:isFullAxis()
    end
    if not action2 then
        local allDpad = true
        for _, binding in pairs(contextBindings) do
            if allDpad then
                allDpad = InputBinding.getIsDPadInput(binding.axisNames)
            end
        end
    end
    if not action2 then
        local allDpad = true
        for _, binding in pairs(contextBindings) do
            if allDpad then
                allDpad = InputBinding.getIsMouseWheelInput(binding.axisNames)
            end
        end
    end
    return action2
end
function InputDisplayManager:makeHelpElement(action1, action2, text, isComboAction, isContextGamepad, ignoreComboButtons, customAxisIcon, priority)
    local contextBindings = self:getActionBindingsForContext(action1, action2, isContextGamepad, isComboAction)
    local overlays = {}
    if #contextBindings > 0 then
        if isComboAction then
            self:addComboSymbols(overlays, {}, {}, contextBindings, isContextGamepad)
        else
            self:addRegularSymbols(overlays, separators, isComboButtonMapping, InputDisplayManager.requireSymbolAccumulation(action1, action2, contextBindings), contextBindings, isContextGamepad, ignoreComboButtons)
        end
    end
    local accumulateSymbols = {}
    if #overlays < 1 and not isContextGamepad then
        local kbBindings = self:getKeyboardBindings(action1, action2)
        for _, binding in ipairs(kbBindings) do
            for _, key in ipairs(binding.axisNames) do
                local isModifierKey = binding.modifierAxisSet[key] ~= nil
                if not (isModifierKey and ({})[key]) then
                    table.insert(accumulateSymbols, KeyboardHelper.getDisplayKeyName(Input[key]))
                    if isModifierKey then
                        modifierHash[key] = true
                    end
                end
            end
        end
    end
    local kbBindings = InputDisplayManager.NO_HELP_ELEMENT
    if #overlays > 0 or #accumulateSymbols > 0 then
        kbBindings = InputHelpElement.new(action1.name, action2 ~= nil and action2.name or "", overlays, accumulateSymbols, separators, isComboButtonMapping, text, not ignoreComboButtons, customAxisIcon, priority)
    end
    return kbBindings
end
function InputDisplayManager:makeHelpElementForBinding(action, binding)
    local overlays = {}
    if not binding.isKeyboard then
        self:addRegularSymbols(overlays, {}, {}, InputDisplayManager.requireSymbolAccumulation(action, nil, { binding }), { binding }, binding.isGamepad)
    end
    local accumulateSymbols = {}
    if #overlays < 1 then
        for _, key in ipairs(binding.axisNames) do
            local isModifierKey = binding.modifierAxisSet[key] ~= nil
            if not (isModifierKey and ({})[key]) then
                table.insert(accumulateSymbols, KeyboardHelper.getDisplayKeyName(Input[key]))
                if isModifierKey then
                    modifierHash[key] = true
                end
            end
        end
    end
    local modifierHash = InputDisplayManager.NO_HELP_ELEMENT
    if #overlays > 0 or #accumulateSymbols > 0 then
        modifierHash = InputHelpElement.new(action.name, nil, overlays, accumulateSymbols, separators, isComboButtonMapping)
    end
    return modifierHash
end
function InputDisplayManager:onActionEventsChanged(displayActionEvents)
    self:storeEventHelpElements(displayActionEvents)
    self:storeComboHelpElements(displayActionEvents)
end
function InputDisplayManager.sortEventHelpElements(helpElem1, helpElem2)
    if helpElem1.priority ~= helpElem2.priority then
        return helpElem1.priority < helpElem2.priority
    end
    if helpElem1.actionName == "" or helpElem2.actionName == "" then
        return helpElem2.actionName == ""
    end
    local action1 = g_inputBinding:getActionByName(helpElem1.actionName)
    local action2 = g_inputBinding:getActionByName(helpElem2.actionName)
    if action1.primaryKeyboardInput == nil then
        return helpElem1.text < helpElem2.text
    end
    if action2.primaryKeyboardInput == nil then
        return false
    end
    return action1.primaryKeyboardInput < action2.primaryKeyboardInput
end
function InputDisplayManager.sortEventHelpElementsGamepad(helpElem1, helpElem2)
    -- block 16
    if #helpElem1.buttons <= 0 or #helpElem2.buttons <= 0 then
        return #helpElem1.buttons > 0
    end
    local v63_, v64_, v65_ = pairs(helpElem1.buttons)
    v63_, v64_, v65_ = v63_, v64_, v65_
    local k, button
    -- GenericForNext
k, button = v63_(v64_, [internal control])
if k ~= nil
[internal control] = k
-- end GenericForNext
    -- block 2
    goto l13
    ::l4::
    local helpElem2Button = helpElem2.buttons[k]
    if helpElem2Button == nil then
        return true
    end
    if helpElem2Button.overlayId == button.overlayId then
        return false
    end
    return button.overlayId < helpElem2Button.overlayId
    -- block 5
    goto l4
    ::l13::
    return true
end
function InputDisplayManager:storeEventHelpElements(displayActionEvents)
    self.eventHelpElements = {
        [GS_INPUT_HELP_MODE_GAMEPAD] = {},
        [GS_INPUT_HELP_MODE_KEYBOARD] = {},
        [GS_INPUT_HELP_MODE_TOUCH] = {}
    }
    for helpMode, modeHelpElements in pairs(self.eventHelpElements) do
        local isContextGamepad = helpMode == GS_INPUT_HELP_MODE_GAMEPAD
        for _, actionEvent in ipairs(displayActionEvents) do
            local action = actionEvent.action
            local event = actionEvent.event
            local inlineModifierButtons = actionEvent.inlineModifierButtons
            if not inlineModifierButtons then
                inlineModifierButtons = helpMode == GS_INPUT_HELP_MODE_KEYBOARD
            end
            local actionComboMask = 0
            if isContextGamepad then
                if not inlineModifierButtons then
                    actionComboMask = action.comboMaskGamepad
                end
            else
                actionComboMask = action.comboMaskMouse
            end
            local maskHelpElements = modeHelpElements[actionComboMask]
            if not maskHelpElements then
                modeHelpElements[actionComboMask] = {}
            end
            local axisIcon = not event.contextDisplayIconName or self.axisIconOverlays[event.contextDisplayIconName]
            if not axisIcon then
                printWarning("Warning: Could not resolve axis icon name \'" .. event.contextDisplayIconName .. "\'. Check vehicle and axis icon configurations.")
            end
            local helpElement = self:makeHelpElement(action, nil, event.contextDisplayText, false, isContextGamepad, not inlineModifierButtons, axisIcon, event.displayPriority)
            if helpElement ~= InputDisplayManager.NO_HELP_ELEMENT then
                table.insert(maskHelpElements, helpElement)
            end
        end
        local sortFunc = InputDisplayManager.sortEventHelpElements
        if isContextGamepad then
            sortFunc = InputDisplayManager.sortEventHelpElementsGamepad
        end
        for actionEvent, action in pairs(modeHelpElements) do
            table.sort(action, sortFunc)
        end
    end
end
function InputDisplayManager:storeComboHelpElements(displayActionEvents)
    self.eventComboButtons = {
        [GS_INPUT_HELP_MODE_GAMEPAD] = {},
        [GS_INPUT_HELP_MODE_KEYBOARD] = {},
        [GS_INPUT_HELP_MODE_TOUCH] = {}
    }
    for helpMode, _ in pairs(self.eventHelpElements) do
        for _, actionEvent in ipairs(displayActionEvents) do
            for _, binding in pairs(self.actionBindings[actionEvent.action]) do
                local isPrimaryGamepad = helpMode == GS_INPUT_HELP_MODE_GAMEPAD and binding.isActive
                if isPrimaryGamepad then
                    isPrimaryGamepad = binding.isGamepad
                end
                local isMouse = not isContextGamepad
                if isMouse then
                    isMouse = binding.isMouse
                end
                if isPrimaryGamepad and not actionEvent.inlineModifierButtons or isMouse then
                    local comboActionName = self.inputManager:getComboActionNameForAxisSet(binding.modifierAxisSet)
                    if comboActionName then
                        self.eventComboButtons[helpMode][comboActionName] = true
                    end
                end
            end
        end
    end
end
function InputDisplayManager:getEventHelpElementForAction(inputActionName)
    local helpMode = self.inputManager:getInputHelpMode()
    local eventHelpElement = nil
    for _, helpElements in pairs(self.eventHelpElements[helpMode]) do
        for _, element in pairs(helpElements) do
            if element.actionName == inputActionName then
                eventHelpElement = element
                break
            end
        end
    end
    return eventHelpElement
end
function InputDisplayManager:getEventHelpElements(pressedComboMask, isContextGamepad)
    return self.eventHelpElements[isContextGamepad and GS_INPUT_HELP_MODE_GAMEPAD or GS_INPUT_HELP_MODE_KEYBOARD][pressedComboMask]
end
function InputDisplayManager:getComboHelpElements(isContextGamepad)
    return self.eventComboButtons[isContextGamepad and GS_INPUT_HELP_MODE_GAMEPAD or GS_INPUT_HELP_MODE_KEYBOARD]
end
function InputDisplayManager.getPrefix(_, internalDeviceId)
    local prefix = ""
    if GS_PLATFORM_XBOX then
        return InputDisplayManager.SYMBOL_PREFIX_XBOX
    end
    if GS_PLATFORM_SWITCH then
        return InputDisplayManager.SYMBOL_PREFIX_SWITCH
    end
    if GS_PLATFORM_SWITCH2 then
        return InputDisplayManager.SYMBOL_PREFIX_SWITCH
    end
    if GS_PLATFORM_PLAYSTATION then
        if internalDeviceId == 0 and GS_PLATFORM_ID == PlatformId.PS5 then
            return InputDisplayManager.SYMBOL_PREFIX_PS5
        end
    else
        if GS_IS_MOBILE_VERSION then
            prefix = InputDisplayManager.SYMBOL_PREFIX_MOBILE
        end
        if internalDeviceId ~= nil then
            local gamepadName = getGamepadName(internalDeviceId)
            if gamepadName == InputDevice.NAMES.XBOX_GAMEPAD or gamepadName == InputDevice.NAMES.XINPUT_GAMEPAD then
                return InputDisplayManager.SYMBOL_PREFIX_XBOX
            end
            if gamepadName == InputDevice.NAMES.PS_GAMEPAD then
                return InputDisplayManager.SYMBOL_PREFIX_PS4
            end
            if gamepadName == InputDevice.NAMES.PS5_GAMEPAD then
                return InputDisplayManager.SYMBOL_PREFIX_PS5
            end
            if gamepadName == InputDevice.NAMES.STADIA_GAMEPAD then
                return InputDisplayManager.SYMBOL_PREFIX_STADIA
            end
            if gamepadName == InputDevice.NAMES.SWITCH_GAMEPAD then
                prefix = InputDisplayManager.SYMBOL_PREFIX_SWITCH
            end
        end
    end
    return prefix
end
function InputDisplayManager:getPlusOverlay()
    return self.plusOverlay
end
function InputDisplayManager:getOrOverlay()
    return self.orOverlay
end
function InputDisplayManager:getKeyboardKeyOverlay()
    return self.keyboardKeyOverlay
end
function InputDisplayManager:getFirstBindingAxisAndDeviceForActionName(inputActionName, axisComponent, isGamepad)
    axisComponent = axisComponent or Binding.AXIS_COMPONENT.POSITIVE
    local action = self.inputManager:getActionByName(inputActionName)
    local contextBinding = nil
    local internalDeviceId = nil
    local bindings = self.actionBindings[action]
    local lowestIndex = math.huge
    if bindings == nil then
        return "", -1
    else
        for _, binding in ipairs(bindings) do
            local fitsContext = not (binding.isGamepad and isGamepad) and binding.isKeyboard
            if fitsContext then
                fitsContext = not isGamepad
            end
            if binding.isActive and (binding.index < lowestIndex and (fitsContext and binding.axisComponent == axisComponent)) then
                internalDeviceId = binding.internalDeviceId
                lowestIndex = binding.index
                contextBinding = binding
            end
        end
        if contextBinding then
            return contextBinding.axisNames[1], internalDeviceId
        else
            return "", -1
        end
    end
end
function InputDisplayManager:getGamepadInputActionOverlay(inputActionName, axisComponent)
    local axisName, internalDeviceId = self:getFirstBindingAxisAndDeviceForActionName(inputActionName, axisComponent, true)
    local symbolName = self:getGamepadInputSymbolName(internalDeviceId, axisName, false)
    if symbolName == nil or symbolName == "" then
        return nil
    end
    if self.controllerSymbols[symbolName] == nil then
        Logging.devWarning("Controller symbol name \'%s\' is not defined in controllerSymbols.xml", symbolName)
        return nil
    end
    local overlay = self.controllerSymbols[symbolName].overlay
    local guiOverlay = {
        ["uvs"] = overlay.uvs,
        ["color"] = {
            overlay.r,
            overlay.g,
            overlay.b,
            overlay.a
        },
        ["filename"] = overlay.filename
    }
    GuiOverlay.createOverlay(guiOverlay)
    return guiOverlay
end
function InputDisplayManager:getKeyboardInputActionKey(inputActionName, axisComponent)
    local axisName = self:getFirstBindingAxisAndDeviceForActionName(inputActionName, axisComponent, false)
    if axisName == "" then
        return nil
    end
    return KeyboardHelper.getDisplayKeyName(Input[axisName])
end
function InputDisplayManager.getGamepadInputSymbolName(_, internalDeviceId, axisName, isAxisInput)
    local symbolName = ""
    if internalDeviceId ~= nil and internalDeviceId >= 0 then
        local prefix = InputDisplayManager:getPrefix(internalDeviceId)
        if isAxisInput then
            local axisId = Input.axisIdNameToId[axisName]
            if axisId ~= nil then
                return prefix .. string.gsub(getGamepadAxisLabel(axisId, internalDeviceId), " ", "")
            end
        else
            local axisId = Input.buttonIdNameToId[axisName]
            if axisId ~= nil then
                local axisLabel = getGamepadButtonLabel(axisId, internalDeviceId)
                symbolName = prefix .. string.gsub(axisLabel, " ", "")
            end
        end
    end
    return symbolName
end
function InputDisplayManager.getMouseInputSymbolName(_, axisNames)
    local symbolName = ""
    for _, axisName in pairs(axisNames) do
        if InputBinding.MOUSE_BUTTONS[axisName] then
        elseif axisName:sub(1, #InputDisplayManager.AXIS_NAME_MOUSE_X) == InputDisplayManager.AXIS_NAME_MOUSE_X then
        elseif axisName:sub(1, #InputDisplayManager.AXIS_NAME_MOUSE_Y) == InputDisplayManager.AXIS_NAME_MOUSE_Y then
        end
    end
    return symbolName
end
function InputDisplayManager:onActionBindingsChanged(actionBindings)
    self.actionBindings = actionBindings
end
function InputDisplayManager:draw()
    if self.debugControllerSymbols then
        self:debugRenderControllerSymbols()
    end
end
function InputDisplayManager:debugRenderControllerSymbols()
    new2DLayer()
    setOverlayColor(GuiElement.debugOverlay, 0, 0, 0, 0.99)
    renderOverlay(GuiElement.debugOverlay, 0, 0, 1, 1)
    local posX = 0.005
    local posY = 0.97
    local width, height = getNormalizedScreenValues(30, 30)
    local textOffsetX, _ = getNormalizedScreenValues(5, 0)
    local offsetX, offsetY = getNormalizedScreenValues(20, -45)
    local textSize = getCorrectTextSize(0.007)
    local maxTextWidth = getNormalizedScreenValues(120, 0)
    local maxWidth = 0
    setTextWrapWidth(maxTextWidth, true)
    setTextColor(1, 1, 1, 1)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
    for _, data in ipairs(self.controllerSymbolsSorted) do
        local overlay = data.overlay
        overlay:setPosition(posX, posY)
        overlay:setDimension(width, height)
        overlay:render()
        overlay:resetDimensions()
        maxWidth = math.max(maxWidth, getTextWidth(textSize, data.name))
        renderText(posX + textOffsetX + width, posY, textSize, data.name)
        posY = posY + offsetY
        if posY < 0 then
            posY = 0.97
        end
    end
    setTextWrapWidth(0)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
end
function InputDisplayManager:consoleCommandShowInputControllerSymbols()
    self.debugControllerSymbols = not self.debugControllerSymbols
    if self.debugControllerSymbols then
        if self.controllerSymbolsSorted == nil then
            self.controllerSymbolsSorted = {}
            for _, symbol in pairs(self.controllerSymbols) do
                table.insert(self.controllerSymbolsSorted, symbol)
            end
            table.sort(self.controllerSymbolsSorted, function(a, b)
                return a.name < b.name
            end)
            return
        end
    else
        self.controllerSymbolsSorted = nil
    end
end