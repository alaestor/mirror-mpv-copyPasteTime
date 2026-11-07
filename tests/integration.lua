-- Run alongside copyPasteTime.lua in a paused mpv with the long WAV loaded.
local function fail(message)
    mp.msg.error(message)
    mp.commandv("quit", "1")
end

mp.register_event("file-loaded", function()
    local ok = mp.commandv("script-message-to", "copyPasteTime", "_pasteTime_impl", "100:00:00.000")
    if not ok then return fail("could not dispatch timestamp") end
    mp.add_timeout(1, function()
        local position = mp.get_property_number("time-pos")
        if not position or math.abs(position - 360000) > 0.1 then
            return fail("expected 360000 seconds, got " .. tostring(position))
        end
        mp.commandv("quit", "0")
    end)
end)
mp.add_timeout(10, function() fail("integration test timed out") end)
