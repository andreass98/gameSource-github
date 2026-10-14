Cylindered = {}
Cylindered.DIRTY_COLLISION_UPDATE_CHECK = false
Cylindered.MOVING_TOOL_SEND_MIN_RESOLUTION = 0.006981317007977318
Cylindered.MOVING_TOOLS_XML_KEYS = { "vehicle.cylindered.movingTools", "vehicle.cylindered.cylinderedConfigurations.cylinderedConfiguration(?).movingTools" }
Cylindered.MOVING_PART_XML_KEYS = { "vehicle.cylindered.movingParts.movingPart(?)", "vehicle.cylindered.cylinderedConfigurations.cylinderedConfiguration(?).movingParts.movingPart(?)" }
Cylindered.DASHBOARD_XML_KEYS = { "vehicle.cylindered.dashboards", "vehicle.cylindered.cylinderedConfigurations.cylinderedConfiguration(?).dashboards" }
Cylindered.SOUND_TYPE_EVENT = 0
Cylindered.SOUND_TYPE_CONTINUES = 1
Cylindered.SOUND_TYPE_ENDING = 2
Cylindered.SOUND_TYPE_STARTING = 3
Cylindered.SOUND_ACTION_TRANSLATING_END = 0
Cylindered.SOUND_ACTION_TRANSLATING_END_POS = 1
Cylindered.SOUND_ACTION_TRANSLATING_END_NEG = 2
Cylindered.SOUND_ACTION_TRANSLATING_START = 3
Cylindered.SOUND_ACTION_TRANSLATING_START_POS = 4
Cylindered.SOUND_ACTION_TRANSLATING_START_NEG = 5
Cylindered.SOUND_ACTION_TRANSLATING_POS = 6
Cylindered.SOUND_ACTION_TRANSLATING_NEG = 7
Cylindered.SOUND_ACTION_TOOL_MOVE_END = 8
Cylindered.SOUND_ACTION_TOOL_MOVE_END_POS = 9
Cylindered.SOUND_ACTION_TOOL_MOVE_END_NEG = 10
Cylindered.SOUND_ACTION_TOOL_MOVE_END_POS_LIMIT = 11
Cylindered.SOUND_ACTION_TOOL_MOVE_END_NEG_LIMIT = 12
Cylindered.SOUND_ACTION_TOOL_MOVE_START = 13
Cylindered.SOUND_ACTION_TOOL_MOVE_START_POS = 14
Cylindered.SOUND_ACTION_TOOL_MOVE_START_NEG = 15
Cylindered.SOUND_ACTION_TOOL_MOVE_START_POS_LIMIT = 16
Cylindered.SOUND_ACTION_TOOL_MOVE_START_NEG_LIMIT = 17
Cylindered.SOUND_ACTION_TOOL_MOVE_POS = 18
Cylindered.SOUND_ACTION_TOOL_MOVE_NEG = 19
function Cylindered.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(VehicleSettings, specializations)
end
function Cylindered.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("cylindered", g_i18n:getText("shop_configuration"), "cylindered", VehicleConfigurationItem)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Cylindered")
    schema:register(XMLValueType.TIME, "vehicle.cylindered.movingTools#powerConsumingActiveTimeOffset", "Power consumer deactivation delay. After the moving tool has not been moved this long it will no longer consume power.", 5)
    Cylindered.registerSoundXMLPaths(schema, "vehicle.cylindered.sounds")
    Cylindered.registerSoundXMLPaths(schema, "vehicle.cylindered.cylinderedConfigurations.cylinderedConfiguration(?).sounds")
    for _, toolKey in ipairs(Cylindered.MOVING_TOOLS_XML_KEYS) do
        Cylindered.registerMovingToolXMLPaths(schema, toolKey .. ".movingTool(?)")
        Cylindered.registerEasyArmControlXMLPaths(schema, toolKey .. ".easyArmControl")
        schema:register(XMLValueType.L10N_STRING, toolKey .. ".controlGroups.controlGroup(?)#name", "Control group name")
    end
    for _, toolKey in ipairs(Cylindered.MOVING_PART_XML_KEYS) do
        Cylindered.registerMovingPartXMLPaths(schema, toolKey)
    end
    schema:addDelayedRegistrationFunc("Cylindered:movingPart", function(cSchema, cKey)
        cSchema:register(XMLValueType.INT, cKey .. "#inputAttacherJointIndex", "Input Attacher Joint Index [1..n]")
    end)
    for _, toolKey in ipairs(Cylindered.DASHBOARD_XML_KEYS) do
        Dashboard.registerDashboardXMLPaths(schema, toolKey, { "movingTool" })
        schema:register(XMLValueType.STRING, toolKey .. ".dashboard(?)#axis", "Moving tool input action name")
        schema:register(XMLValueType.INT, toolKey .. ".dashboard(?)#attacherJointIndex", "Index of attacher joint that has to be connected")
        schema:register(XMLValueType.NODE_INDEX, toolKey .. ".dashboard(?)#attacherJointNode", "Node of attacher joint that has to be connected")
        schema:register(XMLValueType.NODE_INDICES, toolKey .. ".dashboard(?)#attacherJointNodes", "List of attacher joints nodes that has to be connected (on of them)")
    end
    ObjectChangeUtil.addAdditionalObjectChangeXMLPaths(schema, function(_schema, key)
        _schema:register(XMLValueType.ANGLE, key .. "#movingToolRotMaxActive", "Moving tool max. rotation if object change active")
        _schema:register(XMLValueType.ANGLE, key .. "#movingToolRotMaxInactive", "Moving tool max. rotation if object change inactive")
        _schema:register(XMLValueType.ANGLE, key .. "#movingToolRotMinActive", "Moving tool min. rotation if object change active")
        _schema:register(XMLValueType.ANGLE, key .. "#movingToolRotMinInactive", "Moving tool min. rotation if object change inactive")
        _schema:register(XMLValueType.ANGLE, key .. "#movingToolStartRotActive", "Moving tool start rotation if object change inactive")
        _schema:register(XMLValueType.ANGLE, key .. "#movingToolStartRotInactive", "Moving tool start rotation if object change inactive")
        _schema:register(XMLValueType.FLOAT, key .. "#movingToolTransMaxActive", "Moving tool max. translation if object change active")
        _schema:register(XMLValueType.FLOAT, key .. "#movingToolTransMaxInactive", "Moving tool max. translation if object change inactive")
        _schema:register(XMLValueType.FLOAT, key .. "#movingToolTransMinActive", "Moving tool min. translation if object change active")
        _schema:register(XMLValueType.FLOAT, key .. "#movingToolTransMinInactive", "Moving tool min. translation if object change inactive")
        _schema:register(XMLValueType.FLOAT, key .. "#movingToolStartTransActive", "Moving tool start translation if object change inactive")
        _schema:register(XMLValueType.FLOAT, key .. "#movingToolStartTransInactive", "Moving tool start translation if object change inactive")
        _schema:register(XMLValueType.BOOL, key .. "#movingPartUpdateActive", "moving part active state if object change active")
        _schema:register(XMLValueType.BOOL, key .. "#movingPartUpdateInactive", "moving part active state if object change inactive")
    end)
    schema:register(XMLValueType.NODE_INDEX, Dischargeable.DISCHARGE_NODE_XML_PATH .. ".movingToolActivation#node", "Moving tool node")
    schema:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_XML_PATH .. ".movingToolActivation#isInverted", "Activation is inverted", false)
    schema:register(XMLValueType.FLOAT, Dischargeable.DISCHARGE_NODE_XML_PATH .. ".movingToolActivation#openFactor", "Open factor", 1)
    schema:register(XMLValueType.FLOAT, Dischargeable.DISCHARGE_NODE_XML_PATH .. ".movingToolActivation#openOffset", "Open offset", 0)
    schema:register(XMLValueType.NODE_INDEX, Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH .. ".movingToolActivation#node", "Moving tool node")
    schema:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH .. ".movingToolActivation#isInverted", "Activation is inverted", false)
    schema:register(XMLValueType.FLOAT, Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH .. ".movingToolActivation#openFactor", "Open factor", 1)
    schema:register(XMLValueType.FLOAT, Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH .. ".movingToolActivation#openOffset", "Open offset", 0)
    schema:register(XMLValueType.NODE_INDEX, Shovel.SHOVEL_NODE_XML_KEY .. ".movingToolActivation#node", "Moving tool node")
    schema:register(XMLValueType.BOOL, Shovel.SHOVEL_NODE_XML_KEY .. ".movingToolActivation#isInverted", "Activation is inverted", false)
    schema:register(XMLValueType.FLOAT, Shovel.SHOVEL_NODE_XML_KEY .. ".movingToolActivation#openFactor", "Open factor", 1)
    schema:register(XMLValueType.NODE_INDEX, DynamicMountAttacher.DYNAMIC_MOUNT_GRAB_XML_PATH .. ".movingToolActivation#node", "Moving tool node")
    schema:register(XMLValueType.BOOL, DynamicMountAttacher.DYNAMIC_MOUNT_GRAB_XML_PATH .. ".movingToolActivation#isInverted", "Activation is inverted", false)
    schema:register(XMLValueType.FLOAT, DynamicMountAttacher.DYNAMIC_MOUNT_GRAB_XML_PATH .. ".movingToolActivation#openFactor", "Open factor", 1)
    schema:addDelayedRegistrationFunc("AnimatedVehicle:part", function(cSchema, cKey)
        cSchema:register(XMLValueType.NODE_INDEX, cKey .. "#startReferencePoint", "Start reference point")
        cSchema:register(XMLValueType.NODE_INDEX, cKey .. "#endReferencePoint", "End reference point")
    end)
    schema:setXMLSpecializationType()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).cylindered.movingTool(?)#translation", "Current translation value")
    schemaSavegame:register(XMLValueType.ANGLE, "vehicles.vehicle(?).cylindered.movingTool(?)#rotation", "Current rotation in rad")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).cylindered.movingTool(?)#animationTime", "Current animation time")
end
function Cylindered.registerSoundXMLPaths(schema, baseKey)
    SoundManager.registerSampleXMLPaths(schema, baseKey, "hydraulic")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "actionSound(?)")
    schema:register(XMLValueType.STRING, baseKey .. ".actionSound(?)#actionNames", "Target actions on given nodes")
    schema:register(XMLValueType.STRING, baseKey .. ".actionSound(?)#nodes", "Nodes that can activate this sound on given action events")
    schema:register(XMLValueType.FLOAT, baseKey .. ".actionSound(?).pitch#dropOffFactor", "Factor that is applied to pitch while drop off time is active", 1)
    schema:register(XMLValueType.FLOAT, baseKey .. ".actionSound(?).pitch#dropOffTime", "After this time the sound will be deactivated", 0)
end
function Cylindered.registerEasyArmControlXMLPaths(schema, key)
    schema:register(XMLValueType.NODE_INDEX, key .. "#rootNode", "Root node")
    schema:register(XMLValueType.NODE_INDEX, key .. "#node", "Node")
    schema:register(XMLValueType.NODE_INDEX, key .. "#targetNodeZ", "Z target node")
    schema:register(XMLValueType.NODE_INDEX, key .. "#refNode", "Reference node")
    schema:register(XMLValueType.FLOAT, key .. "#maxTotalDistance", "Max. total distance the arms can move from rootNode", "automatically calculated")
    schema:register(XMLValueType.FLOAT, key .. ".targetMovement#speed", "Target node move speed", 1)
    schema:register(XMLValueType.FLOAT, key .. ".targetMovement#acceleration", "Target node move acceleration", 50)
    schema:register(XMLValueType.FLOAT, key .. ".zTranslationNodes#minMoveRatio", "Min. ratio between translation and rotation movement [0: only rotation, 1: only translation]", 0.2)
    schema:register(XMLValueType.FLOAT, key .. ".zTranslationNodes#maxMoveRatio", "Max. ratio between translation and rotation movement [0: only rotation, 1: only translation]", 0.8)
    schema:register(XMLValueType.FLOAT, key .. ".zTranslationNodes#moveRatioMinDir", "Defines direction value when the translation parts start to move", 0)
    schema:register(XMLValueType.FLOAT, key .. ".zTranslationNodes#moveRatioMaxDir", "Defines direction value when the rotation parts stop to move", 1)
    schema:register(XMLValueType.BOOL, key .. ".zTranslationNodes#allowNegativeTrans", "Allow translation movement if translation parts are pointing towards the root node", false)
    schema:register(XMLValueType.FLOAT, key .. ".zTranslationNodes#minNegativeTrans", "Min. translation percentage when moving the translation parts into negative direction while they are pointing towards the root node", 0)
    schema:register(XMLValueType.NODE_INDEX, key .. ".zTranslationNodes.zTranslationNode(?)#node", "Z translation node")
    schema:register(XMLValueType.NODE_INDEX, key .. ".xRotationNodes.xRotationNode1#node", "X translation node")
    schema:register(XMLValueType.NODE_INDEX, key .. ".xRotationNodes.xRotationNode2#node", "X translation node")
end
function Cylindered.registerMovingToolXMLPaths(schema, toolKey)
    schema:addDelayedRegistrationPath(toolKey, "Cylindered:movingTool")
    schema:register(XMLValueType.NODE_INDEX, toolKey .. "#node", "Node")
    schema:register(XMLValueType.BOOL, toolKey .. "#isEasyControlTarget", "Is easy control target", false)
    schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#rotSpeed", "Rotation speed")
    schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#rotAcceleration", "Rotation acceleration")
    schema:register(XMLValueType.INT, toolKey .. ".rotation#rotationAxis", "Rotation axis", 1)
    schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#rotMax", "Max. rotation")
    schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#rotMin", "Min. rotation")
    schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#startRot", "Start rotation")
    schema:register(XMLValueType.BOOL, toolKey .. ".rotation#syncMaxRotLimits", "Synchronize max. rotation limits", false)
    schema:register(XMLValueType.BOOL, toolKey .. ".rotation#syncMinRotLimits", "Synchronize min. rotation limits", false)
    schema:register(XMLValueType.INT, toolKey .. ".rotation#rotSendNumBits", "Number of bits to synchronize", "automatically calculated by rotation range")
    schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#attachRotMax", "Max. rotation value set during attach")
    schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#attachRotMin", "Min. rotation value set during attach")
    schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#detachingRotMaxLimit", "Max. rotation to detach vehicle")
    schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#detachingRotMinLimit", "Min. rotation to detach vehicle")
    schema:register(XMLValueType.FLOAT, toolKey .. ".translation#transSpeed", "Translation speed")
    schema:register(XMLValueType.FLOAT, toolKey .. ".translation#transAcceleration", "Translation acceleration")
    schema:register(XMLValueType.INT, toolKey .. ".translation#translationAxis", "Translation axis")
    schema:register(XMLValueType.FLOAT, toolKey .. ".translation#transMax", "Max. translation")
    schema:register(XMLValueType.FLOAT, toolKey .. ".translation#transMin", "Min. translation")
    schema:register(XMLValueType.FLOAT, toolKey .. ".translation#startTrans", "Start translation")
    schema:register(XMLValueType.FLOAT, toolKey .. ".translation#attachTransMax", "Max. translation value set during attach")
    schema:register(XMLValueType.FLOAT, toolKey .. ".translation#attachTransMin", "Min. translation value set during attach")
    schema:register(XMLValueType.FLOAT, toolKey .. ".translation#detachingTransMaxLimit", "Max. translation to detach vehicle")
    schema:register(XMLValueType.FLOAT, toolKey .. ".translation#detachingTransMinLimit", "Min. translation to detach vehicle")
    schema:register(XMLValueType.STRING, toolKey .. "#requiredConfigurationName", "Name of configuration that is required to use this moving tool")
    schema:register(XMLValueType.VECTOR_N, toolKey .. "#requiredConfigurationIndices", "List of configuration indices that are required to use this moving tool")
    schema:register(XMLValueType.BOOL, toolKey .. "#playSound", "Play sound", false)
    schema:register(XMLValueType.STRING, toolKey .. ".animation#animName", "Animation name")
    schema:register(XMLValueType.FLOAT, toolKey .. ".animation#animSpeed", "Animation speed")
    schema:register(XMLValueType.FLOAT, toolKey .. ".animation#animAcceleration", "Animation acceleration")
    schema:register(XMLValueType.INT, toolKey .. ".animation#animSendNumBits", "Number of bits to synchronize", 8)
    schema:register(XMLValueType.FLOAT, toolKey .. ".animation#animMaxTime", "Animation max. time", 1)
    schema:register(XMLValueType.FLOAT, toolKey .. ".animation#animMinTime", "Animation min. time", 0)
    schema:register(XMLValueType.FLOAT, toolKey .. ".animation#animStartTime", "Animation start time")
    schema:register(XMLValueType.STRING, toolKey .. ".controls#iconName", "Icon identifier")
    schema:registerAutoCompletionDataSource(toolKey .. ".controls#iconName", "$dataS/axisIcons.xml", "axisIcons.icon#name")
    schema:register(XMLValueType.INT, toolKey .. ".controls#groupIndex", "Control group index", 0)
    schema:register(XMLValueType.STRING, toolKey .. ".controls#axis", "Input action name")
    schema:register(XMLValueType.BOOL, toolKey .. ".controls#invertAxis", "Invert input axis", false)
    schema:register(XMLValueType.FLOAT, toolKey .. ".controls#mouseSpeedFactor", "Mouse speed factor", 1)
    schema:register(XMLValueType.BOOL, toolKey .. "#allowSaving", "Allow saving", true)
    schema:register(XMLValueType.FLOAT, toolKey .. "#aiActivePosition", "Position of the moving tool (trans, rot, anim) while the AI is active [0-1]. Position will then be enforced when the AI starts to work.")
    schema:register(XMLValueType.BOOL, toolKey .. "#isIntitialDirty", "Is initial dirty", true)
    schema:register(XMLValueType.NODE_INDEX, toolKey .. "#delayedNode", "Delayed node")
    schema:register(XMLValueType.INT, toolKey .. "#delayedFrames", "Delayed frames", 3)
    schema:register(XMLValueType.BOOL, toolKey .. "#isConsumingPower", "While tool is moving the power consumer is set active", false)
    schema:register(XMLValueType.NODE_INDEX, toolKey .. ".dependentPart(?)#node", "Dependent part")
    schema:register(XMLValueType.STRING, toolKey .. ".dependentPart(?)#maxUpdateDistance", "Max. distance to vehicle root to update dependent part (\'-\' means unlimited)", "-")
    schema:register(XMLValueType.VECTOR_N, toolKey .. "#wheelIndices", "List of wheel indices to update")
    schema:register(XMLValueType.STRING, toolKey .. "#wheelNodes", "List of wheel nodes to update")
    schema:register(XMLValueType.BOOL, toolKey .. ".inputAttacherJoint#value", "Update input attacher joint")
    schema:register(XMLValueType.VECTOR_N, toolKey .. ".attacherJoint#jointIndices", "List of attacher joints to update")
    schema:register(XMLValueType.BOOL, toolKey .. ".attacherJoint#ignoreWarning", "No warning is printed if the joint index is not available (due to configurations)", false)
    schema:register(XMLValueType.INT, toolKey .. "#fillUnitIndex", "Fill unit index")
    schema:register(XMLValueType.FLOAT, toolKey .. "#minFillLevel", "Min. fill level")
    schema:register(XMLValueType.FLOAT, toolKey .. "#maxFillLevel", "Max. fill level")
    schema:register(XMLValueType.FLOAT, toolKey .. "#foldMinLimit", "Min. fold time", 0)
    schema:register(XMLValueType.FLOAT, toolKey .. "#foldMaxLimit", "Max. fold time", 1)
    Cylindered.registerDependentComponentJointXMLPaths(schema, toolKey)
    Cylindered.registerDependentAnimationXMLPaths(schema, toolKey)
    Cylindered.registerDependentMovingToolXMLPaths(schema, toolKey)
end
function Cylindered.registerMovingPartXMLPaths(schema, partKey)
    schema:addDelayedRegistrationPath(partKey, "Cylindered:movingPart")
    schema:register(XMLValueType.NODE_INDEX, partKey .. "#node", "Node")
    schema:register(XMLValueType.NODE_INDEX, partKey .. "#referenceFrame", "Reference frame")
    schema:register(XMLValueType.NODE_INDEX, partKey .. "#referencePoint", "Reference point")
    schema:register(XMLValueType.NODE_INDICES, partKey .. "#referencePoints", "List of reference points (average position will be used as reference)")
    schema:register(XMLValueType.BOOL, partKey .. "#invertZ", "Invert Z axis", false)
    schema:register(XMLValueType.BOOL, partKey .. "#scaleZ", "Allow Z axis scaling", false)
    schema:register(XMLValueType.INT, partKey .. "#limitedAxis", "Limited axis")
    schema:register(XMLValueType.BOOL, partKey .. "#isActiveDirty", "Part is permanently updated", false)
    schema:register(XMLValueType.BOOL, partKey .. "#playSound", "Play hydraulic sound", false)
    schema:register(XMLValueType.BOOL, partKey .. "#moveToReferenceFrame", "Move to reference frame", false)
    schema:register(XMLValueType.BOOL, partKey .. "#doLineAlignment", "Do line alignment (line as ref point)", false)
    schema:register(XMLValueType.BOOL, partKey .. "#doInversedLineAlignment", "Do inversed line alignment (line inside part and fixed ref point)", false)
    schema:register(XMLValueType.BOOL, partKey .. "#do3DLineAlignment", "Do 3D line alignment (X and Y rotation is aligned to the given line - line is only allowed to have two points!)", false)
    schema:register(XMLValueType.FLOAT, partKey .. ".orientationLine#partLength", "Part length (Distance from part to line)", 0.5)
    schema:register(XMLValueType.NODE_INDEX, partKey .. ".orientationLine#referenceTransNode", "Node that is moved to the current line position and at the same time is used a referencePoint for the directional alignment of the movingPart")
    schema:register(XMLValueType.NODE_INDEX, partKey .. ".orientationLine#partLengthNode", "Node to measure the part length dynamically")
    schema:register(XMLValueType.NODE_INDEX, partKey .. ".orientationLine.lineNode(?)#node", "Line node")
    schema:register(XMLValueType.BOOL, partKey .. "#doDirectionAlignment", "Do direction alignment", true)
    schema:register(XMLValueType.BOOL, partKey .. "#doRotationAlignment", "Do rotation alignment", false)
    schema:register(XMLValueType.FLOAT, partKey .. "#rotMultiplier", "Rotation multiplier for rotation alignment", 0)
    schema:register(XMLValueType.ANGLE, partKey .. "#minRot", "Min. rotation for limited axis")
    schema:register(XMLValueType.ANGLE, partKey .. "#maxRot", "Max. rotation for limited axis")
    schema:register(XMLValueType.BOOL, partKey .. "#alignToWorldY", "Align part to world Y axis", false)
    schema:register(XMLValueType.NODE_INDEX, partKey .. "#localReferencePoint", "Local reference point")
    schema:register(XMLValueType.NODE_INDEX, partKey .. "#referenceDistancePoint", "Z translation will be used as reference distance")
    schema:register(XMLValueType.FLOAT, partKey .. "#referenceDistance", "Reference distance to be used instead of the current distance in the i3d (distance between node and ref point - or local ref point and ref point)")
    schema:register(XMLValueType.FLOAT, partKey .. "#localReferenceDistance", "Predefined reference distance", "calculated automatically")
    schema:register(XMLValueType.BOOL, partKey .. "#updateLocalReferenceDistance", "Update distance to local reference point", false)
    schema:register(XMLValueType.BOOL, partKey .. "#dynamicLocalReferenceDistance", "Local reference distance will be calculated based on the initial distance and the localReferencePoint direction", false)
    schema:register(XMLValueType.BOOL, partKey .. "#localReferenceTranslate", "Translate to local reference node", false)
    schema:register(XMLValueType.FLOAT, partKey .. "#referenceDistanceThreshold", "Distance threshold to update moving part while isActiveDirty", 0.0001)
    schema:register(XMLValueType.BOOL, partKey .. "#useLocalOffset", "Use local offset", false)
    schema:register(XMLValueType.FLOAT, partKey .. "#referencePointOffset", "Offset to the reference point in Y alignment")
    schema:register(XMLValueType.FLOAT, partKey .. "#directionThreshold", "Direction threshold to update part if vehicle is inactive", 0.0001)
    schema:register(XMLValueType.FLOAT, partKey .. "#directionThresholdActive", "Direction threshold to update part if vehicle is inactive", 0.0001)
    schema:register(XMLValueType.STRING, partKey .. "#maxUpdateDistance", "Max. distance to vehicle root while isActiveDirty is set (\'-\' means unlimited)")
    schema:register(XMLValueType.BOOL, partKey .. "#smoothedDirectionScale", "If moving part is deactivated e.g. due to folding limits the direction is slowly interpolated back to the start direction depending on #smoothedDirectionTime", false)
    schema:register(XMLValueType.TIME, partKey .. "#smoothedDirectionTime", "Defines how low it takes until the part is back in original direction (sec.)", 2)
    schema:register(XMLValueType.BOOL, partKey .. "#debug", "Enables debug rendering for this part", false)
    schema:register(XMLValueType.NODE_INDEX, partKey .. ".dependentPart(?)#node", "Dependent part")
    schema:register(XMLValueType.STRING, partKey .. ".dependentPart(?)#maxUpdateDistance", "Max. distance to vehicle root to update dependent part (\'-\' means unlimited)", "-")
    schema:register(XMLValueType.BOOL, partKey .. "#divideTranslatingDistance", "If true all translating parts will move at the same time. If false they start to move in the order from the xml", true)
    schema:register(XMLValueType.NODE_INDEX, partKey .. ".translatingPart(?)#node", "Translating part")
    schema:register(XMLValueType.FLOAT, partKey .. ".translatingPart(?)#referenceDistance", "Reference distance")
    schema:register(XMLValueType.FLOAT, partKey .. ".translatingPart(?)#minZTrans", "Min. Z Translation")
    schema:register(XMLValueType.FLOAT, partKey .. ".translatingPart(?)#maxZTrans", "Max. Z Translation")
    schema:register(XMLValueType.BOOL, partKey .. ".translatingPart(?)#divideTranslatingDistance", "Define individual division per translating part. E.g. one part is extending without division and two other parts extend afterwards at the same speed.", "movingPart#divideTranslatingDistance")
    schema:register(XMLValueType.VECTOR_N, partKey .. "#wheelIndices", "List of wheel indices to update")
    schema:register(XMLValueType.STRING, partKey .. "#wheelNodes", "List of wheel nodes to update")
    schema:register(XMLValueType.BOOL, partKey .. ".inputAttacherJoint#value", "Update input attacher joint")
    schema:register(XMLValueType.VECTOR_N, partKey .. ".attacherJoint#jointIndices", "List of attacher joints to update")
    schema:register(XMLValueType.BOOL, partKey .. ".attacherJoint#ignoreWarning", "No warning is printed if the joint index is not available (due to configurations)", false)
    Cylindered.registerDependentComponentJointXMLPaths(schema, partKey)
    Cylindered.registerCopyLocalDirectionXMLPaths(schema, partKey)
    Cylindered.registerDependentAnimationXMLPaths(schema, partKey)
    Cylindered.registerDependentMovingToolXMLPaths(schema, partKey)
