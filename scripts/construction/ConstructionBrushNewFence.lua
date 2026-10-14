ConstructionBrushNewFence = {}
local ConstructionBrushNewFence_mt = Class(ConstructionBrushNewFence, ConstructionBrush)
ConstructionBrushNewFence.ERROR = {
    ["MININUM_LENGTH"] = 100,
    ["MINIMUM_ANGLE"] = 101,
    ["MAXIMUM_ANGLE"] = 102,
    ["COLLISION"] = 103,
    ["NOT_ENOUGH_MONEY"] = 104,
    ["CANNOT_BE_PLACED_HERE"] = 105
}
ConstructionBrushNewFence.ERROR_MESSAGES = {
    [ConstructionBrushNewFence.ERROR.MININUM_LENGTH] = "ui_construction_distanceTooShort",
    [ConstructionBrushNewFence.ERROR.MINIMUM_ANGLE] = "ui_construction_cornerAngleTooLarge",
    [ConstructionBrushNewFence.ERROR.MAXIMUM_ANGLE] = "ui_construction_terrainTooSteep",
    [ConstructionBrushNewFence.ERROR.COLLISION] = "ui_construction_collidesWithItem",
    [ConstructionBrushNewFence.ERROR.NOT_ENOUGH_MONEY] = "ui_construction_notEnoughMoney",
    [ConstructionBrushNewFence.ERROR.CANNOT_BE_PLACED_HERE] = "ui_construction_cannotBePlacedHere"
}
ConstructionBrushNewFence.SEGMENT_ERROR_TO_MESSAGE = {
    [FenceSegment.ERROR_TOO_SHORT] = "ui_construction_distanceTooShort",
    [FenceSegment.ERROR_TOO_STEEP] = "ui_construction_terrainTooSteep"
}
ConstructionBrushNewFence.STATUS = {
    ["SUCCESS"] = 0,
    ["CANCELLED"] = 1
}
ConstructionBrushNewFence.MINIMUM_LENGTH = 0.5
ConstructionBrushNewFence.MINIMUM_ANGLE = 0.5235987755982988
ConstructionBrushNewFence.SNAP_DISTANCE = 0.4
ConstructionBrushNewFence.LAST_SNAPPING_STATE = false
function ConstructionBrushNewFence.new(subclass_mt, cursor)
    -- upvalues: (copy) ConstructionBrushNewFence_mt
    local self = ConstructionBrushNewFence:superClass().new(subclass_mt or ConstructionBrushNewFence_mt, cursor)
    self.supportsPrimaryButton = true
    self.supportsSecondaryButton = true
    self.supportsTertiaryButton = true
    self.supportsFourthButton = true
    self.supportsPrimaryAxis = true
    self.supportsSecondaryAxis = true
    self.needsOverlayReset = {}
    self.segmentIds = {}
    self.requiredPermission = Farm.PERMISSION.BUY_PLACEABLE
    self.isValidating = false
    self.canToggleParallelSnapping = false
    self.parallelSnappingEnabled = false
    self.doFindPlaceable = false
    self.supportsSnapping = true
    self.snappingActive = ConstructionBrushNewFence.LAST_SNAPPING_STATE
    self.snappingAngleDeg = 7.5
    self.snappingSize = 0.25
    self.overlappingNodes = {}
    local i3dNode = g_i3DManager:loadI3DFile("data/shared/visualization/fenceSnapMarker.i3d", false, false)
    if i3dNode ~= 0 then
        self.snapMarkerStart = getChildAt(i3dNode, 0)
        self.snapMarkerEnd = clone(self.snapMarkerStart, false, false, false)
        link(getRootNode(), self.snapMarkerStart)
        link(getRootNode(), self.snapMarkerEnd)
        setShaderParameter(self.snapMarkerStart, "emitColor", 0, 1, 0, 1, false)
        setShaderParameter(self.snapMarkerEnd, "emitColor", 0, 1, 0, 1, false)
        setVisibility(self.snapMarkerStart, false)
        setVisibility(self.snapMarkerEnd, false)
        delete(i3dNode)
    end
    return self
