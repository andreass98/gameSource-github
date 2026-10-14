CollisionFlag = {}
local USED_BITS = {}
local DATA = {}
local DATA_MAPPING = {}
local FULL_MASK = 255
local ACTIVE_MASK = 0
local function registerFlag(bit, name, description, isActive)
    -- upvalues: (copy) USED_BITS, (ref) ACTIVE_MASK, (ref) FULL_MASK, (copy) DATA_MAPPING, (copy) DATA
    if USED_BITS[bit] ~= nil then
        Logging.error("CollisionFlag.registerFlag: Given bit \'%d\' is already in use.", bit)
        return nil
    end
    local data = string.upper(name)
    if CollisionFlag[data] ~= nil then
        Logging.error("CollisionFlag.registerFlag: Given  name \'%s\' is already in use", data)
        return nil
    end
    local data = {
        ["name"] = data,
        ["description"] = description or "",
        ["bit"] = bit,
        ["flag"] = 2 ^ bit
    }
    data.isActive = isActive or bit < 8
    data.isDeprecated = not isActive
    if data.isActive then
        ACTIVE_MASK = bit32.bor(ACTIVE_MASK, data.flag)
    end
    FULL_MASK = bit32.bor(FULL_MASK, data.flag)
    USED_BITS[bit] = true
    CollisionFlag[data] = data.flag
    DATA_MAPPING[data.flag] = data
    table.insert(DATA, data)
    return data.flag
end
function CollisionFlag.iteratorFlags()
    -- upvalues: (copy) DATA_MAPPING
    local currentIndex = 0
    local endIndex = 31
    return function()
        -- upvalues: (ref) currentIndex, (ref) DATA_MAPPING, (copy) endIndex
        if currentIndex > 31 then
            return nil
        end
        currentIndex = currentIndex + 1
        while DATA_MAPPING[2 ^ (currentIndex - 1)] == nil do
            currentIndex = currentIndex + 1
        end
        local data = DATA_MAPPING[2 ^ (currentIndex - 1)]
        return data.name, data.bit, data.flag, data
    end
end
function CollisionFlag.getHasMaskFlagSet(node, flag)
    local collisionMask = getCollisionFilterMask(node)
    return bit32.btest(collisionMask, flag)
end
function CollisionFlag.getHasGroupFlagSet(node, flag)
    local collisionMask = getCollisionFilterGroup(node)
    return bit32.btest(collisionMask, flag)
end
function CollisionFlag.setMaskFlag(node, flag)
    local collisionMask = getCollisionFilterMask(node)
    local newCollisionMask = bit32.bor(collisionMask, flag)
    setCollisionFilterMask(node, newCollisionMask)
end
function CollisionFlag.setGroupFlag(node, flag)
    local collisionGroup = getCollisionFilterGroup(node)
    local newCollisionGroup = bit32.bor(collisionGroup, flag)
    setCollisionFilterGroup(node, newCollisionGroup)
end
function CollisionFlag.getBit(flag)
    -- upvalues: (copy) DATA_MAPPING
    local data = DATA_MAPPING[flag]
    if data == nil then
        printCallstack()
    end
    return data.bit
end
function CollisionFlag.getBitAndName(flag)
    -- upvalues: (copy) DATA_MAPPING
    local data = DATA_MAPPING[flag]
    if data == nil then
        printCallstack()
    end
    return string.format("bit %d (%s)", data.bit, data.name)
end
function CollisionFlag.getFlagsFromMask(mask)
    -- upvalues: (copy) DATA_MAPPING
    local flags = {}
    local flagInverse = {}
    local bit = 0
    for bit = bit, 31 do
        local flagMask = 2 ^ bit
        local data = DATA_MAPPING[flagMask]
        if data ~= nil then
            if bit32.btest(flagMask, mask) then
                table.insert(flags, data)
            else
                table.insert(flagInverse, data)
            end
        end
    end
    return flags, flagInverse
