PlaceableVine = {}
function PlaceableVine.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableFence, specializations)
end
function PlaceableVine.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "updateVineNode", PlaceableVine.updateVineNode)
    SpecializationUtil.registerFunction(placeableType, "updateVineVisuals", PlaceableVine.updateVineVisuals)
    SpecializationUtil.registerFunction(placeableType, "destroyVineArea", PlaceableVine.destroyVineArea)
    SpecializationUtil.registerFunction(placeableType, "getVineFruitTypeIndex", PlaceableVine.getVineFruitTypeIndex)
    SpecializationUtil.registerFunction(placeableType, "setShakingFactor", PlaceableVine.setShakingFactor)
    SpecializationUtil.registerFunction(placeableType, "harvestVine", PlaceableVine.harvestVine)
    SpecializationUtil.registerFunction(placeableType, "prepareVine", PlaceableVine.prepareVine)
    SpecializationUtil.registerFunction(placeableType, "getVineFruitType", PlaceableVine.getVineFruitType)
    SpecializationUtil.registerFunction(placeableType, "getHasSegmentTargetGrowthState", PlaceableVine.getHasSegmentTargetGrowthState)
    SpecializationUtil.registerFunction(placeableType, "getSegmentSideArea", PlaceableVine.getSegmentSideArea)
    SpecializationUtil.registerFunction(placeableType, "getSectionFactor", PlaceableVine.getSectionFactor)
    SpecializationUtil.registerFunction(placeableType, "getVineAreaByNode", PlaceableVine.getVineAreaByNode)
end
function PlaceableVine.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "doDeletePanel", PlaceableVine.doDeletePanel)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "generateSegmentPoles", PlaceableVine.generateSegmentPoles)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "deleteSegment", PlaceableVine.deleteSegment)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getCanBePlacedAt", PlaceableVine.getCanBePlacedAt)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getHasParallelSnapping", PlaceableVine.getHasParallelSnapping)
end
function PlaceableVine.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableVine)
    SpecializationUtil.registerEventListener(placeableType, "onCreateSegmentPanel", PlaceableVine)
end
function PlaceableVine.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Vine")
    schema:register(XMLValueType.STRING, basePath .. ".vine#fruitType", "Vine fruit type")
    schema:register(XMLValueType.FLOAT, basePath .. ".vine#width", "Vine width")
    schema:register(XMLValueType.FLOAT, basePath .. ".vine#length", "Vine length")
    schema:register(XMLValueType.FLOAT, basePath .. ".vine#thresholdFactor", "Section work threshold factor")
    schema:register(XMLValueType.INT, basePath .. ".vine#numLODOffsets", "Vine num lod offsets")
    schema:register(XMLValueType.INT, basePath .. ".vine#numSections", "Vine num sub sections")
    schema:register(XMLValueType.INT, basePath .. ".vine.growthStates#previewNodeIndex", "Node index of preview node")
    schema:register(XMLValueType.STRING, basePath .. ".vine.growthStates.growthState(?)#nodeIndex", "Growthstate node index. Relative to panel rootnode")
    schema:register(XMLValueType.INT, basePath .. ".vine.growthStates.growthState(?).foliage(?)#state", "Growthstate")
    schema:register(XMLValueType.INT, basePath .. ".vine.growthStates.growthState(?).foliage(?)#sectionState", "SectionState")
    schema:register(XMLValueType.INT, basePath .. ".vine.resetStates.resetState(?)#state", "Reset state")
    schema:register(XMLValueType.INT, basePath .. ".vine.resetStates.resetState(?)#targetState", "Reset target state")
    schema:register(XMLValueType.FLOAT, basePath .. ".vine.resetStates.resetState(?)#threshold", "Threshold to apply reset")
    schema:setXMLSpecializationType()
end
function PlaceableVine.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Vine")
    schema:register(XMLValueType.INT, basePath .. "#startGrowthState", "Vineyard start growth state")
    schema:setXMLSpecializationType()
