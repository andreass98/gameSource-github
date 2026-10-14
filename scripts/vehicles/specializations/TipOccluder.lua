TipOccluder = {}
function TipOccluder.prerequisitesPresent(specializations)
    return true
end
function TipOccluder.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("TipOccluder")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.tipOccluder.occlusionArea(?)#start", "Start node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.tipOccluder.occlusionArea(?)#width", "Width node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.tipOccluder.occlusionArea(?)#height", "Height node")
    schema:setXMLSpecializationType()
end
function TipOccluder.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getTipOcclusionAreas", TipOccluder.getTipOcclusionAreas)
    SpecializationUtil.registerFunction(vehicleType, "getWheelsWithTipOcclisionAreaGroupId", TipOccluder.getWheelsWithTipOcclisionAreaGroupId)
    SpecializationUtil.registerFunction(vehicleType, "getRequiresTipOcclusionArea", TipOccluder.getRequiresTipOcclusionArea)
end
function TipOccluder.registerOverwrittenFunctions(vehicleType) end
function TipOccluder.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", TipOccluder)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", TipOccluder)
end
function TipOccluder:onLoad(_)
    local spec = self.spec_tipOccluder
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.tipOcclusionAreas.tipOcclusionArea", "vehicle.tipOccluder.occlusionArea")
    spec.tipOcclusionAreas = {}
    local i = 0
    while true do
        local key = string.format("vehicle.tipOccluder.occlusionArea(%d)", i)
        if not self.xmlFile:hasProperty(key) then
            break
        end
        local entry = {
            ["start"] = self.xmlFile:getValue(key .. "#start", nil, self.components, self.i3dMappings),
            ["width"] = self.xmlFile:getValue(key .. "#width", nil, self.components, self.i3dMappings),
            ["height"] = self.xmlFile:getValue(key .. "#height", nil, self.components, self.i3dMappings)
        }
        if entry.start ~= nil and (entry.width ~= nil and entry.height ~= nil) then
            table.insert(spec.tipOcclusionAreas, entry)
        end
        i = i + 1
    end
    spec.createdTipOcclusionAreaGroupIds = {}
end
function TipOccluder:onLoadFinished(_)
    if self.getWheels ~= nil then
        for i, wheel in ipairs(self:getWheels()) do
            local wheelGroupId = wheel.physics.tipOcclusionAreaGroupId
            if wheelGroupId ~= nil then
                local doCreate = true
                local area = nil
                for groupId, occluderArea in pairs(self.spec_tipOccluder.createdTipOcclusionAreaGroupIds) do
                    if groupId == wheelGroupId then
                        doCreate = false
                        area = occluderArea
                        break
                    end
                end
                if doCreate then
                    local start = createTransformGroup(string.format("tipOcclusionAreaGroupId%d", wheelGroupId))
                    local width = createTransformGroup(string.format("tipOcclusionAreaGroupId%d", wheelGroupId))
                    local height = createTransformGroup(string.format("tipOcclusionAreaGroupId%d", wheelGroupId))
                    link(self.components[1].node, start)
                    link(vehicleRootNode, width)
                    link(vehicleRootNode, height)
                    area = {
                        ["start"] = start,
                        ["width"] = width,
                        ["height"] = height
                    }
                    table.insert(spec.tipOcclusionAreas, area)
                    spec.createdTipOcclusionAreaGroupIds[wheelGroupId] = area
                end
                if area ~= nil then
                    local start = -math.huge
                    local width = math.huge
                    local height = -math.huge
                    local groupId = math.huge
                    local occluderArea = self:getWheelsWithTipOcclisionAreaGroupId(self:getWheels(), wheelGroupId)
                    table.insert(occluderArea, wheel)
                    local rootNodeToUse = occluderArea[#occluderArea].node
                    link(rootNodeToUse, area.start)
                    link(rootNodeToUse, area.width)
                    link(rootNodeToUse, area.height)
                    for _, usedWheel in pairs(occluderArea) do
                        local x, _, z = localToLocal(usedWheel.driveNode, rootNodeToUse, usedWheel.physics.wheelShapeWidth - 0.5 * usedWheel.physics.width, 0, -usedWheel.physics.radius)
                        start = math.max(x, start)
                        groupId = math.min(z, groupId)
                        local x, _, z = localToLocal(usedWheel.driveNode, rootNodeToUse, -usedWheel.physics.wheelShapeWidth + 0.5 * usedWheel.physics.width, 0, usedWheel.physics.radius)
                        width = math.min(x, width)
                        height = math.max(z, height)
                    end
                    setTranslation(area.start, start, 0, groupId)
                    setTranslation(area.width, width, 0, groupId)
                    setTranslation(area.height, start, 0, height)
                end
            end
        end
    end
    if self:getRequiresTipOcclusionArea() and #self.spec_tipOccluder.tipOcclusionAreas == 0 then
        Logging.xmlDevWarning(self.xmlFile, "No TipOcclusionArea defined")
    end
end
function TipOccluder:getTipOcclusionAreas()
    return self.spec_tipOccluder.tipOcclusionAreas
end
function TipOccluder.getWheelsWithTipOcclisionAreaGroupId(_, wheels, groupId)
    local returnWheels = {}
    for _, wheel in pairs(wheels) do
        if wheel.physics.tipOcclusionAreaGroupId == groupId then
            table.insert(returnWheels, wheel)
        end
    end
    return returnWheels
end
function TipOccluder:getRequiresTipOcclusionArea()
    return false
end