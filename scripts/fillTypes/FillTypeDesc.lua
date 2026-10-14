FillTypeDesc = {}
local FillTypeDesc_mt = Class(FillTypeDesc)
function FillTypeDesc.new(customMt)
    -- upvalues: (copy) FillTypeDesc_mt
    local self = setmetatable({}, customMt or FillTypeDesc_mt)
    self.index = nil
    self.name = "UNKNOWN"
    self.title = "Unknown"
    self.unitShort = ""
    self.achievementName = nil
    self.showOnPriceTable = false
    self.pricePerLiter = 0
    self.massPerLiter = 0.001
    self.maxPhysicalSurfaceAngle = 0.5235987755982988
    self.hudOverlayFilename = nil
    self.textureArrayIndex = nil
    self.layerTextures = {}
    self.layerTextures.diffuseMapFilename = nil
    self.layerTextures.normalMapFilename = nil
    self.layerTextures.heightMapFilename = nil
    self.layerTextures.displacementMapFilename = nil
    self.layerTextures.distanceFilename = nil
    self.layerTextures.isValid = false
    self.layerParameters = {}
    self.layerParameters.unitSize = 4
    self.layerParameters.displacementMaxHeight = 0.2
    self.layerParameters.blendContrast = 0.5
    self.layerParameters.noiseScale = 0.5
    self.layerParameters.fillBlendStart = 1
    self.layerParameters.porosityAtZeroRoughness = 0
    self.layerParameters.porosityAtFullRoughness = 0
    self.layerParameters.firmness = 0.5
    self.layerParameters.viscosity = 0.5
    self.layerParameters.firmnessWet = 0.5
    self.hudFilename = nil
    self.palletFilename = nil
    self.previousHourPrice = 0
    self.startPricePerLiter = 0
    self.totalAmount = 0
    self.economy = {}
    self.economy.factors = {}
    self.economy.history = {}
    self.economy.sychronizeData = true
    self.prioritizedEffectType = "ShaderPlaneEffect"
    self.fillSmokeColor = nil
    self.fruitSmokeColor = nil
    self.particles = {}
    self.alphaClip = {}
    self.alphaClip.value = 0.5
    self.alphaClip.sharpness = 0.5
    self.alphaClip.gradientScale = 1
    self.alphaClip.alphaScale = 1
    self.alphaClip.beltAlphaScale = 1
    self.finalized = false
    return self
