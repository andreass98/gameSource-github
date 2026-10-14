source("dataS/scripts/handTools/events/HandsPickUpObjectEvent.lua")
source("dataS/scripts/handTools/events/HandsThrowObjectEvent.lua")
source("dataS/scripts/handTools/events/HandsPickUpFailedEvent.lua")
HandToolHands = {}
HandToolHands.TARGET_MASK = CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.TREE + CollisionFlag.VEHICLE
HandToolHands.MAXIMUM_PICKUP_MASS = 0.2
HandToolHands.SUPER_STRENGTH_PICKUP_MASS = 500
HandToolHands.PICKUP_DISTANCE = 2
HandToolHands.MAXIMUM_THROW_TIME = 1200
HandToolHands.MINIMUM_THROW_CHARGE_DISTANCE = 1.5
HandToolHands.KINEMATIC_NODE_DIRECTION_NUM_BITS = 12
HandToolHands.FOOTBALL_DETECTION_RADIUS = 1.5
HandToolHands.FOOTBALL_DRIBBLE_MAX_DISTANCE = 0.75
HandToolHands.FOOTBALL_DRIBBLE_MIN_DISTANCE = 0.35
HandToolHands.FOOTBALL_SHOOT_THRESHOLD = 500
HandToolHands.FOOTBALL_DRIBBLE_VELOCITY = 5
HandToolHands.FOOTBALL_PASS_VELOCITY = 12
HandToolHands.FOOTBALL_SHOT_VELOCITY = 15
function HandToolHands.registerXMLPaths(xmlSchema)
    xmlSchema:setXMLSpecializationType("HandToolHands")
    xmlSchema:setXMLSpecializationType()
end
function HandToolHands.registerFunctions(handToolType)
    SpecializationUtil.registerFunction(handToolType, "updateKinematicNode", HandToolHands.updateKinematicNode)
    SpecializationUtil.registerFunction(handToolType, "getKinematicNode", HandToolHands.getKinematicNode)
    SpecializationUtil.registerFunction(handToolType, "getIsHoldingItem", HandToolHands.getIsHoldingItem)
    SpecializationUtil.registerFunction(handToolType, "getIsThrowingItem", HandToolHands.getIsThrowingItem)
    SpecializationUtil.registerFunction(handToolType, "getIsAwaitingJointCreation", HandToolHands.getIsAwaitingJointCreation)
    SpecializationUtil.registerFunction(handToolType, "getHasJoint", HandToolHands.getHasJoint)
    SpecializationUtil.registerFunction(handToolType, "getHeldItem", HandToolHands.getHeldItem)
    SpecializationUtil.registerFunction(handToolType, "getCanPickUpNode", HandToolHands.getCanPickUpNode)
    SpecializationUtil.registerFunction(handToolType, "orientRotationNodeToItem", HandToolHands.orientRotationNodeToItem)
    SpecializationUtil.registerFunction(handToolType, "createItemJoint", HandToolHands.createItemJoint)
    SpecializationUtil.registerFunction(handToolType, "pickUpTarget", HandToolHands.pickUpTarget)
    SpecializationUtil.registerFunction(handToolType, "pickupFailed", HandToolHands.pickupFailed)
    SpecializationUtil.registerFunction(handToolType, "dropHeldItem", HandToolHands.dropHeldItem)
    SpecializationUtil.registerFunction(handToolType, "throwHeldItemWithForceScalar", HandToolHands.throwHeldItemWithForceScalar)
    SpecializationUtil.registerFunction(handToolType, "throwHeldItemWithForceVector", HandToolHands.throwHeldItemWithForceVector)
    SpecializationUtil.registerFunction(handToolType, "rotateHeldItem", HandToolHands.rotateHeldItem)
    SpecializationUtil.registerFunction(handToolType, "levelHeldItem", HandToolHands.levelHeldItem)
    SpecializationUtil.registerFunction(handToolType, "onHeldItemJointBroken", HandToolHands.onHeldItemJointBroken)
    SpecializationUtil.registerFunction(handToolType, "findFootballCallback", HandToolHands.findFootballCallback)
    SpecializationUtil.registerFunction(handToolType, "shootBall", HandToolHands.shootBall)
    SpecializationUtil.registerFunction(handToolType, "consoleCommandToggleSuperStrength", HandToolHands.consoleCommandToggleSuperStrength)
end
function HandToolHands.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeDropped", HandToolHands.getCanBeDropped)
end
function HandToolHands.registerEventListeners(handToolType)
    SpecializationUtil.registerEventListener(handToolType, "onLoad", HandToolHands)
    SpecializationUtil.registerEventListener(handToolType, "onDelete", HandToolHands)
    SpecializationUtil.registerEventListener(handToolType, "onUpdate", HandToolHands)
    SpecializationUtil.registerEventListener(handToolType, "onDraw", HandToolHands)
    SpecializationUtil.registerEventListener(handToolType, "onWriteUpdateStream", HandToolHands)
    SpecializationUtil.registerEventListener(handToolType, "onReadUpdateStream", HandToolHands)
    SpecializationUtil.registerEventListener(handToolType, "onRegisterActionEvents", HandToolHands)
    SpecializationUtil.registerEventListener(handToolType, "onCarryingPlayerChanged", HandToolHands)
    SpecializationUtil.registerEventListener(handToolType, "onHeldStart", HandToolHands)
    SpecializationUtil.registerEventListener(handToolType, "onHeldEnd", HandToolHands)
    SpecializationUtil.registerEventListener(handToolType, "onDebugDraw", HandToolHands)
