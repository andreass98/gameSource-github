YarderTower = {}
YarderTower.TREE_RAYCAST_DISTANCE = 40
YarderTower.TERRAIN_RAYCAST_DISTANCE = 20
YarderTower.MAX_CONTROL_DISTANCE = 15
YarderTower.GROUND_COLLISION_MASK = CollisionFlag.TERRAIN + CollisionFlag.TERRAIN_DELTA + CollisionFlag.STATIC_OBJECT
YarderTower.DAMAGED_SPEED_REDUCTION = 0.3
YarderTower.FOLLOW_MODE_NONE = 0
YarderTower.FOLLOW_MODE_ME = 1
YarderTower.FOLLOW_MODE_HOME = 2
YarderTower.FOLLOW_MODE_PICKUP = 3
YarderTower.FAILED_REASON_NONE = 0
YarderTower.FAILED_REASON_TOO_LONG = 1
YarderTower.FAILED_REASON_WRONG_ANGLE = 2
YarderTower.FAILED_REASON_TREE_TOO_SMALL = 3
YarderTower.FAILED_REASON_WAY_BLOCKED = 4
YarderTower.FAILED_REASON_ONLY_UPHILL_YARDING = 5
source("dataS/scripts/vehicles/specializations/activatables/YarderTowerSetupActivatable.lua")
source("dataS/scripts/vehicles/specializations/activatables/YarderTowerControlActivatable.lua")
source("dataS/scripts/vehicles/specializations/events/YarderTowerFollowModeEvent.lua")
source("dataS/scripts/vehicles/specializations/events/YarderTowerSetTargetEvent.lua")
source("dataS/scripts/gui/hud/extensions/YarderTowerHUDExtension.lua")
function YarderTower.prerequisitesPresent(specializations)
    return true
end
function YarderTower.initSpecialization()
    g_storeManager:addSpecType("yarderMaxLength", "shopListAttributeIconWinchMaxLength", YarderTower.loadSpecValueMaxLength, YarderTower.getSpecValueMaxLength, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("yarderMaxMass", "shopListAttributeIconWinchMaxMass", YarderTower.loadSpecValueMaxMass, YarderTower.getSpecValueMaxMass, StoreSpecies.VEHICLE)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("YarderTower")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.yarderTower#controlTrigger", "Trigger for player to control the tower")
    schema:register(XMLValueType.BOOL, "vehicle.yarderTower#requiresAttacherVehicle", "Attacher vehicle is not allowed to be detached", false)
    schema:register(XMLValueType.BOOL, "vehicle.yarderTower#requiresLowering", "Yarder can only be set up while lowered", false)
    schema:register(XMLValueType.FLOAT, "vehicle.yarderTower#foldMinLimit", "Yarder can only be set up while fold time in between these limits", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.yarderTower#foldMaxLimit", "Yarder can only be set up while fold time in between these limits", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.yarderTower.placement#height", "Default height used on the trees", 10)
    schema:register(XMLValueType.STRING, "vehicle.yarderTower.placement#minHeightOffset", "Min. height offset from main rope start to position on the tree (\'-\' for no limit)", "-1")
    schema:register(XMLValueType.FLOAT, "vehicle.yarderTower.carriage#maxSpeed", "Max. speed of carriage in kph", 20)
    schema:register(XMLValueType.FLOAT, "vehicle.yarderTower.carriage#acceleration", "Acceleration speed", 0.01)
    schema:register(XMLValueType.FLOAT, "vehicle.yarderTower.carriage#deceleration", "Deceleration speed", 0.05)
    schema:register(XMLValueType.FLOAT, "vehicle.yarderTower.carriage#startOffset", "Min. offset from tower to the carriage in meter", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.yarderTower.carriage#endOffset", "Min. offset from tree to the carriage in meter", 1)
    schema:register(XMLValueType.STRING, "vehicle.yarderTower.carriage#filename", "Path to vehicle xml of carriage vehicle")
    schema:register(XMLValueType.FLOAT, "vehicle.yarderTower.carriage#maxTreeMass", "Max. tree mass that can be attached (used for store spec data)")
    ForestryHook.registerXMLPaths(schema, "vehicle.yarderTower.hooks.tree")
    ForestryHook.registerXMLPaths(schema, "vehicle.yarderTower.hooks.ground")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.yarderTower.ropes.setupRope#node", "Setup rope start node")
    schema:register(XMLValueType.COLOR, "vehicle.yarderTower.ropes.setupRope#colorInvalid", "Emissive color of rope while placement is invalid")
    schema:register(XMLValueType.COLOR, "vehicle.yarderTower.ropes.setupRope#colorValid", "Emissive color of rope while placement is valid")
    schema:register(XMLValueType.FLOAT, "vehicle.yarderTower.ropes.setupRope#diameterTree", "Rope diameter while on a tree", 0.015)
    schema:register(XMLValueType.FLOAT, "vehicle.yarderTower.ropes.setupRope#diameterPlayer", "Rope diameter while in players hand", 0.015)
    YarderTower.registerRopeXMLPaths(schema, "vehicle.yarderTower.ropes.setupRope")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.yarderTower.ropes.mainRope#node", "Main rope start node")
    schema:register(XMLValueType.ANGLE, "vehicle.yarderTower.ropes.mainRope#maxAngle", "Max angle to the target", 80)
    schema:register(XMLValueType.FLOAT, "vehicle.yarderTower.ropes.mainRope#maxLength", "Max distance to the target", 100)
    schema:register(XMLValueType.FLOAT, "vehicle.yarderTower.ropes.mainRope#clearance", "Min. clearance below the rope", 2)
    schema:register(XMLValueType.FLOAT, "vehicle.yarderTower.ropes.mainRope#minTreeDiameter", "Min. diameter of target tree", 0.2)
    YarderTower.registerRopeXMLPaths(schema, "vehicle.yarderTower.ropes.mainRope")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.yarderTower.ropes.pullRope#node", "Pull rope start node")
    YarderTower.registerRopeXMLPaths(schema, "vehicle.yarderTower.ropes.pullRope")
    schema:register(XMLValueType.FLOAT, "vehicle.yarderTower.ropes.pushRope#yOffset", "Y Offset from main anchor point", 1.5)
    YarderTower.registerRopeXMLPaths(schema, "vehicle.yarderTower.ropes.pushRope")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.yarderTower.ropes.supportRopes#centerNode", "Center of search radius")
    schema:register(XMLValueType.FLOAT, "vehicle.yarderTower.ropes.supportRopes#treeRadius", "Radius to search mounting trees", 25)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.yarderTower.ropes.supportRopes.supportRope(?)#node", "Support node which is automatically connected")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.yarderTower.ropes.supportRopes.supportRope(?)#raycastNode", "Dedicated node only used for ground detection raycast", "#node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.yarderTower.ropes.supportRopes.supportRope(?)#angleReferenceNode", "Node used for angle calculations to validate the mounting point")
    schema:register(XMLValueType.ANGLE, "vehicle.yarderTower.ropes.supportRopes.supportRope(?)#maxAngle", "Max. angle to tree", 15)
    schema:register(XMLValueType.ANGLE, "vehicle.yarderTower.ropes.supportRopes.supportRope(?)#raycastRotY", "Y rotation of rotNode while searching for ground mounting point via raycast")
    schema:register(XMLValueType.FLOAT, "vehicle.yarderTower.ropes.supportRopes.supportRope(?)#treeYOffset", "Y translation offset from tree root", 1)
    YarderTower.registerRopeXMLPaths(schema, "vehicle.yarderTower.ropes.supportRopes.supportRope(?)")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderTower.sounds", "setupRopeIncrease")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderTower.sounds", "setupRopeDecrease")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderTower.sounds", "setupRopeValidTarget")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderTower.sounds", "setupStarted")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderTower.sounds", "setupFinished")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderTower.sounds", "setupCanceled")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderTower.sounds", "ropeLinkTree")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderTower.sounds", "ropeLinkGround")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderTower.sounds", "removeYarder")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderTower.sounds", "carriageMovePos")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderTower.sounds", "carriageMoveNeg")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderTower.sounds", "carriageMovePosLimit")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderTower.sounds", "carriageMoveNegLimit")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderTower.sounds", "carriageDriveMovePos")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderTower.sounds", "carriageDriveMoveNeg")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderTower.sounds", "carriageDriveMovePosLimit")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderTower.sounds", "carriageDriveMoveNegLimit")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.yarderTower.sounds", "motor")
    EffectManager.registerEffectXMLPaths(schema, "vehicle.yarderTower.motorEffects")
    schema:setXMLSpecializationType()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).yarderTower#isActive", "Main rope is active")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).yarderTower#position", "Current carriage position")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).yarderTower.target#x", "Target x position")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).yarderTower.target#y", "Target y position")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).yarderTower.target#z", "Target z position")
    YarderCarriage.registerSavegameXMLPaths(schemaSavegame, "vehicles.vehicle(?).yarderTower")
