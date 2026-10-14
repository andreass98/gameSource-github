FruitTypeDesc = {}
local FruitTypeDesc_mt = Class(FruitTypeDesc)
g_xmlManager:addCreateSchemaFunction(function()
    FruitTypeDesc.xmlSchema = XMLSchema.new("foliageType")
    local xmlSchema = FruitTypeDesc.xmlSchema
    xmlSchema.supportsParentFile = false
    xmlSchema:register(XMLValueType.STRING, "foliageType.fruitType#name")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.fruitType#shownOnMap")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.fruitType#useForFieldMissions")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.fruitType#isCatchCrop")
    xmlSchema:register(XMLValueType.VECTOR_4, "foliageType.fruitType.mapColors#default")
    xmlSchema:register(XMLValueType.VECTOR_4, "foliageType.fruitType.mapColors#colorBlind")
    xmlSchema:register(XMLValueType.STRING, "foliageType.fruitType.windrow#fillType")
    xmlSchema:register(XMLValueType.STRING, "foliageType.fruitType.windrow#cutFillType")
    xmlSchema:register(XMLValueType.FLOAT, "foliageType.fruitType.windrow#windrowCutFactor", "Additional yield factor while threshing the windrows", 1)
    xmlSchema:register(XMLValueType.FLOAT, "foliageType.fruitType.windrow#litersPerSqm")
    xmlSchema:register(XMLValueType.STRING, "foliageType.fruitType.harvest#chopperType")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.fruitType.harvest#chopperUseHaulm", "true if chopper should use haulm layer instead of chopper spray type")
    xmlSchema:register(XMLValueType.STRING, "foliageType.fruitType.harvest#groundType")
    xmlSchema:register(XMLValueType.FLOAT, "foliageType.fruitType.harvest#litersPerSqm")
    xmlSchema:register(XMLValueType.FLOAT, "foliageType.fruitType.harvest#cutHeight")
    xmlSchema:register(XMLValueType.FLOAT, "foliageType.fruitType.harvest#forageCutHeight")
    xmlSchema:register(XMLValueType.FLOAT, "foliageType.fruitType.harvest#beeYieldBonusPercentage")
    xmlSchema:register(XMLValueType.STRING, "foliageType.fruitType.harvest.transition(?)#src")
    xmlSchema:register(XMLValueType.STRING, "foliageType.fruitType.harvest.transition(?)#target")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.fruitType.growth#resetsSpray")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.fruitType.growth#growthRequiresLime")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.fruitType.soil#lowDensityRequired")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.fruitType.soil#increasesDensity")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.fruitType.soil#consumesLime")
    xmlSchema:register(XMLValueType.INT, "foliageType.fruitType.soil#startSprayLevel")
    xmlSchema:register(XMLValueType.INT, "foliageType.fruitType.seeding#directionSnapAngle")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.fruitType.seeding#needsRolling")
    xmlSchema:register(XMLValueType.FLOAT, "foliageType.fruitType.seeding#litersPerSqm")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.fruitType.seeding#isAvailable")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.fruitType.seeding#plantsWeed")
    xmlSchema:register(XMLValueType.STRING, "foliageType.fruitType.seeding#defaultSowingGroundType")
    FieldType.registerXMLPath(xmlSchema, "foliageType.fruitType.seeding#requiredFieldType", "Name of the field type", nil, false)
    xmlSchema:register(XMLValueType.BOOL, "foliageType.fruitType.cultivation#isAllowed")
    xmlSchema:register(XMLValueType.STRING, "foliageType.fruitType.mulcher#chopperType")
    xmlSchema:register(XMLValueType.STRING, "foliageType.fruitType.haulm#layerName")
    xmlSchema:register(XMLValueType.STRING, "foliageType.foliageLayer(?)#name")
    xmlSchema:register(XMLValueType.STRING, "foliageType.foliageLayer(?)#distanceTexturePath", "optional path for distance textures")
    xmlSchema:register(XMLValueType.INT, "foliageType.foliageLayer(?)#densityMapChannelOffset")
    xmlSchema:register(XMLValueType.INT, "foliageType.foliageLayer(?)#numDensityMapChannels")
    xmlSchema:register(XMLValueType.FLOAT, "foliageType.foliageLayer(?)#numBlocksPerUnit", "default number of blocks per unit (rounded)")
    xmlSchema:register(XMLValueType.VECTOR_2, "foliageType.foliageLayer(?)#plantOffset", "default X/Z offset for plant layout, in meters")
    xmlSchema:register(XMLValueType.VECTOR_2, "foliageType.foliageLayer(?)#plantSeparation", "default X/Z separation for plant layout, in meters (not rounded) - overrides numBlocksPerUnit")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer(?)#plantLayoutRotation", "allows the plant layout to rotate with the field - requires plantSeparation to be used instead of numBlocksPerUnit")
    xmlSchema:register(XMLValueType.STRING, "foliageType.foliageLayer(?)#shapeSource")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer(?)#debugMesh")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer(?)#alignsToSun")
    for _, elementName in ipairs({ "foliageStateDefaults", "foliageState(?)" }) do
        xmlSchema:register(XMLValueType.INT, "foliageType.foliageLayer(?)." .. elementName .. "#distanceMapLayer")
        xmlSchema:register(XMLValueType.FLOAT, "foliageType.foliageLayer(?)." .. elementName .. "#width")
        xmlSchema:register(XMLValueType.FLOAT, "foliageType.foliageLayer(?)." .. elementName .. "#height")
        xmlSchema:register(XMLValueType.FLOAT, "foliageType.foliageLayer(?)." .. elementName .. "#widthVariance")
        xmlSchema:register(XMLValueType.FLOAT, "foliageType.foliageLayer(?)." .. elementName .. "#heightVariance")
        xmlSchema:register(XMLValueType.FLOAT, "foliageType.foliageLayer(?)." .. elementName .. "#horizontalPositionVariance")
        xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer(?)." .. elementName .. "#debugMesh")
        xmlSchema:register(XMLValueType.FLOAT, "foliageType.foliageLayer(?)." .. elementName .. "#numBlocksPerUnit", "number of blocks per unit (rounded)")
        xmlSchema:register(XMLValueType.VECTOR_2, "foliageType.foliageLayer(?)." .. elementName .. "#plantOffset", "X/Z offset for plant layout, in meters")
        xmlSchema:register(XMLValueType.VECTOR_2, "foliageType.foliageLayer(?)." .. elementName .. "#plantSeparation", "X/Z separation for plant layout, in meters (not rounded) - overrides numBlocksPerUnit")
        xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer(?)." .. elementName .. "#plantLayoutRotation", "allows the plant layout to rotate with the field - requires plantSeparation to be used instead of numBlocksPerUnit")
    end
    xmlSchema:register(XMLValueType.INT, "foliageType.foliageLayer(?).foliageLodDefaults(?)#lod")
    for _, elementName in ipairs({ "foliageLodDefaults", "foliageState(?).foliageShape(?).foliageLod(?)" }) do
        xmlSchema:register(XMLValueType.INT, "foliageType.foliageLayer(?)." .. elementName .. "#viewDistance")
        xmlSchema:register(XMLValueType.INT, "foliageType.foliageLayer(?)." .. elementName .. "#blendOutDistance")
        xmlSchema:register(XMLValueType.INT, "foliageType.foliageLayer(?)." .. elementName .. "#atlasSize")
        xmlSchema:register(XMLValueType.VECTOR_2, "foliageType.foliageLayer(?)." .. elementName .. "#atlasOffset")
        xmlSchema:register(XMLValueType.VECTOR_4, "foliageType.foliageLayer(?)." .. elementName .. "#texCoords")
        xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer(?)." .. elementName .. "#debugMesh")
    end
    xmlSchema:register(XMLValueType.STRING, "foliageType.foliageLayer(?).foliageState(?)#name")
    xmlSchema:register(XMLValueType.FLOAT, "foliageType.foliageLayer(?).foliageState(?)#numBlocksPerUnit")
    xmlSchema:register(XMLValueType.STRING, "foliageType.foliageLayer(?).foliageState(?)#distanceMap")
    xmlSchema:register(XMLValueType.FLOAT, "foliageType.foliageLayer.foliageState(?)#yieldScale")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isGrowing")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#allowsWeeding")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#allowsHoeing")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isPreparable")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isPrepared")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isHarvestReady")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isForageReady")
    xmlSchema:register(XMLValueType.STRING, "foliageType.foliageLayer.foliageState(?)#groundType")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isCut")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isWithered")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isDestructibleByWheel", "Whether this state can be destructed by wheels, defines a range from first to last state where this is set to true")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isDestructedByWheel", "If wheel destruction occurs for the fruitType change to this state, can only be set for one state")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isDestructibleByDisaster", "Whether this state can be destructed by disaster, defines a range from first to last state where this is set to true")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isDestructedByDisaster", "If disaster occurs for the fruitType change to this state, can only be set for one state")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#cullCropsBelowFillHeight", "Foliage shape will be culled if tipAny/fillHeight at the pixel is higher than the LOD0", false)
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#regrowthStart")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isMulched")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isRolledCut")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isWeed")
    xmlSchema:register(XMLValueType.BOOL, "foliageType.foliageLayer.foliageState(?)#isCultivatable")
    xmlSchema:register(XMLValueType.FLOAT, "foliageType.foliageLayer.foliageState(?)#minWaterLitersPerSqm", "Minimum water level in liters per squaremeter required for the state to grow without a yield reduction")
    xmlSchema:register(XMLValueType.FLOAT, "foliageType.foliageLayer.foliageState(?)#maxWaterLitersPerSqm", "Maximum water level in liters per squaremeter required for the state to grow without a yield reduction")
    xmlSchema:register(XMLValueType.STRING, "foliageType.foliageLayer.foliageState(?)#penaltyStateName", "Name of the foliage state to change to if water level was incorrect")
    xmlSchema:register(XMLValueType.FLOAT, "foliageType.foliageLayer.foliageState(?)#penaltyPercentage", "Percentage of foliage to convert to penalty foliage if water level was incorrect")
    xmlSchema:register(XMLValueType.STRING_LIST, "foliageType.foliageLayer.foliageState(?)#groundTypeMask", "Space separated list of ground type names")
    xmlSchema:register(XMLValueType.FLOAT, "foliageType.foliageLayer.foliageState(?)#fieldCourseLineHeight", "Height of the field course lines if this growth state is on the field", 0.15)
    xmlSchema:register(XMLValueType.FLOAT, "foliageType.foliageLayer(?).foliageState(?).foliageShape(?)#probability")
    xmlSchema:register(XMLValueType.NODE_INDEX, "foliageType.foliageLayer(?).foliageState(?).foliageShape(?).foliageLod(?)#blockShape")
    xmlSchema:register(XMLValueType.STRING, "foliageType.growth.seasonal#initialState")
    xmlSchema:register(XMLValueType.STRING, "foliageType.growth.seasonal.period(?)#name")
    xmlSchema:register(XMLValueType.STRING, "foliageType.growth.seasonal.period(?)#plantingAllowed")
    for _, elementName in ipairs({ "seasonal.period(?)", "nonSeasonal" }) do
        xmlSchema:register(XMLValueType.STRING, "foliageType.growth." .. elementName .. ".update(?)#startState")
        xmlSchema:register(XMLValueType.STRING, "foliageType.growth." .. elementName .. ".update(?)#endState")
    end
