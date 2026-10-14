I3DUtil = {}
function I3DUtil.checkChildIndex(node, index)
    if getNumOfChildren(node) > index then
        return true
    end
    Logging.error("Failed to find child %d from node %q, only %s children given", tostring(index), I3DUtil.getNodePath(node), (tostring(getNumOfChildren(node))))
    printCallstack()
    return false
end
function I3DUtil.indexToObject(components, index, mappings, realNumComponents)
    if index == nil or components == nil then
        return nil
    end
    local mapping
    if mappings == nil then
        mapping = index
    else
        mapping = mappings[index]
        if mapping == nil then
            mapping = index
        elseif type(mapping) == "table" then
            return mapping.nodeId, mapping.rootNode
        end
    end
    local mapping = 1
    local iStart, iEnd = string.find(mapping, ">", 1, true)
    if iStart ~= nil then
        mapping = iEnd + 1
    end
    local rootNode
    if type(components) == "table" then
        local componentIndex = 1
        if iStart ~= nil then
            local curCompIndex = tonumber((string.sub(mapping, 1, iStart - 1)))
            if curCompIndex == nil then
                Logging.error("Invalid index format: %s", mapping)
            end
            componentIndex = curCompIndex + 1
        end
        if components[componentIndex] == nil then
            if (realNumComponents or #components) < componentIndex then
                Logging.error("Invalid compound index: %s", mapping)
            end
            return nil
        end
        rootNode = components[componentIndex].node
    else
        rootNode = components
    end
    if iStart ~= nil and iEnd == string.len(mapping) then
        return rootNode, rootNode
    end
    if type(components) ~= "table" and iStart ~= nil then
        Logging.error("Invalid usage of \'>\'! Works with vehicle & placeable components table only. Please replace \'>\' with \'|\' in the xml config. Referenced node: \'%s\'", mapping)
        printCallstack()
        return nil
    end
    local curCompIndex, iEnd = string.find(mapping, "|", mapping, true)
    while curCompIndex ~= nil do
        local curCompIndex = tonumber((string.sub(mapping, mapping, curCompIndex - 1)))
        if curCompIndex == nil or not I3DUtil.checkChildIndex(rootNode, curCompIndex) then
            Logging.error("Index not found: %s", mapping)
            return nil
        end
        rootNode = getChildAt(rootNode, curCompIndex)
        mapping = iEnd + 1
        curCompIndex, iEnd = string.find(mapping, "|", mapping, true)
    end
    local curCompIndex = tonumber((string.sub(mapping, mapping)))
    if curCompIndex ~= nil and I3DUtil.checkChildIndex(rootNode, curCompIndex) then
        return getChildAt(rootNode, curCompIndex), rootNode
    end
    Logging.error("Index not found: %s", mapping)
    return nil
end
function I3DUtil.setNumberShaderByValue(numbers, value, precision, showZero)
    if numbers ~= nil then
        value = math.floor(value * 10 ^ precision)
        local i = 0
        for i = i, getNumOfChildren(numbers) - 1 do
            local elem = getChildAt(numbers, i)
            if value > 0 then
                local curNumber = value - math.floor(value / 10) * 10
                value = (value - curNumber) / 10
                setShaderParameter(elem, "number", curNumber, 0, 0, 0, false)
            elseif showZero and i <= precision then
                setShaderParameter(elem, "number", 0, 0, 0, 0, false)
            else
                setShaderParameter(elem, "number", -1, 0, 0, 0, false)
            end
        end
    end
end
function I3DUtil.wakeUpObject(node)
    addImpulse(node, 0, 0.001, 0, 0, 0, 0, true)
end
function I3DUtil.setWorldDirection(node, dirX, dirY, dirZ, upX, upY, upZ, limitedAxis, minRot, maxRot)
    local parent = getParent(node)
    if dirX == dirX and (dirY == dirY and dirZ == dirZ) then
        if parent ~= 0 then
            dirX, dirY, dirZ = worldDirectionToLocal(parent, dirX, dirY, dirZ)
            upX, upY, upZ = worldDirectionToLocal(parent, upX, upY, upZ)
        end
        if limitedAxis ~= nil then
            if limitedAxis == 1 then
                dirX = 0
                if minRot ~= nil then
                    dirZ, dirY = MathUtil.getRotationLimitedVector2(dirZ, dirY, minRot, maxRot)
                end
            elseif limitedAxis == 2 then
                dirY = 0
                if minRot ~= nil then
                    dirZ, dirX = MathUtil.getRotationLimitedVector2(dirZ, dirX, minRot, maxRot)
                end
            else
                dirZ = 0
                if minRot ~= nil then
                    dirX, dirY = MathUtil.getRotationLimitedVector2(dirX, dirY, minRot, maxRot)
                end
            end
        end
        if dirX * dirX + dirY * dirY + dirZ * dirZ > 0.0001 then
            setDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
        end
    else
        Logging.error("Failed to set world direction: Object \'%s\' dir %.2f %.2f %.2f up %.2f %.2f %.2f", getName(node), dirX, dirY, dirZ, upX, upY, upZ)
    end
end
function I3DUtil.setDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
    if MathUtil.vector3LengthSq(dirX, dirY, dirZ) > 0.0001 then
        setDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
    end
end
function I3DUtil.setShaderParameterRec(node, shaderParam, x, y, z, w)
    if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParam) then
        setShaderParameter(node, shaderParam, x, y, z, w, false)
    end
    local i = 0
    for i = i, getNumOfChildren(node) - 1 do
        I3DUtil.setShaderParameterRec(getChildAt(node, i), shaderParam, x, y, z, w)
    end
