DebugManager = {}
DebugManager.DEFAULT_GROUP = "default"
DebugManager.DEFAULT_GROUP_ELEMENT_LIMIT = 250
local DebugManager_mt = Class(DebugManager, AbstractManager)
function DebugManager.new(customMt)
    -- upvalues: (copy) DebugManager_mt
    return AbstractManager.new(customMt or DebugManager_mt)
end
function DebugManager:initDataStructures()
    self.drawables = {}
    self.frameElements = {}
    self.elementIdToElement = {}
    self.elementToElementId = {}
    self.groupIdToElements = {}
    self.elementsWithLifetime = {}
    self.hiddenGroups = {}
    self.debugMaterial = nil
    if self.debugMaterialNode ~= nil then
        delete(self.debugMaterialNode)
        self.debugMaterialNode = nil
    end
    self.splineDebugEnabled = false
    self.splineDebugElements = {}
    self.occluderDebugEnabled = false
    if not self.initialized then
        addConsoleCommand("gsDebugManagerClearElements", "Removes all permanent elements and functions from DebugManager", "consoleCommandRemoveElements", self)
        addConsoleCommand("gsDebugManagerGroupsList", "List all currently used debug element groups with visibility and number of elements", "consoleCommandGroupsList", self)
        addConsoleCommand("gsDebugManagerGroupVisibilitySet", "Toggle or set visibility of given group name", "consoleCommandGroupVisibilitySet", self, "groupId; [visibility]")
        addConsoleCommand("gsDebugManagerGroupRemove", "Remove group and its debug elements", "consoleCommandGroupRemove", self)
        addConsoleCommand("gsSplineDebug", "Toggles debug visualization for all splines currently in the scene", "consoleCommandSplineToggleDebug", self, "[displayEPs]")
        addConsoleCommand("gsTerrainLayerDebug", "Toggles debug visualization for terrain layers", "consoleCommandLayerDebug", self, "visualizeAttributeName")
        self.initialized = true
    end
end
function DebugManager:getDebugMat()
    if self.debugMaterial == nil then
        local debugMatI3d = loadI3DFile("data/shared/materialHolders/debugMaterialHolder.i3d", false, false, false)
        self.debugMaterialNode = getChildAt(debugMatI3d, 0)
        unlink(self.debugMaterialNode)
        self.debugMaterial = getMaterial(self.debugMaterialNode, 0)
        delete(debugMatI3d)
    end
    return self.debugMaterial
end
function DebugManager:unloadMapData()
    self.loadedMapData = false
    self:initDataStructures()
end
function DebugManager:addElement(debugElement, groupId, lifetime, maxCount)
    if debugElement ~= nil then
        local elementId = groupId or DebugManager.DEFAULT_GROUP
        if self.elementToElementId[debugElement] == nil then
            local elementId = Utils.getUniqueId(debugElement, self.elementIdToElement, "debugElement", 10)
            self.elementIdToElement[elementId] = debugElement
            self.elementToElementId[debugElement] = elementId
            self.groupIdToElements[elementId] = self.groupIdToElements[elementId] or {}
            table.insert(self.groupIdToElements[elementId], debugElement)
            if maxCount == nil then
                if elementId == DebugManager.DEFAULT_GROUP then
                    maxCount = DebugManager.DEFAULT_GROUP_ELEMENT_LIMIT
                else
                    maxCount = math.huge
                end
            end
            if maxCount < #self.groupIdToElements[elementId] then
                self:removeElement(self.groupIdToElements[elementId][1])
            end
            if lifetime ~= nil then
                debugElement.removeTime = g_time + lifetime
                table.insert(self.elementsWithLifetime, debugElement)
                table.sort(self.elementsWithLifetime, function(a, b)
                    return a.removeTime > b.removeTime
                end)
            end
            return elementId
        end
    end
