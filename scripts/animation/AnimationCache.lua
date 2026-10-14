AnimationCache = {}
AnimationCache.CHARACTER = "CHARACTER"
AnimationCache.PEDESTRIAN = "PEDESTRIAN"
AnimationCache.VEHICLE_CHARACTER = "VEHICLE_CHARACTER"
local AnimationCache_mt = Class(AnimationCache)
function AnimationCache.new()
    -- upvalues: (copy) AnimationCache_mt
    local self = setmetatable({}, AnimationCache_mt)
    self.pendingLoadRequestIds = {}
    self.nameToFilename = {}
    self.nameToAnimationNode = {}
    return self
end
function AnimationCache:load(name, filename)
    if self.nameToFilename[name] ~= nil then
        Logging.error("\'%s\' already exists in animation cache", name)
        return false
    end
    for existingName, file in pairs(self.nameToFilename) do
        if file == filename then
            self.nameToFilename[name] = filename
            for n, node in pairs(self.nameToAnimationNode) do
                if n == existingName then
                    self.nameToAnimationNode[name] = node
                end
            end
            return true
        end
    end
    self.nameToFilename[name] = filename
    local args = {
        ["name"] = name
    }
    local loadRequestId = g_i3DManager:loadI3DFileAsync(filename, false, false, self.onAnimationFileLoaded, self, args)
    args.loadRequestId = loadRequestId
    self.pendingLoadRequestIds[loadRequestId] = true
    return true
end
function AnimationCache:onAnimationFileLoaded(node, _, args)
    self.pendingLoadRequestIds[args.loadRequestId] = nil
    if node == 0 then
        return
    else
        local filename = self.nameToFilename[args.name]
        if filename == nil then
            delete(node)
        else
            self.nameToAnimationNode[name] = node
            for n, file in pairs(self.nameToFilename) do
                if filename == file then
                    self.nameToAnimationNode[n] = node
                end
            end
        end
    end
end
function AnimationCache:getNode(name)
    return self.nameToAnimationNode[name]
end
function AnimationCache:isLoaded(name)
    return self.nameToAnimationNode[name] ~= nil
end
function AnimationCache:delete()
    for name, filename in pairs(self.nameToFilename) do
        local node = self.nameToAnimationNode[name]
        if node ~= nil and entityExists(node) then
            delete(self.nameToAnimationNode[name])
        end
    end
    self.nameToFilename = {}
    for name, filename in pairs(self.pendingLoadRequestIds) do
        g_i3DManager:cancelStreamI3DFile(name)
    end
end