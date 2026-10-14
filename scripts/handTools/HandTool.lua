HandTool = {}
local HandTool_mt = Class(HandTool, Object)
InitStaticObjectClass(HandTool, "HandTool")
HandTool.DEFAULT_CROSSHAIR_COLOR = Color.new(1, 1, 1, 0.3)
HandTool.DEFAULT_CROSSHAIR_SIZE_PIXELS = 48
function HandTool.init()
    for name, spec in pairs(g_handToolSpecializationManager:getSpecializations()) do
        local classObj = ClassUtil.getClassObject(spec.className)
        if classObj ~= nil and rawget(classObj, "init") ~= nil then
            classObj.init()
        end
    end
end
function HandTool.postInit() end
function HandTool.registerXMLPaths()
    local xmlSchema = XMLSchema.new("handTool")
    HandTool.xmlSchema = xmlSchema
    g_storeManager:addSpeciesXMLSchema(StoreSpecies.HANDTOOL, HandTool.xmlSchema)
    g_handToolTypeManager:setXMLSchema(HandTool.xmlSchema)
    HandTool.xmlSchemaSounds = XMLSchema.new("handTool_sounds")
    HandTool.xmlSchemaSounds:setRootNodeName("sounds")
    HandTool.xmlSchema:addSubSchema(HandTool.xmlSchemaSounds, "sounds")
    StoreManager.registerStoreDataXMLPaths(xmlSchema, "handTool")
    I3DUtil.registerI3dMappingXMLPaths(xmlSchema, "handTool")
    xmlSchema:register(XMLValueType.STRING, "handTool.annotation", "Annotation", nil, true)
    xmlSchema:register(XMLValueType.BOOL, "handTool.base#canCrouch", "If the player can crouch while holding this tool", true, false)
    xmlSchema:register(XMLValueType.BOOL, "handTool.base#mustBeHeld", "True if this tool must be held, and cannot be put away; false otherwise", false, false)
    xmlSchema:register(XMLValueType.BOOL, "handTool.base#canBeSaved", "True if this tool can be saved; false otherwise", "Defaults to true, so that the tool will be saved", false)
    xmlSchema:register(XMLValueType.BOOL, "handTool.base#canBeDropped", "True if this tool can be dropped to inventory", "Defaults to true, so that the tool will be dropped", false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.base#runMultiplier", "The amount of run speed the player gains while running with this tool", true, false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.base#walkMultiplier", "The amount of walk speed the player gains while walking with this tool", true, false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.base#jumpMultiplier", "The amount of jump strength the player gains while walking with this tool", true, false)
    xmlSchema:register(XMLValueType.L10N_STRING, "handTool.base.actions#activate", "The text displayed for activating the tool", nil, false)
    xmlSchema:register(XMLValueType.STRING, "handTool.base.filename", "Hand tool i3d file", nil, false)
    xmlSchema:register(XMLValueType.L10N_STRING, "handTool.base.typeDesc", "Hand tool name localization string", nil, false)
    xmlSchema:register(XMLValueType.STRING, "handTool.base.sounds#filename", "The filename of the xml file defining the sounds of the tool", nil, false)
    xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.base.graphics#node", "The node containing all the graphical nodes of the tool", nil, false)
    xmlSchema:register(XMLValueType.BOOL, "handTool.base.graphics#lockFirstPerson", "True if first person mode should be forced, false for third person. A lack of this attribute does not lock the perspective at all", nil, false)
    xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.base.handNode#node", "The node used to position the hand tool when held in third person", nil, false)
    xmlSchema:register(XMLValueType.BOOL, "handTool.base.handNode#useLeftHand", "If the handtool should be attached to player left hand", nil, false)
    xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.base.firstPersonNode#node", "The node used to position the hand tool when held in first person", nil, false)
    xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.base.carried#targetNode", "The node of the player character that the tool is attached to when not held", nil, false)
    xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.base.carried#node", "The node used to position the hand tool when not held", nil, false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.base#mass", "Mass in kilograms", nil, false)
    xmlSchema:register(XMLValueType.STRING, "handTool#type", "The specialisation type of the hand tool", nil, true)
    xmlSchema:registerAutoCompletionDataSource("handTool#type", "$dataS/handToolTypes.xml", "handToolTypes.type#name")
    for _, specialisation in pairs(g_handToolSpecializationManager:getSpecializations()) do
        local specialisationClass = ClassUtil.getClassObject(specialisation.className)
        if specialisationClass ~= nil and specialisationClass.registerXMLPaths then
            specialisationClass.registerXMLPaths(xmlSchema)
            xmlSchema:setXMLSpecializationType()
        end
    end
end
function HandTool.registerSavegameXMLPaths(savegameXMLSchema)
    savegameXMLSchema:register(XMLValueType.STRING, "handTools.handTool(?)#filename", "The filename of the tool xml file", nil, true)
    savegameXMLSchema:register(XMLValueType.STRING, "handTools.handTool(?)#modName", "Name of mod")
    savegameXMLSchema:register(XMLValueType.STRING, "handTools.handTool(?)#uniqueId", "The unique id of the hand tool within the savegame", nil, true)
    savegameXMLSchema:register(XMLValueType.INT, "handTools.handTool(?)#farmId", "The id of the farm owning the tool", nil, true)
    savegameXMLSchema:register(XMLValueType.FLOAT, "handTools.handTool(?)#age", "The age of the hand tool", nil, true)
    savegameXMLSchema:register(XMLValueType.FLOAT, "handTools.handTool(?)#price", "The price of the hand tool", nil, true)
    savegameXMLSchema:register(XMLValueType.STRING, "handTools.handTool(?).holder#uniqueId", "Last holder", nil, true)
    for _, specialisation in pairs(g_handToolSpecializationManager:getSpecializations()) do
        local specialisationClass = ClassUtil.getClassObject(specialisation.className)
        if specialisationClass ~= nil and specialisationClass.registerSavegameXMLPaths then
            specialisationClass.registerSavegameXMLPaths(savegameXMLSchema, "handTools.handTool(?)")
        end
    end
end
function HandTool.registerFunctions(handToolType)
    SpecializationUtil.registerFunction(handToolType, "register", HandTool.register)
    SpecializationUtil.registerFunction(handToolType, "getShowInHandToolsOverview", HandTool.getShowInHandToolsOverview)
    SpecializationUtil.registerFunction(handToolType, "getNeedsSaving", HandTool.getNeedsSaving)
    SpecializationUtil.registerFunction(handToolType, "getCanBeDropped", HandTool.getCanBeDropped)
    SpecializationUtil.registerFunction(handToolType, "getHolder", HandTool.getHolder)
    SpecializationUtil.registerFunction(handToolType, "setHolder", HandTool.setHolder)
    SpecializationUtil.registerFunction(handToolType, "getIsCarried", HandTool.getIsCarried)
    SpecializationUtil.registerFunction(handToolType, "setCarryingPlayer", HandTool.setCarryingPlayer)
    SpecializationUtil.registerFunction(handToolType, "getCarryingPlayer", HandTool.getCarryingPlayer)
    SpecializationUtil.registerFunction(handToolType, "getPrice", HandTool.getPrice)
    SpecializationUtil.registerFunction(handToolType, "getSellPrice", HandTool.getSellPrice)
    SpecializationUtil.registerFunction(handToolType, "getIsActiveForInput", HandTool.getIsActiveForInput)
    SpecializationUtil.registerFunction(handToolType, "getIsHeld", HandTool.getIsHeld)
    SpecializationUtil.registerFunction(handToolType, "setCarryingPlayerShown", HandTool.setCarryingPlayerShown)
    SpecializationUtil.registerFunction(handToolType, "setCarryingPlayerHidden", HandTool.setCarryingPlayerHidden)
    SpecializationUtil.registerFunction(handToolType, "setCarryingPlayerStyleChanged", HandTool.setCarryingPlayerStyleChanged)
    SpecializationUtil.registerFunction(handToolType, "setCarryingPlayerExitedVehicle", HandTool.setCarryingPlayerExitedVehicle)
    SpecializationUtil.registerFunction(handToolType, "setCarryingPlayerEnteredVehicle", HandTool.setCarryingPlayerEnteredVehicle)
    SpecializationUtil.registerFunction(handToolType, "setCarryingPlayerPerspectiveChanged", HandTool.setCarryingPlayerPerspectiveChanged)
    SpecializationUtil.registerFunction(handToolType, "getName", HandTool.getName)
    SpecializationUtil.registerFunction(handToolType, "attachTool", HandTool.attachTool)
    SpecializationUtil.registerFunction(handToolType, "detachTool", HandTool.detachTool)
    SpecializationUtil.registerFunction(handToolType, "attachToolToHand", HandTool.attachToolToHand)
    SpecializationUtil.registerFunction(handToolType, "attachToolToCamera", HandTool.attachToolToCamera)
    SpecializationUtil.registerFunction(handToolType, "attachToolToCharacter", HandTool.attachToolToCharacter)
end
function HandTool.registerEvents(handToolType)
    SpecializationUtil.registerEvent(handToolType, "onPreLoad")
    SpecializationUtil.registerEvent(handToolType, "onLoad")
    SpecializationUtil.registerEvent(handToolType, "onPostLoad")
    SpecializationUtil.registerEvent(handToolType, "onLoadFinished")
    SpecializationUtil.registerEvent(handToolType, "onDelete")
    SpecializationUtil.registerEvent(handToolType, "onSave")
    SpecializationUtil.registerEvent(handToolType, "onRegistered")
    SpecializationUtil.registerEvent(handToolType, "onWriteStream")
    SpecializationUtil.registerEvent(handToolType, "onReadStream")
    SpecializationUtil.registerEvent(handToolType, "onWriteUpdateStream")
    SpecializationUtil.registerEvent(handToolType, "onReadUpdateStream")
    SpecializationUtil.registerEvent(handToolType, "onPreUpdate")
    SpecializationUtil.registerEvent(handToolType, "onUpdate")
    SpecializationUtil.registerEvent(handToolType, "onPostUpdate")
    SpecializationUtil.registerEvent(handToolType, "onUpdateTick")
    SpecializationUtil.registerEvent(handToolType, "onDraw")
    SpecializationUtil.registerEvent(handToolType, "onRegisterActionEvents")
    SpecializationUtil.registerEvent(handToolType, "onHandToolHolderChanged")
    SpecializationUtil.registerEvent(handToolType, "onHeldStart")
    SpecializationUtil.registerEvent(handToolType, "onHeldEnd")
    SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerStyleChanged")
    SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerShown")
    SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerHidden")
    SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerEnteredVehicle")
    SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerExitedVehicle")
    SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerChanged")
    SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerPerspectiveSwitched")
    SpecializationUtil.registerEvent(handToolType, "onDebugDraw")
end
function HandTool.new(isServer, isClient, customMt)
    -- upvalues: (copy) HandTool_mt
    local self = Object.new(isServer, isClient, customMt or HandTool_mt)
    self.finishedLoading = false
    self.isDeleted = false
    self.updateLoopIndex = -1
    self.sharedLoadRequestId = nil
    self.loadingState = HandToolLoadingState.OK
    self.loadingStep = SpecializationLoadStep.CREATED
    self.loadingTasks = {}
    self.readyForFinishLoading = false
    self.uniqueId = nil
    self.rootNode = nil
    self.graphicalNode = nil
    self.handNode = nil
    self.useLeftHand = false
    self.firstPersonNode = nil
    self.mass = 0
    self.actionEvents = {}
    self.carryingPlayer = nil
    self.isHeld = false
    self.holder = nil
    return self
end
function HandTool:setFilename(filename)
    self.configFileName = filename
    self.configFileNameClean = Utils.getFilenameInfo(filename, true)
    self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(filename)
end
function HandTool:setType(typeDef)
    SpecializationUtil.initSpecializationsIntoTypeClass(g_handToolTypeManager, typeDef, self)
end
function HandTool:setLoadCallback(loadCallbackFunction, loadCallbackFunctionTarget, loadCallbackFunctionArguments)
    self.loadCallbackFunction = loadCallbackFunction
    self.loadCallbackFunctionTarget = loadCallbackFunctionTarget
    self.loadCallbackFunctionArguments = loadCallbackFunctionArguments
end
function HandTool:loadCallback()
    g_currentMission.handToolSystem:removePendingHandToolLoad(self)
    if self.loadCallbackFunction ~= nil then
        self.loadCallbackFunction(self.loadCallbackFunctionTarget, self, self.loadingState, self.loadCallbackFunctionArguments)
        self.loadCallbackFunctionTarget = nil
        self.loadCallbackFunctionArguments = nil
    end
end
function HandTool:load(handToolLoadingData)
    self.handToolLoadingData = handToolLoadingData
    if not self.handToolLoadingData.canBeDropped then
        self.canBeDropped = false
    end
    g_currentMission.handToolSystem:addPendingHandToolLoad(self)
    self:setLoadingStep(SpecializationLoadStep.PRE_LOAD)
    if self.type == nil then
        Logging.xmlWarning(self.xmlFile, "Unable to find handtoolType")
        self:setLoadingState(HandToolLoadingState.ERROR)
        return self.loadingState
    else
        self.xmlFile = XMLFile.load("handToolXML", self.configFileName, HandTool.xmlSchema)
        self.savegame = handToolLoadingData.savegameData
        local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
        if storeItem ~= nil then
            self.brand = g_brandManager:getBrandByIndex(storeItem.brandIndex)
            self.lifetime = storeItem.lifetime
        end
        SpecializationUtil.copyTypeFunctionsInto(self.type, self)
        SpecializationUtil.createSpecializationEnvironments(self, function(specName, specEntryName)
            -- upvalues: (copy) self
            Logging.xmlError(self.xmlFile, "The handTool specialization \'%s\' could not be added because variable \'%s\' already exists!", specName, specEntryName)
            self:setLoadingState(HandToolLoadingState.ERROR)
        end)
        SpecializationUtil.raiseEvent(self, "onPreLoad", self.savegame)
        if self.loadingState == HandToolLoadingState.OK then
            self.i3dFilename = Utils.getFilename(self.xmlFile:getValue("handTool.base.filename"), self.baseDirectory)
            if self.i3dFilename == nil then
                self:loadFinished()
            else
                local isPathValid, invalidDesc = Utils.getPathIsValid(self.i3dFilename)
                if not isPathValid then
                    Logging.xmlWarning(self.xmlFile, "Filename contains %s, which are not allowed! (%s)", invalidDesc, "handTool.base.filename")
                end
                self:setLoadingStep(SpecializationLoadStep.AWAIT_I3D)
                self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, true, false, self.i3dFileLoaded, self)
            end
            return nil
        else
            Logging.xmlError(self.xmlFile, "Handtool pre-loading failed!")
            self.xmlFile:delete()
            return false
        end
    end
