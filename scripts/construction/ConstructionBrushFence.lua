ConstructionBrushFence = {}
local ConstructionBrushFence_mt = Class(ConstructionBrushFence, ConstructionBrush)
ConstructionBrushFence.ERROR = {
    ["MININUM_LENGTH"] = 100,
    ["MINIMUM_ANGLE"] = 101,
    ["MAXIMUM_ANGLE"] = 102,
    ["COLLISION"] = 103,
    ["NOT_ENOUGH_MONEY"] = 104,
    ["CANNOT_BE_PLACED_HERE"] = 105
}
ConstructionBrushFence.ERROR_MESSAGES = {
    [ConstructionBrushFence.ERROR.MININUM_LENGTH] = "ui_construction_distanceTooShort",
    [ConstructionBrushFence.ERROR.MINIMUM_ANGLE] = "ui_construction_cornerAngleTooLarge",
    [ConstructionBrushFence.ERROR.MAXIMUM_ANGLE] = "ui_construction_terrainTooSteep",
    [ConstructionBrushFence.ERROR.COLLISION] = "ui_construction_collidesWithItem",
    [ConstructionBrushFence.ERROR.NOT_ENOUGH_MONEY] = "ui_construction_notEnoughMoney",
    [ConstructionBrushFence.ERROR.CANNOT_BE_PLACED_HERE] = "ui_construction_cannotBePlacedHere"
}
ConstructionBrushFence.MINIMUM_LENGTH = 0.5
ConstructionBrushFence.MINIMUM_ANGLE = 0.5235987755982988
ConstructionBrushFence.SNAP_DISTANCE = 0.4
ConstructionBrushFence.LAST_SNAPPING_STATE = false
ConstructionBrushFence.OVERLAP_COLLISION_MASK = CollisionMask.ALL - CollisionFlag.TERRAIN - CollisionFlag.TERRAIN_DISPLACEMENT - CollisionFlag.TRIGGER - CollisionFlag.GROUND_TIP_BLOCKING
function ConstructionBrushFence.new(subclass_mt, cursor)
    -- upvalues: (copy) ConstructionBrushFence_mt
    local self = ConstructionBrushFence:superClass().new(subclass_mt or ConstructionBrushFence_mt, cursor)
    self.supportsPrimaryButton = true
    self.supportsSecondaryButton = true
    self.supportsTertiaryButton = true
    self.needsOverlayReset = {}
    self.requiredPermission = Farm.PERMISSION.BUY_PLACEABLE
    self.parallelSnappingEnabled = false
    self.doFindPlaceable = false
    self.supportsSnapping = true
    self.snappingActive = ConstructionBrushFence.LAST_SNAPPING_STATE
    self.snappingAngleDeg = 7.5
    self.snappingSize = 0.25
    return self
end
function ConstructionBrushFence:delete()
    ConstructionBrushFence:superClass().delete(self)
    self.doFindPlaceable = false
end
function ConstructionBrushFence:activate()
    ConstructionBrushFence:superClass().activate(self)
    self.cursor:setRotationEnabled(false)
    self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
    self.cursor:setShapeSize(0.3)
    self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SUCCESS)
    self.cursor:setTerrainOnly(true)
    g_messageCenter:subscribe(PlaceableFenceAddSegmentEvent, self.onFenceSegmentCreated, self)
    self:acquirePlaceable()
end
function ConstructionBrushFence:deactivate()
    self:releasePlaceable()
    self.fence = nil
    self.doFindPlaceable = false
    self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SELECT, nil)
    self:resetErrorOverlays()
    g_messageCenter:unsubscribeAll(self)
    ConstructionBrushFence:superClass().deactivate(self)
end
function ConstructionBrushFence:setFilename(xmlFilename)
    if not self.isActive then
        self.xmlFilename = xmlFilename
    end
end
function ConstructionBrushFence:setIsGate(isGate, gateIndex)
    if isGate then
        self.gateIndex = gateIndex
    else
        self.gateIndex = nil
    end
end
function ConstructionBrushFence:setParameters(filename, isGate, gateIndex)
    if isGate == "true" then
        self:setIsGate(true, (tonumber(gateIndex)))
    else
        self:setIsGate(false)
    end
    self:setFilename(filename)
