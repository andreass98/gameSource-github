DensityMapHeightUtil = {}
DensityMapHeightUtil.lastVehiclesInRange = {}
DensityMapHeightUtil.terrainDetailHeightId = nil
DensityMapHeightUtil.typeFirstChannel = nil
DensityMapHeightUtil.typeNumChannels = nil
DensityMapHeightUtil.heightFirstChannel = nil
DensityMapHeightUtil.heightNumChannels = nil
DensityMapHeightUtil.modifiersCache = nil
function DensityMapHeightUtil.initTerrain(_, _, detailHeightId)
    DensityMapHeightUtil.terrainDetailHeightId = detailHeightId
    DensityMapHeightUtil.typeFirstChannel = g_densityMapHeightManager.heightTypeFirstChannel
    DensityMapHeightUtil.typeNumChannels = g_densityMapHeightManager.heightTypeNumChannels
    DensityMapHeightUtil.heightFirstChannel = getDensityMapHeightFirstChannel(detailHeightId)
    DensityMapHeightUtil.heightNumChannels = getDensityMapHeightNumChannels(detailHeightId)
    DensityMapHeightUtil.modifiersCache = {}
end
function DensityMapHeightUtil.clearCache()
    DensityMapHeightUtil.lastVehiclesInRange = {}
    DensityMapHeightUtil.terrainDetailHeightId = nil
    DensityMapHeightUtil.typeFirstChannel = nil
    DensityMapHeightUtil.typeNumChannels = nil
    DensityMapHeightUtil.heightFirstChannel = nil
    DensityMapHeightUtil.heightNumChannels = nil
    DensityMapHeightUtil.modifiersCache = nil
end
function DensityMapHeightUtil.getCanTipToGround(fillTypeIndex)
    if g_densityMapHeightManager:getIsValid() then
        local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
        if heightType == nil then
            return false
        else
            return heightType.canBeTipped and true or false
        end
    else
        return false
    end
end
function DensityMapHeightUtil.getFillTypeAtLine(sx, sy, sz, ex, ey, ez, radius)
    if g_densityMapHeightManager:getIsValid() then
        local heightTypeIndex = getDensityMapHeightTypeAtWorldLine(g_densityMapHeightManager:getTerrainDetailHeightUpdater(), sx, sy, sz, ex, ey, ez, radius)
        local fillTypeIndex = g_densityMapHeightManager:getFillTypeIndexByDensityHeightMapIndex(heightTypeIndex)
        if fillTypeIndex ~= nil then
            return fillTypeIndex
        end
    end
    return FillType.UNKNOWN
end
function DensityMapHeightUtil.getFillTypeAtArea(x0, z0, x1, z1, x2, z2)
    local modifiers = DensityMapHeightUtil.modifiersCache.getFillTypeAtArea
    if modifiers == nil then
        modifiers = {
            ["typeModifier"] = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels),
            ["typeFilters"] = {}
        }
        local heightTypes = g_densityMapHeightManager:getDensityMapHeightTypes()
        if heightTypes ~= nil then
            for _, heightType in ipairs(heightTypes) do
                local typeFilter = DensityMapFilter.new(modifiers.typeModifier)
                typeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, heightType.index)
                modifiers.typeFilters[heightType] = typeFilter
            end
        end
        DensityMapHeightUtil.modifiersCache.getFillTypeAtArea = modifiers
    end
    if not g_densityMapHeightManager:getIsValid() then
        return FillType.UNKNOWN
    end
    local heightTypes = FillType.UNKNOWN
    local modifierType = modifiers.typeModifier
    modifierType:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
    if modifierType:executeGet() > 0 then
        for heightType, typeFilter in pairs(modifiers.typeFilters) do
            if modifierType:executeGet(typeFilter) > 0 then
                return heightType.fillTypeIndex
            end
        end
    end
    return heightTypes