end
function HandTool:i3dFileLoaded(i3dNode, _, _, _)
    if i3dNode == 0 then
        self:setLoadingState(HandToolLoadingState.ERROR)
        Logging.xmlError(self.xmlFile, "Handtool i3d loading failed!")
        self:loadCallback()
    else
        self.i3dNode = i3dNode
        setVisibility(i3dNode, false)
        self:loadFinished()
    end
end
function HandTool:loadFinished()
    self:setLoadingState(HandToolLoadingState.OK)
    self:setLoadingStep(SpecializationLoadStep.LOAD)
    self.age = 0
    self:setOwnerFarmId(self.handToolLoadingData.ownerFarmId, true)
    self.mass = self.xmlFile:getValue("handTool.base#mass", 0)
    local savegame = self.savegame
    if savegame ~= nil then
        local uniqueId = savegame.xmlFile:getValue(savegame.key .. "#uniqueId", nil)
        if uniqueId ~= nil then
            self:setUniqueId(uniqueId)
        end
        local farmId = savegame.xmlFile:getValue(savegame.key .. "#farmId", AccessHandler.EVERYONE)
        if g_farmManager.mergedFarms ~= nil and g_farmManager.mergedFarms[farmId] ~= nil then
        end
        self:setOwnerFarmId(farmId, true)
    end
    self.price = self.handToolLoadingData.price
    if self.price == 0 or self.price == nil then
        local uniqueId = g_storeManager:getItemByXMLFilename(self.configFileName)
        self.price = StoreItemUtil.getDefaultPrice(uniqueId, self.configurations)
    end
    self.typeDesc = self.xmlFile:getValue("handTool.base.typeDesc", "TypeDescription", self.customEnvironment, true)
    self.activateText = self.xmlFile:getValue("handTool.base.actions#activate", "Activate", self.customEnvironment, true)
    if self.i3dNode ~= nil then
        self.rootNode = getChildAt(self.i3dNode, 0)
        self.components = {}
        I3DUtil.loadI3DComponents(self.i3dNode, self.components)
        self.i3dMappings = {}
        I3DUtil.loadI3DMapping(self.xmlFile, "handTool", self.rootLevelNodes, self.i3dMappings)
        for _, component in ipairs(self.components) do
            link(getRootNode(), component.node)
            setVisibility(component.node, false)
        end
        delete(self.i3dNode)
        self.i3dNode = nil
        self.graphicalNode = self.xmlFile:getValue("handTool.base.graphics#node", nil, self.components, self.i3dMappings)
        if self.graphicalNode == nil then
            Logging.xmlError(self.xmlFile, "Handtool is missing graphical node! Graphics will not work as intended!")
            self:setLoadingState(HandToolLoadingState.ERROR)
            self:loadCallback()
            return
        end
        self.graphicalNodeParent = getParent(self.graphicalNode)
        self.handNode = self.xmlFile:getValue("handTool.base.handNode#node", nil, self.components, self.i3dMappings)
        self.useLeftHand = self.xmlFile:getValue("handTool.base.handNode#useLeftHand", self.useLeftHand)
        self.firstPersonNode = self.xmlFile:getValue("handTool.base.firstPersonNode#node", nil, self.components, self.i3dMappings)
    end
    self.shouldLockFirstPerson = self.xmlFile:getValue("handTool.base.graphics#lockFirstPerson", nil)
    self.runMultiplier = self.xmlFile:getValue("handTool.base#runMultiplier", 1)
    self.walkMultiplier = self.xmlFile:getValue("handTool.base#walkMultiplier", 1)
    local farmId = self.xmlFile:getValue("handTool.base#jumpMultiplier", 1)
    self.jumpMultiplier = math.clamp(farmId, 0, 1.2)
    self.canCrouch = self.xmlFile:getValue("handTool.base#canCrouch", true)
    self.mustBeHeld = self.xmlFile:getValue("handTool.base#mustBeHeld", false)
    self.canBeSaved = self.xmlFile:getValue("handTool.base#canBeSaved", true)
    if not self.handToolLoadingData.isSaved then
        self.canBeSaved = false
    end
    self.canBeDropped = self.xmlFile:getValue("handTool.base#canBeDropped", true)
    if not self.handToolLoadingData.canBeDropped then
        self.canBeDropped = false
    end
    local uniqueId = self.xmlFile:getValue("handTool.base.sounds#filename", nil)
    local farmId = Utils.getFilename(uniqueId, self.baseDirectory)
    self.externalSoundsFile = XMLFile.loadIfExists("TempExternalSounds", farmId, HandTool.xmlSchemaSounds)
    SpecializationUtil.raiseEvent(self, "onLoad", self.xmlFile, self.baseDirectory)
    if self.loadingState == HandToolLoadingState.OK then
        self:setLoadingStep(SpecializationLoadStep.POST_LOAD)
        SpecializationUtil.raiseEvent(self, "onPostLoad", self.savegame)
        if self.loadingState == HandToolLoadingState.OK then
            if savegame ~= nil then
                self.age = savegame.xmlFile:getValue(savegame.key .. "#age", 0)
                self.price = savegame.xmlFile:getValue(savegame.key .. "#price", self.price)
            end
            local farmId = g_currentMission
            if farmId ~= nil and farmId.environment ~= nil then
                g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.periodChanged, self)
            end
            if #self.loadingTasks == 0 then
                self:onFinishedLoading()
            else
                self.readyForFinishLoading = true
                self:setLoadingStep(SpecializationLoadStep.AWAIT_SUB_I3D)
            end
        else
            Logging.xmlError(self.xmlFile, "HandTool post-loading failed!")
            self:loadCallback()
            return
        end
    else
        Logging.xmlError(self.xmlFile, "HandTool loading failed!")
        self:loadCallback()
        return
    end
