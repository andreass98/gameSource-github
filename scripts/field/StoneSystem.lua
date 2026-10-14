StoneSystem = {}
local StoneSystem_mt = Class(StoneSystem)
g_xmlManager:addCreateSchemaFunction(function()
    StoneSystem.xmlSchema = XMLSchema.new("stones")
end)
g_xmlManager:addInitSchemaFunction(function()
    local schema = StoneSystem.xmlSchema
    schema:register(XMLValueType.STRING, "map.stones#name", "Stone layer name")
    schema:register(XMLValueType.STRING, "map.stones#title", "Stone title")
    schema:register(XMLValueType.INT, "map.stones.general#firstChannel", "Stone first channel")
    schema:register(XMLValueType.INT, "map.stones.general#numChannels", "Stone num channels")
    schema:register(XMLValueType.VECTOR_N, "map.stones.mapColors.mapColor(?)#states", "Map color states", nil, true)
    schema:register(XMLValueType.VECTOR_4, "map.stones.mapColors.mapColor(?)#default", "Default map colors")
    schema:register(XMLValueType.VECTOR_4, "map.stones.mapColors.mapColor(?)#colorBlind", "Color blind map colors")
    schema:register(XMLValueType.INT, "map.stones.picking#maskValue", "Stone mask value")
    schema:register(XMLValueType.INT, "map.stones.picking#minValue", "Stone min value")
    schema:register(XMLValueType.INT, "map.stones.picking#maxValue", "Stone max value")
    schema:register(XMLValueType.INT, "map.stones.picking#pickedValue", "Stone picked value")
    schema:register(XMLValueType.FLOAT, "map.stones.picking#litersPerSqm", "Stone liters per sqm")
    schema:register(XMLValueType.INT, "map.stones.growth.update(?)#period", "Stone update period")
    schema:register(XMLValueType.INT, "map.stones.growth.update(?)#sourceState", "Stone update source state")
    schema:register(XMLValueType.INT, "map.stones.growth.update(?)#targetState", "Stone update target state")
    schema:register(XMLValueType.STRING, "map.stones.wear.type(?)#name", "Vehicle type name")
    schema:register(XMLValueType.FLOAT, "map.stones.wear.type(?)#multiplier1", "Multiplier in stone state 1")
    schema:register(XMLValueType.FLOAT, "map.stones.wear.type(?)#multiplier2", "Multiplier in stone state 2")
    schema:register(XMLValueType.FLOAT, "map.stones.wear.type(?)#multiplier3", "Multiplier in stone state 3")
end)
function StoneSystem.new(customMt)
    -- upvalues: (copy) StoneSystem_mt
    local self = setmetatable({}, customMt or StoneSystem_mt)
    self.baseDirectory = ""
    self.densityMap = nil
    self.growthMapping = {}
    self.wearByType = {}
    self.mapColor = {}
    self.mapColorBlind = {}
    return self
end
function StoneSystem:delete()
    removeConsoleCommand("gsStoneSystemAddDelta")
    removeConsoleCommand("gsStoneSystemSetState")
    removeConsoleCommand("gsStoneSystemToggleDebug")
    self.densityMap = nil
    if self.debugArea ~= nil then
        self.debugArea:delete()
    end
