AIMessageErrorVehicleBroken = {}
local AIMessageErrorVehicleBroken_mt = Class(AIMessageErrorVehicleBroken, AIMessage)
function AIMessageErrorVehicleBroken.new(customMt)
    -- upvalues: (copy) AIMessageErrorVehicleBroken_mt
    return AIMessage.new(customMt or AIMessageErrorVehicleBroken_mt)
end
function AIMessageErrorVehicleBroken:getI18NText()
    return g_i18n:getText("ai_messageErrorVehicleBroken")
end