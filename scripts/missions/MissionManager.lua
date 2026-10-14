MissionManager = {}
MissionManager.UNIQUE_ID_PREFIX = "mission"
MissionManager.MAX_MISSIONS = 30
MissionManager.MISSION_GENERATION_INTERVAL = 360000
MissionManager.MAX_MISSIONS_PER_FARM = 3
MissionManager.VERSION = 0
MissionManager.DEBUG_ENABLED = false
local MissionManager_mt = Class(MissionManager, AbstractManager)
g_xmlManager:addCreateSchemaFunction(function()
    MissionManager.xmlSchema = XMLSchema.new("missionVehicles")
    MissionManager.xmlSchemaSavegame = XMLSchema.new("savegame_missions")
end)
g_xmlManager:addInitSchemaFunction(function()
    local missionSchema = Mission00.xmlSchema
    missionSchema:register(XMLValueType.BOOL, "map.missions#enabled", "")
    missionSchema:register(XMLValueType.STRING, "map.missions#vehicleFilename", "")
    for _, missionType in ipairs(g_missionManager.missionTypes) do
        local classObject = missionType.classObject
        local key = string.format("map.missions.%s", missionType.name)
        missionSchema:register(XMLValueType.INT, key .. "#maxNumInstances")
        if classObject.registerXMLPaths ~= nil then
            classObject.registerXMLPaths(missionSchema, key)
        end
    end
    local schema = MissionManager.xmlSchema
    schema:register(XMLValueType.STRING, "missionVehicles.mission(?)#type", "Type of the mission", nil, true)
    schema:register(XMLValueType.STRING, "missionVehicles.mission(?).group(?)#size", "Size of the mission", "medium", false, { "small", "medium", "large" })
    schema:register(XMLValueType.FLOAT, "missionVehicles.mission(?).group(?)#rewardScale", "Reward scale factor", 1, false)
    schema:register(XMLValueType.STRING, "missionVehicles.mission(?).group(?)#variant", "Name of the variant", nil, false)
    schema:register(XMLValueType.STRING, "missionVehicles.mission(?).group(?).vehicle(?)#filename", "Filename of the vehicle", nil, true)
    schema:registerAutoCompletionDataSource("missionVehicles.mission(?).group(?).vehicle(?)#filename", "dataS/storeItems.xml", "storeItems.storeItem#xmlFilename")
    schema:register(XMLValueType.STRING, "missionVehicles.mission(?).group(?).vehicle(?).configuration(?)#name", "Name of the configuration", nil, true)
    schema:register(XMLValueType.INT, "missionVehicles.mission(?).group(?).vehicle(?).configuration(?)#id", "Id of the configuration", nil, true)
    local savegameSchema = MissionManager.xmlSchemaSavegame
    savegameSchema:register(XMLValueType.INT, "missions#version", "Version")
    for key, missionType in ipairs(g_missionManager.missionTypes) do
        local classObject = missionType.classObject
        local key = string.format("missions.meta.%s", missionType.name)
        if classObject.registerMetaXMLPaths ~= nil then
            classObject.registerMetaXMLPaths(savegameSchema, key)
        end
    end
    for key, missionType in ipairs(g_missionManager.missionTypes) do
        local classObject = missionType.classObject
        local key = string.format("missions.%s(?)", missionType.name)
        if classObject.registerSavegameXMLPaths ~= nil then
            classObject.registerSavegameXMLPaths(savegameSchema, key)
        end
    end
end)
function MissionManager.new(customMt)
    -- upvalues: (copy) MissionManager_mt
    local self = AbstractManager.new(customMt or MissionManager_mt)
    self.defaultMissionMapWidth = 512
    self.defaultMissionMapHeight = 512
    self.missionMapNumChannels = 4
    return self
end
function MissionManager:initDataStructures()
    self.missions = {}
    self.missionsToDelete = {}
    self.missionTypes = {}
    self.nameToMissionType = {}
    self.missionByUniqueId = {}
    self.missionMap = nil
    self.currentMissionTypeIndex = 0
    self.startMissionTypeIndex = 0
    self.pendingMissionVehicleFiles = {}
    self.missionVehicles = {}
    self.nextGeneratedMissionId = 1
    self.generationTimer = 0
