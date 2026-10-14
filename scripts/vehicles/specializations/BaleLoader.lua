source("dataS/scripts/vehicles/specializations/events/BaleLoaderStateEvent.lua")
BaleLoader = {}
function BaleLoader.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end
function BaleLoader.initSpecialization()
    g_storeManager:addSpecType("baleLoaderBaleSizeRound", "shopListAttributeIconBaleSizeRound", BaleLoader.loadSpecValueBaleSizeRound, BaleLoader.getSpecValueBaleSizeRound, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("baleLoaderBaleSizeSquare", "shopListAttributeIconBaleSizeSquare", BaleLoader.loadSpecValueBaleSizeSquare, BaleLoader.getSpecValueBaleSizeSquare, StoreSpecies.VEHICLE)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("BaleLoader")
    schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#transportPosition", "Transport position text", "action_baleloaderTransportPosition")
    schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#operatingPosition", "Operating position text", "action_baleloaderOperatingPosition")
    schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#unload", "Unload text", "action_baleloaderUnload")
    schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#tilting", "Tilting text", "info_baleloaderTiltingTable")
    schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#lowering", "Lowering text", "info_baleloaderLoweringTable")
    schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#lowerPlattform", "Lower platform text", "action_baleloaderLowerPlatform")
    schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#abortUnloading", "Abort unloading text", "action_baleloaderAbortUnloading")
    schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#unloadHere", "Unload here text", "action_baleloaderUnloadHere")
    schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#baleNotSupported", "Bale not supported warning", "warning_baleNotSupported")
    schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#baleDoNotAllowFillTypeMixing", "Warning to be shown if the fill type is different from loaded fill types", "warning_baleDoNotAllowFillTypeMixing")
    schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#onlyOneBaleTypeWarning", "Warning to be shown if user tries to collect a different bale type as already loaded", "warning_baleLoaderOnlyAllowOnceSize")
    schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#minUnloadingFillLevelWarning", "Warning to be displayed if min fill level is not reached", "warning_baleLoaderNotFullyLoaded")
    BaleLoader.registerAnimationXMLPaths(schema, "vehicle.baleLoader")
    schema:register(XMLValueType.BOOL, "vehicle.baleLoader#transportPositionAfterUnloading", "Activate transport mode after unloading", true)
    schema:register(XMLValueType.BOOL, "vehicle.baleLoader#useFoldingState", "Use folding state for activation and deactivation", false)
    schema:register(XMLValueType.BOOL, "vehicle.baleLoader#useBalePlaceAsLoadPosition", "Use bale place position as load position", false)
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader#balePlaceOffset", "Bale place offset", 0)
    schema:register(XMLValueType.BOOL, "vehicle.baleLoader#keepBaleRotationDuringLoad", "Keep the same bale rotation while loading bale", false)
    schema:register(XMLValueType.BOOL, "vehicle.baleLoader#automaticUnloading", "Automatically unload the bale loader if platform lifted", false)
    schema:register(XMLValueType.BOOL, "vehicle.baleLoader#fullAutomaticUnloading", "Automatically unload the bale loader when getting full", false)
    schema:register(XMLValueType.INT, "vehicle.baleLoader#minUnloadingFillLevel", "Min. fill level until unloading is allowed", 1)
    schema:register(XMLValueType.BOOL, "vehicle.baleLoader#allowKinematicMounting", "Kinematic mounting of bale is allow (= bales still have collision while loaded)", true)
    schema:register(XMLValueType.BOOL, "vehicle.baleLoader#consumePtoPower", "Defines if the bale loader consumes pto power while in work mode", true)
    schema:register(XMLValueType.BOOL, "vehicle.baleLoader.dynamicMount#enabled", "Bales are dynamically mounted", false)
    schema:register(XMLValueType.BOOL, "vehicle.baleLoader.dynamicMount#doInterpolation", "Bale position is interpolated from bale origin position to grabber position", false)
    schema:register(XMLValueType.TIME, "vehicle.baleLoader.dynamicMount#interpolationTimeRot", "Time for bale rotation interpolation", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.dynamicMount#interpolationSpeedTrans", "Speed of translation interpolation (m/sec)", 0.1)
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.baleLoader.dynamicMount#minTransLimits", "Min translation limit")
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.baleLoader.dynamicMount#maxTransLimits", "Max translation limit")
    schema:register(XMLValueType.BOOL, "vehicle.baleLoader.dynamicBaleUnloading#enabled", "Bales are joint together during unloading")
    schema:register(XMLValueType.VECTOR_N, "vehicle.baleLoader.dynamicBaleUnloading#connectedRows", "Indices of rows that are connected together")
    schema:register(XMLValueType.STRING, "vehicle.baleLoader.dynamicBaleUnloading#interConnectedRowStarts", "Interconnections at row start between rows (e.g. \'1-2 3-4\')")
    schema:register(XMLValueType.STRING, "vehicle.baleLoader.dynamicBaleUnloading#interConnectedRowEnds", "Interconnections at row ends between rows (e.g. \'1-2 3-4\')")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.dynamicBaleUnloading#widthOffset", "Width offset")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.dynamicBaleUnloading#heightOffset", "Height offset")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.dynamicBaleUnloading#diameterOffset", "Diameter offset")
    schema:register(XMLValueType.ANGLE, "vehicle.baleLoader.dynamicBaleUnloading#rowConnectionRotLimit", "Rotation limit for row joints")
    schema:register(XMLValueType.ANGLE, "vehicle.baleLoader.dynamicBaleUnloading#rowInterConnectionRotLimit", "Rotation limit for inter row joints")
    schema:register(XMLValueType.STRING, "vehicle.baleLoader.dynamicBaleUnloading.releaseAnimation#name", "Reference animation to remove joints")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.dynamicBaleUnloading.releaseAnimation#time", "If animation time is higher than this time the joints will be removed", 1)
    schema:register(XMLValueType.BOOL, "vehicle.baleLoader.dynamicBaleUnloading.releaseAnimation#useUnloadingMoverTrigger", "Bale joints will be removed as soon all bales hast left the unloading mover trigger", false)
    schema:register(XMLValueType.INT, "vehicle.baleLoader#fillUnitIndex", "Fill unit index", 1)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.grabber#grabNode", "Grab node")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.grabber#pickupRange", "Pickup range", 3)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.grabber#triggerNode", "Trigger node")
    EffectManager.registerEffectXMLPaths(schema, "vehicle.baleLoader.grabber")
    schema:register(XMLValueType.TIME, "vehicle.baleLoader.grabber#effectDisableDuration", "Disable duration", 0.6)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.balePlaces#startBalePlace", "Start bale place node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.balePlaces.balePlace(?)#node", "Bale place node")
    schema:register(XMLValueType.STRING, "vehicle.baleLoader.foldingAnimations#baseAnimation", "Base animation name", "baleGrabberTransportToWork")
    schema:register(XMLValueType.STRING, "vehicle.baleLoader.foldingAnimations.foldingAnimation(?)#name", "Animation name")
    schema:register(XMLValueType.INT, "vehicle.baleLoader.foldingAnimations.foldingAnimation(?)#baleTypeIndex", "Index of current bale type", "\'0\' - any bale type")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.foldingAnimations.foldingAnimation(?)#minFillLevel", "Min. fill level to use this animation", "-inf")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.foldingAnimations.foldingAnimation(?)#maxFillLevel", "Max. fill level to use this animation", "inf")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.foldingAnimations.foldingAnimation(?)#minBalePlace", "Min. bales on platform to use this animation", "-inf")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.foldingAnimations.foldingAnimation(?)#maxBalePlace", "Max. bales on platform to use this animation", "inf")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.unloadingMoverNodes#trigger", "As long as bales are in this trigger the mover nodes are active and the player can not lower the platform")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.unloadingMoverNodes.unloadingMoverNode(?)#node", "Node that moves bales")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.unloadingMoverNodes.unloadingMoverNode(?)#speed", "Defines direction and speed of moving in X direction", -1)
    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.baleLoader.unloadingMoverNodes.animationNodes")
    schema:register(XMLValueType.INT, "vehicle.baleLoader.synchronization#numBitsPosition", "Number of bits to synchronize bale positions", 10)
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.synchronization#maxPosition", "Max. position offset of bales from bale place in meter", 3)
    SoundManager.registerSampleXMLPaths(schema, "vehicle.baleLoader.sounds", "grab")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.baleLoader.sounds", "emptyRotate")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.baleLoader.sounds", "work")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.baleLoader.sounds", "unload")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#diameter", "Bale diameter")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#width", "Bale width")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#height", "Bale height")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#length", "Bale length")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#minDiameter", "Bale min diameter", "diameter value")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#maxDiameter", "Bale max diameter", "diameter value")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#minWidth", "Bale min width", "width value")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#maxWidth", "Bale max width", "width value")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#minHeight", "Bale min height", "height value")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#maxHeight", "Bale max height", "height value")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#minLength", "Bale min length", "length value")
    schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#maxLength", "Bale max length", "length value")
    schema:register(XMLValueType.INT, "vehicle.baleLoader.baleTypes.baleType(?)#fillUnitIndex", "Fill unit index", "baleLoader#fillUnitIndex")
    schema:register(XMLValueType.BOOL, "vehicle.baleLoader.baleTypes.baleType(?)#mixedFillTypes", "Allow loading of mixed fill types", true)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.baleTypes.baleType(?).balePlaces#startBalePlace", "Start bale place node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.baleTypes.baleType(?).balePlaces.balePlace(?)#node", "Bale place node")
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.baleLoader.baleTypes.baleType(?)")
    BaleLoader.registerAnimationXMLPaths(schema, "vehicle.baleLoader.baleTypes.baleType(?)")
    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.baleLoader.animationNodes")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.balePacker#node", "Node where to create the packed bale")
    schema:register(XMLValueType.STRING, "vehicle.baleLoader.balePacker#packedFilename", "Filename to packed bale")
    schema:addDelayedRegistrationFunc("AnimatedVehicle:part", function(cSchema, cKey)
        cSchema:register(XMLValueType.BOOL, cKey .. "#baleLoaderAnimationNodes", "Bale Loader animation nodes turn on/off")
    end)
    schema:setXMLSpecializationType()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).baleLoader#lastFoldingAnimation", "Last folding animation name")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).baleLoader#baleTypeIndex", "Last bale type index")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).baleLoader#isInWorkPosition", "Is in working Position")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).baleLoader.bale(?)#filename", "Filename")
    schemaSavegame:register(XMLValueType.VECTOR_TRANS, "vehicles.vehicle(?).baleLoader.bale(?)#position", "Position")
    schemaSavegame:register(XMLValueType.VECTOR_ROT, "vehicles.vehicle(?).baleLoader.bale(?)#rotation", "Rotation")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).baleLoader.bale(?)#fillLevel", "Filllevel")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).baleLoader.bale(?)#balePlace", "Bale place index")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).baleLoader.bale(?)#helper", "Helper index")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).baleLoader.bale(?)#farmId", "Farm index")
    Bale.registerSavegameXMLPaths(schemaSavegame, "vehicles.vehicle(?).baleLoader.bale(?)")
end
function BaleLoader.registerAnimationXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".animations.platform#rotate", "Rotate platform animation name", "rotatePlatform")
    schema:register(XMLValueType.STRING, basePath .. ".animations.platform#rotateBack", "Rotate platform back animation name", "rotatePlatform")
    schema:register(XMLValueType.STRING, basePath .. ".animations.platform#rotateEmpty", "Rotate platform empty animation name", "rotatePlatform")
    schema:register(XMLValueType.BOOL, basePath .. ".animations.platform#allowPickupWhileMoving", "Allow pickup of next bale while platform is rotating", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".animations.baleGrabber#dropBaleReverseSpeed", "Speed of grabber in reverse", 5)
    schema:register(XMLValueType.STRING, basePath .. ".animations.baleGrabber#dropToWork", "Custom grabber animation when moving from drop to work")
    schema:register(XMLValueType.STRING, basePath .. ".animations.baleGrabber#workToDrop", "Bale grabber work to drop animation", "baleGrabberWorkToDrop")
    schema:register(XMLValueType.STRING, basePath .. ".animations.baleGrabber#dropBale", "Bale grabber drop bale animation", "baleGrabberDropBale")
    schema:register(XMLValueType.STRING, basePath .. ".animations.baleGrabber#transportToWork", "Transport to work animation", "baleGrabberTransportToWork")
    schema:register(XMLValueType.STRING, basePath .. ".animations.pusher#emptyHide", "Empty hide animation", "emptyHidePusher1")
    schema:register(XMLValueType.STRING, basePath .. ".animations.pusher#moveToEmpty", "Move to empty position", "moveBalePusherToEmpty")
    schema:register(XMLValueType.BOOL, basePath .. ".animations.pusher#hidePusherOnEmpty", "Reverse move to empty animation after execution", true)
    schema:register(XMLValueType.BOOL, basePath .. ".animations.pusher#pushBalesOnEmpty", "Defines if bale are pushed or pulled on empty", false)
    schema:register(XMLValueType.STRING, basePath .. ".animations.releaseFrontPlatform#name", "Release front platform animation name", "releaseFrontplattform")
    schema:register(XMLValueType.BOOL, basePath .. ".animations.releaseFrontPlatform#fillLevelSpeed", "Front platform speed is dependent on fill level", false)
    schema:register(XMLValueType.STRING, basePath .. ".animations.moveBalePlaces#name", "Move bale places animation", "moveBalePlaces")
    schema:register(XMLValueType.STRING, basePath .. ".animations.moveBalePlaces#extrasOnce", "Move bale places extra once animation", "moveBalePlaces")
    schema:register(XMLValueType.STRING, basePath .. ".animations.moveBalePlaces#empty", "Move bale places empty animation", "moveBalePlaces")
    schema:register(XMLValueType.FLOAT, basePath .. ".animations.moveBalePlaces#emptySpeed", "Speed of move bale places to empty", 1.5)
    schema:register(XMLValueType.FLOAT, basePath .. ".animations.moveBalePlaces#emptyReverseSpeed", "Reverse speed of move bale places to empty", -1)
    schema:register(XMLValueType.FLOAT, basePath .. ".animations.moveBalePlaces#pushOffset", "Delay of empty animation to give pusher time to move to the last bale", 0)
    schema:register(XMLValueType.BOOL, basePath .. ".animations.moveBalePlaces#moveAfterRotatePlatform", "Move bale places after rotate platform", false)
    schema:register(XMLValueType.BOOL, basePath .. ".animations.moveBalePlaces#resetOnSink", "Reset move bale places on platform sink", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".animations.moveBalePlaces#maxGrabberTime", "Max. grabber time to move bale places", "inf")
    schema:register(XMLValueType.BOOL, basePath .. ".animations.moveBalePlaces#alwaysMove", "Always move bale places", false)
    schema:register(XMLValueType.STRING, basePath .. ".animations.emptyRotate#name", "Empty rotate", "emptyRotate")
    schema:register(XMLValueType.BOOL, basePath .. ".animations.emptyRotate#reset", "Reset empty rotate animation", true)
    schema:register(XMLValueType.STRING, basePath .. ".animations#frontBalePusher", "Front bale pusher animation", "frontBalePusher")
    schema:register(XMLValueType.STRING, basePath .. ".animations#balesToOtherRow", "Bales to othe row animation", "balesToOtherRow")
    schema:register(XMLValueType.STRING, basePath .. ".animations#closeGrippers", "Close grippers animation", "closeGrippers")
end
BaleLoader.GRAB_MOVE_UP = 1
BaleLoader.GRAB_MOVE_DOWN = 2
BaleLoader.GRAB_DROP_BALE = 3
BaleLoader.EMPTY_NONE = 1
BaleLoader.EMPTY_TO_WORK = 2
BaleLoader.EMPTY_ROTATE_PLATFORM = 3
BaleLoader.EMPTY_ROTATE1 = 4
BaleLoader.EMPTY_CLOSE_GRIPPERS = 5
BaleLoader.EMPTY_HIDE_PUSHER1 = 6
BaleLoader.EMPTY_HIDE_PUSHER2 = 7
BaleLoader.EMPTY_ROTATE2 = 8
BaleLoader.EMPTY_WAIT_TO_DROP = 9
BaleLoader.EMPTY_WAIT_TO_SINK = 10
BaleLoader.EMPTY_SINK = 11
BaleLoader.EMPTY_CANCEL = 12
BaleLoader.EMPTY_WAIT_TO_REDO = 13
BaleLoader.CHANGE_DROP_BALES = 1
BaleLoader.CHANGE_SINK = 2
BaleLoader.CHANGE_EMPTY_REDO = 3
BaleLoader.CHANGE_EMPTY_START = 4
BaleLoader.CHANGE_EMPTY_CANCEL = 5
BaleLoader.CHANGE_MOVE_TO_WORK = 6
BaleLoader.CHANGE_MOVE_TO_TRANSPORT = 7
BaleLoader.CHANGE_GRAB_BALE = 8
BaleLoader.CHANGE_GRAB_MOVE_UP = 9
BaleLoader.CHANGE_GRAB_DROP_BALE = 10
BaleLoader.CHANGE_GRAB_MOVE_DOWN = 11
BaleLoader.CHANGE_FRONT_PUSHER = 12
BaleLoader.CHANGE_ROTATE_PLATFORM = 13
BaleLoader.CHANGE_EMPTY_ROTATE_PLATFORM = 14
BaleLoader.CHANGE_EMPTY_ROTATE1 = 15
BaleLoader.CHANGE_EMPTY_CLOSE_GRIPPERS = 16
BaleLoader.CHANGE_EMPTY_HIDE_PUSHER1 = 17
BaleLoader.CHANGE_EMPTY_HIDE_PUSHER2 = 18
BaleLoader.CHANGE_EMPTY_ROTATE2 = 19
BaleLoader.CHANGE_EMPTY_WAIT_TO_DROP = 20
BaleLoader.CHANGE_EMPTY_STATE_NIL = 21
BaleLoader.CHANGE_EMPTY_WAIT_TO_REDO = 22
BaleLoader.CHANGE_BUTTON_EMPTY = 23
BaleLoader.CHANGE_BUTTON_EMPTY_ABORT = 24
BaleLoader.CHANGE_BUTTON_WORK_TRANSPORT = 25
function BaleLoader.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadBaleTypeFromXML", BaleLoader.loadBaleTypeFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadBalePlacesFromXML", BaleLoader.loadBalePlacesFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadBaleLoaderAnimationsFromXML", BaleLoader.loadBaleLoaderAnimationsFromXML)
    SpecializationUtil.registerFunction(vehicleType, "createBaleToBaleJoints", BaleLoader.createBaleToBaleJoints)
    SpecializationUtil.registerFunction(vehicleType, "createBaleToBaleJoint", BaleLoader.createBaleToBaleJoint)
    SpecializationUtil.registerFunction(vehicleType, "doStateChange", BaleLoader.doStateChange)
    SpecializationUtil.registerFunction(vehicleType, "getBaleGrabberDropBaleAnimName", BaleLoader.getBaleGrabberDropBaleAnimName)
    SpecializationUtil.registerFunction(vehicleType, "getIsBaleGrabbingAllowed", BaleLoader.getIsBaleGrabbingAllowed)
    SpecializationUtil.registerFunction(vehicleType, "pickupBale", BaleLoader.pickupBale)
    SpecializationUtil.registerFunction(vehicleType, "setBaleLoaderBaleType", BaleLoader.setBaleLoaderBaleType)
    SpecializationUtil.registerFunction(vehicleType, "getBaleTypeByBale", BaleLoader.getBaleTypeByBale)
    SpecializationUtil.registerFunction(vehicleType, "baleGrabberTriggerCallback", BaleLoader.baleGrabberTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "baleLoaderMoveTriggerCallback", BaleLoader.baleLoaderMoveTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "mountDynamicBale", BaleLoader.mountDynamicBale)
    SpecializationUtil.registerFunction(vehicleType, "unmountDynamicBale", BaleLoader.unmountDynamicBale)
    SpecializationUtil.registerFunction(vehicleType, "mountBale", BaleLoader.mountBale)
    SpecializationUtil.registerFunction(vehicleType, "unmountBale", BaleLoader.unmountBale)
    SpecializationUtil.registerFunction(vehicleType, "setBalePairCollision", BaleLoader.setBalePairCollision)
    SpecializationUtil.registerFunction(vehicleType, "getLoadedBales", BaleLoader.getLoadedBales)
    SpecializationUtil.registerFunction(vehicleType, "startAutomaticBaleUnloading", BaleLoader.startAutomaticBaleUnloading)
    SpecializationUtil.registerFunction(vehicleType, "getIsAutomaticBaleUnloadingInProgress", BaleLoader.getIsAutomaticBaleUnloadingInProgress)
    SpecializationUtil.registerFunction(vehicleType, "getIsAutomaticBaleUnloadingAllowed", BaleLoader.getIsAutomaticBaleUnloadingAllowed)
    SpecializationUtil.registerFunction(vehicleType, "playBaleLoaderFoldingAnimation", BaleLoader.playBaleLoaderFoldingAnimation)
    SpecializationUtil.registerFunction(vehicleType, "getIsBaleLoaderFoldingPlaying", BaleLoader.getIsBaleLoaderFoldingPlaying)
    SpecializationUtil.registerFunction(vehicleType, "getCurrentFoldingAnimation", BaleLoader.getCurrentFoldingAnimation)
    SpecializationUtil.registerFunction(vehicleType, "updateFoldingAnimation", BaleLoader.updateFoldingAnimation)
    SpecializationUtil.registerFunction(vehicleType, "onBaleMoverBaleRemoved", BaleLoader.onBaleMoverBaleRemoved)
    SpecializationUtil.registerFunction(vehicleType, "addBaleUnloadTrigger", BaleLoader.addBaleUnloadTrigger)
    SpecializationUtil.registerFunction(vehicleType, "removeBaleUnloadTrigger", BaleLoader.removeBaleUnloadTrigger)
