source("dataS/scripts/vehicles/specializations/events/TensionBeltsEvent.lua")
source("dataS/scripts/vehicles/specializations/events/TensionBeltsRefreshEvent.lua")
TensionBelts = {}
TensionBelts.debugRendering = false
TensionBelts.NUM_SEND_BITS = 5
function TensionBelts.prerequisitesPresent(specializations)
    return true
end
function TensionBelts.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("tensionBelts", g_i18n:getText("configuration_tensionBelts"), "tensionBelts", VehicleConfigurationItem)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("TensionBelts")
    schema:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#totalInteractionRadius", "Total interaction radius", 6)
    schema:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#interactionRadius", "Interaction radius", 1)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#interactionBaseNode", "Interaction base node", "Vehicle root node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#activationTrigger", "Activation trigger")
    schema:register(XMLValueType.STRING, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#tensionBeltType", "Supports tension belts", "basic")
    schema:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#width", "Belt width", "Used from belt definitions")
    schema:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#ratchetPosition", "Ratchet position")
    schema:register(XMLValueType.BOOL, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#useHooks", "Use hooks", true)
    schema:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#maxEdgeLength", "Max. edge length", 0.1)
    schema:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#geometryBias", "Geometry bias", 0.01)
    schema:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#defaultOffsetSide", "Default offset side", 0.1)
    schema:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#defaultOffset", "Default offset", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#defaultHeight", "Default height", 5)
    schema:register(XMLValueType.BOOL, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#allowFoldingWhileFasten", "Folding is allowed while tension belts are fasten", true)
    schema:register(XMLValueType.BOOL, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#allowDischargeWhileFasten", "Discharging is allowed while tension belts are fasten", true)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#linkNode", "Link node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#rootNode", "Root node", "Root component")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#jointNode", "Joint node", "rootNode")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.tensionBelt(?)#startNode", "Start node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.tensionBelt(?)#endNode", "End node")
    schema:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.tensionBelt(?)#offsetLeft", "Offset left")
    schema:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.tensionBelt(?)#offsetRight", "Offset right")
    schema:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.tensionBelt(?)#offset", "Offset")
    schema:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.tensionBelt(?)#height", "Height")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.tensionBelt(?)#linkNode", "Custom link node for visual tension belts")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.tensionBelt(?)#jointNode", "Custom joint node for to mount the objects to")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.tensionBelt(?).intersectionNode(?)#node", "Intersection node")
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.tensionBelt(?)")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.sounds", "toggleBelt")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.sounds", "addBelt")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.sounds", "removeBelt")
    schema:addDelayedRegistrationFunc("Cylindered:movingTool", function(cSchema, cKey)
        cSchema:register(XMLValueType.BOOL, cKey .. ".tensionBelts#allowedMounted", "Allow moving tool movement while something is mounted", true)
    end)
    schema:setXMLSpecializationType()
    Vehicle.xmlSchemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).tensionBelts.belt(?)#isActive", "Belt is active", false)
end
function TensionBelts.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "createTensionBelt", TensionBelts.createTensionBelt)
    SpecializationUtil.registerFunction(vehicleType, "removeTensionBelt", TensionBelts.removeTensionBelt)
    SpecializationUtil.registerFunction(vehicleType, "setTensionBeltsActive", TensionBelts.setTensionBeltsActive)
    SpecializationUtil.registerFunction(vehicleType, "setAllTensionBeltsActive", TensionBelts.setAllTensionBeltsActive)
    SpecializationUtil.registerFunction(vehicleType, "objectOverlapCallback", TensionBelts.objectOverlapCallback)
    SpecializationUtil.registerFunction(vehicleType, "getTensionBeltObjectCanBeMounted", TensionBelts.getTensionBeltObjectCanBeMounted)
    SpecializationUtil.registerFunction(vehicleType, "getObjectToMount", TensionBelts.getObjectToMount)
    SpecializationUtil.registerFunction(vehicleType, "getObjectsToUnmount", TensionBelts.getObjectsToUnmount)
    SpecializationUtil.registerFunction(vehicleType, "updateFastenState", TensionBelts.updateFastenState)
    SpecializationUtil.registerFunction(vehicleType, "refreshTensionBelts", TensionBelts.refreshTensionBelts)
    SpecializationUtil.registerFunction(vehicleType, "freeTensionBeltObject", TensionBelts.freeTensionBeltObject)
    SpecializationUtil.registerFunction(vehicleType, "lockTensionBeltObject", TensionBelts.lockTensionBeltObject)
    SpecializationUtil.registerFunction(vehicleType, "getIsPlayerInTensionBeltsRange", TensionBelts.getIsPlayerInTensionBeltsRange)
    SpecializationUtil.registerFunction(vehicleType, "getIsDynamicallyMountedNode", TensionBelts.getIsDynamicallyMountedNode)
    SpecializationUtil.registerFunction(vehicleType, "tensionBeltActivationTriggerCallback", TensionBelts.tensionBeltActivationTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "onTensionBeltTreeShapeCut", TensionBelts.onTensionBeltTreeShapeCut)
end
function TensionBelts.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsReadyForAutomatedTrainTravel", TensionBelts.getIsReadyForAutomatedTrainTravel)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", TensionBelts.getCanBeSelected)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", TensionBelts.getIsFoldAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadMovingToolFromXML", TensionBelts.loadMovingToolFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMovingToolActive", TensionBelts.getIsMovingToolActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanDischargeToGround", TensionBelts.getCanDischargeToGround)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanDischargeToObject", TensionBelts.getCanDischargeToObject)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation", TensionBelts.getFillLevelInformation)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getHasObjectMounted", TensionBelts.getHasObjectMounted)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAdditionalComponentMass", TensionBelts.getAdditionalComponentMass)
end
function TensionBelts.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", TensionBelts)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", TensionBelts)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", TensionBelts)
    SpecializationUtil.registerEventListener(vehicleType, "onPreDelete", TensionBelts)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", TensionBelts)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", TensionBelts)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", TensionBelts)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", TensionBelts)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", TensionBelts)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", TensionBelts)
