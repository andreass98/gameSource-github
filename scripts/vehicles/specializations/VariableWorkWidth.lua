source("dataS/scripts/vehicles/specializations/events/VariableWorkWidthStateEvent.lua")
VariableWorkWidth = {}
VariableWorkWidth.SEND_NUM_BITS = 6
source("dataS/scripts/gui/hud/extensions/VariableWorkWidthHUDExtension.lua")
function VariableWorkWidth.prerequisitesPresent(specializations)
    return true
end
function VariableWorkWidth.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("variableWorkWidth", g_i18n:getText("configuration_workingWidth"), "variableWorkWidth", VehicleConfigurationItem)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("VariableWorkWidth")
    VariableWorkWidth.registerSectionPaths(schema, "vehicle.variableWorkWidth")
    VariableWorkWidth.registerSectionPaths(schema, "vehicle.variableWorkWidth.variableWorkWidthConfigurations.variableWorkWidthConfiguration(?)")
    schema:register(XMLValueType.INT, "vehicle.variableWorkWidth#widthReferenceWorkAreaIndex", "Width of this work area is used as reference for the HUD display", 1)
    schema:register(XMLValueType.INT, "vehicle.variableWorkWidth#defaultStateLeft", "Default state on left side", "Max. possible state")
    schema:register(XMLValueType.INT, "vehicle.variableWorkWidth#defaultStateRight", "Default state on right side", "Max. possible state")
    schema:register(XMLValueType.BOOL, "vehicle.variableWorkWidth#aiKeepCurrentWidth", "Defines if the ai should keep the current width or change it", false)
    schema:register(XMLValueType.INT, "vehicle.variableWorkWidth#aiStateLeft", "AI state on left side", "Max. possible state")
    schema:register(XMLValueType.INT, "vehicle.variableWorkWidth#aiStateRight", "AI state on right side", "Max. possible state")
    schema:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_KEY .. ".section#index", "Section index (Section needs to be active to activate workArea)")
    schema:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".section#index", "Section index (Section needs to be active to activate workArea)")
    schema:setXMLSpecializationType()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).variableWorkWidth#leftSide", "Left side section states", "Max. state")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).variableWorkWidth#rightSide", "Right side section states", "Max. state")
end
function VariableWorkWidth.registerSectionPaths(schema, basePath)
    schema:register(XMLValueType.BOOL, basePath .. ".sections.section(?)#isLeft", "Section side", false)
    schema:register(XMLValueType.BOOL, basePath .. ".sections.section(?)#isCenter", "Is center section", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".sections.section(?)#width", "Section max. width as percentage [0..1]", "Automatically calculated")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".sections.section(?)#maxWidthNode", "Position of this node defines max. width of this section")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".sections.section(?).effect(?)#node", "Effect to deactivate/activate")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".sectionNodes.sectionNode(?)#node", "Section node")
    schema:register(XMLValueType.BOOL, basePath .. ".sectionNodes.sectionNode(?)#isLeft", "Section node")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".sectionNodes.sectionNode(?)#minTrans", "Min. translation")
    schema:register(XMLValueType.FLOAT, basePath .. ".sectionNodes.sectionNode(?)#minTransX", "Min. X translation")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".sectionNodes.sectionNode(?)#maxTrans", "Max. translation")
    schema:register(XMLValueType.FLOAT, basePath .. ".sectionNodes.sectionNode(?)#maxTransX", "Max. X translation")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".sectionNodes.sectionNode(?)#minRot", "Min. rotation")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".sectionNodes.sectionNode(?)#endRot", "Max. rotation")
    schema:register(XMLValueType.INT, basePath .. ".sectionNodes.sectionNode(?)#workAreaIndex", "Work area index", 1)
