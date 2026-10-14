BunkerSiloCompacter = {}
BunkerSiloCompacter.XML_PATH = "vehicle.bunkerSiloCompacter"
function BunkerSiloCompacter.prerequisitesPresent(specializations)
    return true
end
function BunkerSiloCompacter.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("BunkerSiloCompacter")
    schema:register(XMLValueType.FLOAT, BunkerSiloCompacter.XML_PATH .. "#compactingScale", "Compacting scale", 1)
    schema:register(XMLValueType.BOOL, BunkerSiloCompacter.XML_PATH .. "#useSpeedLimit", "Defines if speed limit is used while compactor has contact with ground", false)
    SoundManager.registerSampleXMLPaths(schema, BunkerSiloCompacter.XML_PATH .. ".sounds", "rolling")
    SoundManager.registerSampleXMLPaths(schema, BunkerSiloCompacter.XML_PATH .. ".sounds", "compacting")
    schema:setXMLSpecializationType()
end
function BunkerSiloCompacter.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadBunkerSiloCompactorFromXML", BunkerSiloCompacter.loadBunkerSiloCompactorFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getBunkerSiloCompacterScale", BunkerSiloCompacter.getBunkerSiloCompacterScale)
end
function BunkerSiloCompacter.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", BunkerSiloCompacter.doCheckSpeedLimit)
end
function BunkerSiloCompacter.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", BunkerSiloCompacter)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", BunkerSiloCompacter)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", BunkerSiloCompacter)
end
function BunkerSiloCompacter:onLoad(_)
    self:loadBunkerSiloCompactorFromXML(self.xmlFile, BunkerSiloCompacter.XML_PATH)
    if self.isClient then
        self.spec_bunkerSiloCompacter.samples = {}
        spec.samples.rolling = g_soundManager:loadSampleFromXML(self.xmlFile, BunkerSiloCompacter.XML_PATH .. ".sounds", "rolling", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.compacting = g_soundManager:loadSampleFromXML(self.xmlFile, BunkerSiloCompacter.XML_PATH .. ".sounds", "compacting", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.lastIsCompacting = false
        spec.lastHasGroundContact = false
    end
    if self.getWheels == nil then
        SpecializationUtil.removeEventListener(self, "onUpdate", BunkerSiloCompacter)
    end
end
function BunkerSiloCompacter:onDelete()
    g_soundManager:deleteSamples(self.spec_bunkerSiloCompacter.samples)
end
function BunkerSiloCompacter:loadBunkerSiloCompactorFromXML(xmlFile, key)
    local spec = self.spec_bunkerSiloCompacter
    spec.scale = xmlFile:getValue(key .. "#compactingScale", 1)
    spec.useSpeedLimit = xmlFile:getValue(key .. "#useSpeedLimit", false)
end
function BunkerSiloCompacter:getBunkerSiloCompacterScale()
    return self.spec_bunkerSiloCompacter.scale
end
function BunkerSiloCompacter:onUpdate(_, _, _, _)
    local spec = self.spec_bunkerSiloCompacter
    local hasGroundContact = false
    local isCompacting = false
    local wheels = self:getWheels()
    local i = 1
    for i = i, #wheels do
        local wheel = wheels[i]
        if wheel.physics.contact ~= WheelContactType.NONE then
            hasGroundContact = true
            if wheel.physics.contact == WheelContactType.GROUND_HEIGHT then
                isCompacting = true
                break
            end
        end
    end
    if spec.lastHasGroundContact ~= hasGroundContact or spec.lastIsCompacting ~= isCompacting then
        if hasGroundContact then
            if isCompacting then
                if not g_soundManager:getIsSamplePlaying(spec.samples.compacting) then
                    g_soundManager:playSample(spec.samples.compacting)
                end
            elseif g_soundManager:getIsSamplePlaying(spec.samples.compacting) then
                g_soundManager:stopSample(spec.samples.compacting)
            end
            if not g_soundManager:getIsSamplePlaying(spec.samples.rolling) then
                g_soundManager:playSample(spec.samples.rolling)
            end
        else
            if g_soundManager:getIsSamplePlaying(spec.samples.compacting) then
                g_soundManager:stopSample(spec.samples.compacting)
            end
            if g_soundManager:getIsSamplePlaying(spec.samples.rolling) then
                g_soundManager:stopSample(spec.samples.rolling)
            end
        end
        spec.lastHasGroundContact = hasGroundContact
        spec.lastIsCompacting = isCompacting
    end
end
function BunkerSiloCompacter:doCheckSpeedLimit(superFunc)
    local spec = self.spec_bunkerSiloCompacter
    if spec.useSpeedLimit then
        return superFunc(self) or spec.lastIsCompacting
    else
        return superFunc(self)
    end
end
function BunkerSiloCompacter.getDefaultSpeedLimit()
    return 5
end