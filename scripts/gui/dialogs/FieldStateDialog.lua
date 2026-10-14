FieldStateDialog = {}
local FieldStateDialog_mt = Class(FieldStateDialog, DialogElement)
function FieldStateDialog.register()
    local fieldStateDialog = FieldStateDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/FieldStateDialog.xml", "FieldStateDialog", fieldStateDialog)
    FieldStateDialog.INSTANCE = fieldStateDialog
end
function FieldStateDialog.show(fieldId, fruitTypeName, growthState, groundTypeName, angle, groundLayer, fertilizerState, plowingState, weedState, limeState, stubbleState, buyField, removeFoliage)
    if FieldStateDialog.INSTANCE ~= nil then
        g_gui:showDialog("FieldStateDialog")
        FieldStateDialog.INSTANCE:setFieldId(fieldId)
        FieldStateDialog.INSTANCE:setFruitName(fruitTypeName, growthState)
        FieldStateDialog.INSTANCE:setGroundType(groundTypeName, angle)
        FieldStateDialog.INSTANCE:setGroundLayer(groundLayer)
        FieldStateDialog.INSTANCE:setFertilizerState(fertilizerState)
        FieldStateDialog.INSTANCE:setPlowingState(plowingState)
        FieldStateDialog.INSTANCE:setWeedState(weedState)
        FieldStateDialog.INSTANCE:setLimeState(limeState)
        FieldStateDialog.INSTANCE:setStubbleState(stubbleState)
        FieldStateDialog.INSTANCE:setBuyField(buyField)
        FieldStateDialog.INSTANCE:setRemoveFoliage(removeFoliage)
    end
end
function FieldStateDialog.new(target, custom_mt)
    -- upvalues: (copy) FieldStateDialog_mt
    return ColorPickerDialog.new(target, custom_mt or FieldStateDialog_mt)
end
function FieldStateDialog.createFromExistingGui(gui, guiName)
    FieldStateDialog.register()
    FieldStateDialog.show()
end
function FieldStateDialog:onOpen()
    FieldStateDialog:superClass().onOpen(self)
    self.buyField = nil
    local fieldGroundSystem = g_currentMission.fieldGroundSystem
    local texts = { "UNKNOWN" }
    for _, fruitType in ipairs(g_fruitTypeManager:getFruitTypes()) do
        table.insert(texts, fruitType.name)
    end
    self.fruitTypes:setTexts(texts)
    self.fruitTypes:setState(1, true)
    local groundTypeTexts = {}
    for fruitType, groundType in ipairs(FieldGroundType.getAllOrdered()) do
        table.insert(groundTypeTexts, FieldGroundType.getName(groundType))
    end
    self.groundTypes:setTexts(groundTypeTexts)
    local groundAngleTexts = {}
    self.groundAngleValues = {}
    local maxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.GROUND_ANGLE) + 1
    self.groundAngleStep = 3.141592653589793 / maxValue
    local groundType = 1
    local fruitType = 1
    for groundType = groundType, maxValue, fruitType do
        local angle = (groundType - 1) * self.groundAngleStep
        local i = math.deg(angle)
        table.insert(groundAngleTexts, string.format("%.1f \194\176", i))
        table.insert(self.groundAngleValues, angle)
    end
    self.groundAngles:setTexts(groundAngleTexts)
    for _, sprayType in ipairs(FieldSprayType.getAllOrdered()) do
        table.insert(_, FieldSprayType.getName(sprayType))
    end
    self.sprayTypes:setTexts(_)
    local fruitType = {}
    local sprayType = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
    local angle = 1
    for _ = {}, sprayType, angle do
        local rollerLevelTexts = tostring(_)
        table.insert(fruitType, rollerLevelTexts)
    end
    self.sprayLevel:setTexts(fruitType)
    local groundType = Platform.gameplay.usePlowCounter and fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL) or 0
    local angle = {}
    local i = 0
    local sprayType = 1
    for i = i, groundType, sprayType do
        local stubbleShredLevelTexts = tostring(i)
        table.insert(angle, stubbleShredLevelTexts)
    end
    self.plowLevel:setTexts(angle)
    local sprayType = {}
    local i = 0
    local rollerLevelTexts = 1
    for i = i, Platform.gameplay.useLimeCounter and fieldGroundSystem:getMaxValue(FieldDensityMap.LIME_LEVEL) or 0, rollerLevelTexts do
        local stoneTexts = tostring(i)
        table.insert(sprayType, stoneTexts)
    end
    self.limeLevel:setTexts(sprayType)
    local i = Platform.gameplay.useRolling and fieldGroundSystem:getMaxValue(FieldDensityMap.ROLLER_LEVEL) or 0
    local rollerLevelTexts = {}
    local i = 0
    local stubbleShredLevelTexts = 1
    for i = i, i, stubbleShredLevelTexts do
        table.insert(rollerLevelTexts, (tostring(i)))
    end
    self.rollerLevel:setTexts(rollerLevelTexts)
    local i = Platform.gameplay.useStubbleShred and fieldGroundSystem:getMaxValue(FieldDensityMap.STUBBLE_SHRED_LEVEL) or 0
    local stubbleShredLevelTexts = {}
    local i = 0
    local stoneTexts = 1
    for i = i, i, stoneTexts do
        table.insert(stubbleShredLevelTexts, (tostring(i)))
    end
    self.stubbleShredLevel:setTexts(stubbleShredLevelTexts)
    local i = g_currentMission.stoneSystem
    if i ~= nil and i:getMapHasStones() then
        self.stoneLevels = {
            0,
            1,
            2,
            3,
            4,
            5
        }
        self.stones:setTexts({
            "Invisible",
            "Small",
            "Medium",
            "Big",
            "Picked",
            "Blocked after picked"
        })
    end
    self.weed:setTexts({
        "invisible",
        "invisible dense",
        "small alive",
        "small dense alive",
        "big alive",
        "small dense weeded alive",
        "small dead",
        "small dense dead",
        "big dead"
    })