end
function HandToolHands.prerequisitesPresent(specializations)
    return true
end
function HandToolHands:onLoad(_, _)
    local spec = self.spec_hands
    spec.hasSuperStrength = false
    spec.currentMaximumMass = HandToolHands.MAXIMUM_PICKUP_MASS
    spec.pickupDistance = HandToolHands.PICKUP_DISTANCE
    spec.currentThrowTime = nil
    spec.pickUpActionEventId = nil
    spec.throwActionEventId = nil
    spec.pitchActionEventId = nil
    spec.yawActionEventId = nil
    spec.heldItemJointId = nil
    spec.heldItemNode = nil
    spec.currentHoldDistance = HandToolHands.PICKUP_DISTANCE
    spec.kinematicNode = nil
    spec.kinematicRotationNode = nil
    spec.lastThrowUpdateIndex = nil
    spec.pickupPhysicsIndex = nil
    spec.dirtyFlag = self:getNextDirtyFlag()
    spec.kinematicLoadingTask = self:createLoadingTask(spec)
    spec.kinematicSharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync("dataS/character/shared/kinematicHelper.i3d", true, false, HandToolHands.onKinematicHelperLoaded, self, nil)
    spec.lastShootTime = g_time
    spec.canShoot = false
    spec.football = nil
    spec.actionPassText = g_i18n:getText("action_passFootball")
    spec.actionShootText = g_i18n:getText("action_shootFootball")
    spec.pickupText = g_i18n:getText("action_pickUpObject")
    spec.throwText = g_i18n:getText("input_THROW_OBJECT")
    if self.isClient then
        spec.crosshair = self:createCrosshairOverlay("gui.crosshairDefault", HandTool.DEFAULT_CROSSHAIR_SIZE_PIXELS * 0.5)
        spec.crosshair:setColor(nil, nil, nil, 0.25)
        spec.pickUpCrosshair = self:createCrosshairOverlay("gui.grab")
        spec.throwCrosshair = self:createCrosshairOverlay("gui.crosshairThrow")
    end
end
function HandToolHands:onKinematicHelperLoaded(kinematicNode, _)
    local spec = self.spec_hands
    self:finishLoadingTask(spec.kinematicLoadingTask)
    spec.kinematicLoadingTask = nil
    if kinematicNode == nil or kinematicNode == 0 then
        Logging.error("Hands could not load kinematic helper i3d!")
    else
        spec.kinematicNode = getChildAt(kinematicNode, 0)
        link(getRootNode(), spec.kinematicNode)
        addToPhysics(spec.kinematicNode)
        spec.kinematicRotationNode = createTransformGroup("kinematicRotationHelper")
        link(spec.kinematicNode, spec.kinematicRotationNode)
        delete(kinematicNode)
    end
end
function HandToolHands:onDelete()
    local spec = self.spec_hands
    self:dropHeldItem(true)
    if spec.kinematicSharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(spec.kinematicSharedLoadRequestId)
        spec.kinematicSharedLoadRequestId = nil
    end
    if spec.kinematicNode ~= nil then
        delete(spec.kinematicNode)
        spec.kinematicNode = nil
    end
    local player = self:getCarryingPlayer()
    if player ~= nil and player.isOwner then
        removeConsoleCommand("gsPlayerSuperStrengthToggle")
    end
    if spec.crosshair ~= nil then
        spec.crosshair:delete()
        spec.crosshair = nil
    end
    if spec.pickUpCrosshair ~= nil then
        spec.pickUpCrosshair:delete()
        spec.pickUpCrosshair = nil
    end
    if spec.throwCrosshair ~= nil then
        spec.throwCrosshair:delete()
        spec.throwCrosshair = nil
    end
end
function HandToolHands:onWriteUpdateStream(streamId, connection, dirtyMask)
    if connection:getIsServer() then
        local kinematicNode = streamWriteBool
        local kinematicNodeRoll = self.spec_hands.dirtyFlag
        if kinematicNode(streamId, (bit32.btest(dirtyMask, kinematicNodeRoll))) then
            local kinematicNode, kinematicRotationNode = self:getKinematicNode()
            local kinematicNodePitch, kinematicNodeYaw, kinematicNodeRoll = getWorldRotation(kinematicRotationNode)
            local kinematicNodePositionX, kinematicNodePositionY, kinematicNodePositionZ = getWorldTranslation(kinematicNode)
            local kinematicNodeDirectionX, _, kinematicNodeDirectionZ = localDirectionToWorld(kinematicNode, 0, 0, 1)
            local paramsXZ, paramsY = MathUtil.vector2Normalize(kinematicNodeDirectionX, kinematicNodeDirectionZ)
            local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
            NetworkUtil.writeCompressedWorldPosition(streamId, kinematicNodePositionX, paramsXZ)
            NetworkUtil.writeCompressedWorldPosition(streamId, kinematicNodePositionY, g_currentMission.vehicleYPosCompressionParams)
            NetworkUtil.writeCompressedWorldPosition(streamId, kinematicNodePositionZ, paramsXZ)
            NetworkUtil.writeCompressedRange(streamId, paramsXZ, -1, 1, HandToolHands.KINEMATIC_NODE_DIRECTION_NUM_BITS)
            NetworkUtil.writeCompressedRange(streamId, paramsY, -1, 1, HandToolHands.KINEMATIC_NODE_DIRECTION_NUM_BITS)
            NetworkUtil.writeCompressedAngle(streamId, kinematicNodePitch)
            NetworkUtil.writeCompressedAngle(streamId, kinematicNodeYaw)
            NetworkUtil.writeCompressedAngle(streamId, kinematicNodeRoll)
        end
    end
