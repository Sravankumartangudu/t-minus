# T-Minus — meeting launch control

A macOS menu-bar app that makes sure you never miss a Google Meet. Shortly before each
meeting, it shows an animated alert. There are three core styles plus six superhero styles:

- **Portal (default):** a glowing ring of light swirls open and throws off sparks, and a
  floating card flips out of it with a rolling countdown and attendee avatars. Joining ends
  with a confetti burst.
- **Full takeover:** an "INCOMING TRANSMISSION" screen with falling glyphs, a glitching
  title, a decrypting meeting name, a countdown ring, and a fake terminal handshake log.
- **Flyby:** a small pixel-art rocket tows a banner with the meeting details across your
  screen. Click anywhere to close it, or click the banner to join.
- **Superhero styles:** six alerts inspired by famous comic-book heroes, such as a card that
  swings in on a web, an armor HUD that locks onto your meeting, lightning that slams it
  down, and a searchlight in the night sky. There's also **Hero roulette**, which picks one
  at random each time. [See all of them](#superhero-styles).

Press Enter and you're in the meeting.

- Works with Google Meet, plus Zoom and Microsoft Teams links
- Lives in the menu bar with a live countdown to your next meeting
- Nine alert styles (plus Hero roulette), four themes, optional sound and voice announcement
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

By default the alert appears **2 minutes before** each meeting, on the screen your mouse
is on. Choose the style under **Alert style** in the menu.

### Style 1: Portal (default)

The screen dims, and a glowing ring of light swirls open in the middle, throwing off sparks.
A card flips out of the portal and floats gently. It shows:

- **STARTING IN** with a countdown whose digits roll as they change (it switches to a
  blinking **LIVE NOW** and counts up once the meeting starts)
- the meeting title, start and end time, calendar, and service (Google Meet, Zoom, Teams)
- avatar bubbles with attendees' initials, plus how many people are joining

| Action | Result |
|---|---|
| **Join now** button (or press ⏎) | Confetti bursts, the portal closes, and the meeting opens in your browser |
| **Snooze 1m** (or press S) | Closes the portal and opens it again in 1 minute |
| **Dismiss**, **click anywhere outside the card**, or press Esc | Closes the portal. You won't be reminded about this meeting again |

Clicking on the card itself (not a button) does nothing, so you can't close it by accident.

### Style 2: Full takeover

The whole screen switches to an animated "INCOMING TRANSMISSION" display showing:

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

### Style 3: Flyby

A lighter alert. The screen dims slightly, and a pixel-art rocket flies from left to right
towing a banner with:

- the meeting title and a live countdown (`T-01:58`, or `● LIVE +00:12` once it starts)
- the start and end time, the meeting service (Google Meet, Zoom, Teams), and the number of attendees

The rocket keeps making passes, each at a slightly different height, until you react.

| Action | Result |
|---|---|
| **Click the banner** (or press ⏎) | Joins the meeting and closes the alert |
| **Click anywhere else** (or press Esc) | Closes the alert. You won't be reminded about this meeting again |
| Press **S** | Hides the alert and shows it again in 1 minute |

While the Flyby is showing, it catches all clicks, so click once to close it before going
back to your work.

### Superhero styles

Choose one under **Alert style → Superhero styles**. All of them show the same meeting card
(rolling countdown, title, time, attendees, and **Join now** / **Snooze 1m** / **Dismiss**)
and use the same controls as Portal:

| Action | Result |
|---|---|
| **Join now** (or press ⏎) | Joins the meeting, with a hero-specific exit |
| **Snooze 1m** (or press S) | Hides the alert and shows it again in 1 minute |
| **Dismiss**, **click anywhere outside the card**, or press Esc | Closes the alert. You won't be reminded about this meeting again |

| Style | Inspired by | What happens |
|---|---|---|
| 🕸 **Web Slinger** | the wall-crawling web-slinger | Webs spin out from the screen corners and the card swings in on a web line like a pendulum (with a "THWIP!"). Joining zips it up and away; dismissing snaps the line and the card drops. |
| 🔴 **Arc Reactor** | the genius in the armored suit | An armor heads-up display boots up: holographic rings, a reticle that slides in and shows **TARGET LOCKED** on your meeting, and suit telemetry typing out on both sides. The card flickers in like a hologram. |
| ⚡ **Thunder God** | the hammer-wielding god of thunder | Storm clouds and rain roll in, a lightning bolt slams the card down with a screen shake and a shockwave, and lightning keeps striking while static crackles around the card's edges. Joining calls down one last bolt. |
| 🔦 **Night Signal** | the caped detective | The screen turns into a night skyline with lit windows. A searchlight sweeps up and projects your countdown onto the clouds, and the card rises out of the city. Dismissing switches the light off. |
| 💥 **Gamma Smash** | the big green rage monster | The card is hurled at your screen, the "glass" cracks, shards fly, and a comic **SMASH!** burst pops up. Joining punches the card through the screen. |
| 🛡 **Star Shield** | the star-spangled super-soldier | A spinning round shield ricochets off the screen edges with sparks, lands, and the card unfolds beneath it. Joining throws the shield off-screen. |
| 🎲 **Hero roulette** | all of the above | Picks a random superhero style for each alert. |

Superhero styles use their own hero colors, so the **Theme** setting doesn't affect them.

> These styles are fan homages. They use original artwork and generic names, contain no
> official logos or characters, and T-Minus isn't affiliated with or endorsed by any comic
> publisher or studio.

### Try it now

Open the menu and choose **⚡ Fire test alert** (or press ⌘T while the menu is open). It
shows a fake meeting in your current alert style, so you can see it without waiting.

---

## Settings

All settings are in the menu-bar menu and are remembered between launches.

| Setting | Default | What it does |
|---|---|---|
| Alert style | Portal | **Portal** (sparks + floating card), **Full takeover** (whole-screen transmission), **Flyby** (rocket tows a banner across), one of the six [superhero styles](#superhero-styles), or **Hero roulette** (random hero each time) |
| Alert lead time | 2 min | How early the alert appears: 1, 2, 3, 5, or 10 minutes |
| Theme | Matrix | Matrix (green), Synthwave (pink/cyan), Amber CRT (hex), ICE (binary blue). Applies to Portal, Full takeover, and Flyby (superhero styles use their own colors) |
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
| `open build/T-Minus.app --args --demo` | Launches and immediately shows a test alert (current style) |
| `open build/T-Minus.app --args --demo-portal` | Same, forcing a style: `--demo-portal`, `--demo-takeover`, `--demo-flyby`, `--demo-webslinger`, `--demo-arcreactor`, `--demo-thundergod`, `--demo-nightsignal`, `--demo-gammasmash`, `--demo-starshield`, `--demo-heroroulette` |

### Project layout

```
Sources/
  main.swift             app entry point
  AppDelegate.swift      menu bar, scheduling, settings
  CalendarService.swift  reads events and finds meeting links
  AlertOverlay.swift     alert window, alert styles, full-takeover layout
  Portal.swift           Portal style: swirling ring, sparks, confetti
  MeetingCard.swift      floating meeting card shared by Portal and the superhero styles
  HeroStage.swift        shared shell for superhero styles (timeline, click-outside, keys) + helpers
  WebSlinger.swift       🕸 corner webs, swinging card
  ArcReactor.swift       🔴 HUD rings, target-lock reticle, telemetry
  ThunderGod.swift       ⚡ storm clouds, rain, lightning, shockwave
  NightSignal.swift      🔦 skyline, searchlights, projected countdown
  GammaSmash.swift       💥 cracked glass, flying shards, SMASH! burst
  StarShield.swift       🛡 ricocheting shield, sparks
  Flyby.swift            Flyby style: pixel rocket, banner, exhaust, glyph trail
  Effects.swift          glyph rain, glitch text, countdown ring, terminal log
  Theme.swift            color themes and glyph sets
Info.plist               app metadata and calendar permission text
build.sh                 build, install, and packaging script
```