end
function MissionManager:delete()
    if self.debugBitVectorMap ~= nil then
        g_debugManager:removeElement(self.debugBitVectorMap)
    end
end
function MissionManager:loadMapData(xmlFile)
    MissionManager:superClass().loadMapData(self)
    if Utils.getNoNil(getXMLBool(xmlFile, "map.missions#enabled"), true) then
        self:createMissionMap()
        local currentMission = g_currentMission
        local xmlFileObj = XMLFile.wrap(xmlFile, Mission00.xmlSchema)
        for _, missionType in ipairs(self.missionTypes) do
            local classObject = missionType.classObject
            local key = string.format("map.missions.%s", missionType.name)
            local data = missionType.data
            data.maxNumInstances = xmlFileObj:getInt(key .. "#maxNumInstances") or data.maxNumInstances
            if classObject.loadMapData ~= nil then
                classObject.loadMapData(xmlFileObj, key, currentMission.baseDirectory)
            end
        end
        xmlFileObj:delete()
        if currentMission:getIsServer() then
            currentMission:addUpdateable(self)
        end
        local missionVehicleXmlFilename = getXMLString(xmlFile, "map.missions#vehicleFilename")
        if missionVehicleXmlFilename == nil then
            Logging.xmlDevWarning(xmlFile, "MissionManager: No vehicleFilename defined for mission vehicles")
        else
            local path = Utils.getFilename(missionVehicleXmlFilename, currentMission.baseDirectory)
            if path ~= nil then
                self:loadVehicleGroups(path, currentMission.baseDirectory)
            end
        end
        for missionType, classObject in ipairs(self.pendingMissionVehicleFiles) do
            self:loadVehicleGroups(classObject[1], classObject[2])
        end
        if g_addTestCommands and g_server ~= nil then
            addConsoleCommand("gsMissionGenerate", "Force generating a new mission for given farmland", "consoleGenerateMission", self, "farmlandId; missionType")
            addConsoleCommand("gsMissionLoadVehicleSet", "Loads a specific vehicle set", "consoleLoadVehicleSet", self, "missionType; [size (small|medium|large)]; [groupIndex]")
            addConsoleCommand("gsMissionLoadVehiclesAll", "Loads all mission vehicles", "consoleLoadAllVehicleSets", self, "")
        end
    else
        Logging.xmlInfo(xmlFile, "MissionManager: Disabled missions according to configuration")
    end
end
function MissionManager:unloadMapData()
    g_messageCenter:unsubscribeAll(self)
    g_currentMission:removeUpdateable(self)
    for _, missionType in ipairs(self.missionTypes) do
        local classObject = missionType.classObject
        if classObject.unloadMapData ~= nil then
            classObject.unloadMapData(missionType.data)
        end
    end
    self:destroyMissionMap()
    removeConsoleCommand("gsMissionGenerate")
    removeConsoleCommand("gsMissionLoadVehicleSet")
    removeConsoleCommand("gsMissionLoadVehiclesAll")
    MissionManager:superClass().unloadMapData(self)
end
function MissionManager:saveToXMLFile(xmlFilename)
    local xmlFile = XMLFile.create("missionXML", xmlFilename, "missions", MissionManager.xmlSchemaSavegame)
    if xmlFile ~= nil then
        for _, missionType in ipairs(self.missionTypes) do
            local classObject = missionType.classObject
            local key = string.format("missions.meta.%s", missionType.name)
            if classObject.saveMetaDataToXMLFile ~= nil then
                classObject.saveMetaDataToXMLFile(xmlFile, key)
            end
        end
        xmlFile:setValue("missions#version", MissionManager.VERSION)
        for missionType, classObject in ipairs(self.missions) do
            ({})[classObject.type.name] = (({})[classObject.type.name] or 0) + 1
            classObject:saveToXMLFile(xmlFile, (string.format("missions.%s(%d)", classObject.type.name, counts[classObject.type.name] - 1)))
        end
        xmlFile:save()
        xmlFile:delete()
    end
    return false