end
function HandTool:onFinishedLoading()
    self:setLoadingStep(SpecializationLoadStep.FINISHED)
    SpecializationUtil.raiseEvent(self, "onLoadFinished", self.savegame)
    if self.isServer then
        self:setLoadingStep(SpecializationLoadStep.SYNCHRONIZED)
    end
    self.finishedLoading = true
    if g_currentMission.handToolSystem:addHandTool(self) then
        if self.handToolLoadingData.isRegistered then
            self:register()
        end
        local holder = self.handToolLoadingData.holder
        if holder == nil then
            local savegame = self.savegame
            if savegame ~= nil then
                self.pendingHolderUniqueId = savegame.xmlFile:getValue(savegame.key .. ".holder#uniqueId", nil)
            end
        elseif holder:getCanPickupHandTool(self) then
            self.pendingHolder = holder
        end
        g_currentMission:addOwnedItem(self)
        self.savegame = nil
        self.handToolLoadingData = nil
        self.xmlFile:delete()
        self.xmlFile = nil
        if self.externalSoundsFile ~= nil then
            self.externalSoundsFile:delete()
            self.externalSoundsFile = nil
        end
        self:loadCallback()
    else
        Logging.xmlError(self.xmlFile, "Failed to register handTool!")
        self:setLoadingState(HandToolLoadingState.ERROR)
        self:loadCallback()
    end