end
function ConstructionBrushNewFence:delete()
    ConstructionBrushNewFence:superClass().delete(self)
    self.doFindPlaceable = false
    if self.snapMarkerStart ~= nil then
        delete(self.snapMarkerStart)
        delete(self.snapMarkerEnd)
    end
end
function ConstructionBrushNewFence:setFenceParentObject(parentObject)
    if parentObject.getFence == nil then
        Logging.error("ConstructionBrushNewFence:setFenceParentObject(): parent object does not have a \'getFence\' function")
    else
        self.fenceParentObject = parentObject
        self:initFence()
    end
end
function ConstructionBrushNewFence:activate()
    ConstructionBrushNewFence:superClass().activate(self)
    self.cursor:setRotationEnabled(false)
    self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
    self.cursor:setShapeSize(0.3)
    self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SUCCESS)
    self.cursor:setTerrainOnly(true)
    if self.fenceParentObject == nil and self:hasPlayerPermission() then
        self:acquirePlaceable()
    end
end
function ConstructionBrushNewFence:deactivate()
    if self.currentSegment ~= nil then
        self.currentSegment:delete()
        self.currentSegment = nil
    end
    if self.snapMarkerStart ~= nil then
        setWorldTranslation(self.snapMarkerStart, 0, 0, 0)
        setWorldTranslation(self.snapMarkerEnd, 0, 0, 0)
        setVisibility(self.snapMarkerStart, false)
        setVisibility(self.snapMarkerEnd, false)
    end
    self:releasePlaceable()
    self.isValidating = false
    self.segmentIds = {}
    self.fenceParentObject = nil
    self.doFindPlaceable = false
    self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SELECT, nil)
    g_messageCenter:unsubscribeAll(self)
    self.overlappingNodes = {}
    self:finish(ConstructionBrushNewFence.STATUS.CANCELLED)
    self.cursor:setTerrainOnly(false)
    ConstructionBrushNewFence:superClass().deactivate(self)
end
function ConstructionBrushNewFence:setSnapStartAndEndPositions(startX, startY, startZ, endX, endY, endZ)
    if startX == nil or endX == nil then
        Logging.devError("ConstructionBrushNewFence:setSnapStartAndEndPositions(): Trying to set nil snapping positions")
    else
        self.snapStart = { startX, startY, startZ }
        self.snapEnd = { endX, endY, endZ }
        self.hasSnapPositions = true
        if self.snapMarkerStart ~= nil then
            setWorldTranslation(self.snapMarkerStart, startX, startY, startZ)
            setWorldTranslation(self.snapMarkerEnd, endX, endY, endZ)
            setVisibility(self.snapMarkerStart, true)
            setVisibility(self.snapMarkerEnd, true)
        end
    end
end
function ConstructionBrushNewFence:setFinishCallback(func)
    self.finishCallbackFunc = func
end
function ConstructionBrushNewFence:setValidateCallback(func)
    self.validateCallbackFunc = func
end
function ConstructionBrushNewFence:setSegmentTemplate(id)
    self.templateId = id
    self.parallelSnappingEnabled = false
    self.canToggleParallelSnapping = false
    local metadata = self.fence:getSegmentTemplateById(self.templateId)
    if metadata.parallelSnapping ~= nil then
        self.canToggleParallelSnapping = metadata.parallelSnapping.canToggle
        if not self.canToggleParallelSnapping then
            self.parallelSnappingEnabled = true
        end
    end
    self:setInputTextDirty()
    local sx = nil
    local sy = nil
    local sz = nil
    if self.currentSegment ~= nil then
        sx, sy, sz = self.currentSegment:getStartPos()
        self.currentSegment:delete()
        self.currentSegment = nil
    end
    self.currentSegment = self.fence:createNewSegment(self.templateId)
    self.currentSegment:setParallelSnappingSegment(self.parallelSnappingSegment)
    if sx ~= nil then
        self.currentSegment:setStartPos(sx, sy, sz)
    end
