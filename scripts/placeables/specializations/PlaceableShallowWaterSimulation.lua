PlaceableShallowWaterSimulation = {}
function PlaceableShallowWaterSimulation.prerequisitesPresent(specializations)
    return true
end
function PlaceableShallowWaterSimulation.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableShallowWaterSimulation)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableShallowWaterSimulation)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableShallowWaterSimulation)
end
function PlaceableShallowWaterSimulation.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("ShallowWaterSimulation")
    basePath = basePath .. ".shallowWaterSimulation"
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".waterPlane(?)#node", "water plane shape to add to the shallow water simulation")
    schema:register(XMLValueType.STRING, basePath .. ".waterPlane(?)#materialName", "optional material name of a registered material to apply onto the shape, otherwise the material already present will be kept")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".obstacle(?)#node", "Obstacle node")
    ObstacleType.registerXMLPath(schema, basePath .. ".obstacle(?)#type", "Obstacle Type", "RECTANGLE", false)
    schema:register(XMLValueType.VECTOR_3, basePath .. ".obstacle(?)#size", "Size of the obstacle in m", "1 1 1")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".obstacle(?)#offset", "Offset of the obstacle in local space", "0 0 0")
    schema:setXMLSpecializationType()
end
function PlaceableShallowWaterSimulation:onLoad(_)
    if g_currentMission.shallowWaterSimulation == nil then
        return
    elseif self.propertyState ~= PlaceablePropertyState.CONSTRUCTION_PREVIEW then
        for _, waterPlaneKey in self.xmlFile:iterator("placeable.shallowWaterSimulation.waterPlane") do
            local waterPlane = self.xmlFile:getValue(waterPlaneKey .. "#node", nil, self.components, self.i3dMappings)
            if waterPlane ~= nil then
                local materialName = self.xmlFile:getValue(waterPlaneKey .. "#materialName", nil)
                if materialName ~= nil then
                    local waterSimMat = g_materialManager:getBaseMaterialByName(materialName)
                    if waterSimMat == nil then
                        Logging.xmlError(self.xmlFile, "Unable to retrieve material %s for water plane %q at %q", materialName, getName(waterPlane), waterPlaneKey)
                    else
                        setMaterial(waterPlane, waterSimMat, 0)
                    end
                end
                self.spec_shallowWaterSimulation.waterPlanes = self.spec_shallowWaterSimulation.waterPlanes or {}
                if g_currentMission.shallowWaterSimulation:addWaterPlane(waterPlane) then
                    g_currentMission.shallowWaterSimulation:addAreaGeometry(waterPlane)
                    table.insert(spec.waterPlanes, waterPlane)
                end
            end
        end
        for _, waterPlaneKey in self.xmlFile:iterator("placeable.shallowWaterSimulation.obstacle") do
            local waterPlane = self.xmlFile:getValue(waterPlaneKey .. "#node", nil, self.components, self.i3dMappings)
            if waterPlane == nil then
                Logging.xmlWarning(self.xmlFile, "Missing node for obstacle node \'%s\'", waterPlaneKey)
            else
                local materialName = ObstacleType.loadFromXMLFile(self.xmlFile, waterPlaneKey .. "#type") or ObstacleType.RECTANGLE
                local waterSimMat = self.xmlFile:getValue(waterPlaneKey .. "#size", "1 1 1", true)
                local offset = self.xmlFile:getValue(waterPlaneKey .. "#offset", nil, true)
                local xDir, _, zDir = localDirectionToWorld(waterPlane, 0, 0, 1)
                local rotY = MathUtil.getYRotationFromDirection(xDir, zDir)
                local obstacle = g_currentMission.shallowWaterSimulation:addObstacle(waterPlane, waterSimMat[1], waterSimMat[2], waterSimMat[3], nil, nil, offset, rotY, materialName)
                if obstacle ~= nil then
                    spec.obstacles = spec.obstacles or {}
                    table.insert(spec.obstacles, obstacle)
                end
            end
        end
    end
end
function PlaceableShallowWaterSimulation:onFinalizePlacement()
    local spec = self.spec_shallowWaterSimulation
    if spec.obstacles ~= nil then
        for k, obstacle in ipairs_reverse(spec.obstacles) do
            if not getVisibility(obstacle.node) then
                g_currentMission.shallowWaterSimulation:removeObstacle(obstacle)
                table.remove(spec.obstacles, k)
            end
        end
    end
end
function PlaceableShallowWaterSimulation:onDelete()
    local spec = self.spec_shallowWaterSimulation
    if spec.waterPlanes ~= nil then
        for _, waterPlane in ipairs(spec.waterPlanes) do
            g_currentMission.shallowWaterSimulation:removeAreaGeometry(waterPlane)
            g_currentMission.shallowWaterSimulation:removeWaterPlane(waterPlane)
        end
        spec.waterPlanes = nil
    end
    if spec.obstacles ~= nil then
        for _, waterPlane in ipairs(spec.obstacles) do
            g_currentMission.shallowWaterSimulation:removeObstacle(waterPlane)
        end
        spec.obstacles = nil
    end
end