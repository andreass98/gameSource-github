InputDevice = {}
local InputDevice_mt = Class(InputDevice)
InputDevice.CATEGORY = {
    ["UNKNOWN"] = GamepadCategories.CATEGORY_UNKNOWN,
    ["GAMEPAD"] = GamepadCategories.CATEGORY_GAMEPAD,
    ["WHEEL"] = GamepadCategories.CATEGORY_WHEEL,
    ["JOYSTICK"] = GamepadCategories.CATEGORY_JOYSTICK,
    ["FARMWHEEL"] = GamepadCategories.CATEGORY_FARMWHEEL,
    ["FARMPANEL"] = GamepadCategories.CATEGORY_FARMSIDEPANEL,
    ["FARMWHEEL_HORI"] = GamepadCategories.CATEGORY_FARMWHEEL_HORI,
    ["FARMPANEL_HORI"] = GamepadCategories.CATEGORY_FARMSIDEPANEL_HORI,
    ["FARMPANEL_MOZA"] = GamepadCategories.CATEGORY_FARMSIDEPANEL_MOZA,
    ["FARMJOYSTICK_THRUSTMASTER"] = GamepadCategories.CATEGORY_FARMJOYSTICK_THRUSTMASTER,
    ["FARMJOYSTICK_THRUSTMASTER_LEFT"] = 251,
    ["FARMJOYSTICK_THRUSTMASTER_DUAL"] = 252,
    ["KEYBOARD_MOUSE"] = 253,
    ["WHEEL_AND_PANEL"] = 254,
    ["FARMWHEEL_AND_PANEL"] = 255
}
InputDevice.DEFAULT_DEVICE_NAMES = {
    ["KB_MOUSE_DEFAULT"] = "KB_MOUSE_DEFAULT",
    ["GAMEPAD_DEFAULT"] = "GAMEPAD_DEFAULT",
    ["JOYSTICK_DEFAULT"] = "JOYSTICK_DEFAULT",
    ["WHEEL_DEFAULT"] = "WHEEL_DEFAULT",
    ["FARM_WHEEL_DEFAULT"] = "FARM_WHEEL_DEFAULT",
    ["PANEL_DEFAULT"] = "PANEL_DEFAULT",
    ["FARM_WHEEL_HORI_DEFAULT"] = "FARM_WHEEL_HORI_DEFAULT",
    ["FARM_PANEL_HORI_DEFAULT"] = "FARM_PANEL_HORI_DEFAULT",
    ["FARM_JOYSTICK_THRUSTMASTER_DEFAULT"] = "FARM_JOYSTICK_THRUSTMASTER_DEFAULT",
    ["FARM_JOYSTICK_THRUSTMASTER_DEFAULT_LEFT"] = "FARM_JOYSTICK_THRUSTMASTER_DEFAULT_LEFT",
    ["FARM_PANEL_MOZA_DEFAULT"] = "FARM_PANEL_MOZA_DEFAULT"
}
InputDevice.NAMES = {
    ["SAITEK_WHEEL"] = "Saitek Heavy Eqpt. Wheel & Pedal",
    ["SAITEK_PANEL"] = "Saitek Side Panel Control Deck",
    ["HORI_WHEEL"] = "HORI FARMING CONTROLLER STEERING",
    ["HORI_PANEL"] = "HORI FARMING CONTROLLER PANEL",
    ["XINPUT_GAMEPAD"] = "XINPUT_GAMEPAD",
    ["XBOX_GAMEPAD"] = "Xbox Gamepad",
    ["PS_GAMEPAD"] = "DUALSHOCK(R)4",
    ["PS5_GAMEPAD"] = "DualSense Wireless Controller",
    ["STADIA_GAMEPAD"] = "Stadia Controller",
    ["SWITCH_GAMEPAD"] = "Nintendo Controller",
    ["MOZA_PANEL"] = "MOZA Farming Control System"
}
InputDevice.DEFAULT_DEVICE_CATEGORIES = {
    [InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT] = InputDevice.CATEGORY.KEYBOARD_MOUSE,
    [InputDevice.DEFAULT_DEVICE_NAMES.GAMEPAD_DEFAULT] = InputDevice.CATEGORY.GAMEPAD,
    [InputDevice.DEFAULT_DEVICE_NAMES.JOYSTICK_DEFAULT] = InputDevice.CATEGORY.JOYSTICK,
    [InputDevice.DEFAULT_DEVICE_NAMES.WHEEL_DEFAULT] = InputDevice.CATEGORY.WHEEL,
    [InputDevice.DEFAULT_DEVICE_NAMES.FARM_WHEEL_DEFAULT] = InputDevice.CATEGORY.FARMWHEEL,
    [InputDevice.DEFAULT_DEVICE_NAMES.PANEL_DEFAULT] = InputDevice.CATEGORY.FARMPANEL,
    [InputDevice.DEFAULT_DEVICE_NAMES.FARM_WHEEL_HORI_DEFAULT] = InputDevice.CATEGORY.FARMWHEEL_HORI,
    [InputDevice.DEFAULT_DEVICE_NAMES.FARM_PANEL_HORI_DEFAULT] = InputDevice.CATEGORY.FARMPANEL_HORI,
    [InputDevice.DEFAULT_DEVICE_NAMES.FARM_JOYSTICK_THRUSTMASTER_DEFAULT] = InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER,
    [InputDevice.DEFAULT_DEVICE_NAMES.FARM_JOYSTICK_THRUSTMASTER_DEFAULT_LEFT] = InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER_LEFT,
    [InputDevice.DEFAULT_DEVICE_NAMES.FARM_PANEL_MOZA_DEFAULT] = InputDevice.CATEGORY.FARMPANEL_MOZA
}
function InputDevice.new(internalId, deviceId, deviceName, category)
    -- upvalues: (copy) InputDevice_mt
    local self = setmetatable({}, InputDevice_mt)
    self.internalId = internalId
    self.deviceId = deviceId
    self.deviceName = deviceName
    self.category = category
    self.deadzones = {}
    self.sensitivities = {}
    self.isActive = false
    self.forceFeedbackState = {}
    local i = 0
    for i = i, Input.MAX_NUM_AXES do
        self.forceFeedbackState[i] = {
            ["isSupported"] = nil,
            ["force"] = 0,
            ["position"] = 0
        }
    end
    return self
