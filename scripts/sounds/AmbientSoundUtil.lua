AmbientSoundUtil = {}
function AmbientSoundUtil.onCreateSoundNode(_, id)
    Logging.warning("AmbientSoundUtil.onCreateSoundNode does not exist anymore. Use AudioSource and Visibility Conditions instead!")
end
function AmbientSoundUtil.onCreateMovingSound(_, id)
    g_currentMission.ambientSoundSystem:addMovingSound(id)
end