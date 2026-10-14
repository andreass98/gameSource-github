TerrainLayerElement = {}
local TerrainLayerElement_mt = Class(TerrainLayerElement, GuiElement)
Gui.registerGuiElement("TerrainLayer", TerrainLayerElement)
function TerrainLayerElement.new(target, custom_mt)
    -- upvalues: (copy) TerrainLayerElement_mt
    local self = TerrainLayerElement:superClass().new(target, custom_mt or TerrainLayerElement_mt)
    self.terrainLayerTextureOverlay = nil
    return self
end
function TerrainLayerElement:delete()
    self:destroyOverlay(self.terrainRootNode)
    TerrainLayerElement:superClass().delete(self)
end
function TerrainLayerElement:copyAttributes(src)
    TerrainLayerElement:superClass().copyAttributes(self, src)
    self:setTerrainLayer(src.terrainRootNode, src.layer)
end
function TerrainLayerElement:setTerrainLayer(terrainRootNode, layer)
    if layer ~= nil then
        if self.terrainLayerTextureOverlay == nil then
            self:createOverlay(terrainRootNode)
        end
        local displayLayer = getTerrainLayerSubLayer(terrainRootNode, layer, 0)
        setOverlayLayer(self.terrainLayerTextureOverlay, displayLayer)
        self.layer = layer
    end
end
function TerrainLayerElement:createOverlay(terrainRootNode)
    self.terrainRootNode = terrainRootNode
    local terrainLayerTexture = createTerrainLayerTexture(g_terrainNode)
    self.terrainLayerTextureOverlay = createImageOverlayWithTexture(terrainLayerTexture)
    delete(terrainLayerTexture)
end
function TerrainLayerElement:destroyOverlay(terrainRootNode)
    if self.terrainRootNode ~= nil and self.terrainRootNode == terrainRootNode then
        if self.terrainLayerTextureOverlay ~= nil then
            delete(self.terrainLayerTextureOverlay)
            self.terrainLayerTextureOverlay = nil
        end
        self.terrainRootNode = nil
    end
end
function TerrainLayerElement:draw(clipX1, clipY1, clipX2, clipY2)
    if self.terrainLayerTextureOverlay ~= nil then
        local sizeX = self.size[1]
        local sizeY = self.size[2]
        local u1 = 0
        local v1 = 0
        local u2 = 0
        local v2 = 1
        local u3 = 1
        local v3 = 0
        local u4 = 1
        local v4 = 1
        local p1, p1
        if clipX1 == nil then
            p1 = self.absPosition[1]
            p1 = self.absPosition[2]
        else
            local oldX2 = sizeX + posX
            local oldY2 = sizeY + posY
            p1 = math.max(posX, clipX1)
            p1 = math.max(posY, clipY1)
            local p2 = math.min(posX + sizeX, clipX2) - p1
            sizeX = math.max(p2, 0)
            local p2 = math.min(posY + sizeY, clipY2) - p1
            sizeY = math.max(p2, 0)
            u2 = (p1 - posX) / (oldX2 - posX)
            u3 = (p1 + sizeX - posX) / (oldX2 - posX)
            v2 = (p1 + sizeY - posY) / (oldY2 - posY)
            v1 = (p1 - posY) / (oldY2 - posY)
        end
        if u1 ~= u3 and v1 ~= v2 then
            setOverlayUVs(self.terrainLayerTextureOverlay, u1, v1, u2, v2, u3, v3, u4, v4)
            renderOverlay(self.terrainLayerTextureOverlay, p1, p1, sizeX, sizeY)
        end
        TerrainLayerElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
    end
end
function TerrainLayerElement:canReceiveFocus()
    if not self.visible or #self.elements < 1 then
        return false
    end
    for _, v in ipairs(self.elements) do
        if not v:canReceiveFocus() then
            return false
        end
    end
    return true
end
function TerrainLayerElement:getFocusTarget()
    if #self.elements > 0 then
        local _, firstElement = next(self.elements)
        if firstElement then
            return firstElement
        end
    end
    return self
end
function TerrainLayerElement:reset()
    self:destroyOverlay(self.terrainRootNode)
end