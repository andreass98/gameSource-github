MotionPathEffectManager = {}
MotionPathEffectManager.MOTION_PATH_SHADER_PARAMS = {
    "scrollPos",
    "fadeProgress",
    "visibilityCut",
    "density",
    "verticalOffset",
    "subUVspeed",
    "subUVelements",
    "sizeScale"
}
local MotionPathEffectManager_mt = Class(MotionPathEffectManager, AbstractManager)
g_xmlManager:addInitSchemaFunction(function()
    MotionPathEffectManager.createMotionPathEffectXMLSchema()
end)
function MotionPathEffectManager.new(customMt)
    -- upvalues: (copy) MotionPathEffectManager_mt
    return AbstractManager.new(customMt or MotionPathEffectManager_mt)
end
function MotionPathEffectManager:initDataStructures()
    self.xmlFiles = {}
    self.sharedLoadRequestIds = {}
    self.effectsByType = {}
    self.effects = {}
    self.modMotionPathEffectsToLoad = {}
end
function MotionPathEffectManager:loadMapData(xmlFile, missionInfo, baseDirectory)
    MotionPathEffectManager:superClass().loadMapData(self, xmlFile, missionInfo, baseDirectory)
    self.baseDirectory = baseDirectory
    local customEnvironment, _ = Utils.getModNameAndBaseDirectory(baseDirectory)
    self:loadMotionPathEffects(xmlFile, "map.motionPathEffects.motionPathEffect", baseDirectory, customEnvironment)
    local externalXMLFilename = getXMLString(xmlFile, "map.motionPathEffects#filename")
    if externalXMLFilename ~= nil then
        local externalXMLFilename = Utils.getFilename(externalXMLFilename, baseDirectory)
        if externalXMLFilename ~= nil then
            self:loadMotionPathEffectsFromExternalFile(externalXMLFilename, baseDirectory, customEnvironment)
        end
    end
    return true
end
function MotionPathEffectManager:loadQueuedModMotionPathEffects()
    if self.modMotionPathEffectsToLoad ~= nil then
        for _, modMotionPathEffect in ipairs(self.modMotionPathEffectsToLoad) do
            self:loadMotionPathEffectsFromExternalFile(modMotionPathEffect.filename, modMotionPathEffect.baseDirectory, modMotionPathEffect.customEnvironment)
        end
        self.modMotionPathEffectsToLoad = nil
    end
end
function MotionPathEffectManager:loadModMotionPathEffects(filename, baseDirectory, customEnvironment)
    if self.modMotionPathEffectsToLoad == nil then
        self:loadMotionPathEffectsFromExternalFile(filename, baseDirectory, customEnvironment)
    else
        table.insert(self.modMotionPathEffectsToLoad, {
            ["filename"] = filename,
            ["baseDirectory"] = baseDirectory,
            ["customEnvironment"] = customEnvironment
        })
    end
end
function MotionPathEffectManager:loadMotionPathEffectsFromExternalFile(filename, baseDirectory, customEnvironment)
    local externalXMLFile = XMLFile.load("motionPathXML", filename)
    if externalXMLFile ~= nil then
        self:loadMotionPathEffects(externalXMLFile.handle, "motionPathEffects.motionPathEffect", baseDirectory, customEnvironment)
        externalXMLFile:delete()
    end
end
function MotionPathEffectManager:loadMotionPathEffects(xmlFileHandle, key, baseDirectory, customEnvironment)
    local i = 0
    while true do
        local motionPathEffectKey = string.format("%s(%d)", key, i)
        if not hasXMLProperty(xmlFileHandle, motionPathEffectKey) then
            break
        end
        local filename = getXMLString(xmlFileHandle, motionPathEffectKey .. "#filename")
        if filename ~= nil then
            if string.contains(filename, ".i3d") then
                Logging.xmlError(xmlFileHandle, "Motion path effect filename \'%s\' is not allowed in \'%s\'. Please use a motion path effect xml file.", filename, motionPathEffectKey)
                return
            end
            self:loadMotionPathEffectsXML(filename, baseDirectory, customEnvironment)
        end
        i = i + 1
    end