end
function StoneSystem:loadStones(filename)
    local xmlFile = XMLFile.load("stones", filename, StoneSystem.xmlSchema)
    self.name = xmlFile:getValue("map.stones#name") or self.name
    self.title = g_i18n:convertText(xmlFile:getValue("map.stones#title")) or self.title
    self.firstChannel = xmlFile:getValue("map.stones.general#firstChannel") or (self.firstChannel or 0)
    self.numChannels = xmlFile:getValue("map.stones.general#numChannels") or (self.numChannels or 3)
    self.maskValue = xmlFile:getValue("map.stones.picking#maskValue") or (self.maskValue or 1)
    self.minValue = xmlFile:getValue("map.stones.picking#minValue") or (self.minValue or 2)
    self.maxValue = xmlFile:getValue("map.stones.picking#maxValue") or (self.maxValue or 4)
    self.litersPerSqm = xmlFile:getValue("map.stones.picking#litersPerSqm") or (self.litersPerSqm or 5)
    self.pickedValue = xmlFile:getValue("map.stones.picking#pickedValue") or (self.pickedValue or 5)
    xmlFile:iterate("map.stones.growth.update", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) self
        local period = xmlFile:getValue(key .. "#period")
        local sourceState = xmlFile:getValue(key .. "#sourceState")
        local targetState = xmlFile:getValue(key .. "#targetState")
        if period ~= nil and (sourceState ~= nil and targetState ~= nil) then
            table.insert(self.growthMapping, {
                ["from"] = sourceState,
                ["to"] = targetState,
                ["period"] = period
            })
        end
    end)
    local color = {
        0.6,
        0.6,
        0.6,
        1
    }
    xmlFile:iterate("map.stones.mapColors.mapColor", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) color, (copy) self
        local states = xmlFile:getValue(key .. "#states", 1, true)
        if states == nil then
            Logging.xmlError(xmlFile, "Missing values for \'\'", key .. "#states")
        else
            local data = {
                ["states"] = states,
                ["color"] = xmlFile:getValue(key .. "#default", color, 4)
            }
            local dataBlind = {
                ["states"] = states,
                ["color"] = xmlFile:getValue(key .. "#colorBlind", color, 4)
            }
            table.insert(self.mapColor, data)
            table.insert(self.mapColorBlind, dataBlind)
        end
    end)
    self.wearByType = {}
    xmlFile:iterate("map.stones.wear.type", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) self
        local name = xmlFile:getValue(key .. "#name")
        local multiplier1 = xmlFile:getValue(key .. "#multiplier1")
        local multiplier2 = xmlFile:getValue(key .. "#multiplier2")
        local multiplier3 = xmlFile:getValue(key .. "#multiplier3")
        if name ~= nil and (multiplier1 ~= nil and (multiplier2 ~= nil and multiplier3 ~= nil)) then
            self.wearByType[string.upper(name)] = { multiplier1, multiplier2, multiplier3 }
        end
    end)
    xmlFile:delete()
end
function StoneSystem:loadMapData(xmlFile, _, baseDirectory)
    self.baseDirectory = baseDirectory
    self:loadStones("data/maps/maps_stones.xml")
    local filename = getXMLString(xmlFile, "map.stones#filename")
    if filename ~= nil then
        self:loadStones((Utils.getFilename(filename, baseDirectory)))
    end
    if g_server ~= nil and g_addCheatCommands then
        addConsoleCommand("gsStoneSystemAddDelta", "Add stone delta to field", "consoleCommandAddDelta", self, "fieldId; [delta]")
        addConsoleCommand("gsStoneSystemSetState", "Set stone state to field", "consoleCommandSetState", self, "fieldId; state")
        addConsoleCommand("gsStoneSystemToggleDebug", "Toggles debug view", "consoleCommandToggleDebug", self)
    end
    return true
end
function StoneSystem:addDensityMapSyncer(densityMapSyncer)
    if self.densityMap ~= nil then
        densityMapSyncer:addDensityMap(self.densityMap)
    end
end
function StoneSystem:getDensityMapData()
    return self.densityMap, self.firstChannel, self.numChannels
end
function StoneSystem:getMapHasStones()
    return self.densityMap ~= nil
end
function StoneSystem:getMinMaxValues()
    return self.minValue, self.maxValue
end
function StoneSystem:getPickedValue()
    return self.pickedValue
end
function StoneSystem:getMaskValue()
    return self.maskValue
end
function StoneSystem:getLitersPerSqm()
    return self.litersPerSqm
end
function StoneSystem:getWearMultiplierByType(name)
    if name == nil then
        return nil
    else
        return self.wearByType[string.upper(name)]
    end
