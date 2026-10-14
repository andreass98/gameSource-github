source("dataS/scripts/vehicles/specializations/events/MixerWagonBaleNotAcceptedEvent.lua")
MixerWagon = {}
source("dataS/scripts/gui/hud/extensions/MixerWagonHUDExtension.lua")
function MixerWagon.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Trailer, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
end
function MixerWagon.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("MixerWagon")
    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.mixerWagon.mixAnimationNodes")
    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.mixerWagon.pickupAnimationNodes")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.mixerWagon.baleTriggers.baleTrigger(?)#node", "Bale trigger node")
    schema:register(XMLValueType.FLOAT, "vehicle.mixerWagon.baleTriggers.baleTrigger(?)#pickupSpeed", "Bale pickup speed in liter per second", 500)
    schema:register(XMLValueType.BOOL, "vehicle.mixerWagon.baleTriggers.baleTrigger(?)#needsSetIsTurnedOn", "Vehicle needs to be turned on to pickup bales with this trigger", false)
    schema:register(XMLValueType.BOOL, "vehicle.mixerWagon.baleTriggers.baleTrigger(?)#useEffect", "Filling effect is played while picking up a bale", false)
    schema:register(XMLValueType.TIME, "vehicle.mixerWagon#mixingTime", "Mixing time after the fill level was changed", 5)
    schema:register(XMLValueType.INT, "vehicle.mixerWagon#fillUnitIndex", "Fill unit index", 1)
    schema:register(XMLValueType.STRING, "vehicle.mixerWagon#recipe", "Recipe fill type name")
    EffectManager.registerEffectXMLPaths(schema, "vehicle.mixerWagon.fillEffect")
    schema:setXMLSpecializationType()
    Vehicle.xmlSchemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).mixerWagon.fillType(?)#fillLevel", "Fill level", 0)
end
function MixerWagon.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "mixerWagonBaleTriggerCallback", MixerWagon.mixerWagonBaleTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "onMixerWagonBaleDeleted", MixerWagon.onMixerWagonBaleDeleted)
end
function MixerWagon.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addFillUnitFillLevel", MixerWagon.addFillUnitFillLevel)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitAllowsFillType", MixerWagon.getFillUnitAllowsFillType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeFillType", MixerWagon.getDischargeFillType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsBaleAutoLoadable", MixerWagon.getIsBaleAutoLoadable)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", MixerWagon.getDoConsumePtoPower)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", MixerWagon.getConsumingLoad)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowerTakeOffActive", MixerWagon.getIsPowerTakeOffActive)
end
function MixerWagon.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", MixerWagon)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", MixerWagon)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", MixerWagon)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", MixerWagon)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", MixerWagon)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", MixerWagon)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", MixerWagon)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", MixerWagon)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", MixerWagon)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", MixerWagon)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", MixerWagon)
    SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", MixerWagon)