end
function ConstructionBrushNewFence:canCancel()
    return self.fenceParentObject ~= nil and self.currentSegment ~= nil
end
function ConstructionBrushNewFence:acquirePlaceable()
    if self.storeItem == nil then
        Logging.warning("ConstructionBrushNewFence has no store item set")
    else
        self.fenceParentObject = self:findPlaceable()
        if self.fenceParentObject == nil then
            local data = BuyPlaceableData.new()
            data:setStoreItem(self.storeItem)
            data:setPosition(0, PlacementUtil.NETHER_HEIGHT - 1, 0)
            data:setRotation(0, 0, 0)
            data:setConfigurations({})
            data:setOwnerFarmId(AccessHandler.EVERYONE)
            data:setDisplacementCosts(0)
            data:setModifyTerrain(false)
            data:setIsFreeOfCharge(true)
            g_messageCenter:subscribe(BuyPlaceableEvent, self.onPlaceableCreated, self)
            g_client:getServerConnection():sendEvent(BuyPlaceableEvent.new(data))
        else
            self:initFence()
        end
        self:setInputTextDirty()
    end
end
function ConstructionBrushNewFence:findPlaceable()
    return g_currentMission.placeableSystem:getExistingPlaceableByXMLFilename(self.storeItem.xmlFilename)
end
function ConstructionBrushNewFence:onPlaceableCreated(errorCode, _, _)
    g_messageCenter:unsubscribe(BuyPlaceableEvent, self)
    if errorCode == BuyPlaceableEvent.STATE_FAILED_TO_LOAD then
        self.cursor:setErrorMessage(g_i18n:getText("ui_construction_couldNotLoadItem"))
    else
        self.doFindPlaceable = true
    end
end
function ConstructionBrushNewFence:initFence()
    if self.fenceParentObject.getFence == nil then
        Logging.xmlError(self.fenceParentObject.configFileName, "Fence parent object is missing \'getFence\' function, check placeableType")
    else
        self.fence = self.fenceParentObject:getFence()
        self:setSegmentTemplate(self.fence:getSegmentTemplates()[1])
        self:setInputTextDirty()
    end
end
function ConstructionBrushNewFence:releasePlaceable()
    if self.storeItem ~= nil and self.fenceParentObject ~= nil then
        if self.fence == nil or self.fence:getNumSegments() == 0 then
            g_messageCenter:subscribe(SellPlaceableEvent, self.onPlaceableDestroyed, self)
            g_client:getServerConnection():sendEvent(SellPlaceableEvent.new(self.fenceParentObject, true, false, false, true))
        end
        self.fenceParentObject = nil
        self.fence = nil
        self:setInputTextDirty()
    end
end
function ConstructionBrushNewFence:onPlaceableDestroyed()
    g_messageCenter:unsubscribe(SellPlaceableEvent, self)
