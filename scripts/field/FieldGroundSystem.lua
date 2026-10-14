FieldGroundSystem = {}
FieldDensityMap = {}
FieldDensityMap.GROUND_TYPE = 1
FieldDensityMap.GROUND_ANGLE = 2
FieldDensityMap.SPRAY_TYPE = 3
FieldDensityMap.SPRAY_LEVEL = 4
FieldDensityMap.LIME_LEVEL = 5
FieldDensityMap.PLOW_LEVEL = 6
FieldDensityMap.STUBBLE_SHRED_LEVEL = 7
FieldDensityMap.ROLLER_LEVEL = 8
FieldDensityMap.WATER_LEVEL = 9
FieldDensityMap.FIELD_TYPE = 10
local FieldGroundSystem_mt = Class(FieldGroundSystem)
function FieldGroundSystem.new(customMt)
    -- upvalues: (copy) FieldGroundSystem_mt
    local self = setmetatable({}, customMt or FieldGroundSystem_mt)
    self.baseDirectory = ""
    self:initDataStructures()
    return self
end
function FieldGroundSystem:initDataStructures()
    self.fieldGroundTypeValue = {}
    self.fieldGroundTypeValueToId = {}
    self.fieldGroundTypeTyreTrackColor = {}
    self.fieldSprayTypeValue = {}
    self.fieldSprayTypeTyreTrackColor = {}
    self.fieldChopperTypeValue = {}
    self.fieldChopperTypeTyreTrackColor = {}
    self.fieldTypeValue = {}
    self.densityMaps = {}