end
function BaleLoader.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", BaleLoader.getCanBeSelected)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowDynamicMountFillLevelInfo", BaleLoader.getAllowDynamicMountFillLevelInfo)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", BaleLoader.getAreControlledActionsAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIReadyToDrive", BaleLoader.getIsAIReadyToDrive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIPreparingToDrive", BaleLoader.getIsAIPreparingToDrive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", BaleLoader.getIsFoldAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", BaleLoader.getDoConsumePtoPower)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", BaleLoader.getConsumingLoad)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowerTakeOffActive", BaleLoader.getIsPowerTakeOffActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", BaleLoader.addToPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", BaleLoader.removeFromPhysics)
end
function BaleLoader.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", BaleLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", BaleLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", BaleLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", BaleLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", BaleLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", BaleLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", BaleLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", BaleLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", BaleLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", BaleLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", BaleLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", BaleLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onActivate", BaleLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", BaleLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", BaleLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", BaleLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", BaleLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onBalerUnloadingStarted", BaleLoader)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterAnimationValueTypes", BaleLoader)
end
function BaleLoader:onLoad(_)
    local spec = self.spec_baleLoader
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleloaderTurnedOnScrollers.baleloaderTurnedOnScroller", "vehicle.baleLoader.animationNodes.animationNode")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleGrabber", "vehicle.baleLoader.grabber")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.balePlaces", "vehicle.baleLoader.balePlaces")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.grabParticleSystem", "vehicle.baleLoader.grabber.grabParticleSystem")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader.grabber.grabParticleSystem", "vehicle.baleLoader.grabber.effectNode")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#pickupRange", "vehicle.baleLoader.grabber#pickupRange")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleTypes", "vehicle.baleLoader.baleTypes")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textTransportPosition", "vehicle.baleLoader.texts#transportPosition")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textOperatingPosition", "vehicle.baleLoader.texts#operatingPosition")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textUnload", "vehicle.baleLoader.texts#unload")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textTilting", "vehicle.baleLoader.texts#tilting")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textLowering", "vehicle.baleLoader.texts#lowering")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textLowerPlattform", "vehicle.baleLoader.texts#lowerPlattform")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textAbortUnloading", "vehicle.baleLoader.texts#abortUnloading")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textUnloadHere", "vehicle.baleLoader.texts#unloadHere")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#rotatePlatformAnimName", "vehicle.baleLoader.animations#rotatePlatform")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#rotatePlatformBackAnimName", "vehicle.baleLoader.animations#rotatePlatformBack")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#rotatePlatformEmptyAnimName", "vehicle.baleLoader.animations#rotatePlatformEmpty")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader.animations#grabberDropBaleReverseSpeed", "vehicle.baleLoader.animations.baleGrabber#dropBaleReverseSpeed")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader.animations#grabberDropToWork", "vehicle.baleLoader.animations.baleGrabber#dropToWork")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader.animations#rotatePlatform", "vehicle.baleLoader.animations.platform#rotate")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader.animations#rotatePlatformBack", "vehicle.baleLoader.animations.platform#rotateBack")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader.animations#rotatePlatformEmpty", "vehicle.baleLoader.animations.platform#rotateEmpty")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#moveBalePlacesAfterRotatePlatform", "vehicle.baleLoader.animations.moveBalePlaces#moveAfterRotatePlatform")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#moveBalePlacesMaxGrabberTime", "vehicle.baleLoader.animations.moveBalePlaces#maxGrabberTime")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#alwaysMoveBalePlaces", "vehicle.baleLoader.animations.moveBalePlaces#alwaysMove")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#resetEmptyRotateAnimation", "vehicle.baleLoader.animations.emptyRotate#reset")
    spec.balesToLoad = {}
    spec.balesToMount = {}
    spec.isInWorkPosition = false
    spec.grabberIsMoving = false
    spec.rotatePlatformDirection = 0
    spec.frontBalePusherDirection = 0
    spec.emptyState = BaleLoader.EMPTY_NONE
    spec.texts = {}
    spec.texts.transportPosition = self.xmlFile:getValue("vehicle.baleLoader.texts#transportPosition", "action_baleloaderTransportPosition", nil, self.customEnvironment)
    spec.texts.operatingPosition = self.xmlFile:getValue("vehicle.baleLoader.texts#operatingPosition", "action_baleloaderOperatingPosition", nil, self.customEnvironment)
    spec.texts.unload = self.xmlFile:getValue("vehicle.baleLoader.texts#unload", "action_baleloaderUnload", nil, self.customEnvironment)
    spec.texts.tilting = self.xmlFile:getValue("vehicle.baleLoader.texts#tilting", "info_baleloaderTiltingTable", nil, self.customEnvironment)
    spec.texts.lowering = self.xmlFile:getValue("vehicle.baleLoader.texts#lowering", "info_baleloaderLoweringTable", nil, self.customEnvironment)
    spec.texts.lowerPlattform = self.xmlFile:getValue("vehicle.baleLoader.texts#lowerPlattform", "action_baleloaderLowerPlatform", nil, self.customEnvironment)
    spec.texts.abortUnloading = self.xmlFile:getValue("vehicle.baleLoader.texts#abortUnloading", "action_baleloaderAbortUnloading", nil, self.customEnvironment)
    spec.texts.unloadHere = self.xmlFile:getValue("vehicle.baleLoader.texts#unloadHere", "action_baleloaderUnloadHere", nil, self.customEnvironment)
    spec.texts.baleNotSupported = self.xmlFile:getValue("vehicle.baleLoader.texts#baleNotSupported", "warning_baleNotSupported", nil, self.customEnvironment)
    spec.texts.baleDoNotAllowFillTypeMixing = self.xmlFile:getValue("vehicle.baleLoader.texts#baleDoNotAllowFillTypeMixing", "warning_baleDoNotAllowFillTypeMixing", nil, self.customEnvironment)
    spec.texts.onlyOneBaleTypeWarning = self.xmlFile:getValue("vehicle.baleLoader.texts#onlyOneBaleTypeWarning", "warning_baleLoaderOnlyAllowOnceSize", nil, self.customEnvironment)
    spec.texts.minUnloadingFillLevelWarning = self.xmlFile:getValue("vehicle.baleLoader.texts#minUnloadingFillLevelWarning", "warning_baleLoaderNotFullyLoaded", nil, self.customEnvironment)
    spec.texts.youDoNotOwnBale = g_i18n:getText("warning_youDontOwnThisItem")
    spec.transportPositionAfterUnloading = self.xmlFile:getValue("vehicle.baleLoader#transportPositionAfterUnloading", true)
    spec.useFoldingState = self.xmlFile:getValue("vehicle.baleLoader#useFoldingState", false)
    spec.useBalePlaceAsLoadPosition = self.xmlFile:getValue("vehicle.baleLoader#useBalePlaceAsLoadPosition", false)
    spec.balePlaceOffset = self.xmlFile:getValue("vehicle.baleLoader#balePlaceOffset", 0)
    spec.keepBaleRotationDuringLoad = self.xmlFile:getValue("vehicle.baleLoader#keepBaleRotationDuringLoad", false)
    spec.fullAutomaticUnloading = self.xmlFile:getValue("vehicle.baleLoader#fullAutomaticUnloading", false)
    spec.automaticUnloading = self.xmlFile:getValue("vehicle.baleLoader#automaticUnloading", spec.fullAutomaticUnloading)
    spec.minUnloadingFillLevel = self.xmlFile:getValue("vehicle.baleLoader#minUnloadingFillLevel", 1)
    spec.fillUnitIndex = self.xmlFile:getValue("vehicle.baleLoader#fillUnitIndex", 1)
    spec.allowKinematicMounting = self.xmlFile:getValue("vehicle.baleLoader#allowKinematicMounting", true)
    spec.consumePtoPower = self.xmlFile:getValue("vehicle.baleLoader#consumePtoPower", true)
    spec.dynamicMount = {}
    spec.dynamicMount.enabled = self.xmlFile:getValue("vehicle.baleLoader.dynamicMount#enabled", false)
    spec.dynamicMount.jointInterpolation = self.xmlFile:getValue("vehicle.baleLoader.dynamicMount#doInterpolation", false)
    spec.dynamicMount.jointInterpolationTimeRot = self.xmlFile:getValue("vehicle.baleLoader.dynamicMount#interpolationTimeRot", 1)
    spec.dynamicMount.jointInterpolationSpeedTrans = self.xmlFile:getValue("vehicle.baleLoader.dynamicMount#interpolationSpeedTrans", 0.1) / 1000
    spec.dynamicMount.baleJointsToUpdate = {}
    spec.dynamicMount.minTransLimits = self.xmlFile:getValue("vehicle.baleLoader.dynamicMount#minTransLimits", nil, true)
    spec.dynamicMount.maxTransLimits = self.xmlFile:getValue("vehicle.baleLoader.dynamicMount#maxTransLimits", nil, true)
    spec.dynamicMount.baleMassDirty = false
    spec.dynamicBaleUnloading = {}
    spec.dynamicBaleUnloading.enabled = self.xmlFile:getValue("vehicle.baleLoader.dynamicBaleUnloading#enabled", false)
    spec.dynamicBaleUnloading.connectedRows = {}
    local connectedRows = self.xmlFile:getValue("vehicle.baleLoader.dynamicBaleUnloading#connectedRows", nil, true)
    if connectedRows ~= nil then
        local i = 1
        for i = i, #connectedRows do
            spec.dynamicBaleUnloading.connectedRows[connectedRows[i]] = true
        end
    end
    local function getConnectedRows(key)
        -- upvalues: (copy) self
        local connections = {}
        local connectedRowStartsStr = self.xmlFile:getValue(key)
        if connectedRowStartsStr ~= nil then
            local connectedRowStartsParts = string.split(connectedRowStartsStr, " ")
            local i = 1
            for i = i, #connectedRowStartsParts do
                local subParts = string.split(connectedRowStartsParts[i], "-")
                if #subParts == 2 then
                    table.insert(connections, { tonumber(subParts[1]), (tonumber(subParts[2])) })
                else
                    Logging.xmlWarning(self.xmlFile, "Unknown row connection \'%s\' in \'%s\' (should look like \'1-2 3-4\')", connectedRowStartsParts[i], key)
                end
            end
        end
        return connections
    end
    spec.dynamicBaleUnloading.interConnectedRowStarts = getConnectedRows("vehicle.baleLoader.dynamicBaleUnloading#interConnectedRowStarts")
    spec.dynamicBaleUnloading.interConnectedRowEnds = getConnectedRows("vehicle.baleLoader.dynamicBaleUnloading#interConnectedRowEnds")
    spec.dynamicBaleUnloading.widthOffset = self.xmlFile:getValue("vehicle.baleLoader.dynamicBaleUnloading#widthOffset", 0.05)
    spec.dynamicBaleUnloading.heightOffset = self.xmlFile:getValue("vehicle.baleLoader.dynamicBaleUnloading#heightOffset", 0.05)
    spec.dynamicBaleUnloading.diameterOffset = self.xmlFile:getValue("vehicle.baleLoader.dynamicBaleUnloading#diameterOffset", 0.05)
    spec.dynamicBaleUnloading.rowConnectionRotLimit = self.xmlFile:getValue("vehicle.baleLoader.dynamicBaleUnloading#rowConnectionRotLimit", 4)
    spec.dynamicBaleUnloading.rowInterConnectionRotLimit = self.xmlFile:getValue("vehicle.baleLoader.dynamicBaleUnloading#rowInterConnectionRotLimit", 1)
    spec.dynamicBaleUnloading.releaseAnimation = self.xmlFile:getValue("vehicle.baleLoader.dynamicBaleUnloading.releaseAnimation#name")
    spec.dynamicBaleUnloading.releaseAnimationTime = self.xmlFile:getValue("vehicle.baleLoader.dynamicBaleUnloading.releaseAnimation#time", 1)
    spec.dynamicBaleUnloading.useUnloadingMoverTrigger = self.xmlFile:getValue("vehicle.baleLoader.dynamicBaleUnloading.releaseAnimation#useUnloadingMoverTrigger", false)
    spec.baleGrabber = {}
    spec.baleGrabber.grabNode = self.xmlFile:getValue("vehicle.baleLoader.grabber#grabNode", nil, self.components, self.i3dMappings)
    spec.baleGrabber.pickupRange = self.xmlFile:getValue("vehicle.baleLoader.grabber#pickupRange", 3)
    spec.baleGrabber.balesInTrigger = {}
    spec.baleGrabber.trigger = self.xmlFile:getValue("vehicle.baleLoader.grabber#triggerNode", nil, self.components, self.i3dMappings)
    if spec.baleGrabber.trigger == nil then
        Logging.xmlError(self.xmlFile, "Bale grabber needs a valid trigger!")
    else
        addTrigger(spec.baleGrabber.trigger, "baleGrabberTriggerCallback", self)
        g_currentMission:addNodeObject(spec.baleGrabber.trigger, self)
    end
    if self.isClient then
        local grabParticleSystem = {}
        if ParticleUtil.loadParticleSystem(self.xmlFile, grabParticleSystem, "vehicle.baleLoader.grabber.grabParticleSystem", self.components, false, nil, self.baseDirectory) then
            spec.grabParticleSystem = grabParticleSystem
            spec.grabParticleSystemDisableTime = 0
        end
        spec.grabberEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.baleLoader.grabber", self.components, self, self.i3dMappings)
        spec.grabberEffectDisableDuration = self.xmlFile:getValue("vehicle.baleLoader.grabber#effectDisableDuration", 0.6)
        spec.grabberEffectDisableTime = 0
        spec.samples = {}
        spec.samples.grab = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.baleLoader.sounds", "grab", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.emptyRotate = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.baleLoader.sounds", "emptyRotate", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.baleLoader.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.unload = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.baleLoader.sounds", "unload", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    spec.defaultAnimations = {}
    self:loadBaleLoaderAnimationsFromXML(self.xmlFile, "vehicle.baleLoader", spec.defaultAnimations)
    spec.animations = spec.defaultAnimations.animations
    spec.defaultBalePlace = {}
    spec.useSharedBalePlaces = false
    if self:loadBalePlacesFromXML(self.xmlFile, "vehicle.baleLoader", spec.defaultBalePlace) then
        spec.useSharedBalePlaces = true
    end
    spec.startBalePlace = spec.defaultBalePlace.startBalePlace
    spec.balePlaces = spec.defaultBalePlace.balePlaces
    spec.baleTypes = {}
    local grabParticleSystem = 0
    while true do
        local i = string.format("%s.baleTypes.baleType(%d)", "vehicle.baleLoader", grabParticleSystem)
        if not self.xmlFile:hasProperty(i) then
            break
        end
        local entry = {}
        if self:loadBaleTypeFromXML(self.xmlFile, i, entry) then
            entry.index = grabParticleSystem + 1
            table.insert(spec.baleTypes, entry)
        end
        grabParticleSystem = grabParticleSystem + 1
    end
    if #spec.baleTypes == 0 then
        Logging.xmlError(self.xmlFile, "No bale types defined for baleLoader!")
    else
        if spec.startBalePlace == nil then
            spec.startBalePlace = spec.baleTypes[1].startBalePlace
        end
        if spec.balePlaces == nil then
            spec.balePlaces = spec.baleTypes[1].balePlaces
        end
        if spec.startBalePlace == nil then
            Logging.xmlError(self.xmlFile, "Could not find startBalePlace for baleLoader!")
        end
        if spec.balePlaces == nil then
            Logging.xmlError(self.xmlFile, "Could not find bale places for baleLoader!")
        end
    end
    self:setBaleLoaderBaleType(1)
    spec.foldingAnimations = {}
    local grabParticleSystem = 0
    while true do
        local i = string.format("%s.foldingAnimations.foldingAnimation(%d)", "vehicle.baleLoader", grabParticleSystem)
        if not self.xmlFile:hasProperty(i) then
            break
        end
        local entry = {
            ["name"] = self.xmlFile:getValue(i .. "#name"),
            ["baleTypeIndex"] = self.xmlFile:getValue(i .. "#baleTypeIndex", 0),
            ["minFillLevel"] = self.xmlFile:getValue(i .. "#minFillLevel", -math.huge),
            ["maxFillLevel"] = self.xmlFile:getValue(i .. "#maxFillLevel", math.huge),
            ["minBalePlace"] = self.xmlFile:getValue(i .. "#minBalePlace", -math.huge),
            ["maxBalePlace"] = self.xmlFile:getValue(i .. "#maxBalePlace", math.huge)
        }
        if self:getAnimationExists(entry.name) then
            table.insert(spec.foldingAnimations, entry)
        else
            Logging.xmlWarning(self.xmlFile, "Unknown folding animation \'%s\' in \'%s\'", entry.name, i)
        end
        grabParticleSystem = grabParticleSystem + 1
    end
    local i = #spec.foldingAnimations > 0
    spec.hasMultipleFoldingAnimations = i
    spec.lastFoldingAnimation = spec.animations.baleGrabberTransportToWork
    self:updateFoldingAnimation()
    spec.unloadingMover = {}
    spec.unloadingMover.trigger = self.xmlFile:getValue("vehicle.baleLoader.unloadingMoverNodes#trigger", nil, self.components, self.i3dMappings)
    if spec.unloadingMover.trigger ~= nil then
        addTrigger(spec.unloadingMover.trigger, "baleLoaderMoveTriggerCallback", self)
        g_currentMission:addNodeObject(spec.unloadingMover.trigger, self)
    end
    spec.unloadingMover.isActive = false
    spec.unloadingMover.dirtyFlag = self:getNextDirtyFlag()
    spec.unloadingMover.frameDelay = 0
    spec.unloadingMover.balesInTrigger = {}
    spec.unloadingMover.nodes = {}
    spec.unloadingMover.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.baleLoader.unloadingMoverNodes.animationNodes", self.components, self, self.i3dMappings)
    local grabParticleSystem = 0
    while true do
        local i = string.format("%s.unloadingMoverNodes.unloadingMoverNode(%d)", "vehicle.baleLoader", grabParticleSystem)
        if not self.xmlFile:hasProperty(i) then
            break
        end
        local entry = {
            ["node"] = self.xmlFile:getValue(i .. "#node", nil, self.components, self.i3dMappings),
            ["speed"] = self.xmlFile:getValue(i .. "#speed", -1)
        }
        if entry.node == nil then
            Logging.xmlWarning(self.xmlFile, "Unknown node in \'%s\'", i)
        else
            table.insert(spec.unloadingMover.nodes, entry)
        end
        grabParticleSystem = grabParticleSystem + 1
    end
    spec.balePacker = {}
    spec.balePacker.node = self.xmlFile:getValue("vehicle.baleLoader.balePacker#node", nil, self.components, self.i3dMappings)
    spec.balePacker.filename = self.xmlFile:getValue("vehicle.baleLoader.balePacker#packedFilename")
    if spec.balePacker.filename ~= nil then
        spec.balePacker.filename = Utils.getFilename(spec.balePacker.filename, self.baseDirectory)
        if spec.balePacker.filename ~= nil and not fileExists(spec.balePacker.filename) then
            Logging.xmlError(self.xmlFile, "Unable to find packed bale \'%s\'", spec.balePacker.filename)
        end
    end
    spec.synchronizationNumBitsPosition = self.xmlFile:getValue("vehicle.baleLoader.synchronization#numBitsPosition", 10)
    spec.synchronizationMaxPosition = self.xmlFile:getValue("vehicle.baleLoader.synchronization#maxPosition", 3)
    spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.baleLoader.animationNodes", self.components, self, self.i3dMappings)
    spec.animationNodesBlocked = false
    spec.showBaleNotSupportedWarning = false
    spec.baleNotSupportedWarning = nil
    spec.automaticUnloadingInProgress = false
    spec.automaticUnloadingAdditionalBalesToLoad = -1
    spec.lastPickupAutomatedUnloadingDelayTime = 15000
    spec.lastPickupTime = -spec.lastPickupAutomatedUnloadingDelayTime
    spec.kinematicMountedBales = {}
    spec.baleUnloadTriggers = {}
    spec.baleJoints = {}