end
function HandToolHands:onReadUpdateStream(streamId, _, connection)
    if not connection:getIsServer() and streamReadBool(streamId) then
        local kinematicNode, kinematicRotationNode = self:getKinematicNode()
        local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
        local kinematicNodePositionX = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
        local kinematicNodePositionY = NetworkUtil.readCompressedWorldPosition(streamId, g_currentMission.vehicleYPosCompressionParams)
        local kinematicNodePositionZ = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
        local kinematicNodeDirectionX = NetworkUtil.readCompressedRange(streamId, -1, 1, HandToolHands.KINEMATIC_NODE_DIRECTION_NUM_BITS)
        local kinematicNodeDirectionZ = NetworkUtil.readCompressedRange(streamId, -1, 1, HandToolHands.KINEMATIC_NODE_DIRECTION_NUM_BITS)
        local kinematicNodePitch = NetworkUtil.readCompressedAngle(streamId)
        local kinematicNodeYaw = NetworkUtil.readCompressedAngle(streamId)
        local kinematicNodeRoll = NetworkUtil.readCompressedAngle(streamId)
        setWorldTranslation(kinematicNode, kinematicNodePositionX, kinematicNodePositionY, kinematicNodePositionZ)
        setWorldDirection(kinematicNode, kinematicNodeDirectionX, 0, kinematicNodeDirectionZ, 0, 1, 0)
        setWorldRotation(kinematicRotationNode, kinematicNodePitch, kinematicNodeYaw, kinematicNodeRoll)
        if self:getHasJoint() then
            setJointFrame(self.spec_hands.heldItemJointId, 0, kinematicRotationNode)
        end
    end
end
function HandToolHands:onUpdate(_)
    local carryingPlayer = self:getCarryingPlayer()
    if carryingPlayer == nil then
        return
    elseif self:getIsHeld() then
        local spec = self.spec_hands
        if self:getIsAwaitingJointCreation() and getIsPhysicsUpdateIndexSimulated(spec.pickupPhysicsIndex) then
            self:createItemJoint()
        end
        self:updateKinematicNode()
        if carryingPlayer.isOwner then
            local targetNode = spec.lastShootTime + HandToolHands.FOOTBALL_SHOOT_THRESHOLD < g_time
            spec.canShoot = targetNode
            spec.football = nil
            if self:getIsHoldingItem() and (self.isServer and (spec.heldItemNode ~= nil and not entityExists(spec.heldItemNode))) then
                self:dropHeldItem()
            end
            if self:getIsHoldingItem() then
                if self:getIsThrowingItem() and (spec.lastThrowUpdateIndex ~= nil and spec.lastThrowUpdateIndex ~= g_updateLoopIndex) then
                    self:throwHeldItemWithForceScalar((math.clamp(spec.currentThrowTime / HandToolHands.MAXIMUM_THROW_TIME, 0, 1)))
                end
            else
                local targetNode = carryingPlayer.targeter:getClosestTargetedNodeFromType(HandToolHands)
                local canPickUpTarget = self:getCanPickUpNode(targetNode)
                if not canPickUpTarget then
                    local object = g_currentMission:getNodeObject(targetNode)
                    if object ~= nil and object:isa(Football) then
                        spec.football = object
                    end
                    if spec.football == nil then
                        local x, y, z = getWorldTranslation(carryingPlayer.graphicsComponent.graphicsRootNode)
                        overlapSphere(x, y, z, HandToolHands.FOOTBALL_DETECTION_RADIUS, "findFootballCallback", self, CollisionFlag.DYNAMIC_OBJECT, true, false, false)
                    end
                end
                local mission = false
                if spec.football ~= nil then
                    mission = spec.canShoot
                end
                g_inputBinding:setActionEventActive(spec.pickUpActionEventId, canPickUpTarget or mission)
                g_inputBinding:setActionEventActive(spec.throwActionEventId, spec.heldItemNode or mission)
                if mission then
                    g_inputBinding:setActionEventText(spec.pickUpActionEventId, spec.actionPassText)
                    g_inputBinding:setActionEventText(spec.throwActionEventId, spec.actionShootText)
                else
                    g_inputBinding:setActionEventText(spec.pickUpActionEventId, spec.pickupText)
                    g_inputBinding:setActionEventText(spec.throwActionEventId, spec.throwText)
                end
            end
            if spec.football ~= nil and spec.canShoot then
                local canPickUpTarget, mission, object = getWorldTranslation(carryingPlayer.graphicsComponent.graphicsRootNode)
                local x, y, z = getWorldTranslation(spec.football.nodeId)
                local distance = MathUtil.vector3Length(canPickUpTarget - x, mission - y, object - z)
                if HandToolHands.FOOTBALL_DRIBBLE_MIN_DISTANCE < distance and distance < HandToolHands.FOOTBALL_DRIBBLE_MAX_DISTANCE then
                    local camera = g_cameraManager:getActiveCamera()
                    local dirX, _, dirZ = localDirectionToWorld(camera, 0, 0, -1)
                    local dirX, _, dirZ = MathUtil.vector3Normalize(dirX, 0, dirZ)
                    self:shootBall(spec.football, dirX, dirZ, 0, HandToolHands.FOOTBALL_DRIBBLE_VELOCITY, Football.TYPE_DRIBBLE)
                end
            end
        end
    else
        return
    end
