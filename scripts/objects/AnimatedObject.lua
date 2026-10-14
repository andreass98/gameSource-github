source("dataS/scripts/objects/AnimatedObjectActivatable.lua")
source("dataS/scripts/objects/AnimatedObjectEvent.lua")
AnimatedObject = {}
local AnimatedObject_mt = Class(AnimatedObject, Object)
InitStaticObjectClass(AnimatedObject, "AnimatedObject")
function AnimatedObject.new(isServer, isClient, customMt)
    -- upvalues: (copy) AnimatedObject_mt
    local self = Object.new(isServer, isClient, customMt or AnimatedObject_mt)
    self.nodeId = 0
    self.isMoving = false
    self.controls = {}
    self.controls.wasPressed = false
    self.controls.posAction = nil
    self.controls.negAction = nil
    self.controls.posText = nil
    self.controls.negText = nil
    self.controls.posActionEventId = nil
    self.controls.negActionEventId = nil
    self.networkTimeInterpolator = InterpolationTime.new(1.2)
    self.networkAnimTimeInterpolator = InterpolatorValue.new(0)
    self.activatable = AnimatedObjectActivatable.new(self)
    return self
end
function AnimatedObject:load(rootNode, xmlFile, key, xmlFilename, i3dMappings)
    self.xmlFilename = xmlFilename
    local modName, baseDirectory = Utils.getModNameAndBaseDirectory(xmlFilename)
    self.baseDirectory = baseDirectory
    self.customEnvironment = modName
    self.nodeId = rootNode
    if type(rootNode) == "table" then
        self.nodeId = rootNode[1].node
    end
    self.saveId = xmlFile:getString(key .. "#saveId") or "AnimatedObject_" .. getName(self.nodeId)
    local animKey = key .. ".animation"
    self.animation = {}
    self.animation.parts = {}
    self.animation.shaderAnims = nil
    self.animation.clipRootNode = nil
    self.animation.clipName = nil
    self.animation.clipTrack = nil
    self.animation.duration = xmlFile:getFloat(animKey .. "#duration")
    self.animation.time = 0
    self.animation.direction = 0
    self.animation.maxTime = 0
    for _, partKey in xmlFile:iterator(animKey .. ".part") do
        local node = xmlFile:getNode(partKey .. "#node", nil, rootNode, i3dMappings)
        local partKey
        if node ~= nil and I3DUtil.iterateRecursively(node, function(nodeToCheck)
            -- upvalues: (copy) xmlFile, (copy) self, (copy) partKey
            if getRigidBodyType(nodeToCheck) == RigidBodyType.STATIC and getHasClassId(nodeToCheck, ClassIds.SHAPE) then
                Logging.xmlWarning(xmlFile, "Animated node %q at %q is a static rigid body, ignoring", I3DUtil.getNodePath(nodeToCheck, self.nodeId), partKey)
                return false
            end
        end, true) ~= false then
            local part = {
                ["node"] = node,
                ["frames"] = {}
            }
            for _, frameKey in xmlFile:iterator(partKey .. ".keyFrame") do
                local keyframe = {
                    self:loadFrameValues(xmlFile, frameKey, node),
                    ["time"] = xmlFile:getFloat(frameKey .. "#time")
                }
                self.animation.maxTime = math.max(keyframe.time, self.animation.maxTime)
                table.insert(part.frames, keyframe)
            end
            if #part.frames > 0 then
                table.insert(self.animation.parts, part)
            end
        end
    end
    for _, partKey in xmlFile:iterator(animKey .. ".shader") do
        local node = xmlFile:getNode(partKey .. "#node", nil, rootNode, i3dMappings)
        if node ~= nil then
            local checkStaticCol = xmlFile:getString(partKey .. "#parameterName")
            if checkStaticCol ~= nil and getHasShaderParameter(node, checkStaticCol) then
                local part = {
                    ["node"] = node,
                    ["parameterName"] = checkStaticCol,
                    ["frames"] = {}
                }
                for _, frameKey in xmlFile:iterator(partKey .. ".keyFrame") do
                    local keyframe = xmlFile:getFloat(frameKey .. "#time")
                    local shaderValuesStr = xmlFile:getString(frameKey .. "#values", nil)
                    if shaderValuesStr ~= nil then
                        local values = string.split(shaderValuesStr, " ")
                        if #values > 4 then
                            Logging.xmlWarning(xmlFile, "More than 4 values (%q) given for shader parameters at %q", shaderValuesStr, frameKey .. "#values")
                        end
                        values[1] = tonumber(values[1])
                        values[2] = tonumber(values[2])
                        values[3] = tonumber(values[3])
                        values[4] = tonumber(values[4])
                        values.time = keyframe
                        table.insert(part.frames, values)
                    end
                end
                if #part.frames > 0 then
                    self.animation.shaderAnims = self.animation.shaderAnims or {}
                    table.insert(self.animation.shaderAnims, part)
                end
            end
        end
    end
    for _, partKey in ipairs(self.animation.parts) do
        partKey.animCurve = AnimCurve.new(linearInterpolatorN)
        for _, frame in ipairs(partKey.frames) do
            frame.time = frame.time / self.animation.maxTime
            partKey.animCurve:addKeyframe(frame)
        end
        partKey.frames = nil
    end
    if self.animation.shaderAnims ~= nil then
        for _, partKey in ipairs(self.animation.shaderAnims) do
            partKey.animCurve = AnimCurve.new(linearInterpolatorN)
            for _, frame in ipairs(partKey.frames) do
                frame.time = frame.time / self.animation.maxTime
                partKey.animCurve:addKeyframe(frame)
            end
            partKey.frames = nil
        end
    end
    local clipRootNode = xmlFile:getNode(animKey .. ".clip#rootNode", nil, rootNode, i3dMappings)
    local clipName = xmlFile:getString(animKey .. ".clip#name")
    if clipRootNode ~= nil and clipName ~= nil then
        local clipFilename = xmlFile:getString(animKey .. ".clip#filename")
        self.animation.clipRootNode = clipRootNode
        self.animation.clipName = clipName
        self.animation.clipTrack = 0
        if clipFilename == nil then
            self:applyAnimation()
        else
            clipFilename = Utils.getFilename(clipFilename, self.baseDirectory)
            self.animation.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(clipFilename, false, false, self.onSharedAnimationFileLoaded, self, nil)
            self.animation.clipFilename = clipFilename
        end
    end
    self.rollingGateAnimations = {}
    for node, checkStaticCol in xmlFile:iterator(animKey .. ".rollingGateAnimation") do
        local part = RollingGateAnimation.new()
        if part:load(xmlFile, checkStaticCol, rootNode, i3dMappings) then
            if self.rollingGateAnimations == nil then
                self.rollingGateAnimations = {}
            end
            table.insert(self.rollingGateAnimations, part)
        end
    end
    if self.animation.duration == nil then
        self.animation.duration = self.animation.maxTime
    end
    self.animation.duration = self.animation.duration * 1000
    local clipFilename = xmlFile:getFloat(animKey .. "#initialTime", 0) * 1000
    local _ = 0
    if self.animation.duration ~= 0 then
        _ = clipFilename / self.animation.duration
    end
    self:setAnimTime(_, true)
    local partKey = xmlFile:getFloat(key .. ".openingHours#startTime")
    local node = xmlFile:getFloat(key .. ".openingHours#endTime")
    if partKey ~= nil and node ~= nil then
        self.openingHours = {
            ["startTime"] = partKey,
            ["endTime"] = node,
            ["disableIfClosed"] = xmlFile:getBool(key .. ".openingHours#disableIfClosed", false),
            ["closedText"] = xmlFile:getI18NValue(key .. ".openingHours#closedText", nil, self.customEnvironment)
        }
        g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self)
    end
    self.isEnabled = true
    local checkStaticCol = xmlFile:getNode(key .. ".controls#triggerNode", nil, rootNode, i3dMappings)
    if checkStaticCol ~= nil then
        self.triggerNode = checkStaticCol
        addTrigger(self.triggerNode, "triggerCallback", self)
        local frame = 0
        local part = getNumOfChildren(self.triggerNode) - 1
        for frame = frame, part do
            addTrigger(getChildAt(self.triggerNode, frame), "triggerCallback", self)
        end
        if InputAction ~= nil then
            local part = xmlFile:getString(key .. ".controls#posAction")
            if part ~= nil then
                if InputAction[part] then
                    self.controls.posAction = part
                    local _ = xmlFile:getString(key .. ".controls#posText")
                    if _ ~= nil then
                        if g_i18n:hasText(_, self.customEnvironment) then
                            _ = g_i18n:getText(_, self.customEnvironment)
                        end
                        self.controls.posActionText = _
                    end
                    local frame = xmlFile:getString(key .. ".controls#negText")
                    if frame ~= nil then
                        if g_i18n:hasText(frame, self.customEnvironment) then
                            frame = g_i18n:getText(frame, self.customEnvironment)
                        end
                        self.controls.negActionText = frame
                    end
                    local negAction = xmlFile:getString(key .. ".controls#negAction")
                    if negAction ~= nil then
                        if InputAction[negAction] then
                            self.controls.negAction = negAction
                        else
                            printWarning("Warning: Negative direction action \'" .. negAction .. "\' not defined!")
                        end
                    end
                else
                    printWarning("Warning: Positive direction action \'" .. part .. "\' not defined!")
                end
            end
        end
    end
    if g_client ~= nil then
        local part = key .. ".sounds"
        self.samplesMoving = g_soundManager:loadSamplesFromXML(xmlFile, part, "moving", self.baseDirectory, rootNode, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
        self.samplePosEnd = g_soundManager:loadSampleFromXML(xmlFile, part, "posEnd", self.baseDirectory, rootNode, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
        self.sampleNegEnd = g_soundManager:loadSampleFromXML(xmlFile, part, "negEnd", self.baseDirectory, rootNode, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
    end
    self.animatedObjectDirtyFlag = self:getNextDirtyFlag()
    return true
end
function AnimatedObject:builder(xmlFilename, saveId)
    return AnimatedObjectBuilder.new(self, xmlFilename, saveId)
end
function AnimatedObject.loadFrameValues(_, xmlFile, key, node)
    local rx, ry, rz = xmlFile:getRotation(key .. "#rotation")
    if rx == nil then
        rx, ry, rz = getRotation(node)
    end
    local x, y, z = xmlFile:getTranslation(key .. "#translation")
    if x == nil then
        x, y, z = getTranslation(node)
    end
    local sx, sy, sz = xmlFile:getScale(key .. "#scale")
    if sx == nil then
        sx, sy, sz = getScale(node)
    end
    return x, y, z, rx, ry, rz, sx, sy, sz, not xmlFile:getBool(key .. "#visibility", true) and 0 or 1
end
function AnimatedObject:onSharedAnimationFileLoaded(node, _, _)
    if node ~= 0 and node ~= nil then
        if not self.isDeleted then
            local animNode = getChildAt(node, 0)
            cloneAnimCharacterSet(animNode, getParent(self.animation.clipRootNode))
            self:applyAnimation()
        end
        delete(node)
    end
end
function AnimatedObject:applyAnimation()
    if self.animation.clipRootNode == nil or self.animation.clipRootNode == 0 then
        Logging.error("Animation clipRootNode not set")
        return
    else
        local characterSet = getAnimCharacterSet(self.animation.clipRootNode)
        if characterSet == 0 then
            Logging.error("Animation character set not found for node \'%s\'", getName(self.animation.clipRootNode))
            return
        else
            local clipIndex = getAnimClipIndex(characterSet, self.animation.clipName)
            if clipIndex == -1 then
                Logging.error("Animation clip with name \'%s\' does not exist in \'%s\'", self.animation.clipName, self.animation.clipFilename or self.xmlFilename)
            else
                assignAnimTrackClip(characterSet, self.animation.clipTrack, clipIndex)
                setAnimTrackLoopState(characterSet, self.animation.clipTrack, false)
                self.animation.clipDuration = getAnimClipDuration(characterSet, clipIndex)
                self.animation.clipCharacterSet = characterSet
                self:setAnimTime(self.animation.time, false)
            end
        end
    end
end
function AnimatedObject:delete()
    if self.triggerNode ~= nil then
        removeTrigger(self.triggerNode)
        local i = 0
        for i = i, getNumOfChildren(self.triggerNode) - 1 do
            removeTrigger(getChildAt(self.triggerNode, i))
        end
        self.triggerNode = nil
    end
    if self.samplesMoving ~= nil then
        g_soundManager:deleteSamples(self.samplesMoving)
        self.samplesMoving = nil
    end
    if self.samplePosEnd ~= nil then
        g_soundManager:deleteSample(self.samplePosEnd)
        self.samplePosEnd = nil
    end
    if self.sampleNegEnd ~= nil then
        g_soundManager:deleteSample(self.sampleNegEnd)
        self.sampleNegEnd = nil
    end
    if self.animation ~= nil and self.animation.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.animation.sharedLoadRequestId)
        self.animation.sharedLoadRequestId = nil
    end
    if g_currentMission ~= nil then
        g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
    end
    if g_messageCenter ~= nil then
        g_messageCenter:unsubscribeAll(self)
    end
    self.isDeleted = true
    AnimatedObject:superClass().delete(self)
end
function AnimatedObject:readStream(streamId, connection)
    AnimatedObject:superClass().readStream(self, streamId, connection)
    if connection:getIsServer() then
        local animTime = streamReadFloat32(streamId)
        self:setAnimTime(animTime, true)
        local direction = streamReadUIntN(streamId, 2) - 1
        self.animation.direction = direction
        self.networkAnimTimeInterpolator:setValue(animTime)
        self.networkTimeInterpolator:reset()
    end
end
function AnimatedObject:writeStream(streamId, connection)
    AnimatedObject:superClass().writeStream(self, streamId, connection)
    if not connection:getIsServer() then
        streamWriteFloat32(streamId, self.animation.time)
        streamWriteUIntN(streamId, self.animation.direction + 1, 2)
    end
end
function AnimatedObject:readUpdateStream(streamId, timestamp, connection)
    AnimatedObject:superClass().readUpdateStream(self, streamId, timestamp, connection)
    if connection:getIsServer() and streamReadBool(streamId) then
        self.networkTimeInterpolator:startNewPhaseNetwork()
        local animTime = streamReadFloat32(streamId)
        self.networkAnimTimeInterpolator:setTargetValue(animTime)
        local direction = streamReadUIntN(streamId, 2) - 1
        self.animation.direction = direction
    end
end
function AnimatedObject:writeUpdateStream(streamId, connection, dirtyMask)
    AnimatedObject:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.animatedObjectDirtyFlag) ~= 0) then
            streamWriteFloat32(streamId, self.animation.timeSend)
            streamWriteUIntN(streamId, self.animation.direction + 1, 2)
        end
    end
