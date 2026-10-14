AIMessageSuccessSiloEmpty = {}
local AIMessageSuccessSiloEmpty_mt = Class(AIMessageSuccessSiloEmpty, AIMessage)
function AIMessageSuccessSiloEmpty.new(customMt)
    -- upvalues: (copy) AIMessageSuccessSiloEmpty_mt
    return AIMessage.new(customMt or AIMessageSuccessSiloEmpty_mt)
end
function AIMessageSuccessSiloEmpty:getI18NText()
    return g_i18n:getText("ai_messageSuccessSiloEmpty")
end
function AIMessageSuccessSiloEmpty:getType()
    return AIMessageType.OK
end