PlaceableDynamicallyLoadedParts = {}
function PlaceableDynamicallyLoadedParts.prerequisitesPresent(specializations)
    return true
end
function PlaceableDynamicallyLoadedParts.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onDynamicallyPartI3DLoaded", PlaceableDynamicallyLoadedParts.onDynamicallyPartI3DLoaded)
end
function PlaceableDynamicallyLoadedParts.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableDynamicallyLoadedParts)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableDynamicallyLoadedParts)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableDynamicallyLoadedParts)
end
function PlaceableDynamicallyLoadedParts.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("DynamicallyLoadedParts")
    basePath = basePath .. ".dynamicallyLoadedParts.dynamicallyLoadedPart(?)"
    schema:register(XMLValueType.STRING, basePath .. "#filename", "Filename to i3d file")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Node in external i3d file", "0")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#linkNode", "Link node", "0>")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#position", "Position")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#rotationNode", "Rotation node", "node")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotation", "Rotation node rotation")
    schema:register(XMLValueType.STRING, basePath .. "#shaderParameterName", "Shader parameter name")
    schema:register(XMLValueType.VECTOR_4, basePath .. "#shaderParameter", "Shader parameter to apply")
    ObjectChangeUtil.registerObjectChangeSingleXMLPaths(schema, basePath)
    schema:setXMLSpecializationType()
end
function PlaceableDynamicallyLoadedParts:onLoad(_)
    local spec = self.spec_dynamicallyLoadedParts
    spec.sharedLoadRequestIds = {}
    spec.parts = {}
    self.xmlFile:iterate("placeable.dynamicallyLoadedParts.dynamicallyLoadedPart", function(_, partKey)
        -- upvalues: (copy) self, (copy) spec
        local filename = self.xmlFile:getValue(partKey .. "#filename")
        if filename == nil then
            Logging.xmlWarning(self.xmlFile, "Missing filename for dynamically loaded part \'%s\'", partKey)
        else
            local args = Utils.getFilename(filename, self.baseDirectory)
            local args = {
                ["xmlFile"] = self.xmlFile,
                ["key"] = partKey,
                ["loadingTask"] = self:createLoadingTask(spec),
                ["filename"] = args
            }
            local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(args, true, true, self.onDynamicallyPartI3DLoaded, self, args)
            table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)
        end
    end)