end
function HandToolHands:onDraw()
    local carryingPlayer = self:getCarryingPlayer()
    if carryingPlayer ~= nil and (carryingPlayer.isOwner and carryingPlayer.camera.isFirstPerson) then
        local target = self:getCarryingPlayer().targeter.closestTargetsByKey[HandToolHands]
        if self:getIsThrowingItem() then
            local throwForceScalar = math.clamp(self.spec_hands.currentThrowTime / HandToolHands.MAXIMUM_THROW_TIME, 0, 1)
            spec.throwCrosshair:setScale(throwForceScalar, throwForceScalar)
            spec.throwCrosshair:render()
            return
        end
        if spec.heldItemNode ~= nil or self:getCanPickUpNode(target and target.node or nil) then
            spec.pickUpCrosshair:render()
            return
        end
        spec.crosshair:render()
    end
end
function HandToolHands:onRegisterActionEvents()
    if self:getIsActiveForInput(true) then
        local spec = self.spec_hands
        local _, actionEventId = self:addActionEvent(InputAction.ACTIVATE_HANDTOOL, self, HandToolHands.onPickUpAction, true, false, false, false, nil)
        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
        g_inputBinding:setActionEventText(actionEventId, spec.pickupText)
        spec.pickUpActionEventId = actionEventId
        local _, actionEventId = self:addActionEvent(InputAction.ACTIVATE_HANDTOOL_SECONDARY, self, HandToolHands.onThrowAction, false, true, true, false, nil)
        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
        g_inputBinding:setActionEventText(actionEventId, spec.throwText)
        spec.throwActionEventId = actionEventId
        local _, actionEventId = self:addActionEvent(InputAction.ROTATE_OBJECT_UP_DOWN, self, HandToolHands.onPitchAction, false, false, true, false, nil)
        g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_rotateObjectVertically"))
        spec.pitchActionEventId = actionEventId
        local _, actionEventId = self:addActionEvent(InputAction.ROTATE_OBJECT_LEFT_RIGHT, self, HandToolHands.onYawAction, false, false, true, false, nil)
        g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_rotateObjectHorizontally"))
        spec.yawActionEventId = actionEventId
        local _, actionEventId = self:addActionEvent(InputAction.HANDS_LEVEL_ITEM, self, HandToolHands.onLevelAction, true, false, false, false, nil)
        spec.levelActionEventId = actionEventId
    end
end
function HandToolHands:onHeldStart()
    local carryingPlayer = self:getCarryingPlayer()
    if carryingPlayer ~= nil and carryingPlayer.isOwner then
        self:getCarryingPlayer().targeter:addTargetType(HandToolHands, HandToolHands.TARGET_MASK, 0.5, self.spec_hands.pickupDistance)
    end
end
function HandToolHands:onHeldEnd()
    local carryingPlayer = self:getCarryingPlayer()
    if carryingPlayer ~= nil and carryingPlayer.isOwner then
        carryingPlayer.targeter:removeTargetType(HandToolHands)
        self:dropHeldItem()
    end
end
function HandToolHands:onCarryingPlayerChanged(player, lastPlayer)
    if player == nil or not player.isOwner then
        if lastPlayer ~= nil and lastPlayer.isOwner then
            removeConsoleCommand("gsPlayerSuperStrengthToggle")
        end
    else
        addConsoleCommand("gsPlayerSuperStrengthToggle", "Toggles the super strength mode for the player", "consoleCommandToggleSuperStrength", self)
    end
end
function HandToolHands:getCanBeDropped(superFunc)
    return false
end
function HandToolHands:updateKinematicNode()
    local spec = self.spec_hands
    if spec.kinematicNode == nil then
        return
    elseif self:getIsHeld() then
        if self:getCarryingPlayer().isOwner then
            local x, y, z, dx, dy, dz = self:getCarryingPlayer().targeter:getLastLookRay()
            if x ~= nil then
                self:raiseDirtyFlags(spec.dirtyFlag)
                setWorldTranslation(spec.kinematicNode, x + dx * spec.currentHoldDistance, y + dy * spec.currentHoldDistance, z + dz * spec.currentHoldDistance)
                local dx, dz = MathUtil.vector2Normalize(dx, dz)
                setWorldDirection(spec.kinematicNode, dx, 0, dz, 0, 1, 0)
            end
        else
            return
        end
    else
        return
    end