end
function ConstructionBrushFence:setStoreItem(storeItem, _, _)
    if not self.isActive then
        self.storeItem = storeItem
    end
end
function ConstructionBrushFence:canCancel()
    return self.fence ~= nil and self.fence:getPreviewSegment() ~= nil
end
function ConstructionBrushFence:acquirePlaceable()
    if self.xmlFilename == nil then
        Logging.warning("Fence brush has no placeable set")
        return
    else
        self.fence = self:findPlaceable()
        self:setInputTextDirty()
        if self.fence == nil then
            local singletonStoreItem = g_storeManager:getItemByXMLFilename(self.xmlFilename)
            local data = BuyPlaceableData.new()
            data:setStoreItem(singletonStoreItem)
            data:setPosition(0, PlacementUtil.NETHER_HEIGHT - 1, 0)
            data:setRotation(0, 0, 0)
            data:setConfigurations({})
            data:setOwnerFarmId(g_localPlayer.farmId)
            data:setDisplacementCosts(0)
            data:setModifyTerrain(false)
            data:setIsFreeOfCharge(true)
            g_messageCenter:subscribe(BuyPlaceableEvent, self.onPlaceableCreated, self)
            g_client:getServerConnection():sendEvent(BuyPlaceableEvent.new(data))
        elseif self.fence:getHasParallelSnapping() then
            self.parallelSnappingEnabled = true
        end
    end
end
function ConstructionBrushFence:findPlaceable()
    local farmId = g_currentMission:getFarmId()
    return g_currentMission.placeableSystem:getExistingPlaceableByXMLFilename(self.xmlFilename, farmId)
end
function ConstructionBrushFence:onPlaceableCreated(errorCode, _, _)
    g_messageCenter:unsubscribe(BuyPlaceableEvent, self)
    if errorCode == BuyPlaceableEvent.STATE_FAILED_TO_LOAD then
        self.cursor:setErrorMessage("Loading failed")
    else
        self.doFindPlaceable = true
    end
end
function ConstructionBrushFence:releasePlaceable()
    if self.fence ~= nil then
        if self.fence:getNumSequments() == 0 then
            g_client:getServerConnection():sendEvent(SellPlaceableEvent.new(self.fence, true, false, false))
        elseif self.fence:getPreviewSegment() ~= nil then
            self.fence:setPreviewSegment(nil)
        end
        if self.previewPole ~= nil then
            delete(self.previewPole)
            self.previewPole = nil
        end
        self.fence = nil
        self:setInputTextDirty()
    end