end
function DebugManager:removeElement(debugElement)
    if debugElement ~= nil then
        local elementId = self.elementToElementId[debugElement]
        for groupId, groupElements in pairs(self.groupIdToElements) do
            local index = table.find(groupElements, debugElement)
            if index then
                table.remove(groupElements, index)
                if #groupElements == 0 then
                    self.groupIdToElements[groupId] = nil
                end
                self.elementIdToElement[elementId] = nil
                self.elementToElementId[debugElement] = nil
                table.removeElement(self.elementsWithLifetime, debugElement)
                return
            end
        end
        Logging.warning("Unable to remove debug element \'%s\', not found", elementId)
        printCallstack()
    end
end
function DebugManager:removeElementById(elementId)
    self:removeElement(self.elementIdToElement[elementId])
end
function DebugManager:getElement(elementId)
    return self.elementIdToElement[elementId]
end
function DebugManager:removeGroup(groupId)
    if self.groupIdToElements[groupId] ~= nil then
        local elementIndex = #self.groupIdToElements[groupId]
        for elementIndex = elementIndex, 1, -1 do
            self:removeElement(self.groupIdToElements[groupId][elementIndex])
        end
    end
end
function DebugManager:setGroupVisibility(groupId, isVisible)
    self.hiddenGroups[groupId] = not isVisible or nil
