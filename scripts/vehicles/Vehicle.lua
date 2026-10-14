Vehicle = {}
local Vehicle_mt = Class(Vehicle, Object)
Vehicle.defaultWidth = 6
Vehicle.defaultLength = 8
Vehicle.defaultHeight = 4
Vehicle.DEFAULT_SIZE = {
    ["width"] = Vehicle.defaultWidth,
    ["length"] = Vehicle.defaultLength,
    ["height"] = Vehicle.defaultHeight,
    ["widthOffset"] = 0,
    ["lengthOffset"] = 0,
    ["heightOffset"] = 0
}
Vehicle.SPRING_SCALE = 10
Vehicle.NUM_INTERACTION_FLAGS = 0
Vehicle.INTERACTION_FLAG_NONE = 0
Vehicle.NUM_STATE_CHANGES = 0
Vehicle.DAMAGED_SPEEDLIMIT_REDUCTION = 0.3
Vehicle.INPUT_CONTEXT_NAME = "VEHICLE"
Vehicle.xmlSchema = nil
Vehicle.xmlSchemaSounds = nil
Vehicle.xmlSchemaSavegame = nil
Vehicle.DEBUG_NETWORK_READ_WRITE = false
Vehicle.DEBUG_NETWORK_READ_WRITE_UPDATE = false
Vehicle.DEBUG_RANDOM_FAIL_LOADING = false
InitStaticObjectClass(Vehicle, "Vehicle")
source("dataS/scripts/vehicles/VehicleDebug.lua")
source("dataS/scripts/vehicles/VehicleStateRecorder.lua")
source("dataS/scripts/vehicles/VehicleSchemaOverlayData.lua")
source("dataS/scripts/vehicles/VehicleBrokenEvent.lua")
source("dataS/scripts/vehicles/VehiclePropertyState.lua")
source("dataS/scripts/vehicles/VehicleStateChange.lua")
source("dataS/scripts/vehicles/VehicleSetIsReconfiguratingEvent.lua")
source("dataS/scripts/vehicles/VehicleTeleportEvent.lua")
function Vehicle.registerInteractionFlag(name)
    local key = "INTERACTION_FLAG_" .. string.upper(name)
    if Vehicle[key] == nil then
        Vehicle.NUM_INTERACTION_FLAGS = Vehicle.NUM_INTERACTION_FLAGS + 1
        Vehicle[key] = Vehicle.NUM_INTERACTION_FLAGS
    end
    return Vehicle[key]
end
function Vehicle.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onPreLoad")
    SpecializationUtil.registerEvent(vehicleType, "onLoad")
    SpecializationUtil.registerEvent(vehicleType, "onPostLoad")
    SpecializationUtil.registerEvent(vehicleType, "onPreInitComponentPlacement")
    SpecializationUtil.registerEvent(vehicleType, "onPreLoadFinished")
    SpecializationUtil.registerEvent(vehicleType, "onLoadFinished")
    SpecializationUtil.registerEvent(vehicleType, "onLoadEnd")
    SpecializationUtil.registerEvent(vehicleType, "onRegistered")
    SpecializationUtil.registerEvent(vehicleType, "onDirtyMaskCleared")
    SpecializationUtil.registerEvent(vehicleType, "onPreDelete")
    SpecializationUtil.registerEvent(vehicleType, "onDelete")
    SpecializationUtil.registerEvent(vehicleType, "onSave")
    SpecializationUtil.registerEvent(vehicleType, "onReadStream")
    SpecializationUtil.registerEvent(vehicleType, "onWriteStream")
    SpecializationUtil.registerEvent(vehicleType, "onReadUpdateStream")
    SpecializationUtil.registerEvent(vehicleType, "onWriteUpdateStream")
    SpecializationUtil.registerEvent(vehicleType, "onReadPositionUpdateStream")
    SpecializationUtil.registerEvent(vehicleType, "onWritePositionUpdateStream")
    SpecializationUtil.registerEvent(vehicleType, "onHandToolTaken")
    SpecializationUtil.registerEvent(vehicleType, "onHandToolPlaced")
    SpecializationUtil.registerEvent(vehicleType, "onPreUpdate")
    SpecializationUtil.registerEvent(vehicleType, "onUpdate")
    SpecializationUtil.registerEvent(vehicleType, "onUpdateInterpolation")
    SpecializationUtil.registerEvent(vehicleType, "onUpdateDebug")
    SpecializationUtil.registerEvent(vehicleType, "onPostUpdate")
    SpecializationUtil.registerEvent(vehicleType, "onUpdateTick")
    SpecializationUtil.registerEvent(vehicleType, "onPostUpdateTick")
    SpecializationUtil.registerEvent(vehicleType, "onUpdateEnd")
    SpecializationUtil.registerEvent(vehicleType, "onDraw")
    SpecializationUtil.registerEvent(vehicleType, "onDrawUIInfo")
    SpecializationUtil.registerEvent(vehicleType, "onActivate")
    SpecializationUtil.registerEvent(vehicleType, "onDeactivate")
    SpecializationUtil.registerEvent(vehicleType, "onStateChange")
    SpecializationUtil.registerEvent(vehicleType, "onPreRegisterActionEvents")
    SpecializationUtil.registerEvent(vehicleType, "onRegisterActionEvents")
    SpecializationUtil.registerEvent(vehicleType, "onRootVehicleChanged")
    SpecializationUtil.registerEvent(vehicleType, "onSelect")
    SpecializationUtil.registerEvent(vehicleType, "onUnselect")
    SpecializationUtil.registerEvent(vehicleType, "onSetBroken")
    SpecializationUtil.registerEvent(vehicleType, "onSaleItemSet")
