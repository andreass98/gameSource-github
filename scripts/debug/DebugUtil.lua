DebugUtil = {}
DebugUtil.DEFAULT_RENDERLINE_SCALAR = 1.1
DebugUtil.COLORS = {
    Color.PRESETS.MAGENTA,
    Color.PRESETS.GREENYELLOW,
    Color.PRESETS.CYAN,
    Color.PRESETS.RED,
    Color.PRESETS.BLUE,
    Color.PRESETS.ORANGE,
    Color.PRESETS.GREEN,
    Color.PRESETS.TEAL
}
function DebugUtil.drawDebugNode(node, text, alignToGround, offsetY)
    local x, y, z = getWorldTranslation(node)
    local upX, upY, upZ = localDirectionToWorld(node, 0, 1, 0)
    local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)
    DebugUtil.drawDebugGizmoAtWorldPos(x, y + (offsetY or 0), z, dirX, dirY, dirZ, upX, upY, upZ, text, alignToGround)
end
function DebugUtil.renderTextAtNode(node, text, textSize)
    local x, y, z = getWorldTranslation(node)
    Utils.renderTextAtWorldPosition(x, y, z, text, textSize or 0.02)
end
function DebugUtil.drawDebugGizmoAtWorldPos(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, text, alignToGround, color)
    local sideX, sideY, sideZ = MathUtil.crossProduct(upX, upY, upZ, dirX, dirY, dirZ)
    if alignToGround then
        y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.1
    end
    drawDebugLine(x, y, z, 1, 0, 0, x + sideX * 0.3, y + sideY * 0.3, z + sideZ * 0.3, 1, 0, 0)
    drawDebugLine(x, y, z, 0, 1, 0, x + upX * 0.3, y + upY * 0.3, z + upZ * 0.3, 0, 1, 0)
    drawDebugLine(x, y, z, 0, 0, 1, x + dirX * 0.3, y + dirY * 0.3, z + dirZ * 0.3, 0, 0, 1)
    if text ~= nil then
        Utils.renderTextAtWorldPosition(x, y, z, tostring(text), getCorrectTextSize(0.012), 0, color)
    end
end
function DebugUtil.drawDebugArea(start, width, height, r, g, b, alignToGround, drawNodes, drawCircle, offsetY)
    offsetY = offsetY or 0
    local x, y, z = getWorldTranslation(start)
    local x1, y1, z1 = getWorldTranslation(width)
    local x2, y2, z2 = getWorldTranslation(height)
    DebugUtil.drawDebugAreaRectangle(x, y + offsetY, z, x1, y1 + offsetY, z1, x2, y2 + offsetY, z2, alignToGround, r, g, b)
    if drawNodes == nil or drawNodes then
        DebugGizmo.renderAtNodeWithOffset(start, 0, offsetY, 0, getName(start), false, 1, alignToGround)
        DebugGizmo.renderAtNodeWithOffset(width, 0, offsetY, 0, getName(width), false, 1, alignToGround)
        DebugGizmo.renderAtNodeWithOffset(height, 0, offsetY, 0, getName(height), false, 1, alignToGround)
    end
    local lsx, lsy, lsz, lex, ley, lez, radius = DensityMapHeightUtil.getLineByArea(start, width, height, 0.5)
    local lsy = lsy + offsetY
    local ley = ley + offsetY
    if alignToGround then
        lsy = getTerrainHeightAtWorldPos(g_terrainNode, lsx, 0, lsz) + 0.1
        ley = getTerrainHeightAtWorldPos(g_terrainNode, lex, 0, lez) + 0.1
    end
    if drawCircle == nil or drawCircle then
        drawDebugLine(lsx, lsy, lsz, 1, 1, 1, lex, ley, lez, 1, 1, 1)
        DebugUtil.drawDebugCircle((lsx + lex) * 0.5, (lsy + ley) * 0.5, (lsz + lez) * 0.5, radius, 20, nil)
    end
