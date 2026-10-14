I3DManager = {}
I3DManager.VERBOSE_LOADING = true
I3DManager.DEBUG_LOADING_CHECKS = {}
local I3DManager_mt = Class(I3DManager)
function I3DManager.new(customMt)
    -- upvalues: (copy) I3DManager_mt
    local self = setmetatable({}, customMt or I3DManager_mt)
    addConsoleCommand("gsI3DLoadingDelaySet", "Sets loading delay for i3d files", "consoleCommandSetLoadingDelay", self, "minDelaySec; [maxDelaySec]; [minDelayCachedSec]; [maxDelayCachedSec]")
    addConsoleCommand("gsI3DCacheShow", "Show active i3d cache", "consoleCommandShowCache", self)
    addConsoleCommand("gsI3DPrintActiveLoadings", "Print active loadings", "consoleCommandPrintActiveLoadings", self)
    return self
end
function I3DManager:init()
    local loadingDelay = tonumber(StartParams.getValue("i3dLoadingDelay"))
    if loadingDelay ~= nil and loadingDelay > 0 then
        CaptionUtil.addText("- I3D Delay (" .. loadingDelay .. "ms)")
        self:setLoadingDelay(loadingDelay / 1000)
    end
    if StartParams.getIsSet("scriptDebug") then
        self:setupDebugLoading()
    end
end
function I3DManager:drawDebug()
    if I3DManager.showCache then
        local profilePath = getUserProfileAppPath()
        local numSharedI3ds = getNumOfSharedI3DFiles()
        local data = table.create(numSharedI3ds)
        local i = 0
        local posX = numSharedI3ds - 1
        local posY = 1
        for i = i, posX, posY do
            local filename, numRefs = getSharedI3DFilesData(i)
            table.insert(data, {
                ["filename"] = string.gsub(filename, profilePath, ""),
                ["numRefs"] = numRefs
            })
        end
        table.sort(data, function(a, b)
            return a.filename < b.filename
        end)
        local posX = 0.01
        local posY = 0.99
        for _, item in ipairs(data) do
            setTextAlignment(RenderText.ALIGN_LEFT)
            renderText(posX, posY, 0.01, "Refcount: " .. tostring(item.numRefs))
            renderText(posX + 0.04, posY, 0.01, "File: " .. tostring(item.filename))
            posY = posY - 0.011
            if posY < 0 then
                posY = 0.99
            end
        end
    end
end
function I3DManager.loadSharedI3DFile(_, filename, callOnCreate, addToPhysics)
    local node = Utils.getNoNil(callOnCreate, false)
    local node = Utils.getNoNil(addToPhysics, false)
    local node, sharedLoadRequestId, failedReason = loadSharedI3DFile(filename, node, node, I3DManager.VERBOSE_LOADING)
    return node, sharedLoadRequestId, failedReason