end
function Vehicle.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "register", Vehicle.register)
    SpecializationUtil.registerFunction(vehicleType, "setOwnerFarmId", Vehicle.setOwnerFarmId)
    SpecializationUtil.registerFunction(vehicleType, "loadSubSharedI3DFile", Vehicle.loadSubSharedI3DFile)
    SpecializationUtil.registerFunction(vehicleType, "drawUIInfo", Vehicle.drawUIInfo)
    SpecializationUtil.registerFunction(vehicleType, "raiseActive", Vehicle.raiseActive)
    SpecializationUtil.registerFunction(vehicleType, "setLoadingState", Vehicle.setLoadingState)
    SpecializationUtil.registerFunction(vehicleType, "setLoadingStep", Vehicle.setLoadingStep)
    SpecializationUtil.registerFunction(vehicleType, "addToPhysics", Vehicle.addToPhysics)
    SpecializationUtil.registerFunction(vehicleType, "removeFromPhysics", Vehicle.removeFromPhysics)
    SpecializationUtil.registerFunction(vehicleType, "setVisibility", Vehicle.setVisibility)
    SpecializationUtil.registerFunction(vehicleType, "setRelativePosition", Vehicle.setRelativePosition)
    SpecializationUtil.registerFunction(vehicleType, "setAbsolutePosition", Vehicle.setAbsolutePosition)
    SpecializationUtil.registerFunction(vehicleType, "getLimitedVehicleYPosition", Vehicle.getLimitedVehicleYPosition)
    SpecializationUtil.registerFunction(vehicleType, "setWorldPosition", Vehicle.setWorldPosition)
    SpecializationUtil.registerFunction(vehicleType, "setWorldPositionQuaternion", Vehicle.setWorldPositionQuaternion)
    SpecializationUtil.registerFunction(vehicleType, "setDefaultComponentPosition", Vehicle.setDefaultComponentPosition)
    SpecializationUtil.registerFunction(vehicleType, "getIsNodeActive", Vehicle.getIsNodeActive)
    SpecializationUtil.registerFunction(vehicleType, "updateVehicleSpeed", Vehicle.updateVehicleSpeed)
    SpecializationUtil.registerFunction(vehicleType, "getUpdatePriority", Vehicle.getUpdatePriority)
    SpecializationUtil.registerFunction(vehicleType, "getPrice", Vehicle.getPrice)
    SpecializationUtil.registerFunction(vehicleType, "getSellPrice", Vehicle.getSellPrice)
    SpecializationUtil.registerFunction(vehicleType, "getDailyUpkeep", Vehicle.getDailyUpkeep)
    SpecializationUtil.registerFunction(vehicleType, "getIsOnField", Vehicle.getIsOnField)
    SpecializationUtil.registerFunction(vehicleType, "getParentComponent", Vehicle.getParentComponent)
    SpecializationUtil.registerFunction(vehicleType, "getLastSpeed", Vehicle.getLastSpeed)
    SpecializationUtil.registerFunction(vehicleType, "getDeactivateOnLeave", Vehicle.getDeactivateOnLeave)
    SpecializationUtil.registerFunction(vehicleType, "getOwnerConnection", Vehicle.getOwnerConnection)
    SpecializationUtil.registerFunction(vehicleType, "getIsVehicleNode", Vehicle.getIsVehicleNode)
    SpecializationUtil.registerFunction(vehicleType, "getIsOperating", Vehicle.getIsOperating)
    SpecializationUtil.registerFunction(vehicleType, "getIsActive", Vehicle.getIsActive)
    SpecializationUtil.registerFunction(vehicleType, "getIsActiveForInput", Vehicle.getIsActiveForInput)
    SpecializationUtil.registerFunction(vehicleType, "getIsActiveForSound", Vehicle.getIsActiveForSound)
    SpecializationUtil.registerFunction(vehicleType, "getIsLowered", Vehicle.getIsLowered)
    SpecializationUtil.registerFunction(vehicleType, "updateWaterInfo", Vehicle.updateWaterInfo)
    SpecializationUtil.registerFunction(vehicleType, "onWaterRaycastCallback", Vehicle.onWaterRaycastCallback)
    SpecializationUtil.registerFunction(vehicleType, "setBroken", Vehicle.setBroken)
    SpecializationUtil.registerFunction(vehicleType, "getVehicleDamage", Vehicle.getVehicleDamage)
    SpecializationUtil.registerFunction(vehicleType, "getRepairPrice", Vehicle.getRepairPrice)
    SpecializationUtil.registerFunction(vehicleType, "getRepaintPrice", Vehicle.getRepaintPrice)
    SpecializationUtil.registerFunction(vehicleType, "setMassDirty", Vehicle.setMassDirty)
    SpecializationUtil.registerFunction(vehicleType, "updateMass", Vehicle.updateMass)
    SpecializationUtil.registerFunction(vehicleType, "getMaxComponentMassReached", Vehicle.getMaxComponentMassReached)
    SpecializationUtil.registerFunction(vehicleType, "getAdditionalComponentMass", Vehicle.getAdditionalComponentMass)
    SpecializationUtil.registerFunction(vehicleType, "getTotalMass", Vehicle.getTotalMass)
    SpecializationUtil.registerFunction(vehicleType, "getComponentMass", Vehicle.getComponentMass)
    SpecializationUtil.registerFunction(vehicleType, "getDefaultMass", Vehicle.getDefaultMass)
    SpecializationUtil.registerFunction(vehicleType, "getOverallCenterOfMass", Vehicle.getOverallCenterOfMass)
    SpecializationUtil.registerFunction(vehicleType, "getVehicleWorldXRot", Vehicle.getVehicleWorldXRot)
    SpecializationUtil.registerFunction(vehicleType, "getVehicleWorldDirection", Vehicle.getVehicleWorldDirection)
    SpecializationUtil.registerFunction(vehicleType, "getFillLevelInformation", Vehicle.getFillLevelInformation)
    SpecializationUtil.registerFunction(vehicleType, "getHasObjectMounted", Vehicle.getHasObjectMounted)
    SpecializationUtil.registerFunction(vehicleType, "activate", Vehicle.activate)
    SpecializationUtil.registerFunction(vehicleType, "deactivate", Vehicle.deactivate)
    SpecializationUtil.registerFunction(vehicleType, "setComponentJointFrame", Vehicle.setComponentJointFrame)
    SpecializationUtil.registerFunction(vehicleType, "setComponentJointRotLimit", Vehicle.setComponentJointRotLimit)
    SpecializationUtil.registerFunction(vehicleType, "setComponentJointTransLimit", Vehicle.setComponentJointTransLimit)
    SpecializationUtil.registerFunction(vehicleType, "loadComponentFromXML", Vehicle.loadComponentFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadComponentJointFromXML", Vehicle.loadComponentJointFromXML)
    SpecializationUtil.registerFunction(vehicleType, "createComponentJoint", Vehicle.createComponentJoint)
    SpecializationUtil.registerFunction(vehicleType, "loadSchemaOverlay", Vehicle.loadSchemaOverlay)
    SpecializationUtil.registerFunction(vehicleType, "getAdditionalSchemaText", Vehicle.getAdditionalSchemaText)
    SpecializationUtil.registerFunction(vehicleType, "getUseTurnedOnSchema", Vehicle.getUseTurnedOnSchema)
    SpecializationUtil.registerFunction(vehicleType, "dayChanged", Vehicle.dayChanged)
    SpecializationUtil.registerFunction(vehicleType, "periodChanged", Vehicle.periodChanged)
    SpecializationUtil.registerFunction(vehicleType, "raiseStateChange", Vehicle.raiseStateChange)
    SpecializationUtil.registerFunction(vehicleType, "doCheckSpeedLimit", Vehicle.doCheckSpeedLimit)
    SpecializationUtil.registerFunction(vehicleType, "interact", Vehicle.interact)
    SpecializationUtil.registerFunction(vehicleType, "getInteractionHelp", Vehicle.getInteractionHelp)
    SpecializationUtil.registerFunction(vehicleType, "getIsInteractive", Vehicle.getIsInteractive)
    SpecializationUtil.registerFunction(vehicleType, "getDistanceToNode", Vehicle.getDistanceToNode)
    SpecializationUtil.registerFunction(vehicleType, "getIsAIActive", Vehicle.getIsAIActive)
    SpecializationUtil.registerFunction(vehicleType, "getIsPowered", Vehicle.getIsPowered)
    SpecializationUtil.registerFunction(vehicleType, "getRequiresPower", Vehicle.getRequiresPower)
    SpecializationUtil.registerFunction(vehicleType, "getIsInShowroom", Vehicle.getIsInShowroom)
    SpecializationUtil.registerFunction(vehicleType, "addVehicleToAIImplementList", Vehicle.addVehicleToAIImplementList)
    SpecializationUtil.registerFunction(vehicleType, "setOperatingTime", Vehicle.setOperatingTime)
    SpecializationUtil.registerFunction(vehicleType, "requestActionEventUpdate", Vehicle.requestActionEventUpdate)
    SpecializationUtil.registerFunction(vehicleType, "removeActionEvents", Vehicle.removeActionEvents)
    SpecializationUtil.registerFunction(vehicleType, "updateActionEvents", Vehicle.updateActionEvents)
    SpecializationUtil.registerFunction(vehicleType, "registerActionEvents", Vehicle.registerActionEvents)
    SpecializationUtil.registerFunction(vehicleType, "addActionEvent", Vehicle.addActionEvent)
    SpecializationUtil.registerFunction(vehicleType, "updateSelectableObjects", Vehicle.updateSelectableObjects)
    SpecializationUtil.registerFunction(vehicleType, "registerSelectableObjects", Vehicle.registerSelectableObjects)
    SpecializationUtil.registerFunction(vehicleType, "addSubselection", Vehicle.addSubselection)
    SpecializationUtil.registerFunction(vehicleType, "getRootVehicle", Vehicle.getRootVehicle)
    SpecializationUtil.registerFunction(vehicleType, "findRootVehicle", Vehicle.findRootVehicle)
    SpecializationUtil.registerFunction(vehicleType, "getChildVehicles", Vehicle.getChildVehicles)
    SpecializationUtil.registerFunction(vehicleType, "addChildVehicles", Vehicle.addChildVehicles)
    SpecializationUtil.registerFunction(vehicleType, "updateVehicleChain", Vehicle.updateVehicleChain)
    SpecializationUtil.registerFunction(vehicleType, "getCanBeSelected", Vehicle.getCanBeSelected)
    SpecializationUtil.registerFunction(vehicleType, "getBlockSelection", Vehicle.getBlockSelection)
    SpecializationUtil.registerFunction(vehicleType, "getCanToggleSelectable", Vehicle.getCanToggleSelectable)
    SpecializationUtil.registerFunction(vehicleType, "unselectVehicle", Vehicle.unselectVehicle)
    SpecializationUtil.registerFunction(vehicleType, "selectVehicle", Vehicle.selectVehicle)
    SpecializationUtil.registerFunction(vehicleType, "getIsSelected", Vehicle.getIsSelected)
    SpecializationUtil.registerFunction(vehicleType, "getSelectedObject", Vehicle.getSelectedObject)
    SpecializationUtil.registerFunction(vehicleType, "getSelectedVehicle", Vehicle.getSelectedVehicle)
    SpecializationUtil.registerFunction(vehicleType, "setSelectedVehicle", Vehicle.setSelectedVehicle)
    SpecializationUtil.registerFunction(vehicleType, "setSelectedObject", Vehicle.setSelectedObject)
    SpecializationUtil.registerFunction(vehicleType, "getIsReadyForAutomatedTrainTravel", Vehicle.getIsReadyForAutomatedTrainTravel)
    SpecializationUtil.registerFunction(vehicleType, "getIsAutomaticShiftingAllowed", Vehicle.getIsAutomaticShiftingAllowed)
    SpecializationUtil.registerFunction(vehicleType, "getSpeedLimit", Vehicle.getSpeedLimit)
    SpecializationUtil.registerFunction(vehicleType, "getRawSpeedLimit", Vehicle.getRawSpeedLimit)
    SpecializationUtil.registerFunction(vehicleType, "getActiveFarm", Vehicle.getActiveFarm)
    SpecializationUtil.registerFunction(vehicleType, "onVehicleWakeUpCallback", Vehicle.onVehicleWakeUpCallback)
    SpecializationUtil.registerFunction(vehicleType, "getCanBeMounted", Vehicle.getCanBeMounted)
    SpecializationUtil.registerFunction(vehicleType, "getName", Vehicle.getName)
    SpecializationUtil.registerFunction(vehicleType, "getFullName", Vehicle.getFullName)
    SpecializationUtil.registerFunction(vehicleType, "getBrand", Vehicle.getBrand)
    SpecializationUtil.registerFunction(vehicleType, "getImageFilename", Vehicle.getImageFilename)
    SpecializationUtil.registerFunction(vehicleType, "getCanBePickedUp", Vehicle.getCanBePickedUp)
    SpecializationUtil.registerFunction(vehicleType, "getCanBeReset", Vehicle.getCanBeReset)
    SpecializationUtil.registerFunction(vehicleType, "getResetPlaces", Vehicle.getResetPlaces)
    SpecializationUtil.registerFunction(vehicleType, "getCanBeSold", Vehicle.getCanBeSold)
    SpecializationUtil.registerFunction(vehicleType, "getCanBeAddedToSales", Vehicle.getCanBeAddedToSales)
    SpecializationUtil.registerFunction(vehicleType, "getReloadXML", Vehicle.getReloadXML)
    SpecializationUtil.registerFunction(vehicleType, "getIsInUse", Vehicle.getIsInUse)
    SpecializationUtil.registerFunction(vehicleType, "getPropertyState", Vehicle.getPropertyState)
    SpecializationUtil.registerFunction(vehicleType, "getAreControlledActionsAllowed", Vehicle.getAreControlledActionsAllowed)
    SpecializationUtil.registerFunction(vehicleType, "getAreControlledActionsAvailable", Vehicle.getAreControlledActionsAvailable)
    SpecializationUtil.registerFunction(vehicleType, "getAreControlledActionsAccessible", Vehicle.getAreControlledActionsAccessible)
    SpecializationUtil.registerFunction(vehicleType, "getControlledActionIcons", Vehicle.getControlledActionIcons)
    SpecializationUtil.registerFunction(vehicleType, "playControlledActions", Vehicle.playControlledActions)
    SpecializationUtil.registerFunction(vehicleType, "getActionControllerDirection", Vehicle.getActionControllerDirection)
    SpecializationUtil.registerFunction(vehicleType, "createMapHotspot", Vehicle.createMapHotspot)
    SpecializationUtil.registerFunction(vehicleType, "getMapHotspot", Vehicle.getMapHotspot)
    SpecializationUtil.registerFunction(vehicleType, "updateMapHotspot", Vehicle.updateMapHotspot)
    SpecializationUtil.registerFunction(vehicleType, "getIsMapHotspotVisible", Vehicle.getIsMapHotspotVisible)
    SpecializationUtil.registerFunction(vehicleType, "getMapHotspotRotation", Vehicle.getMapHotspotRotation)
    SpecializationUtil.registerFunction(vehicleType, "getMapHotspotPosition", Vehicle.getMapHotspotPosition)
    SpecializationUtil.registerFunction(vehicleType, "getShowInVehiclesOverview", Vehicle.getShowInVehiclesOverview)
    SpecializationUtil.registerFunction(vehicleType, "showInfo", Vehicle.showInfo)
    SpecializationUtil.registerFunction(vehicleType, "loadObjectChangeValuesFromXML", Vehicle.loadObjectChangeValuesFromXML)
    SpecializationUtil.registerFunction(vehicleType, "setObjectChangeValues", Vehicle.setObjectChangeValues)
    SpecializationUtil.registerFunction(vehicleType, "getIsSynchronized", Vehicle.getIsSynchronized)
end
function Vehicle.init()
    g_vehicleConfigurationManager:addConfigurationType("baseColor", g_i18n:getText("configuration_baseColor"), nil, VehicleConfigurationItemColor)
    g_vehicleConfigurationManager:addConfigurationType("vehicleType", g_i18n:getText("configuration_design"), nil, VehicleConfigurationItemVehicleType)
    g_vehicleConfigurationManager:addConfigurationType("component", g_i18n:getText("configuration_design"), "base", VehicleConfigurationItem)
    g_vehicleConfigurationManager:addConfigurationType("design", g_i18n:getText("configuration_design"), nil, VehicleConfigurationItem)
    g_vehicleConfigurationManager:addConfigurationType("designColor", g_i18n:getText("configuration_designColor"), nil, VehicleConfigurationItemColor)
    local i = 2
    for i = i, 16 do
        g_vehicleConfigurationManager:addConfigurationType(string.format("design%d", i), g_i18n:getText("configuration_design"), nil, VehicleConfigurationItem)
        g_vehicleConfigurationManager:addConfigurationType(string.format("designColor%d", i), g_i18n:getText("configuration_designColor"), nil, VehicleConfigurationItemColor)
    end
    g_storeManager:addSpecType("age", "shopListAttributeIconLifeTime", nil, Vehicle.getSpecValueAge, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("operatingTime", "shopListAttributeIconOperatingHours", nil, Vehicle.getSpecValueOperatingTime, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("dailyUpkeep", "shopListAttributeIconMaintenanceCosts", nil, Vehicle.getSpecValueDailyUpkeep, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("workingWidth", "shopListAttributeIconWorkingWidth", Vehicle.loadSpecValueWorkingWidth, Vehicle.getSpecValueWorkingWidth, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("workingWidthConfig", "shopListAttributeIconWorkingWidth", Vehicle.loadSpecValueWorkingWidthConfig, Vehicle.getSpecValueWorkingWidthConfig, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("speedLimit", "shopListAttributeIconWorkSpeed", Vehicle.loadSpecValueSpeedLimit, Vehicle.getSpecValueSpeedLimit, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("weight", "shopListAttributeIconWeight", Vehicle.loadSpecValueWeight, Vehicle.getSpecValueWeight, StoreSpecies.VEHICLE, nil, Vehicle.getSpecConfigValuesWeight)
    g_storeManager:addSpecType("additionalWeight", "shopListAttributeIconAdditionalWeight", Vehicle.loadSpecValueAdditionalWeight, Vehicle.getSpecValueAdditionalWeight, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("combinations", nil, Vehicle.loadSpecValueCombinations, Vehicle.getSpecValueCombinations, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("slots", "shopListAttributeIconSlots", nil, Vehicle.getSpecValueSlots, StoreSpecies.VEHICLE)
    Vehicle.xmlSchema = XMLSchema.new("vehicle")
    g_storeManager:addSpeciesXMLSchema(StoreSpecies.VEHICLE, Vehicle.xmlSchema)
    g_vehicleTypeManager:setXMLSchema(Vehicle.xmlSchema)
    Vehicle.xmlSchemaSounds = XMLSchema.new("vehicle_sounds")
    Vehicle.xmlSchemaSounds:setRootNodeName("sounds")
    Vehicle.xmlSchema:addSubSchema(Vehicle.xmlSchemaSounds, "sounds")
    Vehicle.xmlSchemaSavegame = XMLSchema.new("savegame_vehicles")
    Vehicle.registers()
end
function Vehicle.postInit()
    local schema = Vehicle.xmlSchema
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    local configurations = g_vehicleConfigurationManager:getConfigurations()
    for _, configuration in pairs(configurations) do
        local configuration
        g_asyncTaskManager:addSubtask(function()
            -- upvalues: (copy) configuration, (copy) schema, (copy) schemaSavegame
            if configuration.itemClass.registerXMLPaths ~= nil then
                configuration.itemClass.registerXMLPaths(schema, configuration.configurationsKey, configuration.configurationKey .. "(?)")
            end
            schema:register(XMLValueType.FLOAT, configuration.configurationKey .. "(?)#workingWidth", "Work width to display in shop while config is active")
            schema:register(XMLValueType.L10N_STRING, configuration.configurationKey .. "(?)#typeDesc", "Type description text to display in shop while config is active")
            if configuration.itemClass.registerSavegameXMLPaths ~= nil then
                configuration.itemClass.registerSavegameXMLPaths(schemaSavegame, "vehicles.vehicle(?).configuration(?)")
                configuration.itemClass.registerSavegameXMLPaths(schemaSavegame, "vehicles.vehicle(?).boughtConfiguration(?)")
            end
        end)
    end
end
function Vehicle.registers()
    local schema = Vehicle.xmlSchema
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schema:register(XMLValueType.STRING, "vehicle#type", "Vehicle type")
    schema:registerAutoCompletionDataSource("vehicle#type", "$dataS/vehicleTypes.xml", "vehicleTypes.type#name")
    schema:register(XMLValueType.STRING, "vehicle.annotation", "Annotation", nil, true)
    StoreManager.registerStoreDataXMLPaths(schema, "vehicle")
    schema:register(XMLValueType.FLOAT, "vehicle.storeData.specs.workingWidth", "Working width to display in shop")
    schema:register(XMLValueType.FLOAT, "vehicle.storeData.specs.workingWidth#minWidth", "Min. working width to display in shop")
    schema:register(XMLValueType.STRING, "vehicle.storeData.specs.combination(?)#xmlFilename", "Combination to display in shop")
    schema:registerAutoCompletionDataSource("vehicle.storeData.specs.combination(?)#xmlFilename", "dataS/storeItems.xml", "storeItems.storeItem#xmlFilename")
    schema:register(XMLValueType.STRING, "vehicle.storeData.specs.combination(?)#filterCategory", "Filter in this category")
    schema:registerAutoCompletionDataSource("vehicle.storeData.specs.combination(?)#filterCategory", "$dataS/storeCategories.xml", "categories.category#name")
    schema:register(XMLValueType.STRING, "vehicle.storeData.specs.combination(?)#filterSpec", "Filter for this spec type")
    schema:register(XMLValueType.FLOAT, "vehicle.storeData.specs.combination(?)#filterSpecMin", "Filter spec type in this range (min.)")
    schema:register(XMLValueType.FLOAT, "vehicle.storeData.specs.combination(?)#filterSpecMax", "Filter spec type in this range (max.)")
    schema:register(XMLValueType.BOOL, "vehicle.storeData.specs.weight#ignore", "Hide vehicle weight in shop", false)
    schema:register(XMLValueType.FLOAT, "vehicle.storeData.specs.weight#minValue", "Min. weight to display in shop")
    schema:register(XMLValueType.FLOAT, "vehicle.storeData.specs.weight#maxValue", "Max. weight to display in shop")
    schema:register(XMLValueType.STRING, "vehicle.storeData.specs.weight.config(?)#name", "Name of configuration")
    schema:register(XMLValueType.INT, "vehicle.storeData.specs.weight.config(?)#index", "Index of selected configuration")
    schema:register(XMLValueType.FLOAT, "vehicle.storeData.specs.weight.config(?)#value", "Weight value which can be reached with this configuration")
    schema:register(XMLValueType.STRING, "vehicle.base.filename", "Path to i3d filename", nil)
    schema:register(XMLValueType.L10N_STRING, "vehicle.base.typeDesc", "Type description", nil)
    schema:register(XMLValueType.BOOL, "vehicle.base.synchronizePosition", "Vehicle position synchronized", true)
    schema:register(XMLValueType.BOOL, "vehicle.base.supportsPickUp", "Vehicle can be picked up by hand", false)
    schema:register(XMLValueType.BOOL, "vehicle.base.canBeReset", "Vehicle can be reset to shop", true)
    schema:register(XMLValueType.BOOL, "vehicle.base.showInVehicleMenu", "Vehicle shows in vehicle menu", true)
    schema:register(XMLValueType.BOOL, "vehicle.base.supportsRadio", "Vehicle supported radio", true)
    schema:register(XMLValueType.BOOL, "vehicle.base.input#allowed", "Vehicle allows key input", true)
    schema:register(XMLValueType.BOOL, "vehicle.base.selection#allowed", "Vehicle selection is allowed", true)
    schema:register(XMLValueType.FLOAT, "vehicle.base.tailwaterDepth#warning", "Tailwater depth warning is shown from this water depth", "25% of vehicle height")
    schema:register(XMLValueType.FLOAT, "vehicle.base.tailwaterDepth#threshold", "Vehicle is broken after this water depth", "75% of vehicle height")
    schema:register(XMLValueType.STRING, "vehicle.base.mapHotspot#type", "Map hotspot type", nil, nil, table.toList(VehicleHotspot.TYPE))
    schema:register(XMLValueType.BOOL, "vehicle.base.mapHotspot#available", "Map hotspot is available", true)
    schema:register(XMLValueType.FLOAT, "vehicle.base.speedLimit#value", "Speed limit")
    schema:register(XMLValueType.FLOAT, "vehicle.base.size#width", "Occupied width of the vehicle when loaded", nil, true)
    schema:register(XMLValueType.FLOAT, "vehicle.base.size#length", "Occupied length of the vehicle when loaded", nil, true)
    schema:register(XMLValueType.FLOAT, "vehicle.base.size#height", "Occupied height of the vehicle when loaded")
    schema:register(XMLValueType.FLOAT, "vehicle.base.size#widthOffset", "Width offset")
    schema:register(XMLValueType.FLOAT, "vehicle.base.size#lengthOffset", "Width offset")
    schema:register(XMLValueType.FLOAT, "vehicle.base.size#heightOffset", "Height offset")
    schema:register(XMLValueType.ANGLE, "vehicle.base.size#yRotation", "Y Rotation offset in i3d (Needs to be set to the vehicle\'s rotation in the i3d file and is e.g. used to check ai working direction)", 0)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.base.steeringAxle#node", "Steering axle node used to calculate the steering angle of attachments")
    schema:register(XMLValueType.STRING, "vehicle.base.sounds#filename", "Path to external sound files")
    schema:register(XMLValueType.FLOAT, "vehicle.base.sounds#volumeFactor", "This factor will be applied to all sounds of this vehicle")
    I3DUtil.registerI3dMappingXMLPaths(schema, "vehicle")
    Vehicle.registerComponentXMLPaths(schema, "vehicle.base.components")
    Vehicle.registerComponentXMLPaths(schema, "vehicle.base.componentConfigurations.componentConfiguration(?)")
    ObjectChangeUtil.registerObjectChangesXMLPaths(schema, "vehicle.base")
    schema:register(XMLValueType.VECTOR_2, "vehicle.base.schemaOverlay#attacherJointPosition", "Position of attacher joint")
    schema:register(XMLValueType.VECTOR_2, "vehicle.base.schemaOverlay#basePosition", "Position of vehicle")
    schema:register(XMLValueType.STRING, "vehicle.base.schemaOverlay#name", "Name of schema overlay")
    schema:registerAutoCompletionDataSource("vehicle.base.schemaOverlay#name", "$dataS/vehicleSchemaOverlays.xml", "vehicleSchemaOverlays.overlay#name")
    schema:register(XMLValueType.FLOAT, "vehicle.base.schemaOverlay#invisibleBorderRight", "Size of invisible border on the right")
    schema:register(XMLValueType.FLOAT, "vehicle.base.schemaOverlay#invisibleBorderLeft", "Size of invisible border on the left")
    schema:register(XMLValueType.STRING, "vehicle.vehicleTypeConfigurations.vehicleTypeConfiguration(?)#vehicleType", "Vehicle type for configuration")
    schema:register(XMLValueType.BOOL, "vehicle.designConfigurations#preLoad", "Defines if the design configurations are applied before the execution of load or after. Can help if the configurations manipulate the wheel positions for example.", false)
    StoreItemUtil.registerConfigurationSetXMLPaths(schema, "vehicle")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles#loadAnyFarmInSingleplayer", "Load any farm in singleplayer", false)
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?)#filename", "XML filename")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?)#modName", "Vehicle mod name")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)#isBroken", "If the vehicle is broken", false)
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)#defaultFarmProperty", "Property of default farm", false)
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?)#id", "Vehicle id")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?)#tourId", "Tour id")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?)#farmId", "Farm id")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?)#uniqueId", "Vehicle\'s unique id")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?)#age", "Age in number of months")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?)#price", "Price")
    VehiclePropertyState.registerXMLPath(schemaSavegame, "vehicles.vehicle(?)#propertyState", "Property state", nil, false)
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?)#operatingTime", "Operating time")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?)#selectedObjectIndex", "Selected object index")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?)#subSelectedObjectIndex", "Sub selected object index")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).component(?)#index", "Component index")
    schemaSavegame:register(XMLValueType.VECTOR_TRANS, "vehicles.vehicle(?).component(?)#position", "Component position")
    schemaSavegame:register(XMLValueType.VECTOR_ROT, "vehicles.vehicle(?).component(?)#rotation", "Component rotation")
    VehicleActionController.registerXMLPaths(schemaSavegame, "vehicles.vehicle(?).actionController")
    schemaSavegame:register(XMLValueType.INT, "vehicles.attachments(?)#rootVehicleId", "Id of root vehicle")
end
function Vehicle.registerComponentXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#numComponents", "Number of components loaded from i3d", "number of components the i3d contains")
    schema:register(XMLValueType.FLOAT, basePath .. "#maxMass", "Max. overall mass the vehicle can have", "unlimited")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#directionReferenceNode", "Direction node to calculate the current driving direction and speed")
    schema:register(XMLValueType.INT, basePath .. ".component(?)#index", "Index of the component node in the i3d hierarchy")
    schema:register(XMLValueType.FLOAT, basePath .. ".component(?)#mass", "Mass of component [kg]", "Mass of component in i3d")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".component(?)#centerOfMass", "Center of mass in local space (x y z)", "Center of mass in i3d")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".component(?)#inertiaScale", "Scales the inertia, defining how the mass is distributed around the object (x y z, x = inertia around the local x axis). Inertia quadratically depends on the object radius. E.g. using an inertiaScale of 4 is equal to having a 2 times larger object along the given axis", "1 1 1")
    schema:register(XMLValueType.INT, basePath .. ".component(?)#solverIterationCount", "Solver iterations count")
    schema:register(XMLValueType.BOOL, basePath .. ".component(?)#motorized", "Is motorized component", "set by motorized specialization")
    schema:register(XMLValueType.BOOL, basePath .. ".component(?)#collideWithAttachables", "Collides with attachables", false)
    schema:register(XMLValueType.INT, basePath .. ".joint(?)#component1", "First component of the joint")
    schema:register(XMLValueType.INT, basePath .. ".joint(?)#component2", "Second component of the joint")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".joint(?)#node", "Joint node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".joint(?)#nodeActor1", "Actor node of second component", "Joint node")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#rotLimit", "Rotation limit", "0 0 0")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#transLimit", "Translation limit", "0 0 0")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#rotMinLimit", "Min rotation limit", "inversed rotation limit")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#transMinLimit", "Min translation limit", "inversed translation limit")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#rotLimitSpring", "Rotation spring limit", "0 0 0")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#rotLimitDamping", "Rotation damping limit", "1 1 1")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#rotLimitForceLimit", "Rotation limit force limit (-1 = infinite)", "-1 -1 -1")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#transLimitForceLimit", "Translation limit force limit (-1 = infinite)", "-1 -1 -1")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#transLimitSpring", "Translation spring limit", "0 0 0")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#transLimitDamping", "Translation damping limit", "1 1 1")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".joint(?)#zRotationNode", "Position of joints z rotation")
    schema:register(XMLValueType.BOOL, basePath .. ".joint(?)#breakable", "Joint is breakable", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".joint(?)#breakForce", "Joint force until it breaks", 10)
    schema:register(XMLValueType.FLOAT, basePath .. ".joint(?)#breakTorque", "Joint torque until it breaks", 10)
    schema:register(XMLValueType.BOOL, basePath .. ".joint(?)#enableCollision", "Enable collision between both components", false)
    schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#maxRotDriveForce", "Max rotational drive force", "0 0 0")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#rotDriveVelocity", "Rotational drive velocity")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#rotDriveRotation", "Rotational drive rotation")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#rotDriveSpring", "Rotational drive spring", "0 0 0")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#rotDriveDamping", "Rotational drive damping", "0 0 0")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#transDriveVelocity", "Translational drive velocity")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#transDrivePosition", "Translational drive position")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#transDriveSpring", "Translational drive spring", "0 0 0")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#transDriveDamping", "Translational drive damping", "1 1 1")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".joint(?)#maxTransDriveForce", "Max translational drive force", "0 0 0")
    schema:register(XMLValueType.BOOL, basePath .. ".joint(?)#initComponentPosition", "Defines if the component is translated and rotated during loading based on joint movement", true)
    schema:register(XMLValueType.BOOL, basePath .. ".collisionPair(?)#enabled", "Collision between components enabled")
    schema:register(XMLValueType.INT, basePath .. ".collisionPair(?)#component1", "Index of first component")
    schema:register(XMLValueType.INT, basePath .. ".collisionPair(?)#component2", "Index of second component")
end
function Vehicle.new(isServer, isClient, customMt)
    -- upvalues: (copy) Vehicle_mt
    local self = Object.new(isServer, isClient, customMt or Vehicle_mt)
    self.finishedLoading = false
    self.isDeleted = false
    self.updateLoopIndex = -1
    self.sharedLoadRequestId = nil
    self.loadingState = VehicleLoadingState.OK
    self.loadingStep = SpecializationLoadStep.CREATED
    self.loadingTasks = {}
    self.readyForFinishLoading = false
    self.uniqueId = nil
    self.actionController = VehicleActionController.new(self)
    return self
end
function Vehicle:setFilename(filename)
    self.configFileName = filename
    self.configFileNameClean = Utils.getFilenameInfo(filename, true)
    self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(filename)
end
function Vehicle:setConfigurations(configurations, boughtConfigurations, configurationData)
    self.configurations = configurations
    self.boughtConfigurations = boughtConfigurations
    self.configurationData = configurationData or self.configurationData
    if self.configurationData == nil then
        self.configurationData = {}
    end
    self.sortedConfigurationNames = {}
    for configName, _ in pairs(self.configurations) do
        table.insert(self.sortedConfigurationNames, configName)
    end
    table.sort(self.sortedConfigurationNames, function(a, b)
        return a < b
    end)
end
function Vehicle:setType(typeDef)
    local configItem = assertWithCallstack
    local configType = self.configFileName ~= nil
    configItem(configType, "Setting vehicle type without setting a filename previously. Call \'setFilename\' first!")
    if self.configurations ~= nil then
        local configItem = ConfigurationUtil.getConfigItemByConfigId(self.configFileName, "vehicleType", self.configurations.vehicleType)
        if configItem ~= nil and configItem.vehicleType ~= nil then
            local configType = g_vehicleTypeManager:getTypeByName(configItem.vehicleType, self.customEnvironment)
            if configType == nil then
                Logging.warning("Unknown vehicle type \'%s\' in configuration for \'%s\'", configItem.vehicleType, self.configFileName)
            else
                typeDef = configType
            end
        end
    end
    SpecializationUtil.initSpecializationsIntoTypeClass(g_vehicleTypeManager, typeDef, self)
end
function Vehicle:setLoadCallback(loadCallbackFunction, loadCallbackFunctionTarget, loadCallbackFunctionArguments)
    self.loadCallbackFunction = loadCallbackFunction
    self.loadCallbackFunctionTarget = loadCallbackFunctionTarget
    self.loadCallbackFunctionArguments = loadCallbackFunctionArguments
end
function Vehicle:loadCallback()
    if self.loadCallbackFunction ~= nil then
        self.loadCallbackFunction(self.loadCallbackFunctionTarget, self, self.loadingState, self.loadCallbackFunctionArguments)
        self.loadCallbackFunction = nil
        self.loadCallbackFunctionTarget = nil
        self.loadCallbackFunctionArguments = nil
    end
end
function Vehicle:load(vehicleLoadingData)
    self.vehicleLoadingData = vehicleLoadingData
    self:setLoadingStep(SpecializationLoadStep.PRE_LOAD)
    self.isVehicleSaved = vehicleLoadingData.isSaved
    if self.type == nil then
        Logging.xmlWarning(self.xmlFile, "Unable to find vehicleType")
        self:setLoadingState(VehicleLoadingState.ERROR)
        return self.loadingState
    end
    self.actionEvents = {}
    self.xmlFile = XMLFile.load("vehicleXML", self.configFileName, Vehicle.xmlSchema)
    self.savegame = vehicleLoadingData.savegameData
    self.isAddedToPhysics = false
    local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
    if storeItem ~= nil then
        self.brand = g_brandManager:getBrandByIndex(storeItem.brandIndex)
        self.lifetime = storeItem.lifetime
    end
    self.externalSoundsFilename = self.xmlFile:getValue("vehicle.base.sounds#filename")
    if self.externalSoundsFilename ~= nil then
        self.externalSoundsFilename = Utils.getFilename(self.externalSoundsFilename, self.baseDirectory)
        self.externalSoundsFile = XMLFile.load("TempExternalSounds", self.externalSoundsFilename, Vehicle.xmlSchemaSounds)
    end
    self.soundVolumeFactor = self.xmlFile:getValue("vehicle.base.sounds#volumeFactor")
    SpecializationUtil.copyTypeFunctionsInto(self.type, self)
    local item = g_storeManager:getItemByXMLFilename(self.configFileName)
    if item ~= nil and item.configurations ~= nil then
        if item.configurationSets ~= nil and (#item.configurationSets > 0 and not ConfigurationUtil.getConfigurationsMatchConfigSets(self.configurations, item.configurationSets)) then
            local closestSet, closestSetMatches = ConfigurationUtil.getClosestConfigurationSet(self.configurations, item.configurationSets)
            if closestSet ~= nil then
                for configName, index in pairs(closestSet.configurations) do
                    self.configurations[configName] = index
                end
                Logging.xmlInfo(self.xmlFile, "Savegame configurations do not match the configuration sets! Apply closest configuration set \'%s\' with %d matching configurations.", closestSet.name, closestSetMatches)
            end
        end
        for configName, _ in pairs(item.configurations) do
            local configName = StoreItemUtil.getDefaultConfigId(item, configName)
            if self.configurations[configName] == nil then
                ConfigurationUtil.setConfiguration(self, configName, configName)
            end
            ConfigurationUtil.addBoughtConfiguration(g_vehicleConfigurationManager, self, configName, configName)
        end
        for configName, _ in pairs(self.configurations) do
            if item.configurations[configName] == nil then
                Logging.xmlWarning(self.xmlFile, "Configurations are not present anymore. Ignoring this configuration (%s)!", configName)
                self.configurations[configName] = nil
                self.boughtConfigurations[configName] = nil
            else
                local configName = StoreItemUtil.getDefaultConfigId(item, configName)
                if #item.configurations[configName] < _ then
                    Logging.xmlWarning(self.xmlFile, "Configuration with index \'%d\' is not present anymore. Using default configuration instead! (%s)", _, configName)
                    if self.boughtConfigurations[configName] ~= nil then
                        self.boughtConfigurations[configName][_] = nil
                        if next(self.boughtConfigurations[configName]) == nil then
                            self.boughtConfigurations[configName] = nil
                        end
                    end
                    ConfigurationUtil.setConfiguration(self, configName, configName)
                else
                    ConfigurationUtil.addBoughtConfiguration(g_vehicleConfigurationManager, self, configName, _)
                end
            end
        end
    end
    SpecializationUtil.createSpecializationEnvironments(self, function(specName, specEntryName)
        -- upvalues: (copy) self
        Logging.xmlError(self.xmlFile, "The vehicle specialization \'%s\' could not be added because variable \'%s\' already exists!", specName, specEntryName)
        self:setLoadingState(VehicleLoadingState.ERROR)
    end)
    SpecializationUtil.raiseEvent(self, "onPreLoad", self.savegame)
    if self.loadingState ~= VehicleLoadingState.OK then
        Logging.xmlError(self.xmlFile, "Vehicle pre-loading failed!")
        self.xmlFile:delete()
        return false
    end
    ConfigurationUtil.raiseConfigurationItemEvent(self, "onPreLoad")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.filename", "vehicle.base.filename")
    self.i3dFilename = Utils.getFilename(self.xmlFile:getValue("vehicle.base.filename"), self.baseDirectory)
    if self.i3dFilename ~= nil then
        local closestSet, closestSetMatches = Utils.getPathIsValid(self.i3dFilename)
        if not closestSet then
            Logging.xmlWarning(self.xmlFile, "Filename contains %s, which are not allowed! (%s)", closestSetMatches, "vehicle.base.filename")
        end
    end
    self:setLoadingStep(SpecializationLoadStep.AWAIT_I3D)
    self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, true, false, self.i3dFileLoaded, self)
    return nil
end
function Vehicle:i3dFileLoaded(i3dNode, _, _, _)
    if i3dNode == 0 then
        self:setLoadingState(VehicleLoadingState.ERROR)
        Logging.xmlError(self.xmlFile, "Vehicle i3d loading failed!")
        self:loadCallback()
    else
        self.i3dNode = i3dNode
        setVisibility(i3dNode, false)
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            self:loadFinished()
        end)
    end
end
function Vehicle:loadFinished()
    local realNumComponents = nil
    local componentsKey = nil
    local numComponents = nil
    self:addAsyncTask(function()
        -- upvalues: (copy) self
        self:setLoadingState(VehicleLoadingState.OK)
        self:setLoadingStep(SpecializationLoadStep.LOAD)
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.forcedMapHotspotType", "vehicle.base.mapHotspot#type")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.base.forcedMapHotspotType", "vehicle.base.mapHotspot#type")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.speedLimit#value", "vehicle.base.speedLimit#value")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.steeringAxleNode#index", "vehicle.base.steeringAxle#node")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.size#width", "vehicle.base.size#width")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.size#length", "vehicle.base.size#length")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.size#widthOffset", "vehicle.base.size#widthOffset")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.size#lengthOffset", "vehicle.base.size#lengthOffset")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.typeDesc", "vehicle.base.typeDesc")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.components", "vehicle.base.components")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.components.component", "vehicle.base.components.component")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.base.components.component1", "vehicle.base.components.component")
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.base.mapHotspot#hasDirection")
    end, "Vehicle - Deprecated Check")
    self:addAsyncTask(function()
        -- upvalues: (copy) self, (ref) realNumComponents, (ref) componentsKey, (ref) numComponents
        local savegame = self.savegame
        if savegame ~= nil then
            self.tourId = nil
            local tourId = savegame.xmlFile:getValue(savegame.key .. "#tourId")
            if tourId ~= nil then
                self.tourId = tourId
                g_guidedTourManager:addVehicle(self, self.tourId)
            end
        end
        self.age = 0
        self.propertyState = self.vehicleLoadingData.propertyState
        self:setOwnerFarmId(self.vehicleLoadingData.ownerFarmId, true)
        if savegame ~= nil then
            local tourId = savegame.xmlFile:getValue(savegame.key .. "#uniqueId", nil)
            if tourId ~= nil then
                self:setUniqueId(tourId)
            end
            if not savegame.ignoreFarmId then
                local farmId = savegame.xmlFile:getValue(savegame.key .. "#farmId", AccessHandler.EVERYONE)
                if g_farmManager.mergedFarms ~= nil and g_farmManager.mergedFarms[farmId] ~= nil then
                end
                self:setOwnerFarmId(farmId, true)
            end
        end
        self.price = self.vehicleLoadingData.price
        if self.price == 0 or self.price == nil then
            local tourId = g_storeManager:getItemByXMLFilename(self.configFileName)
            self.price = StoreItemUtil.getDefaultPrice(tourId, self.configurations)
        end
        self.typeDesc = self.xmlFile:getValue("vehicle.base.typeDesc", "TypeDescription", self.customEnvironment, true)
        for name, configDesc in pairs(g_vehicleConfigurationManager:getConfigurations()) do
            local configurationKey = string.format("%s(%d)", configDesc.configurationKey, (self.configurations[name] or 1) - 1)
            self.typeDesc = self.xmlFile:getValue(configurationKey .. "#typeDesc", nil, self.customEnvironment, false) or self.typeDesc
        end
        self.synchronizePosition = self.xmlFile:getValue("vehicle.base.synchronizePosition", true)
        self.highPrecisionPositionSynchronization = false
        self.supportsPickUp = self.xmlFile:getValue("vehicle.base.supportsPickUp", false)
        self.canBeReset = self.xmlFile:getValue("vehicle.base.canBeReset", true)
        self.showInVehicleOverview = self.xmlFile:getValue("vehicle.base.showInVehicleMenu", true)
        self.rootNode = getChildAt(self.i3dNode, 0)
        self.serverMass = 0
        self.precalculatedMass = 0
        self.isMassDirty = false
        self.terrainHeightResetCounter = 0
        self.currentUpdateDistance = 0
        self.lastDistanceToCamera = 0
        self.lodDistanceCoeff = getLODDistanceCoeff()
        self.viewDistanceCoeff = getViewDistanceCoeff()
        self.components = {}
        self.vehicleNodes = {}
        realNumComponents = getNumOfChildren(self.i3dNode)
        local tourId = { 0, 0, 0 }
        local farmId = self.configurations.component or 1
        componentsKey = string.format("vehicle.base.componentConfigurations.componentConfiguration(%d)", farmId - 1)
        if not self.xmlFile:hasProperty(componentsKey) then
            componentsKey = "vehicle.base.components"
        end
        numComponents = self.xmlFile:getValue(componentsKey .. "#numComponents", realNumComponents)
        self.maxComponentMass = self.xmlFile:getValue(componentsKey .. "#maxMass", math.huge) / 1000
        self.rootLevelNodes = {}
        local configDesc = 1
        local name = 1
        for configDesc = configDesc, realNumComponents, name do
            local configurationKey = {
                ["node"] = getChildAt(self.i3dNode, configDesc - 1),
                ["isInactive"] = true
            }
            if not getVisibility(configurationKey.node) then
                Logging.xmlDevWarning(self.xmlFile, "Found hidden component \'%s\' in i3d file. Components are not allowed to be hidden!", getName(configurationKey.node))
            end
            setVisibility(configurationKey.node, false)
            table.insert(self.rootLevelNodes, configurationKey)
        end
        for configurationKey, typeDesc in self.xmlFile:iterator(componentsKey .. ".component") do
            if numComponents < configurationKey then
                Logging.xmlWarning(self.xmlFile, "Invalid components count. I3D file has \'%d\' components, but tried to load component no. \'%d\'!", numComponents, configurationKey + 1)
                break
            end
            local i3dIndex = self.xmlFile:getValue(typeDesc .. "#index", configurationKey) - 1
            local component = {
                ["node"] = getChildAt(self.i3dNode, i3dIndex)
            }
            if self:loadComponentFromXML(component, self.xmlFile, typeDesc, tourId, configurationKey) then
                local x, y, z = getWorldTranslation(component.node)
                local qx, qy, qz, qw = getWorldQuaternion(component.node)
                component.networkInterpolators = {}
                component.networkInterpolators.position = InterpolatorPosition.new(x, y, z)
                component.networkInterpolators.quaternion = InterpolatorQuaternion.new(qx, qy, qz, qw)
                table.insert(self.components, component)
            end
        end
        for configurationKey, typeDesc in ipairs(self.components) do
            link(getRootNode(), typeDesc.node)
        end
    end, "Vehicle - Components Loading")
    self:addAsyncTask(function()
        -- upvalues: (copy) self, (ref) numComponents
        for _, rootLevelNode in ipairs(self.rootLevelNodes) do
            for _, component in ipairs(self.components) do
                if component.node == rootLevelNode.node then
                    rootLevelNode.isInactive = false
                end
            end
            if rootLevelNode.isInactive then
                local x, y, z = getWorldTranslation(rootLevelNode.node)
                local _, component, rz = getWorldRotation(rootLevelNode.node)
                link(self.components[1].node, rootLevelNode.node)
                setWorldTranslation(rootLevelNode.node, x, y, z)
                setWorldRotation(rootLevelNode.node, _, component, rz)
                setRigidBodyType(rootLevelNode.node, RigidBodyType.NONE)
                I3DUtil.iterateRecursively(rootLevelNode.node, function(node)
                    if getIsCompoundChild(node) then
                        setIsCompoundChild(node, false)
                    end
                end)
            end
        end
        delete(self.i3dNode)
        self.i3dNode = nil
        self.numComponents = #self.components
        if numComponents ~= self.numComponents then
            Logging.xmlWarning(self.xmlFile, "I3D file offers \'%d\' objects, but \'%d\' components have been loaded!", numComponents, self.numComponents)
        end
        if Vehicle.DEBUG_RANDOM_FAIL_LOADING and math.random() > 0.75 then
            self.numComponents = 0
        end
        if self.numComponents == 0 then
            Logging.xmlWarning(self.xmlFile, "No components defined for vehicle!")
            self:setLoadingState(VehicleLoadingState.ERROR)
            self:loadCallback()
        end
    end, "Vehicle - I3D Delete")
    self:addAsyncTask(function()
        -- upvalues: (copy) self, (ref) realNumComponents
        self.defaultMass = 0
        local j = 1
        for j = j, #self.components do
            self.defaultMass = self.defaultMass + self.components[j].defaultMass
        end
        self.i3dMappings = {}
        I3DUtil.loadI3DMapping(self.xmlFile, "vehicle", self.rootLevelNodes, self.i3dMappings, realNumComponents)
    end, "Vehicle - I3D mapping")
    self:addAsyncTask(function()
        -- upvalues: (copy) self
        self.steeringAxleNode = self.xmlFile:getValue("vehicle.base.steeringAxle#node", nil, self.components, self.i3dMappings)
        if self.steeringAxleNode == nil then
            self.steeringAxleNode = self.components[1].node
        end
        self:loadSchemaOverlay(self.xmlFile)
    end, "Vehicle - Schema Overlays")
    self:addAsyncTask(function()
        -- upvalues: (copy) self, (ref) componentsKey
        self.componentJoints = {}
        for componentJointIndex, componentJointKey in self.xmlFile:iterator(componentsKey .. ".joint") do
            local index1 = self.xmlFile:getValue(componentJointKey .. "#component1")
            local index2 = self.xmlFile:getValue(componentJointKey .. "#component2")
            XMLUtil.checkDeprecatedXMLElements(self.xmlFile, componentJointKey .. "#index", componentJointKey .. "#node")
            if index1 == nil or index2 == nil then
                Logging.xmlWarning(self.xmlFile, "Missing component index in component joint \'%s\'", componentJointKey)
                return
            end
            local jointNode = self.xmlFile:getValue(componentJointKey .. "#node", nil, self.components, self.i3dMappings)
            if jointNode ~= nil and jointNode ~= 0 then
                local jointDesc = {}
                if self:loadComponentJointFromXML(jointDesc, self.xmlFile, componentJointKey, componentJointIndex - 1, jointNode, index1, index2) then
                    table.insert(self.componentJoints, jointDesc)
                    jointDesc.index = #self.componentJoints
                end
            end
        end
    end, "Vehicle - Component Joints")
    self:addAsyncTask(function()
        -- upvalues: (copy) self, (ref) componentsKey
        self.collisionPairs = {}
        for collisionPairIndex, collisionPairKey in self.xmlFile:iterator(componentsKey .. ".collisionPair") do
            local enabled = self.xmlFile:getValue(collisionPairKey .. "#enabled")
            local index1 = self.xmlFile:getValue(collisionPairKey .. "#component1")
            local index2 = self.xmlFile:getValue(collisionPairKey .. "#component2")
            if index1 ~= nil and (index2 ~= nil and enabled ~= nil) then
                local component1 = self.components[index1]
                local component2 = self.components[index2]
                if component1 == nil or component2 == nil then
                    Logging.xmlWarning(self.xmlFile, "Failed to load collision pair \'%s\'. Unknown component indices. Indices start with 1.", collisionPairKey)
                elseif not enabled then
                    table.insert(self.collisionPairs, {
                        ["component1"] = component1,
                        ["component2"] = component2,
                        ["enabled"] = enabled
                    })
                end
            end
        end
    end, "Vehicle - Collision Pairs")
    self:addAsyncTask(function()
        -- upvalues: (copy) self
        self.supportsRadio = self.xmlFile:getValue("vehicle.base.supportsRadio", true)
        self.allowsInput = self.xmlFile:getValue("vehicle.base.input#allowed", true)
        self.size = StoreItemUtil.getSizeValuesFromXML(self.configFileName, self.xmlFile, "vehicle", 0, self.configurations)
    end, "Vehicle - Size")
    self:addAsyncTask(function()
        -- upvalues: (copy) self, (ref) componentsKey
        self.yRotationOffset = self.xmlFile:getValue("vehicle.base.size#yRotation", 0)
        self.showTailwaterDepthWarning = false
        self.thresholdTailwaterDepthWarning = self.xmlFile:getValue("vehicle.base.tailwaterDepth#warning", self.size.height * 0.25)
        self.thresholdTailwaterDepth = self.xmlFile:getValue("vehicle.base.tailwaterDepth#threshold", self.size.height * 0.75)
        self.networkTimeInterpolator = InterpolationTime.new(1.2)
        self.movingDirection = 0
        self.rotatedTime = 0
        self.isBroken = false
        self.forceIsActive = false
        self.finishedFirstUpdate = false
        self.lastPosition = nil
        self.lastSpeed = 0
        self.lastSpeedReal = 0
        self.lastSpeedSmoothed = 0
        self.lastSignedSpeed = 0
        self.lastSignedSpeedReal = 0
        self.lastMovedDistance = 0
        self.lastSpeedAcceleration = 0
        self.lastMoveTime = -10000
        self.operatingTime = 0
        self.allowSelection = self.xmlFile:getValue("vehicle.base.selection#allowed", true)
        self.isInWater = false
        self.isInShallowWater = false
        self.isInMediumWater = false
        self.waterY = -200
        self.tailwaterDepth = -200
        self.waterCheckPosition = { 0, 0, 0 }
        self.currentSelection = {
            ["object"] = nil,
            ["index"] = 0,
            ["subIndex"] = 1
        }
        self.selectionObject = {
            ["index"] = 0,
            ["isSelected"] = false,
            ["vehicle"] = self,
            ["subSelections"] = {}
        }
        self.childVehicles = { self }
        self.childVehicleHash = ""
        self.rootVehicle = self
        self.registeredActionEvents = {}
        self.actionEventUpdateRequested = false
        self.vehicleDirtyFlag = self:getNextDirtyFlag()
        if g_currentMission ~= nil and g_currentMission.environment ~= nil then
            g_messageCenter:subscribe(MessageType.DAY_CHANGED, self.dayChanged, self)
            g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.periodChanged, self)
        end
        self.mapHotspotAvailable = self.xmlFile:getValue("vehicle.base.mapHotspot#available", true)
        if self.mapHotspotAvailable then
            local hotspotType = self.xmlFile:getValue("vehicle.base.mapHotspot#type", "OTHER")
            self.mapHotspotType = VehicleHotspot.getTypeByName(hotspotType) or VehicleHotspot.TYPE.OTHER
        end
        self.directionReferenceNode = self.xmlFile:getValue(componentsKey .. "#directionReferenceNode", nil, self.components, self.i3dMappings)
        local hotspotType = math.huge
        for _, spec in ipairs(self.specializations) do
            if spec.getDefaultSpeedLimit ~= nil then
                local limit = spec.getDefaultSpeedLimit(self)
                hotspotType = math.min(limit, hotspotType)
            end
        end
        self.checkSpeedLimit = hotspotType == math.huge
        self.speedLimit = self.xmlFile:getValue("vehicle.base.speedLimit#value", hotspotType)
    end, "Vehicle - Various Data")
    self:addAsyncTask(function()
        -- upvalues: (copy) self
        local objectChanges = {}
        ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, "vehicle.base.objectChanges", objectChanges, self.components, self)
        ObjectChangeUtil.setObjectChanges(objectChanges, true)
    end, "Vehicle - Object Change Loading")
    self:addAsyncTask(function()
        -- upvalues: (copy) self
        ConfigurationUtil.raiseConfigurationItemEvent(self, "onLoad")
    end, "Vehicle - Configurations OnLoad")
    self:addAsyncTask(function()
        -- upvalues: (copy) self
        SpecializationUtil.raiseAsyncEvent(self, "onLoad", self.savegame)
    end)
    self:addAsyncTask(function()
        -- upvalues: (copy) self
        if self.loadingState ~= VehicleLoadingState.OK then
            Logging.xmlError(self.xmlFile, "Vehicle loading failed!")
            self:loadCallback()
        end
    end, nil, true)
    self:addAsyncTask(function()
        -- upvalues: (copy) self
        if Platform.gameplay.automaticVehicleControl and self.actionController ~= nil then
            self.actionController:load(self.savegame)
        end
        SpecializationUtil.raiseEvent(self, "onRootVehicleChanged", self)
        if self.isServer then
            for _, jointDesc in pairs(self.componentJoints) do
                if jointDesc.initComponentPosition then
                    local component2 = self.components[jointDesc.componentIndices[2]].node
                    local jointNode = jointDesc.jointNode
                    if self:getParentComponent(jointNode) == component2 then
                        jointNode = jointDesc.jointNodeActor1
                    end
                    if self:getParentComponent(jointNode) ~= component2 then
                        setTranslation(component2, localToLocal(component2, jointNode, 0, 0, 0))
                        setRotation(component2, localRotationToLocal(component2, jointNode, 0, 0, 0))
                        link(jointNode, component2)
                    end
                end
            end
        end
    end)
    self:addAsyncTask(function()
        -- upvalues: (copy) self
        ConfigurationUtil.raiseConfigurationItemEvent(self, "onPrePostLoad")
        self:setLoadingStep(SpecializationLoadStep.POST_LOAD)
    end)
    self:addAsyncTask(function()
        -- upvalues: (copy) self
        SpecializationUtil.raiseAsyncEvent(self, "onPostLoad", self.savegame)
    end)
    self:addAsyncTask(function()
        -- upvalues: (copy) self
        ConfigurationUtil.raiseConfigurationItemEvent(self, "onPostLoad")
    end)
    self:addAsyncTask(function()
        -- upvalues: (copy) self
        if self.loadingState ~= VehicleLoadingState.OK then
            Logging.xmlError(self.xmlFile, "Vehicle post-loading failed!")
            self:loadCallback()
        end
    end, nil, true)
    self:addAsyncTask(function()
        -- upvalues: (copy) self
        SpecializationUtil.raiseAsyncEvent(self, "onPreInitComponentPlacement", self.savegame)
    end)
    self:addAsyncTask(function()
        -- upvalues: (copy) self
        if self.loadingState ~= VehicleLoadingState.OK then
            Logging.xmlError(self.xmlFile, "Vehicle pre init component placement failed!")
            self:loadCallback()
        end
    end, nil, true)
    self:addAsyncTask(function()
        -- upvalues: (copy) self
        if self.isServer then
            for _, jointDesc in pairs(self.componentJoints) do
                if jointDesc.initComponentPosition then
                    local component2 = self.components[jointDesc.componentIndices[2]]
                    local jointNode = jointDesc.jointNode
                    if self:getParentComponent(jointNode) == component2.node then
                        jointNode = jointDesc.jointNodeActor1
                    end
                    if self:getParentComponent(jointNode) ~= component2.node and getParent(component2.node) == jointNode then
                        local ox = 0
                        local oy = 0
                        local oz = 0
                        if jointDesc.jointNodeActor1 ~= jointDesc.jointNode then
                            local x1, y1, z1 = localToLocal(jointDesc.jointNode, component2.node, 0, 0, 0)
                            local x2, y2, z2 = localToLocal(jointDesc.jointNodeActor1, component2.node, 0, 0, 0)
                            ox = x1 - x2
                            oy = y1 - y2
                            oz = z1 - z2
                        end
                        local x1, y1, z1 = localToWorld(component2.node, ox, oy, oz)
                        local x2, y2, z2 = localRotationToWorld(component2.node, 0, 0, 0)
                        link(getRootNode(), component2.node)
                        setWorldTranslation(component2.node, x1, y1, z1)
                        setWorldRotation(component2.node, x2, y2, z2)
                        component2.originalTranslation = { x1, y1, z1 }
                        component2.originalRotation = { x2, y2, z2 }
                        component2.sentTranslation = { x1, y1, z1 }
                        component2.sentRotation = { x2, y2, z2 }
                    end
                end
            end
            for _, jointDesc in pairs(self.componentJoints) do
                self:setComponentJointFrame(jointDesc, 0)
                self:setComponentJointFrame(jointDesc, 1)
            end
        end
        local savegame = self.savegame
        if savegame ~= nil then
            self.age = savegame.xmlFile:getValue(savegame.key .. "#age", 0)
            self.price = savegame.xmlFile:getValue(savegame.key .. "#price", self.price)
            self.propertyState = VehiclePropertyState.loadFromXMLFile(savegame.xmlFile, savegame.key .. "#propertyState") or self.propertyState
            self:setOperatingTime(savegame.xmlFile:getValue(savegame.key .. "#operatingTime", self.operatingTime) * 1000, true)
            local isBroken = savegame.xmlFile:getValue(savegame.key .. "#isBroken", self.isBroken)
            if not savegame.resetVehicles and isBroken then
                self:setBroken()
            end
        end
        if not self.vehicleLoadingData:applyPositionData(self) then
            self:setLoadingState(VehicleLoadingState.NO_SPACE)
            self:loadCallback()
        end
    end, "Vehicle - Components Linking")
    self:addAsyncTask(function()
        -- upvalues: (copy) self
        self:updateSelectableObjects()
        self:setSelectedVehicle(self, nil, true)
        if self.rootVehicle == self then
            local savegame = self.savegame
            if savegame ~= nil then
                self.loadedSelectedObjectIndex = savegame.xmlFile:getValue(savegame.key .. "#selectedObjectIndex")
                self.loadedSubSelectedObjectIndex = savegame.xmlFile:getValue(savegame.key .. "#subSelectedObjectIndex")
            end
        end
        SpecializationUtil.raiseEvent(self, "onPreLoadFinished", self.savegame)
        self:setVisibility(false)
        if #self.loadingTasks == 0 then
            self:onFinishedLoading()
        else
            self.readyForFinishLoading = true
            self:setLoadingStep(SpecializationLoadStep.AWAIT_SUB_I3D)
        end
    end, "Vehicle - Finalize Loading")
