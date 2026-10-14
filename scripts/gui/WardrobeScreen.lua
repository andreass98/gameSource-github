WardrobeScreen = {}
local WardrobeScreen_mt = Class(WardrobeScreen, TabbedMenuWithDetails)
WardrobeScreen.CAMERA_FOV = 0.7155849933176751
WardrobeScreen.BACKGROUND_PATH = "data/store/ui/shop.i3d"
WardrobeScreen.LIGHTING_XML_PATH = "data/store/ui/wardrobe_lighting.xml"
function WardrobeScreen.register()
    WardrobeItemsFrame.register()
    WardrobeColorsFrame.register()
    WardrobeOutfitsFrame.register()
    WardrobeCharactersFrame.register()
    local wardrobeScreen = WardrobeScreen.new()
    g_gui:loadGui("dataS/gui/WardrobeScreen.xml", "WardrobeScreen", wardrobeScreen)
    return wardrobeScreen
end
function WardrobeScreen.new(target, custom_mt)
    -- upvalues: (copy) WardrobeScreen_mt
    local self = TabbedMenuWithDetails.new(target, custom_mt or WardrobeScreen_mt)
    self.scenePrepared = false
    self.startRotY = 3.12413936106985
    self.characterPosition = { 14, 0.185, 35.5 }
    self.characterRotY = 3.490658503988659
    self.playerGraphics = nil
    self.needsBrandsInitialization = true
    self.defaultMenuButtonInfo = {}
    return self
end
function WardrobeScreen.createFromExistingGui(gui, guiName)
    WardrobeCharactersFrame.createFromExistingGui(g_gui.frames.wardrobeCharacters.target, "WardrobeCharactersFrame")
    WardrobeColorsFrame.createFromExistingGui(g_gui.frames.wardrobeColors.target, "WardrobeColorsFrame")
    WardrobeItemsFrame.createFromExistingGui(g_gui.frames.wardrobeItems.target, "WardrobeItemsFrame")
    WardrobeOutfitsFrame.createFromExistingGui(g_gui.frames.wardrobeOutfits.target, "WardrobeOutfitsFrame")
    local newGui = WardrobeScreen.new()
    newGui.sceneRootNode = gui.sceneRootNode
    newGui.characterRootNode = gui.characterRootNode
    g_gui.guis[gui.name].target:delete()
    g_gui.guis[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, false)
    return newGui
end
function WardrobeScreen:onOpen()
    WardrobeScreen:superClass().onOpen(self)
    self.isClosePending = false
    self.currentPlayerStyle = PlayerStyle.new()
    self.temporaryPlayerStyle = PlayerStyle.new()
    local playerStyle = g_localPlayer.graphicsComponent:getStyle()
    if playerStyle == nil then
        Logging.error("Player should not have a nil style!")
        printCallstack()
    end
    if not playerStyle:isValid() then
        Logging.warning("Selected style is invalid, reset to default style!")
        playerStyle = PlayerStyle.defaultStyle(playerStyle)
    end
    self.currentPlayerStyle:copyFrom(playerStyle)
    self.currentPlayerStyle:loadConfigurationIfRequired()
    self.temporaryPlayerStyle:copyFrom(self.currentPlayerStyle)
    self:updatePagePlayerStyle()
    g_currentMission.environment:setCustomLighting(self.lighting)
    self.playerGraphics = HumanGraphicsComponent.new()
    self.playerGraphics:initialize()
    link(self.characterRootNode, self.playerGraphics.graphicsRootNode)
    self.playerGraphics:setModelYaw(self.characterRotY)
    self.isCharacterDirty = true
    self:updateBrandIcon()
    self.rotY = self.startRotY
    self.inputHorizontal = 0
    self.isDragging = false
    self.accumDraggingInput = 0
    self.lastInputMode = -1
    self.mouseDragActive = false
    self:registerActionEvents()
    self:updateInputGlyphs()
    self.previousCamera = g_cameraManager:getActiveCamera()
    g_cameraManager:setActiveCamera(self.camera)
    self:showContent(true)
    if self.needsBrandsInitialization then
        for _, config in pairs(self.currentPlayerStyle.configs) do
            for _, preset in pairs(config.items) do
                if preset.brandName ~= nil then
                    preset.brand = g_brandManager:getBrandByName(preset.brandName)
                    if preset.brand ~= nil then
                        preset.brandName = nil
                    end
                end
            end
        end
        self.needsBrandsInitialization = false
    end
