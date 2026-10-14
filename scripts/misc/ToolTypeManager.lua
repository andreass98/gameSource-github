ToolType = nil
ToolTypeManager = {}
local ToolTypeManager_mt = Class(ToolTypeManager, AbstractManager)
function ToolTypeManager.new(customMt)
    -- upvalues: (copy) ToolTypeManager_mt
    return AbstractManager.new(customMt or ToolTypeManager_mt)
end
function ToolTypeManager:initDataStructures()
    self.indexToName = {}
    self.nameToInt = {}
    ToolType = self.nameToInt
end
function ToolTypeManager:loadMapData()
    ToolTypeManager:superClass().loadMapData(self)
    self:addToolType("undefined")
    self:addToolType("dischargeable")
    self:addToolType("pallet")
    self:addToolType("trigger")
    self:addToolType("bale")
    return true
end
function ToolTypeManager:addToolType(name)
    name = string.upper(name)
    if ClassUtil.getIsValidIndexName(name) then
        if ToolType[name] == nil then
            table.insert(self.indexToName, name)
            self.nameToInt[name] = #self.indexToName
        end
        return ToolType[name]
    else
        printWarning("Warning: \'" .. tostring(name) .. "\' is not a valid name for a toolType. Ignoring toolType!")
        return nil
    end
end
function ToolTypeManager:getToolTypeNameByIndex(index)
    return self.indexToName[index] == nil and "UNDEFINED" or self.indexToName[index]
end
function ToolTypeManager:getToolTypeIndexByName(name)
    name = string.upper(name)
    if self.nameToInt[name] == nil then
        return ToolType.UNDEFINED
    else
        return self.nameToInt[name]
    end
end
function ToolTypeManager:getNumberOfToolTypes()
    return #self.indexToName
end
g_toolTypeManager = ToolTypeManager.new()