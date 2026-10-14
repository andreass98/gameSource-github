FeedingRobot = {}
local FeedingRobot_mt = Class(FeedingRobot, Object)
InitStaticObjectClass(FeedingRobot, "FeedingRobot")
g_xmlManager:addCreateSchemaFunction(function()
    FeedingRobot.xmlSchema = XMLSchema.new("feedingRobot")
end)
g_xmlManager:addInitSchemaFunction(function()
    local schema = FeedingRobot.xmlSchema
    schema:register(XMLValueType.STRING, "feedingRobot.filename", "Feeding robot i3d file", nil, true)
    schema:register(XMLValueType.NODE_INDEX, "feedingRobot.robot#node", "Robot node")
    schema:register(XMLValueType.NODE_INDEX, "feedingRobot.robot.door#node", "Robot door node")
    schema:register(XMLValueType.FLOAT, "feedingRobot.robot.door#maxY", "Robot door maxY")
    schema:register(XMLValueType.FLOAT, "feedingRobot.robot.door#maxRotZ", "Robot door maxRotZ")
    schema:register(XMLValueType.FLOAT, "feedingRobot.robot.door#duration", "Robot door duration")
    schema:register(XMLValueType.FLOAT, "feedingRobot.robot#maxSpeed", "Max Speed", 0)
    schema:register(XMLValueType.FLOAT, "feedingRobot.robot#acceleration", "Max acceleration", 1)
    schema:register(XMLValueType.FLOAT, "feedingRobot.robot#deceleration", "Max deceleration", -1)
    schema:register(XMLValueType.NODE_INDEX, "feedingRobot.robot#triggerNode", "Vehicle and player trigger node")
    schema:register(XMLValueType.STRING, "feedingRobot.stateMachine.states.state(?)#name", "State name")
    schema:register(XMLValueType.STRING, "feedingRobot.stateMachine.states.state(?)#class", "State class")
    FeedingRobotState.registerXMLPaths(schema, "feedingRobot.stateMachine.states.state(?)")
    FeedingRobotStateFilling.registerXMLPaths(schema, "feedingRobot.stateMachine.states.state(?)")
    FeedingRobotStateWait.registerXMLPaths(schema, "feedingRobot.stateMachine.states.state(?)")
    FeedingRobotStateDriving.registerXMLPaths(schema, "feedingRobot.stateMachine.states.state(?)")
    I3DUtil.registerI3dMappingXMLPaths(schema, "feedingRobot")
    schema:register(XMLValueType.NODE_INDEX, "feedingRobot.playerTrigger#node", "Vehicle and player trigger node")
    schema:register(XMLValueType.STRING, "feedingRobot.stateMachine.transitions.transition(?)#from", "State name from")
    schema:register(XMLValueType.STRING, "feedingRobot.stateMachine.transitions.transition(?)#to", "State name to")
    AnimatedObject.registerXMLPaths(schema, "feedingRobot.animatedObjects")
    AnimationManager.registerAnimationNodesXMLPaths(schema, "feedingRobot.robot.mixer.animationNodes")
    EffectManager.registerEffectXMLPaths(schema, "feedingRobot.robot.dischargeEffects")
    schema:register(XMLValueType.NODE_INDEX, "feedingRobot.robot.fillPlane#node", "Fillplane base node")
    schema:register(XMLValueType.INT, "feedingRobot.robot.fillPlane#capacity", "Fillplane capacity")
    schema:register(XMLValueType.STRING, "feedingRobot.robot.mixer#recipe", "Recipe filltype")
    FillPlaneUtil.registerFillPlaneXMLPaths(schema, "feedingRobot.robot.fillPlane")
    SoundManager.registerSampleXMLPaths(schema, "feedingRobot.robot.sounds", "driving")
    SoundManager.registerSampleXMLPaths(schema, "feedingRobot.robot.sounds", "discharging")
    UnloadTrigger.registerTriggerXMLPaths(schema, "feedingRobot.unloadingSpots.unloadingSpot(?)")
    FillPlane.registerXMLPaths(schema, "feedingRobot.unloadingSpots.unloadingSpot(?).fillPlane")
    schema:register(XMLValueType.NODE_INDEX, "feedingRobot.unloadingSpots.unloadingSpot(?).fillVolume#node", "Fillplane base node")
    FillPlaneUtil.registerFillPlaneXMLPaths(schema, "feedingRobot.unloadingSpots.unloadingSpot(?).fillVolume")
    schema:register(XMLValueType.STRING, "feedingRobot.unloadingSpots.unloadingSpot(?)#capacity", "Unloading spot capacity")
    schema:register(XMLValueType.STRING, "feedingRobot.unloadingSpots.unloadingSpot(?)#fillTypes", "Unloading spot filltypes")
    schema:register(XMLValueType.STRING, "feedingRobot.unloadingSpots.unloadingSpot(?)#fillTypeCategories", "Unloading spot filltype categories")
    schema:register(XMLValueType.NODE_INDEX, "feedingRobot.unloadingSpots.unloadingSpot(?)#markerNode", "Unloading spot marker")
    AnimationManager.registerAnimationNodesXMLPaths(schema, "feedingRobot.unloadingSpots.unloadingSpot(?).dischargeAnimationNodes")
    EffectManager.registerEffectXMLPaths(schema, "feedingRobot.unloadingSpots.unloadingSpot(?).dischargeEffects")
    SoundManager.registerSampleXMLPaths(schema, "feedingRobot.unloadingSpots.unloadingSpot(?).sounds", "discharging")
end)
function FeedingRobot.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. ".unloadingSpot(?)#index", "Unloading spot index")
    schema:register(XMLValueType.INT, basePath .. ".unloadingSpot(?)#fillLevel", "Unloading spot filllevel")
