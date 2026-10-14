AIHotspot = {}
local AIHotspot_mt = Class(AIHotspot, MapHotspot)
function AIHotspot.new(customMt)
    -- upvalues: (copy) AIHotspot_mt
    local self = MapHotspot.new(customMt or AIHotspot_mt)
    if Platform.isMobile then
        local _, textSize = getNormalizedScreenValues(120, 120)
        self.width = _
        self.height = textSize
        local _, textSize = getNormalizedScreenValues(0, 20)
        self.textSize = textSize
        self.textOffsetX, self.textOffsetY = getNormalizedScreenValues(60, 53)
        self.clickArea = MapHotspot.getClickCircle(0.667)
    else
        local _, textSize = getNormalizedScreenValues(50, 50)
        self.width = _
        self.height = textSize
        local _, textSize = getNormalizedScreenValues(0, 10)
        self.textSize = textSize
        self.textOffsetX, self.textOffsetY = getNormalizedScreenValues(25, 21)
        self.clickArea = MapHotspot.getClickCircle(0.333)
    end
    self.name = nil
    self.icon = g_overlayManager:createOverlay("mapHotspots.worker", 0, 0, self.width, self.height)
    return self
end
function AIHotspot:getCategory()
    return MapHotspot.CATEGORY_AI
end
function AIHotspot:setVehicle(vehicle)
    self.vehicle = vehicle
end
function AIHotspot:getVehicle()
    return self.vehicle
end
function AIHotspot:setAIHelperName(name)
    self.name = name
end
function AIHotspot:getWorldPosition()
    local x = nil
    local z = nil
    if self.vehicle ~= nil and entityExists(self.vehicle.rootNode) then
        x, _, z = getWorldTranslation(self.vehicle.rootNode)
    end
    return x, z
end
function AIHotspot:render(x, y, rotation, small)
    AIHotspot:superClass().render(self, x, y, rotation, small)
    if self.name ~= nil then
        local alpha = 1
        if self.isBlinking then
            alpha = IngameMap.alpha
        end
        setTextColor(1, 1, 1, alpha)
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextWrapWidth(0)
        setTextBold(false)
        renderText(x + self.textOffsetX * self.scale, y + self.textOffsetY * self.scale, self.textSize * self.scale, self.name)
        setTextColor(1, 1, 1, 1)
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
end
function AIHotspot:setOwnerFarmId(farmId)
    AIHotspot:superClass().setOwnerFarmId(self, farmId)
    if g_currentMission.missionDynamicInfo.isMultiplayer then
        local farm = g_farmManager:getFarmById(farmId)
        if farm ~= nil then
            local color = Farm.COLORS[farm.color]
            if color ~= nil then
                self:setColor(unpack(color))
            end
        end
    end
end