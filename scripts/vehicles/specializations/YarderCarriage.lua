YarderCarriage = {}
YarderCarriage.TREE_RAYCAST_DISTANCE = 5
YarderCarriage.ROPE_MAX_LIMIT_OFFSET = 2.5
source("dataS/scripts/vehicles/specializations/events/TreeAttachEvent.lua")
source("dataS/scripts/vehicles/specializations/events/TreeAttachRequestEvent.lua")
source("dataS/scripts/vehicles/specializations/events/TreeAttachResponseEvent.lua")
source("dataS/scripts/vehicles/specializations/events/TreeDetachEvent.lua")
function YarderCarriage.prerequisitesPresent(specializations)
    return true
end
function YarderCarriage.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("YarderCarriage")
    schema:register(XMLValueType.INT, "vehicle.yarderCarriage#maxNumTrees", "Max. number of trees that can be attached", 4)
    schema:register(XMLValueType.FLOAT, "vehicle.yarderCarriage#maxTreeMass", "Max. total tree mass that can be attached (to)", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.yarderCarriage#length", "Total length off carriage to calculate the offset to start and end correctly", 2)
    schema:register(XMLValueType.FLOAT, "vehicle.yarderCarriage#rollSpacing", "Spacing between the rolls to calculate the rotation correctly", 0.75)
    schema:register(XMLValueType.FLOAT, "vehicle.yarderCarriage#liftSpeed", "Lifting speed [m/sec]", 2)
    schema:register(XMLValueType.FLOAT, "vehicle.yarderCarriage#liftAcceleration", "Lifting acceleration (time in seconds until full speed is reached)", 0.75)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage#pullRopeTargetNode", "Target connection node for pull rope")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage#pushRopeTargetNode", "Target connection node for push rope")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage.ropeAlignmentNode(?)#node", "Node is aligned to the rope in x and y axis")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage.joint#node", "Attach joint node")
    schema:register(XMLValueType.TIME, "vehicle.yarderCarriage.joint#attachTime", "Time until the tree is fully attached", 0.5)
    schema:register(XMLValueType.FLOAT, "vehicle.yarderCarriage.joint#minDistance", "Min. distance of the rope", 0.5)
    schema:register(XMLValueType.FLOAT, "vehicle.yarderCarriage.joint#maxDistance", "Max. distance of the rope", 10)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage.rope#originNode", "Rope origin node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage.rope#rootHook", "Root hook node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage.rope#rootHookReferenceNode", "Root hook reference node placed at the end of the hook")
    schema:register(XMLValueType.FLOAT, "vehicle.yarderCarriage.rope#treeRopeLength", "Length of the rope from the root hook to the tree", 1)
    ForestryRope.registerXMLPaths(schema, "vehicle.yarderCarriage.rope.mainRope")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage.rope.attach#mainNode", "Outgoing node for main tree attach rope (used for dummy rope display)")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage.rope.attach#additionalNode", "Outgoing node for additional tree attach rope (used for dummy rope display)")
    ForestryRope.registerXMLPaths(schema, "vehicle.yarderCarriage.rope.attach.mainRope")
    ForestryRope.registerXMLPaths(schema, "vehicle.yarderCarriage.rope.attach.additionalRope")
    TargetTreeMarker.registerXMLPaths(schema, "vehicle.yarderCarriage.rope.attach.marker")
    schema:register(XMLValueType.INT, "vehicle.yarderCarriage.rope.componentJoint#index", "Component joint index")
    schema:register(XMLValueType.VECTOR_ROT, "vehicle.yarderCarriage.rope.componentJoint#rotLimitInactive", "Component joint rot limit while tree(s) not attached")
    schema:register(XMLValueType.VECTOR_ROT, "vehicle.yarderCarriage.rope.componentJoint#rotLimitActive", "Component joint rot limit while tree(s) attached")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage.additionalRopes.additionalRope(?)#referenceNode", "Node at the end of the hook for placement of the rope")
    ForestryRope.registerXMLPaths(schema, "vehicle.yarderCarriage.additionalRopes.additionalRope(?).rope")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.yarderCarriage.additionalRopes.additionalRope(?).hookNode(?)#node", "Node to align to target point")
    schema:register(XMLValueType.BOOL, "vehicle.yarderCarriage.additionalRopes.additionalRope(?).hookNode(?)#alignYRot", "Node is only aligned on y axis", false)
    schema:register(XMLValueType.BOOL, "vehicle.yarderCarriage.additionalRopes.additionalRope(?).hookNode(?)#alignXRot", "Node is only aligned on x axis", false)
    schema:register(XMLValueType.ANGLE, "vehicle.yarderCarriage.additionalRopes.additionalRope(?).hookNode(?)#minRot", "Min. rotation value for only y or x alignment", -180)
    schema:register(XMLValueType.ANGLE, "vehicle.yarderCarriage.additionalRopes.additionalRope(?).hookNode(?)#maxRot", "Max. rotation value for only y or x alignment", 180)
    schema:register(XMLValueType.BOOL, "vehicle.yarderCarriage.additionalRopes.additionalRope(?).hookNode(?)#alignToTarget", "Node is only aligned on all axis", true)
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.yarderCarriage.rope")
    schema:register(XMLValueType.FLOAT, "vehicle.yarderCarriage.treeHook#offset", "Hook offset from tree", 0.01)
    schema:register(XMLValueType.STRING, "vehicle.yarderCarriage.treeHook#tensionBeltType", "Name of tension belt type used for tree hook", "forestryTreeBelt")
    ForestryHook.registerXMLPaths(schema, "vehicle.yarderCarriage.treeHook")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderCarriage.sounds", "attachTree")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderCarriage.sounds", "detachTree")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderCarriage.sounds", "lift")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderCarriage.sounds", "lower")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderCarriage.sounds", "liftLimit")
    schema:setXMLSpecializationType()