end
function FeedingRobot.new(isServer, isClient, owner, baseDirectory, customMt)
    -- upvalues: (copy) FeedingRobot_mt
    local self = Object.new(isServer, isClient, customMt or FeedingRobot_mt)
    self.owner = owner
    self.baseDirectory = baseDirectory
    self.i3dMappings = {}
    self.components = {}
    self.isLoadingFinished = false
    self.requestedStart = false
    self.reachedStopPoint = false
    self.spline = {}
    self.spline.nodes = {}
    self.spline.time = 0
    self.spline.timeSent = 0
    self.spline.length = 0
    self.spline.feedingLength = 0
    self.spline.feedingFactor = 0
    self.spline.dirtyFlag = self:getNextDirtyFlag()
    self.spline.timeInterpolator = InterpolationTime.new(1.2)
    self.spline.interpolator = InterpolatorSplineTime.new(0, false)
    self.fillTypeToUnloadingSpot = {}
    self.unloadingSpots = {}
    self.dirtyFlagFillLevel = self:getNextDirtyFlag()
    self.robot = nil
    self.playerTrigger = nil
    self.stateChangedListeners = {}
    self.animatedObjects = {}
    self.stateMachineNextIndex = 0
    self.stateIndex = nil
    self.state = {}
    self.stateMachine = {}
    self.stateTransitions = {}
    return self
end
function FeedingRobot:load(linkNode, filename, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArgs)
    local xmlFile = XMLFile.load("feedingRobot", filename, FeedingRobot.xmlSchema)
    if xmlFile == nil then
        return false
    end
    self.configFileName = filename
    local i3dFilename = Utils.getFilename(xmlFile:getValue("feedingRobot.filename"), self.baseDirectory)
    self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(i3dFilename, true, false, self.onI3DFileLoaded, self, {
        ["xmlFile"] = xmlFile,
        ["linkNode"] = linkNode,
        ["asyncCallbackFunction"] = asyncCallbackFunction,
        ["asyncCallbackObject"] = asyncCallbackObject,
        ["asyncCallbackArgs"] = asyncCallbackArgs
    })
    return true
end
function FeedingRobot:delete()
    if self.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
        self.sharedLoadRequestId = nil
    end
    if self.animatedObjects ~= nil then
        for _, animatedObject in ipairs(self.animatedObjects) do
            animatedObject:delete()
        end
        self.animatedObjects = nil
    end
    if self.isServer then
        if self.robot ~= nil then
            removeTrigger(self.robot.trigger)
        end
        if self.playerTrigger ~= nil then
            removeTrigger(self.playerTrigger)
        end
    end
    if self.robot ~= nil then
        g_animationManager:deleteAnimations(self.robot.mixerAnimationNodes)
        g_effectManager:deleteEffects(self.robot.dischargeEffects)
        g_soundManager:deleteSamples(self.robot.samples)
    end
    if self.unloadingSpots ~= nil then
        for _, animatedObject in ipairs(self.unloadingSpots) do
            for _, unloadTrigger in ipairs(animatedObject.unloadTriggers) do
                unloadTrigger:delete()
            end
            animatedObject.unloadTriggers = {}
            if animatedObject.markerNode ~= nil then
                g_currentMission:removeTriggerMarker(animatedObject.markerNode)
                animatedObject.markerNode = nil
            end
            g_animationManager:deleteAnimations(animatedObject.dischargeAnimationNodes)
            g_effectManager:deleteEffects(animatedObject.dischargeEffects)
            g_soundManager:deleteSamples(animatedObject.samples)
        end
    end
    if self.rootNode ~= nil then
        delete(self.rootNode)
        self.rootNode = nil
    end
    FeedingRobot:superClass().delete(self)
