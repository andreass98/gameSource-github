LicensePlate = {}
local LicensePlate_mt = Class(LicensePlate)
function LicensePlate.new(customMt)
    -- upvalues: (copy) LicensePlate_mt
    local self = setmetatable({}, customMt or LicensePlate_mt)
    self.variationIndex = 1
    self.position = LicensePlateManager.PLATE_POSITION.ANY
    self.characters = ""
    self.manager = g_licensePlateManager
    return self
end
function LicensePlate:loadFromXML(node, filename, customEnvironment, xmlFile, key)
    local typeStr = xmlFile:getValue(key .. "#type", "ELONGATED")
    if typeStr ~= nil then
        self.type = LicensePlateManager.PLATE_TYPE[typeStr]
        if self.type == nil then
            return false
        end
        self.node = node
        self.filename = filename
        self.width = xmlFile:getValue(key .. "#width", 1)
        self.height = xmlFile:getValue(key .. "#height", 0.3)
        self.fontSize = xmlFile:getValue(key .. ".font#size", 0.1)
        self.fontUseNormalMap = xmlFile:getValue(key .. ".font#useNormalMap", true)
        self.fontScaleX = xmlFile:getValue(key .. ".font#scaleX", 1)
        self.fontScaleY = xmlFile:getValue(key .. ".font#scaleY", 1)
        self.widthOffsetLeft = 0
        self.widthOffsetRight = 0
        self.heightOffsetTop = 0
        self.heightOffsetBot = 0
        self.font = g_licensePlateManager:getFont()
        if self.font == nil then
            Logging.error("LicensePlate: Unable to get font from LicensePlateManager, possibly not initialized/loaded yet")
            printCallstack()
            return false
        end
        self.fontMaxWidthRatio = self.font:getFontMaxWidthRatio()
        self.variations = {}
        xmlFile:iterate(key .. ".variations.variation", function(_, variationKey)
            -- upvalues: (copy) xmlFile, (copy) self, (copy) customEnvironment
            local variation = {
                ["values"] = {}
            }
            local realIndex = 0
            xmlFile:iterate(variationKey .. ".value", function(index, valueKey)
                -- upvalues: (ref) realIndex, (ref) xmlFile, (ref) self, (copy) variation
                local value = {
                    ["index"] = index,
                    ["realIndex"] = realIndex + 1,
                    ["nodePath"] = xmlFile:getValue(valueKey .. "#node")
                }
                value.node = I3DUtil.indexToObject(self.node, value.nodePath)
                value.nextSection = xmlFile:getValue(valueKey .. "#nextSection", false)
                if value.nodePath ~= nil and value.node ~= nil then
                    local x, y, z = getTranslation(value.node)
                    value.posX = xmlFile:getValue(valueKey .. "#posX", x)
                    value.posY = xmlFile:getValue(valueKey .. "#posY", y)
                    value.posZ = xmlFile:getValue(valueKey .. "#posZ", z)
                    value.character = xmlFile:getValue(valueKey .. "#character")
                    value.numerical = xmlFile:getValue(valueKey .. "#numerical", false)
                    value.alphabetical = xmlFile:getValue(valueKey .. "#alphabetical", false)
                    value.special = xmlFile:getValue(valueKey .. "#special", false)
                    local positionStr = xmlFile
                    value.isStatic = positionStr:getValue(valueKey .. "#isStatic", not (value.numerical or (value.alphabetical or value.special)) and value.character ~= nil)
                    local positionStr = xmlFile
                    value.locked = positionStr:getValue(valueKey .. "#locked", value.character ~= nil)
                    value.maxWidthRatio = self.font:getFontMaxWidthRatio(value.alphabetical, value.numerical, value.special)
                    local positionStr = xmlFile:getValue(valueKey .. "#position", "ANY")
                    local position = LicensePlateManager.PLATE_POSITION[string.upper(positionStr)]
                    if position == nil then
                        Logging.xmlError(xmlFile, "Unknown position \'%s\' in \'%s\'", positionStr, valueKey)
                    end
                    value.position = position or LicensePlateManager.PLATE_POSITION.ANY
                    if not value.isStatic then
                    end
                    I3DUtil.setShapeCastShadowmapRec(value.node, false)
                    table.insert(variation.values, value)
                end
            end)
            variation.materials = {}
            xmlFile:iterate(variationKey .. ".material", function(_, materialKey)
                -- upvalues: (ref) xmlFile, (ref) customEnvironment, (copy) variation
                local material = VehicleMaterial.new()
                if material:loadFromXML(xmlFile, materialKey, customEnvironment) then
                    local positionStr = xmlFile:getValue(materialKey .. "#position", "ANY")
                    local position = LicensePlateManager.PLATE_POSITION[string.upper(positionStr)]
                    if position == nil then
                        Logging.xmlError(xmlFile, "Unknown position \'%s\' in \'%s\'", positionStr, materialKey)
                    end
                    material.licensePlatePosition = position or LicensePlateManager.PLATE_POSITION.ANY
                    table.insert(variation.materials, material)
                end
            end)
            if #variation.values > 0 then
                table.insert(self.variations, variation)
            end
        end)
        self.frame = {}
        self.frame.node = xmlFile:getValue(key .. ".frame#node")
        self.frame.widthOffset = xmlFile:getValue(key .. ".frame#widthOffset", 0)
        self.frame.heightOffsetTop = xmlFile:getValue(key .. ".frame#heightOffsetTop", 0)
        self.frame.heightOffsetBot = xmlFile:getValue(key .. ".frame#heightOffsetBot", 0)
        if self.frame.node == nil or I3DUtil.indexToObject(self.node, self.frame.node) == nil then
            self.frame = nil
        end
    end
    return true