end
function PlaceableVine:onLoad(savegame)
    local spec = self.spec_vine
    local xmlFile = self.xmlFile
    local fruitTypeName = xmlFile:getValue("placeable.vine#fruitType")
    if fruitTypeName == nil then
        Logging.xmlWarning(xmlFile, "Missing fruit type name")
        return
    else
        local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)
        if fruitType == nil then
            Logging.xmlWarning(xmlFile, "Fruit type \'%s\' not defined", fruitTypeName)
        else
            spec.fruitType = fruitType
            spec.length = xmlFile:getValue("placeable.vine#length", 1)
            spec.width = xmlFile:getValue("placeable.vine#width", 1)
            spec.thresholdFactor = xmlFile:getValue("placeable.vine#thresholdFactor", 0.5)
            spec.numLODOffsets = xmlFile:getValue("placeable.vine#numLODOffsets", 0)
            spec.numSections = math.max(xmlFile:getValue("placeable.vine#numSections", 1), 1)
            spec.sectionLength = spec.length / spec.numSections
            spec.vineSegments = {}
            spec.nodes = {}
            spec.growthStates = {}
            xmlFile:iterate("placeable.vine.growthStates.growthState", function(_, key)
                -- upvalues: (copy) xmlFile, (copy) fruitType, (copy) spec
                local nodeIndex = xmlFile:getValue(key .. "#nodeIndex")
                if nodeIndex == nil then
                    Logging.xmlWarning(xmlFile, "Missing growth state nodeIndex for \'%s\'", key)
                    return
                else
                    local foliageStates = {}
                    xmlFile:iterate(key .. ".foliage", function(_, foliageKey)
                        -- upvalues: (ref) xmlFile, (ref) fruitType, (copy) foliageStates
                        local state = xmlFile:getValue(foliageKey .. "#state")
                        if state == nil then
                            Logging.xmlWarning(xmlFile, "Missing foliage state for \'%s\'", foliageKey)
                            return
                        elseif state < 0 or fruitType.numStateChannels ^ 2 - 1 < state then
                            Logging.xmlWarning(xmlFile, "Invalid foliage state for \'%s\'", foliageKey)
                            return
                        else
                            local sectionState = xmlFile:getValue(foliageKey .. "#sectionState")
                            if sectionState == nil then
                                Logging.xmlWarning(xmlFile, "Missing foliage sectionState for \'%s\'", foliageKey)
                            else
                                table.insert(foliageStates, {
                                    ["state"] = state,
                                    ["sectionState"] = sectionState
                                })
                            end
                        end
                    end)
                    if #foliageStates == 0 then
                        Logging.xmlWarning(xmlFile, "Missing foliage states for growthstate \'%s\'", key)
                    else
                        spec.growthStates[nodeIndex] = foliageStates
                    end
                end
            end)
            spec.previewNodeIndex = xmlFile:getValue("placeable.vine.growthStates#previewNodeIndex", 0)
            spec.resetStates = {}
            xmlFile:iterate("placeable.vine.resetStates.resetState", function(_, key)
                -- upvalues: (copy) xmlFile, (copy) spec
                local state = xmlFile:getValue(key .. "#state")
                if state == nil then
                    Logging.xmlWarning(xmlFile, "Missing reset state for \'%s\'", key)
                    return
                else
                    local targetState = xmlFile:getValue(key .. "#targetState")
                    if targetState == nil then
                        Logging.xmlWarning(xmlFile, "Missing reset target state for \'%s\'", key)
                        return
                    else
                        local threshold = xmlFile:getValue(key .. "#threshold")
                        if threshold == nil then
                            Logging.xmlWarning(xmlFile, "Missing reset state threshold for \'%s\'", key)
                        else
                            local resetState = {
                                ["state"] = state,
                                ["targetState"] = targetState,
                                ["values"] = {}
                            }
                            resetState.values[state] = 0
                            resetState.threshold = threshold
                            table.insert(spec.resetStates, resetState)
                        end
                    end
                end
            end)
            spec.startGrowthState = nil
            if savegame ~= nil then
                spec.startGrowthState = savegame.xmlFile:getValue(savegame.key .. ".vine#startGrowthState")
            end
        end
    end