end
function YarderCarriage.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getCarriageDimensions", YarderCarriage.getCarriageDimensions)
    SpecializationUtil.registerFunction(vehicleType, "getCarriagePullRopeTargetNode", YarderCarriage.getCarriagePullRopeTargetNode)
    SpecializationUtil.registerFunction(vehicleType, "getCarriagePushRopeTargetNode", YarderCarriage.getCarriagePushRopeTargetNode)
    SpecializationUtil.registerFunction(vehicleType, "setYarderTowerVehicle", YarderCarriage.setYarderTowerVehicle)
    SpecializationUtil.registerFunction(vehicleType, "updateRopeAlignmentNodes", YarderCarriage.updateRopeAlignmentNodes)
    SpecializationUtil.registerFunction(vehicleType, "updateCarriageInRange", YarderCarriage.updateCarriageInRange)
    SpecializationUtil.registerFunction(vehicleType, "onYarderCarriageUpdateEnd", YarderCarriage.onYarderCarriageUpdateEnd)
    SpecializationUtil.registerFunction(vehicleType, "updateTreeAttachRopes", YarderCarriage.updateTreeAttachRopes)
    SpecializationUtil.registerFunction(vehicleType, "onCarriageTreeRaycastCallback", YarderCarriage.onCarriageTreeRaycastCallback)
    SpecializationUtil.registerFunction(vehicleType, "onAttachTreeAction", YarderCarriage.onAttachTreeAction)
    SpecializationUtil.registerFunction(vehicleType, "attachTreeToCarriage", YarderCarriage.attachTreeToCarriage)
    SpecializationUtil.registerFunction(vehicleType, "createJoint", YarderCarriage.createJoint)
    SpecializationUtil.registerFunction(vehicleType, "onDetachTreeAction", YarderCarriage.onDetachTreeAction)
    SpecializationUtil.registerFunction(vehicleType, "detachTreeFromCarriage", YarderCarriage.detachTreeFromCarriage)
    SpecializationUtil.registerFunction(vehicleType, "getNumAttachedTrees", YarderCarriage.getNumAttachedTrees)
    SpecializationUtil.registerFunction(vehicleType, "getMaxNumAttachedTrees", YarderCarriage.getMaxNumAttachedTrees)
    SpecializationUtil.registerFunction(vehicleType, "getAttachedTreeMass", YarderCarriage.getAttachedTreeMass)
    SpecializationUtil.registerFunction(vehicleType, "getIsCarriageTreeAttachAllowed", YarderCarriage.getIsCarriageTreeAttachAllowed)
    SpecializationUtil.registerFunction(vehicleType, "getIsTreeInMountRange", YarderCarriage.getIsTreeInMountRange)
    SpecializationUtil.registerFunction(vehicleType, "showCarriageTreeMountFailedWarning", YarderCarriage.showCarriageTreeMountFailedWarning)
    SpecializationUtil.registerFunction(vehicleType, "setCarriageLiftInput", YarderCarriage.setCarriageLiftInput)
    SpecializationUtil.registerFunction(vehicleType, "saveAttachedTreesToXML", YarderCarriage.saveAttachedTreesToXML)
    SpecializationUtil.registerFunction(vehicleType, "resolveLoadedAttachedTrees", YarderCarriage.resolveLoadedAttachedTrees)
    SpecializationUtil.registerFunction(vehicleType, "onYarderCarriageTreeShapeCut", YarderCarriage.onYarderCarriageTreeShapeCut)
    SpecializationUtil.registerFunction(vehicleType, "onYarderCarriageTreeShapeMounted", YarderCarriage.onYarderCarriageTreeShapeMounted)
end
function YarderCarriage.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", YarderCarriage.getDirtMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", YarderCarriage.getWearMultiplier)
end
function YarderCarriage.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", YarderCarriage)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", YarderCarriage)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", YarderCarriage)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", YarderCarriage)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", YarderCarriage)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", YarderCarriage)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", YarderCarriage)
    SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", YarderCarriage)
