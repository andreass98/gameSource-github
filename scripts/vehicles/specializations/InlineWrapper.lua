InlineWrapper = {}
InlineWrapper.INTERACTION_RADIUS = 5
InlineWrapper.CONSUMABLE_TYPE_NAME = "BALE_WRAP"
source("dataS/scripts/vehicles/specializations/events/InlineWrapperPushOffEvent.lua")
function InlineWrapper.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Foldable, specializations) and SpecializationUtil.hasSpecialization(Consumable, specializations)
end
function InlineWrapper.initSpecialization()
    g_storeManager:addSpecType("inlineWrapperBaleSizeRound", "shopListAttributeIconBaleWrapperBaleSizeRound", InlineWrapper.loadSpecValueBaleSizeRound, InlineWrapper.getSpecValueBaleSizeRound, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("inlineWrapperBaleSizeSquare", "shopListAttributeIconBaleWrapperBaleSizeSquare", InlineWrapper.loadSpecValueBaleSizeSquare, InlineWrapper.getSpecValueBaleSizeSquare, StoreSpecies.VEHICLE)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("InlineWrapper")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.baleTrigger#node", "Bale pickup trigger")
    schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTrigger#minFoldTime", "Min. folding time for bale pickup", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTrigger#maxFoldTime", "Max. folding time for bale pickup", 1)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.wrapTrigger#node", "Wrap trigger")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.baleTypes.baleType(?)#startNode", "Start placement node for bale")
    schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTypes.baleType(?)#wrapUsage", "Usage of wrap rolls per minute", 0.1)
    schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTypes.baleType(?).railing#width", "Railing width to set")
    schema:register(XMLValueType.STRING, "vehicle.inlineWrapper.baleTypes.baleType(?).inlineBale#filename", "Path to inline bale xml file")
    schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTypes.baleType(?).size#diameter", "Bale diameter")
    schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTypes.baleType(?).size#width", "Bale width")
    schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTypes.baleType(?).size#height", "Bale height")
    schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTypes.baleType(?).size#length", "Bale length")
    schema:register(XMLValueType.STRING, "vehicle.inlineWrapper.railings#animation", "Railing animation")
    schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.railings#animStartX", "Railing width at start of animation")
    schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.railings#animEndX", "Railing width at end of animation")
    schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.railings#defaultX", "Default railing width", 1)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.wrapping#startNode", "Reference node for wrapping state of bale")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.steeringNodes.steeringNode(?)#node", "Steering node that is aligned to the start wrapping direction")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.wrappingNodes.wrappingNode(?)#node", "Wrapping node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.wrappingNodes.wrappingNode(?)#target", "Target node that is aligned to the bale")
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.inlineWrapper.wrappingNodes.wrappingNode(?)#startTrans", "Start translation")
    schema:register(XMLValueType.STRING, "vehicle.inlineWrapper.animations#pusher", "Pusher animation", "pusherAnimation")
    schema:register(XMLValueType.STRING, "vehicle.inlineWrapper.animations#wrapping", "Wrapping animation", "wrappingAnimation")
    schema:register(XMLValueType.STRING, "vehicle.inlineWrapper.animations#pushOff", "Push bale off animation", "pushOffAnimation")
    schema:register(XMLValueType.STRING, "vehicle.inlineWrapper.pushing#brakeForce", "Brake force while pushing", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.pushing#openBrakeTime", "Pusher animation time to open brake", 0.1)
    schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.pushing#closeBrakeTime", "Pusher animation time to close brake", 0.5)
    schema:register(XMLValueType.INT, "vehicle.inlineWrapper.pushing#minBaleAmount", "Min. bales wrapped to open brake", 4)
    schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper#baleMovedThreshold", "Bale moved threshold for starting wrapping animation", 0.05)
    schema:register(XMLValueType.INT, "vehicle.inlineWrapper#numObjectBits", "Num bits for sending bales", 4)
    SoundManager.registerSampleXMLPaths(schema, "vehicle.inlineWrapper.sounds", "wrap")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.inlineWrapper.sounds", "start")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.inlineWrapper.sounds", "stop")
    schema:setXMLSpecializationType()
end
function InlineWrapper.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "readInlineBales", InlineWrapper.readInlineBales)
    SpecializationUtil.registerFunction(vehicleType, "writeInlineBales", InlineWrapper.writeInlineBales)
    SpecializationUtil.registerFunction(vehicleType, "getIsInlineBalingAllowed", InlineWrapper.getIsInlineBalingAllowed)
    SpecializationUtil.registerFunction(vehicleType, "inlineBaleTriggerCallback", InlineWrapper.inlineBaleTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "inlineWrapTriggerCallback", InlineWrapper.inlineWrapTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "updateWrappingNodes", InlineWrapper.updateWrappingNodes)
    SpecializationUtil.registerFunction(vehicleType, "updateRoundBaleWrappingNode", InlineWrapper.updateRoundBaleWrappingNode)
    SpecializationUtil.registerFunction(vehicleType, "updateSquareBaleWrappingNode", InlineWrapper.updateSquareBaleWrappingNode)
    SpecializationUtil.registerFunction(vehicleType, "getWrapperBaleType", InlineWrapper.getWrapperBaleType)
    SpecializationUtil.registerFunction(vehicleType, "getAllowBalePushing", InlineWrapper.getAllowBalePushing)
    SpecializationUtil.registerFunction(vehicleType, "updateWrapperRailings", InlineWrapper.updateWrapperRailings)
    SpecializationUtil.registerFunction(vehicleType, "updateInlineSteeringWheels", InlineWrapper.updateInlineSteeringWheels)
    SpecializationUtil.registerFunction(vehicleType, "getCanInteract", InlineWrapper.getCanInteract)
    SpecializationUtil.registerFunction(vehicleType, "getCanPushOff", InlineWrapper.getCanPushOff)
    SpecializationUtil.registerFunction(vehicleType, "setCurrentInlineBale", InlineWrapper.setCurrentInlineBale)
    SpecializationUtil.registerFunction(vehicleType, "getCurrentInlineBale", InlineWrapper.getCurrentInlineBale)
    SpecializationUtil.registerFunction(vehicleType, "pushOffInlineBale", InlineWrapper.pushOffInlineBale)
