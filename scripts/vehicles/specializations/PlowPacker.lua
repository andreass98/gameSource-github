PlowPacker = {}
PlowPacker.CULTIVATED_GROUND_TYPES = {
    FieldGroundType.STUBBLE_TILLAGE,
    FieldGroundType.CULTIVATED,
    FieldGroundType.SEEDBED,
    FieldGroundType.ROLLED_SEEDBED
}
PlowPacker.CLIENT_DM_UPDATE_RADIUS = 50
source("dataS/scripts/vehicles/specializations/events/PlowPackerStateEvent.lua")
function PlowPacker.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("PlowPacker")
    schema:register(XMLValueType.STRING, "vehicle.plow.packer#inputAction", "Input action name for packer toggling", "IMPLEMENT_EXTRA4")
    schema:register(XMLValueType.STRING, "vehicle.plow.packer#deactivateLeft", "Packer deactivate animation left side")
    schema:register(XMLValueType.STRING, "vehicle.plow.packer#deactivateRight", "Packer deactivate animation left side")
    schema:register(XMLValueType.FLOAT, "vehicle.plow.packer#animationSpeed", "Packer animation speed", 1)
    schema:register(XMLValueType.INT, "vehicle.plow.packer#foldingConfig", "Folding configuration with available packer", 1)
    schema:register(XMLValueType.BOOL, "vehicle.plow.packer#partialDeactivated", "Only some parts of the packer are deactivated", false)
    schema:register(XMLValueType.STRING, "vehicle.plow.packer.lowerAnimation#name", "Lower animation that is played while packer is active")
    schema:register(XMLValueType.FLOAT, "vehicle.plow.packer.lowerAnimation#speed", "Lower animation speed", 1)
    schema:setXMLSpecializationType()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).plowPacker#packerState", "Packer state")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).plowPacker#lastPackerState", "Last packer state while turning")
end
function PlowPacker.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Plow, specializations) and SpecializationUtil.hasSpecialization(Cultivator, specializations) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
end
function PlowPacker.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setPackerState", PlowPacker.setPackerState)
    SpecializationUtil.registerFunction(vehicleType, "getIsPackerAllowed", PlowPacker.getIsPackerAllowed)
end
function PlowPacker.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setRotationMax", PlowPacker.setRotationMax)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setPlowAIRequirements", PlowPacker.setPlowAIRequirements)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setFoldState", PlowPacker.setFoldState)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "processCultivatorArea", PlowPacker.processCultivatorArea)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getUseCultivatorAIRequirements", PlowPacker.getUseCultivatorAIRequirements)
end
function PlowPacker.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", PlowPacker)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", PlowPacker)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", PlowPacker)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", PlowPacker)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", PlowPacker)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", PlowPacker)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", PlowPacker)
    SpecializationUtil.registerEventListener(vehicleType, "onSetLowered", PlowPacker)
end
function PlowPacker:onLoad(_)
    local spec = self.spec_plowPacker
    local actionName = self.xmlFile:getValue("vehicle.plow.packer#inputAction", "IMPLEMENT_EXTRA4")
    if actionName ~= nil then
        spec.packerInputActionIndex = InputAction[actionName]
    end
    spec.packerDeactivateLeftAnimation = self.xmlFile:getValue("vehicle.plow.packer#deactivateLeft")
    spec.packerDeactivateRightAnimation = self.xmlFile:getValue("vehicle.plow.packer#deactivateRight")
    spec.packerDeactivateAnimSpeed = self.xmlFile:getValue("vehicle.plow.packer#animationSpeed", 1)
    spec.packerFoldingConfiguration = self.xmlFile:getValue("vehicle.plow.packer#foldingConfig", 1)
    spec.packerAvailable = self.configurations.folding == spec.packerFoldingConfiguration and spec.packerDeactivateLeftAnimation ~= nil and spec.packerDeactivateRightAnimation ~= nil
    spec.partialDeactivated = self.xmlFile:getValue("vehicle.plow.packer#partialDeactivated", false)
    spec.lowerAnimation = self.xmlFile:getValue("vehicle.plow.packer.lowerAnimation#name")
    spec.lowerAnimationSpeed = self.xmlFile:getValue("vehicle.plow.packer.lowerAnimation#speed", 1)
    spec.packerActivateText = g_i18n:getText("action_activatePacker", self.customEnvironment)
    spec.packerDeactivateText = g_i18n:getText("action_deactivatePacker", self.customEnvironment)
    spec.packerState = true
    spec.delayedFoldStateChange = nil
    spec.delayedLowerAnimationUpdate = false
