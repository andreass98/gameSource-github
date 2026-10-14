source("dataS/scripts/vehicles/specializations/events/PlowRotationCenterEvent.lua")
source("dataS/scripts/vehicles/specializations/events/PlowRotationEvent.lua")
source("dataS/scripts/vehicles/specializations/events/PlowLimitToFieldEvent.lua")
Plow = {}
Plow.AI_REQUIRED_GROUND_TYPES = {
    FieldGroundType.STUBBLE_TILLAGE,
    FieldGroundType.CULTIVATED,
    FieldGroundType.SEEDBED,
    FieldGroundType.ROLLED_SEEDBED,
    FieldGroundType.RIDGE,
    FieldGroundType.SOWN,
    FieldGroundType.DIRECT_SOWN,
    FieldGroundType.PLANTED,
    FieldGroundType.RIDGE_SOWN,
    FieldGroundType.ROLLER_LINES,
    FieldGroundType.HARVEST_READY,
    FieldGroundType.HARVEST_READY_OTHER,
    FieldGroundType.GRASS,
    FieldGroundType.GRASS_CUT
}
Plow.AI_OUTPUT_GROUND_TYPES = { FieldGroundType.PLOWED }
Plow.CLIENT_DM_UPDATE_RADIUS = 50
function Plow.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("plow", g_i18n:getText("configuration_design"), "plow", VehicleConfigurationItem)
    g_workAreaTypeManager:addWorkAreaType("plow", true, true, true)
    g_workAreaTypeManager:addWorkAreaType("plowShare", true, false, false)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Plow")
    Plow.registerXMLPaths(schema, "vehicle.plow")
    Plow.registerXMLPaths(schema, "vehicle.plow.plowConfigurations.plowConfiguration(?)")
    schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#disableOnTurn", "Disable while turning", true)
    schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#turnAnimLimit", "Turn animation limit", 0)
    schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#turnAnimLimitSide", "Turn animation limit side", 0)
    schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#invertDirectionOnRotation", "Invert direction on rotation", true)
    schema:setXMLSpecializationType()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).plow#rotationMax", "Rotation max.")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).plow#turnAnimTime", "Turn animation time")
end
function Plow.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".rotationPart#turnAnimationName", "Turn animation name")
    schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#foldMinLimit", "Fold min. limit", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#foldMaxLimit", "Fold max. limit", 1)
    schema:register(XMLValueType.BOOL, basePath .. ".rotationPart#limitFoldRotationMax", "Block folding if in max state")
    schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#foldRotationMinLimit", "Fold allow if inbetween this limit", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#foldRotationMaxLimit", "Fold allow if inbetween this limit", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#rotationFoldMinLimit", "Rotation allow if fold time inbetween this limit", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#rotationFoldMaxLimit", "Rotation allow if fold time inbetween this limit", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#detachMinLimit", "Detach is allowed if turn animation between these values", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#detachMaxLimit", "Detach is allowed if turn animation between these values", 1)
    schema:register(XMLValueType.BOOL, basePath .. ".rotationPart#rotationAllowedIfLowered", "Allow plow rotation if lowered", true)
    schema:register(XMLValueType.L10N_STRING, basePath .. ".rotationPart#detachWarning", "Warning to be displayed if not in correct turn state for detach", "warning_detachNotAllowedPlowTurn")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".directionNode#node", "Plow direction node")
    schema:register(XMLValueType.FLOAT, basePath .. ".ai#centerPosition", "Center position", 0.5)
    schema:register(XMLValueType.FLOAT, basePath .. ".ai#rotateToCenterHeadlandPos", "Rotate to center headland position", 0.5)
    schema:register(XMLValueType.FLOAT, basePath .. ".ai#rotateCompletelyHeadlandPos", "Rotate completely headland position", 0.5)
    schema:register(XMLValueType.BOOL, basePath .. ".ai#stopDuringTurn", "Stop the vehicle while the plow is turning", true)
    schema:register(XMLValueType.BOOL, basePath .. ".ai#allowTurnWhileReversing", "Allow the turn of the plow while we are reversing", true)
    schema:register(XMLValueType.BOOL, basePath .. ".rotateLeftToMax#value", "Rotate left to max", true)
    schema:register(XMLValueType.BOOL, basePath .. ".onlyActiveWhenLowered#value", "Only active when lowered", true)
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "turn(?)")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "work(?)")
end
function Plow.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(WorkArea, specializations)
end
function Plow.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "processPlowArea", Plow.processPlowArea)
    SpecializationUtil.registerFunction(vehicleType, "processPlowShareArea", Plow.processPlowShareArea)
    SpecializationUtil.registerFunction(vehicleType, "setRotationMax", Plow.setRotationMax)
    SpecializationUtil.registerFunction(vehicleType, "setRotationCenter", Plow.setRotationCenter)
    SpecializationUtil.registerFunction(vehicleType, "setPlowLimitToField", Plow.setPlowLimitToField)
    SpecializationUtil.registerFunction(vehicleType, "getIsPlowRotationAllowed", Plow.getIsPlowRotationAllowed)
    SpecializationUtil.registerFunction(vehicleType, "getCanTogglePlowRotation", Plow.getCanTogglePlowRotation)
    SpecializationUtil.registerFunction(vehicleType, "getPlowLimitToField", Plow.getPlowLimitToField)
    SpecializationUtil.registerFunction(vehicleType, "getPlowForceLimitToField", Plow.getPlowForceLimitToField)
    SpecializationUtil.registerFunction(vehicleType, "setPlowAIRequirements", Plow.setPlowAIRequirements)
