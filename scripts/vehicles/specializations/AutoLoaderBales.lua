AutoLoaderBales = {}
function AutoLoaderBales.prerequisitesPresent(specializations)
    return true
end
function AutoLoaderBales.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("AutoLoaderBales")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.autoLoaderBales.trigger#node", "Bale pickup trigger node")
    schema:register(XMLValueType.STRING, "vehicle.autoLoaderBales.baleTypes.baleType(?)#fillTypes", "List of supported fill types (if empty, all fill types are allowed)")
    schema:register(XMLValueType.FLOAT, "vehicle.autoLoaderBales.baleTypes.baleType(?)#diameter", "Bale diameter", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.autoLoaderBales.baleTypes.baleType(?)#width", "Bale width", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.autoLoaderBales.baleTypes.baleType(?)#height", "Bale height", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.autoLoaderBales.baleTypes.baleType(?)#length", "Bale length", 0)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.autoLoaderBales.baleTypes.baleType(?).spawnPlace#node", "Node to spawn the bale")
    schema:register(XMLValueType.INT, "vehicle.autoLoaderBales.baleTypes.baleType(?).spawnPlace#numBales", "Number of bales that can be loaded", 1)
    schema:register(XMLValueType.VECTOR_3, "vehicle.autoLoaderBales.baleTypes.baleType(?).spawnPlace#offsetDirection", "Defines the axis in which the additional bales are moved", "0 1 0")
    schema:register(XMLValueType.BOOL, "vehicle.autoLoaderBales.baleTypes.baleType(?).spawnPlace#mountBale", "Defines if the bale is mounted or just moved to the position of the spawn node", true)
    schema:setXMLSpecializationType()
    Bale.registerSavegameXMLPaths(Vehicle.xmlSchemaSavegame, "vehicles.vehicle(?).autoLoaderBales.bale(?)")
end
function AutoLoaderBales.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "autoLoaderBalesTriggerCallback", AutoLoaderBales.autoLoaderBalesTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "getAutoLoadBaleTypeFromBale", AutoLoaderBales.getAutoLoadBaleTypeFromBale)
    SpecializationUtil.registerFunction(vehicleType, "doAutoLoadBale", AutoLoaderBales.doAutoLoadBale)
    SpecializationUtil.registerFunction(vehicleType, "getIsBaleAutoLoadable", AutoLoaderBales.getIsBaleAutoLoadable)
end
function AutoLoaderBales.registerOverwrittenFunctions(vehicleType) end
function AutoLoaderBales.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AutoLoaderBales)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", AutoLoaderBales)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", AutoLoaderBales)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AutoLoaderBales)
end
function AutoLoaderBales:onLoad(_)
    local spec = self.spec_autoLoaderBales
    spec.balesInTrigger = {}
    spec.balePickupDelay = 0
    spec.mountedBales = {}
    spec.numMountedBales = 0
    spec.loadedBaleType = nil
    if self.isServer then
        spec.triggerId = self.xmlFile:getValue("vehicle.autoLoaderBales.trigger#node", nil, self.components, self.i3dMappings)
        if spec.triggerId ~= nil then
            addTrigger(spec.triggerId, "autoLoaderBalesTriggerCallback", self)
        end
        spec.baleTypes = {}
        self.xmlFile:iterate("vehicle.autoLoaderBales.baleTypes.baleType", function(_, baleTypeKey)
            -- upvalues: (copy) self, (copy) spec
            local baleType = {
                ["spawnNode"] = self.xmlFile:getValue(baleTypeKey .. ".spawnPlace#node", nil, self.components, self.i3dMappings)
            }
            if baleType.spawnNode == nil then
                Logging.xmlWarning(self.xmlFile, "Missing spawn place node in \'%s\'", baleTypeKey)
                return
            else
                baleType.numBales = self.xmlFile:getValue(baleTypeKey .. ".spawnPlace#numBales", 1)
                baleType.offsetDirection = self.xmlFile:getValue(baleTypeKey .. ".spawnPlace#offsetDirection", "0 1 0", true)
                baleType.mountBale = self.xmlFile:getValue(baleTypeKey .. ".spawnPlace#mountBale", true)
                baleType.diameter = MathUtil.round(self.xmlFile:getValue(baleTypeKey .. "#diameter", 0), 2)
                baleType.width = MathUtil.round(self.xmlFile:getValue(baleTypeKey .. "#width", 0), 2)
                baleType.height = MathUtil.round(self.xmlFile:getValue(baleTypeKey .. "#height", 0), 2)
                baleType.length = MathUtil.round(self.xmlFile:getValue(baleTypeKey .. "#length", 0), 2)
                local fillTypeNames = self.xmlFile:getValue(baleTypeKey .. "#fillTypes")
                baleType.fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: \'" .. self.xmlFile:getFilename() .. "\' has invalid fillType \'%s\'.")
                if (baleType.diameter == 0 or baleType.width == 0) and (baleType.width == 0 or (baleType.height == 0 or baleType.length == 0)) then
                    Logging.xmlWarning(self.xmlFile, "Incomplete bale size defintion in \'%s\'", baleTypeKey)
                else
                    table.insert(spec.baleTypes, baleType)
                end
            end
        end)
    end
