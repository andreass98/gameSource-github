HandToolChainsaw = {}
source("dataS/scripts/handTools/events/ChainsawCutEvent.lua")
HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_XZ = nil
HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_Y = nil
HandToolChainsaw.CACHED_TARGETED_TREE = {
    ["node"] = nil,
    ["x"] = 0,
    ["y"] = 0,
    ["z"] = 0
}
HandToolChainsaw.TARGET_MASK = CollisionFlag.TREE + CollisionFlag.DYNAMIC_OBJECT
HandToolChainsaw.SPLIT_PLANE_OFFSET_Z = -0.2
HandToolChainsaw.ROOTS_HEIGHT_THRESHOLD = 0.01
HandToolChainsaw.GROUND_DISTANCE_THRESHOLD = 0.02
HandToolChainsaw.MINIMUM_CUT_DISTANCE = 0.5
HandToolChainsaw.MAXIMUM_CUT_DISTANCE = 1.5
HandToolChainsaw.ROTATION_SPEED = 0.003
HandToolChainsaw.VALID_CUT_COLOR = Color.new(0.395, 0.925, 0.115, 1)
HandToolChainsaw.INVALID_CUT_COLOR = Color.PRESETS.ORANGERED
source("dataS/scripts/handTools/specializations/ChainsawCutState.lua")
function HandToolChainsaw.registerXMLPaths(xmlSchema)
    xmlSchema:setXMLSpecializationType("HandToolChainsaw")
    xmlSchema:register(XMLValueType.STRING, "handTool.chainsaw.playerWorkStylePreset", "Name of the style preset", nil, false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.chainsaw#maximumCutDiameter", "The maximum diameter in metres that can be cut", 1, false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.chainsaw#maximumDelimbDiameter", "The maximum diameter range in metres that is used for delimb", 1, false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.chainsaw#cutTimePerSquareMeter", "The time in seconds per square metre that the chainsaw takes to cut", 1, false)
    xmlSchema:register(XMLValueType.STRING, "handTool.chainsaw.ringSelector#filename", "The path of the ring selector i3d file", nil, true)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.chainsaw.ringSelector#scaleOffset", "The size in metres added onto the ring indicator\'s scale", 0, false)
    xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.chainsaw.cutNode#node", "The name of the node used to position the chainsaw while cutting", nil, false)
    xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.chainsaw.handNode#cutting", "The name of the node used to position the chainsaw while cutting", nil, false)
    xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.chainsaw.handNode#walking", "The name of the node used to position the chainsaw while walking", nil, false)
    AnimationManager.registerAnimationNodesXMLPaths(xmlSchema, "handTool.chainsaw.chain")
    EffectManager.registerEffectXMLPaths(xmlSchema, "handTool.chainsaw.effects")
    SoundManager.registerSampleXMLPaths(xmlSchema, "handTool.chainsaw.sounds", "cut(?)")
end
function HandToolChainsaw.registerFunctions(handToolType)
    SpecializationUtil.registerFunction(handToolType, "calculateCutPlane", HandToolChainsaw.calculateCutPlane)
    SpecializationUtil.registerFunction(handToolType, "getChainSpeedFactor", HandToolChainsaw.getChainSpeedFactor)
    SpecializationUtil.registerFunction(handToolType, "testIfTooLow", HandToolChainsaw.testIfTooLow)
    SpecializationUtil.registerFunction(handToolType, "testIfCutAllowed", HandToolChainsaw.testIfCutAllowed)
    SpecializationUtil.registerFunction(handToolType, "testIfCutValid", HandToolChainsaw.testIfCutValid)
    SpecializationUtil.registerFunction(handToolType, "beginCutting", HandToolChainsaw.beginCutting)
    SpecializationUtil.registerFunction(handToolType, "stopCutting", HandToolChainsaw.stopCutting)
    SpecializationUtil.registerFunction(handToolType, "beginDelimbing", HandToolChainsaw.beginDelimbing)
    SpecializationUtil.registerFunction(handToolType, "stopDelimbing", HandToolChainsaw.stopDelimbing)
    SpecializationUtil.registerFunction(handToolType, "setCurrentCutState", HandToolChainsaw.setCurrentCutState)
    SpecializationUtil.registerFunction(handToolType, "updateCutting", HandToolChainsaw.updateCutting)
    SpecializationUtil.registerFunction(handToolType, "updateCuttingAnimation", HandToolChainsaw.updateCuttingAnimation)
    SpecializationUtil.registerFunction(handToolType, "updateSplitPlane", HandToolChainsaw.updateSplitPlane)
    SpecializationUtil.registerFunction(handToolType, "updateRingSelector", HandToolChainsaw.updateRingSelector)
end
function HandToolChainsaw.registerEventListeners(handToolType)
    SpecializationUtil.registerEventListener(handToolType, "onDelete", HandToolChainsaw)
    SpecializationUtil.registerEventListener(handToolType, "onLoad", HandToolChainsaw)
    SpecializationUtil.registerEventListener(handToolType, "onPostLoad", HandToolChainsaw)
    SpecializationUtil.registerEventListener(handToolType, "onUpdate", HandToolChainsaw)
    SpecializationUtil.registerEventListener(handToolType, "onDraw", HandToolChainsaw)
    SpecializationUtil.registerEventListener(handToolType, "onWriteUpdateStream", HandToolChainsaw)
    SpecializationUtil.registerEventListener(handToolType, "onReadUpdateStream", HandToolChainsaw)
    SpecializationUtil.registerEventListener(handToolType, "onHeldStart", HandToolChainsaw)
    SpecializationUtil.registerEventListener(handToolType, "onHeldEnd", HandToolChainsaw)
    SpecializationUtil.registerEventListener(handToolType, "onRegisterActionEvents", HandToolChainsaw)
end
function HandToolChainsaw.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(HandToolMotorized, specializations)
end
function HandToolChainsaw:onLoad(xmlFile, baseDirectory)
    local spec = self.spec_chainsaw
    if HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_XZ == nil then
        local mission = g_currentMission
        HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_XZ = NetworkUtil.createWorldPositionCompressionParams(mission.terrainSize + 10, 0.5 * (mission.terrainSize + 10), 0.01)
        HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_Y = NetworkUtil.createWorldPositionCompressionParams(1500, 0, 0.01)
    end
    spec.dirtyFlag = self:getNextDirtyFlag()
    spec.revText = g_i18n:getText("action_revHandToolMotor")
    spec.cutText = g_i18n:getText("action_startCuttingChainsaw")
    spec.rollText = g_i18n:getText("action_rollChainsaw")
    spec.currentCutState = ChainsawCutState.IDLE
    spec.currentCutStateSent = spec.currentCutState
    spec.isVerticalCut = true
    spec.removedAttachmentsSent = false
    spec.targetedTree = nil
    spec.cuttingTreeNode = nil
    spec.currentCutRoll = 0
    spec.rollInput = 0
    spec.isCutting = false
    spec.cutMinimumY = nil
    spec.cutMaximumY = nil
    spec.cutMinimumZ = nil
    spec.cutMaximumZ = nil
    spec.cutStartPositionX = 0
    spec.cutStartPositionY = 0
    spec.cutStartPositionZ = 0
    spec.cutEndPositionX = 0
    spec.cutEndPositionY = 0
    spec.cutEndPositionZ = 0
    spec.smoothingCurve = BezierCurve.new(0.11, 0.54, 0.91, 0.5)
    spec.playerWorkStylePreset = xmlFile:getValue("handTool.chainsaw.playerWorkStylePreset")
    spec.maximumDelimbDiameter = xmlFile:getValue("handTool.chainsaw#maximumDelimbDiameter", 1)
    spec.maximumCutDiameter = xmlFile:getValue("handTool.chainsaw#maximumCutDiameter", 1)
    spec.cutTimePerSquareMeter = xmlFile:getValue("handTool.chainsaw#cutTimePerSquareMeter", 1) * 1000
    spec.currentCutTime = 0
    spec.currentTargetCutTime = 0
    spec.currentTargetStartupTime = 0
    spec.startupTime = 1000
    spec.cutNode = xmlFile:getValue("handTool.chainsaw.cutNode#node", nil, self.components, self.i3dMappings)
    if spec.cutNode == nil then
        Logging.xmlWarning(xmlFile, "Chainsaw is missing cut node, root node will be used instead!")
        spec.cutNode = self.rootNode
    end
    spec.handNodeCutting = xmlFile:getValue("handTool.chainsaw.handNode#cutting", nil, self.components, self.i3dMappings)
    spec.handNodeWalking = xmlFile:getValue("handTool.chainsaw.handNode#walking", nil, self.components, self.i3dMappings)
    local mission = xmlFile:getValue("handTool.chainsaw.ringSelector#filename", nil)
    if mission ~= nil then
        local mission = Utils.getFilename(mission, self.baseDirectory)
        spec.ringSharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(mission, true, false, HandToolChainsaw.onRingLoadFinished, self, nil)
        spec.ringLoadingTask = self:createLoadingTask(spec)
        spec.ringScaleOffset = xmlFile:getValue("handTool.chainsaw.ringSelector#scaleOffset", 0)
    end
    spec.cutGuideNode = createTransformGroup("chainsawCutGuideNode")
    link(getRootNode(), spec.cutGuideNode)
    spec.cameraRotationNode = createTransformGroup("chainsawCameraRotationNode")
    link(getRootNode(), spec.cameraRotationNode)
    spec.splitPlaneNode = createTransformGroup("chainsawSplitPlaneNode")
    link(spec.cameraRotationNode, spec.splitPlaneNode)
    setRotation(spec.splitPlaneNode, 0, 0, -1.5707963267948966)
    setTranslation(spec.splitPlaneNode, -0.1, spec.maximumCutDiameter / 2, HandToolChainsaw.SPLIT_PLANE_OFFSET_Z)
    if self.isClient then
        spec.effectEndTime = 0
        spec.isPlayingEffects = false
        spec.effects = g_effectManager:loadEffect(xmlFile, "handTool.chainsaw.effects", self.components, self, self.i3dMappings)
        g_effectManager:setEffectTypeInfo(spec.effects, FillType.WOOD)
        spec.isPlayingChainAnimation = false
        spec.chainsAnimation = g_animationManager:loadAnimations(xmlFile, "handTool.chainsaw.chain", self.components, spec, self.i3dMappings)
        for i, animation in ipairs(spec.chainsAnimation) do
            spec.startupTime = math.max(spec.startupTime, animation.turnOnFadeTime)
        end
        spec.cutSamples = g_soundManager:loadSamplesFromXML(xmlFile, "handTool.chainsaw.sounds", "cut", baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    spec.delimbEffectDuration = 100
    spec.lastDelimbPosX = 0
    spec.lastDelimbPosY = 0
    spec.lastDelimbPosZ = 0
    spec.lastDelimbNormalX = 1
    spec.lastDelimbNormalY = 0
    spec.lastDelimbNormalZ = 0
    spec.lastDelimbUpX = 0
    spec.lastDelimbUpY = 1
    spec.lastDelimbUpZ = 0
    if self.isClient then
        spec.crosshair = self:createCrosshairOverlay("gui.crosshairDefault")
    end
    self.walkMultiplier = 0.5
end
function HandToolChainsaw:onPostLoad(_)
    local spec = self.spec_chainsaw
    local motorizedSpec = self.spec_motorized
    self:setRPMGainPerSecond((motorizedSpec.maxRPM - motorizedSpec.minRPM) / (spec.startupTime * 0.001))
    self:setRPMLossPerSecond((motorizedSpec.maxRPM - motorizedSpec.minRPM) / (spec.startupTime * 0.001) * 1.2)
end
function HandToolChainsaw:onRingLoadFinished(ringNode, _)
    local spec = self.spec_chainsaw
    self:finishLoadingTask(spec.ringLoadingTask)
    spec.ringLoadingTask = nil
    if ringNode == nil or ringNode == 0 then
        Logging.error("Chainsaw could not load ring indicator i3d!")
    else
        spec.ringNode = getChildAt(ringNode, 0)
        setVisibility(spec.ringNode, false)
        link(spec.cameraRotationNode, spec.ringNode)
        delete(ringNode)
    end
end
function HandToolChainsaw:onDelete()
    local spec = self.spec_chainsaw
    if spec.ringSharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(spec.ringSharedLoadRequestId)
        spec.ringSharedLoadRequestId = nil
    end
    if spec.chainsAnimation ~= nil then
        g_animationManager:deleteAnimations(spec.chainsAnimation)
    end
    g_effectManager:deleteEffects(spec.effects)
    g_soundManager:deleteSamples(spec.cutSamples)
    if spec.cutGuideNode ~= nil then
        delete(spec.cutGuideNode)
        spec.cutGuideNode = nil
    end
    if spec.cameraRotationNode ~= nil then
        delete(spec.cameraRotationNode)
        spec.cameraRotationNode = nil
        spec.splitPlaneNode = nil
        spec.ringNode = nil
    end
    if self:getCarryingPlayer() ~= nil then
        self:getCarryingPlayer().targeter:removeTargetType(HandToolChainsaw)
    end
    if spec.crosshair ~= nil then
        spec.crosshair:delete()
        spec.crosshair = nil
    end
end
function HandToolChainsaw:onWriteUpdateStream(streamId, connection, dirtyMask)
    local spec = self.spec_chainsaw
    if streamWriteBool(streamId, bit32.band(dirtyMask, spec.dirtyFlag) ~= 0) then
        ChainsawCutState.writeStream(streamId, spec.currentCutStateSent)
        if spec.currentCutStateSent == ChainsawCutState.CUTTING then
            streamWriteBool(streamId, spec.isVerticalCut)
        end
        if connection:getIsServer() then
            if spec.currentCutStateSent == ChainsawCutState.DELIMBING then
                NetworkUtil.writeCompressedWorldPosition(streamId, spec.lastDelimbPosX, HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_XZ)
                NetworkUtil.writeCompressedWorldPosition(streamId, spec.lastDelimbPosY, HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_Y)
                NetworkUtil.writeCompressedWorldPosition(streamId, spec.lastDelimbPosZ, HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_XZ)
                NetworkUtil.writeCompressedRange(streamId, spec.lastDelimbNormalX, -1, 1, 12)
                NetworkUtil.writeCompressedRange(streamId, spec.lastDelimbNormalY, -1, 1, 12)
                NetworkUtil.writeCompressedRange(streamId, spec.lastDelimbNormalZ, -1, 1, 12)
                NetworkUtil.writeCompressedRange(streamId, spec.lastDelimbUpX, -1, 1, 12)
                NetworkUtil.writeCompressedRange(streamId, spec.lastDelimbUpY, -1, 1, 12)
                NetworkUtil.writeCompressedRange(streamId, spec.lastDelimbUpZ, -1, 1, 12)
                return
            end
        else
            streamWriteBool(streamId, spec.removedAttachmentsSent)
        end
    end
end
function HandToolChainsaw:onReadUpdateStream(streamId, _, connection)
    local carryingPlayer = self:getCarryingPlayer()
    if streamReadBool(streamId) then
        local receivedState = ChainsawCutState.readStream(streamId)
        local isVerticalCut = true
        if receivedState == ChainsawCutState.CUTTING then
            isVerticalCut = streamReadBool(streamId)
        end
        if carryingPlayer == nil or not carryingPlayer.isOwner then
            self:setCurrentCutState(receivedState, isVerticalCut)
        end
        if connection:getIsServer() then
            if streamReadBool(streamId) and (carryingPlayer ~= nil and carryingPlayer.isOwner) then
                self.spec_chainsaw.effectEndTime = g_time + self.spec_chainsaw.delimbEffectDuration
            end
        elseif receivedState == ChainsawCutState.DELIMBING then
            spec.lastDelimbPosX = NetworkUtil.readCompressedWorldPosition(streamId, HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_XZ)
            spec.lastDelimbPosY = NetworkUtil.readCompressedWorldPosition(streamId, HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_Y)
            spec.lastDelimbPosZ = NetworkUtil.readCompressedWorldPosition(streamId, HandToolChainsaw.WORLD_POSITION_COMPRESSION_PARAMS_XZ)
            spec.lastDelimbNormalX = NetworkUtil.readCompressedRange(streamId, -1, 1, 12)
            spec.lastDelimbNormalY = NetworkUtil.readCompressedRange(streamId, -1, 1, 12)
            spec.lastDelimbNormalZ = NetworkUtil.readCompressedRange(streamId, -1, 1, 12)
            spec.lastDelimbUpX = NetworkUtil.readCompressedRange(streamId, -1, 1, 12)
            spec.lastDelimbUpY = NetworkUtil.readCompressedRange(streamId, -1, 1, 12)
            spec.lastDelimbUpZ = NetworkUtil.readCompressedRange(streamId, -1, 1, 12)
            return
        end
    end
end
function HandToolChainsaw:onUpdate(dt)
    local carryingPlayer = self:getCarryingPlayer()
    if carryingPlayer ~= nil then
        if carryingPlayer.isOwner and self:getIsHeld() then
            self.spec_chainsaw.targetedTree = self:getCarryingPlayer().targeter.closestTargetsByKey[HandToolChainsaw]
            spec.possibleTreeNode = nil
            self:updateSplitPlane()
            if spec.currentCutState ~= ChainsawCutState.CUTTING then
                if spec.rollInput ~= 0 then
                    spec.currentCutRoll = math.clamp(spec.currentCutRoll + HandToolChainsaw.ROTATION_SPEED * spec.rollInput * dt, -1.5707963267948966, 1.5707963267948966)
                    spec.rollInput = 0
                end
                if self.graphicalNode ~= nil then
                    local upX, upY, upZ = localDirectionToLocal(spec.cameraRotationNode, getParent(self.graphicalNode), 0, 1, 0)
                    local cameraNode = g_cameraManager:getActiveCamera()
                    local dirX, dirY, dirZ = localDirectionToLocal(cameraNode, getParent(self.graphicalNode), 0, 0, -1)
                    setDirection(self.graphicalNode, dirX, dirY, dirZ, upX, upY, upZ)
                end
            end
            local upX = false
            if spec.currentCutState == ChainsawCutState.IDLE or spec.currentCutState == ChainsawCutState.CUTTING then
                local upY = spec.cuttingTreeNode
                if upY == nil and spec.targetedTree ~= nil then
                    upY = spec.targetedTree.node
                end
                if upY ~= nil then
                    local upZ, cameraNode, dirX = getWorldTranslation(spec.cameraRotationNode)
                    if self:testIfCutValid(upY, upZ, dirX, spec.cutMinimumY, spec.cutMaximumY, spec.cutMinimumZ, spec.cutMaximumZ) then
                        if spec.cuttingTreeNode == nil then
                            spec.possibleTreeNode = upY
                        end
                        upX = true
                    elseif spec.cuttingTreeNode ~= nil then
                        self:stopCutting(false)
                    end
                end
            end
            if spec.currentCutState == ChainsawCutState.IDLE then
                if upX then
                    g_inputBinding:setActionEventText(spec.activateActionId, spec.cutText)
                else
                    g_inputBinding:setActionEventText(spec.activateActionId, string.format(spec.revText, self.typeDesc))
                end
                g_inputBinding:setActionEventTextVisibility(spec.activateActionId, true)
                self:updateRingSelector(spec.targetedTree, upX, spec.cutMinimumY, spec.cutMaximumY, spec.cutMinimumZ, spec.cutMaximumZ)
            elseif spec.currentCutState == ChainsawCutState.CUTTING then
                g_inputBinding:setActionEventTextVisibility(spec.activateActionId, false)
                self:updateCutting(dt)
            end
        end
        if spec.currentCutState == ChainsawCutState.DELIMBING then
            if carryingPlayer.isOwner then
                local upX, upY, upZ, cameraNode, dirX, dirY, dirZ, upY, upZ = self:calculateCutPlane()
                spec.lastDelimbPosX = upX
                spec.lastDelimbPosY = upY
                spec.lastDelimbPosZ = upZ
                spec.lastDelimbNormalX = cameraNode
                spec.lastDelimbNormalY = dirX
                spec.lastDelimbNormalZ = dirY
                spec.lastDelimbUpX = dirZ
                spec.lastDelimbUpY = upY
                spec.lastDelimbUpZ = upZ
                self:raiseDirtyFlags(spec.dirtyFlag)
            end
            if self.isServer then
                local removedAttachment = findAndRemoveSplitShapeAttachments(spec.lastDelimbPosX, spec.lastDelimbPosY, spec.lastDelimbUpZ, spec.lastDelimbNormalX, spec.lastDelimbNormalY, spec.lastDelimbNormalZ, spec.lastDelimbUpX, spec.lastDelimbUpY, spec.lastDelimbPosZ, 0.7, spec.maximumDelimbDiameter, spec.maximumDelimbDiameter + HandToolChainsaw.SPLIT_PLANE_OFFSET_Z)
                if spec.removedAttachmentsSent ~= removedAttachment then
                    spec.removedAttachmentsSent = removedAttachment
                    self:raiseDirtyFlags(spec.dirtyFlag)
                end
                if removedAttachment then
                    spec.effectEndTime = g_time + spec.delimbEffectDuration
                end
            end
        end
        if self.isClient then
            if spec.effectEndTime > g_time then
                if not spec.isPlayingEffects then
                    g_effectManager:startEffects(spec.effects)
                    g_soundManager:playSamples(spec.cutSamples)
                    spec.isPlayingEffects = true
                end
            elseif spec.isPlayingEffects then
                g_effectManager:stopEffects(spec.effects)
                g_soundManager:stopSamples(spec.cutSamples)
                spec.isPlayingEffects = false
            end
            if self:getCurrentRPM() > self:getMinRPM() then
                if not spec.isPlayingChainAnimation then
                    g_animationManager:startAnimations(spec.chainsAnimation)
                    spec.isPlayingChainAnimation = true
                    return
                end
            elseif spec.isPlayingChainAnimation then
                g_animationManager:stopAnimations(spec.chainsAnimation)
                spec.isPlayingChainAnimation = false
            end
        end
    end
end
function HandToolChainsaw:onDraw()
    local spec = self.spec_chainsaw
    if spec.crosshair ~= nil and spec.currentCutState == ChainsawCutState.IDLE then
        spec.crosshair:render()
    end
end
function HandToolChainsaw:onHeldStart()
    local carryingPlayer = self:getCarryingPlayer()
    if carryingPlayer ~= nil then
        if carryingPlayer.isOwner then
            local targeter = carryingPlayer.targeter
            targeter:addTargetType(HandToolChainsaw, HandToolChainsaw.TARGET_MASK, HandToolChainsaw.MINIMUM_CUT_DISTANCE, HandToolChainsaw.MAXIMUM_CUT_DISTANCE)
            targeter:addFilterToTargetType(HandToolChainsaw, function(hitNode, _, _, _)
                return hitNode ~= nil and hitNode ~= 0 and getHasClassId(hitNode, ClassIds.MESH_SPLIT_SHAPE)
            end)
        else
            setTranslation(self.graphicalNode, 0, 0, 0)
            setRotation(self.graphicalNode, 0, 0, 0)
        end
        local targeter = self.spec_chainsaw
        if targeter.playerWorkStylePreset ~= nil then
            carryingPlayer:applyCustomWorkStyle(targeter.playerWorkStylePreset)
            carryingPlayer:setIsHoldingChainsaw(true)
        end
    end
end
function HandToolChainsaw:onHeldEnd()
    local spec = self.spec_chainsaw
    local carryingPlayer = self:getCarryingPlayer()
    if carryingPlayer ~= nil then
        if carryingPlayer.isOwner then
            carryingPlayer.targeter:removeTargetType(HandToolChainsaw)
        end
        if spec.playerWorkStylePreset ~= nil then
            carryingPlayer:applyCustomWorkStyle(nil)
            carryingPlayer:setIsHoldingChainsaw(false)
        end
    end
    if spec.currentCutState == ChainsawCutState.DELIMBING then
        self:stopDelimbing()
    elseif spec.currentCutState == ChainsawCutState.CUTTING then
        self:stopCutting(false)
    end
    g_animationManager:stopAnimations(spec.chainsAnimation)
    spec.isPlayingChainAnimation = false
    if spec.ringNode ~= nil then
        setVisibility(spec.ringNode, false)
    end
    spec.rollInput = 0
end
function HandToolChainsaw:onRegisterActionEvents()
    if self:getIsActiveForInput(true) then
        local _, actionEventId = self:addActionEvent(InputAction.AXIS_ROTATE_HANDTOOL, self, HandToolChainsaw.onRollAction, false, false, true, true, nil)
        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
        g_inputBinding:setActionEventText(actionEventId, string.format(self.spec_chainsaw.rollText, self.typeDesc))
        local _, actionEventId = self:addActionEvent(InputAction.ACTIVATE_HANDTOOL, self, HandToolChainsaw.onCutAction, true, true, false, true, nil)
        spec.activateActionId = actionEventId
        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
        g_inputBinding:setActionEventText(actionEventId, string.format(spec.revText, self.typeDesc))
    end
end
function HandToolChainsaw:onRollAction(_, inputDelta)
    local spec = self.spec_chainsaw
    spec.rollInput = spec.rollInput + inputDelta
end
function HandToolChainsaw:onCutAction(_, inputValue)
    local isInputDown = inputValue > 0
    local spec = self.spec_chainsaw
    spec.isCutting = isInputDown
    if isInputDown then
        if spec.targetedTree == nil then
            self:beginDelimbing()
        else
            self:beginCutting()
            if spec.currentCutState ~= ChainsawCutState.CUTTING then
                self:beginDelimbing()
            end
        end
    elseif spec.currentCutState == ChainsawCutState.CUTTING then
        self:stopCutting(false)
        return
    elseif spec.currentCutState == ChainsawCutState.DELIMBING then
        self:stopDelimbing()
    else
        spec.currentCutState = ChainsawCutState.IDLE
    end
end
function HandToolChainsaw:setCurrentCutState(cutState, isVerticalCut)
    local spec = self.spec_chainsaw
    spec.currentCutState = cutState
    spec.isVerticalCut = isVerticalCut
    local carryingPlayer = self:getCarryingPlayer()
    if self.isServer or carryingPlayer ~= nil and carryingPlayer.isOwner then
        spec.currentCutStateSent = spec.currentCutState
        self:raiseDirtyFlags(spec.dirtyFlag)
    end
    if carryingPlayer ~= nil then
        carryingPlayer:setChainsawState(cutState == ChainsawCutState.CUTTING, isVerticalCut)
    end
end
function HandToolChainsaw:testIfCutAllowed(treeNode, cutX, cutZ)
    local carryingPlayer = self:getCarryingPlayer()
    if carryingPlayer == nil then
        return false
    elseif g_currentMission:getHasPlayerPermission(Farm.PERMISSION.CUT_TREES) then
        return g_splitShapeManager:getIsShapeCutAllowed(cutX, cutZ, treeNode, carryingPlayer:getFarmId()) and true or false
    else
        return false
    end
end
function HandToolChainsaw:testIfCutValid(treeNode, _, _, minY, maxY, minZ, maxZ)
    if self:testIfTooLow(treeNode, minY, maxY, minZ, maxZ) then
        return maxY - minY < self.spec_chainsaw.maximumCutDiameter and maxZ - minZ < self.spec_chainsaw.maximumCutDiameter
    else
        return false
    end
end
function HandToolChainsaw:testIfTooLow(treeNode, minY, maxY, minZ, maxZ)
    if treeNode == nil or (treeNode == 0 or not entityExists(treeNode)) then
        return false
    end
    if minY == nil or (maxY == nil or (minZ == nil or maxZ == nil)) then
        return false
    end
    if getRigidBodyType(treeNode) ~= RigidBodyType.STATIC then
        return true
    end
    local spec = self.spec_chainsaw
    local x1, y1, z1 = localToWorld(spec.splitPlaneNode, minY, 0, minZ)
    local x2, y2, z2 = localToWorld(spec.splitPlaneNode, minY, 0, maxZ)
    local x3, y3, z3 = localToWorld(spec.splitPlaneNode, maxY, 0, minZ)
    local x4, y4, z4 = localToWorld(spec.splitPlaneNode, maxY, 0, maxZ)
    local _, distanceFromRootsY1 = worldToLocal(treeNode, x1, y1, z1)
    local _, distanceFromRootsY2 = worldToLocal(treeNode, x2, y2, z2)
    local _, distanceFromRootsY3 = worldToLocal(treeNode, x3, y3, z3)
    local _, distanceFromRootsY4 = worldToLocal(treeNode, x4, y4, z4)
    local rootDistanceValid1 = HandToolChainsaw.ROOTS_HEIGHT_THRESHOLD <= distanceFromRootsY1
    local distanceFromTerrainY1 = y1 - getTerrainHeightAtWorldPos(g_terrainNode, x1, y1, z1)
    local distanceFromTerrainY2 = y2 - getTerrainHeightAtWorldPos(g_terrainNode, x2, y2, z2)
    local distanceFromTerrainY3 = y3 - getTerrainHeightAtWorldPos(g_terrainNode, x3, y3, z3)
    local distanceFromTerrainY4 = y4 - getTerrainHeightAtWorldPos(g_terrainNode, x4, y4, z4)
    local terrainDistanceValid4 = HandToolChainsaw.GROUND_DISTANCE_THRESHOLD <= distanceFromTerrainY4
    if bit32.band(Player.DEBUG_DISPLAY_FLAG.HANDTOOLS, Player.currentDebugFlag) ~= 0 then
        drawDebugPoint(x1, y1, z1, rootDistanceValid1 and 0 or 1, rootDistanceValid1 and 1 or 0, 0, 1, true)
        drawDebugPoint(x2, y2, z2, HandToolChainsaw.ROOTS_HEIGHT_THRESHOLD <= distanceFromRootsY2 and 0 or 1, rootDistanceValid2 and 1 or 0, 0, 1, true)
        drawDebugPoint(x3, y3, z3, HandToolChainsaw.ROOTS_HEIGHT_THRESHOLD <= distanceFromRootsY3 and 0 or 1, rootDistanceValid3 and 1 or 0, 0, 1, true)
        drawDebugPoint(x4, y4, z4, HandToolChainsaw.ROOTS_HEIGHT_THRESHOLD <= distanceFromRootsY4 and 0 or 1, rootDistanceValid4 and 1 or 0, 0, 1, true)
        drawDebugLine(x1, y1, z1, rootDistanceValid1 and 0 or 1, rootDistanceValid1 and 1 or 0, 0, x1, y1 - (distanceFromRootsY1 + HandToolChainsaw.ROOTS_HEIGHT_THRESHOLD), z1, 1, 0, 0, true)
        drawDebugLine(x2, y2, z2, rootDistanceValid2 and 0 or 1, rootDistanceValid2 and 1 or 0, 0, x2, y2 - (distanceFromRootsY2 + HandToolChainsaw.ROOTS_HEIGHT_THRESHOLD), z2, 1, 0, 0, true)
        drawDebugLine(x3, y3, z3, rootDistanceValid3 and 0 or 1, rootDistanceValid3 and 1 or 0, 0, x3, y3 - (distanceFromRootsY3 + HandToolChainsaw.ROOTS_HEIGHT_THRESHOLD), z3, 1, 0, 0, true)
        drawDebugLine(x4, y4, z4, rootDistanceValid4 and 0 or 1, rootDistanceValid4 and 1 or 0, 0, x4, y4 - (distanceFromRootsY4 + HandToolChainsaw.ROOTS_HEIGHT_THRESHOLD), z4, 1, 0, 0, true)
        drawDebugLine(x1, y1, z1, HandToolChainsaw.GROUND_DISTANCE_THRESHOLD <= distanceFromTerrainY1 and 0 or 1, terrainDistanceValid1 and 1 or 0, 0, x1, y1 - (distanceFromTerrainY1 + HandToolChainsaw.GROUND_DISTANCE_THRESHOLD), z1, 1, 0, 0, true)
        drawDebugLine(x2, y2, z2, HandToolChainsaw.GROUND_DISTANCE_THRESHOLD <= distanceFromTerrainY2 and 0 or 1, terrainDistanceValid2 and 1 or 0, 0, x2, y2 - (distanceFromTerrainY2 + HandToolChainsaw.GROUND_DISTANCE_THRESHOLD), z2, 1, 0, 0, true)
        drawDebugLine(x3, y3, z3, HandToolChainsaw.GROUND_DISTANCE_THRESHOLD <= distanceFromTerrainY3 and 0 or 1, terrainDistanceValid3 and 1 or 0, 0, x3, y3 - (distanceFromTerrainY3 + HandToolChainsaw.GROUND_DISTANCE_THRESHOLD), z3, 1, 0, 0, true)
        drawDebugLine(x4, y4, z4, terrainDistanceValid4 and 0 or 1, terrainDistanceValid4 and 1 or 0, 0, x4, y4 - (distanceFromTerrainY4 + HandToolChainsaw.GROUND_DISTANCE_THRESHOLD), z4, 1, 0, 0, true)
    end
    if rootDistanceValid1 then
        if rootDistanceValid2 then
            if rootDistanceValid3 then
                if rootDistanceValid4 then
                    if terrainDistanceValid1 then
                        if terrainDistanceValid2 then
                            if not terrainDistanceValid3 then
                                terrainDistanceValid4 = terrainDistanceValid3
                            end
                        else
                            terrainDistanceValid4 = terrainDistanceValid2
                        end
                    else
                        terrainDistanceValid4 = terrainDistanceValid1
                    end
                else
                    terrainDistanceValid4 = rootDistanceValid4
                end
            else
                terrainDistanceValid4 = rootDistanceValid3
            end
        else
            terrainDistanceValid4 = rootDistanceValid2
        end
    else
        terrainDistanceValid4 = rootDistanceValid1
    end
    return terrainDistanceValid4
end
function HandToolChainsaw:getChainSpeedFactor()
    local motorizedSpec = self.spec_motorized
    return MathUtil.inverseLerp(0.3, 1, MathUtil.lerp(motorizedSpec.minRPM, motorizedSpec.maxRPM, motorizedSpec.currentRPM))
end
function HandToolChainsaw:beginDelimbing()
    local player = self:getCarryingPlayer()
    if player ~= nil and player.isOwner then
        self:setCurrentCutState(ChainsawCutState.DELIMBING, true)
        self:setCurrentLoad(0)
        self:setTargetRPMToMax()
        g_inputBinding:setActionEventTextVisibility(self.spec_chainsaw.activateActionId, false)
    end
end
function HandToolChainsaw:stopDelimbing()
    self:setCurrentCutState(ChainsawCutState.IDLE, true)
    self.spec_chainsaw.effectEndTime = 0
    self:setCurrentLoad(0)
    self:setTargetRPMToIdle()
end
function HandToolChainsaw:beginCutting()
    local spec = self.spec_chainsaw
    if spec.ringNode ~= nil then
        setVisibility(spec.ringNode, false)
    end
    local player = self:getCarryingPlayer()
    if player == nil or not player.isOwner then
        return
    elseif spec.possibleTreeNode == nil then
        return
    else
        local cutX, _, cutZ = getWorldTranslation(spec.cameraRotationNode)
        if self:testIfCutAllowed(spec.possibleTreeNode, cutX, cutZ) then
            local mission, _, rotZ = getRotation(spec.cameraRotationNode)
            self:setCurrentCutState(ChainsawCutState.CUTTING, rotZ < 0.7)
            spec.cuttingTreeNode = spec.possibleTreeNode
            self:setCurrentLoad(0)
            spec.currentCutTime = 0
            spec.currentTargetStartupTime = math.max(math.floor(self:getTimeToReachRPM(self:getMaxRPM()) * 1000), 0.00001)
            spec.currentTargetCutTime = (spec.cutMaximumZ - spec.cutMinimumZ) * (spec.cutMaximumY - spec.cutMinimumY) * 3.141592653589793 * spec.cutTimePerSquareMeter + spec.currentTargetStartupTime
            spec.cutRevPositionX, spec.cutRevPositionY, spec.cutRevPositionZ = localToWorld(spec.splitPlaneNode, spec.cutMinimumY - 0.05, 0, spec.cutMinimumZ)
            spec.cutStartPositionX, spec.cutStartPositionY, spec.cutStartPositionZ = localToWorld(spec.splitPlaneNode, spec.cutMinimumY, 0, spec.cutMinimumZ)
            spec.cutEndPositionX, spec.cutEndPositionY, spec.cutEndPositionZ = localToWorld(spec.splitPlaneNode, spec.cutMaximumY, 0, spec.cutMinimumZ)
            HandToolUtil.linkAndTransformRelativeToParent(self.graphicalNode, spec.cutNode, spec.cutGuideNode)
            if player.inputComponent ~= nil then
                player.inputComponent:lock()
            end
        else
            g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youAreNotAllowedToCutThisTree"), 2000)
        end
    end
end
function HandToolChainsaw:stopCutting(sliceTree)
    local player = self:getCarryingPlayer()
    if player ~= nil and player.isOwner then
        local cuttingTreeNode = self.spec_chainsaw.cuttingTreeNode
        spec.cuttingTreeNode = nil
        self:setCurrentCutState(ChainsawCutState.IDLE, true)
        spec.currentCutTime = 0
        self:setCurrentLoad(0)
        self:setTargetRPMToIdle()
        if player.isOwner then
            link(self.graphicalNodeParent, self.graphicalNode)
            setTranslation(self.graphicalNode, 0, 0, 0)
            player.inputComponent:unlock()
        end
        spec.effectEndTime = 0
        if sliceTree and cuttingTreeNode ~= nil then
            local x, y, z, downX, downY, downZ, leftX, leftY, leftZ, planeWidth, planeDepth = self:calculateCutPlane()
            if self.isServer then
                ChainsawUtil.cutSplitShape(cuttingTreeNode, x, y, z, downX, downY, downZ, leftX, leftY, leftZ, planeWidth, planeDepth, self:getOwnerFarmId())
                return
            end
            g_client:getServerConnection():sendEvent(ChainsawCutEvent.new(cuttingTreeNode, x, y, z, downX, downY, downZ, leftX, leftY, leftZ, planeWidth, planeDepth, self:getOwnerFarmId()))
        end
    end
end
function HandToolChainsaw:updateCutting(dt)
    local spec = self.spec_chainsaw
    local cutPositionX, cutPositionY, cutPositionZ = getWorldTranslation(spec.cameraRotationNode)
    local playerTargeter = self:getCarryingPlayer().targeter
    self:updateCuttingAnimation(dt)
    self:setTargetRPMToMax()
    spec.currentCutTime = spec.currentCutTime + dt
    if MathUtil.vector3Length(playerTargeter.lastRayX - cutPositionX, playerTargeter.lastRayY - cutPositionY, playerTargeter.lastRayZ - cutPositionZ) >= HandToolChainsaw.MAXIMUM_CUT_DISTANCE then
        self:stopCutting(false)
    elseif spec.currentCutTime >= spec.currentTargetCutTime then
        self:stopCutting(true)
    end
end
function HandToolChainsaw:updateCuttingAnimation(dt)
    local spec = self.spec_chainsaw
    local cutCurrentPositionX, cutCurrentPositionY, cutCurrentPositionZ
    if spec.currentCutTime <= spec.currentTargetStartupTime then
        local cutCurrentProgress = math.clamp(spec.currentCutTime / spec.currentTargetStartupTime, 0, 1)
        cutCurrentPositionX, cutCurrentPositionY, cutCurrentPositionZ = MathUtil.vector3Lerp(spec.cutRevPositionX, spec.cutRevPositionY, spec.cutRevPositionZ, spec.cutStartPositionX, spec.cutStartPositionY, spec.cutStartPositionZ, cutCurrentProgress)
        self:setCurrentLoad(0)
    else
        spec.effectEndTime = g_time + 200
        local cutCurrentProgress = math.clamp((spec.currentCutTime - spec.currentTargetStartupTime) / (spec.currentTargetCutTime - spec.currentTargetStartupTime), 0, 1)
        self:setCurrentLoad((math.clamp(dt / (spec.currentTargetCutTime - spec.currentTargetStartupTime) / math.max(cutLastProgress - spec.smoothingCurve:solve(cutLastProgress), 0.00001), 0, 1)))
        cutCurrentPositionX, cutCurrentPositionY, cutCurrentPositionZ = MathUtil.vector3Lerp(spec.cutStartPositionX, spec.cutStartPositionY, spec.cutStartPositionZ, spec.cutEndPositionX, spec.cutEndPositionY, spec.cutEndPositionZ, cutLastProgress)
    end
    setWorldTranslation(spec.cutGuideNode, cutCurrentPositionX, cutCurrentPositionY, cutCurrentPositionZ)
    setWorldQuaternion(spec.cutGuideNode, getWorldQuaternion(spec.splitPlaneNode))
end
function HandToolChainsaw:updateSplitPlane()
    local spec = self.spec_chainsaw
    if spec.currentCutState == ChainsawCutState.DELIMBING then
        local x, y, z = localToWorld(self.graphicalNode, 0, -spec.maximumDelimbDiameter * 0.5, 0)
        setWorldTranslation(spec.cameraRotationNode, x, y, z)
        local cameraNode = g_cameraManager:getActiveCamera()
        local upX, upY, upZ = localDirectionToWorld(cameraNode, 0, 1, 0)
        local dirX, dirY, dirZ = localDirectionToWorld(cameraNode, 0, 0, -1)
        setDirection(spec.cameraRotationNode, dirX, dirY, dirZ, upX, upY, upZ)
    else
        local x, y = self:getCarryingPlayer().camera:getRotation()
        setWorldRotation(spec.cameraRotationNode, 0, y, 0)
    end
    rotateAboutLocalAxis(spec.cameraRotationNode, spec.currentCutRoll, 0, 0, 1)
    spec.cutMinimumY = nil
    spec.cutMaximumY = nil
    spec.cutMinimumZ = nil
    spec.cutMaximumZ = nil
    if spec.currentCutState == ChainsawCutState.CUTTING then
        if spec.cuttingTreeNode ~= nil and entityExists(spec.cuttingTreeNode) then
            local x, y, z, cameraNode, upX, upY, upZ, dirX, dirY, dirZ, planeDepth = self:calculateCutPlane()
            spec.cutMinimumY, spec.cutMaximumY, spec.cutMinimumZ, spec.cutMaximumZ = testSplitShape(spec.cuttingTreeNode, x, y, z, cameraNode, upX, upY, upZ, dirX, dirY, dirZ, planeDepth)
        end
    else
        if spec.currentCutState == ChainsawCutState.IDLE then
            if spec.targetedTree == nil or not entityExists(spec.targetedTree.node) then
                return
            end
            setWorldTranslation(spec.cameraRotationNode, spec.targetedTree.x, spec.targetedTree.y, spec.targetedTree.z)
            local x, y, z, cameraNode, upX, upY, upZ, dirX, dirY, dirZ, planeDepth = self:calculateCutPlane()
            spec.cutMinimumY, spec.cutMaximumY, spec.cutMinimumZ, spec.cutMaximumZ = testSplitShape(spec.targetedTree.node, x, y, z, cameraNode, upX, upY, upZ, dirX, dirY, dirZ, planeDepth)
        end
        return
    end
end
function HandToolChainsaw:updateRingSelector(targetedTree, isCutPossible, cutMinimumY, cutMaximumY, cutMinimumZ, cutMaximumZ)
    local spec = self.spec_chainsaw
    if spec.ringNode == nil then
        return
    else
        local ringScale = setVisibility
        local worldTreeCentreX = spec.ringNode
        local worldTreeCentreY = targetedTree ~= nil
        ringScale(worldTreeCentreX, worldTreeCentreY)
        if targetedTree == nil then
            return
        else
            if isCutPossible then
                setShaderParameter(spec.ringNode, "colorScale", HandToolChainsaw.VALID_CUT_COLOR.r, HandToolChainsaw.VALID_CUT_COLOR.g, HandToolChainsaw.VALID_CUT_COLOR.b, 1, false)
            else
                setShaderParameter(spec.ringNode, "colorScale", HandToolChainsaw.INVALID_CUT_COLOR.r, HandToolChainsaw.INVALID_CUT_COLOR.g, HandToolChainsaw.INVALID_CUT_COLOR.b, 1, false)
            end
            if cutMinimumY ~= nil then
                local ringScale = math.max(cutMaximumZ - cutMinimumZ, cutMaximumY - cutMinimumY) + spec.ringScaleOffset
                setScale(spec.ringNode, 1, ringScale, ringScale)
                local worldTreeCentreX, worldTreeCentreY, worldTreeCentreZ = localToWorld(spec.splitPlaneNode, (cutMinimumY + cutMaximumY) * 0.5, 0, (cutMinimumZ + cutMaximumZ) * 0.5)
                local localTreeCentreX, localTreeCentreY, localTreeCentreZ = worldToLocal(getParent(spec.ringNode), worldTreeCentreX, worldTreeCentreY, worldTreeCentreZ)
                setTranslation(spec.ringNode, localTreeCentreX, localTreeCentreY, localTreeCentreZ)
            end
        end
    end
end
function HandToolChainsaw:calculateCutPlane()
    local spec = self.spec_chainsaw
    local x, y, z = getWorldTranslation(spec.splitPlaneNode)
    local downX, downY, downZ = localDirectionToWorld(spec.splitPlaneNode, 0, -1, 0)
    local leftX, leftY, leftZ = localDirectionToWorld(spec.splitPlaneNode, 1, 0, 0)
    return x, y, z, downX, downY, downZ, leftX, leftY, leftZ, spec.maximumCutDiameter, spec.maximumCutDiameter + HandToolChainsaw.SPLIT_PLANE_OFFSET_Z
end