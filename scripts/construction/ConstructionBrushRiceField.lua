ConstructionBrushRiceField = {}
local ConstructionBrushRiceField_mt = Class(ConstructionBrushRiceField, ConstructionBrush)
ConstructionBrushRiceField.ERROR = {
    ["MININUM_LENGTH"] = 1,
    ["COLLISION"] = 2,
    ["NOT_ENOUGH_MONEY"] = 3,
    ["CANNOT_BE_PLACED_HERE"] = 4
}
ConstructionBrushRiceField.ERROR_MESSAGES = {
    [ConstructionBrushRiceField.ERROR.MININUM_LENGTH] = "ui_construction_distanceTooShort",
    [ConstructionBrushRiceField.ERROR.COLLISION] = "ui_construction_collidesWithItem",
    [ConstructionBrushRiceField.ERROR.NOT_ENOUGH_MONEY] = "ui_construction_notEnoughMoney",
    [ConstructionBrushRiceField.ERROR.CANNOT_BE_PLACED_HERE] = "ui_construction_cannotBePlacedHere"
}
ConstructionBrushRiceField.HEIGHT_CHANGE_INCREMENT = 0.25
function ConstructionBrushRiceField.new(subclass_mt, cursor)
    -- upvalues: (copy) ConstructionBrushRiceField_mt
    local self = ConstructionBrushRiceField:superClass().new(subclass_mt or ConstructionBrushRiceField_mt, cursor)
    self.overlapCollisionMask = CollisionFlag.WATER + CollisionFlag.PLACEMENT_BLOCKING
    self.supportsPrimaryButton = true
    self.supportsSecondaryButton = true
    self.supportsTertiaryButton = true
    self.supportsPrimaryAxis = true
    self.requiredPermission = Farm.PERMISSION.BUY_PLACEABLE
    self.parallelSnappingEnabled = false
    self.doFindPlaceable = false
    self.supportsSnapping = true
    self.snappingActive = ConstructionBrushRiceField.LAST_SNAPPING_STATE
    self.minDistanceToExistingFields = 3
    self.isVertexValid = false
    self.pendingCreation = false
    self.heightMapUnitSize = getTerrainHeightmapUnitSize(g_terrainNode)
    self.lineVisualization = Line3D.new()
    self.debugBox = DebugBox.new()
    return self
end
function ConstructionBrushRiceField:delete()
    ConstructionBrushRiceField:superClass().delete(self)
    self.doFindPlaceable = false
    self.lineVisualization:delete()
end
function ConstructionBrushRiceField:activate()
    ConstructionBrushRiceField:superClass().activate(self)
    self.cursor:setRotationEnabled(false)
    self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
    self.cursor:setShapeSize(0.5)
    self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SUCCESS)
    self.cursor:setTerrainOnly(true)
    self:acquirePlaceable()
end
function ConstructionBrushRiceField:deactivate()
    self.lineVisualization:clearVisualization()
    self:releasePlaceable()
    self.doFindPlaceable = false
    self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SELECT, nil)
    ConstructionBrushRiceField:superClass().deactivate(self)
end
function ConstructionBrushRiceField:setFilename(xmlFilename)
    if not self.isActive then
        self.xmlFilename = xmlFilename
    end
end
function ConstructionBrushRiceField:setParameters(filename)
    self:setFilename(filename)
end
function ConstructionBrushRiceField:setStoreItem(storeItem)
    if not self.isActive then
        self.storeItem = storeItem
    end
end
function ConstructionBrushRiceField:canCancel()
    return self.currentField ~= nil and self.currentField.polygon:getNumVertices() > 0
end
function ConstructionBrushRiceField:acquirePlaceable()
    if self.xmlFilename == nil then
        Logging.warning("Rice Field brush has no placeable set")
    else
        self.placeable = self:findPlaceable()
        self:setInputTextDirty()
        if self.placeable == nil then
            local data = BuyPlaceableData.new()
            data:setStoreItem((g_storeManager:getItemByXMLFilename(self.xmlFilename)))
            data:setPosition(0, 0, 0)
            data:setRotation(0, 0, 0)
            data:setConfigurations({})
            data:setOwnerFarmId(g_localPlayer.farmId)
            data:setDisplacementCosts(0)
            data:setModifyTerrain(false)
            data:setIsFreeOfCharge(true)
            g_messageCenter:subscribe(BuyPlaceableEvent, self.onPlaceableCreated, self)
            g_client:getServerConnection():sendEvent(BuyPlaceableEvent.new(data))
        end
    end