end
function InlineWrapper.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", InlineWrapper.getIsFoldAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActive", InlineWrapper.getIsActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getBrakeForce", InlineWrapper.getBrakeForce)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShowConsumableEmptyWarning", InlineWrapper.getShowConsumableEmptyWarning)
end
function InlineWrapper.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", InlineWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", InlineWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", InlineWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", InlineWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", InlineWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", InlineWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", InlineWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", InlineWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", InlineWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", InlineWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", InlineWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", InlineWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", InlineWrapper)
    SpecializationUtil.registerEventListener(vehicleType, "onConsumableVariationChanged", InlineWrapper)
end
function InlineWrapper:onLoad(_)
    local spec = self.spec_inlineWrapper
    spec.triggerNode = self.xmlFile:getValue("vehicle.inlineWrapper.baleTrigger#node", nil, self.components, self.i3dMappings)
    if spec.triggerNode ~= nil then
        addTrigger(spec.triggerNode, "inlineBaleTriggerCallback", self)
    end
    spec.wrapTriggerNode = self.xmlFile:getValue("vehicle.inlineWrapper.wrapTrigger#node", nil, self.components, self.i3dMappings)
    if spec.wrapTriggerNode ~= nil then
        addTrigger(spec.wrapTriggerNode, "inlineWrapTriggerCallback", self)
    end
    spec.minFoldTime = self.xmlFile:getValue("vehicle.inlineWrapper.baleTrigger#minFoldTime", 0)
    spec.maxFoldTime = self.xmlFile:getValue("vehicle.inlineWrapper.baleTrigger#maxFoldTime", 1)
    spec.wrapColor = { 1, 1, 1 }
    spec.baleTypes = {}
    self.xmlFile:iterate("vehicle.inlineWrapper.baleTypes.baleType", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local entry = {
            ["startNode"] = self.xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)
        }
        if entry.startNode == nil then
            Logging.xmlError(self.xmlFile, "Failed to load bale type. Missing start node! \'%s\'", key)
            return
        else
            entry.railingWidth = self.xmlFile:getValue(key .. ".railing#width")
            entry.wrapUsage = self.xmlFile:getValue(key .. "#wrapUsage", 0.1) / 60 / 1000
            entry.inlineBaleFilename = Utils.getFilename(self.xmlFile:getValue(key .. ".inlineBale#filename"), self.baseDirectory)
            if entry.inlineBaleFilename == nil then
                Logging.xmlError(self.xmlFile, "Failed to load bale type. Missing inline bale filename! \'%s\'", key)
            else
                entry.diameter = MathUtil.round(self.xmlFile:getValue(key .. ".size#diameter", 0), 2)
                entry.width = MathUtil.round(self.xmlFile:getValue(key .. ".size#width", 0), 2)
                entry.isRoundBale = entry.diameter ~= 0
                if not entry.isRoundBale then
                    entry.height = MathUtil.round(self.xmlFile:getValue(key .. ".size#height", 0), 2)
                    entry.length = MathUtil.round(self.xmlFile:getValue(key .. ".size#length", 0), 2)
                end
                entry.index = #spec.baleTypes + 1
                table.insert(spec.baleTypes, entry)
            end
        end
    end)
    spec.railingsAnimation = self.xmlFile:getValue("vehicle.inlineWrapper.railings#animation")
    spec.railingsAnimationStartX = self.xmlFile:getValue("vehicle.inlineWrapper.railings#animStartX")
    spec.railingsAnimationEndX = self.xmlFile:getValue("vehicle.inlineWrapper.railings#animEndX")
    spec.railingStartX = self.xmlFile:getValue("vehicle.inlineWrapper.railings#defaultX", 1)
    spec.currentPosition = spec.railingStartX + 0.01
    spec.targetPosition = spec.railingStartX + 0.01
    spec.wrappingStartNode = self.xmlFile:getValue("vehicle.inlineWrapper.wrapping#startNode", nil, self.components, self.i3dMappings)
    spec.steeringNodes = {}
    self.xmlFile:iterate("vehicle.inlineWrapper.steeringNodes.steeringNode", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local entry = {
            ["node"] = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        }
        if entry.node ~= nil then
            entry.startRot = { getRotation(entry.node) }
            table.insert(spec.steeringNodes, entry)
        end
    end)
    spec.wrappingNodes = {}
    self.xmlFile:iterate("vehicle.inlineWrapper.wrappingNodes.wrappingNode", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local entry = {
            ["node"] = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings),
            ["target"] = self.xmlFile:getValue(key .. "#target", nil, self.components, self.i3dMappings)
        }
        if entry.node ~= nil and entry.target ~= nil then
            entry.startTrans = self.xmlFile:getValue(key .. "#startTrans", nil, true) or { getTranslation(entry.target) }
            setTranslation(entry.target, entry.startTrans[1], entry.startTrans[2], entry.startTrans[3])
            table.insert(spec.wrappingNodes, entry)
        end
    end)
    spec.animations = {}
    spec.animations.pusher = self.xmlFile:getValue("vehicle.inlineWrapper.animations#pusher", "pusherAnimation")
    spec.animations.wrapping = self.xmlFile:getValue("vehicle.inlineWrapper.animations#wrapping", "wrappingAnimation")
    spec.animations.pushOff = self.xmlFile:getValue("vehicle.inlineWrapper.animations#pushOff", "pushOffAnimation")
    spec.pushingBrakeForce = self.xmlFile:getValue("vehicle.inlineWrapper.pushing#brakeForce", 0)
    spec.pushingOpenBrakeTime = self.xmlFile:getValue("vehicle.inlineWrapper.pushing#openBrakeTime", 0.1)
    spec.pushingCloseBrakeTime = self.xmlFile:getValue("vehicle.inlineWrapper.pushing#closeBrakeTime", 0.5)
    spec.pushingMinBaleAmount = self.xmlFile:getValue("vehicle.inlineWrapper.pushing#minBaleAmount", 4)
    spec.baleMovedThreshold = self.xmlFile:getValue("vehicle.inlineWrapper#baleMovedThreshold", 0.05)
    spec.pusherAnimationDirty = false
    spec.showIncompatibleBalesWarning = false
    spec.pendingSingleBales = {}
    spec.pendingIncompatibleBales = {}
    spec.enteredInlineBales = {}
    spec.enteredBalesToWrap = {}
    spec.numObjectBits = self.xmlFile:getValue("vehicle.inlineWrapper#numObjectBits", 4)
    spec.inlineBalesDirtyFlag = self:getNextDirtyFlag()
    spec.warningDirtyFlag = self:getNextDirtyFlag()
    spec.currentLineDirection = nil
    spec.lineDirection = nil
    spec.activatable = InlineWrapperActivatable.new(self)
    if self.isClient then
        spec.samples = {}
        spec.samples.wrap = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.inlineWrapper.sounds", "wrap", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.start = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.inlineWrapper.sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.stop = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.inlineWrapper.sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