end
function PlaceableDynamicallyLoadedParts:onDynamicallyPartI3DLoaded(i3dNode, _, args)
    local loadingTask = args.loadingTask
    local filename = args.filename
    local xmlFile = args.xmlFile
    local partKey = args.key
    if i3dNode == 0 then
        Logging.xmlError(xmlFile, "Could not load load part %q at %q!", filename, partKey)
        self:finishLoadingTask(loadingTask)
        return false
    end
    local node = xmlFile:getValue(partKey .. "#node", "0", i3dNode)
    if node == nil then
        Logging.xmlWarning(xmlFile, "Failed to load dynamicallyLoadedPart \'%s\'. Unable to find node in loaded i3d", partKey)
        self:finishLoadingTask(loadingTask)
        delete(i3dNode)
        return false
    end
    local linkedSkinnedShapes = nil
    I3DUtil.iterateRecursively(node, function(toBeLinkedNode)
        -- upvalues: (ref) linkedSkinnedShapes
        if getHasClassId(toBeLinkedNode, ClassIds.SHAPE) and getShapeIsSkinned(toBeLinkedNode) then
            linkedSkinnedShapes = linkedSkinnedShapes or {}
            linkedSkinnedShapes[toBeLinkedNode] = true
        end
    end)
    local linkedBones = nil
    I3DUtil.iterateRecursively(i3dNode, function(loadedNode)
        -- upvalues: (ref) linkedBones
        if getHasClassId(loadedNode, ClassIds.SHAPE) and getShapeIsSkinned(loadedNode) then
            local boneIndex = 0
            for boneIndex = boneIndex, getNumOfShapeBones(loadedNode) - 1 do
                local bone = getShapeBone(loadedNode, boneIndex)
                linkedBones = linkedBones or {}
                linkedBones[bone] = loadedNode
            end
        end
    end)
    if linkedSkinnedShapes ~= nil or linkedBones ~= nil then
        local missingShapesForBones = nil
        I3DUtil.iterateRecursively(node, function(toBeLinkedNode)
            -- upvalues: (ref) linkedBones, (ref) linkedSkinnedShapes, (ref) missingShapesForBones
            local shape = linkedBones[toBeLinkedNode]
            if shape ~= nil then
                linkedBones[toBeLinkedNode] = nil
                if linkedSkinnedShapes == nil or linkedSkinnedShapes[shape] == nil then
                    missingShapesForBones = missingShapesForBones or {}
                    missingShapesForBones[shape] = toBeLinkedNode
                end
            end
        end)
        if missingShapesForBones ~= nil then
            for shape, bone in pairs(missingShapesForBones) do
                Logging.xmlWarning(self.xmlFile, "Node %q at %q do not contain the skinned shape %q for bone %q, ignoring", getName(node), partKey .. "#node", getName(shape), getName(bone))
            end
            self:finishLoadingTask(loadingTask)
            delete(i3dNode)
            return false
        end
        if next(linkedBones) ~= nil then
            for shape, bone in pairs(linkedBones) do
                if linkedSkinnedShapes == nil or linkedSkinnedShapes[bone] ~= nil then
                    Logging.xmlWarning(self.xmlFile, "Node %q at %q does not contain all bones of the skinned shape %q and cannot be linked on their own, ignoring", getName(node), partKey .. "#node", getName(bone))
                    for bone2, shape2 in pairs(linkedBones) do
                        if bone == shape2 then
                            linkedBones[bone2] = nil
                        end
                    end
                    if linkedSkinnedShapes ~= nil then
                        linkedSkinnedShapes[bone] = nil
                    end
                end
            end
            self:finishLoadingTask(loadingTask)
            delete(i3dNode)
            return false
        end
    end
    local missingShapesForBones = xmlFile:getValue(partKey .. "#linkNode", "0>", self.components, self.i3dMappings)
    if missingShapesForBones == nil then
        Logging.xmlWarning(xmlFile, "Failed to load dynamicallyLoadedPart \'%s\'. Unable to find linkNode", partKey)
        self:finishLoadingTask(loadingTask)
        delete(i3dNode)
        return false
    end
    removeFromPhysics(node)
    local x, y, z = xmlFile:getValue(partKey .. "#position")
    if x ~= nil and (y ~= nil and z ~= nil) then
        setTranslation(node, x, y, z)
    end
    local shape = xmlFile:getValue(partKey .. "#rotationNode", node, i3dNode)
    local bone, rotY, rotZ = xmlFile:getValue(partKey .. "#rotation")
    if bone ~= nil and (rotY ~= nil and rotZ ~= nil) then
        setRotation(shape, bone, rotY, rotZ)
    end
    local shaderParameterName = xmlFile:getValue(partKey .. "#shaderParameterName")
    local bone2, shape2, sz, sw = xmlFile:getValue(partKey .. "#shaderParameter")
    if shaderParameterName ~= nil and (bone2 ~= nil and (shape2 ~= nil and (sz ~= nil and sw ~= nil))) then
        setShaderParameter(node, shaderParameterName, bone2, shape2, sz, sw, false)
    end
    local objectChanges = ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, partKey, nil, i3dNode, nil)
    ObjectChangeUtil.setObjectChanges(objectChanges, true, nil)
    link(missingShapesForBones, node)
    delete(i3dNode)
    table.insert(self.spec_dynamicallyLoadedParts.parts, {
        ["filename"] = filename,
        ["node"] = node
    })
    self:finishLoadingTask(loadingTask)
    return true
end
function PlaceableDynamicallyLoadedParts:onDelete()
    local spec = self.spec_dynamicallyLoadedParts
    if spec.sharedLoadRequestIds ~= nil then
        for _, sharedLoadRequestId in ipairs(spec.sharedLoadRequestIds) do
            g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
        end
        spec.sharedLoadRequestIds = nil
    end
    if spec.parts ~= nil then
        for _, sharedLoadRequestId in pairs(spec.parts) do
            delete(sharedLoadRequestId.node)
        end
    end
end
function PlaceableDynamicallyLoadedParts:onFinalizePlacement()
    local spec = self.spec_dynamicallyLoadedParts
    if spec.parts ~= nil then
        for _, part in pairs(spec.parts) do
            addToPhysics(part.node)
        end
    end
end