end
function TensionBelts:onLoad(_)
    local spec = self.spec_tensionBelts
    local tensionBeltConfigurationId = Utils.getNoNil(self.configurations.tensionBelts, 1)
    local configKey = string.format("vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(%d).tensionBelts", tensionBeltConfigurationId - 1)
    spec.hasTensionBelts = true
    if not self.xmlFile:hasProperty(configKey) then
        spec.hasTensionBelts = false
        SpecializationUtil.removeEventListener(self, "onPostLoad", TensionBelts)
        SpecializationUtil.removeEventListener(self, "onDelete", TensionBelts)
        SpecializationUtil.removeEventListener(self, "onPreDelete", TensionBelts)
        SpecializationUtil.removeEventListener(self, "onReadStream", TensionBelts)
        SpecializationUtil.removeEventListener(self, "onWriteStream", TensionBelts)
        SpecializationUtil.removeEventListener(self, "onUpdate", TensionBelts)
        SpecializationUtil.removeEventListener(self, "onUpdateTick", TensionBelts)
        SpecializationUtil.removeEventListener(self, "onDraw", TensionBelts)
        SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", TensionBelts)
        return
    end
    spec.belts = {}
    spec.tensionBelts = {}
    spec.singleBelts = {}
    spec.sortedBelts = {}
    spec.activatable = TensionBeltsActivatable.new(self)
    spec.totalInteractionRadius = self.xmlFile:getValue(configKey .. "#totalInteractionRadius", 6)
    spec.interactionRadius = self.xmlFile:getValue(configKey .. "#interactionRadius", 1)
    spec.interactionBaseNode = self.xmlFile:getValue(configKey .. "#interactionBaseNode", self.rootNode, self.components, self.i3dMappings)
    local activationTrigger = self.xmlFile:getValue(configKey .. "#activationTrigger", nil, self.components, self.i3dMappings)
    if activationTrigger ~= nil then
        if getCollisionFilterGroup(activationTrigger) == CollisionFlag.TRIGGER then
            if getCollisionFilterMask(activationTrigger) == CollisionFlag.PLAYER then
                addTrigger(activationTrigger, "tensionBeltActivationTriggerCallback", self)
                spec.activationTrigger = activationTrigger
            else
                Logging.xmlError(self.xmlFile, "Wrong collision filter mask for tension belt activation trigger \'%s\'. Should only have %s", getName(activationTrigger), CollisionFlag.getBitAndName(CollisionFlag.PLAYER))
            end
        else
            Logging.xmlError(self.xmlFile, "Wrong collision filter group set for tension belt activation trigger \'%s\'. Should only have %s", getName(activationTrigger), CollisionFlag.getBitAndName(CollisionFlag.TRIGGER))
        end
    end
    spec.allowFoldingWhileFasten = self.xmlFile:getValue(configKey .. "#allowFoldingWhileFasten", true)
    spec.allowDischargeWhileFasten = self.xmlFile:getValue(configKey .. "#allowDischargeWhileFasten", true)
    spec.isPlayerInTrigger = false
    spec.checkSizeOffsets = { 0, 2.5, 1.5 }
    spec.objectsInTensionBeltRange = {}
    spec.numObjectsIntensionBeltRange = 0
    local tensionBeltType = self.xmlFile:getValue(configKey .. "#tensionBeltType", "basic")
    local beltData = g_tensionBeltManager:getBeltData(tensionBeltType)
    if beltData == nil then
        Logging.xmlWarning(self.xmlFile, "No belt data found for tension belt type %s", tensionBeltType)
    else
        spec.width = self.xmlFile:getValue(configKey .. "#width")
        spec.ratchetPosition = self.xmlFile:getValue(configKey .. "#ratchetPosition")
        spec.useHooks = self.xmlFile:getValue(configKey .. "#useHooks", true)
        spec.maxEdgeLength = self.xmlFile:getValue(configKey .. "#maxEdgeLength", 0.1)
        spec.geometryBias = self.xmlFile:getValue(configKey .. "#geometryBias", 0.01)
        spec.defaultOffsetSide = self.xmlFile:getValue(configKey .. "#defaultOffsetSide", 0.1)
        spec.defaultOffset = self.xmlFile:getValue(configKey .. "#defaultOffset", 0)
        spec.defaultHeight = self.xmlFile:getValue(configKey .. "#defaultHeight", 5)
        spec.beltData = beltData
        spec.linkNode = self.xmlFile:getValue(configKey .. "#linkNode", nil, self.components, self.i3dMappings)
        spec.rootNode = self.xmlFile:getValue(configKey .. "#rootNode", self.components[1].node, self.components, self.i3dMappings)
        spec.jointNode = self.xmlFile:getValue(configKey .. "#jointNode", spec.rootNode, self.components, self.i3dMappings)
        spec.checkTimerDuration = 500
        spec.checkTimer = spec.checkTimerDuration
        if spec.linkNode == nil then
            Logging.xmlError(self.xmlFile, "No tension belts link node given at %s%s", configKey, "#linkNode")
            self:setLoadingState(VehicleLoadingState.ERROR)
            return
        end
        if getRigidBodyType(spec.jointNode) ~= RigidBodyType.DYNAMIC and getRigidBodyType(spec.jointNode) ~= RigidBodyType.KINEMATIC then
            Logging.xmlError(self.xmlFile, "Given jointNode \'" .. getName(spec.jointNode) .. "\' has invalid rigidBodyType. Have to be \'Dynamic\' or \'Kinematic\'! Using \'" .. getName(self.components[1].node) .. "\' instead!")
            spec.jointNode = self.components[1].node
        end
        local x = getRigidBodyType(spec.jointNode) == RigidBodyType.DYNAMIC
        spec.isDynamic = x
        local x, y, z = localToLocal(spec.linkNode, spec.jointNode, 0, 0, 0)
        local rx, ry, rz = localRotationToLocal(spec.linkNode, spec.jointNode, 0, 0, 0)
        spec.linkNodePosition = { x, y, z }
        spec.linkNodeRotation = { rx, ry, rz }
        spec.jointComponent = self:getParentComponent(spec.jointNode)
        local i = 0
        while true do
            local key = string.format(configKey .. ".tensionBelt(%d)", i)
            if not self.xmlFile:hasProperty(key) then
                break
            end
            if #spec.sortedBelts == 2 ^ TensionBelts.NUM_SEND_BITS then
                Logging.xmlWarning(self.xmlFile, "Max number of tension belts is " .. 2 ^ TensionBelts.NUM_SEND_BITS .. "!")
                break
            end
            local startNode = self.xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)
            local endNode = self.xmlFile:getValue(key .. "#endNode", nil, self.components, self.i3dMappings)
            if startNode ~= nil and endNode ~= nil then
                local endX, endY, _ = getTranslation(endNode)
                if math.abs(endX) < 0.0001 and math.abs(endY) < 0.0001 then
                    if spec.linkNode == nil then
                        spec.linkNode = getParent(startNode)
                    end
                    if spec.startNode == nil then
                        spec.startNode = startNode
                    end
                    spec.endNode = endNode
                    local offsetLeft = self.xmlFile:getValue(key .. "#offsetLeft")
                    local offsetRight = self.xmlFile:getValue(key .. "#offsetRight")
                    local offset = self.xmlFile:getValue(key .. "#offset")
                    local height = self.xmlFile:getValue(key .. "#height")
                    local intersectionNodes = {}
                    local j = 0
                    while true do
                        local intersectionKey = string.format(key .. ".intersectionNode(%d)", j)
                        if not self.xmlFile:hasProperty(intersectionKey) then
                            break
                        end
                        local node = self.xmlFile:getValue(intersectionKey .. "#node", nil, self.components, self.i3dMappings)
                        if node ~= nil then
                            table.insert(intersectionNodes, node)
                        end
                        j = j + 1
                    end
                    local intersectionKey = self.xmlFile:getValue(key .. "#linkNode", nil, self.components, self.i3dMappings)
                    local node = self.xmlFile:getValue(key .. "#jointNode", nil, self.components, self.i3dMappings)
                    local changeObjects = {}
                    ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, key, changeObjects, self.components, self)
                    ObjectChangeUtil.setObjectChanges(changeObjects, false, self, self.setMovingToolDirty)
                    local belt = {
                        ["id"] = i + 1,
                        ["startNode"] = startNode,
                        ["endNode"] = endNode,
                        ["offsetLeft"] = offsetLeft,
                        ["offsetRight"] = offsetRight,
                        ["offset"] = offset,
                        ["height"] = height,
                        ["mesh"] = nil,
                        ["intersectionNodes"] = intersectionNodes,
                        ["changeObjects"] = changeObjects,
                        ["linkNode"] = intersectionKey,
                        ["jointNode"] = node,
                        ["dummy"] = nil,
                        ["objectsToMount"] = nil
                    }
                    spec.singleBelts[belt] = belt
                    table.insert(spec.sortedBelts, belt)
                else
                    Logging.xmlWarning(self.xmlFile, "x and y position of endNode need to be 0 for tension belt \'" .. key .. "\'")
                end
            end
            i = i + 1
        end
        local key = math.huge
        local startNode = math.huge
        local endNode = -math.huge
        local endX = -math.huge
        for offsetRight, offset in pairs(spec.singleBelts) do
            local height, intersectionNodes, j = localToLocal(offset.startNode, spec.interactionBaseNode, 0, 0, 0)
            local intersectionKey, node, changeObjects = localToLocal(offset.endNode, spec.interactionBaseNode, 0, 0, 0)
            key = math.min(key, height, intersectionKey)
            startNode = math.min(startNode, j, changeObjects)
            endNode = math.max(endNode, height, intersectionKey)
            endX = math.max(endX, j, changeObjects)
        end
        spec.interactionBasePointX = (endNode + key) / 2
        spec.interactionBasePointZ = (endX + startNode) / 2
        for offsetRight, offset in pairs(spec.singleBelts) do
            local height, intersectionNodes, j = localToLocal(offset.startNode, spec.interactionBaseNode, 0, 0, 0)
            local intersectionKey = MathUtil.vector2Length(spec.interactionBasePointX - height, spec.interactionBasePointZ - j) + 1
            local node = MathUtil.vector2Length(spec.interactionBasePointX - height, spec.interactionBasePointZ - j) + 1
            spec.totalInteractionRadius = math.max(spec.totalInteractionRadius, intersectionKey, node)
        end
    end
    spec.hasTensionBelts = #spec.sortedBelts > 0
    spec.checkBoxes = {}
    spec.objectsToJoint = {}
    spec.isPlayerInRange = false
    spec.currentBelt = nil
    spec.areAllBeltsFastened = false
    spec.fastenedAllBeltsIndex = -1
    spec.fastenedAllBeltsState = true
    if self.isClient then
        spec.samples = {}
        spec.samples.toggleBelt = g_soundManager:loadSampleFromXML(self.xmlFile, configKey .. ".sounds", "toggleBelt", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.addBelt = g_soundManager:loadSampleFromXML(self.xmlFile, configKey .. ".sounds", "addBelt", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.removeBelt = g_soundManager:loadSampleFromXML(self.xmlFile, configKey .. ".sounds", "removeBelt", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    spec.texts = {}
    spec.texts.warningFoldingTensionBelts = g_i18n:getText("warning_foldingNotWhileTensionBeltsFasten")
    if spec.hasTensionBelts then
        g_messageCenter:subscribe(MessageType.TREE_SHAPE_CUT, self.onTensionBeltTreeShapeCut, self)
    else
        SpecializationUtil.removeEventListener(self, "onPostLoad", TensionBelts)
        SpecializationUtil.removeEventListener(self, "onDelete", TensionBelts)
        SpecializationUtil.removeEventListener(self, "onPreDelete", TensionBelts)
        SpecializationUtil.removeEventListener(self, "onReadStream", TensionBelts)
        SpecializationUtil.removeEventListener(self, "onWriteStream", TensionBelts)
        SpecializationUtil.removeEventListener(self, "onUpdate", TensionBelts)
        SpecializationUtil.removeEventListener(self, "onUpdateTick", TensionBelts)
        SpecializationUtil.removeEventListener(self, "onDraw", TensionBelts)
        SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", TensionBelts)
        if spec.activationTrigger ~= nil then
            removeTrigger(spec.activationTrigger)
            spec.activationTrigger = nil
            return
        end
    end
end
function TensionBelts:onPostLoad(savegame)
    if savegame ~= nil then
        local spec = self.spec_tensionBelts
        spec.beltsToLoad = {}
        local i = 0
        while true do
            local key = string.format("%s.tensionBelts.belt(%d)", savegame.key, i)
            if not savegame.xmlFile:hasProperty(key) then
                break
            end
            if savegame.xmlFile:getValue(key .. "#isActive") then
                table.insert(spec.beltsToLoad, i + 1)
            end
            i = i + 1
        end
    end
end
function TensionBelts:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_tensionBelts
    if spec.hasTensionBelts then
        for i, belt in ipairs(spec.sortedBelts) do
            xmlFile:setValue(string.format("%s.belt(%d)", key, i - 1) .. "#isActive", belt.mesh ~= nil)
        end
    end
end
function TensionBelts:onPreDelete()
    if self.spec_tensionBelts.sortedBelts ~= nil then
        for _, belt in pairs(self.spec_tensionBelts.sortedBelts) do
            local objects, _ = self:getObjectToMount(belt)
            for id, _ in pairs(objects) do
                I3DUtil.wakeUpObject(id)
            end
        end
    end
end
function TensionBelts:onDelete()
    local spec = self.spec_tensionBelts
    spec.isPlayerInRange = false
    g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    self:setTensionBeltsActive(false, nil, true, false)
    if spec.activationTrigger ~= nil then
        removeTrigger(spec.activationTrigger)
        spec.activationTrigger = nil
    end
    g_soundManager:deleteSamples(spec.samples)
end
function TensionBelts:onReadStream(streamId, _)
    local spec = self.spec_tensionBelts
    if spec.tensionBelts ~= nil then
        spec.beltsToLoad = {}
        for k, _ in ipairs(spec.sortedBelts) do
            if streamReadBool(streamId) then
                table.insert(spec.beltsToLoad, k)
            end
        end
    end
end
function TensionBelts:onWriteStream(streamId, _)
    local spec = self.spec_tensionBelts
    if spec.tensionBelts ~= nil then
        for _, belt in ipairs(spec.sortedBelts) do
            streamWriteBool(streamId, belt.mesh ~= nil)
        end
    end
end
function TensionBelts:onUpdate(_, _, _, _)
    local spec = self.spec_tensionBelts
    if spec.beltsToLoad ~= nil then
        if #spec.beltsToLoad > 0 then
            self:setTensionBeltsActive(true, spec.sortedBelts[spec.beltsToLoad[#spec.beltsToLoad]].id, not self.isServer, false)
            table.remove(spec.beltsToLoad, #spec.beltsToLoad)
        else
            spec.beltsToLoad = nil
        end
    end
    if self.isServer and spec.isDynamic then
        local beltIndex, noEventSend, z = localToLocal(spec.linkNode, spec.jointNode, 0, 0, 0)
        local rx, ry, rz = localRotationToLocal(spec.linkNode, spec.jointNode, 0, 0, 0)
        local isDirty = false
        local z = beltIndex - spec.linkNodePosition[1]
        if math.abs(z) <= 0.001 then
            local z = noEventSend - spec.linkNodePosition[2]
            if math.abs(z) <= 0.001 then
                local z = z - spec.linkNodePosition[3]
                if math.abs(z) <= 0.001 then
                    local z = rx - spec.linkNodeRotation[1]
                    if math.abs(z) <= 0.001 then
                        local z = ry - spec.linkNodeRotation[2]
                        if math.abs(z) > 0.001 then
                            goto l11
                        end
                        local z = rz - spec.linkNodeRotation[3]
                        if math.abs(z) > 0.001 then
                            goto l11
                        end
                        ::l16::
                        if isDirty then
                            spec.linkNodePosition[1] = beltIndex
                            spec.linkNodePosition[2] = noEventSend
                            spec.linkNodePosition[3] = z
                            spec.linkNodeRotation[1] = rx
                            spec.linkNodeRotation[2] = ry
                            spec.linkNodeRotation[3] = rz
                            for _, joint in pairs(spec.objectsToJoint) do
                                setJointFrame(joint.jointIndex, 0, joint.jointTransform)
                            end
                        end
                        goto l8
                    end
                end
            end
        end
        ::l11::
        isDirty = true
        goto l16
    else
        ::l8::
        if self.isClient and spec.fastenedAllBeltsIndex > 0 then
            local beltIndex = spec.sortedBelts[spec.fastenedAllBeltsIndex]
            if beltIndex ~= nil then
                self:setTensionBeltsActive(spec.fastenedAllBeltsState, beltIndex.id, false)
            end
            spec.fastenedAllBeltsIndex = spec.fastenedAllBeltsIndex + 1
            if spec.fastenedAllBeltsIndex > #spec.sortedBelts then
                spec.fastenedAllBeltsIndex = -1
            end
        end
        if TensionBelts.debugRendering then
            for rx, ry in pairs(spec.belts) do
                DebugGizmo.renderAtNode(rx, rx.id, false, 0.5)
                local i = 0
                local rz = getNumOfChildren(rx) - 1
                for i = i, rz do
                    DebugGizmo.renderAtNode(getChildAt(rx, i), string.format("%s-%d", rx.id, i), false, 0.2)
                end
            end
            if spec.checkBoxes ~= nil then
                for rx, ry in pairs(spec.checkBoxes) do
                    local rz = ry.points
                    local isDirty = ry.color
                    drawDebugLine(rz[1][1], rz[1][2], rz[1][3], isDirty[1], isDirty[2], isDirty[3], rz[2][1], rz[2][2], rz[2][3], isDirty[1], isDirty[2], isDirty[3])
                    drawDebugLine(rz[2][1], rz[2][2], rz[2][3], isDirty[1], isDirty[2], isDirty[3], rz[3][1], rz[3][2], rz[3][3], isDirty[1], isDirty[2], isDirty[3])
                    drawDebugLine(rz[3][1], rz[3][2], rz[3][3], isDirty[1], isDirty[2], isDirty[3], rz[4][1], rz[4][2], rz[4][3], isDirty[1], isDirty[2], isDirty[3])
                    drawDebugLine(rz[4][1], rz[4][2], rz[4][3], isDirty[1], isDirty[2], isDirty[3], rz[1][1], rz[1][2], rz[1][3], isDirty[1], isDirty[2], isDirty[3])
                    drawDebugLine(rz[5][1], rz[5][2], rz[5][3], isDirty[1], isDirty[2], isDirty[3], rz[6][1], rz[6][2], rz[6][3], isDirty[1], isDirty[2], isDirty[3])
                    drawDebugLine(rz[6][1], rz[6][2], rz[6][3], isDirty[1], isDirty[2], isDirty[3], rz[7][1], rz[7][2], rz[7][3], isDirty[1], isDirty[2], isDirty[3])
                    drawDebugLine(rz[7][1], rz[7][2], rz[7][3], isDirty[1], isDirty[2], isDirty[3], rz[8][1], rz[8][2], rz[8][3], isDirty[1], isDirty[2], isDirty[3])
                    drawDebugLine(rz[8][1], rz[8][2], rz[8][3], isDirty[1], isDirty[2], isDirty[3], rz[5][1], rz[5][2], rz[5][3], isDirty[1], isDirty[2], isDirty[3])
                    drawDebugLine(rz[1][1], rz[1][2], rz[1][3], isDirty[1], isDirty[2], isDirty[3], rz[5][1], rz[5][2], rz[5][3], isDirty[1], isDirty[2], isDirty[3])
                    drawDebugLine(rz[4][1], rz[4][2], rz[4][3], isDirty[1], isDirty[2], isDirty[3], rz[8][1], rz[8][2], rz[8][3], isDirty[1], isDirty[2], isDirty[3])
                    drawDebugLine(rz[2][1], rz[2][2], rz[2][3], isDirty[1], isDirty[2], isDirty[3], rz[6][1], rz[6][2], rz[6][3], isDirty[1], isDirty[2], isDirty[3])
                    drawDebugLine(rz[3][1], rz[3][2], rz[3][3], isDirty[1], isDirty[2], isDirty[3], rz[7][1], rz[7][2], rz[7][3], isDirty[1], isDirty[2], isDirty[3])
                    drawDebugPoint(rz[9][1], rz[9][2], rz[9][3], 1, 1, 1, 1)
                end
            end
            local beltIndex, noEventSend, z = localToWorld(spec.interactionBaseNode, spec.interactionBasePointX, 0, spec.interactionBasePointZ)
            drawDebugPoint(beltIndex, noEventSend, z, 0, 0, 1, 1, false)
            local rz = 0
            local rx = 350
            local ry = 10
            for rz = rz, rx, ry do
                local isDirty = localToWorld
                local i = spec.interactionBaseNode
                local z = spec.interactionBasePointX + math.cos((math.rad(rz))) * spec.totalInteractionRadius
                local isDirty, i, z = isDirty(i, z, 0, spec.interactionBasePointZ + math.sin((math.rad(rz))) * spec.totalInteractionRadius)
                drawDebugPoint(isDirty, i, z, 1, 1, 1, 1)
                for _, belt in pairs(spec.singleBelts) do
                    local isDirty, i, z = localToWorld(belt.startNode, math.cos((math.rad(rz))) * spec.interactionRadius, 0, math.sin((math.rad(rz))) * spec.interactionRadius)
                    drawDebugPoint(isDirty, i, z, 0, 1, 0, 1)
                    local isDirty, i, z = localToWorld(belt.endNode, math.cos((math.rad(rz))) * spec.interactionRadius, 0, math.sin((math.rad(rz))) * spec.interactionRadius)
                    drawDebugPoint(isDirty, i, z, 1, 0, 0, 1)
                end
            end
        end
        if spec.isPlayerInTrigger or spec.isPlayerInRange then
            self:raiseActive()
        end
        local noEventSend = spec.isPlayerInRange
        local z, rx = self:getIsPlayerInTensionBeltsRange()
        spec.isPlayerInRange = z
        if spec.isPlayerInRange then
            if rx ~= spec.currentBelt then
                if spec.currentBelt ~= nil and spec.currentBelt.dummy ~= nil then
                    delete(spec.currentBelt.dummy)
                    spec.currentBelt.dummy = nil
                end
                spec.currentBelt = rx
                if spec.currentBelt ~= nil and spec.currentBelt.mesh == nil then
                    local z, rx = self:getObjectToMount(spec.currentBelt)
                    self:createTensionBelt(spec.currentBelt, true, z)
                end
            end
            g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
            spec.activatable:updateActivateText()
        elseif noEventSend then
            g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
            if spec.currentBelt ~= nil and spec.currentBelt.dummy ~= nil then
                delete(spec.currentBelt.dummy)
                spec.currentBelt.dummy = nil
                spec.currentBelt = nil
            end
        end
    end
end
function TensionBelts:onUpdateTick(dt, _, _, _)
    local spec = self.spec_tensionBelts
    if not spec.hasTensionBelts then
        return
    end
    if self.isServer and spec.tensionBelts ~= nil then
        spec.checkTimer = spec.checkTimer - dt
        if spec.checkTimer < 0 then
            local needUpdate = false
            for phyiscObject, _ in pairs(spec.objectsToJoint) do
                if not entityExists(phyiscObject) then
                    spec.objectsToJoint[phyiscObject] = nil
                    needUpdate = true
                    break
                end
            end
            if needUpdate then
                self:refreshTensionBelts()
            end
            spec.checkTimer = spec.checkTimerDuration
        end
    end
end
function TensionBelts:onDraw(_, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_tensionBelts
    if spec.hasTensionBelts then
        if isActiveForInputIgnoreSelection and isSelected then
            if spec.areAllBeltsFastened then
                g_inputBinding:setActionEventText(self.toggleTensionBeltActionEvent, g_i18n:getText("action_unfastenTensionBelts"))
                return
            end
            g_inputBinding:setActionEventText(self.toggleTensionBeltActionEvent, g_i18n:getText("action_fastenTensionBelts"))
        end
    end
end
function TensionBelts:refreshTensionBelts()
    if self.isServer and g_server ~= nil then
        g_server:broadcastEvent(TensionBeltsRefreshEvent.new(self), nil, nil, self)
    end
    for _, belt in pairs(self.spec_tensionBelts.sortedBelts) do
        if belt.mesh ~= nil then
            self:removeTensionBelt(belt)
            local objects, _ = self:getObjectToMount(belt)
            self:createTensionBelt(belt, false, objects)
        end
    end
end
function TensionBelts:freeTensionBeltObject(objectId, objectsToJointTable, _, object)
    if entityExists(objectId) then
        local jointData = objectsToJointTable[objectId]
        if jointData.jointIndex == nil then
            local parentNode = nil
            if jointData ~= nil then
                parentNode = jointData.parent
            end
            if parentNode == nil or entityExists(parentNode) then
                if parentNode == nil then
                    parentNode = getRootNode()
                end
                local x, y, z = getWorldTranslation(objectId)
                local rx, ry, rz = getWorldRotation(objectId)
                if object == nil or object.unmountKinematic == nil then
                    if self.isServer then
                        link(parentNode, objectId)
                        setWorldTranslation(objectId, x, y, z)
                        setWorldRotation(objectId, rx, ry, rz)
                        setRigidBodyType(objectId, RigidBodyType.DYNAMIC)
                    end
                else
                    object:unmountKinematic()
                end
            else
                delete(objectId)
            end
        elseif self.isServer and jointData ~= nil then
            removeJoint(jointData.jointIndex)
            delete(jointData.jointTransform)
            if getSplitType(objectId) ~= 0 then
                setInertiaScale(objectId, 1, 1, 1)
            end
            if jointData.objectMass ~= nil then
                setMass(objectId, jointData.objectMass)
                self:setMassDirty()
            end
            if object ~= nil then
                if object.setReducedComponentMass ~= nil then
                    object:setReducedComponentMass(false)
                    self:setMassDirty()
                end
                if object.setCanBeSold ~= nil then
                    object:setCanBeSold(true)
                end
                if object.setDynamicMountType ~= nil then
                    object:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE, nil)
                end
            end
        end
        if getSplitType(objectId) ~= 0 then
            setUserAttribute(objectId, "isTensionBeltMounted", UserAttributeType.BOOLEAN, false)
        end
    end
    objectsToJointTable[objectId] = nil
end
function TensionBelts:lockTensionBeltObject(objectId, objectsToJointTable, isDynamic, jointNode, object)
    if objectsToJointTable[objectId] == nil then
        local useDynamicMount = false
        local useSplitShapeMount = false
        if isDynamic or getSplitType(objectId) == 0 then
            useDynamicMount = true
        else
            useSplitShapeMount = true
        end
        if useDynamicMount then
            if self.isServer then
                local constr = JointConstructor.new()
                constr:setActors(jointNode, objectId)
                local jointTransform = createTransformGroup("tensionBeltJoint")
                link(jointNode, jointTransform)
                local x, y, z = localToWorld(objectId, getCenterOfMass(objectId))
                setWorldTranslation(jointTransform, x, y, z)
                constr:setJointTransforms(jointTransform, jointTransform)
                constr:setEnableCollision(true)
                constr:setRotationLimit(0, 0, 0)
                constr:setRotationLimit(1, 0, 0)
                constr:setRotationLimit(2, 0, 0)
                constr:setRotationLimitSpring(1000, 10, 1000, 10, 1000, 10)
                constr:setTranslationLimitSpring(1000, 10, 1000, 10, 1000, 10)
                local jointIndex = constr:finalize()
                local objectMass = nil
                if object == nil then
                    objectMass = getMass(objectId)
                    if objectMass > 0.01 then
                        setMass(objectId, 0.01)
                        self:setMassDirty()
                    else
                        objectMass = nil
                    end
                else
                    if object.setReducedComponentMass ~= nil and object:getAllowComponentMassReduction() then
                        object:setReducedComponentMass(true)
                        self:setMassDirty()
                    end
                    if object.setCanBeSold ~= nil then
                        object:setCanBeSold(false)
                    end
                    if object.setDynamicMountType ~= nil then
                        object:setDynamicMountType(MountableObject.MOUNT_TYPE_DYNAMIC, self)
                    end
                end
                if getSplitType(objectId) ~= 0 then
                    setInertiaScale(objectId, 20, 20, 20)
                end
                objectsToJointTable[objectId] = {
                    ["jointIndex"] = jointIndex,
                    ["jointTransform"] = jointTransform,
                    ["object"] = object,
                    ["objectMass"] = objectMass
                }
            else
                objectsToJointTable[objectId] = {
                    ["jointIndex"] = 0,
                    ["object"] = object
                }
            end
        elseif useSplitShapeMount and self.isServer then
            local constr = getParent(objectId)
            local jointTransform, x, y = localToLocal(objectId, jointNode, 0, 0, 0)
            local z, springForce, springDamping = localRotationToLocal(objectId, jointNode, 0, 0, 0)
            setRigidBodyType(objectId, RigidBodyType.KINEMATIC)
            link(jointNode, objectId)
            setTranslation(objectId, jointTransform, x, y)
            setRotation(objectId, z, springForce, springDamping)
            objectsToJointTable[objectId] = {
                ["parent"] = constr,
                ["object"] = object
            }
        end
        if getSplitType(objectId) ~= 0 then
            setUserAttribute(objectId, "isTensionBeltMounted", UserAttributeType.BOOLEAN, true)
            g_messageCenter:publish(MessageType.TREE_SHAPE_MOUNTED, objectId, self)
        end
    end
end
function TensionBelts:setTensionBeltsActive(isActive, beltId, noEventSend, playSound)
    local spec = self.spec_tensionBelts
    if spec.tensionBelts ~= nil then
        TensionBeltsEvent.sendEvent(self, isActive, beltId, noEventSend)
        local belt = nil
        if beltId ~= nil then
            belt = spec.sortedBelts[beltId]
        end
        if isActive then
            local objects, _ = self:getObjectToMount(belt)
            if belt == nil then
                for _, singleBelt in pairs(spec.singleBelts) do
                    if singleBelt.mesh == nil then
                        self:createTensionBelt(singleBelt, false, objects, playSound)
                    end
                end
            elseif belt.mesh == nil then
                self:createTensionBelt(belt, false, objects, playSound)
            end
            for _, singleBelt in pairs(objects) do
                self:lockTensionBeltObject(singleBelt.physics, spec.objectsToJoint, spec.isDynamic, belt.jointNode or spec.jointNode, singleBelt.object)
                if singleBelt.object ~= nil then
                    singleBelt.object.tensionMountObject = self
                end
            end
        else
            if belt == nil then
                for _, singleBelt in pairs(spec.singleBelts) do
                    self:removeTensionBelt(singleBelt, playSound)
                end
            else
                self:removeTensionBelt(belt, playSound)
            end
            local objects, _ = self:getObjectsToUnmount(belt)
            for _, singleBelt in pairs(objects) do
                self:freeTensionBeltObject(_, spec.objectsToJoint, spec.isDynamic, singleBelt.object)
                if singleBelt.object ~= nil then
                    singleBelt.object.tensionMountObject = nil
                end
            end
        end
        if belt ~= nil then
            ObjectChangeUtil.setObjectChanges(belt.changeObjects, isActive, self, self.setMovingToolDirty)
        end
        self:updateFastenState()
    end
end
function TensionBelts:setAllTensionBeltsActive(isActive, noEventSend)
    local spec = self.spec_tensionBelts
    if spec.hasTensionBelts then
        isActive = Utils.getNoNil(isActive, not spec.areAllBeltsFastened)
        for _, belt in pairs(spec.sortedBelts) do
            self:setTensionBeltsActive(isActive, belt.id, noEventSend)
        end
    end
end
function TensionBelts:updateFastenState()
    local spec = self.spec_tensionBelts
    local hasUnfastenedBelts = false
    for _, belt in pairs(spec.singleBelts) do
        if belt.mesh == nil then
            hasUnfastenedBelts = true
            break
        end
    end
    spec.areAllBeltsFastened = not hasUnfastenedBelts
end
function TensionBelts:createTensionBelt(belt, isDummy, objects, playSound)
    local spec = self.spec_tensionBelts
    local tensionBelt = TensionBeltGeometryConstructor.new()
    local beltData = spec.beltData
    local scale = spec.width or beltData.width
    tensionBelt:setWidth(scale)
    tensionBelt:setMaxEdgeLength(spec.maxEdgeLength)
    if isDummy then
        tensionBelt:setMaterial(beltData.dummyMaterial.materialId)
        tensionBelt:setUVscale(beltData.dummyMaterial.uvScale)
    else
        tensionBelt:setMaterial(beltData.material.materialId)
        tensionBelt:setUVscale(beltData.material.uvScale)
    end
    local ratchetStart = 0
    local ratchetEnd = 0
    if spec.ratchetPosition ~= nil and beltData.ratchet ~= nil then
        ratchetStart = spec.ratchetPosition
        ratchetEnd = spec.ratchetPosition + beltData.ratchet.sizeRatio * scale
        tensionBelt:addAttachment(0, spec.ratchetPosition, beltData.ratchet.sizeRatio * scale)
    end
    local hookLength1 = 0
    local hookLength2 = 0
    if spec.useHooks and beltData.hook ~= nil then
        tensionBelt:addAttachment(0, beltData.hook.sizeRatio * scale, 0)
        tensionBelt:addAttachment(1, -((beltData.hook2 or beltData.hook).sizeRatio * scale), 0)
    end
    tensionBelt:setFixedPoints(belt.startNode, belt.endNode)
    tensionBelt:setGeometryBias(spec.geometryBias)
    tensionBelt:setLinkNode(belt.linkNode or spec.linkNode)
    for _, pointNode in pairs(belt.intersectionNodes) do
        local x, y, z = getWorldTranslation(pointNode)
        local dirX, dirY, dirZ = localDirectionToWorld(pointNode, 1, 0, 0)
        tensionBelt:addIntersectionPoint(x, y, z, dirX, dirY, dirZ)
    end
    for _, pointNode in pairs(objects) do
        for dirX, dirY in pairs(pointNode.visuals) do
            if getSplitType(dirY) == 0 then
                tensionBelt:addShape(dirY, 0, 10, 0, 10)
            else
                tensionBelt:addShape(dirY, -100, 100, -100, 100)
            end
        end
    end
    local beltShape, _, beltLength = tensionBelt:finalize()
    if beltShape == 0 then
        return nil
    end
    if isDummy then
        belt.dummy = beltShape
        return beltShape
    end
    local _ = 0
    if spec.ratchetPosition ~= nil and (beltData.ratchet ~= nil and _ < getNumOfChildren(beltShape)) then
        local pointNode = clone(beltData.ratchet.node, false, false, false)
        link(getChildAt(beltShape, 0), pointNode)
        setTranslation(pointNode, 0, spec.geometryBias, 0)
        setScale(pointNode, scale, scale, scale)
    end
    if spec.useHooks and (beltData.hook ~= nil and getNumOfChildren(beltShape) > _ + 1) then
        local pointNode = clone(beltData.hook.node, false, false, false)
        link(getChildAt(beltShape, _), pointNode)
        local x = spec.geometryBias * math.min(hookLength1 / spec.maxEdgeLength, 1)
        setTranslation(pointNode, 0, x, 0)
        local y, z, dirX = getWorldTranslation(belt.startNode)
        local dirY, dirZ, wz2 = getWorldTranslation(pointNode)
        local dx, dy, dz = worldDirectionToLocal(getParent(pointNode), y - dirY, z - dirZ, dirX - wz2)
        local upX, upY, upZ = localDirectionToLocal(pointNode, getParent(pointNode), 0, 1, 0)
        setDirection(pointNode, dx, dy, dz, upX, upY, upZ)
        setScale(pointNode, scale, scale, scale)
        local hookEnd = clone((beltData.hook2 or beltData.hook).node, false, false, false)
        link(getChildAt(beltShape, _ + 1), hookEnd)
        local x = spec.geometryBias * math.min(hookLength2 / spec.maxEdgeLength, 1)
        setTranslation(hookEnd, 0, x, 0)
        local y, z, dirX = getWorldTranslation(belt.endNode)
        local dirY, dirZ, wz2 = getWorldTranslation(hookEnd)
        local dx, dy, dz = worldDirectionToLocal(getParent(hookEnd), y - dirY, z - dirZ, dirX - wz2)
        local upX, upY, upZ = localDirectionToLocal(hookEnd, getParent(hookEnd), 0, 1, 0)
        setDirection(hookEnd, dx, dy, dz, upX, upY, upZ)
        setScale(hookEnd, scale, scale, scale)
    end
    setShaderParameter(beltShape, "beltClipOffsets", hookLength1, ratchetStart, ratchetEnd, beltLength - hookLength2, false)
    belt.mesh = beltShape
    spec.belts[beltShape] = beltShape
    if belt.dummy ~= nil then
        delete(belt.dummy)
        belt.dummy = nil
    end
    if playSound ~= false and self.isClient then
        g_soundManager:playSample(spec.samples.toggleBelt)
        g_soundManager:playSample(spec.samples.addBelt)
    end
    return beltShape
end
function TensionBelts:removeTensionBelt(belt, playSound)
    if belt.mesh ~= nil then
        local spec = self.spec_tensionBelts
        spec.belts[belt.mesh] = nil
        delete(belt.mesh)
        belt.mesh = nil
        if spec.currentBelt == belt then
            spec.currentBelt = nil
        end
        if belt.dummy == nil and (playSound ~= false and self.isClient) then
            g_soundManager:playSample(spec.samples.toggleBelt)
            g_soundManager:playSample(spec.samples.removeBelt)
        end
    end
end
function TensionBelts:getObjectToMount(belt)
    local spec = self.spec_tensionBelts
    local markerStart = spec.startNode
    local markerEnd = spec.endNode
    local offsetLeft = nil
    local offsetRight = nil
    local offset = nil
    local height = nil
    if belt ~= nil then
        markerEnd = belt.endNode
        offsetLeft = belt.offsetLeft
        offsetRight = belt.offsetRight
        offset = belt.offset
        height = belt.height
        if offsetLeft == nil and (spec.sortedBelts[belt.id - 1] ~= nil and spec.sortedBelts[belt.id - 1].mesh ~= nil) then
            local x, _, _ = localToLocal(belt.startNode, spec.sortedBelts[belt.id - 1].startNode, 0, 0, 0)
            offsetLeft = math.abs(x)
        end
        if offsetRight == nil and (spec.sortedBelts[belt.id + 1] ~= nil and spec.sortedBelts[belt.id + 1].mesh ~= nil) then
            local x, _, _ = localToLocal(markerStart, spec.sortedBelts[belt.id + 1].startNode, 0, 0, 0)
            offsetRight = math.abs(x)
        end
    end
    if offsetLeft == nil then
        offsetLeft = spec.defaultOffsetSide
    end
    if offsetRight == nil then
        offsetRight = spec.defaultOffsetSide
    end
    if offset == nil then
        offset = spec.defaultOffset
    end
    if height == nil then
        height = spec.defaultHeight
    end
    local x = (offsetLeft + offsetRight) * 0.5
    local _ = height * 0.5
    local _, _, width = localToLocal(markerEnd, markerStart, 0, 0, 0)
    local sizeZ = width * 0.5 - 2 * offset
    local centerX = (offsetLeft - offsetRight) * 0.5
    local centerY = height * 0.5
    local centerZ = width * 0.5
    local x, y, z = localToWorld(markerStart, centerX, centerY, centerZ)
    if TensionBelts.debugRendering then
        local box = {
            ["points"] = {},
            ["color"] = { math.random(0, 1), math.random(0, 1), (math.random(0, 1)) }
        }
        local blx, bly, blz = localToWorld(markerStart, centerX - x, centerY - _, centerZ - sizeZ)
        local brx, bry, brz = localToWorld(markerStart, centerX + x, centerY - _, centerZ - sizeZ)
        local flx, fly, flz = localToWorld(markerStart, centerX - x, centerY - _, centerZ + sizeZ)
        local frx, fry, frz = localToWorld(markerStart, centerX + x, centerY - _, centerZ + sizeZ)
        local tblx, tbly, tblz = localToWorld(markerStart, centerX - x, centerY + _, centerZ - sizeZ)
        local tbrx, tbry, tbrz = localToWorld(markerStart, centerX + x, centerY + _, centerZ - sizeZ)
        local tflx, tfly, tflz = localToWorld(markerStart, centerX - x, centerY + _, centerZ + sizeZ)
        local tfrx, tfry, tfrz = localToWorld(markerStart, centerX + x, centerY + _, centerZ + sizeZ)
        table.insert(box.points, { blx, bly, blz })
        table.insert(box.points, { brx, bry, brz })
        table.insert(box.points, { frx, fry, frz })
        table.insert(box.points, { flx, fly, flz })
        table.insert(box.points, { tblx, tbly, tblz })
        table.insert(box.points, { tbrx, tbry, tbrz })
        table.insert(box.points, { tfrx, tfry, tfrz })
        table.insert(box.points, { tflx, tfly, tflz })
        table.insert(box.points, { x, y, z })
        spec.checkBoxes[markerStart] = box
    end
    local box, colorR, colorG = getWorldRotation(markerStart)
    table.clear(spec.objectsInTensionBeltRange)
    spec.numObjectsIntensionBeltRange = 0
    overlapBox(x, y, z, box, colorR, colorG, x, _, sizeZ, "objectOverlapCallback", self, CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.TREE, true, true, false, true)
    return spec.objectsInTensionBeltRange, spec.numObjectsIntensionBeltRange
end
function TensionBelts:getObjectsToUnmount(belt)
    local spec = self.spec_tensionBelts
    local objectIdsToUnmount = {}
    local numObjects = 0
    for objectId, data in pairs(spec.objectsToJoint) do
        objectIdsToUnmount[objectId] = {
            ["objectId"] = objectId,
            ["object"] = data.object
        }
    end
    for objectId, data in pairs(spec.singleBelts) do
        if data.mesh ~= nil and data ~= belt then
            local objectToMount, _ = self:getObjectToMount(data)
            for _, object in pairs(objectToMount) do
                if objectIdsToUnmount[object.physics] ~= nil then
                    objectIdsToUnmount[object.physics] = nil
                end
            end
        end
    end
    return objectIdsToUnmount, numObjects
end
function TensionBelts:objectOverlapCallback(transformId)
    if transformId ~= 0 and getHasClassId(transformId, ClassIds.SHAPE) then
        local object = g_currentMission:getNodeObject(transformId)
        if object == nil then
            if getSplitType(transformId) ~= 0 then
                local nodeId = getRigidBodyType(transformId)
                if (nodeId == RigidBodyType.DYNAMIC or nodeId == RigidBodyType.KINEMATIC) and self.spec_tensionBelts.objectsInTensionBeltRange[transformId] == nil then
                    spec.objectsInTensionBeltRange[transformId] = {
                        ["physics"] = transformId,
                        ["visuals"] = { transformId }
                    }
                    spec.numObjectsIntensionBeltRange = spec.numObjectsIntensionBeltRange + 1
                end
            end
        elseif self:getTensionBeltObjectCanBeMounted(object) then
            local nodeId = object:getTensionBeltNodeId()
            if spec.objectsInTensionBeltRange[nodeId] == nil then
                local nodes = object:getMeshNodes()
                if nodes ~= nil then
                    spec.objectsInTensionBeltRange[nodeId] = {
                        ["physics"] = nodeId,
                        ["visuals"] = nodes,
                        ["object"] = object
                    }
                    spec.numObjectsIntensionBeltRange = spec.numObjectsIntensionBeltRange + 1
                end
            end
        end
    end
    return true
end
function TensionBelts:getTensionBeltObjectCanBeMounted(object)
    if object == self then
        return false
    end
    if object.rootVehicle == self.rootVehicle then
        return false
    end
    if object.getSupportsTensionBelts == nil or not object:getSupportsTensionBelts() then
        return false
    end
    if object.getMeshNodes == nil then
        return false
    end
    if object.dynamicMountObject ~= nil then
        return false
    end
    local hasObjectMounted = false
    for _, objectData in pairs(self.spec_tensionBelts.objectsToJoint) do
        if objectData.object ~= nil and objectData.object == object then
            hasObjectMounted = true
        end
    end
    if not hasObjectMounted then
        if object.rootVehicle ~= nil and object.rootVehicle:getHasObjectMounted(self) then
            return false
        end
        if self.rootVehicle:getHasObjectMounted(object) then
            return false
        end
    end
    return true
end
function TensionBelts:getIsPlayerInTensionBeltsRange()
    if g_localPlayer == nil then
        return false, nil
    end
    if not g_currentMission.accessHandler:canPlayerAccess(self) then
        return false, nil
    end
    local spec = self.spec_tensionBelts
    if spec.beltData ~= nil then
        local px, py, pz = getWorldTranslation(g_localPlayer.rootNode)
        local vx, vy, vz = localToWorld(spec.interactionBaseNode, spec.interactionBasePointX, 0, spec.interactionBasePointZ)
        local currentBelt = nil
        local distance = math.huge
        if MathUtil.vector3Length(px - vx, py - vy, pz - vz) < spec.totalInteractionRadius then
            if spec.tensionBelts ~= nil then
                for _, belt in pairs(spec.singleBelts) do
                    local sx, _, sz = getWorldTranslation(belt.startNode)
                    local ex, _, ez = getWorldTranslation(belt.endNode)
                    local sDistance = MathUtil.vector2Length(px - sx, pz - sz)
                    local eDistance = MathUtil.vector2Length(px - ex, pz - ez)
                    if sDistance < distance and sDistance < spec.interactionRadius or eDistance < distance and eDistance < spec.interactionRadius then
                        distance = math.min(sDistance, eDistance)
                        currentBelt = belt
                    end
                end
            end
            if distance < spec.interactionRadius then
                return true, currentBelt
            end
        end
    end
    return false, nil
end
function TensionBelts:getIsDynamicallyMountedNode(node)
    local spec = self.spec_tensionBelts
    if spec.objectsToJoint ~= nil then
        for object, _ in pairs(spec.objectsToJoint) do
            if object == node then
                return true
            end
        end
    end
    return false
end
function TensionBelts:getIsReadyForAutomatedTrainTravel(superFunc)
    local spec = self.spec_tensionBelts
    if spec.hasTensionBelts and spec.numObjectsIntensionBeltRange > 0 then
        return false
    else
        return superFunc(self)
    end
end
function TensionBelts:getCanBeSelected(superFunc)
    return true
end
function TensionBelts:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
    local spec = self.spec_tensionBelts
    if spec.hasTensionBelts and (not spec.allowFoldingWhileFasten and ((direction or 1) >= 0 and spec.areAllBeltsFastened)) then
        return false, spec.texts.warningFoldingTensionBelts
    else
        return superFunc(self, direction, onAiTurnOn)
    end
end
function TensionBelts:loadMovingToolFromXML(superFunc, xmlFile, key, entry)
    if not superFunc(self, xmlFile, key, entry) then
        return false
    end
    entry.tensionBeltsAllowedMounted = xmlFile:getValue(key .. ".tensionBelts#allowedMounted", true)
    return true
end
function TensionBelts:getIsMovingToolActive(superFunc, movingTool)
    if not movingTool.tensionBeltsAllowedMounted then
        local spec = self.spec_tensionBelts
        if spec.hasTensionBelts and spec.areAllBeltsFastened then
            return false
        end
    end
    return superFunc(self, movingTool)
end
function TensionBelts:getCanDischargeToGround(superFunc, dischargeNode)
    local spec = self.spec_tensionBelts
    if spec.hasTensionBelts and (not spec.allowDischargeWhileFasten and spec.areAllBeltsFastened) then
        return false
    else
        return superFunc(self, dischargeNode)
    end
end
function TensionBelts:getCanDischargeToObject(superFunc, dischargeNode)
    local spec = self.spec_tensionBelts
    if spec.hasTensionBelts and (not spec.allowDischargeWhileFasten and spec.areAllBeltsFastened) then
        return false
    else
        return superFunc(self, dischargeNode)
    end
end
function TensionBelts:getFillLevelInformation(superFunc, display)
    superFunc(self, display)
    local spec = self.spec_tensionBelts
    if spec.hasTensionBelts then
        for _, objectData in pairs(spec.objectsToJoint) do
            local object = objectData.object
            if object ~= nil then
                if object.getFillLevelInformation == nil then
                    if object.getFillLevel ~= nil and object.getFillType ~= nil then
                        local fillType = object:getFillType()
                        local fillLevel = object:getFillLevel()
                        local capacity
                        if object.getCapacity == nil then
                            capacity = fillLevel
                        else
                            capacity = object:getCapacity()
                        end
                        display:addFillLevel(fillType, fillLevel, capacity)
                    end
                else
                    object:getFillLevelInformation(display)
                end
            end
        end
    end
end
function TensionBelts:getHasObjectMounted(superFunc, object)
    if superFunc(self, object) then
        return true
    end
    local spec = self.spec_tensionBelts
    if spec.hasTensionBelts then
        for _, objectData in pairs(spec.objectsToJoint) do
            if objectData.object ~= nil then
                if objectData.object == object then
                    return true
                end
                if objectData.object.getHasObjectMounted ~= nil and objectData.object:getHasObjectMounted(object) then
                    return true
                end
            end
        end
    end
    return false
end
function TensionBelts:getAdditionalComponentMass(superFunc, component)
    local additionalMass = superFunc(self, component)
    local spec = self.spec_tensionBelts
    if spec.hasTensionBelts and spec.jointComponent == component.node then
        for _, objectData in pairs(spec.objectsToJoint) do
            local object = objectData.object
            if object ~= nil and (object.getAllowComponentMassReduction ~= nil and object:getAllowComponentMassReduction()) then
                additionalMass = additionalMass + math.max(object:getDefaultMass() - 0.1, 0)
            end
            if objectData.objectMass ~= nil then
            end
        end
    end
    return additionalMass
end
function TensionBelts:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    local spec = self.spec_tensionBelts
    if self.isClient and spec.hasTensionBelts then
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_TENSION_BELTS, self, TensionBelts.actionEventToggleTensionBelts, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            self.toggleTensionBeltActionEvent = actionEventId
        end
    end
end
function TensionBelts:tensionBeltActivationTriggerCallback(_, otherActorId, onEnter, onLeave, _, _)
    local spec = self.spec_tensionBelts
    if self.isClient and (spec.hasTensionBelts and (onEnter or onLeave)) and (g_localPlayer ~= nil and otherActorId == g_localPlayer.rootNode) then
        if onEnter then
            self:raiseActive()
            spec.isPlayerInTrigger = true
            return
        end
        spec.isPlayerInTrigger = false
    end
end
function TensionBelts:onTensionBeltTreeShapeCut(oldShape, _)
    if self.isServer then
        for objectId, data in pairs(self.spec_tensionBelts.objectsToJoint) do
            if objectId == oldShape then
                self:setAllTensionBeltsActive(false)
            end
        end
    end
end
TensionBeltsActivatable = {}
local TensionBeltsActivatable_mt = Class(TensionBeltsActivatable)
function TensionBeltsActivatable.new(object)
    -- upvalues: (copy) TensionBeltsActivatable_mt
    local self = setmetatable({}, TensionBeltsActivatable_mt)
    self.object = object
    self.spec = object.spec_tensionBelts
    self.activateText = g_i18n:getText("action_fastenTensionBelt")
    return self
end
function TensionBeltsActivatable:getIsActivatable()
    return self.spec.isPlayerInRange
end
function TensionBeltsActivatable:getDistance(_, _, _)
    return self.spec.currentBelt == nil and math.huge or 0
end
function TensionBeltsActivatable:run()
    if self.spec.currentBelt ~= nil then
        if self.spec.currentBelt.mesh == nil then
            self.object:setTensionBeltsActive(true, self.spec.currentBelt.id, false)
        else
            self.object:setTensionBeltsActive(false, self.spec.currentBelt.id, false)
        end
    end
    self:updateActivateText()
end
function TensionBeltsActivatable:updateActivateText()
    if self.spec.currentBelt == nil or self.spec.currentBelt.mesh == nil then
        self.activateText = g_i18n:getText("action_fastenTensionBelt")
    else
        self.activateText = g_i18n:getText("action_unfastenTensionBelt")
    end
end
function TensionBelts:actionEventToggleTensionBelts(_, _, _, _)
    local spec = self.spec_tensionBelts
    spec.fastenedAllBeltsIndex = 1
    spec.fastenedAllBeltsState = not spec.areAllBeltsFastened
end
function TensionBelts.consoleCommandToggleTensionBeltDebugRendering(unusedSelf)
    TensionBelts.debugRendering = not TensionBelts.debugRendering
    return "TensionBeltsDebugRendering = " .. tostring(TensionBelts.debugRendering)
end
addConsoleCommand("gsTensionBeltDebug", "Toggles the debug tension belt rendering of the vehicle", "TensionBelts.consoleCommandToggleTensionBeltDebugRendering", nil)