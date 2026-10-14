MouseHelper = {}
KeyboardHelper = {}
GamepadHelper = {}
function MouseHelper.getButtonName(mouseButtonId)
    return getMouseButtonName(mouseButtonId)
end
function MouseHelper.getButtonNames(mouseButtons)
    local buttonsText = ""
    for i, buttonId in ipairs(mouseButtons) do
        local buttonName = getMouseButtonName(buttonId)
        if buttonName then
            if i ~= 1 then
            end
            buttonsText = buttonsText .. buttonName
        end
    end
    return buttonsText
end
function MouseHelper.getInputDisplayText(mouseInputs)
    local names = {}
    for _, inputName in ipairs(mouseInputs) do
        local inputId = InputBinding.MOUSE_AXES[inputName]
        if inputId then
            table.insert(names, inputId == Input.AXIS_Y and "Y" or "X")
        else
            local inputId = InputBinding.MOUSE_BUTTONS[inputName]
            if inputId then
                table.insert(names, getMouseButtonName(inputId))
            end
        end
    end
    return table.concat(names, ", ")
end
function MouseHelper.getButtonsXMLString(mouseButtons)
    local buttonsText = ""
    for i, buttonId in ipairs(mouseButtons) do
        local buttonIdName = Input.mouseButtonIdToIdName[buttonId]
        if buttonIdName ~= nil then
            if i ~= 1 then
            end
            buttonsText = buttonsText .. buttonIdName
        end
    end
    return buttonsText
end
KeyboardHelper.KEY_GLYPHS = {
    [13] = "keyGlyph_return",
    [271] = "keyGlyph_enter",
    [8] = "keyGlyph_backspace",
    [27] = "keyGlyph_escape",
    [32] = "keyGlyph_space",
    [273] = "keyGlyph_up",
    [274] = "keyGlyph_down",
    [275] = "keyGlyph_right",
    [276] = "keyGlyph_left",
    [306] = "keyGlyph_ctrl",
    [308] = "keyGlyph_alt"
}
if getPlatformId() == PlatformId.MAC then
    KeyboardHelper.KEY_GLYPHS[308] = "keyGlyph_option"
end
function KeyboardHelper.getDisplayKeyName(keyId)
    local keyName = nil
    local glyphSymbol = KeyboardHelper.KEY_GLYPHS[keyId]
    if glyphSymbol ~= nil then
        keyName = g_i18n:getText(glyphSymbol)
    end
    if keyName == nil then
        keyName = getKeyName(keyId)
    end
    return keyName
end
function KeyboardHelper.getKeyNames(keyList)
    local keyText = ""
    for i, keyId in ipairs(keyList) do
        if i ~= 1 then
        end
        keyText = keyText .. KeyboardHelper.getDisplayKeyName(keyId)
    end
    return keyText
end
function KeyboardHelper.getKeyNameTable(keyList)
    local keyTable = {}
    for _, keyId in ipairs(keyList) do
        table.insert(keyTable, KeyboardHelper.getDisplayKeyName(keyId))
    end
    return keyTable
end
function KeyboardHelper.getInputDisplayText(keyNames)
    local names = {}
    for _, keyName in ipairs(keyNames) do
        table.insert(names, KeyboardHelper.getDisplayKeyName(Input[keyName]))
    end
    return table.concat(names, ", ")
end
function KeyboardHelper.getKeysXMLString(keyList)
    if keyList == nil or keyList == -1 then
        return ""
    end
    local keyText = ""
    for i, keyId in ipairs(keyList) do
        local keyString = Input.keyIdToIdName[keyId]
        if keyString ~= nil then
            if i ~= 1 then
            end
            keyText = keyText .. keyString
        end
    end
    return keyText
