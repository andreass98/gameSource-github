HumanGraphicsComponent = {}
local HumanGraphicsComponent_mt = Class(HumanGraphicsComponent)
HumanGraphicsComponent.ROTATION_VELOCITY_DAMPENING = 0.025
function HumanGraphicsComponent.new()
    -- upvalues: (copy) HumanGraphicsComponent_mt
    local self = setmetatable({}, HumanGraphicsComponent_mt)
    self.foliageBendingId = nil
    self.foliageBendingNode = nil
    self.graphicsRootNode = nil
    self.isGraphicsRootNodeVisible = true
    self.rightShoulderCameraNode = nil
    self.style = PlayerStyle.new()
    self.baseStyle = PlayerStyle.new()
    self.model = HumanModel.new()
    self.model:loadEmpty()
    self.nameTagOffsetY = 1.9
    self.facialAnimation = nil
    self.facialAnimationEnabled = false
    self.facialAnimationMinimumDistance = FacialAnimation.MINIMUM_VISIBLE_CAMERA_DISTANCE
    self.facialAnimationMaximumDistance = FacialAnimation.MAXIMUM_VISIBLE_CAMERA_DISTANCE
    self.postAnimationCallbackHandle = nil
    self.sounds = HumanSounds.new()
    self.soundsEnabled = true
    local animation = ConditionalAnimation.new()
    local parameters = {
        ["absSpeed"] = animation:registerParameter("absSpeed", ConditionalAnimation.TYPE.FLOAT),
        ["relativeVelocityX"] = animation:registerParameter("relativeVelocityX", ConditionalAnimation.TYPE.FLOAT),
        ["relativeVelocityY"] = animation:registerParameter("relativeVelocityY", ConditionalAnimation.TYPE.FLOAT),
        ["relativeVelocityZ"] = animation:registerParameter("relativeVelocityZ", ConditionalAnimation.TYPE.FLOAT),
        ["rotationVelocity"] = animation:registerParameter("rotationVelocity", ConditionalAnimation.TYPE.FLOAT),
        ["movementDirX"] = animation:registerParameter("movementDirX", ConditionalAnimation.TYPE.FLOAT),
        ["movementDirZ"] = animation:registerParameter("movementDirZ", ConditionalAnimation.TYPE.FLOAT),
        ["distanceToGround"] = animation:registerParameter("distanceToGround", ConditionalAnimation.TYPE.FLOAT),
        ["isCloseToGround"] = animation:registerParameter("isCloseToGround", ConditionalAnimation.TYPE.BOOL),
        ["isIdling"] = animation:registerParameter("isIdling", ConditionalAnimation.TYPE.BOOL),
        ["isWalking"] = animation:registerParameter("isWalking", ConditionalAnimation.TYPE.BOOL),
        ["isRunning"] = animation:registerParameter("isRunning", ConditionalAnimation.TYPE.BOOL),
        ["isCrouching"] = animation:registerParameter("isCrouching", ConditionalAnimation.TYPE.BOOL),
        ["isGrounded"] = animation:registerParameter("isGrounded", ConditionalAnimation.TYPE.BOOL),
        ["isInWater"] = animation:registerParameter("isInWater", ConditionalAnimation.TYPE.BOOL),
        ["isSwimming"] = animation:registerParameter("isSwimming", ConditionalAnimation.TYPE.BOOL),
        ["isStrafeWalkMode"] = animation:registerParameter("isStrafeWalkMode", ConditionalAnimation.TYPE.BOOL),
        ["isFirstPerson"] = animation:registerParameter("isFirstPerson", ConditionalAnimation.TYPE.BOOL),
        ["isCutting"] = animation:registerParameter("isCutting", ConditionalAnimation.TYPE.BOOL),
        ["isVerticalCut"] = animation:registerParameter("isVerticalCut", ConditionalAnimation.TYPE.BOOL),
        ["isHoldingChainsaw"] = animation:registerParameter("isHoldingChainsaw", ConditionalAnimation.TYPE.BOOL),
        ["isNPC"] = animation:registerParameter("isNPC", ConditionalAnimation.TYPE.BOOL)
    }
    animation:setSpecialParameterIds(parameters.absSpeed, parameters.rotationVelocity)
    self.animation = animation
    self.animationParameters = parameters
    self.defaultState = HumanGraphicsComponentState.new()
    self:defaultAllParameters()
    return self
