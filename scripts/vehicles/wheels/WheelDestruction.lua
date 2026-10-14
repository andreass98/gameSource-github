WheelDestruction = {}
WheelDestruction.MAX_UPDATE_DISTANCE = 40
function WheelDestruction.new(wheel)
    local self = setmetatable({}, {
        ["__index"] = WheelDestruction
    })
    self.wheel = wheel
    self.vehicle = wheel.vehicle
    self.destructionNodes = {}
    self.wheelSmoothAccumulation = 0
    return self
end
function WheelDestruction:loadFromXML(xmlObject)
    xmlObject:checkDeprecatedXMLElements(".tire#isCareWheel", "#isCareWheel")
    self.isCareWheel = xmlObject:getValue("#isCareWheel", false)
    self.smoothGroundRadius = xmlObject:getValue(".physics#smoothGroundRadius", (math.max(0.6, self.wheel.physics.width * 0.75)))
    return true
end
function WheelDestruction:finalize()
    for _, visualWheel in ipairs(self.wheel.visualWheels) do
        table.insert(self.destructionNodes, {
            ["node"] = visualWheel.node,
            ["width"] = visualWheel.width,
            ["radius"] = visualWheel.radius
        })
    end
    if #self.wheel.visualWheels == 0 then
        table.insert(self.destructionNodes, {
            ["node"] = self.wheel.driveNode,
            ["width"] = self.wheel.physics.width,
            ["radius"] = self.wheel.physics.radius
        })
    end
end
function WheelDestruction:update(dt, allowFoliageDestruction)
    if g_server ~= nil or self.vehicle.currentUpdateDistance < WheelDestruction.MAX_UPDATE_DISTANCE then
        if allowFoliageDestruction and self.vehicle.lastSpeedReal > 0.0002 then
            local hasContact = self.wheel.physics.contact ~= WheelContactType.NONE
            local doFruitDestruction = hasContact and not self.isCareWheel
            if hasContact then
                hasContact = self.wheel.physics.hasSnowContact
            end
            if doFruitDestruction or hasContact then
                for _, destructionNode in ipairs(self.destructionNodes) do
                    local repr = self.wheel.repr
                    local yShift = 0.5 * destructionNode.width
                    local length = math.min(0.5, yShift)
                    local xShift, yShift, zShift = localToLocal(destructionNode.node, repr, 0, 0, 0)
                    if doFruitDestruction then
                        local x0, _, z0 = localToWorld(repr, xShift + 0.5 * destructionNode.width, yShift, zShift - length)
                        local x1, _, z1 = localToWorld(repr, xShift - width, yShift, zShift - length)
                        local x2, _, z2 = localToWorld(repr, xShift + width, yShift, zShift + length)
                        if g_farmlandManager:getIsOwnedByFarmAtWorldPosition(self.vehicle:getActiveFarm(), x0, z0) then
                            self:destroyFruitArea(x0, z0, x1, z1, x2, z2)
                        end
                    end
                    if hasContact then
                        local x0 = destructionNode.radius * 0.75 * self.vehicle.movingDirection
                        local _, z0, x1 = localToWorld(repr, xShift + width, yShift, zShift - length + x0)
                        local _, z1, x2 = localToWorld(repr, xShift - width, yShift, zShift - length + x0)
                        local _, z2, z5 = localToWorld(repr, xShift + width, yShift, zShift + length + x0)
                        self:destroySnowArea(_, x1, _, x2, _, z5)
                    end
                end
            end
        end
        if Platform.gameplay.wheelDensityHeightSmooth then
            local hasContact = 0
            if self.vehicle.lastSpeedReal > 0.0002 then
                hasContact = self.wheelSmoothAccumulation + math.max(self.vehicle.lastMovedDistance * 1.2, 0.0003 * dt)
                self.wheelSmoothAccumulation = hasContact - DensityMapHeightUtil.getRoundedHeightValue(hasContact)
            else
                self.wheelSmoothAccumulation = 0
            end
            if hasContact > 0 then
                for _, destructionNode in ipairs(self.destructionNodes) do
                    local _, destructionNode, repr = localToLocal(destructionNode.node, self.wheel.repr, 0, 0, 0)
                    local width, length, xShift = localToLocal(self.wheel.node, self.wheel.repr, self.wheel.physics.netInfo.x, self.wheel.physics.netInfo.y, self.wheel.physics.netInfo.z)
                    local yShift, zShift, x0 = localToWorld(self.wheel.repr, width + _, length - self.wheel.physics.radius, xShift)
                    self:smoothHeightAtPosition(yShift, zShift, x0, self.smoothGroundRadius, hasContact)
                end
            end
        end
    end
