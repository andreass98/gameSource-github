source("dataS/scripts/vehicles/specializations/events/BaleWrapperStateEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BaleWrapperAutomaticDropEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BaleWrapperDropEvent.lua")
BaleWrapper = {}
BaleWrapper.CONSUMABLE_TYPE_NAME = "BALE_WRAP"
BaleWrapper.STATE_NONE = 0
BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER = 1
BaleWrapper.STATE_MOVING_GRABBER_TO_WORK = 2
BaleWrapper.STATE_WRAPPER_WRAPPING_BALE = 3
BaleWrapper.STATE_WRAPPER_FINSIHED = 4
BaleWrapper.STATE_WRAPPER_DROPPING_BALE = 5
BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM = 6
BaleWrapper.STATE_NUM_BITS = 3
BaleWrapper.CHANGE_GRAB_BALE = 1
BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER = 2
BaleWrapper.CHANGE_WRAPPING_START = 3
BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED = 4
BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE = 5
BaleWrapper.CHANGE_WRAPPER_BALE_DROPPED = 6
BaleWrapper.CHANGE_WRAPPER_PLATFORM_RESET = 7
BaleWrapper.CHANGE_BUTTON_EMPTY = 8
BaleWrapper.ANIMATION_NAMES = {
    "moveToWrapper",
    "wrapBale",
    "dropFromWrapper",
    "resetAfterDrop",
    "resetWrapping"
}
BaleWrapper.DROP_COLLISION_MASK = CollisionFlag.VEHICLE + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.PLAYER
BaleWrapper.BLOCK_COLLISION_MASK = CollisionFlag.VEHICLE + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.PLAYER
function BaleWrapper.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations) and SpecializationUtil.hasSpecialization(Consumable, specializations)
end
function BaleWrapper.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("wrappingColor", g_i18n:getText("configuration_wrappingColor"), nil, VehicleConfigurationItemColor)
    g_vehicleConfigurationManager:addConfigurationType("wrappingAnimation", g_i18n:getText("configuration_wrappingAnimation"), "baleWrapper", VehicleConfigurationItem)
    g_storeManager:addSpecType("baleWrapperBaleSizeRound", "shopListAttributeIconBaleWrapperBaleSizeRound", BaleWrapper.loadSpecValueBaleSizeRound, BaleWrapper.getSpecValueBaleSizeRound, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("baleWrapperBaleSizeSquare", "shopListAttributeIconBaleWrapperBaleSizeSquare", BaleWrapper.loadSpecValueBaleSizeSquare, BaleWrapper.getSpecValueBaleSizeSquare, StoreSpecies.VEHICLE)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("BaleWrapper")
    schema:register(XMLValueType.FLOAT, "vehicle.baleWrapper#foldMinLimit", "Fold min limit (Allow grabbing if folding is between these values)", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.baleWrapper#foldMaxLimit", "Fold max limit (Allow grabbing if folding is between these values)", 1)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.baleWrapper.grabber#node", "Grabber node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.baleWrapper.grabber#triggerNode", "Grabber trigger node")
    schema:register(XMLValueType.FLOAT, "vehicle.baleWrapper.grabber#nearestDistance", "Distance to bale to grab it", 3)
    schema:register(XMLValueType.BOOL, "vehicle.baleWrapper.automaticDrop#enabled", "Automatic drop", "true on mobile")
    schema:register(XMLValueType.BOOL, "vehicle.baleWrapper.automaticDrop#toggleable", "Automatic bale drop can be toggled", "false on mobile")
    schema:register(XMLValueType.L10N_STRING, "vehicle.baleWrapper.automaticDrop#textPos", "Positive toggle automatic drop text", "action_toggleAutomaticBaleDropPos")
    schema:register(XMLValueType.L10N_STRING, "vehicle.baleWrapper.automaticDrop#textNeg", "Negative toggle automatic drop text", "action_toggleAutomaticBaleDropNeg")
    BaleWrapper.registerWrapperXMLPaths(schema, "vehicle.baleWrapper.roundBaleWrapper")
    BaleWrapper.registerWrapperXMLPaths(schema, "vehicle.baleWrapper.squareBaleWrapper")
    local i = 1
    for i = i, #BaleWrapper.ANIMATION_NAMES do
        BaleWrapper.registerWrapperAnimationXMLPaths(schema, "vehicle.baleWrapper.wrappingAnimationConfigurations.wrappingAnimationConfiguration(?).roundBaleWrapper", BaleWrapper.ANIMATION_NAMES[i])
        BaleWrapper.registerWrapperAnimationXMLPaths(schema, "vehicle.baleWrapper.wrappingAnimationConfigurations.wrappingAnimationConfiguration(?).roundBaleWrapper.baleTypes.baleType(?)", BaleWrapper.ANIMATION_NAMES[i])
        BaleWrapper.registerWrapperAnimationXMLPaths(schema, "vehicle.baleWrapper.wrappingAnimationConfigurations.wrappingAnimationConfiguration(?).squareBaleWrapper", BaleWrapper.ANIMATION_NAMES[i])
        BaleWrapper.registerWrapperAnimationXMLPaths(schema, "vehicle.baleWrapper.wrappingAnimationConfigurations.wrappingAnimationConfiguration(?).squareBaleWrapper.baleTypes.baleType(?)", BaleWrapper.ANIMATION_NAMES[i])
    end
    schema:setXMLSpecializationType()
    Vehicle.xmlSchemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).baleWrapper#wrapperTime", "Bale wrapping time", 0)
    Bale.registerSavegameXMLPaths(schemaSavegame, "vehicles.vehicle(?).baleWrapper.bale")
end
function BaleWrapper.registerWrapperXMLPaths(schema, basePath)
    local i = 1
    for i = i, #BaleWrapper.ANIMATION_NAMES do
        BaleWrapper.registerWrapperAnimationXMLPaths(schema, basePath, BaleWrapper.ANIMATION_NAMES[i])
        BaleWrapper.registerWrapperAnimationXMLPaths(schema, basePath .. ".baleTypes.baleType(?)", BaleWrapper.ANIMATION_NAMES[i])
    end
    schema:register(XMLValueType.STRING, basePath .. ".baleTypes.baleType(?)#fillType", "Fill type name")
    schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?)#diameter", "Bale diameter", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?)#width", "Bale width", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?)#height", "Bale height", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?)#length", "Bale length", 0)
    schema:register(XMLValueType.STRING, basePath .. ".baleTypes.baleType(?).textures#diffuse", "Path to wrap diffuse map")
    schema:register(XMLValueType.STRING, basePath .. ".baleTypes.baleType(?).textures#normal", "Path to wrap normal map")
    schema:register(XMLValueType.BOOL, basePath .. ".baleTypes.baleType(?)#skipWrapping", "Bale is picked up, but not wrapped", false)
    schema:register(XMLValueType.BOOL, basePath .. ".baleTypes.baleType(?)#forceWhileFolding", "Force this bale type while wrapper is folded", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?)#wrapUsage", "Usage of wrap rolls per bale", 0.1)
    schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?).wrappingState.key(?)#time", "Time of wrapping (0-1)")
    schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?).wrappingState.key(?)#wrappingState", "Wrapping state for shader")
    schema:register(XMLValueType.STRING, basePath .. ".baleTypes.baleType(?).dropAnimations.dropAnimation(?)#name", "Drop animation name")
    schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?).dropAnimations.dropAnimation(?)#animSpeed", "Drop animation speed", 1)
    schema:register(XMLValueType.L10N_STRING, basePath .. ".baleTypes.baleType(?).dropAnimations.dropAnimation(?)#text", "Text to display in the input help")
    schema:register(XMLValueType.STRING, basePath .. ".baleTypes.baleType(?).dropAnimations.dropAnimation(?)#inputAction", "Name of input action")
    schema:register(XMLValueType.BOOL, basePath .. ".baleTypes.baleType(?).dropAnimations.dropAnimation(?)#liftOnDrop", "Lift the tools attacher joint while the bale is dropped", false)
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath .. ".baleTypes.baleType(?)")
    BaleWrapper.registerWrapperFoilAnimationXMLPaths(schema, basePath .. ".baleTypes.baleType(?)")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#baleNode", "Bale Node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#wrapperNode", "Wrapper Node")
    schema:register(XMLValueType.INT, basePath .. "#wrapperRotAxis", "Wrapper rotation axis", 2)
    schema:register(XMLValueType.FLOAT, basePath .. ".wrapperAnimation.key(?)#time", "Key time")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".wrapperAnimation.key(?)#baleRot", "Bale rotation")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".wrapperAnimation.key(?)#wrapperRot", "Wrapper rotation", "0 0 0")
    schema:register(XMLValueType.FLOAT, basePath .. "#wrappingTime", "Wrapping duration", 5)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".wrapAnimNodes.wrapAnimNode(?)#node", "Wrap node")
    schema:register(XMLValueType.BOOL, basePath .. ".wrapAnimNodes.wrapAnimNode(?)#repeatWrapperRot", "Repeat wrapper rotation, so wrapper rotation is always between 0 and 360", false)
    schema:register(XMLValueType.INT, basePath .. ".wrapAnimNodes.wrapAnimNode(?)#normalizeRotationOnBaleDrop", "Normalize rotation on bale drop", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".wrapAnimNodes.wrapAnimNode(?).key(?)#wrapperRot", "Wrapper rotation")
    schema:register(XMLValueType.FLOAT, basePath .. ".wrapAnimNodes.wrapAnimNode(?).key(?)#wrapperTime", "Wrapper time")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".wrapAnimNodes.wrapAnimNode(?).key(?)#trans", "Trans", "0 0 0")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".wrapAnimNodes.wrapAnimNode(?).key(?)#rot", "Rotation", "0 0 0")
    schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".wrapAnimNodes.wrapAnimNode(?).key(?)#scale", "Scale", "1 1 1")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".wrapNodes.wrapNode(?)#node", "Wrap node")
    schema:register(XMLValueType.BOOL, basePath .. ".wrapNodes.wrapNode(?)#wrapVisibility", "Visibility while wrapping", false)
    schema:register(XMLValueType.BOOL, basePath .. ".wrapNodes.wrapNode(?)#emptyVisibility", "Visibility while empty", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".wrapNodes.wrapNode(?)#maxWrapperRot", "Max. wrapper rotation")
    schema:register(XMLValueType.FLOAT, basePath .. ".wrappingState.key(?)#time", "Time of wrapping (0-1)")
    schema:register(XMLValueType.FLOAT, basePath .. ".wrappingState.key(?)#wrappingState", "Wrapping state for shader")
    schema:register(XMLValueType.FLOAT, basePath .. ".wrappingAnimationNodes#maxTime", "Max. time of animation nodes", "Wrapper anim time")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".wrappingAnimationNodes.key(?)#node", "Animation node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".wrappingAnimationNodes.key(?)#rootNode", "Reference node for rotation")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".wrappingAnimationNodes.key(?)#linkNode", "Node will be linked to this node while key is activated")
    schema:register(XMLValueType.FLOAT, basePath .. ".wrappingAnimationNodes.key(?)#time", "Time to activate key")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".wrappingAnimationNodes.key(?)#translation", "Translation of key")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".wrappingAnimationNodes#referenceNode", "Reference node")
    schema:register(XMLValueType.INT, basePath .. ".wrappingAnimationNodes#referenceAxis", "Reference axis", 1)
    schema:register(XMLValueType.ANGLE, basePath .. ".wrappingAnimationNodes#minRot", "Min. rotation", 0)
    schema:register(XMLValueType.ANGLE, basePath .. ".wrappingAnimationNodes#maxRot", "Max. rotation", 0)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".dropArea#node", "Node in the center of the drop area (if defined this area will be checked if something blocks this area)")
    schema:register(XMLValueType.FLOAT, basePath .. ".dropArea#width", "Width of area", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".dropArea#height", "Height of area", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".dropArea#length", "Length of area", 1)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".blockWrapArea#node", "Node in the center of the block area (if defined this area will be checked if it\'s clear to start the wrapping process)")
    schema:register(XMLValueType.FLOAT, basePath .. ".blockWrapArea#width", "Width of area", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".blockWrapArea#height", "Height of area", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".blockWrapArea#length", "Length of area", 1)
    BaleWrapper.registerWrapperFoilAnimationXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".wrappingCollisions.collision(?)#node", "Collision node")
    schema:register(XMLValueType.INT, basePath .. ".wrappingCollisions.collision(?)#activeCollisionMask", "Collision mask active")
    schema:register(XMLValueType.INT, basePath .. ".wrappingCollisions.collision(?)#inActiveCollisionMask", "Collision mask in active")
    schema:register(XMLValueType.L10N_STRING, basePath .. "#unloadBaleText", "Unload bale text", "\'action_unloadRoundBale\' for round bales and \'action_unloadSquareBale\' for square bales")
    schema:register(XMLValueType.BOOL, basePath .. "#skipUnsupportedBales", "Skip unsupported bales (pick them up and drop them instantly)")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "wrap(?)")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "start(?)")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "stop(?)")
    schema:register(XMLValueType.FLOAT, basePath .. ".sounds#wrappingEndTime", "Wrapping time to play end wrapping sound", 1)
