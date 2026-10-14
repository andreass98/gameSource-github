PalletFiller = {}
source("dataS/scripts/vehicles/specializations/enums/PalletFillerState.lua")
source("dataS/scripts/vehicles/specializations/events/PalletFillerBuyPalletEvent.lua")
source("dataS/scripts/vehicles/specializations/events/PalletFillerStateEvent.lua")
function PalletFiller.prerequisitesPresent(specializations)
    return true
end
function PalletFiller.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("PalletFiller")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.palletFiller.pickupTrigger#node", "Pickup pallet trigger")
    schema:register(XMLValueType.STRING, "vehicle.palletFiller.pallet#filename", "Filename to supported pallet xml file")
    schema:register(XMLValueType.FLOAT, "vehicle.palletFiller.pallet#spacing", "Spacing between the pallets while they are loaded", 0.5)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.palletFiller.palletRow#node", "Pallet row node")
    schema:register(XMLValueType.INT, "vehicle.palletFiller.palletRow#maxNumPallets", "Max. number of pallets that can be picked up", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.palletFiller.palletRow#minTransZ", "Min. translation of the row (drop off point)", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.palletFiller.palletRow#maxTransZ", "Max. translation of the row (pick up point)", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.palletFiller.palletRow#moveSpeed", "Move speed of pallet on the row (m/sec)", 1)
    schema:register(XMLValueType.TIME, "vehicle.palletFiller.palletRow#pickupTime", "Time until the pallet is fully picked up (sec)", 2)
    schema:register(XMLValueType.ANGLE, "vehicle.palletFiller.palletRow#yRotation", "Y Rotation of the pallet", 0)
    schema:register(XMLValueType.TIME, "vehicle.palletFiller.palletRow#loadingDelay", "Loading delay used for combine", 0)
    schema:register(XMLValueType.VECTOR_ROT, "vehicle.palletFiller.palletRow.rotLimit#startLimit", "Start rotation limit after pickup", "0 0 0")
    schema:register(XMLValueType.VECTOR_ROT, "vehicle.palletFiller.palletRow.rotLimit#endLimit", "End rotation limit while fully mounted", "0 0 0")
    schema:register(XMLValueType.VECTOR_ROT, "vehicle.palletFiller.palletRow.rotLimit#unloadLimit", "Rotation limit while unloading", "0 0 25")
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.palletFiller.palletRow.transLimit#startLimit", "Start translation limit after pickup", "0.25 2 0.25")
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.palletFiller.palletRow.transLimit#endLimit", "End translation limit while fully mounted", "0.05 2 0")
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.palletFiller.palletRow.transLimit#unloadLimit", "Translation limit while unloading", "0.25 2 0")
    schema:register(XMLValueType.FLOAT, "vehicle.palletFiller.palletRow.fillStep(?)#transZ", "Target Z translation of the pickup of pallet while filling this pallet index", 0)
    schema:register(XMLValueType.INT, "vehicle.palletFiller.palletRow.fillStep(?)#palletIndex", "Pallet index to fill", 1)
    schema:register(XMLValueType.INT, "vehicle.palletFiller.palletRow.fillStep(?)#dischargeNodeIndex", "Discharge Node Index (defines which discharge node is used while the defined pallet index is available & not full)", 1)
    schema:register(XMLValueType.STRING, "vehicle.palletFiller.fillDeflectorAnimation#name", "Name of fill deflector animation (animation is played before the pallets are moving and revered after they are in the new position)")
    schema:register(XMLValueType.FLOAT, "vehicle.palletFiller.fillDeflectorAnimation#speed", "Animation speed scale", 1)
    schema:register(XMLValueType.STRING, "vehicle.palletFiller.platformAnimation#name", "Name of platform animation (animation to lower the tool for pallet pickup and drop -> 0=pickup, #middleTime=idle, 1=drop)")
    schema:register(XMLValueType.FLOAT, "vehicle.palletFiller.platformAnimation#speed", "Animation speed scale", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.palletFiller.platformAnimation#middleTime", "Animation middle time", 0.5)
    schema:register(XMLValueType.BOOL, "vehicle.palletFiller.platformAnimation#automaticLift", "Automatically lift platform after dropping or pickup", false)
    schema:register(XMLValueType.BOOL, "vehicle.palletFiller.platformAnimation#lowerToUnload", "Tool needs to be lowered first to be unloaded", false)
    schema:register(XMLValueType.FLOAT, "vehicle.palletFiller.foldable#minLimit", "Min. folding time for platform state change [0-1]", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.palletFiller.foldable#maxLimit", "Max. folding time for platform state change [0-1]", 1)
    SoundManager.registerSampleXMLPaths(schema, "vehicle.palletFiller.sounds", "move")
    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.palletFiller.animationNodes")
    schema:setXMLSpecializationType()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    PalletFillerState.registerXMLPath(schemaSavegame, "vehicles.vehicle(?).palletFiller#state", "Current vehicle state", nil, false)
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).palletFiller#deflectorState", "Current deflector state")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).palletFiller.palletSlot(?)#slotIndex", "Index of slot")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).palletFiller.palletSlot(?)#objectUniqueId", "Unique id of the object that is loaded on this slot")
    schemaSavegame:register(XMLValueType.VECTOR_TRANS, "vehicles.vehicle(?).palletFiller.palletSlot(?)#translation", "Translation of the joint")
    schemaSavegame:register(XMLValueType.VECTOR_ROT, "vehicles.vehicle(?).palletFiller.palletSlot(?)#rotation", "Rotation of the joint")
end
function PalletFiller.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadPalletFillerPallet", PalletFiller.loadPalletFillerPallet)
    SpecializationUtil.registerFunction(vehicleType, "unloadPalletFillerPallet", PalletFiller.unloadPalletFillerPallet)
    SpecializationUtil.registerFunction(vehicleType, "buyPalletFillerPallets", PalletFiller.buyPalletFillerPallets)
    SpecializationUtil.registerFunction(vehicleType, "getCanChangePalletFillerState", PalletFiller.getCanChangePalletFillerState)
    SpecializationUtil.registerFunction(vehicleType, "getCanBuyPalletFillerPallets", PalletFiller.getCanBuyPalletFillerPallets)
    SpecializationUtil.registerFunction(vehicleType, "setPalletFillerState", PalletFiller.setPalletFillerState)
    SpecializationUtil.registerFunction(vehicleType, "setPalletFillerDeflectorState", PalletFiller.setPalletFillerDeflectorState)
    SpecializationUtil.registerFunction(vehicleType, "getPalletFillerFillStep", PalletFiller.getPalletFillerFillStep)
    SpecializationUtil.registerFunction(vehicleType, "getPalletFillerMovementDirection", PalletFiller.getPalletFillerMovementDirection)
end
function PalletFiller.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleDischargeToObject", PalletFiller.getCanToggleDischargeToObject)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleDischargeToGround", PalletFiller.getCanToggleDischargeToGround)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", PalletFiller.removeFromPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", PalletFiller.getIsFoldAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation", PalletFiller.getFillLevelInformation)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getHasObjectMounted", PalletFiller.getHasObjectMounted)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanAIImplementContinueWork", PalletFiller.getCanAIImplementContinueWork)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "verifyCombine", PalletFiller.verifyCombine)
end
function PalletFiller.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onFinishAnimation", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onFoldTimeChanged", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", PalletFiller)
end
function PalletFiller:onLoad(_)
    local spec = self.spec_palletFiller
    spec.state = PalletFillerState.IDLE
    spec.pickupTrigger = {}
    spec.pickupTrigger.node = self.xmlFile:getValue("vehicle.palletFiller.pickupTrigger#node", nil, self.components, self.i3dMappings)
    if spec.pickupTrigger.node ~= nil then
        spec.pickupTrigger.triggeredObjects = {}
        function spec.pickupTrigger.pickupTriggerCallback(_, _, otherActorId, onEnter, onLeave, _, _)
            -- upvalues: (copy) spec, (copy) self
            local object = g_currentMission:getNodeObject(otherActorId)
            if object ~= nil and object:isa(Vehicle) then
                if onEnter then
                    for _, palletSlot in ipairs(spec.palletRow.palletSlots) do
                        if palletSlot.object == object then
                            return
                        end
                    end
                    if object.configFileName == spec.pallet.filename then
                        spec.pickupTrigger.triggeredObjects[otherActorId] = (spec.pickupTrigger.triggeredObjects[otherActorId] or 0) + 1
                        object:addDeleteListener(self, PalletFiller.onObjectDeleted)
                        self:raiseActive()
                        return
                    end
                elseif onLeave then
                    spec.pickupTrigger.triggeredObjects[otherActorId] = (spec.pickupTrigger.triggeredObjects[otherActorId] or 0) - 1
                    if spec.pickupTrigger.triggeredObjects[otherActorId] <= 0 then
                        spec.pickupTrigger.triggeredObjects[otherActorId] = nil
                        object:removeDeleteListener(self, PalletFiller.onObjectDeleted)
                    end
                end
            end
        end
        addTrigger(spec.pickupTrigger.node, "pickupTriggerCallback", spec.pickupTrigger)
    end
    spec.pallet = {}
    spec.pallet.filename = self.xmlFile:getValue("vehicle.palletFiller.pallet#filename")
    if spec.pallet.filename == nil then
        Logging.xmlWarning(self.xmlFile, "No pallet filename defined for \'%s\'", "vehicle.palletFiller")
    else
        spec.pallet.filename = Utils.getFilename(spec.pallet.filename, self.baseDirectory)
        spec.pallet.storeItem = g_storeManager:getItemByXMLFilename(spec.pallet.filename)
        if spec.pallet.storeItem == nil then
            Logging.xmlWarning(self.xmlFile, "Invalid pallet filename defined for \'%s\' (%s)", "vehicle.palletFiller", spec.pallet.filename)
            spec.pallet.filename = nil
        end
    end
    spec.pallet.spacing = self.xmlFile:getValue("vehicle.palletFiller.pallet#spacing", 0.5)
    spec.palletRow = {}
    spec.palletRow.node = self.xmlFile:getValue("vehicle.palletFiller.palletRow#node", nil, self.components, self.i3dMappings)
    spec.palletRow.maxNumPallets = self.xmlFile:getValue("vehicle.palletFiller.palletRow#maxNumPallets", 1)
    spec.palletRow.minTransZ = self.xmlFile:getValue("vehicle.palletFiller.palletRow#minTransZ", 0)
    spec.palletRow.maxTransZ = self.xmlFile:getValue("vehicle.palletFiller.palletRow#maxTransZ", 0)
    spec.palletRow.moveSpeed = self.xmlFile:getValue("vehicle.palletFiller.palletRow#moveSpeed", 1) / 1000
    spec.palletRow.pickupTime = self.xmlFile:getValue("vehicle.palletFiller.palletRow#pickupTime", 2)
    spec.palletRow.yRotation = self.xmlFile:getValue("vehicle.palletFiller.palletRow#yRotation", 0)
    spec.palletRow.loadingDelay = self.xmlFile:getValue("vehicle.palletFiller.palletRow#loadingDelay", 0)
    spec.palletRow.fillSteps = {}
    self.xmlFile:iterate("vehicle.palletFiller.palletRow.fillStep", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local fillStep = {
            ["transZ"] = self.xmlFile:getValue(key .. "#transZ", 0),
            ["palletIndex"] = self.xmlFile:getValue(key .. "#palletIndex", 1),
            ["dischargeNodeIndex"] = self.xmlFile:getValue(key .. "#dischargeNodeIndex", 1),
            ["index"] = #spec.palletRow.fillSteps + 1
        }
        table.insert(spec.palletRow.fillSteps, fillStep)
    end)
    spec.palletRow.startRotLimit = self.xmlFile:getValue("vehicle.palletFiller.palletRow.rotLimit#startLimit", "0 0 0", true)
    spec.palletRow.endRotLimit = self.xmlFile:getValue("vehicle.palletFiller.palletRow.rotLimit#endLimit", "0 0 0", true)
    spec.palletRow.unloadRotLimit = self.xmlFile:getValue("vehicle.palletFiller.palletRow.rotLimit#unloadLimit", "0 0 25", true)
    spec.palletRow.startTransLimit = self.xmlFile:getValue("vehicle.palletFiller.palletRow.transLimit#startLimit", "0.25 2 0.25", true)
    spec.palletRow.endTransLimit = self.xmlFile:getValue("vehicle.palletFiller.palletRow.transLimit#endLimit", "0 2 0", true)
    spec.palletRow.unloadTransLimit = self.xmlFile:getValue("vehicle.palletFiller.palletRow.transLimit#unloadLimit", "0.25 2 0", true)
    spec.palletRow.palletSlots = {}
    local i = 1
    for i = i, spec.palletRow.maxNumPallets do
        local palletSlot = {
            ["jointNode"] = createTransformGroup("jointNode" .. i)
        }
        link(spec.palletRow.node, palletSlot.jointNode)
        setTranslation(palletSlot.jointNode, 0, 0, 0)
        setRotation(palletSlot.jointNode, 0, spec.palletRow.yRotation, 0)
        palletSlot.object = nil
        palletSlot.interpolationTimer = 0
        palletSlot.index = #spec.palletRow.palletSlots + 1
        table.insert(spec.palletRow.palletSlots, palletSlot)
    end
    spec.palletRow.currentTransZ = 0
    spec.palletRow.currentDischargeNodeIndex = 1
    spec.palletRow.isMoving = false
    spec.fillDeflectorAnimation = {}
    spec.fillDeflectorAnimation.name = self.xmlFile:getValue("vehicle.palletFiller.fillDeflectorAnimation#name")
    spec.fillDeflectorAnimation.speed = self.xmlFile:getValue("vehicle.palletFiller.fillDeflectorAnimation#speed", 1)
    spec.fillDeflectorAnimation.state = false
    spec.platformAnimation = {}
    spec.platformAnimation.name = self.xmlFile:getValue("vehicle.palletFiller.platformAnimation#name")
    spec.platformAnimation.speed = self.xmlFile:getValue("vehicle.palletFiller.platformAnimation#speed", 1)
    spec.platformAnimation.middleTime = self.xmlFile:getValue("vehicle.palletFiller.platformAnimation#middleTime", 0.5)
    spec.platformAnimation.automaticLift = self.xmlFile:getValue("vehicle.palletFiller.platformAnimation#automaticLift", false)
    spec.platformAnimation.lowerToUnload = self.xmlFile:getValue("vehicle.palletFiller.platformAnimation#lowerToUnload", false)
    spec.foldable = {}
    spec.foldable.minLimit = self.xmlFile:getValue("vehicle.palletFiller.foldable#minLimit", 0)
    spec.foldable.maxLimit = self.xmlFile:getValue("vehicle.palletFiller.foldable#maxLimit", 1)
    if self.isClient then
        spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.palletFiller.animationNodes", self.components, self, self.i3dMappings)
        spec.samples = {}
        spec.samples.move = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.palletFiller.sounds", "move", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    spec.texts = {}
    spec.texts.warningPalletFillerNoPalletAvailable = g_i18n:getText("warning_palletFillerNoPalletAvailable", PalletFiller.MOD_NAME)
    spec.dirtyFlag = self:getNextDirtyFlag()
    if not self.isServer then
        SpecializationUtil.removeEventListener(self, "onUpdate", PalletFiller)
    end
    if not self.isClient then
        SpecializationUtil.removeEventListener(self, "onUpdateTick", PalletFiller)
    end
