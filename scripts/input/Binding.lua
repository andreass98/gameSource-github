Binding = {}
local Binding_mt = Class(Binding)
Binding.AXIS_COMPONENT = {
    ["POSITIVE"] = "+",
    ["NEGATIVE"] = "-"
}
Binding.INPUT_COMPONENT = {
    ["POSITIVE"] = "+",
    ["NEGATIVE"] = "-"
}
Binding.MAX_ALTERNATIVES_KB_MOUSE = 3
Binding.MAX_ALTERNATIVES_GAMEPAD = GS_IS_CONSOLE_VERSION and 3 or 2
Binding.PRESSED_MAGNITUDE_THRESHOLD = 0.1
Binding.PS_JAPAN_BUTTON_SWAP_MAP = {
    ["BUTTON_2"] = "BUTTON_3",
    ["BUTTON_3"] = "BUTTON_2"
}
function Binding.new(deviceId, axisNames, axisComponent, inputComponent, neutralInput, index)
    -- upvalues: (copy) Binding_mt
    local self = setmetatable({}, Binding_mt)
    self.axisComponent = axisComponent
    self.index = index
    if self.axisComponent == Binding.AXIS_COMPONENT.POSITIVE then
        self.axisDirection = 1
    else
        self.axisDirection = -1
    end
    self.id = nil
    self.comboMask = 0
    self.deviceId = nil
    self.deviceCategory = InputDevice.CATEGORY.UNKNOWN
    self.internalDeviceId = nil
    self.axisNameSet = nil
    self.inputString = ""
    self.unmodifiedAxis = nil
    self.modifierAxisSet = nil
    self.axisNames = {}
    self.inputComponent = nil
    self.inputDirection = 0
    self.neutralInput = neutralInput
    self.isMouse = false
    self.isKeyboard = false
    self.isGamepad = false
    self.isPrimary = false
    self:updateData(deviceId, nil, axisNames, inputComponent, true)
    self.isAnalog = false
    self.inputValue = 0
    self.isInputActive = false
    self.isDownFlank = false
    self.isUpFlank = false
    self.recievedDownFlankInCurrentContext = false
    self.enteredNewContextThisFrame = false
    self.isPressed = false
    self.isShadowed = false
    self.isActive = true
    self.hasFrameTriggered = false
    return self
end
function Binding.createFromXML(xmlFile, elementTag)
    local deviceId = getXMLString(xmlFile, elementTag .. "#device")
    local axisNames = (getXMLString(xmlFile, elementTag .. "#input") or ""):split(" ")
    local axisComponent = getXMLString(xmlFile, elementTag .. "#axisComponent")
    if axisComponent ~= Binding.AXIS_COMPONENT.POSITIVE and axisComponent ~= Binding.AXIS_COMPONENT.NEGATIVE then
        axisComponent = Binding.AXIS_COMPONENT.POSITIVE
    end
    local inputComponent = getXMLString(xmlFile, elementTag .. "#inputComponent")
    if inputComponent ~= Binding.INPUT_COMPONENT.POSITIVE and inputComponent ~= Binding.INPUT_COMPONENT.NEGATIVE then
        inputComponent = Binding.INPUT_COMPONENT.POSITIVE
        if #axisNames > 0 and axisNames[#axisNames]:sub(axisNames[#axisNames]:len()) == "-" then
            inputComponent = Binding.INPUT_COMPONENT.NEGATIVE
        end
    end
    local neutralInput = getXMLInt(xmlFile, elementTag .. "#neutralInput") or 0
    local index = getXMLInt(xmlFile, elementTag .. "#index") or -1
    return Binding.new(deviceId, axisNames, axisComponent, inputComponent, neutralInput, index)
end
function Binding:saveToXMLFile(xmlFile, elementTag)
    setXMLString(xmlFile, elementTag .. "#device", self.deviceId)
    local inputValue = table.concat(self.axisNames, " ")
    setXMLString(xmlFile, elementTag .. "#input", inputValue)
    setXMLString(xmlFile, elementTag .. "#axisComponent", self.axisComponent)
    setXMLInt(xmlFile, elementTag .. "#neutralInput", self.neutralInput)
    setXMLInt(xmlFile, elementTag .. "#index", self.index)
