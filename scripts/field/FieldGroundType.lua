FieldGroundType = {}
FieldGroundType.NONE = 1
FieldGroundType.STUBBLE_TILLAGE = 2
FieldGroundType.CULTIVATED = 3
FieldGroundType.SEEDBED = 4
FieldGroundType.PLOWED = 5
FieldGroundType.ROLLED_SEEDBED = 6
FieldGroundType.RIDGE = 7
FieldGroundType.SOWN = 8
FieldGroundType.DIRECT_SOWN = 9
FieldGroundType.PLANTED = 10
FieldGroundType.RIDGE_SOWN = 11
FieldGroundType.ROLLER_LINES = 12
FieldGroundType.HARVEST_READY = 13
FieldGroundType.HARVEST_READY_OTHER = 14
FieldGroundType.GRASS = 15
FieldGroundType.GRASS_CUT = 16
Enum(FieldGroundType)
function FieldGroundType.getValueByType(typeIndex)
    return g_currentMission.fieldGroundSystem:getFieldGroundValue(typeIndex)
end
function FieldGroundType.getValueByName(name)
    return g_currentMission.fieldGroundSystem:getFieldGroundValueByName(name)
end
function FieldGroundType.getTypeByValue(value)
    return g_currentMission.fieldGroundSystem:getFieldGroundTypeByValue(value)
end