end
function Cylindered.registerDependentComponentJointXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. ".componentJoint(?)#index", "Dependent component joint index")
    schema:register(XMLValueType.BOOL, basePath .. ".componentJoint(?)#ignoreWarning", "Ignore if the index could not be found (due to configurations for example)", false)
    schema:register(XMLValueType.INT, basePath .. ".componentJoint(?)#anchorActor", "Dependent component anchor actor")
end
function Cylindered.registerCopyLocalDirectionXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".copyLocalDirectionPart(?)#node", "Copy local direction part")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".copyLocalDirectionPart(?)#dirScale", "Direction scale")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".copyLocalDirectionPart(?)#upScale", "Up vector scale")
    Cylindered.registerDependentComponentJointXMLPaths(schema, basePath .. ".copyLocalDirectionPart(?)")
end
function Cylindered.registerDependentAnimationXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".dependentAnimation(?)#name", "Dependent animation name")
    schema:register(XMLValueType.INT, basePath .. ".dependentAnimation(?)#translationAxis", "Translation axis")
    schema:register(XMLValueType.INT, basePath .. ".dependentAnimation(?)#rotationAxis", "Rotation axis")
    schema:register(XMLValueType.INT, basePath .. ".dependentAnimation(?)#useTranslatingPartIndex", "Use translation part index")
    schema:register(XMLValueType.FLOAT, basePath .. ".dependentAnimation(?)#minValue", "Min. reference value")
    schema:register(XMLValueType.FLOAT, basePath .. ".dependentAnimation(?)#maxValue", "Max. reference value")
    schema:register(XMLValueType.BOOL, basePath .. ".dependentAnimation(?)#invert", "Invert reference value", false)
end
function Cylindered.registerDependentMovingToolXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".dependentMovingTool(?)#node", "Dependent part")
    schema:register(XMLValueType.INT, basePath .. ".dependentMovingTool(?)#axis", "Rotation axis of the moving part which is used as reference in the rotationBasedLimits", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".dependentMovingTool(?)#speedScale", "Speed scale")
    schema:register(XMLValueType.BOOL, basePath .. ".dependentMovingTool(?)#requiresMovement", "Requires movement", false)
    schema:register(XMLValueType.ANGLE, basePath .. ".dependentMovingTool(?).rotationBasedLimits.limit(?)#rotation", "Rotation")
    schema:register(XMLValueType.ANGLE, basePath .. ".dependentMovingTool(?).rotationBasedLimits.limit(?)#rotMin", "Min. rotation")
    schema:register(XMLValueType.ANGLE, basePath .. ".dependentMovingTool(?).rotationBasedLimits.limit(?)#rotMax", "Max. rotation")
    schema:register(XMLValueType.FLOAT, basePath .. ".dependentMovingTool(?).rotationBasedLimits.limit(?)#transMin", "Min. translation")
    schema:register(XMLValueType.FLOAT, basePath .. ".dependentMovingTool(?).rotationBasedLimits.limit(?)#transMax", "Max. translation")
    schema:register(XMLValueType.VECTOR_2, basePath .. ".dependentMovingTool(?)#minTransLimits", "Min. translation limits")
    schema:register(XMLValueType.VECTOR_2, basePath .. ".dependentMovingTool(?)#maxTransLimits", "Max. translation limits")
    schema:register(XMLValueType.VECTOR_ROT_2, basePath .. ".dependentMovingTool(?)#minRotLimits", "Min. rotation limits")
    schema:register(XMLValueType.VECTOR_ROT_2, basePath .. ".dependentMovingTool(?)#maxRotLimits", "Max. rotation limits")
