AIMessageErrorLoadingStationDeleted = {}
local AIMessageErrorLoadingStationDeleted_mt = Class(AIMessageErrorLoadingStationDeleted, AIMessage)
function AIMessageErrorLoadingStationDeleted.new(customMt)
    -- upvalues: (copy) AIMessageErrorLoadingStationDeleted_mt
    return AIMessage.new(customMt or AIMessageErrorLoadingStationDeleted_mt)
end
function AIMessageErrorLoadingStationDeleted:getI18NText()
    return g_i18n:getText("ai_messageErrorLoadingStationDeleted")
end