end
function LicensePlate:delete()
    delete(self.node)
end
function LicensePlate:clone(includeFrame)
    local licensePlateClone = LicensePlate.new()
    licensePlateClone.node = clone(self.node, false, false, false)
    licensePlateClone.type = self.type
    licensePlateClone.filename = self.filename
    licensePlateClone.width = self.width
    licensePlateClone.height = self.height
    licensePlateClone.fontSize = self.fontSize
    licensePlateClone.fontUseNormalMap = self.fontUseNormalMap
    licensePlateClone.fontScaleX = self.fontScaleX
    licensePlateClone.fontScaleY = self.fontScaleY
    licensePlateClone.rawWidth = self.width
    licensePlateClone.rawHeight = self.height
    licensePlateClone.widthOffsetLeft = 0
    licensePlateClone.widthOffsetRight = 0
    licensePlateClone.heightOffsetTop = 0
    licensePlateClone.heightOffsetBot = 0
    licensePlateClone.font = self.font
    licensePlateClone.fontMaxWidthRatio = self.fontMaxWidthRatio
    licensePlateClone.variations = table.clone(self.variations, 10)
    local i = 1
    local frameNode = #licensePlateClone.variations
    for i = i, frameNode do
        local variation = licensePlateClone.variations[i]
        local j = 1
        for j = j, #variation.values do
            local value = variation.values[j]
            value.node = I3DUtil.indexToObject(licensePlateClone.node, value.nodePath)
        end
    end
    licensePlateClone.frame = table.clone(self.frame, 10)
    if licensePlateClone.frame ~= nil then
        includeFrame = includeFrame == true
        local frameNode = I3DUtil.indexToObject(licensePlateClone.node, licensePlateClone.frame.node)
        if frameNode ~= nil then
            setVisibility(frameNode, includeFrame)
            if includeFrame then
                licensePlateClone.width = licensePlateClone.width + 2 * licensePlateClone.frame.widthOffset
                licensePlateClone.height = licensePlateClone.height + licensePlateClone.frame.heightOffsetTop + licensePlateClone.frame.heightOffsetBot
                licensePlateClone.widthOffsetLeft = licensePlateClone.frame.widthOffset
                licensePlateClone.widthOffsetRight = licensePlateClone.frame.widthOffset
                licensePlateClone.heightOffsetTop = licensePlateClone.frame.heightOffsetTop
                licensePlateClone.heightOffsetBot = licensePlateClone.frame.heightOffsetBot
            end
        end
    end
    licensePlateClone:setVariation(self.variationIndex, self.position)
    return licensePlateClone