end
function BaleWrapper.registerWrapperAnimationXMLPaths(schema, basePath, name)
    schema:register(XMLValueType.STRING, basePath .. ".animations." .. name .. "#animName", "Animation name", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".animations." .. name .. "#animSpeed", "Animation speed", 1)
    schema:register(XMLValueType.BOOL, basePath .. ".animations." .. name .. "#reverseAfterMove", "Reverse animation after playing", true)
    schema:register(XMLValueType.BOOL, basePath .. ".animations." .. name .. "#resetOnStart", "Reset animation on start", false)
end
function BaleWrapper.registerWrapperFoilAnimationXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".wrappingFoilAnimation#referenceNode", "Time reference node")
    schema:register(XMLValueType.INT, basePath .. ".wrappingFoilAnimation#referenceAxis", "Rotation axis")
    schema:register(XMLValueType.ANGLE, basePath .. ".wrappingFoilAnimation#minRot", "Min. reference rotation")
    schema:register(XMLValueType.ANGLE, basePath .. ".wrappingFoilAnimation#maxRot", "Max. reference rotation")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".wrappingFoilAnimation#clipNode", "Node which has clip assigned")
    schema:register(XMLValueType.STRING, basePath .. ".wrappingFoilAnimation#clipName", "Name of the clip to control")
end
function BaleWrapper.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadWrapperFromXML", BaleWrapper.loadWrapperFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadWrapperAnimationsFromXML", BaleWrapper.loadWrapperAnimationsFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadWrapperAnimCurveFromXML", BaleWrapper.loadWrapperAnimCurveFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadWrapperAnimNodesFromXML", BaleWrapper.loadWrapperAnimNodesFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadWrapperWrapNodesFromXML", BaleWrapper.loadWrapperWrapNodesFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadWrapperStateCurveFromXML", BaleWrapper.loadWrapperStateCurveFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadWrapperAnimationNodesFromXML", BaleWrapper.loadWrapperAnimationNodesFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadWrapperFoilAnimationFromXML", BaleWrapper.loadWrapperFoilAnimationFromXML)
    SpecializationUtil.registerFunction(vehicleType, "baleGrabberTriggerCallback", BaleWrapper.baleGrabberTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "allowsGrabbingBale", BaleWrapper.allowsGrabbingBale)
    SpecializationUtil.registerFunction(vehicleType, "pickupWrapperBale", BaleWrapper.pickupWrapperBale)
    SpecializationUtil.registerFunction(vehicleType, "getIsBaleWrappable", BaleWrapper.getIsBaleWrappable)
    SpecializationUtil.registerFunction(vehicleType, "getIsBaleDropAllowed", BaleWrapper.getIsBaleDropAllowed)
    SpecializationUtil.registerFunction(vehicleType, "onBaleWrapperDropOverlapCallback", BaleWrapper.onBaleWrapperDropOverlapCallback)
    SpecializationUtil.registerFunction(vehicleType, "getIsBaleWrappingAllowed", BaleWrapper.getIsBaleWrappingAllowed)
    SpecializationUtil.registerFunction(vehicleType, "onBaleWrapperBlockOverlapCallback", BaleWrapper.onBaleWrapperBlockOverlapCallback)
    SpecializationUtil.registerFunction(vehicleType, "updateWrappingState", BaleWrapper.updateWrappingState)
    SpecializationUtil.registerFunction(vehicleType, "doStateChange", BaleWrapper.doStateChange)
    SpecializationUtil.registerFunction(vehicleType, "updateWrapNodes", BaleWrapper.updateWrapNodes)
    SpecializationUtil.registerFunction(vehicleType, "playMoveToWrapper", BaleWrapper.playMoveToWrapper)
    SpecializationUtil.registerFunction(vehicleType, "setBaleWrapperType", BaleWrapper.setBaleWrapperType)
    SpecializationUtil.registerFunction(vehicleType, "getMatchingBaleTypeIndex", BaleWrapper.getMatchingBaleTypeIndex)
    SpecializationUtil.registerFunction(vehicleType, "setBaleWrapperAutomaticDrop", BaleWrapper.setBaleWrapperAutomaticDrop)
    SpecializationUtil.registerFunction(vehicleType, "setBaleWrapperDropAnimation", BaleWrapper.setBaleWrapperDropAnimation)
end
function BaleWrapper.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", BaleWrapper.getIsFoldAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", BaleWrapper.getCanBeSelected)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShowConsumableEmptyWarning", BaleWrapper.getShowConsumableEmptyWarning)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRequiresPower", BaleWrapper.getRequiresPower)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getStandaloneMotorTargetRpm", BaleWrapper.getStandaloneMotorTargetRpm)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getStandaloneMotorLoad", BaleWrapper.getStandaloneMotorLoad)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", BaleWrapper.addToPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", BaleWrapper.removeFromPhysics)
end
function BaleWrapper.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", BaleWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", BaleWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", BaleWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", BaleWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", BaleWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", BaleWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", BaleWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", BaleWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", BaleWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", BaleWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterExternalActionEvents", BaleWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", BaleWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", BaleWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onConsumableVariationChanged", BaleWrapper)
end
function BaleWrapper:onLoad(_)
    local spec = self.spec_baleWrapper
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wrapper", "vehicle.baleWrapper")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleGrabber", "vehicle.baleWrapper.grabber")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleWrapper.grabber#index", "vehicle.baleWrapper.grabber#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleWrapper.grabber#index", "vehicle.baleWrapper.grabber#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleWrapper.roundBaleWrapper#baleIndex", "vehicle.baleWrapper.roundBaleWrapper#baleNode")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleWrapper.roundBaleWrapper#wrapperIndex", "vehicle.baleWrapper.roundBaleWrapper#wrapperNode")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleWrapper.squareBaleWrapper#baleIndex", "vehicle.baleWrapper.squareBaleWrapper#baleNode")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleWrapper.squareBaleWrapper#wrapperIndex", "vehicle.baleWrapper.squareBaleWrapper#wrapperNode")
    spec.roundBaleWrapper = {}
    self:loadWrapperFromXML(spec.roundBaleWrapper, self.xmlFile, "vehicle.baleWrapper", "roundBaleWrapper")
    spec.squareBaleWrapper = {}
    self:loadWrapperFromXML(spec.squareBaleWrapper, self.xmlFile, "vehicle.baleWrapper", "squareBaleWrapper")
    spec.currentWrapper = {}
    spec.currentWrapperFoldMinLimit = self.xmlFile:getValue("vehicle.baleWrapper#foldMinLimit", 0)
    spec.currentWrapperFoldMaxLimit = self.xmlFile:getValue("vehicle.baleWrapper#foldMaxLimit", 1)
    spec.currentWrapper = spec.roundBaleWrapper
    self:updateWrapNodes(false, true, 0)
    spec.currentWrapper = spec.squareBaleWrapper
    self:updateWrapNodes(false, true, 0)
    spec.currentBaleTypeIndex = 1
    if spec.roundBaleWrapper.baleNode == nil then
        if spec.squareBaleWrapper.baleNode ~= nil then
            self:setBaleWrapperType(false, 1)
        end
    else
        self:setBaleWrapperType(true, 1)
    end
    spec.baleGrabber = {}
    spec.baleGrabber.grabNode = self.xmlFile:getValue("vehicle.baleWrapper.grabber#node", nil, self.components, self.i3dMappings)
    spec.baleGrabber.triggerNode = self.xmlFile:getValue("vehicle.baleWrapper.grabber#triggerNode", nil, self.components, self.i3dMappings)
    if spec.baleGrabber.triggerNode == nil then
        Logging.xmlWarning(self.xmlFile, "Missing bale grab trigger node \'%s\'. This is required for all bale wrappers.", "vehicle.baleWrapper.grabber#triggerNode")
    else
        addTrigger(spec.baleGrabber.triggerNode, "baleGrabberTriggerCallback", self)
    end
    spec.baleGrabber.nearestDistance = self.xmlFile:getValue("vehicle.baleWrapper.grabber#nearestDistance", 3)
    spec.baleGrabber.balesInTrigger = {}
    spec.baleToLoad = nil
    spec.baleToMount = nil
    spec.baleWrapperState = BaleWrapper.STATE_NONE
    spec.grabberIsMoving = false
    spec.hasBaleWrapper = true
    spec.wrapColor = { 1, 1, 1 }
    spec.showInvalidBaleWarning = false
    spec.baleDropBlockedWarning = nil
    spec.dropAnimationIndex = 1
    spec.foundDropOverlappingObject = false
    spec.foundDropOverlappingObjectTime = -math.huge
    spec.foundBlockOverlappingObject = false
    spec.automaticDrop = self.xmlFile:getValue("vehicle.baleWrapper.automaticDrop#enabled", Platform.gameplay.automaticBaleDrop)
    spec.toggleableAutomaticDrop = self.xmlFile:getValue("vehicle.baleWrapper.automaticDrop#toggleable", not Platform.gameplay.automaticBaleDrop)
    spec.toggleAutomaticDropTextPos = self.xmlFile:getValue("vehicle.baleWrapper.automaticDrop#textPos", "action_toggleAutomaticBaleDropPos", self.customEnvironment)
    spec.toggleAutomaticDropTextNeg = self.xmlFile:getValue("vehicle.baleWrapper.automaticDrop#textNeg", "action_toggleAutomaticBaleDropNeg", self.customEnvironment)
    spec.texts = {}
    spec.texts.warningFoldingWrapping = g_i18n:getText("warning_foldingNotWhileWrapping")
    spec.texts.warningBaleNotSupported = g_i18n:getText("warning_baleNotSupported")
    spec.texts.warningDropAreaBlocked = g_i18n:getText("warning_baleWrapperDropAreaBlocked")
end
function BaleWrapper:onPostLoad(savegame)
    if savegame ~= nil and not savegame.resetVehicles then
        local filename = savegame.xmlFile:getValue(savegame.key .. ".baleWrapper.bale#filename")
        if filename ~= nil then
            local baleToLoad = {
                ["filename"] = NetworkUtil.convertFromNetworkFilename(filename),
                ["wrapperTime"] = savegame.xmlFile:getValue(savegame.key .. ".baleWrapper#wrapperTime", 0),
                ["translation"] = { 0, 0, 0 },
                ["rotation"] = { 0, 0, 0 },
                ["attributes"] = {}
            }
            Bale.loadBaleAttributesFromXMLFile(baleToLoad.attributes, savegame.xmlFile, savegame.key .. ".baleWrapper.bale", savegame.resetVehicles)
            self.spec_baleWrapper.baleToLoad = baleToLoad
        end
    end
