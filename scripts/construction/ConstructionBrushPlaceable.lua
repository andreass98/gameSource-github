ConstructionBrushPlaceable = {}
local ConstructionBrushPlaceable_mt = Class(ConstructionBrushPlaceable, ConstructionBrush)
ConstructionBrushPlaceable.ERROR = {
    ["NOT_ENOUGH_MONEY"] = 200,
    ["NOT_ENOUGH_SLOTS"] = 201,
    ["CANNOT_BE_BOUGHT"] = 202,
    ["CANNOT_BE_PLACED_HERE"] = 203,
    ["PLAYER_COLLISION"] = 204,
    ["OBJECT_OVERLAP"] = 205,
    ["DEFORM_FAILED"] = 206,
    ["BLOCKED"] = 207
}
ConstructionBrushPlaceable.ERROR_MESSAGES = {
    [ConstructionBrushPlaceable.ERROR.NOT_ENOUGH_MONEY] = "ui_construction_notEnoughMoney",
    [ConstructionBrushPlaceable.ERROR.NOT_ENOUGH_SLOTS] = "ui_construction_notEnoughSlots",
    [ConstructionBrushPlaceable.ERROR.CANNOT_BE_BOUGHT] = "ui_construction_cannotBeBought",
    [ConstructionBrushPlaceable.ERROR.CANNOT_BE_PLACED_HERE] = "ui_construction_cannotBePlacedHere",
    [ConstructionBrushPlaceable.ERROR.PLAYER_COLLISION] = "ui_construction_collidesWithPlayer",
    [ConstructionBrushPlaceable.ERROR.OBJECT_OVERLAP] = "ui_construction_overlapsWithObject",
    [ConstructionBrushPlaceable.ERROR.DEFORM_FAILED] = "ui_construction_deformationFailed",
    [ConstructionBrushPlaceable.ERROR.BLOCKED] = "ui_construction_deformationBlocked"
}
ConstructionBrushPlaceable.LAST_SNAPPING_STATE = false
ConstructionBrushPlaceable.DISPLACEMENT_COST_PER_M3 = 5
ConstructionBrushPlaceable.MAX_ACTIVE_VALIDATIONS = 2
function ConstructionBrushPlaceable.new(subclass_mt, cursor)
    -- upvalues: (copy) ConstructionBrushPlaceable_mt
    local self = ConstructionBrushPlaceable:superClass().new(subclass_mt or ConstructionBrushPlaceable_mt, cursor)
    self.supportsPrimaryButton = true
    self.supportsPrimaryAxis = true
    self.primaryAxisIsContinuous = false
    self.supportsTertiaryButton = true
    self.configurations = nil
    self.placeableHasConfigs = false
    self.supportsSecondaryAxis = false
    self.secondaryAxisIsContinuous = false
    self.placeable = nil
    self.isLoading = false
    self.isPlacing = false
    self.offsetY = 0
    self.inputHeight = 0
    self.displacementCosts = 0
    self.colorIndex = 1
    self.placingText = g_i18n:getText("ui_construction_placingItem")
    self.loadingText = g_i18n:getText("ui_construction_loadingItem")
    self.errorText = nil
    self.errorEndTime = 0
    self.freeMode = false
    self.activeValidationCount = 0
    self.supportsSnapping = true
    self.snappingActive = ConstructionBrushPlaceable.LAST_SNAPPING_STATE
    self.snappingAngleDeg = 7.5
    self.snappingSize = 0.25
    self.requiredPermission = Farm.PERMISSION.BUY_PLACEABLE
    return self
end
function ConstructionBrushPlaceable:delete()
    ConstructionBrushPlaceable:superClass().delete(self)
end
function ConstructionBrushPlaceable:activate()
    ConstructionBrushPlaceable:superClass().activate(self)
    self.cursor:setRotationEnabled(true)
    self.cursor:setShape(GuiTopDownCursor.SHAPES.NONE)
    self.offsetY = 0
    self.coolDownTimer = 0
    self:loadPlaceable()
