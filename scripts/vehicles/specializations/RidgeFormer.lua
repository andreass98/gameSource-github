RidgeFormer = {}
RidgeFormer.AI_REQUIRED_GROUND_TYPES = {
    FieldGroundType.STUBBLE_TILLAGE,
    FieldGroundType.CULTIVATED,
    FieldGroundType.SEEDBED,
    FieldGroundType.PLOWED,
    FieldGroundType.ROLLED_SEEDBED
}
RidgeFormer.CLIENT_DM_UPDATE_RADIUS = 50
function RidgeFormer.prerequisitesPresent(specializations)
    return true
end
function RidgeFormer.initSpecialization()
    g_workAreaTypeManager:addWorkAreaType("ridgeFormer", true, true, true)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("RidgeFormer")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.ridgeFormer.sounds", "work")
    schema:setXMLSpecializationType()
end
function RidgeFormer.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "processRidgeFormerArea", RidgeFormer.processRidgeFormerArea)
end
function RidgeFormer.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", RidgeFormer.doCheckSpeedLimit)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", RidgeFormer.getDirtMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", RidgeFormer.getWearMultiplier)
end
function RidgeFormer.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", RidgeFormer)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", RidgeFormer)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", RidgeFormer)
    SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", RidgeFormer)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", RidgeFormer)
end
function RidgeFormer:onLoad(_)
    local spec = self.spec_ridgeFormer
    spec.stoneLastState = 0
    spec.stoneWearMultiplierData = g_currentMission.stoneSystem:getWearMultiplierByType("SOWINGMACHINE")
    if self.addAIGroundTypeRequirements ~= nil then
        self:addAIGroundTypeRequirements(RidgeFormer.AI_REQUIRED_GROUND_TYPES)
    end
    if self.isClient then
        spec.samples = {}
        spec.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.ridgeFormer.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.isWorkSamplePlaying = false
    end
end
function RidgeFormer:onDelete()
    g_soundManager:deleteSamples(self.spec_ridgeFormer.samples)
end
function RidgeFormer:onDeactivate()
    if self.isClient then
        local spec = self.spec_ridgeFormer
        g_soundManager:stopSamples(spec.samples)
        spec.isWorkSamplePlaying = false
    end
end
function RidgeFormer:onStartWorkAreaProcessing(_)
    self.spec_ridgeFormer.isWorking = false
end
function RidgeFormer:onEndWorkAreaProcessing(_)
    if self.isClient then
        if self.spec_ridgeFormer.isWorking then
            if not spec.isWorkSamplePlaying then
                g_soundManager:playSample(spec.samples.work)
                spec.isWorkSamplePlaying = true
                return
            end
        elseif spec.isWorkSamplePlaying then
            g_soundManager:stopSample(spec.samples.work)
            spec.isWorkSamplePlaying = false
        end
    end
end
function RidgeFormer:processRidgeFormerArea(workArea, _)
    local spec = self.spec_ridgeFormer
    local changedArea = 0
    local totalArea = 0
    local sx = self:getLastSpeed() > 0.5
    spec.isWorking = sx
    if not spec.isWorking then
        spec.stoneLastState = 0
        return changedArea, totalArea
    end
    local sx, _, sz = getWorldTranslation(workArea.start)
    local wx, _, wz = getWorldTranslation(workArea.width)
    local hx, _, hz = getWorldTranslation(workArea.height)
    FSDensityMapUtil.eraseTireTrack(sx, sz, wx, wz, hx, hz)
    if not self.isServer and self.currentUpdateDistance > RidgeFormer.CLIENT_DM_UPDATE_RADIUS then
        return changedArea, totalArea
    end
    local dx, _, dz = localDirectionToWorld(self.rootNode, 0, 0, 1)
    local angleRad = math.floor(MathUtil.getYRotationFromDirection(dx, dz) / 1.5707963267948966 + 0.5) * 1.5707963267948966
    local angle = FSDensityMapUtil.convertToDensityMapAngle(angleRad, g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())
    local changedArea, totalArea = FSDensityMapUtil.updateRidgeFormerArea(sx, sz, wx, wz, hx, hz, angle)
    spec.stoneLastState = FSDensityMapUtil.getStoneArea(sx, sz, wx, wz, hx, hz)
    return changedArea, totalArea
end
function RidgeFormer:doCheckSpeedLimit(superFunc)
    return not superFunc(self) and self:getIsImplementChainLowered() and self.spec_ridgeFormer.isWorking
end
function RidgeFormer:getDirtMultiplier(superFunc)
    local multiplier = superFunc(self)
    if self.movingDirection > 0 and self.spec_ridgeFormer.isWorking then
        multiplier = multiplier + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
    end
    return multiplier
end
function RidgeFormer:getWearMultiplier(superFunc)
    local spec = self.spec_ridgeFormer
    local multiplier = superFunc(self)
    if self.movingDirection > 0 and spec.isWorking then
        multiplier = multiplier + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit * (spec.stoneLastState ~= 0 and spec.stoneWearMultiplierData ~= nil and (spec.stoneWearMultiplierData[spec.stoneLastState] or 1) or 1)
    end
    return multiplier
end