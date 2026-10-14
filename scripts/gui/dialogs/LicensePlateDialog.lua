LicensePlateDialog = {}
local LicensePlateDialog_mt = Class(LicensePlateDialog, InfoDialog)
function LicensePlateDialog.register()
    local licensePlateDialog = LicensePlateDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/LicensePlateDialog.xml", "LicensePlateDialog", licensePlateDialog)
    LicensePlateDialog.INSTANCE = licensePlateDialog
end
function LicensePlateDialog.show(licensePlateData, callback, target)
    if LicensePlateDialog.INSTANCE ~= nil then
        local dialog = LicensePlateDialog.INSTANCE
        dialog:setLicensePlateData(licensePlateData)
        dialog:setCallback(callback, target)
        g_gui:showDialog("LicensePlateDialog")
    end
end
function LicensePlateDialog.new(target, custom_mt)
    -- upvalues: (copy) LicensePlateDialog_mt
    local self = InfoDialog.new(target, custom_mt or LicensePlateDialog_mt)
    self.currentVariation = 1
    self.currentColorIndex = 1
    return self
end
function LicensePlateDialog.createFromExistingGui(gui, _)
    LicensePlateDialog.register()
    LicensePlateDialog.show(gui.licensePlateData, gui.callbackFunc, gui.target)
end
function LicensePlateDialog:delete()
    if self.keyboardButtonTemplate ~= nil then
        self.keyboardButtonTemplate:delete()
    end
    if self.licensePlate ~= nil then
        delete(self.licensePlate.node)
        self.self.licensePlate = nil
    end
    LicensePlateDialog:superClass().delete(self)
end
function LicensePlateDialog:onCreate()
    LicensePlateDialog:superClass().onCreate(self)
    self.keyboardButtonTemplate:unlinkElement()
    FocusManager:removeElement(self.keyboardButtonTemplate)
end
function LicensePlateDialog:onGuiSetupFinished()
    LicensePlateDialog:superClass().onGuiSetupFinished(self)
    local lineSize = (self.contentContainer.absSize[1] - self.headerText:getTextWidth()) / 2 - 20 * g_pixelSizeScaledX
    self.topLineLeft:setSize(lineSize, nil)
    self.topLineRight:setSize(lineSize, nil)
end
function LicensePlateDialog:loadMapData(_, _, _)
    self.sceneRender:createScene()
end
function LicensePlateDialog:unloadMapData()
    self.sceneRender:destroyScene()
