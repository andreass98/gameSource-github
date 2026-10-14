FillTrigger = {}
FillTrigger.TRIGGER_MASK = CollisionFlag.FILLABLE
local FillTrigger_mt = Class(FillTrigger)
function FillTrigger.onCreate(_, id)
    local fillTrigger = FillTrigger.new(id)
    fillTrigger:setMoneyChangeType((MoneyType.register("other", "finance_purchaseFuel")))
    g_currentMission:addNonUpdateable(fillTrigger)
end
function FillTrigger.new(id, sourceObject, fillUnitIndex, fillLitersPerSecond, _, customMt)
    -- upvalues: (copy) FillTrigger_mt
    local self = setmetatable({}, customMt or FillTrigger_mt)
    self.customEnvironment = g_currentMission.loadingMapModName
    self.triggerId = id
    addTrigger(id, "fillTriggerCallback", self)
    self.soundNode = createTransformGroup("fillTriggerSoundNode")
    link(getParent(id), self.soundNode)
    setTranslation(self.soundNode, getTranslation(id))
    self.sourceObject = sourceObject
    self.vehiclesTriggerCount = {}
    self.vehicleToFillUnitIndices = {}
    self.fillUnitIndex = fillUnitIndex
    self.fillLitersPerSecond = fillLitersPerSecond
    self.isEnabled = true
    self.fillTypeIndex = FillType.DIESEL
    return self
end
function FillTrigger:setMoneyChangeType(moneyChangeType)
    self.moneyChangeType = moneyChangeType
end
function FillTrigger:delete()
    for vehicle, count in pairs(self.vehiclesTriggerCount) do
        if count > 0 and vehicle.removeFillUnitTrigger ~= nil then
            vehicle:removeFillUnitTrigger(self)
        end
    end
    g_soundManager:deleteSample(self.sample)
    removeTrigger(self.triggerId)
end
function FillTrigger:onVehicleDeleted(vehicle)
    self.vehiclesTriggerCount[vehicle] = nil
    if self.moneyChangeType ~= nil then
        g_currentMission:showMoneyChange(self.moneyChangeType, nil, false, vehicle:getActiveFarm())
    end
end
function FillTrigger:fillVehicle(vehicle, delta, dt)
    if self.fillLitersPerSecond ~= nil then
        delta = math.min(delta, self.fillLitersPerSecond * 0.001 * dt)
    end
    local farmId = vehicle:getActiveFarm()
    if self.sourceObject ~= nil then
        local sourceFuelFillLevel = self.sourceObject:getFillUnitFillLevel(self.fillUnitIndex)
        if sourceFuelFillLevel <= 0 or not g_currentMission.accessHandler:canFarmAccess(farmId, self.sourceObject) then
            return 0
        end
        delta = math.min(delta, sourceFuelFillLevel)
        if delta <= 0 then
            return 0
        end
    end
    local sourceFuelFillLevel = self:getCurrentFillType()
    local fillUnitIndex = nil
    if self.vehicleToFillUnitIndices[vehicle] ~= nil then
        for _, _fillUnitIndex in pairs(self.vehicleToFillUnitIndices[vehicle]) do
            if vehicle:getFillUnitCanBeFilled(_fillUnitIndex, sourceFuelFillLevel) then
                fillUnitIndex = _fillUnitIndex
                break
            end
        end
    end
    if fillUnitIndex == nil then
        return 0
    end
    if vehicle.getCustomFillTriggerSpeedFactor ~= nil then
        delta = delta * vehicle:getCustomFillTriggerSpeedFactor(self, fillUnitIndex, sourceFuelFillLevel)
    end
    local price = vehicle:addFillUnitFillLevel(farmId, fillUnitIndex, delta, sourceFuelFillLevel, ToolType.TRIGGER, nil)
    if price > 0 then
        if self.sourceObject ~= nil then
            self.sourceObject:addFillUnitFillLevel(farmId, self.fillUnitIndex, -price, sourceFuelFillLevel, ToolType.TRIGGER, nil)
            return price
        end
        local price = price * g_currentMission.economyManager:getPricePerLiter(sourceFuelFillLevel)
        g_farmManager:updateFarmStats(farmId, "expenses", price)
        g_currentMission:addMoney(-price, farmId, self.moneyChangeType, true)
    end
    return price
end
function FillTrigger:getIsActivatable(vehicle)
    return self.sourceObject ~= nil and (self.sourceObject:getFillUnitFillLevel(self.fillUnitIndex) > 0 and g_currentMission.accessHandler:canFarmAccess(vehicle:getActiveFarm(), self.sourceObject)) and true or false
end
function FillTrigger:fillTriggerCallback(_, otherId, onEnter, onLeave, _)
    if self.isEnabled and (onEnter or onLeave) then
        local vehicle = g_currentMission:getNodeObject(otherId)
        if vehicle ~= nil and (vehicle.addFillUnitTrigger ~= nil and (vehicle.removeFillUnitTrigger ~= nil and (vehicle ~= self and vehicle ~= self.sourceObject))) then
            local count = Utils.getNoNil(self.vehiclesTriggerCount[vehicle], 0)
            if onEnter then
                local fillType = self:getCurrentFillType()
                local fillUnitIndex = vehicle:getFillUnitIndexFromNode(otherId)
                if fillUnitIndex ~= nil and not vehicle:getFillUnitCanBeFilled(fillUnitIndex, fillType) then
                    fillUnitIndex = nil
                end
                if fillUnitIndex ~= nil then
                    self.vehiclesTriggerCount[vehicle] = count + 1
                    if self.vehicleToFillUnitIndices[vehicle] == nil then
                        self.vehicleToFillUnitIndices[vehicle] = {}
                    end
                    self.vehicleToFillUnitIndices[vehicle][otherId] = fillUnitIndex
                    if count == 0 then
                        vehicle:addFillUnitTrigger(self, fillType, fillUnitIndex)
                        return
                    end
                end
            else
                self.vehiclesTriggerCount[vehicle] = count - 1
                if self.vehicleToFillUnitIndices[vehicle] ~= nil then
                    self.vehicleToFillUnitIndices[vehicle][otherId] = nil
                    if next(self.vehicleToFillUnitIndices[vehicle]) == nil then
                        self.vehicleToFillUnitIndices[vehicle] = nil
                    end
                end
                if count <= 1 then
                    self.vehiclesTriggerCount[vehicle] = nil
                    vehicle:removeFillUnitTrigger(self)
                    if self.moneyChangeType ~= nil then
                        g_currentMission:showMoneyChange(self.moneyChangeType, nil, false, vehicle:getActiveFarm())
                    end
                end
            end
        end
    end
end
function FillTrigger:getCurrentFillType()
    if self.sourceObject == nil then
        return self.fillTypeIndex
    else
        return self.sourceObject:getFillUnitFillType(self.fillUnitIndex)
    end
end
function FillTrigger:setFillSoundIsPlaying(state)
    if state then
        local sharedSample = g_fillTypeManager:getSampleByFillType(self:getCurrentFillType())
        if sharedSample ~= nil then
            if sharedSample ~= self.sharedSample then
                if self.sample ~= nil then
                    g_soundManager:deleteSample(self.sample)
                end
                self.sample = g_soundManager:cloneSample(sharedSample, self.soundNode, self)
                self.sharedSample = sharedSample
                g_soundManager:playSample(self.sample)
                return
            end
            if not g_soundManager:getIsSamplePlaying(self.sample) then
                g_soundManager:playSample(self.sample)
                return
            end
        end
    elseif g_soundManager:getIsSamplePlaying(self.sample) then
        g_soundManager:stopSample(self.sample)
    end
end