AttacherJoints = {}
AttacherJoints.DEFAULT_MAX_UPDATE_DISTANCE = 50
AttacherJoints.MAX_ATTACH_DISTANCE_SQ = 0.48999999999999994
AttacherJoints.MAX_ATTACH_ANGLE = 0.34202
AttacherJoints.SMOOTH_ATTACH_TIME = 500
AttacherJoints.NUM_JOINTTYPES = 0
AttacherJoints.jointTypeNameToInt = {}
AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY = {}
AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[0] = 0.51
AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[1] = 0.718
AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[2] = 0.87
AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[3] = 1.01
AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[4] = 1.222
AttacherJoints.LOWER_LINK_BALL_SIZE_BY_CATEGORY = {}
AttacherJoints.LOWER_LINK_BALL_SIZE_BY_CATEGORY[0] = 0.035
AttacherJoints.LOWER_LINK_BALL_SIZE_BY_CATEGORY[1] = 0.044
AttacherJoints.LOWER_LINK_BALL_SIZE_BY_CATEGORY[2] = 0.056
AttacherJoints.LOWER_LINK_BALL_SIZE_BY_CATEGORY[3] = 0.064
AttacherJoints.LOWER_LINK_BALL_SIZE_BY_CATEGORY[4] = 0.085
source("dataS/scripts/vehicles/specializations/components/AttacherJointTopArm.lua")
function AttacherJoints.getClosestLowerLinkCategoryIndex(width)
    local minDistance = math.huge
    local index = 1
    for categoryIndex, categoryWidth in pairs(AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY) do
        local distance = math.abs(width - categoryWidth)
        if distance < minDistance then
            index = categoryIndex
            minDistance = distance
        end
    end
    return index
end
function AttacherJoints.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("attacherJoint", g_i18n:getText("configuration_attacherJoint"), "attacherJoints", VehicleConfigurationItem)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("AttacherJoints")
    AttacherJoints.registerAttacherJointXMLPaths(schema, "vehicle.attacherJoints")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.attacherJoints.sounds", "hydraulic")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.attacherJoints.sounds", "attach")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.attacherJoints.sounds", "detach")
    schema:register(XMLValueType.FLOAT, "vehicle.attacherJoints#comboDuration", "Combo duration", 2)
    schema:register(XMLValueType.INT, "vehicle.attacherJoints#connectionHoseConfigId", "Connection hose configuration index to use")
    schema:register(XMLValueType.INT, "vehicle.attacherJoints#powerTakeOffConfigId", "Power take off configuration index to use")
    schema:register(XMLValueType.INT, "vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration(?)#connectionHoseConfigId", "Connection hose configuration index to use")
    schema:register(XMLValueType.INT, "vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration(?)#powerTakeOffConfigId", "Power take off configuration index to use")
    schema:register(XMLValueType.FLOAT, "vehicle.attacherJoints#maxUpdateDistance", "Max. distance to vehicle root to update attacher joint graphics", AttacherJoints.DEFAULT_MAX_UPDATE_DISTANCE)
    schema:register(XMLValueType.VECTOR_N, Dashboard.GROUP_XML_KEY .. "#attacherJointIndices", "Group is only active if something is attached to those joints (List if indices of the attacher joint in xml)")
    schema:register(XMLValueType.NODE_INDICES, Dashboard.GROUP_XML_KEY .. "#attacherJointNodes", "Group is only active if something is attached to those joints (List of attacherJoint nodes)")
    schema:register(XMLValueType.VECTOR_N, Attachable.INPUT_ATTACHERJOINT_XML_KEY .. ".heightNode(?)#disablingAttacherJointIndices", "Attacher joint indices that disable height node if something is attached")
    schema:register(XMLValueType.VECTOR_N, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY .. ".heightNode(?)#disablingAttacherJointIndices", "Attacher joint indices that disable height node if something is attached")
    schema:register(XMLValueType.NODE_INDICES, "vehicle.trailer.trailerConfigurations.trailerConfiguration(?).trailer.tipSide(?)#disablingAttacherJointNodes", "Attacher joint nodes that disable the tip side if something is attached")
    schema:register(XMLValueType.NODE_INDICES, FillUnit.FILL_UNIT_XML_KEY .. "#disablingAttacherJointNodes", "Attacher joint nodes that disable the filling if something is attached")
    schema:addDelayedRegistrationFunc("ConnectionHoses:targetNode", function(cSchema, cKey)
        cSchema:register(XMLValueType.NODE_INDICES, cKey .. "#blockedByAttacherJointNodes", "List of attacher joints that block the usage of this hose target node")
    end)
    Dashboard.addDelayedRegistrationFunc(schema, function(cSchema, cKey)
        cSchema:register(XMLValueType.NODE_INDEX, cKey .. "#attacherJointNode", "Node of the attacher joint to use")
        cSchema:register(XMLValueType.NODE_INDICES, cKey .. "#attacherJointNodes", "List of attacher joint indices to use (first active one is used)")
    end)
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.attacherJoints.dashboards", { "bottomArmPosition", "bottomArmPositionMin", "bottomArmPositionMax" })
    schema:setXMLSpecializationType()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).attacherJoints#comboDirection", "Current combo direction")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).attacherJoints.attachedImplement(?)#jointIndex", "Index of attacherJoint")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).attacherJoints.attachedImplement(?)#moveDown", "Attacher joint is lowered or not")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).attacherJoints.attachedImplement(?)#attachedVehicleUniqueId", "Unique id of attached vehicle")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).attacherJoints.attachedImplement(?)#inputJointIndex", "Index of input attacher joint on the attached vehicle")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).attacherJoints.attacherJoint(?)#jointIndex", "Index of attacherJoint")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).attacherJoints.attacherJoint(?)#isBlocked", "Attacher joint is blocked or not")
    schemaSavegame:register(XMLValueType.INT, "vehicles.attachments(?)#rootVehicleId", "Root vehicle id")
    schemaSavegame:register(XMLValueType.INT, "vehicles.attachments(?).attachment(?)#attachmentId", "Attachment vehicle id")
    schemaSavegame:register(XMLValueType.INT, "vehicles.attachments(?).attachment(?)#inputJointDescIndex", "Index of input attacher joint", 1)
    schemaSavegame:register(XMLValueType.INT, "vehicles.attachments(?).attachment(?)#jointIndex", "Index of attacher joint")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.attachments(?).attachment(?)#moveDown", "Attachment lowered or lifted")
end
function AttacherJoints.registerAttacherJointXMLPaths(schema, baseName)
    schema:setXMLSharedRegistration("AttacherJoint", baseName)
    baseName = baseName .. ".attacherJoint(?)"
    schema:register(XMLValueType.NODE_INDEX, baseName .. "#node", "Node")
    schema:register(XMLValueType.NODE_INDEX, baseName .. "#nodeVisual", "Visual node")
    schema:register(XMLValueType.BOOL, baseName .. "#supportsHardAttach", "Supports hard attach")
    schema:register(XMLValueType.STRING, baseName .. "#jointType", "Joint type", "implement")
    schema:register(XMLValueType.STRING, baseName .. ".subType#name", "If defined this type needs to match with the sub type in the tool")
    schema:register(XMLValueType.STRING, baseName .. ".subType#brandRestriction", "If defined it\'s only possible to attach tools from these brands (can be multiple separated by \' \')")
    schema:register(XMLValueType.STRING, baseName .. ".subType#vehicleRestriction", "If defined it\'s only possible to attach tools containing these strings in there xml path (can be multiple separated by \' \')")
    schema:register(XMLValueType.BOOL, baseName .. ".subType#subTypeShowWarning", "Show warning if sub type does not match", true)
    schema:register(XMLValueType.BOOL, baseName .. "#allowsJointLimitMovement", "Allows joint limit movement", true)
    schema:register(XMLValueType.BOOL, baseName .. "#allowsLowering", "Allows lowering", true)
    schema:register(XMLValueType.BOOL, baseName .. "#isDefaultLowered", "Default lowered state", false)
    schema:register(XMLValueType.BOOL, baseName .. "#allowDetachingWhileLifted", "Allow detach while lifted", true)
    schema:register(XMLValueType.BOOL, baseName .. "#allowFoldingWhileAttached", "Allow folding while attached", true)
    schema:register(XMLValueType.BOOL, baseName .. "#canTurnOnImplement", "Can turn on implement", true)
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".rotationNode#node", "Rotation node")
    schema:register(XMLValueType.VECTOR_ROT, baseName .. ".rotationNode#lowerRotation", "Lower rotation", "0 0 0")
    schema:register(XMLValueType.VECTOR_ROT, baseName .. ".rotationNode#upperRotation", "Upper rotation", "rotation in i3d")
    schema:register(XMLValueType.VECTOR_ROT, baseName .. ".rotationNode#startRotation", "Start rotation", "rotation in i3d")
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".rotationNode2#node", "Rotation node")
    schema:register(XMLValueType.VECTOR_ROT, baseName .. ".rotationNode2#lowerRotation", "Lower rotation", "0 0 0")
    schema:register(XMLValueType.VECTOR_ROT, baseName .. ".rotationNode2#upperRotation", "Upper rotation", "rotation in i3d")
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".transNode#node", "Translation node")
    schema:register(XMLValueType.FLOAT, baseName .. ".transNode#height", "Height of visual translation node", 0.12)
    schema:register(XMLValueType.FLOAT, baseName .. ".transNode#minY", "Min Y translation")
    schema:register(XMLValueType.FLOAT, baseName .. ".transNode#maxY", "Max Y translation")
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".transNode.dependentBottomArm#node", "Dependent bottom arm node")
    schema:register(XMLValueType.FLOAT, baseName .. ".transNode.dependentBottomArm#threshold", "If the trans node Y translation is below this threshold the rotation will be set", "unlimited, so rotation is always set")
    schema:register(XMLValueType.VECTOR_ROT, baseName .. ".transNode.dependentBottomArm#rotation", "Rotation to be set when the translation node is below the threshold", "0 0 0")
    schema:register(XMLValueType.FLOAT, baseName .. ".distanceToGround#lower", "Lower distance to ground", 0.7)
    schema:register(XMLValueType.FLOAT, baseName .. ".distanceToGround#upper", "Upper distance to ground", 1)
    schema:register(XMLValueType.ANGLE, baseName .. "#lowerRotationOffset", "Upper rotation offset", 0)
    schema:register(XMLValueType.ANGLE, baseName .. "#upperRotationOffset", "Lower rotation offset", 0)
    schema:register(XMLValueType.BOOL, baseName .. "#dynamicLowerRotLimit", "Set the lower rot limit dynamically based on the lowered state (so the attacher can freely rotate between it\'s upper and lower rotation value. E.g. for combines)", false)
    schema:register(XMLValueType.BOOL, baseName .. "#lockDownRotLimit", "Lock down rotation limit", false)
    schema:register(XMLValueType.BOOL, baseName .. "#lockUpRotLimit", "Lock up rotation limit", false)
    schema:register(XMLValueType.BOOL, baseName .. "#lockDownTransLimit", "Lock down translation limit", true)
    schema:register(XMLValueType.BOOL, baseName .. "#lockUpTransLimit", "Lock up translation limit", false)
    schema:register(XMLValueType.VECTOR_ROT, baseName .. "#lowerRotLimit", "Lower rotation limit", "(20 20 20) for implement type, otherwise (0 0 0)")
    schema:register(XMLValueType.VECTOR_ROT, baseName .. "#upperRotLimit", "Upper rotation limit", "Lower rot limit")
    schema:register(XMLValueType.VECTOR_3, baseName .. "#lowerTransLimit", "Lower translation limit", "(0.5 0.5 0.5) for implement type, otherwise (0 0 0)")
    schema:register(XMLValueType.VECTOR_3, baseName .. "#upperTransLimit", "Upper translation limit", "Lower trans limit")
    schema:register(XMLValueType.VECTOR_3, baseName .. "#jointPositionOffset", "Joint position offset", "0 0 0")
    schema:register(XMLValueType.VECTOR_3, baseName .. "#rotLimitSpring", "Rotation limit spring", "0 0 0")
    schema:register(XMLValueType.VECTOR_3, baseName .. "#rotLimitDamping", "Rotation limit damping", "1 1 1")
    schema:register(XMLValueType.VECTOR_3, baseName .. "#rotLimitForceLimit", "Rotation limit force limit", "-1 -1 -1")
    schema:register(XMLValueType.VECTOR_3, baseName .. "#transLimitSpring", "Translation limit spring", "0 0 0")
    schema:register(XMLValueType.VECTOR_3, baseName .. "#transLimitDamping", "Translation limit damping", "1 1 1")
    schema:register(XMLValueType.VECTOR_3, baseName .. "#transLimitForceLimit", "Translation limit force limit", "-1 -1 -1")
    schema:register(XMLValueType.FLOAT, baseName .. "#moveTime", "Move time", 0.5)
    schema:register(XMLValueType.VECTOR_N, baseName .. "#disabledByAttacherJoints", "This attacher becomes unavailable after attaching something to these attacher joint indices")
    schema:register(XMLValueType.BOOL, baseName .. "#enableCollision", "Collision between vehicle is enabled", false)
    AttacherJointTopArm.registerVehicleXMLPaths(schema, baseName .. ".topArm")
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm#rotationNode", "Rotation node of bottom arm")
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm#translationNode", "Translation node of bottom arm")
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm#referenceNode", "Reference node of bottom arm")
    schema:register(XMLValueType.VECTOR_ROT, baseName .. ".bottomArm#startRotation", "Start rotation", "values set in i3d")
    schema:register(XMLValueType.INT, baseName .. ".bottomArm#zScale", "Inverts bottom arm direction", 1)
    schema:register(XMLValueType.BOOL, baseName .. ".bottomArm#lockDirection", "Lock direction", true)
    schema:register(XMLValueType.ANGLE, baseName .. ".bottomArm#resetSpeed", "Speed of bottom arm to return to idle position (deg/sec)", 45)
    schema:register(XMLValueType.BOOL, baseName .. ".bottomArm#updateReferenceDistance", "If \'true\', the reference distance will be updated dynamically. So it\'s possible to adjust the bottom arm length.", false)
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm#jointPositionNode", "Node that will be equalized with the current attacher joint position of the attached implement")
    schema:register(XMLValueType.BOOL, baseName .. ".bottomArm#toggleVisibility", "Bottom arm will be hidden on detach", false)
    schema:register(XMLValueType.VECTOR_N, baseName .. ".bottomArm#categoryRange", "Defines the min. and max. category that can be used separated by a whitespace. (if only one value is given it will be used as min. and max. value.)", "1 4")
    schema:register(XMLValueType.VECTOR_N, baseName .. ".bottomArm#widthRange", "Defines the min. and max. bottom arm width that can be used separated by a whitespace. Overwrites the categoryRange attribute. (if only one value is given it will be used as min. and max. value.)")
    schema:register(XMLValueType.FLOAT, baseName .. ".bottomArm#defaultWidth", "Defines the default bottom arm width while nothing is attached", "Width inside i3d file")
    schema:register(XMLValueType.INT, baseName .. ".bottomArm#defaultCategory", "Defines the default width category which is used when nothing is attached", "Width inside i3d file")
    schema:register(XMLValueType.BOOL, baseName .. ".bottomArm#ballVisibility", "Defines if the balls of the tool are visible while the tool is attached to us", true)
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm.armLeft#node", "Left bottom arm")
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm.armLeft#referenceNode", "Left bottom arm reference node (placed at the attaching point at the end of the bottom arm. If not defined the arm will be translated on the X axis to the target width.)")
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm.armRight#node", "Right bottom arm")
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm.armRight#referenceNode", "Right bottom arm reference node (placed at the attaching point at the end of the bottom arm. If not defined the arm will be translated on the X axis to the target width.)")
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm#leftNode", "Node of moving tool that will be aligned to \'bottomArmLeftNode\', if defined in the tool")
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm#rightNode", "Node of moving tool that will be aligned to \'bottomArmRightNode\', if defined in the tool")
    schema:register(XMLValueType.STRING, baseName .. ".toolbar#filename", "Filename to toolbars i3d containing 5 meshes for category 0-4", "$data/shared/assets/toolbars/toolbars.i3d")
    SoundManager.registerSampleXMLPaths(schema, baseName, "attachSound")
    SoundManager.registerSampleXMLPaths(schema, baseName, "detachSound")
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".steeringBars#leftNode", "Steering bar left node")
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".steeringBars#rightNode", "Steering bar right node")
    schema:register(XMLValueType.BOOL, baseName .. ".steeringBars#forceUsage", "Forces usage of tools steering axle even if no steering bars are defined", true)
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".visualAlignNode(?)#node", "Node of movingPart that should point towards the inputAttacherJoint node of the implement")
    schema:register(XMLValueType.BOOL, baseName .. ".visualAlignNode(?)#delayedOnAttach", "Node is updated after the smooth attach is finished", true)
    schema:register(XMLValueType.NODE_INDICES, baseName .. ".visuals#nodes", "Visual nodes of attacher joint that will be visible when the joint is active")
    schema:register(XMLValueType.NODE_INDICES, baseName .. ".visuals#hide", "Visual nodes that will be hidden while attacher joint is active if there attacher is inactive")
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, baseName)
    schema:register(XMLValueType.BOOL, baseName .. "#delayedObjectChanges", "Defines if object change is deactivated after the bottomArm has moved (if available)", true)
    schema:register(XMLValueType.BOOL, baseName .. "#delayedObjectChangesOnAttach", "Defines if object change is activated on attach or post attach", false)
    schema:register(XMLValueType.INT, baseName .. "#direction", "Direction of attacher joint (1 = front, -1 = back). Used for additional attachments on mobile and top light control in basegame.")
    schema:register(XMLValueType.BOOL, baseName .. "#useTopLights", "Defines if the attacher joint enables the top lights if something is attached. Flag needs to be set on the implement as well.", "\'true\' if the attacher joint is on the front")
    schema:register(XMLValueType.NODE_INDEX, baseName .. "#rootNode", "Root node", "Parent component of attacher joint node")
    schema:register(XMLValueType.FLOAT, baseName .. "#comboTime", "Combo time")
    schema:register(XMLValueType.VECTOR_2, baseName .. ".schema#position", "Schema position")
    schema:register(XMLValueType.VECTOR_2, baseName .. ".schema#liftedOffset", "Offset if lifted", "0 5")
    schema:register(XMLValueType.ANGLE, baseName .. ".schema#rotation", "Schema rotation", 0)
    schema:register(XMLValueType.BOOL, baseName .. ".schema#invertX", "Invert X", false)
    schema:addDelayedRegistrationPath(baseName, "AttacherJoint")
    schema:resetXMLSharedRegistration("AttacherJoint", baseName)
end
function AttacherJoints.registerJointType(name)
    local key = "JOINTTYPE_" .. string.upper(name)
    if AttacherJoints[key] == nil then
        AttacherJoints.NUM_JOINTTYPES = AttacherJoints.NUM_JOINTTYPES + 1
        AttacherJoints[key] = AttacherJoints.NUM_JOINTTYPES
        AttacherJoints.jointTypeNameToInt[name] = AttacherJoints.NUM_JOINTTYPES
    end
    return AttacherJoints[key]
end
AttacherJoints.JOINTTYPE_IMPLEMENT = AttacherJoints.registerJointType("implement")
AttacherJoints.JOINTTYPE_TRAILER = AttacherJoints.registerJointType("trailer")
AttacherJoints.JOINTTYPE_TRAILERLOW = AttacherJoints.registerJointType("trailerLow")
AttacherJoints.JOINTTYPE_TRAILERSADDLED = AttacherJoints.registerJointType("trailerSaddled")
AttacherJoints.JOINTTYPE_TRAILERCAR = AttacherJoints.registerJointType("trailerCar")
AttacherJoints.JOINTTYPE_TELEHANDLER = AttacherJoints.registerJointType("telehandler")
AttacherJoints.JOINTTYPE_FRONTLOADER = AttacherJoints.registerJointType("frontloader")
AttacherJoints.JOINTTYPE_LOADERFORK = AttacherJoints.registerJointType("loaderFork")
AttacherJoints.JOINTTYPE_SEMITRAILER = AttacherJoints.registerJointType("semitrailer")
AttacherJoints.JOINTTYPE_SEMITRAILERHOOK = AttacherJoints.registerJointType("semitrailerHook")
AttacherJoints.JOINTTYPE_SEMITRAILERCAR = AttacherJoints.registerJointType("semitrailerCar")
AttacherJoints.JOINTTYPE_ATTACHABLEFRONTLOADER = AttacherJoints.registerJointType("attachableFrontloader")
AttacherJoints.JOINTTYPE_WHEELLOADER = AttacherJoints.registerJointType("wheelLoader")
AttacherJoints.JOINTTYPE_MANUREBARREL = AttacherJoints.registerJointType("manureBarrel")
AttacherJoints.JOINTTYPE_CUTTER = AttacherJoints.registerJointType("cutter")
AttacherJoints.JOINTTYPE_CUTTERHARVESTER = AttacherJoints.registerJointType("cutterHarvester")
AttacherJoints.JOINTTYPE_CUTTERTRAILER = AttacherJoints.registerJointType("cutterTrailer")
AttacherJoints.JOINTTYPE_SKIDSTEER = AttacherJoints.registerJointType("skidSteer")
AttacherJoints.JOINTTYPE_CONVEYOR = AttacherJoints.registerJointType("conveyor")
AttacherJoints.JOINTTYPE_HOOKLIFT = AttacherJoints.registerJointType("hookLift")
AttacherJoints.JOINTTYPE_BIGBAG = AttacherJoints.registerJointType("bigBag")
AttacherJoints.JOINTTYPE_TRAIN = AttacherJoints.registerJointType("train")
function AttacherJoints.prerequisitesPresent(specializations)
    return true
end
function AttacherJoints.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onPreAttachImplement")
    SpecializationUtil.registerEvent(vehicleType, "onPostAttachImplement")
    SpecializationUtil.registerEvent(vehicleType, "onPreDetachImplement")
    SpecializationUtil.registerEvent(vehicleType, "onPostDetachImplement")
    SpecializationUtil.registerEvent(vehicleType, "onRequiresTopLightsChanged")
end
function AttacherJoints.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadAttachmentsFinished", AttacherJoints.loadAttachmentsFinished)
    SpecializationUtil.registerFunction(vehicleType, "handleLowerImplementEvent", AttacherJoints.handleLowerImplementEvent)
    SpecializationUtil.registerFunction(vehicleType, "handleLowerImplementByAttacherJointIndex", AttacherJoints.handleLowerImplementByAttacherJointIndex)
    SpecializationUtil.registerFunction(vehicleType, "getAttachedImplements", AttacherJoints.getAttachedImplements)
    SpecializationUtil.registerFunction(vehicleType, "getAttacherJoints", AttacherJoints.getAttacherJoints)
    SpecializationUtil.registerFunction(vehicleType, "getAttacherJointByJointDescIndex", AttacherJoints.getAttacherJointByJointDescIndex)
    SpecializationUtil.registerFunction(vehicleType, "getAttacherJointIndexByNode", AttacherJoints.getAttacherJointIndexByNode)
    SpecializationUtil.registerFunction(vehicleType, "getAttacherJointByNode", AttacherJoints.getAttacherJointByNode)
    SpecializationUtil.registerFunction(vehicleType, "getImplementFromAttacherJointIndex", AttacherJoints.getImplementFromAttacherJointIndex)
    SpecializationUtil.registerFunction(vehicleType, "getAttacherJointIndexFromObject", AttacherJoints.getAttacherJointIndexFromObject)
    SpecializationUtil.registerFunction(vehicleType, "getAttacherJointDescFromObject", AttacherJoints.getAttacherJointDescFromObject)
    SpecializationUtil.registerFunction(vehicleType, "getAttacherJointIndexFromImplementIndex", AttacherJoints.getAttacherJointIndexFromImplementIndex)
    SpecializationUtil.registerFunction(vehicleType, "getObjectFromImplementIndex", AttacherJoints.getObjectFromImplementIndex)
    SpecializationUtil.registerFunction(vehicleType, "updateAttacherJointGraphics", AttacherJoints.updateAttacherJointGraphics)
    SpecializationUtil.registerFunction(vehicleType, "calculateAttacherJointMoveUpperLowerAlpha", AttacherJoints.calculateAttacherJointMoveUpperLowerAlpha)
    SpecializationUtil.registerFunction(vehicleType, "doGroundHeightNodeCheck", AttacherJoints.doGroundHeightNodeCheck)
    SpecializationUtil.registerFunction(vehicleType, "finishGroundHeightNodeCheck", AttacherJoints.finishGroundHeightNodeCheck)
    SpecializationUtil.registerFunction(vehicleType, "groundHeightNodeCheckCallback", AttacherJoints.groundHeightNodeCheckCallback)
    SpecializationUtil.registerFunction(vehicleType, "updateAttacherJointRotation", AttacherJoints.updateAttacherJointRotation)
    SpecializationUtil.registerFunction(vehicleType, "updateAttacherJointRotationNodes", AttacherJoints.updateAttacherJointRotationNodes)
    SpecializationUtil.registerFunction(vehicleType, "updateAttacherJointSettingsByObject", AttacherJoints.updateAttacherJointSettingsByObject)
    SpecializationUtil.registerFunction(vehicleType, "setAttacherJointBottomArmWidth", AttacherJoints.setAttacherJointBottomArmWidth)
    SpecializationUtil.registerFunction(vehicleType, "attachImplementFromInfo", AttacherJoints.attachImplementFromInfo)
    SpecializationUtil.registerFunction(vehicleType, "attachImplement", AttacherJoints.attachImplement)
    SpecializationUtil.registerFunction(vehicleType, "postAttachImplement", AttacherJoints.postAttachImplement)
    SpecializationUtil.registerFunction(vehicleType, "createAttachmentJoint", AttacherJoints.createAttachmentJoint)
    SpecializationUtil.registerFunction(vehicleType, "hardAttachImplement", AttacherJoints.hardAttachImplement)
    SpecializationUtil.registerFunction(vehicleType, "hardDetachImplement", AttacherJoints.hardDetachImplement)
    SpecializationUtil.registerFunction(vehicleType, "detachImplement", AttacherJoints.detachImplement)
    SpecializationUtil.registerFunction(vehicleType, "detachImplementByObject", AttacherJoints.detachImplementByObject)
    SpecializationUtil.registerFunction(vehicleType, "playAttachSound", AttacherJoints.playAttachSound)
    SpecializationUtil.registerFunction(vehicleType, "playDetachSound", AttacherJoints.playDetachSound)
    SpecializationUtil.registerFunction(vehicleType, "detachingIsPossible", AttacherJoints.detachingIsPossible)
    SpecializationUtil.registerFunction(vehicleType, "attachAdditionalAttachment", AttacherJoints.attachAdditionalAttachment)
    SpecializationUtil.registerFunction(vehicleType, "detachAdditionalAttachment", AttacherJoints.detachAdditionalAttachment)
    SpecializationUtil.registerFunction(vehicleType, "getImplementIndexByJointDescIndex", AttacherJoints.getImplementIndexByJointDescIndex)
    SpecializationUtil.registerFunction(vehicleType, "getImplementByJointDescIndex", AttacherJoints.getImplementByJointDescIndex)
    SpecializationUtil.registerFunction(vehicleType, "getImplementIndexByObject", AttacherJoints.getImplementIndexByObject)
    SpecializationUtil.registerFunction(vehicleType, "getImplementByObject", AttacherJoints.getImplementByObject)
    SpecializationUtil.registerFunction(vehicleType, "callFunctionOnAllImplements", AttacherJoints.callFunctionOnAllImplements)
    SpecializationUtil.registerFunction(vehicleType, "activateAttachments", AttacherJoints.activateAttachments)
    SpecializationUtil.registerFunction(vehicleType, "deactivateAttachments", AttacherJoints.deactivateAttachments)
    SpecializationUtil.registerFunction(vehicleType, "deactivateAttachmentsLights", AttacherJoints.deactivateAttachmentsLights)
    SpecializationUtil.registerFunction(vehicleType, "setJointMoveDown", AttacherJoints.setJointMoveDown)
    SpecializationUtil.registerFunction(vehicleType, "getJointMoveDown", AttacherJoints.getJointMoveDown)
    SpecializationUtil.registerFunction(vehicleType, "getIsHardAttachAllowed", AttacherJoints.getIsHardAttachAllowed)
    SpecializationUtil.registerFunction(vehicleType, "getIsSmoothAttachUpdateAllowed", AttacherJoints.getIsSmoothAttachUpdateAllowed)
    SpecializationUtil.registerFunction(vehicleType, "loadAttacherJointFromXML", AttacherJoints.loadAttacherJointFromXML)
    SpecializationUtil.registerFunction(vehicleType, "onBottomArmToolbarI3DLoaded", AttacherJoints.onBottomArmToolbarI3DLoaded)
    SpecializationUtil.registerFunction(vehicleType, "setSelectedImplementByObject", AttacherJoints.setSelectedImplementByObject)
    SpecializationUtil.registerFunction(vehicleType, "getSelectedImplement", AttacherJoints.getSelectedImplement)
    SpecializationUtil.registerFunction(vehicleType, "getCanToggleAttach", AttacherJoints.getCanToggleAttach)
    SpecializationUtil.registerFunction(vehicleType, "getShowAttachControlBarAction", AttacherJoints.getShowAttachControlBarAction)
    SpecializationUtil.registerFunction(vehicleType, "getAttachControlBarActionAccessible", AttacherJoints.getAttachControlBarActionAccessible)
    SpecializationUtil.registerFunction(vehicleType, "detachAttachedImplement", AttacherJoints.detachAttachedImplement)
    SpecializationUtil.registerFunction(vehicleType, "startAttacherJointCombo", AttacherJoints.startAttacherJointCombo)
    SpecializationUtil.registerFunction(vehicleType, "registerSelfLoweringActionEvent", AttacherJoints.registerSelfLoweringActionEvent)
    SpecializationUtil.registerFunction(vehicleType, "getIsAttachingAllowed", AttacherJoints.getIsAttachingAllowed)
    SpecializationUtil.registerFunction(vehicleType, "getIsAttacherJointCompatible", AttacherJoints.getIsAttacherJointCompatible)
    SpecializationUtil.registerFunction(vehicleType, "getCanSteerAttachable", AttacherJoints.getCanSteerAttachable)
    SpecializationUtil.registerFunction(vehicleType, "onAttacherJointsVehicleLoaded", AttacherJoints.onAttacherJointsVehicleLoaded)
    SpecializationUtil.registerFunction(vehicleType, "getAttachableInfo", AttacherJoints.getAttachableInfo)
    SpecializationUtil.registerFunction(vehicleType, "setAttacherJointBlocked", AttacherJoints.setAttacherJointBlocked)