end
function Plow.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", Plow.getIsFoldAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldMiddleAllowed", Plow.getIsFoldMiddleAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Plow.getDirtMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Plow.getWearMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", Plow.loadSpeedRotatingPartFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", Plow.getIsSpeedRotatingPartActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSpeedRotatingPartDirection", Plow.getSpeedRotatingPartDirection)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Plow.doCheckSpeedLimit)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Plow.loadWorkAreaFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Plow.getIsWorkAreaActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanAIImplementContinueWork", Plow.getCanAIImplementContinueWork)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIInvertMarkersOnTurn", Plow.getAIInvertMarkersOnTurn)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Plow.getCanBeSelected)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", Plow.isDetachAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowsLowering", Plow.getAllowsLowering)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIReadyToDrive", Plow.getIsAIReadyToDrive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIPreparingToDrive", Plow.getIsAIPreparingToDrive)
end
function Plow.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onAIFieldCourseSettingsInitialized", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStartTurn", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onAIImplementTurnProgress", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onAIImplementEndTurn", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onAIImplementSideOffsetChanged", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onAIImplementEnd", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onStartAnimation", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onFinishAnimation", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onFoldTimeChanged", Plow)
    SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", Plow)
end
function Plow:onLoad(_)
    if self:getGroundReferenceNodeFromIndex(1) == nil then
        printWarning("Warning: No ground reference nodes in " .. self.configFileName)
    end
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.rotationPart", "vehicle.plow.rotationPart")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.ploughDirectionNode#index", "vehicle.plow.directionNode#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.rotateLeftToMax#value", "vehicle.plow.rotateLeftToMax#value")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.animTimeCenterPosition#value", "vehicle.plow.ai#centerPosition")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.aiPlough#rotateEarly", "vehicle.plow.ai#rotateCompletelyHeadlandPos")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.onlyActiveWhenLowered#value", "vehicle.plow.onlyActiveWhenLowered#value")
    local configKey = string.format("vehicle.plow.plowConfigurations.plowConfiguration(%d)", (self.configurations.plow or 1) - 1)
    local configKey = not self.xmlFile:hasProperty(configKey) and "vehicle.plow" or configKey
    local spec = self.spec_plow
    spec.rotationPart = {}
    spec.rotationPart.turnAnimation = self.xmlFile:getValue(configKey .. ".rotationPart#turnAnimationName")
    spec.rotationPart.foldMinLimit = self.xmlFile:getValue(configKey .. ".rotationPart#foldMinLimit", 0)
    spec.rotationPart.foldMaxLimit = self.xmlFile:getValue(configKey .. ".rotationPart#foldMaxLimit", 1)
    spec.rotationPart.limitFoldRotationMax = self.xmlFile:getValue(configKey .. ".rotationPart#limitFoldRotationMax")
    spec.rotationPart.foldRotationMinLimit = self.xmlFile:getValue(configKey .. ".rotationPart#foldRotationMinLimit", 0)
    spec.rotationPart.foldRotationMaxLimit = self.xmlFile:getValue(configKey .. ".rotationPart#foldRotationMaxLimit", 1)
    spec.rotationPart.rotationFoldMinLimit = self.xmlFile:getValue(configKey .. ".rotationPart#rotationFoldMinLimit", 0)
    spec.rotationPart.rotationFoldMaxLimit = self.xmlFile:getValue(configKey .. ".rotationPart#rotationFoldMaxLimit", 1)
    spec.rotationPart.detachMinLimit = self.xmlFile:getValue(configKey .. ".rotationPart#detachMinLimit", 0)
    spec.rotationPart.detachMaxLimit = self.xmlFile:getValue(configKey .. ".rotationPart#detachMaxLimit", 1)
    spec.rotationPart.rotationAllowedIfLowered = self.xmlFile:getValue(configKey .. ".rotationPart#rotationAllowedIfLowered", true)
    spec.rotationPart.detachWarning = string.format(self.xmlFile:getValue(configKey .. ".rotationPart#detachWarning", "warning_detachNotAllowedPlowTurn", self.customEnvironment, false))
    spec.directionNode = self.xmlFile:getValue(configKey .. ".directionNode#node", self.components[1].node, self.components, self.i3dMappings)
    self:setPlowAIRequirements()
    spec.ai = {}
    spec.ai.centerPosition = self.xmlFile:getValue(configKey .. ".ai#centerPosition", 0.5)
    spec.ai.rotateToCenterHeadlandPos = self.xmlFile:getValue(configKey .. ".ai#rotateToCenterHeadlandPos", 0.5)
    spec.ai.rotateCompletelyHeadlandPos = self.xmlFile:getValue(configKey .. ".ai#rotateCompletelyHeadlandPos", 0.5)
    spec.ai.stopDuringTurn = self.xmlFile:getValue(configKey .. ".ai#stopDuringTurn", true)
    spec.ai.allowTurnWhileReversing = self.xmlFile:getValue(configKey .. ".ai#allowTurnWhileReversing", true)
    spec.ai.lastHeadlandPosition = 0
    spec.rotateLeftToMax = self.xmlFile:getValue(configKey .. ".rotateLeftToMax#value", true)
    spec.onlyActiveWhenLowered = self.xmlFile:getValue(configKey .. ".onlyActiveWhenLowered#value", true)
    spec.rotationMax = false
    spec.startActivationTimeout = 2000
    spec.startActivationTime = 0
    spec.lastPlowArea = 0
    spec.limitToField = true
    spec.forceLimitToField = false
    spec.wasTurnAnimationStopped = false
    spec.isWorking = false
    if self.isClient then
        spec.samples = {}
        spec.samples.turn = g_soundManager:loadSamplesFromXML(self.xmlFile, configKey .. ".sounds", "turn", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.work = g_soundManager:loadSamplesFromXML(self.xmlFile, configKey .. ".sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.isWorkSamplePlaying = false
    end
    spec.texts = {}
    spec.texts.warningFoldingLowered = g_i18n:getText("warning_foldingNotWhileLowered")
    spec.texts.warningFoldingPlowTurned = g_i18n:getText("warning_foldingNotWhilePlowTurned")
    spec.texts.turnPlow = g_i18n:getText("action_turnPlow")
    spec.texts.allowCreateFields = g_i18n:getText("action_allowCreateFields")
    spec.texts.limitToFields = g_i18n:getText("action_limitToFields")
    spec.workAreaParameters = {}
    spec.workAreaParameters.limitToField = self:getPlowLimitToField()
    spec.workAreaParameters.forceLimitToField = self:getPlowForceLimitToField()
    spec.workAreaParameters.angle = 0
    spec.workAreaParameters.lastChangedArea = 0
    spec.workAreaParameters.lastStatsArea = 0
    spec.workAreaParameters.lastTotalArea = 0
    if not self.isClient then
        SpecializationUtil.removeEventListener(self, "onUpdate", Plow)
    end
end
function Plow:onPostLoad(savegame)
    if savegame ~= nil and not savegame.resetVehicles then
        local rotationMax = savegame.xmlFile:getValue(savegame.key .. ".plow#rotationMax")
        if rotationMax ~= nil and self:getIsPlowRotationAllowed() then
            self:setRotationMax(rotationMax, true, (savegame.xmlFile:getValue(savegame.key .. ".plow#turnAnimTime")))
            if self.updateCylinderedInitial ~= nil then
                self:updateCylinderedInitial(false)
            end
        end
    end
end
function Plow:onDelete()
    local spec = self.spec_plow
    if spec.samples ~= nil then
        g_soundManager:deleteSamples(spec.samples.turn)
        g_soundManager:deleteSamples(spec.samples.work)
    end
end
function Plow:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_plow
    xmlFile:setValue(key .. "#rotationMax", spec.rotationMax)
    if spec.rotationPart.turnAnimation ~= nil and self.playAnimation ~= nil then
        local turnAnimTime = self:getAnimationTime(spec.rotationPart.turnAnimation)
        xmlFile:setValue(key .. "#turnAnimTime", turnAnimTime)
    end
end
function Plow:onReadStream(streamId, _)
    local rotationMax = streamReadBool(streamId)
    local turnAnimTime = nil
    if self.spec_plow.rotationPart.turnAnimation ~= nil and self.playAnimation ~= nil then
        turnAnimTime = streamReadFloat32(streamId)
    end
    self:setRotationMax(rotationMax, true, turnAnimTime)
    if self.updateCylinderedInitial ~= nil then
        self:updateCylinderedInitial(false)
    end
end
function Plow:onWriteStream(streamId, _)
    local spec = self.spec_plow
    streamWriteBool(streamId, spec.rotationMax)
    if spec.rotationPart.turnAnimation ~= nil and self.playAnimation ~= nil then
        local turnAnimTime = self:getAnimationTime(spec.rotationPart.turnAnimation)
        streamWriteFloat32(streamId, turnAnimTime)
    end
end
function Plow:onUpdate(_, _, _, _)
    if self.isClient then
        local spec = self.spec_plow
        local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]
        if actionEvent ~= nil then
            if self:getPlowForceLimitToField() or not g_currentMission:getHasPlayerPermission("createFields", self:getOwnerConnection()) then
                g_inputBinding:setActionEventActive(actionEvent.actionEventId, false)
            else
                g_inputBinding:setActionEventActive(actionEvent.actionEventId, true)
                if self:getPlowLimitToField() then
                    g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.allowCreateFields)
                else
                    g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.limitToFields)
                end
            end
        end
        if spec.rotationPart.turnAnimation ~= nil then
            local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA]
            if actionEvent ~= nil then
                g_inputBinding:setActionEventActive(actionEvent.actionEventId, self:getCanTogglePlowRotation())
            end
        end
    end
