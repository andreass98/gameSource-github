ConstructionBrushTree = {}
local ConstructionBrushTree_mt = Class(ConstructionBrushTree, ConstructionBrush)
ConstructionBrushTree.ERROR = {
    ["NOT_ENOUGH_MONEY"] = 200,
    ["TOO_MANY_TREES"] = 201
}
ConstructionBrushTree.ERROR_MESSAGES = {
    [ConstructionBrushTree.ERROR.NOT_ENOUGH_MONEY] = "ui_construction_notEnoughMoney",
    [ConstructionBrushTree.ERROR.TOO_MANY_TREES] = "ui_construction_tooManyTrees"
}
function ConstructionBrushTree.new(subclass_mt, cursor)
    -- upvalues: (copy) ConstructionBrushTree_mt
    local self = ConstructionBrushTree:superClass().new(subclass_mt or ConstructionBrushTree_mt, cursor)
    self.supportsPrimaryButton = true
    self.supportsTertiaryButton = true
    self.supportsPrimaryAxis = true
    self.requiredPermission = Farm.PERMISSION.LANDSCAPING
    return self
end
function ConstructionBrushTree:delete()
    ConstructionBrushTree:superClass().delete(self)
end
function ConstructionBrushTree:activate()
    ConstructionBrushTree:superClass().activate(self)
    self.cursor:setRotationEnabled(true)
    self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
    self.cursor:setShapeSize(1)
    self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SUCCESS)
    self.cursor:setTerrainOnly(true)
    self:loadTree()
    self:randomlyRotateCursor()
end
function ConstructionBrushTree:deactivate()
    self:unloadTree()
    self.cursor:setTerrainOnly(false)
    ConstructionBrushTree:superClass().deactivate(self)
end
function ConstructionBrushTree:setTree(treeType, stage, variationIndex)
    if not self.isActive then
        self.treeType = treeType
        self.treeStage = stage
        self.variationIndex = variationIndex
    end
end
function ConstructionBrushTree:setParameters(treeType, treeStage, treeVariationIndex)
    self:setTree(treeType, tonumber(treeStage), (tonumber(treeVariationIndex)))
end
function ConstructionBrushTree:update(dt)
    ConstructionBrushTree:superClass().update(self, dt)
    self:updateTreePosition()
end
function ConstructionBrushTree:draw()
    if g_isDevelopmentVersion then
        if self.treeType == nil then
            return
        else
            local treeDesc = g_treePlantManager:getTreeTypeDescFromName(self.treeType)
            if treeDesc == nil then
                return
            else
                local stage = treeDesc.stages[self.treeStage]
                if stage == nil then
                    return
                else
                    local variation = stage[self.variationIndex]
                    if variation ~= nil then
                        local storeItemNameCleaned = string.gsub(variation.filename, getUserProfileAppPath(), "")
                        renderText(ConstructionBrush.DEBUG_TEXT_ATTR.x, ConstructionBrush.DEBUG_TEXT_ATTR.y, ConstructionBrush.DEBUG_TEXT_ATTR.z, storeItemNameCleaned)
                    end
                end
            end
        end
    else
        return
    end
end
function ConstructionBrushTree:updateTreePosition()
    if self.tree ~= nil then
        local x, y, z = self.cursor:getHitTerrainPosition()
        if self.cursor.isVisible then
            if x == nil then
                self.cursor:setErrorMessage(g_i18n:getText("ui_construction_spaceAlreadyOccupied"))
            else
                local rotY = self.cursor:getRotation()
                setWorldTranslation(self.tree, x, y, z)
                setRotation(self.tree, 0, rotY, 0)
                local err = self:verifyPlacement(x, y, z)
                if err == nil then
                    self.cursor:setMessage(g_i18n:formatMoney(self:getPrice(), 0, true, true))
                else
                    local message = g_i18n:getText(ConstructionBrushTree.ERROR_MESSAGES[err] or ConstructionBrush.ERROR_MESSAGES[err])
                    self.cursor:setErrorMessage(message)
                end
            end
        end
        setVisibility(self.tree, self.cursor.isVisible)
    end
end
function ConstructionBrushTree:verifyPlacement(x, y, z)
    local err = self:verifyAccess(x, y, z)
    if err == nil then
        local enoughMoney = g_currentMission:getMoney() >= self:getPrice()
        if enoughMoney then
            if g_treePlantManager:canPlantTree() then
                return nil
            else
                return ConstructionBrushTree.ERROR.TOO_MANY_TREES
            end
        else
            return ConstructionBrushTree.ERROR.NOT_ENOUGH_MONEY
        end
    else
        return err
    end