end
function CollisionFlag.getFlagsStringFromMask(mask, allowInverse)
    -- upvalues: (copy) USED_BITS, (copy) DATA_MAPPING
    local isInverse = false
    local numSetBits = MathUtil.getNumOfSetBits(mask)
    if allowInverse and table.size(USED_BITS) * 0.5 < numSetBits then
        mask = bit32.bnot(mask)
        isInverse = true
    end
    for _, bit in ipairs(MathUtil.numberToSetBits(mask)) do
        local data = DATA_MAPPING[2 ^ bit]
        if data ~= nil then
            table.insert({}, data.name)
        end
    end
    if allowInverse and numSetBits == table.size(USED_BITS) then
        return "ALL registered Bits"
    elseif isInverse then
        return "ALL except " .. table.concat(flagNames, ", ")
    else
        return table.concat(flagNames, ", ")
    end
end
function CollisionFlag.checkCollisionMask(node)
    -- upvalues: (ref) FULL_MASK, (ref) ACTIVE_MASK
    local matches = false
    if getHasClassId(node, ClassIds.SHAPE) then
        local mask = getCollisionFilterMask(node)
        if mask > 0 and mask ~= 255 then
            local bitStr = bit32.bnot(FULL_MASK)
            local undefinedMask = bit32.band(mask, bitStr)
            if undefinedMask ~= 0 then
                local bitStr = MathUtil.numberToSetBitsStr(undefinedMask)
                print(string.format("    CollisionFlag-Check: Node \'%s\' uses undefined bits \'%s\'!", I3DUtil.getNodePath(node), bitStr))
                matches = true
            end
            local bitStr = bit32.band(mask, (bit32.bnot(ACTIVE_MASK)))
            if bitStr ~= 0 then
                local bitStr = MathUtil.numberToSetBitsStr(bitStr)
                print(string.format("    CollisionFlag-Check: Node \'%s\' uses deprecated bits \'%s\'!", I3DUtil.getNodePath(node), bitStr))
                matches = true
            end
        end
    end
    return matches
end
function CollisionFlag.checkCollisionMaskRec(node)
    local matches = false
    if node ~= nil and node ~= 0 then
        matches = matches or CollisionFlag.checkCollisionMask(node)
        local i = 0
        for i = i, getNumOfChildren(node) - 1 do
            matches = matches or CollisionFlag.checkCollisionMaskRec(getChildAt(node, i))
        end
    end
    return matches
end
addConsoleCommand("gsCollisionFlagShowAll", "Shows all available collision flags", "consoleCommandShowAll", CollisionFlag)
function CollisionFlag.consoleCommandShowAll()
    -- upvalues: (copy) DATA
    table.sort(DATA, function(a, b)
        if not (a.isDeprecated and b.isDeprecated) and (a.isDeprecated or b.isDeprecated) then
            return not a.isDeprecated
        end
        return a.bit < b.bit
    end)
    print("Defined collision flags:")
    local showedDeprecated = false
    for _, data in ipairs(DATA) do
        if data.isDeprecated and not showedDeprecated then
            print("\nDeprecated:")
            showedDeprecated = true
        end
        print(string.format("Bit %02d: %s - %s", data.bit, data.name, data.description))
    end
    print("\n\nPredefined collision masks:")
    for _, data in pairs(CollisionMask) do
        print(string.format("Mask %010d: %s", data, _))
    end