end
function BaleWrapper:loadWrapperFromXML(wrapper, xmlFile, baseKey, wrapperName)
    local spec = self.spec_baleWrapper
    isRoundBaleWrapper = wrapper == spec.roundBaleWrapper
    local wrappingAnimationConfig = Utils.getNoNil(self.configurations.wrappingAnimation, 1)
    local configKey = string.format("vehicle.baleWrapper.wrappingAnimationConfigurations.wrappingAnimationConfiguration(%d)", wrappingAnimationConfig - 1)
    self:loadWrapperAnimationsFromXML(wrapper, xmlFile, baseKey, configKey, "." .. wrapperName .. ".animations")
    wrapper.defaultAnimations = wrapper.animations
    baseKey = baseKey .. "." .. wrapperName
    wrapper.baleNode = xmlFile:getValue(baseKey .. "#baleNode", nil, self.components, self.i3dMappings)
    wrapper.wrapperNode = xmlFile:getValue(baseKey .. "#wrapperNode", nil, self.components, self.i3dMappings)
    wrapper.wrapperRotAxis = xmlFile:getValue(baseKey .. "#wrapperRotAxis", 2)
    wrapper.animTime = xmlFile:getValue(baseKey .. "#wrappingTime", 5) * 1000
    wrapper.currentTime = 0
    wrapper.currentBale = nil
    wrapper.allowedBaleTypes = {}
    local isRoundBaleWrapper
    xmlFile:iterate(baseKey .. ".baleTypes.baleType", function(index, key)
        -- upvalues: (copy) self, (copy) xmlFile, (copy) configKey, (copy) wrapperName, (copy) wrapper, (copy) spec, (copy) isRoundBaleWrapper
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#fillType")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#wrapperBaleFilename")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#minBaleDiameter", key .. "#diameter")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#maxBaleDiameter", key .. "#diameter")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#minBaleWidth", key .. "#width")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#maxBaleWidth", key .. "#width")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#minBaleHeight", key .. "#height")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#maxBaleHeight", key .. "#height")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#minBaleLength", key .. "#length")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#maxBaleLength", key .. "#length")
        local baleType = {
            ["diameter"] = MathUtil.round(xmlFile:getValue(key .. "#diameter", 0), 2),
            ["width"] = MathUtil.round(xmlFile:getValue(key .. "#width", 0), 2),
            ["height"] = MathUtil.round(xmlFile:getValue(key .. "#height", 0), 2),
            ["length"] = MathUtil.round(xmlFile:getValue(key .. "#length", 0), 2),
            ["wrapDiffuse"] = xmlFile:getValue(key .. ".textures#diffuse")
        }
        if baleType.wrapDiffuse ~= nil then
            baleType.wrapDiffuse = Utils.getFilename(baleType.wrapDiffuse, self.baseDirectory)
            if baleType.wrapDiffuse ~= nil and not textureFileExists(baleType.wrapDiffuse) then
                Logging.xmlWarning(self.xmlFile, "Bale wrap diffuse map \'%s\' does not exist.", baleType.wrapDiffuse)
                baleType.wrapDiffuse = nil
            end
        end
        baleType.wrapNormal = xmlFile:getValue(key .. ".textures#normal")
        if baleType.wrapNormal ~= nil then
            baleType.wrapNormal = Utils.getFilename(baleType.wrapNormal, self.baseDirectory)
            if baleType.wrapNormal ~= nil and not textureFileExists(baleType.wrapNormal) then
                Logging.xmlWarning(self.xmlFile, "Bale wrap normal map \'%s\' does not exist.", baleType.wrapNormal)
                baleType.wrapNormal = nil
            end
        end
        self:loadWrapperAnimationsFromXML(baleType, xmlFile, key, string.format("%s.%s.baleTypes.baleType(%d)", configKey, wrapperName, index - 1), ".animations", wrapper.animations)
        self:loadWrapperFoilAnimationFromXML(baleType, xmlFile, key)
        baleType.changeObjects = {}
        ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, key, baleType.changeObjects, self.components, self)
        baleType.skipWrapping = xmlFile:getValue(key .. "#skipWrapping", false)
        baleType.forceWhileFolding = xmlFile:getValue(key .. "#forceWhileFolding", false)
        if baleType.forceWhileFolding then
            spec.foldedBaleType = {
                ["isRoundBaleWrapper"] = isRoundBaleWrapper,
                ["baleTypeIndex"] = index
            }
        end
        baleType.wrapUsage = xmlFile:getValue(key .. "#wrapUsage", 0.1) / wrapper.animTime
        self:loadWrapperStateCurveFromXML(baleType, xmlFile, key)
        baleType.dropAnimations = {}
        for _, dropAnimationKey in self.xmlFile:iterator(key .. ".dropAnimations.dropAnimation") do
            local dropAnimation = {
                ["name"] = xmlFile:getValue(dropAnimationKey .. "#name"),
                ["animSpeed"] = xmlFile:getValue(dropAnimationKey .. "#animSpeed", 1),
                ["text"] = xmlFile:getValue(dropAnimationKey .. "#text", nil, self.customEnvironment, false),
                ["inputAction"] = xmlFile:getValue(dropAnimationKey .. "#inputAction")
            }
            if dropAnimation.inputAction ~= nil then
                dropAnimation.inputAction = InputAction[dropAnimation.inputAction]
            end
            dropAnimation.liftOnDrop = xmlFile:getValue(dropAnimationKey .. "#liftOnDrop", false)
            table.insert(baleType.dropAnimations, dropAnimation)
        end
        table.insert(wrapper.allowedBaleTypes, baleType)
    end)
    self:loadWrapperAnimCurveFromXML(wrapper, xmlFile, baseKey)
    self:loadWrapperAnimNodesFromXML(wrapper, xmlFile, baseKey)
    self:loadWrapperWrapNodesFromXML(wrapper, xmlFile, baseKey)
    self:loadWrapperStateCurveFromXML(wrapper, xmlFile, baseKey)
    self:loadWrapperAnimationNodesFromXML(wrapper, xmlFile, baseKey, wrapper.animTime)
    self:loadWrapperFoilAnimationFromXML(wrapper, xmlFile, baseKey, true)
    wrapper.wrappingFoilAnimationDefault = wrapper.wrappingFoilAnimation
    wrapper.dropArea = {}
    wrapper.dropArea.node = self.xmlFile:getValue(baseKey .. ".dropArea#node", nil, self.components, self.i3dMappings)
    wrapper.dropArea.width = self.xmlFile:getValue(baseKey .. ".dropArea#width", 1)
    wrapper.dropArea.height = self.xmlFile:getValue(baseKey .. ".dropArea#height", 1)
    wrapper.dropArea.length = self.xmlFile:getValue(baseKey .. ".dropArea#length", 1)
    wrapper.blockWrapArea = {}
    wrapper.blockWrapArea.node = self.xmlFile:getValue(baseKey .. ".blockWrapArea#node", nil, self.components, self.i3dMappings)
    wrapper.blockWrapArea.width = self.xmlFile:getValue(baseKey .. ".blockWrapArea#width", 1)
    wrapper.blockWrapArea.height = self.xmlFile:getValue(baseKey .. ".blockWrapArea#height", 1)
    wrapper.blockWrapArea.length = self.xmlFile:getValue(baseKey .. ".blockWrapArea#length", 1)
    wrapper.unloadBaleText = xmlFile:getValue(baseKey .. "#unloadBaleText", isRoundBaleWrapper and "action_unloadRoundBale" or "action_unloadSquareBale", self.customEnvironment)
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, baseKey .. "#skipWrappingFillTypes", baseKey .. "#skipUnsupportedBales")
    wrapper.skipUnsupportedBales = self.xmlFile:getValue(baseKey .. "#skipUnsupportedBales", false)
    if self.isClient then
        wrapper.samples = {}
        wrapper.samples.wrap = g_soundManager:loadSamplesFromXML(self.xmlFile, baseKey .. ".sounds", "wrap", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        wrapper.samples.start = g_soundManager:loadSamplesFromXML(self.xmlFile, baseKey .. ".sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        wrapper.samples.stop = g_soundManager:loadSamplesFromXML(self.xmlFile, baseKey .. ".sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        wrapper.wrappingSoundEndTime = xmlFile:getValue(baseKey .. ".sounds#wrappingEndTime", 1)
    end
end
function BaleWrapper:loadWrapperAnimationsFromXML(target, xmlFile, baseKey, configKey, animationsKey, parentAnimations)
    target.animations = {}
    if parentAnimations ~= nil then
        setmetatable(target.animations, {
            ["__index"] = parentAnimations
        })
    end
    local i = 1
    for i = i, #BaleWrapper.ANIMATION_NAMES do
        local animType = BaleWrapper.ANIMATION_NAMES[i]
        local configTypeKey = configKey .. animationsKey .. "." .. animType
        if not xmlFile:hasProperty(configTypeKey) then
            configTypeKey = baseKey .. animationsKey .. "." .. animType
        end
        local anim = {
            ["animName"] = xmlFile:getValue(configTypeKey .. "#animName"),
            ["animSpeed"] = xmlFile:getValue(configTypeKey .. "#animSpeed", 1),
            ["reverseAfterMove"] = xmlFile:getValue(configTypeKey .. "#reverseAfterMove", true)
        }
        if xmlFile:getValue(configTypeKey .. "#resetOnStart", false) then
            self:playAnimation(anim.animName, -1, 0.1, true)
            AnimatedVehicle.updateAnimationByName(self, anim.animName, 9999999, true)
        end
        if parentAnimations == nil or anim.animName ~= nil then
            target.animations[animType] = anim
        end
    end
end
function BaleWrapper.loadWrapperAnimCurveFromXML(_, target, xmlFile, baseKey)
    target.animCurve = AnimCurve.new(linearInterpolatorN)
    xmlFile:iterate(baseKey .. "wrapperAnimation.key", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) target
        local t = xmlFile:getValue(key .. "#time")
        local baleX, baleY, baleZ = xmlFile:getValue(key .. "#baleRot")
        if baleX == nil or (baleY == nil or baleZ == nil) then
            return false
        end
        local wrapperX, wrapperY, wrapperZ = xmlFile:getValue(key .. "#wrapperRot", "0 0 0")
        target.animCurve:addKeyframe({
            baleX,
            baleY,
            baleZ,
            wrapperX,
            wrapperY,
            wrapperZ,
            ["time"] = t
        })
    end)
end
function BaleWrapper:loadWrapperAnimNodesFromXML(target, xmlFile, baseKey)
    target.wrapAnimNodes = {}
    xmlFile:iterate(baseKey .. ".wrapAnimNodes.wrapAnimNode", function(_, key)
        -- upvalues: (copy) self, (copy) xmlFile, (copy) target
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#index", key .. "#node")
        local wrapAnimNode = {
            ["nodeId"] = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        }
        if wrapAnimNode.nodeId ~= nil then
            wrapAnimNode.useWrapperRot = false
            wrapAnimNode.animCurve = AnimCurve.new(linearInterpolatorN)
            local numKeyframes = 0
            xmlFile:iterate(key .. ".key", function(_, nodeKey)
                -- upvalues: (ref) xmlFile, (copy) wrapAnimNode, (ref) numKeyframes
                local wrapperRot = xmlFile:getValue(nodeKey .. "#wrapperRot")
                local wrapperTime = xmlFile:getValue(nodeKey .. "#wrapperTime")
                if wrapperRot == nil and wrapperTime == nil then
                    return false
                end
                local x = wrapAnimNode
                local y = wrapperRot ~= nil
                x.useWrapperRot = y
                local x, y, z = xmlFile:getValue(nodeKey .. "#trans", "0 0 0")
                local rx, ry, rz = xmlFile:getValue(nodeKey .. "#rot", "0 0 0")
                local sx, sy, sz = xmlFile:getValue(nodeKey .. "#scale", "1 1 1")
                if wrapperRot == nil then
                    wrapAnimNode.animCurve:addKeyframe({
                        x,
                        y,
                        z,
                        rx,
                        ry,
                        rz,
                        sx,
                        sy,
                        sz,
                        ["time"] = wrapperTime
                    })
                else
                    wrapAnimNode.animCurve:addKeyframe({
                        x,
                        y,
                        z,
                        rx,
                        ry,
                        rz,
                        sx,
                        sy,
                        sz,
                        ["time"] = math.rad(wrapperRot)
                    })
                end
            end)
            if numKeyframes > 0 then
                wrapAnimNode.repeatWrapperRot = xmlFile:getValue(key .. "#repeatWrapperRot", false)
                wrapAnimNode.normalizeRotationOnBaleDrop = xmlFile:getValue(key .. "#normalizeRotationOnBaleDrop", 0)
                table.insert(target.wrapAnimNodes, wrapAnimNode)
            end
        end
    end)
end
function BaleWrapper:loadWrapperWrapNodesFromXML(target, xmlFile, baseKey)
    target.wrapNodes = {}
    xmlFile:iterate(baseKey .. ".wrapNodes.wrapNode", function(_, key)
        -- upvalues: (copy) self, (copy) xmlFile, (copy) target
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#index", key .. "#node")
        local wrapNode = {
            ["nodeId"] = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings),
            ["wrapVisibility"] = xmlFile:getValue(key .. "#wrapVisibility", false),
            ["emptyVisibility"] = xmlFile:getValue(key .. "#emptyVisibility", false)
        }
        if wrapNode.nodeId ~= nil and (wrapNode.wrapVisibility or wrapNode.emptyVisibility) then
            wrapNode.maxWrapperRot = xmlFile:getValue(key .. "#maxWrapperRot", math.huge)
            table.insert(target.wrapNodes, wrapNode)
        end
    end)