end
function DensityMapHeightUtil.getFillLevelAtArea(fillTypeIndex, x0, z0, x1, z1, x2, z2)
    if not g_densityMapHeightManager:getIsValid() then
        return 0, 0, 0
    end
    local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
    if heightType == nil then
        return 0, 0, 0
    end
    local modifiers = DensityMapHeightUtil.modifiersCache.getFillLevelAtArea
    if modifiers == nil then
        modifiers = {
            ["heightModifier"] = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels)
        }
        modifiers.heightModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST_EXPAND)
        modifiers.heightFilter = DensityMapFilter.new(modifiers.heightModifier)
        modifiers.heightFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        modifiers.typeFilters = {}
        DensityMapHeightUtil.modifiersCache.getFillLevelAtArea = modifiers
    end
    local modifierHeight = modifiers.heightModifier
    local typeFilter = modifiers.typeFilters[fillTypeIndex]
    if typeFilter == nil then
        typeFilter = DensityMapFilter.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels)
        typeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, heightType.index)
        modifiers.typeFilters[fillTypeIndex] = typeFilter
    end
    modifierHeight:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
    local density, numPixels, totalNumPixels = modifierHeight:executeGet(modifiers.heightFilter, typeFilter)
    return density * g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex), numPixels, totalNumPixels
end
function DensityMapHeightUtil.getValueAtArea(x0, z0, x1, z1, x2, z2, filterSnow)
    local modifiers = DensityMapHeightUtil.modifiersCache.getValueAtArea
    if modifiers == nil then
        modifiers = {
            ["heightModifier"] = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels)
        }
        DensityMapHeightUtil.modifiersCache.getValueAtArea = modifiers
        modifiers.snowFilter = DensityMapFilter.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels)
        modifiers.snowFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, g_densityMapHeightManager:getDensityMapHeightTypeIndexByFillTypeIndex(FillType.SNOW))
    end
    local modifier = modifiers.heightModifier
    local snowFilter = nil
    if filterSnow then
        snowFilter = modifiers.snowFilter
    end
    modifier:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
    return modifier:executeGet(snowFilter)
end
function DensityMapHeightUtil.getHeightAtWorldPos(x, y, z)
    local height, delta = getDensityHeightAtWorldPos(DensityMapHeightUtil.terrainDetailHeightId, x, y, z)
    return height, delta
end
function DensityMapHeightUtil.getCollisionHeightAtWorldPos(x, y, z)
    if g_densityMapHeightManager:getIsValid() then
        return getDensityMapCollisionHeightAtWorldPos(g_densityMapHeightManager:getTerrainDetailHeightUpdater(), x, y, z)
    else
        return 0, 0
    end
end
function DensityMapHeightUtil.getVehiclesInRange(refVehicle, x, y, z, radiusSq)
    local i = #DensityMapHeightUtil.lastVehiclesInRange
    for i = i, 1, -1 do
        DensityMapHeightUtil.lastVehiclesInRange[i] = nil
    end
    for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
        if vehicle ~= refVehicle and vehicle.components ~= nil then
            for _, component in pairs(vehicle.components) do
                local cx, cy, cz = getWorldTranslation(component.node)
                if MathUtil.vector3LengthSq(x - cx, y - cy, z - cz) < radiusSq then
                    table.insert(DensityMapHeightUtil.lastVehiclesInRange, vehicle)
                    break
                end
            end
        end
    end
    return DensityMapHeightUtil.lastVehiclesInRange