end
function InlineWrapper:onPostLoad(_)
    local spec = self.spec_inlineWrapper
    if spec.railingsAnimation ~= nil then
        self:setAnimationTime(spec.railingsAnimation, 1, true)
    end
end
function InlineWrapper:onDelete()
    local spec = self.spec_inlineWrapper
    if spec.triggerNode ~= nil then
        removeTrigger(spec.triggerNode)
    end
    if spec.wrapTriggerNode ~= nil then
        removeTrigger(spec.wrapTriggerNode)
    end
    g_soundManager:deleteSamples(spec.samples)
    g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    local inlineBale = self:getCurrentInlineBale()
    if inlineBale ~= nil then
        inlineBale:wakeUp(50)
        inlineBale:setWrappingState(1)
        inlineBale:setCurrentWrapperInfo(nil, nil)
        self:setCurrentInlineBale(nil)
    end
end
function InlineWrapper:onReadStream(streamId, connection)
    self:readInlineBales("pendingSingleBales", streamId, connection)
    self:readInlineBales("enteredInlineBales", streamId, connection)
    self:readInlineBales("enteredBalesToWrap", streamId, connection)
    if streamReadBool(streamId) then
        self:setCurrentInlineBale(NetworkUtil.readNodeObjectId(streamId), true)
    else
        self:setCurrentInlineBale(nil, true)
    end
    local inlineBale = self.spec_inlineWrapper
    inlineBale.showIncompatibleBalesWarning = streamReadBool(streamId)
    g_currentMission.activatableObjectsSystem:addActivatable(inlineBale.activatable)
end
function InlineWrapper:onWriteStream(streamId, connection)
    self:writeInlineBales("pendingSingleBales", streamId, connection)
    self:writeInlineBales("enteredInlineBales", streamId, connection)
    self:writeInlineBales("enteredBalesToWrap", streamId, connection)
    local currentInlineBale = self:getCurrentInlineBale()
    if streamWriteBool(streamId, currentInlineBale ~= nil) then
        NetworkUtil.writeNodeObject(streamId, currentInlineBale)
    end
    streamWriteBool(streamId, self.spec_inlineWrapper.showIncompatibleBalesWarning)
end
function InlineWrapper:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        local spec = self.spec_inlineWrapper
        if streamReadBool(streamId) then
            self:readInlineBales("pendingSingleBales", streamId, connection)
            self:readInlineBales("enteredInlineBales", streamId, connection)
            self:readInlineBales("enteredBalesToWrap", streamId, connection)
            if streamReadBool(streamId) then
                self:setCurrentInlineBale(NetworkUtil.readNodeObjectId(streamId), true)
            else
                self:setCurrentInlineBale(nil, true)
            end
            g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
        end
        spec.showIncompatibleBalesWarning = streamReadBool(streamId)
    end
end
function InlineWrapper:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_inlineWrapper
        local currentInlineBale = streamWriteBool
        if currentInlineBale(streamId, bit32.band(dirtyMask, spec.inlineBalesDirtyFlag) ~= 0) then
            self:writeInlineBales("pendingSingleBales", streamId, connection)
            self:writeInlineBales("enteredInlineBales", streamId, connection)
            self:writeInlineBales("enteredBalesToWrap", streamId, connection)
            local currentInlineBale = self:getCurrentInlineBale()
            if streamWriteBool(streamId, currentInlineBale ~= nil) then
                NetworkUtil.writeNodeObject(streamId, currentInlineBale)
            end
        end
        streamWriteBool(streamId, spec.showIncompatibleBalesWarning)
    end
end
function InlineWrapper:readInlineBales(name, streamId, _)
    local spec = self.spec_inlineWrapper
    local sum = streamReadUIntN(streamId, spec.numObjectBits)
    spec[name] = {}
    for _ = 1, sum do
        local object = NetworkUtil.readNodeObjectId(streamId)
        spec[name][object] = object
    end
end
function InlineWrapper:writeInlineBales(name, streamId, _)
    local spec = self.spec_inlineWrapper
    local num = table.size(spec[name])
    streamWriteUIntN(streamId, num, spec.numObjectBits)
    local objectIndex = 0
    for object, _ in pairs(spec[name]) do
        objectIndex = objectIndex + 1
        if objectIndex <= num then
            NetworkUtil.writeNodeObjectId(streamId, object)
        else
            Logging.xmlWarning(self.xmlFile, "Not enough bits to send all inline objects. Please increase \'%s\'", "vehicle.inlineWrapper#numObjectBits")
        end
    end
end
function InlineWrapper:onUpdate(_, _, _, _)
    if self:getIsAnimationPlaying(self.spec_inlineWrapper.animations.wrapping) then
        self:updateWrappingNodes()
    end