end
function Cylindered.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onMovingToolChanged")
end
function Cylindered.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadMovingPartsFromXML", Cylindered.loadMovingPartsFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadMovingPartFromXML", Cylindered.loadMovingPartFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadMovingToolsFromXML", Cylindered.loadMovingToolsFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadMovingToolFromXML", Cylindered.loadMovingToolFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadDependentMovingTools", Cylindered.loadDependentMovingTools)
    SpecializationUtil.registerFunction(vehicleType, "loadEasyArmControlFromXML", Cylindered.loadEasyArmControlFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadDependentParts", Cylindered.loadDependentParts)
    SpecializationUtil.registerFunction(vehicleType, "resolveDependentPartData", Cylindered.resolveDependentPartData)
    SpecializationUtil.registerFunction(vehicleType, "loadDependentComponentJoints", Cylindered.loadDependentComponentJoints)
    SpecializationUtil.registerFunction(vehicleType, "loadDependentAttacherJoints", Cylindered.loadDependentAttacherJoints)
    SpecializationUtil.registerFunction(vehicleType, "loadDependentWheels", Cylindered.loadDependentWheels)
    SpecializationUtil.registerFunction(vehicleType, "loadDependentTranslatingParts", Cylindered.loadDependentTranslatingParts)
    SpecializationUtil.registerFunction(vehicleType, "loadExtraDependentParts", Cylindered.loadExtraDependentParts)
    SpecializationUtil.registerFunction(vehicleType, "loadDependentAnimations", Cylindered.loadDependentAnimations)
    SpecializationUtil.registerFunction(vehicleType, "loadCopyLocalDirectionParts", Cylindered.loadCopyLocalDirectionParts)
    SpecializationUtil.registerFunction(vehicleType, "loadRotationBasedLimits", Cylindered.loadRotationBasedLimits)
    SpecializationUtil.registerFunction(vehicleType, "loadActionSoundsFromXML", Cylindered.loadActionSoundsFromXML)
    SpecializationUtil.registerFunction(vehicleType, "checkMovingPartDirtyUpdateNode", Cylindered.checkMovingPartDirtyUpdateNode)
    SpecializationUtil.registerFunction(vehicleType, "updateDirtyMovingParts", Cylindered.updateDirtyMovingParts)
    SpecializationUtil.registerFunction(vehicleType, "setMovingToolDirty", Cylindered.setMovingToolDirty)
    SpecializationUtil.registerFunction(vehicleType, "setMovingPartReferenceNode", Cylindered.setMovingPartReferenceNode)
    SpecializationUtil.registerFunction(vehicleType, "updateMovingPartByNode", Cylindered.updateMovingPartByNode)
    SpecializationUtil.registerFunction(vehicleType, "updateCylinderedInitial", Cylindered.updateCylinderedInitial)
    SpecializationUtil.registerFunction(vehicleType, "allowLoadMovingToolStates", Cylindered.allowLoadMovingToolStates)
    SpecializationUtil.registerFunction(vehicleType, "getMovingToolByNode", Cylindered.getMovingToolByNode)
    SpecializationUtil.registerFunction(vehicleType, "getMovingPartByNode", Cylindered.getMovingPartByNode)
    SpecializationUtil.registerFunction(vehicleType, "getTranslatingPartByNode", Cylindered.getTranslatingPartByNode)
    SpecializationUtil.registerFunction(vehicleType, "getIsMovingToolActive", Cylindered.getIsMovingToolActive)
    SpecializationUtil.registerFunction(vehicleType, "getIsMovingPartActive", Cylindered.getIsMovingPartActive)
    SpecializationUtil.registerFunction(vehicleType, "getMovingToolMoveValue", Cylindered.getMovingToolMoveValue)
    SpecializationUtil.registerFunction(vehicleType, "setDelayedData", Cylindered.setDelayedData)
    SpecializationUtil.registerFunction(vehicleType, "updateDelayedTool", Cylindered.updateDelayedTool)
    SpecializationUtil.registerFunction(vehicleType, "updateEasyControl", Cylindered.updateEasyControl)
    SpecializationUtil.registerFunction(vehicleType, "setIsEasyControlActive", Cylindered.setIsEasyControlActive)
    SpecializationUtil.registerFunction(vehicleType, "setEasyControlForcedTransMove", Cylindered.setEasyControlForcedTransMove)
    SpecializationUtil.registerFunction(vehicleType, "updateExtraDependentParts", Cylindered.updateExtraDependentParts)
    SpecializationUtil.registerFunction(vehicleType, "updateDependentAnimations", Cylindered.updateDependentAnimations)
    SpecializationUtil.registerFunction(vehicleType, "updateDependentToolLimits", Cylindered.updateDependentToolLimits)
    SpecializationUtil.registerFunction(vehicleType, "onMovingPartSoundEvent", Cylindered.onMovingPartSoundEvent)
    SpecializationUtil.registerFunction(vehicleType, "updateMovingToolSoundEvents", Cylindered.updateMovingToolSoundEvents)
    SpecializationUtil.registerFunction(vehicleType, "updateControlGroups", Cylindered.updateControlGroups)
end
function Cylindered.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", Cylindered.isDetachAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadObjectChangeValuesFromXML", Cylindered.loadObjectChangeValuesFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setObjectChangeValues", Cylindered.setObjectChangeValues)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDischargeNode", Cylindered.loadDischargeNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeNodeEmptyFactor", Cylindered.getDischargeNodeEmptyFactor)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadShovelNode", Cylindered.loadShovelNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShovelNodeIsActive", Cylindered.getShovelNodeIsActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDynamicMountGrabFromXML", Cylindered.loadDynamicMountGrabFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDynamicMountGrabOpened", Cylindered.getIsDynamicMountGrabOpened)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setComponentJointFrame", Cylindered.setComponentJointFrame)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAdditionalSchemaText", Cylindered.getAdditionalSchemaText)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Cylindered.getWearMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", Cylindered.getDoConsumePtoPower)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", Cylindered.getConsumingLoad)
end
function Cylindered.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onPostUpdateTick", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onSelect", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onUnselect", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onAnimationPartChanged", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStart", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onVehicleSettingChanged", Cylindered)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterAnimationValueTypes", Cylindered)
end
function Cylindered:onLoad(_)
    local spec = self.spec_cylindered
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.movingParts", "vehicle.cylindered.movingParts")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.movingTools", "vehicle.cylindered.movingTools")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cylinderedHydraulicSound", "vehicle.cylindered.sounds.hydraulic")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cylindered.movingParts#isActiveDirtyTimeOffset")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cylindered.movingParts.sounds", "vehicle.cylindered.sounds")
    local configKey = string.format("vehicle.cylindered.cylinderedConfigurations.cylinderedConfiguration(%d)", (self.configurations.cylindered or 1) - 1)
    spec.activeDirtyMovingParts = {}
    spec.referenceNodes = {}
    spec.nodesToMovingParts = {}
    spec.movingParts = {}
    self.anyMovingPartsDirty = false
    spec.detachLockNodes = nil
    self:loadMovingPartsFromXML(self.xmlFile, "vehicle.cylindered.movingParts.movingPart")
    self:loadMovingPartsFromXML(self.xmlFile, configKey .. ".movingParts.movingPart")
    if Cylindered.DIRTY_COLLISION_UPDATE_CHECK then
        local function collectDependentParts(part, target)
            -- upvalues: (copy) spec, (copy) collectDependentParts
            table.insert(target, part)
            if part.dependentPartNodes ~= nil then
                local l = 1
                for l = l, #part.dependentPartNodes do
                    local dependentMovingPart = spec.nodesToMovingParts[part.dependentPartNodes[l]]
                    if dependentMovingPart ~= nil then
                        table.insert(target, dependentMovingPart)
                        collectDependentParts(dependentMovingPart, target)
                    end
                end
            end
        end
        spec.realActiveDirtyParts = {}
        local j = 1
        for j = j, #spec.movingParts do
            local movingPart = spec.movingParts[j]
            if movingPart.isActiveDirty and movingPart.directionThreshold == 0.0001 then
                collectDependentParts(movingPart, spec.realActiveDirtyParts)
            end
        end
        local j = 1
        for j = j, #spec.realActiveDirtyParts do
            local movingPart = spec.realActiveDirtyParts[j]
            I3DUtil.checkForChildCollisions(movingPart.node, function(collisionNode, xmlFile, key)
                if getHasClassId(collisionNode, ClassIds.SHAPE) then
                    Logging.xmlError(xmlFile, "Found collision \'%s\' as child of isActiveDirty movingPart \'%s\'. This can cause the vehicle to never sleep!", getName(collisionNode), key)
                end
            end, self.xmlFile, getName(movingPart.node))
        end
    end
    spec.powerConsumingActiveTimeOffset = self.xmlFile:getValue("vehicle.cylindered.movingTools#powerConsumingActiveTimeOffset", 5)
    spec.powerConsumingTimer = -1
    for _, j in pairs(spec.movingParts) do
        self:resolveDependentPartData(j.dependentPartData, spec.referenceNodes)
    end
    local function collectDependentParts(part, newTable, allowDependentParts)
        -- upvalues: (copy) collectDependentParts
        for _, addedPart in ipairs(newTable) do
            if addedPart == part then
                return
            end
        end
        if part.isDependentPart ~= true or allowDependentParts == true then
            table.insert(newTable, part)
            for _, addedPart in pairs(part.dependentPartData) do
                collectDependentParts(addedPart.part, newTable, true)
            end
        end
    end
    local subCollisionErrorFunction = {}
    for movingPart, part in ipairs(spec.movingParts) do
        collectDependentParts(part, subCollisionErrorFunction)
    end
    spec.movingParts = subCollisionErrorFunction
    spec.controlGroups = {}
    spec.controlGroupMapping = {}
    spec.currentControlGroupIndex = 1
    spec.controlGroupNames = {}
    for movingPart, part in ipairs(Cylindered.MOVING_TOOLS_XML_KEYS) do
        for _, groupKey in self.xmlFile:iterator(part .. ".controlGroups.controlGroup") do
            local name = self.xmlFile:getValue(groupKey .. "#name", "", self.customEnvironment, false)
            if name ~= nil then
                table.insert(spec.controlGroupNames, name)
            end
        end
    end
    spec.nodesToMovingTools = {}
    spec.movingTools = {}
    self:loadMovingToolsFromXML(self.xmlFile, "vehicle.cylindered.movingTools.movingTool")
    self:loadMovingToolsFromXML(self.xmlFile, configKey .. ".movingTools.movingTool")
    table.sort(spec.controlGroups, function(a, b)
        return a < b
    end)
    for part, groupIndex in ipairs(spec.controlGroups) do
        local subSelectionIndex = self:addSubselection(groupIndex)
        spec.controlGroupMapping[subSelectionIndex] = groupIndex
    end
    for part, groupIndex in pairs(spec.movingTools) do
        self:resolveDependentPartData(groupIndex.dependentPartData, spec.referenceNodes)
        for _ = #groupIndex.dependentMovingTools, 1, -1 do
            local groupKey = groupIndex.dependentMovingTools[_]
            local name = spec.nodesToMovingTools[groupKey.node]
            if name == nil then
                Logging.xmlWarning(self.xmlFile, "Dependent moving tool \'%s\' not defined. Ignoring it!", getName(groupKey.node))
                table.remove(groupIndex.dependentMovingTools, _)
            else
                groupKey.movingTool = name
            end
        end
    end
    for part, groupIndex in pairs(spec.movingParts) do
        for _ = #groupIndex.dependentMovingTools, 1, -1 do
            local groupKey = groupIndex.dependentMovingTools[_]
            local name = spec.nodesToMovingTools[groupKey.node]
            if name == nil then
                Logging.xmlWarning(self.xmlFile, "Dependent moving tool \'%s\' not defined. Ignoring it!", getName(groupKey.node))
                table.remove(groupIndex.dependentMovingTools, _)
            else
                groupKey.movingTool = name
            end
        end
    end
    spec.referenceNodes = nil
    local _ = configKey .. ".movingTools.easyArmControl"
    local _ = not self.xmlFile:hasProperty(_) and "vehicle.cylindered.movingTools.easyArmControl" or _
    if self.xmlFile:hasProperty(_) then
        local j = {}
        if self:loadEasyArmControlFromXML(self.xmlFile, _, j) then
            spec.easyArmControl = j
        end
    end
    if self.xmlFile:hasProperty(configKey) then
        local j = DashboardValueType.new("cylindered", "movingTool")
        j:setXMLKey(configKey .. ".dashboards")
        j:setValue(self, Cylindered.getMovingToolDashboardState)
        j:setRange(0, 1)
        j:setAdditionalFunctions(Cylindered.movingToolDashboardAttributes, nil)
        j:setIdleValue(0.5)
        self:registerDashboardValueType(j)
    end
    spec.samples = {}
    spec.actionSamples = {}
    if self.isClient then
        spec.samples.hydraulic = g_soundManager:loadSampleFromXML(self.xmlFile, configKey .. ".sounds", "hydraulic", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        if spec.samples.hydraulic == nil then
            spec.samples.hydraulic = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.cylindered.sounds", "hydraulic", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        end
        spec.isHydraulicSamplePlaying = false
        spec.nodesToSamples = {}
        spec.activeSamples = {}
        spec.endingSamples = {}
        spec.endingSamplesBySample = {}
        spec.startingSamples = {}
        spec.startingSamplesBySample = {}
        self:loadActionSoundsFromXML(self.xmlFile, "vehicle.cylindered.sounds")
        self:loadActionSoundsFromXML(self.xmlFile, configKey .. ".sounds")
    end
    spec.cylinderedDirtyFlag = self:getNextDirtyFlag()
    spec.cylinderedInputDirtyFlag = self:getNextDirtyFlag()
    self:registerVehicleSetting(GameSettings.SETTING.EASY_ARM_CONTROL, true)
    spec.isLoading = true
end
function Cylindered:onPostLoad(savegame)
    local spec = self.spec_cylindered
    for _, tool in pairs(spec.movingTools) do
        if self:getIsMovingToolActive(tool) then
            if tool.startRot ~= nil then
                tool.curRot[tool.rotationAxis] = tool.startRot
                tool(setRotation.node, unpack(tool.curRot))
                SpecializationUtil.raiseEvent(self, "onMovingToolChanged", tool, 0, 0)
            end
            if tool.startTrans ~= nil then
                tool.curTrans[tool.translationAxis] = tool.startTrans
                tool(setTranslation.node, unpack(tool.curTrans))
                SpecializationUtil.raiseEvent(self, "onMovingToolChanged", tool, 0, 0)
            end
            if tool.animStartTime ~= nil then
                self:setAnimationTime(tool.animName, tool.animStartTime, nil, false)
                SpecializationUtil.raiseEvent(self, "onMovingToolChanged", tool, 0, 0)
            end
            if tool.delayedNode ~= nil then
                self:setDelayedData(tool, true)
            end
            if tool.isIntitialDirty then
                Cylindered.setDirty(self, tool)
            end
        end
    end
    for _, tool in pairs(spec.movingParts) do
        self:loadDependentAttacherJoints(self.xmlFile, tool.key, tool)
        self:loadDependentWheels(self.xmlFile, tool.key, tool)
    end
    for _, tool in pairs(spec.movingTools) do
        self:loadDependentAttacherJoints(self.xmlFile, tool.key, tool)
        self:loadDependentWheels(self.xmlFile, tool.key, tool)
    end
    if self:allowLoadMovingToolStates() and (savegame ~= nil and not savegame.resetVehicles) then
        local i = 0
        for tool, tool in ipairs(spec.movingTools) do
            if tool.saving then
                if self:getIsMovingToolActive(tool) then
                    local toolKey = string.format("%s.cylindered.movingTool(%d)", savegame.key, i)
                    local changed = false
                    if tool.transSpeed ~= nil then
                        local newTrans = savegame.xmlFile:getValue(toolKey .. "#translation")
                        if newTrans ~= nil then
                            if tool.transMax ~= nil then
                                newTrans = math.min(newTrans, tool.transMax)
                            end
                            if tool.transMin ~= nil then
                                newTrans = math.max(newTrans, tool.transMin)
                            end
                        end
                        if newTrans ~= nil then
                            local dependentTool = newTrans - tool.curTrans[tool.translationAxis]
                            if math.abs(dependentTool) > 0.0001 then
                                tool.curTrans = { getTranslation(tool.node) }
                                tool.curTrans[tool.translationAxis] = newTrans
                                setTranslation(tool.node, unpack(tool.curTrans))
                                changed = true
                            end
                        end
                    end
                    if tool.rotSpeed ~= nil then
                        local newTrans = savegame.xmlFile:getValue(toolKey .. "#rotation")
                        if newTrans ~= nil then
                            if tool.rotMax ~= nil then
                                newTrans = math.min(newTrans, tool.rotMax)
                            end
                            if tool.rotMin ~= nil then
                                newTrans = math.max(newTrans, tool.rotMin)
                            end
                        end
                        if newTrans ~= nil then
                            local dependentTool = newTrans - tool.curRot[tool.rotationAxis]
                            if math.abs(dependentTool) > 0.0001 then
                                tool.curRot = { getRotation(tool.node) }
                                tool.curRot[tool.rotationAxis] = newTrans
                                setRotation(tool.node, unpack(tool.curRot))
                                changed = true
                            end
                        end
                    end
                    if tool.animSpeed ~= nil then
                        local newTrans = savegame.xmlFile:getValue(toolKey .. "#animationTime")
                        if newTrans ~= nil then
                            if tool.animMinTime ~= nil then
                                newTrans = math.max(newTrans, tool.animMinTime)
                            end
                            if tool.animMaxTime ~= nil then
                                newTrans = math.min(newTrans, tool.animMaxTime)
                            end
                            tool.curAnimTime = newTrans
                            self:setAnimationTime(tool.animName, newTrans, true, false)
                        end
                    end
                    if changed then
                        Cylindered.setDirty(self, tool)
                        SpecializationUtil.raiseEvent(self, "onMovingToolChanged", tool, 0, 0)
                    end
                    if tool.delayedNode ~= nil then
                        self:setDelayedData(tool, true)
                    end
                end
                i = i + 1
            end
            for _, dependentTool in pairs(tool.dependentMovingTools) do
                Cylindered.updateRotationBasedLimits(self, tool, dependentTool)
            end
        end
    end
    self:updateEasyControl(9999, true)
    self:updateCylinderedInitial(false)
    local i = #spec.movingTools > 0
    local hasParts = #spec.movingParts > 0
    if not i then
        SpecializationUtil.removeEventListener(self, "onReadStream", Cylindered)
        SpecializationUtil.removeEventListener(self, "onWriteStream", Cylindered)
        SpecializationUtil.removeEventListener(self, "onReadUpdateStream", Cylindered)
        SpecializationUtil.removeEventListener(self, "onWriteUpdateStream", Cylindered)
        SpecializationUtil.removeEventListener(self, "onUpdate", Cylindered)
        if not hasParts then
            SpecializationUtil.removeEventListener(self, "onUpdateTick", Cylindered)
            SpecializationUtil.removeEventListener(self, "onPostUpdate", Cylindered)
            SpecializationUtil.removeEventListener(self, "onPostUpdateTick", Cylindered)
        end
    end
    if not (self.isClient and i) then
        SpecializationUtil.removeEventListener(self, "onDraw", Cylindered)
        SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", Cylindered)
    end
    if g_isDevelopmentVersion then
        local function checkPart(part)
            -- upvalues: (copy) self, (copy) checkPart
            I3DUtil.iterateRecursively(part.node, function(child, _)
                -- upvalues: (ref) self, (copy) part
                self:checkMovingPartDirtyUpdateNode(child, part)
            end)
            if part.dependentPartData ~= nil then
                for _, data in pairs(part.dependentPartData) do
                    if data.part ~= nil then
                        checkPart(data.part)
                    end
                end
            end
        end
        local tool = 1
        local tool = 1
        for tool = tool, #spec.movingParts, tool do
            local toolKey = spec.movingParts[tool]
            if toolKey.isActiveDirty and toolKey.maxUpdateDistance ~= math.huge then
                checkPart(toolKey)
            end
        end
    end
end
function Cylindered:onLoadFinished(_)
    local spec = self.spec_cylindered
    spec.isLoading = false
    local i = 1
    for i = i, #spec.movingTools do
        local tool = spec.movingTools[i]
        if tool.delayedHistoryIndex ~= nil and tool.delayedHistoryIndex > 0 then
            self:updateDelayedTool(tool, true)
        end
    end
end
function Cylindered:onRegisterDashboardValueTypes()
    local movingTool = DashboardValueType.new("cylindered", "movingTool")
    movingTool:setValue(self, Cylindered.getMovingToolDashboardState)
    movingTool:setRange(0, 1)
    movingTool:setAdditionalFunctions(Cylindered.movingToolDashboardAttributes, nil)
    movingTool:setIdleValue(0.5)
    self:registerDashboardValueType(movingTool)
end
function Cylindered:onDelete()
    local spec = self.spec_cylindered
    g_soundManager:deleteSamples(spec.samples)
    g_soundManager:deleteSamples(spec.actionSamples)
    if spec.movingTools ~= nil then
        for _, movingTool in pairs(spec.movingTools) do
            if movingTool.icon ~= nil then
                movingTool.icon:delete()
                movingTool.icon = nil
            end
        end
    end
end
function Cylindered:saveToXMLFile(xmlFile, key, _)
    local index = 0
    for _, tool in ipairs(self.spec_cylindered.movingTools) do
        if tool.saving then
            local toolKey = string.format("%s.movingTool(%d)", key, index)
            if tool.transSpeed ~= nil then
                xmlFile:setValue(toolKey .. "#translation", tool.curTrans[tool.translationAxis])
            end
            if tool.rotSpeed ~= nil then
                xmlFile:setValue(toolKey .. "#rotation", tool.curRot[tool.rotationAxis])
            end
            if tool.animSpeed ~= nil then
                xmlFile:setValue(toolKey .. "#animationTime", tool.curAnimTime)
            end
            index = index + 1
        end
    end
end
function Cylindered:onReadStream(streamId, connection)
    if connection:getIsServer() and streamReadBool(streamId) then
        local i = 1
        for i = i, #self.spec_cylindered.movingTools do
            local tool = spec.movingTools[i]
            if tool.dirtyFlag ~= nil then
                tool.networkTimeInterpolator:reset()
                if tool.transSpeed ~= nil then
                    local newTrans = streamReadFloat32(streamId)
                    tool.curTrans[tool.translationAxis] = newTrans
                    setTranslation(tool.node, unpack(tool.curTrans))
                    tool.networkInterpolators.translation:setValue(tool.curTrans[tool.translationAxis])
                end
                if tool.rotSpeed ~= nil then
                    local newTrans = streamReadFloat32(streamId)
                    tool.curRot[tool.rotationAxis] = newTrans
                    setRotation(tool.node, unpack(tool.curRot))
                    tool.networkInterpolators.rotation:setAngle(newTrans)
                end
                if tool.animSpeed ~= nil then
                    local newTrans = streamReadFloat32(streamId)
                    tool.curAnimTime = newTrans
                    self:setAnimationTime(tool.animName, tool.curAnimTime, nil, false)
                    tool.networkInterpolators.animation:setValue(newTrans)
                end
                if tool.delayedNode ~= nil then
                    self:setDelayedData(tool, true)
                end
                Cylindered.setDirty(self, tool)
                SpecializationUtil.raiseEvent(self, "onMovingToolChanged", tool, 0, 0)
            end
        end
    end
end
function Cylindered:onWriteStream(streamId, connection)
    if not connection:getIsServer() and streamWriteBool(streamId, self:allowLoadMovingToolStates()) then
        local i = 1
        for i = i, #self.spec_cylindered.movingTools do
            local tool = spec.movingTools[i]
            if tool.dirtyFlag ~= nil then
                if tool.transSpeed ~= nil then
                    streamWriteFloat32(streamId, tool.curTrans[tool.translationAxis])
                end
                if tool.rotSpeed ~= nil then
                    streamWriteFloat32(streamId, tool.curRot[tool.rotationAxis])
                end
                if tool.animSpeed ~= nil then
                    tool.curAnimTime = self:getAnimationTime(tool.animName)
                    streamWriteFloat32(streamId, tool.curAnimTime)
                end
            end
        end
    end
end
function Cylindered:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            for _, tool in ipairs(self.spec_cylindered.movingTools) do
                if tool.dirtyFlag ~= nil and streamReadBool(streamId) then
                    tool.networkTimeInterpolator:startNewPhaseNetwork()
                    if tool.transSpeed ~= nil then
                        local newTrans = streamReadFloat32(streamId)
                        if math.abs(newTrans - tool.curTrans[tool.translationAxis]) > 0.0001 then
                            tool.networkInterpolators.translation:setTargetValue(newTrans)
                        end
                    end
                    if tool.rotSpeed ~= nil then
                        local newAnimTime
                        if tool.rotMin == nil or tool.rotMax == nil then
                            newAnimTime = NetworkUtil.readCompressedAngle(streamId)
                        else
                            if tool.syncMinRotLimits then
                                tool.rotMin = streamReadFloat32(streamId)
                            end
                            if tool.syncMaxRotLimits then
                                tool.rotMax = streamReadFloat32(streamId)
                            end
                            tool.networkInterpolators.rotation:setMinMax(tool.rotMin, tool.rotMax)
                            newAnimTime = NetworkUtil.readCompressedRange(streamId, tool.rotMin, tool.rotMax, tool.rotSendNumBits)
                        end
                        if math.abs(newAnimTime - tool.curRot[tool.rotationAxis]) > 0.0001 then
                            tool.networkInterpolators.rotation:setTargetAngle(newAnimTime)
                        end
                    end
                    if tool.animSpeed ~= nil then
                        local newTrans = streamReadBool(streamId)
                        local newAnimTime = NetworkUtil.readCompressedRange(streamId, tool.animMinTime, tool.animMaxTime, tool.animSendNumBits)
                        if math.abs(newAnimTime - tool.curAnimTime) > 0.0001 then
                            tool.networkInterpolators.animation:setTargetValue(newAnimTime)
                            if newTrans then
                                tool.networkInterpolators.animation:setValue(newAnimTime)
                            end
                        end
                    end
                end
            end
        end
    elseif streamReadBool(streamId) then
        for _, tool in ipairs(spec.movingTools) do
            if tool.axisActionIndex ~= nil then
                tool.move = (streamReadUIntN(streamId, 12) / 4095 * 2 - 1) * 5
                if math.abs(tool.move) < 0.01 then
                    tool.move = 0
                end
            end
        end
        return
    end
end
function Cylindered:onWriteUpdateStream(streamId, connection, dirtyMask)
    if connection:getIsServer() then
        local value = self.spec_cylindered.cylinderedInputDirtyFlag
        if streamWriteBool(streamId, bit32.band(dirtyMask, value) ~= 0) then
            for _, tool in ipairs(spec.movingTools) do
                if tool.axisActionIndex ~= nil then
                    local value = (math.clamp(tool.moveToSend / 5, -1, 1) + 1) / 2 * 4095
                    streamWriteUIntN(streamId, value, 12)
                end
            end
            return
        end
    else
        local value = spec.cylinderedDirtyFlag
        if streamWriteBool(streamId, bit32.band(dirtyMask, value) ~= 0) then
            for _, tool in ipairs(spec.movingTools) do
                if tool.dirtyFlag ~= nil then
                    local value = streamWriteBool
                    if value(streamId, bit32.band(dirtyMask, tool.dirtyFlag) ~= 0 and self:getIsMovingToolActive(tool)) then
                        if tool.transSpeed ~= nil then
                            streamWriteFloat32(streamId, tool.curTrans[tool.translationAxis])
                        end
                        if tool.rotSpeed ~= nil then
                            if tool.rotMin == nil or tool.rotMax == nil then
                                NetworkUtil.writeCompressedAngle(streamId, tool.curRot[tool.rotationAxis])
                            else
                                if tool.syncMinRotLimits then
                                    streamWriteFloat32(streamId, tool.rotMin)
                                end
                                if tool.syncMaxRotLimits then
                                    streamWriteFloat32(streamId, tool.rotMax)
                                end
                                NetworkUtil.writeCompressedRange(streamId, value, tool.rotMin, tool.rotMax, tool.rotSendNumBits)
                            end
                        end
                        if tool.animSpeed ~= nil then
                            local value = self:getAnimationTime(tool.animName)
                            local hasChanged = math.abs(value - tool.curAnimTime) > 0.001
                            streamWriteBool(streamId, hasChanged or tool.networkInterpolators.resetAnimInterpolation)
                            tool.networkInterpolators.resetAnimInterpolation = false
                            tool.curAnimTime = value
                            NetworkUtil.writeCompressedRange(streamId, tool.curAnimTime, tool.animMinTime, tool.animMaxTime, tool.animSendNumBits)
                        end
                    end
                end
            end
        end
    end
end
function Cylindered:onUpdate(dt, _, _, _)
    local spec = self.spec_cylindered
    spec.movingToolNeedsSound = false
    spec.movingPartNeedsSound = false
    self:updateEasyControl(dt)
    if self.isServer then
        local i = 1
        for i = i, #spec.movingTools do
            local tool = spec.movingTools[i]
            local rotSpeed = 0
            local transSpeed = 0
            local animSpeed = 0
            local move = self:getMovingToolMoveValue(tool)
            tool.externalMove = 0
            if tool.curTargetPosition ~= nil then
                if math.abs(Cylindered.getMovingToolState(self, tool) - tool.curTargetPosition) < 0.001 then
                    tool.curTargetPosition = nil
                    tool.curTargetDirection = nil
                else
                    move = tool.curTargetDirection
                end
            end
            if math.abs(move) > 0 then
                if tool.rotSpeed ~= nil then
                    rotSpeed = move * tool.rotSpeed
                    if tool.rotAcceleration ~= nil then
                        if math.abs(rotSpeed - tool.lastRotSpeed) >= tool.rotAcceleration * dt then
                            if tool.lastRotSpeed < rotSpeed then
                                rotSpeed = tool.lastRotSpeed + tool.rotAcceleration * dt
                            else
                                rotSpeed = tool.lastRotSpeed - tool.rotAcceleration * dt
                            end
                        end
                    end
                end
                if tool.transSpeed ~= nil then
                    transSpeed = move * tool.transSpeed
                    if tool.transAcceleration ~= nil then
                        if math.abs(transSpeed - tool.lastTransSpeed) >= tool.transAcceleration * dt then
                            if tool.lastTransSpeed < transSpeed then
                                transSpeed = tool.lastTransSpeed + tool.transAcceleration * dt
                            else
                                transSpeed = tool.lastTransSpeed - tool.transAcceleration * dt
                            end
                        end
                    end
                end
                if tool.animSpeed ~= nil then
                    animSpeed = move * tool.animSpeed
                    if tool.animAcceleration ~= nil then
                        if math.abs(animSpeed - tool.lastAnimSpeed) >= tool.animAcceleration * dt then
                            if tool.lastAnimSpeed < animSpeed then
                                animSpeed = tool.lastAnimSpeed + tool.animAcceleration * dt
                            else
                                animSpeed = tool.lastAnimSpeed - tool.animAcceleration * dt
                            end
                        end
                    end
                end
            else
                if tool.rotAcceleration ~= nil then
                    if tool.lastRotSpeed < 0 then
                        rotSpeed = math.min(tool.lastRotSpeed + tool.rotAcceleration * dt, 0)
                    else
                        rotSpeed = math.max(tool.lastRotSpeed - tool.rotAcceleration * dt, 0)
                    end
                end
                if tool.transAcceleration ~= nil then
                    if tool.lastTransSpeed < 0 then
                        transSpeed = math.min(tool.lastTransSpeed + tool.transAcceleration * dt, 0)
                    else
                        transSpeed = math.max(tool.lastTransSpeed - tool.transAcceleration * dt, 0)
                    end
                end
                if tool.animAcceleration ~= nil then
                    if tool.lastAnimSpeed < 0 then
                        animSpeed = math.min(tool.lastAnimSpeed + tool.animAcceleration * dt, 0)
                    else
                        animSpeed = math.max(tool.lastAnimSpeed - tool.animAcceleration * dt, 0)
                    end
                end
            end
            local delta = false
            if rotSpeed == nil or rotSpeed == 0 then
                tool.lastRotSpeed = 0
            else
                delta = delta or Cylindered.setToolRotation(self, tool, rotSpeed, dt)
            end
            if transSpeed == nil or transSpeed == 0 then
                tool.lastTransSpeed = 0
            else
                delta = delta or Cylindered.setToolTranslation(self, tool, transSpeed, dt)
            end
            if animSpeed == nil or animSpeed == 0 then
                tool.lastAnimSpeed = 0
            else
                delta = delta or Cylindered.setToolAnimation(self, tool, animSpeed, dt)
            end
            for _, dependentTool in pairs(tool.dependentMovingTools) do
                if dependentTool.speedScale ~= nil then
                    local isAllowed = true
                    if dependentTool.requiresMovement and not delta then
                        isAllowed = false
                    end
                    if isAllowed then
                        dependentTool.movingTool.externalMove = dependentTool.movingTool.externalMove + dependentTool.speedScale * tool.move
                    end
                end
                Cylindered.updateRotationBasedLimits(self, tool, dependentTool)
                self:updateDependentToolLimits(tool, dependentTool)
            end
            if delta then
                if tool.playSound then
                    spec.movingToolNeedsSound = true
                end
                Cylindered.setDirty(self, tool)
                tool.networkPositionIsDirty = true
                self:raiseDirtyFlags(tool.dirtyFlag)
                self:raiseDirtyFlags(spec.cylinderedDirtyFlag)
                tool.networkDirtyNextFrame = true
                if tool.isConsumingPower then
                    spec.powerConsumingTimer = spec.powerConsumingActiveTimeOffset
                end
            elseif tool.networkDirtyNextFrame then
                self:raiseDirtyFlags(tool.dirtyFlag)
                self:raiseDirtyFlags(spec.cylinderedDirtyFlag)
                tool.networkDirtyNextFrame = nil
            end
        end
    else
        local i = 1
        for i = i, #spec.movingTools do
            local tool = spec.movingTools[i]
            tool.networkTimeInterpolator:update(dt)
            local rotSpeed = tool.networkTimeInterpolator:getAlpha()
            local transSpeed = false
            if self:getIsMovingToolActive(tool) then
                if tool.rotSpeed ~= nil then
                    local animSpeed = tool.networkInterpolators.rotation:getInterpolatedValue(rotSpeed)
                    if math.abs(animSpeed - tool.curRot[tool.rotationAxis]) > 0.0001 then
                        transSpeed = true
                        tool.curRot[tool.rotationAxis] = animSpeed
                        setRotation(tool.node, tool.curRot[1], tool.curRot[2], tool.curRot[3])
                    end
                end
                if tool.transSpeed ~= nil then
                    local animSpeed = tool.networkInterpolators.translation:getInterpolatedValue(rotSpeed)
                    if math.abs(animSpeed - tool.curTrans[tool.translationAxis]) > 0.0001 then
                        transSpeed = true
                        tool.curTrans[tool.translationAxis] = animSpeed
                        setTranslation(tool.node, tool.curTrans[1], tool.curTrans[2], tool.curTrans[3])
                    end
                end
                if tool.animSpeed ~= nil then
                    local animSpeed = tool.networkInterpolators.animation:getInterpolatedValue(rotSpeed)
                    if math.abs(animSpeed - tool.curAnimTime) > 0.0001 then
                        transSpeed = true
                        tool.curAnimTime = animSpeed
                        self:setAnimationTime(tool.animName, animSpeed, nil, true)
                    end
                end
                if transSpeed then
                    Cylindered.setDirty(self, tool)
                    SpecializationUtil.raiseEvent(self, "onMovingToolChanged", tool, 0, dt)
                end
            end
            for _, dependentTool in pairs(tool.dependentMovingTools) do
                if not (dependentTool.movingTool.syncMinRotLimits and dependentTool.movingTool.syncMaxRotLimits) then
                    Cylindered.updateRotationBasedLimits(self, tool, dependentTool)
                    self:updateDependentToolLimits(tool, dependentTool)
                end
            end
            if tool.networkTimeInterpolator:isInterpolating() then
                self:raiseActive()
            end
        end
    end
    local i = 1
    for i = i, #spec.movingTools do
        local tool = spec.movingTools[i]
        if tool.delayedHistoryIndex ~= nil and tool.delayedHistoryIndex > 0 then
            self:updateDelayedTool(tool)
        end
        if tool.smoothedMove ~= 0 and tool.lastInputTime + 50 < g_time then
            tool.smoothedMove = 0
        end
    end
    if spec.powerConsumingTimer > 0 then
        spec.powerConsumingTimer = spec.powerConsumingTimer - dt
    end
    if next(spec.activeSamples) ~= nil then
        self:raiseActive()
    end
end
function Cylindered.setDelayedData(_, tool, immediate)
    local x, y, z = getTranslation(tool.node)
    local rx, ry, rz = getRotation(tool.node)
    tool.delayedHistroyData[tool.delayedFrames] = {
        ["rot"] = { rx, ry, rz },
        ["trans"] = { x, y, z }
    }
    if immediate then
        local i = 1
        for i = i, tool.delayedFrames - 1 do
            tool.delayedHistroyData[i] = tool.delayedHistroyData[tool.delayedFrames]
        end
    end
    tool.delayedHistoryIndex = tool.delayedFrames
end
function Cylindered:updateDelayedTool(tool, forceLastPosition)
    local spec = self.spec_cylindered
    if forceLastPosition ~= nil and forceLastPosition then
        local i = 1
        for i = i, tool.delayedFrames - 1 do
            tool.delayedHistroyData[i] = tool.delayedHistroyData[tool.delayedFrames]
        end
    end
    local currentData = tool.delayedHistroyData[1]
    local i = 1
    local movingPart = tool.delayedFrames - 1
    local i = 1
    for i = i, movingPart, i do
        tool.delayedHistroyData[i] = tool.delayedHistroyData[i + 1]
    end
    local movingPart = setRotation
    local i = tool.delayedNode
    movingPart(i, unpack(currentData.rot))
    local movingPart = setTranslation
    local i = tool.delayedNode
    movingPart(i, unpack(currentData.trans))
    tool.delayedHistoryIndex = tool.delayedHistoryIndex - 1
    local movingPart = spec.nodesToMovingParts[tool.delayedNode]
    local i = spec.nodesToMovingTools[tool.delayedNode]
    if movingPart ~= nil then
        Cylindered.setDirty(self, movingPart)
    end
    if spec.nodesToMovingTools[tool.delayedNode] ~= nil then
        Cylindered.setDirty(self, i)
    end
end
function Cylindered:loadEasyArmControlFromXML(xmlFile, key, easyArmControl)
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".xRotationNodes#maxDistance")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".xRotationNodes#transRotRatio")
    easyArmControl.rootNode = xmlFile:getValue(key .. "#rootNode", nil, self.components, self.i3dMappings)
    easyArmControl.targetNodeY = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
    easyArmControl.targetNodeZ = xmlFile:getValue(key .. "#targetNodeZ", easyArmControl.targetNodeY, self.components, self.i3dMappings)
    easyArmControl.state = false
    if easyArmControl.targetNodeZ == nil or easyArmControl.targetNodeY == nil then
        Logging.xmlError(xmlFile, "Missing easy control targets!")
        return false
    end
    local targetYTool = self:getMovingToolByNode(easyArmControl.targetNodeY)
    local targetZTool = self:getMovingToolByNode(easyArmControl.targetNodeZ)
    if targetYTool == nil or targetZTool == nil then
        Logging.xmlError(xmlFile, "Missing moving tools for easy control targets!")
        return false
    end
    easyArmControl.targetNode = easyArmControl.targetNodeZ
    if getParent(easyArmControl.targetNodeY) == easyArmControl.targetNodeZ then
        easyArmControl.targetNode = easyArmControl.targetNodeY
    end
    easyArmControl.targetRefNode = xmlFile:getValue(key .. "#refNode", nil, self.components, self.i3dMappings)
    easyArmControl.lastValidPositionY = { getTranslation(easyArmControl.targetNodeY) }
    easyArmControl.lastValidPositionZ = { getTranslation(easyArmControl.targetNodeZ) }
    easyArmControl.moveSpeed = xmlFile:getValue(key .. ".targetMovement#speed", 1) / 1000
    easyArmControl.moveAcceleration = xmlFile:getValue(key .. ".targetMovement#acceleration", 50) / 1000000
    easyArmControl.lastSpeedY = 0
    easyArmControl.lastSpeedZ = 0
    easyArmControl.minTransMoveRatio = xmlFile:getValue(key .. ".zTranslationNodes#minMoveRatio", 0.2)
    easyArmControl.maxTransMoveRatio = xmlFile:getValue(key .. ".zTranslationNodes#maxMoveRatio", 0.8)
    easyArmControl.transMoveRatioMinDir = xmlFile:getValue(key .. ".zTranslationNodes#moveRatioMinDir", 0)
    easyArmControl.transMoveRatioMaxDir = xmlFile:getValue(key .. ".zTranslationNodes#moveRatioMaxDir", 1)
    easyArmControl.allowNegativeTrans = xmlFile:getValue(key .. ".zTranslationNodes#allowNegativeTrans", false)
    easyArmControl.minNegativeTrans = xmlFile:getValue(key .. ".zTranslationNodes#minNegativeTrans", 0)
    easyArmControl.forcedTransMove = nil
    easyArmControl.zTranslationNodes = {}
    local maxTrans = 0
    xmlFile:iterate(key .. ".zTranslationNodes.zTranslationNode", function(_, transKey)
        -- upvalues: (copy) xmlFile, (copy) self, (ref) maxTrans, (copy) easyArmControl
        local node = xmlFile:getValue(transKey .. "#node", nil, self.components, self.i3dMappings)
        if node ~= nil then
            local movingTool = self:getMovingToolByNode(node)
            if movingTool ~= nil then
                local maxDistance = math.abs(movingTool.transMin - movingTool.transMax)
                movingTool.easyArmControlActive = false
                table.insert(easyArmControl.zTranslationNodes, {
                    ["node"] = node,
                    ["movingTool"] = movingTool,
                    ["maxDistance"] = maxDistance,
                    ["transFactor"] = 0,
                    ["startTranslation"] = { getTranslation(node) }
                })
            end
        end
    end)
    for _, translationNode in ipairs(easyArmControl.zTranslationNodes) do
        translationNode.transFactor = translationNode.maxDistance / maxTrans
    end
    easyArmControl.xRotationNodes = {}
    local i = 1
    local xOffset = 2
    local yOffset = 1
    for i = i, xOffset, yOffset do
        local _ = string.format("%s.xRotationNodes.xRotationNode%d", key, i)
        if not xmlFile:hasProperty(_) then
            Logging.xmlWarning(xmlFile, "Missing second xRotation node for easy control!")
            return false
        end
        XMLUtil.checkDeprecatedXMLElements(xmlFile, _ .. "#refNode")
        local translationNode = xmlFile:getValue(_ .. "#node", nil, self.components, self.i3dMappings)
        if translationNode ~= nil then
            local movingTool = self:getMovingToolByNode(translationNode)
            if movingTool ~= nil then
                movingTool.easyArmControlActive = false
                local curRot = {
                    ["node"] = translationNode,
                    ["movingTool"] = movingTool,
                    ["startRotation"] = { getRotation(translationNode) }
                }
                table.insert(easyArmControl.xRotationNodes, curRot)
            end
        end
    end
    if #easyArmControl.xRotationNodes ~= 2 then
        Logging.xmlWarning(xmlFile, "Easy arm control requires two x rotation nodes! Only %d given. (%s)", #easyArmControl.xRotationNodes, key)
        return false
    end
    if easyArmControl.targetRefNode ~= nil then
        local xOffset, yOffset, i = localToLocal(easyArmControl.targetRefNode, easyArmControl.xRotationNodes[2].node, 0, 0, 0)
        if math.abs(xOffset) > 0.0001 or math.abs(yOffset) > 0.0001 then
            Logging.xmlWarning(xmlFile, "Invalid position of \'%s\'. Offset to second xRotation node is not 0 on X or Y axis (x: %f y: %f)", key .. "#refNode", xOffset, yOffset)
            return false
        end
    end
    local xOffset, yOffset, i = localToLocal(easyArmControl.xRotationNodes[2].node, easyArmControl.xRotationNodes[1].node, 0, 0, 0)
    if math.abs(xOffset) > 0.0001 or math.abs(yOffset) > 0.0001 then
        Logging.xmlWarning(xmlFile, "Invalid position of xRotationNode2. Offset to second xRotationNode1 is not 0 on X or Y axis (x: %f y: %f)", xOffset, yOffset)
        return false
    end
    local _ = calcDistanceFrom(easyArmControl.rootNode, easyArmControl.xRotationNodes[1].node)
    if _ > 0.05 then
        Logging.xmlWarning(xmlFile, "Distance between easyArmControl rootNode and xRotationNode1 is to big (%.2f). They should be at the same position.", _)
        return false
    end
    easyArmControl.maxTotalDistance = xmlFile:getValue(key .. "#maxTotalDistance")
    if easyArmControl.maxTotalDistance == nil then
        local i = 1
        for i = i, #easyArmControl.xRotationNodes do
            local xRotationNode = easyArmControl.xRotationNodes[i]
            local curRot = {
                getRotation(xRotationNode.node),
                [xRotationNode.movingTool.rotationAxis] = xRotationNode.movingTool.rotMin
            }
            setRotation(xRotationNode.node, curRot[1], curRot[2], curRot[3])
        end
        local i = 1
        for i = i, #easyArmControl.zTranslationNodes do
            local xRotationNode = easyArmControl.zTranslationNodes[i]
            local curRot = {
                getTranslation(xRotationNode.node),
                [xRotationNode.movingTool.translationAxis] = xRotationNode.movingTool.transMax
            }
            setTranslation(xRotationNode.node, curRot[1], curRot[2], curRot[3])
        end
        easyArmControl.maxTotalDistance = calcDistanceFrom(easyArmControl.rootNode, easyArmControl.targetRefNode)
        easyArmControl.maxTransDistance = calcDistanceFrom(easyArmControl.xRotationNodes[#easyArmControl.xRotationNodes].node, easyArmControl.targetRefNode)
        local i = 1
        for i = i, #easyArmControl.xRotationNodes do
            local xRotationNode = easyArmControl.xRotationNodes[i]
            setRotation(xRotationNode.node, xRotationNode.startRotation[1], xRotationNode.startRotation[2], xRotationNode.startRotation[3])
        end
        local i = 1
        for i = i, #easyArmControl.zTranslationNodes do
            local xRotationNode = easyArmControl.zTranslationNodes[i]
            setTranslation(xRotationNode.node, xRotationNode.startTranslation[1], xRotationNode.startTranslation[2], xRotationNode.startTranslation[3])
        end
    end
    return true
end
function Cylindered:updateEasyControl(dt, updateDelayedNodes)
    local spec = self.spec_cylindered
    local easyArmControl = spec.easyArmControl
    if easyArmControl ~= nil then
        local targetYTool = self:getMovingToolByNode(easyArmControl.targetNodeY)
        local targetZTool = self:getMovingToolByNode(easyArmControl.targetNodeZ)
        local moveInputY = self:getMovingToolMoveValue(targetYTool)
        local moveInputZ = self:getMovingToolMoveValue(targetZTool)
        local hasChanged = false
        if moveInputY ~= 0 or moveInputZ ~= 0 then
            hasChanged = true
            if moveInputY ~= 0 and targetYTool.isConsumingPower or moveInputZ ~= 0 and targetZTool.isConsumingPower then
                spec.powerConsumingTimer = spec.powerConsumingActiveTimeOffset
            end
        end
        if self.isServer and (easyArmControl.state and hasChanged) then
            local transSpeedY = moveInputY * easyArmControl.moveSpeed
            if easyArmControl.moveAcceleration ~= nil then
                if math.abs(transSpeedY - easyArmControl.lastSpeedY) >= easyArmControl.moveAcceleration * dt then
                    if easyArmControl.lastSpeedY < transSpeedY then
                        transSpeedY = easyArmControl.lastSpeedY + easyArmControl.moveAcceleration * dt
                    else
                        transSpeedY = easyArmControl.lastSpeedY - easyArmControl.moveAcceleration * dt
                    end
                end
            end
            local transSpeedZ = moveInputZ * easyArmControl.moveSpeed
            if easyArmControl.moveAcceleration ~= nil then
                if math.abs(transSpeedZ - easyArmControl.lastSpeedZ) >= easyArmControl.moveAcceleration * dt then
                    if easyArmControl.lastSpeedZ < transSpeedZ then
                        transSpeedZ = easyArmControl.lastSpeedZ + easyArmControl.moveAcceleration * dt
                    else
                        transSpeedZ = easyArmControl.lastSpeedZ - easyArmControl.moveAcceleration * dt
                    end
                end
            end
            easyArmControl.lastSpeedY = transSpeedY
            local moveY = transSpeedY * dt
            easyArmControl.lastSpeedZ = transSpeedZ
            local moveZ = transSpeedZ * dt
            local worldTargetDirX, worldTargetDirY, worldTargetDirZ = localDirectionToWorld(easyArmControl.rootNode, 0, moveY, moveZ)
            local worldTargetX, worldTargetY, worldTargetZ = getWorldTranslation(easyArmControl.targetRefNode)
            local worldTargetX = worldTargetX + worldTargetDirX
            local worldTargetY = worldTargetY + worldTargetDirY
            local worldTargetZ = worldTargetZ + worldTargetDirZ
            local locTargetX, locTargetY, locTargetZ = worldToLocal(easyArmControl.rootNode, worldTargetX, worldTargetY, worldTargetZ)
            local distanceToTarget = MathUtil.vector3Length(locTargetX, locTargetY, locTargetZ)
            local targetExceedFactor = easyArmControl.maxTotalDistance / distanceToTarget
            if targetExceedFactor < 1 then
                worldTargetX, worldTargetY, worldTargetZ = localToWorld(easyArmControl.rootNode, locTargetX * targetExceedFactor, locTargetY * targetExceedFactor, locTargetZ * targetExceedFactor)
                distanceToTarget = easyArmControl.maxTotalDistance
            end
            local circleDistance1 = MathUtil.vector3Length(localToLocal(easyArmControl.xRotationNodes[2].node, easyArmControl.xRotationNodes[1].node, 0, 0, 0))
            local _, _, circleDistance2 = localToLocal(easyArmControl.targetRefNode, easyArmControl.xRotationNodes[2].node, 0, 0, 0)
            local circle1X, circle1Y, circle1Z = localToLocal(easyArmControl.xRotationNodes[1].node, easyArmControl.rootNode, 0, 0, 0)
            local circle2X, circle2Y, circle2Z = worldToLocal(easyArmControl.rootNode, worldTargetX, worldTargetY, worldTargetZ)
            local numZTranslationNodes = #easyArmControl.zTranslationNodes
            if numZTranslationNodes > 0 then
                local inputDirY, inputDirZ = MathUtil.vector2Normalize(math.abs(moveY), (math.abs(moveZ)))
                if moveY == 0 and moveZ == 0 then
                    inputDirY = 0
                    inputDirZ = 0
                end
                local transDirX, transDirY, transDirZ = localDirectionToWorld(easyArmControl.zTranslationNodes[1].node, 0, 0, 1)
                local difference, rotTransRatio, _ = worldDirectionToLocal(easyArmControl.rootNode, transDirX, transDirY, transDirZ)
                local difference = math.acos((MathUtil.dotProduct(0, inputDirY, inputDirZ, 0, rotTransRatio, _)))
                if difference > 1.5707963267948966 then
                end
                local zDifference = easyArmControl.maxTransMoveRatio
                local _ = math.clamp((1 - difference / 1.5707963267948966 - easyArmControl.transMoveRatioMinDir) / (easyArmControl.transMoveRatioMaxDir - easyArmControl.transMoveRatioMinDir), easyArmControl.minTransMoveRatio, zDifference)
                local _, _, targetZOffset = worldToLocal(easyArmControl.xRotationNodes[2].node, worldTargetX, worldTargetY, worldTargetZ)
                local zDifference = targetZOffset - circleDistance2
                local minTransPct = 0
                if not easyArmControl.allowNegativeTrans and _ < 0 then
                    minTransPct = easyArmControl.minNegativeTrans * -(zDifference > 0 and -2 or _)
                end
                local i = 1
                for i = i, numZTranslationNodes do
                    local movingTool = easyArmControl.zTranslationNodes[i].movingTool
                    local delta = zDifference * _ / numZTranslationNodes
                    if easyArmControl.forcedTransMove ~= nil then
                        delta = easyArmControl.forcedTransMove * movingTool.transSpeed * dt
                        easyArmControl.forcedTransMove = nil
                    end
                    local currentTrans = movingTool.curTrans[movingTool.translationAxis]
                    Cylindered.setAbsoluteToolTranslation(self, movingTool, currentTrans + (math.clamp(currentTrans + delta, (movingTool.transMax - movingTool.transMin) * minTransPct + movingTool.transMin, movingTool.transMax) - currentTrans))
                end
                circleDistance2 = MathUtil.vector3Length(worldToLocal(easyArmControl.xRotationNodes[2].node, getWorldTranslation(easyArmControl.targetRefNode)))
            end
            local inputDirY, inputDirZ, transDirX, transDirY = MathUtil.getCircleCircleIntersection(circle1Z, circle1Y, circleDistance1, circle2Z, circle2Y, circleDistance2)
            if inputDirY ~= nil and inputDirZ ~= nil then
                local transDirZ = easyArmControl.xRotationNodes[1].movingTool
                local difference = easyArmControl.xRotationNodes[2].movingTool
                local rotTransRatio = -math.atan2(inputDirZ, inputDirY)
                rotTransRatio = math.clamp(rotTransRatio, transDirZ.rotMin, transDirZ.rotMax)
                Cylindered.setAbsoluteToolRotation(self, easyArmControl.xRotationNodes[1].movingTool, rotTransRatio, updateDelayedNodes)
                local minTransPct = targetZOffset - math.clamp(3.141592653589793 - math.acos((circleDistance1 * circleDistance1 + circleDistance2 * circleDistance2 - distanceToTarget * distanceToTarget) / (2 * circleDistance1 * circleDistance2)) + 0, difference.rotMin, difference.rotMax)
                Cylindered.setAbsoluteToolRotation(self, easyArmControl.xRotationNodes[2].movingTool, zDifference, updateDelayedNodes)
                Cylindered.setAbsoluteToolRotation(self, easyArmControl.xRotationNodes[1].movingTool, math.clamp(rotTransRatio + minTransPct * 0.5, transDirZ.rotMin, transDirZ.rotMax), updateDelayedNodes)
            end
        end
    end
end
function Cylindered:setIsEasyControlActive(state)
    local spec = self.spec_cylindered
    local easyArmControl = spec.easyArmControl
    if easyArmControl ~= nil then
        if self.isServer then
            if easyArmControl ~= nil then
                local targetYTool = self:getMovingToolByNode(easyArmControl.targetNodeY)
                local targetZTool = self:getMovingToolByNode(easyArmControl.targetNodeZ)
                if state then
                    local origin = getParent(easyArmControl.targetNodeY)
                    if origin == easyArmControl.targetNodeZ then
                        origin = getParent(easyArmControl.targetNodeZ)
                    end
                    local _, y, _ = localToLocal(easyArmControl.targetRefNode, origin, 0, 0, 0)
                    local _, oldY, _ = getTranslation(easyArmControl.targetNodeY)
                    if Cylindered.setToolTranslation(self, targetYTool, nil, 0, y - oldY) then
                        Cylindered.setDirty(self, targetYTool)
                    end
                    local _, _, oldZ = localToLocal(easyArmControl.targetRefNode, origin, 0, 0, 0)
                    local _, _, oldZ = getTranslation(easyArmControl.targetNodeZ)
                    if Cylindered.setToolTranslation(self, targetZTool, nil, 0, oldZ - oldZ) then
                        Cylindered.setDirty(self, targetZTool)
                    end
                    easyArmControl.lastValidPositionY[1], easyArmControl.lastValidPositionY[2], easyArmControl.lastValidPositionY[3] = getTranslation(easyArmControl.targetNodeY)
                    easyArmControl.lastValidPositionZ[1], easyArmControl.lastValidPositionZ[2], easyArmControl.lastValidPositionZ[3] = getTranslation(easyArmControl.targetNodeZ)
                    self:raiseDirtyFlags(spec.cylinderedDirtyFlag)
                end
                easyArmControl.state = state
            end
        else
            easyArmControl.state = state
        end
    end
    self:requestActionEventUpdate()
end
function Cylindered:setEasyControlForcedTransMove(value)
    local easyArmControl = self.spec_cylindered.easyArmControl
    if easyArmControl ~= nil then
        easyArmControl.forcedTransMove = value
    end
end
function Cylindered:updateExtraDependentParts(part, dt) end
function Cylindered:updateDependentAnimations(part, _)
    if #part.dependentAnimations > 0 then
        for _, dependentAnimation in ipairs(part.dependentAnimations) do
            local pos = 0
            if dependentAnimation.translationAxis ~= nil then
                pos = (select(dependentAnimation.translationAxis, getTranslation(dependentAnimation.node)) - dependentAnimation.minValue) / (dependentAnimation.maxValue - dependentAnimation.minValue)
            end
            if dependentAnimation.rotationAxis ~= nil then
                pos = (select(dependentAnimation.rotationAxis, getRotation(dependentAnimation.node)) - dependentAnimation.minValue) / (dependentAnimation.maxValue - dependentAnimation.minValue)
            end
            local translationAxisValue = math.clamp(pos, 0, 1)
            if dependentAnimation.invert then
            end
            dependentAnimation.lastPos = translationAxisValue
            self:setAnimationTime(dependentAnimation.name, translationAxisValue, true, true)
        end
    end
end
function Cylindered:updateDependentToolLimits(tool, dependentTool)
    if dependentTool.minTransLimits ~= nil or dependentTool.maxTransLimits ~= nil then
        local state = Cylindered.getMovingToolState(self, tool)
        if dependentTool.minTransLimits ~= nil then
            dependentTool.movingTool.transMin = MathUtil.lerp(dependentTool.minTransLimits[1], dependentTool.minTransLimits[2], 1 - state)
        end
        if dependentTool.maxTransLimits ~= nil then
            dependentTool.movingTool.transMax = MathUtil.lerp(dependentTool.maxTransLimits[1], dependentTool.maxTransLimits[2], 1 - state)
        end
        if Cylindered.setToolTranslation(self, dependentTool.movingTool, 0, 0) then
            Cylindered.setDirty(self, dependentTool.movingTool)
        end
    end
    if dependentTool.minRotLimits ~= nil or dependentTool.maxRotLimits ~= nil then
        local state = Cylindered.getMovingToolState(self, tool)
        if dependentTool.minRotLimits ~= nil then
            dependentTool.movingTool.rotMin = MathUtil.lerp(dependentTool.minRotLimits[1], dependentTool.minRotLimits[2], 1 - state)
        end
        if dependentTool.maxRotLimits ~= nil then
            dependentTool.movingTool.rotMax = MathUtil.lerp(dependentTool.maxRotLimits[1], dependentTool.maxRotLimits[2], 1 - state)
        end
        dependentTool.movingTool.networkInterpolators.rotation:setMinMax(dependentTool.movingTool.rotMin, dependentTool.movingTool.rotMax)
        if Cylindered.setToolRotation(self, dependentTool.movingTool, 0, 0) then
            Cylindered.setDirty(self, dependentTool.movingTool)
        end
    end
end
function Cylindered:onMovingPartSoundEvent(part, action, type)
    if part.samplesByAction ~= nil then
        local samples = part.samplesByAction[action]
        if samples ~= nil then
            local i = 1
            for i = i, #samples do
                if type == Cylindered.SOUND_TYPE_EVENT then
                    if samples[i].loops == 0 then
                        sample.loops = 1
                    end
                    g_soundManager:playSample(sample)
                elseif type == Cylindered.SOUND_TYPE_CONTINUES then
                    if g_soundManager:getIsSamplePlaying(sample) then
                        if sample.lastActivationPart == part then
                            sample.lastActivationTime = g_time
                        end
                    else
                        g_soundManager:playSample(sample)
                        sample.lastActivationTime = g_time
                        sample.lastActivationPart = part
                        table.insert(self.spec_cylindered.activeSamples, sample)
                    end
                elseif type == Cylindered.SOUND_TYPE_ENDING then
                    local spec = self.spec_cylindered
                    if spec.endingSamplesBySample[sample] == nil then
                        sample.lastActivationTime = g_time
                        table.insert(spec.endingSamples, sample)
                        spec.endingSamplesBySample[sample] = sample
                    else
                        sample.lastActivationTime = g_time
                    end
                elseif type == Cylindered.SOUND_TYPE_STARTING then
                    local spec = self.spec_cylindered
                    if spec.startingSamplesBySample[sample] == nil then
                        if sample.loops == 0 then
                            sample.loops = 1
                        end
                        g_soundManager:playSample(sample)
                        sample.lastActivationTime = g_time
                        table.insert(spec.startingSamples, sample)
                        spec.startingSamplesBySample[sample] = sample
                    else
                        sample.lastActivationTime = g_time
                    end
                end
            end
        end
    end
end
function Cylindered:updateMovingToolSoundEvents(tool, direction, hitLimit, wasAtLimit)
    if tool.samplesByAction ~= nil then
        self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_END, Cylindered.SOUND_TYPE_ENDING)
        self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_START, Cylindered.SOUND_TYPE_STARTING)
        if direction then
            self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_POS, Cylindered.SOUND_TYPE_CONTINUES)
            self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_END_POS, Cylindered.SOUND_TYPE_ENDING)
            self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_START_POS, Cylindered.SOUND_TYPE_STARTING)
            if hitLimit then
                self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_END_POS_LIMIT, Cylindered.SOUND_TYPE_ENDING)
            end
            if wasAtLimit then
                self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_START_POS_LIMIT, Cylindered.SOUND_TYPE_STARTING)
                return
            end
        else
            self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_NEG, Cylindered.SOUND_TYPE_CONTINUES)
            self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_END_NEG, Cylindered.SOUND_TYPE_ENDING)
            self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_START_NEG, Cylindered.SOUND_TYPE_STARTING)
            if hitLimit then
                self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_END_NEG_LIMIT, Cylindered.SOUND_TYPE_ENDING)
            end
            if wasAtLimit then
                self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_START_NEG_LIMIT, Cylindered.SOUND_TYPE_STARTING)
            end
        end
    end
