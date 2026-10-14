source("dataS/scripts/vehicles/specializations/events/SetCoverStateEvent.lua")
Cover = {}
Cover.SEND_NUM_BITS = 4
Cover.COVER_XML_KEY = "vehicle.cover.coverConfigurations.coverConfiguration(?).cover(?)"
function Cover.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
end
function Cover.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("cover", g_i18n:getText("configuration_cover"), "cover", VehicleConfigurationItem)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Cover")
    schema:register(XMLValueType.STRING, Cover.COVER_XML_KEY .. "#openAnimation", "Open animation name")
    schema:register(XMLValueType.FLOAT, Cover.COVER_XML_KEY .. "#openAnimationStopTime", "Open animation stop time")
    schema:register(XMLValueType.FLOAT, Cover.COVER_XML_KEY .. "#openAnimationStartTime", "Open animation start time")
    schema:register(XMLValueType.STRING, Cover.COVER_XML_KEY .. "#closeAnimation", "Close animation name")
    schema:register(XMLValueType.FLOAT, Cover.COVER_XML_KEY .. "#closeAnimationStopTime", "Close animation stop time")
    schema:register(XMLValueType.BOOL, Cover.COVER_XML_KEY .. "#openOnBuy", "Open after buying", false)
    schema:register(XMLValueType.BOOL, Cover.COVER_XML_KEY .. "#forceOpenOnTip", "Open while tipping", true)
    schema:register(XMLValueType.BOOL, Cover.COVER_XML_KEY .. "#autoReactToTrigger", "Automatically open in triggers", true)
    schema:register(XMLValueType.VECTOR_N, Cover.COVER_XML_KEY .. "#fillUnitIndices", "Fill unit indices to cover")
    schema:register(XMLValueType.STRING, Cover.COVER_XML_KEY .. "#blockedToolTypes", "List with blocked tool types", "dischargeable bale trigger pallet")
    schema:register(XMLValueType.BOOL, "vehicle.cover.coverConfigurations.coverConfiguration(?)#closeCoverIfNotAllowed", "Close cover if not allowed to open it", false)
    schema:register(XMLValueType.BOOL, "vehicle.cover.coverConfigurations.coverConfiguration(?)#openCoverWhileTipping", "Open cover while tipping", false)
    schema:register(XMLValueType.L10N_STRING, "vehicle.cover.coverConfigurations.coverConfiguration(?).texts#openCover", "Open cover text", "$l10n_action_openCover")
    schema:register(XMLValueType.L10N_STRING, "vehicle.cover.coverConfigurations.coverConfiguration(?).texts#closeCover", "Close cover text", "$l10n_action_closeCover")
    schema:register(XMLValueType.L10N_STRING, "vehicle.cover.coverConfigurations.coverConfiguration(?).texts#nextCover", "Next cover text", "$l10n_action_nextCover")
    schema:register(XMLValueType.INT, "vehicle.pipe#coverMinState", "Min. cover state to allow pipe state change", 0)
    schema:register(XMLValueType.INT, "vehicle.pipe#coverMaxState", "Max. cover state to allow pipe state change", "Max. cover state")
    schema:setXMLSpecializationType()
    Vehicle.xmlSchemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).cover#state", "Current cover state")
end
function Cover.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadCoverFromXML", Cover.loadCoverFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getIsNextCoverStateAllowed", Cover.getIsNextCoverStateAllowed)
    SpecializationUtil.registerFunction(vehicleType, "getIsNextCoverStateAllowedWarning", Cover.getIsNextCoverStateAllowedWarning)
    SpecializationUtil.registerFunction(vehicleType, "setCoverState", Cover.setCoverState)
    SpecializationUtil.registerFunction(vehicleType, "playCoverAnimation", Cover.playCoverAnimation)
    SpecializationUtil.registerFunction(vehicleType, "getCoverByFillUnitIndex", Cover.getCoverByFillUnitIndex)
