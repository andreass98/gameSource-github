VehicleCharacter = {}
VehicleCharacter.DEFAULT_MAX_UPDATE_DISTANCE = 35
VehicleCharacter.DEFAULT_CLIP_DISTANCE = 75
VehicleCharacter.SPINE_ROTATION = { -1.5707963267948966, -0.2461786909938002, 1.5707963267948966 }
local VehicleCharacter_mt = Class(VehicleCharacter)
function VehicleCharacter.new(vehicle, customMt)
    -- upvalues: (copy) VehicleCharacter_mt
    local self = setmetatable({}, customMt or VehicleCharacter_mt)
    self.vehicle = vehicle
    self.characterNode = nil
    self.allowUpdate = true
    self.ikChainTargets = {}
    self.animationCharsetId = nil
    self.animationPlayer = nil
    self.useAnimation = false
    self.isVisible = false
    return self
end
function VehicleCharacter:load(xmlFile, xmlNode)
    XMLUtil.checkDeprecatedXMLElements(xmlFile, xmlNode .. "#index", xmlNode .. "#node")
    self.characterNode = xmlFile:getValue(xmlNode .. "#node", nil, self.vehicle.components, self.vehicle.i3dMappings)
    if self.characterNode == nil then
        return false
    end
    self.parentComponent = self.vehicle:getParentComponent(self.characterNode)
    self.characterCameraMinDistance = xmlFile:getValue(xmlNode .. "#cameraMinDistance", 1.5)
    self.characterDistanceRefNodeCustom = xmlFile:getValue(xmlNode .. "#distanceRefNode", nil, self.vehicle.components, self.vehicle.i3dMappings)
    self.characterDistanceRefNode = self.characterDistanceRefNodeCustom or self.characterNode
    setVisibility(self.characterNode, false)
    self.useAnimation = xmlFile:getValue(xmlNode .. "#useAnimation", false)
    self.useIdleAnimation = xmlFile:getValue(xmlNode .. "#useIdleAnimation", not self.useAnimation and Platform.gameplay.hasVehicleCharacterIdleAnimations)
    if not self.useAnimation then
        self.ikChainTargets = {}
        IKUtil.loadIKChainTargets(xmlFile, xmlNode, self.vehicle.components, self.ikChainTargets, self.vehicle.i3dMappings)
    end
    self.characterSpineRotationOffset = xmlFile:getValue(xmlNode .. "#spineRotationOffset", nil, true)
    self.characterSpineSpeedDepended = xmlFile:getValue(xmlNode .. "#speedDependedSpine", false)
    self.characterSpineNodeMinRot = xmlFile:getValue(xmlNode .. "#spineNodeMinRot", 10)
    self.characterSpineNodeMaxRot = xmlFile:getValue(xmlNode .. "#spineNodeMaxRot", -10)
    self.characterSpineNodeMinAcc = xmlFile:getValue(xmlNode .. "#spineNodeMinAcc", -1) / 1000000
    self.characterSpineNodeMaxAcc = xmlFile:getValue(xmlNode .. "#spineNodeMaxAcc", 1) / 1000000
    self.characterSpineNodeAccDeadZone = xmlFile:getValue(xmlNode .. "#spineNodeAccDeadZone", 0.2) / 1000000
    self.characterSpineLastRotation = 0
    self:setCharacterVisibility(self.isVisible)
    self.maxUpdateDistance = xmlFile:getValue(xmlNode .. "#maxUpdateDistance", VehicleCharacter.DEFAULT_MAX_UPDATE_DISTANCE)
    setClipDistance(self.characterNode, xmlFile:getValue(xmlNode .. "#clipDistance", VehicleCharacter.DEFAULT_CLIP_DISTANCE))
    return true
end
function VehicleCharacter:getParentComponent()
    return self.parentComponent
end
function VehicleCharacter:loadCharacter(playerStyle, asyncCallbackObject, asyncCallbackFunction, asyncCallbackArguments)
    if playerStyle == nil then
        asyncCallbackFunction(asyncCallbackObject, false, asyncCallbackArguments)
    else
        if self.playerModel ~= nil then
            self.playerModel:delete()
        end
        self.playerModel = HumanModel.new()
        self.playerModel:load(playerStyle.xmlFilename, false, false, self.useAnimation, self.characterLoaded, self, {
            ["asyncCallbackObject"] = asyncCallbackObject,
            ["asyncCallbackFunction"] = asyncCallbackFunction,
            ["asyncCallbackArguments"] = asyncCallbackArguments,
            ["playerStyle"] = playerStyle
        })
    end
