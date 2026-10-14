ShopConfigScreen = {}
local ShopConfigScreen_mt = Class(ShopConfigScreen, ScreenElement)
ShopConfigScreen.INPUT_CONTEXT_NAME = "MENU_SHOP_CONFIG"
ShopConfigScreen.FADE_TEXTURE_PATH = "dataS/menu/base/graph_pixel.png"
ShopConfigScreen.WORKSHOP_PATH = "$data/maps/textures/shared/uiStore.i3d"
ShopConfigScreen.NEAR_CLIP_DISTANCE = 0.2
ShopConfigScreen.MIN_CAMERA_HEIGHT = 0.1
ShopConfigScreen.MAX_CAMERA_HEIGHT = 9
ShopConfigScreen.MAX_CAMERA_DISTANCE = 17
ShopConfigScreen.CAMERA_MAX_DISTANCE_FACTOR = 3
ShopConfigScreen.DEFAULT_PREVIEW_SIZE = 5.2
ShopConfigScreen.CAMERA_MIN_DISTANCE_FACTOR = 0.8
ShopConfigScreen.FAR_BLUR_END_DISTANCE = 100
ShopConfigScreen.INITIAL_CAMERA_ROTATION_X_MIN = 0
ShopConfigScreen.INITIAL_CAMERA_ROTATION_X_MAX = 0.08726646259971647
ShopConfigScreen.INITIAL_CAMERA_ROTATION_X_REF_HEIGHT_MIN = 4.5
ShopConfigScreen.INITIAL_CAMERA_ROTATION_X_REF_HEIGHT_MAX = 2
ShopConfigScreen.INITIAL_CAMERA_ROTATION_Y_MIN = -2.530727415391778
ShopConfigScreen.INITIAL_CAMERA_ROTATION_Y_MAX = -2.007128639793479
ShopConfigScreen.INITIAL_CAMERA_ROTATION_Y_REF_WIDTH_MIN = 3
ShopConfigScreen.INITIAL_CAMERA_ROTATION_Y_REF_WIDTH_MAX = 15
ShopConfigScreen.MOUSE_SPEED_MULTIPLIER = 2
ShopConfigScreen.MIN_MOUSE_DRAG_INPUT = 0.02 * InputBinding.MOUSE_MOVE_BASE_FACTOR
ShopConfigScreen.NO_VEHICLE = {
    ["delete"] = function() end
}
ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG = "motor"
ShopConfigScreen.STORE_ITEM_FILL_UNIT_CONFIG = "fillUnit"
local function NO_CALLBACK() end
function ShopConfigScreen.register()
    local shopConfigScreen = ShopConfigScreen.new()
    g_gui:loadGui("dataS/gui/ShopConfigScreen.xml", "ShopConfigScreen", shopConfigScreen)
    return shopConfigScreen
end
function ShopConfigScreen.new(target, custom_mt)
    -- upvalues: (copy) ShopConfigScreen_mt, (copy) NO_CALLBACK
    local self = ScreenElement.new(target, custom_mt or ShopConfigScreen_mt)
    self.loadRequestIdWorkshop = nil
    self.fadeOverlay = Overlay.new(ShopConfigScreen.FADE_TEXTURE_PATH, 0, 0, 1, 1)
    self.fadeOverlay:setColor(0, 0, 0, 0)
    self.fadeInAnimation = TweenSequence.NO_SEQUENCE
    self.fadeOutAnimation = TweenSequence.NO_SEQUENCE
    self.rotateInputGlyph = nil
    self.zoomInputGlyph = nil
    self.lastInputHelpMode = nil
    self:createInputGlyphs()
    self.configBasePrice = 0
    self.totalPrice = 0
    self.initialLeasingCosts = 0
    self.lastMoney = 0
    self.displayableOptionCount = 0
    self.displayableColorCount = 0
    self.callbackFunc = nil
    self.requestExitCallback = NO_CALLBACK
    self.workshopWorldPosition = { 0, 0, 0 }
    self.workshopRootNode = nil
    self.workshopNode = nil
    self.cameraDistance = 10
    self.cameraMaxDistance = 20
    self.cameraMinDistance = 1
    self.zoomTarget = self.cameraDistance
    self.rotX = 0
    self.rotY = 0
    self.rotMinX = -0.17453292519943295
    self.rotMaxX = 1.2217304763960306
    self.focusY = 0
    self.vehicleSizeX = 1
    self.vehicleSizeY = 1
    self.vehicleSizeZ = 1
    self.rotateNode = nil
    self.cameraNode = nil
    self.previousCamera = nil
    self:createCamera()
    self:resetCamera()
    self.isLoadingInitial = false
    self.previewVehicleSize = 0
    self.previewVehicles = {}
    self.previousVehicles = {}
    self.loadingDelayFrames = 0
    self.loadingDelayTime = 0
    self.configItemCache = {}
    self.configItemCacheLarge = {}
    self.configurationToListElement = {}
    self.inputHorizontal = 0
    self.inputVertical = 0
    self.inputZoom = 0
    self.eventIdUpDownController = ""
    self.eventIdLeftRightController = ""
    self.eventIdUpDownMouse = ""
    self.eventIdLeftRightMouse = ""
    self.inputDragging = false
    self.isDragging = false
    self.accumDraggingInput = 0
    self.lastInputMode = g_inputBinding:getLastInputMode()
    self.lastInputHelpMode = g_inputBinding:getInputHelpMode()
    self.currentConfigSet = 1
    self:createFadeAnimations()
    g_messageCenter:subscribe(BuyVehicleEvent, self.onVehicleBought, self)
    g_messageCenter:subscribe(MessageType.STORE_ITEMS_RELOADED, self.onStoreItemsReloaded, self)
    self.openCounter = 0
    addConsoleCommand("gsShopUIToggle", "Toggle shop config screen UI visibility", "consoleCommandUIToggle", self)
    return self
end
function ShopConfigScreen.createFromExistingGui(gui, guiName)
    removeConsoleCommand("gsShopUIToggle")
    local newGui = ShopConfigScreen.new()
    local x, y, z = unpack(gui.workshopWorldPosition)
    newGui.workshopFilename = gui.workshopFilename
    g_gui.guis[guiName]:delete()
    g_gui.guis[guiName].target:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    g_shopConfigScreen = newGui
    newGui:createWorkshop(newGui.workshopFilename, x, y, z)
    newGui.openCounter = 1
    newGui:setReturnScreenClass(gui.returnScreenClass)
    newGui:setStoreItem(gui.storeItem, nil, gui.saleItem, nil, gui.configurations)
    newGui.openCounter = 0
    newGui:setCallbacks(gui.callbackFunc, gui.target)
    return newGui
end
function ShopConfigScreen:createInputGlyphs()
    local iconWidth, iconHeight = getNormalizedScreenValues(unpack(ShopConfigScreen.SIZE.INPUT_GLYPH))
    self.rotateInputGlyph = InputGlyphElement.new(g_inputDisplayManager, iconWidth, iconHeight)
    self.rotateInputGlyph:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_RIGHT)
    self.zoomInputGlyph = InputGlyphElement.new(g_inputDisplayManager, iconWidth, iconHeight)
    self.zoomInputGlyph:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_RIGHT)
end
function ShopConfigScreen:createFadeAnimations()
    local fadeInAnimation = TweenSequence.new(self)
    fadeInAnimation:addTween((Tween.new(self.fadeScreen, 1, 0, 300)))
    self.fadeInAnimation = fadeInAnimation
    local fadeOutAnimation = TweenSequence.new(self)
    fadeOutAnimation:addTween((Tween.new(self.fadeScreen, 0, 1, 300)))
    self.fadeOutAnimation = fadeOutAnimation
end
function ShopConfigScreen:fadeScreen(alpha)
    self.fadeOverlay:setColor(nil, nil, nil, alpha)
end
function ShopConfigScreen:createWorkshop(assetPath, posX, posY, posZ)
    self.workshopWorldPosition = { posX, posY, posZ }
    self.workshopRootNode = createTransformGroup("ShopConfigWorkshop")
    link(getRootNode(), self.workshopRootNode)
    setTranslation(self.workshopRootNode, posX, posY, posZ)
    setVisibility(self.workshopRootNode, false)
    self.loadRequestIdWorkshop = g_i3DManager:loadI3DFileAsync(assetPath, false, true, self.onWorkshopLoaded, self, nil)
end
function ShopConfigScreen:onWorkshopLoaded(node, _, _)
    if node ~= 0 then
        self.loadRequestIdWorkshop = nil
        self.workshopNode = node
        removeFromPhysics(self.workshopNode)
        setTranslation(self.workshopNode, 0, 0, 0)
        link(self.workshopRootNode, self.workshopNode)
        addToPhysics(self.workshopNode)
        self.workshopColorNodes = {}
        I3DUtil.getNodesByShaderParam(node, "colorScale", self.workshopColorNodes, true)
        if #self.workshopColorNodes > 0 then
            self.workshopDefaultColor = { getShaderParameter(self.workshopColorNodes[1], "colorScale") }
        end
    end
    local slotsVisible = g_currentMission.slotSystem:getAreSlotsVisible()
    self.shopSlotsIcon:setVisible(slotsVisible)
    self.shopSlotsText:setVisible(slotsVisible)
end
function ShopConfigScreen:onLicensePlateBoxLoaded(node, _, _)
    if node ~= 0 then
        self.creationBox = node
        setVisibility(node, false)
    end
end
function ShopConfigScreen:createCamera()
    self.rotateNode = createTransformGroup("VehicleConfigCameraTarget")
    link(getRootNode(), self.rotateNode)
    setRotation(self.rotateNode, 0, 3.141592653589793, 0)
    setTranslation(self.rotateNode, 0, 0, 0)
    self.cameraPositionNode = createTransformGroup("VehicleConfigCameraOffsetNode")
    setTranslation(self.cameraPositionNode, 0, 0, -self.cameraDistance)
    setRotation(self.cameraPositionNode, 0, 3.141592653589793, 0)
    link(self.rotateNode, self.cameraPositionNode)
    self.cameraNode = createCamera("VehicleConfigCamera", 1.0471975511965976, ShopConfigScreen.NEAR_CLIP_DISTANCE, 100)
    local dofInfo = g_depthOfFieldManager:createInfo(1, 1, 0.8, 15, 100, true)
    g_cameraManager:addCamera(self.cameraNode, nil, false, nil, dofInfo, false)
    link(self.cameraPositionNode, self.cameraNode)
end
function ShopConfigScreen:resetCamera()
    local alphaX = MathUtil.inverseLerp(ShopConfigScreen.INITIAL_CAMERA_ROTATION_X_REF_HEIGHT_MIN, ShopConfigScreen.INITIAL_CAMERA_ROTATION_X_REF_HEIGHT_MAX, self.vehicleSizeY)
    local alphaY = MathUtil.inverseLerp(ShopConfigScreen.INITIAL_CAMERA_ROTATION_Y_REF_WIDTH_MIN, ShopConfigScreen.INITIAL_CAMERA_ROTATION_Y_REF_WIDTH_MAX, self.vehicleSizeX)
    self.rotX = MathUtil.lerp(ShopConfigScreen.INITIAL_CAMERA_ROTATION_X_MIN, ShopConfigScreen.INITIAL_CAMERA_ROTATION_X_MAX, alphaX)
    self.rotY = MathUtil.lerp(ShopConfigScreen.INITIAL_CAMERA_ROTATION_Y_MIN, ShopConfigScreen.INITIAL_CAMERA_ROTATION_Y_MAX, alphaY)
    self.cameraDistance = (self.cameraMinDistance + self.cameraMaxDistance) * 0.5
end
function ShopConfigScreen:delete()
    g_messageCenter:unsubscribeAll(self)
    self.rotateInputGlyph:delete()
    self.zoomInputGlyph:delete()
    self.fadeOverlay:delete()
    self.configurationItemTemplate:delete()
    self.configurationItemTemplateLarge:delete()
    self.configurationItemPlate:delete()
    self.attributeItem:delete()
    self:deletePreviewVehicles()
    if self.workshopNode ~= nil then
        delete(self.workshopNode)
        self.workshopNode = nil
    end
    if self.creationBox ~= nil then
        delete(self.creationBox)
        self.creationBox = nil
    end
    if self.workshopRootNode ~= nil then
        delete(self.workshopRootNode)
        self.workshopRootNode = nil
    end
    if self.cameraNode ~= nil then
        g_cameraManager:removeCamera(self.cameraNode)
        self.cameraNode = nil
    end
    if self.rotateNode ~= nil then
        delete(self.rotateNode)
        self.rotateNode = nil
    end
    if self.loadRequestIdWorkshop ~= nil then
        g_i3DManager:cancelStreamI3DFile(self.loadRequestIdWorkshop)
    end
    for _, element in ipairs(self.configItemCache) do
        element:delete()
    end
    self.configItemCache = {}
    for _, element in ipairs(self.configItemCacheLarge) do
        element:delete()
    end
    self.configItemCacheLarge = {}
    removeConsoleCommand("gsShopUIToggle")
    ShopConfigScreen:superClass().delete(self)
