Line3D = {}
Line3D.VISUALS_FILENAME = "data/shared/visualization/line.i3d"
local Line3D_mt = Class(Line3D)
function Line3D.new(customMt)
    -- upvalues: (copy) Line3D_mt
    local self = setmetatable({}, customMt or Line3D_mt)
    self.visNodes = createTransformGroup("line3DVisualizationShapes")
    link(getRootNode(), self.visNodes)
    self.nodeCache = NodeCache.new()
    self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(Line3D.VISUALS_FILENAME, false, false, Line3D.onVisualsLoaded, self)
    return self
end
function Line3D:onVisualsLoaded(i3dNode)
    if i3dNode ~= nil then
        local line = getChildAt(i3dNode, 0)
        unlink(line)
        self.nodeCache:addTemplate(line)
        delete(i3dNode)
    end
end
function Line3D:delete()
    if self.visNodes ~= nil then
        delete(self.visNodes)
        self.visNodes = nil
    end
    if self.nodeCache ~= nil then
        self.nodeCache:delete()
        self.nodeCache = nil
    end
    if self.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
        self.sharedLoadRequestId = nil
    end
end
function Line3D:visualizeLine(sx, sy, sz, ex, ey, ez, alignToTerrain, color)
    local currentNode = MathUtil.vector3Length(ex - sx, ey - sy, ez - sz)
    local len = math.round(currentNode)
    if len ~= 0 then
        local currentNode = self.nodeCache:getNodeInstance(1)
        link(self.visNodes, currentNode)
        local shape = getChildAt(currentNode, 0)
        setShapeBoundingSphere(shape, 0, 0, 0, 60)
        local r = nil
        local g = nil
        local b = nil
        if color ~= nil then
            r, g, b = color:unpack()
            setShaderParameter(shape, "emitColor", r, g, b, 1, false)
        end
        local currentBoneIndex = 0
        local numBones = getNumOfChildren(currentNode)
        local prevBone = nil
        local firstBone = getChildAt(currentNode, 0)
        local x = nil
        local y = nil
        local z = nil
        local step = 0
        local py = 1
        for step = step, len, py do
            if alignToTerrain then
                x, z = MathUtil.vector2Lerp(sx, sz, ex, ez, step / len)
                y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.05
            else
                x, y, z = MathUtil.vector3Lerp(sx, sy, sz, ex, ey, ez, step / len)
            end
            local currentBone = getChildAt(currentNode, currentBoneIndex)
            setWorldTranslation(currentBone, x, y, z)
            setVisibility(currentBone, true)
            if prevBone ~= nil then
                local px, py, pz = getWorldTranslation(prevBone)
                local sDirX, sDirY, sDirZ = MathUtil.vector3Normalize(x - px, y - py, z - pz)
                setDirection(prevBone, sDirX, sDirY, sDirZ, 0, 1, 0)
            end
            currentBoneIndex = currentBoneIndex + 1
            if numBones <= currentBoneIndex then
                currentNode = self.nodeCache:getNodeInstance(1)
                link(self.visNodes, currentNode)
                local px = getChildAt(currentNode, 0)
                if r ~= nil then
                    setShaderParameter(px, "emitColor", r, g, b, 1, false)
                end
                setShapeBoundingSphere(px, 0, 0, 0, numBones)
                currentBoneIndex = 0
                prevBone = currentBone
            else
                prevBone = currentBone
            end
        end
        if prevBone ~= nil and firstBone ~= prevBone then
            local px, py, step = getWorldTranslation(firstBone)
            local currentBone, px, py = MathUtil.vector3Normalize(px - x, py - y, step - z)
            setDirection(prevBone, currentBone, px, py, 0, 1, 0)
        end
        local px = numBones - 1
        local py = 1
        for currentBoneIndex = currentBoneIndex, px, py do
            setVisibility(getChildAt(currentNode, currentBoneIndex), false)
        end
    end
end
function Line3D:clearVisualization()
    if self.visNodes ~= nil then
        local numChildren = getNumOfChildren(self.visNodes)
        if numChildren ~= 0 then
            local i = numChildren - 1
            for i = i, 0, -1 do
                local child = getChildAt(self.visNodes, i)
                unlink(child)
                self.nodeCache:returnNodeToCache(child)
            end
        end
    end
end