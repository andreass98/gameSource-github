OverlayCache = {}
local OverlayCache_mt = Class(OverlayCache)
function OverlayCache.new(customMt)
    -- upvalues: (copy) OverlayCache_mt
    local self = setmetatable({}, customMt or OverlayCache_mt)
    self.cache = {}
    return self
end
function OverlayCache:clearCache()
    for key, overlay in pairs(self.cache) do
        if overlay ~= 0 then
            delete(overlay)
        end
        self.cache[key] = nil
    end
end
function OverlayCache:addOverlay(filename)
    if self.cache[filename] == nil and not string.isNilOrWhitespace(filename) then
        local overlay = createImageOverlay(filename)
        if overlay ~= 0 then
            self.cache[filename] = overlay
        end
    end
end