end
function AnimatedObject:loadFromXMLFile(xmlFile, key)
    local animTime = xmlFile:getFloat(key .. "#time")
    if animTime ~= nil then
        self.animation.direction = xmlFile:getInt(key .. "#direction", 0)
        self:setAnimTime(animTime, true)
    end
    AnimatedObject.hourChanged(self)
    return true
end
function AnimatedObject:saveToXMLFile(xmlFile, key, _)
    xmlFile:setFloat(key .. "#time", self.animation.time)
    xmlFile:setInt(key .. "#direction", self.animation.direction)
end
function AnimatedObject:reset()
    self.animation.time = 0
end
function AnimatedObject:resetTime()
    self.animation.time = 0
    self.networkAnimTimeInterpolator:setValue(0)
    self.networkTimeInterpolator:reset()
end
function AnimatedObject:setDirection(direction)
    self.animation.direction = direction
    if self.animation.direction == 0 then
        if self.animation.time > 0 then
            self.animation.direction = -1
        else
            self.animation.direction = 1
        end
    end
    if g_server == nil then
        g_client:getServerConnection():sendEvent(AnimatedObjectEvent.new(self, self.animation.direction))
    else
        if self.aiBlockingRegion ~= nil and self.animation.time == 1 then
            g_currentMission.aiSystem:setBlockingRegionState(self.aiBlockingRegion.blockingRegionId, true)
        end
        self:raiseActive()
    end