end
function PalletFiller:onLoadFinished(savegame)
    local spec = self.spec_palletFiller
    if spec.palletRow.loadingDelay > 0 then
        if self.spec_combine ~= nil then
            self.spec_combine.loadingDelay = spec.palletRow.loadingDelay
            spec_combine.unloadingDelay = spec.palletRow.loadingDelay
            spec_combine.loadingDelaySlotsDelayedInsert = false
            spec_combine.loadingDelaySlots = {}
            local i = 1
            for i = i, spec_combine.loadingDelay / 1000 * 60 + 1 do
                spec_combine.loadingDelaySlots[i] = {
                    ["time"] = -math.huge,
                    ["fillLevelDelta"] = 0,
                    ["fillType"] = 0,
                    ["valid"] = false
                }
            end
        end
    end
    self:setAnimationTime(spec.platformAnimation.name, 1, true, false)
    self:setAnimationTime(spec.platformAnimation.name, 0, true, false)
    if savegame == nil or savegame.resetVehicles then
        self:setPalletFillerState(spec.state, true, true)
    else
        local spec_combine = savegame.key .. ".palletFiller"
        local state = PalletFillerState.loadFromXMLFile(savegame.xmlFile, spec_combine .. "#state")
        if state ~= nil then
            self:setPalletFillerState(state, true, true)
        end
        self:setPalletFillerDeflectorState(savegame.xmlFile:getValue(spec_combine .. "#deflectorState", spec.fillDeflectorAnimation.state), true)
        spec.objectsToLoad = {}
        savegame.xmlFile:iterate(spec_combine .. ".palletSlot", function(_, slotKey)
            -- upvalues: (copy) savegame, (copy) spec
            local objectToLoad = {
                ["slotIndex"] = savegame.xmlFile:getValue(slotKey .. "#slotIndex"),
                ["objectUniqueId"] = savegame.xmlFile:getValue(slotKey .. "#objectUniqueId")
            }
            if objectToLoad.slotIndex ~= nil and objectToLoad.objectUniqueId ~= nil then
                objectToLoad.translation = savegame.xmlFile:getValue(slotKey .. "#translation", nil, true)
                objectToLoad.rotation = savegame.xmlFile:getValue(slotKey .. "#rotation", nil, true)
                table.insert(spec.objectsToLoad, objectToLoad)
            end
        end)
    end
