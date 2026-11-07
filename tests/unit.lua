local function run(properties, binding)
    local state = { commands = {}, messages = {}, bindings = {} }
    local mp = {
        get_property_number = function(name) return properties[name] end,
        commandv = function(...)
            state.commands[#state.commands + 1] = { ... }
            return true
        end,
        osd_message = function(message) state.messages[#state.messages + 1] = message end,
        add_key_binding = function(_, name, callback) state.bindings[name] = callback end,
        register_script_message = function() end,
    }
    _G.mp = mp
    package.loaded.mp = mp
    assert(loadfile("copyPasteTime.lua"))()
    state.bindings[binding]()
    return state
end

local function equal(actual, expected)
    assert(actual == expected, string.format("expected %q, got %q", tostring(expected), tostring(actual)))
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
    equal(available.commands[1][1], "script-message")
    equal(available.commands[1][2], "set-clipboard")
    equal(available.commands[1][3], case.result)
end