end
function StoneSystem:initTerrain(_, terrainNode, _)
    local id, _ = getTerrainDataPlaneByName(terrainNode, self.name)
    if id ~= nil and id ~= 0 then
        self.densityMap = id
        self.stoneModifier = DensityMapModifier.new(self.densityMap, self.firstChannel, self.numChannels, g_terrainNode)
        self.stoneFilter = DensityMapFilter.new(self.stoneModifier)
    end
end
function StoneSystem:getGrowthMapping()
    return self.growthMapping
end
function StoneSystem:getColors()
    return self.mapColor, self.mapColorBlind
end
function StoneSystem:getTitle()
    return self.title
end
function StoneSystem:getStoneStateAtWorldPos(worldX, worldZ)
    return self.densityMap == nil and 0 or getDensityStatesAtWorldPos(self.densityMap, worldX, 0, worldZ)
end
function StoneSystem:getStoneLevelAtWorldPos(worldX, worldZ)
    if self.densityMap == nil then
        return 0
    end
    local value = getDensityStatesAtWorldPos(self.densityMap, worldX, 0, worldZ)
    if value == self.maskValue then
        return 0
    end
    return math.max(0, value - self.maskValue)
end
function StoneSystem:consoleCommandToggleDebug()
    self.isDebugAreaActive = not self.isDebugAreaActive
    if self.isDebugAreaActive then
        local colors = {
            [0] = Color.new(0, 0.5, 0, 0.05),
            [1] = Color.new(0, 0, 1, 0.075),
            [2] = Color.new(0.995, 0.685, 0, 0.05),
            [3] = Color.new(0.846, 0.216, 0, 0.05),
            [4] = Color.new(0.695, 0.007, 0, 0.05),
            [5] = Color.new(0, 1, 0, 0.05),
            [6] = Color.new(0, 1, 0, 0.05),
            [7] = Color.new(0, 1, 0, 0.05),
            [8] = Color.new(0, 1, 0, 0.05)
        }
        self.debugArea = DebugDensityMap.newFromMap(self.densityMap, self.firstChannel, self.numChannels, 20, 0.05, colors)
        g_debugManager:addElement(self.debugArea)
    elseif self.debugArea ~= nil then
        g_debugManager:removeElement(self.debugArea)
        self.debugArea:delete()
        self.debugArea = nil
    end
end
function StoneSystem:consoleCommandAddDelta(fieldId, delta)
    local field = tonumber(fieldId)
    delta = tonumber(delta) or 1
    if field == nil then
        return "Missing field index. gsStoneSystemAddDelta <fieldId> [<delta>]"
    end
    local field = g_fieldManager:getFieldById(field)
    if field == nil then
        return "Field not found"
    end
    if self.stoneModifier == nil then
        return "No stones defined for current map"
    end
    local modifier = self.stoneModifier
    local filter = self.stoneFilter
    modifier:clearPolygonPoints()
    for _, point in ipairs(field:getPolygonPoints()) do
        local x, _, z = getWorldTranslation(point)
        modifier:addPolygonPointWorldCoords(x, z)
    end
    local point = -delta
    filter:setValueCompareParams(DensityValueCompareType.GREATER, (math.max(point, 0)))
    modifier:executeAdd(delta, filter)
    filter:setValueCompareParams(DensityValueCompareType.GREATER, self.maxValue)
    modifier:executeSet(self.maxValue, filter)
    return "Added stone delta " .. delta
end
function StoneSystem:consoleCommandSetState(fieldId, state)
    local field = tonumber(fieldId)
    state = tonumber(state) or 1
    if field == nil then
        return "Missing field index. gsStoneSystemSetState <fieldId> [<state>]"
    end
    local field = g_fieldManager:getFieldById(field)
    if field == nil then
        return "Field not found"
    end
    if self.stoneModifier == nil then
        return "No stones defined for current map"
    end
    local modifier = self.stoneModifier
    local filter = self.stoneFilter
    modifier:clearPolygonPoints()
    for _, point in ipairs(field:getPolygonPoints()) do
        local x, _, z = getWorldTranslation(point)
        modifier:addPolygonPointWorldCoords(x, z)
    end
    filter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
    modifier:executeSet(state, filter)
    return "Set stone state " .. state
end