end
function ConstructionBrushFence:getSnappedCursorPosition()
    local x, y, z = self.cursor:getHitTerrainPosition()
    if x == nil then
        local node = self.cursor:getHitNode()
        if node == nil then
            return nil
        else
            local px, py, pz, segment = self.fence:getPolePosition(node)
            if px == nil then
                return nil
            elseif self.fence:getAllowExtendingOnly() then
                if (function(node)
                    local pole = getParent(node)
                    local group = getParent(pole)
                    return pole == getChildAt(group, 0) or pole == getChildAt(group, getNumOfChildren(group) - 1)
                end)(node) then
                    return px, py, pz, true, segment
                else
                    return x, y, z, false
                end
            else
                return px, py, pz, true, segment
            end
        end
    else
        if self.parallelSnappingEnabled then
            local node = self.fence:getSnapCheckDistance()
            local px, py, pz, segment, segment = self.fence:getPoleNear(x, y, z, node)
            local previewSegment = self.fence:getPreviewSegment()
            self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SELECT, nil)
            if px ~= nil and previewSegment == nil then
                if self.previewPoleCursor then
                    self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SUCCESS, nil)
                end
                local dx, dz = MathUtil.vector2Normalize(segment.x2 - segment.x1, segment.z2 - segment.z1)
                local dist = self.fence:getSnapDistance()
                local x1 = -dz * dist + px
                local z1 = dx * dist + pz
                local x2 = dz * dist + px
                local z2 = -dx * dist + pz
                local distance1 = MathUtil.vector2Length(x1 - x, z1 - z)
                local distance2 = MathUtil.vector2Length(x2 - x, z2 - z)
                local distancePole = MathUtil.vector2Length(px - x, pz - z)
                if distance1 < distance2 then
                    z2 = z1
                    x2 = x1
                end
                self.parallelSnappingSegment = segment
                local snapY = getTerrainHeightAtWorldPos(g_terrainNode, x2, 0, z2)
                if self.fence:getMaxCornerAngle() == 0 and distancePole < dist * 0.4 then
                    return px, py, pz, true, segment
                else
                    return x2, snapY, z2, true
                end
            end
            if self.parallelSnappingSegment ~= nil and previewSegment ~= nil then
                local dx = self.parallelSnappingSegment
                local dz, dist = MathUtil.vector2Normalize(dx.x2 - dx.x1, dx.z2 - dx.z1)
                local x1, z1 = MathUtil.projectOnLine(x, z, previewSegment.x1, previewSegment.z1, dz, dist)
                return x1, getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z1), z1, true
            end
            self.parallelSnappingSegment = nil
        end
        local px = self.fence:getPanelLength() * ConstructionBrushFence.SNAP_DISTANCE
        local py = self.fence
        local node = math.max(px, py:getSnapCheckDistance())
        local px, py, pz, segment, segment = self.fence:getPoleNear(x, y, z, node)
        if px == nil or self.fence:getMaxCornerAngle() <= 0 then
            if self.snappingActive then
                local previewSegment = 1 / self.snappingSize
                x = math.floor(x * previewSegment) / previewSegment
                z = math.floor(z * previewSegment) / previewSegment
            end
            return x, y, z, false
        elseif self.fence:getAllowExtendingOnly() then
            if isNodeSegmentEndpoint(segment) then
                return px, py, pz, true, segment
            else
                return x, y, z, false
            end
        else
            return px, py, pz, true, segment
        end
    end
end
function ConstructionBrushFence:getLimitedSnappedCursorPosition()
    local x, y, z, snapped, segment = self:getSnappedCursorPosition()
    local pSegment = self.fence:getPreviewSegment()
    if x ~= nil and pSegment ~= nil then
        local dx = x - pSegment.x1
        local dz = z - pSegment.z1
        local panelLength = MathUtil.vector2Length(dx, dz)
        local recalculateY = false
        local length, snapAngleDeg
        if panelLength == 0 then
            length = 1
            snapAngleDeg = 0
        else
            length, snapAngleDeg = MathUtil.vector2Normalize(dx, dz)
        end
        if self.gateIndex == nil then
            if self.fence:getIsPanelLengthFixed() then
                local length = self.fence:getPanelLength()
                panelLength = math.floor(panelLength / length) * length
                recalculateY = true
            end
        else
            panelLength = self.fence:getGate(self.gateIndex).length
            recalculateY = true
        end
        local length = self.attachmentPointSegment
        local snapAngleDeg = self.fence:getSnapAngle()
        if length ~= nil and snapAngleDeg ~= nil then
            local prevRotY, rotY = MathUtil.vector2Normalize(length.x2 - length.x1, length.z2 - length.z1)
            local diff = MathUtil.getYRotationFromDirection(prevRotY, rotY) - MathUtil.getYRotationFromDirection(length, snapAngleDeg)
            local snappedAngle = math.rad((MathUtil.snapValue(math.deg(diff), snapAngleDeg)))
            length, snapAngleDeg = MathUtil.vector2Rotate(prevRotY, rotY, snappedAngle)
            recalculateY = true
        end
        x = pSegment.x1 + length * panelLength
        z = pSegment.z1 + snapAngleDeg * panelLength
        if recalculateY then
            y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
        end
    end
    return x, y, z, snapped, segment
