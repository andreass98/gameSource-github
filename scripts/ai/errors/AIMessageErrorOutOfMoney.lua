AIMessageErrorOutOfMoney = {}
local AIMessageErrorOutOfMoney_mt = Class(AIMessageErrorOutOfMoney, AIMessage)
function AIMessageErrorOutOfMoney.new(customMt)
    -- upvalues: (copy) AIMessageErrorOutOfMoney_mt
    return AIMessage.new(customMt or AIMessageErrorOutOfMoney_mt)
end
function AIMessageErrorOutOfMoney:getI18NText()
    return g_i18n:getText("ai_messageErrorOutOfMoney")
end