end
function YarderCarriage:onLoad(_)
    local spec = self.spec_yarderCarriage
    spec.maxNumTrees = self.xmlFile:getValue("vehicle.yarderCarriage#maxNumTrees", 4)
    spec.maxTreeBits = math.ceil((math.sqrt(spec.maxNumTrees)))
    spec.maxTreeMass = self.xmlFile:getValue("vehicle.yarderCarriage#maxTreeMass", 1)
    spec.length = self.xmlFile:getValue("vehicle.yarderCarriage#length", 2)
    spec.rollSpacing = self.xmlFile:getValue("vehicle.yarderCarriage#rollSpacing", 0.75)
    spec.liftSpeed = self.xmlFile:getValue("vehicle.yarderCarriage#liftSpeed", 2) * 0.001
    spec.liftAcceleration = 1 / self.xmlFile:getValue("vehicle.yarderCarriage#liftAcceleration", 0.75) * 0.001
    spec.curLiftSpeedAlpha = 0
    spec.curLiftSpeedLastDirection = 0
    spec.pullRopeTargetNode = self.xmlFile:getValue("vehicle.yarderCarriage#pullRopeTargetNode", nil, self.components, self.i3dMappings)
    spec.pushRopeTargetNode = self.xmlFile:getValue("vehicle.yarderCarriage#pushRopeTargetNode", nil, self.components, self.i3dMappings)
    spec.ropeAlignmentNodes = {}
    self.xmlFile:iterate("vehicle.yarderCarriage.ropeAlignmentNode", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local entry = {
            ["node"] = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        }
        if entry.node ~= nil then
            table.insert(spec.ropeAlignmentNodes, entry)
        end
    end)
    spec.joint = {}
    spec.joint.node = self.xmlFile:getValue("vehicle.yarderCarriage.joint#node", nil, self.components, self.i3dMappings)
    spec.joint.attachTime = self.xmlFile:getValue("vehicle.yarderCarriage.joint#attachTime", 0.5)
    spec.joint.minDistance = self.xmlFile:getValue("vehicle.yarderCarriage.joint#minDistance", 0.5)
    spec.joint.maxDistance = self.xmlFile:getValue("vehicle.yarderCarriage.joint#maxDistance", 20)
    spec.joint.component = self:getParentComponent(spec.joint.node)
    spec.rope = {}
    spec.rope.originNode = self.xmlFile:getValue("vehicle.yarderCarriage.rope#originNode", nil, self.components, self.i3dMappings)
    spec.rope.rootHook = self.xmlFile:getValue("vehicle.yarderCarriage.rope#rootHook", nil, self.components, self.i3dMappings)
    spec.rope.rootHookReferenceNode = self.xmlFile:getValue("vehicle.yarderCarriage.rope#rootHookReferenceNode", nil, self.components, self.i3dMappings)
    spec.rope.treeRopeLength = self.xmlFile:getValue("vehicle.yarderCarriage.rope#treeRopeLength", 1)
    spec.rope.rootHookLength = 1
    if spec.rope.rootHook ~= nil and spec.rope.rootHookReferenceNode ~= nil then
        spec.rope.rootHookLength = calcDistanceFrom(spec.rope.rootHook, spec.rope.rootHookReferenceNode)
    end
    spec.rope.mainRope = ForestryRope.new(self, spec.rope.rootHook)
    spec.rope.mainRope:loadFromXML(self.xmlFile, "vehicle.yarderCarriage.rope.mainRope", self.baseDirectory)
    spec.rope.attachMainNode = self.xmlFile:getValue("vehicle.yarderCarriage.rope.attach#mainNode", nil, self.components, self.i3dMappings)
    spec.rope.attachMainRope = ForestryRope.new(self, spec.rope.attachMainNode)
    spec.rope.attachMainRope:loadFromXML(self.xmlFile, "vehicle.yarderCarriage.rope.attach.mainRope", self.baseDirectory)
    spec.rope.attachMainRope:setVisibility(false)
    spec.rope.attachAdditionalNode = self.xmlFile:getValue("vehicle.yarderCarriage.rope.attach#additionalNode", nil, self.components, self.i3dMappings)
    spec.rope.attachAdditionalRope = ForestryRope.new(self, spec.rope.attachAdditionalNode)
    spec.rope.attachAdditionalRope:loadFromXML(self.xmlFile, "vehicle.yarderCarriage.rope.attach.additionalRope", self.baseDirectory)
    spec.rope.attachAdditionalRope:setVisibility(false)
    spec.rope.attachMarker = TargetTreeMarker.new(self, self.rootNode)
    spec.rope.attachMarker:loadFromXML(self.xmlFile, "vehicle.yarderCarriage.rope.attach.marker")
    spec.rope.componentJointIndex = self.xmlFile:getValue("vehicle.yarderCarriage.rope.componentJoint#index")
    spec.rope.componentJointLimitInactive = self.xmlFile:getValue("vehicle.yarderCarriage.rope.componentJoint#rotLimitInactive", "0 0 0", true)
    spec.rope.componentJointLimitActive = self.xmlFile:getValue("vehicle.yarderCarriage.rope.componentJoint#rotLimitActive", nil, true)
    spec.rope.changeObjects = {}
    ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, "vehicle.yarderCarriage.rope", spec.rope.changeObjects, self.components, self)
    ObjectChangeUtil.setObjectChanges(spec.rope.changeObjects, false, self, self.setMovingToolDirty)
    spec.additionalRopes = {}
    self.xmlFile:iterate("vehicle.yarderCarriage.additionalRopes.additionalRope", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local entry = {
            ["referenceNode"] = self.xmlFile:getValue(key .. "#referenceNode", nil, self.components, self.i3dMappings)
        }
        entry.rope = ForestryRope.new(self, entry.referenceNode)
        entry.rope:loadFromXML(self.xmlFile, key .. ".rope", self.baseDirectory)
        entry.hookNodes = {}
        self.xmlFile:iterate(key .. ".hookNode", function(_, hookKey)
            -- upvalues: (ref) self, (copy) entry
            local hookNode = {
                ["node"] = self.xmlFile:getValue(hookKey .. "#node", nil, self.components, self.i3dMappings),
                ["alignYRot"] = self.xmlFile:getValue(hookKey .. "#alignYRot", false),
                ["alignXRot"] = self.xmlFile:getValue(hookKey .. "#alignXRot", false),
                ["minRot"] = self.xmlFile:getValue(hookKey .. "#minRot", -180),
                ["maxRot"] = self.xmlFile:getValue(hookKey .. "#maxRot", 180),
                ["alignToTarget"] = self.xmlFile:getValue(hookKey .. "#alignToTarget", true),
                ["referenceFrame"] = createTransformGroup("hookNodeReferenceFrame")
            }
            link(getParent(hookNode.node), hookNode.referenceFrame)
            setTranslation(hookNode.referenceFrame, getTranslation(hookNode.node))
            setRotation(hookNode.referenceFrame, getRotation(hookNode.node))
            setVisibility(hookNode.node, false)
            table.insert(entry.hookNodes, hookNode)
        end)
        setVisibility(entry.referenceNode, false)
        table.insert(spec.additionalRopes, entry)
    end)
    spec.treeHook = {}
    spec.treeHook.offset = self.xmlFile:getValue("vehicle.yarderCarriage.treeHook#offset", 0.01)
    spec.treeHook.tensionBeltType = self.xmlFile:getValue("vehicle.yarderCarriage.treeHook#tensionBeltType", "forestryTreeBelt")
    spec.treeHook.beltData = g_tensionBeltManager:getBeltData(spec.treeHook.tensionBeltType)
    spec.treeHook.hookData = ForestryHook.new(self, self.rootNode)
    spec.treeHook.hookData:loadFromXML(self.xmlFile, "vehicle.yarderCarriage.treeHook", self.baseDirectory)
    spec.treeHook.hookData:setVisibility(false)
    spec.yarderTowerVehicle = nil
    spec.treeRaycast = {}
    spec.treeRaycast.hasStarted = false
    spec.treeRaycast.foundTree = false
    spec.treeRaycast.treeTargetPos = { 0, 0, 0 }
    spec.treeRaycast.treeCenterPos = { 0, 0, 0 }
    spec.treeRaycast.treeUp = { 0, 1, 0 }
    spec.treeRaycast.treeRadius = 1
    spec.attachedTrees = {}
    spec.splitShapesToAttach = {}
    spec.lastTransLimitY = 0
    spec.lastTransLimitYTimeOffset = 0
    spec.sampleLiftPlayedSent = false
    spec.sampleLiftLimitPlayedSent = false
    spec.sampleLowerPlayedSent = false
    spec.samples = {}
    if self.isClient then
        spec.samples.attachTree = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderCarriage.sounds", "attachTree", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.detachTree = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderCarriage.sounds", "detachTree", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.lift = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderCarriage.sounds", "lift", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.lower = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderCarriage.sounds", "lower", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.liftLimit = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderCarriage.sounds", "liftLimit", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    spec.texts = {}
    spec.texts.warningTooHeavy = g_i18n:getText("yarder_treeToHeavy")
    self.isVehicleSaved = false
    spec.dirtyFlag = self:getNextDirtyFlag()
    g_messageCenter:subscribe(MessageType.TREE_SHAPE_CUT, self.onYarderCarriageTreeShapeCut, self)
    g_messageCenter:subscribe(MessageType.TREE_SHAPE_MOUNTED, self.onYarderCarriageTreeShapeMounted, self)
end
function YarderCarriage:onLoadFinished(_)
    local spec = self.spec_yarderCarriage
    spec.rope.mainRope:setTargetNode(spec.rope.originNode)
    spec.rope.treeRope = spec.rope.mainRope:clone(spec.rope.rootHookReferenceNode)
    spec.rope.treeRope:setLength(spec.rope.treeRopeLength)