end
function FillTypeDesc:loadFromXMLFile(xmlFile, key, baseDirectory, customEnvironment)
    self.name = xmlFile:getValue(key .. "#name")
    if not ClassUtil.getIsValidIndexName(self.name) then
        Logging.warning("\'%s\' is not a valid name for a fillType. Ignoring fillType!", self.name)
        return false
    end
    self.name = string.upper(self.name)
    self.title = xmlFile:getValue(key .. "#title", self.title, customEnvironment)
    self.achievementName = xmlFile:getValue(key .. "#achievementName", self.achievementName)
    self.showOnPriceTable = xmlFile:getValue(key .. "#showOnPriceTable", self.showOnPriceTable)
    self.unitShort = xmlFile:getValue(key .. "#unitShort", self.unitShort, customEnvironment)
    self.isBulkType = xmlFile:getValue(key .. "#isBulkType", false)
    self.isPalletType = xmlFile:getValue(key .. "#isPalletType", false)
    self.isBaleType = xmlFile:getValue(key .. "#isBaleType", false)
    self.massPerLiter = xmlFile:getValue(key .. ".physics#massPerLiter", self.massPerLiter * 1000) * 0.001
    self.maxPhysicalSurfaceAngle = Utils.getNoNilRad(xmlFile:getValue(key .. ".physics#maxPhysicalSurfaceAngle"), self.maxPhysicalSurfaceAngle)
    self.hudOverlayFilename = xmlFile:getValue(key .. ".image#hud", nil, baseDirectory) or self.hudOverlayFilename
    self.palletFilename = xmlFile:getValue(key .. ".pallet#filename", nil, baseDirectory) or self.palletFilename
    self.pricePerLiter = xmlFile:getValue(key .. ".economy#pricePerLiter", self.pricePerLiter)
    local economicCurve = {}
    xmlFile:iterate(key .. ".economy.factors.factor", function(_, factorKey)
        -- upvalues: (copy) xmlFile, (copy) economicCurve
        local period = xmlFile:getValue(factorKey .. "#period")
        local factor = xmlFile:getValue(factorKey .. "#value")
        if period ~= nil and factor ~= nil then
            economicCurve[period] = factor
        end
    end)
    local period = SeasonPeriod.EARLY_SPRING
    for period = period, SeasonPeriod.LATE_WINTER do
        self.economy.factors[period] = economicCurve[period] or (self.economy.factors[period] or 1)
        self.economy.history[period] = self.economy.factors[period] * self.pricePerLiter
    end
    self.layerTextures.diffuseMapFilename = xmlFile:getValue(key .. ".textures#diffuse", nil, baseDirectory) or self.layerTextures.diffuseMapFilename
    self.layerTextures.normalMapFilename = xmlFile:getValue(key .. ".textures#normal", nil, baseDirectory) or self.layerTextures.normalMapFilename
    self.layerTextures.heightMapFilename = xmlFile:getValue(key .. ".textures#height", nil, baseDirectory) or self.layerTextures.heightMapFilename
    self.layerTextures.displacementMapFilename = xmlFile:getValue(key .. ".textures#displacement", nil, baseDirectory) or self.layerTextures.displacementMapFilename
    self.layerTextures.distanceFilename = xmlFile:getValue(key .. ".textures#distance", nil, baseDirectory) or self.layerTextures.distanceFilename
    self.layerTextures.isValid = self.layerTextures.diffuseMapFilename ~= nil and self.layerTextures.normalMapFilename ~= nil and self.layerTextures.heightMapFilename ~= nil and self.layerTextures.displacementMapFilename ~= nil
    self.layerParameters.unitSize = xmlFile:getValue(key .. ".textures#unitSize", self.layerParameters.unitSize)
    self.layerParameters.displacementMaxHeight = xmlFile:getValue(key .. ".textures#displacementMaxHeight", self.layerParameters.displacementMaxHeight)
    self.layerParameters.blendContrast = xmlFile:getValue(key .. ".textures#blendContrast", self.layerParameters.blendContrast)
    self.layerParameters.noiseScale = xmlFile:getValue(key .. ".textures#noiseScale", self.layerParameters.noiseScale)
    self.layerParameters.fillBlendStart = xmlFile:getValue(key .. ".textures#fillBlendStart", self.layerParameters.fillBlendStart)
    self.layerParameters.porosityAtZeroRoughness = xmlFile:getValue(key .. ".textures#porosityAtZeroRoughness", self.layerParameters.porosityAtZeroRoughness)
    self.layerParameters.porosityAtFullRoughness = xmlFile:getValue(key .. ".textures#porosityAtFullRoughness", self.layerParameters.porosityAtFullRoughness)
    self.layerParameters.firmness = xmlFile:getValue(key .. ".textures#firmness", self.layerParameters.firmness)
    self.layerParameters.viscosity = xmlFile:getValue(key .. ".textures#viscosity", self.layerParameters.viscosity)
    self.layerParameters.firmnessWet = xmlFile:getValue(key .. ".textures#firmnessWet", self.layerParameters.firmness)
    self.prioritizedEffectType = xmlFile:getValue(key .. ".effects#prioritizedEffectType", self.prioritizedEffectType)
    self.fillSmokeColor = xmlFile:getValue(key .. ".effects#fillSmokeColor", self.fillSmokeColor, true)
    self.fruitSmokeColor = xmlFile:getValue(key .. ".effects#fruitSmokeColor", self.fruitSmokeColor, true)
    for _, particleKey in xmlFile:iterator(key .. ".effects.particle") do
        local particle = {
            ["particleType"] = xmlFile:getValue(particleKey .. "#particleType")
        }
        if particle.particleType == nil then
            Logging.xmlWarning(xmlFile, "Missing particleType in \'%s\'", particleKey)
        else
            particle.filename = xmlFile:getValue(particleKey .. "#filename", nil, baseDirectory)
            if particle.filename == nil then
                Logging.xmlWarning(xmlFile, "Missing filename in \'%s\'", particleKey)
            else
                particle.useFillTexture = xmlFile:getValue(particleKey .. "#useFillTexture", false)
                particle.emitCountScale = xmlFile:getValue(particleKey .. "#emitCountScale", 1)
                particle.spriteScaleX = xmlFile:getValue(particleKey .. "#spriteScaleX")
                particle.spriteScaleY = xmlFile:getValue(particleKey .. "#spriteScaleY")
                self.particles[particle.particleType] = particle
            end
        end
    end
    self.alphaClip = {}
    self.alphaClip.value = xmlFile:getValue(key .. ".effects.alphaClip#value", self.alphaClip.value)
    self.alphaClip.sharpness = xmlFile:getValue(key .. ".effects.alphaClip#sharpness", self.alphaClip.sharpness)
    self.alphaClip.gradientScale = xmlFile:getValue(key .. ".effects.alphaClip#gradientScale", self.alphaClip.gradientScale)
    self.alphaClip.alphaScale = xmlFile:getValue(key .. ".effects.alphaClip#alphaScale", self.alphaClip.alphaScale)
    self.alphaClip.beltAlphaScale = xmlFile:getValue(key .. ".effects.alphaClip#beltAlphaScale", self.alphaClip.beltAlphaScale)
    return true