end
function HandToolHands:getKinematicNode()
    return self.spec_hands.kinematicNode, self.spec_hands.kinematicRotationNode
end
function HandToolHands:getIsHoldingItem()
    return self.spec_hands.heldItemNode ~= nil
end
function HandToolHands:getIsThrowingItem()
    return self.spec_hands.currentThrowTime ~= nil
end
function HandToolHands:getIsAwaitingJointCreation()
    return self.spec_hands.pickupPhysicsIndex ~= nil
end
function HandToolHands:getHasJoint()
    return self.spec_hands.heldItemJointId ~= nil
end
function HandToolHands:getHeldItem()
    return self.spec_hands.heldItemNode
end
function HandToolHands:getCanPickUpNode(node)
    if node == nil or (node == 0 or not entityExists(node)) then
        return false
    end
    if self.isServer and getRigidBodyType(node) ~= RigidBodyType.DYNAMIC then
        return false
    end
    if self:getIsHoldingItem() then
        return false
    end
    local spec = self.spec_hands
    local mass = HandToolHands.calculateItemMass(node)
    if self.isServer and (mass == nil or spec.currentMaximumMass < mass) then
        return false
    end
    local object = g_currentMission:getNodeObject(node)
    if object ~= nil then
        if object.dynamicMountObject ~= nil or object.tensionMountObject ~= nil then
            return false
        end
        if not spec.hasSuperStrength and (object.getCanBePickedUp ~= nil and not object:getCanBePickedUp(self:getCarryingPlayer())) then
            return false
        end
    end
    return true
end
function HandToolHands:onPickUpAction(_, _)
    local player = self:getCarryingPlayer()
    if player.isOwner then
        local spec = self.spec_hands
        if spec.football == nil then
            if self:getIsHoldingItem() then
                self:dropHeldItem()
            else
                self:pickUpTarget(player.targeter.closestTargetsByKey[HandToolHands])
            end
        else
            local camera = g_cameraManager:getActiveCamera()
            local dirX, _, dirZ = localDirectionToWorld(camera, 0, 0, -1)
            local dirX, _, dirZ = MathUtil.vector3Normalize(dirX, 0, dirZ)
            self:shootBall(spec.football, dirX, dirZ, 0, HandToolHands.FOOTBALL_PASS_VELOCITY, Football.TYPE_PASS)
            return
        end
    else
        return
    end
end
function HandToolHands:onThrowAction(_, _)
    if self:getCarryingPlayer().isOwner then
        local spec = self.spec_hands
        if spec.football ~= nil then
            local camera = g_cameraManager:getActiveCamera()
            local dirX, _, dirZ = localDirectionToWorld(camera, 0, 0, -1)
            local dirX, _, dirZ = MathUtil.vector3Normalize(dirX, 0, dirZ)
            self:shootBall(spec.football, dirX, dirZ, 30, HandToolHands.FOOTBALL_SHOT_VELOCITY, Football.TYPE_SHOT)
        end
        if self:getIsHoldingItem() then
            spec.lastThrowUpdateIndex = g_updateLoopIndex
            if spec.currentThrowTime == nil then
                spec.currentThrowTime = 0
            else
                spec.currentThrowTime = spec.currentThrowTime + g_currentDt
            end
        else
            return
        end
    else
        return
    end
end
function HandToolHands:onPitchAction(_, inputDelta)
    local kinematicNode, rotationNode = self:getKinematicNode()
    local directionX, directionY, directionZ = localDirectionToLocal(kinematicNode, rotationNode, 1, 0, 0)
    self:rotateHeldItem(inputDelta, directionX, directionY, directionZ)
end
function HandToolHands:onYawAction(_, inputDelta)
    local kinematicNode, rotationNode = self:getKinematicNode()
    local directionX, directionY, directionZ = localDirectionToLocal(kinematicNode, rotationNode, 0, 1, 0)
    self:rotateHeldItem(inputDelta, directionX, directionY, directionZ)
end
function HandToolHands:onLevelAction(_, _)
    self:levelHeldItem()
end
function HandToolHands:rotateHeldItem(inputDelta, directionX, directionY, directionZ)
    local spec = self.spec_hands
    local _, rotationNode = self:getKinematicNode()
    rotateAboutLocalAxis(rotationNode, 1.5707963267948966 * (g_physicsDt * 0.001) * inputDelta, directionX, directionY, directionZ)
    if self.isServer and spec.heldItemJointId ~= nil then
        setJointFrame(spec.heldItemJointId, 0, rotationNode)
    end
end
function HandToolHands:levelHeldItem()
    if self:getIsHoldingItem() then
        local spec = self.spec_hands
        local kinematicNode, rotationNode = self:getKinematicNode()
        local itemDirectionX, _, itemDirectionZ = localDirectionToLocal(spec.heldItemNode, kinematicNode, 0, 0, 1)
        local preservedYaw = MathUtil.getYRotationFromDirection(itemDirectionX, itemDirectionZ)
        setRotation(rotationNode, 0, preservedYaw, 0)
        if self.isServer then
            setJointFrame(spec.heldItemJointId, 0, rotationNode)
        end
    end
