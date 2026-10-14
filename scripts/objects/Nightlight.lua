Nightlight = {}
function Nightlight.onCreate(_, id)
    Logging.warning("i3d onCreate user-attribute \'Nightlight\' is deprecated. Please use \'Visibility Condition\'-Tab in GIANTS Editor for node \'%s\' instead", getName(id))
end