end
function PalletFiller:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_palletFiller
    PalletFillerState.saveToXMLFile(xmlFile, key .. "#state", spec.state)
    xmlFile:setValue(key .. "#deflectorState", spec.fillDeflectorAnimation.state)
    for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
        if palletSlot.object ~= nil then
            local slotKey = string.format("%s.palletSlot(%d)", key, i - 1)
            xmlFile:setValue(slotKey .. "#slotIndex", i)
            xmlFile:setValue(slotKey .. "#objectUniqueId", palletSlot.object:getUniqueId())
            xmlFile:setValue(slotKey .. "#translation", getTranslation(palletSlot.jointNode))
            xmlFile:setValue(slotKey .. "#rotation", getRotation(palletSlot.jointNode))
        end
    end
end
function PalletFiller:onDelete()
    local spec = self.spec_palletFiller
    local pickupTrigger = spec.pickupTrigger
    if pickupTrigger ~= nil then
        if pickupTrigger.node ~= nil then
            removeTrigger(pickupTrigger.node)
        end
        if pickupTrigger.triggeredObjects ~= nil then
            for objectId, _ in pairs(pickupTrigger.triggeredObjects) do
                local object = NetworkUtil.getObject(objectId)
                if object ~= nil and object.removeDeleteListener ~= nil then
                    object:removeDeleteListener(self, PalletFiller.onObjectDeleted)
                end
            end
            table.clear(pickupTrigger.triggeredObjects)
        end
    end
    if spec.samples ~= nil then
        g_soundManager:deleteSamples(spec.samples)
    end
    if spec.palletRow ~= nil then
        for objectId, _ in ipairs(spec.palletRow.palletSlots) do
            if _.object ~= nil then
                self:unloadPalletFillerPallet(_.object)
            end
        end
    end
