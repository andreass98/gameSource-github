Consumable = {}
Consumable.CONSUME_LEVEL_NUM_BITS = 7
Consumable.CONSUME_LEVEL_RESOLUTION = 2 ^ Consumable.CONSUME_LEVEL_NUM_BITS - 1
source("dataS/scripts/vehicles/specializations/events/ConsumableRefillEvent.lua")
source("dataS/scripts/vehicles/specializations/activatables/ConsumableActivatable.lua")
Consumable.CONFIG_NAMES = { "consumable", "consumable2" }
function Consumable.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end
function Consumable.initSpecialization()
    for _, configName in ipairs(Consumable.CONFIG_NAMES) do
        g_vehicleConfigurationManager:addConfigurationType(configName, g_i18n:getText("shop_configuration"), "consumable", VehicleConfigurationItem)
    end
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Consumable")
    for configName, configName in ipairs(Consumable.CONFIG_NAMES) do
        schema:register(XMLValueType.STRING, "vehicle.consumable." .. configName .. "Configurations#typeName", "Name of the consumable type that can be filled")
        schema:register(XMLValueType.STRING, "vehicle.consumable." .. configName .. "Configurations." .. configName .. "Configuration(?)#consumableName", "Consumable Name")
    end
    schema:register(XMLValueType.STRING, "vehicle.consumable.type(?)#typeName", "Name of the consumable type that can be filled")
    schema:register(XMLValueType.STRING, "vehicle.consumable.type(?)#defaultConsumableName", "Name of the consumable that is loaded by default, if not given the tool spawns empty")
    schema:register(XMLValueType.INT, "vehicle.consumable.type(?)#fillUnitIndex", "Fill unit index of the consumable fill unit", 1)
    schema:register(XMLValueType.BOOL, "vehicle.consumable.type(?)#allowRefillDialog", "Defines if the type can be refilled via the UI dialog", true)
    schema:register(XMLValueType.BOOL, "vehicle.consumable.type(?)#showWarning", "Show warning if the consumable is empty", true)
    schema:register(XMLValueType.BOOL, "vehicle.consumable.type(?).consuming#useScale", "Scale the consuming meshes based on the fill level", false)
    schema:register(XMLValueType.BOOL, "vehicle.consumable.type(?).consuming#useAmount", "Apply the fill level to the \'amount\' shader parameter", false)
    schema:register(XMLValueType.BOOL, "vehicle.consumable.type(?).consuming#useHideByIndex", "Apply hideByIndex shader parameter to the consuming mesh", false)
    schema:register(XMLValueType.FLOAT, "vehicle.consumable.type(?).consuming#hideByIndexOffset", "Offset for the hide by index fill level", 0)
    schema:register(XMLValueType.STRING, "vehicle.consumable.type(?).consuming.animation(?)#name", "Name of the animation that is set based on the consuming fill level")
    schema:register(XMLValueType.FLOAT, "vehicle.consumable.type(?).consuming.animation(?)#numLoops", "Number of times the animation is looping for the capacity of the consuming slots", 1)
    schema:register(XMLValueType.INT, "vehicle.consumable.type(?).consuming.animation(?)#numSteps", "If defined, the animation will move in steps")
    schema:register(XMLValueType.FLOAT, "vehicle.consumable.type(?).consuming.animation(?)#speedScale", "Speed of the animation", 1)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.consumable.type(?).slot(?)#node", "Link node of visual slot")
    schema:register(XMLValueType.BOOL, "vehicle.consumable.type(?).slot(?)#isConsumingSlot", "Slot is a consuming slot (different 3d model without packing if available)", false)
    schema:register(XMLValueType.BOOL, "vehicle.consumable.type(?).slot(?)#useTensionBeltMesh", "A tension belt mesh will be loaded for this slot if available", "\'true\' for pallets")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.consumable.type(?).shaderParameterNode(?)#node", "Shader parameter defined in the consumable variation will be applied here as well")
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.consumable.type(?)")
    schema:setXMLSpecializationType()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).consumable.type(?)#typeName", "Consumer type name")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).consumable.type(?)#consumingFillLevel", "Fill Level of consuming slots")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).consumable.type(?)#consumingVariationName", "Name of the variation that is currently loaded on the consuming slots")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).consumable.type(?).storageSlot(?)#consumableVariation", "Currently loaded consumer variation for slot")