end
function BaleWrapper.loadWrapperStateCurveFromXML(_, target, xmlFile, baseKey)
    target.wrappingStateCurve = AnimCurve.new(linearInterpolator1)
    xmlFile:iterate(baseKey .. ".wrappingState.key", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) target
        local t = xmlFile:getValue(key .. "#time")
        target.wrappingStateCurve:addKeyframe({
            xmlFile:getValue(key .. "#wrappingState"),
            ["time"] = t
        })
    end)
    if #target.wrappingStateCurve.keyframes == 0 then
        target.wrappingStateCurve = nil
    end
end
function BaleWrapper:loadWrapperAnimationNodesFromXML(target, xmlFile, baseKey, animTime)
    local maxTime = xmlFile:getValue(baseKey .. ".wrappingAnimationNodes#maxTime", animTime / 1000)
    target.wrappingAnimationNodes = {}
    target.wrappingAnimationNodes.nodes = {}
    target.wrappingAnimationNodes.nodeToRootNode = {}
    xmlFile:iterate(baseKey .. ".wrappingAnimationNodes.key", function(_, wrappingAnimationNodeKey)
        -- upvalues: (copy) xmlFile, (copy) self, (copy) maxTime, (copy) target
        local time = xmlFile:getValue(wrappingAnimationNodeKey .. "#time")
        local nodeId = xmlFile:getValue(wrappingAnimationNodeKey .. "#node", nil, self.components, self.i3dMappings)
        local rootNode = xmlFile:getValue(wrappingAnimationNodeKey .. "#rootNode", nil, self.components, self.i3dMappings)
        local linkNode = xmlFile:getValue(wrappingAnimationNodeKey .. "#linkNode", nil, self.components, self.i3dMappings)
        if time ~= nil and nodeId ~= nil then
            local entry = {
                ["time"] = time / maxTime,
                ["nodeId"] = nodeId,
                ["linkNode"] = linkNode,
                ["parent"] = getParent(nodeId),
                ["translation"] = xmlFile:getValue(wrappingAnimationNodeKey .. "#translation", nil, true)
            }
            if entry.translation == nil then
                Logging.xmlWarning(xmlFile, "Missing values for \'%s\'", wrappingAnimationNodeKey .. "#translation")
                return
            end
            if rootNode ~= nil then
                target.wrappingAnimationNodes.nodeToRootNode[nodeId] = rootNode
            end
            table.insert(target.wrappingAnimationNodes.nodes, entry)
        end
    end)
    local j = 1
    for j = j, #target.wrappingAnimationNodes.nodes do
        local wrappingAnimationNode = target.wrappingAnimationNodes.nodes[j]
        if wrappingAnimationNode.time == 0 then
            local x = setTranslation
            local y = wrappingAnimationNode.nodeId
            x(y, unpack(wrappingAnimationNode.translation))
            if wrappingAnimationNode.linkNode ~= nil then
                local x, y, z = localToWorld(wrappingAnimationNode.parent, unpack(wrappingAnimationNode.translation))
                link(wrappingAnimationNode.linkNode, wrappingAnimationNode.nodeId)
                setWorldTranslation(wrappingAnimationNode.nodeId, x, y, z)
            end
        end
    end
    target.wrappingAnimationNodes.referenceNode = xmlFile:getValue(baseKey .. ".wrappingAnimationNodes#referenceNode", nil, self.components, self.i3dMappings)
    target.wrappingAnimationNodes.referenceAxis = xmlFile:getValue(baseKey .. ".wrappingAnimationNodes#referenceAxis", 2)
    target.wrappingAnimationNodes.referenceMinRot = xmlFile:getValue(baseKey .. ".wrappingAnimationNodes#minRot", 0)
    target.wrappingAnimationNodes.referenceMaxRot = xmlFile:getValue(baseKey .. ".wrappingAnimationNodes#maxRot", 0)
    if target.wrappingAnimationNodes.referenceNode ~= nil then
        target.wrappingAnimationNodes.referenceNodeRotation = { getRotation(target.wrappingAnimationNodes.referenceNode) }
    end
    target.wrappingAnimationNodes.lastTime = -1
    target.wrappingAnimationNodes.currentIndex = 0
end
function BaleWrapper:loadWrapperFoilAnimationFromXML(target, xmlFile, baseKey, isDefault)
    local wrappingFoilAnimation = {
        ["referenceNode"] = xmlFile:getValue(baseKey .. ".wrappingFoilAnimation#referenceNode", nil, self.components, self.i3dMappings)
    }
    if wrappingFoilAnimation.referenceNode ~= nil then
        wrappingFoilAnimation.referenceAxis = xmlFile:getValue(baseKey .. ".wrappingFoilAnimation#referenceAxis", 2)
        wrappingFoilAnimation.referenceMinRot = xmlFile:getValue(baseKey .. ".wrappingFoilAnimation#minRot", 0)
        wrappingFoilAnimation.referenceMaxRot = xmlFile:getValue(baseKey .. ".wrappingFoilAnimation#maxRot", 0)
        wrappingFoilAnimation.referenceNodeRotation = { 0, 0, 0 }
        wrappingFoilAnimation.clipNode = xmlFile:getValue(baseKey .. ".wrappingFoilAnimation#clipNode", nil, self.components, self.i3dMappings)
        if wrappingFoilAnimation.clipNode ~= nil then
            wrappingFoilAnimation.animationClip = xmlFile:getValue(baseKey .. ".wrappingFoilAnimation#clipName")
            if wrappingFoilAnimation.animationClip == nil then
                Logging.xmlWarning(self.xmlFile, "Missing clipName for foil animation \'%s\'", baseKey .. ".wrappingFoilAnimation")
                return
            else
                wrappingFoilAnimation.animationCharSet = getAnimCharacterSet(wrappingFoilAnimation.clipNode)
                if wrappingFoilAnimation.animationCharSet == 0 then
                    Logging.xmlWarning(self.xmlFile, "Unable to find animation clip \'%s\' on node \'%s\' in \'%s\'", wrappingFoilAnimation.animationClip, getName(wrappingFoilAnimation.clipNode), baseKey .. ".wrappingFoilAnimation")
                    return
                else
                    wrappingFoilAnimation.animationClipIndex = getAnimClipIndex(wrappingFoilAnimation.animationCharSet, wrappingFoilAnimation.animationClip)
                    if wrappingFoilAnimation.animationClipIndex >= 0 then
                        wrappingFoilAnimation.animationClipDuration = getAnimClipDuration(wrappingFoilAnimation.animationCharSet, wrappingFoilAnimation.animationClipIndex)
                        if isDefault then
                            clearAnimTrackClip(wrappingFoilAnimation.animationCharSet, 0)
                            assignAnimTrackClip(wrappingFoilAnimation.animationCharSet, 0, wrappingFoilAnimation.animationClipIndex)
                            enableAnimTrack(wrappingFoilAnimation.animationCharSet, 0)
                            setAnimTrackTime(wrappingFoilAnimation.animationCharSet, 0, 0, true)
                            disableAnimTrack(wrappingFoilAnimation.animationCharSet, 0)
                        end
                        wrappingFoilAnimation.lastTime = 0
                        target.wrappingFoilAnimation = wrappingFoilAnimation
                    else
                        Logging.xmlWarning(self.xmlFile, "Unable to find animation clip \'%s\' on node \'%s\' in \'%s\'", wrappingFoilAnimation.animationClip, getName(wrappingFoilAnimation.clipNode), baseKey .. ".wrappingFoilAnimation")
                    end
                end
            end
        end
        Logging.xmlWarning(self.xmlFile, "Missing clipNode for foil animation \'%s\'", baseKey .. ".wrappingFoilAnimation")
    end
end
function BaleWrapper:onLoadFinished(_)
    local spec = self.spec_baleWrapper
    if spec.baleToLoad ~= nil then
        local v = spec.baleToLoad
        spec.baleToLoad = nil
        local baleObject = Bale.new(self.isServer, self.isClient)
        local x, y, z = unpack(v.translation)
        local rx, ry, rz = unpack(v.rotation)
        if baleObject:loadFromConfigXML(v.filename, x, y, z, rx, ry, rz, v.attributes.uniqueId) then
            baleObject:applyBaleAttributes(v.attributes)
            baleObject:register()
            if baleObject.nodeId ~= nil and baleObject.nodeId ~= 0 then
                self:doStateChange(BaleWrapper.CHANGE_GRAB_BALE, NetworkUtil.getObjectId(baleObject))
                self:doStateChange(BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER)
                self:doStateChange(BaleWrapper.CHANGE_WRAPPING_START)
                spec.currentWrapper.currentTime = v.wrapperTime
                local wrapAnimation = v.wrapperTime / spec.currentWrapper.animTime
                baleObject:setWrappingState((math.min(wrapAnimation, 1)))
                local wrapAnimation = spec.currentWrapper.animations.wrapBale
                local wrappingTime = spec.currentWrapper.currentTime / spec.currentWrapper.animTime
                self:updateWrappingState(wrappingTime)
                AnimatedVehicle.updateAnimations(self, 99999999, true)
                if wrappingTime < 1 then
                    self:setAnimationTime(wrapAnimation.animName, wrappingTime, true)
                    self:playAnimation(wrapAnimation.animName, wrapAnimation.animSpeed, wrappingTime, true)
                    return
                end
                self:doStateChange(BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED)
                self:setAnimationTime(wrapAnimation.animName, wrappingTime, true)
                spec.setWrappingStateFinished = false
            end
        end
    end
end
function BaleWrapper:onDelete()
    local spec = self.spec_baleWrapper
    local baleId = nil
    if spec.currentWrapper ~= nil and spec.currentWrapper.currentBale ~= nil then
        baleId = spec.currentWrapper.currentBale
    end
    if spec.baleGrabber ~= nil and spec.baleGrabber.currentBale ~= nil then
        baleId = spec.baleGrabber.currentBale
    end
    if baleId ~= nil then
        local bale = NetworkUtil.getObject(baleId)
        if bale ~= nil then
            if self.isServer then
                if self.isReconfigurating == nil or not self.isReconfigurating then
                    bale:unmountKinematic()
                    bale:setNeedsSaving(true)
                    bale:setCanBeSold(true)
                else
                    bale:delete()
                end
            else
                bale:unmountKinematic()
                bale:setNeedsSaving(true)
                bale:setCanBeSold(true)
            end
        end
    end
    if spec.baleGrabber ~= nil and spec.baleGrabber.triggerNode ~= nil then
        removeTrigger(spec.baleGrabber.triggerNode)
    end
    if spec.roundBaleWrapper ~= nil then
        g_soundManager:deleteSamples(spec.roundBaleWrapper.samples.wrap)
        g_soundManager:deleteSamples(spec.roundBaleWrapper.samples.start)
        g_soundManager:deleteSamples(spec.roundBaleWrapper.samples.stop)
    end
    if spec.squareBaleWrapper ~= nil then
        g_soundManager:deleteSamples(spec.squareBaleWrapper.samples.wrap)
        g_soundManager:deleteSamples(spec.squareBaleWrapper.samples.start)
        g_soundManager:deleteSamples(spec.squareBaleWrapper.samples.stop)
    end
end
function BaleWrapper:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_baleWrapper
    local baleServerId = spec.baleGrabber.currentBale
    if baleServerId == nil then
        baleServerId = spec.currentWrapper.currentBale
    end
    xmlFile:setValue(key .. "#wrapperTime", spec.currentWrapper.currentTime)
    if baleServerId ~= nil then
        local bale = NetworkUtil.getObject(baleServerId)
        if bale ~= nil then
            bale:saveToXMLFile(xmlFile, key .. ".bale")
        end
    end