end
function ShopConfigScreen:onGuiSetupFinished()
    ShopConfigScreen:superClass().onGuiSetupFinished(self)
    self.configurationItemTemplate:unlinkElement()
    FocusManager:removeElement(self.configurationItemTemplate)
    self.configurationItemTemplateLarge:unlinkElement()
    FocusManager:removeElement(self.configurationItemTemplateLarge)
    self.attributeItem:unlinkElement()
    self.configurationItemPlate:unlinkElement()
    FocusManager:removeElement(self.configurationItemPlate)
end
function ShopConfigScreen:updateBalanceText()
    local money = g_currentMission:getMoney()
    self.lastMoney = money
    self.currentBalanceText:setValue(money)
    if money <= -1 then
        self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE)
    else
        self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY)
    end
    if self.shopMoneyBox ~= nil then
        self.shopMoneyBox:invalidateLayout()
        self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
    end
end
function ShopConfigScreen:onMoneyChange()
    if g_localPlayer ~= nil then
        local farm = g_farmManager:getFarmById(g_localPlayer.farmId)
        if farm.money <= -1 then
            self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE, nil, true)
        else
            self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY, nil, true)
        end
        local moneyText = g_i18n:formatMoney(farm.money, 0, true, false)
        self.currentBalanceText:setText(moneyText)
        if self.shopMoneyBox ~= nil then
            self.shopMoneyBox:invalidateLayout()
            self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
        end
    end
end
function ShopConfigScreen:onSlotUsageChanged(slotsUsage, maxSlots)
    local slotsVisible = g_currentMission.slotSystem:getAreSlotsVisible()
    if slotsVisible then
        local text = string.format("%0d / %0d", slotsUsage, maxSlots)
        local profile = ShopMenu.GUI_PROFILE.SHOP_MONEY
        if slotsUsage / maxSlots >= ShopMenu.SLOTS_USAGE_CRITICAL_THRESHOLD then
            profile = ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE
        end
        self.shopSlotsText:applyProfile(profile)
        self.shopSlotsText:setText(text)
    end
    self.shopSlotsIcon:setVisible(slotsVisible)
    self.shopSlotsText:setVisible(slotsVisible)
    if self.shopMoneyBox ~= nil then
        self.shopMoneyBox:invalidateLayout()
        self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
    end
end
function ShopConfigScreen:processStoreItemUpkeep(storeItem, _, _)
    local dailyUpkeep = 0
    if storeItem.dailyUpkeep ~= nil then
        dailyUpkeep = storeItem.dailyUpkeep
        for name, id in pairs(self.configurations) do
            local configs = storeItem.configurations[name]
            if configs ~= nil and configs[id] ~= nil then
            end
        end
    end
    return dailyUpkeep
end
function ShopConfigScreen:processStoreItemPowerOutput(storeItem, _, _)
    local power = 0
    if storeItem.specs ~= nil and storeItem.specs.power ~= nil then
        power = storeItem.specs.power
        if self.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG] ~= nil and storeItem.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG] ~= nil then
            power = Utils.getNoNil(storeItem.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG][self.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG]].power, power)
        end
    end
    return power
end
function ShopConfigScreen:processStoreItemFuelCapacity(storeItem, realItem, _, fuelFillType)
    return Motorized.getSpecValueFuel(storeItem, realItem, self.configurations, fuelFillType, true) or 0
end
function ShopConfigScreen:processStoreItemCapacity(storeItem, realItem, saleItem)
    if storeItem.specs == nil or storeItem.specs.capacity == nil then
        return 0, nil
    else
        return FillUnit.getSpecValueCapacity(storeItem, realItem, self.configurations, saleItem, true)
    end
end
function ShopConfigScreen.processStoreItemWeight(_, storeItem, realItem, saleItem)
    if storeItem.specs == nil or storeItem.specs.weight == nil then
        return 0, 0
    end
    local baseWeight = Vehicle.getSpecValueWeight(storeItem, realItem, nil, saleItem, true)
    local additionalWeight = 0
    if storeItem.specs.additionalWeight ~= nil then
        additionalWeight = Vehicle.getSpecValueAdditionalWeight(storeItem, realItem, nil, saleItem, true)
    end
    return baseWeight, additionalWeight
end
function ShopConfigScreen:processStoreItemWorkingWidth(storeItem, realItem, saleItem)
    if storeItem.specs ~= nil then
        if storeItem.specs.workingWidth ~= nil then
            return storeItem.specs.workingWidth.minWidth, storeItem.specs.workingWidth.width
        end
        if storeItem.specs.workingWidthConfig ~= nil then
            local width = Vehicle.getSpecValueWorkingWidthConfig(storeItem, realItem, self.configurations, saleItem, true) or 0
            return width, width
        end
    end
    return nil, nil
end
function ShopConfigScreen.processStoreItemWorkingSpeed(_, storeItem, _, _)
    return (storeItem.specs == nil or storeItem.specs.speedLimit == nil) and 0 or storeItem.specs.speedLimit
end
function ShopConfigScreen:processStoreItemPowerNeeded(storeItem, _, _)
    return (storeItem.specs == nil or storeItem.specs.neededPower == nil) and 0 or (storeItem.specs.neededPower.config[self.configurations.powerConsumer] or (storeItem.specs.neededPower.base or 0))
end
function ShopConfigScreen.processStoreItemBalerBaleSize(_, storeItem)
    if storeItem.specs ~= nil then
        local balerBaleSize = storeItem.specs.balerBaleSizeRound or storeItem.specs.balerBaleSizeSquare
        if balerBaleSize ~= nil then
            local size = Baler.getSpecValueBaleSize(storeItem, nil, nil, nil, false, false, balerBaleSize.isRoundBaler)
            if balerBaleSize.isRoundBaler then
                return size, ShopConfigScreen.GUI_PROFILE.BALE_SIZE_ROUND
            else
                return size, ShopConfigScreen.GUI_PROFILE.BALE_SIZE_SQUARE
            end
        end
    end
    return ""
end
function ShopConfigScreen.processStoreItemBaleWrapperBaleSize(_, storeItem)
    if storeItem.specs == nil then
        return nil, nil
    end
    local roundBaleSize = BaleWrapper.getSpecValueBaleSizeRound(storeItem, nil, nil, nil, false, false)
    local squareBaleSize = BaleWrapper.getSpecValueBaleSizeSquare(storeItem, nil, nil, nil, false, false)
    if roundBaleSize == nil and squareBaleSize == nil then
        roundBaleSize = InlineWrapper.getSpecValueBaleSizeRound(storeItem, nil, nil, nil, false, false)
        squareBaleSize = InlineWrapper.getSpecValueBaleSizeSquare(storeItem, nil, nil, nil, false, false)
    end
    return roundBaleSize, squareBaleSize
end
function ShopConfigScreen.processStoreItemBaleLoaderBaleSize(_, storeItem)
    if storeItem.specs == nil then
        return nil, nil
    else
        return BaleLoader.getSpecValueBaleSizeRound(storeItem, nil, nil, nil, false, false), BaleLoader.getSpecValueBaleSizeSquare(storeItem, nil, nil, nil, false, false)
    end
end
function ShopConfigScreen:processStoreItemWoodHarvesterMaxTreeSize(storeItem, realItem, saleItem)
    if storeItem.specs == nil or storeItem.specs.woodHarvesterMaxTreeSize == nil then
        return nil
    else
        return WoodHarvester.getSpecValueMaxTreeSize(storeItem, realItem, self.configurations, saleItem, false)
    end