end
function I3DManager:loadSharedI3DFileAsync(filename, callOnCreate, addToPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
    assert(filename ~= nil, "I3DManager:loadSharedI3DFileAsync - missing filename")
    assert(asyncCallbackFunction ~= nil, "I3DManager:loadSharedI3DFileAsync - missing callback function")
    assert(type(asyncCallbackFunction) == "function", "I3DManager:loadSharedI3DFileAsync - Callback value is not a function")
    local arguments = Utils.getNoNil(callOnCreate, false)
    local arguments = Utils.getNoNil(addToPhysics, false)
    return streamSharedI3DFile(filename, "loadSharedI3DFileAsyncFinished", self, {
        ["asyncCallbackFunction"] = asyncCallbackFunction,
        ["asyncCallbackObject"] = asyncCallbackObject,
        ["asyncCallbackArguments"] = asyncCallbackArguments
    }, arguments, arguments, I3DManager.VERBOSE_LOADING)
end
function I3DManager.loadSharedI3DFileAsyncFinished(_, nodeId, failedReason, arguments)
    arguments.asyncCallbackFunction(arguments.asyncCallbackObject, nodeId, failedReason, arguments.asyncCallbackArguments)
end
function I3DManager.loadI3DFile(_, filename, callOnCreate, addToPhysics)
    local node = Utils.getNoNil(callOnCreate, false)
    local node = Utils.getNoNil(addToPhysics, false)
    return loadI3DFile(filename, node, node, I3DManager.VERBOSE_LOADING)
end
function I3DManager:loadI3DFileAsync(filename, callOnCreate, addToPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
    assert(filename ~= nil, "I3DManager:loadI3DFileAsync - missing filename")
    assert(asyncCallbackFunction ~= nil, "I3DManager:loadI3DFileAsync - missing callback function")
    assert(type(asyncCallbackFunction) == "function", "I3DManager:loadI3DFileAsync - Callback value is not a function")
    local arguments = Utils.getNoNil(callOnCreate, false)
    local arguments = Utils.getNoNil(addToPhysics, false)
    return streamI3DFile(filename, "loadSharedI3DFileFinished", self, {
        ["asyncCallbackFunction"] = asyncCallbackFunction,
        ["asyncCallbackObject"] = asyncCallbackObject,
        ["asyncCallbackArguments"] = asyncCallbackArguments
    }, arguments, arguments, I3DManager.VERBOSE_LOADING)
end
function I3DManager.loadSharedI3DFileFinished(_, nodeId, failedReason, arguments)
    arguments.asyncCallbackFunction(arguments.asyncCallbackObject, nodeId, failedReason, arguments.asyncCallbackArguments)
end
function I3DManager.cancelStreamI3DFile(_, loadingRequestId)
    if loadingRequestId == nil then
        Logging.error("I3DManager:cancelStreamedI3dFile - loadingRequestId is nil")
        printCallstack()
    else
        cancelStreamI3DFile(loadingRequestId)
    end
end
function I3DManager.releaseSharedI3DFile(_, sharedLoadRequestId, warnIfInvalid)
    if sharedLoadRequestId == nil then
        Logging.error("I3DManager:releaseSharedI3DFile - sharedLoadRequestId is nil")
        printCallstack()
    else
        warnIfInvalid = Utils.getNoNil(warnIfInvalid, false)
        local _ = g_isDevelopmentVersion
        releaseSharedI3DFile(sharedLoadRequestId, warnIfInvalid)
    end
end
function I3DManager.pinSharedI3DFileInCache(_, filename)
    if filename == nil then
        Logging.error("I3DManager:pinSharedI3DFileInCache - Filename is nil")
        printCallstack()
    elseif getSharedI3DFileRefCount(filename) < 0 then
        pinSharedI3DFileInCache(filename, true)
        return
    end
end
function I3DManager.unpinSharedI3DFileInCache(_, filename)
    if filename == nil then
        Logging.error("I3DManager:unpinSharedI3DFileInCache - filename is nil")
        printCallstack()
    else
        unpinSharedI3DFileInCache(filename)
    end
end
function I3DManager.clearEntireSharedI3DFileCache(_, verbose)
    if verbose == true then
        local numSharedI3ds = getNumOfSharedI3DFiles()
        Logging.devInfo("I3DManager: Deleting %s shared i3d files", numSharedI3ds)
        local i = 0
        for i = i, numSharedI3ds - 1 do
            local filename, numRefs = getSharedI3DFilesData(i)
            Logging.devWarning("    NumRef: %d - File: %s", numRefs, filename)
        end
    end
    Logging.devInfo("I3DManager: Deleted shared i3d files")
    clearEntireSharedI3DFileCache()
end
function I3DManager.setLoadingDelay(_, minDelaySeconds, maxDelaySeconds, minDelayCachedSeconds, maxDelayCachedSeconds)
    minDelaySeconds = minDelaySeconds or 0
    maxDelaySeconds = maxDelaySeconds or minDelaySeconds
    minDelayCachedSeconds = minDelayCachedSeconds or minDelaySeconds
    maxDelayCachedSeconds = maxDelayCachedSeconds or maxDelaySeconds
    setStreamI3DFileDelay(minDelaySeconds, maxDelaySeconds)
    setStreamSharedI3DFileDelay(minDelaySeconds, maxDelaySeconds, minDelayCachedSeconds, maxDelayCachedSeconds)
    Logging.info("Set new loading delay. MinDelay: %.2fs, MaxDelay: %.2fs, MinDelayCached: %.2fs, MaxDelayCached: %.2fs", minDelaySeconds, maxDelaySeconds, minDelayCachedSeconds, maxDelayCachedSeconds)
end
function I3DManager:consoleCommandSetLoadingDelay(minDelaySec, maxDelaySec, minDelayCachedSec, maxDelayCachedSec)
    minDelaySec = tonumber(minDelaySec) or 0
    maxDelaySec = tonumber(maxDelaySec) or minDelaySec
    self:setLoadingDelay(minDelaySec, maxDelaySec, tonumber(minDelayCachedSec) or minDelaySec, tonumber(maxDelayCachedSec) or maxDelaySec)
end
function I3DManager:consoleCommandShowCache()
    I3DManager.showCache = not I3DManager.showCache
    if g_debugManager ~= nil then
        if I3DManager.showCache then
            g_debugManager:addDrawable(self)
        else
            g_debugManager:removeDrawable(self)
        end
    end
    print("showCache=" .. tostring(I3DManager.showCache))
end
function I3DManager:consoleCommandPrintActiveLoadings()
    print("Non-Shared loading tasks:")
    local loadingRequestIds = getAllStreamI3DFileRequestIds()
    if #loadingRequestIds == 0 then
        print("none")
    else
        for k, loadingRequestId in ipairs(loadingRequestIds) do
            local progress, timeSec, filename, callback, target, args = getStreamI3DFileProgressInfo(loadingRequestId)
            local text = string.format("%03d: Progress: %s | Time %.3fs | File: %s | Callback: %s | Target: %s | Args: %s", loadingRequestId, progress, timeSec, filename, callback, tostring(target), (tostring(args)))
            print(text)
        end
    end
    print("")
    print("Shared loading tasks:")
    local sharedLoadingRequestIds = getAllSharedI3DFileRequestIds()
    if #sharedLoadingRequestIds == 0 then
        print("none")
    else
        for loadingRequestId, progress in ipairs(sharedLoadingRequestIds) do
            local timeSec, filename, callback, target, args, text = getSharedI3DFileProgressInfo(progress)
            local text = string.format("%03d: Progress: %s | Time %.3fs | File: %s | Callback: %s | Target: %s | Args: %s", progress, timeSec, filename, callback, target, tostring(args), (tostring(text)))
            print(text)
        end
    end
end
g_i3DManager = I3DManager.new()
function I3DManager.addDebugLoadingCheck(name, checkFunc)
    if StartParams and StartParams.getIsSet("scriptDebug") then
        table.insert(I3DManager.DEBUG_LOADING_CHECKS, {
            ["checkFunc"] = checkFunc,
            ["name"] = name
        })
    end
end
function I3DManager:setupDebugLoading()
    printWarning("\n\n  ##################   Warning: I3D-Manager Debug checks are active!   ##################\n\n")
    self.debugTracingActive = StartParams.getIsSet("i3dTracing")
    if self.debugTracingActive then
        printWarning("\n\n  ##################   Warning: I3D-Manager Debug tracing is active !   ##################\n\n")
        self.debugPendingRequests = {}
    end
    local function checkRequestIdIsValid(callbackName, nodeId, failedReason, arguments)
        -- upvalues: (copy) self
        log(callbackName, "requestId", arguments.loadRequestId, arguments.filename, "nodeId", nodeId, "failedReason", I3DManager.getFailedReasonName(failedReason), "updateLoopIndex", g_updateLoopIndex)
        local requestId = arguments.loadRequestId
        print("    pendingRequestIds (including current callback): " .. table.concat(self.debugPendingRequests, " "))
        if not table.removeElement(self.debugPendingRequests, requestId) then
            printError(string.format("    Error: unable to remove requestId %d from pendingRequests, no pending request for this id", requestId))
        end
        if #self.debugPendingRequests == 0 then
            print("    no more pending requests")
        end
    end
    function I3DManager.checkRecursive(filename, node, delegate)
        local numMatches = 0
        if delegate(filename, node) then
        end
        local i = 0
        for i = i, getNumOfChildren(node) - 1 do
            numMatches = numMatches + I3DManager.checkRecursive(filename, getChildAt(node, i), delegate)
        end
        return numMatches
    end
    local function runDebugChecksOnNode(filename, nodeId)
        if nodeId > 0 then
            for _, data in ipairs(I3DManager.DEBUG_LOADING_CHECKS) do
                local numMatches = I3DManager.checkRecursive(filename, nodeId, data.checkFunc)
                if numMatches > 0 then
                    Logging.devInfo("Finished \'%s\' check with %d matches for \'%s\'", data.name, numMatches, filename or "")
                end
            end
        end
    end
    local oldLoadI3DFile = loadI3DFile
    function loadI3DFile(filename, ...)
        -- upvalues: (copy) oldLoadI3DFile, (copy) runDebugChecksOnNode
        local nodeId, _, _ = oldLoadI3DFile(filename, ...)
        runDebugChecksOnNode(filename, nodeId)
        return nodeId
    end
    local oldLoadSharedI3dFile = loadSharedI3DFile
    function loadSharedI3DFile(filename, ...)
        -- upvalues: (copy) oldLoadSharedI3dFile, (copy) runDebugChecksOnNode
        local nodeId, sharedLoadRequestId, failedReason = oldLoadSharedI3dFile(filename, ...)
        runDebugChecksOnNode(filename, nodeId)
        return nodeId, sharedLoadRequestId, failedReason
    end
    local oldStreamI3DFile = streamI3DFile
    function streamI3DFile(filename, callbackFunc, target, params, ...)
        -- upvalues: (copy) oldStreamI3DFile, (copy) self
        local arguments = {
            ["target"] = target,
            ["callbackFunc"] = callbackFunc,
            ["params"] = params,
            ["filename"] = filename
        }
        local loadRequestId = oldStreamI3DFile(filename, "streamI3DCallback_injection", I3DManager, arguments, ...)
        if self.debugTracingActive then
            log("streamI3DFile", "requestId", loadRequestId, filename, "callback", arguments.callbackFunc, "updateLoopIndex", g_updateLoopIndex)
            arguments.filename = filename
            arguments.loadRequestId = loadRequestId
            table.insert(self.debugPendingRequests, loadRequestId)
        end
        return loadRequestId
    end
    function I3DManager.streamI3DCallback_injection(_, nodeId, failedReason, arguments)
        -- upvalues: (copy) self, (copy) checkRequestIdIsValid, (copy) runDebugChecksOnNode
        local target = arguments.target
        if self.debugTracingActive then
            checkRequestIdIsValid("streamI3DCallback", nodeId, failedReason, arguments)
        end
        runDebugChecksOnNode(arguments.filename, nodeId)
        target[arguments.callbackFunc](target, nodeId, failedReason, arguments.params or {})
    end
    local oldStreamSharedI3DFile = streamSharedI3DFile
    function streamSharedI3DFile(filename, callbackFunc, target, params, ...)
        -- upvalues: (copy) oldStreamSharedI3DFile, (copy) self
        local arguments = {
            ["target"] = target,
            ["callbackFunc"] = callbackFunc,
            ["filename"] = filename,
            ["params"] = params
        }
        local loadRequestId = oldStreamSharedI3DFile(filename, "streamSharedI3DCallback_injection", I3DManager, arguments, ...)
        if self.debugTracingActive then
            log("streamSharedI3DFile", "requestId", loadRequestId, filename, "callback", arguments.callbackFunc, "updateLoopIndex", g_updateLoopIndex)
            arguments.filename = filename
            arguments.loadRequestId = loadRequestId
            table.insert(self.debugPendingRequests, loadRequestId)
        end
        return loadRequestId
    end
    function I3DManager.streamSharedI3DCallback_injection(_, nodeId, failedReason, arguments)
        -- upvalues: (copy) self, (copy) checkRequestIdIsValid, (copy) runDebugChecksOnNode
        local target = arguments.target
        if self.debugTracingActive then
            checkRequestIdIsValid("streamSharedI3DCallback", nodeId, failedReason, arguments)
        end
        runDebugChecksOnNode(arguments.filename, nodeId)
        target[arguments.callbackFunc](target, nodeId, failedReason, arguments.params or {})
    end
    if self.debugTracingActive then
        local oldCancelStreamI3DFile = cancelStreamI3DFile
        function cancelStreamI3DFile(loadingRequestId)
            -- upvalues: (copy) self, (copy) oldCancelStreamI3DFile
            log("cancelStreamI3DFile", loadingRequestId, "updateLoopIndex", g_updateLoopIndex)
            table.removeElement(self.debugPendingRequests, loadingRequestId)
            return oldCancelStreamI3DFile(loadingRequestId)
        end
        local oldReleaseSharedI3DFile = releaseSharedI3DFile
        function releaseSharedI3DFile(loadingRequestId, ...)
            -- upvalues: (copy) self, (copy) oldReleaseSharedI3DFile
            log("releaseSharedI3DFile", loadingRequestId, "updateLoopIndex", g_updateLoopIndex)
            if getSharedI3DFileProgressInfo(loadingRequestId) ~= "PROGRESS_UNKNOWN" then
                printWarning("    releaseSharedI3DFile while request was still pending, same effect as cancelStreamI3DFile")
                table.removeElement(self.debugPendingRequests, loadingRequestId)
            end
            return oldReleaseSharedI3DFile(loadingRequestId, ...)
        end
    end
end
function I3DManager.getFailedReasonName(failedReason)
    for failedReasonName, value in pairs(LoadI3DFailedReason) do
        if value == failedReason then
            return failedReasonName
        end
    end
    return string.format("<undefined failedReason \'%d\'>", failedReason)
end
I3DManager.addDebugLoadingCheck("Directional-Lights", function(_, node)
    if not getHasClassId(node, ClassIds.LIGHT_SOURCE) or (g_currentMission == nil or (getLightType(node) ~= LightType.DIRECTIONAL or node == g_currentMission.environment.lighting.sunLightId)) then
        return false
    end
    if getName(node) == "licensePlateCreationBoxLight" then
        return false
    end
    if getName(node) == "colorPickerOverlayDirectionalLight" then
        return false
    end
    Logging.devWarning("    Light-Check: Found directional light \'%s\'", I3DUtil.getNodePath(node))
    return true
end)
I3DManager.addDebugLoadingCheck("Collision mask check", function(_, node)
    if getHasClassId(node, ClassIds.SHAPE) and getHasCollision(node) then
        local rbt = getRigidBodyType(node)
        if rbt == RigidBodyType.NONE then
            return false
        end
        local group = getCollisionFilterGroup(node)
        if rbt ~= RigidBodyType.DYNAMIC then
            if bit32.btest(group, CollisionFlag.DYNAMIC_OBJECT) and g_currentMission:getNodeObject(node) == nil then
                Logging.i3dWarning(node, "non-dynamic collision has \'DYNAMIC_OBJECT\' collision group bit set")
                return true
            end
        end
    end
    return false
end)
I3DManager.addDebugLoadingCheck("tip col properties", function(_, node)
    local hasError = false
    if getHasClassId(node, ClassIds.SHAPE) then
        local namedTipCol = string.contains(string.upper(getName(node)), "TIPCOL")
        if namedTipCol then
            if not CollisionFlag.getHasGroupFlagSet(node, CollisionFlag.GROUND_TIP_BLOCKING) then
                Logging.devWarning("node is named tipcol but does not have %s set: %s", CollisionFlag.getBitAndName(CollisionFlag.GROUND_TIP_BLOCKING), I3DUtil.getNodePath(node))
                hasError = true
            end
            if getRigidBodyType(node) ~= RigidBodyType.STATIC then
                Logging.devWarning("tip col not static %s", I3DUtil.getNodePath(node))
                hasError = true
            end
        end
        if CollisionFlag.getHasGroupFlagSet(node, CollisionFlag.GROUND_TIP_BLOCKING) then
            if namedTipCol then
                local rigidBodyType = getRigidBodyType(node)
                if rigidBodyType ~= RigidBodyType.STATIC then
                    Logging.devWarning("node %q has tip col flag but is not STATIC but %s", I3DUtil.getNodePath(node), EnumUtil.getName(RigidBodyType, rigidBodyType))
                    hasError = true
                end
                if getCollisionFilterMask(node) ~= 1 then
                    Logging.devWarning("node %q has tip col flag mask is not 1", I3DUtil.getNodePath(node))
                    hasError = true
                end
                if CollisionFlag.getHasGroupFlagSet(node, CollisionFlag.STATIC_OBJECT) then
                    Logging.devWarning("node %q has STATIC_OBJECT flag set", I3DUtil.getNodePath(node))
                    hasError = true
                end
            end
            local i = 0
            local rigidBodyType = getNumOfUserAttributes(node) - 1
            for i = i, rigidBodyType do
                local _val, uaName, uaType = getUserAttributeByIndex(node, i)
                if uaName == "collisionHeight" and uaType ~= UserAttributeType.FLOAT then
                    Logging.devWarning("node %q has tip col flag with user attribute %q of wrong type %q. Only \'collisionHeight\' of type \'Float\' is supported", I3DUtil.getNodePath(node), uaName, EnumUtil.getName(UserAttributeType, uaType))
                    hasError = true
                end
            end
        end
    end
    return hasError
end)
I3DManager.addDebugLoadingCheck("LOD Checks", function(_, node)
    if not (getIsLODTransformGroup(node) and getVisibility(node)) then
        return false
    end
    local hadErrors = false
    for _, lodChild in I3DUtil.iteratorChildren(node) do
        if not (getVisibility(lodChild) or getHasClassId(lodChild, ClassIds.SHAPE) and getIsNonRenderable(lodChild)) then
            Logging.devWarning("LOD is hidden - Node: %s   NodeIndex: %s", I3DUtil.getNodePath(lodChild), I3DUtil.getNodePathIndices(lodChild))
            hadErrors = true
        end
    end
    return hadErrors
end)
I3DManager.addDebugLoadingCheck("Occluder Checks", function(_, node)
    if getHasClassId(node, ClassIds.SHAPE) then
        local nodeName = getName(node)
        local isOccluderMesh = getIsOccluderMesh(node)
        local isNamedOccluder = string.contains(utf8ToUpper(nodeName), "OCCLUDER")
        if isNamedOccluder or isOccluderMesh then
            local hasErrors = false
            if isNamedOccluder and not isOccluderMesh then
                Logging.devWarning("Mesh is named occluder but does not have the occluder mesh flag set - Node: %s", I3DUtil.getNodePath(node))
                hasErrors = true
            elseif not isNamedOccluder and isOccluderMesh then
                Logging.devWarning("Mesh has occluder flag set but is not named \'occluder\' - Node: %s", I3DUtil.getNodePath(node))
                hasErrors = true
            end
            if isOccluderMesh then
                if not (getVisibility(node) and getVisibility(getParent(node))) then
                    Logging.devWarning("Occluder mesh (or any of its parent nodes) is not visible and will not function. Use \'non-renderable\' flag for hiding the shape instead - Node: %s", I3DUtil.getNodePath(node))
                    hasErrors = true
                end
                local _, _, _, boundingRadius = getShapeBoundingSphere(node)
                if boundingRadius < 3 then
                    Logging.devWarning("Occluder is very small and should probably be removed, bounding radius %.3f - Node: %s", boundingRadius, I3DUtil.getNodePath(node))
                    hasErrors = true
                end
            end
            return hasErrors
        end
    end
    return false
end)
I3DManager.addDebugLoadingCheck("ScaledTrees", function(_, node)
    local hasErrors = false
    if getHasClassId(node, ClassIds.MESH_SPLIT_SHAPE) then
        local parent = getParent(node)
        if parent ~= 0 then
            local x, y, z = getScale(parent)
            if x ~= 1 or (y ~= 1 or z ~= 1) then
                Logging.devWarning("Scaled tree shape found - Node: %s (%s)", I3DUtil.getNodePath(node), I3DUtil.getNodePathIndices(node))
                hasErrors = true
            end
        end
    end
    return hasErrors
end)
I3DManager.addDebugLoadingCheck("TerrainDecal", function(_, node)
    if not (getHasClassId(node, ClassIds.SHAPE) and getIsTerrainDecal(node)) then
        return false
    end
    local hasError = false
    if not getIsNonRenderable(node) and getIsRenderedInViewports(node) then
        Logging.devWarning("Terrain decal without nonRenderable==true or getIsRenderedInViewports==false - Node: %s", I3DUtil.getNodePath(node))
        hasError = true
    end
    if getRigidBodyType(node) ~= RigidBodyType.NONE then
        local allowedMask = bit32.bor(CollisionFlag.AI_BLOCKING, CollisionFlag.PLACEMENT_BLOCKING, CollisionFlag.CAMERA_BLOCKING, CollisionFlag.GROUND_TIP_BLOCKING)
        if bit32.band(getCollisionFilterGroup(node), (bit32.bnot(allowedMask))) ~= 0 then
            Logging.devWarning("Terrain decal has collision enabled - Node: %s", I3DUtil.getNodePath(node))
            hasError = true
        end
    end
    return hasError
end)
I3DManager.addDebugLoadingCheck("DecalLayerGrids", function(_, node)
    if not getHasClassId(node, ClassIds.SHAPE) or (getShapeDecalLayer(node) == 0 or not (string.contains(string.lower(getName(node)), "grid") or (string.contains(string.lower(getName(node)), "alphapart") or string.contains(string.lower(getName(node)), "alpha_decal")))) or string.contains(string.lower(getName(node)), "sticker") then
        return false
    end
    Logging.devWarning("Alpha part or grid node found with decal layer set to %d - Node: %s", getShapeDecalLayer(node), I3DUtil.getNodePath(node))
    return true
end)
local winterMask = nil
I3DManager.addDebugLoadingCheck("SnowHeapsColAndVisCondition", function(_, node)
    -- upvalues: (ref) winterMask
    local hasErrors = false
    if getHasClassId(node, ClassIds.SHAPE) then
        local mat = getMaterial(node, 0)
        if mat ~= 0 and string.contains(getMaterialCustomShaderFilename(mat), "snowHeapShader") then
            if getRigidBodyType(node) ~= RigidBodyType.NONE then
                Logging.devWarning("Snow heap with collision found - Node: %s", I3DUtil.getNodePath(node))
                hasErrors = true
            end
            if not (getVisibility(node) and getVisibility(getParent(node))) then
                Logging.devWarning("Snow heap hidden - Node: %s", I3DUtil.getNodePath(node))
                hasErrors = true
            end
            winterMask = winterMask or (g_currentMission and (g_currentMission.environment.environmentMaskSystem:getWeatherMaskFromFlagName("WINTER") or {}).bitflag or nil)
            if winterMask ~= nil then
                local reqMask, _prevMask = getVisibilityConditionWeatherMask(node)
                if reqMask ~= winterMask then
                    Logging.devWarning("Snow heap (or its parent) does not have weatherRequired mask \'WINTER\' (0x%x) set - Node: %s", winterMask, I3DUtil.getNodeNameAndIndexPath(node))
                    hasErrors = true
                end
            end
        end
    end
    return hasErrors
end)