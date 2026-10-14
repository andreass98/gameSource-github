ConversationInputData = {}
local ConversationInputData_mt = Class(ConversationInputData)
function ConversationInputData.new(customMt)
    -- upvalues: (copy) ConversationInputData_mt
    local self = setmetatable({}, customMt or ConversationInputData_mt)
    self:reset()
    return self
end
function ConversationInputData:delete()
    self:reset()
end
function ConversationInputData:reset()
    self.inputData = {}
end
function ConversationInputData:setData(name, value)
    self.inputData[name] = value
end
function ConversationInputData:getData(name)
    return self.inputData[name]
end