end
CollisionFlag.DEFAULT = registerFlag(0, "DEFAULT", "The default bit", true)
CollisionFlag.STATIC_OBJECT = registerFlag(1, "STATIC_OBJECT", "Static object", true)
CollisionFlag.CAMERA_BLOCKING = registerFlag(2, "CAMERA_BLOCKING", "Blocks the player camera from being inside", true)
CollisionFlag.GROUND_TIP_BLOCKING = registerFlag(3, "GROUND_TIP_BLOCKING", "Blocks tipping on the ground beneath/above", true)
CollisionFlag.PLACEMENT_BLOCKING = registerFlag(4, "PLACEMENT_BLOCKING", "Blocks placing objects via construction", true)
CollisionFlag.AI_BLOCKING = registerFlag(5, "AI_BLOCKING", "Blocks vehicle navigation map beneath/above", true)
CollisionFlag.PRECIPITATION_BLOCKING = registerFlag(6, "PRECIPITATION_BLOCKING", "Masks all precipitation inside and below the collision", true)
CollisionFlag.TERRAIN = registerFlag(8, "TERRAIN", "Terrain without tip any or displacement", true)
CollisionFlag.TERRAIN_DELTA = registerFlag(9, "TERRAIN_DELTA", "Tip anything", true)
CollisionFlag.TERRAIN_DISPLACEMENT = registerFlag(10, "TERRAIN_DISPLACEMENT", "Terrain displacement (tiretrack deformation)", true)
CollisionFlag.TREE = registerFlag(11, "TREE", "A tree", true)
CollisionFlag.BUILDING = registerFlag(12, "BUILDING", "A building", true)
CollisionFlag.ROAD = registerFlag(13, "ROAD", "A road", true)
CollisionFlag.AI_DRIVABLE = registerFlag(14, "AI_DRIVABLE", "Blocks vehicle navigation map at the vertical faces of the mesh if they are above the terrain", true)
CollisionFlag.VEHICLE = registerFlag(16, "VEHICLE", "A vehicle", true)
CollisionFlag.VEHICLE_FORK = registerFlag(17, "VEHICLE_FORK", "A vehicle fork tip for pallets or bales", true)
CollisionFlag.DYNAMIC_OBJECT = registerFlag(18, "DYNAMIC_OBJECT", "A dynamic object", true)
CollisionFlag.TRAFFIC_VEHICLE = registerFlag(19, "TRAFFIC_VEHICLE", "A AI traffic vehicle", true)
CollisionFlag.PLAYER = registerFlag(20, "PLAYER", "A player", true)
CollisionFlag.ANIMAL = registerFlag(21, "ANIMAL", "An Animal", true)
CollisionFlag.ANIMAL_POSITIONING = registerFlag(22, "ANIMAL_POSITIONING", "For animal to walk on (position is raycast from above)", true)
CollisionFlag.ANIMAL_NAV_MESH_BLOCKING = registerFlag(23, "ANIMAL_NAV_MESH_BLOCKING", "Area of the collision is excluded from generated nav meshes", true)
CollisionFlag.TRAFFIC_VEHICLE_BLOCKING = registerFlag(24, "TRAFFIC_VEHICLE_BLOCKING", "Blocks AI traffic vehicles", true)
CollisionFlag.INTERACTABLE_TARGET = registerFlag(28, "INTERACTABLE_TARGET", "An interactable trigger that the player can target", true)
CollisionFlag.TRIGGER = registerFlag(29, "TRIGGER", "A trigger", true)
CollisionFlag.FILLABLE = registerFlag(30, "FILLABLE", "A fillable node. For trailer fillNodes and unload triggers", true)
CollisionFlag.WATER = registerFlag(31, "WATER", "A water plane", true)
function CollisionFlag.consoleCommandReloadCollisionMaskMapping()
    CollisionFlag.loadCollisionMaskMapping()
    CollisionFlag.printMapping()
    return "reloaded mapping"
end
function CollisionFlag.consoleCommandToggleVerbose()
    CollisionFlag.colMaskMappingVerbose = not CollisionFlag.colMaskMappingVerbose
    return "CollisionFlag.colMaskMappingVerbose=" .. tostring(CollisionFlag.colMaskMappingVerbose)