end
function PlowPacker:onPostLoad(savegame)
    local spec = self.spec_plowPacker
    self:setPlowAIRequirements()
    if savegame ~= nil and (not savegame.resetVehicles and spec.packerAvailable) then
        local packerState = savegame.xmlFile:getValue(savegame.key .. ".plowPacker#packerState")
        if packerState ~= nil then
            self:setPackerState(packerState, true, true)
            AnimatedVehicle.updateAnimations(self, 99999999, true)
        end
        spec.lastPackerState = savegame.xmlFile:getValue(savegame.key .. ".plowPacker#lastPackerState")
    end
end
function PlowPacker:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_plowPacker
    if spec.packerAvailable then
        xmlFile:setValue(key .. "#packerState", spec.packerState)
        if spec.lastPackerState ~= nil then
            xmlFile:setValue(key .. "#lastPackerState", spec.lastPackerState)
        end
    end
end
function PlowPacker:onReadStream(streamId, _)
    if self.spec_plowPacker.packerAvailable then
        local packerState = streamReadBool(streamId)
        if self:getIsPackerAllowed() then
            self:setPackerState(packerState, true, true)
            AnimatedVehicle.updateAnimations(self, 99999999, true)
        end
    end
end
function PlowPacker:onWriteStream(streamId, _)
    local spec = self.spec_plowPacker
    if spec.packerAvailable then
        streamWriteBool(streamId, spec.packerState)
    end
end
function PlowPacker:onUpdate(_, _, _, _)
    if self.isServer then
        local spec = self.spec_plowPacker
        if spec.packerAvailable then
            if spec.lastPackerState ~= nil and self:getIsPackerAllowed() then
                if spec.lastPackerState == false then
                    self:setPackerState(false, true)
                end
                spec.lastPackerState = nil
            end
            if spec.delayedFoldStateChange ~= nil and not (self:getIsAnimationPlaying(spec.packerDeactivateLeftAnimation) or self:getIsAnimationPlaying(spec.packerDeactivateRightAnimation)) then
                local data = spec.delayedFoldStateChange
                data.superFunc(self, data.direction, data.moveToMiddle, false)
                spec.delayedFoldStateChange = nil
            end
            if spec.delayedLowerAnimationUpdate and not (self:getIsAnimationPlaying(spec.packerDeactivateLeftAnimation) or self:getIsAnimationPlaying(spec.packerDeactivateRightAnimation)) then
                local data = self:getIsLowered()
                local animationTime = self:getAnimationTime(spec.lowerAnimation)
                if data and animationTime <= 0.5 or not data and animationTime > 0.5 then
                    self:playAnimation(spec.lowerAnimation, data and spec.lowerAnimationSpeed or -spec.lowerAnimationSpeed, nil, true)
                end
                spec.delayedLowerAnimationUpdate = false
            end
        end
    end
end
function PlowPacker:onUpdateTick(_, _, _, _)
    if self.isClient and self.spec_plowPacker.packerAvailable then
        PlowPacker.updateActionEventText(self)
    end
end
function PlowPacker:setRotationMax(superFunc, rotationMax, noEventSend, turnAnimationTime)
    if self.isServer and self.spec_plow.rotationMax ~= rotationMax then
        local spec = self.spec_plowPacker
        if spec.packerAvailable and spec.lastPackerState == nil then
            spec.lastPackerState = spec.packerState
            self:setPackerState(true, true)
        end
    end
    superFunc(self, rotationMax, noEventSend, turnAnimationTime)
end
function PlowPacker:setPlowAIRequirements(superFunc, excludedGroundTypes)
    local spec = self.spec_plowPacker
    if spec.packerAvailable and (spec.packerState or spec.partialDeactivated) then
        return superFunc(self, PlowPacker.CULTIVATED_GROUND_TYPES)
    else
        return superFunc(self, excludedGroundTypes)
    end
end
function PlowPacker:setFoldState(superFunc, direction, moveToMiddle, noEventSend)
    local spec = self.spec_plowPacker
    if spec.packerAvailable and (direction ~= 0 and (direction ~= self.spec_foldable.turnOnFoldDirection and (self:getIsPackerAllowed() and not spec.packerState))) then
        if self.isServer and spec.lastPackerState == nil then
            spec.lastPackerState = spec.packerState
            self:setPackerState(true, true)
            spec.delayedFoldStateChange = {
                ["superFunc"] = superFunc,
                ["direction"] = direction,
                ["moveToMiddle"] = moveToMiddle
            }
        end
        local specFoldable = self.spec_foldable
        if specFoldable.foldMiddleAnimTime == nil then
            moveToMiddle = false
        end
        if (specFoldable.foldMoveDirection ~= direction or specFoldable.moveToMiddle ~= moveToMiddle) and (noEventSend == nil or noEventSend == false) then
            if g_server ~= nil then
                g_server:broadcastEvent(FoldableSetFoldDirectionEvent.new(self, direction, moveToMiddle), nil, nil, self)
                return
            end
            g_client:getServerConnection():sendEvent(FoldableSetFoldDirectionEvent.new(self, direction, moveToMiddle))
        end
    else
        superFunc(self, direction, moveToMiddle, noEventSend)
    end
