ConstructionBrushSelect = {}
local ConstructionBrushSelect_mt = Class(ConstructionBrushSelect, ConstructionBrush)
ConstructionBrushSelect.OVERLAY_COLOR = { 0.2, 0.4, 1 }
function ConstructionBrushSelect.new(subclass_mt, cursor)
    -- upvalues: (copy) ConstructionBrushSelect_mt
    local self = ConstructionBrushSelect:superClass().new(subclass_mt or ConstructionBrushSelect_mt, cursor)
    self.isSelector = true
    self.supportsPrimaryButton = true
    self.supportsTertiaryButton = true
    return self
end
function ConstructionBrushSelect:delete()
    ConstructionBrushSelect:superClass().delete(self)
end
function ConstructionBrushSelect:activate()
    ConstructionBrushSelect:superClass().activate(self)
    self.cursor:setRotationEnabled(false)
    self.cursor:setShape(GuiTopDownCursor.SHAPES.NONE)
    self.cursor:setSelectionMode(true)
    g_messageCenter:subscribe(SellPlaceableEvent, self.onPlaceableDestroyed, self)
end
function ConstructionBrushSelect:deactivate()
    if self.lastPlaceable ~= nil then
        if self.lastPlaceable.rootNode ~= nil and entityExists(self.lastPlaceable.rootNode) then
            self.lastPlaceable:setOverlayColor(0.2, 0.4, 1, 0)
        end
        self.lastPlaceable = nil
        self:setInputTextDirty()
    end
    self.pauseUpdates = false
    self.cursor:setSelectionMode(false)
    g_messageCenter:unsubscribeAll(self)
    ConstructionBrushSelect:superClass().deactivate(self)
end
function ConstructionBrushSelect:update(dt)
    ConstructionBrushSelect:superClass().update(self, dt)
    if self.lastPlaceable ~= nil and self.lastPlaceable.isDeleted then
        self.lastPlaceable = nil
        self.pauseUpdates = false
        self:setInputTextDirty()
    end
    if not self.pauseUpdates then
        self:visualizeMouseOver()
    end
end
function ConstructionBrushSelect:draw()
    if g_isDevelopmentVersion and (self.lastPlaceable ~= nil and self.lastPlaceable.configFileName ~= nil) then
        local storeItemNameCleaned = string.gsub(self.lastPlaceable.configFileName, getUserProfileAppPath(), "")
        renderText(ConstructionBrush.DEBUG_TEXT_ATTR.x, ConstructionBrush.DEBUG_TEXT_ATTR.y, ConstructionBrush.DEBUG_TEXT_ATTR.z, storeItemNameCleaned)
    end
end
function ConstructionBrushSelect:visualizeMouseOver()
    local placeable = self.cursor:getHitPlaceable()
    if placeable ~= self.lastPlaceable then
        if self.lastPlaceable ~= nil then
            if self.lastPlaceable.rootNode ~= nil then
                self.lastPlaceable:setOverlayColor(1, 1, 1, 0)
            end
            self.lastPlaceable = nil
            self:setInputTextDirty()
        end
        if placeable ~= nil and placeable:getDestructionMethod() ~= Placeable.DESTRUCTION.PER_NODE then
            local color = ConstructionBrushSelect.OVERLAY_COLOR
            placeable:setOverlayColor(color[1], color[2], color[3], 0.8)
            self.lastPlaceable = placeable
            self:setInputTextDirty()
        end
    end
end
function ConstructionBrushSelect:onButtonPrimary()
    if self.lastPlaceable == nil or self.lastPlaceable.isDeleted then
        self.lastPlaceable = nil
        self.pauseUpdates = false
        self:setInputTextDirty()
    else
        self.pauseUpdates = true
        PlaceableInfoDialog.show(function(didSell)
            -- upvalues: (copy) self
            if didSell then
                self.lastPlaceable = nil
                self:setInputTextDirty()
            end
            self.pauseUpdates = false
        end, self.lastPlaceable)
    end
end
function ConstructionBrushSelect.onButtonTertiary(_, constructionScreen)
    constructionScreen:onClickDestruct()
end
function ConstructionBrushSelect:onPlaceableDestroyed(_, _)
    if self.lastPlaceable ~= nil then
        self.lastPlaceable = nil
        self.pauseUpdates = false
        self:setInputTextDirty()
    end
end
function ConstructionBrushSelect:getButtonPrimaryText()
    return self.lastPlaceable ~= nil and "$l10n_button_select" or nil
end
function ConstructionBrushSelect:getButtonTertiaryText()
    return "$l10n_ui_demolitionModeEnter"
end