end
function Plow:processPlowArea(workArea, _)
    local spec = self.spec_plow
    local xs, _, zs = getWorldTranslation(workArea.start)
    local xw, _, zw = getWorldTranslation(workArea.width)
    local xh, _, zh = getWorldTranslation(workArea.height)
    FSDensityMapUtil.eraseTireTrack(xs, zs, xw, zw, xh, zh)
    if not self.isServer and self.currentUpdateDistance > Plow.CLIENT_DM_UPDATE_RADIUS then
        return 0, 0
    end
    local params = spec.workAreaParameters
    local changedArea = 0
    local totalArea = 0
    if self.tailwaterDepth < 0.1 then
        local changedArea
        changedArea, totalArea = FSDensityMapUtil.updatePlowArea(xs, zs, xw, zw, xh, zh, not params.limitToField, params.limitFruitDestructionToField, params.angle)
        changedArea = changedArea + FSDensityMapUtil.updateVineCultivatorArea(xs, zs, xw, zw, xh, zh)
    end
    params.lastChangedArea = params.lastChangedArea + changedArea
    params.lastStatsArea = params.lastStatsArea + changedArea
    params.lastTotalArea = params.lastTotalArea + totalArea
    spec.isWorking = self:getLastSpeed() > 0.5
    return changedArea, totalArea
