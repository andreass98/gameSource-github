Placeable = {}
source("dataS/scripts/placeables/PlaceableNameEvent.lua")
local Placeable_mt = Class(Placeable, Object)
InitStaticObjectClass(Placeable, "Placeable")
Placeable.DEBUG_NETWORK = false
Placeable.DEBUG_NETWORK_UPDATE = false
Placeable.SELL_AND_DELETE = 0
Placeable.SELL_AND_SPECTATOR_FARM = 1
Placeable.DESTRUCTION = {
    ["SELL"] = 1,
    ["PER_NODE"] = 2
}
Placeable.UNDO_DURATION = 900000
g_xmlManager:addCreateSchemaFunction(function()
    Placeable.xmlSchema = XMLSchema.new("placeable")
    g_storeManager:addSpeciesXMLSchema(StoreSpecies.PLACEABLE, Placeable.xmlSchema)
    g_placeableTypeManager:setXMLSchema(Placeable.xmlSchema)
    Placeable.xmlSchemaSavegame = XMLSchema.new("savegame_placeables")
end)
function Placeable.onCreate(_, nodeId)
    local parent = getParent(nodeId)
    while parent ~= 0 do
        if getUserAttribute(parent, "onCreate") == "Placeable.onCreate" then
            Logging.i3dError(nodeId, "Node uses \'Placeable.onCreate\' script callback as a child of \'%s\' which already uses \'Placeable.onCreate\', ignoring this definition. Ensure placeables are not nested in the map!", I3DUtil.getNodeNameAndIndexPath(parent))
            return
        end
        parent = getParent(parent)
    end
    g_currentMission.placeableSystem:addMapPlaceableNode(nodeId)
end
function Placeable.registerEvents(placeableType)
    SpecializationUtil.registerEvent(placeableType, "onPreLoad")
    SpecializationUtil.registerEvent(placeableType, "onLoad")
    SpecializationUtil.registerEvent(placeableType, "onPostLoad")
    SpecializationUtil.registerEvent(placeableType, "onPreLoadFinished")
    SpecializationUtil.registerEvent(placeableType, "onLoadFinished")
    SpecializationUtil.registerEvent(placeableType, "onRegistered")
    SpecializationUtil.registerEvent(placeableType, "onPreDelete")
    SpecializationUtil.registerEvent(placeableType, "onDelete")
    SpecializationUtil.registerEvent(placeableType, "onSave")
    SpecializationUtil.registerEvent(placeableType, "onReadStream")
    SpecializationUtil.registerEvent(placeableType, "onWriteStream")
    SpecializationUtil.registerEvent(placeableType, "onReadUpdateStream")
    SpecializationUtil.registerEvent(placeableType, "onWriteUpdateStream")
    SpecializationUtil.registerEvent(placeableType, "onDirtyMaskCleared")
    SpecializationUtil.registerEvent(placeableType, "onPreFinalizePlacement")
    SpecializationUtil.registerEvent(placeableType, "onFinalizePlacement")
    SpecializationUtil.registerEvent(placeableType, "onPostFinalizePlacement")
    SpecializationUtil.registerEvent(placeableType, "onUpdate")
    SpecializationUtil.registerEvent(placeableType, "onUpdateTick")
    SpecializationUtil.registerEvent(placeableType, "onDraw")
    SpecializationUtil.registerEvent(placeableType, "onDrawDebug")
    SpecializationUtil.registerEvent(placeableType, "onHourChanged")
    SpecializationUtil.registerEvent(placeableType, "onMinuteChanged")
    SpecializationUtil.registerEvent(placeableType, "onDayChanged")
    SpecializationUtil.registerEvent(placeableType, "onPeriodChanged")
    SpecializationUtil.registerEvent(placeableType, "onWeatherChanged")
    SpecializationUtil.registerEvent(placeableType, "onFarmlandStateChanged")
    SpecializationUtil.registerEvent(placeableType, "onBuy")
    SpecializationUtil.registerEvent(placeableType, "onSell")
    SpecializationUtil.registerEvent(placeableType, "onOwnerChanged")
end
function Placeable.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "register", Placeable.register)
    SpecializationUtil.registerFunction(placeableType, "getPosition", Placeable.getPosition)
    SpecializationUtil.registerFunction(placeableType, "getIsOnFarmland", Placeable.getIsOnFarmland)
    SpecializationUtil.registerFunction(placeableType, "getFarmlandId", Placeable.getFarmlandId)
    SpecializationUtil.registerFunction(placeableType, "setPose", Placeable.setPose)
    SpecializationUtil.registerFunction(placeableType, "setOwnerFarmId", Placeable.setOwnerFarmId)
    SpecializationUtil.registerFunction(placeableType, "setLoadingStep", Placeable.setLoadingStep)
    SpecializationUtil.registerFunction(placeableType, "setLoadingState", Placeable.setLoadingState)
    SpecializationUtil.registerFunction(placeableType, "addToPhysics", Placeable.addToPhysics)
    SpecializationUtil.registerFunction(placeableType, "removeFromPhysics", Placeable.removeFromPhysics)
    SpecializationUtil.registerFunction(placeableType, "collectPickObjects", Placeable.collectPickObjects)
    SpecializationUtil.registerFunction(placeableType, "getNeedWeatherChanged", Placeable.getNeedWeatherChanged)
    SpecializationUtil.registerFunction(placeableType, "getNeedHourChanged", Placeable.getNeedHourChanged)
    SpecializationUtil.registerFunction(placeableType, "getNeedMinuteChanged", Placeable.getNeedMinuteChanged)
    SpecializationUtil.registerFunction(placeableType, "getNeedDayChanged", Placeable.getNeedDayChanged)
    SpecializationUtil.registerFunction(placeableType, "getName", Placeable.getName)
    SpecializationUtil.registerFunction(placeableType, "getImageFilename", Placeable.getImageFilename)
    SpecializationUtil.registerFunction(placeableType, "getCanBeRenamedByFarm", Placeable.getCanBeRenamedByFarm)
    SpecializationUtil.registerFunction(placeableType, "setName", Placeable.setName)
    SpecializationUtil.registerFunction(placeableType, "getPrice", Placeable.getPrice)
    SpecializationUtil.registerFunction(placeableType, "canBuy", Placeable.canBuy)
    SpecializationUtil.registerFunction(placeableType, "getCanBePlacedAt", Placeable.getCanBePlacedAt)
    SpecializationUtil.registerFunction(placeableType, "canBeSold", Placeable.canBeSold)
    SpecializationUtil.registerFunction(placeableType, "getDestructionMethod", Placeable.getDestructionMethod)
    SpecializationUtil.registerFunction(placeableType, "previewNodeDestructionNodes", Placeable.previewNodeDestructionNodes)
    SpecializationUtil.registerFunction(placeableType, "performNodeDestruction", Placeable.performNodeDestruction)
    SpecializationUtil.registerFunction(placeableType, "updateOwnership", Placeable.updateOwnership)
    SpecializationUtil.registerFunction(placeableType, "setOverlayColor", Placeable.setOverlayColor)
    SpecializationUtil.registerFunction(placeableType, "setOverlayColorNodes", Placeable.setOverlayColorNodes)
    SpecializationUtil.registerFunction(placeableType, "getDailyUpkeep", Placeable.getDailyUpkeep)
    SpecializationUtil.registerFunction(placeableType, "getSellPrice", Placeable.getSellPrice)
    SpecializationUtil.registerFunction(placeableType, "setPreviewPosition", Placeable.setPreviewPosition)
    SpecializationUtil.registerFunction(placeableType, "setPropertyState", Placeable.setPropertyState)
    SpecializationUtil.registerFunction(placeableType, "getPropertyState", Placeable.getPropertyState)
    SpecializationUtil.registerFunction(placeableType, "setVisibility", Placeable.setVisibility)
    SpecializationUtil.registerFunction(placeableType, "getIsSynchronized", Placeable.getIsSynchronized)
    SpecializationUtil.registerFunction(placeableType, "getIsPreplaced", Placeable.getIsPreplaced)
