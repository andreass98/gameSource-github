WildlifeSpecies = {}
local WildlifeSpecies_mt = Class(WildlifeSpecies)
WildlifeSpecies.SPAWN_COLLISION_MASK = CollisionFlag.TERRAIN + CollisionFlag.WATER
WildlifeSpecies.BASE_SPAWN_RULES_DIRECTORY = "dataS/scripts/animals/wildlife/spawnRules/"
function WildlifeSpecies.formatRange(range)
    return type(range) ~= "table" and "nil" or string.format("min: %.2f, max: %.2f", range.minimum, range.maximum)
end
g_xmlManager:addCreateSchemaFunction(function()
    WildlifeSpecies.xmlSchema = XMLSchema.new("wildlifeSpecies")
end)
g_xmlManager:addInitSchemaFunction(function()
    local xmlSchema = WildlifeSpecies.xmlSchema
    xmlSchema:register(XMLValueType.STRING, "species.annotation", "Copyright annotation")
    xmlSchema:register(XMLValueType.STRING, "species.class", "The controller class of the wildlife species", nil, true)
    xmlSchema:register(XMLValueType.STRING, "species.name", "The name of the wildlife species", nil, true)
    xmlSchema:register(XMLValueType.INT, "species.settings#maxNumInstances", "Max number of instances per species", nil, true)
    xmlSchema:register(XMLValueType.FLOAT, "species.settings#costPerAnimal", "The spawn cost of the wildlife species", nil, true)
    xmlSchema:register(XMLValueType.FLOAT, "species.settings#fleeDistance", "Flee distance")
    xmlSchema:register(XMLValueType.FLOAT, "species.settings.foliageBending#minX", "Min. width")
    xmlSchema:register(XMLValueType.FLOAT, "species.settings.foliageBending#maxX", "Max. width")
    xmlSchema:register(XMLValueType.FLOAT, "species.settings.foliageBending#minZ", "Min. length")
    xmlSchema:register(XMLValueType.FLOAT, "species.settings.foliageBending#maxZ", "Max. length")
    xmlSchema:register(XMLValueType.FLOAT, "species.settings.foliageBending#yOffset", "Y translation offset")
    xmlSchema:register(XMLValueType.FLOAT, "species.settings.spawnTimer#minSeconds", "Min time need to pass by to spawn a new instance")
    xmlSchema:register(XMLValueType.FLOAT, "species.settings.spawnTimer#maxSeconds", "Max time need to pass by to spawn a new instance")
    xmlSchema:register(XMLValueType.FLOAT, "species.settings.spawnTimer#retryMinSeconds", "Min time need to pass by to try spawning a new instance after a spawn failure")
    xmlSchema:register(XMLValueType.FLOAT, "species.settings.spawnTimer#retryMaxSeconds", "Max time need to pass by to try spawning a new instance after a spawn failure")
    xmlSchema:register(XMLValueType.FLOAT, "species.settings.despawn#radius", "Distance to player after a instance will despawn")
    xmlSchema:register(XMLValueType.FLOAT, "species.settings.spawn#radiusMin", "A instance cannot spawn within the min radius")
    xmlSchema:register(XMLValueType.FLOAT, "species.settings.spawn#radiusMax", "A instance cannot spawn if distance is greater than max radius")
    xmlSchema:register(XMLValueType.DAY_TIME, "species.settings.time#from", "Start day time")
    xmlSchema:register(XMLValueType.DAY_TIME, "species.settings.time#to", "End day time")
    xmlSchema:register(XMLValueType.FLOAT, "species.settings.treeCheck#radius", "", nil, false)
    xmlSchema:register(XMLValueType.FLOAT, "species.settings.treeCheck#height", "", nil, false)
    xmlSchema:register(XMLValueType.INT, "species.settings.treeCheck#minNumTrees", "", nil, false)
end)
function WildlifeSpecies.new(customMt)
    -- upvalues: (copy) WildlifeSpecies_mt
    local self = setmetatable({}, customMt or WildlifeSpecies_mt)
    self.name = nil
    self.costPerAnimal = 1
    self.maxNumInstances = 1
    self.instances = {}
    self.fleeDistance = nil
    self.foliageBendingArea = nil
    self.spawnTimerMinSeconds = 60000
    self.spawnTimerMaxSeconds = 60000
    self.spawnTimer = self.spawnTimerMinSeconds
    self.despawnRadius = 200
    self.spawnRadiusMin = 120
    self.spawnRadiusMax = 150
    self.treeCheckRadius = 15
    self.treeCheckHeight = 15
    self.treeCheckMinNumTrees = 15
    self.pooledInstances = ObjectPool.new(self:getInstanceConstructor(), self)
    return self
end
function WildlifeSpecies:initialise() end
function WildlifeSpecies:getInstanceConstructor()
    return WildlifeInstance.new
end
function WildlifeSpecies:delete()
    for _, instance in pairs(self.instances) do
        self.pooledInstances:returnToPool(instance)
    end
    table.clear(self.instances)
    for _, instance in pairs(self.pooledInstances.pool) do
        instance:delete()
    end
    self.pooledInstances:clear()
