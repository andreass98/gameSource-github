AIMessageErrorGraintankIsFull = {}
local AIMessageErrorGraintankIsFull_mt = Class(AIMessageErrorGraintankIsFull, AIMessage)
function AIMessageErrorGraintankIsFull.new(customMt)
    -- upvalues: (copy) AIMessageErrorGraintankIsFull_mt
    return AIMessage.new(customMt or AIMessageErrorGraintankIsFull_mt)
end
function AIMessageErrorGraintankIsFull:getI18NText()
    return g_i18n:getText("ai_messageErrorTankIsFull")
end