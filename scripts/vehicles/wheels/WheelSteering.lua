WheelSteering = {}
function WheelSteering.new(wheel)
    local self = setmetatable({}, {
        ["__index"] = WheelSteering
    })
    self.wheel = wheel
    self.vehicle = wheel.vehicle
    self.steeringNodeMaxRot = 1
    self.steeringNodeMinRot = -1
    return self
end
function WheelSteering:loadFromXML(xmlObject)
    self.steeringNode = xmlObject:getValue(".steering#node", nil, self.vehicle.components, self.vehicle.i3dMappings)
    self.steeringRotNode = xmlObject:getValue(".steering#rotNode", nil, self.vehicle.components, self.vehicle.i3dMappings)
    self.steeringNodeMinTransX = xmlObject:getValue(".steering#nodeMinTransX")
    self.steeringNodeMaxTransX = xmlObject:getValue(".steering#nodeMaxTransX")
    self.steeringNodeMinRotY = xmlObject:getValue(".steering#nodeMinRotY")
    self.steeringNodeMaxRotY = xmlObject:getValue(".steering#nodeMaxRotY")
    self.fenders = {}
    local i = 0
    while true do
        local fenderKey = string.format(".fender(%d)", i)
        local xmlFile, _ = xmlObject:getXMLFileAndPropertyKey(fenderKey)
        if xmlFile == nil then
            break
        end
        local entry = {
            ["node"] = xmlObject:getValue(fenderKey .. "#node", nil, self.vehicle.components, self.vehicle.i3dMappings)
        }
        if entry.node ~= nil then
            entry.rotMax = xmlObject:getValue(fenderKey .. "#rotMax")
            entry.rotMin = xmlObject:getValue(fenderKey .. "#rotMin")
            table.insert(self.fenders, entry)
        end
        i = i + 1
    end
    self.steeringAxleScale = xmlObject:getValue(".steeringAxle#scale", 0)
    self.steeringAxleRotMax = xmlObject:getValue(".steeringAxle#rotMax", 0)
    self.steeringAxleRotMin = xmlObject:getValue(".steeringAxle#rotMin", -0)
    return true
end
function WheelSteering:setSteeringValues(rotMin, rotMax, _, _, inverted)
    if self.steeringAxleScale ~= 0 then
        if inverted then
            self.steeringAxleScale = -self.steeringAxleScale
        end
        self.steeringAxleRotMax = rotMax
        self.steeringAxleRotMin = rotMin
    end
    local i = 1
    for i = i, #self.fenders do
        local fender = self.fenders[i]
        fender.rotMax = fender.rotMax or rotMax
        fender.rotMin = fender.rotMin or rotMin
    end
    local i = self.steeringAxleRotMax
    self.steeringNodeMaxRot = math.max(rotMax, i)
    local i = self.steeringAxleRotMin
    self.steeringNodeMinRot = math.min(rotMin, i)
end
function WheelSteering:update(_, _, _, _, _, steeringAngle, _)
    if self.steeringNode ~= nil then
        local refAngle = self.steeringNodeMaxRot
        local refTrans = self.steeringNodeMaxTransX
        local refRot = self.steeringNodeMaxRotY
        if steeringAngle < 0 then
            refAngle = self.steeringNodeMinRot
            refTrans = self.steeringNodeMinTransX
            refRot = self.steeringNodeMinRotY
        end
        local steeringValue = 0
        if refAngle ~= 0 then
            steeringValue = steeringAngle / refAngle
        end
        if self.steeringNodeMinTransX ~= nil then
            local _, sny, snz = getTranslation(self.steeringNode)
            setTranslation(self.steeringNode, refTrans * steeringValue, sny, snz)
        end
        if self.steeringNodeMinRotY ~= nil then
            local _, sny, snz = getRotation(self.steeringRotNode or self.steeringNode)
            setRotation(self.steeringRotNode or self.steeringNode, _, refRot * steeringValue, snz)
        end
    end
    local refRot = 1
    local refAngle = #self.fenders
    local refTrans = 1
    for refRot = refRot, refAngle, refTrans do
        local steeringValue = self.fenders[refRot]
        local _ = 0
        if steeringValue.rotMax < steeringAngle then
            _ = steeringValue.rotMax - steeringAngle
        elseif steeringAngle < steeringValue.rotMin then
            _ = steeringValue.rotMin - steeringAngle
        end
        setRotation(steeringValue.node, 0, _, 0)
    end
end
function WheelSteering.registerXMLPaths(schema, key)
    schema:register(XMLValueType.NODE_INDEX, key .. ".steering#node", "Steering node")
    schema:register(XMLValueType.NODE_INDEX, key .. ".steering#rotNode", "Steering rot node")
    schema:register(XMLValueType.FLOAT, key .. ".steering#nodeMinTransX", "Min. X translation")
    schema:register(XMLValueType.FLOAT, key .. ".steering#nodeMaxTransX", "Max. X translation")
    schema:register(XMLValueType.ANGLE, key .. ".steering#nodeMinRotY", "Min. Y rotation")
    schema:register(XMLValueType.ANGLE, key .. ".steering#nodeMaxRotY", "Max. Y rotation")
    schema:register(XMLValueType.NODE_INDEX, key .. ".fender(?)#node", "Fender node")
    schema:register(XMLValueType.ANGLE, key .. ".fender(?)#rotMax", "Max. rotation")
    schema:register(XMLValueType.ANGLE, key .. ".fender(?)#rotMin", "Min. rotation")
    schema:register(XMLValueType.FLOAT, key .. ".steeringAxle#scale", "Steering axle scale")
    schema:register(XMLValueType.ANGLE, key .. ".steeringAxle#rotMax", "Max. rotation")
    schema:register(XMLValueType.ANGLE, key .. ".steeringAxle#rotMin", "Min. rotation")
end