end
function YarderTower.registerRopeXMLPaths(schema, baseKey)
    schema:register(XMLValueType.FLOAT, baseKey .. "#maxOffset", "Max y offset from direct line in the center of the rope", 0.1)
    schema:register(XMLValueType.FLOAT, baseKey .. "#offsetReferenceLength", "Y offset is interpolated up to this distance of rope length", 5)
    schema:register(XMLValueType.STRING, baseKey .. "#filename", "Path to rope i3d file")
    schema:register(XMLValueType.STRING, baseKey .. "#ropeNode", "Index path to rope to load", "0|0")
    schema:register(XMLValueType.FLOAT, baseKey .. "#diameter", "Rope diameter", 0.015)
    schema:register(XMLValueType.NODE_INDEX, baseKey .. "#rotNode", "Rotation node which is aligned in the rope direction")
    schema:register(XMLValueType.BOOL, baseKey .. "#rotNodeAllAxis", "Adjust all axis of the rotation node - otherwise only rotated about the Y axis", false)
    schema:register(XMLValueType.NODE_INDEX, baseKey .. ".ropeLengthNode(?)#node", "Node that is changing depending on the rope length")
    schema:register(XMLValueType.FLOAT, baseKey .. ".ropeLengthNode(?)#minLength", "Min. length for reference", 0)
    schema:register(XMLValueType.FLOAT, baseKey .. ".ropeLengthNode(?)#maxLength", "Max. length for reference", 10)
    schema:register(XMLValueType.VECTOR_ROT, baseKey .. ".ropeLengthNode(?)#minRot", "Rotation to apply at min. length")
    schema:register(XMLValueType.VECTOR_ROT, baseKey .. ".ropeLengthNode(?)#maxRot", "Rotation to apply at max. length")
    schema:register(XMLValueType.VECTOR_TRANS, baseKey .. ".ropeLengthNode(?)#minTrans", "Translation to apply at min. length")
    schema:register(XMLValueType.VECTOR_TRANS, baseKey .. ".ropeLengthNode(?)#maxTrans", "Translation to apply at max. length")
    schema:register(XMLValueType.VECTOR_SCALE, baseKey .. ".ropeLengthNode(?)#minScale", "Scale to apply at min. length")
    schema:register(XMLValueType.VECTOR_SCALE, baseKey .. ".ropeLengthNode(?)#maxScale", "Scale to apply at max. length")
    schema:register(XMLValueType.STRING, baseKey .. ".ropeLengthNode(?)#shaderParameterName", "Shader parameter to adjust")
    schema:register(XMLValueType.VECTOR_4, baseKey .. ".ropeLengthNode(?)#minShaderParameter", "Shader parameter to apply at min. length")
    schema:register(XMLValueType.VECTOR_4, baseKey .. ".ropeLengthNode(?)#maxShaderParameter", "Shader parameter to apply at max. length")
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, baseKey)
end
function YarderTower.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onYarderCarriageTreeAttached")
end
function YarderTower.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "onHookI3DLoaded", YarderTower.onHookI3DLoaded)
    SpecializationUtil.registerFunction(vehicleType, "onRopeI3DLoaded", YarderTower.onRopeI3DLoaded)
    SpecializationUtil.registerFunction(vehicleType, "getIsSetupModeChangeAllowed", YarderTower.getIsSetupModeChangeAllowed)
    SpecializationUtil.registerFunction(vehicleType, "setYarderSetupModeState", YarderTower.setYarderSetupModeState)
    SpecializationUtil.registerFunction(vehicleType, "setYarderTargetActive", YarderTower.setYarderTargetActive)
    SpecializationUtil.registerFunction(vehicleType, "setYarderCarriageFollowMode", YarderTower.setYarderCarriageFollowMode)
    SpecializationUtil.registerFunction(vehicleType, "setYarderCarriageMoveInput", YarderTower.setYarderCarriageMoveInput)
    SpecializationUtil.registerFunction(vehicleType, "setYarderCarriageLiftInput", YarderTower.setYarderCarriageLiftInput)
    SpecializationUtil.registerFunction(vehicleType, "onYarderCarriageAttach", YarderTower.onYarderCarriageAttach)
    SpecializationUtil.registerFunction(vehicleType, "onYarderCarriageDetach", YarderTower.onYarderCarriageDetach)
    SpecializationUtil.registerFunction(vehicleType, "setupSupportRopes", YarderTower.setupSupportRopes)
    SpecializationUtil.registerFunction(vehicleType, "onCreateCarriageFinished", YarderTower.onCreateCarriageFinished)
    SpecializationUtil.registerFunction(vehicleType, "onCarriageVehicleDeleted", YarderTower.onCarriageVehicleDeleted)
    SpecializationUtil.registerFunction(vehicleType, "setYarderRopeState", YarderTower.setYarderRopeState)
    SpecializationUtil.registerFunction(vehicleType, "updateYarderRope", YarderTower.updateYarderRope)
    SpecializationUtil.registerFunction(vehicleType, "updateYarderRopeLengthNodes", YarderTower.updateYarderRopeLengthNodes)
    SpecializationUtil.registerFunction(vehicleType, "getTreeAtPosition", YarderTower.getTreeAtPosition)
    SpecializationUtil.registerFunction(vehicleType, "getIsPlayerInYarderRange", YarderTower.getIsPlayerInYarderRange)
    SpecializationUtil.registerFunction(vehicleType, "getIsPlayerInYarderControlRange", YarderTower.getIsPlayerInYarderControlRange)
    SpecializationUtil.registerFunction(vehicleType, "getYarderIsSetUp", YarderTower.getYarderIsSetUp)
    SpecializationUtil.registerFunction(vehicleType, "getYarderStatusInfo", YarderTower.getYarderStatusInfo)
    SpecializationUtil.registerFunction(vehicleType, "getYarderMainRopeLength", YarderTower.getYarderMainRopeLength)
    SpecializationUtil.registerFunction(vehicleType, "getYarderCarriageLastSpeed", YarderTower.getYarderCarriageLastSpeed)
    SpecializationUtil.registerFunction(vehicleType, "getIsTreeShapeUsedForYarderSetup", YarderTower.getIsTreeShapeUsedForYarderSetup)
    SpecializationUtil.registerFunction(vehicleType, "onYarderControlTriggerCallback", YarderTower.onYarderControlTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "onYarderTreeRaycastCallback", YarderTower.onYarderTreeRaycastCallback)
    SpecializationUtil.registerFunction(vehicleType, "doRopePlacementValidation", YarderTower.doRopePlacementValidation)
    SpecializationUtil.registerFunction(vehicleType, "onMainRopePlacementValidated", YarderTower.onMainRopePlacementValidated)
    SpecializationUtil.registerFunction(vehicleType, "onYarderSupportTerrainRaycastCallback", YarderTower.onYarderSupportTerrainRaycastCallback)
    SpecializationUtil.registerFunction(vehicleType, "onSupportRopeTreeOverlapCallback", YarderTower.onSupportRopeTreeOverlapCallback)
    SpecializationUtil.registerFunction(vehicleType, "onYarderTowerPlayerDeleted", YarderTower.onYarderTowerPlayerDeleted)
end
function YarderTower.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", YarderTower.isDetachAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", YarderTower.getIsFoldAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowsLowering", YarderTower.getAllowsLowering)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", YarderTower.getDoConsumePtoPower)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", YarderTower.getConsumingLoad)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowerTakeOffActive", YarderTower.getIsPowerTakeOffActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", YarderTower.getDirtMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", YarderTower.getWearMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getUsageCausesDamage", YarderTower.getUsageCausesDamage)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", YarderTower.addToPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", YarderTower.removeFromPhysics)
end
function YarderTower.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", YarderTower)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadEnd", YarderTower)
    SpecializationUtil.registerEventListener(vehicleType, "onPreDelete", YarderTower)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", YarderTower)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", YarderTower)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", YarderTower)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", YarderTower)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", YarderTower)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", YarderTower)
    SpecializationUtil.registerEventListener(vehicleType, "onYarderCarriageTreeAttached", YarderTower)
    SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", YarderTower)