end
function BaleWrapper:onReadStream(streamId, connection)
    if connection:getIsServer() then
        self:setBaleWrapperType(streamReadBool(streamId), (streamReadUIntN(streamId, 8)))
        local wrapperState = streamReadUIntN(streamId, BaleWrapper.STATE_NUM_BITS)
        if BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER <= wrapperState then
            local baleServerId = nil
            if wrapperState ~= BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM then
                baleServerId = NetworkUtil.readNodeObjectId(streamId)
            end
            if wrapperState == BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
                self:doStateChange(BaleWrapper.CHANGE_GRAB_BALE, baleServerId)
                AnimatedVehicle.updateAnimations(self, 99999999, true)
                return
            end
            if wrapperState == BaleWrapper.STATE_MOVING_GRABBER_TO_WORK then
                self.baleGrabber.currentBale = baleServerId
                self:doStateChange(BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER)
                AnimatedVehicle.updateAnimations(self, 99999999, true)
                return
            end
            if wrapperState == BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM then
                self.spec_baleWrapper.baleWrapperState = BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM
            else
                self:doStateChange(BaleWrapper.CHANGE_GRAB_BALE, baleServerId)
                AnimatedVehicle.updateAnimations(self, 99999999, true)
                spec.currentWrapper.currentBale = baleServerId
                self:doStateChange(BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER)
                AnimatedVehicle.updateAnimations(self, 99999999, true)
                self:updateWrapNodes(true, false, 0)
                if wrapperState == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE then
                    self:doStateChange(BaleWrapper.CHANGE_WRAPPING_START)
                    local wrapperTime = streamReadFloat32(streamId)
                    spec.currentWrapper.currentTime = wrapperTime
                    local wrapAnimation = spec.currentWrapper.animations.wrapBale
                    local wrappingTime = spec.currentWrapper.currentTime / spec.currentWrapper.animTime
                    self:setAnimationStopTime(wrapAnimation.animName, wrappingTime)
                    AnimatedVehicle.updateAnimationByName(self, wrapAnimation.animName, 9999999, true)
                    self:updateWrappingState(wrappingTime, true)
                    if wrappingTime < 1 then
                        self:playAnimation(wrapAnimation.animName, wrapAnimation.animSpeed, self:getAnimationTime(wrapAnimation.animName), true, false)
                        return
                    end
                else
                    local wrapperTime = spec.currentWrapper.animations.wrapBale
                    if wrapperTime.animName ~= nil then
                        self:playAnimation(wrapperTime.animName, wrapperTime.animSpeed, nil, true)
                        AnimatedVehicle.updateAnimationByName(self, wrapperTime.animName, 9999999, true)
                    end
                    spec.currentWrapper.currentTime = spec.currentWrapper.animTime
                    self:updateWrappingState(1, true)
                    self:doStateChange(BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED)
                    AnimatedVehicle.updateAnimations(self, 99999999, true)
                    if BaleWrapper.STATE_WRAPPER_DROPPING_BALE <= wrapperState then
                        self:doStateChange(BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE)
                        AnimatedVehicle.updateAnimations(self, 99999999, true)
                        return
                    end
                end
            end
        end
    end
end
function BaleWrapper:onWriteStream(streamId, connection)
    if not connection:getIsServer() then
        local spec = self.spec_baleWrapper
        local wrapperState = streamWriteBool
        wrapperState(streamId, spec.currentWrapper == spec.roundBaleWrapper)
        streamWriteUIntN(streamId, spec.currentBaleTypeIndex, 8)
        local wrapperState = spec.baleWrapperState
        streamWriteUIntN(streamId, wrapperState, BaleWrapper.STATE_NUM_BITS)
        if BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER <= wrapperState and wrapperState ~= BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM then
            if wrapperState == BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
                NetworkUtil.writeNodeObjectId(streamId, spec.baleGrabber.currentBale)
            else
                NetworkUtil.writeNodeObjectId(streamId, spec.currentWrapper.currentBale)
            end
        end
        if wrapperState == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE then
            streamWriteFloat32(streamId, spec.currentWrapper.currentTime)
        end
    end
end
function BaleWrapper:onUpdate(dt, _, _, _)
    local spec = self.spec_baleWrapper
    if spec.baleToMount ~= nil then
        local bale = NetworkUtil.getObject(spec.baleToMount.serverId)
        if bale ~= nil then
            local x, y, z = unpack(spec.baleToMount.trans)
            local rx, ry, rz = unpack(spec.baleToMount.rot)
            bale:mountKinematic(self, spec.baleToMount.linkNode, x, y, z, rx, ry, rz)
            bale:setCanBeSold(false)
            bale:setNeedsSaving(false)
            spec.baleToMount = nil
            if spec.baleWrapperState == BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
                self:playMoveToWrapper(bale)
            end
        end
    end
    if spec.baleWrapperState == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE then
        local bale = spec.currentWrapper
        self:updateConsumable(BaleWrapper.CONSUMABLE_TYPE_NAME, -bale.allowedBaleTypes[spec.currentBaleTypeIndex].wrapUsage * dt, true)
        bale.currentTime = math.min(bale.currentTime + dt, spec.currentWrapper.animTime)
        local y = bale.currentTime / bale.animTime
        self:updateWrappingState(y)
        self:raiseActive()
        if self.isClient then
            if bale.wrappingSoundEndTime <= y then
                if g_soundManager:getIsSamplePlaying(bale.samples.wrap[1]) then
                    g_soundManager:stopSamples(bale.samples.wrap)
                    g_soundManager:playSamples(bale.samples.stop)
                    return
                end
            elseif not g_soundManager:getIsSamplePlaying(bale.samples.wrap[1]) then
                g_soundManager:playSamples(bale.samples.wrap)
            end
        end
    end
end
function BaleWrapper:onUpdateTick(_, _, _, _)
    local spec = self.spec_baleWrapper
    spec.showInvalidBaleWarning = false
    spec.baleDropBlockedWarning = nil
    if self:allowsGrabbingBale() and (spec.baleGrabber.grabNode ~= nil and spec.baleGrabber.currentBale == nil) then
        local nearestBaleWrappable, nearestBale, nearestBaleTypeIndex = BaleWrapper.getBaleInRange(self, spec.baleGrabber.grabNode, spec.baleGrabber.nearestDistance)
        if nearestBale then
            if nearestBaleWrappable == nil and not (nearestBale.isRoundbale and spec.roundBaleWrapper.skipUnsupportedBales) and not spec.squareBaleWrapper.skipUnsupportedBales then
                if self.isClient and (nearestBale and spec.lastDroppedBaleId ~= NetworkUtil.getObjectId(nearestBale)) then
                    spec.showInvalidBaleWarning = true
                end
            elseif self.isServer then
                self:pickupWrapperBale(nearestBaleWrappable or nearestBale, nearestBaleTypeIndex)
            end
        end
    end
    if self.isServer and spec.baleWrapperState ~= BaleWrapper.STATE_NONE then
        if spec.baleWrapperState == BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
            if not self:getIsAnimationPlaying(spec.currentWrapper.animations.moveToWrapper.animName) then
                g_server:broadcastEvent(BaleWrapperStateEvent.new(self, BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER), true, nil, self)
            end
        elseif spec.baleWrapperState == BaleWrapper.STATE_MOVING_GRABBER_TO_WORK then
            if not self:getIsAnimationPlaying(spec.currentWrapper.animations.moveToWrapper.animName) then
                local nearestBaleWrappable = NetworkUtil.getObject(spec.currentWrapper.currentBale)
                if nearestBaleWrappable == nil or nearestBaleWrappable.supportsWrapping then
                    if self:getIsBaleWrappingAllowed() then
                        g_server:broadcastEvent(BaleWrapperStateEvent.new(self, BaleWrapper.CHANGE_WRAPPING_START), true, nil, self)
                    end
                else
                    g_server:broadcastEvent(BaleWrapperStateEvent.new(self, BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE), true, nil, self)
                end
            end
        elseif spec.baleWrapperState == BaleWrapper.STATE_WRAPPER_DROPPING_BALE then
            if not self:getIsAnimationPlaying(spec.currentWrapper.animations.dropFromWrapper.animName) then
                g_server:broadcastEvent(BaleWrapperStateEvent.new(self, BaleWrapper.CHANGE_WRAPPER_BALE_DROPPED), true, nil, self)
            end
        elseif spec.baleWrapperState == BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM and not self:getIsAnimationPlaying(spec.currentWrapper.animations.resetAfterDrop.animName) then
            g_server:broadcastEvent(BaleWrapperStateEvent.new(self, BaleWrapper.CHANGE_WRAPPER_PLATFORM_RESET), true, nil, self)
        end
    end
    if spec.automaticDrop or self:getIsAIActive() then
        local nearestBaleWrappable, nearestBale = self:getIsPowered()
        if nearestBaleWrappable and spec.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED then
            local nearestBaleTypeIndex, warning = self:getIsBaleDropAllowed()
            if nearestBaleTypeIndex then
                if self.isServer then
                    self:doStateChange(BaleWrapper.CHANGE_BUTTON_EMPTY)
                end
            elseif warning ~= nil then
                spec.baleDropBlockedWarning = warning
            end
        end
    end
    BaleWrapper.updateActionEvents(self)
    if spec.setWrappingStateFinished then
        g_server:broadcastEvent(BaleWrapperStateEvent.new(self, BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED), true, nil, self)
        spec.setWrappingStateFinished = false
    end
end
function BaleWrapper:onDraw(_, _, _)
    if self.isClient then
        local spec = self.spec_baleWrapper
        if spec.showInvalidBaleWarning then
            g_currentMission:showBlinkingWarning(spec.texts.warningBaleNotSupported, 500)
            return
        end
        if spec.baleDropBlockedWarning ~= nil then
            g_currentMission:showBlinkingWarning(spec.baleDropBlockedWarning, 500)
        end
    end
end
function BaleWrapper:baleGrabberTriggerCallback(_, otherId, onEnter, onLeave, _, _)
    if otherId ~= 0 and getRigidBodyType(otherId) == RigidBodyType.DYNAMIC then
        local object = g_currentMission:getNodeObject(otherId)
        if object ~= nil and object:isa(Bale) then
            local spec = self.spec_baleWrapper
            if onEnter then
                spec.baleGrabber.balesInTrigger[object] = Utils.getNoNil(spec.baleGrabber.balesInTrigger[object], 0) + 1
                return
            end
            if onLeave and spec.baleGrabber.balesInTrigger[object] ~= nil then
                spec.baleGrabber.balesInTrigger[object] = math.max(0, spec.baleGrabber.balesInTrigger[object] - 1)
                if spec.baleGrabber.balesInTrigger[object] == 0 then
                    spec.baleGrabber.balesInTrigger[object] = nil
                end
            end
        end
    end
end
function BaleWrapper:allowsGrabbingBale()
    local spec = self.spec_baleWrapper
    local specFoldable = self.spec_foldable
    if specFoldable ~= nil and (specFoldable.foldAnimTime ~= nil and (specFoldable.foldAnimTime > spec.currentWrapperFoldMaxLimit or specFoldable.foldAnimTime < spec.currentWrapperFoldMinLimit)) then
        return false
    end
    if spec.baleToLoad ~= nil then
        return false
    end
    return spec.baleWrapperState == BaleWrapper.STATE_NONE
end
function BaleWrapper:updateWrapNodes(isWrapping, isEmpty, t, wrapperRot)
    local spec = self.spec_baleWrapper
    wrapperRot = wrapperRot == nil and 0 or wrapperRot
    for _, wrapNode in pairs(spec.currentWrapper.wrapNodes) do
        local doShow = true
        if wrapNode.maxWrapperRot ~= nil then
            doShow = wrapperRot < wrapNode.maxWrapperRot
        end
        local z = not doShow or isWrapping and wrapNode.wrapVisibility
        if not z then
            z = isEmpty and wrapNode.emptyVisibility
        end
        setVisibility(wrapNode.nodeId, z)
    end
    if isWrapping then
        local wrapperRotRepeat = math.sign(wrapperRot) * (wrapperRot % 3.141592653589793)
        if wrapperRotRepeat < 0 then
        end
        for wrapNode, doShow in pairs(spec.currentWrapper.wrapAnimNodes) do
            local x, y, z, rx, ry, rz, sx, sy, sz
            if doShow.useWrapperRot then
                local rot
                if doShow.repeatWrapperRot then
                    rot = wrapperRotRepeat
                else
                    rot = wrapperRot
                end
                x, y, z, rx, ry, rz, sx, sy, sz = doShow.animCurve:get(rot)
            else
                x, y, z, rx, ry, rz, sx, sy, sz = doShow.animCurve:get(t)
            end
            if x ~= nil then
                setTranslation(doShow.nodeId, x, y, z)
                setRotation(doShow.nodeId, rx, ry, rz)
                setScale(doShow.nodeId, sx, sy, sz)
            end
        end
    elseif not isEmpty then
        for _, wrapNode in pairs(spec.currentWrapper.wrapAnimNodes) do
            if wrapNode.normalizeRotationOnBaleDrop ~= 0 then
                local doShow = { getRotation(wrapNode.nodeId) }
                local z = 1
                for z = z, 3 do
                    doShow[z] = wrapNode.normalizeRotationOnBaleDrop * math.sign(doShow[z]) * (doShow[z] % 6.283185307179586)
                end
                setRotation(wrapNode.nodeId, doShow[1], doShow[2], doShow[3])
            end
        end
    end