end
function MissionManager:loadFromXMLFile(xmlFilename)
    if xmlFilename == nil then
        return false
    end
    local xmlFile = XMLFile.load("missionsXML", xmlFilename, MissionManager.xmlSchemaSavegame)
    if xmlFile == nil then
        return false
    end
    if xmlFile:getValue("missions#version") ~= MissionManager.VERSION then
        Logging.xmlWarning(xmlFile, "Missions version does not match current mission manager version")
        xmlFile:delete()
        return true
    end
    for _, missionType in ipairs(self.missionTypes) do
        local classObject = missionType.classObject
        local key = string.format("missions.meta.%s", missionType.name)
        if classObject.loadMetaDataFromXMLFile ~= nil then
            classObject.loadMetaDataFromXMLFile(xmlFile, key)
        end
    end
    for missionType, classObject in xmlFile:iterator("missions.*") do
        local key = xmlFile:getElementName(classObject);
        ({})[key] = (({})[key] or 0) + 1
        local missionTypeKey = string.format("missions.%s(%d)", key, numElements[key] - 1)
        if key ~= "meta" then
            local missionType = self:getMissionType(key)
            if missionType == nil then
                Logging.xmlWarning(xmlFile, "Mission type \'%s\' not found for \'%s!", key, missionTypeKey)
            else
                local mission = missionType.classObject.new
                local hasValidFarm = true
                local mission = mission(hasValidFarm, g_client ~= nil)
                mission.type = missionType
                self:assignGenerationTime(mission)
                if mission:loadFromXMLFile(xmlFile, missionTypeKey) then
                    local hasValidFarm = true
                    if mission.farmId ~= nil then
                        hasValidFarm = g_farmManager:getFarmById(mission.farmId) ~= nil
                    end
                    if hasValidFarm then
                        mission:register()
                        self:addMission(mission)
                    else
                        table.insert(self.missionsToDelete, mission)
                    end
                else
                    if mission.failedToLoadFromXMLFile ~= nil then
                        mission:failedToLoadFromXMLFile()
                    end
                    table.insert(self.missionsToDelete, mission)
                end
            end
        end
    end
    xmlFile:delete()
    return true
end
function MissionManager:getCanStartNewMissionGeneration()
    return not self.missionGenerationInProgress and #self.missions < MissionManager.MAX_MISSIONS and self.generationTimer < 0
end
function MissionManager:update(dt)
    local currentMission = g_currentMission
    if currentMission:getIsServer() and Platform.gameplay.hasMissions then
        self.generationTimer = self.generationTimer - currentMission:getEffectiveTimeScale() * dt
        self:updateMissions(dt)
        if self:getCanStartNewMissionGeneration() then
            self:startMissionGeneration()
            return
        end
        if self.missionGenerationInProgress then
            self:generateMission()
        end
    end
end
function MissionManager:updateMissions(_)
    for _, mission in ipairs(self.missions) do
        if mission.status == MissionStatus.CREATED and not mission:validate() then
            table.insert(self.missionsToDelete, mission)
        end
    end
    local i = #self.missionsToDelete
    for i = i, 1, -1 do
        table.remove(self.missionsToDelete, i):delete()
    end
