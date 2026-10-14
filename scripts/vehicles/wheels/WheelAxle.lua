WheelAxle = {}
local WheelAxle_mt = Class(WheelAxle)
function WheelAxle.new(vehicle, customMt)
    -- upvalues: (copy) WheelAxle_mt
    local self = setmetatable({}, customMt or WheelAxle_mt)
    self.vehicle = vehicle
    return self
end
function WheelAxle:delete() end
function WheelAxle:loadFromXML(xmlFile, key)
    self.wheelNode1 = xmlFile:getValue(key .. "#wheel1", nil, self.vehicle.components, self.vehicle.i3dMappings)
    self.wheelNode2 = xmlFile:getValue(key .. "#wheel2", nil, self.vehicle.components, self.vehicle.i3dMappings)
    if self.wheelNode1 == nil or self.wheelNode2 == nil then
        Logging.xmlError(xmlFile, "WheelAxle \'%s\' missing wheel1 or wheel2", key)
        return false
    end
    self.wheel1 = self.vehicle:getWheelByWheelNode(self.wheelNode1)
    self.wheel2 = self.vehicle:getWheelByWheelNode(self.wheelNode2)
    if self.wheel1 == nil or self.wheel2 == nil then
        return false
    end
    local springLoadMultiplier = xmlFile:getValue(key .. ".dynamicSuspension#springLoadMultiplier", 1)
    local dampingLoadMultiplier = xmlFile:getValue(key .. ".dynamicSuspension#dampingLoadMultiplier", 1)
    if springLoadMultiplier ~= 1 or dampingLoadMultiplier ~= 1 then
        self.dynamicSuspension = {}
        self.dynamicSuspension.springLoadMultiplier = springLoadMultiplier
        self.dynamicSuspension.dampingLoadMultiplier = dampingLoadMultiplier
        self.dynamicSuspension.maxLoad = xmlFile:getValue(key .. ".dynamicSuspension#maxLoad")
        self.dynamicSuspension.interpolationTime = 1 / xmlFile:getValue(key .. ".dynamicSuspension#interpolationTime", 1)
        self.dynamicSuspension.interpolatedAlpha = 0
        self.dynamicSuspension.appliedAlpha = 0
        if self.vehicle.setDependentComponentJointBaseFactors ~= nil then
            self.dynamicSuspension.componentJointIndex = xmlFile:getValue(key .. ".dynamicSuspension.componentJoint#index", nil)
            if self.dynamicSuspension.componentJointIndex ~= nil then
                self.dynamicSuspension.componentSpringLoadMultiplier = xmlFile:getValue(key .. ".dynamicSuspension.componentJoint#springLoadMultiplier", 1)
                self.dynamicSuspension.componentDampingLoadMultiplier = xmlFile:getValue(key .. ".dynamicSuspension.componentJoint#dampingLoadMultiplier", 1)
            end
        end
    end
    return true
end
function WheelAxle:update(dt)
    if self.dynamicSuspension ~= nil then
        local physics1 = self.wheel1.physics
        local physics2 = self.wheel2.physics
        local axleLoad = physics1:getTireLoad() + physics2:getTireLoad()
        if axleLoad ~= 0 then
            local springMultiplier = MathUtil.inverseLerp(physics1.restLoad + physics2.restLoad, self.maxLoad or physics1.restLoad * 2 + physics2.restLoad * 2, axleLoad) - self.dynamicSuspension.interpolatedAlpha
            local direction = math.sign(springMultiplier)
            local dampingMultiplier = dynamicSuspension.interpolatedAlpha + direction * dt * dynamicSuspension.interpolationTime
            dynamicSuspension.interpolatedAlpha = math.clamp(dampingMultiplier, 0, 1)
            local dampingMultiplier = dynamicSuspension.interpolatedAlpha - dynamicSuspension.appliedAlpha
            if math.abs(dampingMultiplier) > 0.05 then
                dynamicSuspension.appliedAlpha = dynamicSuspension.interpolatedAlpha
                local springMultiplier = MathUtil.lerp(1, dynamicSuspension.springLoadMultiplier, dynamicSuspension.appliedAlpha)
                local dampingMultiplier = MathUtil.lerp(1, dynamicSuspension.dampingLoadMultiplier, dynamicSuspension.appliedAlpha)
                physics1:setSuspensionMultipliers(springMultiplier, dampingMultiplier)
                physics2:setSuspensionMultipliers(springMultiplier, dampingMultiplier)
                if self.dynamicSuspension.componentJointIndex ~= nil then
                    local componentSpringLoadMultiplier = MathUtil.lerp(1, dynamicSuspension.componentSpringLoadMultiplier, dynamicSuspension.appliedAlpha)
                    local componentDampingLoadMultiplier = MathUtil.lerp(1, dynamicSuspension.componentDampingLoadMultiplier, dynamicSuspension.appliedAlpha)
                    self.vehicle:setDependentComponentJointBaseFactors(dynamicSuspension.componentJointIndex, componentSpringLoadMultiplier, componentDampingLoadMultiplier, true)
                    self.vehicle:updateDependentComponentJointValues(false, true)
                end
            end
        end
    end
