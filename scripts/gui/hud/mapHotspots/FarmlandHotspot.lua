FarmlandHotspot = {}
local FarmlandHotspot_mt = Class(FarmlandHotspot, MapHotspot)
function FarmlandHotspot.new(customMt)
    -- upvalues: (copy) FarmlandHotspot_mt
    local self = MapHotspot.new(customMt or FarmlandHotspot_mt)
    self.width, self.height = getNormalizedScreenValues(60, 60)
    self.icon = g_overlayManager:createOverlay("mapHotspots.miniMapField", 0, 0, self.width, self.height)
    self.icon:setColor(unpack(HUD.COLOR.BACKGROUND_DARK))
    self.clickArea = MapHotspot.getClickCircle(0.667)
    local textSize
    if Platform.isMobile then
        _, textSize = getNormalizedScreenValues(0, 50)
    else
        _, textSize = getNormalizedScreenValues(0, 16)
    end
    self.textSize = textSize
    self.color = {
        1,
        1,
        1,
        1
    }
    self.colorDisabled = {
        0.20156,
        0.20156,
        0.20156,
        1
    }
    self.textColor = { 1, 1, 1 }
    self.textColorDisabled = {
        0.89627,
        0.92158,
        0.81485,
        0.5
    }
    _, self.textOffsetY = getNormalizedScreenValues(0, 2)
    self.disabled = false
    self.isFirstRendering = true
    self.name = ""
    return self
end
function FarmlandHotspot:getCategory()
    return MapHotspot.CATEGORY_FIELD
end
function FarmlandHotspot:setFarmland(farmland)
    self.farmland = farmland
    if farmland ~= nil then
        self.name = farmland:getName()
        local x, z = farmland:getIndicatorPosition()
        self:setWorldPosition(x, z)
    end
end
function FarmlandHotspot:getFarmland()
    return self.farmland
end
function FarmlandHotspot:getSortingValue()
    return math.huge
end
function FarmlandHotspot:setOwnerFarmId(farmId)
    FarmlandHotspot:superClass().setOwnerFarmId(self, farmId)
    self.farmId = farmId
    self:updateColors()
end
function FarmlandHotspot:setDisabled(disabled)
    self.disabled = disabled
    if disabled then
        self.icon:setColor(unpack(self.colorDisabled))
    else
        self:updateColors()
    end
end
function FarmlandHotspot:updateColors()
    if self.icon ~= nil then
        if self.farmId == FarmlandManager.NO_OWNER_FARM_ID then
            self.color[1] = 1
            self.color[2] = 1
            self.color[3] = 1
            self.color[4] = 1
            self.textColor[1] = 1
            self.textColor[2] = 1
            self.textColor[3] = 1
            self.icon:setColor(unpack(HUD.COLOR.BACKGROUND_DARK))
        else
            local farm = g_farmManager:getFarmById(self.farmId)
            if farm ~= nil then
                local color = farm:getColor()
                if color ~= nil then
                    self.icon:setColor(color[1], color[2], color[3], color[4])
                    self.color[1] = color[1]
                    self.color[2] = color[2]
                    self.color[3] = color[3]
                    self.color[4] = color[4]
                end
                self.textColor[1] = 0
                self.textColor[2] = 0
                self.textColor[3] = 0
                return
            end
        end
    end
end
function FarmlandHotspot:getIsVisible()
    if self.farmland == nil or self.farmland.showOnFarmlandsScreen then
        return FarmlandHotspot:superClass().getIsVisible(self)
    else
        return false
    end
end
function FarmlandHotspot:render(x, y, _, small)
    if self.isFirstRendering then
        self:setOwnerFarmId(self.farmId)
        self.isFirstRendering = false
    end
    local width, height = self:getDimension()
    if MapHotspot.DEBUGGING and self.clickArea ~= nil then
        drawOutlineCircle2D(x + width * 0.5, y + height * 0.5, width * (self.clickArea.radiusFactor or 1), 0.001, 40, 1, 0, 0, 1)
    end
    if not small then
        local icon = self.icon
        if icon ~= nil then
            icon:renderCustom(x, y, icon.width, icon.height, nil, nil, nil, self.isBlinking and IngameMap.alpha or 1)
        end
    end
    local icon = self.name
    if icon ~= "" then
        local a = self.isBlinking and IngameMap.alpha or 1
        setTextBold(true)
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
        setTextWrapWidth(0)
        local textSize = self.textSize * (0.25 + self.scale * 0.75)
        local posX = x + width * 0.5
        local posY = y + height * 0.5 + self.textOffsetY * self.scale
        if small then
            setTextColor(0, 0, 0, a)
            renderText(posX + g_pixelSizeScaledX, posY + g_pixelSizeScaledY, textSize, icon)
        end
        local r = self.textColor[1]
        local g = self.textColor[2]
        local b = self.textColor[3]
        if small then
            r = self.color[1]
            g = self.color[2]
            b = self.color[3]
        elseif self.disabled then
            r, g, b, a = unpack(self.textColorDisabled)
        end
        setTextColor(r, g, b, a)
        renderText(posX, posY, textSize, icon)
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
        setTextColor(1, 1, 1, 1)
        setTextBold(false)
    end
end
FarmlandHotspot.getWorldPosition = MapHotspot.getWorldPosition
FarmlandHotspot.getWorldRotation = MapHotspot.getWorldRotation
FarmlandHotspot.setScale = MapHotspot.setScale