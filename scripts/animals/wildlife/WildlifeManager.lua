WildlifeManager = {}
local WildlifeManager_mt = Class(WildlifeManager)
g_xmlManager:addCreateSchemaFunction(function()
    WildlifeManager.xmlSchema = XMLSchema.new("wildlife")
    WildlifeManager.registerXMLPaths(WildlifeManager.xmlSchema)
end)
function WildlifeManager.registerXMLPaths(xmlSchema)
    xmlSchema:register(XMLValueType.STRING, "wildlife.annotation", "Copyright annotation")
    xmlSchema:register(XMLValueType.STRING, "wildlife.groups.group(?)#name", "Name of the wildlife group", nil, true)
    xmlSchema:register(XMLValueType.INT, "wildlife.groups.group(?)#maxNumInstances", "Maximum number of instances of this wildlife group", nil, false)
    xmlSchema:register(XMLValueType.STRING, "wildlife.species.species(?)#filename", "The config filename of the wildlife species", nil, true)
    xmlSchema:register(XMLValueType.STRING_LIST, "wildlife.species.species(?)#groups", "List of group names this wildlife species belongs to", nil, true)
end
function WildlifeManager.new()
    -- upvalues: (copy) WildlifeManager_mt
    local self = setmetatable({}, WildlifeManager_mt)
    self.nameToGroup = {}
    self.speciesToGroups = {}
    self.species = {}
    self.nameToSpecies = {}
    self.modSpecies = {}
    self.usedBudget = 0
    self.maximumBudget = 100
    self.speciesSpawnPending = false
    self.debugDrawActive = false
    return self
end
function WildlifeManager:registerModWildlifeFile(filename, baseDirectory, groupNames)
    table.insert(self.modSpecies, {
        ["filename"] = filename,
        ["baseDirectory"] = baseDirectory,
        ["groupNames"] = groupNames
    })
end
function WildlifeManager:unloadMapData()
    for _, species in pairs(self.species) do
        species:delete()
    end
    table.clear(self.species)
    table.clear(self.nameToGroup)
    table.clear(self.nameToSpecies)
    table.clear(self.modSpecies)
    removeConsoleCommand("gsWildlifeSpawn")
    removeConsoleCommand("gsWildlifeDebugToggle")
end
function WildlifeManager:loadMapData(xmlFile, baseDirectory)
    local filename = getXMLString(xmlFile, "map.wildlife#filename")
    if filename == nil then
        Logging.info("No wildlife file defined in map, skipping")
        return
    end
    local wildlifeXMLFile = Utils.getFilename(filename, baseDirectory)
    local wildlifeXMLFile = XMLFile.load("wildlife", wildlifeXMLFile, WildlifeManager.xmlSchema)
    if wildlifeXMLFile == nil then
        Logging.error("Could not load wildlife file at %s. Note that default wildlife is now stored under data/animals/wildlife.", wildlifeXMLFile)
        return
    end
    for _, groupKey in wildlifeXMLFile:iterator("wildlife.groups.group") do
        local name = wildlifeXMLFile:getValue(groupKey .. "#name")
        if name == nil then
            Logging.xmlWarning(wildlifeXMLFile, "Missing group name for \'%s\'", groupKey)
            break
        end
        self:addGroup(name, (wildlifeXMLFile:getValue(groupKey .. "#maxNumInstances")))
    end
    for _, groupKey in wildlifeXMLFile:iterator("wildlife.species.species") do
        local name = wildlifeXMLFile:getValue(groupKey .. "#filename")
        if name == nil then
            Logging.xmlWarning(wildlifeXMLFile, "Missing filename for wildlife species \'%s\'", groupKey)
        else
            local maxNumInstances = wildlifeXMLFile:getValue(groupKey .. "#groups")
            local species = self:loadSpecies(Utils.getFilename(name, baseDirectory), baseDirectory)
            if species ~= nil then
                self.speciesToGroups[species] = {}
                for _, groupName in ipairs(maxNumInstances) do
                    local group = self:addGroup(groupName, nil)
                    table.addElement(group.species, species)
                    table.addElement(self.speciesToGroups[species], group)
                end
            end
        end
    end
    wildlifeXMLFile:delete()
    for _, groupKey in ipairs(self.modSpecies) do
        local maxNumInstances = self:loadSpecies(Utils.getFilename(groupKey.filename, groupKey.baseDirectory), groupKey.baseDirectory)
        if maxNumInstances ~= nil then
            self.speciesToGroups[maxNumInstances] = self.speciesToGroups[maxNumInstances] or {}
            for _, _ in ipairs(groupKey.groupNames) do
                local groupName = self:addGroup(_, nil)
                table.addElement(groupName.species, maxNumInstances)
                table.addElement(self.speciesToGroups[maxNumInstances], groupName)
            end
        end
    end
    table.clear(self.modSpecies)
    self:initialise()
    if g_isDevelopmentVersion then
        addConsoleCommand("gsWildlifeSpawn", "Spawns a species instance", "consoleCommandSpawnSpecies", self, "speciesName;distance;numInstances;rotation", false)
        addConsoleCommand("gsWildlifeDebugToggle", "Toggles debug draw", "consoleCommandToggleDebugDraw", self)
    end
end
function WildlifeManager:addGroup(groupName, maxNumInstances)
    local groupNameUpper = string.upper(groupName)
    if self.nameToGroup[groupNameUpper] ~= nil then
        return self.nameToGroup[groupNameUpper]
    end
    local group = {
        ["name"] = groupName,
        ["species"] = {},
        ["maxNumInstances"] = maxNumInstances,
        ["numInstances"] = 0
    }
    self.nameToGroup[groupNameUpper] = group
    return group