end
function ShopConfigScreen:processAttributeData(storeItem, vehicle, saleItem)
    local dailyUpkeep = 0
    local powerOutput = 0
    local transmissionName = nil
    local fuelCapacity = 0
    local electricCapacity = 0
    local methaneCapacity = 0
    local defCapacity = 0
    local maxSpeed = 0
    local capacity = 0
    local capacityUnit = nil
    local weight = 0
    local additionalWeight = 0
    local workingWidthMin = math.huge
    local workingWidthMax = -math.huge
    local workingSpeed = 0
    local powerNeeded = 0
    local wheelNames = ""
    local baleSize = ""
    local baleSizeProfile = ShopConfigScreen.GUI_PROFILE.BALE_SIZE_ROUND
    local wrapperBaleSizeRound = nil
    local wrapperBaleSizeSquare = nil
    local loaderBaleSizeRound = nil
    local loaderBaleSizeSquare = nil
    local woodHarvesterMaxTreeSize = nil
    local fellerBuncherMaxRadius = 0
    local baleGrabMaxSizeRound = nil
    local baleGrabMaxSizeSquare = nil
    local maxYarderLength = 0
    local maxYarderTreeMass = 0
    local maxWinchMass = 0
    local tireNames
    if storeItem.bundleInfo == nil then
        tireNames = { storeItem }
    else
        tireNames = {}
        local i = 1
        local tireNames = #storeItem.bundleInfo.bundleItems
        for i = i, tireNames do
            table.insert(tireNames, storeItem.bundleInfo.bundleItems[i].item)
        end
    end
    for itemIndex, item in ipairs(tireNames) do
        StoreItemUtil.loadSpecsFromXML(item)
        local realItem = self.previewVehicles[itemIndex] or vehicle
        dailyUpkeep = dailyUpkeep + self:processStoreItemUpkeep(item, realItem, saleItem)
        powerOutput = powerOutput + self:processStoreItemPowerOutput(item, realItem, saleItem)
        transmissionName = transmissionName or Motorized.getSpecValueTransmission(storeItem, realItem, nil, saleItem)
        fuelCapacity = fuelCapacity + self:processStoreItemFuelCapacity(item, realItem, saleItem, FillType.DIESEL)
        electricCapacity = electricCapacity + self:processStoreItemFuelCapacity(item, realItem, saleItem, FillType.ELECTRICCHARGE)
        methaneCapacity = methaneCapacity + self:processStoreItemFuelCapacity(item, realItem, saleItem, FillType.METHANE)
        defCapacity = defCapacity + self:processStoreItemFuelCapacity(item, realItem, saleItem, FillType.DEF)
        local itemCapacity, itemCapacityUnit = self:processStoreItemCapacity(item, realItem, saleItem)
        if capacityUnit ~= nil and (itemCapacityUnit ~= nil and itemCapacityUnit ~= capacityUnit) then
            printWarning("Warning: Bundled store items have different fill capacity units. Check " .. tostring(storeItem.xmlFilename))
        end
        capacityUnit = capacityUnit or itemCapacityUnit
        local itemWeight, itemAdditionalWeight = self:processStoreItemWeight(item, realItem, saleItem)
        local itemMinWidth, itemMaxWidth = self:processStoreItemWorkingWidth(item, realItem, saleItem)
        if itemMinWidth ~= nil and itemMaxWidth ~= nil then
            workingWidthMin = math.min(workingWidthMin, itemMinWidth)
            workingWidthMax = math.max(workingWidthMax, itemMaxWidth)
        end
        workingSpeed = math.max(workingSpeed, self:processStoreItemWorkingSpeed(item, realItem, saleItem))
        local roundSize = Motorized.getSpecValueMaxSpeed(storeItem, realItem, self.configurations, saleItem, true, false) or 0
        maxSpeed = math.max(maxSpeed, roundSize)
        powerNeeded = powerNeeded + self:processStoreItemPowerNeeded(item, realItem, saleItem)
        local itemBaleSize, itemBaleSizeProfile = self:processStoreItemBalerBaleSize(item)
        if baleSize ~= "" then
            itemBaleSizeProfile = baleSizeProfile
            itemBaleSize = baleSize
        end
        local roundSize, squareSize = self:processStoreItemBaleWrapperBaleSize(item)
        local radius, _ = self:processStoreItemBaleLoaderBaleSize(item)
        baleGrabMaxSizeRound = BaleGrab.getSpecValueMaxSizeRound(storeItem, realItem, self.configurations, saleItem, false, false) or baleGrabMaxSizeRound
        baleGrabMaxSizeSquare = BaleGrab.getSpecValueMaxSizeSquare(storeItem, realItem, self.configurations, saleItem, false, false) or baleGrabMaxSizeSquare
        woodHarvesterMaxTreeSize = self:processStoreItemWoodHarvesterMaxTreeSize(item)
        local radius, _ = FellerBuncher.getSpecValueMaxTreeSize(storeItem, realItem, self.configurations, saleItem, true, false)
        fellerBuncherMaxRadius = math.max(radius or 0, fellerBuncherMaxRadius)
        maxYarderLength = math.max(YarderTower.getSpecValueMaxLength(storeItem, realItem, self.configurations, saleItem, true, false) or 0, maxYarderLength)
        maxYarderTreeMass = math.max(YarderTower.getSpecValueMaxMass(storeItem, realItem, self.configurations, saleItem, true, false) or 0, maxYarderTreeMass)
        maxWinchMass = math.max(Winch.getSpecValueMaxMass(storeItem, realItem, self.configurations, saleItem, true, false) or 0, maxWinchMass)
        baleSize = itemBaleSize
    end
    if vehicle ~= nil then
        local tireNames = Wheels.getTireNames(vehicle)
        if tireNames ~= nil then
            wheelNames = table.concatKeys(tireNames, " / ")
        end
    end
    local tireNames = {}
    if dailyUpkeep ~= 0 then
        local itemIndex = {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.MAINTENANCE_COST,
            ["value"] = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.MAINTENANCE_COST), g_i18n:formatMoney(dailyUpkeep, 2))
        }
        table.insert(tireNames, itemIndex)
    end
    if powerOutput ~= 0 then
        local hp, i = g_i18n:getPower(powerOutput)
        local realItem = {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.POWER,
            ["value"] = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.POWER), MathUtil.round(i), MathUtil.round(hp))
        }
        table.insert(tireNames, realItem)
    end
    if transmissionName ~= nil then
        table.insert(tireNames, {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.TRANSMISSION,
            ["value"] = transmissionName
        })
    end
    if fuelCapacity == 0 then
        if electricCapacity == 0 then
            if methaneCapacity ~= 0 then
                local itemIndex = {
                    ["profile"] = ShopConfigScreen.GUI_PROFILE.METHANE,
                    ["value"] = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.FUEL), methaneCapacity, g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_KG))
                }
                table.insert(tireNames, itemIndex)
            end
        else
            local itemIndex = {
                ["profile"] = ShopConfigScreen.GUI_PROFILE.ELECTRICCHARGE,
                ["value"] = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.FUEL), electricCapacity, g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_KW))
            }
            table.insert(tireNames, itemIndex)
        end
    elseif defCapacity == 0 then
        local itemIndex = {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.FUEL,
            ["value"] = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.FUEL), fuelCapacity, g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_LITER))
        }
        table.insert(tireNames, itemIndex)
    elseif defCapacity > 0 then
        local itemIndex = {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.FUEL,
            ["value"] = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.FUEL_DEF), fuelCapacity, g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_LITER), defCapacity, g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_LITER), g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.DEF_SHORT))
        }
        table.insert(tireNames, itemIndex)
    end
    if maxSpeed ~= 0 then
        local itemIndex = {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.MAX_SPEED,
            ["value"] = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.MAX_SPEED), string.format("%1d", g_i18n:getSpeed(maxSpeed)), g_i18n:getSpeedMeasuringUnit())
        }
        table.insert(tireNames, itemIndex)
    end
    if capacity ~= 0 and capacityUnit ~= nil then
        if capacityUnit:sub(1, 6) == "$l10n_" then
            capacityUnit = capacityUnit:sub(7)
        end
        local itemIndex = {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.CAPACITY,
            ["value"] = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.CAPACITY), capacity, g_i18n:getText(capacityUnit))
        }
        table.insert(tireNames, itemIndex)
    end
    if weight ~= 0 then
        local itemIndex = {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.WEIGHT,
            ["value"] = g_i18n:formatMass(weight)
        }
        table.insert(tireNames, itemIndex)
    end
    if additionalWeight ~= 0 then
        local itemIndex = {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.ADDITIONAL_WEIGHT,
            ["value"] = g_i18n:formatMass(additionalWeight)
        }
        table.insert(tireNames, itemIndex)
    end
    if powerNeeded ~= 0 then
        local hp, i = g_i18n:getPower(powerNeeded)
        local realItem = {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.POWER_REQUIREMENT,
            ["value"] = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.POWER_REQUIREMENT), MathUtil.round(i), MathUtil.round(hp))
        }
        table.insert(tireNames, realItem)
    end
    if workingWidthMin ~= math.huge and workingWidthMax ~= -math.huge then
        local i
        if workingWidthMin == workingWidthMax then
            i = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.WORKING_WIDTH), g_i18n:formatNumber(workingWidthMax, 1, true))
        else
            i = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.WORKING_WIDTH), string.format("%s-%s", g_i18n:formatNumber(workingWidthMin, 1, true), g_i18n:formatNumber(workingWidthMax, 1, true)))
        end
        table.insert(tireNames, {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.WORKING_WIDTH,
            ["value"] = i
        })
    end
    if workingSpeed ~= 0 then
        local itemIndex = {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.WORKING_SPEED,
            ["value"] = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.WORKING_SPEED), string.format("%1d", g_i18n:getSpeed(workingSpeed)), g_i18n:getSpeedMeasuringUnit())
        }
        table.insert(tireNames, itemIndex)
    end
    if wheelNames ~= "" then
        table.insert(tireNames, {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.WHEELS,
            ["value"] = wheelNames
        })
    end
    if baleSize ~= nil and baleSize ~= "" then
        table.insert(tireNames, {
            ["profile"] = baleSizeProfile,
            ["value"] = baleSize
        })
    end
    if wrapperBaleSizeRound ~= nil then
        table.insert(tireNames, {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.BALEWRAPPER_SIZE_ROUND,
            ["value"] = wrapperBaleSizeRound
        })
    end
    if wrapperBaleSizeSquare ~= nil then
        table.insert(tireNames, {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.BALEWRAPPER_SIZE_SQUARE,
            ["value"] = wrapperBaleSizeSquare
        })
    end
    if loaderBaleSizeRound ~= nil then
        table.insert(tireNames, {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.BALE_SIZE_ROUND,
            ["value"] = loaderBaleSizeRound
        })
    end
    if loaderBaleSizeSquare ~= nil then
        table.insert(tireNames, {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.BALE_SIZE_SQUARE,
            ["value"] = loaderBaleSizeSquare
        })
    end
    if baleGrabMaxSizeRound ~= nil then
        table.insert(tireNames, {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.BALE_SIZE_ROUND,
            ["value"] = baleGrabMaxSizeRound
        })
    end
    if baleGrabMaxSizeSquare ~= nil then
        table.insert(tireNames, {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.BALE_SIZE_SQUARE,
            ["value"] = baleGrabMaxSizeSquare
        })
    end
    if woodHarvesterMaxTreeSize ~= nil then
        table.insert(tireNames, {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.MAX_TREE_SIZE,
            ["value"] = woodHarvesterMaxTreeSize
        })
    end
    if fellerBuncherMaxRadius ~= 0 then
        local itemIndex = {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.MAX_TREE_SIZE,
            ["value"] = string.format("%d%s", MathUtil.round(fellerBuncherMaxRadius), g_i18n:getText("unit_cmShort"))
        }
        table.insert(tireNames, itemIndex)
    end
    if maxYarderLength ~= 0 then
        local itemIndex = {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.YARDER_MAX_LENGTH,
            ["value"] = string.format("%d%s", maxYarderLength, g_i18n:getText("unit_mShort"))
        }
        table.insert(tireNames, itemIndex)
    end
    if maxYarderTreeMass ~= 0 then
        local itemIndex = {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.MAX_TREE_MASS,
            ["value"] = string.format("%.1f%s", maxYarderTreeMass, g_i18n:getText("unit_tonsShort"))
        }
        table.insert(tireNames, itemIndex)
    end
    if maxWinchMass ~= 0 then
        local itemIndex = {
            ["profile"] = ShopConfigScreen.GUI_PROFILE.MAX_TREE_MASS,
            ["value"] = string.format("%.1f%s", maxWinchMass, g_i18n:getText("unit_tonsShort"))
        }
        table.insert(tireNames, itemIndex)
    end
    self:registerCustomSpecValues(tireNames, tireNames, vehicle, saleItem)
    local itemIndex = 1
    local hp = #self.attributesLayout.elements
    local i = 1
    for itemIndex = itemIndex, hp, i do
        self.attributesLayout.elements[1]:delete()
    end
    for item, realItem in ipairs(tireNames) do
        local itemCapacity = self.attributeItem:clone(self.attributesLayout)
        local itemCapacityUnit = itemCapacity:getDescendantByName("icon")
        local itemWeight = itemCapacity:getDescendantByName("text")
        itemCapacityUnit:applyProfile(realItem.profile)
        itemWeight:setText(realItem.value)
    end
    self.attributesLayout:invalidateLayout()
end
function ShopConfigScreen:registerCustomSpecValues(values, storeItems, vehicle, saleItem) end
function ShopConfigScreen:getConfigurationCostsAndChanges(storeItem, vehicle, saleItem)
    local basePrice = 0
    local upgradePrice = 0
    local hasChanges = false
    if vehicle == nil then
        if saleItem ~= nil then
            local basePrice, upgradePrice = g_currentMission.economyManager:getBuyPrice(storeItem, self.configurations, saleItem)
            return basePrice - upgradePrice, upgradePrice, true
        end
        if storeItem ~= nil then
            hasChanges = true
            local basePrice
            basePrice, upgradePrice = g_currentMission.economyManager:getBuyPrice(storeItem, self.configurations)
        end
    else
        for name, id in pairs(self.configurations) do
            if vehicle.configurations[name] ~= id then
                hasChanges = true
                if not ConfigurationUtil.hasBoughtConfiguration(self.vehicle, name, id) then
                end
            end
        end
        hasChanges = ConfigurationUtil.getConfigurationDataHasChanged(self.vehicle.configFileName, self.configurationData, vehicle.configurationData) and true or hasChanges
        if self.vehicle.getLicensePlatesDataIsEqual ~= nil and not self.vehicle:getLicensePlatesDataIsEqual(self.licensePlateData) then
            return basePrice, upgradePrice, true
        end
    end
    return basePrice, upgradePrice, hasChanges
end
function ShopConfigScreen:updatePriceData(basePrice, upgradePrice)
    self.totalPrice = basePrice + upgradePrice
    self.initialLeasingCosts = 0
    self.initialLeasingCosts = g_currentMission.economyManager:getInitialLeasingPrice(self.totalPrice)
    self.basePriceText:setText(g_i18n:formatMoney(basePrice, 0, true, false))
    self.upgradesPriceText:setText("+ " .. g_i18n:formatMoney(upgradePrice, 0, true, false))
    self.totalPriceText:setText(g_i18n:formatMoney(self.totalPrice, 0, true, false))
end
function ShopConfigScreen:updateData(storeItem, vehicle, saleItem)
    local basePrice, upgradePrice, hasChanges = self:getConfigurationCostsAndChanges(storeItem, vehicle, saleItem)
    self:updatePriceData(basePrice, upgradePrice)
    self.buyButton:setDisabled(not hasChanges)
    self:loadCurrentConfiguration(storeItem)
end
function ShopConfigScreen.getDefaultConfigurationColorIndex(_, configName, configItems, vehicle)
    local index = nil
    for k, item in pairs(configItems) do
        if item.isDefault then
            index = k
            break
        end
    end
    if vehicle ~= nil then
        index = vehicle.configurations[configName]
    end
    return index == nil and 1 or index
end
function ShopConfigScreen:updateButtons(storeItem, vehicle, saleItem)
    local buyButtonText = self.leaseButton
    buyButtonText:setVisible(vehicle == nil and storeItem.allowLeasing and saleItem ~= nil)
    local buyButtonText = g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.BUTTON_BUY)
    if vehicle ~= nil then
        buyButtonText = g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.BUTTON_CONFIGURE)
    end
    self.buyButton:setText(buyButtonText)
    self.buyButton:updateAbsolutePosition()
    self.buttonsPanel:invalidateLayout()
end
function ShopConfigScreen:loadCurrentConfiguration(storeItem)
    if self.currentVehicleLoading ~= nil then
        self.currentVehicleLoading:cancelLoading()
    end
    local data = VehicleLoadingData.new()
    data:setPosition(self.workshopWorldPosition[1], self.workshopWorldPosition[2], self.workshopWorldPosition[3])
    if not storeItem.shopIgnoreLastComponentPositions then
        for _, preVehicle in ipairs(self.previewVehicles) do
            if preVehicle.configFileName == storeItem.xmlFilename then
                data:setComponentPositionData(preVehicle)
            end
        end
    end
    data:setStoreItem(storeItem)
    data:setConfigurations(self.configurations)
    data:setConfigurationData(self.configurationData)
    data:setPropertyState(VehiclePropertyState.SHOP_CONFIG)
    data:setCustomParameter("foldableInvertFoldState", MathUtil.round(storeItem.shopFoldingState, 0) == 1)
    data:setCustomParameter("foldableFoldingTime", storeItem.shopFoldingTime)
    data:setForceServer(true)
    data:setIsRegistered(false)
    data:setIsSaved(false)
    data:setSaleItem(self.saleItem)
    self.currentVehicleLoading = data
    self.loadingAnimation:setVisible(true)
    data:load(self.onVehiclesLoaded, self, {
        ["openCounter"] = self.openCounter
    })
