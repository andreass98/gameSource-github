PlaceableRiceField = {}
PlaceableRiceField.MAX_NUM_FIELDS = 255
PlaceableRiceField.MAX_NUM_VERTICES = 127
PlaceableRiceField.MIN_VERTEX_DISTANCE = 5
PlaceableRiceField.MAX_VERTEX_DISTANCE = 300
PlaceableRiceField.MAX_EXTENT = 500
PlaceableRiceField.MAX_HEIGHT_DIFF_TO_TERRAIN = 5
PlaceableRiceField.COST_PER_DISPLACED_M3 = 3
PlaceableRiceField.COL_MESH_SIZE_OFFSET = 0.75
PlaceableRiceField.UNDERWATER_FOG_COLOR = {}
PlaceableRiceField.UNDERWATER_FOG_DEPTH = {}
PlaceableRiceField.BUILD_STATUS = {}
PlaceableRiceField.BUILD_STATUS.OK = 0
PlaceableRiceField.BUILD_STATUS.DEFORM_FAILED = 1
PlaceableRiceField.BUILD_STATUS.MESH_FAILED = 2
PlaceableRiceField.BUILD_STATUS.OVERLAP_FAILED = 3
PlaceableRiceField.BUILD_STATUS_LOCA_KEYS = {
    [PlaceableRiceField.BUILD_STATUS.DEFORM_FAILED] = "ui_construction_deformationFailed",
    [PlaceableRiceField.BUILD_STATUS.MESH_FAILED] = "warning_placeable_error_cannotBePlacedAtPosition",
    [PlaceableRiceField.BUILD_STATUS.OVERLAP_FAILED] = "ui_construction_overlapsWithObject"
}
PlaceableRiceField.FILL_DIRECTION = {}
PlaceableRiceField.FILL_DIRECTION.RISE = 1
PlaceableRiceField.FILL_DIRECTION.EMPTY = -1
PlaceableRiceField.WATER_LEVEL_NUM_BITS = 7
PlaceableRiceField.OVERLAP_MASK = bit32.bor(CollisionFlag.WATER, CollisionFlag.STATIC_OBJECT, CollisionFlag.TREE, CollisionFlag.BUILDING, CollisionFlag.VEHICLE, CollisionFlag.PLAYER)
source("dataS/scripts/placeables/specializations/events/PlaceableRiceFieldStateEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableRiceFieldEffectStateEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableRiceFieldFieldEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableRiceFieldFieldAnswerEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableRiceFieldRemoveFieldEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableRiceFieldSetTargetHeightEvent.lua")
source("dataS/scripts/placeables/specializations/PlaceableRiceFieldActivatable.lua")
function PlaceableRiceField.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("RiceField")
    schema:register(XMLValueType.STRING, basePath .. ".riceField.area#groundType", "", "dirt")
    schema:register(XMLValueType.FLOAT, basePath .. ".riceField.area#offsetFromRidge", "distance in m the ground type inside the rice field if offset from the ridge center", "-0.5")
    schema:register(XMLValueType.STRING, basePath .. ".riceField.ridge#groundType", "", "grass")
    schema:register(XMLValueType.FLOAT, basePath .. ".riceField.ridge#height", "height of the ridge around the rice field in m", 0.35)
    schema:register(XMLValueType.FLOAT, basePath .. ".riceField.ridge#levelingWidth", "width of the ridge terrain leveling in m", 0.45)
    schema:register(XMLValueType.FLOAT, basePath .. ".riceField.ridge#paintWidth", "width of the painted area on the ridge around the rice field in m", 1)
    schema:register(XMLValueType.STRING, basePath .. ".riceField.ridge#foliageType", "foliage to place ontop of ridge")
    schema:register(XMLValueType.INT, basePath .. ".riceField.ridge#foliageGrowthState", "foliage growth state", 2)
    schema:register(XMLValueType.STRING, basePath .. ".riceField.ridge#foliageGrowthStateName", "foliage growth state name")
    schema:register(XMLValueType.FLOAT, basePath .. ".riceField.ridge#foliageWidth", "foliage width", "paintWidth / 2")
    schema:register(XMLValueType.FLOAT, basePath .. ".riceField.ridge#foliageOffsetFromRidge", "foliage offset", "0.5")
    schema:register(XMLValueType.FLOAT, basePath .. ".riceField.water#maxLevel", "maximum height of the water", "80% or ridge height")
    schema:register(XMLValueType.FLOAT, basePath .. ".riceField.water#fillDurationGameMinutes", "duration for fully filling field in game minutes")
    schema:register(XMLValueType.VECTOR_4, basePath .. ".riceField.water#underwaterFogColor", "shader paramters for underwaterFogColor")
    schema:register(XMLValueType.VECTOR_4, basePath .. ".riceField.water#underwaterFogDepth", "shader paramters for underwaterFogDepth")
    schema:register(XMLValueType.FILENAME, basePath .. ".riceField.pump#filename", "filepath to pump i3d file")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".riceField.pump.filling#water", "node index path to filling water mesh")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".riceField.pump.filling#splash", "node index path to filling water splash mesh")
    schema:register(XMLValueType.FLOAT, basePath .. ".riceField.pump.filling#yOffset", "y offset of the splash above the water plane", 0.07)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".riceField.pump.emptying#water", "node index path to emptying water mesh")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".riceField.pump.emptying#splash", "node index path to emptying water splash mesh")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".riceField.pump.sounds", "pump")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".riceField.pump.sounds", "water")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".riceField.playerTrigger#node", "node of the player trigger")
    schema:register(XMLValueType.STRING, basePath .. ".riceField.foliage#fruitTypes", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".riceField.foliage#offsetFromRidge", "")
    schema:setXMLSpecializationType()
end
function PlaceableRiceField.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("RiceField")
    schema:register(XMLValueType.FLOAT, basePath .. ".fields.field(?)#worldHeight", "world height/y level of the field")
    schema:register(XMLValueType.FLOAT, basePath .. ".fields.field(?)#waterHeight", "water height in meters")
    schema:register(XMLValueType.FLOAT, basePath .. ".fields.field(?)#waterHeightTarget", "water level target height in m relative to field ground")
    schema:register(XMLValueType.STRING, basePath .. ".fields.field(?)#initialFruit", "initial fruit for preplaced rice fields")
    schema:register(XMLValueType.INT, basePath .. ".fields.field(?)#initialFruitGrowthState", "initial fruit growth state index for preplaced rice fields")
    schema:register(XMLValueType.STRING, basePath .. ".fields.field(?).v(?)", "outline vertex x z position")
    schema:register(XMLValueType.INT, basePath .. ".fields.field(?).waterLevels(?)#period", "period index")
    schema:register(XMLValueType.FLOAT, basePath .. ".fields.field(?).waterLevels(?)#levelPerSqm", "water level for period")
    schema:setXMLSpecializationType()
end
function PlaceableRiceField.prerequisitesPresent(specializations)
    return true
end
function PlaceableRiceField.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onPumpI3DLoaded", PlaceableRiceField.onPumpI3DLoaded)
    SpecializationUtil.registerFunction(placeableType, "drawDebug", PlaceableRiceField.drawDebug)
    SpecializationUtil.registerFunction(placeableType, "getCanCreateNewField", PlaceableRiceField.getCanCreateNewField)
    SpecializationUtil.registerFunction(placeableType, "createNewField", PlaceableRiceField.createNewField)
    SpecializationUtil.registerFunction(placeableType, "removeFieldByNode", PlaceableRiceField.removeFieldByNode)
    SpecializationUtil.registerFunction(placeableType, "removeFieldByIndex", PlaceableRiceField.removeFieldByIndex)
    SpecializationUtil.registerFunction(placeableType, "deleteField", PlaceableRiceField.deleteField)
    SpecializationUtil.registerFunction(placeableType, "getFields", PlaceableRiceField.getFields)
    SpecializationUtil.registerFunction(placeableType, "getFieldByIndex", PlaceableRiceField.getFieldByIndex)
    SpecializationUtil.registerFunction(placeableType, "getFieldByNode", PlaceableRiceField.getFieldByNode)
    SpecializationUtil.registerFunction(placeableType, "getCanAddVertex", PlaceableRiceField.getCanAddVertex)
    SpecializationUtil.registerFunction(placeableType, "getCanFinish", PlaceableRiceField.getCanFinish)
    SpecializationUtil.registerFunction(placeableType, "onPolyhedronOverlap", PlaceableRiceField.onPolyhedronOverlap)
    SpecializationUtil.registerFunction(placeableType, "onFinishedGrowthPeriod", PlaceableRiceField.onFinishedGrowthPeriod)
    SpecializationUtil.registerFunction(placeableType, "getHasValidFields", PlaceableRiceField.getHasValidFields)
    SpecializationUtil.registerFunction(placeableType, "addVertex", PlaceableRiceField.addVertex)
    SpecializationUtil.registerFunction(placeableType, "removeLastVertex", PlaceableRiceField.removeLastVertex)
    SpecializationUtil.registerFunction(placeableType, "tryToFinishField", PlaceableRiceField.tryToFinishField)
    SpecializationUtil.registerFunction(placeableType, "finalizeNewField", PlaceableRiceField.finalizeNewField)
    SpecializationUtil.registerFunction(placeableType, "onRiceFieldAnswerEvent", PlaceableRiceField.onRiceFieldAnswerEvent)
    SpecializationUtil.registerFunction(placeableType, "buildMesh", PlaceableRiceField.buildMesh)
    SpecializationUtil.registerFunction(placeableType, "performTerrainDeformation", PlaceableRiceField.performTerrainDeformation)
    SpecializationUtil.registerFunction(placeableType, "onTerrainDeformationFinished", PlaceableRiceField.onTerrainDeformationFinished)
    SpecializationUtil.registerFunction(placeableType, "onTerrainDeformationFailed", PlaceableRiceField.onTerrainDeformationFailed)
    SpecializationUtil.registerFunction(placeableType, "onTerrainDeformationTaskFinished", PlaceableRiceField.onTerrainDeformationTaskFinished)
    SpecializationUtil.registerFunction(placeableType, "getFirstAndLastVertex", PlaceableRiceField.getFirstAndLastVertex)
    SpecializationUtil.registerFunction(placeableType, "getNumVertices", PlaceableRiceField.getNumVertices)
    SpecializationUtil.registerFunction(placeableType, "setWaterHeight", PlaceableRiceField.setWaterHeight)
    SpecializationUtil.registerFunction(placeableType, "setEffectVisibility", PlaceableRiceField.setEffectVisibility)
    SpecializationUtil.registerFunction(placeableType, "getWaterHeight", PlaceableRiceField.getWaterHeight)
    SpecializationUtil.registerFunction(placeableType, "setWaterHeightTarget", PlaceableRiceField.setWaterHeightTarget)
    SpecializationUtil.registerFunction(placeableType, "getWaterHeightTarget", PlaceableRiceField.getWaterHeightTarget)
    SpecializationUtil.registerFunction(placeableType, "getWaterFillLevel", PlaceableRiceField.getWaterFillLevel)
    SpecializationUtil.registerFunction(placeableType, "getWaterFillLevelPerSqm", PlaceableRiceField.getWaterFillLevelPerSqm)
    SpecializationUtil.registerFunction(placeableType, "getFieldFillingState", PlaceableRiceField.getFieldFillingState)
    SpecializationUtil.registerFunction(placeableType, "getMaxWaterHeight", PlaceableRiceField.getMaxWaterHeight)
    SpecializationUtil.registerFunction(placeableType, "getArea", PlaceableRiceField.getArea)
    SpecializationUtil.registerFunction(placeableType, "getSupportedFruitTypes", PlaceableRiceField.getSupportedFruitTypes)
    SpecializationUtil.registerFunction(placeableType, "playerTriggerCallback", PlaceableRiceField.playerTriggerCallback)
    SpecializationUtil.registerFunction(placeableType, "renderEdges", PlaceableRiceField.renderEdges)
    SpecializationUtil.registerFunction(placeableType, "getRiceFieldState", PlaceableRiceField.getRiceFieldState)
    SpecializationUtil.registerFunction(placeableType, "onRiceFieldStatusResult", PlaceableRiceField.onRiceFieldStatusResult)
    SpecializationUtil.registerFunction(placeableType, "getConfirmDestruction", PlaceableRiceField.getConfirmDestruction)
