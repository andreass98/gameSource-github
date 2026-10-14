GameTestCaseAI = {}
local GameTestCaseAI_mt = Class(GameTestCaseAI, GameTestCase)
function GameTestCaseAI.new(customMt)
    -- upvalues: (copy) GameTestCaseAI_mt
    return GameTestCase.new(customMt or GameTestCaseAI_mt)
end
function GameTestCaseAI.loadPosition(xmlFile, key)
    local spawnPosition = {
        ["name"] = xmlFile:getString(key .. "#name"),
        ["translation"] = xmlFile:getVector(key .. "#translation"),
        ["rotation"] = xmlFile:getVector(key .. "#rotation")
    }
    if spawnPosition.name == nil or (spawnPosition.translation == nil or spawnPosition.rotation == nil) then
        return nil
    end
    local fieldId = xmlFile:getInt(key .. "#fieldId")
    if fieldId ~= nil then
        local field = g_fieldManager:getFieldById(fieldId)
        if field == nil then
            Logging.xmlWarning(xmlFile, "Failed to load field for spawn position from \'%s\'. Field no longer exists.", key)
            return nil
        end
        spawnPosition.field = field
    end
    local field = spawnPosition.rotation
    field[1] = math.rad(spawnPosition.rotation[1])
    local field = spawnPosition.rotation
    field[2] = math.rad(spawnPosition.rotation[2])
    local field = spawnPosition.rotation
    field[3] = math.rad(spawnPosition.rotation[3])
    spawnPosition.index = 1
    return spawnPosition
end
function GameTestCaseAI.savePosition(spawnPosition, xmlFile, key)
    xmlFile:setString(key .. "#name", spawnPosition.name)
    xmlFile:setVector(key .. "#translation", spawnPosition.translation)
    local rotation = {}
    rotation[1] = math.deg(spawnPosition.rotation[1])
    rotation[2] = math.deg(spawnPosition.rotation[2])
    rotation[3] = math.deg(spawnPosition.rotation[3])
    xmlFile:setVector(key .. "#rotation", rotation)
    if spawnPosition.field ~= nil then
        xmlFile:setInt(key .. "#fieldId", spawnPosition.field:getId())
    end
end
function GameTestCaseAI.loadPlaceable(xmlFile, key)
    local filename = xmlFile:getString(key .. "#filename")
    if filename ~= nil then
        filename = NetworkUtil.convertFromNetworkFilename(filename)
    end
    local translation = xmlFile:getVector(key .. "#position")
    local rotation = xmlFile:getVector(key .. "#rotation")
    for k, placeable in pairs(g_currentMission.placeableSystem.placeables) do
        if placeable.configFileName == filename then
            local x, y, z = getTranslation(placeable.rootNode)
            local rx, ry, rz = getRotation(placeable.rootNode)
            if math.abs(x - translation[1]) < 0.1 then
                if math.abs(y - translation[2]) < 0.1 then
                    if math.abs(z - translation[3]) < 0.1 then
                        if math.abs(rx - rotation[1]) < 0.1 then
                            if math.abs(ry - rotation[2]) < 0.1 then
                                if math.abs(rz - rotation[3]) < 0.1 then
                                    return placeable
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    Logging.error("Failed to find placeable \'%s\' at \'%.1f %.1f %.1f\'", filename, translation[1], translation[2], translation[3])
    return nil
end
function GameTestCaseAI.savePlaceable(placeable, xmlFile, key)
    xmlFile:setString(key .. "#filename", NetworkUtil.convertToNetworkFilename(placeable.configFileName))
    xmlFile:setVector(key .. "#position", { getTranslation(placeable.rootNode) })
    xmlFile:setVector(key .. "#rotation", { getRotation(placeable.rootNode) })