end
function ShopConfigScreen:onVehiclesLoaded(vehicles, loadingState, asyncArguments)
    self.currentVehicleLoading = nil
    if loadingState == VehicleLoadingState.CANCELED then
        return
    elseif loadingState == VehicleLoadingState.OK then
        if asyncArguments.openCounter == self.openCounter then
            if self.isLoadingInitial or self.isOpen then
                for _, vehicle in ipairs(self.previewVehicles) do
                    vehicle:removeFromPhysics()
                    table.insert(self.previousVehicles, vehicle)
                end
                self.previewVehicles = vehicles
                for _, vehicle in ipairs(vehicles) do
                    vehicle:setVisibility(false)
                    vehicle.forceIsActive = true
                end
                for _, vehicle in ipairs(vehicles) do
                    self:processAttributeData(self.storeItem, vehicle)
                    if vehicle.setLicensePlatesData ~= nil and (vehicle.getHasLicensePlates ~= nil and vehicle:getHasLicensePlates()) then
                        local defaultPlacementIndex, hasFrontPlate = vehicle:getLicensePlateDialogSettings()
                        self.licensePlateData.defaultPlacementIndex = defaultPlacementIndex
                        self.licensePlateData.hasFrontPlate = hasFrontPlate
                        if not self.licensePlateData.customized and defaultPlacementIndex ~= nil then
                            self.licensePlateData.placementIndex = defaultPlacementIndex
                        end
                        vehicle:setLicensePlatesData(self.licensePlateData)
                        self:updateLicensePlateGraphics()
                    end
                    if vehicle.addDamageAmount ~= nil and vehicle.addWearAmount ~= nil then
                        if self.saleItem == nil then
                            if self.vehicle ~= nil and (self.vehicle.getDamageAmount ~= nil and self.vehicle.getWearTotalAmount ~= nil) then
                                vehicle:addDamageAmount(self.vehicle:getDamageAmount(), true)
                                vehicle:addWearAmount(self.vehicle:getWearTotalAmount(), true)
                            end
                        else
                            vehicle:addDamageAmount(self.saleItem.damage or 0, true)
                            vehicle:addWearAmount(self.saleItem.wear or 0, true)
                        end
                    end
                    if vehicle.setDirtAmount ~= nil and (self.vehicle ~= nil and self.vehicle.getDirtAmount ~= nil) then
                        vehicle:setDirtAmount(self.vehicle:getDirtAmount())
                    end
                end
                local loadingDelayTime = 0
                local loadingDelayTime
                if self.isLoadingInitial then
                end
                self.loadingDelayTime = loadingDelayTime
                self.loadingDelayFrames = 3
            else
                for _, vehicle in ipairs(vehicles) do
                    vehicle:delete()
                end
                self.previewVehicles = {}
            end
        else
            for _, vehicle in ipairs(vehicles) do
                vehicle:delete()
            end
            return
        end
    else
        if g_currentMission ~= nil then
            Logging.error("Could not load vehicle defined in [%s]. Check vehicle configuration and mods.", (tostring(self.storeItem.xmlFilename)))
            self.callbackFunc = nil
            self:onClickBack()
        end
        return
    end
end
function ShopConfigScreen:onFinishedLoading()
    local numVehicles = #self.previousVehicles
    local minX = 1
    local maxX = -1
    for numVehicles = numVehicles, minX, maxX do
        self.previousVehicles[numVehicles]:delete()
        self.previousVehicles[numVehicles] = nil
    end
    for _, loadedVehicle in pairs(self.previewVehicles) do
        loadedVehicle:setVisibility(true)
    end
    if numVehicles == 0 then
        self.vehicleSizeY = 1
        self.previewVehicleSize = 0
        local minX = math.huge
        local maxX = -math.huge
        local i = math.huge
        local _ = -math.huge
        for _, vehicle in pairs(self.previewVehicles) do
            local largestDimension = math.max(vehicle.size.width, vehicle.size.length, self.storeItem.shopHeight * 1.5)
            self.previewVehicleSize = self.previewVehicleSize + largestDimension
            self.vehicleSizeY = math.max(self.vehicleSizeY, vehicle.size.height)
            local x1, _, z1 = localToLocal(vehicle.rootNode, self.workshopRootNode, vehicle.size.width * 0.5 + vehicle.size.widthOffset, 0, vehicle.size.length * 0.5 + vehicle.size.lengthOffset)
            local x2, _, z2 = localToLocal(vehicle.rootNode, self.workshopRootNode, halfWidth + vehicle.size.widthOffset, 0, -halfLength + vehicle.size.lengthOffset)
            local x3, _, z3 = localToLocal(vehicle.rootNode, self.workshopRootNode, -halfWidth + vehicle.size.widthOffset, 0, -halfLength + vehicle.size.lengthOffset)
            local x4, _, z4 = localToLocal(vehicle.rootNode, self.workshopRootNode, -halfWidth + vehicle.size.widthOffset, 0, halfLength + vehicle.size.lengthOffset)
            minX = math.min(x1, x2, x3, x4, minX)
            maxX = math.max(x1, x2, x3, x4, maxX)
            i = math.min(z1, z2, z3, z4, i)
            _ = math.max(z1, z2, z3, z4, _)
        end
        self.vehicleSizeX = math.max(maxX - minX, 1)
        self.vehicleSizeZ = math.max(_ - i, 1)
        self.focusY = self.vehicleSizeY * 0.4
    end
    if self.previewVehicleSize == 0 then
        self.previewVehicleSize = ShopConfigScreen.DEFAULT_PREVIEW_SIZE
    end
    local maxX = self.previewVehicleSize * ShopConfigScreen.CAMERA_MAX_DISTANCE_FACTOR
    local i = ShopConfigScreen.MAX_CAMERA_DISTANCE
    self.cameraMaxDistance = math.min(maxX, i)
    local maxX = self.previewVehicleSize * ShopConfigScreen.CAMERA_MIN_DISTANCE_FACTOR + ShopConfigScreen.NEAR_CLIP_DISTANCE
    local i = self.cameraMaxDistance
    self.cameraMinDistance = math.min(maxX, i)
    if self.isLoadingInitial then
        local minX
        if self.vehicleSizeX < self.vehicleSizeY then
            minX = math.max(self.vehicleSizeX, self.vehicleSizeY) * 0.35
        else
            minX = math.max(self.vehicleSizeZ, self.vehicleSizeY) * 0.35
        end
        local i = self.cameraMinDistance + minX
        self.cameraDistance = math.min(i, self.cameraMaxDistance)
        self.zoomTarget = self.cameraDistance
        self:resetCamera()
    end
    if self.storeItem.shopDynamicTitle then
        local minX = self.previewVehicles[1]
        if minX ~= nil then
            local maxX = g_brandManager:getBrandByIndex(minX:getBrand() or self.storeItem.brandIndex)
            self.shopConfigBrandIcon:setImageFilename(self.storeItem.customBrandIcon or maxX.image)
            self.shopConfigItemName:setText(minX:getName() or self.storeItem.name)
        end
    end
    self.isLoadingInitial = false
    self.loadingAnimation:setVisible(false)
end
function ShopConfigScreen:updateDisplay(storeItem, vehicle, saleItem, doNotReload)
    local brandIndex = storeItem.brandIndex
    local vehicleName = storeItem.name
    if storeItem.shopDynamicTitle and vehicle ~= nil then
        brandIndex = vehicle:getBrand()
        vehicleName = vehicle:getName()
    end
    local brand = g_brandManager:getBrandByIndex(brandIndex)
    if self.shopConfigBrandIcon == nil then
        printCallstack()
    end
    self.shopConfigBrandIcon:setImageFilename(storeItem.customBrandIcon or brand.image)
    self.shopConfigItemName:setText(vehicleName)
    self:updateConfigOptionsDisplay(storeItem, vehicle, saleItem)
    self:updateButtons(storeItem, vehicle, saleItem)
    if not doNotReload then
        self:updateData(storeItem, vehicle, saleItem)
    end
end
function ShopConfigScreen:setCurrentMission(currentMission) end
function ShopConfigScreen:loadMapData(mapXMLFile, _, baseDirectory)
    if not GS_IS_MOBILE_VERSION then
        local shopConfigFilename = getXMLString(mapXMLFile, "map.shop#filename") or "$data/store/ui/shop.xml"
        local xmlFile = Utils.getFilename(shopConfigFilename, baseDirectory)
        local xmlFile = XMLFile.load("shopXml", xmlFile)
        self.workshopFilename = Utils.getFilename(xmlFile:getString("shop.filename") or ShopConfigScreen.WORKSHOP_PATH, baseDirectory)
        local x = xmlFile:getFloat("shop.position#xMapPos") or 0
        local y = xmlFile:getFloat("shop.position#yMapPos") or 0
        local z = xmlFile:getFloat("shop.position#zMapPos") or 0
        if Utils.getNoNil(xmlFile:getBool("shop.lighting#isStatic"), false) then
            self.shopLighting = LightingStatic.new()
        else
            self.shopLighting = Lighting.new()
        end
        self.shopLighting:load(xmlFile, "shop.lighting", g_currentMission.baseDirectory)
        xmlFile:delete()
        self:createWorkshop(self.workshopFilename, x, y, z)
        if self.licensePlateRender ~= nil then
            self.licensePlateRender:createScene()
        end
    end
end
function ShopConfigScreen:unloadMapData()
    if self.workshopNode ~= nil then
        delete(self.workshopNode)
    end
    if self.workshopRootNode ~= nil then
        delete(self.workshopRootNode)
    end
    if self.shopLighting ~= nil then
        self.shopLighting:delete()
    end
    if self.creationBox ~= nil then
        delete(self.creationBox)
        self.creationBox = nil
    end
    if self.loadRequestIdWorkshop ~= nil then
        g_i3DManager:cancelStreamI3DFile(self.loadRequestIdWorkshop)
        self.loadRequestIdWorkshop = nil
    end
    if self.licensePlateRender ~= nil then
        self.licensePlateRender:destroyScene()
        self.licensePlateRender = nil
    end
    self.shopLighting = nil
    self.workshopNode = nil
    self.workshopRootNode = nil
end
function ShopConfigScreen:setWorkshopWorldPosition(posX, posY, posZ)
    self.workshopWorldPosition = { posX, posY, posZ }
end
function ShopConfigScreen:setCallbacks(callbackFunc, target)
    self.callbackFunc = callbackFunc
    self.target = target
end
function ShopConfigScreen:deletePreviewVehicles()
    for _, vehicle in pairs(self.previewVehicles) do
        vehicle:delete()
    end
    self.previewVehicles = {}
end
function ShopConfigScreen:setStoreItem(storeItem, vehicle, saleItem, configBasePrice, configurations)
    self:deletePreviewVehicles()
    self.storeItem = storeItem
    self.vehicle = vehicle
    self.saleItem = saleItem
    self.configBasePrice = Utils.getNoNil(configBasePrice, 0)
    if configurations == nil then
        if storeItem.defaultConfigurationIds ~= nil then
            for configName, index in pairs(storeItem.defaultConfigurationIds) do
                ({})[configName] = index
            end
        end
        if vehicle ~= nil and vehicle.configurations ~= nil then
            for configName, index in pairs(vehicle.configurations) do
                configurations[configName] = index
            end
        end
        if saleItem ~= nil and saleItem.boughtConfigurations ~= nil then
            for configName, index in pairs(saleItem.boughtConfigurations) do
                for index, value in pairs(index) do
                    if value then
                        configurations[configName] = index
                    end
                end
            end
        end
    end
    self.configurations = configurations
    if vehicle == nil then
        self.configurationData = {}
        self.boughtConfigurations = {}
    else
        self.configurationData = table.clone(vehicle.configurationData, math.huge)
        self.boughtConfigurations = table.clone(vehicle.boughtConfigurations, math.huge)
    end
    self.subConfigurations = {}
    self.currentConfigSet = 1
    self.isLoadingInitial = true
    if g_licensePlateManager:getAreLicensePlatesAvailable() then
        if vehicle == nil then
            self.licensePlateData = g_currentMission:getLastCreatedLicensePlate() or g_licensePlateManager:getRandomLicensePlateData()
        elseif vehicle.getLicensePlatesData ~= nil then
            local data = vehicle:getLicensePlatesData()
            if data == nil or data.characters == nil then
                self.licensePlateData = g_currentMission:getLastCreatedLicensePlate() or g_licensePlateManager:getRandomLicensePlateData()
            else
                self.licensePlateData = {}
                self.licensePlateData.variation = data.variation
                self.licensePlateData.colorIndex = data.colorIndex
                self.licensePlateData.placementIndex = data.placementIndex
                self.licensePlateData.characters = table.clone(data.characters)
                local defaultPlacementIndex, hasFrontPlate = vehicle:getLicensePlateDialogSettings()
                self.licensePlateData.defaultPlacementIndex = defaultPlacementIndex
                self.licensePlateData.hasFrontPlate = hasFrontPlate
            end
        end
    end
    self:processStoreItemConfigurations(storeItem, vehicle, saleItem)
    self:updateDisplay(storeItem, vehicle, saleItem)
    self:resetCamera()
end
function ShopConfigScreen:setRequestExitCallback(callback)
    -- upvalues: (copy) NO_CALLBACK
    self.requestExitCallback = callback or NO_CALLBACK
end
function ShopConfigScreen:setConfigPrice(configName, configIndex, priceTextElement, vehicle)
    local price = self.storeItem.configurations[configName][configIndex].price
    local price
    if vehicle == nil then
        price = self.saleItem ~= nil and ConfigurationUtil.hasBoughtConfiguration(self.saleItem, configName, configIndex) and 0 or price
    else
        price = ConfigurationUtil.hasBoughtConfiguration(vehicle, configName, configIndex) and 0 or price
    end
    priceTextElement:setText("+" .. g_i18n:formatMoney(price) .. "")
    priceTextElement:setVisible(true)
