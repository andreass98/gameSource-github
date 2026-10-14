CollisionPreset = {}
if CollisionFlag == nil then
    printError("Cannot source \'CollisionPreset\' without \'CollisionFlag\'")
else
    local presets = {}
    local presetsOrdered = {}
    local DEFAULT_MASK = 4294967295 - bit32.bor(CollisionFlag.CAMERA_BLOCKING, CollisionFlag.GROUND_TIP_BLOCKING, CollisionFlag.PLACEMENT_BLOCKING, CollisionFlag.AI_BLOCKING, CollisionFlag.PRECIPITATION_BLOCKING, CollisionFlag.TERRAIN_DISPLACEMENT, CollisionFlag.ANIMAL_POSITIONING, CollisionFlag.ANIMAL_NAV_MESH_BLOCKING, CollisionFlag.TRAFFIC_VEHICLE_BLOCKING)
    local DEFAULT_MASK_STATIC = 4294967295 - bit32.bor(CollisionFlag.TERRAIN_DISPLACEMENT)
    CollisionPreset.VEHICLE = (function(name, filterGroup, filterMask, description)
        -- upvalues: (copy) presets, (copy) presetsOrdered
        if string.upper(name) == name then
            if presets[name] == nil then
                for existingPresetName, preset in pairs(presets) do
                    if preset.group == filterGroup and preset.mask == filterMask then
                        Logging.error("Collision Preset %q is identical to %q", name, existingPresetName)
                        return
                    end
                end
                local preset = {
                    ["name"] = name,
                    ["group"] = filterGroup,
                    ["mask"] = filterMask,
                    ["desc"] = description
                }
                presets[name] = preset
                table.insert(presetsOrdered, preset)
                return presets[name]
            end
            Logging.error("Collision Preset name %q already defined", name)
        else
            Logging.error("Collision Preset name needs to be all uppercase: %q", name)
        end
    end)("VEHICLE", CollisionFlag.VEHICLE + CollisionFlag.CAMERA_BLOCKING, DEFAULT_MASK, "Vehicle main collisions")
    CollisionPreset.VEHICLE_NO_TIP_ANY = registerPreset("VEHICLE_NO_TIP_ANY", CollisionFlag.VEHICLE + CollisionFlag.CAMERA_BLOCKING, bit32.bxor(DEFAULT_MASK, CollisionFlag.TERRAIN_DELTA), "Vehicle collision not colliding with terrain delta/tipany")
    CollisionPreset.EXACT_FILL_ROOT_NODE = registerPreset("EXACT_FILL_ROOT_NODE", CollisionFlag.FILLABLE, CollisionFlag.TRIGGER, "target shape for fill triggers and raycasts")
    CollisionPreset.FILL_TRIGGER = registerPreset("FILL_TRIGGER", CollisionFlag.TRIGGER, CollisionFlag.FILLABLE, "trigger for shapes using the FILLABLE-flag in their collision group")
    CollisionPreset.VEHICLE_TRIGGER = registerPreset("VEHICLE_TRIGGER", CollisionFlag.TRIGGER, CollisionFlag.VEHICLE, "trigger for shapes using the VEHICLE-flag in their collision group")
    CollisionPreset.DYN_OBJECT_TRIGGER = registerPreset("DYN_OBJECT_TRIGGER", CollisionFlag.TRIGGER, CollisionFlag.DYNAMIC_OBJECT, "trigger for shapes using the DYNAMIC_OBJECT-flag in their collision group")
    CollisionPreset.PLAYER_TRIGGER = registerPreset("PLAYER_TRIGGER", CollisionFlag.TRIGGER, CollisionFlag.PLAYER, "trigger for player characters")
    CollisionPreset.PLAYER_VEHICLE_TRIGGER = registerPreset("PLAYER_VEHICLE_TRIGGER", CollisionFlag.TRIGGER, CollisionFlag.PLAYER + CollisionFlag.VEHICLE, "trigger for players and vehicles")
    CollisionPreset.WOOD_TRIGGER = registerPreset("WOOD_TRIGGER", CollisionFlag.TRIGGER, CollisionFlag.TREE, "trigger for trees/logs")
    CollisionPreset.TREE = registerPreset("TREE", CollisionFlag.TREE + CollisionFlag.PLACEMENT_BLOCKING + CollisionFlag.AI_BLOCKING, DEFAULT_MASK)
    CollisionPreset.FORK = registerPreset("FORK", CollisionFlag.VEHICLE_FORK, DEFAULT_MASK)
    CollisionPreset.PALLET_FLOOR = registerPreset("PALLET_FLOOR", CollisionFlag.VEHICLE, (bit32.bxor(DEFAULT_MASK, CollisionFlag.VEHICLE_FORK)))
    CollisionPreset.BALE = registerPreset("BALE", CollisionFlag.DYNAMIC_OBJECT, (bit32.bxor(DEFAULT_MASK, CollisionFlag.VEHICLE_FORK)))
    CollisionPreset.TRAFFIC_VEHICLE = registerPreset("TRAFFIC_VEHICLE", CollisionFlag.TRAFFIC_VEHICLE + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.AI_BLOCKING, (bit32.bor(CollisionFlag.TREE, CollisionFlag.VEHICLE, CollisionFlag.VEHICLE_FORK, CollisionFlag.DYNAMIC_OBJECT, CollisionFlag.PLAYER, CollisionFlag.ANIMAL)))
    CollisionPreset.BUILDING = registerPreset("BUILDING", CollisionFlag.BUILDING + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.AI_BLOCKING + CollisionFlag.PLACEMENT_BLOCKING + CollisionFlag.GROUND_TIP_BLOCKING, DEFAULT_MASK_STATIC)
    CollisionPreset.PLACEABLE_BUILDING = registerPreset("PLACEABLE_BUILDING", CollisionFlag.BUILDING + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.AI_BLOCKING + CollisionFlag.PLACEMENT_BLOCKING, DEFAULT_MASK_STATIC)
    CollisionPreset.ROAD = registerPreset("ROAD", CollisionFlag.ROAD + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.PLACEMENT_BLOCKING + CollisionFlag.GROUND_TIP_BLOCKING + CollisionFlag.AI_DRIVABLE, DEFAULT_MASK_STATIC)
    CollisionPreset.ROAD_BRIDGE = registerPreset("ROAD_BRIDGE", CollisionFlag.ROAD + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.PLACEMENT_BLOCKING + CollisionFlag.GROUND_TIP_BLOCKING + CollisionFlag.AI_BLOCKING + CollisionFlag.PRECIPITATION_BLOCKING, DEFAULT_MASK_STATIC)
    CollisionPreset.WATER = registerPreset("WATER", CollisionFlag.WATER, 1, "Collision used by water planes to make it interact with players and vehicles")
    CollisionPreset.STATIC_OBJECT = registerPreset("STATIC_OBJECT", CollisionFlag.STATIC_OBJECT + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.AI_BLOCKING + CollisionFlag.PLACEMENT_BLOCKING + CollisionFlag.GROUND_TIP_BLOCKING, DEFAULT_MASK_STATIC)
    CollisionPreset.DYNAMIC_OBJECT = registerPreset("DYNAMIC_OBJECT", CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.AI_BLOCKING + CollisionFlag.PLACEMENT_BLOCKING + CollisionFlag.GROUND_TIP_BLOCKING, DEFAULT_MASK)
    CollisionPreset.TIP_BLOCKING_COL = registerPreset("TIP_BLOCKING_COL", CollisionFlag.GROUND_TIP_BLOCKING, 1)
    CollisionPreset.PLACEMENT_BLOCKING_COL = registerPreset("PLACEMENT_BLOCKING_COL", CollisionFlag.PLACEMENT_BLOCKING, 1)
    CollisionPreset.ANIMAL_POSITIONING_COL = registerPreset("ANIMAL_POSITIONING_COL", CollisionFlag.ANIMAL_POSITIONING, 1, "Collision used by animals in nav meshes to determine their y position/height")
    CollisionPreset.DEFAULT = registerPreset("DEFAULT", 0, DEFAULT_MASK)
    function CollisionPreset.init()
        -- upvalues: (copy) DEFAULT_MASK, (copy) presetsOrdered
        if g_isDevelopmentVersion then
            function CollisionPreset.exportToXML(_)
                -- upvalues: (ref) DEFAULT_MASK, (ref) presetsOrdered
                local xmlFile = XMLFile.create("CollisionMaskFlags", "", "collisionMaskFlags")
                xmlFile:addComment("collisionMaskFlags", "Warning: This file is exported from script and should not be edited manually")
                local flagIndex = 0
                for name, bit, flag, data in CollisionFlag.iteratorFlags() do
                    local element = string.format("collisionMaskFlags.flag(%d)", flagIndex)
                    xmlFile:setInt(element .. "#bit", bit)
                    xmlFile:setString(element .. "#name", name)
                    xmlFile:setString(element .. "#desc", data.description)
                    flagIndex = flagIndex + 1
                end
                xmlFile:addComment("collisionMaskFlags", "Warning: This file is exported from script and should not be edited manually")
                xmlFile:setString("collisionMaskFlags.defaultMask", string.format("0x%x", DEFAULT_MASK))
                local presetIndex = 0
                for bit, flag in ipairs(presetsOrdered) do
                    local data = string.format("collisionMaskFlags.preset(%d)", presetIndex)
                    xmlFile:setString(data .. "#name", flag.name)
                    if flag.desc ~= nil then
                        xmlFile:setString(data .. "#desc", flag.desc)
                    end
                    local flagIndex = 0
                    local element = CollisionFlag.getFlagsFromMask(flag.group)
                    for _, flag in pairs(element) do
                        xmlFile:setString(data .. string.format(".group.flag(%d)#name", flagIndex), flag.name)
                        flagIndex = flagIndex + 1
                    end
                    local maskFlags, _maskFlagsInverse = CollisionFlag.getFlagsFromMask(flag.mask)
                    if #maskFlags < 10 then
                        local flagIndex = 0
                        for _, flag in pairs(maskFlags) do
                            xmlFile:setString(data .. string.format(".mask.flag(%d)#name", flagIndex), flag.name)
                            flagIndex = flagIndex + 1
                        end
                    else
                        xmlFile:addComment(data, CollisionFlag.getFlagsStringFromMask(flag.mask, true))
                        xmlFile:setString(data .. ".mask#value", string.format("0x%x", flag.mask))
                    end
                    presetIndex = presetIndex + 1
                end
                xmlFile:addComment("collisionMaskFlags", "Warning: This file is exported from script and should not be edited manually")
                xmlFile:saveTo("shared/collisionMaskFlags.xml", true)
                xmlFile:saveTo("../tools/editor/shared/collisionMaskFlags.xml", true)
                xmlFile:saveTo("../tools/exporter/maya/collisionMaskFlags.xml", true)
                xmlFile:saveTo("../tools/exporter/blender/exporter/io_export_i3d/collisionMaskFlags.xml", true)
                xmlFile:delete()
            end
            addConsoleCommand("gsCollisionPresetsExport", "Export all collision presets to xml files", "exportToXML", CollisionPreset)
        end
    end
end