end
function DebugUtil.drawDebugLine(x1, y1, z1, x2, y2, z2, r, g, b, radius, alignToGround)
    y1 = y1 or 0
    y2 = y2 or 0
    if alignToGround then
        y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z1) + 0.1
        y2 = getTerrainHeightAtWorldPos(g_terrainNode, x2, 0, z2) + 0.1
    end
    r = r or 1
    g = g or 1
    b = b or 1
    drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b)
    if radius ~= nil then
        DebugUtil.drawDebugCircle(x1, y1, z1, radius, 20, nil)
        DebugUtil.drawDebugCircle(x2, y2, z2, radius, 20, nil)
    end
end
function DebugUtil.drawDebugAreaRectangle(x, y, z, x1, y1, z1, x2, y2, z2, alignToGround, r, g, b)
    if alignToGround then
        y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.1
        y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z1) + 0.1
        y2 = getTerrainHeightAtWorldPos(g_terrainNode, x2, 0, z2) + 0.1
    end
    drawDebugLine(x, y, z, r, g, b, x1, y1, z1, r, g, b)
    drawDebugLine(x, y, z, r, g, b, x2, y2, z2, r, g, b)
    drawDebugLine(x2, y2, z2, r, g, b, x2 + (x1 - x), y2 + (y1 - y), z2 + (z1 - z), r, g, b)
    drawDebugLine(x1, y1, z1, r, g, b, x1 + (x2 - x), y1 + (y2 - y), z1 + (z2 - z), r, g, b)
end
function DebugUtil.drawDebugPlane(x, y, z, forwardX, forwardY, forwardZ, leftX, leftY, leftZ, width, depth, r, g, b, a)
    local x2 = x + leftX * width
    local y2 = y + leftY * width
    local z2 = z + leftZ * width
    local x3 = x + forwardX * depth
    local y3 = y + forwardY * depth
    local z3 = z + forwardZ * depth
    local x4 = x + forwardX * depth + leftX * width
    local y4 = y + forwardY * depth + leftY * width
    local z4 = z + forwardZ * depth + leftZ * width
    DebugUtil.drawDebugAreaRectangle(x, y, z, x2, y2, z2, x3, y3, z3, false, r, g, b)
    drawDebugTriangle(x3, y3, z3, x, y, z, x2, y2, z2, r, g, b, a, true)
    drawDebugTriangle(x4, y4, z4, x3, y3, z3, x2, y2, z2, r, g, b, a, true)
    drawDebugTriangle(x4, y4, z4, x, y, z, x3, y3, z3, r, g, b, a, true)
    drawDebugTriangle(x4, y4, z4, x2, y2, z2, x, y, z, r, g, b, a, true)
end
function DebugUtil.drawDebugAreaRectangleFilled(x, y, z, x1, y1, z1, x2, y2, z2, alignToGround, r, g, b, a)
    local y3 = (y1 + y2) / 2
    if alignToGround then
        y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.1
        y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z1) + 0.1
        y2 = getTerrainHeightAtWorldPos(g_terrainNode, x2, 0, z2) + 0.1
        y3 = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z2) + 0.1
    end
    drawDebugTriangle(x, y, z, x2, y2, z2, x1, y1, z1, r, g, b, a, false)
    drawDebugTriangle(x1, y1, z1, x2, y2, z2, x1, y3, z2, r, g, b, a, false)
end
function DebugUtil.drawDebugRectangle(node, minX, maxX, minZ, maxZ, yOffset, r, g, b, a, filled)
    local leftFrontX, leftFrontY, leftFrontZ = localToWorld(node, minX, yOffset, maxZ)
    local rightFrontX, rightFrontY, rightFrontZ = localToWorld(node, maxX, yOffset, maxZ)
    local leftBackX, leftBackY, leftBackZ = localToWorld(node, minX, yOffset, minZ)
    local rightBackX, rightBackY, rightBackZ = localToWorld(node, maxX, yOffset, minZ)
    drawDebugLine(leftFrontX, leftFrontY, leftFrontZ, r, g, b, rightFrontX, rightFrontY, rightFrontZ, r, g, b)
    drawDebugLine(rightFrontX, rightFrontY, rightFrontZ, r, g, b, rightBackX, rightBackY, rightBackZ, r, g, b)
    drawDebugLine(rightBackX, rightBackY, rightBackZ, r, g, b, leftBackX, leftBackY, leftBackZ, r, g, b)
    drawDebugLine(leftBackX, leftBackY, leftBackZ, r, g, b, leftFrontX, leftFrontY, leftFrontZ, r, g, b)
    if filled then
        drawDebugTriangle(leftFrontX, leftFrontY, leftFrontZ, rightFrontX, rightFrontY, rightFrontZ, rightBackX, rightBackY, rightBackZ, r, g, b, a, true)
        drawDebugTriangle(rightBackX, rightBackY, rightBackZ, leftBackX, leftBackY, leftBackZ, leftFrontX, leftFrontY, leftFrontZ, r, g, b, a, true)
    end
