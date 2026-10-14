AIMessageErrorBlockedByObject = {}
local AIMessageErrorBlockedByObject_mt = Class(AIMessageErrorBlockedByObject, AIMessage)
function AIMessageErrorBlockedByObject.new(customMt)
    -- upvalues: (copy) AIMessageErrorBlockedByObject_mt
    return AIMessage.new(customMt or AIMessageErrorBlockedByObject_mt)
end
function AIMessage:getI18NText()
    return g_i18n:getText("ai_messageErrorBlockedByObject")
end