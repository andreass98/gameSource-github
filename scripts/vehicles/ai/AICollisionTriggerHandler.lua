AICollisionTriggerHandler = {}
local AICollisionTriggerHandler_mt = Class(AICollisionTriggerHandler)
AICollisionTriggerHandler.UPDATE_INTERVAL = 5
AICollisionTriggerHandler.TRIGGER_SUBDIVISIONS = 1
AICollisionTriggerHandler.COLLISION_MASK = CollisionFlag.AI_BLOCKING + CollisionFlag.PLAYER + CollisionFlag.TREE + CollisionFlag.VEHICLE
function AICollisionTriggerHandler.new(customMt)
    -- upvalues: (copy) AICollisionTriggerHandler_mt
    local self = setmetatable({}, customMt or AICollisionTriggerHandler_mt)
    self.numCollidingVehicles = {}
    self.vehicleIgnoreList = {}
    self.collisionTriggerByVehicle = {}
    self.maxUpdateIndex = 1
    self.hasStaticCollision = false
    self.isBlocked = false
    self.dynamicHitPointDistance = math.huge
    self.staticHitPointDistance = math.huge
    return self
end
function AICollisionTriggerHandler:init(vehicle, strategy)
    self.vehicle = vehicle
    self.strategy = strategy
    if vehicle.isServer then
        self.collisionTriggerByVehicle = {}
        self.rootVehicle = vehicle.rootVehicle
        local vehicles = self.rootVehicle.childVehicles
        local i = 1
        local index = #vehicles
        for i = i, index do
            local subVehicle = vehicles[i]
            if subVehicle.getAICollisionTriggers ~= nil then
                subVehicle:getAICollisionTriggers(self.collisionTriggerByVehicle)
            end
            if subVehicle.getAIImplementCollisionTriggers ~= nil then
                subVehicle:getAIImplementCollisionTriggers(self.collisionTriggerByVehicle)
            end
        end
        local index = 1
        for v, trigger in pairs(self.collisionTriggerByVehicle) do
            trigger.vehicle = v
            trigger.updateIndex = index
            trigger.hasCollision = false
            trigger.hasStaticCollision = false
            trigger.isValid = true
            trigger.hitCounter = 0
            trigger.hitStaticCounter = 0
            trigger.curTriggerLength = 5
            trigger.curTriggerDirection = 1
            trigger.dynamicHitPoint = { 0, 0, 0 }
            trigger.dynamicHitPointValid = false
            trigger.dynamicHitPointDistance = math.huge
            trigger.dynamicHitPointInitialDistance = 0
            trigger.staticHitPoint = { 0, 0, 0 }
            trigger.staticHitPointValid = false
            trigger.staticHitPointDistance = math.huge
            trigger.staticHitPointInitialDistance = 0
            trigger.positions = {}
            for i = 1, (AICollisionTriggerHandler.TRIGGER_SUBDIVISIONS + 1) * 3 do
                table.insert(trigger.positions, 0)
            end
            index = index + AICollisionTriggerHandler.UPDATE_INTERVAL
        end
        self.maxUpdateIndex = index
    end
end
function AICollisionTriggerHandler:update(_, movingDirection)
    local dynamicHitPointDistance = math.huge
    local staticHitPointDistance = math.huge
    for v, trigger in pairs(self.collisionTriggerByVehicle) do
        if trigger.dynamicHitPointValid then
            local x, y, z = getWorldTranslation(trigger.node)
            trigger.dynamicHitPointDistance = math.max(trigger.length - MathUtil.vector3Length(trigger.dynamicHitPoint[1] - x, trigger.dynamicHitPoint[2] - y, trigger.dynamicHitPoint[3] - z) - trigger.dynamicHitPointInitialDistance, 0)
        end
        if trigger.staticHitPointValid then
            local x, y, z = getWorldTranslation(trigger.node)
            trigger.staticHitPointDistance = math.max(trigger.length - MathUtil.vector3Length(trigger.staticHitPoint[1] - x, trigger.staticHitPoint[2] - y, trigger.staticHitPoint[3] - z) - trigger.staticHitPointInitialDistance, 0)
        end
        local y = trigger.dynamicHitPointDistance
        dynamicHitPointDistance = math.min(y, dynamicHitPointDistance)
        local y = trigger.staticHitPointDistance
        staticHitPointDistance = math.min(y, staticHitPointDistance)
        if trigger.updateIndex == g_updateLoopIndex % self.maxUpdateIndex then
            self:generateTriggerPath(v, trigger, movingDirection)
            if trigger.isValid then
                trigger.hitCounter = 0
                trigger.hitStaticCounter = 0
                local x, y, z = localDirectionToWorld(trigger.node, 0, 0, trigger.curTriggerDirection)
                getVehicleCollisionDistance(trigger.positions, x, y, z, trigger.width, trigger.height, "onVehicleCollisionDistanceCallback", self, trigger, AICollisionTriggerHandler.COLLISION_MASK, true, true, true, true)
            end
        end
    end
    self.dynamicHitPointDistance = dynamicHitPointDistance
    self.staticHitPointDistance = staticHitPointDistance
    if self.collisionDistanceCallback ~= nil then
        self.collisionDistanceCallback((math.min(self.dynamicHitPointDistance, self.staticHitPointDistance)))
    end
    if VehicleDebug.state == VehicleDebug.DEBUG_AI then
        for v, trigger in pairs(self.collisionTriggerByVehicle) do
            self:generateTriggerPath(v, trigger, movingDirection)
            if trigger.isValid then
                local z = 1
                for z = z, #trigger.positions - 3, 3 do
                    drawDebugLine(trigger.positions[z + 0], trigger.positions[z + 1] + 2, trigger.positions[z + 2], 1, 0, 0, trigger.positions[z + 3], trigger.positions[z + 4] + 2, trigger.positions[z + 5], 0, 1, 0, true)
                end
                local x, y, z = localDirectionToWorld(trigger.node, 0, 0, 1)
                debugDrawVehicleCollision(trigger.positions, x, y, z, trigger.width, trigger.height)
            end
        end
    end