end
function DebugUtil.drawDebugSphere(x, y, z, radius, radialSegments, rings, color, alignToGround, solid)
    if alignToGround then
        y = getTerrainHeightAtWorldPos(g_terrainNode, x, y, z)
    end
    local ringSpacing = radius * 2 / (rings + 1)
    local ringY = y + radius - ringSpacing
    local lastRingY = y + radius
    local lastRingRadius = 0
    drawDebugPoint(x, y, z, color.r, color.g, color.b, color.a, solid)
    for i = 1, rings do
        local radialAngleCos = radius ^ 2 - (y - ringY) ^ 2
        local ringRadius = math.sqrt(radialAngleCos)
        DebugUtil.drawDebugCircle(x, ringY, z, ringRadius, radialSegments, color, false, false, solid)
        local radialAngle = 0
        local radialPositionX = 1
        for j = 1, radialSegments, radialPositionX do
            local radialAngleCos = math.cos(radialAngle)
            drawDebugLine(x + radialAngleCos * lastRingRadius, lastRingY, z + (x + radialAngleCos * ringRadius) * lastRingRadius, color[1], color[2], color[3], radialPositionX, ringY, z + math.sin(radialAngle) * ringRadius, color[1], color[2], color[3], solid)
            radialAngle = radialAngle + 6.283185307179586 / radialSegments
        end
        local ringY = ringY - ringSpacing
    end
    local radialAngle = 0
    for i = 1, radialSegments do
        local radialPositionX = math.sin(radialAngle)
        local radialPositionX = x + math.cos(radialAngle) * lastRingRadius
        drawDebugLine(radialPositionX, lastRingY, z + radialPositionX * lastRingRadius, color[1], color[2], color[3], x, ringY, z, color[1], color[2], color[3], solid)
        radialAngle = radialAngle + radialSpacing
    end
end
function DebugUtil.drawDebugCircle(x, y, z, radius, steps, color, alignToTerrain, filled, solid)
    local r = 1
    local g = 0
    local b = 0
    if color ~= nil then
        r = color[1]
        g = color[2]
        b = color[3]
    end
    local i = 1
    for i = i, steps do
        local a1 = (i - 1) / steps * 2 * 3.141592653589793
        local a2 = i / steps * 2 * 3.141592653589793
        local c = math.cos(a1) * radius
        local s = math.sin(a1) * radius
        local x1 = x + c
        local z1 = z + s
        local c = math.cos(a2) * radius
        local s = math.sin(a2) * radius
        local x2 = x + c
        local z2 = z + s
        local y1, y2
        if alignToTerrain then
            y = getTerrainHeightAtWorldPos(g_terrainNode, x, y, z) + 0.25
            y1 = getTerrainHeightAtWorldPos(terrainNode, x1, y, z1) + 0.25
            y2 = getTerrainHeightAtWorldPos(terrainNode, x2, y, z2) + 0.25
        else
            y2 = y
            y1 = y2
            y2 = y1
        end
        drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b, solid)
        if filled then
            drawDebugTriangle(x, y, z, x2, y2, z2, x1, y1, z1, r, g, b, 0.3, solid)
        end
    end