end
function LicensePlate:updateData(variationIndex, position, characters, validate)
    if variationIndex ~= self.variationIndex or position ~= self.position then
        self:setVariation(variationIndex, position)
    end
    self.position = position or self.position
    if validate == true then
        characters = self:validateLicensePlateCharacters(characters)
    end
    self.characters = characters
    local variation = self.variations[self.variationIndex]
    if variation == nil then
        ::l9::
        return
    end
    local stringPos = 1
    local i = 1
    for i = i, #variation.values do
        local value = variation.values[i]
        if value.node ~= nil then
            setTranslation(value.node, value.posX, value.posY, value.posZ)
            if value.position == LicensePlateManager.PLATE_POSITION.ANY then
                ::l14::
                samePosition = value.position ~= LicensePlateManager.PLATE_POSITION.NONE
                goto l15
            end
            local samePosition = false
            if value.position == position then
                goto l14
            end
            ::l15::
            local targetChar = value.character
            if not value.locked then
                targetChar = characters:sub(stringPos, stringPos) or targetChar
            end
            if value.isStatic or (targetChar == "" or (targetChar == "_" or not samePosition)) then
                if value.isStatic and samePosition then
                    setVisibility(value.node, true)
                else
                    setVisibility(value.node, false)
                end
            else
                value.characterLine:setText(targetChar)
                setVisibility(value.node, true)
            end
            if not value.isStatic then
            end
        end
    end
    goto l9
end
function LicensePlate:setVariation(variationIndex, position)
    local variation = self.variations[variationIndex]
    if variation ~= nil then
        local oldVariation = self.variations[self.variationIndex]
        local i = 1
        for i = i, #oldVariation.values do
            local value = oldVariation.values[i]
            if not value.isStatic then
                local j = 1
                for j = j, getNumOfChildren(value.node) do
                    delete(getChildAt(value.node, j - 1))
                end
            end
        end
        self.variationIndex = variationIndex
        local i = 1
        for i = i, #variation.values do
            local value = variation.values[i]
            if not value.isStatic then
                value.characterLine = CharacterLine.new(value.node, self.font, 1)
                value.characterLine:setSizeAndScale(self.fontSize, self.fontScaleX, self.fontScaleY)
                value.characterLine:setTextAlignment(RenderText.ALIGN_CENTER)
                value.characterLine:setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
                value.characterLine:setUseNormalMap(self.fontUseNormalMap)
            end
        end
        local i = 1
        for i = i, #variation.materials do
            local value = variation.materials[i]
            if position == nil or (value.licensePlatePosition == LicensePlateManager.PLATE_POSITION.ANY or value.licensePlatePosition == position) then
                value:apply(self.node)
            end
        end
    end
end
function LicensePlate:getFontSize()
    return self.fontSize * self.fontMaxWidthRatio, self.fontSize
end
function LicensePlate:setColorIndex(colorIndex)
    local colors, _ = self.manager:getAvailableColors()
    local colorData = colors[colorIndex]
    if colorData ~= nil then
        self:setColor(colorData.color[1], colorData.color[2], colorData.color[3])
    end
end
function LicensePlate:getColor(colorIndex)
    local colors, _ = self.manager:getAvailableColors()
    local colorData = colors[colorIndex]
    if colorData == nil then
        return nil
    else
        return colorData.color
    end
end
function LicensePlate:setColor(r, g, b)
    local material = VehicleMaterial.new()
    material:setColor(r, g, b)
    material:apply(self.node, g_licensePlateManager.materialNamePlate)
    local j = 1
    for j = j, #self.variations do
        local i = 1
        for i = i, #self.variations[j].values do
            local value = self.variations[j].values[i]
            if not value.isStatic and value.node ~= nil then
                I3DUtil.setShaderParameterRec(value.node, g_licensePlateManager.shaderParameterCharacters, r, g, b)
            end
        end
    end
