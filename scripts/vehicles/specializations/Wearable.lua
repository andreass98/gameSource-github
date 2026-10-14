source("dataS/scripts/vehicles/specializations/events/WearableRepairEvent.lua")
source("dataS/scripts/vehicles/specializations/events/WearableRepaintEvent.lua")
Wearable = {}
Wearable.SEND_NUM_BITS = 6
Wearable.SEND_MAX_VALUE = 2 ^ Wearable.SEND_NUM_BITS - 1
Wearable.SEND_THRESHOLD = 1 / Wearable.SEND_MAX_VALUE
Wearable.WEAR_FACTOR = 0.5
function Wearable.prerequisitesPresent(specializations)
    return true
end
function Wearable.initSpecialization()
    if Platform.gameplay.hasVehicleDamage then
        g_storeManager:addSpecType("wearable", "shopListAttributeIconCondition", Wearable.loadSpecValueCondition, Wearable.getSpecValueCondition, StoreSpecies.VEHICLE)
    end
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Wearable")
    schema:register(XMLValueType.FLOAT, "vehicle.wearable#wearDuration", "Duration until fully worn (minutes)", 600)
    schema:register(XMLValueType.FLOAT, "vehicle.wearable#workMultiplier", "Multiplier while working", 20)
    schema:register(XMLValueType.FLOAT, "vehicle.wearable#fieldMultiplier", "Multiplier while on field", 2)
    schema:register(XMLValueType.BOOL, "vehicle.wearable#showOnHud", "Show the damage on the hud", true)
    schema:setXMLSpecializationType()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).wearable.wearNode(?)#amount", "Wear amount")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).wearable#damage", "Damage amount")
end
function Wearable.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "addAllSubWearableNodes", Wearable.addAllSubWearableNodes)
    SpecializationUtil.registerFunction(vehicleType, "addDamageAmount", Wearable.addDamageAmount)
    SpecializationUtil.registerFunction(vehicleType, "addToGlobalWearableNode", Wearable.addToGlobalWearableNode)
    SpecializationUtil.registerFunction(vehicleType, "addToLocalWearableNode", Wearable.addToLocalWearableNode)
    SpecializationUtil.registerFunction(vehicleType, "addWearableNode", Wearable.addWearableNode)
    SpecializationUtil.registerFunction(vehicleType, "addWearAmount", Wearable.addWearAmount)
    SpecializationUtil.registerFunction(vehicleType, "getDamageAmount", Wearable.getDamageAmount)
    SpecializationUtil.registerFunction(vehicleType, "getDamageShowOnHud", Wearable.getDamageShowOnHud)
    SpecializationUtil.registerFunction(vehicleType, "getNodeWearAmount", Wearable.getNodeWearAmount)
    SpecializationUtil.registerFunction(vehicleType, "getUsageCausesDamage", Wearable.getUsageCausesDamage)
    SpecializationUtil.registerFunction(vehicleType, "getUsageCausesWear", Wearable.getUsageCausesWear)
    SpecializationUtil.registerFunction(vehicleType, "getWearMultiplier", Wearable.getWearMultiplier)
    SpecializationUtil.registerFunction(vehicleType, "getWearTotalAmount", Wearable.getWearTotalAmount)
    SpecializationUtil.registerFunction(vehicleType, "getWorkWearMultiplier", Wearable.getWorkWearMultiplier)
    SpecializationUtil.registerFunction(vehicleType, "removeAllSubWearableNodes", Wearable.removeAllSubWearableNodes)
    SpecializationUtil.registerFunction(vehicleType, "removeWearableNode", Wearable.removeWearableNode)
    SpecializationUtil.registerFunction(vehicleType, "repaintVehicle", Wearable.repaintVehicle)
    SpecializationUtil.registerFunction(vehicleType, "repairVehicle", Wearable.repairVehicle)
    SpecializationUtil.registerFunction(vehicleType, "setDamageAmount", Wearable.setDamageAmount)
    SpecializationUtil.registerFunction(vehicleType, "setNodeWearAmount", Wearable.setNodeWearAmount)
    SpecializationUtil.registerFunction(vehicleType, "updateDamageAmount", Wearable.updateDamageAmount)
    SpecializationUtil.registerFunction(vehicleType, "updateWearAmount", Wearable.updateWearAmount)
    SpecializationUtil.registerFunction(vehicleType, "validateWearableNode", Wearable.validateWearableNode)