end
function AnimatedObject:update(dt)
    AnimatedObject:superClass().update(self, dt)
    local finishedAnimation = false
    if self.isServer then
        if self.animation.direction ~= 0 then
            local newAnimTime = 0
            if self.animation.duration ~= 0 then
                newAnimTime = math.clamp(self.animation.time + self.animation.direction * dt / self.animation.duration, 0, 1)
            end
            self:setAnimTime(newAnimTime)
            if newAnimTime == 0 or newAnimTime == 1 then
                self.animation.direction = 0
                finishedAnimation = true
                if self.aiBlockingRegion ~= nil then
                    g_currentMission.aiSystem:setBlockingRegionState(self.aiBlockingRegion.blockingRegionId, newAnimTime == 0)
                end
            end
        end
        if self.animation.time ~= self.animation.timeSend then
            self.animation.timeSend = self.animation.time
            self:raiseDirtyFlags(self.animatedObjectDirtyFlag)
        end
    else
        self.networkTimeInterpolator:update(dt)
        local newAnimTime = self.networkTimeInterpolator:getAlpha()
        local newAnimTime = self:setAnimTime((self.networkAnimTimeInterpolator:getInterpolatedValue(newAnimTime)))
        if self.animation.direction ~= 0 then
            if self.animation.direction > 0 then
                if newAnimTime == 1 then
                    self.animation.direction = 0
                    finishedAnimation = true
                end
            elseif newAnimTime == 0 then
                self.animation.direction = 0
                finishedAnimation = true
            end
        end
        if self.networkTimeInterpolator:isInterpolating() then
            self:raiseActive()
        end
    end
    if self.samplesMoving ~= nil then
        if self.isMoving and self.animation.direction ~= 0 then
            if not self.samplesMovingArePlaying then
                g_soundManager:playSamples(self.samplesMoving)
                self.samplesMovingArePlaying = true
            end
        elseif self.samplesMovingArePlaying then
            g_soundManager:stopSamples(self.samplesMoving)
            self.samplesMovingArePlaying = false
        end
    end
    if finishedAnimation and self.animation.direction == 0 then
        if self.samplePosEnd == nil or self.animation.time ~= 1 then
            if self.sampleNegEnd ~= nil and self.animation.time == 0 then
                g_soundManager:playSample(self.sampleNegEnd)
            end
        else
            g_soundManager:playSample(self.samplePosEnd)
        end
    end
    self.isMoving = false
    if self.animation.direction ~= 0 then
        self:raiseActive()
    end
