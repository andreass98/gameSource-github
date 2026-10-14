PlaceableNewFence = {}
function PlaceableNewFence.prerequisitesPresent(specializations)
    return true
end
function PlaceableNewFence.registerEvents(placeableType)
    SpecializationUtil.registerEvent(placeableType, "onCreateSegment")
end
function PlaceableNewFence.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "getFence", PlaceableNewFence.getFence)
    SpecializationUtil.registerFunction(placeableType, "onSegmentCreated", PlaceableNewFence.onSegmentCreated)
    SpecializationUtil.registerFunction(placeableType, "getNumSequments", PlaceableNewFence.getNumSequments)
    SpecializationUtil.registerFunction(placeableType, "getPanelLength", PlaceableNewFence.getPanelLength)
    SpecializationUtil.registerFunction(placeableType, "getIsPanelLengthFixed", PlaceableNewFence.getIsPanelLengthFixed)
    SpecializationUtil.registerFunction(placeableType, "updateDirtyAreas", PlaceableNewFence.updateDirtyAreas)
    SpecializationUtil.registerFunction(placeableType, "getSupportsParallelSnapping", PlaceableNewFence.getSupportsParallelSnapping)
    SpecializationUtil.registerFunction(placeableType, "getSnapDistance", PlaceableNewFence.getSnapDistance)
    SpecializationUtil.registerFunction(placeableType, "getSnapAngle", PlaceableNewFence.getSnapAngle)
    SpecializationUtil.registerFunction(placeableType, "getSnapCheckDistance", PlaceableNewFence.getSnapCheckDistance)
    SpecializationUtil.registerFunction(placeableType, "getAllowExtendingOnly", PlaceableNewFence.getAllowExtendingOnly)
    SpecializationUtil.registerFunction(placeableType, "getMaxCornerAngle", PlaceableNewFence.getMaxCornerAngle)
    SpecializationUtil.registerFunction(placeableType, "getHasParallelSnapping", PlaceableNewFence.getHasParallelSnapping)
end
function PlaceableNewFence.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getIsOnFarmland", PlaceableNewFence.getIsOnFarmland)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableNewFence.collectPickObjects)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getDestructionMethod", PlaceableNewFence.getDestructionMethod)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "performNodeDestruction", PlaceableNewFence.performNodeDestruction)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "previewNodeDestructionNodes", PlaceableNewFence.previewNodeDestructionNodes)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableNewFence.setOwnerFarmId)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getOwnerFarmId", PlaceableNewFence.getOwnerFarmId)
end
function PlaceableNewFence.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableNewFence)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableNewFence)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableNewFence)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableNewFence)
    SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableNewFence)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableNewFence)
end
function PlaceableNewFence.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Fence")
    Fence.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType()
end
function PlaceableNewFence.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Fence")
    Fence.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType()
end
function PlaceableNewFence:onLoad(_)
    local xmlFile = self.xmlFile
    local i3dFilename = xmlFile:getValue("placeable.base.filename")
    if string.isNilOrWhitespace(i3dFilename) then
        Logging.xmlError(xmlFile, "Unable to load fence, no i3d filename given at \'placeable.base.filename\'!")
        self:setLoadingState(PlaceableLoadingState.ERROR)
        return
    else
        self.spec_newFence.existingPlaceableInstance = g_currentMission.placeableSystem:getExistingPlaceableByXMLFilename(self.configFileName)
        if spec.existingPlaceableInstance == nil then
            local preplacedParent = Utils.getFilename(i3dFilename, self.baseDirectory)
            spec.segmentsNode = createTransformGroup("segments")
            link(self.rootNode, spec.segmentsNode)
            spec.fence = Fence.new(xmlFile, "placeable.fence", preplacedParent, self.components, self.i3dMappings, self, spec.segmentsNode)
            if spec.fence:load(xmlFile, "placeable.fence") then
                if self:getIsPreplaced() then
                    local preplacedParent = getParent(self.rootNode)
                    if preplacedParent ~= 0 then
                        local fenceSegmentIndex = getUserAttribute(preplacedParent, "fenceSegments")
                        local fenceSegmentsNode = I3DUtil.indexToObject(preplacedParent, fenceSegmentIndex)
                        if fenceSegmentsNode ~= nil then
                            local i = getNumOfChildren(fenceSegmentsNode) - 1
                            for i = i, 0, -1 do
                                delete(getChildAt(fenceSegmentsNode, i))
                            end
                        end
                        local staticFenceIndex = getUserAttribute(preplacedParent, "staticFence")
                        local staticFenceNode = I3DUtil.indexToObject(preplacedParent, staticFenceIndex)
                        if staticFenceNode ~= nil then
                            local i = getNumOfChildren(staticFenceNode) - 1
                            local i = 0
                            for i = i, i, -1 do
                                delete(getChildAt(staticFenceNode, i))
                            end
                        end
                    end
                end
            else
                Logging.xmlError(xmlFile, "Unable to load fence!")
                self:setLoadingState(PlaceableLoadingState.ERROR)
            end
        else
            Logging.info("Instance of fence \'%s\' found. Starting merge process...", self.configFileName)
            return
        end
    end