end
function InlineWrapper:onUpdateTick(dt, _, _, _)
    local spec = self.spec_inlineWrapper
    if self.isServer then
        local pendingBaleId = next(spec.pendingSingleBales)
        local pendingBale = NetworkUtil.getObject(pendingBaleId)
        if pendingBale ~= nil and self:getIsInlineBalingAllowed() then
            local baleType = self:getWrapperBaleType(pendingBale)
            local lastBaleId = next(spec.enteredInlineBales)
            local lastBale = NetworkUtil.getObject(lastBaleId)
            local inlineBale = nil
            local success = false
            if lastBale == nil then
                inlineBale = InlineBale.new(self.isServer, self.isClient)
                if inlineBale:loadFromConfigXML(baleType.inlineBaleFilename) then
                    inlineBale:setOwnerFarmId(self:getActiveFarm(), true)
                    inlineBale:setCurrentWrapperInfo(self, spec.wrappingStartNode)
                    inlineBale:register()
                    success = inlineBale:addBale(pendingBale, baleType)
                else
                    inlineBale:delete()
                end
            elseif lastBale:isa(InlineBaleSingle) then
                inlineBale = lastBale:getConnectedInlineBale()
                if inlineBale ~= nil then
                    success = inlineBale:addBale(pendingBale, baleType)
                    if success then
                        self:getCurrentInlineBale():setCurrentWrapperInfo(self, spec.wrappingStartNode)
                    end
                end
            end
            if success then
                spec.pendingSingleBales[pendingBaleId] = nil
                spec.enteredInlineBales[pendingBaleId] = pendingBaleId
                spec.pusherAnimationDirty = true
                self:setCurrentInlineBale(inlineBale)
                g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
                local currentInlineBale, _ = g_farmManager:updateFarmStats(self:getOwnerFarmId(), "wrappedBales", 1)
                if currentInlineBale ~= nil then
                    g_achievementManager:tryUnlock("WrappedBales", currentInlineBale)
                end
                self:raiseDirtyFlags(spec.inlineBalesDirtyFlag)
            end
        end
        local baleType = next(spec.pendingIncompatibleBales) ~= nil
        if baleType ~= spec.showIncompatibleBalesWarning then
            spec.showIncompatibleBalesWarning = baleType
            self:raiseDirtyFlags(spec.warningDirtyFlag)
        end
    end
    local pendingBaleId = next(spec.enteredInlineBales)
    local pendingBale = NetworkUtil.getObject(pendingBaleId)
    if pendingBale == nil then
        self:setCurrentInlineBale(nil)
    elseif self:getCurrentInlineBale() == nil and pendingBale:isa(InlineBaleSingle) then
        local baleType = pendingBale:getConnectedInlineBale()
        if baleType ~= nil then
            self:setCurrentInlineBale(baleType)
            g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
            self:updateWrappingNodes()
            self:getCurrentInlineBale():setCurrentWrapperInfo(self, spec.wrappingStartNode)
        end
    end
    local baleType = next(spec.enteredInlineBales) ~= nil or spec.pushOffStarted
    if baleType then
        baleType = self:getAttacherVehicle() ~= nil
    end
    local lastBaleId = baleType and not self:getIsControlled()
    if spec.lineDirection == nil and baleType then
        local lastBale, inlineBale, success = localDirectionToWorld(self.components[1].node, 0, 0, -1)
        spec.lineDirection = { lastBale, success }
    elseif spec.lineDirection ~= nil and not baleType then
        spec.lineDirection = nil
    end
    if lastBaleId then
        spec.currentLineDirection = spec.lineDirection
    elseif spec.currentLineDirection ~= nil then
        spec.currentLineDirection = nil
        self:updateInlineSteeringWheels()
    end
    if spec.currentLineDirection ~= nil then
        self:updateInlineSteeringWheels(spec.currentLineDirection[1], spec.currentLineDirection[2])
    end
    if self.isServer then
        spec.releaseBrake = false
        local lastBale = self:getCurrentInlineBale()
        if spec.pusherAnimationDirty then
            local inlineBale = true
            for _, baleId in pairs(spec.pendingSingleBales) do
                if not self:getAllowBalePushing(NetworkUtil.getObject(baleId)) then
                    inlineBale = false
                    break
                end
            end
            if inlineBale then
                for _, baleId in pairs(spec.enteredInlineBales) do
                    if not self:getAllowBalePushing(NetworkUtil.getObject(baleId)) then
                        inlineBale = false
                        break
                    end
                end
            end
            if inlineBale and lastBale ~= nil then
                local success = lastBale:getPendingBale()
                local currentInlineBale = NetworkUtil.getObjectId(success)
                local _, baleId = lastBale:replacePendingBale(self:getWrapperBaleType(success).startNode, spec.wrapColor)
                if _ then
                    spec.enteredInlineBales[currentInlineBale] = nil
                    spec.enteredInlineBales[baleId] = baleId
                end
                self:playAnimation(spec.animations.pusher, 1, 0)
                spec.pusherAnimationDirty = false
                lastBale:connectPendingBale()
                self:raiseDirtyFlags(spec.inlineBalesDirtyFlag)
            end
            self:raiseActive()
        end
        if self:getAttacherVehicle() == nil then
            local inlineBale = true
            if lastBale ~= nil and lastBale:getNumberOfBales() < spec.pushingMinBaleAmount then
                inlineBale = false
            end
            local success = self:getAnimationTime(spec.animations.pusher)
            local currentInlineBale = self:getIsAnimationPlaying(spec.animations.pusher)
            if currentInlineBale then
                currentInlineBale = false
                if spec.pushingOpenBrakeTime < success then
                    currentInlineBale = success < spec.pushingCloseBrakeTime
                end
            end
            local baleId = currentInlineBale or self:getIsAnimationPlaying(spec.animations.pushOff) and self:getAnimationSpeed(spec.animations.pushOff) > 0
            if inlineBale then
                spec.releaseBrake = baleId
            end
        end
    end
    local lastBale = false
    local inlineBale = nil
    for _, baleId in pairs(spec.enteredBalesToWrap) do
        local wrapBale = NetworkUtil.getObject(baleId)
        if wrapBale ~= nil and entityExists(wrapBale.nodeId) then
            local x, y, z = localToLocal(wrapBale.nodeId, self.components[1].node, 0, 0, 0)
            if wrapBale.lastWrapTranslation == nil or wrapBale.lastWrapMoveTime == nil then
                wrapBale.lastWrapMoveTime = -math.huge
                wrapBale.lastWrapTranslation = { x, y, z }
            elseif math.abs(wrapBale.lastWrapTranslation[1] - x) + math.abs(wrapBale.lastWrapTranslation[2] - y) + math.abs(wrapBale.lastWrapTranslation[3] - z) > spec.baleMovedThreshold then
                wrapBale.lastWrapMoveTime = g_currentMission.time
                wrapBale.lastWrapTranslation = { x, y, z }
            end
            if wrapBale.lastWrapMoveTime + 1500 > g_currentMission.time then
                lastBale = true
                inlineBale = self:getWrapperBaleType(wrapBale)
                break
            end
            self:raiseActive()
        end
    end
    if lastBale then
        if self.isServer and inlineBale ~= nil then
            self:updateConsumable(InlineWrapper.CONSUMABLE_TYPE_NAME, -inlineBale.wrapUsage * dt, true)
        end
        if not self:getIsAnimationPlaying(spec.animations.wrapping) then
            self:playAnimation(spec.animations.wrapping, 1, self:getAnimationTime(spec.animations.wrapping), true)
        end
        if self.isClient and not (g_soundManager:getIsSamplePlaying(spec.samples.start) or g_soundManager:getIsSamplePlaying(spec.samples.wrap)) then
            g_soundManager:playSample(spec.samples.start)
            g_soundManager:playSample(spec.samples.wrap, 0, spec.samples.start)
        end
    else
        self:stopAnimation(spec.animations.wrapping, true)
        if self.isClient and (g_soundManager:getIsSamplePlaying(spec.samples.start) or g_soundManager:getIsSamplePlaying(spec.samples.wrap)) then
            g_soundManager:stopSample(spec.samples.start)
            g_soundManager:stopSample(spec.samples.wrap)
            g_soundManager:playSample(spec.samples.stop)
        end
    end
    local success = next(spec.pendingSingleBales) or next(spec.enteredInlineBales)
    local currentInlineBale = NetworkUtil.getObject(success)
    if currentInlineBale == nil then
        self:updateWrapperRailings(spec.railingStartX, dt)
    elseif self:getIsInlineBalingAllowed() then
        local currentInlineBale = self:getWrapperBaleType(currentInlineBale)
        local _ = self:getCurrentInlineBale()
        if _ ~= nil and not _:getIsBaleAllowed(currentInlineBale, currentInlineBale) then
            currentInlineBale = nil
        end
        if currentInlineBale ~= nil then
            spec.targetPosition = currentInlineBale.railingWidth
            self:updateWrapperRailings(spec.targetPosition, dt)
        end
    end
    if self.isServer and (spec.pushOffStarted ~= nil and (spec.pushOffStarted and not self:getIsAnimationPlaying(spec.animations.pushOff))) then
        self:playAnimation(spec.animations.pushOff, -1, 1)
        spec.pushOffStarted = nil
    end
    if self.isClient then
        local currentInlineBale = spec.actionEvents[InputAction.ACTIVATE_OBJECT]
        if currentInlineBale ~= nil then
            g_inputBinding:setActionEventActive(currentInlineBale.actionEventId, self:getCanPushOff())
        end
    end