end
function DebugUtil.drawDebugCircleAtNode(node, radius, steps, color, vertical, offset)
    local ox = 0
    local oy = 0
    local oz = 0
    if offset ~= nil then
        ox = offset[1]
        oy = offset[2]
        oz = offset[3]
    end
    local i = 1
    for i = i, steps do
        local a1 = (i - 1) / steps * 2 * 3.141592653589793
        local a2 = i / steps * 2 * 3.141592653589793
        local c = math.cos(a1) * radius
        local s = math.sin(a1) * radius
        local x2, y2, z2
        if vertical then
            x2, y2, z2 = localToWorld(node, ox + 0, oy + c, oz + s)
        else
            x2, y2, z2 = localToWorld(node, ox + c, oy + 0, oz + s)
        end
        local c = math.cos(a2) * radius
        local s = math.sin(a2) * radius
        local x2, y2, z2
        if vertical then
            x2, y2, z2 = localToWorld(node, ox + 0, oy + c, oz + s)
        else
            x2, y2, z2 = localToWorld(node, ox + c, oy + 0, oz + s)
        end
        if color == nil then
            drawDebugLine(x2, y2, z2, 1, 0, 0, x2, y2, z2, 1, 0, 0)
        else
            drawDebugLine(x2, y2, z2, color[1], color[2], color[3], x2, y2, z2, color[1], color[2], color[3])
        end
    end
end
function DebugUtil.drawDebugCubeAtWorldPos(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, sizeX, sizeY, sizeZ, r, g, b)
    local temp = createTransformGroup("temp_drawDebugCubeAtWorldPos")
    link(getRootNode(), temp)
    setTranslation(temp, x, y, z)
    setDirection(temp, dirX, dirY, dirZ, upX, upY, upZ)
    DebugUtil.drawDebugCube(temp, sizeX, sizeY, sizeZ, r, g, b)
    delete(temp)
end
function DebugUtil.drawOverlapBox(x, y, z, rotX, rotY, rotZ, extendX, extendY, extendZ, r, g, b)
    local temp = createTransformGroup("temp_drawDebugCubeAtWorldPos")
    link(getRootNode(), temp)
    setTranslation(temp, x, y, z)
    setRotation(temp, rotX, rotY, rotZ)
    DebugUtil.drawDebugCube(temp, extendX * 2, extendY * 2, extendZ * 2, r, g, b)
    delete(temp)