end
function VehicleCharacter:characterLoaded(loadingState, arguments)
    if loadingState == HumanModelLoadingState.OK then
        if self.playerModel.rootNode == nil then
            return
        end
        self.isStyleLoaded = false
        local linkNode = Utils.getNoNil(self.characterNode, self.vehicle.rootNode)
        link(linkNode, self.playerModel.rootNode)
        for ikChainId, target in pairs(self.ikChainTargets) do
            IKUtil.setTarget(self.playerModel:getIKChains(), ikChainId, target)
        end
        if self.playerModel.thirdPersonHipsNode ~= nil then
            local x = VehicleCharacter.SPINE_ROTATION[1]
            local y = VehicleCharacter.SPINE_ROTATION[2]
            local z = VehicleCharacter.SPINE_ROTATION[3]
            if self.characterSpineRotationOffset ~= nil then
            end
            setRotation(self.playerModel.thirdPersonHipsNode, x, y, z)
        end
        self.characterDistanceRefNode = self.characterDistanceRefNodeCustom or self.playerModel.thirdPersonHeadNode
        if self.playerModel.skeleton ~= nil and getNumOfChildren(self.playerModel.skeleton) > 0 then
            if self.useAnimation then
                local x = self.playerModel.skeleton
                local y = g_animCache:getNode(AnimationCache.CHARACTER)
                cloneAnimCharacterSet(getChildAt(y, 0), x)
                self.animationCharsetId = getAnimCharacterSet(getChildAt(x, 0))
                local z = createConditionalAnimation()
                if z ~= 0 then
                    self.animationPlayer = z
                end
                if self.animationCharsetId == 0 then
                    self.animationCharsetId = nil
                    Logging.devError("-- [VehicleCharacter:loadCharacter] Could not load animation CharSet from: [%s/%s]", getName(getParent(x)), getName(x))
                    printScenegraph(getParent(x))
                end
            elseif self.useIdleAnimation then
                local x = self.playerModel.skeleton
                local y = g_animCache:getNode(AnimationCache.VEHICLE_CHARACTER)
                cloneAnimCharacterSet(getChildAt(y, 0), x)
                self.animationCharsetId = getAnimCharacterSet(x)
                if self.animationCharsetId == 0 then
                    self.useIdleAnimation = false
                    self.animationCharsetId = nil
                    Logging.devError("-- [VehicleCharacter:loadCharacter] Could not load animation CharSet from: [%s/%s]", getName(getParent(x)), getName(x))
                else
                    self.idleClipIndex = getAnimClipIndex(self.animationCharsetId, "idle1Source")
                    clearAnimTrackClip(self.animationCharsetId, 0)
                    assignAnimTrackClip(self.animationCharsetId, 0, self.idleClipIndex)
                    setAnimTrackLoopState(self.animationCharsetId, 0, true)
                    self.idleAnimationState = false
                end
            end
        end
        local x = arguments.playerStyle
        self.playerModel:loadFromStyleAsync(x, function(_, loadingState, _)
            -- upvalues: (copy) self
            if loadingState == HumanModelLoadingState.OK then
                self.isStyleLoaded = true
                self:setDirty(true)
                self:setCharacterVisibility(self.isVisible)
            end
        end, nil, nil)
    else
        self.playerModel:delete()
        self.playerModel = nil
        Logging.error("Failed to load vehicleCharacter")
    end
    local linkNode = arguments.asyncCallbackObject
    local x = arguments.asyncCallbackFunction
    local y = arguments.asyncCallbackArguments
    if x ~= nil then
        x(linkNode, loadingState, y)
    end
end
function VehicleCharacter:delete()
    self:unloadCharacter()
end
function VehicleCharacter:unloadCharacter()
    if self.playerModel ~= nil then
        self.characterDistanceRefNode = self.characterDistanceRefNodeCustom or self.characterNode
        self.playerModel:delete()
        self.playerModel = nil
        if self.animationPlayer ~= nil then
            delete(self.animationPlayer)
            self.animationPlayer = nil
        end
    end
end
function VehicleCharacter:setDirty(setAllDirty)
    if self.playerModel ~= nil then
        for chainId, target in pairs(self.ikChainTargets) do
            if target.setDirty or setAllDirty then
                IKUtil.setIKChainDirty(self.playerModel:getIKChains(), chainId)
            end
        end
    end
end
function VehicleCharacter:updateIKChains()
    IKUtil.updateIKChains(self.playerModel:getIKChains(), true)
end
function VehicleCharacter:setIKChainPoseByTarget(target, poseId)
    if self.playerModel ~= nil then
        local ikChains = self.playerModel:getIKChains()
        local chain = IKUtil.getIKChainByTarget(ikChains, target)
        if chain ~= nil then
            IKUtil.setIKChainPose(ikChains, chain.id, poseId)
        end
    end
end
function VehicleCharacter:setSpineDirty(acc)
    local rotation = ((math.abs(acc) < self.characterSpineNodeAccDeadZone and 0 or acc) - self.characterSpineNodeMinAcc) / (self.characterSpineNodeMaxAcc - self.characterSpineNodeMinAcc)
    local alpha = math.clamp(rotation, 0, 1)
    local rotation = MathUtil.lerp(self.characterSpineNodeMinRot, self.characterSpineNodeMaxRot, alpha)
    if rotation ~= self.characterSpineLastRotation then
        self.characterSpineLastRotation = self.characterSpineLastRotation * 0.95 + rotation * 0.05
        setRotation(self.player.spineNode, self.characterSpineLastRotation, 0, 0)
        self:setDirty()
    end