end
function Vehicle:addAsyncTask(func, name, ignoreErrorChecks)
    g_asyncTaskManager:addSubtask(function()
        -- upvalues: (copy) ignoreErrorChecks, (copy) self, (copy) func
        if ignoreErrorChecks == true or self.loadingState == VehicleLoadingState.OK and not self.markedForDeletion then
            func()
        end
    end, name)
end
function Vehicle:loadSubSharedI3DFile(filename, callOnCreate, addToPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
    local loadingTask = self:createLoadingTask(self)
    asyncCallbackFunction = asyncCallbackFunction ~= nil and function(target, i3dNode, failedReason, args)
        -- upvalues: (copy) self, (copy) asyncCallbackFunction, (copy) loadingTask
        if self.isDeleted or self.isDeleting then
            if i3dNode ~= 0 then
                delete(i3dNode)
            end
            asyncCallbackFunction(target, 0, failedReason, args)
            self:finishLoadingTask(loadingTask)
        else
            asyncCallbackFunction(target, i3dNode, failedReason, args)
            self:finishLoadingTask(loadingTask)
        end
    end or asyncCallbackFunction
    return g_i3DManager:loadSharedI3DFileAsync(filename, callOnCreate, addToPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
end
function Vehicle:onFinishedLoading()
    if self.isServer then
        self:setVisibility(true)
        self:addToPhysics()
    end
    self:setLoadingStep(SpecializationLoadStep.FINISHED)
    SpecializationUtil.raiseEvent(self, "onLoadFinished", self.savegame)
    ConfigurationUtil.raiseConfigurationItemEvent(self, "onLoadFinished")
    if self.isServer then
        self:setLoadingStep(SpecializationLoadStep.SYNCHRONIZED)
    end
    if g_currentMission ~= nil and (self.propertyState ~= VehiclePropertyState.SHOP_CONFIG and self.mapHotspotAvailable) then
        self:createMapHotspot()
    end
    self.finishedLoading = true
    if g_currentMission.vehicleSystem:addVehicle(self) then
        if self.propertyState == VehiclePropertyState.OWNED then
            g_currentMission:addOwnedItem(self)
        elseif self.propertyState == VehiclePropertyState.LEASED then
            g_currentMission:addLeasedItem(self)
        end
        if self.vehicleLoadingData.isRegistered then
            self:register()
        end
        SpecializationUtil.raiseEvent(self, "onLoadEnd", self.savegame)
        self:loadCallback()
        self.savegame = nil
        self.vehicleLoadingData = nil
    else
        Logging.xmlError(self.xmlFile, "Failed to register vehicle!")
        self:setLoadingState(VehicleLoadingState.ERROR)
        self:loadCallback()
    end
end
function Vehicle:createLoadingTask(target)
    return SpecializationUtil.createLoadingTask(self, target)
end
function Vehicle:finishLoadingTask(task)
    SpecializationUtil.finishLoadingTask(self, task)
end
function Vehicle:getIsBeingDeleted()
    return self.markedForDeletion or (self.isDeleting or self.isDeleted)
end
function Vehicle:delete(immediate)
    if not self.markedForDeletion then
        self:deleteMapHotspot()
        if self.tourId ~= nil then
            g_guidedTourManager:removeVehicle(self.tourId)
        end
        g_messageCenter:unsubscribeAll(self)
        local rootVehicle = self.rootVehicle
        if rootVehicle ~= nil and rootVehicle:getIsAIActive() then
            rootVehicle:stopCurrentAIJob(AIMessageErrorVehicleDeleted.new())
        end
        if self.propertyState == VehiclePropertyState.OWNED then
            g_currentMission:removeOwnedItem(self)
        elseif self.propertyState == VehiclePropertyState.LEASED then
            g_currentMission:removeLeasedItem(self)
        end
    end
    self.markedForDeletion = true
    if g_currentMission.isExitingGame or immediate then
        if self.isDeleted then
            Logging.devError("Trying to delete an already deleted vehicle")
            printCallstack()
        else
            VehicleDebug.delete(self)
            self.isDeleting = true
            g_inputBinding:beginActionEventsModification(Vehicle.INPUT_CONTEXT_NAME)
            self:removeActionEvents()
            g_inputBinding:endActionEventsModification()
            SpecializationUtil.raiseEvent(self, "onPreDelete")
            SpecializationUtil.raiseEvent(self, "onDelete")
            if self.isServer and self.componentJoints ~= nil then
                for _, v in pairs(self.componentJoints) do
                    if v.jointIndex ~= 0 then
                        removeJoint(v.jointIndex)
                    end
                end
                removeWakeUpReport(self.rootNode)
            end
            if self.components ~= nil then
                for _, v in pairs(self.components) do
                    unlink(v.node)
                end
                for _, v in pairs(self.components) do
                    delete(v.node)
                    g_currentMission:removeNodeObject(v.node)
                end
            end
            if self.i3dNode ~= nil then
                delete(self.i3dNode)
                self.i3dNode = nil
            end
            if self.sharedLoadRequestId ~= nil then
                g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
                self.sharedLoadRequestId = nil
            end
            self.xmlFile:delete()
            if self.externalSoundsFile ~= nil then
                self.externalSoundsFile:delete()
            end
            self.rootNode = nil
            self.isDeleting = false
            self.isDeleted = true
            g_currentMission.vehicleSystem:removeVehicle(self)
            Vehicle:superClass().delete(self)
        end
    else
        g_currentMission.vehicleSystem:markVehicleForDeletion(self)
        return
    end
end
function Vehicle:reset(forceDelete, callback, resetPlayer)
    if not self.isResetInProgress then
        if forceDelete then
            self:delete()
        end
        if resetPlayer and (g_localPlayer ~= nil and g_localPlayer:getCurrentVehicle() == self) then
            g_localPlayer:leaveVehicle(nil, true)
            g_localPlayer.mover:teleportToSpawnPoint()
        end
        local vehicle = self:getUniqueId()
        local vehicleSystem = g_currentMission.vehicleSystem
        self.isResetInProgress = true
        local xmlFile = self:getReloadXML()
        local function asyncCallbackFunction(_, vehicles, _)
            -- upvalues: (copy) self, (copy) forceDelete, (copy) vehicleSystem, (copy) vehicle, (copy) callback, (copy) xmlFile
            self.isResetInProgress = false
            if #vehicles > 0 then
                g_messageCenter:publish(MessageType.VEHICLE_RESET, self, vehicles[1])
                if not forceDelete then
                    self:delete()
                end
            elseif not forceDelete then
                vehicleSystem.vehicleByUniqueId[vehicle] = self
            end
            if callback ~= nil then
                callback(#vehicles > 0)
            end
            xmlFile:delete()
        end
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) vehicleSystem, (copy) vehicle, (copy) xmlFile, (copy) asyncCallbackFunction
            vehicleSystem.vehicleByUniqueId[vehicle] = nil
            vehicleSystem:loadFromXMLFile(xmlFile, asyncCallbackFunction, nil, {}, true)
        end)
    end
end
function Vehicle:getNeedsSaving()
    return self.isVehicleSaved
end
function Vehicle:saveToXMLFile(xmlFile, key, usedModNames)
    xmlFile:setValue(key .. "#uniqueId", self.uniqueId)
    xmlFile:setValue(key .. "#age", self.age)
    xmlFile:setValue(key .. "#price", self.price)
    xmlFile:setValue(key .. "#farmId", self:getOwnerFarmId())
    VehiclePropertyState.saveToXMLFile(xmlFile, key .. "#propertyState", self.propertyState)
    xmlFile:setValue(key .. "#operatingTime", self.operatingTime / 1000)
    if self.tourId ~= nil then
        xmlFile:setValue(key .. "#tourId", self.tourId)
    end
    if self.rootVehicle == self then
        xmlFile:setValue(key .. "#selectedObjectIndex", self.currentSelection.index)
        if self.currentSelection.subIndex ~= nil then
            xmlFile:setValue(key .. "#subSelectedObjectIndex", self.currentSelection.subIndex)
        end
    end
    if self.isBroken then
        xmlFile:setValue(key .. "#isBroken", self.isBroken)
    end
    for k, component in ipairs(self.components) do
        local compKey = string.format("%s.component(%d)", key, k - 1)
        local node = component.node
        local x, y, z = getWorldTranslation(node)
        local xRot, yRot, zRot = getWorldRotation(node)
        xmlFile:setValue(compKey .. "#index", k)
        xmlFile:setValue(compKey .. "#position", x, y, z)
        xmlFile:setValue(compKey .. "#rotation", xRot, yRot, zRot)
    end
    ConfigurationUtil.saveConfigurationsToXMLFile(self.configFileName, xmlFile, key .. ".configuration", self.configurations, self.boughtConfigurations, self.configurationData)
    for k, component in pairs(self.specializations) do
        if component.saveToXMLFile ~= nil then
            component.saveToXMLFile(self, xmlFile, key .. "." .. self.specializationNames[k], usedModNames)
        end
    end
    if Platform.gameplay.automaticVehicleControl and self.actionController ~= nil then
        self.actionController:saveToXMLFile(xmlFile, key .. ".actionController", usedModNames)
    end
end
function Vehicle:saveStatsToXMLFile(xmlFile, key)
    local isTabbable = true
    if self.getIsTabbable ~= nil then
        isTabbable = self:getIsTabbable()
    end
    if self.isDeleted or not (self.isVehicleSaved and isTabbable) then
        return false
    end
    local name = "Unknown"
    local categoryName = "unknown"
    local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
    if storeItem ~= nil then
        if storeItem.name ~= nil then
            name = tostring(storeItem.name)
        end
        categoryName = storeItem.categoryName
    end
    setXMLString(xmlFile, key .. "#name", HTMLUtil.encodeToHTML(name))
    setXMLString(xmlFile, key .. "#category", HTMLUtil.encodeToHTML(categoryName))
    local x = setXMLString
    local z = key .. "#type"
    x(xmlFile, z, HTMLUtil.encodeToHTML((tostring(self.typeName))))
    if self.components[1] ~= nil and self.components[1].node ~= 0 then
        local x, y, z = getWorldTranslation(self.components[1].node)
        setXMLFloat(xmlFile, key .. "#x", x)
        setXMLFloat(xmlFile, key .. "#y", y)
        setXMLFloat(xmlFile, key .. "#z", z)
    end
    for id, spec in pairs(self.specializations) do
        if spec.saveStatsToXMLFile ~= nil then
            spec.saveStatsToXMLFile(self, xmlFile, key)
        end
    end
    return true
end
function Vehicle:readStream(streamId, connection, objectId)
    Vehicle:superClass().readStream(self, streamId, connection, objectId)
    local filename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
    local configurations, boughtConfigurations, configurationData = ConfigurationUtil.readConfigurationsFromStream(g_vehicleConfigurationManager, streamId, connection, filename)
    self.propertyState = VehiclePropertyState.readStream(streamId)
    if self.loadingStep == SpecializationLoadStep.CREATED then
        local data = VehicleLoadingData.new()
        data:setFilename(filename)
        data:setPropertyState(self.propertyState)
        data:setOwnerFarmId(self.ownerFarmId)
        data:setConfigurations(configurations)
        data:setBoughtConfigurations(boughtConfigurations)
        data:setConfigurationData(configurationData)
        data:loadVehicleOnClient(self, function(_, vehicle, loadingState)
            if loadingState == VehicleLoadingState.OK then
                g_client:onObjectFinishedAsyncLoading(vehicle)
            else
                Logging.error("Failed to load vehicle on client")
                printCallstack()
            end
        end, nil)
    else
        Logging.error("Try to intialize loading of a vehicle that is already loading!")
    end
end
function Vehicle:postReadStream(streamId, connection)
    self:removeFromPhysics()
    local i = 1
    for i = i, #self.components do
        local component = self.components[i]
        local x = NetworkUtil.readCompressedWorldPosition(streamId, self.highPrecisionPositionSynchronization and (self.vehicleXZPosHighPrecisionCompressionParams or g_currentMission.vehicleXZPosHighPrecisionCompressionParams) or (self.vehicleXZPosCompressionParams or g_currentMission.vehicleXZPosCompressionParams))
        local y = NetworkUtil.readCompressedWorldPosition(streamId, self.highPrecisionPositionSynchronization and (self.vehicleYPosHighPrecisionCompressionParams or g_currentMission.vehicleYPosHighPrecisionCompressionParams) or (self.vehicleYPosCompressionParams or g_currentMission.vehicleYPosCompressionParams))
        local z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
        local x_rot = NetworkUtil.readCompressedAngle(streamId)
        local y_rot = NetworkUtil.readCompressedAngle(streamId)
        local z_rot = NetworkUtil.readCompressedAngle(streamId)
        local qx, qy, qz, qw = mathEulerToQuaternion(x_rot, y_rot, z_rot)
        self:setWorldPositionQuaternion(x, y, z, qx, qy, qz, qw, i, true)
        component.networkInterpolators.position:setPosition(x, y, z)
        component.networkInterpolators.quaternion:setQuaternion(qx, qy, qz, qw)
    end
    self.networkTimeInterpolator:reset()
    self:setVisibility(true)
    self:addToPhysics()
    self.serverMass = streamReadFloat32(streamId)
    self.age = streamReadUInt16(streamId)
    self:setOperatingTime(streamReadFloat32(streamId), true)
    self.price = streamReadInt32(streamId)
    self.isBroken = streamReadBool(streamId)
    if Vehicle.DEBUG_NETWORK_READ_WRITE then
        print("-------------------------------------------------------------")
        print(self.configFileName)
        for component, x in ipairs(self.eventListeners.onReadStream) do
            local y = ClassUtil.getClassName(x)
            local z = streamGetReadOffset(streamId)
            x.onReadStream(self, streamId, connection)
            print("  " .. tostring(y) .. " read " .. streamGetReadOffset(streamId) - z .. " bits")
        end
    else
        SpecializationUtil.raiseEvent(self, "onReadStream", streamId, connection)
    end
    self:setLoadingStep(SpecializationLoadStep.SYNCHRONIZED)
end
function Vehicle:writeStream(streamId, connection)
    Vehicle:superClass().writeStream(self, streamId, connection)
    streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.configFileName))
    ConfigurationUtil.writeConfigurationsToStream(g_vehicleConfigurationManager, streamId, connection, self.configFileName, self.configurations, self.boughtConfigurations, self.configurationData)
    VehiclePropertyState.writeStream(streamId, self.propertyState)