end
function YarderCarriage:onDelete()
    local spec = self.spec_yarderCarriage
    if spec.yarderTowerVehicle ~= nil then
        spec.yarderTowerVehicle.spec_yarderTower.carriage.vehicle = nil
    end
    if #spec.attachedTrees > 0 then
        self:detachTreeFromCarriage(nil, true)
    end
    if self.isClient then
        g_soundManager:deleteSamples(spec.samples)
    end
    if spec.treeHook.hookData ~= nil then
        spec.treeHook.hookData:delete()
    end
    if spec.rope.attachMarker ~= nil then
        spec.rope.attachMarker:delete()
    end
    if spec.rope.mainRope ~= nil then
        spec.rope.mainRope:delete()
    end
    if spec.rope.treeRope ~= nil then
        spec.rope.treeRope:delete()
    end
    if spec.rope.attachMainRope ~= nil then
        spec.rope.attachMainRope:delete()
    end
    if spec.rope.attachAdditionalRope ~= nil then
        spec.rope.attachAdditionalRope:delete()
    end
    if spec.additionalRopes ~= nil then
        local i = 1
        for i = i, #spec.additionalRopes do
            local additionalRope = spec.additionalRopes[i]
            if additionalRope.rope ~= nil then
                additionalRope.rope:delete()
            end
        end
    end
end
function YarderCarriage:onReadStream(streamId, _)
    local spec = self.spec_yarderCarriage
    if streamReadBool(streamId) then
        spec.yarderTowerVehicle = NetworkUtil.readNodeObject(streamId)
        spec.yarderTowerVehicle.spec_yarderTower.carriage.vehicle = self
    end
    local numTrees = streamReadUIntN(streamId, spec.maxTreeBits)
    for i = 1, numTrees do
        local splitShapeId = streamReadFloat32(streamId)
        local splitShapeId = streamReadFloat32(streamId)
        local z = streamReadFloat32(streamId)
        local splitShapeId, splitShapeId1, splitShapeId2 = readSplitShapeIdFromStream(streamId)
        if splitShapeId == 0 then
            if splitShapeId1 ~= 0 then
                table.insert(spec.splitShapesToAttach, {
                    ["splitShapeId1"] = splitShapeId1,
                    ["splitShapeId2"] = splitShapeId2,
                    ["x"] = splitShapeId,
                    ["y"] = splitShapeId,
                    ["z"] = z
                })
            end
        else
            local x, y, z = localToWorld(splitShapeId, splitShapeId, splitShapeId, z)
            self:attachTreeToCarriage(splitShapeId, x, y, z, nil, true)
        end
    end
end
function YarderCarriage:onWriteStream(streamId, _)
    local spec = self.spec_yarderCarriage
    local i = spec.yarderTowerVehicle ~= nil
    streamWriteBool(streamId, i)
    if spec.yarderTowerVehicle ~= nil then
        NetworkUtil.writeNodeObject(streamId, spec.yarderTowerVehicle)
    end
    streamWriteUIntN(streamId, #spec.attachedTrees, spec.maxTreeBits)
    local i = 1
    for i = i, #spec.attachedTrees do
        local treeData = spec.attachedTrees[i]
        local x, y, z = worldToLocal(treeData.treeId, getWorldTranslation(treeData.hookData.hookId))
        streamWriteFloat32(streamId, x)
        streamWriteFloat32(streamId, y)
        streamWriteFloat32(streamId, z)
        writeSplitShapeIdToStream(streamId, treeData.treeId)
    end
end
function YarderCarriage:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() and streamReadBool(streamId) then
        local spec = self.spec_yarderCarriage
        if streamReadBool(streamId) and not g_soundManager:getIsSamplePlaying(spec.samples.lift) then
            g_soundManager:playSample(spec.samples.lift)
            g_soundManager:stopSample(spec.samples.lower)
            spec.lastTransLimitYTimeOffset = 250
        end
        if streamReadBool(streamId) then
            g_soundManager:playSample(spec.samples.liftLimit)
        end
        if streamReadBool(streamId) and not g_soundManager:getIsSamplePlaying(spec.samples.lower) then
            g_soundManager:playSample(spec.samples.lower)
            g_soundManager:stopSample(spec.samples.lift)
            spec.lastTransLimitYTimeOffset = 250
        end
    end
end
function YarderCarriage:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.spec_yarderCarriage.dirtyFlag) ~= 0) then
            streamWriteBool(streamId, spec.sampleLiftPlayedSent)
            streamWriteBool(streamId, spec.sampleLiftLimitPlayedSent)
            streamWriteBool(streamId, spec.sampleLowerPlayedSent)
            spec.sampleLiftPlayedSent = false
            spec.sampleLiftLimitPlayedSent = false
            spec.sampleLowerPlayedSent = false
        end
    end
