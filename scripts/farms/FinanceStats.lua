FinanceStats = {}
local FinanceStats_mt = Class(FinanceStats)
if GS_IS_MOBILE_VERSION then
    FinanceStats.statNames = {
        "harvestIncome",
        "incomeBga",
        "soldVehicles",
        "soldAnimals",
        "soldBales",
        "soldWool",
        "soldMilk",
        "soldProducts",
        "soldWood",
        "wagePayment",
        "newVehiclesCost",
        "newAnimalsCost",
        "fieldPurchase",
        "constructionCost",
        "propertyMaintenance",
        "purchaseFuel",
        "purchaseSeeds",
        "purchaseFertilizer",
        "animalUpkeep",
        "other"
    }
else
    FinanceStats.statNames = {
        "newVehiclesCost",
        "soldVehicles",
        "newHandtoolsCost",
        "soldHandtools",
        "newAnimalsCost",
        "soldAnimals",
        "constructionCost",
        "soldBuildings",
        "fieldPurchase",
        "fieldSelling",
        "vehicleRunningCost",
        "vehicleLeasingCost",
        "propertyMaintenance",
        "propertyIncome",
        "productionCosts",
        "soldWood",
        "soldBales",
        "soldWool",
        "soldMilk",
        "soldProducts",
        "purchaseFuel",
        "purchaseSeeds",
        "purchaseFertilizer",
        "purchaseSaplings",
        "purchaseWater",
        "purchaseBales",
        "purchasePallets",
        "harvestIncome",
        "incomeBga",
        "missionIncome",
        "wagePayment",
        "other",
        "loanInterest"
    }
end
FinanceStats.statNameToIndex = {}
FinanceStats.statNamesI18n = {}
FinanceStats.filledI18N = false
for i, statName in ipairs(FinanceStats.statNames) do
    FinanceStats.statNameToIndex[statName] = i
end
function FinanceStats.new(customMt)
    -- upvalues: (copy) FinanceStats_mt
    local self = setmetatable({}, customMt or FinanceStats_mt)
    for _, statName in ipairs(FinanceStats.statNames) do
        self[statName] = 0
        FinanceStats.statNamesI18n[statName] = g_i18n:getText("finance_" .. statName)
    end
    return self
end
function FinanceStats:saveToXMLFile(xmlFile, key)
    for _, statName in ipairs(self.statNames) do
        xmlFile:setFloat(key .. "." .. statName, self[statName])
    end
end
function FinanceStats:loadFromXMLFile(xmlFile, key)
    for _, statName in ipairs(self.statNames) do
        self[statName] = xmlFile:getFloat(key .. "." .. statName, 0)
    end
end
function FinanceStats:merge(other)
    for _, statName in ipairs(self.statNames) do
        self[statName] = self[statName] + other[statName]
    end
end