end
function Placeable.init()
    local schema = Placeable.xmlSchema
    schema:register(XMLValueType.STRING, "placeable#type", "Placeable type", nil, true)
    schema:registerAutoCompletionDataSource("placeable#type", "$dataS/placeableTypes.xml", "placeableTypes.type#name")
    schema:register(XMLValueType.STRING, "placeable.annotation", "Annotation", nil, false)
    schema:register(XMLValueType.STRING, "placeable.base.filename", "Placeable i3d file", nil, true)
    schema:register(XMLValueType.BOOL, "placeable.base.canBeRenamed", "Placeable can be renamed by player", false)
    schema:register(XMLValueType.BOOL, "placeable.base.boughtWithFarmland", "Placeable is bough with farmland", false)
    schema:register(XMLValueType.BOOL, "placeable.base.buysFarmland", "Placeable buys farmland it is placed on", false)
    schema:register(XMLValueType.FLOAT, "placeable.base.buysFarmland#priceScale", "Price scale for the farmland price", 1)
    schema:register(XMLValueType.BOOL, "placeable.base.canBeDeleted", "Placeable can be deleted by the player, set to false if it should be set farm 0 on sell instead", true)
    StoreManager.registerStoreDataXMLPaths(schema, "placeable")
    I3DUtil.registerI3dMappingXMLPaths(schema, "placeable")
    local savegameSchema = Placeable.xmlSchemaSavegame
    savegameSchema:register(XMLValueType.BOOL, "placeables.placeable(?)#isDeleted", "If the preplaced placeable is deleted in the savegame")
    savegameSchema:register(XMLValueType.BOOL, "placeables.placeable(?)#isPreplaced", "If the placeable is preplaced in the map")
    savegameSchema:register(XMLValueType.STRING, "placeables.placeable(?)#uniqueId", "Placeable\'s unique id")
    savegameSchema:register(XMLValueType.BOOL, "placeables#loadAnyFarmInSingleplayer", "Load any farm in singleplayer. Causes any placeable with any farmId to be loaded.", false)
    savegameSchema:register(XMLValueType.INT, "placeables#version", "Version of map placeables file")
    savegameSchema:register(XMLValueType.STRING, "placeables.placeable(?)#name", "Custom name set by player to be used instead of store item name")
    savegameSchema:register(XMLValueType.STRING, "placeables.placeable(?)#nameL10nKey", "custom l10n key for name set in preplaced/default placeables xml")
    savegameSchema:register(XMLValueType.STRING, "placeables.placeable(?).customImage#filename", "Path to a custom image file")
    savegameSchema:register(XMLValueType.VECTOR_TRANS, "placeables.placeable(?)#position", "Position")
    savegameSchema:register(XMLValueType.VECTOR_ROT, "placeables.placeable(?)#rotation", "Rotation")
    savegameSchema:register(XMLValueType.STRING, "placeables.placeable(?)#filename", "Path to xml filename")
    savegameSchema:register(XMLValueType.FLOAT, "placeables.placeable(?)#age", "Age of placeable in months.", 0)
    savegameSchema:register(XMLValueType.FLOAT, "placeables.placeable(?)#price", "Price of placeable")
    savegameSchema:register(XMLValueType.INT, "placeables.placeable(?)#farmId", "Owner farmland", 0)
    savegameSchema:register(XMLValueType.BOOL, "placeables.placeable(?)#defaultFarmProperty", "Is property of default farm. Causes object to be removed on non-starter games.", false)
    savegameSchema:register(XMLValueType.BOOL, "placeables.placeable(?)#canBeDeletedOverwrite", "Placeable can be deleted", false)
    savegameSchema:register(XMLValueType.BOOL, "placeables.placeable(?)#boughtWithFarmlandOverwrite", "Placeable is bought with farmland overwritten by savegame", false)
    savegameSchema:register(XMLValueType.STRING, "placeables.placeable(?)#modName", "Name of mod")
    savegameSchema:register(XMLValueType.INT, "placeables.placeable(?)#sinceVersion", "Version of xml file when this placeable was added. Will cause placeable to appear on older, existing saves")
    savegameSchema:register(XMLValueType.STRING, "placeables.placeable(?)#tourId", "Tour id")
    for name, spec in pairs(g_placeableSpecializationManager:getSpecializations()) do
        local classObj = ClassUtil.getClassObject(spec.className)
        if classObj ~= nil then
            if rawget(classObj, "registerXMLPaths") then
                classObj.registerXMLPaths(schema, "placeable")
            end
            if rawget(classObj, "registerSavegameXMLPaths") then
                classObj.registerSavegameXMLPaths(savegameSchema, "placeables.placeable(?)" .. "." .. name)
            end
        end
    end
    g_storeManager:addSpecType("placeableSlots", "shopListAttributeIconSlots", nil, Placeable.getSpecValueSlots, StoreSpecies.PLACEABLE)
    g_placeableConfigurationManager:addConfigurationType("color", g_i18n:getText("configuration_color"), nil, PlaceableConfigurationItemColor)
end
function Placeable.postInit()
    local configurations = g_placeableConfigurationManager:getConfigurations()
    for _, configuration in pairs(configurations) do
        if configuration.itemClass.registerXMLPaths ~= nil then
            configuration.itemClass.registerXMLPaths(Placeable.xmlSchema, configuration.configurationsKey, configuration.configurationKey .. "(?)")
        end
        if configuration.itemClass.registerSavegameXMLPaths ~= nil then
            configuration.itemClass.registerSavegameXMLPaths(Placeable.xmlSchemaSavegame, "placeables.placeable(?).configuration(?)")
            configuration.itemClass.registerSavegameXMLPaths(schemaSavegame, "placeables.placeable(?).boughtConfiguration(?)")
        end
    end