end
function Plow:processPlowShareArea(workArea, _)
    local params = self.spec_plow.workAreaParameters
    if not self.isServer and self.currentUpdateDistance > Plow.CLIENT_DM_UPDATE_RADIUS then
        return 0, 0
    end
    local xs, _, zs = getWorldTranslation(workArea.start)
    local xw, _, zw = getWorldTranslation(workArea.width)
    local xh, _, zh = getWorldTranslation(workArea.height)
    FSDensityMapUtil.updatePlowShareArea(xs, zs, xw, zw, xh, zh, not params.limitToField, params.limitFruitDestructionToField, 0.5)
    return 0, 0
end
function Plow:setRotationMax(rotationMax, noEventSend, turnAnimationTime)
    PlowRotationEvent.sendEvent(self, rotationMax, noEventSend)
    local spec = self.spec_plow
    spec.rotationMax = rotationMax
    if spec.rotationPart.turnAnimation ~= nil then
        if turnAnimationTime == nil then
            local animTime = self:getAnimationTime(spec.rotationPart.turnAnimation)
            if spec.rotationMax then
                self:playAnimation(spec.rotationPart.turnAnimation, 1, animTime, true)
            else
                self:playAnimation(spec.rotationPart.turnAnimation, -1, animTime, true)
            end
        end
        self:setAnimationTime(spec.rotationPart.turnAnimation, turnAnimationTime, true)
    end
