AIMessageErrorNoVineFound = {}
local AIMessageErrorNoVineFound_mt = Class(AIMessageErrorNoVineFound, AIMessage)
function AIMessageErrorNoVineFound.new(customMt)
    -- upvalues: (copy) AIMessageErrorNoVineFound_mt
    return AIMessage.new(customMt or AIMessageErrorNoVineFound_mt)
end
function AIMessageErrorNoVineFound:getI18NText()
    return g_i18n:getText("ai_messageErrorNoVineFound")
end