end
function HumanGraphicsComponent:initialize()
    self.graphicsRootNode = createTransformGroup("player_graphicsRootNode")
    link(getRootNode(), self.graphicsRootNode)
    self.rightShoulderCameraNode = createTransformGroup("player_rightShoulderCameraNode")
    link(self.graphicsRootNode, self.rightShoulderCameraNode)
    setTranslation(self.rightShoulderCameraNode, -0.35, 1.675, -0.35)
    self.foliageBendingNode = createTransformGroup("player_foliageBendingNode")
    link(self.graphicsRootNode, self.foliageBendingNode)
end
function HumanGraphicsComponent:show()
    self:setModelVisibility(true)
end
function HumanGraphicsComponent:hide()
    self:setModelVisibility(false)
end
function HumanGraphicsComponent:delete()
    if self:getHasFacialAnimation() then
        self.facialAnimation:delete()
    end
    self.sounds:delete()
    self.animation:delete()
    self.model:delete()
    if self.graphicsRootNode ~= 0 and self.graphicsRootNode ~= nil then
        delete(self.graphicsRootNode)
        self.graphicsRootNode = nil
    end
    local mission = g_currentMission
    if mission ~= nil and self.foliageBendingId ~= nil then
        mission.foliageBendingSystem:destroyObject(self.foliageBendingId)
        self.foliageBendingId = nil
    end
end
function HumanGraphicsComponent:getModel()
    return self.model
end
function HumanGraphicsComponent:setModel(model)
    if model.rootNode == nil then
        printCallstack()
        Logging.error("New model is missing root node and cannot be used!")
    else
        if self.model ~= nil and self.model ~= model then
            self.model:delete()
        end
        self.model = model
        link(self.graphicsRootNode, model.rootNode)
        self:loadAnimation()
        self:loadSounds()
        self:setModelVisibility(true)
    end
end
function HumanGraphicsComponent:loadAnimation()
    self.animation:unload()
    local model = self.model
    local skeletonNode = model:getSkeletonNode()
    if skeletonNode ~= nil and getNumOfChildren(skeletonNode) > 0 then
        local animNode = g_animCache:getNode(AnimationCache.CHARACTER)
        self:defaultAllParameters()
        self.animation:load(skeletonNode, model.animationFilename, "conditionalAnimation", animNode)
    end
end
function HumanGraphicsComponent:setSoundsEnabled(soundsEnabled)
    self.soundsEnabled = soundsEnabled
end
function HumanGraphicsComponent:loadSounds()
    self.sounds:unload()
    if self.soundsEnabled then
        local model = self.model
        if model.soundFilename ~= nil then
            self.sounds:load(self.graphicsRootNode, model.soundFilename, "humanSounds", model.thirdPersonLeftFootNode, model.thirdPersonRightFootNode)
        end
    end
end
function HumanGraphicsComponent:getIsFacialAnimationEnabled()
    return self.facialAnimationEnabled
end
function HumanGraphicsComponent:setIsFacialAnimationEnabled(facialAnimationEnabled)
    if self.facialAnimationEnabled == facialAnimationEnabled then
        return
    else
        self.facialAnimationEnabled = facialAnimationEnabled
        if self.facialAnimationEnabled or not self:getHasFacialAnimation() then
            if self.facialAnimationEnabled and not self:getHasFacialAnimation() then
                self.facialAnimation = FacialAnimation.new()
                self.postAnimationCallbackHandle = addPostAnimationCallback(HumanGraphicsComponent.onPostAnimationUpdate, self, nil)
            end
        else
            self.facialAnimation:delete()
            self.facialAnimation = nil
            removePostAnimationCallback(self.postAnimationCallbackHandle)
            self.postAnimationCallbackHandle = nil
        end
    end
