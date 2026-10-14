source("dataS/scripts/animals/husbandry/placeables/events/HusbandryFenceUpdateEvent.lua")
source("dataS/scripts/animals/husbandry/placeables/events/HusbandryFenceCustomizeStartEvent.lua")
source("dataS/scripts/animals/husbandry/placeables/events/HusbandryFenceCustomizeFinishEvent.lua")
source("dataS/scripts/animals/husbandry/placeables/events/HusbandryFenceValidateEvent.lua")
PlaceableHusbandryFence = {}
function PlaceableHusbandryFence.prerequisitesPresent(specializations)
    return true
end
function PlaceableHusbandryFence.registerEvents(placeableType)
    SpecializationUtil.registerEvent(placeableType, "onHusbandryFenceCustomizingUserLeft")
end
function PlaceableHusbandryFence.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "getHasCustomizableFence", PlaceableHusbandryFence.getHasCustomizableFence)
    SpecializationUtil.registerFunction(placeableType, "getFence", PlaceableHusbandryFence.getFence)
    SpecializationUtil.registerFunction(placeableType, "getCustomizeableSectionStartAndEndPositions", PlaceableHusbandryFence.getCustomizeableSectionStartAndEndPositions)
    SpecializationUtil.registerFunction(placeableType, "getDefaultFenceOrientation", PlaceableHusbandryFence.getDefaultFenceOrientation)
    SpecializationUtil.registerFunction(placeableType, "getFenceContourPositions", PlaceableHusbandryFence.getFenceContourPositions)
    SpecializationUtil.registerFunction(placeableType, "updateHusbandryFence", PlaceableHusbandryFence.updateHusbandryFence)
    SpecializationUtil.registerFunction(placeableType, "finalizeHusbandryFence", PlaceableHusbandryFence.finalizeHusbandryFence)
    SpecializationUtil.registerFunction(placeableType, "createDefaultFence", PlaceableHusbandryFence.createDefaultFence)
    SpecializationUtil.registerFunction(placeableType, "deleteCustomizableSegments", PlaceableHusbandryFence.deleteCustomizableSegments)
    SpecializationUtil.registerFunction(placeableType, "onFenceI3DLoaded", PlaceableHusbandryFence.onFenceI3DLoaded)
    SpecializationUtil.registerFunction(placeableType, "startFenceCustomization", PlaceableHusbandryFence.startFenceCustomization)
    SpecializationUtil.registerFunction(placeableType, "finishFenceCustomization", PlaceableHusbandryFence.finishFenceCustomization)
    SpecializationUtil.registerFunction(placeableType, "onHusbandryFenceUserRemoved", PlaceableHusbandryFence.onHusbandryFenceUserRemoved)
    SpecializationUtil.registerFunction(placeableType, "hideDefaultFence", PlaceableHusbandryFence.hideDefaultFence)
    SpecializationUtil.registerFunction(placeableType, "restoreDefaultFence", PlaceableHusbandryFence.restoreDefaultFence)
    SpecializationUtil.registerFunction(placeableType, "tryFinalizeFence", PlaceableHusbandryFence.tryFinalizeFence)
    SpecializationUtil.registerFunction(placeableType, "getAllowFenceSegmentDeletion", PlaceableHusbandryFence.getAllowFenceSegmentDeletion)
end
function PlaceableHusbandryFence.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setPreviewPosition", PlaceableHusbandryFence.setPreviewPosition)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getCanBePlacedAt", PlaceableHusbandryFence.getCanBePlacedAt)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "createNavigationMesh", PlaceableHusbandryFence.createNavigationMesh)
end
function PlaceableHusbandryFence.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryFence)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryFence)
    SpecializationUtil.registerEventListener(placeableType, "onPreFinalizePlacement", PlaceableHusbandryFence)
    SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableHusbandryFence)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryFence)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHusbandryFence)
end
function PlaceableHusbandryFence.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Husbandry")
    basePath = basePath .. ".husbandry.fence"
    schema:register(XMLValueType.STRING, basePath .. "#xmlFilename", "Fence xml filename")
    schema:register(XMLValueType.STRING, basePath .. ".sections.section(?)#segmentId", "segment id from fence xml to use for this section", nil, true)
    schema:register(XMLValueType.BOOL, basePath .. ".sections.section(?)#isReversed", "Reverse segment (gate)")
    schema:register(XMLValueType.BOOL, basePath .. ".sections.section(?)#customizable", "User has the option to place this section manually")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".sections.section(?).node(?)#node", "Fence node")
    schema:setXMLSpecializationType()