end
function GamepadHelper.getGamepadInputCombinedName(gamepadsHash)
    local gamepadList = {}
    for gamepadId, gamepadData in pairs(gamepadsHash) do
        table.insert(gamepadList, gamepadId);
        ({})[gamepadId] = {}
        gamepadListData[gamepadId].buttonsList = {}
        gamepadListData[gamepadId].axesList = {}
        for gamepadButtonId, _ in pairs(gamepadData.buttons) do
            table.insert(gamepadListData[gamepadId].buttonsList, gamepadButtonId)
        end
        for gamepadButtonId, _ in pairs(gamepadData.axes) do
            table.insert(gamepadListData[gamepadId].axesList, gamepadButtonId)
        end
        table.sort(gamepadListData[gamepadId].buttonsList)
        table.sort(gamepadListData[gamepadId].axesList)
    end
    table.sort(gamepadList)
    local buttonsString = ""
    local axesString = ""
    for _, gamepadId in ipairs(gamepadList) do
        for j, gamepadButtonId in ipairs(gamepadListData[gamepadId].buttonsList) do
            buttonsString = buttonsString .. (j == 1 and "" or ", ") .. GamepadHelper.getButtonName(gamepadButtonId, gamepadId)
        end
        for j, gamepadButtonId in ipairs(gamepadListData[gamepadId].axesList) do
            axesString = axesString .. (j == 1 and "" or ", ") .. GamepadHelper.getAxisName(gamepadButtonId, gamepadId)
        end
    end
    return (buttonsString ~= "" and g_i18n:getText("ui_button") .. " " .. buttonsString .. " " or "") .. (axesString ~= "" and g_i18n:getText("ui_axis") .. " " .. axesString or "")
end
function GamepadHelper.getButtonName(buttonId, deviceId)
    if buttonId == nil then
        return ""
    end
    return getGamepadButtonLabel(buttonId, deviceId == nil and 0 or deviceId)
end
function GamepadHelper.getAxisName(axisId, deviceId)
    return axisId == nil and "" or getGamepadAxisLabel(axisId, deviceId)
end
function GamepadHelper.getButtonNames(buttonIdList, deviceId)
    if buttonIdList == nil then
        return ""
    end
    local buttonString = ""
    local listCount = #buttonIdList
    for i, buttonId in ipairs(buttonIdList) do
        local currentButton = GamepadHelper.getButtonName(buttonId, (i == listCount or not deviceId) and 0 or deviceId)
    end
    local buttonNamePrefix = ""
    if listCount == 1 then
        buttonNamePrefix = g_i18n:getText("ui_button") .. " "
    elseif listCount > 1 then
        buttonNamePrefix = g_i18n:getText("ui_buttons") .. " "
    end
    return buttonNamePrefix .. buttonString
end
function GamepadHelper.getButtonAndAxisNames(buttonIdList, axisId, deviceId)
    local buttonString = GamepadHelper.getButtonNames(buttonIdList)
    local axisString = GamepadHelper.getAxisName(axisId, deviceId)
    local deviceString = "(\'" .. GamepadHelper.getLocalizedGamepadName(deviceId) .. "\' " .. GamepadHelper.getDeviceString(deviceId) .. ")"
    return buttonString .. ((buttonString == "" or axisString == "") and "" or ", ") .. ((axisString == "" or not axisString) and "" or axisString) .. ((buttonString ~= "" or axisString ~= "") and " " .. deviceString or "")
end
function GamepadHelper.getLocalizedGamepadName(internalDeviceId)
    local gamepadName = getGamepadName(internalDeviceId)
    if g_i18n:hasText(gamepadName) then
        gamepadName = g_i18n:getText(gamepadName)
    end
    return gamepadName
end
function GamepadHelper.getInputDisplayText(inputList, internalDeviceId)
    local names = {}
    for _, input in ipairs(inputList) do
        if Input.buttonIdNameToId[input] then
            table.insert(names, GamepadHelper.getButtonName(Input.buttonIdNameToId[input], internalDeviceId))
        elseif Input.axisIdNameToId[input] then
            table.insert(names, GamepadHelper.getAxisName(Input.axisIdNameToId[input], internalDeviceId))
        end
    end
    local gamePadName = GamepadHelper.getLocalizedGamepadName(internalDeviceId)
    return string.format("%s [%s]", table.concat(names, ", "), gamePadName)
end
function GamepadHelper.getDeviceString(deviceId)
    return "[" .. deviceId + 1 .. "]"
end
function GamepadHelper.getButtonsXMLString(buttonIdList)
    if buttonIdList == nil then
        return ""
    end
    local buttonString = ""
    for i, buttonId in ipairs(buttonIdList) do

    end
    return buttonString
end
function GamepadHelper.getAxisXMLString(gamepadAxisId)
    return (gamepadAxisId == nil or gamepadAxisId == -1) and "" or "AXIS_" .. gamepadAxisId + 1
end
function GamepadHelper.getDeviceXMLInt(gamepadId)
    return (gamepadId == nil or gamepadId == -1) and 0 or gamepadId
end