AIMessageErrorVineyardNotSupported = {}
local AIMessageErrorVineyardNotSupported_mt = Class(AIMessageErrorVineyardNotSupported, AIMessage)
function AIMessageErrorVineyardNotSupported.new(customMt)
    -- upvalues: (copy) AIMessageErrorVineyardNotSupported_mt
    return AIMessage.new(customMt or AIMessageErrorVineyardNotSupported_mt)
end
function AIMessageErrorVineyardNotSupported:getI18NText()
    return g_i18n:getText("ai_messageErrorVineyardNotSupported")
end