end
function FeedingRobot:onI3DFileLoaded(node, _, args)
    local xmlFile = args.xmlFile
    if node == 0 then
        ::l2::
        xmlFile:delete()
        args.asyncCallbackFunction(args.asyncCallbackObject, self, args.asyncCallbackArgs)
        return
    end
    local i = 0
    local duration = getNumOfChildren(node) - 1
    for i = i, duration do
        local component = {
            ["node"] = getChildAt(node, i)
        }
        table.insert(self.components, component)
    end
    if #self.components == 0 then
        Logging.xmlError(xmlFile, "Unable to get feedingRobot components")
        xmlFile:delete()
        asyncCallbackFunction(asyncCallbackObject, self, asyncCallbackArgs)
        return
    end
    I3DUtil.loadI3DMapping(xmlFile, "feedingRobot", self.components, self.i3dMappings)
    for component, component in ipairs(self.components) do
        link(args.linkNode, component.node)
    end
    self.rootNode = node
    self.robot = {}
    self.robot.node = xmlFile:getValue("feedingRobot.robot#node", nil, self.components, self.i3dMappings)
    if self.isClient then
        self.robot.mixerAnimationNodes = g_animationManager:loadAnimations(xmlFile, "feedingRobot.robot.mixer.animationNodes", self.components, self, self.i3dMappings)
        self.robot.dischargeEffects = g_effectManager:loadEffect(xmlFile, "feedingRobot.robot.dischargeEffects", self.components, self, self.i3dMappings)
        self.robot.samples = {}
        self.robot.samples.driving = g_soundManager:loadSampleFromXML(xmlFile, "feedingRobot.robot.sounds", "driving", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        self.robot.samples.discharging = g_soundManager:loadSampleFromXML(xmlFile, "feedingRobot.robot.sounds", "discharging", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    self.robot.maxSpeed = xmlFile:getValue("feedingRobot.robot#maxSpeed", 1) / 3600
    self.robot.speed = 0
    self.robot.acceleration = xmlFile:getValue("feedingRobot.robot#acceleration", 1) / 3600
    self.robot.deceleration = xmlFile:getValue("feedingRobot.robot#deceleration", -1) / 3600
    if self.robot.deceleration > 0 then
        self.robot.deceleration = -self.robot.deceleration
    end
    self.robot.door = {}
    self.robot.door.node = xmlFile:getValue("feedingRobot.robot.door#node", nil, self.components, self.i3dMappings)
    self.robot.door.maxY = xmlFile:getValue("feedingRobot.robot.door#maxY", nil)
    self.robot.door.maxRotZ = xmlFile:getAngle("feedingRobot.robot.door#maxRotZ", nil)
    local duration = xmlFile:getValue("feedingRobot.robot.door#duration", 1) * 1000
    self.robot.door.speed = (self.robot.door.maxY or (self.robot.door.maxRotZ or 0)) / duration
    self.robot.door.isOpen = false
    local i = xmlFile:getValue("feedingRobot.robot.mixer#recipe", "")
    local component = g_fillTypeManager:getFillTypeIndexByName(i)
    if component == nil then
        Logging.xmlError(xmlFile, "Recipe filltype \'%s\' not defined.", i)
    end
    local component = g_currentMission.animalFoodSystem:getRecipeByFillTypeIndex(component)
    if component == nil then
        Logging.xmlError(xmlFile, "Recipe \'%s\' not defined.", i)
    else
        self.infos = {}
        for _, ingredient in pairs(component.ingredients) do
            local info = {
                ["title"] = ingredient.title,
                ["text"] = "",
                ["fillTypes"] = {}
            }
            for _, fillType in ipairs(ingredient.fillTypes) do
                table.insert(info.fillTypes, fillType)
            end
            table.insert(self.infos, info)
        end
    end
    self.robot.recipe = component
    self.robot.fillPlane = {}
    self.robot.fillPlane.baseNode = xmlFile:getValue("feedingRobot.robot.fillPlane#node", nil, self.components, self.i3dMappings)
    self.robot.fillPlane.capacity = xmlFile:getValue("feedingRobot.robot.fillPlane#capacity", 2000)
    self.robot.fillPlane.fillLevel = 0
    self.robot.fillPlane.node = FillPlaneUtil.createFromXML(xmlFile, "feedingRobot.robot.fillPlane", self.robot.fillPlane.baseNode, self.robot.fillPlane.capacity)
    if self.robot.fillPlane.node ~= nil then
        FillPlaneUtil.assignDefaultMaterialsFromTerrain(self.robot.fillPlane.node, g_terrainNode)
        FillPlaneUtil.setFillType(self.robot.fillPlane.node, component)
        setVisibility(self.robot.fillPlane.node, false)
    end
    self.robot.trigger = xmlFile:getValue("feedingRobot.robot#triggerNode", nil, self.components, self.i3dMappings)
    self.robot.objectsInTrigger = {}
    self.robot.isBlocked = false
    if self.isServer then
        addTrigger(self.robot.trigger, "onRobotTrigger", self)
    end
    self.playerTrigger = xmlFile:getValue("feedingRobot.playerTrigger#node", nil, self.components, self.i3dMappings)
    self.nodesInPlayerTrigger = {}
    if self.isServer then
        addTrigger(self.playerTrigger, "onPlayerTrigger", self)
    end
    xmlFile:iterate("feedingRobot.animatedObjects.animatedObject", function(index, fillAnimationKey)
        -- upvalues: (copy) self, (copy) xmlFile
        local animatedObject = AnimatedObject.new(self.isServer, self.isClient)
        animatedObject:setOwnerFarmId(self:getOwnerFarmId(), false)
        if animatedObject:load(self.components, xmlFile, fillAnimationKey, self.configFileName, self.i3dMappings) then
            table.insert(self.animatedObjects, animatedObject)
        else
            Logging.xmlError(xmlFile, "Failed to load animated object %i", index)
        end
    end)
    local maxNumStates = 255
    xmlFile:iterate("feedingRobot.stateMachine.states.state", function(_, stateKey)
        -- upvalues: (copy) self, (copy) xmlFile, (copy) maxNumStates
        if self.stateMachineNextIndex > 255 then
            Logging.xmlWarning(xmlFile, "Maximum number of states reached (%d)", 255)
            return
        else
            local stateName = string.upper(xmlFile:getValue(stateKey .. "#name", ""))
            if self.state[stateName] == nil then
                local stateClassName = xmlFile:getValue(stateKey .. "#class", "")
                local class = ClassUtil.getClassObject(stateClassName)
                if class == nil then
                    Logging.xmlError(xmlFile, "State class \'%s\' not defined for \'%s\'", stateClassName, stateKey)
                else
                    local stateIndex = self.stateMachineNextIndex
                    self.state[stateName] = stateIndex
                    local state = class.new(self)
                    state:load(xmlFile, stateKey)
                    self.stateMachine[stateIndex] = state
                    self.stateMachineNextIndex = self.stateMachineNextIndex + 1
                    if self.stateIndex == nil then
                        self.stateIndex = stateIndex
                    end
                end
            else
                Logging.xmlError(xmlFile, "State \'%s\' at \'%s\' already defined", stateName, stateKey)
                return
            end
        end
    end)
    if self.state.PAUSED == nil then
        Logging.xmlError(xmlFile, "Mandatory state \'PAUSED\' not defined")
        xmlFile:delete()
        asyncCallbackFunction(asyncCallbackObject, self, asyncCallbackArgs)
        return
    end
    if self.state.DRIVING == nil then
        Logging.xmlError(xmlFile, "Mandatory state \'DRIVING\' not defined")
        xmlFile:delete()
        asyncCallbackFunction(asyncCallbackObject, self, asyncCallbackArgs)
        return
    end
    xmlFile:iterate("feedingRobot.stateMachine.transitions.transition", function(_, transitionKey)
        -- upvalues: (copy) xmlFile, (copy) self
        local stateFromName = string.upper(xmlFile:getValue(transitionKey .. "#from", ""))
        local stateFromIndex = self.state[stateFromName]
        if stateFromIndex == nil then
            Logging.xmlError(xmlFile, "Invalid state. Transition from name \'%s\' not defined for \'%s\'", stateFromName, transitionKey)
            return
        else
            local stateToName = string.upper(xmlFile:getValue(transitionKey .. "#to", ""))
            local stateToIndex = self.state[stateToName]
            if stateToIndex == nil then
                Logging.xmlError(xmlFile, "Invalid state. Transition to name \'%s\' not defined for \'%s\'", stateToName, transitionKey)
            else
                self.stateTransitions[stateFromIndex] = stateToIndex
            end
        end
    end)
    for ingredient, info in xmlFile:iterator("feedingRobot.unloadingSpots.unloadingSpot") do
        local spot = {
            ["unloadTriggers"] = UnloadTrigger.createTriggers(self.isServer, self.isClient, xmlFile, info, self.components, self, nil, self.i3dMappings),
            ["capacity"] = xmlFile:getInt(info .. "#capacity", 1000)
        }
        spot.FILLLEVEL_NUM_BITS = MathUtil.getNumRequiredBits(spot.capacity)
        spot.fillLevel = 0
        spot.fillTypes = {}
        spot.markerNode = xmlFile:getValue(info .. "#markerNode", nil, self.components, self.i3dMappings)
        if spot.markerNode ~= nil then
            g_currentMission:addTriggerMarker(spot.markerNode)
        end
        local fillTypeCategories = xmlFile:getValue(info .. "#fillTypeCategories")
        local fillTypeNames = xmlFile:getValue(info .. "#fillTypes")
        local fillType
        if fillTypeCategories == nil or fillTypeNames ~= nil then
            if fillTypeCategories == nil and fillTypeNames ~= nil then
                fillType = g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: \'" .. tostring(info) .. "\' has invalid fillType \'%s\'.")
                goto l46
            end
            Logging.xmlWarning(xmlFile, "\'%s\' An \'unloadingSpot\' entry needs either the \'fillTypeCategories\' or \'fillTypes\' attribute.", info)
            for _, unloadTrigger in ipairs(spot.unloadTriggers) do
                unloadTrigger:delete()
            end
        else
            fillType = g_fillTypeManager:getFillTypesByCategoryNames(fillTypeCategories, "Warning: \'" .. tostring(info) .. "\' has invalid fillTypeCategory \'%s\'.")
            ::l46::
            local fillType = nil
            for unloadTrigger, unloadTrigger in ipairs(spot.unloadTriggers) do
                unloadTrigger.fillTypes = {}
                for _, fillType in pairs(fillType) do
                    table.addElement(spot.fillTypes, fillType)
                    self.fillTypeToUnloadingSpot[fillType] = spot
                    unloadTrigger.fillTypes[fillType] = true
                end
            end
            spot.samples = {}
            spot.samples.discharging = g_soundManager:loadSampleFromXML(xmlFile, info .. ".sounds", "discharging", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
            spot.dischargeAnimationNodes = g_animationManager:loadAnimations(xmlFile, info .. ".dischargeAnimationNodes", self.components, self, self.i3dMappings)
            spot.dischargeEffects = g_effectManager:loadEffect(xmlFile, info .. ".dischargeEffects", self.components, self, self.i3dMappings)
            g_effectManager:setEffectTypeInfo(spot.dischargeEffects, fillType)
            if xmlFile:hasProperty(info .. ".fillPlane") then
                spot.fillPlane = FillPlane.new()
                spot.fillPlane:load(self.components, xmlFile, info .. ".fillPlane", self.i3dMappings)
                FillPlaneUtil.assignDefaultMaterialsFromTerrain(spot.fillPlane.node, g_terrainNode)
                FillPlaneUtil.setFillType(spot.fillPlane.node, fillType)
                setShaderParameter(spot.fillPlane.node, "isCustomShape", 1, 0, 0, 0, false)
            elseif xmlFile:hasProperty(info .. ".fillVolume") then
                local baseNode = xmlFile:getValue(info .. ".fillVolume#node", nil, self.components, self.i3dMappings)
                local fillVolumeNode = FillPlaneUtil.createFromXML(xmlFile, info .. ".fillVolume", baseNode, spot.capacity)
                if fillVolumeNode ~= nil then
                    spot.fillVolume = {}
                    spot.fillVolume.baseNode = baseNode
                    spot.fillVolume.node = fillVolumeNode
                    spot.fillVolume.fillLevel = 0
                    FillPlaneUtil.assignDefaultMaterialsFromTerrain(fillVolumeNode, g_terrainNode)
                    FillPlaneUtil.setFillType(fillVolumeNode, fillType)
                    setVisibility(fillVolumeNode, false)
                end
            end
            local fillVolumeNode = self.unloadingSpots
            table.insert(fillVolumeNode, spot)
        end
    end
    if self.finishedSplines then
        self:setSplineTime(0)
    end
    self:raiseActive()
    goto l2
end
function FeedingRobot:finalizePlacement()
    for _, component in ipairs(self.components) do
        addToPhysics(component.node)
    end
    for _, component in ipairs(self.animatedObjects) do
        component:register(true)
    end
    for _, component in ipairs(self.unloadingSpots) do
        for _, unloadTrigger in ipairs(component.unloadTriggers) do
            unloadTrigger:register(true)
        end
    end
    self.isLoadingFinished = true
end
function FeedingRobot:readStream(streamId, connection)
    FeedingRobot:superClass().readStream(self, streamId, connection)
    if connection:getIsServer() then
        self:setState((streamReadUInt8(streamId)))
        local splineTime = streamReadFloat32(streamId)
        self.spline.interpolator:setValue(splineTime)
        self.spline.timeInterpolator:reset()
        self.spline.time = splineTime
        for _, animatedObject in ipairs(self.animatedObjects) do
            local animatedObjectId = NetworkUtil.readNodeObjectId(streamId)
            animatedObject:readStream(streamId, connection)
            g_client:finishRegisterObject(animatedObject, animatedObjectId)
        end
        for _, animatedObject in ipairs(self.unloadingSpots) do
            for _, unloadTrigger in ipairs(animatedObject.unloadTriggers) do
                local unloadTriggerId = NetworkUtil.readNodeObjectId(streamId)
                unloadTrigger:readStream(streamId, connection)
                g_client:finishRegisterObject(unloadTrigger, unloadTriggerId)
            end
            animatedObject.fillLevel = streamReadUIntN(streamId, animatedObject.FILLLEVEL_NUM_BITS)
            self:updateUnloadingSpot(animatedObject)
        end
        self:raiseActive()
    end
end
function FeedingRobot:writeStream(streamId, connection)
    FeedingRobot:superClass().writeStream(self, streamId, connection)
    if not connection:getIsServer() then
        streamWriteUInt8(streamId, self.stateIndex)
        streamWriteFloat32(streamId, self.spline.timeSent)
        for _, animatedObject in ipairs(self.animatedObjects) do
            NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(animatedObject))
            animatedObject:writeStream(streamId, connection)
            g_server:registerObjectInStream(connection, animatedObject)
        end
        for _, animatedObject in ipairs(self.unloadingSpots) do
            for _, unloadTrigger in ipairs(animatedObject.unloadTriggers) do
                NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(unloadTrigger))
                unloadTrigger:writeStream(streamId, connection)
                g_server:registerObjectInStream(connection, unloadTrigger)
            end
            streamWriteUIntN(streamId, animatedObject.fillLevel, animatedObject.FILLLEVEL_NUM_BITS)
        end
    end
end
function FeedingRobot:readUpdateStream(streamId, timestamp, connection)
    FeedingRobot:superClass().readUpdateStream(self, streamId, timestamp, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            local splineTime = streamReadFloat32(streamId)
            self.spline.timeInterpolator:startNewPhaseNetwork()
            self.spline.interpolator:setTargetValue(splineTime)
        end
        if streamReadBool(streamId) then
            for _, spot in ipairs(self.unloadingSpots) do
                spot.fillLevel = streamReadUIntN(streamId, spot.FILLLEVEL_NUM_BITS)
                self:updateUnloadingSpot(spot)
            end
        end
    end
end
function FeedingRobot:writeUpdateStream(streamId, connection, dirtyMask)
    FeedingRobot:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.spline.dirtyFlag) ~= 0) then
            streamWriteFloat32(streamId, self.spline.timeSent)
        end
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.dirtyFlagFillLevel) ~= 0) then
            for _, spot in ipairs(self.unloadingSpots) do
                streamWriteUIntN(streamId, spot.fillLevel, spot.FILLLEVEL_NUM_BITS)
            end
        end
    end
