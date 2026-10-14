MultipleItemPurchase = {}
function MultipleItemPurchase.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("multipleItemPurchaseAmount", g_i18n:getText("configuration_buyableBaleAmount"), nil, VehicleConfigurationItem)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("MultipleItemPurchase")
    schema:register(XMLValueType.STRING, "vehicle.multipleItemPurchase#filename", "Item filename")
    schema:register(XMLValueType.BOOL, "vehicle.multipleItemPurchase#isVehicle", "Is Loading a vehicle (false=Bale)", false)
    schema:register(XMLValueType.STRING, "vehicle.multipleItemPurchase#fillType", "Bale fill type", "STRAW")
    schema:register(XMLValueType.BOOL, "vehicle.multipleItemPurchase#baleIsWrapped", "Bale is wrapped", false)
    schema:register(XMLValueType.STRING, "vehicle.multipleItemPurchase#baleVariationId", "Bale variation identifier", "DEFAULT")
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.multipleItemPurchase.offsets.offset(?)#offset", "Offset")
    schema:register(XMLValueType.FLOAT, "vehicle.multipleItemPurchase.offsets.offset(?)#amount", "Amount of items to activate offset")
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.multipleItemPurchase.itemPositions.itemPosition(?)#position", "Bale position")
    schema:register(XMLValueType.VECTOR_ROT, "vehicle.multipleItemPurchase.itemPositions.itemPosition(?)#rotation", "Bale rotation")
    schema:setXMLSpecializationType()
end
function MultipleItemPurchase.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end
function MultipleItemPurchase.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadItemAtPosition", MultipleItemPurchase.loadItemAtPosition)
    SpecializationUtil.registerFunction(vehicleType, "onFinishLoadingVehicle", MultipleItemPurchase.onFinishLoadingVehicle)
end
function MultipleItemPurchase.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTotalMass", MultipleItemPurchase.getTotalMass)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitCapacity", MultipleItemPurchase.getFillUnitCapacity)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setVisibility", MultipleItemPurchase.setVisibility)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", MultipleItemPurchase.addToPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", MultipleItemPurchase.removeFromPhysics)
end
function MultipleItemPurchase.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", MultipleItemPurchase)
    SpecializationUtil.registerEventListener(vehicleType, "onPreLoadFinished", MultipleItemPurchase)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", MultipleItemPurchase)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", MultipleItemPurchase)
end
function MultipleItemPurchase:onLoad(_)
    local spec = self.spec_multipleItemPurchase
    spec.loadedBales = {}
    spec.loadedVehicles = {}
    spec.itemFilename = Utils.getFilename(self.xmlFile:getValue("vehicle.multipleItemPurchase#filename"), self.baseDirectory)
    spec.isVehicle = self.xmlFile:getValue("vehicle.multipleItemPurchase#isVehicle", false)
    local fillTypeName = self.xmlFile:getValue("vehicle.multipleItemPurchase#fillType", "STRAW")
    spec.baleFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
    spec.baleIsWrapped = self.xmlFile:getValue("vehicle.multipleItemPurchase#baleIsWrapped", false)
    spec.baleVariationId = self.xmlFile:getValue("vehicle.multipleItemPurchase#baleVariationId", "DEFAULT")
    local positionOffset = { 0, 0, 0 }
    local i = 0
    while true do
        local baseKey = string.format("vehicle.multipleItemPurchase.offsets.offset(%d)", i)
        if not self.xmlFile:hasProperty(baseKey) then
            break
        end
        local offset = self.xmlFile:getValue(baseKey .. "#offset", nil, true)
        if self.xmlFile:getValue(baseKey .. "#amount") > self.configurations.multipleItemPurchaseAmount then
            offset = positionOffset
        end
        i = i + 1
    end
    spec.positions = {}
    local i = 0
    while true do
        local baseKey = string.format("vehicle.multipleItemPurchase.itemPositions.itemPosition(%d)", i)
        if not self.xmlFile:hasProperty(baseKey) then
            break
        end
        local offset = self.xmlFile:getValue(baseKey .. "#position", nil, true)
        local amount = self.xmlFile:getValue(baseKey .. "#rotation", nil, true)
        if offset ~= nil and amount ~= nil then
            if positionOffset ~= nil then
                offset[1] = offset[1] + positionOffset[1]
                offset[2] = offset[2] + positionOffset[2]
                offset[3] = offset[3] + positionOffset[3]
            end
            table.insert(spec.positions, {
                ["position"] = offset,
                ["rotation"] = amount
            })
        end
        i = i + 1
    end
    for _, component in ipairs(self.components) do
        setCollisionFilterMask(component.node, (bit32.bxor(getCollisionFilterMask(component.node), CollisionFlag.VEHICLE + CollisionFlag.DYNAMIC_OBJECT)))
    end
    if not self.isServer then
        SpecializationUtil.removeEventListener(self, "onUpdate", MultipleItemPurchase)
    end
end
function MultipleItemPurchase:onPreLoadFinished(_)
    for j, position in ipairs(self.spec_multipleItemPurchase.positions) do
        if j <= self.configurations.multipleItemPurchaseAmount then
            self:loadItemAtPosition(position)
        end
    end
