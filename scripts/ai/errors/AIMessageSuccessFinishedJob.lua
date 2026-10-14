AIMessageSuccessFinishedJob = {}
local AIMessageSuccessFinishedJob_mt = Class(AIMessageSuccessFinishedJob, AIMessage)
function AIMessageSuccessFinishedJob.new(customMt)
    -- upvalues: (copy) AIMessageSuccessFinishedJob_mt
    return AIMessage.new(customMt or AIMessageSuccessFinishedJob_mt)
end
function AIMessageSuccessFinishedJob:getI18NText()
    return g_i18n:getText("ai_messageSuccessFinishedJob")
end
function AIMessageSuccessFinishedJob:getType()
    return AIMessageType.OK
end