end
function PlaceableVine:deleteSegment(superFunc, segment)
    local spec = self.spec_vine
    if spec.vineSegments[segment] ~= nil then
        spec.vineSegments[segment] = nil
    end
    superFunc(self, segment)
end
function PlaceableVine:generateSegmentPoles(superFunc, segment, sync)
    local isPreviewSegment = segment == self:getPreviewSegment()
    if not isPreviewSegment then
        local spec = self.spec_vine
        local segmentData = spec.vineSegments[segment]
        if segmentData ~= nil then
            for _, data in ipairs(segmentData) do
                g_currentMission.vineSystem:removeElement(self, data.node, spec.width, spec.length)
                spec.nodes[data.node] = nil
            end
        end
        spec.vineSegments[segment] = {}
    end
    superFunc(self, segment, sync)
end
function PlaceableVine:onCreateSegmentPanel(isPreview, segment, panel, poleIndex, dy, pole)
    if not getAllowFoliageShadows() then
        local function disableShadows(node)
            if getHasClassId(node, ClassIds.SHAPE) then
                setShapeCastShadowmap(node, false)
            end
        end
        I3DUtil.iterateRecursively(panel, disableShadows)
        if pole ~= nil then
            I3DUtil.iterateRecursively(pole, disableShadows)
        end
    end
    if isPreview then
        local disableShadows = getChildAt(panel, 1)
        local data = getNumOfChildren(disableShadows) - 1
        for _ = 0, data do
            local dirX = getChildAt(disableShadows, _)
            setVisibility(dirX, _ == self.spec_vine.previewNodeIndex)
        end
    else
        local disableShadows = getChildAt(panel, 0)
        local data = {
            ["node"] = disableShadows,
            ["poleIndex"] = poleIndex
        }
        spec.nodes[disableShadows] = data
        local _ = spec.vineSegments[segment]
        table.insert(_, data)
        local x, _, z = getWorldTranslation(panel)
        local dirX, _, dirZ = localDirectionToWorld(panel, 0, 0, 1)
        local normX, _ = MathUtil.vector2Normalize(dirX, dirZ)
        local normX, _, normZ = MathUtil.crossProduct(normX, 0, _, 0, 1, 0)
        local sizeHalfX, maxState = MathUtil.vector2Normalize(normX, normZ)
        data.growthStates = {}
        for nodeIndex, foliageStates in pairs(spec.growthStates) do
            local stateNode = I3DUtil.indexToObject(panel, nodeIndex)
            if stateNode == nil then
                Logging.warning("Failed to get vine panel growth state node (\'%s\')", nodeIndex)
                return
            end
            data.growthStates[stateNode] = {
                ["foliageStates"] = foliageStates,
                ["value"] = 0,
                ["sectionStates"] = {}
            }
            setVisibility(stateNode, false)
            local i = 0
            local startX = getNumOfChildren(stateNode) - 1
            for i = i, startX do
                local lodNode = getChildAt(stateNode, i)
                if getNumOfChildren(lodNode) > 1 then
                    local j = 0
                    local heightX = getNumOfChildren(lodNode) - 1
                    for j = j, heightX do
                        local lodChildNode = getChildAt(lodNode, j)
                        local lodX, lodY, lodZ = getTranslation(lodChildNode)
                        setTranslation(lodChildNode, lodX, lodY + lodZ / spec.length * -dy, lodZ)
                        if spec.numLODOffsets > 0 and getHasShaderParameter(lodChildNode, "uvOffset") then
                            local uvOffset = math.random(0, spec.numLODOffsets - 1) * (1 / spec.numLODOffsets)
                            setShaderParameter(lodChildNode, "uvOffset", uvOffset, 0, 0, 0, false)
                        end
                    end
                end
            end
        end
        local maxState = 1
        local maxPixels = 0
        data.sections = {}
        data.growthValues = {}
        local stateNode = 1
        local nodeIndex = spec.numSections
        local foliageStates = 1
        for stateNode = stateNode, nodeIndex, foliageStates do
            local startX = x + normX * spec.sectionLength * (stateNode - 1) + spec.width * 0.5 * -sizeHalfX
            local startZ = z + _ * sectionLength * (stateNode - 1) + maxState * -sizeHalfX
            local i = startX + sizeHalfX * spec.width
            local lodNode = startZ + maxState * spec.width
            local heightX = startX + normX * sectionLength
            local heightZ = startZ + _ * sectionLength
            data.sections[stateNode] = {
                startX,
                startZ,
                i,
                lodNode,
                heightX,
                heightZ
            }
            data.growthValues[stateNode] = {
                ["totalArea"] = 0,
                ["values"] = {}
            }
            for lodY, lodZ in pairs(data.growthStates) do
                for _, foliageData in ipairs(lodZ.foliageStates) do
                    data.growthValues[stateNode].values[foliageData.state] = 0
                end
            end
            data.growthValues[stateNode].totalArea = FSDensityMapUtil.updateVineAreaValues(spec.fruitType.index, startX, startZ, i, lodNode, heightX, heightZ, data.growthValues[stateNode].values)
            for lodY, lodZ in pairs(data.growthValues[stateNode].values) do
                if maxPixels < lodZ then
                    maxState = lodY
                    maxPixels = lodZ
                end
            end
        end
        if not self.isLoadingFromSavegameXML or spec.startGrowthState ~= nil then
            if spec.startGrowthState ~= nil then
                maxState = spec.startGrowthState
            end
            local stateNode = 1
            for stateNode = stateNode, spec.numSections do
                local startX = data.sections[stateNode]
                FSDensityMapUtil.createVineArea(spec.fruitType.index, startX[1], startX[2], startX[3], startX[4], startX[5], startX[6], maxState)
            end
        end
        g_currentMission.vineSystem:addElement(self, disableShadows, spec.width, spec.length)
        self:updateVineNode(disableShadows, false)
    end