end
function YarderTower:onLoad(_)
    local spec = self.spec_yarderTower
    local isInvalid = false
    spec.sharedLoadRequestIds = {}
    spec.controlTriggerNode = self.xmlFile:getValue("vehicle.yarderTower#controlTrigger", nil, self.components, self.i3dMappings)
    if spec.controlTriggerNode == nil then
        Logging.xmlError(self.xmlFile, "Missing yarder control trigger")
        isInvalid = true
    else
        if not CollisionFlag.getHasMaskFlagSet(spec.controlTriggerNode, CollisionFlag.PLAYER) then
            Logging.xmlError(self.xmlFile, "Yarder control trigger does not have the PLAYER collision flag set!")
            isInvalid = true
        end
        addTrigger(spec.controlTriggerNode, "onYarderControlTriggerCallback", self)
    end
    spec.requiresAttacherVehicle = self.xmlFile:getValue("vehicle.yarderTower#requiresAttacherVehicle", false)
    spec.requiresLowering = self.xmlFile:getValue("vehicle.yarderTower#requiresLowering", false)
    spec.foldMinLimit = self.xmlFile:getValue("vehicle.yarderTower#foldMinLimit", 0)
    spec.foldMaxLimit = self.xmlFile:getValue("vehicle.yarderTower#foldMaxLimit", 1)
    spec.requiresPowerTimeOffset = 0
    spec.placementHeight = self.xmlFile:getValue("vehicle.yarderTower.placement#height", 10)
    local placementMinHeightOffset = self.xmlFile:getValue("vehicle.yarderTower.placement#minHeightOffset", "-1")
    if placementMinHeightOffset == "-" then
        spec.placementMinHeightOffset = math.huge
    else
        spec.placementMinHeightOffset = tonumber(placementMinHeightOffset)
    end
    spec.carriage = {}
    spec.carriage.lastMoveInput = 0
    spec.carriage.lastMoveInputTime = 0
    spec.carriage.lastLiftInput = 0
    spec.carriage.lastLiftInputTime = 0
    spec.carriage.speed = 0
    spec.carriage.targetSpeed = 0
    spec.carriage.position = 0
    spec.carriage.lastPosition = 0
    spec.carriage.lastPositionTimeOffset = 0
    spec.carriage.lastSpeed = 0
    spec.carriage.followModeState = YarderTower.FOLLOW_MODE_NONE
    spec.carriage.followModePlayer = nil
    spec.carriage.followModeLocalPlayer = false
    spec.carriage.followModePickupPosition = 0
    spec.carriage.lastPlayerInRange = false
    spec.carriage.maxSpeed = self.xmlFile:getValue("vehicle.yarderTower.carriage#maxSpeed", 20) / 3600
    spec.carriage.acceleration = self.xmlFile:getValue("vehicle.yarderTower.carriage#acceleration", 0.01)
    spec.carriage.deceleration = self.xmlFile:getValue("vehicle.yarderTower.carriage#deceleration", 0.05)
    spec.carriage.startOffset = self.xmlFile:getValue("vehicle.yarderTower.carriage#startOffset", 1)
    spec.carriage.endOffset = self.xmlFile:getValue("vehicle.yarderTower.carriage#endOffset", 1)
    spec.carriage.filename = self.xmlFile:getValue("vehicle.yarderTower.carriage#filename")
    if spec.carriage.filename == nil then
        Logging.xmlError(self.xmlFile, "No carriage filename given in \'vehicle.yarderTower.carriage#filename\'")
        isInvalid = true
    else
        spec.carriage.filename = Utils.getFilename(spec.carriage.filename, self.baseDirectory)
        if g_storeManager:getItemByXMLFilename(spec.carriage.filename) == nil then
            Logging.xmlError(self.xmlFile, "Invalid carriage filename given. (%s)", spec.carriage.filename)
            isInvalid = true
        end
    end
    spec.hooks = {}
    spec.hooks.treeData = ForestryHook.new(self, self.rootNode)
    spec.hooks.treeData:loadFromXML(self.xmlFile, "vehicle.yarderTower.hooks.tree", self.baseDirectory)
    spec.hooks.treeData:setVisibility(false)
    spec.hooks.groundData = ForestryHook.new(self, self.rootNode)
    spec.hooks.groundData:loadFromXML(self.xmlFile, "vehicle.yarderTower.hooks.ground", self.baseDirectory)
    spec.hooks.groundData:setVisibility(false)
    if not (spec.hooks.treeData:isValid() and spec.hooks.groundData:isValid()) then
        Logging.xmlError(self.xmlFile, "Missing ground or tree hook for yarder!")
        isInvalid = true
    end
    local function storeItem(ropeData, key)
        -- upvalues: (copy) self, (copy) spec
        ropeData.isActive = false
        ropeData.maxOffset = self.xmlFile:getValue(key .. "#maxOffset", 0.4)
        ropeData.offsetReferenceLength = self.xmlFile:getValue(key .. "#offsetReferenceLength", 5)
        ropeData.diameter = self.xmlFile:getValue(key .. "#diameter", 0.015)
        ropeData.filename = self.xmlFile:getValue(key .. "#filename")
        ropeData.ropeNodePath = self.xmlFile:getValue(key .. "#ropeNode", "0|0")
        if ropeData.filename ~= nil then
            ropeData.filename = Utils.getFilename(ropeData.filename, self.baseDirectory)
            local sharedLoadRequestId = self:loadSubSharedI3DFile(ropeData.filename, false, false, self.onRopeI3DLoaded, self, ropeData)
            table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)
        end
        ropeData.rotNode = self.xmlFile:getValue(key .. "#rotNode", nil, self.components, self.i3dMappings)
        ropeData.rotNodeAllAxis = self.xmlFile:getValue(key .. "#rotNodeAllAxis", false)
        if ropeData.rotNode ~= nil then
            ropeData.rotNodeInitRot = { getRotation(ropeData.rotNode) }
        end
        ropeData.ropeLengthNodes = {}
        self.xmlFile:iterate(key .. ".ropeLengthNode", function(_, nodeKey)
            -- upvalues: (ref) self, (copy) ropeData
            local entry = {
                ["node"] = self.xmlFile:getValue(nodeKey .. "#node", nil, self.components, self.i3dMappings)
            }
            if entry.node ~= nil then
                entry.minLength = self.xmlFile:getValue(nodeKey .. "#minLength", 0)
                entry.maxLength = self.xmlFile:getValue(nodeKey .. "#maxLength", 10)
                entry.minRot = self.xmlFile:getValue(nodeKey .. "#minRot", nil, true)
                entry.maxRot = self.xmlFile:getValue(nodeKey .. "#maxRot", nil, true)
                entry.minTrans = self.xmlFile:getValue(nodeKey .. "#minTrans", nil, true)
                entry.maxTrans = self.xmlFile:getValue(nodeKey .. "#maxTrans", nil, true)
                entry.minScale = self.xmlFile:getValue(nodeKey .. "#minScale", nil, true)
                entry.maxScale = self.xmlFile:getValue(nodeKey .. "#maxScale", nil, true)
                entry.shaderParameterName = self.xmlFile:getValue(nodeKey .. "#shaderParameterName")
                entry.minShaderParameter = self.xmlFile:getValue(nodeKey .. "#minShaderParameter", nil, true)
                entry.maxShaderParameter = self.xmlFile:getValue(nodeKey .. "#maxShaderParameter", nil, true)
                if entry.shaderParameterName ~= nil and not getHasShaderParameter(entry.node, entry.shaderParameterName) then
                    Logging.xmlWarning(nodeKey, "Node does not have the provided shader parameter \'%s\'", entry.shaderParameterName)
                end
                table.insert(ropeData.ropeLengthNodes, entry)
            end
        end)
        ropeData.changeObjects = {}
        ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, key, ropeData.changeObjects, self.components, self)
        ObjectChangeUtil.setObjectChanges(ropeData.changeObjects, false, self, self.setMovingToolDirty)
    end
    spec.setupRope = {}
    spec.setupRope.node = self.xmlFile:getValue("vehicle.yarderTower.ropes.setupRope#node", nil, self.components, self.i3dMappings)
    if spec.setupRope.node == nil then
        Logging.xmlWarning(self.xmlFile, "Missing setupRope for yarder tower")
        isInvalid = true
    end
    spec.setupRope.colorInvalid = self.xmlFile:getValue("vehicle.yarderTower.ropes.setupRope#colorInvalid", nil, true)
    spec.setupRope.colorValid = self.xmlFile:getValue("vehicle.yarderTower.ropes.setupRope#colorValid", nil, true)
    spec.setupRope.diameterTree = self.xmlFile:getValue("vehicle.yarderTower.ropes.setupRope#diameterTree", 0.015)
    spec.setupRope.diameterPlayer = self.xmlFile:getValue("vehicle.yarderTower.ropes.setupRope#diameterPlayer", 0.015)
    storeItem(spec.setupRope, "vehicle.yarderTower.ropes.setupRope")
    spec.mainRope = {}
    spec.mainRope.node = self.xmlFile:getValue("vehicle.yarderTower.ropes.mainRope#node", nil, self.components, self.i3dMappings)
    if spec.mainRope.node == nil then
        Logging.xmlWarning(self.xmlFile, "Missing mainRope for yarder tower")
        isInvalid = true
    end
    spec.mainRope.maxAngle = self.xmlFile:getValue("vehicle.yarderTower.ropes.mainRope#maxAngle", 80)
    spec.mainRope.maxLength = self.xmlFile:getValue("vehicle.yarderTower.ropes.mainRope#maxLength", 100)
    spec.mainRope.clearance = self.xmlFile:getValue("vehicle.yarderTower.ropes.mainRope#clearance", 2)
    spec.mainRope.minTreeDiameter = self.xmlFile:getValue("vehicle.yarderTower.ropes.mainRope#minTreeDiameter", 0.2)
    storeItem(spec.mainRope, "vehicle.yarderTower.ropes.mainRope")
    spec.mainRope.isActive = false
    spec.mainRope.isValid = false
    spec.mainRope.lastIsValid = false
    spec.mainRope.lastLength = 0
    spec.mainRope.lastLengthOffsetTime = 0
    spec.mainRope.failedWarning = nil
    spec.mainRope.target = { 0, 0, 0 }
    spec.pullRope = {}
    spec.pullRope.node = self.xmlFile:getValue("vehicle.yarderTower.ropes.pullRope#node", nil, self.components, self.i3dMappings)
    storeItem(spec.pullRope, "vehicle.yarderTower.ropes.pullRope")
    spec.pushRope = {}
    spec.pushRope.yOffset = self.xmlFile:getValue("vehicle.yarderTower.ropes.pushRope#yOffset", 1.5)
    storeItem(spec.pushRope, "vehicle.yarderTower.ropes.pushRope")
    spec.supportRopes = {}
    spec.supportRopes.centerNode = self.xmlFile:getValue("vehicle.yarderTower.ropes.supportRopes#centerNode", nil, self.components, self.i3dMappings)
    spec.supportRopes.treeRadius = self.xmlFile:getValue("vehicle.yarderTower.ropes.supportRopes#treeRadius", 25)
    spec.supportRopes.foundTrees = {}
    spec.supportRopes.ropes = {}
    self.xmlFile:iterate("vehicle.yarderTower.ropes.supportRopes.supportRope", function(_, key)
        -- upvalues: (copy) self, (copy) storeItem, (copy) spec
        local supportRope = {
            ["node"] = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        }
        if supportRope.node ~= nil then
            supportRope.angleReferenceNode = self.xmlFile:getValue(key .. "#angleReferenceNode", supportRope.node, self.components, self.i3dMappings)
            supportRope.maxAngle = self.xmlFile:getValue(key .. "#maxAngle", 22.5)
            supportRope.raycastRotY = self.xmlFile:getValue(key .. "#raycastRotY")
            supportRope.treeYOffset = self.xmlFile:getValue(key .. "#treeYOffset", 1)
            supportRope.raycastNode = self.xmlFile:getValue(key .. "#raycastNode", supportRope.node, self.components, self.i3dMappings)
            supportRope.target = { 0, 0, 0 }
            supportRope.vehicle = self
            supportRope.onYarderSupportTerrainRaycastCallback = self.onYarderSupportTerrainRaycastCallback
            storeItem(supportRope, key)
            table.insert(spec.supportRopes.ropes, supportRope)
        end
    end)
    spec.isPlayerInRange = false
    spec.setupModeState = false
    spec.updateRopesDirtyTime = 0
    spec.treeRaycast = {}
    spec.treeRaycast.hasStarted = false
    spec.treeRaycast.lastValidTree = nil
    spec.treeRaycast.lastValidTreeHeight = 0
    spec.treeRaycast.foundTree = nil
    spec.treeRaycast.data = {
        ["vehicle"] = self,
        ["x"] = 0,
        ["y"] = 0,
        ["z"] = 0,
        ["hasStarted"] = false,
        ["callback"] = self.onMainRopePlacementValidated
    }
    spec.lastMotorRpm = 0
    spec.lastMotorPowerTimeOffset = 0
    spec.samples = {}
    if self.isClient then
        spec.samples.setupRopeIncrease = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "setupRopeIncrease", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.setupRopeDecrease = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "setupRopeDecrease", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.setupRopeValidTarget = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "setupRopeValidTarget", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.setupStarted = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "setupStarted", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.setupFinished = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "setupFinished", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.setupCanceled = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "setupCanceled", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.ropeLinkTree = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "ropeLinkTree", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.ropeLinkGround = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "ropeLinkGround", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.removeYarder = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "removeYarder", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.carriageMovePos = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "carriageMovePos", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.carriageMoveNeg = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "carriageMoveNeg", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.carriageMovePosLimit = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "carriageMovePosLimit", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.carriageMoveNegLimit = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "carriageMoveNegLimit", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.carriageDriveMovePos = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "carriageDriveMovePos", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.carriageDriveMoveNeg = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "carriageDriveMoveNeg", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.carriageDriveMovePosLimit = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "carriageDriveMovePosLimit", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.carriageDriveMoveNegLimit = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "carriageDriveMoveNegLimit", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.motor = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.yarderTower.sounds", "motor", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        local i = 1
        for i = i, #spec.supportRopes.ropes do
            if spec.samples.ropeLinkTree ~= nil then
                spec.supportRopes.ropes[i].sampleRopeLinkTree = g_soundManager:cloneSample(spec.samples.ropeLinkTree, self.rootNode, self)
            end
            if spec.samples.ropeLinkGround ~= nil then
                supportRope.sampleRopeLinkGround = g_soundManager:cloneSample(spec.samples.ropeLinkGround, self.rootNode, self)
            end
        end
        if spec.samples.ropeLinkTree ~= nil then
            spec.mainRope.sampleRopeLinkTree = g_soundManager:cloneSample(spec.samples.ropeLinkTree, self.rootNode, self)
        end
        spec.motorEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.yarderTower.motorEffects", self.components, self, self.i3dMappings)
    end
    spec.texts = {}
    spec.texts.warningWrongAngle = g_i18n:getText("yarder_wrongAngle")
    spec.texts.warningRopeTooLong = g_i18n:getText("yarder_ropeTooLong")
    spec.texts.warningTreeTooSmall = g_i18n:getText("yarder_treeTooSmall")
    spec.texts.warningWayIsBlocked = g_i18n:getText("yarder_wayIsBlocked")
    spec.texts.actionStartSetup = g_i18n:getText("yarder_setup")
    spec.texts.actionCancelSetup = g_i18n:getText("yarder_cancelSetup")
    spec.texts.actionRemoveYarder = g_i18n:getText("yarder_remove")
    spec.texts.actionSetTargetTree = g_i18n:getText("yarder_setTargetTree")
    spec.texts.actionCarriageFollowModeEnable = g_i18n:getText("yarder_carriageFollowModeEnable")
    spec.texts.actionCarriageFollowModeDisable = g_i18n:getText("yarder_carriageFollowModeDisable")
    spec.texts.actionCarriageManualControl = g_i18n:getText("yarder_carriageMove")
    spec.texts.actionCarriageLiftLower = g_i18n:getText("yarder_carriageLiftLower")
    spec.texts.actionCarriageAttachTree = g_i18n:getText("yarder_carriageAttachTree")
    spec.texts.actionCarriageDetachTree = g_i18n:getText("yarder_carriageDetachTree")
    spec.texts.warningDetachNotAllowed = g_i18n:getText("yarder_detachNotAllowed")
    spec.texts.warningDoNotMoveVehicle = g_i18n:getText("yarder_doNotMoveVehicle")
    spec.texts.warningLowerFirst = g_i18n:getText("warning_lowerImplementFirst")
    spec.texts.warningUnfoldFirst = g_i18n:getText("warning_firstUnfoldTheTool")
    spec.texts.warningOnlyForUphillYarding = g_i18n:getText("yarder_onlyForUphillYarding")
    if isInvalid then
        Logging.xmlError(self.xmlFile, "Failed to load yarder")
        if spec.controlTriggerNode ~= nil then
            removeTrigger(spec.controlTriggerNode)
            spec.controlTriggerNode = nil
        end
        SpecializationUtil.removeEventListener(self, "onLoadEnd", YarderTower)
        SpecializationUtil.removeEventListener(self, "onReadStream", YarderTower)
        SpecializationUtil.removeEventListener(self, "onWriteStream", YarderTower)
        SpecializationUtil.removeEventListener(self, "onReadUpdateStream", YarderTower)
        SpecializationUtil.removeEventListener(self, "onWriteUpdateStream", YarderTower)
        SpecializationUtil.removeEventListener(self, "onUpdate", YarderTower)
        SpecializationUtil.removeEventListener(self, "onYarderCarriageTreeAttached", YarderTower)
        SpecializationUtil.removeEventListener(self, "onPostAttach", YarderTower)
    else
        spec.setupActivatable = YarderTowerSetupActivatable.new(self)
        spec.controlActivatable = YarderTowerControlActivatable.new(self)
        spec.hudExtension = YarderTowerHUDExtension.new(self)
    end
    spec.dirtyFlag = self:getNextDirtyFlag()
end
function YarderTower:onLoadEnd(savegame)
    if savegame ~= nil and not savegame.resetVehicles then
        local key = savegame.key .. ".yarderTower"
        self.spec_yarderTower.mainRope.isActive = savegame.xmlFile:getValue(key .. "#isActive", false)
        spec.carriage.position = savegame.xmlFile:getValue(key .. "#position", 0)
        if spec.mainRope.isActive then
            spec.mainRope.isValid = true
            spec.mainRope.target[1] = savegame.xmlFile:getValue(key .. ".target#x", spec.mainRope.target[1])
            spec.mainRope.target[2] = savegame.xmlFile:getValue(key .. ".target#y", spec.mainRope.target[2])
            spec.mainRope.target[3] = savegame.xmlFile:getValue(key .. ".target#z", spec.mainRope.target[3])
            self:setYarderTargetActive(true, true)
            spec.loadedAttachedTreesData = YarderCarriage.loadAttachedTreesFromXML(savegame.xmlFile, key)
        end
    end
end
function YarderTower:onPreDelete()
    local spec = self.spec_yarderTower
    if spec.mainRope ~= nil and spec.mainRope.isActive then
        self:setYarderTargetActive(false, true)
    end