end
function ConstructionBrushNewFence:getSnappedCursorPosition()
    local x, y, z = self.cursor:getHitTerrainPosition()
    if x == nil then
        return x, y, z, false
    else
        local metadata = self.fence:getSegmentTemplateById(self.templateId)
        local snapDistance = metadata.snapDistance or (self.currentSegment ~= nil and self.currentSegment:getMinimumPanelLength() or 2)
        local maxCornerAngle = metadata.extending ~= nil and metadata.extending.maxCornerAngle or nil
        local currentSegmentStartX = nil
        local currentSegmentStartY = nil
        local currentSegmentStartZ = nil
        if self.currentSegment ~= nil then
            currentSegmentStartX, currentSegmentStartY, currentSegmentStartZ = self.currentSegment:getStartPos()
        end
        local hasStartPosition = currentSegmentStartX ~= nil
        if self.hasSnapPositions and hasStartPosition then
            local endPos = self.snapEnd
            if MathUtil.vector3Length(endPos[1] - x, endPos[2] - y, endPos[3] - z) < snapDistance then
                return endPos[1], endPos[2], endPos[3], true
            end
        end
        local endPos, _distance, px, py, pz, _segmentId, isStartPole, isEndPole = self.fence:getPoleNear(x, y, z, snapDistance)
        if endPos ~= nil and (not hasStartPosition or self.parallelSnappingSegment == nil) and (not hasStartPosition or MathUtil.vector2Length(px - currentSegmentStartX, pz - currentSegmentStartZ) >= 0.1) then
            local snappedTargetSegment = self.fence:getSegmentFromNode(endPos)
            if not (metadata.extending ~= nil and metadata.extending.allowExtendingOnly or nil) or (isStartPole or isEndPole) then
                return px, py, pz, true, snappedTargetSegment
            end
        end
        if maxCornerAngle ~= nil and (self.currentSegment ~= nil and (hasStartPosition and x ~= nil)) then
            local lastPole, _distance, _px, _py, _pz, lastSegmentId, _isStartPole, _isEndPole = self.fence:getPoleNear(currentSegmentStartX, currentSegmentStartY, currentSegmentStartZ, 0.5)
            if lastPole ~= nil then
                local segment = self.fence:getSegmentById(lastSegmentId)
                if segment ~= nil then
                    local segmentStartX, _, segmentStartZ = segment:getStartPos()
                    local segmentEndX, _, segmentEndZ = segment:getEndPos()
                    local distance = MathUtil.vector2Length(x - currentSegmentStartX, z - currentSegmentStartZ)
                    local currentSegmentDirX, currentSegmentDirZ = MathUtil.vector2Normalize(x - currentSegmentStartX, z - currentSegmentStartZ)
                    local lastSegmentDirX, lastSegmentDirZ = MathUtil.vector2Normalize(segmentEndX - segmentStartX, segmentEndZ - segmentStartZ)
                    local cosMax = math.cos(maxCornerAngle)
                    local forwardDot = MathUtil.dotProduct(lastSegmentDirX, 0, lastSegmentDirZ, currentSegmentDirX, 0, currentSegmentDirZ)
                    local backwardDot = MathUtil.dotProduct(lastSegmentDirX, 0, lastSegmentDirZ, -currentSegmentDirX, 0, -currentSegmentDirZ)
                    if not (cosMax <= forwardDot or cosMax <= backwardDot) then
                        if forwardDot < 0 then
                        end
                        local _, crossY, _ = MathUtil.crossProduct(currentSegmentDirX, 0, currentSegmentDirZ, lastSegmentDirX, 0, lastSegmentDirZ)
                        local dot = MathUtil.dotProduct(currentSegmentDirX, 0, currentSegmentDirZ, lastSegmentDirX, 0, lastSegmentDirZ)
                        local angle = math.atan2(crossY, dot)
                        local clampedAngle = math.clamp(angle, -maxCornerAngle, maxCornerAngle)
                        if backwardDot > 0 then
                        end
                        local cos = math.cos(clampedAngle)
                        local clampedNewX, clampedNewZ = MathUtil.vector2Normalize(lastSegmentDirX * cos - lastSegmentDirZ * math.sin(clampedAngle), lastSegmentDirX * sin + lastSegmentDirZ * cos)
                        local clampedNewX = currentSegmentStartX + clampedNewX * distance
                        local clampedNewZ = currentSegmentStartZ + clampedNewZ * distance
                        return clampedNewX, getTerrainHeightAtWorldPos(g_terrainNode, clampedNewX, 0, clampedNewZ), clampedNewZ, true
                    end
                end
            end
        end
        if self.parallelSnappingEnabled then
            local lastPole, _distance, _px, _py, _pz = self.fence:getPoleNear(x, y, z, metadata.parallelSnapping.checkDistance)
            if lastPole ~= nil and not hasStartPosition then
                local lastSegmentId = self.fence:getSegmentFromNode(lastPole)
                self.parallelSnappingSegment = lastSegmentId
                if self.currentSegment ~= nil then
                    self.currentSegment:setParallelSnappingSegment(lastSegmentId)
                end
                local _isStartPole, _isEndPole, segment = lastSegmentId:getStartPos()
                local segmentStartX, _, segmentStartZ = lastSegmentId:getEndPos()
                local segmentEndX, _ = MathUtil.vector2Normalize(segmentStartX - _isStartPole, segmentStartZ - segment)
                local currentSegmentDirZ, currentSegmentDirX
                if self.snappingActive then
                    currentSegmentDirZ = _pz
                    currentSegmentDirX = _px
                else
                    currentSegmentDirX, currentSegmentDirZ = MathUtil.projectOnLine(x, z, _px, _pz, segmentEndX, _)
                end
                local currentSegmentDirX = -_ * metadata.parallelSnapping.snapDistance + currentSegmentDirX
                local currentSegmentDirZ = segmentEndX * snappedTargetSegment + currentSegmentDirZ
                local lastSegmentDirX = _ * snappedTargetSegment + currentSegmentDirX
                local lastSegmentDirZ = -segmentEndX * snappedTargetSegment + currentSegmentDirZ
                local cosMax = MathUtil.vector2Length(currentSegmentDirX - x, currentSegmentDirZ - z)
                local forwardDot = MathUtil.vector2Length(lastSegmentDirX - x, lastSegmentDirZ - z)
                local backwardDot = MathUtil.vector2Length(_px - x, _pz - z)
                if cosMax < forwardDot then
                    lastSegmentDirZ = currentSegmentDirZ
                    lastSegmentDirX = currentSegmentDirX
                end
                local allowed = getTerrainHeightAtWorldPos(g_terrainNode, lastSegmentDirX, 0, lastSegmentDirZ)
                if maxCornerAngle == 0 and (backwardDot < snapDistance and (isStartPole or isEndPole)) then
                    return _px, _py, _pz, true, lastSegmentId
                else
                    local ax, az, _, crossY, _ = self.fence:getPoleNear(lastSegmentDirX, allowed, lastSegmentDirZ, snapDistance)
                    if ax then
                        return _, crossY, _, true
                    else
                        return lastSegmentDirX, allowed, lastSegmentDirZ, true
                    end
                end
            end
            if self.parallelSnappingSegment ~= nil and hasStartPosition then
                local lastSegmentId = self.parallelSnappingSegment
                local _isStartPole, _isEndPole, segment = lastSegmentId:getStartPos()
                local segmentStartX, _, segmentStartZ = lastSegmentId:getEndPos()
                local segmentEndX, _ = MathUtil.vector2Normalize(segmentStartX - _isStartPole, segmentStartZ - segment)
                local segmentEndZ, distance = MathUtil.projectOnLine(x, z, currentSegmentStartX, currentSegmentStartZ, segmentEndX, _)
                return segmentEndZ, getTerrainHeightAtWorldPos(g_terrainNode, segmentEndZ, 0, distance), distance, true
            end
            self.parallelSnappingSegment = nil
            if self.currentSegment ~= nil then
                self.currentSegment:setParallelSnappingSegment(nil)
            end
        end
        if self.snappingActive then
            return MathUtil.snapValue(x, self.snappingSize), y, MathUtil.snapValue(z, self.snappingSize), true
        else
            return x, y, z, false
        end
    end