end
function MissionManager:startMissionGeneration()
    g_messageCenter:publish(MessageType.MISSION_GENERATION_START)
    self.currentMissionTypeIndex = math.random(1, #self.missionTypes)
    self.startMissionTypeIndex = self.currentMissionTypeIndex
    self.missionGenerationInProgress = true
end
function MissionManager:finishMissionGeneration()
    g_messageCenter:publish(MessageType.MISSION_GENERATION_END)
    self.generationTimer = MissionManager.MISSION_GENERATION_INTERVAL
    self.missionGenerationInProgress = false
end
function MissionManager:generateMission()
    local missionType = self.missionTypes[self.currentMissionTypeIndex]
    if missionType == nil then
        self:finishMissionGeneration()
        return
    else
        local success = false
        local classObject = missionType.classObject
        if classObject.tryGenerateMission ~= nil then
            local mission = classObject.tryGenerateMission()
            if mission ~= nil then
                self:registerMission(mission, missionType)
                success = true
            end
        end
        self.currentMissionTypeIndex = self.currentMissionTypeIndex + 1
        if self.currentMissionTypeIndex > #self.missionTypes then
            self.currentMissionTypeIndex = 1
        end
        if self.currentMissionTypeIndex == self.startMissionTypeIndex then
            self:finishMissionGeneration()
            return
        elseif success then
            self:finishMissionGeneration()
        end
    end
end
function MissionManager:registerMission(mission, missionType)
    mission.type = missionType
    mission:register()
    self:addMission(mission)
    g_messageCenter:publish(MessageType.MISSION_GENERATED, mission)
end
function MissionManager:addMission(mission)
    if mission:getUniqueId() == nil or self.missionByUniqueId[mission:getUniqueId()] == nil then
        if mission:getUniqueId() == nil then
            mission:setUniqueId(Utils.getUniqueId(mission, self.missionByUniqueId, MissionManager.UNIQUE_ID_PREFIX))
        end
        self.missionByUniqueId[mission:getUniqueId()] = mission
        table.addElement(self.missions, mission)
    else
        Logging.warning("Tried to add existing mission with unique id of %s! Existing: %s, new: %s", mission:getUniqueId(), tostring(self.missionByUniqueId[mission:getUniqueId()]), (tostring(mission)))
    end
end
function MissionManager:removeMission(mission)
    table.removeElement(self.missions, mission)
    local uniqueId = mission:getUniqueId()
    if uniqueId ~= nil then
        self.missionByUniqueId[uniqueId] = nil
    end
end
function MissionManager:markMissionForDeletion(mission)
    table.addElement(self.missionsToDelete, mission)
end
function MissionManager:getMissionByUniqueId(uniqueId)
    return self.missionByUniqueId[uniqueId]
end
function MissionManager:startMission(mission, farmId, spawnVehicles)
    assert(g_currentMission:getIsServer(), "MissionManager:startMission is a server-only function")
    if farmId == FarmManager.SPECTATOR_FARM_ID then
        return MissionStartState.NO_ACCESS
    elseif self:hasFarmReachedMissionLimit(farmId) then
        return MissionStartState.LIMIT_REACHED
    elseif mission.activeMissionId then
        return MissionStartState.ALREADY_STARTED
    else
        for _, activeMission in ipairs(self.missions) do
            if activeMission.status == MissionStatus.PREPARING then
                return MissionStartState.PENDING_MISSION
            end
        end
        if mission:validate() then
            mission.activeMissionId = self:getFreeActiveMissionId()
            if mission.activeMissionId == 0 then
                return MissionStartState.CANNOT_BE_STARTED_NOW
            else
                mission.farmId = farmId
                if mission:start(spawnVehicles) then
                    g_messageCenter:publish(MissionStartedEvent, mission)
                    return MissionStartState.OK
                else
                    mission:delete()
                    return MissionStartState.CANNOT_BE_STARTED_NOW
                end
            end
        else
            mission:delete()
            return MissionStartState.NOT_AVAILABLE_ANYMORE
        end
    end
end
function MissionManager.cancelMission(_, mission)
    assert(g_currentMission:getIsServer(), "MissionManager:cancelMission is a server-only function")
    if mission == nil or mission.status == MissionStatus.FINISHED then
        return false
    end
    mission:finish(MissionFinishState.CANCELED)
    return true
end
function MissionManager.dismissMission(_, mission)
    assert(g_currentMission:getIsServer(), "MissionManager:dismissMission is a server-only function")
    mission:dismiss()
    mission:delete()
    return true
end
function MissionManager:getMissions()
    return self.missions
end
function MissionManager:getMissionsByFarmId(farmId)
    return table.ifilter(self.missions, function(mission)
        -- upvalues: (copy) farmId
        return mission.farmId == nil or mission.farmId == farmId
    end)
end
function MissionManager:getIsMissionRunningOnFarmland(farmland)
    if farmland == nil then
        return false
    end
    local farmlandId = farmland:getId()
    for _, mission in ipairs(self.missions) do
        if mission.getFarmlandId ~= nil and (mission:getFarmlandId() == farmlandId and mission:getIsInProgress()) then
            return true
        end
    end
    return false
end
function MissionManager:getMissionByFarmlandId(farmlandId)
    if farmlandId == nil then
        return nil
    end
    for _, mission in ipairs(self.missions) do
        if mission.getFarmlandId ~= nil and mission:getFarmlandId() == farmlandId then
            return mission
        end
    end
    return nil
end
function MissionManager:getMissionsByType(typeIndex)
    local missionType = self.missionTypes[typeIndex]
    if missionType == nil then
        return nil
    else
        return table.ifilter(self.missions, function(mission)
            -- upvalues: (copy) missionType
            return mission:isa(missionType.classObject)
        end)
    end
end
function MissionManager:hasFarmReachedMissionLimit(farmId)
    local total = 0
    for _, mission in ipairs(self.missions) do
        if mission.farmId == farmId and mission:getWasStarted() then
        end
    end
    return MissionManager.MAX_MISSIONS_PER_FARM <= total
end
function MissionManager:createMissionMap()
    self.missionMap = InfoLayer.new("MissionAccessMap")
    self.missionMap:create(self.defaultMissionMapWidth, self.defaultMissionMapHeight, self.missionMapNumChannels, false)
    local currentMission = g_currentMission
    if currentMission:getIsServer() then
        currentMission.growthSystem:setGrowthMask(self.missionMap:getId(), 0, self.missionMapNumChannels)
    end
    if MissionManager.DEBUG_ENABLED then
        self.debugBitVectorMap = DebugBitVectorMap.newSimple(20, currentMission.terrainSize / self.defaultMissionMapWidth, false, 0.2)
        self.debugBitVectorMap:createWithCustomFunc(function(_, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
            -- upvalues: (copy) self
            return self.missionMap:getValueAtWorldPos((startWorldX + widthWorldX + heightWorldX) / 3, (startWorldZ + widthWorldZ + heightWorldZ) / 3)
        end)
        g_debugManager:addElement(self.debugBitVectorMap)
    end
end
function MissionManager:destroyMissionMap()
    local currentMission = g_currentMission
    if currentMission:getIsServer() then
        currentMission.growthSystem:resetGrowthMask()
    end
    if self.missionMap ~= nil then
        self.missionMap:delete()
        self.missionMap = nil
    end
end
function MissionManager:setMissionMapActiveMissionId(area, missionId)
    if self.missionMap ~= nil then
        self.missionMap:setValueAtArea(area, missionId)
    end
end
function MissionManager:getMissionMapActiveMissionIdAtWorldPosition(worldX, worldZ)
    return self.missionMap == nil and 0 or self.missionMap:getValueAtWorldPos(worldX, worldZ, nil, nil)
end
function MissionManager:getMissionAtWorldPosition(worldX, worldZ)
    local missionId = self:getMissionMapActiveMissionIdAtWorldPosition(worldX, worldZ)
    if missionId > 0 then
        return self:getMissionByActiveMissionId(missionId)
    else
        return nil
    end
end
function MissionManager:getMissionByActiveMissionId(activeMissionId)
    for _, mission in ipairs(self.missions) do
        if mission.activeMissionId == activeMissionId then
            return mission
        end
    end
    return nil
end
function MissionManager:getFreeActiveMissionId()
    local i = 1
    for i = i, MissionManager.MAX_MISSIONS do
        if self:getMissionByActiveMissionId(i) == nil then
            return i
        end
    end
    return 0
end
function MissionManager:getIsMissionWorkAllowed(farmId, x, z, workAreaType, vehicle)
    local mission = self:getMissionAtWorldPosition(x, z)
    return mission ~= nil and (mission.farmId == farmId and mission:getIsWorkAllowed(farmId, x, z, workAreaType, vehicle)) and true or false
end
function MissionManager:registerMissionType(classObject, name, defaultMaxNumInstances)
    if classObject ~= nil and name ~= nil then
        local missionType = {
            ["name"] = name,
            ["classObject"] = classObject,
            ["typeId"] = #self.missionTypes + 1,
            ["data"] = {
                ["numInstances"] = 0,
                ["maxNumInstances"] = defaultMaxNumInstances or 2
            }
        }
        table.insert(self.missionTypes, missionType)
        self.nameToMissionType[string.upper(name)] = missionType
    end
end
function MissionManager:unregisterMissionType(name)
    if name ~= nil then
        for i, type in ipairs(self.missionTypes) do
            if type.name == name then
                table.remove(self.missionType, i)
                return
            end
        end
    end
end
function MissionManager:getMissionType(name)
    return self.nameToMissionType[string.upper(name)]
end
function MissionManager:getMissionTypeById(id)
    return self.missionTypes[id]
end
function MissionManager:getMissionTypeDataByName(name)
    if name == nil then
        Logging.devError("MissionManager.getMissionTypeDataByName: no mission type name defined")
        if g_isDevelopmentVersion then
            printCallstack()
        end
        return nil
    else
        local missionType = self.nameToMissionType[string.upper(name)]
        if missionType == nil then
            return nil
        else
            return missionType.data
        end
    end
end
function MissionManager:getMissionBySplitShape(shape)
    if shape == nil or shape == 0 then
        return nil
    end
    for _, mission in ipairs(self.missions) do
        if mission.getIsMissionSplitShape ~= nil and mission:getIsMissionSplitShape(shape) then
            return mission
        end
    end
    return nil
end
function MissionManager:getIsShapeCutAllowed(shape, x, z, farmId)
    for _, mission in ipairs(self.missions) do
        if mission.getIsShapeCutAllowed ~= nil then
            local isAllowed = mission:getIsShapeCutAllowed(shape, x, z, farmId)
            if isAllowed ~= nil then
                return isAllowed
            end
        end
    end
    return nil
end
function MissionManager:getIsMissionDestructible(farmId, nodeId)
    for _, mission in ipairs(self.missions) do
        if mission.getDestructibleIsInMissionArea ~= nil and mission:getDestructibleIsInMissionArea(nodeId, farmId) then
            return true
        end
    end
    return false
end
function MissionManager:addPendingMissionVehiclesFile(filename, baseDirectory)
    table.insert(self.pendingMissionVehicleFiles, { filename, baseDirectory })
end
function MissionManager:loadVehicleGroups(xmlFilename, baseDirectory)
    local xmlFile = XMLFile.load("MissionVehicles", xmlFilename, MissionManager.xmlSchema)
    if xmlFile == nil then
        return false
    end
    for _, missionKey in xmlFile:iterator("missionVehicles.mission") do
        local missionTypeName = xmlFile:getValue(missionKey .. "#type")
        if missionTypeName == nil then
            Logging.xmlError(xmlFile, "Property type must exist on each mission - \'%s\'", missionKey)
        elseif self:getMissionType(missionTypeName) == nil then
            Logging.xmlError(xmlFile, "Mission type \'%s\' is not defined - \'%s\'", missionTypeName, missionKey)
        else
            if self.missionVehicles[missionTypeName] == nil then
                self.missionVehicles[missionTypeName] = {}
            end
            for _, groupKey in xmlFile:iterator(missionKey .. ".group") do
                local size = xmlFile:getValue(groupKey .. "#size", "medium")
                local success = true
                local vehicles = {}
                local group = {
                    ["rewardScale"] = xmlFile:getValue(groupKey .. "#rewardScale", 1),
                    ["vehicles"] = vehicles,
                    ["variant"] = xmlFile:getValue(groupKey .. "#variant")
                }
                for _, vehicleKey in xmlFile:iterator(groupKey .. ".vehicle") do
                    local vehicleXMLFilename = Utils.getFilename(xmlFile:getValue(vehicleKey .. "#filename"), baseDirectory)
                    if vehicleXMLFilename == nil then
                        success = false
                        Logging.xmlError(xmlFile, "Missing \'filename\' attribute for vehicle %q", vehicleKey)
                        break
                    end
                    if g_storeManager:getItemByXMLFilename(vehicleXMLFilename) == nil then
                        success = false
                        Logging.xmlError(xmlFile, "Unable to load store item for xml filename \'%q at %q", vehicleXMLFilename, vehicleKey)
                        break
                    end
                    local configurations = nil
                    for _, configKey in xmlFile:iterator(vehicleKey .. ".configuration") do
                        local name = xmlFile:getValue(configKey .. "#name")
                        local id = xmlFile:getValue(configKey .. "#id")
                        if name == nil then
                            Logging.xmlError(xmlFile, "Missing \'name\' attribute for configuration at %q", configKey)
                        elseif id == nil then
                            Logging.xmlError(xmlFile, "Missing \'id\' attribute for configuration %q at %q", name, configKey)
                        else
                            configurations = configurations or {}
                            configurations[name] = id
                        end
                    end
                    table.insert(vehicles, {
                        ["filename"] = vehicleXMLFilename,
                        ["configurations"] = configurations
                    })
                end
                if success then
                    if self.missionVehicles[missionTypeName][size] == nil then
                        groups[size] = {}
                    end
                    table.insert(groups[size], group)
                    group.identifier = #groups[size]
                end
            end
        end
    end
    xmlFile:delete()
    return true
end
function MissionManager:getRandomVehicleGroup(missionType, size, variant)
    local groups = self.missionVehicles[missionType]
    if groups == nil then
        return nil, 1
    else
        local sized = groups[size]
        if sized == nil then
            return nil, 1
        else
            local variantGroups = table.ifilter(sized, function(group)
                -- upvalues: (copy) variant
                return variant == nil or group.variant == variant
            end)
            local group = table.getRandomElement(variantGroups)
            if group == nil then
                return nil, 1
            else
                return group.vehicles, group.identifier
            end
        end
    end
end
function MissionManager:getVehicleGroupFromIdentifier(missionType, fieldSize, identifier)
    local groups = self.missionVehicles[missionType]
    if groups == nil then
        return nil, 1, "No vehicles for missionType"
    else
        local sized = groups[fieldSize]
        if sized == nil then
            return nil, 1, "No vehicles for fieldSize"
        else
            local group = sized[identifier]
            if group == nil then
                return nil, 1, "No vehicles for index/indetifier"
            else
                return group.vehicles, group.rewardScale, "", group
            end
        end
    end
end
function MissionManager:assignGenerationTime(mission)
    mission.generationTime = self.nextGeneratedMissionId
    self.nextGeneratedMissionId = self.nextGeneratedMissionId + 1
end
function MissionManager:consoleGenerateMission(farmlandId, missionTypeName)
    local farmland = tonumber(farmlandId)
    local farmland = g_farmlandManager:getFarmlandById(farmland)
    if farmland == nil then
        printError("Error: Given farmland not found")
        return
    else
        local field = farmland:getField()
        g_fieldManager.debugField = field
        if missionTypeName == nil then
            printError(string.format("Error: No mission type given"))
            print(string.format("Available mission types: %s", table.concatKeys(self.nameToMissionType, ", ")))
            return
        else
            local success = false
            local missionType = self:getMissionType(missionTypeName)
            if missionType == nil then
                printError(string.format("Error: Given missionType %q not found", missionTypeName))
                print(string.format("Available mission types: %s", table.concatKeys(self.nameToMissionType, ", ")))
            else
                local classObject = missionType.classObject
                if classObject.tryGenerateMission ~= nil then
                    local mission = classObject.tryGenerateMission()
                    if mission ~= nil then
                        self:registerMission(mission, missionType)
                        success = true
                    end
                end
                g_fieldManager.debugField = nil
                if success then
                    return "Mission created"
                end
                printError("Error: Failed to create mission")
            end
        end
    end
end
function MissionManager:consoleLoadVehicleSet(missionTypeName, size, groupIndex)
    size = size or "medium"
    groupIndex = tonumber(groupIndex) or 1
    local foundMissionType = false
    for _, missionType in ipairs(self.missionTypes) do
        table.insert({}, missionType.name)
        if missionType.name == missionTypeName then
            foundMissionType = true
        end
    end
    if foundMissionType then
        local vehicles, _, errorMessage = self:getVehicleGroupFromIdentifier(missionTypeName, size, groupIndex)
        if vehicles == nil then
            Logging.error("No vehicles defined for parameter. %s", errorMessage)
        else
            local _ = 0
            local missionType = #vehicles
            for _, vehicleInfo in ipairs(vehicles) do
                local data = VehicleLoadingData.new()
                data:setFilename(vehicleInfo.filename)
                if data.isValid then
                    if vehicleInfo.configurations ~= nil then
                        data:setConfigurations(vehicleInfo.configurations)
                    end
                    local mission = g_currentMission
                    data:setLoadingPlace(mission.storeSpawnPlaces, mission.usedStorePlaces)
                    data:setOwnerFarmId(g_localPlayer:getFarmId())
                    data:load(function(_, loadedVehicles, vehicleLoadState, _)
                        -- upvalues: (ref) _, (copy) missionType
                        if vehicleLoadState == VehicleLoadingState.OK then
                            _ = _ + 1
                            if _ == missionType then
                                Logging.info("Finished mission vehicle loading")
                                return
                            end
                        else
                            for _, vehicle in ipairs(loadedVehicles) do
                                vehicle:delete()
                            end
                            Logging.error("Failed to load vehicles")
                        end
                    end, nil, nil)
                end
            end
        end
    else
        Logging.error("Unknown missionType %q", missionTypeName)
        print(string.format("Available mission types: %s", table.concat(missionTypeNames, ", ")))
        return
    end
end
function MissionManager:consoleLoadAllVehicleSets()
    local vehiclesToLoad = {}
    for missionType, missionSizes in pairs(self.missionVehicles) do
        for missionSize, variants in pairs(missionSizes) do
            for _, variant in ipairs(variants) do
                for _, vehicle in ipairs(variant.vehicles) do
                    table.insert(vehiclesToLoad, vehicle)
                end
            end
        end
    end
    local numVehicles = #vehiclesToLoad
    local loadNextVehicle = nil
    local function onSpawnedVehicle(_, loadedVehicles, _, _)
        -- upvalues: (copy) vehiclesToLoad, (ref) loadNextVehicle
        for _, vehicle in ipairs(loadedVehicles) do
            vehicle:delete()
        end
        if #vehiclesToLoad > 0 then
            loadNextVehicle()
        else
            Logging.info("Finished mission vehicle loading")
        end
    end
    loadNextVehicle = function()
        -- upvalues: (copy) vehiclesToLoad, (copy) numVehicles, (copy) onSpawnedVehicle
        local vehicleToLoad = table.remove(vehiclesToLoad, 1)
        if vehicleToLoad ~= nil then
            Logging.info("loading mission vehicle %d/%d", numVehicles - #vehiclesToLoad, numVehicles)
            local data = VehicleLoadingData.new()
            data:setFilename(vehicleToLoad.filename)
            if vehicleToLoad.configurations ~= nil then
                data:setConfigurations(vehicleToLoad.configurations)
            end
            local mission = g_currentMission
            data:setLoadingPlace(mission.storeSpawnPlaces, mission.usedStorePlaces)
            data:setOwnerFarmId(g_localPlayer:getFarmId())
            data:load(onSpawnedVehicle, nil, nil)
        end
    end
    Logging.info("Started loading %d mission vehicles", numVehicles)
    loadNextVehicle()
end
g_missionManager = MissionManager.new()