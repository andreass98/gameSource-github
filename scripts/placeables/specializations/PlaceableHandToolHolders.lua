PlaceableHandToolHolders = {}
function PlaceableHandToolHolders.prerequisitesPresent(specializations)
    return true
end
function PlaceableHandToolHolders.initSpecialization()
    HandToolHolder.registerXMLPaths(Placeable.xmlSchema, "placeable.handToolHolders")
    HandToolHolder.registerSavegameXMLPaths(Placeable.xmlSchemaSavegame, "placeables.placeable(?).handToolHolders.handToolHolder(?)")
    Placeable.xmlSchemaSavegame:register(XMLValueType.INT, "placeables.placeable(?).handToolHolders.handToolHolder(?)#index", "Index of the holder", nil, true)
end
function PlaceableHandToolHolders.registerEvents(vehicleType) end
function PlaceableHandToolHolders.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onHandToolHolderFinished", PlaceableHandToolHolders.onHandToolHolderFinished)
end
function PlaceableHandToolHolders.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableHandToolHolders.setOwnerFarmId)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setName", PlaceableHandToolHolders.setName)
end
function PlaceableHandToolHolders.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHandToolHolders)
    SpecializationUtil.registerEventListener(placeableType, "onLoadFinished", PlaceableHandToolHolders)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHandToolHolders)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHandToolHolders)
    SpecializationUtil.registerEventListener(placeableType, "saveToXMLFile", PlaceableHandToolHolders)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHandToolHolders)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHandToolHolders)
    SpecializationUtil.registerEventListener(placeableType, "onRegistered", PlaceableHandToolHolders)
end
function PlaceableHandToolHolders:onLoad(savegame)
    self.spec_handToolHolders.handToolHolders = {}
    local holderName = string.format(g_i18n:getText("ui_handToolHolderPlaceable"), self:getName())
    for nodeIndex, key in self.xmlFile:iterator("placeable.handToolHolders.handToolHolder") do
        local handToolHolder = HandToolHolder.new(self, self.isServer, self.isClient)
        handToolHolder:setHolderName(holderName)
        local args = {
            ["loadingTask"] = self:createLoadingTask(self),
            ["savegame"] = savegame
        }
        handToolHolder:load(self.xmlFile, key, self.onHandToolHolderFinished, self, args, self.components, self.i3dMappings, self.baseDirectory, self.customEnvironment)
    end
end
function PlaceableHandToolHolders:onHandToolHolderFinished(handToolHolder, args)
    if handToolHolder ~= nil then
        local spec = self.spec_handToolHolders
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
function PlaceableHandToolHolders:onLoadFinished(_)
    local spec = self.spec_handToolHolders
    if spec.handToolHolders ~= nil then
        for i, handToolHolder in ipairs(spec.handToolHolders) do
            for j, clickBox in ipairs(handToolHolder.clickBoxes) do
                removeFromPhysics(clickBox)
            end
        end
    end
end
function PlaceableHandToolHolders:onFinalizePlacement()
    for i, handToolHolder in ipairs(self.spec_handToolHolders.handToolHolders) do
        for j, clickBox in ipairs(handToolHolder.clickBoxes) do
            addToPhysics(clickBox)
        end
        handToolHolder:setOwnerFarmId(self:getOwnerFarmId())
    end
end
function PlaceableHandToolHolders:onDelete()
    local spec = self.spec_handToolHolders
    if spec.handToolHolders ~= nil then
        for _, handToolHolder in ipairs(spec.handToolHolders) do
            handToolHolder:delete()
        end
    end
end
function PlaceableHandToolHolders:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_handToolHolders
    if spec.handToolHolders ~= nil then
        for k, handToolHolder in ipairs(spec.handToolHolders) do
            local holderKey = string.format("%s.handToolHolder(%d)", key, k - 1)
            xmlFile:setValue(holderKey .. "#index", k)
            handToolHolder:saveToXMLFile(xmlFile, holderKey)
        end
    end
end
function PlaceableHandToolHolders:onWriteStream(streamId, connection)
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
function PlaceableHandToolHolders:onReadStream(streamId, connection)
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
function PlaceableHandToolHolders:setOwnerFarmId(superFunc, ownerFarmId, noEventSend)
    superFunc(self, ownerFarmId, noEventSend)
    local spec = self.spec_handToolHolders
    if spec.handToolHolders ~= nil then
        for _, handToolHolder in ipairs(spec.handToolHolders) do
            handToolHolder:setOwnerFarmId(ownerFarmId, true)
        end
    end
end
function PlaceableHandToolHolders:setName(superFunc, name, noEventSend)
    superFunc(self, name, noEventSend)
    local spec = self.spec_handToolHolders
    if spec.handToolHolders ~= nil then
        for _, handToolHolder in ipairs(spec.handToolHolders) do
            handToolHolder:setName(name)
        end
    end
end
function PlaceableHandToolHolders:onRegistered(_)
    local spec = self.spec_handToolHolders
    if spec.handToolHolders ~= nil then
        for _, handToolHolder in ipairs(spec.handToolHolders) do
            handToolHolder:register(true)
        end
    end
end