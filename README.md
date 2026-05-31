# Sticky Finger

A lightweight sticky-notes app for macOS that lives in your menu bar. Jot
down anything in a floating note that stays out of your way, formats text
beautifully, and is always one keystroke away.

---

## What it does

Sticky Finger gives you instant, frictionless notes:

- **Menu-bar app** — no Dock icon, no main window. It sits quietly in your
  menu bar until you need it.
- **Floating notes** — each note is its own translucent ("Liquid Glass")
  window that can hover above other apps and follow you across every Space.
- **Rich text editing** — a full formatting toolbar with **bold**, *italic*,
  underline, strikethrough, three heading levels, bullet / numbered / task
  lists, inline code, code blocks, and blockquotes.
- **Color themes** — tint any note one of eight colors (yellow, orange, rose,
  purple, blue, teal, graphite, or the default).
- **Pin on top** — keep an important note always above your other windows.
- **All Notes overview** — a searchable panel listing every note so you can
  jump to the one you want.
- **Automatic saving** — notes are saved as you type and restored the next
  time you launch the app.

---

## How it works

Sticky Finger is a native macOS app built with **Swift**, **SwiftUI**, and
**AppKit**, with rich text powered by the [Tiptap](https://tiptap.dev) editor
running inside a `WKWebView`.

A few key pieces:

- **`AppDelegate`** — sets up the menu-bar (status) item and global keyboard
  shortcuts, and re-opens all your saved notes on launch.
- **`NoteStore`** — the single source of truth for your notes. It saves them
  to a JSON file using debounced, atomic writes (so a crash mid-save can't
  corrupt your data):
  ```
  ~/Library/Application Support/Sticky Finger/notes.json
  ```
  (Notes from older versions, which used a "New Sticky" folder, are migrated
  automatically.)
- **`WindowManager`** — creates and tracks one floating note window per note.
- **`TiptapEditor` / `EditorBridge`** — host the web-based editor and shuttle
  content and formatting commands between Swift and JavaScript.

All your data stays on your Mac. Nothing is sent anywhere.

---

## How to use it

### Install

1. Download `StickyFinger.zip` from the
   [Releases page](https://github.com/mandouix/Sticky-Finger/releases).
2. Unzip it and drag **Sticky Finger.app** into your **Applications** folder.
3. Open it. A document icon appears in your menu bar — there is no Dock icon
   or window, that's expected.

### Everyday use

- Click the menu-bar icon and choose **New Note**, or press **⌘N** from
  anywhere.
- Start typing. Use the formatting toolbar at the bottom of a note to style
  text, or change the note's color with the color picker.
- Drag a note anywhere on screen; it remembers where you left it.
- Open **All Notes** from the menu (or press **⌘F**) to search across every
  note and jump to one.
- Use **Send Feedback…** in the menu to email the developer.

### Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| **⌘N** | Create a new note |
| **⌘F** | Open the All Notes search panel |
| **⌘P** | Pin / unpin the focused note (keep it always on top) |
| **⌘Q** | Close the focused note window |

Quit the app entirely from the menu-bar icon → **Quit Sticky Finger**.

---

## Building from source

**Requirements:** macOS 26 or later and a matching version of Xcode.

1. Clone the repository.
2. Open `Sticky Finger.xcodeproj` in Xcode.
3. Select the **Sticky Finger** scheme and press **Run** (⌘R). The app it
   produces is **Sticky Finger.app**.

To produce a distributable build, run the release script with a version
number:

```
./release.sh 1.0.3
```

It bumps the version, builds a Release `.app`, and zips it to
`build-release/Release/StickyFinger.zip` ready to upload to GitHub Releases.
See [RELEASING.md](RELEASING.md) for the full release process.

---

## Distribution

Sticky Finger is distributed as a manual download via GitHub Releases — to
update, download the latest version and replace the app in your Applications
folder. (There is no in-app auto-update; see RELEASING.md for the rationale.)

---

## License

Copyright © 2026 Mandar Chaudhari. All rights reserved.