end
function InlineWrapper:onDraw(_, _, _)
    if self.isClient then
        local spec = self.spec_inlineWrapper
        if next(spec.pendingSingleBales) ~= nil then
            local foldTime = self:getFoldAnimTime()
            if foldTime < spec.minFoldTime or spec.maxFoldTime < foldTime then
                g_currentMission:showBlinkingWarning(self.spec_foldable.unfoldWarning, 500)
            end
        end
        if spec.showIncompatibleBalesWarning then
            g_currentMission:showBlinkingWarning(g_i18n:getText("warning_baleNotSupported"), 500)
        end
    end
end
function InlineWrapper:updateWrappingNodes()
    local inlineBale = self:getCurrentInlineBale()
    if inlineBale == nil then
        if self.spec_inlineWrapper.resetWrappingNodes then
            for _, _ in ipairs(spec.wrappingNodes) do
                setTranslation(_.target, _.startTrans[1], _.startTrans[2], _.startTrans[3])
            end
            spec.resetWrappingNodes = nil
        end
    else
        for _, wrappingNode in ipairs(spec.wrappingNodes) do
            local x, y, z = getWorldTranslation(wrappingNode.node)
            local minDistance = math.huge
            local minBale = nil
            for _, baleId in pairs(spec.enteredBalesToWrap) do
                local bale = NetworkUtil.getObject(baleId)
                if bale ~= nil and bale ~= inlineBale:getPendingBale() then
                    local bx, _, bz = worldToLocal(bale.nodeId, x, y, z)
                    local x1 = nil
                    local y1 = nil
                    local z1 = nil
                    local x2 = nil
                    local y2 = nil
                    local z2 = nil
                    if bale.isRoundbale then
                        if -bale.width / 2 <= bz then
                            x1, y1, z1 = localToWorld(bale.nodeId, 0, 0, bale.width / 2)
                            x2, y2, z2 = localToWorld(bale.nodeId, 0, 0, -bale.width / 2)
                        end
                    elseif -bale.width / 2 <= bx then
                        x1, y1, z1 = localToWorld(bale.nodeId, bale.width / 2, 0, 0)
                        x2, y2, z2 = localToWorld(bale.nodeId, -bale.width / 2, 0, 0)
                    end
                    if x1 ~= nil then
                        local distance = math.min(MathUtil.vector3Length(x - x1, y - y1, z - z1), MathUtil.vector3Length(x - x2, y - y2, z - z2))
                        if distance < minDistance then
                            minBale = bale
                            minDistance = distance
                        end
                    end
                end
            end
            if minBale == nil then
                setTranslation(wrappingNode.target, wrappingNode.startTrans[1], wrappingNode.startTrans[2], wrappingNode.startTrans[3])
            else
                local _, baleId, bale
                if minBale.isRoundbale then
                    _, baleId, bale = self:updateRoundBaleWrappingNode(minBale, wrappingNode.node, x, y, z)
                else
                    _, baleId, bale = self:updateSquareBaleWrappingNode(minBale, wrappingNode.node, x, y, z)
                end
                if _ == nil then
                    setTranslation(wrappingNode.target, wrappingNode.startTrans[1], wrappingNode.startTrans[2], wrappingNode.startTrans[3])
                else
                    local _, baleId, bale = worldToLocal(getParent(wrappingNode.target), _, baleId, bale)
                    setTranslation(wrappingNode.target, _, baleId, bale)
                end
            end
        end
        spec.resetWrappingNodes = true
    end