end
function YarderTower:onDelete()
    local spec = self.spec_yarderTower
    if spec.hudExtension ~= nil then
        g_currentMission.hud:removeInfoExtension(spec.hudExtension)
        spec.hudExtension:delete()
    end
    if spec.controlTriggerNode ~= nil then
        removeTrigger(spec.controlTriggerNode)
        spec.controlTriggerNode = nil
    end
    if spec.sharedLoadRequestIds ~= nil then
        for _, sharedLoadRequestId in ipairs(spec.sharedLoadRequestIds) do
            g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
        end
    end
    if spec.hooks ~= nil then
        if spec.hooks.treeData ~= nil then
            spec.hooks.treeData:delete()
        end
        if spec.hooks.groundData ~= nil then
            spec.hooks.groundData:delete()
        end
    end
    if self.isClient then
        g_soundManager:deleteSamples(spec.samples)
        if spec.supportRopes ~= nil then
            local i = 1
            for i = i, #spec.supportRopes.ropes do
                local _ = spec.supportRopes.ropes[i]
                g_soundManager:deleteSample(_.sampleRopeLinkTree)
                g_soundManager:deleteSample(_.sampleRopeLinkGround)
            end
        end
        if spec.mainRope ~= nil then
            g_soundManager:deleteSample(spec.mainRope.sampleRopeLinkTree)
        end
        g_effectManager:deleteEffects(spec.motorEffects)
    end
    g_currentMission.activatableObjectsSystem:removeActivatable(spec.setupActivatable)
    g_currentMission.activatableObjectsSystem:removeActivatable(spec.controlActivatable)
end
function YarderTower:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_yarderTower
    xmlFile:setValue(key .. "#isActive", spec.mainRope.isActive)
    xmlFile:setValue(key .. "#position", spec.carriage.position)
    if spec.mainRope.isActive then
        xmlFile:setValue(key .. ".target#x", spec.mainRope.target[1])
        xmlFile:setValue(key .. ".target#y", spec.mainRope.target[2])
        xmlFile:setValue(key .. ".target#z", spec.mainRope.target[3])
    end
    if spec.carriage.vehicle ~= nil then
        spec.carriage.vehicle:saveAttachedTreesToXML(xmlFile, key, usedModNames)
    end
end
function YarderTower:onReadStream(streamId, _)
    local spec = self.spec_yarderTower
    spec.carriage.followModeState = streamReadUIntN(streamId, 2)
    if streamReadBool(streamId) then
        local x = streamReadFloat32(streamId)
        local y = streamReadFloat32(streamId)
        local z = streamReadFloat32(streamId)
        spec.mainRope.isValid = true
        spec.mainRope.target[1] = x
        spec.mainRope.target[2] = y
        spec.mainRope.target[3] = z
        self:setYarderTargetActive(true, true)
    end
end
function YarderTower:onWriteStream(streamId, _)
    local spec = self.spec_yarderTower
    streamWriteUIntN(streamId, spec.carriage.followModeState, 2)
    if streamWriteBool(streamId, spec.mainRope.isActive) then
        streamWriteFloat32(streamId, spec.mainRope.target[1])
        streamWriteFloat32(streamId, spec.mainRope.target[2])
        streamWriteFloat32(streamId, spec.mainRope.target[3])
    end
end
function YarderTower:onReadUpdateStream(streamId, _, connection)
    if not connection:getIsServer() and streamReadBool(streamId) then
        self:setYarderCarriageMoveInput(streamReadUIntN(streamId, 2) - 1)
        self:setYarderCarriageLiftInput(streamReadUIntN(streamId, 2) - 1)
    end
end
function YarderTower:onWriteUpdateStream(streamId, connection, dirtyMask)
    if connection:getIsServer() then
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.spec_yarderTower.dirtyFlag) ~= 0) then
            streamWriteUIntN(streamId, math.sign(spec.carriage.lastMoveInput) + 1, 2)
            streamWriteUIntN(streamId, math.sign(spec.carriage.lastLiftInput) + 1, 2)
        end
    end
