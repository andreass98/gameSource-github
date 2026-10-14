FarmlandStatsDialog = {}
FarmlandStatsDialog.MOD_NAME = g_currentModName
FarmlandStatsDialog.MOD_DIR = g_currentModDirectory
local FarmlandStatsDialog_mt = Class(FarmlandStatsDialog, MessageDialog)
function FarmlandStatsDialog.register()
    local instance = FarmlandStatsDialog.new()
    g_gui:loadGui(FarmlandStatsDialog.MOD_DIR .. "gui/FarmlandStatsDialog.xml", "FarmlandStatsDialog", instance)
    FarmlandStatsDialog.INSTANCE = instance
end
function FarmlandStatsDialog.new(target, custom_mt)
    -- upvalues: (copy) FarmlandStatsDialog_mt
    local self = FarmlandStatsDialog:superClass().new(target, custom_mt or FarmlandStatsDialog_mt)
    self.farmlandId = 0
    self.fieldNumber = 0
    self.fieldArea = 0
    self.statistic = nil
    self.showTotal = false
    return self
end
function FarmlandStatsDialog:setData(farmlandId, fieldNumber, fieldArea, statistic)
    self.farmlandId = farmlandId
    self.fieldNumber = fieldNumber
    self.fieldArea = fieldArea
    self.statistic = statistic
    local farmlandStatistics = g_precisionFarming.farmlandStatistics
    local setChangePercentageElement
    if fieldNumber == 0 then
        setChangePercentageElement = string.format(g_i18n:getText("ui_economicAnalysisHeaderAdditionalField"), fieldArea)
    else
        setChangePercentageElement = string.format(g_i18n:getText("ui_economicAnalysisHeaderField"), fieldNumber, fieldArea)
    end
    self.economicAnalysisHeaderField:setText(setChangePercentageElement)
    local setChangePercentageElement = self.economicAnalysisHeaderValues
    setChangePercentageElement:setText(g_i18n:getText(self.showTotal and "ui_economicAnalysisHeaderValuesTotal" or "ui_economicAnalysisHeaderValuesPeriod"))
    local function setChangePercentageElement(element, value, valueRegular, cost, inversePercentageColor)
        local pct = 0
        if value == valueRegular then
            element:setText("")
            return pct
        end
        local direction = nil
        local pctText = ""
        if valueRegular == 0 then
            if math.floor(cost or 0) == 0 then
                pctText = ""
            else
                pctText = string.format("(%s%s)", cost > 0 and "+" or "", g_i18n:formatMoney(cost))
                pct = 100
                direction = cost > 0
            end
        else
            pct = math.floor(-100 * (1 - value / valueRegular))
            if pct ~= 0 then
                pctText = string.format(pct <= 0 and "(%d%%)" or "(+%d%%)", pct)
                direction = pct > 0
            end
        end
        if inversePercentageColor == true then
        end
        element:applyProfile(direction and "farmlandStatsDialogChangeNeg" or "farmlandStatsDialogChangePos", true)
        element:setText(pctText)
        return pct
    end
    local function buildValueDisplay(statistic, index, showTotal, name, nameRegular, fillTypeIndex, showWeight, showValue, showCost, showDetailedLiters, unitStr, cost, weight, inversePercentageColor)
        -- upvalues: (copy) farmlandStatistics, (copy) self, (copy) setChangePercentageElement
        if unitStr == nil then
            unitStr = " l"
        elseif unitStr:len() > 0 then
        end
        local value = statistic:getValue(showTotal, name)
        if nameRegular == nil then
            nameRegular = value
        elseif type(nameRegular) == "string" then
            nameRegular = statistic:getValue(showTotal, nameRegular)
        elseif type(nameRegular) ~= "number" then
            nameRegular = value
        end
        local valueText = cost or farmlandStatistics:getFillLevelPrice(value, fillTypeIndex)
        local valueText = weight or farmlandStatistics:getFillLevelWeight(value, fillTypeIndex)
        if showValue then
            local valueText = "%d" .. unitStr
            if showDetailedLiters then
                valueText = "%.1f" .. unitStr
            else
                value = MathUtil.round(value)
            end
            if showWeight then
            end
            self.statAmountText[index]:setText(string.format(valueText, value, valueText))
        else
            self.statAmountText[index]:setText("")
        end
        if showCost == nil or showCost then
            self.statCostText[index]:setText(g_i18n:formatMoney(valueText))
        else
            self.statCostText[index]:setText("")
        end
        local valueText = setChangePercentageElement(self.statPercentageText[index], value, nameRegular, valueText, inversePercentageColor)
        local valueText = showCost == false and 0 or valueText
        return math.max((math.floor(valueText))), math.max(math.floor(valueText * (-valueText * 0.01 + 1)), 0)
    end
    local subsidies, yieldWeight = buildValueDisplay(statistic, 1, self.showTotal, "numSoilSamples", 0, "soilSamples", false, true, true, false, "", statistic:getValue(self.showTotal, "soilSampleCosts"))
    local subsidies, yieldWeight = buildValueDisplay(statistic, 2, self.showTotal, "usedLime", "usedLimeRegular", FillType.LIME, true, true, true, false)
    local subsidies, yieldWeight = buildValueDisplay(statistic, 3, self.showTotal, "usedMineralFertilizer", "usedMineralFertilizerRegular", FillType.FERTILIZER, true, true, true, false)
    local subsidies, yieldWeight = buildValueDisplay(statistic, 4, self.showTotal, "usedLiquidFertilizer", "usedLiquidFertilizerRegular", FillType.LIQUIDFERTILIZER, false, true, true, false)
    buildValueDisplay(statistic, 5, self.showTotal, "usedManure", "usedManureRegular", FillType.MANURE, true, true, false, false)
    buildValueDisplay(statistic, 6, self.showTotal, "usedLiquidManure", "usedLiquidManureRegular", FillType.LIQUIDMANURE, false, true, false, false)
    local subsidies, yieldWeight = buildValueDisplay(statistic, 7, self.showTotal, "usedSeeds", "usedSeedsRegular", FillType.SEEDS, true, true, true, false)
    local subsidies, yieldWeight = buildValueDisplay(statistic, 8, self.showTotal, "usedHerbicide", "usedHerbicideRegular", FillType.HERBICIDE, false, true, true, false)
    local subsidies, yieldWeight = buildValueDisplay(statistic, 9, self.showTotal, "usedFuel", nil, FillType.DIESEL, false, true, true, true)
    local subsidies, yieldWeight = buildValueDisplay(statistic, 10, self.showTotal, "vehicleCosts", nil, 0, false, false, true, false)
    local subsidies, yieldWeight = buildValueDisplay(statistic, 11, self.showTotal, "helperCosts", nil, 0, false, false, true, false)
    local subsidies = statistic:getValue(self.showTotal, "subsidies")
    buildValueDisplay(statistic, 12, self.showTotal, subsidies, 0, 0, false, false, true, false, nil, subsidies, 0, false)
    local yieldWeight = statistic:getValue(self.showTotal, "yieldWeight")
    local yieldBestPrice = statistic:getValue(self.showTotal, "yieldBestPrice")
    buildValueDisplay(statistic, 13, self.showTotal, "yield", "yieldRegular", 0, true, true, true, false, nil, yieldBestPrice, yieldWeight, true)
    local earningsIncrease = statistic:getValue(self.showTotal, "yield")
    local totalEarnings = statistic:getValue(self.showTotal, "yieldRegular")
    local earningsIncreasePct = earningsIncrease / math.max(totalEarnings, 0.01)
    local earningsIncrease = 0
    if earningsIncreasePct ~= 0 then
        earningsIncrease = yieldBestPrice - yieldBestPrice / earningsIncreasePct
    end
    local costIncrease = 0 + yieldWeight + yieldWeight + yieldWeight + yieldWeight + yieldWeight + yieldWeight + yieldWeight + yieldWeight + yieldWeight - (0 + subsidies + subsidies + subsidies + subsidies + subsidies + subsidies + subsidies + subsidies + subsidies)
    setChangePercentageElement(self.statTotalCostPercentageText, totalCosts, 0, math.abs(costIncrease), false)
    setChangePercentageElement(self.statTotalEarningsPercentageText, yieldBestPrice, 0, earningsIncrease, true)
    setChangePercentageElement(self.statTotalPercentageText, yieldBestPrice, 0, costIncrease + earningsIncrease, true)
    local totalEarnings = yieldBestPrice + subsidies
    self.statTotalCostText:setText(g_i18n:formatMoney(totalCosts))
    self.statTotalEarningsText:setText(g_i18n:formatMoney(totalEarnings))
    self.statTotalText:setText(g_i18n:formatMoney(totalEarnings - totalCosts))