end
function DensityMapHeightUtil.tipToGroundAroundLine(vehicle, delta, fillTypeIndex, sx, sy, sz, ex, ey, ez, innerRadius, radius, lineOffset, limitToLineHeight, occlusionAreas, useOcclusionAreas, applyChanges)
    if not g_densityMapHeightManager:getIsValid() then
        return 0, 0
    end
    local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
    if heightType == nil then
        return 0, 0
    end
    if occlusionAreas == nil and (vehicle ~= nil and vehicle.getTipOcclusionAreas ~= nil) then
        occlusionAreas = vehicle:getTipOcclusionAreas()
    end
    if radius == nil then
        local fixedFillTypeAreas = getDensityMapMaxHeight(DensityMapHeightUtil.terrainDetailHeightId)
        radius = fixedFillTypeAreas / math.tan(heightType.maxSurfaceAngle)
    end
    innerRadius = innerRadius == nil and 0 or innerRadius
    lineOffset = lineOffset == nil and 0 or lineOffset
    if limitToLineHeight == nil then
        limitToLineHeight = false
    end
    applyChanges = applyChanges == nil and true or applyChanges
    if delta < 0 then
        useOcclusionAreas = false
    end
    if delta > 0 then
        local fixedFillTypeAreas = g_densityMapHeightManager:getFixedFillTypesAreas()
        if fixedFillTypeAreas ~= nil then
            for area, fixedFillTypeArea in pairs(fixedFillTypeAreas) do
                if area ~= nil and fixedFillTypeArea ~= nil then
                    local validFillType = false
                    for availableFillType, _ in pairs(fixedFillTypeArea.fillTypes) do
                        if availableFillType == fillTypeIndex then
                            validFillType = true
                        end
                    end
                    if area ~= nil and not validFillType then
                        local x1, _, z1 = getWorldTranslation(area.start)
                        local availableFillType, _, z2 = getWorldTranslation(area.width)
                        local x3, _, z3 = getWorldTranslation(area.height)
                        if MathUtil.hasRectangleLineIntersection2D(x1, z1, availableFillType - x1, z2 - z1, x3 - x1, z3 - z1, sx, sz, ex - sx, ez - sz) then
                            return 0, 0
                        end
                    end
                end
            end
        end
        local convertingFillTypesAreas = g_densityMapHeightManager:getConvertingFillTypesAreas()
        if convertingFillTypesAreas ~= nil then
            for fixedFillTypeArea, validFillType in pairs(convertingFillTypesAreas) do
                if fixedFillTypeArea ~= nil and validFillType ~= nil then
                    local x1, _, z1 = getWorldTranslation(fixedFillTypeArea.start)
                    local availableFillType, _, z2 = getWorldTranslation(fixedFillTypeArea.width)
                    local x3, _, z3 = getWorldTranslation(fixedFillTypeArea.height)
                    if MathUtil.hasRectangleLineIntersection2D(x1, z1, availableFillType - x1, z2 - z1, x3 - x1, z3 - z1, sx, sz, ex - sx, ez - sz) then
                        if validFillType.fillTypes[fillTypeIndex] ~= true then
                            return 0, 0
                        end
                        fillTypeIndex = validFillType.fillTypeTarget
                        heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
                        if heightType == nil then
                            return 0, 0
                        end
                    end
                end
            end
        end
    end
    local fixedFillTypeAreas = g_densityMapHeightManager.fillToGroundScale * heightType.fillToGroundScale
    if useOcclusionAreas ~= nil and useOcclusionAreas then
        if occlusionAreas ~= nil then
            local convertingFillTypesAreas = g_densityMapHeightManager:getTerrainDetailHeightUpdater()
            if convertingFillTypesAreas ~= nil then
                for fixedFillTypeArea, validFillType in pairs(occlusionAreas) do
                    local x1, _, z1 = getWorldTranslation(validFillType.start)
                    local availableFillType, _, z2 = getWorldTranslation(validFillType.width)
                    local x3, _, z3 = getWorldTranslation(validFillType.height)
                    local allowPropagation = validFillType.allowPropagation
                    if allowPropagation == nil then
                        allowPropagation = false
                    end
                    addDensityMapHeightOcclusionArea(convertingFillTypesAreas, x1, _, z1, availableFillType - x1, _ - _, z2 - z1, x3 - x1, _ - _, z3 - z1, allowPropagation)
                    if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
                        local x = availableFillType + (x3 - x1)
                        local y = _ + (_ - _)
                        local z = z2 + (z3 - z1)
                        drawDebugTriangle(x1, _, z1, availableFillType, _, z2, x3, _, z3, 1, 0, 0, 0.5, false)
                        drawDebugTriangle(x, y, z, x3, _, z3, availableFillType, _, z2, 1, 0, 0, 0.5, false)
                        drawDebugTriangle(x3, _, z3, availableFillType, _, z2, x1, _, z1, 1, 0, 0, 0.5, false)
                        drawDebugTriangle(availableFillType, _, z2, x3, _, z3, x, y, z, 1, 0, 0, 0.5, false)
                    end
                end
            end
        end
        local convertingFillTypesAreas = g_densityMapHeightManager:getTerrainDetailHeightUpdater()
        if convertingFillTypesAreas ~= nil then
            local maxDistSq = (20 + 0.5 * MathUtil.vector3Length(sx - ex, sy - ey, sz - ez) + radius) ^ 2
            local x1 = DensityMapHeightUtil.getVehiclesInRange(vehicle, 0.5 * (sx + ex), 0.5 * (sy + ey), 0.5 * (sz + ez), maxDistSq)
            if x1 ~= nil then
                for _, z2 in pairs(x1) do
                    if z2.getTipOcclusionAreas ~= nil then
                        local x3 = z2:getTipOcclusionAreas()
                        for x, y in pairs(x3) do
                            local z, ys, zs = getWorldTranslation(y.start)
                            local xw, yw, zw = getWorldTranslation(y.width)
                            local xh, yh, zh = getWorldTranslation(y.height)
                            addDensityMapHeightOcclusionArea(convertingFillTypesAreas, z, ys, zs, xw - z, yw - ys, zw - zs, xh - z, yh - ys, zh - zs, false)
                            if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
                                local xV = xw + (xh - z)
                                local yV = yw + (yh - ys)
                                local zV = zw + (zh - zs)
                                drawDebugTriangle(z, ys, zs, xw, yw, zw, xh, yh, zh, 1, 0, 0, 0.5, false)
                                drawDebugTriangle(xV, yV, zV, xh, yh, zh, xw, yw, zw, 1, 0, 0, 0.5, false)
                                drawDebugTriangle(xh, yh, zh, xw, yw, zw, z, ys, zs, 1, 0, 0, 0.5, false)
                                drawDebugTriangle(xw, yw, zw, xh, yh, zh, xV, yV, zV, 1, 0, 0, 0.5, false)
                            end
                        end
                    end
                end
            end
        end
    end
    if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
        drawDebugLine(sx, sy, sz, 0, 1, 1, ex, ey, ez, 0, 1, 1)
        drawDebugLine(sx, sy, sz, 0, 1, 1, sx, sy, sz, 0, 1, 1)
        drawDebugLine(ex, ey, ez, 0, 1, 1, ex, ey, ez, 0, 1, 1)
    end
    local convertingFillTypesAreas = 0
    local lineLength = g_densityMapHeightManager:getTerrainDetailHeightUpdater()
    if lineLength ~= nil then
        local maxDistSq = delta * fixedFillTypeAreas
        if not applyChanges then
            maxDistSq = math.max(maxDistSq, g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex))
        end
        convertingFillTypesAreas, lineOffset = addDensityMapHeightAtWorldLine(lineLength, sx, sy, sz, ex, ey, ez, maxDistSq, heightType.index, innerRadius, radius, limitToLineHeight, lineOffset, applyChanges, g_currentMission.tireTrackSystem.tireTrackSystemId)
        if not applyChanges then
            convertingFillTypesAreas = math.min(convertingFillTypesAreas, maxDistSq)
        end
    end
    local convertingFillTypesAreas = convertingFillTypesAreas / fixedFillTypeAreas
    if math.abs(delta) - math.abs(convertingFillTypesAreas) >= 0.001 then
        delta = convertingFillTypesAreas
    end
    return delta, lineOffset
