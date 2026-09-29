# GlassNotes iOS

A private notepad for iPhone built with Swift and SwiftUI. Notes are stored locally with SwiftData, optionally locked behind Face ID, and can be forwarded to Telegram. The interface uses Apple's Liquid Glass material.

## Backgrounds

The wallpaper is chosen in Settings and matters more than usual here: Liquid Glass refracts whatever sits behind it, so a flat colour gives it nothing to bend. The built-in options are Graphite, Aurora, Prism, Lattice, and Silk, plus any photo from your library.

- Graphite, Silk — restrained, keeps text legible
- Lattice — a fine grid, which makes lensing and distortion obvious
- Prism — saturated, for checking chromatic fringing at the edges
- Photo — shows refraction most clearly

## Material

On iOS 26 and later, cards, fields, and buttons use the real `Glass` material via `glassEffect(_:in:)` and are grouped in a `GlassEffectContainer`. On iOS 17 through 25 the app falls back to a hand-built approximation: a thin tint, a strong specular rim, and an inner angular sheen. It is deliberately not a frosted material — the fallback keeps the background legible rather than blurring it.

Both paths go through `liquidGlass(_:)` in `Views/Components/LiquidGlass.swift`, so there is one place to change the look.

## Features

- Quick capture bar that streams notes into the feed
- Search across titles and bodies
- Tags with colours and SF Symbols, filterable
- Markdown toolbar and preview
- Per-note pin and lock
- Face ID / Touch ID / passcode lock
- Telegram forwarding
- JSON export via the share sheet

## Build

Push to GitHub; the workflow in `.github/workflows/build-ipa.yml` compiles an unsigned `.ipa` and uploads it as a build artifact. Open the run, download `GlassNotes-LiveContainer-IPA`, unzip, and side-load the `.ipa` into LiveContainer.

## Stack

Swift · SwiftUI · SwiftData · LocalAuthentication · GitHub Actions