end
function WardrobeScreen:onClose()
    self:removeActionEvents()
    self:showContent(false)
    g_currentMission.environment:setCustomLighting(nil)
    g_cameraManager:setActiveCamera(self.previousCamera)
    if self.playerGraphics ~= nil then
        self.playerGraphics:delete()
        self.playerGraphics = nil
    end
    self:showLoadingDialog(false)
    self.isNewCharacter = false
    WardrobeScreen:superClass().onClose(self)
end
function WardrobeScreen:onDetailClosed(_)
    if self.colorDetailCallback ~= nil and not self.isPoppingDetailSafely then
        self.colorDetailCallback(false)
        self.colorDetailCallback = nil
    end
end
function WardrobeScreen:updatePagePlayerStyle()
    local style = self.temporaryPlayerStyle
    local savedStyle = self.currentPlayerStyle
    self.pageCharacter:setPlayerStyle(style, savedStyle)
    self.pageHair:setPlayerStyle(style, savedStyle)
    self.pageBeard:setPlayerStyle(style, savedStyle)
    self.pageHeadgear:setPlayerStyle(style, savedStyle)
    self.pageFootwear:setPlayerStyle(style, savedStyle)
    self.pageTop:setPlayerStyle(style, savedStyle)
    self.pageBottom:setPlayerStyle(style, savedStyle)
    self.pageGloves:setPlayerStyle(style, savedStyle)
    self.pageGlasses:setPlayerStyle(style, savedStyle)
    self.pageColors:setPlayerStyle(style, savedStyle)
    self.pageOutfit:setPlayerStyle(style, savedStyle)
end
function WardrobeScreen:onGuiSetupFinished()
    WardrobeScreen:superClass().onGuiSetupFinished(self)
    self:initializePages()
    self:setupMenuPages()
end
function WardrobeScreen:initializePages()
    self.pageCharacter:initialize("face", self, "character_option_body", WardrobeScreen.SLICE_ID.CHARACTER)
    self.pageHair:initialize("hairStyle", self, "character_option_hairStyle", WardrobeScreen.SLICE_ID.HAIR)
    self.pageBeard:initialize("beard", self, "character_option_beardStyle", WardrobeScreen.SLICE_ID.BEARD)
    self.pageHeadgear:initialize("headgear", self, "character_option_headGear", WardrobeScreen.SLICE_ID.HEADGEAR)
    self.pageFootwear:initialize("footwear", self, "character_option_footwear", WardrobeScreen.SLICE_ID.FOOTWEAR)
    self.pageTop:initialize("top", self, "character_option_top", WardrobeScreen.SLICE_ID.TOP)
    self.pageBottom:initialize("bottom", self, "character_option_bottom", WardrobeScreen.SLICE_ID.BOTTOM)
    self.pageGloves:initialize("gloves", self, "character_option_gloves", WardrobeScreen.SLICE_ID.GLOVES)
    self.pageGlasses:initialize("glasses", self, "character_option_glasses", WardrobeScreen.SLICE_ID.GLASSES)
    self.pageOutfit:initialize(self, "character_option_outfits", WardrobeScreen.SLICE_ID.OUTFIT)
    self.pageColors:initialize(self)