end
function YarderTower:onUpdate(dt, _, _, _)
    local spec = self.spec_yarderTower
    if spec.setupModeState then
        if spec.mainRope.node == nil or (g_localPlayer == nil or not g_localPlayer.isControlled) then
            self:setYarderSetupModeState(false, true)
            spec.mainRope.isValid = false
            spec.mainRope.lastIsValid = false
        else
            local player = g_localPlayer
            local cameraNode = player:getCurrentCameraNode()
            local x1, y1, z1 = getWorldTranslation(spec.mainRope.node)
            local x2, y2, z2 = getWorldTranslation(player.hands.spec_hands.kinematicNode)
            local length = MathUtil.vector3Length(x2 - x1, y2 - y1, z2 - z1)
            if not spec.treeRaycast.hasStarted then
                spec.treeRaycast.hasStarted = true
                spec.treeRaycast.foundTree = nil
                local x, y, z = localToWorld(cameraNode, 0, 0, 1)
                local dx, dy, dz = localDirectionToWorld(cameraNode, 0, 0, -1)
                raycastClosestAsync(x, y, z, dx, dy, dz, YarderTower.TREE_RAYCAST_DISTANCE, "onYarderTreeRaycastCallback", self, CollisionFlag.TREE)
            end
            if spec.treeRaycast.lastValidTree == nil then
                spec.mainRope.isValid = false
                spec.mainRope.target[1] = x2
                spec.mainRope.target[2] = y2
                spec.mainRope.target[3] = z2
                spec.setupRope.diameter = spec.setupRope.diameterPlayer
            else
                local x = spec.treeRaycast.lastValidTree
                local y, z, dx = getWorldTranslation(x)
                local dy = math.max(z + spec.placementHeight, spec.treeRaycast.lastValidTreeHeight)
                local dy = math.min(dy, y1 + spec.placementMinHeightOffset)
                self:doRopePlacementValidation(spec.mainRope.node, x, y, math.max(dy, getTerrainHeightAtWorldPos(g_terrainNode, y, 0, dx) + 0.2), dx, spec.mainRope.maxAngle, spec.mainRope.maxLength, spec.mainRope.clearance, spec.mainRope.minTreeDiameter, spec.treeRaycast.data)
                length = MathUtil.vector3Length(spec.mainRope.target[1] - x1, spec.mainRope.target[2] - y1, spec.mainRope.target[3] - z1)
            end
            if spec.mainRope.isValid ~= spec.mainRope.lastIsValid then
                spec.mainRope.lastIsValid = spec.mainRope.isValid
                if spec.mainRope.isValid then
                    g_soundManager:playSample(spec.samples.setupRopeValidTarget)
                end
            end
            if length ~= spec.mainRope.lastLength then
                if spec.mainRope.lastLength < length then
                    if not g_soundManager:getIsSamplePlaying(spec.samples.setupRopeIncrease) then
                        g_soundManager:playSample(spec.samples.setupRopeIncrease)
                        g_soundManager:stopSample(spec.samples.setupRopeDecrease)
                    end
                elseif not g_soundManager:getIsSamplePlaying(spec.samples.setupRopeDecrease) then
                    g_soundManager:playSample(spec.samples.setupRopeDecrease)
                    g_soundManager:stopSample(spec.samples.setupRopeIncrease)
                end
                spec.mainRope.lastLength = length
                spec.mainRope.lastLengthOffsetTime = 250
            end
            if spec.mainRope.lastLengthOffsetTime > 0 then
                spec.mainRope.lastLengthOffsetTime = spec.mainRope.lastLengthOffsetTime - dt
                if spec.mainRope.lastLengthOffsetTime <= 0 then
                    g_soundManager:stopSample(spec.samples.setupRopeIncrease)
                    g_soundManager:stopSample(spec.samples.setupRopeDecrease)
                end
            end
            local x = spec.mainRope.isValid and spec.setupRope.colorValid or spec.setupRope.colorInvalid
            setShaderParameter(spec.setupRope.ropeNode, "ropeEmissiveColor", x[1], x[2], x[3], 1, false)
            self:updateYarderRope(spec.setupRope, x2, y2, z2, dt)
        end
        spec.setupActivatable:updateActionEventTexts()
        self:raiseActive()
    end
    if spec.mainRope.isActive then
        if spec.loadedAttachedTreesData ~= nil and (spec.carriage.vehicle ~= nil and (spec.carriage.vehicle.isAddedToPhysics and spec.carriage.vehicle:resolveLoadedAttachedTrees(spec.loadedAttachedTreesData))) then
            spec.loadedAttachedTreesData = nil
        end
        local player, cameraNode, x1 = getWorldTranslation(spec.mainRope.node)
        local y1 = spec.mainRope.target[1]
        local z1 = spec.mainRope.target[2]
        local kinematicHelperNode = spec.mainRope.target[3]
        if self.isServer and (spec.carriage.vehicle ~= nil and spec.carriage.vehicle.getCarriageDimensions ~= nil) then
            local x2, y2 = spec.carriage.vehicle:getCarriageDimensions()
            local z2 = MathUtil.vector3Length(y1 - player, z1 - cameraNode, kinematicHelperNode - x1)
            local length = spec.carriage.maxSpeed
            local x = self:getVehicleDamage()
            if x > 0 then
            end
            if spec.carriage.followModeState == YarderTower.FOLLOW_MODE_NONE then
                if spec.carriage.lastMoveInput == 0 then
                    spec.carriage.targetSpeed = 0
                else
                    spec.carriage.targetSpeed = length / z2 * dt * spec.carriage.lastMoveInput
                    if g_time - spec.carriage.lastMoveInputTime > 250 then
                        spec.carriage.lastMoveInput = 0
                    end
                end
            else
                local y = 0
                if spec.carriage.followModeState == YarderTower.FOLLOW_MODE_ME then
                    local z = spec.carriage.followModePlayer
                    if z ~= nil then
                        local dx, dy, dz = getWorldTranslation(z.rootNode)
                        local _, cx, cy
                        _, cx, cy, y = MathUtil.getClosestPointOnLineSegment(player, 0, x1, y1, 0, kinematicHelperNode, dx, dy, dz)
                    end
                end
                if spec.carriage.followModeState == YarderTower.FOLLOW_MODE_PICKUP then
                    y = spec.carriage.followModePickupPosition
                end
                local dx = y - spec.carriage.position
                local z = math.sign(dx)
                local dy = length / z2 * dt
                local cy = y - spec.carriage.position
                local dx = dy * math.min(math.abs(cy) * z2 / 2, 1)
                spec.carriage.targetSpeed = z * dx
                if spec.carriage.followModeState ~= YarderTower.FOLLOW_MODE_ME then
                    if math.abs(y - spec.carriage.position) * z2 < 0.1 then
                        self:setYarderCarriageFollowMode(YarderTower.FOLLOW_MODE_NONE)
                    end
                end
            end
            if spec.carriage.lastLiftInput ~= 0 then
                if g_time - spec.carriage.lastLiftInputTime > 250 then
                    spec.carriage.lastLiftInput = 0
                end
                spec.carriage.vehicle:setCarriageLiftInput(spec.carriage.lastLiftInput)
            end
            if spec.requiresAttacherVehicle then
                if spec.carriage.followModeState ~= YarderTower.FOLLOW_MODE_NONE or (spec.carriage.lastLiftInput ~= 0 or spec.carriage.lastMoveInput ~= 0) then
                    spec.requiresPowerTimeOffset = 10000
                end
                local y = self:getAttacherVehicle()
                if y ~= nil and y.startMotor ~= nil then
                    if spec.requiresPowerTimeOffset > 0 then
                        spec.requiresPowerTimeOffset = spec.requiresPowerTimeOffset - dt
                        if y:getIsMotorStarted() then
                            local z = y:getMotor()
                            local dx = z:getMotorRotationAccelerationLimit()
                            local dy, dz = z:getRequiredMotorRpmRange()
                            local _, _ = PowerConsumer.getTotalConsumedPtoTorque(y)
                            y:controlVehicle(0, 0, 0, dy * 3.141592653589793 / 30, dz * 3.141592653589793 / 30, dx, 0, 0, z:getMaxClutchTorque(), _ / z:getPtoMotorRpmRatio())
                            y:raiseActive()
                        elseif y:getCanMotorRun() then
                            y:startMotor()
                        end
                    elseif (y.getIsControlled == nil or not y:getIsControlled()) and y:getIsMotorStarted() then
                        y:stopMotor()
                    end
                end
            end
            local y = spec.carriage
            local dx = spec.carriage.position + spec.carriage.speed
            y.position = math.clamp(dx, 0, 1)
            local z = spec.carriage.targetSpeed - spec.carriage.speed
            local y = math.sign(z)
            local dy = spec.carriage.speed
            local z = y * math.sign(dy)
            local dx = y == 1 and math.min or math.max
            spec.carriage.speed = dx(spec.carriage.speed + spec.carriage.maxSpeed / z2 * dt * (z == 1 and spec.carriage.acceleration or spec.carriage.deceleration) * y, spec.carriage.targetSpeed)
            local dy = x2 / z2
            local dz = spec.carriage.startOffset / z2 + dy * 0.5
            local _ = spec.carriage.endOffset / z2 + dy * 0.5
            local _ = dz + spec.carriage.position * (1 - (dz + _))
            local cx, cy, cz = MathUtil.vector3Lerp(player, cameraNode, x1, y1, z1, kinematicHelperNode, _)
            local yOffset = math.sin(_ * 3.141592653589793) * spec.mainRope.maxOffset
            local rollSpacingAlpha = y2 / z2 * 0.5
            local rsx1, rsy1, rsz1 = MathUtil.vector3Lerp(player, cameraNode, x1, y1, z1, kinematicHelperNode, _ - rollSpacingAlpha)
            local rsy1 = rsy1 - math.sin((_ - rollSpacingAlpha) * 3.141592653589793) * spec.mainRope.maxOffset
            local rsx2, rsy2, rsz2 = MathUtil.vector3Lerp(player, cameraNode, x1, y1, z1, kinematicHelperNode, _ + rollSpacingAlpha)
            local rsy2 = rsy2 - math.sin((_ + rollSpacingAlpha) * 3.141592653589793) * spec.mainRope.maxOffset
            local cDirX, cDirY, cDirZ = MathUtil.vector3Normalize(rsx2 - rsx1, rsy2 - rsy1, rsz2 - rsz1)
            setDirection(spec.carriage.vehicle.rootNode, cDirX, cDirY, cDirZ, 0, 1, 0)
            local rx, ry, rz = getWorldRotation(spec.carriage.vehicle.rootNode)
            if spec.carriage.vehicle.isAddedToPhysics then
                spec.carriage.vehicle:setWorldPosition(cx, cy - yOffset, cz, rx, ry, rz, 1, false)
            else
                spec.carriage.vehicle:setAbsolutePosition(cx, cy - yOffset, cz, rx, ry, rz)
                spec.carriage.vehicle:addToPhysics()
                spec.carriage.vehicle:addWearAmount(self:getWearTotalAmount(), true)
                spec.carriage.vehicle:setDamageAmount(self:getDamageAmount(), true)
                spec.carriage.vehicle:addDirtAmount(self:getDirtAmount(), true)
            end
            spec.carriage.vehicle:raiseActive()
        end
        if spec.carriage.vehicle ~= nil and spec.carriage.vehicle.getCarriagePullRopeTargetNode ~= nil then
            local x2 = spec.carriage.vehicle:getCarriagePullRopeTargetNode()
            if x2 ~= nil then
                local y2, z2, length = getWorldTranslation(x2)
                local x = self:updateYarderRope(spec.pullRope, y2, z2, length, dt)
                spec.carriage.vehicle:updateRopeAlignmentNodes(spec.pullRope.ropeNode, y2, z2, length, x)
                local y, z = spec.carriage.vehicle:getCarriageDimensions()
                local dx = MathUtil.vector3Length(y1 - player, z1 - cameraNode, kinematicHelperNode - x1)
                local dy = (y + 0.025) / dx * 0.5
                local dz = spec.carriage.startOffset / dx + dy
                local _ = spec.carriage.endOffset / dx + dy
                local _, cx, cy = getWorldTranslation(spec.carriage.vehicle.rootNode)
                local cz, yOffset, rollSpacingAlpha = worldToLocal(spec.mainRope.ropeNode, _, cx, cy)
                local rsx1 = math.clamp((rollSpacingAlpha / dx - dz) / (1 - (dz + _)), 0, 1)
                spec.carriage.lastSpeed = math.abs((spec.carriage.lastPosition - rsx1) / dt * dx) / spec.carriage.maxSpeed
                if math.abs(rsx1 - spec.carriage.lastPosition) * dx > 0.005 then
                    if spec.carriage.lastPosition < rsx1 then
                        if not g_soundManager:getIsSamplePlaying(spec.samples.carriageMovePos) then
                            g_soundManager:playSample(spec.samples.carriageMovePos)
                            g_soundManager:playSample(spec.samples.carriageDriveMovePos)
                            g_soundManager:stopSample(spec.samples.carriageMoveNeg)
                            g_soundManager:stopSample(spec.samples.carriageDriveMoveNeg)
                        end
                    elseif not g_soundManager:getIsSamplePlaying(spec.samples.carriageMoveNeg) then
                        g_soundManager:playSample(spec.samples.carriageMoveNeg)
                        g_soundManager:playSample(spec.samples.carriageDriveMoveNeg)
                        g_soundManager:stopSample(spec.samples.carriageMovePos)
                        g_soundManager:stopSample(spec.samples.carriageDriveMovePos)
                    end
                    if rsx1 == 1 then
                        g_soundManager:playSample(spec.samples.carriageMovePosLimit)
                        g_soundManager:playSample(spec.samples.carriageDriveMovePosLimit)
                    elseif rsx1 == 0 then
                        g_soundManager:playSample(spec.samples.carriageMoveNegLimit)
                        g_soundManager:playSample(spec.samples.carriageDriveMoveNegLimit)
                    end
                    spec.carriage.lastPosition = rsx1
                    spec.carriage.lastPositionTimeOffset = 250
                    if spec.samples.carriageMovePos ~= nil and spec.samples.carriageMovePos.soundNode ~= nil then
                        setWorldTranslation(spec.samples.carriageMovePos.soundNode, _, cx, cy)
                    end
                    if spec.samples.carriageMoveNeg ~= nil and spec.samples.carriageMoveNeg.soundNode ~= nil then
                        setWorldTranslation(spec.samples.carriageMoveNeg.soundNode, _, cx, cy)
                    end
                    if spec.samples.carriageMovePosLimit ~= nil and spec.samples.carriageMovePosLimit.soundNode ~= nil then
                        setWorldTranslation(spec.samples.carriageMovePosLimit.soundNode, _, cx, cy)
                    end
                    if spec.samples.carriageMoveNegLimit ~= nil and spec.samples.carriageMoveNegLimit.soundNode ~= nil then
                        setWorldTranslation(spec.samples.carriageMoveNegLimit.soundNode, _, cx, cy)
                    end
                    spec.controlActivatable:updateActionEventTexts()
                elseif spec.carriage.lastPositionTimeOffset > 0 then
                    spec.carriage.lastPositionTimeOffset = spec.carriage.lastPositionTimeOffset - dt
                    if spec.carriage.lastPositionTimeOffset <= 0 then
                        g_soundManager:stopSample(spec.samples.carriageMovePos)
                        g_soundManager:stopSample(spec.samples.carriageDriveMovePos)
                        g_soundManager:stopSample(spec.samples.carriageMoveNeg)
                        g_soundManager:stopSample(spec.samples.carriageDriveMoveNeg)
                    end
                end
            end
            if spec.pushRope.isActive ~= nil then
                local y2 = spec.carriage.vehicle:getCarriagePushRopeTargetNode()
                if y2 ~= nil then
                    spec.pushRope.hookData:setTargetNode(y2, false)
                    setWorldTranslation(spec.pushRope.ropeNode, spec.pushRope.hookData:getRopeTargetPosition())
                    local z2, length, x = getWorldTranslation(y2)
                    self:updateYarderRope(spec.pushRope, z2, length, x, dt)
                end
            end
            local y2, z2 = self:getIsPlayerInYarderControlRange()
            if y2 then
                spec.carriage.vehicle:updateCarriageInRange(dt)
                if spec.hudExtension ~= nil then
                    g_currentMission.hud:addInfoExtension(spec.hudExtension)
                end
            elseif spec.carriage.lastPlayerInRange then
                spec.carriage.vehicle:onYarderCarriageUpdateEnd()
            end
            spec.carriage.lastPlayerInRange = y2
        end
        local _ = spec.updateRopesDirtyTime > 0
        spec.updateRopesDirtyTime = spec.updateRopesDirtyTime - dt
        self:updateYarderRope(spec.mainRope, y1, z1, kinematicHelperNode, dt)
        local z2 = 1
        local x2 = #spec.supportRopes.ropes
        local y2 = 1
        for z2 = z2, x2, y2 do
            local length = spec.supportRopes.ropes[z2]
            if length.isActive then
                self:updateYarderRope(length, length.target[1], length.target[2], length.target[3], dt)
            end
        end
        if spec.carriage.vehicle ~= nil then
            if not g_soundManager:getIsSamplePlaying(spec.samples.motor) then
                g_soundManager:playSample(spec.samples.motor)
                spec.lastMotorRpm = 0
                g_effectManager:startEffects(spec.motorEffects)
            end
            if spec.carriage.lastPositionTimeOffset > 0 then
                spec.lastMotorPowerTimeOffset = 10000
            else
                spec.lastMotorPowerTimeOffset = math.max(spec.lastMotorPowerTimeOffset - dt, 0)
            end
            local x2 = 0
            local y2 = 0.33 * spec.carriage.lastSpeed
            if spec.lastMotorPowerTimeOffset > 0 then
                x2 = 0.5 + spec.carriage.lastSpeed * 0.5
            end
            spec.lastMotorRpm = spec.lastMotorRpm * 0.975 + x2 * 0.025
            local z2 = y2 + spec.carriage.vehicle:getNumAttachedTrees() / spec.carriage.vehicle:getMaxNumAttachedTrees() * spec.carriage.lastSpeed * (1 - y2)
            g_soundManager:setSampleLoopSynthesisParameters(spec.samples.motor, spec.lastMotorRpm, z2)
            g_effectManager:setDensity(spec.motorEffects, spec.lastMotorRpm)
        end
        self:raiseActive()
    end
end
function YarderTower:onYarderCarriageTreeAttached(_)
    local spec = self.spec_yarderTower
    spec.carriage.followModePickupPosition = spec.carriage.lastPosition
    spec.controlActivatable:updateActionEventTexts()
end
function YarderTower:onPostAttach(_, _, _, _)
    local rootVehicle = self.rootVehicle
    if rootVehicle.registerPlayerVehicleControlAllowedFunction ~= nil then
        rootVehicle:registerPlayerVehicleControlAllowedFunction(self, YarderTower.getIsVehicleControlAllowed)
    end
end
function YarderTower.onHookI3DLoaded(_, i3dNode, _, hookData)
    if i3dNode ~= 0 then
        local hookNode = getChildAt(i3dNode, 0)
        link(getRootNode(), hookNode)
        setVisibility(hookNode, false)
        hookData.hookNode = hookNode
        delete(i3dNode)
    end
end
function YarderTower:onRopeI3DLoaded(i3dNode, _, ropeData)
    if i3dNode ~= 0 then
        local ropeNode = I3DUtil.indexToObject(i3dNode, ropeData.ropeNodePath)
        if ropeNode ~= nil then
            link(ropeData.node or self.rootNode, ropeNode)
            setVisibility(ropeNode, false)
            ropeData.ropeNode = ropeNode
        end
        delete(i3dNode)
    end
end
function YarderTower:getIsSetupModeChangeAllowed()
    local spec = self.spec_yarderTower
    if spec.setupModeState then
        return true
    end
    if spec.requiresLowering and not self:getIsLowered() then
        return false, string.format(spec.texts.warningLowerFirst, self:getName())
    end
    if self.getFoldAnimTime ~= nil then
        local time = self:getFoldAnimTime()
        if time < spec.foldMinLimit or spec.foldMaxLimit < time then
            return false, string.format(spec.texts.warningUnfoldFirst, self:getName())
        end
    end
    return true