end
function FieldGroundSystem:loadGroundTypes(filename)
    local xmlFile = XMLFile.load("fieldGround", filename)
    if xmlFile == nil then
        Logging.error("Could not load field ground type xml file at %q", filename)
    else
        self:loadDensityMapFromXML(FieldDensityMap.GROUND_TYPE, xmlFile, "fieldGround.densityMaps.groundTypes")
        self:loadDensityMapFromXML(FieldDensityMap.GROUND_ANGLE, xmlFile, "fieldGround.densityMaps.groundAngle")
        self:loadDensityMapFromXML(FieldDensityMap.SPRAY_TYPE, xmlFile, "fieldGround.densityMaps.sprayTypes")
        self:loadDensityMapFromXML(FieldDensityMap.SPRAY_LEVEL, xmlFile, "fieldGround.densityMaps.sprayLevel", 3)
        self:loadDensityMapFromXML(FieldDensityMap.WATER_LEVEL, xmlFile, "fieldGround.densityMaps.water")
        if Platform.gameplay.usePlowCounter then
            self:loadDensityMapFromXML(FieldDensityMap.PLOW_LEVEL, xmlFile, "fieldGround.densityMaps.plowLevel")
        end
        if Platform.gameplay.useLimeCounter then
            self:loadDensityMapFromXML(FieldDensityMap.LIME_LEVEL, xmlFile, "fieldGround.densityMaps.limeLevel")
        end
        if Platform.gameplay.useStubbleShred then
            self:loadDensityMapFromXML(FieldDensityMap.STUBBLE_SHRED_LEVEL, xmlFile, "fieldGround.densityMaps.stubbleShredLevel")
        end
        if Platform.gameplay.useRolling then
            self:loadDensityMapFromXML(FieldDensityMap.ROLLER_LEVEL, xmlFile, "fieldGround.densityMaps.rollerLevel")
        end
        self:loadDensityMapFromXML(FieldDensityMap.FIELD_TYPE, xmlFile, "fieldGround.densityMaps.fieldType")
        _, self.groundTypesFirstChannel, self.groundTypesNumChannels = self:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        self.groundTypesMaxValue = self:getMaxValue(FieldDensityMap.GROUND_TYPE)
        self.groundMask = bit32.lshift(2 ^ self.groundTypesNumChannels - 1, self.groundTypesFirstChannel)
        _, self.angleFirstChannel, self.angleNumChannels = self:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
        self.angleMaxValue = self:getMaxValue(FieldDensityMap.GROUND_ANGLE)
        self.angleStep = 3.141592653589793 / 2 ^ self.angleNumChannels
        _, self.sprayTypesFirstChannel, self.sprayTypesNumChannels = self:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
        self.sprayTypesMaxValue = self:getMaxValue(FieldDensityMap.SPRAY_TYPE)
        self.sprayMask = bit32.lshift(2 ^ self.sprayTypesNumChannels - 1, self.sprayTypesFirstChannel)
        self.fieldTypesMaxValue = self:getMaxValue(FieldDensityMap.FIELD_TYPE)
        self:loadGroundIdFromXML(FieldGroundType.STUBBLE_TILLAGE, xmlFile, "fieldGround.densityMaps.groundTypes.stubbleTillage", FieldGroundType.STUBBLE_TILLAGE, {
            1,
            1,
            1,
            1
        })
        self:loadGroundIdFromXML(FieldGroundType.CULTIVATED, xmlFile, "fieldGround.densityMaps.groundTypes.cultivated", FieldGroundType.CULTIVATED, {
            1,
            1,
            1,
            1
        })
        self:loadGroundIdFromXML(FieldGroundType.SEEDBED, xmlFile, "fieldGround.densityMaps.groundTypes.seedbed", FieldGroundType.SEEDBED, {
            1,
            1,
            1,
            1
        })
        self:loadGroundIdFromXML(FieldGroundType.ROLLED_SEEDBED, xmlFile, "fieldGround.densityMaps.groundTypes.rolledSeedbed", FieldGroundType.ROLLED_SEEDBED, {
            1,
            1,
            1,
            1
        })
        self:loadGroundIdFromXML(FieldGroundType.PLOWED, xmlFile, "fieldGround.densityMaps.groundTypes.plowed", FieldGroundType.PLOWED, {
            1,
            1,
            1,
            1
        })
        self:loadGroundIdFromXML(FieldGroundType.SOWN, xmlFile, "fieldGround.densityMaps.groundTypes.sown", FieldGroundType.SOWN, {
            1,
            1,
            1,
            1
        })
        self:loadGroundIdFromXML(FieldGroundType.DIRECT_SOWN, xmlFile, "fieldGround.densityMaps.groundTypes.directSown", FieldGroundType.DIRECT_SOWN, {
            1,
            1,
            1,
            1
        })
        self:loadGroundIdFromXML(FieldGroundType.PLANTED, xmlFile, "fieldGround.densityMaps.groundTypes.planted", FieldGroundType.PLANTED, {
            1,
            1,
            1,
            1
        })
        self:loadGroundIdFromXML(FieldGroundType.RIDGE, xmlFile, "fieldGround.densityMaps.groundTypes.ridge", FieldGroundType.RIDGE, {
            1,
            1,
            1,
            1
        })
        self:loadGroundIdFromXML(FieldGroundType.RIDGE_SOWN, xmlFile, "fieldGround.densityMaps.groundTypes.ridgeSown", FieldGroundType.RIDGE_SOWN, {
            1,
            1,
            1,
            1
        })
        self:loadGroundIdFromXML(FieldGroundType.ROLLER_LINES, xmlFile, "fieldGround.densityMaps.groundTypes.rollerLines", FieldGroundType.ROLLER_LINES, {
            1,
            1,
            1,
            1
        })
        self:loadGroundIdFromXML(FieldGroundType.HARVEST_READY, xmlFile, "fieldGround.densityMaps.groundTypes.harvestReady", FieldGroundType.HARVEST_READY, {
            1,
            1,
            1,
            1
        })
        self:loadGroundIdFromXML(FieldGroundType.HARVEST_READY_OTHER, xmlFile, "fieldGround.densityMaps.groundTypes.harvestReadyOther", FieldGroundType.HARVEST_READY_OTHER, {
            1,
            1,
            1,
            1
        })
        self:loadGroundIdFromXML(FieldGroundType.GRASS, xmlFile, "fieldGround.densityMaps.groundTypes.grass", FieldGroundType.GRASS, {
            1,
            1,
            1,
            1
        })
        self:loadGroundIdFromXML(FieldGroundType.GRASS_CUT, xmlFile, "fieldGround.densityMaps.groundTypes.grassCut", FieldGroundType.GRASS_CUT, {
            1,
            1,
            1,
            1
        })
        self:loadSprayIdFromXML(FieldSprayType.FERTILIZER, xmlFile, "fieldGround.densityMaps.sprayTypes.fertilizer", FieldSprayType.FERTILIZER, {
            1,
            1,
            1,
            1
        })
        self:loadSprayIdFromXML(FieldSprayType.MANURE, xmlFile, "fieldGround.densityMaps.sprayTypes.manure", FieldSprayType.MANURE, {
            1,
            1,
            1,
            1
        })
        self:loadSprayIdFromXML(FieldSprayType.LIQUID_MANURE, xmlFile, "fieldGround.densityMaps.sprayTypes.liquidManure", FieldSprayType.LIQUID_MANURE, {
            1,
            1,
            1,
            1
        })
        if Platform.gameplay.useLimeCounter then
            self:loadSprayIdFromXML(FieldSprayType.LIME, xmlFile, "fieldGround.densityMaps.sprayTypes.lime", FieldSprayType.LIME, {
                1,
                1,
                1,
                1
            })
        end
        self:loadChopperIdFromXML(FieldChopperType.CHOPPER_STRAW, xmlFile, "fieldGround.densityMaps.sprayTypes.straw", 5, {
            1,
            1,
            1,
            1
        })
        self:loadChopperIdFromXML(FieldChopperType.CHOPPER_MAIZE, xmlFile, "fieldGround.densityMaps.sprayTypes.maize", 6, {
            1,
            1,
            1,
            1
        })
        self:loadFieldTypeIdFromXML(FieldType.DEFAULT, xmlFile, "fieldGround.densityMaps.fieldType.default", 0)
        self:loadFieldTypeIdFromXML(FieldType.RICE, xmlFile, "fieldGround.densityMaps.fieldType.rice", 1)
        self.firstSowableValue = xmlFile:getInt("fieldGround.densityMaps.groundTypes.ranges.sowable#firstValue", self.firstSowableValue or self.fieldGroundTypeValue[FieldGroundType.STUBBLE_TILLAGE])
        self.lastSowableValue = xmlFile:getInt("fieldGround.densityMaps.groundTypes.ranges.sowable#lastValue", self.lastSowableValue or self.fieldGroundTypeValue[FieldGroundType.RIDGE])
        self.firstSowingValue = xmlFile:getInt("fieldGround.densityMaps.groundTypes.ranges.sowing#firstValue", self.firstSowingValue or self.fieldGroundTypeValue[FieldGroundType.SOWN])
        self.lastSowingValue = xmlFile:getInt("fieldGround.densityMaps.groundTypes.ranges.sowing#lastValue", self.lastSowingValue or self.fieldGroundTypeValue[FieldGroundType.RIDGE_SOWN])
        xmlFile:delete()
    end