end
function Plow:setRotationCenter(noEventSend)
    local spec = self.spec_plow
    if spec.rotationPart.turnAnimation ~= nil then
        local animTime = self:getAnimationTime(spec.rotationPart.turnAnimation)
        if animTime ~= spec.ai.centerPosition then
            self:setAnimationStopTime(spec.rotationPart.turnAnimation, spec.ai.centerPosition)
            if animTime < spec.ai.centerPosition then
                self:playAnimation(spec.rotationPart.turnAnimation, 1, animTime, true)
            elseif spec.ai.centerPosition < animTime then
                self:playAnimation(spec.rotationPart.turnAnimation, -1, animTime, true)
            end
        end
    end
    PlowRotationCenterEvent.sendEvent(self, noEventSend)
end
function Plow:setPlowLimitToField(plowLimitToField, noEventSend)
    local spec = self.spec_plow
    if spec.limitToField ~= plowLimitToField then
        if noEventSend == nil or noEventSend == false then
            if g_server == nil then
                g_client:getServerConnection():sendEvent(PlowLimitToFieldEvent.new(self, plowLimitToField))
            else
                g_server:broadcastEvent(PlowLimitToFieldEvent.new(self, plowLimitToField), nil, nil, self)
            end
        end
        spec.limitToField = plowLimitToField
        local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]
        if actionEvent ~= nil then
            local text
            if spec.limitToField then
                text = spec.texts.allowCreateFields
            else
                text = spec.texts.limitToFields
            end
            g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
        end
    end
end
function Plow:getIsPlowRotationAllowed()
    if self.getFoldAnimTime ~= nil then
        local foldAnimTime = self:getFoldAnimTime()
        if self.spec_plow.rotationPart.rotationFoldMaxLimit < foldAnimTime or foldAnimTime < self.spec_plow.rotationPart.rotationFoldMinLimit then
            return false
        end
    end
    return true
end
function Plow:getCanTogglePlowRotation()
    if self:getIsPlowRotationAllowed() then
        if self.spec_plow.rotationPart.rotationAllowedIfLowered or (self.getIsLowered == nil or not self:getIsLowered()) then
            return self:getIsPowered() and true or false
        else
            return false
        end
    else
        return false
    end
end
function Plow:getPlowLimitToField()
    return self.spec_plow.limitToField
end
function Plow:getPlowForceLimitToField()
    return self.spec_plow.forceLimitToField or not Platform.gameplay.canCreateFields
end
function Plow:setPlowAIRequirements(excludedGroundTypes)
    if self.clearAITerrainDetailRequiredRange ~= nil then
        self:clearAITerrainDetailRequiredRange()
        if excludedGroundTypes == nil then
            self:addAIGroundTypeRequirements(Plow.AI_REQUIRED_GROUND_TYPES)
        else
            self:addAIGroundTypeRequirements(Plow.AI_REQUIRED_GROUND_TYPES, unpack(excludedGroundTypes))
        end
        self:setAIImplementVariableSideOffset(true)
    end
end
function Plow:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
    local spec = self.spec_plow
    if spec.rotationPart.limitFoldRotationMax == nil or spec.rotationPart.limitFoldRotationMax ~= spec.rotationMax then
        if spec.rotationPart.turnAnimation ~= nil and self.getAnimationTime ~= nil then
            local rotationTime = self:getAnimationTime(spec.rotationPart.turnAnimation)
            if spec.rotationPart.foldRotationMaxLimit < rotationTime or rotationTime < spec.rotationPart.foldRotationMinLimit then
                return false, spec.texts.warningFoldingPlowTurned
            end
        end
        if spec.rotationPart.rotationAllowedIfLowered or (self.getIsLowered == nil or not self:getIsLowered()) then
            return superFunc(self, direction, onAiTurnOn)
        else
            return false, spec.texts.warningFoldingLowered
        end
    else
        return false, spec.texts.warningFoldingPlowTurned
    end
end
function Plow:getIsFoldMiddleAllowed(superFunc)
    local spec = self.spec_plow
    if spec.rotationPart.limitFoldRotationMax ~= nil and spec.rotationPart.limitFoldRotationMax == spec.rotationMax then
        return false
    end
    if spec.rotationPart.turnAnimation ~= nil and self.getAnimationTime ~= nil then
        local rotationTime = self:getAnimationTime(spec.rotationPart.turnAnimation)
        if spec.rotationPart.foldRotationMaxLimit < rotationTime or rotationTime < spec.rotationPart.foldRotationMinLimit then
            return false
        end
    end
    return superFunc(self)
end
function Plow:getDirtMultiplier(superFunc)
    local multiplier = superFunc(self)
    if self.spec_plow.isWorking then
        multiplier = multiplier + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
    end
    return multiplier
end
function Plow:getWearMultiplier(superFunc)
    local multiplier = superFunc(self)
    if self.spec_plow.isWorking then
        multiplier = multiplier + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
    end
    return multiplier