end
function ConstructionBrushNewFence:getLimitedSnappedCursorPosition()
    local x, y, z, snapped, segment = self:getSnappedCursorPosition()
    return x, y, z, snapped, segment
end
function ConstructionBrushNewFence:getPrice(length)
    if self.gateIndex ~= nil then
        return self.storeItem.price
    end
    if length == nil then
        length = self.fenceParentObject:getSegmentLength(self.fenceParentObject:getPreviewSegment())
    end
    return length * self.storeItem.price
end
function ConstructionBrushNewFence:verifyPreview()
    return nil
end
function ConstructionBrushNewFence:update(dt)
    ConstructionBrushNewFence:superClass().update(self, dt)
    if self.doFindPlaceable then
        self.fenceParentObject = self:findPlaceable()
        self:setInputTextDirty()
        if self.fenceParentObject ~= nil then
            self:initFence()
            self.doFindPlaceable = false
        end
    end
    if self.fenceParentObject == nil then
        if not self:hasPlayerPermission() then
            self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.ERROR)
            self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrush.ERROR_MESSAGES[ConstructionBrush.ERROR.NO_PERMISSION]))
        end
        return
    elseif self.fence == nil then
        return
    else
        self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SUCCESS)
        local x, y, z, isSnapped, _snappedSegment = self:getLimitedSnappedCursorPosition()
        if self.currentSegment == nil then
            if isSnapped then
                self.cursor:setPosition(x, y, z)
            end
            return
        else
            self.currentSegment:draw()
            if self.hasSnapPositions and self.currentSegment:getStartPos() == nil then
                self.currentSegment:setStartPos(self.snapStart[1], self.snapStart[2], self.snapStart[3])
            end
            if x == nil then
                return
            else
                local err = self:verifyAccess(x, y, z)
                if err == nil then
                    if isSnapped and self.currentSegment:getStartPos() == nil then
                        self.cursor:setPosition(x, y, z)
                    end
                    if self:validateCurrentSegment(x, z) then
                        self.currentSegment:setEndPos(x, y, z)
                        if self.currentSegment:updateMeshes() then
                            self.currentSegment:update()
                            table.clear(self.overlappingNodes)
                            self.currentSegment:checkOverlap(self.overlappingNodes)
                            for overlappingNode in pairs(self.overlappingNodes) do
                                local segment = self.fence:getSegmentFromNode(overlappingNode)
                                if segment ~= nil then
                                    local segmentPart = segment:getSegmentPartFromNode(overlappingNode)
                                    if segmentPart ~= nil then
                                        renderShapeOutline(segmentPart, true)
                                    end
                                end
                            end
                            if next(self.overlappingNodes) ~= nil then
                                self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.ERROR)
                                self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrushNewFence.ERROR_MESSAGES[ConstructionBrushNewFence.ERROR.COLLISION]))
                                return
                            end
                        else
                            local segmentError = self.currentSegment:getLastError()
                            if segmentError ~= nil then
                                self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.ERROR)
                                self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrushNewFence.SEGMENT_ERROR_TO_MESSAGE[segmentError]))
                            end
                        end
                    end
                else
                    self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.ERROR)
                    self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrushNewFence.ERROR_MESSAGES[err] or ConstructionBrush.ERROR_MESSAGES[err]))
                end
            end
        end
    end