end
function VariableWorkWidth.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onVariableWorkWidthSectionChanged")
end
function VariableWorkWidth.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setVariableWorkWidthActive", VariableWorkWidth.setVariableWorkWidthActive)
    SpecializationUtil.registerFunction(vehicleType, "setSectionsActive", VariableWorkWidth.setSectionsActive)
    SpecializationUtil.registerFunction(vehicleType, "setSectionNodePercentage", VariableWorkWidth.setSectionNodePercentage)
    SpecializationUtil.registerFunction(vehicleType, "updateSections", VariableWorkWidth.updateSections)
    SpecializationUtil.registerFunction(vehicleType, "updateSectionStates", VariableWorkWidth.updateSectionStates)
    SpecializationUtil.registerFunction(vehicleType, "getEffectByNode", VariableWorkWidth.getEffectByNode)
    SpecializationUtil.registerFunction(vehicleType, "getVariableWorkWidth", VariableWorkWidth.getVariableWorkWidth)
    SpecializationUtil.registerFunction(vehicleType, "getVariableWorkWidthUsage", VariableWorkWidth.getVariableWorkWidthUsage)
end
function VariableWorkWidth.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", VariableWorkWidth.loadWorkAreaFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", VariableWorkWidth.getIsWorkAreaActive)
end
function VariableWorkWidth.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", VariableWorkWidth)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", VariableWorkWidth)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", VariableWorkWidth)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", VariableWorkWidth)
    SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerStart", VariableWorkWidth)
    SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStart", VariableWorkWidth)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", VariableWorkWidth)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", VariableWorkWidth)