end
function HandTool:createLoadingTask(target)
    return SpecializationUtil.createLoadingTask(self, target)
end
function HandTool:finishLoadingTask(task)
    SpecializationUtil.finishLoadingTask(self, task)
end
function HandTool:setLoadingState(loadingState)
    if HandToolLoadingState.getName(loadingState) == nil then
        printCallstack()
        Logging.error("Invalid loading state \'%s\'!", loadingState)
    else
        self.loadingState = loadingState
    end
end
function HandTool:setLoadingStep(loadingStep)
    SpecializationUtil.setLoadingStep(self, loadingStep)
end
function HandTool:delete()
    if not self.isDeleted then
        g_currentMission:removeOwnedItem(self)
        g_messageCenter:unsubscribeAll(self)
        if self.holder ~= nil then
            self:setHolder(nil, true)
        end
        if self.sharedLoadRequestId ~= nil then
            g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
            self.sharedLoadRequestId = nil
        end
        SpecializationUtil.raiseEvent(self, "onDelete")
        if self.rootNode ~= nil and entityExists(self.rootNode) then
            delete(self.rootNode)
            self.rootNode = nil
        end
        g_currentMission.handToolSystem:removeHandTool(self)
        if self.externalSoundsFile ~= nil then
            self.externalSoundsFile:delete()
            self.externalSoundsFile = nil
        end
        HandTool:superClass().delete(self)
        self.isDeleted = true
    end