end
function YarderTower:setYarderSetupModeState(state, canceled)
    local spec = self.spec_yarderTower
    if state == nil then
        state = not spec.setupModeState
    end
    spec.setupModeState = state
    if state then
        g_soundManager:playSample(spec.samples.setupStarted)
        self:setYarderTargetActive(false)
        self:setYarderRopeState(spec.setupRope, true)
        self:raiseActive()
    else
        self:setYarderRopeState(spec.setupRope, false)
        if not self.spec_yarderTower.isPlayerInRange then
            g_currentMission.activatableObjectsSystem:removeActivatable(spec.setupActivatable)
        end
        if canceled then
            g_soundManager:playSample(spec.samples.setupCanceled)
        end
    end
end
function YarderTower:setYarderTargetActive(state, noEventSend)
    local spec = self.spec_yarderTower
    if state then
        if spec.mainRope.isValid then
            local x = spec.mainRope.target[1]
            local y = spec.mainRope.target[2]
            local z = spec.mainRope.target[3]
            local shapeId = self:getTreeAtPosition(x, y, z, 3)
            if shapeId ~= nil and shapeId ~= 0 then
                local sx, sy, sz = getWorldTranslation(spec.mainRope.node)
                spec.mainRope.hookData = spec.hooks.treeData:clone()
                local centerX, centerY, centerZ = spec.mainRope.hookData:mountToTree(shapeId, x, y, z, 4, sx, sy, sz)
                if centerX == nil then
                    return
                end
                spec.mainRope.hookData:setTargetNode(spec.mainRope.node, false)
                local yRot = spec.mainRope.target
                local data = spec.mainRope.target
                local i = spec.mainRope.target
                yRot[1], data[2], i[3] = spec.mainRope.hookData:getRopeTargetPosition()
                if spec.mainRope.sampleRopeLinkTree ~= nil and spec.mainRope.sampleRopeLinkTree.soundNode ~= nil then
                    setWorldTranslation(spec.mainRope.sampleRopeLinkTree.soundNode, centerX, centerY, centerZ)
                    g_soundManager:playSample(spec.mainRope.sampleRopeLinkTree)
                end
                spec.mainRope.isActive = true
                spec.mainRope.treeId = shapeId
                if spec.pushRope.ropeNode ~= nil then
                    spec.pushRope.hookData = spec.hooks.treeData:clone()
                    spec.pushRope.hookData:mountToTree(shapeId, x, y - spec.pushRope.yOffset, z, 4, sx, sy - spec.pushRope.yOffset, sz)
                    self:setYarderRopeState(spec.pushRope, true)
                end
                g_splitShapeManager:addActiveYarder(self)
                g_soundManager:playSample(spec.samples.setupFinished)
                self:raiseActive()
                self:setYarderSetupModeState(false, false)
                self:setupSupportRopes()
                if self.isServer then
                    if spec.carriage.filename == nil then
                        Logging.error("Carriage vehicle could not be loaded")
                    else
                        local yRot = MathUtil.getYRotationFromDirection(MathUtil.vector2Normalize(x - sx, z - sz))
                        local data = VehicleLoadingData.new()
                        data:setFilename(spec.carriage.filename)
                        data:setPosition(spec.mainRope.target[1], spec.mainRope.target[2], spec.mainRope.target[3])
                        data:setRotation(0, yRot, 0)
                        data:setPropertyState(VehiclePropertyState.OWNED)
                        data:setOwnerFarmId(self:getOwnerFarmId())
                        data:load(self.onCreateCarriageFinished, self)
                    end
                    local i = 1
                    local yRot = #self.components
                    local data = 1
                    for i = i, yRot, data do
                        local component = self.components[i]
                        setRigidBodyType(component.node, RigidBodyType.KINEMATIC)
                        component.isDynamic = false
                        component.isKinematic = true
                    end
                end
                spec.updateRopesDirtyTime = 500
                g_currentMission.activatableObjectsSystem:addActivatable(spec.controlActivatable)
                YarderTowerSetTargetEvent.sendEvent(self, true, centerX, centerY, centerZ, noEventSend)
            end
        end
        spec.treeRaycast.hasStarted = false
        spec.treeRaycast.lastValidTree = nil
    else
        if self.isClient and spec.mainRope.isActive then
            g_soundManager:playSample(spec.samples.removeYarder)
            if g_soundManager:getIsSamplePlaying(spec.samples.motor) then
                g_soundManager:stopSample(spec.samples.motor)
                g_effectManager:stopEffects(spec.motorEffects)
            end
        end
        spec.mainRope.isValid = false
        spec.mainRope.isActive = false
        spec.mainRope.treeId = nil
        if not g_currentMission.isExitingGame then
            g_splitShapeManager:removeActiveYarder(self)
        end
        local z = 1
        local x = #spec.supportRopes.ropes
        local y = 1
        for z = z, x, y do
            local shapeId = spec.supportRopes.ropes[z]
            self:setYarderRopeState(shapeId, false)
            shapeId.treeId = nil
        end
        self:setYarderRopeState(spec.pushRope, false)
        if spec.carriage.vehicle ~= nil then
            if self.isServer then
                spec.carriage.vehicle:setYarderTowerVehicle(nil)
                spec.carriage.vehicle:delete()
            end
            spec.carriage.vehicle = nil
            spec.carriage.lastPlayerInRange = false
        end
        spec.carriage.position = 0
        g_currentMission.activatableObjectsSystem:removeActivatable(spec.controlActivatable)
        if self.isServer then
            local z = 1
            for z = z, #self.components do
                local shapeId = self.components[z]
                setRigidBodyType(shapeId.node, RigidBodyType.DYNAMIC)
                shapeId.isDynamic = true
                shapeId.isKinematic = false
            end
        end
        YarderTowerSetTargetEvent.sendEvent(self, false, 0, 0, 0, noEventSend)
    end
    self:setYarderRopeState(spec.mainRope, spec.mainRope.isActive)
    self:setYarderRopeState(spec.pullRope, spec.mainRope.isActive)
end
function YarderTower:setYarderCarriageFollowMode(state, connection, noEventSend)
    local spec = self.spec_yarderTower
    if state == nil then
        state = YarderTower.FOLLOW_MODE_NONE
    end
    spec.carriage.followModeState = state
    if state == YarderTower.FOLLOW_MODE_ME then
        if self.isServer then
            if connection == nil then
                spec.carriage.followModePlayer = g_localPlayer
                spec.carriage.followModePlayer:addDeleteListener(self, "onYarderTowerPlayerDeleted")
            else
                for _, player in pairs(g_currentMission.playerSystem.players) do
                    if player.connection == connection then
                        spec.carriage.followModePlayer = player
                        spec.carriage.followModePlayer:addDeleteListener(self, "onYarderTowerPlayerDeleted")
                    end
                end
            end
        end
        if connection == nil then
            spec.carriage.followModeLocalPlayer = true
        end
    else
        if spec.carriage.followModePlayer ~= nil then
            spec.carriage.followModePlayer:removeDeleteListener(self, "onYarderTowerPlayerDeleted")
        end
        spec.carriage.followModePlayer = nil
        spec.carriage.followModeLocalPlayer = false
    end
    YarderTowerFollowModeEvent.sendEvent(self, state, noEventSend)
    spec.controlActivatable:updateActionEventTexts()
end
function YarderTower:setYarderCarriageMoveInput(direction)
    local spec = self.spec_yarderTower
    if direction ~= 0 and spec.carriage.followModeState ~= YarderTower.FOLLOW_MODE_NONE then
        self:setYarderCarriageFollowMode(YarderTower.FOLLOW_MODE_NONE)
    end
    spec.carriage.lastMoveInput = direction or 0
    spec.carriage.lastMoveInputTime = g_time
    if spec.carriage.lastMoveInput ~= 0 then
        self:raiseDirtyFlags(spec.dirtyFlag)
    end
end
function YarderTower:setYarderCarriageLiftInput(direction)
    local spec = self.spec_yarderTower
    spec.carriage.lastLiftInput = direction or 0
    spec.carriage.lastLiftInputTime = g_time
    if spec.carriage.lastLiftInput ~= 0 then
        self:raiseDirtyFlags(spec.dirtyFlag)
    end
end
function YarderTower:onYarderCarriageAttach()
    self.spec_yarderTower.carriage.vehicle:onAttachTreeAction()
end
function YarderTower:onYarderCarriageDetach()
    self.spec_yarderTower.carriage.vehicle:onDetachTreeAction()
end
function YarderTower:setupSupportRopes()
    local spec = self.spec_yarderTower
    local x, y, z = getWorldTranslation(spec.supportRopes.centerNode)
    local j = 1
    local getBestTreeIndex = #spec.supportRopes.ropes
    local mountToTree = 1
    for j = j, getBestTreeIndex, mountToTree do
        self:setYarderRopeState(spec.supportRopes.ropes[j], false)
    end
    local j = #spec.supportRopes.foundTrees
    local getBestTreeIndex = 1
    local mountToTree = -1
    for j = j, getBestTreeIndex, mountToTree do
        spec.supportRopes.foundTrees[j] = nil
    end
    overlapSphere(x, y, z, spec.supportRopes.treeRadius, "onSupportRopeTreeOverlapCallback", self, CollisionFlag.TREE, false, false, true, false)
    local function getBestTreeIndex(node, maxAngle)
        -- upvalues: (copy) spec
        local minAngle = math.huge
        local minAngleTree = nil
        local j = 1
        for j = j, #spec.supportRopes.foundTrees do
            local treeId = spec.supportRopes.foundTrees[j]
            local tx, ty, tz = getWorldTranslation(treeId)
            local dx, _, dz = MathUtil.vector3Normalize(worldToLocal(node, tx, ty, tz))
            local angle, dz = MathUtil.vector2Normalize(dx, dz)
            local angle = math.abs((MathUtil.getYRotationFromDirection(angle, dz)))
            if angle < maxAngle and angle < minAngle then
                minAngleTree = treeId
                minAngle = angle
            end
        end
        return minAngleTree, minAngle
    end
    local function mountToTree(supportRope, targetTreeId)
        -- upvalues: (copy) spec, (copy) self
        local j = 1
        for j = j, #spec.supportRopes.foundTrees do
            local treeId = spec.supportRopes.foundTrees[j]
            if treeId == targetTreeId then
                local tx, ty, tz = getWorldTranslation(treeId)
                local centerZ = getTerrainHeightAtWorldPos
                local centerX = math.max(ty, centerZ(g_terrainNode, tx, 0, tz))
                local centerX, centerY, centerZ, _, _, _, radius = SplitShapeUtil.getTreeOffsetPosition(treeId, tx, centerX + supportRope.treeYOffset, tz, 3)
                if centerX ~= nil then
                    self:setYarderRopeState(supportRope, true)
                    local sx, sy, sz = getWorldTranslation(supportRope.node)
                    supportRope.hookData = spec.hooks.treeData:clone()
                    supportRope.hookData:mountToTree(treeId, centerX, centerY, centerZ, 4, sx, sy, sz)
                    supportRope.hookData:setTargetNode(spec.mainRope.node, false)
                    supportRope.treeId = treeId
                    supportRope.target[1], supportRope.target[2], supportRope.target[3] = supportRope.hookData:getRopeTargetPosition()
                    if supportRope.sampleRopeLinkTree ~= nil and supportRope.sampleRopeLinkTree.soundNode ~= nil then
                        setWorldTranslation(supportRope.sampleRopeLinkTree.soundNode, centerX, centerY, centerZ)
                        g_soundManager:playSample(supportRope.sampleRopeLinkTree)
                    end
                    table.remove(spec.supportRopes.foundTrees, j)
                    return true
                end
            end
        end
        return false
    end
    local j = {}
    local i = 1
    local usedTrees = #spec.supportRopes.ropes
    for i = i, usedTrees do
        local supportRope = spec.supportRopes.ropes[i]
        local treeId, angle = getBestTreeIndex(supportRope.angleReferenceNode, supportRope.maxAngle)
        if treeId ~= nil then
            table.insert(j, {
                ["supportRope"] = supportRope,
                ["treeId"] = treeId,
                ["angle"] = angle
            })
        end
    end
    table.sort(j, function(a, b)
        return a.angle > b.angle
    end)
    local usedTrees = {}
    local supportRope = #j
    local i = -1
    for supportRope = supportRope, 1, i do
        local treeId = j[supportRope]
        if usedTrees[treeId.treeId] == nil and mountToTree(treeId.supportRope, treeId.treeId) then
            usedTrees[treeId.treeId] = true
            table.remove(j, supportRope)
        end
    end
    local supportRope = 1
    local i = 1
    for supportRope = supportRope, #j, i do
        local treeId = j[supportRope]
        local angle, _ = getBestTreeIndex(treeId.supportRope.angleReferenceNode, treeId.supportRope.maxAngle)
        if angle ~= nil then
            mountToTree(treeId.supportRope, angle)
        end
    end
    local supportRope = 1
    local i = 1
    for supportRope = supportRope, #spec.supportRopes.ropes, i do
        local treeId = spec.supportRopes.ropes[supportRope]
        if not treeId.isActive then
            if treeId.rotNode ~= nil and treeId.raycastRotY ~= nil then
                local angle, _, rz = getRotation(treeId.rotNode)
                setRotation(treeId.rotNode, angle, treeId.raycastRotY, rz)
                if self.setMovingToolDirty ~= nil then
                    self:setMovingToolDirty(treeId.rotNode)
                end
            end
            local angle, _, rz = getWorldTranslation(treeId.raycastNode)
            local ex, ey, ez = localToWorld(treeId.raycastNode, 0, 0, YarderTower.TERRAIN_RAYCAST_DISTANCE)
            local dz = getTerrainHeightAtWorldPos(g_terrainNode, ex, 0, ez) - 0.25
            local dx = math.min(ey, dz)
            local dx = ex - angle
            local dy = dx - _
            local dz = ez - rz
            local distance = MathUtil.vector3Length(dx, dy, dz)
            local dx, dy, dz = MathUtil.vector3Normalize(dx, dy, dz)
            raycastClosestAsync(angle, _, rz, dx, dy, dz, distance, "onYarderSupportTerrainRaycastCallback", treeId, YarderTower.GROUND_COLLISION_MASK)
        end
    end
