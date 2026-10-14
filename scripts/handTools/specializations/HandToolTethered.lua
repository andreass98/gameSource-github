HandToolTethered = {}
function HandToolTethered.registerXMLPaths(xmlSchema)
    xmlSchema:setXMLSpecializationType("HandToolTethered")
    xmlSchema:register(XMLValueType.L10N_STRING, "handTool.tethered#warningText", "The l10n text string to use when warning the player of the range. The remaining range is the first argument", nil, false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.tethered#actionRange", "The range in metres in which this tool can work. When outside of this range, the range warning is shown", "3 metres", false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.tethered#range", "The range in metres before this tool snaps back into its holder", "5 metres", false)
end
function HandToolTethered.registerFunctions(handToolType)
    SpecializationUtil.registerFunction(handToolType, "showRangeWarning", HandToolTethered.showRangeWarning)
    SpecializationUtil.registerFunction(handToolType, "returnToHolder", HandToolTethered.returnToHolder)
    SpecializationUtil.registerFunction(handToolType, "setAttachedHolder", HandToolTethered.setAttachedHolder)
end
function HandToolTethered.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setHolder", HandToolTethered.setHolder)
end
function HandToolTethered.registerEventListeners(handToolType)
    SpecializationUtil.registerEventListener(handToolType, "onLoad", HandToolTethered)
    SpecializationUtil.registerEventListener(handToolType, "onDelete", HandToolTethered)
    SpecializationUtil.registerEventListener(handToolType, "onCarryingPlayerEnteredVehicle", HandToolTethered)
    SpecializationUtil.registerEventListener(handToolType, "onCarryingPlayerLeftGame", HandToolTethered)
    SpecializationUtil.registerEventListener(handToolType, "onPreUpdate", HandToolTethered)
end
function HandToolTethered.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(HandToolStorable, specializations)
end
function HandToolTethered:onLoad(xmlFile, _)
    local spec = self.spec_tethered
    spec.attachedHolder = nil
    spec.rangeWarningText = self.xmlFile:getValue("handTool.tethered#warningText", "DistanceWarning %d", self.customEnvironment, true)
    spec.actionRange = xmlFile:getValue("handTool.tethered#actionRange", 3)
    spec.maximumRange = xmlFile:getValue("handTool.tethered#range", 5)
    if not self.mustBeHeld then
        Logging.warning("HandTool %q has its mustBeHeld value set to false, but tethered tools cannot be put away! Setting to true!", self.typeName)
        self.mustBeHeld = true
    end
    if self.canBeSaved then
        Logging.warning("HandTool %q has its canBeSaved value set to true, but tethered tools cannot be saved! Setting to false!", self.typeName)
        self.canBeSaved = false
    end
    spec.warningIdentifier = getMD5((tostring(self)))
end
function HandToolTethered:onDelete()
    local spec = self.spec_tethered
    if spec.attachedHolder ~= nil then
        spec.attachedHolder.spawnedHandTool = nil
    end
end
function HandToolTethered:onPreUpdate(_)
    local spec = self.spec_tethered
    if spec.attachedHolder == nil then
        return
    elseif self:getIsHeld() then
        local player = self:getCarryingPlayer()
        if player == nil then
            return
        else
            local playerPositionX, playerPositionY, playerPositionZ = player:getPosition()
            local holderPositionX, holderPositionY, holderPositionZ = getWorldTranslation(spec.attachedHolder.holderNode)
            local holderPlayerDistance = MathUtil.vector3Length(playerPositionX - holderPositionX, playerPositionY - holderPositionY, playerPositionZ - holderPositionZ)
            if spec.maximumRange < holderPlayerDistance then
                self:returnToHolder()
            elseif spec.actionRange < holderPlayerDistance and player == g_localPlayer then
                self:showRangeWarning(holderPlayerDistance)
            end
        end
    else
        return
    end
end
function HandToolTethered:setAttachedHolder(holder)
    local spec = self.spec_tethered
    if spec.attachedHolder == nil then
        spec.attachedHolder = holder
    else
        Logging.devWarning("Tethered tool holder already set")
    end
end
function HandToolTethered:onCarryingPlayerLeftGame()
    self:returnToHolder()
end
function HandToolTethered:onCarryingPlayerEnteredVehicle()
    self:returnToHolder()
end
function HandToolTethered:setHolder(superFunc, holder, noEventSend)
    if holder == nil then
        local spec = self.spec_tethered
        if spec.attachedHolder == nil then
            return
        end
        holder = spec.attachedHolder
    end
    superFunc(self, holder, noEventSend)
end
function HandToolTethered:returnToHolder(noEventSend)
    local spec = self.spec_tethered
    if spec.attachedHolder ~= nil then
        self:setHolder(spec.attachedHolder, noEventSend)
    end
end
function HandToolTethered:showRangeWarning(holderPlayerDistance)
    if g_gui:getIsGuiVisible() then
        return
    else
        local spec = self.spec_tethered
        if not string.isNilOrWhitespace(spec.rangeWarningText) then
            g_currentMission:showBlinkingWarning(string.format(spec.rangeWarningText, spec.maximumRange - holderPlayerDistance), 100, spec.warningIdentifier)
        end
    end
end