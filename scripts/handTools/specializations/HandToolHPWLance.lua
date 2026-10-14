HandToolHPWLance = {}
function HandToolHPWLance.registerXMLPaths(xmlSchema)
    xmlSchema:setXMLSpecializationType("HandToolHPWLance")
    xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.highPressureWasherLance.lance#raycastNode", "The range in metres that the lance can wash things", nil, false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.highPressureWasherLance.lance#washDistance", "The range in metres that the lance can wash things", "10 metres", false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.highPressureWasherLance.lance#washMultiplier", "The multiplier applied to the wash amount", "1x", false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.highPressureWasherLance.lance#pricePerMinute", "The cost of using this tool for a minute", "10", false)
    EffectManager.registerEffectXMLPaths(xmlSchema, "handTool.highPressureWasherLance.effects")
    SoundManager.registerSampleXMLPaths(xmlSchema, "handTool.highPressureWasherLance.sounds", "washing")
end
function HandToolHPWLance.registerFunctions(handToolType)
    SpecializationUtil.registerFunction(handToolType, "onWashAction", HandToolHPWLance.onWashAction)
    SpecializationUtil.registerFunction(handToolType, "setIsActivated", HandToolHPWLance.setIsActivated)
    SpecializationUtil.registerFunction(handToolType, "onLanceCallback", HandToolHPWLance.onLanceCallback)
end
function HandToolHPWLance.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeDropped", HandToolHPWLance.getCanBeDropped)
end
function HandToolHPWLance.registerEventListeners(handToolType)
    SpecializationUtil.registerEventListener(handToolType, "onLoad", HandToolHPWLance)
    SpecializationUtil.registerEventListener(handToolType, "onDelete", HandToolHPWLance)
    SpecializationUtil.registerEventListener(handToolType, "onWriteUpdateStream", HandToolHPWLance)
    SpecializationUtil.registerEventListener(handToolType, "onReadUpdateStream", HandToolHPWLance)
    SpecializationUtil.registerEventListener(handToolType, "onUpdate", HandToolHPWLance)
    SpecializationUtil.registerEventListener(handToolType, "onRegisterActionEvents", HandToolHPWLance)
    SpecializationUtil.registerEventListener(handToolType, "onHeldEnd", HandToolHPWLance)
    SpecializationUtil.registerEventListener(handToolType, "onDebugDraw", HandToolHPWLance)