end
function PlaceableRiceField.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "addToPhysics", PlaceableRiceField.addToPhysics)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableRiceField.collectPickObjects)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getIsOnFarmland", PlaceableRiceField.getIsOnFarmland)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getFarmlandId", PlaceableRiceField.getFarmlandId)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getDestructionMethod", PlaceableRiceField.getDestructionMethod)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "performNodeDestruction", PlaceableRiceField.performNodeDestruction)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "previewNodeDestructionNodes", PlaceableRiceField.previewNodeDestructionNodes)
end
function PlaceableRiceField.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableRiceField)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableRiceField)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableRiceField)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableRiceField)
    SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableRiceField)
    SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableRiceField)
    SpecializationUtil.registerEventListener(placeableType, "onDirtyMaskCleared", PlaceableRiceField)
    SpecializationUtil.registerEventListener(placeableType, "onUpdateTick", PlaceableRiceField)
    SpecializationUtil.registerEventListener(placeableType, "onPeriodChanged", PlaceableRiceField)
end
function PlaceableRiceField.initSpecialization()
    if g_isDevelopmentVersion then
        addConsoleCommand("gsRiceFieldWaterSetLevel", "Set rice field water level percentage", "consoleCommandSetWaterLevel", PlaceableRiceField)
        addConsoleCommand("gsRiceFieldWaterSetShaderParameters", "Set rice field water plane shader parameters", "consoleCommandsetWaterShaderParameters", PlaceableRiceField, "r; g; b; a; depthScale; refractionColorScale; getWaterDepthScale; inscatteringScale")
        addConsoleCommand("gsRiceFieldSetRice", "Set field rice state", "consoleCommandSetRiceState", PlaceableRiceField, "fruitTypeName; growthState; groundAngle")
        addConsoleCommand("gsRiceFieldCreateFromField", "Create a rice field from a field using the same outline", "consoleCommandCreateRiceFieldFromField", PlaceableRiceField, "fieldIndex")
    end
end
function PlaceableRiceField.terminateSpecialization()
    if g_isDevelopmentVersion then
        removeConsoleCommand("gsRiceFieldWaterSetLevel")
        removeConsoleCommand("gsRiceFieldWaterSetShaderParameters")
        removeConsoleCommand("gsRiceFieldSetRice")
        removeConsoleCommand("gsRiceFieldCreateFromField")
    end
