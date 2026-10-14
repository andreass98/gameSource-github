SeedTreater = {}
function SeedTreater.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Dischargeable, specializations) and SpecializationUtil.hasSpecialization(FillUnit, specializations)
end
function SeedTreater.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("SeedTreater")
    schema:register(XMLValueType.INT, "vehicle.seedTreater#fillUnitIndex", "Fill unit index with seed treatment liquid", 1)
    schema:register(XMLValueType.INT, "vehicle.seedTreater#dischargeNodeIndex", "Discharge node index", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.seedTreater#usagePerLiter", "Usage of treatment liquid", 0.1)
    schema:register(XMLValueType.FLOAT, "vehicle.seedTreater#fillFromTriggerThreshold", "After this amount is available as free capacity the filling from nearby pallets starts", 5)
    schema:register(XMLValueType.FLOAT, "vehicle.seedTreater#treatmentSpeedFactor", "Speed factor while treatment is active", 0.1)
    schema:setXMLSpecializationType()
end
function SeedTreater.registerFunctions(vehicleType) end
function SeedTreater.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "discharge", SeedTreater.discharge)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeFillType", SeedTreater.getDischargeFillType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeNodeEmptyFactor", SeedTreater.getDischargeNodeEmptyFactor)
end
function SeedTreater.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", SeedTreater)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SeedTreater)
end
function SeedTreater:onLoad(_)
    local spec = self.spec_seedTreater
    spec.fillUnitIndex = self.xmlFile:getValue("vehicle.seedTreater#fillUnitIndex", 1)
    spec.dischargeNodeIndex = self.xmlFile:getValue("vehicle.seedTreater#dischargeNodeIndex", 1)
    spec.usagePerLiter = self.xmlFile:getValue("vehicle.seedTreater#usagePerLiter", 0.1)
    spec.fillFromTriggerThreshold = self.xmlFile:getValue("vehicle.seedTreater#fillFromTriggerThreshold", 5)
    spec.treatmentSpeedFactor = self.xmlFile:getValue("vehicle.seedTreater#treatmentSpeedFactor", 0.1)
end
function SeedTreater:onUpdate(_, _, _, _)
    if self.isServer then
        local fillUnit = self:getFillUnitByIndex(self.spec_seedTreater.fillUnitIndex)
        if fillUnit ~= nil then
            if fillUnit.capacity - fillUnit.fillLevel > 5 then
                local specFillUnit = self.spec_fillUnit
                if not specFillUnit.fillTrigger.isFilling then
                    for _, trigger in ipairs(specFillUnit.fillTrigger.triggers) do
                        if trigger:getCurrentFillType() == FillType.LIQUIDSEEDTREATMENT and trigger:getIsActivatable(self) then
                            self:setFillUnitIsFilling(true)
                        end
                    end
                    return
                end
            elseif self.spec_fillUnit.fillTrigger.isFilling and (self:getDischargeState() ~= Dischargeable.DISCHARGE_STATE_OFF and fillUnit.capacity - fillUnit.fillLevel < 0.1) then
                self:setFillUnitIsFilling(false)
            end
        end
    end
end
function SeedTreater:discharge(superFunc, dischargeNode, emptyLiters)
    local dischargedLiters, minDropReached, hasMinDropFillLevel = superFunc(self, dischargeNode, emptyLiters)
    local spec = self.spec_seedTreater
    if dischargeNode.index == spec.dischargeNodeIndex then
        local fillType = self:getFillUnitFillType(dischargeNode.fillUnitIndex)
        if dischargeNode.fillTypeConverter ~= nil and dischargeNode.fillTypeConverter[fillType] ~= nil then
            local usage = -dischargedLiters * spec.usagePerLiter
            if usage > 0 then
                self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -usage, self:getFillUnitFillType(spec.fillUnitIndex), ToolType.UNDEFINED, nil)
            end
        end
    end
    return dischargedLiters, minDropReached, hasMinDropFillLevel
end
function SeedTreater:getDischargeFillType(superFunc, dischargeNode)
    local spec = self.spec_seedTreater
    if spec == nil or self:getFillUnitFillLevel(spec.fillUnitIndex) ~= 0 then
        return superFunc(self, dischargeNode)
    else
        return self:getFillUnitFillType(dischargeNode.fillUnitIndex), 1
    end
end
function SeedTreater:getDischargeNodeEmptyFactor(superFunc, dischargeNode)
    local fillType = self:getFillUnitFillType(dischargeNode.fillUnitIndex)
    if dischargeNode.fillTypeConverter == nil or dischargeNode.fillTypeConverter[fillType] ~= nil then
        if self:getFillUnitFillLevel(self.spec_seedTreater.fillUnitIndex) == 0 then
            return superFunc(self, dischargeNode)
        else
            return superFunc(self, dischargeNode) * spec.treatmentSpeedFactor
        end
    else
        return superFunc(self, dischargeNode)
    end
end