Mission00 = {}
local Mission00_mt = Class(Mission00, FSBaseMission)
g_xmlManager:addCreateSchemaFunction(function()
    Mission00.xmlSchema = XMLSchema.new("mission00")
end)
g_xmlManager:addInitSchemaFunction(function()
    local schema = Mission00.xmlSchema
    schema:register(XMLValueType.STRING, "map.filename", "filepath to map i3d file", nil, true)
    schema:register(XMLValueType.INT, "map#width", "Width of the world", 2048)
    schema:register(XMLValueType.INT, "map#height", "Height of the world", 2048)
    schema:register(XMLValueType.STRING, "map#imageFilename", "2D map filename")
    schema:register(XMLValueType.VECTOR_3, "map#mapFieldColor", "2D map field color rgb")
    schema:register(XMLValueType.VECTOR_3, "map#mapGrassFieldColor", "2D map grass color rgb")
    schema:register(XMLValueType.FLOAT, "map.culling#xzOffset", "")
    schema:register(XMLValueType.FLOAT, "map.culling#minY", "")
    schema:register(XMLValueType.FLOAT, "map.culling#maxY", "")
    schema:register(XMLValueType.FLOAT, "map.culling#clipDistanceThreshold1", "")
    schema:register(XMLValueType.FLOAT, "map.culling#clipDistanceThreshold2", "")
    schema:register(XMLValueType.INT, "map.densityMap#revision", "")
    schema:register(XMLValueType.INT, "map.terrainTexture#revision", "")
    schema:register(XMLValueType.INT, "map.terrainLodTexture#revision", "")
    schema:register(XMLValueType.INT, "map.splitShapes#revision", "")
    schema:register(XMLValueType.INT, "map.tipCollision#revision", "")
    schema:register(XMLValueType.INT, "map.placementCollision#revision", "")
    schema:register(XMLValueType.INT, "map.navigationCollision#revision", "")
    schema:register(XMLValueType.FLOAT, "map.vertexBufferMemoryUsage", "")
    schema:register(XMLValueType.FLOAT, "map.indexBufferMemoryUsage", "")
    schema:register(XMLValueType.FLOAT, "map.textureMemoryUsage", "")
    schema:register(XMLValueType.STRING, "map.shop#filename", "")
    schema:register(XMLValueType.STRING, "map.storeItems#filename", "")
    schema:register(XMLValueType.STRING, "map.sounds#filename", "")
    schema:register(XMLValueType.STRING, "map.environment#filename", "")
    schema:register(XMLValueType.STRING, "map.environmentAreaSystem#outOfBoundsAreaType", "AreaType to use for EnvironmentAreaSystem if the requested posities lies outside of the map bounds / bitmap")
    schema:register(XMLValueType.STRING, "map.weed#filename", "")
    schema:register(XMLValueType.STRING, "map.fieldGround#filename", "")
    schema:register(XMLValueType.STRING, "map.motionPathEffects#filename", "")
    schema:register(XMLValueType.STRING, "map.bales#filename", "")
    schema:register(XMLValueType.STRING, "map.helpers#filename", "")
    schema:register(XMLValueType.STRING, "map.densityHeightTypes#filename", "")
    schema:register(XMLValueType.STRING, "map.fillTypes#filename", "")
    schema:register(XMLValueType.STRING, "map.groundTypes#filename", "")
    schema:register(XMLValueType.STRING, "map.sprayTypes#filename", "")
    schema:register(XMLValueType.STRING, "map.animals#filename", "")
    schema:register(XMLValueType.STRING, "map.animals.food#filename", "")
    schema:register(XMLValueType.STRING, "map.animals.names#filename", "")
    schema:register(XMLValueType.STRING, "map.wildlife#filename", "")
    schema:register(XMLValueType.STRING, "map.aiSystem#filename", "")
    schema:register(XMLValueType.STRING, "map.licensePlates#filename", "")
    schema:register(XMLValueType.STRING, "map.helpline#filename", "")
    schema:register(XMLValueType.VECTOR_TRANS, "map.helpline.trigger(?)#position", "")
    schema:register(XMLValueType.INT, "map.helpline.trigger(?)#categoryIndex", "")
    schema:register(XMLValueType.INT, "map.helpline.trigger(?)#pageIndex", "")
    schema:register(XMLValueType.STRING, "map.gameplayHints#filename", "")
    schema:register(XMLValueType.STRING, "map.collectibles#filename", "")
    schema:register(XMLValueType.STRING, "map.additionalFiles.additionalFile(?)#filename", "Path to additional i3d- or xml files to load for the map")
    schema:register(XMLValueType.STRING, "map.decoFoliages.decoFoliage(?)#layerName", "")
    schema:register(XMLValueType.INT, "map.decoFoliages.decoFoliage(?)#startChannel", "")
    schema:register(XMLValueType.INT, "map.decoFoliages.decoFoliage(?)#numChannels", "")
    schema:register(XMLValueType.BOOL, "map.decoFoliages.decoFoliage(?)#mowable", "")
    schema:register(XMLValueType.STRING, "map.decoFoliages.mapping(?)#name", "")
    schema:register(XMLValueType.STRING, "map.decoFoliages.mapping(?)#layerName", "")
    schema:register(XMLValueType.INT, "map.decoFoliages.mapping(?)#state", "")
    schema:register(XMLValueType.STRING, "map.paintableFoliages.paintableFoliage(?)#layerName", "")
    schema:register(XMLValueType.INT, "map.paintableFoliages.paintableFoliage(?)#startChannel", "")
    schema:register(XMLValueType.INT, "map.paintableFoliages.paintableFoliage(?)#numStateChannels", "")
    schema:register(XMLValueType.STRING, "map.groundTypeMappings.groundTypeMapping(?)#type", "")
    schema:register(XMLValueType.STRING, "map.groundTypeMappings.groundTypeMapping(?)#title", "")
    schema:register(XMLValueType.STRING, "map.groundTypeMappings.groundTypeMapping(?)#layer", "")
    schema:register(XMLValueType.STRING, "map.hotspots.placeableHotspot(?)#type", "Placeable hotspot type")
    schema:register(XMLValueType.VECTOR_2, "map.hotspots.placeableHotspot(?)#worldPosition", "Placeable world position")
    schema:register(XMLValueType.VECTOR_3, "map.hotspots.placeableHotspot(?)#teleportWorldPosition", "Placeable teleport world position")
    schema:register(XMLValueType.STRING, "map.hotspots.placeableHotspot(?)#text", "Placeable hotspot text")
end)
function Mission00.new(baseDirectory, custom_mt)
    -- upvalues: (copy) Mission00_mt
    local self = Mission00:superClass().new(baseDirectory, custom_mt or Mission00_mt)
    if g_dedicatedServer ~= nil then
        self:setAutoSaveInterval(g_dedicatedServer.autoSaveInterval, true)
    end
    self.isSaving = false
    g_mission00StartPoint = nil
    self.gameStarted = false
    self.mapHotspots = {}
    return self
