-- Clipboard protocol double. It never accesses the system clipboard.
mp.register_script_message("set-clipboard", function(text)
    mp.commandv("script-message-to", "scenarios", "clipboard-write", text)
end)
mp.register_script_message("get-clipboard", function(callback)
    mp.commandv("script-message-to", "scenarios", "clipboard-read")
    mp.commandv("script-message", callback, "00:00:12.500")
end)