end
function ConstructionBrushPlaceable:deactivate()
    self:unloadPlaceable()
    self.coolDownTimer = 0
    if self.cursor ~= nil then
        self.cursor:setIsWaterDetectionActive(false)
    end
    ConstructionBrushPlaceable:superClass().deactivate(self)
end
function ConstructionBrushPlaceable:setPlaceableFilename(xmlFilename)
    if not self.isActive then
        self.placeableXMLFilename = xmlFilename
        self.storeItem = g_storeManager:getItemByXMLFilename(xmlFilename)
        self.placeableHasConfigs = false
        if self.storeItem.configurations ~= nil then
            for _, configs in pairs(self.storeItem.configurations) do
                if #configs > 1 then
                    self.placeableHasConfigs = true
                    return
                end
            end
        end
    end
end
function ConstructionBrushPlaceable:setParameters(filename)
    self:setPlaceableFilename(filename)
end
function ConstructionBrushPlaceable:copyState(from)
    self.freeMode = from.freeMode
end
function ConstructionBrushPlaceable:update(dt)
    ConstructionBrushPlaceable:superClass().update(self, dt)
    self:updateHeightFromInput(dt)
    if self.errorText ~= nil and self.errorEndTime < g_time then
        self.errorText = nil
    end
    if self.coolDownTimer > 0 then
        self.coolDownTimer = self.coolDownTimer - dt
    end
    self:updatePlaceablePosition()
end
function ConstructionBrushPlaceable:updateHeightFromInput(dt)
    self.offsetY = self.offsetY + self.inputHeight * dt * 0.005
    self.inputHeight = 0
end
function ConstructionBrushPlaceable:getSnappedRotation(rotY)
    if self.snappingActive then
        local degAngle = MathUtil.snapValue(math.deg(rotY), self.snappingAngleDeg)
        rotY = math.rad(degAngle)
    end
    if self.placeable ~= nil and self.placeable.getPlacementRotation ~= nil then
        local degAngle, degAngle
        degAngle, rotY, degAngle = self.placeable:getPlacementRotation(0, rotY, 0)
    end
    return rotY
end
function ConstructionBrushPlaceable:getSnappedPosition(x, y, z)
    if x == nil then
        return nil
    end
    if self.snappingActive then
        local snapSize = 1 / self.snappingSize
        x = math.floor(x * snapSize) / snapSize
        z = math.floor(z * snapSize) / snapSize
    end
    if self.placeable ~= nil and self.placeable.getPlacementPosition ~= nil then
        x, y, z = self.placeable:getPlacementPosition(x, y, z)
    end
    return x, y + self.offsetY, z
end
function ConstructionBrushPlaceable:getDisplacementCost()
    return self.displacementCosts
end
function ConstructionBrushPlaceable:getPrice()
    return g_currentMission.economyManager:getBuyPrice(self.storeItem) + self:getDisplacementCost()
end
function ConstructionBrushPlaceable:updatePlaceablePosition()
    if self.errorText == nil then
        if self.isPlacing then
            self.cursor:setMessage(self.placingText)
            return
        elseif self.isLoading then
            self.cursor:setMessage(self.loadingText)
            return
        elseif self.placeable == nil then
            self.cursor:setErrorMessage(g_i18n:getText("ui_construction_couldNotLoadItem"))
        else
            local x, y, z = self.cursor:getPosition()
            local rotY = self.cursor:getRotation()
            self.placeable:startPlacementCheck(x, y, z, rotY)
            local err, message, z = self:getSnappedPosition(x, y, z)
            local err = self:getSnappedRotation(rotY)
            if err ~= nil then
                self.placeable:setPreviewPosition(err, message, z, 0, err, 0)
                local err, message = self:verifyPlacement(err, message, z, err)
                if err == nil then
                    if self.displacementError == nil then
                        self.cursor:setMessage(g_i18n:formatMoney(self:getPrice(), 0, true, true))
                    else
                        self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrushPlaceable.ERROR_MESSAGES[self.displacementError]))
                    end
                else
                    if message == nil then
                        message = g_i18n:getText(ConstructionBrushPlaceable.ERROR_MESSAGES[err] or ConstructionBrush.ERROR_MESSAGES[err])
                    end
                    self.cursor:setErrorMessage(message)
                end
            end
            setVisibility(self.placeable.rootNode, self.cursor.isVisible)
        end
    else
        self.cursor:setErrorMessage(self.errorText)
        return
    end