end
function I3DUtil.setMaterialSlotShaderParameterRec(node, materialSlotName, shaderParam, x, y, z, w)
    if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParam) then
        local i = 1
        local i = getNumOfMaterials(node)
        for i = i, i do
            if getMaterialSlotName(node, i - 1) == materialSlotName then
                setShaderParameter(node, shaderParam, x, y, z, w, false, i - 1)
            end
        end
    end
    local numChildren = getNumOfChildren(node)
    local i = 1
    local i = 1
    for i = i, numChildren, i do
        I3DUtil.setMaterialSlotShaderParameterRec(getChildAt(node, i - 1), materialSlotName, shaderParam, x, y, z, w)
    end
end
function I3DUtil.setShaderParameter(node, shaderParameter, x, y, z, w, shared)
    if getHasClassId(node, ClassIds.SHAPE) then
        setShaderParameter(node, shaderParameter, x, y, z, w, shared, -1)
    end
end
function I3DUtil.setHideByIndexRec(node, fillLevelPercentage)
    if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, "hideByIndex") then
        local hideByIndexMaxIndex = getUserAttribute(node, "hideByIndexMaxIndex")
        if hideByIndexMaxIndex == nil then
            Logging.warning("Try to set hideByIndex on node \'%s\', but \'hideByIndexMaxIndex\' user attribute is missing!", getName(node))
            printCallstack()
        else
            local offset = getUserAttribute(node, "hideByIndexOffset") or 0
            setShaderParameter(node, "hideByIndex", (1 - fillLevelPercentage) * hideByIndexMaxIndex - offset, 0, 0, 0, false)
        end
    end
    local i = 0
    local offset = getNumOfChildren(node) - 1
    for i = i, offset do
        I3DUtil.setHideByIndexRec(getChildAt(node, i), fillLevelPercentage)
    end
end
function I3DUtil.setShapeBonesRec(node, skeleton, oldSkeleton, keepBindPoses)
    if getHasClassId(node, ClassIds.SHAPE) then
        setShapeBones(node, skeleton, oldSkeleton, keepBindPoses)
    end
    local numChildren = getNumOfChildren(node)
    if numChildren > 0 then
        local i = 0
        for i = i, numChildren - 1 do
            I3DUtil.setShapeBonesRec(getChildAt(node, i), skeleton, oldSkeleton, keepBindPoses)
        end
    end