end
function ConstructionBrushFence:getPreviewAngle()
    if self.fence:getPreviewSegment() == nil then
        return nil
    end
    local segment = self.fence:getPreviewSegment()
    local prevSegment = self.attachmentPointSegment
    if prevSegment == nil then
        return nil
    end
    local beta
    if self.attachmentPointSegmentReversed then
        beta = MathUtil.getYRotationFromDirection(prevSegment.x2 - prevSegment.x1, prevSegment.z2 - prevSegment.z1)
    else
        beta = MathUtil.getYRotationFromDirection(prevSegment.x1 - prevSegment.x2, prevSegment.z1 - prevSegment.z2)
    end
    local dx = segment.x1 - segment.x2
    local dz = segment.z1 - segment.z2
    local beta = MathUtil.getYRotationFromDirection(dx, dz)
    local angle = MathUtil.getAngleDifference(beta, beta) - 3.141592653589793
    local angle = math.abs(angle)
    if angle > 3.141592653589793 then
    end
    return 3.141592653589793 - angle
end
function ConstructionBrushFence:getPrice(length)
    if self.gateIndex ~= nil then
        return self.storeItem.price
    end
    if length == nil then
        length = self.fence:getSegmentLength(self.fence:getPreviewSegment())
    end
    return length * self.storeItem.price
end
function ConstructionBrushFence:verifyPreview()
    local pSegment = self.fence:getPreviewSegment()
    local y = getTerrainHeightAtWorldPos(g_terrainNode, pSegment.x2, 0, pSegment.z2)
    local err = self:verifyAccess(pSegment.x2, y, pSegment.z2)
    if err == nil then
        local canBePlaced, placingFailedMessage = self.fence:getCanBePlacedAt(pSegment.x2, 0, pSegment.z2, g_currentMission:getFarmId())
        if canBePlaced then
            local length = self.fence:getSegmentLength(pSegment)
            if length < self.fence:getPanelLength() * ConstructionBrushFence.MINIMUM_LENGTH then
                return ConstructionBrushFence.ERROR.MININUM_LENGTH
            else
                local verticalAngle, minY, maxY = self.fence:getMaxVerticalAngleAndYForPreview()
                if self.fence:getMaxVerticalAngle() < verticalAngle or pSegment.gateIndex ~= nil and self.fence:getMaxVerticalGateAngle() < verticalAngle then
                    return ConstructionBrushFence.ERROR.MAXIMUM_ANGLE
                elseif self:getPrice(length) > g_currentMission:getMoney(self.fence:getOwnerFarmId()) then
                    return ConstructionBrushFence.ERROR.NOT_ENOUGH_MONEY
                else
                    local angle = self:getPreviewAngle()
                    if self.parallelSnappingSegment == nil and (angle ~= nil and self.fence:getMaxCornerAngle() < angle) then
                        return ConstructionBrushFence.ERROR.MINIMUM_ANGLE
                    else
                        local ry = math.atan2(pSegment.x2 - pSegment.x1, pSegment.z2 - pSegment.z1) + 1.5707963267948966
                        local ez = self.fence:getBoundingCheckWidth() * 0.5
                        self.hitAnyObjects = false
                        overlapBox(pSegment.x1 / 2 + pSegment.x2 / 2, minY / 2 + maxY / 2, pSegment.z1 / 2 + pSegment.z2 / 2, 0, ry, 0, length * 0.5 + self.fence:getBoundingCheckWidth() * 0.5, math.abs(minY - maxY) * 0.5 + 2, ez, "boxOverlapCallback", self, ConstructionBrushFence.OVERLAP_COLLISION_MASK, true, true, true, true)
                        if self.hitAnyObjects then
                            return ConstructionBrushFence.ERROR.COLLISION
                        else
                            return nil
                        end
                    end
                end
            end
        else
            return ConstructionBrushFence.ERROR.CANNOT_BE_PLACED_HERE, placingFailedMessage
        end
    else
        return err
    end