end
function Placeable.new(isServer, isClient, customMt)
    -- upvalues: (copy) Placeable_mt
    local self = Object.new(isServer, isClient, customMt or Placeable_mt)
    self.finishedLoading = false
    self.rootNode = nil
    self.loadingState = PlaceableLoadingState.OK
    self.loadingStep = SpecializationLoadStep.CREATED
    self.isDeleting = false
    self.isDeleted = false
    self.isLoadedFromSavegame = false
    self.loadingTasks = {}
    self.readyForFinishLoading = false
    self.propertyState = PlaceablePropertyState.OWNED
    self.age = 0
    self.price = 0
    self.pickObjects = {}
    self.undoTimer = 0
    self.uniqueId = nil
    return self
end
function Placeable:setFilename(filename)
    self.configFileName = filename
    self.configFileNameClean = Utils.getFilenameInfo(filename, true)
    self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(filename)
end
function Placeable:setConfigurations(configurations, boughtConfigurations, configurationData)
    self.configurations = configurations
    self.boughtConfigurations = boughtConfigurations
    self.configurationData = configurationData or self.configurationData
    if self.configurationData == nil then
        self.configurationData = {}
    end
    self.sortedConfigurationNames = {}
    for configName, _ in pairs(self.configurations) do
        table.insert(self.sortedConfigurationNames, configName)
    end
    table.sort(self.sortedConfigurationNames, function(a, b)
        return a < b
    end)
end
function Placeable:setType(typeDef)
    local configItem = assertWithCallstack
    local configType = self.configFileName ~= nil
    configItem(configType, "Setting placeable type without setting a filename previously. Call \'setFilename\' first!")
    if self.configurations ~= nil then
        local configItem = ConfigurationUtil.getConfigItemByConfigId(self.configFileName, "placeableType", self.configurations.placeableType)
        if configItem ~= nil and configItem.placeableType ~= nil then
            local configType = g_placeableTypeManager:getTypeByName(configItem.placeableType, self.customEnvironment)
            if configType == nil then
                Logging.warning("Unknown placeable type \'%s\' in configuration for \'%s\'", configItem.placeableType, self.configFileName)
            else
                typeDef = configType
            end
        end
    end
    SpecializationUtil.initSpecializationsIntoTypeClass(g_placeableTypeManager, typeDef, self)
end
function Placeable:setLoadCallback(loadCallbackFunction, loadCallbackFunctionTarget, loadCallbackFunctionArguments)
    self.loadCallbackFunction = loadCallbackFunction
    self.loadCallbackFunctionTarget = loadCallbackFunctionTarget
    self.loadCallbackFunctionArguments = loadCallbackFunctionArguments
end
function Placeable:loadCallback()
    if self.loadCallbackFunction ~= nil then
        self.loadCallbackFunction(self.loadCallbackFunctionTarget, self, self.loadingState, self.loadCallbackFunctionArguments)
        self.loadCallbackFunctionTarget = nil
        self.loadCallbackFunctionArguments = nil
    end
end
function Placeable:load(placeableLoadingData)
    self.placeableLoadingData = placeableLoadingData
    self:setLoadingStep(SpecializationLoadStep.PRE_LOAD)
    if self.type == nil then
        Logging.xmlWarning(self.xmlFile, "Unable to find placeableType \'%s\'", self.typeName)
        self:setLoadingState(PlaceableLoadingState.ERROR)
        return self.loadingState
    end
    self.xmlFile = XMLFile.load("placeableXml", self.configFileName, Placeable.xmlSchema)
    self.savegame = placeableLoadingData.savegameData
    self.storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
    if self.storeItem ~= nil then
        self.brand = g_brandManager:getBrandByIndex(self.storeItem.brandIndex)
        self.lifetime = self.storeItem.lifetime
    end
    SpecializationUtil.copyTypeFunctionsInto(self.type, self)
    local item = g_storeManager:getItemByXMLFilename(self.configFileName)
    if item ~= nil and item.configurations ~= nil then
        if item.configurationSets ~= nil and (#item.configurationSets > 0 and not ConfigurationUtil.getConfigurationsMatchConfigSets(self.configurations, item.configurationSets)) then
            local closestSet, closestSetMatches = ConfigurationUtil.getClosestConfigurationSet(self.configurations, item.configurationSets)
            if closestSet ~= nil then
                for configName, index in pairs(closestSet.configurations) do
                    self.configurations[configName] = index
                end
                Logging.xmlInfo(self.xmlFile, "Savegame configurations do not match the configuration sets! Apply closest configuration set \'%s\' with %d matching configurations.", closestSet.name, closestSetMatches)
            end
        end
        for configName, _ in pairs(item.configurations) do
            local configName = StoreItemUtil.getDefaultConfigId(item, configName)
            if self.configurations[configName] == nil then
                ConfigurationUtil.setConfiguration(self, configName, configName)
            end
            ConfigurationUtil.addBoughtConfiguration(g_placeableConfigurationManager, self, configName, configName)
        end
        for configName, _ in pairs(self.configurations) do
            if item.configurations[configName] == nil then
                Logging.xmlWarning(self.xmlFile, "Configurations are not present anymore. Ignoring this configuration (%s)!", configName)
                self.configurations[configName] = nil
                self.boughtConfigurations[configName] = nil
            else
                local configName = StoreItemUtil.getDefaultConfigId(item, configName)
                if #item.configurations[configName] < _ then
                    Logging.xmlWarning(self.xmlFile, "Configuration with index \'%d\' is not present anymore. Using default configuration instead!", _)
                    if self.boughtConfigurations[configName] ~= nil then
                        self.boughtConfigurations[configName][_] = nil
                        if next(self.boughtConfigurations[configName]) == nil then
                            self.boughtConfigurations[configName] = nil
                        end
                    end
                    ConfigurationUtil.setConfiguration(self, configName, configName)
                else
                    ConfigurationUtil.addBoughtConfiguration(g_placeableConfigurationManager, self, configName, _)
                end
            end
        end
    end
    SpecializationUtil.createSpecializationEnvironments(self, function(specName, specEntryName)
        -- upvalues: (copy) self
        Logging.xmlError(self.xmlFile, "The placeable specialization \'%s\' could not be added because variable \'%s\' already exists!", specName, specEntryName)
        self:setLoadingState(PlaceableLoadingState.ERROR)
    end)
    SpecializationUtil.raiseEvent(self, "onPreLoad", self.savegame)
    if self.loadingState ~= PlaceableLoadingState.OK then
        Logging.xmlError(self.xmlFile, "Placeable pre-loading failed!")
        self.xmlFile:delete()
        return false
    end
    ConfigurationUtil.raiseConfigurationItemEvent(self, "onPreLoad")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.filename", "placeable.base.filename")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.dayNightObjects", "Visibility Condition-Tab in GIANTS Editor / Exporter")
    self.preplacedIndex = placeableLoadingData:getPreplacedIndex()
    local closestSet = self.preplacedIndex ~= nil
    self.isPreplaced = closestSet
    self.customImageFilename = nil
    self.i3dFilename = Utils.getFilename(self.xmlFile:getValue("placeable.base.filename"), self.baseDirectory)
    if self.isPreplaced then
        self.i3dFilename = placeableLoadingData.customI3DFilename or self.i3dFilename
    end
    if self.i3dFilename ~= nil then
        local closestSet, closestSetMatches = Utils.getPathIsValid(self.i3dFilename)
        if not closestSet then
            Logging.xmlWarning(self.xmlFile, "Filename contains %s, which are not allowed! (%s)", closestSetMatches, "placeable.base.filename")
        end
    end
    self:setLoadingStep(SpecializationLoadStep.AWAIT_I3D)
    if self.isPreplaced then
        local closestSet = g_currentMission.placeableSystem:getPreplacedNodeByIndex(self.preplacedIndex)
        if closestSet == nil then
            Logging.xmlError(self.xmlFile, "Placeable loading failed. Preplaced node not defined!")
            self.xmlFile:delete()
            return false
        end
        removeFromPhysics(closestSet)
        self:i3dFileLoaded(closestSet, LoadI3DFailedReason.NONE, nil, nil)
    else
        self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, true, false, self.i3dFileLoaded, self)
    end
    return true