end
function Vehicle:postWriteStream(streamId, connection)
    local i = 1
    for i = i, #self.components do
        local component = self.components[i]
        local x, y, z = getWorldTranslation(component.node)
        local x_rot, y_rot, z_rot = getWorldRotation(component.node)
        NetworkUtil.writeCompressedWorldPosition(streamId, x, self.highPrecisionPositionSynchronization and (self.vehicleXZPosHighPrecisionCompressionParams or g_currentMission.vehicleXZPosHighPrecisionCompressionParams) or (self.vehicleXZPosCompressionParams or g_currentMission.vehicleXZPosCompressionParams))
        NetworkUtil.writeCompressedWorldPosition(streamId, y, self.highPrecisionPositionSynchronization and (self.vehicleYPosHighPrecisionCompressionParams or g_currentMission.vehicleYPosHighPrecisionCompressionParams) or (self.vehicleYPosCompressionParams or g_currentMission.vehicleYPosCompressionParams))
        NetworkUtil.writeCompressedWorldPosition(streamId, z, paramsXZ)
        NetworkUtil.writeCompressedAngle(streamId, x_rot)
        NetworkUtil.writeCompressedAngle(streamId, y_rot)
        NetworkUtil.writeCompressedAngle(streamId, z_rot)
    end
    streamWriteFloat32(streamId, self.serverMass)
    streamWriteUInt16(streamId, self.age)
    streamWriteFloat32(streamId, self.operatingTime)
    streamWriteInt32(streamId, self.price)
    streamWriteBool(streamId, self.isBroken)
    if Vehicle.DEBUG_NETWORK_READ_WRITE then
        print("-------------------------------------------------------------")
        print(self.configFileName)
        for component, x in ipairs(self.eventListeners.onWriteStream) do
            local y = ClassUtil.getClassName(x)
            local z = streamGetWriteOffset(streamId)
            x.onWriteStream(self, streamId, connection)
            print("  " .. tostring(y) .. " Wrote " .. streamGetWriteOffset(streamId) - z .. " bits")
        end
    else
        SpecializationUtil.raiseEvent(self, "onWriteStream", streamId, connection)
    end
end
function Vehicle:readUpdateStream(streamId, timestamp, connection)
    if connection.isServer and streamReadBool(streamId) then
        self.networkTimeInterpolator:startNewPhaseNetwork()
        local i = 1
        for i = i, #self.components do
            local component = self.components[i]
            if not component.isStatic then
                local x = NetworkUtil.readCompressedWorldPosition(streamId, self.highPrecisionPositionSynchronization and (self.vehicleXZPosHighPrecisionCompressionParams or g_currentMission.vehicleXZPosHighPrecisionCompressionParams) or (self.vehicleXZPosCompressionParams or g_currentMission.vehicleXZPosCompressionParams))
                local y = NetworkUtil.readCompressedWorldPosition(streamId, self.highPrecisionPositionSynchronization and (self.vehicleYPosHighPrecisionCompressionParams or g_currentMission.vehicleYPosHighPrecisionCompressionParams) or (self.vehicleYPosCompressionParams or g_currentMission.vehicleYPosCompressionParams))
                local z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
                local x_rot = NetworkUtil.readCompressedAngle(streamId)
                local y_rot = NetworkUtil.readCompressedAngle(streamId)
                local z_rot = NetworkUtil.readCompressedAngle(streamId)
                local qx, qy, qz, qw = mathEulerToQuaternion(x_rot, y_rot, z_rot)
                component.networkInterpolators.position:setTargetPosition(x, y, z)
                component.networkInterpolators.quaternion:setTargetQuaternion(qx, qy, qz, qw)
            end
        end
        SpecializationUtil.raiseEvent(self, "onReadPositionUpdateStream", streamId, connection)
    end
    if Vehicle.DEBUG_NETWORK_READ_WRITE_UPDATE then
        print("-------------------------------------------------------------")
        print(self.configFileName)
        for _, spec in ipairs(self.eventListeners.onReadUpdateStream) do
            local i = ClassUtil.getClassName(spec)
            local component = streamGetReadOffset(streamId)
            spec.onReadUpdateStream(self, streamId, timestamp, connection)
            print("  " .. tostring(i) .. " read " .. streamGetReadOffset(streamId) - component .. " bits")
        end
    else
        SpecializationUtil.raiseEvent(self, "onReadUpdateStream", streamId, timestamp, connection)
    end
end
function Vehicle:writeUpdateStream(streamId, connection, dirtyMask)
    if not connection.isServer then
        local paramsXZ = streamWriteBool
        local component = self.vehicleDirtyFlag
        if paramsXZ(streamId, bit32.band(dirtyMask, component) ~= 0) then
            local i = 1
            for i = i, #self.components do
                local component = self.components[i]
                if not component.isStatic then
                    local x, y, z = getWorldTranslation(component.node)
                    local x_rot, y_rot, z_rot = getWorldRotation(component.node)
                    NetworkUtil.writeCompressedWorldPosition(streamId, x, self.highPrecisionPositionSynchronization and (self.vehicleXZPosHighPrecisionCompressionParams or g_currentMission.vehicleXZPosHighPrecisionCompressionParams) or (self.vehicleXZPosCompressionParams or g_currentMission.vehicleXZPosCompressionParams))
                    NetworkUtil.writeCompressedWorldPosition(streamId, y, self.highPrecisionPositionSynchronization and (self.vehicleYPosHighPrecisionCompressionParams or g_currentMission.vehicleYPosHighPrecisionCompressionParams) or (self.vehicleYPosCompressionParams or g_currentMission.vehicleYPosCompressionParams))
                    NetworkUtil.writeCompressedWorldPosition(streamId, z, paramsXZ)
                    NetworkUtil.writeCompressedAngle(streamId, x_rot)
                    NetworkUtil.writeCompressedAngle(streamId, y_rot)
                    NetworkUtil.writeCompressedAngle(streamId, z_rot)
                end
            end
            SpecializationUtil.raiseEvent(self, "onWritePositionUpdateStream", streamId, connection, dirtyMask)
        end
    end
    if Vehicle.DEBUG_NETWORK_READ_WRITE_UPDATE then
        print("-------------------------------------------------------------")
        print(self.configFileName)
        for _, i in ipairs(self.eventListeners.onWriteUpdateStream) do
            local component = ClassUtil.getClassName(i)
            local x = streamGetWriteOffset(streamId)
            i.onWriteUpdateStream(self, streamId, connection, dirtyMask)
            print("  " .. tostring(component) .. " Wrote " .. streamGetWriteOffset(streamId) - x .. " bits")
        end
    else
        SpecializationUtil.raiseEvent(self, "onWriteUpdateStream", streamId, connection, dirtyMask)
    end
