AdsSystem = {}
local AdsSystem_mt = Class(AdsSystem)
AdsSystem.OCCLUSION_GROUP = {}
AdsSystem.OCCLUSION_GROUP.UI = 0
function AdsSystem.new()
    -- upvalues: (copy) AdsSystem_mt
    local self = setmetatable({}, AdsSystem_mt)
    self.groups = {}
    local numGroups = 0
    for name, id in pairs(AdsSystem.OCCLUSION_GROUP) do
        if numGroups == 32 then
            Logging.warning("AdsSystem: Occclusion group limit (32) reached!")
            break
        end
        self.groups[id] = {
            ["id"] = id,
            ["name"] = name,
            ["regions"] = {},
            ["isActive"] = false
        }
        numGroups = numGroups + 1
    end
    if g_isDevelopmentVersion then
        addConsoleCommand("gsAdsSystemShowOcclusionRegions", "Renders occlusion areas", "consoleCommandShowOcclusionRegions", self)
        addConsoleCommand("gsAdsSystemDecalsToggle", "Toggle ad decals visibility in the map", "consoleCommandToggleDecals", self)
    else
        AdsSystem.consoleCommandShowOcclusionRegions = nil
        AdsSystem.consoleCommandToggleDecals = nil
    end
    self.renderOcclusionRegions = false
    return self
end
function AdsSystem:delete()
    removeConsoleCommand("gsAdsSystemShowOcclusionRegions")
    removeConsoleCommand("gsAdsSystemDecalsToggle")
    self.groups = {}
end
function AdsSystem:drawDebug()
    for _, group in pairs(self.groups) do
        local groupId = group.id
        if adsGetIsOcclusionRegionGroupActive(groupId) then
            for k, region in ipairs(group.regions) do
                local minX, minY, maxX, maxY = adsGetOcclusionRegion(groupId, k - 1)
                drawFilledRect(minX, minY, maxX - minX, maxY - minY, 1, 0, 0, 0.3, nil, nil, nil, nil)
                setTextColor(1, 1, 1, 1)
                setTextAlignment(RenderText.ALIGN_LEFT)
                renderText(minX + 5 * g_pixelSizeX, minY + 5 * g_pixelSizeY, 0.02, (tostring(group.name)))
            end
        end
    end
end
function AdsSystem:clearGroupRegion(groupId)
    local group = self.groups[groupId]
    if group == nil then
        Logging.warning("AdsSystem: GroupId \'%s\' not defined!", (tostring(groupId)))
        return false
    end
    group.regions = {}
    adsClearOcclusionRegionGroup(groupId)
    return true
end
function AdsSystem:addGroupRegion(groupId, x, y, width, height)
    local group = self.groups[groupId]
    if group == nil then
        Logging.warning("AdsSystem: GroupId \'%s\' not defined!", (tostring(groupId)))
        return false
    end
    if #group.regions == 4 then
        Logging.warning("AdsSystem: Region limit (4) per group already reached!")
        return false
    end
    table.insert(group.regions, {
        ["x"] = x,
        ["y"] = y,
        ["width"] = width,
        ["height"] = height
    })
    adsAddOcclusionRegion(groupId, x, y, x + width, y + height)
    return true
end
function AdsSystem:setGroupActive(groupId, isActive)
    local group = self.groups[groupId]
    if group == nil then
        Logging.warning("AdsSystem: GroupId \'%s\' not defined!", (tostring(groupId)))
        return false
    end
    group.isActive = isActive
    adsSetIsOcclusionRegionGroupActive(groupId, isActive)
    return false
end
function AdsSystem:consoleCommandShowOcclusionRegions()
    self.renderOcclusionRegions = not self.renderOcclusionRegions
    if self.renderOcclusionRegions then
        g_debugManager:addDrawable(self)
    else
        g_debugManager:removeDrawable(self)
    end
    return string.format("ShowOcclusionRegions=%s", self.renderOcclusionRegions)
end
function AdsSystem:consoleCommandToggleDecals()
    self.adDecalsHidden = not self.adDecalsHidden
    self.decals = self.decals or {}
    if self.adDecalsHidden then
        local adDecalMatchString = "_(%dx%d)Panel.*Decal"
        local searchPaths = { "data/maps/mapEU/textures/shared/billboards", "data/maps/textures/shared/props/billboards" }
        local filenameFormat = "%{dir}s/ad%{size}s_%{index}02d_diffuse.png"
        I3DUtil.iterateRecursively(getRootNode(), function(node)
            -- upvalues: (copy) self, (copy) searchPaths, (copy) adDecalMatchString, (copy) filenameFormat
            if getHasClassId(node, ClassIds.SHAPE) then
                local sizeStr = string.match(getName(node), "_(%dx%d)Panel.*Decal")
                if sizeStr ~= nil then
                    local clonedDecal = clone(node, true, false, false)
                    self.decals[node] = clonedDecal
                    setVisibility(node, false)
                    local clonedDecalMat = getMaterial(clonedDecal, 0)
                    for _, searchPath in ipairs(searchPaths) do
                        local i = 1
                        for i = i, 4 do
                            local filepath = string.namedFormat("%{dir}s/ad%{size}s_%{index}02d_diffuse.png", "dir", searchPath, "size", sizeStr, "index", (node % 4 + i) % 4)
                            if fileExists(filepath) then
                                local clonedDecalMat = setMaterialDiffuseMapFromFile(clonedDecalMat, filepath, false, true, false)
                                setMaterial(clonedDecal, clonedDecalMat, 0)
                                return
                            end
                        end
                    end
                    Logging.warning("No replacement texture found for ad size %s for node %q", sizeStr, I3DUtil.getNodePath(node))
                end
            end
        end)
    else
        for decal, clonedDecal in pairs(self.decals) do
            delete(clonedDecal)
            setVisibility(decal, true)
        end
        self.decals = nil
    end
    return string.format("adDecalsHidden=%s", self.adDecalsHidden)
end