end
function AnimatedObject:getCanBeTriggered()
    return true
end
function AnimatedObject:setAnimTime(t, _)
    local characterSet = math.clamp(t, 0, 1)
    for _, part in pairs(self.animation.parts) do
        local x, y, z, rx, ry, rz, sx, sy, sz, vis = part.animCurve:get(characterSet)
        setTranslation(part.node, x, y, z)
        setRotation(part.node, rx, ry, rz)
        setScale(part.node, sx, sy, sz)
        setVisibility(part.node, vis == 1)
    end
    if self.animation.shaderAnims ~= nil then
        for _, part in pairs(self.animation.shaderAnims) do
            local x, y, z, rx = part.animCurve:get(characterSet)
            setShaderParameter(part.node, part.parameterName, x, y, z, rx, false)
        end
    end
    local characterSet = self.animation.clipCharacterSet
    if characterSet ~= nil then
        enableAnimTrack(characterSet, self.animation.clipTrack)
        setAnimTrackTime(characterSet, self.animation.clipTrack, characterSet * self.animation.clipDuration, true)
        disableAnimTrack(characterSet, self.animation.clipTrack)
    end
    if self.rollingGateAnimations ~= nil then
        for part, x in pairs(self.rollingGateAnimations) do
            x:setState(characterSet)
        end
    end
    self.animation.time = characterSet
    self.isMoving = true
    return characterSet