end
function WheelAxle.getDebugValueHeader()
    return {
        "w1\n",
        "w2\n",
        "load\n",
        "maxLoad\n",
        "alpha\n",
        "spring\n",
        "damp\n",
        "compJ\n",
        "jSpring\n",
        "jDamp\n"
    }
end
function WheelAxle:fillDebugValues(debugTable)
    local dynamicSuspension = self.dynamicSuspension
    if dynamicSuspension ~= nil then
        debugTable[1] = debugTable[1] .. string.format("%d\n", self.wheel1.wheelIndex)
        debugTable[2] = debugTable[2] .. string.format("%d\n", self.wheel2.wheelIndex)
        debugTable[3] = debugTable[3] .. string.format("%2.2f\n", self.wheel1.physics:getTireLoad() + self.wheel2.physics:getTireLoad())
        debugTable[4] = debugTable[4] .. string.format("%2.2f\n", dynamicSuspension.maxLoad or physics1.restLoad * 2 + physics2.restLoad * 2)
        debugTable[5] = debugTable[5] .. string.format("%.2f\n", dynamicSuspension.appliedAlpha)
        local springMultiplier = MathUtil.lerp(1, dynamicSuspension.springLoadMultiplier, dynamicSuspension.appliedAlpha)
        local dampingMultiplier = MathUtil.lerp(1, dynamicSuspension.dampingLoadMultiplier, dynamicSuspension.appliedAlpha)
        debugTable[6] = debugTable[6] .. string.format("x%.2f\n", springMultiplier)
        debugTable[7] = debugTable[7] .. string.format("x%.2f\n", dampingMultiplier)
        if self.dynamicSuspension.componentJointIndex ~= nil then
            debugTable[8] = debugTable[8] .. string.format("%d\n", self.dynamicSuspension.componentJointIndex)
            local componentSpringMultiplier = MathUtil.lerp(1, dynamicSuspension.componentSpringLoadMultiplier, dynamicSuspension.appliedAlpha)
            local componentDampingMultiplier = MathUtil.lerp(1, dynamicSuspension.componentDampingLoadMultiplier, dynamicSuspension.appliedAlpha)
            debugTable[9] = debugTable[9] .. string.format("x%.2f\n", componentSpringMultiplier)
            debugTable[10] = debugTable[10] .. string.format("x%.2f\n", componentDampingMultiplier)
            return
        end
        debugTable[8] = debugTable[8] .. "n/a\n"
        debugTable[9] = debugTable[9] .. "n/a\n"
        debugTable[10] = debugTable[10] .. "n/a\n"
    end
end
function WheelAxle.registerXMLPaths(schema, key)
    schema:register(XMLValueType.NODE_INDEX, key .. "#wheel1", "First wheel of the axle")
    schema:register(XMLValueType.NODE_INDEX, key .. "#wheel2", "Second wheel of the axle")
    schema:register(XMLValueType.FLOAT, key .. ".dynamicSuspension#springLoadMultiplier", "Multiplier for spring value while maxLoad is applied on the wheels", 1)
    schema:register(XMLValueType.FLOAT, key .. ".dynamicSuspension#dampingLoadMultiplier", "Multiplier for damping value while maxLoad is applied on the wheels", 1)
    schema:register(XMLValueType.FLOAT, key .. ".dynamicSuspension#maxLoad", "Axle load as reference for springLoadMultiplier/dampingLoadMultiplier to adjust the physics behaviour in high load situations", "restLoad of all wheels multiplied by 2")
    schema:register(XMLValueType.TIME, key .. ".dynamicSuspension#interpolationTime", "Interpolation time for tire load", 1)
    schema:register(XMLValueType.INT, key .. ".dynamicSuspension.componentJoint#index", "Index of the axle component joint")
    schema:register(XMLValueType.FLOAT, key .. ".dynamicSuspension.componentJoint#springLoadMultiplier", "Multiplier for component joint spring value while maxLoad is applied on the wheels", 1)
    schema:register(XMLValueType.FLOAT, key .. ".dynamicSuspension.componentJoint#dampingLoadMultiplier", "Multiplier for component joint damping value while maxLoad is applied on the wheels", 1)
end