end
function FieldStateDialog:setFieldId(fieldIdStr)
    if fieldIdStr ~= nil then
        self.fieldIds:setText(fieldIdStr)
        local fieldId = tonumber(fieldIdStr)
        if fieldId ~= nil then
            local field = g_fieldManager:getFieldById(fieldId)
            if field ~= nil then
                local state = field:getFieldState()
                local x, z = field:getIndicatorPosition()
                state:update(x, z)
                self.fruitTypes:setState(state.fruitTypeIndex + 1, true)
                self.growthStates:setState(state.growthState, true)
                self.groundTypes:setState(state.groundType)
                self.weed:setState(state.weedState)
                self.sprayTypes:setState(state.sprayType)
                self.sprayLevel:setState(state.sprayLevel + 1)
                self.limeLevel:setState(state.limeLevel + 1)
                self.plowLevel:setState(state.plowLevel + 1)
                self.rollerLevel:setState(state.rollerLevel + 1)
                self.stubbleShredLevel:setState(state.stubbleShredLevel + 1)
            end
        end
    end
end
function FieldStateDialog:setFruitName(fruitTypeName, growthState)
    local fruitTypeIndex = g_fruitTypeManager:getFruitTypeIndexByName(fruitTypeName)
    if fruitTypeIndex ~= nil then
        self.fruitTypes:setState(fruitTypeIndex + 1, true)
        self.growthStates:setState((growthState or 0) + 1, true)
    end
end
function FieldStateDialog:setGroundType(groundTypeName, angleDeg)
    if groundTypeName == nil then
        return
    end
    local groundType = FieldGroundType.getByName(groundTypeName)
    if groundType == nil then
        Logging.warning("Unknown ground type name %q", groundTypeName)
        print("Available types: " .. FieldGroundType.getAllNames())
        return
    end
    self.groundTypes:setState(groundType)
    local angle = tonumber(angleDeg)
    if angle ~= nil then
        local angle = math.rad((math.abs(angle))) % 3.141592653589793
        local matchingState = MathUtil.snapValue(angle, self.groundAngleStep)
        local matchingState = 1
        for state, angleValue in ipairs(self.groundAngleValues) do
            if MathUtil.equalEpsilon(angleValue, matchingState) then
                matchingState = state
                break
            end
        end
        self.groundAngles:setState(matchingState)
    end
end
function FieldStateDialog:setGroundLayer(groundLayer)
    if groundLayer == nil then
        return
    else
        local sprayType = FieldSprayType.getByName(groundLayer)
        if sprayType == nil then
            Logging.warning("Unknown ground layer name %q", groundLayer)
            print("Available layers: " .. FieldSprayType.getAllNames())
        else
            self.sprayTypes:setState(sprayType)
        end
    end
end
function FieldStateDialog:setFertilizerState(fertilizerState)
    if fertilizerState ~= nil then
        self.sprayLevel:setState(fertilizerState + 1)
    end
end
function FieldStateDialog:setPlowingState(plowingState)
    if plowingState ~= nil then
        self.plowLevel:setState(plowingState + 1)
    end
end
function FieldStateDialog:setWeedState(weedState)
    if weedState ~= nil then
        self.weed:setState(weedState)
    end