end
function I3DUtil.setShapeCastShadowmapRec(node, castShadowmap)
    if getHasClassId(node, ClassIds.SHAPE) then
        setShapeCastShadowmap(node, castShadowmap)
    end
    local numChildren = getNumOfChildren(node)
    if numChildren > 0 then
        local i = 0
        for i = i, numChildren - 1 do
            I3DUtil.setShapeCastShadowmapRec(getChildAt(node, i), castShadowmap)
        end
    end
end
function I3DUtil.getHasShaderParameterRec(node, shaderParam)
    if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParam) then
        return true
    end
    local numChildren = getNumOfChildren(node)
    if numChildren > 0 then
        local i = 0
        for i = i, numChildren - 1 do
            if I3DUtil.getHasShaderParameterRec(getChildAt(node, i), shaderParam) then
                return true
            end
        end
    end
    return false
end
function I3DUtil.getShaderParameterRec(node, shaderParam)
    if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParam) then
        return getShaderParameter(node, shaderParam)
    end
    local numChildren = getNumOfChildren(node)
    if numChildren > 0 then
        local i = 0
        for i = i, numChildren - 1 do
            local x, y, z, w = I3DUtil.getShaderParameterRec(getChildAt(node, i), shaderParam)
            if x ~= nil then
                return x, y, z, w
            end
        end
    end
    return nil, nil, nil, nil
end
function I3DUtil.getNodesByShaderParam(node, shaderParam, nodes, asList)
    nodes = nodes == nil and {} or nodes
    if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParam) then
        if asList == nil or not asList then
            nodes[node] = node
        else
            table.insert(nodes, node)
        end
    end
    local numChildren = getNumOfChildren(node)
    if numChildren > 0 then
        local i = 0
        for i = i, numChildren - 1 do
            I3DUtil.getNodesByShaderParam(getChildAt(node, i), shaderParam, nodes, asList)
        end
    end
    return nodes
end
function I3DUtil.getNodesByShaderParameters(node, shaderParameters, nodes, asList)
    nodes = nodes == nil and {} or nodes
    if getHasClassId(node, ClassIds.SHAPE) then
        for _, shaderParam in ipairs(shaderParameters) do
            if getHasShaderParameter(node, shaderParam) then
                if asList == nil or not asList then
                    nodes[node] = node
                else
                    table.insert(nodes, node)
                end
                break
            end
        end
    end
    local numChildren = getNumOfChildren(node)
    if numChildren > 0 then
        for _ = 0, numChildren - 1 do
            I3DUtil.getNodesByShaderParameters(getChildAt(node, _), shaderParameters, nodes, asList)
        end
    end
    return nodes
end
function I3DUtil.printChildren(node, indentation, depth)
    indentation = indentation or "    "
    depth = depth or 0
    local i = 0
    for i = i, getNumOfChildren(node) - 1 do
        local child = getChildAt(node, i)
        log(string.rep(indentation, depth), child, getName(child))
        I3DUtil.printChildren(child, indentation, depth + 1)
    end
end
function I3DUtil.hasNamedChildren(node, name)
    local i = 0
    for i = i, getNumOfChildren(node) - 1 do
        local child = getChildAt(node, i)
        if getName(child) == name or I3DUtil.hasNamedChildren(child, name) then
            return true
        end
    end
    return false
end
function I3DUtil.getChildByName(node, name)
    local i = 0
    for i = i, getNumOfChildren(node) - 1 do
        local child = getChildAt(node, i)
        if getName(child) == name then
            return child
        end
        local foundChild = I3DUtil.getChildByName(child, name)
        if foundChild ~= nil then
            return foundChild
        end
    end
    return nil
end
function I3DUtil.iterateRecursively(node, func, includeStartNode)
    if includeStartNode and func(node, 0) == false then
        return false
    end
    local function iterateRecursivelyRec(node, func, depth)
        -- upvalues: (copy) iterateRecursivelyRec
        local i = 0
        for i = i, getNumOfChildren(node) - 1 do
            local child = getChildAt(node, i)
            if func(child, depth) == false then
                return false
            end
            if iterateRecursivelyRec(child, func, depth + 1) == false then
                return false
            end
        end
        return true
    end
    return iterateRecursivelyRec(node, func, 0)
