require 'mp'

local function setClipboard(text)
    if mp.commandv("script-message-to", "clipboard", "set-clipboard", text) then
        -- mpv-clipboard does not acknowledge operating-system write completion.
        mp.osd_message(string.format("Clipboard copy requested: %s", text))
    else
        mp.osd_message(string.format("Failed to copy '%s'.\nAre you missing `mpv-clipboard`?", text))
    end
end

local function copyTime()
    local time_pos = mp.get_property_number("time-pos")
    if time_pos == nil then
        mp.osd_message("Current time is unavailable.")
        return
    end
    local total_ms = math.floor(time_pos * 1000 + 0.5)
    local milliseconds = total_ms % 1000
    local seconds = math.floor(total_ms / 1000) % 60
    local minutes = math.floor(total_ms / 60000) % 60
    local hours = math.floor(total_ms / 3600000)
    local time = string.format("%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
    setClipboard(time)
end

local function copyFrame()
    local frame_number = mp.get_property_number("estimated-frame-number")
    if frame_number == nil then
        mp.osd_message("Estimated frame number is unavailable.")
        return
    end
    local frame_string = string.format("%d", frame_number)
    setClipboard(frame_string)
end

local clipboard_timer

local function _pasteTime_impl(text)
    if clipboard_timer then
        clipboard_timer:kill()
        clipboard_timer = nil
    end
    local timestamp = text:match("^%s*(.-)%s*$")
    local valid = timestamp:match("^%d+$")
        or timestamp:match("^%d+%.%d+$")
        or timestamp:match("^%d+:%d%d?$")
        or timestamp:match("^%d+:%d%d?%.%d+$")
        or timestamp:match("^%d+:%d%d?:%d%d?$")
        or timestamp:match("^%d+:%d%d?:%d%d?%.%d+$")
    if valid then
        if mp.commandv("osd-bar", "seek", timestamp, "absolute") then
            mp.osd_message("Timestamp pasted: " .. timestamp)
        else
            mp.osd_message("Failed to seek to timestamp: " .. timestamp)
        end
    end
end

local function pasteTime()
    if clipboard_timer then clipboard_timer:kill() end
    clipboard_timer = mp.add_timeout(3, function()
        clipboard_timer = nil
        mp.osd_message("Failed to read clipboard: no response from `mpv-clipboard`.")
    end)
    if not mp.commandv("script-message-to", "clipboard", "get-clipboard", "_pasteTime_impl") then
        clipboard_timer:kill()
        clipboard_timer = nil
        mp.osd_message("Failed to read clipboard.\nAre you missing `mpv-clipboard`?")
    end
end

mp.register_script_message("_pasteTime_impl", _pasteTime_impl)

mp.add_key_binding(nil, "copyFrame", copyFrame)
mp.add_key_binding(nil, "copyTime", copyTime)
mp.add_key_binding(nil, "pasteTime", pasteTime)
