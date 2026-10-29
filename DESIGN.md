# Design

World: **Native Mac pro.** Reads like a first-party Apple utility (System Settings, Screen Sharing), with AntCloud blue as the only accent.

- **Structure:** `NavigationSplitView`. The sidebar has *Cloud PC* and *Stream*, with an account footer (initial avatar, name, plan, menu).
- **Appearance:** follows the system. All colours are semantic (`.primary`, `.secondary`, `.quaternary`, window and control backgrounds) except the brand accent.
- **Accent:** `Color.antBlue` (#4A86E8), set as the app tint. Status colours carry meaning only: green when ready or streaming, orange for warnings, red for errors.
- **Type:** SF Pro through system text styles. Pane titles are `.largeTitle.bold` on the Cloud PC hero and `.title2.semibold` for the status. Readouts use `.monospacedDigit()`.
- **Signature move:** the *display hero*, a drawn monitor whose screen renders the session state (dark glass when off, a scanning shimmer while booting, a brand-blue screen with a play glyph when ready, a live dot when streaming). Under it sits a four-step connection track: Connect → Boot → Ready → Stream.
- **Controls:** stock SwiftUI controls only. Grouped `Form` for settings, segmented pickers for short option sets, `.borderedProminent` large for the one primary action.
- **Motion:** state changes crossfade with `.smooth` spring. The busy step pulses. Nothing moves when idle.
- **Login (the one expressive screen):** a drifting aurora of brand blues (soft radial gradients, a faint dot grid) runs under a hidden title bar. The left side carries a large headline and three feature rows; the form sits on a `.regularMaterial` card. Sign In uses the brand-gradient glow pill. The aurora stops under Reduce Motion.
- **Plan names:** always shown through `UserProfile.planName` ("premiumNyt" → "Premium Night", with a moon icon), never the raw code.