end
function Placeable:i3dFileLoaded(i3dNode, _, _, _)
    if i3dNode == 0 then
        self:setLoadingState(PlaceableLoadingState.ERROR)
        Logging.xmlError(self.xmlFile, "Placeable i3d loading failed!")
        self:loadCallback()
        return
    else
        self.i3dNode = i3dNode
        self.rootNode = self.i3dNode
        if self.isDeleted then
            self:setLoadingState(PlaceableLoadingState.CANCELED)
            self:loadCallback()
        else
            g_asyncTaskManager:addTask(function()
                -- upvalues: (copy) self
                self:loadFinished()
            end)
        end
    end
end
function Placeable:loadFinished()
    self:setLoadingState(PlaceableLoadingState.OK)
    self:setLoadingStep(SpecializationLoadStep.LOAD)
    local savegame = self.savegame
    self.age = 0
    self.propertyState = self.placeableLoadingData.propertyState
    self:setOwnerFarmId(self.placeableLoadingData.ownerFarmId, true)
    if savegame == nil then
        if self.isPreplaced then
            self:setUniqueId((self.placeableLoadingData:getUniqueId()))
        end
    else
        local uniqueId = savegame.xmlFile:getValue(savegame.key .. "#uniqueId", nil)
        if uniqueId ~= nil then
            self:setUniqueId(uniqueId)
        end
        if not savegame.ignoreFarmId then
            local farmId = savegame.xmlFile:getValue(savegame.key .. "#farmId", AccessHandler.EVERYONE)
            if g_farmManager.mergedFarms ~= nil and g_farmManager.mergedFarms[farmId] ~= nil then
            end
            self:setOwnerFarmId(farmId, true)
        end
        self.tourId = nil
        local farmId = savegame.xmlFile:getValue(savegame.key .. "#tourId")
        if farmId ~= nil then
            self.tourId = farmId
            g_guidedTourManager:addPlaceable(self, self.tourId)
        end
    end
    self.price = self.placeableLoadingData.price
    if self.price == 0 or self.price == nil then
        self.price = StoreItemUtil.getDefaultPrice(self.storeItem, self.configurations)
    end
    if self.rootNode == nil or not entityExists(self.rootNode) then
        Logging.xmlError(self.xmlFile, "Placeable rootnode was already deleted!")
        self:setLoadingState(PlaceableLoadingState.ERROR)
        self:loadCallback()
        return
    else
        self.components = {}
        I3DUtil.loadI3DComponents(self.i3dNode, self.components)
        if not self.isPreplaced then
            link(getRootNode(), self.i3dNode)
        end
        self.i3dNode = nil
        if self.numComponents == 0 then
            Logging.xmlWarning(self.xmlFile, "No components defined for placeable!")
            self:setLoadingState(PlaceableLoadingState.ERROR)
            self:loadCallback()
            return
        else
            self.i3dMappings = {}
            I3DUtil.loadI3DMapping(self.xmlFile, "placeable", self.components, self.i3dMappings)
            if self.placeableLoadingData:applyPositionData(self) then
                self.canBeRenamed = self.xmlFile:getValue("placeable.base.canBeRenamed", false)
                self.canBeDeleted = self.xmlFile:getValue("placeable.base.canBeDeleted", true)
                self.boughtWithFarmland = self.xmlFile:getValue("placeable.base.boughtWithFarmland", false)
                self.buysFarmland = self.xmlFile:getValue("placeable.base.buysFarmland", false)
                self.buysFarmlandPriceScale = self.xmlFile:getValue("placeable.base.buysFarmland#priceScale", 1)
                ConfigurationUtil.raiseConfigurationItemEvent(self, "onLoad")
                SpecializationUtil.raiseEvent(self, "onLoad", savegame)
                if self.loadingState == PlaceableLoadingState.OK then
                    self:setLoadingStep(SpecializationLoadStep.POST_LOAD)
                    SpecializationUtil.raiseEvent(self, "onPostLoad", savegame)
                    if self.loadingState == PlaceableLoadingState.OK then
                        ConfigurationUtil.raiseConfigurationItemEvent(self, "onPostLoad")
                        SpecializationUtil.raiseEvent(self, "onPreLoadFinished", self.savegame)
                        self:setVisibility(false)
                        if not self.isPreplaced then
                            self:removeFromPhysics()
                        end
                        if #self.loadingTasks == 0 then
                            self:onFinishedLoading()
                        else
                            self.readyForFinishLoading = true
                            self:setLoadingStep(SpecializationLoadStep.AWAIT_SUB_I3D)
                        end
                        if StartParams.getIsSet("scriptDebug") then
                            g_debugManager:addDrawable(self)
                        end
                    else
                        Logging.xmlError(self.xmlFile, "Placeable post-loading failed!")
                        self:loadCallback()
                    end
                else
                    Logging.xmlError(self.xmlFile, "Placeable loading failed!")
                    self:loadCallback()
                    return
                end
            else
                self:setLoadingState(PlaceableLoadingState.NO_SPACE)
                self:loadCallback()
                return
            end
        end
    end
