Field = {}
Field.DEPRECATED_USER_ATTRIBUTES = {}
Field.DEPRECATED_USER_ATTRIBUTES.fieldMissionAllowed = "missionAllowed"
Field.DEPRECATED_USER_ATTRIBUTES.fieldGrassMission = "missionOnlyGrass"
Field.DEPRECATED_USER_ATTRIBUTES.fieldDimensionIndex = "dimensionIndex"
Field.DEPRECATED_USER_ATTRIBUTES.fieldAngle = "angle"
local Field_mt = Class(Field)
function Field.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#plannedFruit", "Name of the planned fruit type", nil, false)
    FieldState.registerXMLPaths(schema, basePath)
end
function Field.new(customMt)
    -- upvalues: (copy) Field_mt
    local self = setmetatable({}, customMt or Field_mt)
    self.name = nil
    self.rootNode = nil
    self.densityMapPolygon = DensityMapPolygon.new()
    self.polygonPoints = {}
    self.angle = 0
    self.areaHa = 1
    self.farmland = nil
    self.currentMission = nil
    self.plannedFruitTypeIndex = FruitType.UNKNOWN
    self.isMissionAllowed = true
    self.grassMissionOnly = false
    self.posX = 0
    self.posZ = 0
    self.fieldState = FieldState.new()
    return self
end
function Field:load(id)
    self.rootNode = id
    local name = getUserAttribute(id, "name")
    if not string.isNilOrWhitespace(name) then
        self.name = g_i18n:convertText(name, g_currentMission.loadingMapModName)
    end
    for oldAttribute, newAttribute in pairs(Field.DEPRECATED_USER_ATTRIBUTES) do
        if getUserAttribute(id, oldAttribute) ~= nil then
            Logging.warning("User attribute \'%s\' is not supported anymore for field \'%s\'. Please use \'%s\' instead!", oldAttribute, getName(id), newAttribute)
        end
    end
    local polygonIndex = getUserAttribute(id, "polygonIndex")
    if polygonIndex == nil then
        Logging.warning("No polygonIndex defined for field \'%s\'!", getName(id))
        return false
    end
    local polygonPointsRoot = I3DUtil.indexToObject(id, polygonIndex)
    if polygonPointsRoot == nil then
        Logging.warning("Could not resolve polygonIndex \'%s\' for field \'%s\'!", polygonIndex, getName(id))
        return false
    end
    local newAttribute = 0
    local sqm = getNumOfChildren(polygonPointsRoot) - 1
    local oldAttribute = 1
    for newAttribute = newAttribute, sqm, oldAttribute do
        local polygonPoint = getChildAt(polygonPointsRoot, newAttribute)
        table.insert(self.polygonPoints, polygonPoint)
    end
    self.densityMapPolygon:updateFromNodes(self.polygonPoints)
    self.areaHa = MathUtil.getPolygon2DSize(self.polygonPoints) / 10000
    local oldAttribute, newAttribute = MathUtil.getPolygonLabel(self.polygonPoints, 1)
    self.posX = oldAttribute
    self.posZ = newAttribute
    self.nameIndicator = I3DUtil.indexToObject(id, getUserAttribute(id, "nameIndicatorIndex"))
    self.teleportNode = I3DUtil.indexToObject(id, getUserAttribute(id, "teleportIndicatorIndex"))
    local oldAttribute = getUserAttribute(id, "angle") or 0
    local newAttribute = math.rad(oldAttribute)
    self.angle = FSDensityMapUtil.convertToDensityMapAngle(newAttribute, g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())
    self.isMissionAllowed = Utils.getNoNil(getUserAttribute(id, "missionAllowed"), true)
    self.grassMissionOnly = Utils.getNoNil(getUserAttribute(id, "missionOnlyGrass"), false)
    return true
end
function Field:delete()
    g_messageCenter:unsubscribeAll(self)
end
function Field:saveToXMLFile(xmlFile, key)
    if self.plannedFruitTypeIndex == FruitType.UNKNOWN then
        xmlFile:setString(key .. "#plannedFruit", "FALLOW")
    else
        xmlFile:setString(key .. "#plannedFruit", g_fruitTypeManager:getFruitTypeNameByIndex(self.plannedFruitTypeIndex))
    end
    self.fieldState:saveToXMLFile(xmlFile, key)