end
function Wearable.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getVehicleDamage", Wearable.getVehicleDamage)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRepairPrice", Wearable.getRepairPrice)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRepaintPrice", Wearable.getRepaintPrice)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "showInfo", Wearable.showInfo)
end
function Wearable.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Wearable)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Wearable)
    if not GS_IS_MOBILE_VERSION then
        SpecializationUtil.registerEventListener(vehicleType, "onSaleItemSet", Wearable)
        SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Wearable)
        SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Wearable)
        SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Wearable)
        SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Wearable)
        SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Wearable)
    end
end
function Wearable:onLoad(_)
    local spec = self.spec_wearable
    spec.wearableNodes = {}
    spec.wearableNodesByIndex = {}
    self:addToLocalWearableNode(nil, Wearable.updateWearAmount, nil, nil)
    spec.wearDuration = self.xmlFile:getValue("vehicle.wearable#wearDuration", 600) * 60 * 1000
    if spec.wearDuration ~= 0 then
        spec.wearDuration = 1 / spec.wearDuration * Wearable.WEAR_FACTOR
    end
    spec.totalAmount = 0
    spec.damage = 0
    spec.damageByCurve = 0
    spec.damageSent = 0
    spec.workMultiplier = self.xmlFile:getValue("vehicle.wearable#workMultiplier", 20)
    spec.fieldMultiplier = self.xmlFile:getValue("vehicle.wearable#fieldMultiplier", 2)
    spec.showOnHud = self.xmlFile:getValue("vehicle.wearable#showOnHud", true)
    spec.dirtyFlag = self:getNextDirtyFlag()
end
function Wearable:onLoadFinished(savegame)
    local spec = self.spec_wearable
    if savegame ~= nil then
        spec.damage = savegame.xmlFile:getValue(savegame.key .. ".wearable#damage", 0)
        spec.damageByCurve = math.max(spec.damage - 0.3, 0) / 0.7
    end
    if spec.wearableNodes ~= nil then
        for _, component in pairs(self.components) do
            self:addAllSubWearableNodes(component.node)
        end
        if savegame ~= nil then
            for _, component in ipairs(spec.wearableNodes) do
                local nodeKey = string.format("%s.wearable.wearNode(%d)", savegame.key, _ - 1)
                self:setNodeWearAmount(component, savegame.xmlFile:getValue(nodeKey .. "#amount", 0), true)
            end
            return
        end
        for _, component in ipairs(spec.wearableNodes) do
            self:setNodeWearAmount(component, 0, true)
        end
    end
end
function Wearable:onSaleItemSet(saleItem)
    self:addDamageAmount(saleItem.damage or 0, true)
    self:addWearAmount(saleItem.wear or 0, true)
end
function Wearable:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_wearable
    xmlFile:setValue(key .. "#damage", spec.damage)
    if spec.wearableNodes ~= nil then
        for i, nodeData in ipairs(spec.wearableNodes) do
            xmlFile:setValue(string.format("%s.wearNode(%d)", key, i - 1) .. "#amount", self:getNodeWearAmount(nodeData))
        end
    end
end
function Wearable:onReadStream(streamId, _)
    local spec = self.spec_wearable
    self:setDamageAmount(streamReadUIntN(streamId, Wearable.SEND_NUM_BITS) / Wearable.SEND_MAX_VALUE, true)
    if spec.wearableNodes ~= nil then
        for _, nodeData in ipairs(spec.wearableNodes) do
            self:setNodeWearAmount(nodeData, streamReadUIntN(streamId, Wearable.SEND_NUM_BITS) / Wearable.SEND_MAX_VALUE, true)
        end
    end
