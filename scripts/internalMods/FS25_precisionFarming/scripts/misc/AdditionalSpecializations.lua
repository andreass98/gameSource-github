local modName = g_currentModName
local additionals = {}
local additionalsSpec = {
    ["sprayer"] = {
        modName .. ".extendedSprayer",
        modName .. ".extendedSprayerEffects",
        modName .. ".manureSensor",
        modName .. ".weedSpotSpray"
    },
    ["sowingMachine"] = { modName .. ".extendedSowingMachine" },
    ["motorized"] = { modName .. ".extendedMotorized", modName .. ".cropSensor" },
    ["wearable"] = { modName .. ".extendedWearable" },
    ["combine"] = { modName .. ".extendedCombine" },
    ["mower"] = { modName .. ".extendedMower" }
}
local globalSpec = { modName .. ".precisionFarmingStatistic" }
local oldFinalizeTypes = TypeManager.finalizeTypes
function TypeManager:finalizeTypes(...)
    -- upvalues: (copy) modName, (copy) globalSpec, (copy) additionalsSpec, (copy) additionals, (copy) oldFinalizeTypes
    if self.typeName == "vehicle" and g_modIsLoaded[modName] then
        for typeName, typeEntry in pairs(self:getTypes()) do
            for _, spec in pairs(globalSpec) do
                if typeEntry.specializationsByName[spec] == nil then
                    self:addSpecialization(typeName, spec)
                end
            end
            local i = #typeEntry.specializationNames
            for i = i, 1, -1 do
                for addName, specs in pairs(additionalsSpec) do
                    if typeEntry.specializationNames[i] == addName then
                        local j = 1
                        for j = j, #specs do
                            if typeEntry.specializationsByName[specs[j]] == nil then
                                self:addSpecialization(typeName, specs[j])
                            end
                        end
                    end
                end
            end
            for _, spec in pairs(additionals) do
                if typeName == _ then
                    local addName = 1
                    for addName = addName, #spec do
                        if typeEntry.specializationsByName[spec[addName]] == nil then
                            self:addSpecialization(typeName, spec[addName])
                        end
                    end
                end
            end
        end
    end
    oldFinalizeTypes(self, ...)
end