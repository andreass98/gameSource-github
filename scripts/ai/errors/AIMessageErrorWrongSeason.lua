AIMessageErrorWrongSeason = {}
local AIMessageErrorWrongSeason_mt = Class(AIMessageErrorWrongSeason, AIMessage)
function AIMessageErrorWrongSeason.new(customMt)
    -- upvalues: (copy) AIMessageErrorWrongSeason_mt
    return AIMessage.new(customMt or AIMessageErrorWrongSeason_mt)
end
function AIMessageErrorWrongSeason:getI18NText()
    return g_i18n:getText("ai_messageErrorWrongSeason")
end