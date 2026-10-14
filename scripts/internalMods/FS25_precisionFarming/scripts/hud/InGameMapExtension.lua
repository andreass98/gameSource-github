InGameMapExtension = {}
InGameMapExtension.MOD_NAME = g_currentModName
InGameMapExtension.MOD_DIR = g_currentModDirectory
InGameMapExtension.GUI_ELEMENTS = g_currentModDirectory .. "gui/ui_elements.png"
local InGameMapExtension_mt = Class(InGameMapExtension)
function InGameMapExtension.new(precisionFarming, customMt)
    -- upvalues: (copy) InGameMapExtension_mt
    local self = setmetatable({}, customMt or InGameMapExtension_mt)
    local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
    local width, height = getNormalizedScreenValues(120 * uiScale, 6 * uiScale)
    self.gradientBackgroundElement = g_overlayManager:createOverlay("precisionFarming.filled", 0, 0, width, height)
    self.gradientBackgroundElement:setColor(0, 0, 0, 0.6)
    self.gradientElement = g_overlayManager:createOverlay("precisionFarming.gradient_red_green", 0, 0, width, height)
    self.labelPositionsByState = {}
    self.labelPositionsByState[IngameMapState.MINIMAP_ROUND] = {
        ["labelOffset"] = { getNormalizedScreenValues(0, 15 * uiScale) },
        ["labelTextSize"] = { getNormalizedScreenValues(0, 15 * uiScale) },
        ["gradientOffset"] = { getNormalizedScreenValues(0, 40 * uiScale) },
        ["labelXAlignment"] = RenderText.ALIGN_CENTER,
        ["gradientXAlignment"] = RenderText.ALIGN_CENTER
    }
    self.labelPositionsByState[IngameMapState.MINIMAP_SQUARE] = {
        ["labelOffset"] = { getNormalizedScreenValues(18 * uiScale, 15 * uiScale) },
        ["labelTextSize"] = { getNormalizedScreenValues(0, 15 * uiScale) },
        ["gradientOffset"] = { getNormalizedScreenValues(0, 30 * uiScale) },
        ["labelXAlignment"] = RenderText.ALIGN_LEFT,
        ["gradientXAlignment"] = RenderText.ALIGN_CENTER
    }
    self.labelPositionsByState[IngameMapState.MAP] = {
        ["labelOffset"] = { getNormalizedScreenValues(18 * uiScale, 15 * uiScale) },
        ["labelTextSize"] = { getNormalizedScreenValues(0, 15 * uiScale) },
        ["gradientOffset"] = { getNormalizedScreenValues(20 * uiScale, 20 * uiScale) },
        ["labelXAlignment"] = RenderText.ALIGN_LEFT,
        ["gradientXAlignment"] = RenderText.ALIGN_LEFT
    }
    self.minimapSoilStateOverlay = createDensityMapVisualizationOverlay("soilStateOverlay", 1024, 1024)
    self.minimapSoilStateOverlayIsReady = nil
    self.minimapSoilStateOverlayIsReadyForDisplay = nil
    precisionFarming:registerVisualizationOverlay(self.minimapSoilStateOverlay)
    self.smoothedMapZoomLevel = 1
    self.smoothedMapZoomTargetLevel = 1
    self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
    self.precisionFarming = precisionFarming
    self.inGameMap = nil
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], self.onColorBlindModeChanged, self)
    return self
end
function InGameMapExtension:unloadMapData() end
function InGameMapExtension:delete()
    if self.minimapSoilStateOverlay ~= nil then
        delete(self.minimapSoilStateOverlay)
    end
    self.gradientElement:delete()
    self.gradientBackgroundElement:delete()
    g_messageCenter:unsubscribeAll(self)
