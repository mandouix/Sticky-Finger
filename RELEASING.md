# How to Release a New Version of Sticky Finger

Sticky Finger is distributed as a manual download. There is no in-app
auto-update — users download each new version and replace the app
themselves. Follow these steps to ship an update.

---

## Every Time You Release

### Step 1 — Open Terminal and go to the project folder

Open Terminal (press Cmd+Space, type Terminal, press Enter).

Type this and press Enter:
```
cd ~/Documents/Projects/Sticky\ Fingers
```

---

### Step 2 — Run the release script

Type this, replacing `1.0.3` with your new version number:
```
./release.sh 1.0.3
```

It will automatically:
- Update the version number in the app
- Build a Release version of the app
- Zip it into `StickyFinger.zip`
- Print the version, build number, and file size

The zip is created at:
```
~/Documents/Projects/Sticky Fingers/build-release/Release/StickyFinger.zip
```

---

### Step 3 — Upload the zip to GitHub Releases

1. Go to `https://github.com/mandouix/Sticky-Finger/releases`
2. Click **Draft a new release**
3. In the **Tag version** field, type: `v1.0.3` (use your version number)
4. In the **Release title** field, type: `Sticky Finger 1.0.3`
5. Write a short description of what changed
6. Click **Attach binaries by dropping them here** and upload `StickyFinger.zip`
7. Click **Publish release**

---

### Step 4 — Commit the version bump

Back in Terminal:
```
git add "Sticky Fingers/Info.plist"
git commit -m "Release v1.0.3"
git push
```

---

### Step 5 — Tell your users

Point users at the latest release page so they can download the new
version. To update, they quit Sticky Finger, drag the new app into
`/Applications` (replacing the old one), and reopen it.

---

## Note on Auto-Updates

Auto-update (Sparkle) was removed. It requires an Apple Developer ID
signing certificate to work — without one, every build has a different
ad-hoc code signature and Sparkle rejects the update as "improperly
signed." If you later obtain a Developer ID certificate and want to
re-add auto-updates, the app would need to be signed (and notarized)
at release time before Sparkle could be reintroduced.
