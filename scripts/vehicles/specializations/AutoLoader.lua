AutoLoader = {}
function AutoLoader.prerequisitesPresent(specializations)
    return true
end
function AutoLoader.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("AutoLoader")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.autoLoader.areas.area(?)#node", "Area root node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.autoLoader.areas.area(?).trigger(?)#node", "Trigger node")
    schema:register(XMLValueType.BOOL, "vehicle.autoLoader.areas.area(?).trigger(?)#alwaysActive", "Sets a trigger always active")
    schema:register(XMLValueType.FLOAT, "vehicle.autoLoader.areas.area(?)#length", "Area length")
    schema:register(XMLValueType.FLOAT, "vehicle.autoLoader.areas.area(?)#width", "Area width")
    schema:register(XMLValueType.FLOAT, "vehicle.autoLoader.areas.area(?)#height", "Area height (only used for collision checks)")
    schema:register(XMLValueType.FLOAT, "vehicle.autoLoader.areas.area(?)#spacing", "Area spacing")
    schema:setXMLSpecializationType()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).autoLoader.mountedObject(?)#mountPosX", "Mount position x")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).autoLoader.mountedObject(?)#mountPosZ", "Mount position z")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).autoLoader.mountedObject(?)#mountSizeX", "Mount size x")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).autoLoader.mountedObject(?)#mountSizeZ", "Mount size z")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).autoLoader.mountedObject(?)#mountAreaIndex", "Mount area index")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).autoLoader.mountedObject(?)#vehicleUniqueId", "Vehicle unique id")
    Bale.registerSavegameXMLPaths(schemaSavegame, "vehicles.vehicle(?).autoLoader.mountedObject(?).bale")
end
function AutoLoader.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "autoLoaderPickupTriggerCallback", AutoLoader.autoLoaderPickupTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "autoLoaderOverlapCallback", AutoLoader.autoLoaderOverlapCallback)
    SpecializationUtil.registerFunction(vehicleType, "getIsValidAutoLoaderObject", AutoLoader.getIsValidAutoLoaderObject)
    SpecializationUtil.registerFunction(vehicleType, "getIsAutoLoadingAllowed", AutoLoader.getIsAutoLoadingAllowed)
    SpecializationUtil.registerFunction(vehicleType, "onUnmountObject", AutoLoader.onUnmountObject)
end
function AutoLoader.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDynamicMountTimeToMount", AutoLoader.getDynamicMountTimeToMount)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", AutoLoader.addToPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", AutoLoader.removeFromPhysics)
end
function AutoLoader.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AutoLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AutoLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", AutoLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AutoLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", AutoLoader)
end
function AutoLoader:onLoad(_)
    local spec = self.spec_autoLoader
    if self.isServer then
        spec.collsionMask = CollisionFlag.VEHICLE + CollisionFlag.DYNAMIC_OBJECT
        spec.pendingObjects = {}
        spec.mountedObjects = {}
        spec.triggerToAreas = {}
        spec.alwaysActiveTriggers = {}
        spec.skippedObjects = {}
        self.xmlFile:iterate("vehicle.autoLoader.areas.area", function(_, areaKey)
            -- upvalues: (copy) self, (copy) spec
            local node = self.xmlFile:getValue(areaKey .. "#node", nil, self.components, self.i3dMappings)
            local length = self.xmlFile:getValue(areaKey .. "#length", 6)
            local width = self.xmlFile:getValue(areaKey .. "#width", 2.5)
            local height = self.xmlFile:getValue(areaKey .. "#height", 4)
            local spacing = self.xmlFile:getValue(areaKey .. "#spacing", 0.1)
            if node ~= nil then
                if spec.areas == nil then
                    spec.areas = {}
                end
                local area = {
                    ["node"] = node,
                    ["index"] = #spec.areas + 1,
                    ["width"] = width,
                    ["length"] = length,
                    ["height"] = height,
                    ["spacing"] = spacing,
                    ["grid"] = PlacementGrid2D.new(node, width, length, spacing, PlacementGrid2D.MODE_SIDES)
                }
                self.xmlFile:iterate(areaKey .. ".trigger", function(_, triggerKey)
                    -- upvalues: (ref) self, (ref) spec, (copy) area
                    local triggerNode = self.xmlFile:getValue(triggerKey .. "#node", nil, self.components, self.i3dMappings)
                    if spec.triggerToAreas[triggerNode] == nil then
                        addTrigger(triggerNode, "autoLoaderPickupTriggerCallback", self)
                        spec.triggerToAreas[triggerNode] = {}
                    end
                    if self.xmlFile:getValue(triggerKey .. "#alwaysActive") then
                        spec.alwaysActiveTriggers[triggerNode] = true
                    end
                    table.insert(spec.triggerToAreas[triggerNode], area)
                end)
                table.insert(spec.areas, area)
            end
        end)
    end
    spec.isAutoLoadingActive = false
    spec.warningNoSpace = g_i18n:getText("autoLoader_warningNoSpace")
    spec.warningTooLarge = g_i18n:getText("autoLoader_warningTooLarge")