end
function Wearable:onWriteStream(streamId, _)
    local spec = self.spec_wearable
    streamWriteUIntN(streamId, math.floor(spec.damage * Wearable.SEND_MAX_VALUE + 0.5), Wearable.SEND_NUM_BITS)
    if spec.wearableNodes ~= nil then
        for _, nodeData in ipairs(spec.wearableNodes) do
            streamWriteUIntN(streamId, math.floor(self:getNodeWearAmount(nodeData) * Wearable.SEND_MAX_VALUE + 0.5), Wearable.SEND_NUM_BITS)
        end
    end
end
function Wearable:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() and streamReadBool(streamId) then
        self:setDamageAmount(streamReadUIntN(streamId, Wearable.SEND_NUM_BITS) / Wearable.SEND_MAX_VALUE, true)
        if self.spec_wearable.wearableNodes ~= nil then
            for _, nodeData in ipairs(spec.wearableNodes) do
                self:setNodeWearAmount(nodeData, streamReadUIntN(streamId, Wearable.SEND_NUM_BITS) / Wearable.SEND_MAX_VALUE, true)
            end
        end
    end
end
function Wearable:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.spec_wearable.dirtyFlag) ~= 0) then
            streamWriteUIntN(streamId, math.floor(spec.damage * Wearable.SEND_MAX_VALUE + 0.5), Wearable.SEND_NUM_BITS)
            if spec.wearableNodes ~= nil then
                for _, nodeData in ipairs(spec.wearableNodes) do
                    streamWriteUIntN(streamId, math.floor(self:getNodeWearAmount(nodeData) * Wearable.SEND_MAX_VALUE + 0.5), Wearable.SEND_NUM_BITS)
                end
            end
        end
    end
end
function Wearable:onUpdateTick(dt, _, _, _)
    local spec = self.spec_wearable
    if spec.wearableNodes ~= nil and self.isServer then
        local changeAmount = self:updateDamageAmount(dt)
        if changeAmount ~= 0 then
            self:setDamageAmount(spec.damage + changeAmount)
        end
        for _, nodeData in ipairs(spec.wearableNodes) do
            local changedAmount = nodeData.updateFunc(self, nodeData, dt)
            if changedAmount ~= 0 then
                self:setNodeWearAmount(nodeData, self:getNodeWearAmount(nodeData) + changedAmount)
            end
        end
    end
end
function Wearable:setDamageAmount(amount, force)
    local spec = self.spec_wearable
    spec.damage = math.min(math.max(amount, 0), 1)
    spec.damageByCurve = math.max(spec.damage - 0.3, 0) / 0.7
    if (math.abs(spec.damageSent - spec.damage) > Wearable.SEND_THRESHOLD or force) and self.isServer then
        self:raiseDirtyFlags(spec.dirtyFlag)
        spec.damageSent = spec.damage
    end
end
function Wearable:updateWearAmount(nodeData, dt)
    return not self:getUsageCausesWear() and 0 or dt * self.spec_wearable.wearDuration * self:getWearMultiplier(nodeData) * 0.5
end
function Wearable:updateDamageAmount(dt)
    if not self:getUsageCausesDamage() then
        return 0
    end
    local factor = 1
    if self.lifetime ~= nil and self.lifetime ~= 0 then
        local ageMultiplier = 0.15 * math.min(self.age / self.lifetime, 1)
        local operatingTimeMultiplier = 0.85 * math.min(self.operatingTime / 3600000 / (self.lifetime * EconomyManager.LIFETIME_OPERATINGTIME_RATIO), 1)
        factor = 1 + EconomyManager.MAX_DAILYUPKEEP_MULTIPLIER * (ageMultiplier + operatingTimeMultiplier)
    end
    return dt * self.spec_wearable.wearDuration * 0.35 * factor