end
function PlaceableHusbandryFence.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Husbandry")
    Fence.registerSavegameXMLPaths(schema, basePath .. ".fence")
    schema:setXMLSpecializationType()
end
function PlaceableHusbandryFence:onLoad(_)
    local spec = self.spec_husbandryFence
    spec.userIsCustomizing = false
    spec.hasCustomizableFence = nil
    spec.canBePlaced = true
    if _G.g_iconGenerator == nil then
        local fenceXmlFilename = self.xmlFile:getValue("placeable.husbandry.fence#xmlFilename")
        if fenceXmlFilename == nil then
            return
        else
            local fenceI3dFilename = Utils.getFilename(fenceXmlFilename, self.baseDirectory)
            if fenceI3dFilename == nil then
                Logging.xmlWarning(self.xmlFile, "No fence xml filename defined at %q", "placeable.husbandry.fence.xmlFilename")
                return
            else
                self.fenceXmlFile = XMLFile.load("placeableHusbandryfence", fenceI3dFilename, Fence.xmlSchema)
                if self.fenceXmlFile == nil then
                    Logging.xmlWarning(self.xmlFile, "Could not load fence xml file")
                    return
                else
                    local fenceI3dFilename = self.fenceXmlFile:getString("placeable.base.filename")
                    if string.isNilOrWhitespace(fenceI3dFilename) then
                        Logging.xmlWarning(self.fenceXmlFile, "No fence i3d file defined at %q", "placeable.base.filename")
                        self.fenceXmlFile:delete()
                        self.fenceXmlFile = nil
                    else
                        local loadingTask = Utils.getFilename(fenceI3dFilename, self.baseDirectory)
                        local arguments = {
                            ["fenceI3dFilename"] = loadingTask,
                            ["loadingTask"] = self:createLoadingTask()
                        }
                        spec.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(loadingTask, false, false, self.onFenceI3DLoaded, self, arguments)
                    end
                end
            end
        end
    else
        return
    end
end
function PlaceableHusbandryFence:onFenceI3DLoaded(i3dNode, _, args)
    if i3dNode ~= 0 then
        local components = I3DUtil.loadI3DComponents(i3dNode)
        local i3dMappings = I3DUtil.loadI3DMapping(self.fenceXmlFile, "placeable", components)
        self.spec_husbandryFence.fence = Fence.new(self.fenceXmlFile, "placeable.fence", args.fenceI3dFilename, components, i3dMappings, self)
        if spec.fence:load(self.fenceXmlFile, "placeable.fence") then
            spec.fenceSegmentsData = {}
            for _, sectionKey in self.xmlFile:iterator("placeable.husbandry.fence.sections.section") do
                if spec.hasCustomizableFence then
                    Logging.xmlError(self.xmlFile, "Customizable section needs to be the last section. No more section definitions allowed: %q", sectionKey)
                    break
                end
                local sectionSegmentId = self.xmlFile:getValue(sectionKey .. "#segmentId")
                if sectionSegmentId == nil then
                    Logging.xmlError(self.xmlFile, "Missing segment id for %q", sectionKey)
                elseif spec.fence:getSegmentTemplateById(sectionSegmentId) == nil then
                    Logging.xmlError(self.xmlFile, "Segment id %q does not exist in %q", sectionSegmentId, self.fenceXmlFile:getFilename())
                else
                    local isReversed = self.xmlFile:getValue(sectionKey .. "#isReversed")
                    local customizable = self.xmlFile:getValue(sectionKey .. "#customizable")
                    local sectionNodes = {}
                    for _, sectionNodeKey in self.xmlFile:iterator(sectionKey .. ".node") do
                        local node = self.xmlFile:getValue(sectionNodeKey .. "#node", nil, self.components, self.i3dMappings)
                        table.insert(sectionNodes, node)
                    end
                    table.insert(spec.fenceSegmentsData, {
                        ["segmentId"] = sectionSegmentId,
                        ["nodes"] = sectionNodes,
                        ["isReversed"] = isReversed,
                        ["isCustomizable"] = customizable
                    })
                    if customizable then
                        spec.hasCustomizableFence = true
                    end
                end
            end
            spec.hasFence = #spec.fenceSegmentsData > 0
            if self.propertyState == PlaceablePropertyState.CONSTRUCTION_PREVIEW then
                self:createDefaultFence()
            end
        end
        delete(i3dNode)
    end
    if self.fenceXmlFile ~= nil then
        self.fenceXmlFile:delete()
        self.fenceXmlFile = nil
    end
    self:finishLoadingTask(args.loadingTask)