end
function ShopConfigScreen:onPickColor(colorIndex, args, customColor, noUpdate)
    if customColor ~= nil then
        local isValid = true
        for index, configItem in pairs(self.storeItem.configurations[args.configName]) do
            if configItem.isCustomColor then
                isValid = true
                colorIndex = index
                break
            end
        end
        if isValid then
            if self.configurationData[configName] == nil then
                self.configurationData[configName] = {}
            end
            self.configurationData[configName][colorIndex] = {}
            self.configurationData[configName][colorIndex].color = { customColor.customColor[1], customColor.customColor[2], customColor.customColor[3] }
            self.configurationData[configName][colorIndex].materialTemplateName = customColor.templateName
        end
    end
    if colorIndex ~= nil then
        self.configurations[configName] = colorIndex
        local isValid = self.storeItem.configurations[configName][colorIndex]
        local configItems = isValid.uiColor or isValid.color
        local materialTemplateName = isValid.materialTemplateName
        if self.configurationData[configName] ~= nil then
            local data = self.configurationData[configName][colorIndex]
            if data ~= nil then
            end
        end
        local data, isMat = g_vehicleMaterialManager:getMaterialTemplateFinish(materialTemplateName)
        local index = data or isValid.isMetallic
        local index = isMat or isValid.isMat
        self.colorElements[args.colorOptionIndex]:getDescendantByName("colorImageGlossy"):setVisible(not (index or index))
        element:getDescendantByName("colorImageMetallic"):setVisible(index)
        element:getDescendantByName("colorImageMatte"):setVisible(index)
        if MathUtil.getBrightnessFromColor(unpack(configItems)) >= ColorPickButtonElement.BRIGHTNESS_THRESHOLD then
            element:getDescendantByName("colorImageGlossy"):setImageColor(nil, 0, 0, 0)
            element:getDescendantByName("colorImageMetallic"):setImageColor(nil, 0, 0, 0)
            element:getDescendantByName("colorImageMatte"):setImageColor(nil, 0, 0, 0)
        else
            element:getDescendantByName("colorImageGlossy"):setImageColor(nil, 1, 1, 1)
            element:getDescendantByName("colorImageMetallic"):setImageColor(nil, 1, 1, 1)
            element:getDescendantByName("colorImageMatte"):setImageColor(nil, 1, 1, 1)
        end
        local index, configItem, b = unpack(configItems)
        element:getDescendantByName("colorImage"):setImageColor(nil, math.clamp(index, 0, 1), math.clamp(configItem, 0, 1), (math.clamp(b, 0, 1)))
        self:setConfigPrice(configName, colorIndex, element.parent:getDescendantByName("price"), self.vehicle)
        if not noUpdate then
            self:updateData(self.storeItem, self.vehicle, self.saleItem)
            self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_SPRAY)
        end
    end
end
function ShopConfigScreen:selectFirstConfig()
    local firstElement = self.configurationLayout.elements[1]
    if firstElement == nil then
        FocusManager:unsetFocus(FocusManager:getFocusedElement())
        FocusManager.currentFocusData.focusElement = nil
    else
        local focusElement = firstElement:getDescendantByName("option")
        if focusElement == nil or not focusElement:getIsVisible() then
            focusElement = firstElement:getDescendantByName("color")
        end
        if focusElement == nil or not focusElement:getIsVisible() then
            focusElement = firstElement:getDescendantByName("yesNoOption")
        end
        if focusElement == nil or not focusElement:getIsVisible() then
            focusElement = firstElement:getDescendantByName("button")
        end
        FocusManager:unsetFocus(focusElement)
        FocusManager:setFocus(focusElement)
    end
end
function ShopConfigScreen:processStoreItemConfigurationSet(storeItem, configSet, vehicle, saleItem)
    local options = {}
    local configurationTypes = g_vehicleConfigurationManager:getSortedConfigurationTypes()
    for _, configName in ipairs(configurationTypes) do
        if g_vehicleConfigurationManager:getConfigurationSelectorType(configName) ~= ConfigurationUtil.SELECTOR_COLOR then
            local subConfigItems = storeItem.subConfigurations[configName]
            if subConfigItems == nil or #subConfigItems.subConfigValues <= 1 then
                if storeItem.configurations[configName] ~= nil and (#storeItem.configurations[configName] > 1 and configSet.configurations[configName] == nil) then
                    local option = self:processStoreItemConfigurationOption(storeItem, configName, items, vehicle, nil, saleItem)
                    table.insert(options, option)
                end
            else
                local option = self:processStoreItemSubConfigurationOption(storeItem, configName, vehicle, saleItem)
                table.insert(options, option)
            end
        end
    end
    return options
end
function ShopConfigScreen:processStoreItemSubConfigurationOption(storeItem, configName, vehicle, saleItem)
    local icons = {}
    local subConfigSelection = {
        ["name"] = configName,
        ["title"] = g_vehicleConfigurationManager:getConfigurationDescByName(configName).subConfigurationTitle,
        ["texts"] = {},
        ["subConfigOptions"] = {},
        ["selectedIndex"] = 1,
        ["isSubConfiguration"] = true
    }
    local initialIndex = StoreItemUtil.getSubConfigurationIndex(storeItem, configName, self.configurations[configName] or 1)
    if vehicle ~= nil then
        initialIndex = StoreItemUtil.getSubConfigurationIndex(storeItem, configName, vehicle.configurations[configName])
    end
    subConfigSelection.selectedIndex = initialIndex
    self.subConfigurations[configName] = initialIndex
    for i, name in pairs(storeItem.subConfigurations[configName].subConfigValues) do
        if type(name) == "table" then
            table.insert(subConfigSelection.texts, name.title)
            table.insert(icons, name.icon)
        else
            table.insert(subConfigSelection.texts, name)
        end
        local subConfigOption = self:processStoreItemConfigurationOption(storeItem, configName, StoreItemUtil.getSubConfigurationItems(storeItem, configName, i), vehicle, true, saleItem)
        table.insert(subConfigSelection.subConfigOptions, subConfigOption)
    end
    if #icons > 0 then
        subConfigSelection.icons = icons
    end
    return subConfigSelection
end
function ShopConfigScreen.processStoreItemConfigurationOption(_, storeItem, configName, configItems, vehicle, isSubConfigOption)
    local configOption = {
        ["name"] = configName,
        ["title"] = g_vehicleConfigurationManager:getConfigurationAttribute(configName, "title"),
        ["texts"] = {},
        ["icons"] = {},
        ["options"] = {},
        ["defaultIndex"] = 1
    }
    local initialIndex = 1
    local overwrittenTitle = nil
    local hasValidIcons = false
    local index = 1
    for _, item in ipairs(configItems) do
        if item.isDefault then
            configOption.defaultIndex = index
            initialIndex = index
        end
        local isSelectable = item.isSelectable
        if storeItem.bundleInfo ~= nil then
            for _, bundleItem in ipairs(storeItem.bundleInfo.bundleItems) do
                if bundleItem.preSelectedConfigurations ~= nil and bundleItem.preSelectedConfigurations[configName] ~= nil then
                    local preSelectedOption = bundleItem.preSelectedConfigurations[configName]
                    if item.index == preSelectedOption.configValue then
                        isSelectable = true
                        configOption.defaultIndex = index
                        initialIndex = index
                    end
                    if not preSelectedOption.allowChange then
                        configOption.isDisabled = true
                    end
                    if preSelectedOption.hideOption then
                        return
                    end
                end
            end
        end
        for _, bundleItem in pairs(storeItem.configurations) do
            for _, configItem in pairs(bundleItem) do
                if configItem.dependentConfigurations ~= nil then
                    for _, dependentConfiguration in pairs(configItem.dependentConfigurations) do
                        if dependentConfiguration.name == configName then
                            return
                        end
                    end
                end
            end
        end
        if isSelectable then
            table.insert(configOption.texts, item.name)
            table.insert(configOption.options, item)
            if item.brandIndex ~= nil then
                local iconFilename = g_brandManager:getBrandIconByIndex(item.brandIndex)
                if iconFilename ~= nil then
                    table.insert(configOption.icons, iconFilename)
                    hasValidIcons = true
                end
            end
            if #configOption.icons ~= #configOption.texts then
                table.insert(configOption.icons, item.name)
            end
        end
    end
    if vehicle ~= nil then
        for item, isSelectable in ipairs(configItems) do
            if isSelectable.index == vehicle.configurations[configName] then
                initialIndex = item
                break
            end
        end
    end
    configOption.defaultIndex = initialIndex
    configOption.title = overwrittenTitle or configOption.title
    if not hasValidIcons then
        configOption.icons = nil
    end
    if #configOption.options > 1 or isSubConfigOption then
        return configOption
    end
end
function ShopConfigScreen:processStoreItemColorOption(_, configName, colorItems, _, _, _)
    local overwrittenTitle = nil
    for _, item in ipairs(colorItems) do

    end
    table.insert(self.colorPickers, {
        ["title"] = overwrittenTitle or g_vehicleConfigurationManager:getConfigurationAttribute(configName, "title"),
        ["configName"] = configName,
        ["colorItems"] = colorItems
    })
end
function ShopConfigScreen:processStoreItemConfigurations(storeItem, vehicle, saleItem)
    self.configSelection = {
        ["title"] = g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.CONFIGURATION_LABEL),
        ["texts"] = {},
        ["prices"] = {},
        ["options"] = {}
    }
    self.currentConfigSet = 1
    local configSets = storeItem.configurationSets
    local configSets = #configSets == 0 and {
        {
            ["name"] = "",
            ["configurations"] = {},
            ["isDefault"] = true
        }
    } or configSets
    if storeItem.configurations == nil then
        table.insert(self.configSelection.options, {})
        self.displayableColorCount = 0
    else
        for i, configSet in ipairs(configSets) do
            if configSet.isDefault then
                self.currentConfigSet = i
            end
            if configSet.overwrittenTitle ~= nil then
                self.configSelection.title = configSet.overwrittenTitle
            end
            local price = 0
            for name, index in pairs(configSet.configurations) do
                local alreadyInOwnedVehicle = false
                if self.vehicle ~= nil then
                    alreadyInOwnedVehicle = ConfigurationUtil.hasBoughtConfiguration(self.vehicle, name, index)
                end
                local alreadyInSaleVehicle = false
                if self.saleItem ~= nil then
                    alreadyInSaleVehicle = ConfigurationUtil.hasBoughtConfiguration(self.saleItem, name, index)
                end
                if not (alreadyInOwnedVehicle or alreadyInSaleVehicle) then
                end
            end
            table.insert(self.configSelection.prices, price)
            table.insert(self.configSelection.texts, configSet.name)
            local setOptions = self:processStoreItemConfigurationSet(storeItem, configSet, vehicle, saleItem)
            table.insert(self.configSelection.options, setOptions)
        end
        if #configSets > 0 then
            if saleItem ~= nil then
                self.currentConfigSet = saleItem.configSetIndex or self.currentConfigSet
            end
            if vehicle ~= nil then
                local defaultSet, _ = ConfigurationUtil.getClosestConfigurationSet(vehicle.configurations, configSets)
                if defaultSet ~= nil then
                    self.currentConfigSet = defaultSet.index
                end
            end
        end
        for i, configSet in pairs(configSets[self.currentConfigSet].configurations) do
            self.configurations[i] = configSet
        end
        self.colorPickers = {}
        local defaultSet = 1
        local _ = g_vehicleConfigurationManager:getSortedConfigurationTypes()
        local configSet = 1
        local i = 1
        for configSet = configSet, #_, i do
            local price = _[configSet]
            if storeItem.configurations[price] ~= nil then
                local isColor = g_vehicleConfigurationManager:getConfigurationSelectorType(price) == ConfigurationUtil.SELECTOR_COLOR
                if #storeItem.configurations[price] > 1 and isColor then
                    self:processStoreItemColorOption(storeItem, price, setOptions, defaultSet, vehicle, saleItem)
                    defaultSet = defaultSet + 1
                end
            end
        end
        self.displayableColorCount = defaultSet - 1
    end
    if storeItem.bundleInfo ~= nil then
        for i, configSet in ipairs(storeItem.bundleInfo.bundleItems) do
            if configSet.preSelectedConfigurations ~= nil then
                for configName, name in pairs(configSet.preSelectedConfigurations) do
                    self.configurations[configName] = name.configValue
                end
            end
        end
    end