end
function ConstructionBrushPlaceable:verifyPlacement(x, y, z, rotY)
    if not self:hasPlayerPermission() then
        return ConstructionBrush.ERROR.NO_PERMISSION
    end
    local enoughMoney = self:getPrice() <= g_currentMission:getMoney()
    local enoughSlots = g_currentMission.slotSystem:hasEnoughSlots(self.storeItem)
    if not enoughMoney then
        return ConstructionBrushPlaceable.ERROR.NOT_ENOUGH_MONEY
    end
    if not enoughSlots then
        return ConstructionBrushPlaceable.ERROR.NOT_ENOUGH_SLOTS
    end
    local canBuy, message = self.placeable:canBuy()
    if not canBuy then
        return ConstructionBrushPlaceable.ERROR.CANNOT_BE_BOUGHT, message
    end
    local canBePlaced, placingFailedMessage = self.placeable:getCanBePlacedAt(x, y, z, g_currentMission:getFarmId())
    if not canBePlaced then
        return ConstructionBrushPlaceable.ERROR.CANNOT_BE_PLACED_HERE, placingFailedMessage
    end
    if self.placeable.getIsOnOwnedFarmland ~= nil and not self.placeable:getIsOnOwnedFarmland(x, y, z, rotY) then
        return ConstructionBrush.ERROR.LAND_UNOWNED
    end
    if self.placeable.getHasOverlapWithZones ~= nil and self.placeable:getHasOverlapWithZones(g_currentMission.restrictedZones, x, y, z, rotY) then
        return ConstructionBrush.ERROR.RESTRICTED_ZONE
    end
    if self.placeable.getHasOverlapWithPlaces ~= nil then
        if self.placeable:getHasOverlapWithPlaces(g_currentMission.storeSpawnPlaces, x, y, z, rotY) then
            return ConstructionBrush.ERROR.STORE_PLACE
        end
        if self.placeable:getHasOverlapWithPlaces(g_currentMission.loadSpawnPlaces, x, y, z, rotY) then
            return ConstructionBrush.ERROR.SPAWN_PLACE
        end
    end
    if not self.freeMode and self.placeable.getHasOverlap ~= nil then
        local hasOverlap, node = self.placeable:getHasOverlap(x, y, z, rotY)
        if hasOverlap then
            if node ~= nil then
                if g_currentMission.players[node] ~= nil then
                    return ConstructionBrushPlaceable.ERROR.PLAYER_COLLISION
                end
            end
            return ConstructionBrushPlaceable.ERROR.OBJECT_OVERLAP
        end
    end
    if not self.freeMode and (self.placeable.getRequiresLeveling ~= nil and (self.placeable:getRequiresLeveling() and self.activeValidationCount < ConstructionBrushPlaceable.MAX_ACTIVE_VALIDATIONS)) then
        self.terrainValidationPending = true
        self.activeValidationCount = self.activeValidationCount + 1
        self.placeable:applyDeformation(true, function(...)
            -- upvalues: (copy) self
            self:onTerrainValidationFinished(...)
        end)
    end
    if self.freeMode then
        self.displacementCosts = 0
    end
    return nil
end
function ConstructionBrushPlaceable:onTerrainValidationFinished(errorCode, displacedVolume, _)
    self.activeValidationCount = self.activeValidationCount - 1
    self.terrainValidationPending = false
    if errorCode == TerrainDeformation.STATE_CANCELLED then
        return
    elseif errorCode == TerrainDeformation.STATE_SUCCESS then
        self.displacementCosts = displacedVolume * ConstructionBrushPlaceable.DISPLACEMENT_COST_PER_M3
        self.displacementError = nil
        return
    else
        self.displacementCosts = 0
        if errorCode == TerrainDeformation.STATE_FAILED_BLOCKED then
            self.displacementError = ConstructionBrushPlaceable.ERROR.BLOCKED
            return
        elseif errorCode == TerrainDeformation.STATE_FAILED_COLLIDE_WITH_OBJECT then
            self.displacementError = ConstructionBrushPlaceable.ERROR.OBJECT_OVERLAP
            return
        elseif errorCode == TerrainDeformation.STATE_FAILED_TO_DEFORM then
            self.displacementError = ConstructionBrushPlaceable.ERROR.DEFORM_FAILED
        end
    end