end
function PlowPacker:processCultivatorArea(_, workArea, _)
    local spec = self.spec_cultivator
    local xs, _, zs = getWorldTranslation(workArea.start)
    local xw, _, zw = getWorldTranslation(workArea.width)
    local xh, _, zh = getWorldTranslation(workArea.height)
    FSDensityMapUtil.eraseTireTrack(xs, zs, xw, zw, xh, zh)
    if not self.isServer and self.currentUpdateDistance > PlowPacker.CLIENT_DM_UPDATE_RADIUS then
        return 0, 0
    end
    local params = spec.workAreaParameters
    local realArea, area = FSDensityMapUtil.updatePlowPackerArea(xs, zs, xw, zw, xh, zh, params.angle)
    params.lastChangedArea = params.lastChangedArea + realArea
    params.lastStatsArea = params.lastStatsArea + realArea
    params.lastTotalArea = params.lastTotalArea + area
    spec.isWorking = self:getLastSpeed() > 0.5
    return realArea, area
end
function PlowPacker:getUseCultivatorAIRequirements(superFunc)
    return false
end
function PlowPacker:setPackerState(newState, updateAnimations, noEventSend)
    local spec = self.spec_plowPacker
    if newState == nil then
        newState = not spec.packerState
    end
    updateAnimations = updateAnimations == nil and true or updateAnimations
    if newState ~= spec.packerState then
        spec.packerState = newState
        if updateAnimations then
            if self.spec_plow.rotationMax then
                self:playAnimation(spec.packerDeactivateLeftAnimation, spec.packerDeactivateAnimSpeed * (newState and -1 or 1), nil, true)
            else
                self:playAnimation(spec.packerDeactivateRightAnimation, spec.packerDeactivateAnimSpeed * direction, nil, true)
            end
        end
        if newState and spec.lowerAnimation ~= nil then
            local direction = self:getIsLowered()
            local animationTime = self:getAnimationTime(spec.lowerAnimation)
            if direction and animationTime <= 0.5 or not direction and animationTime > 0.5 then
                spec.delayedLowerAnimationUpdate = true
            end
        end
        self:setPlowAIRequirements()
        PlowPackerStateEvent.sendEvent(self, newState, updateAnimations, noEventSend)
    end
    PlowPacker.updateActionEventText(self)
end
function PlowPacker:getIsPackerAllowed()
    if self:getIsAnimationPlaying(self.spec_plow.rotationPart.turnAnimation) then
        return false
    else
        local spec = self:getFoldAnimTime()
        if spec == (self.spec_foldable.turnOnFoldDirection > 0 and 1 or 0) then
            local spec = self.spec_plowPacker
            if spec.delayedFoldStateChange == nil then
                return spec.packerAvailable and true or false
            else
                return false
            end
        else
            return false
        end
    end
end
function PlowPacker:onSetLowered(lowered)
    local spec = self.spec_plowPacker
    if self:getIsPackerAllowed() and (spec.packerState and spec.lowerAnimation ~= nil) then
        self:playAnimation(spec.lowerAnimation, lowered and spec.lowerAnimationSpeed or -spec.lowerAnimationSpeed, nil, true)
    end
end
function PlowPacker:onRegisterActionEvents(isActiveForInput, _)
    if self.isClient then
        local spec = self.spec_plowPacker
        if spec.packerAvailable then
            self:clearActionEventsTable(spec.actionEvents)
            if isActiveForInput and spec.packerInputActionIndex ~= nil then
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, spec.packerInputActionIndex, self, PlowPacker.actionEventPackerDeactivate, false, true, false, true)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
                PlowPacker.updateActionEventText(self)
            end
        end
    end
end
function PlowPacker:updateActionEventText()
    local spec = self.spec_plowPacker
    local actionEvent = spec.actionEvents[spec.packerInputActionIndex]
    if actionEvent ~= nil then
        if spec.packerState then
            g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.packerDeactivateText)
        else
            g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.packerActivateText)
        end
        g_inputBinding:setActionEventActive(actionEvent.actionEventId, self:getIsPackerAllowed())
    end
end
function PlowPacker:actionEventPackerDeactivate(_, _, _, _, _)
    self:setPackerState()
end