end
function BaleWrapper:updateWrappingState(wrappingTime, noEventSend)
    local spec = self.spec_baleWrapper
    local wrapper = spec.currentWrapper
    local foilTime = 0
    if wrapper.wrappingFoilAnimation ~= nil then
        local wrappingFoilAnimation = wrapper.wrappingFoilAnimation
        local i, wrappingAnimationNode, x = getRotation(wrappingFoilAnimation.referenceNode)
        wrappingFoilAnimation.referenceNodeRotation[1] = i
        wrappingFoilAnimation.referenceNodeRotation[2] = wrappingAnimationNode
        wrappingFoilAnimation.referenceNodeRotation[3] = x
        foilTime = (wrappingFoilAnimation.referenceNodeRotation[wrappingFoilAnimation.referenceAxis] - wrappingFoilAnimation.referenceMinRot) / (wrappingFoilAnimation.referenceMaxRot - wrappingFoilAnimation.referenceMinRot)
        if foilTime > 0 and (foilTime < 1 and foilTime ~= wrappingFoilAnimation.lastTime) then
            if getAnimTrackAssignedClip(wrappingFoilAnimation.animationCharSet, 0) ~= wrappingFoilAnimation.animationClipIndex then
                clearAnimTrackClip(wrappingFoilAnimation.animationCharSet, 0)
                assignAnimTrackClip(wrappingFoilAnimation.animationCharSet, 0, wrappingFoilAnimation.animationClipIndex)
            end
            enableAnimTrack(wrappingFoilAnimation.animationCharSet, 0)
            setAnimTrackTime(wrappingFoilAnimation.animationCharSet, 0, foilTime * wrappingFoilAnimation.animationClipDuration, true)
            disableAnimTrack(wrappingFoilAnimation.animationCharSet, 0)
            wrappingFoilAnimation.lastTime = foilTime
        end
    end
    local wrappingFoilAnimation = 0
    if wrapper.wrappingAnimationNodes.referenceNode ~= nil then
        local i, wrappingAnimationNode, x = getRotation(wrapper.wrappingAnimationNodes.referenceNode)
        wrapper.wrappingAnimationNodes.referenceNodeRotation[1] = i
        wrapper.wrappingAnimationNodes.referenceNodeRotation[2] = wrappingAnimationNode
        wrapper.wrappingAnimationNodes.referenceNodeRotation[3] = x
        wrappingFoilAnimation = MathUtil.round(math.clamp((wrapper.wrappingAnimationNodes.referenceNodeRotation[wrapper.wrappingAnimationNodes.referenceAxis] - wrapper.wrappingAnimationNodes.referenceMinRot) / (wrapper.wrappingAnimationNodes.referenceMaxRot - wrapper.wrappingAnimationNodes.referenceMinRot), 0, 1), 5)
    end
    if wrapper.wrappingAnimationNodes.lastTime < wrappingFoilAnimation then
        local rotation = wrapper.wrappingAnimationNodes.nodes
        local i = wrapper.wrappingAnimationNodes.currentIndex + 1
        for i = i, #rotation do
            local wrappingAnimationNode = rotation[i]
            if wrappingAnimationNode.time > wrappingFoilAnimation then
                break
            end
            if wrappingAnimationNode.linkNode == nil then
                if getParent(wrappingAnimationNode.nodeId) ~= wrappingAnimationNode.parent then
                    link(wrappingAnimationNode.parent, wrappingAnimationNode.nodeId)
                end
                setTranslation(wrappingAnimationNode.nodeId, unpack(wrappingAnimationNode.translation))
            else
                local x, y, z = localToWorld(wrappingAnimationNode.parent, unpack(wrappingAnimationNode.translation))
                if getParent(wrappingAnimationNode.nodeId) ~= wrappingAnimationNode.linkNode then
                    link(wrappingAnimationNode.linkNode, wrappingAnimationNode.nodeId)
                end
                setWorldTranslation(wrappingAnimationNode.nodeId, x, y, z)
            end
            wrapper.wrappingAnimationNodes.currentIndex = i
        end
    elseif wrappingFoilAnimation < wrapper.wrappingAnimationNodes.lastTime then
        wrapper.wrappingAnimationNodes.currentIndex = 0
    end
    wrapper.wrappingAnimationNodes.lastTime = wrappingFoilAnimation
    for i, wrappingAnimationNode in pairs(wrapper.wrappingAnimationNodes.nodeToRootNode) do
        local x, y, z = localRotationToLocal(wrappingAnimationNode, getParent(i), 0, 0, 0)
        setRotation(i, x, y, z)
    end
    local rotation = math.min(wrappingTime, 1)
    local oldClipIndex = 0
    if wrapper.animCurve ~= nil then
        local baleX, i, wrappingAnimationNode, x, y, z = wrapper.animCurve:get(wrappingTime)
        if baleX == nil then
            if wrapper.animations.wrapBale.animName ~= nil then
                wrappingTime = self:getAnimationTime(wrapper.animations.wrapBale.animName)
            end
        else
            setRotation(wrapper.baleNode, baleX % 6.283185307179586, i % 6.283185307179586, wrappingAnimationNode % 6.283185307179586)
            setRotation(wrapper.wrapperNode, x % 6.283185307179586, y % 6.283185307179586, z % 6.283185307179586)
            oldClipIndex = v[3 + wrapper.wrapperRotAxis]
        end
        if wrapper.wrappingAnimationNodes.referenceNode == nil then
            wrappingFoilAnimation = rotation
        end
        if wrapper.wrappingFoilAnimation == nil then
            foilTime = wrappingFoilAnimation
        end
        if wrapper.currentBale ~= nil then
            local bale = NetworkUtil.getObject(wrapper.currentBale)
            if bale ~= nil then
                local baleType = spec.currentWrapper.allowedBaleTypes[spec.currentBaleTypeIndex]
                if bale:getSupportsWrapping() and (not baleType.skipWrapping and bale.wrappingState < 1) then
                    local wrappingStateCurve = baleType.wrappingStateCurve or wrapper.wrappingStateCurve
                    if wrappingStateCurve ~= nil then
                        foilTime = wrappingStateCurve:get(foilTime)
                    end
                    bale:setWrappingState(foilTime, true)
                    if bale.setColor ~= nil then
                        bale:setColor(spec.wrapColor[1], spec.wrapColor[2], spec.wrapColor[3])
                    end
                end
            end
        end
    end
    local wrappingAnimationNode = wrappingTime > 0
    self:updateWrapNodes(wrappingAnimationNode, false, wrappingTime, oldClipIndex)
    if wrappingTime > 0.99999 and (self.isServer and (spec.baleWrapperState == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE and not noEventSend)) then
        g_server:broadcastEvent(BaleWrapperStateEvent.new(self, BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED), true, nil, self)
    end
end
function BaleWrapper:playMoveToWrapper(bale)
    local spec = self.spec_baleWrapper
    local baleTypeIndex = self:getMatchingBaleTypeIndex(bale.isRoundbale and spec.roundBaleWrapper.allowedBaleTypes or spec.squareBaleWrapper.allowedBaleTypes, bale)
    self:setBaleWrapperType(bale.isRoundbale, baleTypeIndex)
    if spec.currentWrapper.animations.moveToWrapper.animName ~= nil then
        self:playAnimation(spec.currentWrapper.animations.moveToWrapper.animName, spec.currentWrapper.animations.moveToWrapper.animSpeed, nil, true)
    end
end
function BaleWrapper:setBaleWrapperType(isRoundBaleWrapper, baleTypeIndex)
    local spec = self.spec_baleWrapper
    spec.currentWrapper = isRoundBaleWrapper and spec.roundBaleWrapper or spec.squareBaleWrapper
    spec.currentBaleTypeIndex = baleTypeIndex
    local baleType = spec.currentWrapper.allowedBaleTypes[baleTypeIndex]
    if baleType ~= nil then
        spec.currentWrapper.animations = baleType.animations
        spec.currentWrapper.wrappingFoilAnimation = baleType.wrappingFoilAnimation or spec.currentWrapper.wrappingFoilAnimationDefault
        ObjectChangeUtil.setObjectChanges(baleType.changeObjects, true, self, self.setMovingToolDirty)
        if spec.currentWrapper.wrappingFoilAnimation ~= nil then
            local wrappingFoilAnimation = spec.currentWrapper.wrappingFoilAnimation
            clearAnimTrackClip(wrappingFoilAnimation.animationCharSet, 0)
            assignAnimTrackClip(wrappingFoilAnimation.animationCharSet, 0, wrappingFoilAnimation.animationClipIndex)
            enableAnimTrack(wrappingFoilAnimation.animationCharSet, 0)
            setAnimTrackTime(wrappingFoilAnimation.animationCharSet, 0, 0, true)
            disableAnimTrack(wrappingFoilAnimation.animationCharSet, 0)
        end
    end
    self:requestActionEventUpdate()
end
function BaleWrapper.getMatchingBaleTypeIndex(_, baleTypes, bale)
    for i, baleType in ipairs(baleTypes) do
        if bale:getBaleMatchesSize(baleType.diameter, baleType.width, baleType.height, baleType.length) then
            return i
        end
    end
    return 1