end
function Cover.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitSupportsToolType", Cover.getFillUnitSupportsToolType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Cover.getCanBeSelected)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadPipeNodes", Cover.loadPipeNodes)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPipeStateChangeAllowed", Cover.getIsPipeStateChangeAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "aiPrepareLoading", Cover.aiPrepareLoading)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "aiFinishLoading", Cover.aiFinishLoading)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "finishedAIDischarge", Cover.finishedAIDischarge)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setFillUnitInTriggerRange", Cover.setFillUnitInTriggerRange)
end
function Cover.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Cover)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Cover)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Cover)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Cover)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Cover)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Cover)
    SpecializationUtil.registerEventListener(vehicleType, "onStartTipping", Cover)
    SpecializationUtil.registerEventListener(vehicleType, "onOpenBackDoor", Cover)
    SpecializationUtil.registerEventListener(vehicleType, "onFillUnitTriggerChanged", Cover)
    SpecializationUtil.registerEventListener(vehicleType, "onRemovedFillUnitTrigger", Cover)
end
function Cover:onLoad(_)
    local spec = self.spec_cover
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cover#animationName", "vehicle.cover.coverConfigurations.coverConfiguration.cover#openAnimation")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.foldable.foldingParts#closeCoverOnFold", "vehicle.cover.coverConfigurations.coverConfiguration.cover#closeCoverIfNotAllowed")
    local coverConfigurationId = Utils.getNoNil(self.configurations.cover, 1)
    local configKey = string.format("vehicle.cover.coverConfigurations.coverConfiguration(%d)", coverConfigurationId - 1)
    spec.state = 0
    spec.runningAnimations = {}
    spec.covers = {}
    spec.fillUnitIndexToCovers = {}
    spec.isStateSetAutomatically = false
    local i = 0
    while true do
        local key = string.format("%s.cover(%d)", configKey, i)
        if not self.xmlFile:hasProperty(key) then
            break
        end
        local cover = {}
        if self:loadCoverFromXML(self.xmlFile, key, cover) then
            local j = #cover.fillUnitIndices
            for j = j, 1, -1 do
                local index = cover.fillUnitIndices[j]
                if spec.fillUnitIndexToCovers[index] == nil then
                    spec.fillUnitIndexToCovers[index] = { cover }
                else
                    table.insert(spec.fillUnitIndexToCovers[index], cover)
                end
            end
            table.insert(spec.covers, cover)
            cover.index = #spec.covers
        end
        i = i + 1
    end
    spec.closeCoverIfNotAllowed = self.xmlFile:getValue(configKey .. "#closeCoverIfNotAllowed", false)
    spec.openCoverWhileTipping = self.xmlFile:getValue(configKey .. "#openCoverWhileTipping", false)
    spec.texts = {}
    spec.texts.openCover = self.xmlFile:getValue(configKey .. ".texts#openCover", "action_openCover", self.customEnvironment)
    spec.texts.closeCover = self.xmlFile:getValue(configKey .. ".texts#closeCover", "action_closeCover", self.customEnvironment)
    spec.texts.nextCover = self.xmlFile:getValue(configKey .. ".texts#nextCover", "action_nextCover", self.customEnvironment)
    local key = #spec.covers > 0
    spec.hasCovers = key
    spec.isDirty = false
    if not spec.hasCovers then
        SpecializationUtil.removeEventListener(self, "onReadStream", Cover)
        SpecializationUtil.removeEventListener(self, "onWriteStream", Cover)
        SpecializationUtil.removeEventListener(self, "onUpdate", Cover)
        SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", Cover)
        SpecializationUtil.removeEventListener(self, "onStartTipping", Cover)
        SpecializationUtil.removeEventListener(self, "onFillUnitTriggerChanged", Cover)
        SpecializationUtil.removeEventListener(self, "onRemovedFillUnitTrigger", Cover)
    end
end
function Cover:onPostLoad(savegame)
    local spec = self.spec_cover
    if spec.hasCovers then
        local state = 0
        if savegame == nil then
            local i = 1
            for i = i, #spec.covers do
                if spec.covers[i].startOpenState then
                    state = i
                end
            end
        else
            state = savegame.xmlFile:getValue(savegame.key .. ".cover#state", state)
        end
        if state == 0 then
            spec.state = #spec.covers
        end
        self:setCoverState(state, true)
        local i = #spec.runningAnimations
        for i = i, 1, -1 do
            AnimatedVehicle.updateAnimationByName(self, spec.runningAnimations[i].name, 9999999, true)
            table.remove(spec.runningAnimations, i)
        end
        spec.isDirty = false
    end