end
function Field:loadFromXMLFile(xmlFile, key)
    local plannedFruitName = xmlFile:getString(key .. "#plannedFruit")
    local plannedFruitDesc = g_fruitTypeManager:getFruitTypeByName(plannedFruitName)
    if plannedFruitName == "FALLOW" then
        self.plannedFruitTypeIndex = FruitType.UNKNOWN
    elseif plannedFruitDesc ~= nil then
        self.plannedFruitTypeIndex = plannedFruitDesc.index
    end
    self.fieldState:loadFromXMLFile(xmlFile, key)
end
function Field:getCenterOfFieldWorldPosition()
    return self.posX, self.posZ
end
function Field:getIndicatorPosition()
    if self.nameIndicator == nil then
        return self.posX, self.posZ
    end
    local x, _, z = getWorldTranslation(self.nameIndicator)
    return x, z
end
function Field:getTeleportPosition()
    if self.teleportNode == nil then
        return self.posX, self.posZ
    end
    local x, _, z = getWorldTranslation(self.teleportNode)
    return x, z
end
function Field:setFarmland(farmland)
    self.farmland = farmland
end
function Field:getFarmland()
    return self.farmland
end
function Field:getId()
    if self.farmland == nil then
        return nil
    else
        return self.farmland:getId()
    end
end
function Field:getName()
    if self.farmland == nil then
        if self.name == nil then
            return tostring(self:getId())
        else
            return self.name
        end
    else
        return self.farmland:getName()
    end
end
function Field:getAngle()
    return self.angle
end
function Field:getAreaHa()
    return self.areaHa
end
function Field:getTeleportNode()
    return self.teleportNode
end
function Field:getHasOwner()
    local farmId = FarmlandManager.NO_OWNER_FARM_ID
    if self.farmland ~= nil then
        farmId = g_farmlandManager:getFarmlandOwner(self.farmland:getId())
    end
    return farmId ~= FarmlandManager.NO_OWNER_FARM_ID
end
function Field:getOwner()
    local farmId = FarmlandManager.NO_OWNER_FARM_ID
    if self.farmland ~= nil then
        farmId = g_farmlandManager:getFarmlandOwner(self.farmland:getId())
    end
    return farmId
end
function Field:reset(immediate)
    if self.fieldState.isValid then
        local fieldUpdateTask = self.fieldState:createFieldUpdateTask()
        fieldUpdateTask:clearHeight()
        fieldUpdateTask:setArea(self:getDensityMapPolygon())
        Logging.devInfo("Field:reset - Added task to reset field \'%s\'", self:getName())
        g_fieldManager:addFieldUpdateTask(fieldUpdateTask, immediate)
    end
end
function Field:getPolygonPoints()
    return self.polygonPoints
end
function Field:getDensityMapPolygon()
    return self.densityMapPolygon
end
function Field:getPlannedFruitTypeIndex()
    return self.plannedFruitTypeIndex
end
function Field:getFieldState()
    return self.fieldState
end
function Field:getIsReadyForMission()
    if self:getId() == nil then
        return false
    elseif self.isMissionAllowed then
        if self.currentMission == nil then
            return not self:getHasOwner()
        else
            return false
        end
    else
        return false
    end
end
function Field:setMission(mission)
    self.currentMission = mission
end
function Field:updateState()
    if self.currentMission == nil or not self.currentMission:getIsRunning() then
        Logging.devInfo("Field:updateState - Updating state for field \'%s\'", self:getName())
        self.fieldState:update(self.posX, self.posZ)
    end
end
function Field:drawDebug(x, y)
    renderText(x, y, 0.02, "Field: " .. self:getName())
    y = y - 0.013
    if self.currentMission ~= nil then
        setTextColor(0, 1, 0, 1)
    end
    renderText(x, y, 0.012, "Mission: " .. tostring(self.currentMission ~= nil))
    setTextColor(1, 1, 1, 1)
    y = y - 0.013
    renderText(x, y, 0.012, "Planned: " .. tostring((g_fruitTypeManager:getFruitTypeNameByIndex(self.plannedFruitTypeIndex))))
    y = y - 0.013
    self.fieldState:drawDebug(x, y)
    return y
end