end
function InGameMapExtension:update(dt)
    local valueMaps = self.precisionFarming:getValueMaps()
    local requiredValueMap = nil
    local requiredValueMapSelected = nil
    local i = 1
    local requiredFilter = #valueMaps
    local requiresUpdate = 1
    for i = i, requiredFilter, requiresUpdate do
        local valueMap = valueMaps[i]
        local requireDisplay, isSelected = valueMap:getRequireMinimapDisplay()
        if requireDisplay then
            if requiredValueMap == nil then
                requiredValueMapSelected = isSelected
                requiredValueMap = valueMap
            elseif not requiredValueMapSelected and isSelected then
                requiredValueMapSelected = isSelected
                requiredValueMap = valueMap
            end
        end
    end
    if requiredValueMap == nil or self.inGameMap ~= nil and (not self.inGameMap.isVisible or self.inGameMap.state == IngameMapState.OFF) then
        self.minimapSoilStateOverlayIsReady = nil
        self.minimapSoilStateOverlayIsReadyForDisplay = false
        self.lastValueMap = nil
        self.lastValueMapFilter = nil
        self.smoothedMapZoomTargetLevel = 1
    else
        if self.minimapSoilStateOverlayIsReady == nil or self.minimapSoilStateOverlayIsReady == true then
            local requiredFilter = requiredValueMap:getMinimapValueFilter()
            local requiresUpdate = requiredValueMap:getMinimapRequiresUpdate()
            if not requiresUpdate then
                requiresUpdate = g_server ~= nil
            end
            if self.lastValueMap ~= requiredValueMap then
                self.minimapSoilStateOverlayIsReadyForDisplay = false
            end
            if self.lastValueMap ~= requiredValueMap or (self.lastValueMapFilter ~= requiredFilter or requiresUpdate) then
                requiredValueMap:getMinimapUpdateTimeLimit()
                local _ = g_server == nil
                requiredValueMap:buildOverlay(self.minimapSoilStateOverlay, requiredFilter, self.isColorBlindMode, true)
                generateDensityMapVisualizationOverlay(self.minimapSoilStateOverlay)
                self.minimapSoilStateOverlayIsReady = false
                requiredValueMap:setMinimapRequiresUpdate(false)
                self.lastValueMap = requiredValueMap
                self.lastValueMapFilter = requiredFilter
            end
        end
        if self.minimapSoilStateOverlayIsReady == false and getIsDensityMapVisualizationOverlayReady(self.minimapSoilStateOverlay) then
            self.minimapSoilStateOverlayIsReady = true
            self.minimapSoilStateOverlayIsReadyForDisplay = true
        end
        self.smoothedMapZoomTargetLevel = requiredValueMap:getMinimapZoomFactor()
    end
    if self.smoothedMapZoomLevel ~= self.smoothedMapZoomTargetLevel then
        local requiredFilter = math.sign(self.smoothedMapZoomTargetLevel - self.smoothedMapZoomLevel)
        self.smoothedMapZoomLevel = (requiredFilter == 1 and math.min or math.max)(self.smoothedMapZoomLevel + dt * 0.001 * requiredFilter * 2, self.smoothedMapZoomTargetLevel)
    end
end
function InGameMapExtension:updatePrecisionFarmingOverlays()
    if self.lastValueMap ~= nil then
        self.lastValueMap:setMinimapRequiresUpdate(true)
    end
end
function InGameMapExtension:onColorBlindModeChanged(isColorBlindMode)
    self.isColorBlindMode = isColorBlindMode
    self.minimapSoilStateOverlayIsReady = nil
    self.lastValueMap = nil
    self.lastValueMapFilter = nil
