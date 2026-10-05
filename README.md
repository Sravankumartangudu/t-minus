# T-Minus — meeting launch control

A macOS menu-bar app. When a meeting is close, it takes over your screen with an animated
"INCOMING TRANSMISSION" overlay: falling glyphs, a glitch title, a decrypting meeting name,
a countdown ring, and a fake terminal handshake log.

## Install (no coding needed)

Requires macOS 14 (Sonoma) or later. Works on Apple Silicon and Intel Macs.

1. Download **T-Minus.zip** from the [Releases page](../../releases/latest).
2. Unzip it and drag **T-Minus.app** into your Applications folder.
3. Double-click it. macOS will block it because the app isn't signed by an identified developer.
   Go to **System Settings → Privacy & Security**, scroll down, and click **Open Anyway**.
   (Or, in Terminal: `xattr -dr com.apple.quarantine /Applications/T-Minus.app`)
4. Allow Calendar access when asked. T-Minus appears in the menu bar, not the Dock.

## Build from source

Requires Apple's command-line tools (`xcode-select --install`).

    ./build.sh            # builds build/T-Minus.app (universal)
    ./build.sh --install  # copies it to ~/Applications and launches it
    ./build.sh --dist     # also creates build/T-Minus.zip for sharing

    open build/T-Minus.app --args --demo   # shows a test alert right after launch

## Calendar source

T-Minus reads events through macOS Calendar (EventKit), so it needs no Google OAuth.
To get your Google Calendar into macOS Calendar, add your Google account under
System Settings → Internet Accounts and turn on Calendars. Grant Calendar access the
first time T-Minus asks.

T-Minus looks for Google Meet links (and Zoom/Teams links) in each event's URL,
location, and notes. It skips all-day, cancelled, and declined events.

## Controls

| Key   | Action                         |
|-------|--------------------------------|
| ⏎     | Join (opens the meeting link)  |
| S     | Snooze for 1 minute            |
| Esc   | Dismiss                        |

Menu bar options: test alert (⌘T), lead time (1/2/3/5/10 min), theme
(Matrix / Synthwave / Amber CRT / ICE), sound, voice announcement,
only meetings with video links, launch at login.