end
function Mission00:delete()
    if self.xmlFile ~= nil then
        delete(self.xmlFile)
        self.xmlFile = nil
    end
    g_autoSaveManager:unloadMapData()
    for _, hotspot in ipairs(self.mapHotspots) do
        self:removeMapHotspot(hotspot)
        hotspot:delete()
    end
    Mission00:superClass().delete(self)
end
function Mission00:setMissionInfo(missionInfo, missionDynamicInfo)
    local mapXMLFilename = Utils.getFilename(missionInfo.mapXMLFilename, self.baseDirectory)
    local xmlFile = XMLFile.load("MapXML", mapXMLFilename, Mission00.xmlSchema)
    self.xmlFile = xmlFile:getHandle()
    self.mapWidth = xmlFile:getValue("map#width", 2048)
    self.mapHeight = xmlFile:getValue("map#height", 2048)
    self.mapImageFilename = Utils.getFilename(xmlFile:getValue("map#imageFilename"), self.baseDirectory)
    self.mapFieldColor = xmlFile:getValue("map#mapFieldColor", nil, true) or { 0.15, 0.1195, 0.0953 }
    self.mapGrassFieldColor = xmlFile:getValue("map#mapGrassFieldColor", nil, true) or { 0.147, 0.1441, 0.0823 }
    self.cullingWorldXZOffset = xmlFile:getValue("map.culling#xzOffset", self.cullingWorldXZOffset)
    self.cullingWorldMinY = xmlFile:getValue("map.culling#minY", self.cullingWorldMinY)
    self.cullingWorldMaxY = xmlFile:getValue("map.culling#maxY", self.cullingWorldMaxY)
    self.cullingClipDistanceThreshold1 = xmlFile:getValue("map.culling#clipDistanceThreshold1", self.cullingClipDistanceThreshold1)
    self.cullingClipDistanceThreshold2 = xmlFile:getValue("map.culling#clipDistanceThreshold2", self.cullingClipDistanceThreshold2)
    self.mapDensityMapRevision = xmlFile:getValue("map.densityMap#revision", 1)
    self.mapTerrainTextureRevision = xmlFile:getValue("map.terrainTexture#revision", 1)
    self.mapTerrainLodTextureRevision = xmlFile:getValue("map.terrainLodTexture#revision", 1)
    self.mapSplitShapesRevision = xmlFile:getValue("map.splitShapes#revision", 1)
    self.mapTipCollisionRevision = xmlFile:getValue("map.tipCollision#revision", 1)
    self.mapPlacementCollisionRevision = xmlFile:getValue("map.placementCollision#revision", 1)
    self.mapNavigationCollisionRevision = xmlFile:getValue("map.navigationCollision#revision", 1)
    self.vertexBufferMemoryUsage = xmlFile:getValue("map.vertexBufferMemoryUsage", self.vertexBufferMemoryUsage)
    self.indexBufferMemoryUsage = xmlFile:getValue("map.indexBufferMemoryUsage", self.indexBufferMemoryUsage)
    self.textureMemoryUsage = xmlFile:getValue("map.textureMemoryUsage", self.textureMemoryUsage)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        g_gameplayHintManager:loadMapData(self.xmlFile, missionInfo)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        self.navigationSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        self.slotSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        self.fieldGroundSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        self.aiMessageManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
        self.aiJobTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        g_wheelManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        g_treePlantManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        self.treeMarkerSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        g_vehicleMaterialManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        g_storeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
        g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.STORE)
    end, "Mission00:setMissionInfo - StoreManager:loadMapData")
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        g_groundTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        g_connectionHoseManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        g_consumableManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        g_fillTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        g_fruitTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        g_baleManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        self.weedSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        self.stoneSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        self.aiSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        self.animalSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end, "Mission00:setMissionInfo - AnimalSystem:loadMapData")
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        self.animalFoodSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        g_sleepManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        self.animalNameSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        g_densityMapHeightManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        g_npcManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo
        g_helperManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo, (copy) missionDynamicInfo
        g_materialManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory, function()
            -- upvalues: (ref) self, (ref) missionInfo, (ref) missionDynamicInfo
            self:onMaterialsLoaded(missionInfo, missionDynamicInfo)
        end)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo, (copy) missionDynamicInfo
        Mission00:superClass().setMissionInfo(self, missionInfo, missionDynamicInfo)
    end)