end
function BaleLoader:onPostLoad(savegame)
    if savegame ~= nil then
        local spec = self.spec_baleLoader
        local baleTypeIndex = savegame.xmlFile:getValue(savegame.key .. ".baleLoader#baleTypeIndex")
        if baleTypeIndex ~= nil then
            self:setBaleLoaderBaleType(baleTypeIndex, true)
        end
        if spec.hasMultipleFoldingAnimations and not savegame.resetVehicles then
            spec.lastFoldingAnimation = savegame.xmlFile:getValue(savegame.key .. ".baleLoader#lastFoldingAnimation", spec.lastFoldingAnimation)
        end
        if savegame.xmlFile:getValue(savegame.key .. ".baleLoader#isInWorkPosition", false) then
            if not spec.isInWorkPosition then
                spec.grabberIsMoving = true
                spec.isInWorkPosition = true
                BaleLoader.moveToWorkPosition(self, true)
            end
        else
            BaleLoader.moveToTransportPosition(self)
        end
        spec.startBalePlace.current = 1
        spec.startBalePlace.count = 0
        local numBales = 0
        if not savegame.resetVehicles then
            local i = 0
            while true do
                local baleKey = savegame.key .. string.format(".baleLoader.bale(%d)", i)
                if not savegame.xmlFile:hasProperty(baleKey) then
                    break
                end
                local filename = savegame.xmlFile:getValue(baleKey .. "#filename")
                if filename ~= nil then
                    local translation = NetworkUtil.convertFromNetworkFilename(filename)
                    local translation = savegame.xmlFile:getValue(baleKey .. "#position", nil, true)
                    local rotation = savegame.xmlFile:getValue(baleKey .. "#rotation", nil, true)
                    local balePlace = savegame.xmlFile:getValue(baleKey .. "#balePlace")
                    local helper = savegame.xmlFile:getValue(baleKey .. "#helper")
                    if balePlace == nil or balePlace > 0 and (translation == nil or rotation == nil) or balePlace < 1 and helper == nil then
                        printWarning("Warning: Corrupt savegame, bale " .. translation .. " could not be loaded")
                    else
                        if balePlace <= 0 then
                            translation = { 0, 0, 0 }
                            rotation = { 0, 0, 0 }
                        end
                        local parentNode = nil
                        local bales = nil
                        if balePlace < 1 then
                            if spec.startBalePlace.node ~= nil and helper <= spec.startBalePlace.numOfPlaces then
                                parentNode = getChildAt(spec.startBalePlace.node, helper - 1)
                                if spec.startBalePlace.bales == nil then
                                    spec.startBalePlace.bales = {}
                                end
                                bales = spec.startBalePlace.bales
                                spec.startBalePlace.count = spec.startBalePlace.count + 1
                            end
                        elseif balePlace <= #spec.balePlaces then
                            spec.startBalePlace.current = math.max(spec.startBalePlace.current, balePlace + 1)
                            parentNode = spec.balePlaces[balePlace].node
                            if spec.balePlaces[balePlace].bales == nil then
                                spec.balePlaces[balePlace].bales = {}
                            end
                            bales = spec.balePlaces[balePlace].bales
                        end
                        if parentNode ~= nil then
                            local attributes = {}
                            Bale.loadBaleAttributesFromXMLFile(attributes, savegame.xmlFile, baleKey, savegame.resetVehicles)
                            table.insert(spec.balesToLoad, {
                                ["parentNode"] = parentNode,
                                ["filename"] = translation,
                                ["bales"] = bales,
                                ["translation"] = translation,
                                ["rotation"] = rotation,
                                ["attributes"] = attributes
                            })
                        end
                    end
                end
                i = i + 1
            end
        end
        self:updateFoldingAnimation()
        BaleLoader.updateBalePlacesAnimations(self)
    end
end
function BaleLoader:onLoadFinished(_)
    local spec = self.spec_baleLoader
    for k, v in pairs(spec.balesToLoad) do
        local baleObject = Bale.new(self.isServer, self.isClient)
        local y = v.translation
        local x, y, z = unpack(y)
        local ry = v.rotation
        local rx, ry, rz = unpack(ry)
        if baleObject:loadFromConfigXML(v.filename, x, y, z, rx, ry, rz, v.attributes.uniqueId) then
            baleObject:applyBaleAttributes(v.attributes)
            baleObject:register()
            if spec.dynamicMount.enabled then
                self:mountDynamicBale(baleObject, v.parentNode)
            else
                self:mountBale(baleObject, self, v.parentNode, x, y, z, rx, ry, rz)
            end
            baleObject:setCanBeSold(false)
            table.insert(v.bales, NetworkUtil.getObjectId(baleObject))
        end
        spec.balesToLoad[k] = nil
    end
end
function BaleLoader:onDelete()
    local spec = self.spec_baleLoader
    if spec.balePlaces ~= nil then
        for _, balePlace in pairs(spec.balePlaces) do
            if balePlace.bales ~= nil then
                for _, baleServerId in pairs(balePlace.bales) do
                    local bale = NetworkUtil.getObject(baleServerId)
                    if bale ~= nil then
                        if spec.dynamicMount.enabled then
                            self:unmountDynamicBale(bale)
                        else
                            self:unmountBale(bale)
                        end
                        bale:setCanBeSold(true)
                        if self.isReconfigurating ~= nil and self.isReconfigurating then
                            bale:delete()
                        end
                    end
                end
            end
        end
    end
    if spec.startBalePlace ~= nil then
        for _, balePlace in ipairs(spec.startBalePlace.bales) do
            local bale = NetworkUtil.getObject(balePlace)
            if bale ~= nil then
                if spec.dynamicMount.enabled then
                    self:unmountDynamicBale(bale)
                else
                    self:unmountBale(bale)
                end
                bale:setCanBeSold(true)
                if self.isReconfigurating ~= nil and self.isReconfigurating then
                    bale:delete()
                end
            end
        end
    end
    if spec.baleGrabber ~= nil then
        if spec.baleGrabber.currentBale ~= nil then
            local bale = NetworkUtil.getObject(spec.baleGrabber.currentBale)
            if bale ~= nil then
                if spec.dynamicMount.enabled then
                    self:unmountDynamicBale(bale)
                else
                    self:unmountBale(bale)
                end
                bale:setCanBeSold(true)
            end
        end
        if spec.baleGrabber.trigger ~= nil then
            removeTrigger(spec.baleGrabber.trigger)
            g_currentMission:removeNodeObject(spec.baleGrabber.trigger)
        end
    end
    if spec.unloadingMover ~= nil then
        if spec.unloadingMover.trigger ~= nil then
            removeTrigger(spec.unloadingMover.trigger)
            g_currentMission:removeNodeObject(spec.unloadingMover.trigger)
        end
        if spec.unloadingMover.balesInTrigger ~= nil then
            for _, balePlace in pairs(spec.unloadingMover.balesInTrigger) do
                if _.removeDeleteListener ~= nil then
                    _:removeDeleteListener(self, "onBaleMoverBaleRemoved")
                end
            end
            table.clear(spec.unloadingMover.balesInTrigger)
        end
        g_animationManager:deleteAnimations(spec.unloadingMover.animationNodes)
    end
    if spec.baleUnloadTriggers ~= nil then
        for _, balePlace in pairs(spec.baleUnloadTriggers) do
            if _.removeDeleteListener ~= nil then
                _:removeDeleteListener(self, BaleLoader.onBaleUnloadTriggerDeleted)
            end
        end
        table.clear(spec.baleUnloadTriggers)
    end
    g_effectManager:deleteEffects(spec.grabberEffects)
    g_soundManager:deleteSamples(spec.samples)
    g_animationManager:deleteAnimations(spec.animationNodes)
end
function BaleLoader:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_baleLoader
    xmlFile:setValue(key .. "#isInWorkPosition", spec.isInWorkPosition)
    if spec.currentBaleType ~= nil then
        xmlFile:setValue(key .. "#baleTypeIndex", spec.currentBaleType.index)
    end
    local baleIndex = 0
    for i, balePlace in pairs(spec.balePlaces) do
        if balePlace.bales ~= nil then
            for _, baleServerId in pairs(balePlace.bales) do
                local bale = NetworkUtil.getObject(baleServerId)
                if bale ~= nil then
                    local baleKey = string.format("%s.bale(%d)", key, baleIndex)
                    bale:saveToXMLFile(xmlFile, baleKey)
                    local loadPlaceEmpty = self:getFillUnitFillLevel(spec.fillUnitIndex) % spec.startBalePlace.numOfPlaces ~= 0
                    local lastItem = math.floor(self:getFillUnitFillLevel(spec.fillUnitIndex) / spec.startBalePlace.numOfPlaces) + 1 == i
                    local evenCapacity = self:getFillUnitCapacity(spec.fillUnitIndex) % 2 == 0
                    if #spec.startBalePlace.bales == 0 and (loadPlaceEmpty and (lastItem and evenCapacity)) then
                        xmlFile:setValue(baleKey .. "#balePlace", 0)
                        xmlFile:setValue(baleKey .. "#helper", 1)
                    else
                        xmlFile:setValue(baleKey .. "#balePlace", i)
                    end
                    baleIndex = baleIndex + 1
                end
            end
        end
    end
    for i, balePlace in ipairs(spec.startBalePlace.bales) do
        local bale = NetworkUtil.getObject(balePlace)
        if bale ~= nil then
            local baleKey = string.format("%s.bale(%d)", key, baleIndex)
            bale:saveToXMLFile(xmlFile, baleKey)
            xmlFile:setValue(baleKey .. "#balePlace", 0)
            xmlFile:setValue(baleKey .. "#helper", i)
            baleIndex = baleIndex + 1
        end
    end
    if spec.hasMultipleFoldingAnimations and spec.lastFoldingAnimation ~= nil then
        xmlFile:setValue(key .. "#lastFoldingAnimation", spec.lastFoldingAnimation)
    end
    if spec.baleGrabber.currentBale ~= nil then
        local bale = NetworkUtil.getObject(spec.baleGrabber.currentBale)
        if bale ~= nil then
            self:unmountBale(bale)
            spec.baleGrabber.currentBaleIsUnmounted = true
        end
    end
end
function BaleLoader:onReadStream(streamId, _)
    local spec = self.spec_baleLoader
    spec.isInWorkPosition = streamReadBool(streamId)
    spec.frontBalePusherDirection = streamReadIntN(streamId, 3)
    spec.rotatePlatformDirection = streamReadIntN(streamId, 3)
    if streamReadBool(streamId) then
        self:setBaleLoaderBaleType((streamReadIntN(streamId, 6)))
    end
    if spec.isInWorkPosition then
        BaleLoader.moveToWorkPosition(self)
    end
    local currentBaleTypeIndex = streamReadUIntN(streamId, 4)
    spec.startBalePlace.current = streamReadInt8(streamId)
    if streamReadBool(streamId) then
        spec.baleGrabber.currentBale = NetworkUtil.readNodeObjectId(streamId)
        spec.balesToMount[spec.baleGrabber.currentBale] = {
            ["serverId"] = spec.baleGrabber.currentBale,
            ["linkNode"] = spec.baleGrabber.grabNode,
            ["trans"] = { 0, 0, 0 },
            ["rot"] = { 0, 0, 0 }
        }
    end
    spec.startBalePlace.count = streamReadUInt8(streamId)
    local i = 1
    for i = i, spec.startBalePlace.count do
        local baleServerId = NetworkUtil.readNodeObjectId(streamId)
        spec.balesToMount[baleServerId] = {
            ["serverId"] = baleServerId,
            ["linkNode"] = getChildAt(spec.startBalePlace.node, i - 1),
            ["trans"] = { 0, 0, 0 },
            ["rot"] = { 0, 0, 0 }
        }
        table.insert(spec.startBalePlace.bales, baleServerId)
        self:updateFoldingAnimation()
    end
    local i = 1
    for i = i, #spec.balePlaces do
        local baleServerId = spec.balePlaces[i]
        local attachNode = streamReadUInt8(streamId)
        if attachNode > 0 then
            baleServerId.bales = {}
            for _ = 1, attachNode do
                local baleServerId = NetworkUtil.readNodeObjectId(streamId)
                local x = 0
                local y = 0
                local z = 0
                if not spec.dynamicMount.enabled then
                    local maxValue = 2 ^ spec.synchronizationNumBitsPosition - 1
                    x = streamReadUIntN(streamId, spec.synchronizationNumBitsPosition) / maxValue * (spec.synchronizationMaxPosition * 2) - spec.synchronizationMaxPosition
                    y = streamReadUIntN(streamId, spec.synchronizationNumBitsPosition) / maxValue * (spec.synchronizationMaxPosition * 2) - spec.synchronizationMaxPosition
                    z = streamReadUIntN(streamId, spec.synchronizationNumBitsPosition) / maxValue * (spec.synchronizationMaxPosition * 2) - spec.synchronizationMaxPosition
                end
                table.insert(baleServerId.bales, baleServerId)
                spec.balesToMount[baleServerId] = {
                    ["serverId"] = baleServerId,
                    ["linkNode"] = baleServerId.node,
                    ["trans"] = { x, y, z },
                    ["rot"] = { 0, 0, 0 }
                }
            end
        end
    end
    BaleLoader.updateBalePlacesAnimations(self)
    if BaleLoader.EMPTY_TO_WORK <= currentBaleTypeIndex then
        self:doStateChange(BaleLoader.CHANGE_EMPTY_START)
        AnimatedVehicle.updateAnimations(self, 99999999, true)
        if BaleLoader.EMPTY_ROTATE_PLATFORM <= currentBaleTypeIndex then
            self:doStateChange(BaleLoader.CHANGE_EMPTY_ROTATE_PLATFORM)
            AnimatedVehicle.updateAnimations(self, 99999999, true)
            if BaleLoader.EMPTY_ROTATE1 <= currentBaleTypeIndex then
                self:doStateChange(BaleLoader.CHANGE_EMPTY_ROTATE1)
                AnimatedVehicle.updateAnimations(self, 99999999, true)
                if BaleLoader.EMPTY_CLOSE_GRIPPERS <= currentBaleTypeIndex then
                    self:doStateChange(BaleLoader.CHANGE_EMPTY_CLOSE_GRIPPERS)
                    AnimatedVehicle.updateAnimations(self, 99999999, true)
                    if BaleLoader.EMPTY_HIDE_PUSHER1 <= currentBaleTypeIndex then
                        self:doStateChange(BaleLoader.CHANGE_EMPTY_HIDE_PUSHER1)
                        AnimatedVehicle.updateAnimations(self, 99999999, true)
                        if BaleLoader.EMPTY_HIDE_PUSHER2 <= currentBaleTypeIndex then
                            self:doStateChange(BaleLoader.CHANGE_EMPTY_HIDE_PUSHER2)
                            AnimatedVehicle.updateAnimations(self, 99999999, true)
                            if BaleLoader.EMPTY_ROTATE2 <= currentBaleTypeIndex then
                                self:doStateChange(BaleLoader.CHANGE_EMPTY_ROTATE2)
                                AnimatedVehicle.updateAnimations(self, 99999999, true)
                                if BaleLoader.EMPTY_WAIT_TO_DROP <= currentBaleTypeIndex then
                                    self:doStateChange(BaleLoader.CHANGE_EMPTY_WAIT_TO_DROP)
                                    AnimatedVehicle.updateAnimations(self, 99999999, true)
                                    if currentBaleTypeIndex == BaleLoader.EMPTY_CANCEL or currentBaleTypeIndex == BaleLoader.EMPTY_WAIT_TO_REDO then
                                        self:doStateChange(BaleLoader.CHANGE_EMPTY_CANCEL)
                                        AnimatedVehicle.updateAnimations(self, 99999999, true)
                                        if currentBaleTypeIndex == BaleLoader.EMPTY_WAIT_TO_REDO then
                                            self:doStateChange(BaleLoader.CHANGE_EMPTY_WAIT_TO_REDO)
                                            AnimatedVehicle.updateAnimations(self, 99999999, true)
                                        end
                                    elseif currentBaleTypeIndex == BaleLoader.EMPTY_WAIT_TO_SINK or currentBaleTypeIndex == BaleLoader.EMPTY_SINK then
                                        self:doStateChange(BaleLoader.CHANGE_DROP_BALES)
                                        AnimatedVehicle.updateAnimations(self, 99999999, true)
                                        if currentBaleTypeIndex == BaleLoader.EMPTY_SINK then
                                            self:doStateChange(BaleLoader.CHANGE_SINK)
                                            AnimatedVehicle.updateAnimations(self, 99999999, true)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    spec.emptyState = currentBaleTypeIndex