end
function Vehicle:updateVehicleSpeed(dt)
    if self.finishedFirstUpdate and not self.components[1].isStatic then
        local speedReal = 0
        local movedDistance = 0
        local movingDirection = 0
        local signedSpeedReal = 0
        if self.isServer and not self.components[1].isKinematic then
            if self.components[1].isDynamic then
                local interpPos, dx, dy = getLocalLinearVelocity(self.components[1].node)
                if self.directionReferenceNode ~= nil then
                    interpPos, dx, dy = localDirectionToLocal(self.components[1].node, self.directionReferenceNode, interpPos, dx, dy)
                end
                speedReal = MathUtil.vector3Length(interpPos, dx, dy) * 0.001
                movedDistance = speedReal * g_physicsDt
                signedSpeedReal = speedReal * (dy >= 0 and 1 or -1)
                if dy > 0.001 then
                    movingDirection = 1
                elseif dy < -0.001 then
                    movingDirection = -1
                end
            end
        elseif self.isServer or not self.synchronizePosition then
            local interpPos, dx, dy = getWorldTranslation(self.components[1].node)
            if self.lastPosition == nil then
                self.lastPosition = { interpPos, dx, dy }
            end
            local dz, dy, dz = worldDirectionToLocal(self.directionReferenceNode or self.components[1].node, interpPos - self.lastPosition[1], dx - self.lastPosition[2], dy - self.lastPosition[3])
            self.lastPosition[1] = interpPos
            self.lastPosition[2] = dx
            self.lastPosition[3] = dy
            movedDistance = MathUtil.vector3Length(dz, dy, dz)
            signedSpeedReal = movedDistance / dt * (dz >= 0 and 1 or -1)
        else
            local dx = 0
            local dy = 0
            local dz = 0
            if self.networkTimeInterpolator:isInterpolating() then
                dx, dy, dz = worldDirectionToLocal(self.directionReferenceNode or self.components[1].node, self.components[1].networkInterpolators.position.targetPositionX - self.components[1].networkInterpolators.position.lastPositionX, self.components[1].networkInterpolators.position.targetPositionY - self.components[1].networkInterpolators.position.lastPositionY, self.components[1].networkInterpolators.position.targetPositionZ - self.components[1].networkInterpolators.position.lastPositionZ)
            end
            speedReal = MathUtil.vector3Length(dx, dy, dz) / self.networkTimeInterpolator.interpolationDuration
            local dy = dz >= 0 and 1 or -1
            signedSpeedReal = speedReal * dy
            movedDistance = speedReal * dt
        end
        if self.isServer then
            if g_physicsDtNonInterpolated > 0 then
                self.lastSpeedAcceleration = (speedReal * movingDirection - self.lastSpeedReal * self.movingDirection) / g_physicsDtNonInterpolated
            end
        else
            self.lastSpeedAcceleration = (speedReal * movingDirection - self.lastSpeedReal * self.movingDirection) / dt
        end
        if self.isServer then
            self.lastSpeed = self.lastSpeed * 0.5 + speedReal * 0.5
            self.lastSignedSpeed = self.lastSignedSpeed * 0.5 + signedSpeedReal * 0.5
        else
            self.lastSpeed = self.lastSpeed * 0.9 + speedReal * 0.1
            self.lastSignedSpeed = self.lastSignedSpeed * 0.9 + signedSpeedReal * 0.1
        end
        self.lastSpeedSmoothed = self.lastSpeedSmoothed * 0.9 + speedReal * 0.1
        self.lastSpeedReal = speedReal
        self.lastSignedSpeedReal = signedSpeedReal
        self.movingDirection = movingDirection
        self.lastMovedDistance = movedDistance
    end
end
function Vehicle:update(dt)
    if self.isServer then
        local mapBoundingSize = g_currentMission.terrainSize
        local wx, wy, wz = getTranslation(self.rootNode)
        if MathUtil.isNan(wx) then
            if not self.isDeleting or self.isDeleted then
                Logging.error("Invalid vehicle translation detected, resetting to shop (%s)", self.configFileName)
                self:setRelativePosition(0, 0, 0, 0)
                self:reset(true, nil, true)
            end
            return
        end
        if wx < -mapBoundingSize or (mapBoundingSize < wx or (wz < -mapBoundingSize or mapBoundingSize < wz)) then
            if not self.isDeleting or self.isDeleted then
                Logging.error("Vehicle outside of the world detected, resetting to shop (%s)", self.configFileName)
                self:reset(true, nil, true)
            end
            return
        end
        if wy < -mapBoundingSize then
            if not self.isDeleting or self.isDeleted then
                local resetThreshold = mapBoundingSize * 0.5 - 25
                if wx < -resetThreshold or (resetThreshold < wx or (wz < -resetThreshold or resetThreshold < wz)) then
                    Logging.error("Vehicle below the world detected, resetting to shop (%s)", self.configFileName)
                    self:reset(true, nil, true)
                    return
                end
                if self.terrainHeightResetCounter > 5 then
                    self.terrainHeightResetCounter = 0
                    Logging.error("Vehicle below the world detected multiple times, resetting to shop (%s)", self.configFileName)
                    self:reset(true, nil, true)
                    return
                end
                Logging.error("Vehicle below the world detected, resetting to terrain level again (%s)", self.configFileName)
                self.rootVehicle:resetPositionToTerrainHeight()
                self.terrainHeightResetCounter = self.terrainHeightResetCounter + 1
            end
            return
        end
    end
    self.isActive = self:getIsActive()
    local mapBoundingSize = self:getIsActiveForInput()
    local wx = self:getIsActiveForInput(true)
    local wy = self:getIsSelected()
    local wz = 999999
    local resetThreshold = self.rootNode
    if resetThreshold ~= nil then
        local cameraNode = g_cameraManager:getActiveCamera()
        wz = calcDistanceFrom(resetThreshold, cameraNode)
    end
    self.lastDistanceToCamera = wz
    self.currentUpdateDistance = wz / self.viewDistanceCoeff
    self.isActiveForInputIgnoreSelectionIgnoreAI = self:getIsActiveForInput(true, true)
    self.isActiveForLocalSound = self.isActiveForInputIgnoreSelectionIgnoreAI
    self.updateLoopIndex = g_updateLoopIndex
    SpecializationUtil.raiseEvent(self, "onPreUpdate", dt, mapBoundingSize, wx, wy)
    if not self.isServer and self.synchronizePosition then
        self.networkTimeInterpolator:update(dt)
        local cameraNode = self.networkTimeInterpolator:getAlpha()
        for i, component in pairs(self.components) do
            if not component.isStatic then
                local posX, posY, posZ = component.networkInterpolators.position:getInterpolatedValues(cameraNode)
                local quatX, quatY, quatZ, quatW = component.networkInterpolators.quaternion:getInterpolatedValues(cameraNode)
                self:setWorldPositionQuaternion(posX, posY, posZ, quatX, quatY, quatZ, quatW, i, false)
            end
        end
        if self.networkTimeInterpolator:isInterpolating() then
            self:raiseActive()
        end
    end
    SpecializationUtil.raiseEvent(self, "onUpdateInterpolation", dt, mapBoundingSize, wx, wy)
    self:updateVehicleSpeed(dt)
    if self.actionEventUpdateRequested then
        self:updateActionEvents()
    end
    if Platform.gameplay.automaticVehicleControl then
        if self.actionController ~= nil then
            self.actionController:update(dt)
            self.actionController:updateForAI(dt)
        end
    elseif self.actionController ~= nil then
        self.actionController:updateForAI(dt)
    end
    SpecializationUtil.raiseEvent(self, "onUpdate", dt, mapBoundingSize, wx, wy)
    if Vehicle.debuggingActive then
        SpecializationUtil.raiseEvent(self, "onUpdateDebug", dt, mapBoundingSize, wx, wy)
    end
    SpecializationUtil.raiseEvent(self, "onPostUpdate", dt, mapBoundingSize, wx, wy)
    if self.finishedFirstUpdate and self.isMassDirty then
        self.isMassDirty = false
        self:updateMass()
    end
    self.finishedFirstUpdate = true
    if self.isServer and not getIsSleeping(self.rootNode) then
        self:raiseActive()
    end
    VehicleDebug.updateDebug(self, dt)
    self:updateMapHotspot()
end
function Vehicle:updateTick(dt)
    if self.isServer then
        local wx, _, _ = getWorldTranslation(self.rootNode)
        if MathUtil.isNan(wx) then
            return
        end
    end
    local wx = self:getIsActiveForInput()
    local _ = self:getIsActiveForInput(true)
    local _ = self:getIsSelected()
    if self.isActive and self.needWaterInfo then
        self:updateWaterInfo()
    end
    self.isOnField = self:getIsOnField()
    if not (self.isServer and self.synchronizePosition) then
        ::l8::
        self.showTailwaterDepthWarning = false
        if not self.isBroken and (not g_gui:getIsGuiVisible() and self.tailwaterDepth > self.thresholdTailwaterDepthWarning) then
            self.showTailwaterDepthWarning = true
            if self.tailwaterDepth > self.thresholdTailwaterDepth then
                self:setBroken()
            end
        end
        local hasOwner = self.rootVehicle
        if hasOwner ~= nil and hasOwner ~= self then
            hasOwner.showTailwaterDepthWarning = hasOwner.showTailwaterDepthWarning or self.showTailwaterDepthWarning
        end
        if self:getIsOperating() then
            self:setOperatingTime(self.operatingTime + dt)
        end
        SpecializationUtil.raiseEvent(self, "onUpdateTick", dt, wx, _, _)
        SpecializationUtil.raiseEvent(self, "onPostUpdateTick", dt, wx, _, _)
        return
    end
    local hasOwner = self:getOwnerConnection() ~= nil
    local i = 1
    for i = i, #self.components do
        local component = self.components[i]
        if not component.isStatic then
            local x, y, z = getWorldTranslation(component.node)
            local x_rot, y_rot, z_rot = getWorldRotation(component.node)
            if hasOwner then
                ::l17::
                self:raiseDirtyFlags(self.vehicleDirtyFlag)
                component.sentTranslation[1] = x
                sentTranslation[2] = y
                sentTranslation[3] = z
                component.sentRotation[1] = x_rot
                sentRotation[2] = y_rot
                sentRotation[3] = z_rot
                self.lastMoveTime = g_currentMission.time
            else
                if math.abs(x - sentTranslation[1]) > 0.005 then
                    goto l17
                end
                if math.abs(y - sentTranslation[2]) > 0.005 then
                    goto l17
                end
                if math.abs(z - sentTranslation[3]) > 0.005 then
                    goto l17
                end
                if math.abs(x_rot - sentRotation[1]) > 0.1 then
                    goto l17
                end
                if math.abs(y_rot - sentRotation[2]) > 0.1 then
                    goto l17
                end
                if math.abs(z_rot - sentRotation[3]) > 0.1 then
                    goto l17
                end
            end
        end
    end
    goto l8
end
function Vehicle:updateEnd(dt)
    local isActiveForInput = self:getIsActiveForInput()
    local isActiveForInputIgnoreSelection = self:getIsActiveForInput(true)
    local isSelected = self:getIsSelected()
    self.currentUpdateDistance = 0
    SpecializationUtil.raiseEvent(self, "onUpdateEnd", dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
end
function Vehicle:draw(subDraw)
    if self:getIsSynchronized() then
        local rootVehicle = self.rootVehicle
        local selectedVehicle = self:getSelectedVehicle()
        if not subDraw then
            if self ~= rootVehicle and selectedVehicle ~= rootVehicle then
                rootVehicle:draw(true)
            end
            if selectedVehicle ~= nil and (self ~= selectedVehicle and selectedVehicle ~= rootVehicle) then
                selectedVehicle:draw(true)
            end
        end
        if selectedVehicle == self or rootVehicle == self then
            local isActiveForInput = self:getIsActiveForInput()
            local isActiveForInputIgnoreSelection = self:getIsActiveForInput(true)
            SpecializationUtil.raiseEvent(self, "onDraw", isActiveForInput, isActiveForInputIgnoreSelection, true)
        end
        VehicleDebug.drawDebug(self)
        if self.showTailwaterDepthWarning then
            g_currentMission:showBlinkingWarning(g_i18n:getText("warning_dontDriveIntoWater"), 2000)
        end
    end
end
function Vehicle:drawUIInfo()
    if self:getIsSynchronized() then
        SpecializationUtil.raiseEvent(self, "onDrawUIInfo")
        if g_showVehicleDistance then
            local dist = calcDistanceFrom(self.rootNode, g_cameraManager:getActiveCamera())
            if dist <= 350 then
                local x, y, z = getWorldTranslation(self.rootNode)
                Utils.renderTextAtWorldPosition(x, y + 1, z, string.format("%.0f", dist), getCorrectTextSize(0.02), 0)
            end
        end
    end
end
function Vehicle:setLoadingState(loadingState)
    if VehicleLoadingState.getName(loadingState) == nil then
        printCallstack()
        Logging.error("Invalid loading state \'%s\'!", loadingState)
    else
        self.loadingState = loadingState
    end
end
function Vehicle:setLoadingStep(loadingStep)
    SpecializationUtil.setLoadingStep(self, loadingStep)
end
function Vehicle:addToPhysics()
    if self.isAddedToPhysics then
        return false
    end
    local lastMotorizedNode = nil
    for _, component in pairs(self.components) do
        addToPhysics(component.node)
        if component.motorized then
            if lastMotorizedNode ~= nil and self.isServer then
                addVehicleLink(lastMotorizedNode, component.node)
            end
            lastMotorizedNode = component.node
        end
    end
    self.isAddedToPhysics = true
    if self.isServer then
        for _, component in pairs(self.componentJoints) do
            self:createComponentJoint(self.components[component.componentIndices[1]], self.components[component.componentIndices[2]], component)
        end
        addWakeUpReport(self.rootNode, "onVehicleWakeUpCallback", self)
    end
    for _, component in pairs(self.collisionPairs) do
        setPairCollision(component.component1.node, component.component2.node, component.enabled)
    end
    self:setMassDirty()
    return true
end
function Vehicle:removeFromPhysics()
    for _, component in pairs(self.components) do
        removeFromPhysics(component.node)
    end
    if self.isServer then
        for _, component in pairs(self.componentJoints) do
            component.jointIndex = 0
        end
        removeWakeUpReport(self.rootNode)
    end
    self.isAddedToPhysics = false
    return true
end
function Vehicle:setVisibility(state)
    for _, component in pairs(self.components) do
        setVisibility(component.node, state)
    end
end
function Vehicle:setRelativePosition(positionX, offsetY, positionZ, yRot)
    self:setAbsolutePosition(positionX, getTerrainHeightAtWorldPos(g_terrainNode, positionX, 300, positionZ) + offsetY, positionZ, 0, yRot, 0)
end
function Vehicle:setAbsolutePosition(positionX, positionY, positionZ, xRot, yRot, zRot, componentPositions)
    local tempRootNode = createTransformGroup("tempRootNode")
    setTranslation(tempRootNode, positionX, positionY, positionZ)
    setRotation(tempRootNode, xRot, yRot, zRot)
    for i, component in pairs(self.components) do
        local x = localToWorld
        local rx = component.originalTranslation
        local x, y, z = x(tempRootNode, unpack(rx))
        local rx = localRotationToWorld
        local rx, ry, rz = rx(tempRootNode, unpack(component.originalRotation))
        if componentPositions ~= nil and #componentPositions == #self.components then
            x, y, z = unpack(componentPositions[i][1])
            rx, ry, rz = unpack(componentPositions[i][2])
        end
        self:setWorldPosition(x, y, z, rx, ry, rz, i, true)
    end
    delete(tempRootNode)
    self.networkTimeInterpolator:reset()
end
function Vehicle.getLimitedVehicleYPosition(_, position)
    if position.posY == nil then
        return getTerrainHeightAtWorldPos(g_terrainNode, position.posX, 300, position.posZ) + Utils.getNoNil(position.yOffset, 0)
    else
        return position.posY
    end
end
function Vehicle:setWorldPosition(x, y, z, xRot, yRot, zRot, componentIndex, changeInterp)
    local component = self.components[componentIndex]
    if component ~= nil then
        setWorldTranslation(component.node, x, y, z)
        setWorldRotation(component.node, xRot, yRot, zRot)
        if changeInterp then
            local qx, qy, qz, qw = mathEulerToQuaternion(xRot, yRot, zRot)
            component.networkInterpolators.quaternion:setQuaternion(qx, qy, qz, qw)
            component.networkInterpolators.position:setPosition(x, y, z)
        end
    end
end
function Vehicle:setWorldPositionQuaternion(x, y, z, qx, qy, qz, qw, componentIndex, changeInterp)
    local component = self.components[componentIndex]
    if component ~= nil then
        setWorldTranslation(component.node, x, y, z)
        setWorldQuaternion(component.node, qx, qy, qz, qw)
        if changeInterp then
            component.networkInterpolators.quaternion:setQuaternion(qx, qy, qz, qw)
            component.networkInterpolators.position:setPosition(x, y, z)
        end
    end
end
function Vehicle:setDefaultComponentPosition(componentIndex)
    if componentIndex ~= 1 then
        local component = self.components[componentIndex]
        if component ~= nil then
            local x, y, z = localToWorld(self.rootNode, unpack(component.originalTranslation))
            local rx, ry, rz = localRotationToWorld(self.rootNode, unpack(component.originalRotation))
            self:setWorldPosition(x, y, z, rx, ry, rz, componentIndex, true)
        end
    end
end
function Vehicle:resetPositionToTerrainHeight()
    local maxOffset = 0
    for i, component in pairs(self.components) do
        local wx, wy, wz = getWorldTranslation(component.node)
        maxOffset = math.max(maxOffset, getTerrainHeightAtWorldPos(g_terrainNode, wx, wy, wz) - wy)
    end
    self:removeFromPhysics()
    for i, component in pairs(self.components) do
        local wx, wy, wz = getWorldTranslation(component.node)
        setWorldTranslation(component.node, wx, wy + maxOffset + 10, wz)
    end
    self:addToPhysics()
    for i, component in ipairs(self.childVehicles) do
        if component ~= self then
            component:resetPositionToTerrainHeight()
        end
    end
end
function Vehicle:getIsNodeActive(node)
    while node ~= 0 do
        for _, rootLevelNode in ipairs(self.rootLevelNodes) do
            if node == rootLevelNode.node then
                return not rootLevelNode.isInactive
            end
        end
        node = getParent(node)
    end
    return false
end
function Vehicle:getUpdatePriority(skipCount, x, y, z, coeff, connection, _)
    if self:getOwnerConnection() == connection then
        return 50
    end
    local x1, y1, z1 = getWorldTranslation(self.components[1].node)
    return (1 - MathUtil.vector3Length(x1 - x, y1 - y, z1 - z) / (getClipDistance(self.components[1].node) * coeff)) * 0.8 + 0.5 * skipCount * 0.2
end
function Vehicle:getPrice()
    return self.price
end
function Vehicle:getSellPrice()
    local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
    return Vehicle.calculateSellPrice(storeItem, self.age, self.operatingTime, self:getPrice(), self:getRepairPrice(), self:getRepaintPrice())
end
function Vehicle.calculateSellPrice(storeItem, age, operatingTime, price, repairPrice, repaintPrice)
    StoreItemUtil.loadSpecsFromXML(storeItem)
    local ageFactor = math.min(-0.1 * math.log(age / Environment.PERIODS_IN_YEAR) + 0.75, 0.85)
    return math.max(price * (1 - (operatingTime / 3600000) ^ (storeItem.specs.power == nil and 1.3 or 1) / storeItem.lifetime) * ageFactor - repairPrice - repaintPrice, price * 0.03)
end
function Vehicle:getIsOnField()
    for _, component in pairs(self.components) do
        local wx, wy, wz = localToWorld(component.node, getCenterOfMass(component.node))
        if wy < getTerrainHeightAtWorldPos(g_terrainNode, wx, wy, wz) - 1 then
            break
        end
        local isOnField, _ = FSDensityMapUtil.getFieldDataAtWorldPosition(wx, wy, wz)
        if isOnField then
            return true
        end
    end
    return false
end
function Vehicle:getParentComponent(node)
    while node ~= 0 do
        if self:getIsVehicleNode(node) then
            return node
        end
        node = getParent(node)
    end
    return 0
end
function Vehicle:getLastSpeed(useAttacherVehicleSpeed)
    if useAttacherVehicleSpeed and self.attacherVehicle ~= nil then
        return self.attacherVehicle:getLastSpeed(true)
    else
        return self.lastSpeed * 3600
    end
end
g_soundManager:registerModifierType("SPEED", Vehicle.getLastSpeed)
function Vehicle:getDeactivateOnLeave()
    return true
end
function Vehicle:getIsSynchronized()
    return self.loadingStep == SpecializationLoadStep.SYNCHRONIZED
end
function Vehicle:getActiveFarm()
    return self:getOwnerFarmId()
end
function Vehicle:getIsVehicleNode(nodeId)
    return self.vehicleNodes[nodeId] ~= nil
end
function Vehicle:getIsOperating()
    return false
end
function Vehicle:getIsActive()
    if self.isBroken then
        return false
    else
        return self.forceIsActive and true or false
    end
end
function Vehicle:getIsActiveForInput(ignoreSelection, activeForAI)
    if not self.allowsInput then
        return false
    end
    if not g_currentMission.isRunning then
        return false
    end
    if (activeForAI == nil or not activeForAI) and self:getIsAIActive() then
        return false
    end
    if not ignoreSelection then
        local rootVehicle = self.rootVehicle
        if rootVehicle == nil then
            return false
        end
        if self ~= rootVehicle:getSelectedVehicle() then
            return false
        end
    end
    local rootVehicle = self.rootVehicle
    if rootVehicle == self then
        if self.getIsEntered == nil and (self.getAttacherVehicle ~= nil and self:getAttacherVehicle() == nil) then
            return false
        end
    elseif not rootVehicle:getIsActiveForInput(true, activeForAI) then
        return false
    end
    return true
end
function Vehicle:getIsActiveForSound()
    printWarning("Warning: Vehicle:getIsActiveForSound() is deprecated")
    return false
end
function Vehicle:getIsLowered(defaultIsLowered)
    return false
end
function Vehicle:updateWaterInfo()
    if not self.waterCheckIsPending then
        local x, y, z = localToWorld(self.rootNode, 0, self.size.height * 0.5, 0)
        self.waterCheckPosition[1] = x
        self.waterCheckPosition[2] = y
        self.waterCheckPosition[3] = z
        self.waterCheckIsPending = true
        raycastClosestAsync(x, y + 25, z, 0, -1, 0, 50, "onWaterRaycastCallback", self, CollisionFlag.WATER)
    end
end
function Vehicle:onWaterRaycastCallback(nodeId, _, y, _, _, _, _, _, _, _, _)
    self.waterCheckIsPending = false
    local checkY = self.waterCheckPosition[2] - self.size.height * 0.5
    local waterY = nodeId == 0 and -2500 or y
    self.waterY = waterY
    local checkX = checkY < waterY
    self.isInWater = checkX
    self.isInShallowWater = false
    self.isInMediumWater = false
    if self.isInWater then
        self.isInShallowWater = math.max(0, waterY - getTerrainHeightAtWorldPos(g_terrainNode, self.waterCheckPosition[1], 0, self.waterCheckPosition[3])) <= 0.5
        self.isInMediumWater = not self.isInShallowWater
    end
    self.tailwaterDepth = math.max(0, waterY - checkY)
    return false
end
function Vehicle:setBroken()
    if self.isServer and not self.isBroken then
        g_server:broadcastEvent(VehicleBrokenEvent.new(self), nil, nil, self)
    end
    self.isBroken = true
    SpecializationUtil.raiseEvent(self, "onSetBroken")
    if self.tourId ~= nil and g_guidedTourManager:getIsTourRunning() then
        g_guidedTourManager:abortTour()
    end
end
function Vehicle:getVehicleDamage()
    return 0
end
function Vehicle:getRepairPrice()
    return 0
end
function Vehicle:getRepaintPrice()
    return 0
end
function Vehicle:requestActionEventUpdate()
    local vehicle = self.rootVehicle
    if vehicle == self then
        self.actionEventUpdateRequested = true
    else
        vehicle:requestActionEventUpdate()
    end
    vehicle:removeActionEvents()
end
function Vehicle:removeActionEvents()
    g_inputBinding:removeActionEventsByTarget(self)
end
function Vehicle:updateActionEvents()
    self.rootVehicle:registerActionEvents()
end
function Vehicle:registerActionEvents(excludedVehicle)
    if not g_gui:getIsGuiVisible() and (not g_currentMission.isPlayerFrozen and excludedVehicle ~= self) then
        self.actionEventUpdateRequested = false
        local isActiveForInput = self:getIsActiveForInput()
        local isActiveForInputIgnoreSelection = self:getIsActiveForInput(true)
        if isActiveForInput then
            g_inputBinding:resetActiveActionBindings()
        end
        g_inputBinding:beginActionEventsModification(Vehicle.INPUT_CONTEXT_NAME)
        SpecializationUtil.raiseEvent(self, "onPreRegisterActionEvents", isActiveForInput, isActiveForInputIgnoreSelection)
        SpecializationUtil.raiseEvent(self, "onRegisterActionEvents", isActiveForInput, isActiveForInputIgnoreSelection)
        self:clearActionEventsTable(self.actionEvents)
        if self:getCanToggleSelectable() then
            local numSelectableObjects = 0
            for _, object in ipairs(self.selectableObjects) do

            end
            if numSelectableObjects > 1 then
                local _, actionEventId = self:addActionEvent(self.actionEvents, InputAction.SWITCH_IMPLEMENT, self, Vehicle.actionEventToggleSelection, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
                local _, _ = self:addActionEvent(self.actionEvents, InputAction.SWITCH_IMPLEMENT_BACK, self, Vehicle.actionEventToggleSelectionReverse, false, true, false, true, nil)
                g_inputBinding:setActionEventTextVisibility(_, false)
            end
        end
        VehicleDebug.registerActionEvents(self)
        if Platform.gameplay.automaticVehicleControl and (self.actionController ~= nil and (self:getIsActiveForInput(true) and self == self.rootVehicle)) then
            self.actionController:registerActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
        end
        g_inputBinding:endActionEventsModification()
    end
end
function Vehicle.clearActionEventsTable(_, actionEventsTable)
    if actionEventsTable ~= nil then
        for actionEventName, actionEvent in pairs(actionEventsTable) do
            g_inputBinding:removeActionEvent(actionEvent.actionEventId)
            actionEventsTable[actionEventName] = nil
        end
    end
end
function Vehicle:addPoweredActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions, reportAnyDeviceCollision)
    return self:addActionEvent(actionEventsTable, inputAction, target, function(vehicle, actionName, inputValue, state, isAnalog, isMouse, deviceCategory, binding)
        -- upvalues: (copy) callback
        local isPowered, warning = vehicle:getIsPowered()
        if isPowered then
            callback(vehicle, actionName, inputValue, state, isAnalog, isMouse, deviceCategory, binding)
        elseif inputValue ~= 0 and warning ~= nil then
            g_currentMission:showBlinkingWarning(warning, 2000)
        end
    end, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions, reportAnyDeviceCollision)
end
function Vehicle:addActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions, reportAnyDeviceCollision)
    local state, actionEventId, otherEvents = g_inputBinding:registerActionEvent(inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, true, reportAnyDeviceCollision)
    if state then
        actionEventsTable[inputAction] = {
            ["actionEventId"] = actionEventId
        }
        local event = g_inputBinding.events[actionEventId]
        if event ~= nil then
            event.parentEventsTable = actionEventsTable
        end
        if customIconName and customIconName ~= "" then
            g_inputBinding:setActionEventIcon(actionEventId, customIconName)
        end
    end
    if otherEvents ~= nil and (ignoreCollisions == nil or not ignoreCollisions) then
        if self:getIsSelected() then
            local event = false
            for _, otherEvent in ipairs(otherEvents) do
                if otherEvent.parentEventsTable ~= nil then
                    g_inputBinding:removeActionEvent(otherEvent.id)
                    otherEvent.parentEventsTable[otherEvent.id] = nil
                    event = true
                end
            end
            if event then
                return self:addActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
            end
        else
            g_inputBinding:removeActionEvent(actionEventId)
            for _, _ in ipairs(otherEvents) do
                if _.targetObject.getIsSelected ~= nil and (not _.targetObject:getIsSelected() and _.parentEventsTable ~= nil) then
                    g_inputBinding:removeActionEvent(_.id)
                    _.parentEventsTable[_.id] = nil
                end
            end
        end
    end
    return state, actionEventId