end)
function FruitTypeDesc.new(customMt)
    -- upvalues: (copy) FruitTypeDesc_mt
    local self = setmetatable({}, customMt or FruitTypeDesc_mt)
    self.index = nil
    self.modifier = nil
    self.name = nil
    self.layerName = nil
    self.shownOnMap = false
    self.useForFieldMissions = true
    self.missionMultiplier = 1
    self.growthStateToName = {}
    self.nameToGrowthState = {}
    self.startStateChannel = 0
    self.numStateChannels = 4
    self.startStateChannelHaulm = 0
    self.numStateChannelsHaulm = 1
    self.alignsToSun = false
    self.plantSpacing = 1
    self.fillType = nil
    self.defaultSowingGroundType = nil
    self.isCatchCrop = false
    self.yieldScales = {}
    self.minHarvestingGrowthState = 0
    self.maxHarvestingGrowthState = 0
    self.minForageGrowthState = 0
    self.maxForageGrowthState = 0
    self.cutState = 0
    self.cutStates = {}
    self.witheredState = nil
    self.harvestWeedState = -1
    self.mulchedState = 0
    self.rolledCutState = 0
    self.minWheelDestructionState = nil
    self.maxWheelDestructionState = nil
    self.wheelDestructionState = nil
    self.minDisasterDestructionState = nil
    self.maxDisasterDestructionState = nil
    self.disasterDestructionState = 0
    self.minPreparingGrowthState = -1
    self.maxPreparingGrowthState = -1
    self.preparedGrowthState = -1
    self.groundTypeChangeGrowthState = -1
    self.groundTypeChangeType = nil
    self.groundTypeChangeMaskTypes = {}
    self.minWeederState = 0
    self.maxWeederState = 0
    self.minWeederHoeState = 0
    self.maxWeederHoeState = 0
    self.regrows = false
    self.firstRegrowthState = 1
    return self