end
function WardrobeScreen:setupMenuPages()
    local function rootPagePredicate()
        -- upvalues: (copy) self
        return not self:getIsDetailMode()
    end
    for i, pageDef in ipairs({
        { self.pageCharacter, rootPagePredicate, WardrobeScreen.SLICE_ID.CHARACTER },
        { self.pageHair, rootPagePredicate, WardrobeScreen.SLICE_ID.HAIR },
        { self.pageBeard, rootPagePredicate, WardrobeScreen.SLICE_ID.BEARD },
        { self.pageOutfit, rootPagePredicate, WardrobeScreen.SLICE_ID.OUTFIT },
        { self.pageTop, rootPagePredicate, WardrobeScreen.SLICE_ID.TOP },
        { self.pageBottom, rootPagePredicate, WardrobeScreen.SLICE_ID.BOTTOM },
        { self.pageFootwear, rootPagePredicate, WardrobeScreen.SLICE_ID.FOOTWEAR },
        { self.pageHeadgear, rootPagePredicate, WardrobeScreen.SLICE_ID.HEADGEAR },
        { self.pageGloves, rootPagePredicate, WardrobeScreen.SLICE_ID.GLOVES },
        { self.pageGlasses, rootPagePredicate, WardrobeScreen.SLICE_ID.GLASSES },
        { self.pageColors, function()
                -- upvalues: (copy) self
                return self:getIsDetailMode()
            end, WardrobeScreen.SLICE_ID.HEADGEAR }
    }) do
        local page, predicate, sliceId = unpack(pageDef)
        self:registerPage(page, i, predicate)
        self:addPageTab(page, nil, nil, sliceId)
    end
    self:rebuildTabList()
end
function WardrobeScreen:setupMenuButtonInfo()
    WardrobeScreen:superClass().setupMenuButtonInfo(self)
    local onButtonPagePreviousFunction = self:makeSelfCallback(self.onPagePrevious)
    local onButtonPageNextFunction = self:makeSelfCallback(self.onPageNext)
    self.backButtonInfo = {
        ["inputAction"] = InputAction.MENU_BACK,
        ["text"] = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BACK),
        ["callback"] = self.clickBackCallback
    }
    self.nextPageButtonInfo = {
        ["inputAction"] = InputAction.MENU_PAGE_NEXT,
        ["text"] = g_i18n:getText("ui_ingameMenuNext"),
        ["callback"] = onButtonPageNextFunction
    }
    self.prevPageButtonInfo = {
        ["inputAction"] = InputAction.MENU_PAGE_PREV,
        ["text"] = g_i18n:getText("ui_ingameMenuPrev"),
        ["callback"] = onButtonPagePreviousFunction
    }
    self.defaultMenuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
    self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
    self.defaultMenuButtonInfoByActions[InputAction.MENU_PAGE_PREV] = self.defaultMenuButtonInfo[2]
    self.defaultMenuButtonInfoByActions[InputAction.MENU_PAGE_NEXT] = self.defaultMenuButtonInfo[3]
    self.defaultButtonActionCallbacks = {
        [InputAction.MENU_BACK] = self.clickBackCallback,
        [InputAction.MENU_PAGE_PREV] = onButtonPagePreviousFunction,
        [InputAction.MENU_PAGE_NEXT] = onButtonPageNextFunction
    }
end
function WardrobeScreen:setNextOpenIsNewCharacter()
    self.isNewCharacter = true
end
function WardrobeScreen:onButtonBack()
    if not self.isClosePending then
        self.isClosePending = true
        self:showLoadingDialog(true)
        local style = self.currentPlayerStyle
        if not style:isValid() then
            Logging.warning("Selected style is invalid, reset to default style!")
            self.currentPlayerStyle:copyFrom(PlayerStyle.defaultStyle(style))
        end
        g_localPlayer:setStyleAsync(self.currentPlayerStyle, false, function(success)
            -- upvalues: (copy) self
            g_gameSettings:setLastPlayerStyle(self.currentPlayerStyle)
            g_gameSettings:save()
            self:exitMenu()
        end, false)
    end
end
function WardrobeScreen:update(dt)
    WardrobeScreen:superClass().update(self, dt)
    if self.isCharacterDirty then
        self:updateCharacter()
        self.isCharacterDirty = false
    end
    if self.updateAnimationCallback ~= nil and not self.updateAnimationCallback(dt) then
        self.updateAnimationCallback = nil
        if self.updateAnimationFinishedCallback ~= nil then
            self.updateAnimationFinishedCallback = nil
            self.updateAnimationFinishedCallback()
        end
    end
    if self.playerGraphics ~= nil then
        self.playerGraphics:defaultAllParameters()
        self.playerGraphics:update(dt)
    end
    self:updateInput(dt)
    self:updateCamera(dt)
end
function WardrobeScreen:updateCamera(_)
    if self.rotateNode ~= nil then
        setRotation(self.rotateNode, 0, self.rotY, 0)
    end
