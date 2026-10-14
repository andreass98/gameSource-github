RainSettings = {}
local RainSettings_mt = Class(RainSettings)
function RainSettings.new(customMt)
    -- upvalues: (copy) RainSettings_mt
    local self = setmetatable({}, customMt or RainSettings_mt)
    self.typeId = nil
    self.presetId = nil
    self.dropsMultiplier = 1
    self.maxDropsMultiplier = 1
    self.turbulence = 1
    self.turbulenceTimeScale = 0.5
    self.turbulencePulseDuration = 2
    self.spawnVelocityX = 0
    self.spawnVelocityY = -8
    self.spawnVelocityZ = 0
    self.mostConcentratedDistance = 5
    self.distributionPower = 3.2
    self.turbulenceFrequency = 1
    self.rainfallScale = 0
    self.snowfallScale = 0
    self.hailfallScale = 0
    self.maxBounces = 0
    self.bounceRandomFactor = 1
    self.bounceRestitution = 0.25
    return self
end
function RainSettings:load(xmlFile, key)
    self.maxDropsMultiplier = xmlFile:getFloat(key .. ".general#maxDropsMultiplier", self.maxDropsMultiplier)
    if self.maxDropsMultiplier > 1 then
        Logging.xmlWarning(xmlFile, "Valid range for maxDropsMultiplier is 0-1. Set value to 1 for \'%s\'", key)
        self.maxDropsMultiplier = 1
    end
    local velocityVector = xmlFile:getString(key .. ".general#spawnVelocity", nil)
    local velocityVector = string.getVector(velocityVector)
    if #velocityVector == 1 then
        self.spawnVelocityX = 0
        self.spawnVelocityY = velocityVector[1]
        self.spawnVelocityZ = 0
    elseif #velocityVector == 3 then
        self.spawnVelocityX = velocityVector[1]
        self.spawnVelocityY = velocityVector[2]
        self.spawnVelocityZ = velocityVector[3]
    end
    self.mostConcentratedDistance = xmlFile:getFloat(key .. ".general#mostConcentratedDistance", self.mostConcentratedDistance)
    self.distributionPower = xmlFile:getFloat(key .. ".general#distributionPower", self.distributionPower)
    self.turbulence = xmlFile:getFloat(key .. ".turbulence#value", self.turbulence)
    self.turbulenceTimeScale = xmlFile:getFloat(key .. ".turbulence#timeScale", self.turbulenceTimeScale)
    self.turbulencePulseDuration = xmlFile:getFloat(key .. ".turbulence#pulseDuration", self.turbulencePulseDuration)
    self.turbulenceFrequency = xmlFile:getFloat(key .. ".turbulence#frequency", self.turbulenceFrequency)
    self.rainfallScale = xmlFile:getFloat(key .. "#rainfallScale", self.rainfallScale)
    self.hailfallScale = xmlFile:getFloat(key .. "#hailfallScale", self.hailfallScale)
    self.snowfallScale = xmlFile:getFloat(key .. "#snowfallScale", self.snowfallScale)
    self.maxBounces = xmlFile:getUInt(key .. ".general#maxBounces", self.maxBounces)
    self.bounceRandomFactor = xmlFile:getFloat(key .. ".general#bounceRandomFactor", self.bounceRandomFactor)
    self.bounceRestitution = xmlFile:getFloat(key .. ".general#bounceRestitution", self.bounceRestitution)
    return true
end
function RainSettings:save(xmlFile, key)
    xmlFile:setFloat(key .. ".general#maxDropsMultiplier", self.maxDropsMultiplier)
    xmlFile:setString(key .. ".general#spawnVelocity", tostring(self.spawnVelocityX) .. " " .. tostring(self.spawnVelocityY) .. " " .. tostring(self.spawnVelocityZ))
    xmlFile:setFloat(key .. ".general#mostConcentratedDistance", self.mostConcentratedDistance)
    xmlFile:setFloat(key .. ".general#distributionPower", self.distributionPower)
    xmlFile:setUInt(key .. ".general#maxBounces", self.maxBounces)
    xmlFile:setFloat(key .. ".general#bounceRandomFactor", self.bounceRandomFactor)
    xmlFile:setFloat(key .. ".general#bounceRestitution", self.bounceRestitution)
    xmlFile:setFloat(key .. ".turbulence#value", self.turbulence)
    xmlFile:setFloat(key .. ".turbulence#timeScale", self.turbulenceTimeScale)
    xmlFile:setFloat(key .. ".turbulence#pulseDuration", self.turbulencePulseDuration)
    xmlFile:setFloat(key .. ".turbulence#frequency", self.turbulenceFrequency)
    return true
end
function RainSettings:clone()
    local ret = self.new()
    ret:copyAttributes(self)
    return ret
end
function RainSettings:copyAttributes(src)
    self.presetId = src.presetId
    self.typeId = src.typeId
    self.dropsMultiplier = src.dropsMultiplier
    self.maxDropsMultiplier = src.maxDropsMultiplier
    self.turbulence = src.turbulence
    self.turbulenceTimeScale = src.turbulenceTimeScale
    self.turbulencePulseDuration = src.turbulencePulseDuration
    self.spawnVelocityX = src.spawnVelocityX
    self.spawnVelocityY = src.spawnVelocityY
    self.spawnVelocityZ = src.spawnVelocityZ
    self.mostConcentratedDistance = src.mostConcentratedDistance
    self.distributionPower = src.distributionPower
    self.turbulenceFrequency = src.turbulenceFrequency
    self.rainfallScale = src.rainfallScale
    self.snowfallScale = src.snowfallScale
    self.hailfallScale = src.hailfallScale
    self.maxBounces = src.maxBounces
    self.bounceRandomFactor = src.bounceRandomFactor
    self.bounceRestitution = src.bounceRestitution
end