end
function YarderCarriage:onPostUpdate(dt, _, _, _)
    local spec = self.spec_yarderCarriage
    if self.isServer then
        local i = 1
        for i = i, #spec.attachedTrees do
            local treeData = spec.attachedTrees[i]
            if treeData.limitDirty then
                treeData.limitValue = math.max(treeData.limitValue - treeData.speedScale * g_currentDt, 0)
                setJointTranslationLimit(treeData.jointIndex, 0, true, -treeData.limitValue, treeData.limitValue)
                setJointTranslationLimit(treeData.jointIndex, 1, true, -treeData.transLimitY, treeData.limitValue)
                setJointTranslationLimit(treeData.jointIndex, 2, true, -treeData.limitValue, treeData.limitValue)
                if treeData.limitValue == 0 then
                    treeData.limitDirty = false
                end
            else
                if treeData.treeId == nil or not entityExists(treeData.treeId) then
                    self:detachTreeFromCarriage()
                    break
                end
                if calcDistanceFrom(spec.joint.node, treeData.hookData.hookId) > treeData.transLimitY + YarderCarriage.ROPE_MAX_LIMIT_OFFSET then
                    self:detachTreeFromCarriage()
                    break
                end
            end
        end
    else
        local i = #spec.splitShapesToAttach
        for i = i, 1, -1 do
            local treeData = spec.splitShapesToAttach[i]
            local distance = resolveStreamSplitShapeId(treeData.splitShapeId1, treeData.splitShapeId2)
            if distance ~= 0 then
                local x, y, z = localToWorld(distance, treeData.x, treeData.y, treeData.z)
                self:attachTreeToCarriage(distance, x, y, z, nil, true)
                table.remove(spec.splitShapesToAttach, i)
            end
        end
    end
    self:updateTreeAttachRopes(dt)
    if spec.treeRaycast.validTree ~= nil and not entityExists(spec.treeRaycast.validTree) then
        spec.treeRaycast.validTree = nil
    end
    if spec.treeRaycast.validTree ~= spec.treeRaycast.lastValidTree then
        local i = spec.treeRaycast.validTree ~= nil
        spec.rope.attachMarker:setIsActive(i)
        local i = false
        if spec.treeRaycast.validTree ~= nil then
            i = #spec.attachedTrees == 0
        end
        spec.rope.attachMainRope:setVisibility(i)
        local i = false
        if spec.treeRaycast.validTree ~= nil then
            i = #spec.attachedTrees > 0
        end
        spec.rope.attachAdditionalRope:setVisibility(i)
        spec.treeRaycast.lastValidTree = spec.treeRaycast.validTree
    end
    local attachRope = #spec.attachedTrees == 0 and spec.rope.attachMainRope or spec.rope.attachAdditionalRope
    if spec.treeRaycast.validTree ~= nil and attachRope ~= nil then
        attachRope:setTargetPosition(spec.treeRaycast.treeTargetPos[1], spec.treeRaycast.treeTargetPos[2], spec.treeRaycast.treeTargetPos[3])
        spec.rope.attachMarker:setIsActive(true)
        spec.rope.attachMarker:setPosition(spec.treeRaycast.treeCenterPos[1], spec.treeRaycast.treeCenterPos[2], spec.treeRaycast.treeCenterPos[3], spec.treeRaycast.treeUp[1], spec.treeRaycast.treeUp[2], spec.treeRaycast.treeUp[3], spec.treeRaycast.treeRadius)
    end
    if spec.lastTransLimitYTimeOffset > 0 then
        spec.lastTransLimitYTimeOffset = spec.lastTransLimitYTimeOffset - dt
        if spec.lastTransLimitYTimeOffset <= 0 then
            spec.curLiftSpeedAlpha = 0
            spec.curLiftSpeedLastDirection = 0
            g_soundManager:stopSample(spec.samples.lower)
            g_soundManager:stopSample(spec.samples.lift)
        end
    end
    if #spec.attachedTrees > 0 or spec.treeRaycast.validTree ~= nil then
        self:raiseActive()
    end
end
function YarderCarriage:getCarriageDimensions()
    local spec = self.spec_yarderCarriage
    return spec.length, spec.rollSpacing
end
function YarderCarriage:getCarriagePullRopeTargetNode()
    return self.spec_yarderCarriage.pullRopeTargetNode
end
function YarderCarriage:getCarriagePushRopeTargetNode()
    return self.spec_yarderCarriage.pushRopeTargetNode
end
function YarderCarriage:setYarderTowerVehicle(vehicle)
    self.spec_yarderCarriage.yarderTowerVehicle = vehicle
end
function YarderCarriage:updateRopeAlignmentNodes(ropeNode, tx, ty, tz, maxOffset)
    local _, _, z1 = worldToLocal(ropeNode, tx, ty, tz)
    local spec = self.spec_yarderCarriage
    local i = 1
    for i = i, #spec.ropeAlignmentNodes do
        local nodeData = spec.ropeAlignmentNodes[i]
        local _, _, z2 = worldToLocal(ropeNode, getWorldTranslation(nodeData.node))
        local y = math.clamp(z2 / z1, 0, 1) * 3.141592653589793
        local x, y, z = localToWorld(ropeNode, 0, -(math.sin(y) * maxOffset), z2)
        local x, y, _ = worldToLocal(nodeData.node, x, y, z)
        translate(nodeData.node, x, y, 0)
    end
end
function YarderCarriage:updateCarriageInRange()
    if g_localPlayer ~= nil then
        local spec = self.spec_yarderCarriage
        local player = g_localPlayer
        local x1, _, z1 = getWorldTranslation(player.rootNode)
        local x2, _, z2 = getWorldTranslation(spec.rope.originNode)
        if MathUtil.vector2Length(x1 - x2, z1 - z2) < spec.joint.maxDistance then
            if player:getIsHoldingHandTool() then
                spec.treeRaycast.validTree = nil
                return
            end
            if #spec.attachedTrees >= spec.maxNumTrees then
                spec.treeRaycast.validTree = nil
                return
            end
            if not spec.treeRaycast.hasStarted then
                spec.treeRaycast.hasStarted = true
                spec.treeRaycast.foundTree = nil
                local cameraNode = player:getCurrentCameraNode()
                local x, y, z = localToWorld(cameraNode, 0, 0, 1)
                local dx, dy, dz = localDirectionToWorld(cameraNode, 0, 0, -1)
                raycastClosestAsync(x, y, z, dx, dy, dz, YarderCarriage.TREE_RAYCAST_DISTANCE, "onCarriageTreeRaycastCallback", self, CollisionFlag.TREE)
                return
            end
        else
            spec.treeRaycast.validTree = nil
        end
    end
end
function YarderCarriage:onYarderCarriageUpdateEnd()
    local spec = self.spec_yarderCarriage
    spec.treeRaycast.validTree = nil
    spec.treeRaycast.hasStarted = false
    self:raiseActive()