end
function FruitTypeDesc:loadFromFoliageXMLFile(xmlFilename)
    local xmlFile = XMLFile.load("foliageXml", xmlFilename)
    if xmlFile == nil then
        return false
    end
    local name = xmlFile:getString("foliageType.fruitType#name")
    if name == nil then
        Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: Missing fruitType name")
        xmlFile:delete()
        return false
    end
    if not ClassUtil.getIsValidIndexName(name) then
        Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: \'%s\' is not a valid name for a fruitType. Ignoring fruitType!", self.name)
        xmlFile:delete()
        return false
    end
    local upperName = string.upper(name)
    self.xmlFilename = xmlFilename
    self.name = upperName
    self.layerName = name
    local fillType = g_fillTypeManager:getFillTypeByName(upperName)
    if fillType == nil then
        Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: Missing fillType \'%s\' for fruitType definition. Ignoring fruitType!", name)
        xmlFile:delete()
        return false
    end
    self.fillType = fillType
    self.shownOnMap = xmlFile:getBool("foliageType.fruitType#shownOnMap", true)
    self.useForFieldMissions = xmlFile:getBool("foliageType.fruitType#useForFieldMissions", true)
    self.missionMultiplier = xmlFile:getFloat("foliageType.fruitType#missionMultiplier", 1)
    self.isCatchCrop = xmlFile:getBool("foliageType.fruitType#isCatchCrop")
    self.defaultMapColor = Color.parseFromString(xmlFile:getString("foliageType.fruitType.mapColors#default", "1 1 1 1"))
    self.colorBlindMapColor = Color.parseFromString(xmlFile:getString("foliageType.fruitType.mapColors#colorBlind", "1 1 1 1"))
    self.startStateChannel = xmlFile:getInt("foliageType.foliageLayer(0)#densityMapChannelOffset", 0)
    self.numStateChannels = xmlFile:getInt("foliageType.foliageLayer(0)#numDensityMapChannels", 4)
    self.alignsToSun = xmlFile:getBool("foliageType.foliageLayer(0)#alignsToSun", false)
    self.numBlocksPerUnit = xmlFile:getFloat("foliageType.foliageLayer(0)#numBlocksPerUnit")
    self.plantSeparation = xmlFile:getVector("foliageType.foliageLayer(0)#plantSeparation", nil, 2)
    self.plantOffset = xmlFile:getVector("foliageType.foliageLayer(0)#plantOffset", nil, 2)
    self:updatePlantSpacing()
    local startStateChannelHaulm = xmlFile:getInt("foliageType.foliageLayer(1)#densityMapChannelOffset", nil)
    if startStateChannelHaulm ~= nil then
        self.startStateChannelHaulm = startStateChannelHaulm - self.numStateChannels
        self.numStateChannelsHaulm = xmlFile:getInt("foliageType.foliageLayer(1)#numDensityMapChannels", 1)
    end
    self.fieldCourseLineHeightByGrowthState = {}
    local numGrowthStates = 0
    local hasProhibitedCultivationStates = false
    for k, foliageStateKey in xmlFile:iterator("foliageType.foliageLayer(0).foliageState") do
        local foliageStateName = xmlFile:getString(foliageStateKey .. "#name")
        self.growthStateToName[k] = foliageStateName
        self.nameToGrowthState[string.upper(foliageStateName)] = k
        if xmlFile:getBool(foliageStateKey .. "#isHarvestReady") then
            if self.minHarvestingGrowthState == 0 then
                self.minHarvestingGrowthState = k
            end
            self.maxHarvestingGrowthState = k
            self.yieldScales[k] = xmlFile:getFloat(foliageStateKey .. "#yieldScale", 1)
        end
        if xmlFile:getBool(foliageStateKey .. "#isForageReady") then
            if self.minForageGrowthState == 0 then
                self.minForageGrowthState = k
            end
            self.maxForageGrowthState = k
        end
        if xmlFile:getBool(foliageStateKey .. "#isCut") then
            self.cutStates[k] = true
            self.cutState = k
        end
        if xmlFile:getBool(foliageStateKey .. "#isWithered") then
            if self.witheredState ~= nil then
                Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: WitheredState already defined for foliage state \'%s\'. Overwriting it with \'%s\'!", self.growthStateToName[self.witheredState], foliageStateName)
            end
            self.witheredState = k
        end
        if xmlFile:getBool(foliageStateKey .. "#isGrowing") then
        end
        local groundTypeName = xmlFile:getString(foliageStateKey .. "#groundType")
        if groundTypeName ~= nil then
            local groundType = FieldGroundType.getByName(groundTypeName)
            if groundType == nil then
                Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: Invalid groundType name \'%s\' for foliage state \'%s\'. Ignoring it!", groundTypeName, foliageStateName)
            else
                if self.groundTypeChangeGrowthState ~= -1 then
                    Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: GroundType change already defined for foliage state \'%s\'. Overwriting it with \'%s\'!", self.growthStateToName[self.groundTypeChangeGrowthState], foliageStateName)
                end
                self.groundTypeChangeGrowthState = k
                self.groundTypeChangeType = groundType
            end
        end
        local groundType = xmlFile:getString(foliageStateKey .. "#groundTypeMask")
        if groundType ~= nil then
            local groundTypeChangeMaskList = groundType:split(" ")
            for _, groundTypeMaskName in ipairs(groundTypeChangeMaskList) do
                local groundType = FieldGroundType.getByName(groundTypeMaskName)
                if groundType == nil then
                    Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: Invalid groundTypeChangeMask name \'%s\' for foliage state \'%s\'. Ignoring it!", groundTypeMaskName, foliageStateName)
                else
                    table.insert(self.groundTypeChangeMaskTypes, groundType)
                end
            end
        end
        if xmlFile:getBool(foliageStateKey .. "#allowsWeeding") then
            if self.minWeederState == 0 then
                self.minWeederState = k
            end
            self.maxWeederState = k
        end
        if xmlFile:getBool(foliageStateKey .. "#allowsHoeing") then
            if self.minWeederHoeState == 0 then
                self.minWeederHoeState = k
            end
            self.maxWeederHoeState = k
        end
        if xmlFile:getBool(foliageStateKey .. "#regrowthStart") then
            if self.regrows then
                Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: RegrowthStart already defined for foliage state \'%s\'. Overwriting it with \'%s\'!", self.growthStateToName[self.firstRegrowthState], foliageStateName)
            end
            self.firstRegrowthState = k
            self.regrows = true
        end
        if xmlFile:getBool(foliageStateKey .. "#isDestructibleByWheel") then
            if self.minWheelDestructionState == nil then
                self.minWheelDestructionState = k
            end
            self.maxWheelDestructionState = k
        end
        if xmlFile:getBool(foliageStateKey .. "#isDestructedByWheel") then
            if self.wheelDestructionState ~= nil then
                Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: Wheel destructed state already defined for foliage state \'%s\'. Overwriting it with \'%s\'!", self.growthStateToName[self.wheelDestructionState], foliageStateName)
            end
            self.wheelDestructionState = k
        end
        if xmlFile:getBool(foliageStateKey .. "#isDestructibleByDisaster") then
            if self.minDisasterDestructionState == nil then
                self.minDisasterDestructionState = k
            end
            self.maxDisasterDestructionState = k
        end
        if xmlFile:getBool(foliageStateKey .. "#isDestructedByDisaster") then
            if self.disasterDestructionState ~= 0 then
                Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: Disaster destructed state already defined for foliage state \'%s\'. Overwriting it with \'%s\'!", self.growthStateToName[self.disasterDestructionState], foliageStateName)
            end
            self.disasterDestructionState = k
        end
        if xmlFile:getBool(foliageStateKey .. "#isPreparable") then
            if self.minPreparingGrowthState == -1 then
                self.minPreparingGrowthState = k
            end
            self.maxPreparingGrowthState = k
        end
        if xmlFile:getBool(foliageStateKey .. "#isPrepared") then
            if self.preparedGrowthState ~= -1 then
                Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: Prepared state already defined for foliage state \'%s\'. Overwriting it with \'%s\'!", self.growthStateToName[self.preparedGrowthState], foliageStateName)
            end
            self.preparedGrowthState = k
        end
        if xmlFile:getBool(foliageStateKey .. "#isWeed") then
            if self.harvestWeedState ~= -1 then
                Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: Harvested weed state already defined for foliage state \'%s\'. Overwriting it with \'%s\'!", self.growthStateToName[self.harvestWeedState], foliageStateName)
            end
            self.harvestWeedState = k
        end
        if xmlFile:getBool(foliageStateKey .. "#isMulched") then
            if self.mulchedState ~= 0 then
                Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: Mulched state already defined for foliage state \'%s\'. Overwriting it with \'%s\'!", self.growthStateToName[self.mulchedState], foliageStateName)
            end
            self.mulchedState = k
        end
        if xmlFile:getBool(foliageStateKey .. "#isRolledCut") then
            if self.rolledCutState ~= 0 then
                Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: Rolled cut state already defined for foliage state \'%s\'. Overwriting it with \'%s\'!", self.growthStateToName[self.rolledCutState], foliageStateName)
            end
            self.rolledCutState = k
        end
        if xmlFile:getBool(foliageStateKey .. "#isCultivatable", true) then
            table.insert({}, k)
        else
            hasProhibitedCultivationStates = true
        end
        local groundTypeChangeMaskList = xmlFile:getFloat(foliageStateKey .. "#minWaterLitersPerSqm")
        if groundTypeChangeMaskList ~= nil then
            self.minWaterLitersPerSqm = self.minWaterLitersPerSqm or {}
            self.minWaterLitersPerSqm[k] = groundTypeChangeMaskList
        end
        local maxWaterLitersPerSqm = xmlFile:getFloat(foliageStateKey .. "#maxWaterLitersPerSqm")
        if maxWaterLitersPerSqm ~= nil then
            self.maxWaterLitersPerSqm = self.maxWaterLitersPerSqm or {}
            self.maxWaterLitersPerSqm[k] = maxWaterLitersPerSqm
        end
        local penaltyStateName = xmlFile:getString(foliageStateKey .. "#penaltyStateName")
        if penaltyStateName ~= nil then
            self.penaltyStateName = self.penaltyStateName or {}
            self.penaltyStateName[k] = penaltyStateName
        end
        local penaltyPercentage = xmlFile:getFloat(foliageStateKey .. "#penaltyPercentage")
        if penaltyPercentage ~= nil then
            self.penaltyPercentage = self.penaltyPercentage or {}
            self.penaltyPercentage[k] = penaltyPercentage
        end
        self.fieldCourseLineHeightByGrowthState[k] = xmlFile:getFloat(foliageStateKey .. "#fieldCourseLineHeight")
    end
    self.numGrowthStates = numGrowthStates
    self.numFoliageStates = #self.growthStateToName
    if hasProhibitedCultivationStates then
        self.cultivationStates = cultivationStates
    end
    if self.maxWheelDestructionState ~= nil and self.wheelDestructionState == nil then
        Logging.xmlWarning(xmlFile, "Fruit has states where \'isDestructibleByWheel\' is true but does not specify a state where \'isDestructedByWheel\' (state to change to when destruction occurs) is true")
        self.minWheelDestructionState = nil
        self.maxWheelDestructionState = nil
    end
    if self.maxDisasterDestructionState ~= nil and self.disasterDestructionState == nil then
        Logging.xmlWarning(xmlFile, "Fruit has states where \'isDestructibleByDisaster\' is true but does not specify a state where \'isDestructedByDisaster\' (state to change to when disaster occurs) is true")
        self.minDisasterDestructionState = nil
        self.maxDisasterDestructionState = nil
    end
    self.literPerSqm = xmlFile:getFloat("foliageType.fruitType.harvest#litersPerSqm", 0)
    self.cutHeight = xmlFile:getFloat("foliageType.fruitType.harvest#cutHeight", 0.15)
    self.forageCutHeight = xmlFile:getFloat("foliageType.fruitType.harvest#forageCutHeight", self.forageCutHeight)
    self.beeYieldBonusPercentage = xmlFile:getFloat("foliageType.fruitType.harvest#beeYieldBonusPercentage", 0)
    local harvestGroundTypeName = xmlFile:getString("foliageType.fruitType.harvest#groundType")
    if harvestGroundTypeName ~= nil then
        local groundType = FieldGroundType.getByName(harvestGroundTypeName)
        if groundType == nil then
            Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: Invalid harvest ground type name \'%s\'", harvestGroundTypeName)
        else
            self.harvestGroundType = groundType
        end
    end
    local groundType = xmlFile:getString("foliageType.fruitType.harvest#chopperType")
    if groundType ~= nil then
        local chopperType = FieldChopperType.getByName(groundType)
        if chopperType == nil then
            Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: Invalid chopperType name \'%s\'", groundType)
        else
            self.chopperType = chopperType
        end
    end
    self.chopperUseHaulm = xmlFile:getBool("foliageType.fruitType.harvest#chopperUseHaulm", false)
    self.resetsSpray = xmlFile:getBool("foliageType.fruitType.growth#resetsSpray", true)
    self.growthRequiresLime = xmlFile:getBool("foliageType.fruitType.growth#requiresLime", true)
    self.increasesSoilDensity = xmlFile:getBool("foliageType.fruitType.soil#increasesDensity", false)
    self.lowSoilDensityRequired = xmlFile:getBool("foliageType.fruitType.soil#lowDensityRequired", true)
    self.consumesLime = xmlFile:getBool("foliageType.fruitType.soil#consumesLime", true)
    self.startSprayLevel = xmlFile:getInt("foliageType.fruitType.soil#startSprayLevel", 0)
    self.seedUsagePerSqm = xmlFile:getFloat("foliageType.fruitType.seeding#litersPerSqm", 0.1)
    self.allowsSeeding = xmlFile:getBool("foliageType.fruitType.seeding#isAvailable", true)
    self.needsRolling = xmlFile:getBool("foliageType.fruitType.seeding#needsRolling", true)
    local k = xmlFile:getFloat("foliageType.fruitType.seeding#directionSnapAngle", 0)
    self.directionSnapAngle = math.rad(k)
    self.plantsWeed = xmlFile:getBool("foliageType.fruitType.seeding#plantsWeed", true)
    self.defaultSowingGroundType = xmlFile:getString("foliageType.fruitType.seeding#defaultSowingGroundType")
    local chopperType = xmlFile:getString("foliageType.fruitType.seeding#requiredFieldType", nil)
    self.seedRequiredFieldType = FieldType.getByName(chopperType) or self.seedRequiredFieldType
    self.isCultivationAllowed = xmlFile:getBool("foliageType.fruitType.cultivation#isAllowed", true)
    self.limitDestructionToField = xmlFile:getBool("foliageType.fruitType.destruction#limitToField", true)
    local foliageStateKey = xmlFile:getString("foliageType.fruitType.windrow#fillType")
    if foliageStateKey ~= nil then
        local foliageStateName = g_fillTypeManager:getFillTypeByName(foliageStateKey)
        if foliageStateName == nil then
            Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: FruitType windrow fillType \'%s\' not defined for \'%s\'. Ignoring windrow!", foliageStateKey, "foliageType.fruitType")
        else
            self.hasWindrow = true
            self.windrowFillType = foliageStateName
            self.windrowName = foliageStateName.name
        end
    end
    local foliageStateName = xmlFile:getString("foliageType.fruitType.windrow#cutFillType")
    if foliageStateName ~= nil then
        local groundTypeName = g_fillTypeManager:getFillTypeByName(foliageStateName)
        if groundTypeName == nil then
            Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: FruitType windrow cut fillType \'%s\' not defined for \'%s\'. Ignoring windrow!", foliageStateName, "foliageType.fruitType")
        else
            self.windrowCutFillType = groundTypeName
            self.windrowCutFactor = xmlFile:getFloat("foliageType.fruitType.windrow#windrowCutFactor", 1)
        end
    end
    self.windrowLiterPerSqm = xmlFile:getFloat("foliageType.fruitType.windrow#litersPerSqm")
    local groundTypeName = xmlFile:getString("foliageType.fruitType.mulcher#chopperType")
    if groundTypeName ~= nil then
        local groundType = FieldChopperType.getByName(groundTypeName)
        if groundType == nil then
            Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: Invalid mulcher chopperTypeName name \'%s\'", groundTypeName)
        else
            self.mulcherChopperType = groundType
        end
    end
    self.haulmLayerName = xmlFile:getString("foliageType.fruitType.haulm#layerName")
    local groundType = nil
    for penaltyPercentage, _ in xmlFile:iterator("foliageType.fruitType.harvest.transition") do
        local groundTypeMaskName = xmlFile:getString(_ .. "#src")
        local groundType = xmlFile:getString(_ .. "#target")
        local srcState = self:getGrowthStateByName(groundTypeMaskName)
        if srcState == nil then
            Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: foliage state \'%s\' is not defined for harvest transition \'%s\'", groundTypeMaskName, _)
            break
        end
        local targetState = self:getGrowthStateByName(groundType)
        if targetState == nil then
            Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadFromFoliageXMLFile: foliage state \'%s\' is not defined for harvest transition \'%s\'", groundType, _)
            break
        end
        if srcState ~= nil and targetState ~= nil then
            groundType = groundType == nil and {} or groundType
            groundType[srcState] = targetState
        end
    end
    if groundType == nil then
        if self.minForageGrowthState ~= 0 then
            local penaltyStateName = self.minForageGrowthState
            for penaltyStateName = penaltyStateName, self.maxForageGrowthState do
                ({})[penaltyStateName] = self.cutState
            end
        end
        if self.minHarvestingGrowthState ~= 0 then
            local penaltyStateName = self.minHarvestingGrowthState
            for penaltyStateName = penaltyStateName, self.maxHarvestingGrowthState do
                groundType[penaltyStateName] = self.cutState
            end
        end
    end
    local groundTypeChangeMaskList = {}
    if self.minHarvestingGrowthState ~= 0 then
        local penaltyPercentage = self.minHarvestingGrowthState
        for penaltyPercentage = penaltyPercentage, self.maxHarvestingGrowthState do
            groundTypeChangeMaskList[penaltyPercentage] = self.cutState
        end
    end
    self.harvestTransitions = groundType
    self.harvestReadyTransitions = groundTypeChangeMaskList
    self:loadGrowth(xmlFile, "foliageType.growth")
    xmlFile:delete()
    return true