end
function FarmlandStatsDialog:onSwitchMode()
    self.showTotal = not self.showTotal
    if self.farmlandId ~= 0 then
        self:setData(self.farmlandId, self.fieldNumber, self.fieldArea, self.statistic)
    end
end
function FarmlandStatsDialog:onReset()
    if self.farmlandId ~= 0 then
        g_precisionFarming.farmlandStatistics:resetStatistic(self.farmlandId, false)
        self:setData(self.farmlandId, self.fieldNumber, self.fieldArea, self.statistic)
        if g_server == nil and g_client ~= nil then
            g_client:getServerConnection():sendEvent(FarmlandStatisticsResetEvent.new(self.farmlandId))
        end
    end
end
function FarmlandStatsDialog:onCloseButton()
    self:close()
    self.farmlandId = 0
    self.fieldNumber = 0
    self.fieldArea = 0
    self.statistic = nil
    self.showTotal = false
end
function FarmlandStatsDialog.show(farmlandId, fieldNumber, fieldArea, statistic)
    if FarmlandStatsDialog.INSTANCE ~= nil then
        FarmlandStatsDialog.INSTANCE:setData(farmlandId, fieldNumber, fieldArea, statistic)
        g_gui:showDialog("FarmlandStatsDialog")
    end
end
function FarmlandStatsDialog.createFromExistingGui(gui, _)
    FarmlandStatsDialog.register()
    local farmlandId = gui.farmlandId
    if farmlandId ~= 0 then
        FarmlandStatsDialog.show(farmlandId, gui.fieldNumber, gui.fieldArea, gui.statistic)
    end
end