end
function FieldStateDialog:setLimeState(limeState)
    if limeState ~= nil then
        self.limeLevel:setState(limeState + 1)
    end
end
function FieldStateDialog:setStubbleState(stubbleState)
    if stubbleState ~= nil then
        self.stubbleShredLevel:setState(stubbleState + 1)
    end
end
function FieldStateDialog:setBuyField(buyField)
    if buyField then
        self.buyField = buyField
    end
end
function FieldStateDialog:setRemoveFoliage(removeFoliage)
    if removeFoliage then
        self.fruitTypes:setState(1, true)
        self.growthStates:setState(1, true)
    end
end
function FieldStateDialog:updateGrowthStates()
    local state = self.fruitTypes:getState() - 1
    if state == 0 then
        table.insert({}, "")
    else
        local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(state)
        for _, name in ipairs(fruitTypeDesc.growthStateToName) do
            table.insert(texts, name)
        end
        self.growthStates:setTexts(texts)
    end
end
function FieldStateDialog:onClickFruitType(state)
    self:updateGrowthStates()
    self.growthStates:setDisabled(state == 1)
end
function FieldStateDialog:onClickGrowthStates(growthState)
    local fruitTypeState = self.fruitTypes:getState() - 1
    if fruitTypeState > 0 then
        local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeState)
        if fruitTypeDesc ~= nil then
            if fruitTypeDesc:getIsCut(growthState) and fruitTypeDesc.harvestGroundType ~= nil then
                self.groundTypes:setState(fruitTypeDesc.harvestGroundType)
                return
            end
            if fruitTypeDesc.groundTypeChangeType ~= nil and fruitTypeDesc.groundTypeChangeGrowthState <= growthState then
                self.groundTypes:setState(fruitTypeDesc.groundTypeChangeType)
            end
        end
    end
end
function FieldStateDialog:onClickOk()
    self:applySettings()
    self:close()
    return false
end
function FieldStateDialog:onClickApply()
    self:applySettings()
end
function FieldStateDialog:applySettings()
    local fieldIds = self.fieldIds:getText()
    local idStrs = string.split(fieldIds, ",")
    local fields = {}
    if #idStrs > 0 then
        for _, idStr in ipairs(idStrs) do
            local id = string.trim(idStr)
            if string.lower(id) == "all" then
                fields = g_fieldManager:getFields()
                break
            end
            local id = tonumber(id)
            local field = g_fieldManager:getFieldById(id)
            if field == nil then
                Logging.warning("Field \'%s\' not defined", id)
            else
                table.insert(fields, field)
            end
        end
    end
    local fruitTypeIndex = FruitType.UNKNOWN
    local growthState = 0
    local state = self.fruitTypes:getState()
    if state > 1 then
        fruitTypeIndex = g_fruitTypeManager:getFruitTypeByIndex(state - 1).index
        growthState = self.growthStates:getState()
    end
    local _ = self.groundTypes:getState()
    local idStr = self.groundAngleValues[self.groundAngles:getState()]
    local id = self.sprayTypes:getState()
    local field = self.weed:getState()
    local stoneLevel = self.stoneLevels[self.stones:getState()]
    local sprayLevel = self.sprayLevel:getState() - 1
    local limeLevel = self.limeLevel:getState() - 1
    local plowLevel = self.plowLevel:getState() - 1
    local rollerLevel = self.rollerLevel:getState() - 1
    local stubbleShredLevel = self.stubbleShredLevel:getState() - 1
    for _, field in ipairs(fields) do
        if self.buyField then
            local fieldFarmland = field.farmland
            if fieldFarmland ~= nil then
                fieldFarmland:setOwnerFarmId(g_localPlayer.farmId)
            end
        end
        local fieldFarmland = FieldUpdateTask.new()
        fieldFarmland:setField(field)
        fieldFarmland:setArea(field:getDensityMapPolygon())
        fieldFarmland:setFruit(fruitTypeIndex, growthState)
        fieldFarmland:setWeedState(field)
        fieldFarmland:setStoneLevel(stoneLevel)
        fieldFarmland:setGroundType(_)
        fieldFarmland:setGroundAngle(idStr)
        fieldFarmland:setSprayType(id)
        fieldFarmland:setSprayLevel(sprayLevel)
        fieldFarmland:setLimeLevel(limeLevel)
        fieldFarmland:setPlowLevel(plowLevel)
        fieldFarmland:setRollerLevel(rollerLevel)
        fieldFarmland:setStubbleShredLevel(stubbleShredLevel)
        fieldFarmland:resetDisplacement()
        fieldFarmland:clearTireTracks()
        g_fieldManager:addFieldUpdateTask(fieldFarmland)
    end
end