end
function FeedingRobot:loadFromXMLFile(xmlFile, key)
    xmlFile:iterate(key .. ".unloadingSpot", function(_, fillLevelKey)
        -- upvalues: (copy) xmlFile, (copy) self
        local spotIndex = xmlFile:getValue(fillLevelKey .. "#index")
        local fillLevel = xmlFile:getValue(fillLevelKey .. "#fillLevel")
        if spotIndex ~= nil and fillLevel ~= nil then
            local spot = self.unloadingSpots[spotIndex]
            if spot ~= nil then
                spot.fillLevel = math.clamp(fillLevel, 0, spot.capacity)
                self:updateUnloadingSpot(spot)
            end
        end
    end)
end
function FeedingRobot:saveToXMLFile(xmlFile, key, _)
    local index = 0
    for spotIndex, spot in pairs(self.unloadingSpots) do
        local spotKey = string.format("%s.unloadingSpot(%d)", key, index)
        xmlFile:setValue(spotKey .. "#index", spotIndex)
        xmlFile:setValue(spotKey .. "#fillLevel", spot.fillLevel)
        index = index + 1
    end
end
function FeedingRobot:setOwnerFarmId(ownerFarmId, noEventSend)
    FeedingRobot:superClass().setOwnerFarmId(self, ownerFarmId, noEventSend)
    for _, animatedObject in ipairs(self.animatedObjects) do
        animatedObject:setOwnerFarmId(ownerFarmId, true)
    end