end
function Mission00:onMaterialsLoaded(missionInfo, _)
    if not self.cancelLoading then
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self, (copy) missionInfo
            g_licensePlateManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
        end)
        g_asyncTaskManager:addTask(function()
            g_particleSystemManager:loadMapData()
        end)
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self, (copy) missionInfo
            g_motionPathEffectManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
        end)
        g_asyncTaskManager:addTask(function()
            g_effectManager:loadMapData()
        end)
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self, (copy) missionInfo
            self.foliageSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
        end)
        g_asyncTaskManager:addTask(function()
            g_fillTypeManager:loadModFillTypes()
            g_densityMapHeightManager:loadModDensityMapHeightTypes()
            g_motionPathEffectManager:loadQueuedModMotionPathEffects()
        end)
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self, (copy) missionInfo
            g_sprayTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
            g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.DATA)
        end)
    end
end
function Mission00:load()
    self:startLoadingTask()
    self:loadEnvironment(self.xmlFile)
    local mapFilename = getXMLString(self.xmlFile, "map.filename")
    local soundFilename = Utils.getFilename(mapFilename, self.baseDirectory)
    Logging.info("Loading map: %s", soundFilename)
    self:loadMap(soundFilename, true, self.loadMission00Finished, self)
    local soundFilename = Utils.getNoNil(getXMLString(self.xmlFile, "map.sounds#filename"), "$data/maps/map01_sound.xml")
    local soundFilename = Utils.getFilename(soundFilename, self.baseDirectory)
    self.missionInfo.mapSoundXmlFilename = soundFilename
    self:loadMapSounds(soundFilename, self.baseDirectory)
    self.ambientSoundSystem:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
    self.environmentAreaSystem:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
    self.reverbSystem:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
    self.collectiblesSystem:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
    self.growthSystem:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
    self.snowSystem:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