end
function BaleLoader:onWriteStream(streamId, _)
    local spec = self.spec_baleLoader
    streamWriteBool(streamId, spec.isInWorkPosition)
    streamWriteIntN(streamId, spec.frontBalePusherDirection, 3)
    streamWriteIntN(streamId, spec.rotatePlatformDirection, 3)
    local i = spec.currentBaleType ~= nil
    if streamWriteBool(streamId, i) then
        streamWriteIntN(streamId, spec.currentBaleType.index or 1, 6)
    end
    streamWriteUIntN(streamId, spec.emptyState, 4)
    streamWriteInt8(streamId, spec.startBalePlace.current)
    local i = spec.baleGrabber.currentBale ~= nil
    if streamWriteBool(streamId, i) then
        NetworkUtil.writeNodeObjectId(streamId, spec.baleGrabber.currentBale)
    end
    streamWriteUInt8(streamId, spec.startBalePlace.count)
    local i = 1
    for i = i, spec.startBalePlace.count do
        NetworkUtil.writeNodeObjectId(streamId, spec.startBalePlace.bales[i])
    end
    local i = 1
    for i = i, #spec.balePlaces do
        local baleServerId = spec.balePlaces[i]
        local numBales = baleServerId.bales ~= nil and #baleServerId.bales or 0
        streamWriteUInt8(streamId, numBales)
        if baleServerId.bales ~= nil then
            local baleI = 1
            for baleI = baleI, numBales do
                local baleServerId = baleServerId.bales[baleI]
                local nodeId = NetworkUtil.getObject(baleServerId).nodeId
                local x, y, z = getTranslation(nodeId)
                NetworkUtil.writeNodeObjectId(streamId, baleServerId)
                if not spec.dynamicMount.enabled then
                    if math.abs(x) > spec.synchronizationMaxPosition or (math.abs(y) > spec.synchronizationMaxPosition or math.abs(z) > spec.synchronizationMaxPosition) then
                        Logging.xmlWarning(self.xmlFile, "Position of bale \'%d\' could not be synchronized correctly. Position out of range (%.2f, %.2f, %.2f) > %.2f. Increase \'vehicle.baleLoader.synchronization#maxPosition\'", baleI, x, y, z, spec.synchronizationMaxPosition)
                    end
                    local maxValue = 2 ^ spec.synchronizationNumBitsPosition - 1
                    streamWriteUIntN(streamId, (spec.synchronizationMaxPosition + x) / (spec.synchronizationMaxPosition * 2) * maxValue, spec.synchronizationNumBitsPosition)
                    streamWriteUIntN(streamId, (spec.synchronizationMaxPosition + y) / (spec.synchronizationMaxPosition * 2) * maxValue, spec.synchronizationNumBitsPosition)
                    streamWriteUIntN(streamId, (spec.synchronizationMaxPosition + z) / (spec.synchronizationMaxPosition * 2) * maxValue, spec.synchronizationNumBitsPosition)
                end
            end
        end
    end
end
function BaleLoader:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() and streamReadBool(streamId) then
        local moverActive = streamReadBool(streamId)
        if moverActive ~= self.spec_baleLoader.unloadingMover.isActive then
            if moverActive then
                g_animationManager:startAnimations(spec.unloadingMover.animationNodes)
                g_soundManager:playSample(spec.samples.unload)
            else
                g_animationManager:stopAnimations(spec.unloadingMover.animationNodes)
                g_soundManager:stopSample(spec.samples.unload)
            end
            spec.unloadingMover.isActive = moverActive
        end
    end
end
function BaleLoader:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.spec_baleLoader.unloadingMover.dirtyFlag) ~= 0) then
            streamWriteBool(streamId, spec.unloadingMover.isActive)
        end
    end
end
function BaleLoader:updateBalePlacesAnimations()
    local spec = self.spec_baleLoader
    if spec.startBalePlace ~= nil and spec.startBalePlace.current > spec.startBalePlace.numOfPlaces or spec.animations.moveBalePlacesAfterRotatePlatform and spec.startBalePlace.current > 1 then
        local numBalePlaces = #spec.balePlaces
        local delta = spec.animations.moveBalePlacesAfterRotatePlatform and not (spec.animations.moveBalePlacesAlways or spec.useBalePlaceAsLoadPosition) and 0 or 1
        if spec.useBalePlaceAsLoadPosition then
        end
        self:playAnimation(spec.animations.moveBalePlaces, 1, 0, true)
        self:setAnimationStopTime(spec.animations.moveBalePlaces, (math.min((spec.startBalePlace.current - delta) / numBalePlaces, 1)))
        AnimatedVehicle.updateAnimations(self, 99999999, true)
    end
    if spec.startBalePlace ~= nil and spec.startBalePlace.count >= 1 then
        self:playAnimation(spec.animations.balesToOtherRow, 20, nil, true)
        AnimatedVehicle.updateAnimations(self, 99999999, true)
        if spec.startBalePlace.count >= spec.startBalePlace.numOfPlaces then
            BaleLoader.rotatePlatform(self)
        end
    end
end
function BaleLoader:onUpdate(_, _, _, _)
    local spec = self.spec_baleLoader
    if self.finishedFirstUpdate then
        for k, baleToMount in pairs(spec.balesToMount) do
            local bale = NetworkUtil.getObject(baleToMount.serverId)
            if bale ~= nil then
                local y = baleToMount.trans
                local x, y, z = unpack(y)
                local ry = baleToMount.rot
                local rx, ry, rz = unpack(ry)
                if spec.dynamicMount.enabled then
                    self:mountDynamicBale(bale, baleToMount.linkNode)
                else
                    self:mountBale(bale, self, baleToMount.linkNode, x, y, z, rx, ry, rz)
                end
                local baleType = self:getBaleTypeByBale(bale)
                if baleType ~= nil then
                    self:setBaleLoaderBaleType(baleType.index)
                end
                spec.balesToMount[k] = nil
            end
        end
    end
    if self.isClient and (spec.grabberEffectDisableTime ~= 0 and spec.grabberEffectDisableTime < g_currentMission.time) then
        g_effectManager:stopEffects(spec.grabberEffects)
        spec.grabberEffectDisableTime = 0
    end
    if spec.grabberIsMoving and not self:getIsBaleLoaderFoldingPlaying() then
        spec.grabberIsMoving = false
    end
    spec.showBaleNotSupportedWarning = false
    if self:getIsBaleGrabbingAllowed() and (spec.baleGrabber.grabNode ~= nil and spec.baleGrabber.currentBale == nil) then
        local nearestBale, nearestBaleType, warning = BaleLoader.getBaleInRange(self, spec.baleGrabber.grabNode, spec.baleGrabber.balesInTrigger)
        if nearestBale ~= nil then
            if nearestBaleType == nil then
                spec.showBaleNotSupportedWarning = true
                spec.baleNotSupportedWarning = warning
            elseif self.isServer then
                self:pickupBale(nearestBale, nearestBaleType)
            end
        end
    end
    if self.isServer then
        if spec.grabberMoveState ~= nil then
            if spec.grabberMoveState == BaleLoader.GRAB_MOVE_UP then
                if not self:getIsAnimationPlaying(spec.animations.baleGrabberWorkToDrop) then
                    g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_GRAB_MOVE_UP), true, nil, self)
                end
            elseif spec.grabberMoveState == BaleLoader.GRAB_DROP_BALE then
                if not self:getIsAnimationPlaying(spec.currentBaleGrabberDropBaleAnimName) then
                    g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_GRAB_DROP_BALE), true, nil, self)
                end
            elseif spec.grabberMoveState == BaleLoader.GRAB_MOVE_DOWN and not self:getIsAnimationPlaying(spec.animations.baleGrabberDropToWork or spec.animations.baleGrabberWorkToDrop) then
                g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_GRAB_MOVE_DOWN), true, nil, self)
                self:setAnimationTime(spec.currentBaleGrabberDropBaleAnimName, 0, false)
                self:setAnimationTime(spec.animations.baleGrabberWorkToDrop, 0, false)
            end
        end
        if spec.frontBalePusherDirection ~= 0 and not self:getIsAnimationPlaying(spec.animations.frontBalePusher) then
            g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_FRONT_PUSHER), true, nil, self)
        end
        if spec.rotatePlatformDirection ~= 0 then
            local nearestBale = spec.animations.rotatePlatform
            if spec.rotatePlatformDirection < 0 then
                nearestBale = spec.animations.rotatePlatformBack
            end
            if not (self:getIsAnimationPlaying(nearestBale) or (self:getIsAnimationPlaying(spec.animations.moveBalePlacesExtrasOnce) or spec.moveBalePlacesDelayedMovement)) then
                g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_ROTATE_PLATFORM), true, nil, self)
            end
        end
        if spec.emptyState ~= BaleLoader.EMPTY_NONE then
            if spec.emptyState == BaleLoader.EMPTY_TO_WORK then
                if not self:getIsBaleLoaderFoldingPlaying() then
                    g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_ROTATE_PLATFORM), true, nil, self)
                end
            elseif spec.emptyState == BaleLoader.EMPTY_ROTATE_PLATFORM then
                if not self:getIsAnimationPlaying(spec.animations.rotatePlatformEmpty) then
                    g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_ROTATE1), true, nil, self)
                end
            elseif spec.emptyState == BaleLoader.EMPTY_ROTATE1 then
                if not (self:getIsAnimationPlaying(spec.animations.emptyRotate) or self:getIsAnimationPlaying(spec.animations.moveBalePlacesToEmpty)) then
                    g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_CLOSE_GRIPPERS), true, nil, self)
                end
            elseif spec.emptyState == BaleLoader.EMPTY_CLOSE_GRIPPERS then
                if not self:getIsAnimationPlaying(spec.animations.closeGrippers) then
                    g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_HIDE_PUSHER1), true, nil, self)
                end
            elseif spec.emptyState == BaleLoader.EMPTY_HIDE_PUSHER1 then
                if not self:getIsAnimationPlaying(spec.animations.pusherEmptyHide1) then
                    g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_HIDE_PUSHER2), true, nil, self)
                end
            elseif spec.emptyState == BaleLoader.EMPTY_HIDE_PUSHER2 then
                if self:getAnimationTime(spec.animations.pusherMoveToEmpty) < 0.7 or not self:getIsAnimationPlaying(spec.animations.pusherMoveToEmpty) then
                    g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_ROTATE2), true, nil, self)
                end
            elseif spec.emptyState == BaleLoader.EMPTY_ROTATE2 then
                if not self:getIsAnimationPlaying(spec.animations.emptyRotate) then
                    g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_WAIT_TO_DROP), true, nil, self)
                end
            elseif spec.emptyState == BaleLoader.EMPTY_SINK then
                if not (self:getIsAnimationPlaying(spec.animations.emptyRotate) or (self:getIsAnimationPlaying(spec.animations.moveBalePlacesToEmpty) or (self:getIsAnimationPlaying(spec.animations.pusherEmptyHide1) or self:getIsAnimationPlaying(spec.animations.rotatePlatformEmpty)))) then
                    g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_STATE_NIL), true, nil, self)
                end
            elseif spec.emptyState == BaleLoader.EMPTY_CANCEL and not self:getIsAnimationPlaying(spec.animations.emptyRotate) then
                g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_WAIT_TO_REDO), true, nil, self)
            end
        end
    end
    if spec.baleGrabber.currentBaleIsUnmounted then
        spec.baleGrabber.currentBaleIsUnmounted = false
        local nearestBale = NetworkUtil.getObject(spec.baleGrabber.currentBale)
        if nearestBale ~= nil then
            if spec.dynamicMount.enabled then
                self:mountDynamicBale(nearestBale, spec.baleGrabber.grabNode)
            else
                self:mountBale(nearestBale, self, spec.baleGrabber.grabNode, 0, 0, 0, 0, 0, 0)
            end
            nearestBale:setCanBeSold(false)
        end
    end