end
function FillTypeDesc:finalize(force)
    if not self.finalized or force then
        self.finalized = true
        for _, particle in pairs(self.particles) do
            if force then
                local i3dNode, sharedLoadRequestId, failedReason = g_i3DManager:loadSharedI3DFile(particle.filename, false, false)
                self:particleShapeI3DFileLoaded(i3dNode, failedReason, particle)
                particle.sharedLoadRequestId = sharedLoadRequestId
            else
                particle.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(particle.filename, false, false, self.particleShapeI3DFileLoaded, self, particle)
            end
        end
    end
end
function FillTypeDesc.particleShapeI3DFileLoaded(_, i3dNode, _, particle)
    if i3dNode == 0 then
        return
    elseif getNumOfChildren(i3dNode) == 0 then
        Logging.error("i3d file %q does not contain a shape", particle.filename)
        delete(i3dNode)
        return
    else
        local node = getChildAt(i3dNode, 0)
        if getHasClassId(node, ClassIds.SHAPE) then
            particle.shape = node
            unlink(particle.shape)
            setVisibility(particle.shape, false)
            particle.materialId = getMaterial(particle.shape, 0)
            delete(i3dNode)
        else
            Logging.error("node %q in %q is not a shape", getName(node), particle.filename)
            delete(i3dNode)
        end
    end
end
function FillTypeDesc:delete()
    for _, particle in pairs(self.particles) do
        if particle.sharedLoadRequestId ~= nil then
            g_i3DManager:releaseSharedI3DFile(particle.sharedLoadRequestId)
            particle.sharedLoadRequestId = nil
        end
        if particle.shape ~= nil then
            delete(particle.shape)
            particle.shape = nil
        end
        particle.materialId = nil
    end
end
function FillTypeDesc:addTerrainFillLayer(terrainRootNodeId, index)
    local layerTextures = self.layerTextures
    if not layerTextures.isValid then
        Logging.error("Failed to create terrain fill layer. Fill type \'%s\' does not have textures defined!", self.name)
        return false
    end
    local layerParameters = self.layerParameters
    addTerrainFillLayer(terrainRootNodeId, self.name, layerTextures.diffuseMapFilename, layerTextures.normalMapFilename, layerTextures.heightMapFilename, layerTextures.displacementMapFilename, layerParameters.unitSize, layerParameters.displacementMaxHeight, layerParameters.blendContrast, layerParameters.noiseScale, layerParameters.fillBlendStart, layerParameters.porosityAtZeroRoughness, layerParameters.porosityAtFullRoughness, layerParameters.firmness, layerParameters.viscosity, layerParameters.firmnessWet)
    self.textureArrayIndex = index
    return true
end
function FillTypeDesc:addDistanceTexture(distanceConstr, index)
    if self.layerTextures.distanceFilename == nil or self.layerTextures.distanceFilename:len() <= 0 then
        Logging.error("Failed to create density height map distance texture array. Fill type \'%s\' does not have distance texture defined!", self.name)
        return false
    else
        distanceConstr:addTexture(index, self.layerTextures.distanceFilename, 3)
        return true
    end
end
function FillTypeDesc:getTextureUnitSize()
    return self.layerParameters.unitSize
end
function FillTypeDesc:getBeltEffectAlphaClipScale()
    return self.alphaClip.beltAlphaScale
