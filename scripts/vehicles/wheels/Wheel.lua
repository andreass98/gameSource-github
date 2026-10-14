Wheel = {}
Wheel.VISUAL_WHEEL_UPDATE_DISTANCE = 300
Wheel.STEERING_ANGLE_THRESHOLD = 0.00034
Wheel.SUSPENSION_THRESHOLD = 0.001
source("dataS/scripts/vehicles/wheels/WheelXMLObject.lua")
source("dataS/scripts/vehicles/wheels/WheelPhysics.lua")
source("dataS/scripts/vehicles/wheels/WheelDestruction.lua")
source("dataS/scripts/vehicles/wheels/WheelEffects.lua")
source("dataS/scripts/vehicles/wheels/WheelSteering.lua")
source("dataS/scripts/vehicles/wheels/WheelVisual.lua")
source("dataS/scripts/vehicles/wheels/WheelDebug.lua")
source("dataS/scripts/vehicles/wheels/WheelChock.lua")
local Wheel_mt = Class(Wheel)
function Wheel.new(vehicle, xmlFile, baseKey, wheelKey, wheelIndex, configIndex, indexToParentIndex, baseDirectory, customMt)
    -- upvalues: (copy) Wheel_mt
    local self = setmetatable({}, customMt or Wheel_mt)
    self.vehicle = vehicle
    self.xmlFile = xmlFile
    self.xmlObject = WheelXMLObject.new(xmlFile, baseKey, configIndex, wheelKey, indexToParentIndex)
    self.baseDirectory = baseDirectory
    self.name = nil
    self.wheelIndex = wheelIndex
    self.updateIndex = (wheelIndex - 1) % 4 + 1
    self.brakePedal = 0
    self.syncContactState = false
    self.lastSteeringAngle = 0
    self.lastXDrive = 0
    self.lastSuspensionLength = 0
    self.additionalMass = 0
    self.physics = WheelPhysics.new(self)
    self.steering = WheelSteering.new(self)
    self.destruction = WheelDestruction.new(self)
    self.effects = WheelEffects.new(self)
    self.debug = WheelDebug.new(self)
    return self
