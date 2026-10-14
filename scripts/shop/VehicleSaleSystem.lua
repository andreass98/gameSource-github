VehicleSaleSystem = {}
VehicleSaleSystem.MINIMUM_ITEM_VALUE = 10000
VehicleSaleSystem.MAX_MULTIPLAYER_ITEMS = 20
VehicleSaleSystem.MIN_MULTIPLAYER_ITEM_DURATION = 20
VehicleSaleSystem.MAX_MULTIPLAYER_ITEM_DURATION = 40
VehicleSaleSystem.MULTIPLAYER_ACCEPT_CHANCE = 0.8
VehicleSaleSystem.MAX_GENERATED_ITEMS = 5
VehicleSaleSystem.MIN_GENERATED_ITEM_DURATION = 20
VehicleSaleSystem.MAX_GENERATED_ITEM_DURATION = 40
VehicleSaleSystem.GENERATED_HOURLY_CHANCE = 3 / VehicleSaleSystem.MIN_GENERATED_ITEM_DURATION
VehicleSaleSystem.BUYPRICE_FACTOR = 1.1
local VehicleSaleSystem_mt = Class(VehicleSaleSystem)
function VehicleSaleSystem.new(mission)
    -- upvalues: (copy) VehicleSaleSystem_mt
    local self = setmetatable({}, VehicleSaleSystem_mt)
    self.mission = mission
    self.items = {}
    self.numGeneratedItems = 0
    self.numMultiplayerItems = 0
    self.isEnabled = Platform.gameplay.hasVehicleSales
    self.nextFreeId = 1
    self.freeIds = {}
    g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
    return self
end
function VehicleSaleSystem:delete(_)
    g_messageCenter:unsubscribeAll(self)
end
function VehicleSaleSystem:loadFromXMLFile(xmlFilename)
    if not self.isEnabled then
        return true
    end
    local xmlFile = XMLFile.loadIfExists("vehicleSaleXML", xmlFilename)
    if xmlFile == nil then
        self:generateInitialSales()
        return false
    end
    xmlFile:iterate("sales.item", function(_, key)
        -- upvalues: (copy) self, (copy) xmlFile
        local item = {
            ["id"] = #self.items + 1,
            ["timeLeft"] = xmlFile:getInt(key .. "#timeLeft"),
            ["isGenerated"] = xmlFile:getBool(key .. "#isGenerated"),
            ["xmlFilename"] = xmlFile:getString(key .. "#xmlFilename"),
            ["boughtConfigurations"] = {},
            ["age"] = xmlFile:getInt(key .. "#age"),
            ["price"] = xmlFile:getInt(key .. "#price"),
            ["damage"] = xmlFile:getFloat(key .. "#damage"),
            ["wear"] = xmlFile:getFloat(key .. "#wear"),
            ["operatingTime"] = xmlFile:getFloat(key .. "#operatingTime") * 1000,
            ["configSetIndex"] = xmlFile:getInt(key .. "#configSetIndex")
        }
        local storeItem = g_storeManager:getItemByXMLFilename(item.xmlFilename)
        if storeItem == nil then
            Logging.xmlWarning(xmlFile, "Store item for sale item \'%s\' could not be found, ignoring this item", item.xmlFilename)
        else
            xmlFile:iterate(key .. ".boughtConfiguration", function(_, cKey)
                -- upvalues: (ref) xmlFile, (copy) storeItem, (copy) item
                local name = xmlFile:getString(cKey .. "#name")
                local value = xmlFile:getString(cKey .. "#id")
                if storeItem.configurations[name] == nil then
                    return
                end
                local id = nil
                for _, config in ipairs(storeItem.configurations[name]) do
                    if config.saveId == value then
                        id = config.index
                        break
                    end
                end
                if id ~= nil then
                    if item.boughtConfigurations[name] == nil then
                        item.boughtConfigurations[name] = {}
                    end
                    item.boughtConfigurations[name][id] = true
                end
            end)
            if item.isGenerated then
                self.numGeneratedItems = self.numGeneratedItems + 1
            else
                self.numMultiplayerItems = self.numMultiplayerItems + 1
            end
            table.insert(self.items, item)
        end
    end)
    self.nextFreeId = #self.items + 1
    xmlFile:delete()
    return true
