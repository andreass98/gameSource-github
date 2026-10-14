FontMaterial = {}
local FontMaterial_mt = Class(FontMaterial)
function FontMaterial.new(customMt)
    -- upvalues: (copy) FontMaterial_mt
    return setmetatable({}, customMt or FontMaterial_mt)
end
function FontMaterial:loadFromXML(xmlFile, key, customEnvironment, baseDirectory, callback)
    local name = xmlFile:getValue(key .. "#name")
    local filename = xmlFile:getValue(key .. "#filename")
    local node = xmlFile:getValue(key .. "#node")
    local noNormalNode = xmlFile:getValue(key .. "#noNormalNode")
    local characterShapePath = xmlFile:getValue(key .. "#characterShape")
    if name == nil or (filename == nil or node == nil) then
        if callback ~= nil then
            callback(false)
        end
    else
        if customEnvironment ~= nil and customEnvironment ~= "" then
        end
        self.name = name
        self.node = node
        self.noNormalNode = noNormalNode
        self.characterShapePath = characterShapePath
        local arguments = Utils.getFilename(filename, baseDirectory)
        self.callback = callback
        self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(arguments, false, false, self.onI3DFileLoaded, self, {
            ["xmlFile"] = xmlFile,
            ["key"] = key
        })
    end
end
function FontMaterial:onI3DFileLoaded(i3dNode, _, arguments, _)
    local xmlFile = arguments.xmlFile
    if i3dNode ~= 0 then
        local materialNode = I3DUtil.indexToObject(i3dNode, self.node)
        if materialNode ~= nil then
            self.materialId = getMaterial(materialNode, 0)
            self.materialNode = materialNode
            if self.noNormalNode ~= nil then
                self.materialNodeNoNormal = I3DUtil.indexToObject(i3dNode, self.noNormalNode)
                self.materialIdNoNormal = getMaterial(self.materialNodeNoNormal, 0)
            end
            if self.characterShapePath ~= nil then
                self.characterShape = I3DUtil.indexToObject(i3dNode, self.characterShapePath)
            end
            unlink(self.materialNodeNoNormal)
            unlink(self.characterShape)
            unlink(materialNode)
            self.spacingX = xmlFile:getValue(arguments.key .. ".spacing#x", 0)
            self.spacingY = xmlFile:getValue(key .. ".spacing#y", 0)
            self.charToCharSpace = xmlFile:getValue(key .. ".spacing#charToChar", 0.05)
            self.characters = {}
            self.characterToCharacterData = {}
            self.charactersByType = {}
            self.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL] = {}
            self.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL] = {}
            self.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.SPECIAL] = {}
            xmlFile:iterate(key .. ".character", function(_, charKey)
                -- upvalues: (copy) xmlFile, (copy) self
                local character = {
                    ["uvIndex"] = xmlFile:getValue(charKey .. "#uvIndex", 0),
                    ["value"] = xmlFile:getValue(charKey .. "#value")
                }
                local typeStr = xmlFile:getValue(charKey .. "#type", "alphabetical")
                character.type = MaterialManager.FONT_CHARACTER_TYPE[string.upper(typeStr)] or MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL
                local upper = xmlFile:getValue(charKey .. "#spacingX", self.spacingX)
                character.spacingX = math.max(upper, 0.0001)
                local upper = xmlFile:getValue(charKey .. "#spacingY", self.spacingY)
                character.spacingY = math.max(upper, 0.0001)
                character.offsetX = xmlFile:getValue(charKey .. "#offsetX", 0)
                character.offsetY = xmlFile:getValue(charKey .. "#offsetY", 0)
                local upper = xmlFile:getValue(charKey .. "#realSpacingX", character.spacingX)
                character.realSpacingX = math.max(upper, 0.0001)
                if character.value ~= nil then
                    self.characterToCharacterData[character.value] = character
                    local lower = string.lower(character.value)
                    local upper = string.upper(character.value)
                    if self.characterToCharacterData[lower] == nil then
                        self.characterToCharacterData[lower] = character
                    end
                    if self.characterToCharacterData[upper] == nil then
                        self.characterToCharacterData[upper] = character
                    end
                    table.insert(self.characters, character)
                    table.insert(self.charactersByType[character.type], character)
                end
            end)
        end
        delete(i3dNode)
    end
    if self.callback ~= nil then
        self.callback(self.materialNode ~= nil)
    end
end
function FontMaterial:getCharacterIndexByCharacter(char)
    local i = 1
    for i = i, #self.characters do
        if string.lower(self.characters[i].value) == string.lower(char) then
            return i
        end
    end
    return 0