end
function AnimatedObject.setFrameValues(_, node, v)
    setTranslation(node, v[1], v[2], v[3])
    setRotation(node, v[4], v[5], v[6])
    setScale(node, v[7], v[8], v[9])
    setVisibility(node, v[10] == 1)
end
function AnimatedObject:hourChanged()
    if self.isServer then
        if g_currentMission ~= nil and g_currentMission.environment ~= nil then
            if self.openingHours ~= nil then
                local currentHour = g_currentMission.environment.currentHour
                if self.openingHours.startTime <= currentHour and currentHour < self.openingHours.endTime then
                    if not self.openingHours.isOpen then
                        if self.isServer then
                            self.animation.direction = 1
                            self:raiseActive()
                        end
                        self.openingHours.isOpen = true
                    end
                    if self.openingHours.disableIfClosed then
                        self.isEnabled = true
                        return
                    end
                else
                    if self.openingHours.isOpen then
                        if self.isServer then
                            self.animation.direction = -1
                            self:raiseActive()
                        end
                        self.openingHours.isOpen = false
                    end
                    if self.openingHours.disableIfClosed then
                        self.isEnabled = false
                    end
                end
            end
        end
    else
        return
    end
end
function AnimatedObject:triggerCallback(_, otherId, onEnter, onLeave, _)
    if g_currentMission.missionInfo:isa(FSCareerMissionInfo) and (onEnter or onLeave) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
        if onEnter then
            g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
        else
            g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
        end
        self:raiseActive()
    end