end
function FieldGroundSystem:loadMapData(xmlFile, _, baseDirectory)
    self.baseDirectory = baseDirectory
    self:loadGroundTypes("data/maps/maps_fieldGround.xml")
    local filename = getXMLString(xmlFile, "map.fieldGround#filename")
    if filename ~= nil then
        self:loadGroundTypes((Utils.getFilename(filename, baseDirectory)))
    end
    return true
end
function FieldGroundSystem:delete()
    for _, data in pairs(self.densityMaps) do
        if data.map ~= nil and data.canBeDeleted then
            delete(data.map)
        end
    end
    self.densityMaps = {}
end
function FieldGroundSystem:initTerrain(mission, terrainNode, terrainDetailId)
    for identifier, data in pairs(self.densityMaps) do
        if data.useTerrainDetailId then
            data.map = terrainDetailId
            local size = getDensityMapSize(terrainDetailId)
            data.width = size
            data.height = size
            data.filename = getDensityMapFilename(terrainDetailId)
            data.isBitVector = false
            data.canBeDeleted = false
            data.usedByTerrainVT = true
        else
            data.map = createBitVectorMap("densityMap_fieldGroundSystem_" .. (data.filename or ""))
            local size = data.path
            local missionInfo = mission.missionInfo
            local loadFromSave = false
            local needDefaultMap = false
            if missionInfo.isValid and data.filename ~= nil then
                size = missionInfo.savegameDirectory .. "/" .. data.filename
                loadFromSave = true
            end
            if loadFromSave and not loadBitVectorMapFromFile(data.map, size, data.numChannels) then
                Logging.warning("Loading density map file \'" .. tostring(size) .. "\' failed! Loading default density map.")
                loadFromSave = false
            end
            if not loadFromSave then
                if data.path == nil then
                    needDefaultMap = true
                elseif not loadBitVectorMapFromFile(data.map, data.path, data.numChannels) then
                    Logging.error("Loading default density map file \'" .. tostring(data.path) .. "\' failed!")
                    needDefaultMap = true
                end
            end
            if needDefaultMap then
                loadBitVectorMapNew(data.map, 1024, 1024, data.numChannels, false)
                Logging.error("Missing field density map data for \'%s\'! Creating empty default", data.key)
            end
            data.width, data.height = getBitVectorMapSize(data.map)
            data.isBitVector = true
            data.canBeDeleted = true
        end
    end
    self.displacementId, _ = getTerrainDataPlaneByName(terrainNode, "terrainDisplacement")
    self.displacementNumChannels = getTerrainDetailNumChannels(self.displacementId)
    self.displacementResetValue = 2 ^ (self.displacementNumChannels - 1)
    self.displacementCustomFlagId, _ = getTerrainDataPlaneByName(terrainNode, "terrainDisplacementCustomFlag")
