HumanSounds = {}
local HumanSounds_mt = Class(HumanSounds)
g_xmlManager:addCreateSchemaFunction(function()
    HumanSounds.xmlSchema = XMLSchema.new("HumanSounds")
end)
g_xmlManager:addInitSchemaFunction(function()
    HumanSounds.registerXMLPaths(HumanSounds.xmlSchema, "humanSounds")
end)
function HumanSounds.registerXMLPaths(_, key)
    local xmlSchema = HumanSounds.xmlSchema
    SoundManager.registerSampleXMLPaths(xmlSchema, key .. ".water", "swim")
    SoundManager.registerSampleXMLPaths(xmlSchema, key .. ".water", "swimFast")
    SoundManager.registerSampleXMLPaths(xmlSchema, key .. ".water", "swimIdle")
    SoundManager.registerSampleXMLPaths(xmlSchema, key .. ".water", "plunge")
    SoundManager.registerSampleXMLPaths(xmlSchema, key .. ".jump", "takeoff")
    SoundManager.registerSampleXMLPaths(xmlSchema, key .. ".jump", "landing")
    xmlSchema:register(XMLValueType.FLOAT, key .. ".footsteps.left#nodeOffset", "The offset of the foot node to the ground while standing still", 0.035, false)
    xmlSchema:register(XMLValueType.FLOAT, key .. ".footsteps.left#liftedDistanceThreshold", "The offset of the foot node to the ground while standing still", 0.1, false)
    xmlSchema:register(XMLValueType.FLOAT, key .. ".footsteps.left#playDistance", "The offset of the foot node to the ground while standing still", 0.02, false)
    xmlSchema:register(XMLValueType.FLOAT, key .. ".footsteps.right#nodeOffset", "The offset of the foot node to the ground while standing still", 0.035, false)
    xmlSchema:register(XMLValueType.FLOAT, key .. ".footsteps.right#liftedDistanceThreshold", "The offset of the foot node to the ground while standing still", 0.1, false)
    xmlSchema:register(XMLValueType.FLOAT, key .. ".footsteps.right#playDistance", "The offset of the foot node to the ground while standing still", 0.02, false)
end
function HumanSounds.new(baseDirectory, customMt)
    -- upvalues: (copy) HumanSounds_mt
    local self = setmetatable({}, customMt or HumanSounds_mt)
    self.isLoaded = false
    self.baseDirectory = baseDirectory
    self.raycastMask = bit32.bor(CollisionFlag.STATIC_OBJECT, CollisionFlag.WATER, CollisionFlag.TERRAIN, CollisionFlag.TERRAIN_DELTA, CollisionFlag.ROAD, CollisionFlag.BUILDING, CollisionFlag.VEHICLE)
    return self