end
function AttacherJoints.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "raiseActive", AttacherJoints.raiseActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerActionEvents", AttacherJoints.registerActionEvents)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeActionEvents", AttacherJoints.removeActionEvents)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", AttacherJoints.addToPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", AttacherJoints.removeFromPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTotalMass", AttacherJoints.getTotalMass)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAdditionalComponentMass", AttacherJoints.getAdditionalComponentMass)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addChildVehicles", AttacherJoints.addChildVehicles)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAirConsumerUsage", AttacherJoints.getAirConsumerUsage)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRequiresPower", AttacherJoints.getRequiresPower)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addVehicleToAIImplementList", AttacherJoints.addVehicleToAIImplementList)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "collectAIAgentAttachments", AttacherJoints.collectAIAgentAttachments)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setAIVehicleObstacleStateDirty", AttacherJoints.setAIVehicleObstacleStateDirty)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirectionSnapAngle", AttacherJoints.getDirectionSnapAngle)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation", AttacherJoints.getFillLevelInformation)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getHasObjectMounted", AttacherJoints.getHasObjectMounted)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "attachableAddToolCameras", AttacherJoints.attachableAddToolCameras)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "attachableRemoveToolCameras", AttacherJoints.attachableRemoveToolCameras)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerSelectableObjects", AttacherJoints.registerSelectableObjects)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsReadyForAutomatedTrainTravel", AttacherJoints.getIsReadyForAutomatedTrainTravel)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAutomaticShiftingAllowed", AttacherJoints.getIsAutomaticShiftingAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", AttacherJoints.loadDashboardGroupFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", AttacherJoints.getIsDashboardGroupActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAttacherJointHeightNode", AttacherJoints.loadAttacherJointHeightNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAttacherJointHeightNodeActive", AttacherJoints.getIsAttacherJointHeightNodeActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadTipSide", AttacherJoints.loadTipSide)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsTipSideAvailable", AttacherJoints.getIsTipSideAvailable)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadFillUnitFromXML", AttacherJoints.loadFillUnitFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitSupportsToolType", AttacherJoints.getFillUnitSupportsToolType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", AttacherJoints.isDetachAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", AttacherJoints.getIsFoldAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWheelFoliageDestructionAllowed", AttacherJoints.getIsWheelFoliageDestructionAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", AttacherJoints.getAreControlledActionsAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConnectionHoseConfigIndex", AttacherJoints.getConnectionHoseConfigIndex)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getPowerTakeOffConfigIndex", AttacherJoints.getPowerTakeOffConfigIndex)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadHoseTargetNode", AttacherJoints.loadHoseTargetNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsConnectionTargetUsed", AttacherJoints.getIsConnectionTargetUsed)
end
function AttacherJoints.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onPreDelete", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateInterpolation", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onStateChange", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onLightsTypesMaskChanged", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnLightStateChanged", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onBrakeLightsVisibilityChanged", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onReverseLightsVisibilityChanged", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onBeaconLightsVisibilityChanged", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onBrake", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onActivate", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onReverseDirectionChanged", AttacherJoints)
end
function AttacherJoints:onPreLoad(_)
    local spec = self.spec_attacherJoints
    spec.attachedImplements = {}
    spec.selectedImplement = nil
    spec.lastInputAttacherCheckIndex = 0
end
function AttacherJoints:onLoad(_)
    local spec = self.spec_attacherJoints
    spec.attacherJointCombos = {}
    spec.attacherJointCombos.duration = self.xmlFile:getValue("vehicle.attacherJoints#comboDuration", 2) * 1000
    spec.attacherJointCombos.currentTime = 0
    spec.attacherJointCombos.direction = -1
    spec.attacherJointCombos.isRunning = false
    spec.attacherJointCombos.joints = {}
    spec.maxUpdateDistance = self.xmlFile:getValue("vehicle.attacherJoints#maxUpdateDistance", AttacherJoints.DEFAULT_MAX_UPDATE_DISTANCE)
    spec.visualNodeToAttacherJoints = {}
    spec.hideVisualNodeToAttacherJoints = {}
    spec.attacherJoints = {}
    local i = 0
    while true do
        local baseName = string.format("vehicle.attacherJoints.attacherJoint(%d)", i)
        if not self.xmlFile:hasProperty(baseName) then
            break
        end
        local attacherJoint = {}
        if self:loadAttacherJointFromXML(attacherJoint, self.xmlFile, baseName, i) then
            table.insert(spec.attacherJoints, attacherJoint)
            attacherJoint.index = #spec.attacherJoints
        end
        i = i + 1
    end
    spec.attachableInfo = {}
    spec.attachableInfo.attacherVehicle = nil
    spec.attachableInfo.attacherVehicleJointDescIndex = nil
    spec.attachableInfo.attachable = nil
    spec.attachableInfo.attachableJointDescIndex = nil
    spec.pendingAttachableInfo = {}
    spec.pendingAttachableInfo.minDistance = math.huge
    spec.pendingAttachableInfo.minDistanceY = math.huge
    spec.pendingAttachableInfo.attacherVehicle = nil
    spec.pendingAttachableInfo.attacherVehicleJointDescIndex = nil
    spec.pendingAttachableInfo.attachable = nil
    spec.pendingAttachableInfo.attachableJointDescIndex = nil
    spec.pendingAttachableInfo.warning = nil
    if self.isClient then
        spec.samples = {}
        spec.isHydraulicSamplePlaying = false
        spec.samples.hydraulic = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.attacherJoints.sounds", "hydraulic", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.attach = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.attacherJoints.sounds", "attach", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.detach = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.attacherJoints.sounds", "detach", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    if self.isClient and g_isDevelopmentVersion then
        for k, attacherJoint in ipairs(spec.attacherJoints) do
            if spec.samples.attach == nil and attacherJoint.sampleAttach == nil then
                Logging.xmlDevWarning(self.xmlFile, "Missing attach sound for attacherjoint \'%d\'", k)
            end
            if attacherJoint.rotationNode ~= nil and spec.samples.hydraulic == nil then
                Logging.xmlDevWarning(self.xmlFile, "Missing hydraulic sound for attacherjoint \'%d\'", k)
            end
        end
    end
    spec.showAttachNotAllowedText = 0
    spec.wasInAttachRange = false
    spec.texts = {}
    spec.texts.warningToolNotCompatible = g_i18n:getText("warning_toolNotCompatible")
    spec.texts.warningToolBrandNotCompatible = g_i18n:getText("warning_toolBrandNotCompatible")
    spec.texts.infoAttachNotAllowed = g_i18n:getText("info_attach_not_allowed")
    spec.texts.lowerImplementFirst = g_i18n:getText("warning_lowerImplementFirst")
    spec.texts.detachNotAllowed = g_i18n:getText("warning_detachNotAllowed")
    spec.texts.actionAttach = g_i18n:getText("action_attach")
    spec.texts.actionDetach = g_i18n:getText("action_detach")
    spec.texts.warningFoldingAttacherJoint = g_i18n:getText("warning_foldingNotWhileAttachedToAttacherJoint")
    spec.groundHeightNodeCheckData = {
        ["isDirty"] = false,
        ["minDistance"] = math.huge,
        ["hit"] = false,
        ["raycastDistance"] = 1,
        ["currentRaycastDistance"] = 1,
        ["heightNodes"] = {},
        ["jointDesc"] = {},
        ["index"] = -1,
        ["lowerDistanceToGround"] = 0,
        ["upperDistanceToGround"] = 0,
        ["currentRaycastWorldPos"] = { 0, 0, 0 },
        ["currentRaycastWorldDir"] = { 0, 0, 0 },
        ["currentJointTransformPos"] = { 0, 0, 0 },
        ["raycastWorldPos"] = { 0, 0, 0 },
        ["raycastWorldDir"] = { 0, 0, 0 },
        ["jointTransformPos"] = { 0, 0, 0 },
        ["upperAlpha"] = 0,
        ["lowerAlpha"] = 0
    }
    spec.dirtyFlag = self:getNextDirtyFlag()