end
function DebugUtil.drawDebugCube(node, sizeX, sizeY, sizeZ, r, g, b, offsetX, offsetY, offsetZ)
    sizeX = sizeX * 0.5
    sizeY = sizeY * 0.5
    sizeZ = sizeZ * 0.5
    r = r or 1
    g = g or 1
    b = b or 1
    local x, y, z = localToWorld(node, offsetX or 0, offsetY or 0, offsetZ or 0)
    local up1X, up1Y, up1Z = localDirectionToWorld(node, 1, 0, 0)
    local upX, upY, upZ = localDirectionToWorld(node, 0, 1, 0)
    local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)
    local up1X = up1X * sizeX
    local up1Y = up1Y * sizeX
    local up1Z = up1Z * sizeX
    local upX = upX * sizeY
    local upY = upY * sizeY
    local upZ = upZ * sizeY
    local dirX = dirX * sizeZ
    local dirY = dirY * sizeZ
    local dirZ = dirZ * sizeZ
    drawDebugLine(x + up1X - dirX - upX, y + up1Y - dirY - upY, z + up1Z - dirZ - upZ, r, g, b, x + up1X - dirX + upX, y + up1Y - dirY + upY, z + up1Z - dirZ + upZ, r, g, b)
    drawDebugLine(x - up1X - dirX - upX, y - up1Y - dirY - upY, z - up1Z - dirZ - upZ, r, g, b, x - up1X - dirX + upX, y - up1Y - dirY + upY, z - up1Z - dirZ + upZ, r, g, b)
    drawDebugLine(x + up1X + dirX - upX, y + up1Y + dirY - upY, z + up1Z + dirZ - upZ, r, g, b, x + up1X + dirX + upX, y + up1Y + dirY + upY, z + up1Z + dirZ + upZ, r, g, b)
    drawDebugLine(x - up1X + dirX - upX, y - up1Y + dirY - upY, z - up1Z + dirZ - upZ, r, g, b, x - up1X + dirX + upX, y - up1Y + dirY + upY, z - up1Z + dirZ + upZ, r, g, b)
    drawDebugLine(x + up1X - dirX + upX, y + up1Y - dirY + upY, z + up1Z - dirZ + upZ, r, g, b, x - up1X - dirX + upX, y - up1Y - dirY + upY, z - up1Z - dirZ + upZ, r, g, b)
    drawDebugLine(x - up1X - dirX + upX, y - up1Y - dirY + upY, z - up1Z - dirZ + upZ, r, g, b, x - up1X + dirX + upX, y - up1Y + dirY + upY, z - up1Z + dirZ + upZ, r, g, b)
    drawDebugLine(x - up1X + dirX + upX, y - up1Y + dirY + upY, z - up1Z + dirZ + upZ, r, g, b, x + up1X + dirX + upX, y + up1Y + dirY + upY, z + up1Z + dirZ + upZ, r, g, b)
    drawDebugLine(x + up1X + dirX + upX, y + up1Y + dirY + upY, z + up1Z + dirZ + upZ, r, g, b, x + up1X - dirX + upX, y + up1Y - dirY + upY, z + up1Z - dirZ + upZ, r, g, b)
    drawDebugLine(x + up1X - dirX - upX, y + up1Y - dirY - upY, z + up1Z - dirZ - upZ, r, g, b, x - up1X - dirX - upX, y - up1Y - dirY - upY, z - up1Z - dirZ - upZ, r, g, b)
    drawDebugLine(x - up1X - dirX - upX, y - up1Y - dirY - upY, z - up1Z - dirZ - upZ, r, g, b, x - up1X + dirX - upX, y - up1Y + dirY - upY, z - up1Z + dirZ - upZ, r, g, b)
    drawDebugLine(x - up1X + dirX - upX, y - up1Y + dirY - upY, z - up1Z + dirZ - upZ, r, g, b, x + up1X + dirX - upX, y + up1Y + dirY - upY, z + up1Z + dirZ - upZ, r, g, b)
    drawDebugLine(x + up1X + dirX - upX, y + up1Y + dirY - upY, z + up1Z + dirZ - upZ, r, g, b, x + up1X - dirX - upX, y + up1Y - dirY - upY, z + up1Z - dirZ - upZ, r, g, b)
end
function DebugUtil.drawSimpleDebugCube(x, y, z, width, r, g, b)
    local halfWidth = width * 0.5
    drawDebugLine(x - halfWidth, y - halfWidth, z - halfWidth, r, g, b, x + halfWidth, y - halfWidth, z - halfWidth, r, g, b)
    drawDebugLine(x - halfWidth, y - halfWidth, z - halfWidth, r, g, b, x - halfWidth, y + halfWidth, z - halfWidth, r, g, b)
    drawDebugLine(x - halfWidth, y - halfWidth, z - halfWidth, r, g, b, x - halfWidth, y - halfWidth, z + halfWidth, r, g, b)
    drawDebugLine(x + halfWidth, y + halfWidth, z + halfWidth, r, g, b, x - halfWidth, y + halfWidth, z + halfWidth, r, g, b)
    drawDebugLine(x + halfWidth, y + halfWidth, z + halfWidth, r, g, b, x + halfWidth, y - halfWidth, z + halfWidth, r, g, b)
    drawDebugLine(x + halfWidth, y + halfWidth, z + halfWidth, r, g, b, x + halfWidth, y + halfWidth, z - halfWidth, r, g, b)
    drawDebugLine(x - halfWidth, y - halfWidth, z + halfWidth, r, g, b, x + halfWidth, y - halfWidth, z + halfWidth, r, g, b)
    drawDebugLine(x - halfWidth, y - halfWidth, z + halfWidth, r, g, b, x - halfWidth, y + halfWidth, z + halfWidth, r, g, b)
    drawDebugLine(x - halfWidth, y + halfWidth, z - halfWidth, r, g, b, x - halfWidth, y + halfWidth, z + halfWidth, r, g, b)
    drawDebugLine(x - halfWidth, y + halfWidth, z - halfWidth, r, g, b, x + halfWidth, y + halfWidth, z - halfWidth, r, g, b)
    drawDebugLine(x + halfWidth, y - halfWidth, z - halfWidth, r, g, b, x + halfWidth, y + halfWidth, z - halfWidth, r, g, b)
    drawDebugLine(x + halfWidth, y - halfWidth, z - halfWidth, r, g, b, x + halfWidth, y - halfWidth, z + halfWidth, r, g, b)
    drawDebugPoint(x, y, z, r, g, b, 1)