end
function Cylindered:updateControlGroups()
    local spec = self.spec_cylindered
    self:clearSubselections()
    for k, _ in pairs(spec.controlGroupMapping) do
        spec.controlGroupMapping[k] = nil
    end
    for k, _ in ipairs(spec.controlGroups) do
        local isActive = false
        for _, movingTool in pairs(spec.movingTools) do
            if movingTool.axisActionIndex ~= nil and (movingTool.controlGroupIndex == _ and movingTool.lastIsActiveState) then
                isActive = true
                break
            end
        end
        if isActive then
            local subSelectionIndex = self:addSubselection(_)
            spec.controlGroupMapping[subSelectionIndex] = _
        end
    end
    self.rootVehicle:updateSelectableObjects()
    if self.rootVehicle:getSelectedVehicle() == self then
        self.rootVehicle:setSelectedVehicle(self, 99999, false)
    end
end
function Cylindered:onUpdateTick(dt, _, _, _)
    if self.isClient then
        local spec = self.spec_cylindered
        local movingToolStateChanged = false
        for _, movingTool in pairs(spec.movingTools) do
            if movingTool.axisActionIndex ~= nil then
                local isActive = self:getIsMovingToolActive(movingTool)
                if isActive ~= movingTool.lastIsActiveState then
                    movingTool.lastIsActiveState = isActive
                    movingToolStateChanged = true
                end
                if spec.currentControlGroupIndex == movingTool.controlGroupIndex then
                    local actionEvent = spec.actionEvents[movingTool.axisActionIndex]
                    if actionEvent ~= nil then
                        g_inputBinding:setActionEventActive(actionEvent.actionEventId, isActive)
                        if not isActive then
                            movingTool.move = 0
                            if movingTool.move ~= movingTool.moveToSend then
                                movingTool.moveToSend = movingTool.move
                                self:raiseDirtyFlags(spec.cylinderedInputDirtyFlag)
                            end
                        end
                    end
                end
            end
        end
        if movingToolStateChanged then
            self:updateControlGroups()
        end
        local i = #spec.activeSamples
        for i = i, 1, -1 do
            local _ = spec.activeSamples[i]
            if _.lastActivationTime + dt * 3 < g_time then
                if _.lastActivationTime + dt * 3 + _.dropOffTime >= g_time then
                    if not _.dropOffActive then
                        _.dropOffActive = true
                        g_soundManager:setSamplePitchOffset(_, g_soundManager:getCurrentSamplePitch(_) * (_.dropOffFactor - 1))
                    end
                else
                    _.dropOffActive = false
                    g_soundManager:setSamplePitchOffset(_, 0)
                    g_soundManager:stopSample(_)
                    table.remove(spec.activeSamples, i)
                end
            end
        end
        local i = #spec.endingSamples
        for i = i, 1, -1 do
            local _ = spec.endingSamples[i]
            if _.lastActivationTime + dt < g_time then
                if _.loops == 0 then
                    _.loops = 1
                end
                g_soundManager:playSample(_)
                table.remove(spec.endingSamples, i)
                spec.endingSamplesBySample[_] = nil
            end
        end
        local i = #spec.startingSamples
        for i = i, 1, -1 do
            local _ = spec.startingSamples[i]
            if _.lastActivationTime + dt < g_time then
                table.remove(spec.startingSamples, i)
                spec.startingSamplesBySample[_] = nil
            end
        end
    end
end
function Cylindered:onUpdateEnd(dt, _, _, _)
    for _, part in pairs(self.spec_cylindered.activeDirtyMovingParts) do
        Cylindered.setDirty(self, part)
    end
    self:updateDirtyMovingParts(dt, true)
end
function Cylindered:onPostUpdate(dt, _, _, _)
    for _, part in pairs(self.spec_cylindered.activeDirtyMovingParts) do
        if self.currentUpdateDistance < part.maxUpdateDistance then
            Cylindered.setDirty(self, part)
        end
    end
    self:updateDirtyMovingParts(dt, true)
end
function Cylindered:onPostUpdateTick(dt, _, _, _)
    self:updateDirtyMovingParts(dt, false)
end
function Cylindered:updateDirtyMovingParts(dt, updateSound)
    local spec = self.spec_cylindered
    local i = 1
    for i = i, #spec.movingTools do
        local tool = spec.movingTools[i]
        if tool.isDirty then
            if tool.playSound then
                spec.movingToolNeedsSound = true
            end
            Cylindered.updateWheels(self, tool)
            if self.isServer then
                Cylindered.updateComponentJoints(self, tool, false)
            end
            self:updateExtraDependentParts(tool, dt)
            self:updateDependentAnimations(tool, dt)
            tool.isDirty = false
        end
    end
    if self.anyMovingPartsDirty then
        local i = 1
        for i = i, #spec.movingParts do
            local tool = spec.movingParts[i]
            if tool.isDirty then
                local isActive = self:getIsMovingPartActive(tool)
                if isActive or tool.smoothedDirectionScale and tool.smoothedDirectionScaleAlpha ~= 0 then
                    Cylindered.updateMovingPart(self, tool, false, nil, isActive)
                    self:updateExtraDependentParts(tool, dt)
                    self:updateDependentAnimations(tool, dt)
                    if tool.playSound then
                        spec.cylinderedHydraulicSoundPartNumber = i
                        spec.movingPartNeedsSound = true
                    end
                end
            elseif spec.isClient and spec.cylinderedHydraulicSoundPartNumber == i then
                spec.movingPartNeedsSound = false
            end
        end
        self.anyMovingPartsDirty = false
    end
    if updateSound and self.isClient then
        if spec.movingToolNeedsSound or spec.movingPartNeedsSound then
            if not spec.isHydraulicSamplePlaying then
                g_soundManager:playSample(spec.samples.hydraulic)
                spec.isHydraulicSamplePlaying = true
            end
            self:raiseActive()
            return
        end
        if spec.isHydraulicSamplePlaying then
            g_soundManager:stopSample(spec.samples.hydraulic)
            spec.isHydraulicSamplePlaying = false
        end
    end
end
function Cylindered:onDraw(_, isActiveForInputIgnoreSelection, _)
    local spec = self.spec_cylindered
    if #spec.controlGroupNames > 1 and (isActiveForInputIgnoreSelection and spec.currentControlGroupIndex ~= 0) then
        g_currentMission:addExtraPrintText(string.format(g_i18n:getText("action_selectedControlGroup"), spec.controlGroupNames[spec.currentControlGroupIndex], spec.currentControlGroupIndex))
    end
