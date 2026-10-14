PlatformIconElement = {}
local PlatformIconElement_mt = Class(PlatformIconElement, BitmapElement)
Gui.registerGuiElement("PlatformIcon", PlatformIconElement)
function PlatformIconElement.new(target, custom_mt)
    -- upvalues: (copy) PlatformIconElement_mt
    return PlatformIconElement:superClass().new(target, custom_mt or PlatformIconElement_mt)
end
function PlatformIconElement:delete()
    PlatformIconElement:superClass().delete(self)
end
function PlatformIconElement:copyAttributes(src)
    PlatformIconElement:superClass().copyAttributes(self, src)
    self.platformId = src.platformId
end
function PlatformIconElement:setPlatformId(platformId)
    platformId = (GS_PLATFORM_ID == PlatformId.PS5 and platformId ~= PlatformId.PS5 and true or (GS_PLATFORM_ID == PlatformId.XBOX_SERIES and platformId ~= PlatformId.XBOX_SERIES and true or (GS_IS_MSSTORE_VERSION and (platformId ~= PlatformId.XBOX_SERIES and platformId ~= PlatformId.WIN) and true or false))) and 0 or platformId
    if PlatformIconElement.ALLOW_COLOR_CHANGE[platformId] then
        if self.colorSelectedBackup ~= nil then
            self.overlay.colorSelected = self.colorSelectedBackup
            self.colorSelectedBackup = nil
        end
    else
        self.colorSelectedBackup = self.overlay.colorSelected
        self.overlay.colorSelected = self.overlay.color
    end
    self:setImageSlice(nil, PlatformIconElement.SLICES[platformId])
end
PlatformIconElement.SLICES = {
    [0] = "gui.multiplayer_genericPlatform",
    [PlatformId.WIN] = "gui.multiplayer_PC",
    [PlatformId.MAC] = "gui.multiplayer_PC",
    [PlatformId.PS5] = "gui.multiplayer_playstation",
    [PlatformId.XBOX_SERIES] = "gui.multiplayer_xbox"
}
PlatformIconElement.ALLOW_COLOR_CHANGE = {
    [0] = true,
    [PlatformId.WIN] = true,
    [PlatformId.MAC] = true,
    [PlatformId.PS5] = false,
    [PlatformId.XBOX_SERIES] = true
}