end
function DebugUtil.drawDebugReferenceAxisFromNode(node)
    if node ~= nil then
        local x, y, z = getWorldTranslation(node)
        local yx, yy, yz = localDirectionToWorld(node, 0, 1, 0)
        local zx, zy, zz = localDirectionToWorld(node, 0, 0, 1)
        DebugUtil.drawDebugReferenceAxis(x, y, z, yx, yy, yz, zx, zy, zz)
    end
end
function DebugUtil.drawDebugReferenceAxis(posX, posY, posZ, upX, upY, upZ, dirX, dirY, dirZ)
    local sideX, sideY, sideZ = MathUtil.crossProduct(upX, upY, upZ, dirX, dirY, dirZ)
    drawDebugLine(posX - sideX * 0.2, posY - sideY * 0.2, posZ - sideZ * 0.2, 1, 1, 1, posX + sideX * 0.2, posY + sideY * 0.2, posZ + sideZ * 0.2, 1, 0, 0)
    drawDebugLine(posX - upX * 0.2, posY - upY * 0.2, posZ - upZ * 0.2, 1, 1, 1, posX + upX * 0.2, posY + upY * 0.2, posZ + upZ * 0.2, 0, 1, 0)
    drawDebugLine(posX - dirX * 0.2, posY - dirY * 0.2, posZ - dirZ * 0.2, 1, 1, 1, posX + dirX * 0.2, posY + dirY * 0.2, posZ + dirZ * 0.2, 0, 0, 1)
end
function DebugUtil.drawDebugParallelogram(x, z, widthX, widthZ, heightX, heightZ, heightOffset, r, g, b, a, fixedHeight)
    local y0 = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + heightOffset
    local x1 = x + widthX
    local z1 = z + widthZ
    local y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z1) + heightOffset
    local x2 = x + heightX
    local z2 = z + heightZ
    local y2 = getTerrainHeightAtWorldPos(g_terrainNode, x2, 0, z2) + heightOffset
    local x3 = x + widthX + heightX
    local z3 = z + widthZ + heightZ
    local y3 = getTerrainHeightAtWorldPos(g_terrainNode, x3, 0, z3) + heightOffset
    if fixedHeight then
        y3 = heightOffset
        y2 = y3
        y1 = y2
        y0 = y1
        y3 = y0
        y2 = y3
        y1 = y2
    end
    drawDebugTriangle(x, y0, z, x1, y1, z1, x2, y2, z2, r, g, b, a, false)
    drawDebugTriangle(x1, y1, z1, x3, y3, z3, x2, y2, z2, r, g, b, a, false)
    drawDebugTriangle(x, y0, z, x2, y2, z2, x1, y1, z1, r, g, b, a, false)
    drawDebugTriangle(x2, y2, z2, x3, y3, z3, x1, y1, z1, r, g, b, a, false)
    drawDebugLine(x, y0, z, r, g, b, x1, y1, z1, r, g, b)
    drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b)
    drawDebugLine(x2, y2, z2, r, g, b, x, y0, z, r, g, b)
    drawDebugLine(x1, y1, z1, r, g, b, x3, y3, z3, r, g, b)
    drawDebugLine(x3, y3, z3, r, g, b, x2, y2, z2, r, g, b)