end
function Placeable:onFinishedLoading()
    if self.propertyState == PlaceablePropertyState.CONSTRUCTION_PREVIEW then
        I3DUtil.iterateRecursively(self.rootNode, function(node)
            if getHasClassId(node, ClassIds.SHAPE) and getIsTerrainDecal(node) then
                setIsTerrainDecal(node, false)
                setIsNonRenderable(node, false)
            end
        end)
    end
    self:setVisibility(true)
    if self.isServer and self.savegame ~= nil then
        if getXMLString(self.savegame.xmlFile.handle, self.savegame.key .. "#mapBoundId") ~= nil then
            Logging.xmlWarning(self.savegame.xmlFile, "Attribute \'mapBoundId\' is not supported anymore for \'%s\'. Use \'isPreplaced\' and \'uniqueId\' instead!", self.savegame.key)
        end
        self.isLoadingFromSavegameXML = true
        for id, spec in pairs(self.specializations) do
            if spec.loadFromXMLFile ~= nil then
                spec.loadFromXMLFile(self, self.savegame.xmlFile, self.savegame.key .. "." .. self.specializationNames[id], self.savegame.reset)
            end
        end
        self.isLoadingFromSavegameXML = false
        self.boughtWithFarmlandSavegameOverwrite = self.savegame.xmlFile:getValue(self.savegame.key .. "#boughtWithFarmlandOverwrite") or self.boughtWithFarmlandSavegameOverwrite
        self.canBeDeletedOverwrite = self.savegame.xmlFile:getValue(self.savegame.key .. "#canBeDeletedOverwrite") or self.canBeDeletedOverwrite
        local customImageFilename = self.savegame.xmlFile:getValue(self.savegame.key .. ".customImage#filename")
        if customImageFilename ~= nil then
            self.customImageFilename = NetworkUtil.convertFromNetworkFilename(customImageFilename)
        end
        self.nameCustom = self.savegame.xmlFile:getValue(self.savegame.key .. "#name")
        local id = self.savegame.xmlFile:getValue(self.savegame.key .. "#nameL10nKey")
        if id ~= nil then
            self:setNameL10nKey(id)
        end
        self.age = self.savegame.xmlFile:getValue(self.savegame.key .. "#age", 0)
        self.price = self.savegame.xmlFile:getValue(self.savegame.key .. "#price", self.price)
        if not self.savegame.ignoreFarmId then
            self:setOwnerFarmId(self.savegame.xmlFile:getValue(self.savegame.key .. "#farmId", AccessHandler.EVERYONE), true)
        end
        self.isLoadedFromSavegame = true
    end
    self:setLoadingStep(SpecializationLoadStep.FINISHED)
    SpecializationUtil.raiseEvent(self, "onLoadFinished", self.savegame)
    if self.isLoadedFromSavegame then
        self:finalizePlacement()
    end
    if self.isServer then
        self:setLoadingStep(SpecializationLoadStep.SYNCHRONIZED)
    end
    self.finishedLoading = true
    if self.placeableLoadingData.isRegistered then
        self:register()
    end
    self:loadCallback()
    self.savegame = nil
end
function Placeable:onLoadingError(msg, ...)
    if self.xmlFile == nil then
        Logging.error(msg, ...)
    else
        Logging.xmlError(self.xmlFile, msg, ...)
        self.xmlFile:delete()
        self.xmlFile = nil
    end
    self:setLoadingState(PlaceableLoadingState.ERROR)
    self:loadCallback()
end
function Placeable:createLoadingTask(target)
    return SpecializationUtil.createLoadingTask(self, target)
end
function Placeable:finishLoadingTask(task)
    SpecializationUtil.finishLoadingTask(self, task)
end
function Placeable:finalizePlacement()
    SpecializationUtil.raiseEvent(self, "onPreFinalizePlacement")
    self:addToPhysics()
    local placeableSystem = g_currentMission.placeableSystem
    placeableSystem:addPlaceable(self)
    if self.isPreplaced then
        placeableSystem:addPreplacedPlaceable(self)
    end
    g_currentMission:addOwnedItem(self)
    self:collectPickObjects(self.rootNode)
    for _, node in pairs(self.pickObjects) do
        g_currentMission:addNodeObject(node, self)
    end
    if self.boughtWithFarmlandSavegameOverwrite == nil and self.boughtWithFarmland or self.boughtWithFarmlandSavegameOverwrite then
        if self.isServer then
            self:updateOwnership()
        end
        g_messageCenter:subscribe(MessageType.FARMLAND_OWNER_CHANGED, self.onFarmlandStateChanged, self)
    end
    SpecializationUtil.raiseEvent(self, "onFinalizePlacement")
    SpecializationUtil.raiseEvent(self, "onPostFinalizePlacement")
    if self:getNeedWeatherChanged() then
        g_messageCenter:subscribe(MessageType.DAY_NIGHT_CHANGED, self.weatherChanged, self)
    end
    if self:getNeedHourChanged() then
        g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self)
    end
    if self:getNeedMinuteChanged() then
        g_messageCenter:subscribe(MessageType.MINUTE_CHANGED, self.minuteChanged, self)
    end
    if self:getNeedDayChanged() then
        g_messageCenter:subscribe(MessageType.DAY_CHANGED, self.dayChanged, self)
    end
    g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.periodChanged, self)
    g_messageCenter:publish(MessageType.FARM_PROPERTY_CHANGED, self:getOwnerFarmId())
end
function Placeable:delete(immediate)
    self.markedForDeletion = true
    if g_currentMission.isExitingGame or immediate then
        if self.isDeleted then
            Logging.devError("Trying to delete a already deleted placeable")
            printCallstack()
        else
            g_messageCenter:unsubscribeAll(self)
            if self.tourId ~= nil then
                g_guidedTourManager:removePlaceable(self.tourId)
            end
            self.isDeleting = true
            SpecializationUtil.raiseEvent(self, "onPreDelete")
            local placeableSystem = g_currentMission.placeableSystem
            placeableSystem:removePlaceable(self)
            g_currentMission:removeOwnedItem(self)
            if self.sharedLoadRequestId ~= nil then
                g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
                self.sharedLoadRequestId = nil
            end
            for _, node in pairs(self.pickObjects) do
                g_currentMission:removeNodeObject(node)
            end
            SpecializationUtil.raiseEvent(self, "onDelete")
            if not self.isPreplaced and self.rootNode ~= nil then
                delete(self.rootNode)
                self.rootNode = nil
            end
            if self.isPreplaced then
                placeableSystem:removePreplacedPlaceable(self)
            end
            if self.xmlFile ~= nil then
                self.xmlFile:delete()
                self.xmlFile = nil
            end
            self.isDeleting = false
            self.isDeleted = true
            Placeable:superClass().delete(self)
        end
    else
        g_currentMission.placeableSystem:markPlaceableForDeletion(self)
        return
    end