end
function YarderCarriage:updateTreeAttachRopes(_)
    local spec = self.spec_yarderCarriage
    local rootTreeData = spec.attachedTrees[1]
    if rootTreeData ~= nil and entityExists(rootTreeData.treeId) then
        local x1, y1, z1 = getWorldTranslation(spec.rope.originNode)
        local x2, y2, z2 = rootTreeData.hookData:getRopeTargetPosition()
        local distance = MathUtil.vector3Length(x2 - x1, y2 - y1, z2 - z1)
        local dx, dy, dz = MathUtil.vector3Normalize(x2 - x1, y2 - y1, z2 - z1)
        local upX, upY, upZ = localDirectionToWorld(getParent(spec.rope.originNode), 0, 1, 0)
        I3DUtil.setWorldDirection(spec.rope.originNode, dx, dy, dz, upX, upY, upZ)
        local rootHookPosition = distance - spec.rope.treeRopeLength - spec.rope.rootHookLength
        setTranslation(spec.rope.rootHook, 0, 0, rootHookPosition)
        spec.rope.mainRope:setLength(rootHookPosition)
    end
    local z1 = 1
    local x1 = #spec.additionalRopes
    local y1 = 1
    for z1 = z1, x1, y1 do
        local y2 = spec.attachedTrees[z1 + 1]
        if y2 ~= nil and entityExists(y2.treeId) then
            local z2, distance, dx = y2.hookData:getRopeTargetPosition()
            local upX = 1
            for upX = upX, #spec.additionalRopes[z1].hookNodes do
                local upY = x2.hookNodes[upX]
                if upY.alignYRot then
                    local upZ, rootHookPosition, z = worldToLocal(upY.referenceFrame, z2, distance, dx)
                    local angle, z = MathUtil.vector2Normalize(upZ, z)
                    local angle = math.clamp(math.atan2(angle, z), upY.minRot, upY.maxRot)
                    setRotation(upY.node, 0, angle, 0)
                elseif upY.alignXRot then
                    local upZ, rootHookPosition, z = worldToLocal(upY.referenceFrame, z2, distance, dx)
                    local angle, z = MathUtil.vector2Normalize(rootHookPosition, z)
                    local angle = math.clamp(-math.atan2(angle, z), upY.minRot, upY.maxRot)
                    setRotation(upY.node, angle, 0, 0)
                elseif upY.alignToTarget then
                    local upZ, rootHookPosition, z = worldToLocal(upY.referenceFrame, z2, distance, dx)
                    local angle, rootHookPosition, z = MathUtil.vector3Normalize(upZ, rootHookPosition, z)
                    setDirection(upY.node, angle, rootHookPosition, z, 0, 1, 0)
                end
            end
            x2.rope:setTargetNode(y2.hookData:getRopeTarget(), false)
        end
    end
end
function YarderCarriage:onCarriageTreeRaycastCallback(hitObjectId, x, y, z, _, _, _, _, _, _, isLast)
    if not (self.isDeleted or self.isDeleting) then
        local spec = self.spec_yarderCarriage
        if not spec.treeRaycast.hasStarted then
            spec.treeRaycast.validTree = nil
            return false
        end
        if hitObjectId ~= 0 and (getHasClassId(hitObjectId, ClassIds.SHAPE) and (getSplitType(hitObjectId) ~= 0 and getIsSplitShapeSplit(hitObjectId))) then
            if isLast then
                spec.treeRaycast.hasStarted = false
                local x2, y2, z2 = getWorldTranslation(spec.rope.originNode)
                if MathUtil.vector2Length(x - x2, z - z2) > spec.joint.maxDistance then
                    spec.treeRaycast.validTree = nil
                    return false
                end
                if #spec.attachedTrees > 0 then
                    local i = 1
                    for i = i, #spec.attachedTrees do
                        if hitObjectId == spec.attachedTrees[i].treeId then
                            spec.treeRaycast.validTree = nil
                            return false
                        end
                    end
                    local distanceToRoot, i, upX = getWorldTranslation(spec.attachedTrees[1].hookData.hookId)
                    if MathUtil.vector3Length(x - distanceToRoot, y - i, z - upX) > 2 then
                        spec.treeRaycast.validTree = nil
                        return false
                    end
                end
                local rootTreeData, distanceToRoot, i, upX, upY, upZ, radius = SplitShapeUtil.getTreeOffsetPosition(hitObjectId, x, y, z, 4, 0.15)
                if rootTreeData == nil then
                    spec.treeRaycast.validTree = nil
                else
                    spec.treeRaycast.validTree = hitObjectId
                    spec.treeRaycast.treeTargetPos[1] = x
                    spec.treeRaycast.treeTargetPos[2] = y
                    spec.treeRaycast.treeTargetPos[3] = z
                    spec.treeRaycast.treeCenterPos[1] = rootTreeData
                    spec.treeRaycast.treeCenterPos[2] = distanceToRoot
                    spec.treeRaycast.treeCenterPos[3] = i
                    spec.treeRaycast.treeUp[1] = upX
                    spec.treeRaycast.treeUp[2] = upY
                    spec.treeRaycast.treeUp[3] = upZ
                    spec.treeRaycast.treeRadius = radius
                    self:raiseActive()
                end
            end
            return false
        end
        if isLast then
            spec.treeRaycast.hasStarted = false
            spec.treeRaycast.validTree = nil
        end
    end
end
function YarderCarriage:onAttachTreeAction()
    local spec = self.spec_yarderCarriage
    if spec.treeRaycast.validTree ~= nil then
        if g_server == nil then
            g_client:getServerConnection():sendEvent(TreeAttachRequestEvent.new(self, spec.treeRaycast.validTree, spec.treeRaycast.treeTargetPos[1], spec.treeRaycast.treeTargetPos[2], spec.treeRaycast.treeTargetPos[3]))
        else
            local isAllowed, reason = self:getIsCarriageTreeAttachAllowed(spec.treeRaycast.validTree)
            if isAllowed then
                self:attachTreeToCarriage(spec.treeRaycast.validTree, spec.treeRaycast.treeTargetPos[1], spec.treeRaycast.treeTargetPos[2], spec.treeRaycast.treeTargetPos[3])
            else
                self:showCarriageTreeMountFailedWarning(nil, reason)
            end
        end
        spec.treeRaycast.validTree = nil
    end