end
function DensityMapHeightUtil.getCanTipToGroundAroundLine(vehicle, delta, fillTypeIndex, sx, sy, sz, ex, ey, ez, innerRadius, radius, lineOffset, limitToLineHeight, occlusionAreas, useOcclusionAreas)
    local fillLevel, _ = DensityMapHeightUtil.tipToGroundAroundLine(vehicle, delta, fillTypeIndex, sx, sy, sz, ex, ey, ez, innerRadius, radius, lineOffset, limitToLineHeight, occlusionAreas, useOcclusionAreas, false)
    return fillLevel ~= 0
end
function DensityMapHeightUtil.removeFromGroundByArea(x0, z0, x1, z1, x2, z2, fillTypeIndex)
    if not g_densityMapHeightManager:getIsValid() then
        return 0
    end
    local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
    if heightType == nil then
        return 0
    end
    local modifiers = DensityMapHeightUtil.modifiersCache.removeFromGroundByArea
    if modifiers == nil then
        modifiers = {
            ["heightModifier"] = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels),
            ["typeModifier"] = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels),
            ["typeFilters"] = {}
        }
        DensityMapHeightUtil.modifiersCache.removeFromGroundByArea = modifiers
    end
    local typeFilter = modifiers.typeFilters[heightType]
    if typeFilter == nil then
        typeFilter = DensityMapFilter.new(modifiers.typeModifier)
        typeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, heightType.index)
        modifiers.typeFilters[heightType] = typeFilter
    end
    local heightModifier = modifiers.heightModifier
    local typeModifier = modifiers.typeModifier
    heightModifier:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
    typeModifier:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
    typeModifier:executeSet(0, typeFilter)
    return heightModifier:executeSetWithStats(0, typeFilter) * g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex)