end
function Cylindered:loadMovingPartsFromXML(xmlFile, key)
    for _, partKey in xmlFile:iterator(key) do
        local entry = {}
        if self:loadMovingPartFromXML(xmlFile, partKey, entry) then
            if self.spec_cylindered.referenceNodes[entry.node] == nil then
                spec.referenceNodes[entry.node] = {}
            end
            if spec.nodesToMovingParts[entry.node] == nil then
                table.insert(spec.referenceNodes[entry.node], entry)
                self:loadDependentParts(xmlFile, partKey, entry)
                self:loadDependentComponentJoints(xmlFile, partKey, entry)
                self:loadCopyLocalDirectionParts(xmlFile, partKey, entry)
                self:loadExtraDependentParts(xmlFile, partKey, entry)
                self:loadDependentAnimations(xmlFile, partKey, entry)
                entry.key = partKey
                table.insert(spec.movingParts, entry)
                if entry.isActiveDirty then
                    table.insert(spec.activeDirtyMovingParts, entry)
                end
                spec.nodesToMovingParts[entry.node] = entry
            else
                Logging.xmlWarning(xmlFile, "Moving part with node \'%s\' already exists!", getName(entry.node))
            end
        end
    end
end
function Cylindered:loadMovingPartFromXML(xmlFile, key, entry)
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")
    local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
    local referenceFrame = xmlFile:getValue(key .. "#referenceFrame", nil, self.components, self.i3dMappings)
    if node == nil or referenceFrame == nil then
        return false
    end
    entry.referencePoint = xmlFile:getValue(key .. "#referencePoint", nil, self.components, self.i3dMappings)
    entry.referencePoints = xmlFile:getValue(key .. "#referencePoints", nil, self.components, self.i3dMappings, true)
    entry.numReferencePoints = #entry.referencePoints
    local x = true
    if entry.numReferencePoints <= 0 then
        x = entry.referencePoint ~= nil
    end
    entry.hasReferencePoints = x
    entry.node = node
    entry.parent = getParent(node)
    entry.referenceFrame = referenceFrame
    entry.invertZ = xmlFile:getValue(key .. "#invertZ", false)
    entry.scaleZ = xmlFile:getValue(key .. "#scaleZ", false)
    entry.limitedAxis = xmlFile:getValue(key .. "#limitedAxis")
    entry.isActiveDirty = xmlFile:getValue(key .. "#isActiveDirty", false)
    entry.playSound = xmlFile:getValue(key .. "#playSound", false)
    entry.moveToReferenceFrame = xmlFile:getValue(key .. "#moveToReferenceFrame", false)
    if entry.moveToReferenceFrame then
        local x, y, z = worldToLocal(referenceFrame, getWorldTranslation(node))
        entry.referenceFrameOffset = { x, y, z }
    end
    if entry.referenceFrame == entry.node then
        Logging.xmlWarning(xmlFile, "Reference frame equals moving part node. This can lead to bad behaviours! Node \'%s\' in \'%s\'.", getName(entry.node), key)
    end
    entry.doLineAlignment = xmlFile:getValue(key .. "#doLineAlignment", false)
    entry.doInversedLineAlignment = xmlFile:getValue(key .. "#doInversedLineAlignment", false)
    entry.do3DLineAlignment = xmlFile:getValue(key .. "#do3DLineAlignment", false)
    entry.partLength = xmlFile:getValue(key .. ".orientationLine#partLength", 0.5)
    entry.partLengthNode = xmlFile:getValue(key .. ".orientationLine#partLengthNode", nil, self.components, self.i3dMappings)
    entry.orientationLineNodes = {}
    for _, pointKey in self.xmlFile:iterator(key .. ".orientationLine.lineNode") do
        local lineNode = xmlFile:getValue(pointKey .. "#node", nil, self.components, self.i3dMappings)
        if lineNode ~= nil then
            if entry.doInversedLineAlignment then
                local _, _, zOffset = localToLocal(lineNode, entry.node, 0, 0, 0)
                if zOffset >= 0 then
                    goto l16
                end
                Logging.xmlWarning(xmlFile, "Local orientation line node \'%s\' is in negative Z direction to the movingPart node. This is not allowed! (%s)", getName(lineNode), pointKey)
            else
                ::l16::
                table.insert(entry.orientationLineNodes, lineNode)
            end
        end
    end
    if entry.do3DLineAlignment then
        if #entry.orientationLineNodes == 2 then
            entry.orientationLineTransNode = xmlFile:getValue(key .. ".orientationLine#referenceTransNode", nil, self.components, self.i3dMappings)
            if entry.orientationLineTransNode == nil then
                Logging.xmlWarning(xmlFile, "Failed to load 3D line alignment from xml. Missing referenceTransNode! (movingPart \'%s\')", getName(node))
                entry.do3DLineAlignment = false
            end
        else
            Logging.xmlWarning(xmlFile, "Failed to load 3D line alignment from xml. Requires exactly two line nodes! (movingPart \'%s\')", getName(node))
            entry.do3DLineAlignment = false
        end
    end
    entry.doDirectionAlignment = xmlFile:getValue(key .. "#doDirectionAlignment", true)
    entry.doRotationAlignment = xmlFile:getValue(key .. "#doRotationAlignment", false)
    entry.rotMultiplier = xmlFile:getValue(key .. "#rotMultiplier", 0)
    if entry.doDirectionAlignment and entry.doRotationAlignment then
        Logging.xmlWarning(xmlFile, "Direction alignment and rotation alignment used at the same time for movingPart \'%s\' in \'%s\'", getName(node), key)
        return false
    end
    if entry.doDirectionAlignment and (entry.doLineAlignment or (entry.doInversedLineAlignment or entry.do3DLineAlignment)) then
        Logging.xmlWarning(xmlFile, "Direction alignment and line alignment used at the same time for movingPart \'%s\' in \'%s\'", getName(node), key)
        return false
    end
    local x = xmlFile:getValue(key .. "#minRot")
    local y = xmlFile:getValue(key .. "#maxRot")
    if x ~= nil and y ~= nil then
        if entry.limitedAxis == nil then
            Logging.xmlWarning(xmlFile, "minRot/maxRot requires the use of limitedAxis in for movingPart \'%s\' in \'%s\'", getName(node), key)
        else
            entry.minRot = MathUtil.getValidLimit(x)
            entry.maxRot = MathUtil.getValidLimit(y)
        end
    end
    entry.alignToWorldY = xmlFile:getValue(key .. "#alignToWorldY", false)
    if entry.hasReferencePoints then
        local z = xmlFile:getValue(key .. "#localReferencePoint", nil, self.components, self.i3dMappings)
        local _, pointKey, lineNode
        if entry.referencePoint == nil then
            local _ = 0
            local pointKey = 0
            local lineNode = 0
            for i, referencePoint in ipairs(entry.referencePoints) do
                local x, y, z = worldToLocal(node, getWorldTranslation(referencePoint))
            end
            _ = _ / entry.numReferencePoints
            pointKey = pointKey / entry.numReferencePoints
            lineNode = lineNode / entry.numReferencePoints
        else
            _, pointKey, lineNode = worldToLocal(node, getWorldTranslation(entry.referencePoint))
        end
        local _, zOffset, i = worldToLocal(entry.node, _, pointKey, lineNode)
        entry.smoothedDirectionScaleZOffset = i
        if z == nil then
            entry.referenceDistance = 0
            entry.localReferencePoint = { _, pointKey, lineNode }
        else
            local _, zOffset, i = worldToLocal(node, getWorldTranslation(z))
            entry.referenceDistance = MathUtil.vector3Length(_ - _, pointKey - zOffset, lineNode - i)
            entry.lastReferenceDistance = entry.referenceDistance
            entry.localReferencePoint = { _, zOffset, i }
            entry.localReferenceAngleSide = zOffset * (lineNode - i) - i * (pointKey - zOffset)
            entry.localReferencePointNode = z
            entry.updateLocalReferenceDistance = xmlFile:getValue(key .. "#updateLocalReferenceDistance", false)
            entry.localReferenceTranslate = xmlFile:getValue(key .. "#localReferenceTranslate", false)
            if entry.localReferenceTranslate then
                entry.localReferenceTranslation = { getTranslation(entry.node) }
            end
            entry.dynamicLocalReferenceDistance = xmlFile:getValue(key .. "#dynamicLocalReferenceDistance", false)
        end
        entry.referenceDistanceThreshold = xmlFile:getValue(key .. "#referenceDistanceThreshold", 0.0001)
        entry.useLocalOffset = xmlFile:getValue(key .. "#useLocalOffset", false)
        entry.referencePointOffset = xmlFile:getValue(key .. "#referencePointOffset")
        entry.referenceDistance = xmlFile:getValue(key .. "#referenceDistance", entry.referenceDistance)
        entry.referenceDistancePoint = xmlFile:getValue(key .. "#referenceDistancePoint", nil, self.components, self.i3dMappings)
        entry.localReferenceDistance = xmlFile:getValue(key .. "#localReferenceDistance", MathUtil.vector2Length(entry.localReferencePoint[2], entry.localReferencePoint[3]))
        self:loadDependentTranslatingParts(xmlFile, key, entry)
    end
    self:loadDependentMovingTools(xmlFile, key, entry)
    entry.directionThreshold = xmlFile:getValue(key .. "#directionThreshold", 0.0001)
    entry.directionThresholdActive = xmlFile:getValue(key .. "#directionThresholdActive", 0.00001)
    if entry.doDirectionAlignment and not entry.hasReferencePoints then
        entry.directionThreshold = 0
        entry.directionThresholdActive = 0
    end
    entry.maxUpdateDistance = xmlFile:getValue(key .. "#maxUpdateDistance", "-")
    if entry.maxUpdateDistance == "-" then
        entry.maxUpdateDistance = math.huge
    else
        entry.maxUpdateDistance = tonumber(entry.maxUpdateDistance)
    end
    if entry.isActiveDirty and (xmlFile:getString(key .. "#maxUpdateDistance") == nil or entry.maxUpdateDistance == nil) then
        Logging.xmlWarning(xmlFile, "No max. update distance set for isActiveDirty moving part \'%s\'! Use #maxUpdateDistance attribute.", getName(node))
    end
    entry.smoothedDirectionScale = xmlFile:getValue(key .. "#smoothedDirectionScale", false)
    entry.smoothedDirectionTime = 1 / xmlFile:getValue(key .. "#smoothedDirectionTime", 2)
    entry.smoothedDirectionScaleAlpha = nil
    if entry.smoothedDirectionScale then
        entry.initialDirection = { localDirectionToLocal(entry.node, getParent(entry.node), 0, 0, 1) }
    end
    entry.debug = xmlFile:getValue(key .. "#debug", false)
    if entry.debug then
        Logging.xmlWarning(xmlFile, "MovingPart debug enabled for moving part \'%s\'", getName(node))
    end
    entry.lastDirection = { 0, 0, 0 }
    entry.lastUpVector = { 0, 0, 0 }
    entry.isDirty = false
    entry.isPart = true
    entry.isActive = true
    return true
end
function Cylindered:loadMovingToolsFromXML(xmlFile, key)
    for _, toolKey in xmlFile:iterator(key) do
        local entry = {}
        if self:loadMovingToolFromXML(xmlFile, toolKey, entry) then
            if self.spec_cylindered.referenceNodes[entry.node] == nil then
                spec.referenceNodes[entry.node] = {}
            end
            if spec.nodesToMovingTools[entry.node] == nil then
                table.insert(spec.referenceNodes[entry.node], entry)
                self:loadDependentMovingTools(xmlFile, toolKey, entry)
                self:loadDependentParts(xmlFile, toolKey, entry)
                self:loadDependentComponentJoints(xmlFile, toolKey, entry)
                self:loadExtraDependentParts(xmlFile, toolKey, entry)
                self:loadDependentAnimations(xmlFile, toolKey, entry)
                entry.isActive = true
                entry.key = toolKey
                table.insert(spec.movingTools, entry)
                spec.nodesToMovingTools[entry.node] = entry
            else
                Logging.xmlWarning(xmlFile, "Moving tool with node \'%s\' already exists!", getName(entry.node))
            end
        end
    end
end
function Cylindered:loadMovingToolFromXML(xmlFile, key, entry)
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")
    local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
    if node == nil then
        return false
    end
    entry.node = node
    entry.externalMove = 0
    entry.easyArmControlActive = true
    entry.isEasyControlTarget = xmlFile:getValue(key .. "#isEasyControlTarget", false)
    entry.networkInterpolators = {}
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#rotSpeed", key .. ".rotation#rotSpeed")
    local rotSpeed = xmlFile:getValue(key .. ".rotation#rotSpeed")
    if rotSpeed ~= nil then
        entry.rotSpeed = rotSpeed / 1000
    end
    local rotAcceleration = xmlFile:getValue(key .. ".rotation#rotAcceleration")
    if rotAcceleration ~= nil then
        entry.rotAcceleration = rotAcceleration / 1000000
    end
    entry.lastRotSpeed = 0
    entry.rotMax = xmlFile:getValue(key .. ".rotation#rotMax")
    entry.rotMin = xmlFile:getValue(key .. ".rotation#rotMin")
    entry.syncMaxRotLimits = xmlFile:getValue(key .. ".rotation#syncMaxRotLimits", false)
    entry.syncMinRotLimits = xmlFile:getValue(key .. ".rotation#syncMinRotLimits", false)
    entry.rotSendNumBits = xmlFile:getValue(key .. ".rotation#rotSendNumBits")
    entry.attachRotMax = xmlFile:getValue(key .. ".rotation#attachRotMax")
    entry.attachRotMin = xmlFile:getValue(key .. ".rotation#attachRotMin")
    if entry.rotSendNumBits == nil then
        if entry.rotMin == nil or entry.rotMax == nil then
            entry.rotSendNumBits = 11
        else
            local requiredMinValues = math.ceil((entry.rotMax - entry.rotMin) / Cylindered.MOVING_TOOL_SEND_MIN_RESOLUTION)
            entry.rotSendNumBits = requiredMinValues <= 1 and 1 or (requiredMinValues <= 3 and 2 or (requiredMinValues <= 7 and 3 or (requiredMinValues <= 15 and 4 or (requiredMinValues <= 31 and 5 or (requiredMinValues <= 63 and 6 or (requiredMinValues <= 127 and 7 or (requiredMinValues <= 255 and 8 or (requiredMinValues <= 511 and 9 or (requiredMinValues <= 1023 and 10 or (requiredMinValues <= 2047 and 11 or 11))))))))))
        end
    end
    if entry.rotMin ~= nil and (entry.rotMax ~= nil and entry.rotMin >= entry.rotMax) then
        Logging.xmlWarning(xmlFile, "Rotation min value is greater or equal to max value for movingTool \'%s\' in \'%s\'", getName(node), key)
        return false
    end
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#transSpeed", key .. ".rotation#transSpeed")
    local range = xmlFile:getValue(key .. ".translation#transSpeed")
    if range ~= nil then
        entry.transSpeed = range / 1000
    end
    local requiredMinValues = xmlFile:getValue(key .. ".translation#transAcceleration")
    if requiredMinValues ~= nil then
        entry.transAcceleration = requiredMinValues / 1000000
    end
    entry.lastTransSpeed = 0
    entry.transMax = xmlFile:getValue(key .. ".translation#transMax")
    entry.transMin = xmlFile:getValue(key .. ".translation#transMin")
    entry.attachTransMax = xmlFile:getValue(key .. ".translation#attachTransMax")
    entry.attachTransMin = xmlFile:getValue(key .. ".translation#attachTransMin")
    entry.playSound = xmlFile:getValue(key .. "#playSound", false)
    if entry.transMin ~= nil and (entry.transMax ~= nil and entry.transMin >= entry.transMax) then
        Logging.xmlWarning(xmlFile, "Translation min value is greater or equal to max value for movingTool \'%s\' in \'%s\'", getName(node), key)
        return false
    end
    entry.isConsumingPower = xmlFile:getValue(key .. "#isConsumingPower", false)
    if SpecializationUtil.hasSpecialization(AnimatedVehicle, self.specializations) then
        local bitsToUse = xmlFile:getValue(key .. ".animation#animSpeed")
        if bitsToUse ~= nil then
            entry.animSpeed = bitsToUse / 1000
        end
        local availableValues = xmlFile:getValue(key .. ".animation#animAcceleration")
        if availableValues ~= nil then
            entry.animAcceleration = availableValues / 1000000
        end
        entry.curAnimTime = 0
        entry.lastAnimSpeed = 0
        entry.animName = xmlFile:getValue(key .. ".animation#animName")
        entry.animSendNumBits = xmlFile:getValue(key .. ".animation#animSendNumBits", 8)
        local detachingTransMaxLimit = xmlFile:getValue(key .. ".animation#animMaxTime", 1)
        entry.animMaxTime = math.min(detachingTransMaxLimit, 1)
        local detachingTransMaxLimit = xmlFile:getValue(key .. ".animation#animMinTime", 0)
        entry.animMinTime = math.max(detachingTransMaxLimit, 0)
        if entry.animMinTime >= entry.animMaxTime then
            Logging.xmlWarning(xmlFile, "Animation min value is greater or equal to max value for movingTool \'%s\' in \'%s\'", getName(node), key)
            return false
        end
        entry.animStartTime = xmlFile:getValue(key .. ".animation#animStartTime")
        if entry.animStartTime ~= nil then
            entry.curAnimTime = entry.animStartTime
        end
        entry.networkInterpolators.animation = InterpolatorValue.new(entry.curAnimTime)
        entry.networkInterpolators.animation:setMinMax(0, 1)
        entry.networkInterpolators.resetAnimInterpolation = false
    end
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".controls#iconFilename", key .. ".controls#iconName")
    local bitsToUse = xmlFile:getValue(key .. ".controls#iconName")
    if bitsToUse ~= nil then
        if InputHelpElement.AXIS_ICON[bitsToUse] == nil then
        end
        entry.axisActionIcon = bitsToUse
    end
    entry.controlGroupIndex = xmlFile:getValue(key .. ".controls#groupIndex", 0)
    if entry.controlGroupIndex ~= 0 then
        if self.spec_cylindered.controlGroupNames[entry.controlGroupIndex] == nil then
            Logging.xmlWarning(xmlFile, "ControlGroup \'%d\' not defined for \'%s\'!", entry.controlGroupIndex, key)
        else
            table.addElement(spec.controlGroups, entry.controlGroupIndex)
        end
    end
    entry.axis = xmlFile:getValue(key .. ".controls#axis")
    if entry.axis ~= nil then
        entry.axisActionIndex = InputAction[entry.axis]
    end
    entry.invertAxis = xmlFile:getValue(key .. ".controls#invertAxis", false)
    entry.mouseSpeedFactor = xmlFile:getValue(key .. ".controls#mouseSpeedFactor", 1)
    if entry.rotSpeed ~= nil or (entry.transSpeed ~= nil or entry.animSpeed ~= nil) then
        entry.dirtyFlag = self:getNextDirtyFlag()
        entry.saving = xmlFile:getValue(key .. "#allowSaving", true)
    end
    entry.aiActivePosition = xmlFile:getValue(key .. "#aiActivePosition")
    entry.isDirty = false
    entry.isIntitialDirty = xmlFile:getValue(key .. "#isIntitialDirty", true)
    entry.rotationAxis = xmlFile:getValue(key .. ".rotation#rotationAxis", 1)
    entry.translationAxis = xmlFile:getValue(key .. ".translation#translationAxis", 3)
    local availableValues = xmlFile:getValue(key .. ".rotation#detachingRotMaxLimit")
    local detachingRotMinLimit = xmlFile:getValue(key .. ".rotation#detachingRotMinLimit")
    local detachingTransMaxLimit = xmlFile:getValue(key .. ".translation#detachingTransMaxLimit")
    local detachingTransMinLimit = xmlFile:getValue(key .. ".translation#detachingTransMinLimit")
    if availableValues ~= nil or (detachingRotMinLimit ~= nil or (detachingTransMaxLimit ~= nil or detachingTransMinLimit ~= nil)) then
        if spec.detachLockNodes == nil then
            spec.detachLockNodes = {}
        end
        spec.detachLockNodes[entry] = {
            ["detachingRotMaxLimit"] = availableValues,
            ["detachingRotMinLimit"] = detachingRotMinLimit,
            ["detachingTransMinLimit"] = detachingTransMinLimit,
            ["detachingTransMaxLimit"] = detachingTransMaxLimit
        }
    end
    entry.hasRequiredConfigurations = true
    local detachLock = xmlFile:getValue(key .. "#requiredConfigurationName")
    if detachLock ~= nil then
        local requiredConfigurationIndices = xmlFile:getValue(key .. "#requiredConfigurationIndices", nil, true)
        if requiredConfigurationIndices ~= nil then
            entry.hasRequiredConfigurations = false
            local i = 1
            for i = i, #requiredConfigurationIndices do
                if self.configurations[detachLock] == requiredConfigurationIndices[i] then
                    entry.hasRequiredConfigurations = true
                    break
                end
            end
        end
    end
    local requiredConfigurationIndices, ry, rz = getRotation(node)
    entry.curRot = { requiredConfigurationIndices, ry, rz }
    local i, y, z = getTranslation(node)
    entry.curTrans = { i, y, z }
    entry.startRot = xmlFile:getValue(key .. ".rotation#startRot")
    entry.startTrans = xmlFile:getValue(key .. ".translation#startTrans")
    entry.move = 0
    entry.moveToSend = 0
    entry.smoothedMove = 0
    entry.lastInputTime = 0
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#delayedIndex", key .. "#delayedNode")
    entry.delayedNode = xmlFile:getValue(key .. "#delayedNode", nil, self.components, self.i3dMappings)
    if entry.delayedNode ~= nil then
        entry.delayedFrames = xmlFile:getValue(key .. "#delayedFrames", 3)
        entry.currentDelayedData = {
            ["rot"] = { requiredConfigurationIndices, ry, rz },
            ["trans"] = { i, y, z }
        }
        entry.delayedHistroyData = {}
        local i = 1
        for i = i, entry.delayedFrames do
            entry.delayedHistroyData[i] = {
                ["rot"] = { requiredConfigurationIndices, ry, rz },
                ["trans"] = { i, y, z }
            }
        end
        entry.delayedHistoryIndex = 0
    end
    entry.networkInterpolators.translation = InterpolatorValue.new(entry.curTrans[entry.translationAxis])
    entry.networkInterpolators.translation:setMinMax(entry.transMin, entry.transMax)
    entry.networkInterpolators.rotation = InterpolatorAngle.new(entry.curRot[entry.rotationAxis])
    entry.networkInterpolators.rotation:setMinMax(entry.rotMin, entry.rotMax)
    entry.networkTimeInterpolator = InterpolationTime.new(1.2)
    entry.isTool = true
    return true
end
function Cylindered:loadDependentMovingTools(xmlFile, baseName, entry)
    entry.dependentMovingTools = {}
    local j = 0
    while true do
        local refBaseName = baseName .. string.format(".dependentMovingTool(%d)", j)
        if not xmlFile:hasProperty(refBaseName) then
            break
        end
        XMLUtil.checkDeprecatedXMLElements(xmlFile, refBaseName .. "#index", refBaseName .. "#index")
        local node = xmlFile:getValue(refBaseName .. "#node", nil, self.components, self.i3dMappings)
        local speedScale = xmlFile:getValue(refBaseName .. "#speedScale")
        local requiresMovement = xmlFile:getValue(refBaseName .. "#requiresMovement", false)
        local axis = xmlFile:getValue(refBaseName .. "#axis", 1)
        local rotationBasedLimits = AnimCurve.new(Cylindered.limitInterpolator)
        local found = false
        local i = 0
        while true do
            local key = string.format("%s.limit(%d)", refBaseName .. ".rotationBasedLimits", i)
            if not xmlFile:hasProperty(key) then
                break
            end
            local keyFrame = self:loadRotationBasedLimits(xmlFile, key, entry)
            if keyFrame ~= nil then
                rotationBasedLimits:addKeyframe(keyFrame)
                found = true
            end
            i = i + 1
        end
        if not found then
            rotationBasedLimits = nil
        end
        local key = xmlFile:getValue(refBaseName .. "#minTransLimits", nil, true)
        local keyFrame = xmlFile:getValue(refBaseName .. "#maxTransLimits", nil, true)
        local minRotLimits = xmlFile:getValue(refBaseName .. "#minRotLimits", nil, true)
        local maxRotLimits = xmlFile:getValue(refBaseName .. "#maxRotLimits", nil, true)
        if node ~= nil and (rotationBasedLimits ~= nil or (speedScale ~= nil or (key ~= nil or (keyFrame ~= nil or (minRotLimits ~= nil or maxRotLimits ~= nil))))) then
            table.insert(entry.dependentMovingTools, {
                ["node"] = node,
                ["axis"] = axis,
                ["rotation"] = { 0, 0, 0 },
                ["rotationBasedLimits"] = rotationBasedLimits,
                ["speedScale"] = speedScale,
                ["requiresMovement"] = requiresMovement,
                ["minTransLimits"] = key,
                ["maxTransLimits"] = keyFrame,
                ["minRotLimits"] = minRotLimits,
                ["maxRotLimits"] = maxRotLimits
            })
        end
        j = j + 1
    end