end
function ConstructionBrushNewFence:draw()
    if g_isDevelopmentVersion and (self.fenceParentObject ~= nil and self.fenceParentObject.configFileName ~= nil) then
        local storeItemNameCleaned = string.gsub(self.fenceParentObject.configFileName, getUserProfileAppPath(), "")
        renderText(ConstructionBrush.DEBUG_TEXT_ATTR.x, ConstructionBrush.DEBUG_TEXT_ATTR.y, ConstructionBrush.DEBUG_TEXT_ATTR.z, storeItemNameCleaned)
    end
end
function ConstructionBrushNewFence:validateCurrentSegment(x, z)
    if self.currentSegment == nil then
        return false
    else
        local sx, _, sz = self.currentSegment:getStartPos()
        if sx == nil then
            return false
        elseif g_farmlandManager:getIsOwnedByFarmAlongLine(g_localPlayer.farmId, sx, sz, x, z) then
            local price = self.currentSegment:getPrice()
            if g_currentMission:getMoney(g_localPlayer.farmId) < price then
                self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrushNewFence.ERROR_MESSAGES[ConstructionBrushNewFence.ERROR.NOT_ENOUGH_MONEY]))
                return false
            else
                if price ~= 0 then
                    self.cursor:setMessage(g_i18n:formatMoney(price))
                end
                return true
            end
        else
            self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrush.ERROR_MESSAGES[ConstructionBrush.ERROR.LAND_UNOWNED]))
            return false
        end
    end
