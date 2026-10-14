DensityMapNodePolygon = {}
local DensityMapNodePolygon_mt = Class(DensityMapNodePolygon)
function DensityMapNodePolygon.new(customMt)
    -- upvalues: (copy) DensityMapNodePolygon_mt
    local self = setmetatable({}, customMt or DensityMapNodePolygon_mt)
    self.nodes = {}
    return self
end
function DensityMapNodePolygon:saveToXMLFile(xmlFile, key) end
function DensityMapNodePolygon:loadFromXMLFile(xmlFile, key)
    return true
end
function DensityMapNodePolygon:addNode(node)
    table.insert(self.nodes, node)
end
function DensityMapNodePolygon:getVerticesAs3DCoordinates(_, _)
    local polygon3DVertices = table.create(#self.nodes * 3)
    for _, node in ipairs(self.nodes) do
        local x, y, z = getWorldTranslation(node)
        table.insert(polygon3DVertices, x)
        table.insert(polygon3DVertices, y)
        table.insert(polygon3DVertices, z)
    end
    return polygon3DVertices
end
function DensityMapNodePolygon:getCenter()
    local worldX = 0
    local worldZ = 0
    local numNodes = #self.nodes
    if numNodes > 0 then
        local i = 1
        for i = i, #self.nodes do
            local x, _, z = getWorldTranslation(self.nodes[i])
        end
        worldX = worldX / numNodes
        worldZ = worldZ / numNodes
    end
    return worldX, worldZ
end
function DensityMapNodePolygon:drawDebug()
    local vertices = {}
    for _, node in ipairs(self.nodes) do
        local x, y, z = getWorldTranslation(node)
        table.insert(vertices, x)
        table.insert(vertices, y)
        table.insert(vertices, z)
    end
    drawDebugPolygon(vertices, 1, 0, 0, 1, false)
end
function DensityMapNodePolygon:applyToModifier(modifier)
    modifier:clearPolygonPoints()
    for _, node in ipairs(self.nodes) do
        local x, _, z = getWorldTranslation(node)
        modifier:addPolygonPointWorldCoords(x, z)
    end
end
function DensityMapNodePolygon.createFromXMLFile(xmlFile, key, components, i3dMappings)
    if not xmlFile:hasProperty(key .. ".polygon.node") then
        return nil
    end
    local polygon = DensityMapNodePolygon.new()
    for _, nodeKey in xmlFile:iterator(key .. ".polygon.node") do
        local node = xmlFile:getValue(nodeKey .. "#node", nil, components, i3dMappings)
        if node == nil then
            Logging.xmlWarning(xmlFile, "Invalid node for DensityMapNodePolygon in \'%s\'", nodeKey)
            return
        end
        polygon:addNode(node)
    end
    if #polygon.nodes >= 3 then
        return polygon
    end
    Logging.xmlWarning(xmlFile, "Too few polygon nodes defined. A polygon needs at least 3 nodes. \'%s\'", key)
    return nil
end
function DensityMapNodePolygon.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".polygon.node(?)#node", "Polygon node", nil, false)
end