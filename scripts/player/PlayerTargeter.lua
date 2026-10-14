PlayerTargeter = {}
local PlayerTargeter_mt = Class(PlayerTargeter)
function PlayerTargeter.new(player)
    -- upvalues: (copy) PlayerTargeter_mt
    local self = setmetatable({}, PlayerTargeter_mt)
    self.player = player
    self.pooledTargets = ObjectPool.new()
    self.combinedTargetMask = 0
    self.targetedMasks = {}
    self.closestTargetsByKey = {}
    self.currentTargetsByKey = {}
    self.highestMaxDistance = 0
    self.lastRayX = nil
    self.lastRayY = nil
    self.lastRayZ = nil
    self.lastRayDirectionX = nil
    self.lastRayDirectionY = nil
    self.lastRayDirectionZ = nil
    return self
end
function PlayerTargeter:delete() end
function PlayerTargeter:getLastLookRay()
    return self.lastRayX, self.lastRayY, self.lastRayZ, self.lastRayDirectionX, self.lastRayDirectionY, self.lastRayDirectionZ
end
function PlayerTargeter:getHasTargetedKey(targetKey)
    return self.targetedMasks[targetKey] ~= nil
end
function PlayerTargeter:addTargetType(targetKey, targetMask, minDistance, maxDistance)
    if not self:getHasTargetedKey(targetKey) then
        self.highestMaxDistance = math.max(self.highestMaxDistance, maxDistance)
        self.targetedMasks[targetKey] = {
            ["key"] = targetKey,
            ["mask"] = targetMask,
            ["minDistance"] = minDistance or 0,
            ["maxDistance"] = maxDistance,
            ["filterFunctions"] = {}
        }
        self:recalculateCombinedTargetMask()
    end
end
function PlayerTargeter:addFilterToTargetType(targetKey, filterFunction)
    table.insert(self.targetedMasks[targetKey].filterFunctions, filterFunction)
end
function PlayerTargeter:removeTargetType(targetKey)
    self.targetedMasks[targetKey] = nil
    self:recalculateCombinedTargetMask()
    self.highestMaxDistance = 0
    for _, targetedMask in pairs(self.targetedMasks) do
        self.highestMaxDistance = math.max(self.highestMaxDistance, targetedMask.maxDistance)
    end
end
function PlayerTargeter:recalculateCombinedTargetMask()
    self.combinedTargetMask = 0
    for _, targetedMask in pairs(self.targetedMasks) do
        self.combinedTargetMask = bit32.bor(self.combinedTargetMask, targetedMask.mask)
    end
end
function PlayerTargeter:getClosestTargetedNodeFromType(targetKey)
    local closestTarget = self.closestTargetsByKey[targetKey]
    return closestTarget ~= nil and closestTarget.node or nil
end
function PlayerTargeter:update(_)
    self.lastRayX, self.lastRayY, self.lastRayZ, self.lastRayDirectionX, self.lastRayDirectionY, self.lastRayDirectionZ = self.player:getLookRay()
    if self.lastRayX ~= nil then
        self:resetState()
        raycastAllAsync(self.lastRayX, self.lastRayY, self.lastRayZ, self.lastRayDirectionX, self.lastRayDirectionY, self.lastRayDirectionZ, self.highestMaxDistance, "raycastCallback", self, self.combinedTargetMask)
    end
end
function PlayerTargeter:resetState()
    for key, target in pairs(self.closestTargetsByKey) do
        self.pooledTargets:returnToPool(target)
        self.closestTargetsByKey[key] = nil
    end
    self.closestTargetsByKey = self.currentTargetsByKey
    self.currentTargetsByKey = self.closestTargetsByKey
end
function PlayerTargeter:raycastCallback(hitNode, x, y, z, distance, _, _, _, _, _, _)
    if hitNode ~= nil and hitNode ~= 0 then
        for _, targetedMask in pairs(self.targetedMasks) do
            self:tryAddTargetWithMask(hitNode, x, y, z, targetedMask, distance)
        end
    end
end
function PlayerTargeter:tryAddTargetWithMask(hitNode, x, y, z, targetedMask, distance)
    if targetedMask.maxDistance < distance or (distance < targetedMask.minDistance or not CollisionFlag.getHasGroupFlagSet(hitNode, targetedMask.mask)) then
        return
    else
        local existingClosestTarget = self.currentTargetsByKey[targetedMask.key]
        if existingClosestTarget == nil or existingClosestTarget.distance >= distance then
            for i, filterFunction in ipairs(targetedMask.filterFunctions) do
                if not filterFunction(hitNode, x, y, z) then
                    return
                end
            end
            local target = self.pooledTargets:getOrCreateNext()
            target.x = x
            target.y = y
            target.z = z
            target.node = hitNode
            target.distance = distance
            self.currentTargetsByKey[targetedMask.key] = target
        end
    end
end
function PlayerTargeter:debugDraw(x, y, textSize)
    local combinedMaskName = DebugUtil.renderTextLine(x, y, textSize * 1.5, "Targeter", nil, true)
    local combinedMaskName = CollisionFlag.getFlagsStringFromMask(self.combinedTargetMask)
    y = DebugUtil.renderTextLine(x, combinedMaskName, textSize, string.format("Combined mask: %q", combinedMaskName), nil, true)
    y = DebugUtil.renderTextLine(x, y, textSize, "Masks:", nil, true)
    for key, targetedMask in pairs(self.targetedMasks) do
        local maskNode = self:getClosestTargetedNodeFromType(key)
        local nodeName = (maskNode ~= nil and entityExists(maskNode) and true or false) and getName(maskNode) or "none"
        local maskName = CollisionFlag.getFlagsStringFromMask(targetedMask.mask)
        y = DebugUtil.renderTextLine(x, y, textSize, string.format("Mask %q: %q", maskName, nodeName))
    end
    return y
end