end
function AttacherJoints:onPostLoad(savegame)
    local spec = self.spec_attacherJoints
    for attacherJointIndex, attacherJoint in pairs(spec.attacherJoints) do
        attacherJoint.jointOrigRot = { getRotation(attacherJoint.jointTransform) }
        attacherJoint.jointOrigTrans = { getTranslation(attacherJoint.jointTransform) }
        if attacherJoint.transNode ~= nil then
            attacherJoint.transNodeMinY = Utils.getNoNil(attacherJoint.transNodeMinY, attacherJoint.jointOrigTrans[2])
            attacherJoint.transNodeMaxY = Utils.getNoNil(attacherJoint.transNodeMaxY, attacherJoint.jointOrigTrans[2])
            local xDir, yDir, _ = localToLocal(attacherJoint.jointTransform, attacherJoint.transNode, 0, 0, 0)
            attacherJoint.transNodeOffsetY = yDir
            local xDir, yDir, _ = localToLocal(getParent(attacherJoint.transNode), attacherJoint.rootNode, 0, attacherJoint.transNodeMinY, 0)
            attacherJoint.transNodeMinY = yDir
            local xDir, yDir, _ = localToLocal(getParent(attacherJoint.transNode), attacherJoint.rootNode, 0, attacherJoint.transNodeMaxY, 0)
            attacherJoint.transNodeMaxY = yDir
        end
        if attacherJoint.transNodeDependentBottomArm ~= nil then
            for _, attacherJoint2 in pairs(spec.attacherJoints) do
                if attacherJoint2.bottomArm ~= nil and attacherJoint2.bottomArm.rotationNode == attacherJoint.transNodeDependentBottomArm then
                    attacherJoint.transNodeDependentBottomArmAttacherJoint = attacherJoint2
                end
            end
            if attacherJoint.transNodeDependentBottomArmAttacherJoint == nil then
                Logging.xmlWarning(self.xmlFile, "Unable to find dependent bottom arm \'%s\' in any attacher joint.", getName(attacherJoint.transNodeDependentBottomArm))
                attacherJoint.transNodeDependentBottomArm = nil
            end
        end
        if attacherJoint.bottomArm ~= nil then
            setRotation(attacherJoint.bottomArm.rotationNode, attacherJoint.bottomArm.rotX, attacherJoint.bottomArm.rotY, attacherJoint.bottomArm.rotZ)
            if self.setMovingToolDirty ~= nil then
                self:setMovingToolDirty(attacherJoint.bottomArm.rotationNode)
            end
        end
        if attacherJoint.rotationNode ~= nil then
            setRotation(attacherJoint.rotationNode, attacherJoint.rotX, attacherJoint.rotY, attacherJoint.rotZ)
        end
        if attacherJoint.visualAlignNodes ~= nil then
            for _, attacherJoint2 in ipairs(attacherJoint.visualAlignNodes) do
                self:setMovingPartReferenceNode(attacherJoint2.node, attacherJoint.jointTransform, false)
            end
        end
        if self.getInputAttacherJoints ~= nil then
            attacherJoint.inputAttacherJointOffsets = {}
            for _, attacherJoint2 in ipairs(self:getInputAttacherJoints()) do
                local xDir, yDir, zDir = localDirectionToLocal(attacherJoint.jointTransform, attacherJoint2.node, 0, 0, 1)
                local xUp, yUp, zUp = localDirectionToLocal(attacherJoint.jointTransform, attacherJoint2.node, 0, 1, 0)
                local xNorm, yNorm, zNorm = localDirectionToLocal(attacherJoint.jointTransform, attacherJoint2.node, 1, 0, 0)
                local xOffset, yOffset, zOffset = localToLocal(attacherJoint.jointTransform, attacherJoint2.node, 0, 0, 0)
                table.insert(attacherJoint.inputAttacherJointOffsets, {
                    xOffset,
                    yOffset,
                    zOffset,
                    xDir,
                    yDir,
                    zDir,
                    xUp,
                    yUp,
                    zUp,
                    xNorm,
                    yNorm,
                    zNorm
                })
            end
        end
        if self.getAIRootNode ~= nil then
            local _ = self:getAIRootNode()
            local xDir, yDir, _ = localDirectionToLocal(attacherJoint.jointTransform, _, 0, 0, 1)
            local attacherJoint2, xDir, yDir = localDirectionToLocal(attacherJoint.jointTransform, _, 0, 1, 0)
            local zDir, xUp, yUp = localDirectionToLocal(attacherJoint.jointTransform, _, 1, 0, 0)
            local zUp, xNorm, yNorm = localToLocal(attacherJoint.jointTransform, _, 0, 0, 0)
            attacherJoint.aiRootNodeOffset = {
                zUp,
                xNorm,
                yNorm,
                xDir,
                yDir,
                _,
                attacherJoint2,
                xDir,
                yDir,
                zDir,
                xUp,
                yUp
            }
        end
        if attacherJoint.comboTime ~= nil then
            ({
                ["jointIndex"] = attacherJointIndex
            }).time = math.clamp(attacherJoint.comboTime, 0, 1) * spec.attacherJointCombos.duration
            _.initialTime = _.time
            table.insert(spec.attacherJointCombos.joints, _)
        end
        self:setAttacherJointBottomArmWidth(attacherJointIndex, nil)
    end
    if savegame ~= nil and (not savegame.resetVehicles and spec.attacherJointCombos ~= nil) then
        local comboDirection = savegame.xmlFile:getValue(savegame.key .. ".attacherJoints#comboDirection")
        if comboDirection ~= nil then
            spec.attacherJointCombos.direction = comboDirection
            if comboDirection == 1 then
                spec.attacherJointCombos.currentTime = spec.attacherJointCombos.duration
            end
        end
    end
    if #spec.attacherJoints == 0 then
        SpecializationUtil.removeEventListener(self, "onReadStream", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onWriteStream", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onUpdateInterpolation", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onUpdate", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onUpdateEnd", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onStateChange", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onLightsTypesMaskChanged", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onTurnLightStateChanged", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onBrakeLightsVisibilityChanged", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onReverseLightsVisibilityChanged", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onBeaconLightsVisibilityChanged", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onBrake", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onTurnedOn", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onTurnedOff", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onLeaveVehicle", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onActivate", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onDeactivate", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onReverseDirectionChanged", AttacherJoints)
    end
end
function AttacherJoints:onLoadFinished(savegame)
    if savegame ~= nil and (not savegame.resetVehicles or savegame.keepPosition) then
        self.spec_attacherJoints.attachmentDataToLoad = {}
        local xmlFile = savegame.xmlFile
        for index, attachedImplementKey in xmlFile:iterator(savegame.key .. ".attacherJoints.attachedImplement") do
            local attachmentData = {
                ["jointIndex"] = xmlFile:getValue(attachedImplementKey .. "#jointIndex"),
                ["attachedVehicleUniqueId"] = xmlFile:getValue(attachedImplementKey .. "#attachedVehicleUniqueId"),
                ["inputIndex"] = xmlFile:getValue(attachedImplementKey .. "#inputJointIndex"),
                ["moveDown"] = xmlFile:getValue(attachedImplementKey .. "#moveDown", false)
            }
            if attachmentData.jointIndex ~= nil and (attachmentData.attachedVehicleUniqueId ~= nil and attachmentData.inputIndex ~= nil) then
                local vehicle = g_currentMission.vehicleSystem:getVehicleByUniqueId(attachmentData.attachedVehicleUniqueId)
                if vehicle == nil then
                    table.insert(spec.attachmentDataToLoad, attachmentData)
                else
                    self:attachImplement(vehicle, attachmentData.inputIndex, attachmentData.jointIndex, true, nil, attachmentData.moveDown, true, true)
                    self:setJointMoveDown(attachmentData.jointIndex, attachmentData.moveDown, true)
                end
            end
        end
        for index, attachedImplementKey in xmlFile:iterator(savegame.key .. ".attacherJoints.attacherJoint") do
            local jointIndex = xmlFile:getValue(attachedImplementKey .. "#jointIndex")
            spec.attacherJoints[jointIndex].isBlocked = xmlFile:getValue(attachedImplementKey .. "#isBlocked") or spec.attacherJoints[jointIndex].isBlocked
        end
        if #spec.attachmentDataToLoad > 0 then
            g_messageCenter:subscribe(MessageType.VEHICLE_LOADED, self.onAttacherJointsVehicleLoaded, self)
        end
    end
end
function AttacherJoints:onRegisterDashboardValueTypes()
    local spec = self.spec_attacherJoints
    local function loadAttacherJointNodeFunc(_, xmlFile, key, dashboard, _)
        -- upvalues: (copy) self
        dashboard.attacherJointNode = xmlFile:getValue(key .. "#attacherJointNode", nil, self.components, self.i3dMappings)
        if dashboard.attacherJointNode ~= nil then
            return true
        end
        dashboard.attacherJointNodes = xmlFile:getValue(key .. "#attacherJointNodes", nil, self.components, self.i3dMappings, true)
        return #dashboard.attacherJointNodes ~= 0
    end
    local function setAttacherJointFromNodes(dashboard)
        -- upvalues: (copy) self
        if dashboard.attacherJointNode ~= nil then
            local attacherJoint = self:getAttacherJointByNode(dashboard.attacherJointNode)
            if attacherJoint == nil or attacherJoint.bottomArm == nil then
                dashboard.attacherJointNode = nil
            else
                dashboard.attacherJoint = attacherJoint
            end
        end
        if dashboard.attacherJointNodes ~= nil then
            for _, attacherJointNode in ipairs(dashboard.attacherJointNodes) do
                local attacherJoint = self:getAttacherJointByNode(attacherJointNode)
                if attacherJoint ~= nil and attacherJoint.bottomArm ~= nil then
                    dashboard.attacherJoint = attacherJoint
                    break
                end
            end
            if dashboard.attacherJoint == nil then
                dashboard.attacherJointNodes = nil
            end
        end
    end
    local bottomArmPosition = DashboardValueType.new("attacherJoints", "bottomArmPosition")
    bottomArmPosition:setValue(spec, function(_, dashboard)
        -- upvalues: (copy) setAttacherJointFromNodes
        if dashboard.attacherJoint == nil then
            setAttacherJointFromNodes(dashboard)
            if dashboard.attacherJoint == nil then
                return 0
            end
        end
        return 1 - (dashboard.attacherJoint.moveAlpha or 0)
    end)
    bottomArmPosition:setAdditionalFunctions(loadAttacherJointNodeFunc)
    bottomArmPosition:setValueFactor(100)
    bottomArmPosition:setRange(0, 100)
    bottomArmPosition:setPollUpdate(false)
    self:registerDashboardValueType(bottomArmPosition)
    local bottomArmPositionMin = DashboardValueType.new("attacherJoints", "bottomArmPositionMin")
    bottomArmPositionMin:setValue(spec, function(_, dashboard)
        -- upvalues: (copy) setAttacherJointFromNodes
        if dashboard.attacherJoint == nil then
            setAttacherJointFromNodes(dashboard)
            if dashboard.attacherJoint == nil then
                return 0
            end
        end
        return 1 - (dashboard.attacherJoint.lowerAlpha or 1)
    end)
    bottomArmPositionMin:setAdditionalFunctions(loadAttacherJointNodeFunc)
    bottomArmPositionMin:setValueFactor(100)
    bottomArmPositionMin:setRange(0, 100)
    bottomArmPositionMin:setPollUpdate(false)
    self:registerDashboardValueType(bottomArmPositionMin)
    local bottomArmPositionMax = DashboardValueType.new("attacherJoints", "bottomArmPositionMax")
    bottomArmPositionMax:setValue(spec, function(_, dashboard)
        -- upvalues: (copy) setAttacherJointFromNodes
        if dashboard.attacherJoint == nil then
            setAttacherJointFromNodes(dashboard)
            if dashboard.attacherJoint == nil then
                return 0
            end
        end
        return 1 - (dashboard.attacherJoint.upperAlpha or 0)
    end)
    bottomArmPositionMax:setAdditionalFunctions(loadAttacherJointNodeFunc)
    bottomArmPositionMax:setValueFactor(100)
    bottomArmPositionMax:setRange(0, 100)
    bottomArmPositionMax:setPollUpdate(false)
    self:registerDashboardValueType(bottomArmPositionMax)
end
function AttacherJoints:onPreDelete()
    local spec = self.spec_attacherJoints
    if spec.attachedImplements ~= nil then
        local i = #spec.attachedImplements
        for i = i, 1, -1 do
            local implement = spec.attachedImplements[i]
            if not implement.object:getIsAdditionalAttachment() then
                self:detachImplementByObject(implement.object, true)
            end
        end
    end
end
function AttacherJoints:onDelete()
    local spec = self.spec_attacherJoints
    if spec.attacherJoints ~= nil then
        for _, jointDesc in pairs(spec.attacherJoints) do
            g_soundManager:deleteSample(jointDesc.sampleAttach)
            g_soundManager:deleteSample(jointDesc.sampleDetach)
            if jointDesc.topArm ~= nil then
                jointDesc.topArm:delete()
                jointDesc.topArm = nil
            end
            local bottomArm = jointDesc.bottomArm
            if bottomArm ~= nil and bottomArm.sharedLoadRequestIdToolbar ~= nil then
                g_i3DManager:releaseSharedI3DFile(bottomArm.sharedLoadRequestIdToolbar)
                bottomArm.sharedLoadRequestIdToolbar = nil
            end
        end
        g_soundManager:deleteSamples(spec.samples)
    end
end
function AttacherJoints:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_attacherJoints
    if spec.attacherJointCombos ~= nil then
        xmlFile:setValue(key .. "#comboDirection", spec.attacherJointCombos.direction)
    end
    if spec.attacherJoints ~= nil then
        for index, implement in ipairs(spec.attachedImplements) do
            if implement.object ~= nil then
                local attacherJointKey = string.format("%s.attachedImplement(%d)", key, index - 1)
                local jointDesc = self:getAttacherJointByJointDescIndex(implement.jointDescIndex)
                xmlFile:setValue(attacherJointKey .. "#jointIndex", implement.jointDescIndex)
                xmlFile:setValue(attacherJointKey .. "#moveDown", jointDesc.moveDown)
                xmlFile:setValue(attacherJointKey .. "#attachedVehicleUniqueId", implement.object:getUniqueId())
                xmlFile:setValue(attacherJointKey .. "#inputJointIndex", implement.inputJointDescIndex)
            end
        end
        local index = 0
        for implement, attacherJointKey in pairs(spec.attacherJoints) do
            if attacherJointKey.isBlocked then
                local jointDesc = string.format("%s.attacherJoint(%d)", key, index)
                xmlFile:setValue(jointDesc .. "#jointIndex", implement)
                xmlFile:setValue(jointDesc .. "#isBlocked", attacherJointKey.isBlocked)
                index = index + 1
            end
        end
    end
end
function AttacherJoints:onReadStream(streamId, _)
    local numImplements = streamReadInt8(streamId)
    local i = 1
    for i = i, numImplements do
        local object = NetworkUtil.readNodeObject(streamId)
        local inputJointDescIndex = streamReadInt8(streamId)
        local jointDescIndex = streamReadInt8(streamId)
        local moveDown = streamReadBool(streamId)
        if object ~= nil and object:getIsSynchronized() then
            self:attachImplement(object, inputJointDescIndex, jointDescIndex, true, i, moveDown, true, true)
            self:setJointMoveDown(jointDescIndex, moveDown, true)
        end
    end
end
function AttacherJoints:onWriteStream(streamId, _)
    local spec = self.spec_attacherJoints
    streamWriteInt8(streamId, #spec.attachedImplements)
    local i = 1
    for i = i, #spec.attachedImplements do
        local implement = spec.attachedImplements[i]
        local jointDescIndex = implement.jointDescIndex
        NetworkUtil.writeNodeObject(streamId, implement.object)
        streamWriteInt8(streamId, implement.object.spec_attachable.inputAttacherJointDescIndex)
        streamWriteInt8(streamId, jointDescIndex)
        streamWriteBool(streamId, spec.attacherJoints[jointDescIndex].moveDown)
    end
end
function AttacherJoints:onUpdateInterpolation(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_attacherJoints
    if self.currentUpdateDistance < spec.maxUpdateDistance then
        for _, implement in pairs(spec.attachedImplements) do
            if implement.object ~= nil and self.updateLoopIndex == implement.object.updateLoopIndex then
                self:updateAttacherJointGraphics(implement, dt, true)
                implement.object:updateInputAttacherJointGraphics(implement, dt)
            end
        end
    end
    for _, implement in pairs(spec.attachedImplements) do
        if implement.object ~= nil and implement.object.spec_attachable.isHardAttached then
            SpecializationUtil.raiseEvent(implement.object, "onUpdateInterpolation", dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
        end
    end
end
function AttacherJoints:onUpdate(dt, _, _, _)
    local spec = self.spec_attacherJoints
    if self.isClient then
        spec.showAttachNotAllowedText = math.max(spec.showAttachNotAllowedText - dt, 0)
        if spec.showAttachNotAllowedText > 0 then
            g_currentMission:addExtraPrintText(spec.texts.infoAttachNotAllowed)
        end
    end
    if Platform.gameplay.automaticAttach and self.isServer or self.isClient and (spec.actionEvents ~= nil and spec.actionEvents[InputAction.ATTACH] ~= nil) then
        if self:getCanToggleAttach() then
            AttacherJoints.updateVehiclesInAttachRange(self, AttacherJoints.MAX_ATTACH_DISTANCE_SQ, AttacherJoints.MAX_ATTACH_ANGLE, true)
            return
        end
        spec.attachableInfo.attacherVehicle = nil
        info.attacherVehicleJointDescIndex = nil
        info.attachable = nil
        info.attachableJointDescIndex = nil
    end
end
function AttacherJoints:onUpdateEnd(dt, _, _, _)
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        if implement.object ~= nil and self.updateLoopIndex == implement.object.updateLoopIndex then
            self:updateAttacherJointGraphics(implement, dt, true)
        end
    end
end
function AttacherJoints:onUpdateTick(dt, _, _, _)
    local spec = self.spec_attacherJoints
    local playHydraulicSound = false
    for _, implement in pairs(spec.attachedImplements) do
        if implement.object ~= nil then
            if not implement.object.spec_attachable.isHardAttached then
                if self.isServer and (implement.attachingIsInProgress and self:getIsSmoothAttachUpdateAllowed(implement)) then
                    local done = true
                    local i = 1
                    for i = i, 3 do
                        implement.attachingRotLimit[i] = math.max(0, implement.attachingRotLimit[i] - implement.attachingRotLimitSpeed[i] * dt)
                        implement.attachingTransLimit[i] = math.max(0, implement.attachingTransLimit[i] - implement.attachingTransLimitSpeed[i] * dt)
                        if implement.attachingRotLimit[i] > 0 or (implement.attachingTransLimit[i] > 0 or (implement.attachingRotLimit[i] > 0 or implement.attachingTransLimit[i] > 0)) then
                            done = false
                        end
                    end
                    implement.attachingIsInProgress = not done
                    if done then
                        if implement.object.spec_attachable.attacherJoint.hardAttach and self:getIsHardAttachAllowed(implement.jointDescIndex) then
                            self:hardAttachImplement(implement)
                        end
                        self:postAttachImplement(implement)
                    end
                end
                if not implement.attachingIsInProgress then
                    local done = false
                    if spec.attacherJoints[implement.jointDescIndex].allowsLowering and self:getIsActive() then
                        local upperAlpha = jointDesc.upperAlpha
                        local lowerAlpha = jointDesc.lowerAlpha
                        if jointDesc.moveDown then
                            upperAlpha, lowerAlpha = self:calculateAttacherJointMoveUpperLowerAlpha(jointDesc, implement.object)
                            jointDesc.moveTime = jointDesc.moveDefaultTime * math.abs(upperAlpha - lowerAlpha)
                        end
                        local i = Utils.getMovedLimitedValue(jointDesc.moveAlpha, lowerAlpha, upperAlpha, jointDesc.moveTime, dt, not jointDesc.moveDown)
                        if i ~= jointDesc.moveAlpha or (upperAlpha ~= jointDesc.upperAlpha or lowerAlpha ~= jointDesc.lowerAlpha) then
                            jointDesc.upperAlpha = upperAlpha
                            jointDesc.lowerAlpha = lowerAlpha
                            if jointDesc.moveDown then
                                if math.abs(jointDesc.moveAlpha - jointDesc.lowerAlpha) < 0.05 then
                                    jointDesc.isMoving = false
                                end
                            elseif math.abs(jointDesc.moveAlpha - jointDesc.upperAlpha) < 0.05 then
                                jointDesc.isMoving = false
                            end
                            playHydraulicSound = jointDesc.isMoving
                            jointDesc.moveAlpha = i
                            if jointDesc.upperAlpha - jointDesc.lowerAlpha == 0 then
                                jointDesc.moveLimitAlpha = 1
                            else
                                jointDesc.moveLimitAlpha = 1 - (i - jointDesc.lowerAlpha) / (jointDesc.upperAlpha - jointDesc.lowerAlpha)
                            end
                            done = true
                            self:updateAttacherJointRotationNodes(jointDesc, jointDesc.moveAlpha)
                            self:updateAttacherJointRotation(jointDesc, implement.object)
                            if self.isClient and self.updateDashboardValueType ~= nil then
                                self:updateDashboardValueType("attacherJoints.bottomArmPosition")
                            end
                        end
                    end
                    if done or jointDesc.jointFrameInvalid then
                        jointDesc.jointFrameInvalid = false
                        if self.isServer then
                            setJointFrame(jointDesc.jointIndex, 0, jointDesc.jointTransform)
                        end
                    end
                end
                if self.isServer then
                    local done = implement.attachingIsInProgress
                    if (done or jointDesc.allowsLowering and jointDesc.allowsJointLimitMovement) and (jointDesc.jointIndex ~= nil and jointDesc.jointIndex ~= 0) then
                        if done or implement.object.spec_attachable.attacherJoint.allowsJointRotLimitMovement then
                            local upperAlpha = math.max(jointDesc.moveLimitAlpha - implement.rotLimitThreshold, 0) / (1 - implement.rotLimitThreshold)
                            local lastRotLimit = 1
                            for lastRotLimit = lastRotLimit, 3 do
                                AttacherJoints.updateAttacherJointRotationLimit(implement, jointDesc, lastRotLimit, done, upperAlpha)
                            end
                        end
                        if done or implement.object.spec_attachable.attacherJoint.allowsJointTransLimitMovement then
                            local upperAlpha = math.max(jointDesc.moveLimitAlpha - implement.transLimitThreshold, 0) / (1 - implement.transLimitThreshold)
                            local lastRotLimit = 1
                            for lastRotLimit = lastRotLimit, 3 do
                                AttacherJoints.updateAttacherJointTranslationLimit(implement, jointDesc, lastRotLimit, done, upperAlpha)
                            end
                        end
                    end
                end
            end
        end
    end
    if self.isClient and spec.samples.hydraulic ~= nil then
        local i = 1
        for i = i, #spec.attacherJoints do
            local _ = spec.attacherJoints[i]
            if _.bottomArm ~= nil and _.bottomArm.bottomArmInterpolating then
                playHydraulicSound = true
            end
        end
        if playHydraulicSound then
            if not spec.isHydraulicSamplePlaying then
                g_soundManager:playSample(spec.samples.hydraulic)
                spec.isHydraulicSamplePlaying = true
            end
        elseif spec.isHydraulicSamplePlaying then
            g_soundManager:stopSample(spec.samples.hydraulic)
            spec.isHydraulicSamplePlaying = false
        end
    end
    local combos = spec.attacherJointCombos
    if combos ~= nil and combos.isRunning then
        for implement, jointDesc in pairs(combos.joints) do
            local done = nil
            if combos.direction == 1 and combos.currentTime >= jointDesc.time then
                done = true
            elseif combos.direction == -1 and combos.currentTime <= combos.duration - jointDesc.time then
                done = false
            end
            if done ~= nil then
                local upperAlpha = self:getImplementFromAttacherJointIndex(jointDesc.jointIndex)
                if upperAlpha ~= nil and upperAlpha.object.setLoweredAll ~= nil then
                    upperAlpha.object:setLoweredAll(done, jointDesc.jointIndex)
                end
            end
        end
        if combos.direction == -1 and combos.currentTime == 0 or combos.direction == 1 and combos.currentTime == combos.duration then
            combos.isRunning = false
        end
        combos.currentTime = math.clamp(combos.currentTime + dt * combos.direction, 0, combos.duration)
    end
    AttacherJoints.updateActionEvents(self)
    if Platform.gameplay.automaticAttach and (self.isServer and self:getCanToggleAttach()) then
        local info = spec.attachableInfo
        if info.attachable == nil or (spec.wasInAttachRange or info.attacherVehicle ~= self) then
            if info.attachable == nil and spec.wasInAttachRange then
                spec.wasInAttachRange = false
            end
        elseif not (self.isReconfigurating or info.attachable.isReconfigurating) then
            local i, _ = info.attachable:isAttachAllowed(self:getActiveFarm(), info.attacherVehicle)
            if i then
                if spec.wasInAttachRange == nil then
                    spec.wasInAttachRange = true
                else
                    self:attachImplementFromInfo(info)
                end
            end
            if _ ~= nil then
                g_currentMission:showBlinkingWarning(_, 2000)
                return
            end
        end
    end
end
function AttacherJoints:loadAttachmentsFinished()
    if self.rootVehicle == self and self.loadedSelectedObjectIndex ~= nil then
        local object = self.selectableObjects[self.loadedSelectedObjectIndex]
        if object ~= nil then
            self:setSelectedObject(object, self.loadedSubSelectedObjectIndex or 1)
        end
        self.loadedSelectedObjectIndex = nil
        self.loadedSubSelectedObjectIndex = nil
    end
end
function AttacherJoints:handleLowerImplementEvent(vehicle, direction)
    local selectedVehicle = self:getSelectedVehicle()
    if vehicle == nil and selectedVehicle == self then
        local spec = self.spec_attacherJoints
        if #spec.attachedImplements == 1 then
            vehicle = spec.attachedImplements[1].object
        end
    end
    local spec = self:getImplementByObject(vehicle or selectedVehicle)
    if spec ~= nil then
        local object = spec.object
        if object ~= nil and object.getAttacherVehicle ~= nil then
            local attacherVehicle = object:getAttacherVehicle()
            if attacherVehicle ~= nil then
                attacherVehicle:handleLowerImplementByAttacherJointIndex(attacherVehicle:getAttacherJointIndexFromObject(object), direction)
            end
        end
    end
end
function AttacherJoints:handleLowerImplementByAttacherJointIndex(attacherJointIndex, direction)
    if attacherJointIndex ~= nil then
        local implement = self:getImplementByJointDescIndex(attacherJointIndex)
        if implement ~= nil then
            local attacherJoint = self:getAttacherJoints()[attacherJointIndex]
            local allowsLowering, warning = implement.object:getAllowsLowering()
            if allowsLowering and attacherJoint.allowsLowering then
                if direction == nil then
                    direction = not attacherJoint.moveDown
                end
                self:setJointMoveDown(implement.jointDescIndex, direction, false)
                return
            end
            if not allowsLowering and warning ~= nil then
                g_currentMission:showBlinkingWarning(warning, 2000)
            end
        end
    end
end
function AttacherJoints:getAttachedImplements()
    return self.spec_attacherJoints.attachedImplements
end
function AttacherJoints:getAttacherJoints()
    return self.spec_attacherJoints.attacherJoints
end
function AttacherJoints:getAttacherJointByJointDescIndex(jointDescIndex)
    return self.spec_attacherJoints.attacherJoints[jointDescIndex]
end
function AttacherJoints:getAttacherJointIndexByNode(node)
    local spec = self.spec_attacherJoints
    local i = 1
    for i = i, #spec.attacherJoints do
        if spec.attacherJoints[i].jointTransform == node then
            return i
        end
    end
    return nil
end
function AttacherJoints:getAttacherJointByNode(node)
    local spec = self.spec_attacherJoints
    local i = 1
    for i = i, #spec.attacherJoints do
        local attacherJoint = spec.attacherJoints[i]
        if attacherJoint.jointTransform == node then
            return attacherJoint
        end
    end
    return nil
end
function AttacherJoints:getImplementFromAttacherJointIndex(attacherJointIndex)
    for _, attachedImplement in pairs(self.spec_attacherJoints.attachedImplements) do
        if attachedImplement.jointDescIndex == attacherJointIndex then
            return attachedImplement
        end
    end
    return nil
end
function AttacherJoints:getAttacherJointIndexFromObject(object)
    for _, attachedImplement in pairs(self.spec_attacherJoints.attachedImplements) do
        if attachedImplement.object == object then
            return attachedImplement.jointDescIndex
        end
    end
    return nil
end
function AttacherJoints:getAttacherJointDescFromObject(object)
    local spec = self.spec_attacherJoints
    for _, attachedImplement in pairs(spec.attachedImplements) do
        if attachedImplement.object == object then
            return spec.attacherJoints[attachedImplement.jointDescIndex]
        end
    end
    return nil
end
function AttacherJoints:getAttacherJointIndexFromImplementIndex(implementIndex)
    local attachedImplement = self.spec_attacherJoints.attachedImplements[implementIndex]
    if attachedImplement == nil then
        return nil
    else
        return attachedImplement.jointDescIndex
    end
end
function AttacherJoints:getObjectFromImplementIndex(implementIndex)
    local attachedImplement = self.spec_attacherJoints.attachedImplements[implementIndex]
    if attachedImplement == nil then
        return nil
    else
        return attachedImplement.object
    end
end
function AttacherJoints:updateAttacherJointGraphics(implement, dt, forceUpdate)
    if implement.object == nil then
        ::l2::
        return
    end
    local jointDesc = self.spec_attacherJoints.attacherJoints[implement.jointDescIndex]
    local attacherJoint = implement.object:getInputAttacherJointByJointDescIndex(implement.inputJointDescIndex)
    if jointDesc.bottomArm ~= nil then
        local ax, ay, az = getWorldTranslation(jointDesc.bottomArm.rotationNode)
        local bx, by, bz = getWorldTranslation(attacherJoint.node)
        local x, y, z = worldDirectionToLocal(getParent(jointDesc.bottomArm.rotationNode), bx - ax, by - ay, bz - az)
        local distance = MathUtil.vector3Length(x, y, z)
        local upY = 1
        local upZ = 0
        if math.abs(y) > 0.99 * distance then
            upY = 0
            upZ = y > 0 and 1 or -1
        end
        local dirX = 0
        local dirY = y * jointDesc.bottomArm.zScale
        local dirZ = z * jointDesc.bottomArm.zScale
        if not jointDesc.bottomArm.lockDirection then
            dirX = x * jointDesc.bottomArm.zScale
        end
        local changed = false
        local ry = jointDesc.bottomArm.lastDirection[1] - dirX
        if math.abs(ry) <= 0.001 then
            local ry = jointDesc.bottomArm.lastDirection[2] - dirY
            if math.abs(ry) <= 0.001 then
                if math.abs(jointDesc.bottomArm.lastDirection[3] - dirZ) <= 0.001 then
                    goto l14
                end
            end
        end
        if implement.attachingIsInProgress then
            setDirection(jointDesc.bottomArm.rotationNodeDir, dirX, dirY, dirZ, 0, upY, upZ)
        else
            setDirection(jointDesc.bottomArm.rotationNode, dirX, dirY, dirZ, 0, upY, upZ)
        end
        jointDesc.bottomArm.lastDirection[1] = dirX
        jointDesc.bottomArm.lastDirection[2] = dirY
        jointDesc.bottomArm.lastDirection[3] = dirZ
        changed = true
        ::l14::
        if implement.attachingIsInProgress then
            if changed then
                if implement.bottomArmInterpolating then
                    local interpolator, ry, rz = getRotation(jointDesc.bottomArm.rotationNodeDir)
                    local target = implement.bottomArmInterpolator:getTarget()
                    target[1] = interpolator
                    target[2] = ry
                    target[3] = rz
                    implement.bottomArmInterpolator:updateSpeed()
                else
                    local interpolator = ValueInterpolator.new(jointDesc.bottomArm.interpolatorKey, jointDesc.bottomArm.interpolatorGet, jointDesc.bottomArm.interpolatorSet, { getRotation(jointDesc.bottomArm.rotationNodeDir) }, AttacherJoints.SMOOTH_ATTACH_TIME)
                    if interpolator ~= nil then
                        interpolator:setDeleteListenerObject(self)
                        interpolator:setFinishedFunc(jointDesc.bottomArm.interpolatorFinished, jointDesc.bottomArm)
                        jointDesc.bottomArm.bottomArmInterpolating = true
                        implement.bottomArmInterpolating = true
                        implement.bottomArmInterpolator = interpolator
                    end
                end
            end
        elseif implement.bottomArmInterpolator ~= nil then
            ValueInterpolator.removeInterpolator(jointDesc.bottomArm.interpolatorKey)
            jointDesc.bottomArm.bottomArmInterpolating = false
            implement.bottomArmInterpolating = false
            implement.bottomArmInterpolator = nil
        end
        if jointDesc.bottomArm.translationNode ~= nil and not implement.attachingIsInProgress then
            if jointDesc.bottomArm.updateReferenceDistance then
                jointDesc.bottomArm.referenceDistance = calcDistanceFrom(jointDesc.bottomArm.referenceNode, jointDesc.bottomArm.translationNode)
            end
            setTranslation(jointDesc.bottomArm.translationNode, 0, 0, (distance - jointDesc.bottomArm.referenceDistance) * jointDesc.bottomArm.zScale)
        end
        if jointDesc.bottomArm.jointPositionNode ~= nil and not implement.attachingIsInProgress then
            setWorldTranslation(jointDesc.bottomArm.jointPositionNode, bx, by, bz)
            if self.setMovingToolDirty ~= nil then
                self:setMovingToolDirty(jointDesc.bottomArm.jointPositionNode, forceUpdate, dt)
            end
        end
        if self.setMovingToolDirty ~= nil then
            self:setMovingToolDirty(jointDesc.bottomArm.rotationNode, forceUpdate, dt)
        end
        if attacherJoint.needsToolbar and jointDesc.bottomArm.toolbarNode ~= nil then
            local interpolator = getParent(jointDesc.bottomArm.toolbarNode)
            local ry, rz, target = localDirectionToLocal(attacherJoint.node, jointDesc.rootNode, 1, 0, 0)
            local xUp, yUp, zUp = localDirectionToLocal(jointDesc.rootNode, interpolator, 0, rz, target)
            local xUp, yUp, zUp = localDirectionToLocal(attacherJoint.node, jointDesc.rootNode, 0, 1, 0)
            local xUp, yUp, zUp = localDirectionToLocal(jointDesc.rootNode, interpolator, 0, yUp, zUp)
            setDirection(jointDesc.bottomArm.toolbarNode, xUp, yUp, zUp, xUp, yUp, zUp)
        end
        if self.updateMovingPartByNode ~= nil then
            if jointDesc.bottomArm.leftNode ~= nil then
                self:updateMovingPartByNode(jointDesc.bottomArm.leftNode, forceUpdate, dt)
            end
            if jointDesc.bottomArm.rightNode ~= nil then
                self:updateMovingPartByNode(jointDesc.bottomArm.rightNode, forceUpdate, dt)
            end
        end
    end
    if jointDesc.topArm ~= nil and (not implement.attachingIsInProgress and attacherJoint.topReferenceNode ~= nil) then
        jointDesc.topArm:update(dt, attacherJoint.topReferenceNode)
    end
    if jointDesc.visualAlignNodes ~= nil then
        for bx, by in ipairs(jointDesc.visualAlignNodes) do
            self:updateMovingPartByNode(by.node, dt)
        end
    end
    goto l2
end
function AttacherJoints:calculateAttacherJointMoveUpperLowerAlpha(jointDesc, object, initial)
    if jointDesc.allowsLowering then
        local lowerDistanceToGround = jointDesc.lowerDistanceToGround
        local upperDistanceToGround = jointDesc.upperDistanceToGround
        local upperAlpha = nil
        local lowerAlpha = nil
        if #object.spec_attachable.attacherJoint.heightNodes > 0 and jointDesc.rotationNode ~= nil then
            if initial then
                self.spec_attacherJoints.groundHeightNodeCheckData.heightNodes = objectAttacherJoint.heightNodes
                checkData.jointDesc = jointDesc
                checkData.objectAttacherJoint = objectAttacherJoint
                checkData.object = object
                checkData.index = -1
                lowerDistanceToGround = jointDesc.lowerDistanceToGround
                upperDistanceToGround = jointDesc.upperDistanceToGround
                local i = 1
                for i = i, #objectAttacherJoint.heightNodes do
                    local heightNode = objectAttacherJoint.heightNodes[i]
                    local offX, offY, offZ = localToLocal(heightNode.node, heightNode.attacherJointNode, 0, 0, 0)
                    self:updateAttacherJointRotationNodes(jointDesc, 1)
                    setRotation(jointDesc.jointTransform, unpack(jointDesc.jointOrigRot))
                    local _, y, _ = localToLocal(jointDesc.jointTransform, jointDesc.rootNode, 0, 0, 0)
                    local _, hy, _ = localToLocal(jointDesc.jointTransform, jointDesc.rootNode, offX, offY, offZ)
                    lowerDistanceToGround = hy + (jointDesc.lowerDistanceToGround - y)
                    self:updateAttacherJointRotationNodes(jointDesc, 0)
                    local _, y, _ = localToLocal(jointDesc.jointTransform, jointDesc.rootNode, 0, 0, 0)
                    local _, hy, _ = localToLocal(jointDesc.jointTransform, jointDesc.rootNode, offX, offY, offZ)
                    upperDistanceToGround = hy + (jointDesc.upperDistanceToGround - y)
                end
            elseif (jointDesc.moveAlpha or 0) > 0 then
                if checkData.index == -1 then
                    checkData.index = 1
                    checkData.minDistance = math.huge
                    checkData.hit = false
                    self:doGroundHeightNodeCheck()
                end
                if checkData.isDirty then
                    checkData.isDirty = false
                    self:doGroundHeightNodeCheck()
                end
                if jointDesc.upperAlpha == nil or checkData.upperAlpha == nil then
                    upperAlpha = checkData.upperAlpha
                    lowerAlpha = checkData.lowerAlpha
                else
                    upperAlpha = jointDesc.upperAlpha * 0.9 + checkData.upperAlpha * 0.1
                    lowerAlpha = jointDesc.lowerAlpha * 0.9 + checkData.lowerAlpha * 0.1
                end
            else
                upperAlpha = jointDesc.upperAlpha
                lowerAlpha = jointDesc.lowerAlpha
            end
        end
        if upperDistanceToGround == lowerDistanceToGround then
        else
            if not upperAlpha then
                upperAlpha = math.clamp((objectAttacherJoint.upperDistanceToGround - upperDistanceToGround) / (lowerDistanceToGround - upperDistanceToGround), 0, 1)
            end
            if not lowerAlpha then
                lowerAlpha = math.clamp((objectAttacherJoint.lowerDistanceToGround - upperDistanceToGround) / (lowerDistanceToGround - upperDistanceToGround), 0, 1)
            end
        end
        if initial then
            local checkData = self.spec_attacherJoints.groundHeightNodeCheckData
            checkData.upperAlpha = upperAlpha
            checkData.lowerAlpha = lowerAlpha
        end
        if objectAttacherJoint.allowsLowering and jointDesc.allowsLowering then
            return upperAlpha, lowerAlpha
        elseif objectAttacherJoint.isDefaultLowered then
            return lowerAlpha, lowerAlpha
        else
            return upperAlpha, upperAlpha
        end
    elseif objectAttacherJoint.isDefaultLowered then
        return 1, 1
    else
        return 0, 0
    end
end
function AttacherJoints:doGroundHeightNodeCheck()
    local checkData = self.spec_attacherJoints.groundHeightNodeCheckData
    local heightNode = checkData.heightNodes[checkData.index]
    if heightNode == nil or not checkData.object:getIsAttacherJointHeightNodeActive(heightNode) then
        checkData.index = checkData.index + 1
        if checkData.index > #checkData.heightNodes then
            self:finishGroundHeightNodeCheck()
        else
            checkData.isDirty = true
        end
    else
        local offX, offY, offZ = localToLocal(heightNode.node, heightNode.attacherJointNode, 0, 0, 0)
        self:updateAttacherJointRotationNodes(checkData.jointDesc, 1)
        local lWx, lWy, lWz = localToWorld(checkData.jointDesc.jointTransformOrig, offX, offY, offZ)
        self:updateAttacherJointRotationNodes(checkData.jointDesc, 0)
        local uWx, uWy, uWz = localToWorld(checkData.jointDesc.jointTransformOrig, offX, offY, offZ)
        local dirX = lWx - uWx
        local dirY = lWy - uWy
        local dirZ = lWz - uWz
        local distance = MathUtil.vector3Length(dirX, dirY, dirZ)
        local dirX, dirY, dirZ = MathUtil.vector3Normalize(dirX, dirY, dirZ)
        checkData.currentRaycastDistance = distance
        checkData.currentRaycastWorldPos[1] = uWx
        checkData.currentRaycastWorldPos[2] = uWy
        checkData.currentRaycastWorldPos[3] = uWz
        checkData.currentRaycastWorldDir[1] = dirX
        checkData.currentRaycastWorldDir[2] = dirY
        checkData.currentRaycastWorldDir[3] = dirZ
        checkData.currentJointTransformPos[1], checkData.currentJointTransformPos[2], checkData.currentJointTransformPos[3] = getWorldTranslation(checkData.jointDesc.jointTransform)
        local distance = distance + checkData.objectAttacherJoint.lowerDistanceToGround
        checkData.minDistance = math.min(checkData.minDistance, distance)
        raycastAllAsync(uWx, uWy, uWz, dirX, dirY, dirZ, distance, "groundHeightNodeCheckCallback", self, CollisionFlag.TERRAIN)
        self:updateAttacherJointRotationNodes(checkData.jointDesc, checkData.jointDesc.moveAlpha or 0)
        return
    end
end
function AttacherJoints:finishGroundHeightNodeCheck()
    local checkData = self.spec_attacherJoints.groundHeightNodeCheckData
    if checkData.minDistance ~= math.huge then
        if not checkData.hit then
            checkData.raycastDistance = checkData.currentRaycastDistance
            checkData.raycastWorldPos[1] = checkData.currentRaycastWorldPos[1]
            checkData.raycastWorldPos[2] = checkData.currentRaycastWorldPos[2]
            checkData.raycastWorldPos[3] = checkData.currentRaycastWorldPos[3]
            checkData.raycastWorldDir[1] = checkData.currentRaycastWorldDir[1]
            checkData.raycastWorldDir[2] = checkData.currentRaycastWorldDir[2]
            checkData.raycastWorldDir[3] = checkData.currentRaycastWorldDir[3]
            checkData.jointTransformPos[1] = checkData.currentJointTransformPos[1]
            checkData.jointTransformPos[2] = checkData.currentJointTransformPos[2]
            checkData.jointTransformPos[3] = checkData.currentJointTransformPos[3]
        end
        local uWx = checkData.raycastWorldPos[1]
        local uWy = checkData.raycastWorldPos[2]
        local uWz = checkData.raycastWorldPos[3]
        local x1 = uWx + checkData.raycastWorldDir[1] * checkData.raycastDistance * ((checkData.minDistance - checkData.objectAttacherJoint.lowerDistanceToGround) / checkData.raycastDistance)
        local y1 = uWy + checkData.raycastWorldDir[2] * checkData.raycastDistance * lowerAlpha
        local z1 = uWz + checkData.raycastWorldDir[3] * checkData.raycastDistance * lowerAlpha
        local x3 = checkData.jointTransformPos[1]
        local y3 = checkData.jointTransformPos[2]
        local z3 = checkData.jointTransformPos[3]
        local straightToCenter = MathUtil.vector3Length(x1 - x3, y1 - y3, z1 - z3)
        local straightOffset = MathUtil.vector3Length(uWx - x3, uWy - y3, uWz - z3) - straightToCenter
        local angle, offset, _ = worldToLocal(self.rootNode, x1, y1, z1)
        local angle, offset, _ = worldToLocal(self.rootNode, uWx, uWy, uWz)
        local angle = math.atan(straightOffset / (offset - offset))
        checkData.lowerAlpha = math.clamp((checkData.minDistance - checkData.objectAttacherJoint.lowerDistanceToGround - straightOffset * math.sin(angle)) / checkData.raycastDistance, 0, 1)
        checkData.upperAlpha = math.clamp((checkData.minDistance - checkData.objectAttacherJoint.upperDistanceToGround) / checkData.raycastDistance, 0, 1)
    end
    checkData.index = -1
end
function AttacherJoints:groundHeightNodeCheckCallback(hitObjectId, _, _, _, distance, _, _, _, _, _, isLast)
    if not self.isDeleted then
        local checkData = self.spec_attacherJoints.groundHeightNodeCheckData
        if hitObjectId ~= 0 then
            if getRigidBodyType(hitObjectId) == RigidBodyType.STATIC then
                if distance < checkData.minDistance then
                    checkData.raycastDistance = checkData.currentRaycastDistance
                    checkData.minDistance = distance
                    checkData.hit = true
                    checkData.raycastWorldPos[1] = checkData.currentRaycastWorldPos[1]
                    checkData.raycastWorldPos[2] = checkData.currentRaycastWorldPos[2]
                    checkData.raycastWorldPos[3] = checkData.currentRaycastWorldPos[3]
                    checkData.raycastWorldDir[1] = checkData.currentRaycastWorldDir[1]
                    checkData.raycastWorldDir[2] = checkData.currentRaycastWorldDir[2]
                    checkData.raycastWorldDir[3] = checkData.currentRaycastWorldDir[3]
                    checkData.jointTransformPos[1] = checkData.currentJointTransformPos[1]
                    checkData.jointTransformPos[2] = checkData.currentJointTransformPos[2]
                    checkData.jointTransformPos[3] = checkData.currentJointTransformPos[3]
                end
            elseif not isLast then
                return true
            end
        end
        checkData.index = checkData.index + 1
        if checkData.index > #checkData.heightNodes then
            self:finishGroundHeightNodeCheck()
        else
            checkData.isDirty = true
        end
        return false
    end
end
function AttacherJoints.updateAttacherJointRotation(_, jointDesc, object)
    local objectAttacherJoint = object.spec_attachable.attacherJoint
    local rotDiff = MathUtil.lerp(objectAttacherJoint.upperRotationOffset, objectAttacherJoint.lowerRotationOffset, jointDesc.moveAlpha) - MathUtil.lerp(jointDesc.upperRotationOffset, jointDesc.lowerRotationOffset, jointDesc.moveAlpha)
    setRotation(jointDesc.jointTransform, unpack(jointDesc.jointOrigRot))
    rotateAboutLocalAxis(jointDesc.jointTransform, rotDiff, 0, 0, 1)
end
function AttacherJoints.updateAttacherJointRotationNodes(_, jointDesc, alpha)
    if jointDesc.rotationNode ~= nil then
        setRotation(jointDesc.rotationNode, MathUtil.vector3ArrayLerp(jointDesc.upperRotation, jointDesc.lowerRotation, alpha))
    end
    if jointDesc.rotationNode2 ~= nil then
        setRotation(jointDesc.rotationNode2, MathUtil.vector3ArrayLerp(jointDesc.upperRotation2, jointDesc.lowerRotation2, alpha))
    end
end
function AttacherJoints:updateAttacherJointSettingsByObject(vehicle, updateLimit, updateRotationOffset, updateDistanceToGround)
    local jointDesc = self:getAttacherJointDescFromObject(vehicle)
    local implement = self:getImplementByObject(vehicle)
    local objectAttacherJoint = vehicle:getActiveInputAttacherJoint()
    if jointDesc ~= nil and implement ~= nil then
        if updateLimit then
            local i = 1
            for i = i, 3 do
                AttacherJoints.updateAttacherJointLimits(implement, jointDesc, objectAttacherJoint, i)
                AttacherJoints.updateAttacherJointRotationLimit(implement, jointDesc, i, false, jointDesc.moveLimitAlpha)
                AttacherJoints.updateAttacherJointTranslationLimit(implement, jointDesc, i, false, jointDesc.moveLimitAlpha)
            end
        end
        if updateRotationOffset then
            self:updateAttacherJointRotation(jointDesc, vehicle)
            if self.isServer then
                setJointFrame(jointDesc.jointIndex, 0, jointDesc.jointTransform)
            end
        end
        if updateDistanceToGround then
            local upperAlpha, lowerAlpha = self:calculateAttacherJointMoveUpperLowerAlpha(jointDesc, vehicle)
            jointDesc.moveTime = jointDesc.moveDefaultTime * math.abs(upperAlpha - lowerAlpha)
            jointDesc.upperAlpha = upperAlpha
            jointDesc.lowerAlpha = lowerAlpha
            if self.isClient and self.updateDashboardValueType ~= nil then
                self:updateDashboardValueType("attacherJoints.bottomArmPositionMin")
                self:updateDashboardValueType("attacherJoints.bottomArmPositionMax")
            end
        end
    end
end
function AttacherJoints:setAttacherJointBottomArmWidth(jointDescIndex, width)
    local jointDesc = self.spec_attacherJoints.attacherJoints[jointDescIndex]
    local bottomArm = jointDesc.bottomArm
    if bottomArm ~= nil and bottomArm.variableWidthAvailable ~= nil then
        width = width or bottomArm.defaultWidth
        if bottomArm.armLeftReferenceNode == nil or bottomArm.armRightReferenceNode == nil then
            local upX, upY, upZ = getTranslation(bottomArm.armLeft)
            setTranslation(bottomArm.armLeft, width * 0.5, upY, upZ)
            local wx, wy, wz = getTranslation(bottomArm.armRight)
            setTranslation(bottomArm.armRight, -width * 0.5, wy, wz)
        else
            local upX, upY, upZ = localDirectionToWorld(bottomArm.rotationNode, 0, 1, 0)
            local wx, wy, wz = localToWorld(bottomArm.referenceNode, width * 0.5, 0, 0)
            local ax, ay, az = getWorldTranslation(bottomArm.armLeft)
            local dx, dy, dz = MathUtil.vector3Normalize(wx - ax, wy - ay, wz - az)
            I3DUtil.setWorldDirection(bottomArm.armLeft, dx, dy, dz, upX, upY, upZ, nil, nil, nil)
            local _, _, zOffsetLeft = localToWorld(bottomArm.referenceNode, -width * 0.5, 0, 0)
            local _, _, zOffsetLeft = getWorldTranslation(bottomArm.armRight)
            local _, _, zOffsetLeft = MathUtil.vector3Normalize(_ - _, _ - _, zOffsetLeft - zOffsetLeft)
            I3DUtil.setWorldDirection(bottomArm.armRight, _, _, zOffsetLeft, upX, upY, upZ, nil, nil, nil)
            local _, _, zOffsetLeft = localToLocal(bottomArm.armLeftReferenceNode, bottomArm.rotationNode, 0, 0, 0)
            local _, _, zOffsetRight = localToLocal(bottomArm.armRightReferenceNode, bottomArm.rotationNode, 0, 0, 0)
            bottomArm.referenceDistance = (math.abs(zOffsetLeft) + math.abs(zOffsetRight)) * 0.5
            setTranslation(bottomArm.referenceNode, 0, 0, -bottomArm.referenceDistance)
        end
        if self.setMovingToolDirty ~= nil then
            self:setMovingToolDirty(bottomArm.rotationNode)
        end
    end
    if bottomArm ~= nil and bottomArm.toolbars ~= nil then
        local upX = AttacherJoints.getClosestLowerLinkCategoryIndex(width or bottomArm.defaultWidth)
        for wy, wz in ipairs(jointDesc.bottomArm.toolbars) do
            setVisibility(wz, upX == wy - 1)
        end
    end
end
function AttacherJoints.attachImplementFromInfo(_, info)
    if info.attachable ~= nil then
        local attacherJoints = info.attacherVehicle.spec_attacherJoints.attacherJoints
        if attacherJoints[info.attacherVehicleJointDescIndex].jointIndex == 0 then
            if info.attachable:getActiveInputAttacherJointDescIndex() ~= nil then
                if not info.attachable:getAllowMultipleAttachments() then
                    return false
                end
                info.attachable:resolveMultipleAttachments()
            end
            if GS_IS_MOBILE_VERSION then
                local attacherJointDirection = attacherJoints[info.attacherVehicleJointDescIndex].attacherJointDirection
                if attacherJointDirection ~= nil then
                    local attachedImplements = info.attacherVehicle:getAttachedImplements()
                    local i = 1
                    for i = i, #attachedImplements do
                        if attacherJointDirection == attacherJoints[attachedImplements[i].jointDescIndex].attacherJointDirection then
                            return false
                        end
                    end
                end
            end
            info.attacherVehicle:attachImplement(info.attachable, info.attachableJointDescIndex, info.attacherVehicleJointDescIndex)
            return true
        end
    end
    return false
end
function AttacherJoints:attachImplement(object, inputJointDescIndex, jointDescIndex, noEventSend, index, startLowered, noSmoothAttach, loadFromSavegame)
    local spec = self.spec_attacherJoints
    local objectAttacherJoint = object.spec_attachable.inputAttacherJoints[inputJointDescIndex]
    local jointDesc = spec.attacherJoints[jointDescIndex]
    if jointDesc == nil or objectAttacherJoint == nil then
        Logging.warning("Cannot attach object \'%s\' to vehicle \'%s\'. Attacher joint \'%s\' or input attachher joint \'%s\' not found", object.configFileName, self.configFileName, jointDescIndex, inputJointDescIndex)
        return false
    end
    if self:getAttacherJointIndexFromObject(object) ~= nil then
        Logging.warning("Cannot attach object \'%s\' to vehicle \'%s\' between joints \'%d\' and \'%d\'. Joint already in use!", object.configFileName, self.configFileName, jointDescIndex, inputJointDescIndex)
        return
    end
    SpecializationUtil.raiseEvent(self, "onPreAttachImplement", object, inputJointDescIndex, jointDescIndex, loadFromSavegame)
    object:preAttach(self, inputJointDescIndex, jointDescIndex, loadFromSavegame)
    if jointDesc.visualAlignNodes ~= nil then
        for _, visualAlignNode in ipairs(jointDesc.visualAlignNodes) do
            if not visualAlignNode.delayedOnAttach then
                self:setMovingPartReferenceNode(visualAlignNode.node, objectAttacherJoint.node, false)
            end
        end
    end
    if not jointDesc.delayedObjectChangesOnAttach then
        ObjectChangeUtil.setObjectChanges(jointDesc.changeObjects, true, self, self.setMovingToolDirty)
    end
    local i = 1
    local widthIndexToUse = #jointDesc.visualNodes
    local widthToUse = 1
    for i = i, widthIndexToUse, widthToUse do
        setVisibility(jointDesc.visualNodes[i], true)
    end
    local i = 1
    local widthIndexToUse = #jointDesc.hideVisuals
    local widthToUse = 1
    for i = i, widthIndexToUse, widthToUse do
        local _ = jointDesc.hideVisuals[i]
        local visualAlignNode = true
        local attacherJoints = spec.visualNodeToAttacherJoints[_]
        if attacherJoints ~= nil then
            local j = 1
            for j = j, #attacherJoints do
                if attacherJoints[j].jointIndex ~= 0 then
                    visualAlignNode = false
                end
            end
        end
        if visualAlignNode then
            setVisibility(_, false)
        end
    end
    if objectAttacherJoint.bottomArm ~= nil and (jointDesc.bottomArm ~= nil and jointDesc.bottomArm.variableWidthAvailable) then
        local widthIndexToUse = nil
        local widthToUse = nil
        local visualAlignNode = #objectAttacherJoint.bottomArm.widths
        local i = 1
        for visualAlignNode = visualAlignNode, i, -1 do
            local attacherJoints = objectAttacherJoint.bottomArm.widths[visualAlignNode]
            if jointDesc.bottomArm.minWidth <= attacherJoints and attacherJoints <= jointDesc.bottomArm.maxWidth then
                widthIndexToUse = visualAlignNode
                widthToUse = attacherJoints
                break
            end
        end
        if widthToUse == nil then
            local visualAlignNode = 1
            for visualAlignNode = visualAlignNode, #objectAttacherJoint.bottomArm.widths do
                local attacherJoints = objectAttacherJoint.bottomArm.widths[visualAlignNode]
                if attacherJoints < jointDesc.bottomArm.minWidth then
                    widthToUse = jointDesc.bottomArm.minWidth
                elseif jointDesc.bottomArm.maxWidth < attacherJoints then
                    widthToUse = jointDesc.bottomArm.maxWidth
                end
            end
            widthToUse = widthToUse or jointDesc.bottomArm.maxWidth
        end
        if widthIndexToUse ~= nil then
            object:setToolBottomArmWidthByIndex(inputJointDescIndex, widthIndexToUse)
        end
        self:setAttacherJointBottomArmWidth(jointDescIndex, widthToUse)
    end
    local widthIndexToUse, widthToUse = self:calculateAttacherJointMoveUpperLowerAlpha(jointDesc, object, true)
    local _ = jointDesc.moveDefaultTime
    local attacherJoints = widthIndexToUse - widthToUse
    jointDesc.moveTime = _ * math.abs(attacherJoints)
    if startLowered == nil then
        startLowered = true
        if objectAttacherJoint.allowsLowering and jointDesc.allowsLowering then
            self:updateAttacherJointRotationNodes(jointDesc, widthIndexToUse)
            local i = calcDistanceSquaredFrom(jointDesc.jointTransform, objectAttacherJoint.node)
            self:updateAttacherJointRotationNodes(jointDesc, widthToUse)
            if i < calcDistanceSquaredFrom(jointDesc.jointTransform, objectAttacherJoint.node) * 1.1 then
                startLowered = false
            end
            if objectAttacherJoint.useFoldingLoweredState then
                startLowered = object:getIsLowered()
            end
        elseif not objectAttacherJoint.isDefaultLowered then
            startLowered = false
        end
    end
    if noEventSend == nil or noEventSend == false then
        if g_server == nil then
            g_client:getServerConnection():sendEvent(VehicleAttachEvent.new(self, object, inputJointDescIndex, jointDescIndex, startLowered))
        else
            g_server:broadcastEvent(VehicleAttachEvent.new(self, object, inputJointDescIndex, jointDescIndex, startLowered), nil, nil, self)
        end
    end
    if jointDesc.transNode == nil or objectAttacherJoint.attacherHeight == nil then
        if jointDesc.transNode == nil then
            local i = true
            if jointDesc.jointType ~= AttacherJoints.JOINTTYPE_TRAILER then
                i = true
                if jointDesc.jointType ~= AttacherJoints.JOINTTYPE_TRAILERLOW then
                    i = jointDesc.jointType == AttacherJoints.JOINTTYPE_TRAILERCAR
                end
            end
            if self.checkPowerTakeOffCollision ~= nil then
                self:checkPowerTakeOffCollision(jointDesc.jointTransform, jointDescIndex, i)
            end
        end
    else
        local i = jointDesc.transNodeMinY
        local _ = jointDesc.transNodeMaxY
        local visualAlignNode = jointDesc.lowerDistanceToGround
        local attacherJoints = jointDesc.upperDistanceToGround
        local attacherHeight = objectAttacherJoint.attacherHeight
        if self.getOutputPowerTakeOffsByJointDescIndex ~= nil and i ~= _ then
            local ptoOutputs = self:getOutputPowerTakeOffsByJointDescIndex(jointDescIndex)
            if ptoOutputs ~= nil and #ptoOutputs > 0 then
                local j = ptoOutputs[1]
                local ptoInput = j.connectedInput
                if ptoInput ~= nil then
                    local _, y, _ = localToLocal(j.outputNode, jointDesc.rootNode, 0, 0, 0)
                    local ptoRealHeight = MathUtil.lerp(visualAlignNode, attacherJoints, (y - i) / (_ - i))
                    if ptoInput.aboveAttacher then
                        local max = ptoRealHeight - (ptoInput.size + jointDesc.transNodeHeight) * 0.5
                        attacherHeight = math.clamp(attacherHeight, math.min(visualAlignNode, max), max)
                    else
                        local max = ptoRealHeight + ptoSize
                        attacherHeight = math.clamp(attacherHeight, max, (math.max(attacherJoints, max)))
                    end
                end
            end
        end
        local j = attacherHeight - jointDesc.transNodeOffsetY
        local ptoOutputs = math.clamp(j, visualAlignNode, attacherJoints)
        local ptoOutputs = attacherJoints - visualAlignNode
        local j = 0
        if ptoOutputs > 0 then
            j = math.clamp((ptoOutputs - visualAlignNode) / ptoOutputs, 0, 1)
        end
        local ptoInput = MathUtil.lerp(i, _, j)
        local _, y, _ = getTranslation(jointDesc.transNode)
        local ptoYFactor, ptoRealHeight, ptoSize = localToLocal(jointDesc.rootNode, getParent(jointDesc.transNode), 0, ptoInput, 0)
        setTranslation(jointDesc.transNode, _, ptoRealHeight, _)
        if jointDesc.transNodeDependentBottomArm ~= nil and ptoRealHeight <= jointDesc.transNodeDependentBottomArmThreshold then
            if loadFromSavegame then
                setRotation(jointDesc.transNodeDependentBottomArmAttacherJoint.bottomArm.rotationNode, jointDesc.transNodeDependentBottomArmRotation[1], jointDesc.transNodeDependentBottomArmRotation[2], jointDesc.transNodeDependentBottomArmRotation[3])
                if self.setMovingToolDirty ~= nil then
                    self:setMovingToolDirty(ptoYFactor.bottomArm.rotationNode)
                end
            else
                local interpolator = ValueInterpolator.new(ptoYFactor.bottomArm.interpolatorKey, ptoYFactor.bottomArm.interpolatorGet, ptoYFactor.bottomArm.interpolatorSet, { ptoRealHeight, ptoSize, max }, AttacherJoints.SMOOTH_ATTACH_TIME * 2)
                if interpolator ~= nil then
                    interpolator:setDeleteListenerObject(self)
                    interpolator:setFinishedFunc(ptoYFactor.bottomArm.interpolatorFinished, ptoYFactor.bottomArm)
                    ptoYFactor.bottomArm.bottomArmInterpolating = true
                end
            end
        end
    end
    local i = {
        ["object"] = object,
        ["jointDescIndex"] = jointDescIndex,
        ["inputJointDescIndex"] = inputJointDescIndex,
        ["loadFromSavegame"] = loadFromSavegame,
        ["isDetaching"] = false
    }
    jointDesc.upperAlpha = widthIndexToUse
    jointDesc.lowerAlpha = widthToUse
    jointDesc.moveAlpha = widthIndexToUse
    jointDesc.moveLimitAlpha = 0
    if startLowered then
        jointDesc.moveAlpha = widthToUse
        jointDesc.moveLimitAlpha = 1
    end
    self:updateAttacherJointRotationNodes(jointDesc, jointDesc.moveAlpha)
    self:updateAttacherJointRotation(jointDesc, object)
    self:createAttachmentJoint(i, noSmoothAttach)
    local _ = objectAttacherJoint.isDefaultLowered or jointDesc.isDefaultLowered
    if objectAttacherJoint.useFoldingLoweredState or loadFromSavegame then
        _ = startLowered
    end
    jointDesc.moveDown = _
    jointDesc.isMoving = true
    object:setLowered(jointDesc.moveDown)
    if index == nil then
        table.insert(spec.attachedImplements, i)
    else
        spec.attachedImplements[index] = i
    end
    self:updateAttacherJointGraphics(i, 0)
    self:attachAdditionalAttachment(jointDesc, objectAttacherJoint, object)
    self.rootVehicle:updateSelectableObjects()
    self:updateVehicleChain()
    local attacherJoints = nil
    if i.object:getActiveInputAttacherJoint().forceSelection then
        attacherJoints = i.object
    end
    self.rootVehicle:setSelectedVehicle(attacherJoints)
    if not i.attachingIsInProgress then
        if i.object.spec_attachable.attacherJoint.hardAttach and self:getIsHardAttachAllowed(i.jointDescIndex) then
            self:hardAttachImplement(i)
        end
        self:postAttachImplement(i)
    end
    AttacherJoints.updateRequiredTopLightsState(self)
    if self.setTipSideUpdateDirty ~= nil then
        self:setTipSideUpdateDirty()
    end
    if self.isClient and self.updateDashboardValueType ~= nil then
        self:updateDashboardValueType("attacherJoints.bottomArmPositionMin")
        self:updateDashboardValueType("attacherJoints.bottomArmPositionMax")
    end
    return true
end
function AttacherJoints:postAttachImplement(implement)
    local object = implement.object
    local inputJointDescIndex = implement.inputJointDescIndex
    local jointDescIndex = implement.jointDescIndex
    local objectAttacherJoint = object.spec_attachable.inputAttacherJoints[inputJointDescIndex]
    local jointDesc = self.spec_attacherJoints.attacherJoints[jointDescIndex]
    if objectAttacherJoint.topReferenceNode ~= nil and jointDesc.topArm ~= nil then
        jointDesc.topArm:setIsActive(true)
    end
    if jointDesc.bottomArm ~= nil then
        if jointDesc.bottomArm.toggleVisibility then
            setVisibility(jointDesc.bottomArm.rotationNode, true)
        end
        if objectAttacherJoint.needsToolbar and jointDesc.bottomArm.toolbarNode ~= nil then
            setVisibility(jointDesc.bottomArm.toolbarNode, true)
        end
        if jointDesc.bottomArm.leftNode ~= nil and objectAttacherJoint.bottomArmLeftNode ~= nil then
            self:setMovingPartReferenceNode(jointDesc.bottomArm.leftNode, objectAttacherJoint.bottomArmLeftNode, false)
        end
        if jointDesc.bottomArm.rightNode ~= nil and objectAttacherJoint.bottomArmRightNode ~= nil then
            self:setMovingPartReferenceNode(jointDesc.bottomArm.rightNode, objectAttacherJoint.bottomArmRightNode, false)
        end
    end
    if jointDesc.visualAlignNodes ~= nil then
        for _, visualAlignNode in ipairs(jointDesc.visualAlignNodes) do
            if visualAlignNode.delayedOnAttach then
                self:setMovingPartReferenceNode(visualAlignNode.node, objectAttacherJoint.node, false)
            end
        end
    end
    if jointDesc.delayedObjectChangesOnAttach then
        ObjectChangeUtil.setObjectChanges(jointDesc.changeObjects, true, self, self.setMovingToolDirty)
    end
    if not implement.loadFromSavegame then
        self:playAttachSound(jointDesc)
    end
    self:updateAttacherJointGraphics(implement, 0)
    SpecializationUtil.raiseEvent(self, "onPostAttachImplement", object, inputJointDescIndex, jointDescIndex, implement.loadFromSavegame)
    object:postAttach(self, inputJointDescIndex, jointDescIndex, implement.loadFromSavegame)
    local data = {
        ["attacherVehicle"] = self,
        ["attachedVehicle"] = implement.object,
        ["loadFromSavegame"] = implement.loadFromSavegame
    }
    self.rootVehicle:raiseStateChange(VehicleStateChange.ATTACH, data)
end
function AttacherJoints:createAttachmentJoint(implement, noSmoothAttach)
    local objectAttacherJoint = implement.object.spec_attachable.inputAttacherJoints[implement.inputJointDescIndex]
    if self.isServer and objectAttacherJoint ~= nil then
        if (getRigidBodyType(self.spec_attacherJoints.attacherJoints[implement.jointDescIndex].rootNode) == RigidBodyType.DYNAMIC or getRigidBodyType(self.spec_attacherJoints.attacherJoints[implement.jointDescIndex].rootNode) == RigidBodyType.KINEMATIC) and (getRigidBodyType(objectAttacherJoint.rootNode) == RigidBodyType.DYNAMIC or getRigidBodyType(objectAttacherJoint.rootNode) == RigidBodyType.KINEMATIC) then
            if (g_currentMission:getNodeObject(jointDesc.rootNode) or self).isAddedToPhysics and implement.object.isAddedToPhysics then
                local xNew = jointDesc.jointOrigTrans[1] + jointDesc.jointPositionOffset[1]
                local yNew = jointDesc.jointOrigTrans[2] + jointDesc.jointPositionOffset[2]
                local zNew = jointDesc.jointOrigTrans[3] + jointDesc.jointPositionOffset[3]
                local rx, ry, rz = getRotation(jointDesc.jointTransform)
                setTranslation(jointDesc.jointTransform, jointDesc.jointOrigTrans[1], jointDesc.jointOrigTrans[2], jointDesc.jointOrigTrans[3])
                setRotation(jointDesc.jointTransform, jointDesc.jointOrigRot[1], jointDesc.jointOrigRot[2], jointDesc.jointOrigRot[3])
                local x, y, z = localToWorld(getParent(jointDesc.jointTransform), xNew, yNew, zNew)
                local x1, y1, z1 = worldToLocal(jointDesc.jointTransform, x, y, z)
                setTranslation(jointDesc.jointTransform, xNew, yNew, zNew)
                setRotation(jointDesc.jointTransform, rx, ry, rz)
                local x2, y2, z2 = localToWorld(objectAttacherJoint.node, x1, y1, z1)
                local x2, y2, z2 = worldToLocal(getParent(objectAttacherJoint.node), x2, y2, z2)
                setTranslation(objectAttacherJoint.node, x2, y2, z2)
                local constr = JointConstructor.new()
                constr:setActors(jointDesc.rootNode, objectAttacherJoint.rootNode)
                constr:setJointTransforms(jointDesc.jointTransform, objectAttacherJoint.node)
                implement.jointRotLimit = {}
                implement.jointTransLimit = {}
                implement.lowerRotLimit = {}
                implement.lowerTransLimit = {}
                implement.upperRotLimit = {}
                implement.upperTransLimit = {}
                if noSmoothAttach == nil or not noSmoothAttach then
                    local dx, dy, dz = localToLocal(objectAttacherJoint.node, jointDesc.jointTransform, 0, 0, 0)
                    local dirX, dirY, dirZ = localDirectionToLocal(objectAttacherJoint.node, jointDesc.jointTransform, 0, 1, 0)
                    local rX = math.atan2(dirZ, dirY)
                    local rY, rZ, smoothAttachTime = localDirectionToLocal(objectAttacherJoint.node, jointDesc.jointTransform, 0, 0, 1)
                    local rY = math.atan2(rY, smoothAttachTime)
                    local rZ, smoothAttachTime, _ = localDirectionToLocal(objectAttacherJoint.node, jointDesc.jointTransform, 1, 0, 0)
                    local rZ = math.atan2(smoothAttachTime, rZ)
                    local smoothAttachTime = objectAttacherJoint.smoothAttachTime or AttacherJoints.SMOOTH_ATTACH_TIME
                    implement.attachingTransLimit = { math.abs(dx), math.abs(dy), (math.abs(dz)) }
                    implement.attachingRotLimit = { math.abs(rX), math.abs(rY), (math.abs(rZ)) }
                    implement.attachingTransLimitSpeed = {}
                    implement.attachingRotLimitSpeed = {}
                    local i = 1
                    for i = i, 3 do
                        implement.attachingTransLimitSpeed[i] = implement.attachingTransLimit[i] / smoothAttachTime
                        implement.attachingRotLimitSpeed[i] = implement.attachingRotLimit[i] / smoothAttachTime
                    end
                    implement.attachingIsInProgress = true
                else
                    implement.attachingTransLimit = { 0, 0, 0 }
                    implement.attachingRotLimit = { 0, 0, 0 }
                end
                implement.rotLimitThreshold = objectAttacherJoint.rotLimitThreshold or 0
                implement.transLimitThreshold = objectAttacherJoint.transLimitThreshold or 0
                local dy = 1
                local dx = 1
                for dy = dy, 3, dx do
                    local dz, dirX = AttacherJoints.updateAttacherJointLimits(implement, jointDesc, objectAttacherJoint, dy)
                    if noSmoothAttach == nil or not noSmoothAttach then
                        dz = math.max(dz, implement.attachingRotLimit[dy])
                        dirX = math.max(dirX, implement.attachingTransLimit[dy])
                    end
                    local rX = -dz
                    local rZ
                    if dy == 3 then
                        if jointDesc.lockDownRotLimit then
                            rX = math.min(-implement.attachingRotLimit[dy], 0)
                        end
                        if jointDesc.lockUpRotLimit then
                            rZ = math.max(implement.attachingRotLimit[dy], 0)
                        else
                            rZ = dz
                        end
                    else
                        rZ = dz
                    end
                    constr:setRotationLimit(dy - 1, rX, rZ)
                    implement.jointRotLimit[dy] = dz
                    local rZ = -dirX
                    local smoothAttachTime
                    if dy == 2 then
                        if jointDesc.lockDownTransLimit then
                            rZ = math.min(-implement.attachingTransLimit[dy], 0)
                        end
                        if jointDesc.lockUpTransLimit then
                            smoothAttachTime = math.max(implement.attachingTransLimit[dy], 0)
                        else
                            smoothAttachTime = dirX
                        end
                    else
                        smoothAttachTime = dirX
                    end
                    constr:setTranslationLimit(dy - 1, true, rZ, smoothAttachTime)
                    implement.jointTransLimit[dy] = dirX
                end
                if jointDesc.enableCollision then
                    constr:setEnableCollision(true)
                else
                    for dz, dirX in pairs(self.components) do
                        if dirX.node ~= jointDesc.rootNodeBackup and not dirX.collideWithAttachables then
                            setPairCollision(dirX.node, objectAttacherJoint.rootNode, false)
                        end
                    end
                end
                local dx = jointDesc.rotLimitSpring[1]
                local dy = objectAttacherJoint.rotLimitSpring[1]
                local _ = math.max(dx, dy)
                local dy = jointDesc.rotLimitSpring[2]
                local dz = objectAttacherJoint.rotLimitSpring[2]
                local dx = math.max(dy, dz)
                local dz = jointDesc.rotLimitSpring[3]
                local dirX = objectAttacherJoint.rotLimitSpring[3]
                local dy = math.max(dz, dirX)
                local dirX = jointDesc.rotLimitDamping[1]
                local dirY = objectAttacherJoint.rotLimitDamping[1]
                local dz = math.max(dirX, dirY)
                local dirY = jointDesc.rotLimitDamping[2]
                local dirZ = objectAttacherJoint.rotLimitDamping[2]
                local dirX = math.max(dirY, dirZ)
                local dirZ = jointDesc.rotLimitDamping[3]
                local rX = objectAttacherJoint.rotLimitDamping[3]
                local dirY = math.max(dirZ, rX)
                local dirZ = Utils.getMaxJointForceLimit(jointDesc.rotLimitForceLimit[1], objectAttacherJoint.rotLimitForceLimit[1])
                local rX = Utils.getMaxJointForceLimit(jointDesc.rotLimitForceLimit[2], objectAttacherJoint.rotLimitForceLimit[2])
                local rY = Utils.getMaxJointForceLimit(jointDesc.rotLimitForceLimit[3], objectAttacherJoint.rotLimitForceLimit[3])
                constr:setRotationLimitSpring(_, dz, dx, dirX, dy, dirY)
                constr:setRotationLimitForceLimit(dirZ, rX, rY)
                local smoothAttachTime = jointDesc.transLimitSpring[1]
                local rZ = math.max(smoothAttachTime, objectAttacherJoint.transLimitSpring[1])
                local smoothAttachTime = jointDesc.transLimitSpring[2]
                local rZ = math.max(smoothAttachTime, objectAttacherJoint.transLimitSpring[2])
                local smoothAttachTime = jointDesc.transLimitSpring[3]
                local rZ = math.max(smoothAttachTime, objectAttacherJoint.transLimitSpring[3])
                local smoothAttachTime = jointDesc.transLimitDamping[1]
                local rZ = math.max(smoothAttachTime, objectAttacherJoint.transLimitDamping[1])
                local smoothAttachTime = jointDesc.transLimitDamping[2]
                local rZ = math.max(smoothAttachTime, objectAttacherJoint.transLimitDamping[2])
                local smoothAttachTime = jointDesc.transLimitDamping[3]
                local rZ = math.max(smoothAttachTime, objectAttacherJoint.transLimitDamping[3])
                local rZ = Utils.getMaxJointForceLimit(jointDesc.transLimitForceLimit[1], objectAttacherJoint.transLimitForceLimit[1])
                local rZ = Utils.getMaxJointForceLimit(jointDesc.transLimitForceLimit[2], objectAttacherJoint.transLimitForceLimit[2])
                local rZ = Utils.getMaxJointForceLimit(jointDesc.transLimitForceLimit[3], objectAttacherJoint.transLimitForceLimit[3])
                constr:setTranslationLimitSpring(rZ, rZ, rZ, rZ, rZ, rZ)
                constr:setTranslationLimitForceLimit(rZ, rZ, rZ)
                jointDesc.jointIndex = constr:finalize()
                local rZ = setTranslation
                local smoothAttachTime = objectAttacherJoint.node
                rZ(smoothAttachTime, unpack(objectAttacherJoint.jointOrigTrans))
            end
        else
            return
        end
    else
        jointDesc.jointIndex = 1
        return
    end
end
function AttacherJoints:hardAttachImplement(implement)
    local spec = self.spec_attacherJoints
    local implements = {}
    local attachedImplements = nil
    if implement.object.getAttachedImplements ~= nil then
        attachedImplements = implement.object:getAttachedImplements()
    end
    if attachedImplements ~= nil then
        local i = 1
        for i = i, #attachedImplements do
            local impl = attachedImplements[i]
            local object = impl.object
            local jointDescIndex = impl.jointDescIndex
            table.insert(implements, {
                ["object"] = object,
                ["implementIndex"] = i,
                ["jointDescIndex"] = jointDescIndex,
                ["inputJointDescIndex"] = object.spec_attachable.inputAttacherJointDescIndex,
                ["moveDown"] = implement.object.spec_attacherJoints.attacherJoints[jointDescIndex].moveDown
            })
        end
        local i = 1
        for i = i, #attachedImplements do
            implement.object:detachImplement(1, true)
        end
    end
    local attacherJoint = spec.attacherJoints[implement.jointDescIndex]
    local implementJoint = implement.object.spec_attachable.attacherJoint
    local i = self:getParentComponent(attacherJoint.jointTransform)
    local impl = implement.object:getParentComponent(implement.object.spec_attachable.attacherJoint.node)
    local object = self.isAddedToPhysics
    if object then
        while self ~= nil do
            self:removeFromPhysics()
            self = self.attacherVehicle
        end
        implement.object:removeFromPhysics()
    end
    if spec.attacherVehicle == nil then
        setIsCompound(i, true)
    end
    setIsCompoundChild(impl, true)
    local jointDescIndex, jointDesc, inputJointDescIndex = localDirectionToLocal(impl, implementJoint.node, 0, 0, 1)
    local moveDown, upY, upZ = localDirectionToLocal(impl, implementJoint.node, 0, 1, 0)
    setDirection(impl, jointDescIndex, jointDesc, inputJointDescIndex, moveDown, upY, upZ)
    local x, y, z = localToLocal(impl, implementJoint.node, 0, 0, 0)
    setTranslation(impl, x, y, z)
    link(attacherJoint.jointTransform, impl)
    if implementJoint.visualNode ~= nil and attacherJoint.jointTransformVisual ~= nil then
        local currentVehicle, jointDesc, inputJointDescIndex = localDirectionToLocal(implementJoint.visualNode, implementJoint.node, 0, 0, 1)
        local currentVehicle, upY, upZ = localDirectionToLocal(implementJoint.visualNode, implementJoint.node, 0, 1, 0)
        setDirection(implementJoint.visualNode, currentVehicle, jointDesc, inputJointDescIndex, currentVehicle, upY, upZ)
        local currentVehicle, y, z = localToLocal(implementJoint.visualNode, implementJoint.node, 0, 0, 0)
        setTranslation(implementJoint.visualNode, currentVehicle, y, z)
        link(attacherJoint.jointTransformVisual, implementJoint.visualNode)
    end
    implement.object.spec_attachable.isHardAttached = true
    if object then
        while self ~= nil do
            self:addToPhysics()
            self = self.attacherVehicle
        end
    end
    for _, attacherJointToUpdate in pairs(implement.object.spec_attacherJoints.attacherJoints) do
        attacherJointToUpdate.rootNode = i
    end
    for _, attacherJointToUpdate in pairs(implements) do
        implement.object:attachImplement(attacherJointToUpdate.object, attacherJointToUpdate.inputJointDescIndex, attacherJointToUpdate.jointDescIndex, true, attacherJointToUpdate.implementIndex, attacherJointToUpdate.moveDown, true)
    end
    if self.isServer then
        self:setMassDirty()
        self:raiseDirtyFlags(self.vehicleDirtyFlag)
    end
    return true
end
function AttacherJoints:hardDetachImplement(implement)
    for _, attacherJoint in pairs(implement.object.spec_attacherJoints.attacherJoints) do
        attacherJoint.rootNode = attacherJoint.rootNodeBackup
    end
    local implementJoint = implement.object.spec_attachable.attacherJoint
    local attachedVehicleComponentNode = implement.object:getParentComponent(implementJoint.node)
    local wasAddedToPhysics = self.isAddedToPhysics
    if wasAddedToPhysics then
        while self ~= nil do
            self:removeFromPhysics()
            self = self.attacherVehicle
        end
    end
    setIsCompound(attachedVehicleComponentNode, true)
    local _, attacherJoint, z = getWorldTranslation(attachedVehicleComponentNode)
    setTranslation(attachedVehicleComponentNode, _, attacherJoint, z)
    local dirX, dirY, dirZ = localDirectionToWorld(implement.object.rootNode, 0, 0, 1)
    local upX, upY, upZ = localDirectionToWorld(implement.object.rootNode, 0, 1, 0)
    setDirection(attachedVehicleComponentNode, dirX, dirY, dirZ, upX, upY, upZ)
    link(getRootNode(), attachedVehicleComponentNode)
    if implementJoint.visualNode ~= nil and getParent(implementJoint.visualNode) ~= implementJoint.visualNodeData.parent then
        link(implementJoint.visualNodeData.parent, implementJoint.visualNode, implementJoint.visualNodeData.index)
        setRotation(implementJoint.visualNode, implementJoint.visualNodeData.rotation[1], implementJoint.visualNodeData.rotation[2], implementJoint.visualNodeData.rotation[3])
        setTranslation(implementJoint.visualNode, implementJoint.visualNodeData.translation[1], implementJoint.visualNodeData.translation[2], implementJoint.visualNodeData.translation[3])
    end
    if wasAddedToPhysics then
        while self ~= nil do
            self:addToPhysics()
            self = self.attacherVehicle
        end
        implement.object:addToPhysics()
    end
    implement.object.spec_attachable.isHardAttached = false
    if self.isServer then
        self:setMassDirty()
        self:raiseDirtyFlags(self.vehicleDirtyFlag)
    end
    return true
end
function AttacherJoints:detachImplement(implementIndex, noEventSend)
    local spec = self.spec_attacherJoints
    if noEventSend == nil or noEventSend == false then
        if g_server == nil then
            local implement = spec.attachedImplements[implementIndex]
            if implement.object ~= nil then
                g_client:getServerConnection():sendEvent(VehicleDetachEvent.new(self, implement.object))
            end
            return
        end
        g_server:broadcastEvent(VehicleDetachEvent.new(self, spec.attachedImplements[implementIndex].object), nil, nil, self)
    end
    local implement = spec.attachedImplements[implementIndex]
    implement.isDetaching = true
    SpecializationUtil.raiseEvent(self, "onPreDetachImplement", implement)
    implement.object:preDetach(self, implement)
    local jointDesc = nil
    if implement.object ~= nil then
        jointDesc = spec.attacherJoints[implement.jointDescIndex]
        if jointDesc.transNode ~= nil then
            local bottomArmJointDesc = setTranslation
            local interpolator = jointDesc.transNode
            bottomArmJointDesc(interpolator, unpack(jointDesc.transNodeOrgTrans))
            if jointDesc.transNodeDependentBottomArm ~= nil then
                local bottomArmJointDesc = jointDesc.transNodeDependentBottomArmAttacherJoint
                local interpolator = ValueInterpolator.new(bottomArmJointDesc.bottomArm.interpolatorKey, bottomArmJointDesc.bottomArm.interpolatorGet, bottomArmJointDesc.bottomArm.interpolatorSet, { bottomArmJointDesc.bottomArm.rotX, bottomArmJointDesc.bottomArm.rotY, bottomArmJointDesc.bottomArm.rotZ }, AttacherJoints.SMOOTH_ATTACH_TIME * 2)
                if interpolator ~= nil then
                    interpolator:setDeleteListenerObject(self)
                    interpolator:setFinishedFunc(bottomArmJointDesc.bottomArm.interpolatorFinished, bottomArmJointDesc.bottomArm)
                    bottomArmJointDesc.bottomArm.bottomArmInterpolating = true
                end
            end
        end
        if not implement.object.spec_attachable.isHardAttached and self.isServer then
            if jointDesc.jointIndex ~= 0 then
                removeJoint(jointDesc.jointIndex)
            end
            if not jointDesc.enableCollision then
                for _, component in pairs(self.components) do
                    if component.node ~= jointDesc.rootNodeBackup and not component.collideWithAttachables then
                        local attacherJoint = implement.object:getActiveInputAttacherJoint()
                        setPairCollision(component.node, attacherJoint.rootNode, true)
                    end
                end
            end
        end
        jointDesc.jointIndex = 0
        self:setAttacherJointBottomArmWidth(implement.jointDescIndex, nil)
    end
    if not jointDesc.delayedObjectChanges or jointDesc.bottomArm == nil then
        ObjectChangeUtil.setObjectChanges(jointDesc.changeObjects, false, self, self.setMovingToolDirty)
    end
    local i = 1
    local bottomArmJointDesc = #jointDesc.hideVisuals
    local interpolator = 1
    for i = i, bottomArmJointDesc, interpolator do
        local _ = jointDesc.hideVisuals[i]
        local component = true
        local attacherJoint = spec.hideVisualNodeToAttacherJoints[_]
        if attacherJoint ~= nil then
            local j = 1
            for j = j, #attacherJoint do
                if attacherJoint[j].jointIndex ~= 0 then
                    component = false
                end
            end
        end
        if component then
            setVisibility(_, true)
        end
    end
    local i = 1
    local bottomArmJointDesc = #jointDesc.visualNodes
    local interpolator = 1
    for i = i, bottomArmJointDesc, interpolator do
        local _ = jointDesc.visualNodes[i]
        local component = false
        local attacherJoint = spec.hideVisualNodeToAttacherJoints[_]
        if attacherJoint ~= nil then
            local j = 1
            for j = j, #attacherJoint do
                if attacherJoint[j].jointIndex ~= 0 then
                    component = true
                end
            end
        end
        if component then
            setVisibility(_, false)
        end
    end
    if implement.object ~= nil then
        local bottomArmJointDesc = implement.object
        if bottomArmJointDesc.spec_attachable.isHardAttached then
            self:hardDetachImplement(implement)
        end
        if self.isClient then
            if jointDesc.topArm ~= nil then
                jointDesc.topArm:setIsActive(false)
            end
            if jointDesc.bottomArm ~= nil then
                local interpolator = ValueInterpolator.new(jointDesc.bottomArm.interpolatorKey, jointDesc.bottomArm.interpolatorGet, jointDesc.bottomArm.interpolatorSet, { jointDesc.bottomArm.rotX, jointDesc.bottomArm.rotY, jointDesc.bottomArm.rotZ }, nil, jointDesc.bottomArm.resetSpeed)
                if interpolator ~= nil then
                    interpolator:setDeleteListenerObject(self)
                    interpolator:setFinishedFunc(jointDesc.bottomArm.interpolatorFinished, jointDesc.bottomArm)
                    jointDesc.bottomArm.bottomArmInterpolating = true
                    if jointDesc.delayedObjectChanges then
                        interpolator:setFinishedFunc(function()
                            -- upvalues: (ref) jointDesc, (copy) self
                            jointDesc.bottomArm.interpolatorFinished(jointDesc.bottomArm)
                            if jointDesc.jointIndex == 0 then
                                ObjectChangeUtil.setObjectChanges(jointDesc.changeObjects, false, self, self.setMovingToolDirty)
                            end
                        end)
                    end
                end
                jointDesc.bottomArm.lastDirection[1] = 0
                jointDesc.bottomArm.lastDirection[2] = 0
                jointDesc.bottomArm.lastDirection[3] = 0
                if jointDesc.bottomArm.translationNode ~= nil then
                    setTranslation(jointDesc.bottomArm.translationNode, 0, 0, 0)
                end
                if jointDesc.bottomArm.toolbarNode ~= nil then
                    setVisibility(jointDesc.bottomArm.toolbarNode, false)
                end
                if jointDesc.bottomArm.toggleVisibility then
                    setVisibility(jointDesc.bottomArm.rotationNode, false)
                end
                if jointDesc.bottomArm.leftNode ~= nil then
                    self:setMovingPartReferenceNode(jointDesc.bottomArm.leftNode, nil, false)
                end
                if jointDesc.bottomArm.rightNode ~= nil then
                    self:setMovingPartReferenceNode(jointDesc.bottomArm.rightNode, nil, false)
                end
            end
        end
        local interpolator = setTranslation
        local i = jointDesc.jointTransform
        local component = jointDesc.jointOrigTrans
        interpolator(i, unpack(component))
        local interpolator = bottomArmJointDesc:getActiveInputAttacherJoint()
        local i = setTranslation
        local _ = interpolator.node
        local attacherJoint = interpolator.jointOrigTrans
        i(_, unpack(attacherJoint))
        if jointDesc.rotationNode ~= nil then
            setRotation(jointDesc.rotationNode, jointDesc.rotX, jointDesc.rotY, jointDesc.rotZ)
        end
        if jointDesc.rotationNode2 ~= nil then
            setRotation(jointDesc.rotationNode2, -jointDesc.rotX, -jointDesc.rotY, -jointDesc.rotZ)
        end
        if jointDesc.visualAlignNodes ~= nil then
            for attacherJoint, visualAlignNode in ipairs(jointDesc.visualAlignNodes) do
                self:setMovingPartReferenceNode(visualAlignNode.node, jointDesc.jointTransform, false)
            end
        end
        SpecializationUtil.raiseEvent(self, "onPostDetachImplement", implementIndex)
        bottomArmJointDesc:postDetach(implementIndex)
        self:detachAdditionalAttachment(jointDesc, interpolator)
    end
    table.remove(spec.attachedImplements, implementIndex)
    self:playDetachSound(jointDesc)
    spec.wasInAttachRange = nil
    self:updateVehicleChain()
    implement.object:updateVehicleChain()
    local bottomArmJointDesc = {
        ["attacherVehicle"] = self,
        ["attachedVehicle"] = implement.object
    }
    implement.object:raiseStateChange(VehicleStateChange.DETACH, bottomArmJointDesc)
    self.rootVehicle:raiseStateChange(VehicleStateChange.DETACH, bottomArmJointDesc)
    self.rootVehicle:updateSelectableObjects()
    if GS_IS_MOBILE_VERSION then
        local i = next(spec.attachedImplements)
        if spec.attachedImplements[i] == nil then
            self.rootVehicle:setSelectedVehicle(self, nil, true)
        else
            self.rootVehicle:setSelectedVehicle(spec.attachedImplements[i].object, nil, true)
        end
    else
        self.rootVehicle:setSelectedVehicle(self, nil, true)
    end
    self.rootVehicle:requestActionEventUpdate()
    implement.object:updateSelectableObjects()
    implement.object:setSelectedVehicle(implement.object, nil, true)
    implement.object:requestActionEventUpdate()
    AttacherJoints.updateRequiredTopLightsState(self)
    return true
end
function AttacherJoints:detachImplementByObject(object, noEventSend)
    for i, implement in ipairs(self.spec_attacherJoints.attachedImplements) do
        if implement.object == object then
            self:detachImplement(i, noEventSend)
            break
        end
    end
    return true
end
function AttacherJoints:setSelectedImplementByObject(object)
    self.spec_attacherJoints.selectedImplement = self:getImplementByObject(object)
end
function AttacherJoints:getSelectedImplement()
    local spec = self.spec_attacherJoints
    if spec.selectedImplement == nil or spec.selectedImplement.object:getAttacherVehicle() == self then
        return spec.selectedImplement
    else
        return nil
    end
end
function AttacherJoints:getCanToggleAttach()
    return true
end
function AttacherJoints:getAttachControlBarActionAccessible()
    return true
end
function AttacherJoints:getShowAttachControlBarAction()
    if self:getIsAIActive() then
        return false
    end
    local info = self.spec_attacherJoints.attachableInfo
    local selectedVehicle = self:getSelectedVehicle()
    if info.attacherVehicle == nil then
        if selectedVehicle ~= nil and (not selectedVehicle.isDeleted and (selectedVehicle.getAttacherVehicle ~= nil and selectedVehicle:getAttacherVehicle() ~= nil)) then
            return true
        end
    elseif selectedVehicle == nil then
        return true
    end
    return info.attachable ~= nil and info.attacherVehicle == self
end
function AttacherJoints:detachAttachedImplement()
    if self:getCanToggleAttach() then
        AttacherJoints.actionEventAttach(self)
    end
end
function AttacherJoints:startAttacherJointCombo(force)
    local spec = self.spec_attacherJoints
    if not spec.attacherJointCombos.isRunning or force then
        spec.attacherJointCombos.direction = -spec.attacherJointCombos.direction
        spec.attacherJointCombos.isRunning = true
    end
end
function AttacherJoints:setAttacherJointBlocked(attacherJointIndex, isBlocked)
    local attacherJoint = self.spec_attacherJoints.attacherJoints[attacherJointIndex]
    if attacherJoint ~= nil then
        attacherJoint.isBlocked = isBlocked
    end
end
function AttacherJoints:getIsAttachingAllowed(attacherJoint)
    if attacherJoint.jointIndex ~= 0 then
        return false
    end
    if attacherJoint.isBlocked then
        return false
    end
    if attacherJoint.disabledByAttacherJoints ~= nil and #attacherJoint.disabledByAttacherJoints > 0 then
        local i = 1
        for i = i, #attacherJoint.disabledByAttacherJoints do
            if self:getImplementByJointDescIndex(attacherJoint.disabledByAttacherJoints[i]) ~= nil then
                return false
            end
        end
    end
    return true
end
function AttacherJoints:getIsAttacherJointCompatible(vehicle, attacherJoint, inputAttacherVehicle, inputAttacherJoint)
    return true
end
function AttacherJoints:getCanSteerAttachable(attachable)
    local jointDesc = self:getAttacherJointDescFromObject(attachable)
    return jointDesc ~= nil and (jointDesc.steeringBarLeftNode ~= nil or (jointDesc.steeringBarRightNode ~= nil or jointDesc.steeringBarForceUsage)) and true or false
end
function AttacherJoints:onAttacherJointsVehicleLoaded(vehicle)
    local spec = self.spec_attacherJoints
    if spec.attachmentDataToLoad == nil then
        g_messageCenter:unsubscribe(MessageType.VEHICLE_LOADED, self)
    else
        local i = #spec.attachmentDataToLoad
        for i = i, 1, -1 do
            local attachmentData = spec.attachmentDataToLoad[i]
            if attachmentData.attachedVehicleUniqueId == vehicle:getUniqueId() then
                self:attachImplement(vehicle, attachmentData.inputIndex, attachmentData.jointIndex, true, nil, attachmentData.moveDown, true, true)
                self:setJointMoveDown(attachmentData.jointIndex, attachmentData.moveDown, true)
                table.remove(spec.attachmentDataToLoad, i)
            end
        end
        if #spec.attachmentDataToLoad == 0 then
            self:loadAttachmentsFinished()
            spec.attachmentDataToLoad = nil
            g_messageCenter:unsubscribe(MessageType.VEHICLE_LOADED, self)
            return
        end
    end
end
function AttacherJoints:registerSelfLoweringActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions) end
function AttacherJoints:playAttachSound(jointDesc)
    if self.isClient then
        if jointDesc == nil or jointDesc.sampleAttach == nil then
            g_soundManager:playSample(self.spec_attacherJoints.samples.attach)
        else
            g_soundManager:playSample(jointDesc.sampleAttach)
        end
    end
    return true
end
function AttacherJoints:playDetachSound(jointDesc)
    if self.isClient then
        if jointDesc == nil or jointDesc.sampleDetach == nil then
            if self.spec_attacherJoints.samples.detach == nil then
                if jointDesc == nil or jointDesc.sampleAttach == nil then
                    g_soundManager:playSample(spec.samples.attach)
                else
                    g_soundManager:playSample(jointDesc.sampleAttach)
                end
            else
                g_soundManager:playSample(spec.samples.detach)
            end
        else
            g_soundManager:playSample(jointDesc.sampleDetach)
        end
    end
    return true
end
function AttacherJoints:detachingIsPossible()
    local implement = self:getImplementByObject(self:getSelectedVehicle())
    if implement ~= nil then
        local object = implement.object
        if object ~= nil and (object.attacherVehicle ~= nil and (object:isDetachAllowed() and object.attacherVehicle:getImplementIndexByObject(object) ~= nil)) then
            return true
        end
    end
    return false
end
function AttacherJoints:attachAdditionalAttachment(jointDesc, inputJointDesc, object)
    if jointDesc.attacherJointDirection ~= nil and inputJointDesc.additionalAttachment.filename ~= nil then
        local storeItem = g_storeManager:getItemByXMLFilename(inputJointDesc.additionalAttachment.filename)
        if storeItem ~= nil then
            local attacherJoint = nil
            local attacherJointIndex = nil
            for index, attacherJointToCheck in ipairs(self:getAttacherJoints()) do
                if attacherJointToCheck.attacherJointDirection == -jointDesc.attacherJointDirection then
                    if attacherJointToCheck.jointIndex ~= 0 then
                        attacherJoint = nil
                        break
                    end
                    if attacherJointToCheck.jointType == inputJointDesc.additionalAttachment.jointType then
                        attacherJoint = attacherJointToCheck
                        attacherJointIndex = index
                    end
                end
            end
            if attacherJoint ~= nil then
                local x, y, z = localToWorld(attacherJoint.jointTransform, 0, 0, 0)
                local index, attacherJointToCheck, dirZ = localDirectionToWorld(attacherJoint.jointTransform, 1, 0, 0)
                local yRot = MathUtil.getYRotationFromDirection(index, dirZ)
                jointDesc.additionalAttachment.currentAttacherJointIndex = attacherJointIndex
                local data = VehicleLoadingData.new()
                data:setStoreItem(storeItem)
                data:setPosition(x, y, z)
                data:setRotation(0, yRot, 0)
                data:setPropertyState(VehiclePropertyState.NONE)
                data:setOwnerFarmId(self:getActiveFarm())
                data:load(AttacherJoints.additionalAttachmentLoaded, self, {
                    attacherJointIndex,
                    inputJointDesc.additionalAttachment.inputAttacherJointIndex,
                    attacherJoint.jointTransform,
                    inputJointDesc.additionalAttachment.needsLowering,
                    object,
                    storeItem.xmlFilename
                })
            end
        end
    end
end
function AttacherJoints:detachAdditionalAttachment(jointDesc, inputJointDesc)
    if jointDesc.additionalAttachment.currentAttacherJointIndex ~= nil and inputJointDesc.additionalAttachment.filename ~= nil then
        local implement = self:getImplementByJointDescIndex(jointDesc.additionalAttachment.currentAttacherJointIndex)
        if implement ~= nil and implement.object:getIsAdditionalAttachment() then
            self:detachImplementByObject(implement.object)
            if not g_currentMission.isExitingGame then
                implement.object:delete()
            end
        end
    end
end
function AttacherJoints:additionalAttachmentLoaded(vehicles, vehicleLoadState, asyncCallbackArguments)
    if vehicleLoadState == VehicleLoadingState.OK then
        local vehicle = vehicles[1]
        if vehicle == nil or vehicle.setIsAdditionalAttachment == nil then
            Logging.warning("Invalid additional attachment \'%s\'.", asyncCallbackArguments[6].xmlFilename)
        else
            local offset = { 0, 0, 0 }
            if vehicle.getInputAttacherJoints ~= nil then
                local inputAttacherJoints = vehicle:getInputAttacherJoints()
                if inputAttacherJoints[asyncCallbackArguments[2]] ~= nil then
                    offset = inputAttacherJoints[asyncCallbackArguments[2]].jointOrigOffsetComponent
                end
            end
            local inputAttacherJoints, y, z = localToWorld(asyncCallbackArguments[3], unpack(offset))
            local dirX, _, dirZ = localDirectionToWorld(asyncCallbackArguments[3], 1, 0, 0)
            local yRot = MathUtil.getYRotationFromDirection(dirX, dirZ)
            vehicle:setAbsolutePosition(inputAttacherJoints, math.max(y, getTerrainHeightAtWorldPos(g_terrainNode, inputAttacherJoints, 0, z) + 0.05), z, 0, yRot, 0)
            self:attachImplement(vehicle, asyncCallbackArguments[2], asyncCallbackArguments[1], true, nil, nil, true, true)
            vehicle:setIsAdditionalAttachment(asyncCallbackArguments[4], true)
            if vehicle.addDirtAmount ~= nil and (asyncCallbackArguments[5] ~= nil and asyncCallbackArguments[5].getDirtAmount ~= nil) then
                vehicle:addDirtAmount(asyncCallbackArguments[5]:getDirtAmount())
            end
            self.rootVehicle:updateSelectableObjects()
            self.rootVehicle:setSelectedVehicle(asyncCallbackArguments[5] or self)
        end
    else
        Logging.warning("Failed to load additional attachment \'%s\'.", asyncCallbackArguments[6].xmlFilename)
        return
    end
end
function AttacherJoints:getImplementIndexByJointDescIndex(jointDescIndex)
    for i, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        if implement.jointDescIndex == jointDescIndex then
            return i
        end
    end
    return nil
end
function AttacherJoints:getImplementByJointDescIndex(jointDescIndex)
    for i, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        if implement.jointDescIndex == jointDescIndex then
            return implement
        end
    end
    return nil
end
function AttacherJoints:getImplementIndexByObject(object)
    for i, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        if implement.object == object then
            return i
        end
    end
    return nil
end
function AttacherJoints:getImplementByObject(object)
    for i, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        if implement.object == object then
            return implement
        end
    end
    return nil
end
function AttacherJoints:callFunctionOnAllImplements(functionName, ...)
    for _, implement in pairs(self:getAttachedImplements()) do
        local vehicle = implement.object
        if vehicle ~= nil and vehicle[functionName] ~= nil then
            vehicle[functionName](vehicle, ...)
        end
    end
end
function AttacherJoints:activateAttachments()
    for _, v in pairs(self.spec_attacherJoints.attachedImplements) do
        if v.object ~= nil then
            v.object:activate()
        end
    end
end
function AttacherJoints:deactivateAttachments()
    for _, v in pairs(self.spec_attacherJoints.attachedImplements) do
        if v.object ~= nil then
            v.object:deactivate()
        end
    end
end
function AttacherJoints:deactivateAttachmentsLights()
    for _, v in pairs(self.spec_attacherJoints.attachedImplements) do
        if v.object ~= nil and v.object.deactivateLights ~= nil then
            v.object:deactivateLights()
        end
    end
end
function AttacherJoints:setJointMoveDown(jointDescIndex, moveDown, noEventSend)
    local spec = self.spec_attacherJoints
    local jointDesc = spec.attacherJoints[jointDescIndex]
    if jointDesc ~= nil and moveDown ~= jointDesc.moveDown then
        if jointDesc.allowsLowering then
            jointDesc.moveDown = moveDown
            jointDesc.isMoving = true
            local implementIndex = self:getImplementIndexByJointDescIndex(jointDescIndex)
            if implementIndex ~= nil then
                local implement = spec.attachedImplements[implementIndex]
                if implement.object ~= nil then
                    implement.object:setLowered(moveDown)
                end
            end
        end
        VehicleLowerImplementEvent.sendEvent(self, jointDescIndex, moveDown, noEventSend)
    end
    return true
end
function AttacherJoints:getJointMoveDown(jointDescIndex)
    local jointDesc = self.spec_attacherJoints.attacherJoints[jointDescIndex]
    if jointDesc.allowsLowering then
        return jointDesc.moveDown
    else
        return false
    end
end
function AttacherJoints:getIsHardAttachAllowed(jointDescIndex)
    return self.spec_attacherJoints.attacherJoints[jointDescIndex].supportsHardAttach
end
function AttacherJoints:getIsSmoothAttachUpdateAllowed(implement)
    return true
end
function AttacherJoints:loadAttacherJointFromXML(attacherJoint, xmlFile, baseName, _)
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#index", baseName .. "#node")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#indexVisual", baseName .. "#nodeVisual")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#ptoOutputNode", "vehicle.powerTakeOffs.output")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#lowerDistanceToGround", baseName .. ".distanceToGround#lower")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#upperDistanceToGround", baseName .. ".distanceToGround#upper")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#rotationNode", baseName .. ".rotationNode#node")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#upperRotation", baseName .. ".rotationNode#upperRotation")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#lowerRotation", baseName .. ".rotationNode#lowerRotation")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#startRotation", baseName .. ".rotationNode#startRotation")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#rotationNode2", baseName .. ".rotationNode2#node")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#upperRotation2", baseName .. ".rotationNode2#upperRotation")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#lowerRotation2", baseName .. ".rotationNode2#lowerRotation")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#transNode", baseName .. ".transNode#node")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#transNodeMinY", baseName .. ".transNode#minY")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#transNodeMaxY", baseName .. ".transNode#maxY")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#transNodeHeight", baseName .. ".transNode#height")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. ".additionalAttachment#attacherJointDirection", baseName .. "#direction")
    local node = xmlFile:getValue(baseName .. "#node", nil, self.components, self.i3dMappings)
    if node == nil then
        Logging.xmlWarning(self.xmlFile, "Missing node for attacherJoint \'%s\'", baseName)
        return false
    end
    attacherJoint.jointTransform = node
    attacherJoint.jointComponent = self:getParentComponent(attacherJoint.jointTransform)
    attacherJoint.jointTransformVisual = xmlFile:getValue(baseName .. "#nodeVisual", nil, self.components, self.i3dMappings)
    attacherJoint.supportsHardAttach = xmlFile:getValue(baseName .. "#supportsHardAttach", true)
    attacherJoint.jointOrigOffsetComponent = { localToLocal(attacherJoint.jointComponent, attacherJoint.jointTransform, 0, 0, 0) }
    attacherJoint.jointOrigRotOffsetComponent = { localRotationToLocal(attacherJoint.jointComponent, attacherJoint.jointTransform, 0, 0, 0) }
    attacherJoint.jointTransformOrig = createTransformGroup(getName(node) .. "_jointTransformOrig")
    link(getParent(node), attacherJoint.jointTransformOrig)
    setTranslation(attacherJoint.jointTransformOrig, getTranslation(node))
    setRotation(attacherJoint.jointTransformOrig, getRotation(node))
    local jointTypeStr = xmlFile:getValue(baseName .. "#jointType")
    local jointType = nil
    if jointTypeStr ~= nil then
        if AttacherJoints.jointTypeNameToInt[jointTypeStr] == nil then
            Logging.xmlWarning(self.xmlFile, "Invalid jointType \'%s\' for attacherJoint \'%s\'!", tostring(jointTypeStr), baseName)
        end
    end
    if jointType == nil then
        jointType = AttacherJoints.JOINTTYPE_IMPLEMENT
    end
    attacherJoint.jointType = jointType
    local subTypeStr = xmlFile:getValue(baseName .. ".subType#name")
    if not string.isNilOrWhitespace(subTypeStr) then
        attacherJoint.subTypes = string.split(subTypeStr, " ")
    end
    local brandRestrictionStr = xmlFile:getValue(baseName .. ".subType#brandRestriction")
    if brandRestrictionStr ~= nil and string.trim(brandRestrictionStr) ~= "" then
        attacherJoint.brandRestrictions = string.split(brandRestrictionStr, " ")
        local i = 1
        for i = i, #attacherJoint.brandRestrictions do
            local brand = g_brandManager:getBrandByName(attacherJoint.brandRestrictions[i])
            if brand == nil then
                Logging.xmlError(xmlFile, "Unknown brand \'%s\' in \'%s\'", attacherJoint.brandRestrictions[i], baseName .. ".subType#brandRestriction")
                attacherJoint.brandRestrictions = nil
                break
            end
            attacherJoint.brandRestrictions[i] = brand
        end
    end
    local vehicleRestrictionStr = xmlFile:getValue(baseName .. ".subType#vehicleRestriction")
    if vehicleRestrictionStr ~= nil and string.trim(vehicleRestrictionStr) ~= "" then
        attacherJoint.vehicleRestrictions = string.split(vehicleRestrictionStr, " ")
    end
    attacherJoint.subTypeShowWarning = xmlFile:getValue(baseName .. ".subType#subTypeShowWarning", true)
    attacherJoint.allowsJointLimitMovement = xmlFile:getValue(baseName .. "#allowsJointLimitMovement", true)
    attacherJoint.allowsLowering = xmlFile:getValue(baseName .. "#allowsLowering", true)
    attacherJoint.isDefaultLowered = xmlFile:getValue(baseName .. "#isDefaultLowered", false)
    attacherJoint.allowDetachingWhileLifted = xmlFile:getValue(baseName .. "#allowDetachingWhileLifted", true)
    attacherJoint.allowFoldingWhileAttached = xmlFile:getValue(baseName .. "#allowFoldingWhileAttached", true)
    if jointType == AttacherJoints.JOINTTYPE_TRAILER or (jointType == AttacherJoints.JOINTTYPE_TRAILERLOW or jointType == AttacherJoints.JOINTTYPE_TRAILERCAR) then
        attacherJoint.allowsLowering = false
    end
    attacherJoint.canTurnOnImplement = xmlFile:getValue(baseName .. "#canTurnOnImplement", true)
    local rotationNode = xmlFile:getValue(baseName .. ".rotationNode#node", nil, self.components, self.i3dMappings)
    if rotationNode ~= nil then
        attacherJoint.rotationNode = rotationNode
        attacherJoint.lowerRotation = xmlFile:getValue(baseName .. ".rotationNode#lowerRotation", "0 0 0", true)
        attacherJoint.upperRotation = xmlFile:getValue(baseName .. ".rotationNode#upperRotation", nil, true) or { getRotation(rotationNode) }
        local i, brand, l = xmlFile:getValue(baseName .. ".rotationNode#startRotation", nil)
        attacherJoint.rotX = i
        attacherJoint.rotY = brand
        attacherJoint.rotZ = l
        if attacherJoint.rotX == nil then
            local i, brand, l = getRotation(rotationNode)
            attacherJoint.rotX = i
            attacherJoint.rotY = brand
            attacherJoint.rotZ = l
        end
        local i = { attacherJoint.lowerRotation[1], attacherJoint.lowerRotation[2], attacherJoint.lowerRotation[3] }
        local brand = { attacherJoint.upperRotation[1], attacherJoint.upperRotation[2], attacherJoint.upperRotation[3] }
        local l = i[1]
        local u = brand[1]
        if u < l then
            brand[1] = l
            i[1] = u
        end
        local l = i[2]
        local u = brand[2]
        if u < l then
            brand[2] = l
            i[2] = u
        end
        local l = i[3]
        local u = brand[3]
        if u < l then
            brand[3] = l
            i[3] = u
        end
        local u = attacherJoint.rotX
        attacherJoint.rotX = math.clamp(u, i[1], brand[1])
        local u = attacherJoint.rotY
        attacherJoint.rotY = math.clamp(u, i[2], brand[2])
        local u = attacherJoint.rotZ
        attacherJoint.rotZ = math.clamp(u, i[3], brand[3])
    end
    local i = xmlFile:getValue(baseName .. ".rotationNode2#node", nil, self.components, self.i3dMappings)
    if i ~= nil then
        attacherJoint.rotationNode2 = i
        attacherJoint.lowerRotation2 = xmlFile:getValue(baseName .. ".rotationNode2#lowerRotation", nil, true) or { -attacherJoint.lowerRotation[1], -attacherJoint.lowerRotation[2], -attacherJoint.lowerRotation[3] }
        attacherJoint.upperRotation2 = xmlFile:getValue(baseName .. ".rotationNode2#upperRotation", nil, true) or { -attacherJoint.upperRotation[1], -attacherJoint.upperRotation[2], -attacherJoint.upperRotation[3] }
    end
    attacherJoint.transNode = xmlFile:getValue(baseName .. ".transNode#node", nil, self.components, self.i3dMappings)
    if attacherJoint.transNode ~= nil then
        attacherJoint.transNodeOrgTrans = { getTranslation(attacherJoint.transNode) }
        attacherJoint.transNodeHeight = xmlFile:getValue(baseName .. ".transNode#height", 0.12)
        attacherJoint.transNodeMinY = xmlFile:getValue(baseName .. ".transNode#minY")
        attacherJoint.transNodeMaxY = xmlFile:getValue(baseName .. ".transNode#maxY")
        attacherJoint.transNodeDependentBottomArm = xmlFile:getValue(baseName .. ".transNode.dependentBottomArm#node", nil, self.components, self.i3dMappings)
        attacherJoint.transNodeDependentBottomArmThreshold = xmlFile:getValue(baseName .. ".transNode.dependentBottomArm#threshold", math.huge)
        attacherJoint.transNodeDependentBottomArmRotation = xmlFile:getValue(baseName .. ".transNode.dependentBottomArm#rotation", "0 0 0", true)
    end
    if (attacherJoint.rotationNode ~= nil or attacherJoint.transNode ~= nil) and xmlFile:getValue(baseName .. ".distanceToGround#lower") == nil then
        Logging.xmlWarning(self.xmlFile, "Missing \'.distanceToGround#lower\' for attacherJoint \'%s\'. Use console command \'gsVehicleAnalyze\' to get correct values!", baseName)
    end
    attacherJoint.lowerDistanceToGround = xmlFile:getValue(baseName .. ".distanceToGround#lower", 0.7)
    if (attacherJoint.rotationNode ~= nil or attacherJoint.transNode ~= nil) and xmlFile:getValue(baseName .. ".distanceToGround#upper") == nil then
        Logging.xmlWarning(self.xmlFile, "Missing \'.distanceToGround#upper\' for attacherJoint \'%s\'. Use console command \'gsVehicleAnalyze\' to get correct values!", baseName)
    end
    attacherJoint.upperDistanceToGround = xmlFile:getValue(baseName .. ".distanceToGround#upper", 1)
    if attacherJoint.lowerDistanceToGround > attacherJoint.upperDistanceToGround then
        Logging.xmlWarning(self.xmlFile, "distanceToGround#lower may not be larger than distanceToGround#upper for attacherJoint \'%s\'. Switching values!", baseName)
        attacherJoint.lowerDistanceToGround = attacherJoint.upperDistanceToGround
        attacherJoint.upperDistanceToGround = attacherJoint.lowerDistanceToGround
    end
    attacherJoint.lowerRotationOffset = xmlFile:getValue(baseName .. "#lowerRotationOffset", 0)
    attacherJoint.upperRotationOffset = xmlFile:getValue(baseName .. "#upperRotationOffset", 0)
    attacherJoint.dynamicLowerRotLimit = xmlFile:getValue(baseName .. "#dynamicLowerRotLimit", false)
    attacherJoint.lockDownRotLimit = xmlFile:getValue(baseName .. "#lockDownRotLimit", false)
    attacherJoint.lockUpRotLimit = xmlFile:getValue(baseName .. "#lockUpRotLimit", false)
    attacherJoint.lockDownTransLimit = xmlFile:getValue(baseName .. "#lockDownTransLimit", true)
    attacherJoint.lockUpTransLimit = xmlFile:getValue(baseName .. "#lockUpTransLimit", false)
    local brand = jointType ~= AttacherJoints.JOINTTYPE_IMPLEMENT and "0 0 0" or "20 20 20"
    local l, u, lz = xmlFile:getValue(baseName .. "#lowerRotLimit", brand)
    attacherJoint.lowerRotLimit = { math.abs(l or 20), math.abs(u or 20), (math.abs(lz or 20)) }
    local ux, uy, uz = xmlFile:getValue(baseName .. "#upperRotLimit")
    attacherJoint.upperRotLimit = { math.abs(ux or (l or 20)), math.abs(uy or (u or 20)), (math.abs(uz or (lz or 20))) }
    local bottomArmRotationNode, translationNode, referenceNode = xmlFile:getValue(baseName .. "#lowerTransLimit", jointType ~= AttacherJoints.JOINTTYPE_IMPLEMENT and "0 0 0" or "0.5 0.5 0.5")
    attacherJoint.lowerTransLimit = { math.abs(bottomArmRotationNode or 0), math.abs(translationNode or 0), (math.abs(referenceNode or 0)) }
    local bottomArmRotationNode, translationNode, referenceNode = xmlFile:getValue(baseName .. "#upperTransLimit")
    attacherJoint.upperTransLimit = { math.abs(bottomArmRotationNode or (bottomArmRotationNode or 0)), math.abs(translationNode or (translationNode or 0)), (math.abs(referenceNode or (referenceNode or 0))) }
    attacherJoint.jointPositionOffset = xmlFile:getValue(baseName .. "#jointPositionOffset", "0 0 0", true)
    attacherJoint.rotLimitSpring = xmlFile:getValue(baseName .. "#rotLimitSpring", "0 0 0", true)
    attacherJoint.rotLimitDamping = xmlFile:getValue(baseName .. "#rotLimitDamping", "1 1 1", true)
    attacherJoint.rotLimitForceLimit = xmlFile:getValue(baseName .. "#rotLimitForceLimit", "-1 -1 -1", true)
    attacherJoint.transLimitSpring = xmlFile:getValue(baseName .. "#transLimitSpring", "0 0 0", true)
    attacherJoint.transLimitDamping = xmlFile:getValue(baseName .. "#transLimitDamping", "1 1 1", true)
    attacherJoint.transLimitForceLimit = xmlFile:getValue(baseName .. "#transLimitForceLimit", "-1 -1 -1", true)
    attacherJoint.moveDefaultTime = xmlFile:getValue(baseName .. "#moveTime", 0.5) * 1000
    attacherJoint.moveTime = attacherJoint.moveDefaultTime
    attacherJoint.disabledByAttacherJoints = xmlFile:getValue(baseName .. "#disabledByAttacherJoints", nil, true)
    attacherJoint.enableCollision = xmlFile:getValue(baseName .. "#enableCollision", false)
    attacherJoint.topArm = AttacherJointTopArm.loadFromVehicleXML(self, baseName .. ".topArm")
    local bottomArmRotationNode = xmlFile:getValue(baseName .. ".bottomArm#rotationNode", nil, self.components, self.i3dMappings)
    local translationNode = xmlFile:getValue(baseName .. ".bottomArm#translationNode", nil, self.components, self.i3dMappings)
    local referenceNode = xmlFile:getValue(baseName .. ".bottomArm#referenceNode", nil, self.components, self.i3dMappings)
    if bottomArmRotationNode ~= nil then
        local bottomArm = {
            ["rotationNode"] = bottomArmRotationNode,
            ["rotationNodeDir"] = createTransformGroup("rotationNodeDirTemp")
        }
        link(getParent(bottomArmRotationNode), bottomArm.rotationNodeDir)
        setTranslation(bottomArm.rotationNodeDir, getTranslation(bottomArmRotationNode))
        setRotation(bottomArm.rotationNodeDir, getRotation(bottomArmRotationNode))
        bottomArm.lastDirection = { 0, 0, 0 }
        local x, y, z = xmlFile:getValue(baseName .. ".bottomArm#startRotation", nil)
        bottomArm.rotX = x
        bottomArm.rotY = y
        bottomArm.rotZ = z
        if bottomArm.rotX == nil then
            local x, y, z = getRotation(bottomArmRotationNode)
            bottomArm.rotX = x
            bottomArm.rotY = y
            bottomArm.rotZ = z
        end
        function bottomArm.interpolatorGet()
            -- upvalues: (copy) bottomArm
            return getRotation(bottomArm.rotationNode)
        end
        function bottomArm.interpolatorSet(x, y, z)
            -- upvalues: (copy) bottomArm, (copy) self
            setRotation(bottomArm.rotationNode, x, y, z)
            if self.setMovingToolDirty ~= nil then
                self:setMovingToolDirty(bottomArm.rotationNode)
            end
        end
        function bottomArm.interpolatorFinished(_)
            -- upvalues: (copy) bottomArm
            bottomArm.bottomArmInterpolating = false
        end
        bottomArm.interpolatorKey = bottomArmRotationNode .. "rotation"
        bottomArm.bottomArmInterpolating = false
        if translationNode ~= nil and referenceNode ~= nil then
            bottomArm.translationNode = translationNode
            bottomArm.referenceNode = referenceNode
            local x, y, z = getTranslation(translationNode)
            if math.abs(x) >= 0.0001 or (math.abs(y) >= 0.0001 or math.abs(z) >= 0.0001) then
                Logging.xmlWarning(self.xmlFile, "BottomArm translation of attacherJoint \'%s\' is not 0/0/0!", baseName)
            end
            bottomArm.referenceDistance = calcDistanceFrom(referenceNode, translationNode)
        end
        local y = xmlFile:getValue(baseName .. ".bottomArm#zScale", 1)
        bottomArm.zScale = math.sign(y)
        bottomArm.lockDirection = xmlFile:getValue(baseName .. ".bottomArm#lockDirection", true)
        bottomArm.resetSpeed = xmlFile:getValue(baseName .. ".bottomArm#resetSpeed", 45)
        bottomArm.updateReferenceDistance = xmlFile:getValue(baseName .. ".bottomArm#updateReferenceDistance", false)
        bottomArm.jointPositionNode = xmlFile:getValue(baseName .. ".bottomArm#jointPositionNode", nil, self.components, self.i3dMappings)
        bottomArm.toggleVisibility = xmlFile:getValue(baseName .. ".bottomArm#toggleVisibility", false)
        if bottomArm.toggleVisibility then
            setVisibility(bottomArm.rotationNode, false)
        end
        if jointType == AttacherJoints.JOINTTYPE_IMPLEMENT then
            bottomArm.sharedLoadRequestIdToolbar = self:loadSubSharedI3DFile(Utils.getFilename(xmlFile:getValue(baseName .. ".toolbar#filename", "$data/shared/assets/toolbars/toolbars.i3d"), self.baseDirectory), false, false, self.onBottomArmToolbarI3DLoaded, self, {
                ["bottomArm"] = bottomArm,
                ["referenceNode"] = referenceNode
            })
        end
        local x = AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[2]
        local y = AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[2]
        bottomArm.minWidth = x
        bottomArm.maxWidth = y
        local x = xmlFile:getValue(baseName .. ".bottomArm#categoryRange", "1 4", true)
        if x ~= nil and #x >= 1 then
            bottomArm.minWidth = AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[x[1]] or bottomArm.minWidth
            bottomArm.maxWidth = AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[x[2] or x[1]] or bottomArm.maxWidth
        end
        local y = xmlFile:getValue(baseName .. ".bottomArm#widthRange", nil, true)
        if y ~= nil and #y >= 1 then
            bottomArm.minWidth = y[1] or bottomArm.minWidth
            bottomArm.maxWidth = y[2] or (y[1] or bottomArm.maxWidth)
        end
        if jointType == AttacherJoints.JOINTTYPE_IMPLEMENT and not (xmlFile:hasProperty(baseName .. ".bottomArm#categoryRange") or xmlFile:hasProperty(baseName .. ".bottomArm#widthRange")) then
            Logging.xmlWarning(xmlFile, "Missing categoryRange or widthRange attribute for bottom arm in \'%s\'", baseName)
        end
        bottomArm.armLeft = xmlFile:getValue(baseName .. ".bottomArm.armLeft#node", nil, self.components, self.i3dMappings)
        bottomArm.armLeftReferenceNode = xmlFile:getValue(baseName .. ".bottomArm.armLeft#referenceNode", nil, self.components, self.i3dMappings)
        if bottomArm.armLeft ~= nil and bottomArm.armLeftReferenceNode ~= nil then
            bottomArm.armLeftLength = calcDistanceFrom(bottomArm.armLeft, bottomArm.armLeftReferenceNode)
        end
        bottomArm.armRight = xmlFile:getValue(baseName .. ".bottomArm.armRight#node", nil, self.components, self.i3dMappings)
        bottomArm.armRightReferenceNode = xmlFile:getValue(baseName .. ".bottomArm.armRight#referenceNode", nil, self.components, self.i3dMappings)
        if bottomArm.armRight ~= nil and bottomArm.armRightReferenceNode ~= nil then
            bottomArm.armRightLength = calcDistanceFrom(bottomArm.armRight, bottomArm.armRightReferenceNode)
        end
        bottomArm.ballVisibility = xmlFile:getValue(baseName .. ".bottomArm#ballVisibility", true)
        if bottomArm.armLeft == nil or (bottomArm.armRight == nil or bottomArm.referenceNode == nil) then
            bottomArm.defaultWidth = (bottomArm.minWidth + bottomArm.maxWidth) * 0.5
        else
            bottomArm.variableWidthAvailable = true
            local z = nil
            local defaultCategory = xmlFile:getValue(baseName .. ".bottomArm#defaultCategory")
            if defaultCategory ~= nil and (defaultCategory >= 0 and defaultCategory <= 4) then
                z = AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[defaultCategory]
            end
            if z == nil then
                z = xmlFile:getValue(baseName .. ".bottomArm#defaultWidth")
            end
            if z == nil then
                local xOffset, _, _ = localToLocal(bottomArm.armLeftReferenceNode or bottomArm.armLeft, bottomArm.referenceNode, 0, 0, 0)
                z = math.abs(xOffset) * 2
            end
            bottomArm.defaultWidth = z
        end
        if self.setMovingPartReferenceNode ~= nil then
            bottomArm.leftNode = xmlFile:getValue(baseName .. ".bottomArm#leftNode", nil, self.components, self.i3dMappings)
            bottomArm.rightNode = xmlFile:getValue(baseName .. ".bottomArm#rightNode", nil, self.components, self.i3dMappings)
        end
        attacherJoint.bottomArm = bottomArm
    end
    if self.isClient then
        attacherJoint.sampleAttach = g_soundManager:loadSampleFromXML(xmlFile, baseName, "attachSound", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        attacherJoint.sampleDetach = g_soundManager:loadSampleFromXML(xmlFile, baseName, "detachSound", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    attacherJoint.steeringBarLeftNode = xmlFile:getValue(baseName .. ".steeringBars#leftNode", nil, self.components, self.i3dMappings)
    attacherJoint.steeringBarRightNode = xmlFile:getValue(baseName .. ".steeringBars#rightNode", nil, self.components, self.i3dMappings)
    attacherJoint.steeringBarForceUsage = xmlFile:getValue(baseName .. ".steeringBars#forceUsage", true)
    if self.setMovingPartReferenceNode ~= nil then
        for z, defaultCategory in self.xmlFile:iterator(baseName .. ".visualAlignNode") do
            local xOffset = xmlFile:getValue(defaultCategory .. "#node", nil, self.components, self.i3dMappings)
            if xOffset ~= nil then
                if attacherJoint.visualAlignNodes == nil then
                    attacherJoint.visualAlignNodes = {}
                end
                table.insert(attacherJoint.visualAlignNodes, {
                    ["node"] = xOffset,
                    ["delayedOnAttach"] = xmlFile:getValue(defaultCategory .. "#delayedOnAttach", true)
                })
            end
        end
    end
    attacherJoint.visualNodes = xmlFile:getValue(baseName .. ".visuals#nodes", nil, self.components, self.i3dMappings, true)
    local y = 1
    local bottomArm = #attacherJoint.visualNodes
    local x = 1
    for y = y, bottomArm, x do
        local z = attacherJoint.visualNodes[y]
        if self.spec_attacherJoints.visualNodeToAttacherJoints[z] == nil then
            spec.visualNodeToAttacherJoints[z] = {}
        end
        table.insert(spec.visualNodeToAttacherJoints[z], attacherJoint)
    end
    attacherJoint.hideVisuals = xmlFile:getValue(baseName .. ".visuals#hide", nil, self.components, self.i3dMappings, true)
    local y = 1
    local bottomArm = #attacherJoint.hideVisuals
    local x = 1
    for y = y, bottomArm, x do
        local z = attacherJoint.hideVisuals[y]
        if spec.hideVisualNodeToAttacherJoints[z] == nil then
            spec.hideVisualNodeToAttacherJoints[z] = {}
        end
        table.insert(spec.hideVisualNodeToAttacherJoints[z], attacherJoint)
    end
    attacherJoint.changeObjects = {}
    ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, baseName, attacherJoint.changeObjects, self.components, self)
    ObjectChangeUtil.setObjectChanges(attacherJoint.changeObjects, false, self, self.setMovingToolDirty, true)
    attacherJoint.delayedObjectChanges = xmlFile:getValue(baseName .. "#delayedObjectChanges", true)
    attacherJoint.delayedObjectChangesOnAttach = xmlFile:getValue(baseName .. "#delayedObjectChangesOnAttach", false)
    attacherJoint.additionalAttachment = {}
    local bottomArm, x, y = localToLocal(attacherJoint.jointTransform, self.rootNode, 0, 0, 0)
    attacherJoint.attacherJointDirection = xmlFile:getValue(baseName .. "#direction", (math.sign(y)))
    local xOffset = baseName .. "#useTopLights"
    local _ = attacherJoint.attacherJointDirection == 1
    attacherJoint.useTopLights = xmlFile:getValue(xOffset, _)
    attacherJoint.rootNode = xmlFile:getValue(baseName .. "#rootNode", self:getParentComponent(attacherJoint.jointTransform), self.components, self.i3dMappings)
    attacherJoint.rootNodeBackup = attacherJoint.rootNode
    attacherJoint.jointIndex = 0
    attacherJoint.isBlocked = false
    attacherJoint.comboTime = xmlFile:getValue(baseName .. "#comboTime")
    local z = baseName .. ".schema"
    if xmlFile:hasProperty(z) then
        local defaultCategory, xOffset = xmlFile:getValue(z .. "#position")
        if defaultCategory == nil then
            Logging.xmlWarning(self.xmlFile, "Missing values for \'%s\'", z .. "#position")
        else
            local _, _ = xmlFile:getValue(z .. "#liftedOffset", "0 5")
            self.schemaOverlay:addAttacherJoint(defaultCategory, xOffset, xmlFile:getValue(z .. "#rotation", 0), xmlFile:getValue(z .. "#invertX", false), _, _)
        end
    else
        Logging.xmlWarning(self.xmlFile, "Missing schema overlay attacherJoint \'%s\'!", baseName)
    end
    return true
end
function AttacherJoints.onBottomArmToolbarI3DLoaded(_, i3dNode, _, args)
    if i3dNode ~= 0 then
        local rootNode = getChildAt(i3dNode, 0)
        link(args.referenceNode, rootNode)
        setTranslation(rootNode, 0, 0, 0)
        setVisibility(rootNode, false)
        local activeIndex = AttacherJoints.getClosestLowerLinkCategoryIndex(args.bottomArm.defaultWidth or AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[2])
        bottomArm.toolbarNode = rootNode
        bottomArm.toolbars = {}
        local index = 1
        local toolbar = getNumOfChildren(rootNode)
        for index = index, toolbar do
            local toolbar = getChildAt(rootNode, index - 1)
            setTranslation(toolbar, 0, 0, 0)
            setVisibility(toolbar, activeIndex == index - 1)
            table.insert(bottomArm.toolbars, toolbar)
        end
        delete(i3dNode)
    end
end
function AttacherJoints:raiseActive(superFunc)
    superFunc(self)
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        if implement.object ~= nil then
            implement.object:raiseActive()
        end
    end
end
function AttacherJoints:registerActionEvents(superFunc, excludedVehicle)
    superFunc(self, excludedVehicle)
    if self ~= excludedVehicle then
        local selectedObject = self:getSelectedObject()
        if selectedObject ~= nil and (self ~= selectedObject.vehicle and excludedVehicle ~= selectedObject.vehicle) then
            selectedObject.vehicle:registerActionEvents()
        end
        for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
            if implement.object ~= nil then
                if selectedObject == nil then
                    printCallstack()
                end
                implement.object:registerActionEvents(selectedObject.vehicle)
            end
        end
    end
end
function AttacherJoints:removeActionEvents(superFunc)
    superFunc(self)
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        if implement.object ~= nil then
            implement.object:removeActionEvents()
        end
    end
end
function AttacherJoints:addToPhysics(superFunc)
    if not superFunc(self) then
        return false
    end
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        if implement.object.spec_attachable.isHardAttached then
            implement.object:addToPhysics()
        else
            self:createAttachmentJoint(implement, true)
        end
    end
    return true
end
function AttacherJoints:removeFromPhysics(superFunc)
    local spec = self.spec_attacherJoints
    for _, implement in pairs(spec.attachedImplements) do
        if implement.object.spec_attachable.isHardAttached then
            implement.object:removeFromPhysics()
        else
            local jointDesc = spec.attacherJoints[implement.jointDescIndex]
            if jointDesc.jointIndex ~= 0 then
                jointDesc.jointIndex = 0
            end
        end
    end
    return superFunc(self) and true or false
end
function AttacherJoints:getTotalMass(superFunc, onlyGivenVehicle)
    local mass = superFunc(self)
    if onlyGivenVehicle == nil or not onlyGivenVehicle then
        for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
            local object = implement.object
            if object ~= nil then
                mass = mass + object:getTotalMass(onlyGivenVehicle)
            end
        end
    end
    return mass
end
function AttacherJoints:getAdditionalComponentMass(superFunc, component)
    local additionalMass = superFunc(self, component)
    if component.node == self.rootNode then
        for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
            local object = implement.object
            if object ~= nil and object.spec_attachable.isHardAttached then
                additionalMass = additionalMass + object:getTotalMass(true)
            end
        end
    end
    return additionalMass
end
function AttacherJoints:addChildVehicles(superFunc, vehicles, rootVehicle)
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        local object = implement.object
        if object ~= nil and object.addChildVehicles ~= nil then
            object:addChildVehicles(vehicles, rootVehicle)
        end
    end
    return superFunc(self, vehicles, rootVehicle)
end
function AttacherJoints:getAirConsumerUsage(superFunc)
    local usage = superFunc(self)
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        local object = implement.object
        if object ~= nil and object.getAttachbleAirConsumerUsage ~= nil then
            usage = usage + object:getAttachbleAirConsumerUsage()
        end
    end
    return usage
end
function AttacherJoints:getRequiresPower(superFunc)
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        if implement.object ~= nil and implement.object:getRequiresPower() then
            return true
        end
    end
    return superFunc(self)
end
function AttacherJoints:addVehicleToAIImplementList(superFunc, list)
    superFunc(self, list)
    for _, implement in pairs(self:getAttachedImplements()) do
        local object = implement.object
        if object ~= nil and object.addVehicleToAIImplementList ~= nil then
            object:addVehicleToAIImplementList(list)
        end
    end
end
function AttacherJoints:collectAIAgentAttachments(superFunc, aiDrivableVehicle)
    superFunc(self, aiDrivableVehicle)
    for _, implement in pairs(self:getAttachedImplements()) do
        local object = implement.object
        if object ~= nil and object.collectAIAgentAttachments ~= nil then
            object:collectAIAgentAttachments(aiDrivableVehicle)
            aiDrivableVehicle:startNewAIAgentAttachmentChain()
        end
    end
end
function AttacherJoints:setAIVehicleObstacleStateDirty(superFunc)
    superFunc(self)
    for _, implement in pairs(self:getAttachedImplements()) do
        local object = implement.object
        if object ~= nil and object.setAIVehicleObstacleStateDirty ~= nil then
            object:setAIVehicleObstacleStateDirty()
        end
    end
end
function AttacherJoints:getDirectionSnapAngle(superFunc)
    local maxAngle = superFunc(self)
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        local object = implement.object
        if object ~= nil and object.getDirectionSnapAngle ~= nil then
            maxAngle = math.max(maxAngle + object:getDirectionSnapAngle())
        end
    end
    return maxAngle
end
function AttacherJoints:getFillLevelInformation(superFunc, display)
    superFunc(self, display)
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        local object = implement.object
        if object ~= nil and object.getFillLevelInformation ~= nil then
            object:getFillLevelInformation(display)
        end
    end
end
function AttacherJoints:getHasObjectMounted(superFunc, object)
    if superFunc(self, object) then
        return true
    end
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        if implement.object ~= nil and implement.object:getHasObjectMounted(object) then
            return true
        end
    end
    return false
end
function AttacherJoints:attachableAddToolCameras(superFunc)
    superFunc(self)
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        local object = implement.object
        if object ~= nil and object.attachableAddToolCameras ~= nil then
            object:attachableAddToolCameras()
        end
    end
end
function AttacherJoints:attachableRemoveToolCameras(superFunc)
    superFunc(self)
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        local object = implement.object
        if object ~= nil and object.attachableRemoveToolCameras ~= nil then
            object:attachableRemoveToolCameras()
        end
    end
end
function AttacherJoints:registerSelectableObjects(superFunc, selectableObjects)
    superFunc(self, selectableObjects)
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        local object = implement.object
        if object ~= nil and object.registerSelectableObjects ~= nil then
            object:registerSelectableObjects(selectableObjects)
        end
    end
end
function AttacherJoints:getIsReadyForAutomatedTrainTravel(superFunc)
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        local object = implement.object
        if object ~= nil and (object.getIsReadyForAutomatedTrainTravel ~= nil and not object:getIsReadyForAutomatedTrainTravel()) then
            return false
        end
    end
    return superFunc(self)
end
function AttacherJoints:getIsAutomaticShiftingAllowed(superFunc)
    local spec = self.spec_attacherJoints
    local lastSpeed = self:getLastSpeed()
    for _, implement in pairs(spec.attachedImplements) do
        if lastSpeed < 2 then
            if implement.attachingIsInProgress then
                return false
            end
            if spec.attacherJoints[implement.jointDescIndex].isMoving then
                return false
            end
        end
        local jointDescIndex = implement.object
        if jointDescIndex ~= nil and (jointDescIndex.getIsAutomaticShiftingAllowed ~= nil and not jointDescIndex:getIsAutomaticShiftingAllowed()) then
            return false
        end
    end
    return superFunc(self)
end
function AttacherJoints:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
    if not superFunc(self, xmlFile, key, group) then
        return false
    end
    group.attacherJointIndices = {}
    local attacherJointIndices = xmlFile:getValue(key .. "#attacherJointIndices", nil, true)
    if attacherJointIndices ~= nil then
        for _, attacherJointIndex in ipairs(attacherJointIndices) do
            table.insert(group.attacherJointIndices, attacherJointIndex)
        end
    end
    if #group.attacherJointIndices == 0 then
        group.attacherJointIndices = nil
    end
    group.attacherJointNodes = xmlFile:getValue(key .. "#attacherJointNodes", nil, self.components, self.i3dMappings, true)
    if #group.attacherJointNodes == 0 then
        group.attacherJointNodes = nil
    end
    return true
end
function AttacherJoints:getIsDashboardGroupActive(superFunc, group)
    if group.attacherJointNodes ~= nil and self.finishedLoading then
        if group.attacherJointIndices == nil then
            group.attacherJointIndices = {}
        end
        for _, node in ipairs(group.attacherJointNodes) do
            local attacherJointIndex = self:getAttacherJointIndexByNode(node)
            if attacherJointIndex ~= nil then
                table.insert(group.attacherJointIndices, attacherJointIndex)
            end
        end
        if #group.attacherJointIndices == 0 then
            group.attacherJointIndices = nil
        end
        group.attacherJointNodes = nil
    end
    if group.attacherJointIndices ~= nil then
        local hasAttachment = false
        for node, attacherJointIndex in ipairs(group.attacherJointIndices) do
            if self:getImplementFromAttacherJointIndex(attacherJointIndex) ~= nil then
                hasAttachment = true
            end
        end
        if not hasAttachment then
            return false
        end
    end
    return superFunc(self, group)
end
function AttacherJoints:loadAttacherJointHeightNode(superFunc, xmlFile, key, heightNode, attacherJointNode)
    heightNode.disablingAttacherJointIndices = xmlFile:getValue(key .. "#disablingAttacherJointIndices", "", true)
    return superFunc(self, xmlFile, key, heightNode, attacherJointNode)
end
function AttacherJoints:getIsAttacherJointHeightNodeActive(superFunc, heightNode)
    for _, jointIndex in ipairs(heightNode.disablingAttacherJointIndices) do
        if self:getImplementFromAttacherJointIndex(jointIndex) ~= nil then
            return false
        end
    end
    return superFunc(self, heightNode)
end
function AttacherJoints:loadTipSide(superFunc, xmlFile, key, entry)
    if not superFunc(self, xmlFile, key, entry) then
        return false
    end
    local disablingAttacherJointNodes = xmlFile:getValue(key .. "#disablingAttacherJointNodes", nil, self.components, self.i3dMappings, true)
    if #disablingAttacherJointNodes > 0 then
        entry.disablingAttacherJointNodes = disablingAttacherJointNodes
    end
    return true
end
function AttacherJoints:getIsTipSideAvailable(superFunc, sideIndex)
    if not superFunc(self, sideIndex) then
        return false
    end
    local tipSide = self.spec_trailer.tipSides[sideIndex]
    if tipSide ~= nil then
        if tipSide.disablingAttacherJointNodes ~= nil then
            tipSide.disablingAttacherJointIndices = {}
            for _, jointNode in ipairs(tipSide.disablingAttacherJointNodes) do
                local jointIndex = self:getAttacherJointIndexByNode(jointNode)
                if jointIndex ~= nil then
                    table.insert(tipSide.disablingAttacherJointIndices, jointIndex)
                end
            end
            if #tipSide.disablingAttacherJointIndices == 0 then
                tipSide.disablingAttacherJointIndices = nil
            end
        end
        if tipSide.disablingAttacherJointIndices ~= nil then
            for _, jointNode in ipairs(tipSide.disablingAttacherJointIndices) do
                if self:getImplementFromAttacherJointIndex(jointNode) ~= nil then
                    return false
                end
            end
        end
    end
    return true
end
function AttacherJoints:loadFillUnitFromXML(superFunc, xmlFile, key, entry, index)
    if not superFunc(self, xmlFile, key, entry, index) then
        return false
    end
    local disablingAttacherJointNodes = xmlFile:getValue(key .. "#disablingAttacherJointNodes", nil, self.components, self.i3dMappings, true)
    if #disablingAttacherJointNodes > 0 then
        entry.disablingAttacherJointNodes = disablingAttacherJointNodes
    end
    return true
end
function AttacherJoints:getFillUnitSupportsToolType(superFunc, fillUnitIndex, toolType)
    if not superFunc(self, fillUnitIndex, toolType) then
        return false
    end
    local fillUnit = self.spec_fillUnit.fillUnits[fillUnitIndex]
    if fillUnit ~= nil then
        if fillUnit.disablingAttacherJointNodes ~= nil then
            fillUnit.disablingAttacherJointIndices = {}
            for _, jointNode in ipairs(fillUnit.disablingAttacherJointNodes) do
                local jointIndex = self:getAttacherJointIndexByNode(jointNode)
                if jointIndex ~= nil then
                    table.insert(fillUnit.disablingAttacherJointIndices, jointIndex)
                end
            end
            if #fillUnit.disablingAttacherJointIndices == 0 then
                fillUnit.disablingAttacherJointIndices = nil
            end
        end
        if fillUnit.disablingAttacherJointIndices ~= nil then
            for _, jointNode in ipairs(fillUnit.disablingAttacherJointIndices) do
                if self:getImplementFromAttacherJointIndex(jointNode) ~= nil then
                    return false
                end
            end
        end
    end
    return true
end
function AttacherJoints:isDetachAllowed(superFunc)
    local detachAllowed, warning, showWarning = superFunc(self)
    if not detachAllowed then
        return detachAllowed, warning, showWarning
    end
    local spec = self.spec_attacherJoints
    for attacherJointIndex, attacherJoint in ipairs(spec.attacherJoints) do
        if not (attacherJoint.allowDetachingWhileLifted or attacherJoint.moveDown) then
            local implement = self:getImplementByJointDescIndex(attacherJointIndex)
            if implement ~= nil then
                local inputAttacherJoint = implement.object:getInputAttacherJointByJointDescIndex(implement.inputJointDescIndex)
                if inputAttacherJoint ~= nil and not inputAttacherJoint.forceAllowDetachWhileLifted then
                    return false, string.format(spec.texts.lowerImplementFirst, implement.object.typeDesc)
                end
            end
        end
    end
    return true
end
function AttacherJoints:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
    local spec = self.spec_attacherJoints
    for attacherJointIndex, attacherJoint in ipairs(spec.attacherJoints) do
        if not attacherJoint.allowFoldingWhileAttached and attacherJoint.jointIndex ~= 0 then
            return false, spec.texts.warningFoldingAttacherJoint
        end
    end
    return superFunc(self, direction, onAiTurnOn)
end
function AttacherJoints:getIsWheelFoliageDestructionAllowed(superFunc, wheel)
    if not superFunc(self, wheel) then
        return false
    end
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        local object = implement.object
        if object ~= nil and (object.getBlockFoliageDestruction ~= nil and object:getBlockFoliageDestruction()) then
            return false
        end
    end
    return true
end
function AttacherJoints:getAreControlledActionsAllowed(superFunc)
    local allowed, warning = superFunc(self)
    if not allowed then
        return false, warning
    end
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        local object = implement.object
        if object ~= nil and object.getAreControlledActionsAllowed ~= nil then
            local allowed
            allowed, warning = object:getAreControlledActionsAllowed()
            if not allowed then
                return false, warning
            end
        end
        if implement.attachingIsInProgress then
            return false
        end
    end
    return true, warning
end
function AttacherJoints:getConnectionHoseConfigIndex(superFunc)
    local index = superFunc(self)
    local configKey = self.xmlFile:getValue("vehicle.attacherJoints#connectionHoseConfigId", index)
    if self.configurations.attacherJoint ~= nil then
        local configKey = string.format("vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration(%d)", self.configurations.attacherJoint - 1)
        configKey = self.xmlFile:getValue(configKey .. "#connectionHoseConfigId", configKey)
    end
    return configKey
end
function AttacherJoints:getPowerTakeOffConfigIndex(superFunc)
    local index = superFunc(self)
    local configKey = self.xmlFile:getValue("vehicle.attacherJoints#powerTakeOffConfigId", index)
    if self.configurations.attacherJoint ~= nil then
        local configKey = string.format("vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration(%d)", self.configurations.attacherJoint - 1)
        configKey = self.xmlFile:getValue(configKey .. "#powerTakeOffConfigId", configKey)
    end
    return configKey
end
function AttacherJoints:loadHoseTargetNode(superFunc, xmlFile, targetKey, entry)
    if not superFunc(self, xmlFile, targetKey, entry) then
        return false
    end
    entry.blockedByAttacherJointIndices = xmlFile:getValue(targetKey .. "#blockedByAttacherJointNodes", nil, self.components, self.i3dMappings, true) or entry.blockedByAttacherJointIndices
    return true
end
function AttacherJoints:getIsConnectionTargetUsed(superFunc, desc)
    if superFunc(self, desc) then
        return true
    end
    if desc.blockedByAttacherJointIndices ~= nil then
        for _, jointNode in ipairs(desc.blockedByAttacherJointIndices) do
            local jointIndex = self:getAttacherJointIndexByNode(jointNode)
            if jointIndex ~= nil and self:getImplementFromAttacherJointIndex(jointIndex) ~= nil then
                return true
            end
        end
    end
    return false
end
function AttacherJoints:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_attacherJoints
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection then
            if #spec.attacherJoints > 0 then
                local selectedImplement = self:getSelectedImplement()
                if selectedImplement ~= nil and selectedImplement.object ~= self then
                    for _, attachedImplement in pairs(spec.attachedImplements) do
                        if attachedImplement == selectedImplement then
                            selectedImplement.object:registerLoweringActionEvent(spec.actionEvents, InputAction.LOWER_IMPLEMENT, selectedImplement.object, AttacherJoints.actionEventLowerImplement, false, true, false, true, nil, nil, true)
                        end
                    end
                end
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.LOWER_ALL_IMPLEMENTS, self, AttacherJoints.actionEventLowerAllImplements, false, true, false, true, nil, nil, true)
                g_inputBinding:setActionEventTextVisibility(actionEventId, false)
            end
            if self:getSelectedVehicle() == self then
                local selectedImplement, _ = self:registerSelfLoweringActionEvent(spec.actionEvents, InputAction.LOWER_IMPLEMENT, self, AttacherJoints.actionEventLowerImplement, false, true, false, true, nil, nil, true)
                if (selectedImplement == nil or not selectedImplement) and #spec.attachedImplements == 1 then
                    local actionEventId = spec.attachedImplements[1]
                    if actionEventId ~= nil then
                        actionEventId.object:registerLoweringActionEvent(spec.actionEvents, InputAction.LOWER_IMPLEMENT, actionEventId.object, AttacherJoints.actionEventLowerImplement, false, true, false, true, nil, nil, true)
                    end
                end
            end
            local selectedImplement, _ = self:addActionEvent(spec.actionEvents, InputAction.ATTACH, self, AttacherJoints.actionEventAttach, false, true, false, true, nil, nil, true)
            g_inputBinding:setActionEventTextPriority(_, GS_PRIO_VERY_HIGH)
            local actionEventId, _ = self:addActionEvent(spec.actionEvents, InputAction.DETACH, self, AttacherJoints.actionEventDetach, false, true, false, true, nil, nil, true)
            g_inputBinding:setActionEventTextVisibility(_, false)
            AttacherJoints.updateActionEvents(self)
        end
    end
end
function AttacherJoints:onActivate()
    self:activateAttachments()
end
function AttacherJoints:onDeactivate()
    self:deactivateAttachments()
    if self.isClient then
        local spec = self.spec_attacherJoints
        g_soundManager:stopSample(spec.samples.hydraulic)
        spec.isHydraulicSamplePlaying = false
    end
end
function AttacherJoints:onReverseDirectionChanged(_)
    local spec = self.spec_attacherJoints
    local reverserDirection = self:getReverserDirection()
    if spec.attacherJointCombos ~= nil then
        for _, joint in pairs(spec.attacherJointCombos.joints) do
            if reverserDirection < 0 then
                joint.time = math.abs(joint.initialTime - spec.attacherJointCombos.duration)
            else
                joint.time = joint.initialTime
            end
        end
    end
end
function AttacherJoints:onStateChange(state, data)
    local spec = self.spec_attacherJoints
    for _, implement in pairs(spec.attachedImplements) do
        if implement.object ~= nil then
            implement.object:raiseStateChange(state, data)
        end
    end
    if state == VehicleStateChange.LOWER_ALL_IMPLEMENTS and #spec.attacherJoints > 0 then
        self:startAttacherJointCombo()
    end
end
function AttacherJoints:onLightsTypesMaskChanged(lightsTypesMask)
    if self.isServer then
        for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
            local vehicle = implement.object
            if vehicle ~= nil and vehicle.setLightsTypesMask ~= nil then
                vehicle:setLightsTypesMask(lightsTypesMask, true)
            end
        end
    end
end
function AttacherJoints:onTurnLightStateChanged(state)
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        local vehicle = implement.object
        if vehicle ~= nil and vehicle.setTurnLightState ~= nil then
            vehicle:setTurnLightState(state, true, true)
        end
    end
end
function AttacherJoints:onBrakeLightsVisibilityChanged(visibility)
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        local vehicle = implement.object
        if vehicle ~= nil and vehicle.setBrakeLightsVisibility ~= nil then
            vehicle:setBrakeLightsVisibility(visibility)
        end
    end
end
function AttacherJoints:onReverseLightsVisibilityChanged(visibility)
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        local vehicle = implement.object
        if vehicle ~= nil and vehicle.setReverseLightsVisibility ~= nil then
            vehicle:setReverseLightsVisibility(visibility)
        end
    end
end
function AttacherJoints:onBeaconLightsVisibilityChanged(visibility)
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        local vehicle = implement.object
        if vehicle ~= nil and vehicle.setBeaconLightsVisibility ~= nil then
            vehicle:setBeaconLightsVisibility(visibility, true, true)
        end
    end
end
function AttacherJoints:onBrake(brakePedal)
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        local vehicle = implement.object
        if vehicle ~= nil and vehicle.brake ~= nil then
            vehicle:brake(brakePedal)
        end
    end
end
function AttacherJoints:onTurnedOn()
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        local vehicle = implement.object
        if vehicle ~= nil then
            local turnedOnVehicleSpec = vehicle.spec_turnOnVehicle
            if turnedOnVehicleSpec and turnedOnVehicleSpec.turnedOnByAttacherVehicle then
                vehicle:setIsTurnedOn(true, true)
            end
        end
    end
end
function AttacherJoints:onTurnedOff()
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        local vehicle = implement.object
        if vehicle ~= nil then
            local turnedOnVehicleSpec = vehicle.spec_turnOnVehicle
            if turnedOnVehicleSpec and turnedOnVehicleSpec.turnedOnByAttacherVehicle then
                vehicle:setIsTurnedOn(false, true)
            end
        end
    end
end
function AttacherJoints:onLeaveVehicle()
    for _, implement in pairs(self.spec_attacherJoints.attachedImplements) do
        local vehicle = implement.object
        if vehicle ~= nil then
            SpecializationUtil.raiseEvent(vehicle, "onLeaveRootVehicle")
        end
    end
end
function AttacherJoints:getAttachableInfo()
    local info = self.spec_attacherJoints.attachableInfo
    return info.attacherVehicle, info.attacherVehicleJointDescIndex, info.attachable, info.attachableJointDescIndex
end
function AttacherJoints.getAttacherJointCompatibility(vehicle, attacherJoint, inputAttacherVehicle, inputAttacherJoint)
    if inputAttacherJoint.forcedAttachingDirection ~= 0 and (attacherJoint.attacherJointDirection ~= nil and inputAttacherJoint.forcedAttachingDirection ~= attacherJoint.attacherJointDirection) then
        return false
    end
    if attacherJoint.isBlocked then
        return false
    end
    if attacherJoint.subTypes == nil then
        if inputAttacherJoint.subTypes ~= nil then
            if inputAttacherJoint.subTypeShowWarning and attacherJoint.subTypeShowWarning then
                return false, vehicle.spec_attacherJoints.texts.warningToolNotCompatible
            else
                return false
            end
        end
    else
        if inputAttacherJoint.subTypes == nil then
            if attacherJoint.subTypeShowWarning and inputAttacherJoint.subTypeShowWarning then
                return false, vehicle.spec_attacherJoints.texts.warningToolNotCompatible
            else
                return false
            end
        end
        local found = false
        local i = 1
        for i = i, #attacherJoint.subTypes do
            local j = 1
            local i = #inputAttacherJoint.subTypes
            for j = j, i do
                if attacherJoint.subTypes[i] == inputAttacherJoint.subTypes[j] then
                    found = true
                    break
                end
            end
        end
        if not found then
            if attacherJoint.subTypeShowWarning and inputAttacherJoint.subTypeShowWarning then
                return false, vehicle.spec_attacherJoints.texts.warningToolNotCompatible
            else
                return false
            end
        end
    end
    if attacherJoint.brandRestrictions ~= nil then
        local found = false
        local i = 1
        local brandString = #attacherJoint.brandRestrictions
        for i = i, brandString do
            if inputAttacherVehicle.brand ~= nil and inputAttacherVehicle.brand == attacherJoint.brandRestrictions[i] then
                found = true
                break
            end
        end
        if not found then
            local brandString = ""
            local i = 1
            local i = 1
            for i = i, #attacherJoint.brandRestrictions, i do
                if i > 1 then
                end
                brandString = brandString .. attacherJoint.brandRestrictions[i].title
            end
            return false, string.format(vehicle.spec_attacherJoints.texts.warningToolBrandNotCompatible, brandString)
        end
    end
    if attacherJoint.vehicleRestrictions ~= nil then
        local found = false
        local i = 1
        for i = i, #attacherJoint.vehicleRestrictions do
            if inputAttacherVehicle.configFileName:find(attacherJoint.vehicleRestrictions[i]) ~= nil then
                found = true
                break
            end
        end
        if not found then
            return false, vehicle.spec_attacherJoints.texts.warningToolNotCompatible
        end
    end
    local found, brandString = vehicle:getIsAttacherJointCompatible(vehicle, attacherJoint, inputAttacherVehicle, inputAttacherJoint)
    if found then
        return true
    else
        return false, brandString
    end
end
local getAttacherJointCompatibility = AttacherJoints.getAttacherJointCompatibility
function AttacherJoints.findVehicleInAttachRange()
    log("function \'AttacherJoints.findVehicleInAttachRange\' is deprecated. Use \'AttacherJoints.updateVehiclesInAttachRange\' instead. Valid output of this function is now up to 5 frames delayed, if parameter 4 is not \'true\'.")
end
function AttacherJoints.updateVehiclesInAttachRange(vehicle, maxDistanceSq, maxAngle, fullUpdate)
    -- upvalues: (copy) getAttacherJointCompatibility
    local spec = vehicle.spec_attacherJoints
    if spec == nil then
        return nil, nil, nil, nil
    end
    local attachableInfo = spec.attachableInfo
    if vehicle.getAttachedImplements ~= nil then
        local implements = vehicle:getAttachedImplements()
        for _, implement in pairs(implements) do
            if implement.object ~= nil then
                local attacherVehicle, attacherVehicleJointDescIndex, attachable, attachableJointDescIndex, warning = AttacherJoints.updateVehiclesInAttachRange(implement.object, maxDistanceSq, maxAngle, fullUpdate)
                if attacherVehicle ~= nil then
                    attachableInfo.attacherVehicle = attacherVehicle
                    attachableInfo.attacherVehicleJointDescIndex = attacherVehicleJointDescIndex
                    attachableInfo.attachable = attachable
                    attachableInfo.attachableJointDescIndex = attachableJointDescIndex
                    attachableInfo.warning = warning
                    return attacherVehicle, attacherVehicleJointDescIndex, attachable, attachableJointDescIndex, warning
                end
            end
        end
    end
    local implements = #g_currentMission.vehicleSystem.inputAttacherJoints
    local lastJoint = implements / 5
    local firstJoint = math.floor(lastJoint)
    local minUpdateJoints = math.max(firstJoint, 1)
    local firstJoint = spec.lastInputAttacherCheckIndex % implements + 1
    local lastJoint = math.min(_, implements)
    if fullUpdate then
        firstJoint = 1
        lastJoint = implements
    end
    spec.lastInputAttacherCheckIndex = lastJoint % implements
    local attacherVehicle = 1
    local implement = 1
    for attacherVehicle = attacherVehicle, firstJoint + minUpdateJoints, implement do
        local attacherVehicleJointDescIndex = spec.attacherJoints[attacherVehicle]
        if attacherVehicleJointDescIndex.jointIndex == 0 and vehicle:getIsAttachingAllowed(attacherVehicleJointDescIndex) then
            local attachable, attachableJointDescIndex, warning = getWorldTranslation(attacherVehicleJointDescIndex.jointTransform)
            for i = firstJoint, lastJoint do
                local jointInfo = g_currentMission.vehicleSystem.inputAttacherJoints[i]
                if jointInfo.jointType == attacherVehicleJointDescIndex.jointType and jointInfo.vehicle:getIsInputAttacherActive(jointInfo.inputAttacherJoint) then
                    local distSq = MathUtil.vector2LengthSq(attachable - jointInfo.translation[1], warning - jointInfo.translation[3])
                    if distSq < maxDistanceSq and distSq < spec.pendingAttachableInfo.minDistance then
                        local distY = attachableJointDescIndex - jointInfo.translation[2]
                        local distSqY = distY * distY
                        if distSqY < maxDistanceSq * 4 and (distSqY < pendingInfo.minDistanceY and (jointInfo.vehicle:getActiveInputAttacherJointDescIndex() == nil or jointInfo.vehicle:getAllowMultipleAttachments())) then
                            local compatibility, notAllowedWarning = getAttacherJointCompatibility(vehicle, attacherVehicleJointDescIndex, jointInfo.vehicle, jointInfo.inputAttacherJoint)
                            if compatibility then
                                local attachAngleLimitAxis = jointInfo.inputAttacherJoint.attachAngleLimitAxis
                                local angleInRange
                                if attachAngleLimitAxis == 1 then
                                    local dx, _, _ = localDirectionToLocal(jointInfo.node, attacherVehicleJointDescIndex.jointTransform, 1, 0, 0)
                                    angleInRange = maxAngle < dx
                                elseif attachAngleLimitAxis == 2 then
                                    local dx, _, _ = localDirectionToLocal(jointInfo.node, attacherVehicleJointDescIndex.jointTransform, 0, 1, 0)
                                    angleInRange = maxAngle < _
                                else
                                    local dx, _, _ = localDirectionToLocal(jointInfo.node, attacherVehicleJointDescIndex.jointTransform, 0, 0, 1)
                                    angleInRange = maxAngle < _
                                end
                                if angleInRange then
                                    pendingInfo.minDistance = distSq
                                    pendingInfo.minDistanceY = distSqY
                                    pendingInfo.attacherVehicle = vehicle
                                    pendingInfo.attacherVehicleJointDescIndex = attacherVehicle
                                    pendingInfo.attachable = jointInfo.vehicle
                                    pendingInfo.attachableJointDescIndex = jointInfo.jointIndex
                                end
                            else
                                pendingInfo.warning = pendingInfo.warning or notAllowedWarning
                            end
                        end
                    end
                end
            end
        end
    end
    if spec.lastInputAttacherCheckIndex == 0 or implements == 0 then
        attachableInfo.attacherVehicle = pendingInfo.attacherVehicle
        attachableInfo.attacherVehicleJointDescIndex = pendingInfo.attacherVehicleJointDescIndex
        attachableInfo.attachable = pendingInfo.attachable
        attachableInfo.attachableJointDescIndex = pendingInfo.attachableJointDescIndex
        attachableInfo.warning = pendingInfo.warning
        pendingInfo.minDistance = math.huge
        pendingInfo.minDistanceY = math.huge
        pendingInfo.attacherVehicle = nil
        pendingInfo.attacherVehicleJointDescIndex = nil
        pendingInfo.attachable = nil
        pendingInfo.attachableJointDescIndex = nil
        pendingInfo.warning = nil
    end
    return attachableInfo.attacherVehicle, attachableInfo.attacherVehicleJointDescIndex, attachableInfo.attachable, attachableInfo.attachableJointDescIndex, attachableInfo.warning
end
function AttacherJoints:actionEventAttach(_, _, _, _)
    local info = self.spec_attacherJoints.attachableInfo
    if info.attachable == nil then
        local attachAllowed = self:getSelectedVehicle()
        if attachAllowed ~= nil and (attachAllowed ~= self and attachAllowed.isDetachAllowed ~= nil) then
            local warning, warning, showWarning = attachAllowed:isDetachAllowed()
            if warning then
                attachAllowed:startDetachProcess()
                return
            end
            if showWarning == nil or showWarning then
                g_currentMission:showBlinkingWarning(warning or self.spec_attacherJoints.texts.detachNotAllowed, 2000)
            end
        end
    else
        local attachAllowed, warning = info.attachable:isAttachAllowed(self:getActiveFarm(), info.attacherVehicle)
        if attachAllowed then
            if self.isServer then
                self:attachImplementFromInfo(info)
            else
                g_client:getServerConnection():sendEvent(VehicleAttachRequestEvent.new(info))
            end
        end
        if warning ~= nil then
            g_currentMission:showBlinkingWarning(warning, 2000)
            return
        end
    end
end
function AttacherJoints:actionEventDetach(_, _, _, _)
    local object = self:getSelectedVehicle()
    if object ~= nil and (object ~= self and object.isDetachAllowed ~= nil) then
        local detachAllowed, warning, showWarning = object:isDetachAllowed()
        if detachAllowed then
            object:startDetachProcess()
            return
        end
        if showWarning == nil or showWarning then
            g_currentMission:showBlinkingWarning(warning or self.spec_attacherJoints.texts.detachNotAllowed, 2000)
        end
    end
end
function AttacherJoints:actionEventLowerImplement(_, _, _, _)
    if self.getAttacherVehicle ~= nil then
        self:getAttacherVehicle():handleLowerImplementEvent()
    end
end
function AttacherJoints:actionEventLowerAllImplements(_, _, _, _)
    self:startAttacherJointCombo(true)
    self.rootVehicle:raiseStateChange(VehicleStateChange.LOWER_ALL_IMPLEMENTS)
end
function AttacherJoints:updateActionEvents()
    local spec = self.spec_attacherJoints
    if self.isClient and spec.actionEvents ~= nil then
        local attachActionEvent = spec.actionEvents[InputAction.ATTACH]
        if attachActionEvent ~= nil then
            local visible = false
            if self:getCanToggleAttach() then
                if spec.attachableInfo.warning ~= nil then
                    g_currentMission:showBlinkingWarning(info.warning, 500)
                end
                local text = ""
                local prio = GS_PRIO_VERY_LOW
                local selectedVehicle = self:getSelectedVehicle()
                if selectedVehicle ~= nil and (not selectedVehicle.isDeleted and (selectedVehicle.isDetachAllowed ~= nil and (selectedVehicle:isDetachAllowed() and selectedVehicle:getAttacherVehicle() ~= nil))) then
                    visible = true
                    text = spec.texts.actionDetach
                end
                if info.attacherVehicle ~= nil then
                    if g_currentMission.accessHandler:canFarmAccess(self:getActiveFarm(), info.attachable) then
                        visible = true
                        text = spec.texts.actionAttach
                        g_currentMission:showAttachContext(info.attachable)
                        prio = GS_PRIO_VERY_HIGH
                    else
                        spec.showAttachNotAllowedText = 100
                    end
                end
                g_inputBinding:setActionEventText(attachActionEvent.actionEventId, text)
                g_inputBinding:setActionEventTextPriority(attachActionEvent.actionEventId, prio)
            end
            g_inputBinding:setActionEventTextVisibility(attachActionEvent.actionEventId, visible)
        end
        local visible = spec.actionEvents[InputAction.LOWER_IMPLEMENT]
        if visible ~= nil then
            local text = false
            local prio = ""
            local selectedVehicle = self:getSelectedImplement()
            if selectedVehicle == nil then
                if #spec.attachedImplements == 1 then
                    text, prio = spec.attachedImplements[1].object:getLoweringActionEventState()
                end
            else
                for _, attachedImplement in pairs(spec.attachedImplements) do
                    if attachedImplement == selectedVehicle then
                        text, prio = attachedImplement.object:getLoweringActionEventState()
                        break
                    end
                end
            end
            g_inputBinding:setActionEventActive(visible.actionEventId, text)
            g_inputBinding:setActionEventText(visible.actionEventId, prio)
            g_inputBinding:setActionEventTextPriority(visible.actionEventId, GS_PRIO_NORMAL)
        end
    end
end
function AttacherJoints.updateAttacherJointLimits(implement, attacherJointDesc, inputAttacherJointDesc, axis)
    local lowerRotLimit = attacherJointDesc.lowerRotLimit[axis] * inputAttacherJointDesc.lowerRotLimitScale[axis]
    local upperRotLimit = attacherJointDesc.upperRotLimit[axis] * inputAttacherJointDesc.upperRotLimitScale[axis]
    if inputAttacherJointDesc.fixedRotation then
        lowerRotLimit = 0
        upperRotLimit = 0
    end
    local upperTransLimit = attacherJointDesc.lowerTransLimit[axis] * inputAttacherJointDesc.lowerTransLimitScale[axis]
    local lowerTransLimit = attacherJointDesc.upperTransLimit[axis] * inputAttacherJointDesc.upperTransLimitScale[axis]
    implement.lowerRotLimit[axis] = lowerRotLimit
    implement.upperRotLimit[axis] = upperRotLimit
    implement.lowerTransLimit[axis] = upperTransLimit
    implement.upperTransLimit[axis] = lowerTransLimit
    if not attacherJointDesc.allowsLowering then
        implement.upperRotLimit[axis] = lowerRotLimit
        implement.upperTransLimit[axis] = upperTransLimit
    end
    if attacherJointDesc.allowsLowering and attacherJointDesc.allowsJointLimitMovement then
        if inputAttacherJointDesc.allowsJointRotLimitMovement then
            lowerRotLimit = MathUtil.lerp(upperRotLimit, lowerRotLimit, attacherJointDesc.moveAlpha)
        end
        if inputAttacherJointDesc.allowsJointTransLimitMovement then
            upperTransLimit = MathUtil.lerp(lowerTransLimit, upperTransLimit, attacherJointDesc.moveAlpha)
        end
    end
    return lowerRotLimit, upperTransLimit
end
function AttacherJoints.updateAttacherJointRotationLimit(implement, attacherJointDesc, axis, force, alpha)
    local newRotLimit = MathUtil.lerp
    local rotLimitUp = implement.attachingRotLimit[axis]
    local rotLimit = implement.upperRotLimit[axis]
    local rotLimitDown = math.max(rotLimitUp, rotLimit)
    local rotLimit = implement.attachingRotLimit[axis]
    local newRotLimit = newRotLimit(rotLimitDown, math.max(rotLimit, implement.lowerRotLimit[axis]), alpha)
    if not force then
        if math.abs(newRotLimit - implement.jointRotLimit[axis]) <= 0.0005 then
            ::l3::
            return
        end
    end
    local rotLimitDown = -newRotLimit
    local rotLimit
    if axis == 3 then
        if attacherJointDesc.lockDownRotLimit then
            rotLimitDown = math.min(-implement.attachingRotLimit[axis], 0)
        end
        if attacherJointDesc.lockUpRotLimit then
            rotLimit = math.max(implement.attachingRotLimit[axis], 0)
        else
            rotLimit = newRotLimit
        end
        if attacherJointDesc.dynamicLowerRotLimit and attacherJointDesc.rotationNode ~= nil then
            rotLimit = math.abs(attacherJointDesc.upperRotation[1] - attacherJointDesc.lowerRotation[1]) * alpha
            rotLimitDown = 0
        end
    else
        rotLimit = newRotLimit
    end
    setJointRotationLimit(attacherJointDesc.jointIndex, axis - 1, true, rotLimitDown, rotLimit)
    implement.jointRotLimit[axis] = newRotLimit
    goto l3
end
function AttacherJoints.updateAttacherJointTranslationLimit(implement, attacherJointDesc, axis, force, alpha)
    local newTransLimit = MathUtil.lerp
    local transLimitUp = implement.attachingTransLimit[axis]
    local transLimitDown = math.max(transLimitUp, implement.upperTransLimit[axis])
    local newTransLimit = newTransLimit(transLimitDown, math.max(implement.attachingTransLimit[axis], implement.lowerTransLimit[axis]), alpha)
    if force then
        ::l2::
        local transLimitDown = -newTransLimit
        local transLimitUp
        if axis == 2 then
            if attacherJointDesc.lockDownTransLimit then
                transLimitDown = math.min(-implement.attachingTransLimit[axis], 0)
            end
            if attacherJointDesc.lockUpTransLimit then
                transLimitUp = math.max(implement.attachingTransLimit[axis], 0)
            else
                transLimitUp = newTransLimit
            end
        else
            transLimitUp = newTransLimit
        end
        setJointTranslationLimit(attacherJointDesc.jointIndex, axis - 1, true, transLimitDown, transLimitUp)
        implement.jointTransLimit[axis] = newTransLimit
    elseif math.abs(newTransLimit - implement.jointTransLimit[axis]) > 0.0005 then
        goto l2
    end
end
function AttacherJoints:updateRequiredTopLightsState()
    local spec = self.spec_attacherJoints
    local requiresTopLights = false
    for i, implement in ipairs(spec.attachedImplements) do
        local implementJoint = implement.object:getActiveInputAttacherJoint()
        if spec.attacherJoints[implement.jointDescIndex].useTopLights and implementJoint.useTopLights then
            requiresTopLights = true
            break
        end
    end
    SpecializationUtil.raiseEvent(self, "onRequiresTopLightsChanged", requiresTopLights)
end
function AttacherJoints.consoleCommandBottomArmWidth(_, category, width)
    if width == nil then
        width = AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[tonumber(category) or 2]
    else
        width = tonumber(width) or AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[2]
    end
    Logging.info("Set bottom arm width to %.3f m. (Category %d)", width, AttacherJoints.getClosestLowerLinkCategoryIndex(width))
    if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
        for i, vehicle in ipairs(g_localPlayer:getCurrentVehicle().childVehicles) do
            local spec = vehicle.spec_attacherJoints
            if spec ~= nil then
                for jointDescIndex, _ in ipairs(spec.attacherJoints) do
                    vehicle:setAttacherJointBottomArmWidth(jointDescIndex, width)
                end
            end
        end
    end
end
addConsoleCommand("gsVehicleBottomArmSetWidth", "Sets the width of the bottom arm to a certain category width", "consoleCommandBottomArmWidth", AttacherJoints)