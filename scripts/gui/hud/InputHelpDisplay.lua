local data = nil
if InputHelpDisplay ~= nil then
    local old = g_currentMission.hud.inputHelp
    data = {
        ["uiScale"] = old.uiScale,
        ["isVisible"] = old:getVisible(),
        ["vehicle"] = old.vehicle
    }
    old:delete()
end
InputHelpDisplay = {}
InputHelpDisplay.MAX_NUM_ELEMENTS = 6
InputHelpDisplay.MAX_NUM_ELEMENTS_HIGH_PRIORITY = 16
InputHelpDisplay.MAX_SCHEMA_COLLECTION_DEPTH = 5
InputHelpDisplay.SCHEMA_OVERLAY_DEFINITIONS_PATH = "dataS/vehicleSchemaOverlays.xml"
local old = Class(InputHelpDisplay, HUDDisplay)
function InputHelpDisplay.new()
    -- upvalues: (copy) old
    local self = InputHelpDisplay:superClass().new(old)
    self.vehicle = nil
    self.extraHelpTexts = {}
    self.helpExtensions = {}
    self.infoExtensions = {}
    self.skipActions = {}
    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.lineBg = g_overlayManager:createOverlay("gui.shortcutBox1", 0, 0, 0, 0)
    self.lineBg:setColor(r, g, b, a)
    self.lineBgLeft = g_overlayManager:createOverlay("gui.shortcutBox1_left", 0, 0, 0, 0)
    self.lineBgLeft:setColor(r, g, b, a)
    self.lineBgScale = g_overlayManager:createOverlay("gui.shortcutBox1_middle", 0, 0, 0, 0)
    self.lineBgScale:setColor(r, g, b, a)
    self.lineBgRight = g_overlayManager:createOverlay("gui.shortcutBox1_right", 0, 0, 0, 0)
    self.lineBgRight:setColor(r, g, b, a)
    self.comboBg = g_overlayManager:createOverlay("gui.shortcutBox2", 0, 0, 0, 0)
    self.comboBg:setColor(r, g, b, a)
    self.comboText = utf8ToUpper(g_i18n:getText("ui_controlsAdvanced"))
    self.controlGroupText = utf8ToUpper(g_i18n:getText("ui_controlsControlGroup"))
    self.glyphButtonOverlay = GlyphButtonOverlay.new()
    self.glyphButtonOverlay:setColor(nil, nil, nil, nil, 0, 0, 0, 0.8)
    self.keyButtonOverlay = ButtonOverlay.new()
    self.keyButtonOverlay:setColor(nil, nil, nil, nil, 0, 0, 0, 0.8)
    self.separatorHorizontal = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
    self.separatorHorizontal:setColor(1, 1, 1, 0.25)
    self.separatorVertical = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
    self.separatorVertical:setColor(1, 1, 1, 0.25)
    self.mouseComboOverlays = {}
    for _, combo in ipairs(InputBinding.ORDERED_MOUSE_COMBOS) do
        local actionName = combo.controls
        local helpElement = g_inputDisplayManager:getControllerSymbolOverlays(actionName, "", "", false)
        local overlays = {}
        for _, button in ipairs(helpElement.buttons) do
            table.insert(overlays, button)
        end
        table.insert(self.mouseComboOverlays, {
            ["actionName"] = actionName,
            ["overlays"] = overlays,
            ["mask"] = combo.mask
        })
    end
    self:updateGamepadComboButtons()
    self.vehicle = nil
    self.vehicleSchemaOverlays = {}
    self.iconSizeX = 0
    self.iconSizeY = 0
    self.maxSchemaWidth = 0
    g_messageCenter:subscribe(MessageType.INPUT_DEVICES_CHANGED, self.updateGamepadComboButtons, self)
    return self
