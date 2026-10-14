TerrainDeformationQueue = {}
local TerrainDeformationQueue_mt = Class(TerrainDeformationQueue)
function TerrainDeformationQueue.new()
    -- upvalues: (copy) TerrainDeformationQueue_mt
    local self = setmetatable({}, TerrainDeformationQueue_mt)
    self.jobQueue = {}
    self.nextId = 0
    self.currentJob = nil
    self.cancelling = false
    return self
end
function TerrainDeformationQueue:update(_)
    if not self.cancelling then
        while self:tryRunJob() do

        end
    end
end
function TerrainDeformationQueue:queueJob(terrainDeformation, previewOnly, callbackFuncName, callbackObject, callbackArgs)
    self.nextId = self.nextId + 1
    table.insert(self.jobQueue, {
        ["id"] = self.nextId,
        ["deformer"] = terrainDeformation,
        ["previewOnly"] = previewOnly,
        ["callbackFuncName"] = callbackFuncName,
        ["callbackObject"] = callbackObject,
        ["callbackArgs"] = callbackArgs
    })
    return self.nextId
end
function TerrainDeformationQueue:tryRunJob()
    if self.currentJob or not self.jobQueue[1] then
        return false
    end
    self.currentJob = self.jobQueue[1]
    table.remove(self.jobQueue, 1)
    if self.currentJob.deformer then
        self.currentJob.deformer:apply(self.currentJob.previewOnly, "onJobComplete", self, self.currentJob.callbackArgs)
    else
        self:onJobComplete(TerrainDeformation.STATE_SUCCESS, 0, "")
    end
    return true
end
function TerrainDeformationQueue:onJobComplete(errorCode, displacedVolume, blockedObjectName, callbackArgs)
    if self.currentJob.callbackFuncName == nil then
        self.currentJob.deformer:delete()
    elseif self.currentJob.callbackObject then
        if self.currentJob.callbackObject[self.currentJob.callbackFuncName] == nil then
            Logging.warning("TerrainDeformationQueue:onJobComplete: no function %q for callback target %q", self.currentJob.callbackFuncName, ClassUtil.getClassNameByObject(self.currentJob.callbackObject))
        else
            self.currentJob.callbackObject[self.currentJob.callbackFuncName](self.currentJob.callbackObject, errorCode, displacedVolume, blockedObjectName, callbackArgs)
        end
    elseif _G[self.currentJob.callbackFuncName] == nil then
        Logging.warning("TerrainDeformationQueue:onJobComplete: no function %q in global scope", self.currentJob.callbackFuncName)
    else
        _G[self.currentJob.callbackFuncName](errorCode, displacedVolume, blockedObjectName, callbackArgs)
    end
    self.currentJob = nil
end
function TerrainDeformationQueue:cancelJob(jobId)
    for k, job in ipairs(self.jobQueue) do
        if job.id == jobId then
            table.remove(self.jobQueue, k)
            return true
        end
    end
    return false
end
function TerrainDeformationQueue:cancelAllJobs()
    self.cancelling = true
    if self.currentJob then
        self.currentJob.deformer:cancel()
    end
    while self.jobQueue[1] do
        self.currentJob = self.jobQueue[1]
        table.remove(self.jobQueue, 1)
        self:onJobComplete(TerrainDeformation.STATE_CANCELLED, 0, "")
    end
    self.currentJob = nil
    self.cancelling = false
end
g_terrainDeformationQueue = TerrainDeformationQueue.new()