end
function WildlifeSpecies:loadFromXML(xmlFile, _)
    self.name = xmlFile:getValue("species.name")
    if self.name == nil then
        Logging.xmlWarning(xmlFile, "Missing wildlife species name")
        return false
    end
    self.isSpawnPending = false
    self.spawnCallbackFunc = nil
    self.costPerAnimal = xmlFile:getValue("species.settings#costPerAnimal", 1)
    self.maxNumInstances = xmlFile:getValue("species.settings#maxNumInstances", 1)
    self.fleeDistance = xmlFile:getValue("species.settings#fleeDistance", self.fleeDistance)
    self.timeFrom = xmlFile:getValue("species.settings.time#from") or 0
    self.timeTo = xmlFile:getValue("species.settings.time#to") or 86400000
    self.spawnTimerRetryMinSeconds = xmlFile:getValue("species.settings.spawnTimer#retryMinSeconds", 5) * 1000
    self.spawnTimerRetryMaxSeconds = xmlFile:getValue("species.settings.spawnTimer#retryMaxSeconds", 10) * 1000
    self.spawnTimerMinSeconds = xmlFile:getValue("species.settings.spawnTimer#minSeconds", 10) * 1000
    self.spawnTimerMaxSeconds = xmlFile:getValue("species.settings.spawnTimer#maxSeconds", 60) * 1000
    self:resetSpawnTimer(true)
    if xmlFile:hasProperty("species.settings.foliageBending") then
        self.foliageBendingArea = {}
        self.foliageBendingArea.minX = xmlFile:getValue("species.settings.foliageBending#minX", -1)
        self.foliageBendingArea.maxX = xmlFile:getValue("species.settings.foliageBending#maxX", 1)
        self.foliageBendingArea.minZ = xmlFile:getValue("species.settings.foliageBending#minZ", -1)
        self.foliageBendingArea.maxZ = xmlFile:getValue("species.settings.foliageBending#maxZ", 1)
        self.foliageBendingArea.yOffset = xmlFile:getValue("species.settings.foliageBending#yOffset", 0)
    end
    self.despawnRadius = xmlFile:getValue("species.settings.despawn#radius", self.despawnRadius)
    self.spawnRadiusMin = xmlFile:getValue("species.settings.spawn#radiusMin", self.spawnRadiusMin)
    self.spawnRadiusMax = xmlFile:getValue("species.settings.spawn#radiusMax", self.spawnRadiusMax)
    self.treeCheckRadius = xmlFile:getValue("species.settings.treeCheck#radius", self.treeCheckRadius)
    self.treeCheckHeight = xmlFile:getValue("species.settings.treeCheck#height", self.treeCheckHeight)
    self.treeCheckMinNumTrees = xmlFile:getValue("species.settings.treeCheck#minNumTrees", self.treeCheckMinNumTrees)
    return true
end
function WildlifeSpecies:update(dt)
    self.spawnTimer = self.spawnTimer - dt
    local playerX, playerZ, playerRotY = g_localPlayer:getMapPositionAndLookYaw()
    for k, instance in ipairs_reverse(self.instances) do
        instance:update(dt)
        if self:getCanDespawnInstance(instance, playerX, playerZ, playerRotY) then
            self:despawn(instance)
        end
    end
end
function WildlifeSpecies:drawDebug()
    for k, instance in ipairs(self.instances) do
        instance:drawDebug()
    end
end
function WildlifeSpecies:getCanDespawnInstance(instance, playerX, playerZ, _)
    return instance:calculateDistanceFrom(playerX, playerZ) > self.despawnRadius
end
function WildlifeSpecies:getCosts()
    local numInstances = 0
    for _, instance in ipairs(self.instances) do
        numInstances = instance:getNumAnimals()
    end
    return numInstances * self.costPerAnimal
end
function WildlifeSpecies:getNumInstances()
    return #self.instances
end
function WildlifeSpecies:despawn(instance)
    if instance ~= nil then
        instance:despawn()
        self:removeInstance(instance)
    end
end
function WildlifeSpecies:removeInstance(instance)
    table.removeElement(self.instances, instance)
    self.pooledInstances:returnToPool(instance)
end
function WildlifeSpecies:createInstance()
    local instance = self.pooledInstances:getOrCreateNext()
    table.addElement(self.instances, instance)
    return instance
end
function WildlifeSpecies:getCanSpawnInstance()
    if self.spawnTimer > 0 then
        return false
    end
    if #self.instances >= self.maxNumInstances then
        return false
    end
    if self.isSpawnPending then
        return false
    end
    return not MathUtil.getIsOutOfBounds(g_currentMission.environment.dayTime, self.timeFrom, self.timeTo)
end
function WildlifeSpecies:resetSpawnTimer(success)
    if success then
        self.spawnTimer = MathUtil.randomFloat(self.spawnTimerMinSeconds, self.spawnTimerMaxSeconds)
    else
        self.spawnTimer = MathUtil.randomFloat(self.spawnTimerRetryMinSeconds, self.spawnTimerRetryMaxSeconds)
    end
end
function WildlifeSpecies:trySpawnAt(_, _, _, _, callbackFunc)
    if self.isSpawnPending then
        callbackFunc(false)
        return false
    end
    self.spawnCallbackFunc = callbackFunc
    self.isSpawnPending = true
    return true
end
function WildlifeSpecies:debugSpawn(_, _, _, _)
    self.isSpawnPending = true
end
function WildlifeSpecies:finishSpawning(success)
    if self.spawnCallbackFunc ~= nil then
        self.spawnCallbackFunc(success)
        self.spawnCallbackFunc = nil
    end
    self.isSpawnPending = false
end
function WildlifeSpecies:runForestCheck(x, y, z, callbackFunc)
    WildlifeUtil.getNumOfTrees(x, y, z, self.treeCheckRadius, self.treeCheckHeight, function(numTrees)
        -- upvalues: (copy) callbackFunc, (copy) self
        callbackFunc(self.treeCheckMinNumTrees <= numTrees)
    end)
end