end
function PalletFiller:onReadStream(streamId, _)
    self:setPalletFillerState(PalletFillerState.readStream(streamId), true, true)
    self:setPalletFillerDeflectorState(streamReadBool(streamId), true)
    for i, palletSlot in ipairs(self.spec_palletFiller.palletRow.palletSlots) do
        if streamReadBool(streamId) then
            palletSlot.object = NetworkUtil.readNodeObject(streamId)
        else
            palletSlot.object = nil
        end
        palletSlot.pendingObjectLoading = false
    end
end
function PalletFiller:onWriteStream(streamId, _)
    local spec = self.spec_palletFiller
    PalletFillerState.writeStream(streamId, spec.state)
    streamWriteBool(streamId, spec.fillDeflectorAnimation.state)
    for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
        if streamWriteBool(streamId, palletSlot.object ~= nil) then
            NetworkUtil.writeNodeObject(streamId, palletSlot.object)
        end
    end
end
function PalletFiller:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() and streamReadBool(streamId) then
        local spec = self.spec_palletFiller
        spec.palletRow.isMoving = streamReadBool(streamId)
        if spec.palletRow.isMoving then
            g_animationManager:startAnimations(spec.animationNodes)
            g_soundManager:playSample(spec.samples.move)
        else
            g_animationManager:stopAnimations(spec.animationNodes)
            g_soundManager:stopSample(spec.samples.move)
        end
        for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
            if streamReadBool(streamId) then
                palletSlot.objectId = NetworkUtil.readNodeObjectId(streamId)
                palletSlot.object = NetworkUtil.getObject(palletSlot.objectId)
                if palletSlot.object == nil then
                    self:raiseActive()
                else
                    palletSlot.objectId = nil
                    palletSlot.pendingObjectLoading = false
                end
            else
                palletSlot.object = nil
                palletSlot.pendingObjectLoading = false
            end
        end
        PalletFiller.updatePalletFillerDeflectorState(self)
        PalletFiller.updateActionEventTexts(self)
    end
end
function PalletFiller:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_palletFiller
        if streamWriteBool(streamId, bit32.band(dirtyMask, spec.dirtyFlag) ~= 0) then
            streamWriteBool(streamId, spec.palletRow.isMoving)
            for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
                if streamWriteBool(streamId, palletSlot.object ~= nil) then
                    NetworkUtil.writeNodeObject(streamId, palletSlot.object)
                end
            end
        end
    end
