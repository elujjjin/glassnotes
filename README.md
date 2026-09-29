# 💎 GlassNotes iOS - Liquid Glass Private Notepad

**GlassNotes** is a native iOS application built with **Swift & SwiftUI**, leveraging modern **Liquid Glass visual effects** (ultraThinMaterial blurs, animated mesh gradients, frosted cards, and vibrant translucency), **SwiftData** persistence, local **Face ID / Touch ID security**, and a **Telegram-style instant scratchpad timeline**.

Designed specifically to be built easily without a Mac via **GitHub Actions CI/CD** and loaded directly into **LiveContainer** on iOS devices (iPhone 11 / iOS 18/26+).

---

## 🌟 Key Features

- 💎 **Liquid Glass UI**: Modern frosted glass materials (`.ultraThinMaterial`), dynamic ambient mesh gradient backgrounds, translucent floating search bar, and interactive haptic buttons.
- ⚡ **Telegram-Style Quick Scratchpad Feed**: Instant bottom input bar to stream thoughts, quick notes, or snippets instantly into your feed (just like sending messages to yourself in Telegram).
- 🔒 **Privacy & Biometric Lock**: Secure private notes with Face ID, Touch ID, or passcode authentication.
- 🏷️ **Tag Badges & Filters**: Organize notes with custom icons and hex color badges (Ideas, Work, Personal, Secret, Scratchpad).
- 📝 **Markdown Editor & Live Preview**: Write rich text with a quick Markdown formatting toolbar (`#`, `**bold**`, `*italic*`, `- [ ] tasks`, ``code``) and toggle instant live preview mode.
- ✈️ **Telegram Cross-Platform Sync**: Optional integration with Telegram Bot API to send notes back and forth between your iPhone and Telegram on PC or other devices.
- 📦 **No-Mac Sideloading**: GitHub Actions workflow compiles the unsigned `.ipa` automatically for LiveContainer.

---

## 🚀 How to Build & Install on LiveContainer (No Mac Needed!)

Since you are running Windows, follow these 3 simple steps to get your `.ipa` artifact built in under 2 minutes using GitHub Actions:

### Step 1: Push Code to GitHub

Open terminal / PowerShell in `c:\vvv\iosthing` and push the project to your GitHub repository:

```bash
git init
git add .
git commit -m "Initial commit of GlassNotes iOS app"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/GlassNotes.git
git push -u origin main
```

---

### Step 2: Automated GitHub Actions Build

1. Go to your repository on **GitHub.com**.
2. Click on the **Actions** tab.
3. You will see the **Build GlassNotes LiveContainer IPA** workflow running automatically (or click **Run workflow** manually).
4. Wait ~1–2 minutes for the `macos-14` runner to complete compiling Xcode.
5. Click on the completed workflow run.
6. Scroll down to the **Artifacts** section at the bottom of the page and click to download **`GlassNotes-LiveContainer-IPA.zip`**.

---

### Step 3: Install in LiveContainer on iPhone 11

1. Unzip the downloaded file to get **`GlassNotes.ipa`**.
2. Share `GlassNotes.ipa` to your iPhone (via AirDrop, Telegram, Google Drive, iCloud, or local transfer).
3. Open **LiveContainer** on your iPhone.
4. Tap **+ (Add App)** and select `GlassNotes.ipa`.
5. Tap **GlassNotes** to launch! Enjoy your private Liquid Glass Notepad! 🎉

---

## 🛠️ Tech Stack & Architecture

- **Language**: Swift 5
- **UI Framework**: SwiftUI (iOS 17+)
- **Storage**: SwiftData (`@Model`)
- **Authentication**: LocalAuthentication (`LAContext` Face ID / Touch ID)
- **CI/CD**: GitHub Actions (`macos-14` / `xcodebuild`)
- **Package Target**: Unsigned `.ipa` / LiveContainer Payload
