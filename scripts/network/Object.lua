Object = {}
local Object_mt = Class(Object)
InitStaticObjectClass(Object, "Object")
Object.nextObjectId = 1
Object.MAX_DIRTY_FLAG = 1073741824
function Object.resetObjectIds()
    assert(g_server == nil or next(g_server.objects) ~= nil)
    Object.nextObjectId = 1
end
function Object.new(isServer, isClient, customMt)
    -- upvalues: (copy) Object_mt
    local self = setmetatable({}, customMt or Object_mt)
    self.id = Object.nextObjectId
    Object.nextObjectId = Object.nextObjectId + 1
    if g_isDevelopmentVersion and not isServer then
        self.id = math.random(9999, 99999999)
    end
    self.isRegistered = false
    self.isServer = isServer
    self.isClient = isClient
    self.ownerConnection = nil
    self.ownerFarmId = AccessHandler.EVERYONE
    self.recieveUpdates = isServer
    self.nextDirtyFlag = 1
    self.dirtyMask = 0
    self.deleteListeners = nil
    return self
end
function Object:delete()
    if self.deleteListeners ~= nil then
        for _, listener in ipairs(self.deleteListeners) do
            if type(listener.callbackFunc) == "string" then
                listener.object[listener.callbackFunc](listener.object, self)
            elseif type(listener.callbackFunc) == "function" then
                listener.callbackFunc(listener.object, self)
            end
        end
    end
    if self.isRegistered then
        self:unregister()
    end
end
function Object:register(alreadySent)
    if self.isServer then
        if g_server ~= nil then
            g_server:registerObject(self, alreadySent)
            return
        end
    elseif g_client ~= nil then
        g_client:registerObject(self, alreadySent)
    end
end
function Object:unregister(alreadySent)
    if self.isServer then
        if g_server ~= nil then
            g_server:unregisterObject(self, alreadySent)
            return
        end
    elseif g_client ~= nil then
        g_client:unregisterObject(self, alreadySent)
    end
end
function Object:raiseActive()
    if self.isServer then
        if g_server ~= nil then
            g_server:addObjectToUpdateLoop(self)
            return
        end
    elseif g_client ~= nil then
        g_client:addObjectToUpdateLoop(self)
    end
end
function Object:readStream(streamId, _, _)
    self:setOwnerFarmId(streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS), true)
end
function Object:writeStream(streamId, _)
    streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end
function Object:readUpdateStream(streamId, timestamp, connection) end
function Object:writeUpdateStream(streamId, connection, dirtyMask) end
function Object:getIsDelayedLoaded()
    return self.postWriteStream ~= nil and self.postReadStream ~= nil
end
function Object:update(dt) end
function Object:updateTick(dt) end
function Object:updateEnd(dt) end
function Object:draw() end
function Object:setOwnerConnection(connection)
    if self.isServer then
        self.ownerConnection = connection
    else
        printError("Error: setOwner only allowed on Server")
    end
end
function Object:getOwnerConnection()
    return self.ownerConnection
end
function Object:onGhostRemove() end
function Object:onGhostAdd() end
function Object.getUpdatePriority(_, skipCount, _, _, _, _, _, _)
    return skipCount * 0.5
end
function Object:getNextDirtyFlag()
    if self.nextDirtyFlag > Object.MAX_DIRTY_FLAG then
        self.nextDirtyFlag = Object.MAX_DIRTY_FLAG
        Logging.devWarning("Object:getNextDirtyFlag(), too many dirty flags")
        if g_isDevelopmentVersion then
            printCallstack()
        end
    end
    self.nextDirtyFlag = self.nextDirtyFlag * 2
    return self.nextDirtyFlag
end
function Object:raiseDirtyFlags(flag)
    self.dirtyMask = bit32.bor(self.dirtyMask, flag)
end
function Object:clearDirtyFlags(flag)
    self.dirtyMask = bit32.band(self.dirtyMask, (bit32.bnot(flag)))
end
function Object:clearDirtyMask()
    self.dirtyMask = 0
end
function Object:onMissionStarted(isNewSavegame) end
function Object:setOwnerFarmId(farmId, noEventSend)
    if self.ownerFarmId ~= farmId then
        self.ownerFarmId = farmId
        if self.isServer and (noEventSend == nil or not noEventSend) then
            g_server:broadcastEvent(ObjectFarmChangeEvent.new(self, farmId), nil, nil, self)
        end
    end
end
function Object:getOwnerFarmId()
    return self.ownerFarmId
end
function Object:addDeleteListener(object, callbackFunc)
    callbackFunc = callbackFunc == nil and "onDeleteObject" or callbackFunc
    self.deleteListeners = self.deleteListeners or {}
    for _, listener in ipairs(self.deleteListeners) do
        if listener.object == object and listener.callbackFunc == callbackFunc then
            return
        end
    end
    table.insert(self.deleteListeners, {
        ["object"] = object,
        ["callbackFunc"] = callbackFunc
    })
end
function Object:removeDeleteListener(object, callbackFunc)
    if self.deleteListeners ~= nil then
        callbackFunc = callbackFunc == nil and "onDeleteObject" or callbackFunc
        for i, listener in ipairs(self.deleteListeners) do
            if listener.object == object and listener.callbackFunc == callbackFunc then
                table.remove(self.deleteListeners, i)
                return
            end
        end
    end
end