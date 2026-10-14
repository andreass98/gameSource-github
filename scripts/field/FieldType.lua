FieldType = {}
FieldType.DEFAULT = 1
FieldType.RICE = 2
Enum(FieldType)
function FieldType.getValueByType(typeIndex)
    return g_currentMission.fieldGroundSystem:getFieldTypeValue(typeIndex)
end
function FieldType.getValueByName(name)
    return g_currentMission.fieldGroundSystem:getFieldTypeValueByName(name)
end
function FieldType.getTypeByValue(value)
    return g_currentMission.fieldGroundSystem:getFieldTypeByValue(value)
end