end
function AnimatedObject.registerXMLPaths(schema, basePath)
    schema:setXMLSharedRegistration("AnimatedObject", basePath)
    basePath = basePath .. ".animatedObject(?)"
    schema:register(XMLValueType.STRING, basePath .. "#saveId", "Save identifier", "AnimatedObject_[nodeName]")
    schema:register(XMLValueType.FLOAT, basePath .. ".animation#duration", "Animation duration (sec.)", 3)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".animation.part(?)#node", "Part node")
    schema:register(XMLValueType.FLOAT, basePath .. ".animation.part(?).keyFrame(?)#time", "Key time")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".animation.part(?).keyFrame(?)#rotation", "Key rotation", "values read from i3d node")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".animation.part(?).keyFrame(?)#translation", "Key translation", "values read from i3d node")
    schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".animation.part(?).keyFrame(?)#scale", "Key scale", "values read from i3d node")
    schema:register(XMLValueType.BOOL, basePath .. ".animation.part(?).keyFrame(?)#visibility", "Key visibility", true)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".animation.shader(?)#node", "Shader node")
    schema:register(XMLValueType.STRING, basePath .. ".animation.shader(?)#parameterName", "Shader parameter name")
    schema:register(XMLValueType.FLOAT, basePath .. ".animation.shader(?).keyFrame(?)#time", "Key time")
    schema:register(XMLValueType.STRING, basePath .. ".animation.shader(?).keyFrame(?)#values", "Key shader parameter values. Use \'-\' to force using existing shader parameter value")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".animation.clip#rootNode", "I3d animation rootnode")
    schema:register(XMLValueType.STRING, basePath .. ".animation.clip#name", "I3d animation clipName")
    schema:register(XMLValueType.STRING, basePath .. ".animation.clip#filename", "I3d animation external animation")
    RollingGateAnimation.registerXMLPaths(schema, basePath .. ".animation.rollingGateAnimation(?)")
    schema:register(XMLValueType.FLOAT, basePath .. ".animation#initialTime", "Animation time after loading", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".openingHours#startTime", "Start day time")
    schema:register(XMLValueType.FLOAT, basePath .. ".openingHours#endTime", "End day time")
    schema:register(XMLValueType.BOOL, basePath .. ".openingHours#disableIfClosed", "Disabled if closed")
    schema:register(XMLValueType.L10N_STRING, basePath .. ".openingHours#closedText", "Closed text")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".controls#triggerNode", "Player trigger node")
    schema:register(XMLValueType.STRING, basePath .. ".controls#posAction", "Positive direction action event name")
    schema:registerAutoCompletionDataSource(basePath .. ".controls#posAction", "$dataS/inputActions.xml", "actions.action#name")
    schema:register(XMLValueType.STRING, basePath .. ".controls#posText", "Positive direction text")
    schema:register(XMLValueType.STRING, basePath .. ".controls#negText", "Negative direction text")
    schema:register(XMLValueType.STRING, basePath .. ".controls#negAction", "Negative direction action event name")
    schema:registerAutoCompletionDataSource(basePath .. ".controls#negAction", "$dataS/inputActions.xml", "actions.action#name")
    if SoundManager ~= nil then
        SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "moving(?)")
        SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "posEnd")
        SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "negEnd")
    end
    schema:resetXMLSharedRegistration("AnimatedObject", basePath)
end
function AnimatedObject.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.FLOAT, basePath .. "#time", "Animated object time")
    schema:register(XMLValueType.INT, basePath .. "#direction", "Animated object direction", 0)
end
AnimatedObjectBuilder = {}
local AnimatedObjectBuilder_mt = Class(AnimatedObjectBuilder)
function AnimatedObjectBuilder.registerXMLPaths(schema, basePath)
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "moving(?)")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "posEnd")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "negEnd")
end
function AnimatedObjectBuilder.new(animatedObject, xmlFilename, saveId)
    -- upvalues: (copy) AnimatedObjectBuilder_mt
    local self = setmetatable({}, AnimatedObjectBuilder_mt)
    self.animatedObject = animatedObject
    local modName, baseDirectory = Utils.getModNameAndBaseDirectory(xmlFilename)
    animatedObject.baseDirectory = baseDirectory
    animatedObject.customEnvironment = modName
    animatedObject.saveId = saveId
    animatedObject.animation = {}
    animatedObject.animation.parts = {}
    animatedObject.animation.time = 0
    animatedObject.animation.direction = 0
    animatedObject.animation.duration = 1000
    animatedObject.animation.shaderAnims = {}
    animatedObject.isEnabled = true
    return self
