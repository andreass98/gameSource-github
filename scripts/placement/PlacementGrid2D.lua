PlacementGrid2D = {}
PlacementGrid2D.MODE_SIDES = 0
PlacementGrid2D.MODE_FILL = 1
PlacementGrid2D.EPSILON = 0.01
local PlacementGrid2D_mt = Class(PlacementGrid2D)
function PlacementGrid2D.new(node, width, length, spacing, mode)
    -- upvalues: (copy) PlacementGrid2D_mt
    local self = setmetatable({}, PlacementGrid2D_mt)
    self.node = node
    self.width = width
    self.length = length
    self.spacing = spacing
    self.placementMode = mode or PlacementGrid2D.MODE_SIDES
    self.blockedAreas = {}
    self.lowerPos = {
        ["x"] = 0,
        ["z"] = 0,
        ["isValid"] = false
    }
    self.upperPos = {
        ["x"] = 0,
        ["z"] = 0,
        ["isValid"] = false
    }
    return self
end
function PlacementGrid2D:delete() end
function PlacementGrid2D:reset()
    self.blockedAreas = {}
end
function PlacementGrid2D:getFreePosition(width, length)
    self.lowerPos.isValid = false
    self.upperPos.isValid = false
    local foundPosX = nil
    local foundPosZ = nil
    local steps = math.floor(self.length / self.spacing)
    local i = 0
    for i = i, steps do
        local blockedArea = self.blockedAreas[i]
        local minX = self.width
        local maxX = 0
        local lowerSpace = self.width
        local upperSpace = self.width
        if blockedArea ~= nil then
            minX = blockedArea.minX
            maxX = blockedArea.maxX
            lowerSpace = blockedArea.minX
            upperSpace = self.width - blockedArea.maxX
        end
        if self.lowerPos.isValid then
            if width - lowerSpace < PlacementGrid2D.EPSILON then
                if self.placementMode == PlacementGrid2D.MODE_FILL then
                    self.lowerPos.x = math.min(self.lowerPos.x, minX - width)
                end
                if length <= i * self.spacing + self.spacing - self.lowerPos.z then
                    foundPosX = self.lowerPos.x
                    foundPosZ = self.lowerPos.z
                    break
                end
            else
                self.lowerPos.isValid = false
            end
        elseif width - lowerSpace < 0.01 then
            self.lowerPos.isValid = true
            self.lowerPos.z = offsetZ
            if self.placementMode == PlacementGrid2D.MODE_SIDES then
                self.lowerPos.x = 0
            else
                self.lowerPos.x = minX - width
            end
        end
        if self.upperPos.isValid then
            if width - upperSpace < 0.01 then
                if self.placementMode == PlacementGrid2D.MODE_FILL then
                    self.upperPos.x = math.max(self.upperPos.x, maxX)
                end
                if length <= offsetZ + self.spacing - self.upperPos.z then
                    foundPosX = self.upperPos.x
                    foundPosZ = self.upperPos.z
                    break
                end
            else
                self.upperPos.isValid = false
            end
        elseif width - upperSpace < PlacementGrid2D.EPSILON then
            self.upperPos.isValid = true
            self.upperPos.z = offsetZ
            if self.placementMode == PlacementGrid2D.MODE_SIDES then
                self.upperPos.x = self.width - width
            else
                self.upperPos.x = maxX
            end
        end
    end
    if foundPosX == nil then
        return nil, nil
    else
        return foundPosX, foundPosZ
    end
end
function PlacementGrid2D:blockAreaLocal(minX, minZ, width, length)
    self:updateBlockedArea(minX, minX + width, minZ, minZ + length)