end
function ConstructionBrushRiceField:findPlaceable()
    local farmId = g_currentMission:getFarmId()
    return g_currentMission.placeableSystem:getExistingPlaceableByXMLFilename(self.xmlFilename, farmId, true)
end
function ConstructionBrushRiceField:onPlaceableCreated(errorCode, _)
    g_messageCenter:unsubscribe(BuyPlaceableEvent, self)
    if errorCode == BuyPlaceableEvent.STATE_FAILED_TO_LOAD then
        self.cursor:setErrorMessage("Loading failed")
    else
        self.doFindPlaceable = true
    end
end
function ConstructionBrushRiceField:releasePlaceable()
    if self.placeable ~= nil then
        if not self.placeable:getHasValidFields() then
            g_client:getServerConnection():sendEvent(SellPlaceableEvent.new(self.placeable, true, false, false))
        end
        self.placeable = nil
    end
end
function ConstructionBrushRiceField:getSnappedCursorPosition()
    local x, y, z = self.cursor:getHitTerrainPosition()
    if x ~= nil and self.snappingActive then
        local x = MathUtil.snapValue(x, self.heightMapUnitSize) + 0
        local z = MathUtil.snapValue(z, self.heightMapUnitSize) + 0
        if self.currentField == nil then
        else
            y = self.currentField.height
            local vx, lvx, lvz
            vx, z, lvx, lvz = self.placeable:getFirstAndLastVertex(self.currentField)
            x = lvx or vx
            if x == nil then
            else
                if math.abs((lvz or z) - z) < math.abs(x - x) then
                    z = cvz
                end
                if lvx == nil then
                elseif math.abs(vx - x) < 2 then
                    x = vx
                elseif math.abs(z - z) >= 2 then
                end
            end
        end
    end
    return x, y, z, false
end
function ConstructionBrushRiceField:getLimitedSnappedCursorPosition()
    local x, y, z, snapped = self:getSnappedCursorPosition()
    return x, y, z, snapped
