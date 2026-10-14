VehicleSystem = {}
VehicleSystem.UNIQUE_ID_PREFIX = "vehicle"
local VehicleSystem_mt = Class(VehicleSystem)
function VehicleSystem.new(mission, customMt)
    -- upvalues: (copy) VehicleSystem_mt
    local self = setmetatable({}, customMt or VehicleSystem_mt)
    self.mission = mission
    self.vehicles = {}
    self.pendingVehicleLoadingData = {}
    self.pendingVehicleSavegameLoadings = {}
    self.vehicleByUniqueId = {}
    self.wetVehicles = {}
    self.enterables = {}
    self.lastEnteredVehicleIndex = 1
    self.inputAttacherJoints = {}
    self.interactiveVehicles = {}
    self.vehiclesToDelete = {}
    self.isReloadRunning = false
    if g_addCheatCommands then
        addConsoleCommand("gsVehicleShowDistance", "Shows the distance between vehicle and cam", "consoleCommandShowVehicleDistance", self)
    end
    if self.mission:getIsServer() then
        addConsoleCommand("gsVehicleReload", "Reloads currently entered vehicle or vehicles within a range when second radius parameter is given", "consoleCommandReloadVehicle", self, "[resetVehicle]; [radiusAroundPlayer]")
        if g_addCheatCommands then
            addConsoleCommand("gsPalletAdd", "Adds a pallet", "consoleCommandAddPallet", self, "fillTypeName; [fillAmount]; [worldX]; [worldZ]")
            addConsoleCommand("gsVehicleFuelSet", "Sets the vehicle fuel level", "consoleCommandSetFuel", self)
            addConsoleCommand("gsVehicleTemperatureSet", "Sets the vehicle motor temperature", "consoleCommandSetMotorTemperature", self)
            addConsoleCommand("gsFillUnitAdd", "Changes a fillUnit with given filllevel and filltype", "consoleCommandFillUnitAdd", self, "fillUnitIndex; fillTypeName; [amount]")
            addConsoleCommand("gsVehicleOperatingTimeSet", "Sets the vehicle operating time", "consoleCommandSetOperatingTime", self)
            addConsoleCommand("gsVehicleAddDirt", "Adds a given amount to current dirt amount", "consoleCommandAddDirtAmount", self)
            addConsoleCommand("gsVehicleAddWear", "Adds a given amount to current wear amount", "consoleCommandAddWearAmount", self)
            addConsoleCommand("gsVehicleAddWetness", "Adds a given amount to current wetness amount", "consoleCommandAddWetnessAmount", self)
            addConsoleCommand("gsVehicleAddDamage", "Adds a given amount to current damage amount", "consoleCommandAddDamageAmount", self)
            addConsoleCommand("gsVehicleLoadAll", "Load all vehicles", "consoleCommandLoadAllVehicles", self, "[loadConfigs]; [modsOnly]; [palletsOnly]; [verbose]", true)
        end
        if g_addTestCommands then
            addConsoleCommand("gsVehicleToggleRandomFail", "Toggles random vehicle load failing", "consoleCommandVehicleToggleRandomFail", self)
            addConsoleCommand("gsVehicleRemoveAll", "Removes all vehicles from current mission", "consoleCommandVehicleRemoveAll", self, nil, true)
            addConsoleCommand("gsExportVehicleSets", "Exports vehicle sets", "consoleCommandExportVehicleSets", self)
        end
    end
    if g_addTestCommands then
        addConsoleCommand("gsVehiclesPendingLoadings", "Prints the pending vehicle loadings", "consoleCommandPrintPendingLoadings", self)
    end
    g_messageCenter:subscribe(BuyVehicleEvent, self.onVehicleBuyEvent, self)
    return self
end
function VehicleSystem:delete()
    local i = #self.pendingVehicleLoadingData
    for i = i, 1, -1 do
        self.pendingVehicleLoadingData[i]:cancelLoading()
    end
    for k, vehicle in pairs(self.vehiclesToDelete) do
        vehicle:delete(true)
        self.vehiclesToDelete[k] = nil
    end
    local i = #self.vehicles
    for i = i, 1, -1 do
        self.vehicles[i]:delete(true)
    end
    if self.savegameXMLFile ~= nil then
        self.savegameXMLFile:delete()
        self.savegameXMLFile = nil
    end
    self.mission = nil
    self.vehicles = {}
    self.vehicleByUniqueId = {}
    self.wetVehicles = {}
    self.enterables = {}
    self.interactiveVehicles = {}
    g_messageCenter:unsubscribeAll(self)
    removeConsoleCommand("gsVehicleShowDistance")
    removeConsoleCommand("gsVehicleReload")
    removeConsoleCommand("gsPalletAdd")
    removeConsoleCommand("gsVehicleFuelSet")
    removeConsoleCommand("gsVehicleTemperatureSet")
    removeConsoleCommand("gsFillUnitAdd")
    removeConsoleCommand("gsVehicleOperatingTimeSet")
    removeConsoleCommand("gsVehicleAddDirt")
    removeConsoleCommand("gsVehicleAddWear")
    removeConsoleCommand("gsVehicleAddWetness")
    removeConsoleCommand("gsVehicleAddDamage")
    removeConsoleCommand("gsVehicleLoadAll")
    removeConsoleCommand("gsVehicleRemoveAll")
    removeConsoleCommand("gsExportVehicleSets")
    removeConsoleCommand("gsVehiclesPendingLoadings")
end
function VehicleSystem:deleteAll()
    local i = #self.vehicles
    for i = i, 1, -1 do
        self.vehicles[i]:delete()
    end
    return #self.vehicles
end
function VehicleSystem:deleteAllPallets()
    local numDeleted = 0
    local i = #self.vehicles
    for i = i, 1, -1 do
        local vehicle = self.vehicles[i]
        if vehicle.isPallet then
            vehicle:delete()
        end
    end
    return numDeleted
end
function VehicleSystem:update(dt)
    if self.debugVehiclesToBeLoaded ~= nil then
        self:consoleCommandLoadAllVehiclesNext()
    end
    if g_server ~= nil then
        local weather = g_currentMission.environment.weather
        if weather:getRainFallScale() > 0.1 then
            local timeScale = g_currentMission:getEffectiveTimeScale()
            local timeSinceLastRain = weather:getTimeSinceLastRain()
            local temperature = weather:getCurrentTemperature()
            if timeSinceLastRain < 30 and temperature > 0 then
                for _, vehicle in pairs(self.vehicles) do
                    if not vehicle:getIsInShowroom() and vehicle.updateWetness ~= nil then
                        local x, _, z = getWorldTranslation(vehicle.rootNode)
                        if g_currentMission.indoorMask:getIsIndoorAtWorldPosition(x, z) then
                            vehicle:updateWetness(false, dt * timeScale)
                            if not vehicle:getIsWet() then
                                self.wetVehicles[vehicle] = nil
                            end
                        else
                            vehicle:updateWetness(true, dt * timeScale)
                            if vehicle:getIsWet() then
                                self.wetVehicles[vehicle] = vehicle
                            end
                        end
                    end
                end
                return
            end
        elseif next(self.wetVehicles) ~= nil then
            local timeScale = g_currentMission:getEffectiveTimeScale()
            for vehicle, _ in pairs(self.wetVehicles) do
                vehicle:updateWetness(false, dt * timeScale)
                if not vehicle:getIsWet() then
                    self.wetVehicles[vehicle] = nil
                end
            end
        end
    end