end
function FeedingRobot:addSpline(node, direction, isFeeding, stopAtEnd)
    local length = getSplineLength(node)
    table.insert(self.spline.nodes, {
        ["node"] = node,
        ["direction"] = direction,
        ["length"] = length,
        ["startTime"] = 0,
        ["endTime"] = 0,
        ["isFeeding"] = isFeeding,
        ["stopAtEnd"] = stopAtEnd
    })
    self.spline.length = self.spline.length + length
    if isFeeding then
        self.spline.feedingLength = self.spline.feedingLength + length
    end
end
function FeedingRobot:finishSplines()
    self:updateSplineTimes()
    self.finishedSplines = true
    self:setSplineTime(0)
end
function FeedingRobot:addSplineWaitingPoint(fakeLength)
    table.insert(self.spline.nodes, {
        ["node"] = nil,
        ["length"] = fakeLength,
        ["startTime"] = 0,
        ["endTime"] = 0,
        ["isFeeding"] = false
    })
end
function FeedingRobot:updateSplineTimes()
    local startTime = 0
    for _, splineNode in ipairs(self.spline.nodes) do
        splineNode.startTime = math.max(startTime, 0)
        splineNode.endTime = math.min(startTime + splineNode.length / self.spline.length, 1)
        startTime = splineNode.endTime
    end