end
function FruitTypeDesc:loadGrowth(xmlFile, key)
    local maxStates = #self.growthStateToName
    if Platform.gameplay.supportSeasonalGrowth then
        local seasonalKey = key .. ".seasonal"
        local initialStateName = xmlFile:getString(seasonalKey .. "#initialState")
        local initialState = nil
        if initialStateName ~= nil then
            initialState = self:getGrowthStateByName(initialStateName)
            if initialState == nil then
                Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadGrowth: Initial state \'%s\' not defined", initialStateName)
            end
        end
        local growthDataSeasonal = {
            ["initialState"] = initialState,
            ["periods"] = {}
        }
        for _, periodKey in xmlFile:iterator(seasonalKey .. ".period") do
            local periodName = xmlFile:getString(periodKey .. "#name")
            local period = SeasonPeriod.getByName(periodName)
            if period == nil then
                Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadGrowth: Period name \'%s\' not defined", periodName)
            end
            local growthMapping = {}
            local state = 1
            for state = state, maxStates do
                growthMapping[state] = state
            end
            for _, updateKey in xmlFile:iterator(periodKey .. ".update") do
                local startStateName = xmlFile:getString(updateKey .. "#startState")
                local startState = self:getGrowthStateByName(startStateName)
                if startState == nil then
                    Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadGrowth: Period \'%s\' update startState \'%s\' not defined", periodName, startStateName)
                    break
                end
                local endStateName = xmlFile:getString(updateKey .. "#endState")
                local endState = self:getGrowthStateByName(endStateName)
                if endState == nil then
                    Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadGrowth: Period \'%s\' update endState \'%s\' not defined", periodName, endStateName)
                    break
                end
                growthMapping[startState] = endState
            end
            local periodInfo = {
                ["isHarvestable"] = false,
                ["growthMapping"] = growthMapping,
                ["plantingAllowed"] = xmlFile:getBool(periodKey .. "#plantingAllowed", false)
            }
            growthDataSeasonal.periods[period] = periodInfo
        end
        local period = 1
        local state = 12
        for period = period, state do
            local _ = growthDataSeasonal.periods[period]
            if _ ~= nil and _.plantingAllowed then
                local periodKey = 1
                local growthMapping = 0
                local period = 1
                for growthMapping = growthMapping, 24, period do
                    local currentPeriodInfo = growthDataSeasonal.periods[(period + growthMapping - 1) % 12 + 1]
                    if self:getIsHarvestReady(periodKey) or self:getIsPreparable(periodKey) then
                        currentPeriodInfo.isHarvestable = true
                    elseif periodKey == maxStates then
                        break
                    end
                    periodKey = currentPeriodInfo.growthMapping[periodKey]
                end
            end
        end
        self.growthDataSeasonal = growthDataSeasonal
    end
    local seasonalKey = key .. ".nonSeasonal"
    if xmlFile:hasProperty(seasonalKey) then
        local initialStateName = {}
        local state = 1
        for state = state, maxStates do
            initialStateName[state] = state
        end
        for _, period in xmlFile:iterator(seasonalKey .. ".update") do
            local _ = xmlFile:getString(period .. "#startState")
            local periodKey = self:getGrowthStateByName(_)
            if periodKey == nil then
                Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadGrowth: Non-seasonal update startState \'%s\' not defined", _)
                break
            end
            local periodName = xmlFile:getString(period .. "#endState")
            local period = self:getGrowthStateByName(periodName)
            if period == nil then
                Logging.xmlWarning(xmlFile, "FruitTypeDesc.loadGrowth: Non-seasonal update endState \'%s\' not defined", periodName)
                break
            end
            initialStateName[periodKey] = period
        end
        self.growthDataNonSeasonal = {
            ["growthMapping"] = initialStateName
        }
    end