end
function CollisionFlag.loadCollisionMaskMapping()
    local xmlFile = XMLFile.load("collisionMaskConversionRules", "shared/collisionMaskConversionRules.xml")
    if xmlFile ~= nil then
        Logging.info("Loading collision mask conversion rules from %q", xmlFile:getFilename())
        colMaskMapping = {}
        colMaskPresets = {}
        for _, preset in xmlFile:iterator("collisionMaskUpdater.presets.preset") do
            local presetName = xmlFile:getString(preset .. "#name")
            if colMaskPresets[presetName] == nil then
                colMaskPresets[presetName] = {
                    ["group"] = (function(key, startingValue)
                        -- upvalues: (copy) xmlFile
                        local maskNew = startingValue or 0
                        local valueStr = xmlFile:getString(key .. "#value")
                        if valueStr ~= nil then
                            local valueStr = string.gsub(valueStr, "_", "")
                            maskNew = tonumber(valueStr)
                            if maskNew == nil then
                                Logging.xmlError(xmlFile, "Unable to parse %q as a number for %q", valueStr, key .. "#value")
                                return nil
                            end
                        end
                        for _, flagElement in xmlFile:iterator(key .. ".flag") do
                            local flagName = xmlFile:getString(flagElement .. "#name")
                            if flagName == nil then
                                local mask = xmlFile:getInt(flagElement .. "#bit")
                                if mask ~= nil then
                                    if mask < 0 or mask > 31 then
                                        Logging.xmlError(xmlFile, "Invalid bit number %q at %q, needs to be between 0 and 31", mask, flagElement)
                                    else
                                        maskNew = bit32.bor(maskNew, 2 ^ mask)
                                    end
                                end
                            else
                                local mask = CollisionFlag[flagName]
                                if mask == nil then
                                    Logging.xmlError(xmlFile, "Unable to find CollisionFlag %q for %q", flagName, flagElement)
                                else
                                    maskNew = bit32.bor(maskNew, mask)
                                end
                            end
                        end
                        for _, flagElement in xmlFile:iterator(key .. ".withoutFlag") do
                            local flagName = xmlFile:getString(flagElement .. "#name")
                            if flagName == nil then
                                local mask = xmlFile:getInt(flagElement .. "#bit")
                                if mask ~= nil then
                                    if mask < 0 or mask > 31 then
                                        Logging.xmlError(xmlFile, "Invalid bit number %q at %q, needs to be between 0 and 31", mask, flagElement)
                                    else
                                        maskNew = bit32.bxor(maskNew, 2 ^ mask)
                                    end
                                end
                            else
                                local mask = CollisionFlag[flagName]
                                if mask == nil then
                                    Logging.xmlError(xmlFile, "Unable to find CollisionFlag %q for %q", flagName, flagElement)
                                else
                                    maskNew = bit32.bxor(maskNew, mask)
                                end
                            end
                        end
                        return maskNew
                    end)(preset .. ".group"),
                    ["mask"] = (function(key, startingValue)
                        -- upvalues: (copy) xmlFile
                        local maskNew = startingValue or 0
                        local valueStr = xmlFile:getString(key .. "#value")
                        if valueStr ~= nil then
                            local valueStr = string.gsub(valueStr, "_", "")
                            maskNew = tonumber(valueStr)
                            if maskNew == nil then
                                Logging.xmlError(xmlFile, "Unable to parse %q as a number for %q", valueStr, key .. "#value")
                                return nil
                            end
                        end
                        for _, flagElement in xmlFile:iterator(key .. ".flag") do
                            local flagName = xmlFile:getString(flagElement .. "#name")
                            if flagName == nil then
                                local mask = xmlFile:getInt(flagElement .. "#bit")
                                if mask ~= nil then
                                    if mask < 0 or mask > 31 then
                                        Logging.xmlError(xmlFile, "Invalid bit number %q at %q, needs to be between 0 and 31", mask, flagElement)
                                    else
                                        maskNew = bit32.bor(maskNew, 2 ^ mask)
                                    end
                                end
                            else
                                local mask = CollisionFlag[flagName]
                                if mask == nil then
                                    Logging.xmlError(xmlFile, "Unable to find CollisionFlag %q for %q", flagName, flagElement)
                                else
                                    maskNew = bit32.bor(maskNew, mask)
                                end
                            end
                        end
                        for _, flagElement in xmlFile:iterator(key .. ".withoutFlag") do
                            local flagName = xmlFile:getString(flagElement .. "#name")
                            if flagName == nil then
                                local mask = xmlFile:getInt(flagElement .. "#bit")
                                if mask ~= nil then
                                    if mask < 0 or mask > 31 then
                                        Logging.xmlError(xmlFile, "Invalid bit number %q at %q, needs to be between 0 and 31", mask, flagElement)
                                    else
                                        maskNew = bit32.bxor(maskNew, 2 ^ mask)
                                    end
                                end
                            else
                                local mask = CollisionFlag[flagName]
                                if mask == nil then
                                    Logging.xmlError(xmlFile, "Unable to find CollisionFlag %q for %q", flagName, flagElement)
                                else
                                    maskNew = bit32.bxor(maskNew, mask)
                                end
                            end
                        end
                        return maskNew
                    end)(preset .. ".mask")
                }
            else
                Logging.xmlError(xmlFile, "Preset name %q at %q already in use", presetName, preset)
            end
        end
        for _, preset in xmlFile:iterator("collisionMaskUpdater.conversionRules.rule") do
            local presetName = tonumber(xmlFile:getString(preset .. "#maskOld"))
            if colMaskMapping[presetName] == nil then
                for _, output in xmlFile:iterator(preset .. ".output") do
                    local groupNew = nil
                    local maskNew = nil
                    local presetName = xmlFile:getString(output .. "#preset")
                    if presetName ~= nil then
                        local preset = CollisionPreset[presetName] or colMaskPresets[presetName]
                        if preset == nil then
                            Logging.xmlError(xmlFile, "Unknown preset %q in %q", presetName, output)
                        else
                            groupNew = preset.group
                            maskNew = preset.mask
                        end
                    end
                    local preset = loadMask(output .. ".group", groupNew)
                    local preset = loadMask(output .. ".mask", maskNew)
                    if preset == 0 then
                        Logging.xmlError(xmlFile, "Incomplete conversion rule for old mask %q at %q, no new group filter defined", presetName, output)
                    elseif preset == 0 then
                        Logging.xmlError(xmlFile, "Incomplete conversion rule for old mask %q at %q, no new mask defined", presetName, output)
                    else
                        colMaskMapping[presetName] = colMaskMapping[presetName] or {}
                        table.insert(colMaskMapping[presetName], {
                            ["group"] = preset,
                            ["mask"] = preset,
                            ["isTrigger"] = xmlFile:getBool(output .. "#isTrigger")
                        })
                    end
                end
            else
                Logging.warning("duplicate mask %q", presetName)
            end
        end
        xmlFile:delete()
    end