end
function PlaceableRiceField:onLoad(_)
    local spec = self.spec_riceField
    local xmlFile = self.xmlFile
    spec.fields = {}
    spec.triggerToFieldIndex = {}
    spec.fieldsToCheckForOverlap = {}
    spec.nodesToCheckForOverlap = {}
    spec.groundTypeInner = xmlFile:getValue("placeable.riceField.area#groundType")
    spec.groundInnerOffsetFromRidge = xmlFile:getValue("placeable.riceField.area#offsetFromRidge", -0.5)
    spec.groundTypeRidge = xmlFile:getValue("placeable.riceField.ridge#groundType")
    spec.ridgeHeight = xmlFile:getValue("placeable.riceField.ridge#height", 0.35)
    spec.levelingWidth = xmlFile:getValue("placeable.riceField.ridge#levelingWidth", 0.45)
    spec.ridgePaintWidth = xmlFile:getValue("placeable.riceField.ridge#paintWidth", 1)
    local foliageTypeName = xmlFile:getValue("placeable.riceField.ridge#foliageType")
    if foliageTypeName ~= nil then
        spec.ridgeFoliageType = g_fruitTypeManager:getFruitTypeByName(foliageTypeName)
        if spec.ridgeFoliageType == nil then
            Logging.xmlWarning(xmlFile, "Foliage type \'%s\' does not exist!", foliageTypeName)
        else
            local foliageGrowthState = nil
            local foliageGrowthStateName = xmlFile:getValue("placeable.riceField.ridge#foliageGrowthStateName")
            if foliageGrowthStateName ~= nil then
                foliageGrowthState = spec.ridgeFoliageType:getGrowthStateByName(foliageGrowthStateName)
                if foliageGrowthState == nil then
                    Logging.xmlWarning(xmlFile, "Foliage growthstate name \'%s\' does not exist for fruit type \'%s\'!", foliageGrowthStateName, foliageTypeName)
                end
            end
            if foliageGrowthState == nil then
                foliageGrowthState = xmlFile:getValue("placeable.riceField.ridge#foliageGrowthStateName", 2)
            end
            spec.ridgeFoliageGrowthState = foliageGrowthState
            spec.ridgeFoliageWidth = xmlFile:getValue("placeable.riceField.ridge#foliageWidth", spec.ridgePaintWidth / 2)
            spec.ridgeFoliageOffset = xmlFile:getValue("placeable.riceField.ridge#foliageOffsetFromRidge", 0.5)
        end
    end
    spec.waterMaxLevel = xmlFile:getValue("placeable.riceField.water#maxLevel", spec.ridgeHeight * 0.8)
    spec.waterFillDurationMs = xmlFile:getValue("placeable.riceField.water#fillDurationGameMinutes", 60) * 60 * 1000
    spec.underwaterFogColor = xmlFile:getValue("placeable.riceField.water#underwaterFogColor")
    spec.underwaterFogDepth = xmlFile:getValue("placeable.riceField.water#underwaterFogDepth")
    spec.playerTriggerNode = xmlFile:getValue("placeable.riceField.playerTrigger#node", nil, self.components, self.i3dMappings)
    local foliageGrowthStateName = xmlFile:getValue("placeable.riceField.pump#filename")
    if foliageGrowthStateName ~= nil then
        local args = Utils.getFilename(foliageGrowthStateName, self.baseDirectory)
        local args = {
            ["loadingTask"] = self:createLoadingTask(spec),
            ["xmlFile"] = xmlFile
        }
        spec.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(args, false, false, self.onPumpI3DLoaded, self, args)
    end
    if self.isClient then
        spec.samples = {}
        spec.samples.pumpSound = g_soundManager:loadSampleFromXML(xmlFile, "placeable.riceField.pump.sounds", "pump", self.baseDirectory, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
        spec.samples.waterSound = g_soundManager:loadSampleFromXML(xmlFile, "placeable.riceField.pump.sounds", "water", self.baseDirectory, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
    end
    local args = xmlFile:getValue("placeable.riceField.foliage#fruitTypes", "RICELONGGRAIN RICE")
    spec.fruitTypes = g_fruitTypeManager:getFruitTypesByNames(args)
    spec.foliageOffsetFromRidge = xmlFile:getValue("placeable.riceField.foliage#offsetFromRidge", -1)
    if self.isServer then
        spec.waterPlanesDirtyFlag = self:getNextDirtyFlag()
        spec.fieldIndicesDirty = {}
        spec.fieldsPendingTargetWaterLevel = {}
    end
    spec.activatable = PlaceableRiceFieldActivatable.new(self)
    g_messageCenter:subscribe(MessageType.FINISHED_GROWTH_PERIOD, self.onFinishedGrowthPeriod, self)
end
function PlaceableRiceField:onPumpI3DLoaded(i3dNode, _, args)
    local spec = self.spec_riceField
    local loadingTask = args.loadingTask
    local xmlFile = args.xmlFile
    if i3dNode == 0 then
        self:finishLoadingTask(loadingTask)
        return false
    end
    spec.pumpNode = i3dNode
    spec.fillingWaterPath = xmlFile:getString("placeable.riceField.pump.filling#water")
    spec.fillingSplashPath = xmlFile:getString("placeable.riceField.pump.filling#splash")
    spec.fillingSplashYOffset = xmlFile:getValue("placeable.riceField.pump.filling#yOffset", 0.07)
    spec.emptyingWaterPath = xmlFile:getString("placeable.riceField.pump.emptying#water")
    spec.emptyingSplashPath = xmlFile:getString("placeable.riceField.pump.emptying#splash")
    self:finishLoadingTask(loadingTask)
    return true
end
function PlaceableRiceField:onDelete()
    local spec = self.spec_riceField
    g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    g_messageCenter:unsubscribe(MessageType.FINISHED_GROWTH_PERIOD, self)
    g_messageCenter:unsubscribe(PlaceableRiceFieldFieldAnswerEvent, self)
    g_debugManager:removeGroup("PlaceableRiceField" .. tostring(self))
    if spec.fields ~= nil then
        for _, field in ipairs(spec.fields) do
            self:deleteField(field)
        end
        spec.fields = {}
    end
    if spec.pumpNode ~= nil then
        delete(spec.pumpNode)
        spec.pumpNode = nil
    end
    if spec.samples ~= nil then
        g_soundManager:deleteSamples(spec.samples)
    end
    if spec.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(spec.sharedLoadRequestId)
        spec.sharedLoadRequestId = nil
    end
end
function PlaceableRiceField:onReadStream(streamId, _)
    local numFields = streamReadUInt8(streamId)
    local i = 1
    for i = i, numFields do
        local field = self:createNewField((streamReadFloat32(streamId)))
        local numVertices = streamReadUInt16(streamId)
        field.polygon = Polygon2D.new(numVertices)
        local isEmptying = 1
        for i = 1, numVertices, isEmptying do
            field.polygon:addPos(streamReadFloat32(streamId), streamReadFloat32(streamId))
        end
        field.waterHeight = streamReadFloat32(streamId)
        local isFilling = false
        local isEmptying = false
        if streamReadBool(streamId) then
            field.waterHeightTarget = streamReadFloat32(streamId)
            isFilling = field.waterHeightTarget > field.waterHeight
            isEmptying = field.waterHeightTarget < field.waterHeight
        end
        self:buildMesh(field)
        self:setEffectVisibility(i, isFilling, isEmptying)
    end
end
function PlaceableRiceField:onWriteStream(streamId, _)
    local spec = self.spec_riceField
    streamWriteUInt8(streamId, #spec.fields)
    for _, field in ipairs(spec.fields) do
        streamWriteFloat32(streamId, field.height)
        streamWriteUInt16(streamId, field.polygon:getNumVertices())
        for _, vertexComponent in ipairs(field.polygon:getVertices()) do
            streamWriteFloat32(streamId, vertexComponent)
        end
        streamWriteFloat32(streamId, field.waterHeight)
        if streamWriteBool(streamId, field.waterHeightTarget ~= nil) then
            streamWriteFloat32(streamId, field.waterHeightTarget)
        end
    end
end
function PlaceableRiceField:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() and streamReadBool(streamId) then
        for fieldIndex, field in ipairs(self.spec_riceField.fields) do
            if streamReadBool(streamId) then
                self:setWaterHeight(fieldIndex, (NetworkUtil.readCompressedRange(streamId, 0, spec.waterMaxLevel, PlaceableRiceField.WATER_LEVEL_NUM_BITS)))
                if streamReadBool(streamId) then
                    field.waterHeightTarget = nil
                end
            end
        end
    end
end
function PlaceableRiceField:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local field = self.spec_riceField.waterPlanesDirtyFlag
        if streamWriteBool(streamId, (bit32.btest(dirtyMask, field))) then
            for fieldIndex, field in ipairs(spec.fields) do
                if streamWriteBool(streamId, spec.fieldIndicesDirty[fieldIndex] ~= nil) then
                    NetworkUtil.writeCompressedRange(streamId, field.waterHeight, 0, spec.waterMaxLevel, PlaceableRiceField.WATER_LEVEL_NUM_BITS)
                    streamWriteBool(streamId, field.waterHeightTarget ~= nil)
                end
            end
        end
    end
end
function PlaceableRiceField:onDirtyMaskCleared()
    local spec = self.spec_riceField
    if next(spec.fieldIndicesDirty) ~= nil then
        for fieldIndex, field in ipairs(spec.fields) do
            spec.fieldIndicesDirty[fieldIndex] = nil
        end
    end
end
function PlaceableRiceField:onUpdateTick(dt)
    if g_currentMission.shallowWaterSimulation ~= nil then
        for _, field in ipairs(self.spec_riceField.fields) do
            if field.isFilling and math.random() > 0.6 then
                local x, _, z = getWorldTranslation(field.fillingSplash)
                g_currentMission.shallowWaterSimulation:paintCircle(x, nil, z, 0.3, MathUtil.randomFloat(-1, 1), MathUtil.randomFloat(-1, 1))
            end
        end
    end
    if self.isServer then
        local changeFactor = g_currentMission:getEffectiveTimeScale() * dt / spec.waterFillDurationMs
        for field in pairs(spec.fieldsPendingTargetWaterLevel) do
            local _ = spec.fields[field]
            if _ ~= nil then
                local z = spec.fieldsPendingTargetWaterLevel[field]
                if (_.waterHeight - _.waterHeightTarget) * z >= 0 then
                    spec.fieldsPendingTargetWaterLevel[field] = nil
                    _.waterHeightTarget = nil
                    self:setEffectVisibility(field, false, false)
                    spec.fieldIndicesDirty[field] = true
                    self:raiseDirtyFlags(spec.waterPlanesDirtyFlag)
                    self:raiseActive()
                else
                    local newHeight = _.waterHeight + z * spec.waterMaxLevel * changeFactor
                    local newHeight
                    if z == PlaceableRiceField.FILL_DIRECTION.RISE then
                        newHeight = math.min(newHeight, _.waterHeightTarget)
                    else
                        newHeight = math.max(newHeight, _.waterHeightTarget)
                    end
                    self:setWaterHeight(field, newHeight)
                end
            end
        end
    end
end
function PlaceableRiceField:addToPhysics() end
function PlaceableRiceField:drawDebug()
    for fieldIndex, field in ipairs(self.spec_riceField.fields) do
        local x, y, z = getWorldTranslation(field.playerTriggerNode)
        if DebugUtil.isPositionInCameraRange(x, y, z, 10) then
            local text = string.format("index %d\nwaterHeight %.3f\narea %d sqm\n", fieldIndex, field.waterHeight, field.areaSqm)
            if field.waterHeightTarget ~= nil then
                text = text .. string.format("waterTarget %.3f", field.waterHeightTarget)
            end
            DebugText.renderAtPosition(x, y + 2, z, text)
        end
    end
end
function PlaceableRiceField:loadFromXMLFile(xmlFile, key)
    for fieldIndex, fieldKey in xmlFile:iterator(key .. ".fields.field") do
        local field = self:createNewField((xmlFile:getValue(fieldKey .. "#worldHeight")))
        field.waterHeight = xmlFile:getValue(fieldKey .. "#waterHeight") or 0
        local waterHeightTarget = xmlFile:getValue(fieldKey .. "#waterHeightTarget")
        local numVertexElements = xmlFile:getNumOfElements(fieldKey .. ".v")
        field.polygon = Polygon2D.new(numVertexElements)
        for _, periodKey in xmlFile:iterator(fieldKey .. ".waterLevels") do
            local period = xmlFile:getValue(periodKey .. "#period")
            field.periodWaterLevelPerSqm[period] = xmlFile:getValue(periodKey .. "#levelPerSqm")
        end
        xmlFile:iterate(fieldKey .. ".v", function(_, vertexKey)
            -- upvalues: (copy) xmlFile, (copy) field
            local xz = xmlFile:getVector(vertexKey, nil, 2)
            field.polygon:addPos(xz[1], xz[2])
        end)
        self:buildMesh(field)
        if self.isServer and not g_currentMission.missionInfo.isValid then
            Logging.devInfo("perform initial deformation for rice field %q", key)
            local initialFruitName = xmlFile:getValue(fieldKey .. "#initialFruit")
            if initialFruitName ~= nil then
                local initialFruitType = g_fruitTypeManager:getFruitTypeByName(initialFruitName)
                if initialFruitType ~= nil then
                    field.initialFruitTypeIndex = initialFruitType.index
                    field.initialFruitGrowthState = xmlFile:getValue(fieldKey .. "#initialFruitGrowthState") or initialFruitType:getMinHarvestingGrowthState()
                    Logging.devInfo("initial fruit %q at growth state %d", initialFruitName, field.initialFruitGrowthState or -1)
                end
            end
            field.deformationIsFree = true
            self:performTerrainDeformation(field, callback)
        end
        if waterHeightTarget ~= nil then
            self:setWaterHeightTarget(fieldIndex, waterHeightTarget)
        end
    end
end
function PlaceableRiceField:saveToXMLFile(xmlFile, key, _)
    xmlFile:setTable(key .. ".fields.field", self.spec_riceField.fields, function(path, field, _)
        -- upvalues: (copy) xmlFile
        xmlFile:setValue(path .. "#worldHeight", field.height)
        xmlFile:setValue(path .. "#waterHeight", field.waterHeight)
        if field.waterHeightTarget ~= nil then
            xmlFile:setValue(path .. "#waterHeightTarget", field.waterHeightTarget)
        end
        local periodIndex = 0
        for period, waterLevelPerSqm in pairs(field.periodWaterLevelPerSqm) do
            xmlFile:setValue(string.format("%s.waterLevels(%d)#period", path, periodIndex), period)
            xmlFile:setValue(string.format("%s.waterLevels(%d)#levelPerSqm", path, periodIndex), waterLevelPerSqm)
            periodIndex = periodIndex + 1
        end
        for period, waterLevelPerSqm, zPos in field.polygon:iteratorVertices() do
            xmlFile:setValue(string.format("%s.v(%d)", path, period - 1), string.format("%.3f %.3f", waterLevelPerSqm, zPos))
        end
    end)
end
function PlaceableRiceField:getDestructionMethod(superFunc)
    return Placeable.DESTRUCTION.PER_NODE
end
function PlaceableRiceField:getConfirmDestruction()
    return true
end
function PlaceableRiceField:previewNodeDestructionNodes(_, node)
    local field = self:getFieldByNode(node)
    if field ~= nil then
        renderShapeOutline(field.mesh, false)
        I3DUtil.iterateRecursively(field.pumpNode, function(iteratedNode)
            if getHasClassId(iteratedNode, ClassIds.SHAPE) and (not getIsNonRenderable(iteratedNode) and getVisibility(iteratedNode)) then
                renderShapeOutline(iteratedNode, false)
            end
        end)
    end
    return nil
end
function PlaceableRiceField:performNodeDestruction(_, node)
    return self:removeFieldByNode(node), not self:getHasValidFields()
end
function PlaceableRiceField:collectPickObjects(superFunc, node, target) end
function PlaceableRiceField:getCanCreateNewField()
    local spec = self.spec_riceField
    if spec == nil or spec.fields == nil then
        return false
    else
        return #spec.fields < PlaceableRiceField.MAX_NUM_FIELDS
    end
end
function PlaceableRiceField.createNewField(_, height)
    return {
        ["node"] = nil,
        ["height"] = height,
        ["areaSqm"] = 0,
        ["capacity"] = 0,
        ["waterHeight"] = 0,
        ["waterHeightTarget"] = nil,
        ["periodWaterLevelPerSqm"] = {},
        ["polygon"] = Polygon2D.new(),
        ["polygonFoliage"] = nil,
        ["mesh"] = nil,
        ["mirrorMesh"] = nil,
        ["colMesh"] = nil,
        ["placementColMesh"] = nil,
        ["pumpNode"] = nil,
        ["playerTriggerNode"] = nil
    }
end
function PlaceableRiceField:removeFieldByNode(node)
    for fieldIndex, field in ipairs(self.spec_riceField.fields) do
        if field.colMesh == node then
            g_client:getServerConnection():sendEvent(PlaceableRiceFieldRemoveFieldEvent.new(self, fieldIndex))
            return true
        end
    end
    return false
end
function PlaceableRiceField:removeFieldByIndex(index)
    local spec = self.spec_riceField
    local field = spec.fields[index]
    if field == nil then
        return false
    end
    table.remove(spec.fields, index)
    if self.isServer then
        spec.fieldIndicesDirty[index] = nil
        spec.fieldsPendingTargetWaterLevel[index] = nil
    end
    self:deleteField(field)
    return true
end
function PlaceableRiceField:deleteField(field)
    if field.mesh ~= nil then
        local spec = self.spec_riceField
        if g_currentMission.shallowWaterSimulation ~= nil then
            g_currentMission.shallowWaterSimulation:removeWaterPlane(field.mesh)
            g_currentMission.shallowWaterSimulation:removeAreaGeometry(field.mesh)
        end
        g_currentMission:removeNodeObject(field.colMesh)
        g_currentMission:removeNodeObject(field.placementColMesh)
        if field.pumpSound ~= nil then
            g_soundManager:deleteSample(field.pumpSound)
            field.pumpSound = nil
        end
        if field.waterSound ~= nil then
            g_soundManager:deleteSample(field.waterSound)
            field.waterSound = nil
        end
        spec.triggerToFieldIndex[field.playerTriggerNode] = nil
        removeTrigger(field.playerTriggerNode)
        field.mesh = nil
        field.mirrorMesh = nil
        field.colMesh = nil
        field.placementColMesh = nil
        field.pumpNode = nil
        field.playerTriggerNode = nil
        field.fillingWater = nil
        field.emptyingWater = nil
        field.fillingSplash = nil
        field.emptyingSplash = nil
        delete(field.node)
        if g_server ~= nil and not g_currentMission.isExitingGame then
            if not self.isReloading then
                local enlargedPolygon = field.polygon:getOffsetPolygon(spec.ridgePaintWidth)
                local densityMapPolygon = DensityMapPolygon.new()
                densityMapPolygon:updateFromPolygon2D(enlargedPolygon)
                local fieldUpdateTask = FieldUpdateTask.new()
                fieldUpdateTask:setName("PlaceableRiceField deleteField()")
                fieldUpdateTask:setArea(densityMapPolygon)
                fieldUpdateTask:setGroundType(FieldGroundType.NONE)
                fieldUpdateTask:setWaterLevel(0)
                fieldUpdateTask:setFieldType(FieldType.DEFAULT)
                fieldUpdateTask:setFruit(FruitType.UNKNOWN, 0)
                fieldUpdateTask:enqueue()
            end
            local enlargedPolygon = spec.levelingWidth / 2
            local densityMapPolygon = TerrainDeformation.new(g_terrainNode)
            densityMapPolygon:enableDeformationMode()
            densityMapPolygon:setOutsideAreaConstraints(PlaceableRiceField.MAX_HEIGHT_DIFF_TO_TERRAIN * 1.1, 0.7853981633974483, 0.8726646259971648)
            for edgeIndex, v1x, v1z, v2x, v2z in field.polygon:iteratorEdges() do
                local dx, dz = MathUtil.vector2Normalize(v2x - v1x, v2z - v1z)
                local dxPerp = -dz
                local v1x = v1x - dx * enlargedPolygon + dxPerp * enlargedPolygon
                local v1z = v1z - dz * enlargedPolygon + dx * enlargedPolygon
                local hx, hz = MathUtil.vector2SetLength(v2z + dz * enlargedPolygon + dx * enlargedPolygon - v1z, -(v2x + dx * enlargedPolygon + dxPerp * enlargedPolygon - v1x), spec.levelingWidth)
                densityMapPolygon:addArea(v1x, field.height, v1z, v2x, 0, v2z, hx, 0, hz, TerrainDeformation.NO_TERRAIN_BRUSH, false)
            end
            g_terrainDeformationQueue:queueJob(densityMapPolygon, false)
            local fieldUpdateTask, maxX, minZ, edgeIndex = field.polygon:getBoundingBox()
            g_densityMapHeightManager:setCollisionMapAreaDirty(fieldUpdateTask, minZ, maxX, edgeIndex, true)
        end
    end
end
function PlaceableRiceField:getFields()
    return self.spec_riceField.fields
end
function PlaceableRiceField:getFieldByIndex(fieldIndex)
    return self.spec_riceField.fields[fieldIndex]
end
function PlaceableRiceField:getFieldByNode(node)
    local parent = getParent(node)
    while parent ~= 0 and parent ~= self.rootNode do
        local parent = getParent(parent)
        node = parent
    end
    for _, field in ipairs(self.spec_riceField.fields) do
        if field.node == node then
            return field
        end
    end
    return nil
end
function PlaceableRiceField:getIsOnFarmland(_, farmlandId)
    for _, field in ipairs(self.spec_riceField.fields) do
        for _, vx, vz in field.polygon:iteratorVertices() do
            if g_farmlandManager:getFarmlandIdAtWorldPosition(vx, vz) == farmlandId then
                return true
            end
        end
    end
    return false
end
function PlaceableRiceField:getFarmlandId(_)
    local farmland = nil
    for _, field in ipairs(self.spec_riceField.fields) do
        for _, vx, vz in field.polygon:iteratorVertices() do
            local vertexFarmland = g_farmlandManager:getFarmlandIdAtWorldPosition(vx, vz)
            if farmland == nil or vertexFarmland == farmland then
                farmland = vertexFarmland
            else
                Logging.warning("PlaceableRiceField:getFarmland(): placeable spans more than one farmland: %d and %d", farmland, vertexFarmland)
            end
        end
    end
    return farmland
end
function PlaceableRiceField:getCanAddVertex(field, newX, newZ)
    if field.polygon:getNumVertices() >= PlaceableRiceField.MAX_NUM_VERTICES then
        return false, "Maximum number of vertices reached"
    end
    if not g_farmlandManager:getIsOwnedByFarmAtWorldPosition(self:getOwnerFarmId(), newX, newZ) then
        return false, g_i18n:getText("ui_construction_landIsNotOwned")
    end
    local lastVertexX = getTerrainHeightAtWorldPos(g_terrainNode, newX, 0, newZ) - field.height
    if math.abs(lastVertexX) > PlaceableRiceField.MAX_HEIGHT_DIFF_TO_TERRAIN then
        return false, g_i18n:getText("ui_construction_heightDifferenceTooLarge")
    end
    local numVertices = field.polygon:getNumVertices()
    if numVertices >= 1 then
        local lastVertexX, lastVertexZ = field.polygon:getLastVertex()
        local distance = MathUtil.vector2Length(lastVertexX - newX, lastVertexZ - newZ)
        if distance < PlaceableRiceField.MIN_VERTEX_DISTANCE then
            return false, g_i18n:getText("ui_construction_riceFieldCornerTooClose")
        end
        if PlaceableRiceField.MAX_VERTEX_DISTANCE < distance then
            return false, g_i18n:getText("ui_construction_riceFieldCornerTooFar")
        end
        if not g_farmlandManager:getIsOwnedByFarmAlongLine(self:getOwnerFarmId(), lastVertexX, lastVertexZ, newX, newZ) then
            return false, g_i18n:getText("ui_construction_landIsNotOwned")
        end
        if g_densityMapHeightManager:getIsPlacementAreaBlocked(lastVertexX, lastVertexZ, newX, newZ) then
            return false, g_i18n:getText("ui_construction_areaRestricted")
        end
        if distance ~= 0 then
            local step = getTerrainHeightmapUnitSize(g_terrainNode) / distance
            local alpha = 0
            for alpha = alpha, 1, step do
                local x, z = MathUtil.vector2Lerp(lastVertexX, lastVertexZ, newX, newZ, alpha)
                local x1 = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) - field.height
                if math.abs(x1) > PlaceableRiceField.MAX_HEIGHT_DIFF_TO_TERRAIN then
                    return false, g_i18n:getText("ui_construction_heightDifferenceTooLarge")
                end
            end
        end
        if numVertices > 1 then
            local step = math.huge
            local maxX = -math.huge
            local minZ = math.huge
            local alpha = -math.huge
            for index, x1, z1, x2, z2 in field.polygon:iteratorEdges() do
                if MathUtil.vector2Length(x1 - newX, z1 - newZ) < PlaceableRiceField.MIN_VERTEX_DISTANCE then
                    return false, g_i18n:getText("ui_construction_riceFieldCornerTooClose")
                end
                step = math.min(step, x1)
                maxX = math.max(maxX, x1)
                minZ = math.min(minZ, z1)
                alpha = math.max(alpha, z1)
                if MathUtil.vector2Length(maxX - newX, alpha - newZ) > PlaceableRiceField.MAX_EXTENT or MathUtil.vector2Length(step - newX, minZ - newZ) > PlaceableRiceField.MAX_EXTENT then
                    return false, g_i18n:getText("ui_construction_riceFieldMaxSizeReached")
                end
                if MathUtil.getAreLineSegmentsIntersecting(lastVertexX, lastVertexZ, newX, newZ, x1, z1, x2, z2, true) then
                    return false, g_i18n:getText("ui_construction_riceFieldIntersect")
                end
                if MathUtil.getDistanceToLineSegment2D(x1, z1, x2, z2, newX, newZ) <= 0.1 then
                    return false, g_i18n:getText("ui_construction_riceFieldIntersect")
                end
            end
        end
    end
    return true
end
function PlaceableRiceField.getCanFinish(_, field, perpendicularOnly)
    if field == nil then
        return false
    end
    if field.polygon == nil or field.polygon:getNumVertices() < 3 then
        return false
    end
    local firstVertexX, firstVertexZ = field.polygon:getVertex(1)
    local lastVertexX, lastVertexZ = field.polygon:getLastVertex()
    if perpendicularOnly and (firstVertexX ~= lastVertexX and firstVertexZ ~= lastVertexZ) then
        return false
    end
    for index, x1, z1, x2, z2 in field.polygon:iteratorEdges(nil, 1) do
        if MathUtil.getAreLineSegmentsIntersecting(firstVertexX, firstVertexZ, lastVertexX, lastVertexZ, x1, z1, x2, z2, true) then
            return false
        end
    end
    return true
end
function PlaceableRiceField:tryToFinishField(field)
    local spec = self.spec_riceField
    local convexHull = field.polygon:getConvexHull()
    table.clear(spec.fieldsToCheckForOverlap)
    table.clear(spec.nodesToCheckForOverlap)
    local polyhedronPoints = {}
    local i = 1
    for i = i, #convexHull, 2 do
        polyhedronPoints[#polyhedronPoints + 1] = convexHull[i]
        polyhedronPoints[#polyhedronPoints + 1] = field.height - 5
        polyhedronPoints[#polyhedronPoints + 1] = convexHull[i + 1]
        polyhedronPoints[#polyhedronPoints + 1] = convexHull[i]
        polyhedronPoints[#polyhedronPoints + 1] = field.height + 5
        polyhedronPoints[#polyhedronPoints + 1] = convexHull[i + 1]
    end
    overlapConvexPolyhedron(polyhedronPoints, "onPolyhedronOverlap", self, PlaceableRiceField.OVERLAP_MASK, true, true, true, true)
    for _, fieldToCheck in ipairs(spec.fieldsToCheckForOverlap) do
        for _, vertexToCheckX, vertexToCheckZ in fieldToCheck.polygon:iteratorVertices() do
            if field.polygon:getIsPosInside(vertexToCheckX, vertexToCheckZ) then
                return false
            end
        end
    end
    for _, fieldToCheck in ipairs(spec.nodesToCheckForOverlap) do
        local wx, wy, vertexToCheckX, vertexToCheckZ
        if getHasClassId(fieldToCheck, ClassIds.SHAPE) then
            local wz, _
            wx, wy, wz, _, vertexToCheckX, vertexToCheckZ = getRigidBodyAABB(fieldToCheck)
        else
            local wx, wy, wz = getWorldTranslation(fieldToCheck)
            wx = wx - 0.5
            wy = wx + 0.5
            vertexToCheckX = wz - 0.5
            vertexToCheckZ = wz + 0.5
        end
        if field.polygon:getIsPosInside(wx, vertexToCheckX) or field.polygon:getIsPosInside(wx, vertexToCheckZ) or (field.polygon:getIsPosInside(wy, vertexToCheckX) or field.polygon:getIsPosInside(wy, vertexToCheckZ)) then
            DebugShapeOutline.new():createWithNode(fieldToCheck):addToManager(nil, 10000)
            return false
        end
    end
    table.clear(spec.fieldsToCheckForOverlap)
    table.clear(spec.nodesToCheckForOverlap)
    return true
end
function PlaceableRiceField:onPolyhedronOverlap(node)
    if node ~= 0 then
        local spec = self.spec_riceField
        local placeableRiceField = g_currentMission:getNodeObject(node)
        if placeableRiceField ~= nil and placeableRiceField.getFieldByNode ~= nil then
            local field = placeableRiceField:getFieldByNode(node)
            if field ~= nil then
                table.insert(spec.fieldsToCheckForOverlap, field)
                Logging.devInfo("PlaceableRiceField:onPolyhedronOverlap fieldsToCheckForOverlap %s", I3DUtil.getNodePath(node))
                return
            end
        end
        table.insert(spec.nodesToCheckForOverlap, node)
        Logging.devInfo("PlaceableRiceField:onPolyhedronOverlap nodesToCheckForOverlap %s", I3DUtil.getNodePath(node))
    end
end
function PlaceableRiceField:addVertex(field, x, z)
    local canAdd, errorMessage = self:getCanAddVertex(field, x, z)
    if not canAdd then
        return false, errorMessage
    end
    field.polygon:addPos(x, z)
    return true, nil
end
function PlaceableRiceField.removeLastVertex(_, field)
    field.polygon:removeVertex(field.polygon:getNumVertices())
end
function PlaceableRiceField:finalizeNewField(field, noEventSent, callback)
    if not (self.isServer or noEventSent) then
        g_client:getServerConnection():sendEvent(PlaceableRiceFieldFieldEvent.new(self, field))
        self.pendingCallback = callback
        g_messageCenter:subscribeOneshot(PlaceableRiceFieldFieldAnswerEvent, self.onRiceFieldAnswerEvent, self)
        return true
    end
    if not self:tryToFinishField(field) then
        Logging.devInfo("PlaceableRiceField:finalizeNewField OVERLAP_FAILED")
        callback(PlaceableRiceField.BUILD_STATUS.OVERLAP_FAILED)
        return false
    end
    if self:buildMesh(field) then
        if self.isServer then
            self:performTerrainDeformation(field, callback)
        end
        return true
    end
    Logging.devInfo("PlaceableRiceField:finalizeNewField MESH_FAILED")
    callback(PlaceableRiceField.BUILD_STATUS.MESH_FAILED)
    return false
end
function PlaceableRiceField:onRiceFieldAnswerEvent(statusCode)
    self.pendingCallback(statusCode)
    self.pendingCallback = nil
end
function PlaceableRiceField:onTerrainDeformationFinished(field, volumeDisplaced)
    local spec = self.spec_riceField
    local enlargedPolygon = field.polygon:getOffsetPolygon(spec.ridgePaintWidth)
    local densityMapPolygon = DensityMapPolygon.new()
    densityMapPolygon:updateFromPolygon2D(enlargedPolygon)
    local fieldUpdateTask = FieldUpdateTask.new()
    fieldUpdateTask:setName("PlaceableRiceField prepareField")
    fieldUpdateTask:setArea(densityMapPolygon)
    fieldUpdateTask:clearHeight()
    fieldUpdateTask:setWeedState(0)
    fieldUpdateTask:setStoneLevel(0)
    fieldUpdateTask:setLimeLevel(1)
    if field.initialFruitTypeIndex == nil then
        fieldUpdateTask:setFruit(FruitType.UNKNOWN, 0)
    end
    fieldUpdateTask:setSprayType(FieldSprayType.NONE)
    fieldUpdateTask:setGroundType(FieldGroundType.NONE)
    fieldUpdateTask:resetDisplacement()
    fieldUpdateTask:clearTireTracks()
    fieldUpdateTask:enqueue()
    local densityMapPolygonInner = DensityMapPolygon.new()
    densityMapPolygonInner:updateFromPolygon2D((field.polygon:getOffsetPolygon(spec.groundInnerOffsetFromRidge)))
    local fieldUpdateTaskInner = FieldUpdateTask.new()
    fieldUpdateTaskInner:setName("PlaceableRiceField set ground")
    fieldUpdateTaskInner:setArea(densityMapPolygonInner)
    local groundType = FieldGroundType.CULTIVATED
    if field.initialFruitTypeIndex ~= nil then
        local fruitType = g_fruitTypeManager:getFruitTypeByIndex(field.initialFruitTypeIndex)
        if fruitType ~= nil then
            groundType = fruitType:getGrowthStateGroundType(field.initialFruitGrowthState) or groundType
        end
    end
    fieldUpdateTaskInner:setGroundType(groundType)
    fieldUpdateTaskInner:setFieldType(FieldType.RICE)
    fieldUpdateTaskInner:enqueue()
    if field.initialFruitTypeIndex ~= nil then
        local fruitType = DensityMapPolygon.new()
        fruitType:updateFromPolygon2D(field.polygonFoliage)
        local fieldUpdateTaskFoliage = FieldUpdateTask.new()
        fieldUpdateTaskFoliage:setName("PlaceableRiceField set foliage")
        fieldUpdateTaskFoliage:setArea(fruitType)
        fieldUpdateTaskFoliage:setFruit(field.initialFruitTypeIndex, field.initialFruitGrowthState)
        fieldUpdateTaskFoliage:enqueue()
    end
    if spec.ridgeFoliageType ~= nil then
        local fruitType = field.polygon:getOffsetPolygon(spec.ridgeFoliageOffset)
        for edgeIndex, v1x, v1z, v2x, v2z in fruitType:iteratorEdges() do
            local ridgeFoliageTask = FieldUpdateTask.new()
            ridgeFoliageTask:setName("PlaceableRiceField set ridge foliage")
            local densityMapPolygonRidge = DensityMapPolygon.new()
            local dx, dz = MathUtil.vector2Normalize(v2x - v1x, v2z - v1z)
            local offsetX = spec.ridgeFoliageWidth / 2 * -dz
            local offsetZ = fieldUpdateTaskFoliage * dx
            densityMapPolygonRidge:addPolygonPoint(v1x + offsetX, v1z + offsetZ)
            densityMapPolygonRidge:addPolygonPoint(v2x + offsetX, v2z + offsetZ)
            densityMapPolygonRidge:addPolygonPoint(v2x - offsetX, v2z - offsetZ)
            densityMapPolygonRidge:addPolygonPoint(v1x - offsetX, v1z - offsetZ)
            ridgeFoliageTask:setArea(densityMapPolygonRidge)
            ridgeFoliageTask:setFruit(spec.ridgeFoliageType.index, spec.ridgeFoliageGrowthState)
            ridgeFoliageTask:enqueue()
        end
    end
    local fruitType, fieldUpdateTaskFoliage, minZ, maxZ = field.polygon:getBoundingBox()
    g_densityMapHeightManager:setCollisionMapAreaDirty(fruitType, minZ, fieldUpdateTaskFoliage, maxZ, true)
    g_server:broadcastEvent(PlaceableRiceFieldFieldEvent.new(self, field), false, nil, self.placeableRiceField)
    if field.deformationIsFree then
        field.deformationIsFree = nil
    else
        g_currentMission:addMoney(-(volumeDisplaced * PlaceableRiceField.COST_PER_DISPLACED_M3), self:getOwnerFarmId(), MoneyType.SHOP_PROPERTY_BUY, true)
    end
    field.brushCallback(PlaceableRiceField.BUILD_STATUS.OK)
    field.brushCallback = nil
end
function PlaceableRiceField:onTerrainDeformationFailed(field)
    table.removeElement(self.spec_riceField.fields, field)
    self:deleteField(field)
    field.brushCallback(PlaceableRiceField.BUILD_STATUS.DEFORM_FAILED)
    field.brushCallback = nil
end
function PlaceableRiceField:buildMesh(field)
    local spec = self.spec_riceField
    local offsetPolygon = field.polygon:getOffsetPolygon(PlaceableRiceField.COL_MESH_SIZE_OFFSET)
    if offsetPolygon == nil then
        return false
    end
    local waterplaneNode = createPlaneShapeFrom2DContour("riceFieldVisualWaterPlane", field.polygon:getVertices(), false)
    if waterplaneNode == 0 then
        return false
    end
    local waterplaneMirrorsNode = clone(waterplaneNode, false, false, false)
    setName(waterplaneMirrorsNode, "riceFieldVisualWaterPlaneMirror")
    local waterplaneColNode = createPlaneShapeFrom2DContour("riceFieldWaterCol", field.polygon:getVertices(), true)
    if waterplaneColNode == 0 then
        return false
    end
    local placementColPlaneNode = createPlaneShapeFrom2DContour("riceFieldPlacementCol", offsetPolygon:getVertices(), true)
    if placementColPlaneNode == 0 then
        return false
    end
    removeFromPhysics(waterplaneColNode)
    removeFromPhysics(placementColPlaneNode)
    field.node = createTransformGroup("riceField")
    link(self.rootNode, field.node)
    field.mesh = waterplaneNode
    field.mirrorMesh = waterplaneMirrorsNode
    field.colMesh = waterplaneColNode
    field.placementColMesh = placementColPlaneNode
    link(field.node, waterplaneNode)
    link(field.node, waterplaneMirrorsNode)
    link(field.node, waterplaneColNode)
    link(field.node, placementColPlaneNode)
    local x, _, z = getTranslation(placementColPlaneNode)
    setTranslation(placementColPlaneNode, x, field.height - 1, z)
    setCollisionFilter(placementColPlaneNode, CollisionFlag.PLACEMENT_BLOCKING, 1)
    setIsNonRenderable(placementColPlaneNode, true)
    addToPhysics(placementColPlaneNode)
    local r, g, b = getTranslation(waterplaneColNode)
    setTranslation(waterplaneColNode, r, field.height + spec.waterMaxLevel, b)
    setCollisionFilter(waterplaneColNode, CollisionFlag.WATER, 1)
    setIsNonRenderable(waterplaneColNode, true)
    addToPhysics(waterplaneColNode)
    setShapeReceiveShadowmap(waterplaneNode, true)
    setShapeCastShadowmap(waterplaneNode, false)
    local g = spec.underwaterFogColor or PlaceableRiceField.UNDERWATER_FOG_COLOR
    local r, g, b, a = unpack(g)
    local refractionColorScale = spec.underwaterFogDepth or PlaceableRiceField.UNDERWATER_FOG_DEPTH
    local depthScale, refractionColorScale, getWaterDepthScale, inscatteringScale = unpack(refractionColorScale)
    local waterSimMat = g_materialManager:getBaseMaterialByName("riceFieldWaterSimulation")
    if waterSimMat == nil then
        Logging.error("Unable to retrieve material \'riceFieldWaterSimulation\' for rice field water plane")
    else
        setMaterial(waterplaneNode, waterSimMat, 0)
        setShaderParameter(waterplaneNode, "underwaterFogColor", r, g, b, a, false)
        setShaderParameter(waterplaneNode, "underwaterFogDepth", depthScale, refractionColorScale, getWaterDepthScale, inscatteringScale, false)
    end
    setShapeReceiveShadowmap(waterplaneMirrorsNode, true)
    setShapeCastShadowmap(waterplaneMirrorsNode, false)
    local waterMirrorMat = g_materialManager:getBaseMaterialByName("riceFieldWaterInMirror")
    if waterMirrorMat == nil then
        Logging.error("Unable to retrieve material \'riceFieldWaterInMirror\' for rice field water plane")
    else
        setMaterial(waterplaneMirrorsNode, waterMirrorMat, 0)
        setShaderParameter(waterplaneNode, "underwaterFogColor", r, g, b, a)
        setShaderParameter(waterplaneNode, "underwaterFogDepth", depthScale, refractionColorScale, getWaterDepthScale, inscatteringScale, false)
        setObjectMask(waterplaneMirrorsNode, ObjectMask.SHAPE_VIS_MIRROR_ONLY)
    end
    field.polygonFoliage = field.polygon:getOffsetPolygon(spec.foliageOffsetFromRidge)
    field.areaSqm = field.polygon:getArea()
    field.capacity = field.areaSqm * 1000 * spec.waterMaxLevel
    local waterSoundLinkNode = spec.fields
    table.insert(waterSoundLinkNode, field)
    local fieldIndex = #spec.fields
    self:setWaterHeight(fieldIndex, field.waterHeight, true)
    if g_currentMission.shallowWaterSimulation ~= nil then
        g_currentMission.shallowWaterSimulation:addWaterPlane(field.mesh)
        g_currentMission.shallowWaterSimulation:addAreaGeometry(field.mesh)
    end
    g_currentMission:addNodeObject(waterplaneColNode, self)
    g_currentMission:addNodeObject(placementColPlaneNode, self)
    field.pumpNode = clone(spec.pumpNode, false, false, false)
    link(field.node, field.pumpNode)
    field.fillingWater = I3DUtil.indexToObject(field.pumpNode, spec.fillingWaterPath)
    field.fillingSplash = I3DUtil.indexToObject(field.pumpNode, spec.fillingSplashPath)
    field.emptyingWater = I3DUtil.indexToObject(field.pumpNode, spec.emptyingWaterPath)
    field.emptyingSplash = I3DUtil.indexToObject(field.pumpNode, spec.emptyingSplashPath)
    if spec.samples ~= nil then
        if spec.samples.pumpSound ~= nil then
            field.pumpSound = g_soundManager:cloneSample(spec.samples.pumpSound, field.pumpNode)
        end
        if spec.samples.waterSound ~= nil then
            local waterSoundLinkNode = createTransformGroup("riceFieldWaterSoundNode")
            link(field.pumpNode, waterSoundLinkNode)
            field.waterSoundLinkNode = waterSoundLinkNode
            field.waterSound = g_soundManager:cloneSample(spec.samples.waterSound, field.waterSoundLinkNode)
        end
    end
    local waterSoundLinkNode, z1, x2, z2 = field.polygon:getEdge(1)
    local cx = (waterSoundLinkNode + x2) / 2
    local cz = (z1 + z2) / 2
    setWorldTranslation(field.pumpNode, cx, field.height, cz)
    local wx, wy, wz = getWorldTranslation(field.emptyingSplash)
    local orientation = getTerrainHeightAtWorldPos(g_terrainNode, wx, 0, wz) - wy
    if math.abs(orientation) < 0.5 then
        setWorldTranslation(field.emptyingSplash, wx, wy + 0.07, wz)
    else
        delete(field.emptyingSplash)
        field.emptyingSplash = createTransformGroup("riceFieldEmptyingSplashDummy")
        link(field.pumpNode, field.emptyingSplash)
    end
    local orientation = field.polygon:getCurveOrientation()
    local ry = -1.5707963267948966 + MathUtil.getYRotationFromDirection(x2 - waterSoundLinkNode, z2 - z1) + (orientation == -1 and 3.141592653589793 or 0)
    setRotation(field.pumpNode, 0, ry, 0)
    addToPhysics(field.pumpNode)
    self:setEffectVisibility(fieldIndex, false, false)
    field.playerTriggerNode = clone(spec.playerTriggerNode, false, false, false)
    link(field.node, field.playerTriggerNode)
    setWorldTranslation(field.playerTriggerNode, cx, field.height, cz)
    setRotation(field.playerTriggerNode, 0, ry, 0)
    addToPhysics(field.playerTriggerNode)
    addTrigger(field.playerTriggerNode, "playerTriggerCallback", self)
    spec.triggerToFieldIndex[field.playerTriggerNode] = fieldIndex
    return true
end
function PlaceableRiceField:performTerrainDeformation(field, callback)
    local spec = self.spec_riceField
    field.displacedVolume = 0
    field.areaDeformation = TerrainDeformation.new(g_terrainNode)
    local polygon3dVertices = field.polygon:getVerticesAs3DCoordinates(field.height + 0.02)
    field.brushCallback = callback or function() end
    local terrainBrushId = g_groundTypeManager:getTerrainLayerByType(spec.groundTypeInner)
    field.areaDeformation:setOutsideAreaConstraints(PlaceableRiceField.MAX_HEIGHT_DIFF_TO_TERRAIN * 1.1, 0.7853981633974483, 0.8726646259971648)
    field.areaDeformation:addPolygonalArea(polygon3dVertices, terrainBrushId, false)
    field.deformQueue = 1
    field.areaDeformationJobId = g_terrainDeformationQueue:queueJob(field.areaDeformation, false, "onTerrainDeformationTaskFinished", self, field)
    field.ridgeDeformation = TerrainDeformation.new(g_terrainNode)
    field.ridgeDeformation:enableDeformationMode()
    field.ridgeDeformation:setOutsideAreaConstraints(PlaceableRiceField.MAX_HEIGHT_DIFF_TO_TERRAIN * 1.1, 0.7853981633974483, 0.8726646259971648)
    for edgeIndex, v1x, v1z, v2x, v2z in field.polygon:iteratorEdges() do
        local dx, dz = MathUtil.vector2Normalize(v2x - v1x, v2z - v1z)
        local dxPerp = -dz
        local v1x = v1x - dx * (spec.levelingWidth / 2) + dxPerp * (spec.levelingWidth / 2)
        local v1z = v1z - dz * deformWidthHalf + dx * deformWidthHalf
        local hx, hz = MathUtil.vector2SetLength(v2z + dz * deformWidthHalf + dx * deformWidthHalf - v1z, -(v2x + dx * deformWidthHalf + dxPerp * deformWidthHalf - v1x), spec.levelingWidth)
        field.ridgeDeformation:addArea(v1x, field.height + spec.ridgeHeight, v1z, v2x, 0, v2z, hx, 0, hz, terrainBrushId, false)
    end
    field.deformQueue = field.deformQueue + 1
    field.ridgeDeformationJobId = g_terrainDeformationQueue:queueJob(field.ridgeDeformation, false, "onTerrainDeformationTaskFinished", self, field)
    local ridgeWidthHalf = g_groundTypeManager:getTerrainLayerByType(spec.groundTypeRidge)
    if ridgeWidthHalf ~= nil then
        field.ridgeDeformationPaint = TerrainDeformation.new(g_terrainNode)
        field.ridgeDeformationPaint:enablePaintingMode()
        for v1x, v1z, v2x, v2z, dx in field.polygon:iteratorEdges() do
            local dz, dxPerp = MathUtil.vector2Normalize(v2z - v1z, dx - v2x)
            local dzPerp = -dxPerp
            local v1z = v1z - dz * (spec.ridgePaintWidth / 2) + dzPerp * (spec.ridgePaintWidth / 2)
            local v2x = v2x - dxPerp * ridgeWidthHalf + dz * ridgeWidthHalf
            local hz, hz = MathUtil.vector2SetLength(dx + dxPerp * ridgeWidthHalf + dz * ridgeWidthHalf - v2x, -(v2z + dz * ridgeWidthHalf + dzPerp * ridgeWidthHalf - v1z), spec.ridgePaintWidth)
            field.ridgeDeformationPaint:addArea(v1z, field.height + spec.ridgeHeight, v2x, v2z, 0, dx, hz, 0, hz, ridgeWidthHalf, false)
        end
        field.deformQueue = field.deformQueue + 1
        field.ridgePaintJobId = g_terrainDeformationQueue:queueJob(field.ridgeDeformationPaint, false, "onTerrainDeformationTaskFinished", self, field)
    end
end
function PlaceableRiceField:onTerrainDeformationTaskFinished(errorCode, displacementVolume, blockedObjectName, callbackArgs)
    Logging.devInfo("PlaceableRiceField:onTerrainDeformationFinished errorCode=%d, displacementVolume=%.3f, blockedObjectName=%s", errorCode, displacementVolume, blockedObjectName)
    if errorCode == TerrainDeformation.STATE_SUCCESS then
        callbackArgs.displacedVolume = callbackArgs.displacedVolume + displacementVolume
        callbackArgs.deformQueue = callbackArgs.deformQueue - 1
        if callbackArgs.deformQueue < 0 then
            Logging.error("queue count broken")
        end
        if callbackArgs.deformQueue == 0 then
            callbackArgs.areaDeformation:delete()
            callbackArgs.areaDeformation = nil
            callbackArgs.ridgeDeformationPaint:delete()
            callbackArgs.ridgeDeformationPaint = nil
            callbackArgs.ridgeDeformation:delete()
            callbackArgs.ridgeDeformation = nil
            callbackArgs.displacedVolume = nil
            self:onTerrainDeformationFinished(callbackArgs, callbackArgs.displacedVolume)
        end
    elseif callbackArgs ~= nil then
        g_terrainDeformationQueue:cancelJob(callbackArgs.areaDeformationJobId)
        g_terrainDeformationQueue:cancelJob(callbackArgs.ridgeDeformationJobId)
        g_terrainDeformationQueue:cancelJob(callbackArgs.ridgePaintJobId)
        if callbackArgs.areaDeformation then
            callbackArgs.areaDeformation:delete()
            callbackArgs.areaDeformation = nil
            callbackArgs.areaDeformationJobId = nil
        end
        if callbackArgs.ridgeDeformationPaint then
            callbackArgs.ridgeDeformationPaint:delete()
            callbackArgs.ridgeDeformationPaint = nil
            callbackArgs.ridgePaintJobId = nil
        end
        if callbackArgs.ridgeDeformation then
            callbackArgs.ridgeDeformation:delete()
            callbackArgs.ridgeDeformation = nil
            callbackArgs.ridgeDeformationJobId = nil
        end
        callbackArgs.deformQueue = nil
        self:onTerrainDeformationFailed(callbackArgs)
    end
end
function PlaceableRiceField:onPeriodChanged(period)
    local spec = self.spec_riceField
    if spec.fields ~= nil then
        local prevPeriod = period - 1
        local prevPeriod = prevPeriod == 0 and 12 or prevPeriod
        for fieldIndex, field in ipairs(spec.fields) do
            field.periodWaterLevelPerSqm[prevPeriod] = self:getWaterFillLevelPerSqm(fieldIndex)
            self:setWaterHeight(fieldIndex, -spec.waterMaxLevel * 0.5)
        end
    end
end
function PlaceableRiceField:onFinishedGrowthPeriod(period)
    local spec = self.spec_riceField
    if spec.fields ~= nil then
        local perlinFilter = PerlinNoiseFilter.new(spec.fruitTypes[1].terrainDataPlaneId, 11, 1, 0.5, nil)
        for fieldIndex, field in ipairs(spec.fields) do
            local waterFillLevelPerSqm = field.periodWaterLevelPerSqm[period]
            field.periodWaterLevelPerSqm[period] = nil
            if waterFillLevelPerSqm ~= nil then
                local densityMapPolygonFoliage = DensityMapPolygon.new()
                densityMapPolygonFoliage:updateFromPolygon2D(field.polygonFoliage)
                local riceFieldUpdateTask = RiceFieldUpdateTask.new()
                riceFieldUpdateTask:setArea(densityMapPolygonFoliage)
                riceFieldUpdateTask:performPerlinNoiseDestruction(spec.fruitTypes, waterFillLevelPerSqm, perlinFilter)
                riceFieldUpdateTask:enqueue()
            end
        end
    end
end
function PlaceableRiceField:getHasValidFields()
    for _, field in ipairs(self.spec_riceField.fields) do
        if field.polygon:getNumVertices() >= 3 then
            return true
        end
    end
    return false
end
function PlaceableRiceField.getFirstAndLastVertex(_, field)
    if field.polygon == nil then
        return nil
    else
        local numVerts = field.polygon:getNumVertices()
        if numVerts > 1 then
            local v1x, v1z = field.polygon:getVertex(1)
            local v2x, v2z = field.polygon:getVertex(numVerts)
            return v1x, v1z, v2x, v2z
        elseif numVerts == 1 then
            return field.polygon:getVertex(1)
        else
            return nil
        end
    end
end
function PlaceableRiceField.getNumVertices(_, field)
    return field.polygon == nil and 0 or field.polygon:getNumVertices()
end
function PlaceableRiceField:setWaterHeight(fieldIndex, height, skipSetDirty)
    local field = self:getFieldByIndex(fieldIndex)
    if field ~= nil then
        field.waterHeight = math.clamp(height, 0, self.spec_riceField.waterMaxLevel)
        local abswaterFillLevel = field.height + field.waterHeight
        local wx, _wy, wz = getWorldTranslation(field.mesh)
        setWorldTranslation(field.mesh, wx, abswaterFillLevel, wz)
        setWorldTranslation(field.mirrorMesh, wx, abswaterFillLevel, wz)
        setShaderParameter(field.mesh, "waterLevelPercentage", height / spec.waterMaxLevel)
        if field.fillingSplash ~= nil then
            local visible, densityMapPolygonFoliage, fieldUpdateTaskInner = getWorldTranslation(field.fillingSplash)
            setWorldTranslation(field.fillingSplash, visible, abswaterFillLevel + spec.fillingSplashYOffset, fieldUpdateTaskInner)
        end
        local visible = field.waterHeight > 0
        if getVisibility(field.mesh) ~= visible then
            setVisibility(field.mesh, visible)
            setVisibility(field.mirrorMesh, visible)
            if g_server ~= nil then
                local densityMapPolygonFoliage = DensityMapPolygon.new()
                densityMapPolygonFoliage:updateFromPolygon2D(field.polygon)
                local fieldUpdateTaskInner = FieldUpdateTask.new()
                fieldUpdateTaskInner:setName("PlaceableRiceField set water level")
                fieldUpdateTaskInner:setArea(densityMapPolygonFoliage)
                fieldUpdateTaskInner:setWaterLevel(visible and 1 or 0)
                fieldUpdateTaskInner:enqueue()
            end
            if visible then
                setCollisionFilterGroup(field.colMesh, CollisionFlag.WATER)
            else
                setCollisionFilterGroup(field.colMesh, CollisionFlag.PLACEMENT_BLOCKING)
            end
        end
        if self.isServer and not skipSetDirty then
            spec.fieldIndicesDirty[fieldIndex] = true
            self:raiseDirtyFlags(spec.waterPlanesDirtyFlag)
            self:raiseActive()
        end
        return field.waterHeight
    end
    Logging.error("unable to retrieve field for index %q", fieldIndex)
    printCallstack()
end
function PlaceableRiceField:setEffectVisibility(fieldIndex, isFilling, isEmptying)
    local field = self:getFieldByIndex(fieldIndex)
    if field ~= nil then
        field.isFilling = isFilling
        field.isEmptying = isEmptying
        setVisibility(field.fillingWater, isFilling)
        setVisibility(field.fillingSplash, isFilling)
        setVisibility(field.emptyingWater, isEmptying)
        setVisibility(field.emptyingSplash, isEmptying)
        if isFilling or isEmptying then
            setWorldTranslation(field.waterSoundLinkNode, getWorldTranslation(isFilling and field.fillingSplash or field.emptyingSplash))
            g_soundManager:playSample(field.pumpSound)
            g_soundManager:playSample(field.waterSound)
        else
            g_soundManager:stopSample(field.pumpSound)
            g_soundManager:stopSample(field.waterSound)
        end
        if g_server ~= nil then
            g_server:broadcastEvent(PlaceableRiceFieldEffectStateEvent.new(self, fieldIndex, isFilling, isEmptying), false)
        end
    end
end
function PlaceableRiceField:setWaterHeightTarget(fieldIndex, targetHeight, noEventSent)
    local field = self:getFieldByIndex(fieldIndex)
    if field == nil then
        return
    else
        local spec = self.spec_riceField
        local clampedHeight = math.clamp(targetHeight, 0, spec.waterMaxLevel)
        field.waterHeightTarget = clampedHeight
        if self.isServer then
            local isFilling = self:getWaterHeight(fieldIndex) < clampedHeight
            spec.fieldsPendingTargetWaterLevel[fieldIndex] = isFilling and PlaceableRiceField.FILL_DIRECTION.RISE or PlaceableRiceField.FILL_DIRECTION.EMPTY
            self:setEffectVisibility(fieldIndex, isFilling, not isFilling)
            if not noEventSent then
                g_server:broadcastEvent(PlaceableRiceFieldSetTargetHeightEvent.new(self, fieldIndex, clampedHeight))
            end
            self:raiseActive()
        elseif not noEventSent then
            g_client:getServerConnection():sendEvent(PlaceableRiceFieldSetTargetHeightEvent.new(self, fieldIndex, clampedHeight))
        end
    end
end
function PlaceableRiceField:getWaterHeightTarget(fieldIndex)
    local field = self:getFieldByIndex(fieldIndex)
    if field == nil then
        return nil
    else
        return field.waterHeightTarget
    end
end
function PlaceableRiceField:getWaterFillLevel(fieldIndex)
    local field = self:getFieldByIndex(fieldIndex)
    if field == nil then
        return nil
    else
        return field.waterHeight * field.areaSqm * 1000
    end
end
function PlaceableRiceField:getWaterHeight(fieldIndex)
    local field = self:getFieldByIndex(fieldIndex)
    if field == nil then
        return nil
    else
        return field.waterHeight
    end
end
function PlaceableRiceField:getWaterFillLevelPerSqm(fieldIndex)
    local field = self:getFieldByIndex(fieldIndex)
    if field == nil then
        return nil
    else
        return field.waterHeight * 1000
    end
end
function PlaceableRiceField:getFieldFillingState(fieldIndex)
    local spec = self.spec_riceField
    if spec.fieldsPendingTargetWaterLevel == nil then
        return nil
    else
        return spec.fieldsPendingTargetWaterLevel[fieldIndex]
    end
end
function PlaceableRiceField:getMaxWaterHeight()
    return self.spec_riceField.waterMaxLevel
end
function PlaceableRiceField:getArea(fieldIndex)
    local field = self:getFieldByIndex(fieldIndex)
    if field == nil then
        return nil
    else
        return field.areaSqm
    end
end
function PlaceableRiceField:getSupportedFruitTypes()
    return self.spec_riceField.fruitTypes
end
function PlaceableRiceField:playerTriggerCallback(triggerId, otherId, onEnter, onLeave, _)
    local player = g_localPlayer
    if player ~= nil and otherId == player.rootNode then
        local spec = self.spec_riceField
        local fieldIndex = spec.triggerToFieldIndex[triggerId]
        if fieldIndex == nil then
            return
        end
        if onEnter then
            spec.activatable:setRiceFieldIndex(fieldIndex)
            g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
            return
        end
        if onLeave then
            spec.activatable:setRiceFieldIndex(nil)
            g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
        end
    end
end
function PlaceableRiceField.renderEdges(_, field)
    local color = DebugUtil.tableToColor(field)
    field.polygon:renderEdges(field.height, color, false, true, true)
    local minX, maxX, minZ, maxZ = field.polygon:getBoundingBox()
    local area = field.polygon:getArea()
    if area > 0 then
        Utils.renderTextAtWorldPosition((minX + maxX) / 2, field.height, (minZ + maxZ) / 2, string.format("%dsqm", area), nil, nil, color:unpack())
    end
end
function PlaceableRiceField:getRiceFieldState(fieldIndex, callback, callbackTarget)
    local field = self:getFieldByIndex(fieldIndex)
    local infoTask = FieldGetInfoTask.new()
    local densityMapPolygon = DensityMapPolygon.new()
    densityMapPolygon:updateFromPolygon2D(field.polygon)
    infoTask:setArea(densityMapPolygon)
    infoTask:setFruitTypes(self:getSupportedFruitTypes())
    infoTask:setCallback(self.onRiceFieldStatusResult, self, {
        ["callback"] = callback,
        ["callbackTarget"] = callbackTarget
    })
    infoTask:enqueue()
end
function PlaceableRiceField.onRiceFieldStatusResult(_, ftGrowthStatePixels, totalTouchedPixels, callbackArgs)
    local labelMaxNumPixels = nil
    local maxFruitPixels = 0
    for label, numPixels in pairs(ftGrowthStatePixels) do
        if totalTouchedPixels * 0.1 < numPixels and maxFruitPixels < numPixels then
            labelMaxNumPixels = label
            maxFruitPixels = numPixels
        end
    end
    if labelMaxNumPixels == nil then
        callbackArgs.callback(callbackArgs.callbackTarget, FruitType.UNKNOWN, 0)
    else
        local fruitTypeName, stageIndex = unpack(string.split(labelMaxNumPixels, "|"))
        callbackArgs.callback(callbackArgs.callbackTarget, g_fruitTypeManager:getFruitTypeIndexByName(fruitTypeName), (tonumber(stageIndex)))
    end
end
function PlaceableRiceField.getRiceFieldAtPosition(x, y, z)
    local waterPlane = RaycastUtil.raycastClosest(x, y + 1, z, 0, -1, 0, 10, CollisionFlag.WATER + CollisionFlag.PLACEMENT_BLOCKING)
    if waterPlane == nil then
        return "Error: no water plane found.\nMake sure to be standing inside the a field"
    else
        local object = g_currentMission.nodeToObject[waterPlane]
        if object == nil or not (object:isa(Placeable) and SpecializationUtil.hasSpecialization(PlaceableRiceField, object.specializations)) then
            return "Error: no rice field placeable found.\nMake sure to be standing inside a rice field"
        else
            local field = object:getFieldByNode(waterPlane)
            if field == nil then
                return string.format("Error: no field found for water plane %q (%d)", getName(waterPlane), waterPlane)
            else
                return nil, object, waterPlane, field
            end
        end
    end
end
function PlaceableRiceField.consoleCommandSetWaterLevel(_, waterFillLevelPercentage)
    local x = tonumber(waterFillLevelPercentage)
    if x == nil or (x < 0 or x > 100) then
        printError("Error: no valid water level given")
        return "Usage: gsRiceFieldWaterSetLevel percentage[0..100]"
    end
    local x, y, z = g_localPlayer:getPosition()
    local errorMsg, object, _waterPlane, field = PlaceableRiceField.getRiceFieldAtPosition(x, y, z)
    if errorMsg == nil then
        object:setWaterHeight(table.find(object:getFields(), field), object.spec_riceField.waterMaxLevel * (x / 100))
        return string.format("Set water level to %.3fm (%d%%)", field.waterHeight, x)
    end
    printError(errorMsg)
end
function PlaceableRiceField.consoleCommandsetWaterShaderParameters(_, r, g, b, a, depthScale, refractionColorScale, getWaterDepthScale, inscatteringScale)
    local px, py, pz = g_localPlayer:getPosition()
    local errorMsg, _object, _waterPlane, field = PlaceableRiceField.getRiceFieldAtPosition(px, py, pz)
    if errorMsg == nil then
        local x = tonumber(r)
        local x = tonumber(g)
        local x = tonumber(b)
        local x = tonumber(a)
        local x = tonumber(depthScale)
        local x = tonumber(refractionColorScale)
        local x = tonumber(getWaterDepthScale)
        local x = tonumber(inscatteringScale)
        setShaderParameter(field.mesh, "underwaterFogColor", x, x, x, x, false)
        setShaderParameter(field.mesh, "underwaterFogDepth", x, x, x, x, false)
        setShaderParameter(field.mirrorMesh, "underwaterFogColor", x, x, x, x, false)
        setShaderParameter(field.mirrorMesh, "underwaterFogDepth", x, x, x, x, false)
        local x, y, z, w = getShaderParameter(field.mesh, "underwaterFogColor")
        local x2, y2, z2, w2 = getShaderParameter(field.mesh, "underwaterFogDepth")
        return string.format("underwaterFogColor %.3f %.3f %.3f %.3f\nunderwaterFogDepth %.3f %.3f %.3f %.3f", x, y, z, w, x2, y2, z2, w2)
    end
    printError(errorMsg)
end
function PlaceableRiceField.consoleCommandSetRiceState(_, fruitTypeName, stateIndex, groundAngle)
    local x = tonumber(stateIndex)
    local x, y, z = g_localPlayer:getPosition()
    local errorMsg, object, _waterPlane, field = PlaceableRiceField.getRiceFieldAtPosition(x, y, z)
    if errorMsg == nil then
        local densityMapPolygonFoliage, densityMapPolygonFoliage, densityMapPolygonFoliage
        if fruitTypeName and string.upper(fruitTypeName) == "NONE" then
            densityMapPolygonFoliage = FruitType.UNKNOWN
            densityMapPolygonFoliage = 0
            densityMapPolygonFoliage = FieldGroundType.CULTIVATED
        else
            densityMapPolygonFoliage = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)
            if densityMapPolygonFoliage == nil or table.find(object.spec_riceField.fruitTypes, densityMapPolygonFoliage) == nil then
                Logging.error("Unknown or unsupported fruitTypeName %q", fruitTypeName)
                return
            end
            densityMapPolygonFoliage = math.clamp(x or densityMapPolygonFoliage.minHarvestingGrowthState, 1, densityMapPolygonFoliage.numFoliageStates)
            densityMapPolygonFoliage = densityMapPolygonFoliage:getGrowthStateGroundType(densityMapPolygonFoliage)
        end
        local densityMapPolygonFoliage = DensityMapPolygon.new()
        densityMapPolygonFoliage:updateFromPolygon2D(field.polygonFoliage)
        local fieldUpdateTaskInner = FieldUpdateTask.new()
        fieldUpdateTaskInner:setArea(densityMapPolygonFoliage)
        if densityMapPolygonFoliage == FruitType.UNKNOWN then
            fieldUpdateTaskInner:setFruit(FruitType.UNKNOWN, densityMapPolygonFoliage)
        else
            fieldUpdateTaskInner:setFruit(densityMapPolygonFoliage.index, densityMapPolygonFoliage)
        end
        if densityMapPolygonFoliage ~= nil then
            fieldUpdateTaskInner:setGroundType(densityMapPolygonFoliage)
        end
        if groundAngle ~= nil then
            local maxAngle = math.rad(tonumber(groundAngle) or 0)
            local maxAngle = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.GROUND_ANGLE) + 1
            fieldUpdateTaskInner:setGroundAngle(math.clamp(maxAngle / 1.5707963267948966, 0, 1) * maxAngle)
        end
        fieldUpdateTaskInner:enqueue()
        return densityMapPolygonFoliage == FruitType.UNKNOWN and "Removed crops from rice field" or string.format("Updated rice field to %q at growth state %q (index %d)", densityMapPolygonFoliage.name, densityMapPolygonFoliage:getGrowthStateName(densityMapPolygonFoliage), densityMapPolygonFoliage)
    end
    printError(errorMsg)
end
function PlaceableRiceField.consoleCommandCreateRiceFieldFromField(_, fieldIndex)
    if g_server == nil then
        printError("Only allowed for server")
    else
        local field = nil
        if fieldIndex == nil then
            local x, _, z = g_localPlayer:getPosition()
            local farmland = g_farmlandManager:getFarmlandAtWorldPosition(x, z)
            if farmland ~= nil then
                field = farmland:getField()
            end
        else
            local x = tonumber(fieldIndex)
            if x == nil then
                return "Invalid field index"
            end
            field = g_fieldManager:getFieldById(x)
        end
        if field == nil then
            return "Unable to get field"
        end
        print(string.format("Trying to create rice field on field %s", field:getName()))
        local function x(buildStatus)
            if buildStatus == PlaceableRiceField.BUILD_STATUS.OK then
                print("successfully created rice field")
            else
                Logging.error("Failed to create rice field, reason: %s", EnumUtil.getName(PlaceableRiceField.BUILD_STATUS, buildStatus))
            end
        end
        local _ = {
            ["onPlaceableCreated"] = function(_, errorCode, _, objectId)
                -- upvalues: (ref) field, (copy) x
                if errorCode == BuyPlaceableEvent.STATE_SUCCESS then
                    local placeable = NetworkUtil.getObject(objectId)
                    local _, y, _ = getWorldTranslation(field.polygonPoints[1])
                    local riceField = placeable:createNewField(y)
                    local backupMin = PlaceableRiceField.MIN_VERTEX_DISTANCE
                    local backupMax = PlaceableRiceField.MAX_VERTEX_DISTANCE
                    PlaceableRiceField.MIN_VERTEX_DISTANCE = 1
                    PlaceableRiceField.MAX_VERTEX_DISTANCE = 1000
                    for _, point in ipairs(field.polygonPoints) do
                        local x, _, z = getWorldTranslation(point)
                        local success, errorMessage = placeable:addVertex(riceField, x, z)
                        if not success then
                            Logging.error("Unable to add vertex at %d %d: %s", x, z, errorMessage)
                            PlaceableRiceField.MIN_VERTEX_DISTANCE = backupMin
                            PlaceableRiceField.MAX_VERTEX_DISTANCE = backupMax
                            return
                        end
                    end
                    PlaceableRiceField.MIN_VERTEX_DISTANCE = backupMin
                    PlaceableRiceField.MAX_VERTEX_DISTANCE = backupMax
                    placeable:finalizeNewField(riceField, true, x)
                else
                    Logging.error("Failed to create rice field, unable to load rice field placeable")
                end
            end
        }
        local farmland = g_currentMission.placeableSystem:getExistingPlaceableByXMLFilename("data/placeables/brandless/riceField/riceField.xml", g_currentMission:getFarmId(), true)
        if farmland == nil then
            local data = BuyPlaceableData.new()
            data:setStoreItem((g_storeManager:getItemByXMLFilename("data/placeables/brandless/riceField/riceField.xml")))
            data:setPosition(0, 0, 0)
            data:setRotation(0, 0, 0)
            data:setIsFreeOfCharge(false)
            data:setConfigurations({})
            data:setOwnerFarmId(g_localPlayer.farmId)
            data:setDisplacementCosts(0)
            data:setModifyTerrain(false)
            data:updatePrice()
            g_messageCenter:subscribeOneshot(BuyPlaceableEvent, _.onPlaceableCreated, _)
            g_client:getServerConnection():sendEvent(BuyPlaceableEvent.new(data))
        else
            _.onPlaceableCreated(nil, BuyPlaceableEvent.STATE_SUCCESS, nil, farmland.id)
        end
    end
end