end
function WardrobeScreen:showContent(show)
    if show then
        self.header:setVisible(true)
        self.buttonsPanel:setVisible(true)
        self.background:setVisible(true)
        setVisibility(self.sceneRootNode, true)
    else
        self.header:setVisible(false)
        self.buttonsPanel:setVisible(false)
        self.background:setVisible(false)
        setVisibility(self.sceneRootNode, false)
    end
end
function WardrobeScreen:showLoadingDialog(show)
    self.loadingAnimation:setVisible(show)
end
function WardrobeScreen:runAnimation(duration, tick, finish)
    self.animationTime = duration
    function self.updateAnimationCallback(dt)
        -- upvalues: (copy) self, (copy) duration, (copy) tick
        self.animationTime = self.animationTime - dt
        tick((math.min(math.max(1 - self.animationTime / duration, 0), 1)))
        return self.animationTime > 0
    end
    self.updateAnimationFinishedCallback = finish
end
function WardrobeScreen:fadeOut(cb)
    self:runAnimation(150, function(t)
        -- upvalues: (copy) self
        self.fadeElement:setImageColor(nil, 0, 0, 0, Tween.CURVE.EASE_IN())
    end, cb)
end
function WardrobeScreen:fadeIn(cb)
    self:runAnimation(150, function(t)
        -- upvalues: (copy) self
        self.fadeElement:setImageColor(nil, 0, 0, 0, 1 - Tween.CURVE.EASE_OUT())
    end, cb)
end
function WardrobeScreen:loadMapData(_, _, _)
    self.sceneRootNode = createTransformGroup("CharacterArea")
    self.characterRootNode = createTransformGroup("CaracterRootNode")
    link(getRootNode(), self.sceneRootNode)
    link(self.sceneRootNode, self.characterRootNode)
    setTranslation(self.sceneRootNode, 0, -100, 100)
    setVisibility(self.sceneRootNode, false)
    setTranslation(self.characterRootNode, self.characterPosition[1], self.characterPosition[2], self.characterPosition[3])
    self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(WardrobeScreen.BACKGROUND_PATH, false, true, self.onLoadedWardrobeScene, self, nil)
    g_currentMission:startLoadingTask()
    self.hasLoadingTask = true
end
function WardrobeScreen:onLoadedWardrobeScene(node, _, _)
    removeFromPhysics(node)
    link(self.sceneRootNode, node)
    addToPhysics(node)
    self.rotY = self.startRotY
    self.rotateNode = createTransformGroup("rotateNode")
    link(self.characterRootNode, self.rotateNode)
    setWorldRotation(self.rotateNode, 0, self.rotY, 0)
    local cameraTargetNode = createTransformGroup("finalCameraPosNode")
    link(self.rotateNode, cameraTargetNode)
    setTranslation(cameraTargetNode, -1.35, 0.8, 0)
    setRotation(cameraTargetNode, -0.13962634015954636, 0.9599310885968813, 0)
    local dofSettings = g_depthOfFieldManager:createInfo(0.75, 2, 0.3, 3, 7, false)
    self.camera = createCamera("camera_ccscreen", WardrobeScreen.CAMERA_FOV, 2, 10000)
    g_cameraManager:addCamera(self.camera, nil, false, nil, dofSettings, false)
    link(cameraTargetNode, self.camera)
    setTranslation(self.camera, 0, 0, 4)
    self.lighting = LightingStatic.new()
    local xmlFile = XMLFile.load("wardrobeLighting", WardrobeScreen.LIGHTING_XML_PATH)
    self.lighting:load(xmlFile, "lighting", g_currentMission.baseDirectory)
    xmlFile:delete()
    self.scenePrepared = true
    if self.hasLoadingTask then
        g_currentMission:finishLoadingTask()
        self.hasLoadingTask = nil
    end