end
function BaleLoader:onUpdateTick(dt, _, _, _)
    local spec = self.spec_baleLoader
    if self.isClient then
        local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA]
        if actionEvent ~= nil then
            local showAction = false
            if spec.emptyState == BaleLoader.EMPTY_NONE and spec.grabberMoveState == nil then
                if spec.isInWorkPosition then
                    g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.transportPosition)
                    showAction = true
                else
                    g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.operatingPosition)
                    showAction = true
                end
            end
            g_inputBinding:setActionEventActive(actionEvent.actionEventId, showAction)
        end
        local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA2]
        if actionEvent ~= nil then
            g_inputBinding:setActionEventActive(actionEvent.actionEventId, spec.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP)
        end
        local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]
        if actionEvent ~= nil then
            local showAction = false
            if spec.emptyState == BaleLoader.EMPTY_NONE then
                if BaleLoader.getAllowsStartUnloading(self) then
                    g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.unload)
                    showAction = true
                end
            elseif spec.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
                g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.unloadHere)
                showAction = true
            elseif spec.emptyState == BaleLoader.EMPTY_WAIT_TO_SINK then
                if not spec.unloadingMover.isActive then
                    g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.lowerPlattform)
                    showAction = true
                end
            elseif spec.emptyState == BaleLoader.EMPTY_WAIT_TO_REDO then
                g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.unload)
                showAction = true
            end
            g_inputBinding:setActionEventActive(actionEvent.actionEventId, showAction)
        end
    end
    if self.isServer then
        if Platform.gameplay.automaticBaleDrop then
            local actionEvent, showAction = next(spec.baleUnloadTriggers)
            if actionEvent ~= nil and self:getIsAutomaticBaleUnloadingAllowed() then
                local bales = self:getLoadedBales()
                local unloadingAllowed = false
                for i, bale in ipairs(bales) do
                    if actionEvent:getIsBaleSupportedByUnloadTrigger(bale) then
                        unloadingAllowed = true
                        break
                    end
                end
                if unloadingAllowed and BaleLoader.getAllowsStartUnloading(self) then
                    self:startAutomaticBaleUnloading()
                end
            end
        end
        if spec.fullAutomaticUnloading and (self:getFillUnitFillLevelPercentage(spec.fillUnitIndex) == 1 or spec.automaticUnloadingAdditionalBalesToLoad == 0) and BaleLoader.getAllowsStartUnloading(self) then
            self:startAutomaticBaleUnloading()
        end
        if spec.automaticUnloading or spec.automaticUnloadingInProgress then
            if spec.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
                self:doStateChange(BaleLoader.CHANGE_BUTTON_EMPTY)
            end
            local actionEvent = self:getIsAnimationPlaying(spec.animations.releaseFrontPlatform)
            if spec.emptyState == BaleLoader.EMPTY_WAIT_TO_SINK and not (actionEvent or spec.unloadingMover.isActive) then
                self:doStateChange(BaleLoader.CHANGE_SINK)
            end
        end
        if #spec.baleJoints > 0 then
            local actionEvent = spec.dynamicBaleUnloading.useUnloadingMoverTrigger and (spec.unloadingMover.frameDelay == 0 and next(spec.unloadingMover.balesInTrigger) == nil) and true or false
            if spec.dynamicBaleUnloading.useUnloadingMoverTrigger == nil or actionEvent then
                actionEvent = false
                if spec.dynamicBaleUnloading.releaseAnimation ~= nil then
                    local showAction = spec.dynamicBaleUnloading.releaseAnimation
                    actionEvent = (self:getAnimationTime(showAction) >= spec.dynamicBaleUnloading.releaseAnimationTime or not self:getIsAnimationPlaying(showAction)) and true or actionEvent
                end
            end
            if actionEvent then
                local unloadingAllowed = #spec.baleJoints
                for unloadingAllowed = unloadingAllowed, 1, -1 do
                    removeJoint(spec.baleJoints[unloadingAllowed])
                    spec.baleJoints[unloadingAllowed] = nil
                end
            end
        end
        if spec.unloadingMover.isActive then
            local actionEvent = spec.unloadingMover
            local bales = spec.unloadingMover.frameDelay - 1
            actionEvent.frameDelay = math.max(bales, 0)
            if spec.unloadingMover.frameDelay == 0 and next(spec.unloadingMover.balesInTrigger) == nil then
                spec.unloadingMover.isActive = false
                local bales = 1
                for bales = bales, #spec.unloadingMover.nodes do
                    setFrictionVelocity(spec.unloadingMover.nodes[bales].node, 0)
                end
                if self.isClient then
                    g_animationManager:stopAnimations(spec.unloadingMover.animationNodes)
                    g_soundManager:stopSample(spec.samples.unload)
                end
                self:raiseDirtyFlags(spec.unloadingMover.dirtyFlag)
            end
        end
        if spec.dynamicMount.enabled then
            local actionEvent = false
            for i, jointNode in ipairs(spec.dynamicMount.baleJointsToUpdate) do
                if jointNode.quaternion == nil then
                    local qx, i, bale, qw = getQuaternion(jointNode.node)
                    jointNode.quaternion = {
                        qx,
                        i,
                        bale,
                        qw
                    }
                end
                if jointNode.time < spec.dynamicMount.jointInterpolationTimeRot then
                    jointNode.time = jointNode.time + dt
                    local qx = 0
                    local i = 0
                    local bale = 0
                    local qw = 1
                    local baleServerId = jointNode.quaternion[2]
                    if math.abs(baleServerId) > 0.5 then
                        qx, i, bale, qw = MathUtil.slerpQuaternionShortestPath(jointNode.quaternion[1], jointNode.quaternion[2], jointNode.quaternion[3], jointNode.quaternion[4], 0, 1, 0, 0, jointNode.time / spec.dynamicMount.jointInterpolationTimeRot)
                    elseif math.abs(jointNode.quaternion[2]) < 0.5 then
                        qx, i, bale, qw = MathUtil.slerpQuaternionShortestPath(jointNode.quaternion[1], jointNode.quaternion[2], jointNode.quaternion[3], jointNode.quaternion[4], 0, 0, 0, 1, jointNode.time / spec.dynamicMount.jointInterpolationTimeRot)
                    end
                    setQuaternion(jointNode.node, qx, i, bale, qw)
                    actionEvent = true
                end
                local qx, i, bale = getTranslation(jointNode.node)
                if math.abs(qx) + math.abs(i) + math.abs(bale) > 0.001 then
                    local qw = spec.dynamicMount.jointInterpolationSpeedTrans * dt
                    setTranslation(jointNode.node, (math.sign(qx) > 0 and math.max or math.min)(qx - math.sign(qx) * qw, 0), (math.sign(i) > 0 and math.max or math.min)(i - math.sign(i) * qw, 0), (function(old)
                        -- upvalues: (copy) qw
                        return (math.sign(old) > 0 and math.max or math.min)(old - math.sign(old) * qw, 0)
                    end)(bale))
                    actionEvent = true
                elseif jointNode.time > spec.dynamicMount.jointInterpolationTimeRot then
                    table.remove(spec.dynamicMount.baleJointsToUpdate, i)
                end
            end
            local showAction = false
            for jointNode, qx in pairs(self.spec_animatedVehicle.animations) do
                if self:getIsAnimationPlaying(jointNode) then
                    showAction = true
                end
            end
            if showAction or (actionEvent or spec.dynamicMount.baleMassDirty) then
                for jointNode, qx in pairs(spec.balePlaces) do
                    if qx.bales ~= nil then
                        for moveValue, baleServerId in pairs(qx.bales) do
                            local bale = NetworkUtil.getObject(baleServerId)
                            if bale ~= nil then
                                if bale.dynamicMountJointIndex ~= nil then
                                    setJointFrame(bale.dynamicMountJointIndex, 0, bale.baleLoaderDynamicJointNode)
                                end
                                if bale.backupMass == nil then
                                    local mass = getMass(bale.nodeId)
                                    if mass ~= 1 then
                                        bale.backupMass = mass
                                        setMass(bale.nodeId, 0.1)
                                        spec.dynamicMount.baleMassDirty = false
                                    end
                                end
                            end
                        end
                    end
                end
                if spec.startBalePlace ~= nil then
                    for jointNode, qx in ipairs(spec.startBalePlace.bales) do
                        local i = NetworkUtil.getObject(qx)
                        if i ~= nil then
                            if i.dynamicMountJointIndex ~= nil then
                                setJointFrame(i.dynamicMountJointIndex, 0, i.baleLoaderDynamicJointNode)
                            end
                            if i.backupMass == nil then
                                local bale = getMass(i.nodeId)
                                if bale ~= 1 then
                                    i.backupMass = bale
                                    setMass(i.nodeId, 0.1)
                                    spec.dynamicMount.baleMassDirty = false
                                end
                            end
                        end
                    end
                end
                if spec.baleGrabber.currentBale ~= nil then
                    local bales = NetworkUtil.getObject(spec.baleGrabber.currentBale)
                    if bales ~= nil and bales.dynamicMountJointIndex ~= nil then
                        setJointFrame(bales.dynamicMountJointIndex, 0, bales.baleLoaderDynamicJointNode)
                    end
                end
            end
        end
    end
    if spec.moveBalePlacesDelayedMovement and self:getAnimationTime(spec.animations.baleGrabberWorkToDrop) < spec.animations.moveBalePlacesMaxGrabberTime then
        spec.rotatePlatformDirection = -1
        self:playAnimation(spec.animations.rotatePlatformBack, -1, nil, true)
        if spec.animations.moveBalePlacesAfterRotatePlatform and (spec.startBalePlace ~= nil and spec.startBalePlace.current <= #spec.balePlaces or spec.animations.moveBalePlacesAlways) then
            self:playAnimation(spec.animations.moveBalePlaces, 1, (spec.startBalePlace.current - 1) / #spec.balePlaces, true)
            self:setAnimationStopTime(spec.animations.moveBalePlaces, spec.startBalePlace.current / #spec.balePlaces)
            self:playAnimation(spec.animations.moveBalePlacesExtrasOnce, 1, nil, true)
        end
        spec.moveBalePlacesDelayedMovement = nil
    end
    if spec.animations.moveBalePlacesToEmptyPushOffsetTime > 0 then
        spec.animations.moveBalePlacesToEmptyPushOffsetTime = spec.animations.moveBalePlacesToEmptyPushOffsetTime - dt
        if spec.animations.moveBalePlacesToEmptyPushOffsetTime <= 0 then
            local actionEvent = self:getRealAnimationTime(spec.animations.moveBalePlaces)
            local showAction = self:getAnimationDuration(spec.animations.moveBalePlacesToEmpty)
            self:playAnimation(spec.animations.moveBalePlacesToEmpty, spec.animations.moveBalePlacesToEmptySpeed * ((showAction - actionEvent) / (showAction - actionEvent - spec.animations.moveBalePlacesToEmptyPushOffsetDelay * spec.animations.moveBalePlacesToEmptySpeed)), actionEvent / showAction, true)
            spec.animations.moveBalePlacesToEmptyPushOffsetTime = 0
        end
    end
end
function BaleLoader:onDraw(_, _, _)
    local spec = self.spec_baleLoader
    if spec.showBaleNotSupportedWarning and spec.baleNotSupportedWarning ~= nil then
        g_currentMission:showBlinkingWarning(spec.baleNotSupportedWarning, 2000)
    end
end
function BaleLoader:getBaleInRange(refNode, balesInTrigger)
    local spec = self.spec_baleLoader
    local nearestDistance = spec.baleGrabber.pickupRange
    local nearestBale = nil
    local nearestBaleType = nil
    local warning = spec.texts.baleNotSupported
    for bale, state in pairs(balesInTrigger) do
        if state ~= nil and state > 0 then
            local isValidBale = true
            local otherBale = nil
            for _, balePlace in pairs(spec.balePlaces) do
                if balePlace.bales ~= nil then
                    for _, baleServerId in pairs(balePlace.bales) do
                        otherBale = NetworkUtil.getObject(baleServerId)
                        if otherBale ~= nil and otherBale == bale then
                            isValidBale = false
                        end
                    end
                end
            end
            if spec.startBalePlace ~= nil then
                for _, balePlace in ipairs(spec.startBalePlace.bales) do
                    otherBale = NetworkUtil.getObject(balePlace)
                    if otherBale ~= nil and otherBale == bale then
                        isValidBale = false
                    end
                end
            end
            if bale == nil or not entityExists(bale.nodeId) then
                isValidBale = false
            end
            if isValidBale then
                local distance = calcDistanceFrom(refNode, bale.nodeId)
                if distance < nearestDistance then
                    local foundBaleType = self:getBaleTypeByBale(bale)
                    if foundBaleType ~= spec.currentBaleType and self:getFillUnitFillLevel(spec.currentBaleType.fillUnitIndex) ~= 0 then
                        foundBaleType = nil
                        warning = spec.texts.onlyOneBaleTypeWarning
                    end
                    if foundBaleType ~= nil and (not foundBaleType.mixedFillTypes and (otherBale ~= nil and bale:getFillType() ~= otherBale:getFillType())) then
                        foundBaleType = nil
                        warning = spec.texts.baleDoNotAllowFillTypeMixing
                    end
                    if bale:getIsMounted() or bale.baleJointIndex ~= nil then
                        foundBaleType = nil
                        warning = nil
                    end
                    if not bale:getBaleSupportsBaleLoader() then
                        foundBaleType = nil
                    end
                    local activeFarmId = self:getActiveFarm()
                    if activeFarmId ~= bale.ownerFarmId and (not g_currentMission.accessHandler:canFarmAccessOtherId(activeFarmId, bale.ownerFarmId) and self.spec_baler == nil) then
                        foundBaleType = nil
                        warning = spec.texts.youDoNotOwnBale
                    end
                    if foundBaleType ~= nil or nearestBaleType == nil then
                        if foundBaleType == nil then
                            distance = nearestDistance
                        end
                        nearestBale = bale
                        nearestBaleType = foundBaleType
                    end
                end
            end
        end
    end
    return nearestBale, nearestBaleType, warning
end
function BaleLoader:onActivate()
    local spec = self.spec_baleLoader
    if spec.isInWorkPosition and not spec.animationNodesBlocked then
        g_animationManager:startAnimations(spec.animationNodes)
        g_soundManager:playSample(spec.samples.work)
    end
end
function BaleLoader:onDeactivate()
    local spec = self.spec_baleLoader
    g_effectManager:stopEffects(spec.grabberEffects)
    g_animationManager:stopAnimations(spec.animationNodes)
    g_soundManager:stopSample(spec.samples.work)
end
function BaleLoader:onRootVehicleChanged(rootVehicle)
    local actionController = rootVehicle.actionController
    if actionController == nil then
        if self.spec_baleLoader.controlledAction ~= nil then
            spec.controlledAction:remove()
        end
        return
    elseif spec.controlledAction == nil then
        spec.controlledAction = actionController:registerAction("baleLoaderWorkstate", nil, 4)
        spec.controlledAction:setCallback(self, BaleLoader.actionControllerEvent)
        spec.controlledAction:setFinishedFunctions(self, function(vehicle)
            return vehicle.spec_baleLoader.isInWorkPosition
        end, true, false)
        spec.controlledAction:addAIEventListener(self, "onAIImplementPrepareForTransport", -1)
    else
        spec.controlledAction:updateParent(actionController)
    end
end
function BaleLoader:actionControllerEvent(direction)
    local spec = self.spec_baleLoader
    if spec.grabberIsMoving or spec.grabberMoveState ~= nil or (direction <= 0 or spec.isInWorkPosition) and (direction >= 0 or not spec.isInWorkPosition) then
        return false
    end
    BaleLoader.actionEventWorkTransport(self)
    return true
end
function BaleLoader:onFillUnitFillLevelChanged(fillUnitIndex, _, _, _, _, _)
    if fillUnitIndex == self.spec_baleLoader.fillUnitIndex then
        self:updateFoldingAnimation()
    end
end
function BaleLoader:onFoldStateChanged(direction)
    if self.spec_baleLoader.useFoldingState and self.isServer then
        if direction == self.spec_foldable.turnOnFoldDirection then
            g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_MOVE_TO_WORK), true, nil, self)
            return
        end
        g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_MOVE_TO_TRANSPORT), true, nil, self)
    end
end
function BaleLoader:onBalerUnloadingStarted(balesToUnload)
    local spec = self.spec_baleLoader
    if spec.fullAutomaticUnloading then
        spec.automaticUnloadingAdditionalBalesToLoad = balesToUnload
    end
end
function BaleLoader:onRegisterAnimationValueTypes()
    local spec = self.spec_baleLoader
    self:registerAnimationValueType("baleLoaderAnimationNodes", "baleLoaderAnimationNodes", "", false, AnimationValueBool, function(value, xmlFile, xmlKey)
        return true
    end, function(value)
        -- upvalues: (copy) spec
        return not spec.animationNodesBlocked
    end, function(_, state)
        -- upvalues: (copy) spec
        spec.animationNodesBlocked = not state
        if not spec.animationNodesBlocked and spec.isInWorkPosition then
            g_animationManager:startAnimations(spec.animationNodes)
            g_soundManager:playSample(spec.samples.work)
        end
        if spec.animationNodesBlocked and spec.isInWorkPosition then
            g_animationManager:stopAnimations(spec.animationNodes)
            g_soundManager:stopSample(spec.samples.work)
        end
    end)
end
function BaleLoader:loadBaleTypeFromXML(xmlFile, key, baleType)
    local spec = self.spec_baleLoader
    baleType.dimensions = {}
    local dimensions = baleType.dimensions
    dimensions.isRoundbale = self.xmlFile:getString(key .. "#diameter") ~= nil or (self.xmlFile:getString(key .. "#minDiameter") ~= nil or self.xmlFile:getString(key .. "#maxDiameter") ~= nil)
    if dimensions.isRoundbale then
        dimensions.minWidth, dimensions.maxWidth = (function(xml, valueKey, valueName, minValueName, maxValueName)
            -- upvalues: (copy) xmlFile
            local value = xml:getValue(valueKey .. "#" .. valueName)
            local minValue = xml:getValue(valueKey .. "#" .. minValueName)
            local maxValue = xml:getValue(valueKey .. "#" .. maxValueName)
            local minValue = minValue or (maxValue or value)
            local maxValue = maxValue or minValue
            if minValue ~= nil and maxValue ~= nil then
                return MathUtil.round(minValue, 2), MathUtil.round(maxValue, 2)
            end
            Logging.xmlError(xmlFile, "Unable to load bale dimension. \'%s\' is not available in \'%s\'", valueName, valueKey)
            return 0, 0
        end)(self.xmlFile, key, "width", "minWidth", "maxWidth")
        dimensions.minDiameter, dimensions.maxDiameter = getDimensionValue(self.xmlFile, key, "diameter", "minDiameter", "maxDiameter")
    else
        dimensions.minWidth, dimensions.maxWidth = getDimensionValue(self.xmlFile, key, "width", "minWidth", "maxWidth")
        dimensions.minHeight, dimensions.maxHeight = getDimensionValue(self.xmlFile, key, "height", "minHeight", "maxHeight")
        dimensions.minLength, dimensions.maxLength = getDimensionValue(self.xmlFile, key, "length", "minLength", "maxLength")
    end
    baleType.mixedFillTypes = self.xmlFile:getValue(key .. "#mixedFillTypes", true)
    baleType.fillUnitIndex = self.xmlFile:getValue(key .. "#fillUnitIndex", spec.fillUnitIndex)
    baleType.changeObjects = {}
    ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, key, baleType.changeObjects, self.components, self)
    self:loadBalePlacesFromXML(xmlFile, key, baleType)
    return self:loadBaleLoaderAnimationsFromXML(xmlFile, key, baleType, spec.defaultAnimations) and true or false
end
function BaleLoader.loadBaleLoaderAnimationsFromXML(_, xmlFile, key, target, defaultTarget)
    target.animations = {}
    local default = target.animations
    if defaultTarget ~= nil then
        default = defaultTarget.animations or target.animations
    end
    target.animations.rotatePlatform = xmlFile:getValue(key .. ".animations.platform#rotate", default.rotatePlatform or "rotatePlatform")
    target.animations.rotatePlatformBack = xmlFile:getValue(key .. ".animations.platform#rotateBack", default.rotatePlatformBack or "rotatePlatform")
    target.animations.rotatePlatformEmpty = xmlFile:getValue(key .. ".animations.platform#rotateEmpty", default.rotatePlatformEmpty or "rotatePlatform")
    target.animations.rotatePlatformAllowPickup = xmlFile:getValue(key .. ".animations.platform#allowPickupWhileMoving", Utils.getNoNil(default.rotatePlatformAllowPickup, false))
    target.animations.baleGrabberDropBaleReverseSpeed = xmlFile:getValue(key .. ".animations.baleGrabber#dropBaleReverseSpeed", default.baleGrabberDropBaleReverseSpeed or 5)
    target.animations.baleGrabberDropToWork = xmlFile:getValue(key .. ".animations.baleGrabber#dropToWork", default.baleGrabberDropToWork)
    target.animations.baleGrabberWorkToDrop = xmlFile:getValue(key .. ".animations.baleGrabber#workToDrop", default.baleGrabberWorkToDrop or "baleGrabberWorkToDrop")
    target.animations.baleGrabberDropBale = xmlFile:getValue(key .. ".animations.baleGrabber#dropBale", default.baleGrabberDropBale or "baleGrabberDropBale")
    target.animations.baleGrabberTransportToWork = xmlFile:getValue(key .. ".animations.baleGrabber#transportToWork", default.baleGrabberTransportToWork or "baleGrabberTransportToWork")
    target.animations.pusherEmptyHide1 = xmlFile:getValue(key .. ".animations.pusher#emptyHide", default.pusherEmptyHide1 or "emptyHidePusher1")
    target.animations.pusherMoveToEmpty = xmlFile:getValue(key .. ".animations.pusher#moveToEmpty", default.pusherMoveToEmpty or "moveBalePusherToEmpty")
    target.animations.pusherHideOnEmpty = xmlFile:getValue(key .. ".animations.pusher#hidePusherOnEmpty", Utils.getNoNil(default.pusherHideOnEmpty, true))
    target.animations.pusherPushBalesOnEmpty = xmlFile:getValue(key .. ".animations.pusher#pushBalesOnEmpty", Utils.getNoNil(default.pusherPushBalesOnEmpty, false))
    target.animations.releaseFrontPlatform = xmlFile:getValue(key .. ".animations.releaseFrontPlatform#name", default.releaseFrontPlatform or "releaseFrontplattform")
    target.animations.releaseFrontPlatformFillLevelSpeed = xmlFile:getValue(key .. ".animations.releaseFrontPlatform#fillLevelSpeed", Utils.getNoNil(default.releaseFrontPlatformFillLevelSpeed, false))
    target.animations.moveBalePlaces = xmlFile:getValue(key .. ".animations.moveBalePlaces#name", default.moveBalePlaces or "moveBalePlaces")
    target.animations.moveBalePlacesExtrasOnce = xmlFile:getValue(key .. ".animations.moveBalePlaces#extrasOnce", default.moveBalePlacesExtrasOnce or "moveBalePlacesExtrasOnce")
    target.animations.moveBalePlacesToEmpty = xmlFile:getValue(key .. ".animations.moveBalePlaces#empty", default.moveBalePlacesToEmpty or "moveBalePlacesToEmpty")
    target.animations.moveBalePlacesToEmptySpeed = xmlFile:getValue(key .. ".animations.moveBalePlaces#emptySpeed", default.moveBalePlacesToEmptySpeed or 1.5)
    target.animations.moveBalePlacesToEmptyReverseSpeed = xmlFile:getValue(key .. ".animations.moveBalePlaces#emptyReverseSpeed", default.moveBalePlacesToEmptyReverseSpeed or -1)
    target.animations.moveBalePlacesToEmptyPushOffset = xmlFile:getValue(key .. ".animations.moveBalePlaces#pushOffset", default.moveBalePlacesToEmptyPushOffset or 0)
    target.animations.moveBalePlacesToEmptyPushOffsetDelay = 0
    target.animations.moveBalePlacesToEmptyPushOffsetTime = 0
    target.animations.moveBalePlacesAfterRotatePlatform = xmlFile:getValue(key .. ".animations.moveBalePlaces#moveAfterRotatePlatform", Utils.getNoNil(default.moveBalePlacesAfterRotatePlatform, false))
    target.animations.moveBalePlacesResetOnSink = xmlFile:getValue(key .. ".animations.moveBalePlaces#resetOnSink", Utils.getNoNil(default.moveBalePlacesResetOnSink, false))
    target.animations.moveBalePlacesMaxGrabberTime = xmlFile:getValue(key .. ".animations.moveBalePlaces#maxGrabberTime", default.moveBalePlacesMaxGrabberTime or math.huge)
    target.animations.moveBalePlacesAlways = xmlFile:getValue(key .. ".animations.moveBalePlaces#alwaysMove", Utils.getNoNil(default.moveBalePlacesAlways, false))
    target.animations.emptyRotate = xmlFile:getValue(key .. ".animations.emptyRotate#name", default.emptyRotate or "emptyRotate")
    target.animations.emptyRotateReset = xmlFile:getValue(key .. ".animations.emptyRotate#reset", Utils.getNoNil(default.emptyRotateReset, true))
    target.animations.frontBalePusher = xmlFile:getValue(key .. ".animations#frontBalePusher", default.frontBalePusher or "frontBalePusher")
    target.animations.balesToOtherRow = xmlFile:getValue(key .. ".animations#balesToOtherRow", default.balesToOtherRow or "balesToOtherRow")
    target.animations.closeGrippers = xmlFile:getValue(key .. ".animations#closeGrippers", default.closeGrippers or "closeGrippers")
    return true