end
function HandToolHands:dropHeldItem(noEventSend)
    if self:getIsHoldingItem() then
        HandsThrowObjectEvent.sendEvent(self, 0, 0, 0, 0, noEventSend)
        self:onHeldItemJointBroken(nil, nil, true)
    end
end
function HandToolHands:throwHeldItemWithForceScalar(throwForceScalar, noEventSend)
    if self:getIsHoldingItem() then
        local player = self:getCarryingPlayer()
        if player == nil or player.targeter == nil then
            Logging.error("HandToolHands:throwHeldItemWithForceScalar can only be used on the owning player, as it uses their camera direction!")
        else
            local _, _, _, cameraDirectionX, cameraDirectionY, cameraDirectionZ = player.targeter:getLastLookRay()
            self:throwHeldItemWithForceVector(cameraDirectionX, cameraDirectionY, cameraDirectionZ, throwForceScalar, noEventSend)
        end
    else
        return
    end
end
function HandToolHands:throwHeldItemWithForceVector(dirX, dirY, dirZ, throwForceScalar, noEventSend)
    if self:getIsHoldingItem() then
        HandsThrowObjectEvent.sendEvent(self, dirX, dirY, dirZ, throwForceScalar, noEventSend)
        local spec = self.spec_hands
        local heldItemNode = self:getHeldItem()
        spec.lastThrowUpdateIndex = nil
        spec.currentThrowTime = nil
        local player = self:getCarryingPlayer()
        local playerPositionX, playerPositionY, playerPositionZ = player:getPosition()
        local mission = g_currentMission
        local object = mission:getNodeObject(heldItemNode)
        if object ~= nil then
            object.thrownFromPosition = { playerPositionX, playerPositionY, playerPositionZ }
        end
        if self.isServer then
            self:dropHeldItem()
            local mass = HandToolHands.calculateItemMass(heldItemNode)
            if mass ~= nil then
                setLinearVelocity(heldItemNode, dirX * (8 * (1.1 - math.min(mass / spec.currentMaximumMass, 1)) * throwForceScalar), dirY * throwForce, dirZ * throwForce)
                if object ~= nil and object:isa(DogBall) then
                    local dogHouse = mission:getDoghouse(player.farmId)
                    if dogHouse then
                        dogHouse = dogHouse:getDog()
                    end
                    local dogDistance = nil
                    if dogHouse ~= nil then
                        dogDistance = getCompanionClosestDistance(dogHouse.dogInstance, playerPositionX, playerPositionY, playerPositionZ)
                    end
                    if dogDistance ~= nil and dogDistance < Dog.FETCH_RANGE then
                        dogHouse:fetchItem(player, object)
                    end
                end
            end
        else
            return
        end
    else
        return
    end
end
function HandToolHands:pickUpTarget(target, noEventSend)
    if target == nil or not self:getCanPickUpNode(target.node) then
        return false
    end
    HandsPickUpObjectEvent.sendEvent(self, target, noEventSend)
    local heldObject = g_currentMission:getNodeObject(target.node)
    local rootHasRigidBody = false
    if heldObject ~= nil then
        rootHasRigidBody = false
        if heldObject.rootNode ~= nil then
            rootHasRigidBody = getRigidBodyType(heldObject.rootNode) ~= RigidBodyType.NONE
        end
    end
    local heldItemNode = rootHasRigidBody and heldObject.rootNode or target.node
    local spec = self.spec_hands
    spec.heldItemNode = heldItemNode
    local player = self:getCarryingPlayer()
    if player ~= nil and player.capsuleController ~= nil then
        local cctIndex = player.capsuleController.capsuleId
        if cctIndex ~= nil then
            setCCTPairCollision(cctIndex, spec.heldItemNode, false)
        end
    end
    spec.currentHoldDistance = target.distance
    self:updateKinematicNode()
    g_inputBinding:setActionEventActive(spec.throwActionEventId, true)
    g_inputBinding:setActionEventActive(spec.pitchActionEventId, true)
    g_inputBinding:setActionEventActive(spec.yawActionEventId, true)
    g_inputBinding:setActionEventActive(spec.pickUpActionEventId, true)
    g_inputBinding:setActionEventText(spec.pickUpActionEventId, g_i18n:getText("action_dropObject"))
    if heldObject ~= nil and (heldObject.isPallet or heldObject:isa(Bale) and not heldObject.isRoundbale) then
        g_inputBinding:setActionEventActive(spec.levelActionEventId, true)
        local cctIndex = "object"
        if heldObject.isPallet then
            cctIndex = g_i18n:getText("typeDesc_pallet")
        elseif heldObject:isa(Bale) then
            cctIndex = g_i18n:getText("fillType_squareBale")
        end
        g_inputBinding:setActionEventText(spec.levelActionEventId, string.namedFormat(g_i18n:getText("action_levelObject"), "objectName", cctIndex))
    end
    if self.isServer then
        spec.pickupPhysicsIndex = getPhysicsUpdateIndex()
    else
        self:orientRotationNodeToItem(heldItemNode)
    end
    return true