end
function DebugUtil.drawDebugWorldParallelogram(x, z, widthX, widthZ, heightX, heightZ, heightOffset, r, g, b, a, fixedHeight)
    local y0 = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + heightOffset
    local y1 = getTerrainHeightAtWorldPos(g_terrainNode, widthX, 0, widthZ) + heightOffset
    local y2 = getTerrainHeightAtWorldPos(g_terrainNode, heightX, 0, heightZ) + heightOffset
    local x3 = x + (widthX - x) + (heightX - x)
    local z3 = z + (widthZ - z) + (heightZ - z)
    local y3 = getTerrainHeightAtWorldPos(g_terrainNode, x3, 0, z3) + heightOffset
    if fixedHeight then
        y2 = heightOffset
        y0 = y2
        y3 = y0
        y1 = y3
        y2 = y1
        y0 = y2
        y3 = y0
    end
    drawDebugTriangle(x, y0, z, widthX, y1, widthZ, heightX, y2, heightZ, r, g, b, a, false)
    drawDebugTriangle(widthX, y1, widthZ, x3, y3, z3, heightX, y2, heightZ, r, g, b, a, false)
    drawDebugTriangle(x, y0, z, heightX, y2, heightZ, widthX, y1, widthZ, r, g, b, a, false)
    drawDebugTriangle(heightX, y2, heightZ, x3, y3, z3, widthX, y1, widthZ, r, g, b, a, false)
    drawDebugLine(x, y0, z, r, g, b, widthX, y1, widthZ, r, g, b)
    drawDebugLine(widthX, y1, widthZ, r, g, b, heightX, y2, heightZ, r, g, b)
    drawDebugLine(heightX, y2, heightZ, r, g, b, x, y0, z, r, g, b)
    drawDebugLine(widthX, y1, widthZ, r, g, b, x3, y3, z3, r, g, b)
    drawDebugLine(x3, y3, z3, r, g, b, heightX, y2, heightZ, r, g, b)
end
function DebugUtil.drawArea(area, r, g, b, a)
    local x0, _, z0 = getWorldTranslation(area.start)
    local x1, _, z1 = getWorldTranslation(area.width)
    local x2, _, z2 = getWorldTranslation(area.height)
    local x, z, widthX, widthZ, heightX, heightZ = MathUtil.getXZWidthAndHeight(x0, z0, x1, z1, x2, z2)
    DebugUtil.drawDebugParallelogram(x, z, widthX, widthZ, heightX, heightZ, r, g, b, a)
end
function DebugUtil.drawCutNodeArea(node, sizeY, sizeZ, r, g, b)
    if node ~= nil then
        local x, y, z = getWorldTranslation(node)
        local x2, y2, z2 = localToWorld(node, 0, sizeY or 1, 0)
        local x3, y3, z3 = localToWorld(node, 0, 0, sizeZ or 1)
        DebugUtil.drawDebugAreaRectangle(x, y, z, x2, y2, z2, x3, y3, z3, false, r or 0, g or 1, b or 0)
    end
end
function DebugUtil.printTableRecursively(inputTable, inputIndent, depth, maxDepth)
    inputIndent = inputIndent or "  "
    depth = depth or 0
    maxDepth = maxDepth or 3
    if maxDepth >= depth then
        for i, j in pairs(inputTable) do
            print(inputIndent .. tostring(i) .. " :: " .. tostring(j))
            if type(j) == "table" then
                DebugUtil.printTableRecursively(j, inputIndent .. "    ", depth + 1, maxDepth)
            end
        end
        return ""
    end
end
function DebugUtil.debugTableToString(inputTable, inputIndent, depth, maxDepth)
    inputIndent = inputIndent or "  "
    depth = depth or 0
    maxDepth = maxDepth or 2
    if maxDepth < depth then
        return nil
    end
    local string1 = ""
    for i, j in pairs(inputTable) do
        string1 = string1 .. string.format("\n%s %s :: %s", inputIndent, tostring(i), (tostring(j)))
        if type(j) == "table" then
            local string2 = DebugUtil.debugTableToString(j, inputIndent .. "    ", depth + 1, maxDepth)
            if string2 ~= nil then
            end
        end
    end
    return string1