end
function FruitTypeDesc:delete() end
function FruitTypeDesc:setTerrainDataPlane(id)
    self.terrainDataPlaneId = id
    self:updatePlantSpacing()
end
function FruitTypeDesc:setTerrainDataPlaneIndex(index)
    self.terrainDataPlaneIndex = index
end
function FruitTypeDesc:setTerrainDataPlaneHaulm(id)
    self.terrainDataPlaneIdHaulm = id
end
function FruitTypeDesc:setTerrainDataPlaneHaulmIndex(index)
    self.terrainDataPlaneHaulmIndex = index
end
function FruitTypeDesc:setFoliageTransformGroup(id)
    self.foliageTransformGroupId = id
end
function FruitTypeDesc:getDataPlaneInfo()
    return self.terrainDataPlaneId, self.startStateChannel, self.numStateChannels
end
function FruitTypeDesc:updatePlantSpacing()
    if self.plantSeparation == nil then
        if self.numBlocksPerUnit ~= nil then
            local cellSize = 16
            if self.terrainDataPlaneId ~= nil then
                cellSize = getFoliageGraphicsCellSize(self.terrainDataPlaneId)
            end
            local plantsPerCell = math.floor(cellSize * self.numBlocksPerUnit)
            if plantsPerCell ~= 0 then
                self.plantSpacing = cellSize / plantsPerCell
            end
        end
    else
        self.plantSpacing = self.plantSeparation[1]
        return
    end
