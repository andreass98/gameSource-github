SprayType = nil
SprayTypeManager = {}
local SprayTypeManager_mt = Class(SprayTypeManager, AbstractManager)
function SprayTypeManager.new(customMt)
    -- upvalues: (copy) SprayTypeManager_mt
    return AbstractManager.new(customMt or SprayTypeManager_mt)
end
function SprayTypeManager:initDataStructures()
    self.numSprayTypes = 0
    self.sprayTypes = {}
    self.nameToSprayType = {}
    self.nameToIndex = {}
    self.indexToName = {}
    self.fillTypeIndexToSprayType = {}
    SprayType = self.nameToIndex
end
function SprayTypeManager:loadDefaultTypes()
    local xmlFile = loadXMLFile("sprayTypes", "data/maps/maps_sprayTypes.xml")
    self:loadSprayTypes(xmlFile, nil, true)
    delete(xmlFile)
end
function SprayTypeManager:loadMapData(xmlFile, missionInfo, baseDirectory)
    SprayTypeManager:superClass().loadMapData(self)
    self:loadDefaultTypes()
    return XMLUtil.loadDataFromMapXML(xmlFile, "sprayTypes", baseDirectory, self, self.loadSprayTypes, missionInfo)
end
function SprayTypeManager:loadSprayTypes(xmlFile, _, isBaseType)
    local i = 0
    while true do
        local key = string.format("map.sprayTypes.sprayType(%d)", i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        self:addSprayType(getXMLString(xmlFile, key .. "#name"), getXMLFloat(xmlFile, key .. "#litersPerSecond"), getXMLString(xmlFile, key .. "#type"), FieldSprayType.getValueByName(getXMLString(xmlFile, key .. "#sprayGroundType")), isBaseType)
        i = i + 1
    end
    return true
end
function SprayTypeManager:addSprayType(name, litersPerSecond, typeName, sprayGroundType, isBaseType)
    if not ClassUtil.getIsValidIndexName(name) then
        printWarning("Warning: \'" .. tostring(name) .. "\' is not a valid name for a sprayType. Ignoring sprayType!")
        return nil
    end
    local fillType = string.upper(name)
    local fillType = g_fillTypeManager:getFillTypeByName(fillType)
    if fillType ~= nil then
        if isBaseType and self.nameToSprayType[fillType] ~= nil then
            printWarning("Warning: SprayType \'" .. tostring(fillType) .. "\' already exists. Ignoring sprayType!")
            return nil
        end
        local sprayType = self.nameToSprayType[fillType]
        if sprayType == nil then
            self.numSprayTypes = self.numSprayTypes + 1
            sprayType = {
                ["name"] = fillType,
                ["index"] = self.numSprayTypes,
                ["fillType"] = fillType,
                ["litersPerSecond"] = Utils.getNoNil(litersPerSecond, 0)
            }
            typeName = string.upper(typeName)
            sprayType.isFertilizer = typeName == "FERTILIZER"
            sprayType.isLime = typeName == "LIME"
            sprayType.isHerbicide = typeName == "HERBICIDE"
            if not (sprayType.isFertilizer or (sprayType.isLime or sprayType.isHerbicide)) then
                printWarning("Warning: SprayType \'" .. tostring(fillType) .. "\' type \'" .. tostring(typeName) .. "\' is invalid. Possible values are \'FERTILIZER\', \'HERBICIDE\' or \'LIME\'. Ignoring sprayType!")
                return nil
            end
            table.insert(self.sprayTypes, sprayType)
            self.nameToSprayType[fillType] = sprayType
            self.nameToIndex[fillType] = self.numSprayTypes
            self.indexToName[self.numSprayTypes] = fillType
            self.fillTypeIndexToSprayType[fillType.index] = sprayType
        end
        sprayType.litersPerSecond = litersPerSecond or (sprayType.litersPerSecond or 0)
        sprayType.sprayGroundType = sprayGroundType or (sprayType.sprayGroundType or 1)
        return sprayType
    end
    printWarning("Warning: Missing fillType \'" .. tostring(fillType) .. "\' for sprayType definition. Ignoring sprayType!")
end
function SprayTypeManager:getSprayTypeByIndex(index)
    if index == nil then
        return nil
    else
        return self.sprayTypes[index]
    end
end
function SprayTypeManager:getSprayTypeByName(name)
    if name == nil then
        return nil
    end
    name = string.upper(name)
    return self.nameToSprayType[name]
end
function SprayTypeManager:getFillTypeNameByIndex(index)
    if index == nil then
        return nil
    else
        return self.indexToName[index]
    end
end
function SprayTypeManager:getFillTypeIndexByName(name)
    if name == nil then
        return nil
    end
    name = string.upper(name)
    return self.nameToIndex[name]
end
function SprayTypeManager:getFillTypeByName(name)
    if name == nil then
        return nil
    end
    name = string.upper(name)
    return self.nameToSprayType[name]
end
function SprayTypeManager:getSprayTypeByFillTypeIndex(index)
    if index == nil then
        return nil
    else
        return self.fillTypeIndexToSprayType[index]
    end
end
function SprayTypeManager:getSprayTypeIndexByFillTypeIndex(index)
    if index ~= nil then
        local sprayType = self.fillTypeIndexToSprayType[index]
        if sprayType ~= nil then
            return sprayType.index
        end
    end
    return nil
end
function SprayTypeManager:getSprayTypes()
    return self.sprayTypes
end
g_sprayTypeManager = SprayTypeManager.new()