end
function Placeable:readStream(streamId, connection, objectId)
    Placeable:superClass().readStream(self, streamId, connection, objectId)
    local data = PlaceableLoadingData.new()
    local preplacedIndex
    if streamReadBool(streamId) then
        local preplacedIndex = streamReadUInt16(streamId)
        local placeableSystem = g_currentMission.placeableSystem
        preplacedIndex = placeableSystem:getPreplacedFilenameByIndex(preplacedIndex)
        local uniqueId = placeableSystem:getPreplacedUniqueIdByIndex(preplacedIndex)
        data:setPreplacedIndex(preplacedIndex)
        data:setFilename(preplacedIndex)
        data:setUniqueId(uniqueId)
    else
        preplacedIndex = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
        local preplacedIndex = streamReadFloat32(streamId)
        local placeableSystem = streamReadFloat32(streamId)
        local uniqueId = streamReadFloat32(streamId)
        local rotX = streamReadFloat32(streamId)
        local rotY = streamReadFloat32(streamId)
        local rotZ = streamReadFloat32(streamId)
        data:setFilename(preplacedIndex)
        data:setPosition(preplacedIndex, placeableSystem, uniqueId)
        data:setRotation(rotX, rotY, rotZ)
    end
    local preplacedIndex, placeableSystem, uniqueId = ConfigurationUtil.readConfigurationsFromStream(g_placeableConfigurationManager, streamId, connection, preplacedIndex)
    self.propertyState = PlaceablePropertyState.readStream(streamId)
    data:setPropertyState(self.propertyState)
    data:setOwnerFarmId(self.ownerFarmId)
    data:setConfigurations(preplacedIndex)
    data:setBoughtConfigurations(placeableSystem)
    data:setConfigurationData(uniqueId)
    if self.loadingStep == SpecializationLoadStep.CREATED then
        data:loadPlaceableOnClient(self, function(_, placeable, loadingState)
            if loadingState == PlaceableLoadingState.OK then
                g_client:onObjectFinishedAsyncLoading(placeable)
            else
                Logging.error("Failed to load placeable on client")
                printCallstack()
            end
        end, nil)
    else
        Logging.error("Try to intialize loading of a placeable that is already loading!")
    end
end
function Placeable:writeStream(streamId, connection)
    Placeable:superClass().writeStream(self, streamId, connection)
    if streamWriteBool(streamId, self.isPreplaced) then
        streamWriteUInt16(streamId, self.preplacedIndex)
    else
        streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.configFileName))
        local x, y, z = getTranslation(self.rootNode)
        local x_rot, y_rot, z_rot = getRotation(self.rootNode)
        streamWriteFloat32(streamId, x)
        streamWriteFloat32(streamId, y)
        streamWriteFloat32(streamId, z)
        streamWriteFloat32(streamId, x_rot)
        streamWriteFloat32(streamId, y_rot)
        streamWriteFloat32(streamId, z_rot)
    end
    ConfigurationUtil.writeConfigurationsToStream(g_placeableConfigurationManager, streamId, connection, self.configFileName, self.configurations, self.boughtConfigurations, self.configurationData)
    PlaceablePropertyState.writeStream(streamId, self.propertyState)
end
function Placeable:postReadStream(streamId, connection)
    self:finalizePlacement()
    if Placeable.DEBUG_NETWORK then
        print("-------------------------------------------------------------")
        print(self.configFileName)
        for _, spec in ipairs(self.eventListeners.onReadStream) do
            local className = ClassUtil.getClassName(spec)
            local startBits = streamGetReadOffset(streamId)
            spec.onReadStream(self, streamId, connection)
            print("  " .. tostring(className) .. " read " .. streamGetReadOffset(streamId) - startBits .. " bits")
        end
    else
        SpecializationUtil.raiseEvent(self, "onReadStream", streamId, connection)
    end
    if streamReadBool(streamId) then
        self:setName(streamReadString(streamId), true)
    end
    if streamReadBool(streamId) then
        self:setNameL10nKey((streamReadString(streamId)))
    end
    if streamReadBool(streamId) then
        self.customImageFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
    end
    self:setLoadingStep(SpecializationLoadStep.SYNCHRONIZED)
    self:raiseActive()
end
function Placeable:postWriteStream(streamId, connection)
    if Placeable.DEBUG_NETWORK then
        print("-------------------------------------------------------------")
        print(self.configFileName)
        for _, spec in ipairs(self.eventListeners.onWriteStream) do
            local className = ClassUtil.getClassName(spec)
            local startBits = streamGetWriteOffset(streamId)
            spec.onWriteStream(self, streamId, connection)
            print("  " .. tostring(className) .. " Wrote " .. streamGetWriteOffset(streamId) - startBits .. " bits")
        end
    else
        SpecializationUtil.raiseEvent(self, "onWriteStream", streamId, connection)
    end
    if streamWriteBool(streamId, self.nameCustom ~= nil) then
        streamWriteString(streamId, self.nameCustom)
    end
    if streamWriteBool(streamId, self.nameL10nKey ~= nil) then
        streamWriteString(streamId, self.nameL10nKey)
    end
    if streamWriteBool(streamId, self.customImageFilename ~= nil) then
        streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.customImageFilename))
    end
end
function Placeable:readUpdateStream(streamId, timestamp, connection)
    if Placeable.DEBUG_NETWORK_UPDATE then
        print("-------------------------------------------------------------")
        print(self.configFileName)
        for _, spec in ipairs(self.eventListeners.onReadUpdateStream) do
            local className = ClassUtil.getClassName(spec)
            local startBits = streamGetReadOffset(streamId)
            spec.onReadUpdateStream(self, streamId, timestamp, connection)
            print("  " .. tostring(className) .. " read " .. streamGetReadOffset(streamId) - startBits .. " bits")
        end
    else
        SpecializationUtil.raiseEvent(self, "onReadUpdateStream", streamId, timestamp, connection)
    end
end
function Placeable:writeUpdateStream(streamId, connection, dirtyMask)
    if Placeable.DEBUG_NETWORK_UPDATE then
        print("-------------------------------------------------------------")
        print(self.configFileName)
        for _, spec in ipairs(self.eventListeners.onWriteUpdateStream) do
            local className = ClassUtil.getClassName(spec)
            local startBits = streamGetWriteOffset(streamId)
            spec.onWriteUpdateStream(self, streamId, connection, dirtyMask)
            print("  " .. tostring(className) .. " Wrote " .. streamGetWriteOffset(streamId) - startBits .. " bits")
        end
    else
        SpecializationUtil.raiseEvent(self, "onWriteUpdateStream", streamId, connection, dirtyMask)
    end
