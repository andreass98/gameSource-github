AIMessageErrorImplementWrongWay = {}
local AIMessageErrorImplementWrongWay_mt = Class(AIMessageErrorImplementWrongWay, AIMessage)
function AIMessageErrorImplementWrongWay.new(customMt)
    -- upvalues: (copy) AIMessageErrorImplementWrongWay_mt
    return AIMessage.new(customMt or AIMessageErrorImplementWrongWay_mt)
end
function AIMessageErrorImplementWrongWay:getI18NText()
    return g_i18n:getText("ai_messageErrorImplementWrongWay")
end