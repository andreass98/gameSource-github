NodeCache = {}
local NodeCache_mt = Class(NodeCache)
function NodeCache.new(customMt)
    -- upvalues: (copy) NodeCache_mt
    local self = setmetatable({}, customMt or NodeCache_mt)
    self.templateNodes = {}
    self.cloneToTemplateIndex = {}
    self.templateIndexToBuffer = {}
    return self
end
function NodeCache:addTemplate(node)
    if table.hasElement(self.templateNodes, node) then
        Logging.error("NodeCache:addTemplate: Node %q (%d) already present in templates", getName(node), node)
        return
    elseif entityExists(node) then
        if getParent(node) == 0 then
            table.insert(self.templateNodes, node)
            local templateIndex = #self.templateNodes
            self.templateIndexToBuffer[templateIndex] = {}
            return templateIndex
        end
        Logging.error("NodeCache:addTemplate: Node %q (%d) is still linked", getName(node), node)
    else
        Logging.error("NodeCache:addTemplate: entity %d does not exist", node)
    end
end
function NodeCache:getNodeInstance(templateIndex)
    if #self.templateNodes < templateIndex then
        Logging.error("templateIndex %d out of bounds, only %d template node registered", templateIndex, #self.templateNodes)
        return nil
    end
    if #self.templateIndexToBuffer[templateIndex] > 0 then
        return table.remove(self.templateIndexToBuffer[templateIndex])
    end
    local clonedNode = clone(self.templateNodes[templateIndex], false, false, false)
    self.cloneToTemplateIndex[clonedNode] = templateIndex
    return clonedNode
end
function NodeCache:returnNodeToCache(node)
    if entityExists(node) then
        local templateIndex = self.cloneToTemplateIndex[node]
        if templateIndex == nil then
            Logging.error("NodeCache:returnNodeToCache: Node %q (%d) is not a clone of a template", getName(node), node)
            return
        elseif getParent(node) == 0 then
            table.insert(self.templateIndexToBuffer[templateIndex], node)
        else
            Logging.error("NodeCache:returnNodeInstanceToBuffer: Node %q (%d) is still linked", getName(node), node)
        end
    else
        Logging.error("NodeCache:returnNodeToCache: entity %d does not exist", node)
        return
    end
end
function NodeCache:empty()
    for meshIndex, buffer in ipairs(self.templateIndexToBuffer) do
        for _, mesh in ipairs(buffer) do
            delete(mesh)
        end
        table.clear(buffer)
    end
    table.clear(self.cloneToTemplateIndex)
end
function NodeCache:delete()
    self:empty()
    for _, templateNode in ipairs(self.templateNodes) do
        delete(templateNode)
    end
    table.clear(self.templateNodes)
end
function NodeCache:drawDebug(screenX, screenY)
    screenX = screenX or 0.02
    screenY = screenY or 0.8
    setTextColor(1, 1, 1, 1)
    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_LEFT)
    renderText(screenX, screenY, 0.015, "NodeCache")
    for index, templateNode in ipairs(self.templateNodes) do
        renderText(screenX, screenY - index * 0.015, 0.015, string.format("%s: %d", getName(templateNode), #self.templateIndexToBuffer[index]))
    end
end