end
function WardrobeScreen:unloadMapData()
    if self.sceneRootNode ~= nil then
        delete(self.sceneRootNode)
        self.sceneRootNode = nil
        self.rotateNode = nil
        self.characterRootNode = nil
    end
    if self.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
        self.sharedLoadRequestId = nil
    end
    if self.lighting ~= nil then
        self.lighting:delete()
        self.lighting = nil
    end
    if self.hasLoadingTask then
        g_currentMission:finishLoadingTask()
        self.hasLoadingTask = nil
    end
    if self.camera ~= nil then
        g_cameraManager:removeCamera(self.camera)
    end
    self.scenePrepared = false
end
function WardrobeScreen:updateCharacter(isCreatingScene)
    if self.playerGraphics ~= nil and self.scenePrepared then
        self.loadingAnimation:setVisible(true)
        if not self.temporaryPlayerStyle:isValid() then
            Logging.warning("Selected style is invalid, reset to default style!")
            self.temporaryPlayerStyle:copyFrom(PlayerStyle.defaultStyle(self.temporaryPlayerStyle))
        end
        self.playerGraphics:setStyleAsync(self.temporaryPlayerStyle, function(_, loadingState, loadedNewPlayerModel)
            -- upvalues: (copy) self, (copy) isCreatingScene
            self:updateCharacterFinished(loadingState, loadedNewPlayerModel, isCreatingScene)
        end, nil, nil, true)
        if self.playerGraphics.model.xmlFilename ~= self.temporaryPlayerStyle.xmlFilename then
            setVisibility(self.characterRootNode, false)
        end
        if g_currentMission ~= nil and g_currentMission.playerSystem ~= nil then
            g_gameSettings:setValue(GameSettings.SETTING.LAST_PLAYER_STYLE_MALE, g_localPlayer.graphicsComponent:getStyle():getIsMale())
        end
    end
end
function WardrobeScreen:updateCharacterFinished(loadingState, loadedNewPlayerModel, _)
    if not loadedNewPlayerModel and loadingState == HumanModelLoadingState.OK then
        self.loadingAnimation:setVisible(false)
        setVisibility(self.characterRootNode, true)
    end
    self.loadingAnimation:setVisible(false)
    if loadingState == HumanModelLoadingState.OK then
        setVisibility(self.characterRootNode, true)
        self.playerGraphics:defaultAllParameters()
        self:updateBrandIcon()
        return
    elseif loadingState == HumanModelLoadingState.CANCELED then
        Logging.devInfo("Loading player model canceled")
    else
        Logging.error("Loading player model failed")
    end
end
function WardrobeScreen:updateBrandIcon()
    local brandImage = nil
    local configName = self.currentPage.configName
    local fallbackConfigName = nil
    if self.currentPage:isa(WardrobeOutfitsFrame) then
        configName = "onepiece"
        fallbackConfigName = "top"
    end
    if configName ~= nil then
        local index = self.temporaryPlayerStyle.configs[configName].selectedItemIndex
        local item = self.temporaryPlayerStyle.configs[configName].items[index]
        if item ~= nil and item.brandName ~= nil then
            item.brand = g_brandManager:getBrandByName(item.brandName)
            if item.brand ~= nil then
                item.brandName = nil
            end
        end
        if item == nil or item.brand == nil then
            if fallbackConfigName ~= nil then
                local item = self.temporaryPlayerStyle.configs[fallbackConfigName].items[self.temporaryPlayerStyle.configs[fallbackConfigName].selectedItemIndex]
                if item ~= nil and item.brand ~= nil then
                    brandImage = item.brand.image
                end
            end
        else
            brandImage = item.brand.image
        end
    end
    local index = self.brandIcon
    index:setVisible(brandImage ~= nil)
    if brandImage ~= nil then
        self.brandIcon:setImageFilename(brandImage)
    end
end
function WardrobeScreen:onItemSelectionStart()
    if self.temporaryPlayerStyle ~= nil then
        self.temporaryPlayerStyle:copyFrom(self.currentPlayerStyle)
        self.isCharacterDirty = true
    end
end
function WardrobeScreen:onItemSelectionChanged()
    self.isCharacterDirty = true
end
function WardrobeScreen:onItemSelectionConfirmed()
    self.currentPlayerStyle:copyFrom(self.temporaryPlayerStyle)
end
function WardrobeScreen:onItemSelectionCancelled()
    if self.temporaryPlayerStyle ~= nil then
        self.temporaryPlayerStyle:copyFrom(self.currentPlayerStyle)
        self.isCharacterDirty = true
    end