end
function VehicleSystem:draw()
    for _, vehicle in pairs(self.enterables) do
        vehicle:drawUIInfo()
    end
end
function VehicleSystem:deleteMarkedVehicles()
    for k, vehicle in pairs(self.vehiclesToDelete) do
        vehicle:delete(true)
        self.vehiclesToDelete[k] = nil
    end
end
function VehicleSystem:markVehicleForDeletion(vehicle)
    self.vehiclesToDelete[vehicle] = vehicle
end
function VehicleSystem:addVehicle(vehicle)
    if vehicle == nil or vehicle:isa(Vehicle) == nil then
        Logging.error("Given object is not a vehicle")
        return false
    end
    if vehicle:getUniqueId() ~= nil and self.vehicleByUniqueId[vehicle:getUniqueId()] ~= nil then
        Logging.warning("Tried to add existing vehicle with unique id of %s! Existing: %s, new: %s", vehicle:getUniqueId(), tostring(self.vehicleByUniqueId[vehicle:getUniqueId()]), (tostring(vehicle)))
        return false
    end
    if vehicle:getUniqueId() == nil then
        vehicle:setUniqueId(Utils.getUniqueId(vehicle, self.vehicleByUniqueId, VehicleSystem.UNIQUE_ID_PREFIX))
    end
    table.addElement(self.vehicles, vehicle)
    self.vehicleByUniqueId[vehicle:getUniqueId()] = vehicle
    if vehicle.getIsWet ~= nil and vehicle:getIsWet() then
        self.wetVehicles[vehicle] = vehicle
    end
    g_messageCenter:publish(MessageType.VEHICLE_ADDED)
    return true
end
function VehicleSystem:removeVehicle(vehicle)
    table.removeElement(self.vehicles, vehicle)
    local uniqueId = vehicle:getUniqueId()
    if uniqueId ~= nil and self.vehicleByUniqueId[uniqueId] == vehicle then
        self.vehicleByUniqueId[uniqueId] = nil
    end
    self.wetVehicles[vehicle] = nil
    g_messageCenter:publish(MessageType.VEHICLE_REMOVED)
end
function VehicleSystem:getVehicleByUniqueId(uniqueId)
    return self.vehicleByUniqueId[uniqueId]
end
function VehicleSystem:addPendingVehicleLoad(vehicleLoadingData)
    table.addElement(self.pendingVehicleLoadingData, vehicleLoadingData)
end
function VehicleSystem:removePendingVehicleLoad(vehicleLoadingData)
    table.removeElement(self.pendingVehicleLoadingData, vehicleLoadingData)
end
function VehicleSystem:getNumPendingVehicles()
    return #self.pendingVehicleLoadingData
end
function VehicleSystem:canStartMission()
    local i = 1
    for i = i, #self.vehicles do
        if not self.vehicles[i]:getIsSynchronized() then
            return false
        end
    end
    return #self.pendingVehicleLoadingData <= 0
end
function VehicleSystem:addEnterableVehicle(vehicle)
    table.addElement(self.enterables, vehicle)