end
function MotionPathEffectManager:loadMotionPathEffectsXML(filename, baseDirectory, customEnvironment)
    local xmlFilename = Utils.getFilename(filename, baseDirectory)
    local xmlFile = XMLFile.load("mapMotionPathEffects", xmlFilename, MotionPathEffectManager.xmlSchema)
    if xmlFile ~= nil then
        self.xmlFiles[xmlFile] = true
        xmlFile.xmlReferences = 0
        local i = 0
        while true do
            local motionPathEffectKey = string.format("motionPathEffects.motionPathEffect(%d)", i)
            if not xmlFile:hasProperty(motionPathEffectKey) then
                break
            end
            local effectClassName = xmlFile:getValue(motionPathEffectKey .. "#effectClass", "MotionPathEffect")
            if effectClassName ~= nil then
                local effectClass = g_effectManager:getEffectClass(effectClassName)
                if effectClass == nil then
                    if customEnvironment ~= nil and customEnvironment ~= "" then
                        effectClass = g_effectManager:getEffectClass(customEnvironment .. "." .. effectClassName)
                    end
                    if effectClass == nil then
                        effectClass = ClassUtil.getClassObject(effectClassName)
                    end
                end
                if effectClass == nil then
                    Logging.xmlError(xmlFile, "Unknown motion path effect class \'%s\' in \'%s\'", effectClassName, motionPathEffectKey)
                else
                    effectClass.loadEffectDefinitionFromXML({}, xmlFile, motionPathEffectKey .. ".typeDefinition")
                    motionPathEffect.effectClass = effectClass
                    motionPathEffect.effectClassName = effectClassName
                    motionPathEffect.effectTypes = {}
                    motionPathEffect.effectTypeStr = xmlFile:getValue(motionPathEffectKey .. "#effectType", "DEFAULT")
                    local effectTypes = motionPathEffect.effectTypeStr:split(" ")
                    for _, effectType in ipairs(effectTypes) do
                        table.insert(motionPathEffect.effectTypes, string.upper(effectType))
                    end
                    motionPathEffect.filename = xmlFile:getValue(motionPathEffectKey .. "#filename")
                    if motionPathEffect.filename == nil then
                        Logging.xmlError(xmlFile, "Missing filename for motion path effect \'%s\'", motionPathEffectKey)
                    else
                        xmlFile.xmlReferences = xmlFile.xmlReferences + 1
                        motionPathEffect.filename = Utils.getFilename(motionPathEffect.filename, baseDirectory)
                        local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(motionPathEffect.filename, false, false, self.motionPathEffectI3DFileLoaded, self, {
                            ["motionPathEffect"] = motionPathEffect,
                            ["xmlFile"] = xmlFile,
                            ["motionPathEffectKey"] = motionPathEffectKey,
                            ["baseDirectory"] = baseDirectory
                        })
                        table.insert(self.sharedLoadRequestIds, sharedLoadRequestId)
                    end
                end
            end
            i = i + 1
        end
        if xmlFile.xmlReferences == 0 then
            self.xmlFiles[xmlFile] = nil
            xmlFile:delete()
        end
    end