end
function GameTestCaseAI.loadSpawnPositions(xmlFile, key)
    local spawnPositions = {}
    key = xmlFile:getBool(key .. ".spawnPositions#useBasePositions", false) and "testing" or key
    xmlFile:iterate(key .. ".spawnPositions.spawnPosition", function(_, positionKey)
        -- upvalues: (copy) xmlFile, (copy) spawnPositions
        local spawnPosition = GameTestCaseAI.loadPosition(xmlFile, positionKey)
        if spawnPosition == nil then
            Logging.xmlWarning(xmlFile, "Failed to load spawn position from \'%s\'", positionKey)
        else
            spawnPosition.index = #spawnPositions + 1
            table.insert(spawnPositions, spawnPosition)
        end
    end)
    local useFieldCenter = xmlFile:getBool(key .. ".spawnPositions#useFieldCenter", false)
    if useFieldCenter or xmlFile:getBool(key .. ".spawnPositions#useFieldBorder", false) then
        local includeFields = xmlFile:getVector(key .. ".spawnPositions#includeFields")
        local excludeFields = xmlFile:getVector(key .. ".spawnPositions#excludeFields")
        local fields = g_fieldManager:getFields()
        local i = 1
        for i = i, #fields do
            local field = fields[i]
            if field:getId() ~= nil then
                local fieldAllowed = true
                if excludeFields == nil then
                    if includeFields ~= nil then
                        fieldAllowed = false
                        local j = 1
                        for j = j, #includeFields do
                            if field:getId() == includeFields[j] then
                                fieldAllowed = true
                                break
                            end
                        end
                    end
                else
                    local j = 1
                    for j = j, #excludeFields do
                        if field:getId() == excludeFields[j] then
                            fieldAllowed = false
                            break
                        end
                    end
                end
                if fieldAllowed then
                    local spawnPosition = {
                        ["name"] = string.format("Field %d", field:getId()),
                        ["field"] = field
                    }
                    if useFieldCenter then
                        local posX, j = field:getCenterOfFieldWorldPosition()
                        spawnPosition.translation = { posX, 0, j }
                        spawnPosition.rotation = { 0, math.random() * 3.141592653589793 * 2, 0 }
                    elseif getNumOfChildren(field.fieldDimensions) > 0 then
                        local j = getChildAt(field.fieldDimensions, 0)
                        local dimStart = getChildAt(j, 0)
                        local dimHeight = getChildAt(j, 1)
                        if calcDistanceFrom(dimStart, j) <= calcDistanceFrom(dimStart, dimHeight) then
                            j = dimHeight
                        end
                        local sx, _, sz = getWorldTranslation(dimStart)
                        local hx, _, hz = getWorldTranslation(j)
                        local dirX2, dirZ2 = MathUtil.vector2Normalize(hx - sx, hz - sz)
                        spawnPosition.translation = { sx, 0, sz }
                        spawnPosition.rotation = { 0, MathUtil.getYRotationFromDirection(dirX2, dirZ2), 0 }
                    end
                    if spawnPosition.translation ~= nil then
                        spawnPosition.index = #spawnPositions + 1
                        table.insert(spawnPositions, spawnPosition)
                    end
                end
            end
        end
    end
    return spawnPositions
end
function GameTestCaseAI.loadVehicleSetup(xmlFile, key)
    local vehicleSetup = {
        ["name"] = xmlFile:getString(key .. "#name"),
        ["zOffset"] = xmlFile:getFloat(key .. "#zOffset", 0),
        ["vehicles"] = {}
    }
    xmlFile:iterate(key .. ".vehicle", function(_, vehicleKey)
        -- upvalues: (copy) xmlFile, (copy) vehicleSetup
        local vehicle = {
            ["xmlFilename"] = xmlFile:getString(vehicleKey .. "#xmlFilename")
        }
        if vehicle.xmlFilename ~= nil then
            vehicle.xmlFilename = NetworkUtil.convertFromNetworkFilename(vehicle.xmlFilename)
            vehicle.offset = xmlFile:getVector(vehicleKey .. "#offset") or { 0, 0, 0 }
            vehicle.offset[3] = vehicle.offset[3] + vehicleSetup.zOffset
            vehicle.rotationOffset = xmlFile:getFloat(vehicleKey .. "#rotationOffset", 0)
            if vehicle.xmlFilename:startsWith("$data") then
                vehicle.xmlFilename = vehicle.xmlFilename:gsub("$data", "data")
            end
            vehicle.storeItem = g_storeManager:getItemByXMLFilename(vehicle.xmlFilename)
            if vehicle.storeItem == nil then
                vehicleSetup.isInvalid = true
                Logging.xmlWarning(xmlFile, "Unable to find store item for \'%s\'", vehicle.xmlFilename)
                return
            end
            StoreItemUtil.loadSpecsFromXML(vehicle.storeItem)
            vehicle.fillTypes = FillUnit.getSpecValueFillTypes(vehicle.storeItem, nil, nil)
            table.insert(vehicleSetup.vehicles, vehicle)
        end
    end)
    if vehicleSetup.isInvalid then
        return nil
    else
        vehicleSetup.attachments = {}
        xmlFile:iterate(key .. ".attachment", function(_, attachmentKey)
            -- upvalues: (copy) xmlFile, (copy) vehicleSetup
            local attachment = {
                ["rootVehicleId"] = xmlFile:getInt(attachmentKey .. "#rootVehicleId", 1),
                ["attachmentId"] = xmlFile:getInt(attachmentKey .. "#attachmentId", 2),
                ["jointIndex"] = xmlFile:getInt(attachmentKey .. "#jointIndex", 1),
                ["inputAttacherJointIndex"] = xmlFile:getInt(attachmentKey .. "#inputAttacherJointIndex", 1)
            }
            table.insert(vehicleSetup.attachments, attachment)
        end)
        vehicleSetup.index = 1
        if #vehicleSetup.vehicles > 0 then
            return vehicleSetup
        else
            return nil
        end
    end