end
function BaleLoader:loadBalePlacesFromXML(_, key, target)
    local useSharedBalePlaces = true
    target.startBalePlace = {}
    target.startBalePlace.bales = {}
    target.startBalePlace.node = self.xmlFile:getValue(key .. ".balePlaces#startBalePlace", nil, self.components, self.i3dMappings)
    if target.startBalePlace.node == nil then
        target.startBalePlace.numOfPlaces = 0
        useSharedBalePlaces = false
    else
        target.startBalePlace.numOfPlaces = getNumOfChildren(target.startBalePlace.node)
        if target.startBalePlace.numOfPlaces == 0 then
            target.startBalePlace.node = nil
        else
            target.startBalePlace.origRot = {}
            target.startBalePlace.origTrans = {}
            local i = 1
            local i = target.startBalePlace.numOfPlaces
            for i = i, i do
                local node = getChildAt(target.startBalePlace.node, i - 1)
                target.startBalePlace.origRot[i] = { getRotation(node) }
                target.startBalePlace.origTrans[i] = { getTranslation(node) }
            end
        end
    end
    target.startBalePlace.count = 0
    target.startBalePlace.current = 1
    target.balePlaces = {}
    local i = 0
    while true do
        local balePlaceKey = string.format("%s.balePlaces.balePlace(%d)", key, i)
        if not self.xmlFile:hasProperty(balePlaceKey) then
            break
        end
        local i = self.xmlFile:getValue(balePlaceKey .. "#node", nil, self.components, self.i3dMappings)
        if i ~= nil then
            table.insert(target.balePlaces, {
                ["node"] = i
            })
        end
        i = i + 1
    end
    if #target.balePlaces == 0 then
        useSharedBalePlaces = false
    end
    return useSharedBalePlaces
end
function BaleLoader:createBaleToBaleJoints(baleLines)
    if #baleLines > 1 then
        local dynamicBaleUnloading = self.spec_baleLoader.dynamicBaleUnloading
        for lineIndex, bales in ipairs(baleLines) do
            if dynamicBaleUnloading.connectedRows[lineIndex] then
                local i = 1
                for i = i, #bales - 1 do
                    if bales[1].isRoundbale then
                        self:createBaleToBaleJoint(bales[i], bales[i + 1], 0, dynamicBaleUnloading.heightOffset, bales[i].width + dynamicBaleUnloading.widthOffset, dynamicBaleUnloading.rowConnectionRotLimit, 0, 0, i)
                    else
                        self:createBaleToBaleJoint(bales[i], bales[i + 1], bales[i].width + dynamicBaleUnloading.widthOffset, dynamicBaleUnloading.heightOffset, 0, 0, 0, lineRotLimit * 5, i)
                    end
                end
            end
            for _, connection in ipairs(dynamicBaleUnloading.interConnectedRowStarts) do
                if connection[1] == lineIndex then
                    local bales2 = baleLines[connection[2]]
                    if bales2 ~= nil then
                        if isRoundbale then
                            self:createBaleToBaleJoint(bales[1], bales2[1], bales[1].diameter + dynamicBaleUnloading.diameterOffset, dynamicBaleUnloading.heightOffset, 0, dynamicBaleUnloading.rowInterConnectionRotLimit, dynamicBaleUnloading.rowInterConnectionRotLimit, dynamicBaleUnloading.rowInterConnectionRotLimit, 1)
                        else
                            self:createBaleToBaleJoint(bales[1], bales2[1], 0, bales[1].height + 0.05, 0, lineRotLimit, 0, 0, 1)
                        end
                    end
                end
            end
            for _, connection in ipairs(dynamicBaleUnloading.interConnectedRowEnds) do
                if connection[1] == lineIndex then
                    local bales2 = baleLines[connection[2]]
                    if bales2 ~= nil and #bales == #bales2 then
                        if isRoundbale then
                            self:createBaleToBaleJoint(bales[#bales], bales2[#bales2], bales[#bales].diameter + dynamicBaleUnloading.diameterOffset, dynamicBaleUnloading.heightOffset, 0, sideRotLimit, sideRotLimit, sideRotLimit, #bales)
                        else
                            self:createBaleToBaleJoint(bales[#bales], bales2[#bales2], 0, bales[#bales].height + 0.05, 0, lineRotLimit, 0, 0, #bales)
                        end
                    end
                end
            end
        end
    end
end
function BaleLoader:createBaleToBaleJoint(bale1, bale2, x, y, z, rx, ry, rz, balePlaceIndex)
    local spec = self.spec_baleLoader
    local balePlaceRot = spec.balePlaces[balePlaceIndex].node
    local constr = JointConstructor.new()
    constr:setActors(bale1.nodeId, bale2.nodeId)
    local jointTransform1 = createTransformGroup("jointTransform1")
    link(bale1.nodeId, jointTransform1)
    setRotation(jointTransform1, localRotationToLocal(balePlaceRot, bale1.nodeId, 0, 0, 0))
    local jointTransform2 = createTransformGroup("jointTransform2")
    link(bale2.nodeId, jointTransform2)
    setRotation(jointTransform2, localRotationToLocal(balePlaceRot, bale2.nodeId, 0, 0, 0))
    constr:setJointTransforms(jointTransform1, jointTransform2)
    constr:setEnableCollision(true)
    constr:setRotationLimit(0, -rx, rx)
    constr:setRotationLimit(1, -ry, ry)
    constr:setRotationLimit(2, -rz, rz)
    constr:setTranslationLimit(0, true, -x, x)
    constr:setTranslationLimit(1, true, -y, y)
    constr:setTranslationLimit(2, true, -z, z)
    local jointIndex = constr:finalize()
    table.insert(spec.baleJoints, jointIndex)
end
function BaleLoader:doStateChange(id, nearestBaleServerId)
    if id == BaleLoader.CHANGE_DROP_BALES then
        if self.spec_baleLoader.startBalePlace ~= nil then
            spec.startBalePlace.current = 1
        end
        local packBales = false
        if spec.balePacker.node ~= nil then
            packBales = spec.balePacker.filename ~= nil
        end
        local packedFarmId = FarmManager.SPECTATOR_FARM_ID
        local packedFillType = FillType.UNKNOWN
        local packedFillLevel = 0
        for _, balePlace in pairs(spec.balePlaces) do
            if balePlace.bales ~= nil then
                for i, baleServerId in pairs(balePlace.bales) do
                    local bale = NetworkUtil.getObject(baleServerId)
                    if bale ~= nil then
                        if spec.dynamicMount.enabled then
                            self:unmountDynamicBale(bale)
                        else
                            self:unmountBale(bale)
                        end
                        bale:setCanBeSold(true)
                        if spec.baleGrabber.balesInTrigger[bale] ~= nil then
                            spec.baleGrabber.balesInTrigger[bale] = nil
                        end
                        if spec.dynamicBaleUnloading.enabled then
                            if ({})[i] == nil then
                                table.insert(baleLines, { bale })
                            else
                                table.insert(baleLines[i], bale)
                            end
                        end
                        if packBales then
                            packedFarmId = bale.ownerFarmId
                            packedFillType = bale.fillType
                            bale:delete()
                        end
                    end
                    spec.balesToMount[baleServerId] = nil
                end
                balePlace.bales = nil
            end
        end
        if self.isServer and packBales then
            local baleObject = PackedBale.new(self.isServer, self.isClient)
            local x, y, _ = getWorldTranslation(spec.balePacker.node)
            local balePlace, ry, rz = getWorldRotation(spec.balePacker.node)
            if baleObject:loadFromConfigXML(spec.balePacker.filename, x, y, _, balePlace, ry, rz) then
                baleObject:setFillType(packedFillType)
                baleObject:setFillLevel(packedFillLevel)
                baleObject:setOwnerFarmId(packedFarmId, true)
                baleObject:register()
                removeFromPhysics(baleObject.nodeId)
                addToPhysics(baleObject.nodeId)
            end
        end
        if spec.dynamicBaleUnloading.enabled then
            self:createBaleToBaleJoints(baleLines)
        end
        local baleObject = 1
        if spec.animations.releaseFrontPlatformFillLevelSpeed then
            local _ = self:getFillUnitFillLevel(spec.fillUnitIndex) / self:getFillUnitCapacity(spec.fillUnitIndex)
            if _ > 0 then
                baleObject = 1 / _
            end
        end
        self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -math.huge, self:getFillUnitFirstSupportedFillType(spec.fillUnitIndex), ToolType.UNDEFINED, nil)
        if self.isServer and spec.unloadingMover.trigger ~= nil then
            spec.unloadingMover.isActive = true
            spec.unloadingMover.frameDelay = 3
            for _ = 1, #spec.unloadingMover.nodes do
                local balePlace = spec.unloadingMover.nodes[_]
                setFrictionVelocity(balePlace.node, balePlace.speed)
            end
            if self.isClient then
                g_animationManager:startAnimations(spec.unloadingMover.animationNodes)
                g_soundManager:playSample(spec.samples.unload)
            end
            self:raiseDirtyFlags(spec.unloadingMover.dirtyFlag)
        end
        self:playAnimation(spec.animations.releaseFrontPlatform, baleObject, nil, true)
        self:playAnimation(spec.animations.closeGrippers, -1, nil, true)
        spec.emptyState = BaleLoader.EMPTY_WAIT_TO_SINK
        return
    elseif id == BaleLoader.CHANGE_SINK then
        if spec.animations.emptyRotateReset then
            self:playAnimation(spec.animations.emptyRotate, -1, nil, true)
        end
        self:playAnimation(spec.animations.moveBalePlacesToEmpty, spec.animations.moveBalePlacesToEmptyReverseSpeed, nil, true)
        if spec.animations.moveBalePlacesResetOnSink then
            self:playAnimation(spec.animations.moveBalePlaces, -999999, nil, true)
        end
        self:playAnimation(spec.animations.pusherEmptyHide1, -1, nil, true)
        self:playAnimation(spec.animations.rotatePlatformEmpty, -1, nil, true)
        if not spec.isInWorkPosition then
            self:playAnimation(spec.animations.closeGrippers, 1, self:getAnimationTime(spec.animations.closeGrippers), true)
        end
        spec.emptyState = BaleLoader.EMPTY_SINK
        return
    elseif id == BaleLoader.CHANGE_EMPTY_REDO then
        self:playAnimation(spec.animations.emptyRotate, 1, nil, true)
        spec.emptyState = BaleLoader.EMPTY_ROTATE2
        return
    elseif id == BaleLoader.CHANGE_EMPTY_START then
        if GS_IS_MOBILE_VERSION then
            if self.rootVehicle:getActionControllerDirection() > 0 then
                spec.controlledAction.parent:startActionSequence()
            end
            spec.emptyState = BaleLoader.EMPTY_TO_WORK
        else
            BaleLoader.moveToWorkPosition(self)
            spec.emptyState = BaleLoader.EMPTY_TO_WORK
        end
    elseif id == BaleLoader.CHANGE_EMPTY_CANCEL then
        self:playAnimation(spec.animations.emptyRotate, -1, nil, true)
        spec.emptyState = BaleLoader.EMPTY_CANCEL
    elseif id == BaleLoader.CHANGE_MOVE_TO_TRANSPORT then
        if spec.isInWorkPosition then
            spec.grabberIsMoving = true
            spec.isInWorkPosition = false
            g_animationManager:stopAnimations(spec.animationNodes)
            g_soundManager:stopSample(spec.samples.work)
            BaleLoader.moveToTransportPosition(self)
            return
        end
    elseif id == BaleLoader.CHANGE_MOVE_TO_WORK then
        if not spec.isInWorkPosition then
            spec.grabberIsMoving = true
            spec.isInWorkPosition = true
            if not spec.animationNodesBlocked then
                g_animationManager:startAnimations(spec.animationNodes)
                g_soundManager:playSample(spec.samples.work)
            end
            BaleLoader.moveToWorkPosition(self)
            return
        end
    elseif id == BaleLoader.CHANGE_GRAB_BALE then
        local baleLines = NetworkUtil.getObject(nearestBaleServerId)
        spec.baleGrabber.currentBale = nearestBaleServerId
        if baleLines == nil then
            spec.balesToMount[nearestBaleServerId] = {
                ["serverId"] = nearestBaleServerId,
                ["linkNode"] = spec.baleGrabber.grabNode,
                ["trans"] = { 0, 0, 0 },
                ["rot"] = { 0, 0, 0 }
            }
        else
            if spec.dynamicMount.enabled then
                self:mountDynamicBale(baleLines, spec.baleGrabber.grabNode)
            else
                self:mountBale(baleLines, self, spec.baleGrabber.grabNode, 0, 0, 0, 0, 0, 0, true)
            end
            baleLines:setCanBeSold(false)
            local packBales = self:getBaleTypeByBale(baleLines)
            if packBales ~= nil then
                self:setBaleLoaderBaleType(packBales.index)
            end
            spec.balesToMount[nearestBaleServerId] = nil
        end
        spec.grabberMoveState = BaleLoader.GRAB_MOVE_UP
        self:playAnimation(spec.animations.baleGrabberWorkToDrop, 1, nil, true)
        self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, 1, self:getFillUnitFirstSupportedFillType(spec.fillUnitIndex), ToolType.UNDEFINED, nil)
        if self.isClient then
            g_soundManager:playSample(spec.samples.grab)
            if baleLines ~= nil then
                g_effectManager:setEffectTypeInfo(spec.grabberEffects, baleLines:getFillType())
                g_effectManager:startEffects(spec.grabberEffects)
                spec.grabberEffectDisableTime = g_currentMission.time + spec.grabberEffectDisableDuration
                return
            end
        end
    else
        if id == BaleLoader.CHANGE_GRAB_MOVE_UP then
            spec.currentBaleGrabberDropBaleAnimName = self:getBaleGrabberDropBaleAnimName()
            self:playAnimation(spec.currentBaleGrabberDropBaleAnimName, 1, nil, true)
            spec.grabberMoveState = BaleLoader.GRAB_DROP_BALE
            return
        end
        if id == BaleLoader.CHANGE_GRAB_DROP_BALE then
            if spec.startBalePlace ~= nil and (spec.startBalePlace.count < spec.startBalePlace.numOfPlaces and spec.startBalePlace.node ~= nil) then
                local baleLines = getChildAt(spec.startBalePlace.node, spec.startBalePlace.count)
                local packBales = NetworkUtil.getObject(spec.baleGrabber.currentBale)
                if packBales == nil then
                    spec.balesToMount[spec.baleGrabber.currentBale] = {
                        ["serverId"] = spec.baleGrabber.currentBale,
                        ["linkNode"] = baleLines,
                        ["trans"] = { 0, 0, 0 },
                        ["rot"] = { 0, 0, 0 }
                    }
                else
                    if spec.dynamicMount.enabled then
                        self:mountDynamicBale(packBales, baleLines)
                    else
                        local packedFarmId = 0
                        local packedFillType = 0
                        local packedFillLevel = 0
                        if spec.keepBaleRotationDuringLoad then
                            packedFarmId, packedFillType, packedFillLevel = localRotationToLocal(packBales.nodeId, baleLines, 0, 0, 0)
                        end
                        self:mountBale(packBales, self, baleLines, 0, 0, 0, packedFarmId, packedFillType, packedFillLevel)
                    end
                    spec.balesToMount[spec.baleGrabber.currentBale] = nil
                end
                spec.startBalePlace.count = spec.startBalePlace.count + 1
                local packedFillType = spec.startBalePlace.bales
                local packedFillLevel = spec.baleGrabber.currentBale
                table.insert(packedFillType, packedFillLevel)
                spec.baleGrabber.currentBale = nil
                self:updateFoldingAnimation()
                if spec.startBalePlace.count < spec.startBalePlace.numOfPlaces then
                    spec.frontBalePusherDirection = 1
                    self:playAnimation(spec.animations.balesToOtherRow, 1, nil, true)
                    self:playAnimation(spec.animations.frontBalePusher, 1, nil, true)
                elseif spec.startBalePlace.count == spec.startBalePlace.numOfPlaces then
                    BaleLoader.rotatePlatform(self)
                end
                if spec.animations.baleGrabberDropToWork == nil then
                    self:playAnimation(spec.currentBaleGrabberDropBaleAnimName, -spec.animations.baleGrabberDropBaleReverseSpeed, nil, true)
                    self:playAnimation(spec.animations.baleGrabberWorkToDrop, -1, nil, true)
                else
                    self:playAnimation(spec.animations.baleGrabberDropToWork, 1, 0, true)
                end
                spec.grabberMoveState = BaleLoader.GRAB_MOVE_DOWN
                return
            end
        else
            if id == BaleLoader.CHANGE_GRAB_MOVE_DOWN then
                spec.grabberMoveState = nil
                spec.automaticUnloadingAdditionalBalesToLoad = spec.automaticUnloadingAdditionalBalesToLoad - 1
                return
            end
            if id == BaleLoader.CHANGE_FRONT_PUSHER then
                if spec.frontBalePusherDirection > 0 then
                    self:playAnimation(spec.animations.frontBalePusher, -1, nil, true)
                    spec.frontBalePusherDirection = -1
                else
                    spec.frontBalePusherDirection = 0
                end
            end
            if id == BaleLoader.CHANGE_ROTATE_PLATFORM then
                if spec.startBalePlace == nil or spec.rotatePlatformDirection <= 0 then
                    spec.rotatePlatformDirection = 0
                    return
                end
                local baleLines = spec.balePlaces[spec.startBalePlace.current]
                spec.startBalePlace.current = spec.startBalePlace.current + 1
                local packedFillType = 1
                for packedFillType = packedFillType, #spec.startBalePlace.bales do
                    local packedFillLevel = getChildAt(spec.startBalePlace.node, packedFillType - 1)
                    local baleObject, x, y = getTranslation(packedFillLevel)
                    local _, balePlace, ry = getRotation(packedFillLevel)
                    local rz = spec.startBalePlace.bales[packedFillType]
                    local bale = NetworkUtil.getObject(rz)
                    if bale == nil then
                        spec.balesToMount[rz] = {
                            ["serverId"] = rz,
                            ["linkNode"] = baleLines.node,
                            ["trans"] = { baleObject, x, y },
                            ["rot"] = { _, balePlace, ry }
                        }
                    else
                        if spec.keepBaleRotationDuringLoad then
                            baleObject, x, y = localToLocal(bale.nodeId, baleLines.node, 0, 0, 0)
                            _, balePlace, ry = localRotationToLocal(bale.nodeId, baleLines.node, 0, 0, 0)
                        end
                        if spec.dynamicMount.enabled then
                            self:mountDynamicBale(bale, baleLines.node)
                        else
                            self:mountBale(bale, self, baleLines.node, baleObject, x, y, _, balePlace, ry)
                        end
                        spec.balesToMount[rz] = nil
                    end
                end
                baleLines.bales = spec.startBalePlace.bales
                spec.startBalePlace.bales = {}
                spec.startBalePlace.count = 0
                self:updateFoldingAnimation()
                local packedFillType = 1
                for packedFillType = packedFillType, spec.startBalePlace.numOfPlaces do
                    local packedFillLevel = getChildAt(spec.startBalePlace.node, packedFillType - 1)
                    setRotation(packedFillLevel, unpack(spec.startBalePlace.origRot[packedFillType]))
                    setTranslation(packedFillLevel, unpack(spec.startBalePlace.origTrans[packedFillType]))
                end
                if spec.emptyState ~= BaleLoader.EMPTY_NONE then
                    spec.rotatePlatformDirection = 0
                    return
                end
                if self:getAnimationTime(spec.animations.baleGrabberWorkToDrop) >= spec.animations.moveBalePlacesMaxGrabberTime and spec.animations.moveBalePlacesMaxGrabberTime ~= math.huge then
                    spec.rotatePlatformDirection = -1
                    spec.moveBalePlacesDelayedMovement = true
                    return
                end
                spec.rotatePlatformDirection = -1
                self:playAnimation(spec.animations.rotatePlatformBack, -1, nil, true)
                if spec.animations.moveBalePlacesAfterRotatePlatform and (spec.startBalePlace.current <= #spec.balePlaces or spec.animations.moveBalePlacesAlways) then
                    self:playAnimation(spec.animations.moveBalePlaces, 1, (spec.startBalePlace.current - 1) / #spec.balePlaces, true)
                    self:setAnimationStopTime(spec.animations.moveBalePlaces, spec.startBalePlace.current / #spec.balePlaces)
                    self:playAnimation(spec.animations.moveBalePlacesExtrasOnce, 1, nil, true)
                    return
                end
            else
                if id == BaleLoader.CHANGE_EMPTY_ROTATE_PLATFORM then
                    spec.emptyState = BaleLoader.EMPTY_ROTATE_PLATFORM
                    if spec.startBalePlace == nil or spec.startBalePlace.count ~= 0 then
                        BaleLoader.rotatePlatform(self)
                    else
                        self:playAnimation(spec.animations.rotatePlatformEmpty, 1, nil, true)
                    end
                end
                if id == BaleLoader.CHANGE_EMPTY_ROTATE1 then
                    self:playAnimation(spec.animations.emptyRotate, 1, nil, true)
                    self:setAnimationStopTime(spec.animations.emptyRotate, 0.2)
                    local baleLines = self:getRealAnimationTime(spec.animations.moveBalePlaces)
                    local packBales = spec.animations.moveBalePlacesToEmptySpeed
                    if spec.animations.pusherPushBalesOnEmpty and spec.startBalePlace ~= nil then
                        local packedFarmId = spec.startBalePlace.current
                        if #spec.startBalePlace.bales == 0 then
                        end
                        local packedFillType = self:getAnimationDuration(spec.animations.moveBalePlacesToEmpty)
                        local packedFillLevel = 1
                        if packedFillType > 0 then
                            packedFillLevel = 1 - baleLines / packedFillType
                        end
                        local baleObject = 1 - packedFarmId / #spec.balePlaces
                        packBales = spec.animations.moveBalePlacesToEmptySpeed * (baleObject / math.max(packedFillLevel, 0.0001))
                        if packBales > 0 then
                            self:playAnimation(spec.animations.pusherMoveToEmpty, packBales, 0, true)
                            self:setAnimationStopTime(spec.animations.pusherMoveToEmpty, baleObject)
                        end
                    else
                        local packedFarmId = 0
                        local packedFillType = self:getAnimationDuration(spec.animations.pusherMoveToEmpty)
                        if packedFillType > 0 then
                            packedFarmId = baleLines / packedFillType
                        end
                        self:playAnimation(spec.animations.pusherMoveToEmpty, spec.animations.moveBalePlacesToEmptySpeed, packedFarmId, true)
                    end
                    local packedFarmId = true
                    local packedFillType = spec.balePlaces[spec.startBalePlace.current - 1]
                    if packedFillType ~= nil and #packedFillType.bales < spec.startBalePlace.numOfPlaces then
                        packedFarmId = false
                    end
                    if spec.animations.moveBalePlacesToEmptyPushOffset > 0 and packedFarmId then
                        if packBales > 0 then
                            spec.animations.moveBalePlacesToEmptyPushOffsetDelay = spec.animations.moveBalePlacesToEmptyPushOffset * self:getAnimationDuration(spec.animations.pusherMoveToEmpty) / packBales
                            spec.animations.moveBalePlacesToEmptyPushOffsetTime = spec.animations.moveBalePlacesToEmptyPushOffsetDelay
                        end
                    else
                        local packedFillLevel = 0
                        local baleObject = self:getAnimationDuration(spec.animations.moveBalePlacesToEmpty)
                        if baleObject > 0 then
                            packedFillLevel = baleLines / baleObject
                        end
                        self:playAnimation(spec.animations.moveBalePlacesToEmpty, spec.animations.moveBalePlacesToEmptySpeed, packedFillLevel, true)
                    end
                    spec.emptyState = BaleLoader.EMPTY_ROTATE1
                    if self.isClient then
                        g_soundManager:playSample(spec.samples.emptyRotate)
                        return
                    end
                else
                    if id == BaleLoader.CHANGE_EMPTY_CLOSE_GRIPPERS then
                        self:playAnimation(spec.animations.closeGrippers, 1, nil, true)
                        spec.emptyState = BaleLoader.EMPTY_CLOSE_GRIPPERS
                        return
                    end
                    if id == BaleLoader.CHANGE_EMPTY_HIDE_PUSHER1 then
                        self:playAnimation(spec.animations.pusherEmptyHide1, 1, nil, true)
                        spec.emptyState = BaleLoader.EMPTY_HIDE_PUSHER1
                        return
                    end
                    if id == BaleLoader.CHANGE_EMPTY_HIDE_PUSHER2 then
                        if spec.animations.pusherHideOnEmpty then
                            self:playAnimation(spec.animations.pusherMoveToEmpty, -2, nil, true)
                            spec.emptyState = BaleLoader.EMPTY_HIDE_PUSHER2
                            return
                        end
                        if self.isServer then
                            g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_ROTATE2), true, nil, self)
                            return
                        end
                    else
                        if id == BaleLoader.CHANGE_EMPTY_ROTATE2 then
                            self:playAnimation(spec.animations.emptyRotate, 1, self:getAnimationTime(spec.animations.emptyRotate), true)
                            spec.emptyState = BaleLoader.EMPTY_ROTATE2
                            return
                        end
                        if id == BaleLoader.CHANGE_EMPTY_WAIT_TO_DROP then
                            spec.emptyState = BaleLoader.EMPTY_WAIT_TO_DROP
                            return
                        end
                        if id == BaleLoader.CHANGE_EMPTY_STATE_NIL then
                            spec.emptyState = BaleLoader.EMPTY_NONE
                            if GS_IS_MOBILE_VERSION then
                                if self.rootVehicle:getActionControllerDirection() < 0 then
                                    spec.controlledAction.parent:startActionSequence()
                                end
                            elseif spec.transportPositionAfterUnloading then
                                BaleLoader.moveToTransportPosition(self)
                                if self.isServer then
                                    g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_MOVE_TO_TRANSPORT), true, nil, self)
                                end
                            end
                            spec.automaticUnloadingInProgress = false
                            return
                        end
                        if id == BaleLoader.CHANGE_EMPTY_WAIT_TO_REDO then
                            spec.emptyState = BaleLoader.EMPTY_WAIT_TO_REDO
                            return
                        end
                        if id == BaleLoader.CHANGE_BUTTON_EMPTY then
                            assert(self.isServer)
                            if spec.emptyState == BaleLoader.EMPTY_NONE then
                                if BaleLoader.getAllowsStartUnloading(self) then
                                    g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_START), true, nil, self)
                                    return
                                end
                            else
                                if spec.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
                                    g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_DROP_BALES), true, nil, self)
                                    return
                                end
                                if spec.emptyState == BaleLoader.EMPTY_WAIT_TO_SINK then
                                    if not spec.unloadingMover.isActive then
                                        g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_SINK), true, nil, self)
                                        return
                                    end
                                elseif spec.emptyState == BaleLoader.EMPTY_WAIT_TO_REDO then
                                    g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_REDO), true, nil, self)
                                    return
                                end
                            end
                        elseif id == BaleLoader.CHANGE_BUTTON_EMPTY_ABORT then
                            assert(self.isServer)
                            if spec.emptyState ~= BaleLoader.EMPTY_NONE and spec.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
                                g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_CANCEL), true, nil, self)
                                return
                            end
                        elseif id == BaleLoader.CHANGE_BUTTON_WORK_TRANSPORT then
                            assert(self.isServer)
                            if spec.emptyState == BaleLoader.EMPTY_NONE and spec.grabberMoveState == nil then
                                if spec.isInWorkPosition then
                                    g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_MOVE_TO_TRANSPORT), true, nil, self)
                                    return
                                end
                                g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_MOVE_TO_WORK), true, nil, self)
                            end
                        end
                    end
                end
            end
        end
    end
