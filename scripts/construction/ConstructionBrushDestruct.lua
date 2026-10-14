ConstructionBrushDestruct = {}
local ConstructionBrushDestruct_mt = Class(ConstructionBrushDestruct, ConstructionBrush)
ConstructionBrushDestruct.OVERLAY_COLOR = { 1, 0.1, 0.1 }
ConstructionBrushDestruct.SELL_UNDO_TIMEOUT = 900000
function ConstructionBrushDestruct.new(subclass_mt, cursor)
    -- upvalues: (copy) ConstructionBrushDestruct_mt
    local self = ConstructionBrushDestruct:superClass().new(subclass_mt or ConstructionBrushDestruct_mt, cursor)
    self.supportsPrimaryButton = true
    self.supportsPrimaryDragging = true
    self.requiredPermission = Farm.PERMISSION.SELL_PLACEABLE
    return self
end
function ConstructionBrushDestruct:delete()
    ConstructionBrushDestruct:superClass().delete(self)
end
function ConstructionBrushDestruct:activate()
    ConstructionBrushDestruct:superClass().activate(self)
    self.cursor:setRotationEnabled(false)
    self.cursor:setShape(GuiTopDownCursor.SHAPES.NONE)
    self.cursor:setSelectionMode(true)
    self.coloredNodes = {}
    self.destructionPreviewNodes = {}
end
function ConstructionBrushDestruct:deactivate()
    self.cursor:setSelectionMode(false)
    self:resetPlaceableSelection()
    g_messageCenter:unsubscribeAll(self)
    ConstructionBrushDestruct:superClass().deactivate(self)
end
function ConstructionBrushDestruct:update(dt)
    ConstructionBrushDestruct:superClass().update(self, dt)
    if self:hasPlayerPermission() then
        self:visualizeMouseOver()
    else
        self.cursor:setErrorMessage(g_i18n:getText("shop_messageNoPermissionGeneral"))
    end
end
function ConstructionBrushDestruct:draw()
    if g_isDevelopmentVersion and (self.lastPlaceable ~= nil and self.lastPlaceable.configFileName ~= nil) then
        local storeItemNameCleaned = string.gsub(self.lastPlaceable.configFileName, getUserProfileAppPath(), "")
        renderText(ConstructionBrush.DEBUG_TEXT_ATTR.x, ConstructionBrush.DEBUG_TEXT_ATTR.y, ConstructionBrush.DEBUG_TEXT_ATTR.z, storeItemNameCleaned)
    end
end
function ConstructionBrushDestruct:resetColoredNodes()
    local i = #self.coloredNodes
    for i = i, 1, -1 do
        local node = self.coloredNodes[i]
        if entityExists(node) then
            setShaderParameter(node, "placeableColorScale", 1, 1, 1, 0, false)
        end
        self.coloredNodes[i] = nil
    end
end
function ConstructionBrushDestruct:visualizeMouseOver()
    table.clear(self.destructionPreviewNodes)
    local placeable = self.cursor:getHitPlaceable()
    if placeable == self.lastPlaceable and not self.perNodeMode then
        local color = self.cursor:getHitObject()
        if color ~= nil and color:isa(Fence) then
            if color.getAllowSegmentDeletion ~= nil and not color:getAllowSegmentDeletion() then
                return
            end
            local r = color:getSegmentFromNode(self.cursor:getHitNode())
            if r ~= nil and r:getCanBeModifiedByFarmId(g_localPlayer.farmId) then
                DebugShapeOutline.render(r.root, true)
            end
        end
    else
        self:resetPlaceableSelection()
        if placeable ~= nil and g_localPlayer.farmId == placeable.ownerFarmId then
            self.lastPlaceable = placeable
            g_messageCenter:subscribe(SellPlaceableEvent, self.onPlaceableDestroyed, self)
            local color = ConstructionBrushDestruct.OVERLAY_COLOR
            if placeable:getDestructionMethod() == Placeable.DESTRUCTION.PER_NODE then
                self:resetColoredNodes()
                local nodes = placeable:previewNodeDestructionNodes(self.cursor:getHitNode(), self.destructionPreviewNodes)
                if nodes ~= nil then
                    for _, node in ipairs(nodes) do
                        if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, "placeableColorScale") then
                            setShaderParameter(node, "placeableColorScale", color[1], color[2], color[3], 0.8, false)
                            table.insert(self.coloredNodes, node)
                        end
                    end
                    if #self.coloredNodes == 0 then
                        for _, node in ipairs(nodes) do
                            DebugShapeOutline.render(node, true)
                        end
                    end
                end
                self.perNodeMode = true
            else
                placeable:setOverlayColor(r, g, b, 0.8)
                self.perNodeMode = false
            end
        end
    end
