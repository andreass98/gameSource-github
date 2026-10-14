WheelChock = {}
local WheelChock_mt = Class(WheelChock)
function WheelChock.new(wheel, customMt)
    -- upvalues: (copy) WheelChock_mt
    local self = setmetatable({}, customMt or WheelChock_mt)
    self.wheel = wheel
    self.isInParkingPosition = false
    self.wheelRadiusOffset = 0
    return self
end
function WheelChock:delete()
    if self.node ~= nil then
        delete(self.node)
        self.node = nil
    end
    if self.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
        self.sharedLoadRequestId = nil
    end
end
function WheelChock:loadFromXML(xmlObject, key)
    local vehicle = self.wheel.vehicle
    self.filename = xmlObject:getValue(key .. "#filename", "$data/shared/assets/wheelChocks/wheelChock01.i3d")
    self.filename = Utils.getFilename(self.filename, self.wheel.baseDirectory)
    if self.filename == nil then
        xmlObject:xmlWarning(key .. "#filename", "Invalid filename given for wheel chock")
        return false
    end
    self.parkingNode = xmlObject:getValue(key .. "#parkingNode", nil, vehicle.components, vehicle.i3dMappings)
    self.scale = xmlObject:getValue(key .. "#scale", "1 1 1", true)
    self.isInverted = xmlObject:getValue(key .. "#isInverted", false)
    self.isParked = xmlObject:getValue(key .. "#isParked", false)
    self.offset = xmlObject:getValue(key .. "#offset", "0 0 0", true)
    local material = VehicleMaterial.new(self.wheel.baseDirectory)
    if material:loadFromXML(xmlObject, key, self.wheel.vehicle.customEnvironment) then
        self.material = material
    end
    vehicle:onLoadWheelChockFromXML(self, xmlObject, key)
    self.sharedLoadRequestId = vehicle:loadSubSharedI3DFile(self.filename, false, false, self.onI3DLoaded, self)
    return true
end
function WheelChock:onI3DLoaded(i3dNode, _, _)
    if i3dNode ~= 0 then
        self.node = getChildAt(i3dNode, 0)
        local posRefNode = I3DUtil.indexToObject(self.node, getUserAttribute(self.node, "posRefNode"))
        if posRefNode == nil then
            Logging.warning("Missing \'posRefNode\'-userattribute for wheel-chock \'%s\'!", self.filename)
        else
            _, self.height, self.zOffset = localToLocal(posRefNode, self.node, 0, 0, 0)
            self.height = self.height * self.scale[2]
            self.zOffset = self.zOffset * self.scale[3]
            setScale(self.node, self.scale[1], self.scale[2], self.scale[3])
            self.parkedNode = I3DUtil.indexToObject(self.node, getUserAttribute(self.node, "parkedNode"))
            self.linkedNode = I3DUtil.indexToObject(self.node, getUserAttribute(self.node, "linkedNode"))
            if self.material ~= nil then
                self.material:apply(self.node, "wheelChock_main_mat")
            end
            self:update(self.isParked)
        end
        delete(i3dNode)
    end
end
function WheelChock:update(isInParkingPosition)
    if self.node ~= nil then
        if isInParkingPosition == nil then
            isInParkingPosition = self.isInParkingPosition
        end
        isInParkingPosition = not self.wheel.vehicle:getIsWheelChockAllowed(self) and true or isInParkingPosition
        self.isInParkingPosition = isInParkingPosition
        if isInParkingPosition then
            if self.parkingNode == nil then
                setVisibility(self.node, false)
            else
                setTranslation(self.node, 0, 0, 0)
                setRotation(self.node, 0, 0, 0)
                link(self.parkingNode, self.node)
                setVisibility(self.node, true)
            end
        else
            setVisibility(self.node, true)
            setScale(self.node, 1, 1, 1)
            local wheel = self.wheel
            local zWheelIntersection = math.max(wheel.physics.radius - self.wheelRadiusOffset - self.height, 0.01) / wheel.physics.radius
            local zChockOffset = -(wheel.physics.radius * math.sin((math.acos(zWheelIntersection)))) - self.zOffset
            link(wheel.node, self.node)
            local _, yRot, _ = localRotationToLocal(getParent(wheel.repr), wheel.node, getRotation(wheel.repr))
            if self.isInverted then
            end
            setRotation(self.node, 0, yRot, 0)
            local dirX, dirY, dirZ = localDirectionToLocal(self.node, wheel.node, 0, 0, 1)
            local normX, normY, normZ = localDirectionToLocal(self.node, wheel.node, 1, 0, 0)
            local posX, posY, posZ = localToLocal(wheel.driveNode, wheel.node, 0, 0, 0)
            setTranslation(self.node, posX + normX * self.offset[1] + dirX * (zChockOffset + self.offset[3]), posY + normY * self.offset[1] + dirY * (zChockOffset + self.offset[3]) - wheel.physics.radius + self.wheelRadiusOffset + self.offset[2], posZ + normZ * self.offset[1] + dirZ * (zChockOffset + self.offset[3]))
            setScale(self.node, self.scale[1], self.scale[2], self.scale[3])
        end
        if self.parkedNode ~= nil then
            setVisibility(self.parkedNode, isInParkingPosition)
        end
        if self.linkedNode ~= nil then
            setVisibility(self.linkedNode, not isInParkingPosition)
        end
        return true
    end
end
function WheelChock.registerXMLPaths(schema, key)
    schema:addDelayedRegistrationPath(key, "WheelChock")
    schema:register(XMLValueType.STRING, key .. "#filename", "Path to wheel chock i3d", "$data/shared/assets/wheelChocks/wheelChock01.i3d")
    schema:register(XMLValueType.VECTOR_SCALE, key .. "#scale", "Scale", "1 1 1")
    schema:register(XMLValueType.NODE_INDEX, key .. "#parkingNode", "Parking node")
    schema:register(XMLValueType.BOOL, key .. "#isInverted", "Is inverted (In front or back of the wheel)", false)
    schema:register(XMLValueType.BOOL, key .. "#isParked", "Default is parked", false)
    schema:register(XMLValueType.VECTOR_TRANS, key .. "#offset", "Translation offset", "0 0 0")
    VehicleMaterial.registerXMLPaths(schema, key)
end