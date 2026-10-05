# T-Minus — meeting launch control

A macOS menu-bar app that makes sure you never miss a Google Meet. Shortly before each
meeting, it takes over your screen with an animated "INCOMING TRANSMISSION" alert:
falling glyphs, a glitching title, a decrypting meeting name, a countdown ring, and a
fake terminal handshake log. Press Enter and you're in the meeting.

- Works with Google Meet, plus Zoom and Microsoft Teams links
- Lives in the menu bar with a live countdown to your next meeting
- Four themes, optional sound and voice announcement
- Reads your calendar locally. No Google login, no servers, no tracking

---

## Contents

1. [Prerequisites](#prerequisites)
2. [Install](#install)
3. [Connect your Google Calendar](#connect-your-google-calendar)
4. [How to use](#how-to-use)
5. [Settings](#settings)
6. [Troubleshooting](#troubleshooting)
7. [Update or uninstall](#update-or-uninstall)
8. [Privacy](#privacy)
9. [Build from source](#build-from-source)

---

## Prerequisites

| Requirement | Details |
|---|---|
| macOS | 14 (Sonoma) or later. Check under  → About This Mac. |
| Mac | Apple Silicon (M1–M4) or Intel. Both are supported. |
| Calendar | Your Google Calendar synced into the macOS **Calendar** app (see below). |
| Permission | Calendar access for T-Minus (macOS asks on first launch). |

Work-managed Macs: some company security tools block apps that aren't signed by an
identified developer. If "Open Anyway" doesn't appear in step 3 below, ask your IT team to
allow the app.

---

## Install

1. Go to the [Releases page](../../releases/latest) and download **T-Minus.zip**.
2. Unzip it (double-click the zip) and drag **T-Minus.app** into your **Applications** folder.
3. Double-click **T-Minus.app**. The first time, macOS will block it with a message that it
   "can't be opened" or is from an unidentified developer. This is expected, because the app
   isn't notarized by Apple. To allow it:
   - Open **System Settings → Privacy & Security**.
   - Scroll down to the message about T-Minus and click **Open Anyway**, then confirm.

   Or, in Terminal:
   ```
   xattr -dr com.apple.quarantine /Applications/T-Minus.app
   ```
4. When asked, click **Allow** for Calendar access.
5. Look at the top-right of your screen. T-Minus shows up in the **menu bar** (for example,
   `◎ T-∞`). It has no Dock icon and no window.

---

## Connect your Google Calendar

T-Minus reads events from the macOS Calendar app. If your Google meetings already show up
in Calendar, you're done. Otherwise:

1. Open **System Settings → Internet Accounts**.
2. Click **Add Account → Google** and sign in.
3. Make sure **Calendars** is turned on for that account.
4. Open the **Calendar** app and check that your meetings appear.

T-Minus finds the meeting link in each event's URL, location, or description. Events
created with "Add Google Meet video conferencing" include the link automatically.

---

## How to use

### The menu bar

| What you see | Meaning |
|---|---|
| `◎ T-∞` | No video meetings in the next hour |
| `◉ 12m · Standup` | Next meeting and minutes until it starts |
| `◉ 0:42 · Standup` (blinking) | Less than a minute to go |
| `● LIVE · Standup` | A meeting is in progress |

Click it to open the menu. Upcoming meetings are listed with their start time, and clicking
one opens its meeting link.

### The alert

By default the alert appears **2 minutes before** each meeting. It covers the screen your
mouse is on and shows:

- the meeting title, time, calendar, and number of attendees
- a countdown ring (it flashes **LIVE +mm:ss** once the meeting has started)
- a terminal log with a few random jokes

| Key | Button | Action |
|---|---|---|
| **⏎ Enter** | JOIN | Opens the meeting link in your browser and closes the alert |
| **S** | SNOOZE 1M | Hides the alert and shows it again in 1 minute |
| **Esc** | DISMISS | Closes the alert. You won't be reminded about this meeting again |

If a meeting has no video link, the JOIN button reads **ACKNOWLEDGE** and just closes the
alert.

### Try it now

Open the menu and choose **⚡ Fire test alert** (or press ⌘T while the menu is open). It
shows a fake meeting so you can see the alert without waiting.

---

## Settings

All settings are in the menu-bar menu and are remembered between launches.

| Setting | Default | What it does |
|---|---|---|
| Alert lead time | 2 min | How early the alert appears: 1, 2, 3, 5, or 10 minutes |
| Theme | Matrix | Matrix (green), Synthwave (pink/cyan), Amber CRT (hex), ICE (binary blue) |
| Sound | On | Plays a sound when the alert appears |
| Voice announcement | Off | Speaks "Incoming transmission. *Meeting* launches in 2 minutes." |
| Only meetings with video links | On | Skips events without a Meet/Zoom/Teams link (lunch, focus time, etc.) |
| Launch at login | Off | Starts T-Minus automatically when you log in |
| Refresh calendars (⌘R) | — | Re-reads your calendar immediately (it also refreshes every minute and on calendar changes) |

T-Minus skips all-day events, cancelled events, and meetings you've declined.

---

## Troubleshooting

**I can't find T-Minus in the menu bar.**
On MacBooks with a notch, menu-bar items can hide behind it when the bar is full. Quit a few
other menu-bar apps, or hold **⌘** and drag icons to rearrange them. To check it's running,
open Activity Monitor and search for "TMinus".

**The menu says "Calendar access denied".**
Click that item, or go to **System Settings → Privacy & Security → Calendars**, and turn on
T-Minus. Then quit and reopen the app.

**My meetings don't show up.**
- Check that they appear in the macOS Calendar app first.
- If a meeting has no Meet/Zoom/Teams link, it's hidden while
  "Only meetings with video links" is on. Turn that off to see all events.
- Choose **Refresh calendars** from the menu.

**macOS says the app is damaged or can't be opened.**
Run `xattr -dr com.apple.quarantine /Applications/T-Minus.app` in Terminal, then open it again.

**The alert didn't appear for a meeting.**
Alerts fire within the lead time and up to 5 minutes after the start. If T-Minus wasn't
running then, or you dismissed the alert earlier, it won't show again. Turn on
**Launch at login** so it's always running.

**Launch at login doesn't stick.**
Make sure the app is in your Applications folder, not running from Downloads or the zip.

---

## Update or uninstall

**Update:** download the new **T-Minus.zip** from Releases, quit T-Minus (menu → Quit),
and replace the app in Applications. Your settings are kept.

**Uninstall:**
1. Turn off **Launch at login** in the menu, then choose **Quit T-Minus**.
2. Delete **T-Minus.app** from Applications.
3. Optional, to remove saved settings:
   ```
   defaults delete com.stangudu.tminus
   ```

---

## Privacy

T-Minus reads your calendar on your Mac through Apple's EventKit. It doesn't
connect to Google, doesn't send data anywhere, and doesn't collect analytics. The only
network activity is your browser opening a meeting link when you press JOIN.

---

## Build from source

Requires macOS 14+ and Apple's command-line tools:

```
xcode-select --install     # one-time
git clone https://github.com/Sravankumartangudu/t-minus.git
cd t-minus
./build.sh --install
```

| Command | Result |
|---|---|
| `./build.sh` | Builds `build/T-Minus.app` (universal: arm64 + x86_64) |
| `./build.sh --install` | Builds, copies to `~/Applications`, and launches it |
| `./build.sh --dist` | Builds and creates `build/T-Minus.zip` for sharing |
| `open build/T-Minus.app --args --demo` | Launches and immediately shows a test alert |

### Project layout

```
Sources/
  main.swift             app entry point
  AppDelegate.swift      menu bar, scheduling, settings
  CalendarService.swift  reads events and finds meeting links
  AlertOverlay.swift     full-screen alert window and layout
  Effects.swift          glyph rain, glitch text, countdown ring, terminal log
  Theme.swift            color themes and glyph sets
Info.plist               app metadata and calendar permission text
build.sh                 build, install, and packaging script
```
