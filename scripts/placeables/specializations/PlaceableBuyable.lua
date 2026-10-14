PlaceableBuyable = {}
source("dataS/scripts/placeables/specializations/activatables/BuyBuildingActivatable.lua")
function PlaceableBuyable.prerequisitesPresent(specializations)
    return true
end
function PlaceableBuyable.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onBuyingTriggerCallback", PlaceableBuyable.onBuyingTriggerCallback)
    SpecializationUtil.registerFunction(placeableType, "setIsBuyingTriggerActive", PlaceableBuyable.setIsBuyingTriggerActive)
    SpecializationUtil.registerFunction(placeableType, "buyRequest", PlaceableBuyable.buyRequest)
    SpecializationUtil.registerFunction(placeableType, "getHasBuyingTrigger", PlaceableBuyable.getHasBuyingTrigger)
end
function PlaceableBuyable.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableBuyable.setOwnerFarmId)
end
function PlaceableBuyable.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableBuyable)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableBuyable)
end
function PlaceableBuyable.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Buyable")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".buyable.trigger#node", "Buying trigger", nil, false)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".buyable.marker#node", "Marker node", nil, false)
    schema:setXMLSpecializationType()
end
function PlaceableBuyable:onLoad(_)
    local spec = self.spec_buyable
    spec.activatable = BuyBuildingActivatable.new(self)
    spec.triggerNode = self.xmlFile:getValue("placeable.buyable.trigger#node", nil, self.components, self.i3dMappings)
    if spec.triggerNode ~= nil then
        addTrigger(spec.triggerNode, "onBuyingTriggerCallback", self)
    end
    spec.markerNode = self.xmlFile:getValue("placeable.buyable.marker#node", nil, self.components, self.i3dMappings)
    spec.isTriggerActive = true
end
function PlaceableBuyable:onDelete()
    local spec = self.spec_buyable
    g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    spec.activatable = nil
    if spec.markerNode ~= nil then
        g_currentMission:removeTriggerMarker(spec.markerNode)
    end
    if spec.triggerNode ~= nil then
        removeTrigger(spec.triggerNode)
    end
end
function PlaceableBuyable:getHasBuyingTrigger()
    return self.spec_buyable.triggerNode ~= nil
end
function PlaceableBuyable:setIsBuyingTriggerActive(isActive)
    local spec = self.spec_buyable
    spec.isTriggerActive = isActive
    if spec.markerNode ~= nil then
        setVisibility(spec.markerNode, isActive)
        if isActive then
            g_currentMission:addTriggerMarker(spec.markerNode)
            return
        end
        g_currentMission:removeTriggerMarker(spec.markerNode)
    end
end
function PlaceableBuyable:onBuyingTriggerCallback(_, otherId, onEnter, onLeave, _, _)
    if (onEnter or onLeave) and (g_localPlayer and g_localPlayer.rootNode == otherId) then
        local spec = self.spec_buyable
        if onEnter and spec.isTriggerActive then
            if Platform.gameplay.autoActivateTrigger and spec.activatable:getIsActivatable() then
                spec.activatable:run()
                return
            end
            g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
        end
        if onLeave then
            g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
        end
    end
end
function PlaceableBuyable:buyRequest(requestCallback, target)
    if g_guidedTourManager:getIsTourRunning() then
        InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
    else
        local playerFarmId = g_currentMission:getFarmId()
        local price = self:getPrice()
        if self.buysFarmland then
            local farmlandId = self:getFarmlandId()
            local farmland = g_farmlandManager:getFarmlandById(farmlandId)
            if farmland ~= nil and g_farmlandManager:getFarmlandOwner(farmlandId) ~= playerFarmId then
            end
        end
        local function farmlandId(statusCode)
            -- upvalues: (copy) self
            if statusCode ~= nil then
                local dialogArgs = BuyExistingPlaceableEvent.DIALOG_MESSAGES[statusCode]
                if dialogArgs ~= nil then
                    InfoDialog.show(g_i18n:getText(dialogArgs.text), nil, nil, dialogArgs.dialogType)
                end
            end
            g_messageCenter:unsubscribe(BuyExistingPlaceableEvent, self)
            self:onBuy()
        end
        YesNoDialog.show(function(yes)
            -- upvalues: (copy) farmlandId, (copy) self, (copy) playerFarmId, (copy) requestCallback, (copy) target
            if yes then
                g_messageCenter:subscribe(BuyExistingPlaceableEvent, farmlandId)
                g_client:getServerConnection():sendEvent(BuyExistingPlaceableEvent.new(self, playerFarmId))
            end
            if requestCallback ~= nil then
                if target ~= nil then
                    target:requestCallback(yes)
                    return
                end
                requestCallback(yes)
            end
        end, nil, string.format(g_i18n:getText("dialog_buyBuildingFor"), self:getName(), g_i18n:formatMoney(price, 0, true)))
    end
end
function PlaceableBuyable:setOwnerFarmId(superFunc, farmId, noEventSend)
    superFunc(self, farmId, noEventSend)
    self:setIsBuyingTriggerActive(farmId == AccessHandler.EVERYONE)
end