end
function DensityMapHeightUtil.changeFillTypeAtArea(x0, z0, x1, z1, x2, z2, fillTypeIndex, newFillTypeIndex)
    if not g_densityMapHeightManager:getIsValid() then
        return 0
    end
    local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
    local newHeightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(newFillTypeIndex)
    if heightType == nil or newHeightType == nil then
        return 0
    end
    local modifiers = DensityMapHeightUtil.modifiersCache.changeFillTypeAtArea
    if modifiers == nil then
        modifiers = {
            ["typeModifier"] = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels),
            ["typeFilters"] = {}
        }
        DensityMapHeightUtil.modifiersCache.changeFillTypeAtArea = modifiers
    end
    local typeFilter = modifiers.typeFilters[heightType]
    if typeFilter == nil then
        typeFilter = DensityMapFilter.new(modifiers.typeModifier)
        typeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, heightType.index)
        modifiers.typeFilters[heightType] = typeFilter
    end
    local typeModifier = modifiers.typeModifier
    typeModifier:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
    return typeModifier:executeSetWithStats(newHeightType.index, typeFilter) * g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex)
end
function DensityMapHeightUtil.clearArea(x0, z0, x1, z1, x2, z2)
    local modifiers = DensityMapHeightUtil.modifiersCache.clearArea
    if modifiers == nil then
        modifiers = {
            ["heightModifier"] = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels),
            ["typeModifier"] = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels)
        }
        DensityMapHeightUtil.modifiersCache.clearArea = modifiers
    end
    local heightModifier = modifiers.heightModifier
    local typeModifier = modifiers.typeModifier
    heightModifier:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
    typeModifier:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
    heightModifier:executeSet(0)
    typeModifier:executeSet(0)
end
function DensityMapHeightUtil.multiModifierAddClearArea(multiModifier, filter1, filter2)
    local terrainDetailHeightId = DensityMapHeightUtil.terrainDetailHeightId
    local heightModifier = DensityMapModifier.new(terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels)
    local typeModifier = DensityMapModifier.new(terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels)
    multiModifier:addExecuteSet(0, heightModifier, filter1, filter2)
    multiModifier:addExecuteSet(0, typeModifier, filter1, filter2)