end
function VehicleSaleSystem:saveToXMLFile(xmlFilename)
    if self.isEnabled then
        local xmlFile = XMLFile.create("vehicleSaleXML", xmlFilename, "sales")
        if xmlFile ~= nil then
            xmlFile:setSortedTable("sales.item", self.items, function(key, item, _)
                -- upvalues: (copy) xmlFile
                xmlFile:setInt(key .. "#timeLeft", item.timeLeft)
                xmlFile:setBool(key .. "#isGenerated", item.isGenerated)
                xmlFile:setString(key .. "#xmlFilename", item.xmlFilename)
                xmlFile:setInt(key .. "#age", item.age)
                xmlFile:setInt(key .. "#price", item.price)
                xmlFile:setFloat(key .. "#damage", item.damage)
                xmlFile:setFloat(key .. "#wear", item.wear)
                xmlFile:setFloat(key .. "#operatingTime", item.operatingTime / 1000)
                if item.configSetIndex ~= nil then
                    xmlFile:setInt(key .. "#configSetIndex", item.configSetIndex)
                end
                local storeItem = g_storeManager:getItemByXMLFilename(item.xmlFilename)
                local i = 0
                for name, ids in pairs(item.boughtConfigurations) do
                    for id, _ in pairs(ids) do
                        if storeItem.configurations[name] == nil or storeItem.configurations[name][id] == nil then
                            Logging.warning("Configuration \'%s\' on %s has invalid id %s (is bought but does not exist)", name, storeItem.xmlFilename, id)
                        else
                            local cKey = string.format("%s.boughtConfiguration(%d)", key, i)
                            xmlFile:setString(cKey .. "#name", name)
                            xmlFile:setString(cKey .. "#id", (tostring(storeItem.configurations[name][id].saveId)))
                            i = i + 1
                        end
                    end
                end
            end)
            xmlFile:save()
            xmlFile:delete()
            return true
        end
    end
end
function VehicleSaleSystem:sendAllToClient(connection)
    local i = 1
    for i = i, #self.items do
        connection:sendEvent(VehicleSaleAddEvent.new(self.items[i]))
    end
end
function VehicleSaleSystem:generateInitialSales()
    for i = 1, VehicleSaleSystem.MAX_GENERATED_ITEMS - 1 do
        local randomVehicle = self:generateRandomVehicle()
        if randomVehicle ~= nil then
            self:addSale(randomVehicle)
        end
    end
end
function VehicleSaleSystem:getItems()
    return self.items
end
function VehicleSaleSystem:getSaleById(id)
    for _, item in ipairs(self.items) do
        if item.id == id then
            return item
        end
    end
    return nil
end
function VehicleSaleSystem:getFreeId()
    if #self.freeIds > 0 then
        return table.remove(self.freeIds)
    end
    self.nextFreeId = self.nextFreeId + 1
    return self.nextFreeId
end
function VehicleSaleSystem:onHourChanged()
    if self.isEnabled and self.mission:getIsServer() then
        if self.numGeneratedItems < VehicleSaleSystem.MAX_GENERATED_ITEMS and math.random() < VehicleSaleSystem.GENERATED_HOURLY_CHANCE then
            local randomVehicle = self:generateRandomVehicle()
            if randomVehicle ~= nil then
                self:addSale(randomVehicle)
            end
        end
        local i = #self.items
        local randomVehicle = 1
        for i = i, randomVehicle, -1 do
            local item = self.items[i]
            item.timeLeft = item.timeLeft - 1
            local storeItem = g_storeManager:getItemByXMLFilename(item.xmlFilename)
            if item.timeLeft <= 0 or storeItem == nil then
                self:removeSale(item, i)
            end
        end
    end