end
function ConstructionBrushNewFence:onButtonPrimary()
    if self.isValidating then
        return
    elseif self.fenceParentObject == nil then
        return
    elseif self.fence == nil then
        return
    else
        if self.currentSegment == nil then
            self.currentSegment = self.fence:createNewSegment(self.templateId)
            self.currentSegment:setParallelSnappingSegment(self.parallelSnappingSegment)
        end
        local x, y, z, _snapped, _segment = self:getLimitedSnappedCursorPosition()
        if x == nil then
            return
        elseif self:verifyAccess(x, y, z) == nil then
            if self.currentSegment:getStartPos() == nil then
                self.currentSegment:setStartPos(x, y, z)
            else
                if not self:validateCurrentSegment(x, z) then
                    return
                end
                if next(self.overlappingNodes) ~= nil then
                    return
                end
                g_messageCenter:subscribeOneshot(FenceNewSegmentEvent, self.onServerCreatedFenceCallback, self)
                g_client:getServerConnection():sendEvent(FenceNewSegmentEvent.newClientToServer(self.fenceParentObject, self.currentSegment))
            end
            self:setInputTextDirty()
        end
    end
end
function ConstructionBrushNewFence:finish(status)
    self.currentSegment = nil
    self.parallelSnappingSegment = nil
    if self.finishCallbackFunc ~= nil then
        self.finishCallbackFunc = nil
        self.finishCallbackFunc(status)
    end
end
function ConstructionBrushNewFence:onServerCreatedFenceCallback(statusCode, segmentId, endX, endY, endZ)
    if statusCode == FenceNewSegmentEvent.STATUS_CODE.SUCCESS then
        if self.fenceParentObject.playPlaceSound ~= nil then
            self.fenceParentObject:playPlaceSound()
        end
        if self.currentSegment ~= nil and g_server == nil then
            self.currentSegment:delete()
            self.currentSegment = nil
        end
        table.addElement(self.segmentIds, segmentId)
        if self.hasSnapPositions and MathUtil.vector3Length(self.snapEnd[1] - endX, self.snapEnd[2] - endY, self.snapEnd[3] - endZ) < 0.1 then
            self.currentSegment = nil
            if self.validateCallbackFunc == nil then
                self:finish(ConstructionBrushNewFence.STATUS.SUCCESS)
            else
                self.isValidating = true
                self.validateCallbackFunc(function(success)
                    -- upvalues: (copy) self
                    self.isValidating = false
                    if success then
                        self:finish(ConstructionBrushNewFence.STATUS.SUCCESS)
                    else
                        self:deleteLastSeqment()
                    end
                end)
            end
        else
            self:createNextSegment(endX, endY, endZ)
            return
        end
    else
        return
    end