end
function PalletFiller:onUpdate(dt, _, _, _)
    local spec = self.spec_palletFiller
    if spec.objectsToLoad ~= nil and #spec.objectsToLoad > 0 then
        local i = #spec.objectsToLoad
        for i = i, 1, -1 do
            local objectToLoad = spec.objectsToLoad[i]
            local vehicle = g_currentMission.vehicleSystem:getVehicleByUniqueId(objectToLoad.objectUniqueId)
            if vehicle ~= nil then
                if not self:loadPalletFillerPallet(vehicle, objectToLoad) then
                    Logging.warning("Failed to load pallet object from savegame. UniqueId: %d SlotIndex: %d", objectToLoad.objectUniqueId, objectToLoad.slotIndex)
                end
                spec.objectsToLoad[i] = nil
            end
        end
    end
    if spec.state == PalletFillerState.LOADING and not self:getIsAnimationPlaying(spec.platformAnimation.name) then
        for objectToLoad, vehicle in pairs(spec.pickupTrigger.triggeredObjects) do
            local object = g_currentMission:getNodeObject(objectToLoad)
            if object ~= nil and (object:isa(Vehicle) and self.dynamicMountType == MountableObject.MOUNT_TYPE_NONE) then
                local allowPickup = true
                for _, palletSlot in ipairs(spec.palletRow.palletSlots) do
                    if palletSlot.object == object then
                        allowPickup = false
                        break
                    end
                    if palletSlot.interpolationTimer ~= 0 then
                        allowPickup = false
                        break
                    end
                end
                if allowPickup then
                    self:loadPalletFillerPallet(object)
                end
            end
            self:raiseActive()
        end
    end
    local fillStep = self:getPalletFillerFillStep()
    if fillStep ~= nil then
        spec.palletRow.currentTransZ = fillStep.transZ
        spec.palletRow.currentDischargeNodeIndex = fillStep.dischargeNodeIndex
        if self:getCurrentDischargeNodeIndex() ~= fillStep.dischargeNodeIndex then
            self:setCurrentDischargeNodeIndex(fillStep.dischargeNodeIndex)
        end
    end
    local palletsMoving = false
    local i = 0
    for allowPickup, palletSlot in ipairs(spec.palletRow.palletSlots) do
        if palletSlot.interpolationTimer == 0 then
            if palletSlot.object ~= nil then
                local alpha = spec.palletRow.currentTransZ + i
                if spec.state == PalletFillerState.UNLOADING and spec.palletRow.minTransZ ~= spec.palletRow.maxTransZ then
                    alpha = spec.palletRow.minTransZ - 0.1
                end
                local qStart, _, palletSlot = getTranslation(palletSlot.jointNode)
                local qy = alpha - palletSlot
                local qw = (qy > 0 and math.min or math.max)(palletSlot + math.sign(qy) * spec.palletRow.moveSpeed * dt, alpha)
                local qw = spec.palletRow.endRotLimit
                local tx = spec.palletRow.endTransLimit
                if spec.state == PalletFillerState.UNLOADING then
                    qw = spec.palletRow.unloadRotLimit
                    tx = spec.palletRow.unloadTransLimit
                end
                setTranslation(palletSlot.jointNode, 0, 0, qw)
                if palletSlot.jointIndex ~= nil then
                    local ty = qw[1]
                    local tz = qw[2]
                    local rlx = qw[3]
                    setJointRotationLimit(palletSlot.jointIndex, 0, true, -ty, ty)
                    setJointRotationLimit(palletSlot.jointIndex, 1, true, -tz, tz)
                    setJointRotationLimit(palletSlot.jointIndex, 2, true, -rlx, rlx)
                    local rly = tx[1]
                    local tlx = tx[3]
                    setJointTranslationLimit(palletSlot.jointIndex, 0, true, -rly, rly)
                    setJointTranslationLimit(palletSlot.jointIndex, 1, true, 0, tx[2])
                    setJointTranslationLimit(palletSlot.jointIndex, 2, true, -tlx, tlx)
                    setJointFrame(palletSlot.jointIndex, 0, palletSlot.jointNode)
                end
                i = i + spec.pallet.spacing
                if not palletsMoving then
                    palletsMoving = math.abs(qy) > 0.01
                end
                if spec.state == PalletFillerState.UNLOADING then
                    if spec.palletRow.minTransZ == spec.palletRow.maxTransZ then
                        if not self:getIsAnimationPlaying(spec.platformAnimation.name) then
                            self:unloadPalletFillerPallet(palletSlot.object)
                        end
                    elseif qw < spec.palletRow.minTransZ then
                        self:unloadPalletFillerPallet(palletSlot.object)
                    end
                end
            end
        elseif palletSlot.object == nil then
            palletSlot.interpolationTimer = 0
        else
            palletSlot.interpolationTimer = math.max(palletSlot.interpolationTimer - dt, 0)
            local alpha = 1 - palletSlot.interpolationTimer / spec.palletRow.pickupTime
            local _ = palletSlot.endQuaternion
            local palletSlot, qy, qz, qw = MathUtil.slerpQuaternionShortestPath(palletSlot.startQuaternion[1], palletSlot.startQuaternion[2], palletSlot.startQuaternion[3], palletSlot.startQuaternion[4], _[1], _[2], _[3], _[4], alpha)
            setQuaternion(palletSlot.jointNode, palletSlot, qy, qz, qw)
            local tx, ty, tz = MathUtil.vector3ArrayLerp(palletSlot.startTranslation, palletSlot.endTranslation, alpha)
            setTranslation(palletSlot.jointNode, tx, ty, tz)
            if palletSlot.jointIndex ~= nil then
                local rlx, rly, rlz = MathUtil.vector3ArrayLerp(spec.palletRow.startRotLimit, spec.palletRow.endRotLimit, alpha)
                setJointRotationLimit(palletSlot.jointIndex, 0, true, -rlx, rlx)
                setJointRotationLimit(palletSlot.jointIndex, 1, true, -rly, rly)
                setJointRotationLimit(palletSlot.jointIndex, 2, true, -rlz, rlz)
                local tlx, tly, tlz = MathUtil.vector3ArrayLerp(spec.palletRow.startTransLimit, spec.palletRow.endTransLimit, alpha)
                setJointTranslationLimit(palletSlot.jointIndex, 0, true, -tlx, tlx)
                setJointTranslationLimit(palletSlot.jointIndex, 1, true, 0, tly)
                setJointTranslationLimit(palletSlot.jointIndex, 2, true, -tlz, tlz)
                setJointFrame(palletSlot.jointIndex, 0, palletSlot.jointNode)
            end
            palletsMoving = true
        end
    end
    if spec.platformAnimation.automaticLift then
        local objectToLoad = 0
        for palletSlot, alpha in ipairs(spec.palletRow.palletSlots) do
            if alpha.interpolationTimer == 0 and alpha.object ~= nil then
            end
        end
        if spec.state == PalletFillerState.LOADING then
            if objectToLoad == #spec.palletRow.palletSlots then
                self:setPalletFillerState(PalletFillerState.IDLE)
            end
        elseif spec.state == PalletFillerState.UNLOADING and (objectToLoad == 0 and next(spec.pickupTrigger.triggeredObjects) == nil) then
            self:setPalletFillerState(PalletFillerState.IDLE)
        end
    end
    if palletsMoving ~= spec.palletRow.isMoving then
        spec.palletRow.isMoving = palletsMoving
        self:raiseDirtyFlags(spec.dirtyFlag)
        PalletFiller.updatePalletFillerDeflectorState(self)
        if self.isClient then
            if palletsMoving then
                g_animationManager:startAnimations(spec.animationNodes)
                g_soundManager:playSample(spec.samples.move)
                return
            end
            g_animationManager:stopAnimations(spec.animationNodes)
            g_soundManager:stopSample(spec.samples.move)
        end
    end
end
function PalletFiller:onUpdateTick(_, _, isActiveForInputIgnoreSelection, _)
    local spec = self.spec_palletFiller
    if isActiveForInputIgnoreSelection and (self:getIsTurnedOn() and spec.state == PalletFillerState.IDLE) then
        local freeCapacity = 0
        for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
            if palletSlot.object ~= nil and palletSlot.object.getFillUnitFreeCapacity ~= nil then
                freeCapacity = freeCapacity + palletSlot.object:getFillUnitFreeCapacity(1)
            end
        end
        if freeCapacity == 0 then
            g_currentMission:showBlinkingWarning(spec.texts.warningPalletFillerNoPalletAvailable, 250)
        end
    end
    for i, i in ipairs(spec.palletRow.palletSlots) do
        if i.objectId ~= nil then
            local palletSlot = NetworkUtil.getObject(i.objectId)
            if palletSlot == nil or not palletSlot:getIsSynchronized() then
                self:raiseActive()
            else
                i.object = palletSlot
                i.objectId = nil
                i.pendingObjectLoading = false
                PalletFiller.updateActionEventTexts(self)
            end
        end
    end
end
function PalletFiller:onFinishAnimation(name)
    if name == self.spec_palletFiller.platformAnimation.name then
        PalletFiller.updatePalletFillerDeflectorState(self)
    end
end
function PalletFiller:onFoldTimeChanged(_)
    PalletFiller.updateActionEventTexts(self)
