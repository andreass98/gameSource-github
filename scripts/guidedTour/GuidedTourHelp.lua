GuidedTourHelp = {}
function GuidedTourHelp.init()
    GuidedTourHelp.registerHelpProgress()
    GuidedTourHelp.registerHelpCalendar()
    GuidedTourHelp.registerHelpTime()
    GuidedTourHelp.registerHelpWeather()
    GuidedTourHelp.registerHelpBalance()
    GuidedTourHelp.registerHelpMiniMap()
    GuidedTourHelp.registerHelpFillLevels()
    GuidedTourHelp.registerHelpVehicleSelection()
end
function GuidedTourHelp.registerHelpProgress()
    local helpData = {}
    local text = g_i18n:getText("introduction_tourProgress")
    function helpData.draw(_, additionalSkipText)
        -- upvalues: (copy) text
        local x, y = g_currentMission.hud.sideNotifications:getHelpAnchorPosition()
        IntroductionHelpHUDUtil.drawHelp(x, y, text, IntroductionHelpHUDUtil.ARROW_POSITION_RIGHT)
        IntroductionHelpHUDUtil.drawSkipMessage(additionalSkipText)
    end
    g_currentMission.introductionHelpSystem:registerHelp("guidedTour_intro_helpProgress", helpData, helpData.draw, nil)
end
function GuidedTourHelp.registerHelpFillLevels()
    local helpData = {}
    local text = g_i18n:getText("introduction_tourFillLevelSeedType")
    function helpData.draw(_, additionalSkipText)
        -- upvalues: (copy) text
        local x, y = g_currentMission.hud.fillLevelsDisplay:getHelpAnchorPosition()
        IntroductionHelpHUDUtil.drawHelp(x, y, text, IntroductionHelpHUDUtil.ARROW_POSITION_RIGHT)
        IntroductionHelpHUDUtil.drawSkipMessage(additionalSkipText)
    end
    g_currentMission.introductionHelpSystem:registerHelp("guidedTour_intro_helpFillLevelsSeedType", helpData, helpData.draw, nil)
end
function GuidedTourHelp.registerHelpVehicleSelection()
    local helpData = {}
    local text = g_i18n:getText("introduction_tourVehicleSelection")
    function helpData.draw(_, additionalSkipText)
        -- upvalues: (copy) text
        local x, y = g_currentMission.hud.inputHelp:getHelpAnchorPosition()
        IntroductionHelpHUDUtil.drawHelp(x, y, text, IntroductionHelpHUDUtil.ARROW_POSITION_LEFT)
        IntroductionHelpHUDUtil.drawSkipMessage(additionalSkipText)
    end
    g_currentMission.introductionHelpSystem:registerHelp("guidedTour_intro_helpVehicleSelection", helpData, helpData.draw, nil)
end
function GuidedTourHelp.registerHelpCalendar()
    local helpData = {}
    local text = g_i18n:getText("introduction_monthInfo")
    function helpData.draw(_, additionalSkipText)
        -- upvalues: (copy) text
        local x, y = g_currentMission.hud.gameInfoDisplay:getHelpAnchorPosition(GameInfoDisplay.HELP_ANCHOR_CALENDAR)
        IntroductionHelpHUDUtil.drawHelp(x, y, text, IntroductionHelpHUDUtil.ARROW_POSITION_TOP)
        IntroductionHelpHUDUtil.drawSkipMessage(additionalSkipText)
    end
    g_currentMission.introductionHelpSystem:registerHelp("guidedTour_intro_helpCalendar", helpData, helpData.draw, nil)
end
function GuidedTourHelp.registerHelpTime()
    local helpData = {}
    local text = g_i18n:getText("introduction_timeInfo")
    function helpData.draw(_, additionalSkipText)
        -- upvalues: (copy) text
        local x, y = g_currentMission.hud.gameInfoDisplay:getHelpAnchorPosition(GameInfoDisplay.HELP_ANCHOR_CLOCK)
        IntroductionHelpHUDUtil.drawHelp(x, y, text, IntroductionHelpHUDUtil.ARROW_POSITION_TOP)
        IntroductionHelpHUDUtil.drawSkipMessage(additionalSkipText)
    end
    g_currentMission.introductionHelpSystem:registerHelp("guidedTour_intro_helpTime", helpData, helpData.draw, nil)
end
function GuidedTourHelp.registerHelpWeather()
    local helpData = {}
    local text = g_i18n:getText("introduction_weather")
    function helpData.draw(_, additionalSkipText)
        -- upvalues: (copy) text
        local x, y = g_currentMission.hud.gameInfoDisplay:getHelpAnchorPosition(GameInfoDisplay.HELP_ANCHOR_WEATHER)
        IntroductionHelpHUDUtil.drawHelp(x, y, text, IntroductionHelpHUDUtil.ARROW_POSITION_TOP)
        IntroductionHelpHUDUtil.drawSkipMessage(additionalSkipText)
    end
    g_currentMission.introductionHelpSystem:registerHelp("guidedTour_intro_helpWeather", helpData, helpData.draw, nil)
end
function GuidedTourHelp.registerHelpBalance()
    local helpData = {}
    local text = g_i18n:getText("introduction_balance")
    function helpData.draw(_, additionalSkipText)
        -- upvalues: (copy) text
        local x, y = g_currentMission.hud.gameInfoDisplay:getHelpAnchorPosition(GameInfoDisplay.HELP_ANCHOR_MONEY)
        IntroductionHelpHUDUtil.drawHelp(x, y, text, IntroductionHelpHUDUtil.ARROW_POSITION_TOP)
        IntroductionHelpHUDUtil.drawSkipMessage(additionalSkipText)
    end
    g_currentMission.introductionHelpSystem:registerHelp("guidedTour_intro_helpBalance", helpData, helpData.draw, nil)
end
function GuidedTourHelp.registerHelpMiniMap()
    local helpData = {}
    local text = g_i18n:getText("introduction_openMinimap")
    function helpData.draw(_, additionalSkipText)
        -- upvalues: (copy) text
        local x, y = g_currentMission.hud.ingameMap:getHelpAnchorPosition()
        IntroductionHelpHUDUtil.drawHelp(x, y, text, IntroductionHelpHUDUtil.ARROW_POSITION_BOTTOM)
        IntroductionHelpHUDUtil.drawSkipMessage(additionalSkipText)
    end
    g_currentMission.introductionHelpSystem:registerHelp("guidedTour_intro_helpMiniMap", helpData, helpData.draw, nil)
end