end
function YarderCarriage:attachTreeToCarriage(splitShapeId, x, y, z, _, noEventSend)
    local spec = self.spec_yarderCarriage
    spec.rope.attachMainRope:setVisibility(false)
    spec.rope.attachAdditionalRope:setVisibility(false)
    local treeData = {
        ["treeId"] = splitShapeId,
        ["hookData"] = spec.treeHook.hookData:clone()
    }
    local centerX, _, _ = treeData.hookData:mountToTree(splitShapeId, x, y, z, 4)
    if centerX == nil then
        treeData.hookData:delete()
    else
        treeData.hookData:setTargetNode(spec.rope.originNode, true)
        if self.isServer then
            local newIndex, additionalRope = self:createJoint(treeData.treeId, treeData.hookData.hookId)
            treeData.jointIndex = newIndex
            treeData.transLimitY = additionalRope
            treeData.limitValue = treeData.transLimitY
            treeData.speedScale = treeData.transLimitY * (1 / spec.joint.attachTime)
            treeData.limitDirty = true
            if #spec.attachedTrees == 0 then
                spec.lastTransLimitY = treeData.transLimitY
            end
        end
        local additionalRope = spec.attachedTrees
        table.insert(additionalRope, treeData)
        ObjectChangeUtil.setObjectChanges(spec.rope.changeObjects, true, self, self.setMovingToolDirty)
        local newIndex = #spec.attachedTrees
        if newIndex > 1 and spec.additionalRopes[newIndex - 1] ~= nil then
            local additionalRope = spec.additionalRopes[newIndex - 1]
            setVisibility(additionalRope.referenceNode, true)
            local j = 1
            for j = j, #additionalRope.hookNodes do
                setVisibility(additionalRope.hookNodes[j].node, true)
            end
            treeData.hookData:setTargetNode(additionalRope.referenceNode, true)
        end
        self:updateTreeAttachRopes(9999)
        if spec.samples.attachTree ~= nil and spec.samples.attachTree.soundNode ~= nil then
            setWorldTranslation(spec.samples.attachTree.soundNode, x, y, z)
            g_soundManager:playSample(spec.samples.attachTree)
        end
        if newIndex == 1 and spec.rope.componentJointIndex ~= nil then
            local additionalRope = self.componentJoints[spec.rope.componentJointIndex]
            local limit = spec.rope.componentJointLimitActive
            self:setComponentJointRotLimit(additionalRope, 1, -limit[1], limit[1])
            self:setComponentJointRotLimit(additionalRope, 2, -limit[2], limit[2])
            self:setComponentJointRotLimit(additionalRope, 3, -limit[3], limit[3])
        end
        if spec.yarderTowerVehicle ~= nil then
            SpecializationUtil.raiseEvent(spec.yarderTowerVehicle, "onYarderCarriageTreeAttached", splitShapeId)
        end
        g_messageCenter:publish(MessageType.TREE_SHAPE_MOUNTED, splitShapeId, self)
        self:raiseActive()
        TreeAttachEvent.sendEvent(self, splitShapeId, x, y, z, nil, noEventSend)
    end
end
function YarderCarriage:createJoint(shapeId, shapeJointId)
    local spec = self.spec_yarderCarriage
    local constr = JointConstructor.new()
    constr:setActors(spec.joint.component, shapeId)
    constr:setJointTransforms(spec.joint.node, shapeJointId)
    constr:setRotationLimit(0, -3.141592653589793, 3.141592653589793)
    constr:setRotationLimit(1, -3.141592653589793, 3.141592653589793)
    constr:setRotationLimit(2, -3.141592653589793, 3.141592653589793)
    constr:setEnableCollision(true)
    constr:setRotationLimitSpring(7500, 1500, 7500, 1500, 7500, 1500)
    constr:setTranslationLimitSpring(7500, 1500, 7500, 1500, 7500, 1500)
    local distance = calcDistanceFrom(spec.joint.node, shapeJointId)
    constr:setTranslationLimit(0, true, -distance, distance)
    constr:setTranslationLimit(1, true, -distance, distance)
    constr:setTranslationLimit(2, true, -distance, distance)
    return constr:finalize(), distance
end
function YarderCarriage:onDetachTreeAction()
    self:detachTreeFromCarriage()
end
function YarderCarriage:detachTreeFromCarriage(_, noEventSend)
    local spec = self.spec_yarderCarriage
    if spec.samples.detachTree ~= nil and (spec.samples.detachTree.soundNode ~= nil and (spec.attachedTrees[1] ~= nil and entityExists(spec.attachedTrees[1].hookData.hookId))) then
        setWorldTranslation(spec.samples.detachTree.soundNode, getWorldTranslation(spec.attachedTrees[1].hookData.hookId))
        g_soundManager:playSample(spec.samples.detachTree)
    end
    local i = #spec.attachedTrees
    local componentJoint = 1
    local limit = -1
    for i = i, componentJoint, limit do
        local treeData = spec.attachedTrees[i]
        if self.isServer then
            removeJoint(treeData.jointIndex)
        end
        treeData.hookData:delete()
        table.remove(spec.attachedTrees, i)
    end
    local i = 1
    local componentJoint = #spec.additionalRopes
    local limit = 1
    for i = i, componentJoint, limit do
        local treeData = spec.additionalRopes[i]
        setVisibility(treeData.referenceNode, false)
        local j = 1
        for j = j, #treeData.hookNodes do
            setVisibility(treeData.hookNodes[j].node, false)
        end
    end
    ObjectChangeUtil.setObjectChanges(spec.rope.changeObjects, false, self, self.setMovingToolDirty)
    if spec.rope.componentJointIndex ~= nil then
        local componentJoint = self.componentJoints[spec.rope.componentJointIndex]
        local limit = spec.rope.componentJointLimitInactive
        self:setComponentJointRotLimit(componentJoint, 1, -limit[1], limit[1])
        self:setComponentJointRotLimit(componentJoint, 2, -limit[2], limit[2])
        self:setComponentJointRotLimit(componentJoint, 3, -limit[3], limit[3])
    end
    TreeDetachEvent.sendEvent(self, nil, noEventSend)
end
function YarderCarriage:getNumAttachedTrees()
    return #self.spec_yarderCarriage.attachedTrees
end
function YarderCarriage:getMaxNumAttachedTrees()
    return self.spec_yarderCarriage.maxNumTrees
end
function YarderCarriage:getAttachedTreeMass()
    local spec = self.spec_yarderCarriage
    local totalMass = 0
    local i = 1
    for i = i, #spec.attachedTrees do
        totalMass = totalMass + getMass(spec.attachedTrees[i].treeId)
    end
    return totalMass
end
function YarderCarriage:getIsCarriageTreeAttachAllowed(splitShapeId)
    if splitShapeId == nil or not entityExists(splitShapeId) then
        return false, TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_DEFAULT
    elseif #self.spec_yarderCarriage.attachedTrees >= self.spec_yarderCarriage.maxNumTrees then
        return false, TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_DEFAULT
    elseif getMass(splitShapeId) + self:getAttachedTreeMass() > spec.maxTreeMass then
        return false, TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_TOO_HEAVY
    elseif getUserAttribute(splitShapeId, "isTensionBeltMounted") == true then
        return false, TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_DEFAULT
    else
        return true, TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_DEFAULT
    end
end
function YarderCarriage:getIsTreeInMountRange()
    local spec = self.spec_yarderCarriage
    if spec.treeRaycast.validTree == nil then
        return false
    elseif entityExists(spec.treeRaycast.validTree) then
        return #spec.attachedTrees < spec.maxNumTrees
    else
        return false
    end
end
function YarderCarriage:showCarriageTreeMountFailedWarning(_, reason)
    if reason == TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_TOO_HEAVY then
        g_currentMission:showBlinkingWarning(string.format(self.spec_yarderCarriage.texts.warningTooHeavy, self.spec_yarderCarriage.maxTreeMass), 2500)
    end