end
function ConstructionBrushDestruct:onButtonPrimary(isDown, isDrag, isUp)
    if isUp then
        self.lastDragPlaceable = nil
        return
    elseif self:hasPlayerPermission() then
        local placeable = self.cursor:getHitPlaceable()
        if placeable == nil or (g_localPlayer.farmId ~= placeable.ownerFarmId or self.lastDragPlaceable ~= nil and placeable ~= self.lastDragPlaceable) then
            if isDown and not isDrag then
                local callbackFunc = self.cursor:getHitObject()
                if callbackFunc ~= nil and callbackFunc:isa(Fence) then
                    if self.awaitingFenceSegmentDeletion then
                        return
                    end
                    if callbackFunc.getAllowSegmentDeletion ~= nil and not callbackFunc:getAllowSegmentDeletion() then
                        return
                    end
                    local price = callbackFunc:getSegmentFromNode((self.cursor:getHitNode()))
                    if price ~= nil and price:getCanBeModifiedByFarmId(g_localPlayer.farmId) then
                        self.awaitingFenceSegmentDeletion = true
                        g_messageCenter:subscribeOneshot(FenceDeleteSegmentEvent, function(fencePlaceable, _)
                            -- upvalues: (copy) self
                            if fencePlaceable ~= nil and fencePlaceable.playDestroySound ~= nil then
                                fencePlaceable:playDestroySound(true)
                            end
                            self.awaitingFenceSegmentDeletion = false
                        end)
                        g_client:getServerConnection():sendEvent(FenceDeleteSegmentEvent.new(callbackFunc.parentObject, price.id))
                    end
                end
            end
        else
            if placeable:getDestructionMethod() == Placeable.DESTRUCTION.PER_NODE then
                if isDown then
                    self.lastDragPlaceable = placeable
                end
                if placeable.getConfirmDestruction == nil or not placeable:getConfirmDestruction() then
                    self:destroyNodeInPlaceable(placeable)
                else
                    YesNoDialog.show(function(yes)
                        -- upvalues: (copy) self, (copy) placeable
                        if yes then
                            self:destroyNodeInPlaceable(placeable)
                        end
                    end, nil, g_i18n:getText("ui_constructionDeleteConfirmationRiceField"), nil, g_i18n:getText("button_ok"), g_i18n:getText("button_cancel"))
                end
            end
            if isDown then
                local callbackFunc, warning = placeable:canBeSold()
                local price, forFullPrice = placeable:getSellPrice()
                if warning == nil then
                    local text = string.format(g_i18n:getText("ui_constructionSellConfirmation"), placeable:getName(), g_i18n:formatMoney(price, 0, true, true))
                    YesNoDialog.show(function(yes)
                        -- upvalues: (copy) placeable, (copy) forFullPrice
                        if yes then
                            g_client:getServerConnection():sendEvent(SellPlaceableEvent.new(placeable, false, forFullPrice))
                        end
                    end, nil, text)
                    return
                elseif callbackFunc then
                    YesNoDialog.show(callbackFunc, nil, warning, nil, g_i18n:getText("button_ok"), g_i18n:getText("button_cancel"))
                else
                    InfoDialog.show(warning, nil, nil, nil, g_i18n:getText("button_back"), InputAction.MENU_BACK)
                end
            end
        end
    end
end
function ConstructionBrushDestruct:destroyNodeInPlaceable(placeable)
    local didDestroy, destroyPlaceable = placeable:performNodeDestruction(self.cursor:getHitNode())
    if didDestroy and placeable.playDestroySound ~= nil then
        placeable:playDestroySound(true)
    end
    if destroyPlaceable then
        g_client:getServerConnection():sendEvent(SellPlaceableEvent.new(placeable, true, true, false))
    end
end
function ConstructionBrushDestruct:resetPlaceableSelection()
    self:resetColoredNodes()
    if self.lastPlaceable ~= nil then
        if self.lastPlaceable.rootNode ~= nil and (entityExists(self.lastPlaceable.rootNode) and not self.perNodeMode) then
            self.lastPlaceable:setOverlayColor(1, 1, 1, 0)
        end
        self.lastPlaceable = nil
        g_messageCenter:unsubscribeAll(self)
    end
end
function ConstructionBrushDestruct:onPlaceableDestroyed(_, _)
    if self.lastPlaceable ~= nil then
        self:resetPlaceableSelection()
    end
end
function ConstructionBrushDestruct:getButtonPrimaryText()
    return "$l10n_input_CONSTRUCTION_REMOVE"
end