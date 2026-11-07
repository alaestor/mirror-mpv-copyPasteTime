# mpv-copyPasteTime

A fork of [mpv-copyTime](https://github.com/Arieleg/mpv-copyTime) with a few bugfixes from unmerged PRs and a couple new features.

Features:

- Copy the current time (formatted as `HH:MM:SS.sss`) or estimated frame number to clipboard.

- Read a time from your clipboard to seek to it. Same format as above but the hours, minutes, and miliseconds are optional (e.g. `HH:MM:SS`, `MM:SS`, `SS`, `S.s`, etc.)

Note: **Seeking to an estimated frame number is not supported. Only timecodes.** *Copying estimated frame numbers is most useful for working with other tools (like the handbrake GUI which truncates miliseconds: frame number can be useful to differentiate keyframes). Times with miliseconds should provide adequate resolution, as it's typically frame-perfect.*

# Screenshot
![ss1](https://user-images.githubusercontent.com/40000640/111867156-02f68a00-8951-11eb-84a8-c78616c68aa3.PNG)

# Installation

## 1. Install dependencies

This script requires [mpv-clipboard](https://github.com/CogentRedTester/mpv-clipboard) be installed.

Windows users may prefer [dyphire's fork](https://github.com/dyphire/mpv-clipboard) as it appears to have some improvements.

## 2. Install the script

Put `copyPasteTime.lua` in your scripts folder, usually in:
*  Windows: `"%APPDATA%\mpv\scripts"`.
*  Linux and Mac: `"~/.config/mpv/scripts/"`.

## 3. Configure Your Keybinds

There are two ways to do this.

Either...

1. Modify the lines at the bottom of the script by changing `nil` to your desired keybinds. e.g.
```
mp.add_key_binding("shift+c", "copyFrame", copyFrame)
mp.add_key_binding("ctrl+c", "copyTime", copyTime)
mp.add_key_binding("ctrl+v", "pasteTime", pasteTime)
```

or

2. Add your preferred keybinds to your `input.conf` file. e.g.
```
shift+c script-message-to copyPasteTime copyFrame
ctrl+c script-message-to copyPasteTime copyTime
ctrl+v script-message-to copyPasteTime pasteTime
```

Note: these example keybinds may conflict with your existing keybinds or [MPV's defaults](https://github.com/mpv-player/mpv/blob/master/etc/input.conf).