end
function YarderTower:onCreateCarriageFinished(vehicles, vehicleLoadState, _)
    if #vehicles == 1 and vehicleLoadState == VehicleLoadingState.OK then
        local vehicle = vehicles[1]
        self.spec_yarderTower.carriage.vehicle = vehicle
        vehicle:addDeleteListener(self, "onCarriageVehicleDeleted")
        vehicle:setYarderTowerVehicle(self)
        vehicle:removeFromPhysics()
    else
        Logging.error("Failed to load yarder carriage \'%s\'", spec.carriage.filename)
    end
end
function YarderTower:onCarriageVehicleDeleted(_, _)
    local spec = self.spec_yarderTower
    spec.carriage.vehicle = nil
    spec.carriage.lastPlayerInRange = nil
end
function YarderTower:setYarderRopeState(rope, state)
    rope.isActive = state
    if rope.ropeNode ~= nil then
        setVisibility(rope.ropeNode, state)
    end
    if rope.rotNode ~= nil and not state then
        setRotation(rope.rotNode, unpack(rope.rotNodeInitRot))
        if self.setMovingToolDirty ~= nil then
            self:setMovingToolDirty(rope.rotNode)
        end
    end
    if not state then
        if rope.hookData ~= nil then
            rope.hookData:delete()
            rope.hookData = nil
        end
        self:updateYarderRopeLengthNodes(rope, 0)
    end
    ObjectChangeUtil.setObjectChanges(rope.changeObjects, state, self, self.setMovingToolDirty)
end
function YarderTower:updateYarderRope(rope, tx, ty, tz, _, _, _)
    local x1, y1, z1 = getWorldTranslation(rope.node or rope.ropeNode)
    local totalRopeLength = MathUtil.vector3Length(tx - x1, ty - y1, tz - z1)
    local dirX = rope.maxOffset or 0
    local dirZ = totalRopeLength / (rope.offsetReferenceLength or 0)
    local maxOffset = dirX * math.min(dirZ, 1)
    if totalRopeLength ~= rope.lastTotalRopeLength then
        local dirX, dirY, dirZ = MathUtil.vector3Normalize(tx - x1, ty - y1, tz - z1)
        if rope.rotNode ~= nil then
            local lDirX, lDirY, lDirZ = worldDirectionToLocal(getParent(rope.rotNode), dirX, dirY, dirZ)
            if rope.rotNodeAllAxis then
                local boundingRadius, lDirY, lDirZ = MathUtil.vector3Normalize(lDirX, lDirY, lDirZ)
                setDirection(rope.rotNode, boundingRadius, lDirY, lDirZ, 0, 1, 0)
            else
                local boundingRadius, lDirZ = MathUtil.vector2Normalize(lDirX, lDirZ)
                setDirection(rope.rotNode, boundingRadius, 0, lDirZ, 0, 1, 0)
            end
            if self.setMovingToolDirty ~= nil then
                self:setMovingToolDirty(rope.rotNode)
            end
        end
        if rope.ropeNode ~= nil then
            local lDirX, lDirY, lDirZ = worldDirectionToLocal(getParent(rope.ropeNode), dirX, dirY, dirZ)
            setDirection(rope.ropeNode, lDirX, lDirY, lDirZ, 0, 1, 0)
            g_animationManager:setPrevShaderParameter(rope.ropeNode, "ropeLengthBendSizeUv", totalRopeLength, -maxOffset, rope.diameter, 4, false, "prevRopeLengthBendSizeUv")
            local boundingRadius = math.max(math.ceil(totalRopeLength), 1) * 0.5
            if math.ceil(boundingRadius) ~= rope.boundingRadius then
                setShapeBoundingSphere(rope.ropeNode, 0, 0, boundingRadius, boundingRadius)
                rope.boundingRadius = boundingRadius
            end
        end
        self:updateYarderRopeLengthNodes(rope, totalRopeLength)
        rope.lastTotalRopeLength = totalRopeLength
    end
    return maxOffset
end
function YarderTower.updateYarderRopeLengthNodes(_, rope, length)
    if rope.ropeLengthNodes ~= nil then
        local i = 1
        for i = i, #rope.ropeLengthNodes do
            local ropeLengthNode = rope.ropeLengthNodes[i]
            local alpha = MathUtil.inverseLerp(ropeLengthNode.minLength, ropeLengthNode.maxLength, length)
            if ropeLengthNode.minRot ~= nil and ropeLengthNode.maxRot ~= nil then
                local x, y, z = MathUtil.vector3ArrayLerp(ropeLengthNode.minRot, ropeLengthNode.maxRot, alpha)
                setRotation(ropeLengthNode.node, x, y, z)
            end
            if ropeLengthNode.minTrans ~= nil and ropeLengthNode.maxTrans ~= nil then
                local x, y, z = MathUtil.vector3ArrayLerp(ropeLengthNode.minTrans, ropeLengthNode.maxTrans, alpha)
                setTranslation(ropeLengthNode.node, x, y, z)
            end
            if ropeLengthNode.minScale ~= nil and ropeLengthNode.maxScale ~= nil then
                local x, y, z = MathUtil.vector3ArrayLerp(ropeLengthNode.minScale, ropeLengthNode.maxScale, alpha)
                setScale(ropeLengthNode.node, x, y, z)
            end
            if ropeLengthNode.shaderParameterName ~= nil and (ropeLengthNode.minShaderParameter ~= nil and ropeLengthNode.maxShaderParameter ~= nil) then
                setShaderParameter(ropeLengthNode.node, ropeLengthNode.shaderParameterName, MathUtil.lerp(ropeLengthNode.minShaderParameter[1], ropeLengthNode.maxShaderParameter[1], alpha), MathUtil.lerp(ropeLengthNode.minShaderParameter[2], ropeLengthNode.maxShaderParameter[2], alpha), MathUtil.lerp(ropeLengthNode.minShaderParameter[3], ropeLengthNode.maxShaderParameter[3], alpha), MathUtil.lerp(ropeLengthNode.minShaderParameter[4], ropeLengthNode.maxShaderParameter[4], alpha), false)
            end
        end
    end
end
function YarderTower.getTreeAtPosition(_, x, y, z, maxRadius)
    local shapeId, _, _, _, _ = findSplitShape(x - maxRadius * 0.5, y, z - maxRadius * 0.5, 0, 1, 0, 0, 0, 1, maxRadius, maxRadius)
    return shapeId
end
function YarderTower:getIsPlayerInYarderRange()
    if self:getOwnerFarmId() == g_currentMission:getFarmId() then
        return self.spec_yarderTower.isPlayerInRange or self.spec_yarderTower.setupModeState
    else
        return false
    end
end
function YarderTower:getIsPlayerInYarderControlRange(x, y, z)
    local spec = self.spec_yarderTower
    if spec.isPlayerInRange then
        return false, math.huge
    end
    if x == nil then
        if g_localPlayer == nil then
            return false
        end
        x, y, z = getWorldTranslation(g_localPlayer.rootNode)
    end
    if self:getOwnerFarmId() ~= g_currentMission:getFarmId() then
        return false
    end
    local x1, _, z1 = getWorldTranslation(spec.mainRope.node)
    local tx, _, tz = MathUtil.getClosestPointOnLineSegment(x1, 0, z1, spec.mainRope.target[1], 0, spec.mainRope.target[3], x, y, z)
    local distance = MathUtil.vector2Length(x - tx, z - tz)
    return distance < YarderTower.MAX_CONTROL_DISTANCE, distance
end
function YarderTower:getYarderIsSetUp()
    return self.spec_yarderTower.carriage.vehicle ~= nil
end
function YarderTower:getYarderStatusInfo()
    local spec = self.spec_yarderTower
    local isLoaded = false
    if spec.carriage.vehicle ~= nil then
        isLoaded = #spec.carriage.vehicle.spec_yarderCarriage.attachedTrees > 0
    end
    local targetPosition = nil
    if spec.carriage.followModeState == YarderTower.FOLLOW_MODE_HOME then
        targetPosition = 0
    elseif spec.carriage.followModeState == YarderTower.FOLLOW_MODE_PICKUP then
        targetPosition = spec.carriage.followModePickupPosition
    end
    if g_localPlayer == nil or not g_localPlayer.isControlled then
        return false, isLoaded, 0, spec.carriage.lastPosition, spec.carriage.followModeState, spec.carriage.followModeLocalPlayer, targetPosition
    end
    local x1, _, z1 = getWorldTranslation(g_localPlayer.rootNode)
    local x1, _, z1 = getWorldTranslation(spec.mainRope.node)
    local _, _, _, playerPosition = MathUtil.getClosestPointOnLineSegment(x1, 0, z1, spec.mainRope.target[1], 0, spec.mainRope.target[3], x1, _, z1)
    return true, isLoaded, playerPosition, spec.carriage.lastPosition, spec.carriage.followModeState, spec.carriage.followModeLocalPlayer, targetPosition
end
function YarderTower:getYarderMainRopeLength()
    local spec = self.spec_yarderTower
    if not spec.mainRope.isValid then
        return 0
    end
    local x1, y1, z1 = getWorldTranslation(spec.mainRope.node)
    return MathUtil.vector3Length(spec.mainRope.target[1] - x1, spec.mainRope.target[2] - y1, spec.mainRope.target[3] - z1)
end
function YarderTower:getYarderCarriageLastSpeed()
    return self.spec_yarderTower.carriage.lastSpeed
end
g_soundManager:registerModifierType("CARRIAGE_SPEED", YarderTower.getYarderCarriageLastSpeed)
function YarderTower:getIsTreeShapeUsedForYarderSetup(shape)
    local spec = self.spec_yarderTower
    if shape == spec.mainRope.treeId then
        return true
    end
    local j = 1
    for j = j, #spec.supportRopes.ropes do
        if spec.supportRopes.ropes[j].treeId == shape then
            return true
        end
    end
    return false