end
function InlineWrapper.updateRoundBaleWrappingNode(_, bale, wrappingNode, x, y, z)
    local baleNode = bale.nodeId
    local w1x, w1y, w1z = worldToLocal(baleNode, x, y, z)
    local distanceToCenter = MathUtil.vector3Length(w1x, w1y, 0)
    local maxDirY = -math.huge
    local targetX = nil
    local targetY = nil
    local targetZ = nil
    local i = 1
    for i = i, 32 do
        local a = i / 32 * 2 * 3.141592653589793
        local c = math.cos(a) * (bale.diameter / 2 + 0.01)
        local s = math.sin(a) * (baleRadius + 0.01)
        if MathUtil.vector2Length(c - w1x, s - w1y) < distanceToCenter then
            local intersect, _, _, _, _ = MathUtil.getCircleLineIntersection(0, 0, baleRadius, w1x, w1y, c, s)
            if not intersect then
                local px, py, pz = localToWorld(baleNode, c, s, 0)
                local _, wrapDirY, _ = worldToLocal(wrappingNode, px, py, pz)
                if maxDirY < wrapDirY then
                    targetX, targetY, targetZ = localToWorld(baleNode, math.cos(a) * (baleRadius + -0.03), math.sin(a) * (baleRadius + -0.03), w1z)
                    maxDirY = wrapDirY
                end
            end
        end
    end
    return targetX, targetY, targetZ
end
function InlineWrapper.updateSquareBaleWrappingNode(_, bale, wrappingNode, x, y, z)
    local baleNode = bale.nodeId
    local minAngle = math.huge
    local targetX = nil
    local targetY = nil
    local targetZ = nil
    local w1x, w1y, w1z = worldToLocal(baleNode, x, y, z)
    if bale.wrappingEdges == nil then
        bale.wrappingEdges = {}
        bale.wrappingEdges[1] = { 0, bale.height / 2, -(bale.length / 2) }
        bale.wrappingEdges[2] = { 0, -height, -length }
        bale.wrappingEdges[3] = { 0, -height, length }
        bale.wrappingEdges[4] = { 0, height, length }
    end
    for _, edge in ipairs(bale.wrappingEdges) do
        local edgeZ = edge[2]
        local py = edge[2]
        local edgeY = edgeZ + math.sign(py) * 0.01
        local intersect = edge[3]
        local i = edge[3]
        local edgeZ = intersect + math.sign(i) * 0.01
        local intersect = false
        local i = 1
        local px = 4
        local py = 1
        for i = i, px, py do
            local i2 = i <= 3 and i + 1 or 1
            intersect = intersect or MathUtil.getLineBoundingVolumeIntersect(edgeY, edgeZ, w1y, w1z, bale.wrappingEdges[i][2], bale.wrappingEdges[i][3], bale.wrappingEdges[i2][2], bale.wrappingEdges[i2][3])
        end
        if not intersect then
            local px, py, i = localToWorld(baleNode, w1x, edgeY, edgeZ)
            local i2, wrapDirY, wrapDirZ = worldToLocal(wrappingNode, px, py, i)
            local angle = MathUtil.getYRotationFromDirection(wrapDirY, wrapDirZ)
            if angle < 0 then
            end
            if angle < minAngle then
                targetX, targetY, targetZ = localToWorld(baleNode, w1x, edge[2] + math.sign(edge[2]) * -0.05, edge[3] + math.sign(edge[3]) * -0.05)
                minAngle = angle
            end
        end
    end
    return targetX, targetY, targetZ
end
function InlineWrapper:onRegisterActionEvents(isActiveForInput, _)
    if self.isClient then
        local spec = self.spec_inlineWrapper
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInput then
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.ACTIVATE_OBJECT, self, InlineWrapper.pushOffInlineBaleEvent, false, false, true, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
            g_inputBinding:setActionEventActive(actionEventId, self:getCanPushOff())
            g_inputBinding:setActionEventTextVisibility(actionEventId, true)
            g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_baleloaderUnload"))
        end
    end
end
function InlineWrapper:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
    if next(self.spec_inlineWrapper.enteredInlineBales) == nil then
        return superFunc(self, direction, onAiTurnOn)
    else
        return false
    end
end
function InlineWrapper:getIsActive(superFunc)
    local spec = self.spec_inlineWrapper
    return (spec.releaseBrake or spec.releaseBrake ~= spec.releaseBrakeSet) and true or superFunc(self)
end
function InlineWrapper:getBrakeForce(superFunc)
    local spec = self.spec_inlineWrapper
    if not spec.releaseBrake then
        return superFunc(self)
    end
    spec.releaseBrakeSet = spec.releaseBrake
    return 0
end
function InlineWrapper:getShowConsumableEmptyWarning(superFunc, typeName)
    if typeName ~= InlineWrapper.CONSUMABLE_TYPE_NAME or not superFunc(self, typeName) then
        return superFunc(self, typeName)
    end
    local spec = self.spec_inlineWrapper
    if next(spec.pendingSingleBales) ~= nil then
        local foldTime = self:getFoldAnimTime()
        if spec.minFoldTime <= foldTime or foldTime <= spec.maxFoldTime then
            return true
        end
    end
    return false
end
function InlineWrapper:getIsInlineBalingAllowed()
    local spec = self.spec_inlineWrapper
    local foldTime = self:getFoldAnimTime()
    if foldTime < spec.minFoldTime or spec.maxFoldTime < foldTime then
        return false
    elseif self:getIsAnimationPlaying(spec.animations.pusher) then
        return false
    elseif self:getIsAnimationPlaying(spec.animations.pushOff) or self:getAnimationTime(spec.animations.pushOff) > 0 then
        return false
    else
        return self:getConsumableIsAvailable(InlineWrapper.CONSUMABLE_TYPE_NAME)
    end