end
function HandToolHPWLance.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(HandToolTethered, specializations)
end
function HandToolHPWLance:onLoad(xmlFile, baseDirectory)
    local spec = self.spec_highPressureWasherLance
    spec.raycastNode = xmlFile:getValue("handTool.highPressureWasherLance.lance#raycastNode", nil, self.components, self.i3dMappings)
    spec.washDistance = xmlFile:getValue("handTool.highPressureWasherLance.lance#washDistance", 10)
    spec.washMultiplier = xmlFile:getValue("handTool.highPressureWasherLance.lance#washMultiplier", 1)
    spec.pricePerSecond = xmlFile:getValue("handTool.highPressureWasherLance.lance#pricePerMinute", 10) / 60
    if self.isClient then
        spec.effects = g_effectManager:loadEffect(xmlFile, "handTool.highPressureWasherLance.effects", self.components, self, self.i3dMappings)
        g_effectManager:setEffectTypeInfo(spec.effects, FillType.WATER)
        spec.washingSample = g_soundManager:loadSampleFromXML(xmlFile, "handTool.highPressureWasherLance.sounds", "washing", baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    spec.isActivated = false
    spec.targetedVehicleId = nil
    spec.activateActionEventId = nil
    spec.isActivatedSent = false
    spec.targetedVehicleIdSent = nil
    spec.dirtyFlag = self:getNextDirtyFlag()
end
function HandToolHPWLance:onDelete()
    local spec = self.spec_highPressureWasherLance
    g_effectManager:deleteEffects(spec.effects)
    g_soundManager:deleteSample(spec.washingSample)
end
function HandToolHPWLance:onWriteUpdateStream(streamId, connection, _)
    local spec = self.spec_highPressureWasherLance
    if streamWriteBool(streamId, spec.isActivatedSent) and connection:getIsServer() then
        if streamWriteBool(streamId, spec.targetedVehicleIdSent ~= nil) then
            NetworkUtil.writeNodeObjectId(streamId, spec.targetedVehicleIdSent)
        end
    end
end
function HandToolHPWLance:onReadUpdateStream(streamId, _, connection)
    local spec = self.spec_highPressureWasherLance
    local isActivated = streamReadBool(streamId)
    spec.targetedVehicleId = nil
    if isActivated and (not connection:getIsServer() and streamReadBool(streamId)) then
        local targetedVehicleId = NetworkUtil.readNodeObjectId(streamId)
        if not self:getCarryingPlayer().isOwner then
            spec.targetedVehicleId = targetedVehicleId
        end
    end
    self:setIsActivated(isActivated)
end
function HandToolHPWLance:onUpdate(dt)
    local carryingPlayer = self:getCarryingPlayer()
    if carryingPlayer == nil then
        return
    else
        local spec = self.spec_highPressureWasherLance
        if spec.isActivated then
            if carryingPlayer.isOwner then
                local x, y, z = getWorldTranslation(spec.raycastNode)
                local dirX, dirY, dirZ = localDirectionToWorld(spec.raycastNode, 0, 0, 1)
                raycastAllAsync(x, y, z, dirX, dirY, dirZ, spec.washDistance, "onLanceCallback", self, CollisionFlag.VEHICLE)
                if spec.targetedVehicleId ~= spec.targetedVehicleIdSent then
                    spec.targetedVehicleIdSent = spec.targetedVehicleId
                    self:raiseDirtyFlags(spec.dirtyFlag)
                end
                if spec.targetedVehicleId == nil then
                    g_inputBinding:setActionEventText(spec.activateActionEventId, string.format(self.activateText, ""))
                else
                    local vehicle = NetworkUtil.getObject(spec.targetedVehicleId)
                    g_inputBinding:setActionEventText(spec.activateActionEventId, string.format(self.activateText, vehicle.typeDesc))
                end
            end
            if self.isServer then
                if spec.targetedVehicleId ~= nil then
                    local x = NetworkUtil.getObject(spec.targetedVehicleId)
                    if x ~= nil then
                        x:cleanVehicle(spec.washMultiplier * dt / x:getWashDuration())
                    end
                end
                local x = carryingPlayer.farmId
                local y = spec.pricePerSecond * dt * 0.001
                g_farmManager:updateFarmStats(x, "expenses", y)
                g_currentMission:addMoney(-y, x, MoneyType.VEHICLE_RUNNING_COSTS)
            end
        else
            spec.targetedVehicleId = nil
        end
    end
end
function HandToolHPWLance:onLanceCallback(nodeId, _, _, _, _, _, _, _, _, shapeId, _)
    local spec = self.spec_highPressureWasherLance
    spec.targetedVehicleId = nil
    if nodeId == 0 then
        return false
    end
    if not CollisionFlag.getHasMaskFlagSet(shapeId, CollisionFlag.VEHICLE) then
        return true
    end
    local vehicle = g_currentMission.vehicleSystem:getVehicleByNodeId(nodeId, shapeId)
    if vehicle == nil or (vehicle.getAllowsWashingByType == nil or not vehicle:getAllowsWashingByType(Washable.WASHTYPE_HIGH_PRESSURE_WASHER)) then
        return true
    end
    spec.targetedVehicleId = NetworkUtil.getObjectId(vehicle)
    return false
end
function HandToolHPWLance:setIsActivated(isActivated)
    local spec = self.spec_highPressureWasherLance
    if spec.isActivated == isActivated then
        return
    else
        local carryingPlayer = self:getCarryingPlayer()
        if carryingPlayer == nil then
            return
        else
            spec.isActivated = isActivated
            if carryingPlayer.isOwner then
                spec.isActivatedSent = isActivated
                self:raiseDirtyFlags(spec.dirtyFlag)
            end
            if spec.isActivated then
                g_effectManager:startEffects(spec.effects)
                g_soundManager:playSample(spec.washingSample)
            else
                g_effectManager:stopEffects(spec.effects)
                g_soundManager:stopSample(spec.washingSample)
            end
        end
    end
end
function HandToolHPWLance:onRegisterActionEvents()
    if self:getIsActiveForInput(true) then
        local _, actionEventId = self:addActionEvent(InputAction.ACTIVATE_HANDTOOL, self, HandToolHPWLance.onWashAction, false, false, true, true, nil)
        self.spec_highPressureWasherLance.activateActionEventId = actionEventId
        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
        g_inputBinding:setActionEventText(actionEventId, string.format(self.activateText, ""))
    end
end
function HandToolHPWLance:onWashAction(_, inputValue)
    self:setIsActivated(inputValue > 0)
end
function HandToolHPWLance:getCanBeDropped(superFunc)
    return false
end
function HandToolHPWLance:onHeldEnd()
    self:setIsActivated(false)
    self:returnToHolder(true)
end
function HandToolHPWLance:onDebugDraw(x, y, textSize)
    local spec = self.spec_highPressureWasherLance
    local vehicle = DebugUtil.renderTextLine
    local vehicle = vehicle(x, y, textSize, string.format("isActivated: %s", (tostring(spec.isActivated))))
    if spec.targetedVehicleId ~= nil then
        local vehicle = NetworkUtil.getObject(spec.targetedVehicleId)
        if vehicle ~= nil then
            vehicle = DebugUtil.renderTextLine(x, vehicle, textSize, string.format("Target: %q", vehicle.typeName))
        end
    end
    return vehicle
end