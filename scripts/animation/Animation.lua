Animation = {}
Animation.DEFAULT_UPDATE_DISTANCE = 150
local Animation_mt = Class(Animation)
function Animation.new(customMt)
    -- upvalues: (copy) Animation_mt
    local self = setmetatable({}, customMt or Animation_mt)
    self.duplicates = {}
    self.allowUpdate = true
    self.lastUpdateTime = 0
    return self
end
function Animation:delete()
    local i = #self.duplicates
    for i = i, 1, -1 do
        self.duplicates[i] = nil
    end
end
function Animation:update(dt) end
function Animation:isRunning()
    return false
end
function Animation:setUpdateDistance(maxUpdateDistance)
    if self.owner == nil then
        return
    elseif self.owner.currentUpdateDistance ~= nil then
        if maxUpdateDistance == math.huge then
            maxUpdateDistance = nil
        end
        self.maxUpdateDistance = maxUpdateDistance
    end
end
function Animation:getAllowUpdate()
    return self.maxUpdateDistance == nil or self.owner.currentUpdateDistance < self.maxUpdateDistance
end
function Animation:start()
    return false
end
function Animation:stop()
    return false
end
function Animation:reset() end
function Animation:setFillType(fillTypeIndex) end
function Animation:isDuplicate(otherAnimation)
    return false
end
function Animation:addDuplicate(otherAnimation)
    table.insert(self.duplicates, otherAnimation)
end
function Animation:updateDuplicates()
    local i = 1
    for i = i, #self.duplicates do
        self:updateDuplicate(self.duplicates[i])
    end
end
function Animation:updateDuplicate(otherAnimation) end
function Animation.calculateTurnOffFadeTime(currentSpeedFactor, currentSpeed, direction, position, targetPosition, originalFadeOut, wrapPosition, subDivisions)
    wrapPosition = wrapPosition / subDivisions
    local i = 1
    for i = i, originalFadeOut do
        currentSpeedFactor = math.max(currentSpeedFactor - 1 / originalFadeOut, 0)
    end
    if math.abs(position - position) < 0.00001 then
        return 1
    end
    local int, fraction = math.modf((position - targetPosition) / wrapPosition)
    local i = int * wrapPosition + targetPosition
    if (direction <= 0 or math.abs(fraction) <= 0.2) and (direction >= 0 or math.abs(fraction) >= 0.2) then
        if math.abs(i - position) >= wrapPosition * 0.5 then
            ::l11::
            return (position - (int * wrapPosition + targetPosition)) / (position - position) * originalFadeOut
        end
    end
    int = int + direction
    goto l11
end