end
function Binding:updateData(deviceId, deviceCategory, axisNames, inputComponent, _)
    if axisNames ~= nil then
        self.axisNames = {}
        for _, axisName in ipairs(axisNames) do
            table.insert(self.axisNames, axisName)
        end
    end
    local axisName = inputComponent or self.inputComponent
    if axisName and axisName ~= Binding.INPUT_COMPONENT.POSITIVE then
        self.inputComponent = Binding.INPUT_COMPONENT.NEGATIVE
        self.inputDirection = -1
    else
        self.inputComponent = Binding.INPUT_COMPONENT.POSITIVE
        self.inputDirection = 1
    end
    if #self.axisNames > 0 then
        local axisName = self.axisNames[#self.axisNames]
        local s = axisName:sub(axisName:len())
        if s == "-" or s == "+" then
            axisName = axisName:sub(1, axisName:len() - 1)
        end
        if self.inputComponent == Binding.INPUT_COMPONENT.NEGATIVE then
        elseif InputBinding.getIsPhysicalFullAxis(axisName) then
        end
        self.axisNames[#self.axisNames] = axisName
    end
    self.deviceId = deviceId or self.deviceId
    self.deviceCategory = deviceCategory or self.deviceCategory
    self.axisNameSet = table.toSet(self.axisNames)
    self.inputString = table.concat(self.axisNames, " ")
    self.unmodifiedAxis = self.axisNames[#self.axisNames]
    self.modifierAxisSet = {}
    local i = 1
    local axisName = #self.axisNames - 1
    local s = 1
    for i = i, axisName, s do
        local _ = self.axisNames[i]
        self.modifierAxisSet[_] = _
    end
    local axisName = self.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT
    local s = axisName and self.index == Binding.MAX_ALTERNATIVES_KB_MOUSE
    self.isMouse = s
    local s = axisName and not self.isMouse
    self.isKeyboard = s
    local s = false
    if self.deviceId ~= nil then
        s = not axisName
    end
    self.isGamepad = s
    local s = self.index == 1
    self.isPrimary = s
end
function Binding:updateInput(inputValue, allInputActive)
    local isPressed
    if self.axisDirection >= 0 then
        self.inputValue = math.max(inputValue, 0)
        isPressed = Binding.PRESSED_MAGNITUDE_THRESHOLD <= inputValue
    else
        self.inputValue = math.min(inputValue, 0)
        isPressed = inputValue <= -Binding.PRESSED_MAGNITUDE_THRESHOLD
    end
    self.isShadowed = false
    self.hasFrameTriggered = false
    local downFlank = isPressed and not self.isPressed
    if downFlank then
        downFlank = not self.enteredNewContextThisFrame
    end
    local upFlank = not isPressed
    if upFlank then
        upFlank = self.isPressed
    end
    self.isDownFlank = downFlank
    self.isUpFlank = upFlank
    self.isPressed = isPressed
    self.enteredNewContextThisFrame = false
    if self.recievedDownFlankInCurrentContext or downFlank then
        downFlank = isPressed or upFlank
    end
    self.recievedDownFlankInCurrentContext = downFlank
    self.isInputActive = allInputActive or upFlank
end
function Binding:setIsAnalog(isAnalog)
    self.isAnalog = isAnalog
end
function Binding:setIndex(index)
    self.index = index
    local isKbMouse = index == 1
    self.isPrimary = isKbMouse
    local isKbMouse = self.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT
    if isKbMouse then
        isKbMouse = self.index == Binding.MAX_ALTERNATIVES_KB_MOUSE
    end
    self.isMouse = isKbMouse
end
function Binding:setActive(isActive)
    self.isActive = isActive
end
function Binding:setFrameTriggered(hasTriggered)
    self.hasFrameTriggered = hasTriggered
end
function Binding:getFrameTriggered()
    return self.hasFrameTriggered
end
function Binding:setComboMask(comboMask)
    self.comboMask = comboMask
end
function Binding:getComboMask()
    return self.comboMask
end
function Binding:hasCollisionWith(otherBinding)
    if self == otherBinding then
        return false
    end
    return self.deviceId == otherBinding.deviceId and table.equalLists(self.axisNames, otherBinding.axisNames, true)
end
function Binding:hasEventCollision(otherBinding)
    if self == otherBinding then
        return true
    end
    local sameDevice = self.deviceId == otherBinding.deviceId
    local sameInput = table.equalLists(self.axisNames, otherBinding.axisNames, true)
    local sameInputComponent = self.inputComponent == otherBinding.inputComponent
    if sameDevice then
        if not sameInput then
            sameInputComponent = sameInput
        end
    else
        sameInputComponent = sameDevice
    end
    return sameInputComponent
end
function Binding:clone()
    local clone = Binding.new(self.deviceId, self.axisNames, self.axisComponent, self.inputComponent, self.neutralInput, self.index)
    clone:updateData(self.deviceId, self.deviceCategory, self.axisNames, self.inputComponent, false)
    clone.internalDeviceId = self.internalDeviceId
    clone.isAnalog = self.isAnalog
    clone.comboMask = self.comboMask
    clone.isActive = self.isActive
    return clone
end
function Binding:copyInputStateFrom(src)
    self.isDownFlank = src.isDownFlank
    self.isUpFlank = src.isUpFlank
    self.isPressed = src.isPressed
    self.isInputActive = src.isInputActive
    self.recievedDownFlankInCurrentContext = src.recievedDownFlankInCurrentContext
    self.enteredNewContextThisFrame = src.enteredNewContextThisFrame
end
function Binding:resetInputState()
    self.enteredNewContextThisFrame = true
    self.recievedDownFlankInCurrentContext = false
end
function Binding:isSameSlot(otherBinding)
    local sameComponent = self.axisComponent == otherBinding.axisComponent
    local sameCategory = not (self.isKeyboard and otherBinding.isKeyboard) and (not (self.isMouse and otherBinding.isMouse) and self.isGamepad)
    if sameCategory then
        sameCategory = otherBinding.isGamepad
    end
    local sameDevice = self.deviceId == otherBinding.deviceId
    if sameComponent then
        if sameCategory then
            if not (self.index == otherBinding.index) then
                sameDevice = sameIndex
            end
        else
            sameDevice = sameCategory
        end
    else
        sameDevice = sameComponent
    end
    return sameDevice
end
function Binding:isSameSlotWithParams(axisComponent, isKbMouse, slotIndex)
    local sameComponent = self.axisComponent == axisComponent
    local sameIndex = self.index == slotIndex
    if sameComponent then
        if not ((self.isKeyboard or self.isMouse) == isKbMouse) then
            sameIndex = sameCategory
        end
    else
        sameIndex = sameComponent
    end
    return sameIndex
end
function Binding.getOppositeAxisComponent(axisComponent)
    if axisComponent == Binding.AXIS_COMPONENT.POSITIVE then
        return Binding.AXIS_COMPONENT.NEGATIVE
    elseif axisComponent == Binding.AXIS_COMPONENT.NEGATIVE then
        return Binding.AXIS_COMPONENT.POSITIVE
    else
        return nil
    end
end
function Binding.getOppositeInputComponent(inputComponent)
    if inputComponent == Binding.INPUT_COMPONENT.POSITIVE then
        return Binding.INPUT_COMPONENT.NEGATIVE
    elseif inputComponent == Binding.INPUT_COMPONENT.NEGATIVE then
        return Binding.INPUT_COMPONENT.POSITIVE
    else
        return nil
    end
end
function Binding:makeId()
    if self.id == nil then
        self.id = string.format("%s|%s|%s|%s|%s", self.deviceId, table.concat(self.axisNames, ";"), self.axisComponent, self.neutralInput, self.index)
    end
end
function Binding:toString()
    return string.format("[(%s), deviceId: %s, axisComponent: %s, index: %s, isActive: %s, isShadowed: %s isInverted: %s, isDown: %s, isUp: %s, inputValue: %s]", table.concat(self.axisNames, ", "), self.deviceId, self.axisComponent, self.index, self.isActive, self.isShadowed, self.isInverted, self.isDownFlank, self.isUpFlank, self.inputValue)
end
Binding_mt.__tostring = Binding.toString