end
function InputDevice:loadSettingsFromXML(xmlFile, deviceElement)
    self.deadzones = {}
    self.sensitivities = {}
    local attrIndex = 0
    while true do
        local attributeKey = string.format(deviceElement .. ".attributes(%d)", attrIndex)
        if not hasXMLProperty(xmlFile, attributeKey) then
            break
        end
        local axis = getXMLInt(xmlFile, attributeKey .. "#axis")
        if axis then
            local deadzone = getXMLFloat(xmlFile, attributeKey .. "#deadzone")
            self.deadzones[axis] = deadzone or getGamepadDefaultDeadzone()
            local sensitivity = getXMLFloat(xmlFile, attributeKey .. "#sensitivity")
            self.sensitivities[axis] = sensitivity or 1
        end
        attrIndex = attrIndex + 1
    end
end
function InputDevice:saveSettingsToXML(xmlFile, deviceElement)
    setXMLString(xmlFile, deviceElement .. "#id", self.deviceId)
    setXMLString(xmlFile, deviceElement .. "#name", self.deviceName)
    setXMLInt(xmlFile, deviceElement .. "#category", self.category)
    local firstAttributeKey = deviceElement .. ".attributes(0)"
    while hasXMLProperty(xmlFile, firstAttributeKey) do
        removeXMLProperty(xmlFile, firstAttributeKey)
    end
    local writtenIndex = 0
    local axisIndex = 0
    for axisIndex = axisIndex, Input.MAX_NUM_AXES - 1 do
        local attributeKey
        if self.internalId >= 0 then
            attributeKey = getHasGamepadAxis(axisIndex, self.internalId)
        else
            attributeKey = true
            if self.deadzones[axisIndex] == nil then
                attributeKey = self.sensitivities[axisIndex] ~= nil
            end
        end
        if attributeKey then
            local attributeKey = string.format(deviceElement .. ".attributes(%d)", writtenIndex)
            setXMLInt(xmlFile, attributeKey .. "#axis", axisIndex)
            setXMLFloat(xmlFile, attributeKey .. "#deadzone", self:getDeadzone(axisIndex))
            setXMLFloat(xmlFile, attributeKey .. "#sensitivity", self:getSensitivity(axisIndex))
            writtenIndex = writtenIndex + 1
        end
    end
