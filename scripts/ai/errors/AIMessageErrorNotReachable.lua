AIMessageErrorNotReachable = {}
local AIMessageErrorNotReachable_mt = Class(AIMessageErrorNotReachable, AIMessage)
function AIMessageErrorNotReachable.new(customMt)
    -- upvalues: (copy) AIMessageErrorNotReachable_mt
    return AIMessage.new(customMt or AIMessageErrorNotReachable_mt)
end
function AIMessageErrorNotReachable:getI18NText()
    return g_i18n:getText("ai_messageErrorNotReachable")
end