end
function FruitTypeDesc:getModifier()
    if self.modifier == nil and self.terrainDataPlaneId ~= nil then
        self.modifier = DensityMapModifier.new(self.terrainDataPlaneId, self.startStateChannel, self.numStateChannels, g_terrainNode)
    end
    return self.modifier
end
function FruitTypeDesc:getHaulmModifier()
    if self.haulmModifier == nil and self.terrainDataPlaneIdHaulm ~= nil then
        self.haulmModifier = DensityMapModifier.new(self.terrainDataPlaneIdHaulm, self.startStateChannelHaulm, self.numStateChannelsHaulm, g_terrainNode)
    end
    return self.haulmModifier
end
function FruitTypeDesc:getFilter()
    if self.filter == nil and self.terrainDataPlaneId ~= nil then
        self.filter = DensityMapFilter.new(self.terrainDataPlaneId, self.startStateChannel, self.numStateChannels)
    end
    return self.filter
end
function FruitTypeDesc:getLayerName()
    return self.layerName
end
function FruitTypeDesc:getHaulmLayerName()
    return self.haulmLayerName
end
function FruitTypeDesc:getGrowthStateName(state)
    return self.growthStateToName[state]
end
function FruitTypeDesc:getGrowthStateByName(name)
    if name then
        name = string.upper(name)
    end
    return self.nameToGrowthState[name]