end
function PlaceableHusbandryFence:onDelete()
    local spec = self.spec_husbandryFence
    if self.fenceXmlFile ~= nil then
        self.fenceXmlFile:delete()
        self.fenceXmlFile = nil
    end
    if spec.previewSegments ~= nil then
        for _, segment in ipairs(spec.previewSegments) do
            segment:delete()
        end
        spec.previewSegments = nil
    end
    if spec.fence ~= nil then
        spec.fence:delete()
        spec.fence = nil
    end
    if spec.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(spec.sharedLoadRequestId)
        spec.sharedLoadRequestId = nil
    end
end
function PlaceableHusbandryFence:onReadStream(streamId, connection)
    local spec = self.spec_husbandryFence
    if spec.fence ~= nil then
        for _, segment in ipairs_reverse(spec.fence:getSegments()) do
            segment:delete()
        end
        spec.fence:readStream(streamId, connection)
        for _, segment in ipairs(spec.fence:getSegments()) do
            segment.husbandryFenceIsCustomizable = streamReadBool(streamId)
            segment.husbandryFenceIsDefaultSegment = streamReadBool(streamId)
        end
        self:finalizeHusbandryFence()
        spec.userIsCustomizing = streamReadBool(streamId)
        if spec.userIsCustomizing then
            self:hideDefaultFence()
        end
    end
end
function PlaceableHusbandryFence:onWriteStream(streamId, connection)
    local spec = self.spec_husbandryFence
    if spec.fence ~= nil then
        spec.fence:writeStream(streamId, connection)
        for _, segment in ipairs(spec.fence:getSegments()) do
            streamWriteBool(streamId, Utils.getNoNil(segment.husbandryFenceIsCustomizable, false))
            streamWriteBool(streamId, Utils.getNoNil(segment.husbandryFenceIsDefaultSegment, false))
        end
        streamWriteBool(streamId, spec.userIsCustomizing)
    end
end
function PlaceableHusbandryFence:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_husbandryFence
    if spec.fence ~= nil then
        if spec.customizingUser ~= nil then
            local adjustNeedsSaving = false
            for _, segment in ipairs(spec.fence:getSegments()) do
                if segment.husbandryFenceIsCustomizable then
                    adjustNeedsSaving = true
                elseif adjustNeedsSaving then
                    segment.needsSaving = false
                end
            end
        end
        spec.fence:saveToXMLFile(xmlFile, key .. ".fence", usedModNames)
    end
end
function PlaceableHusbandryFence:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_husbandryFence
    if spec.fence ~= nil and xmlFile:hasProperty(key .. ".fence") then
        spec.fence:loadFromXMLFile(xmlFile, key .. ".fence")
    end
end
function PlaceableHusbandryFence:onPreFinalizePlacement()
    local spec = self.spec_husbandryFence
    if spec.fence == nil then
        Logging.devInfo("PlaceableHusbandryFence:onPreFinalizePlacement() fence nil, return")
    elseif self.isServer and not self.isLoadedFromSavegame then
        self:createDefaultFence()
        for _, segment in ipairs(spec.previewSegments) do
            Logging.devInfo("PlaceableHusbandryFence.finalizeHusbandryFence: Finalize segments")
            segment:finalize()
        end
        Logging.devInfo("PlaceableHusbandryFence.finalizeHusbandryFence: Finalize fence")
        spec.fence:finalize()
    end
end
function PlaceableHusbandryFence:onPostFinalizePlacement()
    if self.isServer then
        self:finalizeHusbandryFence()
    end
end
function PlaceableHusbandryFence:finalizeHusbandryFence()
    if self.spec_husbandryFence.fence == nil then
        return true
    end
    local contourPositions3D = self:getFenceContourPositions()
    local success = false
    if #contourPositions3D >= 9 then
        success = self:createNavigationMeshFromContour(contourPositions3D)
    end
    return success