end
function AutoLoader:onPostLoad(savegame)
    if savegame ~= nil then
        local spec = self.spec_autoLoader
        if not savegame.resetVehicles then
            local xmlFile = savegame.xmlFile
            local key = string.format("%s.autoLoader.mountedObject", savegame.key)
            spec.pendingVehicles = {}
            xmlFile:iterate(key, function(_, objectKey)
                -- upvalues: (copy) xmlFile, (copy) spec, (copy) self
                local posX = xmlFile:getValue(objectKey .. "#mountPosX")
                local posZ = xmlFile:getValue(objectKey .. "#mountPosZ")
                local sizeX = xmlFile:getValue(objectKey .. "#mountSizeX")
                local sizeZ = xmlFile:getValue(objectKey .. "#mountSizeZ")
                local areaIndex = xmlFile:getValue(objectKey .. "#mountAreaIndex")
                local vehicleUniqueId = xmlFile:getValue(objectKey .. "#vehicleUniqueId")
                local area = spec.areas[areaIndex]
                if area ~= nil then
                    if vehicleUniqueId ~= nil then
                        table.insert(spec.pendingVehicles, {
                            ["posX"] = posX,
                            ["posZ"] = posZ,
                            ["sizeX"] = sizeX,
                            ["sizeZ"] = sizeZ,
                            ["area"] = area,
                            ["vehicleUniqueId"] = vehicleUniqueId
                        })
                        return
                    end
                    if xmlFile:hasProperty(objectKey .. ".bale") then
                        local pendingVehicle = Bale.new(self.isServer, self.isClient)
                        if pendingVehicle:loadFromXMLFile(xmlFile, objectKey .. ".bale", false) then
                            pendingVehicle:register()
                            if pendingVehicle:autoLoad(self, area.node, posX, posZ, sizeX, sizeZ) then
                                spec.mountedObjects[pendingVehicle] = {
                                    posX,
                                    posZ,
                                    sizeX,
                                    sizeZ,
                                    area.index
                                }
                                spec.pendingObjects[pendingVehicle] = nil
                                area.grid:blockAreaLocal(posX, posZ, sizeX, sizeZ)
                                return
                            end
                        else
                            Logging.xmlWarning(xmlFile, "Could not load autoLoader bale for \'%s\'", objectKey)
                            pendingVehicle:delete()
                        end
                    end
                end
            end)
        end
    end
end
function AutoLoader:onDelete()
    local spec = self.spec_autoLoader
    if self.isServer then
        for pendingObject, _ in pairs(spec.pendingObjects) do
            pendingObject:removeDeleteListener(self, AutoLoader.onDeletePendingObject)
        end
        for pendingObject, _ in pairs(spec.mountedObjects) do
            pendingObject:unmountKinematic()
        end
        if spec.areas ~= nil then
            for pendingObject, _ in ipairs(spec.areas) do
                _.grid:delete()
            end
        end
        if spec.triggerToAreas ~= nil then
            for pendingObject, _ in pairs(spec.triggerToAreas) do
                removeTrigger(pendingObject)
            end
        end
    end
    spec.skippedObjects = nil
    spec.pendingObjects = nil
    spec.mountedObjects = nil
end
function AutoLoader:saveToXMLFile(xmlFile, key, _)
    local i = 0
    for object, mountData in pairs(self.spec_autoLoader.mountedObjects) do
        local mountKey = string.format("%s.mountedObject(%d)", key, i)
        xmlFile:setValue(mountKey .. "#mountPosX", mountData[1])
        xmlFile:setValue(mountKey .. "#mountPosZ", mountData[2])
        xmlFile:setValue(mountKey .. "#mountSizeX", mountData[3])
        xmlFile:setValue(mountKey .. "#mountSizeZ", mountData[4])
        xmlFile:setValue(mountKey .. "#mountAreaIndex", mountData[5])
        if object:isa(Vehicle) then
            xmlFile:setValue(mountKey .. "#vehicleUniqueId", object:getUniqueId())
        elseif object:isa(Bale) then
            object:saveToXMLFile(xmlFile, mountKey .. ".bale")
        end
        i = i + 1
    end
