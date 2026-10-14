SaltSpreader = {}
function SaltSpreader.initSpecialization()
    g_workAreaTypeManager:addWorkAreaType("saltSpreader", false, false, false)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("SaltSpreader")
    schema:register(XMLValueType.INT, "vehicle.saltSpreader#fillUnitIndex", "Fill unit index", 1)
    schema:register(XMLValueType.INT, "vehicle.saltSpreader#unloadInfoIndex", "Unload info index", 1)
    schema:register(XMLValueType.INT, "vehicle.saltSpreader#usageWorkArea", "Width of this work area is used as multiplier for usage")
    schema:register(XMLValueType.FLOAT, "vehicle.saltSpreader#usage", "Salt usage in liter per second", 1)
    EffectManager.registerEffectXMLPaths(schema, "vehicle.saltSpreader.effects")
    schema:setXMLSpecializationType()
end
function SaltSpreader.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
end
function SaltSpreader.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "processSaltSpreaderArea", SaltSpreader.processSaltSpreaderArea)
end
function SaltSpreader.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", SaltSpreader.doCheckSpeedLimit)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", SaltSpreader.getDirtMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", SaltSpreader.getWearMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", SaltSpreader.getAreControlledActionsAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", SaltSpreader.getCanBeTurnedOn)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurnedOnNotAllowedWarning", SaltSpreader.getTurnedOnNotAllowedWarning)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getVariableWorkWidthUsage", SaltSpreader.getVariableWorkWidthUsage)
end
function SaltSpreader.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", SaltSpreader)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", SaltSpreader)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", SaltSpreader)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", SaltSpreader)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", SaltSpreader)
end
function SaltSpreader:onLoad(_)
    local spec = self.spec_saltSpreader
    spec.fillUnitIndex = self.xmlFile:getValue("vehicle.saltSpreader#fillUnitIndex", 1)
    spec.unloadInfoIndex = self.xmlFile:getValue("vehicle.saltSpreader#unloadInfoIndex", 1)
    spec.usageWorkArea = self.xmlFile:getValue("vehicle.saltSpreader#usageWorkArea")
    spec.usage = self.xmlFile:getValue("vehicle.saltSpreader#usage", 1) / 1000
    if self.isClient then
        spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.saltSpreader.effects", self.components, self, self.i3dMappings)
    end
    spec.fillToolWarning = g_i18n:getText("info_firstFillTheTool")
    spec.snowSystem = g_currentMission.snowSystem
    if not self.isServer then
        SpecializationUtil.removeEventListener(self, "onUpdateTick", SaltSpreader)
    end
end
function SaltSpreader:onDelete()
    g_effectManager:deleteEffects(self.spec_saltSpreader.effects)
end
function SaltSpreader:onUpdateTick(dt, _, _, _)
    if self:getIsTurnedOn() then
        local spec = self.spec_saltSpreader
        if self:getFillUnitFillLevel(spec.fillUnitIndex) > 0 then
            local usageMultiplier = 1
            if spec.usageWorkArea ~= nil then
                usageMultiplier = self:getWorkAreaWidth(spec.usageWorkArea)
            end
            local unloadInfo = self:getFillVolumeUnloadInfo(spec.unloadInfoIndex)
            self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -(spec.usage * dt * usageMultiplier), self:getFillUnitFillType(spec.fillUnitIndex), ToolType.UNDEFINED, unloadInfo)
            return
        end
        self:setIsTurnedOn(false)
    end
end
function SaltSpreader:onTurnedOn()
    if self.isClient then
        local spec = self.spec_saltSpreader
        local fillTypeIndex = self:getFillUnitFillType(spec.fillUnitIndex)
        if fillTypeIndex ~= FillType.UNKNOWN then
            g_effectManager:setEffectTypeInfo(spec.effects, fillTypeIndex)
            g_effectManager:startEffects(spec.effects)
        end
    end
end
function SaltSpreader:onTurnedOff()
    if self.isClient then
        g_effectManager:stopEffects(self.spec_saltSpreader.effects)
    end
end
function SaltSpreader:doCheckSpeedLimit(superFunc)
    return superFunc(self) or self:getIsTurnedOn()
end
function SaltSpreader:getDirtMultiplier(superFunc)
    if self:getIsTurnedOn() then
        return superFunc(self) + self:getWorkDirtMultiplier()
    else
        return superFunc(self)
    end
end
function SaltSpreader:getWearMultiplier(superFunc)
    if self:getIsTurnedOn() then
        return superFunc(self) + self:getWorkWearMultiplier()
    else
        return superFunc(self)
    end
end
function SaltSpreader:getAreControlledActionsAllowed(superFunc)
    local spec = self.spec_saltSpreader
    if self:getFillUnitFillLevel(spec.fillUnitIndex) <= 0 then
        return false, spec.fillToolWarning
    else
        return superFunc(self)
    end
end
function SaltSpreader:getCanBeTurnedOn(superFunc)
    if self:getFillUnitFillLevel(self.spec_saltSpreader.fillUnitIndex) <= 0 then
        return false
    else
        return superFunc(self)
    end
end
function SaltSpreader:getTurnedOnNotAllowedWarning(superFunc)
    local spec = self.spec_saltSpreader
    if self:getFillUnitFillLevel(spec.fillUnitIndex) <= 0 then
        return spec.fillToolWarning
    else
        return superFunc(self)
    end
end
function SaltSpreader:getVariableWorkWidthUsage(superFunc)
    local usage = superFunc(self)
    if usage ~= nil then
        return usage
    end
    if not self:getIsTurnedOn() then
        return 0
    end
    local spec = self.spec_saltSpreader
    local usageMultiplier = 1
    if spec.usageWorkArea ~= nil then
        usageMultiplier = self:getWorkAreaWidth(spec.usageWorkArea)
    end
    return spec.usage * usageMultiplier * 1000 * 60
end
function SaltSpreader.getDefaultSpeedLimit()
    return 20
end
function SaltSpreader:processSaltSpreaderArea(workArea)
    if not self.isServer then
        return 0, 0
    end
    local xs, _, zs = getWorldTranslation(workArea.start)
    local xw, _, zw = getWorldTranslation(workArea.width)
    local xh, _, zh = getWorldTranslation(workArea.height)
    return self.spec_saltSpreader.snowSystem:saltArea(xs, zs, xw, zw, xh, zh)
end