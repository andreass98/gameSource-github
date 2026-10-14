PlaceableWindTurbine = {}
function PlaceableWindTurbine.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableIncomePerHour, specializations)
end
function PlaceableWindTurbine.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "updateHeadRotation", PlaceableWindTurbine.updateHeadRotation)
    SpecializationUtil.registerFunction(placeableType, "updateRotorRotSpeed", PlaceableWindTurbine.updateRotorRotSpeed)
    SpecializationUtil.registerFunction(placeableType, "setWindValues", PlaceableWindTurbine.setWindValues)
    SpecializationUtil.registerFunction(placeableType, "getWindTurbineLoad", PlaceableWindTurbine.getWindTurbineLoad)
    SpecializationUtil.registerFunction(placeableType, "startWindTurbine", PlaceableWindTurbine.startWindTurbine)
end
function PlaceableWindTurbine.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getIncomePerHour", PlaceableWindTurbine.getIncomePerHour)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "finalizeConstruction", PlaceableWindTurbine.finalizeConstruction)
end
function PlaceableWindTurbine.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableWindTurbine)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableWindTurbine)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableWindTurbine)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableWindTurbine)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableWindTurbine)
end
function PlaceableWindTurbine.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("WindTurbine")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".windTurbine#headNode", "Head node")
    schema:register(XMLValueType.BOOL, basePath .. ".windTurbine#headAdjustToWind", "Adjust head node to current wind direction")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".windTurbine#rotationNode", "Rotor rotation node, rotated on z-axis")
    schema:register(XMLValueType.FLOAT, basePath .. ".windTurbine#optimalWindSpeed", "Wind speed in m/s at which rotor reaches max rpm")
    schema:register(XMLValueType.FLOAT, basePath .. ".windTurbine#incomePerHour", "Income per hour")
    schema:register(XMLValueType.BOOL, basePath .. ".windTurbine#isFinalized", "If the wind turbine is finalized and ready on start. E.g. constructible")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".windTurbine.sounds", "idle")
    AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".windTurbine.animationNodes")
    schema:setXMLSpecializationType()
end
function PlaceableWindTurbine.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("WindTurbine")
    schema:register(XMLValueType.ANGLE, basePath .. "#headRotation", "Current head rotation")
    schema:setXMLSpecializationType()
end
function PlaceableWindTurbine:onLoad(_)
    local spec = self.spec_windTurbine
    local headNode = self.xmlFile:getValue("placeable.windTurbine#headNode", nil, self.components, self.i3dMappings)
    if headNode ~= nil then
        spec.headNode = headNode
        spec.headAdjustToWind = self.xmlFile:getValue("placeable.windTurbine#headAdjustToWind", false)
        spec.headRotation = 0
    end
    spec.rotorOptimalWindSpeed = math.clamp(self.xmlFile:getValue("placeable.windTurbine#optimalWindSpeed", 15), 1, 200)
    spec.rotSpeedFactor = 1
    spec.incomePerHour = self.xmlFile:getValue("placeable.windTurbine#incomePerHour", 0)
    spec.isFinalized = self.xmlFile:getBool("placeable.windTurbine#isFinalized", true)
    if self.isClient then
        spec.samples = {}
        spec.samples.idle = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.windTurbine.sounds", "idle", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
        spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "placeable.windTurbine.animationNodes", self.components, self, self.i3dMappings)
        for _, anim in ipairs(spec.animationNodes) do
            function anim.speedFunc()
                -- upvalues: (copy) spec
                return spec.rotSpeedFactor
            end
        end
    end
end
function PlaceableWindTurbine:onDelete()
    g_currentMission.environment.weather.windUpdater:removeWindChangedListener(self)
    local spec = self.spec_windTurbine
    g_soundManager:deleteSamples(spec.samples)
    g_animationManager:deleteAnimations(spec.animationNodes)
end
function PlaceableWindTurbine:onFinalizePlacement()
    if self.spec_windTurbine.isFinalized then
        self:startWindTurbine()
    end
end
function PlaceableWindTurbine:onReadStream(streamId, _)
    local spec = self.spec_windTurbine
    if spec.headNode ~= nil then
        spec.headRotation = NetworkUtil.readCompressedAngle(streamId)
    end
end
function PlaceableWindTurbine:onWriteStream(streamId, _)
    local spec = self.spec_windTurbine
    if spec.headNode ~= nil then
        NetworkUtil.writeCompressedAngle(streamId, spec.headRotation)
    end
end
function PlaceableWindTurbine:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_windTurbine
    if spec.headNode ~= nil then
        spec.headRotation = xmlFile:getValue(key .. "#headRotation", 0)
        self:updateHeadRotation()
    end
end
function PlaceableWindTurbine:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_windTurbine
    if spec.headNode ~= nil then
        xmlFile:setValue(key .. "#headRotation", spec.headRotation)
    end
end
function PlaceableWindTurbine:startWindTurbine()
    local spec = self.spec_windTurbine
    local windUpdater = g_currentMission.environment.weather.windUpdater
    windUpdater:addWindChangedListener(self)
    local windDirX, windDirZ, windVelocity = windUpdater:getCurrentValues()
    if spec.headNode ~= nil then
        spec.headRotation = MathUtil.getYRotationFromDirection(-windDirX, -windDirZ)
        if not spec.headAdjustToWind then
            spec.headRotation = 0.7 + math.random() * 2 * 0.2 - 0.2
        end
        self:updateHeadRotation()
    end
    self:updateRotorRotSpeed(windVelocity)
    g_animationManager:startAnimations(spec.animationNodes)
end
function PlaceableWindTurbine:finalizeConstruction(superFunc)
    superFunc(self)
    self.spec_windTurbine.isFinalized = true
    self:startWindTurbine()
end
function PlaceableWindTurbine:updateHeadRotation()
    local spec = self.spec_windTurbine
    if spec.headNode ~= nil then
        setWorldRotation(spec.headNode, 0, spec.headRotation, 0)
    end
end
function PlaceableWindTurbine:updateRotorRotSpeed(windVelocity)
    local spec = self.spec_windTurbine
    spec.rotSpeedFactor = math.clamp(windVelocity / spec.rotorOptimalWindSpeed, 0, 1)
    if self.isClient then
        if spec.rotSpeedFactor > 0 then
            if not g_soundManager:getIsSamplePlaying(spec.samples.idle) then
                g_soundManager:playSample(spec.samples.idle, 0)
                return
            end
        elseif g_soundManager:getIsSamplePlaying(spec.samples.idle) then
            g_soundManager:stopSample(spec.samples.idle)
        end
    end
end
function PlaceableWindTurbine:setWindValues(windDirX, windDirZ, windVelocity, _)
    local spec = self.spec_windTurbine
    if spec.headAdjustToWind and spec.headNode ~= nil then
        spec.headRotation = MathUtil.getYRotationFromDirection(-windDirX, -windDirZ)
        self:updateHeadRotation()
    end
    self:updateRotorRotSpeed(windVelocity)
end
function PlaceableWindTurbine:getWindTurbineLoad()
    return self.spec_windTurbine.rotSpeedFactor
end
g_soundManager:registerModifierType("WIND_TURBINE_LOAD", PlaceableWindTurbine.getWindTurbineLoad)
function PlaceableWindTurbine:getIncomePerHour(superFunc)
    local spec = self.spec_windTurbine
    return superFunc(self) + spec.incomePerHour * spec.rotSpeedFactor
end