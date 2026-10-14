HandToolHolderActivatable = {}
local HandToolHolderActivatable_mt = Class(HandToolHolderActivatable)
function HandToolHolderActivatable.new(handToolHolder, takeText, storeText, needTargeting)
    -- upvalues: (copy) HandToolHolderActivatable_mt
    local self = setmetatable({}, HandToolHolderActivatable_mt)
    self.handToolHolder = handToolHolder
    self.needTargeting = needTargeting
    self.takeText = takeText
    self.storeText = storeText
    self.activateText = self.takeText
    return self
end
function HandToolHolderActivatable:getIsActivatable()
    local localPlayer = g_localPlayer
    if localPlayer == nil then
        return false
    end
    if self.needTargeting then
        if localPlayer.targeter == nil then
            return false
        end
        if HandToolUtil.getTargetedHandToolHolder(localPlayer.targeter) ~= self.handToolHolder then
            return false
        end
    end
    local targetedHandToolHolder = self.handToolHolder:getHandTool()
    local playerHandTool = localPlayer:getHeldHandTool()
    if playerHandTool == nil and targetedHandToolHolder ~= nil then
        local canPickup = localPlayer:getCanPickupHandTool(targetedHandToolHolder)
        if canPickup then
            self.activateText = string.format(self.takeText, targetedHandToolHolder.typeDesc)
        end
        return canPickup
    end
    if playerHandTool == nil or targetedHandToolHolder ~= nil then
        return false
    end
    local canPickup = self.handToolHolder:getCanPickupHandTool(playerHandTool)
    if canPickup then
        self.activateText = string.format(self.storeText, playerHandTool.typeDesc)
    end
    return canPickup
end
function HandToolHolderActivatable:getDistance(positionX, positionY, positionZ)
    if self.needTargeting and self:getIsActivatable() then
        return 0
    end
    local x, y, z = getWorldTranslation(self.handToolHolder.holderNode)
    return MathUtil.vector3Length(positionX - x, positionY - y, positionZ - z)
end
function HandToolHolderActivatable:run()
    local holderHandTool = self.handToolHolder:getHandTool()
    local playerHandTool = g_localPlayer:getHeldHandTool()
    if playerHandTool == nil and holderHandTool ~= nil then
        holderHandTool:setHolder(g_localPlayer)
        g_localPlayer:setCurrentHandTool(holderHandTool)
    elseif playerHandTool ~= nil and holderHandTool == nil then
        playerHandTool:setHolder(self.handToolHolder)
    end
end