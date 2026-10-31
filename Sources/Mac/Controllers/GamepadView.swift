import SwiftUI

/// A drawn controller showing live input: pressed buttons light up in AntCloud blue, the sticks move with
/// the real ones, and the triggers fill as they're pulled. One Xbox-style body for every controller; the
/// face-button labels follow its family (✕○□△ on PlayStation).
struct GamepadView: View {
    let state: PadState
    var style = PadStyle.xbox
    /// Draws an unlit, unlabelled controller, for the empty state.
    var dimmed = false

    @Environment(\.colorScheme) private var scheme

    /// Everything is laid out on a 480 × 330 grid and scaled to fit.
    private static let size = CGSize(width: 480, height: 330)

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / Self.size.width, geo.size.height / Self.size.height)
            ZStack(alignment: .topLeading) {
                triggers
                shell
                bumper(.leftShoulder, x: 82)
                bumper(.rightShoulder, x: 303)
                stick(state.leftStick, pressed: state.pressed.contains(.leftStick), at: CGPoint(x: 150, y: 140))
                stick(state.rightStick, pressed: state.pressed.contains(.rightStick), at: CGPoint(x: 290, y: 212))
                dpad(at: CGPoint(x: 192, y: 212))
                faceButtons(at: CGPoint(x: 332, y: 140))
                centerButtons
            }
            .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: Self.size.width * scale, height: Self.size.height * scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(Self.size.width / Self.size.height, contentMode: .fit)
        .opacity(dimmed ? 0.45 : 1)
        .animation(.easeOut(duration: 0.08), value: state)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Controller")
    }

    // MARK: Colours

    private var bodyFill: LinearGradient {
        scheme == .dark
            ? LinearGradient(colors: [Color(white: 0.26), Color(white: 0.17)], startPoint: .top, endPoint: .bottom)
            : LinearGradient(colors: [Color(white: 0.98), Color(white: 0.88)], startPoint: .top, endPoint: .bottom)
    }
    private var control: Color { scheme == .dark ? Color(white: 0.11) : Color(white: 0.75) }
    private var controlEdge: Color { scheme == .dark ? .white.opacity(0.08) : .black.opacity(0.08) }
    private var glyph: Color { scheme == .dark ? .white.opacity(0.75) : .white }

    private func lit(_ on: Bool) -> Color { on && !dimmed ? .antBlue : control }

    // MARK: Body

    /// Overlapping shapes in one fill read as a single moulded body: a wide top and two grips.
    private var shell: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 80, style: .continuous)
                .frame(width: 380, height: 170).offset(x: 50, y: 80)
            Ellipse().frame(width: 128, height: 185).rotationEffect(.degrees(30)).offset(x: 62, y: 128)
            Ellipse().frame(width: 128, height: 185).rotationEffect(.degrees(-30)).offset(x: 290, y: 128)
        }
        .foregroundStyle(bodyFill)
        .compositingGroup()
        .shadow(color: .black.opacity(scheme == .dark ? 0.5 : 0.18), radius: 14, y: 8)
    }

    private func bumper(_ button: PadButton, x: CGFloat) -> some View {
        let on = state.pressed.contains(button)
        return RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(lit(on))
            .overlay(Text(dimmed ? "" : style.label(button)).font(.system(size: 11, weight: .bold)).foregroundStyle(glyph))
            .frame(width: 95, height: 20)
            .offset(x: x, y: 64)
            .shadow(color: on ? Color.antBlue.opacity(0.6) : .clear, radius: 8)
    }

    /// Trigger fill bars, above the body.
    private var triggers: some View {
        let (left, right) = style.triggerLabels
        return HStack(spacing: 0) {
            triggerBar(left, value: state.leftTrigger)
            Spacer()
            triggerBar(right, value: state.rightTrigger)
        }
        .frame(width: 330)
        .offset(x: 75, y: 6)
    }

    private func triggerBar(_ label: String, value: Double) -> some View {
        VStack(spacing: 5) {
            ZStack(alignment: .leading) {
                Capsule().fill(control)
                Capsule().fill(Color.antBlue).frame(width: dimmed ? 0 : 100 * value)
            }
            .frame(width: 100, height: 12)
            .overlay(Capsule().strokeBorder(controlEdge))
            Text(dimmed ? label : "\(label) \(Int((value * 100).rounded()))%")
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Controls

    private func stick(_ value: CGPoint, pressed: Bool, at center: CGPoint) -> some View {
        ZStack {
            Circle().fill(control).frame(width: 66, height: 66)
                .overlay(Circle().strokeBorder(controlEdge, lineWidth: 1))
            // Thumb: follows the stick (up is positive on the controller, down on screen).
            Circle()
                .fill(pressed && !dimmed ? Color.antBlue : (scheme == .dark ? Color(white: 0.32) : Color(white: 0.6)))
                .frame(width: 42, height: 42)
                .overlay(Circle().strokeBorder(.white.opacity(0.15)))
                .offset(x: value.x * 13, y: -value.y * 13)
                .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
        }
        .position(center)
    }

    private func dpad(at center: CGPoint) -> some View {
        let arms: [(PadButton, CGSize)] = [
            (.dpadUp, CGSize(width: 0, height: -20)), (.dpadDown, CGSize(width: 0, height: 20)),
            (.dpadLeft, CGSize(width: -20, height: 0)), (.dpadRight, CGSize(width: 20, height: 0)),
        ]
        return ZStack {
            RoundedRectangle(cornerRadius: 5).fill(control).frame(width: 22, height: 62)
            RoundedRectangle(cornerRadius: 5).fill(control).frame(width: 62, height: 22)
            ForEach(arms, id: \.0) { button, offset in
                RoundedRectangle(cornerRadius: 4)
                    .fill(state.pressed.contains(button) && !dimmed ? Color.antBlue : .clear)
                    .frame(width: 20, height: 20)
                    .offset(offset)
            }
        }
        .position(center)
    }

    private func faceButtons(at center: CGPoint) -> some View {
        let buttons: [(PadButton, CGSize)] = [
            (.y, CGSize(width: 0, height: -27)), (.a, CGSize(width: 0, height: 27)),
            (.x, CGSize(width: -27, height: 0)), (.b, CGSize(width: 27, height: 0)),
        ]
        return ZStack {
            ForEach(buttons, id: \.0) { button, offset in
                let on = state.pressed.contains(button)
                Circle()
                    .fill(lit(on))
                    .frame(width: 27, height: 27)
                    .overlay(Text(dimmed ? "" : style.label(button)).font(.system(size: 13, weight: .bold)).foregroundStyle(glyph))
                    .shadow(color: on && !dimmed ? Color.antBlue.opacity(0.7) : .clear, radius: 8)
                    .offset(offset)
            }
        }
        .position(center)
    }

    private var centerButtons: some View {
        ZStack {
            Capsule().fill(lit(state.pressed.contains(.view))).frame(width: 18, height: 10).position(x: 205, y: 140)
            Capsule().fill(lit(state.pressed.contains(.menu))).frame(width: 18, height: 10).position(x: 275, y: 140)
            Circle()
                .fill(lit(state.pressed.contains(.home)))
                .frame(width: 30, height: 30)
                .overlay(Circle().strokeBorder(controlEdge))
                .position(x: 240, y: 104)
        }
    }
}