end
function MotionPathEffectManager:motionPathEffectI3DFileLoaded(i3dNode, _, args)
    local motionPathEffect = args.motionPathEffect
    local xmlFile = args.xmlFile
    local baseDirectory = args.baseDirectory
    if i3dNode ~= nil and i3dNode ~= 0 then
        local loadedMeshes = {}
        motionPathEffect.effectMeshes = {}
        xmlFile:iterate(args.motionPathEffectKey .. ".effectMeshes.effectMesh", function(_, key)
            -- upvalues: (copy) xmlFile, (copy) i3dNode, (copy) loadedMeshes, (copy) motionPathEffect, (copy) self
            local node = xmlFile:getValue(key .. "#node", nil, i3dNode)
            if node == nil or loadedMeshes[node] ~= nil then
                if node == nil then
                    Logging.xmlError(xmlFile, "Failed to load effect mesh node from xml (%s)", key)
                else
                    Logging.xmlError(xmlFile, "Failed to load effect mesh node from xml. Node already used. (%s)", key)
                end
            else
                local effectMesh = {
                    ["node"] = node,
                    ["rowLength"] = xmlFile:getValue(key .. "#rowLength", 30),
                    ["numRows"] = xmlFile:getValue(key .. "#numRows", 12),
                    ["skipPositions"] = xmlFile:getValue(key .. "#skipPositions", 0),
                    ["numVariations"] = xmlFile:getValue(key .. "#numVariations", 1)
                }
                if effectMesh.numVariations > 1 then
                    effectMesh.usedVariations = {}
                    local i = 1
                    for i = i, effectMesh.numVariations do
                        effectMesh.usedVariations[i] = false
                    end
                end
                effectMesh.parent = motionPathEffect
                self:loadCustomShaderSettingsFromXML(effectMesh, xmlFile, key)
                motionPathEffect.effectClass.loadEffectMeshFromXML(effectMesh, xmlFile, key)
                effectMesh.growthStates = motionPathEffect.growthStates
                table.insert(motionPathEffect.effectMeshes, effectMesh)
                loadedMeshes[node] = true
                return
            end
        end)
        motionPathEffect.effectMaterials = {}
        xmlFile:iterate(motionPathEffectKey .. ".effectMaterials.effectMaterial", function(_, key)
            -- upvalues: (copy) xmlFile, (copy) i3dNode, (copy) motionPathEffect, (copy) baseDirectory, (copy) self
            local node = xmlFile:getValue(key .. "#node", nil, i3dNode)
            if node == nil then
                Logging.xmlError(xmlFile, "Failed to load effect material from xml (%s)", key)
            else
                local effectMaterial = {
                    ["node"] = node,
                    ["materialId"] = getMaterial(node, 0),
                    ["parent"] = motionPathEffect,
                    ["lod"] = {}
                }
                xmlFile:iterate(key .. ".lod", function(_, lodKey)
                    -- upvalues: (ref) xmlFile, (ref) i3dNode, (copy) effectMaterial
                    local lodNode = xmlFile:getValue(lodKey .. "#node", nil, i3dNode)
                    if lodNode ~= nil then
                        table.insert(effectMaterial.lod, getMaterial(lodNode, 0))
                    end
                end)
                effectMaterial.customDiffuse = xmlFile:getValue(key .. ".textures#diffuse")
                if effectMaterial.customDiffuse ~= nil then
                    effectMaterial.customDiffuse = Utils.getFilename(effectMaterial.customDiffuse, baseDirectory)
                    effectMaterial.materialId = setMaterialDiffuseMapFromFile(effectMaterial.materialId, effectMaterial.customDiffuse, true, true, false)
                end
                effectMaterial.customNormal = xmlFile:getValue(key .. ".textures#normal")
                if effectMaterial.customNormal ~= nil then
                    effectMaterial.customNormal = Utils.getFilename(effectMaterial.customNormal, baseDirectory)
                    effectMaterial.materialId = setMaterialNormalMapFromFile(effectMaterial.materialId, effectMaterial.customDiffuse, true, false, false)
                end
                effectMaterial.customSpecular = xmlFile:getValue(key .. ".textures#specular")
                if effectMaterial.customSpecular ~= nil then
                    effectMaterial.customSpecular = Utils.getFilename(effectMaterial.customSpecular, baseDirectory)
                    effectMaterial.materialId = setMaterialGlossMapFromFile(effectMaterial.materialId, effectMaterial.customSpecular, true, true, false)
                end
                setMaterial(node, effectMaterial.materialId, 0)
                self:loadCustomShaderSettingsFromXML(effectMaterial, xmlFile, key)
                motionPathEffect.effectClass.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
                table.insert(motionPathEffect.effectMaterials, effectMaterial)
            end
        end)
        self:loadCustomShaderSettingsFromXML(motionPathEffect, xmlFile, motionPathEffectKey .. ".customShaderDefaults", baseDirectory)
        local j = 1
        for j = j, #motionPathEffect.effectMeshes do
            unlink(motionPathEffect.effectMeshes[j].node)
        end
        local j = 1
        for j = j, #motionPathEffect.effectMaterials do
            unlink(motionPathEffect.effectMaterials[j].node)
        end
        local j = 1
        for j = j, #motionPathEffect.effectTypes do
            local effectType = motionPathEffect.effectTypes[j]
            if self.effectsByType[effectType] == nil then
                self.effectsByType[effectType] = {}
            end
            table.insert(self.effectsByType[effectType], motionPathEffect)
        end
        table.insert(self.effects, motionPathEffect)
        delete(i3dNode)
    end
    xmlFile.xmlReferences = xmlFile.xmlReferences - 1
    if xmlFile.xmlReferences == 0 then
        self.xmlFiles[xmlFile] = nil
        xmlFile:delete()
    end