end
function VehicleSystem:removeEnterableVehicle(vehicle)
    table.removeElement(self.enterables, vehicle)
    self.lastEnteredVehicleIndex = math.max(1, (math.min(self.lastEnteredVehicleIndex, #self.enterables)))
end
function VehicleSystem:setEnteredVehicle(vehicle)
    local i = 1
    for i = i, #self.enterables do
        if self.enterables[i] == vehicle then
            self.lastEnteredVehicleIndex = i
            return
        end
    end
end
function VehicleSystem:getNextEnterableVehicle(currentVehicle, delta)
    local numVehicles = #self.enterables
    if numVehicles == 0 then
        return nil
    end
    local index = 1
    if g_localPlayer:getIsInVehicle() and currentVehicle ~= nil then
        for i, enterable in ipairs(self.enterables) do
            if currentVehicle == self.enterables[i] then
                index = i + delta
                break
            end
        end
    elseif delta > 0 then
        index = self.lastEnteredVehicleIndex
    else
        index = numVehicles
    end
    local found = false
    local i = 1
    for i = i, numVehicles do
        local enterable = self.enterables[index]
        if enterable ~= nil and (enterable:getIsTabbable() and enterable:getIsEnterable()) then
            found = true
            break
        end
        index = index + delta
        if numVehicles < index then
            index = 1
        elseif index < 1 then
            index = numVehicles
        end
    end
    if found then
        return self.enterables[index]
    else
        return nil
    end
end
function VehicleSystem:registerInputAttacherJoint(vehicle, inputAttacherJointIndex, inputAttacherJoint)
    local inputAttacherJointInfo = {
        ["vehicle"] = vehicle,
        ["jointIndex"] = inputAttacherJointIndex,
        ["inputAttacherJoint"] = inputAttacherJoint,
        ["node"] = inputAttacherJoint.node,
        ["jointType"] = inputAttacherJoint.jointType,
        ["translation"] = { getWorldTranslation(inputAttacherJoint.node) }
    }
    table.addElement(self.inputAttacherJoints, inputAttacherJointInfo)
    return inputAttacherJointInfo
end
function VehicleSystem.updateInputAttacherJoint(_, inputAttacherJointInfo)
    local x, y, z = getWorldTranslation(inputAttacherJointInfo.node)
    inputAttacherJointInfo.translation[1] = x
    inputAttacherJointInfo.translation[2] = y
    inputAttacherJointInfo.translation[3] = z
end
function VehicleSystem:removeInputAttacherJoint(inputAttacherJointInfo)
    table.removeElement(self.inputAttacherJoints, inputAttacherJointInfo)
end
function VehicleSystem:addInteractiveVehicle(vehicle)
    self.interactiveVehicles[vehicle] = vehicle
end
function VehicleSystem:removeInteractiveVehicle(vehicle)
    self.interactiveVehicles[vehicle] = nil
end
function VehicleSystem:save(xmlFilename, usedModNames)
    local xmlFile = XMLFile.create("vehiclesXML", xmlFilename, "vehicles", Vehicle.xmlSchemaSavegame)
    if xmlFile ~= nil then
        self:saveToXML(self.vehicles, xmlFile, usedModNames)
        xmlFile:delete()
    end
end
function VehicleSystem:saveToXML(vehicles, xmlFile, usedModNames)
    if xmlFile ~= nil then
        local xmlIndex = 0
        for i, vehicle in ipairs(vehicles) do
            if vehicle:getNeedsSaving() then
                self:saveVehicleToXML(vehicle, xmlFile, xmlIndex, i, usedModNames)
                xmlIndex = xmlIndex + 1
            end
        end
        xmlFile:save(false, true)
    end
end
function VehicleSystem.saveVehicleToXML(_, vehicle, xmlFile, index, _, usedModNames)
    local vehicleKey = string.format("vehicles.vehicle(%d)", index)
    local modName = vehicle.customEnvironment
    if modName ~= nil then
        if usedModNames ~= nil then
            usedModNames[modName] = modName
        end
        xmlFile:setValue(vehicleKey .. "#modName", modName)
    end
    xmlFile:setValue(vehicleKey .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(vehicle.configFileName)))
    vehicle:saveToXMLFile(xmlFile, vehicleKey, usedModNames)
end
function VehicleSystem:load(xmlFilename, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments, _)
    self.savegameXMLFile = XMLFile.load("vehiclesXML", xmlFilename, Vehicle.xmlSchemaSavegame)
    if self.savegameXMLFile == nil then
        Logging.xmlError(xmlFilename, "Loading vehicles xml file failed")
        g_asyncTaskManager:addSubtask(function()
            -- upvalues: (copy) asyncCallbackFunction, (copy) asyncCallbackObject, (copy) asyncCallbackArguments
            asyncCallbackFunction(asyncCallbackObject, {}, VehicleLoadingState.ERROR, asyncCallbackArguments)
        end)
    else
        self:loadFromXMLFile(self.savegameXMLFile, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
    end
end
function VehicleSystem:loadFromXMLFile(xmlFile, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments, resetVehicles, keepPosition)
    if self.loadedVehicles == nil then
        local savegameLoadingData = xmlFile:getValue("vehicles#loadAnyFarmInSingleplayer", false)
        self.loadedVehicles = {}
        self.vehiclesToLoad = 0
        self.vehicleLoadingState = nil
        self.asyncCallbackFunction = asyncCallbackFunction
        self.asyncCallbackObject = asyncCallbackObject
        self.asyncCallbackArguments = asyncCallbackArguments
        xmlFile:iterate("vehicles.vehicle", function(_, key)
            -- upvalues: (copy) self, (copy) xmlFile, (copy) savegameLoadingData, (copy) resetVehicles, (copy) keepPosition
            g_asyncTaskManager:addSubtask(function()
                -- upvalues: (ref) self, (ref) xmlFile, (copy) key, (ref) savegameLoadingData, (ref) resetVehicles, (ref) keepPosition
                self:loadVehicleFromXML(xmlFile, key, savegameLoadingData, resetVehicles, keepPosition)
            end)
        end)
        g_asyncTaskManager:addSubtask(function()
            -- upvalues: (copy) self
            if self.vehiclesToLoad <= 0 then
                if self.asyncCallbackFunction ~= nil then
                    self.asyncCallbackFunction(self.asyncCallbackObject, self.loadedVehicles, VehicleLoadingState.OK, self.asyncCallbackArguments)
                    self.asyncCallbackFunction = nil
                    self.asyncCallbackObject = nil
                    self.asyncCallbackArguments = nil
                end
                self.loadedVehicles = nil
                self.vehicleLoadingState = nil
                self:updatePendingSavegameLoadings()
            end
        end)
    else
        table.insert(self.pendingVehicleSavegameLoadings, {
            ["xmlFile"] = xmlFile,
            ["asyncCallbackFunction"] = asyncCallbackFunction,
            ["asyncCallbackObject"] = asyncCallbackObject,
            ["asyncCallbackArguments"] = asyncCallbackArguments,
            ["resetVehicles"] = resetVehicles,
            ["keepPosition"] = keepPosition
        })
    end
end
function VehicleSystem:loadVehicleFromXML(xmlFile, key, defaultItemsToSPFarm, resetVehicles, keepPosition)
    local missionInfo = g_currentMission.missionInfo
    local filename = xmlFile:getValue(key .. "#filename")
    local defaultProperty = xmlFile:getValue(key .. "#defaultFarmProperty", false)
    local farmId = xmlFile:getValue(key .. "#farmId")
    local loadForCompetitive = defaultProperty and missionInfo.isCompetitiveMultiplayer
    if loadForCompetitive then
        loadForCompetitive = g_farmManager:getFarmById(farmId) ~= nil
    end
    local loadDefaultProperty = defaultProperty and (missionInfo.loadDefaultFarm and not g_currentMission.missionDynamicInfo.isMultiplayer)
    if loadDefaultProperty then
        loadDefaultProperty = true
        if farmId ~= FarmManager.SINGLEPLAYER_FARM_ID then
            loadDefaultProperty = defaultItemsToSPFarm
        end
    end
    if not missionInfo.isValid and (defaultProperty and not (loadDefaultProperty or loadForCompetitive)) then
        Logging.xmlInfo(xmlFile, "Vehicle \'%s\' is not allowed to be loaded", filename)
        return false
    end
    local storeItem = NetworkUtil.convertFromNetworkFilename(filename)
    local storeItem = g_storeManager:getItemByXMLFilename(storeItem)
    if storeItem == nil then
        Logging.xmlWarning(xmlFile, "Unable to retrieve store item for vehicle xml \'%s\'", storeItem)
        return false
    end
    local savegame = {
        ["xmlFile"] = xmlFile,
        ["key"] = key,
        ["ignoreFarmId"] = false,
        ["resetVehicles"] = resetVehicles,
        ["keepPosition"] = keepPosition
    }
    if loadDefaultProperty and (defaultItemsToSPFarm and farmId ~= FarmManager.SINGLEPLAYER_FARM_ID) then
        farmId = FarmManager.SINGLEPLAYER_FARM_ID
        savegame.ignoreFarmId = true
    end
    if not g_currentMission.slotSystem:hasEnoughSlots(storeItem) then
        g_currentMission:addMoney(storeItem.price, farmId, MoneyType.SHOP_VEHICLE_SELL, true)
        Logging.xmlWarning(xmlFile, "Too many slots in use. Selling vehicle \'%s\' for \'%d\'", storeItem, storeItem.price)
        return false
    end
    self.vehiclesToLoad = self.vehiclesToLoad + 1
    local data = VehicleLoadingData.new()
    data:setStoreItem(storeItem)
    data:setSavegameData(savegame)
    data:setAddToPhysics(false)
    data:load(self.loadVehicleFinished, self)
    return true
end
function VehicleSystem:loadVehicleFinished(vehicles, loadingState)
    if loadingState == VehicleLoadingState.OK then
        for _, vehicle in ipairs(vehicles) do
            table.insert(self.loadedVehicles, vehicle)
        end
    else
        self.vehicleLoadingState = self.vehicleLoadingState or loadingState
    end
    self.vehiclesToLoad = self.vehiclesToLoad - 1
    if self.vehiclesToLoad <= 0 then
        for _, vehicle in ipairs(self.loadedVehicles) do
            vehicle:addToPhysics()
        end
        if self.asyncCallbackFunction ~= nil then
            self.asyncCallbackFunction(self.asyncCallbackObject, self.loadedVehicles, self.vehicleLoadingState or VehicleLoadingState.OK, self.asyncCallbackArguments)
            self.asyncCallbackFunction = nil
            self.asyncCallbackObject = nil
            self.asyncCallbackArguments = nil
        end
        self.loadedVehicles = nil
        self.vehicleLoadingState = nil
        self:updatePendingSavegameLoadings()
    end
end
function VehicleSystem:updatePendingSavegameLoadings()
    if #self.pendingVehicleSavegameLoadings > 0 then
        local savegameLoadingData = self.pendingVehicleSavegameLoadings[1]
        table.remove(self.pendingVehicleSavegameLoadings, 1)
        self:loadFromXMLFile(savegameLoadingData.xmlFile, savegameLoadingData.asyncCallbackFunction, savegameLoadingData.asyncCallbackObject, savegameLoadingData.asyncCallbackArguments, savegameLoadingData.resetVehicles, savegameLoadingData.keepPosition)
    end
end
function VehicleSystem:onVehicleBuyEvent(_, _, _)
    local serverFarmId = g_currentMission:getFarmId()
    local numDrivables = 0
    local numVehicles = 0
    for _, item in ipairs(self.vehicles) do
        if item:getOwnerFarmId() == serverFarmId then
            if item.spec_drivable == nil then
                if item.spec_attachable ~= nil and item.spec_bigBag == nil then
                end
            end
        end
    end
    g_achievementManager:tryUnlock("NumDrivables", numDrivables)
    g_achievementManager:tryUnlock("NumVehiclesSmall", numVehicles)
    g_achievementManager:tryUnlock("NumVehiclesLarge", numVehicles)
end
function VehicleSystem.getVehicleByNodeId(_, nodeId, subShapeId)
    local vehicle = nil
    if nodeId == subShapeId then
        vehicle = g_currentMission.nodeToObject[nodeId]
    else
        while subShapeId ~= 0 do
            if g_currentMission.nodeToObject[subShapeId] ~= nil then
                vehicle = g_currentMission.nodeToObject[subShapeId]
                break
            end
            subShapeId = getParent(subShapeId)
        end
    end
    if vehicle == nil or (vehicle.isa == nil or not vehicle:isa(Vehicle)) then
        return nil
    else
        return vehicle
    end
end
function VehicleSystem:consoleCommandPrintPendingLoadings()
    Logging.info("Pending Vehicle Loadings:")
    for _, pendingData in ipairs(self.pendingVehicleLoadingData) do
        Logging.info("    - %s (Num pending: %d | State: %s)", pendingData.storeItem ~= nil and pendingData.storeItem.xmlFilename or "Unknown", pendingData.vehiclesToLoad, VehicleLoadingState.getName(pendingData.loadingState))
    end
    Logging.info("Pending Vehicles:")
    for _, pendingData in ipairs(self.vehicles) do
        if not pendingData:getIsSynchronized() then
            Logging.info("    - LoadingState: %s (%s) | LoadingStep: %s (%s) | %s", VehicleLoadingState.getName(pendingData.loadingState), pendingData.loadingState, SpecializationUtil.getLoadingStepName(pendingData.loadingStep), pendingData.loadingStep, pendingData.configFileName)
        end
    end
end
function VehicleSystem.consoleCommandShowVehicleDistance(_, active)
    g_showVehicleDistance = Utils.getNoNil(active, not g_showVehicleDistance)
end
function VehicleSystem:consoleCommandReloadVehicle(resetVehicle, radius)
    if g_gui.currentGuiName == "ShopMenu" or g_gui.currentGuiName == "ShopConfigScreen" then
        return "Error: Reload not supported while in shop!"
    end
    if self.isReloadRunning then
        return "Error: Reloading of vehicles already in progress!"
    end
    if not self.mission:getIsServer() or self.mission.missionDynamicInfo.isMultiplayer then
        return "Error: Reloading only available in SP"
    end
    resetVehicle = Utils.stringToBoolean(resetVehicle)
    radius = tonumber(radius) or 0
    local posX, posY, posZ = g_localPlayer:getPosition()
    g_soundManager:reloadSoundTemplates()
    g_vehicleMaterialManager:loadMaterialTemplates(VehicleMaterialManager.DEFAULT_TEMPLATES_FILENAME)
    g_vehicleMaterialManager:loadMaterialTemplates(VehicleMaterialManager.DEFAULT_BRAND_TEMPLATES_FILENAME)
    local affectedVehicles = {}
    local usedVehicles = {}
    local function addVehicleToReload(v, list)
        -- upvalues: (copy) usedVehicles, (copy) addVehicleToReload
        if v.isVehicleSaved then
            v.isReconfigurating = true
            table.insert(list, v)
            usedVehicles[v] = true
            if v ~= nil and v.getAttachedImplements ~= nil then
                local attachedImplements = v:getAttachedImplements()
                for _, implement in pairs(attachedImplements) do
                    addVehicleToReload(implement.object, list)
                end
                return
            end
        else
            v:delete()
        end
    end
    if g_localPlayer:getCurrentVehicle() ~= nil then
        addVehicleToReload(g_localPlayer:getCurrentVehicle(), affectedVehicles)
    end
    if radius ~= 0 then
        for _, v in pairs(self.vehicles) do
            if v ~= g_localPlayer:getCurrentVehicle() then
                local vx, vy, vz = getWorldTranslation(v.rootNode)
                if MathUtil.vector3Length(vx - posX, vy - posY, vz - posZ) < radius and usedVehicles[v.rootVehicle] == nil then
                    addVehicleToReload(v.rootVehicle, affectedVehicles)
                end
            end
        end
    end
    if #affectedVehicles == 0 then
        return "Warning: No vehicle reloaded. Enter a vehicle first or use the command with the radius parameter given, e.g. \'gsVehicleReload false 25\'\nUsage: gsVehicleReload [resetVehicle] [radius]"
    end
    local xmlFile = XMLFile.create("reloadVehiclesXMLFile", "", "vehicles", Vehicle.xmlSchemaSavegame)
    if xmlFile == nil then
        return "Error: Unable to create XML for saving vehicles"
    end
    simulatePhysics(false)
    self.isReloadRunning = true
    for v, vx in ipairs(affectedVehicles) do
        self.vehicleByUniqueId[vx:getUniqueId()] = nil
    end
    self:saveToXML(affectedVehicles, xmlFile, {})
    for v, vx in ipairs(affectedVehicles) do
        vx:removeFromPhysics()
    end
    local steerableId = nil
    if g_localPlayer:getCurrentVehicle() ~= nil then
        steerableId = g_localPlayer:getCurrentVehicle():getUniqueId()
    end
    g_i3DManager:clearEntireSharedI3DFileCache(false)
    local function asyncCallbackFunction(_, vehicles, vehicleLoadState, _)
        -- upvalues: (copy) affectedVehicles, (ref) steerableId, (copy) self, (copy) xmlFile
        local success = true
        if vehicleLoadState == VehicleLoadingState.OK then
            if #vehicles == #affectedVehicles then
                for _, affected_vehicle in pairs(affectedVehicles) do
                    affected_vehicle:delete()
                end
                if steerableId ~= nil then
                    for _, affected_vehicle in pairs(vehicles) do
                        if affected_vehicle:getUniqueId() == steerableId then
                            g_localPlayer:requestToEnterVehicle(affected_vehicle)
                        end
                    end
                end
            else
                Logging.error("Not all vehicles could be reloaded")
                success = false
            end
        else
            Logging.error("Failed to load vehicles")
            success = false
        end
        if not success then
            for _, affected_vehicle in pairs(vehicles) do
                affected_vehicle:delete()
            end
            for _, affected_vehicle in ipairs(affectedVehicles) do
                affected_vehicle:addToPhysics()
                self.vehicleByUniqueId[affected_vehicle:getUniqueId()] = affected_vehicle
            end
        end
        xmlFile:delete()
        self.isReloadRunning = false
        simulatePhysics(true)
        if success then
            Logging.info("%d vehicle(s) reloaded", #affectedVehicles)
        end
    end
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) xmlFile, (copy) asyncCallbackFunction, (ref) resetVehicle
        self:loadFromXMLFile(xmlFile, asyncCallbackFunction, nil, nil, resetVehicle, true)
    end)
end
function VehicleSystem:consoleCommandAddPallet(palletFillTypeName, amount, worldX, worldZ)
    for _, fillType in pairs(g_fillTypeManager:getFillTypes()) do
        if fillType.palletFilename ~= nil then
            ({})[fillType.name] = fillType.palletFilename
        end
    end
    if palletFillTypeName == nil then
        Logging.error("Error: no fillType given")
        return
    elseif string.lower(palletFillTypeName) == "all" then
        local x, _, _ = g_localPlayer:getPosition()
        local fillType, dirZ = localPlayer:getCurrentFacingDirection()
        for _, fillType in pairs(g_fillTypeManager:getFillTypes()) do
            if fillType.palletFilename ~= nil then
                x = x + fillType * 3
                _ = _ + dirZ * 3
                self:consoleCommandAddPallet(fillType.name, amount, x, _)
            end
        end
        return
    else
        palletFillTypeName = string.upper(palletFillTypeName)
        local x = g_fillTypeManager:getFillTypeIndexByName(palletFillTypeName)
        if x == nil then
            Logging.error("Error: Invalid pallet fillType \'%s\'", palletFillTypeName)
            local _ = Utils.getClosestMatchingString(palletFillTypeName, table.toList(pallets))
            if _ ~= nil then
                print(string.format("Did you mean %q?", _))
            end
            return string.format("Valid types are %s", table.concatKeys(pallets, ", "))
        else
            local _ = pallets[palletFillTypeName]
            if _ == nil then
                Logging.error("Error: no pallet for given fillType \'%s\'", palletFillTypeName)
            else
                local _, fillType, dirZ = localPlayer:getPosition()
                local dirX, dirZ = localPlayer:getCurrentFacingDirection()
                local _ = _ + dirX * 4
                local dirZ = dirZ + dirZ * 4
                local _ = tonumber(worldX) or _
                local dirZ = tonumber(worldZ) or dirZ
                local _ = CollisionFlag.STATIC_OBJECT + CollisionFlag.TERRAIN + CollisionFlag.TERRAIN_DELTA + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE
                local fillType, _, hitY, _, _ = RaycastUtil.raycastClosest(_, fillType + 25, dirZ, 0, -1, 0, 40, _)
                if fillType == nil then
                    hitY = getTerrainHeightAtWorldPos(g_terrainNode, _, fillType, dirZ)
                end
                local farmId = self.mission:getFarmId()
                VehicleLoadingData.new():setFilename(_);
                ((farmId == FarmManager.SPECTATOR_FARM_ID or not farmId) and 1 or farmId):setPosition(_, hitY + (Platform.gameplay.hasDynamicPallets and 0.2 or 0), dirZ)
                data:setPropertyState(VehiclePropertyState.OWNED)
                data:setOwnerFarmId(data)
                data:load(function(_, vehicles, vehicleLoadState, _)
                    -- upvalues: (copy) amount, (copy) x, (ref) palletFillTypeName
                    if vehicleLoadState ~= VehicleLoadingState.OK then
                        printError("Error: Failed to load pallet")
                        return
                    end
                    local vehicle = vehicles[1]
                    local fillUnits = vehicle:getFillUnits()
                    local amountToAdd = tonumber(amount) or math.huge
                    local addedAmount = 0
                    for _, fillUnit in ipairs(fillUnits) do
                        if vehicle:getFillUnitSupportsFillType(fillUnit.fillUnitIndex, x) then
                            addedAmount = addedAmount + vehicle:addFillUnitFillLevel(1, fillUnit.fillUnitIndex, amountToAdd, x, ToolType.UNDEFINED, nil)
                            amountToAdd = amountToAdd - addedAmount
                            if amountToAdd <= 0 then
                                break
                            end
                        end
                    end
                    print(string.format("Loaded pallet with %dl of %s", addedAmount, palletFillTypeName))
                end)
            end
        end
    end
end
function VehicleSystem:consoleCommandSetFuel(fuelLevel)
    if not self.mission:getIsServer() then
        return "Not available on clients"
    end
    if fuelLevel == nil then
        return "No fuellevel given! Usage: gsVehicleFuelSet <fuelLevel>"
    end
    local vehicle = Utils.getNoNil(tonumber(fuelLevel), 10000000000)
    local vehicle = g_localPlayer:getCurrentVehicle()
    if vehicle == nil then
        return "Enter a vehicle first!"
    end
    if vehicle.getConsumerFillUnitIndex == nil then
        return "Vehicle has no consumer"
    end
    local fillUnitIndex = vehicle:getConsumerFillUnitIndex(FillType.DIESEL) or (vehicle:getConsumerFillUnitIndex(FillType.ELECTRICCHARGE) or vehicle:getConsumerFillUnitIndex(FillType.METHANE))
    if fillUnitIndex == nil then
        return "No Fuel filltype supported!"
    end
    local delta = vehicle - vehicle:getFillUnitFillLevel(fillUnitIndex)
    vehicle:addFillUnitFillLevel(self.mission:getFarmId(), fillUnitIndex, delta, vehicle:getFillUnitFirstSupportedFillType(fillUnitIndex), ToolType.UNDEFINED, nil)
    return "Added fuel"
end
function VehicleSystem:consoleCommandSetMotorTemperature(temperature)
    if not self.mission:getIsServer() then
        return "Not available on clients"
    end
    if temperature == nil then
        return "No temperature given! Usage: gsVehicleTemperatureSet <temperature>"
    end
    local vehicle = Utils.getNoNil(tonumber(temperature), 0)
    local vehicle = g_localPlayer:getCurrentVehicle()
    if vehicle == nil then
        return "Enter a vehicle first!"
    end
    local spec = vehicle.spec_motorized
    if spec == nil then
        return "Vehicle has no motor"
    end
    spec.motorTemperature.value = math.clamp(vehicle, spec.motorTemperature.valueMin, spec.motorTemperature.valueMax)
    return "Set motor temperature to " .. spec.motorTemperature.value
end
function VehicleSystem:consoleCommandFillUnitAdd(fillUnitIndex, fillTypeName, amount)
    local mission = self.mission
    local player = g_localPlayer
    local controlledVehicle = player:getCurrentVehicle()
    local fillableVehicle = nil
    if controlledVehicle ~= nil and controlledVehicle.getSelectedObject ~= nil then
        local selectedObject = controlledVehicle:getSelectedObject()
        if selectedObject ~= nil and selectedObject.vehicle.addFillUnitFillLevel ~= nil then
            fillableVehicle = selectedObject.vehicle
        end
    end
    if fillableVehicle ~= nil or (controlledVehicle == nil or controlledVehicle.addFillUnitFillLevel == nil) then
        controlledVehicle = fillableVehicle
    end
    local object
    if controlledVehicle == nil then
        object = mission:getNodeObject((player.targeter:getClosestTargetedNodeFromType(PlayerInputComponent)))
        if object == nil or (not object:isa(Vehicle) or object.addFillUnitFillLevel == nil) then
            object = controlledVehicle
        end
    else
        object = controlledVehicle
    end
    local selectedObject = mission:getFarmId()
    if object == nil or object.getFillUnitSupportedToolTypes == nil then
        return "Error: could not find a fillable vehicle!"
    else
        local function object()
            -- upvalues: (ref) object
            local fillUnits = {}
            for fillUnitIdx, fillTypesIndices in pairs(object:debugGetSupportedFillTypesPerFillUnit()) do
                table.insert(fillUnits, string.format("FillUnit %d - FillTypes: %s", fillUnitIdx, table.concat(g_fillTypeManager:getFillTypeNamesByIndices(fillTypesIndices), " ")))
            end
            return "Available FillUnits and supported FillTypes:\n" .. table.concat(fillUnits, "\n")
        end
        if fillUnitIndex == nil or fillTypeName == nil then
            return "Error: Missing parameters.\nUsage: \'gsFillUnitAdd <fillUnitIndex> <fillTypeName> [amount]\'"
        elseif mission:getIsServer() then
            local fillTypeIndex = tonumber(fillUnitIndex)
            local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
            local capacity = tonumber(amount)
            if fillTypeIndex == nil then
                return "Error: Missing fillUnitIndex!\nUsage: \'gsFillUnitAdd <fillUnitIndex> <fillTypeName> [amount]\'"
            elseif object:getFillUnitExists(fillTypeIndex) then
                if fillTypeIndex == nil then
                    Logging.error("Unknown fillType \'%s\'!\n%s", fillTypeName, (object()))
                    return
                else
                    local capacity = object:getFillUnitCapacity(fillTypeIndex)
                    if capacity == 0 then
                        Logging.error("Selected Vehicle \'%s\' cannot be filled. Capacity is 0!", object:getName())
                    else
                        if object:getFillUnitSupportsFillType(fillTypeIndex, fillTypeIndex) then
                            amount = capacity or capacity
                            if amount == 0 then
                                amount = -capacity
                            end
                            object:addFillUnitFillLevel(selectedObject, fillTypeIndex, amount, fillTypeIndex, ToolType.UNDEFINED)
                            local fillLevel = object:getFillUnitFillLevel(fillTypeIndex)
                            local fillTypeIndex = object:getFillUnitFillType(fillTypeIndex)
                            fillTypeName = Utils.getNoNil(g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex), "unknown")
                            return string.format("new fillLevel: %.1f, fillType: %d (%s)", fillLevel, fillTypeIndex, fillTypeName)
                        end
                        Logging.error("fillUnit \'%d\' in \'%s\' does not support fillType \'%s\'\n%s", fillTypeIndex, object:getName(), fillTypeName, (object()))
                    end
                end
            else
                Logging.error("FillUnit \'%d\' in \'%s\' does not exist!\n%s", fillTypeIndex, object:getName(), (object()))
                return
            end
        else
            return "Error: \'gsFillUnitAdd\' can only be called on server side!"
        end
    end
end
function VehicleSystem:consoleCommandSetOperatingTime(operatingTime)
    if not self.mission:getIsServer() then
        return "Not available on clients"
    end
    if operatingTime == nil then
        return "No operatingTime given! Usage: gsVehicleOperatingTimeSet <operatingTime (h)>"
    end
    operatingTime = (tonumber(operatingTime) or 0) * 1000 * 60 * 60
    local controlledVehicle = g_localPlayer:getCurrentVehicle()
    if controlledVehicle == nil then
        return "Enter a vehicle first!"
    end
    if controlledVehicle.setOperatingTime == nil then
        return "Vehicle has no operating time"
    end
    controlledVehicle:setOperatingTime(operatingTime)
    return string.format("Set operating time to %.1f", operatingTime)
end
function VehicleSystem:consoleCommandAddDirtAmount(amount)
    if not self.mission:getIsServer() then
        return "Error: Not available on clients"
    end
    amount = tonumber(amount) or 0
    local controlledVehicle = g_localPlayer:getCurrentVehicle()
    if controlledVehicle == nil then
        return "Error: Enter a vehicle first!"
    end
    for _, vehicle in pairs(controlledVehicle.rootVehicle.childVehicles) do
        if vehicle.setDirtAmount ~= nil then
            local prevDirtAmount = vehicle:getDirtAmount()
            vehicle:setDirtAmount(prevDirtAmount + amount)
            Logging.info("Set dirt amount of vehicle \'%s\' from %.2f to %.2f", vehicle:getName(), prevDirtAmount, vehicle:getDirtAmount())
        end
    end
end
function VehicleSystem:consoleCommandAddWearAmount(amount)
    if not self.mission:getIsServer() then
        return "Error: Not available on clients"
    end
    amount = tonumber(amount) or 0
    local controlledVehicle = g_localPlayer:getCurrentVehicle()
    if controlledVehicle == nil then
        return "Error: Enter a vehicle first!"
    end
    for _, vehicle in pairs(controlledVehicle.rootVehicle.childVehicles) do
        if vehicle.addWearAmount ~= nil then
            vehicle:addWearAmount(amount)
        end
    end
    return string.format("Added wear to vehicles (Amount: %.2f)", amount)
end
function VehicleSystem:consoleCommandAddWetnessAmount(amount)
    if not self.mission:getIsServer() then
        return "Error: Not available on clients"
    end
    amount = tonumber(amount) or 0
    local controlledVehicle = g_localPlayer:getCurrentVehicle()
    if controlledVehicle == nil then
        return "Error: Enter a vehicle first!"
    end
    for _, vehicle in pairs(controlledVehicle.rootVehicle.childVehicles) do
        if vehicle.addWetnessAmount ~= nil then
            vehicle:addWetnessAmount(amount)
        end
    end
    return string.format("Added wetness to vehicles (Amount: %.2f)", amount)
end
function VehicleSystem:consoleCommandAddDamageAmount(amount)
    if not self.mission:getIsServer() then
        return "Error: Not available on clients"
    end
    amount = tonumber(amount) or 0
    local controlledVehicle = g_localPlayer:getCurrentVehicle()
    if controlledVehicle == nil then
        return "Error: Enter a vehicle first!"
    end
    for _, vehicle in pairs(controlledVehicle.rootVehicle.childVehicles) do
        if vehicle.addDamageAmount ~= nil then
            vehicle:addDamageAmount(amount)
        end
    end
    return string.format("Added damage to vehicles (Amount: %.2f)", amount)
end
function VehicleSystem:consoleCommandLoadAllVehicles(loadConfigs, modsOnly, palletsOnly, verbose)
    if not self.mission:getIsServer() and self.mission.missionDynamicInfo.isMultiplayer then
        return "Error: Command not allowed in multiplayer"
    end
    if self.debugVehiclesToBeLoaded ~= nil then
        return "Error: Loading task is currently running!"
    end
    loadConfigs = string.lower(loadConfigs or "false") == "true"
    modsOnly = string.lower(modsOnly or "false") == "true"
    palletsOnly = string.lower(palletsOnly or "false") == "true"
    verbose = string.lower(verbose or "false") == "true"
    self.debugVehiclesToBeLoaded = {}
    self.debugVehiclesLoaded = {}
    self.debugVehiclesTotal = 0
    self.debugVehiclesToBeLoadedStartTime = g_time
    I3DManager.VERBOSE_LOADING = verbose
    if palletsOnly then
        for _, storeItem in pairs(g_fillTypeManager:getFillTypes()) do
            if storeItem.palletFilename ~= nil then
                local defaultConfigs = g_storeManager:getItemByXMLFilename(storeItem.palletFilename)
                table.insert(self.debugVehiclesToBeLoaded, {
                    ["storeItem"] = defaultConfigs,
                    ["configurations"] = {}
                })
            end
        end
    else
        for _, storeItem in pairs(g_storeManager:getItems()) do
            if StoreItemUtil.getIsVehicle(storeItem) and (not modsOnly or (storeItem.isMod or storeItem.dlcTitle ~= "")) then
                local defaultConfigs = {}
                if storeItem.defaultConfigurationIds ~= nil then
                    defaultConfigs = table.clone(storeItem.defaultConfigurationIds)
                end
                if #storeItem.configurationSets > 0 then
                    local defaultSetIndex = 1
                    local i = 1
                    local i = 1
                    for i = i, #storeItem.configurationSets, i do
                        if storeItem.configurationSets[i].isDefault then
                            defaultSetIndex = i
                            break
                        end
                    end
                    for name, index in pairs(storeItem.configurationSets[defaultSetIndex].configurations) do
                        defaultConfigs[name] = index
                    end
                end
                table.insert(self.debugVehiclesToBeLoaded, {
                    ["storeItem"] = storeItem,
                    ["configurations"] = defaultConfigs
                })
                self.debugVehiclesTotal = self.debugVehiclesTotal + 1
                if loadConfigs then
                    if storeItem.configurations ~= nil then
                        for i, name in pairs(storeItem.configurations) do
                            if #name > 1 then
                                local index = false
                                local i = 1
                                local usedAsDependentConfig = #storeItem.configurationSets
                                for i = i, usedAsDependentConfig do
                                    if storeItem.configurationSets[i].configurations[i] ~= nil then
                                        index = true
                                        break
                                    end
                                end
                                local usedAsDependentConfig = false
                                if not index then
                                    for _, otherConfigItems in pairs(storeItem.configurations) do
                                        for _, otherConfigItem in ipairs(otherConfigItems) do
                                            if otherConfigItem.dependentConfigurations ~= nil then
                                                for _, dependentConfig in ipairs(otherConfigItem.dependentConfigurations) do
                                                    if dependentConfig.name == i then
                                                        usedAsDependentConfig = true
                                                        break
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                                if not (index or usedAsDependentConfig) then
                                    for _, otherConfigItems in ipairs(name) do
                                        if otherConfigItems.isSelectable then
                                            if #storeItem.configurationSets > 0 then
                                                local i = 1
                                                for i = i, #storeItem.configurationSets do
                                                    local otherConfigItem = table.clone(storeItem.configurationSets[i].configurations)
                                                    otherConfigItem[i] = otherConfigItems.index
                                                    table.insert(self.debugVehiclesToBeLoaded, {
                                                        ["storeItem"] = storeItem,
                                                        ["configurations"] = otherConfigItem
                                                    })
                                                end
                                            else
                                                table.insert(self.debugVehiclesToBeLoaded, {
                                                    ["storeItem"] = storeItem,
                                                    ["configurations"] = {
                                                        [i] = otherConfigItems.index
                                                    }
                                                })
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    local i = 1
                    local defaultSetIndex = #storeItem.configurationSets
                    for i = i, defaultSetIndex do
                        local i = storeItem.configurationSets[i]
                        local name = {}
                        for i, configSet in pairs(i.configurations) do
                            name[i] = configSet
                        end
                        table.insert(self.debugVehiclesToBeLoaded, {
                            ["storeItem"] = storeItem,
                            ["configurations"] = name
                        })
                    end
                end
            end
        end
    end
    self.debugVehiclesTotalConfigs = #self.debugVehiclesToBeLoaded
    local modStr = modsOnly and "mod " or ""
    if loadConfigs then
        return print(string.format("Loading %i %svehicles with all configs...", self.debugVehiclesTotal, modStr))
    else
        return print(string.format("Loading %i %svehicles (add first param \'true\' to include configs, add second param \'true\' to only load mods, add third param \'true\' to only load pallets, add fourth param \'verbose\' to print i3d loading messages)...", self.debugVehiclesTotal, modStr))
    end
end
function VehicleSystem:consoleCommandLoadAllVehiclesNext()
    if self.debugVehiclesLoaded ~= nil then
        local i = #self.debugVehiclesLoaded
        for i = i, 1, -1 do
            local vehicle = self.debugVehiclesLoaded[i]
            vehicle.deleteFrameCounter = vehicle.deleteFrameCounter - 1
            if vehicle.deleteFrameCounter <= 0 then
                vehicle:delete()
                table.remove(self.debugVehiclesLoaded, i)
            end
        end
    end
    if self.debugVehiclesToBeLoaded == nil then
        return
    elseif self.debugVehiclesLoadingCount == nil or self.debugVehiclesLoadingCount <= 0 then
        if not self.debugVehiclesLoading then
            local vehicleData = table.remove(self.debugVehiclesToBeLoaded, 1)
            if vehicleData == nil then
                print(string.format("Successfully loaded and removed all vehicles in %.1f seconds!", (g_time - self.debugVehiclesToBeLoadedStartTime) / 1000))
                self.debugVehiclesToBeLoaded = nil
                self.debugVehiclesLoadingCount = nil
                for _, vehicle in pairs(self.debugVehiclesLoaded) do
                    vehicle:delete()
                end
                self.debugVehiclesLoaded = {}
                I3DManager.VERBOSE_LOADING = true
                return
            end
            local totalTime = "None"
            if next(vehicleData.configurations) ~= nil then
                totalTime = ""
                for _, vehicle in pairs(vehicleData.configurations) do
                    if totalTime ~= "" then
                    end
                    totalTime = totalTime .. string.format("%s:%d", _, vehicle)
                end
            end
            Logging.info("Loading vehicle %d/%d: %s (Configuration: %s)", self.debugVehiclesTotalConfigs - #self.debugVehiclesToBeLoaded, self.debugVehiclesTotalConfigs, vehicleData.storeItem.xmlFilename, totalTime)
            local vehicle = VehicleLoadingData.new()
            local localPlayer = g_localPlayer
            local _, vehicle, z = localPlayer:getPosition()
            local dirX, dirZ = localPlayer:getCurrentFacingDirection()
            vehicle:setPosition(_ + dirX * 10, vehicle, z + dirZ * 10)
            vehicle:setStoreItem(vehicleData.storeItem)
            vehicle:setConfigurations(vehicleData.configurations)
            vehicle:setIsRegistered(false)
            vehicle:setIsSaved(false)
            self.debugVehiclesLoading = true
            vehicle:load(function(_, vehicles, _, _)
                -- upvalues: (copy) self
                self.debugVehiclesLoading = false
                for _, vehicle in pairs(vehicles) do
                    vehicle:removeFromPhysics()
                    table.insert(self.debugVehiclesLoaded, vehicle)
                    vehicle.deleteFrameCounter = 2
                end
            end, nil, nil)
        end
    end
end
function VehicleSystem:consoleCommandVehicleRemoveAll()
    local numDeleted = 0
    local i = #self.vehicles
    for i = i, 1, -1 do
        local vehicle = self.vehicles[i]
        if vehicle.trainSystem == nil and not vehicle.isPallet then
            vehicle:delete()
        end
    end
    return string.format("Deleted %i vehicle(s)! Excluded train and pallets", numDeleted)
end
function VehicleSystem:consoleCommandVehicleToggleRandomFail()
    Vehicle.DEBUG_RANDOM_FAIL_LOADING = not Vehicle.DEBUG_RANDOM_FAIL_LOADING
    return string.format("Vehicle.DEBUG_RANDOM_FAIL_LOADING: %s", Vehicle.DEBUG_RANDOM_FAIL_LOADING)
end
function VehicleSystem:consoleCommandExportVehicleSets()
    local rootVehicles = {}
    for _, v in ipairs(self.vehicles) do
        rootVehicles[rootVehicle] = v:getRootVehicle() or rootVehicles[rootVehicle]
    end
    setFileLogPrefixTimestamp(false)
    for rootVehicle, vehicle in pairs(rootVehicles) do
        local xmlFile = loadXMLFileFromMemory("vehicleSets", "<vehicleSets></vehicleSets>")
        local key = string.format("vehicleSets.vehicleSet(%d)", 0)
        local children = vehicle:getChildVehicles()
        local vehicleIndex = 0
        local k = #children
        local attacherIndex = 1
        for k = k, attacherIndex, -1 do
            local childVehicle = children[k];
            (function(xmlFile, key, vehicle, baseVehicle)
                setXMLString(xmlFile, key .. ".xmlFilename", vehicle.configFileName)
                setXMLFloat(xmlFile, key .. ".rotY", 0)
                setXMLFloat(xmlFile, key .. ".captainFoldingState", 0)
                local offsetX, offsetY, offsetZ = localToLocal(vehicle.rootNode, baseVehicle.rootNode, 0, 0, 0)
                setXMLString(xmlFile, key .. ".offset", string.format("%.2f %.2f %.2f", offsetX, offsetY, offsetZ))
                local configIndex = 0
                for configName, configId in pairs(vehicle.configurations) do
                    local saveId = ConfigurationUtil.getSaveIdByConfigId(vehicle.configFileName, configName, configId)
                    if saveId ~= nil then
                        local configKey = string.format("%s.configurations.configuration(%d)", key, configIndex)
                        setXMLString(xmlFile, configKey .. "#name", configName)
                        setXMLString(xmlFile, configKey .. "#id", saveId)
                        configIndex = configIndex + 1
                    end
                end
            end)(xmlFile, string.format("%s.vehicle(%d)", key, vehicleIndex), childVehicle, vehicle)
            vehicleIndex = vehicleIndex + 1
            ({})[childVehicle] = vehicleIndex
        end
        local attacherIndex = 0
        local childVehicle = #children
        local k = -1
        for childVehicle = childVehicle, 1, k do
            local vehicleKey = children[childVehicle]
            local attacherVehicle = nil
            if vehicleKey.getAttacherVehicle ~= nil then
                attacherVehicle = vehicleKey:getAttacherVehicle()
            end
            if attacherVehicle ~= nil then
                local attachKey = string.format("%s.attach(%d)", key, attacherIndex)
                local implement = attacherVehicle:getImplementByObject(vehicleKey)
                local inputAttacherJointIndex = vehicleKey:getActiveInputAttacherJointDescIndex()
                setXMLInt(xmlFile, attachKey .. "#element0", childToIndex[attacherVehicle])
                setXMLInt(xmlFile, attachKey .. "#element1", childToIndex[vehicleKey])
                setXMLInt(xmlFile, attachKey .. "#attacherJointIndex", implement.jointDescIndex)
                setXMLInt(xmlFile, attachKey .. "#inputAttacherJointIndex", inputAttacherJointIndex)
                attacherIndex = attacherIndex + 1
            end
        end
        print((saveXMLFileToMemory(xmlFile)))
        delete(xmlFile)
    end
    setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
end