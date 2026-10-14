AIMessageErrorUnloadingStationDeleted = {}
local AIMessageErrorUnloadingStationDeleted_mt = Class(AIMessageErrorUnloadingStationDeleted, AIMessage)
function AIMessageErrorUnloadingStationDeleted.new(customMt)
    -- upvalues: (copy) AIMessageErrorUnloadingStationDeleted_mt
    return AIMessage.new(customMt or AIMessageErrorUnloadingStationDeleted_mt)
end
function AIMessageErrorUnloadingStationDeleted:getI18NText()
    return g_i18n:getText("ai_messageErrorUnloadingStationDeleted")
end