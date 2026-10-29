# AntCloud for macOS

Native SwiftUI launcher for AntCloud cloud PCs. It reimplements the Windows launcher's protocol
(see `../re/FINDINGS.md`) and uses upstream [Moonlight](https://moonlight-stream.org) for the stream.

## Requirements

- macOS 13+, Swift 5.9+ (Command Line Tools are enough, Xcode is not required)
- Moonlight: `brew install --cask moonlight`

## Build & run

```sh
swift run                         # dev
scripts/build-app.sh              # → build/AntCloud.app (needed for the microphone permission prompt)
scripts/build-app.sh --bundle-moonlight   # also embeds /Applications/Moonlight.app
```

## Flow

1. Log in (email/password or phone OTP). The refresh token is stored in the Keychain.
2. **Start Cloud PC** opens the Socket.IO session → queue → VM boot → `/vm/checkconnectionstatus` → `control "video"`.
3. **Launch Stream** gets `/vm/getVmIp`, sends `setstream`, runs `Moonlight pair <ip> --pin N` while posting
   the PIN to `/vm/vmauth`, then runs `Moonlight stream <ip> Desktop …`.
4. **Shut Down** sends `closestream` and disconnects.

## Layout

| Path | Purpose |
|---|---|
| `API/APIClient.swift` | REST client for `api.antcloud.co` (JWT auth, retries once after refreshing on 401) |
| `Auth/` | Login state and Keychain storage |
| `Session/SessionService.swift` | Socket.IO session, VM readiness, pairing, server notices, night-plan cutoff |
| `Session/StreamSettings.swift` | Settings, server `stream` spec, Moonlight arguments |
| `Stream/MoonlightRunner.swift` | Finds and runs the Moonlight CLI |
| `Stream/MicForwarder.swift` | Microphone → raw PCM over UDP to `vmip:9002` |