end
function FieldGroundSystem:addDensityMapSyncer(densityMapSyncer)
    local added = {}
    for identifier, data in pairs(self.densityMaps) do
        if added[data.map] == nil and data.syncOverNetwork then
            densityMapSyncer:addDensityMap(data.map, data.usedByTerrainVT)
            added[data.map] = true
        end
    end
    if added[self.displacementId] == nil then
        densityMapSyncer:addDensityMap(self.displacementId, true, 16, 100, 100)
        added[self.displacementId] = true
    end
end
function FieldGroundSystem:getDensityMaps()
    return self.densityMaps
end
function FieldGroundSystem:loadDensityMapFromXML(identifier, xmlFile, key, forcedMaxValue, syncOverNetwork)
    if xmlFile:hasProperty(key) then
        local data = self.densityMaps[identifier] or {}
        data.syncOverNetwork = xmlFile:getBool(key .. "#syncOverNetwork", Utils.getNoNil(syncOverNetwork, true))
        data.firstChannel = xmlFile:getInt(key .. "#firstChannel") or (data.firstChannel or 0)
        data.numChannels = xmlFile:getInt(key .. "#numChannels") or (data.numChannels or 0)
        data.canBeDeleted = Utils.getNoNil(data.canBeDeleted, Utils.getNoNil(data.canBeDeleted, false))
        data.useTerrainDetailId = Utils.getNoNil(xmlFile:getBool(key .. "#useDefaultTerrainDetail"), Utils.getNoNil(data.useTerrainDetailId, false))
        if not data.useTerrainDetailId then
            local filename = xmlFile:getString(key .. "#filename")
            if filename ~= nil then
                data.path = Utils.getFilename(filename, self.baseDirectory)
                data.filename = Utils.getFilenameFromPath(data.path)
            end
            if data.path == nil then
                Logging.xmlError(xmlFile, "Invalid file given for densityMap in \'%s\'. Using default terrain detail instead", key)
                data.useTerrainDetailId = true
            end
        end
        local filename = 2 ^ data.numChannels - 1
        local newValue = data.maxValue or filename
        local maxValue = math.max(newValue, filename)
        local newValue = xmlFile:getInt(key .. "#maxValue")
        if newValue ~= nil then
            maxValue = math.min(newValue, filename)
        end
        if forcedMaxValue ~= nil then
            maxValue = math.min(maxValue, forcedMaxValue)
        end
        data.maxValue = maxValue
        data.key = key
        self.densityMaps[identifier] = data
        return true
    end
end
function FieldGroundSystem:loadGroundIdFromXML(identifier, xmlFile, key, defaultValue, defaultColor)
    local id = xmlFile:getInt(key .. "#value") or self.fieldGroundTypeValue[identifier]
    if id == nil then
        Logging.xmlWarning(xmlFile, "Missing xml element \'%s\'! Using default value \'%d\'", key, defaultValue)
    else
        defaultValue = id
    end
    if self.groundTypesMaxValue < defaultValue then
        defaultValue = 0
        Logging.xmlError(xmlFile, "Invalid value for xml element \'%s\'! Using value \'0\'", key)
    end
    self.fieldGroundTypeValue[identifier] = defaultValue
    self.fieldGroundTypeValueToId[defaultValue] = identifier
    local colorStr = xmlFile:getString(key .. "#tireTrackColor")
    local color = nil
    if colorStr ~= nil then
        color = string.getVector(colorStr)
        if #color ~= 4 then
            Logging.xmlError(xmlFile, "Invalid number of values (should be 4) for xml element \'%s\'!", key)
            color = nil
        end
    end
    self.fieldGroundTypeTyreTrackColor[defaultValue] = color or (self.fieldGroundTypeTyreTrackColor[defaultValue] or defaultColor)
