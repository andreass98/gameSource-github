AchievementManager = {}
local AchievementManager_mt = Class(AchievementManager, AbstractManager)
function AchievementManager.new(customMt)
    -- upvalues: (copy) AchievementManager_mt
    return AbstractManager.new(customMt or AchievementManager_mt)
end
function AchievementManager:initDataStructures()
    self.achievementList = {}
    self.achievementListById = {}
    self.achievementListByName = {}
    self.pendingAchievements = {}
    self.numberOfAchievements = 0
    self.numberOfUnlockedAchievements = 0
    self.achievementsValid = false
    self.achievementTimer = 0
    self.achievementTimeInterval = 30000
    self.fillTypeAchievements = {}
end
function AchievementManager:load()
    local xmlFile = XMLFile.load("achievementsXML", "dataS/achievements.xml")
    if xmlFile == nil then
        return false
    end
    local xmlFileContent = xmlFile:getAsString()
    initAchievements(xmlFileContent)
    self.numberOfAchievements = 0
    for _achievementIndex, key in xmlFile:iterator("achievements.achievement") do
        local id = xmlFile:getInt(key .. "#id")
        if id == nil then
            Logging.xmlDevWarning(xmlFile, "Missing or non-integer \'id\' for achievement \'%s\'", key)
        else
            local idName = xmlFile:getString(key .. "#idName")
            if string.isNilOrWhitespace(idName) then
                Logging.xmlDevWarning(xmlFile, "Missing \'idName\' for achievement \'%s\'", key)
            else
                local score = xmlFile:getInt(key .. "#score")
                local targetScore = xmlFile:getInt(key .. "#targetScore")
                local showScore = xmlFile:getBool(key .. "#showScore")
                local imageFilename = xmlFile:getString(key .. "#imageFilename")
                local imageSize = string.getVector(xmlFile:getString(key .. "#imageSize"), 2) or { 2048, 2048 }
                local imageUVs = GuiUtils.getUVs(xmlFile:getString(key .. "#imageUVs") or "0 0 1 1", imageSize)
                if (xmlFile:getString(key .. "#psn_type") or "") ~= "P" or GS_PLATFORM_PLAYSTATION then
                    local name = g_i18n:getText("achievement_name" .. idName)
                    local description = g_i18n:getText("achievement_desc" .. idName)
                    local description = string.gsub(description, "$MEASURING_UNIT", g_i18n:getMeasuringUnit(true))
                    self:addAchievement(id, idName, name, string.gsub(description, "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true)), score, targetScore, showScore, imageFilename, imageUVs)
                end
            end
        end
    end
    local lockedImageSize = string.getVector(xmlFile:getString("achievements#lockedImageSize"), 2) or { 2048, 2048 }
    self.lockedImage = xmlFile:getString("achievements#lockedImageFilename")
    self.lockedUVs = GuiUtils.getUVs(xmlFile:getString("achievements#lockedImageUVs") or "0 0 1 1", lockedImageSize)
    xmlFile:delete()
    if areAchievementsAvailable() then
        self:loadAchievementsState(false)
    end
    return true
end
function AchievementManager:loadMapData()
    local mission = g_currentMission
    local isNewSPCareer = mission.missionInfo.isNewSPCareer
    if isNewSPCareer then
        self.startPlayTime = nil
        self.startMoney = nil
        self.startMissionCount = nil
        self.startCultivatedHectares = nil
        self.startSownHectares = nil
        self.startFertilizedHectares = nil
        self.startThreshedHectares = nil
        self.startCutTreeCount = nil
        self.startBreedCowsCount = nil
        self.startBreedSheepCount = nil
        self.startBreedPigsCount = nil
        self.startBreedChickenCount = nil
        self.startPetDogCount = nil
        self.startTractorDistance = nil
        self.startTruckDistance = nil
        self.startCarDistance = nil
        self.startRepairVehicleCount = nil
        self.startRepaintVehicleCount = nil
        self.startHorseDistance = nil
        self.startHorseJumpCount = nil
        self.startSoldCottonBales = nil
        self.startWrappedBales = nil
    else
        local stats = mission:farmStats()
        self.startPlayTime = math.floor(stats:getTotalValue("playTime") / 60 + 0.0001)
        self.startMoney = g_farmManager:getFarmById(0).money
        self.startMissionCount = stats:getTotalValue("missionCount")
        self.startCultivatedHectares = stats:getTotalValue("cultivatedHectares")
        self.startSownHectares = stats:getTotalValue("sownHectares")
        self.startFertilizedHectares = stats:getTotalValue("sprayedHectares")
        self.startThreshedHectares = stats:getTotalValue("threshedHectares")
        self.startCutTreeCount = stats:getTotalValue("cutTreeCount")
        self.startBreedCowsCount = stats:getTotalValue("breedCowsCount")
        self.startBreedSheepCount = stats:getTotalValue("breedSheepCount")
        self.startBreedPigsCount = stats:getTotalValue("breedPigsCount")
        self.startBreedChickenCount = stats:getTotalValue("breedChickenCount")
        self.startPetDogCount = stats:getTotalValue("petDogCount")
        self.startTractorDistance = stats:getTotalValue("tractorDistance")
        self.startTruckDistance = stats:getTotalValue("truckDistance")
        self.startCarDistance = stats:getTotalValue("carDistance")
        self.startRepairVehicleCount = stats:getTotalValue("repairVehicleCount")
        self.startRepaintVehicleCount = stats:getTotalValue("repaintVehicleCount")
        self.startHorseDistance = stats:getTotalValue("horseDistance")
        self.startHorseJumpCount = stats:getTotalValue("horseJumpCount")
        self.startSoldCottonBales = stats:getTotalValue("soldCottonBales")
        self.startWrappedBales = stats:getTotalValue("wrappedBales")
    end
    self.fillTypeAchievements = {}
    for _, fillType in ipairs(g_fillTypeManager:getFillTypes()) do
        local achievementName = fillType.achievementName
        if achievementName ~= nil and self.achievementListByName[achievementName] ~= nil then
            local fillTypeAchievement = {
                ["name"] = achievementName,
                ["fillType"] = fillType
            }
            if not isNewSPCareer then
                fillTypeAchievement.startValue = fillType.totalAmount
            end
            table.insert(self.fillTypeAchievements, fillTypeAchievement)
        end
    end
    return true
end
function AchievementManager:addAchievement(id, idName, name, description, score, targetScore, showScore, imageFilename, imageUVs)
    local achievement = {
        ["id"] = id,
        ["idName"] = idName,
        ["name"] = name,
        ["description"] = description,
        ["score"] = score,
        ["targetScore"] = targetScore,
        ["showScore"] = showScore,
        ["imageFilename"] = imageFilename,
        ["imageUVs"] = imageUVs,
        ["unlocked"] = false
    }
    table.insert(self.achievementList, achievement)
    self.achievementListById[id] = achievement
    self.achievementListByName[idName] = achievement
    self.numberOfAchievements = self.numberOfAchievements + 1
    return achievement
end
function AchievementManager:resetAchievementsState()
    self.numberOfUnlockedAchievements = 0
    for _, achievement in pairs(self.achievementList) do
        achievement.unlocked = false
    end
    self.achievementsValid = false
end
function AchievementManager:loadAchievementsState(showGui)
    self.numberOfUnlockedAchievements = 0
    for _, achievement in pairs(self.achievementList) do
        achievement.unlocked = getAchievement(achievement.id)
        if achievement.unlocked then
            if not achievement.unlocked and (showGui and not hasNativeAchievementGUI()) then
                g_messageCenter:publish(MessageType.ACHIEVEMENT_UNLOCKED, achievement.name, achievement.description, achievement.imageFilename, achievement.imageUVs)
            end
            self.numberOfUnlockedAchievements = self.numberOfUnlockedAchievements + 1
        end
    end
    self.achievementsValid = true
end
function AchievementManager:handleStandardScoreAchievement(idName, currentScore, startScore)
    local currentAchievement = self.achievementListByName[idName]
    if currentAchievement ~= nil and not currentAchievement.unlocked and (g_currentMission.missionInfo.isNewSPCareer or (startScore == nil or currentScore ~= startScore)) then
        currentAchievement.score = currentScore
        setAchievementProgress(currentAchievement.id, currentAchievement.score, currentAchievement.targetScore)
        if not areAchievementsAvailable() then
            self.pendingAchievements[currentAchievement] = true
        end
    end
end
function AchievementManager:tryUnlock(idName, score)
    if self:getCanUnlockAchievement() then
        local currentAchievement = self.achievementListByName[idName]
        if currentAchievement ~= nil and not currentAchievement.unlocked then
            currentAchievement.score = score
            setAchievementProgress(currentAchievement.id, score, currentAchievement.targetScore)
            if not areAchievementsAvailable() then
                self.pendingAchievements[currentAchievement] = true
            end
        end
    end
end
function AchievementManager:update(dt)
    if areAchievementsAvailable() then
        for achievement, _ in pairs(self.pendingAchievements) do
            self:tryUnlock(achievement.id, achievement.score)
            self.pendingAchievements[achievement] = nil
        end
        if getHaveAchievementsChanged() then
            self.achievementsValid = false
        end
        if not self.achievementsValid then
            self:loadAchievementsState(true)
        end
        if self:getCanUnlockAchievement() then
            self:updateAchievements(dt)
        end
    end
end
function AchievementManager:getCanUnlockAchievement()
    local mission = g_currentMission
    if mission == nil then
        return false
    elseif mission.missionInfo:isa(FSCareerMissionInfo) then
        if mission.missionDynamicInfo.isMultiplayer then
            return false
        else
            return mission.gameStarted and true or false
        end
    else
        return false
    end
end
function AchievementManager:updateAchievements(dt)
    self.achievementTimer = self.achievementTimer + dt
    if self.achievementTimer >= self.achievementTimeInterval then
        local farm = g_farmManager:getFarmById(g_currentMission:getFarmId())
        if farm == nil then
            return
        end
        local stats = farm.stats
        local horseRiding = stats:getTotalValue("playTime") / 60 + 0.0001
        self:handleStandardScoreAchievement("PlayTime", math.floor(horseRiding), self.startPlayTime)
        self:handleStandardScoreAchievement("Money", farm.money, self.startMoney)
        local cultivatedHectares = stats:getTotalValue("cultivatedHectares")
        self:handleStandardScoreAchievement("CultivateFirst", cultivatedHectares, self.startCultivatedHectares)
        self:handleStandardScoreAchievement("Cultivate", cultivatedHectares, self.startCultivatedHectares)
        local sownHectares = stats:getTotalValue("sownHectares")
        self:handleStandardScoreAchievement("SowFirst", sownHectares, self.startSownHectares)
        self:handleStandardScoreAchievement("Sow", sownHectares, self.startSownHectares)
        local sprayedHectares = stats:getTotalValue("sprayedHectares")
        self:handleStandardScoreAchievement("FertilizeFirst", sprayedHectares, self.startFertilizedHectares)
        self:handleStandardScoreAchievement("Fertilize", sprayedHectares, self.startFertilizedHectares)
        local threshedHectares = stats:getTotalValue("threshedHectares")
        self:handleStandardScoreAchievement("HarvestedFirst", threshedHectares, self.startThreshedHectares)
        self:handleStandardScoreAchievement("Harvested", threshedHectares, self.startThreshedHectares)
        self:handleStandardScoreAchievement("BreedCows", stats:getTotalValue("breedCowsCount"), self.startBreedCowsCount)
        self:handleStandardScoreAchievement("BreedSheep", stats:getTotalValue("breedSheepCount"), self.startBreedSheepCount)
        self:handleStandardScoreAchievement("BreedPigs", stats:getTotalValue("breedPigsCount"), self.startBreedPigsCount)
        self:handleStandardScoreAchievement("BreedChicken", stats:getTotalValue("breedChickenCount"), self.startBreedChickenCount)
        self:handleStandardScoreAchievement("TractorDriving", stats:getTotalValue("tractorDistance"), self.startTractorDistance)
        self:handleStandardScoreAchievement("TruckDriving", stats:getTotalValue("truckDistance"), self.startTruckDistance)
        self:handleStandardScoreAchievement("CarDriving", stats:getTotalValue("carDistance"), self.startCarDistance)
        local horseRiding = stats:getTotalValue("horseDistance")
        self:handleStandardScoreAchievement("HorseRidingFirst", horseRiding, self.startHorseDistance)
        self:handleStandardScoreAchievement("HorseRiding", horseRiding, self.startHorseDistance)
        for _, fillTypeAchievement in ipairs(self.fillTypeAchievements) do
            self:handleStandardScoreAchievement(fillTypeAchievement.name, fillTypeAchievement.fillType.totalAmount, fillTypeAchievement.startValue)
        end
        self.achievementTimer = 0
    end
end
function AchievementManager:getLockedImageData()
    return self.lockedImage, self.lockedUVs
end