end
function Consumable.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onConsumableVariationChanged")
end
function Consumable.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getConsumableVariationIndexByFillUnitIndex", Consumable.getConsumableVariationIndexByFillUnitIndex)
    SpecializationUtil.registerFunction(vehicleType, "setConsumableSlotVariationIndex", Consumable.setConsumableSlotVariationIndex)
    SpecializationUtil.registerFunction(vehicleType, "updateConsumable", Consumable.updateConsumable)
    SpecializationUtil.registerFunction(vehicleType, "getConsumableIsAvailable", Consumable.getConsumableIsAvailable)
    SpecializationUtil.registerFunction(vehicleType, "getShowConsumableEmptyWarning", Consumable.getShowConsumableEmptyWarning)
    SpecializationUtil.registerFunction(vehicleType, "getCustomFillTriggerSpeedFactor", Consumable.getCustomFillTriggerSpeedFactor)
end
function Consumable.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addFillUnitFillLevel", Consumable.addFillUnitFillLevel)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitFreeCapacity", Consumable.getFillUnitFreeCapacity)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "collectPalletTensionBeltNodes", Consumable.collectPalletTensionBeltNodes)
end
function Consumable.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Consumable)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Consumable)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Consumable)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Consumable)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Consumable)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Consumable)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Consumable)
    SpecializationUtil.registerEventListener(vehicleType, "onDirtyMaskCleared", Consumable)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Consumable)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", Consumable)
    SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Consumable)
    SpecializationUtil.registerEventListener(vehicleType, "onFillUnitIsFillingStateChanged", Consumable)
    SpecializationUtil.registerEventListener(vehicleType, "onAddedFillUnitTrigger", Consumable)
    SpecializationUtil.registerEventListener(vehicleType, "onRemovedFillUnitTrigger", Consumable)
end
function Consumable:onLoad(_)
    local spec = self.spec_consumable
    spec.animationsDirty = false
    spec.types = {}
    spec.typesByName = {}
    for _, typeKey in self.xmlFile:iterator("vehicle.consumable.type") do
        local type = {
            ["typeName"] = self.xmlFile:getValue(typeKey .. "#typeName")
        }
        if type.typeName == nil then
            Logging.xmlWarning(self.xmlFile, "Missing type name in \'%s\'", typeKey)
        else
            type.fillUnitIndex = self.xmlFile:getValue(typeKey .. "#fillUnitIndex")
            if type.fillUnitIndex == nil then
                Logging.xmlWarning(self.xmlFile, "Missing fillUnitIndex in \'%s\'", typeKey)
            elseif self:getFillUnitByIndex(type.fillUnitIndex) == nil then
                Logging.xmlWarning(self.xmlFile, "Invalid fillUnitIndex in \'%s\'", typeKey)
            else
                type.defaultConsumableName = self.xmlFile:getValue(typeKey .. "#defaultConsumableName")
                type.allowRefillDialog = self.xmlFile:getValue(typeKey .. "#allowRefillDialog", true)
                type.showWarning = self.xmlFile:getValue(typeKey .. "#showWarning", true)
                type.slots = {}
                type.storageSlots = {}
                type.consumingSlots = {}
                for _, slotKey in self.xmlFile:iterator(typeKey .. ".slot") do
                    local slot = {
                        ["node"] = self.xmlFile:getValue(slotKey .. "#node", nil, self.components, self.i3dMappings),
                        ["isConsumingSlot"] = self.xmlFile:getValue(slotKey .. "#isConsumingSlot", false)
                    }
                    slot.useTensionBeltMesh = self.xmlFile:getValue(slotKey .. "#useTensionBeltMesh", self.setPalletTensionBeltNodesDirty ~= nil)
                    slot.mesh = nil
                    slot.consumingMesh = nil
                    slot.consumableVariationIndex = 0
                    if slot.isConsumingSlot then
                        table.insert(type.consumingSlots, slot)
                    else
                        table.insert(type.storageSlots, slot)
                    end
                    table.insert(type.slots, slot)
                end
                type.useScale = self.xmlFile:getValue(typeKey .. ".consuming#useScale", false)
                type.useAmount = self.xmlFile:getValue(typeKey .. ".consuming#useAmount", false)
                type.useHideByIndex = self.xmlFile:getValue(typeKey .. ".consuming#useHideByIndex", false)
                type.hideByIndexOffset = self.xmlFile:getValue(typeKey .. ".consuming#hideByIndexOffset", 0)
                type.animations = {}
                for _, slotKey in self.xmlFile:iterator(typeKey .. ".consuming.animation") do
                    local slot = {
                        ["name"] = self.xmlFile:getValue(slotKey .. "#name")
                    }
                    if slot.name ~= nil then
                        slot.numLoops = math.max(self.xmlFile:getValue(slotKey .. "#numLoops", 1), 1)
                        slot.numSteps = self.xmlFile:getValue(slotKey .. "#numSteps")
                        slot.speedScale = self.xmlFile:getValue(slotKey .. "#speedScale", 1) * 0.001
                        slot.currentTime = 0
                        table.insert(type.animations, slot)
                    end
                end
                type.numSlots = #type.slots
                type.numStorageSlots = #type.storageSlots
                type.numConsumingSlots = #type.consumingSlots
                type.objectChanges = {}
                ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, typeKey, type.objectChanges, self.components, self)
                ObjectChangeUtil.setObjectChanges(type.objectChanges, false, self, self.setMovingToolDirty)
                type.shaderParameterNodes = {}
                for _, slotKey in self.xmlFile:iterator(typeKey .. ".shaderParameterNode") do
                    local slot = self.xmlFile:getValue(slotKey .. "#node", nil, self.components, self.i3dMappings)
                    if slot ~= nil then
                        table.insert(type.shaderParameterNodes, slot)
                    end
                end
                type.consumingFillLevel = 0
                type.consumingFillLevelSent = 0
                type.consumingVariationIndex = 0
                type.lastConsumedVariationIndex = 0
                type.isDirty = false
                self:setFillUnitCapacity(type.fillUnitIndex, type.numStorageSlots + type.numConsumingSlots, true)
                self:setFillUnitCapacityToDisplay(type.fillUnitIndex, type.numStorageSlots + type.numConsumingSlots)
                table.insert(spec.types, type)
                type.index = #spec.types
                spec.typesByName[type.typeName] = type
            end
        end
    end
    for _, typeKey in ipairs(Consumable.CONFIG_NAMES) do
        local type = string.format("vehicle.consumable.%sConfigurations", typeKey)
        if self.xmlFile:hasProperty(type) then
            local typeName = self.xmlFile:getValue(type .. "#typeName")
            if typeName ~= nil then
                local type = spec.typesByName[typeName]
                if type == nil then
                    Logging.xmlWarning(self.xmlFile, "Consumable type name \'%s\' not found for configuration \'%s\'", typeName, typeKey)
                else
                    type.defaultConsumableName = self.xmlFile:getValue(string.format("%s.%sConfiguration(%d)", type, typeKey, (self.configurations[typeKey] or 1) - 1) .. "#consumableName")
                end
            end
        end
    end
    spec.activatable = ConsumableActivatable.new(self)
    spec.dirtyFlag = self:getNextDirtyFlag()