end
function VariableWorkWidth:onPostLoad(savegame)
    local spec = self.spec_variableWorkWidth
    local configurationId = Utils.getNoNil(self.configurations.variableWorkWidth, 1)
    local configKey = string.format("vehicle.variableWorkWidth.variableWorkWidthConfigurations.variableWorkWidthConfiguration(%d)", configurationId - 1)
    local configKey = not self.xmlFile:hasProperty(configKey) and "vehicle.variableWorkWidth" or configKey
    local function deleteListener(section, effect)
        local i = #section.effects
        for i = i, 1, -1 do
            if section.effects[i] == effect then
                section.effects[i] = nil
                return
            end
        end
    end
    local function startRestriction(section)
        return section.isActive
    end
    spec.hasCenter = false
    spec.sections = {}
    spec.sectionsLeft = {}
    spec.sectionsRight = {}
    self.xmlFile:iterate(configKey .. ".sections.section", function(_, key)
        -- upvalues: (copy) self, (copy) deleteListener, (copy) startRestriction, (copy) spec
        local section = {
            ["isLeft"] = self.xmlFile:getValue(key .. "#isLeft", false),
            ["isCenter"] = self.xmlFile:getValue(key .. "#isCenter", false),
            ["maxWidthNode"] = self.xmlFile:getValue(key .. "#maxWidthNode", nil, self.components, self.i3dMappings),
            ["width"] = self.xmlFile:getValue(key .. "#width"),
            ["effects"] = {}
        }
        self.xmlFile:iterate(key .. ".effect", function(_, effectKey)
            -- upvalues: (ref) self, (ref) deleteListener, (copy) section, (ref) startRestriction
            local effectNode = self.xmlFile:getValue(effectKey .. "#node", nil, self.components, self.i3dMappings)
            if effectNode ~= nil then
                local effect = self:getEffectByNode(effectNode)
                if effect ~= nil then
                    effect:addDeleteListener(deleteListener, section, effect)
                    effect:addStartRestriction(startRestriction, section)
                    table.insert(section.effects, effect)
                end
            end
        end)
        section.isActive = true
        if section.isLeft then
            table.insert(spec.sectionsLeft, section)
        elseif section.isCenter then
            spec.hasCenter = true
        else
            table.insert(spec.sectionsRight, section)
        end
        table.insert(spec.sections, section)
        section.index = #spec.sections
    end)
    spec.sectionNodes = {}
    spec.sectionNodesLeft = {}
    spec.sectionNodesRight = {}
    self.xmlFile:iterate(configKey .. ".sectionNodes.sectionNode", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local sectionNode = {
            ["node"] = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        }
        if sectionNode.node ~= nil then
            sectionNode.isLeft = self.xmlFile:getValue(key .. "#isLeft", false)
            sectionNode.startTrans = self.xmlFile:getValue(key .. "#minTrans", nil, true)
            sectionNode.startTransX = self.xmlFile:getValue(key .. "#minTransX")
            sectionNode.endTrans = self.xmlFile:getValue(key .. "#maxTrans", nil, true)
            sectionNode.endTransX = self.xmlFile:getValue(key .. "#maxTransX")
            sectionNode.startRot = self.xmlFile:getValue(key .. "#minRot", nil, true)
            sectionNode.endRot = self.xmlFile:getValue(key .. "#endRot", nil, true)
            if sectionNode.startTrans == nil and sectionNode.startTransX == nil then
                Logging.xmlWarning(self.xmlFile, "sectionNode \'%s\' needs either \'minTrans\' or \'minTransX\' set", key)
                return
            end
            if sectionNode.endTrans == nil and sectionNode.endTransX == nil then
                Logging.xmlWarning(self.xmlFile, "sectionNode \'%s\' needs either \'maxTrans\' or \'maxTransX\' set", key)
                return
            end
            sectionNode.workAreaIndex = self.xmlFile:getValue(key .. "#workAreaIndex", 1)
            if sectionNode.isLeft then
                table.insert(spec.sectionNodesLeft, sectionNode)
            else
                table.insert(spec.sectionNodesRight, sectionNode)
            end
            table.insert(spec.sectionNodes, sectionNode)
        end
    end)
    local i = 1
    for i = i, #spec.sections do
        local section = spec.sections[i]
        if section.maxWidthNode == nil then
            section.width = 0
        elseif not section.isCenter then
            local j = 1
            for j = j, #spec.sectionNodes do
                local sectionNode = spec.sectionNodes[j]
                if sectionNode.isLeft == section.isLeft then
                    local x, _, _ = localToLocal(section.maxWidthNode, getParent(sectionNode.node), 0, 0, 0)
                    local minX = sectionNode.startTransX or sectionNode.startTrans[1]
                    section.width = math.clamp(math.abs((x - minX) / ((sectionNode.endTransX or sectionNode.endTrans[1]) - minX)), 0, 1)
                    section.widthAbs = x
                    break
                end
            end
        end
        if section.width == nil then
            Logging.xmlWarning(self.xmlFile, "Unable to get width for section \'vehicle.variableWorkWidth.sections.section(%d)\'", i)
            section.width = 0
        end
    end
    table.sort(spec.sectionsLeft, function(a, b)
        return a.width < b.width
    end)
    table.sort(spec.sectionsRight, sort)
    spec.widthReferenceWorkArea = self.xmlFile:getValue("vehicle.variableWorkWidth#widthReferenceWorkAreaIndex", 1)
    spec.leftSideMax = #spec.sectionsLeft
    spec.leftSide = self.xmlFile:getValue("vehicle.variableWorkWidth#defaultStateLeft", spec.leftSideMax)
    spec.rightSideMax = #spec.sectionsRight
    spec.rightSide = self.xmlFile:getValue("vehicle.variableWorkWidth#defaultStateRight", spec.rightSideMax)
    spec.aiKeepCurrentWidth = self.xmlFile:getValue("vehicle.variableWorkWidth#aiKeepCurrentWidth", false)
    spec.aiStateLeft = self.xmlFile:getValue("vehicle.variableWorkWidth#aiStateLeft", spec.leftSideMax)
    spec.aiStateRight = self.xmlFile:getValue("vehicle.variableWorkWidth#aiStateRight", spec.rightSideMax)
    spec.minSideState = spec.hasCenter and 0 or 1
    if savegame ~= nil and not savegame.resetVehicles then
        local i = savegame.xmlFile:getValue(savegame.key .. ".variableWorkWidth#leftSide", spec.leftSide)
        spec.leftSide = math.min(i, spec.leftSideMax)
        local i = savegame.xmlFile:getValue(savegame.key .. ".variableWorkWidth#rightSide", spec.rightSide)
        spec.rightSide = math.min(i, spec.rightSideMax)
    end
    self:updateSections()
    spec.drawInputHelp = false
    spec.hasSections = #spec.sections > 0
    spec.isActive = spec.hasSections
    if spec.hasSections then
        spec.hudExtension = VariableWorkWidthHUDExtension.new(self)
    else
        SpecializationUtil.removeEventListener(self, "onReadStream", VariableWorkWidth)
        SpecializationUtil.removeEventListener(self, "onWriteStream", VariableWorkWidth)
    end
    if not (self.isClient and spec.hasSections) then
        SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", VariableWorkWidth)
    end