end
function HumanGraphicsComponent:getHasFacialAnimation()
    return self.facialAnimation ~= nil
end
function HumanGraphicsComponent:getFacialAnimation()
    return self.facialAnimation
end
function HumanGraphicsComponent:getIsInCameraFrustum(camera, aspectRatio)
    local currentModel = self:getModel()
    if currentModel == nil then
        return false
    else
        return currentModel:getIsInCameraFrustum(camera, aspectRatio)
    end
end
function HumanGraphicsComponent:getModelDirection()
    if self.graphicsRootNode == nil then
        return 0, 0, -1
    end
    local directionX, directionY, directionZ = localDirectionToWorld(self.graphicsRootNode, 0, 0, -1)
    return directionX, directionY, directionZ
end
function HumanGraphicsComponent:getModelYaw()
    if self.graphicsRootNode == nil then
        return 0
    end
    local directionX, directionY, directionZ = localDirectionToWorld(self.graphicsRootNode, 0, 0, 1)
    local _, yaw = MathUtil.directionToPitchYaw(directionX, directionY, directionZ)
    return yaw
end
function HumanGraphicsComponent:setModelYaw(yaw)
    yaw = MathUtil.getValidLimit(yaw)
    setWorldRotation(self.graphicsRootNode, 0, yaw, 0)
end
function HumanGraphicsComponent:setModelRotation(rx, ry, rz)
    setWorldRotation(self.graphicsRootNode, rx, ry, rz)
end
function HumanGraphicsComponent:setModelPosition(x, y, z)
    setWorldTranslation(self.graphicsRootNode, x, y, z)
end
function HumanGraphicsComponent:getModelVisibility()
    return self.model:getVisibility()
end
function HumanGraphicsComponent:setModelVisibility(visibility, overrideFoliageBending)
    self.model:setVisibility(visibility)
    self:setGraphicsRootNodeVisibility(self.isGraphicsRootNodeVisible)
    local useFoliageBending = Utils.getNoNil(overrideFoliageBending, visibility)
    if useFoliageBending then
        if self.foliageBendingNode ~= nil and (self.foliageBendingId == nil and (g_currentMission ~= nil and g_currentMission.foliageBendingSystem)) then
            self.foliageBendingId = mission.foliageBendingSystem:createRectangle(-0.5, 0.5, -0.5, 0.5, 0.4, self.foliageBendingNode)
            return
        end
    elseif self.foliageBendingId ~= nil then
        mission.foliageBendingSystem:destroyObject(self.foliageBendingId)
        self.foliageBendingId = nil
    end
end
function HumanGraphicsComponent:setGraphicsRootNodeVisibility(isVisible)
    self.isGraphicsRootNodeVisible = isVisible
    if self.model ~= nil then
        self.model:setParentVisibility(isVisible)
    end
end
function HumanGraphicsComponent:getIsFacialAnimationVisible()
    return self:getHasFacialAnimation() and self.facialAnimation:getIsVisible()
end
function HumanGraphicsComponent:blendFacialAnimation(blendFactor)
    if self:getHasFacialAnimation() then
        local lookAtWeight = self.facialAnimation
        lookAtWeight:setIsVisible(blendFactor > 0)
        if self.model.faceNode ~= nil then
            setVisibility(self.model.faceNode, blendFactor <= 0)
        end
        local lookAtWeight = math.clamp(blendFactor, 0, 1)
        self.facialAnimation:setLookAtWeight(lookAtWeight)
    else
        self.model:showHead()
    end
end
function HumanGraphicsComponent:updateFacialAnimationEmotions()
    if not self:getHasFacialAnimation() then
    end
end
function HumanGraphicsComponent:updateFacialAnimationVisibilityFromCameraDistance(cameraDistance)
    self:blendFacialAnimation((cameraDistance - self.facialAnimationMinimumDistance) / (self.facialAnimationMinimumDistance - self.facialAnimationMaximumDistance))
