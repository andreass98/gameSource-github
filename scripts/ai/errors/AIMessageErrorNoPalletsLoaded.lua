AIMessageErrorNoPalletsLoaded = {}
local AIMessageErrorNoPalletsLoaded_mt = Class(AIMessageErrorNoPalletsLoaded, AIMessage)
function AIMessageErrorNoPalletsLoaded.new(customMt)
    -- upvalues: (copy) AIMessageErrorNoPalletsLoaded_mt
    return AIMessage.new(customMt or AIMessageErrorNoPalletsLoaded_mt)
end
function AIMessageErrorNoPalletsLoaded:getI18NText()
    return g_i18n:getText("ai_messageErrorNoPalletsLoaded")
end
function AIMessageErrorNoPalletsLoaded:getType()
    return AIMessageType.ERROR
end