end
function InputHelpDisplay:delete()
    self.lineBg:delete()
    self.lineBgLeft:delete()
    self.lineBgScale:delete()
    self.lineBgRight:delete()
    self.comboBg:delete()
    self.glyphButtonOverlay:delete()
    self.keyButtonOverlay:delete()
    self.separatorHorizontal:delete()
    self.separatorVertical:delete()
    for k, v in pairs(self.vehicleSchemaOverlays) do
        v:delete()
        self.vehicleSchemaOverlays[k] = nil
    end
    g_messageCenter:unsubscribe(MessageType.INPUT_DEVICES_CHANGED, self)
    InputHelpDisplay:superClass().delete(self)
end
function InputHelpDisplay:storeScaledValues()
    self:setPosition(g_hudAnchorLeft, g_hudAnchorTop)
    local lineWidth, lineHeight = self:scalePixelValuesToScreenVector(330, 25)
    self.lineBg:setDimension(lineWidth, lineHeight)
    local partWidth, comboWidth = self:scalePixelValuesToScreenVector(340, -25)
    self.helpAnchorOffsetX = partWidth
    self.helpAnchorOffsetY = comboWidth
    local partWidth = self:scalePixelToScreenWidth(6)
    self.lineBgLeft:setDimension(partWidth, lineHeight)
    self.lineBgScale:setDimension(0, lineHeight)
    self.lineBgRight:setDimension(partWidth, lineHeight)
    local comboWidth, comboHeight = self:scalePixelValuesToScreenVector(330, 50)
    self.comboBg:setDimension(comboWidth, comboHeight)
    self.lineOffsetY = self:scalePixelToScreenHeight(5)
    self.textSize = self:scalePixelToScreenHeight(12)
    verticalSeparatorHeight, self.textOffsetY = self:scalePixelValuesToScreenVector(14, 8)
    self.textOffsetX = verticalSeparatorHeight
    verticalSeparatorHeight, self.comboTextOffsetY = self:scalePixelValuesToScreenVector(14, 32)
    self.comboTextOffsetX = verticalSeparatorHeight
    verticalSeparatorHeight, self.comboSeparatorOffsetY = self:scalePixelValuesToScreenVector(0, 24)
    self.comboSeparatorOffsetX = verticalSeparatorHeight
    self.comboIconWidth, self.comboIconHeight = self:scalePixelValuesToScreenVector(24, 24)
    self.separatorHorizontal:setDimension(lineWidth, g_pixelSizeY)
    local verticalSeparatorHeight = self:scalePixelToScreenHeight(24)
    self.separatorVertical:setDimension(g_pixelSizeX, verticalSeparatorHeight)
    self.keyButtonOverlay:setMinWidth(self:scalePixelToScreenWidth(35))
    self.glyphButtonOverlay:setMinWidth(self:scalePixelToScreenWidth(35))
    self.schemaOffsetX, self.schemaOffsetY = self:scalePixelValuesToScreenVector(14, 2)
    self.iconSizeX, self.iconSizeY = self:scalePixelValuesToScreenVector(26, 26)
    self.maxSchemaWidth = self:scalePixelToScreenWidth(180)
    for _, overlay in pairs(self.vehicleSchemaOverlays) do
        overlay:resetDimensions()
        local width, height = self:scalePixelToScreenVector({ overlay.defaultWidth, overlay.defaultHeight })
        overlay:setDimension(width, height)
    end
