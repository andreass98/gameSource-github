WildlifeSpeciesFlyBy = {}
local WildlifeSpeciesFlyBy_mt = Class(WildlifeSpeciesFlyBy, WildlifeSpecies)
g_xmlManager:addInitSchemaFunction(function()
    local xmlSchema = WildlifeSpecies.xmlSchema
    xmlSchema:register(XMLValueType.INT, "species.flyBy#minNumAnimalsPerInstance")
    xmlSchema:register(XMLValueType.INT, "species.flyBy#maxNumAnimalsPerInstance")
    xmlSchema:register(XMLValueType.FLOAT, "species.flyBy#fallPerMeter")
    xmlSchema:register(XMLValueType.FLOAT, "species.flyBy#climbPerMeter")
    xmlSchema:register(XMLValueType.FLOAT, "species.flyBy#speedKmH")
    xmlSchema:register(XMLValueType.FLOAT, "species.flyBy#minDistanceToGround")
    xmlSchema:register(XMLValueType.FLOAT, "species.flyBy.group#minRadius")
    xmlSchema:register(XMLValueType.FLOAT, "species.flyBy.group#maxRadius")
    WildlifeInstanceGraphics.registerXMLPaths(xmlSchema, "species.flyBy")
end)
function WildlifeSpeciesFlyBy.new(customMt)
    -- upvalues: (copy) WildlifeSpeciesFlyBy_mt
    local self = WildlifeSpecies.new(customMt or WildlifeSpeciesFlyBy_mt)
    self.moveDistancePerMs = MathUtil.kmhToMps(10) / 1000
    self.fallPerMeter = 0.1
    self.climbPerMeter = 0.2
    self.minDistanceToGround = 20
    self.minNumAnimalsPerInstance = 1
    self.maxNumAnimalsPerInstance = 1
    self.groupMinRadius = 0.5
    self.groupMaxRadius = 10
    self.graphics = 10
    return self
end
function WildlifeSpeciesFlyBy:loadFromXML(xmlFile, baseDirectory)
    if not WildlifeSpeciesFlyBy:superClass().loadFromXML(self, xmlFile, baseDirectory) then
        return false
    end
    self.moveDistancePerMs = MathUtil.kmhToMps(xmlFile:getValue("species.flyBy#speedKmH", 20)) / 1000
    self.fallPerMeter = xmlFile:getValue("species.flyBy#fallPerMeter", self.fallPerMeter)
    self.climbPerMeter = xmlFile:getValue("species.flyBy#climbPerMeter", self.climbPerMeter)
    self.minDistanceToGround = xmlFile:getValue("species.flyBy#minDistanceToGround", self.minDistanceToGround)
    self.minNumAnimalsPerInstance = math.max(xmlFile:getValue("species.flyBy#minNumAnimalsPerInstance", self.minNumAnimalsPerInstance), 1)
    self.maxNumAnimalsPerInstance = math.max(xmlFile:getValue("species.flyBy#maxNumAnimalsPerInstance", self.maxNumAnimalsPerInstance), 1)
    self.groupMinRadius = xmlFile:getValue("species.flyBy.group#minRadius", self.groupMinRadius)
    self.groupMaxRadius = xmlFile:getValue("species.flyBy.group#maxRadius", self.groupMaxRadius)
    self.graphics = WildlifeInstanceGraphics.loadAttributesTable(xmlFile, "species.flyBy")
    if self.maxNumAnimalsPerInstance < self.minNumAnimalsPerInstance then
        self.minNumAnimalsPerInstance = self.maxNumAnimalsPerInstance
        self.maxNumAnimalsPerInstance = self.minNumAnimalsPerInstance
    end
    return true
end
function WildlifeSpeciesFlyBy:getInstanceConstructor()
    return WildlifeInstanceFlyByGroup.new
end
function WildlifeSpeciesFlyBy:trySpawnAt(playerX, playerZ, playerRotY, cameraFovY, callbackFunc)
    if not WildlifeSpeciesFlyBy:superClass().trySpawnAt(self, playerX, playerZ, playerRotY, cameraFovY, callbackFunc) then
        return false
    end
    local spawnDistance = MathUtil.randomFloat(self.spawnRadiusMin, self.spawnRadiusMax)
    local x, z = WildlifeUtil.calculateRandomSpawnPosition(playerX, playerZ, playerRotY, cameraFovY, spawnDistance)
    local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + self.minDistanceToGround
    local intersectDistance = MathUtil.randomFloat(0, self.spawnRadiusMin)
    local intersectAngle = MathUtil.randomFloat(-3.141592653589793, 3.141592653589793)
    local intersectX = playerX + math.cos(intersectAngle) * intersectDistance
    local intersectZ = playerZ + math.sin(intersectAngle) * intersectDistance
    local directionX, directionZ = MathUtil.vector2Normalize(intersectX - x, intersectZ - z)
    self:spawnInstances(x, y, z, math.random(self.minNumAnimalsPerInstance, self.maxNumAnimalsPerInstance), directionX, directionZ)
    return true
end
function WildlifeSpeciesFlyBy:spawnInstances(x, y, z, numAnimals, flyDirectionX, flyDirectionZ)
    local instance = self:createInstance()
    instance:setFlyDirection(flyDirectionX, flyDirectionZ)
    instance:setNumAnimals(numAnimals)
    instance:setGroupRadius(self.groupMinRadius, self.groupMaxRadius)
    instance:spawnAt(x, y, z)
    self:finishSpawning(true)
end
function WildlifeSpeciesFlyBy:debugSpawn(x, y, z, numAnimals, rot)
    WildlifeSpeciesFlyBy:superClass().debugSpawn(self, x, y, z, numAnimals)
    local rx, rz = MathUtil.getDirectionFromYRotation(rot or 0)
    self:spawnInstances(x, y, z, numAnimals, rx, rz)
end