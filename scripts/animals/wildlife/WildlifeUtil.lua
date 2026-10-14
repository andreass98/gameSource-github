WildlifeUtil = {}
function WildlifeUtil.createFromXMLFilename(xmlFilename, baseDirectory)
    local xmlFile = XMLFile.load("Wildlifespecies", xmlFilename, WildlifeSpecies.xmlSchema)
    if xmlFile == nil then
        Logging.warning("Could not load wildlife species config file \'%s\'", xmlFilename)
        return nil
    else
        local requiredDLC = xmlFile:getString("species#requiredDLC")
        if requiredDLC == nil or g_modIsLoaded[g_uniqueDlcNamePrefix .. requiredDLC] ~= nil then
            local className = xmlFile:getValue("species.class")
            if className == nil then
                Logging.xmlWarning(xmlFile, "Missing wildlife species class!")
                xmlFile:delete()
                return nil
            else
                local class = ClassUtil.getClassObject(className)
                if class == nil then
                    Logging.xmlWarning(xmlFile, "Wildlife species class \'%s\' not found!", className)
                    xmlFile:delete()
                    return nil
                else
                    local species = class.new()
                    if species:loadFromXML(xmlFile, baseDirectory) then
                        xmlFile:delete()
                        return species
                    else
                        species:delete()
                        return nil
                    end
                end
            end
        else
            xmlFile:delete()
            return nil
        end
    end
end
function WildlifeUtil.calculateRandomSpawnPosition(x, z, rotY, fovY, distance)
    local randomAngle = math.random() * (6.283185307179586 - fovY)
    local angle = rotY + fovY / 2 + randomAngle
    return x + math.sin(angle) * distance, z + math.cos(angle) * distance
end
function WildlifeUtil.getNumOfTrees(x, y, z, radius, height, callbackFunc)
    local target = {
        ["numTrees"] = 0,
        ["onTreeCallback"] = function(_, transformId, _, isLast)
            -- upvalues: (copy) target, (copy) callbackFunc
            if transformId ~= 0 and (getHasClassId(transformId, ClassIds.MESH_SPLIT_SHAPE) and (getSplitType(transformId) ~= 0 and not getIsSplitShapeSplit(transformId))) then
                target.numTrees = target.numTrees + 1
            end
            if isLast then
                callbackFunc(target.numTrees)
            end
            return true
        end
    }
    overlapCylinderAsync(x, y, z, radius, height, Axis.Y, "onTreeCallback", target, CollisionFlag.TREE)
end