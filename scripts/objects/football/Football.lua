Football = {}
Football.TYPE_SHOT = 0
Football.TYPE_PASS = 1
Football.TYPE_DRIBBLE = 2
local Football_mt = Class(Football, PhysicsObject)
InitStaticObjectClass(Football, "Football")
function Football.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Football node")
    schema:register(XMLValueType.FLOAT, basePath .. "#radius", "Football radius")
    schema:register(XMLValueType.FLOAT, basePath .. "#rollingThreshold", "Football rolling threshold")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "shot")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "pass")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "dribble")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "rolling")
end
function Football.new(isServer, isClient, customMt)
    -- upvalues: (copy) Football_mt
    local self = PhysicsObject.new(isServer, isClient, customMt or Football_mt)
    self.forcedClipDistance = 200
    registerObjectClassName(self, "Football")
    return self
end
function Football:load(xmlFile, key, components, i3dMappings)
    local node = xmlFile:getValue(key .. "#node", nil, components, i3dMappings)
    if node == nil then
        return false
    end
    self:setNodeId(node)
    self.radius = xmlFile:getValue(key .. "#radius", 0.16)
    self.rollingThreshold = xmlFile:getValue(key .. "#rollingThreshold", 0.05)
    local baseDirectory = g_currentMission.baseDirectory
    self.samples = {}
    self.samples.shot = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "shot", baseDirectory, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, self)
    self.samples.pass = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "pass", baseDirectory, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, self)
    self.samples.dribble = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "dribble", baseDirectory, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, self)
    self.samples.rolling = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "rolling", baseDirectory, components, 0, AudioGroup.ENVIRONMENT, i3dMappings, self)
    self.lastPosX = 0
    self.lastPosY = 0
    self.lastPosZ = 0
    self.lastSpeed = 0
    return true
end
function Football:delete()
    g_soundManager:deleteSamples(self.samples)
    unregisterObjectClassName(self)
    self:removeChildrenFromNodeObject(self.nodeId)
    PhysicsObject:superClass().delete(self)
end
function Football:resetToWorldPosition(x, y, z, rx, ry, rz)
    if self.isServer then
        removeFromPhysics(self.nodeId)
        setWorldTranslation(self.nodeId, x, y, z)
        setWorldRotation(self.nodeId, rx, ry, rz)
        addToPhysics(self.nodeId)
        self.lastPosX = x
        self.lastPosY = y
        self.lastPosZ = z
    end
end
function Football:getCanBePickedUp()
    return false
end
function Football:update(dt)
    Football:superClass().update(self, dt)
    local x, y, z = getWorldTranslation(self.nodeId)
    local isRolling = false
    if not getIsSleeping(self.nodeId) then
        local terrainHeight = getTerrainHeightAtWorldPos(g_terrainNode, x, y, z)
        if math.abs(y - self.radius - terrainHeight) < self.rollingThreshold then
            self.lastSpeed = MathUtil.vector3Length(self.lastPosX - x, self.lastPosY - y, self.lastPosZ - z) / dt
        end
    end
    if isRolling then
        if not g_soundManager:getIsSamplePlaying(self.samples.rolling) then
            g_soundManager:playSample(self.samples.rolling)
        end
    elseif g_soundManager:getIsSamplePlaying(self.samples.rolling) then
        g_soundManager:stopSample(self.samples.rolling)
    end
    self.lastPosX = x
    self.lastPosY = y
    self.lastPosZ = z
end
function Football:onShot(shotType)
    if shotType == Football.TYPE_SHOT then
        g_soundManager:playSample(self.samples.shot)
        return
    elseif shotType == Football.TYPE_PASS then
        g_soundManager:playSample(self.samples.pass)
    elseif shotType == Football.TYPE_DRIBBLE then
        g_soundManager:playSample(self.samples.dribble)
    end
end
function Football:shoot(dirX, dirZ, angleDeg, velocity, shotType, connection)
    self:onShot(shotType)
    if self.isServer then
        g_server:broadcastEvent(FootballShootEvent.newServerToClient(self, shotType), false, connection)
        self.canShoot = false
        local x, y, z = getWorldTranslation(self.nodeId)
        local mass = getMass(self.nodeId)
        local impulse = math.deg(angleDeg)
        local dirY = math.tan(impulse)
        local impulse = mass * velocity
        addImpulse(self.nodeId, dirX * impulse, dirY * impulse, dirZ * impulse, x, y, z, false)
    else
        g_client:getServerConnection():sendEvent(FootballShootEvent.new(self, dirX, dirZ, angleDeg, velocity, shotType))
    end
end
function Football:getBallSpeed()
    return self.lastSpeed * 3600
end
g_soundManager:registerModifierType("FOOTBALL_SPEED", Football.getBallSpeed)