end
function PlacementGrid2D:blockAreaByBoundingBox(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, extendX, extendY, extendZ)
    local x1, _, z1 = worldToLocal(self.node, MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, -extendX, -extendY, -extendZ))
    local x2, _, z2 = worldToLocal(self.node, MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, extendX, -extendY, -extendZ))
    local x3, _, z3 = worldToLocal(self.node, MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, extendX, -extendY, extendZ))
    local x4, _, z4 = worldToLocal(self.node, MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, -extendX, -extendY, extendZ))
    local x5, _, z5 = worldToLocal(self.node, MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, -extendX, extendY, -extendZ))
    local x6, _, z6 = worldToLocal(self.node, MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, extendX, extendY, -extendZ))
    local x7, _, z7 = worldToLocal(self.node, MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, extendX, extendY, extendZ))
    local x8, _, z8 = worldToLocal(self.node, MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, -extendX, extendY, extendZ))
    local minX = math.max(0, (math.min(x1, x2, x3, x4, x5, x6, x7, x8)))
    local maxZ = math.max(x1, x2, x3, x4, x5, x6, x7, x8)
    local maxX = math.min(self.width, maxZ)
    self:updateBlockedArea(minX, maxX, math.max(0, (math.min(z1, z2, z3, z4, z5, z6, z7, z8))), (math.min(self.length, (math.max(z1, z2, z3, z4, z5, z6, z7, z8)))))
end
function PlacementGrid2D:updateBlockedArea(minX, maxX, minZ, maxZ)
    local startIndex = math.max(1, (math.ceil(minZ / self.spacing)))
    local endIndex = math.max(0, (math.ceil(maxZ / self.spacing)))
    for startIndex = startIndex, endIndex do
        local blockedArea = self.blockedAreas[startIndex]
        if blockedArea == nil then
            local zStart = (startIndex - 1) * self.spacing
            local zEnd = startIndex * self.spacing
            self.blockedAreas[startIndex] = {
                ["minX"] = self.width,
                ["maxX"] = 0,
                ["zStart"] = zStart,
                ["zEnd"] = zEnd,
                ["offsetZ"] = (zStart + zEnd) * 0.5
            }
        end
        local zEnd = blockedArea.minX
        blockedArea.minX = math.min(zEnd, minX)
        local zEnd = blockedArea.maxX
        blockedArea.maxX = math.max(zEnd, maxX)
    end
end
function PlacementGrid2D:drawDebug()
    local x1, y1, z1 = localToWorld(self.node, 0, 0, 0)
    local x2, y2, z2 = localToWorld(self.node, self.width, 0, 0)
    local x3, y3, z3 = localToWorld(self.node, self.width, 0, self.length)
    local x4, y4, z4 = localToWorld(self.node, 0, 0, self.length)
    drawDebugLine(x1, y1, z1, 1, 1, 1, x2, y2, z2, 1, 1, 1)
    drawDebugLine(x2, y2, z2, 1, 1, 1, x3, y3, z3, 1, 1, 1)
    drawDebugLine(x3, y3, z3, 1, 1, 1, x4, y4, z4, 1, 1, 1)
    drawDebugLine(x4, y4, z4, 1, 1, 1, x1, y1, z1, 1, 1, 1)
    for _, blockedArea in pairs(self.blockedAreas) do
        local sx1, sy1, sz1 = localToWorld(self.node, blockedArea.minX, 0, blockedArea.offsetZ)
        local sx2, sy2, sz2 = localToWorld(self.node, blockedArea.maxX, 0, blockedArea.offsetZ)
        if blockedArea.maxX > blockedArea.minX then
            local csx1, csy1, csz1 = localToWorld(self.node, blockedArea.minX, 0, blockedArea.zStart)
            local csx2, csy2, csz2 = localToWorld(self.node, blockedArea.maxX, 0, blockedArea.zStart)
            drawDebugLine(csx1, csy1, csz1, 1, 1, 1, csx2, csy2, csz2, 1, 1, 1)
            local cex1, cey1, cez1 = localToWorld(self.node, blockedArea.minX, 0, blockedArea.zEnd)
            local cex2, cey2, cez2 = localToWorld(self.node, blockedArea.maxX, 0, blockedArea.zEnd)
            drawDebugLine(cex1, cey1, cez1, 1, 1, 1, cex2, cey2, cez2, 1, 1, 1)
            drawDebugLine(sx1, sy1, sz1, 1, 0, 0, sx2, sy2, sz2, 1, 0, 0)
        end
    end
end