end
function ConstructionBrushRiceField:update(dt)
    ConstructionBrushRiceField:superClass().update(self, dt)
    self.cursor:setMessage("")
    self.lineVisualization:clearVisualization()
    self.finalVertexX = nil
    self.finalVertexZ = nil
    if self.currentField ~= nil then
        local numEdges = self.currentField.polygon:getNumEdges()
        local canFinish = self.placeable:getCanFinish(self.currentField, self.snappingActive)
        if canFinish then
            local fvx, fvz, lvx, lvz = self.placeable:getFirstAndLastVertex(self.currentField)
            self.lineVisualization:visualizeLine(lvx, self.currentField.height + 0.05, lvz, fvx, self.currentField.height + 0.05, fvz, false, Color.PRESETS.GREEN)
        elseif numEdges >= 2 then
            local fvx, fvz, lvx, lvz = self.placeable:getFirstAndLastVertex(self.currentField)
            if self.snappingActive then
                local z, x
                if (function(x, z)
                    -- upvalues: (copy) self, (copy) fvx, (copy) fvz, (copy) lvx, (copy) lvz
                    for _, x1, z1, x2, z2 in self.currentField.polygon:iteratorEdges() do
                        if (x1 ~= x or z1 ~= z) and (x2 ~= x or z2 ~= z) then
                            if MathUtil.getAreLineSegmentsIntersecting(x1, z1, x2, z2, fvx, fvz, x, z, true) then
                                return false
                            end
                            if MathUtil.getAreLineSegmentsIntersecting(x1, z1, x2, z2, lvx, lvz, x, z, true) then
                                return false
                            end
                        end
                    end
                    return self.placeable:getCanAddVertex(self.currentField, x, z) and true or false
                end)(fvx, lvz) then
                    z = lvz
                    x = fvx
                elseif getIsNewVertexValid(lvx, fvz) then
                    z = fvz
                    x = lvx
                else
                    x = nil
                    z = nil
                end
                if x ~= nil then
                    self.lineVisualization:visualizeLine(x, height, z, fvx, height, fvz, false, Color.PRESETS.GREEN)
                    self.lineVisualization:visualizeLine(x, height, z, lvx, height, lvz, false, Color.PRESETS.GREEN)
                    self.finalVertexX = x
                    self.finalVertexZ = z
                end
            end
        end
        for lvz, getIsNewVertexValid, getFinalVertex, x, z in self.currentField.polygon:iteratorEdges(nil, 1) do
            self.lineVisualization:visualizeLine(getIsNewVertexValid, height, getFinalVertex, x, height, z, false, canFinish and Color.PRESETS.GREEN or Color.PRESETS.ORANGE)
        end
    end
    if self.doFindPlaceable then
        self.placeable = self:findPlaceable()
        if self.placeable == nil then
            return
        end
        self.doFindPlaceable = false
    end
    local numEdges, height, canFinish, fvx, fvz = self:getLimitedSnappedCursorPosition()
    if numEdges == nil then
        return
    else
        local lvx = self:verifyAccess(numEdges, height, canFinish)
        if lvx == nil then
            if self.placeable == nil then
                return
            elseif self.currentField == nil and not self.placeable:getCanCreateNewField() then
                self.cursor:setErrorMessage(g_i18n:getText("ui_construction_maxNumberOfFieldsReached"))
            else
                if self.currentField ~= nil then
                    local lvz, getIsNewVertexValid = self.placeable:getCanAddVertex(self.currentField, numEdges, canFinish)
                    if not lvz then
                        self.cursor:setErrorMessage(getIsNewVertexValid)
                        return
                    end
                    if self.currentField.polygon:getIsCircleIntersecting(numEdges, canFinish, 1) then
                        return
                    end
                    local getFinalVertex, x, z, ix = self.placeable:getFirstAndLastVertex(self.currentField)
                    local getFinalVertex = z or getFinalVertex
                    local x = ix or x
                    if getFinalVertex ~= nil then
                        local ry = MathUtil.getYRotationFromDirection(numEdges - getFinalVertex, canFinish - x)
                        local width = MathUtil.vector2Length(numEdges - getFinalVertex, canFinish - x)
                        local height = self.currentField.height
                        self.lineVisualization:visualizeLine(getFinalVertex, height, x, numEdges, height, canFinish, false, self.isVertexValid and Color.PRESETS.ORANGE or Color.PRESETS.RED)
                        overlapBoxAsync((numEdges + getFinalVertex) / 2, height, (canFinish + x) / 2, 0, ry, 0, 1, 1, width / 2, "onEdgeBoxOverlap", self, self.overlapCollisionMask, false, false, true, true)
                    end
                end
                overlapSphereAsync(numEdges, height, canFinish, self.minDistanceToExistingFields, "onCursorSphereOverlap", self, self.overlapCollisionMask, false, false, true, true)
            end
        else
            local lvz = g_i18n:getText(ConstructionBrush.ERROR_MESSAGES[lvx])
            self.cursor:setErrorMessage(lvz)
            return
        end
    end
end
function ConstructionBrushRiceField:onCursorSphereOverlap(actorId, _)
    if actorId == 0 then
        self.isVertexValid = true
        return true
    end
    self.isVertexValid = false
    self.cursor:setErrorMessage(g_i18n:getText("ui_construction_overlapsWithObject"))
    return false
end
function ConstructionBrushRiceField:onEdgeBoxOverlap(actorId, _)
    if actorId == 0 then
        self.isVertexValid = true
        return true
    end
    self.isVertexValid = false
    self.cursor:setErrorMessage(g_i18n:getText("ui_construction_overlapsWithObject"))
    return false
end
function ConstructionBrushRiceField:draw()
    if self.placeable ~= nil then
        local _ = self.currentField == nil
    end
    if self.currentField == nil then
        return
    elseif not self.isVertexValid then
    end