end
function ConstructionBrushNewFence:deleteLastSeqment()
    if self.fence ~= nil then
        local lastSegmentId = self.segmentIds[#self.segmentIds]
        local lastSegment = self.fence:getSegmentById(lastSegmentId)
        if lastSegment ~= nil then
            local x, y, z = lastSegment:getStartPos()
            g_messageCenter:subscribeOneshot(FenceRequestDeleteSegmentEvent, function(success)
                -- upvalues: (copy) self, (copy) lastSegment, (copy) lastSegmentId, (copy) x, (copy) y, (copy) z
                if self.currentSegment ~= nil then
                    self.currentSegment:delete()
                    self.currentSegment = nil
                end
                if g_server == nil then
                    lastSegment:delete()
                end
                table.removeElement(self.segmentIds, lastSegmentId)
                self:createNextSegment(x, y, z)
            end)
            g_client:getServerConnection():sendEvent(FenceRequestDeleteSegmentEvent.new(self.fenceParentObject, lastSegmentId))
        end
    end
end
function ConstructionBrushNewFence:createNextSegment(startX, startY, startZ)
    if self.fence ~= nil then
        self.currentSegment = self.fence:createNewSegment(self.templateId)
        self.currentSegment:setParallelSnappingSegment(self.parallelSnappingSegment)
        self.currentSegment:setStartPos(startX, startY, startZ)
    end
end
function ConstructionBrushNewFence:onButtonSecondary()
    if self.snapEnd == nil then
        if self.currentSegment ~= nil then
            self.currentSegment:delete()
            self.currentSegment = nil
            self.parallelSnappingSegment = nil
            self:setInputTextDirty()
        end
    else
        YesNoDialog.show(function(yes)
            -- upvalues: (copy) self
            if yes then
                self:deactivate()
            end
        end, nil, g_i18n:getText("ui_construction_cancelCustomFence"))
    end
end
function ConstructionBrushNewFence:onButtonTertiary()
    if self.canToggleParallelSnapping then
        self.parallelSnappingEnabled = not self.parallelSnappingEnabled
        self:setInputTextDirty()
    end
end
function ConstructionBrushNewFence:onButtonSnapping()
    self.snappingActive = not self.snappingActive
    ConstructionBrushNewFence.LAST_SNAPPING_STATE = self.snappingActive
    self:setInputTextDirty()
end
function ConstructionBrushNewFence:onButtonFourth()
    self:deleteLastSeqment()
end
function ConstructionBrushNewFence:onAxisPrimary(inputValue)
    if self.fence == nil then
        return
    else
        local templates = self.fence:getSegmentTemplates()
        if #templates ~= 1 then
            self:setSegmentTemplate(templates[1 + (table.find(templates, self.templateId) - 1 + inputValue) % #templates])
            self:setInputTextDirty()
        end
    end
end
function ConstructionBrushNewFence:getAxisPrimaryText()
    if self.fence ~= nil then
        local templates = self.fence:getSegmentTemplates()
        if #templates <= 1 then
            return nil
        end
        local currentIndex = table.find(templates, self.templateId)
        return string.format("%s (%d/%d)", g_i18n:getText("action_fenceSwitchSegmentType"), currentIndex, #templates)
    end
end
function ConstructionBrushNewFence:onAxisSecondary(_)
    if self.currentSegment ~= nil and self.currentSegment.setIsReversed ~= nil then
        self.currentSegment:setIsReversed(not self.currentSegment:getIsReversed())
    end
end
function ConstructionBrushNewFence:getAxisSecondaryText()
    if self.currentSegment == nil or self.currentSegment.setIsReversed == nil then
        return nil
    else
        return g_i18n:getText("action_fenceReverse")
    end
end
function ConstructionBrushNewFence:cancel()
    self:onButtonSecondary()
end
function ConstructionBrushNewFence:getButtonPrimaryText()
    if self.fence == nil then
        return nil
    else
        return self.currentSegment ~= nil and self.currentSegment:getStartPos() == nil and "$l10n_input_CONSTRUCTION_PLACE_POLE" or g_i18n:getText("action_fencePlaceSegment")
    end
end
function ConstructionBrushNewFence:getButtonSecondaryText()
    if self.fence == nil then
        return nil
    elseif self.snapEnd == nil then
        return self.currentSegment ~= nil and self.currentSegment:getStartPos() ~= nil and "$l10n_input_CONSTRUCTION_FINISH" or nil
    else
        return nil
    end
end
function ConstructionBrushNewFence:getButtonTertiaryText()
    if self.fence == nil then
        return nil
    end
    if not self.canToggleParallelSnapping then
        return nil
    end
    return string.format(g_i18n:getText("input_CONSTRUCTION_SNAP"), g_i18n:getText(self.parallelSnappingEnabled and "ui_on" or "ui_off"))
end
function ConstructionBrushNewFence:getButtonSnappingText()
    if self.fence == nil then
        return nil
    end
    return string.format("%s (%s)", g_i18n:getText("input_CONSTRUCTION_ACTION_SNAPPING"), g_i18n:getText(self.snappingActive and "ui_on" or "ui_off"))
end
function ConstructionBrushNewFence:getButtonFourthText()
    return #self.segmentIds > 0 and "$l10n_action_deleteLastSegment" or nil
end