end
function FieldGroundSystem:loadSprayIdFromXML(identifier, xmlFile, key, defaultValue, defaultColor)
    if xmlFile:hasProperty(key) then
        local id = xmlFile:getInt(key .. "#value") or self.fieldSprayTypeValue[identifier]
        if id == nil then
            Logging.xmlWarning(xmlFile, "Missing xml element \'%s\'! Using default value \'%d\'", key, defaultValue)
        else
            defaultValue = id
        end
        if defaultValue == self.sprayTypesMaxValue then
            defaultValue = 0
            Logging.xmlError(xmlFile, "Value \'%d\' is reserved and cannot be used in xml element \'%s\'! Using value \'0\'", self.sprayTypesMaxValue, key)
        end
        if self.sprayTypesMaxValue < defaultValue then
            defaultValue = 0
            Logging.xmlError(xmlFile, "Invalid value for xml element \'%s\'! Using value \'0\'", key)
        end
        self.fieldSprayTypeValue[identifier] = defaultValue
        local colorStr = xmlFile:getString(key .. "#tireTrackColor")
        local color = nil
        if colorStr ~= nil then
            color = string.getVector(colorStr)
            if #color ~= 4 then
                Logging.xmlError(xmlFile, "Invalid number of values (should be 4) for xml element \'%s\'!", key)
                color = nil
            end
        end
        self.fieldSprayTypeTyreTrackColor[defaultValue] = color or (self.fieldSprayTypeTyreTrackColor[defaultValue] or defaultColor)
    end
end
function FieldGroundSystem:loadChopperIdFromXML(identifier, xmlFile, key, defaultValue, defaultColor)
    if xmlFile:hasProperty(key) then
        local id = xmlFile:getInt(key .. "#value") or self.fieldChopperTypeValue[identifier]
        if id == nil then
            Logging.xmlWarning(xmlFile, "Missing xml element \'%s\'! Using default value \'%d\'", key, defaultValue)
        else
            defaultValue = id
        end
        if defaultValue == self.sprayTypesMaxValue then
            defaultValue = 0
            Logging.xmlError(xmlFile, "Value \'%d\' is reserved and cannot be used in xml element \'%s\'! Using value \'0\'", self.sprayTypesMaxValue, key)
        end
        if self.sprayTypesMaxValue < defaultValue then
            defaultValue = 0
            Logging.xmlError(xmlFile, "Invalid value for xml element \'%s\'! Using value \'0\'", key)
        end
        self.fieldChopperTypeValue[identifier] = defaultValue
        local colorStr = xmlFile:getString(key .. "#tireTrackColor")
        local color = nil
        if colorStr ~= nil then
            color = string.getVector(colorStr)
            if #color ~= 4 then
                Logging.xmlError(xmlFile, "Invalid number of values (should be 4) for xml element \'%s\'!", key)
                color = nil
            end
        end
        self.fieldChopperTypeTyreTrackColor[defaultValue] = color or (self.fieldChopperTypeTyreTrackColor[defaultValue] or defaultColor)
    end
end
function FieldGroundSystem:loadFieldTypeIdFromXML(identifier, xmlFile, key, defaultValue)
    if xmlFile:hasProperty(key) then
        local id = xmlFile:getInt(key .. "#value") or self.fieldTypeValue[identifier]
        if id == nil then
            Logging.xmlWarning(xmlFile, "Missing xml element \'%s\'! Using default value \'%d\'", key, defaultValue)
        else
            defaultValue = id
        end
        if self.fieldTypesMaxValue < defaultValue then
            defaultValue = 0
            Logging.xmlError(xmlFile, "Invalid value for xml element \'%s\'! Using value \'0\'", key)
        end
        self.fieldTypeValue[identifier] = defaultValue
    end
end
function FieldGroundSystem:getFieldGroundValueByName(groundTypeName)
    local groundType = FieldGroundType.getByName(groundTypeName)
    if groundType == nil then
        return nil
    else
        return self.fieldGroundTypeValue[groundType]
    end
end
function FieldGroundSystem:getFieldGroundValue(groundType)
    return self.fieldGroundTypeValue[groundType] or 0
end
function FieldGroundSystem:getFieldGroundTypeByValue(value)
    return self.fieldGroundTypeValueToId[value] or FieldGroundType.NONE
