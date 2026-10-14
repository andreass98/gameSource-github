PlacementUtil = {}
PlacementUtil.TEST_HEIGHT = 10
PlacementUtil.TEST_STEP_SIZE = 1
PlacementUtil.NETHER_HEIGHT = -150
function PlacementUtil.getPlace(places, size, usage, includeDynamics, includeKinematics, includeStatics, doExactTest)
    for _, place in pairs(places) do
        if size.width <= place.maxWidth and (size.length <= place.maxLength and size.height <= place.maxHeight) then
            local halfSizeX = size.width * 0.5
            local width = (usage[place] == nil and 0 or usage[place]) + halfSizeX
            for width = width, place.width - halfSizeX, PlacementUtil.TEST_STEP_SIZE do
                local x = place.startX + width * place.dirX
                local y = place.startY + width * place.dirY
                local z = place.startZ + width * place.dirZ
                local vehicleY = getTerrainHeightAtWorldPos(g_terrainNode, x, y, z) + 0.5
                local vehicleX = math.max(vehicleY, y)
                PlacementUtil.tempHasCollision = false
                overlapBox(x, vehicleX, z, place.rotX, place.rotY, place.rotZ, size.width * 0.5, PlacementUtil.TEST_HEIGHT * 0.5, size.length * 0.5, "PlacementUtil.collisionTestCallback", nil, CollisionFlag.VEHICLE + CollisionFlag.PLAYER + CollisionFlag.DYNAMIC_OBJECT, includeDynamics, includeKinematics, includeStatics, doExactTest)
                if not PlacementUtil.tempHasCollision then
                    local terrainHeight = getTerrainHeightAtWorldPos(g_terrainNode, x, vehicleX, z)
                    local y = math.max(terrainHeight + place.yOffset, vehicleX)
                    return vehicleX, x - size.widthOffset * place.dirX - size.lengthOffset * place.dirPerpX - size.widthOffset * place.dirY - size.lengthOffset * place.dirPerpY, z - size.widthOffset * place.dirZ - size.lengthOffset * place.dirPerpZ, place, width + halfSizeX, y - terrainHeight
                end
            end
        end
    end
    return nil
end
function PlacementUtil.markPlaceUsed(usage, place, width)
    usage[place] = width
end
function PlacementUtil.unmarkPlaceUsed(usage, place)
    usage[place] = nil
end
function PlacementUtil.collisionTestCallback(_, transformId)
    if g_currentMission.nodeToObject[transformId] == nil and (g_currentMission.players[transformId] == nil and g_currentMission:getNodeObject(transformId) == nil) then
        return true
    end
    PlacementUtil.tempHasCollision = true
    return false
end
function PlacementUtil.loadPlaceFromXML(xmlFile, key, rootNode, i3dMappings)
    local startNode = xmlFile:getValue(key .. "#startNode", nil, rootNode, i3dMappings)
    local endNode = xmlFile:getValue(key .. "#endNode", nil, rootNode, i3dMappings)
    local isInverted = xmlFile:getValue(key .. "#isInverted", false)
    local place = PlacementUtil.loadPlaceFromNode(startNode, endNode, isInverted)
    if place == nil then
        return nil
    end
    place.maxWidth = xmlFile:getValue(key .. "#maxWidth") or place.maxWidth
    place.maxLength = xmlFile:getValue(key .. "#maxLength") or place.maxLength
    place.maxHeight = xmlFile:getValue(key .. "#maxHeight") or place.maxHeight
    place.length = xmlFile:getValue(key .. "#length") or place.length
    place.palletRotationOffset = xmlFile:getValue(key .. "#palletRotationOffset") or place.palletRotationOffset
    return place