end
function InlineWrapper:inlineBaleTriggerCallback(_, otherActorId, onEnter, onLeave, _, _)
    if self.isServer then
        local object = g_currentMission:getNodeObject(otherActorId)
        if object ~= nil and object:isa(Bale) then
            local objectId = NetworkUtil.getObjectId(object)
            local spec = self.spec_inlineWrapper
            if onEnter then
                if object:isa(InlineBaleSingle) then
                    spec.enteredInlineBales[objectId] = objectId
                    local connectedInlineBale = object:getConnectedInlineBale()
                    if connectedInlineBale == nil then
                        object.inlineWrapperToAdd = {
                            ["wrapper"] = self,
                            ["wrappingNode"] = spec.wrappingStartNode
                        }
                    else
                        connectedInlineBale:setCurrentWrapperInfo(self, spec.wrappingStartNode)
                    end
                elseif self:getWrapperBaleType(object) == nil then
                    spec.pendingIncompatibleBales[objectId] = objectId
                else
                    spec.pendingSingleBales[objectId] = objectId
                end
            elseif onLeave then
                spec.pendingSingleBales[objectId] = nil
                spec.pendingIncompatibleBales[objectId] = nil
                spec.enteredInlineBales[objectId] = nil
                if object:isa(InlineBaleSingle) then
                    local connectedInlineBale = object:getConnectedInlineBale()
                    if connectedInlineBale ~= nil then
                        local bales = connectedInlineBale:getBales()
                        local removeFromWrapper = true
                        for _, bale in ipairs(bales) do
                            local baleId = NetworkUtil.getObjectId(bale)
                            if spec.pendingSingleBales[baleId] ~= nil or spec.enteredInlineBales[baleId] ~= nil then
                                removeFromWrapper = false
                                break
                            end
                        end
                        if removeFromWrapper then
                            connectedInlineBale:setCurrentWrapperInfo(nil, nil)
                            self:setCurrentInlineBale(nil)
                        end
                    end
                end
            end
            self:raiseDirtyFlags(spec.inlineBalesDirtyFlag)
        end
    end
end
function InlineWrapper:inlineWrapTriggerCallback(_, otherActorId, onEnter, onLeave, _, _)
    if self.isServer then
        local object = g_currentMission:getNodeObject(otherActorId)
        if object ~= nil and object:isa(Bale) then
            local spec = self.spec_inlineWrapper
            local objectId = NetworkUtil.getObjectId(object)
            if onEnter then
                spec.enteredBalesToWrap[objectId] = objectId
            elseif onLeave then
                spec.enteredBalesToWrap[objectId] = nil
            end
            self:raiseActive()
            self:raiseDirtyFlags(spec.inlineBalesDirtyFlag)
        end
    end
end
function InlineWrapper:getWrapperBaleType(bale)
    for _, baleType in pairs(self.spec_inlineWrapper.baleTypes) do
        if bale:getSupportsWrapping() then
            if bale.isRoundbale then
                if baleType.isRoundBale and (bale.diameter == baleType.diameter and bale.width == baleType.width) then
                    return baleType
                end
            elseif not baleType.isRoundBale and (bale.width == baleType.width and (bale.height == baleType.height and bale.length == baleType.length)) then
                return baleType
            end
        end
    end
    return nil
end
function InlineWrapper.getAllowBalePushing(_, bale)
    return bale.dynamicMountJointIndex == nil
end
function InlineWrapper:updateWrapperRailings(targetPosition, dt)
    local spec = self.spec_inlineWrapper
    if targetPosition ~= spec.currentPosition then
        local dir = math.sign(targetPosition - spec.currentPosition)
        spec.currentPosition = spec.currentPosition + 0.0001 * dt * dir
        if dir > 0 then
            spec.currentPosition = math.min(spec.currentPosition, targetPosition)
        else
            spec.currentPosition = math.max(spec.currentPosition, targetPosition)
        end
        self:setAnimationTime(spec.railingsAnimation, (spec.currentPosition - spec.railingsAnimationStartX) / (spec.railingsAnimationEndX - spec.railingsAnimationStartX), true)
    end
end
function InlineWrapper:updateInlineSteeringWheels(dirX, dirZ)
    for _, steeringNode in ipairs(self.spec_inlineWrapper.steeringNodes) do
        if dirX == nil or dirZ == nil then
            setRotation(steeringNode.node, unpack(steeringNode.startRot))
        else
            local px, py, pz = getWorldTranslation(steeringNode.node)
            local targetX, _, targetZ = worldToLocal(getParent(steeringNode.node), px + dirX * 10, py, pz + dirZ * 10)
            local upX, upY, upZ = MathUtil.vector3Normalize(targetX, 0, targetZ)
            local upX, upY, upZ = localDirectionToWorld(getParent(steeringNode.node), 0, 1, 0)
            setDirection(steeringNode.node, upX, 0, upZ, upX, upY, upZ)
        end
        if self.setMovingToolDirty ~= nil then
            self:setMovingToolDirty(steeringNode.node)
        end
    end
end
function InlineWrapper:onLeaveVehicle()
    self.rotatedTime = 0
end
function InlineWrapper:onEnterVehicle()
    for _, steeringNode in ipairs(self.spec_inlineWrapper.steeringNodes) do
        setRotation(steeringNode.node, unpack(steeringNode.startRot))
        if self.setMovingToolDirty ~= nil then
            self:setMovingToolDirty(steeringNode.node)
        end
    end
end
function InlineWrapper:onConsumableVariationChanged(_, metaData)
    if metaData.color ~= nil then
        local spec = self.spec_inlineWrapper
        spec.wrapColor[1] = metaData.color[1]
        spec.wrapColor[2] = metaData.color[2]
        spec.wrapColor[3] = metaData.color[3]
    end
end
function InlineWrapper:getCanInteract()
    local localPlayer = g_localPlayer
    if localPlayer:getIsInVehicle() then
        return false
    end
    if not g_currentMission.accessHandler:canPlayerAccess(self) then
        return false
    end
    local x1, y1, z1 = localPlayer:getPosition()
    local x2, y2, z2 = getWorldTranslation(self.components[1].node)
    return MathUtil.vector3Length(x1 - x2, y1 - y2, z1 - z2) < InlineWrapper.INTERACTION_RADIUS