end
function InGameMapExtension:overwriteGameFunctions(pfModule)
    pfModule:overwriteGameFunction(IngameMap, "loadMap", function(superFunc, inGameMap, ...)
        -- upvalues: (copy) self
        self.inGameMap = inGameMap
        superFunc(inGameMap, ...)
    end)
    pfModule:overwriteGameFunction(IngameMap, "drawFields", function(superFunc, ingameMap)
        -- upvalues: (copy) self
        superFunc(ingameMap)
        if ingameMap.layout.supportPrecisionFarmingSoilStateOverlay then
            if not ingameMap.isFullscreen then
                if self.minimapSoilStateOverlayIsReadyForDisplay then
                    local width, height = ingameMap.layout:getMapSize()
                    local x, y = ingameMap.layout:getMapPosition()
                    local px, py = ingameMap.layout:getMapPivot()
                    local x = x + width * 0.25
                    local y = y + height * 0.25
                    setOverlayRotation(self.minimapSoilStateOverlay, ingameMap.layout:getMapRotation(), px + x - x, py + y - y)
                    setOverlayColor(self.minimapSoilStateOverlay, 1, 1, 1, (math.sqrt((ingameMap.layout:getMapAlpha()))))
                    renderOverlay(self.minimapSoilStateOverlay, x, y, width * 0.5, height * 0.5)
                end
                if self.lastValueMap ~= nil then
                    local width = self.lastValueMap:getMinimapAdditionalElement()
                    if width ~= nil then
                        local height, x = self.lastValueMap:getMinimapAdditionalElementRealSize()
                        if height > 0 and x > 0 then
                            local y, px = ingameMap.layout:getMapSize()
                            width.width = height / ingameMap.worldSizeX * y * 0.5
                            width.height = x / ingameMap.worldSizeZ * px * 0.5
                        end
                        local y = ingameMap.layout.background
                        if y ~= nil then
                            local px = self.lastValueMap:getMinimapAdditionalElementLinkNode()
                            if px == nil then
                                width.x = y.x + y.width * 0.5 - width.width * 0.5
                                width.y = y.y + y.height * 0.5 - width.height * 0.5
                            else
                                local py, _, linkZ = getWorldTranslation(px)
                                local posX, posY, _, _ = ingameMap.layout:getMapObjectPosition((py * 0.5 + ingameMap.worldCenterOffsetX) / ingameMap.worldSizeX, (linkZ * 0.5 + ingameMap.worldCenterOffsetZ) / ingameMap.worldSizeZ, width.width, width.height, 0, true)
                                width.x = posX
                                width.y = posY
                            end
                        end
                        width:render()
                    end
                end
            end
        end
    end)
    pfModule:overwriteGameFunction(IngameMap, "draw", function(superFunc, ingameMap)
        -- upvalues: (copy) self
        superFunc(ingameMap)
        if ingameMap.isVisible then
            if ingameMap.layout.supportPrecisionFarmingSoilStateOverlay then
                local width, height = ingameMap.layout:getMapSize()
                if width == 0 or height == 0 then
                    return
                elseif self.labelPositionsByState[ingameMap.state] ~= nil then
                    if self.lastValueMap ~= nil then
                        local background = ingameMap.layout.background
                        if background ~= nil then
                            local label = self.lastValueMap:getMinimapLabel()
                            if label ~= nil then
                                setTextAlignment(RenderText.ALIGN_LEFT)
                                local positions = self.labelPositionsByState[ingameMap.state]
                                local textSize = positions.labelTextSize[2]
                                local tx = background.x + positions.labelOffset[1]
                                local ty = background.y + background.height - positions.labelOffset[2] - textSize
                                if positions.labelXAlignment == RenderText.ALIGN_CENTER then
                                    tx = background.x + background.width * 0.5
                                    setTextAlignment(RenderText.ALIGN_CENTER)
                                end
                                setTextColor(0, 0, 0, 1)
                                renderText(tx, ty - 0.0015, textSize, label)
                                setTextColor(1, 1, 1, 1)
                                renderText(tx, ty, textSize, label)
                                setTextAlignment(RenderText.ALIGN_LEFT)
                            end
                            local positions = self.lastValueMap:getMinimapGradientSliceId(self.isColorBlindMode)
                            local offsetX = self.lastValueMap:getMinimapGradientLabel()
                            if positions ~= nil and offsetX ~= nil then
                                local offsetY = self.labelPositionsByState[ingameMap.state]
                                local textSize = self.gradientBackgroundElement
                                local align = self.gradientElement
                                textSize:setPosition(background.x + offsetY.gradientOffset[1], background.y + offsetY.gradientOffset[2])
                                if offsetY.gradientXAlignment == RenderText.ALIGN_CENTER then
                                    textSize:setPosition(background.x + background.width * 0.5 - textSize.width * 0.5, nil)
                                end
                                textSize:render()
                                align:setPosition(textSize.x + (textSize.width - align.width) * 0.5, textSize.y + (textSize.height - align.height) * 0.5)
                                align:setSliceId(positions)
                                align:render()
                                setTextAlignment(RenderText.ALIGN_CENTER)
                                local tx = textSize.x + textSize.width * 0.5
                                local ty = textSize.y + textSize.height + offsetY.labelTextSize[2] * 0.3
                                setTextColor(0, 0, 0, 1)
                                renderText(tx, ty - 0.0015, offsetY.labelTextSize[2] * 0.85, offsetX)
                                setTextColor(1, 1, 1, 1)
                                renderText(tx, ty, offsetY.labelTextSize[2] * 0.85, offsetX)
                            end
                        end
                    end
                end
            else
                return
            end
        else
            return
        end
    end)
    pfModule:overwriteGameFunction(IngameMapLayoutCircle, "updateScreenValues", function(superFunc, layout, ...)
        -- upvalues: (copy) self
        local oldWorldSizeFactor = layout.worldSizeFactor
        layout.worldSizeFactor = oldWorldSizeFactor * self.smoothedMapZoomLevel
        superFunc(layout, ...)
        layout.worldSizeFactor = oldWorldSizeFactor
    end)
    pfModule:overwriteGameFunction(IngameMapLayoutSquare, "updateScreenValues", function(superFunc, layout, ...)
        -- upvalues: (copy) self
        local oldWorldSizeFactor = layout.worldSizeFactor
        layout.worldSizeFactor = oldWorldSizeFactor * self.smoothedMapZoomLevel
        superFunc(layout, ...)
        layout.worldSizeFactor = oldWorldSizeFactor
    end)
    pfModule:overwriteGameFunction(IngameMapLayout, "new", function(superFunc, ...)
        local _self = superFunc(...)
        _self.supportPrecisionFarmingSoilStateOverlay = true
        return _self
    end)
    pfModule:overwriteGameFunction(IngameMapLayoutPartialscreen, "new", function(superFunc, ...)
        local _self = superFunc(...)
        _self.supportPrecisionFarmingSoilStateOverlay = false
        return _self
    end)
end