end
function Vehicle.removeActionEvent(_, actionEventsTable, inputAction)
    if actionEventsTable[inputAction] ~= nil then
        g_inputBinding:removeActionEvent(actionEventsTable[inputAction].actionEventId)
        actionEventsTable[inputAction] = nil
    end
end
function Vehicle:updateSelectableObjects()
    self.selectableObjects = {}
    if self == self.rootVehicle then
        self:registerSelectableObjects(self.selectableObjects)
    end
end
function Vehicle:registerSelectableObjects(selectableObjects)
    if self:getCanBeSelected() and not self:getBlockSelection() then
        table.insert(selectableObjects, self.selectionObject)
        self.selectionObject.index = #selectableObjects
    end
end
function Vehicle:addSubselection(subSelection)
    table.insert(self.selectionObject.subSelections, subSelection)
    return #self.selectionObject.subSelections
end
function Vehicle:clearSubselections()
    self.selectionObject.subSelections = {}
end
function Vehicle:getCanBeSelected()
    return VehicleDebug.state ~= 0
end
function Vehicle:getBlockSelection()
    return not self.allowSelection
end
function Vehicle:getCanToggleSelectable()
    return false
end
function Vehicle:getRootVehicle()
    return self.rootVehicle
end
function Vehicle:findRootVehicle()
    return self
end
function Vehicle:getChildVehicles()
    return self.childVehicles
end
function Vehicle:getChildVehicleHash()
    return self.childVehicleHash
end
function Vehicle:addChildVehicles(vehicles, rootVehicle)
    table.insert(vehicles, self)
    rootVehicle.childVehicleHash = rootVehicle.childVehicleHash .. ":" .. tostring(self.id)
end
function Vehicle:updateVehicleChain(secondCall)
    local rootVehicle = self:findRootVehicle()
    if rootVehicle ~= self.rootVehicle then
        self.rootVehicle = rootVehicle
        SpecializationUtil.raiseEvent(self, "onRootVehicleChanged", rootVehicle)
    end
    if rootVehicle == self or secondCall then
        local i = #self.childVehicles
        for i = i, 1, -1 do
            self.childVehicles[i] = nil
        end
        self.childVehicleHash = ""
        self:addChildVehicles(self.childVehicles, self)
        if rootVehicle == self then
            local i = 1
            for i = i, #self.childVehicles do
                if self.childVehicles[i] ~= rootVehicle then
                    self.childVehicles[i]:updateVehicleChain(true)
                end
            end
        end
    else
        rootVehicle:updateVehicleChain()
    end
end
function Vehicle:unselectVehicle()
    self.selectionObject.isSelected = false
    SpecializationUtil.raiseEvent(self, "onUnselect")
    self:requestActionEventUpdate()
end
function Vehicle:selectVehicle(subSelectionIndex, ignoreActionEventUpdate)
    self.selectionObject.isSelected = true
    SpecializationUtil.raiseEvent(self, "onSelect", subSelectionIndex)
    if ignoreActionEventUpdate == nil or not ignoreActionEventUpdate then
        self:requestActionEventUpdate()
    end
end
function Vehicle:setSelectedVehicle(vehicle, subSelectionIndex, ignoreActionEventUpdate)
    local object = nil
    if vehicle == nil or (not vehicle:getCanBeSelected() or self:getBlockSelection()) then
        vehicle = nil
        for _, o in ipairs(self.selectableObjects) do
            if o.vehicle:getCanBeSelected() and not o.vehicle:getBlockSelection() then
                vehicle = o.vehicle
                break
            end
        end
    end
    if vehicle ~= nil then
        object = vehicle.selectionObject
    end
    return self:setSelectedObject(object, subSelectionIndex, ignoreActionEventUpdate)
end
function Vehicle:setSelectedObject(object, subSelectionIndex, ignoreActionEventUpdate)
    if object == nil then
        object = self:getSelectedObject()
    end
    local found = false
    for _, o in ipairs(self.selectableObjects) do
        if o == object then
            found = true
        end
    end
    if found then
        for _, o in ipairs(self.selectableObjects) do
            if o ~= object and o.vehicle:getIsSelected() then
                o.vehicle:unselectVehicle()
            end
        end
        if object ~= self.currentSelection.object or subSelectionIndex ~= self.currentSelection.subIndex then
            currentSelection.object = object
            currentSelection.index = object.index
            if subSelectionIndex ~= nil then
                currentSelection.subIndex = subSelectionIndex
            end
            if currentSelection.subIndex > #object.subSelections then
                currentSelection.subIndex = 1
            end
            currentSelection.object.vehicle:selectVehicle(currentSelection.subIndex, ignoreActionEventUpdate)
            return true
        end
    else
        object = self:getSelectedObject()
        local found = false
        for _, o in ipairs(self.selectableObjects) do
            if o == object then
                found = true
            end
        end
        if not found then
            currentSelection.object = nil
            currentSelection.index = 1
            currentSelection.subIndex = 1
        end
    end
    return false
end
function Vehicle:getIsSelected()
    if self.selectionObject == nil then
        return false
    else
        return self.selectionObject.isSelected
    end
end
function Vehicle:getSelectedObject()
    local rootVehicle = self.rootVehicle
    if rootVehicle == self then
        return self.currentSelection.object
    else
        return rootVehicle:getSelectedObject()
    end
end
function Vehicle:getSelectedVehicle()
    local selectedObject = self:getSelectedObject()
    if selectedObject == nil then
        return nil
    else
        return selectedObject.vehicle
    end
end
function Vehicle:hasInputConflictWithSelection(_)
    printCallstack()
    Logging.xmlWarning(self.xmlFile, "Vehicle:hasInputConflictWithSelection() is deprecated!")
    return false
end
function Vehicle:setMassDirty()
    self.isMassDirty = true
end
function Vehicle:updateMass()
    self.serverMass = 0
    for k, component in ipairs(self.components) do
        if component.defaultMass == nil then
            if component.isDynamic then
                component.defaultMass = getMass(component.node)
            else
                component.defaultMass = 1
            end
            component.mass = component.defaultMass
        end
        local mass = self:getAdditionalComponentMass(component)
        if mass == math.huge then
            Logging.devError("%s: Additional component \'%d\' mass is inf!", self.configFileName, k)
        end
        component.mass = component.defaultMass + mass
        if component.mass == math.huge then
            Logging.devError("%s: Setting component \'%d\' mass to inf!", self.configFileName, k)
        end
        self.serverMass = self.serverMass + component.mass
    end
    local realTotalMass = 0
    for component, mass in ipairs(self.components) do
        realTotalMass = realTotalMass + self:getComponentMass(mass)
    end
    self.precalculatedMass = realTotalMass - self.serverMass
    for component, mass in ipairs(self.components) do
        local maxFactor = self.serverMass / (self.maxComponentMass - self.precalculatedMass)
        if maxFactor > 1 then
            mass.mass = mass.mass / maxFactor
            if mass.mass == math.huge then
                Logging.devError("%s: Scaling component \'%d\' mass to inf! MaxFactor %s | serverMass %s | maxComponentMass %s | precalculatedMass %s", self.configFileName, component, maxFactor, self.serverMass, self.maxComponentMass, self.precalculatedMass)
            end
        end
        if self.isServer and mass.isDynamic then
            if math.abs(mass.lastMass - mass.mass) > 0.02 then
                setMass(mass.node, mass.mass)
                mass.lastMass = mass.mass
            end
        end
    end
    local k = self.maxComponentMass - self.precalculatedMass
    self.serverMass = math.min(self.serverMass, k)
end
function Vehicle:getMaxComponentMassReached()
    return self.serverMass + 0.001 >= self.maxComponentMass - self.precalculatedMass
end
function Vehicle:getAvailableComponentMass()
    return math.max(self.maxComponentMass - self.precalculatedMass - self.serverMass, 0)
end
function Vehicle:getAdditionalComponentMass(component)
    return 0
end
function Vehicle:getTotalMass(_)
    local mass = 0
    for _, component in ipairs(self.components) do
        mass = mass + self:getComponentMass(component)
    end
    return mass
end
function Vehicle.getComponentMass(_, component)
    return component == nil and 0 or component.mass
end
function Vehicle:getDefaultMass()
    local mass = 0
    for _, component in ipairs(self.components) do

    end
    return mass
end
function Vehicle:getOverallCenterOfMass()
    local cx = 0
    local cy = 0
    local cz = 0
    local totalMass = self:getTotalMass(true)
    local i = 1
    for i = i, #self.components do
        local component = self.components[i]
        local ccx, ccy, ccz = localToWorld(component.node, getCenterOfMass(component.node))
        local percentage = self:getComponentMass(component) / totalMass
    end
    return cx, cy, cz
end
function Vehicle:getVehicleWorldXRot()
    local _, y, _ = localDirectionToWorld(self.components[1].node, 0, 0, 1)
    local slopeAngle = 1.5707963267948966 - math.atan(1 / y)
    if slopeAngle > 1.5707963267948966 then
    end
    return slopeAngle
end
function Vehicle:getVehicleWorldDirection()
    return localDirectionToWorld(self.components[1].node, 0, 0, 1)
end
function Vehicle:getFillLevelInformation(display) end
function Vehicle:getHasObjectMounted(object)
    return false
end
function Vehicle:activate()
    if self.actionController ~= nil then
        self.actionController:activate()
    end
    SpecializationUtil.raiseEvent(self, "onActivate")
end
function Vehicle:deactivate()
    if self.actionController ~= nil then
        self.actionController:deactivate()
    end
    SpecializationUtil.raiseEvent(self, "onDeactivate")
end
function Vehicle:setComponentJointFrame(jointDesc, anchorActor)
    if anchorActor == 0 then
        local localPoses = jointDesc.jointLocalPoses[1]
        localPoses.trans[1], localPoses.trans[2], localPoses.trans[3] = localToLocal(jointDesc.jointNode, self.components[jointDesc.componentIndices[1]].node, 0, 0, 0)
        localPoses.rot[1], localPoses.rot[2], localPoses.rot[3] = localRotationToLocal(jointDesc.jointNode, self.components[jointDesc.componentIndices[1]].node, 0, 0, 0)
    else
        local localPoses = jointDesc.jointLocalPoses[2]
        localPoses.trans[1], localPoses.trans[2], localPoses.trans[3] = localToLocal(jointDesc.jointNodeActor1, self.components[jointDesc.componentIndices[2]].node, 0, 0, 0)
        localPoses.rot[1], localPoses.rot[2], localPoses.rot[3] = localRotationToLocal(jointDesc.jointNodeActor1, self.components[jointDesc.componentIndices[2]].node, 0, 0, 0)
    end
    local localPoses = jointDesc.jointNode
    if anchorActor == 1 then
        localPoses = jointDesc.jointNodeActor1
    end
    if jointDesc.jointIndex ~= 0 then
        setJointFrame(jointDesc.jointIndex, anchorActor, localPoses)
    end
end
function Vehicle:setComponentJointRotLimit(componentJoint, axis, minLimit, maxLimit)
    if self.isServer then
        componentJoint.rotLimit[axis] = maxLimit
        componentJoint.rotMinLimit[axis] = minLimit
        if componentJoint.jointIndex ~= 0 then
            if minLimit <= maxLimit then
                setJointRotationLimit(componentJoint.jointIndex, axis - 1, true, minLimit, maxLimit)
                return
            end
            setJointRotationLimit(componentJoint.jointIndex, axis - 1, false, 0, 0)
        end
    end
end
function Vehicle:setComponentJointTransLimit(componentJoint, axis, minLimit, maxLimit)
    if self.isServer then
        componentJoint.transLimit[axis] = maxLimit
        componentJoint.transMinLimit[axis] = minLimit
        if componentJoint.jointIndex ~= 0 then
            if minLimit <= maxLimit then
                setJointTranslationLimit(componentJoint.jointIndex, axis - 1, true, minLimit, maxLimit)
                return
            end
            setJointTranslationLimit(componentJoint.jointIndex, axis - 1, false, 0, 0)
        end
    end
end
function Vehicle:loadComponentFromXML(component, xmlFile, key, rootPosition, i)
    if not self.isServer and getRigidBodyType(component.node) == RigidBodyType.DYNAMIC then
        setRigidBodyType(component.node, RigidBodyType.KINEMATIC)
    end
    if i == 1 then
        local x, y, z = getTranslation(component.node)
        rootPosition[1] = x
        rootPosition[2] = y
        rootPosition[3] = z
        if rootPosition[2] ~= 0 then
            Logging.xmlWarning(self.xmlFile, "Y-Translation of component 1 (node 0>) has to be 0. Current value is: %.5f", rootPosition[2])
        end
    end
    if getRigidBodyType(component.node) == RigidBodyType.STATIC then
        component.isStatic = true
    elseif getRigidBodyType(component.node) == RigidBodyType.KINEMATIC then
        component.isKinematic = true
    elseif getRigidBodyType(component.node) == RigidBodyType.DYNAMIC then
        component.isDynamic = true
    end
    if not CollisionFlag.getHasGroupFlagSet(component.node, CollisionFlag.VEHICLE) then
        Logging.xmlWarning(self.xmlFile, "Missing collision group mask %s. Please add this bit to component node \'%s\'", CollisionFlag.getBitAndName(CollisionFlag.VEHICLE), getName(component.node))
    end
    if not CollisionFlag.getHasMaskFlagSet(component.node, CollisionFlag.VEHICLE) then
        Logging.xmlWarning(self.xmlFile, "Missing collision filter mask %s. Please add this bit to component node \'%s\'", CollisionFlag.getBitAndName(CollisionFlag.VEHICLE), getName(component.node))
    end
    translate(component.node, -rootPosition[1], -rootPosition[2], -rootPosition[3])
    local x, y, z = getTranslation(component.node)
    local rx, ry, rz = getRotation(component.node)
    component.originalTranslation = { x, y, z }
    component.originalRotation = { rx, ry, rz }
    component.sentTranslation = { x, y, z }
    component.sentRotation = { rx, ry, rz }
    component.defaultMass = nil
    component.mass = nil
    local mass = xmlFile:getValue(key .. "#mass")
    if mass == nil then
        Logging.xmlWarning(self.xmlFile, "Missing \'mass\' for \'%s\'. Using default mass 500kg instead!", key)
        component.defaultMass = 0.5
        component.mass = 0.5
        component.lastMass = component.mass
    else
        if mass < 10 then
            Logging.xmlDevWarning(self.xmlFile, "Mass is lower than 10kg for \'%s\'. Mass unit is kilograms. Is this correct?", key)
        end
        if component.isDynamic then
            setMass(component.node, mass / 1000)
        end
        component.defaultMass = mass / 1000
        component.mass = component.defaultMass
        component.lastMass = component.mass
    end
    local comX, comY, comZ = xmlFile:getValue(key .. "#centerOfMass")
    if comX ~= nil then
        setCenterOfMass(component.node, comX, comY, comZ)
    end
    local inertiaScaleX, inertiaScaleY, inertiaScaleZ = xmlFile:getValue(key .. "#inertiaScale")
    if inertiaScaleX ~= nil then
        setInertiaScale(component.node, inertiaScaleX, inertiaScaleY, inertiaScaleZ)
    end
    local count = xmlFile:getValue(key .. "#solverIterationCount")
    if count ~= nil then
        setSolverIterationCount(component.node, count)
        component.solverIterationCount = count
    end
    component.motorized = xmlFile:getValue(key .. "#motorized")
    self.vehicleNodes[component.node] = {
        ["component"] = component
    }
    if getClipDistance(component.node) >= 1000000 and getVisibility(component.node) then
        Logging.xmlWarning(self.xmlFile, "No clipdistance is set to component node \'%s\' (%s>). Set default clipdistance \'%d\'", getName(component.node), i - 1, 300)
        setClipDistance(component.node, 300)
    end
    component.collideWithAttachables = xmlFile:getValue(key .. "#collideWithAttachables", false)
    if getRigidBodyType(component.node) ~= RigidBodyType.NONE then
        if getLinearDamping(component.node) > 0.01 then
            Logging.xmlDevWarning(self.xmlFile, "Non-zero linear damping (%.4f) for component node \'%s\' (%s>). Is this correct?", getLinearDamping(component.node), getName(component.node), i - 1)
        elseif getAngularDamping(component.node) > 0.05 then
            Logging.xmlDevWarning(self.xmlFile, "Large angular damping (%.4f) for component node \'%s\' (%s>). Is this correct?", getAngularDamping(component.node), getName(component.node), i - 1)
        elseif getAngularDamping(component.node) < 0.0001 then
            Logging.xmlDevWarning(self.xmlFile, "Zero damping for component node \'%s\' (%s>). Is this correct?", getName(component.node), i - 1)
        end
    end
    local defaultClipdistance = getName(component.node)
    if not defaultClipdistance:contains("_component") then
        Logging.xmlDevWarning(self.xmlFile, "Name of component \'%d\' (\'%s\') does not correspond with the component naming convention! (vehicleName_componentName_component%d)", i, defaultClipdistance, i)
    end
    g_currentMission:addNodeObject(component.node, self)
    return true
