HeadlandAnimation = {}
function HeadlandAnimation.prerequisitesPresent(specializations)
    return true
end
function HeadlandAnimation.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("HeadlandAnimation")
    schema:register(XMLValueType.TIME, "vehicle.headlandAnimation#activationDelay", "Headland is activated after this time above activationAngle", 0.5)
    schema:register(XMLValueType.TIME, "vehicle.headlandAnimation#deactivationDelay", "Headland is deactivated after this time below deactivationAngle", 4)
    schema:register(XMLValueType.FLOAT, "vehicle.headlandAnimation#activationAngle", "Headland is activated above this steering percentage [0-1]", 0.2)
    schema:register(XMLValueType.FLOAT, "vehicle.headlandAnimation#deactivationAngle", "Headland is deactivated below this steering percentage [0-1]", 0.13)
    schema:register(XMLValueType.STRING, "vehicle.headlandAnimation#requiredGroundTypes", "Headland is only activated one of these ground types is below vehicle")
    schema:register(XMLValueType.STRING, "vehicle.headlandAnimation.animation(?)#name", "Animation name")
    schema:register(XMLValueType.FLOAT, "vehicle.headlandAnimation.animation(?)#speed", "Animation speed")
    schema:setXMLSpecializationType()
end
function HeadlandAnimation.registerFunctions(vehicleType) end
function HeadlandAnimation.registerOverwrittenFunctions(vehicleType) end
function HeadlandAnimation.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", HeadlandAnimation)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", HeadlandAnimation)
end
function HeadlandAnimation:onLoad(_)
    local spec = self.spec_headlandAnimation
    spec.isAvailable = self.xmlFile:hasProperty("vehicle.headlandAnimation")
    if spec.isAvailable then
        spec.headlandActivationDelay = self.xmlFile:getValue("vehicle.headlandAnimation#activationDelay", 0.5)
        spec.headlandDeactivationDelay = self.xmlFile:getValue("vehicle.headlandAnimation#deactivationDelay", 4)
        spec.headlandActivationAngle = self.xmlFile:getValue("vehicle.headlandAnimation#activationAngle", 0.2)
        spec.headlandDeactivationAngle = self.xmlFile:getValue("vehicle.headlandAnimation#deactivationAngle", 0.13)
        local i = self.xmlFile:getValue("vehicle.headlandAnimation#requiredGroundTypes"):split(" ")
        spec.requiredGroundTypes = {}
        local i = 1
        local i = #i
        local baseKey = 1
        for i = i, i, baseKey do
            local name = i[i]
            if name ~= nil and name ~= "" then
                local groundType = FieldGroundType[name]
                if groundType == nil then
                    Logging.xmlWarning(self.xmlFile, "Unknown ground type \'%s\' defined for headland animation", name)
                else
                    spec.requiredGroundTypes[groundType] = true
                end
            end
        end
        spec.headlandDeactivationTime = 0
        spec.headlandState = false
        spec.lastHeadlandState = false
        spec.animations = {}
        local i = 0
        while true do
            local baseKey = string.format("vehicle.headlandAnimation.animation(%d)", i)
            if not self.xmlFile:hasProperty(baseKey) then
                break
            end
            local i = {
                ["name"] = self.xmlFile:getValue(baseKey .. "#name"),
                ["speed"] = self.xmlFile:getValue(baseKey .. "#speed")
            }
            if i.name ~= nil then
                table.insert(spec.animations, i)
            end
            i = i + 1
        end
    else
        SpecializationUtil.removeEventListener(self, "onUpdate", HeadlandAnimation)
    end
end
function HeadlandAnimation:onUpdate(dt, _, _, _)
    local spec = self.spec_headlandAnimation
    local validGround = true
    if spec.headlandRequiredDensityBits ~= 0 then
        local x, y, z = getWorldTranslation(self.components[1].node)
        local _, _, groundType = FSDensityMapUtil.getFieldDataAtWorldPosition(x, y, z)
        if spec.requiredGroundTypes[groundType] ~= true then
            validGround = false
        end
    end
    if validGround then
        local y = self.rotatedTime
        if math.abs(y) > spec.headlandActivationAngle then
            spec.headlandDeactivationTime = spec.headlandDeactivationTime + dt
            if spec.headlandDeactivationTime > spec.headlandActivationDelay then
                spec.headlandState = true
                spec.headlandDeactivationTime = spec.headlandDeactivationDelay
            end
            ::l8::
            if spec.headlandDeactivationTime == 0 then
                spec.headlandState = false
            end
            if spec.headlandState ~= spec.lastHeadlandState then
                for _ = 1, #spec.animations do
                    local _ = spec.animations[_]
                    self:playAnimation(_.name, _.speed * (spec.headlandState and 1 or -1), self:getAnimationTime(_.name))
                end
                spec.lastHeadlandState = spec.headlandState
            end
            return
        end
    end
    local y = self.rotatedTime
    if math.abs(y) < spec.headlandDeactivationAngle then
        spec.headlandDeactivationTime = math.max(spec.headlandDeactivationTime - dt, 0)
    end
    goto l8
end