end
function AutoLoaderBales:onLoadFinished(savegame)
    if savegame ~= nil and not savegame.resetVehicles then
        savegame.xmlFile:iterate(savegame.key .. ".autoLoaderBales.bale", function(_, baleKey)
            -- upvalues: (copy) savegame, (copy) self
            local attributes = {}
            Bale.loadBaleAttributesFromXMLFile(attributes, savegame.xmlFile, baleKey, savegame.resetVehicles)
            local bale = Bale.new(self.isServer, self.isClient)
            if bale:loadFromConfigXML(attributes.xmlFilename, 0, 0, 0, 0, 0, 0, attributes.uniqueId) then
                bale:applyBaleAttributes(attributes)
                local baleType = self:getAutoLoadBaleTypeFromBale(bale)
                if baleType ~= nil then
                    self:doAutoLoadBale(baleType, bale)
                    return
                end
                bale:delete()
            end
        end)
    end
end
function AutoLoaderBales:onDelete()
    local spec = self.spec_autoLoaderBales
    if spec.triggerId ~= nil then
        removeTrigger(spec.triggerId)
    end
    if spec.balesInTrigger ~= nil then
        for bale, _ in pairs(spec.balesInTrigger) do
            if bale.removeDeleteListener ~= nil then
                bale:removeDeleteListener(self, AutoLoaderBales.onBaleDeleted)
            end
        end
        table.clear(spec.balesInTrigger)
    end
    if spec.mountedBales ~= nil then
        for bale, _ in pairs(spec.mountedBales) do
            if bale.removeDeleteListener ~= nil then
                bale:removeDeleteListener(self, AutoLoaderBales.onDeleteAutoLoaderBalesObject)
            end
            bale:unmountKinematic()
            bale:setNeedsSaving(true)
        end
        table.clear(spec.mountedBales)
    end
end
function AutoLoaderBales:saveToXMLFile(xmlFile, key, _)
    local index = 0
    for bale, _ in pairs(self.spec_autoLoaderBales.mountedBales) do
        bale:saveToXMLFile(xmlFile, (string.format("%s.bale(%d)", key, index)))
        index = index + 1
    end
end
function AutoLoaderBales:onUpdate(_, _, _, _)
    local spec = self.spec_autoLoaderBales
    local baleToLoad = spec.balePickupDelay - 1
    spec.balePickupDelay = math.max(baleToLoad, 0)
    if spec.balePickupDelay == 0 then
        local baleMaxHeight = 0
        local baleToLoad = nil
        local baleTypeToLoad = nil
        for object, num in pairs(spec.balesInTrigger) do
            if num > 0 and self:getIsBaleAutoLoadable(object) then
                local baleType = self:getAutoLoadBaleTypeFromBale(object)
                if baleType ~= nil and spec.numMountedBales < baleType.numBales then
                    local _, y, _ = getWorldTranslation(object.nodeId)
                    if baleMaxHeight < y then
                        baleTypeToLoad = baleType
                        baleToLoad = object
                        baleMaxHeight = y
                    end
                end
            end
        end
        if baleToLoad ~= nil then
            self:doAutoLoadBale(baleTypeToLoad, baleToLoad)
            spec.balesInTrigger[baleToLoad] = nil
            spec.balePickupDelay = 10
        end
    end