end
function I3DUtil.iteratorChildren(node)
    if node == nil or not entityExists(node) then
        return function() end
    elseif getHasClassId(node, ClassIds.TRANSFORM_GROUP) then
        local currentIndex = 0
        local numChildren = getNumOfChildren(node)
        return function()
            -- upvalues: (ref) currentIndex, (copy) numChildren, (copy) node
            if numChildren <= currentIndex then
                return nil
            end
            currentIndex = currentIndex + 1
            return currentIndex, getChildAt(node, currentIndex - 1)
        end
    else
        Logging.error("I3DUtil.iteratorChildren() called with non-transform entity %q (%d)", getName(node), node)
        printCallstack()
        return function() end
    end
end
function I3DUtil.iteratorChildrenReverse(node)
    if node == nil or not entityExists(node) then
        return function() end
    end
    if getHasClassId(node, ClassIds.TRANSFORM_GROUP) then
        local currentIndex = getNumOfChildren(node)
        return function()
            -- upvalues: (ref) currentIndex, (copy) node
            if currentIndex <= 0 then
                return nil
            end
            currentIndex = currentIndex - 1
            return currentIndex + 1, getChildAt(node, currentIndex)
        end
    end
    Logging.error("I3DUtil.iteratorChildren() called with non-transform entity %q (%d)", getName(node), node)
    printCallstack()
    return function() end
end
function I3DUtil.traverseToRoot(node, callback, stopNode)
    if callback(node) then
        local parent = getParent(node)
        if parent ~= 0 then
            if stopNode ~= nil and parent == stopNode then
                return
            end
            I3DUtil.traverseToRoot(parent, callback, stopNode)
        end
    end
end
function I3DUtil.iterateShaderParameterNodesRecursively(node, shaderParameter, func, funcTarget)
    if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParameter) then
        if funcTarget == nil then
            func(node)
        else
            func(funcTarget, node)
        end
    end
    local i = 0
    for i = i, getNumOfChildren(node) - 1 do
        I3DUtil.iterateShaderParameterNodesRecursively(getChildAt(node, i), shaderParameter, func, funcTarget)
    end
end
function I3DUtil.iterateShaderParametersNodesRecursively(node, shaderParameters, func, funcTarget)
    if getHasClassId(node, ClassIds.SHAPE) then
        for _, shaderParameter in ipairs(shaderParameters) do
            if getHasShaderParameter(node, shaderParameter) then
                if funcTarget == nil then
                    func(node)
                else
                    func(funcTarget, node)
                end
                break
            end
        end
    end
    local i = 0
    for i = i, getNumOfChildren(node) - 1 do
        I3DUtil.iterateShaderParametersNodesRecursively(getChildAt(node, i), shaderParameters, func, funcTarget)
    end
end
function I3DUtil.getIsLinkedToNode(parent, node)
    while node ~= 0 do
        if parent == node then
            return true
        end
        node = getParent(node)
    end
    return false
end
function I3DUtil.getIsSpline(node)
    return node ~= 0 and getHasClassId(node, ClassIds.SHAPE) and getGeometry(node) ~= 0 and getHasClassId(getGeometry(node), ClassIds.SPLINE)
end
function I3DUtil.getIsTransformGroup(node)
    if node == nil or not entityExists(node) then
        return false
    end
    for _, id in pairs(ClassIds) do
        if id ~= ClassIds.TRANSFORM_GROUP and getHasClassId(node, id) then
            return false
        end
    end
    return true
end
function I3DUtil.getSupportsLOD(node)
    return getHasClassId(node, ClassIds.SHAPE) and not getIsNonRenderable(node) and not I3DUtil.getIsSpline(node) or (getHasClassId(node, ClassIds.LIGHT_SOURCE) or getHasClassId(node, ClassIds.AUDIO_SOURCE))
