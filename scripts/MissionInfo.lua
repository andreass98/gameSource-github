MissionInfo = {}
local MissionInfo_mt = Class(MissionInfo)
function MissionInfo.new(baseDirectory, customEnvironment, customMt)
    -- upvalues: (copy) MissionInfo_mt
    local self = setmetatable({}, customMt or MissionInfo_mt)
    self.baseDirectory = baseDirectory
    self.customEnvironment = customEnvironment
    self.savegameDirectory = nil
    self.mapId = nil
    self.mapTitle = nil
    self.mapXMLFilename = nil
    self.isValid = nil
    self.hasInitiallyOwnedFarmlands = nil
    self.initialMoney = nil
    self.initialLoan = nil
    self.isSnowEnabled = nil
    self.disasterDestructionState = nil
    self.growthMode = nil
    self.weedsEnabled = nil
    self.stonesEnabled = nil
    self.timeScale = nil
    self.dirtInterval = nil
    self.fruitDestruction = nil
    self.helperBuySeeds = nil
    self.helperBuyFertilizer = nil
    self.helperSlurrySource = nil
    self.helperManureSource = nil
    self.stopAndGoBraking = nil
    self.trailerFillLimit = nil
    self.automaticMotorStartEnabled = nil
    self.introductionHelpActive = nil
    self.autoSaveInterval = nil
    self.foundHelpIcons = nil
    self.economicDifficulty = nil
    self.trafficEnabled = nil
    return self
end
function MissionInfo:loadDefaults()
    self.id = "invalid"
    self.scriptFilename = ""
    self.scriptClass = ""
end
function MissionInfo.isValidMissionId(_, id)
    if id == nil or id:len() == 0 then
        return false
    else
        return id:find("[^%w_]") == nil
    end
end