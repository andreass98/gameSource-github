EnvironmentAreaWeight = {}
local EnvironmentAreaWeight_mt = Class(EnvironmentAreaWeight)
function EnvironmentAreaWeight.new(_, customMt)
    -- upvalues: (copy) EnvironmentAreaWeight_mt
    local self = setmetatable({}, customMt or EnvironmentAreaWeight_mt)
    self:reset()
    return self
end
function EnvironmentAreaWeight:reset()
    self.isNearWallWeight = 0
    self.isNearWaterWeight = 0
    self.isUnderRoofWeight = 0
    self.isInForestWeight = 0
    self.areaTypeWeights = self.areaTypeWeights or {}
    for _, areaTypeIndex in pairs(AreaType.getAll()) do
        self.areaTypeWeights[areaTypeIndex] = 0
    end
end
function EnvironmentAreaWeight:drawDebug(posX, posY, textSize)
    local function renderValue(name, value)
        -- upvalues: (copy) posX, (ref) posY, (copy) textSize
        setTextAlignment(RenderText.ALIGN_RIGHT)
        renderText(posX, posY, textSize, name .. " : ")
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(posX, posY, textSize, string.format("%.4f", value))
        posY = posY - textSize - 2 * g_pixelSizeY
    end
    setTextBold(false)
    for areaTypeIndex, value in pairs(self.areaTypeWeights) do
        renderValue(AreaType.getName(areaTypeIndex), value)
    end
    renderValue("isNearWallWeight", self.isNearWallWeight)
    renderValue("isNearWaterWeight", self.isNearWaterWeight)
    renderValue("isUnderRoofWeight", self.isUnderRoofWeight)
    renderValue("isInForestWeight", self.isInForestWeight)
    return posY
end