end
function BaleLoader:getAllowsStartUnloading()
    local spec = self.spec_baleLoader
    if self:getFillUnitFillLevel(spec.fillUnitIndex) == 0 then
        return false
    elseif spec.rotatePlatformDirection == 0 then
        if spec.frontBalePusherDirection == 0 then
            if spec.grabberIsMoving or spec.grabberMoveState ~= nil then
                return false
            else
                return spec.emptyState == BaleLoader.EMPTY_NONE
            end
        else
            return false
        end
    else
        return false
    end
end
function BaleLoader:rotatePlatform()
    local spec = self.spec_baleLoader
    spec.rotatePlatformDirection = 1
    self:playAnimation(spec.animations.rotatePlatform, 1, nil, true)
    if spec.startBalePlace.current > 1 and not spec.animations.moveBalePlacesAfterRotatePlatform or spec.animations.moveBalePlacesAlways then
        self:playAnimation(spec.animations.moveBalePlaces, 1, (spec.startBalePlace.current - 1) / #spec.balePlaces, true)
        self:setAnimationStopTime(spec.animations.moveBalePlaces, spec.startBalePlace.current / #spec.balePlaces)
        self:playAnimation(spec.animations.moveBalePlacesExtrasOnce, 1, nil, true)
    end
end
function BaleLoader:moveToWorkPosition(onLoad)
    local spec = self.spec_baleLoader
    self:playBaleLoaderFoldingAnimation(onLoad and 9999 or 1)
    local animTime = nil
    if self:getAnimationTime(spec.animations.closeGrippers) ~= 0 then
        animTime = self:getAnimationTime(spec.animations.closeGrippers)
    end
    self:playAnimation(spec.animations.closeGrippers, -1, animTime, true)
end
function BaleLoader:moveToTransportPosition()
    self:playBaleLoaderFoldingAnimation(-1)
    local spec = self.spec_baleLoader
    self:playAnimation(spec.animations.closeGrippers, 1, math.clamp(self:getAnimationTime(spec.animations.closeGrippers), 0, 1), true)
end
function BaleLoader:getBaleGrabberDropBaleAnimName()
    local spec = self.spec_baleLoader
    local name = string.format("%s%d", spec.animations.baleGrabberDropBale, spec.startBalePlace.count)
    if self:getAnimationExists(name) then
        return name
    else
        return spec.animations.baleGrabberDropBale
    end
end
function BaleLoader:getIsBaleGrabbingAllowed()
    local spec = self.spec_baleLoader
    if spec.isInWorkPosition then
        if spec.grabberIsMoving or spec.grabberMoveState ~= nil then
            return false
        elseif spec.startBalePlace.count >= spec.startBalePlace.numOfPlaces then
            return false
        elseif spec.frontBalePusherDirection == 0 then
            if spec.animations.rotatePlatformAllowPickup or spec.rotatePlatformDirection == 0 then
                if spec.animations.moveBalePlacesAlways and self:getIsAnimationPlaying(spec.animations.moveBalePlaces) then
                    return false
                elseif spec.emptyState == BaleLoader.EMPTY_NONE then
                    return self:getFillUnitFreeCapacity(spec.fillUnitIndex) ~= 0
                else
                    return false
                end
            else
                return false
            end
        else
            return false
        end
    else
        return false
    end
end
function BaleLoader:pickupBale(nearestBale, nearestBaleType)
    self.spec_baleLoader.lastPickupTime = g_time
    self:setBaleLoaderBaleType(nearestBaleType.index)
    g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_GRAB_BALE, NetworkUtil.getObjectId(nearestBale)), true, nil, self)
end
function BaleLoader:setBaleLoaderBaleType(baleTypeIndex, forceUpdate)
    local spec = self.spec_baleLoader
    local newBaleType = spec.baleTypes[baleTypeIndex] or spec.baleTypes[1]
    if newBaleType ~= spec.currentBaleType then
        spec.currentBaleType = newBaleType
        spec.animations = newBaleType.animations
        if not spec.useSharedBalePlaces then
            if newBaleType.startBalePlace.node == nil then
                spec.startBalePlace = spec.defaultBalePlace.startBalePlace
            else
                spec.startBalePlace = newBaleType.startBalePlace
            end
            if #newBaleType.balePlaces > 0 then
                spec.balePlaces = newBaleType.balePlaces
            else
                spec.balePlaces = spec.defaultBalePlace.balePlaces
            end
        end
        spec.fillUnitIndex = newBaleType.fillUnitIndex
        local i = 1
        for i = i, #spec.baleTypes do
            local baleType = spec.baleTypes[i]
            local fillUnit = self:getFillUnitByIndex(baleType.fillUnitIndex)
            if fillUnit.showOnHudOrig == nil then
                fillUnit.showOnHudOrig = fillUnit.showOnHud
            end
            if fillUnit.showOnHudOrig then
                fillUnit.showOnHud = baleType.fillUnitIndex == spec.fillUnitIndex
            end
        end
        ObjectChangeUtil.setObjectChanges(newBaleType.changeObjects, true, self, self.setMovingToolDirty, forceUpdate)
    end
end
function BaleLoader:getBaleTypeByBale(bale)
    for _, baleType in pairs(self.spec_baleLoader.baleTypes) do
        local dimensions = baleType.dimensions
        if dimensions.isRoundbale then
            if dimensions.isRoundbale and (bale.width >= dimensions.minWidth and (bale.width <= dimensions.maxWidth and (bale.diameter >= dimensions.minDiameter and bale.diameter <= dimensions.maxDiameter))) then
                return baleType
            end
        elseif not dimensions.isRoundbale and (bale.width >= dimensions.minWidth and (bale.width <= dimensions.maxWidth and (bale.height >= dimensions.minHeight and (bale.height <= dimensions.maxHeight and (bale.length >= dimensions.minLength and bale.length <= dimensions.maxLength))))) then
            return baleType
        end
    end
    return nil
end
function BaleLoader:baleGrabberTriggerCallback(_, otherId, onEnter, onLeave, _, _)
    if otherId ~= 0 then
        local rigidBodyType = getRigidBodyType(otherId)
        if self.isServer and rigidBodyType == RigidBodyType.DYNAMIC or not self.isServer and rigidBodyType == RigidBodyType.KINEMATIC then
            local object = g_currentMission:getNodeObject(otherId)
            if object ~= nil and object:isa(Bale) then
                local spec = self.spec_baleLoader
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
end
function BaleLoader:baleLoaderMoveTriggerCallback(_, otherId, onEnter, onLeave, _, _)
    if otherId ~= 0 and getRigidBodyType(otherId) == RigidBodyType.DYNAMIC then
        local object = g_currentMission:getNodeObject(otherId)
        if object ~= nil and object:isa(Bale) then
            if onEnter then
                self.spec_baleLoader.unloadingMover.balesInTrigger[object] = Utils.getNoNil(self.spec_baleLoader.unloadingMover.balesInTrigger[object], 0) + 1
                if spec.unloadingMover.balesInTrigger[object] == 1 then
                    object:addDeleteListener(self, "onBaleMoverBaleRemoved")
                    return
                end
            elseif onLeave and spec.unloadingMover.balesInTrigger[object] ~= nil then
                spec.unloadingMover.balesInTrigger[object] = math.max(0, spec.unloadingMover.balesInTrigger[object] - 1)
                if spec.unloadingMover.balesInTrigger[object] == 0 then
                    spec.unloadingMover.balesInTrigger[object] = nil
                    object:removeDeleteListener(self, "onBaleMoverBaleRemoved")
                end
            end
        end
    end