end
function AutoLoader:onUpdate(dt, _, _, _)
    local spec = self.spec_autoLoader
    if self.isServer and spec.areas ~= nil then
        for object, t in pairs(spec.skippedObjects) do
            local t = t - dt
            spec.skippedObjects[object] = t > 0 and t and t or nil
        end
        if spec.pendingVehicles ~= nil then
            for object, t in ipairs(spec.pendingVehicles) do
                local vehicle = g_currentMission.vehicleSystem:getVehicleByUniqueId(t.vehicleUniqueId)
                if vehicle ~= nil then
                    local area = t.area
                    local posX = t.posX
                    local posZ = t.posZ
                    local sizeX = t.sizeX
                    local sizeZ = t.sizeZ
                    if vehicle:autoLoad(self, area.node, posX, posZ, sizeX, sizeZ) then
                        spec.mountedObjects[vehicle] = {
                            posX,
                            posZ,
                            sizeX,
                            sizeZ,
                            area.index
                        }
                        spec.pendingObjects[vehicle] = nil
                        vehicle:removeDeleteListener(self, AutoLoader.onDeletePendingObject)
                        area.grid:blockAreaLocal(posX, posZ, sizeX, sizeZ)
                    end
                end
            end
            spec.pendingVehicles = nil
        end
        if spec.needGridUpdate then
            spec.needGridUpdate = false
            for object, t in ipairs(spec.areas) do
                t.grid:reset()
                for posX, posZ in pairs(spec.mountedObjects) do
                    local sizeX, sizeZ, success, dirX, dirY, dirZ, upX, upY, upZ, extendX, extendY, extendZ = posX:getAutoLoadBoundingBox()
                    t.grid:blockAreaByBoundingBox(sizeX, sizeZ, success, dirX, dirY, dirZ, upX, upY, upZ, extendX, extendY, extendZ)
                end
            end
        end
        local showTooLargeWarning = false
        local showNoSpaceWarning = false
        for vehicleUniqueId, vehicle in pairs(spec.pendingObjects) do
            if vehicleUniqueId.isDeleted then
                spec.pendingObjects[vehicleUniqueId] = true
            else
                if (spec.isAutoLoadingActive or spec.alwaysActiveTriggers[vehicle] == true) and vehicleUniqueId:getAutoLoadIsAllowed() then
                    local area, posX, posZ = vehicleUniqueId:getAutoLoadSize()
                    for dirY, dirZ in ipairs(spec.triggerToAreas[vehicle]) do
                        if area <= dirZ.width and (posX <= dirZ.height and posZ <= dirZ.length) then
                            local upX = false
                            for extendX = 1, 3 do
                                local extendY, extendZ = dirZ.grid:getFreePosition(area, posZ)
                                if extendY == nil then
                                    showNoSpaceWarning = true
                                else
                                    local x, y, z = localToWorld(dirZ.node, extendY + area * 0.5, posX * 0.5, extendZ + posZ * 0.5)
                                    local rx, ry, rz = getWorldRotation(dirZ.node)
                                    spec.isAreaBlocked = false
                                    spec.currentPendingObject = vehicleUniqueId
                                    overlapBox(x, y, z, rx, ry, rz, area * 0.5, posX * 0.5, posZ * 0.5, "autoLoaderOverlapCallback", self, spec.collsionMask, true, true, false, true)
                                    spec.currentPendingObject = nil
                                    if spec.isAreaBlocked then
                                        dirZ.grid:blockAreaLocal(extendY, extendZ, area, posZ)
                                    elseif vehicleUniqueId:autoLoad(self, dirZ.node, extendY, extendZ, area, posZ) then
                                        spec.mountedObjects[vehicleUniqueId] = {
                                            extendY,
                                            extendZ,
                                            area,
                                            posZ,
                                            dirZ.index
                                        }
                                        spec.pendingObjects[vehicleUniqueId] = nil
                                        vehicleUniqueId:removeDeleteListener(self, AutoLoader.onDeletePendingObject)
                                        dirZ.grid:blockAreaLocal(extendY, extendZ, area, posZ)
                                        upX = true
                                        showNoSpaceWarning = false
                                        showTooLargeWarning = false
                                        break
                                    end
                                end
                            end
                            if upX then
                                break
                            end
                        else
                            showTooLargeWarning = true
                        end
                    end
                end
                if showNoSpaceWarning and spec.warningNoSpace ~= nil then
                    g_currentMission:showBlinkingWarning(spec.warningNoSpace, 2000)
                elseif showTooLargeWarning and spec.warningTooLarge ~= nil then
                    g_currentMission:showBlinkingWarning(spec.warningTooLarge, 2000)
                end
            end
        end
        if Platform.gameplay.automaticVehicleControl and spec.isAutoLoadingActive then
            self.rootVehicle:playControlledActions()
        end
    end
end
function AutoLoader:onDraw()
    local spec = self.spec_autoLoader
    if spec.areas ~= nil then
        for _, area in ipairs(spec.areas) do
            area.grid:drawDebug()
        end
    end