end
function PalletFiller:loadPalletFillerPallet(object, data)
    local spec = self.spec_palletFiller
    for slotIndex, palletSlot in ipairs(spec.palletRow.palletSlots) do
        if data == nil and palletSlot.object == nil or data ~= nil and data.slotIndex == slotIndex then
            palletSlot.object = object
            if data == nil or data.translation == nil then
                setWorldTranslation(palletSlot.jointNode, getWorldTranslation(object.rootNode))
                setWorldRotation(palletSlot.jointNode, getWorldRotation(object.rootNode))
            else
                setTranslation(palletSlot.jointNode, data.translation[1], data.translation[2], data.translation[3])
                setRotation(palletSlot.jointNode, data.rotation[1], data.rotation[2], data.rotation[3])
            end
            local distance = calcDistanceFrom(palletSlot.jointNode, object.rootNode)
            local constr = JointConstructor.new()
            constr:setActors(self.rootNode, object.rootNode)
            constr:setJointTransforms(palletSlot.jointNode, object.rootNode)
            constr:setEnableCollision(true)
            local rlx = spec.palletRow.startRotLimit[1]
            local rly = spec.palletRow.startRotLimit[2]
            local rlz = spec.palletRow.startRotLimit[3]
            constr:setRotationLimit(0, -rlx, rlx)
            constr:setRotationLimit(1, -rly, rly)
            constr:setRotationLimit(2, -rlz, rlz)
            local tlx = spec.palletRow.startTransLimit[1]
            local tlz = spec.palletRow.startTransLimit[3]
            constr:setTranslationLimit(0, true, -tlx, tlx)
            constr:setTranslationLimit(1, true, 0, spec.palletRow.startTransLimit[2])
            constr:setTranslationLimit(2, true, -tlz, tlz)
            if data == nil then
                palletSlot.startQuaternion = { getQuaternion(palletSlot.jointNode) }
                local dx, _, dz = worldDirectionToLocal(getParent(palletSlot.jointNode), localDirectionToWorld(object.rootNode, 0, 0, 1))
                local yRot = MathUtil.vector2Normalize(dx, dz)
                if math.abs(yRot) < 1.5707963267948966 then
                    palletSlot.endQuaternion = { mathEulerToQuaternion(0, spec.palletRow.yRotation, 0) }
                else
                    palletSlot.endQuaternion = { mathEulerToQuaternion(0, spec.palletRow.yRotation + 3.141592653589793, 0) }
                end
                palletSlot.startTranslation = { getTranslation(palletSlot.jointNode) }
                palletSlot.endTranslation = { 0, 0, spec.palletRow.maxTransZ }
                palletSlot.interpolationDistance = distance
                palletSlot.interpolationTimer = spec.palletRow.pickupTime
            else
                palletSlot.interpolationDistance = distance
                palletSlot.interpolationTimer = 0
            end
            palletSlot.jointIndex = constr:finalize()
            object:setDynamicMountType(MountableObject.MOUNT_TYPE_DYNAMIC)
            self:raiseDirtyFlags(spec.dirtyFlag)
            PalletFiller.updateActionEventTexts(self)
            return true
        end
    end
    return false
end
function PalletFiller:unloadPalletFillerPallet(object)
    local spec = self.spec_palletFiller
    for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
        if palletSlot.object == object then
            palletSlot.object = nil
            palletSlot.interpolationTimer = 0
            if palletSlot.jointIndex ~= nil then
                removeJoint(palletSlot.jointIndex)
                palletSlot.jointIndex = nil
            end
            object:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)
            break
        end
    end
    self:raiseDirtyFlags(spec.dirtyFlag)
    PalletFiller.updateActionEventTexts(self)
end
function PalletFiller:buyPalletFillerPallets(noEventSend)
    if self.isServer then
        local palletSlotOffset = 0
        for i, palletSlot in ipairs(self.spec_palletFiller.palletRow.palletSlots) do
            setTranslation(palletSlot.jointNode, 0, 0, spec.palletRow.currentTransZ + palletSlotOffset)
            if palletSlot.object == nil then
                palletSlot.pendingObjectLoading = true
                local data = VehicleLoadingData.new()
                data:setFilename(spec.pallet.filename)
                data:setSpawnNode(palletSlot.jointNode)
                data:setIgnoreShopOffset(true)
                data:setPropertyState(VehiclePropertyState.OWNED)
                data:setOwnerFarmId(self:getOwnerFarmId())
                data:load(PalletFiller.onCreatePalletFinished, self, {
                    ["palletSlot"] = palletSlot
                })
            elseif palletSlot.jointIndex ~= nil then
                setJointFrame(palletSlot.jointIndex, 0, palletSlot.jointNode)
            end
            palletSlotOffset = palletSlotOffset + spec.pallet.spacing
        end
    else
        for i, i in ipairs(spec.palletRow.palletSlots) do
            if i.object == nil then
                i.pendingObjectLoading = true
            end
        end
        if noEventSend ~= true then
            g_client:getServerConnection():sendEvent(PalletFillerBuyPalletEvent.new(self))
        end
    end
end
function PalletFiller:onCreatePalletFinished(vehicles, vehicleLoadState, arguments)
    arguments.palletSlot.pendingObjectLoading = false
    if vehicleLoadState == VehicleLoadingState.OK and #vehicles >= 1 then
        local vehicle = vehicles[1]
        vehicle:removeFromPhysics()
        vehicle:addToPhysics()
        if not self:loadPalletFillerPallet(vehicle, {
            ["slotIndex"] = arguments.palletSlot.index,
            ["translation"] = { getTranslation(arguments.palletSlot.jointNode) },
            ["rotation"] = { getRotation(arguments.palletSlot.jointNode) }
        }) then
            vehicle:delete()
            return
        end
        g_currentMission:addMoney(-self.spec_palletFiller.pallet.storeItem.price, self:getOwnerFarmId(), MoneyType.PURCHASE_PALLETS)
        g_currentMission:addMoneyChange(-spec.pallet.storeItem.price, self:getOwnerFarmId(), MoneyType.PURCHASE_PALLETS, false)
        local hasFreeSlots = false
        for _, palletSlot in ipairs(spec.palletRow.palletSlots) do
            if not hasFreeSlots then
                hasFreeSlots = palletSlot.object ~= nil
            end
        end
        if not hasFreeSlots then
            g_currentMission:showMoneyChange(MoneyType.PURCHASE_PALLETS)
        end
    end