end
function MotionPathEffectManager.loadCustomShaderSettingsFromXML(_, target, xmlFile, key, baseDirectory)
    target.customShaderVariation = xmlFile:getValue(key .. ".customShaderVariation#name")
    target.customShaderMaps = {}
    xmlFile:iterate(key .. ".customShaderMap", function(_, parameterKey)
        -- upvalues: (copy) xmlFile, (copy) baseDirectory, (copy) target
        local customShaderMap = {
            ["name"] = xmlFile:getValue(parameterKey .. "#name"),
            ["filename"] = xmlFile:getValue(parameterKey .. "#filename")
        }
        customShaderMap.filename = Utils.getFilename(customShaderMap.filename, baseDirectory)
        if customShaderMap.name == nil or customShaderMap.filename == nil then
            Logging.xmlError(xmlFile, "Failed to load custom shader map from \'%s\'", parameterKey)
        else
            customShaderMap.texture = createMaterialTextureFromFile(customShaderMap.filename, true, false)
            if customShaderMap.texture ~= nil then
                table.insert(target.customShaderMaps, customShaderMap)
                return
            end
        end
    end)
    target.customShaderParameters = {}
    xmlFile:iterate(key .. ".customShaderParameter", function(_, parameterKey)
        -- upvalues: (copy) xmlFile, (copy) target
        local customShaderParameter = {
            ["name"] = xmlFile:getValue(parameterKey .. "#name"),
            ["value"] = xmlFile:getValue(parameterKey .. "#value", "0 0 0 0", true)
        }
        if customShaderParameter.name == nil or customShaderParameter.value == nil then
            Logging.xmlError(xmlFile, "Failed to load custom shader parameter from \'%s\'", parameterKey)
        else
            table.insert(target.customShaderParameters, customShaderParameter)
        end
    end)
end
function MotionPathEffectManager:unloadMapData()
    local i = 1
    for i = i, #self.effects do
        local effect = self.effects[i]
        self:deleteCustomShaderMaps(effect)
        local j = 1
        for j = j, #effect.effectMeshes do
            local effectMesh = effect.effectMeshes[j]
            if effectMesh.node ~= nil and entityExists(effectMesh.node) then
                delete(effectMesh.node)
                effectMesh.node = nil
            end
            self:deleteCustomShaderMaps(effectMesh)
        end
        local j = 1
        for j = j, #effect.effectMaterials do
            local effectMesh = effect.effectMaterials[j]
            if effectMesh.node ~= nil and entityExists(effectMesh.node) then
                delete(effectMesh.node)
                effectMesh.node = nil
            end
            self:deleteCustomShaderMaps(effectMesh)
        end
    end
    local i = 1
    for i = i, #self.sharedLoadRequestIds do
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestIds[i])
    end
    for effect, _ in pairs(self.xmlFiles) do
        self.xmlFiles[effect] = nil
        effect:delete()
    end
    MotionPathEffectManager:superClass().unloadMapData(self)
end
function MotionPathEffectManager.deleteCustomShaderMaps(_, entity)
    for _, customMap in ipairs(entity.customShaderMaps) do
        if customMap.texture ~= nil and entityExists(customMap.texture) then
            delete(customMap.texture)
            customMap.texture = nil
        end
    end
end
function MotionPathEffectManager:getSharedMotionPathEffect(motionPathEffectObject)
    local i = 1
    for i = i, #self.effects do
        local effect = self.effects[i]
        if motionPathEffectObject:getIsSharedEffectMatching(effect, false) then
            return effect
        end
    end
    local i = 1
    for i = i, #self.effects do
        local effect = self.effects[i]
        if motionPathEffectObject:getIsSharedEffectMatching(effect, true) then
            return effect
        end
    end
    return nil
end
function MotionPathEffectManager.getMotionPathEffectMesh(_, sharedEffect, motionPathEffectObject)
    local j = 1
    for j = j, #sharedEffect.effectMeshes do
        local effectMesh = sharedEffect.effectMeshes[j]
        if motionPathEffectObject:getIsEffectMeshMatching(effectMesh, false) then
            return effectMesh
        end
    end
    local j = 1
    for j = j, #sharedEffect.effectMeshes do
        local effectMesh = sharedEffect.effectMeshes[j]
        if motionPathEffectObject:getIsEffectMeshMatching(effectMesh, true) then
            return effectMesh
        end
    end
    return nil
