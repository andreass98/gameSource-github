NightIllumination = {}
NightIllumination.deprecated = true
function NightIllumination.onCreate(_, id)
    Logging.warning("i3d onCreate user-attribute \'NightIllumination\' is deprecated. Please use \'Visibility Condition\'-Tab in GIANTS Editor for node \'%s\' instead", getNodeFullPath(id))
end