end
function Consumable:onPostLoad(savegame)
    if savegame == nil then
        if not self.vehicleLoadingData:getCustomParameter("spawnEmpty") then
            for typeIndex, _ in ipairs(self.spec_consumable.types) do
                if _.defaultConsumableName ~= nil then
                    self:addFillUnitFillLevel(self:getOwnerFarmId(), _.fillUnitIndex, _.numStorageSlots, self:getFillUnitFirstSupportedFillType(_.fillUnitIndex), ToolType.UNDEFINED, nil)
                    _.consumingFillLevel = 1
                    _.consumingVariationIndex = g_consumableManager:getConsumableVariationIndexByName(_.defaultConsumableName, self.customEnvironment)
                    self:updateConsumable(_.typeName, 0)
                end
            end
        end
    elseif not savegame.resetVehicles then
        for _, typeKey in savegame.xmlFile:iterator((savegame.key .. ".consumable") .. ".type") do
            local typeName = savegame.xmlFile:getValue(typeKey .. "#typeName")
            local type = spec.typesByName[typeName]
            if type ~= nil then
                type.consumingFillLevel = savegame.xmlFile:getValue(typeKey .. "#consumingFillLevel", 0)
                local consumingVariationName = savegame.xmlFile:getValue(typeKey .. "#consumingVariationName")
                type.consumingVariationIndex = g_consumableManager:getConsumableVariationIndexByName(consumingVariationName, self.customEnvironment)
                for slotIndex, slotKey in savegame.xmlFile:iterator(typeKey .. ".storageSlot") do
                    local consumableVariation = savegame.xmlFile:getValue(slotKey .. "#consumableVariation")
                    if consumableVariation ~= nil then
                        local consumableVariationIndex = g_consumableManager:getConsumableVariationIndexByName(consumableVariation, self.customEnvironment)
                        self:setConsumableSlotVariationIndex(type.index, slotIndex, consumableVariationIndex)
                    end
                end
                self:updateConsumable(type.typeName, 0)
                if self.updatePalletStraps ~= nil then
                    self:updatePalletStraps()
                end
            end
        end
    end
    Consumable.updateActivatable(self)