end
function Wearable:getUsageCausesWear()
    return true
end
function Wearable:getUsageCausesDamage()
    if self.spec_motorized == nil and getIsSleeping(self.rootNode) then
        return false
    end
    return self.isActive and self.propertyState ~= VehiclePropertyState.MISSION
end
function Wearable:addWearAmount(wearAmount, force)
    local spec = self.spec_wearable
    if spec.wearableNodes ~= nil then
        for _, nodeData in ipairs(spec.wearableNodes) do
            self:setNodeWearAmount(nodeData, self:getNodeWearAmount(nodeData) + wearAmount, force)
        end
    end
end
function Wearable:addDamageAmount(amount, force)
    self:setDamageAmount(self.spec_wearable.damage + amount, force)
end
function Wearable:setNodeWearAmount(nodeData, wearAmount, force)
    nodeData.wearAmount = math.clamp(wearAmount, 0, 1)
    if math.abs(nodeData.wearAmountSent - nodeData.wearAmount) > Wearable.SEND_THRESHOLD or force then
        for _, node in pairs(nodeData.nodes) do
            setShaderParameter(node, "scratches_dirt_snow_wetness", nodeData.wearAmount, nil, nil, nil, false)
        end
        if self.isServer then
            self:raiseDirtyFlags(self.spec_wearable.dirtyFlag)
            nodeData.wearAmountSent = nodeData.wearAmount
        end
        spec.totalAmount = 0
        local i = 1
        for i = i, #spec.wearableNodes do
            spec.totalAmount = spec.totalAmount + spec.wearableNodes[i].wearAmount
        end
        spec.totalAmount = spec.totalAmount / #spec.wearableNodes
    end
end
function Wearable.getNodeWearAmount(_, nodeData)
    return nodeData.wearAmount
end
function Wearable:getWearTotalAmount()
    return self.spec_wearable.totalAmount
end
function Wearable:getDamageAmount()
    return self.spec_wearable.damage
end
function Wearable:getDamageShowOnHud()
    return self.spec_wearable.showOnHud
end
function Wearable:repairVehicle()
    if self.isServer then
        g_currentMission:addMoney(-self:getRepairPrice(), self:getOwnerFarmId(), MoneyType.VEHICLE_REPAIR, true, true)
        local total, _ = g_farmManager:updateFarmStats(self:getOwnerFarmId(), "repairVehicleCount", 1)
        if total ~= nil then
            g_achievementManager:tryUnlock("VehicleRepairFirst", total)
            g_achievementManager:tryUnlock("VehicleRepair", total)
        end
    end
    self:setDamageAmount(0)
end
function Wearable:repaintVehicle()
    if self.isServer then
        g_currentMission:addMoney(-self:getRepaintPrice(), self:getOwnerFarmId(), MoneyType.VEHICLE_REPAIR, true, true)
        local total, _ = g_farmManager:updateFarmStats(self:getOwnerFarmId(), "repaintVehicleCount", 1)
        if total ~= nil then
            g_achievementManager:tryUnlock("VehicleRepaint", total)
        end
    end
    for _, data in ipairs(self.spec_wearable.wearableNodes) do
        self:setNodeWearAmount(data, 0, true)
    end
end
function Wearable:getRepairPrice(superFunc)
    return superFunc(self) + Wearable.calculateRepairPrice(self:getPrice(), self.spec_wearable.damage)
end
function Wearable.calculateRepairPrice(price, damage)
    return price * math.pow(damage, 1.5) * 0.09
end
function Wearable:getRepaintPrice(superFunc)
    return superFunc(self) + Wearable.calculateRepaintPrice(self:getPrice(), self:getWearTotalAmount())
end
function Wearable:showInfo(superFunc, box)
    local damage = self.spec_wearable.damage
    if damage > 0.01 then
        box:addLine(g_i18n:getText("infohud_damage"), string.format("%d %%", damage * 100))
    end
    superFunc(self, box)
