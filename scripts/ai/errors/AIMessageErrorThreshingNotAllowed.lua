AIMessageErrorThreshingNotAllowed = {}
local AIMessageErrorThreshingNotAllowed_mt = Class(AIMessageErrorThreshingNotAllowed, AIMessage)
function AIMessageErrorThreshingNotAllowed.new(customMt)
    -- upvalues: (copy) AIMessageErrorThreshingNotAllowed_mt
    return AIMessage.new(customMt or AIMessageErrorThreshingNotAllowed_mt)
end
function AIMessageErrorThreshingNotAllowed:getI18NText()
    return g_i18n:getText("ai_messageErrorThreshingNotAllowed")
end