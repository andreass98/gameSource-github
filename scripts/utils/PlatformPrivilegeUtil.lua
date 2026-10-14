PlatformPrivilegeUtil = {}
function PlatformPrivilegeUtil.checkModDownload(callback, callbackTarget)
    if getNetworkError() then
        ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
        return false
    end
    local availability, showsNativeGUI = getModDownloadAvailability()
    if availability == MultiplayerAvailability.AVAILABLE then
        return true
    end
    if availability == MultiplayerAvailability.AVAILABILITY_UNKNOWN then
        local text = g_i18n:getText("ui_connectingPleaseWait")
        ConnectionPendingDialog.show(PlatformPrivilegeUtil.checkModDownloadUpdateCallback, nil, text, nil, nil, {
            ["showsNativeGUI"] = showsNativeGUI,
            ["callback"] = callback,
            ["callbackTarget"] = callbackTarget
        })
    elseif not showsNativeGUI then
        InfoDialog.show(g_i18n:getText("ui_missingUGCdownloadPrivilege"))
    end
    return false
end
function PlatformPrivilegeUtil.checkModDownloadUpdateCallback(_, args)
    if getNetworkError() then
        ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
    else
        local availability, showsNativeGUI = getModDownloadAvailability()
        args.showsNativeGUI = args.showsNativeGUI or showsNativeGUI
        if availability ~= MultiplayerAvailability.AVAILABILITY_UNKNOWN then
            ConnectionPendingDialog.hide()
            if availability == MultiplayerAvailability.AVAILABLE then
                if args.callback ~= nil then
                    if args.callbackTarget == nil then
                        args.callback()
                    else
                        args.callback(args.callbackTarget)
                    end
                end
            elseif not args.showsNativeGUI then
                InfoDialog.show(g_i18n:getText("ui_missingUGCdownloadPrivilege"))
            end
        end
    end
end
function PlatformPrivilegeUtil.checkModUse(callback, callbackTarget)
    local availability, showsNativeGUI = getModUseAvailability(true)
    if availability == MultiplayerAvailability.AVAILABLE then
        return true
    end
    if availability == MultiplayerAvailability.AVAILABILITY_UNKNOWN then
        local text = g_i18n:getText("ui_connectingPleaseWait")
        ConnectionPendingDialog.show(PlatformPrivilegeUtil.checkModUseUpdateCallback, nil, text, nil, nil, {
            ["showsNativeGUI"] = showsNativeGUI,
            ["callback"] = callback,
            ["callbackTarget"] = callbackTarget
        })
    elseif not showsNativeGUI then
        InfoDialog.show(g_i18n:getText("ui_missingUGCdownloadPrivilege"))
    end
    return false
end
function PlatformPrivilegeUtil.checkModUseUpdateCallback(_, args)
    local availability, showsNativeGUI = getModUseAvailability(true)
    args.showsNativeGUI = args.showsNativeGUI or showsNativeGUI
    if availability ~= MultiplayerAvailability.AVAILABILITY_UNKNOWN then
        ConnectionPendingDialog.hide()
        if availability == MultiplayerAvailability.AVAILABLE then
            if args.callback ~= nil then
                if args.callbackTarget == nil then
                    args.callback()
                else
                    args.callback(args.callbackTarget)
                end
            end
        elseif not args.showsNativeGUI then
            InfoDialog.show(g_i18n:getText("ui_missingUGCdownloadPrivilege"))
        end
    end
end
function PlatformPrivilegeUtil.checkMultiplayer(callback, callbackTarget, callbackArgs, networkTimeout)
    local availability, showsNativeGUI = getMultiplayerAvailability()
    if getNetworkError() then
        if networkTimeout == nil then
            ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
        else
            local text = g_i18n:getText("ui_connectingPleaseWait")
            ConnectionPendingDialog.show(PlatformPrivilegeUtil.checkMultiplayerUpdateCallback, nil, text, nil, nil, {
                ["showsNativeGUI"] = showsNativeGUI,
                ["callback"] = callback,
                ["callbackTarget"] = callbackTarget,
                ["callbackArgs"] = callbackArgs,
                ["networkTimeout"] = networkTimeout
            })
        end
        return false
    end
    if availability == MultiplayerAvailability.AVAILABLE then
        return true
    end
    if availability == MultiplayerAvailability.AVAILABILITY_UNKNOWN then
        local text = g_i18n:getText("ui_connectingPleaseWait")
        ConnectionPendingDialog.show(PlatformPrivilegeUtil.checkMultiplayerUpdateCallback, nil, text, nil, nil, {
            ["showsNativeGUI"] = showsNativeGUI,
            ["callback"] = callback,
            ["callbackTarget"] = callbackTarget,
            ["callbackArgs"] = callbackArgs,
            ["networkTimeout"] = networkTimeout
        })
    elseif not showsNativeGUI and GS_PLATFORM_XBOX then
        if availability == MultiplayerAvailability.NOT_AVAILABLE then
            InfoDialog.show(g_i18n:getText("ui_missingGoldForMultiplayer_xbox"))
        elseif availability == MultiplayerAvailability.NO_PRIVILEGES then
            InfoDialog.show(g_i18n:getText("ui_missingPrivilegeMultiplayerSession_xbox"))
        end
    end
    return false
end
function PlatformPrivilegeUtil.checkMultiplayerUpdateCallback(dt, args)
    if args.networkTimeout ~= nil then
        args.networkTimeout = args.networkTimeout - dt
        if args.networkTimeout <= 0 then
            args.networkTimeout = nil
        end
    end
    if getNetworkError() then
        if args.networkTimeout == nil then
            ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
        end
    else
        local availability, showsNativeGUI = getMultiplayerAvailability()
        args.showsNativeGUI = args.showsNativeGUI or showsNativeGUI
        if availability ~= MultiplayerAvailability.AVAILABILITY_UNKNOWN then
            ConnectionPendingDialog.hide()
            if availability == MultiplayerAvailability.AVAILABLE then
                if args.callback ~= nil then
                    if args.callbackTarget == nil then
                        args.callback(args.callbackArgs)
                    else
                        args.callback(args.callbackTarget, args.callbackArgs)
                    end
                end
            elseif not args.showsNativeGUI and GS_PLATFORM_XBOX then
                if availability == MultiplayerAvailability.NOT_AVAILABLE then
                    InfoDialog.show(g_i18n:getText("ui_missingGoldForMultiplayer_xbox"))
                    return
                end
                if availability == MultiplayerAvailability.NO_PRIVILEGES then
                    InfoDialog.show(g_i18n:getText("ui_missingPrivilegeMultiplayerSession_xbox"))
                end
            end
        end
    end
end
function PlatformPrivilegeUtil.getCanInvitePlayer(misson)
    return GS_IS_CONSOLE_VERSION
end