end
function WardrobeScreen:onItemShowColors(configName, item, itemsCallback)
    self.colorDetailCallback = itemsCallback
    self.pageColors:setConfigAndItem(configName, item)
    self:pushDetail(self.pageColors)
end
function WardrobeScreen:onColorSelectionChanged()
    self.isCharacterDirty = true
end
function WardrobeScreen:onColorSelectionConfirmed(keepOpen)
    if not keepOpen then
        self.isPoppingDetailSafely = true
        self:popDetail()
        self.isPoppingDetailSafely = false
    end
    self.colorDetailCallback(true, keepOpen)
    self.currentPlayerStyle:copyFrom(self.temporaryPlayerStyle)
    if not keepOpen then
        self.colorDetailCallback = nil
    end
end
function WardrobeScreen:onColorSelectionCancelled(keepOpen)
    if not keepOpen then
        self.isPoppingDetailSafely = true
        self:popDetail()
        self.isPoppingDetailSafely = false
    end
    self.colorDetailCallback(false, keepOpen)
    if not keepOpen then
        self.colorDetailCallback = nil
    end
end
function WardrobeScreen:registerActionEvents()
    if self.eventIdLeftRightController ~= nil then
        g_inputBinding:removeActionEvent(self.eventIdLeftRightController)
    end
    _, self.eventIdLeftRightController = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE, self, self.onCameraLeftRight, false, false, true, true)
    self.lastInputMode = -1
    self:updateInputContext()
end
function WardrobeScreen:removeActionEvents()
    g_inputBinding:removeActionEvent(self.eventIdLeftRightController)
    self.eventIdLeftRightController = nil
end
function WardrobeScreen:updateInputGlyphs()
    self.rotateCameraGlyph:setActions({ InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE })
end
function WardrobeScreen:onCameraLeftRight(_, inputValue, _, _)
    self.inputHorizontal = inputValue * -2
end
function WardrobeScreen:mouseEvent(posX, posY, isDown, isUp, _, _)
    if self:getIsActive() then
        if GuiUtils.checkOverlayOverlap(posX, posY, self.background.absPosition[1], self.background.absPosition[2], self.background.absSize[1], self.background.absSize[2]) then
            self.mouseDragActive = false
            return
        end
        if isDown then
            self.mouseDragActive = true
            self.lastMousePosX = posX
        end
        if isUp then
            self.mouseDragActive = false
        end
        if self.mouseDragActive then
            self.lastMousePosX = posX
            self.inputHorizontal = self.inputHorizontal + (posX - self.lastMousePosX) * 200
        end
    end
end
function WardrobeScreen:updateInput(dt)
    self:updateInputContext()
    if self.inputHorizontal ~= 0 then
        self.inputHorizontal = 0
        self.rotY = self.rotY - 0.001 * dt * self.inputHorizontal
    end
    self.inputDragging = false
end
function WardrobeScreen:updateInputContext()
    local currentInputMode = g_inputBinding:getLastInputMode()
    if currentInputMode ~= self.lastInputMode then
        g_inputBinding:setActionEventActive(self.eventIdLeftRightController, currentInputMode == GS_INPUT_HELP_MODE_GAMEPAD)
        self:updateInputGlyphs()
        self.lastInputMode = currentInputMode
        self.isDragging = false
    end
end
WardrobeScreen.SLICE_ID = {
    ["CHARACTER"] = "gui.wardrobe_character",
    ["HAIR"] = "gui.wardrobe_hairstyles",
    ["BEARD"] = "gui.wardrobe_beards",
    ["HEADGEAR"] = "gui.wardrobe_headgear",
    ["FOOTWEAR"] = "gui.wardrobe_shoes",
    ["TOP"] = "gui.wardrobe_tops",
    ["BOTTOM"] = "gui.wardrobe_bottoms",
    ["GLOVES"] = "gui.wardrobe_gloves",
    ["GLASSES"] = "gui.wardrobe_glasses",
    ["ONEPIECE"] = "gui.wardrobe_onepieceSuits",
    ["OUTFIT"] = "gui.wardrobe_outfits"
}