end
function Plow:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
    if not superFunc(self, speedRotatingPart, xmlFile, key) then
        return false
    end
    speedRotatingPart.disableOnTurn = xmlFile:getValue(key .. "#disableOnTurn", true)
    speedRotatingPart.turnAnimLimit = xmlFile:getValue(key .. "#turnAnimLimit", 0)
    speedRotatingPart.turnAnimLimitSide = xmlFile:getValue(key .. "#turnAnimLimitSide", 0)
    speedRotatingPart.invertDirectionOnRotation = xmlFile:getValue(key .. "#invertDirectionOnRotation", true)
    return true
end
function Plow:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
    local spec = self.spec_plow
    if spec.rotationPart.turnAnimation ~= nil and speedRotatingPart.disableOnTurn then
        local turnAnimTime = self:getAnimationTime(spec.rotationPart.turnAnimation)
        if turnAnimTime ~= nil then
            local enabled
            if speedRotatingPart.turnAnimLimitSide < 0 then
                enabled = turnAnimTime <= speedRotatingPart.turnAnimLimit
            elseif speedRotatingPart.turnAnimLimitSide > 0 then
                enabled = 1 - turnAnimTime <= speedRotatingPart.turnAnimLimit
            else
                enabled = true
                if turnAnimTime > speedRotatingPart.turnAnimLimit then
                    enabled = 1 - turnAnimTime <= speedRotatingPart.turnAnimLimit
                end
            end
            if not enabled then
                return false
            end
        end
    end
    return superFunc(self, speedRotatingPart)
end
function Plow:getSpeedRotatingPartDirection(superFunc, speedRotatingPart)
    local spec = self.spec_plow
    return spec.rotationPart.turnAnimation ~= nil and (self:getAnimationTime(spec.rotationPart.turnAnimation) > 0.5 and speedRotatingPart.invertDirectionOnRotation) and -1 or superFunc(self, speedRotatingPart)
end
function Plow:doCheckSpeedLimit(superFunc)
    return not superFunc(self) and self.spec_plow.onlyActiveWhenLowered and self:getIsImplementChainLowered()
end
function Plow:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
    local retValue = superFunc(self, workArea, xmlFile, key)
    if workArea.type == WorkAreaType.DEFAULT then
        workArea.type = WorkAreaType.PLOW
    end
    return retValue
end
function Plow.getDefaultSpeedLimit()
    return 15
end
function Plow:getIsWorkAreaActive(superFunc, workArea)
    if workArea.type == WorkAreaType.PLOW then
        local spec = self.spec_plow
        if spec.startActivationTime > g_currentMission.time then
            return false
        end
        if spec.onlyActiveWhenLowered and (self.getIsLowered ~= nil and not self:getIsLowered(false)) then
            return false
        end
    end
    return superFunc(self, workArea)
end
function Plow:getCanAIImplementContinueWork(superFunc, isTurning)
    local canContinue, stopAI, stopReason = superFunc(self, isTurning)
    if not canContinue then
        return false, stopAI, stopReason
    end
    local spec = self.spec_plow
    return not spec.ai.stopDuringTurn and isTurning and true or not self:getIsAnimationPlaying(spec.rotationPart.turnAnimation)
end
function Plow:getAIInvertMarkersOnTurn(_, turnLeft)
    local spec = self.spec_plow
    if spec.rotationPart.turnAnimation == nil then
        return false
    elseif turnLeft then
        return spec.rotationMax == spec.rotateLeftToMax
    else
        return spec.rotationMax ~= spec.rotateLeftToMax
    end
end
function Plow:getCanBeSelected(superFunc)
    return true
end
function Plow:isDetachAllowed(superFunc)
    local spec = self.spec_plow
    if self:getIsAnimationPlaying(spec.rotationPart.turnAnimation) then
        return false
    end
    if spec.rotationPart.turnAnimation ~= nil then
        local animTime = self:getAnimationTime(spec.rotationPart.turnAnimation)
        if animTime < spec.rotationPart.detachMinLimit or spec.rotationPart.detachMaxLimit < animTime then
            return false, spec.rotationPart.detachWarning, true
        end
    end
    return superFunc(self)
end
function Plow:getAllowsLowering(superFunc)
    if self:getIsAnimationPlaying(self.spec_plow.rotationPart.turnAnimation) then
        return false
    else
        return superFunc(self)
    end
end
function Plow:getIsAIReadyToDrive(superFunc)
    local spec = self.spec_plow
    if spec.rotationMax or self:getIsAnimationPlaying(spec.rotationPart.turnAnimation) then
        return false
    else
        return superFunc(self)
    end
