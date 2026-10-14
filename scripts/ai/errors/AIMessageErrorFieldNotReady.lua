AIMessageErrorFieldNotReady = {}
local AIMessageErrorFieldNotReady_mt = Class(AIMessageErrorFieldNotReady, AIMessage)
function AIMessageErrorFieldNotReady.new(customMt)
    -- upvalues: (copy) AIMessageErrorFieldNotReady_mt
    return AIMessage.new(customMt or AIMessageErrorFieldNotReady_mt)
end
function AIMessageErrorFieldNotReady:getI18NText()
    return g_i18n:getText("ai_messageErrorFieldNotReady")
end