end
function HandTool:writeStream(streamId, connection)
    HandTool:superClass().writeStream(self, streamId, connection)
    streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.configFileName))
    streamWriteBool(streamId, self.canBeDropped)
end
function HandTool:readStream(streamId, connection, objectId)
    HandTool:superClass().readStream(self, streamId, connection, objectId)
    local filename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
    local canBeDropped = streamReadBool(streamId)
    if self.loadingStep == SpecializationLoadStep.CREATED then
        local data = HandToolLoadingData.new()
        data:setFilename(filename)
        data:setOwnerFarmId(self.ownerFarmId)
        data:setCanBeDropped(canBeDropped)
        data:loadHandToolOnClient(self, function(_, handTool, loadingState)
            if loadingState == HandToolLoadingState.OK then
                g_client:onObjectFinishedAsyncLoading(handTool)
            else
                Logging.error("Failed to load handtool on client")
                printCallstack()
            end
        end, nil)
    else
        Logging.error("Try to intialize loading of a handtool that is already loading!")
    end
end
function HandTool:postWriteStream(streamId, connection)
    local holder = self:getHolder()
    if streamWriteBool(streamId, holder ~= nil) then
        NetworkUtil.writeNodeObject(streamId, holder)
        streamWriteBool(streamId, self:getIsHeld())
    end
    SpecializationUtil.raiseEvent(self, "onWriteStream", streamId, connection)