end
function BaleLoader:mountDynamicBale(bale, node)
    if self.isServer then
        if bale.dynamicMountJointIndex == nil or bale.baleLoaderDynamicJointNode == nil then
            local x = createTransformGroup("baleJoint")
            link(node, x)
            bale.baleLoaderDynamicJointNode = x
            if self.spec_baleLoader.dynamicMount.jointInterpolation then
                setWorldTranslation(x, getWorldTranslation(bale.nodeId))
                setWorldRotation(x, getWorldRotation(bale.nodeId))
            else
                local y, z, rx = getWorldTranslation(x)
                local ry, rz, quatZ, quatW = getWorldQuaternion(x)
                removeFromPhysics(bale.nodeId)
                bale:setWorldPositionQuaternion(y, z, rx, ry, rz, quatZ, quatW, true)
                addToPhysics(bale.nodeId)
                link(x, bale.meshNode)
            end
            bale:mountDynamic(self, self:getParentComponent(node), x, DynamicMountUtil.TYPE_FIX_ATTACH, 0, false)
            bale:setNeedsSaving(false)
            if spec.dynamicMount.minTransLimits ~= nil and spec.dynamicMount.maxTransLimits ~= nil then
                local ry = 1
                for ry = ry, 3 do
                    local rz = true
                    if spec.dynamicMount.minTransLimits[ry] == 0 then
                        rz = spec.dynamicMount.maxTransLimits[ry] ~= 0
                    end
                    if rz then
                        setJointTranslationLimit(bale.dynamicMountJointIndex, ry - 1, rz, spec.dynamicMount.minTransLimits[ry], spec.dynamicMount.maxTransLimits[ry])
                    end
                end
            end
            if spec.dynamicMount.jointInterpolation then
                table.insert(spec.dynamicMount.baleJointsToUpdate, {
                    ["node"] = bale.baleLoaderDynamicJointNode,
                    ["time"] = 0
                })
            end
            spec.dynamicMount.baleMassDirty = true
        else
            local x, y, z = getWorldTranslation(bale.baleLoaderDynamicJointNode)
            local rx, ry, rz = getWorldRotation(bale.baleLoaderDynamicJointNode)
            link(node, bale.baleLoaderDynamicJointNode)
            setWorldTranslation(bale.baleLoaderDynamicJointNode, x, y, z)
            setWorldRotation(bale.baleLoaderDynamicJointNode, rx, ry, rz)
            setJointFrame(bale.dynamicMountJointIndex, 0, bale.baleLoaderDynamicJointNode)
            if spec.dynamicMount.jointInterpolation then
                table.insert(spec.dynamicMount.baleJointsToUpdate, {
                    ["node"] = bale.baleLoaderDynamicJointNode,
                    ["time"] = 0
                })
                return
            end
        end
    end
end
function BaleLoader:unmountDynamicBale(bale)
    if self.isServer then
        bale:unmountDynamic()
        bale:setNeedsSaving(true)
        if bale.baleLoaderDynamicJointNode ~= nil then
            delete(bale.baleLoaderDynamicJointNode)
            bale.baleLoaderDynamicJointNode = nil
        end
        self.spec_baleLoader.dynamicMount.baleJointsToUpdate = {}
        if bale.backupMass ~= nil then
            setMass(bale.nodeId, bale.backupMass)
            bale.backupMass = nil
        end
    end
end
function BaleLoader:mountBale(bale, object, node, x, y, z, rx, ry, rz, noKinematicMounting)
    local spec = self.spec_baleLoader
    if spec.unloadingMover.balesInTrigger[bale] ~= nil then
        spec.unloadingMover.balesInTrigger[bale] = nil
    end
    if noKinematicMounting == true or not spec.allowKinematicMounting then
        bale:mount(object, node, x, y, z, rx, ry, rz)
        bale:setNeedsSaving(false)
    else
        bale:mountKinematic(object, node, x, y, z, rx, ry, rz)
        bale:setNeedsSaving(false)
        if not table.hasElement(spec.kinematicMountedBales, bale) then
            self:setBalePairCollision(bale, false)
            table.addElement(spec.kinematicMountedBales, bale)
        end
    end
end
function BaleLoader:unmountBale(bale)
    if bale.dynamicMountType == MountableObject.MOUNT_TYPE_DEFAULT then
        bale:unmount()
        bale:setNeedsSaving(true)
    elseif bale.dynamicMountType == MountableObject.MOUNT_TYPE_KINEMATIC then
        bale:unmountKinematic()
        bale:setNeedsSaving(true)
        table.removeElement(self.spec_baleLoader.kinematicMountedBales, bale)
        self:setBalePairCollision(bale, true)
    end
end
function BaleLoader:setBalePairCollision(bale, state)
    local spec = self.spec_baleLoader
    local i = 1
    for i = i, #self.components do
        setPairCollision(self.components[i].node, bale.nodeId, state)
    end
    local i = 1
    for i = i, #spec.kinematicMountedBales do
        setPairCollision(spec.kinematicMountedBales[i].nodeId, bale.nodeId, state)
    end
end
function BaleLoader:getLoadedBales()
    local bales = {}
    local spec = self.spec_baleLoader
    for _, balePlace in pairs(spec.balePlaces) do
        if balePlace.bales ~= nil then
            for _, baleServerId in pairs(balePlace.bales) do
                local bale = NetworkUtil.getObject(baleServerId)
                if bale ~= nil then
                    table.insert(bales, bale)
                end
            end
        end
    end
    for _, balePlace in ipairs(spec.startBalePlace.bales) do
        local bale = NetworkUtil.getObject(balePlace)
        if bale ~= nil then
            table.insert(bales, bale)
        end
    end
    return bales
end
function BaleLoader:startAutomaticBaleUnloading()
    local spec = self.spec_baleLoader
    spec.automaticUnloadingInProgress = true
    if spec.automaticUnloadingAdditionalBalesToLoad == 0 then
        spec.automaticUnloadingAdditionalBalesToLoad = -1
    end
    g_client:getServerConnection():sendEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_BUTTON_EMPTY))
end
function BaleLoader:getIsAutomaticBaleUnloadingInProgress()
    return self.spec_baleLoader.automaticUnloadingInProgress
end
function BaleLoader:getIsAutomaticBaleUnloadingAllowed()
    if self:getIsAutomaticBaleUnloadingInProgress() then
        return false
    elseif self.spec_baleLoader.lastPickupTime + self.spec_baleLoader.lastPickupAutomatedUnloadingDelayTime > g_time then
        return false
    else
        return BaleLoader.getAllowsStartUnloading(self) and true or false
    end
end
function BaleLoader:playBaleLoaderFoldingAnimation(speed)
    local animationName = self:getCurrentFoldingAnimation()
    self:playAnimation(animationName, speed, math.clamp(self:getAnimationTime(animationName), 0, 1), true)
end
function BaleLoader:getIsBaleLoaderFoldingPlaying()
    return self:getIsAnimationPlaying(self:getCurrentFoldingAnimation())
end
function BaleLoader:getCurrentFoldingAnimation()
    local spec = self.spec_baleLoader
    if spec.hasMultipleFoldingAnimations then
        return spec.lastFoldingAnimation
    else
        return spec.animations.baleGrabberTransportToWork
    end
end
function BaleLoader:updateFoldingAnimation()
    local spec = self.spec_baleLoader
    local name = spec.animations.baleGrabberTransportToWork
    local fillLevel = MathUtil.round(self:getFillUnitFillLevel(spec.fillUnitIndex))
    local baleTypeIndex = 1
    if spec.currentBaleType ~= nil then
        baleTypeIndex = spec.currentBaleType.index
    end
    for _, foldingAnimation in ipairs(spec.foldingAnimations) do
        if (foldingAnimation.baleTypeIndex == 0 or foldingAnimation.baleTypeIndex == baleTypeIndex) and (foldingAnimation.minFillLevel <= fillLevel and (fillLevel <= foldingAnimation.maxFillLevel and (foldingAnimation.minBalePlace <= #spec.startBalePlace.bales and #spec.startBalePlace.bales <= foldingAnimation.maxBalePlace))) then
            name = foldingAnimation.name
            break
        end
    end
    if name ~= spec.lastFoldingAnimation then
        if spec.lastFoldingAnimation ~= nil then
            self:setAnimationTime(name, self:getAnimationTime(spec.lastFoldingAnimation), false)
        end
        spec.lastFoldingAnimation = name
    end
end
function BaleLoader:onBaleMoverBaleRemoved(bale)
    self.spec_baleLoader.unloadingMover.balesInTrigger[bale] = nil
end
function BaleLoader:onBaleUnloadTriggerDeleted(unloadTrigger)
    local spec = self.spec_baleLoader
    if spec.baleUnloadTriggers[unloadTrigger] ~= nil then
        spec.baleUnloadTriggers[unloadTrigger] = nil
    end
end
function BaleLoader:addBaleUnloadTrigger(unloadTrigger)
    local spec = self.spec_baleLoader
    spec.baleUnloadTriggers[unloadTrigger] = (spec.baleUnloadTriggers[unloadTrigger] or 0) + 1
    unloadTrigger:addDeleteListener(self, BaleLoader.onBaleUnloadTriggerDeleted)
    self:raiseActive()
end
function BaleLoader:removeBaleUnloadTrigger(unloadTrigger)
    local spec = self.spec_baleLoader
    spec.baleUnloadTriggers[unloadTrigger] = (spec.baleUnloadTriggers[unloadTrigger] or 0) - 1
    if spec.baleUnloadTriggers[unloadTrigger] <= 0 then
        spec.baleUnloadTriggers[unloadTrigger] = nil
        unloadTrigger:removeDeleteListener(self, BaleLoader.onBaleUnloadTriggerDeleted)
    end
end
function BaleLoader:getCanBeSelected(superFunc)
    return true
end
function BaleLoader:getAllowDynamicMountFillLevelInfo(superFunc)
    if self.spec_baleLoader.dynamicMount.enabled then
        return false
    else
        return superFunc(self)
    end
end
function BaleLoader:getAreControlledActionsAllowed(superFunc)
    if self:getIsAutomaticBaleUnloadingInProgress() then
        return false
    else
        return superFunc(self)
    end
end
function BaleLoader:getIsAIReadyToDrive(superFunc)
    local spec = self.spec_baleLoader
    if spec.isInWorkPosition or spec.grabberIsMoving then
        return false
    else
        return superFunc(self)
    end
end
function BaleLoader:getIsAIPreparingToDrive(superFunc)
    return self.spec_baleLoader.grabberIsMoving and true or superFunc(self)
end
function BaleLoader:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
    if self:getFillUnitFillLevel(self.spec_baleLoader.fillUnitIndex) > 0 then
        return false
    else
        return superFunc(self, direction, onAiTurnOn)
    end
end
function BaleLoader:getDoConsumePtoPower(superFunc)
    local spec = self.spec_baleLoader
    return spec.consumePtoPower and (spec.isInWorkPosition or spec.grabberIsMoving) and true or superFunc(self)
end
function BaleLoader:getConsumingLoad(superFunc)
    local value, count = superFunc(self)
    local spec = self.spec_baleLoader
    return value + (spec.consumePtoPower and (spec.isInWorkPosition or spec.grabberIsMoving) and 1 or 0), count + 1
end
function BaleLoader:getIsPowerTakeOffActive(superFunc)
    local spec = self.spec_baleLoader
    return spec.consumePtoPower and (spec.isInWorkPosition or spec.grabberIsMoving) and true or superFunc(self)
end
function BaleLoader:addToPhysics(superFunc)
    if not superFunc(self) then
        return false
    end
    local spec = self.spec_baleLoader
    for _, balePlace in pairs(spec.balePlaces) do
        if balePlace.bales ~= nil then
            for _, baleServerId in pairs(balePlace.bales) do
                local bale = NetworkUtil.getObject(baleServerId)
                if bale ~= nil then
                    bale:addToPhysics()
                    if spec.dynamicMount.enabled then
                        self:mountDynamicBale(bale, balePlace.node)
                    else
                        local x, y, z = localToLocal(bale.nodeId, balePlace.node, 0, 0, 0)
                        local rx, ry, rz = localRotationToLocal(bale.nodeId, balePlace.node, 0, 0, 0)
                        self:mountBale(bale, self, balePlace.node, x, y, z, rx, ry, rz)
                    end
                end
            end
        end
    end
    for _, balePlace in ipairs(spec.startBalePlace.bales) do
        local bale = NetworkUtil.getObject(balePlace)
        if bale ~= nil then
            bale:addToPhysics()
            local attachNode = getChildAt(spec.startBalePlace.node, spec.startBalePlace.count)
            if spec.dynamicMount.enabled then
                self:mountDynamicBale(bale, attachNode)
            else
                local x, _, baleServerId = localToLocal(bale.nodeId, attachNode, 0, 0, 0)
                local bale, x, y = localRotationToLocal(bale.nodeId, attachNode, 0, 0, 0)
                self:mountBale(bale, self, attachNode, x, _, baleServerId, bale, x, y)
            end
        end
    end
    return true
end
function BaleLoader:removeFromPhysics(superFunc)
    if not superFunc(self) then
        return false
    end
    local spec = self.spec_baleLoader
    for _, balePlace in pairs(spec.balePlaces) do
        if balePlace.bales ~= nil then
            for _, baleServerId in pairs(balePlace.bales) do
                local bale = NetworkUtil.getObject(baleServerId)
                if bale ~= nil then
                    if spec.dynamicMount.enabled then
                        self:unmountDynamicBale(bale)
                    else
                        self:unmountBale(bale)
                    end
                    bale:removeFromPhysics()
                end
            end
        end
    end
    for _, balePlace in ipairs(spec.startBalePlace.bales) do
        local bale = NetworkUtil.getObject(balePlace)
        if bale ~= nil then
            if spec.dynamicMount.enabled then
                self:unmountDynamicBale(bale)
            else
                self:unmountBale(bale)
            end
            bale:removeFromPhysics()
        end
    end
    return true
end
function BaleLoader:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_baleLoader
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection then
            if not spec.useFoldingState then
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA, self, BaleLoader.actionEventWorkTransport, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            end
            if not spec.fullAutomaticUnloading then
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, BaleLoader.actionEventEmpty, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA2, self, BaleLoader.actionEventAbortEmpty, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
                g_inputBinding:setActionEventText(actionEventId, spec.texts.abortUnloading)
            end
        end
    end
end
function BaleLoader:actionEventEmpty(_, _, _, _)
    local spec = self.spec_baleLoader
    if self:getFillUnitFillLevel(spec.fillUnitIndex) >= spec.minUnloadingFillLevel or spec.emptyState ~= BaleLoader.EMPTY_NONE then
        g_client:getServerConnection():sendEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_BUTTON_EMPTY))
    else
        g_currentMission:showBlinkingWarning(spec.texts.minUnloadingFillLevelWarning, 2500)
    end
end
function BaleLoader:actionEventAbortEmpty(_, _, _, _)
    g_client:getServerConnection():sendEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_BUTTON_EMPTY_ABORT))
end
function BaleLoader:actionEventWorkTransport(_, _, _, _)
    g_client:getServerConnection():sendEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_BUTTON_WORK_TRANSPORT))
end
function BaleLoader.loadSpecValueBaleSize(xmlFile, _, _, roundBaleLoader)
    local baleSizeAttributes = {
        ["minDiameter"] = math.huge,
        ["maxDiameter"] = -math.huge,
        ["minLength"] = math.huge,
        ["maxLength"] = -math.huge
    }
    xmlFile:iterate(xmlFile:getRootName() .. ".baleLoader.baleTypes.baleType", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) roundBaleLoader, (copy) baleSizeAttributes
        local diameter = true
        if xmlFile:getValue(key .. "#diameter") == nil then
            diameter = true
            if xmlFile:getValue(key .. "#minDiameter") == nil then
                diameter = xmlFile:getValue(key .. "#maxDiameter") ~= nil
            end
        end
        if diameter == roundBaleLoader then
            local diameter = MathUtil.round(xmlFile:getValue(key .. "#diameter"), 2)
            local minDiameter = MathUtil.round(xmlFile:getValue(key .. "#minDiameter"), 2)
            local maxDiameter = MathUtil.round(xmlFile:getValue(key .. "#maxDiameter"), 2)
            baleSizeAttributes.minDiameter = math.min(baleSizeAttributes.minDiameter, diameter or baleSizeAttributes.minDiameter, minDiameter or baleSizeAttributes.minDiameter, maxDiameter or baleSizeAttributes.minDiameter)
            baleSizeAttributes.maxDiameter = math.max(baleSizeAttributes.maxDiameter, diameter or baleSizeAttributes.maxDiameter, minDiameter or baleSizeAttributes.maxDiameter, maxDiameter or baleSizeAttributes.maxDiameter)
            local minLength = MathUtil.round(xmlFile:getValue(key .. "#minLength"), 2)
            baleSizeAttributes.minLength = math.min(baleSizeAttributes.minLength, MathUtil.round(xmlFile:getValue(key .. "#length"), 2) or baleSizeAttributes.minLength, minLength or baleSizeAttributes.minLength, MathUtil.round(xmlFile:getValue(key .. "#maxLength"), 2) or baleSizeAttributes.minLength)
            baleSizeAttributes.maxLength = math.max(baleSizeAttributes.maxLength, length or baleSizeAttributes.maxLength, minLength or baleSizeAttributes.maxLength, maxLength or baleSizeAttributes.maxLength)
        end
    end)
    if baleSizeAttributes.minDiameter == math.huge and baleSizeAttributes.minLength == math.huge then
        return nil
    else
        return baleSizeAttributes
    end
end
function BaleLoader.getSpecValueBaleSize(storeItem, _, _, _, returnValues, returnRange, roundBaleLoader)
    local baleSizeAttributes = roundBaleLoader and storeItem.specs.baleLoaderBaleSizeRound or storeItem.specs.baleLoaderBaleSizeSquare
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
        if (roundBaleLoader and baleSizeAttributes.maxDiameter or baleSizeAttributes.maxLength) == (roundBaleLoader and baleSizeAttributes.minDiameter or baleSizeAttributes.minLength) then
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
function BaleLoader.loadSpecValueBaleSizeRound(xmlFile, customEnvironment, baseDir)
    return BaleLoader.loadSpecValueBaleSize(xmlFile, customEnvironment, baseDir, true)
end
function BaleLoader.loadSpecValueBaleSizeSquare(xmlFile, customEnvironment, baseDir)
    return BaleLoader.loadSpecValueBaleSize(xmlFile, customEnvironment, baseDir, false)
end
function BaleLoader.getSpecValueBaleSizeRound(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
    if storeItem.specs.baleLoaderBaleSizeRound == nil then
        return nil
    else
        return BaleLoader.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, true)
    end
end
function BaleLoader.getSpecValueBaleSizeSquare(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
    if storeItem.specs.baleLoaderBaleSizeSquare == nil then
        return nil
    else
        return BaleLoader.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, false)
    end
end