end
function Wheel:loadFromXML()
    self.repr = self.xmlObject:getValue(".physics#repr", nil, self.vehicle.components, self.vehicle.i3dMappings)
    if self.repr == nil then
        self.xmlObject:xmlWarning(".physics#repr", "Failed to load wheel! Missing repr node.")
        return false
    end
    if not self.vehicle:getIsNodeActive(self.repr) then
        return false
    end
    self.isLeft = self.xmlObject:getValue("#isLeft", true)
    self.rimOffset = self.xmlObject:getValue("#rimOffset", 0)
    self.node = self.vehicle:getParentComponent(self.repr)
    if self.node == 0 then
        self.xmlObject:xmlWarning("", "Invalid repr for wheel. Needs to be a child of a collision!")
        return false
    end
    self.driveNode = self.xmlObject:getValue(".physics#driveNode", nil, self.vehicle.components, self.vehicle.i3dMappings)
    if self.driveNode == self.repr then
        self.xmlObject:xmlWarning("", "repr and driveNode may not be equal. Using default driveNode instead!")
        self.driveNode = nil
    end
    self.linkNode = self.xmlObject:getValue(".physics#linkNode", nil, self.vehicle.components, self.vehicle.i3dMappings)
    if self.driveNode == nil then
        local newRepr = createTransformGroup("wheelReprNode")
        local reprIndex = getChildIndex(self.repr)
        link(getParent(self.repr), newRepr, reprIndex)
        setTranslation(newRepr, getTranslation(self.repr))
        setRotation(newRepr, getRotation(self.repr))
        setScale(newRepr, getScale(self.repr))
        self.driveNode = self.repr
        link(newRepr, self.driveNode)
        setTranslation(self.driveNode, 0, 0, 0)
        setRotation(self.driveNode, 0, 0, 0)
        setScale(self.driveNode, 1, 1, 1)
        self.repr = newRepr
    end
    if self.driveNode ~= nil then
        local newRepr = createTransformGroup("driveNodeDirectionNode")
        link(self.repr, newRepr)
        setWorldTranslation(newRepr, getWorldTranslation(self.driveNode))
        setWorldRotation(newRepr, getWorldRotation(self.driveNode))
        self.driveNodeDirectionNode = newRepr
        local reprIndex, defaultY, defaultZ = getRotation(self.driveNode)
        if math.abs(reprIndex) > 0.0001 or (math.abs(defaultY) > 0.0001 or math.abs(defaultZ) > 0.0001) then
            self.xmlObject:xmlWarning("", "Rotation of driveNode \'%s\' is not 0/0/0 in the i3d file (%.1f/%.1f/%.1f).", getName(self.driveNode), math.deg(reprIndex), math.deg(defaultY), (math.deg(defaultZ)))
        end
    end
    if self.linkNode == nil then
        self.linkNode = self.driveNode
    end
    self.transRatio = self.xmlObject:getValue(".physics#transRatio", 0)
    if not self.physics:loadFromXML(self.xmlObject) then
        return false
    end
    if not self.steering:loadFromXML(self.xmlObject) then
        return false
    end
    if not self.destruction:loadFromXML(self.xmlObject) then
        return false
    end
    if not self.effects:loadFromXML(self.xmlObject) then
        return false
    end
    local newRepr, reprIndex, defaultY = getTranslation(self.repr)
    self.startPositionX = newRepr
    self.startPositionY = reprIndex
    self.startPositionZ = defaultY
    local newRepr, reprIndex, defaultY = getTranslation(self.driveNode)
    self.driveNodeStartPosX = newRepr
    self.driveNodeStartPosY = reprIndex
    self.driveNodeStartPosZ = defaultY
    self.xmlObject:checkDeprecatedXMLElements(".tire#widthOffset", ".tire#offset")
    self.xmlObject:checkDeprecatedXMLElements("#color", "#material")
    self.xmlObject:checkDeprecatedXMLElements("#additionalColor", "#additionalMaterial")
    self.material = self.xmlObject:getValue("#material")
    self.additionalMaterial = self.xmlObject:getValue("#additionalMaterial")
    self.wheelChocks = {}
    local newRepr = 0
    while true do
        local reprIndex = string.format(".wheelChock(%d)", newRepr)
        local defaultY, defaultZ = self.xmlObject:getXMLFileAndPropertyKey(reprIndex)
        if defaultY == nil then
            break
        end
        local wheelChock = WheelChock.new(self)
        if wheelChock:loadFromXML(self.xmlObject, reprIndex) then
            table.insert(self.wheelChocks, wheelChock)
        end
        newRepr = newRepr + 1
    end
    self.visualWheels = {}
    local reprIndex = WheelVisual.new(self.vehicle, self, self.linkNode, self.isLeft, self.rimOffset, self.baseDirectory)
    if reprIndex:loadFromXML(self.xmlObject) then
        self.additionalMass = self.additionalMass + reprIndex:getAdditionalMass()
        table.insert(self.visualWheels, reprIndex)
    else
        reprIndex:delete()
    end
    local defaultY = self.xmlObject:getValue("#filename")
    self.name = self.name or self.xmlObject.externalWheelName
    local newRepr = 0
    while true do
        local defaultZ = string.format(".additionalWheel(%d)", newRepr)
        self.xmlObject:setXMLLoadKey("")
        local wheelChock, _ = self.xmlObject:getXMLFileAndPropertyKey(defaultZ)
        if wheelChock == nil then
            break
        end
        self.xmlObject:setXMLLoadKey(defaultZ, defaultY)
        local isLeft = self.xmlObject:getValue("#isLeft", self.isLeft)
        local lastVisualWheel = WheelVisual.new(self.vehicle, self, self.linkNode, isLeft, 0, self.baseDirectory)
        if lastVisualWheel:loadFromXML(self.xmlObject) then
            self.additionalMass = self.additionalMass + lastVisualWheel:getAdditionalMass()
            local lastVisualWheel = self.visualWheels[#self.visualWheels]
            if lastVisualWheel ~= nil then
                lastVisualWheel:setConnectedWheel(lastVisualWheel, self.rimOffset + self.xmlObject:getValue("#offset", 0))
            end
            self.physics:loadAdditionalWheel(self.xmlObject)
            table.insert(self.visualWheels, lastVisualWheel)
        else
            lastVisualWheel:delete()
        end
        newRepr = newRepr + 1
    end
    return true
end
function Wheel:finalize()
    local minX = math.huge
    local maxX = -math.huge
    for _, visualWheel in ipairs(self.visualWheels) do
        local width, offset = visualWheel:getWidthAndOffset()
        minX = math.min(minX, offset - width * 0.5)
        maxX = math.max(maxX, offset + width * 0.5)
    end
    if minX ~= math.huge then
        local shapeWidth = maxX - minX
        self.physics:setWheelShapeWidth(shapeWidth, minX + shapeWidth * 0.5)
    end
    self.physics:finalize()
    self.destruction:finalize()
    self.effects:finalize()
    if self.xmlObject ~= nil then
        self.xmlObject:delete()
        self.xmlObject = nil
    end
end
function Wheel:postLoad()
    for _, visualWheel in ipairs(self.visualWheels) do
        visualWheel:postLoad()
    end
    self.physics:postLoad()
    self.effects:postLoad()
end
function Wheel:delete()
    for _, visualWheel in ipairs(self.visualWheels) do
        visualWheel:delete()
    end
    for _, visualWheel in ipairs(self.wheelChocks) do
        visualWheel:delete()
    end
    self.effects:delete()
    self.debug:delete()
    if self.xmlObject ~= nil then
        self.xmlObject:delete()
        self.xmlObject = nil
    end
end
function Wheel:readStream(streamId, updateInterpolation)
    self.physics:readStream(streamId, updateInterpolation)
end
function Wheel:writeStream(streamId)
    self.physics:writeStream(streamId)
end
function Wheel:update(dt, currentUpdateIndex, groundWetness, force)
    if self.vehicle.isServer then
        if self.vehicle.isAddedToPhysics then
            self.physics:serverUpdate(dt, currentUpdateIndex, groundWetness)
        end
    else
        self.physics:clientUpdate(dt, currentUpdateIndex, groundWetness)
    end
    if self.vehicle.currentUpdateDistance < Wheel.VISUAL_WHEEL_UPDATE_DISTANCE or force then
        local x, y, z, xDrive, suspensionLength, steeringAngle = self.physics:getVisualInfo()
        local changed = false
        local wheelRadiusOffset = steeringAngle - self.lastSteeringAngle
        if math.abs(wheelRadiusOffset) > Wheel.STEERING_ANGLE_THRESHOLD then
            setRotation(self.repr, 0, steeringAngle, 0)
            self.lastSteeringAngle = steeringAngle
            changed = true
        end
        local wheelRadiusOffset = xDrive - self.lastXDrive
        if math.abs(wheelRadiusOffset) > Wheel.STEERING_ANGLE_THRESHOLD then
            setRotation(self.driveNode, xDrive, 0, 0)
            self.lastXDrive = xDrive
            changed = true
        end
        for _, visualWheel in ipairs(self.visualWheels) do
            changed, suspensionLength = visualWheel:update(x, y, z, xDrive, suspensionLength, steeringAngle, changed)
        end
        local wheelRadiusOffset = suspensionLength - suspensionLength
        local dirY = self.lastSuspensionLength - suspensionLength
        if math.abs(dirY) > Wheel.SUSPENSION_THRESHOLD then
            local dirX, dirY, _ = localDirectionToLocal(self.repr, getParent(self.repr), 0, -1, 0)
            local visualWheel = suspensionLength * self.transRatio
            setTranslation(self.repr, self.startPositionX + dirX * visualWheel, self.startPositionY + dirY * visualWheel, self.startPositionZ + _ * visualWheel)
            if self.transRatio < 1 then
                local visualWheel = suspensionLength * (1 - self.transRatio)
                setTranslation(self.driveNode, self.driveNodeStartPosX + dirX * visualWheel, self.driveNodeStartPosY + dirY * visualWheel, self.driveNodeStartPosZ + _ * visualWheel)
            end
            self.lastSuspensionLength = suspensionLength
            changed = true
        end
        self.steering:update(x, y, z, xDrive, suspensionLength, steeringAngle, changed)
        if changed then
            for visualWheel, wheelChock in ipairs(self.wheelChocks) do
                if not wheelChock.isInParkingPosition then
                    wheelChock.wheelRadiusOffset = wheelRadiusOffset
                    wheelChock:update()
                end
            end
        end
        self.effects:update(dt, groundWetness, currentUpdateIndex)
    end
end
function Wheel:updateInterpolation(dt, interpolationAlpha)
    self.physics:updateInterpolation(dt, interpolationAlpha)
end
function Wheel:updateTick(dt, groundWetness, currentUpdateDistance)
    self.physics:updateTick(dt, groundWetness, currentUpdateDistance)
    self.effects:updateTick(dt, groundWetness, currentUpdateDistance)
end
function Wheel:postUpdate(dt)
    self.physics:postUpdate(dt)
end
function Wheel:onUpdateEnd(dt)
    self.effects:onUpdateEnd(dt)
end
function Wheel:onPreAttach()
    for _, wheelChock in ipairs(self.wheelChocks) do
        wheelChock:update(true)
    end
end
function Wheel:onPostDetach()
    for _, wheelChock in ipairs(self.wheelChocks) do
        wheelChock:update(false)
    end
end
function Wheel:addToPhysics(brakeForce)
    self.physics:addToPhysics(brakeForce)
end
function Wheel:updatePhysics(brakeForce)
    self.physics:updatePhysics(brakeForce)
end
function Wheel:removeFromPhysics()
    self.physics:removeFromPhysics()
end
function Wheel:getMass()
    return self.physics.mass + self.additionalMass
end
function Wheel:setSteeringValues(rotMin, rotMax, rotSpeed, rotSpeedNeg, inverted)
    self.physics:setSteeringValues(rotMin, rotMax, rotSpeed, rotSpeedNeg, inverted)
    self.steering:setSteeringValues(rotMin, rotMax, rotSpeed, rotSpeedNeg, inverted)
end
function Wheel:setBrakePedal(brakePedal)
    self.brakePedal = brakePedal
    self.physics:updatePhysics(self.vehicle:getBrakeForce() * self.brakePedal)
end
function Wheel:setIsCareWheel(isCareWheel)
    self.destruction:setIsCareWheel(isCareWheel)
end
function Wheel:getFirstTireNode()
    for _, visualWheel in ipairs(self.visualWheels) do
        local tireNode = visualWheel:getTireNode()
        if tireNode ~= nil then
            return tireNode
        end
    end
    return nil
end
function Wheel.registerXMLPaths(schema, key)
    schema:register(XMLValueType.NODE_INDEX, key .. ".physics#repr", "Repr node")
    schema:register(XMLValueType.NODE_INDEX, key .. ".physics#driveNode", "Drive node")
    schema:register(XMLValueType.NODE_INDEX, key .. ".physics#linkNode", "Link node")
    schema:register(XMLValueType.FLOAT, key .. ".physics#transRatio", "Suspension translation ratio between repr and drive node (1: repr only, 0: drive node only)", 0)
    schema:register(XMLValueType.INT, key .. "#material", "Wheel material id")
    schema:register(XMLValueType.INT, key .. "#additionalMaterial", "Additional wheel material id")
    schema:register(XMLValueType.BOOL, key .. "#isLeft", "Is left", true)
    schema:register(XMLValueType.FLOAT, key .. "#rimOffset", "Offset that is only applied to the outer rim and the wheel itself, inner rim stays the same.", 0)
    schema:register(XMLValueType.STRING, key .. "#filename", "Filename")
    schema:registerAutoCompletionDataSource(key .. "#filename", "data/shared/wheels/wheels.xml", "wheels.wheel#filename")
    schema:register(XMLValueType.STRING, key .. "#dimensions", "List of dimensions for automatic branded wheel configuration generation")
    schema:register(XMLValueType.STRING, key .. "#configId", "Wheel config id", "default")
    WheelPhysics.registerXMLPaths(schema, key)
    WheelSteering.registerXMLPaths(schema, key)
    WheelDestruction.registerXMLPaths(schema, key)
    WheelEffects.registerXMLPaths(schema, key)
    WheelVisual.registerXMLPaths(schema, key)
    local additionalWheelKey = key .. ".additionalWheel(?)"
    schema:register(XMLValueType.STRING, additionalWheelKey .. "#filename", "Filename")
    schema:registerAutoCompletionDataSource(additionalWheelKey .. "#filename", "data/shared/wheels/wheels.xml", "wheels.wheel#filename")
    schema:register(XMLValueType.BOOL, additionalWheelKey .. "#isLeft", "Is left", "Same value as parent wheel")
    schema:register(XMLValueType.STRING, additionalWheelKey .. "#configId", "Wheel config id", "default")
    schema:register(XMLValueType.FLOAT, additionalWheelKey .. "#offset", "X Offset of additional wheel")
    WheelVisual.registerXMLPaths(schema, additionalWheelKey)
    WheelPhysics.registerAdditionalWheelXMLPaths(schema, additionalWheelKey)
    WheelChock.registerXMLPaths(schema, key .. ".wheelChock(?)")
end