end
function PalletFiller:getCanChangePalletFillerState(newState)
    local spec = self.spec_palletFiller
    if spec.platformAnimation.automaticLift and spec.state == PalletFillerState.UNLOADING then
        return false
    end
    local hasPalletsLoaded = false
    local hasFreeSlots = false
    for _, palletSlot in ipairs(spec.palletRow.palletSlots) do
        if palletSlot.object == nil then
            hasFreeSlots = true
        else
            hasPalletsLoaded = true
        end
    end
    if spec.state == PalletFillerState.UNLOADING and hasPalletsLoaded then
        return false
    end
    if spec.state == PalletFillerState.IDLE and newState == PalletFillerState.UNLOADING then
        if not hasPalletsLoaded then
            return false
        end
        if spec.platformAnimation.lowerToUnload and not self:getIsLowered(true) then
            return false, string.format(g_i18n:getText("warning_lowerImplementFirst"), self:getName())
        end
    end
    if spec.state == PalletFillerState.IDLE and (newState == PalletFillerState.LOADING and not hasFreeSlots) then
        return false
    end
    if newState ~= PalletFillerState.IDLE then
        local foldAnimTime = self:getFoldAnimTime()
        if foldAnimTime < spec.foldable.minLimit or spec.foldable.maxLimit < foldAnimTime then
            return false
        end
    end
    return true
end
function PalletFiller:getCanBuyPalletFillerPallets()
    local spec = self.spec_palletFiller
    local foldAnimTime = self:getFoldAnimTime()
    if foldAnimTime < spec.foldable.minLimit or spec.foldable.maxLimit < foldAnimTime then
        return false, string.format(g_i18n:getText("warning_firstUnfoldTheTool"), self:getFullName())
    else
        return true
    end
end
function PalletFiller:setPalletFillerState(state, updateAnimations, noEventSend)
    local spec = self.spec_palletFiller
    spec.state = state
    local animationTime = self:getAnimationTime(spec.platformAnimation.name)
    local targetTime = spec.platformAnimation.middleTime
    local targetTime = spec.state == PalletFillerState.LOADING and 0 or (spec.state == PalletFillerState.UNLOADING and 1 or targetTime)
    if targetTime ~= animationTime then
        self:setAnimationStopTime(spec.platformAnimation.name, targetTime)
        self:playAnimation(spec.platformAnimation.name, spec.platformAnimation.speed * math.sign(targetTime - animationTime), animationTime, true)
        if updateAnimations == true then
            AnimatedVehicle.updateAnimationByName(self, spec.platformAnimation.name, 99999, true)
        end
    end
    PalletFiller.updateActionEventTexts(self)
    PalletFillerStateEvent.sendEvent(self, state, noEventSend)
end
function PalletFiller:updatePalletFillerDeflectorState()
    local spec = self.spec_palletFiller
    local deflectorState = (math.abs(self:getAnimationTime(spec.platformAnimation.name) - spec.platformAnimation.middleTime) > 0.01 or spec.palletRow.isMoving) and true or false
    if deflectorState ~= spec.fillDeflectorAnimation.state then
        self:setPalletFillerDeflectorState(deflectorState)
    end
end
function PalletFiller:setPalletFillerDeflectorState(state, updateAnimations)
    local spec = self.spec_palletFiller
    spec.fillDeflectorAnimation.state = state
    self:playAnimation(spec.fillDeflectorAnimation.name, spec.fillDeflectorAnimation.speed * (spec.fillDeflectorAnimation.state and 1 or -1), self:getAnimationTime(spec.fillDeflectorAnimation.name), true)
    if updateAnimations == true then
        AnimatedVehicle.updateAnimationByName(self, spec.fillDeflectorAnimation.name, 99999, true)
    end
end
function PalletFiller:getPalletFillerFillStep()
    local spec = self.spec_palletFiller
    for i, fillStep in ipairs(spec.palletRow.fillSteps) do
        local palletSlot = spec.palletRow.palletSlots[fillStep.palletIndex]
        if palletSlot.object ~= nil and palletSlot.object:getFillUnitFreeCapacity(1) > 0 then
            return fillStep
        end
    end
    for i, fillStep in ipairs(spec.palletRow.fillSteps) do
        if spec.palletRow.palletSlots[fillStep.palletIndex].object == nil then
            return fillStep
        end
    end
    return spec.palletRow.fillSteps[1]
end
function PalletFiller:getPalletFillerMovementDirection()
    local spec = self.spec_palletFiller
    return spec.state == PalletFillerState.LOADING and 1 or (spec.state == PalletFillerState.UNLOADING and -1 or 0)
end
function PalletFiller:getCanToggleDischargeToObject(superFunc)
    return false
end
function PalletFiller:getCanToggleDischargeToGround(superFunc)
    return false
end
function PalletFiller:removeFromPhysics(superFunc)
    local spec = self.spec_palletFiller
    if spec.palletRow ~= nil then
        for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
            if palletSlot.object ~= nil then
                self:unloadPalletFillerPallet(palletSlot.object)
            end
        end
    end
    return superFunc(self)
end
function PalletFiller:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
    local spec = self.spec_palletFiller
    if spec.state ~= PalletFillerState.IDLE then
        return false, g_i18n:getText("warning_palletFillerPlatformLowered")
    end
    if spec.palletRow ~= nil then
        for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
            if palletSlot.object ~= nil or palletSlot.pendingObjectLoading then
                return false, g_i18n:getText("warning_palletFillerNoEmpty")
            end
        end
    end
    return superFunc(self, direction, onAiTurnOn)
end
function PalletFiller:getFillLevelInformation(superFunc, display)
    superFunc(self, display)
    local fillType = nil
    local fillLevel = 0
    local capacity = 0
    for i, palletSlot in ipairs(self.spec_palletFiller.palletRow.palletSlots) do
        if palletSlot.object ~= nil and palletSlot.object.getFillUnitFillLevel ~= nil then
            local objectFillType = palletSlot.object:getFillUnitFillType(1)
            if objectFillType == FillType.UNKNOWN then
                objectFillType = fillType
            end
            fillLevel = fillLevel + palletSlot.object:getFillUnitFillLevel(1)
            capacity = capacity + palletSlot.object:getFillUnitCapacity(1)
        end
    end
    if capacity > 0 then
        display:addFillLevel(fillType or FillType.UNKNOWN, fillLevel, capacity)
    end
end
function PalletFiller:getHasObjectMounted(superFunc, object)
    if superFunc(self, object) then
        return true
    end
    for i, palletSlot in ipairs(self.spec_palletFiller.palletRow.palletSlots) do
        if palletSlot.object ~= nil then
            if palletSlot.object == object then
                return true
            end
            if palletSlot.object.getHasObjectMounted ~= nil and palletSlot.object:getHasObjectMounted(object) then
                return true
            end
        end
    end
    return false
