HighPressureWasher = {}
function HighPressureWasher.prerequisitesPresent(specializations)
    return true
end
function HighPressureWasher.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("HighPressureWasher")
    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.highPressureWasher.animationNodes")
    EffectManager.registerEffectXMLPaths(schema, "vehicle.highPressureWasher.effects")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.highPressureWasher.sounds", "start(?)")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.highPressureWasher.sounds", "stop(?)")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.highPressureWasher.sounds", "work(?)")
    schema:setXMLSpecializationType()
end
function HighPressureWasher.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", HighPressureWasher)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", HighPressureWasher)
    SpecializationUtil.registerEventListener(vehicleType, "onHandToolStoredInHolder", HighPressureWasher)
    SpecializationUtil.registerEventListener(vehicleType, "onHandToolTakenFromHolder", HighPressureWasher)
end
function HighPressureWasher:onLoad(_)
    if self.isClient then
        self.spec_highPressureWasher.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.highPressureWasher.animationNodes", self.components, self, self.i3dMappings)
        spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.highPressureWasher.effects", self.components, self, self.i3dMappings)
        spec.samples = {}
        spec.samples.start = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.highPressureWasher.sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.stop = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.highPressureWasher.sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.highPressureWasher.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    if not self.isClient then
        SpecializationUtil.removeEventListener(self, "onDelete", HighPressureWasher)
        SpecializationUtil.removeEventListener(self, "onUpdate", HighPressureWasher)
    end
end
function HighPressureWasher:onDelete()
    if self.isClient then
        g_soundManager:deleteSamples(self.spec_highPressureWasher.samples)
        g_animationManager:deleteAnimations(spec.animationNodes)
        g_effectManager:deleteEffects(spec.effects)
    end
end
function HighPressureWasher:onHandToolStoredInHolder(_, _)
    if self.isClient then
        local spec = self.spec_highPressureWasher
        g_soundManager:stopSample(spec.samples.start)
        g_soundManager:stopSample(spec.samples.work)
        g_soundManager:stopSample(spec.samples.stop)
        g_soundManager:playSample(spec.samples.stop)
        g_animationManager:stopAnimations(spec.animationNodes)
        g_effectManager:stopEffects(spec.effects)
    end
end
function HighPressureWasher:onHandToolTakenFromHolder(_, _)
    if self.isClient then
        local spec = self.spec_highPressureWasher
        g_soundManager:stopSample(spec.samples.start)
        g_soundManager:stopSample(spec.samples.work)
        g_soundManager:stopSample(spec.samples.stop)
        g_soundManager:playSample(spec.samples.start)
        g_soundManager:playSample(spec.samples.work, 0, spec.samples.start)
        g_animationManager:startAnimations(spec.animationNodes)
        g_effectManager:startEffects(spec.effects)
    end
end