end
function ShopConfigScreen:getOrCreateConfigItem(type)
    local option
    if #self.configItemCache == 0 then
        option = self.configurationItemTemplate:clone(self.configurationLayout)
    else
        self.configItemCache[#self.configItemCache] = nil
        self.configurationLayout:addElement(self.configItemCache[#self.configItemCache])
    end
    option.isLargeConfigItem = false
    option:setVisible(true)
    option.focusId = nil
    local option = false
    local color = false
    local yesNoOption = false
    local focusableElement = nil
    if type == "option" then
        focusableElement = (true):getDescendantByName("option")
    elseif type == "color" then
        color = true
        focusableElement = option:getDescendantByName("color")
    elseif type == "yesNoOption" then
        yesNoOption = true
        focusableElement = option:getDescendantByName("yesNoOption")
    end
    option:getDescendantByName("option"):setVisible(option)
    option:getDescendantByName("color"):setVisible(color)
    option:getDescendantByName("yesNoOption"):setVisible(yesNoOption)
    option:getDescendantByName("price"):setVisible(true)
    if focusableElement ~= nil then
        focusableElement.forceFocusScrollToTop = self.focusableElementForScroll ~= nil
        self.focusableElementForScroll = focusableElement
        option:getDescendantByName("title").getIsSelected = function()
            -- upvalues: (ref) focusableElement
            return focusableElement:getIsFocused()
        end
    end
    return option
end
function ShopConfigScreen:getOrCreateLargeConfigItem(_)
    local focusableElement
    if #self.configItemCacheLarge == 0 then
        focusableElement = self.configurationItemTemplateLarge:clone(self.configurationLayout)
    else
        self.configItemCacheLarge[#self.configItemCacheLarge] = nil
        self.configurationLayout:addElement(self.configItemCacheLarge[#self.configItemCacheLarge])
    end
    focusableElement.isLargeConfigItem = true
    focusableElement:setVisible(true)
    focusableElement.focusId = nil
    local focusableElement = focusableElement:getDescendantByName("option")
    focusableElement.forceFocusScrollToTop = self.focusableElementForScroll ~= nil
    self.focusableElementForScroll = focusableElement
    focusableElement:getDescendantByName("title").getIsSelected = function()
        -- upvalues: (copy) focusableElement
        return focusableElement:getIsFocused()
    end
    return focusableElement
end
function ShopConfigScreen:getDefaultConfigIndexByName(configName) end
function ShopConfigScreen:updateConfigSetOptionElement(_, storeItem, vehicle, saleItem)
    local isYesNoOption = false
    if #storeItem.configurationSets > 1 then
        isYesNoOption = storeItem.configurationSets[1].isYesNoOption
    end
    local price = isYesNoOption and "yesNoOption" or "option"
    local listElement = self:getOrCreateConfigItem(price)
    local price
    if isYesNoOption then
        price = listElement:getDescendantByName("yesNoOption")
        price:setIsChecked(self.currentConfigSet ~= 1, true)
        price:setTexts(self.configSelection.texts)
    else
        price = listElement:getDescendantByName("option")
        price:setTexts(self.configSelection.texts)
        price:setState(self.currentConfigSet)
    end
    price:setDisabled(false)
    function price.onClickCallback(_, configSetIndex)
        -- upvalues: (copy) storeItem, (copy) self, (copy) vehicle, (copy) saleItem
        for name, _ in pairs(storeItem.configurationSets[self.currentConfigSet].configurations) do
            self.configurations[name] = ConfigurationUtil.getDefaultConfigIdFromItems(storeItem.configurations[name])
        end
        for name, _ in pairs(storeItem.configurationSets[configSetIndex].configurations) do
            self.configurations[name] = _
        end
        self.currentConfigSet = configSetIndex
        self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
        self:updateDisplay(storeItem, vehicle, saleItem)
        self:selectFirstConfig()
    end
    listElement:getDescendantByName("title"):setText(self.configSelection.title)
    local price = self.configSelection.prices[self.currentConfigSet]
    listElement:getDescendantByName("price"):setText("+" .. g_i18n:formatMoney(price))
end
function ShopConfigScreen:updateConfigOptionElement(_, option, storeItem, vehicle, _)
    local hasIcons = option.icons ~= nil
    local hasText = not hasIcons
    local isYesNoOption = false
    if #option.options > 1 then
        if option.options[1].isYesNoOption then
            hasIcons = false
            hasText = false
        end
    end
    local listElement = nil
    if hasIcons then
        listElement = self:getOrCreateLargeConfigItem("option")
    elseif hasText then
        listElement = self:getOrCreateConfigItem("option")
    elseif isYesNoOption then
        listElement = self:getOrCreateConfigItem("yesNoOption")
    end
    local configName = isYesNoOption and "yesNoOption" or "option"
    local optionElement = listElement:getDescendantByName(configName)
    optionElement:setVisible(true)
    local configIndex = true
    if #option.options > 1 then
        configIndex = option.isDisabled
    end
    optionElement:setDisabled(configIndex)
    if hasIcons then
        optionElement:setIcons(option.icons)
    elseif hasText then
        optionElement:setTexts(option.texts)
    elseif isYesNoOption then
        optionElement:setTexts(option.texts)
    end
    local priceElement = listElement:getDescendantByName("price")
    local configName = option.name
    local configIndex = 0
    for i, item in pairs(option.options) do
        if item.index == self.configurations[configName] then
            configIndex = i
            break
        end
    end
    if configIndex == 0 or option.options[configIndex] == nil then
        configIndex = option.defaultIndex
    end
    if isYesNoOption then
        optionElement:setIsChecked(configIndex ~= 1, true)
    else
        optionElement:setState(configIndex)
    end
    function optionElement.onClickCallback(_, optionIndex)
        -- upvalues: (copy) option, (copy) self, (copy) configName, (copy) priceElement, (copy) vehicle, (copy) storeItem
        local selectedConfigIndex = option.options[optionIndex].index
        self:setConfigPrice(configName, selectedConfigIndex, priceElement, vehicle)
        self.configurations[configName] = selectedConfigIndex
        self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
        self:updateData(storeItem, self.vehicle, self.saleItem)
    end
    local index
    if option.options[configIndex] == nil then
        index = option.defaultIndex
    else
        index = option.options[configIndex].index
    end
    self.configurations[configName] = index
    self.configurationToListElement[configName] = listElement
    listElement:getDescendantByName("title"):setText(option.title)
    self:setConfigPrice(configName, index, priceElement, vehicle)
end
function ShopConfigScreen:updateSubConfigOptionElement(_, option, storeItem, vehicle, saleItem)
    local hasIcons = option.icons ~= nil
    local optionElement
    if hasIcons then
        optionElement = self:getOrCreateLargeConfigItem("option")
    else
        optionElement = self:getOrCreateConfigItem("option")
    end
    local optionElement = optionElement:getDescendantByName("option")
    optionElement:setVisible(true)
    optionElement:setDisabled(false)
    if hasIcons then
        optionElement:setIcons(option.icons)
    else
        optionElement:setTexts(option.texts)
    end
    local configName = option.name
    local subConfigIndex = self.subConfigurations[configName] or option.defaultIndex
    self.subConfigurations[configName] = subConfigIndex
    option.selectedIndex = subConfigIndex
    optionElement:setState(subConfigIndex)
    function optionElement.onClickCallback(_, state)
        -- upvalues: (copy) self, (copy) configName, (copy) option, (copy) storeItem, (copy) vehicle, (copy) saleItem, (copy) optionElement
        self.subConfigurations[configName] = state
        option.selectedIndex = state
        self.configurations[configName] = option.subConfigOptions[state].defaultIndex
        self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
        self:updateConfigOptionsDisplay(storeItem, vehicle, saleItem)
        self:updateData(storeItem, self.vehicle, saleItem)
        FocusManager:unsetFocus(optionElement)
        FocusManager:setFocus(optionElement)
    end
    optionElement:getDescendantByName("price"):setVisible(false)
    optionElement:getDescendantByName("title"):setText(option.title)
end
function ShopConfigScreen:updateConfigOptionsData(storeItem, vehicle, saleItem)
    if self.licensePlate ~= nil then
        self.licensePlate:delete()
        self.licensePlate = nil
    end
    self.configurationToListElement = {}
    local displayableOptionCount = 0
    local count = 0
    local i = #self.configurationLayout.elements
    for i = i, 1, -1 do
        local item = self.configurationLayout.elements[i]
        item:setVisible(false)
        FocusManager:removeElement(item)
        item:unlinkElement()
        if item ~= self.configurationItemPlate then
            if item.isLargeConfigItem then
                table.insert(self.configItemCacheLarge, item)
            else
                table.insert(self.configItemCache, item)
            end
        end
    end
    self.focusableElementForScroll = nil
    if #self.configSelection.options > 1 then
        count = 1
        self:updateConfigSetOptionElement(1, storeItem, vehicle, saleItem)
    end
    for _, option in ipairs(self.configSelection.options[self.currentConfigSet]) do
        displayableOptionCount = displayableOptionCount + 1
        count = count + 1
        if option.isSubConfiguration then
            self:updateSubConfigOptionElement(count, option, storeItem, vehicle, saleItem)
        else
            self:updateConfigOptionElement(count, option, storeItem, vehicle, saleItem)
        end
        if option.isSubConfiguration then
            count = count + 1
            self:updateConfigOptionElement(count, option.subConfigOptions[option.selectedIndex], storeItem, vehicle, saleItem)
        end
    end
    local i = storeItem.configurationSets[self.currentConfigSet]
    self.colorElements = {}
    if self.displayableColorCount > 0 then
        for subOption, option in ipairs(self.colorPickers) do
            local visibility = true
            if i ~= nil and i.configurations[option.configName] ~= nil then
                visibility = false
            end
            if storeItem.bundleInfo ~= nil then
                for _, bundleItem in ipairs(storeItem.bundleInfo.bundleItems) do
                    if bundleItem.preSelectedConfigurations ~= nil and (bundleItem.preSelectedConfigurations[option.configName] ~= nil and bundleItem.preSelectedConfigurations[option.configName].hideOption) then
                        visibility = false
                    end
                end
            end
            local itemsToDisplay = 0
            local hasCustomColorSupport = false
            local bundleItem = 1
            local listElement = #option.colorItems
            for bundleItem = bundleItem, listElement do
                if option.colorItems[bundleItem].isSelectable ~= false then
                end
                if option.colorItems[bundleItem].isCustomColor then
                    hasCustomColorSupport = true
                end
            end
            if visibility then
                visibility = itemsToDisplay > 1
            end
            if visibility then
                local listElement = self:getOrCreateConfigItem("color")
                local _ = listElement:getDescendantByName("color")
                self.colorElements[subOption] = _
                local bundleItem = option.colorItems
                local option, subOption
                function _.onClickCallback(sourceElement)
                    -- upvalues: (copy) self, (copy) option, (copy) subOption, (copy) bundleItem, (ref) hasCustomColorSupport
                    local configIndex = self.configurations[option.configName]
                    local customColor = nil
                    local customMaterialTemplateName = nil
                    local data = self.configurationData[option.configName]
                    if data ~= nil and data[configIndex] ~= nil then
                        customMaterialTemplateName = data[configIndex].materialTemplateName
                        configIndex = nil
                    end
                    g_inputBinding:setShowMouseCursor(true)
                    ColorPickerDialog.show(self.onPickColor, self, {
                        ["configName"] = option.configName,
                        ["colorOptionIndex"] = subOption
                    }, bundleItem, configIndex, customMaterialTemplateName, customColor, hasCustomColorSupport, true)
                end
                self:onPickColor(self.configurations[option.configName] or self:getDefaultConfigurationColorIndex(option.configName, bundleItem, vehicle), {
                    ["configName"] = option.configName,
                    ["colorOptionIndex"] = subOption
                }, nil, true)
                listElement:getDescendantByName("title"):setText(option.title)
            end
        end
    end
    if storeItem.hasLicensePlates and g_licensePlateManager:getAreLicensePlatesAvailable() then
        self.configurationLayout:addElement(self.configurationItemPlate)
        self.configurationItemPlate:setVisible(true)
        self.configurationItemPlate:reloadFocusHandling(true)
        self:updateLicensePlate()
        local item = self.configurationItemPlate:getDescendantByName("button")
        if item ~= nil then
            item.forceFocusScrollToTop = self.focusableElementForScroll ~= nil
            self.focusableElementForScroll = item
            self.configurationItemPlate:getDescendantByName("title").getIsSelected = function()
                -- upvalues: (copy) item
                return item:getIsFocused()
            end
        end
    end
    self.displayableOptionCount = displayableOptionCount
    return count
end
function ShopConfigScreen:updateConfigOptionsDisplay(storeItem, vehicle, saleItem)
    FocusManager:setGui("ShopConfigScreen")
    local num = self:updateConfigOptionsData(storeItem, vehicle, saleItem)
    self.configurationsTitle:setVisible(num > 0)
    self.startClipper:setVisible(num > 0)
    self.endClipper:setVisible(num > 0)
    self.configSlider.parent:setVisible(num > 0)
    self.configurationLayout:invalidateLayout()
    FocusManager:setGui(FocusManager.currentGui)
    if self.needsRefocus then
        self:selectFirstConfig()
        self.needsRefocus = false
    end
end
function ShopConfigScreen:update(dt)
    ShopConfigScreen:superClass().update(self, dt)
    if self.vehicle == nil or not self.vehicle.isDeleted then
        if not self.fadeInAnimation:getFinished() then
            self.fadeInAnimation:update(dt)
        end
        if not self.fadeOutAnimation:getFinished() then
            self.fadeOutAnimation:update()
        end
        if self.lastMoney ~= g_currentMission:getMoney() then
            self:updateBalanceText()
        end
        if self.loadingDelayTime > 0 or self.loadingDelayFrames > 0 then
            self.loadingDelayFrames = math.max(self.loadingDelayFrames - 1, 0)
            self.loadingDelayTime = math.max(self.loadingDelayTime - dt, 0)
            if self.loadingDelayTime <= 0 and self.loadingDelayFrames <= 0 then
                self:onFinishedLoading()
            end
        end
        for _, vehicle in pairs(self.previewVehicles) do
            vehicle:update(dt)
            vehicle:updateTick(dt)
        end
        g_shopController:update(dt)
        self:updateInput(dt)
        self:updateCamera(dt)
        if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
            for _, vehicle in pairs(self.previewVehicles) do
                local component = vehicle.components[1]
                if component ~= nil then
                    local x, y, z = getWorldTranslation(component.node)
                    local rx, ry, rz = getWorldRotation(component.node)
                    renderText(0.35, 0.05 + (_ - 1) * 0.02, 0.015, string.format("Vehicle Position: Translation: %.3f %.3f %.3f Rotation: %.3f %.3f %.3f (%s)", x, y + 100, z, math.deg(rx), math.deg(ry), math.deg(rz), vehicle:getName()))
                end
            end
        elseif VehicleDebug.state == VehicleDebug.DEBUG_AI then
            for _, vehicle in pairs(self.previewVehicles) do
                if vehicle.updateAIMarkerWidth ~= nil then
                    vehicle:updateAIMarkerWidth()
                    local component, x, y, z, rx = vehicle:getAIMarkers()
                    local ry = AIVehicleUtil.getAttachedImplementsAllowTurnBackward(vehicle)
                    local rz = vehicle:getAIToolReverserDirectionNode() ~= nil
                    setTextBold(true)
                    renderText(0.35, 0.11, 0.015, "Field Course:")
                    if rx > 0 then
                        renderText(0.35, 0.09, 0.015, string.format("Width: %.1f", rx))
                        if ry then
                            setTextColor(0, 1, 0, 1)
                        elseif rz then
                            setTextColor(1, 1, 1, 1)
                        else
                            setTextColor(1, 0, 0, 1)
                        end
                        renderText(0.35, 0.07, 0.015, string.format("Turn Backward: %s", ry and "Yes" or "No"))
                        if rz then
                            setTextColor(0, 1, 0, 1)
                        elseif ry then
                            setTextColor(1, 1, 1, 1)
                        else
                            setTextColor(1, 0, 0, 1)
                        end
                        renderText(0.35, 0.05, 0.015, string.format("Straight Reversing: %s", rz and "Yes" or "No"))
                    else
                        renderText(0.35, 0.09, 0.015, "Not supported")
                    end
                    setTextColor(1, 1, 1, 1)
                    setTextBold(false)
                end
            end
        end
    else
        self:onClickBack()
        self.vehicle = nil
        return
    end
end
function ShopConfigScreen:updateCamera(_)
    setTranslation(self.rotateNode, self.workshopWorldPosition[1], self.workshopWorldPosition[2] + self.focusY, self.workshopWorldPosition[3])
    setRotation(self.rotateNode, self.rotX, self.rotY, 0)
    local camPosX, camPosY, camPosZ = getWorldTranslation(self.cameraPositionNode)
    local targetPosX, targetPosY, targetPosZ = getWorldTranslation(self.rotateNode)
    local dx, dy, dz = MathUtil.vector3Normalize(targetPosX - camPosX, targetPosY - camPosY, targetPosZ - camPosZ)
    local lx, ly, lz = worldToLocal(self.rotateNode, targetPosX - dx * self.cameraDistance, targetPosY - dy * self.cameraDistance, targetPosZ - dz * self.cameraDistance)
    setTranslation(self.cameraPositionNode, lx, ly, lz)
    local projectionOffsetX = not self.shopConfigContent.parent:getIsVisible() and 0 or -0.15625
    local direction = 1
    local ratio = self.vehicleSizeX / self.vehicleSizeZ
    if self.vehicleSizeX > self.vehicleSizeZ then
        direction = -1
        ratio = self.vehicleSizeZ / self.vehicleSizeX
    end
    local ratio = 1 - math.clamp(ratio, 0, 1)
    local cameraAlpha = self.rotY % 6.283185307179586 / 6.283185307179586
    local offsetFactor = 0
    if cameraAlpha >= 0 and cameraAlpha < 0.25 then
        offsetFactor = cameraAlpha / 0.125
        if offsetFactor > 1 then
        end
    elseif cameraAlpha >= 0.25 and cameraAlpha < 0.5 then
        local offsetFactor = (cameraAlpha - 0.25) / 0.125
        if offsetFactor > 1 then
        end
        offsetFactor = -offsetFactor
    elseif cameraAlpha >= 0.5 and cameraAlpha < 0.75 then
        offsetFactor = (cameraAlpha - 0.5) / 0.125
        if offsetFactor > 1 then
        end
    elseif cameraAlpha >= 0.75 and cameraAlpha < 1 then
        local offsetFactor = (cameraAlpha - 0.75) / 0.125
        if offsetFactor > 1 then
        end
        offsetFactor = -offsetFactor
    end
    setProjectionOffset(self.cameraNode, projectionOffsetX - offsetFactor * 0.1 * direction * ratio, 0.07)
end
function ShopConfigScreen:draw()
    ShopConfigScreen:superClass().draw(self)
    if self.fadeOverlay.visible then
        self.fadeOverlay:render()
    end
end
function ShopConfigScreen:onRenderLoad(scene, _)
    setName(scene, "ShopConfigScreen_" .. getName(scene))
    self.licensePlaceLinkNode = I3DUtil.indexToObject(scene, "0|0")
end
function ShopConfigScreen:updateLicensePlate()
    if self.licensePlateRender ~= nil and self.licensePlaceLinkNode ~= nil then
        local licensePlate = g_licensePlateManager:getLicensePlate(LicensePlateManager.PLATE_TYPE.ELONGATED)
        if licensePlate ~= nil then
            link(self.licensePlaceLinkNode, licensePlate.node)
            setTranslation(licensePlate.node, 0, 0, 0)
            setRotation(licensePlate.node, 0, 0, 0)
            if self.licensePlate ~= nil then
                self.licensePlate:delete()
            end
            self.licensePlate = licensePlate
            self:updateLicensePlateGraphics()
            local cameraNode = I3DUtil.indexToObject(self.licensePlateRender.scene, self.licensePlateRender.cameraPath)
            if cameraNode ~= nil then
                local fovY = getFovY(cameraNode)
                local distance = (self.licensePlate.width / 2 + 0.005) / math.tan(fovY / 2) / (self.licensePlateRender.absSize[1] * (licensePlate.width / licensePlate.height / 5) / self.licensePlateRender.absSize[2] * g_screenAspectRatio)
                setTranslation(cameraNode, 0, 0, distance)
            end
        end
    end
end
function ShopConfigScreen:updateLicensePlateGraphics()
    local currentCharacters = table.clone(self.licensePlateData.characters, math.huge)
    if self.licensePlate ~= nil then
        self.licensePlate:updateData(self.licensePlateData.variation or 1, LicensePlateManager.PLATE_POSITION.BACK, table.concat(currentCharacters, ""))
        self.licensePlate:setColorIndex(self.licensePlateData.colorIndex or 1)
        self.licensePlateRender:setRenderDirty()
    end
    if #self.previewVehicles == 0 then
        self.licensePlateRender.parent:setText("")
        self.licensePlateRender:setVisible(false)
        return
    elseif self.licensePlateData.placementIndex == LicensePlateManager.PLATE_POSITION.NONE then
        self.licensePlateRender.parent:setText(g_i18n:getText("configuration_valueLicensePlateNone"))
        self.licensePlateRender:setVisible(false)
    else
        self.licensePlateRender.parent:setText("")
        self.licensePlateRender:setVisible(true)
    end
end
function ShopConfigScreen:onOpen(_)
    ShopConfigScreen:superClass().onOpen(self)
    self.openCounter = self.openCounter + 1
    local posX, posY = unpack(self.configurationsBox.absPosition)
    local width, height = unpack(self.configurationsBox.absSize)
    g_depthOfFieldManager:pushArea(posX, posY, width, height)
    self:onMoneyChange()
    g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.onMoneyChange, self)
    g_gameStateManager:setGameState(GameState.MENU_SHOP_CONFIG)
    g_currentMission.environment:setCustomLighting(self.shopLighting)
    g_currentMission.environment:setSunVisibility(false)
    setVisibility(self.workshopRootNode, true)
    self.previousCamera = g_cameraManager:getActiveCamera()
    g_cameraManager:setActiveCamera(self.cameraNode)
    self:updateInputGlyphs()
    self:toggleCustomInputContext(true, ShopConfigScreen.INPUT_CONTEXT_NAME)
    self:registerInputActions()
    self.needsRefocus = true
    if self.shopMoneyBox ~= nil then
        self.shopMoneyBox:invalidateLayout()
        self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
    end
end
function ShopConfigScreen:onClose()
    self.isLoadingInitial = false
    ShopConfigScreen:superClass().onClose(self)
    g_currentMission.environment:setSunVisibility(true)
    g_currentMission.environment:setCustomLighting(nil)
    g_cameraManager:setActiveCamera(self.previousCamera)
    setVisibility(self.workshopRootNode, false)
    self:deletePreviewVehicles()
    if self.licensePlate ~= nil then
        self.licensePlate:delete()
        self.licensePlate = nil
    end
    self.vehicle = nil
    self.loadingDelayFrames = 0
    self.loadingDelayTime = 0
    g_currentMission:resetGameState()
    self.fadeInAnimation:reset()
    g_depthOfFieldManager:popArea()
    g_messageCenter:unsubscribe(MessageType.MONEY_CHANGED, self)
    g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_PREV, true)
    g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_NEXT, true)
    g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_START, true)
    g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_END, true)
    g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_START_GAMEPAD, true)
    g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_END_GAMEPAD, true)
    self:toggleCustomInputContext(false)