end
function FeedingRobot:update(dt)
    if self.isLoadingFinished then
        local state = self.stateMachine[self.stateIndex]
        if self.isServer then
            if state:isDone() then
                self:setState(self.stateTransitions[self.stateIndex])
                state = self.stateMachine[self.stateIndex]
                self:raiseActive()
            elseif state:raiseActive() then
                self:raiseActive()
            end
        end
        state:update(dt)
        if not self.isServer and (self.isClient and self:getIsDriving()) then
            self.spline.timeInterpolator:update(dt)
            local nextStateIndex = self.spline.timeInterpolator:getAlpha()
            local splineTime = self.spline.interpolator:getInterpolatedValue(nextStateIndex)
            self:setSplineTime((SplineUtil.getValidSplineTime(splineTime)))
            if self.spline.timeInterpolator:isInterpolating() then
                self:raiseActive()
            end
        end
        local nextStateIndex = self.robot.door
        local splineTime = not nextStateIndex.isOpen and -1 or 1
        if nextStateIndex.maxY ~= nil then
            local validSplineTime, y, _ = getTranslation(nextStateIndex.node)
            local y = math.clamp(y + splineTime * dt * nextStateIndex.speed, 0, nextStateIndex.maxY)
            setTranslation(nextStateIndex.node, 0, y, 0)
        end
        if nextStateIndex.maxRotZ ~= nil then
            local validSplineTime, y, _ = getRotation(nextStateIndex.node)
            setRotation(nextStateIndex.node, 0, 0, (math.clamp(_ + splineTime * dt * nextStateIndex.speed, 0, nextStateIndex.maxRotZ)))
        end
    else
        self:raiseActive()
    end
end
function FeedingRobot:start()
    if self.isServer and self.stateIndex == self.state.PAUSED then
        for node, _ in pairs(self.nodesInPlayerTrigger) do
            if not entityExists(node) then
                self.nodesInPlayerTrigger[node] = nil
            end
        end
        if next(self.nodesInPlayerTrigger) == nil then
            self.requestedStart = true
            self:raiseActive()
        end
    end
end
function FeedingRobot:getIsDriving()
    return self.stateIndex ~= self.state.PAUSED and self.stateIndex ~= self.state.LOADING and self.stateIndex ~= self.state.RESET
end
function FeedingRobot:addStateChangedListener(func)
    table.addElement(self.stateChangedListeners, func)
end
function FeedingRobot:resetRobot()
    self:setSplineTime(0)
    self.spline.interpolator:setValue(0)
    self.spline.timeInterpolator:reset()
end
function FeedingRobot:addSplineDelta(delta)
    self:setSplineTime(self.spline.time + delta / self.spline.length)
