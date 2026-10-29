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

A SwiftUI launcher that handles the whole AntCloud session — login, VM allocation, pairing —
and streams through [Moonlight](https://moonlight-stream.org). You log in, click **Start Cloud PC**,
then **Launch Stream**, and it pairs and opens the stream for you.

## ✨ Features

- 🔐 **Login** with email/password or phone OTP — tokens stored in the macOS Keychain
- ☁️ **One-click cloud PC** — handles the queue, VM boot, and readiness automatically
- 🎮 **Auto-pairing** — generates the PIN and submits it to AntCloud's backend, no manual steps
- ⚙️ **Stream settings** — resolution, aspect ratio, frame rate, bitrate, HEVC, fullscreen
- 🎙️ **Microphone forwarding** to your cloud PC
- 🌙 **Night-plan aware** — ends sessions at the plan's cutoff, like the official client

## 🚀 Getting started

**Requirements:** macOS 13+, Swift 5.9+ (Command Line Tools are enough), and
[Moonlight](https://moonlight-stream.org) (`brew install --cask moonlight`).

```sh
swift run                 # run in development
scripts/build-app.sh      # build AntCloud.app (needed for the microphone permission prompt)
```

`scripts/build-app.sh --bundle-moonlight` also embeds `/Applications/Moonlight.app` into the bundle.

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
| `Sources/Mac/` | macOS app, views, Moonlight runner, mic forwarder |
| `scripts/build-app.sh` | Builds and signs `AntCloud.app` |

> `Sources/Shared/` is shared with the iOS app ([AntCloudMoonlight](https://github.com/Sammy970/AntCloudMoonlight)).

## ⚠️ Note

Unofficial client, not affiliated with AntCloud. Uses the official [Moonlight](https://github.com/moonlight-stream/moonlight-qt) (GPLv3) for streaming.
