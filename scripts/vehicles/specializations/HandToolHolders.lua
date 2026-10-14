HandToolHolders = {}
function HandToolHolders.prerequisitesPresent(specializations)
    return true
end
function HandToolHolders.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("handToolHolder", g_i18n:getText("shop_configuration"), "handToolHolders", VehicleConfigurationItem)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("HandToolHolders")
    HandToolHolder.registerXMLPaths(schema, "vehicle.handToolHolders")
    HandToolHolder.registerXMLPaths(schema, "vehicle.handToolHolders.handToolHolderConfigurations.handToolHolderConfiguration(?)")
    schema:setXMLSpecializationType()
    HandToolHolder.registerSavegameXMLPaths(Vehicle.xmlSchemaSavegame, "vehicles.vehicle(?).handToolHolders.handToolHolder(?)")
    Vehicle.xmlSchemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).handToolHolders.handToolHolder(?)#index", "Index of the holder", nil, true)
end
function HandToolHolders.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onHandToolStoredInHolder")
    SpecializationUtil.registerEvent(vehicleType, "onHandToolTakenFromHolder")
end
function HandToolHolders.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "onHandToolHolderFinished", HandToolHolders.onHandToolHolderFinished)
end
function HandToolHolders.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setOwnerFarmId", HandToolHolders.setOwnerFarmId)
end
function HandToolHolders.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", HandToolHolders)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", HandToolHolders)
    SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", HandToolHolders)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", HandToolHolders)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", HandToolHolders)
    SpecializationUtil.registerEventListener(vehicleType, "onRegistered", HandToolHolders)
end
function HandToolHolders:onLoad(savegame)
    local configKey = string.format("vehicle.handToolHolders.handToolHolderConfigurations.handToolHolderConfiguration(%d)", (self.configurations.handToolHolder or 1) - 1)
    local configKey = not self.xmlFile:hasProperty(configKey) and "vehicle.handToolHolders" or configKey
    self.spec_handToolHolders.handToolHolders = {}
    local name = self:getName()
    local brand = g_brandManager:getBrandByIndex(self:getBrand())
    if brand ~= nil then
    end
    local holderName = string.format(g_i18n:getText("ui_handToolHolderVehicle"), name)
    for nodeIndex, key in self.xmlFile:iterator(configKey .. ".handToolHolder") do
        local handToolHolder = HandToolHolder.new(self, self.isServer, self.isClient)
        handToolHolder:setHolderName(holderName)
        local args = {
            ["loadingTask"] = self:createLoadingTask(self),
            ["xmlFile"] = self.xmlFile,
            ["key"] = key,
            ["savegame"] = savegame
        }
        handToolHolder:load(self.xmlFile, key, self.onHandToolHolderFinished, self, args, self.components, self.i3dMappings, self.baseDirectory, self.customEnvironment)
    end
end
function HandToolHolders:onHandToolHolderFinished(handToolHolder, args)
    if handToolHolder ~= nil then
        local spec = self.spec_handToolHolders
        handToolHolder:setOwnerFarmId(self:getOwnerFarmId())
        handToolHolder:setStoreCallback(function(handTool)
            -- upvalues: (copy) self, (copy) handToolHolder
            SpecializationUtil.raiseEvent(self, "onHandToolStoredInHolder", handTool, handToolHolder)
        end)
        handToolHolder:setPickupCallback(function(handTool)
            -- upvalues: (copy) self, (copy) handToolHolder
            SpecializationUtil.raiseEvent(self, "onHandToolTakenFromHolder", handTool, handToolHolder)
        end)
        local savegame = spec.handToolHolders
        table.insert(savegame, handToolHolder)
        local savegame = args.savegame
        if savegame ~= nil and not savegame.resetVehicles then
            for _, key in savegame.xmlFile:iterator(savegame.key .. ".handToolHolders.handToolHolder") do
                if savegame.xmlFile:getValue(key .. "#index") == #spec.handToolHolders then
                    handToolHolder:loadFromXMLFile(savegame.xmlFile, key)
                    break
                end
            end
        end
    end
    self:finishLoadingTask(args.loadingTask)
end
function HandToolHolders:onDelete()
    local spec = self.spec_handToolHolders
    if spec.handToolHolders ~= nil then
        for _, handToolHolder in ipairs(spec.handToolHolders) do
            handToolHolder:delete()
        end
        table.clear(spec.handToolHolders)
    end
end
function HandToolHolders:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_handToolHolders
    if spec.handToolHolders ~= nil then
        for k, handToolHolder in ipairs(spec.handToolHolders) do
            local holderKey = string.format("%s.handToolHolder(%d)", key, k - 1)
            xmlFile:setValue(holderKey .. "#index", k)
            handToolHolder:saveToXMLFile(xmlFile, holderKey)
        end
    end
end
function HandToolHolders:onWriteStream(streamId, connection)
    if not connection:getIsServer() then
        local spec = self.spec_handToolHolders
        if spec.handToolHolders ~= nil then
            for _, handToolHolder in ipairs(spec.handToolHolders) do
                NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(handToolHolder))
                handToolHolder:writeStream(streamId, connection)
                g_server:registerObjectInStream(connection, handToolHolder)
            end
        end
    end
end
function HandToolHolders:onReadStream(streamId, connection)
    if connection:getIsServer() then
        local spec = self.spec_handToolHolders
        if spec.handToolHolders ~= nil then
            for _, handToolHolder in ipairs(spec.handToolHolders) do
                local handToolHolderId = NetworkUtil.readNodeObjectId(streamId)
                handToolHolder:readStream(streamId, connection)
                g_client:finishRegisterObject(handToolHolder, handToolHolderId)
            end
        end
    end
end
function HandToolHolders:setOwnerFarmId(superFunc, ownerFarmId, noEventSend)
    superFunc(self, ownerFarmId, noEventSend)
    local spec = self.spec_handToolHolders
    if spec.handToolHolders ~= nil then
        for _, handToolHolder in ipairs(spec.handToolHolders) do
            handToolHolder:setOwnerFarmId(ownerFarmId, true)
        end
    end
end
function HandToolHolders:onRegistered(_)
    local spec = self.spec_handToolHolders
    if spec.handToolHolders ~= nil then
        for _, handToolHolder in ipairs(spec.handToolHolders) do
            handToolHolder:register(true)
        end
    end
end