end
function InlineWrapper:getCanPushOff()
    local currentInlineBale = self:getCurrentInlineBale()
    if currentInlineBale == nil then
        return false
    elseif currentInlineBale:getPendingBale() == nil then
        if self:getIsAnimationPlaying(self.spec_inlineWrapper.animations.pusher) then
            return false
        else
            return not self:getIsAnimationPlaying(spec.animations.pushOff)
        end
    else
        return false
    end
end
function InlineWrapper:setCurrentInlineBale(inlineBale, isClient)
    if self.isServer then
        local newInlineBale = NetworkUtil.getObjectId(inlineBale)
        if newInlineBale ~= self.spec_inlineWrapper.currentInlineBale then
            spec.currentInlineBale = newInlineBale
            self:raiseDirtyFlags(spec.inlineBalesDirtyFlag)
        end
    end
    if isClient then
        spec.currentInlineBale = inlineBale
    end
end
function InlineWrapper:getCurrentInlineBale()
    return NetworkUtil.getObject(self.spec_inlineWrapper.currentInlineBale)
end
function InlineWrapper:pushOffInlineBaleEvent(_, inputValue, _, _)
    if inputValue == 1 then
        if g_server ~= nil then
            self:pushOffInlineBale()
            return
        end
        g_client:getServerConnection():sendEvent(InlineWrapperPushOffEvent.new(self))
    end
end
function InlineWrapper:pushOffInlineBale()
    local spec = self.spec_inlineWrapper
    if not self:getIsAnimationPlaying(spec.animations.pushOff) then
        self:playAnimation(spec.animations.pushOff, 1)
        spec.pushOffStarted = true
    end
end
function InlineWrapper.loadSpecValueBaleSize(xmlFile, _, _, roundBaleWrapper)
    local baleSizeAttributes = {
        ["minDiameter"] = math.huge,
        ["maxDiameter"] = -math.huge,
        ["minLength"] = math.huge,
        ["maxLength"] = -math.huge
    }
    xmlFile:iterate(xmlFile:getRootName() .. ".inlineWrapper.baleTypes.baleType", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) roundBaleWrapper, (copy) baleSizeAttributes
        local diameter = MathUtil.round(xmlFile:getValue(key .. ".size#diameter", 0), 2)
        if roundBaleWrapper and diameter ~= 0 then
            baleSizeAttributes.minDiameter = math.min(baleSizeAttributes.minDiameter, diameter)
            baleSizeAttributes.maxDiameter = math.max(baleSizeAttributes.maxDiameter, diameter)
        end
        local length = MathUtil.round(xmlFile:getValue(key .. ".size#length", 0), 2)
        if not roundBaleWrapper and length ~= 0 then
            baleSizeAttributes.minLength = math.min(baleSizeAttributes.minLength, length)
            baleSizeAttributes.maxLength = math.max(baleSizeAttributes.maxLength, length)
        end
    end)
    if baleSizeAttributes.minDiameter == math.huge and baleSizeAttributes.minLength == math.huge then
        return nil
    else
        return baleSizeAttributes
    end
end
function InlineWrapper.getSpecValueBaleSize(storeItem, _, _, _, returnValues, returnRange, roundBaleWrapper)
    local baleSizeAttributes = roundBaleWrapper and storeItem.specs.inlineWrapperBaleSizeRound or storeItem.specs.inlineWrapperBaleSizeSquare
    if baleSizeAttributes == nil then
        if returnValues and returnRange then
            return 0, 0, ""
        elseif returnValues then
            return 0, ""
        else
            return ""
        end
    elseif returnValues == nil or not returnValues then
        local unit = g_i18n:getText("unit_cmShort")
        if (roundBaleWrapper and baleSizeAttributes.maxDiameter or baleSizeAttributes.maxLength) == (roundBaleWrapper and baleSizeAttributes.minDiameter or baleSizeAttributes.minLength) then
            return string.format("%d%s", minValue * 100, unit)
        else
            return string.format("%d%s-%d%s", minValue * 100, unit, maxValue * 100, unit)
        end
    elseif returnRange == true and maxValue ~= minValue then
        return minValue * 100, maxValue * 100, g_i18n:getText("unit_cmShort")
    else
        return minValue * 100, g_i18n:getText("unit_cmShort")
    end
end
function InlineWrapper.loadSpecValueBaleSizeRound(xmlFile, customEnvironment, baseDir)
    return InlineWrapper.loadSpecValueBaleSize(xmlFile, customEnvironment, baseDir, true)
end
function InlineWrapper.loadSpecValueBaleSizeSquare(xmlFile, customEnvironment, baseDir)
    return InlineWrapper.loadSpecValueBaleSize(xmlFile, customEnvironment, baseDir, false)
end
function InlineWrapper.getSpecValueBaleSizeRound(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
    if storeItem.specs.inlineWrapperBaleSizeRound == nil then
        return nil
    else
        return InlineWrapper.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, true)
    end
end
function InlineWrapper.getSpecValueBaleSizeSquare(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
    if storeItem.specs.inlineWrapperBaleSizeSquare == nil then
        return nil
    else
        return InlineWrapper.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, false)
    end
end
InlineWrapperActivatable = {}
local InlineWrapperActivatable_mt = Class(InlineWrapperActivatable)
function InlineWrapperActivatable.new(inlineWrapper)
    -- upvalues: (copy) InlineWrapperActivatable_mt
    local self = setmetatable({}, InlineWrapperActivatable_mt)
    self.inlineWrapper = inlineWrapper
    self.activateText = g_i18n:getText("action_baleloaderUnload")
    return self
end
function InlineWrapperActivatable:getIsActivatable()
    return self.inlineWrapper:getCanInteract() and self.inlineWrapper:getCanPushOff() and true or false
end
function InlineWrapperActivatable:run()
    if g_server == nil then
        g_client:getServerConnection():sendEvent(InlineWrapperPushOffEvent.new(self.inlineWrapper))
    else
        self.inlineWrapper:pushOffInlineBale()
    end
end