end
function HumanSounds:load(rootNode, xmlFilename, xmlKey, leftFootNode, rightFootNode)
    local xmlFile = XMLFile.load("HumandSounds", xmlFilename, HumanSounds.xmlSchema)
    if xmlFile == nil then
        return false
    end
    self.rootNode = rootNode
    self.left = {}
    self.left.node = leftFootNode
    self.left.soundNode = createTransformGroup("leftFootSoundNode")
    self.left.isDirty = false
    self.left.nodeOffset = xmlFile:getValue(xmlKey .. ".footsteps.left#nodeOffset", 0.035)
    self.left.liftedDistanceThreshold = xmlFile:getValue(xmlKey .. ".footsteps.left#liftedDistanceThreshold", 0.1)
    self.left.playDistance = xmlFile:getValue(xmlKey .. ".footsteps.left#playDistance", 0.02)
    self.left.surfaceIdToSound = {}
    self.left.surfaceNameToSound = {}
    link(rootNode, self.left.soundNode)
    self.right = {}
    self.right.node = rightFootNode
    self.right.soundNode = createTransformGroup("rightFootSoundNode")
    self.right.isDirty = false
    self.right.nodeOffset = xmlFile:getValue(xmlKey .. ".footsteps.right#nodeOffset", 0.035)
    self.right.liftedDistanceThreshold = xmlFile:getValue(xmlKey .. ".footsteps.right#liftedDistanceThreshold", 0.1)
    self.right.playDistance = xmlFile:getValue(xmlKey .. ".footsteps.right#playDistance", 0.02)
    self.right.surfaceIdToSound = {}
    self.right.surfaceNameToSound = {}
    link(rootNode, self.right.soundNode)
    self.samples = {}
    self.samples.swim = g_soundManager:loadSampleFromXML(xmlFile, xmlKey .. ".water", "swim", self.baseDirectory, rootNode, 0, AudioGroup.ENVIRONMENT, nil, nil)
    self.samples.swimFast = g_soundManager:loadSampleFromXML(xmlFile, xmlKey .. ".water", "swimFast", self.baseDirectory, rootNode, 0, AudioGroup.ENVIRONMENT, nil, nil)
    self.samples.swimIdle = g_soundManager:loadSampleFromXML(xmlFile, xmlKey .. ".water", "swimIdle", self.baseDirectory, rootNode, 0, AudioGroup.ENVIRONMENT, nil, nil)
    self.samples.plunge = g_soundManager:loadSampleFromXML(xmlFile, xmlKey .. ".water", "plunge", self.baseDirectory, rootNode, 0, AudioGroup.ENVIRONMENT, nil, nil)
    self.samples.jump = g_soundManager:loadSampleFromXML(xmlFile, xmlKey .. ".jump", "takeoff", self.baseDirectory, rootNode, 0, AudioGroup.ENVIRONMENT, nil, nil)
    self.samples.landing = g_soundManager:loadSampleFromXML(xmlFile, xmlKey .. ".jump", "landing", self.baseDirectory, rootNode, 0, AudioGroup.ENVIRONMENT, nil, nil)
    if g_currentMission ~= nil then
        for _, surfaceSound in pairs(g_currentMission.surfaceSounds) do
            if surfaceSound.type == "footstep" and surfaceSound.sample ~= nil then
                local sampleLeft = g_soundManager:cloneSample(surfaceSound.sample, self.left.soundNode, self)
                sampleLeft.sampleName = surfaceSound.name
                self.left.surfaceIdToSound[surfaceSound.materialId] = sampleLeft
                self.left.surfaceNameToSound[surfaceSound.name] = sampleLeft
                local sampleRight = g_soundManager:cloneSample(surfaceSound.sample, self.right.soundNode, self)
                sampleRight.sampleName = surfaceSound.name
                self.right.surfaceIdToSound[surfaceSound.materialId] = sampleRight
                self.right.surfaceNameToSound[surfaceSound.name] = sampleRight
            end
        end
    end
    self.waterHeight = -1
    self.surfaceSample = nil
    self.surfaceId = nil
    self.isLoaded = true
    xmlFile:delete()
    return true
end
function HumanSounds:delete()
    self:unload()
end
function HumanSounds:unload()
    g_soundManager:deleteSamples(self.samples)
    if self.left ~= nil then
        g_soundManager:deleteSamples(self.left.surfaceNameToSound)
        g_soundManager:deleteSamples(self.right.surfaceNameToSound)
        self.left.surfaceNameToSound = nil
        self.left.surfaceIdToSound = nil
        self.right.surfaceNameToSound = nil
        self.right.surfaceIdToSound = nil
    end
    self.samples = nil
    self.isLoaded = false
end
function HumanSounds:update(_)
    if self.isLoaded then
        local activeCamera = g_cameraManager:getActiveCamera()
        if calcDistanceFrom(self.rootNode, activeCamera) <= 50 then
            local x, y, z = getWorldTranslation(self.rootNode)
            raycastClosestAsync(x, y + 2, z, 0, -1, 0, 10, "groundRaycastCallback", self, self.raycastMask)
            if self.lastPosX ~= nil then
                self.distanceMoved = MathUtil.vector2Length(x - self.lastPosX, z - self.lastPosZ)
            end
            self:updateSounds()
            self.lastPosX = x
            self.lastPosY = y
            self.lastPosZ = z
        end
    else
        return
    end
end
function HumanSounds:drawDebug(posX, posY, textSize)
    local distanceToGroundLeft = self:getFootDistanceToRootNode(self.left)
    DebugUtil.drawDebugNode(self.left.node, string.format("%.3f", distanceToGroundLeft), false, 0)
    local distanceToGroundRight = self:getFootDistanceToRootNode(self.right)
    DebugUtil.drawDebugNode(self.right.node, string.format("%.3f", distanceToGroundRight), false, 0)
    local function renderValue(key, value)
        -- upvalues: (copy) posX, (ref) posY, (copy) textSize
        if type(value) == "boolean" then
            value = tostring(value)
        elseif type(value) ~= "string" then
            value = string.format("%.4f", value)
        end
        setTextAlignment(RenderText.ALIGN_RIGHT)
        renderText(posX, posY, textSize, key .. " : ")
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(posX, posY, textSize, value)
        posY = posY - textSize - 2 * g_pixelSizeY
    end
    renderValue("left", "")
    renderValue("distance", distanceToGroundLeft)
    renderValue("isDirty", self.left.isDirty)
    renderValue("nodeOffset", self.left.nodeOffset)
    renderValue("liftedDistanceThreshold", self.left.liftedDistanceThreshold)
    renderValue("playDistance", self.left.playDistance)
    renderValue("", "")
    renderValue("right", "")
    renderValue("distance", distanceToGroundLeft)
    renderValue("isDirty", self.right.isDirty)
    renderValue("nodeOffset", self.right.nodeOffset)
    renderValue("liftedDistanceThreshold", self.right.liftedDistanceThreshold)
    renderValue("playDistance", self.right.playDistance)