end
function FeedingRobot:setSplineTime(splineTime)
    if self.robot == nil then
        return
    end
    local spline = self.spline
    local dischargeEffectActive = math.clamp(splineTime, 0, 1)
    spline.time = dischargeEffectActive
    local dischargeEffectActive = false
    local feedingLength = 0
    for _, splineNode in ipairs(spline.nodes) do
        if self.isServer and (spline.time < splineNode.endTime and (splineNode.endTime < dischargeEffectActive and splineNode.stopAtEnd)) then
            dischargeEffectActive = splineNode.endTime
            self.reachedStopPoint = true
        end
        if splineNode.startTime <= dischargeEffectActive and dischargeEffectActive <= splineNode.endTime then
            local node = splineNode.node
            if node ~= nil then
                local robotNode = self.robot.node
                local x, y, z = getSplinePosition(node, (dischargeEffectActive - splineNode.startTime) / (splineNode.endTime - splineNode.startTime))
                local dirX, dirY, dirZ = getSplineDirection(node, rangeTime)
                local dirX, dirY, dirZ = worldDirectionToLocal(getParent(robotNode), dirX, dirY, dirZ)
                setWorldTranslation(robotNode, x, y, z)
                setDirection(robotNode, dirX * splineNode.direction, dirY, dirZ * splineNode.direction, 0, 1, 0)
            end
            if splineNode.isFeeding then
                dischargeEffectActive = true
            end
            break
        end
        if splineNode.isFeeding then
        end
    end
    local feedingFactor = 0
    if self.spline.feedingLength > 0 then
        feedingFactor = feedingLength / self.spline.feedingLength
    end
    self.spline.feedingFactor = feedingFactor
    if dischargeEffectActive then
        if not g_soundManager:getIsSamplePlaying(self.robot.samples.discharging) then
            g_soundManager:playSample(self.robot.samples.discharging)
        end
        if not self.robot.dischargeEffectsActive then
            g_effectManager:setEffectTypeInfo(self.robot.dischargeEffects, self.robot.recipe.fillType)
            g_effectManager:startEffects(self.robot.dischargeEffects)
            self.robot.dischargeEffectsActive = true
        end
    else
        if g_soundManager:getIsSamplePlaying(self.robot.samples.discharging) then
            g_soundManager:stopSample(self.robot.samples.discharging)
        end
        if self.robot.dischargeEffectsActive then
            g_effectManager:stopEffects(self.robot.dischargeEffects)
            self.robot.dischargeEffectsActive = false
        end
    end
    self.robot.door.isOpen = dischargeEffectActive
    if self.isServer then
        if 0.02 / self.spline.length < math.abs(self.spline.time - self.spline.timeSent) then
            self.spline.timeSent = self.spline.time
            self:raiseDirtyFlags(self.spline.dirtyFlag)
        end
    end
end
function FeedingRobot:getFeedingFactor()
    return self.spline.feedingFactor
end
function FeedingRobot:setState(newState)
    if newState ~= self.stateIndex then
        if self.isServer then
            g_server:broadcastEvent(FeedingRobotStateEvent.new(self, newState), false)
        end
        self.stateIndex = newState
        self.stateMachine[self.stateIndex]:deactivate()
        self.stateMachine[newState]:activate()
        for _, func in ipairs(self.stateChangedListeners) do
            func(self, newState)
        end
    end
end
function FeedingRobot:getState()
    return self.stateIndex
end
function FeedingRobot:setIsDriving(isDriving)
    if self.isClient then
        if isDriving then
            if not g_soundManager:getIsSamplePlaying(self.robot.samples.driving) then
                g_soundManager:playSample(self.robot.samples.driving)
                return
            end
        elseif g_soundManager:getIsSamplePlaying(self.robot.samples.driving) then
            g_soundManager:stopSamples(self.robot.samples)
        end
    end
end
function FeedingRobot:setMixingAnimationActive(isActive)
    if isActive then
        g_animationManager:startAnimations(self.robot.mixerAnimationNodes)
    else
        g_animationManager:stopAnimations(self.robot.mixerAnimationNodes)
    end
end
function FeedingRobot:setUnloadingSpotActive(spotIndex, isActive)
    local spot = self.unloadingSpots[spotIndex]
    if spot ~= nil then
        if isActive then
            if not g_soundManager:getIsSamplePlaying(spot.samples.discharging) then
                g_soundManager:playSample(spot.samples.discharging)
            end
            g_effectManager:startEffects(spot.dischargeEffects)
            g_animationManager:startAnimations(spot.dischargeAnimationNodes)
            return
        end
        if g_soundManager:getIsSamplePlaying(spot.samples.discharging) then
            g_soundManager:stopSample(spot.samples.discharging)
        end
        g_effectManager:stopEffects(spot.dischargeEffects)
        g_animationManager:stopAnimations(spot.dischargeAnimationNodes)
    end
end
function FeedingRobot:setFillScale(scale)
    local fillPlane = self.robot.fillPlane
    if fillPlane ~= nil and fillPlane.node ~= nil then
        local targetLevel = scale * fillPlane.capacity
        local delta = targetLevel - fillPlane.fillLevel
        if math.abs(delta) > 1 then
            fillPlane.fillLevel = targetLevel
            local node = fillPlane.node
            local x, y, z = localToWorld(node, 0, 0, 0)
            local d1x, d1y, d1z = localDirectionToWorld(node, 0.5, 0, 0)
            local d2x, d2y, d2z = localDirectionToWorld(node, 0, 0, 0.5)
            fillPlaneAdd(node, delta, x, y, z, d1x, d1y, d1z, d2x, d2y, d2z)
        end
        local node = setVisibility
        local x = fillPlane.node
        local y = scale > 0
        node(x, y)
    end