end
function Vehicle:loadComponentJointFromXML(jointDesc, xmlFile, key, componentJointI, jointNode, index1, index2)
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#indexActor1", key .. "#nodeActor1")
    jointDesc.componentIndices = { index1, index2 }
    jointDesc.jointNode = jointNode
    jointDesc.jointNodeActor1 = xmlFile:getValue(key .. "#nodeActor1", jointNode, self.components, self.i3dMappings)
    if self.isServer then
        if self.components[index1] == nil or self.components[index2] == nil then
            Logging.xmlWarning(self.xmlFile, "Invalid component indices (component1: %d, component2: %d) for component joint %d. Indices start with 1!", index1, index2, componentJointI)
            return false
        end
        local x, y, z = xmlFile:getValue(key .. "#rotLimit")
        local rotLimits = {}
        local rotMinLimits = Utils.getNoNil(x, 0)
        local transLimits = math.rad(rotMinLimits)
        local transMinLimits = Utils.getNoNil(y, 0)
        local rotMinLimits = math.rad(transMinLimits)
        __set_list(rotLimits, 1, {transLimits, rotMinLimits, (math.rad((Utils.getNoNil(z, 0))))})
        local transLimits, rotMinLimits, transMinLimits = xmlFile:getValue(key .. "#transLimit")
        local transLimits = { Utils.getNoNil(transLimits, 0), Utils.getNoNil(rotMinLimits, 0), Utils.getNoNil(transMinLimits, 0) }
        jointDesc.rotLimit = rotLimits
        jointDesc.transLimit = transLimits
        local rotMinLimits, transMinLimits, trans = xmlFile:getValue(key .. "#rotMinLimit")
        local rotMinLimits = { Utils.getNoNilRad(rotMinLimits, nil), Utils.getNoNilRad(transMinLimits, nil), Utils.getNoNilRad(trans, nil) }
        local transMinLimits, trans, rot = xmlFile:getValue(key .. "#transMinLimit")
        local transMinLimits = { transMinLimits, trans, rot }
        local i = 1
        for i = i, 3 do
            if rotMinLimits[i] == nil then
                if rotLimits[i] >= 0 then
                    rotMinLimits[i] = -rotLimits[i]
                else
                    rotMinLimits[i] = rotLimits[i] + 1
                end
            end
            if transMinLimits[i] == nil then
                if transLimits[i] >= 0 then
                    transMinLimits[i] = -transLimits[i]
                else
                    transMinLimits[i] = transLimits[i] + 1
                end
            end
        end
        jointDesc.jointLocalPoses = {}
        local rotLimitDamping = {
            ["trans"] = { localToLocal(jointDesc.jointNode, self.components[index1].node, 0, 0, 0) },
            ["rot"] = { localRotationToLocal(jointDesc.jointNode, self.components[index1].node, 0, 0, 0) }
        }
        jointDesc.jointLocalPoses[1] = rotLimitDamping
        local rotLimitDamping = {
            ["trans"] = { localToLocal(jointDesc.jointNodeActor1, self.components[index2].node, 0, 0, 0) },
            ["rot"] = { localRotationToLocal(jointDesc.jointNodeActor1, self.components[index2].node, 0, 0, 0) }
        }
        jointDesc.jointLocalPoses[2] = rotLimitDamping
        jointDesc.rotMinLimit = rotMinLimits
        jointDesc.transMinLimit = transMinLimits
        local i, rotLimitDamping, rotLimitForceLimit = xmlFile:getValue(key .. "#rotLimitSpring")
        local i = { Utils.getNoNil(i, 0), Utils.getNoNil(rotLimitDamping, 0), Utils.getNoNil(rotLimitForceLimit, 0) }
        local rotLimitDamping, rotLimitForceLimit, transLimitForceLimit = xmlFile:getValue(key .. "#rotLimitDamping")
        local rotLimitDamping = { Utils.getNoNil(rotLimitDamping, 1), Utils.getNoNil(rotLimitForceLimit, 1), Utils.getNoNil(transLimitForceLimit, 1) }
        jointDesc.rotLimitSpring = i
        jointDesc.rotLimitDamping = rotLimitDamping
        local rotLimitForceLimit, transLimitForceLimit, transLimitSpring = xmlFile:getValue(key .. "#rotLimitForceLimit")
        local rotLimitForceLimit = { Utils.getNoNil(rotLimitForceLimit, -1), Utils.getNoNil(transLimitForceLimit, -1), Utils.getNoNil(transLimitSpring, -1) }
        local transLimitForceLimit, transLimitSpring, transLimitDamping = xmlFile:getValue(key .. "#transLimitForceLimit")
        local transLimitForceLimit = { Utils.getNoNil(transLimitForceLimit, -1), Utils.getNoNil(transLimitSpring, -1), Utils.getNoNil(transLimitDamping, -1) }
        jointDesc.rotLimitForceLimit = rotLimitForceLimit
        jointDesc.transLimitForceLimit = transLimitForceLimit
        local transLimitSpring, transLimitDamping, zRotationNode = xmlFile:getValue(key .. "#transLimitSpring")
        local transLimitSpring = { Utils.getNoNil(transLimitSpring, 0), Utils.getNoNil(transLimitDamping, 0), Utils.getNoNil(zRotationNode, 0) }
        local transLimitDamping, zRotationNode, yOffset = xmlFile:getValue(key .. "#transLimitDamping")
        local transLimitDamping = { Utils.getNoNil(transLimitDamping, 1), Utils.getNoNil(zRotationNode, 1), Utils.getNoNil(yOffset, 1) }
        jointDesc.transLimitSpring = transLimitSpring
        jointDesc.transLimitDamping = transLimitDamping
        jointDesc.zRotationXOffset = 0
        local zRotationNode = xmlFile:getValue(key .. "#zRotationNode", nil, self.components, self.i3dMappings)
        if zRotationNode ~= nil then
            local rotDriveRotation, rotDriveSpring, rotDriveDamping = localToLocal(zRotationNode, jointNode, 0, 0, 0)
            jointDesc.zRotationXOffset = rotDriveRotation
            if math.abs(rotDriveSpring) > 0.01 or math.abs(rotDriveDamping) > 0.01 then
                Logging.xmlWarning(self.xmlFile, "ComponentJoint zRotationNode \'%s\' is not correctly aligned with joint node \'%s\'. Offset is: y %.3f, z %.3f. Make sure the zRotationNode has only a translation offset on the X axis.", getName(zRotationNode), getName(jointNode), rotDriveSpring, rotDriveDamping)
            end
        end
        jointDesc.isBreakable = xmlFile:getValue(key .. "#breakable", false)
        if jointDesc.isBreakable then
            jointDesc.breakForce = xmlFile:getValue(key .. "#breakForce", 10)
            jointDesc.breakTorque = xmlFile:getValue(key .. "#breakTorque", 10)
        end
        jointDesc.enableCollision = xmlFile:getValue(key .. "#enableCollision", false)
        local yOffset, zOffset, rotDriveRotation = xmlFile:getValue(key .. "#maxRotDriveForce")
        local yOffset = { Utils.getNoNil(yOffset, 0), Utils.getNoNil(zOffset, 0), Utils.getNoNil(rotDriveRotation, 0) }
        local zOffset, rotDriveRotation, rotDriveSpring = xmlFile:getValue(key .. "#rotDriveVelocity")
        local zOffset = { Utils.getNoNilRad(zOffset, nil), Utils.getNoNilRad(rotDriveRotation, nil), Utils.getNoNilRad(rotDriveSpring, nil) }
        local rotDriveRotation, rotDriveSpring, rotDriveDamping = xmlFile:getValue(key .. "#rotDriveRotation")
        local rotDriveRotation = { Utils.getNoNilRad(rotDriveRotation, nil), Utils.getNoNilRad(rotDriveSpring, nil), Utils.getNoNilRad(rotDriveDamping, nil) }
        local rotDriveSpring, rotDriveDamping, maxTransDriveForce = xmlFile:getValue(key .. "#rotDriveSpring")
        local rotDriveSpring = { Utils.getNoNil(rotDriveSpring, 0), Utils.getNoNil(rotDriveDamping, 0), Utils.getNoNil(maxTransDriveForce, 0) }
        local rotDriveDamping, maxTransDriveForce, transDriveVelocity = xmlFile:getValue(key .. "#rotDriveDamping")
        local rotDriveDamping = { Utils.getNoNil(rotDriveDamping, 0), Utils.getNoNil(maxTransDriveForce, 0), Utils.getNoNil(transDriveVelocity, 0) }
        jointDesc.rotDriveVelocity = zOffset
        jointDesc.rotDriveRotation = rotDriveRotation
        jointDesc.rotDriveSpring = rotDriveSpring
        jointDesc.rotDriveDamping = rotDriveDamping
        jointDesc.maxRotDriveForce = yOffset
        local maxTransDriveForce, transDriveVelocity, transDrivePosition = xmlFile:getValue(key .. "#maxTransDriveForce")
        local maxTransDriveForce = { Utils.getNoNil(maxTransDriveForce, 0), Utils.getNoNil(transDriveVelocity, 0), Utils.getNoNil(transDrivePosition, 0) }
        local transDriveVelocity, transDrivePosition, transDriveSpring = xmlFile:getValue(key .. "#transDriveVelocity")
        local transDrivePosition, transDriveSpring, transDriveDamping = xmlFile:getValue(key .. "#transDrivePosition")
        local transDriveSpring, transDriveDamping, z = xmlFile:getValue(key .. "#transDriveSpring")
        local transDriveSpring = { Utils.getNoNil(transDriveSpring, 0), Utils.getNoNil(transDriveDamping, 0), Utils.getNoNil(z, 0) }
        local transDriveDamping, y, z = xmlFile:getValue(key .. "#transDriveDamping")
        local transDriveDamping = { Utils.getNoNil(transDriveDamping, 1), Utils.getNoNil(y, 1), Utils.getNoNil(z, 1) }
        jointDesc.transDriveVelocity = { transDriveVelocity, transDrivePosition, transDriveSpring }
        jointDesc.transDrivePosition = { transDrivePosition, transDriveSpring, transDriveDamping }
        jointDesc.transDriveSpring = transDriveSpring
        jointDesc.transDriveDamping = transDriveDamping
        jointDesc.maxTransDriveForce = maxTransDriveForce
        jointDesc.initComponentPosition = xmlFile:getValue(key .. "#initComponentPosition", true)
        jointDesc.jointIndex = 0
    end
    return true
end
function Vehicle:createComponentJoint(component1, component2, jointDesc)
    if component1 == nil or (component2 == nil or jointDesc == nil) then
        Logging.xmlWarning(self.xmlFile, "Could not create component joint. No component1, component2 or jointDesc given!")
        return false
    end
    local constr = JointConstructor.new()
    constr:setActors(component1.node, component2.node)
    local localPoses1 = jointDesc.jointLocalPoses[1]
    local localPoses2 = jointDesc.jointLocalPoses[2]
    constr:setJointLocalPositions(localPoses1.trans[1], localPoses1.trans[2], localPoses1.trans[3], localPoses2.trans[1], localPoses2.trans[2], localPoses2.trans[3])
    constr:setJointLocalRotations(localPoses1.rot[1], localPoses1.rot[2], localPoses1.rot[3], localPoses2.rot[1], localPoses2.rot[2], localPoses2.rot[3])
    constr:setRotationLimitSpring(jointDesc.rotLimitSpring[1], jointDesc.rotLimitDamping[1], jointDesc.rotLimitSpring[2], jointDesc.rotLimitDamping[2], jointDesc.rotLimitSpring[3], jointDesc.rotLimitDamping[3])
    constr:setTranslationLimitSpring(jointDesc.transLimitSpring[1], jointDesc.transLimitDamping[1], jointDesc.transLimitSpring[2], jointDesc.transLimitDamping[2], jointDesc.transLimitSpring[3], jointDesc.transLimitDamping[3])
    constr:setZRotationXOffset(jointDesc.zRotationXOffset)
    local i = 1
    for i = i, 3 do
        if jointDesc.rotLimit[i] >= jointDesc.rotMinLimit[i] then
            constr:setRotationLimit(i - 1, jointDesc.rotMinLimit[i], jointDesc.rotLimit[i])
        end
        if jointDesc.transLimit[i] >= jointDesc.transMinLimit[i] then
            constr:setTranslationLimit(i - 1, true, jointDesc.transMinLimit[i], jointDesc.transLimit[i])
        else
            constr:setTranslationLimit(i - 1, false, 0, 0)
        end
    end
    constr:setRotationLimitForceLimit(jointDesc.rotLimitForceLimit[1], jointDesc.rotLimitForceLimit[2], jointDesc.rotLimitForceLimit[3])
    constr:setTranslationLimitForceLimit(jointDesc.transLimitForceLimit[1], jointDesc.transLimitForceLimit[2], jointDesc.transLimitForceLimit[3])
    if jointDesc.isBreakable then
        constr:setBreakable(jointDesc.breakForce, jointDesc.breakTorque)
    end
    constr:setEnableCollision(jointDesc.enableCollision)
    local i = 1
    for i = i, 3 do
        if jointDesc.maxRotDriveForce[i] > 0.0001 and (jointDesc.rotDriveVelocity[i] ~= nil or jointDesc.rotDriveRotation[i] ~= nil) then
            local pos = Utils.getNoNil(jointDesc.rotDriveRotation[i], 0)
            local vel = Utils.getNoNil(jointDesc.rotDriveVelocity[i], 0)
            constr:setAngularDrive(i - 1, jointDesc.rotDriveRotation[i] ~= nil, jointDesc.rotDriveVelocity[i] ~= nil, jointDesc.rotDriveSpring[i], jointDesc.rotDriveDamping[i], jointDesc.maxRotDriveForce[i], pos, vel)
        end
        if jointDesc.maxTransDriveForce[i] > 0.0001 and (jointDesc.transDriveVelocity[i] ~= nil or jointDesc.transDrivePosition[i] ~= nil) then
            local pos = Utils.getNoNil(jointDesc.transDrivePosition[i], 0)
            local vel = Utils.getNoNil(jointDesc.transDriveVelocity[i], 0)
            constr:setLinearDrive(i - 1, jointDesc.transDrivePosition[i] ~= nil, jointDesc.transDriveVelocity[i] ~= nil, jointDesc.transDriveSpring[i], jointDesc.transDriveDamping[i], jointDesc.maxTransDriveForce[i], pos, vel)
        end
    end
    jointDesc.jointIndex = constr:finalize()
    return true
end
function Vehicle.prefixSchemaOverlayName(baseName, prefix)
    if baseName ~= "" and not VehicleSchemaOverlayData.SCHEMA_OVERLAY[baseName] then
    end
    return baseName
end
function Vehicle:loadSchemaOverlay(xmlFile)
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#file")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#width")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#height")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#invisibleBorderRight", "vehicle.base.schemaOverlay#invisibleBorderRight")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#invisibleBorderLeft", "vehicle.base.schemaOverlay#invisibleBorderLeft")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#attacherJointPosition", "vehicle.base.schemaOverlay#attacherJointPosition")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#basePosition", "vehicle.base.schemaOverlay#basePosition")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#fileSelected")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#fileTurnedOn")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#fileSelectedTurnedOn")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.base.schemaOverlay.default#name", "vehicle.base.schemaOverlay#name")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.base.schemaOverlay.turnedOn#name")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.base.schemaOverlay.selected#name")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.base.schemaOverlay.turnedOnSelected#name")
    if xmlFile:hasProperty("vehicle.base.schemaOverlay") then
        XMLUtil.checkDeprecatedXMLElements(xmlFile, "vehicle.schemaOverlay.attacherJoint", "vehicle.attacherJoints.attacherJoint.schema")
        local x, y = xmlFile:getValue("vehicle.base.schemaOverlay#attacherJointPosition")
        local baseX, baseY = xmlFile:getValue("vehicle.base.schemaOverlay#basePosition")
        if baseX ~= nil then
            x = baseX
        end
        if baseY ~= nil then
            y = baseY
        end
        local schemaName = xmlFile:getValue("vehicle.base.schemaOverlay#name", "")
        local schemaName = Vehicle.prefixSchemaOverlayName(schemaName, self.customEnvironment or "")
        self.schemaOverlay = VehicleSchemaOverlayData.new(x, y, schemaName, xmlFile:getValue("vehicle.base.schemaOverlay#invisibleBorderRight"), xmlFile:getValue("vehicle.base.schemaOverlay#invisibleBorderLeft"))
    end
end
function Vehicle:getAdditionalSchemaText()
    return nil
end
function Vehicle:getUseTurnedOnSchema()
    return false
end
function Vehicle:dayChanged() end
function Vehicle:periodChanged()
    self.age = self.age + 1
end
function Vehicle:raiseStateChange(state, ...)
    SpecializationUtil.raiseEvent(self, "onStateChange", state, ...)
end
function Vehicle:doCheckSpeedLimit()
    return false
end
function Vehicle:getWorkLoad()
    return 0, 0
end
function Vehicle:interact(player) end
function Vehicle:getInteractionHelp()
    return ""
end
function Vehicle:getIsInteractive()
    return not self.isBroken
end
function Vehicle:getDistanceToNode(_)
    self.interactionFlag = Vehicle.INTERACTION_FLAG_NONE
    return math.huge
end
function Vehicle:getIsAIActive()
    if self.getAttacherVehicle ~= nil then
        local attacherVehicle = self:getAttacherVehicle()
        if attacherVehicle ~= nil then
            return attacherVehicle:getIsAIActive()
        end
    end
    return false
end
function Vehicle:getIsPowered()
    return true
end
function Vehicle:getRequiresPower()
    return false
end
function Vehicle:getIsInShowroom()
    return self.propertyState == VehiclePropertyState.SHOP_CONFIG
end
function Vehicle:addVehicleToAIImplementList(list) end
function Vehicle:setOperatingTime(operatingTime, isLoading)
    if not isLoading and (self.propertyState == VehiclePropertyState.LEASED and (g_currentMission ~= nil and g_currentMission.economyManager ~= nil)) then
        if math.floor(self.operatingTime / 3600000) < math.floor(operatingTime / 3600000) then
            g_currentMission.economyManager:vehicleOperatingHourChanged(self)
        end
    end
    self.operatingTime = math.max(operatingTime or 0, 0)
end
function Vehicle:getOperatingTime()
    return self.operatingTime
end
function Vehicle:doCollisionMaskCheck(targetCollisionMask, path, node, str)
    local ignoreCheck = false
    if path ~= nil then
        ignoreCheck = self.xmlFile:getValue(path, false)
    end
    if not ignoreCheck then
        local hasMask = false
        if node == nil then
            for _, component in ipairs(self.components) do
                if not hasMask then
                    hasMask = bit32.band(getCollisionFilterMask(component.node), targetCollisionMask) == targetCollisionMask
                end
            end
        elseif not hasMask then
            hasMask = bit32.band(getCollisionFilterMask(node), targetCollisionMask) == targetCollisionMask
        end
        if not hasMask then
            printCallstack()
            Logging.xmlWarning(self.xmlFile, "%s has wrong collision mask! Following bit(s) need to be set \'%s\' or use \'%s\'", str or self.typeName, MathUtil.numberToSetBitsStr(targetCollisionMask), path)
            return false
        end
    end
    return true
end
function Vehicle:getIsReadyForAutomatedTrainTravel()
    return true
end
function Vehicle:getIsAutomaticShiftingAllowed()
    return true
end
function Vehicle:getSpeedLimit(onlyIfWorking)
    local limit = math.huge
    local doCheckSpeedLimit = self:doCheckSpeedLimit()
    if onlyIfWorking == nil or onlyIfWorking and doCheckSpeedLimit then
        limit = self:getRawSpeedLimit()
        local damage = self:getVehicleDamage()
        if damage > 0 then
        end
    end
    local damage = nil
    if self.getAttachedImplements ~= nil then
        damage = self:getAttachedImplements()
    end
    if damage ~= nil then
        for _, implement in pairs(damage) do
            if implement.object ~= nil then
                local speed, implementDoCheckSpeedLimit = implement.object:getSpeedLimit(onlyIfWorking)
                if onlyIfWorking == nil or onlyIfWorking and implementDoCheckSpeedLimit then
                    limit = math.min(limit, speed)
                end
            end
        end
    end
    return limit, doCheckSpeedLimit
end
function Vehicle:getRawSpeedLimit()
    return self.speedLimit
end
function Vehicle:onVehicleWakeUpCallback(_)
    self:raiseActive()
end
function Vehicle:getCanBeMounted()
    return entityExists(self.components[1].node)
end
function Vehicle:getDailyUpkeep()
    local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
    return Vehicle.calculateDailyUpkeep(storeItem, self.age, self.operatingTime, self.configurations)
