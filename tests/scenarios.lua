local options = { mode = "normal" }
require("mp.options").read_options(options, "test")
local messages, writes, reads = {}, {}, 0
local osd = mp.osd_message
mp.osd_message = function(text, ...)
    messages[#messages + 1] = text
    return osd(text, ...)
end
assert(loadfile("copyPasteTime.lua"))()
mp.register_script_message("clipboard-write", function(text) writes[#writes + 1] = text end)
mp.register_script_message("clipboard-read", function() reads = reads + 1 end)

local function check(condition, message)
    if not condition then
        mp.msg.error("FAIL: " .. message)
        mp.commandv("quit", "1")
        return false
    end
    return true
end
local function has_message(fragment)
    for _, message in ipairs(messages) do
        if message:find(fragment, 1, true) then return true end
    end
    return false
end
local function send(binding)
    mp.commandv("script-message-to", mp.get_script_name(), binding)
end
local function later(fn) mp.add_timeout(0.4, fn) end
local function finish() mp.commandv("quit", "0") end

local function run()
    if options.mode == "normal" then
        send("copyTime")
        later(function()
            if not check(#writes == 1 and writes[1]:match("^%d+:%d%d:%d%d%.%d%d%d$"), "copy time reaches clipboard") then return end
            send("copyFrame")
            later(function()
                if not check(#writes == 2 and writes[2]:match("^%d+$"), "copy frame reaches clipboard") then return end
                send("pasteTime")
                later(function()
                    local position = mp.get_property_number("time-pos")
                    if not check(reads == 1 and position and math.abs(position - 12.5) < 0.1, "paste reads clipboard and seeks") then return end
                    finish()
                end)
            end)
        end)
    elseif options.mode == "input-config" then
        local found = {}
        for _, binding in ipairs(mp.get_property_native("input-bindings", {})) do
            if binding.cmd and binding.cmd:find("script-message-to copyPasteTime", 1, true) then
                found[binding.cmd] = true
            end
        end
        if not check(found["script-message-to copyPasteTime copyFrame"]
            and found["script-message-to copyPasteTime copyTime"]
            and found["script-message-to copyPasteTime pasteTime"], "README bindings must load from input.conf") then return end
        finish()
    elseif options.mode == "missing" then
        send("copyTime")
        send("pasteTime")
        mp.add_timeout(3.5, function()
            if not check(not has_message("Copied to Clipboard"), "copy must not claim completion") then return end
            if not check(has_message("Failed to read clipboard"), "missing clipboard must report failure") then return end
            finish()
        end)
    else
        local binding = options.mode == "idle-time" and "copyTime" or "copyFrame"
        local expected = binding == "copyTime" and "Current time is unavailable." or "Estimated frame number is unavailable."
        send(binding)
        later(function()
            if not check(has_message(expected), "unavailable property must be reported") then return end
            messages = {}
            send(binding)
            later(function()
                if not check(has_message(expected), "script must remain available") then return end
                if not check(#writes == 0, "unavailable property must not reach clipboard") then return end
                finish()
            end)
        end)
    end
end
if options.mode == "idle-time" or options.mode == "idle-frame" or options.mode == "input-config" then
    mp.add_timeout(0.5, run)
else
    mp.register_event("file-loaded", function() later(run) end)
end
mp.add_timeout(10, function() mp.msg.error("scenario timed out"); mp.commandv("quit", "2") end)