end
function HumanGraphicsComponent:applyCustomWorkStyle(presetName, isOwner)
    local preset = nil
    if not string.isNilOrWhitespace(presetName) then
        preset = self.style:getPresetByName(presetName)
    end
    if preset == nil then
        self:setStyleAsync(self.baseStyle, nil, nil, nil, false, nil, isOwner)
    else
        local tempStyle = PlayerStyle.new()
        tempStyle:copyConfigurationFrom(self.baseStyle)
        preset:applyToStyle(tempStyle)
        self:setStyleAsync(tempStyle, nil, nil, nil, true, nil, isOwner)
    end
end
function HumanGraphicsComponent:getStyle(currentStyle)
    if currentStyle then
        return self.style
    else
        return self.baseStyle or self.style
    end
end
function HumanGraphicsComponent:setStyle(style, isTempStyle)
    self.style:copyFrom(style)
    if not isTempStyle then
        self.baseStyle:copyFrom(style)
    end
end
function HumanGraphicsComponent:setStyleAsync(style, callback, callbackObject, callbackArgs, isTempStyle, xmlFile, isOwner)
    local function onFinishedFacialAnimationCallback(_, success, args)
        -- upvalues: (copy) self, (copy) callback, (copy) callbackObject, (copy) callbackArgs
        if not success and self.facialAnimation ~= nil then
            self.facialAnimation:delete()
            self.facialAnimation = nil
        end
        local graphicsLoadingState = args.loadingState
        if graphicsLoadingState == HumanModelLoadingState.OK and self.graphicsRootNode ~= nil then
            self:setGraphicsRootNodeVisibility(self.isGraphicsRootNodeVisible)
        end
        if callback ~= nil then
            callback(callbackObject, graphicsLoadingState, args.loadedNewPlayerModel, callbackArgs)
        end
    end
    local function onStyleLoadedCallback(target, loadingState, args)
        -- upvalues: (copy) self, (copy) style, (copy) onFinishedFacialAnimationCallback
        args.loadingState = loadingState
        local isLoadingFacialAnimations = false
        if self:getIsFacialAnimationEnabled() then
            isLoadingFacialAnimations = self.facialAnimation:loadFromStyleAsync(style, self.model, onFinishedFacialAnimationCallback, target, args)
        end
        if not isLoadingFacialAnimations then
            if self.facialAnimation ~= nil then
                self.facialAnimation:delete()
                self.facialAnimation = nil
            end
            onFinishedFacialAnimationCallback(target, true, args)
        end
    end
    if self.graphicsRootNode ~= nil then
        self:setGraphicsRootNodeVisibility(self.isGraphicsRootNodeVisible)
    end
    if self.model.xmlFilename == style.xmlFilename then
        self:setStyle(style, isTempStyle)
        self.model:loadFromStyleAsync(self.style, onStyleLoadedCallback, nil, {
            ["loadedNewPlayerModel"] = false
        })
        return
    else
        self:setStyle(style, isTempStyle)
        if xmlFile == nil then
            self.model:load(style.xmlFilename, true, isOwner, true, function(_, loadingState, _)
                -- upvalues: (copy) style, (copy) self, (copy) onStyleLoadedCallback
                if loadingState == HumanModelLoadingState.OK then
                    self:setModel(self.model)
                    self.model:loadFromStyleAsync(self.style, onStyleLoadedCallback, nil, {
                        ["loadedNewPlayerModel"] = true
                    })
                else
                    Logging.warning("Player model could not be loaded from " .. style.xmlFilename)
                end
            end)
        else
            self.model:loadFromXMLFileAsync(xmlFile, true, isOwner, true, onModelLoadedCallback)
        end
    end
end
function HumanGraphicsComponent:pointRightShoulderCameraNodeAt(node)
    local targetPositionX, targetPositionY, targetPositionZ = getWorldTranslation(node)
    local shoulderCameraPositionX, shoulderCameraPositionY, shoulderCameraPositionZ = getWorldTranslation(self.rightShoulderCameraNode)
    local targetShoulderDirectionX, targetShoulderDirectionY, targetShoulderDirectionZ = MathUtil.vector3Normalize(shoulderCameraPositionX - targetPositionX, shoulderCameraPositionY - targetPositionY, shoulderCameraPositionZ - targetPositionZ)
    setWorldDirection(self.rightShoulderCameraNode, targetShoulderDirectionX, targetShoulderDirectionY, targetShoulderDirectionZ, 0, 1, 0)