end
function WildlifeManager:loadSpecies(filename, baseDirectory)
    local species = WildlifeUtil.createFromXMLFilename(filename, baseDirectory)
    if species == nil then
        return nil
    end
    local name = string.upper(species.name)
    if self.nameToSpecies[name] ~= nil then
        Logging.warning("Wildlife species \'%s\' already defined", species.name)
        species:delete()
        return nil
    end
    self.nameToSpecies[name] = species
    table.insert(self.species, species)
    return species
end
function WildlifeManager:initialise()
    for i, species in ipairs(self.species) do
        species:initialise()
    end
end
function WildlifeManager:update(dt)
    if g_localPlayer then
        for _, group in pairs(self.nameToGroup) do
            group.numInstances = 0
        end
        self.usedBudget = 0
        for _, group in ipairs(self.species) do
            group:update(dt)
            group.canBeSpawned = true
            self.usedBudget = self.usedBudget + group:getCosts()
            local groups = self.speciesToGroups[group]
            if groups ~= nil then
                local numInstances = group:getNumInstances()
                for _, group in ipairs(groups) do
                    group.numInstances = group.numInstances + numInstances
                    if group.maxNumInstances ~= nil and group.numInstances >= group.maxNumInstances then
                        group.canBeSpawned = false
                    end
                end
            end
        end
        self:trySpawnWildlife()
    end
end
function WildlifeManager:drawDebug()
    local y = 0.8
    setTextAlignment(RenderText.ALIGN_CENTER)
    setTextBold(true)
    renderText(0.8, y, 0.012, "Wildlife Groups")
    setTextBold(false)
    for groupName, group in pairs(self.nameToGroup) do
        y = y - 0.015
        setTextAlignment(RenderText.ALIGN_RIGHT)
        renderText(0.8, y, 0.012, string.format("%s : ", groupName))
        setTextAlignment(RenderText.ALIGN_LEFT)
        if group.maxNumInstances ~= nil and group.numInstances >= group.maxNumInstances then
            setTextColor(1, 0, 0, 1)
        end
        renderText(0.8, y, 0.012, string.format("%d / %d", group.numInstances, group.maxNumInstances or -1))
        setTextColor(1, 1, 1, 1)
    end
    local y = y - 0.025
    setTextAlignment(RenderText.ALIGN_CENTER)
    setTextBold(true)
    renderText(0.8, y, 0.012, "Wildlife Species")
    setTextBold(false)
    for groupName, group in pairs(self.species) do
        y = y - 0.015
        setTextAlignment(RenderText.ALIGN_RIGHT)
        renderText(0.8, y, 0.012, string.format("%s : ", group.name))
        setTextAlignment(RenderText.ALIGN_LEFT)
        if group.canBeSpawned == false then
            setTextColor(1, 0, 0, 1)
        end
        renderText(0.8, y, 0.012, string.format("%d => %d", group:getNumInstances(), group:getCosts()))
        setTextColor(1, 1, 1, 1)
        group:drawDebug()
    end
end
function WildlifeManager:trySpawnWildlife()
    if g_localPlayer == nil or g_localPlayer:getCurrentRootNode() == nil then
        return
    end
    if self.speciesSpawnPending then
        return
    end
    if self.usedBudget >= self.maximumBudget then
        return
    end
    local species = nil
    for _, s in ipairs_randomStart(self.species) do
        if s.canBeSpawned then
            species = s
            break
        end
    end
    if species == nil then
        return
    else
        local playerX, playerZ, playerRotY = g_localPlayer:getMapPositionAndLookYaw()
        local _ = getFovY(g_cameraManager:getActiveCamera())
        if species:getCanSpawnInstance() then
            self.speciesSpawnPending = true
            species:trySpawnAt(playerX, playerZ, playerRotY, _, function(success)
                -- upvalues: (copy) self, (ref) species
                self.speciesSpawnPending = false
                species:resetSpawnTimer(success)
            end)
        end
    end
end
function WildlifeManager:consoleCommandSpawnSpecies(speciesName, distance, numInstances, rot)
    if speciesName == nil then
        printError("Missing species name")
        return string.format("Available species: %s", table.concatKeys(self.nameToSpecies, ", "))
    end
    distance = tonumber(distance) or 50
    local x = tonumber(numInstances) or 1
    local species = math.clamp(x, 1, 100)
    local x = tonumber(rot) or 0
    local species = math.rad(x)
    local species = self.nameToSpecies[string.upper(speciesName)]
    if species == nil then
        printError(string.format("Species \'%s\' not defined for map", speciesName))
        return string.format("Available species: %s", table.concatKeys(self.nameToSpecies, ", "))
    end
    local x, z, rotY = g_localPlayer:getMapPositionAndLookYaw()
    local dirX, dirZ = MathUtil.getDirectionFromYRotation(rotY)
    local x = x + dirX * distance
    local z = z + dirZ * distance
    species:debugSpawn(x, getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z), z, species, species)
    return "Spawned species instances"
end
function WildlifeManager:consoleCommandToggleDebugDraw()
    self.debugDrawActive = not self.debugDrawActive
    if self.debugDrawActive then
        g_debugManager:addDrawable(self)
    else
        g_debugManager:removeDrawable(self)
    end
    return string.format("DebugDraw=%s", self.debugDrawActive)
end
g_wildlifeManager = WildlifeManager.new()