end
function MotionPathEffectManager.getMotionPathEffectMaterial(_, sharedEffect, motionPathEffectObject)
    local i = 1
    for i = i, #sharedEffect.effectMaterials do
        local effectMaterial = sharedEffect.effectMaterials[i]
        if motionPathEffectObject:getIsEffectMaterialMatching(effectMaterial, false) then
            return effectMaterial
        end
    end
    local i = 1
    for i = i, #sharedEffect.effectMaterials do
        local effectMaterial = sharedEffect.effectMaterials[i]
        if motionPathEffectObject:getIsEffectMaterialMatching(effectMaterial, true) then
            return effectMaterial
        end
    end
    return nil
end
function MotionPathEffectManager:applyEffectConfiguration(sharedEffect, effectMesh, effectMaterial, clonedNodes, textureEntityId, overwrittenSpeedScale)
    if sharedEffect == nil or clonedNodes == nil then
        return overwrittenSpeedScale or 1
    end
    for _, clonedNode in ipairs(clonedNodes) do
        self:applyShaderSettingsParameters(clonedNode, sharedEffect)
        if effectMesh ~= nil then
            self:applyShaderSettingsParameters(clonedNode, effectMesh)
        end
        if effectMaterial ~= nil then
            self:applyShaderSettingsParameters(clonedNode, effectMaterial)
        end
        self:setEffectCustomMap(clonedNode, "shapeArray", textureEntityId)
        self:setEffectCustomMap(clonedNode, "animationArray", textureEntityId)
    end
    local speedScale = sharedEffect.speedScale or 0.5
    local speedScale = effectMesh.speedScale or speedScale
    if effectMaterial ~= nil then
    end
    return overwrittenSpeedScale or speedScale
end
function MotionPathEffectManager:applyShaderSettingsParameters(node, target)
    local i = 1
    for i = i, #target.customShaderMaps do
        local customShaderMap = target.customShaderMaps[i]
        self:setEffectCustomMap(node, customShaderMap.name, customShaderMap.texture)
    end
    if target.customShaderVariation ~= nil then
        self:setEffectCustomShaderVariation(node, target.customShaderVariation)
    end
    local i = 1
    for i = i, #target.customShaderParameters do
        local customShaderMap = target.customShaderParameters[i]
        setShaderParameterRecursive(node, customShaderMap.name, customShaderMap.value[1], customShaderMap.value[2], customShaderMap.value[3], customShaderMap.value[4], false)
    end
end
MotionPathEffectManager.setEffectShaderParameter = setShaderParameterRecursive
function MotionPathEffectManager.getEffectShaderParameter(_, node, name)
    if getHasClassId(node, ClassIds.SHAPE) then
        return getShaderParameter(node, name)
    end
    local numChildren = getNumOfChildren(node)
    local i = 1
    for i = i, numChildren do
        local child = getChildAt(node, i - 1)
        if getHasClassId(child, ClassIds.SHAPE) then
            return getShaderParameter(child, name)
        end
    end
    return 0, 0, 0, 0
end
function MotionPathEffectManager.setEffectCustomShaderVariation(_, node, variation)
    if getHasClassId(node, ClassIds.SHAPE) then
        local material = getMaterial(node, 0)
        local newMaterial = setMaterialCustomShaderVariation(material, variation, false)
        if newMaterial ~= material then
            setMaterial(node, newMaterial, 0)
        end
    end
    local material = getNumOfChildren(node)
    if material > 0 then
        local i = 1
        for i = i, material do
            local child = getChildAt(node, i - 1)
            if getHasClassId(child, ClassIds.SHAPE) then
                local material = getMaterial(child, 0)
                local newMaterial = setMaterialCustomShaderVariation(material, variation, false)
                if newMaterial ~= material then
                    setMaterial(child, newMaterial, 0)
                end
            end
        end
    end
end
function MotionPathEffectManager.setEffectCustomMapOnNode(_, node, name, textureEntityId)
    local material = getMaterial(node, 0)
    if textureEntityId ~= nil then
        local newMaterial = setMaterialCustomMap(material, name, textureEntityId, false)
        if newMaterial ~= material then
            setMaterial(node, newMaterial, 0)
        end
    end