end
function Consumable:onDelete()
    g_currentMission.activatableObjectsSystem:removeActivatable(self.spec_consumable.activatable)
end
function Consumable:saveToXMLFile(xmlFile, key, _)
    for typeIndex, type in ipairs(self.spec_consumable.types) do
        local typeKey = string.format("%s.type(%d)", key, typeIndex - 1)
        xmlFile:setValue(typeKey .. "#typeName", type.typeName)
        xmlFile:setValue(typeKey .. "#consumingFillLevel", type.consumingFillLevel)
        xmlFile:setValue(typeKey .. "#consumingVariationName", g_consumableManager:getConsumableVariationNameByIndex(type.consumingVariationIndex))
        for slotIndex, slot in ipairs(type.storageSlots) do
            xmlFile:setValue(string.format("%s.storageSlot(%d)", typeKey, slotIndex - 1) .. "#consumableVariation", g_consumableManager:getConsumableVariationNameByIndex(slot.consumableVariationIndex))
        end
    end
end
function Consumable:onReadStream(streamId, connection)
    if connection:getIsServer() then
        for typeIndex, type in ipairs(self.spec_consumable.types) do
            if type.numConsumingSlots > 0 then
                type.consumingFillLevel = streamReadUIntN(streamId, Consumable.CONSUME_LEVEL_NUM_BITS) / Consumable.CONSUME_LEVEL_RESOLUTION
                type.consumingVariationIndex = streamReadUIntN(streamId, ConsumableManager.NUM_VARIATION_BITS)
                self:updateConsumable(type.typeName, 0)
            end
            for slotIndex, slot in ipairs(type.storageSlots) do
                local consumableVariationIndex = streamReadUIntN(streamId, ConsumableManager.NUM_VARIATION_BITS)
                self:setConsumableSlotVariationIndex(type.index, slotIndex, consumableVariationIndex)
            end
        end
        if self.updatePalletStraps ~= nil then
            self:updatePalletStraps()
        end
    end
end
function Consumable:onWriteStream(streamId, connection)
    if not connection:getIsServer() then
        for typeIndex, type in ipairs(self.spec_consumable.types) do
            if type.numConsumingSlots > 0 then
                streamWriteUIntN(streamId, math.floor(type.consumingFillLevel * Consumable.CONSUME_LEVEL_RESOLUTION), Consumable.CONSUME_LEVEL_NUM_BITS)
                streamWriteUIntN(streamId, type.consumingVariationIndex, ConsumableManager.NUM_VARIATION_BITS)
            end
            for _, slot in ipairs(type.storageSlots) do
                streamWriteUIntN(streamId, slot.consumableVariationIndex, ConsumableManager.NUM_VARIATION_BITS)
            end
        end
    end
end
function Consumable:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            for typeIndex, type in ipairs(self.spec_consumable.types) do
                if streamReadBool(streamId) then
                    type.consumingFillLevel = streamReadUIntN(streamId, Consumable.CONSUME_LEVEL_NUM_BITS) / Consumable.CONSUME_LEVEL_RESOLUTION
                    type.consumingVariationIndex = streamReadUIntN(streamId, ConsumableManager.NUM_VARIATION_BITS)
                    self:updateConsumable(type.typeName, 0)
                end
                if streamReadBool(streamId) then
                    for slotIndex, slot in ipairs(type.storageSlots) do
                        local consumableVariationIndex = streamReadUIntN(streamId, ConsumableManager.NUM_VARIATION_BITS)
                        self:setConsumableSlotVariationIndex(type.index, slotIndex, consumableVariationIndex)
                    end
                    if self.updatePalletStraps ~= nil then
                        self:updatePalletStraps()
                    end
                end
            end
        end
    end
end
function Consumable:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_consumable
        local anySlotDirty = spec.dirtyFlag
        if streamWriteBool(streamId, bit32.band(dirtyMask, anySlotDirty) ~= 0) then
            for typeIndex, type in ipairs(spec.types) do
                if streamWriteBool(streamId, type.isDirty) then
                    streamWriteUIntN(streamId, math.floor(type.consumingFillLevel * Consumable.CONSUME_LEVEL_RESOLUTION), Consumable.CONSUME_LEVEL_NUM_BITS)
                    streamWriteUIntN(streamId, type.consumingVariationIndex, ConsumableManager.NUM_VARIATION_BITS)
                end
                local anySlotDirty = false
                for _, slot in ipairs(type.storageSlots) do
                    if slot.isDirty then
                        anySlotDirty = true
                        break
                    end
                end
                if streamWriteBool(streamId, anySlotDirty) then
                    for _, slot in ipairs(type.storageSlots) do
                        streamWriteUIntN(streamId, slot.consumableVariationIndex, ConsumableManager.NUM_VARIATION_BITS)
                    end
                end
            end
        end
    end