end
function ConstructionBrushFence:boxOverlapCallback(hitObjectId, _, _, _, _)
    if hitObjectId ~= 0 and hitObjectId ~= g_terrainNode then
        local object = g_currentMission:getNodeObject(hitObjectId)
        if object ~= nil and object.setOverlayColor ~= nil then
            if object.findRaycastInfo == nil then
                object:setOverlayColor(1, 0, 0, 1)
                table.insert(self.needsOverlayReset, object)
            else
                local _, panelVisuals, segment, pole, poleIndex = object:findRaycastInfo(hitObjectId)
                if pole ~= nil then
                    local pSegment = self.fence:getPreviewSegment()
                    if object == self.fence and (MathUtil.equalEpsilon(segment.poles[poleIndex], pSegment.x1, 0.01) and MathUtil.equalEpsilon(segment.poles[poleIndex + 1], pSegment.z1, 0.01) or (MathUtil.equalEpsilon(segment.poles[poleIndex], pSegment.x2, 0.01) and MathUtil.equalEpsilon(segment.poles[poleIndex + 1], pSegment.z2, 0.01) or (MathUtil.equalEpsilon(segment.poles[poleIndex + 2], pSegment.x1, 0.01) and MathUtil.equalEpsilon(segment.poles[poleIndex + 3], pSegment.z1, 0.01) or MathUtil.equalEpsilon(segment.poles[poleIndex + 2], pSegment.x2, 0.01) and MathUtil.equalEpsilon(segment.poles[poleIndex + 3], pSegment.z2, 0.01)))) then
                        return
                    end
                    local function setColoredNodes(node)
                        -- upvalues: (copy) self, (copy) setColoredNodes
                        if getHasClassId(node, ClassIds.SHAPE) then
                            setShaderParameter(node, "placeableColorScale", 1, 0, 0, 1, false)
                            table.insert(self.needsOverlayReset, node)
                        end
                        local i = 0
                        for i = i, getNumOfChildren(node) - 1 do
                            setColoredNodes(getChildAt(node, i))
                        end
                    end
                    if getNumOfChildren(pole) > 1 then
                        setColoredNodes((getChildAt(pole, 1)))
                    end
                    if panelVisuals ~= nil then
                        setColoredNodes(panelVisuals)
                    end
                end
            end
        end
        self.hitAnyObjects = true
    end
end
function ConstructionBrushFence:update(dt)
    ConstructionBrushFence:superClass().update(self, dt)
    if self.doFindPlaceable then
        self.fence = self:findPlaceable()
        self:setInputTextDirty()
        if self.fence ~= nil then
            if self.fence:getHasParallelSnapping() then
                self.parallelSnappingEnabled = true
            end
            self.doFindPlaceable = false
        end
    end
    if self.fence == nil then
        if not self:hasPlayerPermission() then
            self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrush.ERROR_MESSAGES[ConstructionBrush.ERROR.NO_PERMISSION]))
        end
        return
    else
        local x, y, z, _, _ = self:getLimitedSnappedCursorPosition()
        local err = nil
        local msg = nil
        local segment = self.fence:getPreviewSegment()
        if x == nil or segment == nil then
            if self.previewPole == nil then
                self.previewPole = self.fence:getPoleShapeForPreview()
                if self.previewPole == nil then
                    self.previewPole = createTransformGroup("PreviewPole")
                    self.previewPoleCursor = true
                else
                    self.previewPoleCursor = false
                end
                link(getRootNode(), self.previewPole)
            end
            if self.previewPoleCursor then
                self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
                self.cursor:setShapeSize(1)
            end
            if x ~= nil then
                setWorldTranslation(self.previewPole, x, y, z)
                err = self:verifyAccess(x, y, z)
            end
            setVisibility(self.previewPole, self.cursor.isVisible)
        else
            if segment.x2 ~= x or segment.z2 ~= z then
                segment.x2 = x
                segment.z2 = z
                self.fence:setPreviewSegment(segment)
            end
            if self.previewPole ~= nil then
                setVisibility(self.previewPole, false)
            end
            if self.previewPoleCursor then
                self.cursor:setShape(GuiTopDownCursor.SHAPES.NONE)
            end
            self:resetErrorOverlays()
            err, msg = self:verifyPreview()
        end
        if err == nil then
            if self.fence:getPreviewSegment() ~= nil then
                self.cursor:setMessage(g_i18n:formatMoney(self:getPrice(), 0, true, true))
            end
        else
            self.cursor:setErrorMessage(msg or g_i18n:getText(ConstructionBrushFence.ERROR_MESSAGES[err] or ConstructionBrush.ERROR_MESSAGES[err]))
        end
    end
end
function ConstructionBrushFence:resetErrorOverlays()
    local i = #self.needsOverlayReset
    for i = i, 1, -1 do
        local item = self.needsOverlayReset[i]
        if type(item) == "number" then
            setShaderParameter(item, "placeableColorScale", 0, 0, 0, 0, false)
        else
            item:setOverlayColor(0, 0, 0, 0)
        end
        self.needsOverlayReset[i] = nil
    end
