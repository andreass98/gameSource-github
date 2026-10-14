CharacterLine = {}
local CharacterLine_mt = Class(CharacterLine)
function CharacterLine.new(linkNode, fontMaterial, numCharacters, customMt)
    -- upvalues: (copy) CharacterLine_mt
    local self = setmetatable({}, customMt or CharacterLine_mt)
    self.fontMaterial = fontMaterial
    self.rootNode = createTransformGroup("characterLine")
    link(linkNode, self.rootNode)
    self.characters = {}
    for i = 1, numCharacters do
        local shape = fontMaterial:getClonedShape(self.rootNode)
        setShapeCastShadowmap(shape, false)
        table.insert(self.characters, shape)
    end
    self.textSize = 1
    self.scaleX = 1
    self.scaleY = 1
    self.textAlignment = RenderText.ALIGN_RIGHT
    self.textVerticalAlignment = RenderText.VERTICAL_ALIGN_BOTTOM
    self.fontThickness = 1
    self.fontThicknessShader = (self.fontThickness - 1) / 8 + 1
    self.useNormalMap = true
    self.textColor = nil
    self.hiddenColor = nil
    self.textEmissiveScale = 0
    self.hiddenAlpha = 0
    self:setText("")
    return self
end
function CharacterLine:setSizeAndScale(textSize, scaleX, scaleY)
    self.textSize = textSize or self.textSize
    self.scaleX = scaleX or self.scaleX
    self.scaleY = scaleY or self.scaleY
end
function CharacterLine:setTextAlignment(textAlignment)
    self.textAlignment = textAlignment or self.textAlignment
end
function CharacterLine:setTextVerticalAlignment(textVerticalAlignment)
    self.textVerticalAlignment = textVerticalAlignment or self.textVerticalAlignment
end
function CharacterLine:setFontThickness(fontThickness)
    self.fontThickness = fontThickness or self.fontThickness
    self.fontThicknessShader = (self.fontThickness - 1) / 8 + 1
    for _, shape in ipairs(self.characters) do
        setShaderParameter(shape, "alphaErosion", 1 - self.fontThicknessShader, 0, 0, 0, false)
    end
end
function CharacterLine:setColor(textColor, hiddenColor, textEmissiveScale, hiddenAlpha)
    self.textColor = textColor or self.textColor
    self.hiddenColor = hiddenColor or self.hiddenColor
    self.textEmissiveScale = textEmissiveScale or self.textEmissiveScale
    self.hiddenAlpha = hiddenAlpha or self.hiddenAlpha
    local r = nil
    local g = nil
    local b = nil
    if self.textColor ~= nil then
        r = self.textColor[1]
        g = self.textColor[2]
        b = self.textColor[3]
    end
    for _, shape in ipairs(self.characters) do
        self.fontMaterial:setFontCharacterColor(shape, r, g, b, 1, self.textEmissiveScale)
    end
end
function CharacterLine:setDecalLayer(decalLayer)
    for _, shape in ipairs(self.characters) do
        setShapeDecalLayer(shape, decalLayer or 0)
    end
end
function CharacterLine:setCastShadowmap(castShadowmap)
    for _, shape in ipairs(self.characters) do
        setShapeCastShadowmap(shape, castShadowmap)
    end
end
function CharacterLine:setUseNormalMap(useNormalMap)
    self.useNormalMap = Utils.getNoNil(useNormalMap, self.useNormalMap)
    for _, shape in ipairs(self.characters) do
        self.fontMaterial:assignFontMaterialToNode(shape, self.useNormalMap)
    end
end
function CharacterLine:setCharacterSpacing(characterSpacing)
    self.characterSpacing = characterSpacing
end
function CharacterLine:setText(text, updateAlignment)
    local realWidth = 0
    local xPos = 0
    local height = 0
    local textLength = utf8Strlen(text)
    for i, shape in ipairs(self.characters) do
        local characterData
        if i <= textLength then
            characterData = utf8Substr(text, textLength - i, 1)
        else
            characterData = " "
        end
        local characterData = self.fontMaterial:setFontCharacter(shape, characterData, self.textColor, self.hiddenColor)
        if updateAlignment == nil or updateAlignment then
            local offsetX = 0
            local offsetY = 0
            local spacingX = self.fontMaterial.spacingX
            local spacingY = self.fontMaterial.spacingY
            local realSpacingX = self.fontMaterial.spacingX
            if characterData ~= nil then
                spacingY = characterData.spacingY or spacingY
                realSpacingX = characterData.realSpacingX or spacingY
                offsetX = characterData.offsetX
                offsetY = characterData.offsetY
            end
            local scaleX = self.textSize * ((1 - spacingX * 2) / (1 - spacingY * 2)) * self.scaleX
            local scaleY = self.textSize * self.scaleY
            setScale(shape, scaleX, scaleY, 1)
            local charWidth = scaleX + self.textSize * self.fontMaterial.charToCharSpace * (self.characterSpacing or 1) * (spacingX / realSpacingX)
            setTranslation(shape, xPos - charWidth * 0.5 + charWidth * offsetX, scaleY * 0.5 + scaleY * offsetY, 0)
            xPos = xPos - charWidth
            height = math.max(height, scaleY)
            if characterData ~= " " and characterData ~= "" then
                realWidth = xPos
            end
        end
    end
    if updateAlignment == nil or updateAlignment then
        local x = 0
        local y = 0
        if self.textAlignment == RenderText.ALIGN_LEFT then
            x = -realWidth
        elseif self.textAlignment == RenderText.ALIGN_CENTER then
            x = -realWidth * 0.5
        end
        if self.textVerticalAlignment == RenderText.VERTICAL_ALIGN_MIDDLE then
            y = -height * 0.5
        elseif self.textVerticalAlignment == RenderText.VERTICAL_ALIGN_TOP then
            y = -height
        end
        setTranslation(self.rootNode, x, y, 0)
    end
end