end
function HumanGraphicsComponent:update(dt)
    self.animation:update(dt)
    self.sounds:update(dt)
    if self:getHasFacialAnimation() then
        self.facialAnimation:update(dt)
        self:updateFacialAnimationEmotions()
    end
end
function HumanGraphicsComponent:applyState(state)
    local animation = self.animation
    local parameters = self.animationParameters
    animation:setParameter(parameters.absSpeed, state.absSpeed)
    animation:setParameter(parameters.relativeVelocityX, state.relativeVelocityX)
    animation:setParameter(parameters.relativeVelocityY, state.relativeVelocityY)
    animation:setParameter(parameters.relativeVelocityZ, state.relativeVelocityZ)
    animation:setParameter(parameters.rotationVelocity, state.rotationVelocity)
    animation:setParameter(parameters.movementDirX, state.movementDirX)
    animation:setParameter(parameters.movementDirZ, state.movementDirZ)
    animation:setParameter(parameters.distanceToGround, state.distanceToGround)
    animation:setParameter(parameters.isCloseToGround, state.isCloseToGround)
    animation:setParameter(parameters.isIdling, state.isIdling)
    animation:setParameter(parameters.isWalking, state.isWalking)
    animation:setParameter(parameters.isRunning, state.isRunning)
    animation:setParameter(parameters.isCrouching, state.isCrouching)
    animation:setParameter(parameters.isGrounded, state.isGrounded)
    animation:setParameter(parameters.isInWater, state.isInWater)
    animation:setParameter(parameters.isSwimming, state.isSwimming)
    animation:setParameter(parameters.isStrafeWalkMode, state.isStrafeWalkMode)
    animation:setParameter(parameters.isFirstPerson, state.isFirstPerson)
    animation:setParameter(parameters.isCutting, state.isCutting)
    animation:setParameter(parameters.isVerticalCut, state.isVerticalCut)
    animation:setParameter(parameters.isHoldingChainsaw, state.isHoldingChainsaw)
    animation:setParameter(parameters.isNPC, state.isNPC)
    self.sounds:applyState(state)
end
function HumanGraphicsComponent:onPostAnimationUpdate(_)
    if self:getHasFacialAnimation() then
        if self.facialAnimation.headNode ~= nil and self.model.thirdPersonHeadNode ~= nil then
            setTranslation(self.model.thirdPersonHeadNode, getTranslation(self.facialAnimation.headNode))
            setRotation(self.model.thirdPersonHeadNode, getRotation(self.facialAnimation.headNode))
            setTranslation(self.facialAnimation.neckNode, 0, 0, 0)
        end
    else
        return
    end
end
function HumanGraphicsComponent:defaultAllParameters()
    self:applyState(self.defaultState)
end
function HumanGraphicsComponent:debugDraw(x, y, textSize, debugDrawModel)
    if (debugDrawModel or debugDrawModel == nil) and self.model ~= nil then
        self.model:debugDraw(x, y, textSize)
    end
    DebugUtil.drawDebugNode(self.graphicsRootNode, "Graphics", false, 0)
    DebugUtil.drawDebugNode(self.rightShoulderCameraNode, "ShoulderCam", false, 0)
    local directionX = DebugUtil.renderTextLine(x, y, textSize * 1.5, "HumanGraphicsComponent", nil, true)
    local directionX, directionY, directionZ = localDirectionToWorld(self.graphicsRootNode, 0, 0, 1)
    local _, yaw = MathUtil.directionToPitchYaw(directionX, directionY, directionZ)
    y = DebugUtil.renderTextLine(x, directionX, textSize, string.format("Rotation: %.4f", yaw), nil, true)
    return self.style:debugDraw(x, y, textSize)
end
function HumanGraphicsComponent:debugDrawAnimator(x, y, textSize)
    self.animation:debugDraw(x, y, textSize)
end