end
function ConstructionBrushFence:onButtonPrimary()
    if self.fence == nil then
        return
    else
        local x, y, z, snapped, segment = self:getLimitedSnappedCursorPosition()
        if x ~= nil then
            if self.fence:getPreviewSegment() == nil then
                if self:verifyAccess(x, y, z) == nil then
                    local previewSegment = self.fence:createSegment(x, z, x, z, not (snapped and segment ~= nil), self.gateIndex)
                    if snapped and segment ~= nil then
                        self.attachmentPointSegment = segment
                        if segment ~= nil then
                            local price = MathUtil.equalEpsilon(segment.x1, x, 0.01)
                            if price then
                                price = MathUtil.equalEpsilon(segment.z1, z, 0.01)
                            end
                            self.attachmentPointSegmentReversed = price
                        end
                    end
                    self.fence:setPreviewSegment(previewSegment)
                    return
                end
            elseif self:verifyPreview() == nil then
                local previewSegment = self.fence:getPreviewSegment()
                local price = self:getPrice()
                if snapped then
                    snapped = segment ~= nil
                end
                g_client:getServerConnection():sendEvent((PlaceableFenceAddSegmentEvent.new(self.fence, previewSegment.x1, previewSegment.z1, x, z, previewSegment.renderFirst, not snapped, previewSegment.gateIndex, price)))
                if self.fence.playPlaceSound ~= nil then
                    self.fence:playPlaceSound()
                end
                if self.parallelSnappingEnabled then
                    self.fence:setPreviewSegment(nil)
                    self.attachmentPointSegment = nil
                    self.attachmentPointSegmentReversed = nil
                    self:resetErrorOverlays()
                    return
                end
                previewSegment.x1 = x
                previewSegment.z1 = z
                previewSegment.renderFirst = false
                previewSegment.renderLast = true
                self.fence:setPreviewSegment(previewSegment)
                self.parallelSnappingSegment = nil
            end
        end
    end
end
function ConstructionBrushFence:onFenceSegmentCreated(fence, segment)
    if self.fence == fence then
        self.attachmentPointSegment = segment
        self.attachmentPointSegmentReversed = false
    end
end
function ConstructionBrushFence:onButtonSecondary()
    if self.fence ~= nil then
        if self.fence:getPreviewSegment() ~= nil then
            self.fence:setPreviewSegment(nil)
            self.attachmentPointSegment = nil
            self.attachmentPointSegmentReversed = nil
            self:resetErrorOverlays()
        end
    end
end
function ConstructionBrushFence:onButtonTertiary()
    if self.fence:getSupportsParallelSnapping() and self.fence:getMaxCornerAngle() > 0 then
        self.parallelSnappingEnabled = not self.parallelSnappingEnabled
        self:setInputTextDirty()
    end
end
function ConstructionBrushFence:onButtonSnapping()
    self.snappingActive = not self.snappingActive
    ConstructionBrushFence.LAST_SNAPPING_STATE = self.snappingActive
    self:setInputTextDirty()
end
function ConstructionBrushFence:cancel()
    self:onButtonSecondary()
end
function ConstructionBrushFence:getButtonPrimaryText()
    return "$l10n_input_CONSTRUCTION_PLACE_POLE"
end
function ConstructionBrushFence:getButtonSecondaryText()
    return "$l10n_input_CONSTRUCTION_FINISH"
end
function ConstructionBrushFence:getButtonTertiaryText()
    if self.fence == nil or (not self.fence:getSupportsParallelSnapping() or self.fence:getMaxCornerAngle() <= 0) then
        return nil
    end
    return string.format(g_i18n:getText("input_CONSTRUCTION_SNAP"), g_i18n:getText(self.parallelSnappingEnabled and "ui_on" or "ui_off"))
end
function ConstructionBrushFence:getButtonSnappingText()
    return string.format("%s (%s)", g_i18n:getText("input_CONSTRUCTION_ACTION_SNAPPING"), g_i18n:getText(self.snappingActive and "ui_on" or "ui_off"))
end