end
function Cover:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_cover
    if spec.hasCovers then
        xmlFile:setValue(key .. "#state", spec.state)
    end
end
function Cover:onReadStream(streamId, connection)
    if connection:getIsServer() then
        local spec = self.spec_cover
        self:setCoverState(streamReadUIntN(streamId, Cover.SEND_NUM_BITS), true)
        local i = #spec.runningAnimations
        for i = i, 1, -1 do
            AnimatedVehicle.updateAnimationByName(self, spec.runningAnimations[i].name, 9999999, true)
            table.remove(spec.runningAnimations, i)
        end
        spec.isDirty = false
    end
end
function Cover:onWriteStream(streamId, connection)
    if not connection:getIsServer() then
        streamWriteUIntN(streamId, self.spec_cover.state, Cover.SEND_NUM_BITS)
    end
end
function Cover:onUpdate(_, _, _, _)
    local spec = self.spec_cover
    if spec.isDirty then
        local animation = spec.runningAnimations[1]
        if animation ~= nil then
            local nextAnim = spec.runningAnimations[2]
            if nextAnim ~= nil and (nextAnim.name == animation.name and nextAnim.startTime == nil) then
                table.remove(spec.runningAnimations, 1)
                self:stopAnimation(animation.name, true)
                self:playCoverAnimation(nextAnim)
            end
            if not self:getIsAnimationPlaying(animation.name) then
                table.remove(spec.runningAnimations, 1)
                local nextAnimation = spec.runningAnimations[1]
                if nextAnimation == nil then
                    spec.isDirty = false
                else
                    self:playCoverAnimation(nextAnimation)
                end
            end
        end
    end
    if spec.closeCoverIfNotAllowed and spec.state ~= 0 then
        local animation = spec.state + 1
        if not self:getIsNextCoverStateAllowed(#spec.covers < animation and 0 or animation) then
            self:setCoverState(0, true)
        end
    end
end
function Cover:loadCoverFromXML(xmlFile, key, cover)
    cover.openAnimation = xmlFile:getValue(key .. "#openAnimation")
    cover.openAnimationStartTime = xmlFile:getValue(key .. "#openAnimationStartTime")
    cover.openAnimationStopTime = xmlFile:getValue(key .. "#openAnimationStopTime")
    if cover.openAnimation == nil then
        Logging.xmlWarning(self.xmlFile, "Missing \'openAnimation\' for cover \'%s\'!", key)
        return false
    end
    cover.closeAnimation = xmlFile:getValue(key .. "#closeAnimation")
    cover.closeAnimationStopTime = xmlFile:getValue(key .. "#closeAnimationStopTime")
    cover.startOpenState = xmlFile:getValue(key .. "#openOnBuy", false)
    cover.forceOpenOnTip = xmlFile:getValue(key .. "#forceOpenOnTip", true)
    cover.autoReactToTrigger = xmlFile:getValue(key .. "#autoReactToTrigger", true)
    cover.fillUnitIndices = xmlFile:getValue(key .. "#fillUnitIndices", nil, true)
    if cover.fillUnitIndices == nil or #cover.fillUnitIndices == 0 then
        Logging.xmlWarning(self.xmlFile, "Missing \'fillUnitIndices\' for cover \'%s\'!", key)
        return false
    end
    cover.blockedToolTypes = {}
    local strBlockedToolTypes = xmlFile:getValue(key .. "#blockedToolTypes", "dischargeable bale trigger pallet"):trim():split(" ")
    for _, toolType in ipairs(strBlockedToolTypes) do
        local index = g_toolTypeManager:getToolTypeIndexByName(toolType)
        if index ~= ToolType.UNDEFINED then
            cover.blockedToolTypes[index] = true
        end
    end
    return true
end
function Cover:setCoverState(state, noEventSend)
    local spec = self.spec_cover
    if spec.hasCovers and (state >= 0 and (state <= #spec.covers and spec.state ~= state)) then
        SetCoverStateEvent.sendEvent(self, state, noEventSend)
        if spec.state > 0 then
            local cover = spec.covers[spec.state]
            local animation = cover.closeAnimation
            local stopTime = cover.closeAnimationStopTime or 1
            if animation == nil then
                animation = cover.openAnimation
                stopTime = cover.openAnimationStopTime or 0
            end
            if self:getAnimationExists(animation) then
                table.insert(spec.runningAnimations, {
                    ["name"] = animation,
                    ["stopTime"] = stopTime
                })
            end
        end
        if state > 0 then
            local cover = spec.covers[state]
            table.insert(spec.runningAnimations, {
                ["name"] = cover.openAnimation,
                ["startTime"] = cover.openAnimationStartTime,
                ["stopTime"] = cover.openAnimationStopTime or 1
            })
        end
        spec.state = state
        local cover = #spec.runningAnimations > 0
        spec.isDirty = cover
        if #spec.runningAnimations == 0 and #spec.runningAnimations > 0 then
            self:playCoverAnimation(spec.runningAnimations[1])
        end
        Cover.updateActionText(self)
    end
end
function Cover:playCoverAnimation(animation)
    if animation.startTime ~= nil then
        self:setAnimationTime(animation.name, animation.startTime, true)
    end
    local dir = math.sign(animation.stopTime - self:getAnimationTime(animation.name))
    self:setAnimationStopTime(animation.name, animation.stopTime)
    self:playAnimation(animation.name, dir, animation.startTime or self:getAnimationTime(animation.name), true)
end
function Cover:getCoverByFillUnitIndex(fillUnitIndex)
    local covers = self.spec_cover.fillUnitIndexToCovers[fillUnitIndex]
    if covers == nil then
        return nil
    else
        return covers[1]
    end
end
function Cover:getIsNextCoverStateAllowed(_)
    return #self.spec_cover.runningAnimations <= 1
end
function Cover:getIsNextCoverStateAllowedWarning(nextState)
    return nil
end
function Cover:getFillUnitSupportsToolType(superFunc, fillUnitIndex, toolType)
    local spec = self.spec_cover
    if spec.hasCovers then
        local covers = spec.fillUnitIndexToCovers[fillUnitIndex]
        if covers ~= nil and #covers > 0 then
            local isOpen = false
            local i = 1
            for i = i, #covers do
                if spec.state == covers[i].index then
                    isOpen = true
                    break
                end
            end
            if not isOpen and covers[1].blockedToolTypes[toolType] then
                return false
            end
        end
    end
    return superFunc(self, fillUnitIndex, toolType)
end
function Cover:getCanBeSelected(superFunc)
    return true
end
function Cover:loadPipeNodes(superFunc, pipeNodes, xmlFile, baseKey)
    superFunc(self, pipeNodes, xmlFile, baseKey)
    local spec = self.spec_pipe
    spec.coverMinState = xmlFile:getValue("vehicle.pipe#coverMinState", 0)
    spec.coverMaxState = xmlFile:getValue("vehicle.pipe#coverMaxState", #self.spec_cover.covers)
end
function Cover:getIsPipeStateChangeAllowed(superFunc, nextPipeState, ...)
    if not superFunc(self, nextPipeState, ...) then
        return false
    end
    local spec = self.spec_pipe
    local specCover = self.spec_cover
    return specCover.state >= spec.coverMinState and specCover.state <= spec.coverMaxState
end
function Cover:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_cover
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection then
            local state, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_COVER, self, Cover.actionEventToggleCover, false, true, false, true, nil, nil, true, true)
            if not state then
                _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA4, self, Cover.actionEventToggleCover, false, true, false, true, nil, nil, true, true)
            end
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            Cover.updateActionText(self)
        end
    end
end
function Cover:onStartTipping(tipSide)
    if self.spec_cover.openCoverWhileTipping then
        local cover = self:getCoverByFillUnitIndex(self:getDischargeNodeByIndex(self.spec_trailer.tipSides[tipSide].dischargeNodeIndex).fillUnitIndex)
        if cover ~= nil then
            self:setCoverState(cover.index, true)
        end
    end
end
function Cover:onOpenBackDoor(tipSide)
    if self.spec_cover.openCoverWhileTipping then
        local cover = self:getCoverByFillUnitIndex(self:getDischargeNodeByIndex(self.spec_trailer.tipSides[tipSide].dischargeNodeIndex).fillUnitIndex)
        if cover ~= nil then
            self:setCoverState(cover.index, true)
        end
    end
end
function Cover:finishedAIDischarge(superFunc)
    if self.spec_cover.hasCovers then
        self:setCoverState(0)
    end
    superFunc(self)
end
function Cover:aiPrepareLoading(superFunc, fillUnitIndex, task)
    local cover = self:getCoverByFillUnitIndex(fillUnitIndex)
    if cover ~= nil then
        self:setCoverState(cover.index)
    end
    superFunc(self, fillUnitIndex, task)
end
function Cover:aiFinishLoading(superFunc, fillUnitIndex, task)
    if self.spec_cover.hasCovers then
        self:setCoverState(0)
    end
    superFunc(self, fillUnitIndex, task)
end
function Cover:setFillUnitInTriggerRange(superFunc, fillUnitIndex, isInRange)
    superFunc(self, fillUnitIndex, isInRange)
    local spec = self.spec_cover
    local covers = spec.fillUnitIndexToCovers[fillUnitIndex]
    if covers ~= nil then
        if isInRange then
            local isDifferentState = true
            for _, cover in pairs(covers) do
                if isDifferentState then
                    isDifferentState = spec.state ~= cover.index
                end
            end
            local isStateChangedAllowed = self:getIsNextCoverStateAllowed(covers[1].index)
            if covers[1].autoReactToTrigger and (isDifferentState and isStateChangedAllowed) then
                self:setCoverState(covers[1].index, true)
                spec.isStateSetAutomatically = true
                return
            end
        else
            local isDifferentState = spec.covers[spec.state]
            if isDifferentState ~= nil and (spec.isStateSetAutomatically and isDifferentState.autoReactToTrigger) then
                self:setCoverState(0, true)
                spec.isStateSetAutomatically = false
            end
        end
    end
end
function Cover:onFillUnitTriggerChanged(_, _, fillUnitIndex, _)
    local spec = self.spec_cover
    local covers = spec.fillUnitIndexToCovers[fillUnitIndex]
    if covers ~= nil then
        local isDifferentState = true
        for _, cover in pairs(covers) do
            if isDifferentState then
                isDifferentState = spec.state ~= cover.index
            end
        end
        local isStateChangedAllowed = self:getIsNextCoverStateAllowed(covers[1].index)
        if covers[1].autoReactToTrigger and (isDifferentState and isStateChangedAllowed) then
            self:setCoverState(covers[1].index, true)
            spec.isStateSetAutomatically = true
        end
    end
end
function Cover:onRemovedFillUnitTrigger(numTriggers)
    if numTriggers == 0 then
        local cover = self.spec_cover.covers[self.spec_cover.state]
        if cover ~= nil and (spec.isStateSetAutomatically and cover.autoReactToTrigger) then
            self:setCoverState(0, true)
            spec.isStateSetAutomatically = false
        end
    end
end
function Cover:updateActionText()
    local spec = self.spec_cover
    if next(spec.actionEvents) ~= nil then
        local actionEvent = spec.actionEvents[next(spec.actionEvents)]
        if actionEvent ~= nil then
            local text = spec.texts.nextCover
            if spec.state == #spec.covers then
                text = spec.texts.closeCover
            elseif spec.state == 0 then
                text = spec.texts.openCover
            end
            g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
        end
    end
end
function Cover:actionEventToggleCover(_, _, _, _)
    local spec = self.spec_cover
    local newState = spec.state + 1
    local newState = #spec.covers < newState and 0 or newState
    if self:getIsNextCoverStateAllowed(newState) then
        self:setCoverState(newState)
        spec.isStateSetAutomatically = false
    else
        local warning = self:getIsNextCoverStateAllowedWarning(newState)
        if warning ~= nil then
            g_currentMission:showBlinkingWarning(warning, 3000)
        end
    end
end