end
function MixerWagon:onLoad(_)
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mixerWagonBaleTrigger#index", "vehicle.mixerWagon.baleTrigger#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mixerWagon.baleTrigger#index", "vehicle.mixerWagon.baleTrigger#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mixerWagonPickupStartSound", "vehicle.turnOnVehicle.sounds.start")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mixerWagonPickupStopSound", "vehicle.turnOnVehicle.sounds.stop")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mixerWagonPickupSound", "vehicle.turnOnVehicle.sounds.work")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mixerWagonRotatingParts.mixerWagonRotatingPart#type", "vehicle.mixerWagon.mixAnimationNodes.animationNode", "mixerWagonMix")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mixerWagonRotatingParts.mixerWagonRotatingPart#type", "vehicle.mixerWagon.pickupAnimationNodes.animationNode", "mixerWagonPickup")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mixerWagonRotatingParts.mixerWagonScroller", "vehicle.mixerWagon.pickupAnimationNodes.pickupAnimationNode")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mixerWagon.baleTrigger#node", "vehicle.mixerWagon.baleTriggers.baleTrigger#node")
    local spec = self.spec_mixerWagon
    if self.isClient then
        spec.mixAnimationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.mixerWagon.mixAnimationNodes", self.components, self, self.i3dMappings)
        spec.pickupAnimationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.mixerWagon.pickupAnimationNodes", self.components, self, self.i3dMappings)
        spec.fillEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.mixerWagon.fillEffect", self.components, self, self.i3dMappings)
        spec.fillEffectsFillType = FillType.UNKNOWN
        spec.fillEffectsState = false
    end
    if self.isServer then
        spec.baleTriggers = {}
        self.xmlFile:iterate("vehicle.mixerWagon.baleTriggers.baleTrigger", function(_, key)
            -- upvalues: (copy) self, (copy) spec
            local baleTrigger = {
                ["node"] = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
            }
            if baleTrigger.node ~= nil then
                addTrigger(baleTrigger.node, "mixerWagonBaleTriggerCallback", self)
                baleTrigger.pickupSpeed = self.xmlFile:getValue(key .. "#pickupSpeed", 500) / 1000
                baleTrigger.needsSetIsTurnedOn = self.xmlFile:getValue(key .. "#needsSetIsTurnedOn", false)
                baleTrigger.useEffect = self.xmlFile:getValue(key .. "#useEffect", false)
                baleTrigger.balesInTrigger = {}
                table.insert(spec.baleTriggers, baleTrigger)
            end
        end)
    end
    spec.activeTimerMax = self.xmlFile:getValue("vehicle.mixerWagon#mixingTime", 5)
    spec.activeTimer = 0
    spec.fillUnitIndex = self.xmlFile:getValue("vehicle.mixerWagon#fillUnitIndex", 1)
    spec.mixerWagonFillTypes = {}
    spec.fillTypeToMixerWagonFillType = {}
    local recipeFillTypeName = self.xmlFile:getValue("vehicle.mixerWagon#recipe")
    if recipeFillTypeName ~= nil then
        local recipeFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(recipeFillTypeName)
        if recipeFillTypeIndex == nil then
            Logging.xmlError(self.xmlFile, "MixerWagon recipe \'%s\' not defined!", recipeFillTypeName)
        end
        local recipe = g_currentMission.animalFoodSystem:getRecipeByFillTypeIndex(recipeFillTypeIndex)
        if recipe == nil then
            Logging.xmlWarning(self.xmlFile, "MixerWagon recipe \'%s\' not defined!", recipeFillTypeName)
        end
        if recipe ~= nil then
            for _, ingredient in ipairs(recipe.ingredients) do
                local entry = {
                    ["fillLevel"] = 0,
                    ["fillTypes"] = {},
                    ["name"] = ingredient.name,
                    ["minPercentage"] = ingredient.minPercentage,
                    ["maxPercentage"] = ingredient.maxPercentage,
                    ["ratio"] = ingredient.ratio
                }
                for _, fillTypeIndex in ipairs(ingredient.fillTypes) do
                    entry.fillTypes[fillTypeIndex] = true
                    spec.fillTypeToMixerWagonFillType[fillTypeIndex] = entry
                end
                table.insert(spec.mixerWagonFillTypes, entry)
            end
        end
    end
    if #spec.mixerWagonFillTypes > 0 then
        local recipeFillTypeIndex = self:getFillUnitByIndex(spec.fillUnitIndex)
        if recipeFillTypeIndex ~= nil then
            recipeFillTypeIndex.needsSaving = false
            recipeFillTypeIndex.synchronizeFillLevel = false
        end
    end
    spec.dirtyFlag = self:getNextDirtyFlag()
    spec.effectDirtyFlag = self:getNextDirtyFlag()
    spec.hudExtension = MixerWagonHUDExtension.new(self)
