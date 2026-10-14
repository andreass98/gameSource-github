local originalSplitFunc = splitShape
SplitShapeUtil = {}
SplitShapeUtil.SPLIT_SHAPES = {}
SplitShapeUtil.callbackFunc = nil
SplitShapeUtil.callbackTarget = nil
function SplitShapeUtil.onSplitShapeCallback(_, shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
    table.insert(SplitShapeUtil.SPLIT_SHAPES, {
        ["shape"] = shape,
        ["isBelow"] = isBelow,
        ["isAbove"] = isAbove,
        ["minY"] = minY,
        ["maxY"] = maxY,
        ["minZ"] = minZ,
        ["maxZ"] = maxZ
    })
    local target = SplitShapeUtil.callbackTarget
    target[SplitShapeUtil.callbackFunc](target, shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
end
function SplitShapeUtil.splitShape(shape, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, callback, target)
    -- upvalues: (copy) originalSplitFunc
    if entityExists(shape) and getHasClassId(shape, ClassIds.MESH_SPLIT_SHAPE) then
        local tx, ty, tz = getWorldTranslation(shape)
        local rx, ry, rz = getWorldRotation(shape)
        local data = {
            ["shape"] = shape,
            ["splitTypeIndex"] = getSplitType(shape),
            ["volume"] = getVolume(shape),
            ["x"] = tx,
            ["y"] = ty,
            ["z"] = tz,
            ["rx"] = rx,
            ["ry"] = ry,
            ["rz"] = rz,
            ["alreadySplit"] = getIsSplitShapeSplit(shape)
        }
        if target == nil then
            local parts = string.split(callback, ".")
            if #parts == 2 then
                target = _G[parts[1]]
                callback = parts[2]
            end
        end
        SplitShapeUtil.callbackFunc = callback
        SplitShapeUtil.callbackTarget = target
        SplitShapeUtil.SPLIT_SHAPES = {}
        originalSplitFunc(shape, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, "onSplitShapeCallback", SplitShapeUtil)
        g_messageCenter:publish(MessageType.SPLIT_SHAPE, data, SplitShapeUtil.SPLIT_SHAPES)
    end
end
function _G.splitShape(shape, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, callback, target)
    SplitShapeUtil.splitShape(shape, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, callback, target)
end
function SplitShapeUtil.getTreeOffsetPosition(shapeId, x, y, z, maxRadius, minLength)
    local localX, localY, localZ = worldToLocal(shapeId, x, y, z)
    local cx, cy, cz = localToWorld(shapeId, localX - maxRadius * 0.5, localY, localZ - maxRadius * 0.5)
    local nx, ny, nz = localDirectionToWorld(shapeId, 0, 1, 0)
    local yx, yy, yz = localDirectionToWorld(shapeId, 0, 0, 1)
    local minY, maxY, minZ, maxZ = testSplitShape(shapeId, cx, cy, cz, nx, ny, nz, yx, yy, yz, maxRadius, maxRadius)
    if minY == nil then
        return nil
    end
    if minLength ~= nil then
        local lengthBelow, lengthAbove = getSplitShapePlaneExtents(shapeId, cx, cy, cz, nx, ny, nz)
        if lengthBelow ~= nil and lengthBelow < minLength then
            return nil
        end
        if lengthAbove ~= nil and lengthAbove < minLength then
            return nil
        end
    end
    local lengthBelow = (minY + maxY) * 0.5
    local lengthAbove = (minZ + maxZ) * 0.5
    local centerX, centerY, centerZ = localToWorld(shapeId, localX - maxRadius * 0.5 + lengthAbove, localY, localZ - maxRadius * 0.5 + lengthBelow)
    return centerX, centerY, centerZ, nx, ny, nz, math.max(maxY - minY, maxZ - minZ) * 0.5
end
function SplitShapeUtil.createTreeBelt(beltData, shapeId, tx, ty, tz, sx, sy, sz, upX, upY, upZ, hookOffset, ignoreYDirection, spacing)
    if beltData ~= nil then
        local dir2X, dir2Y, dir2Z = MathUtil.vector3Normalize(sx - tx, sy - ty, sz - tz)
        spacing = spacing or 0.0025
        local rootNode = createTransformGroup("rootNode")
        link(getRootNode(), rootNode)
        setTranslation(rootNode, tx, ty, tz)
        setDirection(rootNode, dir2X, ignoreYDirection and 0 or dir2Y, dir2Z, upX, upY, upZ)
        local startNode = createTransformGroup("startNode")
        link(rootNode, startNode)
        setTranslation(startNode, -spacing * 0.5, 0, hookOffset)
        setRotation(startNode, -1.5707963267948966, 0, -1.5707963267948966)
        local endNode = createTransformGroup("endNode")
        link(startNode, endNode)
        setTranslation(endNode, 0, 0, spacing)
        setRotation(endNode, 0, 0, 0)
        local linkNode = createTransformGroup("linkNode")
        link(startNode, linkNode)
        setTranslation(linkNode, 0, 0, spacing * 0.5)
        setRotation(linkNode, 0, 0, 0)
        local tensionBelt = TensionBeltGeometryConstructor.new()
        tensionBelt:setWidth(beltData.width)
        tensionBelt:setMaterial(beltData.material.materialId)
        tensionBelt:setUVscale(beltData.material.uvScale)
        tensionBelt:setMaxEdgeLength(0.1)
        tensionBelt:setFixedPoints(startNode, endNode)
        tensionBelt:setGeometryBias(0.005)
        tensionBelt:setLinkNode(linkNode)
        tensionBelt:addShape(shapeId, -100, 100, -100, 100)
        local beltShapeId, _, _ = tensionBelt:finalize()
        local wx, wy, wz = getWorldTranslation(beltShapeId)
        local rx, ry, rz = getWorldRotation(beltShapeId)
        link(getRootNode(), beltShapeId)
        setWorldTranslation(beltShapeId, wx, wy, wz)
        setWorldRotation(beltShapeId, rx, ry, rz)
        delete(rootNode)
        return beltShapeId
    end
    Logging.error("Failed to create tree belt. Missing beltData.")
end
function SplitShapeUtil.getSplitShapeId(node)
    if getHasClassId(node, ClassIds.MESH_SPLIT_SHAPE) then
        return node
    end
    local i = 0
    for i = i, getNumOfChildren(node) - 1 do
        local ret = SplitShapeUtil.getSplitShapeId(getChildAt(node, i))
        if ret ~= nil then
            return ret
        end
    end
    return nil
end