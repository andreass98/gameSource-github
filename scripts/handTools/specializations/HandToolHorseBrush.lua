HandToolHorseBrush = {}
function HandToolHorseBrush.registerXMLPaths(xmlSchema)
    xmlSchema:setXMLSpecializationType("HandToolHorseBrush")
    xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.horseBrush#node", "Node of the brush", nil, false)
    SoundManager.registerSampleXMLPaths(xmlSchema, "handTool.horseBrush.sounds", "cleaning")
    xmlSchema:setXMLSpecializationType()
end
function HandToolHorseBrush.registerEventListeners(handToolType)
    SpecializationUtil.registerEventListener(handToolType, "onLoad", HandToolHorseBrush)
    SpecializationUtil.registerEventListener(handToolType, "onDelete", HandToolHorseBrush)
    SpecializationUtil.registerEventListener(handToolType, "onUpdate", HandToolHorseBrush)
    SpecializationUtil.registerEventListener(handToolType, "onDraw", HandToolHorseBrush)
    SpecializationUtil.registerEventListener(handToolType, "onHeldStart", HandToolHorseBrush)
    SpecializationUtil.registerEventListener(handToolType, "onHeldEnd", HandToolHorseBrush)
    SpecializationUtil.registerEventListener(handToolType, "onRegisterActionEvents", HandToolHorseBrush)
end
function HandToolHorseBrush.prerequisitesPresent(specializations)
    return true
