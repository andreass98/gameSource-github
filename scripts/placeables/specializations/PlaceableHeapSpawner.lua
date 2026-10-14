PlaceableHeapSpawner = {}
function PlaceableHeapSpawner.prerequisitesPresent(specializations)
    return true
end
function PlaceableHeapSpawner.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHeapSpawner)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHeapSpawner)
    SpecializationUtil.registerEventListener(placeableType, "onUpdateTick", PlaceableHeapSpawner)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHeapSpawner)
end
function PlaceableHeapSpawner.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("PlaceableHeapSpawner")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".heapSpawner.spawnArea(?).area#startNode", "")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".heapSpawner.spawnArea(?).area#widthNode", "")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".heapSpawner.spawnArea(?).area#heightNode", "")
    schema:register(XMLValueType.STRING, basePath .. ".heapSpawner.spawnArea(?)#fillType", "Spawn fill type")
    schema:register(XMLValueType.FLOAT, basePath .. ".heapSpawner.spawnArea(?)#litersPerHour", "Spawn liters per ingame hour")
    EffectManager.registerEffectXMLPaths(schema, basePath .. ".heapSpawner.spawnArea(?).effectNodes")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".heapSpawner.spawnArea(?).sounds", "work")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".heapSpawner.spawnArea(?).sounds", "work2")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".heapSpawner.spawnArea(?).sounds", "dropping")
    AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".heapSpawner.spawnArea(?).animationNodes")
    schema:setXMLSpecializationType()
end
function PlaceableHeapSpawner:onLoad(_)
    local spec = self.spec_heapSpawner
    spec.spawnAreas = {}
    for _, areaKey in self.xmlFile:iterator("placeable.heapSpawner.spawnArea") do
        local startNode = self.xmlFile:getValue(areaKey .. ".area#startNode", nil, self.components, self.i3dMappings)
        if startNode == nil then
            Logging.xmlError(self.xmlFile, "Missing startNode for spawnArea \'%s\'", areaKey)
        else
            local widthNode = self.xmlFile:getValue(areaKey .. ".area#widthNode", nil, self.components, self.i3dMappings)
            if widthNode == nil then
                Logging.xmlError(self.xmlFile, "Missing widthNode for spawnArea \'%s\'", areaKey)
            else
                local heightNode = self.xmlFile:getValue(areaKey .. ".area#heightNode", nil, self.components, self.i3dMappings)
                if heightNode == nil then
                    Logging.xmlError(self.xmlFile, "Missing heightNode for spawnArea \'%s\'", areaKey)
                else
                    local fillTypeName = self.xmlFile:getValue(areaKey .. "#fillType", "")
                    local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
                    if fillTypeIndex == nil then
                        Logging.xmlError(self.xmlFile, "Missing or invalid fillType (%s) for spawnArea \'%s\'", fillTypeName, areaKey)
                    else
                        local litersPerHour = self.xmlFile:getValue(areaKey .. "#litersPerHour", 150)
                        if litersPerHour <= 0 then
                            Logging.xmlError(self.xmlFile, "litersPerHour may not be 0 or negative for spawnArea \'%s\'", areaKey)
                        else
                            local spawnArea = {
                                ["start"] = startNode,
                                ["width"] = widthNode,
                                ["height"] = heightNode,
                                ["fillTypeIndex"] = fillTypeIndex,
                                ["litersPerMs"] = litersPerHour / 3600000,
                                ["amountToTip"] = 0,
                                ["lineOffset"] = 0
                            }
                            if self.isClient then
                                spawnArea.effects = g_effectManager:loadEffect(self.xmlFile, areaKey .. ".effectNodes", self.components, self, self.i3dMappings)
                                g_effectManager:setEffectTypeInfo(spawnArea.effects, fillTypeIndex)
                                g_effectManager:startEffects(spawnArea.effects)
                                spawnArea.samples = {}
                                spawnArea.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, areaKey .. ".sounds", "work", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
                                spawnArea.samples.work2 = g_soundManager:loadSampleFromXML(self.xmlFile, areaKey .. ".sounds", "work2", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
                                spawnArea.samples.dropping = g_soundManager:loadSampleFromXML(self.xmlFile, areaKey .. ".sounds", "dropping", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
                                g_soundManager:playSample(spawnArea.samples.work, 0)
                                g_soundManager:playSample(spawnArea.samples.work2, 0)
                                g_soundManager:playSample(spawnArea.samples.dropping, 0)
                                spawnArea.animationNodes = g_animationManager:loadAnimations(self.xmlFile, areaKey .. ".animationNodes", self.components, self, self.i3dMappings)
                                g_animationManager:startAnimations(spawnArea.animationNodes)
                            end
                            table.insert(spec.spawnAreas, spawnArea)
                        end
                    end
                end
            end
        end
    end
end
function PlaceableHeapSpawner:onFinalizePlacement(_)
    if self.isServer then
        self:raiseActive()
    end
end
function PlaceableHeapSpawner:onDelete()
    local spec = self.spec_heapSpawner
    if spec.spawnAreas ~= nil then
        for _, spawnArea in ipairs(spec.spawnAreas) do
            g_effectManager:deleteEffects(spawnArea.effects)
            g_soundManager:deleteSamples(spawnArea.samples)
            g_animationManager:deleteAnimations(spawnArea.animationNodes)
        end
    end
end
function PlaceableHeapSpawner:onUpdateTick(dt)
    if self.isServer then
        local scaledDt = dt * g_currentMission:getEffectiveTimeScale()
        for _, spawnArea in ipairs(self.spec_heapSpawner.spawnAreas) do
            spawnArea.amountToTip = spawnArea.amountToTip + scaledDt * spawnArea.litersPerMs
            if spawnArea.amountToTip > g_densityMapHeightManager:getMinValidLiterValue(spawnArea.fillTypeIndex) then
                local lsx, lsy, lsz, lex, ley, lez, radius = DensityMapHeightUtil.getLineByArea(spawnArea.start, spawnArea.width, spawnArea.height, false)
                local _, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(nil, spawnArea.amountToTip, spawnArea.fillTypeIndex, lsx, lsy, lsz, lex, ley, lez, radius, radius, spawnArea.lineOffset, nil, nil, nil)
                spawnArea.lineOffset = lineOffset
                spawnArea.amountToTip = 0
            end
        end
        self:raiseActive()
    end
end
function PlaceableHeapSpawner.loadSpecValueFillTypes(xmlFile, _, _, fillTypeNamesSet)
    for _, spawnArea in xmlFile:iterator("placeable.heapSpawner.spawnArea") do
        local fillTypesNamesString = xmlFile:getValue(spawnArea .. "#fillType")
        if fillTypesNamesString then
            fillTypeNamesSet = fillTypeNamesSet or {}
            fillTypeNamesSet[string.upper(fillTypesNamesString)] = true
        end
    end
    return fillTypeNamesSet
end