end
function HandTool:postReadStream(streamId, connection)
    if streamReadBool(streamId) then
        self.pendingHolderObjectId = NetworkUtil.readNodeObjectId(streamId)
        self.isHoldingPending = streamReadBool(streamId)
        self:raiseActive()
    end
    SpecializationUtil.raiseEvent(self, "onReadStream", streamId, connection)
    self:setLoadingStep(SpecializationLoadStep.SYNCHRONIZED)
end
function HandTool:writeUpdateStream(streamId, connection, dirtyMask)
    SpecializationUtil.raiseEvent(self, "onWriteUpdateStream", streamId, connection, dirtyMask)
end
function HandTool:readUpdateStream(streamId, timestamp, connection)
    SpecializationUtil.raiseEvent(self, "onReadUpdateStream", streamId, timestamp, connection)
end
function HandTool:getNeedsSaving()
    return self.canBeSaved
end
function HandTool:getCanBeDropped()
    return self.canBeDropped
end
function HandTool:saveToXMLFile(xmlFile, key, usedModNames)
    xmlFile:setValue(key .. "#uniqueId", self.uniqueId)
    xmlFile:setValue(key .. "#farmId", self:getOwnerFarmId() or -1)
    xmlFile:setValue(key .. "#age", self.age)
    if self.holder ~= nil then
        xmlFile:setValue(key .. ".holder#uniqueId", self.holder:getUniqueId())
    end
    for id, spec in pairs(self.specializations) do
        if spec.saveToXMLFile ~= nil then
            spec.saveToXMLFile(self, xmlFile, key .. "." .. self.specializationNames[id], usedModNames)
        end
    end
end
function HandTool:getUniqueId()
    return self.uniqueId
end
function HandTool:setUniqueId(uniqueId)
    self.uniqueId = uniqueId
end
function HandTool:register(alreadySent)
    HandTool:superClass().register(self, alreadySent)
    SpecializationUtil.raiseEvent(self, "onRegistered", alreadySent)
end
function HandTool:getIsSynchronized()
    return self.loadingStep == SpecializationLoadStep.SYNCHRONIZED
end
function HandTool:getHolder()
    return self.holder
end
function HandTool:setHolder(holder, noEventSend)
    if holder == nil or holder ~= self.holder then
        HandToolSetHolderEvent.sendEvent(self, holder, noEventSend)
        if self.holder ~= nil then
            self.holder = nil
            self.holder:onDropHandTool(self)
        end
        local lastHolder = self.holder
        if holder ~= nil then
            if holder:onPickupHandTool(self) then
                self.holder = holder
                if self.rootNode ~= nil then
                    setVisibility(self.rootNode, true)
                end
            else
                holder = nil
            end
        end
        SpecializationUtil.raiseEvent(self, "onHandToolHolderChanged", holder, lastHolder)
    else
        Logging.devInfo("HandTool.setHolder: Tried to set same holder %q (%s) again for handtool %q (%s)", holder, holder:getUniqueId(), self.configFileName, self.uniqueId)
    end
end
function HandTool:update(dt)
    if self.pendingHolder ~= nil then
        self:setHolder(self.pendingHolder)
        self.pendingHolder = nil
    end
    if self.pendingHolderObjectId ~= nil then
        local holder = NetworkUtil.getObject(self.pendingHolderObjectId)
        if holder ~= nil then
            if holder:getCanPickupHandTool(self) then
                self:setHolder(holder, true)
                if self.isHoldingPending and self.carryingPlayer ~= nil then
                    self.carryingPlayer:setCurrentHandTool(self, true)
                end
            end
            self.pendingHolderObjectId = nil
            self.isHoldingPending = nil
        end
        self:raiseActive()
    end
    if self.pendingHolderUniqueId ~= nil then
        local holder = g_currentMission:getObjectByUniqueId(self.pendingHolderUniqueId)
        if holder ~= nil then
            self:setHolder(holder)
            self.pendingHolderUniqueId = nil
        end
        self:raiseActive()
    end
    SpecializationUtil.raiseEvent(self, "onPreUpdate", dt)
    SpecializationUtil.raiseEvent(self, "onUpdate", dt)
    SpecializationUtil.raiseEvent(self, "onPostUpdate", dt)
    if self:getIsHeld() then
        local holder = self:getCarryingPlayer()
        if holder ~= nil and holder:getIsControlled() then
            self:raiseActive()
        end
    end
end
function HandTool:updateTick(dt)
    SpecializationUtil.raiseEvent(self, "onUpdateTick", dt)
end
function HandTool:draw()
    SpecializationUtil.raiseEvent(self, "onDraw")
end
function HandTool:startHolding()
    self:raiseActive()
    self.isHoldStarting = true
    local player = self.carryingPlayer
    if player ~= nil and (player:getForceHandToolFirstPerson() and self.shouldLockFirstPerson ~= nil) then
        self.wasInFirstPerson = player.camera.isFirstPerson
        if self.shouldLockFirstPerson then
            player.camera:lockFirstPersonMode()
        else
            player.camera:lockThirdPersonMode()
        end
    end
    self.isHeld = true
    self:attachTool()
    SpecializationUtil.raiseEvent(self, "onHeldStart", player)
    self:clearActionEvents()
    if player ~= nil and player.isOwner then
        self:registerActionEvents()
    end
    self.isHoldStarting = false