end
function FieldGroundSystem:getFieldGroundTyreTrackColor(densityBits)
    local sprayType = bit32.band(densityBits, self.groundMask)
    local color = self.groundTypesFirstChannel
    local groundType = bit32.rshift(sprayType, color)
    local color = bit32.band(densityBits, self.sprayMask)
    local sprayType = bit32.rshift(color, self.sprayTypesFirstChannel)
    local color = self.fieldGroundTypeTyreTrackColor[groundType + 1]
    if sprayType > 0 then
        color = self.fieldSprayTypeTyreTrackColor[sprayType]
        if color == nil then
            color = self.fieldChopperTypeTyreTrackColor[sprayType]
        end
    end
    if color == nil then
        return 0, 0, 0, 0
    else
        return color[1], color[2], color[3], color[4]
    end
end
function FieldGroundSystem:getFieldSprayValueByName(sprayTypeName)
    if sprayTypeName == nil then
        return 0
    end
    local sprayType = string.upper(sprayTypeName)
    local sprayType = FieldSprayType[sprayType]
    return sprayType == nil and 0 or (self.fieldSprayTypeValue[sprayType] or 0)
end
function FieldGroundSystem:getFieldSprayTypeByValue(value)
    for sprayType, sprayValue in pairs(self.fieldSprayTypeValue) do
        if value == sprayValue then
            return sprayType
        end
    end
    return FieldSprayType.NONE
end
function FieldGroundSystem:getFieldSprayValue(sprayType)
    return self.fieldSprayTypeValue[sprayType] or 0
end
function FieldGroundSystem:getFieldTypeValueByName(fieldTypeName)
    local fieldType = FieldType.getByName(fieldTypeName)
    if fieldType == nil then
        return nil
    else
        return self.fieldTypeValue[fieldType]
    end
end
function FieldGroundSystem:getFieldTypeValue(fieldType)
    return self.fieldTypeValue[fieldType] or 0
end
function FieldGroundSystem:getFieldTypeByValue(value)
    for fieldType, fieldValue in pairs(self.fieldTypeValue) do
        if value == fieldValue then
            return fieldType
        end
    end
    return 0
end
function FieldGroundSystem:getSowableRange()
    return self.firstSowableValue, self.lastSowableValue
end
function FieldGroundSystem:getSowingRange()
    return self.firstSowingValue, self.lastSowingValue
end
function FieldGroundSystem:getGroundAngleMaxValue()
    return self.angleMaxValue
end
function FieldGroundSystem:getGroundAngleStep()
    return self.angleStep
end
function FieldGroundSystem:getChopperTypeValue(chopperType)
    return self.fieldChopperTypeValue[chopperType]
end
function FieldGroundSystem:getDensityMapData(levelType)
    local data = self.densityMaps[levelType]
    if data == nil then
        return nil
    else
        return data.map, data.firstChannel, data.numChannels
    end
end
function FieldGroundSystem:getMaxValue(levelType)
    local data = self.densityMaps[levelType]
    if data == nil then
        return nil
    else
        return data.maxValue
    end
end
function FieldGroundSystem:getSize(levelType)
    local data = self.densityMaps[levelType]
    if data == nil then
        return nil, nil
    else
        return data.width, data.height
    end
end
function FieldGroundSystem:getValueAtWorldPos(levelType, worldPosX, _, worldPosZ)
    local data = self.densityMaps[levelType]
    if data == nil then
        return nil
    end
    if not data.isBitVector then
        local terrainSize = getDensityAtWorldPos(data.map, worldPosX, 0, worldPosZ)
        local localZ = bit32.rshift(terrainSize, data.firstChannel)
        return bit32.band(localZ, 2 ^ data.numChannels - 1)
    end
    local terrainSize = g_currentMission.terrainSize
    local localZ = data.width * (worldPosX + terrainSize * 0.5) / terrainSize
    local localX = math.floor(localZ)
    local localZ = math.floor(data.height * (worldPosZ + terrainSize * 0.5) / terrainSize)
    return getBitVectorMapPoint(data.map, localX, localZ, data.firstChannel, data.numChannels)
end
function FieldGroundSystem:getDisplacementData()
    return self.displacementId, 0, self.displacementNumChannels
end
function FieldGroundSystem:getDisplacementCustomFlagData()
    return self.displacementCustomFlagId, 0, 1
end
function FieldGroundSystem:getDisplacementResetValue()
    return self.displacementResetValue
end