end
function ShopConfigScreen:onClickBuy()
    local _, _, hasChanges = self:getConfigurationCostsAndChanges(self.storeItem, self.vehicle, self.saleItem)
    if hasChanges then
        local enoughMoney = true
        if self.totalPrice > 0 then
            enoughMoney = g_currentMission:getMoney() >= self.totalPrice
        end
        local enoughSlots = g_currentMission.slotSystem:hasEnoughSlots(self.storeItem)
        g_inputBinding:setShowMouseCursor(true)
        if enoughMoney then
            if enoughSlots then
                self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
                local text = string.format(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.CONFIRM_BUY), g_i18n:formatMoney(self.totalPrice, 0, true, true))
                YesNoDialog.show(self.onYesNoBuy, self, text, nil, nil, nil, nil, nil, nil, nil, true)
            else
                self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
                InfoDialog.show(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.TOO_FEW_SLOTS), nil, nil, DialogElement.TYPE_WARNING, nil, nil, nil, true)
            end
        else
            self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
            InfoDialog.show(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.NOT_ENOUGH_MONEY_BUY), nil, nil, DialogElement.TYPE_WARNING, nil, nil, nil, true)
            return
        end
    else
        return
    end
end
function ShopConfigScreen:onClickConfigAction()
    if self.focusedColorElement == nil then
        if self.focusedButtonElement ~= nil then
            self.focusedButtonElement:onFocusActivate()
        end
    else
        self.focusedColorElement:onFocusActivate()
    end
end
function ShopConfigScreen:onClickLicensePlate()
    LicensePlateDialog.show(self.licensePlateData, self.onChangeLicensePlate, self)
end
function ShopConfigScreen:onChangeLicensePlate(licensePlateData)
    if licensePlateData ~= nil then
        self.licensePlateData = licensePlateData
        self.licensePlateData.customized = true
        local i = 1
        for i = i, #self.previewVehicles do
            local vehicle = self.previewVehicles[i]
            if vehicle.setLicensePlatesData ~= nil then
                vehicle:setLicensePlatesData(self.licensePlateData)
            end
        end
        self:updateLicensePlateGraphics()
        self:updateData(self.storeItem, self.vehicle, self.saleItem)
    end
end
function ShopConfigScreen:onFocusConfigurationOption(element)
    self.focusedColorElement = nil
    self.focusedButtonElement = nil
    self.focusedOptionElement = nil
    if element.name == "button" then
        self.focusedButtonElement = element
    elseif element.name == "color" then
        self.focusedColorElement = element
    elseif element.name == "option" then
        self.focusedOptionElement = element
    elseif element.name == "yesNoOption" then
        self.focusedOptionElement = element
    end
    self:updateConfigurationButton()
end
function ShopConfigScreen:onLeaveConfigurationOption(_)
    self.focusedColorElement = nil
    self.focusedButtonElement = nil
    self.focusedOptionElement = nil
    self:updateConfigurationButton()
end
function ShopConfigScreen:updateConfigurationButton()
    local visible = true
    if self.focusedButtonElement == nil then
        visible = self.focusedColorElement ~= nil
    end
    self.configButton:setVisible(visible)
    self.buttonsPanel:invalidateLayout()
end
function ShopConfigScreen:onYesNoBuy(yes)
    if yes then
        self:onCallback(false)
    end
end
function ShopConfigScreen:onVehicleBought()
    if GS_IS_CONSOLE_VERSION then
        self:selectFirstConfig()
    else
        FocusManager:setFocus(self.buyButton)
    end
end
function ShopConfigScreen:onStoreItemsReloaded()
    if self.storeItem ~= nil and g_gui.currentGuiName == "ShopConfigScreen" then
        self.needsRefocus = true
        self.storeItem = g_storeManager:getItemByXMLFilename(self.storeItem.xmlFilename)
        self:setStoreItem(self.storeItem, nil, nil, nil, self.configurations)
    end
end
function ShopConfigScreen:onClickLease()
    if self.vehicle == nil then
        if self.storeItem.allowLeasing then
            local enoughMoney = g_currentMission:getMoney() >= self.initialLeasingCosts
            local enoughSlots = g_currentMission.slotSystem:hasEnoughSlots(self.storeItem)
            g_inputBinding:setShowMouseCursor(true)
            if enoughMoney then
                if enoughSlots then
                    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
                    LeaseYesNoDialog.show(self.onYesNoLease, self, self.totalPrice * EconomyManager.DEFAULT_LEASING_DEPOSIT_FACTOR, self.initialLeasingCosts, self.totalPrice * EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR, self.totalPrice * EconomyManager.PER_DAY_LEASING_FACTOR)
                else
                    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
                    InfoDialog.show(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.TOO_FEW_SLOTS), nil, nil, DialogElement.TYPE_WARNING)
                end
            else
                self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
                InfoDialog.show(g_i18n:getText(ShopConfigScreen.L10N_SYMBOL.NOT_ENOUGH_MONEY_LEASE), nil, nil, DialogElement.TYPE_WARNING)
                return
            end
        else
            return
        end
    else
        return
    end
