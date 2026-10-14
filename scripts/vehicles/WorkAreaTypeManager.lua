WorkAreaTypeManager = {}
WorkAreaType = nil
local WorkAreaTypeManager_mt = Class(WorkAreaTypeManager, AbstractManager)
function WorkAreaTypeManager.new(customMt)
    -- upvalues: (copy) WorkAreaTypeManager_mt
    return AbstractManager.new(customMt or WorkAreaTypeManager_mt)
end
function WorkAreaTypeManager:initDataStructures()
    self.workAreaTypes = {}
    self.workAreaTypeNameToInt = {}
    self.workAreaTypeNameToDesc = {}
    WorkAreaType = self.workAreaTypeNameToInt
end
function WorkAreaTypeManager:addWorkAreaType(name, attractWildlife, isAIArea, isSteeringAssistArea)
    if name == nil then
        Logging.error("WorkArea name missing!")
        return
    elseif self.workAreaTypeNameToInt[name] == nil then
        local entry = string.upper(name)
        local entry = {
            ["name"] = entry,
            ["index"] = #self.workAreaTypes + 1,
            ["attractWildlife"] = Utils.getNoNil(attractWildlife, false),
            ["isAIArea"] = Utils.getNoNil(isAIArea, false),
            ["isSteeringAssistArea"] = Utils.getNoNil(isSteeringAssistArea, false)
        }
        self.workAreaTypeNameToInt[entry] = entry.index
        self.workAreaTypeNameToDesc[entry] = entry
        table.insert(self.workAreaTypes, entry)
        print("  Register workAreaType \'" .. entry .. "\'")
    else
        Logging.error("WorkArea name \'%s\' is already in use!", name)
    end
end
function WorkAreaTypeManager:getWorkAreaTypeNameByIndex(index)
    local workAreaType = self.workAreaTypes[index]
    if workAreaType then
        return workAreaType.name
    else
        return nil
    end
end
function WorkAreaTypeManager:getWorkAreaTypeIndexByName(name)
    if name == nil then
        return nil
    else
        return self.workAreaTypeNameToInt[string.upper(name)]
    end
end
function WorkAreaTypeManager:getConfigurationDescByName(name)
    if name == nil then
        return nil
    else
        return self.workAreaTypeNameToDesc[string.upper(name)]
    end
end
function WorkAreaTypeManager:getWorkAreaTypeByIndex(index)
    return self.workAreaTypes[index]
end
function WorkAreaTypeManager:getWorkAreaTypeIsAIArea(index)
    if self.workAreaTypes[index] == nil then
        return false
    else
        return self.workAreaTypes[index].isAIArea
    end
end
function WorkAreaTypeManager:getWorkAreaTypeIsSteeringAssistArea(index)
    if self.workAreaTypes[index] == nil then
        return false
    else
        return self.workAreaTypes[index].isSteeringAssistArea
    end
end
g_workAreaTypeManager = WorkAreaTypeManager.new()