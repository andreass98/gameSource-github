AIMessageErrorUnknown = {}
local AIMessageErrorUnknown_mt = Class(AIMessageErrorUnknown, AIMessage)
function AIMessageErrorUnknown.new(customMt)
    -- upvalues: (copy) AIMessageErrorUnknown_mt
    return AIMessage.new(customMt or AIMessageErrorUnknown_mt)
end
function AIMessageErrorUnknown:getI18NText()
    return g_i18n:getText("ai_messageErrorUnknown")
end