end
function ConstructionBrushRiceField:onButtonPrimary()
    if self.placeable == nil then
        return
    else
        local x, y, z, _, _ = self:getLimitedSnappedCursorPosition()
        if x == nil then
            return
        elseif self:verifyAccess(x, y, z) == nil then
            if self.currentField == nil and self.placeable:getCanCreateNewField() then
                self.currentField = self.placeable:createNewField(y)
            end
            self.placeable:addVertex(self.currentField, x, z)
            self:setInputTextDirty()
        end
    end
end
function ConstructionBrushRiceField:onButtonSecondary()
    if self.currentField ~= nil and not self.pendingCreation then
        if self.finalVertexX ~= nil then
            self.placeable:addVertex(self.currentField, self.finalVertexX, self.finalVertexZ)
        end
        if self.placeable:getCanFinish(self.currentField, self.snappingActive) then
            self.pendingCreation = true
            self.placeable:finalizeNewField(self.currentField, false, function(buildStatus)
                -- upvalues: (copy) self
                self.pendingCreation = false
                if buildStatus == PlaceableRiceField.BUILD_STATUS.OK then
                    self.currentField = nil
                    if self.placeable ~= nil and self.placeable.playPlaceSound ~= nil then
                        self.placeable:playPlaceSound()
                    end
                else
                    local text = g_i18n:getText(PlaceableRiceField.BUILD_STATUS_LOCA_KEYS[buildStatus])
                    if text ~= nil then
                        g_currentMission:showBlinkingWarning(text)
                    end
                end
                self:setInputTextDirty()
            end)
        end
    end
    self:setInputTextDirty()
end
function ConstructionBrushRiceField:onButtonTertiary()
    if self.currentField ~= nil and self.placeable:getNumVertices(self.currentField) > 1 then
        self.placeable:removeLastVertex(self.currentField)
    end
    self:setInputTextDirty()
end
function ConstructionBrushRiceField:onButtonSnapping()
    self.snappingActive = not self.snappingActive
    ConstructionBrushRiceField.LAST_SNAPPING_STATE = self.snappingActive
    self:setInputTextDirty()
end
function ConstructionBrushRiceField:onAxisPrimary(inputValue)
    if self.currentField ~= nil then
        local newHeight = self.currentField.height + inputValue * ConstructionBrushRiceField.HEIGHT_CHANGE_INCREMENT
        for vertexIndex, xPos, zPos in self.currentField.polygon:iteratorVertices() do
            if math.abs(getTerrainHeightAtWorldPos(g_terrainNode, xPos, 0, zPos) - newHeight) > PlaceableRiceField.MAX_HEIGHT_DIFF_TO_TERRAIN then
                self.cursor:setErrorMessage(g_i18n:getText("ui_construction_heightDifferenceTooLarge"))
                return
            end
        end
        self.currentField.height = newHeight
    end
end
function ConstructionBrushRiceField:cancel()
    if self.currentField ~= nil then
        if self.currentField.polygon:getNumVertices() > 4 then
            YesNoDialog.show(function(yes)
                -- upvalues: (copy) self
                if yes then
                    self.currentField = nil
                end
            end, nil, g_i18n:getText("ui_construction_cancelCurrentField"))
        else
            self.currentField = nil
        end
    end
    self:setInputTextDirty()
end
function ConstructionBrushRiceField:getButtonPrimaryText()
    return (self.currentField == nil or self.placeable:getNumVertices(self.currentField) == 0) and "$l10n_action_startNewField" or "$l10n_action_addCorner"
end
function ConstructionBrushRiceField:getButtonSecondaryText()
    return self.currentField ~= nil and (self.placeable:getCanFinish(self.currentField, self.snappingActive) or self.finalVertexX ~= nil) and "$l10n_input_CONSTRUCTION_FINISH" or nil
end
function ConstructionBrushRiceField:getButtonTertiaryText()
    return self.currentField ~= nil and self.placeable:getNumVertices(self.currentField) > 1 and "$l10n_action_removeLastCorner" or nil
end
function ConstructionBrushRiceField:getAxisPrimaryText()
    return self.currentField ~= nil and "$l10n_action_changePlacementHeight" or nil
end
function ConstructionBrushRiceField:getButtonSnappingText()
    return string.format("%s (%s)", g_i18n:getText("input_CONSTRUCTION_ACTION_SNAPPING"), g_i18n:getText(self.snappingActive and "ui_on" or "ui_off"))
end