end
function Consumable:onDirtyMaskCleared()
    local spec = self.spec_consumable
    if spec.types ~= nil then
        for typeIndex, type in ipairs(spec.types) do
            type.isDirty = false
            for _, slot in ipairs(type.storageSlots) do
                slot.isDirty = false
            end
        end
    end
end
function Consumable:onUpdate(dt, _, _, _)
    local spec = self.spec_consumable
    if spec.types ~= nil and spec.animationsDirty then
        spec.animationsDirty = false
        for typeIndex, type in ipairs(spec.types) do
            for _, animation in ipairs(type.animations) do
                if animation.isDirty then
                    local direction = math.sign(animation.targetTime - animation.currentTime)
                    animation.currentTime = (direction > 0 and math.min or math.max)(animation.currentTime + direction * dt * animation.speedScale, animation.targetTime)
                    if animation.currentTime > 1 and animation.targetTime > 1 then
                        animation.currentTime = animation.currentTime - 1
                        animation.targetTime = animation.targetTime - 1
                    elseif animation.currentTime < 0 and animation.targetTime < 0 then
                        animation.currentTime = animation.currentTime + 1
                        animation.targetTime = animation.targetTime + 1
                    end
                    self:setAnimationTime(animation.name, animation.currentTime, true)
                    animation.isDirty = animation.targetTime ~= animation.currentTime
                    if animation.isDirty then
                        spec.animationsDirty = true
                        self:raiseActive()
                    end
                end
            end
        end
    end
end
function Consumable:onDraw(_, _, _)
    local spec = self.spec_consumable
    if spec.types ~= nil then
        for typeIndex, type in ipairs(spec.types) do
            if type.showWarning and (type.numConsumingSlots > 0 and (type.consumingFillLevel == 0 and (self:getFillUnitFillLevel(type.fillUnitIndex) == 0 and self:getShowConsumableEmptyWarning(type.typeName)))) then
                local text = string.format(g_i18n:getText("warning_consumableEmpty"), g_consumableManager:getTypeTitle(type.typeName))
                g_currentMission:showBlinkingWarning(text, 500)
                return
            end
        end
    end
end
function Consumable:onFillUnitFillLevelChanged(fillUnitIndex, _, _, _, _, _)
    if self.isServer then
        local spec = self.spec_consumable
        if spec.types ~= nil then
            local fillLevel = self:getFillUnitFillLevel(fillUnitIndex)
            for typeIndex, type in ipairs(spec.types) do
                if fillUnitIndex == type.fillUnitIndex then
                    local numFilledSlots = 0
                    for slotIndex, slot in ipairs(type.storageSlots) do
                        if slot.consumableVariationIndex ~= 0 then
                        end
                    end
                    local consumableVariationIndex = fillLevel - numFilledSlots
                    local delta = math.abs(consumableVariationIndex)
                    if type.numStorageSlots > 0 then
                        delta = math.floor(delta)
                    end
                    if delta > 0 then
                        if numFilledSlots < fillLevel then
                            local consumableVariationIndex = nil
                            local specFillUnit = self.spec_fillUnit
                            if specFillUnit.fillTrigger.isFilling then
                                local slotIndex = specFillUnit.fillTrigger.currentTrigger
                                if slotIndex ~= nil and slotIndex.sourceObject.getConsumableVariationIndexByFillUnitIndex ~= nil then
                                    consumableVariationIndex = slotIndex.sourceObject:getConsumableVariationIndexByFillUnitIndex(slotIndex.fillUnitIndex)
                                end
                            end
                            if consumableVariationIndex == nil and type.consumingVariationIndex ~= 0 then
                                consumableVariationIndex = type.consumingVariationIndex
                            end
                            if consumableVariationIndex == nil then
                                consumableVariationIndex = type.defaultConsumableName == nil and 1 or g_consumableManager:getConsumableVariationIndexByName(type.defaultConsumableName, self.customEnvironment)
                            end
                            if type.numStorageSlots > 0 then
                                for i = 1, delta do
                                    local slotIndex = #type.storageSlots
                                    local slotIndex = -1
                                    for slotIndex = slotIndex, 1, slotIndex do
                                        if type.storageSlots[slotIndex].consumableVariationIndex == 0 then
                                            self:setConsumableSlotVariationIndex(type.index, slotIndex, consumableVariationIndex)
                                            break
                                        end
                                    end
                                end
                            end
                            type.lastConsumedVariationIndex = consumableVariationIndex
                            local slotIndex = type.numStorageSlots == 0
                            self:updateConsumable(type.typeName, 0, nil, slotIndex)
                        else
                            local slotIndex = 1
                            for slotIndex = slotIndex, delta do
                                for slotIndex, slotIndex in ipairs(type.storageSlots) do
                                    if slotIndex.consumableVariationIndex ~= 0 then
                                        type.lastConsumedVariationIndex = slotIndex.consumableVariationIndex
                                        self:setConsumableSlotVariationIndex(type.index, slotIndex, 0)
                                        break
                                    end
                                end
                            end
                        end
                        if self.updatePalletStraps ~= nil then
                            self:updatePalletStraps()
                        end
                    end
                end
            end
        end
    end
