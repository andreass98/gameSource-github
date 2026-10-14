ChainRollers = {}
function ChainRollers.prerequisitesPresent(specializations)
    return true
end
function ChainRollers.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("ChainRollers")
    schema:register(XMLValueType.FLOAT, "vehicle.chainRollers#maxUpdateDistance", "If the player is more than this distance away the nodes will no longer be updated", 100)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.chainRollers.chainRoller(?)#elementsNode", "Root node that contains every chain link")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.chainRollers.chainRoller(?)#endReferenceNode", "Reference node for the alignment of the last chain link")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.chainRollers.chainRoller(?).splineNode(?)#node", "Regular transform group(s) that define the spline (at least two have to be defined)")
    schema:addDelayedRegistrationFunc("Cylindered:movingTool", function(cSchema, cKey)
        cSchema:register(XMLValueType.NODE_INDICES, cKey .. ".chainRollers#splineNodes", "Spline nodes to update")
    end)
    schema:addDelayedRegistrationFunc("Cylindered:movingPart", function(cSchema, cKey)
        cSchema:register(XMLValueType.NODE_INDICES, cKey .. ".chainRollers#splineNodes", "Spline nodes to update")
    end)
    schema:setXMLSpecializationType()
end
function ChainRollers.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadChainRollerFromXML", ChainRollers.loadChainRollerFromXML)
    SpecializationUtil.registerFunction(vehicleType, "updateChainRoller", ChainRollers.updateChainRoller)
end
function ChainRollers.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", ChainRollers.loadExtraDependentParts)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", ChainRollers.updateExtraDependentParts)
end
function ChainRollers.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", ChainRollers)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", ChainRollers)
    SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", ChainRollers)
end
function ChainRollers:onLoad(_)
    local spec = self.spec_chainRollers
    if self.xmlFile:hasProperty("vehicle.chainRollers") then
        spec.maxUpdateDistance = self.xmlFile:getValue("vehicle.chainRollers#maxUpdateDistance", 100)
        spec.chainRollers = {}
        spec.chainRollerSplineNodeToSpline = {}
        self.xmlFile:iterate("vehicle.chainRollers.chainRoller", function(_, key)
            -- upvalues: (copy) self, (copy) spec
            local chainRoller = {}
            if self:loadChainRollerFromXML(self.xmlFile, key, chainRoller) then
                table.insert(spec.chainRollers, chainRoller)
            end
        end)
        if #spec.chainRollers == 0 then
            SpecializationUtil.removeEventListener(self, "onLoadFinished", ChainRollers)
            SpecializationUtil.removeEventListener(self, "onPostUpdate", ChainRollers)
        end
    else
        SpecializationUtil.removeEventListener(self, "onLoadFinished", ChainRollers)
        SpecializationUtil.removeEventListener(self, "onPostUpdate", ChainRollers)
    end
end
function ChainRollers:onLoadFinished(_)
    ChainRollers.onPostUpdate(self, 99999, false, false, false)
end
function ChainRollers:onPostUpdate(dt, _, _, _)
    local spec = self.spec_chainRollers
    if self.currentUpdateDistance < spec.maxUpdateDistance then
        for splineNode, splineData in pairs(spec.chainRollerSplineNodeToSpline) do
            if splineData.isDirty then
                setSplineCV(splineData.spline, splineData.index, localToLocal(splineNode, splineData.spline, 0, 0, 0))
                splineData.isDirty = false
                splineData.chainRoller.isDirty = true
            end
        end
        for splineNode, splineData in pairs(spec.chainRollers) do
            if splineData.isDirty then
                self:updateChainRoller(splineData, dt)
                splineData.isDirty = false
            end
        end
        if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
            for splineNode, splineData in pairs(spec.chainRollers) do
                local i = 1
                for i = i, #splineData.splineNodes - 1 do
                    local x1, y1, z1 = getWorldTranslation(splineData.splineNodes[i])
                    local x2, y2, z2 = getWorldTranslation(splineData.splineNodes[i + 1])
                    drawDebugLine(x1, y1, z1, 1, 0, 0, x2, y2, z2, 1, 0, 0, false)
                    drawDebugPoint(x1, y1, z1, 1, 0, 0, 1, false)
                    drawDebugPoint(x2, y2, z2, 1, 0, 0, 1, false)
                end
                local i = 0
                for i = i, 99 do
                    local x1 = i / 100
                    local y1, z1, x2 = getSplinePosition(splineData.spline, x1)
                    local y2, z2, z2 = getSplinePosition(splineData.spline, x1 + 0.01)
                    drawDebugLine(y1, z1, x2, 0, 1, 0, y2, z2, z2, 0, 1, 0, false)
                end
            end
        end
    end