end
function ConstructionBrushPlaceable:loadPlaceable(data)
    if self.placeableXMLFilename == nil then
        Logging.warning("Placeable brush has no placeable set")
        return
    elseif self.storeItem == nil then
        Logging.warning("Placeable brush has undefined placeable storeitem")
    else
        self.isLoading = true
        if data == nil then
            data = PlaceableLoadingData.new()
            data:setPosition(0, -500, 0)
            data:setRotation(0, 0, 0)
        end
        data:setStoreItem(self.storeItem)
        if data ~= nil then
            data:setRotation(0, self.cursor:getRotation(), 0)
        end
        data:load(self.loadedPlaceable, self)
        data:setPropertyState(PlaceablePropertyState.CONSTRUCTION_PREVIEW)
        data:setOwnerFarmId(g_localPlayer.farmId)
        data:setIsRegistered(false)
    end
end
function ConstructionBrushPlaceable:loadedPlaceable(placeable, loadingState, _)
    self.isLoading = false
    self.loadingPlaceable = nil
    if loadingState == PlaceableLoadingState.ERROR then
        Logging.warning("Failed to load placeable")
        if placeable ~= nil then
            placeable:delete()
        end
        return
    elseif placeable == nil then
        Logging.warning("Failed to load placeable")
        return
    elseif self.isActive then
        if placeable.setColor ~= nil then
            placeable:setColor(self.colorIndex)
        end
        if self.cursor ~= nil then
            if placeable.getRotationSnapAngle ~= nil then
                local snapAngle = placeable:getRotationSnapAngle()
                if snapAngle ~= 0 then
                    self.cursor:setSnapAngle(snapAngle)
                end
            end
            if placeable.getIsPlacedOnWater ~= nil and placeable:getIsPlacedOnWater() then
                self.cursor:setIsWaterDetectionActive(true)
            end
        end
        self:setInputTextDirty()
        self.placeable = placeable
    else
        placeable:delete()
    end
end
function ConstructionBrushPlaceable:unloadPlaceable()
    if self.placeable ~= nil then
        self.placeable:delete()
        self.placeable = nil
        self.isLoading = false
        self.isPlacing = false
    end
    if self.loadingPlaceable ~= nil then
        self.loadingPlaceable:delete()
    end
    if self.cursor ~= nil then
        self.cursor:setSnapAngle(nil)
    end
end
function ConstructionBrushPlaceable:onButtonPrimary()
    if self.coolDownTimer > 0 then
        return
    elseif self.placeable == nil then
        return
    elseif self.isLoading or (self.isPlacing or self.displacementError ~= nil) then
        return
    else
        local displacementCosts = self:getDisplacementCost()
        local realignToTerrainAfterLeveing = true
        if self.placeable.getRequiresRealignAfterLeveling ~= nil and not self.placeable:getRequiresRealignAfterLeveling() then
            realignToTerrainAfterLeveing = false
        end
        local x, y, z = self.cursor:getPosition()
        local rotY = self.cursor:getRotation()
        self.placeable:startPlacementCheck(x, y, z, rotY)
        local err, data, z = self:getSnappedPosition(x, y, z)
        local err = self:getSnappedRotation(rotY)
        if err ~= nil then
            if self:verifyPlacement(err, data, z, err) == nil then
                self.isPlacing = true
                local data = BuyPlaceableData.new()
                data:setStoreItem(self.storeItem)
                data:setConfigurations(self.configurations or {})
                data:setConfigurationData(self.configurationData)
                data:setPosition(err, data, z)
                data:setRotation(0, err, 0)
                data:setIsFreeOfCharge(false)
                data:setOwnerFarmId(g_localPlayer.farmId)
                data:setDisplacementCosts(displacementCosts)
                data:setModifyTerrain(not self.freeMode)
                data:setRealignToTerrainAfterLeveling(realignToTerrainAfterLeveing)
                data:updatePrice()
                g_messageCenter:subscribe(BuyPlaceableEvent, self.onPlaceableCreated, self)
                g_client:getServerConnection():sendEvent(BuyPlaceableEvent.new(data))
                if self.placeable.playPlaceSound ~= nil then
                    self.placeable:playPlaceSound()
                end
                return true
            end
        end
    end