end
function GameTestCaseAI.saveVehicleSetup(vehicleSetup, xmlFile, key)
    xmlFile:setString(key .. "#name", vehicleSetup.name)
    for index, vehicle in ipairs(vehicleSetup.vehicles) do
        local vehicleKey = string.format("%s.vehicle(%d)", key, index - 1)
        xmlFile:setString(vehicleKey .. "#xmlFilename", NetworkUtil.convertToNetworkFilename(vehicle.xmlFilename))
        xmlFile:setVector(vehicleKey .. "#offset", vehicle.offset)
        xmlFile:setFloat(vehicleKey .. "#rotationOffset", vehicle.rotationOffset)
    end
    for index, vehicle in ipairs(vehicleSetup.attachments) do
        local vehicleKey = string.format("%s.attachment(%d)", key, index - 1)
        xmlFile:setInt(vehicleKey .. "#rootVehicleId", vehicle.rootVehicleId)
        xmlFile:setInt(vehicleKey .. "#attachmentId", vehicle.attachmentId)
        xmlFile:setInt(vehicleKey .. "#jointIndex", vehicle.jointIndex)
        xmlFile:setInt(vehicleKey .. "#inputAttacherJointIndex", vehicle.inputAttacherJointIndex)
    end
end
function GameTestCaseAI.loadVehicleSetups(xmlFile, key)
    local vehicleSetups = {}
    xmlFile:iterate(key .. ".vehicleSetups.vehicleSetup", function(_, setupKey)
        -- upvalues: (copy) xmlFile, (copy) vehicleSetups
        local vehicleSetup = GameTestCaseAI.loadVehicleSetup(xmlFile, setupKey)
        if vehicleSetup ~= nil then
            vehicleSetup.index = #vehicleSetups + 1
            table.insert(vehicleSetups, vehicleSetup)
        end
    end)
    local categoryNames = xmlFile:getString(key .. ".vehicleSetups.random#categoryNames")
    if categoryNames ~= nil then
        local numVehicles = xmlFile:getInt(key .. ".vehicleSetups.random#numVehicles", 1)
        local categories = string.upper(categoryNames):split(" ")
        local storeItems = g_storeManager:getItems()
        local i = 1
        local index = #storeItems
        local storeItem = 1
        for i = i, index, storeItem do
            local j = 1
            for j = j, #categories do
                if storeItems[i].categoryName == categories[j] then
                    table.insert({}, storeItem)
                end
            end
        end
        while numVehicles > 0 do
            numVehicles = numVehicles - 1
            if #availableItems > 0 then
                local index = math.random(1, #availableItems)
                local storeItem = availableItems[index]
                if storeItem ~= nil and (storeItem.showInStore and not storeItem.isBundleItem) then
                    local i = {
                        ["name"] = storeItem.name,
                        ["vehicles"] = {},
                        ["attachments"] = {}
                    }
                    local storeItem = {
                        ["xmlFilename"] = storeItem.xmlFilename,
                        ["offset"] = { 0, 0, 0 },
                        ["rotationOffset"] = 0,
                        ["fillTypes"] = {},
                        ["storeItem"] = storeItem
                    }
                    StoreItemUtil.loadSpecsFromXML(storeItem.storeItem)
                    table.insert(i.vehicles, storeItem)
                    i.index = #vehicleSetups + 1
                    table.insert(vehicleSetups, i)
                end
                table.remove(availableItems, index)
            end
        end
    end
    return vehicleSetups
end
function GameTestCaseAI.generateTestCases(targetTable, xmlFile, key) end
function GameTestCaseAI.fillMetaData(xmlFile, key)
    key = key .. ".aiSystem"
    local splines = {}
    for _, roadSplineOrTG in ipairs(g_currentMission.aiSystem.roadSplines) do
        if I3DUtil.getIsSpline(roadSplineOrTG) then
            splines[roadSplineOrTG] = false
        end
        I3DUtil.iterateRecursively(roadSplineOrTG, function(node)
            -- upvalues: (copy) splines
            if I3DUtil.getIsSpline(node) then
                splines[node] = false
            end
        end)
    end
    if g_currentMission.trafficSystem ~= nil and g_currentMission.trafficSystem.rootNodeId ~= nil then
        I3DUtil.iterateRecursively(g_currentMission.trafficSystem.rootNodeId, function(node)
            -- upvalues: (copy) splines
            if I3DUtil.getIsSpline(node) then
                splines[node] = true
            end
        end)
    end
    local index = 0
    for roadSplineOrTG, isTrafficSpline in pairs(splines) do
        local splineKey = string.format("%s.splines.spline(%d)", key, index)
        local length = getSplineLength(roadSplineOrTG)
        if length > 0 then
            xmlFile:setFloat(splineKey .. "#length", length)
            xmlFile:setBool(splineKey .. "#isTrafficSpline", isTrafficSpline)
            local posIndex = 0
            local numPositions = length / 2.5
            local i = 0
            for i = i, numPositions do
                local posKey = string.format("%s.pos(%d)", splineKey, posIndex)
                local t = math.clamp(i / numPositions, 0, 1)
                xmlFile:setVector(posKey .. "#translation", { getSplinePosition(roadSplineOrTG, t) })
                posIndex = posIndex + 1
            end
        end
    end
    local unloadingStationIndex = 0
    for isTrafficSpline, splineKey in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
        if splineKey:isa(UnloadingStation) then
            local length, posIndex, numPositions, _, unloadTrigger = splineKey:getAITargetPositionAndDirection(FillType.UNKNOWN)
            if length ~= nil then
                local i, posKey, t = getWorldTranslation(unloadTrigger.aiNode)
                local dx, _, dz = localDirectionToWorld(unloadTrigger.aiNode, 0, 0, 1)
                local yRot, unloadingStationKey = MathUtil.vector2Normalize(dx, dz)
                local yRot = MathUtil.getYRotationFromDirection(yRot, unloadingStationKey)
                local unloadingStationKey = string.format("%s.unloadingStations.unloadingStation(%d)", key, unloadingStationIndex)
                xmlFile:setString(unloadingStationKey .. "#name", splineKey:getName())
                xmlFile:setVector(unloadingStationKey .. "#translation", { i, posKey, t })
                xmlFile:setFloat(unloadingStationKey .. "#rotation", (math.deg(yRot)))
                xmlFile:setString(unloadingStationKey .. "#filename", NetworkUtil.convertToNetworkFilename(splineKey.owningPlaceable.configFileName))
                unloadingStationIndex = unloadingStationIndex + 1
            end
        end
    end
    local loadingStationIndex = 0
    for splineKey, length in pairs(g_currentMission.storageSystem:getLoadingStations()) do
        local posIndex, numPositions, _, unloadTrigger, i = length:getAITargetPositionAndDirection(FillType.UNKNOWN)
        if posIndex ~= nil then
            local posKey, t, dx = getWorldTranslation(i.aiNode)
            local _, dz, yRot = localDirectionToWorld(i.aiNode, 0, 0, 1)
            local unloadingStationKey, unloadingStationKey = MathUtil.vector2Normalize(_, yRot)
            local unloadingStationKey = MathUtil.getYRotationFromDirection(unloadingStationKey, unloadingStationKey)
            local unloadingStationKey = string.format("%s.loadingStations.loadingStation(%d)", key, loadingStationIndex)
            xmlFile:setString(unloadingStationKey .. "#name", length:getName())
            xmlFile:setVector(unloadingStationKey .. "#translation", { posKey, t, dx })
            xmlFile:setFloat(unloadingStationKey .. "#rotation", (math.deg(unloadingStationKey)))
            xmlFile:setString(unloadingStationKey .. "#filename", NetworkUtil.convertToNetworkFilename(length.owningPlaceable.configFileName))
            loadingStationIndex = loadingStationIndex + 1
        end
    end
end
function GameTestCaseAI.overwriteFunctions()
    AISystem.onMissionStarted = Utils.overwrittenFunction(AISystem.onMissionStarted, function(self, superFunc, isNewSavegame)
        superFunc(self, isNewSavegame)
        local filename = g_currentMission.aiSystem:getNavigationMapFilename()
        saveVehicleNavigationCostMapToFile(g_currentMission.aiSystem.navigationMap, g_gameTestManager.currentTestFolder .. "/" .. filename)
    end)
end
function GameTestCaseAI.registerXMLPaths(schema, baseKey)
    schema:register(XMLValueType.BOOL, baseKey .. ".spawnPositions#useFieldCenter", "All field center positions will be added as spawn position", false)
    schema:register(XMLValueType.VECTOR_N, baseKey .. ".spawnPositions#includeFields", "If defined, they are the only fields used")
    schema:register(XMLValueType.VECTOR_N, baseKey .. ".spawnPositions#execludeFields", "Indices of fields to execluded")
    schema:register(XMLValueType.STRING, baseKey .. ".spawnPositions.spawnPosition(?)#name", "Custom name of the spawn position")
    schema:register(XMLValueType.VECTOR_TRANS, baseKey .. ".spawnPositions.spawnPosition(?)#translation", "World translation of the spawn position")
    schema:register(XMLValueType.VECTOR_ROT, baseKey .. ".spawnPositions.spawnPosition(?)#rotation", "World rotation of the spawn position")
    schema:register(XMLValueType.STRING, baseKey .. ".vehicleSetups.random#categoryNames", "Random vehicles of the listed categories will be spawned as single vehicle setup")
    schema:register(XMLValueType.INT, baseKey .. ".vehicleSetups.random#numVehicles", "Num. of total vehicles to spawn", 1)
    schema:register(XMLValueType.STRING, baseKey .. ".vehicleSetups.vehicleSetup(?)#name", "Custom name of the vehicle setup")
    schema:register(XMLValueType.STRING, baseKey .. ".vehicleSetups.vehicleSetup(?).vehicle(?)#xmlFilename", "Path to vehicle xml file")
    schema:register(XMLValueType.VECTOR_TRANS, baseKey .. ".vehicleSetups.vehicleSetup(?).vehicle(?)#offset", "Spawn offset from spawn position")
    schema:register(XMLValueType.ANGLE, baseKey .. ".vehicleSetups.vehicleSetup(?).vehicle(?)#rotationOffset", "Spawn Y rotation offset from spawn position", 0)
    schema:register(XMLValueType.INT, baseKey .. ".vehicleSetups.vehicleSetup(?).attachment(?)#rootVehicleId", "Index of root vehicle (as it is defined in the xml)", 1)
    schema:register(XMLValueType.INT, baseKey .. ".vehicleSetups.vehicleSetup(?).attachment(?)#attachmentId", "Index of attachment vehicle (as it is defined in the xml)", 2)
    schema:register(XMLValueType.INT, baseKey .. ".vehicleSetups.vehicleSetup(?).attachment(?)#jointIndex", "Index of the attacher joint on the root vehicle", 1)
    schema:register(XMLValueType.INT, baseKey .. ".vehicleSetups.vehicleSetup(?).attachment(?)#inputAttacherJointIndex", "Index of the input attacher joint on the attachment vehicle", 1)
end
GameTestManager.registerTestCase(GameTestCaseAI)