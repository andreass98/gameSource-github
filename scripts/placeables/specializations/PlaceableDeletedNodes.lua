PlaceableDeletedNodes = {}
function PlaceableDeletedNodes.prerequisitesPresent(specializations)
    return true
end
function PlaceableDeletedNodes.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoadFinished", PlaceableDeletedNodes)
end
function PlaceableDeletedNodes.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("DeletedNodes")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".deletedNodes.deletedNode(?)#node", "The node that should be deleted")
    schema:setXMLSpecializationType()
end
function PlaceableDeletedNodes:onLoadFinished(_)
    if self.xmlFile == nil then
        return
    elseif self.xmlFile:getNumOfElements("placeable.deletedNodes.deletedNode") ~= 0 then
        local nodes = {}
        local bones = {}
        I3DUtil.iterateRecursively(self.rootNode, function(node)
            -- upvalues: (copy) bones
            if getHasClassId(node, ClassIds.SHAPE) and getShapeIsSkinned(node) then
                local boneIndex = 0
                for boneIndex = boneIndex, getNumOfShapeBones(node) - 1 do
                    bones[getShapeBone(node, boneIndex)] = node
                end
            end
        end)
        for _, deletedNodeKey in self.xmlFile:iterator("placeable.deletedNodes.deletedNode") do
            local node = self.xmlFile:getValue(deletedNodeKey .. "#node", nil, self.components, self.i3dMappings)
            if node ~= nil then
                if bones[node] == nil or bones[node] == node then
                    table.insert(nodes, node)
                else
                    Logging.xmlWarning(self.xmlFile, "DeleteNode %q at %q is a bone of the skinned mesh %q and cannot be deleted on its own, ignoring", getName(node), deletedNodeKey, getName(bones[node]))
                end
            end
        end
        for _, deletedNodeKey in ipairs(nodes) do
            delete(deletedNodeKey)
        end
    end
end