end
function Cylindered:loadDependentParts(xmlFile, baseName, entry)
    entry.dependentPartData = {}
    xmlFile:iterate(baseName .. ".dependentPart", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) self, (copy) entry
        XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")
        local dependentPart = {
            ["node"] = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        }
        if dependentPart.node ~= nil then
            dependentPart.maxUpdateDistance = xmlFile:getValue(key .. "#maxUpdateDistance", "-")
            if dependentPart.maxUpdateDistance == "-" then
                dependentPart.maxUpdateDistance = math.huge
            else
                dependentPart.maxUpdateDistance = tonumber(dependentPart.maxUpdateDistance)
            end
            dependentPart.part = nil
            table.insert(entry.dependentPartData, dependentPart)
        end
    end)
end
function Cylindered.resolveDependentPartData(_, dependentPartData, referenceNodes)
    for _, dependentPart in pairs(dependentPartData) do
        if dependentPart.part == nil and referenceNodes[dependentPart.node] ~= nil then
            local j = 1
            for j = j, #referenceNodes[dependentPart.node] do
                if j == 1 then
                    dependentPart.part = referenceNodes[dependentPart.node][j]
                    depPart.isDependentPart = true
                else
                    table.insert(dependentPartData, {
                        ["node"] = dependentPart.node,
                        ["maxUpdateDistance"] = dependentPart.maxUpdateDistance,
                        ["part"] = depPart
                    })
                    depPart.isDependentPart = true
                end
            end
        end
    end
    local j = #dependentPartData
    for j = j, 1, -1 do
        if dependentPartData[j].part == nil then
            table.remove(dependentPartData, j)
        end
    end
end
function Cylindered:loadDependentComponentJoints(xmlFile, baseName, entry)
    if self.isServer then
        entry.componentJoints = {}
        XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#componentJointIndex", baseName .. ".componentJoint#index")
        XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#anchorActor", baseName .. ".componentJoint#anchorActor")
        local i = 0
        while true do
            local key = baseName .. string.format(".componentJoint(%d)", i)
            if not xmlFile:hasProperty(key) then
                break
            end
            local index = xmlFile:getValue(key .. "#index")
            if index == nil or self.componentJoints[index] == nil then
                if not xmlFile:getValue(key .. "#ignoreWarning") then
                    Logging.xmlWarning(xmlFile, "Invalid index for \'%s\'", key)
                end
            else
                local anchorActor = xmlFile:getValue(key .. "#anchorActor", 0)
                local componentJoint = self.componentJoints[index]
                local jointEntry = {
                    ["componentJoint"] = componentJoint,
                    ["anchorActor"] = anchorActor,
                    ["index"] = index
                }
                local jointNode = componentJoint.jointNode
                if jointEntry.anchorActor == 1 then
                    jointNode = componentJoint.jointNodeActor1
                end
                local node = self.components[componentJoint.componentIndices[2]].node
                jointEntry.x, jointEntry.y, jointEntry.z = localToLocal(node, jointNode, 0, 0, 0)
                jointEntry.upX, jointEntry.upY, jointEntry.upZ = localDirectionToLocal(node, jointNode, 0, 1, 0)
                jointEntry.dirX, jointEntry.dirY, jointEntry.dirZ = localDirectionToLocal(node, jointNode, 0, 0, 1)
                table.insert(entry.componentJoints, jointEntry)
            end
            i = i + 1
        end
    end
end
function Cylindered:loadDependentAttacherJoints(xmlFile, baseName, entry)
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#jointIndices", baseName .. ".attacherJoint#jointIndices")
    local indices = xmlFile:getValue(baseName .. ".attacherJoint#jointIndices", nil, true)
    if indices ~= nil then
        local ignoreWarning = xmlFile:getValue(baseName .. ".attacherJoint#ignoreWarning", false)
        entry.attacherJoints = {}
        local availableAttacherJoints = nil
        if self.getAttacherJoints ~= nil then
            availableAttacherJoints = self:getAttacherJoints()
        end
        if availableAttacherJoints ~= nil then
            local i = 1
            for i = i, #indices do
                if availableAttacherJoints[indices[i]] == nil then
                    if not ignoreWarning then
                        Logging.xmlWarning(xmlFile, "Invalid attacher joint index \'%s\' for \'%s\'!", indices[i], baseName)
                    end
                else
                    table.insert(entry.attacherJoints, availableAttacherJoints[indices[i]])
                end
            end
        end
    end
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#inputAttacherJoint", baseName .. ".inputAttacherJoint#value")
    entry.inputAttacherJoint = xmlFile:getValue(baseName .. ".inputAttacherJoint#value", false)
end
function Cylindered:loadDependentWheels(xmlFile, baseName, entry)
    if SpecializationUtil.hasSpecialization(Wheels, self.specializations) then
        local indices = xmlFile:getValue(baseName .. "#wheelIndices", nil, true)
        if indices ~= nil then
            entry.wheels = {}
            for _, wheelIndex in pairs(indices) do
                local wheel = self:getWheelFromWheelIndex(wheelIndex)
                if wheel == nil then
                    Logging.xmlWarning(xmlFile, "Invalid wheelIndex \'%s\' for \'%s\'!", wheelIndex, baseName)
                else
                    table.insert(entry.wheels, wheel)
                end
            end
        end
        local wheelNodesStr = xmlFile:getValue(baseName .. "#wheelNodes")
        if wheelNodesStr ~= nil and wheelNodesStr ~= "" then
            entry.wheels = entry.wheels or {}
            local wheelNodes = string.split(wheelNodesStr, " ")
            local wheelIndex = 1
            for wheelIndex = wheelIndex, #wheelNodes do
                local wheel = self:getWheelByWheelNode(wheelNodes[wheelIndex])
                if wheel == nil then
                    Logging.xmlWarning(xmlFile, "Invalid wheelNode \'%s\' for \'%s\'!", wheelNodes[wheelIndex], baseName)
                else
                    table.insert(entry.wheels, wheel)
                end
            end
        end
    end
end
function Cylindered:loadDependentTranslatingParts(xmlFile, baseName, entry)
    entry.translatingParts = {}
    if entry.hasReferencePoints then
        entry.divideTranslatingDistance = xmlFile:getValue(baseName .. "#divideTranslatingDistance", true)
        entry.translatingPartsDivider = 0
        local j = 0
        while true do
            local refBaseName = baseName .. string.format(".translatingPart(%d)", j)
            if not xmlFile:hasProperty(refBaseName) then
                break
            end
            XMLUtil.checkDeprecatedXMLElements(xmlFile, refBaseName .. "#index", refBaseName .. "#node")
            local node = xmlFile:getValue(refBaseName .. "#node", nil, self.components, self.i3dMappings)
            if node ~= nil then
                local transEntry = {
                    ["node"] = node
                }
                local x, y, z = getTranslation(node)
                transEntry.startPos = { x, y, z }
                transEntry.lastZ = z
                local refZ
                if entry.referencePoint == nil then
                    local refZ = 0
                    for i, referencePoint in ipairs(entry.referencePoints) do
                        local _, _, z = worldToLocal(node, getWorldTranslation(referencePoint))
                    end
                    refZ = refZ / entry.numReferencePoints
                else
                    _, _, refZ = worldToLocal(node, getWorldTranslation(entry.referencePoint))
                end
                transEntry.referenceDistance = xmlFile:getValue(refBaseName .. "#referenceDistance", refZ)
                transEntry.minZTrans = xmlFile:getValue(refBaseName .. "#minZTrans")
                transEntry.maxZTrans = xmlFile:getValue(refBaseName .. "#maxZTrans")
                transEntry.divideTranslatingDistance = xmlFile:getValue(refBaseName .. "#divideTranslatingDistance", entry.divideTranslatingDistance)
                if transEntry.divideTranslatingDistance then
                    entry.translatingPartsDivider = entry.translatingPartsDivider + 1
                end
                table.insert(entry.translatingParts, transEntry)
            end
            j = j + 1
        end
        local node = entry.translatingPartsDivider
        entry.translatingPartsDivider = math.max(node, 1)
        entry.numTranslatingParts = #entry.translatingParts
    end
end
function Cylindered:loadExtraDependentParts(xmlFile, baseName, entry)
    return true
end
function Cylindered.loadDependentAnimations(_, xmlFile, baseName, entry)
    entry.dependentAnimations = {}
    local i = 0
    while true do
        local baseKey = string.format("%s.dependentAnimation(%d)", baseName, i)
        if not xmlFile:hasProperty(baseKey) then
            break
        end
        local animationName = xmlFile:getValue(baseKey .. "#name")
        if animationName ~= nil then
            local dependentAnimation = {
                ["name"] = animationName,
                ["lastPos"] = 0,
                ["translationAxis"] = xmlFile:getValue(baseKey .. "#translationAxis"),
                ["rotationAxis"] = xmlFile:getValue(baseKey .. "#rotationAxis"),
                ["node"] = entry.node
            }
            local useTranslatingPartIndex = xmlFile:getValue(baseKey .. "#useTranslatingPartIndex")
            if useTranslatingPartIndex ~= nil and entry.translatingParts[useTranslatingPartIndex] ~= nil then
                dependentAnimation.node = entry.translatingParts[useTranslatingPartIndex].node
            end
            dependentAnimation.minValue = xmlFile:getValue(baseKey .. "#minValue")
            dependentAnimation.maxValue = xmlFile:getValue(baseKey .. "#maxValue")
            if dependentAnimation.rotationAxis ~= nil then
                dependentAnimation.minValue = MathUtil.degToRad(dependentAnimation.minValue)
                dependentAnimation.maxValue = MathUtil.degToRad(dependentAnimation.maxValue)
            end
            dependentAnimation.invert = xmlFile:getValue(baseKey .. "#invert", false)
            table.insert(entry.dependentAnimations, dependentAnimation)
        end
        i = i + 1
    end
end
function Cylindered:loadCopyLocalDirectionParts(xmlFile, baseName, entry)
    entry.copyLocalDirectionParts = {}
    for _, copyLocalDirectionPartKey in xmlFile:iterator(baseName .. ".copyLocalDirectionPart") do
        XMLUtil.checkDeprecatedXMLElements(xmlFile, copyLocalDirectionPartKey .. "#index", copyLocalDirectionPartKey .. "#node")
        local node = xmlFile:getValue(copyLocalDirectionPartKey .. "#node", nil, self.components, self.i3dMappings)
        if node ~= nil then
            local copyLocalDirectionPart = {
                ["node"] = node,
                ["dirScale"] = xmlFile:getValue(copyLocalDirectionPartKey .. "#dirScale", nil, true),
                ["upScale"] = xmlFile:getValue(copyLocalDirectionPartKey .. "#upScale", nil, true)
            }
            if copyLocalDirectionPart.dirScale == nil then
                Logging.xmlWarning(xmlFile, "Missing values for \'%s\'", copyLocalDirectionPartKey .. "#dirScale")
            elseif copyLocalDirectionPart.upScale == nil then
                Logging.xmlWarning(xmlFile, "Missing values for \'%s\'", copyLocalDirectionPartKey .. "#upScale")
            else
                self:loadDependentComponentJoints(xmlFile, copyLocalDirectionPartKey, copyLocalDirectionPart)
                table.insert(entry.copyLocalDirectionParts, copyLocalDirectionPart)
            end
        end
    end
end
function Cylindered.loadRotationBasedLimits(_, xmlFile, key, tool)
    local rotation = xmlFile:getValue(key .. "#rotation")
    local rotMin = xmlFile:getValue(key .. "#rotMin")
    local rotMax = xmlFile:getValue(key .. "#rotMax")
    local transMin = xmlFile:getValue(key .. "#transMin")
    local transMax = xmlFile:getValue(key .. "#transMax")
    if rotation == nil or rotMin == nil and (rotMax == nil and (transMin == nil and transMax == nil)) then
        return nil
    end
    if tool.rotMin ~= nil and tool.rotMax ~= nil then
    end
    return {
        ["rotMin"] = rotMin,
        ["rotMax"] = rotMax,
        ["transMin"] = transMin,
        ["transMax"] = transMax,
        ["time"] = rotation
    }
end
function Cylindered:loadActionSoundsFromXML(xmlFile, key)
    local i = 0
    while true do
        local actionKey = string.format("actionSound(%d)", i)
        local baseKey = key .. "." .. actionKey
        if not xmlFile:hasProperty(baseKey) then
            break
        end
        local sample = g_soundManager:loadSampleFromXML(xmlFile, key, actionKey, self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        if sample ~= nil then
            local actionNamesStr = xmlFile:getValue(baseKey .. "#actionNames")
            local actionNames = string.split(actionNamesStr:trim(), " ")
            local nodesStr = xmlFile:getValue(baseKey .. "#nodes")
            local nodes = string.split(nodesStr, " ")
            local l = 1
            for l = l, #nodes do
                nodes[l] = I3DUtil.indexToObject(self.components, nodes[l], self.i3dMappings)
            end
            local l = 1
            for l = l, #actionNames do
                local actionName = actionNames[l]
                local actionName = "SOUND_ACTION_" .. string.upper(actionName)
                local action = Cylindered[actionName]
                if action == nil then
                    Logging.xmlWarning(xmlFile, "Unable to find sound action \'%s\' for sound \'%s\'", actionName, baseKey)
                else
                    local l = 1
                    for l = l, #nodes do
                        local node = nodes[l]
                        if node ~= nil then
                            if self.spec_cylindered.nodesToSamples[node] == nil then
                                spec.nodesToSamples[node] = {}
                            end
                            if spec.nodesToSamples[node][action] == nil then
                                spec.nodesToSamples[node][action] = {}
                            end
                            local part = self:getMovingPartByNode(node) or (self:getTranslatingPartByNode(node) or self:getMovingToolByNode(node))
                            if part == nil then
                                Logging.xmlWarning(xmlFile, "Unable to find movingPart or translatingPart for node \'%s\' in %s", getName(node), baseKey)
                            else
                                part.samplesByAction = spec.nodesToSamples[node]
                            end
                            table.insert(spec.nodesToSamples[node][action], sample)
                        end
                    end
                end
            end
            sample.dropOffFactor = xmlFile:getValue(baseKey .. ".pitch#dropOffFactor", 1)
            sample.dropOffTime = xmlFile:getValue(baseKey .. ".pitch#dropOffTime", 0) * 1000
            sample.actionNames = actionNames
            sample.nodes = nodes
            table.insert(spec.actionSamples, sample)
        end
        i = i + 1
    end
end
function Cylindered:checkMovingPartDirtyUpdateNode(node, movingPart) end
function Cylindered:setMovingToolDirty(node, forceUpdate, dt)
    local tool = self.spec_cylindered.nodesToMovingTools[node]
    if tool ~= nil then
        if tool.transSpeed ~= nil then
            local oldTrans = tool.curTrans[tool.translationAxis]
            local newTrans = tool.curTrans
            local diff = tool.curTrans
            newTrans[1], diff[2], tool.curTrans[3] = getTranslation(tool.node)
            local newTrans = tool.curTrans[tool.translationAxis]
            local diff = newTrans - oldTrans
            if math.abs(diff) > 0.0001 then
                self:updateMovingToolSoundEvents(tool, diff > 0, math.abs(newTrans - (tool.transMax or math.huge)) < 0.0001 or math.abs(newTrans - (tool.transMin or math.huge)) < 0.0001, math.abs(oldTrans - (tool.transMax or math.huge)) < 0.0001 or math.abs(oldTrans - (tool.transMin or math.huge)) < 0.0001)
            end
        end
        if tool.rotSpeed ~= nil then
            local oldTrans = tool.curRot[tool.rotationAxis]
            local newTrans = tool.curRot
            local diff = tool.curRot
            newTrans[1], diff[2], tool.curRot[3] = getRotation(tool.node)
            local newTrans = tool.curRot[tool.rotationAxis]
            local diff = newTrans - oldTrans
            if math.abs(diff) > 0.0001 then
                self:updateMovingToolSoundEvents(tool, diff > 0, math.abs(newTrans - (tool.rotMax or math.huge)) < 0.0001 or math.abs(newTrans - (tool.rotMin or math.huge)) < 0.0001, math.abs(oldTrans - (tool.rotMax or math.huge)) < 0.0001 or math.abs(oldTrans - (tool.rotMin or math.huge)) < 0.0001)
            end
        end
        Cylindered.setDirty(self, tool)
        if not self.isServer and self.isClient then
            tool.networkInterpolators.translation:setValue(tool.curTrans[tool.translationAxis])
            tool.networkInterpolators.rotation:setAngle(tool.curRot[tool.rotationAxis])
        end
        if forceUpdate or self.finishedFirstUpdate and not self.isActive then
            self:updateDirtyMovingParts(dt or g_currentDt, true)
        end
    end
end
function Cylindered:setMovingPartReferenceNode(movingPartNode, referenceNode, isActiveDirty)
    local movingPart = self:getMovingPartByNode(movingPartNode)
    if movingPart ~= nil then
        if movingPart.referencePointOrig == nil then
            movingPart.referencePointOrig = movingPart.referencePoint
        end
        if referenceNode ~= movingPart.referencePoint and movingPart.smoothedDirectionScale then
            movingPart.smoothedDirectionScaleAlpha = 0
            local dx, dy, dz = localDirectionToLocal(movingPart.node, getParent(movingPart.node), 0, 0, 1)
            local refX = movingPart.initialDirection
            local refY = movingPart.initialDirection
            local refZ = movingPart.initialDirection
            refX[1] = dx
            refY[2] = dy
            refZ[3] = dz
            if movingPart.hasReferencePoints and movingPart.numTranslatingParts > 0 then
                local refX, refY, refZ = getWorldTranslation(movingPart.referencePoint)
                _, _, movingPart.smoothedDirectionScaleZOffset = worldToLocal(movingPart.node, refX, refY, refZ)
            end
            if not movingPart.isActiveDirty then
                table.addElement(self.spec_cylindered.activeDirtyMovingParts, movingPart)
                movingPart.smoothedDirectionScaleTempDirty = true
            end
        end
        if referenceNode == nil then
            movingPart.referencePoint = movingPart.referencePointOrig
        else
            movingPart.referencePoint = referenceNode
        end
        if isActiveDirty ~= nil and not movingPart.smoothedDirectionScaleTempDirty then
            if isActiveDirty then
                table.addElement(spec.activeDirtyMovingParts, movingPart)
            elseif not movingPart.isActiveDirty then
                table.removeElement(spec.activeDirtyMovingParts, movingPart)
            end
        end
        Cylindered.updateMovingPart(self, movingPart, false, true, true)
        self:updateExtraDependentParts(movingPart, 99999)
        self:updateDependentAnimations(movingPart, 99999)
        for refX, refY in pairs(movingPart.dependentPartData) do
            if (refY.part.referencePointOrig or refY.part.referencePoint) == movingPart.referencePointOrig then
                self:setMovingPartReferenceNode(refY.part.node, referenceNode, isActiveDirty)
            end
        end
    end
end
function Cylindered:updateMovingPartByNode(movingPartNode, dt)
    local movingPart = self.spec_cylindered.nodesToMovingParts[movingPartNode]
    if movingPart ~= nil then
        Cylindered.updateMovingPart(self, movingPart, false, true, true)
        self:updateExtraDependentParts(movingPart, dt)
        self:updateDependentAnimations(movingPart, dt)
    end
end
function Cylindered:updateCylinderedInitial(placeComponents, keepDirty)
    placeComponents = placeComponents == nil and true or placeComponents
    if keepDirty == nil then
        keepDirty = false
    end
    local spec = self.spec_cylindered
    for _, part in pairs(spec.activeDirtyMovingParts) do
        Cylindered.setDirty(self, part)
    end
    for _, part in ipairs(spec.movingTools) do
        if part.isDirty then
            Cylindered.updateWheels(self, part)
            if self.isServer then
                Cylindered.updateComponentJoints(self, part, placeComponents)
            end
            part.isDirty = keepDirty
        end
        self:updateExtraDependentParts(part, 9999)
        self:updateDependentAnimations(part, 9999)
    end
    for _, part in ipairs(spec.movingParts) do
        local isActive = self:getIsMovingPartActive(part)
        if isActive or part.smoothedDirectionScale and part.smoothedDirectionScaleAlpha ~= 0 then
            if part.isDirty then
                Cylindered.updateMovingPart(self, part, placeComponents, nil, isActive, false)
                Cylindered.updateWheels(self, part)
                part.isDirty = keepDirty
            end
            self:updateExtraDependentParts(part, 9999)
            self:updateDependentAnimations(part, 9999)
        end
    end
end
function Cylindered:allowLoadMovingToolStates(superFunc)
    return true
end
function Cylindered:getMovingToolByNode(node)
    return self.spec_cylindered.nodesToMovingTools[node]
end
function Cylindered:getMovingPartByNode(node)
    return self.spec_cylindered.nodesToMovingParts[node]
end
function Cylindered:getTranslatingPartByNode(node)
    local spec = self.spec_cylindered
    local i = 1
    for i = i, #spec.movingParts do
        local part = spec.movingParts[i]
        if part.translatingParts ~= nil then
            local j = 1
            for j = j, part.numTranslatingParts do
                if part.translatingParts[j].node == node then
                    return part.translatingParts[j]
                end
            end
        end
    end
    return nil
end
function Cylindered.getIsMovingToolActive(_, movingTool)
    return movingTool.isActive and movingTool.hasRequiredConfigurations
end
function Cylindered.getIsMovingPartActive(_, movingPart)
    return movingPart.isActive
end
function Cylindered.getMovingToolMoveValue(_, movingTool)
    return movingTool.move + movingTool.externalMove
end
function Cylindered:isDetachAllowed(superFunc)
    local spec = self.spec_cylindered
    if spec.detachLockNodes ~= nil then
        for entry, data in pairs(spec.detachLockNodes) do
            local node = entry.node
            local rot = select(entry.rotationAxis, getRotation(node))
            if data.detachingRotMinLimit ~= nil and rot < data.detachingRotMinLimit then
                return false, nil
            end
            if data.detachingRotMaxLimit ~= nil and data.detachingRotMaxLimit < rot then
                return false, nil
            end
            local trans = select(entry.translationAxis, getTranslation(node))
            if data.detachingTransMinLimit ~= nil and trans < data.detachingTransMinLimit then
                return false, nil
            end
            if data.detachingTransMaxLimit ~= nil and data.detachingTransMaxLimit < trans then
                return false, nil
            end
        end
    end
    return superFunc(self)
end
function Cylindered:loadObjectChangeValuesFromXML(superFunc, xmlFile, key, node, object)
    superFunc(self, xmlFile, key, node, object)
    local spec = self.spec_cylindered
    if spec.nodesToMovingTools ~= nil and spec.nodesToMovingTools[node] ~= nil then
        local movingTool = spec.nodesToMovingTools[node]
        object.movingToolRotMaxActive = xmlFile:getValue(key .. "#movingToolRotMaxActive", (math.deg(movingTool.rotMax or 0)))
        object.movingToolRotMaxInactive = xmlFile:getValue(key .. "#movingToolRotMaxInactive", (math.deg(movingTool.rotMax or 0)))
        object.movingToolRotMinActive = xmlFile:getValue(key .. "#movingToolRotMinActive", (math.deg(movingTool.rotMin or 0)))
        object.movingToolRotMinInactive = xmlFile:getValue(key .. "#movingToolRotMinInactive", (math.deg(movingTool.rotMin or 0)))
        object.movingToolStartRotActive = xmlFile:getValue(key .. "#movingToolStartRotActive")
        object.movingToolStartRotInactive = xmlFile:getValue(key .. "#movingToolStartRotInactive")
        object.movingToolTransMaxActive = xmlFile:getValue(key .. "#movingToolTransMaxActive", movingTool.transMax)
        object.movingToolTransMaxInactive = xmlFile:getValue(key .. "#movingToolTransMaxInactive", movingTool.transMax)
        object.movingToolTransMinActive = xmlFile:getValue(key .. "#movingToolTransMinActive", movingTool.transMin)
        object.movingToolTransMinInactive = xmlFile:getValue(key .. "#movingToolTransMinInactive", movingTool.transMin)
        object.movingToolStartTransActive = xmlFile:getValue(key .. "#movingToolStartTransActive")
        object.movingToolStartTransInactive = xmlFile:getValue(key .. "#movingToolStartTransInactive")
    end
    ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "movingPartUpdate", nil, function(state)
        -- upvalues: (copy) self, (copy) node
        if self.getMovingPartByNode ~= nil then
            local movingPart = self:getMovingPartByNode(node)
            if movingPart ~= nil then
                movingPart.isActive = state
            end
        end
    end, false)
end
function Cylindered:setObjectChangeValues(superFunc, object, isActive)
    superFunc(self, object, isActive)
    local spec = self.spec_cylindered
    if spec.nodesToMovingTools ~= nil and spec.nodesToMovingTools[object.node] ~= nil then
        local movingTool = spec.nodesToMovingTools[object.node]
        if isActive then
            movingTool.rotMax = object.movingToolRotMaxActive
            movingTool.rotMin = object.movingToolRotMinActive
            movingTool.transMax = object.movingToolTransMaxActive
            movingTool.transMin = object.movingToolTransMinActive
            movingTool.startRot = object.movingToolStartRotActive or movingTool.startRot
            movingTool.startTrans = object.movingToolStartTransActive or movingTool.startTrans
            return
        end
        movingTool.rotMax = object.movingToolRotMaxInactive
        movingTool.rotMin = object.movingToolRotMinInactive
        movingTool.transMax = object.movingToolTransMaxInactive
        movingTool.transMin = object.movingToolTransMinInactive
        movingTool.startRot = object.movingToolStartRotInactive or movingTool.startRot
        movingTool.startTrans = object.movingToolStartTransInactive or movingTool.startTrans
    end