end
function FillTypeDesc:setParticleSystemFillType(particleSystem, particleType, materialType, useFruitColor, emitCountScale, alphaScale)
    local customEmitCountScale = nil
    if materialType ~= nil then
        local particleUseFillTextureArray = true
        local particle = self.particles[particleType]
        if particle ~= nil and particle.shape ~= nil then
            setParticleShape(getGeometry(particleSystem.shape), particle.shape)
            setMaterial(particleSystem.shape, particle.materialId, 0)
            ParticleUtil.initEmitterScale(particleSystem, particleSystem.emitterShapeSize / particleSystem.defaultEmitterShapeSize * emitCountScale * particle.emitCountScale)
            if particle.spriteScaleX ~= nil then
                ParticleUtil.setParticleSystemSpriteScaleX(particleSystem, particle.spriteScaleX)
            end
            if particle.spriteScaleY ~= nil then
                ParticleUtil.setParticleSystemSpriteScaleY(particleSystem, particle.spriteScaleY)
            end
            if not particle.useFillTexture then
                particleUseFillTextureArray = false
            end
        end
        if particleUseFillTextureArray then
            local effectMaterial = g_materialManager:getBaseMaterialByName(materialType)
            if effectMaterial == nil then
                Logging.error("Failed to assign material to shader plane effect. Base Material \'%s\' not found!", materialType)
            else
                ParticleUtil.setMaterial(particleSystem, effectMaterial)
                setMaterial(particleSystem.shape, effectMaterial, 0)
                if getMaterialCustomShaderFilename(effectMaterial):contains("psSubUVShader") then
                    g_fillTypeManager:assignCustomFillTypeTextureArraysFromTerrain(particleSystem.shape, g_terrainNode, "fillTypeColorMap", "", "")
                else
                    g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(particleSystem.shape, g_terrainNode, true, true, true)
                end
            end
            if self.textureArrayIndex ~= nil then
                setShaderParameter(particleSystem.shape, "fillTypeId", self.textureArrayIndex - 1, 0, 0, 0, false)
            end
        end
        if string.lower(particleType):contains("smoke") or string.lower(materialType):contains("smoke") then
            local _
            if useFruitColor then
                _ = self.fruitSmokeColor or self.fillSmokeColor
            else
                _ = self.fillSmokeColor
            end
            if _ == nil then
                if getHasShaderParameter(particleSystem.shape, "colorAlpha") then
                    local _, _, _, a = getShaderParameter(particleSystem.shape, "colorAlpha")
                    setShaderParameter(particleSystem.shape, "colorAlpha", nil, nil, nil, a * (alphaScale or 1), false)
                end
            elseif getHasShaderParameter(particleSystem.shape, "colorAlpha") then
                setShaderParameter(particleSystem.shape, "colorAlpha", _[1], _[2], _[3], _[4] * (alphaScale or 1), false)
            end
        end
        if getHasShaderParameter(particleSystem.shape, "alphaClip") then
            setShaderParameter(particleSystem.shape, "alphaClip", self.alphaClip.value, self.alphaClip.sharpness, self.alphaClip.gradientScale, self.alphaClip.alphaScale, false)
        end
    end
    return customEmitCountScale
end
function FillTypeDesc:reloadData()
    if self.index ~= FillType.UNKNOWN then
        if self.xmlFilename ~= nil then
            self:delete()
            local fillTypesXMLFile = XMLFile.load("fillTypes", self.xmlFilename, FillTypeManager.xmlSchema)
            self:loadFromXMLFile(fillTypesXMLFile, self.xmlKey, self.xmlBaseDirectory, self.xmlCustomEnvironment)
            fillTypesXMLFile:delete()
            self:finalize(true)
            return
        end
        Logging.error("Failed to reload fillType data. Only possible with -scriptDebug!")
    end