end
function CollisionFlag.printMapping()
    setFileLogPrefixTimestamp(false)
    print("Presets")
    for presetName, presetData in pairs(colMaskPresets) do
        print(string.format("    %s", presetName))
        print(string.format("        => group: Dec:%s  Hex:%x  Flags:%s", presetData.group, presetData.group, CollisionFlag.getFlagsStringFromMask(presetData.group)))
        print(string.format("        => mask: Dec:%s  Hex:%x  Flags:%s", presetData.mask, presetData.mask, CollisionFlag.getFlagsStringFromMask(presetData.mask, true)))
    end
    print("\nRules")
    for presetName, presetData in pairs(colMaskMapping) do
        print(string.format("Old: Dec:%s Hex:%x Bits:%s", presetName, presetName, MathUtil.numberToSetBitsStr(presetName)))
        for outputIndex, output in ipairs(presetData) do
            if #presetData > 1 then
                print(string.format("    output %d - isTrigger=%s", outputIndex, output.isTrigger))
            end
            print(string.format("        => group: Dec:%s  Hex:%x  Flags:%s", output.group, output.group, CollisionFlag.getFlagsStringFromMask(output.group)))
            print(string.format("        => mask: Dec:%s  Hex:%x  Flags:%s", output.mask, output.mask, CollisionFlag.getFlagsStringFromMask(output.mask, true)))
        end
    end
    setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
end
if I3DManager ~= nil then
    I3DManager.addDebugLoadingCheck("check col group / mask", function(_, node)
        if getHasClassId(node, ClassIds.SHAPE) or getHasClassId(node, ClassIds.TERRAIN_TRANSFORM_GROUP) then
            local currentMask = getCollisionFilterMask(node)
            if currentMask == 0 then
                return
            end
            if currentMask ~= getCollisionFilterGroup(node) then
                return
            end
            if CollisionFlag.colMaskMappingVerbose then
                printWarning(string.format("Warning: outdated mask for %q Dec:%s Hex:%x Bits: %s", I3DUtil.getNodePath(node), currentMask, currentMask, currentMask == 4294967295 and "ALL" or MathUtil.numberToSetBitsStr(currentMask)))
            end
        end
        return false
    end)
end