end
function InputDevice:isController()
    return self.category and self.category ~= InputDevice.CATEGORY.KEYBOARD_MOUSE
end
function InputDevice:setDeadzone(axisIndex, deadzone)
    self.deadzones[axisIndex] = deadzone
end
function InputDevice:getDeadzone(axisIndex)
    if self.deadzones[axisIndex] == nil then
        return getGamepadDefaultDeadzone()
    else
        return self.deadzones[axisIndex]
    end
end
function InputDevice:setSensitivity(axisIndex, sensitivity)
    self.sensitivities[axisIndex] = sensitivity
end
function InputDevice:getSensitivity(axisIndex)
    return self.sensitivities[axisIndex] == nil and 1 or self.sensitivities[axisIndex]
end
function InputDevice:updateForceFeedbackState(axisIndex)
    local axisState = self.forceFeedbackState[axisIndex]
    if axisState ~= nil and axisState.isSupported == nil then
        axisState.isSupported = getHasGamepadAxisForceFeedback(self.internalId, axisIndex)
    end
    return false
end
function InputDevice:getIsForceFeedbackSupported(axisIndex)
    local axisState = self.forceFeedbackState[axisIndex]
    if axisState == nil or axisState.isSupported == nil then
        return false
    else
        return axisState.isSupported
    end
end
function InputDevice:setForceFeedback(axisIndex, force, position)
    local axisState = self.forceFeedbackState[axisIndex]
    if axisState ~= nil then
        axisState.force = force
        axisState.position = position
        setGamepadAxisForceFeedback(self.internalId, axisIndex, force, position)
    end
end
function InputDevice.loadIdFromXML(xmlFile, deviceElement)
    return getXMLString(xmlFile, deviceElement .. "#id") or ""
end
function InputDevice.loadNameFromXML(xmlFile, deviceElement)
    return getXMLString(xmlFile, deviceElement .. "#name") or ""
end
function InputDevice.loadCategoryFromXML(xmlFile, deviceElement)
    return getXMLInt(xmlFile, deviceElement .. "#category") or InputDevice.CATEGORY.UNKNOWN
end
function InputDevice.getDeviceIdPrefix(deviceId)
    local prefix, engineDeviceId = string.match(deviceId, "^(-?%d+)_(.+)$")
    local number = -1
    if prefix and tonumber(prefix) then
        number = tonumber(prefix)
    end
    return number, engineDeviceId
end
function InputDevice.getPrefixedDeviceId(deviceId, number)
    return string.format("%d_%s", number, deviceId)
end
function InputDevice.getIsDeviceSupported(_, deviceName)
    return deviceName ~= IgnitionLockManager.DEVICE_NAME
end
function InputDevice:toString()
    return string.format("[%s (active: %s), internalId: %s, deviceId: %s, category: %s]", tostring(self.deviceName), tostring(self.isActive), tostring(self.internalId), tostring(self.deviceId), (tostring(self.category)))
end
InputDevice_mt.__tostring = InputDevice.toString