end
function Cylindered:loadDischargeNode(superFunc, xmlFile, key, entry)
    if not superFunc(self, xmlFile, key, entry) then
        return false
    end
    local baseKey = key .. ".movingToolActivation"
    if xmlFile:hasProperty(baseKey) then
        entry.movingToolActivation = {}
        entry.movingToolActivation.node = xmlFile:getValue(baseKey .. "#node", nil, self.components, self.i3dMappings)
        entry.movingToolActivation.isInverted = xmlFile:getValue(baseKey .. "#isInverted", false)
        entry.movingToolActivation.openFactor = xmlFile:getValue(baseKey .. "#openFactor", 1)
        entry.movingToolActivation.openOffset = xmlFile:getValue(baseKey .. "#openOffset", 0)
        entry.movingToolActivation.openOffsetInv = 1 - entry.movingToolActivation.openOffset
    end
    return true
end
function Cylindered:getDischargeNodeEmptyFactor(superFunc, dischargeNode)
    if dischargeNode.movingToolActivation == nil then
        return superFunc(self, dischargeNode)
    end
    local movingToolActivation = dischargeNode.movingToolActivation
    local currentSpeed = superFunc(self, dischargeNode)
    local speedFactor = Cylindered.getMovingToolState(self, self.spec_cylindered.nodesToMovingTools[movingToolActivation.node])
    local state = math.clamp(speedFactor, 0, 1)
    if movingToolActivation.isInverted then
        state = math.abs(state - 1)
    end
    return currentSpeed * math.clamp(math.max(state - movingToolActivation.openOffset, 0) / movingToolActivation.openOffsetInv / movingToolActivation.openFactor, 0, 1)
end
function Cylindered:loadShovelNode(superFunc, xmlFile, key, entry)
    if not superFunc(self, xmlFile, key, entry) then
        return false
    end
    local baseKey = key .. ".movingToolActivation"
    if not xmlFile:hasProperty(baseKey) then
        return true
    end
    entry.movingToolActivation = {}
    entry.movingToolActivation.node = xmlFile:getValue(baseKey .. "#node", nil, self.components, self.i3dMappings)
    entry.movingToolActivation.isInverted = xmlFile:getValue(baseKey .. "#isInverted", false)
    entry.movingToolActivation.openFactor = xmlFile:getValue(baseKey .. "#openFactor", 1)
    return true
end
function Cylindered:getShovelNodeIsActive(superFunc, shovelNode)
    local isActive = superFunc(self, shovelNode)
    if not isActive or shovelNode.movingToolActivation == nil then
        return isActive
    end
    local movingToolActivation = shovelNode.movingToolActivation
    local state = Cylindered.getMovingToolState(self, self.spec_cylindered.nodesToMovingTools[movingToolActivation.node])
    if movingToolActivation.isInverted then
        state = math.abs(state - 1)
    end
    return movingToolActivation.openFactor < state
end
function Cylindered:loadDynamicMountGrabFromXML(superFunc, xmlFile, key, entry)
    if not superFunc(self, xmlFile, key, entry) then
        return false
    end
    local baseKey = key .. ".movingToolActivation"
    if not xmlFile:hasProperty(baseKey) then
        return true
    end
    entry.movingToolActivation = {}
    entry.movingToolActivation.node = xmlFile:getValue(baseKey .. "#node", nil, self.components, self.i3dMappings)
    entry.movingToolActivation.isInverted = xmlFile:getValue(baseKey .. "#isInverted", false)
    entry.movingToolActivation.openFactor = xmlFile:getValue(baseKey .. "#openFactor", 1)
    return true
end
function Cylindered:getIsDynamicMountGrabOpened(superFunc, grab)
    local isActive = superFunc(self, grab)
    if not isActive or grab.movingToolActivation == nil then
        return isActive
    end
    local movingToolActivation = grab.movingToolActivation
    local state = Cylindered.getMovingToolState(self, self.spec_cylindered.nodesToMovingTools[movingToolActivation.node])
    if movingToolActivation.isInverted then
        state = math.abs(state - 1)
    end
    return movingToolActivation.openFactor < state
end
function Cylindered:setComponentJointFrame(superFunc, jointDesc, anchorActor)
    superFunc(self, jointDesc, anchorActor)
    for _, movingTool in ipairs(self.spec_cylindered.movingTools) do
        for _, componentJoint in ipairs(movingTool.componentJoints) do
            local componentJointDesc = self.componentJoints[componentJoint.index]
            local jointNode = componentJointDesc.jointNode
            if componentJoint.anchorActor == 1 then
                jointNode = componentJointDesc.jointNodeActor1
            end
            local node = self.components[componentJointDesc.componentIndices[2]].node
            componentJoint.x, componentJoint.y, componentJoint.z = localToLocal(node, jointNode, 0, 0, 0)
            componentJoint.upX, componentJoint.upY, componentJoint.upZ = localDirectionToLocal(node, jointNode, 0, 1, 0)
            componentJoint.dirX, componentJoint.dirY, componentJoint.dirZ = localDirectionToLocal(node, jointNode, 0, 0, 1)
        end
    end
end
function Cylindered:getAdditionalSchemaText(superFunc)
    local t = superFunc(self)
    if self.isClient and self:getIsActiveForInput(true) then
        local spec = self.spec_cylindered
        if #spec.controlGroupNames > 1 and spec.currentControlGroupIndex ~= 0 then
            t = tostring(spec.currentControlGroupIndex)
        end
    end
    return t
end
function Cylindered:getWearMultiplier(superFunc)
    local multiplier = superFunc(self)
    if self.spec_cylindered.isHydraulicSamplePlaying then
        multiplier = multiplier + self:getWorkWearMultiplier()
    end
    return multiplier
end
function Cylindered:getDoConsumePtoPower(superFunc)
    return superFunc(self) or self.spec_cylindered.powerConsumingTimer > 0
end
function Cylindered:getConsumingLoad(superFunc)
    local value, count = superFunc(self)
    local spec = self.spec_cylindered
    return value + math.max(spec.powerConsumingTimer / spec.powerConsumingActiveTimeOffset, 0), count + 1
end
function Cylindered:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_cylindered
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection then
            local i = 1
            for i = i, #spec.movingTools do
                local movingTool = spec.movingTools[i]
                local isSelectedGroup = true
                if movingTool.controlGroupIndex ~= 0 then
                    isSelectedGroup = movingTool.controlGroupIndex == spec.currentControlGroupIndex
                end
                local easyArmControlActive = g_gameSettings:getValue(GameSettings.SETTING.EASY_ARM_CONTROL)
                local canBeControlled = not (easyArmControlActive and movingTool.easyArmControlActive or easyArmControlActive)
                if canBeControlled then
                    canBeControlled = not movingTool.isEasyControlTarget
                end
                if movingTool.axisActionIndex ~= nil and (isSelectedGroup and canBeControlled) then
                    local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, movingTool.axisActionIndex, self, Cylindered.actionEventInput, true, false, true, true, i, movingTool.axisActionIcon)
                    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
                end
            end
        end
    end
end
function Cylindered:onPostAttach(_, _, _)
    for _, tool in ipairs(self.spec_cylindered.movingTools) do
        local changed = false
        if tool.transSpeed ~= nil then
            local trans = tool.curTrans[tool.translationAxis]
            local changedTrans = false
            if tool.attachTransMax == nil or tool.attachTransMax >= trans then
                if tool.attachTransMin ~= nil and trans < tool.attachTransMin then
                    trans = tool.attachTransMin
                    changedTrans = true
                end
            else
                trans = tool.attachTransMax
                changedTrans = true
            end
            if changedTrans then
                tool.curTrans[tool.translationAxis] = trans
                setTranslation(tool.node, unpack(tool.curTrans))
                changed = true
            end
        end
        if tool.rotSpeed ~= nil then
            local trans = tool.curRot[tool.rotationAxis]
            local changedTrans = false
            if tool.attachRotMax == nil or tool.attachRotMax >= trans then
                if tool.attachRotMin ~= nil and trans < tool.attachRotMin then
                    trans = tool.attachRotMin
                    changedTrans = true
                end
            else
                trans = tool.attachRotMax
                changedTrans = true
            end
            if changedTrans then
                tool.curRot[tool.rotationAxis] = trans
                setRotation(tool.node, unpack(tool.curRot))
                changed = true
            end
        end
        if changed then
            Cylindered.setDirty(self, tool)
        end
    end
end
function Cylindered:onSelect(subSelectionIndex)
    local spec = self.spec_cylindered
    local controlGroupIndex = spec.controlGroupMapping[subSelectionIndex]
    if controlGroupIndex == nil then
        spec.currentControlGroupIndex = 0
    else
        spec.currentControlGroupIndex = controlGroupIndex
    end
end
function Cylindered:onUnselect()
    self.spec_cylindered.currentControlGroupIndex = 0
end
function Cylindered:onDeactivate()
    if self.isClient then
        local spec = self.spec_cylindered
        g_soundManager:stopSample(spec.samples.hydraulic)
        spec.isHydraulicSamplePlaying = false
        for _, movingTool in ipairs(spec.movingTools) do
            movingTool.move = 0
            movingTool.externalMove = 0
        end
    end
end
function Cylindered:onAnimationPartChanged(node)
    self:setMovingToolDirty(node)
end
function Cylindered:onAIImplementStart()
    for _, movingTool in ipairs(self.spec_cylindered.movingTools) do
        if movingTool.aiActivePosition ~= nil then
            movingTool.curTargetPosition = movingTool.aiActivePosition
            movingTool.curTargetDirection = movingTool.curTargetPosition - Cylindered.getMovingToolState(self, movingTool)
        end
    end
end
function Cylindered:onVehicleSettingChanged(gameSettingId, state)
    if gameSettingId == GameSettings.SETTING.EASY_ARM_CONTROL then
        self:setIsEasyControlActive(state)
    end
end
function Cylindered:onRegisterAnimationValueTypes()
    self:registerAnimationValueType("movingPartReferencePoint", "", "", false, AnimationValueFloat, function(value, xmlFile, xmlKey)
        value.node = xmlFile:getValue(xmlKey .. "#node", nil, value.part.components, value.part.i3dMappings)
        value.startReferencePoint = xmlFile:getValue(xmlKey .. "#startReferencePoint", nil, value.part.components, value.part.i3dMappings)
        value.endReferencePoint = xmlFile:getValue(xmlKey .. "#endReferencePoint", nil, value.part.components, value.part.i3dMappings)
        if value.node == nil or (value.startReferencePoint == nil or value.endReferencePoint == nil) then
            return false
        end
        value:setWarningInformation("node: " .. getName(value.node))
        value:addCompareParameters("node")
        value.animatedReferencePoint = createTransformGroup("animatedReferencePoint_" .. getName(value.node))
        link(getParent(value.node), value.animatedReferencePoint)
        setWorldTranslation(value.animatedReferencePoint, getWorldTranslation(value.startReferencePoint))
        value.startValue = { 0 }
        value.endValue = { 1 }
        return true
    end, function(value)
        local startTime = value.startValue or value.endValue
        if value.animation.currentSpeed < 0 then
            startTime = value.endValue or value.startValue
        end
        return startTime[1]
    end, function(value, alpha)
        -- upvalues: (copy) self
        if value.movingPart == nil then
            value.movingPart = self:getMovingPartByNode(value.node)
        end
        local x1, y1, z1 = localToLocal(value.startReferencePoint, getParent(value.node), 0, 0, 0)
        local x2, y2, z2 = localToLocal(value.endReferencePoint, getParent(value.node), 0, 0, 0)
        local x, y, z = MathUtil.vector3Lerp(x1, y1, z1, x2, y2, z2, alpha)
        setTranslation(value.animatedReferencePoint, x, y, z)
        if value.movingPart ~= nil then
            if alpha == 1 then
                self:setMovingPartReferenceNode(value.movingPart, value.endReferencePoint)
                return
            end
            if alpha == 0 then
                self:setMovingPartReferenceNode(value.movingPart, value.startReferencePoint)
                return
            end
            self:setMovingPartReferenceNode(value.movingPart, value.animatedReferencePoint)
        end
    end)
end
function Cylindered:setToolTranslation(tool, transSpeed, dt, delta)
    local newTrans = tool.curTrans
    local diff = tool.curTrans
    newTrans[1], tool.curTrans[2], diff[3] = getTranslation(tool.node)
    local newTrans = tool.curTrans[tool.translationAxis]
    local newTrans
    if transSpeed == nil then
    end
    if tool.transMax ~= nil then
        newTrans = math.min(newTrans, tool.transMax)
    end
    if tool.transMin ~= nil then
        newTrans = math.max(newTrans, tool.transMin)
    end
    local diff = newTrans - newTrans
    if dt ~= 0 then
        tool.lastTransSpeed = diff / dt
    end
    if math.abs(diff) <= 0.0001 then
        return false
    end
    tool.curTrans[tool.translationAxis] = newTrans
    setTranslation(tool.node, tool.curTrans[1], tool.curTrans[2], tool.curTrans[3])
    self:updateMovingToolSoundEvents(tool, diff > 0, newTrans == tool.transMax or newTrans == tool.transMin, newTrans == tool.transMax or newTrans == tool.transMin)
    SpecializationUtil.raiseEvent(self, "onMovingToolChanged", tool, transSpeed, dt)
    return true
end
function Cylindered:setAbsoluteToolTranslation(tool, translation)
    tool.curTrans[1], tool.curTrans[2], tool.curTrans[3] = getTranslation(tool.node)
    if Cylindered.setToolTranslation(self, tool, nil, 0, translation - tool.curTrans[tool.translationAxis]) then
        Cylindered.setDirty(self, tool)
        self:raiseDirtyFlags(tool.dirtyFlag)
        self:raiseDirtyFlags(self.spec_cylindered.cylinderedDirtyFlag)
    end
end
function Cylindered:setToolRotation(tool, rotSpeed, dt, delta)
    local newRot = tool.curRot
    local diff = tool.curRot
    newRot[1], tool.curRot[2], diff[3] = getRotation(tool.node)
    local newRot = tool.curRot[tool.rotationAxis]
    local newRot
    if rotSpeed == nil then
    end
    if tool.rotMax ~= nil then
        newRot = math.min(newRot, tool.rotMax)
    end
    if tool.rotMin ~= nil then
        newRot = math.max(newRot, tool.rotMin)
    end
    local diff = newRot - tool.curRot[tool.rotationAxis]
    if rotSpeed ~= nil and dt ~= 0 then
        tool.lastRotSpeed = diff / dt
    end
    if math.abs(diff) <= 0.0001 then
        return false
    end
    if tool.rotMin == nil and tool.rotMax == nil then
        if newRot > 6.283185307179586 then
        end
        if newRot < 0 then
        end
    end
    tool.curRot[tool.rotationAxis] = newRot
    setRotation(tool.node, tool.curRot[1], tool.curRot[2], tool.curRot[3])
    self:updateMovingToolSoundEvents(tool, diff > 0, newRot == tool.rotMax or newRot == tool.rotMin, newRot == tool.rotMax or newRot == tool.rotMin)
    SpecializationUtil.raiseEvent(self, "onMovingToolChanged", tool, rotSpeed, dt)
    return true
end
function Cylindered:setAbsoluteToolRotation(tool, rotation, updateDelayedNodes)
    tool.curRot[1], tool.curRot[2], tool.curRot[3] = getRotation(tool.node)
    if Cylindered.setToolRotation(self, tool, nil, 0, rotation - tool.curRot[tool.rotationAxis]) then
        Cylindered.setDirty(self, tool)
        if updateDelayedNodes ~= nil and updateDelayedNodes then
            self:updateDelayedTool(tool)
        end
        self:raiseDirtyFlags(tool.dirtyFlag)
        self:raiseDirtyFlags(self.spec_cylindered.cylinderedDirtyFlag)
    end
end
function Cylindered:setToolAnimation(tool, animSpeed, dt)
    local curAnimTime = self:getAnimationTime(tool.animName)
    local oldAnimTime = curAnimTime - tool.curAnimTime
    if math.abs(oldAnimTime) > 0.001 then
        tool.networkInterpolators.resetAnimInterpolation = true
    end
    tool.curAnimTime = curAnimTime
    local newAnimTime = tool.curAnimTime + animSpeed * dt
    local oldAnimTime = tool.curAnimTime
    if tool.animMaxTime ~= nil then
        newAnimTime = math.min(newAnimTime, tool.animMaxTime)
    end
    if tool.animMinTime ~= nil then
        newAnimTime = math.max(newAnimTime, tool.animMinTime)
    end
    local diff = newAnimTime - tool.curAnimTime
    if dt ~= 0 then
        tool.lastAnimSpeed = diff / dt
    end
    if math.abs(diff) <= 0.0001 then
        return false
    end
    tool.curAnimTime = newAnimTime
    self:setAnimationTime(tool.animName, newAnimTime, nil, true)
    self:updateMovingToolSoundEvents(tool, diff > 0, newAnimTime == tool.animMaxTime or (newAnimTime == tool.animMinTime or (newAnimTime == 0 or newAnimTime == 1)), oldAnimTime == tool.animMaxTime or (oldAnimTime == tool.animMinTime or (oldAnimTime == 0 or oldAnimTime == 1)))
    SpecializationUtil.raiseEvent(self, "onMovingToolChanged", tool, animSpeed, dt)
    return true
end
function Cylindered:getMovingToolState(tool)
    if tool.rotMax == nil or tool.rotMin == nil then
        if tool.rotSpeed == nil then
            if tool.transMax == nil or tool.transMin == nil then
                if tool.transSpeed == nil then
                    if tool.animName == nil then
                        return 0
                    else
                        return self:getAnimationTime(tool.animName)
                    end
                else
                    return tool.curTrans[tool.translationAxis]
                end
            else
                return (tool.curTrans[tool.translationAxis] - tool.transMin) / (tool.transMax - tool.transMin)
            end
        else
            return tool.curRot[tool.rotationAxis]
        end
    else
        return (tool.curRot[tool.rotationAxis] - tool.rotMin) / (tool.rotMax - tool.rotMin)
    end
end
function Cylindered:setDirty(part)
    if not part.isDirty or self.spec_cylindered.isLoading then
        part.isDirty = true
        self.anyMovingPartsDirty = true
        if part.delayedNode ~= nil then
            self:setDelayedData(part)
        end
        if part.isTool then
            Cylindered.updateAttacherJoints(self, part)
            Cylindered.updateWheels(self, part)
        end
        for _, data in pairs(part.dependentPartData) do
            if self.currentUpdateDistance < data.maxUpdateDistance then
                Cylindered.setDirty(self, data.part)
            end
        end
    end
end
function Cylindered.updateWheels(_, part)
    if part.wheels ~= nil then
        for _, wheel in pairs(part.wheels) do
            wheel.physics:updateShapePosition()
            for _, wheelChock in ipairs(wheel.wheelChocks) do
                wheelChock:update()
            end
        end
    end
