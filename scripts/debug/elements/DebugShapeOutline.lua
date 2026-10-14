DebugShapeOutline = {}
local DebugShapeOutline_mt = Class(DebugShapeOutline, DebugElement)
function DebugShapeOutline.new(customMt)
    -- upvalues: (copy) DebugShapeOutline_mt
    local self = DebugShapeOutline:superClass().new(customMt or DebugShapeOutline_mt)
    self.node = nil
    return self
end
function DebugShapeOutline:draw()
    DebugShapeOutline.render(self.node, self.recursive)
end
function DebugShapeOutline:createWithNode(node, recursive)
    self.node = node
    self.recursive = recursive
    return self
end
function DebugShapeOutline.render(node, recursive)
    if entityExists(node) then
        I3DUtil.iterateRecursively(node, function(iteratingNode)
            -- upvalues: (copy) recursive
            if not getHasClassId(iteratingNode, ClassIds.SHAPE) or getIsNonRenderable(iteratingNode) then
                return true
            end
            renderShapeOutline(iteratingNode, false)
            return recursive and true or false
        end, true)
    end
end
function DebugShapeOutline.setOutlineColor(color)
    if color ~= nil then
        setOutlineColor(color:unpack())
    end
end