end
function PlacementUtil.loadPlaceFromNode(startNode, endNode, isInverted)
    if startNode == nil then
        return nil
    end
    local place = {}
    local numChildren, x, y = getWorldTranslation(startNode)
    place.startX = numChildren
    place.startY = x
    place.startZ = y
    place.width = getUserAttribute(startNode, "width") or 2
    place.length = getUserAttribute(startNode, "length") or 20
    place.yOffset = getUserAttribute(startNode, "yOffset") or 1
    place.maxWidth = getUserAttribute(startNode, "maxWidth") or math.huge
    place.maxLength = getUserAttribute(startNode, "maxLength") or math.huge
    place.maxHeight = getUserAttribute(startNode, "maxHeight") or math.huge
    local x = getUserAttribute(startNode, "palletRotationOffset") or 0
    place.palletRotationOffset = math.rad(x)
    local numChildren = getNumOfChildren(startNode)
    if endNode == nil then
        if numChildren == 1 then
            endNode = getChildAt(startNode, 0)
        else
            Logging.warning("No end node given and no child node present for place %s", getName(startNode))
        end
    end
    if endNode ~= nil then
        local x, y, z = getWorldTranslation(endNode)
        local dx = x - place.startX
        local dy = y - place.startY
        local dz = z - place.startZ
        if dx == 0 and dz == 0 then
            Logging.error("PlacementUtil.loadPlaceFromNode(): Start node %q and end node %q are on the same location", getName(startNode), getName(endNode))
            return nil
        end
        place.width = MathUtil.vector3Length(dx, dy, dz)
        local dirX, dirY, dirZ = MathUtil.vector3Normalize(dx, dy, dz)
        local wdirX, wdirY, wdirZ = worldDirectionToLocal(getParent(startNode), dirX, dirY, dirZ)
        local upX, upY, upZ = localDirectionToLocal(startNode, getParent(startNode), 0, 1, 0)
        setDirection(startNode, wdirX, wdirY, wdirZ, upX, upY, upZ)
        rotateAboutLocalAxis(startNode, -1.5707963267948966, 0, 1, 0)
    end
    if numChildren > 1 then
        Logging.warning("loadPlaceFromNode: Node \'%s\' has more than one child node. Use \'maxLength\' user- or xml-attribute to limit the maximum vehicle length.", getName(startNode))
    end
    local x, y, z = getWorldRotation(startNode)
    place.rotX = x
    place.rotY = y
    place.rotZ = z
    if isInverted then
        place.rotY = place.rotY + 3.141592653589793
    end
    local x, y, z = localDirectionToWorld(startNode, 1, 0, 0)
    place.dirX = x
    place.dirY = y
    place.dirZ = z
    local x = localDirectionToWorld
    local z = 0
    local dx = 0
    local dy = isInverted and -1 or 1
    local x, y, z = x(startNode, z, dx, dy)
    place.dirPerpX = x
    place.dirPerpY = y
    place.dirPerpZ = z
    place.startNode = startNode
    setWorldRotation(startNode, place.rotX, place.rotY, place.rotZ)
    return place
end
function PlacementUtil.createRestrictedZone(node)
    local restrictedZone = {}
    local x, _, z = getWorldTranslation(node)
    restrictedZone.x = x
    restrictedZone.z = z
    if getNumOfChildren(node) > 0 then
        local x, _, z = getTranslation(getChildAt(node, 0))
        restrictedZone.width = math.abs(x)
        restrictedZone.length = math.abs(z)
        if x < 0 then
            restrictedZone.x = restrictedZone.x + x
        end
        if z < 0 then
            restrictedZone.z = restrictedZone.z + z
            return restrictedZone
        end
    else
        restrictedZone.width = 1
        restrictedZone.length = 1
    end
    return restrictedZone
end
function PlacementUtil.isInsideRestrictedZone(restrictedZones, x, y, z, doWaterCheck)
    for _, restrictedZone in pairs(restrictedZones) do
        local dx = restrictedZone.x + restrictedZone.width - x
        local dz = restrictedZone.z + restrictedZone.length - z
        if dx > 0 and (dx < restrictedZone.width and (dz > 0 and dz < restrictedZone.length)) then
            return true
        end
    end
    return Utils.getNoNil(doWaterCheck, true) and y < (g_currentMission.environmentAreaSystem:getWaterYAtWorldPosition(x, y, z) or -2000) - 0.5 and true or false
end
function PlacementUtil.isInsidePlacementPlaces(places, x, _, z)
    for _, place in pairs(places) do
        local dx = place.dirX
        local dz = place.dirZ
        local sx = place.startX
        local sz = place.startZ
        local width = place.width
        local t = (x - sx) * dx + (z - sz) * dz
        local ex
        if t >= 0 and t <= width then
            ex = math.abs((sz - z) * dx - (sx - x) * dz)
        elseif t < 0 then
            ex = math.sqrt((sx - x) * (sx - x) + (sz - z) * (sz - z))
        else
            local ex = place.startX + width * dx
            local ez = place.startZ + width * dz
            ex = math.sqrt((ex - x) * (ex - x) + (ez - z) * (ez - z))
        end
        if ex <= place.length * 0.5 then
            return true
        end
    end
    return false
end
function PlacementUtil.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".spawnPlaces.spawnPlace(?)#startNode", "Spawn area start node, end node default is first child")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".spawnPlaces.spawnPlace(?)#endNode", "Spawn area end node, end node is first child")
    schema:register(XMLValueType.FLOAT, basePath .. ".spawnPlaces.spawnPlace(?)#width", "Spawn area width in m if no child is present for node")
    schema:register(XMLValueType.FLOAT, basePath .. ".spawnPlaces.spawnPlace(?)#length", "Spawn area length in m if no child is present for node")
    schema:register(XMLValueType.FLOAT, basePath .. ".spawnPlaces.spawnPlace(?)#maxWidth", "Spawn area maximum width of object to spawn")
    schema:register(XMLValueType.FLOAT, basePath .. ".spawnPlaces.spawnPlace(?)#maxLength", "Spawn area maximum length of object to spawn")
    schema:register(XMLValueType.FLOAT, basePath .. ".spawnPlaces.spawnPlace(?)#maxHeight", "Spawn area maximum height of object to spawn")
    schema:register(XMLValueType.BOOL, basePath .. ".spawnPlaces.spawnPlace(?)#isInverted", "Invert the spawn direction of the vehicles", false)
    schema:register(XMLValueType.ANGLE, basePath .. ".spawnPlaces.spawnPlace(?)#palletRotationOffset", "Rotation offset in degrees used for the spawned pallets (offset of 0 spawns pallets perpendicular to line between start and end)", 0)
end