end
function Mission00:loadMission00Finished(_, _)
    if not self.cancelLoading then
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            local numAdditionalFiles = self:loadAdditionalFiles(self.xmlFile, function()
                -- upvalues: (ref) self
                self.numAdditionalFiles = self.numAdditionalFiles - 1
                if self.numAdditionalFiles == 0 then
                    self:loadAdditionalFilesFinished()
                end
            end, nil)
            if numAdditionalFiles > 0 then
                self.numAdditionalFiles = numAdditionalFiles
            else
                self:loadAdditionalFilesFinished()
            end
        end)
    end
end
function Mission00:loadAdditionalFilesFinished()
    if not self.cancelLoading then
        g_asyncTaskManager:addTask(function()
            g_materialManager:loadModMaterialHolders()
            g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.ADDITIONAL_FILES)
        end)
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            self.hud:loadIngameMap(self.mapImageFilename, self.mapWidth, self.mapHeight, self.mapFieldColor, self.mapGrassFieldColor)
        end, "Mission00:loadAdditionalFilesFinished - Load Ingamemap")
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            self:loadHotspots(self.xmlFile, self.missionInfo.customEnvironment)
        end, "Mission00:loadAdditionalFilesFinished - Load Hotspots")
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            self.handToolSystem:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
        end)
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            g_farmlandManager:loadMapData(self.xmlFile)
        end, "Mission00:loadAdditionalFilesFinished - FarmlandManager:loadMapData")
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            g_guidedTourManager:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
        end)
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            g_fieldManager:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
        end)
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            g_fieldCourseManager:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
        end)
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            g_farmManager:loadMapData(self.xmlFile)
            if self.missionDynamicInfo.isMultiplayer then
                self:loadCompetitiveMultiplayer(self.xmlFile)
            end
        end)
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            self.placeableSystem:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
        end)
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            self:loadPlaceables(self.missionInfo.placeablesXMLLoad)
        end)
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            g_missionManager:loadMapData(self.xmlFile)
        end)
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            g_helpLineManager:loadMapData(self.xmlFile, self.missionInfo)
        end)
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            g_gui:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
        end)
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            if self:getIsServer() and (self.missionInfo.savegameDirectory ~= nil and fileExists(self.missionInfo.savegameDirectory .. "/collectibles.xml")) then
                self.collectiblesSystem:loadFromXMLFile(self.missionInfo.savegameDirectory .. "/collectibles.xml")
            end
        end)
        g_asyncTaskManager:addTask(function()
            g_autoSaveManager:loadFinished()
        end)
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            if self.missionDynamicInfo.isMultiplayer then
                self:removeAllHelpIcons()
            else
                self:updateFoundHelpIcons()
            end
        end)
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            if self.xmlFile ~= nil then
                delete(self.xmlFile)
                self.xmlFile = nil
            end
        end)
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            Mission00:superClass().load(self)
            if self.missionInfo.economyXMLLoad ~= nil then
                self:loadEconomy(self.missionInfo.economyXMLLoad)
            end
        end)
        if self:getIsServer() then
            g_asyncTaskManager:addTask(function()
                -- upvalues: (copy) self
                if self.missionInfo.fieldsXMLLoad ~= nil then
                    g_fieldManager:loadFromXMLFile(self.missionInfo.fieldsXMLLoad)
                end
            end)
            g_asyncTaskManager:addTask(function()
                -- upvalues: (copy) self
                g_farmManager:loadFromXMLFile(self.missionInfo.farmsXMLLoad)
            end)
            g_asyncTaskManager:addTask(function()
                -- upvalues: (copy) self
                g_farmlandManager:loadFromXMLFile(self.missionInfo.farmlandXMLLoad)
            end)
            g_asyncTaskManager:addTask(function()
                -- upvalues: (copy) self
                g_missionManager:loadFromXMLFile(self.missionInfo.missionsXMLLoad)
            end)
            g_asyncTaskManager:addTask(function()
                -- upvalues: (copy) self
                g_guidedTourManager:loadFromXMLFile(self.missionInfo.guidedTourXMLLoad)
            end)
            g_asyncTaskManager:addTask(function()
                -- upvalues: (copy) self
                if self.missionInfo.playersXMLLoad ~= nil then
                    self.playerSystem:loadFromSavegameXML(self.missionInfo.playersXMLLoad)
                end
            end)
            g_asyncTaskManager:addTask(function()
                -- upvalues: (copy) self
                g_npcManager:loadFromSavegameXMLFile(self.missionInfo.npcXMLLoad)
            end)
            g_asyncTaskManager:addTask(function()
                -- upvalues: (copy) self
                self.vehicleSaleSystem:loadFromXMLFile(self.missionInfo.vehicleSaleXML)
            end)
            g_asyncTaskManager:addTask(function()
                -- upvalues: (copy) self
                if self.missionInfo.treeMarkerXMLLoad ~= nil then
                    self.treeMarkerSystem:loadFromSavegameXML(self.missionInfo.treeMarkerXMLLoad)
                end
            end)
            g_asyncTaskManager:addTask(function()
                -- upvalues: (copy) self
                if self.missionInfo.destructibleMapObjectsXMLLoad ~= nil then
                    self.destructibleMapObjectSystem:loadFromSavegameXML(self.missionInfo.destructibleMapObjectsXMLLoad)
                end
            end)
            g_asyncTaskManager:addTask(function()
                -- upvalues: (copy) self
                self.growthSystem:loadFromXMLFile(self.missionInfo.environmentXMLLoad)
                if self.missionInfo.environmentXMLLoad ~= nil then
                    self.snowSystem:loadFromXMLFile(self.missionInfo.environmentXMLLoad)
                end
            end)
            g_asyncTaskManager:addTask(function()
                -- upvalues: (copy) self
                if self.missionInfo.aiSystemXMLLoad ~= nil then
                    self.aiSystem:loadFromXMLFile(self.missionInfo.aiSystemXMLLoad)
                end
            end)
            g_asyncTaskManager:addTask(function()
                -- upvalues: (copy) self
                if self.missionInfo.navigationSystemXMLLoad ~= nil then
                    self.aiSystem:loadFromXMLFile(self.missionInfo.navigationSystemXMLLoad)
                end
            end)
        end
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            g_treePlantManager:loadFromXMLFile(self.missionInfo.treePlantXMLLoad)
        end, "TreePlantManager:loadFromXMLFile")
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            self:finishLoadingTask()
        end)
    end