end
function FillTypeDesc.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#name", "Name of fill type")
    schema:register(XMLValueType.L10N_STRING, basePath .. "#title", "Display name of fill type")
    schema:register(XMLValueType.STRING, basePath .. "#achievementName", "Name of linked archivement")
    schema:register(XMLValueType.BOOL, basePath .. "#showOnPriceTable", "Show fill type in pricing menu", false)
    schema:register(XMLValueType.L10N_STRING, basePath .. "#unitShort", "Unit short localization key")
    schema:register(XMLValueType.BOOL, basePath .. "#isBulkType", "Fill type can be sold as bulk (tipped via trailer for example)", false)
    schema:register(XMLValueType.BOOL, basePath .. "#isPalletType", "Fill type can be sold as pallet", false)
    schema:register(XMLValueType.BOOL, basePath .. "#isBaleType", "Fill type can be sold as bale", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".physics#massPerLiter", "Mass per liter/unit in kilograms", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".physics#maxPhysicalSurfaceAngle", "Max physical surface angle used on fill volumes", 30)
    schema:register(XMLValueType.FILENAME, basePath .. ".image#hud", "Path to hud image")
    schema:register(XMLValueType.FILENAME, basePath .. ".pallet#filename", "Pallet xml filename which is spawned on unloading")
    schema:register(XMLValueType.FLOAT, basePath .. ".economy#pricePerLiter", "Price per liter", 0)
    schema:register(XMLValueType.INT, basePath .. ".economy.factors.factor(?)#period", "Period index")
    schema:register(XMLValueType.FLOAT, basePath .. ".economy.factors.factor(?)#value", "Price factor to apply in this period")
    schema:register(XMLValueType.FILENAME, basePath .. ".textures#diffuse", "Path to fill plane diffuse map")
    schema:register(XMLValueType.FILENAME, basePath .. ".textures#normal", "Path to fill plane normal map")
    schema:register(XMLValueType.FILENAME, basePath .. ".textures#height", "Path to fill plane height map")
    schema:register(XMLValueType.FILENAME, basePath .. ".textures#displacement", "Path to fill plane displacement map")
    schema:register(XMLValueType.FILENAME, basePath .. ".textures#distance", "Path to fill plane distance diffuse map")
    schema:register(XMLValueType.FLOAT, basePath .. ".textures#unitSize", "Unit size for fill plane texture, in meters", 4)
    schema:register(XMLValueType.FLOAT, basePath .. ".textures#displacementMaxHeight", "Max height for displacement map, in meters", 0.2)
    schema:register(XMLValueType.FLOAT, basePath .. ".textures#blendContrast", "Blend contrast for texture", 0.5)
    schema:register(XMLValueType.FLOAT, basePath .. ".textures#noiseScale", "Noise scale for texture blending", 0.5)
    schema:register(XMLValueType.FLOAT, basePath .. ".textures#fillBlendStart", "Start of alpha blending region for fill layer (1.0 = no blending)", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".textures#porosityAtZeroRoughness", "Porosity of fill material at zero roughness", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".textures#porosityAtFullRoughness", "Porosity of fill material at full roughness", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".textures#firmness", "Firmness of fill plane (for tyre tracks)", 0.5)
    schema:register(XMLValueType.FLOAT, basePath .. ".textures#viscosity", "Viscosity of fill plane (for tyre tracks)", 0.5)
    schema:register(XMLValueType.FLOAT, basePath .. ".textures#firmnessWet", "Firmness of fill plane when terrain is wet (for tyre tracks)", 0.5)
    schema:register(XMLValueType.STRING, basePath .. ".effects#prioritizedEffectType", "Defines which effect type is priorized in e.g. unloading effects", "ShaderPlaneEffect")
    schema:register(XMLValueType.VECTOR_4, basePath .. ".effects#fillSmokeColor", "Color of smoke effects")
    schema:register(XMLValueType.VECTOR_4, basePath .. ".effects#fruitSmokeColor", "Color of fruit smoke effects")
    schema:register(XMLValueType.STRING, basePath .. ".effects.particle(?)#particleType", "Name of particle type")
    schema:register(XMLValueType.FILENAME, basePath .. ".effects.particle(?)#filename", "Path to the particle shape i3d file")
    schema:register(XMLValueType.BOOL, basePath .. ".effects.particle(?)#useFillTexture", "Use the fill type texture array for the particle meshes, or keep the material of the particle shape", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".effects.particle(?)#emitCountScale", "Emit count scale to use", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".effects.particle(?)#spriteScaleX", "Custom sprite scale X")
    schema:register(XMLValueType.FLOAT, basePath .. ".effects.particle(?)#spriteScaleY", "Custom sprite scale Y")
    schema:register(XMLValueType.FLOAT, basePath .. ".effects.alphaClip#value", "alpha clip value based on the shader formula (for particle with psColorShader)", 0.5)
    schema:register(XMLValueType.FLOAT, basePath .. ".effects.alphaClip#sharpness", "sharpness of the final alpha in the shader formula (for particle with psColorShader)", 0.5)
    schema:register(XMLValueType.FLOAT, basePath .. ".effects.alphaClip#gradientScale", "alphaMap gradient scale", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".effects.alphaClip#alphaScale", "baseMap alpha scale", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".effects.alphaClip#beltAlphaScale", "Scale of the alpha clip on belt / shader plane effects", 1)
end