end
function PlaceableNewFence:onDelete()
    local spec = self.spec_newFence
    if spec.fence ~= nil then
        spec.fence:delete()
        spec.fence = nil
    end
end
function PlaceableNewFence:onFinalizePlacement()
    if self.spec_newFence.existingPlaceableInstance ~= nil then
        Logging.info("Finished merge process for fence \'%s\'.", self.configFileName)
        self:delete()
    end
end
function PlaceableNewFence:onReadStream(streamId, connection)
    self.spec_newFence.fence:readStream(streamId, connection)
end
function PlaceableNewFence:onWriteStream(streamId, connection)
    self.spec_newFence.fence:writeStream(streamId, connection)
end
function PlaceableNewFence:onUpdate(dt)
    local spec = self.spec_newFence
    if spec.fence ~= nil then
        spec.fence:update(dt)
    end
end
function PlaceableNewFence:onSegmentCreated(segment)
    SpecializationUtil.raiseEvent(self, "onCreateSegment", false, segment)
end
function PlaceableNewFence:setOwnerFarmId(superFunc, ownerFarmId, noEventSend) end
function PlaceableNewFence:getOwnerFarmId()
    return AccessHandler.EVERYONE
end
function PlaceableNewFence:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_newFence
    local fence = spec.fence
    if spec.existingPlaceableInstance ~= nil then
        fence = spec.existingPlaceableInstance:getFence()
        Logging.info("Merging savegame data into existing fence instance")
    end
    fence:loadFromXMLFile(xmlFile, key)
end
function PlaceableNewFence:saveToXMLFile(xmlFile, key, usedModNames)
    self.spec_newFence.fence:saveToXMLFile(xmlFile, key, usedModNames)
end
function PlaceableNewFence:getIsOnFarmland(superFunc, farmlandId)
    return false
end
function PlaceableNewFence:getFence()
    return self.spec_newFence.fence
end
function PlaceableNewFence.getSegmentLength(_, segment)
    return MathUtil.getPointPointDistance(segment.x1, segment.z1, segment.x2, segment.z2)
end
function PlaceableNewFence:getPanelLength()
    return self.spec_newFence.panelLength
end
function PlaceableNewFence:getIsPanelLengthFixed()
    return self.spec_newFence.panelLengthFixed
end
function PlaceableNewFence.updateDirtyAreas(_, x1, z1, x2, z2)
    local minX = math.min(x1, x2)
    local maxX = math.max(x1, x2)
    local minZ = math.min(z1, z2)
    local maxZ = math.max(z1, z2)
    g_densityMapHeightManager:setCollisionMapAreaDirty(minX, minZ, maxX, maxZ, true)
    g_currentMission.aiSystem:setAreaDirty(minX, maxX, minZ, maxZ)
end
function PlaceableNewFence:getNumSequments()
    return self.spec_newFence.fence:getNumSegments()
end
function PlaceableNewFence:getMaxVerticalAngle()
    return self.spec_newFence.maxVerticalAngle
end
function PlaceableNewFence:getMaxVerticalGateAngle()
    return self.spec_newFence.maxVerticalGateAngle
end
function PlaceableNewFence:getSnapDistance()
    return nil
end
function PlaceableNewFence:getSnapAngle()
    return nil
end
function PlaceableNewFence:getSnapCheckDistance()
    return nil
end
function PlaceableNewFence:getAllowExtendingOnly()
    return nil
end
function PlaceableNewFence:getMaxCornerAngle()
    return nil
end
function PlaceableNewFence:getHasParallelSnapping()
    return false
end
function PlaceableNewFence:getSupportsParallelSnapping()
    return false
end
function PlaceableNewFence:addPickingNodesForSegment(segment)
    if segment ~= self.spec_newFence.previewSegment then
        if segment.group ~= nil then
            local objects = {}
            self:recursivelyAddPickingNodes(objects, segment.group)
            local i = 1
            for i = i, #objects do
                g_currentMission:addNodeObject(objects[i], self)
            end
        end
        self.overlayColorNodes = nil
    end
end
function PlaceableNewFence:removePickingNodesForSegment(segment)
    if segment ~= self.spec_newFence.previewSegment then
        if segment.group ~= nil then
            local objects = {}
            self:recursivelyAddPickingNodes(objects, segment.group)
            local i = 1
            for i = i, #objects do
                g_currentMission:removeNodeObject(objects[i])
            end
        end
    end
end
function PlaceableNewFence:recursivelyAddPickingNodes(objects, node)
    if getRigidBodyType(node) ~= RigidBodyType.NONE then
        table.insert(objects, node)
    end
    local numChildren = getNumOfChildren(node)
    local i = 1
    for i = i, numChildren do
        self:recursivelyAddPickingNodes(objects, getChildAt(node, i - 1))
    end
end
function PlaceableNewFence:getDestructionMethod(superFunc)
    return Placeable.DESTRUCTION.PER_NODE
end
function PlaceableNewFence:previewNodeDestructionNodes(_, node)
    return self:getNodesToDeleteForPanel(node)
end
function PlaceableNewFence:performNodeDestruction(_, node)
    local destroyedNode = self:deletePanel(node)
    local destroyPlaceable = self:getNumSequments() == 0
    return destroyedNode, destroyPlaceable
end
function PlaceableNewFence:collectPickObjects(superFunc, node) end