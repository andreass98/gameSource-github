ShallowWaterObstacles = {}
ShallowWaterObstacles.OBSTACLE_NODE_XML_KEY = "vehicle.shallowWaterObstacle.obstacleNode(?)"
function ShallowWaterObstacles.prerequisitesPresent(specializations)
    return true
end
function ShallowWaterObstacles.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("ShallowWaterObstacles")
    local key = ShallowWaterObstacles.OBSTACLE_NODE_XML_KEY
    schema:register(XMLValueType.NODE_INDEX, key .. "#node", "Obstacle node")
    schema:register(XMLValueType.NODE_INDEX, key .. "#directionNode", "Node that is used as reference for the moving direction", "Same as #node")
    schema:register(XMLValueType.VECTOR_3, key .. "#size", "Size of the obstacle in m", "1 1 1")
    schema:register(XMLValueType.VECTOR_TRANS, key .. "#offset", "Offset of the obstacle in local space", "0 0 0")
    schema:setXMLSpecializationType()
end
function ShallowWaterObstacles.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadObstacleNodeFromXML", ShallowWaterObstacles.loadObstacleNodeFromXML)
end
function ShallowWaterObstacles.registerEventListeners(vehicleType)
    if Platform.hasShallowWaterSimulation then
        SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ShallowWaterObstacles)
        SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", ShallowWaterObstacles)
        SpecializationUtil.registerEventListener(vehicleType, "onDelete", ShallowWaterObstacles)
    end
end
function ShallowWaterObstacles:onPostLoad(_)
    local spec = self.spec_shallowWaterObstacles
    spec.obstacleNodes = {}
    for _, key in self.xmlFile:iterator("vehicle.shallowWaterObstacle.obstacleNode") do
        local obstacleNode = {}
        if self:loadObstacleNodeFromXML(self.xmlFile, key, obstacleNode) then
            table.insert(spec.obstacleNodes, obstacleNode)
            obstacleNode.vehicle = self
            obstacleNode.index = #spec.obstacleNodes
        end
    end
    if #spec.obstacleNodes == 0 then
        SpecializationUtil.removeEventListener(self, "onLoadFinished", ShallowWaterObstacles)
        SpecializationUtil.removeEventListener(self, "onDelete", ShallowWaterObstacles)
        spec.obstacleNodes = nil
    end
end
function ShallowWaterObstacles:onLoadFinished(_)
    if self.propertyState ~= VehiclePropertyState.SHOP_CONFIG then
        for _, obstacleNode in ipairs(self.spec_shallowWaterObstacles.obstacleNodes) do
            obstacleNode.shallowWaterObstacle = g_currentMission.shallowWaterSimulation:addObstacle(obstacleNode.node, obstacleNode.size[1], obstacleNode.size[2], obstacleNode.size[3], ShallowWaterObstacles.getShallowWaterParameters, obstacleNode, obstacleNode.offset)
        end
    end
end
function ShallowWaterObstacles:onDelete()
    local spec = self.spec_shallowWaterObstacles
    if spec.obstacleNodes ~= nil then
        for _, obstacleNode in ipairs(spec.obstacleNodes) do
            if obstacleNode.shallowWaterObstacle ~= nil then
                g_currentMission.shallowWaterSimulation:removeObstacle(obstacleNode.shallowWaterObstacle)
                obstacleNode.shallowWaterObstacle = nil
            end
        end
    end
end
function ShallowWaterObstacles:loadObstacleNodeFromXML(xmlFile, key, obstacleNode)
    local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
    if node == nil then
        Logging.xmlWarning(xmlFile, "Missing node for obstacle node \'%s\'", key)
        return false
    end
    obstacleNode.node = node
    obstacleNode.directionNode = xmlFile:getValue(key .. "#directionNode", node, self.components, self.i3dMappings)
    obstacleNode.size = xmlFile:getValue(key .. "#size", "1 1 1", true)
    obstacleNode.offset = xmlFile:getValue(key .. "#offset", nil, true)
    obstacleNode.lastWorldPosition = { 0, 0 }
    return true
end
function ShallowWaterObstacles.getShallowWaterParameters(obstacleNode)
    local velocity = obstacleNode.vehicle.lastSignedSpeed * 1000
    local wx, _, wz = getWorldTranslation(obstacleNode.node)
    local dx = wx - obstacleNode.lastWorldPosition[1]
    local dz = wz - obstacleNode.lastWorldPosition[2]
    local length = MathUtil.vector2Length(dx, dz)
    local dx, dz
    if length > 0 then
    else
        dx = 0
        dz = 0
    end
    obstacleNode.lastWorldPosition[1] = wx
    obstacleNode.lastWorldPosition[2] = wz
    local hdx, _, hdz = localDirectionToWorld(obstacleNode.directionNode, 0, 0, 1)
    local yRot = MathUtil.getYRotationFromDirection(hdx, hdz)
    return dx * velocity, dz * velocity, yRot
end