end
function LicensePlate:getRandomCharacters(variationIndex)
    local characters = {}
    local firstNumericCharacter = true
    local variation = self.variations[variationIndex]
    if variation ~= nil then
        local i = 1
        for i = i, #variation.values do
            local value = variation.values[i]
            if not value.isStatic then
                if value.character == nil then
                    local random = math.random()
                    local sourceCharacters = self.font.characters
                    if value.alphabetical then
                        sourceCharacters = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL]
                    elseif value.numerical then
                        sourceCharacters = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL]
                    elseif value.special then
                        sourceCharacters = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.SPECIAL]
                    end
                    if sourceCharacters == nil or #sourceCharacters <= 0 then
                        table.insert(characters, "0")
                    else
                        local index = math.max(math.floor(random * #sourceCharacters), 1)
                        if value.numerical and firstNumericCharacter then
                            index = index == 1 and #sourceCharacters > 1 and 2 or index
                            firstNumericCharacter = false
                        end
                        table.insert(characters, sourceCharacters[index].value)
                    end
                else
                    table.insert(characters, value.character)
                end
            end
        end
    end
    return characters
end
function LicensePlate:validateLicensePlateCharacters(characters)
    local isTbl = type(characters) == "table"
    local variation, length
    if isTbl then
        variation = table.concat(characters, "")
        length = #characters
    else
        length = characters:len()
        variation = characters
    end
    local variation = self.variations[self.variationIndex]
    local str = filterText(variation, false, false)
    local i = 1
    for i = i, length do
        local replacement = str:sub(i, i)
        local old
        if isTbl then
            old = characters[i]
        else
            old = characters:sub(i, i)
        end
        if replacement ~= old then
            local value = variation.values[i]
            if value ~= nil then
                local sourceCharacters = self.font.characters
                if value.alphabetical then
                    sourceCharacters = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL]
                elseif value.numerical then
                    sourceCharacters = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL]
                elseif value.special then
                    sourceCharacters = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.SPECIAL]
                end
                if isTbl then
                    characters[i] = sourceCharacters[1].value
                else
                    characters = str:sub(1, i - 1) .. sourceCharacters[1].value .. str:sub(i + 1)
                end
            end
        end
    end
    return characters
end
function LicensePlate:changeCharacter(variationIndex, currentCharacters, valueIndex, direction)
    local variation = self.variations[variationIndex]
    if variation ~= nil then
        local value = variation.values[valueIndex]
        local sourceCharactersSources = {}
        if value.alphabetical then
            table.insert(sourceCharactersSources, self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL])
        end
        if value.numerical then
            table.insert(sourceCharactersSources, self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL])
        end
        if value.special then
            table.insert(sourceCharactersSources, self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.SPECIAL])
        end
        local newSource = nil
        local newIndex = 1
        local j = 1
        for j = j, #sourceCharactersSources do
            local source = sourceCharactersSources[j]
            local i = 1
            for i = i, #source do
                if source[i].value == currentCharacters[value.realIndex] then
                    newIndex = i + direction
                    if #source < newIndex then
                        newSource = sourceCharactersSources[j + 1]
                        if newSource == nil then
                            newIndex = #source
                            newSource = source
                        else
                            newIndex = 1
                        end
                    elseif newIndex < 1 then
                        newSource = sourceCharactersSources[j - 1]
                        if newSource == nil then
                            newIndex = 1
                            newSource = source
                        else
                            newIndex = #newSource
                        end
                    else
                        newSource = source
                    end
                end
            end
        end
        if newSource ~= nil and newSource[newIndex] ~= nil then
            currentCharacters[value.realIndex] = newSource[newIndex].value
        end
    end
    return currentCharacters