end
function MotionPathEffectManager:setEffectCustomMap(node, name, textureEntityId)
    if getHasClassId(node, ClassIds.SHAPE) then
        self:setEffectCustomMapOnNode(node, name, textureEntityId)
    end
    local numChildren = getNumOfChildren(node)
    if numChildren > 0 then
        local i = 1
        for i = i, numChildren do
            local child = getChildAt(node, i - 1)
            if getHasClassId(child, ClassIds.SHAPE) then
                self:setEffectCustomMapOnNode(child, name, textureEntityId)
            end
        end
    end
end
function MotionPathEffectManager.setEffectMaterial(_, node, material)
    if getHasClassId(node, ClassIds.SHAPE) then
        setMaterial(node, material.materialId, 0)
    end
    local numChildren = getNumOfChildren(node)
    if numChildren > 0 then
        local i = 1
        for i = i, numChildren do
            local child = getChildAt(node, i - 1)
            if getHasClassId(child, ClassIds.SHAPE) then
                local materialId = material.materialId
                if i > 1 and material.lod[i] ~= nil then
                    materialId = material.lod[i]
                end
                setMaterial(child, materialId, 0)
            end
        end
    end
end
function MotionPathEffectManager.createMotionPathEffectXMLSchema()
    if MotionPathEffectManager.xmlSchema == nil then
        local schema = XMLSchema.new("mapMotionPathEffects")
        schema:register(XMLValueType.STRING, "motionPathEffects.motionPathEffect(?)#effectClass", "Effect class name")
        schema:register(XMLValueType.STRING, "motionPathEffects.motionPathEffect(?)#effectType", "Effect type name (can be multiple)")
        schema:register(XMLValueType.STRING, "motionPathEffects.motionPathEffect(?)#filename", "Path to effects i3d file")
        schema:register(XMLValueType.NODE_INDEX, "motionPathEffects.motionPathEffect(?).effectGeneration#rootNode", "(Only for automatic mesh generation) Mesh root node in maya file which has sub shapes")
        schema:register(XMLValueType.VECTOR_ROT, "motionPathEffects.motionPathEffect(?).effectGeneration#minRot", "(Only for automatic mesh generation) Min. random rotation")
        schema:register(XMLValueType.VECTOR_ROT, "motionPathEffects.motionPathEffect(?).effectGeneration#maxRot", "(Only for automatic mesh generation) Max. random rotation")
        schema:register(XMLValueType.VECTOR_SCALE, "motionPathEffects.motionPathEffect(?).effectGeneration#minScale", "(Only for automatic mesh generation) Min. random scale")
        schema:register(XMLValueType.VECTOR_SCALE, "motionPathEffects.motionPathEffect(?).effectGeneration#maxScale", "(Only for automatic mesh generation) Max. random scale")
        schema:register(XMLValueType.STRING, "motionPathEffects.motionPathEffect(?).effectGeneration#useFoliage", "(Only for automatic mesh generation) Name of foliage")
        schema:register(XMLValueType.INT, "motionPathEffects.motionPathEffect(?).effectGeneration#useFoliageStage", "(Only for automatic mesh generation) Foliage growth state")
        schema:register(XMLValueType.INT, "motionPathEffects.motionPathEffect(?).effectGeneration#useFoliageLOD", "(Only for automatic mesh generation) LOD to use")
        MotionPathEffect.registerEffectDefinitionXMLPaths(schema, "motionPathEffects.motionPathEffect(?).typeDefinition")
        TypedMotionPathEffect.registerEffectDefinitionXMLPaths(schema, "motionPathEffects.motionPathEffect(?).typeDefinition")
        CutterMotionPathEffect.registerEffectDefinitionXMLPaths(schema, "motionPathEffects.motionPathEffect(?).typeDefinition")
        CultivatorMotionPathEffect.registerEffectDefinitionXMLPaths(schema, "motionPathEffects.motionPathEffect(?).typeDefinition")
        PlowMotionPathEffect.registerEffectDefinitionXMLPaths(schema, "motionPathEffects.motionPathEffect(?).typeDefinition")
        WindrowerMotionPathEffect.registerEffectDefinitionXMLPaths(schema, "motionPathEffects.motionPathEffect(?).typeDefinition")
        schema:register(XMLValueType.NODE_INDEX, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)#node", "Index path in effect i3d")
        schema:register(XMLValueType.NODE_INDEX, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)#sourceNode", "(Only for automatic mesh generation) Index path to source object in maya file")
        schema:register(XMLValueType.INT, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)#rowLength", "Number of meshes on X axis (on effect texture)", 30)
        schema:register(XMLValueType.INT, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)#numRows", "Number of meshes on Y axis (on effect texture)", 12)
        schema:register(XMLValueType.INT, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)#skipPositions", "Number of skipped meshes on X axis", 0)
        schema:register(XMLValueType.INT, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)#numVariations", "Number of sub random variations", 1)
        schema:register(XMLValueType.VECTOR_SCALE, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)#boundingBox", "(Only for automatic mesh generation) Size of bounding box")
        schema:register(XMLValueType.VECTOR_TRANS, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)#boundingBoxCenter", "(Only for automatic mesh generation) Center of bounding box")
        schema:register(XMLValueType.NODE_INDEX, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?).lod(?)#sourceNode", "(Only for automatic mesh generation) Custom node for LOD")
        schema:register(XMLValueType.FLOAT, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?).lod(?)#distance", "(Only for automatic mesh generation) Distance of LOD")
        schema:register(XMLValueType.INT, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?).lod(?)#skipPositions", "(Only for automatic mesh generation) Custom skip positions")
        MotionPathEffectManager.registerCustomShaderSettingXMLPaths(schema, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)")
        MotionPathEffect.registerEffectMeshXMLPaths(schema, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)")
        TypedMotionPathEffect.registerEffectMeshXMLPaths(schema, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)")
        CutterMotionPathEffect.registerEffectMeshXMLPaths(schema, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)")
        CultivatorMotionPathEffect.registerEffectMeshXMLPaths(schema, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)")
        PlowMotionPathEffect.registerEffectMeshXMLPaths(schema, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)")
        WindrowerMotionPathEffect.registerEffectMeshXMLPaths(schema, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)")
        schema:register(XMLValueType.NODE_INDEX, "motionPathEffects.motionPathEffect(?).effectMaterials#rootNode", "(Only for automatic mesh generation) Node which will be copied over the effect i3d file (position index in i3d is then \'0|1\')")
        schema:register(XMLValueType.NODE_INDEX, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?)#node", "Material node")
        schema:register(XMLValueType.NODE_INDEX, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?).lod(?)#node", "LOD node")
        schema:register(XMLValueType.STRING, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?).textures#diffuse", "Path to custom diffuse map to apply")
        schema:register(XMLValueType.STRING, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?).textures#normal", "Path to custom normal map to apply")
        schema:register(XMLValueType.STRING, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?).textures#specular", "Path to custom specular map to apply")
        MotionPathEffectManager.registerCustomShaderSettingXMLPaths(schema, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?)")
        MotionPathEffect.registerEffectMaterialXMLPaths(schema, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?)")
        TypedMotionPathEffect.registerEffectMaterialXMLPaths(schema, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?)")
        CutterMotionPathEffect.registerEffectMaterialXMLPaths(schema, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?)")
        CultivatorMotionPathEffect.registerEffectMaterialXMLPaths(schema, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?)")
        PlowMotionPathEffect.registerEffectMaterialXMLPaths(schema, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?)")
        WindrowerMotionPathEffect.registerEffectMaterialXMLPaths(schema, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?)")
        MotionPathEffectManager.registerCustomShaderSettingXMLPaths(schema, "motionPathEffects.motionPathEffect(?).customShaderDefaults")
        MotionPathEffectManager.xmlSchema = schema
    end
end
function MotionPathEffectManager.registerCustomShaderSettingXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".customShaderVariation#name", "Shader variation to apply")
    schema:register(XMLValueType.STRING, basePath .. ".customShaderParameter(?)#name", "Name of shader parameter")
    schema:register(XMLValueType.VECTOR_4, basePath .. ".customShaderParameter(?)#value", "Value of shader parameter")
    schema:register(XMLValueType.STRING, basePath .. ".customShaderMap(?)#name", "Name of custom shader map")
    schema:register(XMLValueType.STRING, basePath .. ".customShaderMap(?)#filename", "Path to texture file")
end
function MotionPathEffectManager.registerMotionPathXMLFiles(schema, basePath)
    schema:register(XMLValueType.FILENAME, basePath .. ".motionPathEffects.motionPathEffect(?)#filename", "motion path effect xml config filename")
end
g_motionPathEffectManager = MotionPathEffectManager.new()