end
function HumanSounds:groundRaycastCallback(nodeId, x, y, z, _, _, _, _, _, _, _)
    self.waterHeight = -1
    self.surfaceSample = nil
    self.surfaceId = nil
    if nodeId == 0 then
        return false
    elseif nodeId == g_terrainNode then
        if g_currentMission.snowSystem:getSnowHeightAtArea(x, z, x + 0.1, z + 0.1, x + 0.1, z) > 0 then
            self.surfaceSample = "snow"
            return false
        end
        local isOnField, _ = FSDensityMapUtil.getFieldDataAtWorldPosition(x, y, z)
        if isOnField then
            self.surfaceName = "field"
            return false
        end
        local _, _, _, _, materialId = getTerrainAttributesAtWorldPos(g_terrainNode, x, y, z, true, true, true, true, false)
        self.surfaceId = materialId
        return false
    elseif CollisionFlag.getHasGroupFlagSet(nodeId, CollisionFlag.WATER) then
        self.waterHeight = y - getTerrainHeightAtWorldPos(g_terrainNode, x, y, z)
        if self.waterHeight < 0.3 then
            self.surfaceName = "shallowWater"
        else
            self.surfaceName = "mediumWater"
        end
    else
        self.surfaceName = "asphalt"
        return false
    end
end
function HumanSounds:applyState(state)
    self.isCrouching = state.isCrouching
    self.isSwimming = state.isSwimming
    self.isForwardSwimming = state.isSwimming and (state.isWalking or state.isRunning)
    self.isSwimmingFast = state.isSwimming and state.isRunning
    self.isInWater = state.isInWater
    self.isIdling = state.isIdling
    self.isWalking = state.isWalking
    self.isRunning = state.isRunning
    self.isGrounded = state.isGrounded
    self.isCloseToGround = state.isCloseToGround
    self.distanceToGround = state.distanceToGround
    self.absSpeed = state.absSpeed
end
function HumanSounds:updateSounds()
    local samples = self.samples
    if samples.swim ~= nil then
        samples.swim.isActive = self.isSwimming and self.isForwardSwimming and not self.isSwimmingFast
    end
    if samples.swimFast ~= nil then
        samples.swimFast.isActive = self.isSwimming and self.isForwardSwimming and self.isSwimmingFast
    end
    if samples.swimIdle ~= nil then
        samples.swimIdle.isActive = self.isSwimming and not self.isForwardSwimming
    end
    for _, sample in pairs(samples) do
        if sample.isActive then
            if not g_soundManager:getIsSamplePlaying(sample) then
                g_soundManager:playSample(sample)
            end
        elseif g_soundManager:getIsSamplePlaying(sample) then
            g_soundManager:stopSample(sample)
        end
    end
    if not self.isSwimming and self.distanceToGround < 0.1 then
        self:updateFootStep(self.left)
        self:updateFootStep(self.right)
    end
end
function HumanSounds:updateFootStep(foot)
    setWorldTranslation(foot.soundNode, getWorldTranslation(foot.node))
    local distanceToGround = self:getFootDistanceToRootNode(foot)
    if foot.liftedDistanceThreshold < distanceToGround then
        foot.isDirty = true
    end
    if distanceToGround < foot.playDistance and foot.isDirty then
        foot.isDirty = false
        local sample = nil
        if self.surfaceId == nil then
            if self.surfaceName ~= nil then
                sample = foot.surfaceNameToSound[self.surfaceName]
            end
        else
            sample = foot.surfaceIdToSound[self.surfaceId]
        end
        if sample ~= nil then
            g_soundManager:playSample(sample)
        end
    end
end
function HumanSounds:getFootDistanceToRootNode(foot)
    local _, y, _ = localToLocal(foot.node, self.rootNode, 0, 0, 0)
    return y - foot.nodeOffset
end