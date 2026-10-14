InfoDisplayBox = {}
local InfoDisplayBox_mt = Class(InfoDisplayBox)
function InfoDisplayBox.new(infoDisplay, uiScale, customMt)
    -- upvalues: (copy) InfoDisplayBox_mt
    local self = setmetatable({}, customMt or InfoDisplayBox_mt)
    self.infoDisplay = infoDisplay
    self.uiScale = uiScale
    return self
end
function InfoDisplayBox:delete() end
function InfoDisplayBox:setScale(uiScale)
    self.uiScale = uiScale
    self:storeScaledValues()
end
function InfoDisplayBox:storeScaledValues() end
function InfoDisplayBox:canDraw()
    return true
end
function InfoDisplayBox.draw(_, posX, posY)
    return posX, posY
end