end
function YarderCarriage:setCarriageLiftInput(direction)
    if self.isServer then
        local spec = self.spec_yarderCarriage
        local i = 1
        for i = i, #spec.attachedTrees do
            local treeData = spec.attachedTrees[i]
            local minDistance = spec.joint.minDistance
            if i > 1 then
                minDistance = math.max(spec.attachedTrees[1].transLimitY, minDistance)
            end
            if entityExists(treeData.treeId) then
                local distance = calcDistanceFrom(spec.joint.node, treeData.hookData.hookId)
                if direction ~= spec.curLiftSpeedLastDirection then
                    spec.curLiftSpeedAlpha = 0
                    spec.curLiftSpeedLastDirection = direction
                end
                spec.curLiftSpeedAlpha = math.min(spec.curLiftSpeedAlpha + g_currentDt * spec.liftAcceleration, 1)
                local move = -(spec.liftSpeed * spec.curLiftSpeedAlpha) * g_currentDt * direction
                treeData.transLimitY = math.clamp(treeData.transLimitY + move, minDistance, (math.max(minDistance, distance + 0.3)))
                setJointTranslationLimit(treeData.jointIndex, 1, true, -treeData.transLimitY, 0)
                if i == 1 and treeData.transLimitY ~= spec.lastTransLimitY then
                    if move < 0 then
                        if not g_soundManager:getIsSamplePlaying(spec.samples.lift) then
                            g_soundManager:playSample(spec.samples.lift)
                            g_soundManager:stopSample(spec.samples.lower)
                            spec.sampleLiftPlayedSent = true
                            spec.sampleLowerPlayedSent = false
                        end
                    elseif not g_soundManager:getIsSamplePlaying(spec.samples.lower) then
                        g_soundManager:playSample(spec.samples.lower)
                        g_soundManager:stopSample(spec.samples.lift)
                        spec.sampleLowerPlayedSent = true
                        spec.sampleLiftPlayedSent = false
                    end
                    if treeData.transLimitY == spec.joint.minDistance then
                        g_soundManager:playSample(spec.samples.liftLimit)
                        spec.sampleLiftLimitPlayedSent = true
                    end
                    spec.lastTransLimitY = treeData.transLimitY
                    spec.lastTransLimitYTimeOffset = 250
                    self:raiseDirtyFlags(spec.dirtyFlag)
                end
            end
        end
    end
end
function YarderCarriage.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".attachedTree(?)#translation", "Main rope is active")
    schema:register(XMLValueType.INT, basePath .. ".attachedTree(?)#splitShapePart1", "Split shape data part 1")
    schema:register(XMLValueType.INT, basePath .. ".attachedTree(?)#splitShapePart2", "Split shape data part 2")
    schema:register(XMLValueType.INT, basePath .. ".attachedTree(?)#splitShapePart3", "Split shape data part 3")
end
function YarderCarriage:saveAttachedTreesToXML(xmlFile, key, _)
    local spec = self.spec_yarderCarriage
    local i = 1
    for i = i, #spec.attachedTrees do
        local treeData = spec.attachedTrees[i]
        local treeKey = string.format("%s.attachedTree(%d)", key, i - 1)
        xmlFile:setValue(treeKey .. "#translation", getWorldTranslation(treeData.hookData.hookId))
        local splitShapePart1, splitShapePart2, splitShapePart3 = getSaveableSplitShapeId(treeData.treeId)
        if splitShapePart1 ~= 0 and splitShapePart1 ~= nil then
            xmlFile:setValue(treeKey .. "#splitShapePart1", splitShapePart1)
            xmlFile:setValue(treeKey .. "#splitShapePart2", splitShapePart2)
            xmlFile:setValue(treeKey .. "#splitShapePart3", splitShapePart3)
        end
    end
end
function YarderCarriage.loadAttachedTreesFromXML(xmlFile, key)
    local data = {}
    xmlFile:iterate(key .. ".attachedTree", function(_, treeKey)
        -- upvalues: (copy) xmlFile, (copy) data
        local translation = xmlFile:getValue(treeKey .. "#translation", nil, true)
        if translation ~= nil then
            local splitShapePart1 = xmlFile:getValue(treeKey .. "#splitShapePart1")
            if splitShapePart1 ~= nil then
                table.insert(data, {
                    ["translation"] = translation,
                    ["splitShapePart1"] = splitShapePart1,
                    ["splitShapePart2"] = xmlFile:getValue(treeKey .. "#splitShapePart2"),
                    ["splitShapePart3"] = xmlFile:getValue(treeKey .. "#splitShapePart3")
                })
            end
        end
    end)
    return data
end
function YarderCarriage:resolveLoadedAttachedTrees(data)
    local i = 1
    for i = i, #data do
        local treeData = data[i]
        local shapeId = getShapeFromSaveableSplitShapeId(treeData.splitShapePart1, treeData.splitShapePart2, treeData.splitShapePart3)
        if shapeId == nil or shapeId == 0 then
            return false
        end
    end
    local i = 1
    for i = i, #data do
        local treeData = data[i]
        self:attachTreeToCarriage(getShapeFromSaveableSplitShapeId(treeData.splitShapePart1, treeData.splitShapePart2, treeData.splitShapePart3), treeData.translation[1], treeData.translation[2], treeData.translation[3], nil, true)
    end
    return true
end
function YarderCarriage:onYarderCarriageTreeShapeCut(oldShape, _)
    if self.isServer then
        local spec = self.spec_yarderCarriage
        local i = 1
        for i = i, #spec.attachedTrees do
            if spec.attachedTrees[i].treeId == oldShape then
                self:detachTreeFromCarriage()
                return
            end
        end
    end
end
function YarderCarriage:onYarderCarriageTreeShapeMounted(shape, mountVehicle)
    if mountVehicle ~= self and self.isServer then
        local spec = self.spec_yarderCarriage
        local i = 1
        for i = i, #spec.attachedTrees do
            if spec.attachedTrees[i].treeId == shape then
                self:detachTreeFromCarriage()
                return
            end
        end
    end
end
function YarderCarriage:getDirtMultiplier(superFunc)
    local multiplier = superFunc(self)
    local spec = self.spec_yarderCarriage
    if spec.yarderTowerVehicle == nil then
        return multiplier
    else
        return spec.yarderTowerVehicle:getDirtMultiplier()
    end
end
function YarderCarriage:getWearMultiplier(superFunc)
    local multiplier = superFunc(self)
    local spec = self.spec_yarderCarriage
    if spec.yarderTowerVehicle == nil then
        return multiplier
    else
        return spec.yarderTowerVehicle:getDirtMultiplier()
    end
end