end
function VehicleCharacter:updateVisibility()
    if self.isStyleLoaded and (entityExists(self.characterDistanceRefNode) and entityExists(g_cameraManager:getActiveCamera())) then
        local visible = calcDistanceFrom(self.characterDistanceRefNode, g_cameraManager:getActiveCamera()) >= self.characterCameraMinDistance
        self:setCharacterVisibility(visible)
    end
end
function VehicleCharacter:setCharacterVisibility(isVisible)
    if self.characterNode ~= nil then
        setVisibility(self.characterNode, isVisible)
    end
    if self.playerModel ~= nil and self.playerModel.isLoaded then
        self.playerModel:setVisibility(isVisible)
    end
    self.isVisible = isVisible
end
function VehicleCharacter:setAllowCharacterUpdate(state)
    self.allowUpdate = state
end
function VehicleCharacter:getAllowCharacterUpdate()
    return self.allowUpdate
end
function VehicleCharacter:update(_)
    if self.playerModel ~= nil and self.playerModel.isLoaded then
        if Platform.gameplay.allowVehicleCharacterIKDirtyUpdate and (self.vehicle.currentUpdateDistance < self.maxUpdateDistance and self.isVisible) then
            if self:getAllowCharacterUpdate() then
                self:setDirty(false)
            end
            self:updateIKChains()
        end
        if self.useIdleAnimation then
            if self.vehicle.currentUpdateDistance < self.maxUpdateDistance then
                if not self.idleAnimationState then
                    self.idleAnimationState = true
                    enableAnimTrack(self.animationCharsetId, 0)
                    return
                end
            elseif self.idleAnimationState then
                self.idleAnimationState = false
                disableAnimTrack(self.animationCharsetId, 0)
            end
        end
    end
end
function VehicleCharacter:getIKChainTargets()
    return self.ikChainTargets
end
function VehicleCharacter:setIKChainTargets(targets, force)
    if self.ikChainTargets ~= targets or force then
        self.ikChainTargets = targets
        if self.playerModel ~= nil then
            for ikChainId, target in pairs(self.ikChainTargets) do
                IKUtil.setTarget(self.playerModel:getIKChains(), ikChainId, target)
            end
            self:setDirty(true)
        end
    end
end
function VehicleCharacter:getPlayerStyle()
    if self.playerModel == nil then
        return nil
    else
        return self.playerModel.style
    end
end
function VehicleCharacter.registerCharacterXMLPaths(schema, basePath, _)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Character root node")
    schema:register(XMLValueType.FLOAT, basePath .. "#cameraMinDistance", "Min. distance until character is hidden", 1.5)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#distanceRefNode", "Distance reference node", "Character root node")
    schema:register(XMLValueType.BOOL, basePath .. "#useAnimation", "Use animation instead of ik chains", false)
    schema:register(XMLValueType.BOOL, basePath .. "#useIdleAnimation", "Apply character idle animation additionally to ik chain control", "set if #useAnimation not set")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. "#spineRotationOffset", "Spine rotation offset")
    schema:register(XMLValueType.BOOL, basePath .. "#speedDependedSpine", "Speed dependent spine", false)
    schema:register(XMLValueType.ANGLE, basePath .. "#spineNodeMinRot", "Spine node min. rotation", 10)
    schema:register(XMLValueType.ANGLE, basePath .. "#spineNodeMaxRot", "Spine node max. rotation", -10)
    schema:register(XMLValueType.FLOAT, basePath .. "#spineNodeMinAcc", "Spine node min. acceleration", -1)
    schema:register(XMLValueType.FLOAT, basePath .. "#spineNodeMaxAcc", "Spine node max. acceleration", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#spineNodeAccDeadZone", "Spine node acceleration dead zone", 0.2)
    schema:register(XMLValueType.FLOAT, basePath .. "#maxUpdateDistance", "Max. distance to vehicle root to update ik chains of character", VehicleCharacter.DEFAULT_MAX_UPDATE_DISTANCE)
    schema:register(XMLValueType.FLOAT, basePath .. "#clipDistance", "Clip distance of character", VehicleCharacter.DEFAULT_CLIP_DISTANCE)
    IKUtil.registerIKChainTargetsXMLPaths(schema, basePath)
end
local setCharacterVisibilityBackup = nil
function VehicleCharacter.consoleCommandVisibilityToggle()
    -- upvalues: (ref) setCharacterVisibilityBackup
    if setCharacterVisibilityBackup == nil then
        setCharacterVisibilityBackup = VehicleCharacter.setCharacterVisibility
        VehicleCharacter.setCharacterVisibility = Utils.overwrittenFunction(VehicleCharacter.setCharacterVisibility, function(instance, superFunc, _)
            superFunc(instance, false)
        end)
        return "Vehicle characters hidden"
    else
        VehicleCharacter.setCharacterVisibility = setCharacterVisibilityBackup
        return "Vehicle characters unhidden"
    end
end
addConsoleCommand("gsVehicleCharacterVisibilityToggle", "Locally toggles visibility of all vehicle characters/drivers/players", "consoleCommandVisibilityToggle", VehicleCharacter)