end
function I3DUtil.getNodePath(node, stopAtNode, stopAtReference)
    local parent = getParent(node)
    if parent == 0 or node == stopAtNode then
        return getName(node)
    else
        local isRef, filePath = getReferenceInfo(parent)
        if isRef then
            if stopAtReference then
                return "(Ref:" .. Utils.getFilenameFromPath(filePath) .. ")|" .. getName(node)
            else
                return I3DUtil.getNodePath(parent, stopAtNode, stopAtReference) .. "(Ref:" .. filePath .. ")|" .. getName(node)
            end
        else
            return I3DUtil.getNodePath(parent, stopAtNode, stopAtReference) .. "|" .. getName(node)
        end
    end
end
function I3DUtil.getNodePathIndices(node, stopAtNode, includeStopNode)
    local parent = getParent(node)
    if parent == 0 or (getChildIndex(parent) == -1 or (node == stopAtNode or parent == stopAtNode and includeStopNode == false)) then
        return string.format("%d", getChildIndex(node))
    end
    local spacer = getParent(parent) == getRootNode() and ">" or "|"
    local path = I3DUtil.getNodePathIndices(parent, stopAtNode, includeStopNode)
    return string.format("%s%s%d", path, spacer, getChildIndex(node))
end
function I3DUtil.getRelativeNodePathIndices(node, parentNode)
    local parent = getParent(node)
    if parent == 0 or parent == parentNode then
        return getChildIndex(node)
    else
        return I3DUtil.getRelativeNodePathIndices(parent, parentNode) .. "|" .. getChildIndex(node)
    end
end
function I3DUtil.getNodeNameAndIndexPath(node)
    return string.format("%s (%s)", I3DUtil.getNodePath(node), I3DUtil.getNodePathIndices(node))
end
function I3DUtil.checkForChildCollisions(node, errorFunc, ...)
    local rigidBodyType = getRigidBodyType(node)
    if rigidBodyType == RigidBodyType.STATIC or (rigidBodyType == RigidBodyType.DYNAMIC or getIsCompoundChild(node)) then
        errorFunc(node, ...)
    end
    local i = 0
    for i = i, getNumOfChildren(node) - 1 do
        I3DUtil.checkForChildCollisions(getChildAt(node, i), errorFunc, ...)
    end
end
function I3DUtil.registerI3dMappingXMLPaths(schema, path)
    schema:register(XMLValueType.STRING, path .. ".i3dMappings.i3dMapping(?)#id", "Identifier to be used in xml")
    schema:register(XMLValueType.STRING, path .. ".i3dMappings.i3dMapping(?)#node", "Index path to node in i3d file")
end
function I3DUtil.loadI3DMapping(xmlFile, path, components, mappings, realNumComponents)
    mappings = mappings or {}
    if xmlFile == nil then
        Logging.warning("Cannot load i3d mapping because xml file is missing")
        return mappings
    else
        xmlFile:iterate((path or xmlFile:getRootName()) .. ".i3dMappings.i3dMapping", function(_, key)
            -- upvalues: (copy) xmlFile, (copy) components, (copy) realNumComponents, (ref) mappings
            local id = xmlFile:getString(key .. "#id")
            local node = xmlFile:getString(key .. "#node")
            if id ~= nil and node ~= nil then
                local nodeId, rootNode = I3DUtil.indexToObject(components, node, nil, realNumComponents)
                if nodeId ~= nil then
                    mappings[id] = {
                        ["nodeId"] = nodeId,
                        ["rootNode"] = rootNode
                    }
                    return
                end
                mappings[id] = node
            end
        end)
        return mappings
    end
end
function I3DUtil.loadI3DComponents(rootNode, components)
    local numChildren = components or {}
    local i = 0
    for i = i, getNumOfChildren(rootNode) - 1 do
        table.insert(numChildren, {
            ["node"] = getChildAt(rootNode, i)
        })
    end
    return numChildren
end