end
function LicensePlate:getFormattedString()
    if self.characters == "" then
        return nil
    end
    local str = ""
    local variation = self.variations[self.variationIndex]
    if variation ~= nil then
        local i = 1
        for i = i, #variation.values do
            local value = variation.values[i]
            if not value.isStatic then
                local char = self.characters:sub(i, i) or ""
                if char ~= "_" then
                    if value.nextSection then
                    end
                end
            end
        end
    end
    return str
end
function LicensePlate.registerXMLPaths(schema, baseName)
    schema:register(XMLValueType.STRING, baseName .. "#filename", "License plate i3d filename")
    schema:register(XMLValueType.NODE_INDEX, baseName .. "#node", "License plate node")
    schema:register(XMLValueType.STRING, baseName .. "#type", "License plate type \'SQUARISH\' or \'ELONGATED\'", "ELONGATED")
    schema:register(XMLValueType.FLOAT, baseName .. "#width", "Width of license plate", 1)
    schema:register(XMLValueType.FLOAT, baseName .. "#height", "Height of license plate", 0.2)
    schema:register(XMLValueType.FLOAT, baseName .. ".font#size", "Size of font", 0.1)
    schema:register(XMLValueType.BOOL, baseName .. ".font#useNormalMap", "Use normal map for the characters", true)
    schema:register(XMLValueType.FLOAT, baseName .. ".font#scaleX", "Additional scaling of font X", 1)
    schema:register(XMLValueType.FLOAT, baseName .. ".font#scaleY", "Additional scaling of font Y", 1)
    schema:register(XMLValueType.STRING, baseName .. ".variations.variation(?).value(?)#node", "Value mesh index")
    schema:register(XMLValueType.FLOAT, baseName .. ".variations.variation(?).value(?)#posX", "X translation of value node")
    schema:register(XMLValueType.FLOAT, baseName .. ".variations.variation(?).value(?)#posY", "Y translation of value node")
    schema:register(XMLValueType.FLOAT, baseName .. ".variations.variation(?).value(?)#posZ", "Z translation of value node")
    schema:register(XMLValueType.BOOL, baseName .. ".variations.variation(?).value(?)#nextSection", "Is start character for next section", false)
    schema:register(XMLValueType.STRING, baseName .. ".variations.variation(?).value(?)#character", "Pre defined character of node")
    schema:register(XMLValueType.BOOL, baseName .. ".variations.variation(?).value(?)#numerical", "Node supports numeric characters", false)
    schema:register(XMLValueType.BOOL, baseName .. ".variations.variation(?).value(?)#alphabetical", "Node supports alphabetical characters", false)
    schema:register(XMLValueType.BOOL, baseName .. ".variations.variation(?).value(?)#special", "Node supports special characters", false)
    schema:register(XMLValueType.BOOL, baseName .. ".variations.variation(?).value(?)#isStatic", "Node is only static without applying of characters", "is static if \'numerical\' and \'alphabetical\' are both on false and no fixed character is given")
    schema:register(XMLValueType.BOOL, baseName .. ".variations.variation(?).value(?)#locked", "Character value can not be changed", "locked when character is defined")
    schema:register(XMLValueType.STRING, baseName .. ".variations.variation(?).value(?)#position", "Value will be hidden of position differs from placement position", "ANY")
    VehicleMaterial.registerXMLPaths(schema, baseName .. ".variations.variation(?).material(?)")
    schema:register(XMLValueType.STRING, baseName .. ".variations.variation(?).material(?)#position", "Value will be hidden of position differs from placement position", "ANY")
    schema:register(XMLValueType.STRING, baseName .. ".frame#node", "Frame node that can be toggled")
    schema:register(XMLValueType.FLOAT, baseName .. ".frame#widthOffset", "Width of frame on each side", 0)
    schema:register(XMLValueType.FLOAT, baseName .. ".frame#heightOffsetTop", "Height of frame on top", 0)
    schema:register(XMLValueType.FLOAT, baseName .. ".frame#heightOffsetBot", "Height of frame at bottom", 0)
end