end
function VariableWorkWidth:onDelete()
    local spec = self.spec_variableWorkWidth
    if spec.hudExtension ~= nil then
        g_currentMission.hud:removeInfoExtension(spec.hudExtension)
        spec.hudExtension:delete()
    end
end
function VariableWorkWidth:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_variableWorkWidth
    if spec.hasSections then
        xmlFile:setValue(key .. "#leftSide", spec.leftSide)
        xmlFile:setValue(key .. "#rightSide", spec.rightSide)
    end
end
function VariableWorkWidth:onReadStream(streamId, _)
    self:setSectionsActive(streamReadUIntN(streamId, VariableWorkWidth.SEND_NUM_BITS), streamReadUIntN(streamId, VariableWorkWidth.SEND_NUM_BITS), true)
end
function VariableWorkWidth:onWriteStream(streamId, _)
    local spec = self.spec_variableWorkWidth
    streamWriteUIntN(streamId, spec.leftSide, VariableWorkWidth.SEND_NUM_BITS)
    streamWriteUIntN(streamId, spec.rightSide, VariableWorkWidth.SEND_NUM_BITS)
end
function VariableWorkWidth:onDraw()
    local spec = self.spec_variableWorkWidth
    if spec.hudExtension ~= nil and spec.drawInputHelp then
        g_currentMission.hud:addInfoExtension(spec.hudExtension)
    end
end
function VariableWorkWidth:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    local spec = self.spec_variableWorkWidth
    self:clearActionEventsTable(spec.actionEvents)
    if isActiveForInputIgnoreSelection then
        if spec.isActive then
            local _, actionEventIdLeft = self:addActionEvent(spec.actionEvents, InputAction.VARIABLE_WORK_WIDTH_LEFT, self, VariableWorkWidth.actionEventWorkWidthLeft, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventIdLeft, GS_PRIO_HIGH)
            local _, actionEventIdRight = self:addActionEvent(spec.actionEvents, InputAction.VARIABLE_WORK_WIDTH_RIGHT, self, VariableWorkWidth.actionEventWorkWidthRight, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventIdRight, GS_PRIO_HIGH)
            local _, actionEventIdToggle = self:addActionEvent(spec.actionEvents, InputAction.VARIABLE_WORK_WIDTH_TOGGLE, self, VariableWorkWidth.actionEventWorkWidthToggle, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventIdToggle, GS_PRIO_HIGH)
            spec.drawInputHelp = g_inputBinding:getActionEventsHasBinding(actionEventIdLeft) or (g_inputBinding:getActionEventsHasBinding(actionEventIdRight) or g_inputBinding:getActionEventsHasBinding(actionEventIdToggle))
            return
        end
        spec.drawInputHelp = false
    end
end
function VariableWorkWidth:actionEventWorkWidthLeft(_, inputValue, _, _)
    local spec = self.spec_variableWorkWidth
    self:setSectionsActive(spec.leftSide - inputValue, spec.rightSide)
end
function VariableWorkWidth:actionEventWorkWidthRight(_, inputValue, _, _)
    local spec = self.spec_variableWorkWidth
    self:setSectionsActive(spec.leftSide, spec.rightSide - inputValue)
end
function VariableWorkWidth:actionEventWorkWidthToggle(_, _, _, _)
    local spec = self.spec_variableWorkWidth
    local newState = spec.leftSide
    local newState = math.min(newState, spec.rightSide) - 1
    if newState < spec.minSideState then
        newState = math.min(spec.leftSideMax, spec.rightSideMax)
    end
    self:setSectionsActive(newState, newState)
end
function VariableWorkWidth:onAIFieldWorkerStart()
    if self.isServer then
        local spec = self.spec_variableWorkWidth
        if not spec.aiKeepCurrentWidth then
            self:setSectionsActive(spec.aiStateLeft, spec.aiStateRight)
        end
    end
end
function VariableWorkWidth:onAIImplementStart()
    if self.isServer then
        local spec = self.spec_variableWorkWidth
        if not spec.aiKeepCurrentWidth then
            self:setSectionsActive(spec.aiStateLeft, spec.aiStateRight)
        end
    end
