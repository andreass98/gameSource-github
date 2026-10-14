if StartParams.getIsSet("scriptDebug") then
    WrapFunctions = {}
    WrapFunctions.SCRIPT_BINDING_PATH = "../tools/studio/Farming_Simulator_25_Dev.xml"
    WrapFunctions.ignore = {}
    WrapFunctions.backups = {}
    local function getNamespace(functionNameStr)
        local namespaceStr = nil
        if string.contains(functionNameStr, ":", true) then
            namespaceStr, functionNameStr = unpack(string.split(functionNameStr, ":"))
        elseif string.contains(functionNameStr, ".", true) then
            namespaceStr, functionNameStr = unpack(string.split(functionNameStr, "."))
        end
        return functionNameStr, namespaceStr and _G[namespaceStr] or _G
    end
    function WrapFunctions.init()
        printWarning("Warning: function profiling / wrapping active")
        addConsoleCommand("gsFunctionWrap", "Wrap a global function with a profiling zone", "consoleCommandFunctionWrap", WrapFunctions)
        addConsoleCommand("gsFunctionWrapClass", "Wrap all functions with profiling zones", "consoleCommandFunctionWrapClass", WrapFunctions)
        addConsoleCommand("gsFunctionWrapEngine", "Wrap all engine functions with profiling zones", "consoleCommandFunctionWrapEngine", WrapFunctions)
        addConsoleCommand("gsFunctionWrapEngineCategory", "Wrap all global functions of a specific category with profiling zones", "consoleCommandFunctionWrapEngineCategory", WrapFunctions)
        addConsoleCommand("gsFunctionUnwrap", "Unwrap all functions", "consoleCommandFunctionUnwrap", WrapFunctions)
        addConsoleCommand("gsFunctionWrapVisualize", "Enable custom visualization for overlaps, raycasts, etc", "consoleCommandFunctionVisualize", WrapFunctions)
        addConsoleCommand("gsFunctionDrawTriggerCallbacks", "Draw last performed trigger callbacks on screen", "consoleCommandDrawTriggerCallbacks", WrapFunctions)
        WrapFunctions.memoryAllocations = {}
        WrapFunctions.customWrappers()
        WrapFunctions.customWrappersNetwork()
        WrapFunctions.customWrappersXML()
    end
    function WrapFunctions.consoleCommandFunctionWrap(_, ...)
        -- upvalues: (copy) getNamespace
        local numArgs = select("#", ...)
        if numArgs == 0 then
            printError("Error: no function names given\nUsage: gsFunctionWrap functionName <functionName2> ...")
        else
            local i = 1
            for i = i, numArgs do
                local funcName = select(i, ...)
                local functionNameOnly, namespaceTbl = getNamespace(funcName)
                local success, statusMessage = WrapFunctions.wrapFunction(functionNameOnly, namespaceTbl, funcName)
                if success then
                    print(string.format("%q %s", funcName, statusMessage))
                else
                    printError("Error: " .. string.format("%q %s", funcName, statusMessage))
                end
            end
        end
    end
    function WrapFunctions.consoleCommandFunctionWrapClass(_, ...)
        local numArgs = select("#", ...)
        if numArgs == 0 then
            printError("Error: no function names given\nUsage: gsFunctionWrapClass ClassName <ClassName2> ...")
        else
            local i = 1
            for i = i, numArgs do
                local className = select(i, ...)
                local success, statusMessage = WrapFunctions.wrapClass(className)
                if success then
                    print(statusMessage)
                else
                    printError("Error: " .. statusMessage)
                end
            end
        end
    end
    function WrapFunctions.consoleCommandFunctionWrapEngine()
        local numWrapped = WrapFunctions.wrapEngineFunctions()
        print(string.format("Wrapped %d functions in profiling zones", numWrapped))
    end
    function WrapFunctions.consoleCommandFunctionWrapEngineCategory(_, ...)
        if select("#", ...) == 0 then
            printError("Error: no function names given\nUsage: gsFunctionWrapEngineCategory CategoryName <CategoryName2> ...")
        else
            local numWrapped = WrapFunctions.wrapEngineFunctions(...)
            print(string.format("Wrapped %d functions in profiling zones", numWrapped))
        end
    end
    function WrapFunctions.consoleCommandFunctionUnwrap()
        local num = WrapFunctions.unwrapAll()
        if num == 0 then
            printWarning("Warning: no functions to unwrap, use one of the gsFunctionWrap* console commands to wrap function(s) in profiling zones")
        else
            print(string.format("unwrapped %d functions", num))
        end
    end
    function WrapFunctions.consoleCommandFunctionVisualize()
        WrapFunctions.customWrappersPhysics()
    end
    local debugFunctionDrawLastTriggerCallbacks = nil
    local debugFunctionDrawLastTriggerCallbacksElementId = nil
    local function string_len()
        -- upvalues: (ref) debugFunctionDrawLastTriggerCallbacksElementId, (ref) debugFunctionDrawLastTriggerCallbacks
        if debugFunctionDrawLastTriggerCallbacksElementId then
            g_debugManager:removeElementById(debugFunctionDrawLastTriggerCallbacksElementId)
            return "Disabled drawing of trigger callbacks"
        else
            if debugFunctionDrawLastTriggerCallbacks == nil then
                return "No draw function defined"
            end
            debugFunctionDrawLastTriggerCallbacksElementId = g_debugManager:addElement(debugFunctionDrawLastTriggerCallbacks)
            return "Enabled drawing of trigger callbacks"
        end
    end
    WrapFunctions.consoleCommandDrawTriggerCallbacks = string_len
    function WrapFunctions.wrapClass(className, trackMemory)
        local classTable = _G[className]
        if classTable == nil then
            return false, string.format("No global class %q", className)
        end
        local numWrapped = 0
        for k, v in pairs(classTable) do
            if type(v) == "function" then
                if WrapFunctions.wrapFunction(k, classTable, className .. "." .. k, trackMemory) then
                end
            end
        end
        return true, string.format("Wrapped %d functions for %q in profiling zones", numWrapped, className)
    end
    function WrapFunctions.wrapEngineFunctions(...)
        -- upvalues: (copy) getNamespace
        local xml = loadXMLFile("scriptBinding", WrapFunctions.SCRIPT_BINDING_PATH)
        if xml == 0 then
            return 0
        end
        print(string.format("WrapFunctions.wrapEngineFunctions(): loading script biding from %s", WrapFunctions.SCRIPT_BINDING_PATH))
        local categoryFilter = nil
        local i = 1
        local normalizedCategory = select("#", ...)
        for i = i, normalizedCategory do
            categoryFilter = categoryFilter or {}
            categoryFilter[string.upper(select(i, ...))] = true
        end
        if categoryFilter then
            print("   limit to categories: " .. table.concatKeys(categoryFilter, ", "))
        end
        local numWrapped = 0
        local normalizedCategory = 0
        local i = 1
        for normalizedCategory = normalizedCategory, getXMLNumOfElements(xml, "scriptBinding.function") - 1, i do
            local key = "scriptBinding.function(" .. normalizedCategory .. ")"
            local functionName = getXMLString(xml, key .. "#name")
            local functionCategory = getXMLString(xml, key .. "#category") or "NoCategory"
            local functionCategoryNoramlized = string.gsub(string.upper(functionCategory), " ", "")
            if WrapFunctions.ignore[functionName] == nil and (not categoryFilter or categoryFilter[functionCategoryNoramlized] ~= nil) then
                local functionNameOnly, namespaceTbl = getNamespace(functionName)
                local functionName = string.format("%s (%s)", functionName, functionCategory)
                if WrapFunctions.wrapFunction(functionNameOnly, namespaceTbl, functionName) then
                end
            end
        end
        delete(xml)
        return numWrapped
    end
    function WrapFunctions.wrapFunction(name, namespace, zoneName, trackMemory)
        local oldFunc = namespace or _G
        zoneName = zoneName or name
        local oldFunc = oldFunc[name]
        if type(oldFunc) ~= "function" then
            return false, "not a function"
        end
        local id = tostring(oldFunc) .. name
        if WrapFunctions.backups[id] ~= nil then
            printWarning(string.format("Warning: %q is already wrapped, ignoring", name))
            return false, "already wrapped"
        end
        WrapFunctions.backups[id] = { name, oldFunc, oldFunc }
        if trackMemory then
            WrapFunctions.memoryAllocations[zoneName] = WrapFunctions.memoryAllocations[zoneName] or 0
        end
        oldFunc[name] = function(...)
            -- upvalues: (copy) trackMemory, (ref) zoneName, (copy) oldFunc
            local mem = nil
            if trackMemory then
                collectgarbage("collect")
                mem = collectgarbage("count")
            end
            RemoteProfiler.zoneBeginN(zoneName)
            local ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9, ret10, ret11, ret12, ret13, ret14, ret15, ret16, ret17 = oldFunc(...)
            RemoteProfiler.zoneEnd()
            if trackMemory then
                collectgarbage("collect")
                local mem = collectgarbage("count") - mem
                WrapFunctions.memoryAllocations[zoneName] = WrapFunctions.memoryAllocations[zoneName] + mem
            end
            if ret17 == nil then
                if ret16 == nil then
                    if ret15 == nil then
                        if ret14 == nil then
                            if ret13 == nil then
                                if ret12 == nil then
                                    if ret11 == nil then
                                        if ret10 == nil then
                                            if ret9 == nil then
                                                if ret8 == nil then
                                                    if ret7 == nil then
                                                        if ret6 == nil then
                                                            if ret5 == nil then
                                                                if ret4 == nil then
                                                                    if ret3 == nil then
                                                                        if ret2 == nil then
                                                                            if ret1 == nil then
                                                                                return nil
                                                                            else
                                                                                return ret1
                                                                            end
                                                                        else
                                                                            return ret1, ret2
                                                                        end
                                                                    else
                                                                        return ret1, ret2, ret3
                                                                    end
                                                                else
                                                                    return ret1, ret2, ret3, ret4
                                                                end
                                                            else
                                                                return ret1, ret2, ret3, ret4, ret5
                                                            end
                                                        else
                                                            return ret1, ret2, ret3, ret4, ret5, ret6
                                                        end
                                                    else
                                                        return ret1, ret2, ret3, ret4, ret5, ret6, ret7
                                                    end
                                                else
                                                    return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8
                                                end
                                            else
                                                return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9
                                            end
                                        else
                                            return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9, ret10
                                        end
                                    else
                                        return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9, ret10, ret11
                                    end
                                else
                                    return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9, ret10, ret11, ret12
                                end
                            else
                                return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9, ret10, ret11, ret12, ret13
                            end
                        else
                            return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9, ret10, ret11, ret12, ret13, ret14
                        end
                    else
                        return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9, ret10, ret11, ret12, ret13, ret14, ret15
                    end
                else
                    return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9, ret10, ret11, ret12, ret13, ret14, ret15, ret16
                end
            else
                return ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8, ret9, ret10, ret11, ret12, ret13, ret14, ret15, ret16, ret17
            end
        end
        return true, "wrapped in profiling zone"
    end
    function WrapFunctions.unwrapAll()
        local num = table.size(WrapFunctions.backups)
        for _, triple in pairs(WrapFunctions.backups) do
            local funcName, env, oldFunc = unpack(triple)
            env[funcName] = oldFunc
        end
        WrapFunctions.backups = {}
        return num
    end
    local string_len = nil
    function WrapFunctions.customWrappers()
        -- upvalues: (ref) debugFunctionDrawLastTriggerCallbacks, (ref) string_len
        local lastCallbacks = {}
        debugFunctionDrawLastTriggerCallbacks = DebugFunction.new(nil, function()
            -- upvalues: (copy) lastCallbacks
            setTextColor(1, 1, 1, 1)
            for index, callbackStr in ipairs(lastCallbacks) do
                renderText(0.2, 0.72 + index * 0.012, 0.012, callbackStr)
            end
        end)
        local engine_addTrigger = addTrigger
        function addTrigger(shapeId, callbackFunctionName, callbackTarget, reportOnStay, callbackFunction)
            -- upvalues: (copy) lastCallbacks, (copy) engine_addTrigger
            if not getHasTrigger(shapeId) then
                Logging.warning("addTrigger() shape %q does not have \'trigger\' flag set", I3DUtil.getNodePath(shapeId))
                printCallstack()
            end
            local profilingZoneName = callbackFunction or (callbackTarget[callbackFunctionName] or _G[callbackFunctionName])
            if type(profilingZoneName) ~= "function" then
                Logging.error("Unable to access given trigger callback function %q", callbackFunctionName)
                printCallstack()
            end
            local callbackTargetName = ClassUtil.getClassNameByObject(callbackTarget) or (ClassUtil.getClassName(callbackTarget) or "")
            local profilingZoneName = "TriggerCallback for \'" .. getName(shapeId) .. "\' " .. callbackTargetName .. ":" .. callbackFunctionName
            local callbackTarget_inj = {}
            local function callbackFunc_inj(_, triggerId, otherId, onEnter, onLeave, onStay, ...)
                -- upvalues: (ref) lastCallbacks, (copy) callbackFunction, (copy) profilingZoneName, (copy) callbackTarget, (copy) callbackFunctionName
                local changeString = onEnter and "onEnter" or (onLeave and "onLeave" or (onStay and "onStay" or "unknown"))
                local triggerName = entityExists(triggerId) and I3DUtil.getNodePath(triggerId, nil, true) or "<triggerDeleted>"
                local otherName = entityExists(otherId) and I3DUtil.getNodePath(otherId, nil, true) or "<nodeDeleted>"
                local str = string.format("uli %d: trig: %s(%d) shape: %s(%d) %s ", g_updateLoopIndex, triggerName, triggerId, otherName, otherId, changeString)
                table.insert(lastCallbacks, 1, str)
                if #lastCallbacks > 15 then
                    table.remove(lastCallbacks)
                end
                if callbackFunction == nil then
                    RemoteProfiler.zoneBeginN(profilingZoneName)
                    RemoteProfiler.zoneText(otherName .. " (" .. otherId .. ") " .. changeString)
                    local ret = callbackTarget[callbackFunctionName](callbackTarget, triggerId, otherId, onEnter, onLeave, onStay, ...)
                    RemoteProfiler.zoneEnd()
                    return ret
                else
                    RemoteProfiler.zoneBeginN(profilingZoneName)
                    RemoteProfiler.zoneText(zoneText)
                    local ret = callbackFunction(callbackTarget, triggerId, otherId, onEnter, onLeave, onStay, ...)
                    RemoteProfiler.zoneEnd()
                    return ret
                end
            end
            callbackTarget_inj.callbackFunc_inj = callbackFunc_inj
            if callbackFunction == nil then
                return engine_addTrigger(shapeId, "callbackFunc_inj", callbackTarget_inj, reportOnStay)
            else
                return engine_addTrigger(shapeId, "callbackFunc_inj", callbackTarget_inj, reportOnStay, callbackFunc_inj)
            end
        end
        string_len = string.len
        function string.len(str)
            -- upvalues: (ref) string_len
            if type(str) == "number" then
                str = tostring(str) or str
            end
            if string_len(str) ~= utf8Strlen(str) then
                Logging.warning("string.len used on a string containing utf-8 characters: %s", str)
                printCallstack()
            end
            return string_len(str)
        end
        local string_sub = string.sub
        function string.sub(str, s, e)
            -- upvalues: (ref) string_len, (copy) string_sub
            if type(str) == "number" then
                str = tostring(str) or str
            end
            if string_len(str) ~= utf8Strlen(str) then
                Logging.warning("string.sub used on a string containing utf-8 characters: %s", str)
                printCallstack()
            end
            return string_sub(str, s, e)
        end
        local string_upper = string.upper
        function string.upper(str)
            -- upvalues: (copy) string_upper
            if type(str) == "number" then
                str = tostring(str) or str
            end
            if string_upper(str) ~= utf8ToUpper(str) then
                Logging.warning("string.upper used on a string containing utf-8 characters: %s", str)
                printCallstack()
            end
            return string_upper(str)
        end
        local string_lower = string.lower
        function string.lower(str)
            -- upvalues: (copy) string_lower
            if type(str) == "number" then
                str = tostring(str) or str
            end
            if string_lower(str) ~= utf8ToLower(str) then
                Logging.warning("string.lower used on a string containing utf-8 characters: %s", str)
                printCallstack()
            end
            return string_lower(str)
        end
        local engine_createImageOverlay = createImageOverlay
        function createImageOverlay(filename)
            -- upvalues: (copy) engine_createImageOverlay
            local overlayId = engine_createImageOverlay(filename)
            if overlayId ~= 0 and (debug ~= nil and debug.traceback ~= nil) then
                setName(overlayId, getName(overlayId) .. "\n" .. debug.traceback(nil, 2))
            end
            return overlayId
        end
        local engine_createSample = createSample
        function createSample(sampleName)
            -- upvalues: (copy) engine_createSample
            local sampleId = engine_createSample(sampleName)
            if sampleId ~= 0 and (debug ~= nil and debug.traceback ~= nil) then
                setName(sampleId, getName(sampleId) .. "\n" .. debug.traceback(nil, 2))
            end
            return sampleId
        end
        local engine_loadSample = loadSample
        function loadSample(sampleId, sampleFilename, ...)
            -- upvalues: (copy) engine_loadSample
            local success = engine_loadSample(sampleId, sampleFilename, ...)
            if success then
                setName(sampleId, sampleFilename .. getName(sampleId))
            end
            return success
        end
        local engine_loadXMLFile = loadXMLFile
        function loadXMLFile(objectName, filename)
            -- upvalues: (copy) engine_loadXMLFile
            return engine_loadXMLFile(string.format("%s - %s%s", objectName, filename, debug and "\n" .. debug.traceback(nil, 2) or ""), filename)
        end
        local engine_loadXMLFileFromMemory = loadXMLFileFromMemory
        function loadXMLFileFromMemory(objectName, xmlString)
            -- upvalues: (copy) engine_loadXMLFileFromMemory
            return engine_loadXMLFileFromMemory(string.format("%s%s", objectName, debug and "\n" .. debug.traceback(nil, 2) or ""), xmlString)
        end
        local engine_fileExists = fileExists
        function fileExists(filePath)
            -- upvalues: (copy) engine_fileExists
            if string.endsWith(filePath, ".dds") or string.endsWith(filePath, ".png") then
                Logging.warning("\'fileExists\' called on texture file which might not exist with the specific extension on a different platform, use \'textureFileExists\' instead")
                printCallstack()
            elseif string.endsWith(filePath, ".ogg") or (string.endsWith(filePath, ".wav") or string.endsWith(filePath, ".gls")) then
                Logging.warning("\'fileExists\' called on audio file which might not exist with the specific extension on a different platform, use \'audioFileExists\' instead")
                printCallstack()
            end
            return engine_fileExists(filePath)
        end
    end
    function WrapFunctions.customWrappersPhysics()
        local function debugSplitFindTest(x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, r, g, b, a)
            local zx, zy, zz = MathUtil.crossProduct(nx, ny, nz, yx, yy, yz)
            DebugUtil.drawDebugPlane(x, y, z, zx, zy, zz, yx, yy, yz, cutSizeY, cutSizeZ, r, g, b, a)
        end
        local engineFindAndRemoveSplitShapeAttachments = findAndRemoveSplitShapeAttachments
        function findAndRemoveSplitShapeAttachments(x, y, z, nx, ny, nz, yx, yy, yz, cutSizeX, cutSizeY, cutSizeZ)
            -- upvalues: (copy) debugSplitFindTest, (copy) engineFindAndRemoveSplitShapeAttachments
            debugSplitFindTest(x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, 1, 0, 0, 0.5)
            return engineFindAndRemoveSplitShapeAttachments(x, y, z, nx, ny, nz, yx, yy, yz, cutSizeX, cutSizeY, cutSizeZ)
        end
        local engineFindSplitShape = findSplitShape
        function findSplitShape(x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ)
            -- upvalues: (copy) debugSplitFindTest, (copy) engineFindSplitShape
            debugSplitFindTest(x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, 1, 0, 0, 0.5)
            local shape, minY, maxY, minZ, maxZ = engineFindSplitShape(x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ)
            if shape == nil or shape == 0 then
                Utils.renderTextAtWorldPosition(x, y, z, "findSplitShape nil", 0.02)
                return shape, minY, maxY, minZ, maxZ
            else
                Utils.renderTextAtWorldPosition(x, y, z, string.format("findSplitShape shape:%s minY:%.3f maxY:%.3f minZ:%.3f maxZ:%.3f", shape, minY, maxY, minZ, maxZ), 0.02)
                return shape, minY, maxY, minZ, maxZ
            end
        end
        local engineTestSplitShape = testSplitShape
        function testSplitShape(splitShape, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ)
            -- upvalues: (copy) debugSplitFindTest, (copy) engineTestSplitShape
            debugSplitFindTest(x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, 0, 1, 0, 0.5)
            local minY, maxY, minZ, maxZ = engineTestSplitShape(splitShape, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ)
            if minY then
                Utils.renderTextAtWorldPosition(x, y, z, string.format("testSplitShape shape:%s minY:%.3f maxY:%.3f minZ:%.3f maxZ:%.3f", splitShape, minY, maxY, minZ, maxZ), 0.02)
                return minY, maxY, minZ, maxZ
            else
                Utils.renderTextAtWorldPosition(x, y, z, "testSplitShape nil", 0.02)
                return minY, maxY, minZ, maxZ
            end
        end
        local engineRaycastClosest = raycastClosest
        function raycastClosest(x, y, z, nx, ny, nz, maxDistance, raycastFunctionCallback, targetObject, collisionMask)
            -- upvalues: (copy) engineRaycastClosest
            if not DebugUtil.isPositionInCameraRange(x, y, z, 3) then
                drawDebugArrow(x, y, z, nx * maxDistance, ny * maxDistance, nz * maxDistance, 0.3, 0.3, 0.3, 0.8, 0, 0, true)
            end
            local disallowed = nil or CollisionFlag.TERRAIN_DISPLACEMENT
            if bit32.btest(collisionMask, disallowed) then
                Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
                printCallstack()
            end
            return engineRaycastClosest(x, y, z, nx, ny, nz, maxDistance, raycastFunctionCallback, targetObject, collisionMask)
        end
        local engineRaycastAsyncClosest = raycastClosestAsync
        function raycastClosestAsync(x, y, z, nx, ny, nz, maxDistance, raycastFunctionCallback, targetObject, collisionMask)
            -- upvalues: (copy) engineRaycastAsyncClosest
            if not DebugUtil.isPositionInCameraRange(x, y, z, 3) then
                drawDebugArrow(x, y, z, nx * maxDistance, ny * maxDistance, nz * maxDistance, 0.3, 0.3, 0.3, 1, 1, 1, true)
            end
            local disallowed = nil or CollisionFlag.TERRAIN_DISPLACEMENT
            if bit32.btest(collisionMask, disallowed) then
                Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
                printCallstack()
            end
            return engineRaycastAsyncClosest(x, y, z, nx, ny, nz, maxDistance, raycastFunctionCallback, targetObject, collisionMask)
        end
        local engineRaycastAll = raycastAll
        function raycastAll(x, y, z, nx, ny, nz, maxDistance, raycastFunctionCallback, targetObject, collisionMask)
            -- upvalues: (copy) engineRaycastAll
            if not DebugUtil.isPositionInCameraRange(x, y, z, 3) then
                drawDebugArrow(x, y, z, nx * maxDistance, ny * maxDistance, nz * maxDistance, 0.3, 0.3, 0.3, 0, 0.8, 0, true)
            end
            local disallowed = nil or CollisionFlag.TERRAIN_DISPLACEMENT
            if bit32.btest(collisionMask, disallowed) then
                Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
                printCallstack()
            end
            return engineRaycastAll(x, y, z, nx, ny, nz, maxDistance, raycastFunctionCallback, targetObject, collisionMask)
        end
        local engineRaycastAllAsync = raycastAllAsync
        function raycastAllAsync(x, y, z, nx, ny, nz, maxDistance, raycastFunctionCallback, targetObject, collisionMask)
            -- upvalues: (copy) engineRaycastAllAsync
            if not DebugUtil.isPositionInCameraRange(x, y, z, 3) then
                drawDebugArrow(x, y, z, nx * maxDistance, ny * maxDistance, nz * maxDistance, 0.3, 0.3, 0.3, 0.1, 1, 0.1, true)
            end
            local disallowed = nil or CollisionFlag.TERRAIN_DISPLACEMENT
            if bit32.btest(collisionMask, disallowed) then
                Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
                printCallstack()
            end
            return engineRaycastAllAsync(x, y, z, nx, ny, nz, maxDistance, raycastFunctionCallback, targetObject, collisionMask)
        end
        local engineOverlapBox = overlapBox
        function overlapBox(x, y, z, rx, ry, rz, ex, ey, ez, callbackFunctionName, callbackTarget, collisionMask, ...)
            -- upvalues: (copy) engineOverlapBox
            DebugBox.new():createFromOverlapBoxParameters(x, y, z, rx, ry, rz, ex, ey, ez):setText("overlapBox"):addToManager(nil, 1000, 50)
            local disallowed = nil or CollisionFlag.TERRAIN_DISPLACEMENT
            if bit32.btest(collisionMask, disallowed) then
                Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
                printCallstack()
            end
            return engineOverlapBox(x, y, z, rx, ry, rz, ex, ey, ez, callbackFunctionName, callbackTarget, collisionMask, ...)
        end
        local engineOverlapBoxAsync = overlapBoxAsync
        function overlapBoxAsync(x, y, z, rx, ry, rz, ex, ey, ez, callbackFunctionName, callbackTarget, collisionMask, ...)
            -- upvalues: (copy) engineOverlapBoxAsync
            DebugBox.new():createFromOverlapBoxParameters(x, y, z, rx, ry, rz, ex, ey, ez):setText("overlapBoxAsync"):addToManager(nil, 1000, 50)
            local disallowed = nil or CollisionFlag.TERRAIN_DISPLACEMENT
            if bit32.btest(collisionMask, disallowed) then
                Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
                printCallstack()
            end
            return engineOverlapBoxAsync(x, y, z, rx, ry, rz, ex, ey, ez, callbackFunctionName, callbackTarget, collisionMask, ...)
        end
        local engineOverlapSphere = overlapSphere
        function overlapSphere(x, y, z, radius, callbackFunctionName, callbackTarget, collisionMask, ...)
            -- upvalues: (copy) engineOverlapSphere
            DebugSphere.new():createWithWorldPos(x, y, z, radius):setText("overlapSphere"):addToManager(nil, 1000, 50)
            local disallowed = nil or CollisionFlag.TERRAIN_DISPLACEMENT
            if bit32.btest(collisionMask, disallowed) then
                Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
                printCallstack()
            end
            return engineOverlapSphere(x, y, z, radius, callbackFunctionName, callbackTarget, collisionMask, ...)
        end
        local engineOverlapSphereAsync = overlapSphereAsync
        function overlapSphereAsync(x, y, z, radius, callbackFunctionName, callbackTarget, collisionMask, ...)
            -- upvalues: (copy) engineOverlapSphereAsync
            DebugSphere.new():createWithWorldPos(x, y, z, radius):setText("overlapSphereAsync"):addToManager(nil, 1000, 50)
            local disallowed = nil or CollisionFlag.TERRAIN_DISPLACEMENT
            if bit32.btest(collisionMask, disallowed) then
                Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
                printCallstack()
            end
            return engineOverlapSphereAsync(x, y, z, radius, callbackFunctionName, callbackTarget, collisionMask, ...)
        end
        local overlapCylinder_engine = overlapCylinder
        function overlapCylinder(x, y, z, radius, height, axis, callbackFunctionName, callbackTarget, collisionMask, ...)
            -- upvalues: (copy) overlapCylinder_engine
            DebugCylinder.new():createWithWorldPos(x, y, z, radius, height, axis):setText("overlapCylinder"):addToManager(nil, 1000, 50)
            local disallowed = nil or CollisionFlag.TERRAIN_DISPLACEMENT
            if bit32.btest(collisionMask, disallowed) then
                Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
                printCallstack()
            end
            return overlapCylinder_engine(x, y, z, radius, height, axis, callbackFunctionName, callbackTarget, collisionMask, ...)
        end
        local overlapCylinderAsync_engine = overlapCylinderAsync
        function overlapCylinderAsync(x, y, z, radius, height, axis, callbackFunctionName, callbackTarget, collisionMask, ...)
            -- upvalues: (copy) overlapCylinderAsync_engine
            DebugCylinder.new():createWithWorldPos(x, y, z, radius, height, axis):setText("overlapCylinder"):addToManager(nil, 1000, 50)
            local disallowed = nil or CollisionFlag.TERRAIN_DISPLACEMENT
            if bit32.btest(collisionMask, disallowed) then
                Logging.devWarning("function-call includes %s in its mask", CollisionFlag.getFlagsStringFromMask(disallowed))
                printCallstack()
            end
            return overlapCylinderAsync_engine(x, y, z, radius, height, axis, callbackFunctionName, callbackTarget, collisionMask, ...)
        end
    end
    function WrapFunctions.customWrappersNetwork()
        -- upvalues: (ref) string_len
        print("Injected network functions with bounds checks and stats collection")
        local networkStatsCollectionEnabled = false
        local networkStatsNumBits = {}
        local networkStatsNumBitsTotal = 0
        local networkStatsMaxVal = {}
        local networkStatsMaxSentVal = {}
        local target = {
            ["toggleCollection"] = function()
                -- upvalues: (ref) networkStatsCollectionEnabled
                networkStatsCollectionEnabled = not networkStatsCollectionEnabled
                log("networkStatsCollectionEnabled", networkStatsCollectionEnabled)
            end,
            ["resetStats"] = function(_, groupByFunction)
                -- upvalues: (ref) networkStatsNumBits, (ref) networkStatsNumBitsTotal, (ref) networkStatsMaxVal, (ref) networkStatsMaxSentVal
                networkStatsNumBits = {}
                networkStatsNumBitsTotal = 0
                networkStatsMaxVal = {}
                networkStatsMaxSentVal = {}
                print("reset network stats")
            end,
            ["printStats"] = function(_, groupByFunction)
                -- upvalues: (ref) networkStatsNumBits, (ref) networkStatsNumBitsTotal, (ref) networkStatsMaxSentVal, (ref) networkStatsMaxVal
                local filtered = {}
                for trace, numBits in pairs(networkStatsNumBits) do
                    if groupByFunction then
                        local trace = string.sub(trace, 1, string.findLast(trace, ":") - 1)
                    end
                    filtered[trace] = (filtered[trace] or 0) + numBits
                end
                local sorted = {}
                for numBits, numBits in pairs(filtered) do
                    table.insert(sorted, { numBits, numBits })
                end
                table.sort(sorted, function(a, b)
                    return a[2] > b[2]
                end)
                print("")
                setFileLogPrefixTimestamp(false)
                print("total bits send by function (integer, float and string network stream functions only):")
                for numBits, numBits in ipairs(sorted) do
                    local bits = numBits[2]
                    print(string.format("%10d %.3f%% %s", bits, bits / networkStatsNumBitsTotal * 100, numBits[1]))
                end
                print("")
                print("max value send by function (number network stream functions only)")
                for numBits, numBits in pairs(networkStatsMaxSentVal) do
                    local bits = networkStatsMaxVal[numBits]
                    print(string.format("%s, %d/%d, %.2f%%", numBits, numBits, bits, numBits / bits * 100))
                end
                setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
            end
        }
        addConsoleCommand("gsNetworkStatsPrint", "print network traffic stats", "printStats", target, "[groupByFunction=false]")
        addConsoleCommand("gsNetworkStatsReset", "reset network traffic stats", "resetStats", target)
        addConsoleCommand("gsNetworkStatsToggle", "toggle network traffic stats collection", "toggleCollection", target)
        local function storeStats(bits, value, maxValue)
            -- upvalues: (ref) networkStatsCollectionEnabled, (ref) networkStatsNumBits, (ref) networkStatsNumBitsTotal, (ref) networkStatsMaxVal, (ref) networkStatsMaxSentVal
            if networkStatsCollectionEnabled then
                local trace = string.format("%s:%s:%d", debug.info(3, "snl"))
                if string.contains(trace, "NetworkUtil") then
                    trace = string.format("%s:%s:%d", debug.info(4, "snl"))
                end
                networkStatsNumBits[trace] = (networkStatsNumBits[trace] or 0) + bits
                if value ~= nil and type(value) == "number" then
                    networkStatsMaxVal[trace] = maxValue
                    networkStatsMaxSentVal[trace] = math.max(networkStatsMaxSentVal[trace] or 0, value)
                end
            end
        end
        local engineStreamWriteInt16 = streamWriteInt16
        function streamWriteInt16(streamId, value)
            -- upvalues: (copy) storeStats, (copy) engineStreamWriteInt16
            if value ~= nil and (value > 32767 or value < -65536) then
                Logging.error("value %d out of bounds", value)
                printCallstack()
            end
            storeStats(16, value, 32767)
            return engineStreamWriteInt16(streamId, value)
        end
        local engineStreamWriteInt32 = streamWriteInt32
        function streamWriteInt32(streamId, value)
            -- upvalues: (copy) storeStats, (copy) engineStreamWriteInt32
            if value ~= nil and (value > 2147483647 or value < -2147483648) then
                Logging.error("value %d out of bounds", value)
                printCallstack()
            end
            storeStats(32, value, 2147483647)
            return engineStreamWriteInt32(streamId, value)
        end
        local engineStreamWriteInt8 = streamWriteInt8
        function streamWriteInt8(streamId, value)
            -- upvalues: (copy) storeStats, (copy) engineStreamWriteInt8
            if value ~= nil and (value > 127 or value < -128) then
                Logging.error("value %d out of bounds", value)
                printCallstack()
            end
            storeStats(8, value, 127)
            return engineStreamWriteInt8(streamId, value)
        end
        local engineStreamWriteIntN = streamWriteIntN
        function streamWriteIntN(streamId, value, numBits)
            -- upvalues: (copy) storeStats, (copy) engineStreamWriteIntN
            if value ~= nil and (numBits ~= nil and (2 ^ (numBits - 1) - 1 < value or value < -2 ^ (numBits - 1))) then
                Logging.error("value %d out of bounds (%d bits, %d max)", value, numBits, 2 ^ (numBits - 1) - 1)
                printCallstack()
            end
            storeStats(numBits, value, 2 ^ (numBits - 1) - 1)
            return engineStreamWriteIntN(streamId, value, numBits)
        end
        local engineStreamWriteUInt16 = streamWriteUInt16
        function streamWriteUInt16(streamId, value)
            -- upvalues: (copy) storeStats, (copy) engineStreamWriteUInt16
            if value ~= nil and (value > 65535 or value < 0) then
                Logging.error("value %d out of bounds", value)
                printCallstack()
            end
            storeStats(16, value, 65535)
            return engineStreamWriteUInt16(streamId, value)
        end
        local engineStreamWriteUInt32 = streamWriteUInt32
        function streamWriteUInt32(streamId, value)
            -- upvalues: (copy) storeStats, (copy) engineStreamWriteUInt32
            if value ~= nil and (value > 4294967295 or value < 0) then
                Logging.error("value %d out of bounds", value)
                printCallstack()
            end
            storeStats(32, value, 4294967295)
            return engineStreamWriteUInt32(streamId, value)
        end
        local engineStreamWriteUInt8 = streamWriteUInt8
        function streamWriteUInt8(streamId, value)
            -- upvalues: (copy) storeStats, (copy) engineStreamWriteUInt8
            if value ~= nil and (value > 255 or value < 0) then
                Logging.error("value %d out of bounds", value)
                printCallstack()
            end
            storeStats(8, value, 255)
            return engineStreamWriteUInt8(streamId, value)
        end
        local engineStreamWriteUIntN = streamWriteUIntN
        function streamWriteUIntN(streamId, value, numBits)
            -- upvalues: (copy) storeStats, (copy) engineStreamWriteUIntN
            if value ~= nil and (numBits ~= nil and (2 ^ numBits - 1 < value or value < 0)) then
                Logging.error("value %d out of bounds (%d bits, %d max)", value, numBits, 2 ^ numBits - 1)
                printCallstack()
            end
            storeStats(numBits, value, 2 ^ numBits - 1)
            return engineStreamWriteUIntN(streamId, value, numBits)
        end
        local engineStreamWriteFloat32 = streamWriteFloat32
        function streamWriteFloat32(streamId, value)
            -- upvalues: (copy) storeStats, (copy) engineStreamWriteFloat32
            storeStats(32, value, 1000000000)
            return engineStreamWriteFloat32(streamId, value)
        end
        local engineStreamWriteString = streamWriteString
        function streamWriteString(streamId, value)
            -- upvalues: (copy) storeStats, (ref) string_len, (copy) engineStreamWriteString
            storeStats((string_len or string.len)(value) * 8)
            return engineStreamWriteString(streamId, value)
        end
    end
    function WrapFunctions.customWrappersXML()
        print("Injected XML functions checks")
        local engine_setXMLInt = setXMLInt
        function setXMLInt(xmlFile, path, value)
            -- upvalues: (copy) engine_setXMLInt
            if value ~= nil then
                if value > 2147483647 or value < -2147483648 then
                    Logging.xmlError(xmlFile, "value %d out of bounds", value)
                    printCallstack()
                end
                if not MathUtil.isInt(value) and math.abs(value) < 100 then
                    Logging.xmlError(xmlFile, "float %.3f value written as int, is this intentional?", value)
                    printCallstack()
                end
            end
            return engine_setXMLInt(xmlFile, path, value)
        end
        local engine_setXMLUInt = setXMLUInt
        function setXMLUInt(xmlFile, path, value)
            -- upvalues: (copy) engine_setXMLUInt
            if value ~= nil then
                if value < 0 then
                    Logging.xmlError(xmlFile, "negative value %f passed to setXMLUInt for %q", value, path)
                    printCallstack()
                end
                if not MathUtil.isInt(value) and value < 100 then
                    Logging.xmlError(xmlFile, "float %.3f value written as int in %q, is this intentional?", value, path)
                    printCallstack()
                end
            end
            return engine_setXMLUInt(xmlFile, path, value)
        end
        local engine_getXMLBool = getXMLBool
        function getXMLBool(xmlFile, path)
            -- upvalues: (copy) engine_getXMLBool
            local strVal = getXMLString(xmlFile, path)
            if strVal ~= nil and (strVal ~= "true" and strVal ~= "false") then
                Logging.xmlError(xmlFile, "trying to load malformed xml boolean value %q from %q", strVal, path)
                printCallstack()
            end
            return engine_getXMLBool(xmlFile, path)
        end
        local engine_getXMLInt = getXMLInt
        function getXMLInt(xmlFile, path)
            -- upvalues: (copy) engine_getXMLInt
            local strVal = getXMLString(xmlFile, path)
            if strVal ~= nil then
                local numberVal = tonumber(strVal)
                if numberVal == nil then
                    Logging.xmlError(xmlFile, "trying to load malformed xml number value %q from %q", strVal, path)
                    printCallstack()
                elseif not MathUtil.isInt(numberVal) then
                    Logging.xmlError(xmlFile, "trying to load float value %q as integer from %q in %q", strVal, path)
                    printCallstack()
                end
            end
            return engine_getXMLInt(xmlFile, path)
        end
        local engine_getXMLUInt = getXMLUInt
        function getXMLUInt(xmlFile, path)
            -- upvalues: (copy) engine_getXMLUInt
            local strVal = getXMLString(xmlFile, path)
            if strVal ~= nil then
                local numberVal = tonumber(strVal)
                if numberVal == nil then
                    Logging.xmlError(xmlFile, "trying to load malformed xml number value %q from %q in %q", strVal, path)
                    printCallstack()
                elseif not MathUtil.isInt(numberVal) then
                    Logging.xmlError(xmlFile, "trying to load float value %q as integer from %q in %q", strVal, path)
                    printCallstack()
                end
            end
            return engine_getXMLUInt(xmlFile, path)
        end
        local engine_getXMLFloat = getXMLFloat
        function getXMLFloat(xmlFile, path)
            -- upvalues: (copy) engine_getXMLFloat
            local strVal = getXMLString(xmlFile, path)
            if strVal ~= nil and tonumber(strVal) == nil then
                Logging.xmlError(xmlFile, "trying to load malformed xml number value %q from %q", strVal, path)
                printCallstack()
            end
            return engine_getXMLFloat(xmlFile, path)
        end
    end
end