end
function PlaceableVine:doDeletePanel(superFunc, segment, segmentIndex, poleIndex)
    if segment == nil or #segment.poles < poleIndex then
        return
    end
    local isPreviewSegment = segment == self:getPreviewSegment()
    if not isPreviewSegment then
        local spec = self.spec_vine
        local segmentData = spec.vineSegments[segment]
        if segmentData ~= nil then
            for k, data in ipairs(segmentData) do
                if data.poleIndex == poleIndex then
                    spec.nodes[data.node] = nil
                    table.remove(segmentData, k)
                    g_currentMission.vineSystem:removeElement(self, data.node, spec.width, spec.length)
                    self:destroyVineArea(data)
                    break
                end
            end
        end
    end
    superFunc(self, segment, segmentIndex, poleIndex)
end
function PlaceableVine:getCanBePlacedAt(superFunc, x, y, z, _)
    if g_fruitTypeManager:getFruitTypeByIndex(self:getVineFruitTypeIndex()):getIsPlantableInPeriod(g_currentMission.missionInfo.growthMode, g_currentMission.environment.currentPeriod) then
        return superFunc(self, x, y, z)
    else
        return false, string.format(g_i18n:getText("warning_theSelectedFruitTypeCantBePlantedInThisPeriod"), g_i18n:formatPeriod())
    end
end
function PlaceableVine:getHasParallelSnapping(superFunc)
    return true
end
function PlaceableVine:destroyVineArea(data)
    if self.isServer then
        local i = 1
        for i = i, self.spec_vine.numSections do
            local section = data.sections[i]
            FSDensityMapUtil.destroyVineArea(spec.fruitType.index, section[1], section[2], section[3], section[4], section[5], section[6])
        end
    end
end
function PlaceableVine:getVineFruitTypeIndex()
    return self.spec_vine.fruitType.index