end
function Placeable:saveToXMLFile(xmlFile, key, usedModNames)
    xmlFile:setValue(key .. "#uniqueId", self.uniqueId)
    if not self.isPreplaced then
        xmlFile:setValue(key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.configFileName)))
        xmlFile:setValue(key .. "#position", getTranslation(self.rootNode))
        xmlFile:setValue(key .. "#rotation", getRotation(self.rootNode))
    end
    xmlFile:setValue(key .. "#age", self.age)
    xmlFile:setValue(key .. "#price", self.price)
    xmlFile:setValue(key .. "#farmId", self:getOwnerFarmId() or 1)
    if self.tourId ~= nil then
        xmlFile:setValue(key .. "#tourId", self.tourId)
    end
    if self.canBeRenamed and (self.nameCustom ~= nil and self.nameCustom:trim() ~= "") then
        xmlFile:setValue(key .. "#name", self.nameCustom)
    end
    if self.nameL10nKey ~= nil and g_i18n:hasText(self.nameL10nKey, self.customEnvironment) then
        xmlFile:setValue(key .. "#nameL10nKey", self.nameL10nKey)
    end
    if self.boughtWithFarmlandSavegameOverwrite ~= nil then
        xmlFile:setValue(key .. "#boughtWithFarmlandOverwrite", self.boughtWithFarmlandSavegameOverwrite)
    end
    if self.canBeDeletedOverwrite ~= nil then
        xmlFile:setValue(key .. "#canBeDeletedOverwrite", self.canBeDeletedOverwrite)
    end
    if self.customImageFilename ~= nil then
        xmlFile:setValue(key .. ".customImage#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.customImageFilename)))
    end
    ConfigurationUtil.saveConfigurationsToXMLFile(self.configFileName, xmlFile, key .. ".configuration", self.configurations, self.boughtConfigurations, self.configurationData)
    for id, spec in pairs(self.specializations) do
        if spec.saveToXMLFile ~= nil then
            spec.saveToXMLFile(self, xmlFile, key .. "." .. self.specializationNames[id], usedModNames)
        end
    end
end
function Placeable:getIsBeingDeleted()
    return self.markedForDeletion or (self.isDeleting or self.isDeleted)
end
function Placeable:setPropertyState(state)
    self.propertyState = state
end
function Placeable:getPropertyState()
    return self.propertyState
end
function Placeable:getPosition()
    return getWorldTranslation(self.rootNode)
end
function Placeable:getFarmlandId()
    local x, _, z = getWorldTranslation(self.rootNode)
    return g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
end
function Placeable:getIsOnFarmland(farmlandId)
    local posX, _, posZ = getWorldTranslation(self.rootNode)
    return g_farmlandManager:getFarmlandIdAtWorldPosition(posX, posZ) == farmlandId
end
function Placeable:setPose(x, y, z, rotX, rotY, rotZ)
    self:removeFromPhysics()
    local oldX, oldY, oldZ = getWorldTranslation(self.rootNode)
    local oldRotX, oldRotY, oldRotZ = getWorldRotation(self.rootNode)
    setWorldTranslation(self.rootNode, x or oldX, y or oldY, z or oldZ)
    setWorldRotation(self.rootNode, rotX or oldRotX, rotY or oldRotY, rotZ or oldRotZ)
    self:addToPhysics()
end
function Placeable:setVisibility(state)
    for _, component in pairs(self.components) do
        setVisibility(component.node, state)
    end
end
function Placeable:getIsSynchronized()
    return self.loadingStep == SpecializationLoadStep.SYNCHRONIZED
end
function Placeable:getIsPreplaced()
    return self.isPreplaced
end
function Placeable:getNeedsSaving()
    return true
end
function Placeable:getUniqueId()
    return self.uniqueId
end
function Placeable:setUniqueId(uniqueId)
    self.uniqueId = uniqueId
end
function Placeable:update(dt)
    SpecializationUtil.raiseEvent(self, "onUpdate", dt)
end
function Placeable:updateTick(dt)
    SpecializationUtil.raiseEvent(self, "onUpdateTick", dt)
end
function Placeable:draw()
    SpecializationUtil.raiseEvent(self, "onDraw")
end
function Placeable:drawDebug()
    SpecializationUtil.raiseEvent(self, "onDrawDebug")
end
function Placeable:getName()
    return not self.nameCustom and (not self.nameL10n and self.storeItem) and self.storeItem.name
end
function Placeable:getImageFilename()
    return self.customImageFilename or self.storeItem.imageFilename
end
function Placeable:getCanBeRenamedByFarm(farmId)
    return self.canBeRenamed and self:getOwnerFarmId() == farmId
end
function Placeable:setName(name, noEventSend)
    if not self.canBeRenamed then
        return false
    end
    if name and name:trim() == "" then
        return false
    end
    PlaceableNameEvent.sendEvent(self, name, noEventSend)
    self.nameCustom = name
    g_messageCenter:publish(MessageType.UNLOADING_STATIONS_CHANGED)
    g_messageCenter:publish(MessageType.LOADING_STATIONS_CHANGED)
    return true
end
function Placeable:setNameL10nKey(nameL10nKey)
    local mapCustomEnv = string.gsub(nameL10nKey, "$l10n_", "")
    local mapCustomEnv = g_currentMission.missionInfo.customEnvironment
    if g_i18n:hasText(mapCustomEnv, mapCustomEnv) then
        self.nameL10nKey = mapCustomEnv
        self.nameL10n = g_i18n:getText(mapCustomEnv, mapCustomEnv)
    end
end
function Placeable:onBuy()
    SpecializationUtil.raiseEvent(self, "onBuy")
    local serverFarmId = g_currentMission:getFarmId()
    local numPlaceables = 0
    for _, existingPlaceable in ipairs(g_currentMission.placeableSystem.placeables) do
        if existingPlaceable:getOwnerFarmId() == serverFarmId then
        end
    end
    g_achievementManager:tryUnlock("NumPlaceables", numPlaceables)
end
function Placeable:onSell()
    g_messageCenter:publish(MessageType.FARM_PROPERTY_CHANGED, self:getOwnerFarmId())
    SpecializationUtil.raiseEvent(self, "onSell")
end
function Placeable:getPrice()
    return self.price
end
function Placeable:canBuy()
    local storeItem = self.storeItem
    return storeItem.maxItemCount == nil and true or g_currentMission:getNumOfItems(storeItem, g_currentMission:getFarmId()) < storeItem.maxItemCount
end
function Placeable:getCanBePlacedAt(x, y, z, farmId)
    return true, nil
end
function Placeable:canBeSold()
    return true, nil
end
function Placeable:getDestructionMethod()
    return Placeable.DESTRUCTION.SELL
end
function Placeable:previewNodeDestructionNodes(node)
    return nil
end
function Placeable:performNodeDestruction(node)
    return false, false
end
function Placeable:onFarmlandStateChanged(farmlandId, _, _)
    if (self.boughtWithFarmlandSavegameOverwrite == nil and self.boughtWithFarmland or self.boughtWithFarmlandSavegameOverwrite) and self:getIsOnFarmland(farmlandId) then
        self:updateOwnership()
    end
end
function Placeable:onOwnerChanged() end
function Placeable:register(alreadySent)
    Placeable:superClass().register(self, alreadySent)
    SpecializationUtil.raiseEvent(self, "onRegistered", alreadySent)
end
function Placeable:clearDirtyMask()
    self.dirtyMask = 0
    SpecializationUtil.raiseEvent(self, "onDirtyMaskCleared")
end
function Placeable:setOwnerFarmId(farmId, noEventSend)
    if self.buysFarmland then
        g_farmlandManager:setLandOwnership(self:getFarmlandId(), farmId)
    end
    Placeable:superClass().setOwnerFarmId(self, farmId, noEventSend)
    if self.loadingStep > SpecializationLoadStep.LOAD then
        SpecializationUtil.raiseEvent(self, "onOwnerChanged")
    end
    if self.propertyState ~= PlaceablePropertyState.CONSTRUCTION_PREVIEW then
        g_currentMission:removeOwnedItem(self)
        g_currentMission:addOwnedItem(self)
    end
end
function Placeable:updateOwnership()
    if self.isServer then
        local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
        if storeItem == nil then
            Logging.error("Missing storeItem for placeable \'%s\'", self.configFileName)
        else
            local farmId = g_farmlandManager:getFarmlandOwner(self:getFarmlandId())
            if (not storeItem.canBeSold or self.boughtWithFarmlandSavegameOverwrite == nil and self.boughtWithFarmland or self.boughtWithFarmlandSavegameOverwrite) and farmId == FarmlandManager.NO_OWNER_FARM_ID then
                farmId = AccessHandler.NOBODY
            end
            if self.ownerFarmId ~= farmId then
                self:setOwnerFarmId(farmId)
            end
        end
    else
        return
    end
end
function Placeable:setLoadingState(loadingState)
    if PlaceableLoadingState.getName(loadingState) == nil then
        printCallstack()
        Logging.error("Invalid loading state \'%s\'!", loadingState)
    else
        self.loadingState = loadingState
    end
end
function Placeable:collectPickObjects(node)
    if getRigidBodyType(node) ~= RigidBodyType.NONE then
        table.insert(self.pickObjects, node)
    end
    local numChildren = getNumOfChildren(node)
    local i = 1
    for i = i, numChildren do
        self:collectPickObjects(getChildAt(node, i - 1))
    end
end
function Placeable:setLoadingStep(loadingStep)
    SpecializationUtil.setLoadingStep(self, loadingStep)
end
function Placeable:setOverlayColor(r, g, b, alpha)
    if self.overlayColorNodes == nil then
        self.overlayColorNodes = {}
        self:setOverlayColorNodes(self.rootNode, self.overlayColorNodes)
    end
    local i = 1
    for i = i, #self.overlayColorNodes do
        setShaderParameter(self.overlayColorNodes[i], "placeableColorScale", r, g, b, alpha, false)
    end
end
function Placeable:setOverlayColorNodes(node, nodeTable)
    if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, "placeableColorScale") then
        nodeTable[#nodeTable + 1] = node
    end
    local i = 0
    for i = i, getNumOfChildren(node) - 1 do
        self:setOverlayColorNodes(getChildAt(node, i), nodeTable)
    end
end
function Placeable:getDailyUpkeep()
    local storeItem = self.storeItem
    local multiplier = 1
    if storeItem.lifetime ~= nil and storeItem.lifetime ~= 0 then
        local ageMultiplier = math.min(self.age / storeItem.lifetime, 1)
        multiplier = 1 + EconomyManager.MAX_DAILYUPKEEP_MULTIPLIER * ageMultiplier
    end
    return StoreItemUtil.getDailyUpkeep(storeItem, self.configurations) * multiplier
end
function Placeable:getSellPrice()
    if self.undoTimer > g_time - Placeable.UNDO_DURATION and (self.undoTimer > g_currentMission.lastConstructionScreenOpenTime and g_currentMission.lastConstructionScreenOpenTime > 0) then
        return self.price, true
    else
        return self:getMonetaryValue(), false
    end
end
function Placeable:getMonetaryValue()
    local priceMultiplier = 0.5
    local maxAge = self.storeItem.lifetime
    if maxAge ~= nil and maxAge ~= 0 then
        priceMultiplier = priceMultiplier * math.exp(-3.5 * math.min(self.age / maxAge, 1))
    end
    return math.floor(self.price * math.max(priceMultiplier, 0.05))
end
function Placeable:getSellAction()
    local farmlandId = self:getFarmlandId()
    local isOnPublicGround = false
    if farmlandId ~= nil then
        isOnPublicGround = g_farmlandManager:getFarmlandOwner(farmlandId) == FarmManager.SPECTATOR_FARM_ID
    end
    if self:getIsPreplaced() and (isOnPublicGround or not self.canBeDeleted) then
        return Placeable.SELL_AND_SPECTATOR_FARM
    elseif self.canBeDeletedOverwrite == false then
        return Placeable.SELL_AND_SPECTATOR_FARM
    else
        return Placeable.SELL_AND_DELETE
    end
end
function Placeable:addToPhysics()
    if self.rootNode ~= nil then
        addToPhysics(self.rootNode)
    end
end
function Placeable:removeFromPhysics()
    if self.rootNode ~= nil then
        removeFromPhysics(self.rootNode)
    end
end
function Placeable:setPreviewPosition(x, y, z, _, rotY, _)
    setWorldTranslation(self.rootNode, x, y, z)
    setRotation(self.rootNode, 0, rotY, 0)
end
function Placeable:getNeedWeatherChanged()
    return false
end
function Placeable:weatherChanged()
    SpecializationUtil.raiseEvent(self, "onWeatherChanged")
end
function Placeable:getNeedHourChanged()
    return false
end
function Placeable:hourChanged(hour)
    SpecializationUtil.raiseEvent(self, "onHourChanged", hour)
end
function Placeable:getNeedMinuteChanged()
    return false
end
function Placeable:minuteChanged(minute)
    SpecializationUtil.raiseEvent(self, "onMinuteChanged", minute)
end
function Placeable:getNeedDayChanged()
    return false
end
function Placeable:dayChanged(day)
    SpecializationUtil.raiseEvent(self, "onDayChanged", day)
end
function Placeable:periodChanged(period)
    self.age = self.age + 1
    SpecializationUtil.raiseEvent(self, "onPeriodChanged", period)
end
function Placeable.getSpecValueSlots(storeItem, _)
    local numOwned = g_currentMission:getNumOfItems(storeItem)
    return string.format("+%0d $SLOTS$", (g_currentMission.slotSystem:getStoreItemSlotUsage(storeItem, numOwned == 0)))
end