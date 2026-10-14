PlaceablePalletBuyingStation = {}
source("dataS/scripts/placeables/specializations/activatables/PalletBuyingStationActivatable.lua")
source("dataS/scripts/placeables/specializations/events/PlaceablePalletBuyEvent.lua")
function PlaceablePalletBuyingStation.prerequisitesPresent(specializations)
    return true
end
function PlaceablePalletBuyingStation.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceablePalletBuyingStation)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceablePalletBuyingStation)
end
function PlaceablePalletBuyingStation.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "openShop", PlaceablePalletBuyingStation.openShop)
    SpecializationUtil.registerFunction(placeableType, "onActivationTriggerCallback", PlaceablePalletBuyingStation.onActivationTriggerCallback)
    SpecializationUtil.registerFunction(placeableType, "shopCallback", PlaceablePalletBuyingStation.shopCallback)
    SpecializationUtil.registerFunction(placeableType, "tryToSpawnPallets", PlaceablePalletBuyingStation.tryToSpawnPallets)
    SpecializationUtil.registerFunction(placeableType, "onPalletBought", PlaceablePalletBuyingStation.onPalletBought)
    SpecializationUtil.registerFunction(placeableType, "getHasPalletForFillType", PlaceablePalletBuyingStation.getHasPalletForFillType)
    SpecializationUtil.registerFunction(placeableType, "getEffectivePricePerPallet", PlaceablePalletBuyingStation.getEffectivePricePerPallet)
end
function PlaceablePalletBuyingStation.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("PlaceablePalletBuyingStation")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".palletBuyingStation#triggerNode", "trigger node")
    schema:register(XMLValueType.STRING, basePath .. ".palletBuyingStation#triggerText", "trigger text")
    schema:register(XMLValueType.STRING, basePath .. ".palletBuyingStation.fillType(?)#name", "Fill type name")
    schema:register(XMLValueType.FLOAT, basePath .. ".palletBuyingStation.fillType(?)#priceScale", "Price scale", 1)
    PalletSpawner.registerXMLPaths(schema, basePath .. ".palletBuyingStation.palletSpawner")
    schema:setXMLSpecializationType()
end
function PlaceablePalletBuyingStation:onLoad(_)
    local spec = self.spec_palletBuyingStation
    spec.triggerNode = self.xmlFile:getValue("placeable.palletBuyingStation#triggerNode", nil, self.components, self.i3dMappings)
    if spec.triggerNode ~= nil then
        addTrigger(spec.triggerNode, "onActivationTriggerCallback", self)
        local palletSpawnerKey = "placeable.palletBuyingStation.palletSpawner"
        if self.xmlFile:hasProperty(palletSpawnerKey) then
            spec.palletSpawner = PalletSpawner.new(self.baseDirectory)
            if not spec.palletSpawner:load(self.components, self.xmlFile, "placeable.palletBuyingStation.palletSpawner", self.customEnvironment, self.i3dMappings) then
                Logging.xmlError(self.xmlFile, "Unable to load pallet spawner %s", palletSpawnerKey)
                return
            end
        end
        spec.pallets = {}
        spec.fillTypeIndexToPallet = {}
        local i = 0
        while true do
            local fillTypeKey = string.format("placeable.palletBuyingStation.fillType(%d)", i)
            if not self.xmlFile:hasProperty(fillTypeKey) then
                break
            end
            local fillTypeStr = self.xmlFile:getValue(fillTypeKey .. "#name")
            local fillType = g_fillTypeManager:getFillTypeByName(fillTypeStr)
            if fillType ~= nil then
                local fillTypeIndex = fillType.index
                local storeItem = g_storeManager:getItemByXMLFilename(fillType.palletFilename)
                local priceScale = self.xmlFile:getValue(fillTypeKey .. "#priceScale", 1)
                local pallet = {
                    ["imageFilename"] = storeItem.imageFilename,
                    ["title"] = fillType.title,
                    ["price"] = MathUtil.round(storeItem.price * priceScale * EconomyManager.getPriceMultiplier(fillTypeIndex), 0),
                    ["fillTypeIndex"] = fillTypeIndex
                }
                table.insert(spec.pallets, pallet)
                spec.fillTypeIndexToPallet[fillTypeIndex] = pallet
            end
            i = i + 1
        end
        local fillTypeKey = g_i18n:getText(self.xmlFile:getValue("placeable.palletBuyingStation#triggerText", "palletShop_open"), self.customEnvironment)
        spec.activatable = PalletBuyingStationActivatable.new(self, fillTypeKey)
        g_currentMission.storageSystem:addPalletBuyingStation(self)
        return true
    end
    Logging.xmlError(self.xmlFile, "Missing triggerNode for pallet buying station %s", "placeable.palletBuyingStation")
end
function PlaceablePalletBuyingStation:onDelete()
    local spec = self.spec_palletBuyingStation
    g_currentMission.storageSystem:removePalletBuyingStation(self)
    if spec.palletSpawner ~= nil then
        spec.palletSpawner:delete()
    end
    if spec.triggerNode ~= nil then
        removeTrigger(spec.triggerNode)
    end