end
function ConstructionBrushPlaceable:onButtonTertiary()
    self.freeMode = not self.freeMode
    self:setInputTextDirty()
    if self.freeMode and not g_gameSettings:getValue(GameSettings.SETTING.SHOWN_FREEMODE_WARNING) then
        InfoDialog.show(g_i18n:getText("ui_constructionFreeModeWarning"))
        g_gameSettings:setValue(GameSettings.SETTING.SHOWN_FREEMODE_WARNING, true)
    end
end
function ConstructionBrushPlaceable:onButtonSnapping()
    self.snappingActive = not self.snappingActive
    ConstructionBrushPlaceable.LAST_SNAPPING_STATE = self.snappingActive
    self:setInputTextDirty()
end
function ConstructionBrushPlaceable:onAxisPrimary(inputValue)
    if self.placeable == nil then
        return
    elseif self.placeable.getAvailableColors ~= nil then
        local colors = self.placeable:getAvailableColors()
        if #colors > 0 then
            self.colorIndex = self.colorIndex + inputValue
            if self.colorIndex > #colors then
                self.colorIndex = 1
            elseif self.colorIndex < 1 then
                self.colorIndex = #colors
            end
            self.placeable:setColor(self.colorIndex)
        end
    end
end
function ConstructionBrushPlaceable:onAxisSecondary(inputValue)
    self.inputHeight = inputValue
end
function ConstructionBrushPlaceable:onPlaceableCreated(errorCode, _, _)
    self.isPlacing = false
    local errorText = nil
    if errorCode == BuyPlaceableEvent.STATE_SUCCESS then
        self.coolDownTimer = 500
    elseif errorCode == BuyPlaceableEvent.STATE_FAILED_TO_LOAD then
        errorText = g_i18n:getText("ui_construction_couldNotLoadItem")
    elseif errorCode == BuyPlaceableEvent.STATE_NO_SPACE then
        errorText = g_i18n:getText("ui_construction_spaceAlreadyOccupied")
    elseif errorCode == BuyPlaceableEvent.STATE_NO_PERMISSION then
        errorText = g_i18n:getText("ui_construction_noBuildPermission")
    elseif errorCode == BuyPlaceableEvent.STATE_NOT_ENOUGH_MONEY then
        errorText = g_i18n:getText("ui_construction_notEnoughMoney")
    elseif errorCode == BuyPlaceableEvent.STATE_TERRAIN_DEFORMATION_FAILED then
        errorText = g_i18n:getText("ui_construction_deformationFailed")
    end
    if errorText ~= nil then
        self.errorText = errorText
        self.errorEndTime = g_time + 3000
    end
    g_messageCenter:unsubscribe(BuyPlaceableEvent, self)
end
function ConstructionBrushPlaceable:getButtonPrimaryText()
    return "$l10n_input_CONSTRUCTION_PLACE"
end
function ConstructionBrushPlaceable:getButtonTertiaryText()
    return string.format(g_i18n:getText("input_CONSTRUCTION_FREEMODE"), g_i18n:getText(self.freeMode and "ui_on" or "ui_off"))
end
function ConstructionBrushPlaceable:getAxisPrimaryText()
    return self.placeable ~= nil and (self.placeable.getHasColors ~= nil and self.placeable:getHasColors()) and "$l10n_input_CONSTRUCTION_CHANGE_COLOR" or nil
end
function ConstructionBrushPlaceable:getAxisSecondaryText()
    return "$l10n_input_CONSTRUCTION_HEIGHT"
end
function ConstructionBrushPlaceable:getButtonSnappingText()
    return string.format("%s (%s)", g_i18n:getText("input_CONSTRUCTION_ACTION_SNAPPING"), g_i18n:getText(self.snappingActive and "ui_on" or "ui_off"))
end