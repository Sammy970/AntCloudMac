# Product

<!-- impeccable:product-schema 1 -->

## Platform

macos (native SwiftUI, macOS 13+)

## Users
AntCloud subscribers who want to play on their cloud gaming PC from a Mac, often in the evening on a night plan.
They open the app, start the cloud PC, wait for it to boot, then hand off to a fullscreen Moonlight stream.

## Product Purpose
An unofficial Mac client for AntCloud. It logs in, starts and shuts down the cloud PC, pairs Moonlight automatically and launches the stream with the user's settings.
Success means: one click to start, one click to play, no manual pairing.

## Operating Context
- The app is open only before and after a session. During play, Moonlight owns the screen.
- Session phases: off, connecting, queued, booting, ready, pairing, streaming.
- Stream settings (resolution, aspect, FPS, bitrate, HEVC, fullscreen, microphone) change occasionally and lock while streaming.
- Requires Moonlight installed (`brew install --cask moonlight`).

## Brand Commitments
- Uses the official AntCloud icon (`AntCloud.icns`, `.github/icon.png`), brand blue around #4A86E8.
- Unofficial: never present the app as made by AntCloud.

## Product Principles
1. Play first: the state of the cloud PC and the next action dominate.
2. Native Mac behaviour: standard controls, sidebar navigation, light and dark.
3. Tell the truth about time and data: plan time left, renew date, data per hour.