end
function HandToolHorseBrush:onLoad(xmlFile)
    local spec = self.spec_horseBrush
    spec.animalDetectionDistance = 3
    spec.brushNode = xmlFile:getValue("handTool.horseBrush#node", nil, self.components, self.i3dMappings)
    if spec.brushNode ~= nil then
        spec.originalPos = { getTranslation(spec.brushNode) }
    end
    if self.isClient then
        spec.samples = {}
        spec.samples.cleaning = g_soundManager:loadSampleFromXML(xmlFile, "handTool.horseBrush.sounds", "cleaning", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.defaultCrosshair = self:createCrosshairOverlay("gui.crosshairDefault")
        spec.brushCrosshair = self:createCrosshairOverlay("gui.horseBrush")
    end
    spec.targetedHusbandryId = nil
    spec.targetedClusterId = nil
    spec.dirtyFlag = self:getNextDirtyFlag()
    spec.cleaningDeltaPerMs = 0.01
    spec.deltaSum = 0
    spec.isBrushing = false
    spec.brushText = g_i18n:getText("action_interactAnimalClean")
end
function HandToolHorseBrush:onDelete()
    local spec = self.spec_horseBrush
    g_soundManager:deleteSamples(spec.samples)
    if spec.defaultCrosshair ~= nil then
        spec.defaultCrosshair:delete()
        spec.defaultCrosshair = nil
    end
    if spec.brushCrosshair ~= nil then
        spec.brushCrosshair:delete()
        spec.brushCrosshair = nil
    end
end
function HandToolHorseBrush:onUpdate(dt)
    local carryingPlayer = self:getCarryingPlayer()
    if carryingPlayer ~= nil then
        local spec = self.spec_horseBrush
        spec.targetedHusbandryId = nil
        spec.targetedClusterId = nil
        spec.targetedHusbandry = nil
        if carryingPlayer.isOwner then
            local targetNode = carryingPlayer.targeter:getClosestTargetedNodeFromType(HandToolHorseBrush)
            local husbandry, cluster = HandToolHorseBrush.getHusbandryAndClusterFromNode(carryingPlayer, targetNode)
            spec.targetedHusbandry = husbandry
            if husbandry ~= nil then
                g_inputBinding:setActionEventText(spec.activateActionEventId, string.format(spec.brushText, cluster:getName()))
            end
            local x = g_inputBinding
            local z = spec.activateActionEventId
            x:setActionEventActive(z, husbandry ~= nil)
            if husbandry ~= nil and spec.isCleaning then
                spec.targetedHusbandryId = NetworkUtil.getObjectId(husbandry)
                spec.targetedClusterId = cluster.id
                if spec.brushNode ~= nil then
                    setTranslation(spec.brushNode, spec.originalPos[1] + math.sin(g_time * 0.25 * 3.141592653589793) * 0.005, spec.originalPos[2] + math.sin(g_time * 0.25 * 3.141592653589793) * 0.001, spec.originalPos[3] + math.sin(g_time * 0.25 * 3.141592653589793) * 0.05)
                end
            end
            if spec.targetedHusbandryId ~= spec.targetedHusbandryIdSent then
                spec.targetedHusbandryIdSent = spec.targetedHusbandryId
                spec.targetedClusterIdSent = spec.targetedClusterId
                self:raiseDirtyFlags(spec.dirtyFlag)
            end
        end
        if self.isClient then
            if spec.targetedHusbandryId == nil then
                if g_soundManager:getIsSamplePlaying(spec.samples.cleaning) then
                    g_soundManager:stopSample(spec.samples.cleaning)
                end
            elseif not g_soundManager:getIsSamplePlaying(spec.samples.cleaning) then
                g_soundManager:playSample(spec.samples.cleaning)
            end
        end
        if spec.targetedHusbandryId == nil then
            spec.deltaSum = 0
        else
            local targetNode = NetworkUtil.getObject(spec.targetedHusbandryId)
            if targetNode ~= nil then
                spec.deltaSum = spec.deltaSum + spec.cleaningDeltaPerMs * dt
                if spec.deltaSum > 5 then
                    local husbandry = math.floor(spec.deltaSum)
                    spec.deltaSum = spec.deltaSum - husbandry
                    if targetNode:getClusterById(spec.targetedClusterId) ~= nil then
                        g_client:getServerConnection():sendEvent(AnimalCleanEvent.new(targetNode, spec.targetedClusterId, husbandry))
                        return
                    end
                end
            end
        end
    end
end
function HandToolHorseBrush:onDraw()
    local spec = self.spec_horseBrush
    if spec.treeTypeCrosshair ~= nil then
        spec.treeTypeCrosshair:render()
    end
    if spec.targetedHusbandry == nil then
        spec.defaultCrosshair:render()
    else
        spec.brushCrosshair:render()
    end
end
function HandToolHorseBrush:onRegisterActionEvents()
    if self:getIsActiveForInput(true) then
        local _, actionEventId = self:addActionEvent(InputAction.ACTIVATE_HANDTOOL, self, HandToolHorseBrush.onBrushAction, true, true, false, true, nil)
        self.spec_horseBrush.activateActionEventId = actionEventId
        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
        g_inputBinding:setActionEventText(actionEventId, "")
        g_inputBinding:setActionEventActive(actionEventId, false)
    end
end
function HandToolHorseBrush:onBrushAction(_, inputValue)
    self.spec_horseBrush.isCleaning = inputValue > 0
end
function HandToolHorseBrush:onHeldStart()
    if self:getCarryingPlayer().isOwner then
        self:getCarryingPlayer().targeter:addTargetType(HandToolHorseBrush, CollisionFlag.ANIMAL, 0.5, self.spec_horseBrush.animalDetectionDistance)
    end
end
function HandToolHorseBrush:onHeldEnd()
    local carryingPlayer = self:getCarryingPlayer()
    if carryingPlayer ~= nil and carryingPlayer.isOwner then
        carryingPlayer.targeter:removeTargetType(HandToolHorseBrush)
    end
    local spec = self.spec_horseBrush
    if spec.samples ~= nil then
        g_soundManager:stopSample(spec.samples.cleaning)
    end
end
function HandToolHorseBrush.getHusbandryAndClusterFromNode(carryingPlayer, node)
    if node == nil or not entityExists(node) then
        return nil, nil
    end
    local husbandryId, animalId = getAnimalFromCollisionNode(node)
    if husbandryId ~= nil and husbandryId ~= 0 then
        local mission = g_currentMission
        local clusterHusbandry = mission.husbandrySystem:getClusterHusbandryById(husbandryId)
        if clusterHusbandry ~= nil then
            local husbandry = clusterHusbandry:getPlaceable()
            local cluster = clusterHusbandry:getClusterByAnimalId(animalId)
            if cluster ~= nil and (mission.accessHandler:canFarmAccess(carryingPlayer.farmId, husbandry) and (cluster.changeDirt ~= nil and cluster.getName ~= nil)) then
                return husbandry, cluster
            end
        end
    end
    return nil, nil
end