end
function BaleWrapper:doStateChange(id, nearestBaleServerId)
    local spec = self.spec_baleWrapper
    if id == BaleWrapper.CHANGE_WRAPPING_START or spec.baleWrapperState ~= BaleWrapper.STATE_WRAPPER_FINSIHED and id == BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE then
        local skipWrapping = spec.currentWrapper.allowedBaleTypes[spec.currentBaleTypeIndex].skipWrapping
        local bale = NetworkUtil.getObject(spec.currentWrapper.currentBale)
        if bale == nil or bale:getSupportsWrapping() and bale.wrappingState ~= 1 then
            if bale == nil then
                Logging.devInfo("BaleWrapper:doStateChange (state: %d) - Bale not synced yet objectId %d", id, spec.currentWrapper.currentBale)
            end
        else
            skipWrapping = true
        end
        if skipWrapping then
            if self.isServer then
                spec.setWrappingStateFinished = true
            end
            return
        end
    end
    if id == BaleWrapper.CHANGE_GRAB_BALE then
        local baleType = NetworkUtil.getObject(nearestBaleServerId)
        spec.baleGrabber.currentBale = nearestBaleServerId
        if baleType == nil then
            spec.baleToMount = {
                ["serverId"] = nearestBaleServerId,
                ["linkNode"] = spec.baleGrabber.grabNode,
                ["trans"] = { 0, 0, 0 },
                ["rot"] = { 0, 0, 0 }
            }
        else
            local skipWrapping, bale, z = localToLocal(baleType.nodeId, getParent(spec.baleGrabber.grabNode), 0, 0, 0)
            setTranslation(spec.baleGrabber.grabNode, skipWrapping, bale, z)
            baleType:mountKinematic(self, spec.baleGrabber.grabNode, 0, 0, 0, 0, 0, 0)
            baleType:setCanBeSold(false)
            baleType:setNeedsSaving(false)
            spec.baleToMount = nil
            self:playMoveToWrapper(baleType)
        end
        spec.baleWrapperState = BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER
    elseif id == BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER then
        local skipWrapping = NetworkUtil.getObject(spec.baleGrabber.currentBale)
        if skipWrapping == nil then
            spec.baleToMount = {
                ["serverId"] = spec.baleGrabber.currentBale,
                ["linkNode"] = spec.currentWrapper.baleNode,
                ["trans"] = { 0, 0, 0 },
                ["rot"] = { 0, 0, 0 }
            }
        else
            skipWrapping:mountKinematic(self, baleType, 0, 0, 0, 0, 0, 0)
            skipWrapping:setCanBeSold(false)
            skipWrapping:setNeedsSaving(false)
            spec.baleToMount = nil
        end
        self:updateWrapNodes(true, false, 0)
        spec.currentWrapper.currentBale = spec.baleGrabber.currentBale
        spec.baleGrabber.currentBale = nil
        if spec.currentWrapper.animations.moveToWrapper.animName ~= nil and spec.currentWrapper.animations.moveToWrapper.reverseAfterMove then
            self:playAnimation(spec.currentWrapper.animations.moveToWrapper.animName, -spec.currentWrapper.animations.moveToWrapper.animSpeed, nil, true)
        end
        spec.baleWrapperState = BaleWrapper.STATE_MOVING_GRABBER_TO_WORK
    elseif id == BaleWrapper.CHANGE_WRAPPING_START then
        spec.baleWrapperState = BaleWrapper.STATE_WRAPPER_WRAPPING_BALE
        if self.isClient then
            g_soundManager:playSamples(spec.currentWrapper.samples.start)
            g_soundManager:playSamples(spec.currentWrapper.samples.wrap, 0, spec.currentWrapper.samples.start[1])
        end
        if spec.currentWrapper.animations.wrapBale.animName ~= nil then
            self:playAnimation(spec.currentWrapper.animations.wrapBale.animName, spec.currentWrapper.animations.wrapBale.animSpeed, nil, true)
        end
    elseif id == BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED then
        if self.isClient then
            g_soundManager:stopSamples(spec.currentWrapper.samples.wrap)
            g_soundManager:stopSamples(spec.currentWrapper.samples.stop)
            if spec.currentWrapper.wrappingSoundEndTime == 1 then
                g_soundManager:playSamples(spec.currentWrapper.samples.stop)
            end
            g_soundManager:stopSamples(spec.currentWrapper.samples.start)
        end
        self:updateWrappingState(1, true)
        spec.baleWrapperState = BaleWrapper.STATE_WRAPPER_FINSIHED
        local bale = NetworkUtil.getObject(spec.currentWrapper.currentBale)
        if bale ~= nil and (not bale:getSupportsWrapping() or bale.wrappingState == 1) and true or spec.currentWrapper.allowedBaleTypes[spec.currentBaleTypeIndex].skipWrapping then
            self:updateWrappingState(0, true)
        end
        if not skipWrapping then
            local z = spec.currentWrapper.animations.resetWrapping
            if z.animName ~= nil then
                self:playAnimation(z.animName, z.animSpeed, nil, true)
            end
        end
        self:updateConsumable(BaleWrapper.CONSUMABLE_TYPE_NAME, 0)
    elseif id == BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE then
        self:updateWrapNodes(false, false, 0)
        local skipWrapping = spec.currentWrapper.allowedBaleTypes[spec.currentBaleTypeIndex].dropAnimations[spec.dropAnimationIndex]
        if skipWrapping ~= nil then
            spec.currentWrapper.animations.dropFromWrapper.animName = skipWrapping.name
            spec.currentWrapper.animations.dropFromWrapper.animSpeed = skipWrapping.animSpeed
            if self.isServer and (skipWrapping.liftOnDrop and self:getIsLowered()) then
                local bale = self:getAttacherVehicle()
                if bale ~= nil then
                    bale:handleLowerImplementEvent(self)
                end
            end
        end
        if spec.currentWrapper.animations.dropFromWrapper.animName ~= nil then
            self:playAnimation(spec.currentWrapper.animations.dropFromWrapper.animName, spec.currentWrapper.animations.dropFromWrapper.animSpeed, nil, true)
        end
        spec.dropAnimationIndex = 1
        spec.baleWrapperState = BaleWrapper.STATE_WRAPPER_DROPPING_BALE
    elseif id == BaleWrapper.CHANGE_WRAPPER_BALE_DROPPED then
        local baleType = NetworkUtil.getObject(spec.currentWrapper.currentBale)
        if baleType ~= nil then
            baleType:unmountKinematic()
            baleType:setNeedsSaving(true)
            baleType:setCanBeSold(true)
            if baleType:getSupportsWrapping() and not spec.currentWrapper.allowedBaleTypes[spec.currentBaleTypeIndex].skipWrapping then
                local bale, z = g_farmManager:updateFarmStats(self:getOwnerFarmId(), "wrappedBales", 1)
                if bale ~= nil then
                    g_achievementManager:tryUnlock("WrappedBales", bale)
                end
                if baleType.wrappingState < 1 then
                    baleType:setWrappingState(1)
                end
            end
        end
        spec.lastDroppedBaleId = NetworkUtil.getObjectId(baleType)
        spec.currentWrapper.currentBale = nil
        spec.currentWrapper.currentTime = 0
        if spec.currentWrapper.animations.resetAfterDrop.animName ~= nil then
            local skipWrapping = spec.currentWrapper.animations.dropFromWrapper.animName
            if self:getIsAnimationPlaying(skipWrapping) then
                self:stopAnimation(skipWrapping, true)
                self:setAnimationTime(skipWrapping, 1, true, false)
            end
            self:playAnimation(spec.currentWrapper.animations.resetAfterDrop.animName, spec.currentWrapper.animations.resetAfterDrop.animSpeed, nil, true)
        end
        local z = spec.currentWrapper == spec.roundBaleWrapper
        self:setBaleWrapperType(z, spec.currentBaleTypeIndex)
        spec.baleWrapperState = BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM
    elseif id == BaleWrapper.CHANGE_WRAPPER_PLATFORM_RESET then
        self:updateWrappingState(0)
        self:updateWrapNodes(false, true, 0)
        spec.baleWrapperState = BaleWrapper.STATE_NONE
    elseif id == BaleWrapper.CHANGE_BUTTON_EMPTY then
        assert(self.isServer)
        if spec.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED then
            g_server:broadcastEvent(BaleWrapperStateEvent.new(self, BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE), true, nil, self)
        end
    end
    BaleWrapper.updateActionEvents(self)
end
function BaleWrapper:getIsBaleWrappable(bale)
    local spec = self.spec_baleWrapper
    local sizeMatch = false
    local baleTypes = bale.isRoundbale and spec.roundBaleWrapper.allowedBaleTypes or spec.squareBaleWrapper.allowedBaleTypes
    if baleTypes ~= nil then
        for i, baleType in ipairs(baleTypes) do
            if bale:getBaleMatchesSize(baleType.diameter, baleType.width, baleType.height, baleType.length) then
                if not baleType.skipWrapping and (bale:getSupportsWrapping() and bale.wrappingState < 1) then
                    return true, true, i
                end
            end
        end
    end
    return false, sizeMatch
end
function BaleWrapper:getIsBaleDropAllowed()
    local spec = self.spec_baleWrapper
    local currentWrapper = spec.currentWrapper
    if currentWrapper.dropArea.node ~= nil then
        local x, y, z = getWorldTranslation(currentWrapper.dropArea.node)
        local rx, ry, rz = getWorldRotation(currentWrapper.dropArea.node)
        spec.foundDropOverlappingObject = false
        overlapBox(x, y, z, rx, ry, rz, currentWrapper.dropArea.width * 0.5, currentWrapper.dropArea.height * 0.5, currentWrapper.dropArea.length * 0.5, "onBaleWrapperDropOverlapCallback", self, BaleWrapper.DROP_COLLISION_MASK, true, true, false, true)
        if spec.foundDropOverlappingObject then
            return false, spec.texts.warningDropAreaBlocked
        end
    end
    return true, nil
end
function BaleWrapper:onBaleWrapperDropOverlapCallback(nodeId)
    local object = g_currentMission:getNodeObject(nodeId)
    if object ~= nil and object ~= self then
        local spec = self.spec_baleWrapper
        local currentWrapper = spec.currentWrapper
        if currentWrapper.currentBale ~= nil and object == NetworkUtil.getObject(currentWrapper.currentBale) then
            return
        end
        spec.foundDropOverlappingObject = true
        spec.foundDropOverlappingObjectTime = g_time
    end
end
function BaleWrapper:getIsBaleWrappingAllowed()
    local spec = self.spec_baleWrapper
    local currentWrapper = spec.currentWrapper
    if currentWrapper.blockWrapArea.node ~= nil then
        local x, y, z = getWorldTranslation(currentWrapper.blockWrapArea.node)
        local rx, ry, rz = getWorldRotation(currentWrapper.blockWrapArea.node)
        spec.foundBlockOverlappingObject = false
        overlapBox(x, y, z, rx, ry, rz, currentWrapper.blockWrapArea.width * 0.5, currentWrapper.blockWrapArea.height * 0.5, currentWrapper.blockWrapArea.length * 0.5, "onBaleWrapperBlockOverlapCallback", self, BaleWrapper.BLOCK_COLLISION_MASK, true, true, false, true)
        if spec.foundBlockOverlappingObject then
            return false
        end
    end
    return self:getConsumableIsAvailable(BaleWrapper.CONSUMABLE_TYPE_NAME)
end
function BaleWrapper:onBaleWrapperBlockOverlapCallback(nodeId)
    local object = g_currentMission:getNodeObject(nodeId)
    if object ~= nil and object ~= self then
        local spec = self.spec_baleWrapper
        local currentWrapper = spec.currentWrapper
        if currentWrapper.currentBale ~= nil and object == NetworkUtil.getObject(currentWrapper.currentBale) then
            return
        end
        spec.foundBlockOverlappingObject = true
    end
end
function BaleWrapper:pickupWrapperBale(bale, baleTypeIndex)
    local spec = self.spec_baleWrapper
    if bale:getSupportsWrapping() then
        local baleTypes = bale.isRoundbale and spec.roundBaleWrapper.allowedBaleTypes or spec.squareBaleWrapper.allowedBaleTypes
        if baleTypes ~= nil and baleTypeIndex ~= nil then
            local baleType = baleTypes[baleTypeIndex]
            if baleType ~= nil and (not baleType.skipWrapping and (bale.wrappingState < 1 and (baleType.wrapDiffuse ~= nil or baleType.wrapNormal ~= nil))) then
                bale:setWrapTextures(baleType.wrapDiffuse, baleType.wrapNormal)
            end
        end
    end
    spec.baleGrabber.balesInTrigger[bale] = nil
    g_server:broadcastEvent(BaleWrapperStateEvent.new(self, BaleWrapper.CHANGE_GRAB_BALE, NetworkUtil.getObjectId(bale)), true, nil, self)
end
function BaleWrapper:getBaleInRange(refNode, distance)
    local nearestBale = nil
    local nearestBaleWrappable = nil
    local nearestBaleTypeIndex = nil
    for bale, _ in pairs(self.spec_baleWrapper.baleGrabber.balesInTrigger) do
        if bale.dynamicMountType == MountableObject.MOUNT_TYPE_NONE and (bale.nodeId ~= 0 and calcDistanceFrom(refNode, bale.nodeId) < distance) then
            local isWrappable, sizeMatches, baleTypeIndex = self:getIsBaleWrappable(bale)
            if isWrappable and sizeMatches then
                nearestBaleTypeIndex = baleTypeIndex
                nearestBale = bale
                nearestBaleWrappable = nearestBale
                nearestBale, nearestBaleWrappable = nearestBaleWrappable, nearestBale
            else
                nearestBale = bale
            end
        end
    end
    return nearestBaleWrappable, nearestBale, nearestBaleTypeIndex
end
function BaleWrapper:setBaleWrapperAutomaticDrop(state, noEventSend)
    local spec = self.spec_baleWrapper
    if state == nil then
        state = not spec.automaticDrop
    end
    spec.automaticDrop = state
    self:requestActionEventUpdate()
    BaleWrapperAutomaticDropEvent.sendEvent(self, state, noEventSend)
end
function BaleWrapper:setBaleWrapperDropAnimation(dropAnimationIndex)
    self.spec_baleWrapper.dropAnimationIndex = dropAnimationIndex
end
function BaleWrapper:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
    local spec = self.spec_baleWrapper
    if spec.baleWrapperState == BaleWrapper.STATE_NONE then
        return superFunc(self, direction, onAiTurnOn)
    else
        return false, spec.texts.warningFoldingWrapping
    end
end
function BaleWrapper:getCanBeSelected(superFunc)
    return true
end
function BaleWrapper:getShowConsumableEmptyWarning(superFunc, typeName)
    if typeName ~= BaleWrapper.CONSUMABLE_TYPE_NAME then
        return superFunc(self, typeName)
    end
    return self.spec_baleWrapper.baleWrapperState ~= BaleWrapper.STATE_NONE and superFunc(self, typeName)
end
function BaleWrapper:getRequiresPower(superFunc)
    return self.spec_baleWrapper.baleWrapperState ~= BaleWrapper.STATE_NONE and true or superFunc(self)