end
function MixerWagon:onPostLoad(savegame)
    if savegame ~= nil then
        local spec = self.spec_mixerWagon
        for i, entry in ipairs(spec.mixerWagonFillTypes) do
            local fillTypeKey = savegame.key .. string.format(".mixerWagon.fillType(%d)#fillLevel", i - 1)
            local fillLevel = savegame.xmlFile:getValue(fillTypeKey, 0)
            if fillLevel > 0 then
                self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, fillLevel, next(entry.fillTypes), ToolType.UNDEFINED, nil)
            end
        end
    end
    if self.spec_hudInfoTrigger == nil or self.spec_hudInfoTrigger.triggerNode == nil then
        Logging.xmlDevWarning(self.xmlFile, "Missing hudInfoTrigger for mixer wagon. Required for external mixer wagon hud visibility!")
    end
end
function MixerWagon:onDelete()
    local spec = self.spec_mixerWagon
    if spec.baleTriggers ~= nil then
        for _, baleTrigger in ipairs(spec.baleTriggers) do
            removeTrigger(baleTrigger.node)
            for bale, _ in pairs(baleTrigger.balesInTrigger) do
                if bale.removeDeleteListener ~= nil then
                    bale:removeDeleteListener(self, self.onMixerWagonBaleDeleted)
                end
            end
            table.clear(baleTrigger.balesInTrigger)
        end
        table.clear(spec.baleTriggers)
    end
    g_animationManager:deleteAnimations(spec.mixAnimationNodes)
    g_animationManager:deleteAnimations(spec.pickupAnimationNodes)
    g_effectManager:deleteEffects(spec.fillEffects)
    if spec.hudExtension ~= nil then
        g_currentMission.hud:removeInfoExtension(spec.hudExtension)
        spec.hudExtension:delete()
    end
end
function MixerWagon:saveToXMLFile(xmlFile, key, _)
    for i, fillType in ipairs(self.spec_mixerWagon.mixerWagonFillTypes) do
        xmlFile:setValue(string.format("%s.fillType(%d)", key, i - 1) .. "#fillLevel", fillType.fillLevel)
    end
end
function MixerWagon:onReadStream(streamId, _)
    local spec = self.spec_mixerWagon
    for _, entry in ipairs(spec.mixerWagonFillTypes) do
        local fillLevel = streamReadFloat32(streamId)
        if fillLevel > 0 then
            self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, fillLevel, next(entry.fillTypes), ToolType.UNDEFINED, nil)
        end
    end
    spec.fillEffectsFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
end
function MixerWagon:onWriteStream(streamId, _)
    local spec = self.spec_mixerWagon
    for _, entry in ipairs(spec.mixerWagonFillTypes) do
        streamWriteFloat32(streamId, entry.fillLevel)
    end
    streamWriteUIntN(streamId, spec.fillEffectsFillType, FillTypeManager.SEND_NUM_BITS)
end
function MixerWagon:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            for _, entry in ipairs(self.spec_mixerWagon.mixerWagonFillTypes) do
                local delta = streamReadFloat32(streamId) - entry.fillLevel
                if delta ~= 0 then
                    self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, delta, next(entry.fillTypes), ToolType.UNDEFINED, nil)
                end
            end
        end
        if streamReadBool(streamId) then
            spec.fillEffectsFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
        end
    end
end
function MixerWagon:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_mixerWagon
        if streamWriteBool(streamId, bit32.band(dirtyMask, spec.dirtyFlag) ~= 0) then
            for _, entry in ipairs(spec.mixerWagonFillTypes) do
                streamWriteFloat32(streamId, entry.fillLevel)
            end
        end
        if streamWriteBool(streamId, bit32.band(dirtyMask, spec.effectDirtyFlag) ~= 0) then
            streamWriteUIntN(streamId, spec.fillEffectsFillType, FillTypeManager.SEND_NUM_BITS)
        end
    end