end
function FeedingRobot:onRobotTrigger(_, otherId, onEnter, onLeave, _)
    if onEnter then
        if not I3DUtil.getIsLinkedToNode(self.robot.node, otherId) then
            self.robot.objectsInTrigger[otherId] = true
        end
    elseif onLeave then
        self.robot.objectsInTrigger[otherId] = nil
    end
    self.robot.isBlocked = next(self.robot.objectsInTrigger) ~= nil
end
function FeedingRobot:onPlayerTrigger(_, otherId, onEnter, onLeave, _)
    if onEnter then
        self.nodesInPlayerTrigger[otherId] = true
    elseif onLeave then
        self.nodesInPlayerTrigger[otherId] = nil
    end
end
function FeedingRobot:getIsNodeUsed(node)
    for _, spot in ipairs(self.unloadingSpots) do
        for _, unloadTrigger in ipairs(spot.unloadTriggers) do
            if unloadTrigger.exactFillRootNode == node or unloadTrigger.triggerNode == node then
                return true
            end
        end
    end
    return false
end
function FeedingRobot:getFreeCapacity(fillTypeIndex)
    local spot = self.fillTypeToUnloadingSpot[fillTypeIndex]
    return spot == nil and 0 or spot.capacity - spot.fillLevel
end
function FeedingRobot:getIsFillTypeAllowed(fillTypeIndex)
    return self.fillTypeToUnloadingSpot[fillTypeIndex] ~= nil
end
function FeedingRobot:getIsToolTypeAllowed(toolType)
    return true
end
function FeedingRobot:addFillLevelFromTool(_, deltaFillLevel, fillTypeIndex, _, _, _)
    local spot = self.fillTypeToUnloadingSpot[fillTypeIndex]
    if spot == nil then
        return 0
    end
    if spot.fillLevel >= spot.capacity then
        return 0
    end
    deltaFillLevel = math.min(spot.capacity - spot.fillLevel, deltaFillLevel)
    if self.isServer then
        self:raiseDirtyFlags(self.dirtyFlagFillLevel)
    end
    spot.fillLevel = spot.fillLevel + deltaFillLevel
    self:updateUnloadingSpot(spot)
    return deltaFillLevel
end
function FeedingRobot:removeFillLevel(deltaFillLevel, fillTypeIndex)
    local spot = self.fillTypeToUnloadingSpot[fillTypeIndex]
    local absDelta = math.abs(deltaFillLevel)
    if spot ~= nil then
        local spotDelta = math.min(absDelta, spot.fillLevel)
        spot.fillLevel = spot.fillLevel - spotDelta
        absDelta = absDelta - spotDelta
        if self.isServer then
            self:raiseDirtyFlags(self.dirtyFlagFillLevel)
        end
        self:updateUnloadingSpot(spot)
    end
    return math.abs(deltaFillLevel) - absDelta
end
function FeedingRobot:getFillLevel(fillTypeIndex)
    local fillLevel = 0
    local spot = self.fillTypeToUnloadingSpot[fillTypeIndex]
    if spot ~= nil then
    end
    return fillLevel
end
function FeedingRobot.updateUnloadingSpot(_, spot)
    if spot.fillPlane == nil then
        if spot.fillVolume ~= nil then
            local newFillLevel = spot.fillLevel
            local delta = newFillLevel - spot.fillVolume.fillLevel
            local node = spot.fillVolume.node
            if math.abs(delta) > 10 then
                spot.fillVolume.fillLevel = newFillLevel
                local x, y, z = localToWorld(node, 0, 0, 0)
                local d1x, d1y, d1z = localDirectionToWorld(node, 0.5, 0, 0)
                local d2x, d2y, d2z = localDirectionToWorld(node, 0, 0, 0.5)
                fillPlaneAdd(node, delta, x, y, z, d1x, d1y, d1z, d2x, d2y, d2z)
            end
            local x = setVisibility
            local z = newFillLevel > 0
            x(node, z)
        end
    else
        spot.fillPlane:setState(spot.fillLevel / spot.capacity)
    end
end
function FeedingRobot:createFoodMixture(liters)
    if self.isServer then
        local recipe = self.robot.recipe
        local maxLiters = math.min(liters, self.owner:getFreeFoodCapacity(recipe.fillType))
        for _, ingredient in pairs(recipe.ingredients) do
            local fillLevel = 0
            for _, fillType in ipairs(ingredient.fillTypes) do
                fillLevel = fillLevel + self:getFillLevel(fillType)
            end
            maxLiters = math.min(maxLiters, fillLevel / ingredient.ratio)
            if maxLiters <= 0 then
                return
            end
        end
        for _, ingredient in pairs(recipe.ingredients) do
            local fillLevel = maxLiters * ingredient.ratio
            for _, fillType in ipairs(ingredient.fillTypes) do
                fillLevel = fillLevel - self:removeFillLevel(fillLevel, fillType)
                if fillLevel <= 0 then
                    break
                end
            end
        end
        self.owner:addFood(self:getOwnerFarmId(), maxLiters, recipe.fillType, nil, nil, nil)
        self:start()
    end
end
function FeedingRobot:updateInfo(infoTable)
    if self.infos ~= nil then
        for _, info in ipairs(self.infos) do
            local fillLevel = 0
            for _, fillType in ipairs(info.fillTypes) do
                fillLevel = fillLevel + self:getFillLevel(fillType)
            end
            info.text = string.format("%d l", fillLevel)
            table.insert(infoTable, info)
        end
    end
end