end
function Plow:getIsAIPreparingToDrive(superFunc)
    return self:getIsAnimationPlaying(self.spec_plow.rotationPart.turnAnimation) and true or superFunc(self)
end
function Plow:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_plow
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection then
            if spec.rotationPart.turnAnimation ~= nil then
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA, self, Plow.actionEventTurn, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
                g_inputBinding:setActionEventText(actionEventId, spec.texts.turnPlow)
            end
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, Plow.actionEventLimitToField, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
        end
    end
end
function Plow:onStartWorkAreaProcessing(_)
    local spec = self.spec_plow
    spec.isWorking = false
    local limitToField = self:getPlowLimitToField()
    local limitFruitDestructionToField
    if g_currentMission:getHasPlayerPermission("createFields", self:getOwnerConnection(), nil, true) then
        limitFruitDestructionToField = limitToField
    else
        limitToField = true
        limitFruitDestructionToField = true
    end
    local dx, _, dz = localDirectionToWorld(spec.directionNode, 0, 0, 1)
    local angle = FSDensityMapUtil.convertToDensityMapAngle(MathUtil.getYRotationFromDirection(dx, dz), g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())
    spec.workAreaParameters.limitToField = limitToField
    spec.workAreaParameters.limitFruitDestructionToField = limitFruitDestructionToField
    spec.workAreaParameters.angle = angle
    spec.workAreaParameters.lastChangedArea = 0
    spec.workAreaParameters.lastStatsArea = 0
    spec.workAreaParameters.lastTotalArea = 0
end
function Plow:onEndWorkAreaProcessing(dt)
    if self.isServer then
        local farmId = self:getLastTouchedFarmlandFarmId()
        local lastStatsArea = self.spec_plow.workAreaParameters.lastStatsArea
        if lastStatsArea > 0 then
            local ha = MathUtil.areaToHa(lastStatsArea, g_currentMission:getFruitPixelsToSqm())
            g_farmManager:updateFarmStats(farmId, "plowedHectares", ha)
            self:updateLastWorkedArea(lastStatsArea)
        end
        if spec.isWorking then
            g_farmManager:updateFarmStats(farmId, "plowedTime", dt / 60000)
        end
    end
    if self.isClient then
        if spec.isWorking then
            if not spec.isWorkSamplePlaying then
                g_soundManager:playSamples(spec.samples.work)
                spec.isWorkSamplePlaying = true
                return
            end
        elseif spec.isWorkSamplePlaying then
            g_soundManager:stopSamples(spec.samples.work)
            spec.isWorkSamplePlaying = false
        end
    end
end
function Plow:onPostAttach(_, _, _)
    local spec = self.spec_plow
    spec.startActivationTime = g_currentMission.time + spec.startActivationTimeout
    if spec.wasTurnAnimationStopped then
        self:playAnimation(spec.rotationPart.turnAnimation, not spec.rotationMax and -1 or 1, self:getAnimationTime(spec.rotationPart.turnAnimation), true)
        spec.wasTurnAnimationStopped = false
    end
end
function Plow:onPreDetach(_, _)
    local spec = self.spec_plow
    spec.limitToField = true
    if self:getIsAnimationPlaying(spec.rotationPart.turnAnimation) then
        self:stopAnimation(spec.rotationPart.turnAnimation, true)
        spec.wasTurnAnimationStopped = true
    end
end
function Plow:onDeactivate()
    if self.isClient then
        local spec = self.spec_plow
        g_soundManager:stopSamples(spec.samples.work)
        g_soundManager:stopSamples(spec.samples.turn)
        spec.isWorkSamplePlaying = false
    end
end
function Plow.onAIFieldCourseSettingsInitialized(_, fieldCourseSettings)
    fieldCourseSettings.toolFullOverlap = true
    fieldCourseSettings.toolFullOverlapInside = true
    fieldCourseSettings.segmentSplitAngle = 25
end
function Plow:onAIImplementStartTurn(_)
    self.spec_plow.ai.lastHeadlandPosition = 0
end
function Plow:onAIImplementTurnProgress(progress, isLeft, movingDirection)
    local spec = self.spec_plow
    if movingDirection > 0 or spec.ai.allowTurnWhileReversing then
        if spec.ai.lastHeadlandPosition <= spec.ai.rotateToCenterHeadlandPos and (spec.ai.rotateToCenterHeadlandPos < progress and progress < spec.ai.rotateCompletelyHeadlandPos) then
            self:setRotationCenter()
        elseif spec.ai.lastHeadlandPosition < spec.ai.rotateCompletelyHeadlandPos and spec.ai.rotateCompletelyHeadlandPos < progress then
            self:setRotationMax(isLeft)
        end
        spec.ai.lastHeadlandPosition = progress
    end