end
function AutoLoaderBales:onDeleteAutoLoaderBalesObject(object)
    local spec = self.spec_autoLoaderBales
    if spec.mountedBales[object] ~= nil then
        spec.mountedBales[object] = nil
        spec.numMountedBales = spec.numMountedBales - 1
    end
    spec.balesInTrigger[object] = nil
    if next(spec.mountedBales) == nil then
        spec.loadedBaleType = nil
    end
end
function AutoLoaderBales:onBaleDeleted(object)
    self.spec_autoLoaderBales.balesInTrigger[object] = nil
end
function AutoLoaderBales:autoLoaderBalesTriggerCallback(_, otherActorId, onEnter, _, _, _)
    if otherActorId == 0 then
        return
    else
        local object = g_currentMission:getNodeObject(otherActorId)
        if object == nil then
            return
        elseif object:isa(Bale) and (g_currentMission.accessHandler:canFarmAccess(self:getActiveFarm(), object) and object:getAllowPickup()) then
            if onEnter then
                self.spec_autoLoaderBales.balesInTrigger[object] = (self.spec_autoLoaderBales.balesInTrigger[object] or 0) + 1
                if spec.balesInTrigger[object] == 1 then
                    object:addDeleteListener(self, AutoLoaderBales.onBaleDeleted)
                    return
                end
            else
                spec.balesInTrigger[object] = (spec.balesInTrigger[object] or 0) - 1
                if spec.balesInTrigger[object] <= 0 then
                    spec.balesInTrigger[object] = nil
                    object:removeDeleteListener(self, AutoLoaderBales.onBaleDeleted)
                end
            end
        end
    end
end
function AutoLoaderBales:getAutoLoadBaleTypeFromBale(bale)
    local spec = self.spec_autoLoaderBales
    local baleFillType = bale:getFillType()
    local i = 1
    for i = i, #spec.baleTypes do
        local baleType = spec.baleTypes[i]
        if spec.loadedBaleType == nil or baleType == spec.loadedBaleType then
            local fillTypeAllowed = #baleType.fillTypes == 0
            local j = 1
            for j = j, #baleType.fillTypes do
                if baleType.fillTypes[j] == baleFillType then
                    fillTypeAllowed = true
                    break
                end
            end
            if fillTypeAllowed and bale:getBaleMatchesSize(baleType.diameter, baleType.width, baleType.height, baleType.length) then
                return baleType
            end
        end
    end
    return nil
end
function AutoLoaderBales:doAutoLoadBale(baleType, bale)
    if baleType.mountBale then
        local x, y, z
        if bale.isRoundbale then
            x = baleType.offsetDirection[1] * self.spec_autoLoaderBales.numMountedBales * bale.diameter
            y = baleType.offsetDirection[2] * spec.numMountedBales * bale.diameter
            z = baleType.offsetDirection[3] * spec.numMountedBales * bale.width
        else
            x = baleType.offsetDirection[1] * spec.numMountedBales * bale.width
            y = baleType.offsetDirection[2] * spec.numMountedBales * bale.height
            z = baleType.offsetDirection[3] * spec.numMountedBales * bale.length
        end
        bale:mountKinematic(self, baleType.spawnNode, x, y, z, 0, 0, 0)
        bale:setNeedsSaving(false)
        spec.mountedBales[bale] = true
        bale:addDeleteListener(self, AutoLoaderBales.onDeleteAutoLoaderBalesObject)
        spec.loadedBaleType = baleType
        spec.numMountedBales = spec.numMountedBales + 1
    else
        removeFromPhysics(bale.nodeId)
        setTranslation(bale.nodeId, getWorldTranslation(baleType.spawnNode))
        setWorldRotation(bale.nodeId, getWorldRotation(baleType.spawnNode))
        addToPhysics(bale.nodeId)
        local x, y, z = getLinearVelocity(self:getParentComponent(baleType.spawnNode))
        setLinearVelocity(bale.nodeId, x, y, z)
    end
end
function AutoLoaderBales.getIsBaleAutoLoadable(_, bale)
    return bale.mountObject == nil
end