end
function MixerWagon:onUpdate(dt, _, _, _)
    local spec = self.spec_mixerWagon
    local tipState = self:getTipState()
    local isTurnedOn = self:getIsTurnedOn()
    local isDischarging = true
    if tipState ~= Trailer.TIPSTATE_OPENING then
        isDischarging = tipState == Trailer.TIPSTATE_OPEN
    end
    if self:getIsPowered() and (spec.activeTimer > 0 or (isTurnedOn or isDischarging)) then
        spec.activeTimer = spec.activeTimer - dt
        g_animationManager:startAnimations(spec.mixAnimationNodes)
    else
        g_animationManager:stopAnimations(spec.mixAnimationNodes)
    end
    if self.isServer then
        local fillEffectsFillType = FillType.UNKNOWN
        if self:getFillUnitFreeCapacity(spec.fillUnitIndex) > 0 then
            local i = 1
            local fillType = 1
            for i = i, #spec.baleTriggers, fillType do
                local baleTrigger = spec.baleTriggers[i]
                if not baleTrigger.needsSetIsTurnedOn or self:getIsTurnedOn() then
                    for bale, _ in pairs(baleTrigger.balesInTrigger) do
                        local baleFillLevel = bale:getFillLevel()
                        local fillType = baleTrigger.pickupSpeed * dt
                        local deltaFillLevel = math.min(fillType, baleFillLevel)
                        local fillType = bale:getFillType()
                        local baleFillLevel = baleFillLevel - self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, deltaFillLevel, fillType, ToolType.BALE, nil)
                        bale:setFillLevel(baleFillLevel)
                        if baleFillLevel < 0.01 then
                            bale:delete()
                            baleTrigger.balesInTrigger[bale] = nil
                        end
                        if baleTrigger.useEffect then
                            fillEffectsFillType = fillType
                        end
                    end
                end
            end
        end
        local fillType
        if fillEffectsFillType == FillType.UNKNOWN and self.getIsShovelEffectState ~= nil then
            local state
            state, fillType = self:getIsShovelEffectState()
            if not state then
                fillType = fillEffectsFillType
            end
        else
            fillType = fillEffectsFillType
        end
        if spec.fillEffectsFillType ~= fillType then
            spec.fillEffectsFillType = fillType
            self:raiseDirtyFlags(spec.effectDirtyFlag)
        end
    end
    if self.isClient then
        local fillEffectsFillType = spec.fillEffectsFillType ~= FillType.UNKNOWN
        if fillEffectsFillType ~= spec.fillEffectsState then
            if fillEffectsFillType then
                g_effectManager:setEffectTypeInfo(spec.fillEffects, spec.fillEffectsFillType)
                g_effectManager:startEffects(spec.fillEffects)
            else
                g_effectManager:stopEffects(spec.fillEffects)
            end
            spec.fillEffectsState = fillEffectsFillType
        end
    end
end
function MixerWagon:onDraw()
    local spec = self.spec_mixerWagon
    if spec.hudExtension ~= nil then
        g_currentMission.hud:addInfoExtension(spec.hudExtension)
    end
end
function MixerWagon:mixerWagonBaleTriggerCallback(triggerId, otherActorId, onEnter, onLeave, _, _)
    if otherActorId ~= 0 then
        local bale = g_currentMission:getNodeObject(otherActorId)
        if bale ~= nil and bale:isa(Bale) then
            local spec = self.spec_mixerWagon
            if self:getFillUnitSupportsFillType(spec.fillUnitIndex, bale:getFillType()) then
                local i = 1
                for i = i, #spec.baleTriggers do
                    local baleTrigger = spec.baleTriggers[i]
                    if baleTrigger.node == triggerId then
                        if onEnter then
                            baleTrigger.balesInTrigger[bale] = (baleTrigger.balesInTrigger[bale] or 0) + 1
                            if baleTrigger.balesInTrigger[bale] == 1 then
                                bale:addDeleteListener(self, self.onMixerWagonBaleDeleted)
                            end
                        elseif onLeave then
                            baleTrigger.balesInTrigger[bale] = (baleTrigger.balesInTrigger[bale] or 1) - 1
                            if baleTrigger.balesInTrigger[bale] == 0 then
                                baleTrigger.balesInTrigger[bale] = nil
                                bale:removeDeleteListener(self, self.onMixerWagonBaleDeleted)
                            end
                        end
                    end
                end
                return
            end
            if onEnter and otherActorId == bale.nodeId then
                g_currentMission:broadcastEventToFarm(MixerWagonBaleNotAcceptedEvent.new(), self:getOwnerFarmId(), true)
            end
        end
    end