end
function Plow:onAIImplementEndTurn(isLeft)
    self:setRotationMax(isLeft)
end
function Plow:onAIImplementSideOffsetChanged(isLeft, isInitial)
    if isInitial then
        if self:getIsPlowRotationAllowed() then
            self:setRotationMax(isLeft)
            return
        end
        self.spec_plow.ai.rotationMaxToSet = isLeft
    end
end
function Plow:onAIImplementEnd()
    self.spec_plow.ai.rotationMaxToSet = nil
end
function Plow:onStartAnimation(animName)
    local spec = self.spec_plow
    if animName == spec.rotationPart.turnAnimation then
        g_soundManager:playSamples(spec.samples.turn)
    end
end
function Plow:onFinishAnimation(animName)
    local spec = self.spec_plow
    if animName == spec.rotationPart.turnAnimation then
        g_soundManager:stopSamples(spec.samples.turn)
    end
end
function Plow:onFoldTimeChanged(_)
    if self.isServer then
        local spec = self.spec_plow
        if spec.ai.rotationMaxToSet ~= nil and self:getIsPlowRotationAllowed() then
            self:setRotationMax(spec.ai.rotationMaxToSet)
            spec.ai.rotationMaxToSet = nil
        end
    end
end
function Plow:onRootVehicleChanged(rootVehicle)
    local spec = self.spec_plow
    local specFoldable = self.spec_foldable
    if specFoldable ~= nil and #specFoldable.foldingParts > 0 then
        local actionController = rootVehicle.actionController
        if actionController == nil then
            if spec.controlledActionRotateBack ~= nil then
                spec.controlledActionRotateBack:remove()
                spec.controlledActionRotateBack = nil
            end
        else
            if spec.controlledActionRotateBack ~= nil then
                spec.controlledActionRotateBack:updateParent(actionController)
                return
            end
            spec.controlledActionRotateBack = actionController:registerAction("rotateBackPlow", nil, 3)
            spec.controlledActionRotateBack:setCallback(self, Plow.actionControllerRotateBackEvent)
            spec.controlledActionRotateBack:addAIEventListener(self, "onAIImplementPrepareForTransport", -1, true)
        end
    end
    local actionController = rootVehicle.actionController
    if actionController == nil then
        if spec.controlledActionRotate ~= nil then
            spec.controlledActionRotate:remove()
            spec.controlledActionRotate = nil
        end
        return
    elseif spec.controlledActionRotate == nil then
        spec.controlledActionRotate = actionController:registerAction("rotatePlow", nil, 3)
        spec.controlledActionRotate:setCallback(self, Plow.actionControllerRotateEvent)
        spec.controlledActionRotate:setFinishedFunctions(self, function(vehicle)
            -- upvalues: (copy) self, (copy) spec
            return self:getIsAnimationPlaying(spec.rotationPart.turnAnimation)
        end, false, false)
        spec.controlledActionRotate:addAIEventListener(self, "onAIImplementStart", 1, true)
        spec.controlledActionRotate:setResetOnDeactivation(false)
    else
        spec.controlledActionRotate:updateParent(actionController)
    end
end
function Plow:actionEventTurn(_, _, _, _)
    local spec = self.spec_plow
    if spec.rotationPart.turnAnimation ~= nil and self:getCanTogglePlowRotation() then
        self:setRotationMax(not spec.rotationMax)
    end
end
function Plow:actionEventLimitToField(_, _, _, _)
    if not self:getPlowForceLimitToField() then
        self:setPlowLimitToField(not self.spec_plow.limitToField)
    end
end
function Plow:actionControllerRotateBackEvent(_, isAIEvent)
    if not isAIEvent then
        return false
    end
    local spec = self.spec_plow
    if spec.rotationPart.turnAnimation ~= nil and (self:getCanTogglePlowRotation() and spec.rotationMax) then
        self:setRotationMax(false)
    end
    return true
end
function Plow:actionControllerRotateEvent(direction, _)
    local spec = self.spec_plow
    if spec.rotationPart.turnAnimation ~= nil and self:getCanTogglePlowRotation() then
        if direction < 0 then
            self:setRotationMax(not spec.rotationMax)
        elseif not self:getIsAnimationPlaying(spec.rotationPart.turnAnimation) then
            local animationTime = self:getAnimationTime(spec.rotationPart.turnAnimation)
            if animationTime > 0 and animationTime < 1 then
                self:setRotationMax(spec.rotationMax)
            end
        end
    end
    return true
end