end
function VariableWorkWidth:setVariableWorkWidthActive(isActive)
    local spec = self.spec_variableWorkWidth
    spec.isActive = isActive
    if self.isServer and not isActive then
        self:setSectionsActive(spec.leftSideMax, spec.rightSideMax)
    end
    self:requestActionEventUpdate()
end
function VariableWorkWidth:setSectionsActive(leftSide, rightSide, noEventSend)
    local spec = self.spec_variableWorkWidth
    leftSide = math.clamp(leftSide, 0, spec.leftSideMax)
    rightSide = math.clamp(rightSide, 0, spec.rightSideMax)
    if spec.leftSide ~= leftSide or spec.rightSide ~= rightSide then
        spec.leftSide = leftSide
        spec.rightSide = rightSide
        self:updateSections()
        VariableWorkWidthStateEvent.sendEvent(self, spec.leftSide, spec.rightSide, noEventSend)
    end
end
function VariableWorkWidth:setSectionNodePercentage(sectionNodes, percentage)
    percentage = math.max(math.min(percentage, 1), 0)
    local i = 1
    for i = i, #sectionNodes do
        local sectionNode = sectionNodes[i]
        if sectionNode.startTrans ~= nil and sectionNode.endTrans ~= nil then
            setTranslation(sectionNode.node, MathUtil.vector3ArrayLerp(sectionNode.startTrans, sectionNode.endTrans, percentage))
        end
        if sectionNode.startTransX ~= nil and sectionNode.endTransX ~= nil then
            local _, y, z = getTranslation(sectionNode.node)
            local x = MathUtil.lerp(sectionNode.startTransX, sectionNode.endTransX, percentage)
            setTranslation(sectionNode.node, x, y, z)
        end
        if sectionNode.startRot ~= nil and sectionNode.endRot ~= nil then
            setRotation(sectionNode.node, MathUtil.vector3ArrayLerp(sectionNode.startRot, sectionNode.endRot, percentage))
        end
        if sectionNode.workAreaIndex ~= nil then
            self:updateWorkAreaWidth(sectionNode.workAreaIndex)
        end
    end
end
function VariableWorkWidth:updateSections()
    local spec = self.spec_variableWorkWidth
    self:updateSectionStates(spec.sectionsLeft, spec.leftSide)
    self:updateSectionStates(spec.sectionsRight, spec.rightSide)
    self:setSectionNodePercentage(spec.sectionNodesLeft, spec.leftSide == 0 and 0 or spec.sectionsLeft[spec.leftSide].width)
    self:setSectionNodePercentage(spec.sectionNodesRight, spec.rightSide == 0 and 0 or spec.sectionsRight[spec.rightSide].width)
    SpecializationUtil.raiseEvent(self, "onVariableWorkWidthSectionChanged")
end
function VariableWorkWidth.updateSectionStates(_, sections, state)
    local i = 1
    for i = i, #sections do
        local section = sections[i]
        section.isActive = i <= state
        local j = 1
        for j = j, #section.effects do
            local effect = section.effects[j]
            if not section.isActive and effect:isRunning() then
                effect:stop()
            end
        end
    end
end
function VariableWorkWidth:getEffectByNode(node) end
function VariableWorkWidth:getVariableWorkWidth(isLeft)
    local spec = self.spec_variableWorkWidth
    local sections = isLeft and spec.sectionsLeft or spec.sectionsRight
    if #sections == 0 then
        return 1, 1, false
    end
    local maxWidth = nil
    local i = #sections
    for i = i, 1, -1 do
        local section = sections[i]
        maxWidth = maxWidth or section.widthAbs
        if section.isActive then
            return section.widthAbs, maxWidth, true
        end
    end
    return 0, maxWidth or 1, true
end
function VariableWorkWidth:getVariableWorkWidthUsage()
    return nil
end
function VariableWorkWidth:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
    workArea.sectionIndex = xmlFile:getValue(key .. ".section#index")
    return superFunc(self, workArea, xmlFile, key)
end
function VariableWorkWidth:getIsWorkAreaActive(superFunc, workArea)
    if workArea.sectionIndex ~= nil then
        local section = self.spec_variableWorkWidth.sections[workArea.sectionIndex]
        if section ~= nil and not section.isActive then
            return false
        end
    end
    return superFunc(self, workArea)
end