end
function PalletFiller:getCanAIImplementContinueWork(superFunc, isTurning)
    local freeCapacity = 0
    local numLoadedPallets = 0
    for i, palletSlot in ipairs(self.spec_palletFiller.palletRow.palletSlots) do
        if palletSlot.object ~= nil and palletSlot.object.getFillUnitFillLevel ~= nil then
            freeCapacity = freeCapacity + palletSlot.object:getFillUnitFreeCapacity(1)
        end
    end
    if freeCapacity == 0 then
        if numLoadedPallets > 0 then
            return false, true, AIMessageErrorPalletsFull.new()
        else
            return false, true, AIMessageErrorNoPalletsLoaded.new()
        end
    else
        return superFunc(self, isTurning)
    end
end
function PalletFiller:verifyCombine(superFunc, fruitType, outputFillType, ...)
    local freeCapacity = 0
    for i, palletSlot in ipairs(self.spec_palletFiller.palletRow.palletSlots) do
        if palletSlot.object ~= nil and (palletSlot.object.getFillUnitFillType ~= nil and palletSlot.object:getIsSynchronized()) then
            if outputFillType ~= FillType.UNKNOWN and not palletSlot.object:getFillUnitAllowsFillType(1, outputFillType) then
                return nil, self, palletSlot.object:getFillUnitFillType(1)
            end
            freeCapacity = freeCapacity + palletSlot.object:getFillUnitFreeCapacity(1)
        end
    end
    if freeCapacity == 0 then
        return nil
    else
        return superFunc(self, fruitType, outputFillType, ...)
    end
end
function PalletFiller:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if isActiveForInputIgnoreSelection and self.isClient then
        local spec = self.spec_palletFiller
        self:clearActionEventsTable(spec.actionEvents)
        if spec.platformAnimation.name ~= nil then
            local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, PalletFiller.actionEventLowerPlatformLoad, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
            local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA4, self, PalletFiller.actionEventLowerPlatformUnload, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
            if spec.pallet.storeItem ~= nil then
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.PALLET_FILLER_BUY_PALLETS, self, PalletFiller.actionEventBuyPallets, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
                g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_palletFillerBuyPallets"))
            end
            PalletFiller.updateActionEventTexts(self)
        end
    end
end
function PalletFiller:updateActionEventTexts()
    local spec = self.spec_palletFiller
    local loadAction = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]
    if loadAction ~= nil then
        local text = nil
        if spec.state == PalletFillerState.IDLE then
            local isAllowed, warning = self:getCanChangePalletFillerState(PalletFillerState.LOADING)
            if isAllowed or warning ~= nil then
                text = g_i18n:getText("action_palletFillerLoad")
            end
        elseif spec.state == PalletFillerState.LOADING then
            local isAllowed, warning = self:getCanChangePalletFillerState(PalletFillerState.IDLE)
            if isAllowed or warning ~= nil then
                text = g_i18n:getText("action_palletFillerIdle")
            end
        end
        if text == nil then
            g_inputBinding:setActionEventActive(loadAction.actionEventId, false)
        else
            g_inputBinding:setActionEventText(loadAction.actionEventId, text)
            g_inputBinding:setActionEventActive(loadAction.actionEventId, true)
        end
    end
    local text = spec.actionEvents[InputAction.IMPLEMENT_EXTRA4]
    if text ~= nil then
        local isAllowed = nil
        if spec.state == PalletFillerState.IDLE then
            local warning, warning = self:getCanChangePalletFillerState(PalletFillerState.UNLOADING)
            if warning or warning ~= nil then
                isAllowed = g_i18n:getText("action_palletFillerUnload")
            end
        elseif spec.state == PalletFillerState.UNLOADING then
            local warning, warning = self:getCanChangePalletFillerState(PalletFillerState.IDLE)
            if warning or warning ~= nil then
                isAllowed = g_i18n:getText("action_palletFillerIdle")
            end
        end
        if isAllowed == nil then
            g_inputBinding:setActionEventActive(text.actionEventId, false)
        else
            g_inputBinding:setActionEventText(text.actionEventId, isAllowed)
            g_inputBinding:setActionEventActive(text.actionEventId, true)
        end
    end
    local isAllowed = spec.actionEvents[InputAction.PALLET_FILLER_BUY_PALLETS]
    if isAllowed ~= nil then
        local warning = 0
        for _, palletSlot in ipairs(spec.palletRow.palletSlots) do
            if palletSlot.object == nil then
            end
        end
        local warning = g_inputBinding
        warning:setActionEventActive(isAllowed.actionEventId, spec.state == PalletFillerState.IDLE and warning > 0)
    end
end
function PalletFiller:actionEventLowerPlatformLoad(_, _, _, _)
    local newState = self.spec_palletFiller.state == PalletFillerState.IDLE and PalletFillerState.LOADING or PalletFillerState.IDLE
    local isAllowed, warning = self:getCanChangePalletFillerState(newState)
    if isAllowed then
        self:setPalletFillerState(newState)
    elseif warning ~= nil then
        g_currentMission:showBlinkingWarning(warning, 2000)
    end
end
function PalletFiller:actionEventLowerPlatformUnload(_, _, _, _)
    local newState = self.spec_palletFiller.state == PalletFillerState.IDLE and PalletFillerState.UNLOADING or PalletFillerState.IDLE
    local isAllowed, warning = self:getCanChangePalletFillerState(newState)
    if isAllowed then
        self:setPalletFillerState(newState)
    elseif warning ~= nil then
        g_currentMission:showBlinkingWarning(warning, 2000)
    end
end
function PalletFiller:actionEventBuyPallets(_, _, _, _)
    local isAllowed, warning = self:getCanBuyPalletFillerPallets()
    if isAllowed then
        local numPallets = 0
        for _, palletSlot in ipairs(self.spec_palletFiller.palletRow.palletSlots) do
            if palletSlot.object == nil then
            end
        end
        YesNoDialog.show(function(_, yes)
            -- upvalues: (copy) self
            if yes then
                self:buyPalletFillerPallets()
            end
        end, self, string.format(g_i18n:getText("ui_palletFillerBuyPalletsText"), numPallets, g_i18n:formatMoney(spec.pallet.storeItem.price * numPallets)), self:getFullName())
    elseif warning ~= nil then
        g_currentMission:showBlinkingWarning(warning, 2000)
    end
end
function PalletFiller:onObjectDeleted(object)
    self.spec_palletFiller.pickupTrigger.triggeredObjects[object.rootNode] = nil
end