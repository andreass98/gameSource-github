PlaceableLadders = {}
function PlaceableLadders.prerequisitesPresent(specializations)
    return true
end
function PlaceableLadders.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableLadders)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableLadders)
end
function PlaceableLadders.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableLadders.collectPickObjects)
end
function PlaceableLadders.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Ladders")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".ladders.ladder(?)#triggerNode", "Ladder trigger node for player")
    schema:setXMLSpecializationType()
end
function PlaceableLadders:onLoad(_)
    for _, key in self.xmlFile:iterator("placeable.ladders.ladder") do
        local triggerNode = self.xmlFile:getNode(key .. "#triggerNode", nil, self.components, self.i3dMappings)
        if triggerNode ~= nil then
            if self.spec_ladders.ladderTriggers == nil then
                spec.ladderTriggers = {}
            end
            local ladderTrigger = LadderTrigger.new(triggerNode)
            table.insert(spec.ladderTriggers, ladderTrigger)
        end
    end
end
function PlaceableLadders:onDelete()
    local spec = self.spec_ladders
    if spec.ladderTriggers ~= nil then
        for _, ladderTrigger in ipairs(spec.ladderTriggers) do
            ladderTrigger:delete()
        end
    end
end
function PlaceableLadders:collectPickObjects(superFunc, node)
    local spec = self.spec_ladders
    local foundNode = false
    if spec.ladderTriggers ~= nil then
        for _, ladderTrigger in ipairs(spec.ladderTriggers) do
            if node == ladderTrigger.node then
                foundNode = true
                break
            end
        end
    end
    if not foundNode then
        superFunc(self, node)
    end
end