end
function ShopConfigScreen:onYesNoLease(yes)
    if yes then
        self:onCallback(true)
    end
end
function ShopConfigScreen:onClickShop()
    local eventUnused = ShopConfigScreen:superClass().onClickShop(self)
    if eventUnused then
        self:requestExitCallback()
        eventUnused = false
    end
    return eventUnused
end
function ShopConfigScreen:onCallback(leaseItem)
    local vehicleBuyData = BuyVehicleData.new()
    vehicleBuyData:setStoreItem(self.storeItem)
    vehicleBuyData:setConfigurations(self.configurations, self.boughtConfigurations)
    vehicleBuyData:setConfigurationData(self.configurationData)
    vehicleBuyData:setLeaseVehicle(leaseItem)
    vehicleBuyData:setOwnerFarmId(g_shopController.playerFarmId)
    vehicleBuyData:setLicensePlateData(self.licensePlateData)
    vehicleBuyData:setSaleItem(self.saleItem)
    vehicleBuyData:setPrice(leaseItem and 0 or self.totalPrice)
    local vehicleId = NetworkUtil.getObjectId(self.vehicle)
    if self.callbackFunc ~= nil then
        if self.target == nil then
            self.callbackFunc(vehicleBuyData, vehicleId)
        else
            self.callbackFunc(self.target, vehicleBuyData, vehicleId)
        end
        self.configurations = table.clone(self.configurations)
    end
end
function ShopConfigScreen:updateInputGlyphs()
    self.zoomGlyph:setActions({ InputAction.AXIS_MAP_ZOOM_IN, InputAction.AXIS_MAP_ZOOM_OUT })
    self.lookGlyph:setActions(self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD and { InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE, InputAction.AXIS_LOOK_UPDOWN_VEHICLE } or { InputAction.AXIS_LOOK_LEFTRIGHT_DRAG, InputAction.AXIS_LOOK_UPDOWN_DRAG })
end
function ShopConfigScreen:toggleHUDVisible()
    local isVisible = self.shopConfigContent.parent:getIsVisible()
    if isVisible then
        g_depthOfFieldManager:popArea()
    else
        local posX, posY = unpack(self.configurationsBox.absPosition)
        local width, height = unpack(self.configurationsBox.absSize)
        g_depthOfFieldManager:pushArea(posX, posY, width, height)
    end
    self.shopConfigContent.parent:setVisible(not isVisible)
end
function ShopConfigScreen:registerInputActions()
    g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_PREV, false)
    g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_NEXT, false)
    g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_START, false)
    g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_END, false)
    g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_START_GAMEPAD, false)
    g_inputBinding:setContextEventsActive(ShopConfigScreen.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_END_GAMEPAD, false)
    local isController = g_inputBinding:getLastInputMode() == GS_INPUT_HELP_MODE_GAMEPAD
    _, self.eventIdUpDownController = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_UPDOWN_VEHICLE, self, self.onCameraUpDown, false, false, true, isController)
    _, self.eventIdLeftRightController = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE, self, self.onCameraLeftRight, false, false, true, isController)
    g_inputBinding:registerActionEvent(InputAction.AXIS_MAP_ZOOM_IN, self, self.onCameraZoom, false, false, true, true, -1)
    g_inputBinding:registerActionEvent(InputAction.AXIS_MAP_ZOOM_OUT, self, self.onCameraZoom, false, false, true, true, 1)
    _, self.eventIdUpDownMouse = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_UPDOWN_DRAG, self, self.onCameraUpDown, false, false, true, not isController)
    _, self.eventIdLeftRightMouse = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_LEFTRIGHT_DRAG, self, self.onCameraLeftRight, false, false, true, not isController)
end
function ShopConfigScreen:onCameraLeftRight(actionName, inputValue, _, _)
    if actionName == InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE then
        self.inputHorizontal = inputValue * -1 * 0.001 * g_currentDt
    elseif not self.configSlider.mouseDown then
        local dragValue = inputValue * ShopConfigScreen.MOUSE_SPEED_MULTIPLIER
        self.accumDraggingInput = self.accumDraggingInput + math.abs(dragValue * g_screenAspectRatio)
        if self.accumDraggingInput >= ShopConfigScreen.MIN_MOUSE_DRAG_INPUT then
            self.inputDragging = true
            self.inputHorizontal = dragValue * 0.001 * 16.666
            return
        end
        self.inputHorizontal = 0
    end
end
function ShopConfigScreen:onCameraUpDown(actionName, inputValue, _, _)
    if actionName == InputAction.AXIS_LOOK_UPDOWN_VEHICLE then
        self.inputVertical = inputValue * 0.001 * g_currentDt
    elseif not self.configSlider.mouseDown then
        local dragValue = inputValue * ShopConfigScreen.MOUSE_SPEED_MULTIPLIER
        self.accumDraggingInput = self.accumDraggingInput + math.abs(dragValue)
        if self.accumDraggingInput >= ShopConfigScreen.MIN_MOUSE_DRAG_INPUT then
            self.inputDragging = true
            self.inputVertical = dragValue * 0.001 * 16.666
            return
        end
        self.inputVertical = 0
    end
end
function ShopConfigScreen:onCameraZoom(_, inputValue, direction, isAnalog, isMouse)
    if isMouse and self.configSlider:getIsVisible() then
        local mouseX, mouseY = g_inputBinding:getMousePosition()
        if GuiUtils.checkOverlayOverlap(mouseX, mouseY, self.configSlider.absPosition[1], self.configSlider.absPosition[2], self.configSlider.size[1], self.configSlider.size[2]) then
            return
        end
        if GuiUtils.checkOverlayOverlap(mouseX, mouseY, self.configurationLayout.absPosition[1], self.configurationLayout.absPosition[2], self.configurationLayout.size[1], self.configurationLayout.size[2]) then
            return
        end
    end
    local mouseX = 0.05 * direction
    if not isAnalog then
        mouseX = 0.2 * direction
        if isMouse then
        end
    end
    self.inputZoom = self.inputZoom + inputValue * mouseX
end
function ShopConfigScreen:updateInput(dt)
    self:updateInputContext()
    if self.inputVertical ~= 0 then
        self.inputVertical = 0
        self.rotX = self.rotX - self.inputVertical
    end
    if self.inputHorizontal ~= 0 then
        self.inputHorizontal = 0
        self.rotY = self.rotY - self.inputHorizontal
    end
    if self.inputZoom ~= 0 then
        self.zoomTarget = self.zoomTarget + dt * self.inputZoom * 0.1
        self.zoomTarget = math.clamp(self.zoomTarget, self.cameraMinDistance, self.cameraMaxDistance)
        self.inputZoom = 0
    end
    self.cameraDistance = self.zoomTarget + math.pow(0.99579, dt) * (self.cameraDistance - self.zoomTarget)
    self.rotX = self:limitXRotation(self.rotX)
    local value = g_inputBinding:getInputHelpMode()
    if value ~= self.lastInputHelpMode then
        self.lastInputHelpMode = value
        self:updateInputGlyphs()
    end
    if self.isDragging or not self.inputDragging then
        if self.isDragging and not self.inputDragging then
            self.isDragging = false
            g_inputBinding:setShowMouseCursor(true)
            self.accumDraggingInput = 0
        end
    else
        self.isDragging = true
        g_inputBinding:setShowMouseCursor(false, true)
    end
    self.inputDragging = false
end
function ShopConfigScreen:limitXRotation(currentXRotation)
    local camHeight = self.cameraDistance * math.sin(currentXRotation) + self.focusY
    local rotMaxX = ShopConfigScreen.MAX_CAMERA_HEIGHT - self.focusY
    local maxHeight = math.min(camHeight, rotMaxX)
    local rotMaxX = self.rotMaxX
    if maxHeight <= self.cameraDistance then
        rotMaxX = math.min(rotMaxX, (math.asin(maxHeight / self.cameraDistance)))
    end
    return math.max(math.max(self.rotMinX, (math.asin((ShopConfigScreen.MIN_CAMERA_HEIGHT - self.focusY) / self.cameraDistance))), (math.min(rotMaxX, currentXRotation)))
end
function ShopConfigScreen:updateInputContext()
    local currentInputMode = g_inputBinding:getLastInputMode()
    if currentInputMode ~= self.lastInputMode then
        local isController = currentInputMode == GS_INPUT_HELP_MODE_GAMEPAD
        g_inputBinding:setActionEventActive(self.eventIdUpDownController, isController)
        g_inputBinding:setActionEventActive(self.eventIdLeftRightController, isController)
        g_inputBinding:setActionEventActive(self.eventIdUpDownMouse, not isController)
        g_inputBinding:setActionEventActive(self.eventIdLeftRightMouse, not isController)
        self.lastInputMode = currentInputMode
        self.isDragging = false
        g_inputBinding:setShowMouseCursor(true)
    end
end
function ShopConfigScreen:consoleCommandUIToggle()
    self:toggleHUDVisible()
    return "ShopConfigScreen hudVisible=" .. tostring(self.shopConfigContent:getIsVisible())
end
function ShopConfigScreen:inputEvent(action, value, eventUsed)
    eventUsed = ShopConfigScreen:superClass().inputEvent(self, action, value, eventUsed)
    if not eventUsed and action == InputAction.TOGGLE_STORE then
        self:onClickBack()
        self.target:onClickBack()
        g_gui:changeScreen(nil)
        eventUsed = true
    end
    return eventUsed
end
ShopConfigScreen.GUI_PROFILE = {
    ["MAINTENANCE_COST"] = "shopConfigAttributeIconMaintenanceCosts",
    ["POWER"] = "shopConfigAttributeIconPower",
    ["TRANSMISSION"] = "shopConfigAttributeIconTransmission",
    ["FUEL"] = "shopConfigAttributeIconFuel",
    ["ELECTRICCHARGE"] = "shopConfigAttributeIconElectricCharge",
    ["METHANE"] = "shopConfigAttributeIconMethane",
    ["MAX_SPEED"] = "shopConfigAttributeIconMaxSpeed",
    ["CAPACITY"] = "shopConfigAttributeIconCapacity",
    ["WEIGHT"] = "shopConfigAttributeIconWeight",
    ["ADDITIONAL_WEIGHT"] = "shopConfigAttributeIconAdditionalWeight",
    ["WORKING_WIDTH"] = "shopConfigAttributeIconWorkingWidth",
    ["WORKING_SPEED"] = "shopConfigAttributeIconWorkSpeed",
    ["POWER_REQUIREMENT"] = "shopConfigAttributeIconPowerReq",
    ["WHEELS"] = "shopConfigAttributeIconWheels",
    ["BALE_SIZE_ROUND"] = "shopConfigAttributeIconBaleSizeRound",
    ["BALE_SIZE_SQUARE"] = "shopConfigAttributeIconBaleSizeSquare",
    ["BALEWRAPPER_SIZE_ROUND"] = "shopConfigAttributeIconBaleWrapperBaleSizeRound",
    ["BALEWRAPPER_SIZE_SQUARE"] = "shopConfigAttributeIconBaleWrapperBaleSizeSquare",
    ["MAX_TREE_SIZE"] = "shopConfigAttributeIconMaxTreeSize",
    ["MAX_TREE_MASS"] = "shopConfigAttributeIconMaxTreeMass",
    ["YARDER_MAX_LENGTH"] = "shopConfigAttributeIconYarderMaxLength",
    ["BUTTON_BUY"] = "buttonBuy"
}
ShopConfigScreen.L10N_SYMBOL = {
    ["MAINTENANCE_COST"] = "shop_maintenanceValue",
    ["POWER"] = "shopConfig_maxPowerValue",
    ["FUEL"] = "shop_fuelValue",
    ["FUEL_DEF"] = "shopConfig_fuelDefValue",
    ["MAX_SPEED"] = "shop_maxSpeed",
    ["CAPACITY"] = "shop_capacityValue",
    ["WORKING_WIDTH"] = "shop_workingWidthValue",
    ["WORKING_SPEED"] = "shop_maxSpeed",
    ["POWER_REQUIREMENT"] = "shopConfig_neededPowerValue",
    ["BUTTON_BUY"] = "button_buy",
    ["BUTTON_CONFIGURE"] = "button_configurate",
    ["UNIT_LITER"] = "unit_literShort",
    ["UNIT_KW"] = "unit_kw",
    ["UNIT_KG"] = "unit_kg",
    ["DEF_SHORT"] = "fillType_def_short",
    ["NOT_ENOUGH_MONEY_BUY"] = "shop_messageNotEnoughMoneyToBuy",
    ["NOT_ENOUGH_MONEY_LEASE"] = "shop_messageNotEnoughMoneyToLease",
    ["TOO_FEW_SLOTS"] = "shop_messageNotEnoughSlotsToBuy",
    ["CONFIRM_BUY"] = "shop_doYouWantToBuy",
    ["CONFIRM_LEASE"] = "shop_doYouWantToLease",
    ["CONFIGURATION_LABEL"] = "shop_configuration"
}
ShopConfigScreen.SIZE = {
    ["INPUT_GLYPH"] = { 48, 48 }
}