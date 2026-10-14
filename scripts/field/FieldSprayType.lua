FieldSprayType = {}
FieldSprayType.NONE = 1
FieldSprayType.FERTILIZER = 2
FieldSprayType.LIME = 3
FieldSprayType.MANURE = 4
FieldSprayType.LIQUID_MANURE = 5
Enum(FieldSprayType)
function FieldSprayType.getValueByType(typeIndex)
    return g_currentMission.fieldGroundSystem:getFieldSprayValue(typeIndex)
end
function FieldSprayType.getValueByName(name)
    return g_currentMission.fieldGroundSystem:getFieldSprayValueByName(name)
end
function FieldSprayType.getTypeByValue(value)
    return g_currentMission.fieldGroundSystem:getFieldSprayTypeByValue(value)
end