end
function Vehicle.calculateDailyUpkeep(storeItem, age, operatingTime, configurations)
    local multiplier = 1
    if storeItem.lifetime ~= nil and storeItem.lifetime ~= 0 then
        local ageMultiplier = 0.3 * math.min(age / storeItem.lifetime, 1)
        local operatingTimeMultiplier = 0.7 * math.min(operatingTime / 3600000 / (storeItem.lifetime * EconomyManager.LIFETIME_OPERATINGTIME_RATIO), 1)
        multiplier = 1 + EconomyManager.MAX_DAILYUPKEEP_MULTIPLIER * (ageMultiplier + operatingTimeMultiplier)
    end
    return StoreItemUtil.getDailyUpkeep(storeItem, configurations) * multiplier
end
function Vehicle:getUppercaseName()
    local name = self:getFullName()
    return utf8ToUpper(name)
end
function Vehicle:getName()
    local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
    if storeItem == nil then
        return "Unknown"
    end
    if storeItem.configurations ~= nil then
        for configName, _ in pairs(storeItem.configurations) do
            local config = storeItem.configurations[configName][self.configurations[configName]]
            if config.vehicleName ~= nil and config.vehicleName ~= "" then
                return config.vehicleName
            end
        end
    end
    return storeItem.name
end
function Vehicle:getFullName()
    local name = self:getName()
    if g_storeManager:getItemByXMLFilename(self.configFileName) ~= nil then
        local brand = g_brandManager:getBrandByIndex(self:getBrand())
        if brand ~= nil and brand.name ~= "NONE" then
        end
    end
    return name
end
function Vehicle:getBrand()
    local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
    if storeItem == nil then
        return Brand.LIZARD
    end
    if storeItem.configurations ~= nil then
        for configName, _ in pairs(storeItem.configurations) do
            local config = storeItem.configurations[configName][self.configurations[configName]]
            if config.vehicleBrand ~= nil then
                return config.vehicleBrand
            end
        end
    end
    return storeItem.brandIndex
end
function Vehicle:getImageFilename()
    local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
    if storeItem == nil then
        return ShopController.EMPTY_FILENAME
    end
    if storeItem.configurations ~= nil then
        for configName, _ in pairs(storeItem.configurations) do
            local configId = self.configurations[configName]
            local config = storeItem.configurations[configName][configId]
            if config == nil then
                Logging.xmlWarning(self.xmlFile, "Vehicle has an invalid configuration value %s for %s", configId, configName)
            elseif config.vehicleIcon ~= nil and config.vehicleIcon ~= "" then
                return config.vehicleIcon
            end
        end
    end
    return storeItem.imageFilename
end
function Vehicle:getCanBePickedUp(byPlayer)
    return self.supportsPickUp and g_currentMission.accessHandler:canPlayerAccess(self, byPlayer)
end
function Vehicle:getCanBeReset()
    return self.canBeReset and not g_guidedTourManager:getIsTourRunning()
end
function Vehicle:getResetPlaces()
    return g_currentMission:getResetPlaces(), g_currentMission.usedLoadPlaces
end
function Vehicle:getCanBeSold()
    local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
    return storeItem == nil and true or storeItem.canBeSold
end
function Vehicle:getCanBeAddedToSales()
    return true
end
function Vehicle:getReloadXML()
    local vehicleXMLFile = XMLFile.create("vehicleXMLFile", "", "vehicles", Vehicle.xmlSchemaSavegame)
    if vehicleXMLFile == nil then
        return nil
    end
    local key = string.format("vehicles.vehicle(%d)", 0)
    vehicleXMLFile:setValue(key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.configFileName)))
    self:saveToXMLFile(vehicleXMLFile, key, {})
    return vehicleXMLFile
end
function Vehicle:getIsInUse(connection)
    return false
end
function Vehicle:getPropertyState()
    return self.propertyState
end
function Vehicle:getAreControlledActionsAvailable()
    if self:getIsAIActive() then
        return false
    elseif self.actionController == nil then
        return false
    else
        return self.actionController:getAreControlledActionsAvailable()
    end
end
function Vehicle:getAreControlledActionsAccessible()
    if self:getIsAIActive() then
        return false
    elseif self.actionController == nil then
        return false
    else
        return self.actionController:getAreControlledActionsAccessible()
    end
end
function Vehicle:getControlledActionIcons()
    if self.actionController ~= nil then
        local iconPos, iconNeg, changeColor = self.actionController:getControlledActionIcons()
        if iconPos ~= nil then
            return iconPos, iconNeg, changeColor
        end
    end
    return "TURN_ON", "TURN_ON", true
end
function Vehicle:getAreControlledActionsAllowed()
    return not self:getIsAIActive(), ""
end
function Vehicle:playControlledActions()
    if self.actionController ~= nil then
        self.actionController:playControlledActions()
    end
end
function Vehicle:getActionControllerDirection()
    return self.actionController == nil and 1 or self.actionController:getActionControllerDirection()
end
function Vehicle:createMapHotspot()
    local mapHotspot = VehicleHotspot.new()
    mapHotspot:setVehicle(self)
    mapHotspot:setVehicleType(self.mapHotspotType)
    mapHotspot:setOwnerFarmId(self:getOwnerFarmId())
    self.mapHotspot = mapHotspot
    g_currentMission:addMapHotspot(mapHotspot)
end
function Vehicle:deleteMapHotspot()
    if self.mapHotspot ~= nil then
        g_currentMission:removeMapHotspot(self.mapHotspot)
        self.mapHotspot:delete()
        self.mapHotspot = nil
    end
end
function Vehicle:getMapHotspot()
    return self.mapHotspot
end
function Vehicle:updateMapHotspot()
    if self.mapHotspot ~= nil then
        self.mapHotspot:setVisible(self:getIsMapHotspotVisible())
    end
end
function Vehicle:getIsMapHotspotVisible()
    return true
end
function Vehicle:getMapHotspotRotation(_)
    local dx, _, dz = localDirectionToWorld(self.directionReferenceNode or self.rootNode, 0, 0, 1)
    return MathUtil.getYRotationFromDirection(dx, dz) + 3.141592653589793
end
function Vehicle:getMapHotspotPosition()
    return getWorldTranslation(self.rootNode)
end
function Vehicle:getShowInVehiclesOverview()
    return self.showInVehicleOverview and (self.propertyState == VehiclePropertyState.OWNED or self.propertyState == VehiclePropertyState.LEASED)
end
function Vehicle:showInfo(box)
    if self.isBroken then
        box:addLine(g_i18n:getText("infohud_vehicleBrokenNeedToReset"), nil, true)
    end
end
function Vehicle:loadObjectChangeValuesFromXML(xmlFile, key, node, object) end
function Vehicle:setObjectChangeValues(object, isActive) end
function Vehicle:wakeUp()
    I3DUtil.wakeUpObject(self.components[1].node)
end
function Vehicle:register(alreadySent)
    Vehicle:superClass().register(self, alreadySent)
    SpecializationUtil.raiseEvent(self, "onRegistered", alreadySent)
end
function Vehicle:clearDirtyMask()
    self.dirtyMask = 0
    SpecializationUtil.raiseEvent(self, "onDirtyMaskCleared")
end
function Vehicle:setOwnerFarmId(farmId, noEventSend)
    Vehicle:superClass().setOwnerFarmId(self, farmId, noEventSend)
    if self.mapHotspot ~= nil then
        self.mapHotspot:setOwnerFarmId(farmId)
    end
end
function Vehicle:getUniqueId()
    return self.uniqueId
end
function Vehicle:setUniqueId(uniqueId)
    self.uniqueId = uniqueId
end
function Vehicle:actionEventToggleSelection(_, _, _, _)
    local currentSelection = self.currentSelection
    local currentObject = currentSelection.object
    local currentObjectIndex = currentSelection.index
    local currentSubObjectIndex = currentSelection.subIndex
    local newSelectedSubObjectIndex = currentSubObjectIndex + 1
    local newSelectedObjectIndex, newSelectedObject
    if (currentObject ~= nil and #currentObject.subSelections or 0) < newSelectedSubObjectIndex then
        newSelectedSubObjectIndex = 1
        newSelectedObject = self.selectableObjects[#self.selectableObjects < currentObjectIndex + 1 and 1 or currentObjectIndex + 1]
    else
        newSelectedObjectIndex = currentObjectIndex
        newSelectedObject = currentObject
    end
    if currentObject ~= newSelectedObject or (currentObjectIndex ~= newSelectedObjectIndex or currentSubObjectIndex ~= newSelectedSubObjectIndex) then
        self:setSelectedObject(newSelectedObject, newSelectedSubObjectIndex)
    end
end
function Vehicle:actionEventToggleSelectionReverse(_, _, _, _)
    local currentSelection = self.currentSelection
    local currentObject = currentSelection.object
    local currentObjectIndex = currentSelection.index
    local currentSubObjectIndex = currentSelection.subIndex
    local newSelectedSubObjectIndex = currentSubObjectIndex - 1
    local newSelectedObjectIndex, newSelectedObject
    if newSelectedSubObjectIndex < 1 then
        newSelectedSubObjectIndex = 1
        newSelectedObject = self.selectableObjects[currentObjectIndex - 1 < 1 and #self.selectableObjects or currentObjectIndex - 1]
        if newSelectedObject ~= nil then
            newSelectedSubObjectIndex = #newSelectedObject.subSelections
        end
    else
        newSelectedObjectIndex = currentObjectIndex
        newSelectedObject = currentObject
    end
    if currentObject ~= newSelectedObject or (currentObjectIndex ~= newSelectedObjectIndex or currentSubObjectIndex ~= newSelectedSubObjectIndex) then
        self:setSelectedObject(newSelectedObject, newSelectedSubObjectIndex)
    end
end
function Vehicle.getSpecValueAge(_, realItem, _, saleItem)
    if realItem == nil or realItem.age == nil then
        if saleItem == nil or saleItem.age == nil then
            return nil
        else
            return g_i18n:formatNumMonth(saleItem.age)
        end
    else
        return g_i18n:formatNumMonth(realItem.age)
    end
end
function Vehicle.getSpecValueDailyUpkeep(storeItem, realItem, _, saleItem)
    local dailyUpkeep = storeItem.dailyUpkeep
    local dailyUpkeep
    if realItem == nil or realItem.getDailyUpkeep == nil then
    else
        dailyUpkeep = realItem:getDailyUpkeep()
    end
    if dailyUpkeep == 0 then
        return nil
    else
        return string.format(g_i18n:getText("shop_maintenanceValue"), g_i18n:formatMoney(dailyUpkeep, 2))
    end
end
function Vehicle.getSpecValueOperatingTime(_, realItem, _, saleItem)
    local operatingTime
    if realItem == nil or realItem.operatingTime == nil then
        if saleItem == nil then
            return nil
        end
        operatingTime = saleItem.operatingTime
    else
        operatingTime = realItem.operatingTime
    end
    local minutes = operatingTime / 60000
    local hours = math.floor(minutes / 60)
    local minutes = math.floor((minutes - hours * 60) / 6)
    return string.format(g_i18n:getText("shop_operatingTime"), hours, minutes)
end
function Vehicle.loadSpecValueWorkingWidth(xmlFile, _, _)
    local width = xmlFile:getValue("vehicle.storeData.specs.workingWidth")
    return width ~= nil and {
        ["width"] = width,
        ["minWidth"] = xmlFile:getValue("vehicle.storeData.specs.workingWidth#minWidth", width)
    } or nil
end
function Vehicle.getSpecValueWorkingWidth(storeItem, _)
    if storeItem.specs.workingWidth == nil then
        return nil
    else
        local workingWidth = storeItem.specs.workingWidth
        if workingWidth.minWidth == workingWidth.width then
            return string.format(g_i18n:getText("shop_workingWidthValue"), g_i18n:formatNumber(workingWidth.width, 1, true))
        else
            return string.format(g_i18n:getText("shop_workingWidthValue"), string.format("%s-%s", g_i18n:formatNumber(workingWidth.minWidth, 1, true), g_i18n:formatNumber(workingWidth.width, 1, true)))
        end
    end
end
function Vehicle.loadSpecValueWorkingWidthConfig(xmlFile, _, _)
    local workingWidths = nil
    for name, configDesc in pairs(g_vehicleConfigurationManager:getConfigurations()) do
        for configurationIndex, configurationKey in xmlFile:iterator(configDesc.configurationKey) do
            local workingWidth = xmlFile:getValue(configurationKey .. "#workingWidth")
            if workingWidth ~= nil then
                workingWidths = workingWidths or {}
                workingWidths[name] = workingWidths[name] or {}
                workingWidths[name][configurationIndex] = {
                    ["width"] = workingWidth,
                    ["isSelectable"] = xmlFile:getValue(configurationKey .. "#isSelectable", true)
                }
            end
        end
    end
    return workingWidths
end
function Vehicle.getSpecValueWorkingWidthConfig(storeItem, realItem, configurations, saleItem, returnValues, _)
    if storeItem.specs.workingWidthConfig == nil then
        return nil
    else
        local minWorkingWidth = 0
        local workingWidth = 0
        if configurations == nil or realItem == nil and saleItem == nil then
            minWorkingWidth = math.huge
            workingWidth = 0
            for configData, configs in pairs(storeItem.specs.workingWidthConfig) do
                for _, configData in pairs(configs) do
                    if configData.isSelectable then
                        minWorkingWidth = math.min(minWorkingWidth, configData.width)
                        workingWidth = math.max(workingWidth, configData.width)
                    end
                end
            end
        else
            for configName, config in pairs(configurations) do
                if storeItem.specs.workingWidthConfig[configName] ~= nil then
                    local configData = storeItem.specs.workingWidthConfig[configName][config]
                    if configData ~= nil then
                        workingWidth = configData.width
                    end
                end
            end
        end
        if returnValues then
            return workingWidth
        elseif minWorkingWidth == 0 or (minWorkingWidth == math.huge or minWorkingWidth == workingWidth) then
            return string.format(g_i18n:getText("shop_workingWidthValue"), g_i18n:formatNumber(workingWidth, 1, true))
        else
            return string.format(g_i18n:getText("shop_workingWidthValue"), string.format("%s-%s", g_i18n:formatNumber(minWorkingWidth, 1, true), g_i18n:formatNumber(workingWidth, 1, true)))
        end
    end
end
function Vehicle.loadSpecValueSpeedLimit(xmlFile, _, _)
    return xmlFile:getValue("vehicle.base.speedLimit#value")
end
function Vehicle.getSpecValueSpeedLimit(storeItem, _)
    if storeItem.specs.speedLimit == nil then
        return nil
    else
        return string.format(g_i18n:getText("shop_maxSpeed"), string.format("%1d", g_i18n:getSpeed(storeItem.specs.speedLimit)), g_i18n:getSpeedMeasuringUnit())
    end
end
function Vehicle.loadSpecValueWeight(xmlFile, customEnvironment, baseDir)
    local massData = {
        ["componentMass"] = 0
    }
    for _, key in xmlFile:iterator("vehicle.base.components.component") do
        local mass = xmlFile:getValue(key .. "#mass", 0) / 1000
        massData.componentMass = massData.componentMass + mass
    end
    local hasConfigMass = false
    massData.configurations = {}
    for key, mass in xmlFile:iterator("vehicle.base.componentConfigurations.componentConfiguration") do
        local configMass = 0
        for _, componentKey in xmlFile:iterator(mass .. ".component") do
            configMass = configMass + xmlFile:getValue(componentKey .. "#mass", 0) / 1000
            hasConfigMass = true
        end
        massData.configurations[key] = configMass
    end
    massData.fillUnitMassData = FillUnit.loadSpecValueFillUnitMassData(xmlFile, customEnvironment, baseDir)
    massData.wheelMassDefaultConfig = Wheels.loadSpecValueWheelWeight(xmlFile, customEnvironment, baseDir)
    local configMin = nil
    local configMax = nil
    massData.storeDataConfigs = {}
    for configMass, key in xmlFile:iterator("vehicle.storeData.specs.weight.config") do
        local config = {
            ["name"] = xmlFile:getValue(key .. "#name")
        }
        if config.name ~= nil then
            config.index = xmlFile:getValue(key .. "#index", 1)
            config.value = xmlFile:getValue(key .. "#value", 0) / 1000
            configMin = math.min(configMin or math.huge, config.value * 1000)
            configMax = math.max(configMax or -math.huge, config.value * 1000)
            table.insert(massData.storeDataConfigs, config)
        end
    end
    if #massData.storeDataConfigs == 0 then
        massData.storeDataConfigs = nil
    end
    if not xmlFile:getValue("vehicle.storeData.specs.weight#ignore", false) then
        massData.storeDataMin = xmlFile:getValue("vehicle.storeData.specs.weight#minValue", configMin)
        massData.storeDataMax = xmlFile:getValue("vehicle.storeData.specs.weight#maxValue", configMax)
        if massData.componentMass > 0 or (hasConfigMass or massData.storeDataMin ~= nil) then
            return massData
        end
    end
    return nil
end
function Vehicle.getSpecConfigValuesWeight(storeItem, _, _, _, _, _)
    if storeItem.specs.weight == nil or storeItem.specs.weight.storeDataConfigs == nil then
        return nil
    else
        return storeItem.specs.weight.storeDataConfigs
    end
end
function Vehicle.getSpecValueWeight(storeItem, realItem, configurations, _, returnValues, returnRange)
    if storeItem.specs.weight ~= nil then
        local vehicleMass = nil
        local vehicleMassMax = nil
        if realItem == nil then
            if storeItem.specs.weight.storeDataMin == nil then
                if storeItem.specs.weight.componentMass ~= nil then
                    if configurations ~= nil and configurations.component ~= nil then
                        vehicleMass = storeItem.specs.weight.configurations[configurations.component]
                    end
                    if vehicleMass == nil then
                        vehicleMass = storeItem.specs.weight.componentMass
                    end
                    vehicleMass = vehicleMass + (storeItem.specs.weight.wheelMassDefaultConfig or 0) + FillUnit.getSpecValueStartFillUnitMassByMassData(storeItem.specs.weight.fillUnitMassData)
                end
            else
                vehicleMass = (storeItem.specs.weight.storeDataMin or 0) / 1000
                vehicleMassMax = (storeItem.specs.weight.storeDataMax or 0) / 1000
            end
        else
            realItem:updateMass()
            vehicleMass = realItem:getTotalMass(true)
        end
        if vehicleMass ~= nil and vehicleMass ~= 0 then
            if returnValues then
                if returnRange then
                    return vehicleMass, vehicleMassMax
                else
                    return vehicleMass
                end
            elseif vehicleMassMax == nil or vehicleMassMax == 0 then
                return g_i18n:formatMass(vehicleMass)
            else
                return g_i18n:formatMass(vehicleMass, vehicleMassMax)
            end
        end
    end
    return nil
end
function Vehicle.loadSpecValueAdditionalWeight(xmlFile, _, _)
    local maxWeight = xmlFile:getValue("vehicle.base.components#maxMass")
    if maxWeight == nil then
        return nil
    else
        return maxWeight / 1000
    end
end
function Vehicle.getSpecValueAdditionalWeight(storeItem, realItem, configurations, saleItem, returnValues, _)
    if not g_currentMission.missionInfo.trailerFillLimit then
        return nil
    end
    if storeItem.specs.additionalWeight ~= nil then
        local baseWeight = Vehicle.getSpecValueWeight(storeItem, realItem, configurations, saleItem, true)
        if baseWeight ~= nil then
            if returnValues then
                return storeItem.specs.additionalWeight - baseWeight
            else
                return g_i18n:formatMass(additionalWeight)
            end
        end
    end
    return nil
end
function Vehicle.loadSpecValueCombinations(xmlFile, _, baseDirectory)
    local combinations = {}
    xmlFile:iterate("vehicle.storeData.specs.combination", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) baseDirectory, (copy) combinations
        local combinationData = {}
        local xmlFilename = xmlFile:getValue(key .. "#xmlFilename")
        if xmlFilename ~= nil then
            combinationData.xmlFilename = Utils.getFilename(xmlFilename)
            combinationData.customXMLFilename = Utils.getFilename(xmlFilename, baseDirectory)
            local storeItem = g_storeManager:getItemByXMLFilename(combinationData.customXMLFilename)
            if storeItem == nil then
                storeItem = g_storeManager:getItemByXMLFilename(combinationData.xmlFilename)
            end
            if storeItem == nil then
                Logging.xmlWarning(xmlFile, "Could not find combination vehicle \'%s\'", combinationData.xmlFilename)
            end
        end
        local storeItem = xmlFile:getValue(key .. "#filterCategory")
        if storeItem ~= nil then
            combinationData.filterCategories = storeItem:split(" ")
        end
        combinationData.filterSpec = xmlFile:getValue(key .. "#filterSpec")
        combinationData.filterSpecMin = xmlFile:getValue(key .. "#filterSpecMin", 0)
        combinationData.filterSpecMax = xmlFile:getValue(key .. "#filterSpecMax", 1)
        if combinationData.xmlFilename ~= nil or (combinationData.filterCategories ~= nil or combinationData.filterSpec) then
            table.insert(combinations, combinationData)
        end
    end)
    return combinations
end
function Vehicle.getSpecValueCombinations(storeItem, _)
    return storeItem.specs.combinations
end
function Vehicle.getSpecValueSlots(storeItem, realItem, _, _, _, _)
    local numOwned = g_currentMission:getNumOfItems(storeItem)
    local valueText = ""
    if realItem == nil then
        local sellSlotUsage = g_currentMission.slotSystem
        local i = numOwned == 0
        local sellSlotUsage = sellSlotUsage:getStoreItemSlotUsage(storeItem, i)
        if storeItem.bundleInfo ~= nil then
            sellSlotUsage = 0
            local i = 1
            for i = i, #storeItem.bundleInfo.bundleItems do
                local bundleInfo = storeItem.bundleInfo.bundleItems[i]
                local numBundleItemOwned = g_currentMission:getNumOfItems(bundleInfo.item)
                sellSlotUsage = sellSlotUsage + g_currentMission.slotSystem:getStoreItemSlotUsage(bundleInfo.item, numBundleItemOwned == 0)
            end
        end
        if sellSlotUsage ~= 0 then
            valueText = "+" .. sellSlotUsage
        end
    else
        local sellSlotUsage = g_currentMission.slotSystem
        local sellSlotUsage = sellSlotUsage:getStoreItemSlotUsage(storeItem, numOwned == 1)
        if sellSlotUsage ~= 0 then
            valueText = "-" .. sellSlotUsage
        end
    end
    if valueText == "" then
        return nil
    else
        return valueText
    end
end