end
function LicensePlateDialog:onOpen()
    LicensePlateDialog:superClass().onOpen(self)
    self.needsFirstFocusUpdate = true
    local colors, _ = g_licensePlateManager:getAvailableColors()
    self.changeColorButton.parent:setVisible(#colors > 1)
    self.currentCursorPosition = 1
    self.cursorPositions = {}
    self.sceneRender:setVisible(true)
    self:createKeyboards()
    self:updateLicensePlate()
end
function LicensePlateDialog:onClose()
    LicensePlateDialog:superClass().onClose(self)
    self.sceneRender:setVisible(false)
    if self.licensePlate ~= nil then
        self.licensePlate:delete()
        self.licensePlate = nil
    end
end
function LicensePlateDialog:setLicensePlateData(licensePlateData)
    self.currentVariation = licensePlateData.variation or self.currentVariation
    self.currentCharacters = table.clone(licensePlateData.characters, 5)
    local _, defaultColorIndex = g_licensePlateManager:getAvailableColors()
    self.currentColorIndex = licensePlateData.colorIndex or (defaultColorIndex or self.currentColorIndex)
    self:updateColorButton()
    self.currentPlacementIndex = licensePlateData.placementIndex or (licensePlateData.defaultPlacementIndex or g_licensePlateManager:getDefaultPlacementIndex())
    if licensePlateData.hasFrontPlate == false then
        self:updatePlacementOptions(LicensePlateManager.PLACEMENT_OPTION.BOTH)
        if self.currentPlacementIndex == LicensePlateManager.PLACEMENT_OPTION.BOTH then
            self.currentPlacementIndex = LicensePlateManager.PLACEMENT_OPTION.BACK_ONLY
        end
    else
        self:updatePlacementOptions()
    end
    local i = 1
    for i = i, #self.textToPlacementIndex do
        if self.textToPlacementIndex[i] == self.currentPlacementIndex then
            self.placementOption:setState(i)
        end
    end
    self.licensePlateData = licensePlateData
end
function LicensePlateDialog:setCallback(callbackFunction, target, args)
    self.callbackFunction = callbackFunction
    self.target = target
    self.args = args
end
function LicensePlateDialog:sendCallback(variation, characters, colorIndex, placementIndex)
    if self.callbackFunction ~= nil then
        if self.target ~= nil then
            self.callbackFunction(self.target, variation ~= nil and (characters ~= nil and (colorIndex ~= nil and placementIndex ~= nil)) and {
                ["variation"] = variation,
                ["characters"] = characters,
                ["colorIndex"] = colorIndex,
                ["placementIndex"] = placementIndex
            } or nil, self.args)
            return
        end
        self.callbackFunction(licensePlateData, self.args)
    end
end
function LicensePlateDialog:createKeyboards()
    local font = g_licensePlateManager:getFont()
    local function updateButtons(characterType, list)
        -- upvalues: (copy) font, (copy) self
        local i = #list.elements
        local characters = 1
        for i = i, characters, -1 do
            list.elements[i]:delete()
        end
        local characters = font.charactersByType[characterType]
        local i = 1
        local i = 1
        for i = i, #characters, i do
            local button = self.keyboardButtonTemplate:clone(list)
            local character = characters[i]
            button.keyboardValue = character.value
            button:setText(character.value)
        end
        list:invalidateLayout()
    end
    updateButtons(MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL, self.keyboardAlpha)
    updateButtons(MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL, self.keyboardNumeric)
    updateButtons(MaterialManager.FONT_CHARACTER_TYPE.SPECIAL, self.keyboardSpecial)
    self:updateFocusLinking(false, false, false)
end
function LicensePlateDialog:updateFocusLinking(alphabetical, numerical, special)
    local firstAvailableButton = nil
    local lastAvailableButton = nil
    FocusManager:linkElements(self.buttonCursorLeft, FocusManager.RIGHT, self.buttonCursorRight)
    FocusManager:linkElements(self.buttonCursorLeft, FocusManager.LEFT, self.buttonCursorLeft)
    FocusManager:linkElements(self.buttonCursorRight, FocusManager.RIGHT, self.buttonCursorRight)
    FocusManager:linkElements(self.buttonCursorRight, FocusManager.LEFT, self.buttonCursorLeft)
    if alphabetical then
        local button = (#self.keyboardAlpha.elements - 1) / 10
        lastAvailableButton = self.keyboardAlpha.elements[math.floor(button) * 10 + 1]
        local i = 1
        local i = 1
        for i = i, #self.keyboardAlpha.elements, i do
            local button = self.keyboardAlpha.elements[i]
            local topButton = self.keyboardAlpha.elements[i - 10]
            local bottomButton = self.keyboardAlpha.elements[i + 10]
            FocusManager:linkElements(button, FocusManager.LEFT, self.keyboardAlpha.elements[i - 1] or button)
            FocusManager:linkElements(button, FocusManager.RIGHT, self.keyboardAlpha.elements[i + 1] or button)
            if topButton == nil then
                if i <= 5 then
                    FocusManager:linkElements(button, FocusManager.TOP, self.buttonCursorLeft)
                else
                    FocusManager:linkElements(button, FocusManager.TOP, self.buttonCursorRight)
                end
            else
                FocusManager:linkElements(button, FocusManager.TOP, topButton)
            end
            if bottomButton == nil then
                local below = self.typeOption
                if numerical then
                    below = self.keyboardNumeric.elements[(i - 1) % 10 + 1]
                elseif special then
                    below = self.keyboardSpecial.elements[(i - 1) % 10 + 1]
                end
                FocusManager:linkElements(button, FocusManager.BOTTOM, below)
            else
                FocusManager:linkElements(button, FocusManager.BOTTOM, bottomButton)
            end
        end
    end
    if numerical then
        lastAvailableButton = self.keyboardNumeric.elements[1]
        local i = 1
        for i = i, #self.keyboardNumeric.elements do
            local i = self.keyboardNumeric.elements[i]
            local rightButton = nil
            if alphabetical then
                local topButton = math.floor((#self.keyboardAlpha.elements - 1) / 10) * 10 + i
                local bottomButton = math.min(topButton, #self.keyboardAlpha.elements)
                rightButton = self.keyboardAlpha.elements[bottomButton]
            end
            local topButton = self.typeOption
            if special then
                topButton = self.keyboardSpecial.elements[i]
            end
            FocusManager:linkElements(i, FocusManager.LEFT, self.keyboardNumeric.elements[i - 1] or i)
            FocusManager:linkElements(i, FocusManager.RIGHT, self.keyboardNumeric.elements[i + 1] or i)
            if rightButton == nil then
                if i <= 5 then
                    FocusManager:linkElements(i, FocusManager.TOP, self.buttonCursorLeft)
                else
                    FocusManager:linkElements(i, FocusManager.TOP, self.buttonCursorRight)
                end
            else
                FocusManager:linkElements(i, FocusManager.TOP, rightButton)
            end
            if topButton ~= nil then
                FocusManager:linkElements(i, FocusManager.BOTTOM, topButton)
            end
        end
    end
    if special then
        lastAvailableButton = self.keyboardSpecial.elements[1]
        local i = 1
        for i = i, #self.keyboardSpecial.elements do
            local i = self.keyboardSpecial.elements[i]
            local rightButton = nil
            if numerical then
                rightButton = self.keyboardNumeric.elements[i]
            elseif alphabetical then
                local topButton = math.floor((#self.keyboardAlpha.elements - 1) / 10) * 10 + i
                local bottomButton = math.min(topButton, #self.keyboardAlpha.elements)
                rightButton = self.keyboardAlpha.elements[bottomButton]
            end
            FocusManager:linkElements(i, FocusManager.LEFT, self.keyboardSpecial.elements[i - 1] or i)
            FocusManager:linkElements(i, FocusManager.RIGHT, self.keyboardSpecial.elements[i + 1] or i)
            if rightButton == nil then
                if i <= 5 then
                    FocusManager:linkElements(i, FocusManager.TOP, self.buttonCursorLeft)
                else
                    FocusManager:linkElements(i, FocusManager.TOP, self.buttonCursorRight)
                end
            else
                FocusManager:linkElements(i, FocusManager.TOP, rightButton)
            end
            FocusManager:linkElements(i, FocusManager.BOTTOM, self.typeOption)
        end
    end
    if firstAvailableButton ~= nil then
        FocusManager:linkElements(self.typeOption, FocusManager.TOP, lastAvailableButton)
        FocusManager:linkElements(self.buttonCursorLeft, FocusManager.BOTTOM, firstAvailableButton)
        FocusManager:linkElements(self.buttonCursorRight, FocusManager.BOTTOM, firstAvailableButton)
        if self.needsFirstFocusUpdate or FocusManager:getFocusedElement() ~= nil and FocusManager:getFocusedElement():getIsDisabled() then
            FocusManager:setFocus(firstAvailableButton)
            self.needsFirstFocusUpdate = false
        end
    end
end
function LicensePlateDialog:updateCursor()
    local positionInfo = self.cursorPositions[self.currentCursorPosition]
    self.cursorElement:setSize(positionInfo.width, positionInfo.height)
    self.cursorElement:setAbsolutePosition(positionInfo.x, positionInfo.y)
    local values = self.licensePlate.variations[self.currentVariation].values
    local value = values[1]
    local realIndex = 1
    local i = 1
    for i = i, #values do
        if not (values[i].isStatic or values[i].locked) then
            if realIndex == self.currentCursorPosition then
                value = values[i]
                break
            end
            realIndex = realIndex + 1
        end
    end
    for _, element in ipairs(self.keyboardAlpha.elements) do
        local shouldBeDisabled = not value.alphabetical
        if element:getIsDisabled() ~= shouldBeDisabled then
            element:setDisabled(shouldBeDisabled)
        end
    end
    for _, element in ipairs(self.keyboardNumeric.elements) do
        local shouldBeDisabled = not value.numerical
        if element:getIsDisabled() ~= shouldBeDisabled then
            element:setDisabled(shouldBeDisabled)
        end
    end
    for _, element in ipairs(self.keyboardSpecial.elements) do
        local shouldBeDisabled = not value.special
        if element:getIsDisabled() ~= shouldBeDisabled then
            element:setDisabled(shouldBeDisabled)
        end
    end
    self:updateFocusLinking(value.alphabetical, value.numerical, value.special)
end
function LicensePlateDialog:updateVariations()
    local texts = {}
    local typeText = g_i18n:getText("ui_licensePlateTypeItem")
    local i = 1
    for i = i, #self.licensePlate.variations do
        table.insert(texts, string.format(typeText, i))
    end
    self.typeOption:setTexts(texts)
    self.typeOption:setState(self.currentVariation)
end
function LicensePlateDialog:updateColorButton()
    if self.licensePlate ~= nil then
        local r, g, b = unpack(self.licensePlate:getColor(self.currentColorIndex))
        self.changeColorButtonImage:setImageColor(nil, math.clamp(r, 0, 1), math.clamp(g, 0, 1), math.clamp(b, 0, 1), 1)
    end
end
function LicensePlateDialog:updateLicensePlateGraphics()
    self.licensePlate:updateData(self.currentVariation, LicensePlateManager.PLATE_POSITION.BACK, table.concat(self.currentCharacters, ""))
    self.licensePlate:setColorIndex(self.currentColorIndex)
    self:updateColorButton()
    self.sceneRender:setRenderDirty()
    self.sceneRender:setVisible(true)
    local values = g_licensePlateManager:getLicensePlateValues(self.licensePlate, self.currentVariation)
    self.cursorPositions = {}
    local camera = I3DUtil.indexToObject(self.sceneRender.scene, self.sceneRender.cameraPath)
    local lx, ly, lz = localToWorld(self.licensePlate.node, self.licensePlate.width * 0.5, self.licensePlate.height * 0.5, 0)
    local plateEdgeX, plateEdgeY, _ = projectToCamera(camera, 3, lx, ly, lz)
    local _, fontHeight = self.licensePlate:getFontSize()
    if values ~= nil then
        for _, value in ipairs(values) do
            if not (value.isStatic or value.locked) then
                local valueWidth = (plateEdgeX - 0.5) * 2 * (value.maxWidthRatio * fontHeight / self.licensePlate.width) * self.sceneRender.size[1] + 2 * g_pixelSizeX
                local node, _ = I3DUtil.indexToObject(self.licensePlate.node, value.nodePath)
                local x, y, z = getWorldTranslation(node)
                local cursorX, cursorY, _ = projectToCamera(camera, 3, x, y, z)
                table.insert(self.cursorPositions, {
                    ["x"] = cursorX * self.sceneRender.size[1] + self.sceneRender.absPosition[1] - valueWidth * 0.5,
                    ["y"] = cursorY * self.sceneRender.size[2] + self.sceneRender.absPosition[2] - ((plateEdgeY - 0.5) * 2 * (fontHeight / self.licensePlate.height) * self.sceneRender.size[2] + 8 * g_pixelSizeY) * 0.5,
                    ["width"] = valueWidth,
                    ["height"] = fontHeightScreen,
                    ["valueIndex"] = value.index
                })
            end
        end
    end
    self.currentCursorPosition = math.min(self.currentCursorPosition, #self.cursorPositions)
    self:updateCursor()
end
function LicensePlateDialog:onCreatePlacementOption(element)
    self.placementOption = element
    self:updatePlacementOptions()
end
function LicensePlateDialog:updatePlacementOptions(excluded)
    self.textToPlacementIndex = {}
    local texts = {}
    for index, text in pairs(LicensePlateManager.PLACEMENT_OPTION_TEXT) do
        if index ~= excluded then
            table.insert(texts, g_i18n:getText(text))
            self.textToPlacementIndex[#texts] = index
        end
    end
    self.placementOption:setTexts(texts)
    self.placementOption:setState(1)
end
function LicensePlateDialog:onClickBack()
    self:sendCallback(nil)
    LicensePlateDialog:superClass().onClickBack(self)
end
function LicensePlateDialog:onClickChangeColor()
    local colors, defaultColorIndex = g_licensePlateManager:getAvailableColors()
    local colors = table.clone(colors, math.huge)
    if #colors > 1 then
        ColorPickerDialog.show(self.onPickedColor, self, nil, colors, defaultColorIndex, nil, nil, nil, true)
    end
    return true
end
function LicensePlateDialog:onPickedColor(colorIndex, _, _)
    if colorIndex ~= nil then
        self.currentColorIndex = colorIndex
        self:updateLicensePlateGraphics()
    end
end
function LicensePlateDialog:onClickOk()
    self.currentCharacters = self.licensePlate:validateLicensePlateCharacters(self.currentCharacters)
    self:sendCallback(self.currentVariation, self.currentCharacters, self.currentColorIndex, self.currentPlacementIndex)
    LicensePlateDialog:superClass().onClickOk(self)
end
function LicensePlateDialog:onRenderLoad(scene, _)
    setTranslation(scene, 0, -1, 0)
    setName(scene, "LicensePlateDialog_" .. getName(scene))
    self.licensePlaceLinkNode = I3DUtil.indexToObject(scene, "0|0")
end
function LicensePlateDialog:updateLicensePlate()
    if self.licensePlaceLinkNode ~= nil then
        local licensePlate = g_licensePlateManager:getLicensePlate(LicensePlateManager.PLATE_TYPE.ELONGATED)
        if licensePlate ~= nil then
            link(self.licensePlaceLinkNode, licensePlate.node)
            setTranslation(licensePlate.node, 0, 0, 0)
            setRotation(licensePlate.node, 0, 0, 0)
            self.licensePlate = licensePlate
            if self.currentCharacters == nil then
                self.currentCharacters = self.licensePlate:getRandomCharacters(self.currentVariation)
            end
            local cameraNode = I3DUtil.indexToObject(self.sceneRender.scene, self.sceneRender.cameraPath)
            if cameraNode ~= nil then
                local fovY = getFovY(cameraNode)
                local distanceWidth = (self.licensePlate.width / 2 + 0.005) / math.tan(fovY / 2) / (self.sceneRender.size[1] / self.sceneRender.size[2] * g_screenAspectRatio)
                local distanceHeight = (self.licensePlate.height / 2 + 0.005) / math.tan(fovY / 2)
                setTranslation(cameraNode, 0, 0, (math.max(distanceWidth, distanceHeight)))
            end
            self:updateLicensePlateGraphics()
            self:updateVariations()
        end
    end
end
function LicensePlateDialog:onClickKeyboardButton(element)
    self.currentCharacters[self.cursorPositions[self.currentCursorPosition].valueIndex] = element.keyboardValue
    self:updateLicensePlateGraphics()
    self:onClickCursorRight()
end
function LicensePlateDialog:onClickCursorLeft()
    self.currentCursorPosition = self.currentCursorPosition - 1
    if self.currentCursorPosition < 1 then
        self.currentCursorPosition = #self.cursorPositions
    end
    self:updateCursor()
end
function LicensePlateDialog:onClickCursorRight()
    self.currentCursorPosition = self.currentCursorPosition + 1
    if self.currentCursorPosition > #self.cursorPositions then
        self.currentCursorPosition = 1
    end
    self:updateCursor()
end
function LicensePlateDialog:onClickPlacementOptionChanged(selection)
    self.currentPlacementIndex = self.textToPlacementIndex[selection]
end
function LicensePlateDialog:onClickTypeOptionChanged(selection)
    self.currentVariation = selection
    self.currentCharacters = self.licensePlate:getRandomCharacters(self.currentVariation)
    self:updateLicensePlateGraphics()
end
function LicensePlateDialog:setButtonTexts(okText) end
function LicensePlateDialog:setButtonAction(buttonAction) end
function LicensePlateDialog:keyEvent(unicode, sym, modifier, isDown, eventUsed)
    if LicensePlateDialog:superClass().keyEvent(self, unicode, sym, modifier, isDown, eventUsed) then
        return true
    end
    if isDown then
        if sym ~= Input.KEY_backspace then
            local charValue = self:getUnicodeToKeyboardValue(unicode, self.licensePlate.variations[self.currentVariation].values[self.cursorPositions[self.currentCursorPosition].valueIndex])
            if charValue ~= nil then
                self.currentCharacters[self.cursorPositions[self.currentCursorPosition].valueIndex] = charValue
                self:updateLicensePlateGraphics()
                self:onClickCursorRight()
            end
            return true
        end
        if self.currentCursorPosition > 1 then
            self:onClickCursorLeft()
            return true
        end
    end
    return false
end
function LicensePlateDialog.getUnicodeToKeyboardValue(_, unicode, value)
    local text = utf8ToUpper(unicodeToUtf8(unicode))
    local font = g_licensePlateManager:getFont()
    if value.alphabetical then
        local result = (function(characterType)
            -- upvalues: (copy) font, (copy) text
            local characters = font.charactersByType[characterType]
            local i = 1
            for i = i, #characters do
                if text == utf8ToUpper(characters[i].value) then
                    return characters[i].value
                end
            end
            return nil
        end)(MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL)
        if result ~= nil then
            return result
        end
    end
    if value.numerical then
        local result = check(MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL)
        if result ~= nil then
            return result
        end
    end
    if value.special then
        local result = check(MaterialManager.FONT_CHARACTER_TYPE.SPECIAL)
        if result ~= nil then
            return result
        end
    end
    return nil
end