end
function DensityMapHeightUtil.clear(area)
    local modifiers = DensityMapHeightUtil.modifiersCache.clearArea
    if modifiers == nil then
        modifiers = {
            ["heightModifier"] = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels),
            ["typeModifier"] = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels)
        }
        DensityMapHeightUtil.modifiersCache.clearArea = modifiers
    end
    local heightModifier = modifiers.heightModifier
    local typeModifier = modifiers.typeModifier
    area:applyToModifier(heightModifier)
    area:applyToModifier(typeModifier)
    heightModifier:executeSet(0)
    typeModifier:executeSet(0)
    heightModifier:clearPolygonPoints()
    typeModifier:clearPolygonPoints()
end
function DensityMapHeightUtil.getDefaultMaxRadius(fillTypeIndex)
    local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
    if heightType == nil then
        return 0
    end
    return getDensityMapMaxHeight(DensityMapHeightUtil.terrainDetailHeightId) / math.tan(heightType.maxSurfaceAngle)
end
function DensityMapHeightUtil.getRoundedHeightValue(height)
    if not g_densityMapHeightManager:getIsValid() then
        return height
    end
    return math.floor(height * g_densityMapHeightManager.heightToDensityValue) / g_densityMapHeightManager.heightToDensityValue
end
function DensityMapHeightUtil.getHeightTypeDescAtWorldPos(x, y, z, radius)
    local terrainUpdater = g_densityMapHeightManager:getTerrainDetailHeightUpdater()
    local heightTypeIndex = getDensityMapHeightTypeAtWorldPos(terrainUpdater, x, y, z, radius)
    if heightTypeIndex == nil then
        return nil
    else
        return g_densityMapHeightManager:getDensityMapHeightTypeByIndex(heightTypeIndex)
    end
end
function DensityMapHeightUtil.getLineByAreaDimensions(sx, sy, sz, wx, wy, wz, hx, hy, hz, radiusOverlap)
    local swDirX = wx - sx
    local swDirY = wy - sy
    local swDirZ = wz - sz
    local shDirX = hx - sx
    local shDirY = hy - sy
    local shDirZ = hz - sz
    local swLength = MathUtil.vector3Length(swDirX, swDirY, swDirZ)
    local shLength = MathUtil.vector3Length(shDirX, shDirY, shDirZ)
    local shDirX = shDirX / shLength
    local shDirY = shDirY / shLength
    local shDirZ = shDirZ / shLength
    local swDirX = swDirX / swLength
    local swDirY = swDirY / swLength
    local swDirZ = swDirZ / swLength
    if shLength < swLength then
        local radius = shLength * 0.5
        local shrink = radiusOverlap ~= nil and radiusOverlap and 0 or radius
        return sx + shDirX * shLength * 0.5 + swDirX * shrink, sy + shDirY * shLength * 0.5 + swDirY * shrink, sz + shDirZ * shLength * 0.5 + swDirZ * shrink, wx + shDirX * shLength * 0.5 - swDirX * shrink, wy + shDirY * shLength * 0.5 - swDirY * shrink, wz + shDirZ * shLength * 0.5 - swDirZ * shrink, radius
    else
        local radius = swLength * 0.5
        local shrink = radiusOverlap ~= nil and radiusOverlap and 0 or radius
        return sx + swDirX * swLength * 0.5 + shDirX * shrink, sy + swDirY * swLength * 0.5 + shDirY * shrink, sz + swDirZ * swLength * 0.5 + shDirZ * shrink, hx + swDirX * swLength * 0.5 - shDirX * shrink, hy + swDirY * swLength * 0.5 - shDirY * shrink, hz + swDirZ * swLength * 0.5 - shDirZ * shrink, radius
    end
end
function DensityMapHeightUtil.getLineByArea(start, width, height, radiusOverlap)
    local sx, sy, sz = getWorldTranslation(start)
    local wx, wy, wz = getWorldTranslation(width)
    local hx, hy, hz = getWorldTranslation(height)
    return DensityMapHeightUtil.getLineByAreaDimensions(sx, sy, sz, wx, wy, wz, hx, hy, hz, radiusOverlap)