end
function AutoLoader:addToPhysics(superFunc)
    if not superFunc(self) then
        return false
    end
    if self.isServer then
        for object, _ in pairs(self.spec_autoLoader.mountedObjects) do
            if object.addToPhysics ~= nil then
                object:addToPhysics()
            end
        end
    end
    return true
end
function AutoLoader:removeFromPhysics(superFunc)
    local ret = superFunc(self)
    if self.isServer then
        for object, _ in pairs(self.spec_autoLoader.mountedObjects) do
            if object.removeFromPhysics ~= nil then
                object:removeFromPhysics()
            end
        end
    end
    return ret
end
function AutoLoader:onUnmountObject(object)
    local spec = self.spec_autoLoader
    spec.skippedObjects[object] = 3000
    spec.mountedObjects[object] = nil
    spec.needGridUpdate = true
    self:raiseActive()
end
function AutoLoader:getIsValidAutoLoaderObject(object)
    if object == nil then
        return false
    elseif object == self then
        return false
    elseif self.spec_autoLoader.mountedObjects[object] == nil then
        if object:isa(Vehicle) or object:isa(Bale) then
            if object.getAutoLoadIsSupported == nil or not object:getAutoLoadIsSupported() then
                return false
            else
                return g_currentMission.accessHandler:canFarmAccess(self:getActiveFarm(), object) and true or false
            end
        else
            return false
        end
    else
        return false
    end
end
function AutoLoader:autoLoaderPickupTriggerCallback(triggerId, otherActorId, onEnter, onLeave, _, _)
    if onEnter then
        local object = g_currentMission:getNodeObject(otherActorId)
        if otherActorId ~= 0 and (self:getIsAutoLoadingAllowed() and (object == nil or self.spec_autoLoader.mountedObjects[object] == nil)) then
            local shouldBeSkipped = false
            if spec.skippedObjects[object] ~= nil then
                shouldBeSkipped = spec.alwaysActiveTriggers[triggerId] == true
            end
            if self:getIsValidAutoLoaderObject(object) and (spec.pendingObjects[object] ~= triggerId and not shouldBeSkipped) then
                spec.pendingObjects[object] = triggerId
                object:addDeleteListener(self, AutoLoader.onDeletePendingObject)
                spec.needGridUpdate = true
                self:raiseActive()
                return
            end
        end
    elseif onLeave then
        local object = g_currentMission:getNodeObject(otherActorId)
        if object ~= nil and spec.pendingObjects[object] ~= nil then
            spec.pendingObjects[object] = nil
            object:removeDeleteListener(self, AutoLoader.onDeletePendingObject)
        end
    end
end
function AutoLoader:autoLoaderOverlapCallback(transformId)
    if transformId ~= 0 and (getHasClassId(transformId, ClassIds.SHAPE) and not getHasTrigger(transformId)) then
        local object = g_currentMission:getNodeObject(transformId)
        local spec = self.spec_autoLoader
        if object ~= self and (spec.mountedObjects[object] == nil and spec.currentPendingObject ~= object) then
            spec.isAreaBlocked = true
            return false
        end
    end
    return true
end
function AutoLoader:getIsAutoLoadingAllowed()
    local _, y1, _ = getWorldTranslation(self.components[1].node)
    local _, y2, _ = localToWorld(self.components[1].node, 0, 1, 0)
    return y2 - y1 >= 0.5
end
function AutoLoader:getDynamicMountTimeToMount(_)
    return self:getIsAutoLoadingAllowed() and -1 or math.huge
end
function AutoLoader:onRootVehicleChanged(rootVehicle)
    local actionController = rootVehicle.actionController
    if actionController == nil then
        if self.spec_autoLoader.controlledAction ~= nil then
            spec.controlledAction:remove()
            spec.controlledAction = nil
        end
        return
    elseif spec.controlledAction == nil then
        spec.controlledAction = actionController:registerAction("autoLoaderLoad", nil, 4)
        spec.controlledAction:setCallback(self, AutoLoader.actionControllerEvent)
        spec.controlledAction:setIsAvailableFunction(function()
            -- upvalues: (copy) self
            return next(self.spec_autoLoader.pendingObjects) ~= nil
        end)
        spec.controlledAction:setActionIcons("AUTO_LOAD", "AUTO_LOAD", false)
    else
        spec.controlledAction:updateParent(actionController)
    end
end
function AutoLoader:actionControllerEvent(direction)
    if direction < 0 then
        self.spec_autoLoader.isAutoLoadingActive = false
    else
        spec.isAutoLoadingActive = true
    end
    return true
end
function AutoLoader:onDeletePendingObject(object)
    self.spec_autoLoader.pendingObjects[object] = nil
end