end
function HandToolHands:pickupFailed()
    Logging.devInfo("HandToolHands.pickupFailed")
    local spec = self.spec_hands
    local carryingPlayer = self:getCarryingPlayer()
    if carryingPlayer ~= nil and carryingPlayer.isOwner then
        g_inputBinding:setActionEventActive(spec.throwActionEventId, false)
        g_inputBinding:setActionEventActive(spec.pitchActionEventId, false)
        g_inputBinding:setActionEventActive(spec.yawActionEventId, false)
        g_inputBinding:setActionEventActive(spec.levelActionEventId, false)
        g_inputBinding:setActionEventActive(spec.pickUpActionEventId, false)
        g_inputBinding:setActionEventText(spec.pickUpActionEventId, g_i18n:getText("action_pickUpObject"))
    end
    if spec.heldItemNode ~= nil and (entityExists(spec.heldItemNode) and self:getIsHoldingItem()) then
        local player = self:getCarryingPlayer()
        if player ~= nil and player.capsuleController ~= nil then
            local cctIndex = player.capsuleController.capsuleId
            if cctIndex ~= nil then
                setCCTPairCollision(cctIndex, spec.heldItemNode, true)
            end
        end
    end
    spec.heldItemNode = nil
end
function HandToolHands:orientRotationNodeToItem(targetItemNode)
    local targetCentreX, targetCentreY, targetCentreZ = getCenterOfMass(targetItemNode)
    local targetWorldX, targetWorldY, targetWorldZ = localToWorld(targetItemNode, targetCentreX, targetCentreY, targetCentreZ)
    local _, kinematicRotationNode = self:getKinematicNode()
    setWorldTranslation(kinematicRotationNode, targetWorldX, targetWorldY, targetWorldZ)
    setWorldRotation(kinematicRotationNode, getWorldRotation(targetItemNode))
end
function HandToolHands:createItemJoint()
    local spec = self.spec_hands
    spec.pickupPhysicsIndex = nil
    if self.isServer then
        if self:getIsHoldingItem() then
            if entityExists(spec.heldItemNode) then
                if getRigidBodyType(spec.heldItemNode) == RigidBodyType.DYNAMIC then
                    local joint = JointConstructor.new()
                    joint:setActors(spec.kinematicNode, spec.heldItemNode)
                    local targetCentreX, targetCentreY, targetCentreZ = getCenterOfMass(spec.heldItemNode)
                    local targetWorldX, targetWorldY, targetWorldZ = localToWorld(spec.heldItemNode, targetCentreX, targetCentreY, targetCentreZ)
                    joint:setJointWorldPositions(targetWorldX, targetWorldY, targetWorldZ, targetWorldX, targetWorldY, targetWorldZ)
                    joint:setTranslationLimit(0, true, 0, 0)
                    joint:setTranslationLimit(1, true, 0, 0)
                    joint:setTranslationLimit(2, true, 0, 0)
                    joint:setRotationLimit(0, 0, 0)
                    joint:setRotationLimit(1, 0, 0)
                    joint:setRotationLimit(2, 0, 0)
                    local targetLeftX, targetLeftY, targetLeftZ = localDirectionToWorld(spec.heldItemNode, 1, 0, 0)
                    joint:setJointWorldAxes(targetLeftX, targetLeftY, targetLeftZ, targetLeftX, targetLeftY, targetLeftZ)
                    local targetUpX, targetUpY, targetUpZ = localDirectionToWorld(spec.heldItemNode, 0, 1, 0)
                    joint:setJointWorldNormals(targetUpX, targetUpY, targetUpZ, targetUpX, targetUpY, targetUpZ)
                    joint:setEnableCollision(false)
                    self:orientRotationNodeToItem(spec.heldItemNode)
                    local mass = HandToolHands.calculateItemMass(spec.heldItemNode)
                    local rotationLimitSpring = {}
                    local rotationLimitDamper = {}
                    rotationLimitSpring[1] = mass * 60
                    local forceLimit = mass * rotationLimitSpring[1]
                    rotationLimitDamper[1] = 2 * math.sqrt(forceLimit)
                    rotationLimitSpring[2] = mass * 60
                    local forceLimit = mass * rotationLimitSpring[2]
                    rotationLimitDamper[2] = 2 * math.sqrt(forceLimit)
                    rotationLimitSpring[3] = mass * 60
                    local forceLimit = mass * rotationLimitSpring[3]
                    rotationLimitDamper[3] = 2 * math.sqrt(forceLimit)
                    joint:setRotationLimitSpring(rotationLimitSpring[1], rotationLimitDamper[1], rotationLimitSpring[2], rotationLimitDamper[2], rotationLimitSpring[3], rotationLimitDamper[3])
                    local translationLimitSpring = {}
                    local translationLimitDamper = {}
                    translationLimitSpring[1] = mass * 60
                    translationLimitDamper[1] = 2 * math.sqrt(mass * translationLimitSpring[1])
                    translationLimitSpring[2] = mass * 60
                    translationLimitDamper[2] = 2 * math.sqrt(mass * translationLimitSpring[2])
                    translationLimitSpring[3] = mass * 60
                    translationLimitDamper[3] = 2 * math.sqrt(mass * translationLimitSpring[3])
                    joint:setTranslationLimitSpring(translationLimitSpring[1], translationLimitDamper[1], translationLimitSpring[2], translationLimitDamper[2], translationLimitSpring[3], translationLimitDamper[3])
                    if not spec.hasSuperStrength then
                        local forceLimit = 4 * mass * 40
                        joint:setBreakable(forceLimit, forceLimit)
                    end
                    spec.heldItemJointId = joint:finalize()
                    addJointBreakReport(spec.heldItemJointId, "onHeldItemJointBroken", self)
                else
                    Logging.devWarning("HandToolHands:createItemJoint - held item node is not a dynamic rigid body, aborting pickup")
                    self:dropHeldItem()
                end
            else
                self:dropHeldItem()
                return
            end
        else
            Logging.error("Cannot create joint for held item when no item is being held!")
            return
        end
    else
        return
    end
