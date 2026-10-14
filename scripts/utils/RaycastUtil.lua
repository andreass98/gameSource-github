RaycastUtil = {}
function RaycastUtil.getCameraPickingRay(cursorX, cursorY, cameraNode)
    local camX, camY, camZ = getWorldTranslation(cameraNode)
    local pickX, pickY, pickZ = unProject(cursorX, cursorY, 1)
    local dirX, dirY, dirZ = MathUtil.vector3Normalize(pickX - camX, pickY - camY, pickZ - camZ)
    return camX, camY, camZ, dirX, dirY, dirZ
end
function RaycastUtil.raycastClosest(x, y, z, dx, dy, dz, maxDistance, collisionMask)
    RaycastUtil.closestId = nil
    RaycastUtil.closestX = nil
    RaycastUtil.closestY = nil
    RaycastUtil.closestZ = nil
    raycastClosest(x, y, z, dx, dy, dz, maxDistance, "raycastClosestCallback", RaycastUtil, collisionMask)
    return RaycastUtil.closestId, RaycastUtil.closestX, RaycastUtil.closestY, RaycastUtil.closestZ, RaycastUtil.distance
end
function RaycastUtil.raycastClosestCallback(_, hitObjectId, x, y, z, distance)
    RaycastUtil.closestId = hitObjectId
    RaycastUtil.distance = distance
    RaycastUtil.closestX = x
    RaycastUtil.closestY = y
    RaycastUtil.closestZ = z
end
function RaycastUtil.raycastBox(x, y, z, rx, ry, rz, ex, ey, ez, collisionMask)
    overlapBox(x, y, z, rx, ry, rz, ex, ey, ez, "boxOverlapCallback", RaycastUtil, collisionMask, true, true, true, true)
end
function RaycastUtil.boxOverlapCallback(_, hitObjectId, x, y, z, distance)
    log("BOX HIT", hitObjectId, x, y, z, distance)
end
function RaycastUtil.raycastSphere(x, y, z, radius, collisionMask)
    overlapSphere(x, y, z, radius, "sphereOverlapCallback", RaycastUtil, collisionMask, true, true, true, true)
end
function RaycastUtil.sphereOverlapCallback(_, hitObjectId, x, y, z, distance)
    log("SPHERE HIT", hitObjectId, x, y, z, distance)
end