Butterfly = {}
local Butterfly_mt = Class(Butterfly)
function Butterfly.onCreate(_, id)
    g_currentMission:addUpdateable(Butterfly.new(id))
end
function Butterfly.new(id)
    -- upvalues: (copy) Butterfly_mt
    local self = setmetatable({}, Butterfly_mt)
    self.id = id
    self.butterflies = {}
    local i = 1
    local butterflyId = getNumOfChildren(id)
    for i = i, butterflyId do
        local butterflyId = getChildAt(id, i - 1)
        local butterfly = {
            ["butterflyId"] = butterflyId,
            ["splineId"] = getChildAt(butterflyId, 0),
            ["meshId"] = getChildAt(butterflyId, 1),
            ["speed"] = Utils.getNoNil(getUserAttribute(butterflyId, "speed"), 0.005),
            ["splinePos"] = 0
        }
        table.insert(self.butterflies, butterfly)
    end
    self.time = 0
    self.animTimer = 0
    self.animDelay = 100
    self.flip = true
    self.checkClosestButterflyTimer = 0
    self.checkClosestButterflyInterval = 2000
    self.activeButterfly = nil
    self.isSunOn = true
    return self
end
function Butterfly:delete() end
function Butterfly:update(dt)
    if g_currentMission.environment.isSunOn ~= self.isSunOn then
        self.isSunOn = g_currentMission.environment.isSunOn
        if self.isSunOn then
            setVisibility(self.id, true)
        else
            setVisibility(self.id, false)
        end
    end
    if self.isSunOn then
        self.checkClosestButterflyTimer = self.checkClosestButterflyTimer - dt
        if self.checkClosestButterflyTimer <= 0 then
            local closestDistance = 100000000
            local closestButterfly = nil
            local playerPositionX, playerPositionY, playerPositionZ = g_localPlayer:getPosition()
            for _, butterfly in pairs(self.butterflies) do
                local distance, butterflyPositionY, butterflyPositionZ = getWorldTranslation(butterfly.splineId)
                local distance = MathUtil.vector3Length(playerPositionX - distance, playerPositionY - butterflyPositionY, playerPositionZ - butterflyPositionZ)
                if distance < closestDistance then
                    closestButterfly = butterfly
                    closestDistance = distance
                end
            end
            if closestDistance < 150 then
                for _, butterfly in pairs(self.butterflies) do
                    if butterfly.butterflyId == closestButterfly.butterflyId then
                        setVisibility(butterfly.butterflyId, true)
                    else
                        setVisibility(butterfly.butterflyId, false)
                    end
                end
                self.activeButterfly = closestButterfly
            else
                for _, butterfly in pairs(self.butterflies) do
                    setVisibility(butterfly.butterflyId, false)
                end
                self.activeButterfly = nil
            end
            self.checkClosestButterflyTimer = self.checkClosestButterflyInterval
        end
        if self.activeButterfly ~= nil then
            self.animTimer = self.animTimer - dt
            if self.animTimer <= 0 then
                self.flip = not self.flip
                setVisibility(getChildAt(self.activeButterfly.meshId, 0), self.flip)
                setVisibility(getChildAt(self.activeButterfly.meshId, 1), not self.flip)
                self.animTimer = self.animDelay
            end
            self.time = self.time + dt * math.random() * 1
            self.activeButterfly.splinePos = self.activeButterfly.splinePos + dt * math.random() * 1 * self.activeButterfly.speed * 0.01
            local playerPositionX = math.sin(self.time * 0.005)
            local closestDistance = playerPositionX * math.cos(self.time * 0.025) * 0.05
            local closestButterfly = math.sin(self.time * 0.0175) * math.cos(self.time * 0.0125) * 0.05
            if self.activeButterfly.splinePos > 1 then
                self.activeButterfly.splinePos = self.activeButterfly.splinePos - 1
            end
            local playerPositionX, playerPositionY, playerPositionZ = getSplinePosition(self.activeButterfly.splineId, self.activeButterfly.splinePos)
            local butterflyPositionX, butterflyPositionY, butterflyPositionZ = getSplineOrientation(self.activeButterfly.splineId, self.activeButterfly.splinePos, 0, -1, 0)
            setTranslation(self.activeButterfly.meshId, playerPositionX + closestDistance, playerPositionY + closestButterfly, playerPositionZ + closestDistance)
            setRotation(self.activeButterfly.meshId, butterflyPositionX, butterflyPositionY, butterflyPositionZ)
        end
    end
end