end
function DebugUtil.renderTable(posX, posY, textSize, data, nextColumnOffset)
    local i = 0
    setTextColor(1, 1, 1, 1)
    setTextBold(false)
    textSize = getCorrectTextSize(textSize)
    for _, valuePair in ipairs(data) do
        if valuePair.name ~= "" then
            setTextAlignment(RenderText.ALIGN_RIGHT)
            renderText(posX, posY - i * textSize * 1.05, textSize, tostring(valuePair.name) .. ":")
        end
        setTextAlignment(RenderText.ALIGN_LEFT)
        if type(valuePair.value) == "number" then
            renderText(posX, posY - offset, textSize, " " .. string.format("%.4f", valuePair.value))
        else
            renderText(posX, posY - offset, textSize, " " .. tostring(valuePair.value))
        end
        i = i + 1
        if valuePair.newColumn or valuePair.columnOffset then
            i = 0
        end
    end
end
function DebugUtil.printListAsTriples(list)
    local i = 1
    for i = i, #list, 3 do
        log(list[i], list[i + 1], list[i + 2])
    end
end
function DebugUtil.renderTextLine(x, y, textSize, text, spacingScalar, isBold, color)
    setTextBold(isBold or false)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor((color or Color.PRESETS.WHITE):unpack())
    renderText(x, y, textSize, text)
    return DebugUtil.renderNewLine(y, textSize, spacingScalar)
end
function DebugUtil.renderNewLine(y, textSize, spacingScalar)
    return y - textSize * (spacingScalar or DebugUtil.DEFAULT_RENDERLINE_SCALAR)
end
function DebugUtil.printNodeHierarchy(node, offset, appendType)
    offset = offset or ""
    if appendType then
        local classText = ""
        for className, classId in pairs(ClassIds) do
            if getHasClassId(node, classId) then
            end
        end
        if not string.isNilOrWhitespace(classText) then
            classText = string.sub(classText, 1, #classText - 3)
        end
        log(string.format("%s%s (%s)", offset, getName(node), classText))
    else
        log(string.format("%s%s", offset, getName(node)))
    end
    local i = 0
    local classText = getNumOfChildren(node) - 1
    for i = i, classText do
        DebugUtil.printNodeHierarchy(getChildAt(node, i), offset .. " ", appendType)
    end
end
function DebugUtil.printCallingFunctionLocation()
    local callerScript, callerLine = debug.info(3, "sl")
    print(string.format("%s, line %d", tostring(callerScript), callerLine))
end
function DebugUtil.tableToColor(tbl, alpha)
    local tableIdHex = tostring(tbl):sub(10)
    return Color.new((tonumber(tableIdHex:sub(-2), 16) or 255) / 255, (tonumber(tableIdHex:sub(-4, -3), 16) or 255) / 255, (tonumber(tableIdHex:sub(-6, -5), 16) or 255) / 255, alpha or 1)
end
function DebugUtil.getDebugColor(index)
    index = tonumber(index) or math.random(#DebugUtil.COLORS)
    return DebugUtil.COLORS[(index - 1) % #DebugUtil.COLORS + 1]
end
function DebugUtil.isNodeInCameraRange(node, distance, camera)
    return calcDistanceFrom(node, camera or g_cameraManager:getActiveCamera()) < (distance or math.huge)
end
function DebugUtil.isPositionInCameraRange(x, y, z, distance, camera)
    if distance == nil then
        return true
    end
    local camX, camY, camZ = getWorldTranslation(camera or g_cameraManager:getActiveCamera())
    return MathUtil.vector3Length(x - camX, y and y - camY or 0, z - camZ) < distance
end
function DebugUtil.setNodeEffectivelyVisible(node)
    setVisibility(node, true)
    local parent = getParent(node)
    while parent ~= 0 do
        setVisibility(parent, true)
        parent = getParent(parent)
    end
end
function DebugUtil.getYRotatationToCamera(x, y, z)
    local cx, cy, cz = getWorldTranslation(g_cameraManager:getActiveCamera())
    local dirX, _, dirZ = MathUtil.vector3Normalize(cx - x, cy - y, cz - z)
    return MathUtil.getYRotationFromDirection(dirX, dirZ)
end
function DebugUtil.getLuaMemory(differenceTo)
    collectgarbage("collect")
    return collectgarbage("count") - (differenceTo or 0)
end