end
function HandTool:stopHolding()
    self.isHoldEnding = true
    local carryingPlayer = self:getCarryingPlayer()
    if carryingPlayer ~= nil and (carryingPlayer:getForceHandToolFirstPerson() and self.shouldLockFirstPerson ~= nil) then
        carryingPlayer.camera:unlockSwitching()
        carryingPlayer.camera:switchToPerspective(self.wasInFirstPerson)
    end
    self.isHeld = false
    self:detachTool()
    SpecializationUtil.raiseEvent(self, "onHeldEnd")
    self:clearActionEvents()
    if carryingPlayer ~= nil and carryingPlayer.isOwner then
        self:registerActionEvents()
    end
    self.isHoldEnding = false
end
function HandTool:getIsCarried()
    return self.carryingPlayer ~= nil
end
function HandTool:setCarryingPlayer(player)
    self.carryingPlayer = player
    SpecializationUtil.raiseEvent(self, "onCarryingPlayerChanged", player, self.carryingPlayer)
    self:clearActionEvents()
    if player ~= nil and player.isOwner then
        self:registerActionEvents()
    end
end
function HandTool:getCarryingPlayer()
    return self.carryingPlayer
end
function HandTool:periodChanged()
    self.age = self.age + 1
end
function HandTool:getPrice()
    return self.price
end
function HandTool:getSellPrice()
    local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
    return HandTool.calculateSellPrice(storeItem, self.age, self:getPrice())
end
function HandTool:getDailyUpkeep()
    return 0
end
function HandTool.calculateSellPrice(_, age, price)
    return math.max(price * math.min(-0.1 * math.log(age / Environment.PERIODS_IN_YEAR) + 0.75, 0.8), price * 0.03)
end
function HandTool:getIsActiveForInput(mustBeHeld)
    local carryingPlayer = self:getCarryingPlayer()
    if carryingPlayer == nil or not carryingPlayer.isOwner then
        return false
    else
        return (not mustBeHeld or self:getIsHeld()) and true or false
    end
end
function HandTool:getIsHeld()
    if self:getIsCarried() then
        return self.isHeld
    else
        return false
    end
end
function HandTool:setCarryingPlayerShown()
    self:attachTool()
    local carryingPlayer = self:getCarryingPlayer()
    if carryingPlayer ~= nil and carryingPlayer.isOwner then
        self:clearActionEvents()
        self:registerActionEvents()
    end
    SpecializationUtil.raiseEvent(self, "onCarryingPlayerShown")
    self:raiseActive()
end
function HandTool:setCarryingPlayerHidden()
    self:detachTool()
    local carryingPlayer = self:getCarryingPlayer()
    if carryingPlayer ~= nil and carryingPlayer.isOwner then
        self:clearActionEvents(true)
    end
    SpecializationUtil.raiseEvent(self, "onCarryingPlayerHidden")
end
function HandTool:setCarryingPlayerStyleChanged()
    SpecializationUtil.raiseEvent(self, "onCarryingPlayerStyleChanged")
end
function HandTool:setCarryingPlayerEnteredVehicle()
    SpecializationUtil.raiseEvent(self, "onCarryingPlayerEnteredVehicle")
end
function HandTool:setCarryingPlayerExitedVehicle()
    SpecializationUtil.raiseEvent(self, "onCarryingPlayerExitedVehicle")
end
function HandTool:getName()
    local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
    if storeItem == nil then
        return nil
    else
        return storeItem.name
    end
end
function HandTool:getShowInHandToolsOverview()
    return self:getCanBeDropped()
end
function HandTool:setCarryingPlayerPerspectiveChanged(isFirstPerson)
    if not (self.isHoldEnding or self.isHoldStarting) then
        self:detachTool()
        self:attachTool()
        SpecializationUtil.raiseEvent(self, "onCarryingPlayerPerspectiveSwitched", isFirstPerson)
    end
end
function HandTool:attachTool()
    if self:getIsHeld() then
        if self.carryingPlayer:getForceHandToolFirstPerson() and self.carryingPlayer.camera.isFirstPerson then
            self:attachToolToCamera()
        else
            self:attachToolToHand()
        end
        if self.rootNode ~= nil then
            setVisibility(self.rootNode, true)
        end
    end
end
function HandTool:detachTool()
    if self.rootNode ~= nil then
        setVisibility(self.rootNode, false)
        unlink(self.rootNode)
    end
end
function HandTool:attachToolToHand()
    if not self:getIsHeld() or (self.carryingPlayer.graphicsComponent == nil or self.carryingPlayer.graphicsComponent.model == nil) then
        Logging.error("Invalid player configuration or tool is not held, cannot equip hand tool")
        return false
    end
    if self.rootNode == nil then
        return false
    end
    local playerModel = self.carryingPlayer.graphicsComponent.model
    if self.handNode ~= nil then
        local handNode = playerModel.thirdPersonRightHandNode
        if self.useLeftHand then
            handNode = playerModel.thirdPersonLeftHandNode
        end
        HandToolUtil.linkAndTransformRelativeToParent(self.rootNode, self.handNode, handNode)
        return true
    end
    Logging.warning("Handtool %s is missing hand node, using no offset!", self.typeName)
    link(playerModel.thirdPersonRightHandNode, self.rootNode)
    setTranslation(self.rootNode, 0, 0, 0)
    setRotation(self.rootNode, 0, 0, 0)
    return false