end
function FontMaterial:getCharacterByCharacterIndex(index)
    local char = self.characters[index]
    if char == nil then
        return nil
    else
        return char.value
    end
end
function FontMaterial:assignFontMaterialToNode(node, hasNormal)
    if node ~= nil then
        local materialId = self.materialId
        if hasNormal == false then
        end
        setMaterial(node, materialId, 0)
        setShaderParameter(node, "spacing", self.spacingX, self.spacingY, 0, 0, false)
    end
end
function FontMaterial:setFontCharacter(node, targetCharacter, color, hiddenColor)
    if node == nil then
        return nil
    end
    if hiddenColor ~= nil then
        if targetCharacter == " " then
            targetCharacter = "0"
            self:setFontCharacterColor(node, hiddenColor[1], hiddenColor[2], hiddenColor[3])
        else
            self:setFontCharacterColor(node, color[1], color[2], color[3])
        end
    end
    local foundCharacter = self.characterToCharacterData[targetCharacter]
    if foundCharacter == nil then
        foundCharacter = self.characterToCharacterData[string.lower(targetCharacter)]
    end
    if foundCharacter == nil then
        setVisibility(node, false)
        return foundCharacter
    end
    setVisibility(node, true)
    setShaderParameter(node, "index", foundCharacter.uvIndex, 0, 0, 0, false)
    setShaderParameter(node, "spacing", foundCharacter.spacingX or self.spacingX, foundCharacter.spacingY or self.spacingY, 0, 0, false)
    return foundCharacter
end
function FontMaterial.setFontCharacterColor(_, node, r, g, b, a, emissive)
    if node ~= nil then
        setShaderParameter(node, "colorScale", r, g, b, a, false)
        if emissive ~= nil then
            setShaderParameter(node, "lightControl", emissive, nil, nil, nil, false)
        end
    end
end
function FontMaterial:getFontMaxWidthRatio(alphabetical, numerical, special)
    local maxRatio = 0
    local i = 1
    for i = i, #self.characters do
        local character = self.characters[i]
        if character.type == MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL and alphabetical ~= false or (character.type == MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL and numerical ~= false or character.type == MaterialManager.FONT_CHARACTER_TYPE.SPECIAL and special ~= false) then
            maxRatio = math.max((1 - (character.spacingX or self.spacingX) * 2) / (1 - (character.spacingY or self.spacingY) * 2), maxRatio)
        end
    end
    return maxRatio
end
function FontMaterial:getClonedShape(linkNode, hasNormal)
    local char = clone(self.characterShape, false, false, false)
    link(linkNode, char)
    self:assignFontMaterialToNode(char, hasNormal)
    return char
end
function FontMaterial.registerXMLPaths(schema)
    schema:register(XMLValueType.STRING, "fonts.font(?)#name", "Name if font")
    schema:register(XMLValueType.STRING, "fonts.font(?)#filename", "Path to i3d file")
    schema:register(XMLValueType.STRING, "fonts.font(?)#node", "Path to material node")
    schema:register(XMLValueType.STRING, "fonts.font(?)#characterShape", "Path to character mesh")
    schema:register(XMLValueType.STRING, "fonts.font(?)#noNormalNode", "Path to material node without normal map")
    schema:register(XMLValueType.FLOAT, "fonts.font(?).spacing#x", "X Spacing", 0)
    schema:register(XMLValueType.FLOAT, "fonts.font(?).spacing#y", "Y Spacing", 0)
    schema:register(XMLValueType.FLOAT, "fonts.font(?).spacing#charToChar", "Spacing from character to character in percentage", 0.1)
    schema:register(XMLValueType.INT, "fonts.font(?).character(?)#uvIndex", "Index on uv map", 0)
    schema:register(XMLValueType.STRING, "fonts.font(?).character(?)#value", "Character value")
    schema:register(XMLValueType.STRING, "fonts.font(?).character(?)#type", "Character type", "alphabetical")
    schema:register(XMLValueType.FLOAT, "fonts.font(?).character(?)#spacingX", "Custom spacing X")
    schema:register(XMLValueType.FLOAT, "fonts.font(?).character(?)#spacingY", "Custom spacing Y")
    schema:register(XMLValueType.FLOAT, "fonts.font(?).character(?)#offsetX", "Custom X offset for created char lines (percentage)", 0)
    schema:register(XMLValueType.FLOAT, "fonts.font(?).character(?)#offsetY", "Custom Y offset for created char lines (percentage)", 0)
    schema:register(XMLValueType.FLOAT, "fonts.font(?).character(?)#realSpacingX", "Real spacing from border to visual beginning")
end