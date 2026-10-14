AIMessageErrorOutOfFill = {}
local AIMessageErrorOutOfFill_mt = Class(AIMessageErrorOutOfFill, AIMessage)
function AIMessageErrorOutOfFill.new(customMt)
    -- upvalues: (copy) AIMessageErrorOutOfFill_mt
    return AIMessage.new(customMt or AIMessageErrorOutOfFill_mt)
end
function AIMessageErrorOutOfFill:getI18NText()
    return g_i18n:getText("ai_messageErrorOutOfFill")
end