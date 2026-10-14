AIMessageErrorPalletsFull = {}
local AIMessageErrorPalletsFull_mt = Class(AIMessageErrorPalletsFull, AIMessage)
function AIMessageErrorPalletsFull.new(customMt)
    -- upvalues: (copy) AIMessageErrorPalletsFull_mt
    return AIMessage.new(customMt or AIMessageErrorPalletsFull_mt)
end
function AIMessageErrorPalletsFull:getI18NText()
    return g_i18n:getText("ai_messageErrorPalletsFull")
end
function AIMessageErrorPalletsFull:getType()
    return AIMessageType.ERROR
end