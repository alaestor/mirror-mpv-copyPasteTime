local function run(properties, binding, dispatch_ok)
    local state = { commands = {}, messages = {}, bindings = {}, callbacks = {}, timers = {} }
    local mp = {
        get_property_number = function(name) return properties[name] end,
        commandv = function(...)
            state.commands[#state.commands + 1] = { ... }
            return dispatch_ok ~= false
        end,
        osd_message = function(message) state.messages[#state.messages + 1] = message end,
        add_key_binding = function(_, name, callback) state.bindings[name] = callback end,
        register_script_message = function(name, callback) state.callbacks[name] = callback end,
        add_timeout = function(_, callback)
            local timer = { callback = callback, killed = false }
            function timer:kill() self.killed = true end
            state.timers[#state.timers + 1] = timer
            return timer
        end,
    }
    _G.mp = mp
    package.loaded.mp = mp
    assert(loadfile("copyPasteTime.lua"))()
    if binding then state.bindings[binding]() end
    return state
end

local function equal(actual, expected)
    assert(actual == expected, string.format("expected %q, got %q", tostring(expected), tostring(actual)))
end

for _, case in ipairs({
    { 0.9994, "00:00:00.999" },
    { 0.9996, "00:00:01.000" },
    { 59.9996, "00:01:00.000" },
    { 3599.9996, "01:00:00.000" },
}) do
    local state = run({ ["time-pos"] = case[1] }, "copyTime")
    equal(state.commands[1][4], case[2])
end

for _, case in ipairs({
    { binding = "copyTime", property = "time-pos", value = 1.125, result = "00:00:01.125", unavailable = "Current time is unavailable." },
    { binding = "copyFrame", property = "estimated-frame-number", value = 42, result = "42", unavailable = "Estimated frame number is unavailable." },
}) do
    local missing = run({}, case.binding)
    equal(#missing.commands, 0)
    equal(missing.messages[1], case.unavailable)

    local available = run({ [case.property] = case.value }, case.binding)
    equal(#available.commands, 1)
    equal(available.commands[1][1], "script-message-to")
    equal(available.commands[1][2], "clipboard")
    equal(available.commands[1][3], "set-clipboard")
    equal(available.commands[1][4], case.result)
end

local copy = run({ ["time-pos"] = 1 }, "copyTime")
equal(copy.messages[1], "Clipboard copy requested: 00:00:01.000")
local failed_copy = run({ ["time-pos"] = 1 }, "copyTime", false)
assert(failed_copy.messages[1]:find("Failed to copy", 1, true))

local paste = run({}, "pasteTime")
equal(paste.commands[1][1], "script-message-to")
equal(paste.commands[1][2], "clipboard")
equal(paste.commands[1][3], "get-clipboard")
paste.timers[1].callback()
assert(paste.messages[1]:find("no response", 1, true))

local responded = run({}, "pasteTime")
responded.callbacks._pasteTime_impl("12.5")
equal(responded.timers[1].killed, true)
equal(responded.commands[2][3], "12.5")

local repeated = run({}, "pasteTime")
repeated.bindings.pasteTime()
equal(repeated.timers[1].killed, true)
equal(repeated.timers[2].killed, false)

local failed_paste = run({}, "pasteTime", false)
equal(failed_paste.timers[1].killed, true)
assert(failed_paste.messages[1]:find("Failed to read clipboard", 1, true))

for _, text in ipairs({ "01:02:03.004", "02:03", "5", "5.125", "99:59:59.999", "100:00:00.000", "123:45:06.789", "123:45", "1:2:3" }) do
    local state = run({})
    state.callbacks._pasteTime_impl(text)
    equal(state.commands[1][3], text)
end

for _, text in ipairs({ "", "not a timestamp", "100:00:00:00", "12.3.4", "Episode 2 at 00:12", "-12", "1:234:56" }) do
    local state = run({})
    state.callbacks._pasteTime_impl(text)
    equal(#state.commands, 0)
end

local whitespace = run({})
whitespace.callbacks._pasteTime_impl(" \n100:00:00.000\t")
equal(whitespace.commands[1][3], "100:00:00.000")

local failed_seek = run({}, nil, false)
failed_seek.callbacks._pasteTime_impl("12.5")
assert(failed_seek.messages[1]:find("Failed to seek", 1, true))