end
function HandToolHands:onHeldItemJointBroken(_, _, noEventSend)
    local spec = self.spec_hands
    local carryingPlayer = self:getCarryingPlayer()
    if carryingPlayer ~= nil and carryingPlayer.isOwner then
        g_inputBinding:setActionEventActive(spec.throwActionEventId, false)
        g_inputBinding:setActionEventActive(spec.pitchActionEventId, false)
        g_inputBinding:setActionEventActive(spec.yawActionEventId, false)
        g_inputBinding:setActionEventActive(spec.levelActionEventId, false)
        g_inputBinding:setActionEventActive(spec.pickUpActionEventId, false)
        g_inputBinding:setActionEventText(spec.pickUpActionEventId, g_i18n:getText("action_pickUpObject"))
    end
    if entityExists(spec.heldItemNode) and self:getIsHoldingItem() then
        local player = self:getCarryingPlayer()
        if player ~= nil and player.capsuleController ~= nil then
            local cctIndex = player.capsuleController.capsuleId
            if cctIndex ~= nil then
                setCCTPairCollision(cctIndex, spec.heldItemNode, true)
            end
        end
    end
    local player = entityExists(spec.heldItemNode)
    spec.heldItemNode = nil
    if self.isServer then
        HandsThrowObjectEvent.sendEvent(self, 0, 0, 0, 0, noEventSend)
        if self:getHasJoint() then
            if player then
                removeJoint(spec.heldItemJointId)
            end
            spec.heldItemJointId = nil
        elseif self:getIsAwaitingJointCreation() then
            spec.pickupPhysicsIndex = nil
        end
    else
        return
    end
end
function HandToolHands:findFootballCallback(transformId)
    if transformId ~= 0 and getHasClassId(transformId, ClassIds.SHAPE) then
        local object = g_currentMission:getNodeObject(transformId)
        if object ~= nil and object:isa(Football) then
            self.spec_hands.football = object
            return false
        end
    end
    return true
end
function HandToolHands:shootBall(football, dirX, dirZ, angleDeg, velocity, shotType)
    local spec = self.spec_hands
    spec.lastShootTime = g_time
    spec.canShoot = false
    football:shoot(dirX, dirZ, angleDeg, velocity, shotType)
end
function HandToolHands.calculateItemMass(itemNode)
    if itemNode == nil or not entityExists(itemNode) then
        return nil
    end
    local object = g_currentMission:getNodeObject(itemNode)
    local mass = nil
    if object ~= nil and object.getTotalMass ~= nil then
        mass = object:getTotalMass()
    end
    return mass or getMass(itemNode)
end
function HandToolHands:onDebugDraw()
    local kinematicNode, rotationNode = self:getKinematicNode()
    if kinematicNode ~= nil then
        DebugUtil.drawDebugNode(kinematicNode, "kinematic")
        DebugUtil.drawDebugNode(rotationNode, "rotation")
    end
    if self:getIsHoldingItem() then
        local heldItemNode = self:getHeldItem()
        DebugUtil.drawDebugNode(heldItemNode, "heldItem")
        local heldItemPositionX, heldItemPositionY, heldItemPositionZ = getWorldTranslation(heldItemNode)
        local kinematicPositionX, kinematicPositionY, kinematicPositionZ = getWorldTranslation(kinematicNode)
        local distance = MathUtil.vector3Length(heldItemPositionX - kinematicPositionX, heldItemPositionY - kinematicPositionY, heldItemPositionZ - kinematicPositionZ)
        DebugLine.renderBetweenNodes(kinematicNode, heldItemNode, Color.PRESETS.WHITE, true, string.format("%.3fm", distance), 0.03, Color.PRESETS.GREEN, Color.PRESETS.RED)
    end
end
function HandToolHands:consoleCommandToggleSuperStrength()
    local spec = self.spec_hands
    spec.hasSuperStrength = not spec.hasSuperStrength
    local text = "Disabled super strength"
    if spec.hasSuperStrength then
        spec.currentMaximumMass = HandToolHands.SUPER_STRENGTH_PICKUP_MASS
        spec.pickupDistance = 10
        text = "Enabled super strength"
    else
        spec.currentMaximumMass = HandToolHands.MAXIMUM_PICKUP_MASS
        spec.pickupDistance = HandToolHands.PICKUP_DISTANCE
    end
    local carryingPlayer = self:getCarryingPlayer()
    if carryingPlayer == nil or not carryingPlayer.isOwner then
        return text
    end
    carryingPlayer.targeter:removeTargetType(HandToolHands)
    carryingPlayer.targeter:addTargetType(HandToolHands, HandToolHands.TARGET_MASK, 0.5, spec.pickupDistance)
    return text
end