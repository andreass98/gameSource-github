VoiceChatUtil = {}
VoiceChatUtil.MODE = {
    ["DISABLED"] = 1,
    ["VOICE_ACTIVITY"] = 2,
    ["PUSH_TO_TALK"] = 3
}
function VoiceChatUtil.setOutputVolume(volume)
    voiceChatSetMasterVolume(volume)
end
function VoiceChatUtil.getOutputVolume()
    return voiceChatGetMasterVolume()
end
function VoiceChatUtil.setInputVolume(volume)
    voiceChatSetRecordingVolume(volume)
end
function VoiceChatUtil.getInputVolume()
    return voiceChatGetRecordingVolume()
end
function VoiceChatUtil.setInputMode(mode)
    if mode == VoiceChatUtil.MODE.DISABLED then
        voiceChatSetRecordingMode(VoiceChatRecordingMode.DISABLED)
        return
    elseif mode == VoiceChatUtil.MODE.VOICE_ACTIVITY then
        voiceChatSetRecordingMode(VoiceChatRecordingMode.AUTOMATIC)
    elseif mode == VoiceChatUtil.MODE.PUSH_TO_TALK then
        voiceChatSetRecordingMode(VoiceChatRecordingMode.MUTED)
    end
end
function VoiceChatUtil.getInputMode()
    if VoiceChatUtil.getIsVoiceRestricted() then
        return VoiceChatUtil.MODE.DISABLED
    else
        return g_gameSettings:getValue(SettingsModel.SETTING.VOICE_MODE)
    end
end
function VoiceChatUtil.setIsPushToTalkPressed(pressed)
    if g_currentMission ~= nil and (g_currentMission.missionDynamicInfo.isMultiplayer and VoiceChatUtil.getInputMode() == VoiceChatUtil.MODE.PUSH_TO_TALK) then
        if pressed then
            voiceChatSetRecordingMode(VoiceChatRecordingMode.ALWAYS)
            return
        end
        voiceChatSetRecordingMode(VoiceChatRecordingMode.MUTED)
    end
end
function VoiceChatUtil.setUserVolume(uuid, volume)
    voiceChatSetUserVolume(uuid, volume)
end
function VoiceChatUtil.getUserVolume(uuid)
    return voiceChatGetUserVolume(uuid)
end
function VoiceChatUtil.getIsSpeakerActive(uuid)
    return voiceChatGetConnectionStatus(uuid) == VoiceChatConnectionStatus.ACTIVE
end
function VoiceChatUtil.getHasRecordingDevice()
    return not Platform.hasRecordingDeviceDetection and true or voiceChatGetHasRecordingDevice()
end
function VoiceChatUtil.getIsVoiceRestricted()
    return not getAllowVoiceCommunication(false)
end
function VoiceChatUtil.showVoiceRestrictedPopup()
    getAllowVoiceCommunication(true)
end
function VoiceChatUtil.getInputSensitivity()
    local raw = voiceChatGetAutoActivationSensitivity()
    return raw < 0 and -1 or 1 - raw
end
function VoiceChatUtil.setInputSensitivity(value)
    voiceChatSetAutoActivationSensitivity(value)
end