end
function PlaceableHusbandryFence:getFenceContourPositions(ignoreCustomizableSegments)
    local contourPositions3D = {}
    local segments = self.spec_husbandryFence.fence:getSegments()
    for segmentIndex, segment in ipairs(segments) do
        if not (ignoreCustomizableSegments and segment.husbandryFenceIsCustomizable) then
            local x, y, z = segment:getStartPos()
            local x2, y2, z2 = segment:getEndPos();
            (function(x, y, z)
                -- upvalues: (copy) contourPositions3D
                if MathUtil.equalEpsilon(contourPositions3D[#contourPositions3D - 2], x, 0.1) and MathUtil.equalEpsilon(contourPositions3D[#contourPositions3D], z, 0.1) then
                    return
                elseif not (MathUtil.equalEpsilon(contourPositions3D[1], x, 0.1) and MathUtil.equalEpsilon(contourPositions3D[3], z, 0.1)) then
                    contourPositions3D[#contourPositions3D + 1] = x
                    contourPositions3D[#contourPositions3D + 1] = y
                    contourPositions3D[#contourPositions3D + 1] = z
                end
            end)(x, y, z)
            addPosition(x2, y2, z2)
        end
    end
    return contourPositions3D
end
function PlaceableHusbandryFence:createNavigationMesh(superFunc)
    local spec = self.spec_husbandryFence
    if spec.fence == nil or #spec.fence:getSegments() == 0 then
        superFunc(self)
    end
end
function PlaceableHusbandryFence:startFenceCustomization(user, noEventSend)
    local spec = self.spec_husbandryFence
    if spec.fence ~= nil then
        g_debugManager:removeGroup("NM-Contour")
        HusbandryFenceCustomizeStartEvent.sendEvent(self, noEventSend)
        if self.isServer then
            spec.customizingUser = user
            g_messageCenter:subscribe(MessageType.USER_REMOVED, self.onHusbandryFenceUserRemoved, self)
        end
        spec.userIsCustomizing = true
        self:deleteNavigationMeshPlacementCollision()
        self:hideDefaultFence()
    end
end
function PlaceableHusbandryFence:finishFenceCustomization(_, success, noEventSend)
    local spec = self.spec_husbandryFence
    if spec.fence ~= nil then
        HusbandryFenceCustomizeFinishEvent.sendEvent(self, success, noEventSend)
        spec.userIsCustomizing = false
        if success then
            spec.previewSegments = {}
        else
            self:restoreDefaultFence()
            Logging.devWarning("PlaceableHusbandryFence:finishFenceCustomization: fence customization failed or cancelled")
        end
        if self.isServer then
            g_messageCenter:unsubscribe(MessageType.USER_REMOVED, self)
            spec.customizingUser = nil
            for _, segment in ipairs(spec.fence:getSegments()) do
                segment.needsSaving = nil
            end
            g_server:broadcastEvent(HusbandryFenceUpdateEvent.new(self, success), true)
        end
        self:createNavigationMeshPlacementCollision((self:getFenceContourPositions()))
    end
end
function PlaceableHusbandryFence:tryFinalizeFence()
    if self.spec_husbandryFence.fence == nil then
        return true
    end
    local contourPositions3D = self:getFenceContourPositions(true)
    local success = false
    if #contourPositions3D >= 9 then
        success = self:createNavigationMeshFromContour(contourPositions3D)
    end
    return success
end
function PlaceableHusbandryFence:hideDefaultFence()
    for _, segment in ipairs(self.spec_husbandryFence.fence:getSegments()) do
        if segment.husbandryFenceIsCustomizable then
            segment.parentBackup = getParent(segment.root)
            unlink(segment.root)
            removeFromPhysics(segment.root)
        end
    end
end
function PlaceableHusbandryFence:restoreDefaultFence()
    local spec = self.spec_husbandryFence
    for _, segment in ipairs_reverse(spec.fence:getSegments()) do
        if segment.husbandryFenceIsDefaultSegment or segment.husbandryFenceIsCustomizable then
            if segment.parentBackup ~= nil then
                link(segment.parentBackup, segment.root)
                addToPhysics(segment.root)
                segment.parentBackup = nil
            end
        else
            spec.fence:removeSegment(segment)
            segment:delete()
        end
    end
end
function PlaceableHusbandryFence:onHusbandryFenceUserRemoved(user)
    local spec = self.spec_husbandryFence
    if spec.customizingUser ~= nil and user == spec.customizingUser then
        spec.customizingUser = nil
        self:finishFenceCustomization(user, false)
        SpecializationUtil.raiseEvent(self, "onHusbandryFenceCustomizingUserLeft", user)
        Logging.devInfo("Modifying user left the game")
    end
end
function PlaceableHusbandryFence:createDefaultFence()
    local spec = self.spec_husbandryFence
    local polygon = Polygon2D.new()
    spec.previewSegments = {}
    for _, section in ipairs(spec.fenceSegmentsData) do
        for nodeIndex, node in ipairs(section.nodes) do
            if nodeIndex == #section.nodes then
                break
            end
            local segment = spec.fence:createNewSegment(section.segmentId)
            segment:setStartPos(getWorldTranslation(node))
            segment:setEndPos(getWorldTranslation(section.nodes[nodeIndex + 1]))
            if section.isReversed ~= nil and segment.setIsReversed ~= nil then
                segment:setIsReversed(section.isReversed)
            end
            segment.husbandryFenceIsDefaultSegment = true
            polygon:addNode(node)
            table.insert(spec.previewSegments, segment)
            if section.isCustomizable then
                segment.husbandryFenceIsCustomizable = true
            end
        end
    end
    spec.fenceOrientation = polygon:getCurveOrientation()
    self:updateHusbandryFence()
end
function PlaceableHusbandryFence:deleteCustomizableSegments()
    local spec = self.spec_husbandryFence
    for _, segment in ipairs_reverse(spec.fence:getSegments()) do
        if segment.husbandryFenceIsCustomizable then
            if g_server ~= nil then
                g_server:broadcastEvent(FenceDeleteSegmentEvent.new(self, segment.id), false)
            end
            spec.fence:removeSegment(segment)
            segment:delete()
        end
    end
end
function PlaceableHusbandryFence:getAllowFenceSegmentDeletion()
    return false
end
function PlaceableHusbandryFence:updateHusbandryFence()
    local spec = self.spec_husbandryFence
    if spec.fenceSegmentsData == nil then
        return true
    end
    spec.lastFenceError = nil
    local hitNodes = {}
    local isBlocked = false
    local segmentIndex = 1
    for _, section in ipairs(spec.fenceSegmentsData) do
        for nodeIndex, node in ipairs(section.nodes) do
            if nodeIndex == #section.nodes then
                break
            end
            local segment = spec.previewSegments[segmentIndex]
            segment:setStartPos(getWorldTranslation(node))
            segment:setEndPos(getWorldTranslation(section.nodes[nodeIndex + 1]))
            if not segment:updateMeshes() then
                spec.lastFenceError = segment.lastError
                return false
            end
            segment:checkOverlap(hitNodes)
            isBlocked = segment:getHasBlockingOverlap(self.ownerFarmId) and true or isBlocked
            segmentIndex = segmentIndex + 1
        end
    end
    for _ in pairs(hitNodes) do
        DebugShapeOutline.render(_)
    end
    local hasOverlap = next(hitNodes) ~= nil
    return not hasOverlap and not isBlocked
end
function PlaceableHusbandryFence:setPreviewPosition(superFunc, x, y, z, rotX, rotY, rotZ)
    superFunc(self, x, y, z, rotX, rotY, rotZ)
    local spec = self.spec_husbandryFence
    spec.canBePlaced = true
    local canBePlaced = self:updateHusbandryFence()
    spec.canBePlaced = spec.canBePlaced and canBePlaced
end
function PlaceableHusbandryFence:getHasCustomizableFence()
    return self.spec_husbandryFence.hasCustomizableFence
end
function PlaceableHusbandryFence:getFence()
    return self.spec_husbandryFence.fence
end
function PlaceableHusbandryFence:getCustomizeableSectionStartAndEndPositions()
    local startX = nil
    local startY = nil
    local startZ = nil
    local endX = nil
    local endY = nil
    local endZ = nil
    for _, segment in ipairs(self.spec_husbandryFence.fence:getSegments()) do
        if segment.husbandryFenceIsCustomizable then
            if startX == nil then
                startX, startY, startZ = segment:getStartPos()
            end
            endX, endY, endZ = segment:getEndPos()
        end
    end
    return startX, startY, startZ, endX, endY, endZ
end
function PlaceableHusbandryFence:getDefaultFenceOrientation()
    return self.spec_husbandryFence.fenceOrientation
end
function PlaceableHusbandryFence:getCanBePlacedAt(superFunc, x, y, z, farmId)
    if self.spec_husbandryFence.canBePlaced then
        return superFunc(self, x, y, z, farmId)
    end
    return false, g_i18n:getText(ConstructionBrushNewFence.SEGMENT_ERROR_TO_MESSAGE[self.spec_husbandryFence.lastFenceError] or "warning_canNotPlaceFence")
end