end
function FruitTypeDesc:getGrowthStateGroundType(growthState)
    if self.groundTypeChangeGrowthState == -1 or self.groundTypeChangeGrowthState > growthState then
        return nil
    else
        return self.groundTypeChangeType
    end
end
function FruitTypeDesc:getSeasonalGrowthData()
    return self.growthDataSeasonal
end
function FruitTypeDesc:getNonSeasonalGrowthData()
    return self.growthDataNonSeasonal
end
function FruitTypeDesc:getIsCatchCrop()
    return self.isCatchCrop
end
function FruitTypeDesc:getIsHarvestable(growthState)
    return self.harvestTransitions[growthState] ~= nil
end
function FruitTypeDesc:getIsHarvestReady(growthState)
    return self.harvestReadyTransitions[growthState] ~= nil
end
function FruitTypeDesc:getMinHarvestingGrowthState()
    return self.minHarvestingGrowthState
end
function FruitTypeDesc:getIsHarvestableInPeriod(growthMode, seasonPeriod)
    return growthMode ~= GrowthMode.SEASONAL and true or self.growthDataSeasonal.periods[seasonPeriod].isHarvestable
end
function FruitTypeDesc:getIsPlantableInPeriod(growthMode, seasonPeriod)
    return growthMode ~= GrowthMode.SEASONAL and true or self.growthDataSeasonal.periods[seasonPeriod].plantingAllowed
