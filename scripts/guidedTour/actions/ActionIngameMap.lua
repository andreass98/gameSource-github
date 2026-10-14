ActionIngameMap = {}
ActionIngameMap.NAME = "ingameMap"
local ActionIngameMap_mt = Class(ActionIngameMap)
function ActionIngameMap.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#state", "Name of the state", nil, true)
end
function ActionIngameMap.new(ingameMapState, customMt)
    -- upvalues: (copy) ActionIngameMap_mt
    local self = setmetatable({}, customMt or ActionIngameMap_mt)
    self.ingameMapState = ingameMapState
    return self
end
function ActionIngameMap:run(_, _)
    g_currentMission.hud:getIngameMap():toggleSize(self.ingameMapState, true)
    return true
end
function ActionIngameMap.createFromXML(xmlFile, key, _, _)
    local stateName = xmlFile:getValue(key .. "#state")
    local ingameMapState = IngameMapState.getByName(stateName)
    if ingameMapState == nil then
        return nil
    else
        return ActionIngameMap.new(ingameMapState)
    end
end
g_guidedTourManager:registerActionClass(ActionIngameMap.NAME, ActionIngameMap)