end
function BaleWrapper:getStandaloneMotorTargetRpm(superFunc)
    local rpmFactor = 0
    local spec = self.spec_baleWrapper
    if spec.baleWrapperState ~= BaleWrapper.STATE_NONE then
    end
    return math.max(superFunc(self), rpmFactor)
end
function BaleWrapper:getStandaloneMotorLoad(superFunc)
    local loadFactorSum, numLoadFactors = superFunc(self)
    local loadFactor = 0
    local spec = self.spec_baleWrapper
    if spec.baleWrapperState ~= BaleWrapper.STATE_NONE then
    end
    return loadFactorSum + loadFactor, numLoadFactors + 1
end
function BaleWrapper:addToPhysics(superFunc)
    if not superFunc(self) then
        return false
    end
    local spec = self.spec_baleWrapper
    local object = NetworkUtil.getObject(spec.baleGrabber.currentBale)
    if object ~= nil then
        object:addToPhysics()
        object:mountKinematic(self, spec.baleGrabber.grabNode, 0, 0, 0, 0, 0, 0)
    end
    local currentWrapper = spec.currentWrapper
    if currentWrapper.currentBale ~= nil then
        local object = NetworkUtil.getObject(currentWrapper.currentBale)
        if object ~= nil then
            object:addToPhysics()
            object:mountKinematic(self, spec.currentWrapper.baleNode, 0, 0, 0, 0, 0, 0)
        end
    end
    return true
end
function BaleWrapper:removeFromPhysics(superFunc)
    if not superFunc(self) then
        return false
    end
    local currentWrapper = self.spec_baleWrapper.currentWrapper
    if currentWrapper.currentBale ~= nil then
        local object = NetworkUtil.getObject(currentWrapper.currentBale)
        if object ~= nil then
            object:unmountKinematic()
            object:removeFromPhysics()
        end
    end
    return true
end
function BaleWrapper:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_baleWrapper
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection then
            if not spec.automaticDrop then
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, BaleWrapper.actionEventEmpty, false, true, false, true, nil)
                g_inputBinding:setActionEventText(actionEventId, spec.currentWrapper.unloadBaleText)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
                local baleType = spec.currentWrapper.allowedBaleTypes[spec.currentBaleTypeIndex]
                local i = 1
                for i = i, #baleType.dropAnimations do
                    local dropAnimation = baleType.dropAnimations[i]
                    if dropAnimation.inputAction ~= nil then
                        local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, dropAnimation.inputAction, self, BaleWrapper.actionEventDrop, false, true, false, false, i)
                        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
                        g_inputBinding:setActionEventText(actionEventId, dropAnimation.text)
                    end
                end
            end
            if spec.toggleableAutomaticDrop then
                local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA4, self, BaleWrapper.actionEventToggleAutomaticDrop, false, true, false, true, nil)
                g_inputBinding:setActionEventText(actionEventId, spec.automaticDrop and spec.toggleAutomaticDropTextNeg or spec.toggleAutomaticDropTextPos)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
            end
            BaleWrapper.updateActionEvents(self)
        end
    end
end
function BaleWrapper:onRegisterExternalActionEvents(trigger, name, _, _)
    if name == "baleWrapperDrop" then
        self:registerExternalActionEvent(trigger, name, BaleWrapper.externalActionEventUnloadRegister, BaleWrapper.externalActionEventUnloadUpdate)
    elseif name == "baleWrapperAutomaticDrop" then
        if self.spec_baleWrapper.toggleableAutomaticDrop then
            self:registerExternalActionEvent(trigger, name, BaleWrapper.externalActionEventAutomaticUnloadRegister, BaleWrapper.externalActionEventAutomaticUnloadUpdate)
            return
        end
    elseif name == "baleWrapperWarnings" then
        self:registerExternalActionEvent(trigger, name, BaleWrapper.externalActionEventWarningsRegister, BaleWrapper.externalActionEventWarningsUpdate)
    end
end
function BaleWrapper:onDeactivate()
    local spec = self.spec_baleWrapper
    spec.showInvalidBaleWarning = false
    if self.isClient then
        g_soundManager:stopSamples(spec.currentWrapper.samples.wrap)
        g_soundManager:stopSamples(spec.currentWrapper.samples.start)
        g_soundManager:stopSamples(spec.currentWrapper.samples.stop)
    end
end
function BaleWrapper:onFoldStateChanged(direction, _)
    local spec = self.spec_baleWrapper
    if spec.foldedBaleType ~= nil and self.spec_foldable.turnOnFoldDirection ~= direction then
        self:setBaleWrapperType(spec.foldedBaleType.isRoundBaleWrapper, spec.foldedBaleType.baleTypeIndex)
    end
end
function BaleWrapper:onConsumableVariationChanged(_, metaData)
    if metaData.color ~= nil then
        local spec = self.spec_baleWrapper
        spec.wrapColor[1] = metaData.color[1]
        spec.wrapColor[2] = metaData.color[2]
        spec.wrapColor[3] = metaData.color[3]
    end
end
function BaleWrapper:actionEventEmpty(_, _, _, _)
    if self.spec_baleWrapper.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED then
        local dropIsAllowed, warning = self:getIsBaleDropAllowed()
        if dropIsAllowed then
            g_client:getServerConnection():sendEvent(BaleWrapperStateEvent.new(self, BaleWrapper.CHANGE_BUTTON_EMPTY))
            return
        end
        if warning ~= nil then
            g_currentMission:showBlinkingWarning(warning, 2000)
        end
    end
end
function BaleWrapper:actionEventToggleAutomaticDrop(_, _, _, _)
    self:setBaleWrapperAutomaticDrop()
end
function BaleWrapper:actionEventDrop(_, _, callbackState, _)
    if self.spec_baleWrapper.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED then
        g_client:getServerConnection():sendEvent(BaleWrapperDropEvent.new(self, callbackState))
    end
end
function BaleWrapper:updateActionEvents()
    local spec = self.spec_baleWrapper
    local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]
    if actionEvent ~= nil then
        g_inputBinding:setActionEventActive(actionEvent.actionEventId, spec.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED)
        g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.currentWrapper.unloadBaleText)
    end
    if spec.toggleableAutomaticDrop then
        local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA4]
        if actionEvent ~= nil then
            g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.automaticDrop and spec.toggleAutomaticDropTextNeg or spec.toggleAutomaticDropTextPos)
        end
    end
    local baleType = spec.currentWrapper.allowedBaleTypes[spec.currentBaleTypeIndex]
    local i = 1
    for i = i, #baleType.dropAnimations do
        local dropAnimation = baleType.dropAnimations[i]
        if dropAnimation.inputAction ~= nil then
            local actionEvent = spec.actionEvents[dropAnimation.inputAction]
            if actionEvent ~= nil then
                g_inputBinding:setActionEventActive(actionEvent.actionEventId, spec.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED)
            end
        end
    end
end
function BaleWrapper.externalActionEventUnloadRegister(data, vehicle)
    local spec = vehicle.spec_baleWrapper
    _, data.actionEventId = g_inputBinding:registerActionEvent(InputAction.IMPLEMENT_EXTRA3, data, function(_, actionName, inputValue, callbackState, isAnalog)
        -- upvalues: (copy) spec, (copy) vehicle
        if not spec.automaticDrop then
            BaleWrapper.actionEventEmpty(vehicle, actionName, inputValue, callbackState, isAnalog)
        end
    end, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
    g_inputBinding:setActionEventText(data.actionEventId, spec.currentWrapper.unloadBaleText)
end
function BaleWrapper.externalActionEventUnloadUpdate(data, vehicle)
    g_inputBinding:setActionEventActive(data.actionEventId, vehicle.spec_baleWrapper.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED)
end
function BaleWrapper.externalActionEventAutomaticUnloadRegister(data, vehicle)
    _, data.actionEventId = g_inputBinding:registerActionEvent(InputAction.IMPLEMENT_EXTRA4, data, function(_, actionName, inputValue, callbackState, isAnalog)
        -- upvalues: (copy) vehicle
        BaleWrapper.actionEventToggleAutomaticDrop(vehicle, actionName, inputValue, callbackState, isAnalog)
    end, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
end
function BaleWrapper.externalActionEventAutomaticUnloadUpdate(data, vehicle)
    local spec = vehicle.spec_baleWrapper
    g_inputBinding:setActionEventText(data.actionEventId, spec.automaticDrop and spec.toggleAutomaticDropTextNeg or spec.toggleAutomaticDropTextPos)
end
function BaleWrapper.externalActionEventWarningsRegister(data, vehicle) end
function BaleWrapper.externalActionEventWarningsUpdate(_, vehicle)
    local spec = vehicle.spec_baleWrapper
    if spec.automaticDrop then
        if g_time - spec.foundDropOverlappingObjectTime < 500 then
            g_currentMission:showBlinkingWarning(spec.texts.warningDropAreaBlocked, 500)
            return
        end
    elseif spec.showInvalidBaleWarning then
        g_currentMission:showBlinkingWarning(spec.texts.warningBaleNotSupported, 500)
    end
end
function BaleWrapper.loadSpecValueBaleSize(xmlFile, _, _, roundBaleWrapper)
    local rootName = xmlFile:getRootName()
    local baleSizeAttributes = {
        ["minDiameter"] = math.huge,
        ["maxDiameter"] = -math.huge,
        ["minLength"] = math.huge,
        ["maxLength"] = -math.huge
    }
    xmlFile:iterate(rootName .. ".baleWrapper." .. (roundBaleWrapper and "roundBaleWrapper" or "squareBaleWrapper") .. ".baleTypes.baleType", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) baleSizeAttributes
        if not xmlFile:getValue(key .. "#skipWrapping", false) then
            local diameter = MathUtil.round(xmlFile:getValue(key .. "#diameter", 0), 2)
            baleSizeAttributes.minDiameter = math.min(baleSizeAttributes.minDiameter, diameter)
            baleSizeAttributes.maxDiameter = math.max(baleSizeAttributes.maxDiameter, diameter)
            baleSizeAttributes.minLength = math.min(baleSizeAttributes.minLength, (MathUtil.round(xmlFile:getValue(key .. "#length", 0), 2)))
            baleSizeAttributes.maxLength = math.max(baleSizeAttributes.maxLength, length)
        end
    end)
    if baleSizeAttributes.minDiameter == math.huge and baleSizeAttributes.minLength == math.huge then
        return nil
    else
        return baleSizeAttributes
    end
end
function BaleWrapper.getSpecValueBaleSize(storeItem, _, _, _, returnValues, returnRange, roundBaleWrapper)
    local baleSizeAttributes = roundBaleWrapper and storeItem.specs.baleWrapperBaleSizeRound or storeItem.specs.baleWrapperBaleSizeSquare
    if baleSizeAttributes == nil then
        if returnValues and returnRange then
            return 0, 0, ""
        elseif returnValues then
            return 0, ""
        else
            return ""
        end
    elseif returnValues == nil or not returnValues then
        local unit = g_i18n:getText("unit_cmShort")
        if (roundBaleWrapper and baleSizeAttributes.maxDiameter or baleSizeAttributes.maxLength) == (roundBaleWrapper and baleSizeAttributes.minDiameter or baleSizeAttributes.minLength) then
            return string.format("%d%s", minValue * 100, unit)
        else
            return string.format("%d%s-%d%s", minValue * 100, unit, maxValue * 100, unit)
        end
    elseif returnRange == true and maxValue ~= minValue then
        return minValue * 100, maxValue * 100, g_i18n:getText("unit_cmShort")
    else
        return minValue * 100, g_i18n:getText("unit_cmShort")
    end
end
function BaleWrapper.loadSpecValueBaleSizeRound(xmlFile, customEnvironment, baseDir)
    return BaleWrapper.loadSpecValueBaleSize(xmlFile, customEnvironment, baseDir, true)
end
function BaleWrapper.loadSpecValueBaleSizeSquare(xmlFile, customEnvironment, baseDir)
    return BaleWrapper.loadSpecValueBaleSize(xmlFile, customEnvironment, baseDir, false)
end
function BaleWrapper.getSpecValueBaleSizeRound(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
    if storeItem.specs.baleWrapperBaleSizeRound == nil then
        return nil
    else
        return BaleWrapper.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, true)
    end
end
function BaleWrapper.getSpecValueBaleSizeSquare(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
    if storeItem.specs.baleWrapperBaleSizeSquare == nil then
        return nil
    else
        return BaleWrapper.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, false)
    end
end