end
function AnimatedObjectBuilder:build(_)
    local ao = self.animatedObject
    ao:setAnimTime(0, true)
    if ao.openingHours ~= nil then
        g_messageCenter:subscribe(MessageType.HOUR_CHANGED, ao.hourChanged, ao)
    end
    if ao.triggerNode ~= nil then
        local node = ao.triggerNode
        addTrigger(node, "triggerCallback", ao)
        local i = 0
        for i = i, getNumOfChildren(node) - 1 do
            addTrigger(getChildAt(node, i), "triggerCallback", ao)
        end
    end
    ao.animatedObjectDirtyFlag = ao:getNextDirtyFlag()
    return true
end
function AnimatedObjectBuilder:setTrigger(node)
    self.animatedObject.triggerNode = node
end
function AnimatedObjectBuilder:setActions(posAction, posText, negAction, negText)
    if posAction ~= nil then
        if InputAction[posAction] then
            self.animatedObject.controls.posAction = posAction
            if posText ~= nil then
                if g_i18n:hasText(posText, ao.customEnvironment) then
                    posText = g_i18n:getText(posText, ao.customEnvironment)
                end
                ao.controls.posActionText = posText
            end
            if negText ~= nil then
                if g_i18n:hasText(negText, ao.customEnvironment) then
                    negText = g_i18n:getText(negText, ao.customEnvironment)
                end
                ao.controls.negActionText = negText
            end
            if negAction ~= nil then
                if InputAction[negAction] then
                    ao.controls.negAction = negAction
                else
                    printWarning("Warning: Negative direction action \'" .. negAction .. "\' not defined!")
                end
            end
        else
            printWarning("Warning: Positive direction action \'" .. posAction .. "\' not defined!")
        end
    end
end
function AnimatedObjectBuilder:addSimplePart(node, openRotation, openTranslation)
    local part = {
        ["node"] = node,
        ["animCurve"] = AnimCurve.new(linearInterpolatorN)
    }
    local x, y, z = getTranslation(node)
    local rx, ry, rz = getRotation(node)
    local sx, sy, sz = getScale(node)
    part.animCurve:addKeyframe({
        x,
        y,
        z,
        rx,
        ry,
        rz,
        sx,
        sy,
        sz,
        1,
        ["time"] = 0
    })
    if openTranslation ~= nil then
        x, y, z = unpack(openTranslation)
    end
    if openRotation ~= nil then
        rx, ry, rz = unpack(openRotation)
    end
    part.animCurve:addKeyframe({
        x,
        y,
        z,
        rx,
        ry,
        rz,
        sx,
        sy,
        sz,
        1,
        ["time"] = 1
    })
    table.insert(self.animatedObject.animation.parts, part)
end
function AnimatedObjectBuilder:setDuration(duration)
    self.animatedObject.animation.duration = duration
end
function AnimatedObjectBuilder:setSounds(xmlFile, key, rootNode)
    if g_client ~= nil then
        self.animatedObject.samplesMoving = g_soundManager:loadSamplesFromXML(xmlFile, key, "moving", self.animatedObject.baseDirectory, rootNode, 1, AudioGroup.ENVIRONMENT, nil, nil)
        self.animatedObject.samplePosEnd = g_soundManager:loadSampleFromXML(xmlFile, key, "posEnd", self.animatedObject.baseDirectory, rootNode, 1, AudioGroup.ENVIRONMENT, nil, nil)
        self.animatedObject.sampleNegEnd = g_soundManager:loadSampleFromXML(xmlFile, key, "negEnd", self.animatedObject.baseDirectory, rootNode, 1, AudioGroup.ENVIRONMENT, nil, nil)
    end
end
function AnimatedObjectBuilder:setOpeningTimes(startTime, endTime, disableIfClosed, closedText)
    if startTime ~= nil and endTime ~= nil then
        self.animatedObject.openingHours = {
            ["startTime"] = startTime,
            ["endTime"] = endTime,
            ["disableIfClosed"] = disableIfClosed,
            ["closedText"] = closedText
        }
    end
end