end
function HandTool:attachToolToCamera()
    if self:getIsHeld() and self.rootNode ~= nil then
        if self.firstPersonNode == nil then
            Logging.warning("Handtool %s is missing first person node, using no offset!", self.typeName)
            link(self:getCarryingPlayer().camera.pitchNode, self.rootNode)
            setTranslation(self.rootNode, 0, 0, 0)
            setRotation(self.rootNode, 0, 0, 0)
        else
            HandToolUtil.linkAndTransformRelativeToParent(self.rootNode, self.firstPersonNode, self:getCarryingPlayer().camera.pitchNode)
        end
    else
        return
    end
end
function HandTool:attachToolToCharacter() end
function HandTool:registerActionEvents()
    g_inputBinding:beginActionEventsModification(PlayerInputComponent.INPUT_CONTEXT_NAME)
    SpecializationUtil.raiseEvent(self, "onRegisterActionEvents")
    g_inputBinding:endActionEventsModification()
end
function HandTool:clearActionEvents(_)
    g_inputBinding:beginActionEventsModification(PlayerInputComponent.INPUT_CONTEXT_NAME)
    for inputAction, actionEvent in pairs(self.actionEvents) do
        g_inputBinding:removeActionEvent(actionEvent.actionEventId)
        self.actionEvents[inputAction] = nil
    end
    g_inputBinding:endActionEventsModification()
end
function HandTool:addActionEvent(inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, reportAnyDeviceCollision)
    local actionEvents = self.actionEvents
    if actionEvents[inputAction] == nil then
        local state, actionEventId, otherEvent = g_inputBinding:registerActionEvent(inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, true, reportAnyDeviceCollision)
        if state then
            actionEvents[inputAction] = {
                ["actionEventId"] = actionEventId,
                ["inputAction"] = inputAction
            }
            if not string.isNilOrWhitespace(customIconName) then
                g_inputBinding:setActionEventIcon(actionEventId, customIconName)
            end
        end
        return state, actionEventId, otherEvent
    end
    Logging.warning("Tried to bind two actions to input %s on tool %s!", inputAction, self.typeName)
end
function HandTool:createCrosshairOverlayFromFile(filename, sizePixels)
    local uiScale = sizePixels or HandTool.DEFAULT_CROSSHAIR_SIZE_PIXELS
    local uiScale = g_gameSettings:getValue("uiScale")
    local width, height = getNormalizedScreenValues(uiScale * uiScale, uiScale * uiScale)
    local crosshairFilename = Utils.getFilename(filename, self.baseDirectory)
    local crosshair = Overlay.new(crosshairFilename, 0.5, 0.5, width, height)
    crosshair:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
    crosshair:setColor(HandTool.DEFAULT_CROSSHAIR_COLOR:unpack())
    return crosshair
end
function HandTool.createCrosshairOverlay(_, identifier, sizePixels)
    local uiScale = sizePixels or HandTool.DEFAULT_CROSSHAIR_SIZE_PIXELS
    local uiScale = g_gameSettings:getValue("uiScale")
    local width, height = getNormalizedScreenValues(uiScale * uiScale, uiScale * uiScale)
    local crosshair = g_overlayManager:createOverlay(identifier, 0.5, 0.5, width, height)
    if crosshair == nil then
        return nil
    end
    crosshair:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
    crosshair:setColor(HandTool.DEFAULT_CROSSHAIR_COLOR:unpack())
    return crosshair
end
function HandTool:debugDraw(x, y, textSize)
    for _, spec in ipairs(self.eventListeners.onDebugDraw) do
        y = spec.onDebugDraw(self, x, y, textSize) or y
    end
    if self.rootNode ~= nil then
        local rootParentNode = getParent(self.rootNode)
        local rootNodePositionX, rootNodePositionY, _ = getWorldTranslation(self.rootNode)
        if rootParentNode ~= nil and entityExists(rootParentNode) then
            local spec, rootParentPositionY, rootParentPositionZ = getWorldTranslation(rootParentNode)
            DebugLine.renderBetweenPositions(rootNodePositionX, rootNodePositionY, _, spec, rootParentPositionY, rootParentPositionZ, Color.PRESETS.GREEN, false, "Tool>Parent")
            DebugUtil.drawDebugNode(rootParentNode, "root parent")
        end
        DebugUtil.drawDebugNode(self.rootNode, "root")
        if self.handNode ~= nil then
            DebugUtil.drawDebugNode(self.handNode, "hand")
            return y
        end
        if self.firstPersonNode ~= nil then
            DebugUtil.drawDebugNode(self.firstPersonNode, "fps")
        end
    end
    return y
end