end
function MultipleItemPurchase:loadItemAtPosition(position)
    if self.isServer or self.propertyState == VehiclePropertyState.SHOP_CONFIG then
        local x = localToWorld
        local y = self.components[1].node
        local rx = position.position
        local x, y, z = x(y, unpack(rx))
        local rx = localRotationToWorld
        local ry = self.components[1].node
        local baleObject = position.rotation
        local rx, ry, rz = rx(ry, unpack(baleObject))
        if not self.spec_multipleItemPurchase.isVehicle then
            local baleObject = Bale.new(self.isServer, self.isClient)
            if baleObject:loadFromConfigXML(spec.itemFilename, x, y, z, rx, ry, rz) then
                baleObject:setFillType(spec.baleFillTypeIndex, true)
                baleObject:setOwnerFarmId(self:getActiveFarm(), true)
                baleObject:setVariationId(spec.baleVariationId)
                if self.propertyState ~= VehiclePropertyState.SHOP_CONFIG then
                    baleObject:register()
                end
                if spec.baleIsWrapped then
                    baleObject:setWrappingState(1)
                    if self.configurations.baseColor ~= nil then
                        local color = ConfigurationUtil.getColorByConfigId(self, "baseColor", self.configurations.baseColor)
                        baleObject:setColor(unpack(color))
                    end
                end
                baleObject:removeFromPhysics()
                table.insert(spec.loadedBales, baleObject)
            else
                Logging.error("Failed to load multi purchase item \'%s\'", spec.itemFilename)
            end
        end
        local baleObject = self:createLoadingTask(self)
        local color = VehicleLoadingData.new()
        color:setFilename(spec.itemFilename)
        color:setPosition(x, y, z)
        color:setRotation(rx, ry, rz)
        color:setPropertyState(self.propertyState)
        color:setIsRegistered(self.propertyState ~= VehiclePropertyState.SHOP_CONFIG)
        color:setForceServer(self.propertyState == VehiclePropertyState.SHOP_CONFIG)
        color:setOwnerFarmId(self:getActiveFarm())
        local configurations = {}
        local storeItem = g_storeManager:getItemByXMLFilename(spec.itemFilename)
        if storeItem ~= nil and storeItem.configurations ~= nil then
            for configName, configItems in pairs(storeItem.configurations) do
                if self.configurations[configName] ~= nil then
                    configurations[configName] = self.configurations[configName]
                end
            end
        end
        color:setConfigurations(configurations)
        color:load(self.onFinishLoadingVehicle, self, baleObject)
    end
end
function MultipleItemPurchase:onFinishLoadingVehicle(vehicles, vehicleLoadState, loadingTask)
    if self.isDeleted or self.isDeleting then
        if vehicleLoadState == VehicleLoadingState.OK then
            for _, vehicle in ipairs(vehicles) do
                vehicle:delete()
            end
        end
    else
        if vehicleLoadState == VehicleLoadingState.OK then
            for vehicle, vehicle in ipairs(vehicles) do
                vehicle:removeFromPhysics()
                vehicle:setVisibility(false)
                table.insert(self.spec_multipleItemPurchase.loadedVehicles, vehicle)
            end
        else
            Logging.error("Failed to load multi purchase item \'%s\'", spec.itemFilename)
        end
        if loadingTask ~= nil then
            self:finishLoadingTask(loadingTask)
        end
    end
end
function MultipleItemPurchase:onDelete()
    if self.propertyState == VehiclePropertyState.SHOP_CONFIG or (g_iconGenerator ~= nil or g_currentMission.vehicleSystem.debugVehiclesToBeLoaded ~= nil) then
        local spec = self.spec_multipleItemPurchase
        if spec.loadedBales ~= nil then
            for _, bale in ipairs(spec.loadedBales) do
                bale:delete()
            end
            spec.loadedBales = {}
            for _, bale in ipairs(spec.loadedVehicles) do
                bale:delete()
            end
            spec.loadedVehicles = {}
        end
    end
end
function MultipleItemPurchase:onUpdate(_, _, _, _)
    if self.propertyState ~= VehiclePropertyState.SHOP_CONFIG then
        self:delete()
    end
end
function MultipleItemPurchase:getTotalMass(_, _)
    if self.propertyState ~= VehiclePropertyState.SHOP_CONFIG then
        return 0
    end
    local mass = 0
    local spec = self.spec_multipleItemPurchase
    for _, bale in ipairs(spec.loadedBales) do
        mass = mass + bale:getMass()
    end
    for _, bale in ipairs(spec.loadedVehicles) do
        mass = mass + bale:getTotalMass()
    end
    return mass
end
function MultipleItemPurchase:getFillUnitCapacity(_, _)
    if self.propertyState ~= VehiclePropertyState.SHOP_CONFIG then
        return 0
    end
    local fillLevel = 0
    local spec = self.spec_multipleItemPurchase
    for _, bale in ipairs(spec.loadedBales) do
        fillLevel = fillLevel + bale:getFillLevel()
    end
    for _, bale in ipairs(spec.loadedVehicles) do
        if bale.getFillUnitCapacity ~= nil then
            fillLevel = fillLevel + bale:getFillUnitCapacity(1)
        end
    end
    return fillLevel
end
function MultipleItemPurchase:setVisibility(superFunc, state)
    for _, vehicle in ipairs(self.spec_multipleItemPurchase.loadedVehicles) do
        vehicle:setVisibility(state)
    end
    superFunc(self, state)
end
function MultipleItemPurchase:addToPhysics(superFunc)
    if not superFunc(self) then
        return false
    end
    local spec = self.spec_multipleItemPurchase
    for _, bale in ipairs(spec.loadedBales) do
        bale:addToPhysics()
    end
    for _, bale in ipairs(spec.loadedVehicles) do
        bale:addToPhysics()
    end
    return true
end
function MultipleItemPurchase:removeFromPhysics(superFunc)
    local spec = self.spec_multipleItemPurchase
    for _, bale in ipairs(spec.loadedBales) do
        bale:removeFromPhysics()
    end
    for _, bale in ipairs(spec.loadedVehicles) do
        bale:removeFromPhysics()
    end
    return superFunc(self)
end