end
function ChainRollers:loadChainRollerFromXML(xmlFile, key, chainRoller)
    chainRoller.elementsNode = xmlFile:getValue(key .. "#elementsNode", nil, self.components, self.i3dMappings)
    if chainRoller.elementsNode == nil then
        Logging.xmlWarning(xmlFile, "Missing \'elementsNode\' for chainRoller \'%s\'!", key)
        return false
    end
    chainRoller.elements = {}
    local i = 1
    local node = getNumOfChildren(chainRoller.elementsNode)
    for i = i, node do
        local node = getChildAt(chainRoller.elementsNode, i - 1)
        table.insert(chainRoller.elements, node)
    end
    chainRoller.numElements = #chainRoller.elements
    if chainRoller.numElements == 0 then
        Logging.xmlWarning(xmlFile, "Missing elements inside \'elementsNode\' for chainRoller \'%s\'!", key)
        return false
    end
    chainRoller.endReferenceNode = xmlFile:getValue(key .. "#endReferenceNode", nil, self.components, self.i3dMappings)
    chainRoller.splineNodes = {}
    xmlFile:iterate(key .. ".splineNode", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) self, (copy) chainRoller
        local splineNode = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        if splineNode == nil then
            Logging.xmlWarning(xmlFile, "Missing \'node\' for chainRoller spline \'%s\'!", key)
            return false
        end
        table.insert(chainRoller.splineNodes, splineNode)
    end)
    if #chainRoller.splineNodes < 2 then
        Logging.xmlWarning(xmlFile, "Missing spline nodes for chainRoller \'%s\', at least two are required!", key)
        return false
    end
    local editPoints = {}
    for _, splineNode in pairs(chainRoller.splineNodes) do
        local x, y, z = getTranslation(splineNode)
        table.insert(editPoints, x)
        table.insert(editPoints, y)
        table.insert(editPoints, z)
    end
    chainRoller.spline = createSplineFromEditPoints(getParent(chainRoller.splineNodes[1]), editPoints, false, false)
    setVisibility(chainRoller.spline, false)
    for _, splineNode in pairs(chainRoller.splineNodes) do
        self.spec_chainRollers.chainRollerSplineNodeToSpline[splineNode] = {
            ["chainRoller"] = chainRoller,
            ["spline"] = chainRoller.spline,
            ["index"] = _ - 1,
            ["isDirty"] = false
        }
    end
    chainRoller.isDirty = true
    return true
end
function ChainRollers.updateChainRoller(_, chainRoller, _)
    local lastX = nil
    local lastY = nil
    local lastZ = nil
    local lastElementNode = nil
    local i = 1
    local lastElement = chainRoller.numElements
    local x = 1
    for i = i, lastElement, x do
        local elementNode = chainRoller.elements[i]
        local x, y, z = getSplinePosition(chainRoller.spline, (i - 1) / (chainRoller.numElements - 1))
        setWorldTranslation(elementNode, x, y, z)
        if lastX ~= nil then
            local dx, dy, dz = MathUtil.vector3Normalize(x - lastX, y - lastY, z - lastZ)
            local dx, dy, dz = worldDirectionToLocal(chainRoller.elementsNode, dx, dy, dz)
            setDirection(lastElementNode, dx, dy, dz, 0, 1, 0)
        end
        lastX = x
    end
    if chainRoller.endReferenceNode ~= nil then
        local x, i, elementNode = getWorldTranslation(chainRoller.endReferenceNode)
        local t, x, y = MathUtil.vector3Normalize(x - lastX, i - lastY, elementNode - lastZ)
        local z, dx, dy = worldDirectionToLocal(chainRoller.elementsNode, t, x, y)
        setDirection(chainRoller.elements[chainRoller.numElements], z, dx, dy, 0, 1, 0)
    end
end
function ChainRollers:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
    if not superFunc(self, xmlFile, baseName, entry) then
        return false
    end
    local splineNodes = xmlFile:getValue(baseName .. ".chainRollers#splineNodes", nil, self.components, self.i3dMappings, true)
    if splineNodes ~= nil and #splineNodes > 0 then
        entry.chainRollerSplineNodes = splineNodes
    end
    return true
end
function ChainRollers:updateExtraDependentParts(superFunc, part, dt)
    superFunc(self, part, dt)
    if part.chainRollerSplineNodes ~= nil then
        local i = 1
        for i = i, #part.chainRollerSplineNodes do
            local splineData = self.spec_chainRollers.chainRollerSplineNodeToSpline[part.chainRollerSplineNodes[i]]
            if splineData ~= nil then
                splineData.isDirty = true
            end
        end
    end
end