end
function Cylindered:updateMovingPart(part, placeComponents, updateDependentParts, isActive, updateSounds)
    local refX = nil
    local refY = nil
    local refZ = nil
    local dirX = 0
    local dirY = 0
    local dirZ = 0
    local changed = false
    local applyDirection = false
    if part.hasReferencePoints then
        if part.moveToReferenceFrame then
            local x, y, z = localToLocal(part.referenceFrame, getParent(part.node), part.referenceFrameOffset[1], part.referenceFrameOffset[2], part.referenceFrameOffset[3])
            setTranslation(part.node, x, y, z)
            changed = true
        end
        if part.referencePoint == nil then
            local refX = 0
            local refY = 0
            local refZ = 0
            for i, referencePoint in ipairs(part.referencePoints) do
                local x, y, z = getWorldTranslation(referencePoint)
            end
            refX = refX / part.numReferencePoints
            refY = refY / part.numReferencePoints
            refZ = refZ / part.numReferencePoints
        else
            refX, refY, refZ = getWorldTranslation(part.referencePoint)
        end
        if part.referenceDistance == 0 then
            if part.useLocalOffset then
                local x, y, z = worldToLocal(part.node, refX, refY, refZ)
                dirX, dirY, dirZ = localDirectionToWorld(part.node, x - part.localReferencePoint[1], y - part.localReferencePoint[2], z)
            elseif part.referencePointOffset == nil then
                local x, y, z = getWorldTranslation(part.node)
                dirX = refX - x
                dirY = refY - y
                dirZ = refZ - z
            else
                local y = part.referencePointOffset
                local x = math.abs(y)
                local z = part.referencePointOffset
                local y = math.sign(z)
                local z, i, referencePoint = getWorldTranslation(part.node)
                local x, y, z = localToLocal(part.node, part.referenceFrame, 0, 0, 0)
                local _, y2, z2 = localToLocal(part.referencePoint, part.referenceFrame, 0, 0, 0)
                local a = MathUtil.vector2Length(y2 - y, z2 - z)
                if x < a then
                    local b = math.sqrt(a ^ 2 - x ^ 2)
                    local tDirY, tDirZ = MathUtil.getDirectionFromYRotation(MathUtil.getYRotationFromDirection(y2 - y, z2 - z) + math.atan(x / b) * y)
                    refX, refY, refZ = localToWorld(part.referenceFrame, 0, y + tDirY * b, z + tDirZ * b)
                    dirX = refX - z
                    dirY = refY - i
                    dirZ = refZ - referencePoint
                end
            end
        else
            if part.updateLocalReferenceDistance then
                local x, y, z = worldToLocal(part.node, getWorldTranslation(part.localReferencePointNode))
                part.localReferenceDistance = MathUtil.vector2Length(y, z)
            end
            if part.referenceDistancePoint ~= nil then
                local x, y, z = worldToLocal(part.node, getWorldTranslation(part.referenceDistancePoint))
                part.referenceDistance = z
            end
            if part.localReferenceTranslate then
                local x, y, z = worldToLocal(part.node, refX, refY, refZ)
                if math.abs(y) < part.referenceDistance then
                    local referencePoint = part.referenceDistance * part.referenceDistance - y * y
                    local i = math.sqrt(referencePoint)
                    local referencePoint = z - i - part.localReferenceDistance
                    local x = z + i - part.localReferenceDistance
                    if math.abs(x) >= math.abs(referencePoint) then
                        x = referencePoint
                    end
                    local y = getParent(part.node)
                    local z, _, y2 = unpack(part.localReferenceTranslation)
                    local z2, a, b = localToLocal(y, part.node, z, _, y2)
                    local rotOffset, rot, tDirY = localDirectionToLocal(part.node, y, 0, 0, x - b)
                    setTranslation(part.node, z + rotOffset, _ + rot, y2 + tDirY)
                    changed = true
                end
            else
                local x = part.localReferenceDistance
                local y = part.referenceDistance
                if part.dynamicLocalReferenceDistance then
                    local z, i, referencePoint = worldToLocal(part.node, getWorldTranslation(part.localReferencePointNode))
                    local x, y, z = worldToLocal(part.node, localToWorld(part.localReferencePointNode, 0, 0, part.referenceDistance))
                    y = MathUtil.vector2Length(i - y, referencePoint - z)
                end
                local z, i, referencePoint = worldToLocal(part.node, refX, refY, refZ)
                local z, _, z, _ = MathUtil.getCircleCircleIntersection(0, 0, x, i, referencePoint, y)
                local y2 = true
                if part.referenceDistanceThreshold > 0 then
                    local z2, a, b = getWorldTranslation(part.localReferencePointNode)
                    local tDirY = MathUtil.vector3Length(refX - z2, refY - a, refZ - b) - part.referenceDistance
                    if math.abs(tDirY) < part.referenceDistanceThreshold then
                        y2 = false
                    end
                end
                if y2 and z ~= nil then
                    if z ~= nil then
                        local _ = z * (referencePoint - _) - _ * (i - z) < 0 == (part.localReferenceAngleSide < 0)
                    end
                    dirX, dirY, dirZ = localDirectionToWorld(part.node, 0, z, _)
                    changed = true
                end
            end
        end
        if part.doInversedLineAlignment then
            if part.doInversedLineAlignmentRoot == nil then
                part.doInversedLineAlignmentRoot = createTransformGroup("inversedLineAlignmentRoot")
                link(getParent(part.node), part.doInversedLineAlignmentRoot, getChildIndex(part.node))
                setTranslation(part.doInversedLineAlignmentRoot, getTranslation(part.node))
                setRotation(part.doInversedLineAlignmentRoot, getRotation(part.node))
                link(part.doInversedLineAlignmentRoot, part.node)
                setTranslation(part.node, 0, 0, 0)
                setRotation(part.node, 0, 0, 0)
            end
            local z = 1
            local x = #part.orientationLineNodes - 1
            local y = 1
            for z = z, x, y do
                local x, y, z = localToLocal(part.orientationLineNodes[z], part.node, 0, 0, 0)
                local _, y2, z2 = localToLocal(part.orientationLineNodes[z + 1], part.node, 0, 0, 0)
                local a = MathUtil.vector2Length(y, z)
                local b = MathUtil.vector2Length(y2, z2)
                local rotOffset, rot, tDirY = getWorldTranslation(part.doInversedLineAlignmentRoot)
                local tDirZ = MathUtil.vector3Length(refX - rotOffset, refY - rot, refZ - tDirY)
                if not MathUtil.getIsOutOfBounds(tDirZ, a, b) then
                    local ty = (tDirZ - a) / (b - a)
                    local tz = MathUtil.lerp(y, y2, ty)
                    local tz = MathUtil.lerp(z, z2, ty)
                    local upX, upY, upZ = localDirectionToWorld(part.referenceFrame, 0, 1, 0)
                    local x, y, z = localDirectionToWorld(part.doInversedLineAlignmentRoot, 0, -tz, tz)
                    I3DUtil.setWorldDirection(part.node, x, y, z, upX, upY, upZ, part.limitedAxis, part.minRot, part.maxRot)
                    local x, y, z = getWorldTranslation(part.doInversedLineAlignmentRoot)
                    I3DUtil.setWorldDirection(part.doInversedLineAlignmentRoot, refX - x, refY - y, refZ - z, upX, upY, upZ, part.limitedAxis, part.minRot, part.maxRot)
                    changed = true
                    break
                end
            end
        end
    else
        if part.alignToWorldY then
            local x, y, z = localDirectionToWorld(getRootNode(), 0, 1, 0)
            local x, y, z = worldDirectionToLocal(part.referenceFrame, x, y, z)
            if z < 0 then
            end
            dirX, dirY, dirZ = localDirectionToWorld(part.referenceFrame, x, y, z)
            changed = true
        elseif part.doDirectionAlignment then
            dirX, dirY, dirZ = localDirectionToWorld(part.referenceFrame, 0, 0, 1)
            changed = true
        end
        if part.moveToReferenceFrame then
            local x, y, z = localToLocal(part.referenceFrame, getParent(part.node), part.referenceFrameOffset[1], part.referenceFrameOffset[2], part.referenceFrameOffset[3])
            setTranslation(part.node, x, y, z)
            changed = true
        end
        if part.doLineAlignment then
            local x = false
            local i = 1
            local y = #part.orientationLineNodes - 1
            local z = 1
            for i = i, y, z do
                local x = part.orientationLineNodes[i + 1]
                local y, z, _ = localToLocal(part.orientationLineNodes[i], part.referenceFrame, 0, 0, 0)
                local y2, z2, a = localToLocal(x, part.referenceFrame, 0, 0, 0)
                local b, rotOffset, rot = localToLocal(part.node, part.referenceFrame, 0, 0, 0)
                local tDirY = part.partLength
                if part.partLengthNode ~= nil then
                    tDirY = calcDistanceFrom(part.node, part.partLengthNode)
                end
                local tDirZ, tz, upX, tz, upX = MathUtil.getCircleLineIntersection(rotOffset, rot, tDirY, z, _, z2, a)
                if tDirZ then
                    if tz == nil or upX == nil then
                        if tz == nil or upX == nil then
                            upX = nil
                            tz = nil
                        else
                            x = true
                        end
                    else
                        x = true
                    end
                    if x and not (MathUtil.isNan(tz) or MathUtil.isNan(upX)) then
                        dirX, dirY, dirZ = localDirectionToWorld(part.referenceFrame, 0, tz, upX)
                        changed = true
                        applyDirection = true
                        break
                    end
                end
            end
        end
        if part.do3DLineAlignment then
            local x = part.partLength
            if part.partLengthNode ~= nil then
                x = calcDistanceFrom(part.node, part.partLengthNode)
            end
            local i, referencePoint, x = getWorldTranslation(part.node)
            local y, z, _ = getWorldTranslation(part.orientationLineNodes[1])
            local y2, z2, a = getWorldTranslation(part.orientationLineNodes[2])
            local b = MathUtil.vector3Length(y - i, z - referencePoint, _ - x)
            local rotOffset = MathUtil.vector3Length(y2 - i, z2 - referencePoint, a - x)
            local tDirY = MathUtil.inverseLerp(b, rotOffset, x)
            local rot = math.clamp(tDirY, 0, 1)
            local tDirY, tDirZ, ty = MathUtil.vector3Lerp(y, z, _, y2, z2, a, rot)
            dirX, dirY, dirZ = MathUtil.vector3Normalize(tDirY - i, tDirZ - referencePoint, ty - x)
            setWorldTranslation(part.orientationLineTransNode, tDirY, tDirZ, ty)
            applyDirection = true
        end
    end
    local x = nil
    if part.smoothedDirectionScale then
        if part.smoothedDirectionScaleAlpha == nil then
            part.smoothedDirectionScaleAlpha = isActive and 1 or 0
        end
        local y = g_currentDt or 9999
        if isActive then
            part.smoothedDirectionScaleAlpha = math.min(part.smoothedDirectionScaleAlpha + y * part.smoothedDirectionTime, 1)
        else
            part.smoothedDirectionScaleAlpha = math.max(part.smoothedDirectionScaleAlpha - y * part.smoothedDirectionTime, 0)
        end
        local z = localDirectionToWorld
        local i = getParent(part.node)
        local x = part.initialDirection
        local z, i, referencePoint = z(i, unpack(x))
        dirX, dirY, dirZ = MathUtil.vector3Lerp(z, i, referencePoint, dirX, dirY, dirZ, part.smoothedDirectionScaleAlpha)
        if part.hasReferencePoints and part.numTranslatingParts > 0 then
            local y, z, _ = worldToLocal(part.node, refX, refY, refZ)
            x = MathUtil.lerp(part.smoothedDirectionScaleZOffset, _, part.smoothedDirectionScaleAlpha)
        end
        if part.smoothedDirectionScaleTempDirty and (part.smoothedDirectionScaleAlpha == 0 or part.smoothedDirectionScaleAlpha == 1) then
            table.removeElement(self.spec_cylindered.activeDirtyMovingParts, part)
            part.smoothedDirectionScaleTempDirty = false
        end
    end
    if not (part.doDirectionAlignment or applyDirection) or dirX == 0 and (dirY == 0 and dirZ == 0) then
        ::l97::
        if part.doRotationAlignment then
            local y, z, i = getRotation(part.referenceFrame)
            local y = y * part.rotMultiplier
            local z = z * part.rotMultiplier
            local i = i * part.rotMultiplier
            local referencePoint, x, y = getRotation(part.node)
            if math.abs(y - referencePoint) <= 0.0001 then
                if math.abs(z - x) <= 0.0001 then
                    if math.abs(i - y) <= 0.0001 then
                        goto l125
                    end
                end
            end
            setRotation(part.node, y, z, i)
            changed = true
        end
        ::l125::
        if not part.hasReferencePoints or part.numTranslatingParts <= 0 then
            ::l130::
            if changed then
                if part.copyLocalDirectionParts ~= nil then
                    for referencePoint, x in pairs(part.copyLocalDirectionParts) do
                        local y, z, _ = localDirectionToWorld(part.node, 0, 0, 1)
                        local y2, z2, a = worldDirectionToLocal(getParent(part.node), y, z, _)
                        local y2, z2, a = localDirectionToWorld(part.node, 0, 1, 0)
                        local b, rotOffset, rot = worldDirectionToLocal(getParent(part.node), y2, z2, a)
                        setDirection(x.node, y2 * x.dirScale[1], z2 * x.dirScale[2], a * x.dirScale[3], b * x.upScale[1], rotOffset * x.upScale[2], rot * x.upScale[3])
                        if self.isServer then
                            Cylindered.updateComponentJoints(self, x, placeComponents)
                        end
                    end
                end
                if self.isServer then
                    Cylindered.updateComponentJoints(self, part, placeComponents)
                    Cylindered.updateAttacherJoints(self, part)
                    Cylindered.updateWheels(self, part)
                end
                Cylindered.updateWheels(self, part)
                for referencePoint, x in pairs(part.dependentMovingTools) do
                    Cylindered.updateRotationBasedLimits(self, part, x)
                end
            end
            if updateDependentParts then
                for referencePoint, x in pairs(part.dependentPartData) do
                    if self.currentUpdateDistance < x.maxUpdateDistance then
                        local y = x.part
                        local z = self:getIsMovingPartActive(y)
                        if z or y.smoothedDirectionScale and y.smoothedDirectionScaleAlpha ~= 0 then
                            Cylindered.updateMovingPart(self, y, placeComponents, updateDependentParts, z)
                        end
                    end
                end
            end
            part.isDirty = false
            return
        end
        if x == nil then
            local z, i
            z, i, x = worldToLocal(part.node, refX, refY, refZ)
        end
        local i = 1
        local y = part.numTranslatingParts
        local z = 1
        for i = i, y, z do
            local referencePoint = part.translatingParts[i]
            local x = x - referencePoint.referenceDistance
            if part.translatingPartsDivider ~= 1 and referencePoint.divideTranslatingDistance then
            end
            if referencePoint.minZTrans ~= nil then
                x = math.max(referencePoint.minZTrans, x)
            end
            if referencePoint.maxZTrans ~= nil then
                x = math.min(referencePoint.maxZTrans, x)
            end
            if not referencePoint.divideTranslatingDistance then
            end
            if part.referenceDistanceThreshold == 0 then
                ::l145::
                if updateSounds ~= false and (part.samplesByAction ~= nil or referencePoint.samplesByAction ~= nil) and x ~= referencePoint.lastZ then
                    if math.abs(referencePoint.lastZ - x) > 0.0001 then
                        self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_END, Cylindered.SOUND_TYPE_ENDING)
                        self:onMovingPartSoundEvent(referencePoint, Cylindered.SOUND_ACTION_TRANSLATING_END, Cylindered.SOUND_TYPE_ENDING)
                        self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_START, Cylindered.SOUND_TYPE_STARTING)
                        self:onMovingPartSoundEvent(referencePoint, Cylindered.SOUND_ACTION_TRANSLATING_START, Cylindered.SOUND_TYPE_STARTING)
                        if referencePoint.lastZ + 0.0001 < x then
                            self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_POS, Cylindered.SOUND_TYPE_CONTINUES)
                            self:onMovingPartSoundEvent(referencePoint, Cylindered.SOUND_ACTION_TRANSLATING_POS, Cylindered.SOUND_TYPE_CONTINUES)
                            self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_END_POS, Cylindered.SOUND_TYPE_ENDING)
                            self:onMovingPartSoundEvent(referencePoint, Cylindered.SOUND_ACTION_TRANSLATING_END_POS, Cylindered.SOUND_TYPE_ENDING)
                            self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_START_POS, Cylindered.SOUND_TYPE_STARTING)
                            self:onMovingPartSoundEvent(referencePoint, Cylindered.SOUND_ACTION_TRANSLATING_START_POS, Cylindered.SOUND_TYPE_STARTING)
                        elseif x < referencePoint.lastZ - 0.0001 then
                            self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_NEG, Cylindered.SOUND_TYPE_CONTINUES)
                            self:onMovingPartSoundEvent(referencePoint, Cylindered.SOUND_ACTION_TRANSLATING_NEG, Cylindered.SOUND_TYPE_CONTINUES)
                            self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_END_NEG, Cylindered.SOUND_TYPE_ENDING)
                            self:onMovingPartSoundEvent(referencePoint, Cylindered.SOUND_ACTION_TRANSLATING_END_NEG, Cylindered.SOUND_TYPE_ENDING)
                            self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_START_NEG, Cylindered.SOUND_TYPE_STARTING)
                            self:onMovingPartSoundEvent(referencePoint, Cylindered.SOUND_ACTION_TRANSLATING_START_NEG, Cylindered.SOUND_TYPE_STARTING)
                        end
                    end
                end
                referencePoint.lastZ = x
                setTranslation(referencePoint.node, referencePoint.startPos[1], referencePoint.startPos[2], x)
                changed = true
            elseif math.abs(referencePoint.lastZ - x) > part.referenceDistanceThreshold then
                goto l145
            end
        end
        goto l130
    end
    local y, z, i = localDirectionToWorld(part.referenceFrame, 0, 1, 0)
    if part.invertZ then
    end
    local referencePoint = part.directionThresholdActive
    if not self.isActive and (part.directionThreshold ~= nil and part.directionThreshold > 0) then
        referencePoint = part.directionThreshold
    end
    local x, y, z = worldDirectionToLocal(part.parent, dirX, dirY, dirZ)
    local _ = part.lastDirection
    local y2 = part.lastUpVector
    local a = _[1] - x
    if referencePoint >= math.abs(a) then
        local a = _[2] - y
        if referencePoint >= math.abs(a) then
            local a = _[3] - z
            if referencePoint >= math.abs(a) then
                local a = y2[1] - y
                if referencePoint >= math.abs(a) then
                    local a = y2[2] - z
                    if referencePoint >= math.abs(a) then
                        if referencePoint >= math.abs(y2[3] - i) then
                            changed = false
                            goto l119
                        end
                    end
                end
            end
        end
    end
    I3DUtil.setWorldDirection(part.node, dirX, dirY, dirZ, y, z, i, part.limitedAxis, part.minRot, part.maxRot)
    if part.debug then
        local z2, a, b = getWorldTranslation(part.node)
        drawDebugPoint(z2, a, b, 1, 0, 0, 1, false)
        local rotOffset = 1
        if part.hasReferencePoints then
            local tDirY, tDirZ
            tDirY, tDirZ, rotOffset = worldToLocal(part.node, refX, refY, refZ)
        end
        local tDirY, tDirZ, ty = MathUtil.vector3Normalize(dirX, dirY, dirZ)
        drawDebugLine(z2, a, b, 1, 0, 0, z2 + tDirY * rotOffset, a + tDirZ * rotOffset, b + ty * rotOffset, 0, 1, 0, true)
        if part.referencePoint ~= nil then
            local tz, tz, upX = getWorldTranslation(part.referencePoint)
            drawDebugPoint(tz, tz, upX, 0, 1, 0, 1, false)
            drawDebugPoint(refX, refY, refZ, 0, 0, 1, 1, false)
        end
    end
    _[1] = x
    _[2] = y
    _[3] = z
    y2[1] = y
    y2[2] = z
    y2[3] = i
    changed = true
    ::l119::
    if part.scaleZ and (part.localReferenceDistance ~= nil and part.localReferenceDistance ~= 0) then
        local z2 = MathUtil.vector3Length(dirX, dirY, dirZ)
        setScale(part.node, 1, 1, z2 / part.localReferenceDistance)
        if part.debug then
            DebugGizmo.renderAtNode(part.node, string.format("scale:%.2f", z2 / part.localReferenceDistance))
        end
    end
    goto l97
end
function Cylindered:updateComponentJoints(entry, placeComponents)
    if self.isServer and entry.componentJoints ~= nil then
        for _, joint in ipairs(entry.componentJoints) do
            local componentJoint = joint.componentJoint
            local jointNode = componentJoint.jointNode
            if joint.anchorActor == 1 then
                jointNode = componentJoint.jointNodeActor1
            end
            if placeComponents then
                local node = self.components[componentJoint.componentIndices[2]].node
                local x, y, z = localToWorld(jointNode, joint.x, joint.y, joint.z)
                local upX, upY, upZ = localDirectionToWorld(jointNode, joint.upX, joint.upY, joint.upZ)
                local dirX, dirY, dirZ = localDirectionToWorld(jointNode, joint.dirX, joint.dirY, joint.dirZ)
                setWorldTranslation(node, x, y, z)
                I3DUtil.setWorldDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
            end
            self:setComponentJointFrame(componentJoint, joint.anchorActor)
        end
    end
end
function Cylindered:updateAttacherJoints(entry)
    if self.isServer then
        if entry.attacherJoints ~= nil then
            for _, joint in ipairs(entry.attacherJoints) do
                if joint.jointIndex ~= 0 then
                    setJointFrame(joint.jointIndex, 0, joint.jointTransform)
                end
            end
        end
        if entry.inputAttacherJoint and self.getAttacherVehicle ~= nil then
            local attacherVehicle = self:getAttacherVehicle()
            if attacherVehicle ~= nil then
                local attacherJoints = attacherVehicle:getAttacherJoints()
                if attacherJoints ~= nil then
                    local jointDescIndex = attacherVehicle:getAttacherJointIndexFromObject(self)
                    if jointDescIndex ~= nil then
                        local joint = self:getActiveInputAttacherJoint()
                        if joint ~= nil then
                            local ox, oy, oz = getTranslation(_.jointTransform)
                            setTranslation(_.jointTransform, unpack(_.jointOrigTrans))
                            local x, y, z = localToWorld(getParent(_.jointTransform), attacherJoints[jointDescIndex].jointOrigTrans[1] + attacherJoints[jointDescIndex].jointPositionOffset[1], _.jointOrigTrans[2] + _.jointPositionOffset[2], _.jointOrigTrans[3] + _.jointPositionOffset[3])
                            local x1, y1, z1 = worldToLocal(_.jointTransform, x, y, z)
                            setTranslation(_.jointTransform, ox, oy, oz)
                            local x2, y2, z2 = localToWorld(joint.node, x1, y1, z1)
                            local x2, y2, z2 = worldToLocal(getParent(joint.node), x2, y2, z2)
                            setTranslation(joint.node, x2, y2, z2)
                            setJointFrame(_.jointIndex, 1, joint.node)
                            setTranslation(joint.node, unpack(joint.jointOrigTrans))
                        end
                    end
                end
            end
        end
    end
end
function Cylindered.limitInterpolator(first, second, alpha)
    local rotMin = nil
    local rotMax = nil
    local transMin = nil
    local transMax = nil
    if first.rotMin ~= nil and second.rotMin ~= nil then
        rotMin = first.rotMin * alpha + second.rotMin * (1 - alpha)
    end
    if first.rotMax ~= nil and second.rotMax ~= nil then
        rotMax = first.rotMax * alpha + second.rotMax * oneMinusAlpha
    end
    if first.transMin ~= nil and second.transMin ~= nil then
        transMin = first.minTrans * alpha + second.transMin * oneMinusAlpha
    end
    if first.transMax ~= nil and second.transMax ~= nil then
        transMax = first.transMax * alpha + second.transMax * oneMinusAlpha
    end
    return rotMin, rotMax, transMin, transMax
end
function Cylindered:updateRotationBasedLimits(tool, dependentTool)
    if dependentTool.rotationBasedLimits ~= nil then
        local minRot
        if tool.isTool then
            minRot = Cylindered.getMovingToolState(self, tool)
        else
            dependentTool.rotation[1], dependentTool.rotation[2], dependentTool.rotation[3] = getRotation(tool.node)
        end
        local minRot, maxRot, minTrans, maxTrans = dependentTool.rotationBasedLimits:get(minRot)
        if minRot ~= nil then
            dependentTool.movingTool.rotMin = minRot
        end
        if maxRot ~= nil then
            dependentTool.movingTool.rotMax = maxRot
        end
        if minTrans ~= nil then
            dependentTool.movingTool.transMin = minTrans
        end
        if maxTrans ~= nil then
            dependentTool.movingTool.transMax = maxTrans
        end
        if self.isServer then
            local isDirty = false
            if minRot ~= nil or maxRot ~= nil then
                isDirty = isDirty or Cylindered.setToolRotation(self, dependentTool.movingTool, 0, 0)
            end
            if minTrans ~= nil or maxTrans ~= nil then
                isDirty = isDirty or Cylindered.setToolTranslation(self, dependentTool.movingTool, 0, 0)
            end
            if isDirty then
                Cylindered.setDirty(self, dependentTool.movingTool)
                self:raiseDirtyFlags(dependentTool.movingTool.dirtyFlag)
                self:raiseDirtyFlags(self.spec_cylindered.cylinderedDirtyFlag)
                return
            end
        elseif minRot ~= nil or maxRot ~= nil then
            dependentTool.movingTool.networkInterpolators.rotation:setMinMax(dependentTool.movingTool.rotMin, dependentTool.movingTool.rotMax)
        end
    end
end
function Cylindered:actionEventInput(_, inputValue, callbackState, _, isMouse)
    local spec = self.spec_cylindered
    local tool = spec.movingTools[callbackState]
    if tool ~= nil then
        tool.lastInputTime = g_time
        if tool.invertAxis then
            local move = -inputValue
        end
        local move = move * g_gameSettings:getValue(GameSettings.SETTING.VEHICLE_ARM_SENSITIVITY)
        if isMouse then
            move = move * 16.666 / g_currentDt * tool.mouseSpeedFactor
            if tool.moveLocked then
                if math.abs(inputValue) < 0.75 then
                    local checkOtherTools = math.abs(move)
                    if math.abs(tool.lockTool.move) * 2 < checkOtherTools then
                        tool.moveLocked = false
                    else
                        move = 0
                    end
                else
                    tool.moveLocked = false
                end
            else
                local function checkOtherTools(tools)
                    -- upvalues: (copy) callbackState, (ref) move, (copy) tool
                    for tool2Index, tool2 in ipairs(tools) do
                        if tool2Index ~= callbackState and (tool2.move ~= nil and tool2.move ~= 0) then
                            if math.abs(tool2.move) < math.abs(move) then
                                tool2.move = 0
                                tool2.moveToSend = 0
                                tool2.moveLocked = true
                                tool2.lockTool = tool
                            else
                                move = 0
                                tool.moveLocked = true
                                tool.lockTool = tool2
                            end
                        end
                    end
                end
                checkOtherTools(spec.movingTools)
                if self.getAttachedImplements ~= nil then
                    for _, implement in pairs(self:getAttachedImplements()) do
                        local vehicle = implement.object
                        if vehicle.spec_cylindered ~= nil then
                            checkOtherTools(vehicle.spec_cylindered.movingTools)
                        end
                    end
                end
            end
        end
        if move ~= tool.move then
            tool.move = move
        end
        if tool.move ~= tool.moveToSend then
            tool.moveToSend = tool.move
            self:raiseDirtyFlags(spec.cylinderedInputDirtyFlag)
        end
        tool.smoothedMove = tool.smoothedMove * 0.9 + move * 0.1
    end
end
function Cylindered:getMovingToolDashboardState(dashboard)
    local vehicle
    if dashboard.attacherJointNodes == nil then
        vehicle = self
    else
        if dashboard.attacherJointIndices == nil then
            dashboard.attacherJointIndices = {}
        end
        vehicle = self
        for _, node in ipairs(dashboard.attacherJointNodes) do
            local index = self:getAttacherJointIndexByNode(node)
            if index ~= nil then
                table.insert(dashboard.attacherJointIndices, index)
            end
        end
        dashboard.attacherJointNodes = nil
        if #dashboard.attacherJointIndices == 0 then
            dashboard.attacherJointIndices = nil
        end
    end
    if dashboard.attacherJointIndices ~= nil then
        vehicle = nil
        for _, node in ipairs(dashboard.attacherJointIndices) do
            local index = self:getImplementFromAttacherJointIndex(node)
            if index ~= nil then
                vehicle = index.object
                break
            end
        end
    end
    if vehicle ~= nil then
        local spec = vehicle.spec_cylindered
        if spec ~= nil then
            for node, index in ipairs(spec.movingTools) do
                if index.axis == dashboard.axis then
                    local isSelectedGroup = true
                    if index.controlGroupIndex ~= 0 then
                        isSelectedGroup = index.controlGroupIndex == spec.currentControlGroupIndex
                    end
                    local easyArmControlActive = false
                    if spec.easyArmControl ~= nil then
                        easyArmControlActive = spec.easyArmControl.state
                    end
                    local canBeControlled = not (easyArmControlActive and index.easyArmControlActive or easyArmControlActive)
                    if canBeControlled then
                        canBeControlled = not index.isEasyControlTarget
                    end
                    if isSelectedGroup and canBeControlled then
                        return (index.smoothedMove + 1) / 2
                    end
                end
            end
        end
    end
    return 0.5
end
function Cylindered:movingToolDashboardAttributes(xmlFile, key, dashboard, _, _)
    dashboard.axis = xmlFile:getValue(key .. "#axis")
    if dashboard.axis == nil then
        Logging.xmlWarning(xmlFile, "Misssing axis attribute for dashboard \'%s\'", key)
        return false
    end
    local attacherJointIndex = xmlFile:getValue(key .. "#attacherJointIndex")
    if attacherJointIndex ~= nil then
        dashboard.attacherJointIndices = {}
        table.insert(dashboard.attacherJointIndices, attacherJointIndex)
    end
    dashboard.attacherJointNode = xmlFile:getValue(key .. "#attacherJointNode", nil, self.components, self.i3dMappings)
    dashboard.attacherJointNodes = xmlFile:getValue(key .. "#attacherJointNodes", nil, self.components, self.i3dMappings, true)
    table.insert(dashboard.attacherJointNodes, dashboard.attacherJointNode)
    if #dashboard.attacherJointNodes == 0 then
        dashboard.attacherJointNodes = nil
    end
    return true
end