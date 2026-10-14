Farmland = {}
local Farmland_mt = Class(Farmland)
function Farmland.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#id", "Id of the farmland", nil, true)
    schema:register(XMLValueType.VECTOR_2, basePath .. "#indicatorPosition", "World position of the indicator", nil, false)
    schema:register(XMLValueType.STRING, basePath .. "#name", "Name of the farmland", nil, false)
    schema:register(XMLValueType.FLOAT, basePath .. "#areaInHa", "Area of the farmland in Ha", 2.5, false)
    schema:register(XMLValueType.FLOAT, basePath .. "#price", "Price of the farmland", nil, false)
    schema:register(XMLValueType.FLOAT, basePath .. "#priceScale", "Price scale of the farmland", 1, false)
    schema:register(XMLValueType.STRING, basePath .. "#npcName", "Name of the owner npc", nil, false)
    schema:register(XMLValueType.BOOL, basePath .. "#showOnFarmlandsScreen", "Indicates if the farmland should be shown on the map screen", true, false)
    schema:register(XMLValueType.BOOL, basePath .. "#defaultFarmProperty", "Indicates if the farmland is owned on start", true, false)
end
function Farmland.new(customMt)
    -- upvalues: (copy) Farmland_mt
    local self = setmetatable({}, customMt or Farmland_mt)
    self.isOwned = false
    self.xWorldPos = nil
    self.zWorldPos = nil
    self.field = nil
    self.boundingBox = nil
    return self
end
function Farmland:load(xmlFile, key)
    self.id = xmlFile:getValue(key .. "#id")
    if self.id == nil or self.id == 0 then
        Logging.xmlError(xmlFile, "Invalid farmland id \'%s\'!", self.id)
        return false
    end
    local name, npc = xmlFile:getValue(key .. "#indicatorPosition")
    self.xWorldPos = name
    self.zWorldPos = npc
    local name = xmlFile:getValue(key .. "#name")
    if name ~= nil then
        name = g_i18n:convertText(name, g_currentMission.loadingMapModName)
    end
    if not name then
        name = tostring(self.id)
    end
    self.name = name
    self.areaInHa = xmlFile:getValue(key .. "#areaInHa", 2.5)
    self.fixedPrice = xmlFile:getValue(key .. "#price")
    if self.fixedPrice == nil then
        self.priceFactor = xmlFile:getValue(key .. "#priceScale", 1)
    end
    self.price = self.fixedPrice or 1
    self:updatePrice()
    self.npcIndex = g_npcManager:getRandomIndex()
    local npc = g_npcManager:getNPCByName(xmlFile:getValue(key .. "#npcName"))
    if npc ~= nil then
        self.npcIndex = npc.index
    end
    self.isOwned = false
    self.showOnFarmlandsScreen = xmlFile:getValue(key .. "#showOnFarmlandsScreen", true)
    self.defaultFarmProperty = xmlFile:getValue(key .. "#defaultFarmProperty", false)
    self.farmId = FarmlandManager.NO_OWNER_FARM_ID
    return true
end
function Farmland:delete()
    if self.mapHotspot ~= nil then
        g_currentMission:removeMapHotspot(self.mapHotspot)
        self.mapHotspot:delete()
        self.mapHotspot = nil
    end
end
function Farmland:setField(field)
    self.field = field
    if field ~= nil and self.mapHotspot ~= nil then
        local xWorldPos, zWorldPos = field:getIndicatorPosition()
        self.mapHotspot:setWorldPosition(xWorldPos, zWorldPos)
    end
end
function Farmland:getField()
    return self.field
end
function Farmland:setIndicatorPosition(xWorldPos, zWorldPos)
    self.xWorldPos = xWorldPos
    self.zWorldPos = zWorldPos
    if self.mapHotspot ~= nil then
        self.mapHotspot:setWorldPosition(xWorldPos, zWorldPos)
    end
end
function Farmland:setBoundingBox(boundingBox)
    self.boundingBox = boundingBox
end
function Farmland:getBoundingBox()
    if self.boundingBox == nil then
        return nil, nil, nil, nil
    else
        return self.boundingBox.minX, self.boundingBox.minZ, self.boundingBox.maxX, self.boundingBox.maxZ
    end
end
function Farmland:getIndicatorPosition()
    if self.field == nil then
        return self.xWorldPos, self.zWorldPos
    else
        return self.field:getIndicatorPosition()
    end
end
function Farmland:getTeleportPosition()
    if self.field == nil then
        return self.xWorldPos, self.zWorldPos
    else
        return self.field:getTeleportPosition()
    end
end
function Farmland:getId()
    return self.id
end
function Farmland:getName()
    return self.name
end
function Farmland:setArea(areaInHa)
    self.areaInHa = areaInHa
    if self.fixedPrice == nil then
        self:updatePrice()
    end
end
function Farmland:updatePrice()
    self.price = g_farmlandManager:getPricePerHa() * self.areaInHa * self.priceFactor
end
function Farmland:getNPC()
    return g_npcManager:getNPCByIndex(self.npcIndex)
end
function Farmland:setOwnerFarmId(farmId)
    self.farmId = farmId
    self.isOwned = farmId ~= FarmlandManager.NO_OWNER_FARM_ID
    if self.mapHotspot ~= nil then
        self.mapHotspot:setOwnerFarmId(farmId)
    end
end
function Farmland:addMapHotspot()
    if self.mapHotspot ~= nil then
        g_currentMission:removeMapHotspot(self.mapHotspot)
        self.mapHotspot:delete()
        self.mapHotspot = nil
    end
    local mapHotspot = FarmlandHotspot.new()
    mapHotspot:setFarmland(self)
    self.mapHotspot = mapHotspot
    self.mapHotspot:setOwnerFarmId(self.farmId)
    g_currentMission:addMapHotspot(mapHotspot)
end
function Farmland:getMapHotspot()
    return self.mapHotspot
end