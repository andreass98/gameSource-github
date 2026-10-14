AutoLoadable = {}
function AutoLoadable.prerequisitesPresent(specializations)
    return true
end
function AutoLoadable.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getAutoLoadIsSupported", AutoLoadable.getAutoLoadIsSupported)
    SpecializationUtil.registerFunction(vehicleType, "getAutoLoadIsAllowed", AutoLoadable.getAutoLoadIsAllowed)
    SpecializationUtil.registerFunction(vehicleType, "getAutoLoadBoundingBox", AutoLoadable.getAutoLoadBoundingBox)
    SpecializationUtil.registerFunction(vehicleType, "getAutoLoadSize", AutoLoadable.getAutoLoadSize)
    SpecializationUtil.registerFunction(vehicleType, "autoLoad", AutoLoadable.autoLoad)
end
function AutoLoadable.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AutoLoadable)
end
function AutoLoadable:onLoad(_)
    if self.isServer then
        self.spec_autoLoadable.isSupported = true
    end
end
function AutoLoadable:getAutoLoadIsSupported()
    return self.spec_autoLoadable.isSupported
end
function AutoLoadable:getAutoLoadIsAllowed()
    return true
end
function AutoLoadable:getAutoLoadSize()
    local size = self.size
    return size.width, size.height, size.length
end
function AutoLoadable:getAutoLoadBoundingBox()
    local size = self.size
    local x, y, z = localToWorld(self.rootNode, size.widthOffset, size.heightOffset, size.lengthOffset)
    local dirX, dirY, dirZ = localDirectionToWorld(self.rootNode, 0, 0, 1)
    local upX, upY, upZ = localDirectionToWorld(self.rootNode, 0, 1, 0)
    return x, y, z, dirX, dirY, dirZ, upX, upY, upZ, size.width * 0.5, size.height * 0.5, size.length * 0.5
end
function AutoLoadable:autoLoad(autoLoader, node, posX, posZ, _, _)
    local size = self.size
    self:mountKinematic(autoLoader, node, posX + size.widthOffset + size.width * 0.5, size.heightOffset, posZ + size.lengthOffset + size.height * 0.5, 0, 0, 0)
    return true
end