end
function VehicleSaleSystem:addSale(item, noEventSend)
    table.insert(self.items, item)
    if self.isEnabled and self.mission:getIsServer() then
        item.id = self:getFreeId()
        if item.isGenerated then
            self.numGeneratedItems = self.numGeneratedItems + 1
        else
            self.numMultiplayerItems = self.numMultiplayerItems + 1
        end
        if not noEventSend then
            g_server:broadcastEvent(VehicleSaleAddEvent.new(item))
        end
    end
    g_messageCenter:publish(MessageType.VEHICLE_SALES_CHANGED)
end
function VehicleSaleSystem:removeSale(item, index, noEventSend)
    if item == nil then
        return
    end
    if index == nil then
        for i, it in ipairs(self.items) do
            if item == it then
                index = i
                break
            end
        end
    end
    if index ~= nil then
        table.remove(self.items, index)
        if self.mission:getIsServer() then
            self.freeIds[#self.freeIds + 1] = item.id
            if item.isGenerated then
                self.numGeneratedItems = self.numGeneratedItems - 1
            else
                self.numMultiplayerItems = self.numMultiplayerItems - 1
            end
            if not noEventSend then
                g_server:broadcastEvent(VehicleSaleRemoveEvent.new(item.id))
            end
        end
        g_messageCenter:publish(MessageType.VEHICLE_SALES_CHANGED)
    end
end
function VehicleSaleSystem:removeSaleWithId(saleItemId)
    local i = 1
    for i = i, #self.items do
        if self.items[i].id == saleItemId then
            table.remove(self.items, i)
            break
        end
    end
    g_messageCenter:publish(MessageType.VEHICLE_SALES_CHANGED)
end
function VehicleSaleSystem:generateRandomVehicle()
    local items = g_storeManager:getItems()
    local storeItem = nil
    local try = 1
    local boughtConfigurations = #items
    local configSetIndex = 1
    for try = try, boughtConfigurations, configSetIndex do
        local item = items[math.random(1, #items)]
        if StoreItemUtil.getIsVehicle(item) and (item.showInStore and (item.price >= VehicleSaleSystem.MINIMUM_ITEM_VALUE and item.extraContentId == nil)) then
            storeItem = item
            break
        end
    end
    if storeItem == nil then
        return nil
    end
    StoreItemUtil.loadSpecsFromXML(storeItem)
    local boughtConfigurations = {}
    if storeItem.configurations ~= nil then
        for item, configItems in pairs(storeItem.configurations) do
            if #configItems > 1 then
                local includedInSet = false
                for _, configSet in ipairs(storeItem.configurationSets) do
                    if configSet.configurations[item] ~= nil then
                        includedInSet = true
                        break
                    end
                end
                if not includedInSet and math.random() < 0.15 then
                    local defaultIndex = ConfigurationUtil.getDefaultConfigIdFromItems(configItems)
                    local configSet = 5
                    for _ = 1, configSet do
                        local configSet = math.random(1, #configItems)
                        if configSet ~= defaultIndex and configItems[configSet].isSelectable then
                            boughtConfigurations[item] = {}
                            boughtConfigurations[item][configSet] = true
                            break
                        end
                    end
                end
            end
        end
    end
    local configSetIndex = nil
    local try = #storeItem.configurationSets
    if try > 0 and math.random() < 0.15 then
        local index = 1
        for defaultIndex, configSet in ipairs(storeItem.configurationSets) do
            if configSet.isDefault then
                index = defaultIndex
            end
        end
        for includedInSet = 1, 5 do
            local defaultIndex = math.random(1, try)
            if defaultIndex ~= index then
                configSetIndex = defaultIndex
                break
            end
        end
    end
    local index = math.random(6, 40)
    local item = math.random() * 0.4 + 0.2
    local configItems = math.random() * 0.8 + 0.2
    local includedInSet = index * (math.random() * 0.8 + 0.5) * 60 * 60 * 1000
    local defaultIndex = StoreItemUtil.getDefaultPrice(storeItem, boughtConfigurations)
    local configSet = Wearable.calculateRepairPrice(defaultIndex, item)
    local repaintPrice = Wearable.calculateRepaintPrice(defaultIndex, configItems)
    return {
        ["timeLeft"] = math.random(VehicleSaleSystem.MIN_GENERATED_ITEM_DURATION, VehicleSaleSystem.MAX_GENERATED_ITEM_DURATION),
        ["isGenerated"] = true,
        ["xmlFilename"] = storeItem.xmlFilename,
        ["boughtConfigurations"] = boughtConfigurations,
        ["configSetIndex"] = configSetIndex,
        ["age"] = index,
        ["price"] = Vehicle.calculateSellPrice(storeItem, index, includedInSet, defaultIndex, configSet, repaintPrice),
        ["damage"] = item,
        ["wear"] = configItems,
        ["operatingTime"] = includedInSet
    }
end
function VehicleSaleSystem:onVehicleWillSell(vehicle)
    if self.isEnabled then
        if self.mission.missionDynamicInfo.isMultiplayer then
            if self.numMultiplayerItems >= VehicleSaleSystem.MAX_MULTIPLAYER_ITEMS then
                return
            elseif math.random() >= VehicleSaleSystem.MULTIPLAYER_ACCEPT_CHANCE then
                return
            elseif g_storeManager:getItemByXMLFilename(vehicle.configFileName).price < VehicleSaleSystem.MINIMUM_ITEM_VALUE then
                return
            elseif vehicle.getCanBeAddedToSales == nil or vehicle:getCanBeAddedToSales() then
                local item = {
                    ["timeLeft"] = math.random(VehicleSaleSystem.MIN_MULTIPLAYER_ITEM_DURATION, VehicleSaleSystem.MAX_MULTIPLAYER_ITEM_DURATION),
                    ["isGenerated"] = false,
                    ["xmlFilename"] = vehicle.configFileName,
                    ["boughtConfigurations"] = table.clone(vehicle.boughtConfigurations, 3),
                    ["age"] = vehicle.age,
                    ["price"] = vehicle:getSellPrice() * VehicleSaleSystem.BUYPRICE_FACTOR,
                    ["damage"] = 0,
                    ["wear"] = 0,
                    ["operatingTime"] = vehicle.operatingTime
                }
                if vehicle.getDamageAmount ~= nil then
                    item.damage = vehicle:getDamageAmount()
                end
                if vehicle.getWearTotalAmount ~= nil then
                    item.wear = vehicle:getWearTotalAmount()
                end
                self:addSale(item)
            end
        else
            return
        end
    else
        return
    end
end
function VehicleSaleSystem:onVehicleBought(saleItem)
    self:removeSale(saleItem)
end
function VehicleSaleSystem.consoleCommandRefresh(_, amount)
    if g_currentMission ~= nil then
        local self = g_currentMission.vehicleSaleSystem
        if self ~= nil then
            local i = #self.items
            for i = i, 1, -1 do
                self:removeSale(self.items[i])
            end
            local i = 1
            for i = i, amount or VehicleSaleSystem.MAX_GENERATED_ITEMS do
                local randomVehicle = self:generateRandomVehicle()
                if randomVehicle ~= nil then
                    self:addSale(randomVehicle)
                    Logging.info("Generate Sale Item: %s age: %.1f price: %d damage: %.2f wear: %.2f", randomVehicle.xmlFilename, randomVehicle.age, randomVehicle.price, randomVehicle.damage, randomVehicle.wear)
                    for name, configurations in pairs(randomVehicle.boughtConfigurations) do
                        for id, _ in pairs(configurations) do
                            Logging.info("    Configuration: %s index %d", name, id)
                        end
                    end
                    if randomVehicle.configSetIndex ~= nil then
                        Logging.info("    ConfigurationSet: %d", randomVehicle.configSetIndex)
                    end
                end
            end
        end
    end
end
addConsoleCommand("gsVehicleSaleSystemRefresh", "Generate new set of sale items", "consoleCommandRefresh", VehicleSaleSystem)