end
function PlaceableVine:updateVineNode(node, isGrowing)
    local spec = self.spec_vine
    local data = spec.nodes[node]
    if data == nil then
        return
    end
    if not entityExists(node) then
        return
    end
    if isGrowing then
        local startX, startZ, widthX, widthZ, heightX, heightZ = self:getVineAreaByNode(node)
        for _, resetState in ipairs(spec.resetStates) do
            local totalArea = FSDensityMapUtil.updateVineAreaValues(spec.fruitType.index, startX, startZ, widthX, widthZ, heightX, heightZ, resetState.values)
            local factor = 0
            if totalArea > 0 then
                factor = resetState.values[resetState.state] / totalArea
            end
            if self.isServer and (factor < 1 and resetState.threshold < factor) then
                FSDensityMapUtil.resetVineArea(spec.fruitType.index, startX, startZ, widthX, widthZ, heightX, heightZ, resetState.targetState)
                break
            end
        end
    end
    data.totalArea = 0
    if data.growthValues == nil then
        data.growthValues = {}
    end
    local widthX = 1
    local startX = spec.numSections
    local startZ = 1
    for widthX = widthX, startX, startZ do
        local widthZ = data.sections[widthX]
        if data.growthValues[widthX] == nil then
            data.growthValues[widthX] = {
                ["totalArea"] = 0,
                ["values"] = {}
            }
            for stateNode, growthStateData in pairs(data.growthStates) do
                for factor, foliageData in ipairs(growthStateData.foliageStates) do
                    data.growthValues[widthX].values[foliageData.state] = 0
                end
            end
        end
        data.growthValues[widthX].totalArea = FSDensityMapUtil.updateVineAreaValues(spec.fruitType.index, widthZ[1], widthZ[2], widthZ[3], widthZ[4], widthZ[5], widthZ[6], data.growthValues[widthX].values)
    end
    self:updateVineVisuals(data)
end
function PlaceableVine:updateVineVisuals(data)
    local maxValue = 0
    local growthStateNode = nil
    for stateNode, growthStateData in pairs(data.growthStates) do
        setVisibility(stateNode, false)
        growthStateData.value = 0
        local i = 1
        local sectionStates = self.spec_vine.numSections
        for i = i, sectionStates do
            local maxSectionValue = 0
            growthStateData.sectionStates[i] = 1
            for _, foliageState in ipairs(growthStateData.foliageStates) do
                local value = data.growthValues[i].values[foliageState.state]
                growthStateData.value = growthStateData.value + value
                if maxSectionValue <= value then
                    growthStateData.sectionStates[i] = foliageState.sectionState
                    maxSectionValue = value
                end
            end
        end
        if maxValue < growthStateData.value then
            if growthStateNode ~= nil then
                setVisibility(growthStateNode, false)
            end
            maxValue = growthStateData.value
            setVisibility(stateNode, true)
            local sectionStates = growthStateData.sectionStates
            I3DUtil.setShaderParameterRec(stateNode, "hideSectionStates", sectionStates[1], sectionStates[2], sectionStates[3], spec.sectionLength)
            growthStateNode = stateNode
        end
    end
end
function PlaceableVine:harvestVine(node, startX, startY, startZ, currentX, currentY, currentZ, callback, target)
    if self.isServer then
        local spec = self.spec_vine
        local data = spec.nodes[node]
        if data ~= nil then
            local needsUpdate = false
            local i = 1
            for i = i, spec.numSections do
                if self:getSectionFactor(node, i, startX, startY, startZ, currentX, currentY, currentZ) > spec.thresholdFactor then
                    local section = data.sections[i]
                    local area, totalArea, weedFactor, sprayFactor, plowFactor = FSDensityMapUtil.updateVineCutArea(spec.fruitType.index, section[1], section[2], section[3], section[4], section[5], section[6])
                    if area > 0 then
                        callback(target, self, area, totalArea, weedFactor, sprayFactor, plowFactor, spec.sectionLength)
                        needsUpdate = true
                    end
                end
            end
            if needsUpdate then
                self:updateVineNode(node, false)
            end
        end
    else
        return
    end
end
function PlaceableVine:setShakingFactor(node, worldX, worldY, worldZ, intensity)
    local data = self.spec_vine.nodes[node]
    if data ~= nil then
        for stateNode, _ in pairs(data.growthStates) do
            I3DUtil.setShaderParameterRec(stateNode, "harvestPosition", worldX, worldY, worldZ, intensity)
        end
    end
