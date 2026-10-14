FieldChopperType = {}
FieldChopperType.CHOPPER_STRAW = 1
FieldChopperType.CHOPPER_MAIZE = 2
Enum(FieldChopperType)
function FieldChopperType.getValueByType(typeIndex)
    return g_currentMission.fieldGroundSystem:getChopperTypeValue(typeIndex)
end