end
function AICollisionTriggerHandler:setStaticCollisionCallback(callback)
    self.staticCollisionCallback = callback
end
function AICollisionTriggerHandler:updateStaticCollisionCallback()
    local hasStaticCollision = false
    for v, trigger in pairs(self.collisionTriggerByVehicle) do
        if trigger.hasStaticCollision then
            hasStaticCollision = true
            break
        end
    end
    if hasStaticCollision ~= self.hasStaticCollision then
        self.hasStaticCollision = hasStaticCollision
        if self.staticCollisionCallback ~= nil then
            self.staticCollisionCallback(hasStaticCollision)
        end
    end
end
function AICollisionTriggerHandler:setIsBlockedCallback(callback)
    self.isBlockedCallback = callback
end
function AICollisionTriggerHandler:updateBlockedCallback()
    local isBlocked = false
    for v, trigger in pairs(self.collisionTriggerByVehicle) do
        if trigger.hasCollision then
            isBlocked = true
            break
        end
    end
    if isBlocked ~= self.isBlocked then
        self.isBlocked = isBlocked
        if self.isBlockedCallback ~= nil then
            self.isBlockedCallback(isBlocked)
        end
    end
end
function AICollisionTriggerHandler:setCollisionDistanceCallback(callback)
    self.collisionDistanceCallback = callback
end
function AICollisionTriggerHandler.generateTriggerPath(_, _, trigger, movingDirection)
    trigger.curTriggerDirection = movingDirection < 0 and trigger.backNode ~= trigger.node and trigger.backNodeDirection or 1
    local i = 0
    for i = i, AICollisionTriggerHandler.TRIGGER_SUBDIVISIONS * 3, 3 do
        local x, y, z = localToWorld(movingDirection >= 0 and trigger.node or (trigger.backNode or trigger.node), 0, 0, i / AICollisionTriggerHandler.TRIGGER_SUBDIVISIONS / 3 * trigger.length * trigger.curTriggerDirection)
        trigger.positions[i + 1] = x
        trigger.positions[i + 2] = getTerrainHeightAtWorldPos(g_terrainNode, x, y, z) + trigger.height * 0.5
        trigger.positions[i + 3] = z
    end
    trigger.isValid = true
end
function AICollisionTriggerHandler:onVehicleCollisionDistanceCallback(_, objectId, _, isLast, trigger)
    if g_currentMission ~= nil and self.collisionTriggerByVehicle ~= nil then
        for vehicle, _ in pairs(self.collisionTriggerByVehicle) do
            if vehicle.isDeleted or vehicle.isDeleting then
                return false
            end
        end
        if objectId ~= 0 then
            if g_currentMission.playerSystem:getPlayerByRootNode(objectId) == nil then
                local vehicle = g_currentMission.nodeToObject[objectId]
                if (vehicle == nil or self.collisionTriggerByVehicle[vehicle] == nil) and (not getHasTrigger(objectId) and (vehicle == nil or (vehicle.getRootVehicle == nil or vehicle:getRootVehicle() ~= self.rootVehicle))) then
                    if getRigidBodyType(objectId) == RigidBodyType.DYNAMIC then
                        local vehicle = getCollisionFilterGroup(objectId)
                        if bit32.band(vehicle, CollisionFlag.VEHICLE) ~= 0 then
                            trigger.hitCounter = trigger.hitCounter + 1
                        end
                    else
                        trigger.hitStaticCounter = trigger.hitStaticCounter + 1
                    end
                end
            else
                trigger.hitCounter = trigger.hitCounter + 1
            end
        end
        if objectId ~= 0 and not isLast then
            return true
        end
        local player = trigger.hitCounter > 0
        if player ~= trigger.hasCollision then
            trigger.hasCollision = player
            if player then
                trigger.dynamicHitPointValid = true
                _, trigger.dynamicHitPoint[2], trigger.dynamicHitPoint[3] = getWorldTranslation(trigger.node)
                trigger.dynamicHitPoint[1] = _
                trigger.dynamicHitPointInitialDistance = trigger.vehicle.lastSpeedReal * g_physicsDt * AICollisionTriggerHandler.UPDATE_INTERVAL
            else
                trigger.dynamicHitPointValid = false
                trigger.dynamicHitPointDistance = math.huge
            end
            self:updateBlockedCallback()
        end
        local vehicle = trigger.hitStaticCounter > 0
        if vehicle ~= trigger.hasStaticCollision then
            trigger.hasStaticCollision = vehicle
            if vehicle then
                trigger.staticHitPointValid = true
                trigger.staticHitPoint[1], trigger.staticHitPoint[2], trigger.staticHitPoint[3] = getWorldTranslation(trigger.node)
                trigger.staticHitPointInitialDistance = trigger.vehicle.lastSpeedReal * g_physicsDt * AICollisionTriggerHandler.UPDATE_INTERVAL
            else
                trigger.staticHitPointValid = false
                trigger.staticHitPointDistance = math.huge
            end
            self:updateStaticCollisionCallback()
        end
        return false
    end
end