end
function YarderTower:onYarderControlTriggerCallback(_, otherId, onEnter, onLeave, _)
    if (onEnter or onLeave) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
        local spec = self.spec_yarderTower
        if onEnter then
            self.spec_yarderTower.isPlayerInRange = true
            g_currentMission.activatableObjectsSystem:addActivatable(spec.setupActivatable)
            return
        end
        self.spec_yarderTower.isPlayerInRange = false
        if not spec.setupModeState then
            g_currentMission.activatableObjectsSystem:removeActivatable(spec.setupActivatable)
        end
    end
end
function YarderTower:onYarderTreeRaycastCallback(hitObjectId, _, y, _, _, _, _, _, _, _, isLast)
    if hitObjectId ~= 0 and (getHasClassId(hitObjectId, ClassIds.SHAPE) and (getSplitType(hitObjectId) ~= 0 and not getIsSplitShapeSplit(hitObjectId))) then
        if isLast then
            self.spec_yarderTower.treeRaycast.hasStarted = false
            spec.treeRaycast.lastValidTree = hitObjectId
            spec.treeRaycast.lastValidTreeHeight = y
        end
        return false
    end
    if isLast then
        spec.treeRaycast.hasStarted = false
        spec.treeRaycast.lastValidTree = nil
    end
end
function YarderTower:doRopePlacementValidation(ropeNode, treeId, ex, ey, ez, maxAngle, maxLength, _, minTreeDiameter, callbackData)
    if not callbackData.hasStarted then
        local sx, sy, sz = getWorldTranslation(ropeNode)
        if sy + self.spec_yarderTower.placementMinHeightOffset < ey then
            return callbackData.callback(callbackData.vehicle, false, ex, ey, ez, YarderTower.FAILED_REASON_ONLY_UPHILL_YARDING)
        end
        local dx, dz = MathUtil.vector2Normalize(sx - ex, sz - ez)
        local ldx, _, ldz = worldDirectionToLocal(ropeNode, dx, 0, dz)
        local centerY = MathUtil.getYRotationFromDirection(ldx, ldz)
        local angle = 3.141592653589793 - math.abs(centerY)
        local centerX, centerY, centerZ, _, _, _, radius = SplitShapeUtil.getTreeOffsetPosition(treeId, ex, ey, ez, 3)
        if centerX ~= nil and minTreeDiameter <= radius * 2 then
            local length, wdx = MathUtil.vector2Normalize(sx - centerX, sz - centerZ)
            if angle < maxAngle then
                local length = MathUtil.vector3Length(centerX + length * radius - sx, centerY - sy, centerZ + wdx * radius - sz)
                if length < maxLength then
                    local wdx, wdy, wdz = MathUtil.vector3Normalize(ex - sx, centerY - sy, ez - sz)
                    callbackData.x = ex
                    callbackData.y = centerY
                    callbackData.z = ez
                    callbackData.hasStarted = true
                    callbackData.onYarderMainTreeRaycastCallback = YarderTower.onYarderMainTreeRaycastCallback
                    raycastClosestAsync(sx, sy - 2, sz, wdx, wdy, wdz, length - 0.5, "onYarderMainTreeRaycastCallback", callbackData, YarderTower.GROUND_COLLISION_MASK)
                else
                    callbackData.callback(callbackData.vehicle, false, ex, centerY, ez, YarderTower.FAILED_REASON_TOO_LONG)
                end
            else
                callbackData.callback(callbackData.vehicle, false, ex, centerY, ez, YarderTower.FAILED_REASON_WRONG_ANGLE)
                return
            end
        end
        callbackData.callback(callbackData.vehicle, false, ex, ey, ez, YarderTower.FAILED_REASON_TREE_TOO_SMALL)
    end
end
function YarderTower.onYarderMainTreeRaycastCallback(callbackData, hitObjectId, _, _, _, _, _, _, _, _, _, isLast)
    callbackData.hasStarted = false
    if hitObjectId ~= 0 then
        return callbackData.callback(callbackData.vehicle, false, callbackData.x, callbackData.y, callbackData.z, YarderTower.FAILED_REASON_WAY_BLOCKED)
    end
    if hitObjectId == 0 and isLast then
        return callbackData.callback(callbackData.vehicle, true, callbackData.x, callbackData.y, callbackData.z, YarderTower.FAILED_REASON_NONE)
    end
end
function YarderTower:onMainRopePlacementValidated(isValid, x, y, z, reason)
    local spec = self.spec_yarderTower
    if spec.setupModeState then
        spec.mainRope.isValid = isValid
        spec.mainRope.target[1] = x
        spec.mainRope.target[2] = y
        spec.mainRope.target[3] = z
    end
    if not isValid then
        if reason == YarderTower.FAILED_REASON_TOO_LONG then
            g_currentMission:showBlinkingWarning(spec.texts.warningRopeTooLong, 1000)
        elseif reason == YarderTower.FAILED_REASON_WRONG_ANGLE then
            g_currentMission:showBlinkingWarning(spec.texts.warningWrongAngle, 1000)
        elseif reason == YarderTower.FAILED_REASON_TREE_TOO_SMALL then
            g_currentMission:showBlinkingWarning(spec.texts.warningTreeTooSmall, 1000)
        elseif reason == YarderTower.FAILED_REASON_WAY_BLOCKED then
            g_currentMission:showBlinkingWarning(spec.texts.warningWayIsBlocked, 1000)
        elseif reason == YarderTower.FAILED_REASON_ONLY_UPHILL_YARDING then
            g_currentMission:showBlinkingWarning(spec.texts.warningOnlyForUphillYarding, 1000)
        end
    end
    spec.setupRope.diameter = spec.setupRope.diameterTree
end
function YarderTower.onYarderSupportTerrainRaycastCallback(supportRope, hitObjectId, x, y, z, _, _, _, _, _, _, isLast)
    if hitObjectId ~= 0 and getHasClassId(hitObjectId, ClassIds.TERRAIN_TRANSFORM_GROUP) then
        supportRope.vehicle:setYarderRopeState(supportRope, true)
        local sx, _, sz = getWorldTranslation(supportRope.node)
        supportRope.hookData = supportRope.vehicle.spec_yarderTower.hooks.groundData:clone()
        supportRope.hookData:setPositionAndDirection(x, y, z, MathUtil.vector2Normalize(sx - x, sz - z))
        supportRope.hookData:setTargetNode(supportRope.node, false)
        supportRope.target[1], supportRope.target[2], supportRope.target[3] = supportRope.hookData:getRopeTargetPosition()
        if supportRope.sampleRopeLinkGround ~= nil and supportRope.sampleRopeLinkGround.soundNode ~= nil then
            setWorldTranslation(supportRope.sampleRopeLinkGround.soundNode, x, y, z)
            g_soundManager:playSample(supportRope.sampleRopeLinkGround)
        end
        return false
    end
    if isLast and not supportRope.isActive then
        supportRope.vehicle:setYarderRopeState(supportRope, false)
    end
end
function YarderTower:onSupportRopeTreeOverlapCallback(objectId, ...)
    local spec = self.spec_yarderTower
    if objectId ~= spec.mainRope.treeId then
        table.insert(spec.supportRopes.foundTrees, objectId)
    end
end
function YarderTower:onYarderTowerPlayerDeleted()
    self:setYarderCarriageFollowMode(YarderTower.FOLLOW_MODE_NONE)
end
function YarderTower:isDetachAllowed(superFunc)
    local detachAllowed, warning, showWarning = superFunc(self)
    if detachAllowed then
        local spec = self.spec_yarderTower
        if spec.requiresAttacherVehicle and spec.mainRope.isActive then
            return false, spec.texts.warningDetachNotAllowed
        else
            return true
        end
    else
        return detachAllowed, warning, showWarning
    end
end
function YarderTower:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
    if self.spec_yarderTower.mainRope.isActive then
        return false
    else
        return superFunc(self, direction, onAiTurnOn)
    end
end
function YarderTower:getAllowsLowering(superFunc)
    if self.spec_yarderTower.mainRope.isActive then
        return false
    else
        return superFunc(self)
    end
end
function YarderTower:getDoConsumePtoPower(superFunc)
    return self.spec_yarderTower.mainRope.isActive and true or superFunc(self)
end
function YarderTower:getConsumingLoad(superFunc)
    local value, count = superFunc(self)
    local spec = self.spec_yarderTower
    local loadPercentage = 0
    if spec.mainRope.isActive then
        loadPercentage = 0.05 + spec.carriage.lastSpeed * 0.95
    end
    return value + loadPercentage, count + 1
end
function YarderTower:getIsPowerTakeOffActive(superFunc)
    if self.spec_yarderTower.mainRope.isActive then
        local attacherVehicle = self:getAttacherVehicle()
        if attacherVehicle ~= nil and (attacherVehicle.getIsMotorStarted ~= nil and attacherVehicle:getIsMotorStarted()) then
            return true
        end
    end
    return superFunc(self)
end
function YarderTower:getDirtMultiplier(superFunc)
    local multiplier = superFunc(self)
    local spec = self.spec_yarderTower
    if spec.mainRope.isActive then
        multiplier = multiplier + spec.carriage.lastSpeed * self:getWorkDirtMultiplier()
    end
    return multiplier
end
function YarderTower:getWearMultiplier(superFunc)
    local multiplier = superFunc(self)
    local spec = self.spec_yarderTower
    if spec.mainRope.isActive then
        multiplier = multiplier + spec.carriage.lastSpeed * self:getWorkWearMultiplier()
    end
    return multiplier
end
function YarderTower:getUsageCausesDamage(superFunc)
    local spec = self.spec_yarderTower
    if not spec.mainRope.isActive then
        return superFunc(self)
    end
    return spec.carriage.lastPositionTimeOffset > 0 and self.propertyState ~= VehiclePropertyState.MISSION
end
function YarderTower:addToPhysics(superFunc)
    if not superFunc(self) then
        return false
    end
    if self.spec_yarderTower.mainRope.isActive then
        local i = 1
        for i = i, #self.components do
            local component = self.components[i]
            setRigidBodyType(component.node, RigidBodyType.KINEMATIC)
            component.isDynamic = false
            component.isKinematic = true
        end
    end
    return true
end
function YarderTower:removeFromPhysics(superFunc)
    if self.spec_yarderTower.mainRope.isActive then
        local i = 1
        for i = i, #self.components do
            local component = self.components[i]
            setRigidBodyType(component.node, RigidBodyType.DYNAMIC)
            component.isDynamic = true
            component.isKinematic = false
        end
    end
    return superFunc(self) and true or false
end
function YarderTower:getIsVehicleControlAllowed()
    local spec = self.spec_yarderTower
    if spec.mainRope.isActive then
        return false, spec.texts.warningDoNotMoveVehicle
    else
        return true, nil
    end
end
function YarderTower.loadSpecValueMaxLength(xmlFile, _, _)
    return xmlFile:getValue("vehicle.yarderTower.ropes.mainRope#maxLength")
end
function YarderTower.getSpecValueMaxLength(storeItem, _, _, _, returnValues, returnRange)
    if storeItem.specs.yarderMaxLength ~= nil then
        local maxLength = storeItem.specs.yarderMaxLength
        local str = string.format("%d%s", maxLength, g_i18n:getText("unit_mShort"))
        if returnValues and returnRange then
            return maxLength, maxLength, str
        end
        if returnValues then
            return maxLength, str
        end
        if maxLength ~= 0 then
            return str
        end
    end
end
function YarderTower.loadSpecValueMaxMass(xmlFile, _, _)
    return xmlFile:getValue("vehicle.yarderTower.carriage#maxTreeMass")
end
function YarderTower.getSpecValueMaxMass(storeItem, _, _, _, returnValues, returnRange)
    if storeItem.specs.yarderMaxMass ~= nil then
        local maxTreeMass = storeItem.specs.yarderMaxMass
        local str = string.format("%.1f%s", maxTreeMass, g_i18n:getText("unit_tonsShort"))
        if returnValues and returnRange then
            return maxTreeMass, maxTreeMass, str
        end
        if returnValues then
            return maxTreeMass, str
        end
        if maxTreeMass ~= 0 then
            return str
        end
    end
end