end
function WheelDestruction.destroyFruitArea(_, x0, z0, x1, z1, x2, z2)
    FSDensityMapUtil.updateWheelDestructionArea(x0, z0, x1, z1, x2, z2)
end
function WheelDestruction.destroySnowArea(_, x0, z0, x1, z1, x2, z2)
    local snowSystem = g_currentMission.snowSystem
    local worldSnowHeight = snowSystem.height
    local curHeight = snowSystem:getSnowHeightAtArea(x0, z0, x1, z1, x2, z2)
    local reduceSnow = MathUtil.equalEpsilon(worldSnowHeight, curHeight, 0.005)
    local isOnSnowHeap = false
    if worldSnowHeight < 0.005 then
        isOnSnowHeap = curHeight > 1
    end
    if SnowSystem.MIN_LAYER_HEIGHT < curHeight and (reduceSnow or isOnSnowHeap) then
        local sink = 0.7 * worldSnowHeight
        if isOnSnowHeap then
            sink = 0.1 * curHeight
        end
        local sinkLayers = math.floor(math.min(sink, curHeight) / SnowSystem.MIN_LAYER_HEIGHT)
        if sinkLayers > 0 then
            snowSystem:removeSnow(x0, z0, x1, z1, x2, z2, sinkLayers)
        end
    end
end
function WheelDestruction.smoothHeightAtPosition(_, x, y, z, radius, amount)
    local heightType = DensityMapHeightUtil.getHeightTypeDescAtWorldPos(x, y, z, radius)
    if heightType ~= nil and heightType.allowsSmoothing then
        local terrainHeightUpdater = g_densityMapHeightManager:getTerrainDetailHeightUpdater()
        if terrainHeightUpdater ~= nil then
            local terrainHeight = getTerrainHeightAtWorldPos(g_terrainNode, x, y, z)
            local physicsDeltaHeight = y - terrainHeight
            local internalHeight = terrainHeight + math.max(math.min(math.max((physicsDeltaHeight + heightType.collisionBaseOffset) / heightType.collisionScale, physicsDeltaHeight + heightType.minCollisionOffset), physicsDeltaHeight + heightType.maxCollisionOffset) + -0.1, 0)
            smoothDensityMapHeightAtWorldPos(terrainHeightUpdater, x, internalHeight, z, amount, heightType.index, 0, radius, radius + 1.2, 0)
            if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
                DebugUtil.drawDebugCircle(x, internalHeight, z, radius, 10)
            end
        end
    end
end
function WheelDestruction:drawAreas()
    if not self.isCareWheel then
        for _, visualWheel in ipairs(self.wheel.visualWheels) do
            local repr = self.wheel.repr
            local width = 0.5 * visualWheel.width
            local length = math.min(0.5, 0.5 * visualWheel.width)
            local xShift, yShift, zShift = localToLocal(visualWheel.node, repr, 0, 0, 0)
            local x0, y0, z0 = localToWorld(repr, xShift + width, yShift, zShift - length)
            local x1, _, z1 = localToWorld(repr, xShift - width, yShift, zShift - length)
            local x2, _, z2 = localToWorld(repr, xShift + width, yShift, zShift + length)
            local x, z, widthX, widthZ, heightX, heightZ = MathUtil.getXZWidthAndHeight(x0, z0, x1, z1, x2, z2)
            DebugUtil.drawDebugParallelogram(x, z, widthX, widthZ, heightX, heightZ, y0, 1, 1, 0, 0.05, true)
        end
        if #self.wheel.visualWheels == 0 then
            local repr = self.wheel.repr
            local width = 0.5 * self.wheel.physics.width
            local length = math.min(0.5, 0.5 * self.wheel.physics.width)
            local _, visualWheel, repr = localToLocal(self.wheel.driveNode, repr, 0, 0, 0)
            local width, length, xShift = localToWorld(repr, _ + width, visualWheel, repr - length)
            local yShift, zShift, x0 = localToWorld(repr, _ - width, visualWheel, repr - length)
            local y0, z0, x1 = localToWorld(repr, _ + width, visualWheel, repr + length)
            local _, z1, x2, _, z2, x = MathUtil.getXZWidthAndHeight(width, xShift, yShift, x0, y0, x1)
            DebugUtil.drawDebugParallelogram(_, z1, x2, _, z2, x, length, 1, 1, 0, 0.05, true)
        end
    end
end
function WheelDestruction:setIsCareWheel(isCareWheel)
    self.isCareWheel = isCareWheel
end
function WheelDestruction.registerXMLPaths(schema, key)
    schema:register(XMLValueType.BOOL, key .. "#isCareWheel", "Is care wheel", false)
    schema:register(XMLValueType.FLOAT, key .. ".physics#smoothGroundRadius", "Smooth ground radius", "width * 0.75")
end