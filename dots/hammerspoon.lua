local appName = "WezTerm"

hs.hotkey.bind({"alt"}, "space", function()
    local app = hs.application.get(appName)

    if app and app:isFrontmost() then
        app:hide()
        return
    end

    hs.application.launchOrFocus(appName)

    hs.timer.waitUntil(
        function()
            local a = hs.application.get(appName)
            return a and a:mainWindow() ~= nil
        end,
        function()
            local a = hs.application.get(appName)
            local win = a:mainWindow()
            win:setFrame(win:screen():frame())
            win:focus()
        end,
        0.05
    )
end)
