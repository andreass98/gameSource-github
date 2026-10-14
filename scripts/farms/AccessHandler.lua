AccessHandler = {}
AccessHandler.EVERYONE = 0
AccessHandler.NOBODY = 2 ^ FarmManager.FARM_ID_SEND_NUM_BITS - 1
local AccessHandler_mt = Class(AccessHandler)
function AccessHandler.new(customMt)
    -- upvalues: (copy) AccessHandler_mt
    return setmetatable({}, customMt or AccessHandler_mt)
end
function AccessHandler:delete() end
function AccessHandler:canPlayerAccess(object, player, allowEqualAlways)
    local playerFarmId
    if player == nil then
        playerFarmId = g_currentMission:getFarmId()
    else
        playerFarmId = player.farmId
    end
    return self:canFarmAccess(playerFarmId, object, allowEqualAlways)
end
function AccessHandler:canFarmAccess(farmId, object, allowEqualAlways)
    if object == nil then
        return false
    end
    local ownerFarmId = object:getOwnerFarmId()
    if farmId == FarmManager.SPECTATOR_FARM_ID and (not allowEqualAlways or farmId ~= ownerFarmId) then
        return false
    end
    if ownerFarmId == nil or ownerFarmId == AccessHandler.EVERYONE then
        return true
    end
    if farmId ~= nil then
        return self:canFarmAccessOtherId(farmId, ownerFarmId)
    end
    return ownerFarmId == AccessHandler.EVERYONE
end
function AccessHandler.canFarmAccessOtherId(_, farmId, objectFarmId)
    if objectFarmId == AccessHandler.EVERYONE then
        return true
    elseif objectFarmId == AccessHandler.NOBODY then
        return false
    elseif objectFarmId == farmId then
        return true
    else
        local farm = g_farmManager:getFarmById(farmId)
        if farm == nil then
            return false
        else
            return farm:getIsContractingFor(objectFarmId)
        end
    end
end
function AccessHandler.canFarmAccessLand(_, farmId, x, z, disallowContracting)
    if farmId == FarmlandManager.NO_OWNER_FARM_ID then
        return false
    end
    local ownerFarmId = g_farmlandManager:getOwnerIdAtWorldPosition(x, z)
    if ownerFarmId == farmId then
        return true
    end
    local farm = g_farmManager:getFarmById(farmId)
    if farm == nil then
        return false
    end
    return disallowContracting ~= true and farm:getIsContractingFor(ownerFarmId)
end