ObjectSpawner = {}
local ObjectSpawner_mt = Class(ObjectSpawner)
function ObjectSpawner.new(spawnFunction, numObjectsTarget, numSpawnsPerSecond, spawnMinRadius, spawnMaxRadius, destroyRadius, warmupCameraMove, warmupPercentage, updateFunction)
    -- upvalues: (copy) ObjectSpawner_mt
    local self = setmetatable({}, ObjectSpawner_mt)
    self.spawnFunction = spawnFunction
    self.updateFunction = updateFunction
    self.numObjectsTarget = numObjectsTarget
    self.spawnMinRadius = spawnMinRadius
    self.spawnMaxRadius = spawnMaxRadius
    self.destroyRadius = destroyRadius
    self.destroyRadiusSq = self.destroyRadius * self.destroyRadius
    self.warmupCameraMove = warmupCameraMove
    self.warmupCameraMoveSq = warmupCameraMove * warmupCameraMove
    self.warmupPercentage = warmupPercentage
    self.spawnInterval = 1 / (numSpawnsPerSecond * 0.001)
    self.spawnDt = 0
    self.isWarmedUp = false
    self.lastCx = 0
    self.lastCz = 0
    self.objects = {}
    self.numObjects = 0
    self.objectsCache = {}
    return self
end
function ObjectSpawner:delete()
    for _, object in pairs(self.objects) do
        if not object.isDeleted then
            object:delete()
        end
    end
    for _, object in pairs(self.objectsCache) do
        if not object.isDeleted then
            object:delete()
        end
    end
end
function ObjectSpawner:update(dt)
    local camera = g_cameraManager:getActiveCamera()
    local cx, cy, cz = getWorldTranslation(camera)
    if self.updateFunction == nil then
        for k, object in pairs(self.objects) do
            if not object.isDeleted then
                object:update(dt)
            end
        end
    else
        self.updateFunction(self, dt)
    end
    for k, object in pairs(self.objects) do
        if object.isDeleted then
            self.objects[k] = nil
            self.numObjects = self.numObjects - 1
        elseif object.requestDelete or object:getSquaredDistanceFrom(cx, cz) > self.destroyRadiusSq then
            object:removeFromScene()
            self.objects[k] = nil
            self.numObjects = self.numObjects - 1
            table.insert(self.objectsCache, object)
        end
    end
    local doWarmup = not self.isWarmedUp
    self.isWarmedUp = true
    if not doWarmup then
        local dx = cx - self.lastCx
        local dz = cz - self.lastCz
    end
    self.lastCx = cx
    self.lastCz = cz
    self.spawnDt = self.spawnDt + dt
    if doWarmup or self.spawnDt > self.spawnInterval then
        local dx = 0
        local dz = 1
        if doWarmup then
            dz = math.ceil(self.warmupPercentage * self.numObjectsTarget)
        end
        local object = self.numObjectsTarget - self.numObjects
        local k = math.min(object, dz)
        local object = 1
        local dz = k
        for i = 1, k, object do
            local object = self.spawnFunction(self, doWarmup, cx, cy, cz)
            if object ~= nil then
                self.objects[object] = object
                self.numObjects = self.numObjects + 1
            end
        end
        if dx > 0 or dz == 0 then
            self.spawnDt = 0
            return
        end
        self.spawnDt = self.spawnInterval * 0.75
    end
end
function ObjectSpawner:getObjectFromCache()
    local numObjects = #self.objectsCache
    while numObjects > 0 do
        local object = self.objectsCache[numObjects]
        table.remove(self.objectsCache, numObjects)
        numObjects = numObjects - 1
        if not object.isDeleted then
            return object
        end
    end
    return nil
end