end
function DebugManager:listGroups(_)
    print("Currently available debug groups:")
    if next(self.groupIdToElements) == nil then
        print("no non-empty groups")
    end
    for groupId, elements in pairs(self.groupIdToElements) do
        print(string.format("  %s%s (%d elements)", self.hiddenGroups[groupId] and "[hidden] " or "", groupId, #elements))
    end
end
function DebugManager:getGroupIdFromSubstring(groupIdSubstring)
    if next(self.groupIdToElements) == nil then
        return groupIdSubstring
    end
    if self.groupIdToElements[groupIdSubstring] ~= nil then
        return groupIdSubstring
    end
    local match = nil
    for groupId in pairs(self.groupIdToElements) do
        if string.contains(string.upper(groupId), string.upper(groupIdSubstring)) then
            if match ~= nil then
                return groupIdSubstring
            end
        end
    end
    return match
end
function DebugManager:update(dt)
    local index = #self.elementsWithLifetime
    for index = index, 1, -1 do
        local element = self.elementsWithLifetime[index]
        if element.removeTime == nil then
            local elementId = table.find(self.elementIds, element)
            Logging.error("Element without \'removeTime\' found in \'elementsWithLifetime\' array: %s %s", element, elementId)
        end
        if element.removeTime >= g_time then
            break
        end
        self:removeElement(element)
    end
    for element, elementId in pairs(self.groupIdToElements) do
        if self.hiddenGroups[element] == nil then
            for _, element in ipairs(elementId) do
                if element.update ~= nil and (element.getShouldBeUpdated == nil or element:getShouldBeUpdated()) then
                    element:update(dt)
                end
            end
        end
    end
end
function DebugManager:drawPreUI()
    for groupId, groupElements in pairs(self.groupIdToElements) do
        if self.hiddenGroups[groupId] == nil then
            for _, element in ipairs(groupElements) do
                if element.draw ~= nil and (element.getShouldBeDrawn == nil or element:getShouldBeDrawn()) then
                    element:draw()
                end
            end
        end
    end
    local i = #self.frameElements
    for i = i, 1, -1 do
        self.frameElements[i]:draw()
        table.remove(self.frameElements, i)
    end
end
function DebugManager:drawPostUI()
    for _, drawable in pairs(self.drawables) do
        drawable:drawDebug()
    end
end
function DebugManager:addDrawable(drawable, key)
    if drawable.drawDebug == nil then
        Logging.error("DebugManager:addDrawable(): Provided drawable does not have a \'drawDebug\' function")
        printCallstack()
    else
        if key ~= nil and (self.drawables[key] ~= nil and self.drawables[key] ~= drawable) then
            Logging.warning("DebugManager:addDrawable(): Key \'%s\' already has a different drawable registered", key)
        end
        self.drawables[key or drawable] = drawable
    end
end
function DebugManager:removeDrawable(drawableOrKey)
    self.drawables[drawableOrKey] = nil
end
function DebugManager:hasDrawable(drawableOrKey)
    return self.drawables[drawableOrKey] ~= nil
end
function DebugManager:addPermanentElement(element)
    Logging.error("\'DebugManager:addPermanentElement\' is deprected, use addElement instead")
    printCallstack()
end
function DebugManager:removePermanentElement(element)
    Logging.error("\'DebugManager:removePermanentElement\' is deprected, use removeElement or removeElementById instead")
    printCallstack()
end
function DebugManager:addFrameElement(element)
    table.addElement(self.frameElements, element)
end
function DebugManager:addPermanentFunction(funcAndParams)
    Logging.error("\'DebugManager:addPermanentFunction\' is deprected, use DebugFunction instance and addElement instead")
    printCallstack()
end
function DebugManager:removePermanentFunction(funcAndParams)
    Logging.error("\'DebugManager:removePermanentFunction\' is deprected, use DebugFunction instance and addElement instead")
    printCallstack()
end
function DebugManager:consoleCommandRemoveElements()
    for element in pairs(self.elementToElementId) do
        if element.delete ~= nil then
            element:delete()
        end
    end
    self.elementIdToElement = {}
    self.elementToElementId = {}
    self.groupIdToElements = {}
    self.elementsWithLifetime = {}
    return "Cleared all debug elements"
end
function DebugManager:consoleCommandGroupsList()
    self:listGroups()
end
function DebugManager:consoleCommandGroupVisibilitySet(groupIdInput, visibilityStr)
    if groupIdInput == nil then
        Logging.error("No groupId given")
        print("Usage: gsDebugManagerGroupVisibilitySet groupId <visibility>")
        self:listGroups()
    else
        local groupId = self:getGroupIdFromSubstring(groupIdInput)
        if self.groupIdToElements[groupId] ~= nil then
            local visibility
            if visibilityStr == nil then
                visibility = self.hiddenGroups[groupId] ~= nil
            else
                visibility = Utils.stringToBoolean(visibilityStr)
            end
            self:setGroupVisibility(groupId, visibility)
            return string.format("Debug element group \'%s\' now %s", groupId, visibility and "visible" or "hidden")
        end
        Logging.error("No group \'%s\' with active elements", groupIdInput)
    end
end
function DebugManager:consoleCommandGroupRemove(groupIdInput)
    if groupIdInput == nil then
        Logging.error("No groupId given")
        print("Usage: gsDebugManagerGroupRemove groupId")
        self:listGroups()
    else
        local groupId = self:getGroupIdFromSubstring(groupIdInput)
        if self.groupIdToElements[groupId] ~= nil then
            self:removeGroup(groupId)
            return string.format("Removed debug element group \'%s", groupId)
        end
        Logging.error("No group \'%s\' with active elements", groupIdInput)
    end
end
function DebugManager:consoleCommandSplineToggleDebug(displayEPsStr)
    self.splineDebugEnabled = not self.splineDebugEnabled
    if not self.splineDebugEnabled then
        g_debugManager:removeGroup("splineDebug")
        return string.format("Removed spline debug elements")
    end
    local displayEPs = Utils.stringToBoolean(displayEPsStr)
    local debugMat = self:getDebugMat()
    local numAffectedNodes = 0
    I3DUtil.iterateRecursively(getRootNode(), function(node)
        -- upvalues: (copy) debugMat, (copy) displayEPs, (ref) numAffectedNodes
        if I3DUtil.getIsSpline(node) then
            DebugUtil.setNodeEffectivelyVisible(node)
            local r, g, b = DebugUtil.getDebugColor(node):unpack()
            setMaterial(node, debugMat, 0)
            setShaderParameter(node, "color", r, g, b, 0, false)
            setShaderParameter(node, "alpha", 1, 0, 0, 0, false)
            local debugSpline = DebugSpline.new()
            debugSpline:createWithNode(node, nil, nil, displayEPs):setColorRGBA(r, g, b):setClipDistance(500)
            g_debugManager:addElement(debugSpline, "splineDebug")
        end
    end)
    return string.format("Added debug visualization to %d splines", numAffectedNodes)
end
function DebugManager:consoleCommandLayerDebug(visualizeAttributeName)
    self.layerDebug = not self.layerDebug
    if not self.layerDebug then
        g_debugManager:removeElement(self.layerDebugBitVectorMap)
        self.layerDebugBitVectorMap = nil
        return "Disabled terrain layer debug"
    end
    self.layerDebugBitVectorMap = DebugBitVectorMap.newSimple(6, 1, false, 0.1, nil, nil, nil, false)
    local cellColor = Color.new(0, 0, 0, 1)
    function self.layerDebugBitVectorMap.getColorForValue(_, value)
        -- upvalues: (copy) cellColor
        cellColor.r, cellColor.g, cellColor.b = Utils.getGreenRedBlendedColor(value)
        return cellColor
    end
    local layerIndexToAttributes = {}
    local numLayers = getTerrainNumOfLayers(g_terrainNode)
    local layerIndex = 0
    local textColor = 1
    for layerIndex = layerIndex, numLayers, textColor do
        local layerAttributes = {}
        layerIndexToAttributes[layerIndex] = layerAttributes
        for _, layerAttributeName in ipairs({
            "viscosity",
            "firmness",
            "firmnessWet",
            "porosityAtZeroRoughness",
            "porosityAtFullRoughness"
        }) do
            layerAttributes[layerAttributeName] = getTerrainLayerXmlAttribute(g_terrainNode, layerIndex, layerAttributeName)
        end
    end
    local text = ""
    local textColor = nil
    local layerIndex = nil
    self.layerDebugBitVectorMap:createWithCustomFunc(function(_, startWorldX, startWorldZ, widthWorldX, _, _, heightWorldZ)
        -- upvalues: (ref) text, (copy) numLayers, (ref) textColor, (copy) layerIndexToAttributes, (copy) visualizeAttributeName, (ref) layerIndex
        text = ""
        local centerX = (startWorldX + widthWorldX) * 0.5
        local centerZ = (startWorldZ + heightWorldZ) * 0.5
        local layerIndex = 0
        for layerIndex = layerIndex, numLayers do
            if getTerrainLayerAtWorldPos(g_terrainNode, layerIndex, centerX, 0, centerZ) > 0 then
                text = getTerrainLayerName(g_terrainNode, layerIndex)
                textColor = DebugUtil.getDebugColor(layerIndex)
                for attributeName, attributeValue in pairs(layerIndexToAttributes[layerIndex]) do
                    text = text .. string.format("\n %s %.3f", attributeName, attributeValue)
                    if attributeName == visualizeAttributeName then
                        layerIndex = attributeValue
                    end
                end
                local r, g, b, attributeName, attributeValue = getTerrainAttributesAtWorldPos(g_terrainNode, centerX, 0, centerZ, true, true, true, true, true)
                text = text .. string.format("\n rgb %.2f %.2f %.2f", r, g, b)
                text = text .. string.format("\n softness %.3f", attributeName)
                if visualizeAttributeName == "softness" then
                    layerIndex = attributeName
                end
                text = text .. string.format("\n materialId %d", attributeValue)
                break
            end
        end
        local cx, layerIndex, layerWeight = getWorldTranslation(g_cameraManager:getActiveCamera())
        local b = 0.03 / MathUtil.vector3Length(cx - centerX, layerIndex - getTerrainHeightAtWorldPos(g_terrainNode, centerX, 0, centerZ), layerWeight - centerZ)
        local g = math.clamp(b, 0.001, 0.02)
        Utils.renderTextAtWorldPosition(centerX, y, centerZ, text, g, 0, textColor:unpack())
        return layerIndex
    end)
    g_debugManager:addElement(self.layerDebugBitVectorMap)
    return "Enabled terrain layer debug, " .. (visualizeAttributeName ~= nil and string.format("visualizing layer %q as color gradient in F5 debug", visualizeAttributeName) or "no layer attribute name given to visualize")
end
g_debugManager = DebugManager.new()