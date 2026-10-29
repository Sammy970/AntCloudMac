<div align="center">

<img src=".github/icon.png" width="120" alt="AntCloud">

# AntCloud for macOS

**Native cloud-gaming client for [AntCloud](https://antcloud.co) — boot your cloud PC and stream it, all from one Mac app.**

![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)
![UI](https://img.shields.io/badge/UI-SwiftUI-blue)
![Streaming](https://img.shields.io/badge/streaming-Moonlight-5A0FC8)
![Unofficial](https://img.shields.io/badge/unofficial-not%20affiliated%20with%20AntCloud-red)

</div>

> [!IMPORTANT]
> **Unofficial project.** This is an independent client built by a user. It is not made, endorsed or supported by AntCloud.
> "AntCloud" and the AntCloud logo belong to their owners. Use it with your own AntCloud account, and follow AntCloud's terms of service.

---

<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset=".github/screenshots/dark-ready.png">
  <img src=".github/screenshots/light-ready.png" width="100%" alt="AntCloud for macOS: the Cloud PC screen with the cloud PC ready and a Launch Stream button">
</picture>
</p>

A SwiftUI launcher that handles the whole AntCloud session — login, VM allocation, pairing —
and streams through [Moonlight](https://moonlight-stream.org). You log in, click **Start Cloud PC**,
then **Launch Stream**, and it pairs and opens the stream for you.

## ✨ Features

- 🖥️ **Play-first home screen:** a drawn monitor shows what your cloud PC is doing (off, in queue, booting, ready, live), with a Connect → Boot → Ready → Stream track and one big button
- 🔐 **Login** with email/password or phone OTP. Tokens are stored in the macOS Keychain
- ☁️ **One-click cloud PC:** handles the queue, VM boot and readiness for you
- 🎮 **Auto-pairing:** generates the PIN and submits it to AntCloud's backend, no manual steps
- ⚙️ **Stream settings:** resolution, aspect ratio, frame rate, bitrate, HEVC and fullscreen, with the exact stream size and data use per hour
- ⏱️ **Plan at a glance:** time left this month, renewal date and a readable plan name ("Premium Night")
- 🎙️ **Microphone forwarding** to your cloud PC
- 🌗 **Light and dark mode**, following your Mac
- 🌙 **Night-plan aware:** ends sessions at the plan's cutoff, like the official client

## 📸 Screenshots

<table>
  <tr>
    <td width="50%" align="center">
{pic("login", "Sign-in screen with a blue aurora background and a glass sign-in card")}
      <br><sub><b>Sign in</b>, by email or phone code</sub>
    </td>
    <td width="50%" align="center">
{pic("queued", "Cloud PC screen showing the PC waiting in the queue at position 3")}
      <br><sub><b>In the queue</b>, with your live position</sub>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
{pic("streaming", "Cloud PC screen while streaming, with a LIVE indicator and every step complete")}
      <br><sub><b>Streaming</b> in Moonlight</sub>
    </td>
    <td width="50%" align="center">
{pic("settings", "Stream settings grouped into Display, Performance, and Codec and Audio")}
      <br><sub><b>Stream settings</b>, locked while you play</sub>
    </td>
  </tr>
</table>

<p align="center"><sub>Screenshots follow your GitHub theme: switch between light and dark to see both.</sub></p>

## 🚀 Getting started

**Requirements:** macOS 13+, Swift 5.9+ (Command Line Tools are enough), and
[Moonlight](https://moonlight-stream.org) (`brew install --cask moonlight`).

```sh
swift run                 # run in development
scripts/build-app.sh      # build AntCloud.app (needed for the microphone permission prompt)
```

`scripts/build-app.sh --bundle-moonlight` also embeds `/Applications/Moonlight.app` into the bundle.

**Preview mode (debug builds):** `ANTCLOUD_PREVIEW=home:ready swift run` opens any screen with a sample account,
without touching your Keychain or the API. States: `login`, `home:idle`, `home:queued`, `home:booting`,
`home:ready`, `home:pairing`, `home:streaming`; add `:stream` for the settings pane. Add
`ANTCLOUD_SNAPSHOT=shot.png` to save the window as a PNG, and `ANTCLOUD_APPEARANCE=light` for light mode.

## 🔄 How it works

```
Login ──▶ Start Cloud PC ──▶ queue / boot ──▶ ready
                                                │
                                      Launch Stream
                                                │
                     get VM IP ──▶ pair (auto-PIN) ──▶ Moonlight stream
```

1. Opens a Socket.IO session that queues and boots your VM
2. Polls until the VM is reachable, then tells the server to start video
3. On **Launch Stream**: fetches the VM IP, applies display settings, pairs, and runs Moonlight

## 📁 Layout

| Path | Purpose |
|---|---|
| `Sources/Shared/` | API client, auth/Keychain, Socket.IO session, stream settings |
| `Sources/Mac/` | macOS app, Moonlight runner, mic forwarder |
| `Sources/Mac/Views/` | Sidebar shell, Cloud PC screen, Stream settings |
| `PRODUCT.md`, `DESIGN.md` | Who the app is for, and the design rules the UI follows |
| `scripts/build-app.sh` | Builds and signs `AntCloud.app` |

> `Sources/Shared/` is shared with the iOS app ([AntCloudMoonlight](https://github.com/Sammy970/AntCloudMoonlight)).

## ⚠️ Note

Unofficial client, not affiliated with AntCloud. Uses the official [Moonlight](https://github.com/moonlight-stream/moonlight-qt) (GPLv3) for streaming.
