DebugBitVectorMap = {}
local DebugBitVectorMap_mt = Class(DebugBitVectorMap)
function DebugBitVectorMap.new(customMt)
    -- upvalues: (copy) DebugBitVectorMap_mt
    local self = setmetatable({}, customMt or DebugBitVectorMap_mt)
    self.radius = 15
    self.cellSize = 0.5
    self.vertexAligned = false
    self.opacity = 0.4
    self.valueToColor = {
        [0] = Color.PRESETS.RED:copy(),
        [1] = Color.PRESETS.GREEN:copy(),
        [2] = Color.PRESETS.BLUE:copy()
    }
    self.undefinedValueColor = Color.new(0.2, 0.2, 0.2)
    self.yOffset = 0.1
    self.solid = false
    self.pixelPaddingFactor = 0.02
    self.displayLegend = true
    return self
end
function DebugBitVectorMap.newSimple(radius, cellSize, vertexAligned, opacity, yOffset, solid, pixelPaddingFactor, displayLegend)
    local self = DebugBitVectorMap.new()
    self.radius = radius or self.radius
    self.cellSize = cellSize or self.cellSize
    self.vertexAligned = vertexAligned or self.vertexAligned
    self.opacity = opacity or self.opacity
    self.yOffset = yOffset or self.yOffset
    self.solid = Utils.getNoNil(solid, self.solid)
    self.pixelPaddingFactor = pixelPaddingFactor or self.pixelPaddingFactor
    self.displayLegend = Utils.getNoNil(displayLegend, self.displayLegend)
    return self
end
function DebugBitVectorMap:draw()
    if self.aiVehicle == nil then
        if self.customFunc ~= nil then
            local cx, _, cz = getWorldTranslation(g_cameraManager:getActiveCamera())
            self:drawAroundCenter(cx, cz, self.customFunc)
        end
    elseif not (self.aiVehicle.isDeleted or self.aiVehicle.isDeleting) then
        local cx, _, cz = getWorldTranslation(self.aiVehicle.rootNode)
        self:drawAroundCenter(cx, cz, DebugBitVectorMap.aiAreaCheck)
        return
    end
end
function DebugBitVectorMap:createWithAIVehicle(vehicle)
    self.aiVehicle = vehicle
    return self
end
function DebugBitVectorMap:createWithCustomFunc(customFunc)
    self.customFunc = customFunc
    return self
end
function DebugBitVectorMap:setAdditionalDrawInfoFunc(drawInfoFunc)
    self.drawInfoFunc = drawInfoFunc
    return self
end
function DebugBitVectorMap:getColorForValue(value)
    return self.valueToColor[value] or self.undefinedValueColor
end
function DebugBitVectorMap:drawAroundCenter(x, z, getValueAtAreaFunc)
    local cellSize = self.cellSize
    local steps = math.ceil(self.radius / cellSize) * 2
    x = math.floor(x / self.cellSize) * self.cellSize
    z = math.floor(z / self.cellSize) * self.cellSize
    if self.vertexAligned then
    end
    local xStep = 0
    for xStep = xStep, steps do
        local zStep = 0
        local v3_ = steps
        for zStep = zStep, steps do
            local startWorldX = x + (xStep - steps * 0.5) * cellSize
            local startWorldZ = z + (zStep - steps * 0.5) * cellSize
            local widthWorldX = x + (xStep + 1 - steps * 0.5) * cellSize
            local widthWorldZ = z + (zStep - steps * 0.5) * cellSize
            local heightWorldX = x + (xStep - steps * 0.5) * cellSize
            local heightWorldZ = z + (zStep + 1 - steps * 0.5) * cellSize
            local area, areaTotal = getValueAtAreaFunc(self, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
            if area == nil then
                v3_ = steps
            else
                local color = self:getColorForValue(area)
                local startWorldX = startWorldX + cellSize * self.pixelPaddingFactor
                local startWorldZ = startWorldZ + cellSize * self.pixelPaddingFactor
                local widthWorldX = widthWorldX - cellSize * self.pixelPaddingFactor
                local heightWorldZ = heightWorldZ - cellSize * self.pixelPaddingFactor
                color.a = self.opacity
                DebugPlane.renderWithPositions(startWorldX, 0, startWorldZ, heightWorldX + cellSize * self.pixelPaddingFactor, 0, heightWorldZ, widthWorldX, 0, widthWorldZ + cellSize * self.pixelPaddingFactor, color, true, true, false, false)
                if self.drawInfoFunc == nil then
                    v3_ = steps
                else
                    self.drawInfoFunc(self, (startWorldX + widthWorldX) * 0.5, (startWorldZ + heightWorldZ) * 0.5, area, areaTotal)
                    v3_ = steps
                end
            end
            steps = v3_
        end
    end
    if self.displayLegend then
        local xStep = getTextHeight(0.015, "1") * 0.9
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(0.01, 0.7, 0.015, "DebugBitVector colors")
        local legendEntryOffset = 0 + 0.0165
        for startWorldX, startWorldZ in pairs(self.valueToColor) do
            drawFilledRect(0.013, 0.7 - legendEntryOffset, xStep, xStep, startWorldZ[1], startWorldZ[2], startWorldZ[3], self.opacity)
            renderText(0.013 + xStep * 1.2, 0.7 - legendEntryOffset, 0.015, string.format("%d", startWorldX))
            legendEntryOffset = legendEntryOffset + 0.015
        end
        drawFilledRect(0.013, 0.7 - legendEntryOffset, xStep, xStep, self.undefinedValueColor[1], self.undefinedValueColor[2], self.undefinedValueColor[3], self.opacity)
        renderText(0.013 + xStep * 1.2, 0.7 - legendEntryOffset, 0.015, "*")
    end
end
function DebugBitVectorMap:aiAreaCheck(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    return AIVehicleUtil.getAIAreaOfVehicle(self.aiVehicle, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
end