end
function Consumable:onFillUnitIsFillingStateChanged(isFilling)
    if not isFilling then
        local spec = self.spec_consumable
        if spec.types ~= nil then
            for typeIndex, type in ipairs(spec.types) do
                if type.consumingFillLevel == 0 then
                    self:updateConsumable(type.typeName, 0, nil, true)
                else
                    self:updateConsumable(type.typeName, 0, nil, false)
                end
            end
        end
    end
end
function Consumable:onAddedFillUnitTrigger(_, _, _)
    Consumable.updateActivatable(self)
end
function Consumable:onRemovedFillUnitTrigger(_)
    Consumable.updateActivatable(self)
end
function Consumable:getConsumableVariationIndexByFillUnitIndex(fillUnitIndex)
    local spec = self.spec_consumable
    if spec.types ~= nil then
        for typeIndex, type in ipairs(spec.types) do
            if type.fillUnitIndex == fillUnitIndex then
                for i, slot in ipairs(type.storageSlots) do
                    if slot.consumableVariationIndex ~= 0 then
                        return slot.consumableVariationIndex
                    end
                end
                return type.lastConsumedVariationIndex
            end
        end
    end
    return nil
end
function Consumable:setConsumableSlotVariationIndex(typeIndex, slotIndex, variationIndex)
    variationIndex = variationIndex or 0
    local spec = self.spec_consumable
    local type = spec.types[typeIndex]
    if type ~= nil then
        local slot = type.storageSlots[slotIndex]
        if slot ~= nil and variationIndex ~= slot.consumableVariationIndex then
            slot.consumableVariationIndex = variationIndex
            slot.isDirty = true
            if slot.node ~= nil then
                if slot.mesh ~= nil then
                    if self.removeAllSubWashableNodes ~= nil then
                        self:removeAllSubWashableNodes(slot.mesh)
                    end
                    if self.removeAllSubWearableNodes ~= nil then
                        self:removeAllSubWearableNodes(slot.mesh)
                    end
                    delete(slot.mesh)
                    slot.mesh = nil
                    if slot.tensionBeltMesh ~= nil then
                        slot.tensionBeltMesh = nil
                        if self.setPalletTensionBeltNodesDirty ~= nil then
                            self:setPalletTensionBeltNodesDirty()
                        end
                    end
                end
                local mesh, tensionBeltMesh = g_consumableManager:getConsumableMeshByIndex(slot.consumableVariationIndex, slot.useTensionBeltMesh)
                if mesh ~= nil then
                    link(slot.node, mesh)
                    setTranslation(mesh, 0, 0, 0)
                    setRotation(mesh, 0, 0, 0)
                    slot.mesh = mesh
                    if self.addAllSubWashableNodes ~= nil then
                        self:addAllSubWashableNodes(mesh)
                    end
                    if self.addAllSubWearableNodes ~= nil then
                        self:addAllSubWearableNodes(mesh)
                    end
                    if tensionBeltMesh ~= nil then
                        slot.tensionBeltMesh = tensionBeltMesh
                        if self.setPalletTensionBeltNodesDirty ~= nil then
                            self:setPalletTensionBeltNodesDirty()
                        end
                    end
                end
            end
            self:raiseDirtyFlags(spec.dirtyFlag)
        end
    end