end
function InputHelpDisplay:draw(offsetX, offsetY)
    local isVisible = self:getVisible()
    local posX, posY = self:getPosition()
    local posX = posX + (offsetX or 0)
    local inputBinding, inputDisplayManager = self:drawVehicleSchema(posX, posY + (offsetY or 0), not isVisible)
    if not isVisible then
        return
    end
    local inputBinding = g_inputBinding
    local inputDisplayManager = g_inputDisplayManager
    local pressedComboMaskGamepad, pressedComboMaskMouse = inputBinding:getComboCommandPressedMask()
    local useGamepadButtons = GS_IS_CONSOLE_VERSION
    if not useGamepadButtons then
        useGamepadButtons = inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD
    end
    local currentPressedMask = useGamepadButtons and pressedComboMaskGamepad and pressedComboMaskGamepad or pressedComboMaskMouse
    local comboActionStatus = inputDisplayManager:getComboHelpElements(useGamepadButtons)
    local hasComboCommands = next(comboActionStatus) ~= nil
    local eventHelpElements = inputDisplayManager:getEventHelpElements(currentPressedMask, useGamepadButtons)
    if (eventHelpElements == nil or #eventHelpElements == 0) and (not hasComboCommands and currentPressedMask ~= 0) then
        eventHelpElements = inputDisplayManager:getEventHelpElements(0, useGamepadButtons)
    end
    table.sort(self.helpExtensions, function(a, b)
        return a.priority < b.priority
    end)
    table.sort(self.infoExtensions, function(a, b)
        if a.priority ~= b.priority then
            return a.priority < b.priority
        end
        if a.vehicle == nil or (b.vehicle == nil or (a.vehicle.lastDistanceToCamera == nil or b.vehicle.lastDistanceToCamera == nil)) then
            return true
        end
        return a.vehicle.lastDistanceToCamera < b.vehicle.lastDistanceToCamera
    end)
    local helpExtensionTotalHeight = 0
    local i = #self.helpExtensions
    local infoExtensionTotalHeight = 1
    local ignoreComboButtons = -1
    for i = i, infoExtensionTotalHeight, ignoreComboButtons do
        local helpExtension = self.helpExtensions[i]
        if helpExtension.setEventHelpElements ~= nil then
            helpExtension:setEventHelpElements(self, eventHelpElements)
        end
        local height = helpExtension:getHeight()
        if height > 0 then
        else
            table.remove(self.helpExtensions, i)
        end
    end
    local infoExtensionTotalHeight = 0
    local helpExtension = #self.infoExtensions
    local ignoreComboButtons = 1
    local i = -1
    for helpExtension = helpExtension, ignoreComboButtons, i do
        local height = self.infoExtensions[helpExtension]
        if height.setEventHelpElements ~= nil then
            height:setEventHelpElements(self, eventHelpElements)
        end
        local height = height:getHeight()
        if height > 0 then
        else
            table.remove(self.infoExtensions, helpExtension)
        end
    end
    local ignoreComboButtons = false
    local posX
    if hasComboCommands then
        ignoreComboButtons = true
        local posY = inputBinding - self.comboBg.height
        self.comboBg:renderCustom(posX, posY)
        setTextBold(true)
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextColor(1, 1, 1, 1)
        renderText(posX + self.comboTextOffsetX, posY + self.comboTextOffsetY, self.textSize, self.comboText)
        self.separatorHorizontal:renderCustom(posX + self.comboSeparatorOffsetX, posY + self.comboSeparatorOffsetY)
        local i = self.mouseComboOverlays
        if useGamepadButtons then
            i = self.gamepadComboOverlays
        else
            pressedComboMaskGamepad = pressedComboMaskMouse
        end
        local height = #i
        local height = self.comboBg.width / height
        for k, comboInfo in ipairs(i) do
            if comboActionStatus[comboInfo.actionName] then
                local b = comboInfo.mask
                local isPressed = bit32.band(pressedComboMaskGamepad, b) ~= 0
                local r = 1
                local g = 1
                local b = 1
                local a = 1
                if isPressed then
                    r = HUD.COLOR.ACTIVE[1]
                    g = activeColor[2]
                    b = activeColor[3]
                    a = activeColor[4]
                end
                local numOverlays = #comboInfo.overlays
                local spacingX = (height - self.comboIconWidth * numOverlays) / (numOverlays + 3)
                local overlayPosX = posX + 2 * spacingX
                for _, overlay in ipairs(comboInfo.overlays) do
                    overlay:renderCustom(overlayPosX, posY, self.comboIconWidth, self.comboIconHeight, r, g, b, a)
                    overlayPosX = overlayPosX + spacingX + self.comboIconWidth
                end
            end
            if k < height then
                posX = posX + height
                self.separatorVertical:renderCustom(posX, posY)
            end
        end
    end
    local i = 0
    for activeColor, iconPosX in pairs(self.helpExtensions) do
        if iconPosX.priority <= GS_PRIO_LOW then
        end
    end
    if eventHelpElements ~= nil then
        for activeColor, iconPosX in ipairs(eventHelpElements) do
            if self.skipActions[iconPosX.actionName] == nil then
                if iconPosX.actionName == InputAction.SWITCH_IMPLEMENT and inputDisplayManager ~= nil then
                    local buttons = iconPosX.buttons
                    local k = self.lineBg
                    local comboInfo = k.height
                    inputDisplayManager = inputDisplayManager - comboInfo
                    if #buttons > 0 then
                        local isPressed = self.glyphButtonOverlay:getButtonWidth(buttons, iconPosX.isComboButtonMapping, true, comboInfo)
                        self.glyphButtonOverlay:renderButton(buttons, isComboButtonMapping, true, posX + k.width - isPressed, inputDisplayManager, comboInfo)
                    elseif #iconPosX.keys > 0 then
                        local isPressed = posX + k.width
                        local b = #keys
                        for b = b, 1, -1 do
                            local a = keys[b]
                            isPressed = isPressed - (self.keyButtonOverlay:getButtonWidth(a, comboInfo) + g_pixelSizeX)
                            self.keyButtonOverlay:renderButton(a, isPressed, inputDisplayManager, comboInfo, true)
                        end
                    end
                else
                    inputBinding = self:drawInputHelpElement(posX, inputBinding, iconPosX, ignoreComboButtons) - self.lineOffsetY
                end
                i = i + 1
                if (iconPosX.priority <= GS_PRIO_HIGH and InputHelpDisplay.MAX_NUM_ELEMENTS_HIGH_PRIORITY or InputHelpDisplay.MAX_NUM_ELEMENTS) < i then
                    break
                end
            else
                self.skipActions[iconPosX.actionName] = nil
            end
        end
    end
    for activeColor, iconPosX in pairs(self.helpExtensions) do
        if i < (iconPosX.priority <= GS_PRIO_LOW and InputHelpDisplay.MAX_NUM_ELEMENTS_HIGH_PRIORITY or InputHelpDisplay.MAX_NUM_ELEMENTS) then
            inputBinding = iconPosX:draw(self, posX, inputBinding) - self.lineOffsetY
        end
        self.helpExtensions[activeColor] = nil
    end
    for activeColor, iconPosX in pairs(self.infoExtensions) do
        local buttons = iconPosX:draw(self, posX, inputBinding)
        if buttons ~= inputBinding then
            inputBinding = buttons - self.lineOffsetY
        end
        self.infoExtensions[activeColor] = nil
    end
    for activeColor, iconPosX in pairs(self.extraHelpTexts) do
        inputBinding = self:drawExtraText(posX, inputBinding, iconPosX) - self.lineOffsetY
        self.extraHelpTexts[activeColor] = nil
    end
end
function InputHelpDisplay:drawInputHelpElement(posX, posYTop, helpElement, ignoreComboButtons)
    local lineBg = self.lineBg
    local iconHeight = lineBg.height
    local posY = posYTop - iconHeight
    lineBg:renderCustom(posX, posY)
    local buttons = helpElement.buttons
    local maxWidth = lineBg.width
    if #buttons > 0 then
        local totalWidth = self.glyphButtonOverlay:getButtonWidth(buttons, helpElement.isComboButtonMapping, ignoreComboButtons, iconHeight)
        self.glyphButtonOverlay:renderButton(buttons, isComboButtonMapping, ignoreComboButtons, posX + lineBg.width - totalWidth, posY, iconHeight)
    elseif #helpElement.keys > 0 then
        local totalWidth = posX + lineBg.width
        local i = #keys
        for i = i, 1, -1 do
            local key = keys[i]
            local width = self.keyButtonOverlay:getButtonWidth(key, iconHeight) + g_pixelSizeX
            totalWidth = totalWidth - width
            self.keyButtonOverlay:renderButton(key, totalWidth, posY, iconHeight, true)
        end
    end
    local totalWidth = helpElement.iconOverlay
    if totalWidth ~= nil then
        totalWidth:renderCustom(posX + self.textOffsetX, posY, iconHeight / g_screenAspectRatio, iconHeight, 1, 1, 1, 1)
        return posY
    end
    local startPosX = self.textOffsetX
    local textOffsetY = self.textOffsetY
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
    local i = utf8ToUpper(helpElement.text)
    local key = Utils.limitTextToWidth(i, self.textSize, maxWidth - 2 * startPosX, false, "...")
    renderText(posX + startPosX, posY + textOffsetY, self.textSize, key)
    return posY
end
function InputHelpDisplay:drawInput(posX, posY, height, helpElement, lastButtonCustomOffsetLeft, customButtonInputText)
    local buttons = helpElement.buttons
    local isComboButtonMapping = helpElement.isComboButtonMapping
    local width = 0
    if #buttons <= 0 then
        if #helpElement.keys > 0 then
            local i = #keys
            for i = i, 1, -1 do
                local key = keys[i]
                local offset = i == #keys and lastButtonCustomOffsetLeft and lastButtonCustomOffsetLeft or 0
                local keyWidth = self.keyButtonOverlay:getButtonWidth(key, height, offset, customButtonInputText)
                local startPosX = posX - keyWidth
                self.keyButtonOverlay:renderButton(key, startPosX, posY, height, true, nil, nil, nil, nil, offset, customButtonInputText)
            end
        end
        return width
    end
    local startPosX = self.glyphButtonOverlay:getButtonWidth(buttons, isComboButtonMapping, true, height, lastButtonCustomOffsetLeft, customButtonInputText)
    local startPosX = posX - startPosX
    self.glyphButtonOverlay:renderButton(buttons, isComboButtonMapping, true, startPosX, posY, height, false, nil, nil, nil, nil, lastButtonCustomOffsetLeft, customButtonInputText)
    return startPosX
end
function InputHelpDisplay:drawExtraText(posX, posYTop, text)
    local lineBg = self.lineBg
    local posY = posYTop - lineBg.height
    lineBg:renderCustom(posX, posY)
    local textOffsetX = self.textOffsetX
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
    text = utf8ToUpper(text)
    text = Utils.limitTextToWidth(text, self.textSize, lineBg.width - 2 * textOffsetX, false, "...")
    renderText(posX + textOffsetX, posY + self.textOffsetY, self.textSize, text)
    return posY
end
function InputHelpDisplay:drawVehicleSchema(posX, posY, isShortVersion)
    local vehicle = self.vehicle
    if vehicle == nil or vehicle.schemaOverlay == nil then
        return posY, nil
    end
    self:getVehicleSchemaOverlays(vehicle.rootVehicle)
    local lineBg, lineHeight = self:getSchemaDelimiters()
    if isShortVersion then
        posY = posY - self.lineBg.height
        self.lineBgScale:setDimension(lineHeight - lineBg + 2 * self.schemaOffsetX - 2 * self.lineBgLeft.width, nil)
        self.lineBgLeft:setPosition(posX, posY)
        self.lineBgScale:setPosition(self.lineBgLeft.x + self.lineBgLeft.width, posY)
        self.lineBgRight:setPosition(self.lineBgScale.x + self.lineBgScale.width, posY)
        self.lineBgLeft:render()
        self.lineBgScale:render()
        self.lineBgRight:render()
    else
        posY = posY - self.comboBg.height
        self.comboBg:renderCustom(posX, posY)
        setTextBold(true)
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextColor(1, 1, 1, 1)
        renderText(posX + self.comboTextOffsetX, posY + self.comboTextOffsetY, self.textSize, self.controlGroupText)
        self.separatorHorizontal:renderCustom(posX + self.comboSeparatorOffsetX, posY + self.comboSeparatorOffsetY)
    end
    local lineBg = 1
    local lineHeight = lineHeight - lineBg
    if self.maxSchemaWidth < lineHeight then
        lineBg = self.maxSchemaWidth / lineHeight
    end
    posX = posX - lineBg + self.schemaOffsetX
    posY = posY + self.schemaOffsetY
    for _, overlayDesc in ipairs(self.schemaOverlayEntryCache) do
        if overlayDesc.isUsed then
            local overlay = overlayDesc.overlay
            local width = overlay.width
            local height = overlay.height
            overlay:setInvertX(overlayDesc.invertX)
            overlay:setPosition(posX + overlayDesc.x, posY + overlayDesc.y)
            overlay:setRotation(overlayDesc.rotation, 0, 0)
            overlay:setDimension(width * lineBg, height * lineBg)
            local color = overlayDesc.turnedOn and HUD.COLOR.ACTIVE or HUD.COLOR.DEFAULT
            overlay:setColor(color[1], color[2], color[3], overlayDesc.selected and 1 or 0.5)
            overlay:render()
            if overlayDesc.additionalText ~= nil then
                setTextBold(false)
                setTextColor(1, 1, 1, 1)
                setTextAlignment(RenderText.ALIGN_CENTER)
                renderText(posX + overlayDesc.x + width * lineBg * 0.5, posY + overlayDesc.y + height * lineBg * 0.85, getCorrectTextSize(0.008), overlayDesc.additionalText)
                setTextAlignment(RenderText.ALIGN_LEFT)
                setTextColor(1, 1, 1, 1)
            end
            overlay:setDimension(width, height)
        end
        overlayDesc.isUsed = false
    end
    self.schemaOverlayEntryCacheIndex = 0
    return posY - self.lineOffsetY, posY
end
function InputHelpDisplay:addSkipAction(actionName)
    self.skipActions[actionName] = true
end
function InputHelpDisplay:addHelpText(text)
    if self:getVisible() then
        table.insert(self.extraHelpTexts, text)
    end
end
function InputHelpDisplay:addHelpExtension(extension)
    if self:getVisible() then
        table.addElement(self.helpExtensions, extension)
    end
end
function InputHelpDisplay:addInfoExtension(extension)
    if self:getVisible() then
        table.addElement(self.infoExtensions, extension)
    end
end
function InputHelpDisplay:removeInfoExtension(extension)
    table.removeElement(self.infoExtensions, extension)
end
function InputHelpDisplay:setVehicle(vehicle)
    self.vehicle = vehicle
end
function InputHelpDisplay:updateGamepadComboButtons()
    self.gamepadComboOverlays = {}
    for _, combo in ipairs(InputBinding.ORDERED_GAMEPAD_COMBOS) do
        local actionName = combo.controls
        local helpElement = g_inputDisplayManager:getControllerSymbolOverlays(actionName, "", "", false)
        local overlays = {}
        for _, button in ipairs(helpElement.buttons) do
            table.insert(overlays, button)
        end
        table.insert(self.gamepadComboOverlays, {
            ["actionName"] = actionName,
            ["overlays"] = overlays,
            ["mask"] = combo.mask
        })
    end
end
function InputHelpDisplay:getSchemaOverlayForState(schemaOverlayData, isImplement, _)
    local schemaName = schemaOverlayData.schemaName
    local schemaName = schemaName == "DEFAULT_IMPLEMENT" and "IMPLEMENT" or (schemaName == "DEFAULT_VEHICLE" and "VEHICLE" or schemaName)
    if not schemaName or (schemaName == "" or self.vehicleSchemaOverlays[schemaName] == nil) then
        schemaName = isImplement and VehicleSchemaOverlayData.SCHEMA_OVERLAY.IMPLEMENT or VehicleSchemaOverlayData.SCHEMA_OVERLAY.VEHICLE
    end
    return self.vehicleSchemaOverlays[schemaName]
end
function InputHelpDisplay:getSchemaDelimiters()
    local minX = math.huge
    local maxX = -math.huge
    for _, overlayDesc in ipairs(self.schemaOverlayEntryCache) do
        if not overlayDesc.isUsed then
            break
        end
        local overlay = overlayDesc.overlay
        local cosRot = math.cos(overlayDesc.rotation)
        local x = overlayDesc.x + overlayDesc.invisibleBorderLeft * overlay.width * cosRot
        local dx2 = (overlay.width + (overlayDesc.invisibleBorderRight + overlayDesc.invisibleBorderLeft) * overlay.width) * cosRot
        local dx3 = -overlay.height * math.sin(overlayDesc.rotation)
        local dx4 = dx2 + dx3
        maxX = math.max(maxX, x, x + dx2, x + dx3, x + dx4)
        minX = math.min(minX, x, x + dx2, x + dx3, x + dx4)
    end
    return minX, maxX
end
function InputHelpDisplay:getVehicleSchemaOverlays(vehicle)
    local overlay = self:getSchemaOverlayForState(vehicle.schemaOverlay, false)
    local entry = self:getOrCreateEntry()
    entry.isUsed = true
    entry.overlay = overlay
    entry.additionalText = vehicle:getAdditionalSchemaText()
    entry.x = 0
    entry.y = 0
    entry.rotation = 0
    entry.invertX = false
    entry.invisibleBorderRight = vehicle.schemaOverlay.invisibleBorderRight
    entry.invisibleBorderLeft = vehicle.schemaOverlay.invisibleBorderLeft
    entry.turnedOn = vehicle:getUseTurnedOnSchema()
    entry.selected = vehicle:getIsSelected()
    self:collectVehicleSchemaDisplayOverlays(1, vehicle, vehicle, overlay, 0, 0, 0, false)
    return overlay.height
end
function InputHelpDisplay:collectVehicleSchemaDisplayOverlays(depth, vehicle, rootVehicle, parentOverlay, x, y, rotation, invertingX)
    if vehicle.getAttachedImplements ~= nil then
        local attachedImplements = vehicle:getAttachedImplements()
        for _, implement in pairs(attachedImplements) do
            local object = implement.object
            if object ~= nil and object.schemaOverlay ~= nil then
                local selected = object:getIsSelected()
                local turnedOn = object:getUseTurnedOnSchema()
                local jointDesc = vehicle.schemaOverlay.attacherJoints[implement.jointDescIndex]
                if jointDesc ~= nil then
                    local invertX = invertingX ~= jointDesc.invertX
                    local overlay = self:getSchemaOverlayForState(object.schemaOverlay, true)
                    local baseY = y + jointDesc.y * parentOverlay.height
                    local baseX
                    if invertX then
                        baseX = x + jointDesc.x * parentOverlay.width
                    else
                        baseX = x - overlay.width + (1 - jointDesc.x) * parentOverlay.width
                    end
                    local rot = rotation + jointDesc.rotation
                    local offsetX
                    if invertX then
                        offsetX = -object.schemaOverlay.offsetX * overlay.width
                    else
                        offsetX = object.schemaOverlay.offsetX * overlay.width
                    end
                    local offsetY = object.schemaOverlay.offsetY * overlay.height
                    local rotatedX = offsetX * math.cos(rot) - offsetY * math.sin(rot)
                    local rotatedY = offsetX * math.sin(rot) + offsetY * math.cos(rot)
                    local baseX = baseX - rotatedX
                    local baseY = baseY - rotatedY
                    local isLowered = false
                    if object.getIsLowered ~= nil then
                        isLowered = object:getIsLowered(true)
                    end
                    if not isLowered then
                        local widthOffset, heightOffset = getNormalizedScreenValues(jointDesc.liftedOffsetX, jointDesc.liftedOffsetY)
                    end
                    local widthOffset = object:getAdditionalSchemaText()
                    local heightOffset = self:getOrCreateEntry()
                    heightOffset.isUsed = true
                    heightOffset.overlay = overlay
                    heightOffset.additionalText = widthOffset
                    heightOffset.x = baseX
                    heightOffset.y = baseY
                    heightOffset.rotation = rot
                    heightOffset.invertX = not invertX
                    heightOffset.invisibleBorderRight = object.schemaOverlay.invisibleBorderRight
                    heightOffset.invisibleBorderLeft = object.schemaOverlay.invisibleBorderLeft
                    heightOffset.turnedOn = turnedOn
                    heightOffset.selected = selected
                    if depth <= InputHelpDisplay.MAX_SCHEMA_COLLECTION_DEPTH then
                        self:collectVehicleSchemaDisplayOverlays(depth + 1, object, rootVehicle, overlay, baseX, baseY, rot, invertX)
                    end
                end
            end
        end
    end
end
function InputHelpDisplay:getOrCreateEntry()
    if self.schemaOverlayEntryCache == nil then
        self.schemaOverlayEntryCache = table.create(10)
        self.schemaOverlayEntryCacheIndex = 0
    end
    self.schemaOverlayEntryCacheIndex = self.schemaOverlayEntryCacheIndex + 1
    local entry = self.schemaOverlayEntryCache[self.schemaOverlayEntryCacheIndex]
    if entry == nil then
        table.insert(self.schemaOverlayEntryCache, {
            ["isUsed"] = false,
            ["overlay"] = nil,
            ["additionalText"] = nil,
            ["x"] = 0,
            ["y"] = 0,
            ["rotation"] = 0,
            ["invertX"] = false,
            ["invisibleBorderRight"] = 0,
            ["invisibleBorderLeft"] = 0,
            ["turnedOn"] = false,
            ["selected"] = false
        })
    end
    return entry
end
function InputHelpDisplay:loadVehicleSchemaOverlays()
    local xmlFile = loadXMLFile("VehicleSchemaDisplayOverlays", InputHelpDisplay.SCHEMA_OVERLAY_DEFINITIONS_PATH)
    self:loadVehicleSchemaOverlaysFromXML(xmlFile)
    delete(xmlFile)
    for _, modDesc in ipairs(g_modManager:getActiveMods()) do
        local xmlFile = loadXMLFile("InputHelpDisplay ModFile", modDesc.modFile)
        if xmlFile ~= 0 then
            self:loadVehicleSchemaOverlaysFromXML(xmlFile, modDesc.modFile)
            delete(xmlFile)
        end
    end
end
function InputHelpDisplay:loadVehicleSchemaOverlaysFromXML(xmlFile, modPath)
    local rootPath = "vehicleSchemaOverlays"
    local baseDirectory = ""
    local prefix = ""
    if modPath then
        rootPath = "modDesc.vehicleSchemaOverlays"
        prefix, baseDirectory = Utils.getModNameAndBaseDirectory(modPath)
    end
    local modName = getXMLString(xmlFile, rootPath .. "#filename")
    local dir = string.getVector(getXMLString(xmlFile, rootPath .. "#imageSize"), 2) or { 1024, 1024 }
    local i = 0
    while true do
        local baseName = string.format("%s.overlay(%d)", rootPath, i)
        if not hasXMLProperty(xmlFile, baseName) then
            break
        end
        local baseOverlayName = getXMLString(xmlFile, baseName .. "#name")
        local uvString = getXMLString(xmlFile, baseName .. "#uvs") or string.format("0px 0px %ipx %ipx", dir[1], dir[2])
        local uvs = GuiUtils.getUVs(uvString, dir)
        local sizeString = getXMLString(xmlFile, baseName .. "#size") or "26px 26px"
        local size = GuiUtils.getNormalizedValues(sizeString, { 1, 1 })
        if baseOverlayName then
            local atlasFileName = Utils.getFilename(modName, baseDirectory)
            local schemaOverlay = Overlay.new(atlasFileName, 0, 0, size[1], size[2])
            schemaOverlay:setUVs(uvs)
            self.vehicleSchemaOverlays[prefix .. baseOverlayName] = schemaOverlay
        end
        i = i + 1
    end
end
function InputHelpDisplay:getHelpAnchorPosition(_)
    local posX, posY = self:getPosition()
    return posX + self.helpAnchorOffsetX, posY + self.helpAnchorOffsetY
end
if data ~= nil then
    local inputHelp = InputHelpDisplay.new()
    inputHelp:loadVehicleSchemaOverlays()
    inputHelp:setScale(data.uiScale)
    inputHelp:setVisible(data.isVisible)
    inputHelp:setVehicle(data.vehicle)
    g_currentMission.hud.inputHelp = inputHelp
    g_currentMission.hud.displayComponents.inputHelp = inputHelp
    Logging.info("Reloaded InputHelpDisplay")
end