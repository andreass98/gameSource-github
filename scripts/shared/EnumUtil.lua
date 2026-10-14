EnumUtil = {}
function EnumUtil.getName(enum, enumValue)
    for k, v in pairs(enum) do
        if v == enumValue and k ~= "NUM" then
            return k
        end
    end
    return nil
end
function EnumUtil.getNumEntries(enum)
    return enum.NUM or table.size(enum)
end
function EnumUtil.getKeys(enum)
    local keys = {}
    for k, v in pairs(enum) do
        if k ~= "NUM" then
            table.insert(keys, k)
        end
    end
    return keys
end