end
function Consumable:updateConsumable(typeName, delta, consumingInProgress, fillConsumingSlots)
    local spec = self.spec_consumable
    local type = spec.typesByName[typeName]
    if type ~= nil and type.numConsumingSlots ~= 0 then
        local delta = type.consumingFillLevel + delta / type.numConsumingSlots
        type.consumingFillLevel = math.clamp(delta, 0, 1)
        if (fillConsumingSlots or fillConsumingSlots == nil and type.consumingFillLevel == 0) and self:getFillUnitFillLevel(type.fillUnitIndex) > 0 then
            local delta = self:addFillUnitFillLevel(self:getOwnerFarmId(), type.fillUnitIndex, -type.numConsumingSlots, self:getFillUnitFillType(type.fillUnitIndex), ToolType.UNDEFINED, nil)
            type.consumingFillLevel = math.min(type.consumingFillLevel + -delta / type.numConsumingSlots, type.numConsumingSlots)
            type.consumingVariationIndex = type.lastConsumedVariationIndex
        end
        for index, slot in ipairs(type.consumingSlots) do
            if slot.consumingMesh == nil or type.consumingVariationIndex ~= slot.consumableVariationIndex then
                slot.consumableVariationIndex = type.consumingVariationIndex
                if index == 1 then
                    local shaderParameters = g_consumableManager:getConsumableVariationShaderParameterByIndex(slot.consumableVariationIndex)
                    if shaderParameters ~= nil then
                        for _, shaderParameter in ipairs(shaderParameters) do
                            for _, node in ipairs(type.shaderParameterNodes) do
                                I3DUtil.setShaderParameterRec(node, shaderParameter.name, shaderParameter.value[1], shaderParameter.value[2], shaderParameter.value[3], shaderParameter.value[4])
                            end
                        end
                    end
                    local metaData = g_consumableManager:getConsumableVariationMetaDataByIndex(slot.consumableVariationIndex)
                    if metaData ~= nil then
                        SpecializationUtil.raiseEvent(self, "onConsumableVariationChanged", slot.consumableVariationIndex, metaData)
                    end
                end
                if slot.node ~= nil then
                    if slot.consumingMesh ~= nil then
                        if self.removeAllSubWashableNodes ~= nil then
                            self:removeAllSubWashableNodes(slot.consumingMesh)
                        end
                        if self.removeAllSubWearableNodes ~= nil then
                            self:removeAllSubWearableNodes(slot.consumingMesh)
                        end
                        delete(slot.consumingMesh)
                        slot.consumingMesh = nil
                    end
                    local shaderParameters = g_consumableManager:getConsumableConsumingMeshByIndex(slot.consumableVariationIndex)
                    if shaderParameters ~= nil then
                        link(slot.node, shaderParameters)
                        setTranslation(shaderParameters, 0, 0, 0)
                        setRotation(shaderParameters, 0, 0, 0)
                        slot.consumingMesh = shaderParameters
                        if self.addAllSubWashableNodes ~= nil then
                            self:addAllSubWashableNodes(shaderParameters)
                        end
                        if self.addAllSubWearableNodes ~= nil then
                            self:addAllSubWearableNodes(shaderParameters)
                        end
                    end
                end
            end
            if slot.consumingMesh ~= nil then
                if type.useScale then
                    setScale(slot.consumingMesh, math.max(type.consumingFillLevel, 0.1), 1, (math.max(type.consumingFillLevel, 0.1)))
                end
                if type.useAmount then
                    if getHasClassId(slot.consumingMesh, ClassIds.SHAPE) and getHasShaderParameter(slot.consumingMesh, "amount") then
                        g_animationManager:setPrevShaderParameter(slot.consumingMesh, "amount", type.consumingFillLevel, 0, 0, 0, false, "prevAmount")
                    end
                    local shaderParameters = getNumOfChildren(slot.consumingMesh)
                    local i = 1
                    for i = i, shaderParameters do
                        local _ = getChildAt(slot.consumingMesh, i - 1)
                        if getHasClassId(_, ClassIds.SHAPE) and getHasShaderParameter(_, "amount") then
                            g_animationManager:setPrevShaderParameter(_, "amount", type.consumingFillLevel, 0, 0, 0, false, "prevAmount")
                        end
                    end
                end
                if type.useHideByIndex then
                    I3DUtil.setHideByIndexRec(slot.consumingMesh, (math.clamp(type.consumingFillLevel + type.hideByIndexOffset, 0, 1)))
                end
                if consumingInProgress ~= true then
                    setVisibility(slot.consumingMesh, type.consumingFillLevel > 0)
                end
            end
        end
        for index, slot in ipairs(type.animations) do
            local shaderParameters
            if slot.numSteps == nil then
                local metaData = 1 / slot.numLoops
                shaderParameters = math.clamp((1 - type.consumingFillLevel) % metaData / metaData, 0, 1)
            else
                shaderParameters = 1 - math.ceil(type.consumingFillLevel * slot.numSteps) / slot.numSteps
            end
            local metaData = math.abs(shaderParameters - slot.currentTime)
            if slot.currentTime < shaderParameters then
                if math.abs(shaderParameters - 1 - slot.currentTime) < metaData then
                end
            elseif math.abs(shaderParameters + 1 - slot.currentTime) < metaData then
                slot.currentTime = slot.currentTime - 1
                self:setAnimationTime(slot.name, slot.currentTime, true)
            end
            slot.targetTime = shaderParameters
            slot.isDirty = slot.targetTime ~= slot.currentTime
            if slot.isDirty then
                spec.animationsDirty = true
                self:raiseActive()
            end
        end
        if consumingInProgress ~= true then
            ObjectChangeUtil.setObjectChanges(type.objectChanges, type.consumingFillLevel > 0, self, self.setMovingToolDirty)
        end
        local shaderParameters = type.fillUnitIndex
        local delta = math.min(self:getFillUnitFillLevel(type.fillUnitIndex) + type.consumingFillLevel * type.numConsumingSlots, self:getFillUnitCapacity(shaderParameters))
        self:setFillUnitFillLevelToDisplay(type.fillUnitIndex, delta, true)
        if MathUtil.round(type.consumingFillLevel * Consumable.CONSUME_LEVEL_RESOLUTION) ~= MathUtil.round(type.consumingFillLevelSent * Consumable.CONSUME_LEVEL_RESOLUTION) then
            self:raiseDirtyFlags(spec.dirtyFlag)
            type.consumingFillLevelSent = type.consumingFillLevel
            type.isDirty = true
        end
    end
    if consumingInProgress ~= true then
        Consumable.updateActivatable(self)
    end