end
function ConstructionBrushTree:getPrice()
    local basePrice = g_currentMission.economyManager:getBuyPrice(self.storeItem)
    local treeDesc = g_treePlantManager:getTreeTypeDescFromName(self.treeType)
    if treeDesc ~= nil and treeDesc.stages ~= nil then
        local numStages = #treeDesc.stages
        if numStages > 0 then
            return MathUtil.lerp(0, basePrice, self.treeStage / numStages)
        end
    end
    return basePrice
end
function ConstructionBrushTree:randomlyRotateCursor()
    self.cursor:setRotation(math.random() * 2 * 3.141592653589793)
end
function ConstructionBrushTree:loadTree()
    if self.treeType == nil or self.treeStage == nil then
        Logging.error("Tree brush has no tree type or stage set")
        return
    else
        local treeDesc = g_treePlantManager:getTreeTypeDescFromName(self.treeType)
        if treeDesc == nil then
            Logging.error("Tree type %s does not exist", self.treeType)
            return
        else
            local stage = treeDesc.stages[self.treeStage]
            if stage == nil then
                Logging.error("Tree type %s does not have a stage \'%d\'", self.treeType, self.treeStage)
                return
            else
                self.variationIndex = self.variationIndex or math.random(1, #stage)
                local variation = stage[self.variationIndex]
                if variation == nil then
                    Logging.error("Tree type %s does not have stage %d variation %d", self.treeType, self.treeStage, self.variationIndex)
                else
                    self.treeGrowthFactor = self.treeStage / #treeDesc.stages
                    self.treeTypeIndex = treeDesc.index
                    setSplitShapesLoadingFileId(-1)
                    setSplitShapesNextFileId(true)
                    local node, sharedLoadRequestId, failedReason = g_i3DManager:loadSharedI3DFile(variation.filename, false, false)
                    self.sharedLoadRequestId = sharedLoadRequestId
                    self:onTreeLoaded(node, failedReason)
                end
            end
        end
    end
end
function ConstructionBrushTree:onTreeLoaded(node, _)
    if node == nil or node == 0 then
        Logging.warning("Failed to load tree")
        return
    elseif self.isActive then
        link(getRootNode(), node)
        I3DUtil.setShaderParameterRec(node, "windSnowLeafScale", 0, 0, 1, 80)
        self.tree = node
    else
        if self.sharedLoadRequestId ~= nil then
            g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
            self.sharedLoadRequestId = nil
        end
        delete(node)
    end
end
function ConstructionBrushTree:unloadTree()
    if self.tree ~= nil then
        delete(self.tree)
        self.tree = nil
        if self.sharedLoadRequestId ~= nil then
            g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
            self.sharedLoadRequestId = nil
        end
        self.treeFilename = nil
    end
end
function ConstructionBrushTree:onButtonPrimary()
    if self.tree ~= nil then
        local x, y, z = self.cursor:getHitTerrainPosition()
        if x ~= nil and self:verifyPlacement(x, y, z) == nil then
            local growing = self.cursor:getRotation()
            if g_server == nil then
                g_client:getServerConnection():sendEvent(TreePlantEvent.new(self.treeTypeIndex, x, y, z, 0, growing, 0, self.treeStage, self.variationIndex, nil, false, self:getPrice(), g_localPlayer.farmId))
            else
                g_treePlantManager:plantTree(self.treeTypeIndex, x, y, z, 0, growing, 0, self.treeStage, self.variationIndex, false)
                g_currentMission:addMoney(-self:getPrice(), g_localPlayer.farmId, MoneyType.SHOP_PROPERTY_BUY, true)
            end
            self:playSound(ConstructionSound.ID.TREE, 1 - self.treeGrowthFactor)
            self:randomlyRotateCursor()
        end
    end
end
function ConstructionBrushTree:onButtonTertiary()
    self:randomlyRotateCursor()
end
function ConstructionBrushTree:onAxisPrimary(inputValue)
    if self.treeType == nil then
        return
    else
        local treeDesc = g_treePlantManager:getTreeTypeDescFromName(self.treeType)
        if treeDesc == nil then
            Logging.error("Tree type %s does not exist", self.treeType)
        else
            local treeStage
            if inputValue < 1 then
                local treeStage = self.treeStage - 1
                treeStage = treeStage < 1 and #treeDesc.stages or treeStage
            else
                local treeStage = self.treeStage + 1
                treeStage = #treeDesc.stages < treeStage and 1 or treeStage
            end
            local variationIndex = math.random(1, #treeDesc.stages[treeStage])
            self:deactivate()
            self:setTree(self.treeType, treeStage, variationIndex)
            self:activate()
        end
    end
end
function ConstructionBrushTree:getButtonPrimaryText()
    return "$l10n_input_CONSTRUCTION_PLACE"
end
function ConstructionBrushTree:getButtonTertiaryText()
    return "$l10n_input_CONSTRUCTION_RANDOM_ROTATE"
end
function ConstructionBrushTree:getAxisPrimaryText()
    if self.treeType ~= nil then
        return "$l10n_action_changeTreeSize"
    end
end