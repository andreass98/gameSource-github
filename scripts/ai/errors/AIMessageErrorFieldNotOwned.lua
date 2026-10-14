AIMessageErrorFieldNotOwned = {}
local AIMessageErrorFieldNotOwned_mt = Class(AIMessageErrorFieldNotOwned, AIMessage)
function AIMessageErrorFieldNotOwned.new(customMt)
    -- upvalues: (copy) AIMessageErrorFieldNotOwned_mt
    return AIMessage.new(customMt or AIMessageErrorFieldNotOwned_mt)
end
function AIMessageErrorFieldNotOwned:getI18NText()
    return g_i18n:getText("ai_messageErrorFieldNotOwned")
end