end
function PlaceablePalletBuyingStation:onActivationTriggerCallback(_, otherId, onEnter, onLeave, _, _)
    if (onEnter or onLeave) and (g_localPlayer and g_localPlayer.rootNode == otherId) then
        if onEnter then
            if Platform.isMobile and self.spec_palletBuyingStation.activatable:getIsActivatable() then
                spec.activatable:run()
            else
                g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
            end
        end
        if onLeave then
            g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
        end
    end
end
function PlaceablePalletBuyingStation:getHasPalletForFillType(fillTypeIndex)
    return self.spec_palletBuyingStation.fillTypeIndexToPallet[fillTypeIndex]
end
function PlaceablePalletBuyingStation:getEffectivePricePerPallet(fillTypeIndex)
    local pallet = self.spec_palletBuyingStation.fillTypeIndexToPallet[fillTypeIndex]
    if pallet ~= nil then
        return pallet.price
    end
end
function PlaceablePalletBuyingStation:openShop()
    if g_currentMission:getHasPlayerPermission(Farm.PERMISSION.BUY_VEHICLE) then
        PalletShopDialog.show(self.shopCallback, self, self.spec_palletBuyingStation.pallets, 10, self.storeItem.name)
    else
        InfoDialog.show(g_i18n:getText("shop_messageNoPermissionGeneral"))
    end
end
function PlaceablePalletBuyingStation:shopCallback(selectedIndex, quantity)
    if selectedIndex == nil or quantity == nil then
        return
    else
        local pallet = self.spec_palletBuyingStation.pallets[selectedIndex]
        if pallet == nil then
            return
        else
            local totalPrice = pallet.price * quantity
            local enoughMoney = true
            if totalPrice > 0 then
                enoughMoney = totalPrice <= g_currentMission:getMoney()
            end
            if enoughMoney then
                if g_currentMission.slotSystem:getCanAddLimitedObjects(SlotSystem.LIMITED_OBJECT_PALLET, quantity) then
                    local text = string.format(g_i18n:getText("shop_doYouWantToBuyPallet", self.customEnvironment), g_i18n:formatMoney(totalPrice, 0, true, true))
                    YesNoDialog.show(function(yes)
                        -- upvalues: (copy) self, (copy) pallet, (copy) quantity
                        if yes then
                            MessageDialog.show(g_i18n:getText("shop_buyingPallets", self.customEnvironment))
                            g_client:getServerConnection():sendEvent(PlaceablePalletBuyEvent.new(self, g_localPlayer.farmId, pallet.fillTypeIndex, quantity, pallet.price))
                            g_messageCenter:subscribeOneshot(PlaceablePalletBuyEvent, PlaceablePalletBuyingStation.onPalletBought, self)
                        end
                    end, nil, text)
                else
                    InfoDialog.show(g_i18n:getText("shop_messageNotEnoughSlotsToBuy", self.customEnvironment))
                end
            else
                InfoDialog.show(g_i18n:getText("shop_messageNotEnoughMoneyToBuy", self.customEnvironment))
                return
            end
        end
    end
end
function PlaceablePalletBuyingStation:tryToSpawnPallets(farmId, fillTypeIndex, quantity, callback)
    local spec = self.spec_palletBuyingStation
    local numBoughtPallets = 0
    if spec.palletSpawner ~= nil then
        local function onPalletsSpawned(_, pallet, status, fillType)
            -- upvalues: (ref) numBoughtPallets, (copy) farmId, (copy) quantity, (copy) spec, (copy) fillTypeIndex, (copy) onPalletsSpawned, (copy) callback
            if pallet == nil then
                callback(status, numBoughtPallets)
                return
            else
                numBoughtPallets = numBoughtPallets + 1
                local fillUnitIndex = pallet:getFirstValidFillUnitToFill(fillType)
                if fillUnitIndex then
                    pallet:addFillUnitFillLevel(farmId, fillUnitIndex, math.huge, fillType, ToolType.UNDEFINED)
                end
                if numBoughtPallets < quantity then
                    spec.palletSpawner:spawnPallet(farmId, fillTypeIndex, onPalletsSpawned, nil)
                else
                    callback(status, numBoughtPallets)
                end
            end
        end
        spec.palletSpawner:spawnPallet(farmId, fillTypeIndex, onPalletsSpawned, nil)
    end
end
function PlaceablePalletBuyingStation:onPalletBought(errorCode, numBoughtPallets)
    MessageDialog.hide()
    if errorCode == PalletSpawner.RESULT_SUCCESS then
        InfoDialog.show(g_i18n:getText("shop_messageAllPalletsBought", self.customEnvironment))
    else
        local text = g_i18n:getText("shop_messagePalletsCouldNotBeLoaded", self.customEnvironment)
        if errorCode == PalletSpawner.RESULT_NO_SPACE then
            text = g_i18n:getText("shop_messageNotEnoughSpaceToBuyAllPallets", self.customEnvironment)
        elseif errorCode == PalletSpawner.PALLET_LIMITED_REACHED then
            text = g_i18n:getText("shop_messageNotEnoughSlotsToBuyAllPallets", self.customEnvironment)
        end
        if numBoughtPallets > 0 then
            text = text .. "\n" .. string.format(g_i18n:getText("shop_buyingPalletsAmount", self.customEnvironment), numBoughtPallets)
        end
        InfoDialog.show(text, nil, nil, DialogElement.TYPE_WARNING)
    end
end