end
function PlaceableVine:prepareVine(node, startX, startY, startZ, currentX, currentY, currentZ)
    if not self.isServer then
        return 0
    end
    local spec = self.spec_vine
    local data = spec.nodes[node]
    if data == nil then
        return 0
    end
    local area = 0
    local i = 1
    for i = i, spec.numSections do
        if self:getSectionFactor(node, i, startX, startY, startZ, currentX, currentY, currentZ) > spec.thresholdFactor then
            local section = data.sections[i]
            local currentArea, _ = FSDensityMapUtil.updateVinePrepareArea(spec.fruitType.index, section[1], section[2], section[3], section[4], section[5], section[6])
        end
    end
    if area > 0 then
        self:updateVineNode(node, false)
    end
    return area
end
function PlaceableVine:getSectionFactor(node, i, startX, startY, startZ, currentX, currentY, currentZ)
    local spec = self.spec_vine
    local factor = 0
    local sectionStart = spec.sectionLength * (i - 1)
    local sectionEnd = spec.sectionLength * i
    local _, _, localStartZ = worldToLocal(node, startX, startY, startZ)
    local _, _, localCurrentZ = worldToLocal(node, currentX, currentY, currentZ)
    if localCurrentZ < localStartZ then
    end
    if localStartZ < sectionEnd and sectionStart < localCurrentZ then
        factor = math.abs(math.max(localStartZ, sectionStart) - math.min(localCurrentZ, sectionEnd)) / spec.sectionLength
    end
    return factor
end
function PlaceableVine:getVineAreaByNode(node)
    local spec = self.spec_vine
    local x, _, z = getWorldTranslation(node)
    local dirX, _, dirZ = localDirectionToWorld(node, 0, 0, 1)
    local normX, _, normZ = MathUtil.crossProduct(dirX, 0, dirZ, 0, 1, 0)
    local sizeHalfX = spec.width * 0.5
    local startX = x + normX * -sizeHalfX
    local startZ = z + normZ * -sizeHalfX
    return startX, startZ, startX + normX * spec.width, startZ + normZ * spec.width, startX + dirX * spec.length, startZ + dirZ * spec.length
end
function PlaceableVine:getVineFruitType()
    return self.spec_vine.fruitType.index
end
function PlaceableVine:getHasSegmentTargetGrowthState(segment, fruitTypeIndex, useHarvestStates, usePrepareStates)
    if fruitTypeIndex ~= self.spec_vine.fruitType.index then
        return false
    end
    local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(self.spec_vine.fruitType.index)
    local minState, maxState
    if usePrepareStates then
        minState = fruitTypeDesc.witheredState
        maxState = fruitTypeDesc.witheredState
    else
        if not useHarvestStates then
            return false
        end
        minState = fruitTypeDesc.minHarvestingGrowthState
        maxState = fruitTypeDesc.maxHarvestingGrowthState
    end
    if minState == nil or maxState == nil then
        return false
    end
    local data = self.spec_vine.vineSegments[segment]
    if data ~= nil then
        local i = 1
        for i = i, #data do
            local growthValues = data[i].growthValues
            local j = 1
            for j = j, #growthValues do
                for targetState = minState, maxState do
                    if growthValues[j].values[targetState] > 0 then
                        return true
                    end
                end
            end
        end
    end
    return false
end
function PlaceableVine:getSegmentSideArea(segment, segmentSide)
    local snapDistance = self:getSnapDistance()
    segmentSide = segmentSide or 1
    local dirX, dirZ = MathUtil.vector2Normalize(segment.x2 - segment.x1, segment.z2 - segment.z1)
    return segment.x1 + dirZ * segmentSide * snapDistance * 0.5, segment.z1 - dirX * segmentSide * snapDistance * 0.5, segment.x1 + dirZ * segmentSide * snapDistance * 0.4, segment.z1 - dirX * segmentSide * snapDistance * 0.4, segment.x2 + dirZ * segmentSide * snapDistance * 0.5, segment.z2 - dirX * segmentSide * snapDistance * 0.5
end