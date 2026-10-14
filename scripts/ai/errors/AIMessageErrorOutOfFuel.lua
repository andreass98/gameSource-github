AIMessageErrorOutOfFuel = {}
local AIMessageErrorOutOfFuel_mt = Class(AIMessageErrorOutOfFuel, AIMessage)
function AIMessageErrorOutOfFuel.new(customMt)
    -- upvalues: (copy) AIMessageErrorOutOfFuel_mt
    return AIMessage.new(customMt or AIMessageErrorOutOfFuel_mt)
end
function AIMessageErrorOutOfFuel:getI18NText()
    return g_i18n:getText("ai_messageErrorOutOfFuel")
end