end
function Mission00:loadAdditionalFiles(xmlFile, callbackFunc, callbackTarget)
    local i = 0
    local numFiles = 0
    while true do
        local key = string.format("map.additionalFiles.additionalFile(%d)", i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local filename = getXMLString(xmlFile, key .. "#filename")
        if filename ~= nil then
            if filename:contains(".i3d") then
                g_asyncTaskManager:addSubtask(function()
                    -- upvalues: (ref) filename, (copy) self, (copy) callbackFunc, (copy) callbackTarget
                    filename = Utils.getFilename(filename, self.baseDirectory)
                    g_i3DManager:loadI3DFileAsync(filename, true, true, self.onLoadedMapI3DFiles, self, { callbackFunc, callbackTarget })
                end)
            elseif filename:contains(".xml") then
                local filename = Utils.getFilename(filename, self.baseDirectory)
                local externalXMLFile = XMLFile.load("additionalFilesXML", filename)
                if externalXMLFile ~= nil then
                    externalXMLFile:iterate("additionalFiles.additionalFile", function(_, additionalFileKey)
                        -- upvalues: (copy) externalXMLFile, (copy) self, (copy) callbackFunc, (copy) callbackTarget, (ref) numFiles
                        local externalFilename = externalXMLFile:getString(additionalFileKey .. "#filename")
                        if externalFilename ~= nil then
                            local externalFilename = Utils.getFilename(externalFilename, self.baseDirectory)
                            g_i3DManager:loadI3DFileAsync(externalFilename, true, true, self.onLoadedMapI3DFiles, self, { callbackFunc, callbackTarget })
                        end
                    end)
                    externalXMLFile:delete()
                end
            end
        end
        i = i + 1
    end
    return numFiles
end
function Mission00:onLoadedMapI3DFiles(node, _, args)
    if node ~= 0 then
        unlink(node)
        table.insert(self.dynamicallyLoadedObjects, node)
    end
    args[1](args[2])
end
function Mission00:loadHotspots(xmlFile, customEnvironment)
    local i = XMLFile.wrap(xmlFile, Mission00.xmlSchema)
    local i = 0
    while true do
        local key = string.format("map.hotspots.placeableHotspot(%d)", i)
        if not i:hasProperty(key) then
            break
        end
        local hotspot = PlaceableHotspot.new()
        local text = i:getValue(key .. "#text", nil)
        if text == nil then
            Logging.xmlWarning(i, "Missing placeable hotspot name for \'%s\'", key)
            break
        end
        hotspot:setName(g_i18n:convertText(text, customEnvironment))
        hotspot:createIcon()
        local hotspotTypeName = i:getValue(key .. "#type", "UNLOADING")
        local hotspotType = PlaceableHotspot.getTypeByName(hotspotTypeName)
        if hotspotType == nil then
            Logging.xmlWarning(i, "Unknown placeable hotspot type \'%s\'. Falling back to type \'UNLOADING\'\nAvailable types: %s", hotspotTypeName, table.concatKeys(PlaceableHotspot.TYPE, " "))
            hotspotType = PlaceableHotspot.TYPE.UNLOADING
        end
        hotspot:setPlaceableType(hotspotType)
        local worldPositionX, worldPositionZ = i:getValue(key .. "#worldPosition", nil)
        if worldPositionX ~= nil then
            hotspot:setWorldPosition(worldPositionX, worldPositionZ)
        end
        local teleportX, teleportY, teleportZ = i:getValue(key .. "#teleportWorldPosition", nil)
        if teleportX ~= nil then
            hotspot:setTeleportWorldPosition(teleportX, math.max(teleportY, getTerrainHeightAtWorldPos(g_terrainNode, teleportX, 0, teleportZ)), teleportZ)
        end
        self:addMapHotspot(hotspot)
        table.insert(self.mapHotspots, hotspot)
        i = i + 1
    end
    i:delete()
end
function Mission00:onStartMission()
    Mission00:superClass().onStartMission(self)
    g_gameStateManager:setGameState(GameState.PLAY)
    g_achievementManager:loadMapData()
    g_currentMission.economyManager:restartGreatDemands()
    g_messageCenter:publish(MessageType.CURRENT_MISSION_START, not self.missionInfo.isValid)
    self.gameStarted = true
end
function Mission00:getIsTourSupported()
    if Profiler.IS_INITIALIZED then
        return false
    elseif self.missionInfo.startWithGuidedTour then
        return self.missionInfo.loadDefaultFarm and true or false
    else
        return false
    end
end
function Mission00:update(dt)
    Mission00:superClass().update(self, dt)
    if self:getIsServer() then
        g_autoSaveManager:update(dt)
        self.isSaving = g_savegameController:getIsSaving()
        if (GS_IS_CONSOLE_VERSION or GS_IS_MOBILE_VERSION) and not self.isSaving then
            self:tryUnpauseGame()
        end
    end
end
function Mission00:doPauseGame()
    Mission00:superClass().doPauseGame(self)
    self:showPauseDisplay(true)
end
function Mission00:doUnpauseGame()
    Mission00:superClass().doUnpauseGame(self)
    self:showPauseDisplay(false)
end
function Mission00:canUnpauseGame()
    return Mission00:superClass().canUnpauseGame(self) and not self.isSaving
end
function Mission00:draw()
    Mission00:superClass().draw(self)
    if self.missionDynamicInfo.isMultiplayer and self.gameStarted then
        self.hud:drawCommunicationDisplay()
    end
end
function Mission00:loadPlaceables(xmlFilename)
    if xmlFilename ~= nil and self:getIsServer() then
        self:startLoadingTask()
        self.placeableSystem:load(xmlFilename, self.onFinishedPlaceables, self)
    end
    g_asyncTaskManager:addSubtask(function()
        -- upvalues: (copy) self
        self:loadVehicles(self.missionInfo.vehiclesXMLLoad)
    end)
end
function Mission00:onFinishedPlaceables()
    g_farmManager:mergeObjectsForSingleplayer()
    self:finishLoadingTask()
    g_messageCenter:publish(MessageType.LOADED_ALL_SAVEGAME_PLACEABLES)
end
function Mission00:loadVehicles(xmlFilename)
    if xmlFilename ~= nil and self:getIsServer() then
        self:startLoadingTask()
        self.vehicleSystem:load(xmlFilename, self.onFinishedVehicles, self)
    end
    g_asyncTaskManager:addSubtask(function()
        -- upvalues: (copy) self
        self:loadHandTools(self.missionInfo.handToolsXMLLoad)
    end)
end
function Mission00:onFinishedVehicles(_, _, _)
    g_farmManager:mergeObjectsForSingleplayer()
    self:finishLoadingTask()
    g_messageCenter:publish(MessageType.LOADED_ALL_SAVEGAME_VEHICLES)
end
function Mission00:loadHandTools(xmlFilename)
    if self:getIsServer() then
        self:startLoadingTask()
        self.handToolSystem:load(xmlFilename, self.onFinishedHandTools, self)
    end
    g_asyncTaskManager:addSubtask(function()
        -- upvalues: (copy) self
        if self:getIsServer() then
            g_messageCenter:publish(MessageType.ENQUEUED_ALL_LOADINGS)
        end
        self:loadItems(self.missionInfo.itemsXMLLoad)
    end)
end
function Mission00:onFinishedHandTools()
    g_farmManager:mergeObjectsForSingleplayer()
    self:finishLoadingTask()
    g_messageCenter:publish(MessageType.LOADED_ALL_SAVEGAME_HANDTOOLS)
end
function Mission00:loadItems(xmlFilename, resetItems)
    if xmlFilename == nil then
        self:loadItemsFinished()
    else
        self:startLoadingTask()
        self.itemSystem:loadItems(xmlFilename, resetItems, self.missionInfo, self.missionDynamicInfo, self.loadItemsFinished, self, nil)
    end
end
function Mission00:loadItemsFinished()
    if self:getIsServer() then
        g_asyncTaskManager:addSubtask(function()
            g_farmManager:mergeObjectsForSingleplayer()
        end)
        g_asyncTaskManager:addSubtask(function()
            -- upvalues: (copy) self
            if self.missionInfo.onCreateObjectsXMLLoad ~= nil then
                self.onCreateObjectSystem:load(self.missionInfo.onCreateObjectsXMLLoad)
            end
        end)
        g_asyncTaskManager:addSubtask(function()
            -- upvalues: (copy) self
            self:finishLoadingTask()
        end)
    end
end
function Mission00.onCreateStartPoint(_, id)
    g_mission00StartPoint = id
end
function Mission00:addChatMessage(sender, msg, farmId, userId)
    local isAllowed = true
    if userId ~= nil then
        local user = self.userManager:getUserByUserId(userId, false)
        if user ~= nil then
            sender = user:getNickname()
            isAllowed = user:getAllowTextCommunication()
        end
    end
    if isAllowed then
        self.hud:addChatMessage(msg, sender, farmId)
    end
end
function Mission00:scrollChatMessages(delta)
    self.hud:scrollChatMessages(delta)
end
function Mission00:loadEconomy(xmlFilename)
    if self:getIsServer() then
        local xmlFile = loadXMLFile("economyXML", xmlFilename)
        g_currentMission.economyManager:loadFromXMLFile(xmlFile, "economy")
        delete(xmlFile)
    end
end
function Mission00:loadCompetitiveMultiplayer(xmlFile)
    local filename = getXMLString(xmlFile, "map.competitiveMultiplayer#filename")
    if filename ~= nil and self:getIsServer() then
        local farmXmlFile = Utils.getFilename(filename, self.baseDirectory)
        if not self.missionInfo.isValid then
            local farmXmlFile = loadXMLFile("CompetitiveXML", farmXmlFile)
            local i = 0
            while true do
                local farmKey = string.format("competitiveMultiplayer.farms.farm(%d)", i)
                if not hasXMLProperty(farmXmlFile, farmKey) then
                    break
                end
                local farmId = getXMLInt(farmXmlFile, farmKey .. "#farmId")
                local name = getXMLString(farmXmlFile, farmKey .. "#name")
                local color = getXMLInt(farmXmlFile, farmKey .. "#color")
                local farm = g_farmManager:createFarm(name, color, nil, farmId)
                if farm ~= nil then
                    farm.money = getXMLFloat(farmXmlFile, farmKey .. "#money") or farm.money
                    farm.loan = getXMLFloat(farmXmlFile, farmKey .. "#loan") or farm.loan
                end
                i = i + 1
            end
            delete(farmXmlFile)
        end
        self.missionInfo.isCompetitiveMultiplayer = true
    end
end