end
function FruitTypeDesc:getIsCut(growthState)
    return self.cutStates[growthState] ~= nil
end
function FruitTypeDesc:getIsGrowing(growthState)
    local maxGrowingState = self.minHarvestingGrowthState - 1
    if self.minPreparingGrowthState >= 0 then
        maxGrowingState = math.min(maxGrowingState, self.minPreparingGrowthState - 1)
    end
    return growthState > 0 and growthState <= maxGrowingState
end
function FruitTypeDesc:getIsPreparable(growthState)
    return self.minPreparingGrowthState <= growthState and growthState <= self.maxPreparingGrowthState
end
function FruitTypeDesc:getIsWithered(growthState)
    return self.witheredState ~= nil and self.witheredState == growthState
end
function FruitTypeDesc:getIsWeedable(growthState)
    return self.minWeederState <= growthState and growthState <= self.maxWeederState
end
function FruitTypeDesc:getIsHoeable(growthState)
    return self.minWeederHoeState <= growthState and growthState <= self.maxWeederHoeState
end
function FruitTypeDesc:getRandomInitialState(growthMode)
    if growthMode == GrowthMode.SEASONAL then
        return self.growthDataSeasonal.initialState
    else
        return math.random(1, self.numGrowthStates)
    end
end
function FruitTypeDesc:getAreaLiters(area, windrow)
    if windrow == true then
        return area * g_currentMission:getFruitPixelsToSqm() * (self.windrowLiterPerSqm or self.literPerSqm)
    else
        return area * g_currentMission:getFruitPixelsToSqm() * self.literPerSqm
    end
end
function FruitTypeDesc:getStatsText()
    local str = self.name:sub(0, 15)
    while string.len(str) < 15 do
        str = str .. " "
    end
    local str = string.format("%dl", MathUtil.round(self.literPerSqm * 10000 * 2)):sub(0, 8)
    while string.len(str) < 8 do
        str = str .. " "
    end
    local str = string.format("%dl", MathUtil.round(self.seedUsagePerSqm * 10000)):sub(0, 5)
    while string.len(str) < 5 do
        str = str .. " "
    end
    local str = string.format("%d", self.numGrowthStates):sub(0, 2)
    while string.len(str) < 2 do
        str = str .. " "
    end
    local str = string.format("Easy: %d ", self.fillType.pricePerLiter * 1000 * EconomyManager.PRICE_MULTIPLIER[1]):sub(0, 10)
    while string.len(str) < 10 do
        str = str .. " "
    end
    local str = string.format("Medium: %d ", self.fillType.pricePerLiter * 1000 * EconomyManager.PRICE_MULTIPLIER[2]):sub(0, 12)
    while string.len(str) < 12 do
        str = str .. " "
    end
    local str = string.format("Hard: %d ", self.fillType.pricePerLiter * 1000 * EconomyManager.PRICE_MULTIPLIER[3]):sub(0, 11)
    while string.len(str) < 11 do
        str = str .. " "
    end
    local str = str .. " - " .. str .. " - " .. str
    local str = string.format("%.1fcm", self.plantSpacing * 100):sub(0, 6)
    while string.len(str) < 6 do
        str = str .. " "
    end
    return string.format("%s: Yield per ha: %s | Seeds per ha: %s | Growth stages: %s | Sell price: %s | Plant spacing: %s", str, str, str, str, str, str)
end
function FruitTypeDesc:getWeedingStateText()
    local text = self.name:sub(0, 15)
    while string.len(text) < 15 do
        text = text .. " "
    end
    local i = 1
    for i = i, self.numGrowthStates do
        local allowWeeder = false
        if self.minWeederState <= i then
            allowWeeder = i <= self.maxWeederState
        end
        local allowHoe = false
        if self.minWeederHoeState <= i then
            allowHoe = i <= self.maxWeederHoeState
        end
        if allowWeeder and allowHoe then
        elseif allowWeeder then
        elseif allowHoe then
        end
    end
    return text
end
function FruitTypeDesc:getGrowthStateByDensityState(state)
    if state == nil then
        return nil
    end
    return bit32.band(bit32.rshift(state, self.startStateChannel), 2 ^ self.numStateChannels - 1)
end
function FruitTypeDesc:getYieldScale(growthState)
    return self.yieldScales[growthState] or 1
end
function FruitTypeDesc:getDefaultSowingGroundType()
    return FieldGroundType.getByName(self.defaultSowingGroundType) or FieldGroundType.SOWN
end