end
function Consumable:getConsumableIsAvailable(typeName)
    local type = self.spec_consumable.typesByName[typeName]
    if type == nil then
        return true
    end
    return type.consumingFillLevel > 0
end
function Consumable:getShowConsumableEmptyWarning(typeName)
    local type = self.spec_consumable.typesByName[typeName]
    if type == nil then
        return false
    end
    return type.consumingFillLevel == 0
end
function Consumable:getCustomFillTriggerSpeedFactor(_, fillUnitIndex, _)
    local spec = self.spec_consumable
    if spec.types ~= nil then
        for i, type in ipairs(spec.types) do
            if type.fillUnitIndex == fillUnitIndex and type.numConsumingSlots > 0 then
                for slotIndex, slot in ipairs(type.storageSlots) do
                    if slot.consumableVariationIndex == 0 then
                        return 1
                    end
                end
                return math.huge
            end
        end
    end
    return 1
end
function Consumable:addFillUnitFillLevel(superFunc, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, ...)
    if fillLevelDelta > 0 then
        local spec = self.spec_consumable
        if spec.types ~= nil then
            for i, type in ipairs(spec.types) do
                if type.fillUnitIndex == fillUnitIndex then
                    fillLevelDelta = math.min(fillLevelDelta, type.numConsumingSlots * (1 - type.consumingFillLevel) + type.numStorageSlots + 1e-6 - self:getFillUnitFillLevel(fillUnitIndex))
                end
            end
        end
    end
    return superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, ...)
end
function Consumable:getFillUnitFreeCapacity(superFunc, fillUnitIndex, ...)
    local spec = self.spec_consumable
    if spec.types ~= nil then
        for i, type in ipairs(spec.types) do
            if type.fillUnitIndex == fillUnitIndex then
                local fillLevel = self:getFillUnitFillLevel(fillUnitIndex)
                local capacity = type.numStorageSlots + type.numConsumingSlots
                if type.consumingFillLevel ~= 0 and type.numStorageSlots ~= 0 then
                    capacity = type.numStorageSlots
                end
                return capacity + 1e-6 - fillLevel
            end
        end
    end
    return superFunc(self, fillUnitIndex, ...)
end
function Consumable:collectPalletTensionBeltNodes(superFunc, nodes)
    superFunc(self, nodes)
    local spec = self.spec_consumable
    if spec.types ~= nil then
        for i, type in ipairs(spec.types) do
            for index, slot in ipairs(type.storageSlots) do
                if slot.tensionBeltMesh ~= nil then
                    table.insert(nodes, slot.tensionBeltMesh)
                end
            end
        end
    end
end
function Consumable:updateActivatable()
    local spec = self.spec_consumable
    local showActivatable = false
    for i, type in ipairs(spec.types) do
        if type.consumingFillLevel == 0 and type.allowRefillDialog then
            showActivatable = true
        end
    end
    if #self.spec_fillUnit.fillTrigger.triggers ~= 0 then
        showActivatable = false
    end
    if showActivatable then
        spec.activatable:updateActivateText()
        g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
    else
        g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    end
end