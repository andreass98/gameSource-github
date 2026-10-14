ManureBarrel = {}
function ManureBarrel.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Sprayer, specializations) and SpecializationUtil.hasSpecialization(AttacherJoints, specializations)
end
function ManureBarrel.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("ManureBarrel")
    schema:register(XMLValueType.INT, "vehicle.manureBarrel#attacherJointIndex", "Attacher joint index")
    schema:setXMLSpecializationType()
end
function ManureBarrel.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreEffectsVisible", ManureBarrel.getAreEffectsVisible)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", ManureBarrel.getIsWorkAreaActive)
end
function ManureBarrel.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", ManureBarrel)
    SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", ManureBarrel)
    SpecializationUtil.registerEventListener(vehicleType, "onPostDetachImplement", ManureBarrel)
end
function ManureBarrel:onLoad(_)
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.manureBarrel#toolAttachAnimName", "vehicle.attacherJoints.attacherJoint.objectChange")
    self.spec_manureBarrel.attachToolJointIndex = self.xmlFile:getValue("vehicle.manureBarrel#attacherJointIndex")
end
function ManureBarrel:onPostAttachImplement(attachable, _, jointDescIndex, _)
    local spec = self.spec_manureBarrel
    if jointDescIndex == spec.attachToolJointIndex then
        spec.attachedTool = attachable
    end
end
function ManureBarrel:onPostDetachImplement(implementIndex)
    local spec = self.spec_manureBarrel
    local object = nil
    if self.getObjectFromImplementIndex ~= nil then
        object = self:getObjectFromImplementIndex(implementIndex)
    end
    if object ~= nil and self:getAttachedImplements()[implementIndex].jointDescIndex == spec.attachToolJointIndex then
        spec.attachedTool = nil
    end
end
function ManureBarrel:getAreEffectsVisible(superFunc)
    if self.spec_manureBarrel.attachedTool == nil then
        return superFunc(self)
    else
        return false
    end
end
function ManureBarrel:getIsWorkAreaActive(superFunc, workArea)
    if self.spec_manureBarrel.attachedTool == nil then
        return superFunc(self, workArea)
    else
        return false
    end
end