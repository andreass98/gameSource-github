Ladders = {}
function Ladders.prerequisitesPresent(specializations)
    return true
end
function Ladders.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Ladders)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Ladders)
end
function Ladders.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Ladders")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".ladders.ladder(?)#triggerNode", "Ladder trigger node for player")
    schema:setXMLSpecializationType()
end
function Ladders:onLoad(_)
    for _, key in self.xmlFile:iterator("vehicle.ladders.ladder") do
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
function Ladders:onDelete()
    local spec = self.spec_ladders
    if spec.ladderTriggers ~= nil then
        for _, ladderTrigger in ipairs(spec.ladderTriggers) do
            ladderTrigger:delete()
        end
    end
end