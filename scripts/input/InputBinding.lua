InputBinding = {}
local InputBinding_mt = Class(InputBinding)
source("dataS/scripts/input/InputAction.lua")
source("dataS/scripts/input/InputDevice.lua")
source("dataS/scripts/input/Binding.lua")
source("dataS/scripts/input/InputEvent.lua")
InputBinding.version = 4
InputBinding.currentBindingVersion = 1
InputBinding.PATHS = {
    ["DEFAULT_BINDINGS_KB_MOUSE"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_KeyboardMouse.xml",
    ["DEFAULT_BINDINGS_GAMEPAD"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_Gamepad.xml",
    ["DEFAULT_BINDINGS_JOYSTICK"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_Joystick.xml",
    ["DEFAULT_BINDINGS_WHEEL"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_Wheel.xml",
    ["DEFAULT_BINDINGS_WHEEL_AND_PANEL"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_WheelAndPanel.xml",
    ["DEFAULT_BINDINGS"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_Gamepad.xml",
    ["DEFAULT_BINDINGS_XBOX"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_Gamepad.xml",
    ["DEFAULT_BINDINGS_IOS"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_Mobile.xml",
    ["DEFAULT_BINDINGS_ANDROID"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_Mobile.xml",
    ["DEFAULT_BINDINGS_SWITCH"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_Switch.xml",
    ["DEFAULT_BINDINGS_SAITEK_WHEEL_AND_PANEL"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_SaitekWheelAndPanel.xml",
    ["DEFAULT_BINDINGS_SAITEK_WHEEL"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_SaitekWheel.xml",
    ["DEFAULT_BINDINGS_SAITEK_PANEL"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_SaitekPanel.xml",
    ["DEFAULT_BINDINGS_HORI_WHEEL"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_HoriFarmingControllerWheel.xml",
    ["DEFAULT_BINDINGS_HORI_PANEL"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_HoriFarmingControllerPanel.xml",
    ["DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_ThrustmasterFarmJoystick.xml",
    ["DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK_PS"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_ThrustmasterFarmJoystickConsole_PS.xml",
    ["DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK_XBOX"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_ThrustmasterFarmJoystickConsole.xml",
    ["DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK_DUAL"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_ThrustmasterFarmJoystickConsoleDual.xml",
    ["DEFAULT_BINDINGS_MOZA_FARMING_CONTROL_SYSTEM"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_MozaFarmingControlSystem.xml",
    ["ACTION_DEFINITIONS"] = getAppBasePath() .. "dataS/inputActions.xml",
    ["USER_BINDINGS"] = getUserProfileAppPath() .. "inputBinding.xml"
}
if Platform.isConsole then
    if Platform.isPlaystation then
        InputBinding.PATHS.DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK = getAppBasePath() .. "profileTemplate/inputBindingDefault_ThrustmasterFarmJoystickConsole_PS.xml"
        InputBinding.PATHS.DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK_DUAL = getAppBasePath() .. "profileTemplate/inputBindingDefault_ThrustmasterFarmJoystickConsoleDual_PS.xml"
    else
        InputBinding.PATHS.DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK = getAppBasePath() .. "profileTemplate/inputBindingDefault_ThrustmasterFarmJoystickConsole.xml"
        InputBinding.PATHS.DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK_DUAL = getAppBasePath() .. "profileTemplate/inputBindingDefault_ThrustmasterFarmJoystickConsoleDual.xml"
    end
end
InputBinding.THURSTMASTER_FARMJOYSTICK_LEFT_PRODUCT_IDS = {
    1052,
    1054,
    1088,
    1090,
    1092
}
InputBinding.THURSTMASTER_FARMJOYSTICK_RIGHT_PRODUCT_IDS = {
    1051,
    1053,
    1055,
    1091
}
InputBinding.DEVICE_CATEGORY_DEFAULTS_PATHS = {
    [InputDevice.CATEGORY.GAMEPAD] = InputBinding.PATHS.DEFAULT_BINDINGS_GAMEPAD,
    [InputDevice.CATEGORY.JOYSTICK] = InputBinding.PATHS.DEFAULT_BINDINGS_JOYSTICK,
    [InputDevice.CATEGORY.WHEEL] = InputBinding.PATHS.DEFAULT_BINDINGS_WHEEL,
    [InputDevice.CATEGORY.FARMWHEEL] = InputBinding.PATHS.DEFAULT_BINDINGS_SAITEK_WHEEL,
    [InputDevice.CATEGORY.FARMPANEL] = InputBinding.PATHS.DEFAULT_BINDINGS_SAITEK_PANEL,
    [InputDevice.CATEGORY.UNKNOWN] = InputBinding.PATHS.DEFAULT_BINDINGS_GAMEPAD,
    [InputDevice.CATEGORY.WHEEL_AND_PANEL] = InputBinding.PATHS.DEFAULT_BINDINGS_WHEEL_AND_PANEL,
    [InputDevice.CATEGORY.FARMWHEEL_AND_PANEL] = InputBinding.PATHS.DEFAULT_BINDINGS_SAITEK_WHEEL_AND_PANEL,
    [InputDevice.CATEGORY.FARMWHEEL_HORI] = InputBinding.PATHS.DEFAULT_BINDINGS_HORI_WHEEL,
    [InputDevice.CATEGORY.FARMPANEL_HORI] = InputBinding.PATHS.DEFAULT_BINDINGS_HORI_PANEL,
    [InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER] = InputBinding.PATHS.DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK,
    [InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER_DUAL] = InputBinding.PATHS.DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK_DUAL,
    [InputDevice.CATEGORY.FARMPANEL_MOZA] = InputBinding.PATHS.DEFAULT_BINDINGS_MOZA_FARMING_CONTROL_SYSTEM
}
InputBinding.DEVICE_CATEGORY_DEFAULT_LOAD_ORDER = {
    InputDevice.CATEGORY.FARMWHEEL_AND_PANEL,
    InputDevice.CATEGORY.WHEEL_AND_PANEL,
    InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER_DUAL,
    InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER,
    InputDevice.CATEGORY.FARMWHEEL,
    InputDevice.CATEGORY.FARMWHEEL_HORI,
    InputDevice.CATEGORY.WHEEL,
    InputDevice.CATEGORY.GAMEPAD,
    InputDevice.CATEGORY.JOYSTICK,
    InputDevice.CATEGORY.FARMPANEL,
    InputDevice.CATEGORY.FARMPANEL_HORI,
    InputDevice.CATEGORY.FARMPANEL_MOZA
}
InputBinding.INPUTTYPE_NONE = 0
InputBinding.INPUTTYPE_KEYBOARD = 1
InputBinding.INPUTTYPE_MOUSE_BUTTON = 2
InputBinding.INPUTTYPE_MOUSE_WHEEL = 3
InputBinding.INPUTTYPE_MOUSE_AXIS = 4
InputBinding.INPUTTYPE_GAMEPAD = 5
InputBinding.INPUTTYPE_GAMEPAD_AXIS = 6
InputBinding.MOUSE_AXIS_NONE = 0
InputBinding.MOUSE_AXIS_X = 1
InputBinding.MOUSE_AXIS_Y = 2
InputBinding.SYMBOL_AFFIX_POSITIVE = "_1"
InputBinding.SYMBOL_AFFIX_NEGATIVE = "_2"
InputBinding.MOUSE_AXES = {
    ["AXIS_X"] = Input.AXIS_X,
    ["AXIS_Y"] = Input.AXIS_Y,
    ["AXIS_X+"] = Input.AXIS_X,
    ["AXIS_Y+"] = Input.AXIS_Y,
    ["AXIS_X-"] = Input.AXIS_X,
    ["AXIS_Y-"] = Input.AXIS_Y
}
InputBinding.MOUSE_AXIS_NAMES = {
    [Input.AXIS_X] = "AXIS_X",
    [Input.AXIS_Y] = "AXIS_Y"
}
InputBinding.MOUSE_BUTTONS = {
    ["MOUSE_BUTTON_LEFT"] = Input.MOUSE_BUTTON_LEFT,
    ["MOUSE_BUTTON_RIGHT"] = Input.MOUSE_BUTTON_RIGHT,
    ["MOUSE_BUTTON_MIDDLE"] = Input.MOUSE_BUTTON_MIDDLE,
    ["MOUSE_BUTTON_WHEEL_UP"] = Input.MOUSE_BUTTON_WHEEL_UP,
    ["MOUSE_BUTTON_WHEEL_DOWN"] = Input.MOUSE_BUTTON_WHEEL_DOWN,
    ["MOUSE_BUTTON_X1"] = Input.MOUSE_BUTTON_X1,
    ["MOUSE_BUTTON_X2"] = Input.MOUSE_BUTTON_X2
}
InputBinding.MOUSE_WHEEL = {
    [Input.MOUSE_BUTTON_WHEEL_UP] = true,
    [Input.MOUSE_BUTTON_WHEEL_DOWN] = true
}
InputBinding.MOUSE_BUTTON_NAMES = {
    [Input.MOUSE_BUTTON_LEFT] = "MOUSE_BUTTON_LEFT",
    [Input.MOUSE_BUTTON_RIGHT] = "MOUSE_BUTTON_RIGHT",
    [Input.MOUSE_BUTTON_MIDDLE] = "MOUSE_BUTTON_MIDDLE",
    [Input.MOUSE_BUTTON_WHEEL_UP] = "MOUSE_BUTTON_WHEEL_UP",
    [Input.MOUSE_BUTTON_WHEEL_DOWN] = "MOUSE_BUTTON_WHEEL_DOWN",
    [Input.MOUSE_BUTTON_X1] = "MOUSE_BUTTON_X1",
    [Input.MOUSE_BUTTON_X2] = "MOUSE_BUTTON_X2"
}
InputBinding.GAMEPAD_DPAD = {
    [Input.BUTTON_16] = true,
    [Input.BUTTON_17] = true,
    [Input.BUTTON_18] = true,
    [Input.BUTTON_19] = true
}
InputBinding.COMBO_MASK_CONSOLE_COMMAND_1 = 1
InputBinding.COMBO_MASK_CONSOLE_COMMAND_2 = 2
InputBinding.COMBO_MASK_CONSOLE_COMMAND_3 = 4
InputBinding.COMBO_MASK_MOUSE_COMMAND_1 = 1
InputBinding.COMBO_MASK_MOUSE_COMMAND_2 = 2
InputBinding.COMBO_MASK_MOUSE_COMMAND_3 = 4
InputBinding.COMBO_MASK_MOUSE_COMMAND_4 = 8
local sortEventByOrderValue = InputBinding
sortEventByOrderValue.GAMEPAD_COMBOS = {
    [InputAction.CONSOLE_ALT_COMMAND_BUTTON] = {
        ["mask"] = InputBinding.COMBO_MASK_CONSOLE_COMMAND_1,
        ["controls"] = InputAction.CONSOLE_ALT_COMMAND_BUTTON
    },
    [InputAction.CONSOLE_ALT_COMMAND2_BUTTON] = {
        ["mask"] = InputBinding.COMBO_MASK_CONSOLE_COMMAND_2,
        ["controls"] = InputAction.CONSOLE_ALT_COMMAND2_BUTTON
    },
    [InputAction.CONSOLE_ALT_COMMAND3_BUTTON] = {
        ["mask"] = InputBinding.COMBO_MASK_CONSOLE_COMMAND_3,
        ["controls"] = InputAction.CONSOLE_ALT_COMMAND3_BUTTON
    }
}
InputBinding.ORDERED_GAMEPAD_COMBOS = { InputBinding.GAMEPAD_COMBOS[InputAction.CONSOLE_ALT_COMMAND_BUTTON], InputBinding.GAMEPAD_COMBOS[InputAction.CONSOLE_ALT_COMMAND3_BUTTON], InputBinding.GAMEPAD_COMBOS[InputAction.CONSOLE_ALT_COMMAND2_BUTTON] }
local sortEventByOrderValue = InputBinding
sortEventByOrderValue.MOUSE_COMBOS = {
    [InputAction.MOUSE_ALT_COMMAND_BUTTON] = {
        ["mask"] = InputBinding.COMBO_MASK_MOUSE_COMMAND_1,
        ["controls"] = InputAction.MOUSE_ALT_COMMAND_BUTTON
    },
    [InputAction.MOUSE_ALT_COMMAND2_BUTTON] = {
        ["mask"] = InputBinding.COMBO_MASK_MOUSE_COMMAND_2,
        ["controls"] = InputAction.MOUSE_ALT_COMMAND2_BUTTON
    },
    [InputAction.MOUSE_ALT_COMMAND3_BUTTON] = {
        ["mask"] = InputBinding.COMBO_MASK_MOUSE_COMMAND_3,
        ["controls"] = InputAction.MOUSE_ALT_COMMAND3_BUTTON
    },
    [InputAction.MOUSE_ALT_COMMAND4_BUTTON] = {
        ["mask"] = InputBinding.COMBO_MASK_MOUSE_COMMAND_4,
        ["controls"] = InputAction.MOUSE_ALT_COMMAND4_BUTTON
    }
}
InputBinding.ORDERED_MOUSE_COMBOS = {
    InputBinding.MOUSE_COMBOS[InputAction.MOUSE_ALT_COMMAND_BUTTON],
    InputBinding.MOUSE_COMBOS[InputAction.MOUSE_ALT_COMMAND3_BUTTON],
    InputBinding.MOUSE_COMBOS[InputAction.MOUSE_ALT_COMMAND4_BUTTON],
    InputBinding.MOUSE_COMBOS[InputAction.MOUSE_ALT_COMMAND2_BUTTON]
}
InputBinding.ALL_COMBOS = { InputBinding.GAMEPAD_COMBOS, InputBinding.MOUSE_COMBOS }
InputBinding.GAMEPAD_COMBO_BINDINGS = {
    [InputAction.CONSOLE_ALT_COMMAND_BUTTON] = { Input.buttonIdToIdName[Input.BUTTON_5] },
    [InputAction.CONSOLE_ALT_COMMAND2_BUTTON] = { Input.buttonIdToIdName[Input.BUTTON_6] },
    [InputAction.CONSOLE_ALT_COMMAND3_BUTTON] = { Input.buttonIdToIdName[Input.BUTTON_5], Input.buttonIdToIdName[Input.BUTTON_6] }
}
InputBinding.GAMEPAD_COMBO_AXIS_NAMES = {
    [Input.buttonIdToIdName[Input.BUTTON_5]] = true,
    [Input.buttonIdToIdName[Input.BUTTON_6]] = true
}
InputBinding.MOUSE_COMBO_BINDINGS = {
    [InputAction.MOUSE_ALT_COMMAND_BUTTON] = { InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_LEFT] },
    [InputAction.MOUSE_ALT_COMMAND2_BUTTON] = { InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_RIGHT] },
    [InputAction.MOUSE_ALT_COMMAND3_BUTTON] = { InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_MIDDLE] },
    [InputAction.MOUSE_ALT_COMMAND4_BUTTON] = { InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_LEFT], InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_RIGHT] }
}
InputBinding.MOUSE_COMBO_AXIS_NAMES = {
    [InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_LEFT]] = true,
    [InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_RIGHT]] = true,
    [InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_MIDDLE]] = true
}
InputBinding.MOUSE_MOVE_BASE_FACTOR = 75
InputBinding.MOUSE_MOVE_LIMIT = 4
InputBinding.MOUSE_MOTION_SCALE_X_DEFAULT = 1
InputBinding.MOUSE_MOTION_SCALE_Y_DEFAULT = 1
InputBinding.MOUSE_WHEEL_INPUT_FACTOR = 3
InputBinding.INPUT_MODE_CHANGE_THRESHOLD = 0.2
local sortEventByOrderValue = InputBinding
sortEventByOrderValue.INPUT_MODE_CHANGE_MIN_INTERVAL = GS_IS_MOBILE_VERSION and 0 or 5000
InputBinding.KB_MOUSE_INTERNAL_ID = 255
InputBinding.ROOT_CONTEXT_NAME = "ROOT"
InputBinding.NO_REGISTRATION_CONTEXT = {
    ["actionEvents"] = {},
    ["name"] = "",
    ["previousContextName"] = "",
    ["eventOrderCounter"] = 0
}
InputBinding.NO_ACTION_EVENTS = {}
InputBinding.MESSAGE_PARAM_INPUT_MODE = {
    [GS_INPUT_HELP_MODE_KEYBOARD] = { GS_INPUT_HELP_MODE_KEYBOARD },
    [GS_INPUT_HELP_MODE_GAMEPAD] = { GS_INPUT_HELP_MODE_GAMEPAD },
    [GS_INPUT_HELP_MODE_TOUCH] = { GS_INPUT_HELP_MODE_TOUCH }
}
function InputBinding.new(modManager, messageCenter, isConsoleVersion)
    -- upvalues: (copy) InputBinding_mt
    local self = setmetatable({}, InputBinding_mt)
    self.debugEnabled = false
    self.debugContextEnabled = false
    self.debugRegisteredActions = false
    self.modManager = modManager
    self.messageCenter = messageCenter
    self.isConsoleVersion = isConsoleVersion
    self.devicesByInternalId = {}
    self.devicesByCategory = {}
    self.deviceIdToInternal = {}
    self.internalToDeviceId = {}
    self.engineDeviceIdCounts = {}
    self.internalIdToEngineDeviceId = {}
    self.newlyConnectedDevices = {}
    self.missingDevices = {}
    self.actions = {}
    self.nameActions = {}
    self.originalActionBindings = nil
    self.activeDeviceBindingsBuffer = {}
    self.mouseMovementX = 0
    self.mouseMovementY = 0
    self.accumMouseMovementX = 0
    self.accumMouseMovementY = 0
    self.actionEvents = {}
    self.displayActionEvents = {}
    self.events = {}
    self.eventOrder = {}
    self.loadedBindings = {}
    self.activeBindings = {}
    self.eventBindings = {}
    self.linkedBindings = {}
    self.currentContextName = InputBinding.ROOT_CONTEXT_NAME
    self.contexts = {
        [InputBinding.ROOT_CONTEXT_NAME] = {
            ["previousContextName"] = "",
            ["actionEvents"] = {},
            ["eventOrderCounter"] = 0
        }
    }
    self.registrationContext = InputBinding.NO_REGISTRATION_CONTEXT
    self.comboInputAxisMasks = {}
    self.comboInputActions = {}
    self.comboInputBindings = {}
    self.pressedMouseComboMask = 0
    self.pressedGamepadComboMask = 0
    self.needUpdateAbort = false
    self.eventChangeCallback = nil
    self.wrapMousePositionEnabled = false
    self.saveCursorX = 0.5
    self.saveCursorY = 0.5
    self.mouseMotionScaleX = 0.75
    self.mouseMotionScaleY = 0.75
    self.devicesToMigrateCategory = {}
    self.isInputCapturing = false
    self.gatherInputStoredMouseEvent = nil
    self.gatherInputStoredKeyEvent = nil
    self.gatherInputStoredUpdate = nil
    self.gamepadInputState = {}
    self.timeSinceLastInputHelpModeChange = InputBinding.INPUT_MODE_CHANGE_MIN_INTERVAL
    self.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD
    if isConsoleVersion then
        self.lastInputHelpMode = GS_INPUT_HELP_MODE_GAMEPAD
    end
    self.lastInputMode = self.lastInputHelpMode
    self.inputHelpModeSetting = g_gameSettings:getValue(GameSettings.SETTING.INPUT_HELP_MODE)
    self.isGamepadEnabled = isConsoleVersion or g_gameSettings:getValue(GameSettings.SETTING.IS_GAMEPAD_ENABLED)
    messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.INPUT_HELP_MODE], self.onInputHelpModeSettingChange, self)
    messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.IS_GAMEPAD_ENABLED], self.onGamepadEnabledSettingChanged, self)
    self.settingsPath = nil
    self:assignPlatformBindingPaths()
    addConsoleCommand("gsInputDebug", "", "consoleCommandEnableInputDebug", self)
    addConsoleCommand("gsInputContextPrint", "", "consoleCommandPrintInputContext", self)
    addConsoleCommand("gsInputContextShow", "", "consoleCommandShowInputContext", self)
    addConsoleCommand("gsInputRegisteredActionsShow", "", "consoleCommandShowRegisteredActions", self)
    return self
end
function InputBinding:delete()
    g_messageCenter:unsubscribeAll(self)
end
function InputBinding:load()
    self:clearState()
    local xmlFileActionDefinitions = loadXMLFile("ActionDefinitions", InputBinding.PATHS.ACTION_DEFINITIONS)
    self:loadActions(xmlFileActionDefinitions)
    delete(xmlFileActionDefinitions)
    self:loadModActions()
    local xmlFileInputBinding = loadXMLFile("InputBindings", self.settingsPath)
    self.version = getXMLInt(xmlFileInputBinding, "inputBinding#version") or 1
    self.mouseMotionScaleX = (getXMLFloat(xmlFileInputBinding, "inputBinding#mouseSensitivityScaleX") or 1) * self.MOUSE_MOTION_SCALE_X_DEFAULT
    self.mouseMotionScaleY = (getXMLFloat(xmlFileInputBinding, "inputBinding#mouseSensitivityScaleY") or 1) * self.MOUSE_MOTION_SCALE_Y_DEFAULT
    self:initializeGamepadMapping(xmlFileInputBinding)
    self:loadActionBindingsFromXML(xmlFileInputBinding, false, nil, nil, nil, true)
    self:upgradeBindingVersion(xmlFileInputBinding)
    self:resolveBindingDevices()
    self:migrateDevicesCategory()
    delete(xmlFileInputBinding)
    self:loadDefaultBindings()
    self:validateAndRepairComboActionBindings()
    self:storeComboInputMappings()
    self:assignComboMasks()
    self:assignActionPrimaryBindings()
    self:storeLinkedBindings()
    self:restoreInputContexts()
    self:notifyBindingChanges()
    self:refreshEventCollections()
    for k in pairs(self.newlyConnectedDevices) do
        self.newlyConnectedDevices[k] = nil
    end
    self:checkDefaultInputExclusiveActionBindings()
end
function InputBinding:loadDefaultBindings()
    if self.inputBindingPathTemplate ~= nil then
        local xmlFile = loadXMLFile("DefaultKeyboardMouseBindings", self.inputBindingPathTemplate)
        self:loadActionBindingsFromXML(xmlFile, true, nil, nil, true, false)
        delete(xmlFile)
    end
    if self.numGamepads > 0 then
        local xmlFile = self:getBindingCategorySet(self:getAllDeviceIdsWithBindings())
        local ignoredDevices = self:getAllDeviceIdsWithoutBindings()
        for _, category in ipairs(InputBinding.DEVICE_CATEGORY_DEFAULT_LOAD_ORDER) do
            if xmlFile[category] then
                local xmlFileControllerTemplate = loadXMLFile("ControllerTemplate", InputBinding.DEVICE_CATEGORY_DEFAULTS_PATHS[category])
                if xmlFileControllerTemplate ~= 0 then
                    self:loadActionBindingsFromXML(xmlFileControllerTemplate, true, nil, ignoredDevices, true, false)
                    delete(xmlFileControllerTemplate)
                end
            end
        end
        local requiredCategorySet = self:getBindingCategorySet(ignoredDevices)
        for category, templatePath in ipairs(InputBinding.DEVICE_CATEGORY_DEFAULT_LOAD_ORDER) do
            if requiredCategorySet[templatePath] then
                local xmlFileControllerTemplate = InputBinding.DEVICE_CATEGORY_DEFAULTS_PATHS[templatePath]
                if templatePath == InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER and not Platform.isConsole then
                    for deviceId, _ in pairs(ignoredDevices) do
                        local gamepadName = getGamepadName(deviceId)
                        if string.startsWith(string.upper(gamepadName), "SIMTASK FARMSTICK X") then
                            xmlFileControllerTemplate = InputBinding.PATHS.DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK_XBOX
                            break
                        end
                        if string.startsWith(string.upper(gamepadName), "SIMTASK FARMSTICK P") then
                            xmlFileControllerTemplate = InputBinding.PATHS.DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK_PS
                            break
                        end
                    end
                end
                Logging.devInfo("Loading default input binding: %s", xmlFileControllerTemplate)
                local xmlFileControllerTemplate = loadXMLFile("ControllerTemplate", xmlFileControllerTemplate)
                if xmlFileControllerTemplate ~= 0 then
                    self:loadActionBindingsFromXML(xmlFileControllerTemplate, true, nil, self:getAllDevicesWithBindings(), false, false)
                    delete(xmlFileControllerTemplate)
                end
            end
        end
    end
    self:loadModBindingDefaults()
end
function InputBinding:onInputHelpModeSettingChange(newMode)
    self.inputHelpModeSetting = newMode
end
function InputBinding:onGamepadEnabledSettingChanged(isEnabled)
    self.isGamepadEnabled = isEnabled
end
function InputBinding:getBindingCategorySet(deviceIds)
    local categorySet = {}
    local hasLeftFarmStick = false
    local hasRightFarmStick = false
    for deviceId, _ in pairs(deviceIds) do
        local category = self.devicesByInternalId[deviceId].category
        categorySet[category] = true
        if category == InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER then
            local productId = getGamepadProductId(deviceId)
            hasLeftFarmStick = table.hasElement(InputBinding.THURSTMASTER_FARMJOYSTICK_LEFT_PRODUCT_IDS, productId) and true or hasLeftFarmStick
            if table.hasElement(InputBinding.THURSTMASTER_FARMJOYSTICK_RIGHT_PRODUCT_IDS, productId) then
                hasRightFarmStick = true
            end
        elseif category == InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER_LEFT then
            hasLeftFarmStick = true
        end
    end
    local hasFarmWheel = categorySet[InputDevice.CATEGORY.FARMWHEEL] ~= nil
    if (categorySet[InputDevice.CATEGORY.WHEEL] ~= nil or hasFarmWheel) and categorySet[InputDevice.CATEGORY.FARMPANEL] ~= nil then
        categorySet[InputDevice.CATEGORY.WHEEL] = nil
        categorySet[InputDevice.CATEGORY.FARMWHEEL] = nil
        categorySet[InputDevice.CATEGORY.FARMPANEL] = nil
        if hasFarmWheel then
            categorySet[InputDevice.CATEGORY.FARMWHEEL_AND_PANEL] = true
        else
            categorySet[InputDevice.CATEGORY.WHEEL_AND_PANEL] = true
        end
    end
    if hasLeftFarmStick and hasRightFarmStick then
        categorySet[InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER_DUAL] = true
    end
    return categorySet
end
function InputBinding:getDeviceHasAnyBindings(device)
    for _, action in pairs(self.actions) do
        if InputBinding.GAMEPAD_COMBO_BINDINGS[action.name] == nil then
            for _, binding in pairs(action.bindings) do
                if binding.deviceId == device.deviceId then
                    return true
                end
            end
        end
    end
    return false
end
function InputBinding:getAllDevicesWithBindings()
    local usedDevices = {}
    for _, action in pairs(self.actions) do
        if InputBinding.GAMEPAD_COMBO_BINDINGS[action.name] == nil then
            for _, binding in pairs(action.bindings) do
                usedDevices[binding.deviceId] = true
            end
        end
    end
    return usedDevices
end
function InputBinding:getAllDeviceIdsWithoutBindings()
    local deviceIds = {}
    local deviceId = 0
    local device = self.devicesByInternalId[deviceId]
    while device ~= nil do
        if not self:getDeviceHasAnyBindings(device) then
            deviceIds[deviceId] = true
        end
        deviceId = deviceId + 1
        device = self.devicesByInternalId[deviceId]
    end
    return deviceIds
end
function InputBinding:getAllDeviceIdsWithBindings()
    local deviceIds = {}
    local deviceId = 0
    local device = self.devicesByInternalId[deviceId]
    while device ~= nil do
        if self:getDeviceHasAnyBindings(device) then
            deviceIds[deviceId] = true
        end
        deviceId = deviceId + 1
        device = self.devicesByInternalId[deviceId]
    end
    return deviceIds
end
function InputBinding:reloadModActions()
    self:load()
end
function InputBinding:loadModActions()
    for _, modDesc in ipairs(self.modManager:getMods()) do
        local xmlFile = loadXMLFile("InputBinding ModActions ModFile", modDesc.modFile)
        if xmlFile ~= 0 then
            self:loadActions(xmlFile, modDesc.modName)
            delete(xmlFile)
        end
    end
end
function InputBinding:loadModBindingDefaults()
    for _, modDesc in ipairs(self.modManager:getMods()) do
        local xmlFile = loadXMLFile("InputBinding BindingDefaults ModFile", modDesc.modFile)
        if xmlFile ~= 0 then
            self:loadActionBindingsFromXML(xmlFile, true, modDesc.modName, nil, true, false)
            delete(xmlFile)
        end
    end
end
function InputBinding:assignPlatformBindingPaths()
    if GS_PLATFORM_PLAYSTATION then
        self.settingsPath = InputBinding.PATHS.DEFAULT_BINDINGS
        return
    elseif GS_PLATFORM_XBOX then
        self.settingsPath = InputBinding.PATHS.DEFAULT_BINDINGS_XBOX
        return
    elseif GS_PLATFORM_SWITCH2 then
        self.settingsPath = InputBinding.PATHS.DEFAULT_BINDINGS
        return
    elseif GS_PLATFORM_ID == PlatformId.IOS then
        self.settingsPath = InputBinding.PATHS.DEFAULT_BINDINGS_IOS
        return
    elseif GS_PLATFORM_ID == PlatformId.ANDROID then
        self.settingsPath = InputBinding.PATHS.DEFAULT_BINDINGS_ANDROID
        return
    elseif GS_PLATFORM_SWITCH then
        self.settingsPath = InputBinding.PATHS.DEFAULT_BINDINGS_SWITCH
    else
        self.settingsPath = InputBinding.PATHS.USER_BINDINGS
        self.inputBindingPathTemplate = InputBinding.PATHS.DEFAULT_BINDINGS_KB_MOUSE
        self:overwriteSettingsWithDefault(false)
        if not self:checkSettingsIntegrity(self.settingsPath, self.inputBindingPathTemplate) then
            self:overwriteSettingsWithDefault(true)
        end
    end
end
function InputBinding:overwriteSettingsWithDefault(forceOverwrite)
    copyFile(self.inputBindingPathTemplate, self.settingsPath, forceOverwrite)
end
function InputBinding:restoreInputContexts()
    for contextName, context in pairs(self.contexts) do
        local newActionEvents = {}
        for oldAction, eventList in pairs(context.actionEvents) do
            newActionEvents[self.nameActions[oldAction.name]] = eventList
        end
        if contextName == self.currentContextName then
            self.actionEvents = newActionEvents
        end
        context.actionEvents = newActionEvents
    end
end
function InputBinding:setShowMouseCursor(doShow, saveCursorPosition)
    self.saveCursorX = saveCursorPosition and self.mousePosXLast or 0.5
    self.saveCursorY = saveCursorPosition and self.mousePosYLast or 0.5
    self.mousePosXLastValid = self.mousePosXLast or self.mousePosXLastValid
    self.mousePosYLastValid = self.mousePosYLast or self.mousePosYLastValid
    self.mousePosXLast = nil
    self.mousePosYLast = nil
    setShowMouseCursor(doShow)
    self.wrapMousePositionEnabled = not doShow
end
function InputBinding:getShowMouseCursor()
    return not self.wrapMousePositionEnabled
end
function InputBinding:getInputHelpMode()
    local nonGamepadMode = GS_IS_MOBILE_VERSION and GS_INPUT_HELP_MODE_TOUCH or GS_INPUT_HELP_MODE_KEYBOARD
    if self.isConsoleVersion then
        nonGamepadMode = GS_INPUT_HELP_MODE_GAMEPAD
    elseif self.isGamepadEnabled then
        if self.inputHelpModeSetting == GS_INPUT_HELP_MODE_AUTO then
            return self.lastInputHelpMode
        elseif self.numGamepads > 0 and self.inputHelpModeSetting == GS_INPUT_HELP_MODE_GAMEPAD then
            return GS_INPUT_HELP_MODE_GAMEPAD
        else
            return nonGamepadMode
        end
    end
    return nonGamepadMode
end
function InputBinding:getLastInputMode()
    if Platform.isMobile and self.lastInputMode == GS_INPUT_HELP_MODE_KEYBOARD then
        return GS_INPUT_HELP_MODE_TOUCH
    else
        return self.lastInputMode
    end
end
function InputBinding:validateActionEventParameters(actionName, _, eventCallback, triggerUp, triggerDown, triggerAlways)
    if actionName == nil then
        Logging.devWarning("Tried registering an unknown action")
        printCallstack()
        return false
    elseif InputAction[actionName] == nil then
        Logging.devWarning("Tried registering an event for an unknown action: %s", actionName)
        return false
    elseif eventCallback then
        if triggerUp or (triggerDown or triggerAlways) then
            local action = self.nameActions[actionName]
            return (action == nil or action:getIsSupportedOnCurrentPlatform()) and true or false
        else
            Logging.devWarning("Tried registering an action event without any active trigger flags.")
            return false
        end
    else
        Logging.devWarning("Tried registering an action event without an event callback.")
        return false
    end
end
function InputBinding:registerActionEvent(actionName, targetObject, eventCallback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings, reportAnyDeviceCollision)
    local valid = self:validateActionEventParameters(actionName, targetObject, eventCallback, triggerUp, triggerDown, triggerAlways)
    local actionEvents = self.actionEvents
    local eventOrderCounter = self.contexts[self.currentContextName].eventOrderCounter
    if self.registrationContext ~= InputBinding.NO_REGISTRATION_CONTEXT then
        actionEvents = self.registrationContext.actionEvents
        eventOrderCounter = self.registrationContext.eventOrderCounter
    end
    if startActive and valid then
        local eventCollision, collidingAction = self:checkEventCollision(actionName, disableConflictingBindings, reportAnyDeviceCollision)
        if valid then
            valid = not eventCollision
        end
        if eventCollision then
            return false, "", actionEvents[collidingAction]
        end
    end
    local eventCollision = ""
    if valid then
        local collidingAction = InputEvent.new
        if triggerUp == nil then
            triggerUp = false
        end
        if triggerDown == nil then
            triggerDown = false
        end
        if triggerAlways == nil then
            triggerAlways = false
        end
        if startActive == nil then
            startActive = false
        end
        local collidingAction = collidingAction(actionName, targetObject, eventCallback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, eventOrderCounter)
        local action = self.nameActions[actionName]
        local actionEventList = actionEvents[action]
        if actionEventList == nil then
            actionEvents[action] = {}
        end
        for _, regEvent in ipairs(actionEventList) do
            if regEvent.actionName == collidingAction.actionName and regEvent:getTriggerCode() == collidingAction:getTriggerCode() then
                return false, eventCollision, { regEvent }
            end
        end
        table.insert(actionEventList, collidingAction)
        self.events[collidingAction.id] = collidingAction
        collidingAction.displayIsVisible = #actionEventList == 0
        collidingAction:initializeDisplayText(action)
        collidingAction:setIgnoreComboMask(action:getIgnoreComboMask())
        if self.registrationContext == InputBinding.NO_REGISTRATION_CONTEXT then
            self:refreshEventCollections()
            self.contexts[self.currentContextName].eventOrderCounter = eventOrderCounter + 1
        else
            self.registrationContext.eventOrderCounter = eventOrderCounter + 1
        end
    end
    return valid, eventCollision, nil
end
function InputBinding:checkEventCollision(actionName, disableConflictingBindings, reportAnyDeviceCollision)
    local testAction = self.nameActions[actionName]
    if testAction == nil then
        Logging.error("Unknown action name %q", actionName)
        return false, nil
    end
    local testBindings = testAction:getBindings()
    local actionEvents = self.actionEvents
    if self.registrationContext ~= InputBinding.NO_REGISTRATION_CONTEXT then
        actionEvents = self.registrationContext.actionEvents
    end
    local collidingAction = nil
    local disabledBindings = nil
    for otherAction, events in pairs(actionEvents) do
        local isSameCategory = table.hasSetIntersection(testAction.categories, otherAction.categories)
        local canConflict = not (testAction == otherAction)
        if canConflict then
            if isSameCategory then
                isSameCategory = not (testAction.isLocked or otherAction.isLocked)
            end
        else
            isSameCategory = canConflict
        end
        local otherHasActiveEvents = false
        for _, event in pairs(events) do
            if event.isActive then
                otherHasActiveEvents = true
                break
            end
        end
        if isSameCategory and otherHasActiveEvents then
            local otherBindings = otherAction:getActiveBindings()
            for event, testBinding in pairs(testBindings) do
                for _, otherBinding in pairs(otherBindings) do
                    if testBinding:hasEventCollision(otherBinding) then
                        if not disableConflictingBindings then
                            return true, otherAction
                        end
                        testAction:disableBinding(testBinding)
                        disabledBindings = disabledBindings or {}
                        table.insert(disabledBindings, testBinding)
                        collidingAction = otherAction
                    end
                end
            end
        end
    end
    local hasCollision = false
    if disabledBindings and #disabledBindings > 0 then
        if reportAnyDeviceCollision == true then
            return true, collidingAction
        end
        hasCollision = false
        if #testAction:getBindings() > 0 then
            hasCollision = testAction:getNumActiveBindings() == 0
        end
        if hasCollision then
            for events, isSameCategory in pairs(disabledBindings) do
                testAction:enableBinding(isSameCategory)
            end
        end
    end
    return hasCollision, collidingAction
end
function InputBinding:beginActionEventsModification(inContextName, forceCreateNew)
    if inContextName == nil or inContextName == InputBinding.NO_REGISTRATION_CONTEXT.name then
        Logging.devWarning("Cannot begin action event registration with an empty context name.")
        printCallstack()
    else
        local createdNewContext = false
        local context = self.contexts[inContextName]
        if context == nil or forceCreateNew then
            context = self:createContext(inContextName)
            createdNewContext = true
        end
        if self.debugEnabled then
            Logging.devInfo("[InputBinding] Beginning action events modification in context [%s]", inContextName)
        end
        self.registrationContext = context
        if createdNewContext then
            registerGlobalActionEvents(self)
        end
    end
end
function InputBinding:endActionEventsModification(ignoreCheck)
    if ignoreCheck or self.registrationContext ~= InputBinding.NO_REGISTRATION_CONTEXT then
        if self.debugEnabled then
            Logging.devInfo("[InputBinding] Ended action events modification in context [%s]", self.registrationContext.name)
        end
        self.registrationContext = InputBinding.NO_REGISTRATION_CONTEXT
        self:refreshEventCollections()
    else
        Logging.devWarning("Called InputBinding:endActionEventsModification() when the registration context is already reset. Check call order.")
        printCallstack()
    end
end
function InputBinding:refreshEventCollections()
    self.needsRefresh = true
    if self.markIt then
        self.markIt = false
    end
end
function InputBinding:storeDisplayActionEvents()
    self.displayActionEvents = {}
    for action, events in pairs(self.actionEvents) do
        for _, event in ipairs(events) do
            local bindings = action:getActiveBindings()
            if event.isActive and (event.displayIsVisible and #bindings > 0) then
                local firstControllerBindingIndex = Binding.MAX_ALTERNATIVES_GAMEPAD + 1
                local firstGamepadBindingIndex = Binding.MAX_ALTERNATIVES_GAMEPAD + 1
                for _, binding in pairs(bindings) do
                    local device = self.devicesByInternalId[binding.internalDeviceId]
                    if binding.isActive and device.category ~= InputDevice.CATEGORY.KEYBOARD_MOUSE then
                        if device.category == InputDevice.CATEGORY.GAMEPAD and binding.index < firstGamepadBindingIndex then
                            firstGamepadBindingIndex = binding.index
                        elseif binding.index < firstControllerBindingIndex then
                            firstControllerBindingIndex = binding.index
                        end
                    end
                end
                table.insert(self.displayActionEvents, {
                    ["action"] = action,
                    ["event"] = event,
                    ["inlineModifierButtons"] = firstControllerBindingIndex < firstGamepadBindingIndex
                })
                break
            end
        end
    end
end
local function sortEventByOrderValue(event1, event2)
    if event1.orderValue == event2.orderValue then
        return event1.id < event2.id
    else
        return event1.orderValue < event2.orderValue
    end
end
function InputBinding:storeEventBindings()
    -- upvalues: (copy) sortEventByOrderValue
    for k in pairs(self.activeBindings) do
        self.activeBindings[k] = nil
    end
    for k in pairs(self.eventBindings) do
        self.eventBindings[k] = nil
    end
    for k in pairs(self.eventOrder) do
        self.eventOrder[k] = nil
    end
    for k, eventList in pairs(self.actionEvents) do
        local bindings = k:getActiveBindings()
        for _, event in pairs(eventList) do
            if event.isActive then
                local activeEventBindings = self.eventBindings[event]
                if not activeEventBindings then
                    self.eventBindings[event] = {}
                end
                for _, binding in ipairs(bindings) do
                    if binding.isActive then
                        table.insert(activeEventBindings, binding)
                        self.activeBindings[binding] = binding
                    end
                end
                table.insert(self.eventOrder, event)
            end
        end
    end
    table.sort(self.eventOrder, sortEventByOrderValue)
    self.needUpdateAbort = true
end
function InputBinding:iterateEvents(processingFunction)
    local actionEvents = self.actionEvents
    if self.registrationContext ~= InputBinding.NO_REGISTRATION_CONTEXT then
        actionEvents = self.registrationContext.actionEvents
    end
    for action, eventList in pairs(actionEvents) do
        local i = #eventList
        for i = i, 1, -1 do
            if processingFunction(eventList[i], action.name, eventList, i) then
                return
            end
        end
    end
end
function InputBinding:removeEventInternal(event, eventList, index)
    if event.triggerAlways then
        local eventBindings = self.eventBindings[event]
        if eventBindings ~= nil then
            for _, binding in pairs(eventBindings) do
                self:neutralizeEventBindingInput(event, binding)
            end
        end
    end
    self.events[event.id] = nil
    table.remove(eventList, index)
end
function InputBinding:removeActionEvent(eventId)
    local hasChange = false
    self:iterateEvents(function(event, _, eventList, index)
        -- upvalues: (copy) eventId, (copy) self, (ref) hasChange
        if event.id == eventId then
            self:removeEventInternal(event, eventList, index)
            hasChange = true
            return true
        end
    end)
    if hasChange then
        self:refreshEventCollections()
    end
end
function InputBinding:removeActionEventsByActionName(actionName)
    local hasChange = false
    self:iterateEvents(function(event, _, eventList, index)
        -- upvalues: (copy) actionName, (copy) self, (ref) hasChange
        if event.actionName == actionName then
            self:removeEventInternal(event, eventList, index)
            hasChange = true
        end
    end)
    if hasChange then
        self:refreshEventCollections()
    end
end
function InputBinding:removeActionEventsByTarget(targetObject)
    local hasChange = false
    self:iterateEvents(function(event, _, eventList, index)
        -- upvalues: (copy) targetObject, (copy) self, (ref) hasChange
        if event.targetObject == targetObject then
            self:removeEventInternal(event, eventList, index)
            hasChange = true
        end
    end)
    if hasChange then
        self:refreshEventCollections()
    end
end
function InputBinding:getActionEventsHasBinding(actionEventId)
    local event = self.events[actionEventId]
    if event == nil then
        return false
    end
    return self:getNumActiveBindings(event.actionName) > 0
end
function InputBinding:getDisplayActionEvents()
    return self.displayActionEvents
end
function InputBinding:setActionEventText(eventId, actionText)
    local event = self.events[eventId]
    local hasChange = false
    if event then
        hasChange = event.contextDisplayText ~= actionText
        event.contextDisplayText = actionText
    end
    if hasChange then
        self:refreshEventCollections()
    end
end
function InputBinding:setActionEventIcon(eventId, iconName)
    local event = self.events[eventId]
    local hasChange = false
    if event then
        hasChange = event.contextDisplayIconName ~= iconName
        event.contextDisplayIconName = iconName
    end
    if hasChange then
        self:refreshEventCollections()
    end
end
function InputBinding:setActionEventTextVisibility(eventId, isVisible)
    local event = self.events[eventId]
    local hasChange = false
    if event then
        hasChange = event.displayIsVisible ~= isVisible
        event.displayIsVisible = isVisible
    end
    if hasChange then
        self:refreshEventCollections()
    end
end
function InputBinding:setActionEventTextPriority(eventId, priority)
    local event = self.events[eventId]
    local hasChange = false
    if event and type(priority) == "number" then
        hasChange = event.displayPriority ~= priority
        event.displayPriority = priority
    end
    if hasChange then
        self:refreshEventCollections()
    end
end
function InputBinding:setActionEventActive(eventId, isActive)
    self:setEventActive(self.events[eventId], isActive)
end
function InputBinding:setEventActive(event, isActive)
    local hasChange = false
    if event then
        event.isActive = isActive
        if event.isActive ~= isActive then
            if isActive then
                self:checkEventCollision(event.actionName, true)
            else
                self.nameActions[event.actionName]:resetActiveBindings()
            end
        end
    end
    if hasChange then
        self:refreshEventCollections()
    end
end
function InputBinding:setActionEventsActiveByTarget(targetObject, isActive)
    local hasChange = false
    self:iterateEvents(function(event)
        -- upvalues: (copy) targetObject, (ref) hasChange, (copy) isActive, (copy) self
        if event.targetObject == targetObject then
            event.isActive = isActive
            if event.isActive ~= isActive then
                if isActive then
                    self:checkEventCollision(event.actionName, true)
                    return
                end
                self.nameActions[event.actionName]:resetActiveBindings()
            end
        end
    end)
    if hasChange then
        self:refreshEventCollections()
    end
end
function InputBinding:getComboCommandPressedMask()
    local comboMaskGamepad = 0
    local comboMaskMouse = 0
    if self.numGamepads > 0 then
        for actionName, maskControls in pairs(InputBinding.GAMEPAD_COMBOS) do
            local comboActionBinding = self.comboInputBindings[actionName]
            if comboActionBinding ~= nil and (comboActionBinding.isPressed and comboMaskGamepad < maskControls.mask) then
                comboMaskGamepad = maskControls.mask
            end
        end
    end
    if not self.isConsoleVersion then
        for actionName, maskControls in pairs(InputBinding.MOUSE_COMBOS) do
            if self.comboInputBindings[actionName].isPressed and comboMaskMouse < maskControls.mask then
                comboMaskMouse = maskControls.mask
            end
        end
    end
    return comboMaskGamepad, comboMaskMouse
end
function InputBinding:getComboActionNameForAxisSet(modifierAxisSet)
    for comboSet, comboActionName in pairs(self.comboInputActions) do
        if table.equalSets(comboSet, modifierAxisSet) then
            return comboActionName
        end
    end
    return nil
end
function InputBinding:getInternalIdByDeviceId(deviceId)
    return self.deviceIdToInternal[deviceId]
end
function InputBinding:getDeviceByInternalId(internalDeviceId)
    return self.devicesByInternalId[internalDeviceId]
end
function InputBinding:getDeviceById(deviceId)
    local device = nil
    local internalId = self.deviceIdToInternal[deviceId]
    if internalId ~= nil then
        device = self.devicesByInternalId[internalId]
    end
    return device
end
function InputBinding:getMissingDeviceById(deviceId)
    return self.missingDevices[deviceId]
end
function InputBinding:getHasMissingDevices()
    return next(self.missingDevices) ~= nil
end
function InputBinding:assignLastInputHelpMode(inputHelpMode, force)
    self.lastInputMode = inputHelpMode
    if self.lastInputMode ~= inputHelpMode and true or force then
        self:notifyInputModeChange(inputHelpMode, false)
    end
    if inputHelpMode == GS_INPUT_HELP_MODE_KEYBOARD or self.timeSinceLastInputHelpModeChange >= InputBinding.INPUT_MODE_CHANGE_MIN_INTERVAL then
        local needInputHelpModeNotification = self.lastInputHelpMode ~= inputHelpMode and true or force
        self.lastInputHelpMode = inputHelpMode
        if needInputHelpModeNotification then
            self:notifyInputModeChange(inputHelpMode, true)
        end
        if needInputHelpModeNotification or inputHelpMode == GS_INPUT_HELP_MODE_KEYBOARD then
            self.timeSinceLastInputHelpModeChange = 0
        end
    end
    if GS_IS_MOBILE_VERSION and self.lastInputHelpMode == GS_INPUT_HELP_MODE_KEYBOARD then
        self.lastInputHelpMode = GS_INPUT_HELP_MODE_TOUCH
    end
end
function InputBinding:keyEvent(_, _, _, _)
    self:assignLastInputHelpMode(GS_INPUT_HELP_MODE_KEYBOARD)
end
function InputBinding:mouseEvent(posX, posY, isDown, isUp, button)
    if isDown then
        self:assignLastInputHelpMode(GS_IS_MOBILE_VERSION and GS_INPUT_HELP_MODE_TOUCH or GS_INPUT_HELP_MODE_KEYBOARD)
    end
    if self.mousePosXLast == nil or self.mousePosYLast == nil then
        self.mousePosXLast = posX
        self.mousePosYLast = posY
    end
    self.mouseMovementX = self.mouseMotionScaleX * (posX - self.mousePosXLast)
    self.mouseMovementY = self.mouseMotionScaleY * (posY - self.mousePosYLast) / g_screenAspectRatio
    self.mousePosXLast = posX
    self.mousePosYLast = posY
    self.accumMouseMovementX = self.accumMouseMovementX + self.mouseMovementX
    self.accumMouseMovementY = self.accumMouseMovementY + self.mouseMovementY
    if isDown then
        self.mouseButtonLast = button
        self.mouseButtonStateLast = true
    elseif isUp then
        self.mouseButtonLast = Input.MOUSE_BUTTON_NONE
        self.mouseButtonStateLast = false
    end
end
function InputBinding:touchEvent(_, _, _, _, _)
    self:assignLastInputHelpMode(GS_INPUT_HELP_MODE_TOUCH)
end
function InputBinding:getMousePosition()
    return self.mousePosXLast or self.saveCursorX, self.mousePosYLast or self.saveCursorY
end
function InputBinding:getMouseButtonState()
    return self.mouseButtonLast, self.mouseButtonStateLast
end
function InputBinding:startBindingChanges()
    self.originalActionBindings = {}
    for _, action in pairs(self.actions) do
        local bindings = action:getBindings()
        local clonedBindings = {}
        for _, binding in pairs(bindings) do
            table.insert(clonedBindings, binding:clone())
        end
        self.originalActionBindings[action] = clonedBindings
    end
end
function InputBinding:commitBindingChanges()
    self.originalActionBindings = nil
    self:assignComboMasks()
    self:assignActionPrimaryBindings()
    self:notifyBindingChanges()
    self:refreshEventCollections()
end
function InputBinding:rollbackBindingChanges()
    local newLoadedBindings = {}
    for _, bindings in pairs(self.originalActionBindings) do
        for _, binding in pairs(bindings) do
            binding:makeId()
            local loadedBinding = newLoadedBindings[binding.id]
            if loadedBinding == nil then
                newLoadedBindings[binding.id] = binding
            else
                local binding = loadedBinding
            end
            local oldLoadedBinding = self.loadedBindings[binding.id]
            if oldLoadedBinding ~= nil then
                binding:copyInputStateFrom(oldLoadedBinding)
            end
        end
    end
    self.loadedBindings = newLoadedBindings
    for _, bindings in pairs(self.originalActionBindings) do
        _:clearBindings()
        for _, binding in pairs(bindings) do
            _:addBinding(self.loadedBindings[binding.id])
        end
    end
    self:storeEventBindings()
end
function InputBinding:startInputCapture(isKeyboard, isMouse, callbackTarget, callbackState, inputCallback, abortCallback, deleteCallback)
    self.isInputCapturing = true
    self.gatherInputStoredMouseEvent = mouseEvent
    self.gatherInputStoredKeyEvent = keyEvent
    self.gatherInputStoredUpdate = update
    if isKeyboard then
        self:captureKeyboardInput(function()
            -- upvalues: (copy) callbackTarget, (copy) abortCallback
            if callbackTarget then
                abortCallback(callbackTarget)
            else
                abortCallback()
            end
        end, function()
            -- upvalues: (copy) callbackTarget, (copy) deleteCallback, (copy) callbackState
            if callbackTarget then
                deleteCallback(callbackTarget, callbackState)
            else
                deleteCallback(callbackState)
            end
        end, function(deviceId, axisName, inputValue, initInputValue)
            -- upvalues: (copy) callbackTarget, (copy) inputCallback, (copy) callbackState
            if callbackTarget then
                inputCallback(callbackTarget, deviceId, axisName, inputValue, initInputValue, callbackState)
            else
                inputCallback(axisName, deviceId, inputValue, initInputValue, callbackState)
            end
        end)
        function mouseEvent() end
        function update()
            setTextWidthScale(g_textWidthScale)
        end
        return
    elseif isMouse then
        self:captureKeyboardInput(cbAbort, cbDelete)
        self:captureMouseInput(cbInput)
        function update()
            setTextWidthScale(g_textWidthScale)
        end
    else
        self:captureKeyboardInput(cbAbort, cbDelete)
        self:captureGamepadInput(cbInput)
        function mouseEvent() end
    end
end
function InputBinding.captureKeyboardInput(_, abortCallback, deleteCallback, inputCallback)
    local device = InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT
    function keyEvent(_, sym, _, isDown)
        -- upvalues: (copy) abortCallback, (copy) deleteCallback, (copy) inputCallback, (copy) device
        if abortCallback and sym == Input.KEY_esc then
            abortCallback()
            return
        elseif deleteCallback and sym == Input.KEY_backspace then
            deleteCallback()
        elseif inputCallback and Input.keyIdToIdName[sym] then
            inputCallback(device, keyName, isDown and 1 or 0)
        end
    end
end
function InputBinding:captureMouseInput(callback)
    local dragStartX = nil
    local dragStartY = nil
    local draggingButton = nil
    local startX = self.mousePosXLast or self.mousePosXLastValid
    local startY = self.mousePosYLast or self.mousePosYLastValid
    local device = InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT
    local axisNameX = InputBinding.MOUSE_AXIS_NAMES[Input.AXIS_X]
    local axisNameY = InputBinding.MOUSE_AXIS_NAMES[Input.AXIS_Y]
    callback(device, axisNameX, false, 0)
    callback(device, axisNameY, false, 0)
    function mouseEvent(posX, posY, isDown, isUp, button)
        -- upvalues: (ref) draggingButton, (ref) dragStartX, (ref) dragStartY, (copy) callback, (copy) device, (copy) axisNameX, (copy) axisNameY, (ref) startX, (ref) startY
        if button == Input.MOUSE_BUTTON_WHEEL_UP or button == Input.MOUSE_BUTTON_WHEEL_DOWN then
            callback(device, Input.mouseButtonIdToIdName[button], 1)
            callback(device, buttonName, 0)
        elseif isDown then
            if draggingButton == nil then
                draggingButton = button
                dragStartX = posX
                dragStartY = posY
                callback(device, axisNameX, 0)
                callback(device, axisNameY, 0)
            end
            callback(device, buttonName, 1)
        elseif isUp then
            callback(device, buttonName, 0)
            if button == draggingButton then
                draggingButton = nil
                dragStartX = nil
                dragStartY = nil
            end
        end
        if draggingButton ~= nil then
            startX = posX
            startY = posY
        end
        local buttonIsDragging = startX
        local origY = startY
        if draggingButton ~= nil then
            buttonIsDragging = dragStartX
            origY = dragStartY
        end
        callback(device, axisNameX, posX - buttonIsDragging)
        callback(device, axisNameY, posY - origY)
    end
end
function InputBinding:captureGamepadInput(callback)
    local gamepadInitStates = {}
    function update(dt)
        -- upvalues: (copy) gamepadInitStates, (copy) self, (copy) callback
        setTextWidthScale(g_textWidthScale)
        local numGamepads = getNumOfGamepads()
        local numGamepads
        if numGamepads == #gamepadInitStates then
        else
            for k, _ in pairs(gamepadInitStates) do
                gamepadInitStates[k] = nil
            end
            local d = 1
            for d = d, numGamepads do
                local k = {
                    ["axes"] = {},
                    ["buttons"] = {}
                }
                table.insert(gamepadInitStates, k)
                local i = 1
                for i = i, Input.MAX_NUM_BUTTONS do
                    local isDown = getInputButton(i - 1, d - 1) > 0
                    if isDown then
                        k.buttons[i] = true
                    end
                end
                local i = 1
                for i = i, Input.MAX_NUM_AXES do
                    k.axes[i] = getInputAxis(i - 1, d - 1)
                    if Input.isHalfAxis(i - 1) then
                        k.axes[i] = (1 - k.axes[i]) * 0.5
                    end
                end
            end
        end
        local d = 1
        for d = d, numGamepads do
            local k = d - 1
            local _ = self.internalToDeviceId[k]
            if _ ~= nil then
                local i = {}
                local i = 1
                for i = i, Input.MAX_NUM_AXES do
                    local input = getInputAxis(i - 1, k)
                    if Input.isHalfAxis(i - 1) then
                    end
                    callback(_, Input.axisIdToIdName[i - 1], input, gamepadInitStates[d].axes[i])
                end
                local i = 1
                for i = i, Input.MAX_NUM_BUTTONS do
                    local axisInit = getInputButton(i - 1, k) > 0
                    if axisInit then
                        if not initState.buttons[i] then
                            i[i - 1] = true
                            callback(_, Input.buttonIdToIdName[i - 1], 1, 0)
                        end
                    else
                        initState.buttons[i] = nil
                        callback(_, input, 0, 0)
                    end
                end
            end
        end
    end
end
function InputBinding:stopInputGathering()
    if self.isInputCapturing then
        mouseEvent = self.gatherInputStoredMouseEvent
        keyEvent = self.gatherInputStoredKeyEvent
        update = self.gatherInputStoredUpdate
        self.gatherInputCallbackFunction = nil
        self.gatherInputCallbackObject = nil
        self.gatherInputStoredMouseEvent = nil
        self.gatherInputStoredKeyEvent = nil
        self.gatherInputStoredUpdate = nil
        self.isInputCapturing = false
    end
end
function InputBinding:restoreDefaultBindings()
    copyFile(self.inputBindingPathTemplate, self.settingsPath, true)
    self:load()
    self:refresh()
end
function InputBinding:clearState()
    self.loadedBindings = {}
    self.eventBindings = {}
    self.nameActions = {}
    self.actions = {}
    self.missingDevices = {}
    self.gamepadInputState = {}
    local defaultInputMode = GS_INPUT_HELP_MODE_KEYBOARD
    if self.isConsoleVersion then
        defaultInputMode = GS_INPUT_HELP_MODE_GAMEPAD
    elseif GS_IS_MOBILE_VERSION then
        defaultInputMode = GS_INPUT_HELP_MODE_TOUCH
    end
    self.lastInputMode = defaultInputMode
    self.lastInputHelpMode = defaultInputMode
end
function InputBinding:loadActions(xmlFile, modName)
    local rootPath = "actions"
    local i18n = g_i18n
    if modName then
        rootPath = "modDesc.actions"
        i18n = _G[modName].g_i18n
    end
    self:loadActionsFromXMLPath(xmlFile, rootPath, i18n, modName)
end
function InputBinding:loadActionsFromXMLPath(xmlFile, rootPath, i18n, modName)
    local actionIndex = 0
    while true do
        local actionPath = rootPath .. string.format(".action(%d)", actionIndex)
        if not hasXMLProperty(xmlFile, actionPath) then
            return
        end
        local action = InputAction.createFromXML(xmlFile, actionPath)
        if action ~= nil then
            local inputSymbol = string.format("input_%s", action.name)
            local modPart = modName and string.format(" in mod \'%s\'", modName) or ""
            if modName ~= nil then
                action.displayCategory = g_modManager:getModByName(modName).title
            end
            action.displayNamePositive = action.name
            action.displayNameNegative = action.name
            local mod = false
            if InputBinding.MOUSE_COMBOS[action.name] ~= nil then
                mod = InputBinding.GAMEPAD_COMBOS[action.name] ~= nil
            end
            local needLocalization = not mod
            if needLocalization then
                needLocalization = not action.isLocked
            end
            if action.axisType == InputAction.AXIS_TYPE.FULL then
                local symbolPositive = inputSymbol .. InputBinding.SYMBOL_AFFIX_POSITIVE
                local symbolNegative = inputSymbol .. InputBinding.SYMBOL_AFFIX_NEGATIVE
                if i18n:hasText(symbolPositive) then
                    action.displayNamePositive = i18n:getText(symbolPositive)
                elseif needLocalization then
                    Logging.warning("Missing l10n \'%s\'%s", symbolPositive, modPart)
                end
                if i18n:hasText(symbolNegative) then
                    action.displayNameNegative = i18n:getText(symbolNegative)
                elseif needLocalization then
                    Logging.warning("Missing l10n \'%s\'%s", symbolNegative, modPart)
                end
            elseif i18n:hasText(inputSymbol) then
                action.displayNamePositive = i18n:getText(inputSymbol)
            elseif needLocalization then
                Logging.warning("Missing l10n \'%s\'%s", inputSymbol, modPart)
            end
            if self.nameActions[action.name] == nil then
                table.insert(self.actions, action)
            else
                local i = 1
                for i = i, #self.actions do
                    local action2 = self.actions[i]
                    if action2.name == action.name then
                        action.bindings = action2.bindings
                        action:resetActiveBindings()
                        self.actions[i] = action
                        break
                    end
                end
            end
            self.nameActions[action.name] = action
        end
        actionIndex = actionIndex + 1
    end
end
function InputBinding:resetDeviceInformation()
    self.devicesByInternalId = {}
    self.devicesByCategory = {}
    self.deviceIdToInternal = {}
    self.internalToDeviceId = {}
    return self.devicesByInternalId
end
function InputBinding:createDefaultDevices()
    local kbMouseDevice = InputDevice.new(InputBinding.KB_MOUSE_INTERNAL_ID, InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT, InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT, InputDevice.CATEGORY.KEYBOARD_MOUSE)
    kbMouseDevice.isActive = not self.isConsoleVersion
    self.devicesByInternalId[InputBinding.KB_MOUSE_INTERNAL_ID] = kbMouseDevice
    self.devicesByCategory[InputDevice.CATEGORY.KEYBOARD_MOUSE] = { kbMouseDevice }
    self.deviceIdToInternal[kbMouseDevice.deviceId] = InputBinding.KB_MOUSE_INTERNAL_ID
end
function InputBinding:enumerateGamepadDevices(previousDevices)
    self.engineDeviceIdCounts = {}
    self.numGamepads = getNumOfGamepads()
    self.numActiveGamepads = 0
    self.internalIdToEngineDeviceId = {}
    g_ignitionLockManager:reset()
    local internalId = 0
    for internalId = internalId, self.numGamepads - 1 do
        local engineDeviceId = getGamepadId(internalId)
        local deviceName = getGamepadName(internalId)
        self.internalIdToEngineDeviceId[internalId] = engineDeviceId
        if InputDevice.getIsDeviceSupported(engineDeviceId, deviceName) then
            local existingPrefix, baseDeviceId = InputDevice.getDeviceIdPrefix(engineDeviceId)
            if existingPrefix < 0 then
                baseDeviceId = engineDeviceId
            end
            local count = self.engineDeviceIdCounts[baseDeviceId] or 0
            self.engineDeviceIdCounts[baseDeviceId] = count + 1
            local deviceCategory
            if existingPrefix >= 0 then
                deviceCategory = engineDeviceId
            else
                deviceCategory = InputDevice.getPrefixedDeviceId(baseDeviceId, count)
            end
            self.deviceIdToInternal[deviceCategory] = internalId
            self.internalToDeviceId[internalId] = deviceCategory
            self.numActiveGamepads = self.numActiveGamepads + 1
            local deviceCategory = InputBinding.getDeviceCategory(internalId)
            local device = InputDevice.new(internalId, deviceCategory, deviceName, deviceCategory)
            self.devicesByInternalId[internalId] = device
            if not self.devicesByCategory[deviceCategory] then
                self.devicesByCategory[deviceCategory] = {}
            end
            table.insert(self.devicesByCategory[deviceCategory], device)
        end
        g_ignitionLockManager:tryToAddDevice(internalId, engineDeviceId, deviceName)
    end
    for engineDeviceId, deviceName in pairs(previousDevices) do
        if not self.deviceIdToInternal[deviceName.deviceId] then
            deviceName.internalId = -1
            self.missingDevices[deviceName.deviceId] = deviceName
        end
    end
end
function InputBinding:getGamepadDevices()
    local deviceList = {}
    for _, device in pairs(self.devicesByInternalId) do
        if device:isController() then
            table.insert(deviceList, {
                ["deviceId"] = device.deviceId,
                ["name"] = device.deviceName
            })
        end
    end
    return deviceList
end
function InputBinding:loadDeviceSettingsFromXML(xmlFile)
    local elementIndex = 0
    while true do
        local deviceElement = string.format("inputBinding.devices.device(%d)", elementIndex)
        if not hasXMLProperty(xmlFile, deviceElement) then
            break
        end
        local deviceId = InputDevice.loadIdFromXML(xmlFile, deviceElement);
        ({})[deviceId] = true
        local deviceInternalId = self.deviceIdToInternal[deviceId]
        if deviceInternalId then
            local device = self.devicesByInternalId[deviceInternalId]
            device:loadSettingsFromXML(xmlFile, deviceElement)
            local xmlCategory = InputDevice.loadCategoryFromXML(xmlFile, deviceElement)
            if xmlCategory == InputDevice.CATEGORY.UNKNOWN and xmlCategory ~= device.category then
                self.devicesToMigrateCategory[deviceId] = device
            end
        elseif deviceId and deviceId ~= "" then
            local device = InputDevice.loadCategoryFromXML(xmlFile, deviceElement)
            local xmlCategory = InputDevice.loadNameFromXML(xmlFile, deviceElement)
            local device = InputDevice.new(-1, deviceId, xmlCategory, device)
            device:loadSettingsFromXML(xmlFile, deviceElement)
            self.missingDevices[deviceId] = device
        end
        elementIndex = elementIndex + 1
    end
    for device in pairs(self.deviceIdToInternal) do
        if not hasLoadedDevice[device] then
            self.newlyConnectedDevices[device] = true
        end
    end
end
function InputBinding:applyGamepadDeadzones()
    if GS_PLATFORM_PC then
        for _, device in pairs(self.devicesByInternalId) do
            if device:isController() then
                local axis = 0
                for axis = axis, Input.MAX_NUM_AXES - 1 do
                    setGamepadDeadzone(0, device.internalId, axis)
                end
            end
        end
    end
end
function InputBinding:initializeGamepadMapping(xmlFile)
    local previousDevices = self:resetDeviceInformation()
    self:createDefaultDevices()
    self:enumerateGamepadDevices(previousDevices)
    if xmlFile ~= nil then
        self:loadDeviceSettingsFromXML(xmlFile)
    end
    self:applyGamepadDeadzones()
end
function InputBinding:validateAndRepairComboActionBindings()
    for _, action in pairs(self.actions) do
        local bindings = action:getBindings()
        local comboAxisNames = nil
        local comboBindingIndex = 1
        local comboBindingDevice = nil
        local comboBindingDeviceCategory = InputDevice.CATEGORY.UNKNOWN
        if self.numGamepads > 0 and InputBinding.GAMEPAD_COMBO_BINDINGS[action.name] then
            comboAxisNames = InputBinding.GAMEPAD_COMBO_BINDINGS[action.name]
            comboBindingDevice = InputDevice.DEFAULT_DEVICE_NAMES.GAMEPAD_DEFAULT
        elseif not self.isConsoleVersion and InputBinding.MOUSE_COMBO_BINDINGS[action.name] then
            comboAxisNames = InputBinding.MOUSE_COMBO_BINDINGS[action.name]
            comboBindingIndex = Binding.MAX_ALTERNATIVES_KB_MOUSE
            comboBindingDevice = InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT
        end
        if comboAxisNames then
            local axisNames = table.clone(comboAxisNames)
            for k in pairs(bindings) do
                bindings[k] = nil
            end
            local newBinding = Binding.new(comboBindingDevice, axisNames, Binding.AXIS_COMPONENT.POSITIVE, Binding.INPUT_COMPONENT.POSITIVE, 0, comboBindingIndex)
            table.insert(bindings, newBinding)
            local comboBinding = bindings[1]
            local internalDeviceId = self.deviceIdToInternal[comboBinding.deviceId]
            if internalDeviceId ~= nil then
                comboBindingDevice = comboBinding.deviceId
                comboBindingDeviceCategory = self.devicesByInternalId[internalDeviceId].category
            end
            comboBinding:setIndex(comboBindingIndex)
            comboBinding:updateData(comboBindingDevice, comboBindingDeviceCategory, axisNames, Binding.INPUT_COMPONENT.POSITIVE)
            comboBinding:setActive((self:resolveBindingDefaultDevice(comboBinding, nil)))
            comboBinding:makeId()
        end
    end
end
function InputBinding:loadActionBindingsFromXML(xmlFile, silentIgnoreDuplicates, modName, disallowedDeviceIds, requireUnknownBindings, markActionKnown)
    self:loadActionBindingsFromXMLPath(xmlFile, modName and "modDesc.inputBinding" or "inputBinding", silentIgnoreDuplicates, disallowedDeviceIds, requireUnknownBindings, markActionKnown)
end
function InputBinding:loadActionBindingsFromXMLPath(xmlFile, rootPath, silentIgnoreDuplicates, disallowedDeviceIds, requireUnknownBindings, markActionKnown)
    local actionIndex = 0
    while true do
        local actionPath = string.format("%s.actionBinding(%d)", rootPath, actionIndex)
        if not hasXMLProperty(xmlFile, actionPath) then
            break
        end
        local actionName = getXMLString(xmlFile, actionPath .. "#action")
        if actionName and actionName ~= "" then
            local action = self.nameActions[actionName]
            if action and not (action.bindingsKnown and requireUnknownBindings) then
                if markActionKnown then
                    action.bindingsKnown = true
                end
                self:loadBindingsFromXML(xmlFile, actionPath, action, silentIgnoreDuplicates, disallowedDeviceIds)
            end
        end
        actionIndex = actionIndex + 1
    end
end
function InputBinding:loadBindingsFromXML(xmlFile, actionPath, action, silentIgnoreDuplicates, disallowedDeviceIds)
    local bindingIndex = 0
    while true do
        local bindingPath = actionPath .. string.format(".binding(%d)", bindingIndex)
        if not hasXMLProperty(xmlFile, bindingPath) then
            break
        end
        local binding = Binding.createFromXML(xmlFile, bindingPath)
        if self:resolveBindingDefaultDevice(binding, disallowedDeviceIds) then
            self:addBinding(action, binding, silentIgnoreDuplicates)
        end
        bindingIndex = bindingIndex + 1
    end
end
function InputBinding:storeComboInputMappings()
    self.comboInputAxisMasks = {}
    self.comboInputActions = {}
    self.comboInputBindings = {}
    for _, deviceCombos in pairs(not self.isConsoleVersion and { InputBinding.GAMEPAD_COMBOS, InputBinding.MOUSE_COMBOS } or { InputBinding.GAMEPAD_COMBOS }) do
        for comboActionName, combo in pairs(deviceCombos) do
            local comboAction = self.nameActions[comboActionName]
            if comboAction then
                local validComboBinding = nil
                for _, binding in ipairs(comboAction:getBindings()) do
                    if binding.isActive and (self.devicesByInternalId[binding.internalDeviceId].category == InputDevice.CATEGORY.GAMEPAD or binding.isMouse) then
                        validComboBinding = binding
                        break
                    end
                end
                if validComboBinding ~= nil then
                    self.comboInputAxisMasks[validComboBinding.axisNameSet] = combo.mask
                    self.comboInputActions[validComboBinding.axisNameSet] = comboActionName
                    self.comboInputBindings[comboActionName] = validComboBinding
                end
            end
        end
    end
end
function InputBinding:getBindingComboMask(binding)
    for comboSet, mask in pairs(self.comboInputAxisMasks) do
        if table.equalSets(comboSet, binding.modifierAxisSet) then
            return mask
        end
    end
    return 0
end
function InputBinding:assignComboMasks()
    for _, action in pairs(self.actions) do
        local bindings = action:getActiveBindings()
        action.comboMaskMouse = 0
        action.comboMaskGamepad = 0
        for _, binding in pairs(bindings) do
            local bindingComboMask = self:getBindingComboMask(binding)
            if binding.isMouse then
                if InputBinding.MOUSE_COMBOS[action.name] == nil then
                    action.comboMaskMouse = bindingComboMask
                    binding:setComboMask(bindingComboMask)
                end
            elseif binding.isActive then
                local isPrimaryGamepadBinding = false
                if self.devicesByInternalId[binding.internalDeviceId].category == InputDevice.CATEGORY.GAMEPAD then
                    isPrimaryGamepadBinding = binding.isGamepad
                end
                if isPrimaryGamepadBinding and InputBinding.GAMEPAD_COMBOS[action.name] ~= nil then
                    action.comboMaskGamepad = bindingComboMask
                    binding:setComboMask(bindingComboMask)
                end
            end
        end
    end
end
function InputBinding:storeLinkedBindings()
    for _, action in pairs(self.actions) do
        local linkedActionName = InputAction.LINKED_ACTIONS[action.name]
        if linkedActionName ~= nil then
            for _, binding in pairs(action:getBindings()) do
                local links = self.linkedBindings[binding]
                if links == nil then
                    self.linkedBindings[binding] = {}
                end
                local linkedBindings = self.nameActions[linkedActionName]:getBindings()
                for _, linkedBinding in pairs(linkedBindings) do
                    if linkedBinding.deviceId == binding.deviceId and linkedBinding.index == binding.index then
                        table.insert(links, linkedBinding)
                    end
                end
            end
        end
    end
end
function InputBinding:assignActionPrimaryBindings()
    for _, action in pairs(self.actions) do
        local bindings = action:getActiveBindings()
        for _, binding in pairs(bindings) do
            if binding.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT and binding.index == 1 then
                action:setPrimaryKeyboardBinding(binding)
            end
        end
    end
end
function InputBinding.adjustBindingSlotIndex(_, binding, action)
    if binding.index >= 1 then
        return true
    end
    local isKbMouse = binding.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT
    if isKbMouse and InputBinding.getIsMouseInput(binding.axisNames) then
        if action:getBindingAtSlot(binding.axisComponent, isKbMouse, Binding.MAX_ALTERNATIVES_KB_MOUSE) == nil then
            binding:setIndex(Binding.MAX_ALTERNATIVES_KB_MOUSE)
            return true
        end
    else
        local maxBindings
        if isKbMouse then
            maxBindings = Binding.MAX_ALTERNATIVES_KB_MOUSE - 1
        else
            maxBindings = Binding.MAX_ALTERNATIVES_GAMEPAD
        end
        local i = 1
        for i = i, maxBindings do
            if action:getBindingAtSlot(binding.axisComponent, isKbMouse, i) == nil then
                binding:setIndex(i)
                return true
            end
        end
    end
    return false
end
function InputBinding:upgradeBindingVersion(xmlFileInputBinding)
    if (getXMLInt(xmlFileInputBinding, "inputBinding#bindingVersion") or 0) == 0 then
        for _, action in pairs(self.actions) do
            local bindingsCopy = {}
            for bindingI, binding in pairs(action.bindings) do
                bindingsCopy[bindingI] = binding
            end
            for bindingI, binding in pairs(bindingsCopy) do
                if binding.isGamepad then
                    local device = nil
                    local internalId = self.deviceIdToInternal[binding.deviceId]
                    if internalId then
                        device = self.devicesByInternalId[internalId]
                    end
                    local device = device or self.missingDevices[binding.deviceId]
                    if device and device.category == InputDevice.CATEGORY.UNKNOWN then
                        local newAxisNames = {}
                        local changed = false
                        for _, axisName in ipairs(binding.axisNames) do
                            local sign = axisName:sub(axisName:len())
                            local axisNameNoSign
                            if sign == "+" or sign == "-" then
                                axisNameNoSign = axisName:sub(1, axisName:len() - 1)
                            else
                                sign = ""
                                axisNameNoSign = axisName
                            end
                            local axisName
                            if axisNameNoSign == "HALF_AXIS_1" or axisNameNoSign == "AXIS_11" then
                                axisName = "AXIS_2-"
                                changed = true
                            elseif axisNameNoSign == "HALF_AXIS_2" or axisNameNoSign == "AXIS_12" then
                                axisName = "AXIS_2+"
                                changed = true
                            elseif axisNameNoSign == "AXIS_2" then
                                axisName = "AXIS_7" .. sign
                                changed = true
                            elseif axisNameNoSign == "AXIS_7" then
                                axisName = "AXIS_8" .. sign
                                changed = true
                            elseif axisNameNoSign == "BUTTON_21" then
                                axisName = "BUTTON_25"
                                changed = true
                            elseif axisNameNoSign == "BUTTON_22" then
                                axisName = "BUTTON_26"
                                changed = true
                            elseif axisNameNoSign == "BUTTON_23" then
                                axisName = "BUTTON_27"
                                changed = true
                            elseif axisNameNoSign == "BUTTON_24" then
                                axisName = "BUTTON_28"
                                changed = true
                            elseif axisNameNoSign == "BUTTON_25" then
                                axisName = "BUTTON_29"
                                changed = true
                            elseif axisNameNoSign == "BUTTON_26" then
                                axisName = "BUTTON_30"
                                changed = true
                            elseif axisNameNoSign == "BUTTON_27" then
                                axisName = "BUTTON_31"
                                changed = true
                            elseif axisNameNoSign == "BUTTON_28" then
                                axisName = "BUTTON_32"
                                changed = true
                            end
                            table.insert(newAxisNames, axisName)
                        end
                        if changed and #newAxisNames > 0 then
                            local lastAxisName = newAxisNames[#newAxisNames]
                            local inputComponent = Binding.INPUT_COMPONENT.POSITIVE
                            if lastAxisName:sub(lastAxisName:len()) == "-" then
                                inputComponent = Binding.INPUT_COMPONENT.NEGATIVE
                            end
                            action:removeBinding(binding)
                            self:addBinding(action, (Binding.new(binding.deviceId, newAxisNames, binding.axisComponent, inputComponent, binding.neutralInput, binding.index)))
                        end
                    end
                end
            end
        end
    end
end
function InputBinding:resolveBindingDevice(oldDevice, newDevice)
    if oldDevice.category == InputDevice.CATEGORY.UNKNOWN and oldDevice.category ~= newDevice.category then
        self.devicesToMigrateCategory[newDevice.deviceId] = newDevice
    end
    for _, action in pairs(self.actions) do
        for _, binding in pairs(action.bindings) do
            if binding.deviceId == oldDevice.deviceId then
                binding.deviceId = newDevice.deviceId
                binding.internalDeviceId = newDevice.internalId
                binding:setActive(true)
                binding:makeId()
            end
        end
    end
end
function InputBinding:resolveBindingDevices()
    local usedDevices = self:getAllDevicesWithBindings()
    for missingDeviceId, missingDevice in pairs(self.missingDevices) do
        if usedDevices[missingDeviceId] then
            for _, device in pairs(self.devicesByInternalId) do
                if device.deviceName == missingDevice.deviceName and not usedDevices[device.deviceId] then
                    self:resolveBindingDevice(missingDevice, device)
                    usedDevices[device.deviceId] = true
                    self.missingDevices[missingDeviceId] = nil
                    break
                end
            end
        end
    end
    for missingDeviceId, missingDevice in pairs(self.missingDevices) do
        if usedDevices[missingDeviceId] and missingDevice.category ~= InputDevice.CATEGORY.UNKNOWN then
            for _, device in pairs(self.devicesByInternalId) do
                if device.category == missingDevice.category and not usedDevices[device.deviceId] then
                    self:resolveBindingDevice(missingDevice, device)
                    usedDevices[device.deviceId] = true
                    self.missingDevices[missingDeviceId] = nil
                    break
                end
            end
        end
    end
    for missingDeviceId in pairs(self.missingDevices) do
        if not usedDevices[missingDeviceId] then
            self.missingDevices[missingDeviceId] = nil
        end
    end
end
function InputBinding:resolveBindingDefaultDevice(binding, disallowedDeviceIds)
    if not InputDevice.DEFAULT_DEVICE_NAMES[binding.deviceId] then
        return true
    end
    for _, device in pairs(self.devicesByInternalId) do
        if device.category == InputDevice.DEFAULT_DEVICE_CATEGORIES[binding.deviceId] and (disallowedDeviceIds == nil or not disallowedDeviceIds[device.deviceId]) then
            binding.deviceId = device.deviceId
            binding.internalDeviceId = device.internalId
            return true
        end
    end
    return false
end
function InputBinding:migrateDevicesCategory()
    if GS_PLATFORM_PC then
        for id, device in pairs(self.devicesToMigrateCategory) do
            local gamepad = self.deviceIdToInternal[device.deviceId]
            if gamepad == nil or self.numGamepads <= gamepad then
                self.devicesToMigrateCategory[id] = nil
            elseif getIsGamepadMappingReliable(gamepad) then
                local i = 0
                local newButtonMappings = Input.MAX_NUM_AXES - 1
                for i = i, newButtonMappings do
                    local mapping, inverted = getGamepadMappedUnknownAxis(i, gamepad, 1);
                    ({})[i] = { mapping, inverted }
                    local action, bindingsCopy = getGamepadMappedUnknownAxis(i, gamepad, -1);
                    ({})[i] = { action, bindingsCopy }
                end
                local newButtonMappings = {}
                local mapping = 0
                local i = 1
                for mapping = mapping, Input.MAX_NUM_BUTTONS - 1, i do
                    newButtonMappings[mapping] = getGamepadMappedUnknownButton(mapping, gamepad)
                end
                for inverted, action in pairs(self.actions) do
                    local bindingsCopy = {}
                    for bindingI, binding in pairs(action.bindings) do
                        bindingsCopy[bindingI] = binding
                    end
                    for bindingI, binding in pairs(bindingsCopy) do
                        if binding.deviceId == device.deviceId then
                            local newAxisNames = {}
                            for axisNameI, axisName in ipairs(binding.axisNames) do
                                local axisId = Input.axisIdNameToId[axisName]
                                local axisName
                                if axisId then
                                    local sign = axisName:sub(axisName:len())
                                    if axisNameI == #binding.axisNames and (not Input.isHalfAxis(axisId) and binding.neutralInput ~= 0) then
                                        sign = binding.neutralInput == 1 and "-" or "+"
                                    end
                                    local mapping = (sign == "-" and newAxisMappingsNeg and newAxisMappingsNeg or newAxisMappingsPos)[axisId]
                                    if mapping and mapping[1] < Input.MAX_NUM_AXES then
                                        if Input.isHalfAxis(mapping[1]) then
                                            sign = ""
                                        elseif mapping[2] then
                                        end
                                        axisName = Input.axisIdToIdName[mapping[1]] .. sign
                                    end
                                else
                                    local sign = Input.buttonIdNameToId[axisName]
                                    if sign then
                                        local mappings = newButtonMappings[sign]
                                        if mappings and mappings < Input.MAX_NUM_BUTTONS then
                                            axisName = Input.buttonIdToIdName[mappings]
                                        end
                                    end
                                end
                                table.insert(newAxisNames, axisName)
                            end
                            if #newAxisNames > 0 then
                                local lastAxisName = newAxisNames[#newAxisNames]
                                local inputComponent = Binding.INPUT_COMPONENT.POSITIVE
                                if lastAxisName:sub(lastAxisName:len()) == "-" then
                                    inputComponent = Binding.INPUT_COMPONENT.NEGATIVE
                                end
                                local neutralInput = binding.neutralInput
                                if Input.axisIdNameToId[lastAxisName] then
                                    neutralInput = Input.isHalfAxis(Input.axisIdNameToId[lastAxisName]) and 0 or neutralInput
                                end
                                action:removeBinding(binding)
                                self:addBinding(action, (Binding.new(binding.deviceId, newAxisNames, binding.axisComponent, inputComponent, neutralInput, binding.index)))
                            end
                        end
                    end
                end
                self.devicesToMigrateCategory[id] = nil
            end
        end
    elseif next(self.devicesToMigrateCategory) then
        self.devicesToMigrateCategory = {}
    end
end
function InputBinding:checkBindings(_, checkFunctions)
    local functionResults = {}
    for _, otherAction in pairs(self.actions) do
        local bindings = otherAction:getBindings()
        for _, knownBinding in pairs(bindings) do
            for _, check in pairs(checkFunctions) do
                local hasResult, result = check(knownBinding, otherAction)
                if hasResult then
                    functionResults[check] = result
                end
            end
        end
    end
    return functionResults
end
function InputBinding:validateBinding(binding, action)
    local shouldBeMouse = false
    local shouldBeKeyboard = false
    local maxAlternatives = Binding.MAX_ALTERNATIVES_GAMEPAD
    if binding.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT then
        if binding.index == Binding.MAX_ALTERNATIVES_KB_MOUSE then
            shouldBeMouse = true
        else
            shouldBeKeyboard = true
        end
    end
    local checkCollision
    if shouldBeMouse then
        checkCollision = InputBinding.getIsMouseInput(binding.axisNames)
    elseif shouldBeKeyboard then
        checkCollision = false
        if binding.index > 0 then
            checkCollision = false
            if binding.index <= maxAlternatives then
                checkCollision = InputBinding.getIsKeyboardInput(binding.axisNames)
            end
        end
    else
        checkCollision = false
        if binding.index > 0 then
            checkCollision = false
            if binding.index <= maxAlternatives then
                checkCollision = InputBinding.getIsGamepadInput(binding.axisNames)
            end
        end
    end
    local function checkCollision(otherBinding, otherAction)
        -- upvalues: (copy) binding
        if binding:hasCollisionWith(otherBinding) then
            return true, {
                ["collisionBinding"] = otherBinding,
                ["collisionAction"] = otherAction
            }
        else
            return false, nil
        end
    end
    local function checkDuplicate(otherBinding, otherAction)
        -- upvalues: (copy) action, (copy) binding
        if action == otherAction and binding.id == otherBinding.id then
            return true, true
        else
            return false, nil
        end
    end
    local function checkSlotOccupied(otherBinding, otherAction)
        -- upvalues: (copy) action, (copy) binding
        if otherAction == action and binding:isSameSlot(otherBinding) then
            return true, true
        else
            return false, nil
        end
    end
    local checkResults = self:checkBindings(action, { checkCollision, checkDuplicate, checkSlotOccupied })
    local collision = checkResults[checkCollision]
    return checkCollision, checkResults[checkDuplicate] and true or false, checkResults[checkSlotOccupied] and true or false, collision and true or false, collision
end
function InputBinding:addBinding(action, binding, silentIgnoreDuplicates)
    if not self:adjustBindingSlotIndex(binding, action) then
        if not silentIgnoreDuplicates then
            local hasValidIndex = tostring(binding)
            Logging.warning("Tried to add additional alternative binding %s to %s. The maximum alternative count has been reached. The new binding has been ignored.", hasValidIndex, (tostring(action.name)))
        end
        return false, nil
    end
    local hasAddedBinding = false
    local hasValidIndex, hasDuplicate, slotOccupied, _hasCollision, collisionRef = self:validateBinding(binding, action)
    local canAdd = hasValidIndex and not hasDuplicate
    if canAdd then
        canAdd = not slotOccupied
    end
    if not canAdd then
        if hasDuplicate then
            if not silentIgnoreDuplicates then
                Logging.warning("Tried to add duplicate binding %s to %s. The new binding has been ignored.", tostring(binding), (tostring(action.name)))
                return hasAddedBinding, collisionRef
            end
        elseif slotOccupied and not silentIgnoreDuplicates then
            Logging.warning("Tried assigning the binding %s to %s to an occupied slot. The new binding has been ignored", tostring(binding), (tostring(action.name)))
        end
        return hasAddedBinding, collisionRef
    end
    binding.internalDeviceId = self.deviceIdToInternal[binding.deviceId]
    binding:setIsAnalog(InputBinding.getIsAnalogInput(binding.unmodifiedAxis))
    binding:setActive(binding.internalDeviceId ~= nil)
    local bindingDevice = self.devicesByInternalId[binding.internalDeviceId]
    if bindingDevice ~= nil then
        binding:updateData(nil, bindingDevice.category)
    end
    binding:makeId()
    local loadedBinding = self.loadedBindings[binding.id]
    if loadedBinding == nil or not loadedBinding.isActive then
        self.loadedBindings[binding.id] = binding
    else
        binding = loadedBinding
    end
    action:addBinding(binding)
    return true, collisionRef
end
function InputBinding:updateBinding(findDeviceId, findActionName, findBindingIndex, findAxisComponent, deviceId, axisNames, inputComponent, neutralInput)
    local blockAdd = false
    local updateBinding = nil
    local action = self.nameActions[findActionName]
    if action ~= nil then
        local bindings = action:getBindings()
        for _, binding in pairs(bindings) do
            if binding.deviceId == findDeviceId and binding.axisComponent == findAxisComponent then
                if table.concat(axisNames, " ") == binding.inputString then
                    blockAdd = true
                elseif binding.index == findBindingIndex then
                    updateBinding = binding
                end
            end
        end
    end
    local bindings = false
    local collisionAction = nil
    if updateBinding ~= nil and not blockAdd then
        action:removeBinding(updateBinding)
        bindings, collisionAction = self:addBinding(action, Binding.new(deviceId, axisNames, findAxisComponent, inputComponent, neutralInput, findBindingIndex), true)
        if not bindings then
            self:addBinding(action, updateBinding, true)
        end
    end
    return bindings, collisionAction, blockAdd
end
function InputBinding:deleteBinding(findDeviceId, findActionName, findBindingIndex, findAxisComponent)
    local action = self.nameActions[findActionName]
    if action ~= nil then
        local bindings = action:getBindings()
        for i, binding in pairs(bindings) do
            if binding.deviceId == findDeviceId and (binding.index == findBindingIndex and binding.axisComponent == findAxisComponent) then
                table.remove(bindings, i)
                return
            end
        end
    end
end
function InputBinding:getKeyboardMouseInputActiveAndValue(axes, axisDirection, inputDirection)
    if not next(axes) then
        return false, 0
    end
    local inputValue = 0
    for _, inputAxis in pairs(axes) do
        local inputId = Input[inputAxis]
        if not inputId then
            return false, inputValue
        end
        if InputBinding.MOUSE_AXES[inputAxis] and inputId == Input.AXIS_X then
            inputValue = self.inputMouseXAxisValue
            if axisDirection ~= inputDirection then
            end
        elseif InputBinding.MOUSE_AXES[inputAxis] and inputId == Input.AXIS_Y then
            inputValue = self.inputMouseYAxisValue
            if axisDirection ~= inputDirection then
            end
        else
            if not (InputBinding.MOUSE_BUTTONS[inputAxis] and Input.isMouseButtonPressed(inputId) or Input.isKeyPressed(inputId)) then
                return false, 0
            end
            inputValue = axisDirection
        end
    end
    return true, inputValue
end
function InputBinding:getGamepadInputActiveAndValue(internalDeviceId, axisNames, neutralInput, axisDirection)
    local numAxes = #axisNames
    if numAxes == 0 then
        return false, 0
    end
    local i = 1
    local inputValue = numAxes - 1
    for i = i, inputValue do
        if self:getGamepadAxisOrButtonValue(internalDeviceId, axisNames[i], neutralInput) < Binding.PRESSED_MAGNITUDE_THRESHOLD then
            return false, 0
        end
    end
    local inputValue, isAxis = self:getGamepadAxisOrButtonValue(internalDeviceId, axisNames[numAxes], neutralInput)
    if not isAxis and inputValue < Binding.PRESSED_MAGNITUDE_THRESHOLD then
        return false, 0
    end
    if axisDirection < 0 then
    end
    return true, inputValue
end
function InputBinding:getGamepadAxisOrButtonValue(internalDeviceId, axisName, neutralInput)
    local buttonId = Input.buttonIdNameToId[axisName]
    if buttonId ~= nil then
        return getInputButton(buttonId, internalDeviceId), false
    end
    local axisId = Input.axisIdNameToId[axisName]
    if axisId == nil then
        return 0, false
    end
    local value = self:getGamepadAxisValue(internalDeviceId, axisId, axisName, neutralInput)
    if value ~= 0 then
        local device = self.devicesByInternalId[internalDeviceId]
        if device ~= nil then
        end
    end
    return value, true
end
function InputBinding:getGamepadAxisValue(internalDeviceId, axisId, axisName, neutralInput, overrideDeadzone)
    local device
    if Input.isHalfAxis(axisId) then
        device = (1 - getInputAxis(axisId, internalDeviceId)) * 0.5
    else
        device = getInputAxis(axisId, internalDeviceId)
        if neutralInput ~= 0 then
        end
        if axisName:sub(axisName:len()) == "-" then
        end
    end
    local device = self.devicesByInternalId[internalDeviceId]
    if device then
        if device ~= 0 then
            device:updateForceFeedbackState(axisId)
        end
        if GS_PLATFORM_PC then
            local deadzone = device:getDeadzone(axisId)
            if overrideDeadzone == nil then
                overrideDeadzone = deadzone
            end
            if overrideDeadzone > 0.999 or math.abs(device) < overrideDeadzone then
                return 0
            end
            if device > 0 then
                return (device - overrideDeadzone) / (1 - overrideDeadzone)
            end
            device = (device + overrideDeadzone) / (1 - overrideDeadzone)
        end
    end
    return device
end
function InputBinding:update(dt)
    self.needUpdateAbort = false
    self.timeSinceLastInputHelpModeChange = self.timeSinceLastInputHelpModeChange + dt
    self:checkGamepadsChanged()
    self:checkGamepadsCategoryChanged()
    self:checkGamepadActive(self.numGamepads)
    self:updateMouseInput()
    self:updateInput()
    self:finalizeMouseInput()
end
function InputBinding:refresh(forced)
    if self.needsRefresh or forced then
        self.needsRefresh = false
        self:storeEventBindings()
        self:storeDisplayActionEvents()
        self:notifyEventChanges()
        self.markIt = true
    end
end
function InputBinding:draw()
    if self.debugEnabled then
        self:updateDebugDisplay()
    end
    if self.debugContextEnabled then
        self:debugRenderInputContext()
    end
    if self.debugRegisteredActions then
        self:debugRenderRegisteredActions()
    end
end
function InputBinding:checkGamepadsChanged()
    local numGamepads = getNumOfGamepads()
    local changed = numGamepads ~= self.numGamepads
    if not changed then
        local internalId = 0
        for internalId = internalId, numGamepads - 1 do
            if getGamepadId(internalId) ~= self.internalIdToEngineDeviceId[internalId] then
                changed = true
                break
            end
        end
    end
    if changed then
        self.numGamepads = numGamepads
        self:load()
        self:refresh(true)
        self.messageCenter:publish(MessageType.INPUT_DEVICES_CHANGED)
    end
end
function InputBinding:checkGamepadsCategoryChanged()
    if GS_PLATFORM_PC then
        local gamepad = 0
        for gamepad = gamepad, self.numGamepads - 1 do
            local device = self.devicesByInternalId[gamepad]
            if device and (device.category == InputDevice.CATEGORY.UNKNOWN and getGamepadCategory(gamepad) ~= device.category) then
                self.devicesToMigrateCategory[device.deviceId] = device
            end
        end
        for device, newCategory in pairs(self.devicesToMigrateCategory) do
            local internalId = self.deviceIdToInternal[newCategory.deviceId]
            if internalId then
                if getIsGamepadMappingReliable(internalId) then
                    self:load()
                    return
                end
            else
                self.devicesToMigrateCategory[device] = nil
            end
        end
    end
end
function InputBinding:checkGamepadActive(numGamepads)
    local isActive = false
    if numGamepads > 0 and self.lastInputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD then
        local d = 0
        for d = d, numGamepads - 1 do
            local gamepadState = self.gamepadInputState[d]
            if gamepadState == nil then
                self.gamepadInputState[d] = {
                    ["buttons"] = {},
                    ["axes"] = {}
                }
            end
            local i = 0
            for i = i, Input.MAX_NUM_BUTTONS - 1 do
                local buttonState = getInputButton(i, d)
                if not isActive then
                    isActive = InputBinding.INPUT_MODE_CHANGE_THRESHOLD < math.abs(buttonState - (gamepadState.buttons[i] or 0))
                end
                buttons[i] = buttonState
            end
            local i = 0
            for i = i, Input.MAX_NUM_AXES - 1 do
                local prevButtonState = Input.isHalfAxis(i) and 1 or 0
                local axisState = getInputAxis(i, d)
                if not isActive then
                    isActive = threshold < math.abs(axisState - (gamepadState.axes[i] or prevButtonState))
                end
                axes[i] = axisState
            end
        end
    end
    if isActive then
        self:assignLastInputHelpMode(GS_INPUT_HELP_MODE_GAMEPAD)
    end
end
function InputBinding:updateMouseInput()
    self.inputMouseXAxisValue = math.clamp(self.accumMouseMovementX, -InputBinding.MOUSE_MOVE_LIMIT, InputBinding.MOUSE_MOVE_LIMIT) * InputBinding.MOUSE_MOVE_BASE_FACTOR
    self.inputMouseYAxisValue = math.clamp(-self.accumMouseMovementY, -InputBinding.MOUSE_MOVE_LIMIT, InputBinding.MOUSE_MOVE_LIMIT) * InputBinding.MOUSE_MOVE_BASE_FACTOR
    if math.abs(self.inputMouseXAxisValue) <= 0.001 then
        if math.abs(self.inputMouseYAxisValue) <= 0.001 then
            ::l3::
            return
        end
    end
    self:assignLastInputHelpMode(GS_INPUT_HELP_MODE_KEYBOARD)
    goto l3
end
function InputBinding:finalizeMouseInput()
    if self.wrapMousePositionEnabled then
        wrapMousePosition(self.saveCursorX, self.saveCursorY)
        self.mousePosXLast = self.saveCursorX
        self.mousePosYLast = self.saveCursorY
    end
    self.accumMouseMovementX = 0
    self.accumMouseMovementY = 0
    self.inputMouseXAxisValue = 0
    self.inputMouseYAxisValue = 0
end
function InputBinding:clearActiveBindingBuffer(activeBindingsBuffer)
    for dId in pairs(self.devicesByInternalId) do
        local bindings = activeBindingsBuffer[dId]
        if bindings then
            table.clear(bindings)
        else
            activeBindingsBuffer[dId] = {}
        end
    end
end
function InputBinding:updateEventBindings(activeBindingsBuffer)
    for binding in pairs(self.activeBindings) do
        if binding.isActive then
            self:updateBindingInput(binding)
            local deviceBindings = activeBindingsBuffer[binding.internalDeviceId]
            local bindingActive = binding.isUpFlank
            if not bindingActive then
                bindingActive = binding.inputValue ~= 0
            end
            for _, otherBinding in ipairs(deviceBindings) do
                if otherBinding ~= binding then
                    if bindingActive and (not otherBinding.isShadowed and table.isSubset(otherBinding.axisNameSet, binding.axisNameSet)) then
                        otherBinding.isShadowed = true
                    end
                    local otherActive = otherBinding.isUpFlank
                    if not otherActive then
                        otherActive = otherBinding.inputValue ~= 0
                    end
                    if otherActive and (not binding.isShadowed and table.isSubset(binding.axisNameSet, otherBinding.axisNameSet)) then
                        binding.isShadowed = true
                    end
                end
            end
            deviceBindings[#deviceBindings + 1] = binding
        end
    end
end
function InputBinding:hasBindingForPressedMouseComboMask(pressedMouseComboMask)
    for binding in pairs(self.activeBindings) do
        if binding.isMouse and binding:getComboMask() == pressedMouseComboMask then
            return true
        end
    end
    return false
end
function InputBinding:shadowLinkedBindings()
    for binding, linkedBindings in pairs(self.linkedBindings) do
        if binding.isShadowed then
            for _, linkedBinding in pairs(linkedBindings) do
                linkedBinding.isShadowed = true
            end
        end
    end
end
function InputBinding:updateComboBindings()
    for _, deviceCombos in pairs(InputBinding.ALL_COMBOS) do
        for actionName in pairs(deviceCombos) do
            local comboBinding = self.comboInputBindings[actionName]
            if comboBinding and comboBinding.isActive then
                self:updateBindingInput(comboBinding)
            end
        end
    end
end
function InputBinding:updateInput()
    self.needUpdateAbort = false
    local pressedGamepadComboMask, pressedMouseComboMask = self:getComboCommandPressedMask()
    if pressedGamepadComboMask ~= self.pressedGamepadComboMask or pressedMouseComboMask ~= self.pressedMouseComboMask then
        self:resetContinuousEventBindings(true, self.pressedGamepadComboMask, self.pressedMouseComboMask)
    end
    self.pressedGamepadComboMask = pressedGamepadComboMask
    self.pressedMouseComboMask = pressedMouseComboMask
    self:clearActiveBindingBuffer(self.activeDeviceBindingsBuffer)
    self:updateEventBindings(self.activeDeviceBindingsBuffer)
    self:shadowLinkedBindings()
    local forceMouseMask = self:hasBindingForPressedMouseComboMask(pressedMouseComboMask)
    for _, event in ipairs(self.eventOrder) do
        if self.needUpdateAbort then
            self.needUpdateAbort = false
            break
        end
        local selectedBinding = nil
        local highestInputMagnitude = 0
        local bindings = self.eventBindings[event]
        if bindings ~= nil then
            for _, binding in pairs(bindings) do
                local matchComboMask = true
                local forceMouseAxisMask = forceMouseMask and binding.isMouse
                if forceMouseAxisMask then
                    forceMouseAxisMask = InputBinding.MOUSE_AXES[binding.unmodifiedAxis]
                end
                if not event:getIgnoreComboMask() or forceMouseAxisMask then
                    if binding.isMouse then
                        matchComboMask = true
                        if binding.comboMask ~= pressedMouseComboMask then
                            matchComboMask = InputBinding.MOUSE_COMBO_AXIS_NAMES[binding.unmodifiedAxis]
                        end
                    else
                        matchComboMask = true
                        if binding.comboMask ~= pressedGamepadComboMask then
                            matchComboMask = InputBinding.GAMEPAD_COMBO_AXIS_NAMES[binding.unmodifiedAxis]
                        end
                    end
                end
                if matchComboMask and (binding.isInputActive and not (binding.isShadowed or binding:getFrameTriggered())) then
                    if selectedBinding then
                        if highestInputMagnitude < math.abs(binding.inputValue) or binding.isUpFlank and highestInputMagnitude == 0 then
                            goto l30
                        end
                    else
                        ::l30::
                        highestInputMagnitude = math.abs(binding.inputValue)
                        selectedBinding = binding
                    end
                end
            end
        end
        if selectedBinding ~= nil then
            event:notifyInput(selectedBinding)
        end
    end
    self:updateComboBindings()
    for _, event in pairs(self.eventBindings) do
        _:frameReset()
    end
end
function InputBinding:updateBindingInput(binding)
    local device = self.devicesByInternalId[binding.internalDeviceId]
    if device ~= nil then
        local bindingInputActive = false
        local bindingInputValue = 0
        if device.category == InputDevice.CATEGORY.KEYBOARD_MOUSE then
            bindingInputActive, bindingInputValue = self:getKeyboardMouseInputActiveAndValue(binding.axisNames, binding.axisDirection, binding.inputDirection)
        elseif self.isGamepadEnabled then
            bindingInputActive, bindingInputValue = self:getGamepadInputActiveAndValue(binding.internalDeviceId, binding.axisNames, binding.neutralInput, binding.axisDirection)
        end
        binding:updateInput(bindingInputValue, bindingInputActive)
    end
end
function InputBinding:resetContinuousEventBindings(checkComboMasks, gamepadComboMask, mouseComboMask)
    for event, bindings in pairs(self.eventBindings) do
        if event.triggerAlways and not event:getIgnoreComboMask() then
            for _, binding in pairs(bindings) do
                local matchMask = true
                if checkComboMasks then
                    if binding.isGamepad then
                        matchMask = true
                        if binding.comboMask ~= gamepadComboMask then
                            goto l10
                        end
                    else
                        ::l10::
                        matchMask = binding.isMouse
                        if matchMask then
                            matchMask = binding.comboMask == mouseComboMask
                        end
                    end
                end
                if matchMask then
                    self:neutralizeEventBindingInput(event, binding)
                end
            end
        end
    end
end
function InputBinding:resetBindingInputStates()
    for event, bindings in pairs(self.eventBindings) do
        for _, binding in pairs(bindings) do
            binding:resetInputState()
        end
    end
end
function InputBinding.neutralizeEventBindingInput(_, event, binding)
    binding:updateInput(0, true)
    event:frameReset()
    event:notifyInput(binding, true)
end
function InputBinding:updateDebugDisplay()
    local posX = 0.02
    local d = 0
    for d = d, self.numGamepads - 1 do
        setTextColor(1, 1, 1, 1)
        local posY = 0.95
        setTextBold(true)
        renderText(posX, posY, getCorrectTextSize(0.012), getGamepadName(d))
        setTextBold(false)
        local posY = posY - 0.015
        local i = 0
        for i = i, Input.MAX_NUM_BUTTONS - 1 do
            if getHasGamepadButton(i, d) then
                renderText(posX, posY, getCorrectTextSize(0.012), "- " .. i)
                renderText(posX + 0.05, posY, getCorrectTextSize(0.012), getGamepadButtonLabel(i, d) or "n/a")
                renderText(posX + 0.1, posY, getCorrectTextSize(0.012), (tostring(getInputButton(i, d) > 0)))
                posY = posY - 0.015
            end
        end
        local i = 0
        for i = i, Input.MAX_NUM_AXES - 1 do
            if getHasGamepadAxis(i, d) then
                renderText(posX, posY, getCorrectTextSize(0.012), "+ " .. i)
                renderText(posX + 0.05, posY, getCorrectTextSize(0.012), getGamepadAxisLabel(i, d) or "n/a")
                renderText(posX + 0.1, posY, getCorrectTextSize(0.012), string.format("%.4f", getInputAxis(i, d)))
                posY = posY - 0.015
            end
        end
        setTextColor(1, 0, 0, 1)
        local posY = 0.95 + 0.5 * g_pixelSizeY
        local posX = posX - 0.5 * g_pixelSizeX
        setTextBold(true)
        renderText(posX, posY, getCorrectTextSize(0.012), getGamepadName(d))
        setTextBold(false)
        local posY = posY - 0.015
        local i = 0
        for i = i, Input.MAX_NUM_BUTTONS - 1 do
            if getHasGamepadButton(i, d) then
                renderText(posX, posY, getCorrectTextSize(0.012), "- " .. i)
                renderText(posX + 0.05, posY, getCorrectTextSize(0.012), getGamepadButtonLabel(i, d) or "n/a")
                renderText(posX + 0.1, posY, getCorrectTextSize(0.012), (tostring(getInputButton(i, d) > 0)))
                posY = posY - 0.015
            end
        end
        local i = 0
        for i = i, Input.MAX_NUM_AXES - 1 do
            if getHasGamepadAxis(i, d) then
                renderText(posX, posY, getCorrectTextSize(0.012), "+ " .. i)
                renderText(posX + 0.05, posY, getCorrectTextSize(0.012), getGamepadAxisLabel(i, d) or "n/a")
                renderText(posX + 0.1, posY, getCorrectTextSize(0.012), string.format("%.4f", getInputAxis(i, d)))
                posY = posY - 0.015
            end
        end
        posX = posX + 0.15
    end
    setTextColor(1, 1, 1, 1)
end
function InputBinding:saveToXMLFile()
    if self.settingsPath == InputBinding.PATHS.USER_BINDINGS then
        local xmlFile = loadXMLFile("InputBindings", self.settingsPath)
        local i = 1
        while true do
            local actionBindingElement = string.format("inputBinding.actionBinding(%d)", i - 1)
            if not hasXMLProperty(xmlFile, actionBindingElement) then
                break
            end
            local actionName = getXMLString(xmlFile, actionBindingElement .. "#action")
            if actionName and InputAction[actionName] then
                if self.nameActions[actionName] ~= nil then
                    local firstElement = string.format("%s.binding(0)", actionBindingElement)
                    while hasXMLProperty(xmlFile, firstElement) do
                        removeXMLProperty(xmlFile, firstElement)
                    end
                    local bindings = self.nameActions[actionName]:getBindings()
                    for j, binding in ipairs(bindings) do
                        binding:saveToXMLFile(xmlFile, (string.format("%s.binding(%d)", actionBindingElement, j - 1)))
                    end
                end
                ({})[actionName] = true
            end
            i = i + 1
        end
        for action, bindings in ipairs(self.actions) do
            if not storedActions[bindings.name] then
                local actionBindingElement = string.format("inputBinding.actionBinding(%d)", i - 1)
                setXMLString(xmlFile, actionBindingElement .. "#action", bindings.name)
                local bindings = bindings:getBindings()
                for bindingElement, binding in ipairs(bindings) do
                    binding:saveToXMLFile(xmlFile, (string.format("%s.binding(%d)", actionBindingElement, bindingElement - 1)))
                end
                i = i + 1
            end
        end
        self:saveDeviceSettings(xmlFile)
        setXMLFloat(xmlFile, "inputBinding#mouseSensitivityScaleX", self.mouseMotionScaleX)
        setXMLFloat(xmlFile, "inputBinding#mouseSensitivityScaleY", self.mouseMotionScaleY)
        setXMLInt(xmlFile, "inputBinding#bindingVersion", InputBinding.currentBindingVersion)
        saveXMLFile(xmlFile)
        delete(xmlFile)
        syncProfileFiles()
    end
end
function InputBinding:saveDeviceSettings(xmlFile)
    while hasXMLProperty(xmlFile, "inputBinding.devices.device(0)") do
        removeXMLProperty(xmlFile, "inputBinding.devices.device(0)")
    end
    local elementIndex = 0
    for _, device in pairs(self.devicesByInternalId) do
        if not InputDevice.DEFAULT_DEVICE_NAMES[device.deviceId] then
            device:saveSettingsToXML(xmlFile, (string.format("inputBinding.devices.device(%d)", elementIndex)))
            elementIndex = elementIndex + 1
        end
    end
    for _, device in pairs(self.missingDevices) do
        if not InputDevice.DEFAULT_DEVICE_NAMES[device.deviceId] then
            device:saveSettingsToXML(xmlFile, (string.format("inputBinding.devices.device(%d)", elementIndex)))
            elementIndex = elementIndex + 1
        end
    end
end
function InputBinding:getActionList()
    local tableCopy = {}
    for _, action in ipairs(self.actions) do
        local actionCopy = action:clone()
        table.insert(tableCopy, actionCopy)
    end
    return tableCopy
end
function InputBinding:getActionByName(actionName)
    return self.nameActions[actionName]
end
function InputBinding:disableAlternateBindingsForAction(actionName)
    local events = self.actionEvents[self.nameActions[actionName]]
    if events ~= nil then
        for _, event in pairs(events) do
            local bindings = self.eventBindings[event]
            if bindings ~= nil then
                local i = #bindings
                for i = i, 1, -1 do
                    if bindings[i].index > 1 then
                        table.remove(bindings, i)
                    end
                end
            end
        end
    end
end
function InputBinding:resetActiveActionBindings()
    for _, action in pairs(self.nameActions) do
        action:resetActiveBindings()
    end
end
function InputBinding:createContext(name)
    self:deleteContext(name)
    local context = {
        ["actionEvents"] = {},
        ["name"] = name,
        ["previousContextName"] = "",
        ["eventOrderCounter"] = 1
    }
    self.contexts[name] = context
    return context
end
function InputBinding:deleteContext(name)
    local oldContext = self.contexts[name]
    if oldContext ~= nil then
        for _, eventList in pairs(oldContext.actionEvents) do
            local i = #eventList
            for i = i, 1, -1 do
                self:removeEventInternal(eventList[i], eventList, i)
            end
        end
    end
    self.contexts[name] = nil
end
function InputBinding:replaceContextInStack(oldContextName, newContextName)
    for _, context in pairs(self.contexts) do
        if context.previousContextName == oldContextName then
            context.previousContextName = newContextName
        end
    end
end
function InputBinding:setContext(name, createNew, deletePrevious)
    local context = self.contexts[name]
    local hasCreatedNew = false
    if context == nil or createNew then
        context = self:createContext(name)
        hasCreatedNew = true
    end
    if deletePrevious and self.currentContextName ~= InputBinding.ROOT_CONTEXT_NAME then
        self:deleteContext(self.currentContextName)
    end
    if self.debugEnabled then
        Logging.devInfo("[InputBinding] Set input context from [%s] to [%s], createNew=%s, deletePrevious=%s", tostring(self.currentContextName), tostring(name), tostring(createNew or false), (tostring(deletePrevious or false)))
    end
    if name ~= self.currentContextName then
        context.previousContextName = self.currentContextName
        self.currentContextName = name
    end
    self:resetContinuousEventBindings(false)
    self:resetBindingInputStates()
    self.actionEvents = context.actionEvents
    if hasCreatedNew then
        registerGlobalActionEvents(self)
    end
    self:refreshEventCollections()
end
function InputBinding:revertContext(deleteCurrent)
    if self.currentContextName == InputBinding.ROOT_CONTEXT_NAME then
        Logging.devWarning("Tried reverting input context when at root level.")
        return
    else
        local prevContextName = self.contexts[self.currentContextName].previousContextName
        local prevContext = self.contexts[prevContextName]
        if prevContext then
            if deleteCurrent then
                self:deleteContext(self.currentContextName)
            end
            if self.debugEnabled then
                Logging.devInfo("[InputBinding] Reverting input context from [%s] to [%s], deleteCurrent=%s", tostring(self.currentContextName), tostring(prevContextName), (tostring(deleteCurrent or false)))
            end
            self.currentContextName = prevContextName
            self.actionEvents = prevContext.actionEvents
            self:refreshEventCollections()
            self:resetBindingInputStates()
        else
            Logging.warning("Tried reverting to input context [%s] which is not defined. Current context [%s]", tostring(prevContextName), self.currentContextName)
            printCallstack()
        end
    end
end
function InputBinding:setPreviousContext(forContextName, previousContextName)
    local context = self.contexts[forContextName]
    if context ~= nil and self.contexts[previousContextName] ~= nil then
        context.previousContextName = previousContextName
    end
end
function InputBinding:clearAllContexts()
    for contextName in pairs(self.contexts) do
        if contextName ~= InputBinding.ROOT_CONTEXT_NAME then
            self:deleteContext(contextName)
        end
    end
    if self.debugEnabled then
        Logging.devInfo("[InputBinding] Cleared all contexts")
    end
    self:setContext(InputBinding.ROOT_CONTEXT_NAME, false, false)
end
function InputBinding:getContextName()
    return self.currentContextName
end
function InputBinding:getActionBindingsCopy(onlyAssignable)
    local tableCopy = {}
    for _, action in ipairs(self.actions) do
        if not onlyAssignable or onlyAssignable and not action.isLocked then
            local bindings = action:getBindings()
            local bindingsCopy = {}
            local entry = {
                ["action"] = action:clone(),
                ["bindings"] = bindingsCopy
            }
            table.insert(tableCopy, entry)
            for _, binding in ipairs(bindings) do
                table.insert(bindingsCopy, binding:clone())
            end
        end
    end
    return tableCopy
end
function InputBinding:getActionBindings()
    local actionBindings = {}
    for _, action in pairs(self.actions) do
        actionBindings[action] = action:getActiveBindings()
    end
    return actionBindings
end
function InputBinding:getEventsForActionName(actionName)
    local action = self.nameActions[actionName]
    if action ~= nil then
        local events = self.actionEvents[action]
        if events ~= nil then
            return { unpack(events) }
        end
    end
    return InputBinding.NO_ACTION_EVENTS
end
function InputBinding:getFirstActiveEventForActionName(actionName)
    local action = self.nameActions[actionName]
    if action ~= nil then
        local events = self.actionEvents[action]
        if events ~= nil then
            for _, event in ipairs(events) do
                if event.isActive then
                    return event
                end
            end
        end
    end
    return InputEvent.NO_EVENT
end
function InputBinding:setMouseMotionScale(scale)
    self.mouseMotionScaleX = InputBinding.MOUSE_MOTION_SCALE_X_DEFAULT * scale
    self.mouseMotionScaleY = InputBinding.MOUSE_MOTION_SCALE_Y_DEFAULT * scale
end
function InputBinding:getMouseMotionScale()
    return self.mouseMotionScaleX, self.mouseMotionScaleY
end
function InputBinding:setEventChangeCallback(callback)
    self.eventChangeCallback = callback
end
function InputBinding:notifyBindingChanges()
    self.messageCenter:publish(MessageType.INPUT_BINDINGS_CHANGED, self:getActionBindings())
end
function InputBinding:notifyEventChanges()
    if self.eventChangeCallback then
        self.eventChangeCallback(self.displayActionEvents)
    end
end
function InputBinding:notifyInputModeChange(inputMode, isHelpModeUpdate)
    if not self.isConsoleVersion then
        local messageType = MessageType.INPUT_MODE_CHANGED
        if isHelpModeUpdate then
            messageType = MessageType.INPUT_HELP_MODE_CHANGED
        end
        self.messageCenter:publish(messageType, InputBinding.MESSAGE_PARAM_INPUT_MODE[inputMode])
    end
end
function InputBinding.checkSettingsIntegrity(_, inputBindingPath, inputBindingPathTemplate)
    local xmlFile1 = loadXMLFile("InputBindings1", inputBindingPath)
    if xmlFile1 == 0 then
        return false
    end
    local rootName = getXMLRootName(xmlFile1)
    local xmlFile2 = not rootName
    if not xmlFile2 then
        xmlFile2 = rootName == ""
    end
    if xmlFile2 then
        Logging.error("User input bindings corrupted. Replacing with defaults...")
    end
    local xmlFile2 = loadXMLFile("InputBindings2", inputBindingPathTemplate)
    local version1 = getXMLInt(xmlFile1, "inputBinding#version") or 1
    local version2 = getXMLInt(xmlFile2, "inputBinding#version") or 1
    delete(xmlFile1)
    delete(xmlFile2)
    return not xmlFile2 and version1 == version2
end
function InputBinding:checkDefaultInputExclusiveActionBindings()
    for groupId, exclusiveActions in pairs(InputAction.EXCLUSIVE_ACTION_GROUPS) do
        for i, actionName1 in ipairs(exclusiveActions) do
            local j = i + 1
            for j = j, #exclusiveActions do
                for _, binding1 in ipairs(self.nameActions[actionName1].bindings) do
                    for _, binding2 in ipairs(self.nameActions[exclusiveActions[j]].bindings) do
                        local bothPrimary = false
                        if binding1.index == 1 then
                            bothPrimary = binding2.index == 1
                        end
                        if bothPrimary and binding1.inputString == binding2.inputString then
                            Logging.devError("Currently loaded input bindings have conflicting primary bindings in action group \'%s\' for actions [%s] and [%s], both bound to [%s]", groupId, action1.name, action2.name, binding2.inputString)
                        end
                    end
                end
            end
        end
    end
end
function InputBinding.getBindingForceFeedbackInfo(_, binding)
    if binding == nil then
        return false, nil, 0
    else
        local device = g_inputBinding:getDeviceById(binding.deviceId)
        local axisIndex = nil
        local i = 1
        for i = i, #binding.axisNames do
            axisIndex = Input.axisIdNameToId[binding.axisNames[i]]
        end
        if device == nil or axisIndex == nil then
            return false, nil, 0
        else
            return device:getIsForceFeedbackSupported(axisIndex), device, axisIndex
        end
    end
end
function InputBinding:getNumActiveBindings(actionName)
    local action = self.nameActions[actionName]
    return action == nil and 0 or action:getNumActiveBindings()
end
function InputBinding:setContextEventsActive(contextName, actionName, isActive)
    for _, event in ipairs((self.contexts[contextName] or {}).actionEvents[self.nameActions[actionName]]) do
        self:setEventActive(event, isActive)
    end
end
function InputBinding.getIsPhysicalFullAxis(inputAxisName)
    local isMouseAxis = InputBinding.MOUSE_AXES[inputAxisName] ~= nil
    if not isMouseAxis then
        isMouseAxis = false
        if Input.axisIdNameToId[inputAxisName] ~= nil then
            isMouseAxis = not Input.isHalfAxis(axisId)
        end
    end
    return isMouseAxis
end
function InputBinding.getIsHalfAxis(inputAxisName)
    return Input.isHalfAxis(Input.axisIdNameToId[inputAxisName])
end
function InputBinding.getIsAnalogInput(inputName)
    return InputBinding.MOUSE_AXES[inputName] and true or false or (Input.axisIdNameToId[inputName] and true or false)
end
function InputBinding.getIsKeyboardInput(inputAxisNames)
    if not inputAxisNames or #inputAxisNames == 0 then
        return false
    end
    local isKb = true
    for _, inputAxisName in pairs(inputAxisNames) do
        if isKb then
            isKb = Input.keyIdToIdName[Input[inputAxisName]]
        end
    end
    return isKb
end
function InputBinding.getIsMouseInput(inputAxisNames)
    if not inputAxisNames or #inputAxisNames == 0 then
        return false
    end
    local isMouse = true
    for _, inputAxisName in pairs(inputAxisNames) do
        if isMouse then
            isMouse = InputBinding.MOUSE_AXES[inputAxisName] or InputBinding.MOUSE_BUTTONS[inputAxisName]
        end
    end
    return isMouse
end
function InputBinding.getIsMouseWheelInput(inputAxisNames)
    if not inputAxisNames or #inputAxisNames == 0 then
        return false
    end
    return InputBinding.MOUSE_WHEEL[InputBinding.MOUSE_BUTTONS[inputAxisNames[1]] or ""]
end
function InputBinding.getIsGamepadInput(inputAxisNames)
    if not inputAxisNames or #inputAxisNames == 0 then
        return false
    end
    local isGamepad = true
    for _, inputAxisName in pairs(inputAxisNames) do
        if isGamepad then
            isGamepad = true
            if Input.axisIdNameToId[inputAxisName] == nil then
                isGamepad = Input.buttonIdNameToId[inputAxisName] ~= nil
            end
        end
    end
    return isGamepad
end
function InputBinding.getIsDPadInput(inputAxisNames)
    if inputAxisNames and #inputAxisNames ~= 0 then
        local buttonId = Input.buttonIdNameToId[inputAxisNames[1]]
        if buttonId == nil then
            return false
        else
            return InputBinding.GAMEPAD_DPAD[buttonId]
        end
    else
        return false
    end
end
function InputBinding.isAxisZero(value)
    return value == nil or math.abs(value) < 0.0001
end
function InputBinding.getDeviceCategory(internalDeviceId)
    if internalDeviceId == InputBinding.KB_MOUSE_INTERNAL_ID then
        return InputDevice.CATEGORY.KEYBOARD_MOUSE
    end
    local category = getGamepadCategory(internalDeviceId)
    if category == InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER then
        local productId = getGamepadProductId(internalDeviceId)
        if table.hasElement(InputBinding.THURSTMASTER_FARMJOYSTICK_LEFT_PRODUCT_IDS, productId) then
            category = InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER_LEFT
        end
    end
    return category
end
function InputBinding:printAll()
    for action, eventList in pairs(self.actionEvents) do
        local i = #eventList
        for i = i, 1, -1 do
            log(nil, self.currentContextName, "EventTable:", self.actionEvents, eventList[i])
        end
    end
    for action, eventList in pairs(self.contexts) do
        for event, eventList in pairs(eventList.actionEvents) do
            local i = #eventList
            for i = i, 1, -1 do
                log(eventList, eventList.name, "EventTable:", eventList.actionEvents, eventList[i])
            end
        end
    end
end
function InputBinding:debugPrintInputContext(contextName)
    contextName = contextName or self.currentContextName
    local context = self.contexts[contextName] or {}
    printf("Context [%s]: previousContextName=%s, eventOrderCounter=%s", contextName, context.previousContextName, context.eventOrderCounter)
    for action, events in pairs(context.actionEvents) do
        printf("  Action %s", action)
        printf("    Bindings:")
        for _, binding in ipairs(action:getBindings()) do
            printf("      %s", binding)
        end
        printf("    Events:")
        for _, binding in ipairs(events) do
            printf("      %s", binding)
        end
    end
end
function InputBinding:debugRenderRegisteredActions()
    local xPos = 0.01
    local yPos = 0.98
    local actions = {}
    for _, action in ipairs(self.actions) do
        table.insert(actions, action)
    end
    table.sort(actions, function(a, b)
        return a.name < b.name
    end)
    for _, action in ipairs(actions) do
        local bindings = action:getBindings()
        local text = string.format("%s (%d Bindings)", action.name, #bindings)
        setTextBold(true)
        setTextColor(0, 0, 0, 1)
        renderText(xPos, yPos, 0.012, text)
        setTextColor(1, 1, 1, 1)
        renderText(xPos + g_pixelSizeX, yPos + g_pixelSizeY, 0.012, string.format("%s (%d Bindings)", action.name, #bindings))
        yPos = yPos - 0.012 - 0.0005
        if yPos < 0 then
            yPos = 0.98
        end
    end
    setTextColor(1, 1, 1, 1)
end
function InputBinding:debugRenderInputContext(contextName)
    local context = contextName or self.currentContextName
    local context = self.contexts[context] or {}
    new2DLayer()
    drawFilledRect(0, 0, 1, 1, 0, 0, 0, 0.8)
    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_LEFT)
    renderText(0.01, 0.98, 0.015, string.format("Context [%s]: previousContextName=%s, eventOrderCounter=%s", context, context.previousContextName, context.eventOrderCounter))
    local posX = 0.01
    local posY = 0.96
    local numColumns = 1
    self.debugActionEvents = self.debugActionEvents or {}
    table.clear(self.debugActionEvents)
    for action, events in pairs(context.actionEvents) do
        table.insert(self.debugActionEvents, { action, events })
    end
    table.sort(self.debugActionEvents, function(a, b)
        return a[1].name < b[1].name
    end)
    for action, events in ipairs(self.debugActionEvents) do
        local action = events[1]
        local events = events[2]
        if posY - (1 + 1.5 * #action:getBindings() + #events) * 0.013 < 0 then
            posY = 0.96
            numColumns = numColumns + 1
            if numColumns > 2 then
                new2DLayer()
            end
        end
        setTextColor(1, 0.3, 0.3, 1)
        setTextBold(true)
        local actionText = string.format("%s (%s) - isLocked:%s", action.name, action.axisType, action.isLocked)
        renderText(posX, posY, 0.01, actionText)
        setTextBold(false)
        local posY = posY - 0.011
        local currentDeviceId = nil
        local activeBindings = action:getActiveBindings()
        for _, binding in ipairs(action:getBindings()) do
            setTextColor(0.4, 0.4, 0.4, 1)
            if currentDeviceId ~= binding.deviceId then
                currentDeviceId = binding.deviceId
                renderText(posX + 0.005, posY, 0.007, "Device: " .. tostring((string.sub(binding.deviceId, (math.max(1, string.len(binding.deviceId) - 80))))))
                posY = posY - 0.0105
            end
            local isActive = table.hasElement(activeBindings, binding)
            setTextColor(1, 1, 1, 1)
            if binding.isShadowed then
                setTextColor(1, 0, 0, 1)
                if binding.inputValue ~= 0 then
                    setTextColor(0.4, 0.4, 0, 1)
                end
            elseif isActive then
                if binding.inputValue ~= 0 then
                    setTextColor(0, 1, 0, 1)
                end
            else
                setTextColor(0.4, 0.4, 0.4, 1)
                if binding.inputValue ~= 0 then
                    setTextColor(0, 0.4, 0, 1)
                end
            end
            local className = renderText
            className(posX + 0.005, posY, 0.009, "    Active: " .. tostring(binding.isActive))
            local className = renderText
            className(posX + 0.04, posY, 0.009, "Shadowed: " .. tostring(binding.isShadowed))
            renderText(posX + 0.08, posY, 0.009, "Value: " .. string.format("%.4f", binding.inputValue))
            local className = renderText
            className(posX + 0.12, posY, 0.009, tostring(binding.index) .. ": [" .. table.concat(binding.axisNames, ", ") .. "] " .. tostring(binding.axisComponent))
            posY = posY - 0.0105
        end
        setTextColor(1, 1, 1, 1)
        local posY = posY - 0.003
        for _, binding in ipairs(events) do
            local isActive = renderText
            local className = posX + 0.005
            isActive(className, posY, 0.009, "E: Active: " .. tostring(binding.isActive))
            local isActive = renderText
            local className = posX + 0.04
            isActive(className, posY, 0.009, "Visible: " .. tostring(binding.displayIsVisible))
            local isActive = renderText
            local className = posX + 0.08
            isActive(className, posY, 0.009, "Triggered: " .. tostring(binding.hasFrameTriggered))
            local className = binding.targetObject
            local isActive = tostring(className)
            local className = ClassUtil.getClassNameByObject(binding.targetObject)
            if className ~= nil then
                isActive = string.format("%s (%s)", className, isActive)
            end
            renderText(posX + 0.12, posY, 0.009, "Target: " .. isActive)
            posY = posY - 0.0105
        end
        posY = posY - 0.006
    end
end
function InputBinding:consoleCommandEnableInputDebug()
    self.debugEnabled = not self.debugEnabled
    return "InputBinding.debugEnabled = " .. tostring(self.debugEnabled)
end
function InputBinding:consoleCommandPrintInputContext(_)
    self:debugPrintInputContext()
end
function InputBinding:consoleCommandShowInputContext(_)
    self.debugContextEnabled = not self.debugContextEnabled
end
function InputBinding:consoleCommandShowRegisteredActions(_)
    self.debugRegisteredActions = not self.debugRegisteredActions
end