end
function DensityMapHeightUtil.getAreaPartitions(start, width, height)
    local sx, sy, sz = getWorldTranslation(start)
    local wx, wy, wz = getWorldTranslation(width)
    local hx, hy, hz = getWorldTranslation(height)
    local areas = {}
    local distance = MathUtil.vector3Length(hx - sx, hy - sy, hz - sz)
    local dirX, dirY, dirZ = MathUtil.vector3Normalize(hx - sx, hy - sy, hz - sz)
    if distance <= 4 then
        table.insert(areas, {
            ["start"] = start,
            ["width"] = width,
            ["height"] = height
        })
        return areas
    end
    local numSubareas = math.ceil(distance / 4)
    local i = 1
    for i = i, numSubareas do
        local subStart = createTransformGroup("start" .. i)
        local subWidth = createTransformGroup("width" .. i)
        local subHeight = createTransformGroup("height" .. i)
        link(start, subStart)
        link(width, subWidth)
        link(height, subHeight)
        setWorldTranslation(subStart, sx + dirX * (distance / numSubareas) * (i - 1), sy + dirY * (distance / numSubareas) * (i - 1), sz + dirZ * (distance / numSubareas) * (i - 1))
        setWorldTranslation(subWidth, wx + dirX * areaSize * (i - 1), wy + dirY * areaSize * (i - 1), wz + dirZ * areaSize * (i - 1))
        setWorldTranslation(subHeight, sx + dirX * areaSize * i, sy + dirY * areaSize * i, sz + dirZ * areaSize * i)
        table.insert(areas, {
            ["start"] = subStart,
            ["width"] = subWidth,
            ["height"] = subHeight
        })
    end
    return areas
end
function DensityMapHeightUtil.smoothAroundLine(node, width, radius, overlap, smoothAmount, resetDisplacement)
    local r = width / (radius * 2 / overlap)
    local steps = math.ceil(r)
    local r = width / steps * 0.5
    local heightType = nil
    local step = 1
    for step = step, steps do
        local x, y, z = localToWorld(node, -(width * 0.5) + r * 2 * (step - 0.5), 0, 0)
        local smoothGroundRadius = r * overlap
        heightType = heightType or DensityMapHeightUtil.getHeightTypeDescAtWorldPos(x, y, z, smoothGroundRadius)
        if heightType ~= nil and heightType.allowsSmoothing then
            local terrainHeightUpdater = g_densityMapHeightManager:getTerrainDetailHeightUpdater()
            if terrainHeightUpdater ~= nil then
                local densityHeight = DensityMapHeightUtil.getHeightAtWorldPos(x, y, z)
                if y < densityHeight then
                    smoothDensityMapHeightAtWorldPos(terrainHeightUpdater, x, densityHeight - heightType.collisionBaseOffset, z, smoothAmount, heightType.index, 0, smoothGroundRadius, smoothGroundRadius + 1.2, g_currentMission.tireTrackSystem.tireTrackSystemId)
                    if resetDisplacement then
                        FSDensityMapUtil.resetDisplacementArea(x - radius * 0.5, z - radius * 0.5, x - radius * 0.5, z + radius * 0.5, x + radius * 0.5, z - radius * 0.5)
                    end
                    if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
                        DebugGizmo.renderAtPosition(x, y, z, 0, 0, 1, 0, 1, 0, "smooth DM", false)
                        DebugUtil.drawDebugCircle(x, densityHeight - heightType.collisionBaseOffset, z, smoothGroundRadius, 10)
                        if resetDisplacement then
                            local disp_x, disp_z, widthX, widthZ, heightX, heightZ = MathUtil.getXZWidthAndHeight(x - radius * 0.5, z - radius * 0.5, x - radius * 0.5, z + radius * 0.5, x + radius * 0.5, z - radius * 0.5)
                            DebugUtil.drawDebugParallelogram(disp_x, disp_z, widthX, widthZ, heightX, heightZ, 0.1, 1, 0, 0, 1)
                        end
                    end
                end
            end
        end
    end
end