end
function Wearable.calculateRepaintPrice(price, wear)
    return price * math.sqrt(wear / 100) * 2
end
function Wearable:getVehicleDamage(superFunc)
    return math.min(superFunc(self) + self.spec_wearable.damageByCurve, 1)
end
function Wearable:addAllSubWearableNodes(rootNode)
    if rootNode ~= nil then
        I3DUtil.iterateShaderParameterNodesRecursively(rootNode, "scratches_dirt_snow_wetness", self.addWearableNode, self)
    end
end
function Wearable:addWearableNode(node)
    local isGlobal, updateFunc, customIndex, extraParams = self:validateWearableNode(node)
    if isGlobal then
        self:addToGlobalWearableNode(node)
    elseif updateFunc ~= nil then
        self:addToLocalWearableNode(node, updateFunc, customIndex, extraParams)
    end
end
function Wearable:validateWearableNode(node)
    return true, nil
end
function Wearable:addToGlobalWearableNode(node)
    local spec = self.spec_wearable
    if spec.wearableNodes[1] ~= nil then
        spec.wearableNodes[1].nodes[node] = node
    end
end
function Wearable:addToLocalWearableNode(node, updateFunc, customIndex, extraParams)
    local spec = self.spec_wearable
    local nodeData = {}
    if customIndex ~= nil then
        if spec.wearableNodesByIndex[customIndex] ~= nil then
            spec.wearableNodesByIndex[customIndex].nodes[node] = node
            return
        end
        spec.wearableNodesByIndex[customIndex] = nodeData
    end
    nodeData.nodes = {}
    if node ~= nil then
        nodeData.nodes[node] = node
    end
    nodeData.updateFunc = updateFunc
    nodeData.wearAmount = 0
    nodeData.wearAmountSent = 0
    if extraParams ~= nil then
        for i, v in pairs(extraParams) do
            nodeData[i] = v
        end
    end
    table.insert(spec.wearableNodes, nodeData)
end
function Wearable:removeAllSubWearableNodes(rootNode)
    if rootNode ~= nil then
        I3DUtil.iterateShaderParameterNodesRecursively(rootNode, "scratches_dirt_snow_wetness", self.removeWearableNode, self)
    end
end
function Wearable:removeWearableNode(node)
    local spec = self.spec_wearable
    if spec.wearableNodes ~= nil and node ~= nil then
        for _, nodeData in ipairs(spec.wearableNodes) do
            nodeData.nodes[node] = nil
        end
    end
end
function Wearable:getWearMultiplier()
    local multiplier = self:getLastSpeed() < 1 and 0 or 1
    if self.isOnField then
    end
    return multiplier
end
function Wearable:getWorkWearMultiplier()
    return self.spec_wearable.workMultiplier
end
function Wearable:updateDebugValues(values)
    local spec = self.spec_wearable
    local changedAmount = self:updateDamageAmount(3600000)
    table.insert(values, {
        ["name"] = "Damage",
        ["value"] = string.format("%.4f a/h (%.2f)", changedAmount, self:getDamageAmount())
    })
    if spec.wearableNodes ~= nil and self.isServer then
        for i, nodeData in ipairs(spec.wearableNodes) do
            local changedAmount = nodeData.updateFunc(self, nodeData, 3600000)
            table.insert(values, {
                ["name"] = "WearableNode" .. i,
                ["value"] = string.format("%.4f a/h (%.6f)", changedAmount, self:getNodeWearAmount(nodeData))
            })
        end
    end
end
function Wearable.loadSpecValueCondition(xmlFile, customEnvironment, baseDir)
    return nil
end
function Wearable.getSpecValueCondition(_, realItem)
    if realItem == nil then
        return nil
    elseif realItem.getDamageAmount == nil then
        return nil
    else
        return string.format("%d%%", realItem:getDamageAmount() * 100)
    end
end