end
function MixerWagon:onMixerWagonBaleDeleted(bale)
    local spec = self.spec_mixerWagon
    local i = 1
    for i = i, #spec.baleTriggers do
        spec.baleTriggers[i].balesInTrigger[bale] = nil
    end
end
function MixerWagon:addFillUnitFillLevel(superFunc, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
    local spec = self.spec_mixerWagon
    if fillUnitIndex ~= spec.fillUnitIndex then
        return superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
    end
    if #spec.mixerWagonFillTypes == 0 then
        if fillLevelDelta ~= 0 and self:getIsSynchronized() then
            spec.activeTimer = spec.activeTimerMax
        end
        return superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
    end
    local oldFillLevel = self:getFillUnitFillLevel(fillUnitIndex)
    local mixerWagonFillType = spec.fillTypeToMixerWagonFillType[fillTypeIndex]
    if fillTypeIndex == FillType.FORAGE and fillLevelDelta > 0 then
        for _, entry in pairs(spec.mixerWagonFillTypes) do
            self:addFillUnitFillLevel(farmId, fillUnitIndex, fillLevelDelta * entry.ratio, next(entry.fillTypes), toolType, fillPositionData)
        end
        return fillLevelDelta
    end
    if mixerWagonFillType == nil then
        if fillLevelDelta >= 0 or oldFillLevel <= 0 then
            return 0
        end
        local newFillLevel = -oldFillLevel
        local newFillLevel = math.max(fillLevelDelta, newFillLevel)
        local newFillLevel = 0
        for entry, delta in pairs(spec.mixerWagonFillTypes) do
            delta.fillLevel = math.max(delta.fillLevel + newFillLevel * (delta.fillLevel / oldFillLevel), 0)
        end
        if newFillLevel < 0.1 then
            for entry, delta in pairs(spec.mixerWagonFillTypes) do
                delta.fillLevel = 0
            end
            newFillLevel = -oldFillLevel
        end
        self:raiseDirtyFlags(spec.dirtyFlag)
        return superFunc(self, farmId, fillUnitIndex, newFillLevel, fillTypeIndex, toolType, fillPositionData)
    end
    local ret = self:getFillUnitCapacity(fillUnitIndex) - oldFillLevel
    if fillLevelDelta > 0 then
        mixerWagonFillType.fillLevel = mixerWagonFillType.fillLevel + math.min(ret, fillLevelDelta)
        if self:getIsSynchronized() then
            spec.activeTimer = spec.activeTimerMax
        end
    else
        mixerWagonFillType.fillLevel = math.max(0, mixerWagonFillType.fillLevel + fillLevelDelta)
    end
    local newFillLevel = 0
    for entryDelta, fillType in pairs(spec.mixerWagonFillTypes) do

    end
    local entryDelta = self:getFillUnitCapacity(fillUnitIndex)
    newFillLevel = math.clamp(newFillLevel, 0, entryDelta)
    local _ = FillType.UNKNOWN
    local entry = false
    local delta = false
    for _, fillType in pairs(spec.mixerWagonFillTypes) do
        if newFillLevel == fillType.fillLevel then
            entry = true
            _ = next(mixerWagonFillType.fillTypes)
            break
        end
    end
    if not entry then
        delta = true
        for _, fillType in pairs(spec.mixerWagonFillTypes) do
            if fillType.fillLevel < fillType.minPercentage * newFillLevel - 0.01 or fillType.fillLevel > fillType.maxPercentage * newFillLevel + 0.01 then
                delta = false
                break
            end
        end
    end
    if delta then
        _ = FillType.FORAGE
    elseif not entry then
        _ = FillType.FORAGE_MIXING
    end
    self:raiseDirtyFlags(spec.dirtyFlag)
    self:setFillUnitFillType(fillUnitIndex, newFillLevel)
    return superFunc(self, farmId, fillUnitIndex, newFillLevel - oldFillLevel, newFillLevel, toolType, fillPositionData)
end
function MixerWagon:getFillUnitAllowsFillType(superFunc, fillUnitIndex, fillTypeIndex)
    local spec = self.spec_mixerWagon
    return spec.fillUnitIndex == fillUnitIndex and (#spec.mixerWagonFillTypes > 0 and spec.fillTypeToMixerWagonFillType[fillTypeIndex] ~= nil) and true or superFunc(self, fillUnitIndex, fillTypeIndex)
end
function MixerWagon:getDischargeFillType(superFunc, dischargeNode)
    local spec = self.spec_mixerWagon
    local fillUnitIndex = dischargeNode.fillUnitIndex
    if fillUnitIndex ~= spec.fillUnitIndex then
        return superFunc(self, dischargeNode)
    end
    local currentFillType = self:getFillUnitFillType(fillUnitIndex)
    local fillLevel = self:getFillUnitFillLevel(fillUnitIndex)
    if currentFillType == FillType.FORAGE_MIXING and fillLevel > 0 then
        for _, entry in pairs(spec.mixerWagonFillTypes) do
            if entry.fillLevel > 0 then
                currentFillType = next(entry.fillTypes)
                break
            end
        end
    end
    return currentFillType, 1
end
function MixerWagon:getIsBaleAutoLoadable(superFunc, bale)
    if self:getIsTurnedOn() then
        local i = 1
        for i = i, #self.spec_mixerWagon.baleTriggers do
            if next(spec.baleTriggers[i].balesInTrigger) ~= nil then
                return false
            end
        end
        local loadedFillTypeIndex = self:getFillUnitFillType(spec.fillUnitIndex)
        if loadedFillTypeIndex == FillType.UNKNOWN or bale:getFillType() == loadedFillTypeIndex then
            if self:getFillUnitFreeCapacity(spec.fillUnitIndex) <= 0 then
                return false
            else
                return superFunc(self, bale)
            end
        else
            return false
        end
    else
        return false
    end
end
function MixerWagon:getDoConsumePtoPower(superFunc)
    return self.spec_mixerWagon.activeTimer > 0 and true or superFunc(self)
end
function MixerWagon:getConsumingLoad(superFunc)
    local value, count = superFunc(self)
    return value + (self.spec_mixerWagon.activeTimer > 0 and 1 or 0), count + 1
end
function MixerWagon:getIsPowerTakeOffActive(superFunc)
    return self.spec_mixerWagon.activeTimer > 0 or superFunc(self)
end
function MixerWagon:onFillUnitFillLevelChanged(fillUnitIndex, _, _, _, _, _)
    local spec = self.spec_mixerWagon
    if spec.fillUnitIndex == fillUnitIndex and self:getFillUnitFillLevel(fillUnitIndex) == 0 then
        for _, entry in pairs(spec.mixerWagonFillTypes) do
            entry.fillLevel = 0
        end
    end
end
function MixerWagon:onTurnedOn()
    if self.isClient then
        g_animationManager:startAnimations(self.spec_mixerWagon.pickupAnimationNodes)
    end
end
function MixerWagon:onTurnedOff()
    if self.isClient then
        g_animationManager:stopAnimations(self.spec_mixerWagon.pickupAnimationNodes)
    end
end
function MixerWagon:updateDebugValues(values)
    local spec = self.spec_mixerWagon
    local mixerWagonFillType = self:getFillUnitFillType(spec.fillUnitIndex) == FillType.FORAGE
    table.insert(values, {
        ["name"] = "Forage isOK",
        ["value"] = tostring(mixerWagonFillType)
    })
    for _, mixerWagonFillType in ipairs(spec.mixerWagonFillTypes) do
        local fillTypes = ""
        for fillTypeIndex, _ in pairs(mixerWagonFillType.fillTypes) do
            fillTypes = fillTypes .. " " .. tostring(g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex))
        end
        table.insert(values, {
            ["name"] = fillTypes,
            ["value"] = mixerWagonFillType.fillLevel
        })
    end
end