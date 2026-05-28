# How to Release a New Version of Sticky Fingers

Follow these steps every time you ship an update. You don't need to understand code — just follow the steps in order.

---

## Before You Start

Make sure you have done all of this already (one-time setup):
- Replaced `YOUR_GITHUB_USERNAME` with your actual GitHub username in:
  - `appcast.xml` (the `<link>` and all URLs inside `<item>`)
  - `Sticky Fingers/Info.plist` (the `SUFeedURL` value)
- Committed and pushed both files to GitHub
- Created a GitHub repository called `sticky-fingers`

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

Type this, replacing `1.0.1` with your new version number:
```
./release.sh 1.0.1
```

Wait for it to finish. It will automatically:
- Update the version number in the app
- Build a Release version of the app
- Zip it into `StickyFingers.zip`
- Sign the zip with your secret key
- Print the signature and file size

At the end you will see something like:
```
  Version:   1.0.1
  Build:     202605281200
  File size: 12345678
  Signature: abc123...xyz=
```

**Write down or copy the Signature and File size — you need them in Step 4.**

---

### Step 3 — Upload the zip to GitHub Releases

1. Open your browser and go to `https://github.com/YOUR_GITHUB_USERNAME/sticky-fingers/releases`
2. Click **Draft a new release**
3. In the **Tag version** field, type: `v1.0.1` (use your version number)
4. In the **Release title** field, type: `Sticky Fingers 1.0.1`
5. Write a short description of what changed
6. Click **Attach binaries by dropping them here** and upload `StickyFingers.zip`
   - It is in: `~/Documents/Projects/Sticky Fingers/build-release/Release/StickyFingers.zip`
7. Click **Publish release**

---

### Step 4 — Update appcast.xml

Open `appcast.xml` in the project folder (you can use TextEdit or any text editor).

Find the `<item>` section and update these four things:

1. **Title** — change `Version 1.0.0` to your new version
2. **pubDate** — change the date to today's date
3. **version numbers** — update both `<sparkle:version>` and `<sparkle:shortVersionString>`
4. **The enclosure block** — update the URL, signature, and length:

```xml
<enclosure
  url="https://github.com/YOUR_GITHUB_USERNAME/sticky-fingers/releases/download/v1.0.1/StickyFingers.zip"
  sparkle:edDSASignature="PASTE_THE_SIGNATURE_FROM_STEP_2_HERE"
  length="PASTE_THE_FILE_SIZE_FROM_STEP_2_HERE"
  type="application/octet-stream" />
```

Save the file.

---

### Step 5 — Push appcast.xml to GitHub

Back in Terminal, type these commands one by one and press Enter after each:

```
git add appcast.xml "Sticky Fingers/Info.plist"
git commit -m "Release v1.0.1"
git push
```

---

### Step 6 — Done!

Within 24 hours (or the next time they open Sticky Fingers), your users will see a dialog saying a new update is available. They can click to install it automatically.

If you want to test it immediately, open Sticky Fingers, click the icon in the menu bar, and choose **Check for Updates…**

---

## Important: Protect Your Private Key

Your update signing key is stored in your macOS Keychain under the name `"Sparkle Key"`. It is **never stored in the project folder** and should **never be committed to GitHub**.

If you lose your private key, existing users will not be able to receive automatic updates and you will need to have them reinstall the app manually.

To check that your key is safe, open **Keychain Access** (search for it with Cmd+Space) and search for "Sparkle". You should see an entry there.

---

## Troubleshooting

**"Check for Updates" says it's up to date when it shouldn't be:**
- Make sure the version in `<sparkle:version>` in appcast.xml is higher than what's in the running app
- Make sure appcast.xml has been pushed to GitHub and is publicly accessible

**Users get an error when installing an update:**
- Make sure the `sparkle:edDSASignature` in appcast.xml exactly matches what `release.sh` printed
- Make sure the `length` matches the actual file size of the zip
